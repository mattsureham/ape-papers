# 02_clean_data.R — Build state-month panel for apep_0974

source("00_packages.R")

# =============================================================================
# 1. Load raw data
# =============================================================================
claims <- arrow::read_parquet("../data/claims_raw.parquet")
npi_state <- arrow::read_parquet("../data/npi_state.parquet")
ea_dates <- arrow::read_parquet("../data/snap_ea_dates.parquet")

cat(sprintf("Claims: %d rows\n", nrow(claims)))
cat(sprintf("NPI-state map: %d NPIs\n", nrow(npi_state)))

# =============================================================================
# 2. Map NPIs to states
# =============================================================================
npi_state <- npi_state |> mutate(npi = as.character(npi))

claims_geo <- claims |>
  left_join(npi_state, by = c("BILLING_PROVIDER_NPI_NUM" = "npi")) |>
  filter(!is.na(state), state %in% c(state.abb, "DC"))

cat(sprintf("Claims after NPI geocoding: %d rows (%.1f%% matched)\n",
            nrow(claims_geo), 100 * nrow(claims_geo) / nrow(claims)))

# =============================================================================
# 3. Aggregate to state-month level
# =============================================================================

# Total ED and PC claims by state-month
state_month <- claims_geo |>
  group_by(state, CLAIM_FROM_MONTH) |>
  summarize(
    ed_claims = sum(TOTAL_CLAIMS[is_ed], na.rm = TRUE),
    pc_claims = sum(TOTAL_CLAIMS[is_pc], na.rm = TRUE),
    ed_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES[is_ed], na.rm = TRUE),
    pc_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES[is_pc], na.rm = TRUE),
    ed_paid = sum(TOTAL_PAID[is_ed], na.rm = TRUE),
    pc_paid = sum(TOTAL_PAID[is_pc], na.rm = TRUE),
    # Acuity breakdown
    ed_low_claims = sum(TOTAL_CLAIMS[claim_type == "ed_low_acuity"], na.rm = TRUE),
    ed_mid_claims = sum(TOTAL_CLAIMS[claim_type == "ed_mid_acuity"], na.rm = TRUE),
    ed_high_claims = sum(TOTAL_CLAIMS[claim_type == "ed_high_acuity"], na.rm = TRUE),
    # Provider counts
    n_ed_providers = n_distinct(BILLING_PROVIDER_NPI_NUM[is_ed]),
    n_pc_providers = n_distinct(BILLING_PROVIDER_NPI_NUM[is_pc]),
    .groups = "drop"
  )

# Compute derived variables
state_month <- state_month |>
  mutate(
    total_claims = ed_claims + pc_claims,
    ed_share = ed_claims / (ed_claims + pc_claims),
    log_ed_claims = log(ed_claims + 1),
    log_pc_claims = log(pc_claims + 1),
    log_total_claims = log(total_claims + 1),
    ed_per_provider = ed_claims / pmax(n_ed_providers, 1),
    pc_per_provider = pc_claims / pmax(n_pc_providers, 1),
    # Acuity
    ed_high_share = ed_high_claims / pmax(ed_claims, 1),
    # Calendar variables
    year = as.integer(substr(CLAIM_FROM_MONTH, 1, 4)),
    month = as.integer(substr(CLAIM_FROM_MONTH, 6, 7)),
    year_month = year * 12 + month,
    date = as.Date(paste0(CLAIM_FROM_MONTH, "-01"))
  )

cat(sprintf("State-month panel: %d observations\n", nrow(state_month)))
cat(sprintf("States: %d\n", n_distinct(state_month$state)))
cat(sprintf("Months: %s to %s\n", min(state_month$CLAIM_FROM_MONTH), max(state_month$CLAIM_FROM_MONTH)))

# =============================================================================
# 4. Merge with SNAP EA treatment dates
# =============================================================================
panel <- state_month |>
  left_join(ea_dates, by = "state") |>
  mutate(
    # Treatment indicator: 1 after EA expires
    post_ea = as.integer(CLAIM_FROM_MONTH >= ea_end_month),
    # For CS-DiD: first treatment period (numeric)
    first_treat = ifelse(early_terminator, ea_end_numeric, 0),
    # Event time (months relative to EA expiration)
    event_time = year_month - ea_end_numeric
  )

cat(sprintf("\nTreatment summary:\n"))
cat(sprintf("  Early terminators: %d states\n", n_distinct(panel$state[panel$early_terminator])))
cat(sprintf("  Late/control: %d states\n", n_distinct(panel$state[!panel$early_terminator])))
cat(sprintf("  Treated obs (post_ea=1 in early states): %d\n",
            sum(panel$post_ea == 1 & panel$early_terminator)))

# =============================================================================
# 5. Pre-treatment summary statistics
# =============================================================================
pre_stats <- panel |>
  filter(CLAIM_FROM_MONTH < "2021-04") |>
  group_by(early_terminator) |>
  summarize(
    mean_ed = mean(ed_claims, na.rm = TRUE),
    mean_pc = mean(pc_claims, na.rm = TRUE),
    mean_ed_share = mean(ed_share, na.rm = TRUE),
    sd_ed_share = sd(ed_share, na.rm = TRUE),
    mean_n_ed_providers = mean(n_ed_providers, na.rm = TRUE),
    mean_n_pc_providers = mean(n_pc_providers, na.rm = TRUE),
    n_states = n_distinct(state),
    .groups = "drop"
  )

cat("\nPre-treatment means:\n")
print(as.data.frame(pre_stats))

# =============================================================================
# 6. Save panel
# =============================================================================
arrow::write_parquet(panel, "../data/panel.parquet")
cat(sprintf("\nPanel saved: %d rows, %d columns\n", nrow(panel), ncol(panel)))

# Quick sanity: check for any zero-claims state-months
zero_ed <- sum(panel$ed_claims == 0)
zero_pc <- sum(panel$pc_claims == 0)
cat(sprintf("Zero ED months: %d, Zero PC months: %d\n", zero_ed, zero_pc))
if (zero_ed > nrow(panel) * 0.1) warning("Many zero-ED months — check data coverage")
