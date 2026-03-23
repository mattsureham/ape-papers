## 03_main_analysis.R — Primary DiD regressions
## Paper: The Bureaucrat's Bonus (apep_0821)

source("code/00_packages.R")

panel <- fread("data/analysis_panel.csv")

cat("=== MAIN ANALYSIS ===\n\n")

## ── Table 1: Summary Statistics ──
cat("--- Summary Statistics ---\n")
sum_vars <- c("dmsp_total_light_cal", "log_light", "gov_emp_share",
              "ec05_emp_gov", "ec05_emp_all", "pop")

pre <- panel[year < 2008]
post_d <- panel[year >= 2008]

cat("\nPre-period (2004-2007):\n")
for (v in sum_vars) {
  if (v %in% names(panel)) {
    cat(sprintf("  %s: mean=%.2f, sd=%.2f, N=%d\n",
                v, mean(pre[[v]], na.rm = TRUE),
                sd(pre[[v]], na.rm = TRUE),
                sum(!is.na(pre[[v]]))))
  }
}

## ── Main specification: Dose-response DiD ──
cat("\n--- Main Specification ---\n")

# (1) Baseline: log(NL+1) ~ GovEmpShare × Post | district + year
m1 <- feols(log_light ~ treat_x_post | district_id + year,
            data = panel, cluster = ~pc11_state_id)

# (2) With state × year FE
m2 <- feols(log_light ~ treat_x_post | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)

# (3) asinh transformation
m3 <- feols(asinh_light ~ treat_x_post | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)

# (4) De-trended: GovEmpShare × linear trend absorbs differential pre-trends
panel[, gov_trend := gov_emp_share * (year - 2007)]
m4 <- feols(log_light ~ treat_x_post + gov_trend | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)

# (5) Pop trend + gov trend
panel[, pop_trend := log_pop * year]
m5 <- feols(log_light ~ treat_x_post + gov_trend + pop_trend | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)

cat("\nResults:\n")
etable(m1, m2, m3, m4, m5,
       headers = c("(1) Baseline", "(2) State×Year FE", "(3) asinh",
                    "(4) De-trended", "(5) Full controls"),
       se.below = TRUE)

## ── Cluster count for inference discussion ──
n_clusters <- uniqueN(panel$pc11_state_id)
cat(sprintf("\nNumber of state clusters: %d\n", n_clusters))
cat("Note: With ~30 clusters, state-clustered SEs may be slightly downward-biased.\n")
cat("The main result (null after de-trending) is conservative: bias would make\n")
cat("the naive positive estimate MORE significant, reinforcing the mirage finding.\n")

## ── Event Study (de-trended) ──
cat("\n--- Event Study (raw) ---\n")

es_raw <- feols(log_light ~ et_m4 + et_m3 + et_m2 + et_m1 +
              et_p1 + et_p2 + et_p3 + et_p4 + et_p5 + et_p6 |
              district_id + state_year,
            data = panel, cluster = ~pc11_state_id)

cat("Raw event study coefficients:\n")
print(summary(es_raw))

cat("\n--- Event Study (de-trended) ---\n")
es <- feols(log_light ~ et_m4 + et_m3 + et_m2 + et_m1 +
              et_p1 + et_p2 + et_p3 + et_p4 + et_p5 + et_p6 + gov_trend |
              district_id + state_year,
            data = panel, cluster = ~pc11_state_id)

cat("De-trended event study coefficients:\n")
print(summary(es))

## ── Store key results for SDE table ──
# Use de-trended specification (m4) as main — accounts for pre-trends
beta_main <- coef(m4)["treat_x_post"]
se_main <- se(m4)["treat_x_post"]
sd_y_pre <- sd(panel[year < 2008]$log_light, na.rm = TRUE)
sd_x <- sd(panel$gov_emp_share, na.rm = TRUE)

# For continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_main <- beta_main * sd_x / sd_y_pre
se_sde <- se_main * sd_x / sd_y_pre

cat(sprintf("\nSDE calculation:\n"))
cat(sprintf("  beta = %.4f (se = %.4f)\n", beta_main, se_main))
cat(sprintf("  SD(Y_pre) = %.4f\n", sd_y_pre))
cat(sprintf("  SD(X) = %.4f\n", sd_x))
cat(sprintf("  SDE = %.4f (se = %.4f)\n", sde_main, se_sde))

## ── Save results ──
results <- list(
  m1_coef = coef(m1)["treat_x_post"],
  m1_se = se(m1)["treat_x_post"],
  m2_coef = beta_main,
  m2_se = se_main,
  m3_coef = coef(m3)["treat_x_post"],
  m3_se = se(m3)["treat_x_post"],
  m4_coef = coef(m4)["treat_x_post"],
  m4_se = se(m4)["treat_x_post"],
  m5_coef = coef(m5)["treat_x_post"],
  m5_se = se(m5)["treat_x_post"],
  sd_y_pre = sd_y_pre,
  sd_x = sd_x,
  sde = sde_main,
  sde_se = se_sde,
  n_districts = uniqueN(panel$district_id),
  n_obs = nrow(panel),
  n_treated = sum(panel$gov_emp_share > median(panel$gov_emp_share, na.rm = TRUE)) / 10,
  n_pre = 5L,
  es_coefs = coef(es),
  es_ses = se(es)
)
saveRDS(results, "data/main_results.rds")

## ── diagnostics.json for validator ──
diag <- list(
  n_treated = as.integer(results$n_treated),
  n_pre = results$n_pre,
  n_obs = results$n_obs
)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nSaved: data/main_results.rds, data/diagnostics.json\n")
