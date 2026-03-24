## 04_robustness.R — Robustness checks and placebos
## apep_0866: Male-biased labor demand, sex ratios, and women's outcomes

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

cat("=== Robustness Checks ===\n")

# =============================================================================
# 1. EVENT STUDY: Year-by-year triple-diff coefficients for pre-trends
# =============================================================================
cat("\n--- Event Study ---\n")

panel <- panel |>
  mutate(rel_year = year - 2006)

# Triple-diff event study: female x high_mining x year
panel <- panel |> mutate(fem_hm = female * as.integer(high_mining))

es1 <- feols(log_emp_nonmining ~ i(rel_year, fem_hm, ref = -1) +
               i(rel_year, I(as.integer(high_mining)), ref = -1) +
               i(rel_year, female, ref = -1) |
               fips + year,
             data = panel,
             cluster = ~state)

# Extract female x high_mining x year coefficients
es_coefs <- broom::tidy(es1) |>
  filter(grepl("fem_hm", term))
cat("Event study coefficients (Female x HighMining x Year):\n")
print(es_coefs)

# =============================================================================
# 2. PLACEBO: Healthcare (NAICS 62) — female-dominated, no mining link
# =============================================================================
cat("\n--- Placebo: Healthcare (NAICS 62) ---\n")

qwi_df <- readRDS("../data/qwi_raw.rds")

healthcare <- qwi_df |>
  filter(industry == "62") |>
  group_by(fips, year, sex, state) |>
  summarise(emp_health = mean(Emp, na.rm = TRUE), .groups = "drop") |>
  mutate(log_emp_health = log(emp_health + 1))

shale <- panel |>
  select(fips, high_mining, treatment) |>
  distinct()

healthcare <- healthcare |>
  left_join(shale, by = "fips") |>
  filter(!is.na(high_mining)) |>
  mutate(
    female = as.integer(sex == 2),
    boom = as.integer(year >= 2006 & year <= 2014),
    bust = as.integer(year >= 2015 & year <= 2018)
  )

placebo_health <- feols(log_emp_health ~ female:high_mining:boom +
                          female:high_mining:bust +
                          female:boom + female:bust +
                          high_mining:boom + high_mining:bust |
                          fips + year,
                        data = healthcare,
                        cluster = ~state)

cat("Placebo (Healthcare):\n")
print(summary(placebo_health))

# =============================================================================
# 3. ALTERNATIVE CLUSTERING: County-level
# =============================================================================
cat("\n--- Alternative Clustering ---\n")

main_county_cluster <- feols(log_emp_nonmining ~ female:high_mining:boom +
                               female:high_mining:bust +
                               female:boom + female:bust +
                               high_mining:boom + high_mining:bust |
                               fips + year,
                             data = panel,
                             cluster = ~fips)

cat("County-clustered SEs:\n")
print(summary(main_county_cluster))

# =============================================================================
# 4. CONSTRUCTION (NAICS 23) — male-dominated, should show positive male effect
# =============================================================================
cat("\n--- Construction (NAICS 23) ---\n")

construction <- qwi_df |>
  filter(industry == "23") |>
  group_by(fips, year, sex, state) |>
  summarise(emp_constr = mean(Emp, na.rm = TRUE), .groups = "drop") |>
  mutate(log_emp_constr = log(emp_constr + 1))

construction <- construction |>
  left_join(shale, by = "fips") |>
  filter(!is.na(high_mining)) |>
  mutate(
    female = as.integer(sex == 2),
    boom = as.integer(year >= 2006 & year <= 2014),
    bust = as.integer(year >= 2015 & year <= 2018)
  )

constr_reg <- feols(log_emp_constr ~ female:high_mining:boom +
                      female:high_mining:bust +
                      female:boom + female:bust +
                      high_mining:boom + high_mining:bust |
                      fips + year,
                    data = construction,
                    cluster = ~state)

cat("Construction:\n")
print(summary(constr_reg))

# =============================================================================
# Save robustness results
# =============================================================================

rob_results <- list(
  event_study = es1,
  placebo_healthcare = placebo_health,
  county_cluster = main_county_cluster,
  construction = constr_reg
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
