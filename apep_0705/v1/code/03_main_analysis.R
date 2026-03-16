## 03_main_analysis.R — Dose-response DiD: RUT deduction and formalization
## APEP-0705: Sweden's RUT Household Services Deduction

source("00_packages.R")

data_dir <- "../data"

## Load panels
panel        <- readRDS(file.path(data_dir, "panel_income.rds"))
emp_panel    <- readRDS(file.path(data_dir, "panel_employment.rds"))
emp_sex      <- readRDS(file.path(data_dir, "panel_emp_sex.rds"))
emprate_panel <- readRDS(file.path(data_dir, "panel_emprate.rds"))

## Drop NAs in outcome
panel <- panel %>% filter(!is.na(mean_income), mean_income > 0)
cat("Analysis panel:", nrow(panel), "obs,", n_distinct(panel$region), "municipalities\n")

## ============================================================
## 1. EVENT STUDY: Income x Treatment Intensity
## ============================================================
cat("\n=== Event Study: Log Mean Income ===\n")

# Create year dummies interacted with treatment intensity
# Reference year = 2006 (last pre-reform year)
panel <- panel %>%
  mutate(
    rel_year = year - 2007,  # -8 to +17
    year_factor = relevel(factor(year), ref = "2006")
  )

# Event study regression: municipality + year FE
es_model <- feols(
  log_mean_income ~ i(year, treat_intensity, ref = 2006) | region + year,
  data = panel,
  cluster = ~region
)

cat("Event study coefficients (pre-reform should be ~0):\n")
es_coefs <- coeftable(es_model)
# Show pre-reform coefficients
pre_coefs <- es_coefs[grepl("year::(1999|200[0-5])", rownames(es_coefs)), ]
cat("Pre-reform coefficients:\n")
print(round(pre_coefs, 4))
cat("\nPost-reform coefficients (first 5 years):\n")
post_coefs <- es_coefs[grepl("year::(200[7-9]|201[01])", rownames(es_coefs)), ]
print(round(post_coefs, 4))

## ============================================================
## 2. MAIN DiD: Aggregate effect
## ============================================================
cat("\n=== Main DiD: Log Mean Income ===\n")

# Specification 1: Simple post x treatment intensity
did_1 <- feols(
  log_mean_income ~ treat_x_post | region + year,
  data = panel,
  cluster = ~region
)

# Specification 2: Allow time-varying effect (early vs late post)
panel <- panel %>%
  mutate(
    early_post = as.integer(year >= 2007 & year <= 2012),
    late_post  = as.integer(year >= 2013),
    treat_x_early = treat_intensity * early_post,
    treat_x_late  = treat_intensity * late_post
  )

did_2 <- feols(
  log_mean_income ~ treat_x_early + treat_x_late | region + year,
  data = panel,
  cluster = ~region
)

# Specification 3: Controlling for population
did_3 <- feols(
  log_mean_income ~ treat_x_post + log(n_persons) | region + year,
  data = panel %>% filter(!is.na(n_persons), n_persons > 0),
  cluster = ~region
)

cat("\nSpec 1 (aggregate post):\n")
print(summary(did_1))

cat("\nSpec 2 (early vs late post):\n")
print(summary(did_2))

## ============================================================
## 3. EMPLOYMENT MECHANISM: M+N sector
## ============================================================
cat("\n=== Employment Mechanism: M+N Sector ===\n")

# M+N sector label
mn_label <- unique(emp_panel$sector)[grepl("professional", unique(emp_panel$sector))]
mfg_label <- unique(emp_panel$sector)[grepl("mining", unique(emp_panel$sector))]

# M+N employment grows more in high-treatment municipalities
mn_panel <- emp_panel %>% filter(sector == mn_label, emp > 0)

emp_did <- feols(
  log_emp ~ treat_intensity:i(year, ref = 2008) | region + year,
  data = mn_panel,
  cluster = ~region
)

cat("M+N employment x treatment intensity (2008-2018, ref=2008):\n")
print(summary(emp_did))

## ============================================================
## 4. PLACEBO: Manufacturing (B+C) sector
## ============================================================
cat("\n=== Placebo: Manufacturing Employment ===\n")

mfg_panel <- emp_panel %>% filter(sector == mfg_label, emp > 0)

placebo_did <- feols(
  log_emp ~ treat_intensity:i(year, ref = 2008) | region + year,
  data = mfg_panel,
  cluster = ~region
)

cat("Manufacturing employment x treatment intensity (placebo):\n")
print(summary(placebo_did))

## ============================================================
## 5. GENDER CHANNEL: Female vs Male in M+N
## ============================================================
cat("\n=== Gender Channel: M+N Employment ===\n")

gender_did <- feols(
  log_emp ~ treat_intensity:female:i(year, ref = 2008) +
            treat_intensity:i(year, ref = 2008) | region^sex + year^sex,
  data = emp_sex %>% filter(emp > 0),
  cluster = ~region
)

# Simpler version: just female vs male slopes
gender_simple <- feols(
  log_emp ~ treat_intensity:female + treat_intensity | region + year + sex,
  data = emp_sex %>% filter(emp > 0, year >= 2008),
  cluster = ~region
)

cat("Gender interaction (M+N):\n")
print(summary(gender_simple))

## ============================================================
## 6. IMMIGRATION CHANNEL: Employment rate DiD
## ============================================================
cat("\n=== Immigration Channel: Employment Rate ===\n")

# DDD: Treatment intensity x Post x Foreign-born
imm_did <- feols(
  emp_rate ~ treat_x_post_x_fb + treat_x_post +
             treat_intensity:foreign_born + post:foreign_born |
             region + year,
  data = emprate_panel %>% filter(!is.na(emp_rate)),
  cluster = ~region
)

cat("Immigration DDD (treatment x post x foreign-born):\n")
print(summary(imm_did))

## ============================================================
## SAVE RESULTS
## ============================================================
results <- list(
  event_study = es_model,
  did_aggregate = did_1,
  did_early_late = did_2,
  did_population = did_3,
  emp_mn = emp_did,
  placebo_mfg = placebo_did,
  gender = gender_simple,
  immigration = imm_did
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

## ============================================================
## DIAGNOSTICS (for validator)
## ============================================================
diagnostics <- list(
  n_treated = n_distinct(panel$region),  # All treated (continuous intensity)
  n_pre = sum(panel$year < 2007) / n_distinct(panel$region),
  n_obs = nrow(panel),
  n_municipalities = n_distinct(panel$region),
  n_years = n_distinct(panel$year),
  treatment_type = "continuous_intensity",
  reform_year = 2007
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat("Results saved to data/main_results.rds\n")
cat("Diagnostics saved to data/diagnostics.json\n")
