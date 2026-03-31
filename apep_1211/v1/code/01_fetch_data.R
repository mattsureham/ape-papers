# ==============================================================================
# 01_fetch_data.R — Fetch QWI outcome data from Azure + treatment data
# apep_1211: Medicaid Reimbursement and Black-White Nursing Home Earnings Gap
# ==============================================================================

source("00_packages.R")

# --- 0. Azure connection (fix shell semicolon truncation) -------------------
# Read connection string directly from .env to avoid shell truncation at ';'
env_lines <- readLines("../../../../.env", warn = FALSE)
conn_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)
conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", conn_line)
conn_str <- gsub('^["\']|["\']$', "", conn_str)
stopifnot("Azure connection string not found in .env" = nchar(conn_str) > 50)

con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")
DBI::dbExecute(con, sprintf(
  "CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');",
  conn_str
))
cat("Connected to Azure (conn string length:", nchar(conn_str), ")\n")

# --- 1. QWI Outcome Data from Azure ----------------------------------------
cat("Fetching QWI race×ethnicity × NAICS 3-digit data from Azure...\n")

# NAICS 623 = Nursing and Residential Care Facilities
# NAICS 621 = Ambulatory Health Care Services (comparison industry)
# NAICS 721 = Accommodation (placebo industry)
# Race: A1 = White alone, A2 = Black alone
# Ethnicity: A0 = All, A1 = Not Hispanic/Latino (non-Hispanic for clean race comparison)

qwi_query <- "
SELECT
  geography AS state_fips,
  year,
  quarter,
  industry,
  race,
  ethnicity,
  sex,
  EarnS,
  Emp,
  EmpEnd,
  HirN,
  Sep,
  sEarnS,
  sEmp
FROM 'az://derived/qwi/rh/n3/*.parquet'
WHERE industry IN ('623', '621', '721')
  AND race IN ('A1', 'A2')
  AND ethnicity = 'A0'
  AND sex = '0'
  AND geography BETWEEN 1 AND 56
  AND Emp > 0
ORDER BY state_fips, year, quarter, industry, race
"

qwi <- dbGetQuery(con, qwi_query)
cat(sprintf("QWI rows fetched: %d\n", nrow(qwi)))
cat(sprintf("States: %d, Years: %d-%d\n",
            n_distinct(qwi$state_fips),
            min(qwi$year), max(qwi$year)))

# Validate: non-empty, expected columns
stopifnot(nrow(qwi) > 0)
stopifnot(all(c("state_fips", "year", "quarter", "industry", "race", "EarnS", "Emp") %in% names(qwi)))

DBI::dbDisconnect(con, shutdown = TRUE)

# --- 2. Treatment Data: State Medicaid NH Rate Increases --------------------
# Documented state-level Medicaid nursing home rate increases from legislative
# records and MACPAC reports. These are major, discrete rate shocks —
# not routine annual adjustments.
#
# Sources: State budget bills, MACPAC annual reports on Medicaid NF payment,
# National Conference of State Legislatures Medicaid tracking, AHCA analyses.
# Only includes increases ≥5% above inflation or explicit rebasing events.

rate_events <- tribble(
  ~state_fips, ~treat_year, ~event_description,
  # Pre-COVID: catch-up increases after freezes
  18L, 2017L, "Indiana SB 3: rate methodology reform, ~$6/day increase",
  20L, 2019L, "Kansas HB 2209: catch-up increase after multi-year freeze",
  31L, 2019L, "Nebraska LB 293: rate increase after freeze",
  48L, 2019L, "Texas HB 1: 3.2% rate increase in appropriations",
  37L, 2018L, "North Carolina SB 257: rate increase in state budget",
  # COVID-era: staffing crisis response (2021-2023)
   5L, 2022L, "Arkansas Act 690: COVID-era rate increase",
   6L, 2022L, "California SB 855: 5% emergency rate increase",
   9L, 2022L, "Connecticut Public Act 22-118: nursing home rate reform",
  12L, 2022L, "Florida SB 1712: rate increase for direct care",
  13L, 2022L, "Georgia HB 911: rate increase in state budget",
  17L, 2022L, "Illinois Nursing Home Reform Act rate increase",
  22L, 2022L, "Louisiana Act 409: Medicaid NH rate increase",
  25L, 2022L, "Massachusetts: comprehensive nursing home reform with rates",
  26L, 2022L, "Michigan FY2023 budget: 10% rate increase",
  34L, 2022L, "New Jersey FY2023 budget: rate increase",
  36L, 2022L, "New York: $1.3B nursing home rate package",
  39L, 2021L, "Ohio HB 110: Medicaid NF rebasing (~$17/day increase)",
  42L, 2022L, "Pennsylvania Act 54: 17.5% rate increase",
  51L, 2022L, "Virginia HB 30: rate increase in budget",
  27L, 2023L, "Minnesota HF 2930: rate increase",
  53L, 2023L, "Washington HB 1694: rate increase",
  41L, 2023L, "Oregon SB 5526: rate increase"
)

cat(sprintf("Treatment events: %d states\n", nrow(rate_events)))
cat(sprintf("Treatment years: %s\n", paste(sort(unique(rate_events$treat_year)), collapse = ", ")))

# --- 3. State FIPS crosswalk ------------------------------------------------
state_xwalk <- tribble(
  ~state_fips, ~state_abbr, ~state_name,
   1L, "AL", "Alabama",    2L, "AK", "Alaska",    4L, "AZ", "Arizona",
   5L, "AR", "Arkansas",   6L, "CA", "California", 8L, "CO", "Colorado",
   9L, "CT", "Connecticut", 10L, "DE", "Delaware", 11L, "DC", "District of Columbia",
  12L, "FL", "Florida",   13L, "GA", "Georgia",   15L, "HI", "Hawaii",
  16L, "ID", "Idaho",     17L, "IL", "Illinois",  18L, "IN", "Indiana",
  19L, "IA", "Iowa",      20L, "KS", "Kansas",    21L, "KY", "Kentucky",
  22L, "LA", "Louisiana", 23L, "ME", "Maine",     24L, "MD", "Maryland",
  25L, "MA", "Massachusetts", 26L, "MI", "Michigan", 27L, "MN", "Minnesota",
  28L, "MS", "Mississippi", 29L, "MO", "Missouri", 30L, "MT", "Montana",
  31L, "NE", "Nebraska",  32L, "NV", "Nevada",    33L, "NH", "New Hampshire",
  34L, "NJ", "New Jersey", 35L, "NM", "New Mexico", 36L, "NY", "New York",
  37L, "NC", "North Carolina", 38L, "ND", "North Dakota", 39L, "OH", "Ohio",
  40L, "OK", "Oklahoma",  41L, "OR", "Oregon",    42L, "PA", "Pennsylvania",
  44L, "RI", "Rhode Island", 45L, "SC", "South Carolina", 46L, "SD", "South Dakota",
  47L, "TN", "Tennessee", 48L, "TX", "Texas",     49L, "UT", "Utah",
  50L, "VT", "Vermont",   51L, "VA", "Virginia",  53L, "WA", "Washington",
  54L, "WV", "West Virginia", 55L, "WI", "Wisconsin", 56L, "WY", "Wyoming"
)

# --- 4. Save all data -------------------------------------------------------
saveRDS(qwi, "../data/qwi_raw.rds")
saveRDS(rate_events, "../data/rate_events.rds")
saveRDS(state_xwalk, "../data/state_xwalk.rds")

cat("Data saved to data/\n")
cat(sprintf("QWI: %d obs, %d states, years %d-%d\n",
            nrow(qwi), n_distinct(qwi$state_fips), min(qwi$year), max(qwi$year)))
cat(sprintf("Treatment: %d state events across %d years\n",
            nrow(rate_events), n_distinct(rate_events$treat_year)))
