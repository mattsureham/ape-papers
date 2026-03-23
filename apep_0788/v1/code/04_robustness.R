## 04_robustness.R — Robustness checks and placebo tests
## Paper: Carbon Border Deflection (apep_0788)

source("00_packages.R")

trade <- readRDS("../data/trade_panel.rds")

# ============================================================
# 1. PLACEBO: Uncovered products only (HS 73)
# ============================================================

# If CBAM drives the result, uncovered products should show no deflection
# Use simpler FEs to avoid collinearity (no dest×month since post×EU is collinear)
placebo_uncovered <- feols(
  log_trade ~ post * eu_dest |
    paste(exporter, dest) + paste(exporter, period),
  data = trade |> filter(cbam_covered == 0),
  cluster = ~exp_dest
)

cat("=== PLACEBO: Uncovered products only (HS 73) ===\n")
cat("Post × EU coefficient (should be ~0):\n")
print(coeftable(placebo_uncovered))

# ============================================================
# 2. EXCLUDE RUSSIA & UKRAINE (war disruption)
# ============================================================

m_no_ruua <- feols(
  log_trade ~ post_eu_covered |
    cell_id + exp_month + dest_month + prod_month,
  data = trade |> filter(!exporter %in% c("RUS", "UKR")),
  cluster = ~exp_dest
)

cat("\n=== EXCLUDING RUSSIA & UKRAINE ===\n")
print(coeftable(m_no_ruua))

# ============================================================
# 3. EXCLUDE 2020 (COVID year)
# ============================================================

m_no_2020 <- feols(
  log_trade ~ post_eu_covered |
    cell_id + exp_month + dest_month + prod_month,
  data = trade |> filter(year >= 2021),
  cluster = ~exp_dest
)

cat("\n=== EXCLUDING 2020 ===\n")
print(coeftable(m_no_2020))

# ============================================================
# 4. EXCLUDE US (Section 232 tariffs)
# ============================================================

m_no_us <- feols(
  log_trade ~ post_eu_covered |
    cell_id + exp_month + dest_month + prod_month,
  data = trade |> filter(dest != "US"),
  cluster = ~exp_dest
)

cat("\n=== EXCLUDING US ===\n")
print(coeftable(m_no_us))

# ============================================================
# 5. DOSE-RESPONSE BY CARBON INTENSITY
# ============================================================

# Interact triple-diff with carbon intensity
m_dose <- feols(
  log_trade ~ post_eu_covered + post_eu_covered:co2_intensity |
    cell_id + exp_month + dest_month + prod_month,
  data = trade,
  cluster = ~exp_dest
)

cat("\n=== DOSE-RESPONSE: Carbon Intensity ===\n")
print(coeftable(m_dose))

# Split by high vs low carbon intensity
m_high_carbon <- feols(
  log_trade ~ post_eu_covered |
    cell_id + exp_month + dest_month + prod_month,
  data = trade |> filter(high_carbon == 1),
  cluster = ~exp_dest
)

m_low_carbon <- feols(
  log_trade ~ post_eu_covered |
    cell_id + exp_month + dest_month + prod_month,
  data = trade |> filter(high_carbon == 0),
  cluster = ~exp_dest
)

cat("\nHigh carbon intensity exporters:\n")
print(coeftable(m_high_carbon))
cat("\nLow carbon intensity exporters:\n")
print(coeftable(m_low_carbon))

# ============================================================
# 6. PLACEBO TREATMENT DATES
# ============================================================

# Test false treatment in Oct 2022 (1 year before actual)
trade_placebo_date <- trade |>
  filter(date < as.Date("2023-10-01")) |>
  mutate(
    post_placebo = as.integer(date >= as.Date("2022-10-01")),
    post_eu_covered_placebo = post_placebo * eu_dest * cbam_covered
  )

m_placebo_date <- feols(
  log_trade ~ post_eu_covered_placebo |
    cell_id + exp_month + dest_month + prod_month,
  data = trade_placebo_date,
  cluster = ~exp_dest
)

cat("\n=== PLACEBO: Oct 2022 treatment date ===\n")
print(coeftable(m_placebo_date))

# ============================================================
# 7. PPML ROBUSTNESS (levels, not logs)
# ============================================================

m_ppml_robust <- fepois(
  trade_value ~ post_eu_covered |
    cell_id + exp_month + dest_month + prod_month,
  data = trade |> filter(!exporter %in% c("RUS", "UKR")),
  cluster = ~exp_dest
)

cat("\n=== PPML excluding RUS/UKR ===\n")
print(coeftable(m_ppml_robust))

# ============================================================
# 8. IRON/STEEL ONLY (HS 72 vs 73)
# ============================================================

m_steel_only <- feols(
  log_trade ~ post_eu_covered |
    cell_id + exp_month + dest_month + prod_month,
  data = trade |> filter(hs2 %in% c("72", "73")),
  cluster = ~exp_dest
)

cat("\n=== IRON/STEEL ONLY (HS 72 vs 73) ===\n")
print(coeftable(m_steel_only))

# --- Save all robustness results ---
robust_results <- list(
  placebo_uncovered = placebo_uncovered,
  no_ruua = m_no_ruua,
  no_2020 = m_no_2020,
  no_us = m_no_us,
  dose_response = m_dose,
  high_carbon = m_high_carbon,
  low_carbon = m_low_carbon,
  placebo_date = m_placebo_date,
  ppml_no_ruua = m_ppml_robust,
  steel_only = m_steel_only
)

saveRDS(robust_results, "../data/robust_results.rds")
cat("\nAll robustness results saved.\n")
