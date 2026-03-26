## 03_main_analysis.R — Main IV/2SLS analysis
## apep_1016: Fresh Start Dividend

library(tidyverse)
library(data.table)
library(fixest)

DATA_DIR <- file.path(dirname(getwd()), "data")

# -----------------------------------------------------------------------
# 1. Load analysis data
# -----------------------------------------------------------------------

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cases <- fread(file.path(DATA_DIR, "cases_clean.csv"))
judge_stats <- fread(file.path(DATA_DIR, "judge_stats.csv"))

cat(sprintf("Panel: %d court-years\n", nrow(panel)))
cat(sprintf("Cases: %d individual cases\n", nrow(cases)))
cat(sprintf("Judges: %d judge-court pairs\n", nrow(judge_stats)))

# -----------------------------------------------------------------------
# 2. Summary statistics
# -----------------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")
cat(sprintf("Courts: %d\n", uniqueN(panel$court_id)))
cat(sprintf("Years: %d-%d\n", min(panel$file_year), max(panel$file_year)))
cat(sprintf("Mean cases per court-year: %.1f\n", mean(panel$n_cases)))
cat(sprintf("Mean judges per court-year: %.1f\n", mean(panel$n_judges)))
cat(sprintf("Mean confirmation rate: %.3f\n", mean(panel$confirm_rate)))
cat(sprintf("SD confirmation rate: %.3f\n", sd(panel$confirm_rate)))
cat(sprintf("Mean judge leniency: %.3f\n", mean(panel$avg_leniency)))
cat(sprintf("SD judge leniency: %.3f\n", sd(panel$avg_leniency)))

# Business dynamics summary
for (v in c("entry_t0", "entry_t1", "entry_t2", "entry_rate_t0", "entry_rate_t1")) {
  if (v %in% names(panel)) {
    vals <- panel[[v]]
    vals <- vals[!is.na(vals)]
    cat(sprintf("%s: mean=%.0f, sd=%.0f, n=%d\n", v, mean(vals), sd(vals), length(vals)))
  }
}

# -----------------------------------------------------------------------
# 3. First Stage: Judge Leniency → Confirmation Rate
# -----------------------------------------------------------------------

cat("\n=== FIRST STAGE ===\n")

# Court FE only
fs1 <- feols(confirm_rate ~ avg_leniency | court_id, data = panel,
             cluster = ~court_id)
cat("\nFirst stage (court FE):\n")
print(summary(fs1))

# Court + year FE (main spec)
fs2 <- feols(confirm_rate ~ avg_leniency | court_id + file_year, data = panel,
             cluster = ~court_id)
cat("\nFirst stage (court + year FE):\n")
print(summary(fs2))

# -----------------------------------------------------------------------
# 4. Reduced Form: Judge Leniency → Establishment Entry
# -----------------------------------------------------------------------

cat("\n=== REDUCED FORM ===\n")

# ln(establishment entries) at t+1
rf1 <- feols(ln_entry_t1 ~ avg_leniency | court_id + file_year,
             data = panel[!is.na(ln_entry_t1)], cluster = ~court_id)
cat("\nReduced form — ln(Estab Entry) at t+1:\n")
print(summary(rf1))

# ln(establishment entries) at t+2
rf2 <- feols(ln_entry_t2 ~ avg_leniency | court_id + file_year,
             data = panel[!is.na(ln_entry_t2)], cluster = ~court_id)
cat("\nReduced form — ln(Estab Entry) at t+2:\n")
print(summary(rf2))

# Entry rate at t+1
rf_rate1 <- feols(entry_rate_t1 ~ avg_leniency | court_id + file_year,
                  data = panel[!is.na(entry_rate_t1)], cluster = ~court_id)
cat("\nReduced form — Entry Rate at t+1:\n")
print(summary(rf_rate1))

# ln(firms) at t+1
rf_firms1 <- feols(ln_firms_t1 ~ avg_leniency | court_id + file_year,
                   data = panel[!is.na(ln_firms_t1)], cluster = ~court_id)
cat("\nReduced form — ln(Firms) at t+1:\n")
print(summary(rf_firms1))

# -----------------------------------------------------------------------
# 5. 2SLS: Instrumented Confirmation Rate → Business Dynamics
# -----------------------------------------------------------------------

cat("\n=== 2SLS ESTIMATES ===\n")

# Main spec: ln(establishment entries) at t+1
iv1 <- feols(ln_entry_t1 ~ 1 | court_id + file_year | confirm_rate ~ avg_leniency,
             data = panel[!is.na(ln_entry_t1)], cluster = ~court_id)
cat("\n2SLS — ln(Estab Entry) at t+1:\n")
print(summary(iv1))

# ln(establishment entries) at t+2
iv2 <- feols(ln_entry_t2 ~ 1 | court_id + file_year | confirm_rate ~ avg_leniency,
             data = panel[!is.na(ln_entry_t2)], cluster = ~court_id)
cat("\n2SLS — ln(Estab Entry) at t+2:\n")
print(summary(iv2))

# Entry rate at t+1
iv_rate1 <- feols(entry_rate_t1 ~ 1 | court_id + file_year | confirm_rate ~ avg_leniency,
                  data = panel[!is.na(entry_rate_t1)], cluster = ~court_id)
cat("\n2SLS — Entry Rate at t+1:\n")
print(summary(iv_rate1))

# ln(firms) at t+1
iv_firms1 <- feols(ln_firms_t1 ~ 1 | court_id + file_year | confirm_rate ~ avg_leniency,
                   data = panel[!is.na(ln_firms_t1)], cluster = ~court_id)
cat("\n2SLS — ln(Firms) at t+1:\n")
print(summary(iv_firms1))

# -----------------------------------------------------------------------
# 6. OLS comparison
# -----------------------------------------------------------------------

cat("\n=== OLS COMPARISON ===\n")

ols1 <- feols(ln_entry_t1 ~ confirm_rate | court_id + file_year,
              data = panel[!is.na(ln_entry_t1)], cluster = ~court_id)
cat("\nOLS — ln(Estab Entry) at t+1:\n")
print(summary(ols1))

# -----------------------------------------------------------------------
# 7. Save results
# -----------------------------------------------------------------------

results <- list(
  first_stage = list(fs1 = fs1, fs2 = fs2),
  reduced_form = list(rf1 = rf1, rf2 = rf2, rf_rate1 = rf_rate1, rf_firms1 = rf_firms1),
  iv = list(iv1 = iv1, iv2 = iv2, iv_rate1 = iv_rate1, iv_firms1 = iv_firms1),
  ols = list(ols1 = ols1)
)

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))

# -----------------------------------------------------------------------
# 8. Diagnostics
# -----------------------------------------------------------------------

diag <- list(
  n_treated = uniqueN(panel$court_id),
  n_pre = length(unique(panel$file_year[panel$file_year < 2015])),
  n_obs = nrow(panel),
  n_cases = nrow(cases),
  n_judges = nrow(judge_stats),
  n_courts = uniqueN(panel$court_id),
  mean_confirm_rate = round(mean(panel$confirm_rate), 4),
  sd_confirm_rate = round(sd(panel$confirm_rate), 4),
  mean_leniency = round(mean(panel$avg_leniency), 4),
  sd_leniency = round(sd(panel$avg_leniency), 4)
)

jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat("\nSaved diagnostics.json\n")

cat("\n=== Main analysis complete ===\n")
