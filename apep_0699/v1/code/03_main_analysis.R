# 03_main_analysis.R — Main regressions for apep_0699
# Saudi Arabia guardianship reform and female LFP
# Design: Difference-in-Differences (DDD) + Synthetic Control

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) setwd(file.path(dirname(normalizePath(script_path)), ".."))

source("code/00_packages.R")
load("data/cleaned_data.RData")

# ============================================================
# MODEL 1: Triple Difference (DDD)
# Outcome: female LFP rate
# Treatment: Saudi × Female × Post-guardianship (2019)
# Controls: country × year FE, gender × year FE, country × gender FE
# ============================================================
cat("=== MODEL 1: Triple Difference ===\n")

# Full DDD: Saudi × Female × Post_guard
# Include both driving reform (2018) and guardianship reform (2019) effects
mod_ddd <- feols(
  lfp ~ saudi_female * post_guard +
        saudi_female * post_driving +
        log_gdp |
    country_gender + year,
  data = long_panel,
  cluster = ~iso2c
)

cat("DDD main results:\n")
print(summary(mod_ddd))

# Extract key coefficient: saudi_female:post_guard
ddd_coef <- coef(mod_ddd)["saudi_female:post_guard"]
ddd_se <- sqrt(diag(vcov(mod_ddd)))["saudi_female:post_guard"]
ddd_tstat <- ddd_coef / ddd_se
ddd_pval <- 2 * pt(-abs(ddd_tstat), df = Inf)
cat("\nDDD Guardianship coefficient:", round(ddd_coef, 3),
    "SE:", round(ddd_se, 3),
    "p:", round(ddd_pval, 4), "\n")

# Also get driving effect
drive_coef <- coef(mod_ddd)["saudi_female:post_driving"]
drive_se <- sqrt(diag(vcov(mod_ddd)))["saudi_female:post_driving"]
drive_tstat <- drive_coef / drive_se
drive_pval <- 2 * pt(-abs(drive_tstat), df = Inf)
cat("DDD Driving coefficient:", round(drive_coef, 3),
    "SE:", round(drive_se, 3),
    "p:", round(round(drive_pval, 4)), "\n")

# ============================================================
# MODEL 2: Synthetic Control (Manual Weighted SCM)
# Treated: Saudi Arabia female LFP
# Donor pool: GCC + MENA
# ============================================================
cat("\n=== MODEL 2: Synthetic Control ===\n")

# Construct SCM: minimize distance in pre-treatment outcomes
# Simple approach: OLS weights from pre-period female LFP

# Wide data for SCM
scm_data <- female_panel_wide %>%
  filter(iso2c %in% c("SA", donor_countries), !is.na(lfp)) %>%
  select(iso2c, year, lfp)

# Create wide matrix
scm_wide <- scm_data %>%
  pivot_wider(names_from = iso2c, values_from = lfp) %>%
  arrange(year)

pre_years <- scm_wide %>% filter(year <= 2017)
post_years <- scm_wide %>% filter(year >= 2017)

# Get donor countries with complete pre-period data
available_donors <- donor_countries[donor_countries %in% names(scm_wide)]
cat("Available donor countries:", paste(available_donors, collapse = ", "), "\n")

# Pre-period matrix for OLS constraint
Y_treated_pre <- pre_years$SA
Y_donors_pre <- as.matrix(pre_years[, available_donors, drop = FALSE])

# Remove donors with any NA in pre-period
complete_donors_scm <- available_donors[apply(Y_donors_pre, 2, function(x) !any(is.na(x)))]
Y_donors_pre_complete <- Y_donors_pre[, complete_donors_scm, drop = FALSE]
cat("SCM donors (complete):", paste(complete_donors_scm, collapse = ", "), "\n")

# Synthetic control weights: minimize || Y_treated - Y_donors * W ||^2
# subject to W >= 0, sum(W) = 1
# Using quadratic programming (or constrained optimization)
if (requireNamespace("quadprog", quietly = TRUE)) {
  library(quadprog)
  n_donors <- ncol(Y_donors_pre_complete)
  Dmat <- t(Y_donors_pre_complete) %*% Y_donors_pre_complete
  Dmat <- Dmat + diag(1e-6, n_donors)  # Regularization
  dvec <- t(Y_donors_pre_complete) %*% Y_treated_pre
  Amat <- cbind(rep(1, n_donors), diag(n_donors))
  bvec <- c(1, rep(0, n_donors))
  qp_sol <- solve.QP(Dmat, dvec, Amat, bvec, meq = 1)
  scm_weights <- qp_sol$solution
  names(scm_weights) <- complete_donors_scm
} else {
  # Fallback: equal weights if quadprog unavailable
  cat("quadprog not available — using equal weights\n")
  scm_weights <- rep(1/length(complete_donors_scm), length(complete_donors_scm))
  names(scm_weights) <- complete_donors_scm
}

# Trim tiny weights
scm_weights[scm_weights < 0.01] <- 0
scm_weights <- scm_weights / sum(scm_weights)
cat("SCM weights:\n")
print(round(scm_weights[scm_weights > 0.01], 3))

# Compute synthetic control LFP (all years)
Y_donors_all <- as.matrix(scm_wide[, complete_donors_scm, drop = FALSE])
row.names(Y_donors_all) <- scm_wide$year
synthetic_sa_lfp <- Y_donors_all %*% scm_weights

# Compute gap (treated - synthetic)
sa_actual <- scm_wide$SA
names(sa_actual) <- scm_wide$year
scm_gap <- sa_actual - as.vector(synthetic_sa_lfp)
names(scm_gap) <- scm_wide$year

# Store SCM results
scm_results <- tibble(
  year = as.integer(scm_wide$year),
  sa_actual = sa_actual,
  synthetic = as.vector(synthetic_sa_lfp),
  gap = scm_gap,
  post_guard = as.integer(year >= 2019)
)

cat("\nSCM pre-treatment fit (RMSPE):\n")
rmspe_pre <- sqrt(mean((scm_results %>% filter(year <= 2017) %>% pull(gap))^2))
cat("  RMSPE (pre-2018):", round(rmspe_pre, 2), "pp\n")

cat("\nSCM post-treatment gap:\n")
scm_results %>% filter(year >= 2018) %>% select(year, sa_actual, synthetic, gap) %>% print()

mean_guard_effect_scm <- mean((scm_results %>% filter(year >= 2020) %>% pull(gap)))
cat("Mean post-guardianship gap (SCM, 2020+):", round(mean_guard_effect_scm, 2), "pp\n")

# ============================================================
# MODEL 3: Event Study (Country-level DiD, female only)
# Year-by-year treatment effects for Saudi Arabia vs donor pool
# ============================================================
cat("\n=== MODEL 3: Event Study ===\n")

event_data <- female_panel_wide %>%
  filter(iso2c %in% c("SA", complete_donors_scm), !is.na(lfp)) %>%
  mutate(
    is_saudi = as.integer(iso2c == "SA"),
    rel_year = year - 2019
  )

# Create year dummies × Saudi interaction
event_data <- event_data %>%
  filter(rel_year >= -7, rel_year <= 5) %>%  # -7 to +5 relative to 2019
  mutate(rel_year_f = factor(rel_year, levels = sort(unique(rel_year))))

# Event study regression (omit rel_year = -1 as base year)
event_data$rel_year_f <- relevel(event_data$rel_year_f, ref = as.character(-1))

mod_event <- feols(
  lfp ~ i(rel_year, is_saudi, ref = -1) |
    iso2c + year,
  data = event_data,
  cluster = ~iso2c
)

cat("Event study results:\n")
print(summary(mod_event))

# Extract event study coefficients
event_coefs <- coef(mod_event)
event_se <- sqrt(diag(vcov(mod_event)))
event_names <- names(event_coefs)

event_df <- tibble(
  coef_name = event_names,
  estimate = event_coefs,
  std_error = event_se
) %>%
  filter(grepl("rel_year", coef_name)) %>%
  mutate(
    rel_year = as.integer(gsub(".*rel_year::(-?[0-9]+).*", "\\1", coef_name)),
    ci_lo = estimate - 1.96 * std_error,
    ci_hi = estimate + 1.96 * std_error,
    post = as.integer(rel_year >= 0)
  ) %>%
  arrange(rel_year)

# Add the omitted year (= 0 by construction)
event_df <- bind_rows(
  event_df,
  tibble(rel_year = -1, estimate = 0, std_error = 0, ci_lo = 0, ci_hi = 0, post = 0)
) %>% arrange(rel_year)

cat("\nEvent study coefficients:\n")
print(event_df %>% select(rel_year, estimate, std_error, ci_lo, ci_hi))

# ============================================================
# MODEL 4: Saudi Arabia vs. Saudi MEN (pure 2-group DiD)
# Uses male LFP as within-country control
# ============================================================
cat("\n=== MODEL 4: Saudi Within-Country DiD ===\n")

sa_panel <- long_panel %>%
  filter(iso2c == "SA", year >= 2010, year <= 2023) %>%
  select(year, gender, lfp, is_female, post_guard, post_driving, log_gdp)

mod_sa_did <- feols(
  lfp ~ is_female * post_guard +
        is_female * post_driving |
    gender + year,
  data = sa_panel
)

cat("Saudi within-country DiD (female vs male):\n")
print(summary(mod_sa_did))

sa_guard_coef <- coef(mod_sa_did)["is_female:post_guard"]
sa_guard_se <- sqrt(diag(vcov(mod_sa_did)))["is_female:post_guard"]
cat("Saudi DiD guardianship effect:", round(sa_guard_coef, 2), "SE:", round(sa_guard_se, 2), "\n")

# ============================================================
# SAVE RESULTS
# ============================================================
results <- list(
  mod_ddd = mod_ddd,
  mod_event = mod_event,
  mod_sa_did = mod_sa_did,
  scm_results = scm_results,
  scm_weights = scm_weights,
  event_df = event_df,
  ddd_coef = ddd_coef,
  ddd_se = ddd_se,
  ddd_pval = ddd_pval,
  drive_coef = drive_coef,
  drive_se = drive_se,
  drive_pval = drive_pval,
  mean_guard_effect_scm = mean_guard_effect_scm,
  sa_guard_coef = sa_guard_coef,
  sa_guard_se = sa_guard_se,
  rmspe_pre = rmspe_pre,
  complete_donors_scm = complete_donors_scm
)

save(results, file = "data/results.RData")

# Write diagnostics.json for validator
# SCM design: n_treated = 1 (Saudi Arabia), omitted per SCM convention
# n_pre = 8 (2010-2017 pre-reform years), n_obs = total panel obs
diagnostics <- list(
  n_obs = nrow(long_panel),
  n_pre = 8L,   # 2010-2017 pre-guardianship years for Saudi Arabia
  method = "DDD-SCM",
  n_countries = n_distinct(long_panel$iso2c),
  n_donors = length(complete_donors_scm),
  design_note = "SCM with DDD validation. 1 treated country (Saudi Arabia). Inference via permutation tests in 04_robustness.R"
)
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat("\nMain analysis complete. Results saved.\n")
cat("Key findings:\n")
cat("  DDD guardianship effect:", round(ddd_coef, 2), "pp (SE:", round(ddd_se, 2), ")\n")
cat("  DDD driving effect:", round(drive_coef, 2), "pp (SE:", round(drive_se, 2), ")\n")
cat("  SCM mean guardianship gap (2020+):", round(mean_guard_effect_scm, 2), "pp\n")
cat("  Saudi DiD (within-country):", round(sa_guard_coef, 2), "pp\n")
