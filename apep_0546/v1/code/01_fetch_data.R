# ==============================================================================
# 01_fetch_data.R — Data Acquisition
# APEP-0546: Do Red Flag Laws Save Lives or Shift Deaths?
# ==============================================================================
# Data Sources:
#   1. CDC "Mapping Injury" (Socrata fpsi-y8tj): FA_Suicide, All_Suicide,
#      Drug_OD, FA_Homicide, All_Homicide — state × year, 2019-2024
#   2. NCHS "Leading Causes of Death" (Socrata bi63-dtpu): Total suicide
#      deaths + AADR — state × year, 1999-2017
#   3. Census Bureau ACS 5-year: State population and demographics
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ─── 1. CDC Mapping Injury (2019-2024) ──────────────────────────────────────

cat("=== Fetching CDC Mapping Injury data (2019-2024) ===\n")

# Fetch all intents for all states and years
# Exclude TTM (trailing twelve months) - only annual data
base_url <- "https://data.cdc.gov/resource/fpsi-y8tj.json"
intents <- c("FA_Suicide", "All_Suicide", "FA_Homicide", "All_Homicide", "Drug_OD")

cdc_mapping <- rbindlist(lapply(intents, function(intent) {
  where_clause <- URLencode(paste0("intent='", intent, "' AND period!='TTM'"),
                             reserved = TRUE)
  url <- paste0(
    base_url,
    "?$where=", where_clause,
    "&$select=name,period,intent,count_sup,rate",
    "&$order=name,period",
    "&$limit=50000"
  )
  resp <- GET(url)
  if (status_code(resp) != 200) {
    stop("CDC Mapping Injury API failed for intent: ", intent,
         ". HTTP ", status_code(resp))
  }
  dt <- as.data.table(fromJSON(content(resp, "text", encoding = "UTF-8")))
  cat("  ", intent, ": ", nrow(dt), " rows\n")
  dt
}))

# Clean
cdc_mapping[, `:=`(
  year = as.integer(period),
  deaths = as.integer(count_sup),
  rate = as.numeric(rate),
  state = name
)]

# Exclude "United States" total row
cdc_mapping <- cdc_mapping[state != "United States"]

# Pivot wider: one row per state-year, columns for each intent
cdc_wide <- dcast(cdc_mapping, state + year ~ intent,
                  value.var = c("deaths", "rate"))

# Construct non-firearm suicide
cdc_wide[, `:=`(
  deaths_NF_Suicide = deaths_All_Suicide - deaths_FA_Suicide,
  rate_NF_Suicide = rate_All_Suicide - rate_FA_Suicide
)]

cat("CDC Mapping Injury: ", nrow(cdc_wide), " state-year observations\n")
cat("  States: ", uniqueN(cdc_wide$state), "\n")
cat("  Years: ", paste(sort(unique(cdc_wide$year)), collapse = ", "), "\n")

fwrite(cdc_wide, file.path(data_dir, "cdc_mapping_injury.csv"))

# ─── 2. NCHS Leading Causes of Death (1999-2017) ────────────────────────────

cat("\n=== Fetching NCHS Leading Causes of Death (1999-2017) ===\n")

nchs_where <- URLencode("cause_name='Suicide' AND state!='United States'",
                         reserved = TRUE)
nchs_url <- paste0(
  "https://data.cdc.gov/resource/bi63-dtpu.json",
  "?$where=", nchs_where,
  "&$select=state,year,deaths,aadr",
  "&$order=state,year",
  "&$limit=50000"
)

resp <- GET(nchs_url)
if (status_code(resp) != 200) {
  stop("NCHS Leading Causes API failed. HTTP ", status_code(resp))
}
nchs <- as.data.table(fromJSON(content(resp, "text", encoding = "UTF-8")))

nchs[, `:=`(
  year = as.integer(year),
  deaths_All_Suicide = as.integer(deaths),
  rate_All_Suicide = as.numeric(aadr)
)]

# Keep only relevant columns
nchs <- nchs[, .(state, year, deaths_All_Suicide, rate_All_Suicide)]

cat("NCHS Leading Causes: ", nrow(nchs), " state-year observations\n")
cat("  States: ", uniqueN(nchs$state), "\n")
cat("  Years: ", paste(range(nchs$year), collapse = "-"), "\n")

fwrite(nchs, file.path(data_dir, "nchs_suicide_1999_2017.csv"))

# Note: Homicide data not available from NCHS Leading Causes (only 11 causes).
# Homicide data comes from CDC Mapping Injury (2019-2024) only.
cat("\n=== Homicide data: available from CDC Mapping Injury (2019-2024) only ===\n")

# ─── 4. ERPO Adoption Dates ─────────────────────────────────────────────────

cat("\n=== Coding ERPO adoption dates ===\n")

# Sources: Everytown for Gun Safety, RAND State Firearm Law Database,
# Giffords Law Center, state legislative records
erpo_dates <- data.table(
  state = c(
    "Connecticut", "Indiana", "California", "Washington", "Oregon",
    "Florida", "Vermont", "Maryland", "Rhode Island", "New Jersey",
    "Delaware", "Massachusetts", "Illinois",
    "Colorado", "Nevada", "Hawaii", "New York",
    "New Mexico", "Virginia",
    "Maine", "Michigan", "Minnesota"
  ),
  erpo_year = c(
    1999L, 2005L, 2014L, 2016L, 2017L,
    2018L, 2018L, 2018L, 2018L, 2018L,
    2018L, 2018L, 2018L,
    2019L, 2019L, 2019L, 2019L,
    2020L, 2020L,
    2023L, 2023L, 2024L
  ),
  wave = c(
    "Pre-Parkland", "Pre-Parkland", "Pre-Parkland", "Pre-Parkland", "Pre-Parkland",
    rep("Post-Parkland", 17)
  )
)

# Anti-ERPO states (enacted laws prohibiting or preempting ERPOs)
anti_erpo <- data.table(
  state = c("Texas", "Montana", "Oklahoma", "Tennessee",
            "West Virginia", "Wyoming"),
  anti_erpo = TRUE
)

fwrite(erpo_dates, file.path(data_dir, "erpo_adoption_dates.csv"))
fwrite(anti_erpo, file.path(data_dir, "anti_erpo_states.csv"))

cat("  ", nrow(erpo_dates), " ERPO states coded\n")
cat("  ", nrow(anti_erpo), " anti-ERPO states coded\n")

# ─── 5. State-level gun ownership proxy ─────────────────────────────────────

cat("\n=== Constructing gun ownership proxy ===\n")

# The standard proxy in the literature: firearm suicide share =
# (firearm suicides) / (all suicides). This is highly correlated (r > 0.90)
# with survey-based gun ownership (Kleck 2004, Azrael et al. 2004).
# We use 2019 data from CDC Mapping Injury as the pre-treatment baseline.

gun_proxy <- cdc_wide[year == 2019,
  .(state, gun_ownership_proxy = deaths_FA_Suicide / deaths_All_Suicide)]

# Also create a long-panel proxy from the 2005-2010 average using CDC data
# For the 1999-2017 panel, we don't have the firearm breakdown, so we use
# the 2019 cross-section as the best available proxy for historical gun ownership
# (state-level gun ownership is very stable over time — Cook & Ludwig 2006)

fwrite(gun_proxy, file.path(data_dir, "gun_ownership_proxy.csv"))
cat("  Gun ownership proxy computed from 2019 FA_Suicide share\n")
cat("  Range: ", round(range(gun_proxy$gun_ownership_proxy, na.rm = TRUE), 3), "\n")

# ─── 6. State population from Census Bureau ─────────────────────────────────

cat("\n=== Fetching state population estimates ===\n")

# Census Bureau Population Estimates API
census_key <- Sys.getenv("CENSUS_API_KEY")

# Vintage 2023 population estimates (2020-2023)
pop_url <- paste0(
  "https://api.census.gov/data/2023/pep/natmonthly?get=POP,NAME&for=state:*",
  "&MONTH=7",  # July estimates
  if (nchar(census_key) > 0) paste0("&key=", census_key) else ""
)

# Try Census API; if it fails, use the CDC death counts and rates to back out population
tryCatch({
  resp_pop <- GET(pop_url)
  if (status_code(resp_pop) == 200) {
    pop_raw <- fromJSON(content(resp_pop, "text", encoding = "UTF-8"))
    pop_dt <- as.data.table(pop_raw[-1, ])
    setnames(pop_dt, c("population", "state_name", "state_fips"))
    pop_dt[, population := as.numeric(population)]
    cat("  Census API returned population for ", nrow(pop_dt), " states\n")
  } else {
    stop("Census API returned HTTP ", status_code(resp_pop))
  }
}, error = function(e) {
  cat("  Census API failed: ", e$message, "\n")
  cat("  Backing out population from CDC data (deaths / rate * 100000)\n")
})

# Back out population from CDC data as robust fallback
# population ≈ deaths / (rate / 100000)
pop_from_cdc <- cdc_wide[, .(state, year,
  pop_est = round(deaths_All_Suicide / (rate_All_Suicide / 100000)))]
pop_from_cdc <- pop_from_cdc[!is.na(pop_est) & pop_est > 0]

fwrite(pop_from_cdc, file.path(data_dir, "state_population_estimates.csv"))
cat("  Population backed out from CDC for ", uniqueN(pop_from_cdc$state), " states\n")

# ─── DATA VALIDATION ────────────────────────────────────────────────────────

cat("\n=== Data Validation ===\n")

stopifnot("CDC Mapping Injury: expected 51 jurisdictions" =
  uniqueN(cdc_wide$state) >= 50)
stopifnot("CDC Mapping Injury: expected years 2019-2024" =
  all(2019:2024 %in% cdc_wide$year))
stopifnot("NCHS: expected 50+ states" =
  uniqueN(nchs$state) >= 50)
stopifnot("NCHS: expected years 1999-2017" =
  all(1999:2017 %in% nchs$year))
stopifnot("ERPO dates: 22 states" = nrow(erpo_dates) == 22)
stopifnot("Gun proxy: 50+ states" = nrow(gun_proxy) >= 50)

cat("Data validation passed:\n")
cat("  CDC Mapping Injury:", nrow(cdc_wide), "rows,",
    uniqueN(cdc_wide$state), "states,",
    uniqueN(cdc_wide$year), "years\n")
cat("  NCHS Leading Causes:", nrow(nchs), "rows,",
    uniqueN(nchs$state), "states,",
    uniqueN(nchs$year), "years\n")
cat("  ERPO adoption:", nrow(erpo_dates), "treated states\n")
cat("  Anti-ERPO:", nrow(anti_erpo), "states\n")
cat("DONE.\n")
