## 03_main_analysis.R — Main DiD regressions
## apep_0818: Zombie Nonprofits

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Panel loaded:", nrow(panel), "rows,", n_distinct(panel$county_fips), "counties\n")

# ============================================================================
# 1. Summary Statistics
# ============================================================================
cat("\n=== Summary Statistics ===\n")

# Pre-period means by treatment intensity tercile
panel <- panel %>%
  mutate(intensity_tercile = ntile(revocation_intensity, 3))

pre_summary <- panel %>%
  filter(year < 2011) %>%
  group_by(intensity_tercile) %>%
  summarise(
    n_counties = n_distinct(county_fips),
    mean_revocation_intensity = mean(revocation_intensity, na.rm = TRUE),
    mean_formations = mean(new_formations, na.rm = TRUE),
    mean_formations_per_10k = mean(formations_per_10k, na.rm = TRUE),
    mean_np_employment = mean(np_employment, na.rm = TRUE),
    mean_charitable_per_return = mean(charitable_per_return, na.rm = TRUE),
    mean_population = mean(population, na.rm = TRUE),
    .groups = "drop"
  )

cat("Pre-period summary by treatment intensity tercile:\n")
print(pre_summary)

# ============================================================================
# 2. Main Specifications — New Nonprofit Formations
# ============================================================================
cat("\n=== Main Results: New Formations ===\n")

# Specification 1: Basic DiD
m1_form <- feols(
  formations_per_10k ~ intensity_x_post | county_fips + year,
  data = panel,
  cluster = ~county_fips
)

# Specification 2: With population control
m2_form <- feols(
  formations_per_10k ~ intensity_x_post + log(population) | county_fips + year,
  data = panel,
  cluster = ~county_fips
)

# Specification 3: County-specific linear trends
m3_form <- feols(
  formations_per_10k ~ intensity_x_post | county_fips[year] + year,
  data = panel,
  cluster = ~county_fips
)

cat("Formation results:\n")
etable(m1_form, m2_form, m3_form)

# ============================================================================
# 3. Main Specifications — Charitable Giving (post-period cross-section)
# ============================================================================
cat("\n=== Main Results: Charitable Giving ===\n")

# SOI county data only available 2011+ (no pre-period), so we cannot do DiD.
# Instead: post-period cross-sectional correlation (not causal, flagged in paper)
panel_soi <- panel %>% filter(!is.na(charitable_per_return), year >= 2011)
cat("SOI panel years:", sort(unique(panel_soi$year)), "\n")
cat("SOI panel rows:", nrow(panel_soi), "\n")

# Cross-sectional: does revocation intensity predict charitable giving levels?
m1_charity <- feols(
  charitable_per_return ~ revocation_intensity | year,
  data = panel_soi,
  cluster = ~county_fips
)

# With population control
m2_charity <- feols(
  charitable_per_return ~ revocation_intensity + log(population) | year,
  data = panel_soi,
  cluster = ~county_fips
)

# State FE to absorb regional variation
panel_soi <- panel_soi %>%
  mutate(state_fips = str_sub(county_fips, 1, 2))

m3_charity <- feols(
  charitable_per_return ~ revocation_intensity + log(population) | state_fips + year,
  data = panel_soi,
  cluster = ~county_fips
)

cat("Charitable giving results (cross-sectional, post-period only):\n")
etable(m1_charity, m2_charity, m3_charity)

# ============================================================================
# 4. Main Specifications — Nonprofit Employment
# ============================================================================
cat("\n=== Main Results: Nonprofit Employment ===\n")

panel_qwi <- panel %>% filter(!is.na(np_employment), np_employment > 0)

m1_emp <- feols(
  log(np_employment) ~ intensity_x_post | county_fips + year,
  data = panel_qwi,
  cluster = ~county_fips
)

m2_emp <- feols(
  log(np_employment) ~ intensity_x_post + log(population) | county_fips + year,
  data = panel_qwi,
  cluster = ~county_fips
)

m3_emp <- feols(
  log(np_employment) ~ intensity_x_post | county_fips[year] + year,
  data = panel_qwi,
  cluster = ~county_fips
)

cat("Nonprofit employment results:\n")
etable(m1_emp, m2_emp, m3_emp)

# ============================================================================
# 5. Event Study — Key Outcome (Formations)
# ============================================================================
cat("\n=== Event Study ===\n")

panel_es <- panel %>%
  mutate(
    rel_year = year - 2011,
    # Interact intensity with year dummies (omit -1 as reference)
    rel_year_factor = factor(rel_year)
  )

es_form <- feols(
  formations_per_10k ~ i(rel_year_factor, revocation_intensity, ref = "-1") | county_fips + year,
  data = panel_es,
  cluster = ~county_fips
)

cat("Event study coefficients:\n")
print(summary(es_form))

# Save event study coefficients for table
es_coefs <- as.data.frame(coeftable(es_form))
es_coefs$rel_year <- as.integer(gsub("rel_year_factor::(-?\\d+):revocation_intensity", "\\1",
                                      rownames(es_coefs)))
saveRDS(es_coefs, file.path(data_dir, "event_study_coefs.rds"))

# ============================================================================
# 6. Save All Model Objects
# ============================================================================
cat("\n=== Saving Model Objects ===\n")

models <- list(
  m1_form = m1_form, m2_form = m2_form, m3_form = m3_form,
  m1_charity = m1_charity, m2_charity = m2_charity, m3_charity = m3_charity,
  m1_emp = m1_emp, m2_emp = m2_emp, m3_emp = m3_emp,
  es_form = es_form
)
saveRDS(models, file.path(data_dir, "main_models.rds"))

# ============================================================================
# 7. Write diagnostics.json for validator
# ============================================================================
cat("\n=== Writing diagnostics.json ===\n")

n_counties <- n_distinct(panel$county_fips)
n_pre <- length(unique(panel$year[panel$year < 2011]))

diagnostics <- list(
  n_treated = n_counties,  # All counties have some treatment intensity
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_counties = n_counties,
  n_years = length(unique(panel$year)),
  outcome_sd_formations = sd(panel$formations_per_10k, na.rm = TRUE),
  outcome_sd_charity = sd(panel_soi$charitable_per_return, na.rm = TRUE),
  outcome_sd_emp = sd(log(panel_qwi$np_employment), na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("Diagnostics written.\n")
cat("n_treated:", diagnostics$n_treated, "\n")
cat("n_pre:", diagnostics$n_pre, "\n")
cat("n_obs:", diagnostics$n_obs, "\n")

cat("\n=== Main analysis complete ===\n")
