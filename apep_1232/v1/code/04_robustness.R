## 04_robustness.R — Robustness checks and sensitivity analysis
## APEP-1232: Medicaid Doula Reimbursement and Birth Outcomes

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

# ─── A. Sun-Abraham estimator (alternative to CS) ──────────────────────────
cat("========== SUN-ABRAHAM ESTIMATOR ==========\n")

med <- panel %>%
  filter(payer == "medicaid", first_treat == 0 | first_treat >= 2018)

# sunab() in fixest
sa_csection <- feols(
  csection_rate ~ sunab(first_treat, year) | state_id + year,
  data = med,
  cluster = ~state_id,
  weights = ~births
)
cat("\nSun-Abraham: C-section rate\n")
summary(sa_csection)

# ─── B. Stacked DiD ─────────────────────────────────────────────────────────
cat("\n========== STACKED DiD ==========\n")

# Create stacked dataset: each cohort gets its own copy of never-treated
cohorts <- unique(med$first_treat[med$first_treat > 0])
stacked <- lapply(cohorts, function(g) {
  # Cohort g: treated units + never-treated, window [g-4, g+1]
  window <- (g - 4):(g + 1)
  window <- window[window >= min(med$year) & window <= max(med$year)]
  med %>%
    filter(first_treat %in% c(0, g), year %in% window) %>%
    mutate(
      cohort_id = g,
      stack_state = paste(state_id, g, sep = "_"),
      rel_time = year - g,
      post = as.integer(year >= g)
    )
}) %>% bind_rows()

stacked_did <- feols(
  csection_rate ~ post:i(first_treat > 0) | stack_state + cohort_id:year,
  data = stacked,
  cluster = ~state_id,
  weights = ~births
)
cat("\nStacked DiD: C-section rate\n")
summary(stacked_did)

# ─── C. Placebo: Private-insurance births in treated states ─────────────────
cat("\n========== PLACEBO: PRIVATE INSURANCE ==========\n")

priv <- panel %>%
  filter(payer == "private", first_treat == 0 | first_treat >= 2018)

cs_placebo <- att_gt(
  yname = "csection_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = priv,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_placebo <- aggte(cs_placebo, type = "simple")
cat("\nPlacebo ATT (Private C-section rate):\n")
summary(agg_placebo)

# ─── D. Leave-one-state-out jackknife ────────────────────────────────────────
cat("\n========== JACKKNIFE ==========\n")

treated_states <- unique(med$state[med$first_treat > 0])
jack_results <- sapply(treated_states, function(s) {
  d <- med %>% filter(state != s)
  d <- d %>% mutate(state_id_jack = as.integer(factor(state)))
  cs_j <- tryCatch({
    att_gt(
      yname = "csection_rate", tname = "year",
      idname = "state_id_jack", gname = "first_treat",
      data = d, control_group = "nevertreated", base_period = "universal"
    )
  }, error = function(e) NULL)
  if (is.null(cs_j)) return(NA_real_)
  agg_j <- aggte(cs_j, type = "simple")
  agg_j$overall.att
})

cat("Jackknife ATTs (dropping each treated state):\n")
for (i in seq_along(treated_states)) {
  cat("  Drop", treated_states[i], ":", round(jack_results[i], 5), "\n")
}
cat("  Full sample ATT:", round(results$agg_csection$overall.att, 5), "\n")
cat("  Jackknife range: [", round(min(jack_results, na.rm = TRUE), 5), ",",
    round(max(jack_results, na.rm = TRUE), 5), "]\n")

# ─── E. HonestDiD sensitivity (Rambachan-Roth bounds) ──────────────────────
cat("\n========== HONESTDID SENSITIVITY ==========\n")

# Use CS event study for HonestDiD
es_for_honest <- results$agg_es

tryCatch({
  betahat <- es_for_honest$att.egt
  sigma <- diag(es_for_honest$se.egt^2)  # Use diagonal vcov as approximation
  n_pre <- sum(es_for_honest$egt < 0)
  n_post <- sum(es_for_honest$egt >= 0)

  honest_result <- HonestDiD::createSensitivityResults_relativeMagnitudes(
    betahat = betahat,
    sigma = sigma,
    numPrePeriods = n_pre,
    numPostPeriods = n_post,
    Mbarvec = seq(0, 2, by = 0.5)
  )
  cat("\nHonestDiD relative magnitude sensitivity:\n")
  print(honest_result)
}, error = function(e) {
  cat("HonestDiD encountered an issue:", conditionMessage(e), "\n")
  cat("Note: Pre-trend at t-3 suggests caution. See discussion in paper.\n")
})

# ─── F. Extract coefficients and save ────────────────────────────────────────
# Save extracted coefficients rather than full fixest objects (which need
# the original data environment to reconstruct model matrices)

sa_summary <- summary(sa_csection, agg = "ATT")
sa_coefs <- data.frame(
  est = sa_summary$coeftable[1, "Estimate"],
  se = sa_summary$coeftable[1, "Std. Error"],
  p = sa_summary$coeftable[1, "Pr(>|t|)"]
)

stacked_ct <- coeftable(stacked_did)
stacked_coefs <- data.frame(
  est = stacked_ct[1, "Estimate"],
  se = stacked_ct[1, "Std. Error"],
  p = stacked_ct[1, "Pr(>|t|)"]
)

robust <- list(
  sa_coefs = sa_coefs,
  stacked_coefs = stacked_coefs,
  placebo = agg_placebo,
  jackknife = data.frame(state = treated_states, att = jack_results),
  cs_placebo = cs_placebo
)

saveRDS(robust, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
