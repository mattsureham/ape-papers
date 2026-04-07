## 04_robustness.R — Robustness checks and sensitivity
## apep_1408: PNIS coca substitution in Colombia

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

panel <- panel %>%
  mutate(
    muni_id = as.integer(factor(codmpio)),
    cohort = if_else(first_treat == 0, Inf, as.numeric(first_treat))
  )

## ─────────────────────────────────────────────────
## 1. Dose-response: Pre-PNIS coca intensity
## ─────────────────────────────────────────────────

cat("=== Dose-Response Analysis ===\n")

# Continuous treatment: coca_2016 × post
# Among PNIS municipalities only
pnis_panel <- panel %>% filter(pnis_enrolled == 1)

dose_est <- feols(
  ihs_coca ~ i(year, coca_2016, ref = 2016) | codmpio + year,
  data = pnis_panel,
  cluster = ~codmpio
)
cat("Dose-response (PNIS only, coca_2016 intensity):\n")
print(summary(dose_est))

saveRDS(dose_est, file.path(data_dir, "dose_results.rds"))

## ─────────────────────────────────────────────────
## 2. Placebo: Non-PNIS high-coca municipalities
## ─────────────────────────────────────────────────

cat("\n=== Placebo Test ===\n")

# Find non-PNIS municipalities with high coca in 2016
median_pnis_coca <- median(panel$coca_2016[panel$pnis_enrolled == 1])

placebo_panel <- panel %>%
  filter(pnis_enrolled == 0, coca_2016 >= median_pnis_coca)

cat("Placebo municipalities (non-PNIS, high coca):", n_distinct(placebo_panel$codmpio), "\n")

# Assign fake treatment at 2017
placebo_panel <- placebo_panel %>%
  mutate(
    fake_post = as.integer(year >= 2017),
    fake_first_treat = 2017L
  )

# Placebo: pre-period fake treatment at 2012 for PNIS municipalities
# If PNIS selection is unrelated to coca trends, fake treatment at 2012 should show null
placebo_pre <- panel %>%
  mutate(
    fake_cohort_pre = case_when(
      pnis_enrolled == 1 ~ 2012,
      TRUE ~ Inf
    )
  ) %>%
  filter(year <= 2016)  # Only pre-PNIS period

placebo_pre_est <- feols(
  ihs_coca ~ sunab(fake_cohort_pre, year) | codmpio + year,
  data = placebo_pre,
  cluster = ~codmpio
)
cat("Placebo (fake PNIS treatment at 2012, pre-period only):\n")
print(summary(placebo_pre_est))
saveRDS(placebo_pre_est, file.path(data_dir, "placebo_results.rds"))

## ─────────────────────────────────────────────────
## 3. Triple-difference: PNIS × post × coca_2016
## ─────────────────────────────────────────────────

cat("\n=== Triple-Difference ===\n")

# High vs low coca intensity within PNIS munis
panel <- panel %>%
  mutate(
    high_coca = as.integer(coca_2016 > median(coca_2016[pnis_enrolled == 1])),
    post_2017 = as.integer(year >= 2017)
  )

ddd_est <- feols(
  ihs_coca ~ pnis_enrolled:post_2017 + pnis_enrolled:high_coca +
    post_2017:high_coca + pnis_enrolled:post_2017:high_coca | codmpio + year,
  data = panel,
  cluster = ~codmpio
)
cat("DDD (PNIS × post × high_coca_2016):\n")
print(summary(ddd_est))
saveRDS(ddd_est, file.path(data_dir, "ddd_results.rds"))

## ─────────────────────────────────────────────────
## 4. Wild cluster bootstrap (few-cluster robustness)
## ─────────────────────────────────────────────────

cat("\n=== Wild Cluster Bootstrap ===\n")

# Department-level clustering (fewer clusters)
twfe_dept <- feols(
  ihs_coca ~ post_2017:pnis_enrolled | codmpio + year,
  data = panel,
  cluster = ~coddepto
)
cat("TWFE clustered at department level:\n")
print(summary(twfe_dept))

# Wild cluster bootstrap at department level
boot_res <- tryCatch({
  boottest(
    twfe_dept,
    param = "post_2017:pnis_enrolled",
    clustid = ~coddepto,
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat("Wild bootstrap error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_res)) {
  cat("Wild cluster bootstrap p-value:", boot_res$p_val, "\n")
  saveRDS(boot_res, file.path(data_dir, "wcb_results.rds"))
}

## ─────────────────────────────────────────────────
## 5. Alternative outcomes
## ─────────────────────────────────────────────────

cat("\n=== Alternative Outcome: Level coca_ha ===\n")

sunab_level <- feols(
  coca_ha ~ sunab(cohort, year) | codmpio + year,
  data = panel,
  cluster = ~codmpio
)
cat("Sun-Abraham on level coca_ha:\n")
# Just report aggregate ATT
iplot_data <- coeftable(sunab_level)
post_coefs <- iplot_data[grep("year::[0-9]", rownames(iplot_data)), ]
cat("Post-treatment coefficients:\n")
print(post_coefs)

saveRDS(sunab_level, file.path(data_dir, "sunab_level_results.rds"))

## ─────────────────────────────────────────────────
## 6. Excluding outlier year (2019 coca surge)
## ─────────────────────────────────────────────────

cat("\n=== Excluding 2019 ===\n")

sunab_no2019 <- feols(
  ihs_coca ~ sunab(cohort, year) | codmpio + year,
  data = panel %>% filter(year != 2019),
  cluster = ~codmpio
)
cat("Sun-Abraham excluding 2019:\n")
post_coefs_no2019 <- coeftable(sunab_no2019)[grep("year::[0-9]", rownames(coeftable(sunab_no2019))), ]
print(post_coefs_no2019)

saveRDS(sunab_no2019, file.path(data_dir, "sunab_no2019_results.rds"))

## ─────────────────────────────────────────────────
## 7. HonestDiD sensitivity (pre-trend violations)
## ─────────────────────────────────────────────────

cat("\n=== HonestDiD Sensitivity ===\n")

sunab_main <- readRDS(file.path(data_dir, "sunab_results.rds"))

# Extract pre and post coefficients for HonestDiD
coef_names <- names(coef(sunab_main))
pre_idx <- grep("year::-[0-9]+$", coef_names)
post_idx <- grep("year::[0-9]+$", coef_names)

if (length(pre_idx) > 0 & length(post_idx) > 0) {
  tryCatch({
    # Use relative magnitudes approach
    betahat <- coef(sunab_main)[c(pre_idx, post_idx)]
    sigma <- vcov(sunab_main)[c(pre_idx, post_idx), c(pre_idx, post_idx)]

    # Relative magnitudes: how much would PT violations need to be
    # to explain away the result?
    delta_rm <- createSensitivityResults_relativeMagnitudes(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD relative magnitudes:\n")
    print(delta_rm)
    saveRDS(delta_rm, file.path(data_dir, "honestdid_results.rds"))
  }, error = function(e) {
    cat("HonestDiD error:", conditionMessage(e), "\n")
  })
}

cat("\nAll robustness checks complete.\n")
