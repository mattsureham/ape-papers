# 03_main_analysis.R — Main DiD analysis of the 2014 Uddannelseshjælp reform
source("00_packages.R")

benefit_rates <- readRDS("../data/clean_benefit_rates.rds")
employment <- readRDS("../data/clean_employment.rds")
activation <- readRDS("../data/clean_activation.rds")

# ══════════════════════════════════════════════════════════════════════
# 1. NATIONAL DiD: Cash benefit recipiency (25-29 vs 30-34)
# ══════════════════════════════════════════════════════════════════════
cat("=== MAIN ANALYSIS: National DiD on benefit recipiency ===\n")

# Focus on net unemployed cash benefit recipients (KT), both sexes
nat <- benefit_rates %>%
  filter(benefit_type == "Net unemployed recipients of social assistance",
         sex == "Total",
         age_group %in% c("25-29 years", "30-34 years"),
         !is.na(population)) %>%
  mutate(
    young = as.integer(age_group == "25-29 years"),
    post = as.integer(year >= 2014)
  )

cat(sprintf("National panel: %d obs, years %d-%d\n", nrow(nat), min(nat$year), max(nat$year)))

# Simple 2x2 DiD — HC1 standard errors (only 2 age groups, clustering unreliable)
did_simple <- feols(rate ~ young * post | age_group + year, data = nat, vcov = "HC1")
cat("\n--- Simple DiD (rate per 100 pop) ---\n")
summary(did_simple)

# Dynamic DiD with event-study coefficients
nat$event_time <- nat$year - 2014
nat$event_time_f <- factor(nat$event_time)
# Drop -1 as reference
nat$event_time_f <- relevel(nat$event_time_f, ref = "-1")

did_dynamic <- feols(rate ~ i(event_time_f, young, ref = "-1") | age_group + year,
                     data = nat)
cat("\n--- Dynamic DiD (event study) ---\n")
summary(did_dynamic)

# ══════════════════════════════════════════════════════════════════════
# 2. NATIONAL DiD: Other benefit types
# ══════════════════════════════════════════════════════════════════════
cat("\n=== DiD across benefit types ===\n")

# All benefit types, 25-29 vs 30-34, total sex
nat_all <- benefit_rates %>%
  filter(sex == "Total",
         age_group %in% c("25-29 years", "30-34 years"),
         !is.na(population)) %>%
  mutate(
    young = as.integer(age_group == "25-29 years"),
    post = as.integer(year >= 2014)
  )

results_by_type <- list()
for (bt in unique(nat_all$benefit_type)) {
  sub <- nat_all %>% filter(benefit_type == bt)
  if (nrow(sub) > 5) {
    m <- feols(rate ~ young * post | age_group + year, data = sub)
    results_by_type[[bt]] <- m
    cat(sprintf("  %s: coef=%.4f, se=%.4f, p=%.4f\n",
                bt, coef(m)["young:post"], se(m)["young:post"],
                pvalue(m)["young:post"]))
  }
}

# ══════════════════════════════════════════════════════════════════════
# 3. NATIONAL DiD by sex
# ══════════════════════════════════════════════════════════════════════
cat("\n=== DiD by sex ===\n")

nat_sex <- benefit_rates %>%
  filter(benefit_type == "Net unemployed recipients of social assistance",
         sex != "Total",
         age_group %in% c("25-29 years", "30-34 years"),
         !is.na(population)) %>%
  mutate(
    young = as.integer(age_group == "25-29 years"),
    post = as.integer(year >= 2014)
  )

did_male <- feols(rate ~ young * post | age_group + year,
                  data = nat_sex %>% filter(sex == "Men"), vcov = "HC1")
did_female <- feols(rate ~ young * post | age_group + year,
                    data = nat_sex %>% filter(sex == "Women"), vcov = "HC1")

cat("Men:\n"); summary(did_male)
cat("Women:\n"); summary(did_female)

# ══════════════════════════════════════════════════════════════════════
# 4. REGIONAL DiD: Employment rates (25-29 vs 30-34)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Regional DiD: Employment rates ===\n")

emp <- employment %>%
  filter(measure == "Employment rate",
         sex == "Total",
         age_group_clean %in% c("25-29", "30-34"),
         !is.na(value)) %>%
  mutate(
    young = as.integer(age_group_clean == "25-29"),
    post = as.integer(year >= 2014)
  )

cat(sprintf("Employment panel: %d obs, %d regions, years %d-%d\n",
            nrow(emp), n_distinct(emp$region), min(emp$year), max(emp$year)))

# Region-level DiD with region and year FE, cluster at region
did_emp <- feols(value ~ young * post | region + year, data = emp,
                 cluster = ~region)
cat("\n--- Employment rate DiD ---\n")
summary(did_emp)

# Dynamic employment DiD
emp$event_time <- emp$year - 2014
emp$event_time_f <- relevel(factor(emp$event_time), ref = "-1")

did_emp_dyn <- feols(value ~ i(event_time_f, young, ref = "-1") | region + year,
                     data = emp, cluster = ~region)
cat("\n--- Dynamic Employment DiD ---\n")
summary(did_emp_dyn)

# Employment by sex
emp_sex <- employment %>%
  filter(measure == "Employment rate",
         sex != "Total",
         age_group_clean %in% c("25-29", "30-34"),
         !is.na(value)) %>%
  mutate(
    young = as.integer(age_group_clean == "25-29"),
    post = as.integer(year >= 2014)
  )

did_emp_male <- feols(value ~ young * post | region + year,
                      data = emp_sex %>% filter(sex == "Men"),
                      cluster = ~region)
did_emp_female <- feols(value ~ young * post | region + year,
                        data = emp_sex %>% filter(sex == "Women"),
                        cluster = ~region)

# ══════════════════════════════════════════════════════════════════════
# 5. REGIONAL DiD: Activation programs
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Regional DiD: Activation programs ===\n")

act <- activation %>%
  filter(benefit_type == "Activation total",
         !is.na(value)) %>%
  mutate(
    young = as.integer(grepl("25-29", age_group)),
    post = as.integer(year >= 2014)
  )

did_act <- feols(value ~ young * post | region + year, data = act,
                 cluster = ~region)
cat("\n--- Activation DiD ---\n")
summary(did_act)

# ══════════════════════════════════════════════════════════════════════
# Save results
# ══════════════════════════════════════════════════════════════════════
# Extract coefficients and SEs for tables
extract <- function(m, param = "young:post") {
  list(coef = coef(m)[param], se = se(m)[param], pval = pvalue(m)[param],
       nobs = m$nobs)
}

saveRDS(list(
  did_simple = extract(did_simple),
  did_emp = extract(did_emp),
  did_emp_male = extract(did_emp_male),
  did_emp_female = extract(did_emp_female),
  did_male = extract(did_male),
  did_female = extract(did_female),
  did_act = extract(did_act)
), "../data/main_results.rds")

# Diagnostics for validator
n_treated_regions <- n_distinct(emp$region[emp$young == 1])
n_pre <- sum(unique(nat$year) < 2014)
n_obs <- nrow(emp)

jsonlite::write_json(list(
  n_treated = n_treated_regions,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nMain results and diagnostics saved.\n")
