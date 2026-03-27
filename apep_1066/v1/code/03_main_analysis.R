## 03_main_analysis.R — Main DDD regressions for CROWN Act
## apep_1066 v1

source("00_packages.R")
load("../data/analysis_panel.RData")

## ============================================================
## 1. SUMMARY STATISTICS TABLE
## ============================================================

## Pre-treatment means by race × sex
pre_treat <- panel %>% filter(year < 2019)

sumstats <- pre_treat %>%
  group_by(race, sex) %>%
  summarise(
    mean_earn = mean(median_earnings, na.rm = TRUE),
    sd_earn = sd(median_earnings, na.rm = TRUE),
    mean_emp = mean(emp_rate, na.rm = TRUE),
    sd_emp = sd(emp_rate, na.rm = TRUE),
    n_states = n_distinct(state_fips),
    .groups = "drop"
  )

cat("\n=== Pre-treatment Summary Statistics (2017-2018) ===\n")
print(sumstats)

## ============================================================
## 2. MAIN DDD: CROWN × Black (DiD) + additional Black × Female
## ============================================================

## --- Model 1: DiD on log earnings (CROWN × Black) ---
## State × Race FE + Year × Race FE + State × Year FE
m1_earn <- feols(
  log_earn ~ crown_black |
    state_fips^race + year^race + state_fips^year,
  data = panel,
  cluster = ~state_fips
)

## --- Model 2: Add female interaction ---
m2_earn <- feols(
  log_earn ~ crown_black + crown_active:female + crown_black:female |
    state_fips^race + year^race + state_fips^year + sex,
  data = panel,
  cluster = ~state_fips
)

## --- Model 3: Employment rate DDD ---
m3_emp <- feols(
  emp_rate ~ crown_black |
    state_fips^race + year^race + state_fips^year,
  data = panel,
  cluster = ~state_fips
)

## --- Model 4: Employment with female interaction ---
m4_emp <- feols(
  emp_rate ~ crown_black + crown_active:female + crown_black:female |
    state_fips^race + year^race + state_fips^year + sex,
  data = panel,
  cluster = ~state_fips
)

cat("\n=== Main DDD Results ===\n")
cat("\n--- Log Earnings ---\n")
summary(m1_earn)
summary(m2_earn)
cat("\n--- Employment Rate ---\n")
summary(m3_emp)
summary(m4_emp)

## ============================================================
## 3. CALLAWAY-SANT'ANNA EVENT STUDY (Black workers only)
## ============================================================

## Focus on Black workers for CS — the treated demographic
black_panel <- panel %>%
  filter(race == "Black") %>%
  ## Aggregate across sex for state-level Black outcomes
  group_by(state_fips, state_name, year, first_treat, state_id) %>%
  summarise(
    log_earn = mean(log_earn, na.rm = TRUE),
    emp_rate = mean(emp_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    ## CS requires integer time and first_treat = 0 for never-treated
    first_treat_cs = as.integer(first_treat)
  )

## CS for log earnings
cs_earn <- att_gt(
  yname = "log_earn",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_cs",
  data = black_panel,
  control_group = "nevertreated",
  base_period = "universal"
)

## Dynamic aggregation (event study)
es_earn <- aggte(cs_earn, type = "dynamic")

cat("\n=== Callaway-Sant'Anna Event Study (Black Log Earnings) ===\n")
summary(es_earn)

## CS for employment rate
cs_emp <- att_gt(
  yname = "emp_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_cs",
  data = black_panel,
  control_group = "nevertreated",
  base_period = "universal"
)

es_emp <- aggte(cs_emp, type = "dynamic")

cat("\n=== Callaway-Sant'Anna Event Study (Black Employment Rate) ===\n")
summary(es_emp)

## Overall ATT
att_earn <- aggte(cs_earn, type = "simple")
att_emp <- aggte(cs_emp, type = "simple")

cat("\n=== Overall ATT (CS) ===\n")
cat(sprintf("Log Earnings ATT: %.4f (SE: %.4f)\n", att_earn$overall.att, att_earn$overall.se))
cat(sprintf("Employment ATT: %.4f (SE: %.4f)\n", att_emp$overall.att, att_emp$overall.se))

## ============================================================
## 4. SAVE RESULTS
## ============================================================

## Compute SD(Y) for SDE calculations (pre-treatment Black outcomes)
pre_black <- panel %>% filter(year < 2019, race == "Black")
sd_log_earn <- sd(pre_black$log_earn, na.rm = TRUE)
sd_emp_rate <- sd(pre_black$emp_rate, na.rm = TRUE)

cat(sprintf("\nSD(log_earn) pre-treatment: %.4f\n", sd_log_earn))
cat(sprintf("SD(emp_rate) pre-treatment: %.4f\n", sd_emp_rate))

## Write diagnostics.json for validator
diagnostics <- list(
  n_treated = n_distinct(panel$state_fips[panel$ever_treated]),
  n_pre = length(unique(panel$year[panel$year < 2019])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics written to data/diagnostics.json\n")

## Save all results
save(m1_earn, m2_earn, m3_emp, m4_emp,
     cs_earn, cs_emp, es_earn, es_emp, att_earn, att_emp,
     sumstats, sd_log_earn, sd_emp_rate, black_panel,
     pre_treat,
     file = "../data/results.RData")
cat("Results saved to data/results.RData\n")
