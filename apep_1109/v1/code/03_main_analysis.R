## 03_main_analysis.R — Main IV/2SLS and Triple-Difference Analysis
## apep_1109: Crop Insurance and Deaths of Despair

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# ============================================================
# SAMPLE RESTRICTION: Agricultural counties only for main analysis
# ============================================================

ag <- panel[ag_county == 1 & !is.na(pdsi_growing)]
cat(sprintf("Agricultural county sample: %d obs, %d counties, %d years\n",
            nrow(ag), n_distinct(ag$fips5), n_distinct(ag$year)))

# Per capita measures (dollars per person)
ag[, `:=`(
  indem_pc = indemnity / pop,
  prem_pc = premium / pop,
  sub_pc = subsidy / pop
)]

# Winsorize extreme values at 1st and 99th percentiles
winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs, na.rm = TRUE)
  pmax(pmin(x, q[2]), q[1])
}

ag[, `:=`(
  indem_pc_w = winsorize(indem_pc),
  od_rate_w = winsorize(od_rate)
)]

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("\n=== Summary Statistics ===\n")

# Overall
cat(sprintf("  Mean OD rate: %.1f (SD: %.1f)\n",
            mean(ag$od_rate, na.rm = TRUE), sd(ag$od_rate, na.rm = TRUE)))
cat(sprintf("  Mean indemnity/capita: $%.0f (SD: $%.0f)\n",
            mean(ag$indem_pc, na.rm = TRUE), sd(ag$indem_pc, na.rm = TRUE)))
cat(sprintf("  Mean PDSI (growing): %.2f (SD: %.2f)\n",
            mean(ag$pdsi_growing, na.rm = TRUE), sd(ag$pdsi_growing, na.rm = TRUE)))
cat(sprintf("  Share drought years: %.1f%%\n",
            100 * mean(ag$drought, na.rm = TRUE)))

# By drought status
cat("\n  By drought status:\n")
cat(sprintf("    Non-drought OD rate: %.1f, Drought OD rate: %.1f\n",
            mean(ag[drought == 0, od_rate], na.rm = TRUE),
            mean(ag[drought == 1, od_rate], na.rm = TRUE)))
cat(sprintf("    Non-drought indemnity/cap: $%.0f, Drought: $%.0f\n",
            mean(ag[drought == 0, indem_pc], na.rm = TRUE),
            mean(ag[drought == 1, indem_pc], na.rm = TRUE)))

# ============================================================
# OLS BASELINE (Table 2, Panel A)
# ============================================================

cat("\n=== OLS Baseline ===\n")

# OLS: Naive relationship between indemnity and OD rates
ols1 <- feols(od_rate ~ indem_pc_w | fips5 + year, data = ag, cluster = ~state_fips)
ols2 <- feols(od_rate ~ indem_pc_w + I(pop/1000) | fips5 + year, data = ag, cluster = ~state_fips)

cat("OLS results:\n")
print(summary(ols1))

# ============================================================
# FIRST STAGE (Table 2, Panel B)
# ============================================================

cat("\n=== First Stage: PDSI -> Indemnity per capita ===\n")

fs1 <- feols(indem_pc_w ~ pdsi_growing | fips5 + year, data = ag, cluster = ~state_fips)
fs2 <- feols(indem_pc_w ~ pdsi_growing + I(pop/1000) | fips5 + year, data = ag, cluster = ~state_fips)

cat("First stage:\n")
print(summary(fs1))
fs_f <- summary(fs1)$coeftable["pdsi_growing", "t value"]^2
cat(sprintf("  First-stage F-statistic (t^2): %.1f\n", fs_f))

# ============================================================
# REDUCED FORM (PDSI -> OD rate)
# ============================================================

cat("\n=== Reduced Form: PDSI -> OD rate ===\n")

rf1 <- feols(od_rate ~ pdsi_growing | fips5 + year, data = ag, cluster = ~state_fips)
cat("Reduced form:\n")
print(summary(rf1))

# ============================================================
# IV/2SLS (Table 2, Panel C)
# ============================================================

cat("\n=== IV/2SLS: Instrumented Indemnity -> OD rate ===\n")

iv1 <- feols(od_rate ~ 1 | fips5 + year | indem_pc_w ~ pdsi_growing,
             data = ag, cluster = ~state_fips)
iv2 <- feols(od_rate ~ I(pop/1000) | fips5 + year | indem_pc_w ~ pdsi_growing,
             data = ag, cluster = ~state_fips)

cat("IV results:\n")
print(summary(iv1))
cat(sprintf("  IV coefficient: %.4f (SE: %.4f)\n",
            coef(iv1)["fit_indem_pc_w"], se(iv1)["fit_indem_pc_w"]))

# ============================================================
# TRIPLE DIFFERENCE: Drought × Insurance Penetration
# ============================================================

cat("\n=== Triple Difference: Drought × High Insurance ===\n")

# Create interaction terms
ag[, drought_x_highins := drought * high_insurance]

td1 <- feols(od_rate ~ drought + high_insurance + drought_x_highins |
               fips5 + year, data = ag[!is.na(high_insurance)], cluster = ~state_fips)
td2 <- feols(od_rate ~ drought * high_insurance + I(pop/1000) |
               fips5 + year, data = ag[!is.na(high_insurance)], cluster = ~state_fips)

cat("Triple-diff results:\n")
print(summary(td1))

# ============================================================
# HETEROGENEITY: Rural vs less rural
# ============================================================

cat("\n=== Heterogeneity: Rural vs Non-Rural Ag Counties ===\n")

iv_rural <- feols(od_rate ~ 1 | fips5 + year | indem_pc_w ~ pdsi_growing,
                  data = ag[rural == 1], cluster = ~state_fips)
iv_nonrural <- feols(od_rate ~ 1 | fips5 + year | indem_pc_w ~ pdsi_growing,
                     data = ag[rural == 0], cluster = ~state_fips)

cat(sprintf("  Rural IV coef: %.4f (SE: %.4f)\n",
            coef(iv_rural)["fit_indem_pc_w"], se(iv_rural)["fit_indem_pc_w"]))
cat(sprintf("  Non-rural IV coef: %.4f (SE: %.4f)\n",
            coef(iv_nonrural)["fit_indem_pc_w"], se(iv_nonrural)["fit_indem_pc_w"]))

# ============================================================
# Save diagnostics for validator
# ============================================================

diagnostics <- list(
  n_treated = n_distinct(ag[drought == 1, fips5]),
  n_pre = length(unique(ag$year[ag$year <= 2007])),
  n_obs = nrow(ag),
  n_counties = n_distinct(ag$fips5),
  n_years = n_distinct(ag$year),
  n_ag_counties = n_distinct(ag$fips5),
  first_stage_f = summary(fs1)$coeftable["pdsi_growing", "t value"]^2,
  iv_coef = as.numeric(coef(iv1)["fit_indem_pc_w"]),
  iv_se = as.numeric(se(iv1)["fit_indem_pc_w"]),
  rf_coef = as.numeric(coef(rf1)["pdsi_growing"]),
  mean_od_rate = mean(ag$od_rate, na.rm = TRUE),
  sd_od_rate = sd(ag$od_rate, na.rm = TRUE),
  mean_indem_pc = mean(ag$indem_pc, na.rm = TRUE),
  sd_indem_pc = sd(ag$indem_pc, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

# Save model objects for table generation
save(ols1, ols2, fs1, fs2, rf1, iv1, iv2, td1, td2,
     iv_rural, iv_nonrural, ag,
     file = file.path(data_dir, "models.RData"))

cat("\n=== Main analysis complete ===\n")
cat(sprintf("Diagnostics saved. First-stage F = %.1f\n", diagnostics$first_stage_f))
