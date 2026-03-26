# 01_fetch_data.R — Data acquisition for apep_0974
# Sources: T-MSIS (local Parquet), NPPES extract, SNAP EA dates (USDA)

source("00_packages.R")

# =============================================================================
# 1. T-MSIS: Extract ED and Primary Care claims by provider-month
# =============================================================================
cat("Loading T-MSIS data via Arrow (lazy)...\n")

tmsis_path <- "../../../../data/medicaid_provider_spending/tmsis.parquet"
stopifnot("T-MSIS file must exist" = file.exists(tmsis_path))

ds <- arrow::open_dataset(tmsis_path)

# ED codes: 99281-99285 (Emergency Department E&M, all severity levels)
ed_codes <- c("99281", "99282", "99283", "99284", "99285")

# Primary care E&M codes: 99213-99215 (established patient office visits)
pc_codes <- c("99213", "99214", "99215")

# Also extract low-acuity ED (99281-99282) vs high-acuity (99284-99285) for mechanism
all_codes <- c(ed_codes, pc_codes)

cat("Extracting ED + PC claims from T-MSIS...\n")
claims <- ds |>
  filter(HCPCS_CODE %in% all_codes) |>
  select(BILLING_PROVIDER_NPI_NUM, HCPCS_CODE, CLAIM_FROM_MONTH,
         TOTAL_UNIQUE_BENEFICIARIES, TOTAL_CLAIMS, TOTAL_PAID) |>
  collect()

cat(sprintf("Extracted %d rows covering ED + PC claims\n", nrow(claims)))
stopifnot("Claims data must have rows" = nrow(claims) > 0)

# Tag claim type
claims <- claims |>
  mutate(
    claim_type = case_when(
      HCPCS_CODE %in% c("99281", "99282") ~ "ed_low_acuity",
      HCPCS_CODE %in% c("99283") ~ "ed_mid_acuity",
      HCPCS_CODE %in% c("99284", "99285") ~ "ed_high_acuity",
      HCPCS_CODE %in% pc_codes ~ "primary_care",
      TRUE ~ "other"
    ),
    is_ed = HCPCS_CODE %in% ed_codes,
    is_pc = HCPCS_CODE %in% pc_codes
  )

cat(sprintf("  ED claims: %d rows\n", sum(claims$is_ed)))
cat(sprintf("  PC claims: %d rows\n", sum(claims$is_pc)))

arrow::write_parquet(claims, "../data/claims_raw.parquet")

# =============================================================================
# 2. NPPES: Map provider NPIs to states
# =============================================================================
cat("Loading NPPES extract for NPI geocoding...\n")

nppes_path <- "../../../../data/medicaid_provider_spending/nppes_extract.parquet"
stopifnot("NPPES extract must exist" = file.exists(nppes_path))

nppes <- arrow::read_parquet(nppes_path,
                              col_select = c("npi", "state"))

# Clean: remove deactivated/missing state
nppes <- nppes |>
  filter(!is.na(state), state != "", nchar(state) == 2) |>
  distinct(npi, .keep_all = TRUE)

cat(sprintf("NPPES: %d unique NPIs with state assignments\n", nrow(nppes)))

# Check match rate
unique_npis <- unique(claims$BILLING_PROVIDER_NPI_NUM)
matched <- sum(unique_npis %in% nppes$npi)
cat(sprintf("NPI match rate: %d / %d (%.1f%%)\n",
            matched, length(unique_npis), 100 * matched / length(unique_npis)))

stopifnot("NPI match rate must exceed 50%" = matched / length(unique_npis) > 0.5)

arrow::write_parquet(nppes, "../data/npi_state.parquet")

# =============================================================================
# 3. SNAP EA expiration dates by state
# =============================================================================
cat("Constructing SNAP EA treatment dates...\n")

# SNAP Emergency Allotments: authorized under Families First Act (March 2020)
# States could request EA monthly; some stopped requesting before federal end
# Source: USDA FNS documentation, CBPP tracking
# Federal EA authority ended after February 2023 issuance

# States that ended EA BEFORE the federal end (early terminators):
# These are the "treated" states in our DiD design
ea_dates <- tribble(
  ~state, ~ea_end_month, ~ea_end_label,
  # Ended in 2021
  "AR", "2021-04", "2021-Q2",
  "FL", "2021-04", "2021-Q2",
  "ID", "2021-07", "2021-Q3",
  "IN", "2021-04", "2021-Q2",
  "MS", "2021-04", "2021-Q2",
  "MT", "2021-07", "2021-Q3",
  "ND", "2021-07", "2021-Q3",
  "NE", "2021-07", "2021-Q3",
  "SD", "2021-04", "2021-Q2",
  "TN", "2021-07", "2021-Q3",
  # Ended in 2022
  "AL", "2022-01", "2022-Q1",
  "GA", "2022-04", "2022-Q2",
  "IA", "2022-04", "2022-Q2",
  "MO", "2022-04", "2022-Q2",
  "NH", "2022-07", "2022-Q3",
  "TX", "2022-04", "2022-Q2",
  "WY", "2022-04", "2022-Q2",
  # Ended in 2023 (early, before federal end)
  "SC", "2023-01", "2023-Q1"
)

# All other states (32 + DC) kept EA through February 2023 (federal end)
all_states <- c(state.abb, "DC")
late_states <- setdiff(all_states, ea_dates$state)

late_df <- tibble(
  state = late_states,
  ea_end_month = "2023-03",  # First month WITHOUT EA (EA issued in Feb 2023)
  ea_end_label = "Never_early"
)

ea_all <- bind_rows(ea_dates, late_df) |>
  mutate(
    early_terminator = ea_end_month < "2023-03",
    # Convert to numeric month for DiD
    ea_end_year = as.integer(substr(ea_end_month, 1, 4)),
    ea_end_mo = as.integer(substr(ea_end_month, 6, 7)),
    ea_end_numeric = ea_end_year * 12 + ea_end_mo
  )

cat(sprintf("Early terminators: %d states\n", sum(ea_all$early_terminator)))
cat(sprintf("Late/never: %d states\n", sum(!ea_all$early_terminator)))

arrow::write_parquet(ea_all, "../data/snap_ea_dates.parquet")

# =============================================================================
# 4. SNAP participation data (for dosage/heterogeneity)
# =============================================================================
cat("Fetching SNAP participation data from USDA FNS...\n")

# Try FRED API for state-level SNAP participation
fred_key <- Sys.getenv("FRED_API_KEY", "")

if (nchar(fred_key) > 0) {
  # FRED has state-level SNAP series: e.g., "BRXX08SNAP" pattern
  # Use a simpler approach: national SNAP data as context
  snap_url <- paste0(
    "https://api.stlouisfed.org/fred/series/observations?",
    "series_id=TRP6001A027NBEA&api_key=", fred_key,
    "&file_type=json&observation_start=2018-01-01"
  )

  snap_resp <- tryCatch({
    jsonlite::fromJSON(snap_url)
  }, error = function(e) {
    cat("FRED SNAP fetch failed, will use state EA variation only:", e$message, "\n")
    NULL
  })

  if (!is.null(snap_resp) && "observations" %in% names(snap_resp)) {
    snap_nat <- as_tibble(snap_resp$observations) |>
      mutate(date = as.Date(date), value = as.numeric(value))
    arrow::write_parquet(snap_nat, "../data/snap_national.parquet")
    cat(sprintf("National SNAP data: %d observations\n", nrow(snap_nat)))
  }
} else {
  cat("No FRED API key; proceeding with EA dates only.\n")
}

# =============================================================================
# Summary
# =============================================================================
cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("T-MSIS claims (ED+PC): %d rows\n", nrow(claims)))
cat(sprintf("NPPES NPI-state map: %d NPIs\n", nrow(nppes)))
cat(sprintf("SNAP EA treatment dates: %d states (%d early, %d late)\n",
            nrow(ea_all), sum(ea_all$early_terminator), sum(!ea_all$early_terminator)))
cat("All data saved to ../data/\n")
