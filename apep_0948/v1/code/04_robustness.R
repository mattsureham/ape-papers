# 04_robustness.R — Robustness checks and placebo tests
# Paper: The Fiscal Shadow of the Pill Mill (apep_0948)

source("00_packages.R")

df <- arrow::read_parquet("../data/analysis_state.parquet")
results <- readRDS("../data/main_results.rds")

# =============================================================================
# 1. PLACEBO: Non-opioid SUD treatment
# =============================================================================
cat("\n=== Placebo: Non-Opioid SUD Treatment ===\n")

rf_placebo <- feols(log_nonopioid_claims_pc ~ triplicate + log_population +
                      poverty_rate + uninsured_rate, data = df, vcov = "HC1")
cat("Reduced form — Non-opioid SUD:\n")
cat(sprintf("  coef=%.3f, se=%.3f, p=%.3f\n",
            coef(rf_placebo)["triplicate"],
            sqrt(vcov(rf_placebo)["triplicate","triplicate"]),
            2*pt(-abs(coef(rf_placebo)["triplicate"]/sqrt(vcov(rf_placebo)["triplicate","triplicate"])),
                 nobs(rf_placebo)-5)))

iv_placebo <- feols(log_nonopioid_claims_pc ~ log_population + poverty_rate +
                      uninsured_rate | log_oxy_pc ~ triplicate,
                    data = df, vcov = "HC1")
cat("IV — Non-opioid SUD:\n")
print(summary(iv_placebo))

# =============================================================================
# 2. Anderson-Rubin test
# =============================================================================
cat("\n=== Anderson-Rubin Test ===\n")
rf_model <- feols(log_mat_claims_pc ~ triplicate + log_population +
                    poverty_rate + uninsured_rate, data = df, vcov = "HC1")
rf_coef <- coef(rf_model)["triplicate"]
rf_se <- sqrt(vcov(rf_model)["triplicate", "triplicate"])
ar_stat <- (rf_coef / rf_se)^2
ar_pval <- 1 - pchisq(ar_stat, df = 1)
cat(sprintf("AR stat: %.3f (p=%.4f)\n", ar_stat, ar_pval))

# =============================================================================
# 3. Leave-one-out
# =============================================================================
cat("\n=== Leave-One-Out ===\n")

trip_states <- df$state_abb[df$triplicate == 1]
loo_results <- data.frame(
  dropped = character(), coef = numeric(), se = numeric(),
  f_stat = numeric(), stringsAsFactors = FALSE
)

for (s in trip_states) {
  df_loo <- df |> filter(state_abb != s)
  iv_loo <- tryCatch({
    feols(log_mat_claims_pc ~ log_population + poverty_rate +
            uninsured_rate | log_oxy_pc ~ triplicate,
          data = df_loo, vcov = "HC1")
  }, error = function(e) NULL)

  if (!is.null(iv_loo)) {
    loo_results <- rbind(loo_results, data.frame(
      dropped = s,
      coef = coef(iv_loo)["fit_log_oxy_pc"],
      se = sqrt(vcov(iv_loo)["fit_log_oxy_pc", "fit_log_oxy_pc"]),
      f_stat = fitstat(iv_loo, "ivf")$ivf1$stat,
      stringsAsFactors = FALSE
    ))
  }
}

cat("Leave-one-out:\n")
print(loo_results)

# =============================================================================
# 4. Specification robustness
# =============================================================================
cat("\n=== Specification Robustness ===\n")

iv_nocontrols <- feols(log_mat_claims_pc ~ 1 | log_oxy_pc ~ triplicate,
                       data = df, vcov = "HC1")
iv_pop <- feols(log_mat_claims_pc ~ log_population | log_oxy_pc ~ triplicate,
                data = df, vcov = "HC1")
iv_expansion <- feols(log_mat_claims_pc ~ log_population + poverty_rate +
                        uninsured_rate + medicaid_expansion |
                        log_oxy_pc ~ triplicate,
                      data = df, vcov = "HC1")

cat(sprintf("No controls:      coef=%.3f, se=%.3f, F=%.1f\n",
            coef(iv_nocontrols)["fit_log_oxy_pc"],
            sqrt(vcov(iv_nocontrols)["fit_log_oxy_pc","fit_log_oxy_pc"]),
            fitstat(iv_nocontrols, "ivf")$ivf1$stat))
cat(sprintf("Pop only:         coef=%.3f, se=%.3f, F=%.1f\n",
            coef(iv_pop)["fit_log_oxy_pc"],
            sqrt(vcov(iv_pop)["fit_log_oxy_pc","fit_log_oxy_pc"]),
            fitstat(iv_pop, "ivf")$ivf1$stat))
cat(sprintf("+ Expansion:      coef=%.3f, se=%.3f, F=%.1f\n",
            coef(iv_expansion)["fit_log_oxy_pc"],
            sqrt(vcov(iv_expansion)["fit_log_oxy_pc","fit_log_oxy_pc"]),
            fitstat(iv_expansion, "ivf")$ivf1$stat))

# =============================================================================
# 5. Levels specification
# =============================================================================
cat("\n=== Levels Specification ===\n")
iv_levels <- feols(mat_claims_pc ~ log_population + poverty_rate +
                     uninsured_rate | oxy_pc ~ triplicate,
                   data = df, vcov = "HC1")
cat("IV in levels:\n")
print(summary(iv_levels))

# =============================================================================
# 6. Save robustness results
# =============================================================================
robustness <- list(
  placebo_rf = list(
    coef = coef(rf_placebo)["triplicate"],
    se = sqrt(vcov(rf_placebo)["triplicate","triplicate"]),
    n = nobs(rf_placebo)
  ),
  placebo_iv = list(
    coef = coef(iv_placebo)["fit_log_oxy_pc"],
    se = sqrt(vcov(iv_placebo)["fit_log_oxy_pc","fit_log_oxy_pc"]),
    n = nobs(iv_placebo)
  ),
  ar_test = list(stat = ar_stat, pval = ar_pval),
  iv_levels = list(
    coef = coef(iv_levels)["fit_oxy_pc"],
    se = sqrt(vcov(iv_levels)["fit_oxy_pc","fit_oxy_pc"]),
    n = nobs(iv_levels)
  ),
  loo = loo_results,
  iv_nocontrols = list(
    coef = coef(iv_nocontrols)["fit_log_oxy_pc"],
    se = sqrt(vcov(iv_nocontrols)["fit_log_oxy_pc","fit_log_oxy_pc"]),
    f_stat = fitstat(iv_nocontrols, "ivf")$ivf1$stat
  ),
  iv_pop = list(
    coef = coef(iv_pop)["fit_log_oxy_pc"],
    se = sqrt(vcov(iv_pop)["fit_log_oxy_pc","fit_log_oxy_pc"]),
    f_stat = fitstat(iv_pop, "ivf")$ivf1$stat
  ),
  iv_expansion = list(
    coef = coef(iv_expansion)["fit_log_oxy_pc"],
    se = sqrt(vcov(iv_expansion)["fit_log_oxy_pc","fit_log_oxy_pc"]),
    f_stat = fitstat(iv_expansion, "ivf")$ivf1$stat
  )
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== Robustness complete ===\n")
