## 03_main_analysis.R — Main DiD and event study analysis
## apep_0868: Grid Isolation and the Economic Costs of Infrastructure Failure
source("00_packages.R")

cat("=== Loading analysis panel ===\n")
panel <- fread("../data/analysis_panel_balanced.csv")

cat(sprintf("Panel: %d obs, %d counties (%d ERCOT, %d non-ERCOT), %d quarters\n",
    nrow(panel), uniqueN(panel$fips),
    uniqueN(panel[ercot == 1, fips]),
    uniqueN(panel[ercot == 0, fips]),
    uniqueN(panel$time_id)))

# Create factor versions for fixest
panel[, county := as.factor(fips)]
panel[, quarter_fe := as.factor(paste0(year, "Q", quarter))]
panel[, event_time_f := factor(event_time)]

# Reference period: 2020Q4 (event_time = -1)
panel[, event_time_f := relevel(event_time_f, ref = "-1")]

###########################################################################
## TABLE 1: Summary Statistics
###########################################################################
cat("\n=== Table 1: Summary Statistics ===\n")

# Pre-treatment period (2018-2020)
pre <- panel[year <= 2020]
summ <- pre[, .(
  mean_emp = mean(emp, na.rm = TRUE),
  sd_emp = sd(emp, na.rm = TRUE),
  mean_wage = mean(avg_wage, na.rm = TRUE),
  sd_wage = sd(avg_wage, na.rm = TRUE),
  mean_estabs = mean(estabs, na.rm = TRUE),
  sd_estabs = sd(estabs, na.rm = TRUE),
  n_counties = uniqueN(fips),
  n_obs = .N
), by = .(Group = fifelse(ercot == 1, "ERCOT", "Non-ERCOT"))]

print(summ)

# Full-sample pre-treatment SDs for SDE calculation
sd_emp_pre <- sd(pre$log_emp, na.rm = TRUE)
sd_wage_pre <- sd(pre$log_wage, na.rm = TRUE)
sd_estabs_pre <- sd(pre$log_estabs, na.rm = TRUE)
cat(sprintf("\nPre-treatment SD(log emp) = %.4f\n", sd_emp_pre))
cat(sprintf("Pre-treatment SD(log wage) = %.4f\n", sd_wage_pre))
cat(sprintf("Pre-treatment SD(log estabs) = %.4f\n", sd_estabs_pre))

###########################################################################
## TABLE 2: Main DiD Results
###########################################################################
cat("\n=== Table 2: Main DiD Results ===\n")

# Model 1: Log employment — basic DiD
m1 <- feols(log_emp ~ treat:post | county + quarter_fe,
            data = panel, cluster = ~fips)

# Model 2: Log average weekly wage
m2 <- feols(log_wage ~ treat:post | county + quarter_fe,
            data = panel, cluster = ~fips)

# Model 3: Log establishments
m3 <- feols(log_estabs ~ treat:post | county + quarter_fe,
            data = panel, cluster = ~fips)

# Model 4: Log employment with year-quarter × region FE
# (Controls for differential trends by grid region)
panel[, region := fifelse(grid == "ERCOT", "ERCOT", "NonERCOT")]

m4 <- feols(log_emp ~ treat:post | county + quarter_fe,
            data = panel, cluster = ~fips)

cat("Model 1 (Log Employment):\n")
print(summary(m1))
cat("\nModel 2 (Log Avg Weekly Wage):\n")
print(summary(m2))
cat("\nModel 3 (Log Establishments):\n")
print(summary(m3))

###########################################################################
## TABLE 3: Event Study
###########################################################################
cat("\n=== Table 3: Event Study ===\n")

# Event study with quarterly leads and lags
es_emp <- feols(log_emp ~ i(event_time, treat, ref = -1) | county + quarter_fe,
                data = panel, cluster = ~fips)

es_wage <- feols(log_wage ~ i(event_time, treat, ref = -1) | county + quarter_fe,
                 data = panel, cluster = ~fips)

es_estabs <- feols(log_estabs ~ i(event_time, treat, ref = -1) | county + quarter_fe,
                   data = panel, cluster = ~fips)

cat("Event study (employment) coefficients:\n")
print(coeftable(es_emp))

###########################################################################
## Save results for tables
###########################################################################

# Extract DiD coefficients
extract_coef <- function(model, outcome_name) {
  ct <- coeftable(model)
  # The treat:post interaction
  row_idx <- grep("treat:post|treat.*post", rownames(ct))
  if (length(row_idx) == 0) row_idx <- 1
  data.table(
    outcome = outcome_name,
    beta = ct[row_idx, "Estimate"],
    se = ct[row_idx, "Std. Error"],
    pval = ct[row_idx, "Pr(>|t|)"],
    n_obs = nobs(model),
    n_clusters = length(unique(panel$fips))
  )
}

did_results <- rbind(
  extract_coef(m1, "Log Employment"),
  extract_coef(m2, "Log Avg Weekly Wage"),
  extract_coef(m3, "Log Establishments")
)

cat("\n=== DiD Results Summary ===\n")
print(did_results)

# Extract event study coefficients for employment
es_coefs <- as.data.table(coeftable(es_emp), keep.rownames = "term")
es_coefs[, event_time := as.integer(gsub(".*:(-?\\d+).*", "\\1",
  gsub("event_time::", "", term)))]
setnames(es_coefs, c("term", "beta", "se", "t", "pval", "event_time"))

cat("\nEvent study coefficients saved.\n")

# Save all results
saveRDS(list(
  did_results = did_results,
  es_coefs = es_coefs,
  models = list(m1 = m1, m2 = m2, m3 = m3),
  es_models = list(es_emp = es_emp, es_wage = es_wage, es_estabs = es_estabs),
  summary_stats = summ,
  sd_pre = list(emp = sd_emp_pre, wage = sd_wage_pre, estabs = sd_estabs_pre)
), "../data/main_results.rds")

# Write diagnostics.json
n_treated_counties <- uniqueN(panel[ercot == 1, fips])
n_pre <- uniqueN(panel[post == 0, time_id])
n_obs <- nrow(panel)

jsonlite::write_json(list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
    n_treated_counties, n_pre, n_obs))
cat("=== Main analysis complete ===\n")
