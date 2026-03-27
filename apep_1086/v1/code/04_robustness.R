# 04_robustness.R — Robustness checks
# APEP Paper apep_1086: CAA Attainment Redesignation

source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# ============================================================================
# 1. Placebo: Non-manufacturing employment (services should be unaffected)
# ============================================================================
cat("=== Placebo: Services (non-manufacturing) employment would need separate QWI pull ===\n")
cat("Skipping for V1 — services data not pre-fetched.\n")
cat("Alternative placebo: earlier redesignation years as fake treatment\n\n")

# Placebo: assign fake redesignation 3 years before actual
panel_placebo <- panel %>%
  filter(ever_treated) %>%
  mutate(
    fake_redesig = first_redesig_year - 3,
    fake_post = year >= fake_redesig & year < first_redesig_year
  ) %>%
  # Only use pre-treatment period
  filter(year < first_redesig_year)

if (nrow(panel_placebo) > 100) {
  placebo_twfe <- feols(log_mfg_emp ~ fake_post | fips + year,
                        data = panel_placebo, cluster = ~fips)
  cat("Placebo TWFE (fake treatment 3 years early):\n")
  print(summary(placebo_twfe))
} else {
  cat("Insufficient observations for placebo test\n")
}

# ============================================================================
# 2. Alternative control group: ever-nonattainment only
# ============================================================================
cat("\n=== Robustness: Ever-nonattainment controls only ===\n")

# Include only counties that were ever in nonattainment
# (some redesignated, some still nonattainment)
ever_nonattain <- panel %>%
  group_by(fips) %>%
  summarise(ever_na = any(any_nonattain, na.rm = TRUE), .groups = "drop") %>%
  filter(ever_na) %>%
  pull(fips)

panel_ever_na <- panel %>%
  filter(fips %in% ever_nonattain | ever_treated)

cat("Ever-nonattainment sample:", n_distinct(panel_ever_na$fips), "counties,",
    nrow(panel_ever_na), "obs\n")
cat("Treated:", sum(panel_ever_na$ever_treated & !duplicated(panel_ever_na$fips)), "\n")
cat("Controls:", sum(!panel_ever_na$ever_treated & !duplicated(panel_ever_na$fips)), "\n")

if (sum(!panel_ever_na$ever_treated & !duplicated(panel_ever_na$fips)) >= 10) {
  twfe_ever_na <- feols(log_mfg_emp ~ post | fips + year,
                        data = panel_ever_na, cluster = ~fips)
  cat("TWFE (ever-nonattainment controls):\n")
  print(summary(twfe_ever_na))
} else {
  cat("Too few controls in ever-nonattainment sample\n")
}

# ============================================================================
# 3. Heterogeneity: by pre-treatment manufacturing intensity
# ============================================================================
cat("\n=== Heterogeneity: Manufacturing intensity ===\n")

# Compute pre-treatment average manufacturing employment
pre_avg <- panel %>%
  filter(!post | !ever_treated) %>%
  group_by(fips) %>%
  summarise(
    pre_mfg_emp = mean(mfg_emp, na.rm = TRUE),
    .groups = "drop"
  )

panel <- panel %>%
  left_join(pre_avg, by = "fips", suffix = c("", ".pre"))

# Split at median pre-treatment manufacturing employment
med_mfg <- median(pre_avg$pre_mfg_emp[pre_avg$fips %in%
                    panel$fips[panel$ever_treated]], na.rm = TRUE)
cat("Median pre-treatment mfg employment (treated):", round(med_mfg), "\n")

panel <- panel %>%
  mutate(high_mfg = pre_mfg_emp >= med_mfg)

# High manufacturing counties
twfe_high_mfg <- feols(log_mfg_emp ~ post | fips + year,
                       data = filter(panel, high_mfg == TRUE),
                       cluster = ~fips)

# Low manufacturing counties
twfe_low_mfg <- feols(log_mfg_emp ~ post | fips + year,
                      data = filter(panel, high_mfg == FALSE),
                      cluster = ~fips)

cat("\nHigh manufacturing counties:\n")
print(summary(twfe_high_mfg))
cat("\nLow manufacturing counties:\n")
print(summary(twfe_low_mfg))

# ============================================================================
# 4. Heterogeneity: by pollutant type
# ============================================================================
cat("\n=== Heterogeneity: Pollutant type ===\n")

# Get pollutant info from PHISTORY redesignation data
phistory <- read_xls(file.path(data_dir, "phistory.xls"))
phistory <- phistory %>%
  mutate(fips = paste0(sprintf("%02d", as.integer(fips_state)),
                       sprintf("%03d", as.integer(fips_cnty))))
year_cols <- grep("^pw_", names(phistory), value = TRUE)
ph_long <- phistory %>%
  select(fips, pollutant, all_of(year_cols)) %>%
  pivot_longer(cols = all_of(year_cols), names_to = "year", values_to = "status") %>%
  mutate(year = as.integer(gsub("pw_", "", year)),
         is_nonattain = status %in% c("P", "W"))
ph_long <- ph_long %>%
  arrange(fips, pollutant, year) %>%
  group_by(fips, pollutant) %>%
  mutate(lag_na = lag(is_nonattain),
         redesig = !is.na(lag_na) & lag_na & !is_nonattain) %>%
  ungroup()
redesig_poll <- ph_long %>%
  filter(redesig) %>%
  distinct(fips, pollutant) %>%
  mutate(ozone_redesig = grepl("Ozone", pollutant),
         pm_redesig = grepl("PM", pollutant))
fips_ozone <- redesig_poll %>% filter(ozone_redesig) %>% pull(fips) %>% unique()
fips_pm <- redesig_poll %>% filter(pm_redesig) %>% pull(fips) %>% unique()

panel <- panel %>%
  mutate(ozone_redesig = fips %in% fips_ozone,
         pm_redesig = fips %in% fips_pm)

# Ozone redesignations
panel_ozone <- panel %>%
  filter(ozone_redesig == TRUE | !ever_treated)

if (sum(panel_ozone$ever_treated & !duplicated(panel_ozone$fips)) >= 20) {
  twfe_ozone <- feols(log_mfg_emp ~ post | fips + year,
                      data = panel_ozone, cluster = ~fips)
  cat("TWFE (Ozone redesignations):\n")
  print(summary(twfe_ozone))
}

# PM redesignations
panel_pm <- panel %>%
  filter(pm_redesig == TRUE | !ever_treated)

if (sum(panel_pm$ever_treated & !duplicated(panel_pm$fips)) >= 20) {
  twfe_pm <- feols(log_mfg_emp ~ post | fips + year,
                   data = panel_pm, cluster = ~fips)
  cat("\nTWFE (PM redesignations):\n")
  print(summary(twfe_pm))
}

# ============================================================================
# 5. Leave-one-cohort-out
# ============================================================================
cat("\n=== Leave-one-cohort-out ===\n")

# Drop the largest cohort (2005) and re-estimate
panel_no2005 <- panel %>%
  filter(first_redesig_year != 2005 | !ever_treated)

twfe_no2005 <- feols(log_mfg_emp ~ post | fips + year,
                     data = panel_no2005, cluster = ~fips)
cat("TWFE (excluding 2005 cohort, N=173):\n")
print(summary(twfe_no2005))

# Drop 2007 cohort
panel_no2007 <- panel %>%
  filter(first_redesig_year != 2007 | !ever_treated)

twfe_no2007 <- feols(log_mfg_emp ~ post | fips + year,
                     data = panel_no2007, cluster = ~fips)
cat("\nTWFE (excluding 2007 cohort, N=43):\n")
print(summary(twfe_no2007))

# ============================================================================
# 6. Save robustness results
# ============================================================================
cat("\n=== Saving Robustness Results ===\n")

robustness <- list(
  placebo_twfe = if (exists("placebo_twfe")) placebo_twfe else NULL,
  twfe_ever_na = if (exists("twfe_ever_na")) twfe_ever_na else NULL,
  twfe_high_mfg = twfe_high_mfg,
  twfe_low_mfg = twfe_low_mfg,
  twfe_ozone = if (exists("twfe_ozone")) twfe_ozone else NULL,
  twfe_pm = if (exists("twfe_pm")) twfe_pm else NULL,
  twfe_no2005 = twfe_no2005,
  twfe_no2007 = twfe_no2007
)

# Update analysis panel with new variables
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness Complete ===\n")
