## ============================================================
## 03_main_analysis.R — Primary regressions
## apep_0531: PCSO Cuts and Crime in England
## ============================================================

source("00_packages.R")

panel <- fread(file.path(dat_dir, "analysis_panel.csv"))
panel <- panel[!is.na(total_crime) & !is.na(pcso_fte) & year <= 2024]
cat("Panel:", nrow(panel), "force-years,", length(unique(panel$force_std)), "forces\n")

## ---- 1. Descriptive Statistics --------------------------------

desc_period <- panel[, .(
  pcso_per100k = mean(pcso_per100k, na.rm = TRUE),
  officer_per100k = mean(officer_per100k, na.rm = TRUE),
  crime_rate = mean(crime_rate, na.rm = TRUE),
  N = .N
), by = .(period = fcase(
  year <= 2010, "Pre-austerity (2008-2010)",
  year <= 2015, "Early austerity (2011-2015)",
  year <= 2019, "Late austerity (2016-2019)",
  default = "Post-2020 (2020-2025)"
))]
cat("By period:\n")
print(desc_period[order(-pcso_per100k)])
fwrite(desc_period, file.path(dat_dir, "descriptive_by_period.csv"))

# PCSO change by force
pcso_change <- panel[year == max(year), .(force_name, pcso_baseline, pcso_per100k,
                                           pcso_pct_change)][order(pcso_pct_change)]
fwrite(pcso_change, file.path(dat_dir, "pcso_change_by_force.csv"))


## ---- 2. TWFE Regressions -------------------------------------

cat("\n=== TWFE REGRESSIONS ===\n")

# Model 1: Log crime ~ PCSO/100k (force + year FE)
m1 <- feols(log_crime_rate ~ pcso_per100k | force_id + year,
            data = panel, cluster = ~force_id)

# Model 2: Add sworn officer control
m2 <- feols(log_crime_rate ~ pcso_per100k + officer_per100k | force_id + year,
            data = panel, cluster = ~force_id)

# Model 3: Log-log specification
m3 <- feols(log_crime_rate ~ log_pcso + log_officer | force_id + year,
            data = panel[pcso_per100k > 0 & officer_per100k > 0], cluster = ~force_id)

# Model 4: Levels
m4 <- feols(crime_rate ~ pcso_per100k + officer_per100k | force_id + year,
            data = panel, cluster = ~force_id)

cat("\nModel 1: Log crime ~ PCSO/100k\n")
print(summary(m1))
cat("\nModel 2: + Officer/100k\n")
print(summary(m2))
cat("\nModel 3: Log-log\n")
print(summary(m3))
cat("\nModel 4: Levels\n")
print(summary(m4))

save(m1, m2, m3, m4, file = file.path(dat_dir, "twfe_models.RData"))

# Extract coefficients
coef_table <- data.table(
  model = c("TWFE (log)", "TWFE + officer (log)", "Log-log", "Levels"),
  coef_pcso = c(coef(m1)["pcso_per100k"],
                coef(m2)["pcso_per100k"],
                coef(m3)["log_pcso"],
                coef(m4)["pcso_per100k"]),
  se_pcso = c(se(m1)["pcso_per100k"],
              se(m2)["pcso_per100k"],
              se(m3)["log_pcso"],
              se(m4)["pcso_per100k"]),
  n = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4))
)
fwrite(coef_table, file.path(dat_dir, "twfe_coefficients.csv"))


## ---- 3. Event Study -------------------------------------------

cat("\n=== EVENT STUDY ===\n")

# Exposure-weighted event study:
# Forces with higher 2010 PCSO baseline lost more during austerity
# Interact baseline PCSO exposure with year dummies (ref = 2010)
es <- feols(log_crime_rate ~ i(year, pcso_baseline, ref = 2010) |
              force_id + year,
            data = panel[!is.na(pcso_baseline)], cluster = ~force_id)

cat("Event study:\n")
print(summary(es))

# Extract coefficients
es_ct <- coeftable(es)
es_coefs <- data.table(
  coef_name = rownames(es_ct),
  estimate = es_ct[, "Estimate"],
  se = es_ct[, "Std. Error"],
  tval = es_ct[, "t value"],
  pval = es_ct[, "Pr(>|t|)"]
)
es_coefs[, year := as.integer(gsub("year::(\\d+):.*", "\\1", coef_name))]
es_coefs <- es_coefs[!is.na(year)]
# Add reference year
es_coefs <- rbind(es_coefs,
                   data.table(coef_name = "ref", estimate = 0, se = 0,
                              tval = NA, pval = NA, year = 2010))
es_coefs <- es_coefs[order(year)]
fwrite(es_coefs, file.path(dat_dir, "event_study_coefs.csv"))

save(es, file = file.path(dat_dir, "event_study_models.RData"))


## ---- 4. Crime Type Decomposition ------------------------------

cat("\n=== CRIME TYPE DECOMPOSITION ===\n")

crime_type <- fread(file.path(dat_dir, "crime_type_panel.csv"))
crime_type <- crime_type[!is.na(crime_rate) & !is.na(pcso_per100k) & crime_rate > 0 & year <= 2024]

type_results <- list()
for (ct in unique(crime_type$offence_group)) {
  dt_ct <- crime_type[offence_group == ct]
  if (nrow(dt_ct) < 100) next

  m_ct <- tryCatch({
    feols(log(crime_rate) ~ pcso_per100k + officer_per100k |
            force_id + year,
          data = dt_ct, cluster = ~force_id)
  }, error = function(e) NULL)

  if (!is.null(m_ct) && "pcso_per100k" %in% names(coef(m_ct))) {
    ct_coef <- coeftable(m_ct)
    type_results[[ct]] <- data.table(
      offence_group = ct,
      coef = ct_coef["pcso_per100k", "Estimate"],
      se = ct_coef["pcso_per100k", "Std. Error"],
      pval = ct_coef["pcso_per100k", "Pr(>|t|)"],
      n = nobs(m_ct)
    )
  }
}

type_dt <- rbindlist(type_results)
type_dt[, stars := fcase(pval < 0.01, "***", pval < 0.05, "**",
                          pval < 0.10, "*", default = "")]
cat("\nCrime type results (PCSO coefficient):\n")
print(type_dt[order(coef)])
fwrite(type_dt, file.path(dat_dir, "crime_type_results.csv"))


## ---- 5. Summary -----------------------------------------------

cat("\n=== MAIN FINDINGS ===\n")

pcso_coef <- coef(m2)["pcso_per100k"]
pcso_se <- se(m2)["pcso_per100k"]
mean_decline <- panel[, mean(pcso_per100k[year == 2010], na.rm = TRUE)] -
                panel[, mean(pcso_per100k[year == max(year)], na.rm = TRUE)]

cat("PCSO coefficient (log crime):", round(pcso_coef, 5), "SE:", round(pcso_se, 5), "\n")
cat("Average PCSO decline per 100k:", round(mean_decline, 1), "\n")
cat("Implied crime effect from average decline:", round(pcso_coef * mean_decline * 100, 1), "%\n")

if ("log_pcso" %in% names(coef(m3))) {
  cat("PCSO-crime elasticity:", round(coef(m3)["log_pcso"], 3), "\n")
}
