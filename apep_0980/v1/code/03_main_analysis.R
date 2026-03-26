# =============================================================================
# 03_main_analysis.R — Staggered DiD: Energy community bonus and employment
# apep_0980: IRA Energy Community Bonus Credit and County-Level Labor Markets
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

# =============================================================================
# Load analysis panel
# =============================================================================
cat("=== Loading analysis panel ===\n")
panel <- arrow::read_parquet(file.path(DATA_DIR, "analysis_panel.parquet"))
setDT(panel)

# Create numeric time index for event study
panel[, time_idx := (year - 2018) * 4 + quarter]  # 1 = 2018Q1, ...

# Treatment onset time index: Q2 2023 = (2023-2018)*4 + 2 = 22
treat_time_2023 <- (2023 - 2018) * 4 + 2
treat_time_2024 <- (2024 - 2018) * 4 + 2

# Relative time for event study
panel[first_treat_qtr == 20232, rel_time := time_idx - treat_time_2023]
panel[first_treat_qtr == 20242, rel_time := time_idx - treat_time_2024]
panel[first_treat_qtr == 0, rel_time := NA_integer_]  # never treated

cat(sprintf("  Panel: %s rows\n", format(nrow(panel), big.mark = ",")))

# =============================================================================
# Sample restriction: focus on counties with treatment data
# =============================================================================
# Main sample: FF-eligible counties with unemployment data + non-FF counties
# Exclude "no_unemp_data" to avoid contaminating controls with potentially treated counties
main_sample <- panel[cohort != "no_unemp_data"]
cat(sprintf("  Main sample: %s rows, %d counties\n",
            format(nrow(main_sample), big.mark = ","),
            uniqueN(main_sample$county_fips)))

# =============================================================================
# SPECIFICATION 1: TWFE DiD — Construction Employment
# =============================================================================
cat("\n=== TWFE DiD Results ===\n")

# Main sectors for analysis
sectors <- c("23", "22", "21", "31-33", "44-45", "72")
sector_names <- c("Construction", "Utilities", "Mining",
                  "Manufacturing", "Retail", "Accommodation")

twfe_results <- list()
for (i in seq_along(sectors)) {
  s <- sectors[i]
  sname <- sector_names[i]
  dt <- main_sample[industry == s & !is.na(Emp)]

  if (nrow(dt) < 100) {
    cat(sprintf("  %s: insufficient data (%d rows)\n", sname, nrow(dt)))
    next
  }

  # TWFE with county and quarter FE
  mod <- feols(log_emp ~ treated | county_fips + time,
               data = dt, cluster = ~state_fips)

  twfe_results[[s]] <- mod
  cat(sprintf("  %s: beta = %0.4f (SE = %0.4f), N = %d\n",
              sname, coef(mod)["treated"], se(mod)["treated"],
              mod$nobs))
}

# =============================================================================
# SPECIFICATION 2: Event Study — Construction (main outcome)
# =============================================================================
cat("\n=== Event Study: Construction ===\n")

# Construction event study with 2023 treatment cohort
constr_dt <- main_sample[industry == "23" & !is.na(Emp) &
                          (first_treat_qtr == 20232 | first_treat_qtr == 0)]

# Create event-time dummies (bin at -8 and +7)
constr_dt[first_treat_qtr > 0, event_time := time_idx - treat_time_2023]
constr_dt[first_treat_qtr == 0, event_time := NA_integer_]

# For sunab: need cohort indicator (first treatment period)
constr_dt[, g := fifelse(first_treat_qtr > 0, treat_time_2023, 10000L)]

# Sun-Abraham (2021) event study via fixest::sunab()
es_model <- feols(log_emp ~ sunab(g, time_idx, ref.p = -1) | county_fips + time_idx,
                  data = constr_dt, cluster = ~state_fips)

cat("  Event study coefficients (construction, 2023 cohort):\n")
es_coefs <- coeftable(es_model)
print(round(es_coefs[1:min(20, nrow(es_coefs)), ], 4))

# =============================================================================
# SPECIFICATION 3: Callaway-Sant'Anna (if multiple cohorts)
# =============================================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# CS estimator for construction
cs_dt <- main_sample[industry == "23" & !is.na(Emp)]

# CS needs: id, time, group (0 for never-treated, first treat period otherwise)
# Collapse treated_2023_only into 2023 cohort (conservative)
cs_dt[, cs_group := fifelse(first_treat_qtr > 0, first_treat_qtr, 0L)]

# Ensure balanced panel (CS requires it)
county_obs <- cs_dt[, .N, by = county_fips]
balanced_counties <- county_obs[N == max(N)]$county_fips
cs_balanced <- cs_dt[county_fips %in% balanced_counties]

cat(sprintf("  Balanced panel: %d counties, %d periods\n",
            uniqueN(cs_balanced$county_fips), uniqueN(cs_balanced$time_idx)))

if (uniqueN(cs_balanced[cs_group > 0]$county_fips) >= 20) {
  cs_result <- tryCatch({
    att_gt(
      yname = "log_emp",
      tname = "time_idx",
      idname = "county_fips",
      gname = "cs_group",
      data = as.data.frame(cs_balanced),
      control_group = "notyettreated",
      est_method = "reg",
      clustervars = "state_fips",
      base_period = "universal"
    )
  }, error = function(e) {
    cat("  CS estimation error:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_result)) {
    cs_agg <- aggte(cs_result, type = "simple")
    cat(sprintf("  CS ATT (simple): %0.4f (SE = %0.4f)\n",
                cs_agg$overall.att, cs_agg$overall.se))

    # Dynamic aggregation for event study
    cs_dyn <- aggte(cs_result, type = "dynamic")
    cat("  CS dynamic effects:\n")
    for (j in seq_along(cs_dyn$egt)) {
      cat(sprintf("    e=%2d: ATT=%7.4f (SE=%6.4f)\n",
                  cs_dyn$egt[j], cs_dyn$att.egt[j], cs_dyn$se.egt[j]))
    }
  }
} else {
  cat("  Fewer than 20 treated counties in balanced panel — skipping CS\n")
  cs_result <- NULL
}

# =============================================================================
# SPECIFICATION 4: Sector-by-sector TWFE (main results table)
# =============================================================================
cat("\n=== Main Results Table Data ===\n")

# Additional outcome: earnings
twfe_earn <- list()
for (i in seq_along(sectors)) {
  s <- sectors[i]
  sname <- sector_names[i]
  dt <- main_sample[industry == s & !is.na(EarnS) & EarnS > 0]

  if (nrow(dt) < 100) next

  mod <- feols(log_earn ~ treated | county_fips + time,
               data = dt, cluster = ~state_fips)
  twfe_earn[[s]] <- mod
  cat(sprintf("  Earnings %s: beta = %0.4f (SE = %0.4f)\n",
              sname, coef(mod)["treated"], se(mod)["treated"]))
}

# Hires
twfe_hires <- list()
for (i in 1:3) {  # Only Construction, Utilities, Mining
  s <- sectors[i]
  sname <- sector_names[i]
  dt <- main_sample[industry == s & !is.na(HirA)]

  if (nrow(dt) < 100) next

  mod <- feols(log_hires ~ treated | county_fips + time,
               data = dt, cluster = ~state_fips)
  twfe_hires[[s]] <- mod
}

# =============================================================================
# Save key results for diagnostics
# =============================================================================
n_treated <- uniqueN(main_sample[treated == 1]$county_fips)
n_pre <- length(unique(main_sample[time < 20232]$time))
n_obs <- nrow(main_sample[industry == "23"])

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = uniqueN(main_sample$county_fips),
  n_never_treated = uniqueN(main_sample[cohort == "never_treated"]$county_fips),
  n_never_treated_ff = uniqueN(main_sample[cohort == "never_treated_ff"]$county_fips),
  twfe_construction_beta = unname(coef(twfe_results[["23"]])["treated"]),
  twfe_construction_se = unname(se(twfe_results[["23"]])["treated"]),
  twfe_mining_beta = unname(coef(twfe_results[["21"]])["treated"]),
  twfe_mining_se = unname(se(twfe_results[["21"]])["treated"])
)

jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"),
                      auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Diagnostics ===\n")
cat(sprintf("  N treated counties: %d\n", n_treated))
cat(sprintf("  N pre-periods: %d\n", n_pre))
cat(sprintf("  N obs (construction): %d\n", n_obs))

# Save results objects
save(twfe_results, twfe_earn, twfe_hires, es_model, cs_result,
     file = file.path(DATA_DIR, "main_results.RData"))
cat("\nMain analysis complete. Results saved.\n")
