# ── 03_main_analysis.R ─────────────────────────────────────────────
# Main DiD estimation: 14th FC windfall × post on nightlights
# ───────────────────────────────────────────────────────────────────
source("code/00_packages.R")

panel <- fread("data/district_panel_clean.csv")
cat(sprintf("Analysis panel: %d obs, %d districts, %d states\n",
            nrow(panel), uniqueN(panel$district_id), uniqueN(panel$pc11_state_id)))

# ── 1. Main specification: Continuous treatment DiD ───────────────
cat("\n=== Main Specification ===\n")

# Primary: log(total_light) ~ windfall_pc_z × post | district + year
m1 <- feols(log_light ~ windfall_pc_z:post | district_id + year,
            data = panel, cluster = ~pc11_state_id)
cat("Model 1: log(total_light) ~ windfall × post | district + year\n")
print(summary(m1))

# Alternative outcome: log(mean_light)
m2 <- feols(log_mean_light ~ windfall_pc_z:post | district_id + year,
            data = panel, cluster = ~pc11_state_id)

# With state-specific linear trends (absorbs differential pre-trends)
panel[, state_year := as.numeric(year)]
m3 <- feols(log_light ~ windfall_pc_z:post | district_id + year +
              pc11_state_id[state_year],
            data = panel, cluster = ~pc11_state_id)

# ── 2. Event study ───────────────────────────────────────────────
cat("\n=== Event Study ===\n")

# Create event-time dummies (omit -1 = 2014 as reference)
panel[, et := factor(event_time)]

m_es <- feols(log_light ~ i(event_time, windfall_pc_z, ref = -1) |
                district_id + year,
              data = panel, cluster = ~pc11_state_id)
cat("Event study coefficients:\n")
print(coeftable(m_es))

# ── 3. Pairs cluster bootstrap for main specification ─────────────
cat("\n=== Pairs Cluster Bootstrap (28 state clusters) ===\n")
# Resample entire states (pairs bootstrap)
set.seed(20260329)
B <- 999
states <- unique(panel$pc11_state_id)
boot_coefs <- numeric(B)

for (b in 1:B) {
  boot_states <- sample(states, replace = TRUE)
  # Build resampled dataset
  boot_data <- rbindlist(lapply(seq_along(boot_states), function(i) {
    d <- panel[pc11_state_id == boot_states[i]]
    d[, boot_state := i]  # Relabel to avoid duplicate state IDs
    d
  }))
  boot_data[, boot_district := paste0(boot_state, "_", district_id)]
  m_boot <- tryCatch(
    feols(log_light ~ windfall_pc_z:post | boot_district + year,
          data = boot_data, cluster = ~boot_state),
    error = function(e) NULL
  )
  if (!is.null(m_boot)) {
    boot_coefs[b] <- coef(m_boot)["windfall_pc_z:post"]
  } else {
    boot_coefs[b] <- NA
  }
}

boot_coefs <- boot_coefs[!is.na(boot_coefs)]
boot_se <- sd(boot_coefs)
boot_pval <- 2 * min(mean(boot_coefs >= 0), mean(boot_coefs <= 0))
boot_ci <- quantile(boot_coefs, c(0.025, 0.975))

cat(sprintf("Pairs bootstrap SE: %.4f (analytical: %.4f)\n",
            boot_se, se(m1)["windfall_pc_z:post"]))
cat(sprintf("Bootstrap p-value: %.3f\n", boot_pval))
cat(sprintf("Bootstrap 95%% CI: [%.4f, %.4f]\n", boot_ci[1], boot_ci[2]))

boot_m1 <- list(p_val = boot_pval, conf_int = as.numeric(boot_ci), se = boot_se)

# ── 4. Pre-trend test ────────────────────────────────────────────
cat("\n=== Pre-trend Formal Test ===\n")
# Joint F-test on pre-treatment event-study coefficients
pre_coefs <- grep("event_time::-[2-3]", names(coef(m_es)), value = TRUE)
if (length(pre_coefs) > 0) {
  pre_test <- wald(m_es, pre_coefs)
  cat(sprintf("Joint pre-trend test: F = %.3f, p = %.4f\n",
              pre_test$stat, pre_test$p))
}

# ── 5. Save results ──────────────────────────────────────────────
n_treated <- uniqueN(panel$pc11_state_id)
n_pre <- uniqueN(panel[year < 2015, year])
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_districts = uniqueN(panel$district_id),
  n_states = n_treated,
  main_coef = coef(m1)["windfall_pc_z:post"],
  main_se = se(m1)["windfall_pc_z:post"],
  main_pval = pvalue(m1)["windfall_pc_z:post"],
  wcb_pval = if (!is.null(boot_m1)) boot_m1$p_val else NA_real_
)
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

# Save models for table generation
save(m1, m2, m3, m_es, boot_m1, panel,
     file = "data/main_results.RData")
cat("\nMain results saved.\n")
