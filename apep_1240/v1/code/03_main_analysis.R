## ── 03_main_analysis.R ─────────────────────────────────────────
## Main DiD estimation: effect of CGWB overexploited classification
## on groundwater depletion

source("00_packages.R")

data_dir <- "../data"
district_panel <- fread(file.path(data_dir, "district_panel_clean.csv"))
wells_long <- fread(file.path(data_dir, "wells_long_clean.csv"))
state_treatment <- fread(file.path(data_dir, "state_treatment.csv"))
assessment_data <- fread(file.path(data_dir, "assessment_rounds.csv"))

cat("=== Main Analysis ===\n")

## ── 1. TWFE District-Level DiD ──────────────────────────────────
cat("\n--- Specification 1: TWFE District DiD ---\n")

# Baseline: continuous treatment (oe_share)
fit1_cont <- feols(
  mean_depth ~ oe_share | district_id + year,
  data = district_panel,
  cluster = ~STATE
)
cat("Continuous treatment (oe_share):\n")
summary(fit1_cont)

# Binary treatment
fit1_bin <- feols(
  mean_depth ~ treat_post | district_id + year,
  data = district_panel,
  cluster = ~STATE
)
cat("\nBinary treatment (treat × post):\n")
summary(fit1_bin)

## ── 2. Event Study ──────────────────────────────────────────────
cat("\n--- Specification 2: Event Study ---\n")

# Create event-time dummies (bin extremes)
district_panel[, rel_year_binned := fifelse(
  is.na(rel_year), NA_integer_,
  pmax(-8L, pmin(rel_year, 10L))
)]

# Event study with fixest::sunab() for staggered design
# Need cohort and period variables
district_panel[, cohort := fifelse(treated, first_high_round, 10000L)]

fit2_sa <- feols(
  mean_depth ~ sunab(cohort, year) | district_id + year,
  data = district_panel,
  cluster = ~STATE
)
cat("Sun-Abraham event study:\n")
summary(fit2_sa)

## ── 3. Callaway-Sant'Anna ───────────────────────────────────────
cat("\n--- Specification 3: Callaway-Sant'Anna ---\n")

# Prepare data for did package
cs_data <- district_panel[, .(
  district_id = district_id,
  year = as.integer(year),
  mean_depth = mean_depth,
  cohort = fifelse(treated, as.integer(first_high_round), 0L),
  state = STATE
)]
cs_data <- cs_data[!is.na(mean_depth)]

# Create numeric district ID
cs_data[, did := as.numeric(factor(district_id))]

# Run CS estimator
cs_out <- tryCatch({
  att_gt(
    yname = "mean_depth",
    tname = "year",
    idname = "did",
    gname = "cohort",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr"
  )
}, error = function(e) {
  cat("CS estimation error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  cs_agg <- aggte(cs_out, type = "simple")
  cat("CS aggregate ATT:\n")
  print(summary(cs_agg))

  cs_dyn <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 10)
  cat("\nCS dynamic ATT:\n")
  print(summary(cs_dyn))

  # Save CS results
  saveRDS(cs_out, file.path(data_dir, "cs_results.rds"))
  saveRDS(cs_dyn, file.path(data_dir, "cs_dynamic.rds"))
}

## ── 4. Well-Level Analysis ──────────────────────────────────────
cat("\n--- Specification 4: Well-Level TWFE ---\n")

# Well-level gives more precision
fit4 <- feols(
  depth_to_water ~ treat_post | WLCODE + year,
  data = wells_long,
  cluster = ~STATE
)
cat("Well-level binary DiD:\n")
summary(fit4)

# Continuous treatment at well level
fit4_cont <- feols(
  depth_to_water ~ oe_share | WLCODE + year,
  data = wells_long,
  cluster = ~STATE
)
cat("\nWell-level continuous DiD:\n")
summary(fit4_cont)

## ── 5. Mechanism: Depletion Rate (change in depth) ──────────────
cat("\n--- Specification 5: Depletion Rate ---\n")

# Compute annual change in depth for each well
wells_annual <- wells_long[, .(
  mean_depth = mean(depth_to_water, na.rm = TRUE)
), by = .(WLCODE, STATE, DISTRICT, year, oe_share, treated, post,
          treat_post, first_high_round, rel_year)]

setorder(wells_annual, WLCODE, year)
wells_annual[, delta_depth := mean_depth - shift(mean_depth, 1),
             by = WLCODE]
wells_annual[, lag_depth := shift(mean_depth, 1), by = WLCODE]

# Positive delta = depletion (water table falling)
fit5 <- feols(
  delta_depth ~ treat_post | WLCODE + year,
  data = wells_annual[!is.na(delta_depth)],
  cluster = ~STATE
)
cat("Depletion rate (Δ depth) DiD:\n")
summary(fit5)

## ── 6. Heterogeneity: State-level ──────────────────────────────
cat("\n--- Specification 6: State heterogeneity ---\n")

# Interact treatment with high-extraction states
# Key states: Punjab (PB), Rajasthan (RJ), Haryana (HR), Tamil Nadu (TN)
wells_long[, key_state := STATE %in% c("PB", "RJ", "HR", "TN")]

fit6 <- feols(
  depth_to_water ~ treat_post + treat_post:key_state | WLCODE + year,
  data = wells_long,
  cluster = ~STATE
)
cat("Heterogeneity by key state:\n")
summary(fit6)

## ── 7. Pre-trend test ───────────────────────────────────────────
cat("\n--- Pre-trend analysis ---\n")

# Test for differential pre-trends using pre-2004 data only
pre_data <- wells_annual[year < 2004 & !is.na(delta_depth)]
pre_data[, year_trend := year - 1996]
pre_data[, future_treated := STATE %in% state_treatment$state_code]

fit_pretrend <- feols(
  delta_depth ~ future_treated:year_trend | WLCODE + year,
  data = pre_data,
  cluster = ~STATE
)
cat("Pre-trend test (differential slope, pre-2004):\n")
summary(fit_pretrend)

## ── 8. Save all results ────────────────────────────────────────
results <- list(
  twfe_cont = fit1_cont,
  twfe_bin = fit1_bin,
  event_study = fit2_sa,
  well_level = fit4,
  well_cont = fit4_cont,
  depletion_rate = fit5,
  heterogeneity = fit6,
  pretrend = fit_pretrend
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

## ── 9. Write diagnostics.json ───────────────────────────────────
diagnostics <- list(
  n_treated = uniqueN(district_panel[treated == TRUE, district_id]),
  n_pre = length(unique(district_panel[year < 2004, year])),
  n_obs = nrow(district_panel),
  n_wells = uniqueN(wells_long$WLCODE),
  n_well_obs = nrow(wells_long),
  n_states = uniqueN(wells_long$STATE),
  n_districts = uniqueN(district_panel$district_id),
  treatment_states = paste(state_treatment$state_code, collapse = ", "),
  year_range = paste(range(district_panel$year), collapse = "-"),
  mean_depth_treated = round(mean(wells_long[treated == TRUE, depth_to_water], na.rm = TRUE), 2),
  mean_depth_control = round(mean(wells_long[treated == FALSE, depth_to_water], na.rm = TRUE), 2)
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Results saved to:", file.path(data_dir, "main_results.rds"), "\n")
cat("Diagnostics saved to:", file.path(data_dir, "diagnostics.json"), "\n")
