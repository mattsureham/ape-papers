# ==============================================================================
# 04_robustness.R — Robustness checks and sensitivity
# Paper: Who Bears the Tax Cut? (apep_0512)
# ==============================================================================

source("00_packages.R")

# Load data
dvf <- fread(file.path(data_dir, "dvf_analysis.csv"))
commune <- fread(file.path(data_dir, "commune_panel.csv"))
commune_clean <- commune[!is.na(th_share_pre) & !is.na(taux_tfb)]

cat("=== Robustness Checks ===\n\n")

# ==============================================================================
# R1: Pre-COVID sample (2014-2019)
# ==============================================================================

cat("R1: Pre-COVID sample (2014-2019)\n")

precovid <- feols(
  log_price_m2 ~ treat_post | code_insee + year,
  data = dvf[year <= 2019],
  weights = ~n_total_sales,
  cluster = ~code_insee
)
cat("  Pre-COVID: beta =", round(coef(precovid)["treat_post"], 4),
    "SE =", round(se(precovid)["treat_post"], 4), "\n\n")

# ==============================================================================
# R2: Department x year FE (absorb regional trends)
# ==============================================================================

cat("R2: Department x year fixed effects\n")

dvf[, dept_year := paste0(code_dept, "_", year)]

dept_year_model <- feols(
  log_price_m2 ~ treat_post | code_insee + dept_year,
  data = dvf,
  weights = ~n_total_sales,
  cluster = ~code_insee
)
cat("  Dept x Year FE: beta =", round(coef(dept_year_model)["treat_post"], 4),
    "SE =", round(se(dept_year_model)["treat_post"], 4), "\n\n")

# ==============================================================================
# R3: Exclude Ile-de-France (Paris region)
# ==============================================================================

cat("R3: Excluding Ile-de-France\n")

idf_depts <- c("75", "77", "78", "91", "92", "93", "94", "95")
no_idf <- feols(
  log_price_m2 ~ treat_post | code_insee + year,
  data = dvf[!(code_dept %in% idf_depts)],
  weights = ~n_total_sales,
  cluster = ~code_insee
)
cat("  Excl IDF: beta =", round(coef(no_idf)["treat_post"], 4),
    "SE =", round(se(no_idf)["treat_post"], 4), "\n\n")

# ==============================================================================
# R4: Trimmed sample (5th-95th percentile TH rate)
# ==============================================================================

cat("R4: Trimmed sample (5th-95th percentile TH rate)\n")

q5 <- quantile(dvf$th_rate_pre, 0.05, na.rm = TRUE)
q95 <- quantile(dvf$th_rate_pre, 0.95, na.rm = TRUE)

trimmed <- feols(
  log_price_m2 ~ treat_post | code_insee + year,
  data = dvf[th_rate_pre >= q5 & th_rate_pre <= q95],
  weights = ~n_total_sales,
  cluster = ~code_insee
)
cat("  Trimmed: beta =", round(coef(trimmed)["treat_post"], 4),
    "SE =", round(se(trimmed)["treat_post"], 4), "\n\n")

# ==============================================================================
# R5: Unweighted specification
# ==============================================================================

cat("R5: Unweighted specification\n")

unweighted <- feols(
  log_price_m2 ~ treat_post | code_insee + year,
  data = dvf,
  cluster = ~code_insee
)
cat("  Unweighted: beta =", round(coef(unweighted)["treat_post"], 4),
    "SE =", round(se(unweighted)["treat_post"], 4), "\n\n")

# ==============================================================================
# R6: Anticipation test (2017 as early treatment)
# ==============================================================================

cat("R6: Anticipation test\n")

dvf[, post_2017 := as.integer(year >= 2017)]
dvf[, treat_post_2017 := th_rate_pre * post_2017]

anticip <- feols(
  log_price_m2 ~ treat_post_2017 | code_insee + year,
  data = dvf[year %in% 2014:2018],
  weights = ~n_total_sales,
  cluster = ~code_insee
)
cat("  Anticipation (post=2017): beta =", round(coef(anticip)["treat_post_2017"], 4),
    "SE =", round(se(anticip)["treat_post_2017"], 4), "\n\n")

# ==============================================================================
# R7: Fiscal displacement robustness — Pre-COVID
# ==============================================================================

cat("R7: Fiscal displacement pre-COVID\n")

fiscal_precovid <- feols(
  taux_tfb ~ th_depend_post | code_insee + year,
  data = commune_clean[year <= 2019],
  cluster = ~code_insee
)
cat("  Fiscal pre-COVID: phi =", round(coef(fiscal_precovid)["th_depend_post"], 4),
    "SE =", round(se(fiscal_precovid)["th_depend_post"], 4), "\n\n")

# ==============================================================================
# R8: Fiscal displacement — Department x year FE
# ==============================================================================

cat("R8: Fiscal displacement with dept x year FE\n")

commune_clean[, dept := substr(code_insee, 1, 2)]
commune_clean[, dept_year := paste0(dept, "_", year)]

fiscal_dept <- feols(
  taux_tfb ~ th_depend_post | code_insee + dept_year,
  data = commune_clean,
  cluster = ~code_insee
)
cat("  Fiscal dept x year: phi =", round(coef(fiscal_dept)["th_depend_post"], 4),
    "SE =", round(se(fiscal_dept)["th_depend_post"], 4), "\n\n")

# ==============================================================================
# R9: Balanced panel (communes in both pre and post-reform periods)
# ==============================================================================

cat("R9: Balanced panel\n")

# Identify communes present in both pre-reform (2014-2017) and post-reform (2018-2024)
pre_communes <- unique(dvf[year <= 2017]$code_insee)
post_communes <- unique(dvf[year >= 2018]$code_insee)
balanced_communes <- intersect(pre_communes, post_communes)
cat("  Balanced panel communes:", length(balanced_communes), "\n")

balanced_model <- feols(
  log_price_m2 ~ treat_post | code_insee + year,
  data = dvf[code_insee %in% balanced_communes],
  weights = ~n_total_sales,
  cluster = ~code_insee
)
cat("  Balanced panel: beta =", round(coef(balanced_model)["treat_post"], 4),
    "SE =", round(se(balanced_model)["treat_post"], 4),
    "N =", nobs(balanced_model), "\n\n")

# ==============================================================================
# SAVE ROBUSTNESS RESULTS
# ==============================================================================

cat("=== Saving robustness results ===\n")

robust <- list(
  precovid = precovid,
  dept_year = dept_year_model,
  no_idf = no_idf,
  trimmed = trimmed,
  unweighted = unweighted,
  anticipation = anticip,
  fiscal_precovid = fiscal_precovid,
  fiscal_dept = fiscal_dept,
  balanced = balanced_model
)

saveRDS(robust, file.path(data_dir, "robustness_results.rds"))
cat("Robustness results saved.\n")
