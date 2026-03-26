# 03_main_analysis.R — Main analysis: continuous-exposure triple-difference
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry
#
# V2 core change: continuous biometric exposure measure replaces binary classification
# Specification: log(Y) = β × Illinois × Post × BiometricExposure + FE

source("00_packages.R")

# ============================================================
# Load data
# ============================================================

df_panel <- fread("../data/analysis_panel.csv")
df_border <- fread("../data/border_panel.csv")

cat(sprintf("Full panel: %d rows, %d counties, %d sectors\n",
            nrow(df_panel), uniqueN(df_panel$area_fips), uniqueN(df_panel$naics_2)))
cat(sprintf("Border panel: %d rows\n", nrow(df_border)))

# Filter out "total" sector
df_analysis <- df_panel[sector != "total"]
df_border_analysis <- df_border[sector != "total"]

# ============================================================
# Section 1: Continuous-exposure triple-difference
# ============================================================

cat("\n=== CONTINUOUS-EXPOSURE TRIPLE-DIFFERENCE ===\n")

# Main specification (border counties):
# log_emp ~ Illinois × Post × BiometricExposure + county-sector FE + quarter FE

# Model 1: Employment (border)
m1_border <- feols(log_emp ~ triple_cont + il_post + exposure_post + il_exposure |
                     county_sector + yearqtr,
                   data = df_border_analysis,
                   cluster = ~state_fips)

# Model 2: Establishments (border)
m2_border <- feols(log_estab ~ triple_cont + il_post + exposure_post + il_exposure |
                     county_sector + yearqtr,
                   data = df_border_analysis,
                   cluster = ~state_fips)

# Model 3: Wages (border)
m3_border <- feols(log_wage ~ triple_cont + il_post + exposure_post + il_exposure |
                     county_sector + yearqtr,
                   data = df_border_analysis,
                   cluster = ~state_fips)

# Model 4: Average establishment size (border)
m4_border <- feols(log_avg_size ~ triple_cont + il_post + exposure_post + il_exposure |
                     county_sector + yearqtr,
                   data = df_border_analysis,
                   cluster = ~state_fips)

# Models 5-8: All counties
m5_all <- feols(log_emp ~ triple_cont + il_post + exposure_post + il_exposure |
                  county_sector + yearqtr,
                data = df_analysis, cluster = ~state_fips)

m6_all <- feols(log_estab ~ triple_cont + il_post + exposure_post + il_exposure |
                  county_sector + yearqtr,
                data = df_analysis, cluster = ~state_fips)

m7_all <- feols(log_wage ~ triple_cont + il_post + exposure_post + il_exposure |
                  county_sector + yearqtr,
                data = df_analysis, cluster = ~state_fips)

m8_all <- feols(log_avg_size ~ triple_cont + il_post + exposure_post + il_exposure |
                  county_sector + yearqtr,
                data = df_analysis, cluster = ~state_fips)

cat("\n--- Border County Results ---\n")
cat("Employment:     "); print(coeftable(m1_border)["triple_cont", ])
cat("Establishments: "); print(coeftable(m2_border)["triple_cont", ])
cat("Wages:          "); print(coeftable(m3_border)["triple_cont", ])
cat("Avg Estab Size: "); print(coeftable(m4_border)["triple_cont", ])

cat("\n--- All County Results ---\n")
cat("Employment:     "); print(coeftable(m5_all)["triple_cont", ])
cat("Establishments: "); print(coeftable(m6_all)["triple_cont", ])

# ============================================================
# Section 2: V1-style binary triple-diff (comparison)
# ============================================================

cat("\n=== V1-STYLE BINARY TRIPLE-DIFF (COMPARISON) ===\n")

v1_sectors <- c("information", "professional", "finance", "healthcare")
df_v1 <- df_border_analysis[sector %in% v1_sectors]

m_v1_emp <- feols(log_emp ~ triple + il_post + exposure_post + il_exposure |
                    county_sector + yearqtr,
                  data = df_v1, cluster = ~state_fips)

cat("V1 binary employment: "); print(coeftable(m_v1_emp)["triple", ])

# ============================================================
# Section 3: Event study (continuous exposure)
# ============================================================

cat("\n=== EVENT STUDY ===\n")

# Create event-time dummies × exposure × Illinois
event_times <- sort(unique(df_border_analysis$event_q))
event_times <- event_times[event_times != -1]  # Reference: Q4 2018

for (eq in event_times) {
  varname <- sprintf("eq_%s", gsub("-", "m", as.character(eq)))
  df_border_analysis[, (varname) := fifelse(event_q == eq, 1L, 0L) * bio_exposure_std * illinois]
}

eq_vars <- grep("^eq_", names(df_border_analysis), value = TRUE)

# Employment event study
fml_es <- as.formula(paste("log_emp ~", paste(eq_vars, collapse = " + "),
                           "| county_sector + yearqtr"))
m_es_emp <- feols(fml_es, data = df_border_analysis, cluster = ~state_fips)

es_coefs <- data.table(
  event_q = as.numeric(gsub("eq_m", "-", gsub("eq_", "", eq_vars))),
  coef = coef(m_es_emp)[eq_vars],
  se = sqrt(diag(vcov(m_es_emp)))[eq_vars]
)
es_coefs[, ci_lo := coef - 1.96 * se]
es_coefs[, ci_hi := coef + 1.96 * se]
es_coefs <- rbind(es_coefs, data.table(event_q = -1, coef = 0, se = 0, ci_lo = 0, ci_hi = 0))
es_coefs <- es_coefs[order(event_q)]

fwrite(es_coefs, "../data/event_study_employment.csv")

# Establishments event study
m_es_estab <- feols(as.formula(paste("log_estab ~", paste(eq_vars, collapse = " + "),
                                     "| county_sector + yearqtr")),
                    data = df_border_analysis, cluster = ~state_fips)

es_estab <- data.table(
  event_q = as.numeric(gsub("eq_m", "-", gsub("eq_", "", eq_vars))),
  coef = coef(m_es_estab)[eq_vars],
  se = sqrt(diag(vcov(m_es_estab)))[eq_vars]
)
es_estab[, ci_lo := coef - 1.96 * se]
es_estab[, ci_hi := coef + 1.96 * se]
es_estab <- rbind(es_estab, data.table(event_q = -1, coef = 0, se = 0, ci_lo = 0, ci_hi = 0))
es_estab <- es_estab[order(event_q)]

fwrite(es_estab, "../data/event_study_establishments.csv")

cat("Event study coefficients saved.\n")

# ============================================================
# Section 4: Border reallocation test
# ============================================================

cat("\n=== BORDER REALLOCATION TEST ===\n")

# IL border: high-exposure sectors should LOSE employment
df_il_border <- df_border_analysis[illinois == 1]
# HC1 SEs since only 1 state in IL subset — cannot cluster at state level
m_il_loss <- feols(log_emp ~ post:bio_exposure_std | county_sector + yearqtr,
                   data = df_il_border, vcov = "HC1")

# Neighbor border: high-exposure sectors should GAIN employment
df_nb_border <- df_border_analysis[illinois == 0]
m_nb_gain <- tryCatch(
  feols(log_emp ~ post:bio_exposure_std | county_sector + yearqtr,
        data = df_nb_border, cluster = ~state_fips),
  error = function(e) {
    cat(sprintf("  Neighbor cluster SE failed: %s\n  Using HC1 instead.\n", e$message))
    feols(log_emp ~ post:bio_exposure_std | county_sector + yearqtr,
          data = df_nb_border, vcov = "HC1")
  }
)

cat("IL border (exposure × post):      "); print(coeftable(m_il_loss)[1, ])
cat("Neighbor border (exposure × post): "); print(coeftable(m_nb_gain)[1, ])

# ============================================================
# Section 5: Sector-specific effects
# ============================================================

cat("\n=== SECTOR-SPECIFIC EFFECTS ===\n")

sector_results <- list()
for (s in sort(unique(df_border_analysis$sector))) {
  df_s <- df_border_analysis[sector == s]
  if (nrow(df_s) < 100) next

  m_s <- tryCatch(
    feols(log_emp ~ il_post | county_sector + yearqtr,
          data = df_s, cluster = ~state_fips),
    error = function(e) NULL
  )

  if (!is.null(m_s)) {
    ct <- coeftable(m_s)["il_post", ]
    sector_results[[s]] <- data.table(
      sector = s, bio_exposure = unique(df_s$bio_exposure_std),
      coef = ct[1], se = ct[2], pval = ct[4]
    )
    cat(sprintf("  %-20s (exp=%.2f): β=%7.4f, se=%6.4f, p=%.3f\n",
                s, unique(df_s$bio_exposure_std), ct[1], ct[2], ct[4]))
  }
}

sector_dt <- rbindlist(sector_results)
fwrite(sector_dt, "../data/sector_specific_effects.csv")

# ============================================================
# Section 6: Diagnostics
# ============================================================

cat("\n=== DIAGNOSTICS ===\n")

n_treated <- uniqueN(df_border_analysis[illinois == 1]$area_fips)
n_pre <- uniqueN(df_border_analysis[post == 0]$yearqtr)
n_obs <- nrow(df_border_analysis)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_sectors = uniqueN(df_border_analysis$naics_2),
  n_counties_total = uniqueN(df_border_analysis$area_fips),
  main_coef_employment = coef(m1_border)["triple_cont"],
  main_se_employment = sqrt(diag(vcov(m1_border)))["triple_cont"],
  main_coef_establishments = coef(m2_border)["triple_cont"],
  main_se_establishments = sqrt(diag(vcov(m2_border)))["triple_cont"]
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save all models
save(m1_border, m2_border, m3_border, m4_border,
     m5_all, m6_all, m7_all, m8_all,
     m_v1_emp, m_es_emp, m_es_estab,
     m_il_loss, m_nb_gain,
     sector_dt, es_coefs, es_estab,
     file = "../data/main_models.RData")

cat(sprintf("\nTreated counties: %d, Pre-periods: %d, Observations: %d\n",
            n_treated, n_pre, n_obs))
cat("=== MAIN ANALYSIS COMPLETE ===\n")
