# 03_main_analysis.R — Main DiD and triple-DiD estimation
# APEP paper apep_0784: OSHA Heat NEP

source("00_packages.R")

data_dir <- "../data/"
df <- fread(file.path(data_dir, "analysis_panel.csv"))

cat(sprintf("=== Analysis Dataset: %d obs, %d states, years %d-%d ===\n",
            nrow(df), uniqueN(df$state), min(df$year), max(df$year)))

# ============================================================
# 1. Simple DiD: High-Heat × Post
# ============================================================
cat("\n=== Specification 1: Simple DiD ===\n")

# Outcome: TRC rate per 200,000 hours
# FE: NAICS2 + State×Year
# Clustering: State

m1_trc <- feols(trc_rate ~ did | naics2 + state^year, data = df, cluster = ~state)
m1_dart <- feols(dart_rate ~ did | naics2 + state^year, data = df, cluster = ~state)
m1_ill <- feols(illness_rate ~ did | naics2 + state^year, data = df, cluster = ~state)

cat("\nSimple DiD — TRC Rate:\n")
print(summary(m1_trc))

cat("\nSimple DiD — DART Rate:\n")
print(summary(m1_dart))

cat("\nSimple DiD — Illness Rate:\n")
print(summary(m1_ill))

# ============================================================
# 2. Triple DiD: High-Heat × Post × Hot State
# ============================================================
cat("\n=== Specification 2: Triple DiD ===\n")

# The triple interaction captures the additional effect in hot states
# where the NEP should bite more (more heat-index days > 80°F)

# Need to include lower-order interactions not absorbed by FE
# State×Year FE absorbs post×hot_state
# NAICS2 FE absorbs high_heat
# We need: high_heat × hot_state (absorbed by naics2×state FE if we use those)

# Use NAICS2×State FE to absorb industry-state baseline differences
m2_trc <- feols(trc_rate ~ did + triple_did | naics2^state + state^year,
                data = df, cluster = ~state)
m2_dart <- feols(dart_rate ~ did + triple_did | naics2^state + state^year,
                 data = df, cluster = ~state)
m2_ill <- feols(illness_rate ~ did + triple_did | naics2^state + state^year,
                data = df, cluster = ~state)

cat("\nTriple DiD — TRC Rate:\n")
print(summary(m2_trc))

cat("\nTriple DiD — DART Rate:\n")
print(summary(m2_dart))

cat("\nTriple DiD — Illness Rate:\n")
print(summary(m2_ill))

# ============================================================
# 3. Continuous heat interaction
# ============================================================
cat("\n=== Specification 3: Continuous Heat Interaction ===\n")

# Instead of binary hot_state, use continuous summer temperature
# Standardize temperature for interpretability
df[, temp_std := (avg_summer_temp - mean(avg_summer_temp, na.rm = TRUE)) /
     sd(avg_summer_temp, na.rm = TRUE)]

df[, did_temp := high_heat * post * temp_std]

m3_trc <- feols(trc_rate ~ did + did_temp | naics2^state + state^year,
                data = df, cluster = ~state)
m3_dart <- feols(dart_rate ~ did + did_temp | naics2^state + state^year,
                 data = df, cluster = ~state)

cat("\nContinuous Heat DiD — TRC Rate:\n")
print(summary(m3_trc))

cat("\nContinuous Heat DiD — DART Rate:\n")
print(summary(m3_dart))

# ============================================================
# 4. Event Study
# ============================================================
cat("\n=== Specification 4: Event Study ===\n")

# Create event-time dummies relative to 2022 (treatment year)
# Omit 2021 as reference year
df[, event_time := year - 2022]

# Interact event_time with high_heat
m4_trc <- feols(trc_rate ~ i(event_time, high_heat, ref = -1) | naics2 + state^year,
                data = df, cluster = ~state)

cat("\nEvent Study — TRC Rate:\n")
print(summary(m4_trc))

# ============================================================
# 5. Size-weighted specification
# ============================================================
cat("\n=== Specification 5: Employment-Weighted ===\n")

m5_trc <- feols(trc_rate ~ did | naics2 + state^year,
                data = df, cluster = ~state, weights = ~employees)
m5_dart <- feols(dart_rate ~ did | naics2 + state^year,
                 data = df, cluster = ~state, weights = ~employees)

cat("\nWeighted DiD — TRC Rate:\n")
print(summary(m5_trc))

cat("\nWeighted DiD — DART Rate:\n")
print(summary(m5_dart))

# ============================================================
# 6. Save key results for diagnostics
# ============================================================
cat("\n=== Saving Diagnostics ===\n")

# Count treated units and pre-periods
n_treated <- uniqueN(df[high_heat == 1, estab_id])
n_control <- uniqueN(df[high_heat == 0, estab_id])
n_pre <- length(unique(df[year < 2022, year]))
n_post <- length(unique(df[year >= 2022, year]))
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated,
  n_control = n_control,
  n_pre = n_pre,
  n_post = n_post,
  n_obs = n_obs,
  n_states = uniqueN(df$state),
  years = paste(min(df$year), max(df$year), sep = "-"),
  did_trc_coef = round(coef(m1_trc)["did"], 4),
  did_trc_se = round(se(m1_trc)["did"], 4),
  did_trc_pval = round(pvalue(m1_trc)["did"], 4),
  triple_did_trc_coef = round(coef(m2_trc)["triple_did"], 4),
  triple_did_trc_se = round(se(m2_trc)["triple_did"], 4)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("Diagnostics saved.\n")

# Save model objects for table generation
save(m1_trc, m1_dart, m1_ill,
     m2_trc, m2_dart, m2_ill,
     m3_trc, m3_dart,
     m4_trc,
     m5_trc, m5_dart,
     file = file.path(data_dir, "models.RData"))

cat("Model objects saved.\n")

# Print key results summary
cat("\n========================================\n")
cat("KEY RESULTS SUMMARY\n")
cat("========================================\n")
cat(sprintf("Simple DiD (TRC rate):     β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(m1_trc)["did"], se(m1_trc)["did"], pvalue(m1_trc)["did"]))
cat(sprintf("Simple DiD (DART rate):    β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(m1_dart)["did"], se(m1_dart)["did"], pvalue(m1_dart)["did"]))
cat(sprintf("Simple DiD (Illness rate): β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(m1_ill)["did"], se(m1_ill)["did"], pvalue(m1_ill)["did"]))
cat(sprintf("\nTriple DiD (TRC rate):     β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(m2_trc)["triple_did"], se(m2_trc)["triple_did"], pvalue(m2_trc)["triple_did"]))
cat(sprintf("Triple DiD (DART rate):    β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(m2_dart)["triple_did"], se(m2_dart)["triple_did"], pvalue(m2_dart)["triple_did"]))
cat(sprintf("Triple DiD (Illness rate): β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(m2_ill)["triple_did"], se(m2_ill)["triple_did"], pvalue(m2_ill)["triple_did"]))
cat("========================================\n")

# Pre-treatment SDs for SDE computation
sd_trc_pre <- sd(df[post == 0]$trc_rate, na.rm = TRUE)
sd_dart_pre <- sd(df[post == 0]$dart_rate, na.rm = TRUE)
sd_ill_pre <- sd(df[post == 0]$illness_rate, na.rm = TRUE)

cat(sprintf("\nPre-treatment SDs: TRC=%.3f, DART=%.3f, Illness=%.3f\n",
            sd_trc_pre, sd_dart_pre, sd_ill_pre))

# Save SDs for SDE table
sde_info <- list(
  sd_trc_pre = sd_trc_pre,
  sd_dart_pre = sd_dart_pre,
  sd_ill_pre = sd_ill_pre
)
jsonlite::write_json(sde_info, file.path(data_dir, "sde_info.json"), auto_unbox = TRUE)

cat("\nMain analysis complete.\n")
