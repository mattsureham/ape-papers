# 04_robustness.R — Robustness checks
# Ban the Box and the Black Employment Gap (apep_1012)

source("00_packages.R")

df <- fread("../data/analysis_long.csv")
df_wide <- fread("../data/analysis_wide.csv")

# ============================================================
# 1. Leave-one-out (drop each treated state)
# ============================================================
message("=== Leave-One-Out Analysis ===")

btb_states <- c(25L, 15L, 27L, 44L, 17L, 11L, 34L, 41L, 50L, 9L, 6L, 32L, 53L, 8L, 36L, 24L)
state_names <- c("MA", "HI", "MN", "RI", "IL", "DC", "NJ", "OR", "VT", "CT", "CA", "NV", "WA", "CO", "NY", "MD")

loo_results <- data.table()
for (i in seq_along(btb_states)) {
  df_loo <- df[state_fips != btb_states[i]]
  m_loo <- feols(ln_emp ~ post_btb:black + post_btb + black | county_fips + time_id,
                 data = df_loo, cluster = ~state_fips)
  loo_results <- rbind(loo_results, data.table(
    dropped_state = state_names[i],
    coef = coef(m_loo)["post_btb:black"],
    se = se(m_loo)["post_btb:black"]
  ))
}

message("Leave-one-out range:")
message(sprintf("  Min: %.4f (%s), Max: %.4f (%s)",
                min(loo_results$coef), loo_results[which.min(coef)]$dropped_state,
                max(loo_results$coef), loo_results[which.max(coef)]$dropped_state))

fwrite(loo_results, "../data/loo_results.csv")

# ============================================================
# 2. Wild cluster bootstrap
# ============================================================
message("=== Wild Cluster Bootstrap ===")

m_base <- feols(ln_emp ~ post_btb:black + post_btb + black | county_fips + time_id,
                data = df, cluster = ~state_fips)

wcb <- tryCatch({
  boottest(m_base, param = "post_btb:black", B = 999,
           clustid = ~state_fips, type = "webb")
}, error = function(e) {
  message("WCB error: ", e$message)
  NULL
})

if (!is.null(wcb)) {
  message(sprintf("WCB p-value: %.4f", wcb$p_val))
  message(sprintf("WCB CI: [%.4f, %.4f]", wcb$conf_int[1], wcb$conf_int[2]))
}

# ============================================================
# 3. Bacon decomposition (TWFE diagnostics)
# ============================================================
message("=== Bacon Decomposition ===")

# Use the wide panel for Bacon (county-level, employment ratio)
df_bacon <- df_wide[!is.na(bw_emp_ratio) & is.finite(bw_emp_ratio)]
df_bacon[, treat_time := fifelse(treated_state, btb_time_id, 0L)]
df_bacon[, treated := fifelse(treated_state & time_id >= btb_time_id, 1L, 0L)]
df_bacon[, county_id := as.integer(as.factor(county_fips))]

bacon_result <- tryCatch({
  bacon(bw_emp_ratio ~ treated, data = as.data.frame(df_bacon),
        id_var = "county_id", time_var = "time_id")
}, error = function(e) {
  message("Bacon decomposition error: ", e$message)
  NULL
})

if (!is.null(bacon_result)) {
  bacon_summary <- as.data.table(bacon_result)
  bacon_agg <- bacon_summary[, .(
    avg_estimate = weighted.mean(estimate, weight),
    total_weight = sum(weight)
  ), by = type]
  message("Bacon decomposition by type:")
  print(bacon_agg)
  fwrite(bacon_agg, "../data/bacon_decomp.csv")
}

# ============================================================
# 4. Pre-trend test (event study coefficients)
# ============================================================
message("=== Pre-Trend Test ===")

# Event study using TWFE (for interpretability)
df_wide[, event_time_binned := fifelse(!is.na(event_time) & event_time < -12, -12L,
                                fifelse(!is.na(event_time) & event_time > 12, 12L, event_time))]

m_event <- feols(bw_emp_ratio ~ i(event_time_binned, ref = -1) | county_fips + time_id,
                 data = df_wide[treated_state == TRUE & !is.na(event_time)],
                 cluster = ~state_fips)

# Extract pre-treatment coefficients
es_coefs <- as.data.table(coeftable(m_event), keep.rownames = "term")
setnames(es_coefs, c("term", "estimate", "se", "t_stat", "p_value"))
es_coefs[, event_time := as.integer(gsub(".*::(-?[0-9]+).*", "\\1", term))]
pre_coefs <- es_coefs[event_time < -1]

if (nrow(pre_coefs) > 0) {
  f_stat_pre <- mean(pre_coefs$t_stat^2)
  message(sprintf("Pre-trend F-stat (avg t²): %.2f", f_stat_pre))
  message(sprintf("Pre-trend coefficients significant at 5%%: %d of %d",
                  sum(pre_coefs$p_value < 0.05), nrow(pre_coefs)))
}

fwrite(es_coefs, "../data/event_study_coefs.csv")

# ============================================================
# 5. Public-sector-only BTB states as placebo
# ============================================================
message("=== Public-Sector BTB Placebo ===")

# States with only public-employer BTB (not private): approximate list
# These states adopted BTB only for government jobs
public_only_btb <- c(26L, 42L, 39L, 31L, 18L, 29L, 37L, 40L, 47L, 51L)  # MI, PA, OH, NE, IN, MO, NC, OK, TN, VA (approx)

df_placebo <- copy(df)
df_placebo[, placebo_treated := fifelse(state_fips %in% public_only_btb, 1L, 0L)]
# Assign placebo treatment at the median private-BTB date (2016 Q1)
df_placebo[, placebo_post := fifelse(time_id >= (2016 - 2005) * 4 + 1, 1L, 0L)]

# Exclude actual private-BTB states
df_placebo <- df_placebo[treated_state == FALSE]

m_placebo <- feols(ln_emp ~ placebo_treated:placebo_post:black +
                     placebo_treated:placebo_post + placebo_post:black |
                     county_fips + time_id,
                   data = df_placebo, cluster = ~state_fips)

message(sprintf("Placebo triple-diff: β = %.4f (SE = %.4f, p = %.4f)",
                coef(m_placebo)["placebo_treated:placebo_post:black"],
                se(m_placebo)["placebo_treated:placebo_post:black"],
                pvalue(m_placebo)["placebo_treated:placebo_post:black"]))

# ============================================================
# Save all robustness results
# ============================================================
rob_results <- list(
  loo = loo_results,
  wcb_pval = if (!is.null(wcb)) wcb$p_val else NA,
  bacon = if (!is.null(bacon_result)) bacon_agg else NULL,
  pre_trend_f = if (exists("f_stat_pre")) f_stat_pre else NA,
  placebo_coef = coef(m_placebo)["placebo_treated:placebo_post:black"],
  placebo_se = se(m_placebo)["placebo_treated:placebo_post:black"],
  placebo_p = pvalue(m_placebo)["placebo_treated:placebo_post:black"]
)
saveRDS(rob_results, "../data/robustness_results.rds")
message("Robustness checks complete.")
