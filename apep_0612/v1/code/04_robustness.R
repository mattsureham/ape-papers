## 04_robustness.R — Placebos, balance tests, and robustness checks
## apep_0612: Immigration Judge Leniency and Local Crime

library(fixest)
library(tidyverse)
source("code/00_packages.R")

df <- readRDS("data/analysis.rds")
pn <- readRDS("data/panel.rds")
pn$year_f <- factor(pn$year)

# ===================================================================
# 1. Balance Test: Judge leniency should NOT predict demographics
# ===================================================================
cat("=== Balance Tests ===\n")
cat("If judge leniency is quasi-random, it should not predict state demographics.\n\n")

bal_pop <- feols(log_pop ~ state_judge_leniency, data = df, vcov = "HC1")
bal_pov <- feols(poverty_rate ~ state_judge_leniency, data = df, vcov = "HC1")
bal_for <- feols(pct_foreign ~ state_judge_leniency, data = df, vcov = "HC1")
bal_une <- feols(unemp_rate ~ state_judge_leniency, data = df, vcov = "HC1")
bal_inc <- feols(log(median_inc) ~ state_judge_leniency, data = df, vcov = "HC1")

cat("Balance test results (coef on judge leniency):\n")
print(etable(bal_pop, bal_pov, bal_for, bal_une, bal_inc, se = "HC1"))

# ===================================================================
# 2. Placebo Outcome: Suicide Rate (not plausibly related to immigration)
# ===================================================================
cat("\n=== Placebo: Suicide Rate ===\n")

if ("All_Suicide_avg_rate" %in% names(df) && sum(!is.na(df$All_Suicide_avg_rate)) > 10) {
  placebo_suicide_rf <- feols(All_Suicide_avg_rate ~ state_judge_leniency + log_pop +
                                pct_foreign + poverty_rate, data = df, vcov = "HC1")

  placebo_suicide_iv <- feols(All_Suicide_avg_rate ~ log_pop + pct_foreign + poverty_rate |
                                state_grant_rate ~ state_judge_leniency,
                              data = df, vcov = "HC1")

  cat("Suicide (placebo) results:\n")
  print(etable(placebo_suicide_rf, placebo_suicide_iv, se = "HC1"))
} else {
  cat("  Suicide data not available for placebo test.\n")
  placebo_suicide_rf <- NULL
  placebo_suicide_iv <- NULL
}

# ===================================================================
# 3. Alternative Outcomes: Firearm Homicide Only
# ===================================================================
cat("\n=== Alternative Outcome: Firearm Homicide ===\n")

if ("FA_Homicide_avg_rate" %in% names(df) && sum(!is.na(df$FA_Homicide_avg_rate)) > 10) {
  fa_rf <- feols(FA_Homicide_avg_rate ~ state_judge_leniency + log_pop + pct_foreign +
                   poverty_rate, data = df, vcov = "HC1")

  fa_iv <- feols(FA_Homicide_avg_rate ~ log_pop + pct_foreign + poverty_rate |
                   state_grant_rate ~ state_judge_leniency,
                 data = df, vcov = "HC1")

  cat("Firearm homicide results:\n")
  print(etable(fa_rf, fa_iv, se = "HC1"))
} else {
  cat("  Firearm homicide data not available.\n")
  fa_rf <- NULL
  fa_iv <- NULL
}

# ===================================================================
# 4. Sensitivity: Alternative Control Sets
# ===================================================================
cat("\n=== Sensitivity to Controls ===\n")

# Minimal: no controls
sens_1 <- feols(All_Homicide_avg_rate ~ 1 | state_grant_rate ~ state_judge_leniency,
                data = df, vcov = "HC1")

# + population only
sens_2 <- feols(All_Homicide_avg_rate ~ log_pop |
                  state_grant_rate ~ state_judge_leniency,
                data = df, vcov = "HC1")

# + demographics, no region FE
sens_3 <- feols(All_Homicide_avg_rate ~ log_pop + pct_foreign + poverty_rate |
                  state_grant_rate ~ state_judge_leniency,
                data = df, vcov = "HC1")

# Full: + region FE
sens_4 <- feols(All_Homicide_avg_rate ~ log_pop + pct_foreign + poverty_rate |
                  region | state_grant_rate ~ state_judge_leniency,
                data = df, vcov = "HC1")

# + unemployment
sens_5 <- feols(All_Homicide_avg_rate ~ log_pop + pct_foreign + poverty_rate + unemp_rate |
                  region | state_grant_rate ~ state_judge_leniency,
                data = df, vcov = "HC1")

cat("Sensitivity analysis:\n")
print(etable(sens_1, sens_2, sens_3, sens_4, sens_5, se = "HC1"))

# ===================================================================
# 5. Heterogeneity: High vs Low Immigration States
# ===================================================================
cat("\n=== Heterogeneity: High vs Low Immigration States ===\n")

med_foreign <- median(df$pct_foreign, na.rm = TRUE)
df$high_immigration <- df$pct_foreign > med_foreign

het_high <- feols(All_Homicide_avg_rate ~ log_pop + poverty_rate |
                    state_grant_rate ~ state_judge_leniency,
                  data = df[df$high_immigration, ], vcov = "HC1")

het_low <- feols(All_Homicide_avg_rate ~ log_pop + poverty_rate |
                   state_grant_rate ~ state_judge_leniency,
                 data = df[!df$high_immigration, ], vcov = "HC1")

cat("High immigration states:\n")
tryCatch(print(etable(het_high)), error = function(e) cat(sprintf("  Error: %s\n", e$message)))
cat("\nLow immigration states:\n")
tryCatch(print(etable(het_low)), error = function(e) cat(sprintf("  Error: %s\n", e$message)))

# ===================================================================
# 6. Heterogeneity: Region-level analysis
# ===================================================================
cat("\n=== Heterogeneity by Region ===\n")

for (reg in unique(df$region)) {
  sub <- df[df$region == reg, ]
  if (nrow(sub) >= 5) {
    tryCatch({
      m <- feols(All_Homicide_avg_rate ~ log_pop |
                   state_grant_rate ~ state_judge_leniency,
                 data = sub, vcov = "HC1")
      cat(sprintf("  %s (n=%d): coef=%.3f, se=%.3f\n",
                  reg, nrow(sub), coef(m)["fit_state_grant_rate"],
                  se(m)["fit_state_grant_rate"]))
    }, error = function(e) {
      cat(sprintf("  %s: insufficient variation (%s)\n", reg, e$message))
    })
  }
}

# ===================================================================
# 7. Panel-level placebo: suicide
# ===================================================================
cat("\n=== Panel Placebo: Suicide Rate ===\n")

pn_placebo_suicide <- tryCatch(
  feols(All_Suicide_rate ~ log_pop + pct_foreign + poverty_rate |
          year_f + region | state_grant_rate ~ state_judge_leniency,
        data = pn, vcov = ~state_abb),
  error = function(e) { cat(sprintf("  Error: %s\n", e$message)); NULL }
)

if (!is.null(pn_placebo_suicide)) {
  cat("Panel suicide placebo:\n")
  print(etable(pn_placebo_suicide))
}

# ===================================================================
# 8. Save robustness results
# ===================================================================

robustness <- list(
  balance    = list(bal_pop, bal_pov, bal_for, bal_une, bal_inc),
  placebo    = list(suicide_rf = placebo_suicide_rf, suicide_iv = placebo_suicide_iv),
  alt_outcome = list(fa_rf = fa_rf, fa_iv = fa_iv),
  sensitivity = list(sens_1, sens_2, sens_3, sens_4, sens_5),
  heterogeneity = list(high = het_high, low = het_low),
  panel_placebo = pn_placebo_suicide
)

saveRDS(robustness, "data/robustness.rds")

cat("\n=== Robustness checks complete ===\n")
