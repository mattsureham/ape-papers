## 04_robustness.R — Robustness checks and placebo tests
## apep_0802

source("00_packages.R")

panel_A <- readRDS("../data/panel_A.rds")
panel_B <- readRDS("../data/panel_B.rds")

## ========================================================================
## ROBUSTNESS 1: Leave-one-out (drop Auckland)
## Auckland dominates national multi-unit counts
## ========================================================================

cat("=== Robustness: Leave Auckland out ===\n")

panel_A_no_auck <- panel_A[region != "Auckland"]

panel_A_no_auck[, post := as.integer(date >= as.Date("2021-10-01") &
                                      date < as.Date("2024-04-01"))]
panel_A_no_auck[, reversal := as.integer(date >= as.Date("2024-04-01"))]

rob_no_auck <- feols(
  consents ~ multi:post + multi:reversal | region_type_id + ym,
  data = panel_A_no_auck, cluster = ~region
)
cat("Without Auckland:\n")
print(summary(rob_no_auck))

## ========================================================================
## ROBUSTNESS 2: Poisson regression (count data)
## ========================================================================

cat("\n=== Robustness: Poisson ===\n")

panel_A[, post := as.integer(date >= as.Date("2021-10-01") &
                              date < as.Date("2024-04-01"))]
panel_A[, reversal := as.integer(date >= as.Date("2024-04-01"))]

rob_poisson <- fepois(
  consents ~ multi:post + multi:reversal | region_type_id + ym,
  data = panel_A, cluster = ~region
)
cat("Poisson:\n")
print(summary(rob_poisson))

## ========================================================================
## ROBUSTNESS 3: Log specification
## ========================================================================

cat("\n=== Robustness: Log consents ===\n")

panel_A[, log_consents := log(consents + 1)]

rob_log <- feols(
  log_consents ~ multi:post + multi:reversal | region_type_id + ym,
  data = panel_A, cluster = ~region
)
cat("Log specification:\n")
print(summary(rob_log))

## ========================================================================
## ROBUSTNESS 4: Alternative treatment timing
## Use announcement date (March 23, 2021) instead of effective date
## ========================================================================

cat("\n=== Robustness: Announcement date ===\n")

panel_A[, post_announce := as.integer(date >= as.Date("2021-04-01") &
                                       date < as.Date("2024-04-01"))]

rob_announce <- feols(
  consents ~ multi:post_announce + multi:reversal | region_type_id + ym,
  data = panel_A, cluster = ~region
)
cat("Announcement date (Apr 2021+):\n")
print(summary(rob_announce))

## ========================================================================
## ROBUSTNESS 5: Cross-TA — top vs bottom tercile of rental intensity
## ========================================================================

cat("\n=== Robustness: Tercile exposure ===\n")

# Create tercile bins
panel_B[, post := as.integer(date >= as.Date("2021-10-01") &
                              date < as.Date("2024-04-01"))]
panel_B[, reversal := as.integer(date >= as.Date("2024-04-01"))]

exposure_vals <- unique(panel_B[, .(ta_id, bonds_per_1k)])
q33 <- quantile(exposure_vals$bonds_per_1k, 1/3, na.rm = TRUE)
q67 <- quantile(exposure_vals$bonds_per_1k, 2/3, na.rm = TRUE)

panel_B[, tercile := fcase(
  bonds_per_1k <= q33, "low",
  bonds_per_1k <= q67, "mid",
  default = "high"
)]
panel_B[, high_exposure := as.integer(tercile == "high")]

rob_tercile <- feols(
  consents ~ high_exposure:post + high_exposure:reversal | ta_id + ym,
  data = panel_B, cluster = ~ta_id
)
cat("Tercile exposure:\n")
print(summary(rob_tercile))

## Save robustness results
saveRDS(rob_no_auck, "../data/rob_no_auck.rds")
saveRDS(rob_poisson, "../data/rob_poisson.rds")
saveRDS(rob_log, "../data/rob_log.rds")
saveRDS(rob_announce, "../data/rob_announce.rds")
saveRDS(rob_tercile, "../data/rob_tercile.rds")

cat("\n✓ Robustness checks complete.\n")
