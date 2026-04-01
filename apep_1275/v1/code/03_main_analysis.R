# 03_main_analysis.R — Main regressions for Pakistan 2022 Floods paper

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load panel
# ============================================================================
cat("=== Loading analysis panel ===\n")

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
cat("  Panel:", nrow(panel), "observations,",
    length(unique(panel$tehsil_id)), "units\n")

# Ensure factor types
panel[, tehsil_id := as.factor(tehsil_id)]
panel[, season_year := as.factor(season_year)]
panel[, district := as.factor(district)]

# Create binned treatment × post interactions (needed for binned spec)
panel[, flood_low_post := as.integer(flood_group == "low") * post]
panel[, flood_mod_post := as.integer(flood_group == "moderate") * post]
panel[, flood_sev_post := as.integer(flood_group == "severe") * post]

# ============================================================================
# 2. Main specification: Continuous treatment DiD
# ============================================================================
cat("\n=== Main Specification: Continuous Treatment DiD ===\n")

# --- Pooled (all seasons) ---
# Linear dose-response
m1_linear <- fixest::feols(
  ndvi_mean ~ flood_x_post | tehsil_id + season_year,
  data = panel, cluster = ~district
)

# Quadratic dose-response (non-monotonic test)
m1_quad <- fixest::feols(
  ndvi_mean ~ flood_x_post + flood_sq_x_post | tehsil_id + season_year,
  data = panel, cluster = ~district
)

cat("  Pooled linear:\n")
print(summary(m1_linear))
cat("\n  Pooled quadratic:\n")
print(summary(m1_quad))

# --- By season type ---
cat("\n=== Season-Specific Regressions ===\n")

# Kharif (summer) — expect monotonic negative
kharif <- panel[season_type == "kharif"]
m2_kharif_lin <- fixest::feols(
  ndvi_mean ~ flood_x_post | tehsil_id + season_year,
  data = kharif, cluster = ~district
)
m2_kharif_quad <- fixest::feols(
  ndvi_mean ~ flood_x_post + flood_sq_x_post | tehsil_id + season_year,
  data = kharif, cluster = ~district
)

# Rabi (winter) — expect non-monotonic (inverted U)
rabi <- panel[season_type == "rabi"]
m2_rabi_lin <- fixest::feols(
  ndvi_mean ~ flood_x_post | tehsil_id + season_year,
  data = rabi, cluster = ~district
)
m2_rabi_quad <- fixest::feols(
  ndvi_mean ~ flood_x_post + flood_sq_x_post | tehsil_id + season_year,
  data = rabi, cluster = ~district
)

cat("  Kharif linear:\n")
print(summary(m2_kharif_lin))
cat("\n  Kharif quadratic:\n")
print(summary(m2_kharif_quad))
cat("\n  Rabi linear:\n")
print(summary(m2_rabi_lin))
cat("\n  Rabi quadratic:\n")
print(summary(m2_rabi_quad))

# ============================================================================
# 3. Binned treatment specification (for readability)
# ============================================================================
cat("\n=== Binned Treatment Specification ===\n")

m3_binned <- fixest::feols(
  ndvi_mean ~ flood_low_post + flood_mod_post + flood_sev_post |
    tehsil_id + season_year,
  data = panel, cluster = ~district
)

m3_kharif_bin <- fixest::feols(
  ndvi_mean ~ flood_low_post + flood_mod_post + flood_sev_post |
    tehsil_id + season_year,
  data = kharif, cluster = ~district
)

m3_rabi_bin <- fixest::feols(
  ndvi_mean ~ flood_low_post + flood_mod_post + flood_sev_post |
    tehsil_id + season_year,
  data = rabi, cluster = ~district
)

cat("  Pooled binned:\n")
print(summary(m3_binned))
cat("\n  Kharif binned:\n")
print(summary(m3_kharif_bin))
cat("\n  Rabi binned:\n")
print(summary(m3_rabi_bin))

# ============================================================================
# 4. Event study specification (pre-trends test)
# ============================================================================
cat("\n=== Event Study (Pre-Trends Test) ===\n")

# Create relative time variable
# Kharif 2022 is the treatment season
panel[, rel_time := fcase(
  season_id == "kharif_2019", -6L,
  season_id == "rabi_20192020", -5L,
  season_id == "kharif_2020", -4L,
  season_id == "rabi_20202021", -3L,
  season_id == "kharif_2021", -2L,
  season_id == "rabi_20212022", -1L,
  season_id == "kharif_2022", 0L,
  season_id == "rabi_20222023", 1L,
  season_id == "kharif_2023", 2L,
  season_id == "rabi_20232024", 3L,
  default = NA_integer_
)]

panel[, rel_time_f := factor(rel_time)]

# Event study: interact flood intensity with each period dummy
# Base period: rel_time == -1 (rabi 2021/22, last pre-flood season)
m4_event <- fixest::feols(
  ndvi_mean ~ i(rel_time_f, pct_flooded, ref = "-1") | tehsil_id + season_year,
  data = panel[!is.na(rel_time)], cluster = ~district
)

cat("  Event study coefficients:\n")
print(summary(m4_event))

# ============================================================================
# 5. Save all regression results
# ============================================================================
cat("\n=== Saving results ===\n")

results <- list(
  m1_linear = m1_linear,
  m1_quad = m1_quad,
  m2_kharif_lin = m2_kharif_lin,
  m2_kharif_quad = m2_kharif_quad,
  m2_rabi_lin = m2_rabi_lin,
  m2_rabi_quad = m2_rabi_quad,
  m3_binned = m3_binned,
  m3_kharif_bin = m3_kharif_bin,
  m3_rabi_bin = m3_rabi_bin,
  m4_event = m4_event
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================================
# 6. Write diagnostics.json for validator
# ============================================================================
n_treated <- length(unique(panel[pct_flooded >= 5, tehsil_id]))
n_pre <- length(unique(panel[post == 0, season_year]))
n_obs <- nrow(panel)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs,
    n_units = length(unique(panel$tehsil_id)),
    n_districts = length(unique(panel$district))
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat("  Diagnostics: n_treated =", n_treated, ", n_pre =", n_pre,
    ", n_obs =", n_obs, "\n")
cat("\n=== Main analysis complete ===\n")
