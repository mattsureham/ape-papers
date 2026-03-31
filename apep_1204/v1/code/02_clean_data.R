## 02_clean_data.R — Construct analysis dataset
## APEP-1204: Stretched Thin
## Key tasks:
##   1. Build disaster-level panel from declarations
##   2. Compute concurrent disaster load (the instrument)
##   3. Aggregate IHP outcomes to disaster level
##   4. Aggregate PA obligation lags to disaster level
##   5. Merge everything

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load raw data
# ============================================================================
declarations <- readRDS(file.path(data_dir, "declarations.rds"))
ihp <- readRDS(file.path(data_dir, "ihp_owners.rds"))
pa <- readRDS(file.path(data_dir, "pa_projects.rds"))

cat(sprintf("Raw: %d declaration rows, %d IHP rows, %d PA rows\n",
            nrow(declarations), nrow(ihp), nrow(pa)))

# ============================================================================
# 2. Build disaster-level panel from declarations
# ============================================================================

# Parse dates
declarations <- declarations %>%
  mutate(
    decl_date = as.Date(substr(declarationDate, 1, 10)),
    inc_begin = as.Date(substr(incidentBeginDate, 1, 10)),
    inc_end   = as.Date(substr(incidentEndDate, 1, 10)),
    decl_year = year(decl_date)
  )

# Collapse to disaster level (one row per disasterNumber)
# Each disaster has multiple county-level rows — collapse to disaster level
disasters <- declarations %>%
  group_by(disasterNumber) %>%
  summarise(
    state = first(state),
    decl_date = first(decl_date),
    decl_year = first(decl_year),
    inc_begin = first(inc_begin),
    inc_end   = first(inc_end),
    incident_type = first(incidentType),
    decl_type = first(declarationType),
    ih_program = any(ihProgramDeclared == 1 | ihProgramDeclared == TRUE, na.rm = TRUE),
    ia_program = any(iaProgramDeclared == 1 | iaProgramDeclared == TRUE, na.rm = TRUE),
    pa_program = any(paProgramDeclared == 1 | paProgramDeclared == TRUE, na.rm = TRUE),
    n_counties = n_distinct(fipsCountyCode),
    .groups = "drop"
  ) %>%
  filter(decl_type == "DR") %>%  # Major Disaster Declarations only
  filter(decl_year >= 2005, decl_year <= 2024)

cat(sprintf("Disaster-level panel: %d Major Disasters (2005-2024)\n", nrow(disasters)))

# Fix missing incident end dates: use begin + 30 days as default
disasters <- disasters %>%
  mutate(
    inc_end = if_else(is.na(inc_end), inc_begin + 30, inc_end),
    # "Active period" = incident begin to end + 90 days (FEMA deployment window)
    active_start = inc_begin,
    active_end   = inc_end + 90
  )

# ============================================================================
# 3. Compute concurrent disaster load (THE INSTRUMENT)
# ============================================================================
# For each disaster d, count how many OTHER Major Disasters had overlapping
# active periods at the time of declaration d.

cat("Computing concurrent disaster load...\n")

# Vectorized: for each disaster, count overlaps
disasters$concurrent_load <- NA_integer_
for (i in seq_len(nrow(disasters))) {
  d_date <- disasters$decl_date[i]
  d_num  <- disasters$disasterNumber[i]
  d_state <- disasters$state[i]

  # Count other disasters whose active period overlaps this declaration date
  # Exclude same disaster and same state (for exclusion restriction)
  concurrent <- sum(
    disasters$active_start <= d_date &
    disasters$active_end   >= d_date &
    disasters$disasterNumber != d_num &
    disasters$state != d_state  # Only OTHER-state concurrent disasters
  )
  disasters$concurrent_load[i] <- concurrent
}

# Also compute total concurrent (including same state) for comparison
disasters$concurrent_total <- NA_integer_
for (i in seq_len(nrow(disasters))) {
  d_date <- disasters$decl_date[i]
  d_num  <- disasters$disasterNumber[i]
  concurrent <- sum(
    disasters$active_start <= d_date &
    disasters$active_end   >= d_date &
    disasters$disasterNumber != d_num
  )
  disasters$concurrent_total[i] <- concurrent
}

cat(sprintf("Concurrent load (other-state): mean=%.1f, sd=%.1f, range=[%d, %d]\n",
            mean(disasters$concurrent_load), sd(disasters$concurrent_load),
            min(disasters$concurrent_load), max(disasters$concurrent_load)))

# ============================================================================
# 4. Aggregate IHP outcomes to disaster level
# ============================================================================

ihp_disaster <- ihp %>%
  group_by(disasterNumber) %>%
  summarise(
    ihp_registrations = sum(validRegistrations, na.rm = TRUE),
    ihp_inspected = sum(totalInspected, na.rm = TRUE),
    ihp_approved = sum(approvedForFemaAssistance, na.rm = TRUE),
    ihp_total_amount = sum(totalApprovedIhpAmount, na.rm = TRUE),
    ihp_repair_amount = sum(repairReplaceAmount, na.rm = TRUE),
    ihp_rental_amount = sum(rentalAmount, na.rm = TRUE),
    ihp_other_amount = sum(otherNeedsAmount, na.rm = TRUE),
    ihp_total_damage = sum(totalDamage, na.rm = TRUE),
    ihp_max_grants = sum(totalMaxGrants, na.rm = TRUE),
    ihp_n_zips = n(),
    .groups = "drop"
  ) %>%
  mutate(
    # Key outcomes
    approval_rate = ihp_approved / ihp_registrations,
    avg_grant = ihp_total_amount / ihp_approved,
    avg_grant_per_reg = ihp_total_amount / ihp_registrations,
    pct_max_grant = ihp_max_grants / ihp_approved,
    inspection_rate = ihp_inspected / ihp_registrations
  )

cat(sprintf("IHP disaster-level: %d disasters with IHP data\n", nrow(ihp_disaster)))

# ============================================================================
# 5. Aggregate PA outcomes to disaster level
# ============================================================================

pa <- pa %>%
  mutate(
    first_oblig_date = as.Date(substr(firstObligationDate, 1, 10)),
    last_oblig_date = as.Date(substr(lastObligationDate, 1, 10)),
    decl_date_pa = as.Date(substr(declarationDate, 1, 10))
  )

pa_disaster <- pa %>%
  filter(!is.na(first_oblig_date), !is.na(decl_date_pa)) %>%
  mutate(
    obligation_lag_days = as.numeric(first_oblig_date - decl_date_pa)
  ) %>%
  filter(obligation_lag_days >= 0, obligation_lag_days < 3650) %>%
  group_by(disasterNumber) %>%
  summarise(
    pa_n_projects = n(),
    pa_total_obligated = sum(totalObligated, na.rm = TRUE),
    pa_federal_share = sum(federalShareObligated, na.rm = TRUE),
    pa_median_lag = median(obligation_lag_days, na.rm = TRUE),
    pa_mean_lag = mean(obligation_lag_days, na.rm = TRUE),
    pa_p90_lag = quantile(obligation_lag_days, 0.90, na.rm = TRUE),
    pa_avg_project = mean(projectAmount, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("PA disaster-level: %d disasters with PA data\n", nrow(pa_disaster)))

# ============================================================================
# 6. Merge everything
# ============================================================================

analysis <- disasters %>%
  left_join(ihp_disaster, by = "disasterNumber") %>%
  left_join(pa_disaster, by = "disasterNumber")

# Create analysis variables
analysis <- analysis %>%
  mutate(
    # Disaster severity controls
    log_n_counties = log(n_counties + 1),
    is_hurricane = as.integer(incident_type == "Hurricane"),
    is_flood = as.integer(incident_type == "Flood"),
    is_fire = as.integer(incident_type == "Fire"),
    is_severe_storm = as.integer(grepl("Storm|Tornado", incident_type)),
    quarter = quarter(decl_date),
    month = month(decl_date),
    # Log outcomes
    log_avg_grant = log(avg_grant + 1),
    log_pa_mean_lag = log(pa_mean_lag + 1),
    log_pa_median_lag = log(pa_median_lag + 1),
    # Has IHP / PA data
    has_ihp = !is.na(ihp_registrations),
    has_pa = !is.na(pa_n_projects)
  )

cat(sprintf("\nFinal analysis dataset: %d disasters\n", nrow(analysis)))
cat(sprintf("  With IHP data: %d\n", sum(analysis$has_ihp)))
cat(sprintf("  With PA data:  %d\n", sum(analysis$has_pa)))
cat(sprintf("  Year range: %d-%d\n", min(analysis$decl_year), max(analysis$decl_year)))

saveRDS(analysis, file.path(data_dir, "analysis.rds"))
cat("Saved analysis.rds\n")
