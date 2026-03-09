## 04_robustness.R — Robustness checks and sensitivity analysis
## apep_0561: ZRR reclassification and RN voting in France
##
## Checks:
##   1. Leave-one-department-out (geographic sensitivity)
##   2. Heterogeneity by commune size (median split on inscrits)
##   3. Heterogeneity by prior RN support (median split on 2012 FN/RN share)
##   4. Placebo cutoff test (fake treatment at 2012, purely pre-reform sample)
##   4b. Drop 2002 election year (addresses atypical Le Pen qualification)
##   5. HonestDiD sensitivity analysis (Rambachan-Roth bounds)

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 0) Load Data
# ============================================================
cat("=== Loading DiD sample ===\n")

did_dt <- fread(file.path(data_dir, "did_sample.csv"))

# Ensure proper types
did_dt[, commune_code := as.factor(commune_code)]
did_dt[, year := as.integer(year)]

cat("DiD sample:", nrow(did_dt), "obs,",
    length(unique(did_dt$commune_code)), "communes,",
    length(unique(did_dt$year)), "election years\n")
cat("Election years:", paste(sort(unique(did_dt$year)), collapse = ", "), "\n")
cat("Treatment groups:", paste(unique(did_dt$treatment_group), collapse = ", "), "\n\n")

# Reproduce main result for reference
cat("--- Reproducing main DiD for reference ---\n")
m_main <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                data = did_dt, cluster = ~commune_code)
main_coef <- coeftable(m_main)
cat(sprintf("Main ATT: %.3f pp (SE = %.3f, p = %.4f)\n\n",
            main_coef[1, "Estimate"], main_coef[1, "Std. Error"],
            main_coef[1, "Pr(>|t|)"]))


# ============================================================
# 1) Leave-One-Department-Out
# ============================================================
cat("\n")
cat("================================================================\n")
cat("  1. LEAVE-ONE-DEPARTMENT-OUT\n")
cat("================================================================\n\n")

# Extract department code (first 2 characters of commune_code)
# Handle Corsica (2A, 2B) and overseas departments (97X)
did_dt[, dept_code := substr(as.character(commune_code), 1, 2)]
# For overseas departments with 3-digit codes, use first 3 chars
did_dt[substr(as.character(commune_code), 1, 2) == "97",
       dept_code := substr(as.character(commune_code), 1, 3)]

departments <- sort(unique(did_dt$dept_code))
n_depts <- length(departments)
cat("Number of departments in sample:", n_depts, "\n")
cat("Departments:", paste(departments, collapse = ", "), "\n\n")

# Run DiD dropping each department
lodo_results <- list()

for (i in seq_along(departments)) {
  d <- departments[i]
  sub <- did_dt[dept_code != d]

  n_communes_dropped <- length(unique(did_dt[dept_code == d]$commune_code))
  n_communes_remain <- length(unique(sub$commune_code))

  m_lodo <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                  data = sub, cluster = ~commune_code)
  ct <- coeftable(m_lodo)

  lodo_results[[i]] <- data.table(
    dept_dropped = d,
    n_communes_dropped = n_communes_dropped,
    n_communes_remaining = n_communes_remain,
    n_obs = nobs(m_lodo),
    coef = ct[1, "Estimate"],
    se = ct[1, "Std. Error"],
    t_stat = ct[1, "t value"],
    p_value = ct[1, "Pr(>|t|)"]
  )
}

lodo_dt <- rbindlist(lodo_results)
lodo_dt[, ci_lower := coef - 1.96 * se]
lodo_dt[, ci_upper := coef + 1.96 * se]
lodo_dt[, significant_05 := p_value < 0.05]

# Summary statistics
cat("Leave-one-department-out results:\n")
cat(sprintf("  ATT range: [%.3f, %.3f]\n", min(lodo_dt$coef), max(lodo_dt$coef)))
cat(sprintf("  Main ATT: %.3f\n", main_coef[1, "Estimate"]))
cat(sprintf("  Mean LODO ATT: %.3f\n", mean(lodo_dt$coef)))
cat(sprintf("  SD of LODO ATTs: %.3f\n", sd(lodo_dt$coef)))
cat(sprintf("  Proportion significant at 5%%: %.1f%% (%d/%d)\n",
            100 * mean(lodo_dt$significant_05), sum(lodo_dt$significant_05), n_depts))

# Flag any department whose removal changes sign or significance
sign_changers <- lodo_dt[sign(coef) != sign(main_coef[1, "Estimate"])]
if (nrow(sign_changers) > 0) {
  cat("\n  WARNING: Dropping the following departments CHANGES the sign:\n")
  print(sign_changers[, .(dept_dropped, coef = round(coef, 3),
                           se = round(se, 3), p_value = round(p_value, 4))])
} else {
  cat("\n  No department changes the sign of the ATT when dropped.\n")
}

sig_changers <- lodo_dt[significant_05 == FALSE]
if (nrow(sig_changers) > 0) {
  cat("\n  Dropping these departments renders the ATT insignificant at 5%:\n")
  print(sig_changers[, .(dept_dropped, coef = round(coef, 3),
                          se = round(se, 3), p_value = round(p_value, 4),
                          n_communes_dropped)])
} else {
  cat("  Result is significant at 5% regardless of which department is dropped.\n")
}

# Identify most influential departments
lodo_dt[, coef_deviation := abs(coef - main_coef[1, "Estimate"])]
setorder(lodo_dt, -coef_deviation)
cat("\n  Top 5 most influential departments (largest deviation from main ATT):\n")
print(lodo_dt[1:min(5, nrow(lodo_dt)),
              .(dept_dropped, coef = round(coef, 3),
                deviation = round(coef_deviation, 3),
                n_communes_dropped)])

fwrite(lodo_dt, file.path(data_dir, "robustness_lodo.csv"))
cat("\nSaved: robustness_lodo.csv\n")


# ============================================================
# 2) Heterogeneity by Commune Size
# ============================================================
cat("\n")
cat("================================================================\n")
cat("  2. HETEROGENEITY BY COMMUNE SIZE\n")
cat("================================================================\n\n")

# Compute median registered voters in 2012 (last clean pre-treatment year)
pre_2012 <- did_dt[year == 2012]
median_inscrits <- median(pre_2012$inscrits, na.rm = TRUE)
cat(sprintf("Median registered voters in 2012: %.0f\n", median_inscrits))

# Classify communes as small or large based on 2012 size
size_class <- pre_2012[, .(commune_code,
                           size_group = ifelse(inscrits <= median_inscrits,
                                               "small", "large"))]

# Merge back to full panel (commune classification is time-invariant)
did_size <- merge(did_dt, size_class[, .(commune_code, size_group)],
                  by = "commune_code", all.x = TRUE)

# Drop communes with no 2012 observation (cannot classify)
n_missing <- sum(is.na(did_size$size_group))
if (n_missing > 0) {
  cat(sprintf("  Dropping %d obs with no 2012 size classification\n", n_missing))
  did_size <- did_size[!is.na(size_group)]
}

cat(sprintf("Small communes (inscrits <= %.0f): %d communes\n",
            median_inscrits,
            length(unique(did_size[size_group == "small"]$commune_code))))
cat(sprintf("Large communes (inscrits > %.0f): %d communes\n",
            median_inscrits,
            length(unique(did_size[size_group == "large"]$commune_code))))

# Run DiD separately for each size group
cat("\n--- Small communes ---\n")
m_small <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                 data = did_size[size_group == "small"],
                 cluster = ~commune_code)
small_coef <- coeftable(m_small)
cat(sprintf("ATT (small): %.3f pp (SE = %.3f, p = %.4f), N = %d\n",
            small_coef[1, "Estimate"], small_coef[1, "Std. Error"],
            small_coef[1, "Pr(>|t|)"], nobs(m_small)))

cat("\n--- Large communes ---\n")
m_large <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                 data = did_size[size_group == "large"],
                 cluster = ~commune_code)
large_coef <- coeftable(m_large)
cat(sprintf("ATT (large): %.3f pp (SE = %.3f, p = %.4f), N = %d\n",
            large_coef[1, "Estimate"], large_coef[1, "Std. Error"],
            large_coef[1, "Pr(>|t|)"], nobs(m_large)))

# Formal interaction test: is the difference significant?
cat("\n--- Interaction test (size x treatment) ---\n")
did_size[, large := as.integer(size_group == "large")]
m_interact_size <- feols(fn_rn_pct_exprimes ~ treated:post + treated:post:large |
                           commune_code + year,
                         data = did_size, cluster = ~commune_code)
int_size_coef <- coeftable(m_interact_size)
cat("Interaction model:\n")
summary(m_interact_size)

# Extract and clearly report the interaction term p-value
if (nrow(int_size_coef) >= 2) {
  size_interact_est <- int_size_coef[2, "Estimate"]
  size_interact_se <- int_size_coef[2, "Std. Error"]
  size_interact_t <- int_size_coef[2, "t value"]
  size_interact_p <- int_size_coef[2, "Pr(>|t|)"]
  cat(sprintf("\n*** Interaction term (large x treated x post): %.3f (SE = %.3f, t = %.3f, p = %.4f)\n",
              size_interact_est, size_interact_se, size_interact_t, size_interact_p))
  if (size_interact_p < 0.05) {
    cat("    => Subgroup difference IS statistically significant at 5%.\n")
  } else if (size_interact_p < 0.10) {
    cat("    => Subgroup difference is marginally significant (p < 0.10).\n")
  } else {
    cat("    => Subgroup difference is NOT statistically significant.\n")
  }
} else {
  size_interact_est <- NA
  size_interact_se <- NA
  size_interact_t <- NA
  size_interact_p <- NA
  cat("\n  WARNING: Could not extract interaction term.\n")
}

# Collect size heterogeneity results
size_het_results <- data.table(
  subgroup = c("Small communes", "Large communes", "Full sample (reference)",
               "Interaction (large x treat x post)"),
  median_cutoff = c(median_inscrits, median_inscrits, NA, NA),
  coef = c(small_coef[1, "Estimate"], large_coef[1, "Estimate"],
           main_coef[1, "Estimate"], size_interact_est),
  se = c(small_coef[1, "Std. Error"], large_coef[1, "Std. Error"],
         main_coef[1, "Std. Error"], size_interact_se),
  t_stat = c(small_coef[1, "t value"], large_coef[1, "t value"],
             main_coef[1, "t value"], size_interact_t),
  p_value = c(small_coef[1, "Pr(>|t|)"], large_coef[1, "Pr(>|t|)"],
              main_coef[1, "Pr(>|t|)"], size_interact_p),
  n_obs = c(nobs(m_small), nobs(m_large), nobs(m_main),
            nobs(m_interact_size)),
  n_communes = c(length(unique(did_size[size_group == "small"]$commune_code)),
                 length(unique(did_size[size_group == "large"]$commune_code)),
                 length(unique(did_dt$commune_code)),
                 length(unique(did_size$commune_code)))
)

fwrite(size_het_results, file.path(data_dir, "robustness_size_heterogeneity.csv"))
cat("\nSaved: robustness_size_heterogeneity.csv\n")


# ============================================================
# 3) Heterogeneity by Prior RN Support
# ============================================================
cat("\n")
cat("================================================================\n")
cat("  3. HETEROGENEITY BY PRIOR RN SUPPORT\n")
cat("================================================================\n\n")

# Use 2012 FN/RN share as the baseline
fn_2012 <- pre_2012[, .(commune_code, fn_2012 = fn_rn_pct_exprimes)]
median_fn <- median(fn_2012$fn_2012, na.rm = TRUE)
cat(sprintf("Median FN/RN share in 2012: %.2f%%\n", median_fn))

# Classify communes
fn_class <- fn_2012[, .(commune_code,
                        fn_group = ifelse(fn_2012 <= median_fn,
                                          "low_fn", "high_fn"))]

did_fn <- merge(did_dt, fn_class[, .(commune_code, fn_group)],
                by = "commune_code", all.x = TRUE)

# Drop communes with no 2012 FN data
n_missing_fn <- sum(is.na(did_fn$fn_group))
if (n_missing_fn > 0) {
  cat(sprintf("  Dropping %d obs with no 2012 FN classification\n", n_missing_fn))
  did_fn <- did_fn[!is.na(fn_group)]
}

cat(sprintf("Low-FN communes (FN share <= %.2f%%): %d communes\n",
            median_fn,
            length(unique(did_fn[fn_group == "low_fn"]$commune_code))))
cat(sprintf("High-FN communes (FN share > %.2f%%): %d communes\n",
            median_fn,
            length(unique(did_fn[fn_group == "high_fn"]$commune_code))))

# Run DiD separately
cat("\n--- Low prior FN support ---\n")
m_low_fn <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                  data = did_fn[fn_group == "low_fn"],
                  cluster = ~commune_code)
low_fn_coef <- coeftable(m_low_fn)
cat(sprintf("ATT (low FN): %.3f pp (SE = %.3f, p = %.4f), N = %d\n",
            low_fn_coef[1, "Estimate"], low_fn_coef[1, "Std. Error"],
            low_fn_coef[1, "Pr(>|t|)"], nobs(m_low_fn)))

cat("\n--- High prior FN support ---\n")
m_high_fn <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                   data = did_fn[fn_group == "high_fn"],
                   cluster = ~commune_code)
high_fn_coef <- coeftable(m_high_fn)
cat(sprintf("ATT (high FN): %.3f pp (SE = %.3f, p = %.4f), N = %d\n",
            high_fn_coef[1, "Estimate"], high_fn_coef[1, "Std. Error"],
            high_fn_coef[1, "Pr(>|t|)"], nobs(m_high_fn)))

# Formal interaction test
cat("\n--- Interaction test (prior FN x treatment) ---\n")
did_fn[, high_fn := as.integer(fn_group == "high_fn")]
m_interact_fn <- feols(fn_rn_pct_exprimes ~ treated:post + treated:post:high_fn |
                         commune_code + year,
                       data = did_fn, cluster = ~commune_code)
int_fn_coef <- coeftable(m_interact_fn)
cat("Interaction model:\n")
summary(m_interact_fn)

# Extract and clearly report the interaction term p-value
if (nrow(int_fn_coef) >= 2) {
  fn_interact_est <- int_fn_coef[2, "Estimate"]
  fn_interact_se <- int_fn_coef[2, "Std. Error"]
  fn_interact_t <- int_fn_coef[2, "t value"]
  fn_interact_p <- int_fn_coef[2, "Pr(>|t|)"]
  cat(sprintf("\n*** Interaction term (high_fn x treated x post): %.3f (SE = %.3f, t = %.3f, p = %.4f)\n",
              fn_interact_est, fn_interact_se, fn_interact_t, fn_interact_p))
  if (fn_interact_p < 0.05) {
    cat("    => Subgroup difference IS statistically significant at 5%.\n")
  } else if (fn_interact_p < 0.10) {
    cat("    => Subgroup difference is marginally significant (p < 0.10).\n")
  } else {
    cat("    => Subgroup difference is NOT statistically significant.\n")
  }
} else {
  fn_interact_est <- NA
  fn_interact_se <- NA
  fn_interact_t <- NA
  fn_interact_p <- NA
  cat("\n  WARNING: Could not extract interaction term.\n")
}

# Collect FN heterogeneity results
fn_het_results <- data.table(
  subgroup = c("Low prior FN", "High prior FN", "Full sample (reference)",
               "Interaction (high_fn x treat x post)"),
  median_cutoff = c(median_fn, median_fn, NA, NA),
  coef = c(low_fn_coef[1, "Estimate"], high_fn_coef[1, "Estimate"],
           main_coef[1, "Estimate"], fn_interact_est),
  se = c(low_fn_coef[1, "Std. Error"], high_fn_coef[1, "Std. Error"],
         main_coef[1, "Std. Error"], fn_interact_se),
  t_stat = c(low_fn_coef[1, "t value"], high_fn_coef[1, "t value"],
             main_coef[1, "t value"], fn_interact_t),
  p_value = c(low_fn_coef[1, "Pr(>|t|)"], high_fn_coef[1, "Pr(>|t|)"],
              main_coef[1, "Pr(>|t|)"], fn_interact_p),
  n_obs = c(nobs(m_low_fn), nobs(m_high_fn), nobs(m_main),
            nobs(m_interact_fn)),
  n_communes = c(length(unique(did_fn[fn_group == "low_fn"]$commune_code)),
                 length(unique(did_fn[fn_group == "high_fn"]$commune_code)),
                 length(unique(did_dt$commune_code)),
                 length(unique(did_fn$commune_code)))
)

fwrite(fn_het_results, file.path(data_dir, "robustness_fn_heterogeneity.csv"))
cat("\nSaved: robustness_fn_heterogeneity.csv\n")


# ============================================================
# 4) Placebo Cutoff Test
# ============================================================
cat("\n")
cat("================================================================\n")
cat("  4. PLACEBO CUTOFF TEST\n")
cat("================================================================\n\n")

# The real treatment occurs between 2017 and 2022 (ZRR reform enacted 2015,
# effective ~2017). Placebo test: pretend treatment happened in 2012.
# Use only truly pre-treatment data (years < 2017, i.e., 2002, 2007, 2012)
# with placebo_post = (year >= 2012). This ensures the placebo is entirely
# before any reform announcement or anticipation effects.

cat("Placebo design:\n")
cat("  Real treatment timing: ZRR reform effective ~2017, post = 2022\n")
cat("  Placebo treatment: pretend treatment happened at 2012\n")
cat("  Sample: use only pre-reform years (< 2017): 2002, 2007, 2012\n")
cat("  Placebo post indicator: year >= 2012\n\n")

# Restrict to truly pre-treatment observations only (before any reform)
placebo_dt <- did_dt[year < 2017]
placebo_dt[, placebo_post := as.integer(year >= 2012)]

cat("Placebo sample years:", paste(sort(unique(placebo_dt$year)), collapse = ", "), "\n")
cat("Placebo sample size:", nrow(placebo_dt), "obs\n")
cat("Pre-placebo years (placebo_post=0):",
    paste(sort(unique(placebo_dt[placebo_post == 0]$year)), collapse = ", "), "\n")
cat("Post-placebo years (placebo_post=1):",
    paste(sort(unique(placebo_dt[placebo_post == 1]$year)), collapse = ", "), "\n\n")

# Run placebo DiD
cat("--- Placebo DiD ---\n")
m_placebo <- feols(fn_rn_pct_exprimes ~ treated:placebo_post | commune_code + year,
                   data = placebo_dt, cluster = ~commune_code)
placebo_coef <- coeftable(m_placebo)
summary(m_placebo)

cat(sprintf("\nPlacebo ATT: %.3f pp (SE = %.3f, t = %.3f, p = %.4f)\n",
            placebo_coef[1, "Estimate"], placebo_coef[1, "Std. Error"],
            placebo_coef[1, "t value"], placebo_coef[1, "Pr(>|t|)"]))

if (placebo_coef[1, "Pr(>|t|)"] >= 0.05) {
  cat("  PASS: Placebo ATT is NOT significant at 5% — consistent with valid design.\n")
} else {
  cat("  WARNING: Placebo ATT IS significant at 5% — potential pre-trend concern.\n")
}

cat(sprintf("\n  Comparison: Main ATT = %.3f (p = %.4f) vs Placebo ATT = %.3f (p = %.4f)\n",
            main_coef[1, "Estimate"], main_coef[1, "Pr(>|t|)"],
            placebo_coef[1, "Estimate"], placebo_coef[1, "Pr(>|t|)"]))

# Collect placebo results
placebo_results <- data.table(
  test = c("Main DiD (real)", "Placebo (fake 2012 treatment)"),
  coef = c(main_coef[1, "Estimate"], placebo_coef[1, "Estimate"]),
  se = c(main_coef[1, "Std. Error"], placebo_coef[1, "Std. Error"]),
  t_stat = c(main_coef[1, "t value"], placebo_coef[1, "t value"]),
  p_value = c(main_coef[1, "Pr(>|t|)"], placebo_coef[1, "Pr(>|t|)"]),
  n_obs = c(nobs(m_main), nobs(m_placebo)),
  significant_05 = c(main_coef[1, "Pr(>|t|)"] < 0.05,
                     placebo_coef[1, "Pr(>|t|)"] < 0.05)
)

fwrite(placebo_results, file.path(data_dir, "robustness_placebo.csv"))
cat("\nSaved: robustness_placebo.csv\n")


# ============================================================
# 4b) Drop 2002 Election Year
# ============================================================
cat("\n")
cat("================================================================\n")
cat("  4b. DROP 2002 ELECTION YEAR\n")
cat("================================================================\n\n")

cat("The 2002 election may show a significant pre-treatment coefficient\n")
cat("(Le Pen's surprise qualification for the second round created an\n")
cat("unusual nationwide spike in FN voting). Dropping 2002 tests whether\n")
cat("the main result is driven by that atypical election.\n\n")

# Filter out 2002
did_no2002 <- did_dt[year != 2002]

cat("Original sample years:", paste(sort(unique(did_dt$year)), collapse = ", "), "\n")
cat("Drop-2002 sample years:", paste(sort(unique(did_no2002$year)), collapse = ", "), "\n")
cat(sprintf("Observations: %d -> %d (dropped %d)\n",
            nrow(did_dt), nrow(did_no2002), nrow(did_dt) - nrow(did_no2002)))
cat(sprintf("Communes: %d\n\n", length(unique(did_no2002$commune_code))))

# Run baseline DiD without 2002
m_no2002 <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                  data = did_no2002, cluster = ~commune_code)
no2002_coef <- coeftable(m_no2002)

cat("--- DiD dropping 2002 ---\n")
summary(m_no2002)
cat(sprintf("\nATT (drop 2002): %.3f pp (SE = %.3f, t = %.3f, p = %.4f), N = %d\n",
            no2002_coef[1, "Estimate"], no2002_coef[1, "Std. Error"],
            no2002_coef[1, "t value"], no2002_coef[1, "Pr(>|t|)"],
            nobs(m_no2002)))

cat(sprintf("\nComparison with main result:\n"))
cat(sprintf("  Main ATT:       %.3f (SE = %.3f, p = %.4f, N = %d)\n",
            main_coef[1, "Estimate"], main_coef[1, "Std. Error"],
            main_coef[1, "Pr(>|t|)"], nobs(m_main)))
cat(sprintf("  Drop-2002 ATT:  %.3f (SE = %.3f, p = %.4f, N = %d)\n",
            no2002_coef[1, "Estimate"], no2002_coef[1, "Std. Error"],
            no2002_coef[1, "Pr(>|t|)"], nobs(m_no2002)))

# Save results
drop2002_results <- data.table(
  model = "DiD dropping 2002",
  coef = no2002_coef[1, "Estimate"],
  se = no2002_coef[1, "Std. Error"],
  t_stat = no2002_coef[1, "t value"],
  p_value = no2002_coef[1, "Pr(>|t|)"],
  n_obs = nobs(m_no2002)
)

fwrite(drop2002_results, file.path(data_dir, "robustness_drop2002.csv"))
cat("\nSaved: robustness_drop2002.csv\n")


# ============================================================
# 5) HonestDiD Sensitivity Analysis
# ============================================================
cat("\n")
cat("================================================================\n")
cat("  5. HONESTDID SENSITIVITY ANALYSIS\n")
cat("================================================================\n\n")

cat("Applying Rambachan and Roth (2023) sensitivity analysis.\n")
cat("This tests: how much would parallel trends need to be violated\n")
cat("for the treatment effect to become zero (or change sign)?\n\n")

# Re-estimate event study with fixest for HonestDiD compatibility
# HonestDiD needs: coefficient vector, variance-covariance matrix,
# and identification of which coefficients are pre vs post treatment.

# Event study: year x treated interactions, 2012 omitted (matching main analysis)
es_model <- feols(fn_rn_pct_exprimes ~ i(year, treated, ref = 2012) |
                    commune_code + year,
                  data = did_dt, cluster = ~commune_code)

cat("Event study model for HonestDiD:\n")
es_coefs_table <- coeftable(es_model)
cat("Coefficients:\n")
print(es_coefs_table)

# Extract coefficient vector and variance-covariance matrix
beta_hat <- coef(es_model)
sigma_hat <- vcov(es_model)

cat("\nCoefficient names:", paste(names(beta_hat), collapse = ", "), "\n")

# Identify pre-treatment and post-treatment periods
# With ref=2012: pre-treatment coefficients are 2002, 2007
# Post-treatment (including anticipation): 2017, 2022
coef_years <- as.integer(gsub("year::(\\d+):treated", "\\1", names(beta_hat)))
pre_indices <- which(coef_years < 2012)
post_indices <- which(coef_years >= 2017)

cat(sprintf("Pre-treatment periods: %d (years: %s)\n",
            length(pre_indices),
            paste(coef_years[pre_indices], collapse = ", ")))
cat(sprintf("Post-treatment periods: %d (years: %s)\n",
            length(post_indices),
            paste(coef_years[post_indices], collapse = ", ")))

# Apply HonestDiD
# Method: relative magnitudes (Delta^RM) — bounds on how much the post-treatment
# trend violation can differ from the max pre-treatment violation
honest_results <- tryCatch({

  # Construct the l_vec to identify the post-treatment coefficient of interest
  # We want the causal effect at the first post-treatment period
  numPrePeriods <- length(pre_indices)
  numPostPeriods <- length(post_indices)

  cat(sprintf("\nHonestDiD inputs: %d pre-periods, %d post-periods\n",
              numPrePeriods, numPostPeriods))

  # --- Method 1: Relative Magnitudes (Delta^RM) ---
  cat("\n--- Relative Magnitudes (Delta^RM) approach ---\n")
  cat("M-bar values: maximum ratio of post-treatment to pre-treatment trend violations\n\n")

  # createSensitivityResults from HonestDiD
  # Mbar = max ratio of post to pre violation
  rm_results <- HonestDiD::createSensitivityResults(
    betahat = beta_hat,
    sigma = sigma_hat,
    numPrePeriods = numPrePeriods,
    numPostPeriods = numPostPeriods,
    Mvec = seq(0, 2, by = 0.5),
    l_vec = basisVector(index = 1, size = numPostPeriods)
  )

  cat("Relative Magnitudes sensitivity results:\n")
  print(rm_results)

  # --- Method 2: Smoothness (Delta^SD) ---
  cat("\n--- Smoothness (Delta^SD) approach ---\n")
  cat("M values: bound on second differences of the bias\n\n")

  # For the smoothness restriction, we bound the second differences
  sd_results <- tryCatch({
    HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = numPrePeriods,
      numPostPeriods = numPostPeriods,
      Mvec = seq(0, 0.05, by = 0.01),
      l_vec = basisVector(index = 1, size = numPostPeriods),
      method = "FLCI"
    )
  }, error = function(e) {
    cat("Smoothness approach failed:", conditionMessage(e), "\n")
    cat("Continuing with relative magnitudes results only.\n")
    NULL
  })

  if (!is.null(sd_results)) {
    cat("Smoothness sensitivity results:\n")
    print(sd_results)
  }

  # --- Original confidence set (no violations assumed) ---
  cat("\n--- Original (no violations, M-bar = 0) ---\n")
  orig <- HonestDiD::createSensitivityResults(
    betahat = beta_hat,
    sigma = sigma_hat,
    numPrePeriods = numPrePeriods,
    numPostPeriods = numPostPeriods,
    Mvec = 0,
    l_vec = basisVector(index = 1, size = numPostPeriods)
  )
  cat(sprintf("Original robust CI: [%.3f, %.3f]\n", orig$lb[1], orig$ub[1]))

  # Find breakdown value: smallest M-bar at which CI includes zero
  cat("\n--- Breakdown analysis ---\n")
  m_grid <- seq(0, 5, by = 0.1)
  breakdown_results <- HonestDiD::createSensitivityResults(
    betahat = beta_hat,
    sigma = sigma_hat,
    numPrePeriods = numPrePeriods,
    numPostPeriods = numPostPeriods,
    Mvec = m_grid,
    l_vec = basisVector(index = 1, size = numPostPeriods)
  )

  # Find first M-bar where CI includes zero
  includes_zero <- (breakdown_results$lb <= 0 & breakdown_results$ub >= 0)
  if (any(includes_zero)) {
    breakdown_m <- m_grid[which(includes_zero)[1]]
    cat(sprintf("Breakdown value (M-bar): %.1f\n", breakdown_m))
    cat("  At this M-bar, the confidence interval first includes zero.\n")
    cat(sprintf("  Interpretation: parallel trends violations would need to be\n"))
    cat(sprintf("  %.1fx the max pre-treatment violation to overturn the result.\n",
                breakdown_m))
  } else {
    breakdown_m <- NA
    cat("Result survives all M-bar values tested (up to 5.0).\n")
    cat("The treatment effect is highly robust to parallel trends violations.\n")
  }

  list(rm = rm_results, sd = sd_results, breakdown = breakdown_results,
       breakdown_m = breakdown_m)

}, error = function(e) {
  cat("\nHonestDiD analysis failed:", conditionMessage(e), "\n")
  cat("This may occur if the event study has too few pre-periods\n")
  cat("or the variance-covariance matrix is singular.\n\n")

  # Provide manual sensitivity check as fallback
  cat("--- Fallback: Manual pre-trend magnitude check ---\n")
  pre_coefs <- beta_hat[pre_indices]
  max_pre_violation <- max(abs(pre_coefs))
  post_coef_val <- beta_hat[post_indices[1]]

  cat(sprintf("Max pre-treatment |coefficient|: %.3f\n", max_pre_violation))
  cat(sprintf("Post-treatment coefficient: %.3f\n", post_coef_val))
  if (max_pre_violation > 0) {
    cat(sprintf("Ratio |post/max_pre|: %.2f\n",
                abs(post_coef_val) / max_pre_violation))
    cat("If this ratio >> 1, the effect is large relative to pre-trends.\n")
  }

  NULL
})

# Save HonestDiD results
if (!is.null(honest_results)) {
  # Save relative magnitudes results
  rm_save <- as.data.table(honest_results$rm)
  fwrite(rm_save, file.path(data_dir, "robustness_honestdid_rm.csv"))

  # Save breakdown analysis
  bd_save <- as.data.table(honest_results$breakdown)
  bd_save[, Mbar := seq(0, 5, by = 0.1)[seq_len(nrow(bd_save))]]
  fwrite(bd_save, file.path(data_dir, "robustness_honestdid_breakdown.csv"))

  if (!is.null(honest_results$sd)) {
    sd_save <- as.data.table(honest_results$sd)
    fwrite(sd_save, file.path(data_dir, "robustness_honestdid_sd.csv"))
  }

  cat("\nSaved: robustness_honestdid_rm.csv, robustness_honestdid_breakdown.csv\n")
  if (!is.null(honest_results$sd)) {
    cat("Saved: robustness_honestdid_sd.csv\n")
  }
} else {
  cat("HonestDiD results not saved (analysis failed).\n")
}


# ============================================================
# 6) Assignment-Unit Clustering (EPCI and Department Level)
# ============================================================
cat("\n")
cat("================================================================\n")
cat("  6. ASSIGNMENT-UNIT CLUSTERING\n")
cat("================================================================\n\n")

cat("Treatment is assigned at the EPCI level (density threshold).\n")
cat("Commune-level clustering may understate SEs if residuals correlate within EPCIs.\n")
cat("We cluster at department level as a conservative alternative.\n\n")

# Department-level clustering
cat("--- Department-level clustering ---\n")
m_dept <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                data = did_dt, cluster = ~dept_code)
dept_coef <- coeftable(m_dept)
cat(sprintf("ATT = %.3f pp (SE = %.3f, t = %.3f, p = %.4f)\n",
            dept_coef[1, "Estimate"], dept_coef[1, "Std. Error"],
            dept_coef[1, "t value"], dept_coef[1, "Pr(>|t|)"]))
cat(sprintf("  Compare: commune SE = %.3f, department SE = %.3f\n",
            main_coef[1, "Std. Error"], dept_coef[1, "Std. Error"]))

# If EPCI crosswalk is available, use it
epci_file <- file.path(data_dir, "epci_crosswalk.csv")
if (file.exists(epci_file)) {
  cat("\n--- EPCI-level clustering ---\n")
  epci_xwalk <- fread(epci_file)

  # Merge EPCI codes to did_dt
  did_dt_epci <- merge(did_dt, epci_xwalk[, .(commune_code, epci_code)],
                        by = "commune_code", all.x = TRUE)

  # Report merge rate
  n_matched <- sum(!is.na(did_dt_epci$epci_code))
  n_total <- nrow(did_dt_epci)
  cat(sprintf("EPCI merge: %d/%d obs matched (%.1f%%)\n",
              n_matched, n_total, 100 * n_matched / n_total))

  if (n_matched > 0.8 * n_total) {
    m_epci <- feols(fn_rn_pct_exprimes ~ treated:post | commune_code + year,
                    data = did_dt_epci[!is.na(epci_code)],
                    cluster = ~epci_code)
    epci_coef <- coeftable(m_epci)
    cat(sprintf("ATT = %.3f pp (SE = %.3f, t = %.3f, p = %.4f)\n",
                epci_coef[1, "Estimate"], epci_coef[1, "Std. Error"],
                epci_coef[1, "t value"], epci_coef[1, "Pr(>|t|)"]))
    cat(sprintf("Number of EPCI clusters: %d\n",
                length(unique(did_dt_epci[!is.na(epci_code)]$epci_code))))

    # Save comparison
    cluster_comp <- data.table(
      cluster_level = c("commune", "department", "epci"),
      coef = c(main_coef[1, "Estimate"], dept_coef[1, "Estimate"], epci_coef[1, "Estimate"]),
      se = c(main_coef[1, "Std. Error"], dept_coef[1, "Std. Error"], epci_coef[1, "Std. Error"]),
      t_stat = c(main_coef[1, "t value"], dept_coef[1, "t value"], epci_coef[1, "t value"]),
      p_value = c(main_coef[1, "Pr(>|t|)"], dept_coef[1, "Pr(>|t|)"], epci_coef[1, "Pr(>|t|)"]),
      n_obs = c(nobs(m_main), nobs(m_dept), nobs(m_epci)),
      n_clusters = c(length(unique(did_dt$commune_code)),
                     length(unique(did_dt$dept_code)),
                     length(unique(did_dt_epci[!is.na(epci_code)]$epci_code)))
    )
  } else {
    cat("  EPCI merge rate too low — falling back to department clustering only.\n")
    cluster_comp <- data.table(
      cluster_level = c("commune", "department"),
      coef = c(main_coef[1, "Estimate"], dept_coef[1, "Estimate"]),
      se = c(main_coef[1, "Std. Error"], dept_coef[1, "Std. Error"]),
      t_stat = c(main_coef[1, "t value"], dept_coef[1, "t value"]),
      p_value = c(main_coef[1, "Pr(>|t|)"], dept_coef[1, "Pr(>|t|)"]),
      n_obs = c(nobs(m_main), nobs(m_dept)),
      n_clusters = c(length(unique(did_dt$commune_code)),
                     length(unique(did_dt$dept_code)))
    )
  }
} else {
  cat("\n  EPCI crosswalk not available — using department clustering only.\n")
  cluster_comp <- data.table(
    cluster_level = c("commune", "department"),
    coef = c(main_coef[1, "Estimate"], dept_coef[1, "Estimate"]),
    se = c(main_coef[1, "Std. Error"], dept_coef[1, "Std. Error"]),
    t_stat = c(main_coef[1, "t value"], dept_coef[1, "t value"]),
    p_value = c(main_coef[1, "Pr(>|t|)"], dept_coef[1, "Pr(>|t|)"]),
    n_obs = c(nobs(m_main), nobs(m_dept)),
    n_clusters = c(length(unique(did_dt$commune_code)),
                   length(unique(did_dt$dept_code)))
  )
}

fwrite(cluster_comp, file.path(data_dir, "epci_cluster_comparison.csv"))
cat("\nSaved: epci_cluster_comparison.csv\n")

# Print comparison
cat("\n--- Clustering comparison ---\n")
print(cluster_comp[, .(cluster_level, coef = round(coef, 3),
                        se = round(se, 3), p_value = round(p_value, 4),
                        n_clusters)])


# ============================================================
# 7) Final Robustness Summary
# ============================================================
cat("\n\n")
cat("================================================================\n")
cat("  ROBUSTNESS SUMMARY\n")
cat("================================================================\n\n")

cat("Main result: ATT = %.3f pp (SE = %.3f, p = %.4f)\n\n" |>
      sprintf(main_coef[1, "Estimate"], main_coef[1, "Std. Error"],
              main_coef[1, "Pr(>|t|)"]))

cat("1. LEAVE-ONE-DEPARTMENT-OUT:\n")
cat(sprintf("   ATT range: [%.3f, %.3f]\n", min(lodo_dt$coef), max(lodo_dt$coef)))
cat(sprintf("   Significant in %d/%d specifications (%.0f%%)\n",
            sum(lodo_dt$significant_05), n_depts,
            100 * mean(lodo_dt$significant_05)))
if (nrow(sign_changers) == 0) {
  cat("   No single department drives the sign of the result.\n")
} else {
  cat(sprintf("   CAUTION: %d department(s) change the sign when dropped.\n",
              nrow(sign_changers)))
}

cat("\n2. COMMUNE SIZE HETEROGENEITY:\n")
cat(sprintf("   Small communes: ATT = %.3f (p = %.4f)\n",
            small_coef[1, "Estimate"], small_coef[1, "Pr(>|t|)"]))
cat(sprintf("   Large communes: ATT = %.3f (p = %.4f)\n",
            large_coef[1, "Estimate"], large_coef[1, "Pr(>|t|)"]))
cat(sprintf("   Interaction (large x treat x post): %.3f (p = %.4f) %s\n",
            size_interact_est, size_interact_p,
            ifelse(size_interact_p < 0.05, "[SIGNIFICANT]",
                   ifelse(size_interact_p < 0.10, "[MARGINAL]", "[NOT SIG]"))))

cat("\n3. PRIOR FN SUPPORT HETEROGENEITY:\n")
cat(sprintf("   Low-FN communes: ATT = %.3f (p = %.4f)\n",
            low_fn_coef[1, "Estimate"], low_fn_coef[1, "Pr(>|t|)"]))
cat(sprintf("   High-FN communes: ATT = %.3f (p = %.4f)\n",
            high_fn_coef[1, "Estimate"], high_fn_coef[1, "Pr(>|t|)"]))
cat(sprintf("   Interaction (high_fn x treat x post): %.3f (p = %.4f) %s\n",
            fn_interact_est, fn_interact_p,
            ifelse(fn_interact_p < 0.05, "[SIGNIFICANT]",
                   ifelse(fn_interact_p < 0.10, "[MARGINAL]", "[NOT SIG]"))))

cat("\n4. PLACEBO TEST (purely pre-treatment: 2002, 2007, 2012):\n")
cat(sprintf("   Placebo ATT (fake 2012 treatment, sample < 2017): %.3f (p = %.4f)\n",
            placebo_coef[1, "Estimate"], placebo_coef[1, "Pr(>|t|)"]))
if (placebo_coef[1, "Pr(>|t|)"] >= 0.05) {
  cat("   PASS: No pre-existing differential trend detected.\n")
} else {
  cat("   CONCERN: Significant pre-existing differential trend.\n")
}

cat("\n4b. DROP 2002 ELECTION YEAR:\n")
cat(sprintf("   ATT (drop 2002): %.3f (SE = %.3f, p = %.4f, N = %d)\n",
            no2002_coef[1, "Estimate"], no2002_coef[1, "Std. Error"],
            no2002_coef[1, "Pr(>|t|)"], nobs(m_no2002)))
cat(sprintf("   Main ATT:        %.3f (SE = %.3f, p = %.4f, N = %d)\n",
            main_coef[1, "Estimate"], main_coef[1, "Std. Error"],
            main_coef[1, "Pr(>|t|)"], nobs(m_main)))

cat("\n5. HONESTDID SENSITIVITY:\n")
if (!is.null(honest_results)) {
  if (!is.na(honest_results$breakdown_m)) {
    cat(sprintf("   Breakdown M-bar: %.1f\n", honest_results$breakdown_m))
    cat("   (Parallel trends violations must be this many times the max\n")
    cat("    pre-treatment violation to overturn the result.)\n")
  } else {
    cat("   Result survives all M-bar values tested (up to 5.0).\n")
  }
} else {
  cat("   Analysis failed — see manual fallback results above.\n")
}

cat("\n=== Output files saved to ../data/ ===\n")
cat("  robustness_lodo.csv               — Leave-one-department-out results\n")
cat("  robustness_size_heterogeneity.csv  — Size heterogeneity results\n")
cat("  robustness_fn_heterogeneity.csv    — Prior FN support heterogeneity\n")
cat("  robustness_placebo.csv             — Placebo test results\n")
cat("  robustness_drop2002.csv            — DiD dropping 2002 election year\n")
cat("  robustness_honestdid_rm.csv        — HonestDiD relative magnitudes\n")
cat("  robustness_honestdid_breakdown.csv — HonestDiD breakdown analysis\n")
if (!is.null(honest_results) && !is.null(honest_results$sd)) {
  cat("  robustness_honestdid_sd.csv        — HonestDiD smoothness bounds\n")
}

cat("\n=== 04_robustness.R complete ===\n")
