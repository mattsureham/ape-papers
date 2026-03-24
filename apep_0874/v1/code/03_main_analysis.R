# ============================================================
# 03_main_analysis.R — Main continuous DiD analysis
# apep_0874: Feeding the Supply Side
# ============================================================

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel.rds"))

cat("=== Main Analysis ===\n")
cat("  Panel:", nrow(panel), "obs,", uniqueN(panel$fips), "counties,",
    uniqueN(panel$yq), "quarters\n")

# ----------------------------------------------------------
# 1. Main specification: Continuous DiD
# ----------------------------------------------------------
cat("\n=== Model 1: Baseline (county + quarter FE) ===\n")

# Outcome: new authorizations count
m1_count <- feols(new_auths ~ did_continuous | fips + time_id,
                   data = panel, cluster = ~fips)
cat("  Count model:\n")
print(summary(m1_count))

# Outcome: authorization rate per 1,000 stores
m1_rate <- feols(auth_rate ~ did_continuous | fips + time_id,
                  data = panel[!is.na(auth_rate)], cluster = ~fips)
cat("  Rate model:\n")
print(summary(m1_rate))

# ----------------------------------------------------------
# 2. With EA control
# ----------------------------------------------------------
cat("\n=== Model 2: With EA Control ===\n")

m2_count <- feols(new_auths ~ did_continuous + ea_active | fips + time_id,
                   data = panel, cluster = ~fips)
cat("  Count (with EA):\n")
print(summary(m2_count))

m2_rate <- feols(auth_rate ~ did_continuous + ea_active | fips + time_id,
                  data = panel[!is.na(auth_rate)], cluster = ~fips)
cat("  Rate (with EA):\n")
print(summary(m2_rate))

# ----------------------------------------------------------
# 3. State × quarter FE (absorbs all state-level shocks)
# ----------------------------------------------------------
cat("\n=== Model 3: State × Quarter FE ===\n")

panel[, state_time := paste0(state_fips, "_", time_id)]

m3_count <- feols(new_auths ~ did_continuous | fips + state_time,
                   data = panel, cluster = ~fips)
cat("  Count (state×quarter FE):\n")
print(summary(m3_count))

m3_rate <- feols(auth_rate ~ did_continuous | fips + state_time,
                  data = panel[!is.na(auth_rate)], cluster = ~fips)
cat("  Rate (state×quarter FE):\n")
print(summary(m3_rate))

# ----------------------------------------------------------
# 4. With county-level covariates (interacted with time)
# ----------------------------------------------------------
cat("\n=== Model 4: With Controls ===\n")

# Interact baseline covariates with post (differential trends by observables)
panel[, poverty_post := poverty_rate * post_tfp]
panel[, pct_black_post := pct_black * post_tfp]
panel[, log_pop := log(population + 1)]
panel[, log_pop_post := log_pop * post_tfp]

m4_count <- feols(new_auths ~ did_continuous + ea_active + poverty_post +
                    pct_black_post + log_pop_post | fips + time_id,
                   data = panel, cluster = ~fips)
cat("  Count (with controls):\n")
print(summary(m4_count))

m4_rate <- feols(auth_rate ~ did_continuous + ea_active + poverty_post +
                   pct_black_post + log_pop_post | fips + time_id,
                  data = panel[!is.na(auth_rate)], cluster = ~fips)
cat("  Rate (with controls):\n")
print(summary(m4_rate))

# ----------------------------------------------------------
# 5. By store type
# ----------------------------------------------------------
cat("\n=== Model 5: By Store Type ===\n")

m5_super <- feols(new_supermarket ~ did_continuous + ea_active | fips + time_id,
                   data = panel, cluster = ~fips)
cat("  Supermarkets:\n")
print(summary(m5_super))

m5_conv <- feols(new_convenience ~ did_continuous + ea_active | fips + time_id,
                  data = panel, cluster = ~fips)
cat("  Convenience stores:\n")
print(summary(m5_conv))

m5_large <- feols(new_large ~ did_continuous + ea_active | fips + time_id,
                   data = panel, cluster = ~fips)
cat("  Large grocery:\n")
print(summary(m5_large))

m5_other <- feols(new_other ~ did_continuous + ea_active | fips + time_id,
                   data = panel, cluster = ~fips)
cat("  Other:\n")
print(summary(m5_other))

# ----------------------------------------------------------
# 6. Pre-trends / Event Study
# ----------------------------------------------------------
cat("\n=== Event Study ===\n")

# Create relative time variable
# TFP effective 2021Q4 -> time_id for 2021Q4
tfp_time <- (2021 - 2016) * 4 + 4  # = 24
panel[, rel_time := time_id - tfp_time]

# Bin endpoints
panel[, rel_time_binned := fcase(
  rel_time < -8, -8L,
  rel_time > 8, 8L,
  default = as.integer(rel_time)
)]

# Event study with -1 as reference
es_count <- feols(new_auths ~ i(rel_time_binned, treatment_intensity, ref = -1) + ea_active |
                    fips + time_id,
                   data = panel, cluster = ~fips)
cat("  Event study (count):\n")
print(summary(es_count))

es_rate <- feols(auth_rate ~ i(rel_time_binned, treatment_intensity, ref = -1) + ea_active |
                   fips + time_id,
                  data = panel[!is.na(auth_rate)], cluster = ~fips)
cat("  Event study (rate):\n")
print(summary(es_rate))

# ----------------------------------------------------------
# 7. Heterogeneity: High vs Low SNAP counties
# ----------------------------------------------------------
cat("\n=== Heterogeneity ===\n")

panel[, high_snap := as.integer(snap_rate > median(snap_rate, na.rm = TRUE))]
panel[, urban := as.integer(population > 50000)]

# High SNAP counties
m_high <- feols(new_auths ~ did_continuous + ea_active | fips + time_id,
                 data = panel[high_snap == 1], cluster = ~fips)

# Low SNAP counties
m_low <- feols(new_auths ~ did_continuous + ea_active | fips + time_id,
                data = panel[high_snap == 0], cluster = ~fips)

cat("  High-SNAP counties (n=", uniqueN(panel[high_snap == 1]$fips), "):\n")
print(summary(m_high))
cat("  Low-SNAP counties (n=", uniqueN(panel[high_snap == 0]$fips), "):\n")
print(summary(m_low))

# Urban vs Rural
m_urban <- feols(new_auths ~ did_continuous + ea_active | fips + time_id,
                  data = panel[urban == 1], cluster = ~fips)
m_rural <- feols(new_auths ~ did_continuous + ea_active | fips + time_id,
                  data = panel[urban == 0], cluster = ~fips)

cat("  Urban counties (n=", uniqueN(panel[urban == 1]$fips), "):\n")
print(summary(m_urban))
cat("  Rural counties (n=", uniqueN(panel[urban == 0]$fips), "):\n")
print(summary(m_rural))

# ----------------------------------------------------------
# 8. Save all results
# ----------------------------------------------------------
cat("\n=== Saving Results ===\n")

results <- list(
  m1_count = m1_count, m1_rate = m1_rate,
  m2_count = m2_count, m2_rate = m2_rate,
  m3_count = m3_count, m3_rate = m3_rate,
  m4_count = m4_count, m4_rate = m4_rate,
  m5_super = m5_super, m5_conv = m5_conv,
  m5_large = m5_large, m5_other = m5_other,
  es_count = es_count, es_rate = es_rate,
  m_high = m_high, m_low = m_low,
  m_urban = m_urban, m_rural = m_rural
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ----------------------------------------------------------
# 9. Write diagnostics.json
# ----------------------------------------------------------
cat("\n=== Writing Diagnostics ===\n")

# For continuous DiD, "treated" = counties with above-median treatment intensity
n_treated <- uniqueN(panel[treatment_intensity > median(treatment_intensity, na.rm = TRUE)]$fips)
n_pre <- sum(panel$post_tfp == 0) / uniqueN(panel$fips)  # pre-periods per county
n_pre_quarters <- uniqueN(panel[post_tfp == 0]$yq)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre_quarters,
  n_obs = nrow(panel),
  n_counties = uniqueN(panel$fips),
  n_quarters = uniqueN(panel$yq),
  method = "Continuous DiD",
  main_coef_count = coef(m2_count)["did_continuous"],
  main_se_count = se(m2_count)["did_continuous"],
  main_coef_rate = coef(m2_rate)["did_continuous"],
  main_se_rate = se(m2_rate)["did_continuous"]
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                      auto_unbox = TRUE, pretty = TRUE)

cat("  n_treated:", n_treated, "\n")
cat("  n_pre:", n_pre_quarters, "\n")
cat("  n_obs:", nrow(panel), "\n")
cat("  Main coefficient (count):", diagnostics$main_coef_count, "\n")
cat("  Main SE (count):", diagnostics$main_se_count, "\n")
cat("  Main coefficient (rate):", diagnostics$main_coef_rate, "\n")
cat("  Main SE (rate):", diagnostics$main_se_rate, "\n")

cat("\n=== Main Analysis Complete ===\n")
