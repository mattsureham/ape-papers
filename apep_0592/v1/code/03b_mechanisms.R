# ==============================================================================
# 03b_mechanisms.R — Mechanism tests, heterogeneity, women, long-run
# Paper: State Prohibition and Labor Market Restructuring (apep_0592)
# ==============================================================================

source("00_packages.R")

# ==============================================================================
# 1. MECHANISM TESTS (reload fresh)
# ==============================================================================
cat("=== MECHANISM TESTS ===\n")
dt <- fread("../data/analysis_sample.csv")
males <- dt[male == 1]

# 1a. Supply-chain workers
supply <- males[supply_chain == 1]
mech_supply <- feols(delta_occscore ~ treatment + alc_share + treated_state +
                       age_1910 + age_sq + immigrant + black + married + literate +
                       occscore_1910 | region,
                     data = supply, cluster = ~statefip_1910)

# 1b. Manufacturing workers (crowding channel)
manuf <- males[manufacturing == 1 & supply_chain == 0]
mech_manuf <- feols(delta_occscore ~ treatment + alc_share + treated_state +
                      age_1910 + age_sq + immigrant + black + married + literate +
                      occscore_1910 | region,
                    data = manuf, cluster = ~statefip_1910)

# 1c. Retail/hospitality workers (reallocation channel)
retail <- males[retail_hospitality == 1]
mech_retail <- feols(delta_occscore ~ treatment + alc_share + treated_state +
                       age_1910 + age_sq + immigrant + black + married + literate +
                       occscore_1910 | region,
                     data = retail, cluster = ~statefip_1910)

# 1d. Self-employment (commercial real estate channel)
mech_selfemp <- feols(self_employed_1920 ~ treatment + alc_share + treated_state +
                        age_1910 + age_sq + immigrant + black + married + literate +
                        self_employed_1910 | region,
                      data = males, cluster = ~statefip_1910)

# 1e. Geographic mobility (social infrastructure channel)
mech_mover <- feols(mover ~ treatment + alc_share + treated_state +
                      age_1910 + age_sq + immigrant + black + married + literate +
                      occscore_1910 | region,
                    data = males, cluster = ~statefip_1910)

# 1f. Occupation switching
mech_occswitch <- feols(occ_switch ~ treatment + alc_share + treated_state +
                          age_1910 + age_sq + immigrant + black + married + literate +
                          occscore_1910 | region,
                        data = males, cluster = ~statefip_1910)

cat("Supply chain N:", nobs(mech_supply), "\n")
cat("Manufacturing N:", nobs(mech_manuf), "\n")
cat("Retail/hospitality N:", nobs(mech_retail), "\n")

etable(mech_supply, mech_manuf, mech_retail, mech_selfemp, mech_mover, mech_occswitch,
       keep = "%treatment",
       headers = c("Supply Chain", "Manufacturing", "Retail/Hosp",
                    "Self-Employment", "Mobility", "Occ Switch"),
       se.below = TRUE)

mechanism_coefs <- data.table(
  channel = c("Supply Chain", "Manufacturing", "Retail/Hospitality",
              "Self-Employment", "Mobility", "Occ Switch"),
  outcome = c(rep("ΔOCCSCORE", 3), "Self-Emp 1920", "Moved County", "Switched Occ"),
  beta = c(coef(mech_supply)["treatment"], coef(mech_manuf)["treatment"],
           coef(mech_retail)["treatment"], coef(mech_selfemp)["treatment"],
           coef(mech_mover)["treatment"], coef(mech_occswitch)["treatment"]),
  se = c(se(mech_supply)["treatment"], se(mech_manuf)["treatment"],
         se(mech_retail)["treatment"], se(mech_selfemp)["treatment"],
         se(mech_mover)["treatment"], se(mech_occswitch)["treatment"]),
  n = c(nobs(mech_supply), nobs(mech_manuf), nobs(mech_retail),
        nobs(mech_selfemp), nobs(mech_mover), nobs(mech_occswitch))
)
mechanism_coefs[, pval := 2 * pnorm(-abs(beta / se))]
fwrite(mechanism_coefs, "../data/mechanism_coefficients.csv")

# Free mechanism data before heterogeneity (large objects)
rm(males, dt, supply, manuf, retail)
rm(mech_supply, mech_manuf, mech_retail, mech_selfemp, mech_mover, mech_occswitch)
gc()

# ==============================================================================
# 2. HETEROGENEITY
# ==============================================================================
cat("\n=== HETEROGENEITY ===\n")

# Reload only needed columns to minimize memory footprint
het_cols <- c("delta_occscore", "treatment", "alc_share", "treated_state",
              "age_1910", "age_sq", "immigrant", "black", "married", "literate",
              "occscore_1910", "region", "statefip_1910", "male")
het_dt <- fread("../data/analysis_sample.csv", select = het_cols)
het_dt <- het_dt[male == 1]
het_dt[, male := NULL]  # no longer needed

# Compute median occscore for low/high split before running regressions
med_occ <- median(het_dt$occscore_1910)

# Initialize results accumulator
het_coefs <- data.table(
  subgroup = character(), beta = numeric(), se = numeric(), n = integer()
)

# --- White ---
cat("  Running: White\n")
sub <- het_dt[black == 0]
mod <- feols(delta_occscore ~ treatment + alc_share + treated_state +
               age_1910 + age_sq + immigrant + married + literate +
               occscore_1910 | region,
             data = sub, cluster = ~statefip_1910)
het_coefs <- rbind(het_coefs, data.table(
  subgroup = "White", beta = coef(mod)["treatment"],
  se = se(mod)["treatment"], n = nobs(mod)))
rm(sub, mod); gc()

# --- Black ---
cat("  Running: Black\n")
sub <- het_dt[black == 1]
mod <- feols(delta_occscore ~ treatment + alc_share + treated_state +
               age_1910 + age_sq + married + literate +
               occscore_1910 | region,
             data = sub, cluster = ~statefip_1910)
het_coefs <- rbind(het_coefs, data.table(
  subgroup = "Black", beta = coef(mod)["treatment"],
  se = se(mod)["treatment"], n = nobs(mod)))
rm(sub, mod); gc()

# --- Native-born ---
cat("  Running: Native-born\n")
sub <- het_dt[immigrant == 0]
mod <- feols(delta_occscore ~ treatment + alc_share + treated_state +
               age_1910 + age_sq + black + married + literate +
               occscore_1910 | region,
             data = sub, cluster = ~statefip_1910)
het_coefs <- rbind(het_coefs, data.table(
  subgroup = "Native-born", beta = coef(mod)["treatment"],
  se = se(mod)["treatment"], n = nobs(mod)))
rm(sub, mod); gc()

# --- Immigrant ---
cat("  Running: Immigrant\n")
sub <- het_dt[immigrant == 1]
mod <- feols(delta_occscore ~ treatment + alc_share + treated_state +
               age_1910 + age_sq + black + married + literate +
               occscore_1910 | region,
             data = sub, cluster = ~statefip_1910)
het_coefs <- rbind(het_coefs, data.table(
  subgroup = "Immigrant", beta = coef(mod)["treatment"],
  se = se(mod)["treatment"], n = nobs(mod)))
rm(sub, mod); gc()

# --- Low OccScore ---
cat("  Running: Low OccScore\n")
sub <- het_dt[occscore_1910 <= med_occ]
mod <- feols(delta_occscore ~ treatment + alc_share + treated_state +
               age_1910 + age_sq + immigrant + black + married + literate | region,
             data = sub, cluster = ~statefip_1910)
het_coefs <- rbind(het_coefs, data.table(
  subgroup = "Low OccScore", beta = coef(mod)["treatment"],
  se = se(mod)["treatment"], n = nobs(mod)))
rm(sub, mod); gc()

# --- High OccScore ---
cat("  Running: High OccScore\n")
sub <- het_dt[occscore_1910 > med_occ]
mod <- feols(delta_occscore ~ treatment + alc_share + treated_state +
               age_1910 + age_sq + immigrant + black + married + literate | region,
             data = sub, cluster = ~statefip_1910)
het_coefs <- rbind(het_coefs, data.table(
  subgroup = "High OccScore", beta = coef(mod)["treatment"],
  se = se(mod)["treatment"], n = nobs(mod)))
rm(sub, mod, het_dt); gc()

het_coefs[, pval := 2 * pnorm(-abs(beta / se))]
fwrite(het_coefs, "../data/heterogeneity_coefficients.csv")
cat("  Heterogeneity results saved.\n")

# ==============================================================================
# 3. WOMEN'S EMPLOYMENT
# ==============================================================================
cat("\n=== WOMEN'S EMPLOYMENT ===\n")

# Reload with only needed columns, filter to females
fem_cols <- c("delta_occscore", "treatment", "alc_share", "treated_state",
              "age_1910", "age_sq", "black", "immigrant", "married", "literate",
              "occscore_1910", "region", "statefip_1910", "sex_1910", "occ_switch")
females <- fread("../data/analysis_sample.csv", select = fem_cols)
females <- females[sex_1910 == 2]
females[, sex_1910 := NULL]

fem_occ <- feols(delta_occscore ~ treatment + alc_share + treated_state +
                   age_1910 + age_sq + black + immigrant + married + literate +
                   occscore_1910 | region,
                 data = females, cluster = ~statefip_1910)

fem_switch <- feols(occ_switch ~ treatment + alc_share + treated_state +
                      age_1910 + age_sq + black + immigrant + married + literate +
                      occscore_1910 | region,
                    data = females, cluster = ~statefip_1910)

rm(females); gc()

etable(fem_occ, fem_switch,
       keep = "%treatment",
       headers = c("Female ΔOCCSCORE", "Female Occ Switch"),
       se.below = TRUE)

fem_coefs <- data.table(
  outcome = c("Female ΔOCCSCORE", "Female Occ Switch"),
  beta = c(coef(fem_occ)["treatment"], coef(fem_switch)["treatment"]),
  se = c(se(fem_occ)["treatment"], se(fem_switch)["treatment"]),
  n = c(nobs(fem_occ), nobs(fem_switch))
)
fwrite(fem_coefs, "../data/female_coefficients.csv")

# Save only models currently in memory (mechanism models already freed)
save(fem_occ, fem_switch,
     file = "../data/mechanism_objects.RData")
rm(fem_occ, fem_switch); gc()

# ==============================================================================
# 4. LONG-RUN EFFECTS (1920-1930)
# ==============================================================================
cat("\n=== LONG-RUN EFFECTS (1920-1930) ===\n")

# Load longrun sample with only needed columns
lr_cols <- c("delta_occscore", "treatment", "alc_share", "treated_state",
             "age_1920", "age_sq", "immigrant", "black", "region",
             "statefip_1920", "male", "occ_switch")
longrun <- fread("../data/longrun_sample.csv", select = lr_cols)
lr_males <- longrun[male == 1]
lr_males[, male := NULL]
rm(longrun); gc()

lr_m1 <- feols(delta_occscore ~ treatment + alc_share + treated_state +
                 age_1920 + age_sq + immigrant + black | region,
               data = lr_males, cluster = ~statefip_1920)

lr_m2 <- feols(occ_switch ~ treatment + alc_share + treated_state +
                 age_1920 + age_sq + immigrant + black | region,
               data = lr_males, cluster = ~statefip_1920)

rm(lr_males); gc()

etable(lr_m1, lr_m2,
       keep = "%treatment",
       headers = c("LR ΔOCCSCORE", "LR Occ Switch"),
       se.below = TRUE)

lr_coefs <- data.table(
  outcome = c("ΔOCCSCORE (1920-1930)", "Occ Switch (1920-1930)"),
  beta = c(coef(lr_m1)["treatment"], coef(lr_m2)["treatment"]),
  se = c(se(lr_m1)["treatment"], se(lr_m2)["treatment"]),
  n = c(nobs(lr_m1), nobs(lr_m2))
)
fwrite(lr_coefs, "../data/longrun_coefficients.csv")

save(lr_m1, lr_m2, file = "../data/longrun_objects.RData")
rm(lr_m1, lr_m2); gc()

cat("\nAll mechanism/heterogeneity/long-run analysis complete.\n")
