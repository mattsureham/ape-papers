# ==============================================================================
# 04_robustness.R — Robustness checks and sensitivity analysis
# APEP-0570: Malaysia GST-to-SST Tax Pass-Through
# ==============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, date := as.Date(date)]
panel[, class_id := as.factor(class)]
panel[, date_id := as.factor(date)]

# Recreate time variables
panel[, `:=`(
  event_month = as.integer(12 * (year(date) - 2018) + month(date) - 5),
  gst_era = as.integer(date >= as.Date("2015-04-01") & date < as.Date("2018-06-01")),
  holiday_era = as.integer(date >= as.Date("2018-06-01") & date < as.Date("2018-09-01")),
  sst_era = as.integer(date >= as.Date("2018-09-01"))
)]

cat("=== Robustness Checks ===\n")

# ==============================================================================
# 1. PLACEBO TIMING TESTS
# ==============================================================================

cat("\n--- Placebo Timing Tests ---\n")

# Placebo 1: Move treatment to June 2017
panel[, post_june_2017 := as.integer(date >= as.Date("2017-06-01"))]
placebo_2017 <- feols(log_cpi ~ I(treated * post_june_2017) | class_id + date_id,
                      data = panel[date < as.Date("2018-06-01")],  # Pre-actual treatment only
                      cluster = ~class_id)

# Placebo 2: Move treatment to June 2016
panel[, post_june_2016 := as.integer(date >= as.Date("2016-06-01"))]
placebo_2016 <- feols(log_cpi ~ I(treated * post_june_2016) | class_id + date_id,
                      data = panel[date < as.Date("2018-06-01")],
                      cluster = ~class_id)

# Placebo 3: Move treatment to June 2015 (right after GST introduction)
panel[, post_june_2015 := as.integer(date >= as.Date("2015-06-01"))]
placebo_2015 <- feols(log_cpi ~ I(treated * post_june_2015) | class_id + date_id,
                      data = panel[date < as.Date("2018-06-01")],
                      cluster = ~class_id)

cat("Placebo 2017:", coef(placebo_2017)[1], "(SE:", se(placebo_2017)[1], ")\n")
cat("Placebo 2016:", coef(placebo_2016)[1], "(SE:", se(placebo_2016)[1], ")\n")
cat("Placebo 2015:", coef(placebo_2015)[1], "(SE:", se(placebo_2015)[1], ")\n")

placebo_results <- data.table(
  placebo_year = c(2015, 2016, 2017),
  estimate = c(coef(placebo_2015)[1], coef(placebo_2016)[1], coef(placebo_2017)[1]),
  se = c(se(placebo_2015)[1], se(placebo_2016)[1], se(placebo_2017)[1])
)
placebo_results[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se,
                       significant = abs(estimate / se) > 1.96)]
fwrite(placebo_results, "../data/placebo_timing.csv")

# ==============================================================================
# 2. LEAVE-ONE-CLASS-OUT
# ==============================================================================

cat("\n--- Leave-One-Class-Out Stability ---\n")

classes <- unique(panel$class)
loo_results <- list()

for (i in seq_along(classes)) {
  excluded <- classes[i]
  m_loo <- feols(log_cpi ~ treat_post_june | class_id + date_id,
                 data = panel[class != excluded],
                 cluster = ~class_id)
  loo_results[[i]] <- data.table(
    excluded_class = excluded,
    estimate = coef(m_loo)["treat_post_june"],
    se = se(m_loo)["treat_post_june"]
  )
}

loo_dt <- rbindlist(loo_results)
loo_dt[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]

# Full-sample benchmark
load("../data/main_models.RData")
full_est <- coef(m1)["treat_post_june"]

cat(sprintf("Full sample estimate: %.4f\n", full_est))
cat(sprintf("LOO range: [%.4f, %.4f]\n", min(loo_dt$estimate), max(loo_dt$estimate)))
cat(sprintf("LOO mean: %.4f\n", mean(loo_dt$estimate)))
cat(sprintf("Max deviation from full: %.4f\n",
            max(abs(loo_dt$estimate - full_est))))

fwrite(loo_dt, "../data/loo_results.csv")

# ==============================================================================
# 3. RANDOMIZATION INFERENCE
# ==============================================================================

cat("\n--- Randomization Inference ---\n")

set.seed(20180601)
n_permutations <- 1000
n_treated <- sum(unique(panel[, .(class, treated)])[, treated])
all_classes <- unique(panel$class)
actual_est <- full_est

ri_estimates <- numeric(n_permutations)

for (p in 1:n_permutations) {
  if (p %% 100 == 0) cat("  Permutation", p, "/", n_permutations, "\n")

  # Randomly reassign treatment
  perm_treated <- sample(all_classes, n_treated)
  panel[, treated_perm := as.integer(class %in% perm_treated)]
  panel[, treat_post_perm := treated_perm * post_june]

  m_perm <- feols(log_cpi ~ treat_post_perm | class_id + date_id,
                  data = panel, cluster = ~class_id)
  ri_estimates[p] <- coef(m_perm)["treat_post_perm"]
}

# RI p-value
ri_pval <- mean(abs(ri_estimates) >= abs(actual_est))
cat(sprintf("\nRI p-value (two-sided): %.4f\n", ri_pval))
cat(sprintf("Actual estimate: %.4f\n", actual_est))
cat(sprintf("RI distribution: mean = %.4f, sd = %.4f\n",
            mean(ri_estimates), sd(ri_estimates)))

ri_dt <- data.table(
  permutation = 1:n_permutations,
  estimate = ri_estimates
)
ri_dt[, actual := actual_est]
fwrite(ri_dt, "../data/ri_estimates.csv")

ri_summary <- data.table(
  actual_estimate = actual_est,
  ri_pvalue = ri_pval,
  ri_mean = mean(ri_estimates),
  ri_sd = sd(ri_estimates),
  n_permutations = n_permutations
)
fwrite(ri_summary, "../data/ri_summary.csv")

# ==============================================================================
# 4. PRE-TREND FORMAL TEST
# ==============================================================================

cat("\n--- Pre-trend Formal Test ---\n")

# Joint F-test on pre-treatment event-study coefficients
es_panel <- panel[event_month >= -36 & event_month <= 36]
es_full <- feols(log_cpi ~ i(event_month, treated, ref = 0) |
                   class_id + date_id,
                 data = es_panel, cluster = ~class_id)

# Extract pre-treatment coefficients (event_month < 0)
all_coefs <- coeftable(es_full)
pre_coefs <- all_coefs[grep("event_month.*::-", rownames(all_coefs)), ]
cat("Number of pre-treatment coefficients:", nrow(pre_coefs), "\n")
cat("Pre-trend F-test:\n")

# Wald test for joint significance of pre-treatment coefficients
pre_names <- rownames(pre_coefs)
if (length(pre_names) > 0) {
  wald_res <- wald(es_full, pre_names)
  cat("  Wald statistic:", wald_res$stat, "\n")
  cat("  p-value:", wald_res$p, "\n")

  pretrend_result <- data.table(
    test = "Joint pre-trend F-test (36 months)",
    statistic = wald_res$stat,
    pvalue = wald_res$p,
    n_preperiods = length(pre_names)
  )

  # Short-window pre-trend test (last 12 months only, the preferred window)
  short_pre_names <- pre_names[grep("::-([1-9]|1[0-2]):", pre_names)]
  if (length(short_pre_names) > 0) {
    wald_short <- wald(es_full, short_pre_names)
    cat("\n  Short-window (12 months) Wald statistic:", wald_short$stat, "\n")
    cat("  Short-window p-value:", wald_short$p, "\n")

    pretrend_short <- data.table(
      test = "Joint pre-trend F-test (12 months)",
      statistic = wald_short$stat,
      pvalue = wald_short$p,
      n_preperiods = length(short_pre_names)
    )
    pretrend_result <- rbind(pretrend_result, pretrend_short)
  }

  fwrite(pretrend_result, "../data/pretrend_test.csv")
}

# ==============================================================================
# 5. ALTERNATIVE WINDOW SPECIFICATIONS
# ==============================================================================

cat("\n--- Alternative Window Specifications ---\n")

# Window 1: Short window (2017-2019 only)
m_short <- feols(log_cpi ~ treat_post_june | class_id + date_id,
                 data = panel[date >= "2017-01-01" & date <= "2019-12-31"],
                 cluster = ~class_id)

# Window 2: Medium window (2016-2020)
m_med <- feols(log_cpi ~ treat_post_june | class_id + date_id,
               data = panel[date >= "2016-01-01" & date <= "2020-12-31"],
               cluster = ~class_id)

# Window 3: Pre-COVID only (up to Feb 2020)
m_precovid <- feols(log_cpi ~ treat_post_june | class_id + date_id,
                    data = panel[date <= "2020-02-29"],
                    cluster = ~class_id)

# Window 4: Excluding GST introduction period (start from 2016)
m_post_gst_intro <- feols(log_cpi ~ treat_post_june | class_id + date_id,
                          data = panel[date >= "2016-01-01"],
                          cluster = ~class_id)

window_results <- data.table(
  window = c("Full sample", "2017-2019", "2016-2020", "Pre-COVID", "Post-GST intro"),
  estimate = c(full_est,
               coef(m_short)["treat_post_june"],
               coef(m_med)["treat_post_june"],
               coef(m_precovid)["treat_post_june"],
               coef(m_post_gst_intro)["treat_post_june"]),
  se = c(se(m1)["treat_post_june"],
         se(m_short)["treat_post_june"],
         se(m_med)["treat_post_june"],
         se(m_precovid)["treat_post_june"],
         se(m_post_gst_intro)["treat_post_june"]),
  n_obs = c(m1$nobs, m_short$nobs, m_med$nobs, m_precovid$nobs, m_post_gst_intro$nobs)
)
window_results[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]
fwrite(window_results, "../data/window_robustness.csv")

cat("\nWindow robustness results:\n")
print(window_results)

# ==============================================================================
# 6. GST INTRODUCTION (April 2015) AS ADDITIONAL SHOCK
# ==============================================================================

cat("\n--- GST Introduction (2015) Analysis ---\n")

# The April 2015 GST introduction is an additional treatment event
# Standard-rated products should have seen price INCREASES in April 2015
panel[, post_gst_intro := as.integer(date >= as.Date("2015-04-01"))]
panel[, treat_post_gst := treated * post_gst_intro]

# Restrict to pre-June-2018 for clean estimation
m_gst_intro <- feols(log_cpi ~ treat_post_gst | class_id + date_id,
                     data = panel[date < as.Date("2018-06-01")],
                     cluster = ~class_id)

cat("GST introduction (2015) effect:\n")
summary(m_gst_intro)

gst_intro_result <- data.table(
  event = "GST introduction April 2015",
  estimate = coef(m_gst_intro)["treat_post_gst"],
  se = se(m_gst_intro)["treat_post_gst"],
  expected_sign = "positive (prices increase with new tax)"
)
fwrite(gst_intro_result, "../data/gst_introduction_effect.csv")

# ==============================================================================
# 7. DIVISION-LEVEL (2-DIGIT) ROBUSTNESS
# ==============================================================================

cat("\n--- 2-Digit Division-Level Analysis ---\n")

cpi_2d <- fread("../data/cpi_2d_raw.csv")
cpi_2d[, date := as.Date(date)]

# Get the column name for division code
div_col <- names(cpi_2d)[2]  # Should be 'division' or similar
cat("Division column:", div_col, "\n")
cat("Divisions:", unique(cpi_2d[[div_col]]), "\n")

# Classify divisions by GST status
# Using the same approach: observed June 2018 price breaks
cpi_2d[, log_index := log(index)]
cpi_2d[, post_june := as.integer(date >= as.Date("2018-06-01"))]

# Compute June break by division
div_may <- cpi_2d[date == as.Date("2018-05-01"), .(div = get(div_col), may_cpi = index)]
div_jun <- cpi_2d[date == as.Date("2018-06-01"), .(div = get(div_col), jun_cpi = index)]
div_break <- merge(div_may, div_jun, by = "div")
div_break[, pct_change := (jun_cpi / may_cpi - 1) * 100]
cat("\nDivision-level June 2018 breaks:\n")
print(div_break[order(pct_change)])

# Classify: divisions with >1.5% drop = treated
div_break[, treated_div := as.integer(pct_change < -1.5)]

# Merge
cpi_2d[, div := get(div_col)]
cpi_2d <- merge(cpi_2d, div_break[, .(div, treated_div)], by = "div")
cpi_2d[, treat_post := treated_div * post_june]
cpi_2d[, div_id := as.factor(div)]
cpi_2d[, date_id := as.factor(date)]

m_2d <- feols(log_index ~ treat_post | div_id + date_id,
              data = cpi_2d, cluster = ~div_id)

cat("\n2-digit division DiD:\n")
summary(m_2d)

div_result <- data.table(
  level = "2-digit division",
  estimate = coef(m_2d)["treat_post"],
  se = se(m_2d)["treat_post"],
  n_obs = m_2d$nobs,
  n_clusters = length(unique(cpi_2d[, div_id]))
)
fwrite(div_result, "../data/division_level_result.csv")

# Save all robustness models
save(placebo_2015, placebo_2016, placebo_2017,
     m_short, m_med, m_precovid, m_post_gst_intro,
     m_gst_intro, m_2d,
     file = "../data/robustness_models.RData")

# ==============================================================================
# 8. FORMAL SYMMETRY TEST: |beta_removal| = |beta_reimposition|
# ==============================================================================
# In DDD model m3:
#   treat_post_june     = beta1 (GST removal effect, negative)
#   treat_sst_post_sept = beta2 (SST reimposition increment, positive)
# H0: |beta1| = |beta2|  <=>  beta1 + beta2 = 0  (since beta1 < 0, beta2 > 0)
# Wald test via linearHypothesis from the 'car' package.
# The linear restriction is: treat_post_june + treat_sst_post_sept = 0

cat("\n--- Formal Symmetry Test: |beta_removal| = |beta_reimposition| ---\n")

library(car)

# m3 is already loaded from main_models.RData (loaded above via load())
# Build the vcov from m3's clustered SE
# fixest stores the variance-covariance matrix; extract it
vcov_m3 <- vcov(m3)

# Coefficient names in m3
cat("m3 coefficient names:", paste(names(coef(m3)), collapse=", "), "\n")

beta1 <- coef(m3)["treat_post_june"]
beta2 <- coef(m3)["treat_sst_post_sept"]
cat(sprintf("beta1 (removal):      %.4f\n", beta1))
cat(sprintf("beta2 (reimposition): %.4f\n", beta2))
cat(sprintf("Asymmetry: beta1 + beta2 = %.4f\n", beta1 + beta2))

# Wald test: H0: beta1 + beta2 = 0
# Using the delta method / Wald approach with the clustered vcov from fixest
# R = [1, 1] (the restriction matrix applied to [beta1, beta2])
R_mat <- matrix(c(1, 1), nrow = 1)
colnames(R_mat) <- names(coef(m3))

# Compute Wald statistic manually using the clustered vcov
# W = (R*b - r)' [R * V * R']^{-1} (R*b - r)
Rb <- as.numeric(R_mat %*% coef(m3))    # = beta1 + beta2
RVR <- as.numeric(R_mat %*% vcov_m3 %*% t(R_mat))  # scalar variance
wald_stat <- Rb^2 / RVR                  # Chi-squared(1) under H0
wald_pval <- pchisq(wald_stat, df = 1, lower.tail = FALSE)

cat(sprintf("\nWald test (H0: beta1 + beta2 = 0, i.e., full symmetry):\n"))
cat(sprintf("  Wald statistic (chi-sq, df=1): %.4f\n", wald_stat))
cat(sprintf("  p-value: %.4f\n", wald_pval))
cat(sprintf("  Conclusion: %s\n",
            ifelse(wald_pval < 0.05, "Reject symmetry (significant asymmetry)",
                   "Fail to reject symmetry")))

# Also compute the F-version (Wald/q) as a sanity check
f_stat <- wald_stat / 1
cat(sprintf("  F-statistic (df1=1): %.4f (equivalent)\n", f_stat))

symmetry_result <- data.table(
  test          = "Symmetry: H0: |beta_removal| = |beta_reimposition|",
  beta1_removal = beta1,
  beta2_reimposition = beta2,
  sum_betas     = beta1 + beta2,
  wald_chisq    = wald_stat,
  df            = 1,
  pvalue        = wald_pval,
  reject_h0     = wald_pval < 0.05
)
fwrite(symmetry_result, "../data/symmetry_test.csv")
cat("Symmetry test saved to ../data/symmetry_test.csv\n")

# ==============================================================================
# 9. DELTA-METHOD CIs FOR PASS-THROUGH RATES AND ASYMMETRY RATIO
# ==============================================================================
# Pass-through rate (removal) = beta1 / (-log(1.06))
# Asymmetry ratio              = |beta2| / |beta1| = beta2 / (-beta1)
#                              = -beta2 / beta1  (beta1 < 0, beta2 > 0)
# Delta method for ratio g(b) = f(beta1, beta2):
#   Var[g] ≈ (dg/db)' V (dg/db)

cat("\n--- Delta-Method CIs for Pass-Through Rates and Asymmetry Ratio ---\n")

gst_rate         <- 0.06
full_pt_benchmark <- -log(1 + gst_rate)   # -0.05827 (full pass-through for 6% GST)

# --- (a) Pass-through rate for GST removal (from m3's beta1) ---
# g1(beta1) = beta1 / full_pt_benchmark
# dg1/dbeta1 = 1 / full_pt_benchmark ; dg1/dbeta2 = 0
ptr_removal_m3  <- beta1 / full_pt_benchmark
grad_ptr        <- c(1 / full_pt_benchmark, 0)
var_ptr         <- as.numeric(t(grad_ptr) %*% vcov_m3 %*% grad_ptr)
se_ptr          <- sqrt(var_ptr)
ci_ptr_lo       <- ptr_removal_m3 - 1.96 * se_ptr
ci_ptr_hi       <- ptr_removal_m3 + 1.96 * se_ptr

cat(sprintf("Pass-through (GST removal, from m3):\n"))
cat(sprintf("  Estimate: %.3f (%.1f%%)\n", ptr_removal_m3, ptr_removal_m3 * 100))
cat(sprintf("  Delta-method SE: %.4f\n", se_ptr))
cat(sprintf("  95%% CI: [%.3f, %.3f] ([%.1f%%, %.1f%%])\n",
            ci_ptr_lo, ci_ptr_hi, ci_ptr_lo * 100, ci_ptr_hi * 100))

# --- (b) Asymmetry ratio = -beta2 / beta1 = |beta2|/|beta1| ---
# g2(beta1, beta2) = -beta2 / beta1
# dg2/dbeta1 = beta2 / beta1^2
# dg2/dbeta2 = -1 / beta1
asym_ratio      <- -beta2 / beta1
grad_asym       <- c(beta2 / beta1^2,   # d/dbeta1
                     -1 / beta1)         # d/dbeta2
var_asym        <- as.numeric(t(grad_asym) %*% vcov_m3 %*% grad_asym)
se_asym         <- sqrt(var_asym)
ci_asym_lo      <- asym_ratio - 1.96 * se_asym
ci_asym_hi      <- asym_ratio + 1.96 * se_asym

cat(sprintf("\nAsymmetry ratio (|beta2|/|beta1|):\n"))
cat(sprintf("  Estimate: %.3f\n", asym_ratio))
cat(sprintf("  Delta-method SE: %.4f\n", se_asym))
cat(sprintf("  95%% CI: [%.3f, %.3f]\n", ci_asym_lo, ci_asym_hi))
cat(sprintf("  Interpretation: SST reimposition recovered %.1f%% of GST removal price effect\n",
            asym_ratio * 100))

delta_method_results <- data.table(
  parameter = c("pass_through_rate_removal", "asymmetry_ratio"),
  estimate  = c(ptr_removal_m3,   asym_ratio),
  se_delta  = c(se_ptr,           se_asym),
  ci_lo_95  = c(ci_ptr_lo,        ci_asym_lo),
  ci_hi_95  = c(ci_ptr_hi,        ci_asym_hi),
  notes = c(
    paste0("beta1 / (-log(1.06)); full_pt_benchmark = ", round(full_pt_benchmark, 5)),
    "-beta2 / beta1; ratio of reimposition to removal effect"
  )
)
fwrite(delta_method_results, "../data/delta_method_cis.csv")
cat("Delta-method CIs saved to ../data/delta_method_cis.csv\n")

# ==============================================================================
# 10. SEPARATE ZERO-RATED VS EXEMPT CONTROLS
# ==============================================================================
# The class_map collapses both zero-rated and exempt goods into Group C
# (gst_status == "zero_exempt"). We sub-classify Group C using COICOP-based
# legal knowledge of Malaysia's GST schedules:
#
# ZERO-RATED (GST Zero-Rated Supply Order 2014):
#   Basic food items: rice, flour, cooking oil, sugar, vegetables, fish,
#   eggs, poultry, noodles, bread, coffee/tea, water supply, electricity
#   COICOP classes approx: 1010,1020,1030,1040 (cereals), 1111,1120 (oil/fats),
#   1212,1214 (vegetables), 1312,1313 (fish, selected meat), 1330,1390 (eggs)
#   411 (water), 441 (electricity-related)
#
# EXEMPT (GST Exempt Supply Order 2014):
#   Residential rent, education, healthcare, financial services, public transport
#   COICOP classes approx: 622,623 (rent/housing services), 711,712,713 (transport),
#   811-819 (health), 921,922,931 (education), 561,562 (financial services adjacent)
#
# All other Group C classes (ambiguous/mixed): retain as "control_other"

cat("\n--- Separate Zero-Rated vs Exempt Controls ---\n")

# Load class map to get group info
class_map_full <- fread("../data/class_map.csv")

# Sub-classify Group C using COICOP code knowledge
# These assignments are based on Malaysian GST Act 2014 schedules
zero_rated_classes <- c(
  # COICOP 01: Food — zero-rated staples
  "1010", "1020", "1030", "1040",        # Cereals: rice, flour, bread, noodles
  "1111", "1120",                         # Oils and fats: cooking oil, butter
  "1212", "1214",                         # Vegetables
  "1312", "1313",                         # Fish and meat (selected)
  "1321", "1322", "1329", "1330", "1390", # Eggs and other basic food
  # COICOP 04: Utilities
  "411", "441"                            # Water supply, electricity
)

exempt_classes <- c(
  # COICOP 04: Housing services (residential rent is exempt)
  "431", "432",                           # Actual/imputed rent
  # COICOP 06: Health (public healthcare is exempt)
  "611", "612", "613", "622", "623",     # Medical, hospital services
  # COICOP 07: Transport (public transport exempt, not private)
  "711", "712", "713", "721", "722",     # Passenger transport
  # COICOP 09: Education
  "921", "922", "931", "932"             # Education services
)

# Apply sub-classification within Group C
panel[, ctrl_subgroup := fcase(
  group != "C",                          "treated",
  class %in% zero_rated_classes,         "zero_rated",
  class %in% exempt_classes,             "exempt",
  default =                              "control_other"
)]

cat("Control sub-group distribution:\n")
ctrl_tab <- panel[, .(n_classes = uniqueN(class)), by = ctrl_subgroup]
print(ctrl_tab)

# Number of zero-rated and exempt classes
n_zero <- uniqueN(panel[ctrl_subgroup == "zero_rated", class])
n_exempt <- uniqueN(panel[ctrl_subgroup == "exempt", class])
n_other <- uniqueN(panel[ctrl_subgroup == "control_other", class])

cat(sprintf("\nZero-rated control classes: %d\n", n_zero))
cat(sprintf("Exempt control classes: %d\n", n_exempt))
cat(sprintf("Other control classes: %d\n", n_other))

# DiD using ONLY zero-rated controls (baseline m1 style)
if (n_zero >= 3) {
  panel_zr <- panel[group %in% c("A", "B") | ctrl_subgroup == "zero_rated"]
  m_zr <- feols(log_cpi ~ treat_post_june | class_id + date_id,
                data = panel_zr, cluster = ~class_id)

  cat("\nDiD with zero-rated controls only:\n")
  ct_zr <- coeftable(m_zr)
  cat(sprintf("  Estimate: %.4f (SE: %.4f, p: %.4f)\n",
              coef(m_zr)["treat_post_june"],
              se(m_zr)["treat_post_june"],
              ct_zr["treat_post_june", "Pr(>|t|)"]))
  cat(sprintf("  N obs: %d, N clusters: %d\n",
              m_zr$nobs, length(unique(panel_zr$class_id))))
} else {
  cat("\nInsufficient zero-rated classes for separate estimation; skipping.\n")
  m_zr <- NULL
}

# DiD using ONLY exempt controls
if (n_exempt >= 3) {
  panel_ex <- panel[group %in% c("A", "B") | ctrl_subgroup == "exempt"]
  m_ex <- feols(log_cpi ~ treat_post_june | class_id + date_id,
                data = panel_ex, cluster = ~class_id)

  cat("\nDiD with exempt controls only:\n")
  ct_ex <- coeftable(m_ex)
  cat(sprintf("  Estimate: %.4f (SE: %.4f, p: %.4f)\n",
              coef(m_ex)["treat_post_june"],
              se(m_ex)["treat_post_june"],
              ct_ex["treat_post_june", "Pr(>|t|)"]))
  cat(sprintf("  N obs: %d, N clusters: %d\n",
              m_ex$nobs, length(unique(panel_ex$class_id))))
} else {
  cat("\nInsufficient exempt classes for separate estimation; skipping.\n")
  m_ex <- NULL
}

# Compile comparison table
ctrl_comparison <- data.table(
  control_group  = c("All controls (baseline)", "Zero-rated only", "Exempt only"),
  n_control_cls  = c(uniqueN(panel[group == "C", class]), n_zero, n_exempt),
  estimate       = c(
    coef(m1)["treat_post_june"],
    if (!is.null(m_zr)) coef(m_zr)["treat_post_june"] else NA_real_,
    if (!is.null(m_ex)) coef(m_ex)["treat_post_june"] else NA_real_
  ),
  se = c(
    se(m1)["treat_post_june"],
    if (!is.null(m_zr)) se(m_zr)["treat_post_june"] else NA_real_,
    if (!is.null(m_ex)) se(m_ex)["treat_post_june"] else NA_real_
  )
)
ctrl_comparison[, `:=`(
  ci_lo = estimate - 1.96 * se,
  ci_hi = estimate + 1.96 * se
)]

cat("\nControl group comparison:\n")
print(ctrl_comparison)
fwrite(ctrl_comparison, "../data/control_group_comparison.csv")
cat("Control group comparison saved to ../data/control_group_comparison.csv\n")

# ==============================================================================
# 11. WILD CLUSTER BOOTSTRAP FOR DDD REIMPOSITION COEFFICIENT
# ==============================================================================
# Use fwildclusterboot if available; otherwise fall back to fixest's native
# cluster-robust bootstrap via boot_aggregate = TRUE in feols, or a manual
# pairs cluster bootstrap.

cat("\n--- Wild Cluster Bootstrap for DDD Reimposition Coefficient ---\n")

has_fwcb <- requireNamespace("fwildclusterboot", quietly = TRUE)
cat(sprintf("fwildclusterboot available: %s\n", has_fwcb))

if (has_fwcb) {
  library(fwildclusterboot)
  set.seed(20180901)

  boot_m3 <- boottest(
    object       = m3,
    clustid      = "class_id",
    param        = "treat_sst_post_sept",
    B            = 999,
    type         = "rademacher",
    impose_null  = TRUE
  )

  cat("\nWild cluster bootstrap results (treat_sst_post_sept):\n")
  print(boot_m3)

  wcb_result <- data.table(
    coefficient  = "treat_sst_post_sept",
    estimate     = coef(m3)["treat_sst_post_sept"],
    se_cluster   = se(m3)["treat_sst_post_sept"],
    pval_cluster = coeftable(m3)["treat_sst_post_sept", "Pr(>|t|)"],
    pval_wcb     = boot_m3$p_val,
    ci_lo_wcb    = boot_m3$conf_int[1],
    ci_hi_wcb    = boot_m3$conf_int[2],
    B            = 999,
    type         = "wild (Rademacher)"
  )

} else {
  # Fallback: pairs cluster bootstrap implemented manually
  # Resample whole clusters with replacement, re-estimate m3 B times
  cat("fwildclusterboot not installed. Running pairs cluster bootstrap (B=999).\n")

  set.seed(20180901)
  B_boot <- 999
  clusters <- unique(panel$class_id)
  n_cl     <- length(clusters)
  boot_coefs <- numeric(B_boot)

  for (b in seq_len(B_boot)) {
    if (b %% 100 == 0) cat("  Bootstrap iteration", b, "/", B_boot, "\n")
    # Sample clusters with replacement
    sampled_cls <- sample(clusters, n_cl, replace = TRUE)
    # Build bootstrapped dataset
    boot_data <- rbindlist(lapply(seq_along(sampled_cls), function(i) {
      d <- panel[class_id == sampled_cls[i]]
      d[, boot_class_id := paste0(sampled_cls[i], "_", i)]
      d
    }))
    boot_data[, boot_class_fac := as.factor(boot_class_id)]
    boot_data[, date_id_b := as.factor(date)]

    m_boot <- tryCatch(
      feols(log_cpi ~ treat_post_june + treat_sst_post_sept |
              boot_class_fac + date_id_b,
            data = boot_data, cluster = ~boot_class_fac,
            warn = FALSE, notes = FALSE),
      error = function(e) NULL
    )
    if (!is.null(m_boot) && "treat_sst_post_sept" %in% names(coef(m_boot))) {
      boot_coefs[b] <- coef(m_boot)["treat_sst_post_sept"]
    } else {
      boot_coefs[b] <- NA_real_
    }
  }

  boot_coefs_clean <- boot_coefs[!is.na(boot_coefs)]
  actual_beta2     <- coef(m3)["treat_sst_post_sept"]

  # Percentile CI
  ci_lo_pairs <- quantile(boot_coefs_clean, 0.025)
  ci_hi_pairs <- quantile(boot_coefs_clean, 0.975)

  # Bootstrap p-value (two-sided, null-imposed by centering)
  centered   <- boot_coefs_clean - mean(boot_coefs_clean)
  pval_pairs <- mean(abs(centered) >= abs(actual_beta2 - mean(boot_coefs_clean)))

  cat(sprintf("\nPairs cluster bootstrap (B=%d valid):\n", length(boot_coefs_clean)))
  cat(sprintf("  Original estimate: %.4f\n", actual_beta2))
  cat(sprintf("  Bootstrap mean:    %.4f\n", mean(boot_coefs_clean)))
  cat(sprintf("  Bootstrap SE:      %.4f\n", sd(boot_coefs_clean)))
  cat(sprintf("  95%% percentile CI: [%.4f, %.4f]\n", ci_lo_pairs, ci_hi_pairs))
  cat(sprintf("  Bootstrap p-value: %.4f\n", pval_pairs))

  wcb_result <- data.table(
    coefficient  = "treat_sst_post_sept",
    estimate     = actual_beta2,
    se_cluster   = se(m3)["treat_sst_post_sept"],
    pval_cluster = coeftable(m3)["treat_sst_post_sept", "Pr(>|t|)"],
    boot_mean    = mean(boot_coefs_clean),
    boot_se      = sd(boot_coefs_clean),
    pval_boot    = pval_pairs,
    ci_lo_boot   = ci_lo_pairs,
    ci_hi_boot   = ci_hi_pairs,
    B_valid      = length(boot_coefs_clean),
    B_total      = B_boot,
    type         = "pairs cluster bootstrap"
  )

  # Save the full bootstrap distribution
  boot_dist_dt <- data.table(
    iteration = seq_len(B_boot),
    coef      = boot_coefs
  )
  fwrite(boot_dist_dt, "../data/bootstrap_distribution.csv")
  cat("Bootstrap distribution saved to ../data/bootstrap_distribution.csv\n")
}

fwrite(wcb_result, "../data/wild_cluster_bootstrap.csv")
cat("Bootstrap results saved to ../data/wild_cluster_bootstrap.csv\n")

# ==============================================================================
# SAVE UPDATED ROBUSTNESS MODELS
# ==============================================================================

save(placebo_2015, placebo_2016, placebo_2017,
     m_short, m_med, m_precovid, m_post_gst_intro,
     m_gst_intro, m_2d,
     file = "../data/robustness_models.RData")

cat("\n=== Robustness checks complete ===\n")
