## 03_main_analysis.R — Primary regressions
## apep_0866: Male-biased labor demand, sex ratios, and women's outcomes

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

cat(sprintf("Panel loaded: %d rows, %d counties\n", nrow(panel), n_distinct(panel$fips)))

# =============================================================================
# 1. FIRST STAGE: Mining employment response by sex (continuous treatment)
# =============================================================================
cat("\n=== First Stage: Mining Employment ===\n")

# Continuous treatment: pre-boom mining share
fs_male <- feols(log_emp_mining ~ treatment:boom + treatment:bust |
                   fips + year,
                 data = panel |> filter(sex == 1),
                 cluster = ~state)

fs_female <- feols(log_emp_mining ~ treatment:boom + treatment:bust |
                     fips + year,
                   data = panel |> filter(sex == 2),
                   cluster = ~state)

cat("Male mining employment:\n")
print(summary(fs_male))
cat("\nFemale mining employment:\n")
print(summary(fs_female))

# =============================================================================
# 2. MAIN RESULT: Triple-difference on non-mining employment
# =============================================================================
cat("\n=== Main Result: Non-Mining Employment ===\n")

# Binary treatment triple-diff
main_emp <- feols(log_emp_nonmining ~ female:high_mining:boom +
                    female:high_mining:bust +
                    female:boom + female:bust +
                    high_mining:boom + high_mining:bust |
                    fips + year,
                  data = panel,
                  cluster = ~state)

cat("Triple-diff Employment:\n")
print(summary(main_emp))

# =============================================================================
# 3. EARNINGS: Triple-difference on non-mining earnings
# =============================================================================
cat("\n=== Earnings ===\n")

main_earn <- feols(log_earnings_nonmining ~ female:high_mining:boom +
                     female:high_mining:bust +
                     female:boom + female:bust +
                     high_mining:boom + high_mining:bust |
                     fips + year,
                   data = panel,
                   cluster = ~state)

cat("Triple-diff Earnings:\n")
print(summary(main_earn))

# =============================================================================
# 4. CONTINUOUS TREATMENT: Dose-response
# =============================================================================
cat("\n=== Continuous Treatment ===\n")

cont_emp <- feols(log_emp_nonmining ~ female:treatment:boom +
                    female:treatment:bust +
                    female:boom + female:bust +
                    treatment:boom + treatment:bust |
                    fips + year,
                  data = panel,
                  cluster = ~state)

cont_earn <- feols(log_earnings_nonmining ~ female:treatment:boom +
                     female:treatment:bust +
                     female:boom + female:bust +
                     treatment:boom + treatment:bust |
                     fips + year,
                   data = panel,
                   cluster = ~state)

cat("Continuous treatment - Employment:\n")
print(summary(cont_emp))
cat("\nContinuous treatment - Earnings:\n")
print(summary(cont_earn))

# =============================================================================
# 5. GENDER EARNINGS GAP (county-year level, continuous treatment)
# =============================================================================
cat("\n=== Gender Earnings Gap ===\n")

gap_panel <- panel |>
  filter(sex == 1) |>
  select(fips, year, gender_earn_gap, treatment, boom, bust, state) |>
  filter(!is.na(gender_earn_gap))

gap1 <- feols(gender_earn_gap ~ treatment:boom + treatment:bust |
                fips + year,
              data = gap_panel,
              cluster = ~state)

cat("Gender earnings gap response:\n")
print(summary(gap1))

# =============================================================================
# 6. Save results
# =============================================================================

results <- list(
  first_stage_male = fs_male,
  first_stage_female = fs_female,
  main_employment = main_emp,
  main_earnings = main_earn,
  continuous_employment = cont_emp,
  continuous_earnings = cont_earn,
  gender_gap = gap1
)

saveRDS(results, "../data/main_results.rds")

# Write diagnostics
n_treated <- n_distinct(panel$fips[panel$high_mining == TRUE])
n_pre <- length(unique(panel$year[panel$year < 2006]))
n_obs <- nrow(panel)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))
cat("Main results saved.\n")
