## 03_main_analysis.R — Main regressions for apep_1155
## Continuous DiD: homicide rate ~ gang_intensity × truce/collapse periods

source("00_packages.R")
data_dir <- "../data/"

panel <- readRDS(file.path(data_dir, "panel.rds"))
muni_data <- readRDS(file.path(data_dir, "muni_data.rds"))

stopifnot(nrow(panel) > 100)
stopifnot("gang_intensity_std" %in% names(panel))
stopifnot("hom_rate" %in% names(panel))

# ============================================================
# 1. Main specification: two-period continuous DiD
# ============================================================
cat("=== Main Specification: Two-Period Continuous DiD ===\n")

# (1) Baseline: no FE
m1 <- feols(hom_rate ~ gang_intensity_std * truce + gang_intensity_std * post_collapse,
            data = panel, cluster = ~muni_id)

# (2) Municipality FE only
m2 <- feols(hom_rate ~ gang_intensity_std:truce + gang_intensity_std:post_collapse | muni_id,
            data = panel, cluster = ~muni_id)

# (3) Municipality + Year FE (preferred)
m3 <- feols(hom_rate ~ gang_intensity_std:truce + gang_intensity_std:post_collapse | muni_id + year,
            data = panel, cluster = ~muni_id)

# (4) Log outcome
m4 <- feols(log_hom ~ gang_intensity_std:truce + gang_intensity_std:post_collapse | muni_id + year,
            data = panel, cluster = ~muni_id)

# (5) Binary treatment
m5 <- feols(hom_rate ~ high_gang:truce + high_gang:post_collapse | muni_id + year,
            data = panel, cluster = ~muni_id)

cat("  Model 3 (preferred, muni+year FE):\n")
print(summary(m3))
cat("\n  Model 5 (binary treatment):\n")
print(summary(m5))

# ============================================================
# 2. Event study: year-by-year effects
# ============================================================
cat("\n=== Event Study ===\n")

# Year dummies × gang intensity, reference = 2011 (rel_year = -1)
panel[, rel_year_f := factor(rel_year)]
panel[, rel_year_f := relevel(rel_year_f, ref = "-1")]

# Continuous treatment event study
es_cont <- feols(hom_rate ~ i(rel_year, gang_intensity_std, ref = -1) | muni_id + year,
                 data = panel, cluster = ~muni_id)

cat("  Event study coefficients:\n")
print(coeftable(es_cont))

# Binary treatment event study
es_bin <- feols(hom_rate ~ i(rel_year, high_gang, ref = -1) | muni_id + year,
                data = panel, cluster = ~muni_id)

# ============================================================
# 3. Symmetry test: does violence rebound fully?
# ============================================================
cat("\n=== Symmetry Test ===\n")

# Compare truce effect vs post-collapse effect
# If truce effect = -X and post-collapse effect = 0, the truce was temporary but harmless
# If post-collapse > 0, violence overshoot ("truce trap")
m3_ct <- coeftable(m3)
beta_truce <- m3_ct[grep("truce", rownames(m3_ct)), "Estimate"]
beta_collapse <- m3_ct[grep("post_collapse", rownames(m3_ct)), "Estimate"]
cat(sprintf("  Truce effect (β₁): %.3f\n", beta_truce))
cat(sprintf("  Post-collapse effect (β₂): %.3f\n", beta_collapse))
cat(sprintf("  Symmetry: β₂ + β₁ = %.3f (0 = symmetric, >0 = worse than before)\n",
            beta_collapse + beta_truce))

# Formal test: β₁ + β₂ = 0 (symmetric rebound)
tryCatch({
  wald_test <- wald(m3, "gang_intensity_std:truce + gang_intensity_std:post_collapse = 0")
  cat("  Wald test (β₁ + β₂ = 0):\n")
  print(wald_test)
}, error = function(e) {
  cat("  Wald test error:", e$message, "\n")
})

# ============================================================
# 4. Save results
# ============================================================
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  es_cont = es_cont, es_bin = es_bin
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================
# 5. Diagnostics for validation
# ============================================================
n_munis <- uniqueN(panel$muni_id)
n_pre <- uniqueN(panel[year < 2012]$year)
n_obs <- nrow(panel)
n_treated_above_median <- sum(muni_data$high_gang)

diagnostics <- list(
  n_treated = n_treated_above_median,
  n_pre = n_pre,
  n_obs = n_obs,
  n_municipalities = n_munis,
  n_years = uniqueN(panel$year),
  beta_truce = as.numeric(beta_truce),
  beta_collapse = as.numeric(beta_collapse),
  se_truce = as.numeric(m3_ct[grep("truce", rownames(m3_ct)), "Std. Error"]),
  se_collapse = as.numeric(m3_ct[grep("post_collapse", rownames(m3_ct)), "Std. Error"]),
  treatment_type = "continuous",
  outcome = "hom_rate",
  estimator = "TWFE_continuous_DiD"
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Diagnostics ===\n")
cat(sprintf("  N municipalities: %d\n", n_munis))
cat(sprintf("  N treated (above median): %d\n", n_treated_above_median))
cat(sprintf("  N pre-truce years: %d\n", n_pre))
cat(sprintf("  N observations: %d\n", n_obs))
cat("=== Done ===\n")
