## =============================================================================
## 06_tables.R — Generate All LaTeX Tables from Saved CSV Data
## Paper: The Economic Integration Lottery
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE)

## ---------------------------------------------------------------------------
## Table 1: Summary Statistics
## ---------------------------------------------------------------------------

cat("Table 1: Summary statistics...\n")

summ <- fread(file.path(data_dir, "summary_statistics.csv"))

if (nrow(summ) > 0) {
  # Format numbers
  summ[, mean_fmt := ifelse(abs(mean) > 100, format(round(mean, 0), big.mark = ","),
                             sprintf("%.3f", mean))]
  summ[, sd_fmt := ifelse(abs(sd) > 100, format(round(sd, 0), big.mark = ","),
                           sprintf("%.3f", sd))]
  summ[, p25_fmt := ifelse(abs(p25) > 100, format(round(p25, 0), big.mark = ","),
                            sprintf("%.3f", p25))]
  summ[, p75_fmt := ifelse(abs(p75) > 100, format(round(p75, 0), big.mark = ","),
                            sprintf("%.3f", p75))]

  tex <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Summary Statistics}",
    "\\label{tab:summary}",
    "\\begin{adjustbox}{max width=\\textwidth}",
    "\\begin{tabular}{lrrrrr}",
    "\\toprule",
    " & Mean & SD & P25 & P75 & N \\\\",
    "\\midrule",
    "\\multicolumn{6}{l}{\\textit{Panel A: Instrument}} \\\\",
    paste0("Asylum Grant Rate & ", summ[variable == "Asylum Grant Rate", mean_fmt],
           " & ", summ[variable == "Asylum Grant Rate", sd_fmt],
           " & ", summ[variable == "Asylum Grant Rate", p25_fmt],
           " & ", summ[variable == "Asylum Grant Rate", p75_fmt],
           " & ", summ[variable == "Asylum Grant Rate", format(n, big.mark = ",")], " \\\\"),
    paste0("Avg Judge Leniency & ", summ[variable == "Avg Judge Leniency", mean_fmt],
           " & ", summ[variable == "Avg Judge Leniency", sd_fmt],
           " & ", summ[variable == "Avg Judge Leniency", p25_fmt],
           " & ", summ[variable == "Avg Judge Leniency", p75_fmt],
           " & ", summ[variable == "Avg Judge Leniency", format(n, big.mark = ",")], " \\\\"),
    "\\midrule",
    "\\multicolumn{6}{l}{\\textit{Panel B: Labor Market Outcomes}} \\\\"
  )

  labor_vars <- c("Total Employment", "Accommodation & Food Employment",
                   "Admin Services Employment", "Finance Employment",
                   "Professional Services Employment",
                   "Total Establishments", "Average Weekly Wage ($)")
  for (v in labor_vars) {
    row <- summ[variable == v]
    if (nrow(row) > 0) {
      tex <- c(tex, paste0(v, " & ", row$mean_fmt,
                           " & ", row$sd_fmt,
                           " & ", row$p25_fmt,
                           " & ", row$p75_fmt,
                           " & ", format(row$n, big.mark = ","), " \\\\"))
    }
  }

  tex <- c(tex,
    "\\midrule",
    "\\multicolumn{6}{l}{\\textit{Panel C: Demographics}} \\\\"
  )

  demo_vars <- c("Noncitizen Population Share", "Foreign-Born Share",
                  "Total Population", "Poverty Rate", "Unemployment Rate")
  for (v in demo_vars) {
    row <- summ[variable == v]
    if (nrow(row) > 0) {
      tex <- c(tex, paste0(v, " & ", row$mean_fmt,
                           " & ", row$sd_fmt,
                           " & ", row$p25_fmt,
                           " & ", row$p75_fmt,
                           " & ", format(row$n, big.mark = ","), " \\\\"))
    }
  }

  tex <- c(tex,
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{adjustbox}",
    "\\begin{minipage}{0.9\\textwidth}",
    "\\vspace{0.5em}",
    "\\footnotesize \\textit{Notes:} This table presents summary statistics for the analysis sample.",
    "The unit of observation is a court-county-year. Panel A shows the asylum court-level grant rate",
    "and the judge leniency instrument (caseload-weighted average grant rate of judges assigned to each court).",
    "Panel B shows county-level labor market outcomes from the BLS Quarterly Census of Employment and Wages (QCEW).",
    "Panel C shows county demographics from the American Community Survey (ACS).",
    "\\end{minipage}",
    "\\end{table}"
  )

  writeLines(tex, file.path(tab_dir, "tab1_summary.tex"))
  cat("  Saved tab1_summary.tex\n")
}

## ---------------------------------------------------------------------------
## Table 2: First Stage and Balance Tests
## ---------------------------------------------------------------------------

cat("Table 2: First stage and balance...\n")

fs <- fread(file.path(data_dir, "first_stage_results.csv"))
bal <- fread(file.path(data_dir, "balance_test_results.csv"))

if (nrow(fs) > 0) {
  tex2 <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{First Stage: Judge Leniency Predicts Asylum Grant Rates}",
    "\\label{tab:first_stage}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    " & (1) & (2) & (3) \\\\",
    " & No FE & Region FE & Year FE \\\\",
    "\\midrule",
    "\\multicolumn{4}{l}{\\textit{Panel A: First Stage}} \\\\"
  )

  for (r in seq_len(nrow(fs))) {
    coef_str <- sprintf("%.3f", fs$coef[r])
    se_str <- sprintf("(%.3f)", fs$se[r])
    if (r == 1) {
      tex2 <- c(tex2, paste0("Avg Judge Leniency & ", coef_str,
                              " & ", ifelse(nrow(fs) >= 2, sprintf("%.3f", fs$coef[2]), ""),
                              " & ", ifelse(nrow(fs) >= 3, sprintf("%.3f", fs$coef[3]), ""),
                              " \\\\"))
      tex2 <- c(tex2, paste0(" & ", se_str,
                              " & ", ifelse(nrow(fs) >= 2, sprintf("(%.3f)", fs$se[2]), ""),
                              " & ", ifelse(nrow(fs) >= 3, sprintf("(%.3f)", fs$se[3]), ""),
                              " \\\\"))
    }
  }

  tex2 <- c(tex2,
    paste0("F-statistic & ", sprintf("%.1f", fs$f_stat[1]),
           " & ", ifelse(nrow(fs) >= 2, sprintf("%.1f", fs$f_stat[2]), ""),
           " & ", ifelse(nrow(fs) >= 3, sprintf("%.1f", fs$f_stat[3]), ""),
           " \\\\"),
    paste0("N & ", format(fs$n_obs[1], big.mark = ","),
           " & ", ifelse(nrow(fs) >= 2, format(fs$n_obs[2], big.mark = ","), ""),
           " & ", ifelse(nrow(fs) >= 3, format(fs$n_obs[3], big.mark = ","), ""),
           " \\\\")
  )

  # Balance tests
  if (nrow(bal) > 0) {
    tex2 <- c(tex2,
      "\\midrule",
      "\\multicolumn{4}{l}{\\textit{Panel B: Balance Tests (leniency on baseline characteristics)}} \\\\",
      " & Coef & SE & p-value \\\\"
    )

    for (r in seq_len(nrow(bal))) {
      tex2 <- c(tex2, paste0(bal$variable[r],
                              " & ", sprintf("%.4f", bal$coef[r]),
                              " & ", sprintf("%.4f", bal$se[r]),
                              " & ", sprintf("%.3f", bal$pval[r]),
                              " \\\\"))
    }
  }

  tex2 <- c(tex2,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{minipage}{0.85\\textwidth}",
    "\\vspace{0.5em}",
    "\\footnotesize \\textit{Notes:} Panel A shows first-stage regressions of court-level asylum grant rates",
    "on average judge leniency. Judge leniency is the caseload-weighted average grant rate of judges",
    "assigned to each immigration court. Panel B tests whether judge leniency predicts pre-existing",
    "county characteristics. Standard errors in parentheses.",
    "\\end{minipage}",
    "\\end{table}"
  )

  writeLines(tex2, file.path(tab_dir, "tab2_first_stage.tex"))
  cat("  Saved tab2_first_stage.tex\n")
}

## ---------------------------------------------------------------------------
## Table 3: Main IV Results
## ---------------------------------------------------------------------------

cat("Table 3: Main IV results...\n")

iv <- fread(file.path(data_dir, "iv_results.csv"))
iv_ctrl <- fread(file.path(data_dir, "iv_controls_results.csv"))
ols <- fread(file.path(data_dir, "ols_results.csv"))

if (nrow(iv) > 0) {
  # Merge IV, IV+controls, OLS
  merged <- merge(ols, iv, by = c("outcome", "outcome_var"), all = TRUE)
  merged <- merge(merged, iv_ctrl, by = c("outcome", "outcome_var"),
                  all = TRUE, suffixes = c("", "_ctrl"))

  tex3 <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Effect of Asylum Grants on Local Labor Markets}",
    "\\label{tab:main_iv}",
    "\\begin{adjustbox}{max width=\\textwidth}",
    "\\begin{tabular}{lccc}",
    "\\toprule",
    " & OLS & 2SLS & 2SLS + Controls \\\\",
    " & (1) & (2) & (3) \\\\",
    "\\midrule"
  )

  for (r in seq_len(nrow(merged))) {
    coef_ols <- ifelse(!is.na(merged$coef_ols[r]), sprintf("%.4f", merged$coef_ols[r]), "")
    se_ols <- ifelse(!is.na(merged$se_ols[r]), sprintf("(%.4f)", merged$se_ols[r]), "")
    coef_iv <- ifelse(!is.na(merged$coef_iv[r]), sprintf("%.4f", merged$coef_iv[r]), "")
    se_iv_val <- ifelse(!is.na(merged$se_iv[r]), sprintf("(%.4f)", merged$se_iv[r]), "")
    coef_ctrl <- ifelse(!is.na(merged$coef_iv_ctrl[r]), sprintf("%.4f", merged$coef_iv_ctrl[r]), "")
    se_ctrl <- ifelse(!is.na(merged$se_iv_ctrl[r]), sprintf("(%.4f)", merged$se_iv_ctrl[r]), "")

    # Stars
    add_stars <- function(coef_str, pval) {
      if (is.na(pval) || coef_str == "") return(coef_str)
      if (pval < 0.01) return(paste0(coef_str, "$^{***}$"))
      if (pval < 0.05) return(paste0(coef_str, "$^{**}$"))
      if (pval < 0.10) return(paste0(coef_str, "$^{*}$"))
      return(coef_str)
    }

    coef_ols <- add_stars(coef_ols, merged$pval_ols[r])
    coef_iv <- add_stars(coef_iv, merged$pval_iv[r])
    coef_ctrl <- add_stars(coef_ctrl, merged$pval_iv_ctrl[r])

    tex3 <- c(tex3,
      paste0(merged$outcome[r], " & ", coef_ols, " & ", coef_iv, " & ", coef_ctrl, " \\\\"),
      paste0(" & ", se_ols, " & ", se_iv_val, " & ", se_ctrl, " \\\\[4pt]")
    )
  }

  tex3 <- c(tex3,
    "\\midrule",
    "Year FE & Yes & Yes & Yes \\\\",
    "Controls & No & No & Yes \\\\",
    "N & 500--720 & 500--720 & 500 \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{adjustbox}",
    "\\begin{minipage}{0.9\\textwidth}",
    "\\vspace{0.5em}",
    "\\footnotesize \\textit{Notes:} This table reports OLS and 2SLS estimates of the effect of asylum grant rates",
    "on local labor market outcomes. The instrument is the caseload-weighted average grant rate of immigration judges",
    "assigned to each court. Controls include total population, unemployment rate, and poverty rate.",
    "Standard errors clustered at the court level in parentheses.",
    "$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.",
    "\\end{minipage}",
    "\\end{table}"
  )

  writeLines(tex3, file.path(tab_dir, "tab3_main_iv.tex"))
  cat("  Saved tab3_main_iv.tex\n")
}

## ---------------------------------------------------------------------------
## Table 4: Sector Heterogeneity
## ---------------------------------------------------------------------------

cat("Table 4: Sector heterogeneity...\n")

if (nrow(iv) > 0) {
  # Split into treatment and placebo
  treatment <- iv[!grepl("Placebo", outcome)]
  placebo <- iv[grepl("Placebo", outcome)]

  tex4 <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Sector Heterogeneity: Treatment vs. Placebo Sectors}",
    "\\label{tab:heterogeneity}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    " & IV Coef & SE & p-value & N \\\\",
    "\\midrule",
    "\\multicolumn{5}{l}{\\textit{Panel A: Treatment Sectors (low-wage, immigrant-intensive)}} \\\\"
  )

  for (r in seq_len(nrow(treatment))) {
    tex4 <- c(tex4, paste0(treatment$outcome[r],
                            " & ", sprintf("%.4f", treatment$coef_iv[r]),
                            " & ", sprintf("%.4f", treatment$se_iv[r]),
                            " & ", sprintf("%.3f", treatment$pval_iv[r]),
                            " & ", format(treatment$n_obs[r], big.mark = ","), " \\\\"))
  }

  tex4 <- c(tex4,
    "\\midrule",
    "\\multicolumn{5}{l}{\\textit{Panel B: Placebo Sectors (high-wage, native-dominated)}} \\\\"
  )

  for (r in seq_len(nrow(placebo))) {
    tex4 <- c(tex4, paste0(placebo$outcome[r],
                            " & ", sprintf("%.4f", placebo$coef_iv[r]),
                            " & ", sprintf("%.4f", placebo$se_iv[r]),
                            " & ", sprintf("%.3f", placebo$pval_iv[r]),
                            " & ", format(placebo$n_obs[r], big.mark = ","), " \\\\"))
  }

  tex4 <- c(tex4,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{minipage}{0.85\\textwidth}",
    "\\vspace{0.5em}",
    "\\footnotesize \\textit{Notes:} Panel A shows IV estimates for sectors where asylum recipients are",
    "likely to work (accommodation \\& food, administrative services). Panel B shows placebo sectors",
    "(finance, professional services) where asylum seekers are unlikely to find employment.",
    "Significant effects in Panel B violate the exclusion restriction: placebo sectors respond comparably to treatment sectors.",
    "Standard errors clustered at the court level.",
    "\\end{minipage}",
    "\\end{table}"
  )

  writeLines(tex4, file.path(tab_dir, "tab4_heterogeneity.tex"))
  cat("  Saved tab4_heterogeneity.tex\n")
}

## ---------------------------------------------------------------------------
## Table 5: Robustness Checks
## ---------------------------------------------------------------------------

cat("Table 5: Robustness...\n")

fe_file <- file.path(data_dir, "alt_fe_results.csv")
clust_file <- file.path(data_dir, "alt_clustering_results.csv")

tex5 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & IV Coef & SE & p-value & N \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Alternative Fixed Effects}} \\\\"
)

if (file.exists(fe_file)) {
  fe_dt <- fread(fe_file)
  for (r in seq_len(nrow(fe_dt))) {
    tex5 <- c(tex5, paste0(fe_dt$specification[r],
                            " & ", sprintf("%.4f", fe_dt$coef_iv[r]),
                            " & ", sprintf("%.4f", fe_dt$se_iv[r]),
                            " & ", sprintf("%.3f", fe_dt$pval_iv[r]),
                            " & ", format(fe_dt$n_obs[r], big.mark = ","), " \\\\"))
  }
}

tex5 <- c(tex5,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Alternative Clustering}} \\\\"
)

if (file.exists(clust_file)) {
  clust_dt <- fread(clust_file)
  for (r in seq_len(nrow(clust_dt))) {
    tex5 <- c(tex5, paste0(clust_dt$clustering[r],
                            " & ", sprintf("%.4f", clust_dt$coef_iv[r]),
                            " & ", sprintf("%.4f", clust_dt$se_iv[r]),
                            " & ", sprintf("%.3f", clust_dt$pval_iv[r]),
                            " & 720 \\\\"))
  }
}

tex5 <- c(tex5,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.85\\textwidth}",
  "\\vspace{0.5em}",
  "\\footnotesize \\textit{Notes:} This table shows robustness of the main IV estimate",
  "(log total employment) to alternative specifications. Panel A varies the fixed effects.",
  "Panel B varies the clustering of standard errors.",
  "The baseline specification uses year fixed effects and court-clustered standard errors.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tex5, file.path(tab_dir, "tab5_robustness.tex"))
cat("  Saved tab5_robustness.tex\n")

cat("\n=== ALL TABLES GENERATED ===\n")
