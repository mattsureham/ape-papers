## 04_robustness.R — Robustness checks
## apep_1156: Mexico AVGM and Domestic Violence Reporting

source("00_packages.R")

# -------------------------------------------------------------------
# 1. Load data
# -------------------------------------------------------------------
dv <- fread("../data/dv_panel.csv")

# State-month panel
state_panel <- dv[, .(y_raw = sum(y_raw), n_munis = uniqueN(mun_id)),
                  by = .(state_code, state_name, t, g, ym)]
state_panel[, y := asinh(y_raw)]
state_panel[, treated_post := as.integer(g > 0 & t >= g)]

# -------------------------------------------------------------------
# 2. TWFE with state and time FEs (comparison baseline)
# -------------------------------------------------------------------
cat("=== TWFE: Domestic violence ===\n")
twfe <- feols(y ~ treated_post | state_code + t,
              data = state_panel,
              cluster = ~state_code)
cat("TWFE coefficient:\n")
print(coeftable(twfe))

# -------------------------------------------------------------------
# 3. Leave-one-state-out
# -------------------------------------------------------------------
cat("\n=== Leave-one-state-out ===\n")
loo_results <- data.table()
treated_codes <- unique(state_panel$state_code[state_panel$g > 0])

for (sc in treated_codes) {
  d_loo <- state_panel[state_code != sc]
  fit_loo <- feols(y ~ treated_post | state_code + t,
                   data = d_loo, cluster = ~state_code)
  loo_results <- rbind(loo_results, data.table(
    dropped = sc,
    coef = coef(fit_loo)["treated_post"],
    se = se(fit_loo)["treated_post"]
  ))
}

cat(sprintf("LOO range: [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("Full sample TWFE: %.4f\n", coef(twfe)["treated_post"]))
saveRDS(loo_results, "../data/loo_results.rds")

# -------------------------------------------------------------------
# 4. Urban vs Rural heterogeneity (TWFE at mun level)
# -------------------------------------------------------------------
cat("\n=== Urban vs Rural heterogeneity ===\n")
# Classify municipalities by baseline DV count (proxy for urban)
mun_baseline <- dv[t <= 6, .(baseline_dv = mean(y_raw)), by = mun_id]
mun_baseline[, urban := as.integer(baseline_dv > median(baseline_dv))]

dv_het <- merge(dv, mun_baseline[, .(mun_id, urban)], by = "mun_id")

# State-month panel by urban/rural
het_panel <- dv_het[, .(y_raw = sum(y_raw)),
                    by = .(state_code, t, g, urban)]
het_panel[, y := asinh(y_raw)]
het_panel[, treated_post := as.integer(g > 0 & t >= g)]

twfe_urban <- feols(y ~ treated_post | state_code + t,
                    data = het_panel[urban == 1],
                    cluster = ~state_code)
twfe_rural <- feols(y ~ treated_post | state_code + t,
                    data = het_panel[urban == 0],
                    cluster = ~state_code)

cat("Urban municipalities:\n")
print(coeftable(twfe_urban))
cat("\nRural municipalities:\n")
print(coeftable(twfe_rural))

saveRDS(list(urban = twfe_urban, rural = twfe_rural),
        "../data/het_urban_rural.rds")

# -------------------------------------------------------------------
# 5. Pre-trend test (event study via TWFE for quick check)
# -------------------------------------------------------------------
cat("\n=== Event study (TWFE) ===\n")
# Create event time relative to treatment
state_panel[g > 0, event_time := t - g]
state_panel[g == 0, event_time := NA]

# Bin endpoints
state_panel[!is.na(event_time) & event_time < -24, event_time_bin := -24L]
state_panel[!is.na(event_time) & event_time > 48, event_time_bin := 48L]
state_panel[!is.na(event_time) & is.na(event_time_bin),
            event_time_bin := event_time]

# Include never-treated
state_panel[is.na(event_time), event_time_bin := -999L]

# Event study regression (omit t=-1)
es_data <- state_panel[event_time_bin != -999 | g == 0]
es_data[, event_fac := factor(event_time_bin)]
es_data[, event_fac := relevel(event_fac, ref = "-1")]

es_fit <- feols(y ~ i(event_time_bin, ref = -1) | state_code + t,
                data = es_data[event_time_bin >= -24 & event_time_bin <= 48 |
                                 g == 0],
                cluster = ~state_code)

# Extract pre-treatment coefficients
es_coefs <- as.data.table(coeftable(es_fit), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "t_stat", "p_val"))
es_coefs[, event_time := as.integer(gsub("event_time_bin::", "", term))]

pre_coefs <- es_coefs[event_time < -1 & event_time >= -12]
cat(sprintf("Pre-treatment coefficients (t=-12 to t=-2):\n"))
cat(sprintf("  Max absolute value: %.4f\n", max(abs(pre_coefs$estimate))))
cat(sprintf("  Any significant at 5%%: %s\n",
            ifelse(any(pre_coefs$p_val < 0.05), "YES — concern", "NO — clean")))

saveRDS(es_fit, "../data/es_twfe.rds")
saveRDS(es_coefs, "../data/es_coefs.rds")

# -------------------------------------------------------------------
# 6. Raw count outcome (Poisson-like via log(y+1))
# -------------------------------------------------------------------
cat("\n=== Alternative outcome: log(y+1) ===\n")
state_panel[, y_log1p := log(y_raw + 1)]
twfe_log <- feols(y_log1p ~ treated_post | state_code + t,
                  data = state_panel,
                  cluster = ~state_code)
cat("log(y+1) coefficient:\n")
print(coeftable(twfe_log))

# -------------------------------------------------------------------
# 7. Summary of robustness
# -------------------------------------------------------------------
cat("\n\n========== ROBUSTNESS SUMMARY ==========\n")
cat(sprintf("Main TWFE (asinh):       %.4f (SE %.4f)\n",
            coef(twfe)["treated_post"], se(twfe)["treated_post"]))
cat(sprintf("Alt outcome log(y+1):    %.4f (SE %.4f)\n",
            coef(twfe_log)["treated_post"], se(twfe_log)["treated_post"]))
cat(sprintf("LOO range:               [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("Urban TWFE:              %.4f (SE %.4f)\n",
            coef(twfe_urban)["treated_post"], se(twfe_urban)["treated_post"]))
cat(sprintf("Rural TWFE:              %.4f (SE %.4f)\n",
            coef(twfe_rural)["treated_post"], se(twfe_rural)["treated_post"]))
