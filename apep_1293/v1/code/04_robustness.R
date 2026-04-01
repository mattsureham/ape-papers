## ==============================================================
## 04_robustness.R — apep_1293
## Robustness checks and falsification tests
## ==============================================================

source("code/00_packages.R")

panel <- fread("data/analysis_panel.csv")
panel[, mun_code := as.character(mun_code)]
panel_main <- panel[year <= 2022]

## ------------------------------------------------------------------
## 1. Placebo: Non-firearm homicide (should show NO effect)
## ------------------------------------------------------------------

cat("=== Robustness 1: Placebo (non-firearm homicide) ===\n")

nf <- panel_main[cause_group == "nonfirearm_homicide"]

# Continuous treatment
placebo_cont <- feols(rate ~ post2019_clubs | mun_code + year,
                      data = nf, cluster = ~mun_code)
cat(sprintf("Placebo (continuous): coef=%.4f, se=%.4f, p=%.4f\n",
            coef(placebo_cont), se(placebo_cont), fixest::pvalue(placebo_cont)))

# Binary treatment
nf[, post2019_hasclub := post_2019 * has_club]
placebo_bin <- feols(rate ~ post2019_hasclub | mun_code + year,
                     data = nf, cluster = ~mun_code)
cat(sprintf("Placebo (binary): coef=%.4f, se=%.4f, p=%.4f\n",
            coef(placebo_bin), se(placebo_bin), fixest::pvalue(placebo_bin)))

## ------------------------------------------------------------------
## 2. Alternative treatment: Club GROWTH (2018-2022)
## ------------------------------------------------------------------

cat("\n=== Robustness 2: Club growth as treatment ===\n")

clubs_full <- fread("data/shooting_clubs_panel.csv")
clubs_full[, mun_code := as.character(mun_code)]

# Compute club growth: 2022 count - 2018 count
clubs_growth <- merge(
  clubs_full[year == 2022, .(mun_code, clubs_2022 = active_clubs)],
  clubs_full[year == 2018, .(mun_code, clubs_2018 = active_clubs)],
  by = "mun_code", all = TRUE
)
clubs_growth[is.na(clubs_2022), clubs_2022 := 0L]
clubs_growth[is.na(clubs_2018), clubs_2018 := 0L]
clubs_growth[, club_growth := clubs_2022 - clubs_2018]

# Note: Club growth is endogenous (post-treatment), so we use it
# as OUTCOME/MECHANISM, not as instrument
cat(sprintf("Municipalities with club growth > 0: %d\n",
            sum(clubs_growth$club_growth > 0)))
cat(sprintf("Mean growth (conditional on any club): %.2f\n",
            mean(clubs_growth[clubs_2018 > 0 | clubs_2022 > 0]$club_growth)))

## ------------------------------------------------------------------
## 3. Leave-one-state-out
## ------------------------------------------------------------------

cat("\n=== Robustness 3: Leave-one-state-out ===\n")

fire <- panel_main[cause_group == "firearm_homicide"]

# Get state from municipality code (first 2 digits)
fire[, state_code := substr(mun_code, 1, 2)]
states <- unique(fire$state_code)

loso_results <- data.table(
  state_excluded = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric()
)

for (st in states) {
  sub <- fire[state_code != st]
  fit <- feols(rate ~ post2019_clubs | mun_code + year,
               data = sub, cluster = ~mun_code)
  loso_results <- rbind(loso_results, data.table(
    state_excluded = st,
    coef = coef(fit),
    se = se(fit),
    pval = fixest::pvalue(fit)
  ))
}

cat(sprintf("LOSO range: [%.4f, %.4f]\n",
            min(loso_results$coef), max(loso_results$coef)))
cat(sprintf("Main estimate: %.4f\n", coef(feols(rate ~ post2019_clubs | mun_code + year,
                                                  data = fire, cluster = ~mun_code))))

## ------------------------------------------------------------------
## 4. Population-weighted regression
## ------------------------------------------------------------------

cat("\n=== Robustness 4: Population-weighted ===\n")

fire_weighted <- feols(rate ~ post2019_clubs | mun_code + year,
                       data = fire, cluster = ~mun_code,
                       weights = ~population)
cat(sprintf("Weighted (continuous): coef=%.4f, se=%.4f, p=%.4f\n",
            coef(fire_weighted), se(fire_weighted), fixest::pvalue(fire_weighted)))

fire_weighted_bin <- feols(rate ~ post2019_hasclub | mun_code + year,
                           data = fire, cluster = ~mun_code,
                           weights = ~population)
cat(sprintf("Weighted (binary): coef=%.4f, se=%.4f, p=%.4f\n",
            coef(fire_weighted_bin), se(fire_weighted_bin),
            fixest::pvalue(fire_weighted_bin)))

## ------------------------------------------------------------------
## 5. State-clustered standard errors
## ------------------------------------------------------------------

cat("\n=== Robustness 5: State-clustered SEs ===\n")

fire[, state_code := substr(mun_code, 1, 2)]

state_clust <- feols(rate ~ post2019_clubs | mun_code + year,
                     data = fire, cluster = ~state_code)
cat(sprintf("State-clustered (continuous): coef=%.4f, se=%.4f, p=%.4f\n",
            coef(state_clust), se(state_clust), fixest::pvalue(state_clust)))

state_clust_bin <- feols(rate ~ post2019_hasclub | mun_code + year,
                         data = fire, cluster = ~state_code)
cat(sprintf("State-clustered (binary): coef=%.4f, se=%.4f, p=%.4f\n",
            coef(state_clust_bin), se(state_clust_bin), fixest::pvalue(state_clust_bin)))

## ------------------------------------------------------------------
## 6. Alternative outcome: log(deaths + 1)
## ------------------------------------------------------------------

cat("\n=== Robustness 6: Log deaths ===\n")

fire[, log_deaths := log(deaths + 1)]

log_spec <- feols(log_deaths ~ post2019_clubs | mun_code + year,
                  data = fire, cluster = ~mun_code)
cat(sprintf("Log deaths (continuous): coef=%.5f, se=%.5f, p=%.4f\n",
            coef(log_spec), se(log_spec), fixest::pvalue(log_spec)))

## ------------------------------------------------------------------
## 7. Save robustness results
## ------------------------------------------------------------------

cat("\n=== Saving robustness results ===\n")

saveRDS(list(
  placebo_cont = placebo_cont,
  placebo_bin = placebo_bin,
  fire_weighted = fire_weighted,
  fire_weighted_bin = fire_weighted_bin,
  state_clust = state_clust,
  state_clust_bin = state_clust_bin,
  log_spec = log_spec,
  loso_results = loso_results
), "data/robustness_models.rds")

fwrite(loso_results, "data/loso_results.csv")

cat("All robustness results saved.\n")
