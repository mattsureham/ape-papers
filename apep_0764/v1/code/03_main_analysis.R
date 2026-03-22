# 03_main_analysis.R — Main regressions
# apep_0764: Brazil Intermittent Contracts

source("00_packages.R")

cat("Loading clean panel...\n")
panel <- fread("../data/panel_clean.csv")
panel[, muni_code := as.character(muni_code)]
panel[, state_code := as.character(state_code)]

# =============================================================================
# 1. MAIN SPECIFICATION: BARTIK DiD
# =============================================================================
cat("Running main specifications...\n")

# 1a. Log average wage
m1_wage <- feols(log_avg_wage ~ bartik_exposure:post |
                   muni_code + year,
                 data = panel,
                 cluster = ~state_code,
                 weights = ~total_emp_2016)

cat("\n=== Model 1: Log Average Wage ===\n")
print(summary(m1_wage))

# 1b. Log total formal employment
m2_emp <- feols(log_employment ~ bartik_exposure:post |
                  muni_code + year,
                data = panel,
                cluster = ~state_code,
                weights = ~total_emp_2016)

cat("\n=== Model 2: Log Formal Employment ===\n")
print(summary(m2_emp))

# 1c. Intermittent share
m3_intermittent <- feols(intermittent_share ~ bartik_exposure:post |
                           muni_code + year,
                         data = panel,
                         cluster = ~state_code,
                         weights = ~total_emp_2016)

cat("\n=== Model 3: Intermittent Share ===\n")
print(summary(m3_intermittent))

# 1d. Average contracted hours
m4_hours <- feols(avg_hours ~ bartik_exposure:post |
                    muni_code + year,
                  data = panel,
                  cluster = ~state_code,
                  weights = ~total_emp_2016)

cat("\n=== Model 4: Average Contracted Hours ===\n")
print(summary(m4_hours))

# =============================================================================
# 2. PREFERRED SPECIFICATION: WITH MUNICIPALITY-SPECIFIC LINEAR TRENDS
# =============================================================================
cat("\nRunning preferred specifications (with municipality linear trends)...\n")

panel[, year_int := as.integer(year)]

# The naive DiD has pre-trend violations. Municipality-specific linear trends
# absorb differential pre-reform trajectories correlated with sector composition.

m1t_wage <- feols(log_avg_wage ~ bartik_exposure:post |
                    muni_code[year_int] + year,
                  data = panel,
                  cluster = ~state_code,
                  weights = ~total_emp_2016)

cat("\n=== Preferred Model 1: Log Average Wage (with trends) ===\n")
print(summary(m1t_wage))

m2t_emp <- feols(log_employment ~ bartik_exposure:post |
                   muni_code[year_int] + year,
                 data = panel,
                 cluster = ~state_code,
                 weights = ~total_emp_2016)

cat("\n=== Preferred Model 2: Log Formal Employment (with trends) ===\n")
print(summary(m2t_emp))

m4t_hours <- feols(avg_hours ~ bartik_exposure:post |
                     muni_code[year_int] + year,
                   data = panel,
                   cluster = ~state_code,
                   weights = ~total_emp_2016)

cat("\n=== Preferred Model 4: Average Hours (with trends) ===\n")
print(summary(m4t_hours))

# =============================================================================
# 3. EVENT STUDY (WITH TRENDS — PREFERRED)
# =============================================================================
cat("\nRunning event study with municipality trends...\n")

es1_wage <- feols(log_avg_wage ~ i(year_int, bartik_exposure, ref = 2017) |
                    muni_code[year_int] + year,
                  data = panel,
                  cluster = ~state_code,
                  weights = ~total_emp_2016)

cat("\n=== Event Study: Log Wage (with trends) ===\n")
print(summary(es1_wage))

es2_emp <- feols(log_employment ~ i(year_int, bartik_exposure, ref = 2017) |
                   muni_code[year_int] + year,
                 data = panel,
                 cluster = ~state_code,
                 weights = ~total_emp_2016)

cat("\n=== Event Study: Log Employment (with trends) ===\n")
print(summary(es2_emp))

es3_hours <- feols(avg_hours ~ i(year_int, bartik_exposure, ref = 2017) |
                     muni_code[year_int] + year,
                   data = panel,
                   cluster = ~state_code,
                   weights = ~total_emp_2016)

cat("\n=== Event Study: Average Hours (with trends) ===\n")
print(summary(es3_hours))

# =============================================================================
# 4. SAVE RESULTS
# =============================================================================
saveRDS(list(
  # Naive (no trends)
  m1_wage = m1_wage,
  m2_emp = m2_emp,
  m3_intermittent = m3_intermittent,
  m4_hours = m4_hours,
  # Preferred (with trends)
  m1t_wage = m1t_wage,
  m2t_emp = m2t_emp,
  m4t_hours = m4t_hours,
  # Event studies (with trends)
  es1_wage = es1_wage,
  es2_emp = es2_emp,
  es3_hours = es3_hours
), "../data/main_results.rds")

# Write diagnostics.json for validate_v1.py
pre_data <- panel[year <= 2017]
n_treated <- uniqueN(panel$muni_code[panel$bartik_exposure > median(panel$bartik_exposure)])
n_pre <- length(unique(panel$year[panel$year < 2018]))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(panel)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nMain analysis complete. Results saved.\n")
cat(sprintf("  n_treated (above-median exposure): %d\n", n_treated))
cat(sprintf("  n_pre: %d\n", n_pre))
cat(sprintf("  n_obs: %d\n", nrow(panel)))
