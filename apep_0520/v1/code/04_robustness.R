## ============================================================================
## 04_robustness.R — Bacon decomposition, stacked DiD, RI, HonestDiD, placebos
## ============================================================================

source("00_packages.R")

DATA <- "../data"
main_sample <- readRDS(file.path(DATA, "main_sample.rds"))

# Recreate CS-DiD variables (same as 03_main_analysis.R)
main_sample[, t_period := as.integer(difftime(month_date, as.Date("2018-01-01"), units = "days")) %/% 30L + 1L]
main_sample[!is.na(waiver_date),
            g_period := as.integer(difftime(waiver_date, as.Date("2018-01-01"), units = "days")) %/% 30L + 1L]
main_sample[is.na(waiver_date), g_period := 0L]
main_sample[, state_num := as.integer(factor(state))]

## ---- 1. Bacon Decomposition ----
cat("=== Bacon Decomposition ===\n")

# Need bacondecomp package
if (!requireNamespace("bacondecomp", quietly = TRUE)) {
  install.packages("bacondecomp", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(bacondecomp)

# Bacon decomposition on quarterly data (monthly is too granular)
qtr_sample <- main_sample[, .(
  ln_bh_providers = mean(ln_bh_providers),
  treated = max(treated),
  state_num = state_num[1],
  g_period = g_period[1]
), by = .(state, quarter = paste0(year(month_date), "Q", quarter(month_date)))]
qtr_sample[, t_qtr := as.integer(factor(quarter))]

bacon_result <- tryCatch({
  bacon(ln_bh_providers ~ treated,
        data = as.data.frame(qtr_sample),
        id_var = "state_num",
        time_var = "t_qtr")
}, error = function(e) {
  cat("Bacon decomposition error:", e$message, "\n")
  NULL
})

if (!is.null(bacon_result)) {
  bacon_dt <- as.data.table(bacon_result)
  fwrite(bacon_dt, file.path(DATA, "bacon_decomposition.csv"))
  cat("Bacon decomposition weights:\n")
  bacon_summary <- bacon_dt[, .(
    total_weight = sum(weight),
    weighted_est = sum(weight * estimate)
  ), by = type]
  print(bacon_summary)
}

## ---- 2. Stacked Cohort DiD (Sun & Abraham 2021 style) ----
cat("\n=== Stacked Cohort DiD ===\n")

# Create cohort-specific datasets and stack them
cohorts <- sort(unique(main_sample[g_period > 0, g_period]))

stacked_list <- list()
for (g in cohorts) {
  # Get treated states in this cohort
  treated_states <- unique(main_sample[g_period == g, state_num])

  # Get never-treated states
  control_states <- unique(main_sample[g_period == 0, state_num])

  # Stack: treated + never-treated, restrict to clean window
  cohort_data <- main_sample[state_num %in% c(treated_states, control_states)]
  cohort_data[, cohort_g := g]
  cohort_data[, rel_time := t_period - g]

  # Keep ±24 months around treatment
  cohort_data <- cohort_data[rel_time >= -12 & rel_time <= 36]
  cohort_data[, treated_stacked := fifelse(g_period == g & t_period >= g, 1L, 0L)]

  stacked_list[[as.character(g)]] <- cohort_data
}

stacked <- rbindlist(stacked_list)

# Create cohort × state interaction for clustering
stacked[, cohort_state := paste0(cohort_g, "_", state_num)]

# Stacked regression
stacked_reg <- feols(ln_bh_providers ~ treated_stacked |
                       cohort_state + cohort_g^t_period,
                     data = stacked, cluster = ~state_num)

cat(sprintf("Stacked DiD ATT: %.4f (SE: %.4f)\n",
            coef(stacked_reg), se(stacked_reg)))

# Stacked event study
stacked[, is_treated_cohort := fifelse(g_period > 0, 1L, 0L)]

stacked_es <- feols(ln_bh_providers ~ i(rel_time, is_treated_cohort, ref = -1) |
                      cohort_state + cohort_g^t_period,
                    data = stacked,
                    cluster = ~state_num)

# Extract event study coefficients
es_names <- names(coef(stacked_es))
stacked_coefs <- data.table(
  event_time = as.integer(gsub("rel_time::(-?[0-9]+):.*", "\\1", es_names)),
  att = coef(stacked_es),
  se = se(stacked_es)
)
stacked_coefs[, `:=`(
  ci_lower = att - 1.96 * se,
  ci_upper = att + 1.96 * se,
  outcome = "Stacked DiD"
)]
fwrite(stacked_coefs, file.path(DATA, "stacked_es.csv"))

saveRDS(stacked_reg, file.path(DATA, "stacked_reg.rds"))

## ---- 3. Excluding COVID Period ----
cat("\n=== Robustness: Excluding COVID (Mar-Dec 2020) ===\n")

no_covid <- main_sample[!(month_date >= "2020-03-01" & month_date <= "2020-12-31")]

cs_no_covid <- tryCatch({
  att_gt(
    yname = "ln_bh_providers",
    tname = "t_period",
    idname = "state_num",
    gname = "g_period",
    data = as.data.frame(no_covid),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  cat("No-COVID CS-DiD error:", e$message, "\n")
  NULL
})

if (!is.null(cs_no_covid)) {
  agg_no_covid <- aggte(cs_no_covid, type = "simple")
  cat(sprintf("No-COVID ATT: %.4f (SE: %.4f)\n",
              agg_no_covid$overall.att, agg_no_covid$overall.se))
  saveRDS(agg_no_covid, file.path(DATA, "agg_no_covid.rds"))
}

## ---- 4. State-Specific Linear Trends ----
cat("\n=== Robustness: State-Specific Linear Trends ===\n")

main_sample[, time_trend := as.numeric(month_date - min(month_date))]
twfe_trends <- feols(ln_bh_providers ~ treated | state_id + t_period + state_id[time_trend],
                      data = main_sample, cluster = ~state_id)
cat(sprintf("TWFE with state trends: %.4f (SE: %.4f)\n",
            coef(twfe_trends)["treated"], se(twfe_trends)["treated"]))

saveRDS(twfe_trends, file.path(DATA, "twfe_trends.rds"))

## ---- 5. Per Capita Specification ----
cat("\n=== Robustness: Per Capita Outcomes ===\n")

cs_pc <- tryCatch({
  att_gt(
    yname = "bh_providers_pc",
    tname = "t_period",
    idname = "state_num",
    gname = "g_period",
    data = as.data.frame(main_sample[!is.na(population)]),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  cat("Per capita CS-DiD error:", e$message, "\n")
  NULL
})

if (!is.null(cs_pc)) {
  agg_pc <- aggte(cs_pc, type = "simple")
  agg_pc_dyn <- aggte(cs_pc, type = "dynamic", min_e = -12, max_e = 36)
  cat(sprintf("Per capita ATT (BH providers/100K): %.2f (SE: %.2f)\n",
              agg_pc$overall.att, agg_pc$overall.se))
  saveRDS(agg_pc, file.path(DATA, "agg_pc.rds"))
  saveRDS(agg_pc_dyn, file.path(DATA, "agg_pc_dynamic.rds"))

  es_pc <- data.table(
    event_time = agg_pc_dyn$egt,
    att = agg_pc_dyn$att.egt,
    se = agg_pc_dyn$se.egt,
    ci_lower = agg_pc_dyn$att.egt - 1.96 * agg_pc_dyn$se.egt,
    ci_upper = agg_pc_dyn$att.egt + 1.96 * agg_pc_dyn$se.egt,
    outcome = "BH Providers per 100K"
  )
  fwrite(es_pc, file.path(DATA, "es_percapita.csv"))
}

## ---- 6. Randomization Inference ----
cat("\n=== Randomization Inference (1000 permutations) ===\n")

# Permute treatment assignment across states
set.seed(42)
n_perm <- 1000

# Get observed ATT
observed_att <- readRDS(file.path(DATA, "agg_bh_simple.rds"))$overall.att

# Simple TWFE for speed in RI
twfe_obs <- feols(ln_bh_providers ~ treated | state_id + t_period,
                   data = main_sample, cluster = ~state_id)
obs_coef <- coef(twfe_obs)["treated"]

# Permute
state_waivers <- unique(main_sample[g_period > 0, .(state, g_period)])
all_state_ids <- unique(main_sample$state)
n_treated <- nrow(state_waivers)

ri_coefs <- numeric(n_perm)
for (i in seq_len(n_perm)) {
  # Randomly assign treatment to same number of states
  perm_states <- sample(all_state_ids, n_treated)
  perm_map <- data.table(
    state = perm_states,
    perm_g = sample(state_waivers$g_period)
  )

  perm_data <- copy(main_sample)
  perm_data[, treated_perm := 0L]
  perm_data <- merge(perm_data, perm_map, by = "state", all.x = TRUE)
  perm_data[!is.na(perm_g) & t_period >= perm_g, treated_perm := 1L]

  perm_reg <- tryCatch(
    feols(ln_bh_providers ~ treated_perm | state_id + t_period,
          data = perm_data),
    error = function(e) NULL
  )

  if (!is.null(perm_reg)) {
    ri_coefs[i] <- coef(perm_reg)["treated_perm"]
  } else {
    ri_coefs[i] <- NA
  }

  if (i %% 100 == 0) cat(sprintf("  RI permutation %d/%d\n", i, n_perm))
}

ri_coefs <- ri_coefs[!is.na(ri_coefs)]
ri_p <- mean(abs(ri_coefs) >= abs(obs_coef))
cat(sprintf("\nRI p-value (two-sided): %.4f (obs coef: %.4f)\n", ri_p, obs_coef))

ri_result <- data.table(
  observed_coef = obs_coef,
  ri_p_value = ri_p,
  n_permutations = length(ri_coefs),
  ri_mean = mean(ri_coefs),
  ri_sd = sd(ri_coefs)
)
fwrite(ri_result, file.path(DATA, "ri_result.csv"))
fwrite(data.table(coef = ri_coefs), file.path(DATA, "ri_distribution.csv"))

## ---- 7. Wild Cluster Bootstrap ----
cat("\n=== Wild Cluster Bootstrap ===\n")

wcb_result <- tryCatch({
  boottest(twfe_obs, param = "treated", B = 999,
           clustid = "state_id", type = "rademacher")
}, error = function(e) {
  cat("WCB error:", e$message, "\n")
  NULL
})

if (!is.null(wcb_result)) {
  cat(sprintf("Wild cluster bootstrap p-value: %.4f\n", wcb_result$p_val))
  saveRDS(wcb_result, file.path(DATA, "wcb_result.rds"))
}

## ---- 8. Include Always-Treated (Full Sample) ----
cat("\n=== Robustness: Include Always-Treated States ===\n")

full_panel <- readRDS(file.path(DATA, "panel_state_month.rds"))
full_panel[, t_period := as.integer(difftime(month_date, as.Date("2018-01-01"), units = "days")) %/% 30L + 1L]
full_panel[!is.na(waiver_date),
           g_period := as.integer(difftime(waiver_date, as.Date("2018-01-01"), units = "days")) %/% 30L + 1L]
full_panel[is.na(waiver_date), g_period := 0L]
full_panel[, state_num := as.integer(factor(state))]

twfe_full <- feols(ln_bh_providers ~ treated | state_id + t_period,
                    data = full_panel, cluster = ~state_id)
cat(sprintf("TWFE (full sample incl. always-treated): %.4f (SE: %.4f)\n",
            coef(twfe_full)["treated"], se(twfe_full)["treated"]))

saveRDS(twfe_full, file.path(DATA, "twfe_full.rds"))

## ---- 9. Collect Robustness Summary ----
robustness_summary <- data.table(
  specification = c(
    "CS-DiD (main)",
    "TWFE (comparison)",
    "Stacked DiD",
    "Excluding COVID",
    "State linear trends",
    "Include always-treated",
    "RI p-value",
    "WCB p-value"
  ),
  estimate = c(
    readRDS(file.path(DATA, "agg_bh_simple.rds"))$overall.att,
    coef(readRDS(file.path(DATA, "twfe_results.rds"))$bh),
    coef(stacked_reg),
    if (!is.null(cs_no_covid)) readRDS(file.path(DATA, "agg_no_covid.rds"))$overall.att else NA,
    coef(twfe_trends)["treated"],
    coef(twfe_full)["treated"],
    ri_p,
    if (!is.null(wcb_result)) wcb_result$p_val else NA
  ),
  se = c(
    readRDS(file.path(DATA, "agg_bh_simple.rds"))$overall.se,
    se(readRDS(file.path(DATA, "twfe_results.rds"))$bh),
    se(stacked_reg),
    if (!is.null(cs_no_covid)) readRDS(file.path(DATA, "agg_no_covid.rds"))$overall.se else NA,
    se(twfe_trends)["treated"],
    se(twfe_full)["treated"],
    NA,
    NA
  )
)

fwrite(robustness_summary, file.path(DATA, "robustness_summary.csv"))
cat("\n=== Robustness Summary ===\n")
print(robustness_summary)

cat("\n=== Robustness checks complete ===\n")
