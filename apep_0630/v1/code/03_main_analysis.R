## 03_main_analysis.R — Main DiD estimation
## apep_0630: Surprise Billing Laws and ED Quality

library(data.table)
library(fixest)
library(did)
library(jsonlite)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "."
setwd(file.path(script_dir, ".."))

panel <- fread("data/analysis_panel.csv")

# ---- Verify sample integrity ----
stopifnot("Panel is empty" = nrow(panel) > 0)
stopifnot("No treated units" = sum(panel$G > 0) > 0)
stopifnot("No pre-treatment periods" = any(panel$meas_year < min(panel[G > 0]$G)))

n_treated_states <- uniqueN(panel[G > 0]$state)
# For staggered DiD, count pre-periods for the latest cohort (most pre-treatment data)
max_cohort <- max(panel[G > 0]$G)
n_pre <- length(unique(panel$meas_year[panel$meas_year < max_cohort]))
cat(sprintf("Treated states: %d, Pre-treatment years: %d\n", n_treated_states, n_pre))

# Panel balance diagnostic
cat("\n=== Panel Balance ===\n")
yr_counts <- panel[, .N, by = .(meas_year)]
print(yr_counts[order(meas_year)])
hosp_yr <- panel[, .N, by = provider_id]
cat(sprintf("Hospitals by # years observed: %s\n",
            paste(sprintf("%d yr: %d", 1:6, sapply(1:6, function(k) sum(hosp_yr$N == k))),
                  collapse = ", ")))

# ===================================================================
# 1. TWFE baseline (for comparison — known to be biased under heterogeneity)
# ===================================================================
cat("\n=== TWFE Baseline ===\n")
twfe_time <- feols(ed_time ~ treated | provider_id + meas_year,
                   data = panel, cluster = ~state)
twfe_lwbs <- feols(lwbs_pct ~ treated | provider_id + meas_year,
                   data = panel, cluster = ~state)
cat("TWFE ED Time:\n"); print(summary(twfe_time))
cat("\nTWFE LWBS:\n"); print(summary(twfe_lwbs))

# ===================================================================
# 2. Sun-Abraham (PRIMARY estimator — handles unbalanced panels)
# ===================================================================
cat("\n=== Sun-Abraham (Primary) ===\n")
panel[, cohort := fifelse(G == 0, 10000L, G)]

sa_time <- feols(ed_time ~ sunab(cohort, meas_year) | provider_id + meas_year,
                 data = panel, cluster = ~state)
cat("Sun-Abraham ED Time:\n")
print(summary(sa_time))

# Extract aggregate ATT from SA
sa_time_agg <- summary(sa_time, agg = "ATT")
cat("\nSun-Abraham Aggregate ATT:\n")
print(sa_time_agg)

# SA Event study
sa_time_es <- summary(sa_time, agg = "period")
cat("\nSun-Abraham Event Study:\n")
print(sa_time_es)

# LWBS
panel_lwbs <- panel[!is.na(lwbs_pct)]
panel_lwbs[, cohort := fifelse(G == 0, 10000L, G)]

sa_lwbs <- tryCatch({
  feols(lwbs_pct ~ sunab(cohort, meas_year) | provider_id + meas_year,
        data = panel_lwbs, cluster = ~state)
}, error = function(e) {
  cat("SA LWBS error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(sa_lwbs)) {
  cat("\nSun-Abraham LWBS:\n")
  print(summary(sa_lwbs))
  sa_lwbs_agg <- summary(sa_lwbs, agg = "ATT")
  cat("\nSun-Abraham LWBS Aggregate ATT:\n")
  print(sa_lwbs_agg)
}

# ===================================================================
# 3. Callaway-Sant'Anna (robustness — balanced subset)
# ===================================================================
cat("\n=== Callaway-Sant'Anna (balanced subset) ===\n")

# Balance over a 4-year window (2014-2017) for adequate pre/post
cs_years <- 2014:2017
panel_cs <- panel[meas_year %in% cs_years]
hosp_cs_count <- panel_cs[, .N, by = provider_id]
balanced_cs <- hosp_cs_count[N == length(cs_years)]$provider_id
panel_cs <- panel_cs[provider_id %in% balanced_cs]
cat(sprintf("CS balanced subset: %d hospitals, %d years\n",
            length(balanced_cs), length(cs_years)))

cs_time <- tryCatch({
  att_gt(
    yname = "ed_time",
    tname = "meas_year",
    idname = "provider_id",
    gname = "G",
    data = as.data.frame(panel_cs),
    control_group = "nevertreated",
    est_method = "dr",
    clustervars = "state",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS error:", conditionMessage(e), "\n")
  # Try with reg instead of dr
  tryCatch({
    att_gt(
      yname = "ed_time",
      tname = "meas_year",
      idname = "provider_id",
      gname = "G",
      data = as.data.frame(panel_cs),
      control_group = "nevertreated",
      est_method = "reg",
      clustervars = "state",
      base_period = "universal"
    )
  }, error = function(e2) {
    cat("CS reg fallback error:", conditionMessage(e2), "\n")
    NULL
  })
})

cs_att_time <- NULL
cs_es_time <- NULL
if (!is.null(cs_time)) {
  cs_att_time <- aggte(cs_time, type = "simple")
  cat("\nCS Simple ATT (ED Time):\n")
  print(summary(cs_att_time))
  cs_es_time <- aggte(cs_time, type = "dynamic")
  cat("\nCS Event Study:\n")
  print(summary(cs_es_time))
}

# CS for LWBS
cs_lwbs <- NULL; cs_att_lwbs <- NULL; cs_es_lwbs <- NULL
panel_cs_lwbs <- panel_cs[!is.na(lwbs_pct)]
lwbs_cs_count <- panel_cs_lwbs[, .N, by = provider_id]
bal_lwbs <- lwbs_cs_count[N == length(cs_years)]$provider_id
panel_cs_lwbs <- panel_cs_lwbs[provider_id %in% bal_lwbs]

if (nrow(panel_cs_lwbs) > 200 && uniqueN(panel_cs_lwbs[G > 0]$provider_id) >= 20) {
  cs_lwbs <- tryCatch({
    att_gt(
      yname = "lwbs_pct",
      tname = "meas_year",
      idname = "provider_id",
      gname = "G",
      data = as.data.frame(panel_cs_lwbs),
      control_group = "nevertreated",
      est_method = "reg",
      clustervars = "state",
      base_period = "universal"
    )
  }, error = function(e) {
    cat("CS LWBS error:", conditionMessage(e), "\n")
    NULL
  })
  if (!is.null(cs_lwbs)) {
    cs_att_lwbs <- aggte(cs_lwbs, type = "simple")
    cat("\nCS LWBS ATT:\n")
    print(summary(cs_att_lwbs))
    cs_es_lwbs <- aggte(cs_lwbs, type = "dynamic")
  }
}

# ===================================================================
# 4. Save results
# ===================================================================

# Extract SA aggregate estimates
sa_att_est <- coeftable(sa_time_agg)[1, "Estimate"]
sa_att_se <- coeftable(sa_time_agg)[1, "Std. Error"]

sa_lwbs_est <- NA; sa_lwbs_se_val <- NA
if (!is.null(sa_lwbs)) {
  sa_lwbs_agg_tab <- coeftable(summary(sa_lwbs, agg = "ATT"))
  sa_lwbs_est <- sa_lwbs_agg_tab[1, "Estimate"]
  sa_lwbs_se_val <- sa_lwbs_agg_tab[1, "Std. Error"]
}

saveRDS(list(
  twfe_time = twfe_time,
  twfe_lwbs = twfe_lwbs,
  sa_time = sa_time,
  sa_lwbs = sa_lwbs,
  cs_time = cs_time,
  cs_att_time = cs_att_time,
  cs_es_time = cs_es_time,
  cs_lwbs = cs_lwbs,
  cs_att_lwbs = cs_att_lwbs,
  cs_es_lwbs = cs_es_lwbs,
  sa_att_est = sa_att_est,
  sa_att_se = sa_att_se,
  sa_lwbs_est = sa_lwbs_est,
  sa_lwbs_se = sa_lwbs_se_val
), "data/main_results.rds")

# Write diagnostics.json for validator
diag <- list(
  n_treated = uniqueN(panel[G > 0]$provider_id),
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_states = uniqueN(panel$state),
  n_treated_states = n_treated_states,
  n_never_treated = uniqueN(panel[G == 0]$provider_id),
  sa_att_ed_time = sa_att_est,
  sa_se_ed_time = sa_att_se,
  mean_ed_time = mean(panel$ed_time, na.rm = TRUE),
  sd_ed_time = sd(panel$ed_time, na.rm = TRUE)
)

# Add CS results if available
if (!is.null(cs_att_time)) {
  diag$cs_att_ed_time <- cs_att_time$overall.att
  diag$cs_se_ed_time <- cs_att_time$overall.se
}

if (!is.na(sa_lwbs_est)) {
  diag$sa_att_lwbs <- sa_lwbs_est
  diag$sa_se_lwbs <- sa_lwbs_se_val
  diag$mean_lwbs <- mean(panel$lwbs_pct, na.rm = TRUE)
  diag$sd_lwbs <- sd(panel$lwbs_pct, na.rm = TRUE)
}

write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== SUMMARY ===\n")
cat(sprintf("SA ATT (ED Time): %.2f (SE=%.2f)\n", sa_att_est, sa_att_se))
if (!is.null(cs_att_time)) {
  cat(sprintf("CS ATT (ED Time): %.2f (SE=%.2f)\n",
              cs_att_time$overall.att, cs_att_time$overall.se))
}
cat(sprintf("TWFE (ED Time): %.2f (SE=%.2f)\n",
            coef(twfe_time)["treated"], sqrt(vcov(twfe_time)["treated","treated"])))
if (!is.na(sa_lwbs_est)) {
  cat(sprintf("SA ATT (LWBS): %.3f (SE=%.3f)\n", sa_lwbs_est, sa_lwbs_se_val))
}
cat("Main analysis complete.\n")
