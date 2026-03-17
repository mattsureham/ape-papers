# 03_main_analysis.R — DiD estimation of Alien Land Laws on occupational sorting
# apep_0719

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df_j_main <- readRDS(file.path(data_dir, "japanese_main.rds"))
df_j_farm <- readRDS(file.path(data_dir, "japanese_farmers.rds"))
df_w_farm <- readRDS(file.path(data_dir, "white_farmers.rds"))

# NOTE: Treatment (newly_treated) varies at the state level.
# With only a cross-section of changes (1920→1930), state FEs absorb treatment.
# Primary strategy: OLS with state-clustered SEs for Japanese-only models.
# DDD strategy: Japanese × Treated interaction CAN be estimated with state FEs.

# ===================================================================
# MAIN RESULT 1: FARM EXIT (Japanese farmers)
# ===================================================================

cat("=== MAIN RESULT: Farm Exit ===\n\n")

# Raw means
farm_exit_treated <- mean(df_j_farm$farm_exit[df_j_farm$newly_treated == 1])
farm_exit_control <- mean(df_j_farm$farm_exit[df_j_farm$newly_treated == 0])
cat(sprintf("Japanese farm exit: Treated = %.3f, Control = %.3f, Diff = %.3f\n",
            farm_exit_treated, farm_exit_control,
            farm_exit_treated - farm_exit_control))

# Model 1: Simple difference (clustered at state level)
m1_farm_exit <- feols(farm_exit ~ newly_treated,
                       data = df_j_farm,
                       cluster = ~state_1920)
cat("\nModel 1: Farm exit ~ newly_treated (state-clustered)\n")
summary(m1_farm_exit)

# Model 2: With individual controls
m2_farm_exit <- feols(farm_exit ~ newly_treated + age_1920 + I(age_1920^2) +
                        literate_1920,
                       data = df_j_farm,
                       cluster = ~state_1920)
cat("\nModel 2: Farm exit + controls\n")
summary(m2_farm_exit)

# ===================================================================
# MAIN RESULT 2: OCCUPATIONAL SCORE CHANGE (all Japanese working-age males)
# ===================================================================

cat("\n=== MAIN RESULT: Occupational Score Change ===\n\n")

m3_occscore <- feols(occscore_change ~ newly_treated,
                      data = df_j_main,
                      cluster = ~state_1920)
cat("Model 3: Occscore change ~ newly_treated\n")
summary(m3_occscore)

# With controls
m4_occscore <- feols(occscore_change ~ newly_treated + age_1920 + I(age_1920^2) +
                       literate_1920 + farm_occ_1920,
                      data = df_j_main,
                      cluster = ~state_1920)
cat("\nModel 4: Occscore change + controls\n")
summary(m4_occscore)

# ===================================================================
# MAIN RESULT 3: OCCSCORE CHANGE (Farm subsample)
# ===================================================================

cat("\n=== Farm Subsample: Occscore Change ===\n\n")

m5_farm_occ <- feols(occscore_change ~ newly_treated + age_1920 + literate_1920,
                       data = df_j_farm,
                       cluster = ~state_1920)
cat("Model 5: Farm subsample occscore change\n")
summary(m5_farm_occ)

# ===================================================================
# PLACEBO: WHITE FARMERS
# ===================================================================

cat("\n=== PLACEBO: White Farmers ===\n\n")

white_exit_treated <- mean(df_w_farm$farm_exit[df_w_farm$newly_treated == 1])
white_exit_control <- mean(df_w_farm$farm_exit[df_w_farm$newly_treated == 0])
cat(sprintf("White farm exit: Treated = %.3f, Control = %.3f, Diff = %.3f\n",
            white_exit_treated, white_exit_control,
            white_exit_treated - white_exit_control))

m6_white <- feols(farm_exit ~ newly_treated,
                   data = df_w_farm,
                   cluster = ~state_1920)
cat("\nModel 6: White farm exit ~ newly_treated\n")
summary(m6_white)

m7_white_occ <- feols(occscore_change ~ newly_treated,
                       data = df_w_farm,
                       cluster = ~state_1920)
cat("\nModel 7: White occscore change ~ newly_treated\n")
summary(m7_white_occ)

# ===================================================================
# TRIPLE-DIFFERENCE: Japanese × Treated (with state FEs)
# ===================================================================

cat("\n=== TRIPLE DIFFERENCE ===\n\n")

df_combined <- bind_rows(
  df_j_farm %>% mutate(japanese = 1),
  df_w_farm %>% mutate(japanese = 0)
)

# DDD: farm exit
m8_ddd_exit <- feols(farm_exit ~ newly_treated:japanese + japanese |
                       state_1920,
                      data = df_combined,
                      cluster = ~state_1920)
cat("Model 8: DDD farm exit\n")
summary(m8_ddd_exit)

# DDD: occscore change
m9_ddd_occ <- feols(occscore_change ~ newly_treated:japanese + japanese |
                      state_1920,
                     data = df_combined,
                     cluster = ~state_1920)
cat("\nModel 9: DDD occscore change\n")
summary(m9_ddd_occ)

# ===================================================================
# HETEROGENEITY: Farm Owners vs Farm Laborers
# ===================================================================

cat("\n=== HETEROGENEITY: Owner vs Laborer ===\n\n")

# Among farm owners
df_owners <- df_j_farm %>% filter(farm_owner_1920 == 1)
df_laborers <- df_j_farm %>% filter(farm_laborer_1920 == 1)

cat(sprintf("Farm owners: %d (treated: %d)\n", nrow(df_owners),
            sum(df_owners$newly_treated)))
cat(sprintf("Farm laborers: %d (treated: %d)\n", nrow(df_laborers),
            sum(df_laborers$newly_treated)))

if (nrow(df_owners) >= 20 & sum(df_owners$newly_treated) >= 5) {
  m10_owners <- feols(farm_exit ~ newly_treated, data = df_owners,
                       cluster = ~state_1920)
  cat("\nModel 10: Farm exit (owners only)\n")
  summary(m10_owners)
} else {
  cat("Insufficient farm owner observations for separate regression.\n")
  m10_owners <- NULL
}

if (nrow(df_laborers) >= 20 & sum(df_laborers$newly_treated) >= 5) {
  m11_laborers <- feols(farm_exit ~ newly_treated, data = df_laborers,
                         cluster = ~state_1920)
  cat("\nModel 11: Farm exit (laborers only)\n")
  summary(m11_laborers)
} else {
  cat("Insufficient farm laborer observations for separate regression.\n")
  m11_laborers <- NULL
}

# ===================================================================
# SAVE RESULTS
# ===================================================================

results <- list(
  m1_farm_exit = m1_farm_exit,
  m2_farm_exit = m2_farm_exit,
  m3_occscore = m3_occscore,
  m4_occscore = m4_occscore,
  m5_farm_occ = m5_farm_occ,
  m6_white = m6_white,
  m7_white_occ = m7_white_occ,
  m8_ddd_exit = m8_ddd_exit,
  m9_ddd_occ = m9_ddd_occ,
  m10_owners = m10_owners,
  m11_laborers = m11_laborers,
  stats = list(
    japanese_farm_exit_treated = farm_exit_treated,
    japanese_farm_exit_control = farm_exit_control,
    white_farm_exit_treated = white_exit_treated,
    white_farm_exit_control = white_exit_control,
    n_japanese_farmers = nrow(df_j_farm),
    n_japanese_main = nrow(df_j_main),
    n_white_farmers = nrow(df_w_farm)
  )
)

saveRDS(results, file.path(data_dir, "regression_results.rds"))

# ----- Write diagnostics.json -----
diagnostics <- list(
  n_treated = as.integer(sum(df_j_farm$newly_treated)),
  n_pre = as.integer(10),
  n_obs = as.integer(nrow(df_j_main)),
  n_japanese_farmers = nrow(df_j_farm),
  n_white_farmers = nrow(df_w_farm),
  n_treated_states = length(unique(df_j_farm$state_1920[df_j_farm$newly_treated == 1])),
  n_control_states = length(unique(df_j_farm$state_1920[df_j_farm$newly_treated == 0]))
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\nAll results saved.\n")
