## 03_main_analysis.R — Main DiD estimation
## apep_0823: The Alice Dividend

library(data.table)
library(fixest)
library(jsonlite)

outdir <- here::here("output", "apep_0823", "v1")
datadir <- file.path(outdir, "data")

## ========== LOAD DATA ==========
cbp <- fread(file.path(datadir, "cbp_panel.csv"))
qcew <- fread(file.path(datadir, "qcew_panel.csv"))

## ========== TABLE 1: FIRST STAGE — Patent Rejection Rates ==========
cat("=== First Stage: Patent Rejection Rates ===\n")
fs <- fread(file.path(datadir, "first_stage.csv"))

## DiD on first-stage data
fs[, post := as.integer(year >= 2015 | (year == 2014 & quarter >= 3))]
fs[, software := as.integer(tech_group == "software")]
fs[, treat_post := software * post]

cat("First-stage DiD:\n")
fs_did <- lm(sec101_rate ~ software * post, data = fs)
cat("  Treatment effect:", round(coef(fs_did)["software:post"], 3), "\n")
cat("  (SE:", round(summary(fs_did)$coefficients["software:post", "Std. Error"], 4), ")\n")

## ========== TABLE 2: MAIN DiD — CBP Annual Panel ==========
cat("\n=== Main DiD: CBP Annual Panel ===\n")

## Ensure numeric types
cbp[, emp := as.numeric(emp)]
cbp[, estab := as.numeric(estab)]
cbp[, payann := as.numeric(payann)]
cbp[, log_emp := log(emp)]
cbp[, log_estab := log(estab)]
cbp[, log_payann := log(payann + 1)]

## Main specification: county x industry FE + year FE
## Treatment = software industries × post-2014
m1_emp <- feols(log_emp ~ treat_post | fips^naics + year, data = cbp,
                cluster = ~state_fips)

m2_estab <- feols(log_estab ~ treat_post | fips^naics + year, data = cbp,
                  cluster = ~state_fips)

m3_payann <- feols(log_payann ~ treat_post | fips^naics + year, data = cbp,
                   cluster = ~state_fips)

## With state x year FE (absorbs state-level macro shocks)
m4_emp_styr <- feols(log_emp ~ treat_post | fips^naics + state_fips^year, data = cbp,
                     cluster = ~state_fips)

cat("DiD Results (CBP Annual):\n")
cat("  log(Employment):  beta =", round(coef(m1_emp)["treat_post"], 4),
    " SE =", round(se(m1_emp)["treat_post"], 4), "\n")
cat("  log(Establ):      beta =", round(coef(m2_estab)["treat_post"], 4),
    " SE =", round(se(m2_estab)["treat_post"], 4), "\n")
cat("  log(Payroll):     beta =", round(coef(m3_payann)["treat_post"], 4),
    " SE =", round(se(m3_payann)["treat_post"], 4), "\n")
cat("  log(Emp) st×yr:   beta =", round(coef(m4_emp_styr)["treat_post"], 4),
    " SE =", round(se(m4_emp_styr)["treat_post"], 4), "\n")

## ========== TABLE 3: EVENT STUDY — CBP Annual ==========
cat("\n=== Event Study: CBP Annual ===\n")

## Event study: leads and lags relative to 2014
cbp[, event_time := year - 2014]
cbp[, event_treated := treated * event_time]

## Event study regression (omit t = -1 as reference)
es_emp <- feols(log_emp ~ i(event_time, treated, ref = -1) | fips^naics + year,
                data = cbp, cluster = ~state_fips)

cat("Event study coefficients:\n")
es_coefs <- coeftable(es_emp)
print(round(es_coefs, 4))

## Check pre-trends
pre_coefs <- es_coefs[grepl("event_time::-[2-9]", rownames(es_coefs)), ]
if (nrow(pre_coefs) > 0) {
  cat("\nPre-trend test (joint F):\n")
  pre_test <- wald(es_emp, paste0("event_time::", -6:-2, ":treated"))
  cat("  F =", round(pre_test$stat, 2), " p =", round(pre_test$p, 4), "\n")
}

## ========== TABLE 4: QCEW QUARTERLY EVENT STUDY ==========
cat("\n=== Quarterly Event Study: QCEW ===\n")

## Create quarterly event time (relative to 2014Q2)
qcew[, qtr_event := (year - 2014) * 4 + (quarter - 2)]

## Quarterly DiD
m5_qtr <- feols(log_emp ~ i(qtr_event, treated, ref = -1) | fips^industry_code + yearqtr,
                data = qcew[qtr_event >= -2 & qtr_event <= 18],
                cluster = ~state_fips)

cat("Quarterly event study (select coefficients):\n")
qtr_coefs <- coeftable(m5_qtr)
cat("  Q0 (2014Q2):", round(qtr_coefs[1, 1], 4), "\n")
for (i in seq(1, min(nrow(qtr_coefs), 18))) {
  rn <- rownames(qtr_coefs)[i]
  cat("  ", rn, ":", round(qtr_coefs[i, 1], 4), "(", round(qtr_coefs[i, 2], 4), ")\n")
}

## Simple quarterly DiD (pooled post)
m6_qtr_did <- feols(log_emp ~ treat_post | fips^industry_code + yearqtr,
                    data = qcew, cluster = ~state_fips)
cat("\nPooled quarterly DiD:")
cat("  beta =", round(coef(m6_qtr_did)["treat_post"], 4),
    " SE =", round(se(m6_qtr_did)["treat_post"], 4), "\n")

## ========== SAVE RESULTS ==========
## Store models for table generation
results <- list(
  m1_emp = m1_emp,
  m2_estab = m2_estab,
  m3_payann = m3_payann,
  m4_emp_styr = m4_emp_styr,
  es_emp = es_emp,
  m5_qtr = m5_qtr,
  m6_qtr_did = m6_qtr_did
)

saveRDS(results, file.path(datadir, "main_results.rds"))

## Update diagnostics
diag <- fromJSON(file.path(datadir, "diagnostics.json"))
diag$main_coef <- round(coef(m1_emp)["treat_post"], 4)
diag$main_se <- round(se(m1_emp)["treat_post"], 4)
diag$pre_trend_p <- if (exists("pre_test")) round(pre_test$p, 4) else NA
write_json(diag, file.path(datadir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nAll main results saved.\n")
