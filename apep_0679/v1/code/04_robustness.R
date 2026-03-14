## 04_robustness.R — Robustness checks
## apep_0679: Apprenticeship Levy and Entry-Level Training Crowding Out

source("00_packages.R")

paper_dir <- dirname(getwd())
data_dir <- file.path(paper_dir, "data")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# ==============================================================================
# 1. Randomization Inference
# ==============================================================================
cat("=== Randomization Inference ===\n")

set.seed(42)
n_perms <- 500

true_coef <- coef(feols(log_starts ~ levy_x_post | la_code + acad_year,
                         data = panel, cluster = ~la_code))[[1]]

la_exposure <- unique(panel[, .(la_code, levy_exposure)])
perm_coefs <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  perm_map <- data.table(la_code = la_exposure$la_code,
                          levy_perm = sample(la_exposure$levy_exposure))
  panel_perm <- merge(panel, perm_map, by = "la_code")
  panel_perm[, lxp_perm := levy_perm * post_levy]

  perm_coefs[i] <- tryCatch(
    coef(feols(log_starts ~ lxp_perm | la_code + acad_year,
               data = panel_perm))[[1]],
    error = function(e) NA_real_
  )
  if (i %% 100 == 0) cat(sprintf("  Permutation %d/%d\n", i, n_perms))
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_pvalue <- mean(abs(perm_coefs) >= abs(true_coef))
cat(sprintf("RI p-value: %.4f (true=%.4f, perm_sd=%.4f)\n",
            ri_pvalue, true_coef, sd(perm_coefs)))

# ==============================================================================
# 2. Leave-One-Out
# ==============================================================================
cat("\n=== Leave-One-Out ===\n")

top_las <- panel[post_levy == 0, .(total = sum(starts)), by = la_code]
setorder(top_las, -total)
top5 <- head(top_las$la_code, 5)

loo_results <- lapply(top5, function(la) {
  m <- feols(log_starts ~ levy_x_post | la_code + acad_year,
             data = panel[la_code != la], cluster = ~la_code)
  data.table(dropped_la = la,
             dropped_name = unique(panel[la_code == la]$la_name),
             coef = coef(m)[[1]], se = se(m)[[1]], pval = pvalue(m)[[1]])
})
loo_dt <- rbindlist(loo_results)
print(loo_dt)

# ==============================================================================
# 3. Alternative Exposure Year (2015)
# ==============================================================================
cat("\n=== Alternative Exposure (2015) ===\n")

biz_2015 <- fread(file.path(data_dir, "nomis_business_counts_2015.csv"))
biz_2015_wide <- dcast(biz_2015, GEOGRAPHY_CODE ~ EMPLOYMENT_SIZEBAND_NAME,
                        value.var = "OBS_VALUE")

if ("Total" %in% names(biz_2015_wide) && "Large (250+)" %in% names(biz_2015_wide)) {
  biz_2015_wide[, levy_2015 := `Large (250+)` / Total]
  biz_2015_wide[is.na(levy_2015) | is.infinite(levy_2015), levy_2015 := 0]

  panel_alt <- merge(panel, biz_2015_wide[, .(la_code = GEOGRAPHY_CODE, levy_2015)],
                     by = "la_code", all.x = TRUE)
  panel_alt[, lxp_2015 := levy_2015 * post_levy]

  m_alt <- feols(log_starts ~ lxp_2015 | la_code + acad_year,
                 data = panel_alt[!is.na(levy_2015)], cluster = ~la_code)
  cat(sprintf("2015 exposure: beta=%.4f, se=%.4f, p=%.4f\n",
              coef(m_alt)[[1]], se(m_alt)[[1]], pvalue(m_alt)[[1]]))
} else {
  cat("  2015 data not available in expected format.\n")
  m_alt <- NULL
}

# ==============================================================================
# 4. Drop Partial Year (2019/20 — COVID truncated)
# ==============================================================================
cat("\n=== Drop Partial Year ===\n")

m_no2019 <- feols(log_starts ~ levy_x_post | la_code + acad_year,
                  data = panel[acad_year != 2019], cluster = ~la_code)
cat(sprintf("Drop 2019/20: beta=%.4f, se=%.4f, p=%.4f\n",
            coef(m_no2019)[[1]], se(m_no2019)[[1]], pvalue(m_no2019)[[1]]))

# ==============================================================================
# 5. Trim Extreme Exposure
# ==============================================================================
cat("\n=== Trim Extreme Exposure ===\n")

p5 <- quantile(panel$levy_exposure, 0.05)
p95 <- quantile(panel$levy_exposure, 0.95)
m_trim <- feols(log_starts ~ levy_x_post | la_code + acad_year,
                data = panel[levy_exposure >= p5 & levy_exposure <= p95],
                cluster = ~la_code)
cat(sprintf("Trimmed (5-95%%): beta=%.4f, se=%.4f, p=%.4f\n",
            coef(m_trim)[[1]], se(m_trim)[[1]], pvalue(m_trim)[[1]]))

# ==============================================================================
# 6. Save results
# ==============================================================================
saveRDS(list(
  ri_pvalue = ri_pvalue, perm_coefs = perm_coefs, true_coef = true_coef,
  loo_dt = loo_dt,
  m_no2019 = m_no2019,
  m_trim = m_trim
), file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness complete ===\n")
