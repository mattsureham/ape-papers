# ==============================================================================
# 03_main_analysis.R — Main DiD regressions for apep_1253
# ==============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv",
               colClasses = list(character = c("fips", "industry", "state_fips",
                                               "county_industry", "industry_quarter")))

cat("=== Main Analysis: TFP Revision and Industry Employment ===\n\n")

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

cat("--- Summary Statistics ---\n")

# Pre-treatment summary by poverty tercile
panel[, poverty_tercile := cut(poverty_rate,
                                breaks = quantile(poverty_rate, c(0, 1/3, 2/3, 1)),
                                labels = c("Low", "Medium", "High"),
                                include.lowest = TRUE)]

summ_pre <- panel[post == 0, .(
  mean_emp       = mean(emp, na.rm = TRUE),
  sd_emp         = sd(emp, na.rm = TRUE),
  mean_log_emp   = mean(log_emp, na.rm = TRUE),
  sd_log_emp     = sd(log_emp, na.rm = TRUE),
  mean_earnings  = mean(avg_earnings, na.rm = TRUE),
  sd_earnings    = sd(avg_earnings, na.rm = TRUE),
  mean_hires     = mean(hires_all, na.rm = TRUE),
  sd_hires       = sd(hires_all, na.rm = TRUE),
  mean_seps      = mean(separations, na.rm = TRUE),
  sd_seps        = sd(separations, na.rm = TRUE),
  mean_poverty   = mean(poverty_rate, na.rm = TRUE),
  mean_pop       = mean(population, na.rm = TRUE),
  n_counties     = uniqueN(fips),
  n_obs          = .N
)]

cat(sprintf("Pre-treatment mean employment per county-industry-qtr: %.0f (sd=%.0f)\n",
            summ_pre$mean_emp, summ_pre$sd_emp))
cat(sprintf("Pre-treatment mean log emp: %.3f (sd=%.3f)\n",
            summ_pre$mean_log_emp, summ_pre$sd_log_emp))
cat(sprintf("Pre-treatment mean earnings: $%.0f (sd=$%.0f)\n",
            summ_pre$mean_earnings, summ_pre$sd_earnings))

# Save summary stats for table generation
saveRDS(summ_pre, "../data/summary_stats.rds")

# Summary by poverty tercile
summ_tercile <- panel[post == 0, .(
  mean_emp     = mean(emp, na.rm = TRUE),
  mean_earnings = mean(avg_earnings, na.rm = TRUE),
  mean_poverty = mean(poverty_rate, na.rm = TRUE),
  n_counties   = uniqueN(fips)
), by = poverty_tercile]

print(summ_tercile)

# ==============================================================================
# Main Specification: Pooled DiD
# ==============================================================================

cat("\n--- Main Specification: Pooled DiD ---\n")

# Specification: log(Emp) = county-industry FE + industry-quarter FE +
#                β × (poverty_rate × Post) + ε
# Clustering: state level

fit_pooled <- feols(
  log_emp ~ treat_post | county_industry + industry_quarter,
  data = panel,
  cluster = ~state_fips
)

cat("\nPooled DiD (all industries):\n")
summary(fit_pooled)

# ==============================================================================
# Industry-Specific DiD
# ==============================================================================

cat("\n--- Industry-Specific DiD ---\n")

industries <- sort(unique(panel$industry))
results_list <- list()

for (ind in industries) {
  fit_ind <- feols(
    log_emp ~ treat_post | county_industry + industry_quarter,
    data = panel[industry == ind],
    cluster = ~state_fips
  )

  lab <- panel[industry == ind, ind_label[1]]
  results_list[[ind]] <- data.table(
    industry   = ind,
    ind_label  = lab,
    beta       = coef(fit_ind)["treat_post"],
    se         = sqrt(diag(vcov(fit_ind)))["treat_post"],
    pval       = pvalue(fit_ind)["treat_post"],
    n_obs      = nobs(fit_ind),
    n_counties = uniqueN(panel[industry == ind, fips]),
    n_clusters = length(unique(panel[industry == ind, state_fips]))
  )

  cat(sprintf("  %s (NAICS %s): β=%.5f (SE=%.5f), p=%.4f, N=%s\n",
              lab, ind, coef(fit_ind)["treat_post"],
              sqrt(diag(vcov(fit_ind)))["treat_post"],
              pvalue(fit_ind)["treat_post"],
              format(nobs(fit_ind), big.mark = ",")))
}

results_dt <- rbindlist(results_list)
results_dt[, stars := ifelse(pval < 0.01, "***",
                      ifelse(pval < 0.05, "**",
                      ifelse(pval < 0.10, "*", "")))]

# Save industry results
saveRDS(results_dt, "../data/industry_results.rds")

# ==============================================================================
# Event Study (Pooled)
# ==============================================================================

cat("\n--- Event Study: Pooled ---\n")

# Create event-time dummies interacted with poverty rate
# Omit period -1 (2021Q3, last pre-treatment quarter)
panel[, event_time_fct := factor(event_time)]

fit_es <- feols(
  log_emp ~ i(event_time, poverty_rate, ref = -1) | county_industry + industry_quarter,
  data = panel,
  cluster = ~state_fips
)

cat("Event study coefficients:\n")
es_coefs <- as.data.table(coeftable(fit_es), keep.rownames = "term")
es_coefs[, event_t := as.integer(gsub("event_time::", "", gsub(":poverty_rate", "", term)))]
es_coefs <- es_coefs[order(event_t)]
print(es_coefs[, .(event_t, Estimate, `Std. Error`, `Pr(>|t|)`)])

saveRDS(fit_es, "../data/event_study_fit.rds")

# ==============================================================================
# Event Study by Key Industries
# ==============================================================================

cat("\n--- Event Studies by Industry ---\n")

es_industry <- list()
for (ind in c("72", "44-45", "62", "31-33")) {
  fit_es_ind <- feols(
    log_emp ~ i(event_time, poverty_rate, ref = -1) | county_industry + industry_quarter,
    data = panel[industry == ind],
    cluster = ~state_fips
  )
  es_industry[[ind]] <- fit_es_ind

  lab <- panel[industry == ind, ind_label[1]]
  cat(sprintf("  %s: pre-trend F-test p = %.4f\n",
              lab, wald(fit_es_ind, "event_time::-[0-9]", print = FALSE)$p))
}

saveRDS(es_industry, "../data/event_study_industry.rds")

# ==============================================================================
# Diagnostics JSON (for validate_v1.py)
# ==============================================================================

n_treated_counties <- uniqueN(panel[poverty_rate > median(poverty_rate) & post == 1, fips])
n_pre <- length(unique(panel[post == 0, time_id]))

diag <- list(
  n_treated = n_treated_counties,
  n_pre     = n_pre,
  n_obs     = nrow(panel)
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%s\n",
            diag$n_treated, diag$n_pre, format(diag$n_obs, big.mark = ",")))

cat("\n=== Main analysis complete ===\n")
