# 03_main_analysis.R — Main DiD analysis for apep_0770
# Effect of maternity ward closures on FN/RN vote share

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel.rds"))

cat("Panel dimensions:", nrow(panel), "x", ncol(panel), "\n")

# =============================================================================
# 0. Data preparation
# =============================================================================

# Drop overseas territories (DOM-TOM: dep_code starting with 97)
panel <- panel[!grepl("^97", dep_code)]
cat("After dropping DOM-TOM:", nrow(panel), "rows,", uniqueN(panel$commune_code), "communes\n")

# Create départment-level clustering variable
panel[, dep := dep_code]

# Log population (with floor for tiny communes)
panel[, log_pop := log(pmax(pop, 1))]

# Recode election year as period for CS-DiD
panel[, period := as.integer(factor(election_year))]

# =============================================================================
# 1. Summary statistics
# =============================================================================
cat("\n=== Summary Statistics ===\n")

summ <- panel[, .(
  N = .N,
  n_communes = uniqueN(commune_code),
  n_elections = uniqueN(election_year),
  mean_fn_rn = round(mean(fn_rn_share, na.rm = TRUE), 2),
  sd_fn_rn = round(sd(fn_rn_share, na.rm = TRUE), 2),
  mean_dist_km = round(mean(dist_nearest_mat_km, na.rm = TRUE), 2),
  sd_dist_km = round(sd(dist_nearest_mat_km, na.rm = TRUE), 2),
  mean_pop = round(mean(pop, na.rm = TRUE), 0),
  pct_affected = round(mean(ever_affected) * 100, 1)
)]
print(summ)

# Summary by election year
cat("\nBy election year:\n")
print(panel[, .(
  mean_fn_rn = round(mean(fn_rn_share, na.rm = TRUE), 2),
  mean_dist = round(mean(dist_nearest_mat_km, na.rm = TRUE), 2),
  n = .N
), by = election_year][order(election_year)])


# =============================================================================
# 2. Main specification: TWFE DiD
# =============================================================================
cat("\n=== Main TWFE Specifications ===\n")

# Specification 1: Basic TWFE with commune + year FE
# Treatment = continuous distance to nearest maternity (km)
m1 <- feols(fn_rn_share ~ dist_nearest_mat_km |
              commune_code + election_year,
            data = panel,
            cluster = ~dep)

cat("\nModel 1 — Distance to nearest maternity (continuous, km):\n")
summary(m1)

# Specification 2: Binary treatment (ever_affected × post)
# Create post indicator (treatment cohort-specific)
panel[, post := fifelse(!is.na(first_treatment_year) &
                         election_year >= first_treatment_year, 1L, 0L)]

m2 <- feols(fn_rn_share ~ post |
              commune_code + election_year,
            data = panel,
            cluster = ~dep)

cat("\nModel 2 — Binary post-closure indicator:\n")
summary(m2)

# Specification 3: Add controls
m3 <- feols(fn_rn_share ~ dist_nearest_mat_km + log_pop |
              commune_code + election_year,
            data = panel,
            cluster = ~dep)

cat("\nModel 3 — Distance + controls:\n")
summary(m3)


# =============================================================================
# 3. Callaway-Sant'Anna estimator
# =============================================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Prepare data for did package
# Need: yname, tname, idname, gname
# gname = first treatment period (0 for never treated)
cs_data <- copy(panel)
cs_data[, id := as.integer(factor(commune_code))]
cs_data[is.na(first_treatment_year), first_treatment_year := 0L]

# CS-DiD requires numeric time periods that correspond to actual values
# Use election_year directly
cs_out <- tryCatch({
  att_gt(
    yname = "fn_rn_share",
    tname = "election_year",
    idname = "id",
    gname = "first_treatment_year",
    data = as.data.frame(cs_data),
    control_group = "notyettreated",
    clustervars = "dep",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("\nCS-DiD group-time ATTs:\n")
  print(summary(cs_out))

  # Aggregate to overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nOverall ATT:\n")
  print(summary(cs_agg))

  # Dynamic aggregation (event study)
  cs_dynamic <- aggte(cs_out, type = "dynamic")
  cat("\nDynamic ATT (event study):\n")
  print(summary(cs_dynamic))

  saveRDS(cs_out, file.path(data_dir, "cs_did_result.rds"))
  saveRDS(cs_dynamic, file.path(data_dir, "cs_dynamic.rds"))
}


# =============================================================================
# 4. Event study (TWFE version)
# =============================================================================
cat("\n=== Event Study (TWFE) ===\n")

# Create event time relative to first treatment
panel[, event_time := fifelse(!is.na(first_treatment_year) & first_treatment_year > 0,
                               election_year - first_treatment_year,
                               NA_integer_)]

# For treated communes only, include in event study
es_data <- panel[!is.na(event_time) | first_treatment_year == 0 | is.na(first_treatment_year)]

# Event time dummies (for fixest sunab or i() syntax)
m_es <- feols(fn_rn_share ~ i(event_time, ref = -5) |
                commune_code + election_year,
              data = panel[ever_affected == TRUE | is.na(first_treatment_year)],
              cluster = ~dep)

cat("Event study coefficients:\n")
summary(m_es)

saveRDS(m_es, file.path(data_dir, "event_study.rds"))


# =============================================================================
# 5. Save diagnostics
# =============================================================================
n_treated <- uniqueN(panel[ever_affected == TRUE, commune_code])
n_pre <- sum(unique(panel$election_year) < 2017)  # Pre-treatment elections
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_communes = uniqueN(panel$commune_code),
  n_elections = uniqueN(panel$election_year),
  mean_fn_rn = mean(panel$fn_rn_share, na.rm = TRUE),
  sd_fn_rn = sd(panel$fn_rn_share, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                      auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")
cat(sprintf("n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

# Save main results for table generation
saveRDS(list(m1 = m1, m2 = m2, m3 = m3), file.path(data_dir, "main_models.rds"))
cat("Main models saved.\n")
