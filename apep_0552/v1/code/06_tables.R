# =============================================================================
# 06_tables.R — Generate all LaTeX tables from saved data
# APEP Paper apep_0552: Stranded by the Label?
# =============================================================================

source("00_packages.R")

# Load model objects
models <- readRDS(file.path(data_dir, "main_models.rds"))
rob_models <- tryCatch(readRDS(file.path(data_dir, "robustness_models.rds")),
                        error = function(e) NULL)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================

cat("=== Table 1: Summary Statistics ===\n")

sumstats <- fread(file.path(data_dir, "sumstats_full.csv"))

# Format for LaTeX
sumstats[, Mean := format(round(Mean, 2), big.mark = ",")]
sumstats[, SD := ifelse(is.na(SD), "", format(round(SD, 2), big.mark = ","))]
sumstats[, N := format(N, big.mark = ",")]

tab1_latex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Variable & Mean & SD & N \\\\\n",
  "\\hline\n",
  paste(apply(sumstats, 1, function(row) {
    paste(row["Variable"], "&", row["Mean"], "&", row["SD"], "&", row["N"], "\\\\")
  }), collapse = "\n"),
  "\n\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sample consists of residential property transactions in France ",
  "from DVF (2018--2024) matched to ADEME DPE energy performance certificates. ",
  "Prices are in euros. DPE ratings range from A (most efficient) to G (least efficient). ",
  "Properties rated F or G are classified as ``passoires thermiques'' (energy sieves).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_latex, file.path(table_dir, "tab1_sumstats.tex"))
cat("Table 1 saved.\n")

# =============================================================================
# Table 2: Main DiD Results
# =============================================================================

cat("=== Table 2: Main DiD ===\n")

msummary_list <- list(
  "(1) G vs D" = models$m1_GvD,
  "(2) G vs F" = models$m2_GvF,
  "(3) FG vs CD" = models$m3_passoire
)

modelsummary(msummary_list,
             output = file.path(table_dir, "tab2_main_did.tex"),
             fmt = 4,
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             coef_map = c(
               "is_G:post_reform" = "G $\\times$ Post-Reform",
               "is_G" = "G-Rated",
               "passoire:post_reform" = "Passoire $\\times$ Post-Reform",
               "passoire" = "Passoire (F+G)",
               "surface_reelle_bati" = "Surface (m$^2$)",
               "nombre_pieces_principales" = "Rooms",
               "is_apartment" = "Apartment"
             ),
             gof_map = c("nobs", "r.squared", "adj.r.squared"),
             title = "Effect of DPE G-Rating on Property Prices",
             notes = list(
               "Standard errors clustered at the commune level in parentheses.",
               "All specifications include commune and year-quarter fixed effects.",
               "The dependent variable is log transaction price.",
               "Post-reform = transactions after July 1, 2021."
             ),
             escape = FALSE)

cat("Table 2 saved.\n")

# =============================================================================
# Table 3: Triple-Difference (Rental Share Heterogeneity)
# =============================================================================

cat("=== Table 3: Triple-Diff ===\n")

msummary_triple <- list(
  "(1) Continuous" = models$m_triple_cont,
  "(2) Terciles" = models$m_triple_terc
)

modelsummary(msummary_triple,
             output = file.path(table_dir, "tab3_triple_diff.tex"),
             fmt = 4,
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             coef_map = c(
               "is_G:post_reform" = "G $\\times$ Post",
               "is_G:pct_rental" = "G $\\times$ Rental Share",
               "post_reform:pct_rental" = "Post $\\times$ Rental Share",
               "is_G:post_reform:pct_rental" = "G $\\times$ Post $\\times$ Rental Share",
               "is_G:post_reform:rental_tercileMedium rental" = "G $\\times$ Post $\\times$ Medium Rental",
               "is_G:post_reform:rental_tercileHigh rental" = "G $\\times$ Post $\\times$ High Rental",
               "is_G" = "G-Rated"
             ),
             gof_map = c("nobs", "r.squared"),
             title = "Regulatory vs. Informational Channel: Triple-Difference by Rental Share",
             notes = list(
               "Standard errors clustered at the commune level in parentheses.",
               "Column (1) interacts G $\\times$ Post-Reform with the continuous commune rental share.",
               "Column (2) uses rental-share terciles. The dependent variable is log transaction price.",
               "All specifications include commune and year-quarter fixed effects."
             ),
             escape = FALSE)

cat("Table 3 saved.\n")

# =============================================================================
# Table 4: RDD Results at Multiple Thresholds
# =============================================================================

cat("=== Table 4: RDD Results ===\n")

rdd_results <- fread(file.path(data_dir, "rdd_results.csv"))

if (nrow(rdd_results) > 0) {
  rdd_results[, Boundary := c("G/F (420 kWh)", "F/E (330 kWh)", "D/C (250 kWh)")]
  rdd_results[, Ban := c("Jan 2025", "2028", "None")]
  rdd_results[, Estimate_fmt := sprintf("%.4f", Estimate)]
  rdd_results[, SE_fmt := sprintf("(%.4f)", SE_robust)]
  rdd_results[, pval_fmt := sprintf("%.3f", pval_robust)]
  rdd_results[, BW_fmt := sprintf("%.1f", BW_left)]
  rdd_results[, N_fmt := format(N_left + N_right, big.mark = ",")]

  tab4_latex <- paste0(
    "\\begin{table}[htbp]\n",
    "\\centering\n",
    "\\caption{Multi-Cutoff RDD: Price Discontinuity at DPE Thresholds}\n",
    "\\label{tab:rdd}\n",
    "\\begin{tabular}{lcccccc}\n",
    "\\hline\\hline\n",
    " & Estimate & Robust SE & $p$-value & Bandwidth & $N$ & Rental Ban \\\\\n",
    "\\hline\n",
    paste(apply(rdd_results, 1, function(row) {
      paste(row["Boundary"], "&", row["Estimate_fmt"], "&", row["SE_fmt"],
            "&", row["pval_fmt"], "&", row["BW_fmt"], "&", row["N_fmt"],
            "&", row["Ban"], "\\\\")
    }), collapse = "\n"),
    "\n\\hline\\hline\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}\n",
    "\\small\n",
    "\\item \\textit{Notes:} Local linear RDD with triangular kernel and optimal (IK) bandwidth. ",
    "Robust bias-corrected standard errors and p-values reported. ",
    "The G/F threshold at 420 kWh/m$^2$/year carries an imminent rental ban (January 2025); ",
    "the F/E threshold carries a more distant ban (2028); ",
    "the D/C threshold carries no regulatory consequence. ",
    "Dependent variable is log transaction price.\n",
    "\\end{tablenotes}\n",
    "\\end{table}\n"
  )

  writeLines(tab4_latex, file.path(table_dir, "tab4_rdd.tex"))
  cat("Table 4 saved.\n")
}

# =============================================================================
# Table 5: Robustness — Heterogeneity and Sensitivity
# =============================================================================

cat("=== Table 5: Robustness ===\n")

if (!is.null(rob_models)) {
  msummary_rob <- list(
    "(1) Apartments" = rob_models$m_apt,
    "(2) Houses" = rob_models$m_house,
    "(3) Urban" = rob_models$m_urban,
    "(4) Rural" = rob_models$m_rural,
    "(5) Dept x YQ FE" = rob_models$m_strict
  )

  modelsummary(msummary_rob,
               output = file.path(table_dir, "tab5_robustness.tex"),
               fmt = 4,
               stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
               coef_map = c(
                 "is_G:post_reform" = "G $\\times$ Post-Reform",
                 "is_G" = "G-Rated",
                 "surface_reelle_bati" = "Surface (m$^2$)",
                 "nombre_pieces_principales" = "Rooms",
                 "is_apartment" = "Apartment"
               ),
               gof_map = c("nobs", "r.squared"),
               title = "Robustness: Heterogeneity by Property Type, Urbanicity, and Fixed Effects",
               notes = list(
                 "Standard errors clustered at the commune level in parentheses.",
                 "The dependent variable is log transaction price."
               ),
               escape = FALSE)

  cat("Table 5 saved.\n")
}

# =============================================================================
# Table 6: DiDisc Results
# =============================================================================

cat("=== Table 6: DiDisc ===\n")

if ("m_didisc" %in% names(models)) {
  modelsummary(list("Difference-in-Discontinuities" = models$m_didisc),
               output = file.path(table_dir, "tab6_didisc.tex"),
               fmt = 4,
               stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
               coef_map = c(
                 "above_420:post_reform" = "Above 420 $\\times$ Post-Reform",
                 "above_420" = "Above 420 kWh",
                 "kwh_centered" = "kWh (centered)",
                 "above_420:kwh_centered" = "Above 420 $\\times$ kWh",
                 "surface_reelle_bati" = "Surface (m$^2$)",
                 "nombre_pieces_principales" = "Rooms",
                 "is_apartment" = "Apartment"
               ),
               gof_map = c("nobs", "r.squared"),
               title = "Difference-in-Discontinuities at the G/F Threshold",
               notes = list(
                 "Bandwidth: 50 kWh/m$^2$ around the 420 threshold.",
                 "Standard errors clustered at the commune level in parentheses.",
                 "The interaction above $\\times$ post captures the change in the G/F discontinuity",
                 "after the reform made DPE ratings legally binding."
               ),
               escape = FALSE)

  cat("Table 6 saved.\n")
}

# =============================================================================
# Table A1: Density Tests
# =============================================================================

cat("=== Table A1: Density Tests ===\n")

density_tests <- fread(file.path(data_dir, "density_tests.csv"))

if (nrow(density_tests) > 0) {
  density_tests[, Threshold_label := paste0(Threshold, " kWh/m\u00b2")]
  density_tests[, T_fmt := sprintf("%.3f", T_stat)]
  density_tests[, P_fmt := sprintf("%.3f", P_value)]

  tabA1_latex <- paste0(
    "\\begin{table}[htbp]\n",
    "\\centering\n",
    "\\caption{McCrary Density Tests at DPE Thresholds}\n",
    "\\label{tab:density}\n",
    "\\begin{tabular}{lcc}\n",
    "\\hline\\hline\n",
    "Threshold & $T$-statistic & $p$-value \\\\\n",
    "\\hline\n",
    paste(apply(density_tests, 1, function(row) {
      paste(row["Threshold_label"], "&", row["T_fmt"], "&", row["P_fmt"], "\\\\")
    }), collapse = "\n"),
    "\n\\hline\\hline\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}\n",
    "\\small\n",
    "\\item \\textit{Notes:} Cattaneo, Jansson, and Ma (2020) density test. ",
    "A significant result indicates bunching around the threshold, ",
    "suggesting potential manipulation of DPE assessments.\n",
    "\\end{tablenotes}\n",
    "\\end{table}\n"
  )

  writeLines(tabA1_latex, file.path(table_dir, "tabA1_density.tex"))
  cat("Table A1 saved.\n")
}

cat("\n=== All tables generated ===\n")
