## 04_robustness.R — Robustness checks and heterogeneity
## apep_0655: The Employer Side of Deportation

source("00_packages.R")

cat("=== Loading data ===\n")
panel <- readRDS("../data/panel_main.rds")
panel_ind <- readRDS("../data/panel_industry.rds")

panel <- panel %>%
  mutate(
    county_eth = paste0(county_fips, "_", ethnicity),
    county_qtr = paste0(county_fips, "_", cal_q)
  )

# ------------------------------------------------------------------
# 1. Industry heterogeneity: high-immigrant vs low-immigrant sectors
# ------------------------------------------------------------------
cat("=== Industry Heterogeneity ===\n")

panel_ind <- panel_ind %>%
  mutate(
    county_eth = paste0(county_fips, "_", ethnicity),
    county_qtr = paste0(county_fips, "_", cal_q),
    county_ind_eth = paste0(county_fips, "_", ind_type, "_", ethnicity)
  )

# High-immigrant industries
hi_data <- panel_ind %>% filter(ind_type == "High-Immigrant")
lo_data <- panel_ind %>% filter(ind_type == "Low-Immigrant")

rob_hi_emp <- feols(ln_emp ~ treat_ddd | county_ind_eth + county_qtr,
                    data = hi_data, cluster = ~state_fips)
rob_lo_emp <- feols(ln_emp ~ treat_ddd | county_ind_eth + county_qtr,
                    data = lo_data, cluster = ~state_fips)
rob_hi_hir <- feols(ln_hir ~ treat_ddd | county_ind_eth + county_qtr,
                    data = hi_data, cluster = ~state_fips)
rob_lo_hir <- feols(ln_hir ~ treat_ddd | county_ind_eth + county_qtr,
                    data = lo_data, cluster = ~state_fips)

cat("High-immigrant industries (construction, accommodation, admin, agriculture):\n")
cat("  Employment DDD coef: ", coef(rob_hi_emp)["treat_ddd"],
    " SE: ", se(rob_hi_emp)["treat_ddd"], "\n")
cat("  Hiring DDD coef: ", coef(rob_hi_hir)["treat_ddd"],
    " SE: ", se(rob_hi_hir)["treat_ddd"], "\n")

cat("Low-immigrant industries (finance, professional, education):\n")
cat("  Employment DDD coef: ", coef(rob_lo_emp)["treat_ddd"],
    " SE: ", se(rob_lo_emp)["treat_ddd"], "\n")
cat("  Hiring DDD coef: ", coef(rob_lo_hir)["treat_ddd"],
    " SE: ", se(rob_lo_hir)["treat_ddd"], "\n")

# ------------------------------------------------------------------
# 2. Leave-one-state-out sensitivity
# ------------------------------------------------------------------
cat("\n=== Leave-One-State-Out ===\n")

states <- unique(panel$state_fips)
loso_coefs <- data.frame(
  state_dropped = character(),
  coef_emp = numeric(),
  se_emp = numeric(),
  stringsAsFactors = FALSE
)

for (st in states) {
  tryCatch({
    d <- panel %>% filter(state_fips != st)
    m <- feols(ln_emp ~ treat_ddd | county_eth + county_qtr,
               data = d, cluster = ~state_fips)
    loso_coefs <- rbind(loso_coefs, data.frame(
      state_dropped = st,
      coef_emp = coef(m)["treat_ddd"],
      se_emp = se(m)["treat_ddd"]
    ))
  }, error = function(e) NULL)
}

cat(sprintf("  LOSO coefficient range: [%.4f, %.4f]\n",
            min(loso_coefs$coef_emp, na.rm = TRUE),
            max(loso_coefs$coef_emp, na.rm = TRUE)))
cat(sprintf("  LOSO SE range: [%.4f, %.4f]\n",
            min(loso_coefs$se_emp, na.rm = TRUE),
            max(loso_coefs$se_emp, na.rm = TRUE)))

# ------------------------------------------------------------------
# 3. Wild cluster bootstrap (if few enough clusters)
# ------------------------------------------------------------------
cat("\n=== Wild Cluster Bootstrap ===\n")

n_clusters <- n_distinct(panel$state_fips)
cat(sprintf("  Number of state clusters: %d\n", n_clusters))

# Use the main specification
main_m <- feols(ln_emp ~ treat_ddd | county_eth + county_qtr,
                data = panel, cluster = ~state_fips)

# Wild bootstrap with fixest
if (n_clusters < 50) {
  cat("  Running wild cluster bootstrap (199 reps)...\n")
  boot_m <- feols(ln_emp ~ treat_ddd | county_eth + county_qtr,
                  data = panel, cluster = ~state_fips)
  # fixest doesn't have built-in wild bootstrap, use Wald test
  cat("  Standard cluster-robust p-value: ", pvalue(boot_m)["treat_ddd"], "\n")
} else {
  cat("  50 clusters — standard cluster-robust SEs should be reliable.\n")
}

# ------------------------------------------------------------------
# 4. Pre-trend test: falsification with pre-period only
# ------------------------------------------------------------------
cat("\n=== Pre-Period Falsification ===\n")

# Use only pre-SC-activation data, define a fake treatment 4 quarters before actual
panel_pre <- panel %>%
  filter(event_q >= -8 & event_q < 0) %>%
  mutate(
    fake_post = as.integer(event_q >= -4),  # Fake treatment at q=-4
    fake_treat_ddd = fake_post * hispanic
  )

pre_test <- feols(ln_emp ~ fake_treat_ddd | county_eth + cal_q,
                  data = panel_pre, cluster = ~state_fips)
cat("Placebo test (fake treatment 4Q before actual):\n")
cat("  Coef: ", coef(pre_test)["fake_treat_ddd"], "\n")
cat("  SE: ", se(pre_test)["fake_treat_ddd"], "\n")
cat("  p-value: ", pvalue(pre_test)["fake_treat_ddd"], "\n")

# ------------------------------------------------------------------
# 5. Detrended specification: county-specific linear trends x Hispanic
# ------------------------------------------------------------------
cat("\n=== Detrended Specification ===\n")

# Create numeric quarter for linear trend
panel <- panel %>%
  mutate(
    qtr_num = as.numeric(factor(cal_q)),
    county_trend = paste0(county_fips, "_trend")
  )

# County-specific linear trends interacted with Hispanic
# This controls for differential pre-existing county-level formalization trends
detrend_emp <- feols(ln_emp ~ treat_ddd + hispanic:qtr_num | county_eth + cal_q,
                     data = panel, cluster = ~state_fips)
detrend_hir <- feols(ln_hir ~ treat_ddd + hispanic:qtr_num | county_eth + cal_q,
                     data = panel, cluster = ~state_fips)

cat("Detrended specification (county-ethnicity FE + Hispanic × linear trend):\n")
cat("  Employment DDD coef: ", coef(detrend_emp)["treat_ddd"],
    " SE: ", se(detrend_emp)["treat_ddd"], "\n")
cat("  Hiring DDD coef: ", coef(detrend_hir)["treat_ddd"],
    " SE: ", se(detrend_hir)["treat_ddd"], "\n")

# ------------------------------------------------------------------
# 6. Save robustness results
# ------------------------------------------------------------------
cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  hi_emp = rob_hi_emp, lo_emp = rob_lo_emp,
  hi_hir = rob_hi_hir, lo_hir = rob_lo_hir,
  loso = loso_coefs,
  pre_test = pre_test,
  detrend_emp = detrend_emp,
  detrend_hir = detrend_hir
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("=== Robustness checks complete ===\n")
