# 04_robustness.R — Robustness checks
# apep_1336: EPA Enforcement Federalism Production Function

source("00_packages.R")

data_dir <- "../data/"

cat("=== Loading data ===\n")
pm25 <- readRDS(file.path(data_dir, "panel_pm25.rds"))
pm25_bal <- pm25[balanced == TRUE]
state_panel <- readRDS(file.path(data_dir, "panel_state.rds"))

# ==============================================================================
# 1. LEAVE-ONE-STATE-OUT SENSITIVITY
# ==============================================================================

cat("\n=== Leave-One-State-Out ===\n")

states <- unique(pm25_bal$state_abbr)
loo_results <- data.frame(
  dropped_state = character(),
  coef = numeric(),
  se = numeric(),
  pvalue = numeric(),
  stringsAsFactors = FALSE
)

for (st in states) {
  dt_loo <- pm25_bal[state_abbr != st]
  m_loo <- tryCatch(
    feols(log_conc ~ post_x_fedshare | county_id + year,
          data = dt_loo, cluster = ~state_abbr),
    error = function(e) NULL
  )
  if (!is.null(m_loo)) {
    loo_results <- rbind(loo_results, data.frame(
      dropped_state = st,
      coef = as.numeric(coef(m_loo)),
      se = as.numeric(se(m_loo)),
      pvalue = as.numeric(pvalue(m_loo)),
      stringsAsFactors = FALSE
    ))
  }
}

cat(sprintf("LOO: Range of coefficients: [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("LOO: Main estimate: %.4f\n",
            as.numeric(coef(feols(log_conc ~ post_x_fedshare | county_id + year,
                                  data = pm25_bal, cluster = ~state_abbr)))))

# ==============================================================================
# 2. PLACEBO: PRE-TREATMENT EVENT STUDY COEFFICIENTS
# ==============================================================================

cat("\n=== Placebo: Pre-Treatment Coefficients ===\n")

# Already have event study from main analysis - check pre-trends
pm25_bal[, year_factor := factor(year)]
pm25_bal[, year_factor := relevel(year_factor, ref = "2016")]

m_es <- feols(log_conc ~ i(year_factor, fed_share, ref = "2016") | county_id + year,
              data = pm25_bal, cluster = ~state_abbr)

# Extract pre-treatment coefficients
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$term <- rownames(es_coefs)
pre_coefs <- es_coefs[grep("201[0-5]", es_coefs$term), ]
cat("Pre-treatment event study coefficients:\n")
print(pre_coefs[, c("term", "Estimate", "Std. Error", "Pr(>|t|)")])

# Joint F-test for pre-trends
pre_terms <- grep("201[0-5]", rownames(coeftable(m_es)), value = TRUE)
if (length(pre_terms) > 0) {
  f_test <- tryCatch(wald(m_es, pre_terms), error = function(e) NULL)
  if (!is.null(f_test)) {
    cat(sprintf("\nJoint F-test for pre-trends: F=%.2f, p=%.4f\n",
                f_test$stat, f_test$p))
  }
}

# ==============================================================================
# 3. ALTERNATIVE TREATMENT DEFINITIONS
# ==============================================================================

cat("\n=== Alternative Treatment Definitions ===\n")

# Binary treatment: above/below median federal share
pm25_bal[, high_fedshare := as.integer(fed_share > median(fed_share, na.rm = TRUE))]
m_binary <- feols(log_conc ~ high_fedshare:post_decline | county_id + year,
                  data = pm25_bal, cluster = ~state_abbr)
cat(sprintf("Binary treatment: β=%.4f, SE=%.4f, p=%.4f\n",
            coef(m_binary)[1], se(m_binary)[1], pvalue(m_binary)[1]))

# Tercile treatment
pm25_bal[, fed_tercile := cut(fed_share, quantile(fed_share, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                               include.lowest = TRUE, labels = c("low", "mid", "high"))]
m_tercile <- feols(log_conc ~ fed_tercile:post_decline | county_id + year,
                   data = pm25_bal, cluster = ~state_abbr)
cat("Tercile treatment:\n")
print(coeftable(m_tercile)[, c("Estimate", "Std. Error", "Pr(>|t|)")])

# ==============================================================================
# 4. DIFFERENT SAMPLE RESTRICTIONS
# ==============================================================================

cat("\n=== Sample Restrictions ===\n")

# Exclude extreme observations (top/bottom 1%)
pm25_trimmed <- pm25_bal[mean_conc > quantile(mean_conc, 0.01, na.rm = TRUE) &
                          mean_conc < quantile(mean_conc, 0.99, na.rm = TRUE)]
m_trim <- feols(log_conc ~ post_x_fedshare | county_id + year,
                data = pm25_trimmed, cluster = ~state_abbr)
cat(sprintf("Trimmed (1-99%%): β=%.4f, SE=%.4f, p=%.4f\n",
            coef(m_trim), se(m_trim), pvalue(m_trim)))

# Exclude 2020 (COVID year)
pm25_nocovid <- pm25_bal[year != 2020]
m_nocovid <- feols(log_conc ~ post_x_fedshare | county_id + year,
                   data = pm25_nocovid, cluster = ~state_abbr)
cat(sprintf("Excl 2020: β=%.4f, SE=%.4f, p=%.4f\n",
            coef(m_nocovid), se(m_nocovid), pvalue(m_nocovid)))

# Only 2012-2019 (clean pre/post, no COVID)
pm25_clean <- pm25_bal[year >= 2012 & year <= 2019]
m_clean <- feols(log_conc ~ post_x_fedshare | county_id + year,
                 data = pm25_clean, cluster = ~state_abbr)
cat(sprintf("2012-2019 only: β=%.4f, SE=%.4f, p=%.4f\n",
            coef(m_clean), se(m_clean), pvalue(m_clean)))

# ==============================================================================
# 5. SAVE ROBUSTNESS RESULTS
# ==============================================================================

robustness_models <- list(
  loo = loo_results,
  event_study = m_es,
  binary = m_binary,
  tercile = m_tercile,
  trimmed = m_trim,
  no_covid = m_nocovid,
  clean_window = m_clean
)
saveRDS(robustness_models, file.path(data_dir, "robustness_models.rds"))

cat("\nRobustness checks complete.\n")
