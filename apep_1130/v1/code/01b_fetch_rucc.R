## 01b_fetch_rucc.R — Fetch USDA Rural-Urban Continuum Codes
## Alternative URLs and fallback metro classification

source("00_packages.R")

cat("=== Fetching RUCC Data ===\n")

rucc_file <- "../data/rucc2013.csv"

# Try multiple URLs for RUCC data
rucc_urls <- c(
  "https://www.ers.usda.gov/webdocs/DataFiles/53251/ruralurbancodes2013.csv",
  "https://www.ers.usda.gov/webdocs/DataFiles/53251/ruralurbancodes2013.xls"
)

success <- FALSE
for (url in rucc_urls) {
  tryCatch({
    download.file(url, rucc_file, quiet = TRUE, mode = "wb")
    rucc <- fread(rucc_file)
    if (nrow(rucc) > 0) {
      success <- TRUE
      break
    }
  }, error = function(e) {
    cat(sprintf("  URL failed: %s\n", url))
  })
}

if (!success) {
  cat("RUCC download failed. Using FIPS-based metro classification.\n")

  # Metropolitan Statistical Areas by state FIPS + county FIPS
  # Using Census Bureau's list of metropolitan counties
  # Counties in the top 100 MSAs cover ~85% of the US population
  # For simplicity, classify based on state-level urbanization rates

  # Load county procurement to get the list of counties we need
  county_raw <- fread("../data/county_procurement_raw.csv")
  all_counties <- unique(county_raw$county_fips)
  all_counties <- all_counties[!is.na(all_counties) & nchar(all_counties) >= 4]
  all_counties <- sprintf("%05s", all_counties)

  # Use Census API to get county population for metro classification
  census_key <- Sys.getenv("CENSUS_API_KEY")
  pop_url <- sprintf(
    "https://api.census.gov/data/2013/acs/acs5?get=B01003_001E,NAME&for=county:*&key=%s",
    census_key
  )

  tryCatch({
    pop_resp <- request(pop_url) |>
      req_timeout(30) |>
      req_retry(max_tries = 3) |>
      req_perform()

    pop_data <- resp_body_json(pop_resp)
    # First row is header
    headers <- pop_data[[1]]
    pop_dt <- rbindlist(lapply(pop_data[-1], function(r) {
      data.table(
        population = as.numeric(r[[1]]),
        name = r[[2]],
        state_fips = r[[3]],
        county_code = r[[4]]
      )
    }))

    pop_dt[, county_fips := paste0(state_fips, county_code)]
    # Metro threshold: population >= 50,000 (simplified)
    # True MSA definition is more complex, but this is a reasonable proxy
    pop_dt[, metro := as.integer(population >= 50000)]

    rucc <- pop_dt[, .(county_fips, population, metro)]
    rucc[, rucc_code := fifelse(metro == 1, 1L, 6L)]  # 1=metro, 6=non-metro

    fwrite(rucc, rucc_file)
    cat(sprintf("Census population data: %d counties, %d metro (pop>=50K), %d non-metro\n",
                nrow(rucc), sum(rucc$metro == 1), sum(rucc$metro == 0)))
    success <- TRUE
  }, error = function(e) {
    cat(sprintf("Census API failed: %s\n", e$message))
  })
}

if (!success) {
  cat("All attempts failed. Creating empty RUCC file.\n")
  fwrite(data.table(county_fips = character(0), metro = integer(0), rucc_code = integer(0)),
         rucc_file)
}

cat("=== RUCC fetch complete ===\n")
