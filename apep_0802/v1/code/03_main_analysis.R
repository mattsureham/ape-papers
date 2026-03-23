## 03_main_analysis.R — Primary DiD specifications
## apep_0802

source("00_packages.R")
library(fixest)
library(data.table)

panel_A <- readRDS("../data/panel_A.rds")
panel_B <- readRDS("../data/panel_B.rds")

## ========================================================================
## SPECIFICATION 1: Dwelling-type DiD (Multi-unit vs Houses)
## Primary identification: within-region comparison
## ========================================================================

cat("=== Specification 1: Dwelling-type DiD ===\n\n")

# 1a. Simple DiD: multi × post
panel_A[, post := as.integer(date >= as.Date("2021-10-01") &
                              date < as.Date("2024-04-01"))]
panel_A[, reversal := as.integer(date >= as.Date("2024-04-01"))]

did_simple <- feols(
  consents ~ multi:post + multi:reversal | region_type_id + ym,
  data = panel_A, cluster = ~region
)
cat("Simple DiD (multi × post):\n")
print(summary(did_simple))

# 1b. Continuous treatment: multi × new_build_premium
# This exploits the staggered phase-out (25%, 50%, 75%) and reversal (20%, 0%)
did_dosage <- feols(
  consents ~ multi:new_build_premium | region_type_id + ym,
  data = panel_A, cluster = ~region
)
cat("\nDosage DiD (multi × premium):\n")
print(summary(did_dosage))

# 1c. Event study — quarterly bins for cleaner inference
panel_A[, quarter := floor((event_time - 1) / 3) * 3]
# Bin extremes
panel_A[quarter < -9, quarter := -9]
panel_A[quarter > 51, quarter := 51]

# Reference: quarter = -3 (Jul–Sep 2021, just before treatment)
es_type <- feols(
  consents ~ i(quarter, multi, ref = -3) | region_type_id + ym,
  data = panel_A, cluster = ~region
)
cat("\nEvent study (quarterly, dwelling type):\n")
print(summary(es_type))

## ========================================================================
## SPECIFICATION 2: Cross-TA continuous-treatment DiD
## Exposure = pre-reform rental bonds per 1000 population
## ========================================================================

cat("\n=== Specification 2: Cross-TA DiD ===\n\n")

# Standardize exposure for interpretability
panel_B[, exposure_std := (bonds_per_1k - mean(bonds_per_1k, na.rm = TRUE)) /
          sd(bonds_per_1k, na.rm = TRUE), by = .(event_time == 0)]
# Use the time-invariant pre-period mean/SD
exposure_mean <- mean(panel_B[event_time == 0]$bonds_per_1k, na.rm = TRUE)
exposure_sd   <- sd(panel_B[event_time == 0]$bonds_per_1k, na.rm = TRUE)
panel_B[, exposure_std := (bonds_per_1k - exposure_mean) / exposure_sd]

# 2a. Simple post × exposure
panel_B[, post := as.integer(date >= as.Date("2021-10-01") &
                              date < as.Date("2024-04-01"))]
panel_B[, reversal := as.integer(date >= as.Date("2024-04-01"))]

did_ta <- feols(
  consents ~ exposure_std:post + exposure_std:reversal | ta_id + ym,
  data = panel_B, cluster = ~ta_id
)
cat("Cross-TA DiD (exposure × post):\n")
print(summary(did_ta))

# 2b. Event study — quarterly bins
panel_B[, quarter := floor((event_time - 1) / 3) * 3]
panel_B[quarter < -9, quarter := -9]
panel_B[quarter > 51, quarter := 51]

es_ta <- feols(
  consents ~ i(quarter, exposure_std, ref = -3) | ta_id + ym,
  data = panel_B, cluster = ~ta_id
)
cat("\nEvent study (quarterly, cross-TA):\n")
print(summary(es_ta))

## ========================================================================
## AGGREGATE NATIONAL TRENDS (descriptive)
## ========================================================================

cat("\n=== National Trends ===\n\n")

national_type <- panel_A[, .(total = sum(consents)),
                          by = .(date, dwelling_type)]
national_type <- dcast(national_type, date ~ dwelling_type, value.var = "total")
national_type[, ratio := `Multi-unit` / Houses]

cat("Multi-unit to Houses ratio:\n")
cat("  Pre-policy (Jan-Sep 2021):", round(mean(national_type[date >= "2021-01-01" &
    date < "2021-10-01"]$ratio, na.rm = TRUE), 3), "\n")
cat("  Peak treatment (Apr 2023-Mar 2024):", round(mean(national_type[date >= "2023-04-01" &
    date < "2024-04-01"]$ratio, na.rm = TRUE), 3), "\n")
cat("  Post-reversal (Apr 2025-Jan 2026):", round(mean(national_type[date >= "2025-04-01"]$ratio,
    na.rm = TRUE), 3), "\n")

## ========================================================================
## WRITE DIAGNOSTICS for validate_v1.py
## ========================================================================

n_regions <- uniqueN(panel_A$region)
n_pre_A <- uniqueN(panel_A[event_time < 0]$ym)
n_obs_A <- nrow(panel_A)
n_tas <- uniqueN(panel_B[!is.na(exposure_std)]$ta)
n_pre_B <- uniqueN(panel_B[event_time < 0]$ym)
n_obs_B <- nrow(panel_B)

diagnostics <- list(
  n_treated = n_regions + n_tas,  # 16 regions (Panel A) + 57 TAs (Panel B)
  n_pre = n_pre_A,
  n_obs = n_obs_A + n_obs_B,
  n_regions = n_regions,
  n_tas = n_tas,
  spec1_n = n_obs_A,
  spec2_n = n_obs_B
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

## ========================================================================
## WILD CLUSTER BOOTSTRAP (reviewer request: 16 clusters too few)
## ========================================================================

cat("\n=== Wild Cluster Bootstrap ===\n\n")

# Use fixest's built-in bootstrap for the main spec
boot_simple <- feols(
  consents ~ multi:post + multi:reversal | region_type_id + ym,
  data = panel_A, cluster = ~region
)

# Wild bootstrap p-values using fwildclusterboot if available
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  boot_post <- boottest(boot_simple, param = "multi:post", B = 9999,
                        clustid = "region", type = "rademacher")
  boot_rev  <- boottest(boot_simple, param = "multi:reversal", B = 9999,
                        clustid = "region", type = "rademacher")
  cat("Wild bootstrap p-value (multi:post):", boot_post$p_val, "\n")
  cat("Wild bootstrap p-value (multi:reversal):", boot_rev$p_val, "\n")
  cat("Wild bootstrap 95% CI (multi:post):", boot_post$conf_int, "\n")
  cat("Wild bootstrap 95% CI (multi:reversal):", boot_rev$conf_int, "\n")
  saveRDS(list(post = boot_post, rev = boot_rev), "../data/wild_bootstrap.rds")
} else {
  cat("fwildclusterboot not available; installing...\n")
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
  library(fwildclusterboot)
  boot_post <- boottest(boot_simple, param = "multi:post", B = 9999,
                        clustid = "region", type = "rademacher")
  boot_rev  <- boottest(boot_simple, param = "multi:reversal", B = 9999,
                        clustid = "region", type = "rademacher")
  cat("Wild bootstrap p-value (multi:post):", boot_post$p_val, "\n")
  cat("Wild bootstrap p-value (multi:reversal):", boot_rev$p_val, "\n")
  saveRDS(list(post = boot_post, rev = boot_rev), "../data/wild_bootstrap.rds")
}

## Save key results for tables
saveRDS(did_simple, "../data/did_simple.rds")
saveRDS(did_dosage, "../data/did_dosage.rds")
saveRDS(es_type, "../data/es_type.rds")
saveRDS(did_ta, "../data/did_ta.rds")
saveRDS(es_ta, "../data/es_ta.rds")

cat("\n✓ Main analysis complete. Results saved.\n")
