# 01_fetch_data.R — Fetch BFS Pensionskassenstatistik data
# Swiss occupational pension statistics, 2004-2024

source("00_packages.R")

cat("=== Fetching BFS Pensionskassenstatistik ===\n")

# ---------------------------------------------------------------
# Helper: query BFS PXWeb API
# ---------------------------------------------------------------
fetch_bfs_pxweb <- function(table_id, variables, response_format = "json-stat2") {
  url <- paste0(
    "https://www.pxweb.bfs.admin.ch/api/v1/de/",
    table_id, "/", table_id, ".px"
  )
  # Build JSON manually to ensure values are always arrays
  query_items <- sapply(seq_along(variables), function(i) {
    code <- variables[[i]]$code
    vals <- variables[[i]]$values
    vals_json <- paste0('["', paste(vals, collapse = '","'), '"]')
    sprintf('{"code":"%s","selection":{"filter":"item","values":%s}}', code, vals_json)
  })
  json_body <- sprintf('{"query":[%s],"response":{"format":"%s"}}',
                        paste(query_items, collapse = ","), response_format)

  resp <- httr::POST(
    url,
    body = json_body,
    httr::content_type_json(),
    httr::accept_json()
  )
  if (httr::status_code(resp) != 200) {
    stop("BFS API returned status ", httr::status_code(resp),
         ": ", httr::content(resp, "text", encoding = "UTF-8"))
  }
  raw <- httr::content(resp, "text", encoding = "UTF-8")
  fromJSON(raw)
}

# ---------------------------------------------------------------
# Table _101: Overview — annuity beneficiaries + capital payments
# ---------------------------------------------------------------
cat("Fetching table _101 (overview)...\n")

# Variables needed:
# 4 = Laufende Renten: Bezüger (annuity beneficiaries)
# 5 = Laufende Renten: Jahresbetrag (annuity amounts)
# 6 = Kapitalzahlungen: Bezüger (capital payment beneficiaries)
# 7 = Kapitalzahlungen: Jahresbetrag (capital payment amounts)
# 2 = Aktive Versicherte: Total
vars_101 <- list(
  list(code = "Beobachtungseinheit", values = c("2", "4", "5", "6", "7")),
  list(code = "Verwaltungsform", values = c("99")),
  list(code = "Art der Risikodeckung", values = c("99")),
  list(code = "Rechtsform", values = c("99")),
  list(code = "Registrierung VE", values = c("99"))
)

data_101 <- fetch_bfs_pxweb("px-x-1303030000_101", vars_101)
cat("  Table _101 fetched successfully.\n")

# Parse JSON-stat2 format
parse_jsonstat2 <- function(jstat) {
  dims <- jstat$dimension
  dim_ids <- jstat$id
  dim_sizes <- jstat$size
  values <- jstat$value

  # Build grid of all dimension combinations
  dim_labels <- lapply(dim_ids, function(d) {
    cats <- dims[[d]]$category
    # Preserve order from index
    idx <- cats$index
    if (is.list(idx)) {
      ordered_codes <- names(idx)[order(unlist(idx))]
    } else {
      ordered_codes <- names(cats$label)
    }
    data.table(
      code = ordered_codes,
      label = unlist(cats$label[ordered_codes])
    )
  })

  grid <- do.call(CJ, lapply(dim_labels, function(x) x$code))
  setnames(grid, dim_ids)

  # Add labels
  for (i in seq_along(dim_ids)) {
    d <- dim_ids[i]
    lbl_col <- paste0(d, "_label")
    grid[, (lbl_col) := dim_labels[[i]]$label[match(get(d), dim_labels[[i]]$code)]]
  }

  # Add values
  grid[, value := unlist(values)]
  grid
}

dt_101 <- parse_jsonstat2(data_101)
cat("  Parsed _101: ", nrow(dt_101), " rows\n")

# ---------------------------------------------------------------
# Table _141: Benefits — old-age annuity by gender
# ---------------------------------------------------------------
cat("Fetching table _141 (annuity benefits by type)...\n")

# Key variables:
# 1 = Altersrenten: Bezüger (Alle)
# 2 = Altersrenten: Bezüger (Frauen)
# 3 = Altersrenten: Jahresbetrag Total
# 5 = Invalidenrenten: Bezüger (alle) — placebo
# 7 = Invalidenrenten: Jahresbetrag Total — placebo
vars_141 <- list(
  list(code = "Beobachtungseinheit", values = c("1", "2", "3", "4", "5", "6", "7", "8")),
  list(code = "Verwaltungsform", values = c("99")),
  list(code = "Art der Risikodeckung", values = c("99")),
  list(code = "Rechtsform", values = c("99")),
  list(code = "Registrierung VE", values = c("99"))
)

data_141 <- fetch_bfs_pxweb("px-x-1303030000_141", vars_141)
dt_141 <- parse_jsonstat2(data_141)
cat("  Parsed _141: ", nrow(dt_141), " rows\n")

# ---------------------------------------------------------------
# Table _142: Capital payments at retirement by gender
# ---------------------------------------------------------------
cat("Fetching table _142 (capital payments at retirement)...\n")

# Key variables:
# 1 = Kapitalleistung bei Pensionierung: Bezüger (alle)
# 2 = Kapitalleistung bei Pensionierung: Bezüger (Frauen)
# 3 = Kapitalleistung bei Pensionierung: Jahresbetrag Total
# 4 = Kapitalleistung bei Pensionierung: Jahresbetrag Frauenanteil
# 9 = Kapitalleistung bei Invalidität: Bezüger (alle) — placebo
# 11 = Kapitalleistung bei Invalidität: Jahresbetrag Total — placebo
vars_142 <- list(
  list(code = "Beobachtungseinheit", values = c("1", "2", "3", "4", "9", "10", "11", "12")),
  list(code = "Verwaltungsform", values = c("99")),
  list(code = "Art der Risikodeckung", values = c("99")),
  list(code = "Rechtsform", values = c("99")),
  list(code = "Registrierung VE", values = c("99"))
)

data_142 <- fetch_bfs_pxweb("px-x-1303030000_142", vars_142)
dt_142 <- parse_jsonstat2(data_142)
cat("  Parsed _142: ", nrow(dt_142), " rows\n")

# ---------------------------------------------------------------
# Table _101 by risk coverage type (for mechanism analysis)
# ---------------------------------------------------------------
cat("Fetching table _101 by risk coverage type...\n")

vars_101_risk <- list(
  list(code = "Beobachtungseinheit", values = c("2", "4", "5", "6", "7")),
  list(code = "Verwaltungsform", values = c("99")),
  list(code = "Art der Risikodeckung", values = c("1", "2", "3", "4", "5", "6")),
  list(code = "Rechtsform", values = c("99")),
  list(code = "Registrierung VE", values = c("99"))
)

data_101_risk <- fetch_bfs_pxweb("px-x-1303030000_101", vars_101_risk)
dt_101_risk <- parse_jsonstat2(data_101_risk)
cat("  Parsed _101 by risk type: ", nrow(dt_101_risk), " rows\n")

# ---------------------------------------------------------------
# Save all fetched data
# ---------------------------------------------------------------
saveRDS(dt_101, "../data/bfs_101_overview.rds")
saveRDS(dt_141, "../data/bfs_141_annuities.rds")
saveRDS(dt_142, "../data/bfs_142_capital_retirement.rds")
saveRDS(dt_101_risk, "../data/bfs_101_by_risk_type.rds")

cat("\n=== All data saved to data/ directory ===\n")
cat("  bfs_101_overview.rds\n")
cat("  bfs_141_annuities.rds\n")
cat("  bfs_142_capital_retirement.rds\n")
cat("  bfs_101_by_risk_type.rds\n")
