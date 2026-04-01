# 01_fetch_data.R — Fetch BEA REIS county economic data
# APEP-1284: BLM Lottery Leases and Western County Economies
# BLM lease data already fetched via Python preprocessing (township_leases_geo.csv)

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# Verify BLM data exists
blm_file <- file.path(DATA_DIR, "township_leases_geo.csv")
stopifnot(file.exists(blm_file))
cat(sprintf("BLM township data found: %s\n", blm_file))

# ============================================================
# 1. BEA REIS DATA — All US counties
# ============================================================
cat("\n=== Fetching BEA REIS data ===\n")

bea_key <- Sys.getenv("BEA_API_KEY")
stopifnot(nchar(bea_key) > 0)

fetch_bea_all_counties <- function(table_name, line_code, year) {
  url <- sprintf(
    "https://apps.bea.gov/api/data/?UserID=%s&method=GetData&datasetname=Regional&TableName=%s&LineCode=%s&GeoFips=COUNTY&Year=%s&ResultFormat=json",
    bea_key, table_name, line_code, year
  )

  resp <- httr::GET(url)
  stopifnot(httr::status_code(resp) == 200)

  json <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(json)

  if (!is.null(parsed$BEAAPI$Results$Data)) {
    dt <- as.data.table(parsed$BEAAPI$Results$Data)
    cat(sprintf("  %s year %s: %d county obs\n", table_name, year, nrow(dt)))
    return(dt)
  }
  return(NULL)
}

# Fetch per capita income (CAINC1, Line 3) for key years
years <- c(1969, 1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020)

cat("Fetching per capita income...\n")
income_list <- list()
for (yr in years) {
  dt <- fetch_bea_all_counties("CAINC1", "3", yr)
  if (!is.null(dt)) income_list[[length(income_list) + 1]] <- dt
  Sys.sleep(0.5)
}
bea_income <- rbindlist(income_list, fill = TRUE)
fwrite(bea_income, file.path(DATA_DIR, "bea_pcincome.csv"))
cat(sprintf("Per capita income saved: %d obs\n\n", nrow(bea_income)))

cat("Fetching population...\n")
pop_list <- list()
for (yr in years) {
  dt <- fetch_bea_all_counties("CAINC1", "2", yr)
  if (!is.null(dt)) pop_list[[length(pop_list) + 1]] <- dt
  Sys.sleep(0.5)
}
bea_pop <- rbindlist(pop_list, fill = TRUE)
fwrite(bea_pop, file.path(DATA_DIR, "bea_population.csv"))
cat(sprintf("Population saved: %d obs\n\n", nrow(bea_pop)))

cat("Fetching employment...\n")
emp_list <- list()
for (yr in years) {
  dt <- fetch_bea_all_counties("CAEMP25N", "10", yr)
  if (!is.null(dt)) emp_list[[length(emp_list) + 1]] <- dt
  Sys.sleep(0.5)
}
bea_emp <- rbindlist(emp_list, fill = TRUE)
fwrite(bea_emp, file.path(DATA_DIR, "bea_employment.csv"))
cat(sprintf("Employment saved: %d obs\n\n", nrow(bea_emp)))

cat("=== BEA data fetch complete ===\n")
