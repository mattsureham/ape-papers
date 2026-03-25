## 03_main_analysis.R — Callaway-Sant'Anna DiD + event study
## apep_0944: AVR and Federal Jury Acquittal Rates

library(data.table)
library(fixest)
library(did)
library(jsonlite)

# setwd handled by caller

panel <- fread("data/analysis_panel.csv")
cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$dist_id), "districts\n")

# Create numeric district ID for did package
panel[, dist_num := as.integer(as.factor(dist_id))]

# ── 1. Descriptive: Treatment rollout ───────────────────────────────────
cat("\n=== Treatment Rollout ===\n")
cohort_tab <- panel[first_treat > 0, .(
  n_districts = uniqueN(dist_id),
  states = paste(unique(state_abbr), collapse = ", ")
), by = first_treat][order(first_treat)]
print(cohort_tab)

# ── 2. Pre-treatment means by group ─────────────────────────────────────
pre_means <- panel[fiscalyr < 2016, .(
  mean_acq_rate = mean(acquittal_rate),
  sd_acq_rate = sd(acquittal_rate),
  mean_verdicts = mean(n_verdicts)
), by = .(group = ifelse(first_treat > 0, "AVR", "Non-AVR"))]
cat("\nPre-treatment (pre-2016) means:\n")
print(pre_means)

# ── 3. TWFE baseline (for comparison, known biased with staggered) ──────
cat("\n=== TWFE Baseline ===\n")
twfe <- feols(acquittal_rate ~ treated | dist_id + fiscalyr,
              data = panel, cluster = ~state_abbr)
cat("TWFE coefficient:", round(coef(twfe)["treated"], 4),
    " SE:", round(se(twfe)["treated"], 4),
    " p:", round(pvalue(twfe)["treated"], 4), "\n")

# Weighted by number of verdicts
twfe_w <- feols(acquittal_rate ~ treated | dist_id + fiscalyr,
                data = panel, cluster = ~state_abbr,
                weights = ~n_verdicts)
cat("TWFE (weighted):", round(coef(twfe_w)["treated"], 4),
    " SE:", round(se(twfe_w)["treated"], 4),
    " p:", round(pvalue(twfe_w)["treated"], 4), "\n")

# ── 4. Sun-Abraham (fixest implementation) ───────────────────────────────
cat("\n=== Sun-Abraham ===\n")
# Need cohort variable for sunab
panel[, cohort := ifelse(first_treat == 0, 10000, first_treat)]

sa <- feols(acquittal_rate ~ sunab(cohort, fiscalyr) | dist_id + fiscalyr,
            data = panel, cluster = ~state_abbr)
cat("Sun-Abraham ATT:\n")
summary(sa)

# Extract event-study coefficients
sa_es <- data.table(
  event_time = as.integer(gsub(".*::", "", names(coef(sa)))),
  estimate = coef(sa),
  se = se(sa)
)
sa_es[, ci_lower := estimate - 1.96 * se]
sa_es[, ci_upper := estimate + 1.96 * se]
sa_es <- sa_es[order(event_time)]
fwrite(sa_es, "data/sa_event_study.csv")

cat("\nSun-Abraham event study coefficients:\n")
print(sa_es[event_time >= -8 & event_time <= 6])

# ── 5. Callaway-Sant'Anna ───────────────────────────────────────────────
cat("\n=== Callaway-Sant'Anna ===\n")

# Run CS with never-treated as control
cs_out <- tryCatch({
  att_gt(
    yname = "acquittal_rate",
    tname = "fiscalyr",
    idname = "dist_num",
    gname = "first_treat",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) {
  cat("CS with never-treated failed:", e$message, "\n")
  cat("Trying not-yet-treated...\n")
  att_gt(
    yname = "acquittal_rate",
    tname = "fiscalyr",
    idname = "dist_num",
    gname = "first_treat",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "varying"
  )
})

# Aggregate: overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nCS Overall ATT:", round(cs_agg$overall.att, 4),
    " SE:", round(cs_agg$overall.se, 4), "\n")

# Event study aggregation
cs_es <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 6)
cat("\nCS Event Study:\n")
print(data.table(
  event_time = cs_es$egt,
  estimate = round(cs_es$att.egt, 4),
  se = round(cs_es$se.egt, 4)
))

# Save CS results
cs_es_dt <- data.table(
  event_time = cs_es$egt,
  estimate = cs_es$att.egt,
  se = cs_es$se.egt,
  ci_lower = cs_es$att.egt - 1.96 * cs_es$se.egt,
  ci_upper = cs_es$att.egt + 1.96 * cs_es$se.egt
)
fwrite(cs_es_dt, "data/cs_event_study.csv")

# Group-time ATTs
cs_gt_dt <- data.table(
  group = cs_out$group,
  time = cs_out$t,
  att = cs_out$att,
  se = cs_out$se
)
fwrite(cs_gt_dt, "data/cs_group_time.csv")

# ── 6. Aggregate ATT by cohort ──────────────────────────────────────────
cs_group <- aggte(cs_out, type = "group")
cat("\nCS ATT by adoption cohort:\n")
print(data.table(
  cohort = cs_group$egt,
  att = round(cs_group$att.egt, 4),
  se = round(cs_group$se.egt, 4)
))

# ── 7. Pre-trend test ───────────────────────────────────────────────────
cat("\n=== Pre-trend Test ===\n")
pre_coefs <- cs_es_dt[event_time < 0]
cat("Pre-treatment coefficients:\n")
print(pre_coefs)

# Joint test of pre-trend = 0 (using F-test on SA estimates)
pre_sa <- sa_es[event_time < 0 & event_time >= -5]
if (nrow(pre_sa) > 0) {
  f_stat <- sum(pre_sa$estimate^2 / pre_sa$se^2) / nrow(pre_sa)
  f_pval <- 1 - pf(f_stat, nrow(pre_sa), Inf)
  cat("Joint F-test of pre-trends = 0: F =", round(f_stat, 2),
      " p =", round(f_pval, 3), "\n")
}

# ── 8. Save results for tables ──────────────────────────────────────────
results <- list(
  twfe_coef = coef(twfe)["treated"],
  twfe_se = se(twfe)["treated"],
  twfe_pval = pvalue(twfe)["treated"],
  twfe_w_coef = coef(twfe_w)["treated"],
  twfe_w_se = se(twfe_w)["treated"],
  twfe_w_pval = pvalue(twfe_w)["treated"],
  cs_att = cs_agg$overall.att,
  cs_se = cs_agg$overall.se,
  cs_ci_lower = cs_agg$overall.att - 1.96 * cs_agg$overall.se,
  cs_ci_upper = cs_agg$overall.att + 1.96 * cs_agg$overall.se,
  n_obs = nrow(panel),
  n_districts = uniqueN(panel$dist_id),
  n_treated = uniqueN(panel[first_treat > 0, dist_id]),
  n_clusters = uniqueN(panel$state_abbr),
  pre_trend_f = if (exists("f_stat")) f_stat else NA,
  pre_trend_p = if (exists("f_pval")) f_pval else NA
)
write_json(results, "data/main_results.json", auto_unbox = TRUE, pretty = TRUE)

# ── 9. Diagnostics for validate_v1.py ───────────────────────────────────
diagnostics <- list(
  n_treated = uniqueN(panel[first_treat > 0, dist_id]),
  n_pre = length(unique(panel[fiscalyr < 2016, fiscalyr])),
  n_obs = nrow(panel)
)
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", toJSON(diagnostics, auto_unbox = TRUE), "\n")

cat("\n=== 03_main_analysis.R complete ===\n")
