# 03_main_analysis.R — Primary regressions
# apep_0835: Greece POS Terminal Mandates

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
cat(sprintf("Panel loaded: %d obs, %d sectors, years %d-%d\n",
            nrow(panel), uniqueN(panel$nace1), min(panel$year), max(panel$year)))

# ===================================================================
# 1. TWFE Baseline (national sector-year panel)
# ===================================================================

cat("\n=== TWFE Baseline ===\n")

# Sector and year FEs; cluster at sector level
twfe_est <- feols(log_est ~ treat_post | sector_id + year,
                  data = panel, cluster = ~nace1)
twfe_emp <- feols(log_emp ~ treat_post | sector_id + year,
                  data = panel, cluster = ~nace1)
twfe_wages <- feols(log_wages ~ treat_post | sector_id + year,
                    data = panel, cluster = ~nace1)

cat("Establishments:\n"); print(summary(twfe_est))
cat("\nEmployment:\n"); print(summary(twfe_emp))
cat("\nWages:\n"); print(summary(twfe_wages))

# ===================================================================
# 2. Event Study (Sun-Abraham via fixest::sunab)
# ===================================================================

cat("\n=== Sun-Abraham Event Study ===\n")

panel[, cohort_sa := fifelse(treated == 1, 2017L, 10000L)]

es_est <- feols(log_est ~ sunab(cohort_sa, year) | sector_id + year,
                data = panel, cluster = ~nace1)
es_emp <- feols(log_emp ~ sunab(cohort_sa, year) | sector_id + year,
                data = panel, cluster = ~nace1)
es_wages <- feols(log_wages ~ sunab(cohort_sa, year) | sector_id + year,
                  data = panel, cluster = ~nace1)

cat("Event study — Establishments:\n"); print(summary(es_est))
cat("\nEvent study — Employment:\n"); print(summary(es_emp))
cat("\nEvent study — Wages:\n"); print(summary(es_wages))

# ===================================================================
# 3. Callaway & Sant'Anna (2021) — using regional panel for more units
# ===================================================================

cat("\n=== Callaway-Sant'Anna (Regional Panel, Employment) ===\n")

if (file.exists("../data/regional_panel.csv")) {
  reg_panel <- fread("../data/regional_panel.csv")
  cat(sprintf("Regional panel: %d obs, %d units\n",
              nrow(reg_panel), uniqueN(reg_panel$unit_id)))

  cs_emp_reg <- tryCatch(
    att_gt(yname = "log_emp",
           tname = "year",
           idname = "unit_id",
           gname = "cohort",
           data = as.data.frame(reg_panel),
           control_group = "nevertreated",
           est_method = "reg"),
    error = function(e) {
      cat("CS regional failed:", e$message, "\n")
      NULL
    }
  )

  if (!is.null(cs_emp_reg)) {
    agg_emp_reg <- aggte(cs_emp_reg, type = "simple")
    cat("CS ATT — Employment (regional):\n"); print(summary(agg_emp_reg))

    dyn_emp_reg <- aggte(cs_emp_reg, type = "dynamic")
    cat("\nCS Dynamic — Employment (regional):\n"); print(summary(dyn_emp_reg))
  }
} else {
  cs_emp_reg <- NULL
  cat("No regional panel available.\n")
}

# Also run CS on national panel
cat("\n=== Callaway-Sant'Anna (National Panel) ===\n")

cs_est_nat <- tryCatch(
  att_gt(yname = "log_est",
         tname = "year",
         idname = "unit_id",
         gname = "cohort",
         data = as.data.frame(panel),
         control_group = "nevertreated",
         est_method = "reg"),
  error = function(e) {
    cat("CS national est failed:", e$message, "\n")
    NULL
  }
)

cs_emp_nat <- tryCatch(
  att_gt(yname = "log_emp",
         tname = "year",
         idname = "unit_id",
         gname = "cohort",
         data = as.data.frame(panel),
         control_group = "nevertreated",
         est_method = "reg"),
  error = function(e) {
    cat("CS national emp failed:", e$message, "\n")
    NULL
  }
)

cs_wages_nat <- tryCatch(
  att_gt(yname = "log_wages",
         tname = "year",
         idname = "unit_id",
         gname = "cohort",
         data = as.data.frame(panel),
         control_group = "nevertreated",
         est_method = "reg"),
  error = function(e) {
    cat("CS national wages failed:", e$message, "\n")
    NULL
  }
)

if (!is.null(cs_est_nat)) {
  agg_est_nat <- aggte(cs_est_nat, type = "simple")
  cat("CS ATT — Establishments (national):\n"); print(summary(agg_est_nat))
}
if (!is.null(cs_emp_nat)) {
  agg_emp_nat <- aggte(cs_emp_nat, type = "simple")
  cat("CS ATT — Employment (national):\n"); print(summary(agg_emp_nat))
}
if (!is.null(cs_wages_nat)) {
  agg_wages_nat <- aggte(cs_wages_nat, type = "simple")
  cat("CS ATT — Wages (national):\n"); print(summary(agg_wages_nat))
}

# ===================================================================
# 4. Regional TWFE (employment only, for robustness)
# ===================================================================

cat("\n=== Regional TWFE ===\n")

if (file.exists("../data/regional_panel.csv")) {
  reg_panel <- fread("../data/regional_panel.csv")

  twfe_emp_reg <- feols(log_emp ~ treat_post | sector_id + region_id^year,
                        data = reg_panel, cluster = ~nace1)
  cat("Regional TWFE — Employment:\n"); print(summary(twfe_emp_reg))
}

# ===================================================================
# 5. Pre-treatment summary statistics
# ===================================================================

cat("\n=== Pre-treatment summary (2012-2016) ===\n")

pre <- panel[year < 2017]
pre_stats <- pre[, .(
  mean_est = mean(establishments, na.rm = TRUE),
  sd_est = sd(establishments, na.rm = TRUE),
  mean_emp = mean(employment, na.rm = TRUE),
  sd_emp = sd(employment, na.rm = TRUE),
  mean_wages = mean(wages, na.rm = TRUE),
  sd_wages = sd(wages, na.rm = TRUE),
  n = .N
), by = treated]

cat("Pre-treatment means:\n")
print(pre_stats)

# Pre-treatment SDs of log outcomes (for SDE)
pre_sd <- pre[, .(
  sd_log_est = sd(log_est, na.rm = TRUE),
  sd_log_emp = sd(log_emp, na.rm = TRUE),
  sd_log_wages = sd(log_wages, na.rm = TRUE)
)]
cat("\nPre-treatment SDs of log outcomes:\n")
print(pre_sd)

# ===================================================================
# 6. Save results
# ===================================================================

results <- list(
  twfe = list(est = twfe_est, emp = twfe_emp, wages = twfe_wages),
  es = list(est = es_est, emp = es_emp, wages = es_wages),
  cs_nat = list(est = cs_est_nat, emp = cs_emp_nat, wages = cs_wages_nat),
  cs_agg_nat = list(
    est = if (!is.null(cs_est_nat)) agg_est_nat else NULL,
    emp = if (!is.null(cs_emp_nat)) agg_emp_nat else NULL,
    wages = if (!is.null(cs_wages_nat)) agg_wages_nat else NULL
  ),
  cs_reg = if (exists("cs_emp_reg")) cs_emp_reg else NULL,
  twfe_reg = if (exists("twfe_emp_reg")) twfe_emp_reg else NULL,
  pre_sd = pre_sd,
  pre_stats = pre_stats
)
saveRDS(results, "../data/main_results.rds")

# ===================================================================
# 7. Diagnostics for validate_v1.py
# ===================================================================

n_treated_units <- uniqueN(panel[treated == 1]$nace1)
# For regional panel, count region-sector units
if (file.exists("../data/regional_panel.csv")) {
  reg_panel <- fread("../data/regional_panel.csv")
  n_treated_units <- uniqueN(reg_panel[treated == 1]$unit_id)
}
n_pre <- length(unique(panel[year < 2017]$year))
n_obs <- nrow(panel)
if (file.exists("../data/regional_panel.csv")) {
  n_obs <- nrow(reg_panel)
}

diagnostics <- list(
  n_treated = n_treated_units,
  n_pre = n_pre,
  n_obs = n_obs
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_units, n_pre, n_obs))

cat("\n=== Main analysis complete ===\n")
