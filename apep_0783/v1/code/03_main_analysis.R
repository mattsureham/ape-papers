## 03_main_analysis.R — Main DiD regressions
## apep_0783: USPS POStPlan and Rural Business Formation

source("00_packages.R")

data_dir <- "../data/"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Panel loaded:", nrow(panel), "county-years\n")
cat("Treated:", sum(panel$ever_treated & panel$year == 2012), "counties\n")
cat("Control:", sum(!panel$ever_treated & panel$year == 2012), "counties\n")

# ============================================================
# 1. TWFE DiD — Binary Treatment
# ============================================================
cat("\n=== Specification 1: TWFE Binary DiD ===\n")

# Basic TWFE: county + year FE, cluster at state level
m1 <- feols(
  log_ba ~ treat_post | county_fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Binary TWFE DiD:\n")
summary(m1)

# ============================================================
# 2. TWFE DiD — Continuous Dose
# ============================================================
cat("\n=== Specification 2: TWFE Continuous Dose DiD ===\n")

# Dose-response: avg hours lost × post
m2 <- feols(
  log_ba ~ dose_post | county_fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Continuous Dose TWFE DiD:\n")
summary(m2)

# ============================================================
# 3. Event Study — Dynamic Effects
# ============================================================
cat("\n=== Specification 3: Event Study ===\n")

# Create event time relative to 2013 (first full year of implementation)
panel <- panel %>%
  mutate(
    event_time = year - 2013,
    # Cap at -5 and +5 for cleaner estimation
    event_time_binned = pmax(pmin(event_time, 8), -7)
  )

# Event study with fixest sunab-style (manual relative time dummies)
m3 <- feols(
  log_ba ~ i(event_time_binned, ever_treated, ref = -1) |
    county_fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Event Study (ref = t-1):\n")
summary(m3)

# ============================================================
# 4. Dose-Response Event Study
# ============================================================
cat("\n=== Specification 4: Dose-Response Event Study ===\n")

m4 <- feols(
  log_ba ~ i(event_time_binned, dose, ref = -1) |
    county_fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Dose-Response Event Study (ref = t-1):\n")
summary(m4)

# ============================================================
# 5. Dose Monotonicity Test
# ============================================================
cat("\n=== Specification 5: Dose Monotonicity ===\n")

# Separate indicators for low/medium/high dose
panel <- panel %>%
  mutate(
    dose_group = case_when(
      !ever_treated ~ "control",
      dose > 0 & dose <= 2.5 ~ "low_dose",
      dose > 2.5 & dose <= 4 ~ "med_dose",
      dose > 4 ~ "high_dose",
      TRUE ~ "control"
    ),
    dose_group = factor(dose_group, levels = c("control", "low_dose", "med_dose", "high_dose"))
  )

m5 <- feols(
  log_ba ~ i(dose_group, post, ref = "control") | county_fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Dose Monotonicity:\n")
summary(m5)

# ============================================================
# 6. Pre-trend test (F-test on pre-treatment event study coefficients)
# ============================================================
cat("\n=== Pre-trend Diagnostics ===\n")

# Extract pre-treatment coefficients from event study
m3_coefs <- coeftable(m3)
pre_coefs <- m3_coefs[grep("event_time_binned::-[2-7]", rownames(m3_coefs)), ]
cat("Pre-treatment event study coefficients:\n")
print(pre_coefs)

# Joint F-test for pre-trends
pre_test <- wald(m3, "event_time_binned::-[2-7]")
cat("\nJoint F-test for pre-trends:\n")
print(pre_test)

# ============================================================
# 7. Save diagnostics.json for validator
# ============================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = sum(panel$ever_treated & panel$year == 2012),
  n_pre = length(unique(panel$year[panel$year < 2013])),
  n_obs = nrow(panel),
  n_counties = n_distinct(panel$county_fips),
  n_years = n_distinct(panel$year),
  pre_trend_f_stat = as.numeric(pre_test$stat),
  pre_trend_p_value = as.numeric(pre_test$p)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics saved.\n")

# ============================================================
# 8. Save model objects for tables
# ============================================================

save(m1, m2, m3, m4, m5, panel, file = file.path(data_dir, "models.RData"))
cat("Models saved.\n")

# ============================================================
# Summary of main results
# ============================================================
cat("\n====================================\n")
cat("MAIN RESULTS SUMMARY\n")
cat("====================================\n")
cat("\nBinary DiD (log BA):\n")
cat("  β =", round(coef(m1)["treat_post"], 4),
    " SE =", round(se(m1)["treat_post"], 4),
    " p =", round(pvalue(m1)["treat_post"], 4), "\n")
cat("\nDose DiD (log BA per hour lost):\n")
cat("  β =", round(coef(m2)["dose_post"], 4),
    " SE =", round(se(m2)["dose_post"], 4),
    " p =", round(pvalue(m2)["dose_post"], 4), "\n")
cat("\nDose Monotonicity (post × dose group):\n")
for (nm in names(coef(m5))) {
  cat("  ", nm, ":", round(coef(m5)[nm], 4),
      " (", round(se(m5)[nm], 4), ")\n")
}
cat("====================================\n")
