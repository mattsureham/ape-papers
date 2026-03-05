# ==============================================================================
# 04_robustness.R — Robustness checks
# apep_0532: Extreme Weather and Climate Beliefs in India
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== Robustness Checks ===\n\n")

# --- R1: Alternative weather measures (precipitation focus) ---
cat("R1: Precipitation-focused specification\n")
r1 <- feols(climate_search ~ precip_anomaly + precip_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)
summary(r1)

# --- R2: Combined temp + precip with interactions ---
cat("\nR2: Combined weather + interactions\n")
r2 <- feols(climate_search ~ tavg_anomaly + precip_anomaly +
              tavg_x_ag + precip_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)
summary(r2)

# --- R3: Quadratic temperature ---
cat("\nR3: Quadratic temperature (nonlinear response)\n")
panel[, tavg_anomaly_sq := tavg_anomaly^2]
r3 <- feols(climate_search ~ tavg_anomaly + tavg_anomaly_sq | state_id + time_id,
            data = panel, cluster = ~state_id)
summary(r3)

# --- R4: State-specific linear trends ---
cat("\nR4: State-specific linear trends\n")
panel[, state_year_trend := state_id * (year - 2004)]
r4 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag + state_year_trend |
              state_id + time_id,
            data = panel, cluster = ~state_id)
summary(r4)

# --- R5: Exclude Delhi (outlier — high internet, low agriculture) ---
cat("\nR5: Excluding Delhi\n")
r5 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel[state != "Delhi"], cluster = ~state_id)
summary(r5)

# --- R6: Monsoon season only (June-September) ---
cat("\nR6: Monsoon season only\n")
r6 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel[month >= 6 & month <= 9], cluster = ~state_id)
summary(r6)

# --- R7: Non-monsoon season ---
cat("\nR7: Non-monsoon season\n")
r7 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel[month < 6 | month > 9], cluster = ~state_id)
summary(r7)

# --- R8: Post-2010 only (smartphone era) ---
cat("\nR8: Post-2010 (smartphone era)\n")
r8 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel[year >= 2010], cluster = ~state_id)
summary(r8)

# --- R9: Year FE instead of month-year FE ---
cat("\nR9: Year FE (less restrictive time controls)\n")
r9 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + year + month_of_year,
            data = panel, cluster = ~state_id)
summary(r9)

# Save robustness summary
rob_results <- data.table(
  spec = paste0("R", 1:9),
  description = c("Precipitation focus", "Combined weather", "Quadratic temp",
                  "State-specific trends", "Excl. Delhi", "Monsoon only",
                  "Non-monsoon", "Post-2010", "Year FE"),
  interaction_coef = c(NA, coef(r2)["tavg_x_ag"], NA,
                       coef(r4)["tavg_x_ag"], coef(r5)["tavg_x_ag"],
                       coef(r6)["tavg_x_ag"], coef(r7)["tavg_x_ag"],
                       coef(r8)["tavg_x_ag"], coef(r9)["tavg_x_ag"]),
  interaction_se = c(NA, se(r2)["tavg_x_ag"], NA,
                     se(r4)["tavg_x_ag"], se(r5)["tavg_x_ag"],
                     se(r6)["tavg_x_ag"], se(r7)["tavg_x_ag"],
                     se(r8)["tavg_x_ag"], se(r9)["tavg_x_ag"]),
  n_obs = c(r1$nobs, r2$nobs, r3$nobs, r4$nobs, r5$nobs,
            r6$nobs, r7$nobs, r8$nobs, r9$nobs)
)
fwrite(rob_results, file.path(data_dir, "robustness_results.csv"))

cat("\n=== Robustness checks complete ===\n")
