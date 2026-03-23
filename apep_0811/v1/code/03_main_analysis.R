# 03_main_analysis.R — Triple-DiD estimation
# England vs Scotland × Food Service vs Placebo × Pre vs Post April 2022

source("00_packages.R")

panel <- fread("../data/panel.csv")
panel[, inc_month := as.Date(inc_month)]

# Create factor variables for fixed effects
panel[, cs := paste0(country, "_", sector)]   # country-sector FE
panel[, ct := paste0(country, "_", inc_month)] # country-month FE
panel[, st := paste0(sector, "_", inc_month)]  # sector-month FE

cat("=== MAIN ANALYSIS: TRIPLE-DIFFERENCE ===\n\n")

# ---------------------------------------------------------------
# Summary Statistics (pre-treatment)
# ---------------------------------------------------------------
cat("--- Summary Statistics (Pre-treatment: Jan 2019 - Mar 2022) ---\n")
pre <- panel[post == 0]
sumstats <- pre[, .(
  Mean = round(mean(incorporations), 1),
  SD = round(sd(incorporations), 1),
  Min = min(incorporations),
  Max = max(incorporations),
  N_months = .N
), by = .(country, sector)]
setorder(sumstats, sector, country)
print(sumstats)

# Overall SD for SDE computation
sd_log_inc_all <- sd(panel$log_inc)
cat(sprintf("\nSD(log_inc) overall: %.4f\n", sd_log_inc_all))

# ---------------------------------------------------------------
# MAIN SPECIFICATION: Triple-DiD, all 6 sectors
# Uses cs + ct + st fixed effects (1008 obs, ~684 FE → 324 DF)
# ---------------------------------------------------------------
cat("\n--- Main Model: Triple-DiD (All 6 Sectors) ---\n")

m1 <- feols(log_inc ~ treat_ddd | cs + ct + st,
            data = panel, vcov = "hetero")

cat(sprintf("  β(England × FoodService × Post) = %.4f\n", coef(m1)["treat_ddd"]))
cat(sprintf("  SE (robust) = %.4f\n", se(m1)["treat_ddd"]))
cat(sprintf("  95%% CI: [%.4f, %.4f]\n",
            coef(m1)["treat_ddd"] - 1.96 * se(m1)["treat_ddd"],
            coef(m1)["treat_ddd"] + 1.96 * se(m1)["treat_ddd"]))

# ---------------------------------------------------------------
# ALTERNATIVE SPECS for Table 2
# ---------------------------------------------------------------

# Spec 2: Poisson (count data)
m2 <- fepois(incorporations ~ treat_ddd | cs + ct + st,
             data = panel, vcov = "hetero")

# Spec 3: OLS without sector × time FE (less saturated)
panel[, ym := as.factor(format(inc_month, "%Y-%m"))]
m3 <- feols(log_inc ~ treat_ddd + england:post + food:post | cs + ym,
            data = panel, vcov = "hetero")

# Spec 4: Leave out retail from placebo pool
panel_no_ret <- panel[sector != "Retail"]
m4 <- feols(log_inc ~ treat_ddd | cs + ct + st,
            data = panel_no_ret, vcov = "hetero")

# Spec 5: Leave out real estate from placebo pool
panel_no_re <- panel[sector != "RealEstate"]
m5 <- feols(log_inc ~ treat_ddd | cs + ct + st,
            data = panel_no_re, vcov = "hetero")

cat("\n--- Main Results Table ---\n")
etable(m1, m2, m3, m4, m5,
       headers = c("OLS (Main)", "Poisson", "Simple FE", "Drop Retail", "Drop RE"),
       se.below = TRUE, fitstat = ~ n + r2)

# ---------------------------------------------------------------
# EVENT STUDY: Dynamic Triple-Diff (Quarterly bins)
# ---------------------------------------------------------------
cat("\n--- Event Study ---\n")

treatment_date <- as.Date("2022-04-01")
panel[, quarter_rel := as.integer(
  (year(inc_month) - year(treatment_date)) * 4 +
  (quarter(inc_month) - quarter(treatment_date))
)]

# Bin endpoints at ±8 quarters
panel[, qrel_bin := fcase(
  quarter_rel < -8, -8L,
  quarter_rel > 8, 8L,
  default = as.integer(quarter_rel)
)]

panel[, es_treat := england * food]

m_es <- feols(log_inc ~ i(qrel_bin, es_treat, ref = -1) | cs + ct + st,
              data = panel, vcov = "hetero")

cat("Event study coefficients:\n")
ct_es <- coeftable(m_es)
print(ct_es)

# Pre-trend test: joint F-test on pre-treatment coefficients
pre_coefs <- grep(":-[2-9]|:-1[0-9]", rownames(ct_es), value = TRUE)
if (length(pre_coefs) > 0) {
  wald_pre <- wald(m_es, keep = pre_coefs, print = FALSE)
  cat(sprintf("\nPre-trend joint F-test: F = %.3f, p = %.4f\n",
              wald_pre$stat, wald_pre$p))
}

# ---------------------------------------------------------------
# DISSOLUTIONS: Only run on cells with variation
# ---------------------------------------------------------------
cat("\n--- Dissolutions ---\n")

panel[, log_dis := log(dissolutions + 1)]

# Check for variation
cat("Dissolution summary by country-sector:\n")
dis_sum <- panel[, .(mean_dis = mean(dissolutions),
                     sd_dis = sd(dissolutions),
                     pct_zero = mean(dissolutions == 0) * 100),
                 by = .(country, sector)]
print(dis_sum[order(sector, country)])

if (sd(panel$dissolutions) > 0.1 && mean(panel$dissolutions > 0) > 0.3) {
  m_dis <- feols(log_dis ~ treat_ddd | cs + ct + st,
                 data = panel, vcov = "hetero")
  cat(sprintf("\nDissolution DDD: β = %.4f (SE = %.4f)\n",
              coef(m_dis)["treat_ddd"], se(m_dis)["treat_ddd"]))
} else {
  cat("\nDissolution data is all zeros in Companies House snapshot.\n")
  cat("(Bulk CSV only contains active companies; dissolved companies absent.)\n")
  cat("Dropping dissolution/exit analysis.\n")
  m_dis <- NULL
}

# (Net entry analysis omitted: dissolution data not available in bulk snapshot)

# ---------------------------------------------------------------
# Save all objects
# ---------------------------------------------------------------
m_net <- NULL
save(m1, m2, m3, m4, m5, m_es, m_dis, m_net, panel,
     sd_log_inc_all, sumstats,
     file = "../data/main_results.RData")

# ---------------------------------------------------------------
# Diagnostics for validator
# ---------------------------------------------------------------
diagnostics <- list(
  n_treated = nrow(panel[england == 1 & food == 1]),
  n_pre = uniqueN(panel[post == 0, inc_month]),
  n_obs = nrow(panel)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\nMain analysis complete.\n")
