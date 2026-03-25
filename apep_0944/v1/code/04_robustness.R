## 04_robustness.R — Robustness checks and mechanism tests
## apep_0944: AVR and Federal Jury Acquittal Rates

library(data.table)
library(fixest)
library(did)
library(jsonlite)
# fwildclusterboot not available for this R version; use RI instead

# setwd handled by caller

panel <- fread("data/analysis_panel.csv")
panel[, dist_num := as.integer(as.factor(dist_id))]
panel[, cohort := ifelse(first_treat == 0, 10000, first_treat)]

cat("Panel loaded:", nrow(panel), "obs\n")

# ── 1. Leave-one-state-out ──────────────────────────────────────────────
cat("\n=== Leave-One-State-Out ===\n")
avr_states <- unique(panel[first_treat > 0, state_abbr])

loo_results <- lapply(avr_states, function(st) {
  panel_loo <- panel[state_abbr != st]
  panel_loo[, dist_num_loo := as.integer(as.factor(dist_id))]

  cs_loo <- tryCatch({
    cs <- att_gt(
      yname = "acquittal_rate", tname = "fiscalyr",
      idname = "dist_num_loo", gname = "first_treat",
      data = as.data.frame(panel_loo),
      control_group = "nevertreated", anticipation = 0,
      base_period = "varying"
    )
    agg <- aggte(cs, type = "simple")
    data.table(dropped_state = st, att = agg$overall.att, se = agg$overall.se)
  }, error = function(e) {
    data.table(dropped_state = st, att = NA, se = NA)
  })
  cs_loo
})
loo_dt <- rbindlist(loo_results)
cat("Leave-one-state-out results:\n")
print(loo_dt[order(att)])
cat("Range of ATT:", round(range(loo_dt$att, na.rm = TRUE), 4), "\n")

fwrite(loo_dt, "data/loo_results.csv")

# ── 2. Placebo treatment timing (shift treatment back 3 years) ──────────
cat("\n=== Placebo Test: Shifted Treatment ===\n")
panel_placebo <- copy(panel)
panel_placebo[first_treat > 0, first_treat_placebo := first_treat - 3]
panel_placebo[first_treat == 0, first_treat_placebo := 0]
# Restrict to pre-treatment period only
panel_placebo <- panel_placebo[fiscalyr < min(panel[first_treat > 0, first_treat])]
panel_placebo[, dist_num_p := as.integer(as.factor(dist_id))]

placebo_cs <- tryCatch({
  cs <- att_gt(
    yname = "acquittal_rate", tname = "fiscalyr",
    idname = "dist_num_p", gname = "first_treat_placebo",
    data = as.data.frame(panel_placebo),
    control_group = "nevertreated", anticipation = 0,
    base_period = "varying"
  )
  agg <- aggte(cs, type = "simple")
  cat("Placebo ATT:", round(agg$overall.att, 4),
      " SE:", round(agg$overall.se, 4), "\n")
  list(att = agg$overall.att, se = agg$overall.se)
}, error = function(e) {
  cat("Placebo CS failed:", e$message, "\n")
  list(att = NA, se = NA)
})

# ── 3. COVID robustness (exclude 2020-2021) ─────────────────────────────
cat("\n=== COVID Robustness (excluding 2020-2021) ===\n")
panel_nocovid <- panel[!fiscalyr %in% c(2020, 2021)]
panel_nocovid[, dist_num_nc := as.integer(as.factor(dist_id))]

covid_cs <- tryCatch({
  cs <- att_gt(
    yname = "acquittal_rate", tname = "fiscalyr",
    idname = "dist_num_nc", gname = "first_treat",
    data = as.data.frame(panel_nocovid),
    control_group = "nevertreated", anticipation = 0,
    base_period = "varying"
  )
  agg <- aggte(cs, type = "simple")
  cat("No-COVID ATT:", round(agg$overall.att, 4),
      " SE:", round(agg$overall.se, 4), "\n")
  list(att = agg$overall.att, se = agg$overall.se)
}, error = function(e) {
  cat("No-COVID CS failed:", e$message, "\n")
  list(att = NA, se = NA)
})

# ── 4. Randomization inference (permute treatment at state level) ────────
cat("\n=== Randomization Inference ===\n")
twfe <- feols(acquittal_rate ~ treated | dist_id + fiscalyr,
              data = panel, cluster = ~state_abbr)

set.seed(42)
n_perm <- 500
actual_coef <- coef(twfe)["treated"]
perm_coefs <- numeric(n_perm)

state_list <- unique(panel$state_abbr)
n_treated_states <- uniqueN(panel[first_treat > 0, state_abbr])

for (i in seq_len(n_perm)) {
  fake_avr <- sample(state_list, n_treated_states)
  panel_perm <- copy(panel)
  panel_perm[, treated_perm := as.integer(state_abbr %in% fake_avr & fiscalyr >= 2018)]
  perm_fit <- tryCatch(
    feols(acquittal_rate ~ treated_perm | dist_id + fiscalyr,
          data = panel_perm, cluster = ~state_abbr),
    error = function(e) NULL
  )
  perm_coefs[i] <- if (!is.null(perm_fit)) coef(perm_fit)["treated_perm"] else NA
}
ri_pval <- mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)
cat("RI p-value (500 permutations):", round(ri_pval, 3), "\n")
wcb <- list(p_val = ri_pval)

# ── 5. Weighted by verdicts ─────────────────────────────────────────────
cat("\n=== Verdict-Weighted Analysis ===\n")
# Weight by number of verdicts (larger districts get more weight)
twfe_w <- feols(acquittal_rate ~ treated | dist_id + fiscalyr,
                data = panel, cluster = ~state_abbr,
                weights = ~n_verdicts)
cat("Weighted TWFE:", round(coef(twfe_w)["treated"], 4),
    " SE:", round(se(twfe_w)["treated"], 4), "\n")

# ── 6. Alternative outcome: log verdicts (extensive margin) ─────────────
cat("\n=== Alternative Outcome: Log Jury Verdicts ===\n")
panel[, log_verdicts := log(n_verdicts + 1)]

twfe_lv <- feols(log_verdicts ~ treated | dist_id + fiscalyr,
                 data = panel, cluster = ~state_abbr)
cat("Effect on log(verdicts):", round(coef(twfe_lv)["treated"], 4),
    " SE:", round(se(twfe_lv)["treated"], 4), "\n")

# ── 7. HonestDiD sensitivity analysis ───────────────────────────────────
cat("\n=== HonestDiD Sensitivity ===\n")
tryCatch({
  library(HonestDiD)

  sa_full <- feols(acquittal_rate ~ sunab(cohort, fiscalyr) | dist_id + fiscalyr,
                   data = panel, cluster = ~state_abbr)

  # Extract pre and post coefficients
  coef_names <- names(coef(sa_full))
  event_times <- as.integer(gsub(".*::", "", coef_names))

  pre_idx <- which(event_times < 0)
  post_idx <- which(event_times >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    beta_hat <- coef(sa_full)
    sigma_hat <- vcov(sa_full)

    # Relative magnitudes approach
    honest <- createSensitivityResults_relativeMagnitudes(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0.5, 2, by = 0.5)
    )
    cat("HonestDiD relative magnitudes results:\n")
    print(honest)
    fwrite(as.data.table(honest), "data/honestdid_results.csv")
  } else {
    cat("Not enough pre/post periods for HonestDiD\n")
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
})

# ── 8. Save robustness results ──────────────────────────────────────────
robust_results <- list(
  loo_range = range(loo_dt$att, na.rm = TRUE),
  placebo_att = placebo_cs$att,
  placebo_se = placebo_cs$se,
  nocovid_att = covid_cs$att,
  nocovid_se = covid_cs$se,
  ri_pval = if (is.list(wcb)) wcb$p_val else NA,
  weighted_coef = coef(twfe_w)["treated"],
  weighted_se = se(twfe_w)["treated"],
  log_verdicts_coef = coef(twfe_lv)["treated"],
  log_verdicts_se = se(twfe_lv)["treated"]
)
write_json(robust_results, "data/robust_results.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== 04_robustness.R complete ===\n")
