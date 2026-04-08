## 03_main_analysis.R — Primary DiD estimation
## apep_1419: UK Auto-Enrollment Contribution Step-Up and Wages

source("00_packages.R")
data_dir <- "../data"
load(file.path(data_dir, "analysis_panel.RData"))

## ========================================================================
## 1. Main specification: Continuous treatment DiD
## ========================================================================
cat("=== Main DiD: log annual pay ~ small_share × post ===\n")

# Primary: LA and year FE, continuous treatment
m1 <- feols(log_annual_pay ~ treat_intensity:post | la_code + year,
            data = panel_bal, cluster = ~la_code)

# With separate pre/post coefficients
m1b <- feols(log_annual_pay ~ treat_intensity:i(post) | la_code + year,
             data = panel_bal, cluster = ~la_code)

summary(m1)

## ========================================================================
## 2. Event study: year-by-year treatment effects
## ========================================================================
cat("\n=== Event Study ===\n")

# Omit 2018 as the reference year (last pre-treatment year)
panel_bal$event_year <- relevel(factor(panel_bal$year), ref = "2018")

m_event <- feols(log_annual_pay ~ treat_intensity:i(event_year) | la_code + year,
                 data = panel_bal, cluster = ~la_code)

summary(m_event)

## ========================================================================
## 3. Binary treatment DiD (high vs low small-firm share)
## ========================================================================
cat("\n=== Binary DiD ===\n")

m_binary <- feols(log_annual_pay ~ high_small:post | la_code + year,
                  data = panel_bal, cluster = ~la_code)

m_binary_event <- feols(log_annual_pay ~ high_small:i(event_year) | la_code + year,
                        data = panel_bal, cluster = ~la_code)

summary(m_binary)

## ========================================================================
## 4. Hourly pay (alternative outcome)
## ========================================================================
cat("\n=== Hourly pay specification ===\n")

panel_hourly <- panel_bal %>% filter(!is.na(log_hourly_pay))

m_hourly <- feols(log_hourly_pay ~ treat_intensity:post | la_code + year,
                  data = panel_hourly, cluster = ~la_code)

m_hourly_event <- feols(log_hourly_pay ~ treat_intensity:i(event_year) | la_code + year,
                        data = panel_hourly, cluster = ~la_code)

summary(m_hourly)

## ========================================================================
## 5. Employment-weighted specification
## ========================================================================
cat("\n=== Employment-weighted ===\n")

panel_wt <- panel_bal %>% filter(!is.na(n_jobs) & n_jobs > 0)

m_weighted <- feols(log_annual_pay ~ treat_intensity:post | la_code + year,
                    data = panel_wt, weights = ~n_jobs, cluster = ~la_code)

summary(m_weighted)

## ========================================================================
## 6. Diagnostics
## ========================================================================
cat("\n=== Diagnostics ===\n")

# Pre-trend test: are pre-2019 event-study coefficients jointly zero?
pre_coefs <- coef(m_event)
pre_names <- names(pre_coefs)[grepl("2015|2016|2017", names(pre_coefs))]
cat(sprintf("Pre-trend coefficients: %s\n",
            paste(sprintf("%.4f", pre_coefs[pre_names]), collapse = ", ")))

# Treatment group sizes
n_treated <- sum(panel_bal$high_small == 1 & panel_bal$year == 2018, na.rm = TRUE)
n_control <- sum(panel_bal$high_small == 0 & panel_bal$year == 2018, na.rm = TRUE)
n_pre <- length(unique(panel_bal$year[panel_bal$year < 2019]))
n_obs <- nrow(panel_bal)

cat(sprintf("N treated LAs: %d\n", n_treated))
cat(sprintf("N control LAs: %d\n", n_control))
cat(sprintf("N pre-periods: %d\n", n_pre))
cat(sprintf("N total obs: %d\n", n_obs))

## Write diagnostics for validator
diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

## ========================================================================
## Save results
## ========================================================================

save(m1, m1b, m_event, m_binary, m_binary_event,
     m_hourly, m_hourly_event, m_weighted,
     file = file.path(data_dir, "main_results.RData"))

cat("\nMain results saved.\n")
