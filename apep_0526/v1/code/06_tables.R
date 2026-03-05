# =============================================================================
# 06_tables.R — All tables for the paper
# =============================================================================
source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "panel_state_quarter.csv"))

# ---------------------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------------------
cat("\n=== Table 1: Summary Statistics ===\n")

# Pre-treatment period only
pre_panel <- panel[year <= 2013]

stats_by_group <- panel[, .(
  `Mean Trial Sites` = round(mean(n_trials), 1),
  `SD Trial Sites` = round(sd(n_trials), 1),
  `Mean Enrollment` = round(mean(total_enrollment), 0),
  `Mean Terminal Trials` = round(mean(n_terminal), 1),
  `Mean Non-Terminal Trials` = round(mean(n_nonterminal), 1),
  `Mean Phase I Trials` = round(mean(n_phase1), 1),
  `Mean Observational` = round(mean(n_observational), 1),
  `Industry Share` = round(mean(industry_share, na.rm = TRUE), 3),
  `N (state-quarters)` = .N
), by = .(Group = fifelse(cohort_yq > 0, "Eventually Treated", "Never Treated"))]

fwrite(stats_by_group, file.path(TABLE_DIR, "tab1_summary_stats.csv"))

# LaTeX output
sink(file.path(TABLE_DIR, "tab1_summary_stats.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Clinical Trial Activity by State-Quarter}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & Eventually Treated & Never Treated \\\\\n")
cat("\\hline\n")
for (var in setdiff(names(stats_by_group), "Group")) {
  vals <- stats_by_group[[var]]
  cat(var, " & ", vals[1], " & ", vals[2], " \\\\\n")
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize \\textit{Notes:} Panel of 51 states (including DC) $\\times$ 40 quarters (2008Q1--2017Q4). Trial sites are Phase II/III interventional drug trials registered on ClinicalTrials.gov with at least one facility in the state. Eventually Treated states enacted Right-to-Try laws before the federal act (May 2018). Never Treated states relied on the federal law.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 saved.\n")

# ---------------------------------------------------------------------------
# Table 2: Main Results (CS-DiD)
# ---------------------------------------------------------------------------
cat("\n=== Table 2: Main Results ===\n")
cs_summary <- fread(file.path(DATA_DIR, "cs_summary.csv"))

sink(file.path(TABLE_DIR, "tab2_main_results.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Right-to-Try Laws on Clinical Trial Activity}\n")
cat("\\label{tab:main}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & ATT & SE & \\textit{p}-value \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: Main Outcomes}} \\\\\n")
for (i in 1:3) {
  cat(cs_summary$outcome[i], " & ",
      sprintf("%.4f", cs_summary$att[i]), " & (",
      sprintf("%.4f", cs_summary$se[i]), ") & ",
      sprintf("%.3f", cs_summary$pval[i]), " \\\\\n")
}
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: Placebo Outcomes}} \\\\\n")
for (i in 4:6) {
  cat(cs_summary$outcome[i], " & ",
      sprintf("%.4f", cs_summary$att[i]), " & (",
      sprintf("%.4f", cs_summary$se[i]), ") & ",
      sprintf("%.3f", cs_summary$pval[i]), " \\\\\n")
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize \\textit{Notes:} Callaway--Sant'Anna (2021) estimates. ATT is the average treatment effect on the treated, aggregated across all cohorts and post-treatment periods. Outcomes are in log points (ln(Y+1)). Control group: not-yet-treated states. Estimation uses doubly robust method with universal base period. Standard errors clustered at the state level. Panel A shows outcomes directly affected by Right-to-Try (Phase II/III interventional drug trials); Panel B shows placebo outcomes that should be unaffected.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 saved.\n")

# ---------------------------------------------------------------------------
# Table 3: Robustness Checks
# ---------------------------------------------------------------------------
cat("\n=== Table 3: Robustness ===\n")
robust <- fread(file.path(DATA_DIR, "robustness_summary.csv"))
ri <- fread(file.path(DATA_DIR, "ri_summary.csv"))
power <- fread(file.path(DATA_DIR, "power_stats.csv"))

sink(file.path(TABLE_DIR, "tab3_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks: Trial Sites (Phase II/III)}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Specification & Coefficient & SE & \\textit{p}-value \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(robust)) {
  cat(robust$specification[i], " & ",
      sprintf("%.4f", robust$coef[i]), " & (",
      sprintf("%.4f", robust$se[i]), ") & ",
      sprintf("%.3f", robust$pval[i]), " \\\\\n")
}
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Additional diagnostics}} \\\\\n")
cat("Randomization Inference \\textit{p}-value & \\multicolumn{3}{c}{",
    sprintf("%.3f", ri$ri_pval), "} \\\\\n")
cat("Minimum Detectable Effect (80\\% power) & \\multicolumn{3}{c}{",
    sprintf("%.1f\\%%", power$mde_pct), "} \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize \\textit{Notes:} Outcome: log trial sites (Phase II/III interventional). Main TWFE specification: state and quarter fixed effects, standard errors clustered at the state level. Region$\\times$Quarter FE adds Census region-by-quarter fixed effects. Donut drops the quarter of adoption. Leave-one-out drops individual biotech hub states. RI \\textit{p}-value from 500 permutations of treatment assignment. MDE computed at 80\\% power, two-sided 5\\% test.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 saved.\n")

# ---------------------------------------------------------------------------
# Table 4: Right-to-Try Law Adoption Timeline
# ---------------------------------------------------------------------------
cat("\n=== Table 4: Adoption Timeline ===\n")
rtt_laws <- fread(file.path(DATA_DIR, "rtt_law_dates.csv"))
rtt_laws[, rtt_date := as.Date(rtt_date)]
rtt_laws[, Year := year(rtt_date)]

timeline <- rtt_laws[order(rtt_date), .(States = paste(state, collapse = ", "), N = .N), by = Year]

sink(file.path(TABLE_DIR, "tab4_adoption_timeline.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Right-to-Try Law Adoption by Year}\n")
cat("\\label{tab:timeline}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{clc}\n")
cat("\\hline\\hline\n")
cat("Year & States & N \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(timeline)) {
  # Wrap long state lists
  states_str <- timeline$States[i]
  cat(timeline$Year[i], " & ", states_str, " & ", timeline$N[i], " \\\\\n")
}
cat("\\hline\n")
cat("2018 & Federal Right to Try Act (May 30) & --- \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize \\textit{Notes:} Effective dates from Triage Cancer state law database. Arizona's original adoption (Proposition 303, November 2014) is used rather than the 2022 expansion. States without state-level laws before the federal act (DE, DC, HI, MA, NJ, NM, NY, RI, VT) serve as the never-treated group.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 saved.\n")

cat("\nAll tables complete.\n")
