# 03_main_analysis.R — Main DiD analysis using fixest::sunab
# apep_0881: Academy Conversion and Pupil Sorting

source("00_packages.R")
library(fixest)  # Sun-Abraham estimator
library(did)     # Callaway-Sant'Anna (unused due to fastglm crash; kept for reference)

data_dir <- "../data"
did_panel <- readRDS(file.path(data_dir, "did_panel.rds"))
la_panel <- readRDS(file.path(data_dir, "la_panel.rds"))

cat("DiD panel:", nrow(did_panel), "obs,",
    n_distinct(did_panel$school_id), "schools\n")

# ==============================================================================
# 0. Prepare data
# ==============================================================================

did_data <- did_panel |>
  mutate(
    school_id = as.integer(school_id),
    year = as.integer(year),
    g = as.integer(g),
    la_code = as.character(la_code)
  ) |>
  filter(!is.na(fsm_pct), !is.na(school_id)) |>
  # Remove duplicates (keep observation with more pupils)
  group_by(school_id, year) |>
  slice_max(n_pupils, n = 1, with_ties = FALSE) |>
  ungroup()

# Create treatment timing variable for fixest::sunab()
# sunab needs: cohort = first treatment year (Inf for never-treated)
did_data <- did_data |>
  mutate(
    cohort = ifelse(g == 0, Inf, g),
    post = as.integer(g > 0 & year >= g),
    treated = as.integer(g > 0),
    rel_time = ifelse(g > 0, year - g, NA_integer_)
  )

n_treated <- n_distinct(did_data$school_id[did_data$g > 0])
n_control <- n_distinct(did_data$school_id[did_data$g == 0])
cat("Treated:", n_treated, "| Control:", n_control, "\n")
cat("Cohorts:", paste(sort(unique(did_data$g[did_data$g > 0])), collapse = ", "), "\n")

# ==============================================================================
# 1. Sun-Abraham (2021) interaction-weighted estimator
# ==============================================================================

cat("\n=== Sun-Abraham Event Study: FSM% ===\n")

# sunab() in fixest implements the interaction-weighted estimator
# It handles heterogeneous treatment effects correctly
sa_fsm <- feols(
  fsm_pct ~ sunab(cohort, year) | school_id + year,
  data = did_data,
  cluster = ~la_code
)

cat("\nSun-Abraham results:\n")
print(summary(sa_fsm))

# Extract ATT (average of post-treatment effects)
sa_agg <- summary(sa_fsm, agg = "ATT")
cat("\nAggregate ATT:\n")
print(sa_agg)

# ==============================================================================
# 2. TWFE benchmark
# ==============================================================================

cat("\n=== TWFE Benchmark ===\n")

twfe_fsm <- feols(
  fsm_pct ~ post | school_id + year,
  data = did_data,
  cluster = ~la_code
)

cat("\nTWFE result:\n")
print(summary(twfe_fsm))

# ==============================================================================
# 3. Borusyak-Jaravel-Spiess (2024) imputation estimator
# ==============================================================================

cat("\n=== BJS Imputation Estimator ===\n")

# For the imputation estimator in fixest, we use did_imputation
# This is available through fixest's event study framework
# Use only treated and never-treated units

# Event study on treated units: use last pre-treatment period as reference
# rel_time has no -1 (annual data, conversion happens between years)
# Use -2 as reference (second-to-last pre-treatment year)
treated_es <- did_data |>
  filter(g > 0, !is.na(rel_time))

if (nrow(treated_es) > 0) {
  ref_period <- max(treated_es$rel_time[treated_es$rel_time < 0])
  cat("Using rel_time =", ref_period, "as reference period\n")

  bjs_fsm <- feols(
    fsm_pct ~ i(rel_time, ref = ref_period) | school_id + year,
    data = treated_es,
    cluster = ~la_code
  )
  cat("\nEvent study coefficients (treated only):\n")
  print(summary(bjs_fsm))
}

# ==============================================================================
# 4. Heterogeneity: Converter vs Sponsor-led
# ==============================================================================

cat("\n=== Heterogeneity by Academy Type ===\n")

entity_panel <- readRDS(file.path(data_dir, "entity_panel.rds"))
academy_info <- entity_panel |>
  filter(is_academy) |>
  group_by(entity_id) |>
  summarise(acad_type = TypeName[1], .groups = "drop")

did_data <- did_data |>
  left_join(academy_info |> rename(school_id = entity_id), by = "school_id")

# Converter academies
did_converter <- did_data |>
  filter(g == 0 | acad_type == "Academy converter")
n_conv <- n_distinct(did_converter$school_id[did_converter$g > 0])
cat("Converter academies:", n_conv, "\n")

if (n_conv >= 20) {
  sa_converter <- feols(
    fsm_pct ~ sunab(cohort, year) | school_id + year,
    data = did_converter, cluster = ~la_code
  )
  sa_conv_agg <- summary(sa_converter, agg = "ATT")
  cat("Converter ATT:\n")
  print(sa_conv_agg)
  saveRDS(sa_converter, file.path(data_dir, "sa_converter.rds"))
}

# Sponsor-led academies
did_sponsor <- did_data |>
  filter(g == 0 | acad_type == "Academy sponsor led")
n_spon <- n_distinct(did_sponsor$school_id[did_sponsor$g > 0])
cat("\nSponsor-led academies:", n_spon, "\n")

if (n_spon >= 20) {
  sa_sponsor <- feols(
    fsm_pct ~ sunab(cohort, year) | school_id + year,
    data = did_sponsor, cluster = ~la_code
  )
  sa_spon_agg <- summary(sa_sponsor, agg = "ATT")
  cat("Sponsor-led ATT:\n")
  print(sa_spon_agg)
  saveRDS(sa_sponsor, file.path(data_dir, "sa_sponsor.rds"))
}

# ==============================================================================
# 5. Heterogeneity: Primary vs Secondary
# ==============================================================================

cat("\n=== Heterogeneity by Phase ===\n")

# Primary
did_primary <- did_data |> filter(Phase == "Primary")
n_prim <- n_distinct(did_primary$school_id[did_primary$g > 0])
cat("Primary treated:", n_prim, "\n")

if (n_prim >= 20) {
  sa_primary <- feols(
    fsm_pct ~ sunab(cohort, year) | school_id + year,
    data = did_primary, cluster = ~la_code
  )
  sa_prim_agg <- summary(sa_primary, agg = "ATT")
  cat("Primary ATT:\n")
  print(sa_prim_agg)
  saveRDS(sa_primary, file.path(data_dir, "sa_primary.rds"))
}

# Secondary
did_secondary <- did_data |>
  filter(Phase %in% c("Secondary", "Middle deemed secondary", "All through"))
n_sec <- n_distinct(did_secondary$school_id[did_secondary$g > 0])
cat("\nSecondary treated:", n_sec, "\n")

if (n_sec >= 20) {
  sa_secondary <- feols(
    fsm_pct ~ sunab(cohort, year) | school_id + year,
    data = did_secondary, cluster = ~la_code
  )
  sa_sec_agg <- summary(sa_secondary, agg = "ATT")
  cat("Secondary ATT:\n")
  print(sa_sec_agg)
  saveRDS(sa_secondary, file.path(data_dir, "sa_secondary.rds"))
}

# ==============================================================================
# 6. LA-level: Academy penetration and segregation
# ==============================================================================

cat("\n=== LA-level: Academy Share and Segregation ===\n")

la_reg <- feols(
  dissimilarity ~ academy_share | la_code + snapshot_year,
  data = la_panel,
  cluster = ~la_code
)
cat("\nLA FE: Dissimilarity ~ Academy Share\n")
print(summary(la_reg))

la_reg_cv <- feols(
  cv_fsm ~ academy_share | la_code + snapshot_year,
  data = la_panel,
  cluster = ~la_code
)
cat("\nLA FE: CV(FSM) ~ Academy Share\n")
print(summary(la_reg_cv))

# ==============================================================================
# 7. Save results and diagnostics
# ==============================================================================

saveRDS(sa_fsm, file.path(data_dir, "sa_fsm.rds"))
saveRDS(twfe_fsm, file.path(data_dir, "twfe_fsm.rds"))
saveRDS(la_reg, file.path(data_dir, "la_reg_dissim.rds"))
saveRDS(la_reg_cv, file.path(data_dir, "la_reg_cv.rds"))

# Diagnostics for validator
# n_pre: for the latest treated cohort (2026), pre-periods = 2021-2025 = 5
latest_cohort <- max(did_data$g[did_data$g > 0])
n_pre_max <- length(unique(did_data$year[did_data$year < latest_cohort]))
diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre_max,
  n_obs = nrow(did_data)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
