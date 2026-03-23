## 04_robustness.R — Robustness checks and placebo tests
## apep_0818: Zombie Nonprofits

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
models <- readRDS(file.path(data_dir, "main_models.rds"))

cat("Panel loaded:", nrow(panel), "rows\n")

# ============================================================================
# 1. Placebo Test: Pre-Period Only (Formations)
# ============================================================================
cat("\n=== Placebo: Pre-Period Only ===\n")

# Use 2006-2010, with fake treatment at 2009
panel_placebo <- panel %>%
  filter(year <= 2010) %>%
  mutate(
    placebo_post = as.integer(year >= 2009),
    placebo_intensity_x_post = revocation_intensity * placebo_post
  )

placebo_form <- feols(
  formations_per_10k ~ placebo_intensity_x_post | county_fips + year,
  data = panel_placebo,
  cluster = ~county_fips
)

cat("Placebo (formations, fake 2009 treatment):\n")
print(summary(placebo_form))

# ============================================================================
# 2. Dropping Extreme Counties
# ============================================================================
cat("\n=== Robustness: Trimmed Sample ===\n")

# Drop top and bottom 10% of revocation intensity
q10 <- quantile(panel$revocation_intensity, 0.10, na.rm = TRUE)
q90 <- quantile(panel$revocation_intensity, 0.90, na.rm = TRUE)

panel_trimmed <- panel %>%
  filter(revocation_intensity >= q10, revocation_intensity <= q90)

trimmed_form <- feols(
  formations_per_10k ~ intensity_x_post | county_fips + year,
  data = panel_trimmed,
  cluster = ~county_fips
)

cat("Trimmed sample (formations):\n")
print(summary(trimmed_form))

# ============================================================================
# 3. Alternative Treatment: Binary High/Low
# ============================================================================
cat("\n=== Robustness: Binary Treatment ===\n")

panel <- panel %>%
  mutate(
    high_revocation = as.integer(revocation_intensity > median(revocation_intensity, na.rm = TRUE)),
    high_x_post = high_revocation * post
  )

binary_form <- feols(
  formations_per_10k ~ high_x_post | county_fips + year,
  data = panel,
  cluster = ~county_fips
)

cat("Binary treatment (formations):\n")
print(summary(binary_form))

# ============================================================================
# 4. Controlling for Pre-Trend Characteristics
# ============================================================================
cat("\n=== Robustness: Additional Controls ===\n")

# Add pre-period mean outcome as control (interacted with year)
pre_means <- panel %>%
  filter(year < 2011) %>%
  group_by(county_fips) %>%
  summarise(
    pre_mean_formations = mean(formations_per_10k, na.rm = TRUE),
    pre_mean_pop = mean(population, na.rm = TRUE),
    .groups = "drop"
  )

panel_ctrl <- panel %>%
  left_join(pre_means, by = "county_fips") %>%
  mutate(
    pre_form_x_post = pre_mean_formations * post
  )

controlled_form <- feols(
  formations_per_10k ~ intensity_x_post + pre_form_x_post + log(population) | county_fips + year,
  data = panel_ctrl,
  cluster = ~county_fips
)

cat("With pre-period controls (formations):\n")
print(summary(controlled_form))

# ============================================================================
# 5. Nonprofit Earnings (alternative employment outcome)
# ============================================================================
cat("\n=== Robustness: Nonprofit Earnings ===\n")

panel_earn <- panel %>% filter(!is.na(np_earnings), np_earnings > 0)

earn_model <- feols(
  log(np_earnings) ~ intensity_x_post | county_fips + year,
  data = panel_earn,
  cluster = ~county_fips
)

cat("Nonprofit earnings:\n")
print(summary(earn_model))

# ============================================================================
# 6. Save Robustness Models
# ============================================================================
rob_models <- list(
  placebo_form = placebo_form,
  trimmed_form = trimmed_form,
  binary_form = binary_form,
  controlled_form = controlled_form,
  earn_model = earn_model
)

saveRDS(rob_models, file.path(data_dir, "robustness_models.rds"))
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))  # Updated with binary treatment

cat("\n=== Robustness checks complete ===\n")
