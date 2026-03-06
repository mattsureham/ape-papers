# ==============================================================================
# 04_robustness.R — Robustness checks
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== Robustness Checks ===\n\n")

# --- R1: Standardized anomalies ---
cat("R1: Standardized anomalies\n")
panel[, tavg_z_x_ag := tavg_z * ag_emp_share]
r1 <- feols(climate_search ~ tavg_z + tavg_z_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)
summary(r1)

# --- R2: Quadratic temperature ---
cat("\nR2: Quadratic temperature\n")
panel[, tavg_sq := tavg_anomaly^2]
r2 <- feols(climate_search ~ tavg_anomaly + tavg_sq | state_id + time_id,
            data = panel, cluster = ~state_id)
summary(r2)

# --- R3: State-specific linear trends ---
cat("\nR3: State-specific trends\n")
panel[, state_trend := state_id * (year - 2004)]
r3 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag + state_trend |
              state_id + time_id,
            data = panel, cluster = ~state_id)
summary(r3)

# --- R4: Exclude Delhi ---
cat("\nR4: Exclude Delhi\n")
r4 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel[state != "Delhi"], cluster = ~state_id)
summary(r4)

# --- R5: Post-2010 (smartphone era) ---
cat("\nR5: Post-2010\n")
r5 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel[year >= 2010], cluster = ~state_id)
summary(r5)

# --- R6: Year FE instead of time FE ---
cat("\nR6: Year FE\n")
r6 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + year + month_of_year,
            data = panel, cluster = ~state_id)
summary(r6)

# --- R7: Extreme weather indicators ---
cat("\nR7: Extreme weather binary\n")
panel[, heat_x_ag := heat_extreme * ag_emp_share]
r7 <- feols(climate_search ~ heat_extreme + heat_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)
summary(r7)

# --- R8: Agricultural substitution robustness ---
cat("\nR8: Ag search with state trends\n")
r8 <- feols(agricultural ~ tavg_anomaly + tavg_x_ag + state_trend |
              state_id + time_id,
            data = panel, cluster = ~state_id)
summary(r8)

# --- R9: WCB inference ---
cat("\nR9: Wild Cluster Bootstrap\n")
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  m_main <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
                  data = panel, cluster = ~state_id)

  wcb_tavg <- boottest(m_main, param = "tavg_anomaly",
                        clustid = ~state_id, B = 9999, type = "webb")
  wcb_int <- boottest(m_main, param = "tavg_x_ag",
                       clustid = ~state_id, B = 9999, type = "webb")

  cat("WCB p-value (tavg):", wcb_tavg$p_val, "\n")
  cat("WCB p-value (interaction):", wcb_int$p_val, "\n")

  wcb_results <- data.table(
    param = c("tavg_anomaly", "tavg_x_ag"),
    wcb_pval = c(wcb_tavg$p_val, wcb_int$p_val),
    wcb_ci_lo = c(wcb_tavg$conf_int[1], wcb_int$conf_int[1]),
    wcb_ci_hi = c(wcb_tavg$conf_int[2], wcb_int$conf_int[2])
  )
  fwrite(wcb_results, file.path(data_dir, "wcb_results.csv"))
} else {
  cat("fwildclusterboot not available; using cluster-robust SEs.\n")
}

# Save robustness summary
rob_results <- data.table(
  spec = c("Standardized", "State trends", "Excl. Delhi",
           "Post-2010", "Year FE", "Extreme binary", "Ag search + trends"),
  interaction_coef = c(
    coef(r1)["tavg_z_x_ag"], coef(r3)["tavg_x_ag"],
    coef(r4)["tavg_x_ag"], coef(r5)["tavg_x_ag"],
    coef(r6)["tavg_x_ag"], coef(r7)["heat_x_ag"],
    coef(r8)["tavg_x_ag"]),
  interaction_se = c(
    se(r1)["tavg_z_x_ag"], se(r3)["tavg_x_ag"],
    se(r4)["tavg_x_ag"], se(r5)["tavg_x_ag"],
    se(r6)["tavg_x_ag"], se(r7)["heat_x_ag"],
    se(r8)["tavg_x_ag"]),
  n_obs = c(r1$nobs, r3$nobs, r4$nobs, r5$nobs, r6$nobs, r7$nobs, r8$nobs)
)
fwrite(rob_results, file.path(data_dir, "robustness_summary.csv"))

cat("\n=== Robustness complete ===\n")
