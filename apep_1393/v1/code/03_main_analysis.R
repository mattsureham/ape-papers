## 03_main_analysis.R — IV regressions: merger exposure → branch closures → racial gaps
## apep_1393: Merger-Induced Branch Closures and Racial Mortgage Gaps

source("00_packages.R")


data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Analysis panel:", nrow(panel), "county-years\n")

# ============================================================================
# 1. First Stage: Merger Exposure → Branch Closures
# ============================================================================
cat("\n=== First Stage ===\n")

fs <- feols(branch_change_pct ~ merger_exposure | state_fips + year,
            data = panel, cluster = ~county_fips)
fs_fstat <- fitstat(fs, "f")$f$stat
cat("First stage F-stat:", fs_fstat, "\n")
summary(fs)

panel <- panel %>%
  mutate(ln_branches = log(n_branches))

fs2 <- feols(ln_branches ~ merger_exposure | county_fips + year,
             data = panel, cluster = ~county_fips)
summary(fs2)

# ============================================================================
# 2. Reduced Form: Merger Exposure → Racial Denial Gaps (directly)
# ============================================================================
cat("\n=== Reduced Form ===\n")

rf_bw <- feols(bw_denial_gap ~ merger_exposure | state_fips + year,
               data = panel, cluster = ~county_fips)
summary(rf_bw)

rf_aw <- feols(aw_denial_gap ~ merger_exposure | state_fips + year,
               data = panel, cluster = ~county_fips)
summary(rf_aw)

# ============================================================================
# 3. IV: Merger Exposure instruments Branch Closures → Racial Gaps
# ============================================================================
cat("\n=== IV Regressions ===\n")

# BW denial gap
iv_bw_denial <- feols(bw_denial_gap ~ 1 | state_fips + year |
                        branch_change_pct ~ merger_exposure,
                      data = panel, cluster = ~county_fips)
summary(iv_bw_denial)

# AW denial gap
iv_aw_denial <- feols(aw_denial_gap ~ 1 | state_fips + year |
                        branch_change_pct ~ merger_exposure,
                      data = panel, cluster = ~county_fips)
summary(iv_aw_denial)

# BW rate spread gap
iv_bw_rate <- feols(bw_rate_gap ~ 1 | state_fips + year |
                      branch_change_pct ~ merger_exposure,
                    data = panel, cluster = ~county_fips)
summary(iv_bw_rate)

# AW rate spread gap
iv_aw_rate <- feols(aw_rate_gap ~ 1 | state_fips + year |
                      branch_change_pct ~ merger_exposure,
                    data = panel, cluster = ~county_fips)
summary(iv_aw_rate)

# BW interest rate gap
iv_bw_interest <- feols(bw_interest_gap ~ 1 | state_fips + year |
                          branch_change_pct ~ merger_exposure,
                        data = panel, cluster = ~county_fips)
summary(iv_bw_interest)

# Overall denial rate
iv_denial_all <- feols(overall_denial_rate ~ 1 | state_fips + year |
                         branch_change_pct ~ merger_exposure,
                       data = panel, cluster = ~county_fips)
summary(iv_denial_all)

# ============================================================================
# 4. OLS comparisons
# ============================================================================
cat("\n=== OLS Comparisons ===\n")

ols_bw_denial <- feols(bw_denial_gap ~ branch_change_pct | state_fips + year,
                       data = panel, cluster = ~county_fips)

ols_aw_denial <- feols(aw_denial_gap ~ branch_change_pct | state_fips + year,
                       data = panel, cluster = ~county_fips)

ols_bw_rate <- feols(bw_rate_gap ~ branch_change_pct | state_fips + year,
                     data = panel, cluster = ~county_fips)

# ============================================================================
# 5. County FE specification
# ============================================================================
cat("\n=== County FE Specification ===\n")

iv_bw_cfe <- feols(bw_denial_gap ~ 1 | county_fips + year |
                     branch_change_pct ~ merger_exposure,
                   data = panel, cluster = ~county_fips)
summary(iv_bw_cfe)

iv_aw_cfe <- feols(aw_denial_gap ~ 1 | county_fips + year |
                     branch_change_pct ~ merger_exposure,
                   data = panel, cluster = ~county_fips)
summary(iv_aw_cfe)

# ============================================================================
# 6. Save results
# ============================================================================
cat("\n=== Saving results ===\n")

results <- list(
  first_stage = fs,
  rf_bw = rf_bw,
  rf_aw = rf_aw,
  iv_bw_denial = iv_bw_denial,
  iv_aw_denial = iv_aw_denial,
  iv_bw_rate = iv_bw_rate,
  iv_aw_rate = iv_aw_rate,
  iv_bw_interest = iv_bw_interest,
  iv_denial_all = iv_denial_all,
  ols_bw_denial = ols_bw_denial,
  ols_aw_denial = ols_aw_denial,
  ols_bw_rate = ols_bw_rate,
  iv_bw_cfe = iv_bw_cfe,
  iv_aw_cfe = iv_aw_cfe
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validation
diagnostics <- list(
  n_treated = n_distinct(panel$county_fips[panel$merger_exposure > 0]),
  n_pre = length(unique(panel$year[panel$year < 2018])),
  n_obs = nrow(panel),
  first_stage_f = fs_fstat,
  n_counties = n_distinct(panel$county_fips),
  n_years = n_distinct(panel$year)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("Results and diagnostics saved.\n")
cat("First-stage F:", diagnostics$first_stage_f, "\n")
cat("N treated counties:", diagnostics$n_treated, "\n")
cat("N observations:", diagnostics$n_obs, "\n")
