## 02_clean_data.R — Build analysis dataset from PatentsView bulk files
## apep_0534: Green Patent Examiner Leniency IV

source("00_packages.R")

cat("=== Loading PatentsView data ===\n")

# ── Load core tables ────────────────────────────────────────────────────
patent <- fread(file.path(DATA_DIR, "g_patent.tsv"),
                select = c("patent_id", "patent_date", "patent_type",
                           "num_claims", "patent_title"),
                colClasses = c(patent_id = "character"))
cat("Patents:", format(nrow(patent), big.mark = ","), "\n")

examiner <- fread(file.path(DATA_DIR, "g_examiner_not_disambiguated.tsv"),
                  colClasses = c(patent_id = "character"))
cat("Examiner records:", format(nrow(examiner), big.mark = ","), "\n")

cpc <- fread(file.path(DATA_DIR, "g_cpc_current.tsv"),
             colClasses = c(patent_id = "character"))
cat("CPC records:", format(nrow(cpc), big.mark = ","), "\n")

app <- fread(file.path(DATA_DIR, "g_application.tsv"),
             colClasses = c(patent_id = "character"))
cat("Application records:", format(nrow(app), big.mark = ","), "\n")

# ── Identify Y02 (green/clean energy) patents ──────────────────────────
# CPC Y02 = Climate change mitigation technologies
# Identify available CPC columns
cpc_cols <- names(cpc)
cat("CPC columns:", paste(cpc_cols, collapse = ", "), "\n")

# Y02 identification: check cpc_group if it exists, else use cpc_subclass
if ("cpc_group" %in% cpc_cols) {
  y02_cpc <- cpc[grepl("^Y02", cpc_group) | grepl("^Y02", cpc_subclass)]
} else {
  y02_cpc <- cpc[grepl("^Y02", cpc_subclass)]
}

# Deduplicate to one primary Y02 code per patent (first occurrence)
seq_col <- intersect(names(y02_cpc), c("cpc_sequence"))
if (length(seq_col) > 0) {
  y02_cpc <- y02_cpc[order(patent_id, cpc_sequence)]
} else {
  y02_cpc <- y02_cpc[order(patent_id)]
}
y02_primary <- y02_cpc[, .SD[1], by = patent_id]

# Ensure cpc_group exists for domain classification
if (!"cpc_group" %in% names(y02_primary)) {
  # Use cpc_subclass as proxy
  y02_primary[, cpc_group := cpc_subclass]
}

# Create Y02 technology domain variable
y02_primary[, y02_domain := fcase(
  grepl("^Y02E", cpc_group) | grepl("^Y02E", cpc_subclass), "Energy",
  grepl("^Y02B", cpc_group) | grepl("^Y02B", cpc_subclass), "Buildings",
  grepl("^Y02P", cpc_group) | grepl("^Y02P", cpc_subclass), "Production",
  grepl("^Y02T", cpc_group) | grepl("^Y02T", cpc_subclass), "Transport",
  grepl("^Y02C", cpc_group) | grepl("^Y02C", cpc_subclass), "CarbonCapture",
  grepl("^Y02W", cpc_group) | grepl("^Y02W", cpc_subclass), "Waste",
  default = "Other_Y02"
)]

# Get all Y02 patent IDs
y02_ids <- unique(y02_primary$patent_id)
cat("Y02 patents:", format(length(y02_ids), big.mark = ","), "\n")

# ── Build analysis dataset: Y02 patents with examiner info ─────────────
# Merge patent info
dt <- merge(patent[patent_id %in% y02_ids],
            y02_primary[, .(patent_id, cpc_group, cpc_subclass, y02_domain)],
            by = "patent_id", all.x = TRUE)

# Parse dates
dt[, patent_date := as.Date(patent_date)]
dt[, grant_year := year(patent_date)]

# Merge application info
app_cols <- intersect(names(app), c("patent_id", "filing_date", "series_code",
                                     "number", "application_id"))
dt <- merge(dt, app[, ..app_cols], by = "patent_id", all.x = TRUE)

if ("filing_date" %in% names(dt)) {
  dt[, filing_date := as.Date(filing_date)]
  dt[, filing_year := year(filing_date)]
} else {
  # Fallback: use grant year - 3 as approximate filing year
  dt[, filing_year := grant_year - 3L]
}

# Merge examiner info
ex_cols <- names(examiner)
dt <- merge(dt, examiner, by = "patent_id", all.x = TRUE)

# ── Construct examiner ID ───────────────────────────────────────────────
# Use name_first + name_last within art_unit as examiner identifier
name_first_col <- intersect(names(dt), c("name_first", "examiner_name_first",
                                          "raw_examiner_name_first"))
name_last_col  <- intersect(names(dt), c("name_last", "examiner_name_last",
                                          "raw_examiner_name_last"))
art_unit_col   <- intersect(names(dt), c("art_unit", "examiner_art_unit",
                                          "art_group"))

if (length(name_first_col) > 0 && length(name_last_col) > 0 && length(art_unit_col) > 0) {
  dt[, examiner_id := paste0(get(name_first_col[1]), "_", get(name_last_col[1]))]
  if (art_unit_col[1] != "art_unit") dt[, art_unit := get(art_unit_col[1])]
} else {
  cat("Examiner columns available:", paste(names(dt), collapse = ", "), "\n")
  stop("Cannot identify examiner name and art unit columns")
}

# Filter to utility patents with valid examiner info
dt <- dt[patent_type == "utility" & !is.na(examiner_id) & examiner_id != "_"]

# Filter to filing years 2001-2018 (allow 5-year follow-on window)
dt <- dt[filing_year >= 2001 & filing_year <= 2018]

cat("Analysis sample after filters:", format(nrow(dt), big.mark = ","), "Y02 patents\n")
cat("Unique examiners:", format(uniqueN(dt$examiner_id), big.mark = ","), "\n")
cat("Unique art units:", format(uniqueN(dt$art_unit), big.mark = ","), "\n")
cat("Filing year range:", min(dt$filing_year), "-", max(dt$filing_year), "\n")

# ── Compute examiner leniency ──────────────────────────────────────────
# Need ALL patents (not just Y02) by each examiner to measure leniency
# Load full examiner × patent mapping
cat("\n=== Computing examiner leniency from full patent universe ===\n")

# Get all patents with examiner info (not just Y02)
full_exam <- merge(
  examiner,
  patent[, .(patent_id, patent_date, patent_type)],
  by = "patent_id"
)

# Use same column resolution
fe_first <- intersect(names(full_exam), c("name_first", "examiner_name_first",
                                           "raw_examiner_name_first"))
fe_last  <- intersect(names(full_exam), c("name_last", "examiner_name_last",
                                           "raw_examiner_name_last"))
fe_au    <- intersect(names(full_exam), c("art_unit", "examiner_art_unit",
                                           "art_group"))
if (length(fe_first) > 0 && length(fe_last) > 0 && length(fe_au) > 0) {
  full_exam[, examiner_id := paste0(get(fe_first[1]), "_", get(fe_last[1]))]
  if (fe_au[1] != "art_unit") full_exam[, art_unit := get(fe_au[1])]
}

full_exam[, grant_year := year(as.Date(patent_date))]
full_exam <- full_exam[patent_type == "utility" & !is.na(examiner_id) & examiner_id != "_"]

# Count grants per examiner × art_unit × year (among ALL technologies)
exam_grants <- full_exam[, .(n_grants = .N), by = .(examiner_id, art_unit, grant_year)]

# Total grants per art_unit × year
au_year_total <- full_exam[, .(au_total = .N, n_examiners = uniqueN(examiner_id)),
                           by = .(art_unit, grant_year)]

# Merge
exam_grants <- merge(exam_grants, au_year_total, by = c("art_unit", "grant_year"))

# Leave-one-out examiner leniency:
# Z_j = (total grants by examiner j in art-unit-year MINUS 1) /
#        (total grants in art-unit-year MINUS 1)
# This is the probability of grant for any other patent in this cell
exam_grants[, loo_leniency := (n_grants - 1) / (au_total - 1)]
exam_grants[au_total <= 1, loo_leniency := NA]

# Keep only cells with enough examiners for variation
exam_grants <- exam_grants[n_examiners >= 3]

cat("Examiner-year cells:", format(nrow(exam_grants), big.mark = ","), "\n")
cat("Leniency range:", round(range(exam_grants$loo_leniency, na.rm = TRUE), 3), "\n")

# ── Merge leniency into Y02 analysis dataset ───────────────────────────
# Match on examiner × art_unit × grant_year
dt <- merge(dt, exam_grants[, .(examiner_id, art_unit, grant_year, loo_leniency,
                                 n_grants, au_total, n_examiners)],
            by = c("examiner_id", "art_unit", "grant_year"), all.x = TRUE)

# Drop observations without valid leniency
dt <- dt[!is.na(loo_leniency)]

cat("\nAfter leniency merge:", format(nrow(dt), big.mark = ","), "Y02 patents\n")

# ── Construct follow-on innovation outcomes ─────────────────────────────
cat("\n=== Building follow-on innovation outcomes ===\n")

# Get all Y02 patents with their CPC subclass and grant date
y02_all <- merge(
  patent[patent_id %in% y02_ids, .(patent_id, patent_date)],
  y02_primary[, .(patent_id, cpc_subclass, cpc_group)],
  by = "patent_id"
)
y02_all[, patent_date := as.Date(patent_date)]
y02_all[, grant_year := year(patent_date)]

# Annual follow-on activity by subclass (vectorized, no per-row loops)
cat("Computing subclass-level follow-on activity...\n")
y02_annual <- y02_all[, .(n_y02 = .N), by = .(cpc_subclass, year = grant_year)]

# Build a complete grid of subclass × year for fast lookup
all_sub <- unique(y02_annual$cpc_subclass)
all_yr  <- min(y02_annual$year):max(y02_annual$year)
grid <- CJ(cpc_subclass = all_sub, year = all_yr)
grid <- merge(grid, y02_annual, by = c("cpc_subclass", "year"), all.x = TRUE)
grid[is.na(n_y02), n_y02 := 0L]

# Compute cumulative sums by subclass for fast window queries
setkey(grid, cpc_subclass, year)
grid[, cum_y02 := cumsum(n_y02), by = cpc_subclass]

# Vectorized follow-on: use grid as a lookup table, not merge
# Create a lookup environment for O(1) access
cum_lookup <- grid[, .(key = paste0(cpc_subclass, "_", year), cum_y02)]
cum_env <- new.env(hash = TRUE, size = nrow(cum_lookup))
for (i in seq_len(nrow(cum_lookup))) {
  cum_env[[cum_lookup$key[i]]] <- cum_lookup$cum_y02[i]
}
max_grid_yr <- max(grid$year)

# Also build max cumulative per subclass for years beyond data
max_cum_lookup <- grid[year == max_grid_yr, .(cpc_subclass, cum_max = cum_y02)]
max_cum_env <- new.env(hash = TRUE, size = nrow(max_cum_lookup))
for (i in seq_len(nrow(max_cum_lookup))) {
  max_cum_env[[max_cum_lookup$cpc_subclass[i]]] <- max_cum_lookup$cum_max[i]
}

get_cum <- function(sub, yr) {
  if (yr > max_grid_yr) {
    v <- max_cum_env[[sub]]
  } else {
    v <- cum_env[[paste0(sub, "_", yr)]]
  }
  if (is.null(v)) 0 else v
}

compute_followon <- function(subs, yrs, window) {
  n <- length(subs)
  result <- integer(n)
  for (i in seq_len(n)) {
    cum_base <- get_cum(subs[i], yrs[i])
    cum_end  <- get_cum(subs[i], yrs[i] + window)
    result[i] <- max(0L, cum_end - cum_base)
  }
  result
}

cat("  3-year window...\n")
dt[, followon_3yr := compute_followon(cpc_subclass, grant_year, 3L)]
cat("  5-year window...\n")
dt[, followon_5yr := compute_followon(cpc_subclass, grant_year, 5L)]
cat("  10-year window...\n")
dt[, followon_10yr := compute_followon(cpc_subclass, grant_year, 10L)]

# ── Load inventor data (optional — for inv_id and assignee info) ────────
cat("\n=== Loading inventor and assignee data ===\n")

inv_file <- file.path(DATA_DIR, "g_inventor_not_disambiguated.tsv")
if (file.exists(inv_file)) {
  cat("Loading inventor data...\n")
  inventor <- fread(inv_file, colClasses = c(patent_id = "character"))
  inv_cols <- names(inventor)
  inv_first <- intersect(inv_cols, c("name_first", "inventor_name_first"))
  inv_last  <- intersect(inv_cols, c("name_last", "inventor_name_last"))
  if (length(inv_first) > 0 && length(inv_last) > 0) {
    inventor[, inv_id := paste0(get(inv_first[1]), "_", get(inv_last[1]))]
  } else {
    inventor[, inv_id := paste0("inv_", .I)]
  }
  inv_primary <- inventor[, .SD[1], by = patent_id]
  dt <- merge(dt, inv_primary[, .(patent_id, inv_id)],
              by = "patent_id", all.x = TRUE)
  cat("  Inventor data merged.\n")
} else {
  cat("  Inventor file not available. Setting inv_id to NA.\n")
  dt[, inv_id := NA_character_]
}

# Load assignee data
cat("Loading assignee data...\n")
assignee <- fread(file.path(DATA_DIR, "g_assignee_not_disambiguated.tsv"),
                  colClasses = c(patent_id = "character"))
ass_cols <- names(assignee)
org_col <- intersect(ass_cols, c("assignee_organization", "organization",
                                  "disambig_assignee_organization"))
if (length(org_col) > 0) {
  assignee[, org_name := get(org_col[1])]
} else {
  assignee[, org_name := NA_character_]
}
ass_primary <- assignee[, .SD[1], by = patent_id]
dt <- merge(dt, ass_primary[, .(patent_id, org_name)],
            by = "patent_id", all.x = TRUE)

# ── Forward citations (secondary outcome) ──────────────────────────────
cite_file <- file.path(DATA_DIR, "g_us_patent_citation.tsv")
if (file.exists(cite_file)) {
  cat("\n=== Computing forward citations ===\n")
  cite <- fread(cite_file, colClasses = c(patent_id = "character", citation_patent_id = "character"))
  cite_cols <- names(cite)
  cat("Citation columns:", paste(cite_cols, collapse = ", "), "\n")

  # In PatentsView: patent_id is the CITING patent, citation_patent_id is CITED
  if ("patent_id" %in% cite_cols && "citation_patent_id" %in% cite_cols) {
    fwd_cites <- cite[citation_patent_id %in% dt$patent_id,
                      .(fwd_citations = .N), by = .(patent_id = citation_patent_id)]
    dt <- merge(dt, fwd_cites, by = "patent_id", all.x = TRUE)
    dt[is.na(fwd_citations), fwd_citations := 0L]

    bwd_cites <- cite[patent_id %in% dt$patent_id,
                      .(bwd_citations = .N), by = patent_id]
    dt <- merge(dt, bwd_cites, by = "patent_id", all.x = TRUE)
    dt[is.na(bwd_citations), bwd_citations := 0L]
  } else {
    cat("  Unexpected citation column names. Setting to 0.\n")
    dt[, fwd_citations := 0L]
    dt[, bwd_citations := 0L]
  }

  # Geographic diffusion
  cat("\n=== Computing geographic diffusion ===\n")
  if (exists("inventor") && "patent_id" %in% cite_cols && "citation_patent_id" %in% cite_cols) {
    relevant_cites <- cite[citation_patent_id %in% dt$patent_id]
    inv_state_col <- intersect(names(inventor), c("inventor_state", "location_id", "state"))
    if (length(inv_state_col) > 0) {
      citing_states <- merge(
        relevant_cites[, .(citing_pid = patent_id, focal_patent_id = citation_patent_id)],
        inv_primary[, .(patent_id, inv_state = get(inv_state_col[1]))],
        by.x = "citing_pid", by.y = "patent_id"
      )
      geo_diff <- citing_states[!is.na(inv_state) & inv_state != "",
                                 .(n_citing_states = uniqueN(inv_state)),
                                 by = .(patent_id = focal_patent_id)]
      dt <- merge(dt, geo_diff, by = "patent_id", all.x = TRUE)
      dt[is.na(n_citing_states), n_citing_states := 0L]
    } else {
      dt[, n_citing_states := NA_integer_]
    }
  } else {
    dt[, n_citing_states := NA_integer_]
  }
  rm(cite); gc()
} else {
  cat("\n  Citation file not available. Setting citations to 0.\n")
  dt[, fwd_citations := 0L]
  dt[, bwd_citations := 0L]
  dt[, n_citing_states := NA_integer_]
}

# ── Create art_unit × filing_year FE variable ──────────────────────────
dt[, au_fy := paste0(art_unit, "_", filing_year)]

# ── Assignee type ──────────────────────────────────────────────────────
type_col <- intersect(names(assignee), c("assignee_type", "disambig_assignee_type"))
if (length(type_col) > 0) {
  ass_type <- assignee[, .SD[1], by = patent_id][, .(patent_id, assignee_type = get(type_col[1]))]
  dt <- merge(dt, ass_type, by = "patent_id", all.x = TRUE)
} else {
  dt[, assignee_type := NA_character_]
}

# ── Save analysis dataset ──────────────────────────────────────────────
keep_cols <- c("patent_id", "patent_date", "grant_year", "filing_year",
               "num_claims", "cpc_subclass", "cpc_group", "y02_domain",
               "examiner_id", "art_unit", "au_fy",
               "loo_leniency", "n_grants", "au_total", "n_examiners",
               "followon_3yr", "followon_5yr", "followon_10yr",
               "fwd_citations", "n_citing_states", "bwd_citations",
               "inv_id", "org_name", "assignee_type")
keep_cols <- intersect(keep_cols, names(dt))

analysis <- dt[, ..keep_cols]
fwrite(analysis, file.path(DATA_DIR, "analysis_dataset.csv"))
cat("\n=== Analysis dataset saved ===\n")
cat("Observations:", format(nrow(analysis), big.mark = ","), "\n")
cat("Y02 domains:\n")
print(table(analysis$y02_domain))
cat("Filing years:\n")
print(summary(analysis$filing_year))
cat("Leniency summary:\n")
print(summary(analysis$loo_leniency))
cat("Follow-on 5yr summary:\n")
print(summary(analysis$followon_5yr))

# ── Data validation ────────────────────────────────────────────────────
stopifnot("Expected 1000+ Y02 patents" = nrow(analysis) >= 1000)
stopifnot("Expected 50+ examiners" = uniqueN(analysis$examiner_id) >= 50)
stopifnot("Expected 5+ art units" = uniqueN(analysis$art_unit) >= 5)
stopifnot("Leniency has variation" = sd(analysis$loo_leniency, na.rm = TRUE) > 0.001)

cat("\nData validation passed.\n")
