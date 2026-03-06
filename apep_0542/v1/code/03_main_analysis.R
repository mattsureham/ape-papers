# ==============================================================================
# 03_main_analysis.R — Main DiD regressions and event study
# Paper: When the Train Doesn't Come (apep_0542)
# ==============================================================================

source("code/00_packages.R")

df <- fread(file.path(DATA_DIR, "analysis_main.csv"))
cat("Analysis sample:", nrow(df), "transactions\n")

# Convert factors
df[, prop_type := factor(property_type,
                          levels = c("D", "S", "T", "F", "O"),
                          labels = c("Detached", "Semi", "Terraced", "Flat", "Other"))]
df[, yq_factor := factor(year_quarter)]
df[, pc_fe := factor(postcode_clean)]

# ==============================================================================
# Model 1: Baseline DiD — Phase 2 vs rest of sample
# ==============================================================================

cat("\n=== MODEL 1: Baseline DiD (5km ring) ===\n")
m1 <- feols(
  log_price ~ near_station_5km:post + new_build |
    postcode_clean + yq_factor,
  data = df,
  cluster = ~la_code
)
summary(m1)

# Distance rings: 2km, 5km, 10km
cat("\n=== MODEL 1b: Distance rings ===\n")
m1_2km <- feols(
  log_price ~ near_station_2km:post + new_build |
    postcode_clean + yq_factor,
  data = df,
  cluster = ~la_code
)

m1_10km <- feols(
  log_price ~ near_station_10km:post + new_build |
    postcode_clean + yq_factor,
  data = df,
  cluster = ~la_code
)

# ==============================================================================
# Model 2: Within-project control — Phase 2 vs Phase 1
# ==============================================================================

cat("\n=== MODEL 2: Phase 2 vs Phase 1 (within-project control) ===\n")
# Restrict to properties within 10km of either Phase 1 or Phase 2 stations
df_hs2 <- df[near_station_10km == 1 | near_phase1_10km == 1]
df_hs2[, treated := as.integer(near_station_10km == 1 & near_phase1_10km == 0)]

m2 <- feols(
  log_price ~ treated:post + new_build |
    postcode_clean + yq_factor,
  data = df_hs2,
  cluster = ~la_code
)
summary(m2)

# ==============================================================================
# Model 3: Continuous distance treatment
# ==============================================================================

cat("\n=== MODEL 3: Continuous distance ===\n")
# Use inverse distance (1/km) for dose-response
df[, inv_dist_p2 := 1 / pmax(dist_phase2_km, 0.5)]  # Floor at 0.5km

m3 <- feols(
  log_price ~ inv_dist_p2:post + new_build |
    postcode_clean + yq_factor,
  data = df[dist_phase2_km <= 30],
  cluster = ~la_code
)
summary(m3)

# ==============================================================================
# Model 4: Event study — quarterly treatment effects
# ==============================================================================

cat("\n=== MODEL 4: Event study (5km ring) ===\n")

# Create event-time dummies (relative to Q3 2023, the last pre-period quarter)
# Event quarter: Q4 2023 = 0, Q1 2024 = 1, ..., Q3 2023 = -1, Q2 2023 = -2, etc.
# Drop Q3 2023 (event_quarter == -1) as reference
df[, eq := event_quarter]
df[, eq_factor := factor(eq)]

# Keep quarters -19 to +4 (Q1 2019 to Q4 2024)
df_es <- df[eq >= -19 & eq <= 4]

# Interaction of treatment with event-time dummies (drop -1 as reference)
m4 <- feols(
  log_price ~ i(eq, near_station_5km, ref = -1) + new_build |
    postcode_clean + yq_factor,
  data = df_es,
  cluster = ~la_code
)
summary(m4)

# Extract event-study coefficients for figures
es_coefs <- as.data.table(coeftable(m4))
es_coefs[, term := rownames(coeftable(m4))]
# Parse event quarter from term
es_coefs[, eq_num := as.integer(str_extract(term, "-?\\d+"))]
es_coefs <- es_coefs[!is.na(eq_num)]
setnames(es_coefs, c("estimate", "se", "tstat", "pval", "term", "eq_num"))

# Add reference period
es_coefs <- rbind(
  es_coefs,
  data.table(estimate = 0, se = 0, tstat = 0, pval = 1,
             term = "ref", eq_num = -1)
)
setorder(es_coefs, eq_num)

# Convert to calendar quarter labels
es_coefs[, calendar_q := paste0(2023 + floor((eq_num + 4) / 4),
                                 "-Q", ((eq_num + 4 - 1) %% 4) + 1)]

fwrite(es_coefs, file.path(DATA_DIR, "event_study_coefs.csv"))

# ==============================================================================
# Model 5: Station-level heterogeneity
# ==============================================================================

cat("\n=== MODEL 5: Heterogeneity by nearest cancelled station ===\n")
# Only for properties near Phase 2 stations
df_near <- df[near_station_5km == 1]
df_near[, station_f := factor(nearest_phase2)]

# Add control sample with NA station_f
df_control_sample <- df[near_station_5km == 0][sample(.N, min(.N, 200000))]
df_control_sample[, station_f := NA_character_]
df_control_sample[, station_f := factor(station_f, levels = levels(df_near$station_f))]

m5 <- feols(
  log_price ~ i(station_f, post) + new_build |
    postcode_clean + yq_factor,
  data = rbind(df_near, df_control_sample, fill = TRUE),
  cluster = ~la_code
)
summary(m5)

# Save station-level coefficients
station_coefs <- as.data.table(coeftable(m5))
station_coefs[, term := rownames(coeftable(m5))]
station_coefs <- station_coefs[grepl("station_f", term)]
setnames(station_coefs, c("estimate", "se", "tstat", "pval", "term"))
fwrite(station_coefs, file.path(DATA_DIR, "station_heterogeneity.csv"))

# ==============================================================================
# Model 6: Property type heterogeneity
# ==============================================================================

cat("\n=== MODEL 6: Property type heterogeneity ===\n")
m6_det <- feols(log_price ~ near_station_5km:post + new_build |
                  postcode_clean + yq_factor,
                data = df[prop_type == "Detached"], cluster = ~la_code)
m6_semi <- feols(log_price ~ near_station_5km:post + new_build |
                   postcode_clean + yq_factor,
                 data = df[prop_type == "Semi"], cluster = ~la_code)
m6_terr <- feols(log_price ~ near_station_5km:post + new_build |
                   postcode_clean + yq_factor,
                 data = df[prop_type == "Terraced"], cluster = ~la_code)
m6_flat <- feols(log_price ~ near_station_5km:post + new_build |
                   postcode_clean + yq_factor,
                 data = df[prop_type == "Flat"], cluster = ~la_code)

prop_het <- data.table(
  property_type = c("Detached", "Semi-detached", "Terraced", "Flat"),
  estimate = c(coef(m6_det)["near_station_5km:post"],
               coef(m6_semi)["near_station_5km:post"],
               coef(m6_terr)["near_station_5km:post"],
               coef(m6_flat)["near_station_5km:post"]),
  se = c(se(m6_det)["near_station_5km:post"],
         se(m6_semi)["near_station_5km:post"],
         se(m6_terr)["near_station_5km:post"],
         se(m6_flat)["near_station_5km:post"])
)
prop_het[, ci_lo := estimate - 1.96 * se]
prop_het[, ci_hi := estimate + 1.96 * se]
fwrite(prop_het, file.path(DATA_DIR, "property_type_heterogeneity.csv"))

# ==============================================================================
# Save all model results
# ==============================================================================

cat("\n=== RESULTS SUMMARY ===\n")
cat("Model 1 (5km DiD):", round(coef(m1)["near_station_5km:post"], 4),
    "SE:", round(se(m1)["near_station_5km:post"], 4), "\n")
cat("Model 1b (2km DiD):", round(coef(m1_2km)["near_station_2km:post"], 4),
    "SE:", round(se(m1_2km)["near_station_2km:post"], 4), "\n")
cat("Model 1b (10km DiD):", round(coef(m1_10km)["near_station_10km:post"], 4),
    "SE:", round(se(m1_10km)["near_station_10km:post"], 4), "\n")
cat("Model 2 (Phase2 vs Phase1):", round(coef(m2)["treated:post"], 4),
    "SE:", round(se(m2)["treated:post"], 4), "\n")
cat("Model 3 (Continuous 1/dist):", round(coef(m3)["inv_dist_p2:post"], 4),
    "SE:", round(se(m3)["inv_dist_p2:post"], 4), "\n")

# Save main results for tables
main_results <- data.table(
  model = c("2km ring", "5km ring", "10km ring",
            "Phase2 vs Phase1", "Continuous (1/dist)"),
  estimate = c(
    coef(m1_2km)["near_station_2km:post"],
    coef(m1)["near_station_5km:post"],
    coef(m1_10km)["near_station_10km:post"],
    coef(m2)["treated:post"],
    coef(m3)["inv_dist_p2:post"]
  ),
  se = c(
    se(m1_2km)["near_station_2km:post"],
    se(m1)["near_station_5km:post"],
    se(m1_10km)["near_station_10km:post"],
    se(m2)["treated:post"],
    se(m3)["inv_dist_p2:post"]
  ),
  n = c(nobs(m1_2km), nobs(m1), nobs(m1_10km), nobs(m2), nobs(m3))
)
main_results[, tstat := estimate / se]
main_results[, pval := 2 * pnorm(-abs(tstat))]
main_results[, stars := fifelse(pval < 0.01, "***",
                                 fifelse(pval < 0.05, "**",
                                         fifelse(pval < 0.1, "*", "")))]

fwrite(main_results, file.path(DATA_DIR, "main_results.csv"))
cat("\nMain results saved.\n")

# Save model objects for table generation
save(m1, m1_2km, m1_10km, m2, m3, m4, m5,
     m6_det, m6_semi, m6_terr, m6_flat,
     file = file.path(DATA_DIR, "model_objects.RData"))
