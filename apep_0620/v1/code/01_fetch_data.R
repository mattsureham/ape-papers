# 01_fetch_data.R — Fetch data from Statistics Denmark StatBank API
# apep_0620: Second-generation refugee dispersal outcomes in Denmark
#
# Strategy:
#   Treatment: Non-Western immigrant share by municipality (2008, earliest post-reform)
#   Outcomes:  Non-Western descendant employment (RAS200) and education (HFUDD11)
#   Historical: BEF3 for pre-dispersal balance checks (overlapping municipality codes)

source("00_packages.R")

# ─── StatBank API helpers ────────────────────────────────────────────────────
statbank_fetch <- function(table_id, variables, lang = "en") {
  url <- "https://api.statbank.dk/v1/data"
  # Ensure all 'values' are lists (not character vectors) so toJSON
  # produces arrays even for single-element values with auto_unbox
  variables <- lapply(variables, function(v) {
    v$values <- as.list(v$values)
    v
  })
  body <- list(
    table = table_id,
    format = "CSV",
    lang = lang,
    variables = variables
  )
  resp <- httr::POST(url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    httr::timeout(180)
  )
  if (httr::status_code(resp) != 200) {
    raw_err <- httr::content(resp, "text", encoding = "UTF-8")
    stop(sprintf("StatBank API error for %s: HTTP %d\n%s",
      table_id, httr::status_code(resp), raw_err))
  }
  raw <- httr::content(resp, "text", encoding = "UTF-8")
  df <- readr::read_csv2(raw, show_col_types = FALSE)
  cat(sprintf("  %s: %d rows x %d cols\n", table_id, nrow(df), ncol(df)))
  stopifnot(nrow(df) > 0)
  return(df)
}

statbank_info <- function(table_id, lang = "en") {
  url <- "https://api.statbank.dk/v1/tableinfo"
  body <- list(table = table_id, format = "JSON", lang = lang)
  resp <- httr::POST(url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    httr::timeout(60)
  )
  jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
}

# Get post-2007 municipality codes from RAS200 metadata
cat("Getting post-2007 municipality codes...\n")
ras_info <- statbank_info("RAS200")
all_codes <- ras_info$variables$values[[1]]
# Keep only 3-digit codes that are actual municipalities (not regions/provinces)
muni_codes <- all_codes$id[nchar(all_codes$id) == 3 & all_codes$id != "000"]
cat(sprintf("  %d municipalities identified\n", length(muni_codes)))

# ─────────────────────────────────────────────────────────────────────────────
# 1. RAS200 — Employment rate by municipality × ancestry, 2008-2024
#    HERKOMST 35 = Non-western descendants, 25 = Non-western immigrants
#    BEREGNING BFK = Employment rate (%)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n1. Fetching RAS200: employment rates by municipality and ancestry...\n")

# Non-Western descendant employment rate (primary outcome)
cat("  Non-Western descendants...\n")
ras_nw_desc <- statbank_fetch("RAS200", list(
  list(code = "OMRÅDE", values = muni_codes),
  list(code = "HERKOMST", values = c("35")),
  list(code = "ALDER", values = c("25-29", "30-34", "35-39")),
  list(code = "KØN", values = c("TOT")),
  list(code = "BEREGNING", values = c("BFK")),
  list(code = "Tid", values = c("2008", "2010", "2012", "2014",
                                 "2016", "2018", "2020", "2022", "2024"))
))
saveRDS(ras_nw_desc, "../data/ras_nw_descendants.rds")

# Non-Western immigrant employment rate (for treatment construction + comparison)
cat("  Non-Western immigrants...\n")
ras_nw_imm <- statbank_fetch("RAS200", list(
  list(code = "OMRÅDE", values = muni_codes),
  list(code = "HERKOMST", values = c("25")),
  list(code = "ALDER", values = c("16-64")),
  list(code = "KØN", values = c("TOT")),
  list(code = "BEREGNING", values = c("BFK")),
  list(code = "Tid", values = c("2008", "2012", "2016", "2020", "2024"))
))
saveRDS(ras_nw_imm, "../data/ras_nw_immigrants.rds")

# Danish origin employment rate (benchmark)
cat("  Danish origin...\n")
ras_dk <- statbank_fetch("RAS200", list(
  list(code = "OMRÅDE", values = muni_codes),
  list(code = "HERKOMST", values = c("10")),
  list(code = "ALDER", values = c("25-29", "30-34", "35-39")),
  list(code = "KØN", values = c("TOT")),
  list(code = "BEREGNING", values = c("BFK")),
  list(code = "Tid", values = c("2022"))
))
saveRDS(ras_dk, "../data/ras_danish_origin.rds")

# Total employment (all origins, for controls)
cat("  Total population...\n")
ras_total <- statbank_fetch("RAS200", list(
  list(code = "OMRÅDE", values = muni_codes),
  list(code = "HERKOMST", values = c("00")),
  list(code = "ALDER", values = c("16-64")),
  list(code = "KØN", values = c("TOT")),
  list(code = "BEREGNING", values = c("BFK")),
  list(code = "Tid", values = c("2008", "2022"))
))
saveRDS(ras_total, "../data/ras_total.rds")

# ─────────────────────────────────────────────────────────────────────────────
# 2. HFUDD11 — Education by municipality × ancestry × age
#    HERKOMST 3 = All descendants (no Western/Non-Western split available)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n2. Fetching HFUDD11: education by municipality and ancestry...\n")

# Get HFUDD education level codes
hfudd_info <- statbank_info("HFUDD11")
hfudd_levels <- hfudd_info$variables$values[[which(hfudd_info$variables$id == "HFUDD")]]
cat("  Available education levels:\n")
print(head(hfudd_levels, 12))

# Use BOPOMR codes (same as OMRÅDE for education)
hfudd_muni_info <- hfudd_info$variables$values[[which(hfudd_info$variables$id == "BOPOMR")]]
hfudd_muni_codes <- hfudd_muni_info$id[nchar(hfudd_muni_info$id) == 3 & hfudd_muni_info$id != "000"]

# Descendants education by municipality (latest year + historical)
cat("  Descendants education...\n")
hfudd_desc <- statbank_fetch("HFUDD11", list(
  list(code = "BOPOMR", values = hfudd_muni_codes),
  list(code = "HERKOMST", values = c("3")),
  list(code = "ALDER", values = c("25-29", "30-34", "35-39")),
  list(code = "HFUDD", values = c("TOT", "H10", "H20", "H30", "H40", "H50", "H60", "H70", "H80")),
  list(code = "KØN", values = c("TOT")),
  list(code = "Tid", values = c("2008", "2012", "2016", "2020", "2023"))
))
saveRDS(hfudd_desc, "../data/hfudd_descendants.rds")

# Danish origin education (benchmark)
cat("  Danish origin education...\n")
hfudd_dk <- statbank_fetch("HFUDD11", list(
  list(code = "BOPOMR", values = hfudd_muni_codes),
  list(code = "HERKOMST", values = c("5")),
  list(code = "ALDER", values = c("25-29", "30-34", "35-39")),
  list(code = "HFUDD", values = c("TOT", "H10", "H20", "H30", "H40", "H50", "H60", "H70", "H80")),
  list(code = "KØN", values = c("TOT")),
  list(code = "Tid", values = c("2023"))
))
saveRDS(hfudd_dk, "../data/hfudd_danish.rds")

# ─────────────────────────────────────────────────────────────────────────────
# 3. FOLK1C — Population stocks by municipality × ancestry (quarterly)
#    Used for treatment construction (immigrant share)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n3. Fetching FOLK1C: population by municipality and ancestry...\n")
folk_info <- statbank_info("FOLK1C")

# Get all ancestry groups for multiple time points
folk <- statbank_fetch("FOLK1C", list(
  list(code = "OMRÅDE", values = muni_codes),
  list(code = "HERKOMST", values = c("TOT", "5", "4", "3")),
  list(code = "Tid", values = c("2008K1", "2012K1", "2016K1", "2020K1", "2024K1"))
))
saveRDS(folk, "../data/folk1c_all.rds")

# ─────────────────────────────────────────────────────────────────────────────
# 4. BEF3 — Historical immigrant stocks (pre-2007 municipality codes)
#    Used for pre-dispersal balance check on overlapping municipalities
# ─────────────────────────────────────────────────────────────────────────────
cat("\n4. Fetching BEF3: historical immigrant stocks...\n")

# Get BEF3 municipality codes
bef3_info <- statbank_info("BEF3")
bef3_muni <- bef3_info$variables$values[[1]]
bef3_muni_codes <- bef3_muni$id[nchar(bef3_muni$id) == 3 & bef3_muni$id != "000"]

# Find overlapping codes with post-2007 municipalities
overlap_codes <- intersect(muni_codes, bef3_muni_codes)
cat(sprintf("  %d municipalities with matching old/new codes\n", length(overlap_codes)))

# Fetch immigrant stocks for overlapping municipalities
cat("  Immigrants (historical)...\n")
bef3_imm <- statbank_fetch("BEF3", list(
  list(code = "OMRÅDE", values = overlap_codes),
  list(code = "HERKOMST", values = c("4")),
  list(code = "TID", values = c("1980", "1981", "1982", "1983", "1984", "1985",
                                 "1986", "1990", "1995", "2000", "2005", "2006"))
))
saveRDS(bef3_imm, "../data/bef3_immigrants.rds")

# Total population for denominators
cat("  Danish origin (historical)...\n")
bef3_dk <- statbank_fetch("BEF3", list(
  list(code = "OMRÅDE", values = overlap_codes),
  list(code = "HERKOMST", values = c("5")),
  list(code = "TID", values = c("1980", "1985", "1986", "2000", "2006"))
))
saveRDS(bef3_dk, "../data/bef3_danish.rds")

cat("  Descendants (historical)...\n")
bef3_desc <- statbank_fetch("BEF3", list(
  list(code = "OMRÅDE", values = overlap_codes),
  list(code = "HERKOMST", values = c("3")),
  list(code = "TID", values = c("1980", "1985", "1986", "1990", "1995", "2000", "2005", "2006"))
))
saveRDS(bef3_desc, "../data/bef3_descendants.rds")

# ─────────────────────────────────────────────────────────────────────────────
# 5. FOLK1A — Total population by municipality (quarterly, 2008+)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n5. Fetching FOLK1A: total population by municipality...\n")
folk1a <- statbank_fetch("FOLK1A", list(
  list(code = "OMRÅDE", values = muni_codes),
  list(code = "KØN", values = c("TOT")),
  list(code = "ALDER", values = c("IALT")),
  list(code = "CIVILSTAND", values = c("TOT")),
  list(code = "Tid", values = c("2008K1", "2012K1", "2016K1", "2020K1", "2024K1"))
))
saveRDS(folk1a, "../data/folk1a_total.rds")

cat("\n=== All data fetched successfully ===\n")
cat("Data files:\n")
fls <- list.files("../data/", pattern = "\\.rds$")
for (f in fls) {
  sz <- file.size(file.path("../data", f))
  cat(sprintf("  %s (%.1f KB)\n", f, sz / 1024))
}
