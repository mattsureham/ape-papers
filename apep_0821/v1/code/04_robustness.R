## 04_robustness.R — Robustness checks and mechanism tests
## Paper: The Bureaucrat's Bonus (apep_0821)

source("code/00_packages.R")

panel <- fread("data/analysis_panel.csv")
panel[, gov_trend := gov_emp_share * (year - 2007)]
panel[, pop_trend := log(pop + 1) * year]

cat("=== ROBUSTNESS CHECKS ===\n\n")

## ── R1: De-trended with asinh outcome ──
cat("--- R1: De-trended with asinh ---\n")
r1 <- feols(asinh_light ~ treat_x_post + gov_trend | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)
cat(sprintf("asinh de-trended: %.4f (%.4f)\n",
            coef(r1)["treat_x_post"], se(r1)["treat_x_post"]))

## ── R2: Exclude saturated nightlights ──
cat("\n--- R2: Exclude saturated districts ---\n")
panel[, max_light := max(dmsp_total_light_cal, na.rm = TRUE), by = district_id]
panel_nosaturate <- panel[max_light < quantile(dmsp_total_light_cal, 0.99, na.rm = TRUE)]
r2 <- feols(log_light ~ treat_x_post + gov_trend | district_id + state_year,
            data = panel_nosaturate, cluster = ~pc11_state_id)
cat(sprintf("Excluding saturated (de-trended): %.4f (%.4f), N=%d\n",
            coef(r2)["treat_x_post"], se(r2)["treat_x_post"], nrow(panel_nosaturate)))

## ── R3: Binary treatment (top quartile), de-trended ──
cat("\n--- R3: Binary treatment (top quartile) ---\n")
q75 <- quantile(panel$gov_emp_share, 0.75, na.rm = TRUE)
panel[, high_gov := as.integer(gov_emp_share >= q75)]
panel[, high_gov_post := high_gov * post]
panel[, high_gov_trend := high_gov * (year - 2007)]
r3 <- feols(log_light ~ high_gov_post + high_gov_trend | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)
cat(sprintf("High gov × Post (de-trended): %.4f (%.4f)\n",
            coef(r3)["high_gov_post"], se(r3)["high_gov_post"]))

## ── R4: Placebo timing — 2005 as fake treatment year ──
cat("\n--- R4: Placebo timing (2005) ---\n")
panel_pre <- panel[year <= 2007]
panel_pre[, fake_post := as.integer(year >= 2005)]
panel_pre[, fake_treat := gov_emp_share * fake_post]
r4 <- feols(log_light ~ fake_treat | district_id + state_year,
            data = panel_pre, cluster = ~pc11_state_id)
cat(sprintf("Fake 2005 treatment: %.4f (%.4f)\n",
            coef(r4)["fake_treat"], se(r4)["fake_treat"]))

## ── R5: First-difference specification ──
cat("\n--- R5: First difference ---\n")
setorder(panel, district_id, year)
panel[, d_log_light := log_light - shift(log_light, 1), by = district_id]
panel[, d_treat_post := treat_x_post - shift(treat_x_post, 1), by = district_id]
r5 <- feols(d_log_light ~ d_treat_post | state_year,
            data = panel[!is.na(d_log_light)], cluster = ~pc11_state_id)
cat(sprintf("First difference: %.4f (%.4f)\n",
            coef(r5)["d_treat_post"], se(r5)["d_treat_post"]))

## ── R6: Long-difference firm counts (EC 2013 vs EC 2005) ──
cat("\n--- R6: Long-difference firm counts ---\n")
ec05 <- fread("data/ec05_pc11_district.csv")
ec05[, gov_emp_share := ec05_emp_gov / ec05_emp_all]
ec13_raw <- fread("data/ec13_district.csv")
ec13_raw[, pc11_state_id := as.integer(pc11_state_id)]
ec13_raw[, pc11_district_id := as.integer(pc11_district_id)]

ec_cross <- merge(ec05[, .(pc11_state_id, pc11_district_id,
                            emp05 = ec05_emp_all, gov05 = ec05_emp_gov,
                            firms05 = ec05_count_all, services05 = ec05_emp_services,
                            gov_emp_share)],
                  ec13_raw[, .(pc11_state_id, pc11_district_id,
                               emp13 = ec13_emp_all, firms13 = ec13_count_all,
                               services13 = ec13_emp_services)],
                  by = c("pc11_state_id", "pc11_district_id"))

ec_cross[, d_log_emp := log(emp13 + 1) - log(emp05 + 1)]
ec_cross[, d_log_firms := log(firms13 + 1) - log(firms05 + 1)]
ec_cross[, d_log_services := log(services13 + 1) - log(services05 + 1)]

r6a <- lm(d_log_emp ~ gov_emp_share, data = ec_cross)
r6b <- lm(d_log_firms ~ gov_emp_share, data = ec_cross)
r6c <- lm(d_log_services ~ gov_emp_share, data = ec_cross)
cat(sprintf("Δlog(employment): β=%.4f (se=%.4f)\n",
            coef(r6a)[2], summary(r6a)$coef[2, 2]))
cat(sprintf("Δlog(firms): β=%.4f (se=%.4f)\n",
            coef(r6b)[2], summary(r6b)$coef[2, 2]))
cat(sprintf("Δlog(services): β=%.4f (se=%.4f)\n",
            coef(r6c)[2], summary(r6c)$coef[2, 2]))

## ── Save robustness results ──
rob <- list(
  r1_asinh_coef = coef(r1)["treat_x_post"],
  r1_asinh_se = se(r1)["treat_x_post"],
  r2_nosaturate_coef = coef(r2)["treat_x_post"],
  r2_nosaturate_se = se(r2)["treat_x_post"],
  r3_binary_coef = coef(r3)["high_gov_post"],
  r3_binary_se = se(r3)["high_gov_post"],
  r4_placebo_timing_coef = coef(r4)["fake_treat"],
  r4_placebo_timing_se = se(r4)["fake_treat"],
  r5_fd_coef = coef(r5)["d_treat_post"],
  r5_fd_se = se(r5)["d_treat_post"],
  r6a_demp_coef = coef(r6a)[2],
  r6a_demp_se = summary(r6a)$coef[2, 2],
  r6b_dfirm_coef = coef(r6b)[2],
  r6b_dfirm_se = summary(r6b)$coef[2, 2],
  r6c_dserv_coef = coef(r6c)[2],
  r6c_dserv_se = summary(r6c)$coef[2, 2],
  r2_n = nrow(panel_nosaturate),
  ec_cross_n = nrow(ec_cross)
)
saveRDS(rob, "data/robustness_results.rds")
cat("\nSaved: data/robustness_results.rds\n")
