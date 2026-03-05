# =============================================================================
# 01_fetch_data.R — Pills and Diplomas (apep_0510)
# =============================================================================
# Fetches all data sources:
#   1. IPEDS (local DuckDB)
#   2. PDMP mandate dates (hand-coded from literature)
#   3. CDC drug poisoning mortality (Socrata API)
#   4. VSRR provisional overdose deaths by drug type (Socrata API)
#   5. State-level controls (FRED API)
#   6. Concurrent opioid policy dates (hand-coded from literature)
# =============================================================================

source("code/00_packages.R")

# =============================================================================
# 1. IPEDS DATA (local DuckDB)
# =============================================================================
cat("=== Fetching IPEDS data ===\n")

# Try multiple relative paths to find IPEDS DuckDB
ipeds_candidates <- c(
  "../../../../data/ipeds/ipeds.duckdb",
  "../../../data/ipeds/ipeds.duckdb",
  "../../data/ipeds/ipeds.duckdb"
)
if (nzchar(Sys.getenv("CLAUDE_PROJECT_DIR"))) {
  ipeds_candidates <- c(ipeds_candidates,
    file.path(Sys.getenv("CLAUDE_PROJECT_DIR"), "data/ipeds/ipeds.duckdb"))
}
ipeds_path <- NULL
for (p in ipeds_candidates) {
  if (file.exists(p)) { ipeds_path <- normalizePath(p); break }
}
if (is.null(ipeds_path)) stop("IPEDS DuckDB not found. Searched: ", paste(ipeds_candidates, collapse = ", "))
stopifnot("IPEDS DuckDB not found" = file.exists(ipeds_path))

con <- dbConnect(duckdb(), dbdir = ipeds_path, read_only = TRUE)

# 1a. Institutional directory (hd) — state, sector, level, coordinates
hd <- as.data.table(dbGetQuery(con, "
  SELECT unitid, year, institution_name, state, sector, control, level,
         hbcu, latitude, longitude, fips_state, carnegie_basic
  FROM hd
  WHERE year BETWEEN 2000 AND 2023
"))
cat("  hd:", nrow(hd), "rows\n")

# 1b. Retention rates (ef_d)
efd <- as.data.table(dbGetQuery(con, "
  SELECT unitid, year,
         CAST(ret_pcf AS DOUBLE) AS ret_pcf,
         CAST(ret_pcp AS DOUBLE) AS ret_pcp
  FROM ef_d
  WHERE year BETWEEN 2000 AND 2023
"))
cat("  ef_d:", nrow(efd), "rows\n")

# 1c. Graduation rates (gr) — 150% normal time
gr <- as.data.table(dbGetQuery(con, "
  SELECT unitid, year,
         CAST(grtotlt AS DOUBLE) AS grtotlt,
         CAST(grtotlm AS DOUBLE) AS grtotlm,
         CAST(grtotlw AS DOUBLE) AS grtotlw,
         chrtstat, section, cohort, grtype
  FROM gr
  WHERE year BETWEEN 2000 AND 2023
"))
cat("  gr:", nrow(gr), "rows\n")

# 1d. Fall enrollment (ef_a) — total and by level
efa <- as.data.table(dbGetQuery(con, "
  SELECT unitid, year, efalevel,
         CAST(eftotlt AS DOUBLE) AS eftotlt,
         CAST(eftotlm AS DOUBLE) AS eftotlm,
         CAST(eftotlw AS DOUBLE) AS eftotlw
  FROM ef_a
  WHERE year BETWEEN 2000 AND 2023
"))
cat("  ef_a:", nrow(efa), "rows\n")

# 1e. Completions (c_a) — total by CIP code
ca <- as.data.table(dbGetQuery(con, "
  SELECT unitid, year, cipcode, award_level,
         CAST(COALESCE(ctotalt, crace24, crace15 + crace16) AS DOUBLE) AS ctotalt
  FROM c_a
  WHERE year BETWEEN 2000 AND 2024
    AND CAST(cipcode AS VARCHAR) LIKE '99%'
"))
cat("  c_a (total):", nrow(ca), "rows\n")

# 1f. Financial aid (sfa)
sfa <- as.data.table(dbGetQuery(con, "
  SELECT unitid, year,
         CAST(scfa2 AS DOUBLE) AS pct_any_aid,
         CAST(scugrad AS DOUBLE) AS ug_enrolled_sfa
  FROM sfa
  WHERE year BETWEEN 2000 AND 2023
"))
cat("  sfa:", nrow(sfa), "rows\n")

dbDisconnect(con, shutdown = TRUE)
cat("  IPEDS data fetched successfully.\n\n")

# =============================================================================
# 2. PDMP MANDATE DATES (hand-coded from Gunadi 2023, Buchmueller & Carey 2018)
# =============================================================================
cat("=== Coding PDMP mandate dates ===\n")

# Source: Gunadi (2023, BMC Public Health) Supplementary Table S1
# Cross-referenced with Buchmueller & Carey (2018, AEJ:EP) Table 1
# and Mallatt PDMP dates page
# "Any mandate" = prescriber required to check PDMP for controlled substances
pdmp_dates <- data.table(
  state = c("NV", "OK", "AZ", "OH", "DE", "KY", "WV", "NM", "LA",
            "MA", "TN", "NY", "MS", "VT", "CO", "MN", "NC", "RI",
            "GA", "ND", "IN", "AR", "CT", "PA", "TX", "NJ",
            "NH", "ME", "WI", "MD", "VA", "CA", "FL", "IL",
            "MI", "SC", "IA", "NE", "OR", "AL", "MT", "DC"),
  pdmp_mandate_year = c(
    2007, 2010, 2011, 2011, 2012, 2012, 2012, 2012, 2013,
    2013, 2013, 2013, 2013, 2013, 2013, 2013, 2013, 2013,
    2014, 2014, 2014, 2015, 2015, 2015, 2015, 2015,
    2016, 2017, 2017, 2018, 2018, 2018, 2018, 2018,
    2018, 2017, 2018, 2018, 2018, 2019, 2019, 2021
  )
)

# Never-treated states (no mandate as of 2023)
never_treated <- c("AK", "HI", "ID", "KS", "MO", "SD", "WY", "PR")
# Note: Some of these may have enacted mandates very recently;
# we code them as never-treated through our study period (2000-2023)

cat("  PDMP mandates coded:", nrow(pdmp_dates), "states\n")
cat("  Never-treated states:", length(never_treated), "\n\n")

# =============================================================================
# 3. CDC DRUG POISONING MORTALITY (Socrata API — jx6g-fdh6)
# =============================================================================
cat("=== Fetching CDC drug poisoning mortality (age-specific) ===\n")

# State × year × age group, 1999-2015
cdc_base_url <- "https://data.cdc.gov/resource/jx6g-fdh6.json"

# State-level age-specific data is suppressed in this API.
# Fetch All Ages + All Races state-level data (broad coverage for first stage)
cdc_results <- list()
offset <- 0
repeat {
  resp <- GET(cdc_base_url, query = list(
    "$where" = "age = 'All Ages' AND sex = 'Both Sexes' AND race_hispanic_origin = 'All Races-All Origins' AND state <> 'United States'",
    "$select" = "state, year, deaths, population, crude_death_rate, age_adjusted_rate",
    "$limit" = 5000,
    "$offset" = offset,
    "$order" = "state, year"
  ))
  stopifnot("CDC API request failed" = status_code(resp) == 200)
  chunk <- as.data.table(fromJSON(content(resp, "text", encoding = "UTF-8")))
  if (nrow(chunk) == 0) break
  cdc_results <- c(cdc_results, list(chunk))
  offset <- offset + nrow(chunk)
}
cdc_mortality <- rbindlist(cdc_results)
cdc_mortality[, `:=`(
  year = as.integer(year),
  deaths = as.integer(deaths),
  population = as.integer(population),
  crude_death_rate = as.numeric(crude_death_rate),
  age_adjusted_rate = as.numeric(age_adjusted_rate)
)]
# Add age column for compatibility with downstream scripts
cdc_mortality[, age := "All Ages"]
cat("  CDC state-level mortality:", nrow(cdc_mortality), "rows,",
    length(unique(cdc_mortality$state)), "states\n\n")

# =============================================================================
# 4. VSRR PROVISIONAL OVERDOSE DEATHS BY DRUG TYPE (Socrata API — xkb8-kh2a)
# =============================================================================
cat("=== Fetching VSRR drug-specific overdose deaths ===\n")

vsrr_url <- "https://data.cdc.gov/resource/xkb8-kh2a.json"

# Fetch key drug indicators
drug_indicators <- c(
  "Number of Drug Overdose Deaths",
  "Natural & semi-synthetic opioids (T40.2)",
  "Synthetic opioids, excl. methadone (T40.4)",
  "Heroin (T40.1)",
  "Cocaine (T40.5)",
  "Psychostimulants with abuse potential (T43.6)"
)

vsrr_results <- list()
for (ind in drug_indicators) {
  offset <- 0
  repeat {
    resp <- GET(vsrr_url, query = list(
      "$where" = sprintf("indicator = '%s' AND month = 'December'", ind),
      "$select" = "state_name, year, indicator, data_value, percent_complete",
      "$limit" = 5000,
      "$offset" = offset,
      "$order" = "state_name, year"
    ))
    if (status_code(resp) != 200) {
      warning("VSRR API error for indicator: ", ind)
      break
    }
    chunk <- as.data.table(fromJSON(content(resp, "text", encoding = "UTF-8")))
    if (nrow(chunk) == 0) break
    vsrr_results <- c(vsrr_results, list(chunk))
    offset <- offset + nrow(chunk)
  }
}
vsrr <- rbindlist(vsrr_results, fill = TRUE)
vsrr[, `:=`(
  year = as.integer(year),
  data_value = as.numeric(data_value),
  percent_complete = as.numeric(percent_complete)
)]
cat("  VSRR:", nrow(vsrr), "rows across", length(drug_indicators), "indicators\n\n")

# =============================================================================
# 5. STATE-LEVEL CONTROLS (FRED API)
# =============================================================================
cat("=== Fetching state controls from FRED ===\n")

fred_key <- Sys.getenv("FRED_API_KEY", "")
if (nchar(fred_key) == 0) {
  stop("FRED_API_KEY not set. Required for state unemployment/population data.")
}

# State FIPS to abbreviation mapping
state_fips <- data.table(
  fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,26,
           27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,
           49,50,51,53,54,55,56,72),
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
            "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
            "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
            "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","PR")
)

# Fetch unemployment rate for each state
fetch_fred_series <- function(series_id, api_key) {
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2000-01-01&observation_end=2023-12-31&frequency=a",
    series_id, api_key
  )
  resp <- GET(url)
  if (status_code(resp) != 200) return(NULL)
  parsed <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  if (is.null(parsed$observations) || length(parsed$observations) == 0) return(NULL)
  dt <- as.data.table(parsed$observations)
  dt[, .(date = as.Date(date), value = as.numeric(value))]
}

# State unemployment rate series IDs follow pattern: {ST}UR
cat("  Fetching state unemployment rates...\n")
unemp_list <- list()
for (st in state_fips$state) {
  if (st == "PR") next  # FRED doesn't have PR unemployment
  series_id <- paste0(st, "UR")
  dt <- fetch_fred_series(series_id, fred_key)
  if (!is.null(dt) && nrow(dt) > 0) {
    dt[, state := st]
    dt[, year := as.integer(format(date, "%Y"))]
    unemp_list <- c(unemp_list, list(dt[, .(state, year, unemp_rate = value)]))
  }
}
state_unemp <- rbindlist(unemp_list)
cat("  State unemployment:", nrow(state_unemp), "rows\n")

# National per-capita personal income as proxy for state economic conditions
cat("  Fetching national income data...\n")
pci <- fetch_fred_series("A792RC0A052NBEA", fred_key)  # Per capita income
if (!is.null(pci)) {
  pci[, year := as.integer(format(date, "%Y"))]
  pci <- pci[, .(year, nat_pci = value)]
}

cat("  FRED data fetched.\n\n")

# =============================================================================
# 6. CONCURRENT OPIOID POLICY DATES (hand-coded from PDAPS, NCSL)
# =============================================================================
cat("=== Coding concurrent opioid policy dates ===\n")

# Naloxone access laws (standing order dates)
# Source: PDAPS (pdaps.org), Davis & Carr (2017)
naloxone_dates <- data.table(
  state = c("NM", "WA", "CA", "CT", "NY", "RI", "VT", "IL", "MA", "WI",
            "CO", "NJ", "NC", "OH", "OR", "PA", "TN", "VA", "WV",
            "DE", "GA", "LA", "MD", "MN", "ND", "OK", "SC", "TX", "UT",
            "AL", "AR", "FL", "IN", "KY", "ME", "MS", "NH", "SD", "MT",
            "AZ", "HI", "IA", "ID", "MI", "MO", "NV", "NE", "DC", "AK", "WY"),
  naloxone_year = c(2001, 2010, 2013, 2013, 2013, 2013, 2013, 2013, 2014, 2014,
                    2013, 2013, 2013, 2014, 2013, 2014, 2014, 2013, 2015,
                    2014, 2014, 2015, 2015, 2014, 2015, 2013, 2015, 2015, 2014,
                    2015, 2015, 2015, 2015, 2015, 2016, 2016, 2016, 2016, 2017,
                    2016, 2016, 2016, 2017, 2016, 2017, 2015, 2017, 2016, 2017, 2018)
)

# Good Samaritan laws
good_sam_dates <- data.table(
  state = c("NM", "WA", "NY", "IL", "CO", "CT", "FL", "GA", "LA", "MA",
            "MN", "NC", "RI", "VT", "CA", "DC", "DE", "HI", "KY", "MD",
            "NJ", "OH", "OR", "PA", "TN", "WI", "AR", "IN", "NV", "ND",
            "TX", "UT", "VA", "WV", "MS", "NE", "OK", "SC", "ME", "MI",
            "MT", "NH", "SD", "AK", "AZ", "IA", "ID", "AL", "MO", "WY"),
  good_sam_year = c(2007, 2010, 2011, 2012, 2012, 2012, 2012, 2014, 2014, 2012,
                    2014, 2013, 2012, 2013, 2013, 2013, 2013, 2012, 2015, 2015,
                    2013, 2014, 2013, 2014, 2015, 2014, 2015, 2015, 2015, 2015,
                    2015, 2014, 2015, 2015, 2016, 2016, 2013, 2016, 2019, 2017,
                    2017, 2015, 2016, 2017, 2017, 2017, 2017, 2018, 2017, 2019)
)

# Medicaid expansion dates (ACA)
medicaid_exp <- data.table(
  state = c("AZ", "AR", "CA", "CO", "CT", "DE", "DC", "HI", "IA", "IL",
            "IN", "KY", "LA", "MA", "MD", "MI", "MN", "MT", "ND", "NH",
            "NJ", "NM", "NV", "NY", "OH", "OR", "PA", "RI", "VT", "WA",
            "WV", "AK", "VA", "ME", "ID", "NE", "UT", "NC", "MO", "OK",
            "SD"),
  medicaid_exp_year = c(2014, 2014, 2014, 2014, 2014, 2014, 2014, 2014, 2014, 2014,
                        2015, 2014, 2016, 2014, 2014, 2014, 2014, 2016, 2014, 2014,
                        2014, 2014, 2014, 2014, 2014, 2014, 2015, 2014, 2014, 2014,
                        2014, 2015, 2019, 2019, 2020, 2020, 2020, 2023, 2024, 2024,
                        2024)
)

# Recreational cannabis legalization
cannabis_dates <- data.table(
  state = c("CO", "WA", "OR", "AK", "DC", "NV", "CA", "MA", "ME",
            "MI", "VT", "IL", "AZ", "MT", "NJ", "NY", "CT", "NM",
            "VA", "RI", "MD", "MO", "DE", "MN", "OH"),
  cannabis_year = c(2012, 2012, 2014, 2014, 2015, 2016, 2016, 2016, 2016,
                    2018, 2018, 2019, 2020, 2020, 2020, 2021, 2021, 2021,
                    2021, 2022, 2022, 2022, 2023, 2023, 2023)
)

cat("  Naloxone laws:", nrow(naloxone_dates), "states\n")
cat("  Good Samaritan:", nrow(good_sam_dates), "states\n")
cat("  Medicaid expansion:", nrow(medicaid_exp), "states\n")
cat("  Cannabis legalization:", nrow(cannabis_dates), "states\n\n")

# =============================================================================
# SAVE ALL RAW DATA
# =============================================================================
cat("=== Saving raw data ===\n")

fwrite(hd, file.path(DATA_DIR, "ipeds_hd.csv"))
fwrite(efd, file.path(DATA_DIR, "ipeds_efd.csv"))
fwrite(gr, file.path(DATA_DIR, "ipeds_gr.csv"))
fwrite(efa, file.path(DATA_DIR, "ipeds_efa.csv"))
fwrite(ca, file.path(DATA_DIR, "ipeds_ca.csv"))
fwrite(sfa, file.path(DATA_DIR, "ipeds_sfa.csv"))
fwrite(pdmp_dates, file.path(DATA_DIR, "pdmp_mandate_dates.csv"))
fwrite(cdc_mortality, file.path(DATA_DIR, "cdc_drug_poisoning.csv"))
fwrite(vsrr, file.path(DATA_DIR, "vsrr_overdose_by_drug.csv"))
fwrite(state_unemp, file.path(DATA_DIR, "state_unemployment.csv"))
fwrite(naloxone_dates, file.path(DATA_DIR, "naloxone_dates.csv"))
fwrite(good_sam_dates, file.path(DATA_DIR, "good_samaritan_dates.csv"))
fwrite(medicaid_exp, file.path(DATA_DIR, "medicaid_expansion_dates.csv"))
fwrite(cannabis_dates, file.path(DATA_DIR, "cannabis_legalization_dates.csv"))
fwrite(state_fips, file.path(DATA_DIR, "state_fips.csv"))

cat("  All data saved to", DATA_DIR, "\n")

# =============================================================================
# DATA VALIDATION (required)
# =============================================================================
cat("\n=== Data Validation ===\n")
stopifnot("IPEDS hd: expected 50+ states" = length(unique(hd$state)) >= 50)
stopifnot("IPEDS efd: expected 2000-2023" = min(efd$year) <= 2001 & max(efd$year) >= 2022)
stopifnot("IPEDS gr: expected >100K rows" = nrow(gr) > 100000)
stopifnot("CDC: expected state-level data" = length(unique(cdc_mortality$state)) >= 40)
stopifnot("PDMP: expected 30+ treated states" = nrow(pdmp_dates) >= 30)
stopifnot("VSRR: expected drug-type data" = nrow(vsrr) > 0)
stopifnot("State unemployment: expected 50 states" = length(unique(state_unemp$state)) >= 50)

cat("Data validation PASSED:",
    nrow(hd), "hd rows,",
    nrow(efd), "efd rows,",
    nrow(gr), "gr rows,",
    length(unique(pdmp_dates$state)), "PDMP states,",
    nrow(cdc_mortality), "CDC mortality rows,",
    nrow(vsrr), "VSRR rows\n")
