## 04_robustness.R — apep_0931: IAP and Economic Development
## Robustness checks and pre-trend diagnostics

source("code/00_packages.R")

df <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")

cat("=== Robustness Checks ===\n")

# ── 1. District-specific linear trends ──────────────────────────────
# Allow each district its own linear time trend
cat("\n--- 1. District-specific linear trends ---\n")
df[, year_c := year - 2010]  # center at treatment year
# District-specific linear trends using fixest syntax
m_trend <- feols(ln_light ~ treat_post | pc11_district_id[year_c] + year,
                 data = df, cluster = ~pc11_district_id)
cat(sprintf("DiD with district trends: beta = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m_trend)["treat_post"], se(m_trend)["treat_post"],
            pvalue(m_trend)["treat_post"]))

# ── 2. Within-state event study ─────────────────────────────────────
cat("\n--- 2. Within IAP-states event study ---\n")
es_within <- feols(ln_light ~ i(event_time, iap, ref = -1) | pc11_district_id + year,
                   data = df[in_iap_state == 1], cluster = ~pc11_district_id)
cat("Event study (within IAP states):\n")
es_coefs_w <- data.table(
  event_time = as.integer(gsub(".*::", "", gsub(":iap", "", names(coef(es_within))))),
  coef = coef(es_within),
  se = se(es_within)
)
print(es_coefs_w[order(event_time)])

# ── 3. State × year FE event study ─────────────────────────────────
cat("\n--- 3. State x Year FE event study ---\n")
es_sxy <- feols(ln_light ~ i(event_time, iap, ref = -1) | pc11_district_id + pc11_state_id^year,
                data = df, cluster = ~pc11_district_id)
es_coefs_sxy <- data.table(
  event_time = as.integer(gsub(".*::", "", gsub(":iap", "", names(coef(es_sxy))))),
  coef = coef(es_sxy),
  se = se(es_sxy)
)
cat("Event study with state x year FE:\n")
print(es_coefs_sxy[order(event_time)])

# ── 4. Leave-one-state-out ──────────────────────────────────────────
cat("\n--- 4. Leave-one-state-out ---\n")
iap_states <- unique(df[iap == 1]$pc11_state_id)
loo_results <- data.table()
for (s in iap_states) {
  m <- feols(ln_light ~ treat_post | pc11_district_id + year,
             data = df[pc11_state_id != s], cluster = ~pc11_district_id)
  loo_results <- rbind(loo_results, data.table(
    dropped_state = s,
    coef = coef(m)["treat_post"],
    se = se(m)["treat_post"],
    pval = pvalue(m)["treat_post"]
  ))
}
cat("Leave-one-state-out:\n")
print(loo_results)

# ── 5. Placebo test: pre-treatment only (fake treatment at 2005) ──
cat("\n--- 5. Placebo test (fake treatment 2005) ---\n")
pre_only <- df[year <= 2010]
pre_only[, placebo_post := as.integer(year >= 2005)]
pre_only[, placebo_treat := iap * placebo_post]

m_placebo <- feols(ln_light ~ placebo_treat | pc11_district_id + year,
                   data = pre_only, cluster = ~pc11_district_id)
cat(sprintf("Placebo DiD (fake treatment 2005): beta = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m_placebo)["placebo_treat"], se(m_placebo)["placebo_treat"],
            pvalue(m_placebo)["placebo_treat"]))

# ── 6. HonestDiD / Rambachan-Roth sensitivity ──────────────────────
cat("\n--- 6. HonestDiD bounds ---\n")

# Use the state x year FE event study as the base
# HonestDiD requires the full event study object from fixest
tryCatch({
  # Extract pre-treatment and post-treatment coefficients
  beta_hat <- coef(es_sxy)
  sigma_hat <- vcov(es_sxy)

  # Event times present
  et_names <- names(beta_hat)
  event_times <- as.integer(gsub(".*::", "", gsub(":iap", "", et_names)))

  pre_idx <- which(event_times < -1)
  post_idx <- which(event_times >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Use HonestDiD
    l_vec <- rep(0, length(beta_hat))
    l_vec[post_idx[1]] <- 1  # Effect at time 0

    honest <- HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01),
      l_vec = l_vec[c(pre_idx, post_idx)]
    )
    cat("HonestDiD sensitivity results:\n")
    print(honest)
  }
}, error = function(e) {
  cat(sprintf("HonestDiD failed: %s\n", e$message))
  cat("Proceeding without HonestDiD bounds.\n")
})

# ── 7. Wild cluster bootstrap (few clusters concern) ────────────────
cat("\n--- 7. Inference checks ---\n")
# Number of clusters
n_clusters <- uniqueN(df$pc11_district_id)
n_iap_states <- length(iap_states)
cat(sprintf("Clusters (districts): %d\n", n_clusters))
cat(sprintf("IAP states: %d\n", n_iap_states))

# State-level clustering as alternative
m_state_cluster <- feols(ln_light ~ treat_post | pc11_district_id + year,
                         data = df, cluster = ~pc11_state_id)
cat(sprintf("State-clustered SE: beta = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m_state_cluster)["treat_post"],
            se(m_state_cluster)["treat_post"],
            pvalue(m_state_cluster)["treat_post"]))

# ── 8. VIIRS extension (2012-2023) ─────────────────────────────────
cat("\n--- 8. VIIRS nightlights (2012-2023) ---\n")
viirs <- fread("data/viirs_district_panel.csv")

# VIIRS: compare growth rates post-2012 between IAP and non-IAP
viirs[, year_c := year - 2012]
m_viirs <- feols(ln_light ~ iap:year_c | pc11_district_id + year,
                 data = viirs, cluster = ~pc11_district_id)
cat("VIIRS trend difference (iap x year):\n")
cat(sprintf("  beta = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m_viirs)["iap:year_c"], se(m_viirs)["iap:year_c"],
            pvalue(m_viirs)["iap:year_c"]))

# ── Save robustness results ────────────────────────────────────────
saveRDS(list(
  m_trend = m_trend,
  es_within = es_within,
  es_sxy = es_sxy,
  loo = loo_results,
  m_placebo = m_placebo,
  m_state_cluster = m_state_cluster,
  es_coefs_sxy = es_coefs_sxy
), "data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
