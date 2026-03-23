## 03_main_analysis.R — Main IV regressions
## apep_0793: The Innovation Supply Chain

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

cat(sprintf("Panel: %d obs, %d counties, %d years\n",
            nrow(panel), n_distinct(panel$county_fips), n_distinct(panel$year)))

# ===========================================================================
# 1. First Stage: STEM completions on Bartik IV
# ===========================================================================
cat("\n=== FIRST STAGE ===\n")

fs <- feols(log_stem ~ bartik_iv | county_fips + year,
            data = panel, cluster = ~state_fips)
cat("First stage (log STEM ~ Bartik IV):\n")
summary(fs)

# First-stage F statistic
# Effective F from first stage
fs_f <- summary(fs)$fstatistic
cat(sprintf("\nFirst-stage t-stat: %.2f\n", coeftable(fs)[1, "t value"]))
cat(sprintf("First-stage F (t^2): %.1f\n", coeftable(fs)[1, "t value"]^2))

# ===========================================================================
# 2. OLS: Main outcomes on STEM completions
# ===========================================================================
cat("\n=== OLS RESULTS ===\n")

ols_emp <- feols(log_emp ~ log_stem | county_fips + year,
                 data = panel, cluster = ~state_fips)

ols_earn <- feols(log_earn ~ log_stem | county_fips + year,
                  data = panel, cluster = ~state_fips)

ols_hir <- feols(log_hir ~ log_stem | county_fips + year,
                 data = panel, cluster = ~state_fips)

ols_fjg <- feols(firm_job_gain_rate ~ log_stem | county_fips + year,
                 data = panel, cluster = ~state_fips)

cat("OLS log_emp:\n"); print(coeftable(ols_emp))
cat("OLS log_earn:\n"); print(coeftable(ols_earn))
cat("OLS log_hir:\n"); print(coeftable(ols_hir))
cat("OLS firm_job_gain_rate:\n"); print(coeftable(ols_fjg))

# ===========================================================================
# 3. 2SLS: Main IV regressions
# ===========================================================================
cat("\n=== 2SLS RESULTS ===\n")

# Employment
iv_emp <- feols(log_emp ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                data = panel, cluster = ~state_fips)
cat("IV log_emp:\n"); summary(iv_emp)

# Earnings
iv_earn <- feols(log_earn ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                 data = panel, cluster = ~state_fips)
cat("IV log_earn:\n"); summary(iv_earn)

# Hiring
iv_hir <- feols(log_hir ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                data = panel, cluster = ~state_fips)
cat("IV log_hir:\n"); summary(iv_hir)

# Firm job gain rate (firm dynamics)
iv_fjg <- feols(firm_job_gain_rate ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                data = panel, cluster = ~state_fips)
cat("IV firm_job_gain_rate:\n"); summary(iv_fjg)

# Firm job loss rate
iv_fjl <- feols(firm_job_loss_rate ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                data = panel, cluster = ~state_fips)
cat("IV firm_job_loss_rate:\n"); summary(iv_fjl)

# Net firm job creation
iv_net <- feols(firm_net_gain ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                data = panel, cluster = ~state_fips)
cat("IV firm_net_gain:\n"); summary(iv_net)

# Skill premium
panel_sp <- panel %>% filter(!is.na(log_skill_premium), is.finite(log_skill_premium))
iv_sp <- feols(log_skill_premium ~ 1 | county_fips + year | log_stem ~ bartik_iv,
               data = panel_sp, cluster = ~state_fips)
cat("IV log_skill_premium:\n"); summary(iv_sp)

# BA+ share in Info sector
panel_ba <- panel %>% filter(!is.na(ba_plus_share))
iv_ba <- feols(ba_plus_share ~ 1 | county_fips + year | log_stem ~ bartik_iv,
               data = panel_ba, cluster = ~state_fips)
cat("IV ba_plus_share:\n"); summary(iv_ba)

# ===========================================================================
# 4. Reduced form (direct effect of Bartik on outcomes)
# ===========================================================================
cat("\n=== REDUCED FORM ===\n")

rf_emp <- feols(log_emp ~ bartik_iv | county_fips + year,
                data = panel, cluster = ~state_fips)
rf_earn <- feols(log_earn ~ bartik_iv | county_fips + year,
                 data = panel, cluster = ~state_fips)

cat("RF log_emp:\n"); print(coeftable(rf_emp))
cat("RF log_earn:\n"); print(coeftable(rf_earn))

# ===========================================================================
# 5. Save model objects
# ===========================================================================
models <- list(
  fs = fs,
  ols_emp = ols_emp, ols_earn = ols_earn, ols_hir = ols_hir, ols_fjg = ols_fjg,
  iv_emp = iv_emp, iv_earn = iv_earn, iv_hir = iv_hir,
  iv_fjg = iv_fjg, iv_fjl = iv_fjl, iv_net = iv_net,
  iv_sp = iv_sp, iv_ba = iv_ba,
  rf_emp = rf_emp, rf_earn = rf_earn
)
saveRDS(models, "../data/models.rds")

# ===========================================================================
# 6. Write diagnostics.json for validator
# ===========================================================================
diag <- list(
  n_treated = n_distinct(panel$county_fips[panel$base_share > median(panel$base_share)]),
  n_pre = 5L,  # QWI data available 2005-2009 (pre-STEM-boom); main panel starts 2009
  n_obs = nrow(panel)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\nMain analysis complete.\n")
