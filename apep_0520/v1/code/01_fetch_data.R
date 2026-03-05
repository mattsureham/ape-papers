## ============================================================================
## 01_fetch_data.R — Load T-MSIS, NPPES, waiver dates, and external data
## ============================================================================

source("00_packages.R")

## ---- Load .env ----
env_file <- file.path("..", "..", "..", "..", ".env")
if (file.exists(env_file)) {
  env_lines <- readLines(env_file, warn = FALSE)
  env_lines <- env_lines[!grepl("^#|^$", env_lines)]
  for (line in env_lines) {
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- trimws(substr(line, 1, eq_pos - 1))
      val <- trimws(substr(line, eq_pos + 1, nchar(line)))
      val <- gsub('^["\']|["\']$', '', val)
      if (nchar(key) > 0) do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  cat("Loaded .env\n")
}

## ---- 0. Paths ----
SHARED_DATA <- file.path("..", "..", "..", "..", "data", "medicaid_provider_spending")
DATA <- "../data"
dir.create(DATA, showWarnings = FALSE, recursive = TRUE)

## ---- 1. Verify T-MSIS ----
tmsis_path <- file.path(SHARED_DATA, "tmsis.parquet")
if (!file.exists(tmsis_path)) {
  stop("T-MSIS Parquet not found at: ", tmsis_path,
       "\nDownload from: https://opendata.hhs.gov/datasets/medicaid-provider-spending/")
}

cat("T-MSIS Parquet found.\n")

## ---- 2. Load NPPES ----
nppes_path <- file.path(SHARED_DATA, "nppes_extract.parquet")
if (!file.exists(nppes_path)) {
  stop("NPPES extract not found at: ", nppes_path,
       "\nBuild from bulk CSV or run a prior Medicaid paper first.")
}

cat("Loading NPPES extract...\n")
nppes <- as.data.table(read_parquet(nppes_path))
nppes[, npi := as.character(npi)]
cat(sprintf("NPPES: %s providers\n", format(nrow(nppes), big.mark = ",")))

## ---- 3. Section 1115 SUD Waiver Dates ----
# Source: CMS State Waivers List, KFF Medicaid Waiver Tracker, MACPAC.
# Treatment date = CMS approval date (month the waiver became effective).
# States are classified into cohorts based on approval timing.

waiver_dates <- data.table(
  state = c(
    # Early adopters (pre-T-MSIS or minimal pre-period) — "always treated"
    "VA", "WV", "UT", "IN", "KY", "MD",
    # 2018 cohort
    "CA", "LA", "MA", "NH", "NJ", "WA", "MI", "WI", "NC", "VT",
    # 2019 cohort
    "PA", "AK", "IL", "KS", "MN", "NM", "RI", "NE",
    # 2020 cohort
    "CO", "MT", "DE", "OH", "ME", "OR", "TN",
    # 2021 cohort
    "NY", "AZ",
    # 2022 cohort
    "FL", "IA", "MS",
    # 2023 cohort
    "GA"
  ),
  waiver_date = as.Date(c(
    # Early adopters
    "2017-04-01", "2017-10-01", "2017-10-01", "2018-02-01", "2017-11-01", "2017-01-01",
    # 2018 cohort
    "2018-08-01", "2018-10-01", "2018-11-01", "2018-07-01", "2018-10-01",
    "2018-01-01", "2018-10-01", "2018-09-01", "2018-10-01", "2018-10-01",
    # 2019 cohort
    "2019-02-01", "2019-01-01", "2019-01-01", "2019-01-01",
    "2019-01-01", "2018-12-01", "2018-12-01", "2019-07-01",
    # 2020 cohort
    "2021-01-01", "2020-04-01", "2020-01-01", "2020-07-01",
    "2020-10-01", "2020-01-01", "2020-01-01",
    # 2021 cohort
    "2021-11-01", "2016-10-01",
    # 2022 cohort
    "2022-03-01", "2022-07-01", "2022-10-01",
    # 2023 cohort
    "2023-06-01"
  )),
  cohort_label = c(
    rep("Early (pre-2018)", 6),
    rep("2018", 10),
    rep("2019", 8),
    rep("2020", 7),
    rep("2021", 2),
    rep("2022", 3),
    rep("2023", 1)
  )
)

# Mark early adopters (always-treated, excluded from main DiD)
waiver_dates[, always_treated := waiver_date < as.Date("2018-07-01")]

# All 50 states + DC
all_states <- c(state.abb, "DC")
never_treated <- setdiff(all_states, waiver_dates$state)
cat(sprintf("Waiver states: %d (of which %d always-treated)\n",
            nrow(waiver_dates), sum(waiver_dates$always_treated)))
cat(sprintf("Never-treated states: %d (%s)\n",
            length(never_treated), paste(never_treated, collapse = ", ")))

fwrite(waiver_dates, file.path(DATA, "waiver_dates.csv"))

## ---- 4. SUD-Specific HCPCS Codes ----
# H-codes specifically for SUD services
sud_h_codes <- c(
  "H0001",  # Alcohol/drug assessment
  "H0005",  # Alcohol/drug group counseling
  "H0006",  # Alcohol/drug group education
  "H0010",  # Sub-acute detox (residential addiction program)
  "H0011",  # Acute detox (residential addiction program)
  "H0012",  # Sub-acute detox (non-residential)
  "H0013",  # Acute detox (non-residential)
  "H0014",  # Ambulatory detoxification
  "H0015",  # Intensive outpatient (SUD treatment program)
  "H0016",  # Alcohol/drug halfway house
  "H0018",  # Short-term residential (SUD, non-hospital)
  "H0019",  # Long-term residential (SUD, non-hospital)
  "H0020",  # Alcohol/drug services (methadone admin)
  "H0047",  # Alcohol/drug abuse services (not otherwise specified)
  "H0050"   # Brief alcohol/drug intervention
)

# MAT drug J-codes
mat_j_codes <- c(
  "J0571",  # Buprenorphine (Sublocade 100mg)
  "J0572",  # Buprenorphine (Sublocade 300mg)
  "J0573",  # Buprenorphine implant (Probuphine) — supply
  "J0574",  # Buprenorphine/naloxone, oral ≤3mg
  "J0575",  # Buprenorphine/naloxone, oral >3mg to 6mg
  "J2315"   # Naltrexone (Vivitrol), injection
)

# General behavioral health H-codes (for placebo comparison)
general_bh_codes <- paste0("H", sprintf("%04d", c(
  31:40, 2000:2037
)))

# HCBS/Personal care T-codes (placebo outcome — unrelated to SUD)
placebo_t_codes <- c("T1019", "T2016", "S5125", "T1015", "T2025")

save(sud_h_codes, mat_j_codes, general_bh_codes, placebo_t_codes,
     file = file.path(DATA, "hcpcs_classification.RData"))

## ---- 5. Build State × Month Panel from T-MSIS ----
cat("Building state × month panel with BH code classification...\n")

tmsis_ds <- open_dataset(tmsis_path)

# Step 1: H-codes (BH + SUD) — filter to H-prefix first, then aggregate
cat("Step 1a: Collecting H-code claims (behavioral health)...\n")
h_agg <- tmsis_ds |>
  filter(substr(HCPCS_CODE, 1, 1) == "H") |>
  mutate(
    is_sud_h = HCPCS_CODE %in% sud_h_codes
  ) |>
  group_by(BILLING_PROVIDER_NPI_NUM, CLAIM_FROM_MONTH, is_sud_h) |>
  summarize(
    total_paid = sum(TOTAL_PAID, na.rm = TRUE),
    total_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
    total_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
    .groups = "drop"
  ) |>
  collect() |>
  as.data.table()

setnames(h_agg, c("BILLING_PROVIDER_NPI_NUM", "CLAIM_FROM_MONTH"),
         c("billing_npi", "month_str"))
h_agg[, hcpcs_prefix := "H"]
cat(sprintf("  H-code rows: %s\n", format(nrow(h_agg), big.mark = ",")))

# Step 1b: J-codes (MAT drugs) — much smaller subset
cat("Step 1b: Collecting J-code claims (MAT drugs)...\n")
j_agg <- tmsis_ds |>
  filter(HCPCS_CODE %in% mat_j_codes) |>
  group_by(BILLING_PROVIDER_NPI_NUM, CLAIM_FROM_MONTH) |>
  summarize(
    total_paid = sum(TOTAL_PAID, na.rm = TRUE),
    total_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
    total_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
    .groups = "drop"
  ) |>
  collect() |>
  as.data.table()

setnames(j_agg, c("BILLING_PROVIDER_NPI_NUM", "CLAIM_FROM_MONTH"),
         c("billing_npi", "month_str"))
j_agg[, `:=`(hcpcs_prefix = "J", is_sud_h = FALSE)]
j_agg[, is_mat_j := TRUE]
cat(sprintf("  J-code rows: %s\n", format(nrow(j_agg), big.mark = ",")))

# Step 1c: T/S-codes (placebo personal care)
cat("Step 1c: Collecting T/S-code claims (placebo)...\n")
t_agg <- tmsis_ds |>
  filter(HCPCS_CODE %in% placebo_t_codes) |>
  group_by(BILLING_PROVIDER_NPI_NUM, CLAIM_FROM_MONTH) |>
  summarize(
    total_paid = sum(TOTAL_PAID, na.rm = TRUE),
    total_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
    total_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
    .groups = "drop"
  ) |>
  collect() |>
  as.data.table()

setnames(t_agg, c("BILLING_PROVIDER_NPI_NUM", "CLAIM_FROM_MONTH"),
         c("billing_npi", "month_str"))
t_agg[, `:=`(hcpcs_prefix = "T", is_sud_h = FALSE)]
t_agg[, is_placebo_t := TRUE]
cat(sprintf("  T/S-code rows: %s\n", format(nrow(t_agg), big.mark = ",")))

# Combine (use defaults for missing flag columns)
h_agg[, is_mat_j := FALSE]
h_agg[, is_placebo_t := FALSE]
j_agg[, is_placebo_t := FALSE]
t_agg[, is_mat_j := FALSE]

npi_month_agg <- rbindlist(list(h_agg, j_agg, t_agg), fill = TRUE)

rm(h_agg, j_agg, t_agg, tmsis_ds)
gc()

cat(sprintf("Collected %s rows from Arrow filtered aggregation\n",
            format(nrow(npi_month_agg), big.mark = ",")))

## ---- 6. Join NPPES for state ----
npi_state <- nppes[!is.na(state) & state != "", .(npi, state, entity_type)]
npi_month_agg <- merge(npi_month_agg, npi_state,
                        by.x = "billing_npi", by.y = "npi",
                        all.x = TRUE)

# Drop rows with no state match
cat(sprintf("NPPES match rate: %.1f%%\n",
            100 * mean(!is.na(npi_month_agg$state))))
npi_month_agg <- npi_month_agg[!is.na(state)]

## ---- 7. Construct State × Month Outcomes ----
npi_month_agg[, month_date := as.Date(paste0(month_str, "-01"))]

# A. All behavioral health (H-codes)
bh_panel <- npi_month_agg[hcpcs_prefix == "H", .(
  bh_paid = sum(total_paid),
  bh_claims = sum(total_claims),
  bh_beneficiaries = sum(total_beneficiaries),
  bh_providers = uniqueN(billing_npi)
), by = .(state, month_date)]

# B. SUD-specific H-codes
sud_panel <- npi_month_agg[is_sud_h == TRUE, .(
  sud_paid = sum(total_paid),
  sud_claims = sum(total_claims),
  sud_beneficiaries = sum(total_beneficiaries),
  sud_providers = uniqueN(billing_npi)
), by = .(state, month_date)]

# C. MAT J-codes
mat_panel <- npi_month_agg[is_mat_j == TRUE, .(
  mat_paid = sum(total_paid),
  mat_claims = sum(total_claims),
  mat_beneficiaries = sum(total_beneficiaries),
  mat_providers = uniqueN(billing_npi)
), by = .(state, month_date)]

# D. Placebo: Personal care T/S-codes
placebo_panel <- npi_month_agg[is_placebo_t == TRUE, .(
  pc_paid = sum(total_paid),
  pc_claims = sum(total_claims),
  pc_beneficiaries = sum(total_beneficiaries),
  pc_providers = uniqueN(billing_npi)
), by = .(state, month_date)]

# E. Total spending (across all collected code types: H, J, T/S)
total_panel <- npi_month_agg[, .(
  total_paid = sum(total_paid),
  total_claims = sum(total_claims),
  total_beneficiaries = sum(total_beneficiaries),
  total_providers = uniqueN(billing_npi)
), by = .(state, month_date)]

# F. Entity type decomposition (extensive margin)
entity_panel <- npi_month_agg[hcpcs_prefix == "H", .(
  org_providers = uniqueN(billing_npi[entity_type == "2"]),
  indiv_providers = uniqueN(billing_npi[entity_type == "1"]),
  org_claims = sum(total_claims[entity_type == "2"]),
  indiv_claims = sum(total_claims[entity_type == "1"])
), by = .(state, month_date)]

## ---- 8. Merge all panels ----
# Create complete state × month grid
all_months <- seq(as.Date("2018-01-01"), as.Date("2024-12-01"), by = "month")
grid <- CJ(state = all_states, month_date = all_months)

panel <- merge(grid, bh_panel, by = c("state", "month_date"), all.x = TRUE)
panel <- merge(panel, sud_panel, by = c("state", "month_date"), all.x = TRUE)
panel <- merge(panel, mat_panel, by = c("state", "month_date"), all.x = TRUE)
panel <- merge(panel, placebo_panel, by = c("state", "month_date"), all.x = TRUE)
panel <- merge(panel, total_panel, by = c("state", "month_date"), all.x = TRUE)
panel <- merge(panel, entity_panel, by = c("state", "month_date"), all.x = TRUE)

# Fill missing with 0 (states with no claims in a category)
num_cols <- setdiff(names(panel), c("state", "month_date"))
for (col in num_cols) {
  panel[is.na(get(col)), (col) := 0]
}

## ---- 9. Add waiver treatment variables ----
panel <- merge(panel, waiver_dates[, .(state, waiver_date, always_treated, cohort_label)],
               by = "state", all.x = TRUE)
panel[is.na(always_treated), always_treated := FALSE]
panel[is.na(waiver_date), cohort_label := "Never treated"]

# Treatment indicator
panel[, treated := fifelse(!is.na(waiver_date) & month_date >= waiver_date, 1L, 0L)]

# Event time (months relative to waiver)
panel[, event_time := fifelse(!is.na(waiver_date),
                               as.integer(difftime(month_date, waiver_date, units = "days")) %/% 30L,
                               NA_integer_)]

# Numeric state and month IDs for fixest
panel[, state_id := as.integer(factor(state))]
panel[, month_id := as.integer(factor(month_date))]

# Cohort group for CS-DiD (month of first treatment, or 0 for never-treated)
panel[, cohort_month := fifelse(!is.na(waiver_date),
                                 as.integer(format(waiver_date, "%Y%m")),
                                 0L)]

# Year-month numeric for CS-DiD
panel[, ym := as.integer(format(month_date, "%Y%m"))]

setorder(panel, state, month_date)

## ---- 10. Fetch ACS state population ----
cat("Fetching state population from Census ACS...\n")
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in .env")

pop_list <- list()
for (yr in 2018:2023) {
  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs5?get=B01003_001E,NAME&for=state:*&key=%s",
    yr, census_key
  )
  resp <- tryCatch(
    jsonlite::fromJSON(url),
    error = function(e) stop("Census ACS fetch failed for year ", yr, ": ", e$message)
  )
  dt <- as.data.table(resp[-1, ])
  setnames(dt, c("population", "state_name", "state_fips"))
  dt[, year := yr]
  dt[, population := as.numeric(population)]
  pop_list[[as.character(yr)]] <- dt
}
pop_dt <- rbindlist(pop_list)

# State FIPS to abbreviation
fips_map <- data.table(
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,53,54,55,56)),
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)
pop_dt <- merge(pop_dt, fips_map, by = "state_fips")
pop_dt <- pop_dt[, .(state, year, population)]

# Extend 2023 pop to 2024
pop_2024 <- copy(pop_dt[year == 2023])
pop_2024[, year := 2024]
pop_dt <- rbindlist(list(pop_dt, pop_2024))

# Merge population onto panel
panel[, year := year(month_date)]
panel <- merge(panel, pop_dt, by = c("state", "year"), all.x = TRUE)

# Per-capita rates (per 100,000 population)
panel[, `:=`(
  bh_providers_pc = bh_providers / population * 1e5,
  sud_providers_pc = sud_providers / population * 1e5,
  mat_providers_pc = mat_providers / population * 1e5,
  bh_beneficiaries_pc = bh_beneficiaries / population * 1e5,
  sud_beneficiaries_pc = sud_beneficiaries / population * 1e5,
  bh_paid_pc = bh_paid / population * 1e5,
  sud_paid_pc = sud_paid / population * 1e5,
  pc_providers_pc = pc_providers / population * 1e5
)]

## ---- 11. Fetch FRED state unemployment ----
cat("Fetching state unemployment rates from FRED...\n")
fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) == 0) stop("FRED_API_KEY not set in .env")

# State unemployment series IDs
ur_series <- paste0(all_states, "UR")
ur_series[ur_series == "DCUR"] <- "DCUR"  # DC uses same format

ur_list <- list()
for (s in seq_along(all_states)) {
  sid <- ur_series[s]
  st <- all_states[s]
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2018-01-01&observation_end=2024-12-31",
    sid, fred_key
  )
  resp <- tryCatch(jsonlite::fromJSON(url), error = function(e) NULL)
  if (!is.null(resp) && length(resp$observations) > 0) {
    dt <- as.data.table(resp$observations)
    dt[, `:=`(state = st, date = as.Date(date), urate = as.numeric(value))]
    ur_list[[st]] <- dt[, .(state, date, urate)]
  }
}
ur_dt <- rbindlist(ur_list, fill = TRUE)
ur_dt[, month_date := floor_date(date, "month")]
ur_dt <- ur_dt[, .(urate = mean(urate, na.rm = TRUE)), by = .(state, month_date)]

panel <- merge(panel, ur_dt, by = c("state", "month_date"), all.x = TRUE)

## ---- 12. Log transforms ----
# Add 1 before log to handle zeros
panel[, `:=`(
  ln_bh_providers = log(bh_providers + 1),
  ln_sud_providers = log(sud_providers + 1),
  ln_mat_providers = log(mat_providers + 1),
  ln_bh_claims = log(bh_claims + 1),
  ln_sud_claims = log(sud_claims + 1),
  ln_mat_claims = log(mat_claims + 1),
  ln_bh_beneficiaries = log(bh_beneficiaries + 1),
  ln_sud_beneficiaries = log(sud_beneficiaries + 1),
  ln_pc_providers = log(pc_providers + 1),
  ln_pc_claims = log(pc_claims + 1)
)]

## ---- 13. Save ----
saveRDS(panel, file.path(DATA, "panel_state_month.rds"))
fwrite(panel, file.path(DATA, "panel_state_month.csv"))
cat(sprintf("\nFinal panel: %d rows, %d states, %d months\n",
            nrow(panel), uniqueN(panel$state), uniqueN(panel$month_date)))

## ---- 14. Data Validation ----
stopifnot("Expected 51 states/DC" = uniqueN(panel$state) == 51)
stopifnot("Expected 84 months" = uniqueN(panel$month_date) == 84)
stopifnot("Expected complete panel" = nrow(panel) == 51 * 84)
stopifnot("BH providers exist" = sum(panel$bh_providers) > 0)
stopifnot("SUD providers exist" = sum(panel$sud_providers) > 0)
stopifnot("Waiver dates loaded" = nrow(waiver_dates) > 30)
stopifnot("Population data present" = sum(!is.na(panel$population)) > nrow(panel) * 0.9)

cat("Data validation passed.\n")
cat("\n=== Data preparation complete ===\n")

# Clean up
rm(npi_month_agg, npi_state, nppes)
gc()
gc()
