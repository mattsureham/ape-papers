# ==============================================================================
# 03_main_analysis.R — DiD estimation: shutdown × federal share
# ==============================================================================

source("00_packages.R")

qwi <- readRDS("../data/analysis_total.rds")
qwi_sec <- readRDS("../data/analysis_sector.rds")

# --- State FIPS for clustering ---
qwi[, state_fips := substr(fips, 1, 2)]
qwi_sec[, state_fips := substr(fips, 1, 2)]

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Cross-section at baseline (2012Q1)
baseline <- qwi[year == 2012 & quarter == 1]

summ_stats <- data.frame(
  Variable = c("Federal employment share",
                "Federal employment",
                "Total employment",
                "Private-sector employment (quarterly avg)",
                "Private-sector earnings ($)",
                "Private-sector hires",
                "Population",
                "Counties"),
  Mean = c(mean(baseline$fed_share),
           mean(baseline$fed_emp),
           mean(baseline$total_emp),
           mean(baseline$private_emp, na.rm = TRUE),
           mean(baseline$private_earn, na.rm = TRUE),
           mean(baseline$private_hires, na.rm = TRUE),
           mean(baseline$population),
           uniqueN(baseline$fips)),
  SD = c(sd(baseline$fed_share),
         sd(baseline$fed_emp),
         sd(baseline$total_emp),
         sd(baseline$private_emp, na.rm = TRUE),
         sd(baseline$private_earn, na.rm = TRUE),
         sd(baseline$private_hires, na.rm = TRUE),
         sd(baseline$population),
         NA),
  P25 = c(quantile(baseline$fed_share, 0.25),
          quantile(baseline$fed_emp, 0.25),
          quantile(baseline$total_emp, 0.25),
          quantile(baseline$private_emp, 0.25, na.rm = TRUE),
          quantile(baseline$private_earn, 0.25, na.rm = TRUE),
          quantile(baseline$private_hires, 0.25, na.rm = TRUE),
          quantile(baseline$population, 0.25),
          NA),
  P75 = c(quantile(baseline$fed_share, 0.75),
          quantile(baseline$fed_emp, 0.75),
          quantile(baseline$total_emp, 0.75),
          quantile(baseline$private_emp, 0.75, na.rm = TRUE),
          quantile(baseline$private_earn, 0.75, na.rm = TRUE),
          quantile(baseline$private_hires, 0.75, na.rm = TRUE),
          quantile(baseline$population, 0.75),
          NA)
)

print(summ_stats, digits = 3)
saveRDS(summ_stats, "../data/summ_stats.rds")

# ==============================================================================
# TABLE 2: Main DiD Results — Private Sector Employment
# ==============================================================================
cat("\n=== Table 2: Main DiD ===\n")

# Column 1: Pooled shutdown effect (both events)
m1 <- feols(ln_emp ~ treat_shutdown | fips + time_id,
            data = qwi, cluster = ~state_fips)

# Column 2: Separate effects for 2013 and 2019
m2 <- feols(ln_emp ~ treat_shutdown_2013 + treat_shutdown_2019 | fips + time_id,
            data = qwi, cluster = ~state_fips)

# Column 3: Employment per capita
m3 <- feols(emp_pc ~ treat_shutdown | fips + time_id,
            data = qwi, cluster = ~state_fips)

# Column 4: Earnings
qwi[, ln_earn := log(private_earn + 1)]
m4 <- feols(ln_earn ~ treat_shutdown | fips + time_id,
            data = qwi, cluster = ~state_fips)

# Column 5: Hires
qwi[, ln_hires := log(private_hires + 1)]
m5 <- feols(ln_hires ~ treat_shutdown | fips + time_id,
            data = qwi, cluster = ~state_fips)

cat("Pooled shutdown effect on ln(employment):\n")
print(summary(m1))
cat("\nSeparate shutdown effects:\n")
print(summary(m2))

# Save regression objects
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
        "../data/main_models.rds")

# ==============================================================================
# TABLE 3: Sector Decomposition
# ==============================================================================
cat("\n=== Table 3: Sector Decomposition ===\n")

sector_models <- list()
for (sec in c("72", "44-45", "31-33", "62")) {
  df_sec <- qwi_sec[industry == sec]
  df_sec[, ln_emp := log(emp + 1)]
  df_sec[, state_fips := substr(fips, 1, 2)]

  sector_models[[sec]] <- feols(ln_emp ~ treat_shutdown | fips + time_id,
                                data = df_sec, cluster = ~state_fips)

  cat(sprintf("\nSector %s (%s): coef = %.4f, se = %.4f, n = %d\n",
              sec, unique(df_sec$sector_label),
              coef(sector_models[[sec]])["treat_shutdown"],
              se(sector_models[[sec]])["treat_shutdown"],
              nobs(sector_models[[sec]])))
}

saveRDS(sector_models, "../data/sector_models.rds")

# ==============================================================================
# EVENT STUDY (for Table 4 — dynamic specification)
# ==============================================================================
cat("\n=== Event Study: 2013 Shutdown ===\n")

# Window: 8 quarters before, 4 quarters after
es_data_2013 <- qwi[event_time_2013 >= -8 & event_time_2013 <= 4]
es_data_2013[, et := factor(event_time_2013)]

# Reference period: t = -1
es_2013 <- feols(ln_emp ~ i(et, fed_share, ref = "-1") | fips + time_id,
                 data = es_data_2013, cluster = ~state_fips)

cat("Event study 2013:\n")
print(summary(es_2013))

# 2019 shutdown event study
es_data_2019 <- qwi[event_time_2019 >= -8 & event_time_2019 <= 4]
es_data_2019[, et := factor(event_time_2019)]

es_2019 <- feols(ln_emp ~ i(et, fed_share, ref = "-1") | fips + time_id,
                 data = es_data_2019, cluster = ~state_fips)

cat("\nEvent study 2019:\n")
print(summary(es_2019))

saveRDS(list(es_2013 = es_2013, es_2019 = es_2019), "../data/event_study_models.rds")

# ==============================================================================
# Diagnostics for validation
# ==============================================================================
n_treated_high <- uniqueN(qwi[fed_share >= quantile(qwi$fed_share, 0.75)]$fips)
n_pre_2013 <- length(unique(qwi[year < 2013]$time_id))

diag <- list(
  n_treated = n_treated_high,
  n_pre = n_pre_2013,
  n_obs = nrow(qwi),
  n_counties = uniqueN(qwi$fips),
  n_quarters = uniqueN(qwi$time_id),
  mean_fed_share = mean(qwi[year == 2012 & quarter == 1]$fed_share),
  sd_fed_share = sd(qwi[year == 2012 & quarter == 1]$fed_share)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written.\n")
