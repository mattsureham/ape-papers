## 01_fetch_data.R — Fetch all data for apep_1103
## Sources: BAG OKP Dashboard (Excel), BFS PXWeb (IV integration, IV pensions, population)

source("00_packages.R")

data_dir <- "../data"
stopifnot(dir.exists(data_dir))

# ── Helper: BFS PXWeb API query ──────────────────────────────────────────────
fetch_bfs_pxweb <- function(table_id, query_body) {
  url <- paste0(
    "https://www.pxweb.bfs.admin.ch/api/v1/de/",
    table_id, "/", table_id, ".px"
  )
  resp <- POST(
    url,
    body = query_body,
    encode = "json",
    content_type_json(),
    timeout(60)
  )
  if (status_code(resp) != 200) {
    stop("BFS PXWeb API failed for ", table_id, ": HTTP ", status_code(resp),
         "\nBody: ", content(resp, "text", encoding = "UTF-8"))
  }
  raw <- content(resp, "text", encoding = "UTF-8")
  parsed <- fromJSON(raw)

  # Parse PXWeb JSON-stat format
  dims <- parsed$dimension
  dim_names <- names(dims)

  # Build a data frame from the JSON-stat structure
  values <- parsed$value

  # Get dimension sizes and labels
  dim_info <- lapply(dim_names, function(dn) {
    cats <- dims[[dn]]$category
    labels <- cats$label
    idx <- cats$index
    if (is.null(idx)) {
      return(names(labels))
    }
    # Sort by index
    ord <- order(unlist(idx))
    names(idx)[ord]
  })
  names(dim_info) <- dim_names

  # Create expanded grid
  grid <- expand.grid(rev(dim_info), stringsAsFactors = FALSE)
  grid <- grid[, rev(seq_along(grid))]
  names(grid) <- dim_names

  grid$value <- values

  # Add text labels for each dimension
  for (dn in dim_names) {
    cats <- dims[[dn]]$category
    labels <- cats$label
    label_vec <- unlist(labels)
    grid[[paste0(dn, "_text")]] <- label_vec[grid[[dn]]]
  }

  as_tibble(grid)
}

# ══════════════════════════════════════════════════════════════════════════════
# 1) OKP per-capita costs by canton and year (BAG Dashboard Excel)
# ══════════════════════════════════════════════════════════════════════════════
cat("── Reading BAG OKP cost data ──\n")
okp_file <- file.path(data_dir, "Daten", "02_Kostenmonitoring_Zeitreihe-Jahr_Kanton.xlsx")
stopifnot(file.exists(okp_file))

okp_raw <- read_excel(okp_file, sheet = "Data")
cat("  OKP raw rows:", nrow(okp_raw), "\n")

# Keep total gender, all cost groups, canton-level (exclude CH total)
okp <- okp_raw |>
  filter(
    Geschlecht == "Total",
    Kanton_ISO2 != "CH"  # Keep only individual cantons
  ) |>
  mutate(
    year = as.integer(Jahr),
    canton = Kanton_ISO2,
    cost_group = Kostengruppe,
    okp_cost_pc = as.numeric(Bruttoleistungen_pro_Versicherten)
  ) |>
  select(year, canton, cost_group, okp_cost_pc) |>
  filter(!is.na(okp_cost_pc))

cat("  OKP cleaned rows:", nrow(okp), "\n")
cat("  Cantons:", length(unique(okp$canton)), "\n")
cat("  Years:", range(okp$year), "\n")
cat("  Cost groups:", unique(okp$cost_group), "\n")

stopifnot(length(unique(okp$canton)) == 26)
stopifnot(min(okp$year) <= 2000)
stopifnot(max(okp$year) >= 2020)

saveRDS(okp, file.path(data_dir, "okp_costs.rds"))
cat("  Saved okp_costs.rds\n")

# ══════════════════════════════════════════════════════════════════════════════
# 2) IV integration measures by canton (BFS PXWeb px-x-1305010000_042)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Fetching IV integration measures from BFS PXWeb ──\n")

# Canton codes 1-26 (excluding 27=Ausland and total)
canton_codes <- as.character(1:26)
year_codes <- as.character(2006:2024)

iv_query <- list(
  query = list(
    list(code = "Beobachtungseinheit", selection = list(
      filter = "item", values = list("1", "2")  # Count and CHF amounts
    )),
    list(code = "Leistungsart", selection = list(
      filter = "item", values = list(
        "20", "30", "40", "60"  # Early intervention, integration, vocational, all combined
      )
    )),
    list(code = "IV-Stelle", selection = list(
      filter = "item", values = canton_codes
    )),
    list(code = "Jahr", selection = list(
      filter = "item", values = year_codes
    ))
  ),
  response = list(format = "json-stat2")
)

iv_raw <- fetch_bfs_pxweb("px-x-1305010000_042", iv_query)
cat("  IV integration raw rows:", nrow(iv_raw), "\n")

saveRDS(iv_raw, file.path(data_dir, "iv_integration_raw.rds"))
cat("  Saved iv_integration_raw.rds\n")

# ══════════════════════════════════════════════════════════════════════════════
# 3) IV pension recipients by canton (BFS PXWeb px-x-1305010000_002)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Fetching IV pension recipients from BFS PXWeb ──\n")

# Dimensions: Beobachtungseinheit (1=count, 2=%pop), Kanton (1-26), Geschlecht, Jahr (2009-2024)
pension_query <- list(
  query = list(
    list(code = "Beobachtungseinheit", selection = list(
      filter = "item", values = list("1", "2")  # Count and population share
    )),
    list(code = "Kanton", selection = list(
      filter = "item", values = canton_codes
    )),
    list(code = "Geschlecht", selection = list(
      filter = "item", values = list("\u00AF99999")  # Total (using ¯99999)
    )),
    list(code = "Jahr", selection = list(
      filter = "item", values = as.list(as.character(2009:2024))
    ))
  ),
  response = list(format = "json-stat2")
)

iv_pensions_raw <- fetch_bfs_pxweb("px-x-1305010000_002", pension_query)
cat("  IV pensions raw rows:", nrow(iv_pensions_raw), "\n")

saveRDS(iv_pensions_raw, file.path(data_dir, "iv_pensions_raw.rds"))
cat("  Saved iv_pensions_raw.rds\n")

# ══════════════════════════════════════════════════════════════════════════════
# 4) Cantonal population — derive from IV pension data
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Population will be derived from IV pension count/share in 02_clean_data.R ──\n")

# ══════════════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════════════
cat("\n══ Data fetch complete ══\n")
cat("Files in data/:\n")
for (f in list.files(data_dir, pattern = "\\.rds$")) {
  cat("  ", f, " (", format(file.size(file.path(data_dir, f)), big.mark = ","), " bytes)\n")
}
