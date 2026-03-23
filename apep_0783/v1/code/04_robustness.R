## 04_robustness.R — Robustness checks
## apep_0783: USPS POStPlan and Rural Business Formation

source("00_packages.R")

data_dir <- "../data/"
load(file.path(data_dir, "models.RData"))

cat("Panel loaded:", nrow(panel), "county-years\n")

# ============================================================
# 1. Pre-COVID sample (2005-2019)
# ============================================================
cat("\n=== Robustness 1: Pre-COVID sample (2005-2019) ===\n")

panel_precovid <- panel %>% filter(year <= 2019)

r1_binary <- feols(
  log_ba ~ treat_post | county_fips + year,
  data = panel_precovid,
  cluster = ~state_fips
)

r1_dose <- feols(
  log_ba ~ dose_post | county_fips + year,
  data = panel_precovid,
  cluster = ~state_fips
)

cat("Pre-COVID Binary DiD: β =", round(coef(r1_binary)["treat_post"], 4),
    " SE =", round(se(r1_binary)["treat_post"], 4),
    " p =", round(pvalue(r1_binary)["treat_post"], 4), "\n")
cat("Pre-COVID Dose DiD:   β =", round(coef(r1_dose)["dose_post"], 4),
    " SE =", round(se(r1_dose)["dose_post"], 4),
    " p =", round(pvalue(r1_dose)["dose_post"], 4), "\n")

# ============================================================
# 2. Level specification (BA counts, not logs)
# ============================================================
cat("\n=== Robustness 2: Level specification ===\n")

r2_level <- feols(
  ba ~ treat_post | county_fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Level (BA count) Binary DiD: β =", round(coef(r2_level)["treat_post"], 2),
    " SE =", round(se(r2_level)["treat_post"], 2),
    " p =", round(pvalue(r2_level)["treat_post"], 4), "\n")

# ============================================================
# 3. Asinh transformation
# ============================================================
cat("\n=== Robustness 3: Asinh transformation ===\n")

panel$asinh_ba <- asinh(panel$ba)

r3_asinh <- feols(
  asinh_ba ~ treat_post | county_fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Asinh Binary DiD: β =", round(coef(r3_asinh)["treat_post"], 4),
    " SE =", round(se(r3_asinh)["treat_post"], 4),
    " p =", round(pvalue(r3_asinh)["treat_post"], 4), "\n")

# ============================================================
# 4. Rural counties only (exclude metros)
# ============================================================
cat("\n=== Robustness 4: Rural counties only ===\n")

# Define rural as counties in bottom quartile of pre-treatment BA
pre_ba <- panel %>%
  filter(year < 2013) %>%
  group_by(county_fips) %>%
  summarise(mean_pre_ba = mean(ba, na.rm = TRUE), .groups = "drop")

rural_cutoff <- quantile(pre_ba$mean_pre_ba, 0.75, na.rm = TRUE)
rural_counties <- pre_ba$county_fips[pre_ba$mean_pre_ba <= rural_cutoff]

panel_rural <- panel %>% filter(county_fips %in% rural_counties)

r4_rural <- feols(
  log_ba ~ treat_post | county_fips + year,
  data = panel_rural,
  cluster = ~state_fips
)

cat("Rural-only Binary DiD: β =", round(coef(r4_rural)["treat_post"], 4),
    " SE =", round(se(r4_rural)["treat_post"], 4),
    " p =", round(pvalue(r4_rural)["treat_post"], 4), "\n")
cat("Rural counties:", n_distinct(panel_rural$county_fips), "\n")

# ============================================================
# 5. Placebo treatment: Level 18 upgrades only
# ============================================================
cat("\n=== Robustness 5: Placebo — Level 18 (upgraded) offices ===\n")

county_treatment <- readRDS(file.path(data_dir, "county_treatment.rds"))

# Counties where ALL POStPlan offices were Level 18 (upgraded, not reduced)
level18_only <- county_treatment %>%
  filter(n_po_treated == 0, n_po_18 > 0) %>%
  pull(county_fips)

cat("Counties with Level 18 only (no hour reductions):", length(level18_only), "\n")

# Build placebo: Level 18 counties vs. counties with no POStPlan offices
placebo_panel <- panel %>%
  filter(!ever_treated) %>%  # Only counties without hour reductions
  mutate(
    placebo_treated = county_fips %in% level18_only,
    placebo_post = placebo_treated * post
  )

if (sum(placebo_panel$placebo_treated & placebo_panel$year == 2012) >= 10) {
  r5_placebo <- feols(
    log_ba ~ placebo_post | county_fips + year,
    data = placebo_panel,
    cluster = ~state_fips
  )

  cat("Placebo (Level 18 vs no POStPlan): β =",
      round(coef(r5_placebo)["placebo_post"], 4),
      " SE =", round(se(r5_placebo)["placebo_post"], 4),
      " p =", round(pvalue(r5_placebo)["placebo_post"], 4), "\n")
} else {
  cat("Too few Level 18-only counties for placebo test\n")
  r5_placebo <- NULL
}

# ============================================================
# 6. Placebo treatment year (2009 instead of 2013)
# ============================================================
cat("\n=== Robustness 6: Placebo timing (2009) ===\n")

panel_placebo_time <- panel %>%
  filter(year <= 2012) %>%
  mutate(
    fake_post = year >= 2009,
    fake_treat_post = ever_treated * fake_post
  )

r6_placebo_time <- feols(
  log_ba ~ fake_treat_post | county_fips + year,
  data = panel_placebo_time,
  cluster = ~state_fips
)

cat("Placebo timing (2009): β =", round(coef(r6_placebo_time)["fake_treat_post"], 4),
    " SE =", round(se(r6_placebo_time)["fake_treat_post"], 4),
    " p =", round(pvalue(r6_placebo_time)["fake_treat_post"], 4), "\n")

# ============================================================
# 7. State × year fixed effects
# ============================================================
cat("\n=== Robustness 7: State × year FE ===\n")

r7_styr <- feols(
  log_ba ~ treat_post | county_fips + state_fips^year,
  data = panel,
  cluster = ~state_fips
)

cat("State×Year FE Binary DiD: β =", round(coef(r7_styr)["treat_post"], 4),
    " SE =", round(se(r7_styr)["treat_post"], 4),
    " p =", round(pvalue(r7_styr)["treat_post"], 4), "\n")

r7_dose_styr <- feols(
  log_ba ~ dose_post | county_fips + state_fips^year,
  data = panel,
  cluster = ~state_fips
)

cat("State×Year FE Dose DiD:   β =", round(coef(r7_dose_styr)["dose_post"], 4),
    " SE =", round(se(r7_dose_styr)["dose_post"], 4),
    " p =", round(pvalue(r7_dose_styr)["dose_post"], 4), "\n")

# ============================================================
# Save robustness models
# ============================================================
save(r1_binary, r1_dose, r2_level, r3_asinh, r4_rural,
     r5_placebo, r6_placebo_time, r7_styr, r7_dose_styr,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n=== Robustness checks complete ===\n")
