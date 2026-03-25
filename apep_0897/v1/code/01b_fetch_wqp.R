## 01b_fetch_wqp.R — Fetch WQP data more efficiently
## Shorter date range (2010-2020), skip states already fetched

source("00_packages.R")

DATA_DIR <- "../data"

COAL_STATES <- c("AL", "KY", "OH", "PA", "TN", "VA", "WV")
COAL_STATE_FIPS <- c("01", "21", "39", "42", "47", "51", "54")

# Check what we already have
if (file.exists(file.path(DATA_DIR, "wqp_conductance.rds"))) {
  existing <- readRDS(file.path(DATA_DIR, "wqp_conductance.rds"))
  cat("Existing WQP data:", nrow(existing), "records\n")
} else {
  existing <- NULL
}

wqp_all <- list()
if (!is.null(existing)) wqp_all[["existing"]] <- existing

# Fetch remaining states with shorter date range and smaller chunks
for (i in seq_along(COAL_STATES)) {
  st <- COAL_STATES[i]
  st_fips <- COAL_STATE_FIPS[i]

  # Skip states we might already have
  if (!is.null(existing)) {
    # Check if we have data for this state
    st_cols <- names(existing)
    state_col <- st_cols[grepl("state.*code|statecode", st_cols, ignore.case = TRUE)][1]
    if (!is.na(state_col)) {
      existing_states <- unique(gsub("US:", "", existing[[state_col]]))
      if (st_fips %in% existing_states || st %in% existing_states) {
        cat("  Skipping", st, "(already have data)\n")
        next
      }
    }
  }

  cat("Fetching WQP for", st, "(FIPS", st_fips, ")...\n")

  # Use 5-year windows to avoid timeouts
  for (yr_start in c(2010, 2015, 2020)) {
    yr_end <- min(yr_start + 4, 2023)
    cat("  Years", yr_start, "-", yr_end, "...\n")

    wqp_url <- paste0(
      "https://www.waterqualitydata.us/data/Result/search?",
      "statecode=US%3A", st_fips,
      "&characteristicName=Specific%20conductance",
      "&startDateLo=01-01-", yr_start,
      "&startDateHi=12-31-", yr_end,
      "&mimeType=csv&zip=no&sorted=no",
      "&dataProfile=narrowResult"
    )

    tryCatch({
      resp <- GET(wqp_url, timeout(300))
      if (status_code(resp) == 200) {
        txt <- content(resp, as = "text", encoding = "UTF-8")
        if (nchar(txt) > 200) {
          df <- fread(text = txt, fill = TRUE, quote = "\"")
          df <- clean_names(df)
          key <- paste0(st, "_", yr_start)
          wqp_all[[key]] <- df
          cat("    ", nrow(df), "records\n")
        } else {
          cat("    empty\n")
        }
      } else {
        cat("    HTTP", status_code(resp), "\n")
      }
    }, error = function(e) {
      cat("    ERROR:", conditionMessage(e), "\n")
    })
    Sys.sleep(1)
  }
}

if (length(wqp_all) > 0) {
  wqp_combined <- rbindlist(wqp_all, fill = TRUE)
  cat("\nTotal WQP records:", nrow(wqp_combined), "\n")
  saveRDS(wqp_combined, file.path(DATA_DIR, "wqp_conductance.rds"))
  cat("Saved to", file.path(DATA_DIR, "wqp_conductance.rds"), "\n")
} else {
  stop("FATAL: No WQP data retrieved")
}

# Also fetch Census ACS if not cached
if (!file.exists(file.path(DATA_DIR, "census_acs.rds"))) {
  cat("\n=== Fetching Census ACS ===\n")
  census_key <- Sys.getenv("CENSUS_API_KEY")
  if (nchar(census_key) > 0) census_api_key(census_key, install = FALSE)

  acs_vars <- c(
    total_pop = "B01001_001",
    median_income = "B19013_001",
    pct_poverty = "B17001_002",
    pop_black = "B02001_003",
    pop_white = "B02001_002",
    total_housing = "B25001_001",
    median_age = "B01002_001"
  )

  acs_data <- get_acs(
    geography = "county",
    variables = acs_vars,
    state = c("01", "21", "39", "42", "47", "51", "54"),
    year = 2020, survey = "acs5",
    output = "wide", geometry = FALSE
  )

  acs_data <- acs_data %>%
    mutate(
      fips = GEOID,
      state_fips = substr(GEOID, 1, 2),
      county_fips = substr(GEOID, 3, 5)
    ) %>%
    rename(
      total_pop = total_popE, median_income = median_incomeE,
      poverty_n = pct_povertyE, pop_black = pop_blackE,
      pop_white = pop_whiteE, total_housing = total_housingE,
      median_age = median_ageE
    ) %>%
    select(fips, NAME, state_fips, county_fips,
           total_pop, median_income, poverty_n, pop_black,
           pop_white, total_housing, median_age) %>%
    mutate(
      pct_poverty = poverty_n / total_pop * 100,
      pct_black = pop_black / total_pop * 100
    )

  saveRDS(acs_data, file.path(DATA_DIR, "census_acs.rds"))
  cat("Census ACS:", nrow(acs_data), "counties\n")
}

cat("\n=== Done ===\n")
