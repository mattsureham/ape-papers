# 04_robustness.R — Robustness and validity checks
# apep_0712: UK Ground Rent Abolition

source("00_packages.R")

data_dir <- "../data"
rdd_sample <- readRDS(file.path(data_dir, "rdd_sample.rds"))
did_sample <- readRDS(file.path(data_dir, "did_sample.rds"))
ppd_analysis <- readRDS(file.path(data_dir, "ppd_analysis.rds"))

# ============================================================
# 1. Covariate balance at the cutoff
# ============================================================
cat("=== COVARIATE BALANCE ===\n")

# Test whether property composition changes at the cutoff
# Using indicator for flat type as covariate
# Since all RDD sample is flats, test geographic composition

# Test: is postcode_area distribution smooth at cutoff?
# Use London indicator as a pre-determined covariate
rdd_sample[, is_london := as.integer(postcode_area %in%
  c("E", "EC", "N", "NW", "SE", "SW", "W", "WC"))]

balance_london <- rdrobust(
  y = rdd_sample$is_london,
  x = rdd_sample$days_from_cutoff,
  c = 0, kernel = "triangular", p = 1
)
cat(sprintf("London indicator at cutoff: coef=%.4f, p=%.4f\n",
            balance_london$coef[1], balance_london$pv[3]))

# ============================================================
# 2. Donut RDD (exclude anticipation period)
# ============================================================
cat("\n=== DONUT RDD ===\n")

# Exclude transactions within 30 days of cutoff (anticipation)
donut_30 <- rdd_sample[abs(days_from_cutoff) > 30]
rdd_donut30 <- rdrobust(
  y = donut_30$log_price,
  x = donut_30$days_from_cutoff,
  c = 0, kernel = "triangular", p = 1
)
cat(sprintf("Donut (±30 days): coef=%.4f, se=%.4f, p=%.4f\n",
            rdd_donut30$coef[1], rdd_donut30$se[3], rdd_donut30$pv[3]))

# Exclude Feb-Jun 2022 (Royal Assent to implementation)
# This creates a large gap in the running variable — RDD may not be estimable
donut_assent <- rdd_sample[!(date_transfer >= as.Date("2022-02-08") &
                              date_transfer <= as.Date("2022-06-30"))]
rdd_donut_assent <- tryCatch({
  rdrobust(
    y = donut_assent$log_price,
    x = donut_assent$days_from_cutoff,
    c = 0, kernel = "triangular", p = 1
  )
}, error = function(e) {
  cat(sprintf("Donut (excl. Feb-Jun 2022): not estimable (%s)\n", e$message))
  NULL
})
if (!is.null(rdd_donut_assent)) {
  cat(sprintf("Donut (excl. Feb-Jun 2022): coef=%.4f, se=%.4f, p=%.4f\n",
              rdd_donut_assent$coef[1], rdd_donut_assent$se[3],
              rdd_donut_assent$pv[3]))
}

# ============================================================
# 3. Placebo cutoffs
# ============================================================
cat("\n=== PLACEBO CUTOFFS ===\n")

placebo_dates <- as.Date(c("2021-06-30", "2023-06-30"))
for (pd in placebo_dates) {
  pd <- as.Date(pd, origin = "1970-01-01")
  rdd_sample_tmp <- copy(rdd_sample)
  rdd_sample_tmp[, days_from_placebo := as.numeric(date_transfer - pd)]

  rdd_placebo <- rdrobust(
    y = rdd_sample_tmp$log_price,
    x = rdd_sample_tmp$days_from_placebo,
    c = 0, kernel = "triangular", p = 1
  )
  cat(sprintf("Placebo at %s: coef=%.4f, se=%.4f, p=%.4f\n",
              pd, rdd_placebo$coef[1], rdd_placebo$se[3], rdd_placebo$pv[3]))
}

# ============================================================
# 4. Placebo outcome: new-build freehold houses (unaffected)
# ============================================================
cat("\n=== PLACEBO OUTCOME: FREEHOLD HOUSES ===\n")

freehold_new <- ppd_analysis[group == "new_freehold" & property_type %in% c("D", "S", "T")]
freehold_new[, days_from_cutoff := as.numeric(date_transfer - as.Date("2022-06-30"))]

if (nrow(freehold_new) > 500) {
  rdd_placebo_freehold <- rdrobust(
    y = freehold_new$log_price,
    x = freehold_new$days_from_cutoff,
    c = 0, kernel = "triangular", p = 1
  )
  cat(sprintf("Freehold houses at cutoff: coef=%.4f, se=%.4f, p=%.4f\n",
              rdd_placebo_freehold$coef[1], rdd_placebo_freehold$se[3],
              rdd_placebo_freehold$pv[3]))
}

# ============================================================
# 5. Polynomial sensitivity (quadratic)
# ============================================================
cat("\n=== POLYNOMIAL SENSITIVITY ===\n")

rdd_quad <- rdrobust(
  y = rdd_sample$log_price,
  x = rdd_sample$days_from_cutoff,
  c = 0, kernel = "triangular", p = 2  # quadratic
)
cat(sprintf("Quadratic: coef=%.4f, se=%.4f, p=%.4f\n",
            rdd_quad$coef[1], rdd_quad$se[3], rdd_quad$pv[3]))

# ============================================================
# 6. Retirement property replication (Apr 1, 2023)
# ============================================================
cat("\n=== RETIREMENT PROPERTY REPLICATION ===\n")

# We cannot distinguish retirement properties in the data.
# Instead, use the April 2023 date as a second test on all
# new-build leasehold flats (some of which are retirement).
# This is a weaker test but provides temporal out-of-sample check.
rdd_sample_retire <- copy(rdd_sample)
rdd_sample_retire[, days_from_retire := as.numeric(date_transfer - as.Date("2023-04-01"))]

# Focus on 2022-2024 window
rdd_retire_sub <- rdd_sample_retire[year >= 2022 & year <= 2024]
if (nrow(rdd_retire_sub) > 200) {
  rdd_retire <- rdrobust(
    y = rdd_retire_sub$log_price,
    x = rdd_retire_sub$days_from_retire,
    c = 0, kernel = "triangular", p = 1
  )
  cat(sprintf("Retirement cutoff (Apr 2023): coef=%.4f, se=%.4f, p=%.4f\n",
              rdd_retire$coef[1], rdd_retire$se[3], rdd_retire$pv[3]))
}

# ============================================================
# 7. DiD with event study (monthly coefficients)
# ============================================================
cat("\n=== EVENT STUDY ===\n")

# Create relative month indicator
did_sample[, rel_month := 12 * (year - 2022) + month - 6]
# June 2022 = month 0 (normalize to month -1)
did_sample[, rel_month_factor := relevel(factor(rel_month), ref = "-1")]

es_fit <- feols(
  log_price ~ treated * rel_month_factor | postcode_area,
  data = did_sample[abs(rel_month) <= 18],
  cluster = ~postcode_area
)

# Extract interaction coefficients for event study plot
es_coefs <- data.frame(
  rel_month = as.integer(gsub("treated:rel_month_factor", "",
                              names(coef(es_fit)[grepl("treated:rel_month_factor",
                                                        names(coef(es_fit)))]))),
  coef = coef(es_fit)[grepl("treated:rel_month_factor", names(coef(es_fit)))],
  se = se(es_fit)[grepl("treated:rel_month_factor", names(coef(es_fit)))]
)
es_coefs <- es_coefs[order(es_coefs$rel_month), ]
es_coefs$ci_lo <- es_coefs$coef - 1.96 * es_coefs$se
es_coefs$ci_hi <- es_coefs$coef + 1.96 * es_coefs$se

cat("Event study coefficients (treated × month):\n")
print(es_coefs)

# ============================================================
# Save all robustness results
# ============================================================
save(balance_london, rdd_donut30, rdd_quad,
     es_coefs, es_fit,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nRobustness checks complete.\n")
