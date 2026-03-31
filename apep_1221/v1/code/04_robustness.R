## =============================================================================
## 04_robustness.R — Robustness checks and heterogeneity
## Paper: Rejected and Relocated (apep_1221)
## =============================================================================

library(data.table)
library(fixest)
library(jsonlite)

dt <- fread("../data/analysis_data.csv")
cat(sprintf("Loaded: %s rows\n", format(nrow(dt), big.mark = ",")))

## ---------------------------------------------------------------------------
## 1. Examiner balance: leniency should not predict pre-determined covariates
## ---------------------------------------------------------------------------

cat("\n=== EXAMINER BALANCE ===\n")

# Leniency should not predict: solo, prior_grants, team_size
bal_solo <- feols(solo ~ examiner_leniency | au_year, data = dt, vcov = ~au_year)
bal_prior <- feols(prior_grants ~ examiner_leniency | au_year, data = dt, vcov = ~au_year)
bal_team <- feols(team_size ~ examiner_leniency | au_year, data = dt, vcov = ~au_year)

cat(sprintf("Leniency -> Solo:    %.5f (SE: %.5f, p=%.3f)\n",
            coef(bal_solo)[1], se(bal_solo)[1], pvalue(bal_solo)[1]))
cat(sprintf("Leniency -> Prior:   %.5f (SE: %.5f, p=%.3f)\n",
            coef(bal_prior)[1], se(bal_prior)[1], pvalue(bal_prior)[1]))
cat(sprintf("Leniency -> Team:    %.5f (SE: %.5f, p=%.3f)\n",
            coef(bal_team)[1], se(bal_team)[1], pvalue(bal_team)[1]))

## ---------------------------------------------------------------------------
## 2. Placebo: examiner leniency should not predict PRIOR mobility
## ---------------------------------------------------------------------------

cat("\n=== PLACEBO: Leniency -> Prior Move ===\n")

# Prior move: did inventor move BEFORE this application?
setorder(dt, inventor_id, filing_year)
dt[, prev_state := shift(state, type = "lag"), by = inventor_id]
dt[, prior_moved := as.integer(!is.na(prev_state) & state != prev_state)]

placebo_rf <- feols(prior_moved ~ examiner_leniency | au_year,
                    data = dt[!is.na(prev_state)], vcov = ~au_year)
cat(sprintf("Placebo RF coef: %.5f (SE: %.5f, p=%.3f)\n",
            coef(placebo_rf)[1], se(placebo_rf)[1], pvalue(placebo_rf)[1]))

## ---------------------------------------------------------------------------
## 3. Heterogeneity: Solo vs Team inventors (IV)
## ---------------------------------------------------------------------------

cat("\n=== HETEROGENEITY: Solo vs Team ===\n")

iv_solo <- feols(moved ~ 1 | au_year | rejected ~ examiner_leniency,
                 data = dt[solo == 1], vcov = ~au_year)
iv_team <- feols(moved ~ 1 | au_year | rejected ~ examiner_leniency,
                 data = dt[solo == 0], vcov = ~au_year)

cat(sprintf("IV (solo):  %.4f (SE: %.4f, N=%s)\n",
            coef(iv_solo)[1], se(iv_solo)[1],
            format(nobs(iv_solo), big.mark = ",")))
cat(sprintf("IV (team):  %.4f (SE: %.4f, N=%s)\n",
            coef(iv_team)[1], se(iv_team)[1],
            format(nobs(iv_team), big.mark = ",")))

## ---------------------------------------------------------------------------
## 4. Heterogeneity: Experienced vs Novice inventors (IV)
## ---------------------------------------------------------------------------

cat("\n=== HETEROGENEITY: Experience ===\n")

dt[, experienced := as.integer(prior_grants >= 1)]

iv_exp <- feols(moved ~ 1 | au_year | rejected ~ examiner_leniency,
                data = dt[experienced == 1], vcov = ~au_year)
iv_nov <- feols(moved ~ 1 | au_year | rejected ~ examiner_leniency,
                data = dt[experienced == 0], vcov = ~au_year)

cat(sprintf("IV (experienced): %.4f (SE: %.4f, N=%s)\n",
            coef(iv_exp)[1], se(iv_exp)[1],
            format(nobs(iv_exp), big.mark = ",")))
cat(sprintf("IV (novice):      %.4f (SE: %.4f, N=%s)\n",
            coef(iv_nov)[1], se(iv_nov)[1],
            format(nobs(iv_nov), big.mark = ",")))

## ---------------------------------------------------------------------------
## 5. Heterogeneity: Technology fields
## ---------------------------------------------------------------------------

cat("\n=== HETEROGENEITY: Tech Centers (top 5) ===\n")

top_tc <- dt[, .N, by = tech_center][order(-N)][1:5]$tech_center
for (tc in top_tc) {
  iv_tc <- feols(moved ~ 1 | au_year | rejected ~ examiner_leniency,
                 data = dt[tech_center == tc], vcov = ~au_year)
  cat(sprintf("  TC %s: %.4f (SE: %.4f, N=%s)\n",
              tc, coef(iv_tc)[1], se(iv_tc)[1],
              format(nobs(iv_tc), big.mark = ",")))
}

## ---------------------------------------------------------------------------
## 6. Robustness: minimum AU-year cell size
## ---------------------------------------------------------------------------

cat("\n=== ROBUSTNESS: AU-year cell size thresholds ===\n")

for (min_apps in c(10, 30, 50)) {
  au_yr_size <- dt[, .N, by = au_year]
  valid <- au_yr_size[N >= min_apps]$au_year
  sub <- dt[au_year %in% valid]
  iv_sub <- feols(moved ~ 1 | au_year | rejected ~ examiner_leniency,
                  data = sub, vcov = ~au_year)
  cat(sprintf("  Min %d apps: %.4f (SE: %.4f, N=%s, AU-years=%s)\n",
              min_apps, coef(iv_sub)[1], se(iv_sub)[1],
              format(nobs(iv_sub), big.mark = ","),
              format(uniqueN(sub$au_year), big.mark = ",")))
}

## ---------------------------------------------------------------------------
## 7. Save heterogeneity results for tables
## ---------------------------------------------------------------------------

hetero <- list(
  solo_coef = coef(iv_solo)[1],
  solo_se = se(iv_solo)[1],
  solo_n = nobs(iv_solo),
  team_coef = coef(iv_team)[1],
  team_se = se(iv_team)[1],
  team_n = nobs(iv_team),
  exp_coef = coef(iv_exp)[1],
  exp_se = se(iv_exp)[1],
  exp_n = nobs(iv_exp),
  nov_coef = coef(iv_nov)[1],
  nov_se = se(iv_nov)[1],
  nov_n = nobs(iv_nov),
  bal_solo_coef = coef(bal_solo)[1],
  bal_solo_se = se(bal_solo)[1],
  bal_solo_p = pvalue(bal_solo)[1],
  bal_prior_coef = coef(bal_prior)[1],
  bal_prior_se = se(bal_prior)[1],
  bal_prior_p = pvalue(bal_prior)[1],
  bal_team_coef = coef(bal_team)[1],
  bal_team_se = se(bal_team)[1],
  bal_team_p = pvalue(bal_team)[1],
  placebo_coef = coef(placebo_rf)[1],
  placebo_se = se(placebo_rf)[1],
  placebo_p = pvalue(placebo_rf)[1]
)

write_json(hetero, "../data/robustness_results.json", auto_unbox = TRUE)

# Save model objects
save(bal_solo, bal_prior, bal_team, placebo_rf,
     iv_solo, iv_team, iv_exp, iv_nov,
     file = "../data/robustness_models.RData")

cat("\nAll robustness results saved.\n")
cat("Done.\n")
