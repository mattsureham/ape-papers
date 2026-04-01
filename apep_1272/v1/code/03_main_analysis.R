## 03_main_analysis.R — Primary estimation
## apep_1272: Breaking the Gauge Barrier
##
## Designs:
## A. Two-way FE DiD: log_light ~ mg_exposed × post | dist_id + year
## B. Callaway-Sant'Anna staggered DiD with heterogeneous treatment effects
## C. Event study (dynamic effects ±5 years around conversion)

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# ── A. Two-Way Fixed Effects DiD ───────────────────────────────────────

cat("=== TWFE DiD ===\n")

# Specification 1: baseline
m1 <- feols(log_light ~ post | dist_id + year,
            data = panel,
            cluster = ~pc11_state_id)
cat("Spec 1 (baseline TWFE):\n")
print(summary(m1))

# Specification 2: with state-specific trends
m2 <- feols(log_light ~ post | dist_id + pc11_state_id^year,
            data = panel,
            cluster = ~pc11_state_id)
cat("\nSpec 2 (state × year FE):\n")
print(summary(m2))

# Specification 3: mean light (levels, not logs)
m3 <- feols(mean_light ~ post | dist_id + year,
            data = panel,
            cluster = ~pc11_state_id)
cat("\nSpec 3 (mean light, levels):\n")
print(summary(m3))

# ── B. Callaway-Sant'Anna Staggered DiD ───────────────────────────────

cat("\n=== Callaway-Sant'Anna ===\n")

# Prepare data for did package
# Requires: yname, tname, idname, gname (treatment cohort)
cs_data <- copy(panel)
cs_data[, id := as.integer(factor(dist_id))]

# Treatment group: treat_year (0 = never treated)
cat(sprintf("Treatment cohorts:\n"))
print(cs_data[, .(n_districts = uniqueN(id)), by = treat_year][order(treat_year)])

# Only run if we have enough variation
n_cohorts <- uniqueN(cs_data[treat_year > 0]$treat_year)
n_treated <- uniqueN(cs_data[treat_year > 0]$id)

if (n_cohorts >= 2 & n_treated >= 20) {
  cs_out <- att_gt(
    yname = "log_light",
    tname = "year",
    idname = "id",
    gname = "treat_year",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    bstrap = TRUE,
    cband = TRUE,
    biters = 1000
  )

  cat("Callaway-Sant'Anna group-time ATTs:\n")
  print(summary(cs_out))

  # Aggregate to overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nOverall ATT:\n")
  print(summary(cs_agg))

  # Dynamic effects (event study)
  cs_dyn <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 8)
  cat("\nDynamic effects:\n")
  print(summary(cs_dyn))

  saveRDS(cs_out, file.path(data_dir, "cs_results.rds"))
  saveRDS(cs_dyn, file.path(data_dir, "cs_dynamic.rds"))
} else {
  cat(sprintf("Insufficient variation for C-S-A: %d cohorts, %d treated districts\n",
              n_cohorts, n_treated))
  cs_out <- NULL
  cs_dyn <- NULL
}

# ── C. TWFE Event Study ──────────────────────────────────────────────

cat("\n=== TWFE Event Study ===\n")

# Create event-time dummies for treated districts
es_data <- panel[mg_exposed == 1 & !is.na(rel_time)]

# Restrict to ±8 years
es_data <- es_data[abs(rel_time) <= 8]

# Bin endpoints
es_data[, rel_time_binned := pmax(pmin(rel_time, 8), -8)]

# Event study regression
m_es <- feols(log_light ~ i(rel_time_binned, ref = -1) | dist_id + year,
              data = es_data,
              cluster = ~pc11_state_id)
cat("Event study (ref = -1):\n")
print(summary(m_es))

# ── D. Save results for diagnostics ──────────────────────────────────

# Write diagnostics.json for validate_v1.py
n_treated_districts <- uniqueN(panel[mg_exposed == 1]$dist_id)
n_pre <- length(unique(panel[panel$year < min(panel[mg_exposed == 1 & post == 1]$year,
                                               na.rm = TRUE)]$year))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated_districts,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_districts, n_pre, n_obs))

# Save main estimates for table generation
main_results <- list(
  twfe_baseline = m1,
  twfe_state_trends = m2,
  twfe_levels = m3,
  cs_overall = if (!is.null(cs_out)) cs_agg else NULL,
  event_study = m_es
)
saveRDS(main_results, file.path(data_dir, "main_results.rds"))

cat("\nMain analysis complete.\n")
