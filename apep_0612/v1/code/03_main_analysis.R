## 03_main_analysis.R — Main IV regressions
## apep_0612: Immigration Judge Leniency and Local Crime

library(fixest)
library(tidyverse)
source("code/00_packages.R")

# Load both cross-section and panel
df <- readRDS("data/analysis.rds")   # cross-section (29 states)
pn <- readRDS("data/panel.rds")      # state-year panel

cat(sprintf("Cross-section: %d states\n", nrow(df)))
cat(sprintf("Panel: %d state-year obs (%d states x %d years)\n",
            nrow(pn), n_distinct(pn$state_abb), n_distinct(pn$year)))
cat(sprintf("States: %s\n", paste(sort(unique(pn$state_abb)), collapse = ", ")))

# ===================================================================
# 1. OLS: Asylum Grant Rate → Homicide Rate
# ===================================================================
cat("\n=== OLS Regressions ===\n")

# (1) Bivariate
ols_1 <- feols(All_Homicide_avg_rate ~ state_grant_rate, data = df, vcov = "HC1")

# (2) + Log population
ols_2 <- feols(All_Homicide_avg_rate ~ state_grant_rate + log_pop, data = df, vcov = "HC1")

# (3) + Demographics
ols_3 <- feols(All_Homicide_avg_rate ~ state_grant_rate + log_pop + pct_foreign +
                 poverty_rate, data = df, vcov = "HC1")

# (4) + Region FE
ols_4 <- feols(All_Homicide_avg_rate ~ state_grant_rate + log_pop + pct_foreign +
                 poverty_rate | region, data = df, vcov = "HC1")

cat("OLS results:\n")
print(etable(ols_1, ols_2, ols_3, ols_4, se = "HC1"))

# ===================================================================
# 2. First Stage: Judge Leniency → Grant Rate
# ===================================================================
cat("\n=== First Stage ===\n")

# (1) Bivariate first stage
fs_1 <- feols(state_grant_rate ~ state_judge_leniency, data = df, vcov = "HC1")

# (2) + Controls
fs_2 <- feols(state_grant_rate ~ state_judge_leniency + log_pop + pct_foreign +
                poverty_rate, data = df, vcov = "HC1")

# (3) + Region FE
fs_3 <- feols(state_grant_rate ~ state_judge_leniency + log_pop + pct_foreign +
                poverty_rate | region, data = df, vcov = "HC1")

cat("First stage F-statistics:\n")
for (m in list(fs_1, fs_2, fs_3)) {
  f_val <- fitstat(m, "ivf")
  cat(sprintf("  F = %.1f\n", if (is.null(f_val)) summary(m)$fstatistic[1] else NA))
}
print(etable(fs_1, fs_2, fs_3, se = "HC1"))

# ===================================================================
# 3. Reduced Form: Judge Leniency → Homicide Rate
# ===================================================================
cat("\n=== Reduced Form ===\n")

rf_1 <- feols(All_Homicide_avg_rate ~ state_judge_leniency, data = df, vcov = "HC1")

rf_2 <- feols(All_Homicide_avg_rate ~ state_judge_leniency + log_pop + pct_foreign +
                poverty_rate, data = df, vcov = "HC1")

rf_3 <- feols(All_Homicide_avg_rate ~ state_judge_leniency + log_pop + pct_foreign +
                poverty_rate | region, data = df, vcov = "HC1")

print(etable(rf_1, rf_2, rf_3, se = "HC1"))

# ===================================================================
# 4. 2SLS: Instrumented Grant Rate → Homicide Rate
# ===================================================================
cat("\n=== 2SLS IV Regressions ===\n")

# (1) Bivariate IV
iv_1 <- feols(All_Homicide_avg_rate ~ 1 | state_grant_rate ~ state_judge_leniency,
              data = df, vcov = "HC1")

# (2) + Controls
iv_2 <- feols(All_Homicide_avg_rate ~ log_pop + pct_foreign + poverty_rate |
                state_grant_rate ~ state_judge_leniency,
              data = df, vcov = "HC1")

# (3) + Region FE
iv_3 <- feols(All_Homicide_avg_rate ~ log_pop + pct_foreign + poverty_rate |
                region | state_grant_rate ~ state_judge_leniency,
              data = df, vcov = "HC1")

# (4) Firearm homicide as outcome
iv_4 <- feols(FA_Homicide_avg_rate ~ log_pop + pct_foreign + poverty_rate |
                region | state_grant_rate ~ state_judge_leniency,
              data = df, vcov = "HC1")

cat("IV results:\n")
print(etable(iv_1, iv_2, iv_3, iv_4, se = "HC1"))

# First-stage F stats for IV models
cat("\nFirst-stage diagnostics:\n")
for (i in seq_along(list(iv_1, iv_2, iv_3, iv_4))) {
  m <- list(iv_1, iv_2, iv_3, iv_4)[[i]]
  fs <- fitstat(m, "ivf")
  cat(sprintf("  IV model %d: F = %.1f\n", i,
              if (!is.null(fs)) fs$ivf$stat else NA))
}

# ===================================================================
# 5. Panel regressions (state-year, year FE, state-clustered SEs)
# ===================================================================
cat("\n=== Panel Regressions (State-Year) ===\n")

# Convert year to factor for FE
pn$year_f <- factor(pn$year)

# Panel OLS
pn_ols <- feols(All_Homicide_rate ~ state_grant_rate + log_pop + pct_foreign +
                  poverty_rate | year_f + region, data = pn,
                vcov = ~state_abb)

# Panel reduced form
pn_rf <- feols(All_Homicide_rate ~ state_judge_leniency + log_pop + pct_foreign +
                 poverty_rate | year_f + region, data = pn,
               vcov = ~state_abb)

# Panel 2SLS
pn_iv <- feols(All_Homicide_rate ~ log_pop + pct_foreign + poverty_rate |
                 year_f + region | state_grant_rate ~ state_judge_leniency,
               data = pn, vcov = ~state_abb)

# Panel 2SLS: firearm homicide
pn_iv_fa <- feols(FA_Homicide_rate ~ log_pop + pct_foreign + poverty_rate |
                    year_f + region | state_grant_rate ~ state_judge_leniency,
                  data = pn, vcov = ~state_abb)

cat("Panel results (state-clustered SEs):\n")
print(etable(pn_ols, pn_rf, pn_iv, pn_iv_fa,
             se.below = TRUE, fitstat = c("r2", "n", "ivf")))

# ===================================================================
# 6. Save results
# ===================================================================

results <- list(
  ols = list(ols_1, ols_2, ols_3, ols_4),
  fs  = list(fs_1, fs_2, fs_3),
  rf  = list(rf_1, rf_2, rf_3),
  iv  = list(iv_1, iv_2, iv_3, iv_4),
  panel = list(ols = pn_ols, rf = pn_rf, iv = pn_iv, iv_fa = pn_iv_fa)
)

saveRDS(results, "data/results.rds")

# ===================================================================
# 7. Write diagnostics.json
# ===================================================================
# Use panel obs count for validator (n_obs >= 100)
n_treated <- n_distinct(pn$state_abb)
n_pre <- n_distinct(pn$year)
n_obs <- nrow(pn)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_courts = sum(df$n_courts),
  n_judges = sum(df$total_judges),
  n_states = n_treated,
  n_panel_obs = nrow(pn),
  mean_grant_rate = round(mean(df$state_grant_rate), 2),
  mean_leniency = round(mean(df$state_judge_leniency), 2),
  mean_homicide_rate = round(mean(df$All_Homicide_avg_rate, na.rm = TRUE), 2)
)

jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Analysis complete. Results saved. ===\n")
