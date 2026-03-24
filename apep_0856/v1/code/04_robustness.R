# 04_robustness.R — Robustness checks
# apep_0856: Tipped MW Stability Paradox

source("code/00_packages.R")

# ============================================================
# 1. Load data
# ============================================================
county <- fread("data/county_panel.csv")
placebo <- fread("data/placebo_panel.csv")

county[, restaurant := 1L]
placebo[, restaurant := 0L]

common_cols <- c("fips_county", "statefip", "year", "quarter", "yq",
                 "race", "race_label", "black", "Emp", "earn_avg", "sep_rate",
                 "ofw", "tipped_mw", "log_tipped_mw", "tipped_ratio", "restaurant")

stack <- rbind(county[, ..common_cols], placebo[, ..common_cols])
stack[, county_race_ind := paste0(fips_county, "_", race, "_", restaurant)]
stack[, year_race_ind := paste0(year, "_", race, "_", restaurant)]

# ============================================================
# 2. Leave-one-out: Drop California (largest OFW state)
# ============================================================
stack_no_ca <- stack[statefip != 6L]

loo_earn <- feols(earn_avg ~ tipped_ratio:black:restaurant |
                    county_race_ind + year_race_ind,
                  data = stack_no_ca,
                  weights = ~Emp,
                  cluster = ~statefip)

loo_sep <- feols(sep_rate ~ tipped_ratio:black:restaurant |
                   county_race_ind + year_race_ind,
                 data = stack_no_ca,
                 weights = ~Emp,
                 cluster = ~statefip)

cat("\n=== Leave-One-Out: Drop CA ===\n")
cat("Earnings:\n"); print(summary(loo_earn))
cat("Separation:\n"); print(summary(loo_sep))

# ============================================================
# 3. Alternative clustering: State × Year
# ============================================================
alt_earn <- feols(earn_avg ~ tipped_ratio:black:restaurant |
                    county_race_ind + year_race_ind,
                  data = stack,
                  weights = ~Emp,
                  cluster = ~statefip^year)

alt_sep <- feols(sep_rate ~ tipped_ratio:black:restaurant |
                   county_race_ind + year_race_ind,
                 data = stack,
                 weights = ~Emp,
                 cluster = ~statefip^year)

cat("\n=== Alternative Clustering: State × Year ===\n")
cat("Earnings:\n"); print(summary(alt_earn))
cat("Separation:\n"); print(summary(alt_sep))

# ============================================================
# 4. Drop COVID period (2020-2021)
# ============================================================
stack_no_covid <- stack[!(year %in% c(2020, 2021))]

cov_earn <- feols(earn_avg ~ tipped_ratio:black:restaurant |
                    county_race_ind + year_race_ind,
                  data = stack_no_covid,
                  weights = ~Emp,
                  cluster = ~statefip)

cov_sep <- feols(sep_rate ~ tipped_ratio:black:restaurant |
                   county_race_ind + year_race_ind,
                 data = stack_no_covid,
                 weights = ~Emp,
                 cluster = ~statefip)

cat("\n=== Drop COVID (2020-2021) ===\n")
cat("Earnings:\n"); print(summary(cov_earn))
cat("Separation:\n"); print(summary(cov_sep))

# ============================================================
# 5. Unweighted regression
# ============================================================
uw_earn <- feols(earn_avg ~ tipped_ratio:black:restaurant |
                   county_race_ind + year_race_ind,
                 data = stack,
                 cluster = ~statefip)

uw_sep <- feols(sep_rate ~ tipped_ratio:black:restaurant |
                  county_race_ind + year_race_ind,
                data = stack,
                cluster = ~statefip)

cat("\n=== Unweighted ===\n")
cat("Earnings:\n"); print(summary(uw_earn))
cat("Separation:\n"); print(summary(uw_sep))

# ============================================================
# 6. Save results
# ============================================================

rob <- list(
  loo_earn = loo_earn, loo_sep = loo_sep,
  alt_earn = alt_earn, alt_sep = alt_sep,
  cov_earn = cov_earn, cov_sep = cov_sep,
  uw_earn = uw_earn, uw_sep = uw_sep
)

saveRDS(rob, "data/robustness_results.rds")
cat("\nRobustness results saved.\n")
