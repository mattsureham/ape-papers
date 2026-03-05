# ============================================================================
# 06_tables.R — Generate all LaTeX tables from saved data
# APEP-0525: Tax Borders and the Rich
# ============================================================================

source("00_packages.R")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

summ <- fread(file.path(DATA_DIR, "summary_stats.csv"))

tab1 <- data.table(
  Variable = c("ZIP-code$\\times$year observations",
               "Unique ZIP codes",
               "Mean total returns per ZIP",
               "Mean share AGI $\\geq$ \\$200K",
               "SD share AGI $\\geq$ \\$200K",
               "Mean high-income returns per ZIP",
               "Mean share AGI $<$ \\$50K",
               "Mean AGI per high-income return (\\$K)",
               "Mean distance to border (km)",
               "Share suppressed ZIPs"),
  `High-Tax Side` = c(
    format(summ[side == "High-Tax Side", n_zip_years], big.mark = ","),
    format(summ[side == "High-Tax Side", n_zips], big.mark = ","),
    round(summ[side == "High-Tax Side", mean_total_returns], 0),
    round(summ[side == "High-Tax Side", mean_high_share], 4),
    round(summ[side == "High-Tax Side", sd_high_share], 4),
    round(summ[side == "High-Tax Side", mean_high_returns], 1),
    round(summ[side == "High-Tax Side", mean_low_share], 4),
    round(summ[side == "High-Tax Side", mean_avg_agi_high], 1),
    round(summ[side == "High-Tax Side", mean_dist_km], 1),
    round(summ[side == "High-Tax Side", pct_suppressed], 3)
  ),
  `Low-Tax Side` = c(
    format(summ[side == "Low-Tax Side", n_zip_years], big.mark = ","),
    format(summ[side == "Low-Tax Side", n_zips], big.mark = ","),
    round(summ[side == "Low-Tax Side", mean_total_returns], 0),
    round(summ[side == "Low-Tax Side", mean_high_share], 4),
    round(summ[side == "Low-Tax Side", sd_high_share], 4),
    round(summ[side == "Low-Tax Side", mean_high_returns], 1),
    round(summ[side == "Low-Tax Side", mean_low_share], 4),
    round(summ[side == "Low-Tax Side", mean_avg_agi_high], 1),
    round(summ[side == "Low-Tax Side", mean_dist_km], 1),
    round(summ[side == "Low-Tax Side", pct_suppressed], 3)
  )
)

cat("\\begin{table}[htbp]\n\\centering\n\\caption{Summary Statistics: Border ZIP Codes}\n\\label{tab:summary}\n\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(TAB_DIR, "tab1_summary.tex"))
print(xtable(tab1, align = "llcc"),
      type = "latex", file = file.path(TAB_DIR, "tab1_summary.tex"),
      append = TRUE, include.rownames = FALSE,
      sanitize.text.function = identity,
      floating = FALSE)
cat("\\end{adjustbox}\n\\begin{tablenotes}\\small\n\\item \\textit{Notes:} Sample includes ZIP codes within 50km of a high-tax/low-tax state border, 2012--2021. High-income defined as AGI $\\geq$ \\$200K (IRS SOI agi\\_stub = 6). Suppressed ZIPs are those where the IRS withholds income-bracket counts for privacy.\n\\end{tablenotes}\n\\end{table}\n", file = file.path(TAB_DIR, "tab1_summary.tex"), append = TRUE)
cat("Table 1 saved\n")

# ============================================================================
# Table 2: Main RDD Results
# ============================================================================

rdd_main <- fread(file.path(DATA_DIR, "rdd_main_results.csv"))
param <- fread(file.path(DATA_DIR, "parametric_rdd_results.csv"))
bw_dt <- fread(file.path(DATA_DIR, "bandwidth_sensitivity.csv"))

# Get the 30km parametric estimate from bandwidth sensitivity
bw30 <- bw_dt[bandwidth_km == 30]

tab2_data <- rbind(
  data.table(
    Specification = c("Nonparametric (rdrobust)", "Nonparametric placebo"),
    Outcome = c("High-income share", "Low-income share"),
    Estimate = format(round(rdd_main$estimate, 4), nsmall = 4),
    SE = format(round(rdd_main$se_robust, 4), nsmall = 4),
    Bandwidth = paste0(round(rdd_main$bw_left, 1), "km"),
    N = paste0(rdd_main$n_eff_left, "/", rdd_main$n_eff_right)
  ),
  data.table(
    Specification = c(param$model[1:3], "Linear (30km)", param$model[4:6]),
    Outcome = c("High-income share", "High-income share", "High-income share",
                "High-income share",
                "Low-income share", "Mid-income share", "Log high-inc returns"),
    Estimate = format(round(c(param$estimate[1:3], bw30$estimate, param$estimate[4:6]), 4), nsmall = 4),
    SE = format(round(c(param$se[1:3], bw30$se, param$se[4:6]), 4), nsmall = 4),
    Bandwidth = c("50km", "50km", paste0(round(rdd_main[outcome == "high_share", bw_left], 0), "km"),
                  "30km", "50km", "50km", "50km"),
    N = format(c(param$n_obs[1:3], bw30$n_obs, param$n_obs[4:6]), big.mark = ",")
  ),
  fill = TRUE
)

cat("\\begin{table}[htbp]\n\\centering\n\\caption{Boundary Discontinuity Estimates: Effect of High-Tax State on Income Composition}\n\\label{tab:main_rdd}\n\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(TAB_DIR, "tab2_main_rdd.tex"))
print(xtable(tab2_data, align = "llccccc"),
      type = "latex", file = file.path(TAB_DIR, "tab2_main_rdd.tex"),
      append = TRUE, include.rownames = FALSE,
      sanitize.text.function = identity,
      floating = FALSE)
cat("\\end{adjustbox}\n\\begin{tablenotes}\\small\n\\item \\textit{Notes:} The dependent variable is the share of tax returns in a ZIP code with AGI $\\geq$ \\$200K (or AGI $<$ \\$50K for placebo). Nonparametric rows use rdrobust with MSE-optimal bandwidth; N reports effective observations within the bandwidth (left/right of cutoff). Parametric specifications include border-pair $\\times$ year fixed effects and cluster standard errors at the ZIP code level. The running variable is signed distance to the state border (negative = high-tax side). Note that the nonparametric estimator (right minus left = low-tax minus high-tax) and parametric estimator (coefficient on high-tax indicator) have opposite sign conventions. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n\\end{tablenotes}\n\\end{table}\n", file = file.path(TAB_DIR, "tab2_main_rdd.tex"), append = TRUE)
cat("Table 2 saved\n")

# ============================================================================
# Table 3: Period-Specific Estimates
# ============================================================================

period_dt <- fread(file.path(DATA_DIR, "period_rdd_results.csv"))

if (nrow(period_dt) > 0) {
  tab3 <- data.table(
    Period = period_dt$period,
    Estimate = format(round(period_dt$estimate, 4), nsmall = 4),
    SE = format(round(period_dt$se_robust, 4), nsmall = 4),
    Bandwidth = paste0(round(period_dt$bw, 1), "km"),
    `Effective N` = format(period_dt$n_eff, big.mark = ","),
    `p-value` = format(round(pmax(period_dt$p_value, 0.0001), 4), nsmall = 4)
  )

  cat("\\begin{table}[htbp]\n\\centering\n\\caption{Period-Specific RDD Estimates: Pre-SALT, Post-SALT, and COVID}\n\\label{tab:period_rdd}\n\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(TAB_DIR, "tab3_period_rdd.tex"))
  print(xtable(tab3, align = "llccccc"),
        type = "latex", file = file.path(TAB_DIR, "tab3_period_rdd.tex"),
        append = TRUE, include.rownames = FALSE,
        sanitize.text.function = identity,
        floating = FALSE)
  cat("\\end{adjustbox}\n\\begin{tablenotes}\\small\n\\item \\textit{Notes:} Nonparametric RDD estimates (rdrobust) computed separately for each period. Pre-SALT: 2012--2017. Post-SALT/Pre-COVID: 2018--2019. COVID: 2020--2021. Robust bias-corrected standard errors. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n\\end{tablenotes}\n\\end{table}\n", file = file.path(TAB_DIR, "tab3_period_rdd.tex"), append = TRUE)
  cat("Table 3 saved\n")
}

# ============================================================================
# Table 4: Border-Pair Heterogeneity
# ============================================================================

pair_dt <- fread(file.path(DATA_DIR, "pair_rdd_results.csv"))

if (nrow(pair_dt) > 0) {
  setorder(pair_dt, -tax_diff)
  tab4 <- data.table(
    `Border Pair` = pair_dt$pair_label,
    `Avg Tax Diff (pp)` = round(pair_dt$tax_diff, 1),
    Estimate = format(round(pair_dt$estimate, 4), nsmall = 4),
    SE = format(round(pair_dt$se_robust, 4), nsmall = 4),
    `Effective N` = format(pair_dt$n_eff, big.mark = ","),
    `p-value` = format(round(pmax(pair_dt$p_value, 0.0001), 4), nsmall = 4)
  )

  cat("\\begin{table}[htbp]\n\\centering\n\\caption{RDD Estimates by Border Pair}\n\\label{tab:pair_het}\n\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(TAB_DIR, "tab4_pair_heterogeneity.tex"))
  print(xtable(tab4, align = "llccccc"),
        type = "latex", file = file.path(TAB_DIR, "tab4_pair_heterogeneity.tex"),
        append = TRUE, include.rownames = FALSE,
        sanitize.text.function = identity,
        floating = FALSE)
  cat("\\end{adjustbox}\n\\begin{tablenotes}\\small\n\\item \\textit{Notes:} Separate nonparametric RDD estimates for each border pair. Avg Tax Diff is the sample-period average difference in top marginal state income tax rate (high-tax minus low-tax state, 2012--2021). Robust bias-corrected standard errors. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n\\end{tablenotes}\n\\end{table}\n", file = file.path(TAB_DIR, "tab4_pair_heterogeneity.tex"), append = TRUE)
  cat("Table 4 saved\n")
}

# ============================================================================
# Table 5: McCrary Test + Covariate Balance
# ============================================================================

mccrary <- fread(file.path(DATA_DIR, "mccrary_test.csv"))
balance <- fread(file.path(DATA_DIR, "covariate_balance.csv"))

tab5 <- data.table(
  Test = c("McCrary density (ZIP centroids)", gsub("_", "\\\\_", balance$covariate)),
  Estimate = c(format(round(mccrary$t_stat, 3), nsmall = 3),
               format(round(balance$estimate, 1), big.mark = ",")),
  SE = c("---", format(round(balance$se, 1), big.mark = ",")),
  `p-value` = c(format(round(mccrary$p_value, 3), nsmall = 3),
                format(round(pmax(balance$p_value, 0.001), 3), nsmall = 3))
)

cat("\\begin{table}[htbp]\n\\centering\n\\caption{Validity Tests: Density and Covariate Balance at the Border}\n\\label{tab:validity}\n\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(TAB_DIR, "tab5_validity.tex"))
print(xtable(tab5, align = "llccc"),
      type = "latex", file = file.path(TAB_DIR, "tab5_validity.tex"),
      append = TRUE, include.rownames = FALSE,
      sanitize.text.function = identity,
      floating = FALSE)
cat("\\end{adjustbox}\n\\begin{tablenotes}\\small\n\\item \\textit{Notes:} McCrary (2008) density test evaluates whether ZIP code centroids are disproportionately located on one side of the border (reported statistic is the $t$-statistic). Covariate balance tests use the parametric RDD specification with border-pair $\\times$ year FE, 30km bandwidth, clustered SEs at ZIP level ($N = 14{,}673$). Estimate for covariate rows is the coefficient on the high-tax-side indicator.\n\\end{tablenotes}\n\\end{table}\n", file = file.path(TAB_DIR, "tab5_validity.tex"), append = TRUE)
cat("Table 5 saved\n")

# ============================================================================
# Table 6: Triple-Difference Results
# ============================================================================

ddd <- fread(file.path(DATA_DIR, "triple_diff_results.csv"))
ddd_meta <- tryCatch(fread(file.path(DATA_DIR, "triple_diff_meta.csv")), error = function(e) NULL)

if (nrow(ddd) > 0) {
  # Select key coefficients
  key_terms <- c("high_tax_side:high_income", "high_tax_side:post_salt",
                 "high_income:post_salt", "high_tax_side:high_income:post_salt")
  ddd_key <- ddd[term %in% key_terms]

  tab6 <- data.table(
    Term = c("High-Tax Side $\\times$ High Income",
             "High-Tax Side $\\times$ Post-SALT",
             "High Income $\\times$ Post-SALT",
             "High-Tax $\\times$ High Income $\\times$ Post-SALT"),
    Estimate = format(round(ddd_key$estimate, 4), nsmall = 4),
    SE = format(round(ddd_key$se, 4), nsmall = 4),
    `p-value` = format(round(pmax(ddd_key$p_value, 0.0001), 4), nsmall = 4)
  )

  # Build notes with N info
  notes_text <- "Dependent variable is the income-group share in a ZIP code. Observations are stacked: each ZIP$\\times$year appears twice (once for the high-income share, once for the low-income share), so $N$ is approximately double the 30km analysis sample. Includes ZIP code and border-pair $\\times$ year FE. Controls for distance $\\times$ border side and distance $\\times$ income group interactions. 30km bandwidth. Clustered SEs at ZIP level."
  if (!is.null(ddd_meta)) {
    notes_text <- paste0(notes_text, " $N$ = ", format(ddd_meta$n_obs, big.mark = ","),
                         " (", format(ddd_meta$n_clusters, big.mark = ","), " ZIP clusters).")
  }

  cat("\\begin{table}[htbp]\n\\centering\n\\caption{Triple-Difference Estimates: Income $\\times$ Border Side $\\times$ Post-SALT}\n\\label{tab:ddd}\n\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(TAB_DIR, "tab6_triple_diff.tex"))
  print(xtable(tab6, align = "llccc"),
        type = "latex", file = file.path(TAB_DIR, "tab6_triple_diff.tex"),
        append = TRUE, include.rownames = FALSE,
        sanitize.text.function = identity,
        floating = FALSE)
  cat(paste0("\\end{adjustbox}\n\\begin{tablenotes}\\small\n\\item \\textit{Notes:} ", notes_text, "\n\\end{tablenotes}\n\\end{table}\n"), file = file.path(TAB_DIR, "tab6_triple_diff.tex"), append = TRUE)
  cat("Table 6 saved\n")
}

# ============================================================================
# Table 7: Robustness Summary (Appendix)
# ============================================================================

donut_dt <- tryCatch(fread(file.path(DATA_DIR, "donut_sensitivity.csv")), error = function(e) NULL)
metro_dt <- tryCatch(fread(file.path(DATA_DIR, "metro_only_results.csv")), error = function(e) NULL)
sup_dt <- tryCatch(fread(file.path(DATA_DIR, "suppression_sensitivity.csv")), error = function(e) NULL)
poly_dt <- tryCatch(fread(file.path(DATA_DIR, "polynomial_sensitivity.csv")), error = function(e) NULL)

if (!is.null(donut_dt) && !is.null(metro_dt) && !is.null(sup_dt) && !is.null(poly_dt)) {
  tab7 <- rbind(
    data.table(
      Specification = paste0("Donut: exclude $<$", donut_dt$donut_km, "km"),
      Estimate = format(round(donut_dt$estimate, 4), nsmall = 4),
      SE = format(round(donut_dt$se, 4), nsmall = 4),
      N = format(donut_dt$n_obs, big.mark = ",")
    ),
    data.table(
      Specification = paste0("Polynomial order ", poly_dt$poly_order),
      Estimate = format(round(poly_dt$estimate, 4), nsmall = 4),
      SE = format(round(poly_dt$se, 4), nsmall = 4),
      N = format(poly_dt$n_obs, big.mark = ",")
    ),
    data.table(
      Specification = metro_dt$subsample,
      Estimate = format(round(metro_dt$estimate, 4), nsmall = 4),
      SE = format(round(metro_dt$se, 4), nsmall = 4),
      N = format(metro_dt$n_obs, big.mark = ",")
    ),
    data.table(
      Specification = sup_dt$check,
      Estimate = format(round(sup_dt$estimate, 4), nsmall = 4),
      SE = format(round(sup_dt$se, 4), nsmall = 4),
      N = c(format(nrow(fread(file.path(DATA_DIR, "analysis_panel.csv"))[abs(dist_to_border_km) <= 30 & !is.na(high_share) & total_returns >= 10]), big.mark = ","),
            format(nrow(fread(file.path(DATA_DIR, "analysis_panel.csv"))[abs(dist_to_border_km) <= 30 & !is.na(high_share) & total_returns >= 10 & suppressed == FALSE]), big.mark = ","))
    )
  )

  cat("\\begin{table}[htbp]\n\\centering\n\\caption{Robustness: Alternative Specifications}\n\\label{tab:robustness}\n\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(TAB_DIR, "tab7_robustness.tex"))
  print(xtable(tab7, align = "llccc"),
        type = "latex", file = file.path(TAB_DIR, "tab7_robustness.tex"),
        append = TRUE, include.rownames = FALSE,
        sanitize.text.function = identity,
        floating = FALSE)
  cat("\\end{adjustbox}\n\\begin{tablenotes}\\small\n\\item \\textit{Notes:} All specifications use the parametric RDD with border-pair $\\times$ year FE, 30km bandwidth unless otherwise noted, and standard errors clustered at the ZIP code level. Outcome: high-income share. Donut designs exclude ZIP codes within the specified distance of the border. Polynomial specifications use polynomial order 1--3 in distance.\n\\end{tablenotes}\n\\end{table}\n", file = file.path(TAB_DIR, "tab7_robustness.tex"), append = TRUE)
  cat("Table 7 (robustness) saved\n")
}

# ============================================================================
# Table 8: Pooled Excluding NJ-PA
# ============================================================================

exnjpa <- tryCatch(fread(file.path(DATA_DIR, "pooled_excl_njpa.csv")), error = function(e) NULL)

if (!is.null(exnjpa)) {
  # Append to Table 2 data: add as a note or create supplementary table
  tab8 <- data.table(
    Specification = c("Pooled (all 8 borders)", "Pooled excluding NJ-PA"),
    Estimate = c(
      format(round(rdd_main[outcome == "high_share", estimate], 4), nsmall = 4),
      format(round(exnjpa$estimate, 4), nsmall = 4)
    ),
    SE = c(
      format(round(rdd_main[outcome == "high_share", se_robust], 4), nsmall = 4),
      format(round(exnjpa$se_robust, 4), nsmall = 4)
    ),
    Bandwidth = c(
      paste0(round(rdd_main[outcome == "high_share", bw_left], 1), "km"),
      paste0(round(exnjpa$bw, 1), "km")
    ),
    N = c(
      paste0(rdd_main[outcome == "high_share", n_eff_left], "/", rdd_main[outcome == "high_share", n_eff_right]),
      paste0(exnjpa$n_eff_left, "/", exnjpa$n_eff_right)
    ),
    `p-value` = c(
      format(round(pmax(rdd_main[outcome == "high_share", p_value], 0.0001), 4), nsmall = 4),
      format(round(pmax(exnjpa$p_value, 0.0001), 4), nsmall = 4)
    )
  )

  cat("\\begin{table}[htbp]\n\\centering\n\\caption{Sensitivity to NJ-PA Border: Pooled Nonparametric RDD}\n\\label{tab:excl_njpa}\n\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(TAB_DIR, "tab8_excl_njpa.tex"))
  print(xtable(tab8, align = "llccccc"),
        type = "latex", file = file.path(TAB_DIR, "tab8_excl_njpa.tex"),
        append = TRUE, include.rownames = FALSE,
        sanitize.text.function = identity,
        floating = FALSE)
  cat("\\end{adjustbox}\n\\begin{tablenotes}\\small\n\\item \\textit{Notes:} Nonparametric RDD estimates using rdrobust with MSE-optimal bandwidth. NJ-PA is excluded because its very small effective sample ($N \\approx 30$) generates a disproportionately large estimate. N reports effective observations (left/right of cutoff). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n\\end{tablenotes}\n\\end{table}\n", file = file.path(TAB_DIR, "tab8_excl_njpa.tex"), append = TRUE)
  cat("Table 8 (excl NJ-PA) saved\n")
}

# ============================================================================
# Table 9: DDD Clustering Comparison
# ============================================================================

bp_compare <- tryCatch(fread(file.path(DATA_DIR, "ddd_clustering_comparison.csv")), error = function(e) NULL)

if (!is.null(bp_compare)) {
  tab9 <- data.table(
    `Clustering Level` = bp_compare$clustering,
    Estimate = format(round(bp_compare$estimate, 4), nsmall = 4),
    SE = format(round(bp_compare$se, 4), nsmall = 4),
    `p-value` = format(round(pmax(bp_compare$p_value, 0.0001), 4), nsmall = 4),
    Clusters = format(bp_compare$n_clusters, big.mark = ",")
  )

  cat("\\begin{table}[htbp]\n\\centering\n\\caption{Triple-Difference: Sensitivity to Clustering Level}\n\\label{tab:ddd_cluster}\n\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(TAB_DIR, "tab9_ddd_clustering.tex"))
  print(xtable(tab9, align = "llcccc"),
        type = "latex", file = file.path(TAB_DIR, "tab9_ddd_clustering.tex"),
        append = TRUE, include.rownames = FALSE,
        sanitize.text.function = identity,
        floating = FALSE)
  cat("\\end{adjustbox}\n\\begin{tablenotes}\\small\n\\item \\textit{Notes:} Triple-difference coefficient on High-Tax $\\times$ High Income $\\times$ Post-SALT. Column 1 clusters at the ZIP code level (1,578 clusters). Column 2 clusters at the border-pair level (8 clusters). The point estimate is identical; only standard errors and inference change.\n\\end{tablenotes}\n\\end{table}\n", file = file.path(TAB_DIR, "tab9_ddd_clustering.tex"), append = TRUE)
  cat("Table 9 (DDD clustering) saved\n")
}

cat("\n=== ALL TABLES GENERATED ===\n")
