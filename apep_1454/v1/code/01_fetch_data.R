# 01_fetch_data.R — Fetch data from Statistics Denmark Statbank API
source("00_packages.R")

# ── Helper: query DST Statbank API ──────────────────────────────────
dst_query <- function(table_id, variables, lang = "en") {
  url <- "https://api.statbank.dk/v1/data"
  body <- list(
    table = table_id,
    format = "CSV",
    lang = lang,
    variables = variables
  )
  json_body <- jsonlite::toJSON(body, auto_unbox = TRUE)
  resp <- httr::POST(url, body = json_body,
                     httr::content_type_json(), httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("DST API error %d for table %s: %s",
                 httr::status_code(resp), table_id,
                 httr::content(resp, "text", encoding = "UTF-8")))
  }
  txt <- httr::content(resp, "text", encoding = "UTF-8")
  df <- read.csv(text = txt, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot("DST API returned empty data" = nrow(df) > 0)
  cat(sprintf("  %s: %d rows fetched\n", table_id, nrow(df)))
  df
}

# Helper to make variable lists JSON-safe (as.list ensures arrays)
vl <- function(code, values) list(code = code, values = as.list(values))

years <- as.character(2007:2024)

# ══════════════════════════════════════════════════════════════════════
# 1. Public benefit recipients by type × age × sex (AUH02)
# ══════════════════════════════════════════════════════════════════════
cat("Fetching AUH02: benefit recipients by type, age, sex...\n")
auf02 <- dst_query("AUH02", list(
  vl("TYPE", "FTM"),
  vl("YDELSESTYPE", c("TOT", "KT", "KH", "IN", "DP", "TOTLE", "TOTUSU", "SY")),
  vl("ALDER", c("16-24", "25-29", "30-34", "35-39", "40-44")),
  vl("KØN", c("TOT", "M", "K")),
  vl("Tid", years)
))

# ══════════════════════════════════════════════════════════════════════
# 2. Public benefit recipients by region × age (AUH03)
# ══════════════════════════════════════════════════════════════════════
cat("Fetching AUH03: benefit recipients by region, age...\n")
# Get all region codes
resp_meta <- httr::GET("https://api.statbank.dk/v1/tableinfo/AUH03?lang=en&format=JSON",
                       httr::timeout(60))
meta_auh03 <- jsonlite::fromJSON(httr::content(resp_meta, "text", encoding = "UTF-8"),
                                  simplifyVector = FALSE)
region_codes <- sapply(meta_auh03$variables[[1]]$values, function(x) x$id)
cat(sprintf("  %d regions available\n", length(region_codes)))

auf03 <- dst_query("AUH03", list(
  vl("OMRÅDE", region_codes),
  vl("YDELSESTYPE", c("AKTOT", "AKK", "AKD")),
  vl("KØN", c("TOT")),
  vl("ALDER", c("25-29", "30-34")),
  vl("Tid", years)
))

# ══════════════════════════════════════════════════════════════════════
# 3. Employment rates by region × age (RAS200)
# ══════════════════════════════════════════════════════════════════════
cat("Fetching RAS200: employment rates by region, age...\n")
resp_ras <- httr::GET("https://api.statbank.dk/v1/tableinfo/RAS200?lang=en&format=JSON",
                      httr::timeout(60))
meta_ras <- jsonlite::fromJSON(httr::content(resp_ras, "text", encoding = "UTF-8"),
                                simplifyVector = FALSE)
ras_regions <- sapply(meta_ras$variables[[1]]$values, function(x) x$id)
cat(sprintf("  %d RAS200 regions\n", length(ras_regions)))

ras200 <- dst_query("RAS200", list(
  vl("OMRÅDE", ras_regions),
  vl("HERKOMST", "00"),
  vl("ALDER", c("25-29", "30-34", "35-39", "18-19", "20-24")),
  vl("KØN", c("TOT", "M", "K")),
  vl("BEREGNING", c("BFK", "EFK")),
  vl("Tid", as.character(2008:2024))
))

# ══════════════════════════════════════════════════════════════════════
# 4. Population by age (FOLK1A) — denominator
# ══════════════════════════════════════════════════════════════════════
cat("Fetching FOLK1A: population by age...\n")
resp_folk <- httr::GET("https://api.statbank.dk/v1/tableinfo/FOLK1A?lang=en&format=JSON",
                       httr::timeout(60))
meta_folk <- jsonlite::fromJSON(httr::content(resp_folk, "text", encoding = "UTF-8"),
                                 simplifyVector = FALSE)
folk_time_vals <- sapply(meta_folk$variables[[length(meta_folk$variables)]]$values, function(x) x$id)
q1_times <- grep("K1$", folk_time_vals, value = TRUE)

folk_age_var <- NULL
for (v in meta_folk$variables) {
  if (v$id == "ALDER") folk_age_var <- v
}
all_ages <- sapply(folk_age_var$values, function(x) x$id)
single_ages <- grep("^\\d+$", all_ages, value = TRUE)
rel_ages <- single_ages[as.integer(single_ages) >= 16 & as.integer(single_ages) <= 50]

folk1a <- dst_query("FOLK1A", list(
  vl("ALDER", rel_ages),
  vl("Tid", q1_times)
))

# ══════════════════════════════════════════════════════════════════════
# Save raw data
# ══════════════════════════════════════════════════════════════════════
saveRDS(auf02, "../data/raw_auh02_benefits.rds")
saveRDS(auf03, "../data/raw_auh03_benefits_region.rds")
saveRDS(ras200, "../data/raw_ras200_employment.rds")
saveRDS(folk1a, "../data/raw_folk1a_population.rds")
cat("\nAll raw data saved.\n")
cat(sprintf("AUH02: %d rows\nAUH03: %d rows\nRAS200: %d rows\nFOLK1A: %d rows\n",
            nrow(auf02), nrow(auf03), nrow(ras200), nrow(folk1a)))
