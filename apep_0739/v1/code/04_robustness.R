## 04_robustness.R — Robustness checks
## APEP-0739: GP Practice Closures and A&E Utilization

source("code/00_packages.R")

ae_qtr <- readRDS("data/ae_analysis.rds")
gp_closures <- readRDS("data/gp_closures_mapped.rds")

cat("=== Robustness Check 1: Distance bandwidth sensitivity ===\n")

## Re-map closures with different distance thresholds
run_twfe_at_distance <- function(dist_km) {
  closures_near <- gp_closures[dist_to_trust_km <= dist_km]
  first_closure <- closures_near[, .(first_treat_qtr = min(qtr_num)), by = nearest_trust]

  dt <- copy(ae_qtr[, .(provider_code, qtr_num, trust_id, log_type1, type1_att)])
  dt <- merge(dt, first_closure, by.x = "provider_code", by.y = "nearest_trust", all.x = TRUE)
  dt[is.na(first_treat_qtr), first_treat_qtr := 0]
  dt[, post := as.integer(qtr_num >= first_treat_qtr & first_treat_qtr > 0)]

  m <- feols(log_type1 ~ post | provider_code + qtr_num, data = dt, cluster = ~provider_code)
  data.table(
    dist_km = dist_km,
    beta = coef(m)[1],
    se = se(m)[1],
    n_treated = uniqueN(dt[first_treat_qtr > 0, provider_code]),
    n_obs = nrow(dt)
  )
}

dist_results <- rbindlist(lapply(c(5, 10, 15, 20, 25), run_twfe_at_distance))
cat("Distance sensitivity:\n")
print(dist_results)


cat("\n=== Robustness Check 2: Excluding COVID period (2020Q1-2021Q2) ===\n")

ae_nocovid <- ae_qtr[!(qtr_num >= 9 & qtr_num <= 14)]  # 2020Q1=9, 2021Q2=14
ae_nocovid[, post := as.integer(qtr_num >= first_treat_qtr & first_treat_qtr > 0)]

twfe_nocovid <- feols(
  log_type1 ~ post | provider_code + qtr_num,
  data = ae_nocovid,
  cluster = ~provider_code
)
cat("TWFE excluding COVID:\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(twfe_nocovid), se(twfe_nocovid)))


cat("\n=== Robustness Check 3: Excluding London ===\n")

## London trusts have provider codes starting with R (common) but we can
## identify them via the A&E data region column if available, or via postcode
## London postcodes: E, EC, N, NW, SE, SW, W, WC
london_prefixes <- c("^E[0-9]", "^EC", "^N[0-9]", "^NW", "^SE", "^SW[0-9]", "^W[0-9]", "^WC")
london_pattern <- paste(london_prefixes, collapse = "|")

trusts <- readRDS("data/trusts.rds")
london_trusts <- trusts[grepl(london_pattern, trust_postcode), trust_code]
cat(sprintf("London trusts identified: %d\n", length(london_trusts)))

ae_nolon <- ae_qtr[!provider_code %in% london_trusts]
ae_nolon[, post := as.integer(qtr_num >= first_treat_qtr & first_treat_qtr > 0)]

twfe_nolon <- feols(
  log_type1 ~ post | provider_code + qtr_num,
  data = ae_nolon,
  cluster = ~provider_code
)
cat("TWFE excluding London:\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(twfe_nolon), se(twfe_nolon)))


cat("\n=== Robustness Check 4: Placebo — Total attendances (including minor) ===\n")

## If closures mainly affect urgent care (theory: people go to A&E because
## they can't see GP), then total attendances (including walk-in/minor injury)
## should show a different pattern
ae_qtr[, post := as.integer(qtr_num >= first_treat_qtr & first_treat_qtr > 0)]

twfe_total <- feols(
  log_total ~ post | provider_code + qtr_num,
  data = ae_qtr,
  cluster = ~provider_code
)
cat("Placebo (total attendances including minor A&E):\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(twfe_total), se(twfe_total)))


cat("\n=== Robustness Check 5: Wild cluster bootstrap ===\n")

## Wild cluster bootstrap for the main specification
## Using fwildclusterboot package if available, otherwise skip
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  boot_result <- boottest(
    twfe1 <- feols(log_type1 ~ post | provider_code + qtr_num,
                   data = ae_qtr, cluster = ~provider_code),
    param = "post",
    clustid = "provider_code",
    B = 999,
    type = "webb"
  )
  cat("Wild cluster bootstrap p-value:", boot_result$p_val, "\n")
  cat("Bootstrap CI:", boot_result$conf_int, "\n")
} else {
  cat("fwildclusterboot not available — skipping.\n")
  ## Install for next run
  tryCatch(install.packages("fwildclusterboot", repos = "https://cloud.r-project.org"),
           error = function(e) cat("  Could not install fwildclusterboot\n"))
}


cat("\n=== Robustness Check 6: Pre-2023 only (excluding mass reorganization) ===\n")

## 2023 saw a massive spike in GP practice deactivations (1,693 of 2,259).
## This may reflect administrative cleanup rather than genuine closures.
gp_pre23 <- gp_closures[closure_year < 2023 & dist_to_trust_km <= 15]
first_closure_pre23 <- gp_pre23[, .(first_treat_qtr = min(qtr_num)), by = nearest_trust]

ae_pre23 <- copy(ae_qtr[, .(provider_code, qtr_num, trust_id, log_type1, type1_att)])
ae_pre23 <- merge(ae_pre23, first_closure_pre23, by.x = "provider_code", by.y = "nearest_trust", all.x = TRUE)
ae_pre23[is.na(first_treat_qtr), first_treat_qtr := 0]
ae_pre23[, post := as.integer(qtr_num >= first_treat_qtr & first_treat_qtr > 0)]

twfe_pre23 <- feols(
  log_type1 ~ post | provider_code + qtr_num,
  data = ae_pre23,
  cluster = ~provider_code
)
n_treated_pre23 <- uniqueN(ae_pre23[first_treat_qtr > 0, provider_code])
cat(sprintf("TWFE pre-2023 only (n_treated=%d):\n", n_treated_pre23))
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(twfe_pre23), se(twfe_pre23)))


cat("\n=== Save robustness results ===\n")

robust <- list(
  dist_sensitivity = dist_results,
  twfe_nocovid = twfe_nocovid,
  twfe_nolon = twfe_nolon,
  twfe_total = twfe_total,
  twfe_pre23 = twfe_pre23,
  n_treated_pre23 = n_treated_pre23
)
saveRDS(robust, "data/robustness_results.rds")

cat("Robustness checks complete.\n")
