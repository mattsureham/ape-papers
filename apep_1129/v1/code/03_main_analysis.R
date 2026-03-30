# ==============================================================================
# 03_main_analysis.R — OLS, first stage, reduced form, 2SLS
# ==============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
cat(sprintf("Panel loaded: %d county-years, %d counties\n",
            nrow(panel), uniqueN(panel$fips)))

# Ensure factors for FE
panel[, fips := as.character(fips)]
panel[, year := as.integer(year)]
panel[, state_fips := as.character(state_fips)]

# ============================================================================
# Summary Statistics
# ============================================================================
cat("\n=== Summary Statistics ===\n")
for (v in c("pills_per_cap", "hhi", "bartik_hhi", "overdose_rate",
            "population", "median_income", "pct_white", "pct_hs")) {
  x <- panel[[v]]
  if (!is.null(x)) {
    cat(sprintf("  %s: mean=%.3f, sd=%.3f, n=%d\n",
                v, mean(x, na.rm = TRUE), sd(x, na.rm = TRUE), sum(!is.na(x))))
  }
}

# Check correlation between predicted and actual HHI
cat(sprintf("\nCorrelation(predicted HHI, actual HHI): %.4f\n",
            cor(panel$bartik_hhi, panel$hhi, use = "complete.obs")))

# ============================================================================
# OLS — HHI on pills per capita
# ============================================================================
cat("\n=== OLS Regressions ===\n")

ols1 <- feols(pills_per_cap ~ hhi | fips + year, data = panel, vcov = ~state_fips)
ols2 <- feols(pills_per_cap ~ hhi + log_med_income + pct_white + pct_hs |
                fips + year, data = panel, vcov = ~state_fips)
ols3 <- feols(log_pills_per_cap ~ hhi + log_med_income + pct_white + pct_hs |
                fips + year, data = panel, vcov = ~state_fips)

cat("OLS results:\n")
etable(ols1, ols2, ols3)

# ============================================================================
# First Stage — Predicted HHI on Actual HHI
# ============================================================================
cat("\n=== First Stage ===\n")

fs1 <- feols(hhi ~ bartik_hhi | fips + year, data = panel, vcov = ~state_fips)
fs2 <- feols(hhi ~ bartik_hhi + log_med_income + pct_white + pct_hs |
               fips + year, data = panel, vcov = ~state_fips)

cat("First stage:\n")
etable(fs1, fs2)

# Extract first-stage F manually
fs1_wald <- wald(fs1, "bartik_hhi")
fs2_wald <- wald(fs2, "bartik_hhi")
cat(sprintf("First-stage F (no controls): %.1f\n", fs1_wald$stat))
cat(sprintf("First-stage F (with controls): %.1f\n", fs2_wald$stat))

# ============================================================================
# 2SLS — Instrumented HHI on pills per capita
# ============================================================================
cat("\n=== 2SLS Regressions ===\n")

iv1 <- feols(pills_per_cap ~ 1 | fips + year | hhi ~ bartik_hhi,
             data = panel, vcov = ~state_fips)
iv2 <- feols(pills_per_cap ~ log_med_income + pct_white + pct_hs |
               fips + year | hhi ~ bartik_hhi,
             data = panel, vcov = ~state_fips)
iv3 <- feols(log_pills_per_cap ~ log_med_income + pct_white + pct_hs |
               fips + year | hhi ~ bartik_hhi,
             data = panel, vcov = ~state_fips)

cat("2SLS results:\n")
etable(iv1, iv2, iv3)

# First-stage F from IV models
cat(sprintf("IV1 first-stage F: %.1f\n", fitstat(iv1, "ivf1")[[1]]$stat))
cat(sprintf("IV2 first-stage F: %.1f\n", fitstat(iv2, "ivf1")[[1]]$stat))

# ============================================================================
# Reduced Form: Predicted HHI directly on outcomes
# ============================================================================
cat("\n=== Reduced Form ===\n")

rf1 <- feols(pills_per_cap ~ bartik_hhi | fips + year, data = panel, vcov = ~state_fips)
rf2 <- feols(pills_per_cap ~ bartik_hhi + log_med_income + pct_white + pct_hs |
               fips + year, data = panel, vcov = ~state_fips)

cat("Reduced form:\n")
etable(rf1, rf2)

# ============================================================================
# Mortality Analysis
# ============================================================================
mort_panel <- panel[!is.na(overdose_rate)]
cat(sprintf("\n=== Mortality Analysis (%d county-years) ===\n", nrow(mort_panel)))

mort_ols <- feols(overdose_rate ~ hhi | fips + year,
                  data = mort_panel, vcov = ~state_fips)
mort_iv <- feols(overdose_rate ~ 1 | fips + year | hhi ~ bartik_hhi,
                 data = mort_panel, vcov = ~state_fips)
mort_rf <- feols(overdose_rate ~ bartik_hhi | fips + year,
                 data = mort_panel, vcov = ~state_fips)

cat("Mortality results:\n")
etable(mort_ols, mort_iv, mort_rf)

# ============================================================================
# Save model objects and diagnostics
# ============================================================================

sd_y_pre <- sd(panel[year <= 2007]$pills_per_cap, na.rm = TRUE)
sd_hhi <- sd(panel$hhi, na.rm = TRUE)
cat(sprintf("\nPre-treatment SD(pills_per_cap) = %.3f\n", sd_y_pre))
cat(sprintf("SD(HHI) = %.3f\n", sd_hhi))

# Get IV coefficient
iv2_coef <- coef(iv2)["fit_hhi"]
iv2_se <- se(iv2)["fit_hhi"]

# For IV design: "pre" = years before Cardinal-Kinray merger completion (2011)
# This gives 5 pre years (2006-2010) + 2 post years (2011-2012)
diagnostics <- list(
  n_treated = uniqueN(panel$fips),
  n_pre = length(unique(panel[year <= 2010]$year)),
  n_obs = nrow(panel),
  n_counties = uniqueN(panel$fips),
  n_years = uniqueN(panel$year),
  n_clusters = uniqueN(panel$state_fips),
  sd_y_pre = sd_y_pre,
  sd_hhi = sd_hhi,
  first_stage_f = fitstat(iv2, "ivf1")[[1]]$stat,
  iv_coef = iv2_coef,
  iv_se = iv2_se,
  ols_coef = coef(ols2)["hhi"],
  ols_se = se(ols2)["hhi"]
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics saved.\n")

save(ols1, ols2, ols3, fs1, fs2, iv1, iv2, iv3, rf1, rf2,
     mort_ols, mort_iv, mort_rf, panel, diagnostics,
     file = "../data/models.RData")
cat("Model objects saved.\n")
