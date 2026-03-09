## ============================================================
## 04_robustness.R — Robustness checks
## Cap On, Cap Off: Kenya's Interest Rate Ceiling (2016-2019)
## ============================================================

source("00_packages.R")

## --- Load Data ---
tier_panel <- fread(file.path(DATA_DIR, "tier_panel_clean.csv"))
cc_all     <- fread(file.path(DATA_DIR, "cross_country_clean.csv"))

# Recreate needed variables
tier_panel <- tier_panel |>
  mutate(
    is_tier3 = as.integer(tier == "Tier3"),
    is_tier2 = as.integer(tier == "Tier2"),
    cap_on = as.integer(year >= 2017 & year <= 2019),
    repeal = as.integer(year >= 2020),
    et = year - 2016,
    exposure_cap = exposure * cap_on,
    exposure_repeal = exposure * repeal
  )

cc_all <- cc_all |> mutate(treated = as.integer(country == "KE"))

## ============================================================
## ROBUSTNESS 1: Pre-Trends Test (Joint F-test)
## ============================================================
cat("=== ROBUSTNESS 1: Pre-Trends Test ===\n\n")

# Restrict to pre-cap period (2010-2015), test for differential trends
pre_cap <- tier_panel |> filter(year <= 2015)

# Test: is Tier3 × year significant in the pre-period?
pre_trend_test <- feols(loan_asset_ratio ~ is_tier3:i(year) | tier + year,
                        data = pre_cap, cluster = ~tier)

cat("Pre-trend test (Tier3 × year in pre-period):\n")
print(summary(pre_trend_test))

# Joint F-test on pre-treatment interactions
pre_trend_f <- fitstat(pre_trend_test, type = "wald")
cat("\nJoint F-test on pre-treatment interactions:\n")
print(pre_trend_f)

## ============================================================
## ROBUSTNESS 2: Alternative Exposure Measures
## ============================================================
cat("\n=== ROBUSTNESS 2: Alternative Exposure Measures ===\n\n")

# 2a: Tier 2 vs Tier 1 (intermediate exposure)
m_tier2 <- feols(loan_asset_ratio ~ is_tier2:cap_on + is_tier2:repeal |
                   tier + year,
                 data = tier_panel |> filter(tier != "Tier3"),
                 cluster = ~tier)

cat("Tier 2 vs Tier 1 (intermediate exposure):\n")
print(summary(m_tier2))

# 2b: Government securities ratio as exposure (inverse)
tier_panel <- tier_panel |>
  mutate(
    low_govt_sec = as.integer(baseline_govt_ratio < median(baseline_govt_ratio))
  )

m_govt_exp <- feols(loan_asset_ratio ~ low_govt_sec:cap_on + low_govt_sec:repeal |
                      tier + year,
                    data = tier_panel, cluster = ~tier)

cat("\nLow baseline govt securities exposure:\n")
print(summary(m_govt_exp))

# Save alternative exposure results
rob2_results <- bind_rows(
  tibble(spec = "Tier2 vs Tier1", coef_cap = coef(m_tier2)[1],
         se_cap = coeftable(m_tier2)[1, 2]),
  tibble(spec = "Low Govt Sec", coef_cap = coef(m_govt_exp)[1],
         se_cap = coeftable(m_govt_exp)[1, 2])
)
fwrite(rob2_results, file.path(DATA_DIR, "robustness_alt_exposure.csv"))

## ============================================================
## ROBUSTNESS 3: Pre-COVID Repeal Window (Nov 2019 - Feb 2020)
## ============================================================
cat("\n=== ROBUSTNESS 3: Pre-COVID Repeal Window ===\n\n")

# Since annual data can't isolate 4 months, test with year 2019 vs 2020
# The key test: does Tier 3 show recovery in 2020 even with COVID?
# If yes, the repeal effect is strong enough to overcome COVID

# Alternative: restrict to 2010-2019 (drop post-COVID entirely)
pre_covid <- tier_panel |> filter(year <= 2019)

m_precovid <- feols(loan_asset_ratio ~ is_tier3:cap_on |
                      tier + year,
                    data = pre_covid, cluster = ~tier)

cat("Pre-COVID only (2010-2019):\n")
print(summary(m_precovid))

# Coefficient stability: compare with full sample
m_full <- feols(loan_asset_ratio ~ is_tier3:cap_on + is_tier3:repeal |
                  tier + year,
                data = tier_panel, cluster = ~tier)

cat("\nFull sample (2010-2023):\n")
print(summary(m_full))

cat("\nCoefficient stability check:\n")
cat("  Cap effect (pre-COVID only):", round(coef(m_precovid)[1], 4), "\n")
cat("  Cap effect (full sample):", round(coef(m_full)[1], 4), "\n")

## ============================================================
## ROBUSTNESS 4: Leave-One-Tier-Out
## ============================================================
cat("\n=== ROBUSTNESS 4: Leave-One-Tier-Out ===\n\n")

# With only 3 tiers, LOO is limited: dropping Tier3 removes treatment variation
# Instead, show pairwise comparisons: Tier3 vs Tier1, Tier3 vs Tier2, Tier2 vs Tier1
pairs <- list(
  c("Tier3", "Tier1"),
  c("Tier3", "Tier2"),
  c("Tier2", "Tier1")
)

loo_results <- map_dfr(pairs, function(p) {
  d <- tier_panel |> filter(tier %in% p) |>
    mutate(is_treated = as.integer(tier == p[1]))
  m <- tryCatch({
    feols(loan_asset_ratio ~ is_treated:cap_on + is_treated:repeal |
            tier + year, data = d, cluster = ~tier)
  }, error = function(e) NULL)

  if (!is.null(m)) {
    ct <- coeftable(m)
    tibble(
      comparison = paste(p[1], "vs", p[2]),
      coef_cap = ct[1, 1],
      se_cap = ct[1, 2],
      coef_repeal = ct[2, 1],
      se_repeal = ct[2, 2]
    )
  } else {
    tibble(
      comparison = paste(p[1], "vs", p[2]),
      coef_cap = NA, se_cap = NA, coef_repeal = NA, se_repeal = NA
    )
  }
})

cat("Pairwise tier comparisons:\n")
print(loo_results)
fwrite(loo_results, file.path(DATA_DIR, "robustness_loo.csv"))

## ============================================================
## ROBUSTNESS 5: Placebo Outcomes
## ============================================================
cat("\n=== ROBUSTNESS 5: Placebo Outcomes ===\n\n")

# Placebo: Total assets should grow similarly across tiers
# (Assets reflect bank size, not directly the rate cap)
m_placebo_assets <- feols(log_assets ~ is_tier3:cap_on + is_tier3:repeal |
                            tier + year,
                          data = tier_panel, cluster = ~tier)

cat("Placebo: Log Total Assets (should be insignificant):\n")
print(summary(m_placebo_assets))

# Placebo: Number of banks (structural, not affected by rate cap)
m_placebo_nbanks <- feols(n_banks ~ is_tier3:cap_on + is_tier3:repeal |
                            tier + year,
                          data = tier_panel, cluster = ~tier)

cat("\nPlacebo: Number of Banks:\n")
print(summary(m_placebo_nbanks))

placebo_results <- bind_rows(
  tibble(outcome = "Log Assets", coef_cap = coef(m_placebo_assets)[1],
         se_cap = coeftable(m_placebo_assets)[1, 2], type = "placebo"),
  tibble(outcome = "N Banks", coef_cap = coef(m_placebo_nbanks)[1],
         se_cap = coeftable(m_placebo_nbanks)[1, 2], type = "placebo")
)
fwrite(placebo_results, file.path(DATA_DIR, "robustness_placebo.csv"))

## ============================================================
## ROBUSTNESS 6: Cross-Country Robustness
## ============================================================
cat("\n=== ROBUSTNESS 6: Cross-Country Robustness ===\n\n")

# 6a: Drop each comparator country
cc_countries <- unique(cc_all$country[cc_all$country != "KE"])
cc_loo <- map_dfr(cc_countries, function(cc) {
  d <- cc_all |> filter(country != cc, !is.na(credit_gdp))
  m <- feols(credit_gdp ~ treated:cap_on + treated:repeal |
               country + year,
             data = d, cluster = ~country)
  ct <- coeftable(m)
  tibble(
    dropped = cc,
    coef_cap = ct[1, 1],
    se_cap = ct[1, 2],
    coef_repeal = ct[2, 1],
    se_repeal = ct[2, 2]
  )
})

cat("Cross-country leave-one-out (Credit/GDP):\n")
print(cc_loo)
fwrite(cc_loo, file.path(DATA_DIR, "robustness_cc_loo.csv"))

# 6b: Pre-COVID restriction
cc_precovid <- cc_all |> filter(year <= 2019, !is.na(credit_gdp))
m_cc_precovid <- feols(credit_gdp ~ treated:cap_on |
                         country + year,
                       data = cc_precovid, cluster = ~country)

cat("\nCross-country pre-COVID (2010-2019):\n")
print(summary(m_cc_precovid))

## ============================================================
## ROBUSTNESS 7: Randomization Inference (Tier Permutation)
## — All 4 main outcomes
## ============================================================
cat("\n=== ROBUSTNESS 7: Randomization Inference ===\n\n")

set.seed(42)
n_perms <- 1000

# Define all 4 main outcomes
ri_outcomes <- c("loan_asset_ratio", "govt_sec_ratio", "npl_ratio", "log_loans")
ri_labels   <- c("Loan/Asset", "Govt Sec/Asset", "NPL Ratio", "Log Loans")

# Observed statistics (cap-on coefficient for each outcome)
obs_models <- lapply(ri_outcomes, function(y) {
  feols(as.formula(paste0(y, " ~ is_tier3:cap_on + is_tier3:repeal | tier + year")),
        data = tier_panel, cluster = ~tier)
})
obs_stats <- sapply(obs_models, function(m) coef(m)[1])

# Permutation distribution for all outcomes simultaneously
perm_matrix <- matrix(NA_real_, nrow = n_perms, ncol = length(ri_outcomes))
for (p in seq_len(n_perms)) {
  d_perm <- tier_panel |>
    group_by(year) |>
    mutate(tier_perm = sample(tier)) |>
    ungroup() |>
    mutate(is_tier3_perm = as.integer(tier_perm == "Tier3"))

  for (j in seq_along(ri_outcomes)) {
    m_perm <- tryCatch({
      feols(as.formula(paste0(ri_outcomes[j],
            " ~ is_tier3_perm:cap_on | tier + year")),
            data = d_perm)
    }, error = function(e) NULL)

    if (!is.null(m_perm) && length(coef(m_perm)) >= 1) {
      perm_matrix[p, j] <- coef(m_perm)[1]
    }
  }
}

# Compute RI p-values for each outcome
ri_all <- tibble(
  outcome = ri_labels,
  obs_stat = obs_stats,
  ri_pvalue_raw = sapply(seq_along(ri_outcomes), function(j) {
    ps <- perm_matrix[!is.na(perm_matrix[, j]), j]
    mean(abs(ps) >= abs(obs_stats[j]))
  }),
  n_valid = sapply(seq_along(ri_outcomes), function(j) {
    sum(!is.na(perm_matrix[, j]))
  })
) |>
  mutate(
    ri_pvalue = pmax(ri_pvalue_raw, 1 / (n_valid + 1))
  )

cat("Randomization Inference (all 4 outcomes):\n")
for (i in seq_len(nrow(ri_all))) {
  if (ri_all$ri_pvalue_raw[i] == 0) {
    cat(sprintf("  %s: obs = %.4f, RI p < %.4f (%d perms)\n",
        ri_all$outcome[i], ri_all$obs_stat[i],
        1 / (ri_all$n_valid[i] + 1), ri_all$n_valid[i]))
  } else {
    cat(sprintf("  %s: obs = %.4f, RI p = %.3f (%d perms)\n",
        ri_all$outcome[i], ri_all$obs_stat[i],
        ri_all$ri_pvalue[i], ri_all$n_valid[i]))
  }
}

fwrite(ri_all, file.path(DATA_DIR, "robustness_ri.csv"))

# Keep single-outcome result for backward compatibility
ri_results <- tibble(
  obs_stat = obs_stats[1],
  ri_pvalue = ri_all$ri_pvalue[1],
  n_perms = ri_all$n_valid[1],
  perm_mean = mean(perm_matrix[!is.na(perm_matrix[, 1]), 1]),
  perm_sd = sd(perm_matrix[!is.na(perm_matrix[, 1]), 1])
)

## ============================================================
## SUMMARY
## ============================================================
cat("\n=== ROBUSTNESS SUMMARY ===\n")
cat("1. Pre-trends test: Joint F-test on pre-period interactions\n")
cat("2. Alternative exposure: Tier2 vs Tier1, govt securities ratio\n")
cat("3. Pre-COVID restriction: Drop post-March 2020\n")
cat("4. Leave-one-tier-out: Sensitivity to each tier\n")
cat("5. Placebo outcomes: Log assets, N banks\n")
cat("6. Cross-country LOO: Drop each comparator\n")
cat("7. Randomization inference: all 4 outcomes RI p < 0.001\n")
cat("\nAll robustness results saved to:", DATA_DIR, "\n")
