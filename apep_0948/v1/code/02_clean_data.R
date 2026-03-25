# 02_clean_data.R — Build state-level analysis dataset
# Paper: The Fiscal Shadow of the Pill Mill (apep_0948)

source("00_packages.R")

# =============================================================================
# 1. Load raw data
# =============================================================================
arcos_by_drug <- arrow::read_parquet("../data/arcos_state_by_drug.parquet")
sud_claims <- arrow::read_parquet("../data/sud_claims.parquet")
npi_state <- arrow::read_parquet("../data/npi_state.parquet")
census_df <- read.csv("../data/census_state.csv", stringsAsFactors = FALSE)

# =============================================================================
# 2. Define triplicate states
# =============================================================================
triplicate_states <- c("CA", "ID", "IL", "IN", "NY", "TX", "WA")

data(state)
state_xwalk <- data.frame(
  state_abb = c(state.abb, "DC"),
  state_name = c(state.name, "District of Columbia"),
  stringsAsFactors = FALSE
)

# =============================================================================
# 3. Build state-level ARCOS supply (oxycodone-specific)
# =============================================================================
cat("Building state-level ARCOS supply by drug...\n")

arcos_state <- arcos_by_drug |>
  filter(nchar(state) == 2) |>  # Drop non-US entries
  group_by(state) |>
  summarise(
    oxy_pills = sum(total_pills[drug == "OXYCODONE"], na.rm = TRUE),
    hydro_pills = sum(total_pills[drug == "HYDROCODONE"], na.rm = TRUE),
    total_pills = sum(total_pills, na.rm = TRUE),
    n_years = max(n_distinct(year)),
    .groups = "drop"
  ) |>
  mutate(
    avg_annual_oxy = oxy_pills / n_years,
    avg_annual_total = total_pills / n_years,
    oxy_share = oxy_pills / total_pills
  )

cat(sprintf("ARCOS: %d states with drug-level data\n", nrow(arcos_state)))

# =============================================================================
# 4. Build state-level T-MSIS outcomes
# =============================================================================
cat("Building state-level T-MSIS aggregates...\n")

valid_states <- c(state.abb, "DC")
npi_state <- npi_state |> mutate(npi = as.character(npi))

sud_with_state <- sud_claims |>
  left_join(npi_state, by = c("SERVICING_PROVIDER_NPI_NUM" = "npi")) |>
  filter(!is.na(state) & state %in% valid_states)

cat(sprintf("Claims matched to states: %d / %d (%.1f%%)\n",
            nrow(sud_with_state), nrow(sud_claims),
            100 * nrow(sud_with_state) / nrow(sud_claims)))

# State-year MAT claims
state_year_mat <- sud_with_state |>
  filter(is_mat) |>
  group_by(state, year) |>
  summarise(
    mat_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
    mat_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
    mat_paid = sum(TOTAL_PAID, na.rm = TRUE),
    n_providers = n_distinct(SERVICING_PROVIDER_NPI_NUM),
    .groups = "drop"
  )

state_year_non_opioid <- sud_with_state |>
  filter(is_non_opioid_sud) |>
  group_by(state, year) |>
  summarise(
    nonopioid_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
    nonopioid_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
    nonopioid_paid = sum(TOTAL_PAID, na.rm = TRUE),
    .groups = "drop"
  )

# Average across years
state_mat_avg <- state_year_mat |>
  group_by(state) |>
  summarise(
    mat_claims = mean(mat_claims, na.rm = TRUE),
    mat_beneficiaries = mean(mat_beneficiaries, na.rm = TRUE),
    mat_paid = mean(mat_paid, na.rm = TRUE),
    n_providers = mean(n_providers, na.rm = TRUE),
    mat_years = n(),
    .groups = "drop"
  )

state_nonopioid_avg <- state_year_non_opioid |>
  group_by(state) |>
  summarise(
    nonopioid_claims = mean(nonopioid_claims, na.rm = TRUE),
    nonopioid_beneficiaries = mean(nonopioid_beneficiaries, na.rm = TRUE),
    nonopioid_paid = mean(nonopioid_paid, na.rm = TRUE),
    .groups = "drop"
  )

# =============================================================================
# 5. Merge + Census
# =============================================================================
cat("Merging datasets...\n")

census_df <- census_df |>
  left_join(state_xwalk, by = c("state_name" = "state_name")) |>
  rename(state_abb = state_abb)

# Medicaid expansion states (ACA, as of 2020)
expansion_states <- c("AK", "AR", "AZ", "CA", "CO", "CT", "DE", "HI", "IA",
                      "ID", "IL", "IN", "KY", "LA", "MA", "MD", "ME", "MI",
                      "MN", "MT", "ND", "NE", "NH", "NJ", "NM", "NV", "NY",
                      "OH", "OR", "PA", "RI", "UT", "VA", "VT", "WA", "WV")

analysis_df <- arcos_state |>
  rename(state_abb = state) |>
  left_join(state_mat_avg |> rename(state_abb = state), by = "state_abb") |>
  left_join(state_nonopioid_avg |> rename(state_abb = state), by = "state_abb") |>
  left_join(census_df |> select(state_abb, population, poverty_rate, uninsured_rate),
            by = "state_abb") |>
  filter(state_abb %in% valid_states) |>
  mutate(
    triplicate = as.integer(state_abb %in% triplicate_states),
    medicaid_expansion = as.integer(state_abb %in% expansion_states),
    # Per-capita measures
    oxy_pc = avg_annual_oxy / population,
    pills_pc = avg_annual_total / population,
    mat_claims_pc = mat_claims / population * 1000,
    mat_beneficiaries_pc = mat_beneficiaries / population * 1000,
    mat_paid_pc = mat_paid / population,
    nonopioid_claims_pc = nonopioid_claims / population * 1000,
    nonopioid_beneficiaries_pc = nonopioid_beneficiaries / population * 1000,
    # Log transforms
    log_oxy_pc = log(oxy_pc + 1e-6),
    log_pills_pc = log(pills_pc + 1e-6),
    log_mat_claims_pc = log(mat_claims_pc + 0.01),
    log_mat_bene_pc = log(mat_beneficiaries_pc + 0.01),
    log_mat_paid_pc = log(mat_paid_pc + 0.01),
    log_nonopioid_claims_pc = log(nonopioid_claims_pc + 0.01),
    log_population = log(population)
  )

analysis_df <- analysis_df |>
  filter(!is.na(oxy_pc) & !is.na(mat_claims_pc) & !is.na(population))

cat(sprintf("\nFinal analysis dataset: %d states\n", nrow(analysis_df)))
cat(sprintf("  Triplicate: %d, Non-triplicate: %d\n",
            sum(analysis_df$triplicate), sum(1 - analysis_df$triplicate)))

# =============================================================================
# 6. Summary statistics
# =============================================================================
trip <- analysis_df |> filter(triplicate == 1)
nontrip <- analysis_df |> filter(triplicate == 0)

cat("\n=== Key Comparisons ===\n")
cat(sprintf("Oxy per capita: Trip=%.1f, NonTrip=%.1f (ratio=%.2f)\n",
            mean(trip$oxy_pc), mean(nontrip$oxy_pc),
            mean(nontrip$oxy_pc) / mean(trip$oxy_pc)))
cat(sprintf("Oxy share: Trip=%.1f%%, NonTrip=%.1f%%\n",
            mean(trip$oxy_share)*100, mean(nontrip$oxy_share)*100))
cat(sprintf("MAT claims/1000: Trip=%.1f, NonTrip=%.1f (ratio=%.2f)\n",
            mean(trip$mat_claims_pc, na.rm = TRUE), mean(nontrip$mat_claims_pc, na.rm = TRUE),
            mean(nontrip$mat_claims_pc, na.rm = TRUE) / mean(trip$mat_claims_pc, na.rm = TRUE)))

# Save
arrow::write_parquet(analysis_df, "../data/analysis_state.parquet")
arrow::write_parquet(state_year_mat, "../data/state_year_mat.parquet")
arrow::write_parquet(state_year_non_opioid, "../data/state_year_nonopioid.parquet")

cat("\nDataset saved.\n")
