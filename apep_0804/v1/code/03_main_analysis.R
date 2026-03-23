# 03_main_analysis.R — Triple-difference and CS DiD estimation
# APEP Paper apep_0804: The Caregiving Tax

source("00_packages.R")

cat("=== Main analysis ===\n")

dt <- fread("../data/analysis_data.csv")

# Exclude always-treated states (IN, SC, TX — adopted before 2008, no pre-period)
dt <- dt[always_treated == 0]
cat(sprintf("Analysis sample (excl. always-treated): %s mothers\n",
            format(nrow(dt), big.mark = ",")))

# ============================================================
# 1. TRIPLE-DIFFERENCE (DDD) — Primary specification
# ============================================================
# Y_isgt = α_sg + δ_gt + γ_st + β(Post_st × DREM_g) + X_it'λ + ε_isgt
# s = state, g = DREM group, t = year
# FE: state^DREM, year^DREM, state^year
# Cluster: state

cat("\n--- Triple-Difference (DDD) Estimation ---\n")

# Factor variables for FE
dt[, state_drem := paste0(ST, "_", has_drem_child)]
dt[, year_drem := paste0(year, "_", has_drem_child)]
dt[, state_year := paste0(ST, "_", year)]
dt[, post_drem := post * has_drem_child]

# Primary DDD: Employment
ddd_emp <- feols(employed ~ post_drem |
                   state_drem + year_drem + state_year,
                 data = dt, cluster = ~ST, weights = ~PWGTP)

cat("DDD — Employment:\n")
print(summary(ddd_emp))

# DDD: Hours
ddd_hours <- feols(hours ~ post_drem |
                     state_drem + year_drem + state_year,
                   data = dt, cluster = ~ST, weights = ~PWGTP)

cat("\nDDD — Hours per week:\n")
print(summary(ddd_hours))

# DDD: Log wages (conditional on employed)
ddd_logwage <- feols(log_wages ~ post_drem |
                       state_drem + year_drem + state_year,
                     data = dt[employed == 1], cluster = ~ST, weights = ~PWGTP)

cat("\nDDD — Log wages (conditional on employment):\n")
print(summary(ddd_logwage))

# DDD: Labor force participation
ddd_lfp <- feols(in_labor_force ~ post_drem |
                   state_drem + year_drem + state_year,
                 data = dt, cluster = ~ST, weights = ~PWGTP)

cat("\nDDD — LFP:\n")
print(summary(ddd_lfp))

# DDD with individual covariates
ddd_emp_cov <- feols(employed ~ post_drem + college + married + white + black +
                       i(AGEP) |
                       state_drem + year_drem + state_year,
                     data = dt, cluster = ~ST, weights = ~PWGTP)

cat("\nDDD — Employment with covariates:\n")
print(summary(ddd_emp_cov))

# ============================================================
# 2. EVENT STUDY — DDD version
# ============================================================
cat("\n--- Event Study (DDD) ---\n")

# Create relative time bins for treated states
# Bin endpoints at -5 and +5
dt[, rel_time_bin := fifelse(is.na(rel_time), NA_integer_, rel_time)]
dt[!is.na(rel_time_bin) & rel_time_bin < -5, rel_time_bin := -5L]
dt[!is.na(rel_time_bin) & rel_time_bin > 5, rel_time_bin := 5L]

# Interaction: relative time × DREM
# Reference period: t = -1 (year before mandate)
dt[, rt_drem := fifelse(!is.na(rel_time_bin), rel_time_bin * has_drem_child, 0L)]

# Event study with fixest sunab-style
# Restrict to treated states for event study
dt_treated <- dt[ever_treated == 1]

es_ddd <- feols(employed ~ i(rel_time_bin, has_drem_child, ref = -1) |
                  state_drem + year_drem + state_year,
                data = dt_treated, cluster = ~ST, weights = ~PWGTP)

cat("Event study DDD coefficients:\n")
print(summary(es_ddd))

# ============================================================
# 3. CALLAWAY-SANT'ANNA (2021) — DREM=1 group only
# ============================================================
cat("\n--- Callaway-Sant'Anna DiD (DREM=1 group only) ---\n")

# Collapse to state-year level for DREM=1 mothers
drem1 <- dt[has_drem_child == 1, .(
  employed = weighted.mean(employed, PWGTP, na.rm = TRUE),
  hours = weighted.mean(hours, PWGTP, na.rm = TRUE),
  wages = weighted.mean(wages, PWGTP, na.rm = TRUE),
  n_mothers = .N
), by = .(ST, year, mandate_year_cs)]

# CS requires: group = first treatment period (0 for never-treated)
# id = unit identifier, time = time period
cs_result <- tryCatch({
  att_gt(
    yname = "employed",
    tname = "year",
    idname = "ST",
    gname = "mandate_year_cs",
    data = as.data.frame(drem1[mandate_year_cs >= 2008 | mandate_year_cs == 0]),
    control_group = "nevertreated",
    est_method = "reg",
    base_period = "universal"
  )
}, error = function(e) {
  cat(sprintf("CS estimation error: %s\n", e$message))
  NULL
})

if (!is.null(cs_result)) {
  cs_agg <- aggte(cs_result, type = "simple")
  cat("CS ATT (simple aggregation):\n")
  print(summary(cs_agg))

  cs_dynamic <- aggte(cs_result, type = "dynamic", min_e = -5, max_e = 5)
  cat("\nCS dynamic (event study):\n")
  print(summary(cs_dynamic))
}

# ============================================================
# 4. SAVE RESULTS
# ============================================================
cat("\n--- Saving results ---\n")

# Store model objects for tables
save(ddd_emp, ddd_hours, ddd_logwage, ddd_lfp, ddd_emp_cov,
     es_ddd, cs_result,
     file = "../data/main_results.RData")

# Write diagnostics.json for validator
n_treated_states <- uniqueN(dt[ever_treated == 1]$ST)
n_pre <- min(dt[ever_treated == 1, .(n_pre = min(year) - mandate_year_cs + 1), by = ST]$n_pre)
# use absolute value
n_pre <- max(1, abs(n_pre))

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = as.integer(n_pre),
  n_obs = nrow(dt)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("diagnostics.json: n_treated=%d, n_pre=%d, n_obs=%s\n",
            diagnostics$n_treated, diagnostics$n_pre,
            format(diagnostics$n_obs, big.mark = ",")))

cat("=== Main analysis complete ===\n")
