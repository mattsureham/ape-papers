# ==============================================================================
# 03_main_analysis.R — Primary regressions
# apep_0532: Extreme Weather and Climate Beliefs in India
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$state), "states\n\n")

# ==============================================================================
# TABLE 1: OLS — Temperature anomalies → Climate search interest
# ==============================================================================
cat("=== Table 1: OLS Regressions ===\n\n")

# Model 1: Baseline — tavg anomaly on climate search, state + time FE
m1 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 2: Add precipitation anomaly
m2 <- feols(climate_search ~ tavg_anomaly + precip_anomaly | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 3: Standardized anomalies
m3 <- feols(climate_search ~ tavg_z + precip_z | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 4: Extreme weather indicators
m4 <- feols(climate_search ~ heat_extreme + drought + flood | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 5: Interaction with agricultural share (Bartik mechanism)
m5 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 6: Log outcome
m6 <- feols(log_climate ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

cat("Model 1 - Baseline:\n")
summary(m1)
cat("\nModel 2 - Temp + Precip:\n")
summary(m2)
cat("\nModel 3 - Standardized:\n")
summary(m3)
cat("\nModel 4 - Extreme indicators:\n")
summary(m4)
cat("\nModel 5 - Interaction with ag share:\n")
summary(m5)
cat("\nModel 6 - Log outcome:\n")
summary(m6)

# Save results for tables
table1_results <- data.table(
  model = paste0("m", 1:6),
  dep_var = c(rep("Climate Search", 5), "Log Climate Search"),
  tavg_coef = c(coef(m1)["tavg_anomaly"], coef(m2)["tavg_anomaly"],
                NA, NA, coef(m5)["tavg_anomaly"], coef(m6)["tavg_anomaly"]),
  tavg_se = c(se(m1)["tavg_anomaly"], se(m2)["tavg_anomaly"],
              NA, NA, se(m5)["tavg_anomaly"], se(m6)["tavg_anomaly"]),
  n_obs = sapply(list(m1, m2, m3, m4, m5, m6), function(x) x$nobs),
  r2_within = sapply(list(m1, m2, m3, m4, m5, m6), function(x) fitstat(x, "r2")[[1]])
)
fwrite(table1_results, file.path(data_dir, "table1_ols.csv"))

# ==============================================================================
# TABLE 2: BARTIK IV — Instrumented weather → Climate search
# ==============================================================================
cat("\n=== Table 2: Bartik IV Regressions ===\n\n")

# IV Model 1: Instrument tavg_anomaly with bartik_tavg
iv1 <- feols(climate_search ~ 1 | state_id + time_id |
               tavg_anomaly ~ bartik_tavg,
             data = panel, cluster = ~state_id)

# IV Model 2: Instrument both temp and precip
iv2 <- feols(climate_search ~ 1 | state_id + time_id |
               tavg_anomaly + precip_anomaly ~ bartik_tavg + bartik_precip,
             data = panel, cluster = ~state_id)

# IV Model 3: Log outcome
iv3 <- feols(log_climate ~ 1 | state_id + time_id |
               tavg_anomaly ~ bartik_tavg,
             data = panel, cluster = ~state_id)

cat("IV Model 1 - Bartik temp:\n")
summary(iv1, stage = 1:2)
cat("\nIV Model 2 - Bartik temp + precip:\n")
summary(iv2, stage = 1:2)

# First stage F-stats
cat("\nFirst-stage diagnostics:\n")
fs1 <- fitstat(iv1, "ivf")
cat("  IV1 F-stat:", unlist(fs1)[1], "\n")

# Save IV results
iv_results <- data.table(
  model = paste0("iv", 1:3),
  fs_fstat = c(fs1[[1]], NA, NA),
  n_obs = sapply(list(iv1, iv2, iv3), function(x) x$nobs)
)
fwrite(iv_results, file.path(data_dir, "table2_iv.csv"))

# ==============================================================================
# TABLE 3: PLACEBO TESTS
# ==============================================================================
cat("\n=== Table 3: Placebo Tests ===\n\n")

# Placebo outcome: Cricket/Bollywood search interest
p1 <- feols(placebo_search ~ tavg_anomaly | state_id + time_id,
            data = panel, cluster = ~state_id)

# Placebo treatment: Lead weather (future weather shouldn't predict current search)
p2 <- feols(climate_search ~ tavg_lead1 | state_id + time_id,
            data = panel[!is.na(tavg_lead1)], cluster = ~state_id)

p3 <- feols(climate_search ~ tavg_lead3 | state_id + time_id,
            data = panel[!is.na(tavg_lead3)], cluster = ~state_id)

cat("Placebo 1 - Non-climate search:\n")
summary(p1)
cat("\nPlacebo 2 - Lead weather (1 month):\n")
summary(p2)
cat("\nPlacebo 3 - Lead weather (3 months):\n")
summary(p3)

placebo_results <- data.table(
  test = c("Non-climate outcome", "Lead 1 month", "Lead 3 months"),
  coef = c(coef(p1)["tavg_anomaly"], coef(p2)["tavg_lead1"], coef(p3)["tavg_lead3"]),
  se = c(se(p1)["tavg_anomaly"], se(p2)["tavg_lead1"], se(p3)["tavg_lead3"]),
  pval = c(fixest::pvalue(p1)["tavg_anomaly"], fixest::pvalue(p2)["tavg_lead1"],
           fixest::pvalue(p3)["tavg_lead3"])
)
fwrite(placebo_results, file.path(data_dir, "table3_placebo.csv"))

# ==============================================================================
# TABLE 4: PERSISTENCE — Distributed lag model
# ==============================================================================
cat("\n=== Table 4: Persistence (Distributed Lags) ===\n\n")

# Distributed lag: contemporaneous + lags at 1, 3, 6, 12 months
dl1 <- feols(climate_search ~ tavg_anomaly + tavg_lag1 + tavg_lag3 +
               tavg_lag6 + tavg_lag12 | state_id + time_id,
             data = panel[!is.na(tavg_lag12)], cluster = ~state_id)

cat("Distributed lag model:\n")
summary(dl1)

lag_results <- data.table(
  lag = c(0, 1, 3, 6, 12),
  coef = coef(dl1)[c("tavg_anomaly", "tavg_lag1", "tavg_lag3",
                       "tavg_lag6", "tavg_lag12")],
  se = se(dl1)[c("tavg_anomaly", "tavg_lag1", "tavg_lag3",
                   "tavg_lag6", "tavg_lag12")]
)
lag_results[, ci_lo := coef - 1.96 * se]
lag_results[, ci_hi := coef + 1.96 * se]
fwrite(lag_results, file.path(data_dir, "table4_persistence.csv"))

# ==============================================================================
# TABLE 5: HETEROGENEITY
# ==============================================================================
cat("\n=== Table 5: Heterogeneity ===\n\n")

# By internet penetration
panel[, high_internet := as.integer(internet_pen_2015 > median(internet_pen_2015, na.rm = TRUE))]

h1 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel[high_internet == 1], cluster = ~state_id)
h2 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel[high_internet == 0], cluster = ~state_id)

# By agricultural share
panel[, high_ag := as.integer(ag_share > median(ag_share, na.rm = TRUE))]

h3 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel[high_ag == 1], cluster = ~state_id)
h4 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel[high_ag == 0], cluster = ~state_id)

cat("High internet states:\n"); summary(h1)
cat("\nLow internet states:\n"); summary(h2)
cat("\nHigh agricultural states:\n"); summary(h3)
cat("\nLow agricultural states:\n"); summary(h4)

het_results <- data.table(
  group = c("High Internet", "Low Internet", "High Agriculture", "Low Agriculture"),
  coef = c(coef(h1)["tavg_anomaly"], coef(h2)["tavg_anomaly"],
           coef(h3)["tavg_anomaly"], coef(h4)["tavg_anomaly"]),
  se = c(se(h1)["tavg_anomaly"], se(h2)["tavg_anomaly"],
         se(h3)["tavg_anomaly"], se(h4)["tavg_anomaly"]),
  n_obs = c(h1$nobs, h2$nobs, h3$nobs, h4$nobs)
)
fwrite(het_results, file.path(data_dir, "table5_heterogeneity.csv"))

cat("\n=== All main analysis complete ===\n")
