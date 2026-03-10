## ============================================================
## 06_tables.R — Generate all tables from saved CSVs
## ERDF Treatment Withdrawal RDD
## ============================================================

source("00_packages.R")

data_dir  <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== GENERATING TABLES ===\n\n")

# Load results
main_res  <- fread(paste0(data_dir, "main_results.csv"))
param_res <- fread(paste0(data_dir, "parametric_results.csv"))
sumstats  <- fread(paste0(data_dir, "summary_statistics.csv"))
bal_tests <- fread(paste0(data_dir, "balance_tests.csv"))
donut_res <- fread(paste0(data_dir, "donut_results.csv"))
poly_res  <- fread(paste0(data_dir, "polynomial_sensitivity.csv"))
loco_res  <- fread(paste0(data_dir, "leave_one_country_out.csv"))
dens_test <- fread(paste0(data_dir, "density_test.csv"))

## ---------------------------------------------------------
## Table 1: Summary Statistics
## ---------------------------------------------------------
cat("Table 1: Summary statistics\n")

# Format for LaTeX
sumstats_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Summary Statistics by Threshold Status}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcc}\n\\hline\\hline\n",
  " & Below 75\\% & Above 75\\% \\\\\n",
  " & (Less Developed) & (Graduated) \\\\\n\\hline\n"
)

for (i in 1:nrow(sumstats)) {
  sumstats_tex <- paste0(sumstats_tex,
    sumstats$variable[i], " & ", sumstats$below_75[i], " & ", sumstats$above_75[i], " \\\\\n")
}

sumstats_tex <- paste0(sumstats_tex,
  "\\hline\\hline\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Regions within $\\pm$20 percentage points of the 75\\% threshold. ",
  "GDP per capita measured as PPS per inhabitant, expressed as \\% of EU27 average. ",
  "Employment rate for population aged 15-64. Manufacturing GVA share is gross value added ",
  "in NACE sector C as a fraction of total GVA.\n",
  "\\end{tablenotes}\n\\end{table}\n")

writeLines(sumstats_tex, paste0(table_dir, "tab1_sumstats.tex"))

## ---------------------------------------------------------
## Table 2: Main RDD Results
## ---------------------------------------------------------
cat("Table 2: Main RDD results\n")

main_only <- main_res[spec == "CCT_optimal"]

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Main RDD Results: Effect of Graduating Above 75\\% Threshold}\n",
  "\\label{tab:main_rdd}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & GDP/cap & Employment & Mfg. GVA \\\\\n",
  " & (\\% EU27) & Rate (pp) & Share \\\\\n\\hline\n"
)

for (i in 1:nrow(main_only)) {
  coef_str <- ifelse(!is.na(main_only$coef[i]),
    sprintf("%.3f", main_only$coef[i]), "---")
  se_str <- ifelse(!is.na(main_only$se_robust[i]),
    sprintf("(%.3f)", main_only$se_robust[i]), "")

  stars <- ""
  if (!is.na(main_only$p_value[i])) {
    if (main_only$p_value[i] < 0.01) stars <- "***"
    else if (main_only$p_value[i] < 0.05) stars <- "**"
    else if (main_only$p_value[i] < 0.10) stars <- "*"
  }

  if (i == 1) {
    tab2_tex <- paste0(tab2_tex, "Graduated ($>$75\\%) & ",
      coef_str, stars, " & & \\\\\n & ", se_str, " & & \\\\\n")
  } else if (i == 2) {
    tab2_tex <- paste0(tab2_tex, "Graduated ($>$75\\%) & & ",
      coef_str, stars, " & \\\\\n & & ", se_str, " & \\\\\n")
  } else {
    tab2_tex <- paste0(tab2_tex, "Graduated ($>$75\\%) & & & ",
      coef_str, stars, " \\\\\n & & & ", se_str, " \\\\\n")
  }
}

# Add bandwidth and N info from the first valid result
valid_res <- main_only[!is.na(coef)]
if (nrow(valid_res) > 0) {
  tab2_tex <- paste0(tab2_tex, "\\hline\n",
    "Bandwidth & ", paste(sprintf("%.1f", valid_res$h_opt), collapse = " & "), " \\\\\n",
    "$N$ (left/right) & ",
    paste(sprintf("%d/%d", valid_res$n_left, valid_res$n_right), collapse = " & "), " \\\\\n")
}

tab2_tex <- paste0(tab2_tex,
  "\\hline\\hline\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Local polynomial RDD estimates using \\texttt{rdrobust} ",
  "with CCT optimal bandwidth selection. Robust bias-corrected standard errors in parentheses. ",
  "The running variable is GDP per capita (PPS) as \\% of EU27 average, centered at 75\\%. ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n")

writeLines(tab2_tex, paste0(table_dir, "tab2_main_rdd.tex"))

## ---------------------------------------------------------
## Table 3: Covariate Balance
## ---------------------------------------------------------
cat("Table 3: Covariate balance\n")

if (nrow(bal_tests) > 0) {
  tab3_tex <- paste0(
    "\\begin{table}[htbp]\n\\centering\n",
    "\\caption{Covariate Balance at the 75\\% Threshold}\n",
    "\\label{tab:balance}\n",
    "\\begin{adjustbox}{max width=\\textwidth}\n",
    "\\begin{tabular}{lccc}\n\\hline\\hline\n",
    "Covariate & RDD Estimate & Robust SE & $p$-value \\\\\n\\hline\n"
  )

  for (i in 1:nrow(bal_tests)) {
    tab3_tex <- paste0(tab3_tex,
      bal_tests$covariate[i], " & ",
      sprintf("%.3f", bal_tests$coef[i]), " & ",
      sprintf("%.3f", bal_tests$se[i]), " & ",
      sprintf("%.3f", bal_tests$p_value[i]), " \\\\\n")
  }

  tab3_tex <- paste0(tab3_tex,
    "\\hline\n",
    "Density test ($p$-value) & \\multicolumn{3}{c}{",
    sprintf("%.3f", dens_test$p_value[1]), "} \\\\\n",
    "\\hline\\hline\n\\end{tabular}\n\\end{adjustbox}\n",
    "\\begin{tablenotes}[flushleft]\\small\n",
    "\\item \\textit{Notes:} RDD estimates of the discontinuity in pre-determined covariates ",
    "at the 75\\% threshold, using \\texttt{rdrobust} with CCT optimal bandwidth. ",
    "A non-significant coefficient indicates smooth covariate crossing. ",
    "The density test uses the \\texttt{rddensity} package.\n",
    "\\end{tablenotes}\n\\end{table}\n")

  writeLines(tab3_tex, paste0(table_dir, "tab3_balance.tex"))
}

## ---------------------------------------------------------
## Table C.1 (Appendix): Robustness — Bandwidth, Donut, Polynomial
## ---------------------------------------------------------
cat("Table C.1: Robustness specifications\n")

# Combine all robustness
robust_rows <- list()

# Bandwidth results
bw_res <- main_res[grepl("bw_", spec) & outcome == "GDP_pct_EU27"]
for (i in 1:nrow(bw_res)) {
  robust_rows[[length(robust_rows) + 1]] <- data.table(
    spec = paste0("Bandwidth = ", bw_res$bw_left[i], " pp"),
    coef = bw_res$coef[i],
    se = bw_res$se_robust[i],
    p_value = bw_res$p_value[i],
    n = bw_res$n_left[i] + bw_res$n_right[i]
  )
}

# Donut
for (i in 1:nrow(donut_res)) {
  robust_rows[[length(robust_rows) + 1]] <- data.table(
    spec = paste0("Donut $\\pm$", donut_res$donut[i], " pp"),
    coef = donut_res$coef[i],
    se = donut_res$se[i],
    p_value = donut_res$p_value[i],
    n = donut_res$n[i]
  )
}

# Polynomial
for (i in 1:nrow(poly_res)) {
  robust_rows[[length(robust_rows) + 1]] <- data.table(
    spec = paste0("Polynomial order = ", poly_res$poly_order[i]),
    coef = poly_res$coef[i],
    se = poly_res$se[i],
    p_value = poly_res$p_value[i],
    n = NA_integer_
  )
}

robust_dt <- rbindlist(robust_rows, fill = TRUE)

tabc1_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Robustness: Alternative Specifications}\n",
  "\\label{tab:robustness}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n\\hline\\hline\n",
  "Specification & Coefficient & Robust SE & $p$-value & $N$ \\\\\n\\hline\n"
)

for (i in 1:nrow(robust_dt)) {
  stars <- ""
  if (!is.na(robust_dt$p_value[i])) {
    if (robust_dt$p_value[i] < 0.01) stars <- "***"
    else if (robust_dt$p_value[i] < 0.05) stars <- "**"
    else if (robust_dt$p_value[i] < 0.10) stars <- "*"
  }

  n_str <- ifelse(is.na(robust_dt$n[i]), "---", as.character(robust_dt$n[i]))

  tabc1_tex <- paste0(tabc1_tex,
    robust_dt$spec[i], " & ",
    sprintf("%.3f", robust_dt$coef[i]), stars, " & ",
    sprintf("%.3f", robust_dt$se[i]), " & ",
    sprintf("%.3f", robust_dt$p_value[i]), " & ",
    n_str, " \\\\\n")
}

tabc1_tex <- paste0(tabc1_tex,
  "\\hline\\hline\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Outcome is change in GDP per capita (\\% of EU27 average) ",
  "between the 2007-2013 and 2014-2020 periods. All specifications use \\texttt{rdrobust}. ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n")

writeLines(tabc1_tex, paste0(table_dir, "tabc1_robustness.tex"))

cat("\n=== ALL TABLES GENERATED ===\n")
