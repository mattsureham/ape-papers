## 01_fetch_data.R — Fetch CDC VSRR overdose data + Census population
## APEP Paper apep_0584: Oregon Drug Decriminalization Symmetric Test

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. CDC VSRR Provisional Drug Overdose Death Counts
# ============================================================
# Socrata endpoint: xkb8-kh2a
# Returns 12-month-ending death counts by state × month

cat("Fetching CDC VSRR overdose data...\n")

# Indicators to fetch
indicators <- c(
  "Number of Drug Overdose Deaths",
  "Synthetic opioids, excl. methadone (T40.4)",
  "Heroin (T40.1)",
  "Cocaine (T40.5)",
  "Psychostimulants with abuse potential (T43.6)"
)

all_data <- list()

for (ind in indicators) {
  cat(sprintf("  Fetching: %s\n", ind))

  offset <- 0
  batch_size <- 50000
  ind_data <- list()

  repeat {
    url <- sprintf(
      "https://data.cdc.gov/resource/xkb8-kh2a.json?$where=%s&$limit=%d&$offset=%d&$order=year,month",
      URLencode(sprintf("indicator='%s'", ind), reserved = TRUE),
      batch_size,
      offset
    )

    resp <- httr::GET(url, httr::timeout(120))

    if (httr::status_code(resp) != 200) {
      stop(sprintf("CDC API returned status %d for indicator: %s",
                    httr::status_code(resp), ind))
    }

    batch <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"),
                                 flatten = TRUE)

    if (nrow(batch) == 0) break

    ind_data[[length(ind_data) + 1]] <- batch
    offset <- offset + batch_size

    if (nrow(batch) < batch_size) break
  }

  combined <- bind_rows(ind_data)
  cat(sprintf("    Got %d rows\n", nrow(combined)))
  all_data[[ind]] <- combined
}

vsrr_raw <- bind_rows(all_data)
cat(sprintf("Total VSRR rows: %d\n", nrow(vsrr_raw)))

fwrite(vsrr_raw, file.path(data_dir, "vsrr_raw.csv"))
cat("Saved vsrr_raw.csv\n")

# ============================================================
# 2. Census Population Estimates (state-level, annual)
# ============================================================
cat("\nFetching Census population estimates...\n")

# Fetch 2015-2019 (vintage 2019)
pop_data <- list()

# Vintage 2019 covers 2010-2019
url_2019 <- "https://api.census.gov/data/2019/pep/charagegroups?get=NAME,POP&for=state:*&HITEFLAG=0"
resp_2019 <- httr::GET(url_2019, httr::timeout(60))
if (httr::status_code(resp_2019) == 200) {
  raw_2019 <- jsonlite::fromJSON(httr::content(resp_2019, "text", encoding = "UTF-8"))
  df_2019 <- as.data.frame(raw_2019[-1, ], stringsAsFactors = FALSE)
  names(df_2019) <- raw_2019[1, ]
  df_2019$year <- 2019
  df_2019$POP <- as.numeric(df_2019$POP)
  pop_data[["2019"]] <- df_2019
  cat(sprintf("  2019 vintage: %d states\n", nrow(df_2019)))
}

# Try multiple Census API endpoints for population
# Vintage 2023 covers 2020-2023
url_2023 <- "https://api.census.gov/data/2023/pep/charagegroups?get=NAME,POP&for=state:*&HITEFLAG=0"
resp_2023 <- httr::GET(url_2023, httr::timeout(60))
if (httr::status_code(resp_2023) == 200) {
  raw_2023 <- jsonlite::fromJSON(httr::content(resp_2023, "text", encoding = "UTF-8"))
  df_2023 <- as.data.frame(raw_2023[-1, ], stringsAsFactors = FALSE)
  names(df_2023) <- raw_2023[1, ]
  df_2023$year <- 2023
  df_2023$POP <- as.numeric(df_2023$POP)
  pop_data[["2023"]] <- df_2023
  cat(sprintf("  2023 vintage: %d states\n", nrow(df_2023)))
}

# If Census API is problematic, use a simpler approach:
# fetch annual estimates from a reliable endpoint
# Try the ACS 1-year estimates as backup
census_years <- 2015:2024
pop_all <- list()

for (yr in census_years) {
  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs1?get=NAME,B01003_001E&for=state:*",
    min(yr, 2023)  # ACS available through 2023
  )
  resp <- tryCatch(
    httr::GET(url, httr::timeout(30)),
    error = function(e) NULL
  )

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
    names(df) <- raw[1, ]
    df$year <- yr
    df$population <- as.numeric(df$B01003_001E)
    df$state_fips <- df$state
    pop_all[[as.character(yr)]] <- df[, c("NAME", "state_fips", "year", "population")]
    cat(sprintf("  ACS %d: %d states\n", yr, nrow(df)))
  }
}

if (length(pop_all) == 0) {
  stop("Failed to fetch Census population data from any endpoint. Cannot proceed.")
}

pop_df <- bind_rows(pop_all)

# For years without ACS data, interpolate/extrapolate
# 2024-2025: use 2023 estimates
if (!2024 %in% pop_df$year) {
  pop_2024 <- pop_df %>% filter(year == 2023) %>% mutate(year = 2024)
  pop_df <- bind_rows(pop_df, pop_2024)
}
if (!2025 %in% pop_df$year) {
  pop_2025 <- pop_df %>% filter(year == 2023) %>% mutate(year = 2025)
  pop_df <- bind_rows(pop_df, pop_2025)
}

fwrite(pop_df, file.path(data_dir, "census_population.csv"))
cat(sprintf("\nSaved census_population.csv: %d rows\n", nrow(pop_df)))

# ============================================================
# 3. Data Validation
# ============================================================
cat("\n=== DATA VALIDATION ===\n")

# Validate VSRR
vsrr_states <- n_distinct(vsrr_raw$state_name, na.rm = TRUE)
stopifnot("Expected 50+ jurisdictions in VSRR" = vsrr_states >= 50)

oregon_rows <- vsrr_raw %>%
  filter(state_name == "Oregon", indicator == "Number of Drug Overdose Deaths")
stopifnot("Expected 50+ Oregon observations" = nrow(oregon_rows) >= 50)

# Validate population
pop_states <- n_distinct(pop_df$state_fips)
stopifnot("Expected 50+ states in population data" = pop_states >= 50)

cat(sprintf("VSRR: %d rows, %d jurisdictions\n", nrow(vsrr_raw), vsrr_states))
cat(sprintf("Oregon VSRR: %d monthly observations\n", nrow(oregon_rows)))
cat(sprintf("Population: %d rows, %d states, years %d-%d\n",
            nrow(pop_df), pop_states, min(pop_df$year), max(pop_df$year)))
cat("Data validation passed.\n")
