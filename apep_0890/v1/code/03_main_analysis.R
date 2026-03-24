# 03_main_analysis.R — Primary regressions
# apep_0890: Craigslist Entry and Local Journalism Employment

source("00_packages.R")
setwd(file.path(getwd(), "..", "data"))

panel <- readRDS("panel_clean.rds")
params <- readRDS("params.rds")

# =============================================================================
# 1. TWFE baseline (for comparison — known to be biased under heterogeneity)
# =============================================================================
cat("=== TWFE Baseline ===\n")
twfe <- feols(
  ln_emp ~ post | fips + time_period,
  data = panel,
  cluster = ~state_fips
)
cat("TWFE coefficient:", coef(twfe)["post"], "\n")
cat("TWFE SE:", se(twfe)["post"], "\n")
summary(twfe)

# =============================================================================
# 2. Callaway-Sant'Anna (CS-DiD) — Primary specification
# =============================================================================
cat("\n=== Callaway-Sant'Anna ATT ===\n")

# CS-DiD requires: idname, tname, gname (first treatment period), yname
# Use year-level aggregation for CS-DiD (quarterly is very slow with many groups)
# Aggregate to annual for CS-DiD
panel_annual <- panel %>%
  group_by(fips, year, state_fips, g, treated_ever) %>%
  summarise(
    emp = mean(emp, na.rm = TRUE),
    ln_emp = mean(ln_emp, na.rm = TRUE),
    hir_n = mean(hir_n, na.rm = TRUE),
    sep = mean(sep, na.rm = TRUE),
    earn_s = mean(earn_s, na.rm = TRUE),
    .groups = "drop"
  )

# Run CS-DiD with not-yet-treated as control
cs_out <- att_gt(
  yname = "ln_emp",
  tname = "year",
  idname = "fips",
  gname = "g",
  data = panel_annual,
  control_group = "notyettreated",
  clustervars = "state_fips",
  base_period = "universal"
)

cat("\nCS-DiD group-time ATTs computed.\n")
cat("Number of group-time ATTs:", length(cs_out$att), "\n")

# Overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nOverall ATT:\n")
summary(cs_agg)

# Dynamic (event-study) aggregation
cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -6, max_e = 10)
cat("\nEvent-study ATTs:\n")
summary(cs_dynamic)

# =============================================================================
# 3. Decomposition: Hires vs Separations
# =============================================================================
cat("\n=== Decomposition: New Hires ===\n")
cs_hires <- att_gt(
  yname = "hir_n",
  tname = "year",
  idname = "fips",
  gname = "g",
  data = panel_annual %>% mutate(hir_n = log(hir_n + 1)),
  control_group = "notyettreated",
  clustervars = "state_fips",
  base_period = "universal"
)
cs_hires_agg <- aggte(cs_hires, type = "simple")
cat("Hires ATT:\n")
summary(cs_hires_agg)

cs_hires_dyn <- aggte(cs_hires, type = "dynamic", min_e = -6, max_e = 10)

cat("\n=== Decomposition: Separations ===\n")
cs_sep <- att_gt(
  yname = "sep",
  tname = "year",
  idname = "fips",
  gname = "g",
  data = panel_annual %>% mutate(sep = log(sep + 1)),
  control_group = "notyettreated",
  clustervars = "state_fips",
  base_period = "universal"
)
cs_sep_agg <- aggte(cs_sep, type = "simple")
cat("Separations ATT:\n")
summary(cs_sep_agg)

cs_sep_dyn <- aggte(cs_sep, type = "dynamic", min_e = -6, max_e = 10)

# =============================================================================
# 4. Earnings effect
# =============================================================================
cat("\n=== Earnings Effect ===\n")
cs_earn <- att_gt(
  yname = "earn_s",
  tname = "year",
  idname = "fips",
  gname = "g",
  data = panel_annual %>% mutate(earn_s = log(earn_s + 1)),
  control_group = "notyettreated",
  clustervars = "state_fips",
  base_period = "universal"
)
cs_earn_agg <- aggte(cs_earn, type = "simple")
cat("Earnings ATT:\n")
summary(cs_earn_agg)

# =============================================================================
# 5. Save results
# =============================================================================
results <- list(
  twfe = twfe,
  cs_out = cs_out,
  cs_agg = cs_agg,
  cs_dynamic = cs_dynamic,
  cs_hires_agg = cs_hires_agg,
  cs_hires_dyn = cs_hires_dyn,
  cs_sep_agg = cs_sep_agg,
  cs_sep_dyn = cs_sep_dyn,
  cs_earn_agg = cs_earn_agg
)
saveRDS(results, "results_main.rds")

# Write diagnostics.json for validator
diagnostics <- list(
  n_treated = params$n_treated,
  n_pre = length(unique(panel_annual$year[panel_annual$year < 2000])) +
          length(unique(panel_annual$year[panel_annual$year < 2001])),
  n_obs = nrow(panel_annual)
)
# More precise: count pre-periods for earliest cohort
earliest_cohort <- min(panel_annual$g[panel_annual$g > 0])
diagnostics$n_pre <- length(unique(panel_annual$year[panel_annual$year < earliest_cohort]))
diagnostics$n_treated <- n_distinct(panel_annual$fips[panel_annual$g > 0])

jsonlite::write_json(diagnostics, "diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", jsonlite::toJSON(diagnostics, auto_unbox = TRUE), "\n")
cat("Results saved to data/results_main.rds\n")
