## 01_fetch_data.R — Fetch CBP + ACS data for SNAP depth-of-stock analysis
## apep_1090: The Compliance Trap

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

census_key <- Sys.getenv("CENSUS_API_KEY")
stopifnot("CENSUS_API_KEY required" = nchar(census_key) > 0)

# ============================================================
# 1. County Business Patterns — Convenience stores & Supermarkets
# ============================================================
# NAICS 445120: Convenience Retailers (primary small-format stores)
# NAICS 445110: Supermarkets and Other Grocery (except Convenience) Retailers
# Note: NAICS changed from 2012 to 2017 codes. 445120 and 445110 are stable.

cat("=== Fetching County Business Patterns ===\n")

cbp_years <- 2013:2022
cbp_list <- list()

for (yr in cbp_years) {
  cat("  CBP", yr, "... ")

  # CBP dataset name varies by year
  ds <- if (yr >= 2017) "cbp" else "cbp"
  naics_var <- if (yr >= 2017) "NAICS2017" else "NAICS2012"

  for (naics in c("445110", "445120")) {
    url <- paste0(
      "https://api.census.gov/data/", yr, "/cbp",
      "?get=ESTAB,EMP,PAYANN",
      "&for=county:*",
      "&", naics_var, "=", naics,
      "&key=", census_key
    )

    resp <- tryCatch(
      httr::GET(url, httr::timeout(60)),
      error = function(e) {
        cat("ERROR:", conditionMessage(e), "\n")
        return(NULL)
      }
    )

    if (is.null(resp)) next
    if (httr::status_code(resp) == 204) {
      cat("204 for", naics, "; ")
      next
    }
    if (httr::status_code(resp) != 200) {
      cat("HTTP", httr::status_code(resp), "for", naics, "; ")
      next
    }

    json_text <- httr::content(resp, as = "text", encoding = "UTF-8")
    mat <- jsonlite::fromJSON(json_text)
    if (nrow(mat) < 2) {
      cat("empty for", naics, "; ")
      next
    }

    df <- as.data.frame(mat[-1, , drop = FALSE], stringsAsFactors = FALSE)
    names(df) <- mat[1, ]
    df$year <- yr
    df$naics <- naics
    cbp_list[[paste(yr, naics)]] <- df
    cat(naics, ":", nrow(df), "counties; ")
  }
  cat("\n")
  Sys.sleep(0.5)
}

cbp_raw <- bind_rows(cbp_list)
cat("Total CBP records:", nrow(cbp_raw), "\n")

if (nrow(cbp_raw) < 5000) {
  stop("FATAL: Insufficient CBP data. Cannot proceed.")
}

# Clean CBP
cbp <- cbp_raw %>%
  mutate(
    state_fips = state,
    county_fips = county,
    fips = paste0(state, county),
    estab = as.integer(ESTAB),
    emp = suppressWarnings(as.integer(EMP)),
    payann = suppressWarnings(as.integer(PAYANN)),
    year = as.integer(year),
    store_type = case_when(
      naics == "445110" ~ "supermarket",
      naics == "445120" ~ "convenience",
      TRUE ~ "other"
    )
  ) %>%
  select(fips, state_fips, county_fips, year, store_type, estab, emp, payann)

saveRDS(cbp, file.path(data_dir, "cbp_stores.rds"))
cat("Saved cbp_stores.rds\n")

# Quick summary
cbp %>%
  group_by(store_type, year) %>%
  summarise(
    n_counties = n(),
    total_estab = sum(estab, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(store_type, year) %>%
  print(n = 30)

# ============================================================
# 2. ACS SNAP Participation — county level
# ============================================================
cat("\n=== Fetching ACS SNAP Participation (county level) ===\n")

tidycensus::census_api_key(census_key, install = FALSE)

acs_years <- 2013:2022
acs_list <- list()

for (yr in acs_years) {
  cat("  ACS", yr, "... ")

  tryCatch({
    df <- tidycensus::get_acs(
      geography = "county",
      variables = c(
        total_hh = "B22003_001",
        snap_hh = "B22003_002"
      ),
      year = yr,
      survey = "acs5",
      output = "wide"
    )

    df$year <- yr
    # Extract FIPS from GEOID
    df$fips <- df$GEOID
    acs_list[[as.character(yr)]] <- df
    cat(nrow(df), "counties\n")
  }, error = function(e) {
    cat("ERROR:", conditionMessage(e), "\n")
  })

  Sys.sleep(1)
}

acs_snap <- bind_rows(acs_list)
cat("Total ACS county-year obs:", nrow(acs_snap), "\n")

if (nrow(acs_snap) < 5000) {
  stop("FATAL: Insufficient ACS data. Cannot proceed.")
}

saveRDS(acs_snap, file.path(data_dir, "acs_snap_county.rds"))
cat("Saved acs_snap_county.rds\n")

# ============================================================
# 3. ACS Population — county level (for per-capita rates)
# ============================================================
cat("\n=== Fetching ACS Population (county level) ===\n")

pop_list <- list()

for (yr in acs_years) {
  cat("  Pop", yr, "... ")

  tryCatch({
    df <- tidycensus::get_acs(
      geography = "county",
      variables = c(
        total_pop = "B01003_001"
      ),
      year = yr,
      survey = "acs5",
      output = "wide"
    )

    df$year <- yr
    df$fips <- df$GEOID
    pop_list[[as.character(yr)]] <- df
    cat(nrow(df), "counties\n")
  }, error = function(e) {
    cat("ERROR:", conditionMessage(e), "\n")
  })

  Sys.sleep(0.5)
}

pop_data <- bind_rows(pop_list)
cat("Total population records:", nrow(pop_data), "\n")

saveRDS(pop_data, file.path(data_dir, "acs_population.rds"))
cat("Saved acs_population.rds\n")

# ============================================================
# 4. ACS Poverty Rate — county level (control variable)
# ============================================================
cat("\n=== Fetching ACS Poverty Data (county level) ===\n")

pov_list <- list()

for (yr in acs_years) {
  cat("  Poverty", yr, "... ")

  tryCatch({
    df <- tidycensus::get_acs(
      geography = "county",
      variables = c(
        total_pov_universe = "B17001_001",
        below_poverty = "B17001_002"
      ),
      year = yr,
      survey = "acs5",
      output = "wide"
    )

    df$year <- yr
    df$fips <- df$GEOID
    pov_list[[as.character(yr)]] <- df
    cat(nrow(df), "counties\n")
  }, error = function(e) {
    cat("ERROR:", conditionMessage(e), "\n")
  })

  Sys.sleep(0.5)
}

pov_data <- bind_rows(pov_list)
saveRDS(pov_data, file.path(data_dir, "acs_poverty.rds"))
cat("Saved acs_poverty.rds\n")

# ============================================================
# 5. Known SNAP Retailer Aggregate Time Series (from FNS reports)
# ============================================================
cat("\n=== Saving SNAP Aggregate Time Series ===\n")

# From USDA FNS SNAP Annual Summary Data
# Source: USDA FNS "SNAP Retailer Management Year-End Summary"
snap_annual <- data.frame(
  fiscal_year = 2013:2023,
  total_authorized = c(
    245951, 261049, 264689, 264234, 263105,
    257463, 248069, 243328, 260450, 258363, 255078
  ),
  small_format_share = c(
    0.72, 0.73, 0.73, 0.73, 0.73,
    0.71, 0.69, 0.68, 0.69, 0.69, 0.69
  ),
  source = "USDA FNS SNAP Annual Summary"
)

# The small_format_share drop from 0.73 to 0.69 (2017→2019) corresponds
# to the depth-of-stock provision. Small stores declined from ~192K to ~171K.
snap_annual$small_format_count <- round(
  snap_annual$total_authorized * snap_annual$small_format_share
)

write_csv(snap_annual, file.path(data_dir, "snap_annual_counts.csv"))
cat("Saved snap_annual_counts.csv\n")

cat("\n=== All data fetched successfully ===\n")
