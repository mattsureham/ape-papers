## 04_robustness.R — Robustness checks
## apep_1254: Portugal Golden Visa Geographic Restriction

source("00_packages.R")

df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
load("../data/main_models.RData")

cat("=== Robustness Checks ===\n")

# ============================================================
# 1. Wild cluster bootstrap (manual implementation)
# ============================================================
cat("\n--- Wild Cluster Bootstrap ---\n")

# Manual wild cluster bootstrap for the DiD coefficient
set.seed(42)
B <- 9999

clusters <- unique(df$nuts3_approx)
n_clusters <- length(clusters)

# Original estimate
orig_coef <- coef(did_log)[["treated:post"]]
orig_se <- sqrt(vcov(did_log)[["treated:post", "treated:post"]])
orig_t <- orig_coef / orig_se

boot_t_stats <- numeric(B)

for (b in seq_len(B)) {
  # Rademacher weights: +1 or -1 per cluster
  weights <- sample(c(-1, 1), n_clusters, replace = TRUE)
  names(weights) <- clusters

  df_boot <- df %>%
    mutate(
      w = weights[nuts3_approx],
      # Wild bootstrap: perturb residuals at cluster level
      log_value_boot = fitted(did_log) + residuals(did_log) * w
    )

  boot_model <- tryCatch({
    feols(log_value_boot ~ treated:post | geocod + ym, data = df_boot, cluster = ~nuts3_approx)
  }, error = function(e) NULL)

  if (!is.null(boot_model)) {
    boot_coef <- coef(boot_model)[["treated:post"]]
    boot_se <- sqrt(vcov(boot_model)[["treated:post", "treated:post"]])
    boot_t_stats[b] <- (boot_coef - orig_coef) / boot_se
  } else {
    boot_t_stats[b] <- NA
  }
}

boot_t_stats <- boot_t_stats[!is.na(boot_t_stats)]
boot_pval <- mean(abs(boot_t_stats) >= abs(orig_t))
# Bootstrap confidence interval (percentile-t)
boot_ci_lower <- orig_coef - quantile(boot_t_stats, 0.975) * orig_se
boot_ci_upper <- orig_coef - quantile(boot_t_stats, 0.025) * orig_se
boot_ci <- c(boot_ci_lower, boot_ci_upper)

cat(sprintf("Wild bootstrap p-value: %.4f\n", boot_pval))
cat(sprintf("Wild bootstrap 95%% CI: [%.4f, %.4f]\n", boot_ci[1], boot_ci[2]))

# ============================================================
# 2. Placebo treatment dates
# ============================================================
cat("\n--- Placebo Treatment Dates ---\n")

# Placebo 1: January 2018
df_placebo1 <- df %>%
  filter(date < as.Date("2022-01-01")) %>%  # Pre-treatment only

mutate(post_placebo = as.integer(date >= as.Date("2018-01-01")))

placebo_2018 <- feols(
  log_value ~ treated:post_placebo | geocod + ym,
  data = df_placebo1,
  cluster = ~nuts3_approx
)
cat("Placebo 2018:\n")
summary(placebo_2018)

# Placebo 2: January 2019
df_placebo2 <- df %>%
  filter(date < as.Date("2022-01-01")) %>%
  mutate(post_placebo = as.integer(date >= as.Date("2019-01-01")))

placebo_2019 <- feols(
  log_value ~ treated:post_placebo | geocod + ym,
  data = df_placebo2,
  cluster = ~nuts3_approx
)
cat("Placebo 2019:\n")
summary(placebo_2019)

# ============================================================
# 3. Excluding COVID period (2020-2021)
# ============================================================
cat("\n--- Excluding COVID period ---\n")

df_no_covid <- df %>%
  filter(!(year %in% c(2020, 2021)))

did_no_covid <- feols(
  log_value ~ treated:post | geocod + ym,
  data = df_no_covid,
  cluster = ~nuts3_approx
)
cat("Excluding 2020-2021:\n")
summary(did_no_covid)

# ============================================================
# 4. Shorter post-period (2022 only — before Mais Habitação)
# ============================================================
cat("\n--- Shorter post-period (2022 only) ---\n")

df_short <- df %>%
  filter(year <= 2022)

did_short <- feols(
  log_value ~ treated:post | geocod + ym,
  data = df_short,
  cluster = ~nuts3_approx
)
summary(did_short)

# ============================================================
# 5. HonestDiD sensitivity analysis
# ============================================================
cat("\n--- HonestDiD Sensitivity ---\n")

honest_result <- tryCatch({
  # Need event study for HonestDiD
  es_for_honest <- feols(
    log_value ~ i(event_time_binned, treated, ref = -1) | geocod + ym,
    data = df %>% mutate(
      event_time_binned = case_when(
        event_time <= -24 ~ -24L,
        event_time >= 24 ~ 24L,
        TRUE ~ event_time
      )
    ),
    cluster = ~nuts3_approx
  )

  # Extract coefficients and variance-covariance matrix
  es_terms <- names(coef(es_for_honest))
  pre_terms <- es_terms[grepl("::-[0-9]", es_terms)]
  post_terms <- es_terms[grepl("::[0-9]", es_terms)]

  if (length(pre_terms) >= 2 && length(post_terms) >= 1) {
    beta_hat <- coef(es_for_honest)
    sigma_hat <- vcov(es_for_honest)

    # Create HonestDiD inputs
    l_vec <- rep(0, length(beta_hat))
    # Average post-treatment effect
    post_idx <- which(names(beta_hat) %in% post_terms)
    l_vec[post_idx] <- 1 / length(post_idx)

    honest_ci <- HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_terms),
      numPostPeriods = length(post_terms),
      Mbarvec = seq(0, 0.05, by = 0.01),
      l_vec = l_vec
    )
    cat("HonestDiD sensitivity analysis completed.\n")
    honest_ci
  } else {
    cat("Insufficient pre/post terms for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD error:", e$message, "\n")
  NULL
})

# ============================================================
# 6. Levels specification robustness
# ============================================================
cat("\n--- Levels specification ---\n")
did_levels_robust <- feols(
  value ~ treated:post | geocod + ym,
  data = df,
  cluster = ~nuts3_approx
)
summary(did_levels_robust)

# ============================================================
# Save all robustness results
# ============================================================
robustness <- list(
  boot_pval = boot_pval,
  boot_ci_lower = boot_ci[1],
  boot_ci_upper = boot_ci[2],
  placebo_2018_coef = coef(placebo_2018)[["treated:post_placebo"]],
  placebo_2018_pval = pvalue(placebo_2018)[["treated:post_placebo"]],
  placebo_2019_coef = coef(placebo_2019)[["treated:post_placebo"]],
  placebo_2019_pval = pvalue(placebo_2019)[["treated:post_placebo"]],
  no_covid_coef = coef(did_no_covid)[["treated:post"]],
  no_covid_pval = pvalue(did_no_covid)[["treated:post"]],
  short_post_coef = coef(did_short)[["treated:post"]],
  short_post_pval = pvalue(did_short)[["treated:post"]]
)

jsonlite::write_json(robustness, "../data/robustness_results.json", auto_unbox = TRUE)

save(placebo_2018, placebo_2019, did_no_covid, did_short, did_levels_robust,
     boot_pval, boot_ci, honest_result,
     file = "../data/robustness_models.RData")

cat("\nAll robustness checks complete.\n")
