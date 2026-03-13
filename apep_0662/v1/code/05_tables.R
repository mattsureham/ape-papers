## 05_tables.R — Generate all LaTeX tables
## apep_0662: Clean Slate Laws and Statistical Discrimination

source("00_packages.R")
load("data/clean_data.RData")
load("data/analysis_results.RData")
load("data/robustness_results.RData")

cat("=== Generating Tables ===\n")

# =========================================================
# Table 1: Summary Statistics
# =========================================================
cat("Table 1: Summary Statistics\n")

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & SD & Min & Max & N \\\\\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: BLS LAUS (state-year, 2014--2025)}} \\\\\n"
)

for (i in 1:2) {
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %.2f & %.2f & %.2f & %.2f & %s \\\\\n",
            sumstats$Variable[i],
            sumstats$Mean[i], sumstats$SD[i], sumstats$Min[i], sumstats$Max[i],
            format(as.integer(sumstats$N[i]), big.mark = ",")))
}

tab1_tex <- paste0(tab1_tex,
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: ACS 1-Year (state-year, 2012--2023)}} \\\\\n"
)

for (i in 3:5) {
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %.2f & %.2f & %.2f & %.2f & %s \\\\\n",
            sumstats$Variable[i],
            sumstats$Mean[i], sumstats$SD[i], sumstats$Min[i], sumstats$Max[i],
            format(as.integer(sumstats$N[i]), big.mark = ",")))
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A reports BLS Local Area Unemployment Statistics at the state-year level, ",
  "averaging monthly observations within each year. ",
  "Panel B reports ACS 1-Year employment-to-population ratios by race. ",
  "The White--Black E-pop gap is the difference in employment-to-population ratios ",
  "between White non-Hispanic and Black populations aged 16--64. ",
  "States with Black working-age populations below 1,000 are excluded from Panel B.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "tables/tab1_summary.tex")

# =========================================================
# Table 2: Main Results — Aggregate Employment Effects
# =========================================================
cat("Table 2: Main Results\n")

cs_att_urate <- cs_urate_agg$overall.att
cs_se_urate <- cs_urate_agg$overall.se
cs_att_lemp <- cs_epop_agg$overall.att
cs_se_lemp <- cs_epop_agg$overall.se

twfe_b_urate <- coef(twfe_urate)["post"]
twfe_se_urate <- se(twfe_urate)["post"]
twfe_b_lemp <- coef(twfe_epop)["post"]
twfe_se_lemp <- se(twfe_epop)["post"]

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

pval_twfe <- function(fit, param) {
  z <- coef(fit)[param] / se(fit)[param]
  2 * pnorm(abs(z), lower.tail = FALSE)
}

pval_cs <- function(att, se_val) 2 * pnorm(abs(att / se_val), lower.tail = FALSE)

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Clean Slate Laws on Aggregate Employment}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Unemployment & Log nonfarm \\\\\n",
  " & rate (\\%) & employment \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: TWFE}} \\\\\n",
  sprintf("Clean slate & %.3f%s & %.4f%s \\\\\n",
          twfe_b_urate, stars(pval_twfe(twfe_urate, "post")),
          twfe_b_lemp, stars(pval_twfe(twfe_epop, "post"))),
  sprintf(" & (%.3f) & (%.4f) \\\\\n",
          twfe_se_urate, twfe_se_lemp),
  sprintf("N & %s & %s \\\\\n",
          format(twfe_urate$nobs, big.mark = ","),
          format(twfe_epop$nobs, big.mark = ",")),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Callaway--Sant'Anna}} \\\\\n",
  sprintf("ATT & %.3f%s & %.4f%s \\\\\n",
          cs_att_urate, stars(pval_cs(cs_att_urate, cs_se_urate)),
          cs_att_lemp, stars(pval_cs(cs_att_lemp, cs_se_lemp))),
  sprintf(" & (%.3f) & (%.4f) \\\\\n",
          cs_se_urate, cs_se_lemp),
  "\\midrule\n",
  "State FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "Cluster & State & State \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "Panel A reports TWFE estimates with state and year fixed effects. ",
  "Panel B reports Callaway and Sant'Anna (2021) aggregated ATT estimates ",
  "using never-treated states as the control group. ",
  "Treatment is defined as the year of clean slate law enactment. ",
  "Twelve states enacted clean slate laws between 2018 and 2023; ",
  "39 states and DC serve as never-treated controls. ",
  "Data: BLS Local Area Unemployment Statistics, 2014--2025. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "tables/tab2_main.tex")

# =========================================================
# Table 3: Racial Employment Gap
# =========================================================
cat("Table 3: Racial Employment Gap\n")

cs_att_gap <- cs_gap_agg$overall.att
cs_se_gap <- cs_gap_agg$overall.se
cs_att_black <- cs_black_agg$overall.att
cs_se_black <- cs_black_agg$overall.se
cs_att_white <- cs_white_agg$overall.att
cs_se_white <- cs_white_agg$overall.se

twfe_b_gap <- coef(twfe_gap)["post"]
twfe_se_gap <- se(twfe_gap)["post"]

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Clean Slate Laws and Racial Employment Gaps}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Black & White & White--Black \\\\\n",
  " & E-pop (\\%) & E-pop (\\%) & gap (pp) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: TWFE}} \\\\\n",
  sprintf("Clean slate & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          coef(twfe_black)["post"], stars(pval_twfe(twfe_black, "post")),
          coef(twfe_white)["post"], stars(pval_twfe(twfe_white, "post")),
          twfe_b_gap, stars(pval_twfe(twfe_gap, "post"))),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          se(twfe_black)["post"], se(twfe_white)["post"], twfe_se_gap),
  sprintf("N & %s & %s & %s \\\\\n",
          format(twfe_black$nobs, big.mark = ","),
          format(twfe_white$nobs, big.mark = ","),
          format(twfe_gap$nobs, big.mark = ",")),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Callaway--Sant'Anna}} \\\\\n",
  sprintf("ATT & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          cs_att_black, stars(pval_cs(cs_att_black, cs_se_black)),
          cs_att_white, stars(pval_cs(cs_att_white, cs_se_white)),
          cs_att_gap, stars(pval_cs(cs_att_gap, cs_se_gap))),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          cs_se_black, cs_se_white, cs_se_gap),
  "\\midrule\n",
  "State FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  "Cluster & State & State & State \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "Dependent variables are ACS 1-Year employment-to-population ratios for the Black ",
  "and White non-Hispanic populations aged 16--64. ",
  "Column (3) is the White--Black gap (positive = White higher). ",
  "A positive coefficient in column (3) indicates that clean slate laws widened the ",
  "racial employment gap, consistent with the statistical discrimination hypothesis ",
  "\\citep{doleac2020}. States with Black working-age populations below 1,000 excluded. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:racial_gap}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "tables/tab3_racial_gap.tex")

# =========================================================
# Table 4: Robustness
# =========================================================
cat("Table 4: Robustness\n")

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness of Employment Effects}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Unemployment & Log nonfarm \\\\\n",
  " & rate & employment \\\\\n",
  "\\midrule\n",
  sprintf("Baseline TWFE & %.3f%s & %.4f%s \\\\\n",
          twfe_b_urate, stars(pval_twfe(twfe_urate, "post")),
          twfe_b_lemp, stars(pval_twfe(twfe_epop, "post"))),
  sprintf(" & (%.3f) & (%.4f) \\\\\n", twfe_se_urate, twfe_se_lemp),
  "\\addlinespace\n",
  sprintf("Excl.\\ COVID (2020--21) & %.3f%s & %.4f%s \\\\\n",
          coef(twfe_urate_nocovid)["post"], stars(pval_twfe(twfe_urate_nocovid, "post")),
          coef(twfe_epop_nocovid)["post"], stars(pval_twfe(twfe_epop_nocovid, "post"))),
  sprintf(" & (%.3f) & (%.4f) \\\\\n",
          se(twfe_urate_nocovid)["post"], se(twfe_epop_nocovid)["post"]),
  "\\addlinespace\n",
  sprintf("Implementation date & %.3f%s & %.4f%s \\\\\n",
          coef(twfe_urate_impl)["post_impl"], stars(pval_twfe(twfe_urate_impl, "post_impl")),
          coef(twfe_epop_impl)["post_impl"], stars(pval_twfe(twfe_epop_impl, "post_impl"))),
  sprintf(" & (%.3f) & (%.4f) \\\\\n",
          se(twfe_urate_impl)["post_impl"], se(twfe_epop_impl)["post_impl"]),
  "\\addlinespace\n",
  sprintf("LOO range & [%.3f, %.3f] & \\\\\n",
          min(loo_results$coef), max(loo_results$coef)),
  "\\addlinespace\n",
  sprintf("Permutation $p$-value & %.3f & \\\\\n", perm_p_urate),
  "\\midrule\n",
  "State FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "Row 1 repeats the baseline TWFE estimate from Table~\\ref{tab:main}. ",
  "Row 2 drops 2020--2021 to remove COVID contamination. ",
  "Row 3 uses the implementation date (when automatic sealing began) instead of ",
  "the enactment date; states not yet implemented are treated as never-treated. ",
  "Row 4 shows the range of coefficients from leave-one-out estimates dropping each ",
  "treated state in turn. ",
  "Row 5 reports the permutation $p$-value from 999 random reassignments of treatment status. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "tables/tab4_robustness.tex")

# =========================================================
# Table F1: Standardized Effect Sizes (SDE)
# =========================================================
cat("Table F1: Standardized Effect Sizes\n")

classify_sde <- function(s) {
  if (is.na(s)) return("N/A")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

outcomes <- list(
  list(name = "Unemployment rate", beta = coef(twfe_urate)["post"],
       se_val = se(twfe_urate)["post"], sd_y = sd(bls_annual$urate)),
  list(name = "Log nonfarm emp.", beta = coef(twfe_epop)["post"],
       se_val = se(twfe_epop)["post"],
       sd_y = sd(bls_annual$log_emp, na.rm = TRUE)),
  list(name = "Black E-pop ratio", beta = coef(twfe_black)["post"],
       se_val = se(twfe_black)["post"],
       sd_y = sd(acs_clean$black_epop, na.rm = TRUE)),
  list(name = "W--B employment gap", beta = coef(twfe_gap)["post"],
       se_val = se(twfe_gap)["post"],
       sd_y = sd(acs_clean$bw_gap, na.rm = TRUE))
)

sde_rows <- ""
for (o in outcomes) {
  sde <- o$beta / o$sd_y
  se_sde <- o$se_val / o$sd_y
  class_label <- classify_sde(sde)
  sde_rows <- paste0(sde_rows,
    sprintf("%s & %.4f & %.4f & --- & %.4f & %.4f & %.4f & %s \\\\\n",
            o$name, o$beta, o$se_val, o$sd_y, sde, se_sde, class_label))
}

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sde_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
  "to facilitate cross-study comparison of treatment effect magnitudes. ",
  "For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) ",
  "column is marked ``---''. ",
  "\\textbf{Research question:} Does automatic criminal record sealing (``clean slate'') ",
  "affect aggregate employment and racial employment gaps? ",
  "\\textbf{Treatment:} Binary --- state enactment of clean slate automatic record sealing law. ",
  "\\textbf{Data:} BLS LAUS (state-year, 2014--2025) and ACS 1-Year (state-year, 2012--2023). ",
  "\\textbf{Method:} TWFE with state and year fixed effects, state-clustered standard errors. ",
  sprintf("\\textbf{Sample:} %s state-years (BLS), %s state-years (ACS, states with Black pop $\\geq$ 1,000). ",
          format(nrow(bls_annual), big.mark = ","),
          format(nrow(acs_clean), big.mark = ",")),
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
