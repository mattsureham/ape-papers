## 03_main_analysis.R — Bunching estimation at FHB subsidy thresholds
## apep_1281: Pricing to the Cap
##
## Multi-cutoff bunching (Kleven 2016) at three price thresholds:
##   $600,000 — FHOG notch (new homes only, $10K grant)
##   $800,000 — Stamp duty exemption (all first home buyers, worth up to $31K)
##   $1,000,000 — Concession phase-out upper limit
##
## Migration test: July 2023 threshold shift ($650K→$800K)

source("00_packages.R")
source("bunching_utils.R")

dt <- fread("../data/analysis_sample.csv")
dt[, contract_date := as.Date(contract_date)]

## ====================================================================
## MAIN ESTIMATES — ALL RESIDENTIAL TRANSACTIONS
## ====================================================================

cat("\n=== POOLED BUNCHING ESTIMATES (All Residential, 2018-2025) ===\n\n")

dt_res <- dt[prop_type == "residential"]

thresholds <- c(600000, 800000, 1000000)
results <- list()

for (th in thresholds) {
  cat(sprintf("Estimating bunching at $%s ...\n", formatC(th, format = "d", big.mark = ",")))
  res <- estimate_bunching(dt_res, threshold = th)
  results[[as.character(th)]] <- res
  cat(sprintf("  Excess mass b = %.3f (SE = %.3f)\n", res$b, res$se))
  cat(sprintf("  Excess count = %d (observed %d, counterfactual %.0f)\n",
              res$excess, res$observed, res$counterfactual))
}

## ====================================================================
## MIGRATION TEST — PRE vs POST JULY 2023 REFORM
## ====================================================================

cat("\n=== MIGRATION TEST: Pre vs Post July 2023 ===\n\n")

dt_pre  <- dt_res[contract_date < as.Date("2023-07-01")]
dt_post <- dt_res[contract_date >= as.Date("2023-07-01")]

# Pre-reform: threshold was $650K for stamp duty exemption
# Post-reform: threshold moved to $800K
migration_thresholds <- c(650000, 800000)
migration_results <- list()

for (th in migration_thresholds) {
  cat(sprintf("--- $%s ---\n", formatC(th, format = "d", big.mark = ",")))

  cat("  Pre-reform:\n")
  pre_res <- estimate_bunching(dt_pre, threshold = th)
  cat(sprintf("    b = %.3f (SE = %.3f), excess = %d\n", pre_res$b, pre_res$se, pre_res$excess))

  cat("  Post-reform:\n")
  post_res <- estimate_bunching(dt_post, threshold = th)
  cat(sprintf("    b = %.3f (SE = %.3f), excess = %d\n", post_res$b, post_res$se, post_res$excess))

  migration_results[[paste0(th, "_pre")]] <- pre_res
  migration_results[[paste0(th, "_post")]] <- post_res
}

# Control: bunching at $550K and $750K (round numbers, no policy change)
cat("\n--- Control round numbers (should NOT migrate) ---\n")
for (th in c(550000, 750000)) {
  cat(sprintf("  $%s:\n", formatC(th, format = "d", big.mark = ",")))
  pre_c <- estimate_bunching(dt_pre, threshold = th)
  post_c <- estimate_bunching(dt_post, threshold = th)
  cat(sprintf("    Pre b = %.3f (SE = %.3f); Post b = %.3f (SE = %.3f)\n",
              pre_c$b, pre_c$se, post_c$b, post_c$se))
  migration_results[[paste0(th, "_pre")]] <- pre_c
  migration_results[[paste0(th, "_post")]] <- post_c
}

## ====================================================================
## SUPPLY vs DEMAND DECOMPOSITION
## ====================================================================

cat("\n=== SUPPLY vs DEMAND DECOMPOSITION ===\n\n")

# Vacant land = proxy for new construction (supply-side, developer pricing)
# Existing residence = demand-side (buyer negotiation)
dt_newbuild <- dt[prop_type == "vacant_land"]
dt_existing <- dt[prop_type == "residential"]

cat("--- $600K FHOG threshold (new homes eligible for $10K grant) ---\n")
cat("  Vacant land (proxy new build):\n")
vl_600 <- estimate_bunching(dt_newbuild, threshold = 600000)
cat(sprintf("    b = %.3f (SE = %.3f)\n", vl_600$b, vl_600$se))

cat("  Existing residences:\n")
ex_600 <- estimate_bunching(dt_existing, threshold = 600000)
cat(sprintf("    b = %.3f (SE = %.3f)\n", ex_600$b, ex_600$se))

cat("\n--- $800K Stamp duty threshold (all FHBs) ---\n")
cat("  Vacant land:\n")
vl_800 <- estimate_bunching(dt_newbuild, threshold = 800000)
cat(sprintf("    b = %.3f (SE = %.3f)\n", vl_800$b, vl_800$se))

cat("  Existing residences:\n")
ex_800 <- estimate_bunching(dt_existing, threshold = 800000)
cat(sprintf("    b = %.3f (SE = %.3f)\n", ex_800$b, ex_800$se))

## ====================================================================
## SAVE RESULTS
## ====================================================================

# Diagnostics for validator
n_thresholds <- length(thresholds)
n_obs <- nrow(dt_res)

diagnostics <- list(
  n_treated = n_thresholds,   # number of thresholds estimated
  n_pre = 66,                 # months pre-reform (Jan 2018 - Jun 2023)
  n_obs = n_obs,
  n_residential = nrow(dt_res),
  n_vacant = nrow(dt_newbuild),
  n_nonres = nrow(dt[prop_type %in% c("commercial", "farm")]),
  pooled_b_600k = results[["600000"]]$b,
  pooled_b_800k = results[["800000"]]$b,
  pooled_b_1m   = results[["1000000"]]$b,
  migration_650k_pre  = migration_results[["650000_pre"]]$b,
  migration_650k_post = migration_results[["650000_post"]]$b,
  migration_800k_pre  = migration_results[["800000_pre"]]$b,
  migration_800k_post = migration_results[["800000_post"]]$b
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

# Save results for table generation
save(results, migration_results, vl_600, ex_600, vl_800, ex_800,
     file = "../data/bunching_results.RData")

cat("\nDONE: 03_main_analysis.R\n")
