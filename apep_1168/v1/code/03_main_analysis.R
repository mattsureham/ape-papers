##############################################################################
# 03_main_analysis.R — Main regressions and event study
# apep_1168: Contagious NIMBYism
##############################################################################

source("00_packages.R")
DATA_DIR <- "../data"

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cat("Panel:", nrow(panel), "obs,", uniqueN(panel$fips), "counties\n")

# ============================================================================
# Summary statistics
# ============================================================================
cat("\n=== Summary Statistics ===\n")

# Cross-section at 2024
cs <- panel[year == 2024]

# Overall
cat("Counties:", nrow(cs), "\n")
cat("With turbines:", sum(cs$own_turbines > 0, na.rm = TRUE), "\n")
cat("With ordinance:", sum(cs$ordinance_adopted, na.rm = TRUE), "\n")
cat("With ordinance AND zero own turbines:",
    sum(cs$ordinance_adopted == 1 & cs$own_turbines == 0, na.rm = TRUE), "\n")
cat("With ordinance AND own turbines:",
    sum(cs$ordinance_adopted == 1 & cs$own_turbines > 0, na.rm = TRUE), "\n")

# Mean SCI exposure by ordinance status
cat("\nMean SCI exposure by ordinance status:\n")
cat("  No ordinance:", mean(cs[ordinance_adopted == 0]$sci_exposure_turbines, na.rm = TRUE), "\n")
cat("  Has ordinance:", mean(cs[ordinance_adopted == 1]$sci_exposure_turbines, na.rm = TRUE), "\n")

# ============================================================================
# Main specification: LPM with county + year FE
# ============================================================================
cat("\n=== Main Regressions ===\n")

# Specification 1: SCI exposure only
m1 <- feols(ordinance_adopted ~ sci_exposure_turbines |
              fips + year,
            data = panel, cluster = ~state_fips)

# Specification 2: Horse race — SCI + geographic exposure
m2 <- feols(ordinance_adopted ~ sci_exposure_turbines + geo_exposure_turbines |
              fips + year,
            data = panel, cluster = ~state_fips)

# Specification 3: Horse race + own turbines control
m3 <- feols(ordinance_adopted ~ sci_exposure_turbines + geo_exposure_turbines +
              own_turbines |
              fips + year,
            data = panel, cluster = ~state_fips)

# Specification 4: Full controls
m4 <- feols(ordinance_adopted ~ sci_exposure_turbines + geo_exposure_turbines +
              own_turbines + log_pop + college_share + gop_share |
              fips + year,
            data = panel, cluster = ~state_fips)

cat("\n--- Spec 1: SCI only ---\n")
summary(m1)
cat("\n--- Spec 2: Horse race ---\n")
summary(m2)
cat("\n--- Spec 3: + Own turbines ---\n")
summary(m3)
cat("\n--- Spec 4: Full controls ---\n")
summary(m4)

# ============================================================================
# Key subsample: counties with ZERO own turbines
# (cleanest test of network contagion)
# ============================================================================
cat("\n=== Zero-turbine subsample ===\n")

# Keep counties that NEVER have turbines through the sample period
never_turbine_counties <- panel[, .(max_turb = max(own_turbines, na.rm = TRUE)), by = fips]
never_turbine_counties <- never_turbine_counties[max_turb == 0]$fips
panel_no_turb <- panel[fips %in% never_turbine_counties]
cat("  Never-turbine counties:", uniqueN(panel_no_turb$fips), "\n")
cat("  Of which adopted ordinance:", sum(panel_no_turb[year == 2024]$ordinance_adopted, na.rm = TRUE), "\n")

# Spec 5: Zero-turbine subsample, SCI only
m5 <- feols(ordinance_adopted ~ sci_exposure_turbines |
              fips + year,
            data = panel_no_turb, cluster = ~state_fips)

# Spec 6: Zero-turbine, horse race
m6 <- feols(ordinance_adopted ~ sci_exposure_turbines + geo_exposure_turbines |
              fips + year,
            data = panel_no_turb, cluster = ~state_fips)

cat("\n--- Spec 5: Zero-turbine, SCI only ---\n")
summary(m5)
cat("\n--- Spec 6: Zero-turbine, horse race ---\n")
summary(m6)

# ============================================================================
# Event study: binned exposure quartiles
# ============================================================================
cat("\n=== Event Study ===\n")

# Create exposure quartile indicator based on 2024 SCI exposure
panel[, sci_q := cut(sci_exposure_turbines,
                     breaks = quantile(sci_exposure_turbines, probs = 0:4/4, na.rm = TRUE),
                     labels = paste0("Q", 1:4), include.lowest = TRUE)]

# For event study, need to define "treatment" timing
# Use continuous treatment: first year county's SCI exposure exceeds median
med_exposure <- median(panel[year == 2010]$sci_exposure_turbines, na.rm = TRUE)
panel[, high_exposure := fifelse(sci_exposure_turbines > med_exposure, 1L, 0L)]

# Event study using the interaction of high_exposure with year dummies
# Base period: 2005
es <- feols(ordinance_adopted ~ i(year, high_exposure, ref = 2005) |
              fips + year,
            data = panel[year >= 2000], cluster = ~state_fips)

cat("\nEvent study coefficients:\n")
print(coeftable(es))

# ============================================================================
# Standardized effects for interpretation
# ============================================================================
cat("\n=== Standardized Effects ===\n")

# 1 SD increase in SCI exposure
sd_sci <- sd(panel$sci_exposure_turbines, na.rm = TRUE)
sd_geo <- sd(panel$geo_exposure_turbines, na.rm = TRUE)
sd_y <- sd(panel[year < 2010]$ordinance_adopted, na.rm = TRUE)

cat("SD(SCI exposure):", sd_sci, "\n")
cat("SD(Geo exposure):", sd_geo, "\n")
cat("SD(Y, pre-2010):", sd_y, "\n")

# From horse race (m2)
beta_sci <- coef(m2)["sci_exposure_turbines"]
beta_geo <- coef(m2)["geo_exposure_turbines"]

cat("\nHorse race (Spec 2):\n")
cat("  SCI: 1 SD → ", beta_sci * sd_sci, "pp change in ordinance prob\n")
cat("  Geo: 1 SD → ", beta_geo * sd_geo, "pp change in ordinance prob\n")
cat("  SDE (SCI): ", (beta_sci * sd_sci) / sd_y, "\n")
cat("  SDE (Geo): ", (beta_geo * sd_geo) / sd_y, "\n")

# ============================================================================
# Save diagnostics
# ============================================================================
diag <- list(
  n_treated = sum(panel[year == 2024]$ordinance_adopted, na.rm = TRUE),
  n_pre = length(2000:2009),  # Pre-period years
  n_obs = nrow(panel),
  n_counties = uniqueN(panel$fips),
  n_states = uniqueN(panel$state_fips),
  n_zero_turb_adopt = sum(panel_no_turb[year == 2024]$ordinance_adopted, na.rm = TRUE),
  n_zero_turb_counties = uniqueN(panel_no_turb$fips),
  corr_sci_geo = cor(panel$sci_exposure_turbines, panel$geo_exposure_turbines,
                     use = "complete.obs"),
  beta_sci_horserace = unname(beta_sci),
  se_sci_horserace = unname(se(m2)["sci_exposure_turbines"]),
  beta_geo_horserace = unname(beta_geo),
  se_geo_horserace = unname(se(m2)["geo_exposure_turbines"]),
  sd_sci_exposure = sd_sci,
  sd_geo_exposure = sd_geo,
  sd_y_pre = sd_y
)

jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

# Save regression objects for table generation
save(m1, m2, m3, m4, m5, m6, es, panel, panel_no_turb,
     sd_sci, sd_geo, sd_y, beta_sci, beta_geo,
     file = file.path(DATA_DIR, "regressions.RData"))

cat("\nDiagnostics and regression objects saved.\n")
