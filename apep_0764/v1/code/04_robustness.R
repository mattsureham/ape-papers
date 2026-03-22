# 04_robustness.R — Robustness checks and placebos
# apep_0764: Brazil Intermittent Contracts

source("00_packages.R")

cat("Loading clean panel...\n")
panel <- fread("../data/panel_clean.csv")
panel[, muni_code := as.character(muni_code)]
panel[, state_code := as.character(state_code)]

# =============================================================================
# 1. ALTERNATIVE CLUSTERING
# =============================================================================
cat("Robustness 1: Alternative clustering (municipality level)...\n")

r1_wage_muni <- feols(log_avg_wage ~ bartik_exposure:post |
                        muni_code + year,
                      data = panel,
                      cluster = ~muni_code,
                      weights = ~total_emp_2016)

cat("  Municipality-clustered SE on wage interaction: ",
    sprintf("%.4f (vs state-clustered)\n",
            summary(r1_wage_muni)$se[1]))

# =============================================================================
# 2. UNWEIGHTED SPECIFICATION
# =============================================================================
cat("Robustness 2: Unweighted regression...\n")

r2_wage_unw <- feols(log_avg_wage ~ bartik_exposure:post |
                       muni_code + year,
                     data = panel,
                     cluster = ~state_code)

r2_emp_unw <- feols(log_employment ~ bartik_exposure:post |
                      muni_code + year,
                    data = panel,
                    cluster = ~state_code)

cat(sprintf("  Unweighted wage coef: %.4f (SE: %.4f)\n",
            coef(r2_wage_unw), summary(r2_wage_unw)$se[1]))
cat(sprintf("  Unweighted employment coef: %.4f (SE: %.4f)\n",
            coef(r2_emp_unw), summary(r2_emp_unw)$se[1]))

# =============================================================================
# 3. EXCLUDING EXTREME EXPOSURE MUNICIPALITIES
# =============================================================================
cat("Robustness 3: Trimming top/bottom 5% of exposure...\n")

p05 <- quantile(panel$bartik_exposure, 0.05)
p95 <- quantile(panel$bartik_exposure, 0.95)
panel_trimmed <- panel[bartik_exposure >= p05 & bartik_exposure <= p95]

r3_wage_trim <- feols(log_avg_wage ~ bartik_exposure:post |
                        muni_code + year,
                      data = panel_trimmed,
                      cluster = ~state_code,
                      weights = ~total_emp_2016)

r3_emp_trim <- feols(log_employment ~ bartik_exposure:post |
                       muni_code + year,
                     data = panel_trimmed,
                     cluster = ~state_code,
                     weights = ~total_emp_2016)

cat(sprintf("  Trimmed sample: %d municipalities\n", uniqueN(panel_trimmed$muni_code)))
cat(sprintf("  Trimmed wage coef: %.4f (SE: %.4f)\n",
            coef(r3_wage_trim), summary(r3_wage_trim)$se[1]))

# =============================================================================
# 4. PLACEBO TEST: PRE-REFORM SECTOR GROWTH AS FAKE EXPOSURE
# =============================================================================
cat("Robustness 4: Placebo exposure (pre-reform sector employment growth 2014-2016)...\n")

rais_raw <- fread("../data/rais_muni_cnae2_year.csv")
rais_raw[, muni_code := as.character(muni_code)]

# Compute pre-reform sector growth rates
sector_growth <- rais_raw[year %in% c(2014, 2016),
  .(total_workers = sum(n_workers)),
  by = .(cnae2, year)
]
sector_growth_wide <- dcast(sector_growth, cnae2 ~ year, value.var = "total_workers")
setnames(sector_growth_wide, c("2014", "2016"), c("emp_2014", "emp_2016"))
sector_growth_wide[, growth_rate := (emp_2016 - emp_2014) / emp_2014]
sector_growth_wide <- sector_growth_wide[is.finite(growth_rate)]

# Construct placebo Bartik exposure using growth rates instead of intermittent rates
muni_struct <- fread("../data/panel_clean.csv")[year == 2016, .(muni_code = as.character(muni_code))]
rais_2016 <- rais_raw[year == 2016]
rais_2016[, muni_code := as.character(muni_code)]

muni_struct_full <- rais_2016[, .(emp_2016 = sum(n_workers)), by = .(muni_code, cnae2)]
muni_total <- muni_struct_full[, .(total = sum(emp_2016)), by = muni_code]
muni_struct_full <- merge(muni_struct_full, muni_total, by = "muni_code")
muni_struct_full[, share := emp_2016 / total]

placebo_exp <- merge(muni_struct_full, sector_growth_wide[, .(cnae2, growth_rate)],
                     by = "cnae2", all.x = TRUE)
placebo_exp[is.na(growth_rate), growth_rate := 0]
placebo_bartik <- placebo_exp[, .(placebo_exposure = sum(share * growth_rate)), by = muni_code]

panel_placebo <- merge(panel, placebo_bartik, by = "muni_code", all.x = TRUE)
panel_placebo <- panel_placebo[!is.na(placebo_exposure)]

r4_placebo <- feols(log_avg_wage ~ placebo_exposure:post |
                      muni_code + year,
                    data = panel_placebo,
                    cluster = ~state_code,
                    weights = ~total_emp_2016)

cat(sprintf("  Placebo exposure coef: %.4f (SE: %.4f, p: %.3f)\n",
            coef(r4_placebo), summary(r4_placebo)$se[1],
            fixest::pvalue(r4_placebo)[1]))

# =============================================================================
# 5. EXCLUDING COVID YEARS (2020-2021)
# =============================================================================
cat("Robustness 5: Excluding COVID years (2020-2021)...\n")

panel_nocovid <- panel[!(year %in% c(2020, 2021))]

r5_wage_nocovid <- feols(log_avg_wage ~ bartik_exposure:post |
                           muni_code + year,
                         data = panel_nocovid,
                         cluster = ~state_code,
                         weights = ~total_emp_2016)

r5_emp_nocovid <- feols(log_employment ~ bartik_exposure:post |
                          muni_code + year,
                        data = panel_nocovid,
                        cluster = ~state_code,
                        weights = ~total_emp_2016)

cat(sprintf("  No-COVID wage coef: %.4f (SE: %.4f)\n",
            coef(r5_wage_nocovid), summary(r5_wage_nocovid)$se[1]))
cat(sprintf("  No-COVID employment coef: %.4f (SE: %.4f)\n",
            coef(r5_emp_nocovid), summary(r5_emp_nocovid)$se[1]))

# =============================================================================
# 6. SAVE ROBUSTNESS RESULTS
# =============================================================================
saveRDS(list(
  r1_wage_muni = r1_wage_muni,
  r2_wage_unw = r2_wage_unw,
  r2_emp_unw = r2_emp_unw,
  r3_wage_trim = r3_wage_trim,
  r3_emp_trim = r3_emp_trim,
  r4_placebo = r4_placebo,
  r5_wage_nocovid = r5_wage_nocovid,
  r5_emp_nocovid = r5_emp_nocovid
), "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
