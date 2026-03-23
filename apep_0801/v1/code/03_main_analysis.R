# 03_main_analysis.R — Main SDID and triple-difference estimation
# apep_0801: California School Start Time Mandate and Teen Traffic Fatalities

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load panel data
# ============================================================
panel <- fread(file.path(data_dir, "panel_state_month.csv"))
sdid_data <- fread(file.path(data_dir, "sdid_teen_morning.csv"))

cat("=== MAIN ANALYSIS ===\n\n")

# ============================================================
# 2. Synthetic Difference-in-Differences (SDID)
# ============================================================
cat("--- Specification 1: SDID (Teen Morning Fatalities) ---\n")

# Prepare data for synthdid package
# panel.matrices expects a data.frame with columns: unit, time, Y, W
sdid_df <- data.frame(
  unit = sdid_data$STATE,
  time = sdid_data$t,
  Y = sdid_data$fatality_rate,
  W = as.integer(sdid_data$ca == 1 & sdid_data$post == 1)
)

# Replace NAs with 0
sdid_df$Y[is.na(sdid_df$Y)] <- 0

# panel.matrices wants a balanced panel
sdid_setup <- synthdid::panel.matrices(sdid_df)

sdid_est <- tryCatch(
  synthdid::synthdid_estimate(sdid_setup$Y, sdid_setup$N0, sdid_setup$T0),
  error = function(e) {
    cat(sprintf("SDID estimation error: %s\n", e$message))
    cat("Falling back to SC estimator...\n")
    synthdid::sc_estimate(sdid_setup$Y, sdid_setup$N0, sdid_setup$T0)
  }
)

sdid_se <- tryCatch(
  sqrt(synthdid::vcov(sdid_est, method = "placebo")),
  error = function(e) {
    cat(sprintf("SDID SE error: %s\n", e$message))
    NA_real_
  }
)

cat(sprintf("SDID estimate: %.4f (SE = %.4f)\n", as.numeric(sdid_est), sdid_se))
if (!is.na(sdid_se)) {
  cat(sprintf("95%% CI: [%.4f, %.4f]\n", as.numeric(sdid_est) - 1.96 * sdid_se, as.numeric(sdid_est) + 1.96 * sdid_se))
  cat(sprintf("p-value: %.4f\n", 2 * pnorm(-abs(as.numeric(sdid_est) / sdid_se))))
}

# ============================================================
# 3. Two-way FE DiD (baseline comparison)
# ============================================================
cat("\n--- Specification 2: TWFE DiD (Teen Morning Fatalities) ---\n")

# State × month panel for teen morning
tm <- panel[age_group == "teen" & hour_block == "morning"]

twfe1 <- feols(fatality_rate ~ treat | STATE + t, data = tm,
               cluster = ~STATE)
cat("TWFE (teen morning, state + month FE, clustered by state):\n")
print(summary(twfe1))

# ============================================================
# 4. Triple-Difference
# ============================================================
cat("\n--- Specification 3: Triple-Difference ---\n")
# (Teen vs Adult) × (Morning vs Evening) × (CA vs Control) × (Post vs Pre)

ddd <- panel[age_group %in% c("teen", "adult") & hour_block %in% c("morning", "evening")]
ddd[, teen := as.integer(age_group == "teen")]
ddd[, morning := as.integer(hour_block == "morning")]

# Triple-diff: ca × teen × morning × post
ddd[, ca_teen := ca * teen]
ddd[, ca_morning := ca * morning]
ddd[, teen_morning := teen * morning]
ddd[, ca_teen_morning := ca * teen * morning]
ddd[, post_teen := post * teen]
ddd[, post_morning := post * morning]
ddd[, post_ca := post * ca]
ddd[, post_teen_morning := post * teen * morning]
ddd[, post_ca_teen := post * ca * teen]
ddd[, post_ca_morning := post * ca * morning]
ddd[, ddd_coef := post * ca * teen * morning]

# Full triple-diff with state-age-hour FE and time FE
# Using log(fatalities + 1) to handle zeros
ddd[, log_fat := log(fatalities + 1)]

# Cell FE: state × age × hour
ddd[, cell := paste(STATE, age_group, hour_block, sep = "_")]

ddd_reg <- feols(fatality_rate ~ ddd_coef +
                   post_ca_teen + post_ca_morning + post_teen_morning +
                   post_ca + post_teen + post_morning |
                   cell + t,
                 data = ddd, cluster = ~STATE)
cat("Triple-Difference (state-age-hour FE + month FE, clustered by state):\n")
print(summary(ddd_reg))

# ============================================================
# 5. Poisson specification (count data)
# ============================================================
cat("\n--- Specification 4: Poisson QMLE ---\n")

# Poisson with exposure (population)
tm[, log_pop := log(population)]

pois1 <- fepois(fatalities ~ treat | STATE + t,
                data = tm, offset = ~log_pop, cluster = ~STATE)
cat("Poisson QMLE (teen morning, offset = log(pop), clustered by state):\n")
print(summary(pois1))

# ============================================================
# 6. School-session only (exclude summer months)
# ============================================================
cat("\n--- Specification 5: School session only (Sep-May) ---\n")

tm_school <- tm[school_session == 1]
twfe_school <- feols(fatality_rate ~ treat | STATE + t,
                     data = tm_school, cluster = ~STATE)
cat("TWFE (school months only):\n")
print(summary(twfe_school))

# ============================================================
# 7. Save results
# ============================================================

# Collect main results
results <- list(
  sdid = list(
    estimate = as.numeric(sdid_est),
    se = sdid_se,
    method = "SDID"
  ),
  twfe = list(
    estimate = coef(twfe1)["treat"],
    se = sqrt(vcov(twfe1)["treat", "treat"]),
    method = "TWFE"
  ),
  ddd = list(
    estimate = coef(ddd_reg)["ddd_coef"],
    se = sqrt(vcov(ddd_reg)["ddd_coef", "ddd_coef"]),
    method = "Triple-Diff"
  ),
  poisson = list(
    estimate = coef(pois1)["treat"],
    se = sqrt(vcov(pois1)["treat", "treat"]),
    method = "Poisson"
  ),
  twfe_school = list(
    estimate = coef(twfe_school)["treat"],
    se = sqrt(vcov(twfe_school)["treat", "treat"]),
    method = "TWFE (school months)"
  )
)

# Pre-treatment SD of outcome for SDE calculation
pre_sd <- tm[post == 0, sd(fatality_rate, na.rm = TRUE)]
ca_pre_sd <- tm[ca == 1 & post == 0, sd(fatality_rate, na.rm = TRUE)]

cat(sprintf("\nPre-treatment SD(fatality_rate): all=%.4f, CA=%.4f\n", pre_sd, ca_pre_sd))

# Diagnostics for validate_v1.py
n_treated <- uniqueN(tm[ca == 1]$STATE)  # 1 state
n_pre <- uniqueN(tm[post == 0]$t)
n_obs <- nrow(tm)

diagnostics <- list(
  n_treated = n_treated * uniqueN(tm[ca == 1]$t),  # treated state-months
  n_pre = n_pre,
  n_obs = n_obs,
  pre_sd_y = pre_sd,
  ca_pre_sd_y = ca_pre_sd,
  sdid_estimate = as.numeric(sdid_est),
  sdid_se = sdid_se,
  twfe_estimate = as.numeric(coef(twfe1)["treat"]),
  twfe_se = as.numeric(sqrt(vcov(twfe1)["treat", "treat"]))
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

# Save full results for tables
saveRDS(results, file.path(data_dir, "main_results.rds"))
saveRDS(list(twfe1 = twfe1, ddd_reg = ddd_reg, pois1 = pois1,
             twfe_school = twfe_school, sdid_est = sdid_est, sdid_se = sdid_se),
        file.path(data_dir, "model_objects.rds"))

cat("\n=== Main analysis complete ===\n")
