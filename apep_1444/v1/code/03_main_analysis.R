# 03_main_analysis.R — Sharp RDD at age 65 for Ecuador pension
source("00_packages.R")

df <- as.data.table(readRDS("../data/analysis_sample.rds"))
cat(sprintf("Analysis sample: %s observations\n", format(nrow(df), big.mark = ",")))

# ============================================================================
# 1. FIRST STAGE: Pension/transfer receipt discontinuity at age 65
# ============================================================================
cat("\n=== FIRST STAGE: Transfer receipt at age 65 ===\n")

fs_full <- rdrobust(y = df$receives_transfer, x = df$age_c, c = 0)
cat("\nFull sample:\n")
summary(fs_full)

# Poor subsample
df_poor <- df[poor == 1]
cat(sprintf("\nPoor subsample: %s observations\n", format(nrow(df_poor), big.mark = ",")))

fs_poor <- rdrobust(y = df_poor$receives_transfer, x = df_poor$age_c, c = 0)
cat("\nPoor subsample:\n")
summary(fs_poor)

# ============================================================================
# 2. MAIN OUTCOMES: RDD at age 65
# ============================================================================
cat("\n=== MAIN OUTCOMES ===\n")

outcomes <- list(
  lfp = "Labor Force Participation",
  employed = "Employment",
  hours = "Weekly Hours Worked",
  labor_income = "Monthly Labor Income (USD)"
)

# Store results
results <- list()

for (var in names(outcomes)) {
  cat(sprintf("\n--- %s ---\n", outcomes[[var]]))

  # Full sample
  y <- df[[var]]
  rd <- rdrobust(y = y, x = df$age_c, c = 0)
  cat("Full sample:\n")
  summary(rd)

  results[[paste0(var, "_full")]] <- list(
    outcome = outcomes[[var]],
    sample = "Full",
    coef = rd$coef[1],  # Conventional
    se = rd$se[1],
    ci_l = rd$ci[1, 1],
    ci_u = rd$ci[1, 2],
    bw = rd$bws[1, 1],
    N_l = rd$N_h[1],
    N_r = rd$N_h[2],
    pval = rd$pv[1]
  )

  # Poor subsample
  y_poor <- df_poor[[var]]
  rd_poor <- rdrobust(y = y_poor, x = df_poor$age_c, c = 0)
  cat("\nPoor subsample:\n")
  summary(rd_poor)

  results[[paste0(var, "_poor")]] <- list(
    outcome = outcomes[[var]],
    sample = "Poor",
    coef = rd_poor$coef[1],
    se = rd_poor$se[1],
    ci_l = rd_poor$ci[1, 1],
    ci_u = rd_poor$ci[1, 2],
    bw = rd_poor$bws[1, 1],
    N_l = rd_poor$N_h[1],
    N_r = rd_poor$N_h[2],
    pval = rd_poor$pv[1]
  )
}

# ============================================================================
# 3. HETEROGENEITY: By sex and urban/rural
# ============================================================================
cat("\n=== HETEROGENEITY ===\n")

for (subgroup in c("female", "urban")) {
  for (val in 0:1) {
    label <- paste0(subgroup, "=", val)
    sub <- df[get(subgroup) == val]
    cat(sprintf("\n--- LFP: %s (N=%s) ---\n", label, format(nrow(sub), big.mark=",")))
    rd_sub <- rdrobust(y = sub$lfp, x = sub$age_c, c = 0)
    summary(rd_sub)
    results[[paste0("lfp_", subgroup, val)]] <- list(
      outcome = "LFP", sample = label,
      coef = rd_sub$coef[1], se = rd_sub$se[1],
      pval = rd_sub$pv[1], bw = rd_sub$bws[1,1]
    )
  }
}

# ============================================================================
# 4. McCRARY DENSITY TEST
# ============================================================================
cat("\n=== McCRARY DENSITY TEST ===\n")
density_test <- rddensity(X = df$age_c, c = 0)
summary(density_test)

# ============================================================================
# 5. COVARIATE BALANCE
# ============================================================================
cat("\n=== COVARIATE BALANCE AT CUTOFF ===\n")
covariates <- c("female", "urban", "education", "no_social_security")
cov_results <- list()
for (cov in covariates) {
  y_cov <- df[[cov]]
  if (all(is.na(y_cov))) next
  rd_cov <- rdrobust(y = y_cov, x = df$age_c, c = 0)
  cat(sprintf("\n%s: coef=%.4f, se=%.4f, p=%.3f\n",
              cov, rd_cov$coef[1], rd_cov$se[1], rd_cov$pv[1]))
  cov_results[[cov]] <- list(
    coef = rd_cov$coef[1], se = rd_cov$se[1], pval = rd_cov$pv[1]
  )
}

# ============================================================================
# 6. SAVE RESULTS
# ============================================================================
saveRDS(results, "../data/rdd_results.rds")
saveRDS(cov_results, "../data/cov_balance_results.rds")

# Write diagnostics.json for validator
n_treated <- nrow(df[above65 == 1])
n_pre <- length(unique(df$age[df$above65 == 0]))  # ages below cutoff
diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(df),
  design = "Sharp RDD",
  cutoff = 65,
  bandwidth = fs_full$bws[1, 1],
  quarters = length(unique(df$yq))
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Analysis complete. Results saved. ===\n")
