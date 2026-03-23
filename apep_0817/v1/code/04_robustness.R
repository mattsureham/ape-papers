## 04_robustness.R — Robustness checks and placebos
## APEP Working Paper apep_0817

source("00_packages.R")

cat("=== Robustness Checks ===\n")

analysis_city <- readRDS("../data/analysis_city.rds")
analysis_disaster <- readRDS("../data/analysis_disaster.rds")

# ============================================================
# 1. Exclude major hurricanes
# ============================================================
cat("\n1. Excluding major hurricanes...\n")

rob_no_major <- feols(log_ihp_per_reg ~ log_damage |
                        year + incidentType |
                        declaration_lag ~ concurrent_disasters,
                      data = analysis_city |>
                        filter(!major_hurricane, is.finite(log_ihp_per_reg)),
                      vcov = ~disasterNumber)
cat(sprintf("  IV without major hurricanes: coef=%.5f, SE=%.5f, t=%.2f (N=%d)\n",
            coef(rob_no_major)["fit_declaration_lag"],
            se(rob_no_major)["fit_declaration_lag"],
            tstat(rob_no_major)["fit_declaration_lag"],
            rob_no_major$nobs))

# ============================================================
# 2. Alternative IV: recent declarations (60-day window)
# ============================================================
cat("\n2. Alternative IV (recent declarations)...\n")

rob_alt_iv <- feols(log_ihp_per_reg ~ log_damage |
                      year + incidentType |
                      declaration_lag ~ recent_declarations,
                    data = analysis_city |> filter(is.finite(log_ihp_per_reg)),
                    vcov = ~disasterNumber)
cat(sprintf("  Alt IV: coef=%.5f, SE=%.5f, t=%.2f, 1st F=%.1f\n",
            coef(rob_alt_iv)["fit_declaration_lag"],
            se(rob_alt_iv)["fit_declaration_lag"],
            tstat(rob_alt_iv)["fit_declaration_lag"],
            fitstat(rob_alt_iv, "ivf")$ivf1$stat))

# ============================================================
# 3. Heterogeneity by disaster type
# ============================================================
cat("\n3. By disaster type...\n")

for (dtype in c("Hurricane", "Flood", "Severe Storm")) {
  sub <- analysis_city |>
    filter(incidentType == dtype, is.finite(log_ihp_per_reg))
  if (n_distinct(sub$disasterNumber) < 10) {
    cat(sprintf("  %s: too few disasters (%d), skipping\n",
                dtype, n_distinct(sub$disasterNumber)))
    next
  }

  rob_type <- feols(log_ihp_per_reg ~ log_damage |
                      year |
                      declaration_lag ~ concurrent_disasters,
                    data = sub, vcov = ~disasterNumber)
  cat(sprintf("  %s (N=%d, %d disasters): coef=%.5f, SE=%.5f, t=%.2f\n",
              dtype, nrow(sub), n_distinct(sub$disasterNumber),
              coef(rob_type)["fit_declaration_lag"],
              se(rob_type)["fit_declaration_lag"],
              tstat(rob_type)["fit_declaration_lag"]))
}

# ============================================================
# 4. Placebo: fire management assistance declarations (no IHP)
# ============================================================
cat("\n4. Placebo: non-IHP declarations...\n")

# Use disaster damage as the outcome — declaration lag shouldn't predict it
# after controlling for type (damage is pre-determined, not caused by lag)
rob_placebo <- feols(log_mean_damage ~ declaration_lag + is_hurricane + is_flood |
                       year,
                     data = analysis_disaster, vcov = "hetero")
cat(sprintf("  Placebo (lag → damage): coef=%.5f, SE=%.5f, t=%.2f\n",
            coef(rob_placebo)["declaration_lag"],
            se(rob_placebo)["declaration_lag"],
            tstat(rob_placebo)["declaration_lag"]))

# ============================================================
# 5. Nonlinear lag specification (quartiles)
# ============================================================
cat("\n5. Lag quartile effects...\n")

analysis_city <- analysis_city |>
  mutate(lag_quartile = ntile(declaration_lag, 4),
         lag_q = factor(lag_quartile))

rob_quartile <- feols(log_ihp_per_reg ~ lag_q + log_damage |
                        year + incidentType,
                      data = analysis_city |> filter(is.finite(log_ihp_per_reg)),
                      vcov = ~disasterNumber)
cat("  Lag quartile effects (base=Q1, shortest lag):\n")
for (q in c("2", "3", "4")) {
  cat(sprintf("    Q%s: coef=%.4f, SE=%.4f, t=%.2f\n",
              q,
              coef(rob_quartile)[paste0("lag_q", q)],
              se(rob_quartile)[paste0("lag_q", q)],
              tstat(rob_quartile)[paste0("lag_q", q)]))
}

# ============================================================
# 6. Exclude COVID-era biological disasters
# ============================================================
cat("\n6. Excluding biological disasters (COVID)...\n")

rob_no_covid <- feols(log_ihp_per_reg ~ log_damage |
                        year + incidentType |
                        declaration_lag ~ concurrent_disasters,
                      data = analysis_city |>
                        filter(incidentType != "Biological",
                               is.finite(log_ihp_per_reg)),
                      vcov = ~disasterNumber)
cat(sprintf("  IV without COVID: coef=%.5f, SE=%.5f, t=%.2f (N=%d)\n",
            coef(rob_no_covid)["fit_declaration_lag"],
            se(rob_no_covid)["fit_declaration_lag"],
            tstat(rob_no_covid)["fit_declaration_lag"],
            rob_no_covid$nobs))

# ============================================================
# 7. Balance test: concurrent disasters vs pre-determined covariates
# ============================================================
cat("\n7. Balance test on pre-determined covariates...\n")

bal_type <- feols(is_hurricane ~ concurrent_disasters | year,
                  data = analysis_disaster, vcov = "hetero")
bal_flood <- feols(is_flood ~ concurrent_disasters | year,
                   data = analysis_disaster, vcov = "hetero")
bal_damage <- feols(log_mean_damage ~ concurrent_disasters | year,
                    data = analysis_disaster, vcov = "hetero")
bal_counties <- feols(n_counties ~ concurrent_disasters | year,
                      data = analysis_disaster, vcov = "hetero")

cat(sprintf("  Hurricane:   coef=%.5f, SE=%.5f, t=%.2f\n",
            coef(bal_type)["concurrent_disasters"],
            se(bal_type)["concurrent_disasters"],
            tstat(bal_type)["concurrent_disasters"]))
cat(sprintf("  Flood:       coef=%.5f, SE=%.5f, t=%.2f\n",
            coef(bal_flood)["concurrent_disasters"],
            se(bal_flood)["concurrent_disasters"],
            tstat(bal_flood)["concurrent_disasters"]))
cat(sprintf("  Damage:      coef=%.5f, SE=%.5f, t=%.2f\n",
            coef(bal_damage)["concurrent_disasters"],
            se(bal_damage)["concurrent_disasters"],
            tstat(bal_damage)["concurrent_disasters"]))
cat(sprintf("  Counties:    coef=%.5f, SE=%.5f, t=%.2f\n",
            coef(bal_counties)["concurrent_disasters"],
            se(bal_counties)["concurrent_disasters"],
            tstat(bal_counties)["concurrent_disasters"]))

# ============================================================
# Save robustness results
# ============================================================
cat("\n=== Saving robustness results ===\n")

robustness <- list(
  no_major = rob_no_major,
  alt_iv = rob_alt_iv,
  placebo = rob_placebo,
  quartile = rob_quartile,
  no_covid = rob_no_covid,
  balance = list(hurricane = bal_type, flood = bal_flood,
                 damage = bal_damage, counties = bal_counties)
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("Robustness checks complete.\n")
