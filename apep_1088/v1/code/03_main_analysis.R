## 03_main_analysis.R — Primary analysis: bunching + growth DiD
## apep_1088: IRS 990 Threshold Reform and Nonprofit Growth
##
## Revised strategy: Two-threshold comparison within 2011-2022 data
## 1. Bunching estimation at $200K (new threshold) vs $100K (old, freed)
## 2. DiD: orgs near $200K (constrained) vs control_mid (unconstrained)
## 3. Event study for revenue growth dynamics

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# Load data
# ============================================================
cat("=== Loading analysis panel ===\n")
df <- fread(file.path(data_dir, "analysis_panel.csv"))
df[, `:=`(
  year_fe = factor(tax_year),
  ein_fe = factor(ein),
  constrained = as.integer(group == "near_200k"),
  post = as.integer(tax_year >= 2016),
  event_time = tax_year - 2016  # baseline: 2011-2015
)]

density_full <- fread(file.path(data_dir, "density_full.csv"))

cat(sprintf("Panel: %s obs, %s orgs\n",
    format(nrow(df), big.mark = ","),
    format(uniqueN(df$ein), big.mark = ",")))

# ============================================================
# ANALYSIS 1: Bunching at $200K
# ============================================================
cat("\n=== Bunching Estimation ===\n")

# Polynomial counterfactual approach (Kleven 2016)
# Fit polynomial to density excluding bunching window, then measure excess mass

estimate_bunching <- function(density_dt, threshold, window = 10000, bin_width = 2000, poly_order = 7) {
  # Create bins and normalize
  dt <- copy(density_dt)
  dt[, bin_center := rev_bin + bin_width / 2]

  # Exclude bunching window from polynomial fit
  excl_lo <- threshold - window
  excl_hi <- threshold + window
  dt[, in_window := bin_center >= excl_lo & bin_center <= excl_hi]
  dt[, z := (bin_center - threshold) / bin_width]

  # Fit polynomial on data outside exclusion window
  fit_data <- dt[(in_window == FALSE)]
  if (nrow(fit_data) < poly_order + 1) {
    cat("  WARNING: Too few bins outside window for polynomial fit\n")
    return(list(excess = NA, se = NA, b_hat = NA))
  }

  formula_str <- paste0("count ~ ", paste0("I(z^", 1:poly_order, ")", collapse = " + "))
  fit <- lm(as.formula(formula_str), data = fit_data)

  # Predict counterfactual in the window
  dt[, predicted := predict(fit, newdata = dt)]

  # Excess mass in the bunching window (below threshold only)
  bunching_bins <- dt[bin_center >= excl_lo & bin_center < threshold]
  excess <- sum(bunching_bins$count) - sum(bunching_bins$predicted)
  avg_counterfactual <- mean(bunching_bins$predicted)
  b_hat <- excess / avg_counterfactual  # normalized excess mass

  # Bootstrap SE
  set.seed(42)
  n_boot <- 200
  b_boots <- numeric(n_boot)
  for (b in seq_len(n_boot)) {
    # Resample counts with Poisson noise
    dt_boot <- copy(dt)
    dt_boot[, count := rpois(.N, pmax(count, 1))]
    fit_boot <- tryCatch(
      lm(as.formula(formula_str), data = dt_boot[(in_window == FALSE)]),
      error = function(e) NULL
    )
    if (!is.null(fit_boot)) {
      dt_boot[, pred_boot := predict(fit_boot, newdata = dt_boot)]
      bb <- dt_boot[bin_center >= excl_lo & bin_center < threshold]
      excess_b <- sum(bb$count) - sum(bb$pred_boot)
      avg_cf_b <- mean(bb$pred_boot)
      b_boots[b] <- excess_b / avg_cf_b
    }
  }
  se <- sd(b_boots, na.rm = TRUE)

  list(excess = excess, b_hat = b_hat, se = se,
       density_with_cf = dt[, .(rev_bin, bin_center, count, predicted, in_window)])
}

# Bunching at $200K (new threshold — should find bunching)
cat("\n--- Bunching at $200K (new threshold) ---\n")
bunch_200k <- estimate_bunching(density_full, threshold = 200000)
cat(sprintf("  Excess mass: %.0f organizations\n", bunch_200k$excess))
cat(sprintf("  Normalized b: %.3f (SE: %.3f)\n", bunch_200k$b_hat, bunch_200k$se))
cat(sprintf("  t-stat: %.2f\n", bunch_200k$b_hat / bunch_200k$se))

# Bunching at $100K (old threshold — should find NO bunching)
cat("\n--- Bunching at $100K (old threshold, freed) ---\n")
bunch_100k <- estimate_bunching(density_full, threshold = 100000)
cat(sprintf("  Excess mass: %.0f organizations\n", bunch_100k$excess))
cat(sprintf("  Normalized b: %.3f (SE: %.3f)\n", bunch_100k$b_hat, bunch_100k$se))
cat(sprintf("  t-stat: %.2f\n", bunch_100k$b_hat / bunch_100k$se))

# Placebo at $150K (no threshold — should find NO bunching)
cat("\n--- Placebo at $150K (no threshold) ---\n")
bunch_150k <- estimate_bunching(density_full, threshold = 150000)
cat(sprintf("  Excess mass: %.0f organizations\n", bunch_150k$excess))
cat(sprintf("  Normalized b: %.3f (SE: %.3f)\n", bunch_150k$b_hat, bunch_150k$se))

# ============================================================
# ANALYSIS 2: Revenue Growth DiD
# ============================================================
cat("\n=== DiD: Revenue Growth ===\n")

# Compare near_200k (constrained by new threshold) vs control_mid (between thresholds)
df_did <- df[group %in% c("near_200k", "control_mid")]

# (1) Log revenue
m1 <- feols(log_rev ~ constrained:post | ein_fe + year_fe,
            data = df_did, cluster = ~ein)

# (2) Revenue growth
m2 <- feols(rev_growth ~ constrained:post | ein_fe + year_fe,
            data = df_did, cluster = ~ein)

# (3) Log expenses
m3 <- feols(log_exp ~ constrained:post | ein_fe + year_fe,
            data = df_did, cluster = ~ein)

# (4) Using control_low as alternative controls
df_did2 <- df[group %in% c("near_200k", "control_low")]
df_did2[, `:=`(constrained = as.integer(group == "near_200k"),
               post = as.integer(tax_year >= 2016))]
m4 <- feols(log_rev ~ constrained:post | factor(ein) + factor(tax_year),
            data = df_did2, cluster = ~ein)

cat("--- DiD Results ---\n")
cat(sprintf("(1) Log Revenue: β = %.4f (SE = %.4f), p = %.3f\n",
    coef(m1)[1], sqrt(vcov(m1)[1,1]),
    2 * pnorm(-abs(coef(m1)[1] / sqrt(vcov(m1)[1,1])))))
cat(sprintf("(2) Rev Growth:  β = %.4f (SE = %.4f)\n",
    coef(m2)[1], sqrt(vcov(m2)[1,1])))
cat(sprintf("(3) Log Expenses: β = %.4f (SE = %.4f)\n",
    coef(m3)[1], sqrt(vcov(m3)[1,1])))
cat(sprintf("(4) Log Rev (alt ctrl): β = %.4f (SE = %.4f)\n",
    coef(m4)[1], sqrt(vcov(m4)[1,1])))

# ============================================================
# ANALYSIS 3: Event Study
# ============================================================
cat("\n=== Event Study ===\n")

df_did[, event_time_f := relevel(factor(event_time), ref = "-1")]

m_es <- feols(log_rev ~ constrained:event_time_f | ein_fe + year_fe,
              data = df_did[event_time >= -3 & event_time <= 8],
              cluster = ~ein)

es_coefs <- data.table(
  event_time = as.integer(gsub(".*:event_time_f", "", names(coef(m_es)))),
  coef = coef(m_es),
  se = sqrt(diag(vcov(m_es)))
)
es_coefs[, `:=`(ci_lo = coef - 1.96 * se, ci_hi = coef + 1.96 * se)]
es_coefs <- es_coefs[order(event_time)]

cat("Event study coefficients:\n")
print(es_coefs)

fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# ============================================================
# ANALYSIS 4: Mechanism — Revenue vs Expenses
# ============================================================
cat("\n=== Mechanism Decomposition ===\n")

m_rev <- m1  # Already computed
m_exp <- m3  # Already computed

# Assets
df_did[, log_assets := log(pmax(total_assets, 1, na.rm = TRUE))]
m_assets <- feols(log_assets ~ constrained:post | ein_fe + year_fe,
                  data = df_did[!is.na(total_assets) & total_assets > 0],
                  cluster = ~ein)

# Revenue-expense gap
df_did[, rev_exp_gap := log_rev - log_exp]
m_gap <- feols(rev_exp_gap ~ constrained:post | ein_fe + year_fe,
               data = df_did, cluster = ~ein)

cat(sprintf("Revenue:  β = %.4f (%.4f)\n", coef(m_rev)[1], sqrt(vcov(m_rev)[1,1])))
cat(sprintf("Expenses: β = %.4f (%.4f)\n", coef(m_exp)[1], sqrt(vcov(m_exp)[1,1])))
cat(sprintf("Assets:   β = %.4f (%.4f)\n", coef(m_assets)[1], sqrt(vcov(m_assets)[1,1])))
cat(sprintf("Rev-Exp gap: β = %.4f (%.4f)\n", coef(m_gap)[1], sqrt(vcov(m_gap)[1,1])))

# ============================================================
# Save diagnostics and models
# ============================================================
diag_list <- list(
  n_treated = uniqueN(df_did[constrained == 1, ein]),
  n_control = uniqueN(df_did[constrained == 0, ein]),
  n_pre = length(unique(df_did[tax_year < 2016, tax_year])),
  n_post = length(unique(df_did[tax_year >= 2016, tax_year])),
  n_obs = nrow(df_did),
  bunching_200k = bunch_200k$b_hat,
  bunching_200k_se = bunch_200k$se,
  bunching_100k = bunch_100k$b_hat,
  bunching_100k_se = bunch_100k$se
)
jsonlite::write_json(diag_list, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

save(m1, m2, m3, m4, m_es, m_rev, m_exp, m_assets, m_gap, es_coefs,
     bunch_200k, bunch_100k, bunch_150k,
     file = file.path(data_dir, "models.RData"))

cat(sprintf("\nDiagnostics: %d treated, %d control, %d pre, %d post, %d obs\n",
    diag_list$n_treated, diag_list$n_control, diag_list$n_pre, diag_list$n_post, diag_list$n_obs))
cat("03_main_analysis.R complete.\n")
