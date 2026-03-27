## 03_main_analysis.R — Main regression analysis
## Continuous treatment intensity DiD: urbanization × post-Pix

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat(sprintf("Panel: %d obs, %d municipalities, %d years\n",
            nrow(panel), uniqueN(panel$muni_code), uniqueN(panel$year)))

# ============================================================================
# 1. Main specification: Continuous DiD
# ============================================================================
cat("\n=== MAIN SPECIFICATION ===\n")

# Y_mt = alpha_m + gamma_t + beta * (urban_share_m × post_t) + epsilon_mt
# Outcome: enterprises per 10,000 population
# Treatment intensity: 2010 Census urbanization rate
# Post: 2021 (first full year after Pix launch in Nov 2020)
# FE: municipality + year
# Cluster: state level (27 clusters)

main_spec <- feols(
  enterprises_pc ~ treat_x_post | muni_code + year,
  data = panel, cluster = ~state_code
)

cat("Main result (enterprises per 10K pop):\n")
summary(main_spec)

# Units and employment
units_spec <- feols(
  units_pc ~ treat_x_post | muni_code + year,
  data = panel, cluster = ~state_code
)

emp_spec <- feols(
  emp_pc ~ treat_x_post | muni_code + year,
  data = panel, cluster = ~state_code
)

# Log specifications
log_spec <- feols(
  log_enterprises ~ treat_x_post | muni_code + year,
  data = panel, cluster = ~state_code
)

cat("\n--- All main results ---\n")
etable(main_spec, units_spec, emp_spec, log_spec,
       headers = c("Enterprises/10K", "Units/10K", "Employment/10K", "Log(Enterprises)"))

# ============================================================================
# 2. Event study — by year × urbanization
# ============================================================================
cat("\n=== EVENT STUDY ===\n")

# Create year dummies interacted with urbanization
# Base year: 2020 (transition year — Pix launched Nov 2020)
panel[, year_f := factor(year, levels = c(2020, 2015, 2016, 2017, 2018, 2019, 2021))]

es_spec <- feols(
  enterprises_pc ~ i(year_f, urban_share, ref = 2020) | muni_code + year,
  data = panel, cluster = ~state_code
)

cat("Event study coefficients:\n")
summary(es_spec)

# ============================================================================
# 3. State × year fixed effects (absorb differential state trends)
# ============================================================================
cat("\n=== STATE × YEAR FE ===\n")

state_yr_spec <- feols(
  enterprises_pc ~ treat_x_post | muni_code + state_code^year,
  data = panel, cluster = ~state_code
)

cat("With state × year FE:\n")
summary(state_yr_spec)

# ============================================================================
# 4. Wild cluster bootstrap (27 clusters)
# ============================================================================
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Use fwildclusterboot for proper inference with 27 clusters
wcb_result <- tryCatch({
  boottest(
    main_spec,
    param = "treat_x_post",
    clustid = ~state_code,
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat(sprintf("WCB error: %s\n", e$message))
  NULL
})

if (!is.null(wcb_result)) {
  cat("Wild cluster bootstrap results:\n")
  print(summary(wcb_result))
}

# ============================================================================
# 5. Heterogeneity: by region and municipality size
# ============================================================================
cat("\n=== HETEROGENEITY ===\n")

# By region
panel[, region_f := factor(region)]
hetero_region <- feols(
  enterprises_pc ~ treat_x_post:region_f | muni_code + year,
  data = panel, cluster = ~state_code
)
cat("By region:\n")
summary(hetero_region)

# By municipality size
hetero_size <- feols(
  enterprises_pc ~ treat_x_post:size_cat | muni_code + year,
  data = panel, cluster = ~state_code
)
cat("By municipality size:\n")
summary(hetero_size)

# By pre-existing enterprise density (above/below median)
panel[, high_enterprise := as.integer(
  enterprises_pc > median(panel[year == 2019]$enterprises_pc, na.rm = TRUE)
)]
hetero_density <- feols(
  enterprises_pc ~ treat_x_post:factor(high_enterprise) | muni_code + year,
  data = panel, cluster = ~state_code
)
cat("By pre-existing enterprise density:\n")
summary(hetero_density)

# ============================================================================
# 6. Save results for table generation
# ============================================================================
cat("\n=== Saving results ===\n")

# Compute pre-treatment SD for SDE calculation
pre_sd <- sd(panel[year < 2021]$enterprises_pc, na.rm = TRUE)
pre_sd_units <- sd(panel[year < 2021]$units_pc, na.rm = TRUE)
pre_sd_emp <- sd(panel[year < 2021]$emp_pc, na.rm = TRUE)
pre_sd_log <- sd(panel[year < 2021]$log_enterprises, na.rm = TRUE)

cat(sprintf("Pre-treatment SD(enterprises_pc) = %.2f\n", pre_sd))
cat(sprintf("Pre-treatment SD(units_pc) = %.2f\n", pre_sd_units))
cat(sprintf("Pre-treatment SD(emp_pc) = %.2f\n", pre_sd_emp))

results <- list(
  main = main_spec,
  units = units_spec,
  emp = emp_spec,
  log = log_spec,
  event_study = es_spec,
  state_yr = state_yr_spec,
  wcb = wcb_result,
  hetero_region = hetero_region,
  hetero_size = hetero_size,
  hetero_density = hetero_density,
  pre_sd = pre_sd,
  pre_sd_units = pre_sd_units,
  pre_sd_emp = pre_sd_emp,
  pre_sd_log = pre_sd_log
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validation
n_treated <- uniqueN(panel[post == 1]$muni_code)
n_pre <- length(unique(panel[post == 0]$year))
n_obs <- nrow(panel)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_municipalities = uniqueN(panel$muni_code),
  n_states = uniqueN(panel$state_code),
  years = sort(unique(panel$year)),
  pre_sd_enterprises_pc = pre_sd
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nResults and diagnostics saved.\n")
