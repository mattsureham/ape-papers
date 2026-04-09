# 04_robustness.R — Robustness checks
source("00_packages.R")

benefit_rates <- readRDS("../data/clean_benefit_rates.rds")
employment <- readRDS("../data/clean_employment.rds")

# ══════════════════════════════════════════════════════════════════════
# 1. Placebo: older age groups (35-39 vs 40-44)
# ══════════════════════════════════════════════════════════════════════
cat("=== Placebo: 35-39 vs 40-44 ===\n")

placebo_nat <- benefit_rates %>%
  filter(benefit_type == "Net unemployed recipients of social assistance",
         sex == "Total",
         age_group %in% c("35-39 years", "40-44 years"),
         !is.na(population)) %>%
  mutate(
    young = as.integer(age_group == "35-39 years"),
    post = as.integer(year >= 2014)
  )

placebo_did <- feols(rate ~ young * post | age_group + year, data = placebo_nat, vcov = "HC1")
cat("Placebo benefit DiD (35-39 vs 40-44):\n")
summary(placebo_did)

placebo_emp <- employment %>%
  filter(measure == "Employment rate",
         sex == "Total",
         age_group_clean %in% c("35-39", "30-34"),
         !is.na(value)) %>%
  mutate(
    young = as.integer(age_group_clean == "30-34"),
    post = as.integer(year >= 2014)
  )

placebo_emp_did <- feols(value ~ young * post | region + year, data = placebo_emp,
                         cluster = ~region)
cat("\nPlacebo employment DiD (30-34 vs 35-39):\n")
summary(placebo_emp_did)

# ══════════════════════════════════════════════════════════════════════
# 2. Triple-difference: 25-29 vs 30-34, men vs women
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Triple difference: age × post × sex ===\n")

nat_ddd <- benefit_rates %>%
  filter(benefit_type == "Net unemployed recipients of social assistance",
         sex != "Total",
         age_group %in% c("25-29 years", "30-34 years"),
         !is.na(population)) %>%
  mutate(
    young = as.integer(age_group == "25-29 years"),
    post = as.integer(year >= 2014),
    male = as.integer(sex == "Men")
  )

ddd <- feols(rate ~ young * post * male | age_group + year + sex, data = nat_ddd, vcov = "HC1")
cat("Triple-diff:\n")
summary(ddd)

# ══════════════════════════════════════════════════════════════════════
# 3. Pre-reform only (2008-2013 falsification)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Pre-reform falsification (placebo at 2011) ===\n")

pre_only <- benefit_rates %>%
  filter(benefit_type == "Net unemployed recipients of social assistance",
         sex == "Total",
         age_group %in% c("25-29 years", "30-34 years"),
         year >= 2008, year <= 2013,
         !is.na(population)) %>%
  mutate(
    young = as.integer(age_group == "25-29 years"),
    post_placebo = as.integer(year >= 2011)
  )

placebo_pre <- feols(rate ~ young * post_placebo | age_group + year, data = pre_only, vcov = "HC1")
cat("Placebo at 2011:\n")
summary(placebo_pre)

# ══════════════════════════════════════════════════════════════════════
# 4. Exclude 2020-2021 (COVID)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Excluding COVID years ===\n")

no_covid_emp <- employment %>%
  filter(measure == "Employment rate",
         sex == "Total",
         age_group_clean %in% c("25-29", "30-34"),
         !is.na(value),
         !(year %in% c(2020, 2021))) %>%
  mutate(
    young = as.integer(age_group_clean == "25-29"),
    post = as.integer(year >= 2014)
  )

did_no_covid <- feols(value ~ young * post | region + year, data = no_covid_emp,
                      cluster = ~region)
cat("Employment DiD excl. COVID:\n")
summary(did_no_covid)

# ══════════════════════════════════════════════════════════════════════
# Save robustness results
# ══════════════════════════════════════════════════════════════════════
extract <- function(m, param) {
  list(coef = coef(m)[param], se = se(m)[param], pval = pvalue(m)[param])
}
saveRDS(list(
  placebo_benefit = extract(placebo_did, "young:post"),
  placebo_employment = extract(placebo_emp_did, "young:post"),
  ddd = extract(ddd, "young:post:male"),
  placebo_pre = extract(placebo_pre, "young:post_placebo"),
  did_no_covid = extract(did_no_covid, "young:post")
), "../data/robustness_results.rds")

cat("\nRobustness results saved.\n")
