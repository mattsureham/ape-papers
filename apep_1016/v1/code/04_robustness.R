## 04_robustness.R — Robustness checks and diagnostics
## apep_1016: Fresh Start Dividend

library(tidyverse)
library(data.table)
library(fixest)

DATA_DIR <- file.path(dirname(getwd()), "data")
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cases <- fread(file.path(DATA_DIR, "cases_clean.csv"))

cat("=== Robustness Checks ===\n")

# -----------------------------------------------------------------------
# 1. Balance tests
# -----------------------------------------------------------------------

cat("\n--- Balance Tests ---\n")

bal1 <- feols(log(n_cases) ~ avg_leniency | court_id + file_year,
              data = panel, cluster = ~court_id)
cat(sprintf("Balance: Leniency → log(n_cases): Coef=%.4f, SE=%.4f, p=%.3f\n",
            coef(bal1)["avg_leniency"], se(bal1)["avg_leniency"],
            pvalue(bal1)["avg_leniency"]))

bal2 <- feols(n_judges ~ avg_leniency | court_id + file_year,
              data = panel, cluster = ~court_id)
cat(sprintf("Balance: Leniency → n_judges: Coef=%.4f, SE=%.4f, p=%.3f\n",
            coef(bal2)["avg_leniency"], se(bal2)["avg_leniency"],
            pvalue(bal2)["avg_leniency"]))

# -----------------------------------------------------------------------
# 2. Placebo: concurrent-year outcome
# -----------------------------------------------------------------------

cat("\n--- Placebo Tests ---\n")

placebo_t0 <- feols(ln_entry_t0 ~ avg_leniency | court_id + file_year,
                    data = panel, cluster = ~court_id)
cat(sprintf("Placebo: Leniency → ln(Entry) t=0: Coef=%.4f, SE=%.4f, p=%.3f\n",
            coef(placebo_t0)["avg_leniency"], se(placebo_t0)["avg_leniency"],
            pvalue(placebo_t0)["avg_leniency"]))

placebo_emp <- feols(ln_emp_t0 ~ avg_leniency | court_id + file_year,
                     data = panel[!is.na(ln_emp_t0)], cluster = ~court_id)
cat(sprintf("Placebo: Leniency → ln(Employment) t=0: Coef=%.4f, SE=%.4f, p=%.3f\n",
            coef(placebo_emp)["avg_leniency"], se(placebo_emp)["avg_leniency"],
            pvalue(placebo_emp)["avg_leniency"]))

# -----------------------------------------------------------------------
# 3. Alternative confirmation thresholds
# -----------------------------------------------------------------------

cat("\n--- Alternative Thresholds ---\n")

for (thresh in c(365, 1095)) {
  var_name <- paste0("confirmed_", thresh)
  loo_name <- paste0("loo_", var_name)

  cases[, (var_name) := as.integer(duration_days > thresh)]
  cases[, (loo_name) := {
    total <- sum(get(var_name))
    n <- .N
    (total - get(var_name)) / (n - 1)
  }, by = .(court_id, judge_clean)]

  p <- cases[, .(
    avg_len = mean(get(loo_name)),
    conf = mean(get(var_name)),
    state_fips = first(state_fips)
  ), by = .(court_id, file_year = year(date_filed))]

  # Merge outcomes
  bds <- fread(file.path(DATA_DIR, "census_bds_state_annual.csv"))
  bds[, state_fips := as.character(state_fips)]
  p[, state_fips := as.character(state_fips)]
  bds_t1 <- bds[, .(state_fips, file_year = year - 1,
                     entry_t1 = estabs_entry)]
  p <- merge(p, bds_t1, by = c("state_fips", "file_year"), all.x = TRUE)
  p[, ln_entry_t1 := log(entry_t1 + 1)]

  fs_alt <- feols(conf ~ avg_len | court_id + file_year,
                  data = p, cluster = ~court_id)
  rf_alt <- feols(ln_entry_t1 ~ avg_len | court_id + file_year,
                  data = p[!is.na(ln_entry_t1)], cluster = ~court_id)

  cat(sprintf("Threshold %d days:\n", thresh))
  cat(sprintf("  First stage: Coef=%.3f, SE=%.3f, p=%.3f\n",
              coef(fs_alt)["avg_len"], se(fs_alt)["avg_len"],
              pvalue(fs_alt)["avg_len"]))
  cat(sprintf("  Reduced form → ln(Entry) t+1: Coef=%.4f, SE=%.4f, p=%.3f\n",
              coef(rf_alt)["avg_len"], se(rf_alt)["avg_len"],
              pvalue(rf_alt)["avg_len"]))
}

# -----------------------------------------------------------------------
# 4. Heterogeneity by baseline entry rate
# -----------------------------------------------------------------------

cat("\n--- Heterogeneity ---\n")

baseline <- panel[file_year %in% 2010:2012,
                  .(baseline_entry = mean(entry_rate_t0, na.rm = TRUE)),
                  by = court_id]
panel_het <- merge(panel, baseline, by = "court_id")
panel_het[, high_entry := as.integer(baseline_entry > median(baseline_entry))]

het1 <- feols(ln_entry_t1 ~ avg_leniency * i(high_entry) | court_id + file_year,
              data = panel_het[!is.na(ln_entry_t1)], cluster = ~court_id)
cat("Heterogeneity by baseline entry rate:\n")
print(summary(het1))

# -----------------------------------------------------------------------
# 5. Save results
# -----------------------------------------------------------------------

robustness <- list(
  balance = list(bal1 = bal1, bal2 = bal2),
  placebo = list(placebo_t0 = placebo_t0, placebo_emp = placebo_emp)
)
saveRDS(robustness, file.path(DATA_DIR, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
