## ============================================================
## 03_main_analysis.R — Primary regressions
## Cap On, Cap Off: Kenya's Interest Rate Ceiling (2016-2019)
## ============================================================

source("00_packages.R")

## --- Load Cleaned Data ---
tier_panel <- fread(file.path(DATA_DIR, "tier_panel_clean.csv"))
cc_all     <- fread(file.path(DATA_DIR, "cross_country_clean.csv"))

## ============================================================
## ANALYSIS 1: Tier-Level DiD — Differential Impact by Bank Tier
## ============================================================
cat("=== ANALYSIS 1: Tier-Level DiD ===\n\n")

# Primary specification: Tier × Period interaction
# Outcome: loan/asset ratio (credit allocation)
# Treatment: Tier 3 (most exposed) vs Tier 1 (least exposed)

# Create interaction terms
tier_panel <- tier_panel |>
  mutate(
    is_tier3 = as.integer(tier == "Tier3"),
    is_tier2 = as.integer(tier == "Tier2"),
    # Continuous exposure × period
    exposure_cap = exposure * cap_on,
    exposure_repeal = exposure * repeal,
    # Year as factor for event study
    year_factor = factor(year)
  )

# --- Model 1a: Simple DiD (Tier 3 vs others, cap vs pre) ---
m1a <- feols(loan_asset_ratio ~ is_tier3:cap_on + is_tier3:repeal |
               tier + year,
             data = tier_panel, cluster = ~tier)

# --- Model 1b: Continuous exposure DiD ---
m1b <- feols(loan_asset_ratio ~ exposure_cap + exposure_repeal |
               tier + year,
             data = tier_panel, cluster = ~tier)

# --- Model 1c: Government securities share (portfolio substitution) ---
m1c <- feols(govt_sec_ratio ~ is_tier3:cap_on + is_tier3:repeal |
               tier + year,
             data = tier_panel, cluster = ~tier)

# --- Model 1d: NPL ratio (credit quality) ---
m1d <- feols(npl_ratio ~ is_tier3:cap_on + is_tier3:repeal |
               tier + year,
             data = tier_panel, cluster = ~tier)

# --- Model 1e: Log loans (credit volume) ---
m1e <- feols(log_loans ~ is_tier3:cap_on + is_tier3:repeal |
               tier + year,
             data = tier_panel, cluster = ~tier)

cat("Model 1a: Loan/Asset Ratio DiD\n")
print(summary(m1a))

cat("\nModel 1c: Govt Securities Ratio DiD\n")
print(summary(m1c))

cat("\nModel 1d: NPL Ratio DiD\n")
print(summary(m1d))

# Save main results
main_results <- tibble(
  model = c("1a", "1b", "1c", "1d", "1e"),
  outcome = c("Loan/Asset Ratio", "Loan/Asset (continuous)",
              "Govt Sec Ratio", "NPL Ratio", "Log Loans"),
  specification = c("Tier3 dummy", "Continuous exposure",
                     "Tier3 dummy", "Tier3 dummy", "Tier3 dummy")
)

# Extract coefficients
extract_coefs <- function(model, name) {
  ct <- coeftable(model)
  tibble(
    model = name,
    term = rownames(ct),
    estimate = ct[, 1],
    std_error = ct[, 2],
    t_value = ct[, 3],
    p_value = ct[, 4]
  )
}

all_coefs <- bind_rows(
  extract_coefs(m1a, "Loan/Asset (Tier DiD)"),
  extract_coefs(m1b, "Loan/Asset (Continuous)"),
  extract_coefs(m1c, "Govt Sec Ratio"),
  extract_coefs(m1d, "NPL Ratio"),
  extract_coefs(m1e, "Log Loans")
)

fwrite(all_coefs, file.path(DATA_DIR, "main_results_tier.csv"))

## ============================================================
## ANALYSIS 1B: Event Study — Tier 3 vs Tier 1 by Year
## ============================================================
cat("\n=== Event Study: Tier × Year Interactions ===\n")

# Create year interactions (omit 2015 as base)
tier_panel <- tier_panel |>
  mutate(
    # Event time relative to 2016 (partial cap year)
    event_time = year - 2016,
    # Tier3 × year dummies (omit 2015 = event_time -1)
    et = event_time
  )

# Event study: Tier 3 × year dummies
es_model_loan <- feols(loan_asset_ratio ~ i(et, is_tier3, ref = -1) |
                          tier + year,
                        data = tier_panel, cluster = ~tier)

es_model_govt <- feols(govt_sec_ratio ~ i(et, is_tier3, ref = -1) |
                         tier + year,
                       data = tier_panel, cluster = ~tier)

es_model_npl <- feols(npl_ratio ~ i(et, is_tier3, ref = -1) |
                        tier + year,
                      data = tier_panel, cluster = ~tier)

cat("Event Study — Loan/Asset Ratio:\n")
print(summary(es_model_loan))

# Extract event study coefficients for plotting
extract_es <- function(model, outcome_name) {
  ct <- coeftable(model)
  terms <- rownames(ct)
  # Parse event time from term names
  et_vals <- as.numeric(gsub(".*::([-0-9]+):.*", "\\1", terms))
  tibble(
    outcome = outcome_name,
    event_time = et_vals,
    estimate = ct[, 1],
    se = ct[, 2],
    ci_lower = ct[, 1] - 1.96 * ct[, 2],
    ci_upper = ct[, 1] + 1.96 * ct[, 2],
    p_value = ct[, 4]
  )
}

es_coefs <- bind_rows(
  extract_es(es_model_loan, "Loan/Asset Ratio"),
  extract_es(es_model_govt, "Govt Securities Ratio"),
  extract_es(es_model_npl, "NPL Ratio")
)

fwrite(es_coefs, file.path(DATA_DIR, "event_study_tier.csv"))

## ============================================================
## ANALYSIS 2: Cross-Country DiD — Kenya vs East Africa
## ============================================================
cat("\n=== ANALYSIS 2: Cross-Country DiD ===\n\n")

# Kenya (treated) vs Uganda, Tanzania, Rwanda (controls)
# Outcome: Credit/GDP, Lending Rate, NPL Ratio

# --- Model 2a: Credit/GDP ---
m2a <- feols(credit_gdp ~ treated:cap_on + treated:repeal |
               country + year,
             data = cc_all |> filter(!is.na(credit_gdp)),
             cluster = ~country)

# --- Model 2b: Lending Rate ---
m2b <- feols(lending_rate ~ treated:cap_on + treated:repeal |
               country + year,
             data = cc_all |> filter(!is.na(lending_rate)),
             cluster = ~country)

# --- Model 2c: NPL Ratio ---
m2c <- feols(npl_ratio ~ treated:cap_on + treated:repeal |
               country + year,
             data = cc_all |> filter(!is.na(npl_ratio)),
             cluster = ~country)

cat("Model 2a: Credit/GDP\n")
print(summary(m2a))

cat("\nModel 2b: Lending Rate\n")
print(summary(m2b))

cat("\nModel 2c: NPL Ratio\n")
print(summary(m2c))

# Cross-country event study
cc_all <- cc_all |>
  mutate(et_cc = year - 2017)

es_cc_credit <- feols(credit_gdp ~ i(et_cc, treated, ref = -1) |
                        country + year,
                      data = cc_all |> filter(!is.na(credit_gdp)),
                      cluster = ~country)

es_cc_rate <- feols(lending_rate ~ i(et_cc, treated, ref = -1) |
                      country + year,
                    data = cc_all |> filter(!is.na(lending_rate)),
                    cluster = ~country)

# Extract cross-country event study
es_cc_coefs <- bind_rows(
  extract_es(es_cc_credit, "Credit/GDP (Cross-Country)"),
  extract_es(es_cc_rate, "Lending Rate (Cross-Country)")
)

fwrite(es_cc_coefs, file.path(DATA_DIR, "event_study_cc.csv"))

# Save cross-country results
cc_coefs <- bind_rows(
  extract_coefs(m2a, "Credit/GDP"),
  extract_coefs(m2b, "Lending Rate"),
  extract_coefs(m2c, "NPL Ratio")
)

fwrite(cc_coefs, file.path(DATA_DIR, "main_results_cc.csv"))

## ============================================================
## ANALYSIS 3: Symmetry Test — Does Repeal Reverse the Cap?
## ============================================================
cat("\n=== ANALYSIS 3: Symmetry Test ===\n\n")

# Key test: β_repeal ≈ -β_cap would imply full reversal
# β_repeal ≈ 0 would imply hysteresis (irreversible)

# For tier-level analysis
symmetry_tier <- tier_panel |>
  filter(year >= 2015) |>
  mutate(
    # Create period dummies relative to 2015
    post_cap = as.integer(year >= 2017 & year <= 2019),
    post_repeal = as.integer(year >= 2020)
  )

# Test symmetry for each outcome
sym_loan <- feols(loan_asset_ratio ~ is_tier3:post_cap + is_tier3:post_repeal |
                    tier + year,
                  data = symmetry_tier, cluster = ~tier)

cat("Symmetry Test — Loan/Asset Ratio:\n")
ct_sym <- coeftable(sym_loan)
cat("  Cap effect (Tier3 × Cap):", round(ct_sym[1, 1], 4), "\n")
cat("  Repeal effect (Tier3 × Repeal):", round(ct_sym[2, 1], 4), "\n")

# Wald test: β_cap + β_repeal = 0 (full reversal)
cat("\n  If β_repeal ≈ -β_cap → full reversal\n")
cat("  If β_repeal ≈ 0 → hysteresis\n")
cat("  Sum of coefficients:", round(ct_sym[1, 1] + ct_sym[2, 1], 4), "\n")

symmetry_results <- tibble(
  outcome = "Loan/Asset Ratio",
  beta_cap = ct_sym[1, 1],
  se_cap = ct_sym[1, 2],
  beta_repeal = ct_sym[2, 1],
  se_repeal = ct_sym[2, 2],
  sum_betas = ct_sym[1, 1] + ct_sym[2, 1],
  reversal_pct = ifelse(ct_sym[1, 1] != 0,
                        -ct_sym[2, 1] / ct_sym[1, 1] * 100, NA)
)

cat("  Reversal percentage:", round(symmetry_results$reversal_pct, 1), "%\n")

fwrite(symmetry_results, file.path(DATA_DIR, "symmetry_test.csv"))

## ============================================================
## SUMMARY
## ============================================================
cat("\n=== ANALYSIS SUMMARY ===\n")
cat("Tier-level regressions: 5 specifications\n")
cat("Event studies: 3 outcomes (loan ratio, govt sec, NPL)\n")
cat("Cross-country DiD: 3 outcomes (credit/GDP, lending rate, NPL)\n")
cat("Symmetry test: 1 (hysteresis vs reversal)\n")
cat("\nAll results saved to:", DATA_DIR, "\n")
