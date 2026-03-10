#' 04_robustness.R — Robustness checks
#' REACH 2018 Deadline and Chemical Industry Restructuring

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(paste0(data_dir, "analysis_panel.csv"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ===========================================================================
# 1. Leave-one-country-out
# ===========================================================================
cat("1. Leave-one-country-out...\n")

countries <- unique(panel$geo)
loo_results <- rbindlist(lapply(countries, function(cc) {
  dt <- panel[geo != cc]
  m <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 |
               cs_id + cy_id + sy_id,
             data = dt, cluster = ~geo)
  data.table(
    dropped = cc,
    coef = coef(m)[1],
    se = se(m)[1],
    pval = pvalue(m)[1],
    N = m$nobs
  )
}))

fwrite(loo_results, paste0(data_dir, "robustness_loo.csv"))
cat("  Range of coefficients:", round(range(loo_results$coef), 4), "\n")

# ===========================================================================
# 2. Alternative control sectors
# ===========================================================================
cat("\n2. Alternative control sectors...\n")

# a) Only C22-C23 (closer to chemicals)
panel_narrow <- panel[nace_r2 %in% c("C20", "C22", "C23")]
panel_narrow[, `:=`(
  cs_id = paste0(geo, "_", nace_r2),
  cy_id = paste0(geo, "_", year),
  sy_id = paste0(nace_r2, "_", year)
)]
m_narrow <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 |
                    cs_id + cy_id + sy_id,
                  data = panel_narrow, cluster = ~geo)

# b) Only C24-C25 (metals)
panel_metals <- panel[nace_r2 %in% c("C20", "C24", "C25")]
panel_metals[, `:=`(
  cs_id = paste0(geo, "_", nace_r2),
  cy_id = paste0(geo, "_", year),
  sy_id = paste0(nace_r2, "_", year)
)]
m_metals <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 |
                    cs_id + cy_id + sy_id,
                  data = panel_metals, cluster = ~geo)

alt_controls <- data.table(
  specification = c("Baseline (C22-C25)", "Narrow (C22-C23)", "Metals (C24-C25)"),
  coef = c(NA, coef(m_narrow)[1], coef(m_metals)[1]),
  se = c(NA, se(m_narrow)[1], se(m_metals)[1]),
  pval = c(NA, pvalue(m_narrow)[1], pvalue(m_metals)[1]),
  N = c(NA, m_narrow$nobs, m_metals$nobs)
)

# Fill baseline from main results
main_res <- fread(paste0(data_dir, "main_results.csv"))
baseline <- main_res[model == "DDD (continuous)" & outcome == "Log Enterprises"]
alt_controls[1, `:=`(coef = baseline$coef, se = baseline$se,
                      pval = baseline$pval, N = baseline$N)]

fwrite(alt_controls, paste0(data_dir, "robustness_alt_controls.csv"))

# ===========================================================================
# 3. Wild Cluster Bootstrap
# ===========================================================================
cat("\n3. Wild cluster bootstrap...\n")

models <- readRDS(paste0(data_dir, "model_objects.rds"))

# WCB for main DDD model
wcb <- tryCatch({
  boottest(models$m2_ent, param = "ddd_2018",
           B = 9999, clustid = "geo", type = "webb")
}, error = function(e) {
  message("  WCB failed: ", e$message)
  NULL
})

if (!is.null(wcb)) {
  wcb_result <- data.table(
    test = "WCB (Webb)",
    pval_wcb = wcb$p_val,
    ci_lower = wcb$conf_int[1],
    ci_upper = wcb$conf_int[2]
  )
  cat("  WCB p-value:", wcb$p_val, "\n")
} else {
  wcb_result <- data.table(
    test = "WCB (Webb)",
    pval_wcb = NA_real_,
    ci_lower = NA_real_,
    ci_upper = NA_real_
  )
}

fwrite(wcb_result, paste0(data_dir, "robustness_wcb.csv"))

# ===========================================================================
# 4. Alternative timing — anticipation and delay
# ===========================================================================
cat("\n4. Alternative timing...\n")

# a) Treatment at 2017 (anticipation — firms may have started adjusting early)
panel[, `:=`(
  ddd_2017 = as.integer(nace_r2 == "C20" & year >= 2017) * micro_share_pre,
  chem_post2017 = as.integer(nace_r2 == "C20" & year >= 2017)
)]
m_2017 <- feols(ln_enterprises ~ ddd_2017 + chem_post2017 |
                  cs_id + cy_id + sy_id,
                data = panel, cluster = ~geo)

# b) Treatment at 2019 (delayed effects)
panel[, `:=`(
  ddd_2019 = as.integer(nace_r2 == "C20" & year >= 2019) * micro_share_pre,
  chem_post2019 = as.integer(nace_r2 == "C20" & year >= 2019)
)]
m_2019 <- feols(ln_enterprises ~ ddd_2019 + chem_post2019 |
                  cs_id + cy_id + sy_id,
                data = panel, cluster = ~geo)

alt_timing <- data.table(
  timing = c("2017 (anticipation)", "2018 (baseline)", "2019 (delayed)"),
  coef = c(coef(m_2017)[1], baseline$coef, coef(m_2019)[1]),
  se = c(se(m_2017)[1], baseline$se, se(m_2019)[1]),
  pval = c(pvalue(m_2017)[1], baseline$pval, pvalue(m_2019)[1])
)

fwrite(alt_timing, paste0(data_dir, "robustness_timing.csv"))
cat("  Timing results:\n")
print(alt_timing)

# ===========================================================================
# 5. Randomization Inference
# ===========================================================================
cat("\n5. Randomization inference...\n")

# Permute micro_share_pre across countries
set.seed(42)
n_perms <- 1000

# Get observed coefficient
obs_coef <- coef(models$m2_ent)["ddd_2018"]

ri_coefs <- sapply(1:n_perms, function(i) {
  # Shuffle micro_share_pre across countries
  perm_map <- data.table(
    geo = unique(panel$geo),
    micro_share_perm = sample(unique(panel$micro_share_pre))
  )
  dt_perm <- merge(panel, perm_map, by = "geo")
  dt_perm[, ddd_2018_perm := as.integer(nace_r2 == "C20" & year >= 2018) * micro_share_perm]

  tryCatch({
    m <- feols(ln_enterprises ~ ddd_2018_perm + chem_post2018 |
                 cs_id + cy_id + sy_id,
               data = dt_perm, cluster = ~geo)
    coef(m)["ddd_2018_perm"]
  }, error = function(e) NA_real_)
})

ri_coefs <- ri_coefs[!is.na(ri_coefs)]
ri_pval <- mean(abs(ri_coefs) >= abs(obs_coef))

ri_result <- data.table(
  observed_coef = obs_coef,
  ri_pval = ri_pval,
  n_permutations = length(ri_coefs),
  ri_mean = mean(ri_coefs),
  ri_sd = sd(ri_coefs)
)

fwrite(ri_result, paste0(data_dir, "robustness_ri.csv"))
fwrite(data.table(coef = ri_coefs), paste0(data_dir, "ri_distribution.csv"))

cat("  RI p-value:", ri_pval, "(", length(ri_coefs), "permutations)\n")

# ===========================================================================
# 6. Size-class heterogeneity
# ===========================================================================
cat("\n6. Size-class heterogeneity...\n")

sc_panel <- fread(paste0(data_dir, "size_class_panel.csv"))

# Run DDD by size class
size_classes <- unique(sc_panel$size_emp)
size_classes <- size_classes[size_classes != "TOTAL"]

sc_results <- rbindlist(lapply(size_classes, function(sz) {
  dt <- sc_panel[size_emp %in% c(sz)]
  dt[, `:=`(
    ddd_2018 = chem * post2018 * micro_share_pre,
    chem_post2018 = chem * post2018,
    cs_id = paste0(geo, "_", nace_r2),
    cy_id = paste0(geo, "_", year),
    sy_id = paste0(nace_r2, "_", year)
  )]
  tryCatch({
    m <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 |
                 cs_id + cy_id + sy_id,
               data = dt, cluster = ~geo)
    data.table(
      size_class = sz,
      coef = coef(m)[1],
      se = se(m)[1],
      pval = pvalue(m)[1],
      N = m$nobs
    )
  }, error = function(e) {
    data.table(size_class = sz, coef = NA, se = NA, pval = NA, N = 0)
  })
}))

fwrite(sc_results, paste0(data_dir, "robustness_size_class.csv"))
cat("  Size class results:\n")
print(sc_results)

# ===========================================================================
# 7. Employment robustness checks
# ===========================================================================
cat("\n7. Employment robustness checks...\n")

# LOO for employment
loo_emp <- rbindlist(lapply(countries, function(cc) {
  dt <- panel[geo != cc]
  tryCatch({
    m <- feols(ln_employment ~ ddd_2018 + chem_post2018 |
                 cs_id + cy_id + sy_id,
               data = dt, cluster = ~geo)
    data.table(dropped = cc, coef = coef(m)[1], se = se(m)[1],
               pval = pvalue(m)[1], N = m$nobs)
  }, error = function(e) {
    data.table(dropped = cc, coef = NA, se = NA, pval = NA, N = 0)
  })
}))
fwrite(loo_emp, paste0(data_dir, "robustness_loo_employment.csv"))
cat("  Employment LOO range:", round(range(loo_emp$coef, na.rm = TRUE), 4), "\n")

# Alt controls for employment
m_narrow_emp <- feols(ln_employment ~ ddd_2018 + chem_post2018 |
                        cs_id + cy_id + sy_id,
                      data = panel[nace_r2 %in% c("C20", "C22", "C23")],
                      cluster = ~geo)
m_metals_emp <- feols(ln_employment ~ ddd_2018 + chem_post2018 |
                        cs_id + cy_id + sy_id,
                      data = panel[nace_r2 %in% c("C20", "C24", "C25")],
                      cluster = ~geo)

alt_controls_emp <- data.table(
  specification = c("Baseline (C22-C25)", "Narrow (C22-C23)", "Metals (C24-C25)"),
  coef = c(coef(models$m2_emp)[1], coef(m_narrow_emp)[1], coef(m_metals_emp)[1]),
  se = c(se(models$m2_emp)[1], se(m_narrow_emp)[1], se(m_metals_emp)[1]),
  pval = c(pvalue(models$m2_emp)[1], pvalue(m_narrow_emp)[1], pvalue(m_metals_emp)[1]),
  N = c(models$m2_emp$nobs, m_narrow_emp$nobs, m_metals_emp$nobs)
)
fwrite(alt_controls_emp, paste0(data_dir, "robustness_alt_controls_emp.csv"))

# Alt timing for employment
m_2017_emp <- feols(ln_employment ~ ddd_2017 + chem_post2017 |
                      cs_id + cy_id + sy_id,
                    data = panel, cluster = ~geo)
m_2019_emp <- feols(ln_employment ~ ddd_2019 + chem_post2019 |
                      cs_id + cy_id + sy_id,
                    data = panel, cluster = ~geo)

alt_timing_emp <- data.table(
  timing = c("2017 (anticipation)", "2018 (baseline)", "2019 (delayed)"),
  coef = c(coef(m_2017_emp)[1], coef(models$m2_emp)[1], coef(m_2019_emp)[1]),
  se = c(se(m_2017_emp)[1], se(models$m2_emp)[1], se(m_2019_emp)[1]),
  pval = c(pvalue(m_2017_emp)[1], pvalue(models$m2_emp)[1], pvalue(m_2019_emp)[1]),
  N = c(m_2017_emp$nobs, models$m2_emp$nobs, m_2019_emp$nobs)
)
fwrite(alt_timing_emp, paste0(data_dir, "robustness_timing_emp.csv"))

# RI for employment
obs_coef_emp <- coef(models$m2_emp)["ddd_2018"]
ri_coefs_emp <- sapply(1:n_perms, function(i) {
  perm_map <- data.table(
    geo = unique(panel$geo),
    micro_share_perm = sample(unique(panel$micro_share_pre))
  )
  dt_perm <- merge(panel, perm_map, by = "geo")
  dt_perm[, ddd_2018_perm := as.integer(nace_r2 == "C20" & year >= 2018) * micro_share_perm]
  tryCatch({
    m <- feols(ln_employment ~ ddd_2018_perm + chem_post2018 |
                 cs_id + cy_id + sy_id,
               data = dt_perm, cluster = ~geo)
    coef(m)["ddd_2018_perm"]
  }, error = function(e) NA_real_)
})
ri_coefs_emp <- ri_coefs_emp[!is.na(ri_coefs_emp)]
ri_pval_emp <- mean(abs(ri_coefs_emp) >= abs(obs_coef_emp))

ri_result_emp <- data.table(
  observed_coef = obs_coef_emp,
  ri_pval = ri_pval_emp,
  n_permutations = length(ri_coefs_emp),
  ri_mean = mean(ri_coefs_emp),
  ri_sd = sd(ri_coefs_emp)
)
fwrite(ri_result_emp, paste0(data_dir, "robustness_ri_emp.csv"))
cat("  Employment RI p-value:", ri_pval_emp, "\n")

# Exclude Croatia (EU member only from 2013)
panel_no_hr <- panel[geo != "HR"]
m_no_hr_emp <- feols(ln_employment ~ ddd_2018 + chem_post2018 |
                       cs_id + cy_id + sy_id,
                     data = panel_no_hr, cluster = ~geo)
m_no_hr_ent <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 |
                       cs_id + cy_id + sy_id,
                     data = panel_no_hr, cluster = ~geo)
cat("  Excluding Croatia: enterprises =", round(coef(m_no_hr_ent)[1], 4),
    ", employment =", round(coef(m_no_hr_emp)[1], 4), "\n")

excl_hr <- data.table(
  outcome = c("Log Enterprises", "Log Employment"),
  coef = c(coef(m_no_hr_ent)[1], coef(m_no_hr_emp)[1]),
  se = c(se(m_no_hr_ent)[1], se(m_no_hr_emp)[1]),
  pval = c(pvalue(m_no_hr_ent)[1], pvalue(m_no_hr_emp)[1]),
  N = c(m_no_hr_ent$nobs, m_no_hr_emp$nobs)
)
fwrite(excl_hr, paste0(data_dir, "robustness_excl_croatia.csv"))

# ===========================================================================
# 8. Drop 2020 (COVID) and shorter windows
# ===========================================================================
cat("\n8. Drop 2020 and shorter windows...\n")

# Drop 2020 entirely
panel_no2020 <- panel[year <= 2019]
m_no2020_ent <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 |
                        cs_id + cy_id + sy_id,
                      data = panel_no2020, cluster = ~geo)
m_no2020_emp <- feols(ln_employment ~ ddd_2018 + chem_post2018 |
                        cs_id + cy_id + sy_id,
                      data = panel_no2020, cluster = ~geo)

cat("  Drop 2020: enterprises =", round(coef(m_no2020_ent)[1], 4),
    ", employment =", round(coef(m_no2020_emp)[1], 4), "\n")

# Shorter window: 2014-2019
panel_short <- panel[year >= 2014 & year <= 2019]
panel_short[, `:=`(
  cs_id = paste0(geo, "_", nace_r2),
  cy_id = paste0(geo, "_", year),
  sy_id = paste0(nace_r2, "_", year)
)]
m_short_ent <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 |
                       cs_id + cy_id + sy_id,
                     data = panel_short, cluster = ~geo)
m_short_emp <- feols(ln_employment ~ ddd_2018 + chem_post2018 |
                       cs_id + cy_id + sy_id,
                     data = panel_short, cluster = ~geo)

cat("  Short window (2014-2019): enterprises =", round(coef(m_short_ent)[1], 4),
    ", employment =", round(coef(m_short_emp)[1], 4), "\n")

window_results <- data.table(
  specification = c("Baseline (2008-2020)", "Drop 2020 (2008-2019)",
                     "Short window (2014-2019)"),
  ent_coef = c(coef(models$m2_ent)[1], coef(m_no2020_ent)[1], coef(m_short_ent)[1]),
  ent_se = c(se(models$m2_ent)[1], se(m_no2020_ent)[1], se(m_short_ent)[1]),
  ent_pval = c(pvalue(models$m2_ent)[1], pvalue(m_no2020_ent)[1], pvalue(m_short_ent)[1]),
  emp_coef = c(coef(models$m2_emp)[1], coef(m_no2020_emp)[1], coef(m_short_emp)[1]),
  emp_se = c(se(models$m2_emp)[1], se(m_no2020_emp)[1], se(m_short_emp)[1]),
  emp_pval = c(pvalue(models$m2_emp)[1], pvalue(m_no2020_emp)[1], pvalue(m_short_emp)[1]),
  ent_N = c(models$m2_ent$nobs, m_no2020_ent$nobs, m_short_ent$nobs),
  emp_N = c(models$m2_emp$nobs, m_no2020_emp$nobs, m_short_emp$nobs)
)
fwrite(window_results, paste0(data_dir, "robustness_windows.csv"))

# ===========================================================================
# Summary
# ===========================================================================
cat("\n=== ROBUSTNESS SUMMARY ===\n")
cat("Enterprises:\n")
cat("  LOO range:", round(range(loo_results$coef), 4), "\n")
cat("  Alt controls: narrow =", round(coef(m_narrow)[1], 4),
    ", metals =", round(coef(m_metals)[1], 4), "\n")
cat("  RI p-value:", ri_pval, "\n")
cat("Employment:\n")
cat("  LOO range:", round(range(loo_emp$coef, na.rm = TRUE), 4), "\n")
cat("  Alt controls: narrow =", round(coef(m_narrow_emp)[1], 4),
    ", metals =", round(coef(m_metals_emp)[1], 4), "\n")
cat("  RI p-value:", ri_pval_emp, "\n")
cat("Robustness checks complete.\n")

# Save robustness model objects
saveRDS(list(
  m_narrow = m_narrow, m_metals = m_metals,
  m_2017 = m_2017, m_2019 = m_2019,
  m_narrow_emp = m_narrow_emp, m_metals_emp = m_metals_emp,
  m_2017_emp = m_2017_emp, m_2019_emp = m_2019_emp,
  m_no_hr_ent = m_no_hr_ent, m_no_hr_emp = m_no_hr_emp
), paste0(data_dir, "robustness_models.rds"))
