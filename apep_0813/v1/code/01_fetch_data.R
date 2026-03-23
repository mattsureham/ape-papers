# 01_fetch_data.R — Fetch Swiss cantonal data for NFA reform analysis
# apep_0813/v1
# Sources: BFS PXWeb (migration, population), EFV (NFA resource equalization)

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

cat("=== Fetching Swiss cantonal data ===\n")
cat("Working directory:", getwd(), "\n")

# -------------------------------------------------------------------
# Canton reference table
# -------------------------------------------------------------------
canton_info <- data.table(
  canton_id = 1:26,
  canton = c("ZH","BE","LU","UR","SZ","OW","NW","GL","ZG","FR",
             "SO","BS","BL","SH","AR","AI","SG","GR","AG","TG",
             "TI","VD","VS","NE","GE","JU")
)

# -------------------------------------------------------------------
# 1. Fetch migration + population from BFS PXWeb
# -------------------------------------------------------------------
# Table: px-x-0102020000_101 (Demographic balance by canton)
# 5 dimensions: Year × Canton × Citizenship × Sex × Demographic component
# We need:
#   - Demographic component 5 = In-migration from another canton
#   - Demographic component 7 = Out-migration to another canton
#   - Demographic component 0 = Population on 1 January
# Filtered: Citizenship = 0 (total), Sex = 0 (total)

cat("\n--- Step 1: BFS PXWeb demographic data ---\n")

bfs_url <- "https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0102020000_101/px-x-0102020000_101.px"

# Get metadata to confirm dimension codes
meta_resp <- GET(bfs_url)
stopifnot("BFS PXWeb metadata fetch failed" = status_code(meta_resp) == 200)
meta <- content(meta_resp, "parsed")

# Extract dimension codes
dim_codes <- sapply(meta$variables, function(v) v$code)
cat("Dimension codes:", paste(dim_codes, collapse=", "), "\n")

year_code <- dim_codes[1]       # "Jahr"
canton_code <- dim_codes[2]     # "Kanton"
citizen_code <- dim_codes[3]    # "Staatsangehörigkeit (Kategorie)"
sex_code <- dim_codes[4]        # "Geschlecht"
component_code <- dim_codes[5]  # "Demografische Komponente"

# Query: years 2001-2024, cantons 1-26, citizenship total, sex total,
# components: 0=pop Jan 1, 5=in-migration, 7=out-migration
query_body <- list(
  query = list(
    list(code = year_code,
         selection = list(filter = "item",
                          values = as.list(as.character(2001:2024)))),
    list(code = canton_code,
         selection = list(filter = "item",
                          values = as.list(as.character(1:26)))),
    list(code = citizen_code,
         selection = list(filter = "item",
                          values = list("0"))),  # Total
    list(code = sex_code,
         selection = list(filter = "item",
                          values = list("0"))),  # Total
    list(code = component_code,
         selection = list(filter = "item",
                          values = list("0", "5", "7")))  # Pop, In-mig, Out-mig
  ),
  response = list(format = "json-stat2")
)

cat("Fetching demographic data (migration + population)...\n")
resp <- POST(bfs_url,
             body = toJSON(query_body, auto_unbox = TRUE),
             content_type_json(),
             timeout(60))
stopifnot("BFS data fetch failed" = status_code(resp) == 200)

# Parse json-stat2 response
js <- content(resp, "text", encoding = "UTF-8")
parsed <- fromJSON(js)

dim_sizes <- parsed$size
cat(sprintf("Dimensions: %s = %d cells\n",
            paste(dim_sizes, collapse=" × "), prod(dim_sizes)))

# Build ordered index for each dimension
# Use labels for the year dimension (codes may be sequential, not actual years)
dim_ids <- list()
for (d in names(parsed$dimension)) {
  cats <- parsed$dimension[[d]]$category
  idx <- unlist(cats$index)
  ordered_codes <- names(idx)[order(idx)]

  if (d == names(parsed$dimension)[1]) {
    # Year dimension: use labels (actual year values like "2001")
    lbl <- unlist(cats$label)
    dim_ids[[d]] <- lbl[ordered_codes]
    cat(sprintf("Year mapping: codes %s-%s → labels %s-%s\n",
                ordered_codes[1], tail(ordered_codes, 1),
                dim_ids[[d]][1], tail(dim_ids[[d]], 1)))
  } else {
    dim_ids[[d]] <- ordered_codes
  }
}

# Expand grid (json-stat2 is row-major: last dimension varies fastest)
grid <- do.call(expand.grid, c(rev(dim_ids), list(KEEP.OUT.ATTRS = FALSE)))
grid <- grid[, rev(seq_along(grid))]
names(grid) <- names(parsed$dimension)

dt <- data.table(grid)
dt[, value := parsed$value]

cat(sprintf("Raw data: %d rows\n", nrow(dt)))

# Rename dimensions for clarity
dim_names <- names(parsed$dimension)
setnames(dt, dim_names, c("year", "canton_id_str", "citizenship", "sex", "component"))

# Keep only totals (citizenship=0, sex=0) — should already be filtered
dt <- dt[citizenship == "0" & sex == "0"]
dt[, c("citizenship", "sex") := NULL]

# Convert types (as.character first to avoid factor→integer level-index bug)
dt[, year := as.integer(as.character(year))]
dt[, canton_id := as.integer(as.character(canton_id_str))]

# Pivot wider: one row per canton-year with pop, in_mig, out_mig
panel_raw <- dcast(dt, year + canton_id ~ component, value.var = "value")
setnames(panel_raw, c("0", "5", "7"), c("population", "in_migration", "out_migration"),
         skip_absent = TRUE)

panel_raw[, net_migration := in_migration - out_migration]

cat(sprintf("\nPanel: %d canton-years (%d cantons × %d years)\n",
            nrow(panel_raw), uniqueN(panel_raw$canton_id), uniqueN(panel_raw$year)))

# Validate
stopifnot("Not all 26 cantons" = uniqueN(panel_raw$canton_id) == 26)
stopifnot("Missing population" = sum(is.na(panel_raw$population)) == 0)
stopifnot("Missing in-migration" = sum(is.na(panel_raw$in_migration)) == 0)

cat("Sample (Zurich, first 5 years):\n")
print(panel_raw[canton_id == 1][1:5])

# -------------------------------------------------------------------
# 2. Construct NFA treatment intensity
# -------------------------------------------------------------------
cat("\n--- Step 2: NFA treatment intensity ---\n")

# NFA Resource Equalization: the Ressourcenindex determines transfers mechanically.
# Source: EFV Wirksamkeitsbericht des Finanzausgleichs (public government reports).
# Cantons with RI < 100 receive resource equalization transfers.
# Cantons with RI > 100 contribute to the equalization fund.
#
# 2008 resource indices (initial NFA year) from EFV:
# https://www.efv.admin.ch/efv/en/home/themen/finanzausgleich/wirksamkeitsberichte.html

nfa_treatment <- data.table(
  canton_id = 1:26,
  canton = c("ZH","BE","LU","UR","SZ","OW","NW","GL","ZG","FR",
             "SO","BS","BL","SH","AR","AI","SG","GR","AG","TG",
             "TI","VD","VS","NE","GE","JU"),
  # Ressourcenindex 2008 (from EFV Wirksamkeitsbericht 2008-2011)
  ressourcenindex_2008 = c(
    115.7,  # ZH
     79.3,  # BE
     82.7,  # LU
     64.5,  # UR
    108.5,  # SZ
     78.2,  # OW
    128.5,  # NW
     80.9,  # GL
    246.7,  # ZG
     77.3,  # FR
     84.5,  # SO
    143.5,  # BS
     99.3,  # BL
     88.7,  # SH
     82.6,  # AR
     77.9,  # AI
     84.1,  # SG
     81.2,  # GR
     93.9,  # AG
     80.7,  # TG
     87.2,  # TI
     99.8,  # VD
     70.9,  # VS
     82.2,  # NE
    140.1,  # GE
     63.6   # JU
  )
)

# Treatment intensity: proportional to how much the canton gains/loses
# Positive = receives transfers (resource-weak), Negative = contributes (resource-strong)
nfa_treatment[, nfa_intensity := (100 - ressourcenindex_2008) / 100]

# Binary group classification for robustness
nfa_treatment[, nfa_group := fifelse(ressourcenindex_2008 < 95, "recipient",
                              fifelse(ressourcenindex_2008 > 105, "payer", "near_zero"))]

cat("NFA treatment classification:\n")
cat(sprintf("  Recipients (RI < 95): %d cantons\n", sum(nfa_treatment$nfa_group == "recipient")))
cat(sprintf("  Near-zero (95-105): %d cantons\n", sum(nfa_treatment$nfa_group == "near_zero")))
cat(sprintf("  Payers (RI > 105): %d cantons\n", sum(nfa_treatment$nfa_group == "payer")))

print(nfa_treatment[order(ressourcenindex_2008),
                     .(canton, ressourcenindex_2008, nfa_intensity, nfa_group)])

# -------------------------------------------------------------------
# 3. Merge and save
# -------------------------------------------------------------------
cat("\n--- Step 3: Merge and save ---\n")

panel <- merge(panel_raw, nfa_treatment, by = "canton_id")

# Compute per-capita rates (per 1000 population)
panel[, net_migration_rate := net_migration / population * 1000]
panel[, in_migration_rate := in_migration / population * 1000]
panel[, out_migration_rate := out_migration / population * 1000]

# Post-NFA indicator
panel[, post := as.integer(year >= 2008)]

# Event time (relative to NFA implementation)
panel[, event_time := year - 2008]

setorder(panel, canton_id, year)

cat(sprintf("Final panel: %d obs (%d cantons × %d years)\n",
            nrow(panel), uniqueN(panel$canton_id), uniqueN(panel$year)))

# Summary by group, pre-period
cat("\nPre-NFA means by group:\n")
print(panel[year < 2008, .(
  n_cantons = uniqueN(canton_id),
  mean_pop = round(mean(population)),
  mean_net_mig_rate = round(mean(net_migration_rate), 2),
  mean_in_mig_rate = round(mean(in_migration_rate), 2),
  sd_net_mig_rate = round(sd(net_migration_rate), 2)
), by = nfa_group])

saveRDS(panel, "data/panel.rds")
cat("\nSaved data/panel.rds\n")
cat("=== Data fetch complete ===\n")
