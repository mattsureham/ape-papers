# ==============================================================================
# 04_robustness.R — Robustness checks for apep_1253
# ==============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv",
               colClasses = list(character = c("fips", "industry", "state_fips",
                                               "county_industry", "industry_quarter")))

cat("=== Robustness Checks ===\n\n")

robustness_results <- list()

# ==============================================================================
# 1. Placebo test: 2019Q4 as false treatment date
# ==============================================================================

cat("--- 1. Placebo: 2019Q4 as false treatment ---\n")

panel_pre <- panel[time_id <= 15]  # Up to 2021Q3 (exclude real post)
panel_pre[, placebo_post := as.integer(time_id >= 8)]  # 2019Q4 = time_id 8
panel_pre[, placebo_treat := poverty_rate * placebo_post]

fit_placebo <- feols(
  log_emp ~ placebo_treat | county_industry + industry_quarter,
  data = panel_pre,
  cluster = ~state_fips
)

cat(sprintf("Placebo β=%.5f (SE=%.5f), p=%.4f\n",
            coef(fit_placebo)["placebo_treat"],
            sqrt(diag(vcov(fit_placebo)))["placebo_treat"],
            pvalue(fit_placebo)["placebo_treat"]))

robustness_results[["placebo"]] <- data.table(
  test = "Placebo (2019Q4)",
  beta = coef(fit_placebo)["placebo_treat"],
  se = sqrt(diag(vcov(fit_placebo)))["placebo_treat"],
  pval = pvalue(fit_placebo)["placebo_treat"],
  n_obs = nobs(fit_placebo)
)

# ==============================================================================
# 2. Manufacturing as placebo outcome (SNAP recipients underrepresented)
# ==============================================================================

cat("\n--- 2. Manufacturing placebo outcome ---\n")

fit_mfg <- feols(
  log_emp ~ treat_post | county_industry + industry_quarter,
  data = panel[industry == "31-33"],
  cluster = ~state_fips
)

cat(sprintf("Manufacturing β=%.5f (SE=%.5f), p=%.4f\n",
            coef(fit_mfg)["treat_post"],
            sqrt(diag(vcov(fit_mfg)))["treat_post"],
            pvalue(fit_mfg)["treat_post"]))

robustness_results[["mfg_placebo"]] <- data.table(
  test = "Manufacturing placebo",
  beta = coef(fit_mfg)["treat_post"],
  se = sqrt(diag(vcov(fit_mfg)))["treat_post"],
  pval = pvalue(fit_mfg)["treat_post"],
  n_obs = nobs(fit_mfg)
)

# ==============================================================================
# 3. Leave-one-state-out jackknife
# ==============================================================================

cat("\n--- 3. Leave-one-state-out jackknife ---\n")

states <- sort(unique(panel$state_fips))
jack_betas <- numeric(length(states))

for (i in seq_along(states)) {
  fit_jack <- feols(
    log_emp ~ treat_post | county_industry + industry_quarter,
    data = panel[state_fips != states[i]],
    cluster = ~state_fips
  )
  jack_betas[i] <- coef(fit_jack)["treat_post"]
}

cat(sprintf("Jackknife β range: [%.5f, %.5f]\n", min(jack_betas), max(jack_betas)))
cat(sprintf("Jackknife β mean: %.5f, sd: %.5f\n", mean(jack_betas), sd(jack_betas)))

# Identify most influential state
most_influential <- states[which.max(abs(jack_betas - mean(jack_betas)))]
cat(sprintf("Most influential state: %s\n", most_influential))

saveRDS(data.table(state = states, beta = jack_betas), "../data/jackknife_results.rds")

# ==============================================================================
# 4. State × quarter FE (controls for state-level shocks like UI expiry)
# ==============================================================================

cat("\n--- 4. State × quarter FE ---\n")

panel[, state_quarter := paste0(state_fips, "_", time_id)]

fit_state_qtr <- feols(
  log_emp ~ treat_post | county_industry + industry_quarter + state_quarter,
  data = panel,
  cluster = ~state_fips
)

cat(sprintf("State × quarter FE: β=%.5f (SE=%.5f), p=%.4f\n",
            coef(fit_state_qtr)["treat_post"],
            sqrt(diag(vcov(fit_state_qtr)))["treat_post"],
            pvalue(fit_state_qtr)["treat_post"]))

robustness_results[["state_qtr_fe"]] <- data.table(
  test = "State × quarter FE",
  beta = coef(fit_state_qtr)["treat_post"],
  se = sqrt(diag(vcov(fit_state_qtr)))["treat_post"],
  pval = pvalue(fit_state_qtr)["treat_post"],
  n_obs = nobs(fit_state_qtr)
)

# ==============================================================================
# 5. Balanced panel only
# ==============================================================================

cat("\n--- 5. Balanced panel ---\n")

fit_balanced <- feols(
  log_emp ~ treat_post | county_industry + industry_quarter,
  data = panel[balanced == TRUE],
  cluster = ~state_fips
)

cat(sprintf("Balanced panel: β=%.5f (SE=%.5f), p=%.4f, N=%s\n",
            coef(fit_balanced)["treat_post"],
            sqrt(diag(vcov(fit_balanced)))["treat_post"],
            pvalue(fit_balanced)["treat_post"],
            format(nobs(fit_balanced), big.mark = ",")))

robustness_results[["balanced"]] <- data.table(
  test = "Balanced panel",
  beta = coef(fit_balanced)["treat_post"],
  se = sqrt(diag(vcov(fit_balanced)))["treat_post"],
  pval = pvalue(fit_balanced)["treat_post"],
  n_obs = nobs(fit_balanced)
)

# ==============================================================================
# 6. Alternative treatment: child poverty rate
# ==============================================================================

cat("\n--- 6. Alternative treatment: child poverty rate ---\n")

panel[, treat_post_child := child_poverty_rate * post]

fit_child <- feols(
  log_emp ~ treat_post_child | county_industry + industry_quarter,
  data = panel,
  cluster = ~state_fips
)

cat(sprintf("Child poverty rate: β=%.5f (SE=%.5f), p=%.4f\n",
            coef(fit_child)["treat_post_child"],
            sqrt(diag(vcov(fit_child)))["treat_post_child"],
            pvalue(fit_child)["treat_post_child"]))

robustness_results[["child_poverty"]] <- data.table(
  test = "Child poverty treatment",
  beta = coef(fit_child)["treat_post_child"],
  se = sqrt(diag(vcov(fit_child)))["treat_post_child"],
  pval = pvalue(fit_child)["treat_post_child"],
  n_obs = nobs(fit_child)
)

# ==============================================================================
# 7. Hires and separations outcomes
# ==============================================================================

cat("\n--- 7. Alternative outcomes: hires and separations ---\n")

panel[, log_hires := log(pmax(hires_all, 1))]
panel[, log_seps := log(pmax(separations, 1))]

fit_hires <- feols(
  log_hires ~ treat_post | county_industry + industry_quarter,
  data = panel,
  cluster = ~state_fips
)

fit_seps <- feols(
  log_seps ~ treat_post | county_industry + industry_quarter,
  data = panel,
  cluster = ~state_fips
)

cat(sprintf("Hires: β=%.5f (SE=%.5f), p=%.4f\n",
            coef(fit_hires)["treat_post"],
            sqrt(diag(vcov(fit_hires)))["treat_post"],
            pvalue(fit_hires)["treat_post"]))
cat(sprintf("Separations: β=%.5f (SE=%.5f), p=%.4f\n",
            coef(fit_seps)["treat_post"],
            sqrt(diag(vcov(fit_seps)))["treat_post"],
            pvalue(fit_seps)["treat_post"]))

robustness_results[["hires"]] <- data.table(
  test = "Hires outcome",
  beta = coef(fit_hires)["treat_post"],
  se = sqrt(diag(vcov(fit_hires)))["treat_post"],
  pval = pvalue(fit_hires)["treat_post"],
  n_obs = nobs(fit_hires)
)

robustness_results[["separations"]] <- data.table(
  test = "Separations outcome",
  beta = coef(fit_seps)["treat_post"],
  se = sqrt(diag(vcov(fit_seps)))["treat_post"],
  pval = pvalue(fit_seps)["treat_post"],
  n_obs = nobs(fit_seps)
)

# ==============================================================================
# Save all robustness results
# ==============================================================================

rob_dt <- rbindlist(robustness_results, fill = TRUE)
saveRDS(rob_dt, "../data/robustness_results.rds")

cat("\n=== Robustness summary ===\n")
print(rob_dt[, .(test, beta = round(beta, 5), se = round(se, 5),
                  pval = round(pval, 4), n_obs)])

cat("\n=== Robustness checks complete ===\n")
