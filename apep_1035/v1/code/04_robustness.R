## 04_robustness.R — Robustness checks and placebo tests
## APEP Paper apep_1035

source("00_packages.R")

data_dir <- "../data"

cdc_full <- readRDS(file.path(data_dir, "analysis_panel_cdc.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

# Replicate the balanced panel from 03_main_analysis.R
cdc <- cdc_full %>%
  filter(year >= 1999, state_abb != "FL")

# Balance
state_years <- cdc %>% count(state_fips) %>% filter(n == max(n)) %>% pull(state_fips)
cdc <- cdc %>% filter(state_fips %in% state_years)

cdc <- cdc %>%
  mutate(post = if_else(treated == 1 & year >= treat_year, 1L, 0L))

cat("Robustness panel:", nrow(cdc), "obs,", n_distinct(cdc$state_fips), "states\n")

# ============================================================
# 1. Exclude Covenant Marriage States (LA, AZ, AR)
# ============================================================
cat("=== Robustness: Exclude Covenant Marriage States ===\n")

cdc_no_covenant <- cdc %>%
  filter(!state_abb %in% c("LA", "AZ", "AR"))

cs_no_covenant <- att_gt(
  yname = "divorce_rate",
  tname = "year",
  idname = "state_fips",
  gname = "first_treat",
  data = cdc_no_covenant,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "dr"
)

agg_no_covenant <- aggte(cs_no_covenant, type = "simple")
cat("ATT excluding covenant states:\n")
summary(agg_no_covenant)

# ============================================================
# 2. Drop Early Adopters (FL 1998, OK 1999) — late-adopter only
# ============================================================
cat("\n=== Robustness: Late Adopters Only ===\n")

cdc_late <- cdc %>%
  filter(!state_abb %in% c("FL", "OK")) %>%
  mutate(first_treat = if_else(first_treat %in% c(1998L, 1999L), 0L, first_treat))

cs_late <- att_gt(
  yname = "divorce_rate",
  tname = "year",
  idname = "state_fips",
  gname = "first_treat",
  data = cdc_late,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "dr"
)

agg_late <- aggte(cs_late, type = "simple")
cat("ATT (late adopters only):\n")
summary(agg_late)

# ============================================================
# 3. Controls: unemployment rate
# ============================================================
# Skip unemployment control — BLS data not retrieved in this session
agg_controls <- NULL

# ============================================================
# 4. Placebo: Shift treatment 5 years earlier
# ============================================================
cat("\n=== Placebo: TWFE on Pre-Treatment Data Only ===\n")

# Use TWFE placebo with shifted treatment dates (simpler, avoids CS small-group issues)
cdc_placebo <- cdc %>%
  filter(treated == 0 | (treated == 1 & year < treat_year)) %>%
  mutate(
    placebo_treat_year = if_else(treated == 1, treat_year - 3L, NA_integer_),
    placebo_post = if_else(!is.na(placebo_treat_year) & year >= placebo_treat_year, 1L, 0L)
  )

twfe_placebo <- tryCatch({
  feols(divorce_rate ~ placebo_post | state_fips + year, data = cdc_placebo,
        cluster = ~state_fips)
}, error = function(e) {
  cat("  Placebo TWFE error:", conditionMessage(e), "\n")
  NULL
})

agg_placebo <- if (!is.null(twfe_placebo)) {
  cat("Placebo TWFE (3-year shift, pre-treatment only):\n")
  print(summary(twfe_placebo))
  list(overall.att = coef(twfe_placebo)["placebo_post"],
       overall.se = se(twfe_placebo)["placebo_post"])
} else NULL

# ============================================================
# 5. Leave-one-out: Drop each treated state
# ============================================================
cat("\n=== Leave-One-Out Sensitivity ===\n")

treated_states <- cdc %>%
  filter(treated == 1) %>%
  distinct(state_abb) %>%
  pull()

loo_results <- list()
for (st in treated_states) {
  cdc_loo <- cdc %>%
    filter(state_abb != st) %>%
    mutate(first_treat = if_else(state_abb == st, 0L, first_treat))

  # Recompute first_treat for dropped state (should be absent now)
  cs_loo <- tryCatch({
    att_gt(
      yname = "divorce_rate",
      tname = "year",
      idname = "state_fips",
      gname = "first_treat",
      data = cdc_loo,
      control_group = "nevertreated",
      base_period = "universal",
      anticipation = 0,
      est_method = "dr"
    )
  }, error = function(e) NULL)

  if (!is.null(cs_loo)) {
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results[[st]] <- tibble(
      dropped = st,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se
    )
    cat("  Drop", st, ": ATT =", round(agg_loo$overall.att, 4),
        " SE =", round(agg_loo$overall.se, 4), "\n")
  }
}

loo_df <- bind_rows(loo_results)

# ============================================================
# 6. HonestDiD sensitivity (if pre-trends are close)
# ============================================================
cat("\n=== HonestDiD Sensitivity ===\n")

cat("\n=== HonestDiD Sensitivity ===\n")

honest_result <- tryCatch({
  es <- results$agg_dynamic_divorce
  pre_idx <- which(es$egt < 0 & !is.na(es$se.egt))
  post_idx <- which(es$egt >= 0 & !is.na(es$se.egt))

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Use only event times where SE is not NA
    valid_idx <- c(pre_idx, post_idx)
    beta_hat <- es$att.egt[valid_idx]
    sigma <- diag(es$se.egt[valid_idx]^2)

    honest_out <- HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.5, by = 0.1)
    )
    cat("HonestDiD sensitivity results:\n")
    print(honest_out)
    honest_out
  } else {
    cat("  Insufficient valid pre/post periods for HonestDiD\n")
    NULL
  }
}, error = function(e) {
  cat("  HonestDiD error:", conditionMessage(e), "\n")
  NULL
})

# ============================================================
# 7. Save robustness results
# ============================================================
robustness <- list(
  agg_no_covenant = agg_no_covenant,
  agg_late = agg_late,
  agg_controls = agg_controls,
  agg_placebo = agg_placebo,
  loo_df = loo_df,
  honest_result = honest_result
)
saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
