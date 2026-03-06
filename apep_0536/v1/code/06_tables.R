# ==============================================================================
# 06_tables.R — Generate all tables
# APEP apep_0536: FTTH, Polarization, and Misinformation in France
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

cat("=== Table 1: Summary Statistics ===\n")

sumstats <- fread(file.path(data_dir, "summary_statistics.csv"))

# Add pre/post breakdown
pre <- panel[ftth_coverage == 0]
post <- panel[ftth_coverage > 0]

sumstats_full <- data.table(
  Variable = c("\\emph{Outcome Variables}", "",
               "Anti-system vote share (\\% inscrits)", "Anti-system vote share (\\% exprimes)",
               "Turnout", "Blank/null vote share",
               "", "\\emph{Treatment Variables}", "",
               "FTTH coverage rate", "Treated ($>$25\\%)", "Treated ($>$50\\%)"),
  `Full Sample` = c("", "",
    sprintf("%.3f (%.3f)", mean(panel$antisystem_share, na.rm=T), sd(panel$antisystem_share, na.rm=T)),
    sprintf("%.3f (%.3f)", mean(panel$antisystem_share_expr, na.rm=T), sd(panel$antisystem_share_expr, na.rm=T)),
    sprintf("%.3f (%.3f)", mean(panel$turnout, na.rm=T), sd(panel$turnout, na.rm=T)),
    sprintf("%.3f (%.3f)", mean(panel$blank_null_share, na.rm=T), sd(panel$blank_null_share, na.rm=T)),
    "", "", "",
    sprintf("%.3f (%.3f)", mean(panel$ftth_coverage, na.rm=T), sd(panel$ftth_coverage, na.rm=T)),
    sprintf("%.3f", mean(panel$treated_25, na.rm=T)),
    sprintf("%.3f", mean(panel$treated_50, na.rm=T))),
  `Pre-FTTH` = c("", "",
    sprintf("%.3f (%.3f)", mean(pre$antisystem_share, na.rm=T), sd(pre$antisystem_share, na.rm=T)),
    sprintf("%.3f (%.3f)", mean(pre$antisystem_share_expr, na.rm=T), sd(pre$antisystem_share_expr, na.rm=T)),
    sprintf("%.3f (%.3f)", mean(pre$turnout, na.rm=T), sd(pre$turnout, na.rm=T)),
    sprintf("%.3f (%.3f)", mean(pre$blank_null_share, na.rm=T), sd(pre$blank_null_share, na.rm=T)),
    "", "", "", "0.000", "0.000", "0.000"),
  `Post-FTTH` = c("", "",
    sprintf("%.3f (%.3f)", mean(post$antisystem_share, na.rm=T), sd(post$antisystem_share, na.rm=T)),
    sprintf("%.3f (%.3f)", mean(post$antisystem_share_expr, na.rm=T), sd(post$antisystem_share_expr, na.rm=T)),
    sprintf("%.3f (%.3f)", mean(post$turnout, na.rm=T), sd(post$turnout, na.rm=T)),
    sprintf("%.3f (%.3f)", mean(post$blank_null_share, na.rm=T), sd(post$blank_null_share, na.rm=T)),
    "", "", "",
    sprintf("%.3f (%.3f)", mean(post$ftth_coverage, na.rm=T), sd(post$ftth_coverage, na.rm=T)),
    sprintf("%.3f", mean(post$treated_25, na.rm=T)),
    sprintf("%.3f", mean(post$treated_50, na.rm=T)))
)

# Write LaTeX
sink(file.path(tab_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Summary Statistics}\n\\label{tab:sumstats}\n")
cat("\\begin{tabular}{lccc}\n\\hline\\hline\n")
cat("& Full Sample & Pre-FTTH & Post-FTTH \\\\\n\\hline\n")
for (i in 1:nrow(sumstats_full)) {
  cat(sumstats_full$Variable[i], "&", sumstats_full$`Full Sample`[i], "&",
      sumstats_full$`Pre-FTTH`[i], "&", sumstats_full$`Post-FTTH`[i], "\\\\\n")
}
cat("\\hline\n")
cat("Observations &", nrow(panel), "&", nrow(pre), "&", nrow(post), "\\\\\n")
cat("Departments &", uniqueN(panel$dept_code), "&", uniqueN(pre$dept_code), "&",
    uniqueN(post$dept_code), "\\\\\n")
cat("Elections &", uniqueN(panel$id_election), "&", uniqueN(pre$id_election), "&",
    uniqueN(post$id_election), "\\\\\n")
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{minipage}{0.9\\textwidth}\n\\vspace{0.3em}\n")
cat("\\footnotesize \\emph{Notes:} Standard deviations in parentheses. ")
cat("Anti-system parties: RN/FN + LFI + Reconqu\\^ete. Pre-FTTH = elections before 2019. ")
cat("Post-FTTH = elections from 2019 onward. ")
cat("Panel: 96 metropolitan departments $\\times$ 11 elections (1999--2024).\n")
cat("\\end{minipage}\n\\end{table}\n")
sink()
cat("  Saved tab1_summary.tex\n")

# ==============================================================================
# Table 2: Main Results
# ==============================================================================

cat("=== Table 2: Main Results ===\n")

# Re-estimate models for clean table
mod1 <- feols(antisystem_share ~ ftth_coverage | dept_id + election_id,
              data = panel, cluster = ~dept_code)
mod2 <- feols(antisystem_share ~ treated_50 | dept_id + election_id,
              data = panel, cluster = ~dept_code)
mod3 <- feols(turnout ~ ftth_coverage | dept_id + election_id,
              data = panel, cluster = ~dept_code)
mod4 <- feols(blank_null_share ~ ftth_coverage | dept_id + election_id,
              data = panel, cluster = ~dept_code)
mod5 <- feols(antisystem_share_expr ~ ftth_coverage | dept_id + election_id,
              data = panel, cluster = ~dept_code)

# Presidential only
pres_panel <- panel[election_type == "pres"]
mod6 <- feols(antisystem_share ~ ftth_coverage | dept_id + election_id,
              data = pres_panel, cluster = ~dept_code)

etable(mod1, mod2, mod3, mod4, mod5, mod6,
       file = file.path(tab_dir, "tab2_main_results.tex"),
       title = "Effect of FTTH Coverage on Political Outcomes",
       label = "tab:main",
       headers = c("Anti-system", "Anti-system", "Turnout", "Blank/Null",
                    "Anti-system (expr.)", "Pres. Only"),
       notes = paste("All specifications include department and election fixed effects.",
                      "Standard errors clustered at department level in parentheses.",
                      "Anti-system = RN/FN + LFI + Reconqu\\^ete vote share.",
                      "Columns (1) and (6): continuous FTTH coverage.",
                      "Column (2): binary indicator for $>$50\\% coverage.",
                      "Columns (3)-(5): alternative outcomes.",
                      "Column (6): presidential elections only."),
       style.tex = style.tex("aer"),
       replace = TRUE)

cat("  Saved tab2_main_results.tex\n")

# ==============================================================================
# Table 3: CS-DiD Results
# ==============================================================================

cat("=== Table 3: CS-DiD Results ===\n")

cs_main <- fread(file.path(data_dir, "cs_did_results.csv"))
cs_sec <- fread(file.path(data_dir, "cs_secondary_results.csv"))

sink(file.path(tab_dir, "tab3_cs_did.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Callaway-Sant'Anna Difference-in-Differences Estimates}\n\\label{tab:csdid}\n")
cat("\\begin{tabular}{lcccc}\n\\hline\\hline\n")
cat("& Anti-system & Turnout & Blank/Null & Anti-system \\\\\n")
cat("& (inscrits) & & & (exprimes) \\\\\n\\hline\n")
cat(sprintf("ATT & %.4f & %.4f & %.4f & %.4f \\\\\n",
    cs_main$estimate, cs_sec[outcome == "turnout", estimate],
    cs_sec[outcome == "blank_null_share", estimate],
    cs_sec[outcome == "antisystem_share_expr", estimate]))
cat(sprintf("& (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
    cs_main$se, cs_sec[outcome == "turnout", se],
    cs_sec[outcome == "blank_null_share", se],
    cs_sec[outcome == "antisystem_share_expr", se]))
cat(sprintf("95\\%% CI & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\\n",
    cs_main$ci_lower, cs_main$ci_upper,
    cs_sec[outcome == "turnout", ci_lower], cs_sec[outcome == "turnout", ci_upper],
    cs_sec[outcome == "blank_null_share", ci_lower], cs_sec[outcome == "blank_null_share", ci_upper],
    cs_sec[outcome == "antisystem_share_expr", ci_lower], cs_sec[outcome == "antisystem_share_expr", ci_upper]))
cat("\\hline\n")
cat("Estimator & \\multicolumn{4}{c}{Callaway \\& Sant'Anna (2021)} \\\\\n")
cat("Control group & \\multicolumn{4}{c}{Not-yet-treated} \\\\\n")
cat("Treatment & \\multicolumn{4}{c}{FTTH coverage $>$ 50\\%} \\\\\n")
cat(sprintf("Observations & \\multicolumn{4}{c}{%d} \\\\\n", nrow(panel)))
cat(sprintf("Departments & \\multicolumn{4}{c}{%d} \\\\\n", uniqueN(panel$dept_code)))
cat(sprintf("Elections & \\multicolumn{4}{c}{%d} \\\\\n", uniqueN(panel$id_election)))
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{minipage}{0.9\\textwidth}\n\\vspace{0.3em}\n")
cat("\\footnotesize \\emph{Notes:} Analytical standard errors in parentheses. ")
cat("Treatment defined as department crossing 50\\% FTTH coverage threshold. ")
cat("Not-yet-treated departments serve as the comparison group. ")
cat("Base period varies by cohort.\n")
cat("\\end{minipage}\n\\end{table}\n")
sink()
cat("  Saved tab3_cs_did.tex\n")

# ==============================================================================
# Table 4: Robustness
# ==============================================================================

cat("=== Table 4: Robustness ===\n")

robustness <- fread(file.path(data_dir, "robustness_results.csv"))

sink(file.path(tab_dir, "tab4_robustness.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Robustness Checks}\n\\label{tab:robustness}\n")
cat("\\begin{tabular}{lccc}\n\\hline\\hline\n")
cat("Specification & Estimate & SE & $N$ \\\\\n\\hline\n")
for (i in 1:nrow(robustness)) {
  est <- robustness$estimate[i]
  se_val <- if ("se" %in% names(robustness)) robustness$se[i] else NA
  n_val <- if ("n_obs" %in% names(robustness)) robustness$n_obs[i] else NA
  if (is.na(est)) next  # Skip NA rows
  se_str <- ifelse(is.na(se_val), "", sprintf("%.4f", se_val))
  n_str <- ifelse(is.na(n_val), "", sprintf("%d", n_val))
  cat(robustness$specification[i], "&", sprintf("%.4f", est), "&",
      paste0("(", se_str, ")"), "&", n_str, "\\\\\n")
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{minipage}{0.85\\textwidth}\n\\vspace{0.3em}\n")
cat("\\footnotesize \\emph{Notes:} All specifications include department and election/period fixed effects. ")
cat("Standard errors clustered at the department level in parentheses. ")
cat("Baseline uses continuous FTTH coverage. ")
cat("Threshold specifications use binary treatment indicators.\n")
cat("\\end{minipage}\n\\end{table}\n")
sink()
cat("  Saved tab4_robustness.tex\n")

# ==============================================================================
# Table 5: Balance Tests
# ==============================================================================

cat("=== Table 5: Balance Tests ===\n")

balance <- fread(file.path(data_dir, "balance_test_results.csv"))

sink(file.path(tab_dir, "tab5_balance.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Balance Tests: Pre-Treatment Characteristics and FTTH Rollout Speed}\n\\label{tab:balance}\n")
cat("\\begin{tabular}{lccc}\n\\hline\\hline\n")
cat("& \\multicolumn{3}{c}{Dependent Variable: FTTH Coverage (2022)} \\\\\n")
cat("\\cmidrule(lr){2-4}\n")
cat("Predictor (2012 baseline) & Coefficient & SE & $p$-value \\\\\n\\hline\n")
# Show simple regressions (first two rows) and joint (last two)
cat("\\emph{Simple regressions:} & & & \\\\\n")
for (i in 1:min(2, nrow(balance))) {
  cat("~~", balance$predictor[i], "&",
      sprintf("%.3f", balance$estimate[i]), "&",
      sprintf("%.3f", balance$se[i]), "&",
      sprintf("%.3f", balance$pvalue[i]), "\\\\\n")
  cat(sprintf("~~\\quad $R^2$ & \\multicolumn{3}{c}{%.3f} \\\\\n", balance$r_squared[i]))
}
if (nrow(balance) > 2) {
  cat("\\emph{Joint regression:} & & & \\\\\n")
  for (i in 3:nrow(balance)) {
    cat("~~", balance$predictor[i], "&",
        sprintf("%.3f", balance$estimate[i]), "&",
        sprintf("%.3f", balance$se[i]), "&",
        sprintf("%.3f", balance$pvalue[i]), "\\\\\n")
  }
  cat(sprintf("~~\\quad $R^2$ & \\multicolumn{3}{c}{%.3f} \\\\\n", balance$r_squared[nrow(balance)]))
}
cat("\\hline\n")
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{minipage}{0.85\\textwidth}\n\\vspace{0.3em}\n")
cat("\\footnotesize \\emph{Notes:} OLS regressions of 2022 Q2 FTTH coverage on ")
cat("2012 presidential election outcomes. $N = 96$ departments. ")
cat("A null coefficient indicates that baseline political composition does not predict ")
cat("FTTH deployment speed, supporting the parallel trends assumption.\n")
cat("\\end{minipage}\n\\end{table}\n")
sink()
cat("  Saved tab5_balance.tex\n")

cat("\n06_tables.R complete.\n")
