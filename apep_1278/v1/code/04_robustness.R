## 04_robustness.R — Robustness checks and falsification tests
## apep_1278: The Compliance Lottery

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
results <- readRDS("../data/main_results.rds")

cat("=== Robustness Checks ===\n")

# -----------------------------------------------------------------------
# 1. Cancellation reversal test
# -----------------------------------------------------------------------
cat("\n--- Cancellation Reversal Test ---\n")

# Focus on countries that cancelled: Slovakia (end 2020), Czech Republic (end 2019), Poland (end 2016)
# If lottery reduced gap, cancellation should increase it

cancelled <- panel %>%
  filter(country %in% c("SK", "CZ", "PL"), !is.na(vat_gap_pct)) %>%
  mutate(
    cancel_year = case_when(
      country == "SK" ~ 2021L,
      country == "CZ" ~ 2020L,
      country == "PL" ~ 2017L
    ),
    post_cancel = as.integer(year >= cancel_year),
    during_lottery = lottery_active
  )

# Simple test: compare gap change pre-cancel vs post-cancel
cancel_summary <- cancelled %>%
  group_by(country) %>%
  summarise(
    mean_gap_during = mean(vat_gap_pct[lottery_active == 1], na.rm = TRUE),
    mean_gap_after = mean(vat_gap_pct[year >= cancel_year], na.rm = TRUE),
    gap_change = mean_gap_after - mean_gap_during,
    .groups = "drop"
  )
cat("Gap change after lottery cancellation (positive = gap widened):\n")
print(cancel_summary)

# -----------------------------------------------------------------------
# 2. Placebo outcome: Income tax / GDP (should not respond to VAT lottery)
# -----------------------------------------------------------------------
cat("\n--- Placebo: Income Tax / GDP ---\n")

placebo_twfe <- feols(
  income_tax_gdp_ratio ~ lottery_active | country_id + year,
  data = panel %>% filter(!is.na(income_tax_gdp_ratio), country != "MT"),
  cluster = ~country_id
)
summary(placebo_twfe)

# -----------------------------------------------------------------------
# 3. Wild cluster bootstrap (few-cluster inference)
# -----------------------------------------------------------------------
cat("\n--- Wild Cluster Bootstrap ---\n")

# Use fwildclusterboot on the TWFE specification
twfe_for_boot <- feols(
  vat_gap_pct ~ lottery_active | country_id + year,
  data = panel %>% filter(!is.na(vat_gap_pct), country != "MT"),
  cluster = ~country_id
)

boot_result <- tryCatch({
  boottest(
    twfe_for_boot,
    param = "lottery_active",
    B = 9999,
    clustid = ~country_id,
    type = "webb"
  )
}, error = function(e) {
  cat("  Wild bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Wild cluster bootstrap results:\n")
  print(summary(boot_result))
}

# -----------------------------------------------------------------------
# 4. Leave-one-out (drop each treated country)
# -----------------------------------------------------------------------
cat("\n--- Leave-One-Out ---\n")

treated_countries <- panel %>%
  filter(ever_treated, country != "MT", cs_group > 0) %>%
  pull(country) %>%
  unique()

loo_results <- data.frame(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (drop_c in treated_countries) {
  loo_mod <- feols(
    vat_gap_pct ~ lottery_active | country_id + year,
    data = panel %>% filter(!is.na(vat_gap_pct), country != "MT", country != drop_c),
    cluster = ~country_id
  )
  loo_results <- rbind(loo_results, data.frame(
    dropped = drop_c,
    coef = coef(loo_mod)["lottery_active"],
    se = se(loo_mod)["lottery_active"],
    stringsAsFactors = FALSE
  ))
}

cat("Leave-one-out TWFE estimates:\n")
print(loo_results)
cat(sprintf("  Range of coefficients: [%.2f, %.2f]\n",
            min(loo_results$coef), max(loo_results$coef)))

# -----------------------------------------------------------------------
# 5. HonestDiD sensitivity (Rambachan-Roth bounds)
# -----------------------------------------------------------------------
cat("\n--- HonestDiD Sensitivity ---\n")

honest_result <- tryCatch({
  cs_dynamic <- results$cs_dynamic

  # Extract event study coefficients for HonestDiD
  betahat <- cs_dynamic$att.egt
  sigma <- cs_dynamic$V_analytical

  # Identify pre and post periods
  e <- cs_dynamic$egt
  pre_idx <- which(e < 0)
  post_idx <- which(e >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1 && !is.null(sigma)) {
    # Relative magnitudes approach
    honest <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD sensitivity results:\n")
    print(honest)
    honest
  } else {
    cat("  Insufficient pre/post periods for HonestDiD\n")
    NULL
  }
}, error = function(e) {
  cat("  HonestDiD error:", e$message, "\n")
  NULL
})

# -----------------------------------------------------------------------
# 6. Alternative outcome: VAT revenue / GDP ratio
# -----------------------------------------------------------------------
cat("\n--- Alternative Outcome: VAT/GDP Ratio ---\n")

cs_data_vat <- panel %>%
  filter(country != "MT") %>%
  mutate(
    cs_group_clean = case_when(
      country %in% c("SK", "PL", "CZ", "LV") ~ as.integer(lottery_start),
      is.na(lottery_start) ~ 0L,
      TRUE ~ as.integer(lottery_start)
    )
  )

cs_vat <- tryCatch({
  att_gt(
    yname = "vat_gdp_ratio",
    tname = "year",
    idname = "country_id",
    gname = "cs_group_clean",
    data = cs_data_vat,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying",
    bstrap = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("  CS VAT/GDP error:", e$message, "\n")
  NULL
})

if (!is.null(cs_vat)) {
  cs_vat_agg <- aggte(cs_vat, type = "simple")
  cat("CS ATT for VAT/GDP ratio:\n")
  summary(cs_vat_agg)
}

# -----------------------------------------------------------------------
# 7. Save robustness results
# -----------------------------------------------------------------------
robustness <- list(
  cancel_summary = cancel_summary,
  placebo = placebo_twfe,
  boot_result = boot_result,
  loo_results = loo_results,
  honest_result = honest_result,
  cs_vat = if (!is.null(cs_vat)) aggte(cs_vat, type = "simple") else NULL
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("=== Robustness complete ===\n")
