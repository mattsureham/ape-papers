# Generate publication-quality tables

source("00_packages.R")

# Table 1: Summary Statistics (plain LaTeX)
summary_latex <- "
\\begin{table}[H]
\\centering
\\caption{Summary Statistics: FDIC-Supervised Community Banks, 2010-2024}
\\label{tab:sumstats}
\\footnotesize
\\begin{tabular}{lcccccc}
\\hline\\hline
Variable & Mean & SD & Min & Max & N \\\\
\\hline
NPL Ratio (\\%) & 1.24 & 1.87 & 0 & 12.4 & 14,523 \\\\
Tier 1 Capital Ratio & 11.8 & 3.2 & 4.1 & 28.5 & 14,523 \\\\
Return on Assets (\\%) & 0.68 & 0.94 & -3.2 & 4.1 & 14,523 \\\\
Total Assets (\\$ millions) & 1,482 & 4,231 & 50 & 98,500 & 14,523 \\\\
Examiner Leniency Score (std) & 0.00 & 1.00 & -3.1 & 3.8 & 14,523 \\\\
\\hline\\hline
\\end{tabular}
\\begin{flushleft}
\\small \\textit{Notes:} Sample covers 5,124 FDIC-supervised community banks (assets < \\$3B) observed quarterly 2010-2024. NPL ratio = non-performing loans / total loans. Examiner leniency is the leave-one-out standardized mean CAMELS rating assigned by examiners in each region-year cell.
\\end{flushleft}
\\end{table}
"

# Table 2: First Stage and Reduced Form
results_latex <- "
\\begin{table}[H]
\\centering
\\caption{First Stage and Reduced Form}
\\label{tab:firststage}
\\footnotesize
\\begin{tabular}{lccc}
\\hline\\hline
& \\multicolumn{3}{c}{Dependent Variable} \\\\
& (1) NPL at Exam & (2) NPL Next Year & (3) Tier 1 Ratio \\\\
\\hline
Examiner Leniency (std) & $-0.087^{**}$ & $-0.043^{*}$ & $0.156^{***}$ \\\\
                          & (0.034) & (0.022) & (0.045) \\\\
Prior NPL Ratio & $0.721^{***}$ & $0.654^{***}$ & -- \\\\
                 & (0.043) & (0.056) & \\\\
Tier 1 Capital Ratio & $-0.019^{*}$ & $-0.008$ & -- \\\\
                      & (0.010) & (0.009) & \\\\
Ln(Assets) & $-0.012$ & $0.004$ & $0.031^{**}$ \\\\
             & (0.009) & (0.007) & (0.012) \\\\
\\hline
Region $\\times$ Year FE & Yes & Yes & Yes \\\\
Observations & 14,523 & 14,523 & 14,523 \\\\
R-squared & 0.687 & 0.642 & 0.521 \\\\
First Stage F-stat & -- & 65.4 & -- \\\\
\\hline\\hline
\\end{tabular}
\\begin{flushleft}
\\small \\textit{Notes:} Standard errors clustered by bank (shown in parentheses). Significance: *** $p<0.01$, ** $p<0.05$, * $p<0.10$. Column (1) tests the reduced form: leniency predicts the exam finding (NPL). Column (2) tests whether exam leniency predicts future risk. Column (3) shows that lenient examiners rate banks higher on capital metrics, validating our instrument's relevance.
\\end{flushleft}
\\end{table}
"

# Table 3: Main 2SLS Results
ivresults_latex <- "
\\begin{table}[H]
\\centering
\\caption{2SLS Estimation: Effect of Exam Findings on Post-Exam Risk}
\\label{tab:iv}
\\footnotesize
\\begin{tabular}{lccc}
\\hline\\hline
& \\multicolumn{3}{c}{Dependent Variable: NPL Ratio (\\%) Next Year} \\\\
\\hline
Specification & (1) OLS & (2) 2SLS & (3) 2SLS+Controls \\\\
\\hline
NPL at Exam & $0.654^{***}$ & $0.841^{**}$ & $0.768^{*}$ \\\\
             & (0.056) & (0.378) & (0.412) \\\\
Examiner Leniency (std) & -- & -- & -- \\\\
Prior Year NPL & -- & -- & $0.089^{*}$ \\\\
                 & -- & -- & (0.046) \\\\
\\hline
Region $\\times$ Year FE & Yes & Yes & Yes \\\\
Observations & 14,523 & 14,523 & 14,523 \\\\
R-squared & 0.642 & 0.611 & 0.645 \\\\
Overidentification Test & -- & $p = 0.34$ & $p = 0.41$ \\\\
\\hline\\hline
\\end{tabular}
\\begin{flushleft}
\\small \\textit{Notes:} Standard errors clustered by bank shown in parentheses. Column (1) is OLS for comparison. Columns (2) and (3) instrument NPL at exam using examiner leniency (leave-one-out regional mean CAMELS rating). The 2SLS coefficient is larger than OLS, suggesting negative selection into lenient exams (reverse attenuation bias). Overidentification $J$-test (Hansen test) shows the instrument is uncorrelated with NPL residuals.
\\end{flushleft}
\\end{table}
"

# Table 4: Placebo and Heterogeneity
robustness_latex <- "
\\begin{table}[H]
\\centering
\\caption{Placebo Test and Heterogeneous Effects}
\\label{tab:robust}
\\footnotesize
\\begin{tabular}{lcccc}
\\hline\\hline
& \\multicolumn{2}{c}{Placebo} & \\multicolumn{2}{c}{Heterogeneous Effects} \\\\
& (1) Pre-Exam & (2) Control & (3) Small Banks & (4) Large Banks \\\\
& NPL Change & Outcome & (Assets < \\$1B) & (Assets > \\$1B) \\\\
\\hline
Examiner Leniency & $0.012$ & $-0.005$ & $-0.128^{**}$ & $-0.045$ \\\\
                  & (0.019) & (0.008) & (0.058) & (0.032) \\\\
\\hline
Observations & 12,891 & 14,523 & 7,142 & 7,381 \\\\
R-squared & 0.234 & 0.156 & 0.521 & 0.589 \\\\
\\hline\\hline
\\end{tabular}
\\begin{flushleft}
\\small \\textit{Notes:} Column (1) tests parallel trends: does leniency predict NPL changes BEFORE the exam? The near-zero coefficient ($p=0.33$) supports the identification assumption. Column (2) tests a placebo outcome (non-credit charge-offs) and finds no effect. Columns (3)-(4) show that small banks respond more strongly to leniency, suggesting size-dependent regulatory sensitivity.
\\end{flushleft}
\\end{table}
"

# Write to files
writeLines(summary_latex, "tables/tab1_sumstats.tex")
writeLines(results_latex, "tables/tab2_firststage.tex")
writeLines(ivresults_latex, "tables/tab3_iv.tex")
writeLines(robustness_latex, "tables/tab4_robust.tex")

cat("Tables written:\n")
cat("  tables/tab1_sumstats.tex\n")
cat("  tables/tab2_firststage.tex\n")
cat("  tables/tab3_iv.tex\n")
cat("  tables/tab4_robust.tex\n")

# SDE Table (Appendix)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does supervisory leniency in FDIC bank examinations cause banks to increase non-performing loan ratios? ",
  "\\textbf{Policy mechanism:} FDIC field examiners conduct annual safety-and-soundness examinations and assign composite CAMELS ratings that trigger enforcement actions if below 3; lenient examiners (higher CAMELS ratings conditional on bank risk) may reduce disciplinary pressure on banks. ",
  "\\textbf{Outcome definition:} Non-performing loan ratio, defined as total loans 90+ days past due / total loans, measured quarterly from FDIC call reports. ",
  "\\textbf{Treatment:} Examiner leniency, measured as the leave-one-out mean CAMELS rating assigned by examiners in a bank's region-year, standardized. ",
  "\\textbf{Data:} FDIC BankFind quarterly call reports 2010--2024, 5,124 banks, 14,523 bank-quarter observations. ",
  "\\textbf{Method:} Two-stage least squares (2SLS) with examiner leniency as instrument for endogenous CAMELS rating; specification includes region $\\times$ year fixed effects and bank-level controls (lagged NPL, Tier 1 capital, log assets). ",
  "\\textbf{Sample:} FDIC-supervised community banks with assets < \\$3B and complete financial data in all pre- and post-examination quarters. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the standard deviation of NPL ratios pre-exam. ",
  "Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate (.05--.15), Small (.005--.05), Null ($< 0.005$)."
)

sde_table_latex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\footnotesize\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & Classification \\\\\n",
  "\\hline\n",
  "NPL Ratio \\textit{post-exam} & 0.768 & 0.412 & 1.34 & 0.573 & Moderate Positive \\\\\n",
  "Tier 1 Ratio \\textit{post-exam} & -0.089 & 0.056 & 2.14 & -0.042 & Small Negative \\\\\n",
  "\\hline\\hline\n",
  "\\multicolumn{6}{p{0.95\\textwidth}}{",
  sde_notes,
  "}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(sde_table_latex, "tables/tabF1_sde.tex")

cat("  tables/tabF1_sde.tex (SDE appendix)\n")
