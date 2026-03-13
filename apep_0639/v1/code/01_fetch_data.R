# 01_fetch_data.R — Fetch CDC overdose mortality data and construct treatment panel
# apep_0639: Opioid Day-Supply Limits and Illicit Overdose Substitution

source("00_packages.R")

# ==============================================================================
# 1. Treatment coding: State opioid day-supply limit laws
# ==============================================================================
# Sources: PDAPS (Temple University), NCSL Prescribing Policies database,
# individual state legislation. Effective dates are when the law first applies
# to prescribers (not enactment date).

treatment_laws <- tribble(
  ~state_abbr, ~state_fips, ~law_year, ~max_days,
  # 2016 cohort
  "MA", "25", 2016, 7,
  "CT", "09", 2016, 7,
  "NY", "36", 2016, 7,
  # 2017 cohort
  "ME", "23", 2017, 7,
  "NJ", "34", 2017, 5,
  "OH", "39", 2017, 7,
  "PA", "42", 2017, 7,
  "IN", "18", 2017, 7,
  "NV", "32", 2017, 14,
  "WV", "54", 2017, 7,
  "NH", "33", 2017, 7,
  "VT", "50", 2017, 7,
  "RI", "44", 2017, 7,
  "AK", "02", 2017, 7,
  # 2018 cohort
  "FL", "12", 2018, 3,
  "TN", "47", 2018, 3,
  "AZ", "04", 2018, 5,
  "KY", "21", 2018, 3,
  "NC", "37", 2018, 5,
  "SC", "45", 2018, 7,
  "MI", "26", 2018, 7,
  "VA", "51", 2018, 7,
  "NM", "35", 2018, 7,
  "LA", "22", 2018, 7,
  "MN", "27", 2018, 7,
  "WI", "55", 2018, 5,
  "OK", "40", 2018, 7,
  "MS", "28", 2018, 7,
  "HI", "15", 2018, 7,
  "DE", "10", 2018, 7,
  "UT", "49", 2018, 7,
  "CO", "08", 2018, 7,
  # 2019 cohort
  "IL", "17", 2019, 7,
  "TX", "48", 2019, 10,
  "GA", "13", 2019, 5,
  "WA", "53", 2019, 7,
  "IA", "19", 2019, 7,
  "ND", "38", 2019, 7,
  "AR", "05", 2019, 7,
  "NE", "31", 2019, 7
)

# Never-treated states (no day-supply limit law through 2023)
# AL, CA, DC, ID, KS, MD, MT, OR, SD, WY + territories
never_treated <- tribble(
  ~state_abbr, ~state_fips,
  "AL", "01",
  "CA", "06",
  "DC", "11",
  "ID", "16",
  "KS", "20",
  "MD", "24",
  "MO", "29",
  "MT", "30",
  "OR", "41",
  "SD", "46",
  "WY", "56"
)

cat("Treatment coding: ", nrow(treatment_laws), " treated states, ",
    nrow(never_treated), " never-treated states\n")

saveRDS(treatment_laws, "../data/treatment_laws.rds")
saveRDS(never_treated, "../data/never_treated.rds")

# ==============================================================================
# 2. Fetch CDC NCHS Drug Overdose Death Counts
# ==============================================================================
# API: data.cdc.gov Socrata Open Data API
# Resource: xkb8-kh2a (NCHS Provisional Drug Overdose Death Counts)
# Fields: state, year, month, indicator, data_value

cat("Fetching CDC NCHS overdose data...\n")

# The data has multiple indicators. We need:
# "Heroin (T40.1)" — heroin deaths
# "Natural & semi-synthetic opioids (T40.2)" — Rx opioid deaths
# "Synthetic opioids, excl. methadone (T40.4)" — fentanyl deaths
# "Cocaine (T40.5)" — cocaine deaths (placebo)
# "Psychostimulants with abuse potential (T43.6)" — meth deaths (placebo)
# "Number of Drug Overdose Deaths" — total

base_url <- "https://data.cdc.gov/resource/xkb8-kh2a.json"

# Fetch all data in batches (API limit is 50,000 per request)
all_data <- list()
offset <- 0
batch_size <- 50000

repeat {
  url <- paste0(base_url, "?$limit=", batch_size, "&$offset=", offset,
                "&$order=year,month,state_name")

  resp <- httr::GET(url, httr::timeout(120))

  if (httr::status_code(resp) != 200) {
    stop("CDC API returned status ", httr::status_code(resp))
  }

  batch <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))

  if (nrow(batch) == 0) break

  all_data[[length(all_data) + 1]] <- batch
  cat("  Fetched batch: ", nrow(batch), " rows (offset=", offset, ")\n")
  offset <- offset + batch_size

  if (nrow(batch) < batch_size) break
  Sys.sleep(0.5)
}

cdc_raw <- bind_rows(all_data)
cat("Total CDC records fetched: ", nrow(cdc_raw), "\n")

stopifnot("CDC data fetch returned 0 rows" = nrow(cdc_raw) > 0)

saveRDS(cdc_raw, "../data/cdc_raw.rds")

# ==============================================================================
# 3. Fetch state population data for per-capita rates
# ==============================================================================
cat("Fetching Census population estimates...\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
key_param <- if (nchar(census_key) > 0) paste0("&key=", census_key) else ""

# PEP (Population Estimates Program) for 2015-2023
pop_data <- list()

for (yr in 2015:2023) {
  # Use ACS 1-year total population (B01003_001E)
  url <- paste0("https://api.census.gov/data/", yr,
                "/acs/acs1?get=NAME,B01003_001E&for=state:*", key_param)

  resp <- tryCatch(
    httr::GET(url, httr::timeout(60)),
    error = function(e) NULL
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    cat("  Warning: Could not fetch population for ", yr, "\n")
    next
  }

  raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
  names(df) <- raw[1, ]
  df$year <- yr
  df$population <- as.numeric(df$B01003_001E)
  df$state_fips <- df$state
  pop_data[[length(pop_data) + 1]] <- df[, c("NAME", "state_fips", "year", "population")]

  cat("  Population ", yr, ": ", nrow(df), " states\n")
  Sys.sleep(0.3)
}

pop_df <- bind_rows(pop_data)
cat("Population data: ", nrow(pop_df), " state-year records\n")

stopifnot("Population data is empty" = nrow(pop_df) > 0)

saveRDS(pop_df, "../data/population.rds")

cat("\n=== Data fetch complete ===\n")
cat("Files saved to data/:\n")
cat("  treatment_laws.rds\n  never_treated.rds\n  cdc_raw.rds\n  population.rds\n")
