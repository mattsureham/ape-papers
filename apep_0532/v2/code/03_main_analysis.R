# ==============================================================================
# 03_main_analysis.R — Primary regressions
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================
# Main specification:
#   ClimateSearch_st = b1*TempAnom_st + b2*TempAnom_st × AgShare_s
#                      + alpha_s + delta_t + e_st
#
# KEY v2 ADDITION: substitution analysis showing that heat shocks in
# high-ag states increase agricultural search while decreasing climate search
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$state), "states\n\n")

# ==============================================================================
# TABLE 2: PRIMARY OLS — Temperature anomalies → Climate search
# ==============================================================================
cat("=== Table 2: Primary OLS ===\n\n")

# Model 1: Baseline
m1 <- feols(climate_search ~ tavg_anomaly | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 2: Add precipitation
m2 <- feols(climate_search ~ tavg_anomaly + precip_anomaly | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 3: MAIN — interaction with agricultural share
m3 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 4: Both temp and precip interactions
m4 <- feols(climate_search ~ tavg_anomaly + precip_anomaly +
              tavg_x_ag + precip_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 5: Log outcome
m5 <- feols(log_climate ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

# Model 6: Crop area share instead of emp share
m6 <- feols(climate_search ~ tavg_anomaly + tavg_x_crop | state_id + time_id,
            data = panel, cluster = ~state_id)

cat("M1 - Baseline:\n"); summary(m1)
cat("\nM3 - MAIN (interaction):\n"); summary(m3)
cat("\nM4 - Both interactions:\n"); summary(m4)
cat("\nM5 - Log outcome:\n"); summary(m5)

# ==============================================================================
# TABLE 3: SUBSTITUTION — Agricultural vs Climate search responses
# ==============================================================================
cat("\n=== Table 3: Attention Substitution ===\n\n")

# Climate search: should be POSITIVE tavg, NEGATIVE interaction (crowd-out)
s1 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

# Agricultural search: should show POSITIVE interaction (livelihood attention)
s2 <- feols(agricultural ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

# Placebo search: should be NULL for both
s3 <- feols(placebo ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

# Log versions
s4 <- feols(log_agricultural ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

cat("Substitution — Climate:\n"); summary(s1)
cat("\nSubstitution — Agricultural:\n"); summary(s2)
cat("\nSubstitution — Placebo:\n"); summary(s3)
cat("\nSubstitution — Log Agricultural:\n"); summary(s4)

# ==============================================================================
# TABLE 4: SEASONAL SPLIT (monsoon vs non-monsoon)
# ==============================================================================
cat("\n=== Table 4: Seasonal Split ===\n\n")

# Non-monsoon: weather perceived as anomalous, climate signal stronger
nm1 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
             data = panel[is_monsoon == 0], cluster = ~state_id)

# Monsoon: weather expected, livelihood concerns dominate
nm2 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
             data = panel[is_monsoon == 1], cluster = ~state_id)

# Hot season (March-May): heat waves most salient
nm3 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
             data = panel[is_hot_season == 1], cluster = ~state_id)

cat("Non-monsoon:\n"); summary(nm1)
cat("\nMonsoon:\n"); summary(nm2)
cat("\nHot season (Mar-May):\n"); summary(nm3)

# Agricultural substitution by season
cat("\n--- Ag search substitution by season ---\n")
nm4 <- feols(agricultural ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
             data = panel[is_monsoon == 1], cluster = ~state_id)
nm5 <- feols(agricultural ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
             data = panel[is_monsoon == 0], cluster = ~state_id)
cat("Ag search — Monsoon:\n"); summary(nm4)
cat("\nAg search — Non-monsoon:\n"); summary(nm5)

# ==============================================================================
# TABLE 5: PLACEBO TESTS
# ==============================================================================
cat("\n=== Table 5: Placebo Tests ===\n\n")

# Placebo outcome
p1 <- feols(placebo ~ tavg_anomaly | state_id + time_id,
            data = panel, cluster = ~state_id)

# Lead weather
p2 <- feols(climate_search ~ tavg_lead1 | state_id + time_id,
            data = panel[!is.na(tavg_lead1)], cluster = ~state_id)
p3 <- feols(climate_search ~ tavg_lead3 | state_id + time_id,
            data = panel[!is.na(tavg_lead3)], cluster = ~state_id)

cat("Placebo outcome:\n"); summary(p1)
cat("\nLead 1 month:\n"); summary(p2)
cat("\nLead 3 months:\n"); summary(p3)

# ==============================================================================
# PERSISTENCE (distributed lags)
# ==============================================================================
cat("\n=== Persistence ===\n\n")

dl1 <- feols(climate_search ~ tavg_anomaly + tavg_lag1 + tavg_lag3 +
               tavg_lag6 + tavg_lag12 | state_id + time_id,
             data = panel[!is.na(tavg_lag12)], cluster = ~state_id)
cat("Distributed lags:\n"); summary(dl1)

# ==============================================================================
# HETEROGENEITY — Internet penetration
# ==============================================================================
cat("\n=== Internet Heterogeneity ===\n\n")

panel[, high_internet := as.integer(internet_pen_2015 > median(internet_pen_2015, na.rm = TRUE))]

h1 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel[high_internet == 1], cluster = ~state_id)
h2 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel[high_internet == 0], cluster = ~state_id)

cat("High internet:\n"); summary(h1)
cat("\nLow internet:\n"); summary(h2)

# ==============================================================================
# SAVE ALL MODELS
# ==============================================================================
all_models <- list(
  # Primary
  ols_baseline = m1, ols_precip = m2, ols_main = m3,
  ols_both = m4, ols_log = m5, ols_crop = m6,
  # Substitution
  sub_climate = s1, sub_agricultural = s2, sub_placebo = s3,
  sub_ag_log = s4,
  # Seasonal
  seas_nonmonsoon = nm1, seas_monsoon = nm2, seas_hot = nm3,
  seas_ag_monsoon = nm4, seas_ag_nonmonsoon = nm5,
  # Placebo
  placebo_outcome = p1, placebo_lead1 = p2, placebo_lead3 = p3,
  # Persistence
  distributed_lags = dl1,
  # Internet het
  het_high_internet = h1, het_low_internet = h2
)

saveRDS(all_models, file.path(data_dir, "all_models.rds"))

# Save key coefficients to CSV for tables
key_results <- data.table(
  model = c("Climate (main)", "Agricultural", "Placebo",
            "Non-monsoon", "Monsoon", "Hot season"),
  tavg_coef = c(coef(s1)["tavg_anomaly"], coef(s2)["tavg_anomaly"],
                coef(s3)["tavg_anomaly"],
                coef(nm1)["tavg_anomaly"], coef(nm2)["tavg_anomaly"],
                coef(nm3)["tavg_anomaly"]),
  tavg_se = c(se(s1)["tavg_anomaly"], se(s2)["tavg_anomaly"],
              se(s3)["tavg_anomaly"],
              se(nm1)["tavg_anomaly"], se(nm2)["tavg_anomaly"],
              se(nm3)["tavg_anomaly"]),
  interaction_coef = c(coef(s1)["tavg_x_ag"], coef(s2)["tavg_x_ag"],
                       coef(s3)["tavg_x_ag"],
                       coef(nm1)["tavg_x_ag"], coef(nm2)["tavg_x_ag"],
                       coef(nm3)["tavg_x_ag"]),
  interaction_se = c(se(s1)["tavg_x_ag"], se(s2)["tavg_x_ag"],
                     se(s3)["tavg_x_ag"],
                     se(nm1)["tavg_x_ag"], se(nm2)["tavg_x_ag"],
                     se(nm3)["tavg_x_ag"]),
  n_obs = c(s1$nobs, s2$nobs, s3$nobs, nm1$nobs, nm2$nobs, nm3$nobs)
)
fwrite(key_results, file.path(data_dir, "key_results.csv"))

cat("\n=== Main analysis complete ===\n")
