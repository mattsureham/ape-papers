# 04_robustness.R — Robustness checks and COVID isolation
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry

source("00_packages.R")

df_border <- fread("../data/border_panel.csv")
df_border <- df_border[sector != "total"]

cat("=== ROBUSTNESS CHECKS ===\n")

# ============================================================
# R1: Pre-COVID subsample (2015Q1 - 2019Q4)
# ============================================================

cat("\n--- R1: Pre-COVID Subsample ---\n")
df_precovid <- df_border[year < 2020]
m_precovid <- feols(log_emp ~ triple_cont + il_post + exposure_post + il_exposure |
                      county_sector + yearqtr,
                    data = df_precovid, cluster = ~state_fips)
cat("Pre-COVID employment: "); print(coeftable(m_precovid)["triple_cont", ])

# ============================================================
# R2: State × Quarter FE (absorbs IL-specific COVID policies)
# ============================================================

cat("\n--- R2: State × Quarter FE ---\n")
df_border[, state_qtr := paste0(state_fips, "_", yearqtr)]
m_state_qtr <- feols(log_emp ~ triple_cont + il_exposure |
                       county_sector + state_qtr,
                     data = df_border, cluster = ~state_fips)
cat("State×Quarter FE: "); print(coeftable(m_state_qtr)["triple_cont", ])

# ============================================================
# R3: Sector × Quarter FE (absorbs nationwide sector-specific COVID trends)
# ============================================================

cat("\n--- R3: Sector × Quarter FE ---\n")
df_border[, sector_qtr := paste0(naics_2, "_", yearqtr)]
m_sector_qtr <- feols(log_emp ~ triple_cont + il_post + il_exposure |
                        county_sector + sector_qtr,
                      data = df_border, cluster = ~state_fips)
cat("Sector×Quarter FE: "); print(coeftable(m_sector_qtr)["triple_cont", ])

# ============================================================
# R4: Leave-one-state-out
# ============================================================

cat("\n--- R4: Leave-One-State-Out ---\n")
control_states <- c("18", "55", "29", "19", "21")
loso_results <- list()

for (st in control_states) {
  df_loso <- df_border[state_fips != st]
  m_loso <- feols(log_emp ~ triple_cont + il_post + exposure_post + il_exposure |
                    county_sector + yearqtr,
                  data = df_loso, cluster = ~state_fips)
  ct <- coeftable(m_loso)["triple_cont", ]
  loso_results[[st]] <- data.table(
    dropped_state = st, coef = ct[1], se = ct[2], pval = ct[4]
  )
  cat(sprintf("  Drop %s: β=%.4f (se=%.4f)\n", st, ct[1], ct[2]))
}

loso_dt <- rbindlist(loso_results)
cat(sprintf("LOSO range: [%.4f, %.4f]\n", min(loso_dt$coef), max(loso_dt$coef)))

# ============================================================
# R5: Placebo test (false treatment at 2017Q1)
# ============================================================

cat("\n--- R5: Placebo Test (2017Q1) ---\n")
df_placebo <- df_border[year <= 2018]
df_placebo[, post_placebo := fifelse(year > 2017 | (year == 2017 & qtr >= 1), 1L, 0L)]
df_placebo[, triple_placebo := illinois * post_placebo * bio_exposure_std]
df_placebo[, il_post_p := illinois * post_placebo]
df_placebo[, exp_post_p := bio_exposure_std * post_placebo]

m_placebo <- feols(log_emp ~ triple_placebo + il_post_p + exp_post_p + il_exposure |
                     county_sector + yearqtr,
                   data = df_placebo, cluster = ~state_fips)
cat("Placebo: "); print(coeftable(m_placebo)["triple_placebo", ])

# ============================================================
# R6: Simple DiD (no industry variation)
# ============================================================

cat("\n--- R6: Simple DiD (statewide) ---\n")
m_simple <- feols(log_emp ~ il_post | area_fips + yearqtr,
                  data = df_border, cluster = ~state_fips)
cat("Simple DiD: "); print(coeftable(m_simple)["il_post", ])

# ============================================================
# R7: 2024 BIPA amendments reversal test
# ============================================================

cat("\n--- R7: 2024 Reversal Test ---\n")
if (max(df_border$year) >= 2024) {
  m_reversal <- feols(log_emp ~ triple_cont + triple_amend +
                        il_post + exposure_post + il_exposure |
                        county_sector + yearqtr,
                      data = df_border, cluster = ~state_fips)
  cat("Rosenbach:  "); print(coeftable(m_reversal)["triple_cont", ])
  cat("Amendment:  "); print(coeftable(m_reversal)["triple_amend", ])
} else {
  cat("Data does not extend to 2024. Reversal test skipped.\n")
}

# ============================================================
# Save
# ============================================================

save(m_precovid, m_state_qtr, m_sector_qtr, loso_dt, m_placebo, m_simple,
     file = "../data/robustness_models.RData")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
