## 03_main_analysis.R
## The Housing Cost of Reshoring: CHIPS Act and Local Housing Markets
## Main DiD estimation: Callaway-Sant'Anna + TWFE event study

source("00_packages.R")

data_dir <- "../data"

panel_zhvi <- readRDS(file.path(data_dir, "panel_zhvi.rds"))
panel_zori <- readRDS(file.path(data_dir, "panel_zori.rds"))

# ============================================================
# 1. Callaway-Sant'Anna: ZHVI
# ============================================================
cat("=== Callaway-Sant'Anna: Home Values (ZHVI) ===\n")

# Need numeric county ID for C-S
panel_zhvi <- panel_zhvi %>%
  mutate(county_id = as.numeric(factor(county_fips)))

# C-S requires: yname, tname, idname, gname
# gname = first treatment period (0 for never-treated)
cs_zhvi <- att_gt(
  yname = "log_zhvi",
  tname = "time_index",
  idname = "county_id",
  gname = "first_treat",
  data = panel_zhvi,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

cat("\nGroup-time ATTs computed:", length(cs_zhvi$att), "estimates\n")

# Aggregate to event-study (dynamic effects)
es_zhvi <- aggte(cs_zhvi, type = "dynamic", min_e = -24, max_e = 18)
cat("\nEvent study aggregation:\n")
summary(es_zhvi)

# Overall ATT
overall_zhvi <- aggte(cs_zhvi, type = "simple")
cat("\nOverall ATT (ZHVI):\n")
summary(overall_zhvi)

# Save C-S results
saveRDS(cs_zhvi, file.path(data_dir, "cs_zhvi.rds"))
saveRDS(es_zhvi, file.path(data_dir, "es_zhvi.rds"))
saveRDS(overall_zhvi, file.path(data_dir, "overall_zhvi.rds"))

# ============================================================
# 2. Callaway-Sant'Anna: ZORI (Rents)
# ============================================================
cat("\n=== Callaway-Sant'Anna: Rents (ZORI) ===\n")

panel_zori <- panel_zori %>%
  mutate(county_id = as.numeric(factor(county_fips)))

# Check how many treated counties have ZORI data
n_treat_zori <- panel_zori %>%
  filter(treated) %>%
  pull(county_fips) %>%
  n_distinct()
cat("Treated counties with ZORI data:", n_treat_zori, "\n")

if (n_treat_zori >= 3) {
  cs_zori <- att_gt(
    yname = "log_zori",
    tname = "time_index",
    idname = "county_id",
    gname = "first_treat",
    data = panel_zori,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )

  es_zori <- aggte(cs_zori, type = "dynamic", min_e = -24, max_e = 18, na.rm = TRUE)
  overall_zori <- aggte(cs_zori, type = "simple", na.rm = TRUE)

  cat("\nOverall ATT (ZORI):\n")
  summary(overall_zori)

  saveRDS(cs_zori, file.path(data_dir, "cs_zori.rds"))
  saveRDS(es_zori, file.path(data_dir, "es_zori.rds"))
  saveRDS(overall_zori, file.path(data_dir, "overall_zori.rds"))
} else {
  cat("WARNING: Too few treated counties with ZORI. Skipping.\n")
}

# ============================================================
# 3. TWFE Event Study (fixest) — complementary specification
# ============================================================
cat("\n=== TWFE Event Study (fixest): ZHVI ===\n")

# Create binned event-time indicators
panel_zhvi <- panel_zhvi %>%
  mutate(
    event_time_binned = case_when(
      !treated ~ NA_real_,
      event_time < -24 ~ -24,
      event_time > 18 ~ 18,
      TRUE ~ event_time
    )
  )

# Sunab (Sun-Abraham) estimator via fixest
twfe_zhvi <- feols(
  log_zhvi ~ sunab(first_treat, time_index) | county_fips + time_index,
  data = panel_zhvi %>% filter(first_treat > 0 | first_treat == 0),
  cluster = ~county_fips
)

cat("\nSun-Abraham TWFE estimates:\n")
summary(twfe_zhvi)

saveRDS(twfe_zhvi, file.path(data_dir, "twfe_zhvi.rds"))

# ============================================================
# 4. Static DiD (simple ATT)
# ============================================================
cat("\n=== Static DiD: ZHVI ===\n")

static_zhvi <- feols(
  log_zhvi ~ treated:post | county_fips + time_index,
  data = panel_zhvi,
  cluster = ~county_fips
)

cat("Static DiD coefficient (treated x post):\n")
print(coeftable(static_zhvi))

saveRDS(static_zhvi, file.path(data_dir, "static_zhvi.rds"))

# Rents
if (n_treat_zori >= 3) {
  static_zori <- feols(
    log_zori ~ treated:post | county_fips + time_index,
    data = panel_zori,
    cluster = ~county_fips
  )
  cat("\nStatic DiD coefficient (ZORI):\n")
  print(coeftable(static_zori))
  saveRDS(static_zori, file.path(data_dir, "static_zori.rds"))
}

# ============================================================
# 5. Dose-response: Award size per housing unit
# ============================================================
cat("\n=== Dose-Response: Award per Housing Unit ===\n")

panel_zhvi <- panel_zhvi %>%
  mutate(
    award_per_hunit = ifelse(treated & !is.na(housing_units) & housing_units > 0,
                              total_award_billion * 1e9 / housing_units,
                              0),
    dose_post = award_per_hunit * post
  )

dose_zhvi <- feols(
  log_zhvi ~ dose_post | county_fips + time_index,
  data = panel_zhvi,
  cluster = ~county_fips
)

cat("Dose-response (award $/housing unit x post):\n")
print(coeftable(dose_zhvi))

saveRDS(dose_zhvi, file.path(data_dir, "dose_zhvi.rds"))

# ============================================================
# 6. Diagnostics for validation
# ============================================================
n_treated <- panel_zhvi %>%
  filter(treated) %>%
  pull(county_fips) %>%
  n_distinct()

n_pre <- panel_zhvi %>%
  filter(treated) %>%
  filter(event_time < 0) %>%
  pull(event_time) %>%
  n_distinct()

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = nrow(panel_zhvi),
    n_control = panel_zhvi %>% filter(!treated) %>% pull(county_fips) %>% n_distinct(),
    att_zhvi = overall_zhvi$overall.att,
    att_zhvi_se = overall_zhvi$overall.se
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat("Treated counties:", n_treated, "\n")
cat("Pre-periods:", n_pre, "\n")
cat("Total obs:", nrow(panel_zhvi), "\n")
