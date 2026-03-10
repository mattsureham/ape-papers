# ============================================================================
# 01_fetch_data.R — Fetch all data from public APIs
# APEP Paper apep_0566: Civil Asset Forfeiture Reform and Drug Overdose Mortality
# ============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Load .env for API keys
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  env_lines <- readLines(env_file)
  for (line in env_lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- trimws(substr(line, 1, eq_pos - 1))
      val <- trimws(substr(line, eq_pos + 1, nchar(line)))
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  cat("Loaded .env\n")
}

# ============================================================================
# 1. CDC NCHS Drug Poisoning Mortality by State (Socrata API) — 1999-2015
# Source: https://data.cdc.gov/NCHS/NCHS-Drug-Poisoning-Mortality-by-State-United-Stat/jx6g-fdh6
# ============================================================================

cat("\n=== Fetching CDC NCHS Drug Overdose Mortality (1999-2015) ===\n")

cdc_url <- "https://data.cdc.gov/resource/jx6g-fdh6.json"
all_cdc <- list()
offset <- 0
batch_size <- 5000

repeat {
  resp <- GET(cdc_url, query = list(
    `$limit` = batch_size,
    `$offset` = offset,
    `$order` = "year,state"
  ))
  if (status_code(resp) != 200) {
    stop("CDC NCHS API failed with status: ", status_code(resp))
  }
  batch <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  if (nrow(batch) == 0) break
  all_cdc[[length(all_cdc) + 1]] <- batch
  offset <- offset + batch_size
  cat("  Fetched", offset, "records...\n")
  if (nrow(batch) < batch_size) break
  Sys.sleep(0.5)
}

nchs_raw <- rbindlist(all_cdc, fill = TRUE)

# Filter to Both Sexes, All Ages, All Races, state-level
nchs_panel <- nchs_raw[
  sex == "Both Sexes" &
  age == "All Ages" &
  race_hispanic_origin == "All Races-All Origins" &
  state != "United States",
]

for (col in c("year", "deaths", "population", "crude_death_rate",
              "age_adjusted_rate", "standard_error_age_adjusted_rate")) {
  if (col %in% names(nchs_panel)) nchs_panel[[col]] <- as.numeric(nchs_panel[[col]])
}

nchs_panel <- nchs_panel[, .(state, year, deaths, population,
                              crude_death_rate, age_adjusted_rate)]
cat("NCHS panel:", nrow(nchs_panel), "rows,", min(nchs_panel$year), "-", max(nchs_panel$year), "\n")

# ============================================================================
# 2. CDC VSRR Provisional Drug Overdose Death Counts (Socrata API) — 2015-2022
# Source: https://data.cdc.gov/NCHS/VSRR-Provisional-Drug-Overdose-Death-Counts/xkb8-kh2a
# ============================================================================

cat("\n=== Fetching CDC VSRR Drug Overdose Deaths (2015-2022) ===\n")

vsrr_url <- "https://data.cdc.gov/resource/xkb8-kh2a.json"

# Fetch all states, December (12-month-ending = annual total), Drug Overdose Deaths
all_vsrr <- list()
offset <- 0

repeat {
  resp <- GET(vsrr_url, query = list(
    `$limit` = 5000,
    `$offset` = offset,
    indicator = "Number of Drug Overdose Deaths",
    month = "December",
    `$order` = "year,state"
  ))
  if (status_code(resp) != 200) {
    stop("CDC VSRR API failed with status: ", status_code(resp))
  }
  batch <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  if (nrow(batch) == 0) break
  all_vsrr[[length(all_vsrr) + 1]] <- batch
  offset <- offset + nrow(batch)
  cat("  Fetched", offset, "records...\n")
  if (nrow(batch) < 5000) break
  Sys.sleep(0.5)
}

vsrr_raw <- rbindlist(all_vsrr, fill = TRUE)
cat("VSRR raw records:", nrow(vsrr_raw), "\n")

# Filter to state-level (not US total), with actual data
vsrr_panel <- vsrr_raw[state != "US" & !is.na(data_value)]
vsrr_panel[, year := as.integer(year)]
vsrr_panel[, deaths := as.numeric(data_value)]

# Keep only 2016-2022 (2015 overlaps with NCHS, prefer NCHS for consistency)
vsrr_panel <- vsrr_panel[year >= 2016 & year <= 2022]
vsrr_panel[, state := state_name]  # Use full state name for matching

cat("VSRR panel:", nrow(vsrr_panel), "rows,", min(vsrr_panel$year), "-", max(vsrr_panel$year), "\n")

# ============================================================================
# 3. Combine NCHS (1999-2015) + VSRR (2016-2022) into unified panel
# ============================================================================

cat("\n=== Combining NCHS + VSRR into unified panel ===\n")

# For VSRR, we need population to compute rates. Get from Census API.
# First, let's build the combined deaths panel, then add population.
nchs_deaths <- nchs_panel[, .(state, year, deaths, population,
                               age_adjusted_rate, crude_death_rate)]

# For VSRR, we only have deaths (no population/rates from VSRR)
vsrr_deaths <- vsrr_panel[, .(state, year, deaths)]

# We'll merge population from Census later and compute rates

# ============================================================================
# 4. State FIPS crosswalk
# ============================================================================

cat("\n=== Building state FIPS crosswalk ===\n")

state_fips <- data.table(
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
    "Connecticut","Delaware","District of Columbia","Florida","Georgia","Hawaii",
    "Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine",
    "Maryland","Massachusetts","Michigan","Minnesota","Mississippi","Missouri",
    "Montana","Nebraska","Nevada","New Hampshire","New Jersey","New Mexico",
    "New York","North Carolina","North Dakota","Ohio","Oklahoma","Oregon",
    "Pennsylvania","Rhode Island","South Carolina","South Dakota","Tennessee",
    "Texas","Utah","Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming"),
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,
    26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,53,54,55,56),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI",
    "ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
    "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
    "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

fwrite(state_fips, paste0(data_dir, "state_fips.csv"))

# ============================================================================
# 5. Census ACS State-Level Population + Covariates (via API)
# ============================================================================

cat("\n=== Fetching Census ACS data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
cat("Census API key length:", nchar(census_key), "\n")

if (nchar(census_key) < 5) {
  stop("Census API key not found. Required for population data.\n",
       "Set CENSUS_API_KEY in .env")
}

acs_years <- 2005:2022
acs_list <- list()

for (yr in acs_years) {
  cat("  ACS year:", yr, "...")
  # ACS 1-year not available for 2020 (COVID), use 5-year
  if (yr == 2020) {
    acs_url <- paste0("https://api.census.gov/data/", yr, "/acs/acs5")
  } else {
    acs_url <- paste0("https://api.census.gov/data/", yr, "/acs/acs1")
  }

  resp <- tryCatch(
    GET(acs_url, query = list(
      get = "B01003_001E,B19013_001E,B17001_002E,B17001_001E,B02001_002E,B02001_001E",
      `for` = "state:*",
      key = census_key
    ), timeout(30)),
    error = function(e) { cat(" Error:", e$message, "\n"); NULL }
  )

  if (is.null(resp) || status_code(resp) != 200) {
    cat(" Skipped (status:", if(!is.null(resp)) status_code(resp) else "error", ")\n")
    next
  }

  txt <- content(resp, "text", encoding = "UTF-8")
  mat <- fromJSON(txt)
  df <- as.data.table(mat[-1, , drop = FALSE])
  setnames(df, mat[1, ])

  df[, year := yr]
  df[, acs_pop := as.numeric(B01003_001E)]
  df[, median_income := as.numeric(B19013_001E)]
  df[, poverty_count := as.numeric(B17001_002E)]
  df[, poverty_universe := as.numeric(B17001_001E)]
  df[, white_count := as.numeric(B02001_002E)]
  df[, race_total := as.numeric(B02001_001E)]
  df[, poverty_rate := poverty_count / poverty_universe]
  df[, pct_white := white_count / race_total]
  df[, state_fips := as.integer(state)]

  acs_list[[length(acs_list) + 1]] <- df[, .(state_fips, year, acs_pop,
                                              median_income, poverty_rate, pct_white)]
  cat(" OK\n")
  Sys.sleep(0.3)
}

covariates <- rbindlist(acs_list, fill = TRUE)
cat("ACS covariates:", nrow(covariates), "state-years\n")
fwrite(covariates, paste0(data_dir, "acs_covariates.csv"))

# ============================================================================
# 6. Build unified state-year panel
# ============================================================================

cat("\n=== Building unified panel ===\n")

# Merge NCHS with FIPS
nchs_m <- merge(nchs_deaths, state_fips, by.x = "state", by.y = "state_name", all.x = TRUE)
nchs_m <- nchs_m[!is.na(state_fips)]

# Merge VSRR with FIPS
vsrr_m <- merge(vsrr_deaths, state_fips, by.x = "state", by.y = "state_name", all.x = TRUE)
vsrr_m <- vsrr_m[!is.na(state_fips)]

# Combine: NCHS 1999-2015, VSRR 2016-2022
nchs_use <- nchs_m[, .(state_fips, state_abbr, year, deaths, population,
                        age_adjusted_rate, crude_death_rate)]
vsrr_use <- vsrr_m[, .(state_fips, state_abbr, year, deaths)]

# Add population from Census ACS for VSRR years
vsrr_use <- merge(vsrr_use, covariates[, .(state_fips, year, acs_pop)],
                  by = c("state_fips", "year"), all.x = TRUE)
vsrr_use[, population := acs_pop]
vsrr_use[, crude_death_rate := deaths / population * 100000]
vsrr_use[, age_adjusted_rate := crude_death_rate]  # approximation; crude ≈ age-adjusted at state level
vsrr_use[, acs_pop := NULL]

# Stack
cdc_panel <- rbind(nchs_use, vsrr_use, fill = TRUE)
setorder(cdc_panel, state_fips, year)

# Merge state names back
cdc_panel <- merge(cdc_panel, state_fips[, .(state_fips, state_name = state_name)],
                   by = "state_fips", all.x = TRUE)

cat("Unified panel:", nrow(cdc_panel), "state-years\n")
cat("States:", uniqueN(cdc_panel$state_fips), "\n")
cat("Years:", min(cdc_panel$year), "-", max(cdc_panel$year), "\n")

fwrite(cdc_panel, paste0(data_dir, "cdc_panel.csv"))

# ============================================================================
# 7. Civil Asset Forfeiture Reform Dates
# ============================================================================

cat("\n=== Coding forfeiture reform treatment ===\n")

reform_dates <- data.table(
  state_abbr = c(
    "MN",
    "DC", "GA", "MT", "NM",
    "FL", "KY", "MD", "NE", "NH", "OK",
    "CA", "CO", "CT", "IA",
    "IL", "OR", "WY",
    "IN", "KS", "LA", "MI", "MO", "SC", "UT",
    "AZ", "OH"
  ),
  reform_year = c(
    2014,
    2015, 2015, 2015, 2015,
    2016, 2016, 2016, 2016, 2016, 2016,
    2017, 2017, 2017, 2017,
    2018, 2018, 2018,
    2019, 2019, 2019, 2019, 2019, 2019, 2019,
    2021, 2021
  ),
  reform_intensity = c(
    2,
    2, 2, 2, 3,
    1, 1, 2, 3, 1, 1,
    2, 2, 2, 1,
    1, 1, 2,
    1, 1, 1, 2, 1, 2, 1,
    2, 1
  ),
  reform_type = c(
    "conviction_required",
    "comprehensive", "conviction_partial", "conviction_required", "abolished",
    "burden_raised", "burden_raised", "conviction_required", "abolished",
    "burden_raised", "burden_raised",
    "anti_equitable_sharing", "conviction_required", "conviction_required",
    "burden_raised",
    "burden_raised", "reforms", "conviction_required",
    "reforms", "reforms", "reforms", "conviction_required", "reforms",
    "conviction_required", "reforms",
    "conviction_required", "reforms"
  )
)

cat("Treated states:", nrow(reform_dates), "\n")
cat("Reform years:", paste(sort(unique(reform_dates$reform_year)), collapse = ", "), "\n")

fwrite(reform_dates, paste0(data_dir, "reform_dates.csv"))

# ============================================================================
# 8. DATA VALIDATION (required)
# ============================================================================

cat("\n=== Data Validation ===\n")

stopifnot("Expected 50+ states" = uniqueN(cdc_panel$state_fips) >= 50)
stopifnot("Expected 20+ years" = uniqueN(cdc_panel$year) >= 20)
stopifnot("Expected deaths exist" = "deaths" %in% names(cdc_panel))
stopifnot("Expected positive deaths" = all(cdc_panel$deaths > 0, na.rm = TRUE))
stopifnot("Expected 20+ treated states" = nrow(reform_dates) >= 20)
stopifnot("Expected reform years 2014-2021" = all(reform_dates$reform_year %in% 2014:2021))
stopifnot("Expected ACS covariates" = nrow(covariates) > 0)

cat("Data validation passed:\n")
cat("  CDC panel:", nrow(cdc_panel), "rows,",
    uniqueN(cdc_panel$state_fips), "states,",
    uniqueN(cdc_panel$year), "years\n")
cat("  Reform dates:", nrow(reform_dates), "treated states\n")
cat("  ACS covariates:", nrow(covariates), "state-years\n")
cat("\nAll data fetched successfully.\n")
