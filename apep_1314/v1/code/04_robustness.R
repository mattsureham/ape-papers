## 04_robustness.R — Robustness checks and mechanism tests
## apep_1314: The Prudential Drag
source("00_packages.R")
setwd("..")

panel <- fread("data/analysis_panel.csv")
panel[, treat := fin_share_2008 * post_crd]

cat("=== Robustness Checks ===\n")

# ============================================================================
# 1. Country-specific trends
# ============================================================================
cat("\n--- 1. Country-specific linear trends ---\n")

panel[, country_trend := as.numeric(factor(country)) * (year - 2008)]
panel[, country_f := factor(country)]

# Add country × year FE (absorbs all country-level shocks)
rob_country_yr <- feols(
  d_emp_total ~ treat | nuts2 + country_f^year,
  data = panel[!is.na(d_emp_total)],
  cluster = ~country
)
cat("Country × year FE:\n")
summary(rob_country_yr)

# ============================================================================
# 2. Pre-trend test (formal)
# ============================================================================
cat("\n--- 2. Pre-trend test ---\n")

pre_panel <- panel[year <= 2013]
pre_panel[, treat_pre := fin_share_2008 * (year - 2008)]

pre_test <- feols(
  d_emp_total ~ treat_pre | nuts2 + year,
  data = pre_panel[!is.na(d_emp_total)],
  cluster = ~country
)
cat("Pre-trend (share × linear time, 2008-2013):\n")
summary(pre_test)

# ============================================================================
# 3. Placebo: Non-financial employment as outcome
# ============================================================================
cat("\n--- 3. Non-financial employment placebo ---\n")

panel[, emp_nonfin := emp_total - emp_financial]
panel[, emp_nonfin_2008 := emp_nonfin[year == 2008][1], by = nuts2]
panel[, d_emp_nonfin := (emp_nonfin - emp_nonfin_2008) / emp_nonfin_2008 * 100]

rob_nonfin <- feols(
  d_emp_nonfin ~ treat | nuts2 + year,
  data = panel[!is.na(d_emp_nonfin)],
  cluster = ~country
)
cat("Non-financial employment (should be null if effect is only financial):\n")
summary(rob_nonfin)

# ============================================================================
# 4. Alternative treatment: above-median exposure (binary)
# ============================================================================
cat("\n--- 4. Binary treatment (above median share) ---\n")

med_share <- median(panel$fin_share_2008)
panel[, high_exposure := as.integer(fin_share_2008 > med_share)]
panel[, treat_binary := high_exposure * post_crd]

rob_binary <- feols(
  d_emp_total ~ treat_binary | nuts2 + year,
  data = panel[!is.na(d_emp_total)],
  cluster = ~country
)
cat("Binary treatment (above-median exposure):\n")
summary(rob_binary)

# ============================================================================
# 5. Exclude capital regions (financial centers)
# ============================================================================
cat("\n--- 5. Exclude capital/financial center regions ---\n")

# Capital NUTS2 codes for major financial centers
capitals <- c("DE30", "FR10", "UKI1", "UKI2", "ES30", "IT00",
              "NL32", "AT13", "BE10", "IE06", "LU00", "FI1B",
              "PT17", "EL30", "DK01", "SE11", "CZ01", "PL91",
              "HU11", "RO32", "BG41", "HR04", "SI04")

panel[, is_capital := nuts2 %in% capitals]

rob_nocap <- feols(
  d_emp_total ~ treat | nuts2 + year,
  data = panel[!is.na(d_emp_total) & is_capital == FALSE],
  cluster = ~country
)
cat("Excluding capital/financial center regions:\n")
summary(rob_nocap)

# ============================================================================
# 6. Excluding capitals + country×year FE (strongest specification)
# ============================================================================
cat("\n--- 6. Strongest: No capitals + Country×Year FE ---\n")

rob_strongest <- feols(
  d_emp_total ~ treat | nuts2 + country_f^year,
  data = panel[!is.na(d_emp_total) & is_capital == FALSE],
  cluster = ~country
)
cat("Strongest specification:\n")
summary(rob_strongest)

# Same for unemployment
rob_unemp_strong <- feols(
  d_unemp ~ treat | nuts2 + country_f^year,
  data = panel[!is.na(d_unemp) & is_capital == FALSE],
  cluster = ~country
)
cat("\nStrongest spec — Unemployment:\n")
summary(rob_unemp_strong)

# ============================================================================
# 7. Wild cluster bootstrap (for clustered SEs with 27 clusters)
# ============================================================================
cat("\n--- 7. Wild cluster bootstrap ---\n")

if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  # Main specification with WCB
  wcb_emp <- boottest(
    rf_emp_for_boot <- feols(
      d_emp_total ~ treat | nuts2 + year,
      data = panel[!is.na(d_emp_total)],
      cluster = ~country
    ),
    param = "treat",
    B = 999,
    clustid = "country",
    type = "webb"
  )
  cat("Wild cluster bootstrap — Total employment:\n")
  print(summary(wcb_emp))
} else {
  cat("  fwildclusterboot not available, skipping\n")
}

# ============================================================================
# Save robustness results
# ============================================================================
rob_results <- list(
  country_yr = rob_country_yr,
  pre_test = pre_test,
  nonfin = rob_nonfin,
  binary = rob_binary,
  nocap = rob_nocap,
  strongest = rob_strongest,
  unemp_strong = rob_unemp_strong
)
saveRDS(rob_results, "data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
