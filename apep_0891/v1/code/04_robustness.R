## 04_robustness.R — Robustness and placebo checks
## SNAP EA Expiration and Eviction Filings

source("00_packages.R")

data_dir <- "../data"
monthly <- readRDS(file.path(data_dir, "ets_panel_monthly.rds"))
monthly[median_income < 0, median_income := NA_real_]

cat("=== ROBUSTNESS CHECKS ===\n\n")

## ═══════════════════════════════════════════════════════════════════
## 1. Log specification (semi-elasticity)
## ═══════════════════════════════════════════════════════════════════
cat("1. Log filing rate (semi-elasticity)\n")

monthly[, log_filing := log(filing_rate + 0.01)]

twfe_log <- feols(
  log_filing ~ post | GEOID + month_num,
  data = monthly,
  cluster = ~state_abbr
)
cat("  Log TWFE:", round(coef(twfe_log)["post"], 4),
    "SE:", round(se(twfe_log)["post"], 4),
    "p:", round(fixest::pvalue(twfe_log)["post"], 4), "\n")

## ═══════════════════════════════════════════════════════════════════
## 2. Poisson count model
## ═══════════════════════════════════════════════════════════════════
cat("\n2. Poisson count model\n")

pois_main <- tryCatch({
  fepois(
    filings ~ post | GEOID + month_num,
    data = monthly[filings >= 0],
    cluster = ~state_abbr
  )
}, error = function(e) {
  cat("  Poisson failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(pois_main)) {
  cat("  Poisson IRR:", round(exp(coef(pois_main)["post"]), 4),
      "coef:", round(coef(pois_main)["post"], 4),
      "SE:", round(se(pois_main)["post"], 4),
      "p:", round(fixest::pvalue(pois_main)["post"], 4), "\n")
}

## ═══════════════════════════════════════════════════════════════════
## 3. Alternative treatment timing: use only Wave 1 (April 2021)
## ═══════════════════════════════════════════════════════════════════
cat("\n3. Wave 1 only (April 2021 opt-outs)\n")

## Wave 1 states with ETS coverage: FL, MO, TN
## (AK, IA, MS, MT, ND, NE, SD, WY don't have ETS cities)
wave1_states <- c("FL", "MO", "TN")
wave1_data <- monthly[state_abbr %in% wave1_states | early_optout == FALSE]
wave1_data[, post_w1 := as.integer(year_month >= as.Date("2021-04-01") & early_optout)]

twfe_w1 <- feols(
  filing_rate ~ post_w1 | GEOID + month_num,
  data = wave1_data,
  cluster = ~state_abbr
)
cat("  Wave 1 ATT:", round(coef(twfe_w1)["post_w1"], 4),
    "SE:", round(se(twfe_w1)["post_w1"], 4),
    "p:", round(fixest::pvalue(twfe_w1)["post_w1"], 4), "\n")

## ═══════════════════════════════════════════════════════════════════
## 4. COVID-adjusted: exclude March-December 2020
## ═══════════════════════════════════════════════════════════════════
cat("\n4. COVID-adjusted (exclude Mar-Dec 2020)\n")

monthly_nocovid <- monthly[year_month < as.Date("2020-03-01") |
                             year_month >= as.Date("2021-01-01")]

twfe_nocovid <- feols(
  filing_rate ~ post | GEOID + month_num,
  data = monthly_nocovid,
  cluster = ~state_abbr
)
cat("  Post-COVID ATT:", round(coef(twfe_nocovid)["post"], 4),
    "SE:", round(se(twfe_nocovid)["post"], 4),
    "p:", round(fixest::pvalue(twfe_nocovid)["post"], 4), "\n")

## ═══════════════════════════════════════════════════════════════════
## 5. Racial heterogeneity
## ═══════════════════════════════════════════════════════════════════
cat("\n5. Racial heterogeneity\n")

## Majority-Black tracts
monthly[, majority_black := pct_black > 0.5]
monthly[, high_minority := (pct_black + pct_hispanic) > 0.5]

for (label in c("majority_black", "high_minority")) {
  for (val in c(TRUE, FALSE)) {
    fit <- feols(
      filing_rate ~ post | GEOID + month_num,
      data = monthly[get(label) == val],
      cluster = ~state_abbr
    )
    cat("  ", label, "=", val, "- ATT:", round(coef(fit)["post"], 4),
        "SE:", round(se(fit)["post"], 4),
        "p:", round(fixest::pvalue(fit)["post"], 4), "\n")
  }
}

## ═══════════════════════════════════════════════════════════════════
## 6. Leave-one-state-out
## ═══════════════════════════════════════════════════════════════════
cat("\n6. Leave-one-state-out\n")

treated_states <- unique(monthly[early_optout == TRUE, state_abbr])
loso_results <- data.table(
  dropped_state = character(),
  att = numeric(),
  se = numeric()
)

for (st in treated_states) {
  fit <- feols(
    filing_rate ~ post | GEOID + month_num,
    data = monthly[state_abbr != st],
    cluster = ~state_abbr
  )
  loso_results <- rbind(loso_results, data.table(
    dropped_state = st,
    att = round(coef(fit)["post"], 4),
    se = round(se(fit)["post"], 4)
  ))
}

cat("Leave-one-out range:",
    round(min(loso_results$att), 4), "to",
    round(max(loso_results$att), 4), "\n")
print(loso_results)

## ═══════════════════════════════════════════════════════════════════
## 7. Randomization Inference (permutation test)
## ═══════════════════════════════════════════════════════════════════
cat("\n7. Randomization Inference\n")

## Permute state-level treatment assignment 1000 times
set.seed(42)
n_perms <- 1000
true_att <- coef(feols(
  filing_rate ~ post | GEOID + month_num,
  data = monthly,
  cluster = ~state_abbr
))["post"]

all_states_ets <- unique(monthly$state_abbr)
n_treated_states <- length(treated_states)

perm_atts <- numeric(n_perms)
valid <- 0L
attempt <- 0L
while (valid < n_perms && attempt < n_perms * 3) {
  attempt <- attempt + 1L
  ## Randomly assign treatment to states
  fake_treated <- sample(all_states_ets, n_treated_states)
  tmp <- copy(monthly)
  ## Assign fake treatment using the actual timing structure
  tmp[, fake_early := state_abbr %in% fake_treated]
  tmp[, fake_post := as.integer(fake_early & year_month >= ea_end_date)]

  ## Skip if collinear
  if (sum(tmp$fake_post) == 0 || sum(tmp$fake_post) == nrow(tmp)) next

  fit_perm <- tryCatch(
    feols(filing_rate ~ fake_post | GEOID + month_num, data = tmp),
    error = function(e) NULL
  )
  if (is.null(fit_perm)) next

  valid <- valid + 1L
  perm_atts[valid] <- coef(fit_perm)["fake_post"]

  if (valid %% 200 == 0) cat("  Permutation", valid, "/", n_perms, "\n")
}
cat("  Completed", valid, "valid permutations out of", attempt, "attempts\n")

ri_pval <- mean(abs(perm_atts) >= abs(true_att))
cat("  RI p-value:", round(ri_pval, 4), "\n")
cat("  True ATT:", round(true_att, 4), "\n")
cat("  Permutation distribution: mean =", round(mean(perm_atts), 4),
    "SD =", round(sd(perm_atts), 4), "\n")

## ═══════════════════════════════════════════════════════════════════
## Store robustness results
## ═══════════════════════════════════════════════════════════════════
rob_results <- list(
  log_spec = list(att = round(coef(twfe_log)["post"], 4),
                  se = round(se(twfe_log)["post"], 4)),
  wave1_only = list(att = round(coef(twfe_w1)["post_w1"], 4),
                     se = round(se(twfe_w1)["post_w1"], 4)),
  no_covid = list(att = round(coef(twfe_nocovid)["post"], 4),
                   se = round(se(twfe_nocovid)["post"], 4)),
  ri_pval = round(ri_pval, 4),
  loso_range = c(round(min(loso_results$att), 4),
                  round(max(loso_results$att), 4))
)

if (!is.null(pois_main)) {
  rob_results$poisson <- list(
    irr = round(exp(coef(pois_main)["post"]), 4),
    coef = round(coef(pois_main)["post"], 4),
    se = round(se(pois_main)["post"], 4)
  )
}

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
saveRDS(loso_results, file.path(data_dir, "loso_results.rds"))
saveRDS(perm_atts, file.path(data_dir, "ri_distribution.rds"))

cat("\nRobustness checks complete.\n")
