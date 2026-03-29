# =============================================================================
# 03_main_analysis.R — Event study DiD: FL pill mill crackdown on dosage comp
# =============================================================================

source("00_packages.R")

dt <- fread("../data/county_month_panel.csv")

# Filter to counties with >=100 avg pills/month
county_avg <- dt[, .(avg_pills = mean(total_oxy_pills)), by = county_id]
keep <- county_avg[avg_pills >= 100]$county_id
dt <- dt[county_id %in% keep]

cat("Analysis panel:", nrow(dt), "obs,", uniqueN(dt$county_id), "counties\n")
cat("FL:", uniqueN(dt[fl == 1]$county_id), "counties\n")
cat("GA+AL:", uniqueN(dt[fl == 0]$county_id), "counties\n")

# ---------------------------------------------------------------------------
# Convert to factors for fixest
# ---------------------------------------------------------------------------
dt[, county_id := as.factor(county_id)]
dt[, ym_fac := as.factor(ym_int)]

# Pill weights for volume-weighted regressions
dt[, weight := total_oxy_pills]

# ---------------------------------------------------------------------------
# 1. Main DiD: static (both unweighted and pill-weighted)
# ---------------------------------------------------------------------------
cat("\n=== Static DiD (Unweighted) ===\n")

# (1a) High-dose share — unweighted
m1_uw <- feols(high_dose_share ~ treated | county_id + ym_fac,
               data = dt, cluster = ~BUYER_STATE)
cat("Unweighted:\n")
print(summary(m1_uw))

# (1b) High-dose share — pill-weighted (PREFERRED: captures where pill mills operate)
cat("\n=== Static DiD (Pill-Weighted — Preferred) ===\n")
m1 <- feols(high_dose_share ~ treated | county_id + ym_fac,
            data = dt, cluster = ~BUYER_STATE, weights = ~weight)
cat("Pill-weighted:\n")
print(summary(m1))

# (2) Average mg — pill-weighted
m2 <- feols(avg_mg ~ treated | county_id + ym_fac,
            data = dt, cluster = ~BUYER_STATE, weights = ~weight)
cat("\nAvg mg DiD (weighted):\n")
print(summary(m2))

# (3) Oxy/hydro ratio — pill-weighted
m3 <- feols(oxy_hydro_ratio ~ treated | county_id + ym_fac,
            data = dt, cluster = ~BUYER_STATE, weights = ~weight)
cat("\nOxy/hydro ratio DiD (weighted):\n")
print(summary(m3))

# ---------------------------------------------------------------------------
# 2. Event study (quarterly bins) — pill-weighted
# ---------------------------------------------------------------------------
cat("\n=== Event Study (Pill-Weighted) ===\n")

# Create quarterly event time (relative to Q3 2011)
dt[, event_quarter := floor(event_time / 3)]

# Bin endpoints (cap at -8 and +5 quarters)
dt[event_quarter < -8, event_quarter := -8]
dt[event_quarter > 5, event_quarter := 5]

# Pill-weighted event study
m_es <- feols(high_dose_share ~ i(event_quarter, fl, ref = -1) | county_id + ym_fac,
              data = dt, cluster = ~BUYER_STATE, weights = ~weight)
cat("Event study coefficients (pill-weighted):\n")
print(coeftable(m_es))

# Also unweighted event study for comparison
m_es_uw <- feols(high_dose_share ~ i(event_quarter, fl, ref = -1) | county_id + ym_fac,
                 data = dt, cluster = ~BUYER_STATE)

# ---------------------------------------------------------------------------
# 3. Permutation inference (pill-weighted)
# ---------------------------------------------------------------------------
cat("\n=== Permutation Inference (Pill-Weighted) ===\n")

states_list <- c("FL", "GA", "AL")
perm_coefs <- numeric(3)

for (s in seq_along(states_list)) {
  dt_perm <- copy(dt)
  dt_perm[, fl_perm := as.integer(BUYER_STATE == states_list[s])]
  dt_perm[, treated_perm := fl_perm * post]
  m_perm <- feols(high_dose_share ~ treated_perm | county_id + ym_fac,
                  data = dt_perm, weights = ~weight)
  perm_coefs[s] <- coef(m_perm)["treated_perm"]
}

cat("Permutation coefficients (weighted):\n")
for (s in seq_along(states_list)) {
  cat(sprintf("  %s as treated: %.4f\n", states_list[s], perm_coefs[s]))
}

fl_coef <- perm_coefs[1]
perm_pval <- mean(abs(perm_coefs) >= abs(fl_coef))
cat("Permutation p-value:", perm_pval, "\n")

# ---------------------------------------------------------------------------
# 4. Save results
# ---------------------------------------------------------------------------
results <- list(
  static_did_weighted = list(
    high_dose_share = list(
      coef = coef(m1)["treated"],
      se = se(m1)["treated"],
      pval = pvalue(m1)["treated"],
      nobs = m1$nobs
    ),
    avg_mg = list(
      coef = coef(m2)["treated"],
      se = se(m2)["treated"],
      pval = pvalue(m2)["treated"],
      nobs = m2$nobs
    ),
    oxy_hydro_ratio = list(
      coef = coef(m3)["treated"],
      se = se(m3)["treated"],
      pval = pvalue(m3)["treated"],
      nobs = m3$nobs
    )
  ),
  static_did_unweighted = list(
    high_dose_share = list(
      coef = coef(m1_uw)["treated"],
      se = se(m1_uw)["treated"]
    )
  ),
  perm_pval = perm_pval,
  perm_coefs = as.list(setNames(perm_coefs, states_list)),
  n_treated_counties = uniqueN(dt[fl == 1]$county_id),
  n_control_counties = uniqueN(dt[fl == 0]$county_id),
  n_pre = length(unique(dt[post == 0]$ym_int)),
  n_post = length(unique(dt[post == 1]$ym_int))
)

write_json(results, "../data/main_results.json", auto_unbox = TRUE, digits = 8)

# Save event study coefficients
es_coefs <- as.data.table(coeftable(m_es), keep.rownames = TRUE)
fwrite(es_coefs, "../data/event_study_coefs.csv")

# Diagnostics for validator
diag <- list(
  n_treated = uniqueN(dt[fl == 1]$county_id),
  n_pre = length(unique(dt[post == 0]$ym_int)),
  n_obs = nrow(dt)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

# Save model objects for table generation
save(m1, m1_uw, m2, m3, m_es, m_es_uw, file = "../data/models.RData")

cat("\nMain analysis complete. Results saved.\n")
