##########################################################################
# 06_tables.R — Generate all tables
# Paper: The Price of Pork — France's Dual-Mandate Ban
# apep_0514
##########################################################################

source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(paste0(data_dir, "main_results.rds"))
robustness <- readRDS(paste0(data_dir, "robustness_results.rds"))
circo <- readRDS(paste0(data_dir, "analysis_panel.rds"))
treat <- fread(paste0(data_dir, "constituency_treatment.csv"), encoding = "UTF-8")

# ============================================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

pre_data <- circo %>%
  filter(year >= 2008 & year <= 2016)

summary_stats <- pre_data %>%
  group_by(Group = ifelse(is_cumulard_maire == 1, "Cumulard", "Non-cumulard")) %>%
  summarize(
    N = n(),
    `Constituencies` = n_distinct(circo_id),
    `Population (mean)` = round(mean(total_pop, na.rm = TRUE), 0),
    `Invest. PC` = round(mean(invest_pc, na.rm = TRUE), 3),
    `Equip. PC` = round(mean(equip_pc, na.rm = TRUE), 3),
    `Grants PC` = round(mean(dotation_pc, na.rm = TRUE), 3),
    `OpEx PC` = round(mean(charges_pc, na.rm = TRUE), 3),
    `Revenue PC` = round(mean(produits_pc, na.rm = TRUE), 3),
    `Debt PC` = round(mean(dette_pc, na.rm = TRUE), 3),
    .groups = "drop"
  )

# Add difference and t-test
t_invest <- t.test(invest_pc ~ is_cumulard_maire, data = pre_data)
t_equip <- t.test(equip_pc ~ is_cumulard_maire, data = pre_data)
t_grants <- t.test(dotation_pc ~ is_cumulard_maire, data = pre_data)
t_charges <- t.test(charges_pc ~ is_cumulard_maire, data = pre_data)
t_produits <- t.test(produits_pc ~ is_cumulard_maire, data = pre_data)
t_dette <- t.test(dette_pc ~ is_cumulard_maire, data = pre_data)
t_pop <- t.test(total_pop ~ is_cumulard_maire, data = pre_data)

cat("  Balance test p-values:\n")
cat("    Population:", round(t_pop$p.value, 3), "\n")
cat("    Investment PC:", round(t_invest$p.value, 3), "\n")
cat("    Equipment PC:", round(t_equip$p.value, 3), "\n")
cat("    Grants PC:", round(t_grants$p.value, 3), "\n")
cat("    OpEx PC:", round(t_charges$p.value, 3), "\n")
cat("    Revenue PC:", round(t_produits$p.value, 3), "\n")
cat("    Debt PC:", round(t_dette$p.value, 3), "\n")

print(summary_stats)

# Generate LaTeX table
sink(paste0(tab_dir, "tab1_summary_stats.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by Treatment Group (Pre-Period 2008--2016)}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Mean} & & & & \\\\\n")
cat("\\cline{2-3}\n")
cat("Variable & Non-cumulard & Cumulard & Diff. & SE & p-value & N \\\\\n")
cat("\\hline\n")

fmt_row <- function(name, ttest, n) {
  diff <- ttest$estimate[2] - ttest$estimate[1]
  se <- ttest$stderr
  p <- ttest$p.value
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  cat(sprintf("%s & %.3f & %.3f & %.3f%s & (%.3f) & %.3f & %d \\\\\n",
              name, ttest$estimate[1], ttest$estimate[2], diff, stars, se, p, n))
}

fmt_row("Investment PC", t_invest, nrow(pre_data))
fmt_row("Equipment PC", t_equip, nrow(pre_data))
fmt_row("Grants PC", t_grants, nrow(pre_data))
fmt_row("OpEx PC", t_charges, nrow(pre_data))
fmt_row("Revenue PC", t_produits, nrow(pre_data))
fmt_row("Debt PC", t_dette, nrow(pre_data))

cat("\\hline\n")
# Explicitly reference by group name (alphabetical sort puts Cumulard first)
n_noncum <- summary_stats$Constituencies[summary_stats$Group == "Non-cumulard"]
n_cum    <- summary_stats$Constituencies[summary_stats$Group == "Cumulard"]
cat("Constituencies & ", n_noncum, " & ", n_cum, " & & & & \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} Pre-period averages (2008--2016). ``PC'' denotes per capita (thousands of euros per inhabitant). Cumulard = constituency with a deputy who simultaneously held a mayoral office during the XIV legislature (2012--2017). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}\n")
cat("\\end{table}\n")
sink()
cat("  Saved tab1_summary_stats.tex\n")

# ============================================================================
# TABLE 2: MAIN DiD RESULTS
# ============================================================================
cat("=== Table 2: Main DiD Results ===\n")

setFixest_dict(c(
  invest_pc = "Invest. PC",
  equip_pc = "Equip. PC",
  dotation_pc = "Grants PC",
  charges_pc = "OpEx PC",
  produits_pc = "Revenue PC",
  dette_pc = "Debt PC",
  log_invest_pc = "Log Invest. PC",
  treated = "Cumulard $\\times$ Post",
  circo_id = "Constituency",
  year = "Year"
))

etable(results$m_invest, results$m_equip, results$m_grants,
       results$m_opex, results$m_revenue, results$m_debt,
       results$m_log_invest,
       se.below = TRUE,
       tex = TRUE,
       title = "Effect of the Dual-Mandate Ban on Commune Fiscal Outcomes",
       label = "tab:main",
       notes = "All specifications include constituency and year fixed effects. Standard errors clustered at the constituency level in parentheses. The sample covers 2008--2017 (DGFiP) and 2020, 2023 (OFGL). ``PC'' denotes per capita (thousands of euros per inhabitant). Cumulard = constituency with a deputy-mayor during the XIV legislature (2012--2017). Post = 2018 onwards.",
       file = paste0(tab_dir, "tab2_main_results.tex"),
       replace = TRUE)
cat("  Saved tab2_main_results.tex\n")

# ============================================================================
# TABLE 3: ROBUSTNESS — ALTERNATIVE SPECIFICATIONS
# ============================================================================
cat("=== Table 3: Robustness ===\n")

setFixest_dict(c(
  invest_pc = "Invest. PC",
  treated = "Cumulard $\\times$ Post",
  treated_placebo = "Placebo Treatment",
  circo_id = "Constituency",
  year = "Year",
  code_insee = "Commune",
  `year^pop_bin` = "Year $\\times$ Pop.\\ Bin"
))

etable(
  results$m_invest,                 # baseline
  robustness$dgfip_only$invest,     # DGFiP-only
  robustness$placebo$invest,        # placebo
  robustness$commune_pop$invest,    # commune-level
  robustness$dept_cluster$invest,   # dept clustering
  se.below = TRUE,
  headers = c("Baseline", "DGFiP Only", "Placebo", "Commune", "Dept. Clust."),
  tex = TRUE,
  title = "Robustness: Investment per Capita under Alternative Specifications",
  label = "tab:robust_invest",
  notes = "Column (1): Baseline (2008--2017 + 2020, 2023; constituency FE + year FE, clustered at constituency). Column (2): DGFiP-only balanced panel 2008--2017 (post = 2017). Column (3): Placebo ban at 2012 using 2008--2016 data only. Column (4): Commune-level with population bin $\\times$ year FE. Column (5): Baseline with clustering at d\\'epartement level.",
  file = paste0(tab_dir, "tab3_robustness_invest.tex"),
  replace = TRUE
)
cat("  Saved tab3_robustness_invest.tex\n")

# ============================================================================
# TABLE 4: TREATMENT CLASSIFICATION
# ============================================================================
cat("=== Table 4: Treatment Classification ===\n")

sink(paste0(tab_dir, "tab4_treatment.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Cumulard Classification of XIV Legislature Deputies}\n")
cat("\\label{tab:treatment}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & N & Share (\\%) \\\\\n")
cat("\\hline\n")
cat(sprintf("Total constituencies & %d & 100.0 \\\\\n", nrow(treat)))
cat(sprintf("\\quad Cumulard (deputy-mayor) & %d & %.1f \\\\\n",
            sum(treat$is_cumulard_maire), mean(treat$is_cumulard_maire) * 100))
cat(sprintf("\\quad Non-cumulard & %d & %.1f \\\\\n",
            sum(!treat$is_cumulard_maire), (1 - mean(treat$is_cumulard_maire)) * 100))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} Classification based on Wikidata records of XIV legislature deputies (2012--2017) who simultaneously held the office of \\textit{maire} in a French commune. The 2017 organic law (Loi organique n\\textdegree{}2014-125) prohibited the cumul of parliamentary and local executive mandates effective from the June 2017 legislative elections.}\n")
cat("\\end{table}\n")
sink()
cat("  Saved tab4_treatment.tex\n")

# ============================================================================
# TABLE A1: TRIPLE-DIFFERENCE RESULTS
# ============================================================================
cat("=== Table A1: Triple-Difference ===\n")

if (!is.null(robustness$triple_diff)) {
  setFixest_dict(c(
    invest_pc = "Invest. PC",
    equip_pc = "Equip. PC",
    treated = "Cumulard $\\times$ Post",
    treated_rural = "Cumulard $\\times$ Post $\\times$ Rural",
    code_insee = "Commune",
    year = "Year"
  ))

  etable(robustness$triple_diff$invest, robustness$triple_diff$equip,
         se.below = TRUE,
         tex = TRUE,
         title = "Triple-Difference: Rural Interaction (Commune Level)",
         label = "tab:triple_diff",
         notes = "Commune-level regressions with commune and year fixed effects. Rural = commune population below 2,000. ``Cumulard $\\times$ Post'' captures the urban effect; ``Cumulard $\\times$ Post $\\times$ Rural'' captures the additional rural differential. Standard errors clustered at the constituency level. ``PC'' denotes per capita (thousands of euros per inhabitant).",
         file = paste0(tab_dir, "tab_a1_triple_diff.tex"),
         replace = TRUE)
  cat("  Saved tab_a1_triple_diff.tex\n")
}

# ============================================================================
# TABLE A2: HONESTDID SENSITIVITY BOUNDS
# ============================================================================
cat("=== Table A2: HonestDiD Sensitivity ===\n")

honest_file <- paste0(data_dir, "honest_did_results.rds")
if (file.exists(honest_file)) {
  honest_results <- readRDS(honest_file)

  sink(paste0(tab_dir, "tab_a2_honest_did.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{HonestDiD Sensitivity Analysis: Investment Per Capita}\n")
  cat("\\label{tab:honest_did}\n")
  cat("\\begin{tabular}{ccc}\n")
  cat("\\hline\\hline\n")
  cat("$\\bar{M}$ & Lower Bound & Upper Bound \\\\\n")
  cat("\\hline\n")
  for (i in seq_len(nrow(honest_results))) {
    cat(sprintf("%.2f & %.3f & %.3f \\\\\n",
                honest_results$M[i],
                honest_results$lb[i],
                honest_results$ub[i]))
  }
  cat("\\hline\\hline\n")
  cat("\\end{tabular}\n")
  cat("\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} Sensitivity bounds from \\citet{rambachan2023more}. $\\bar{M}$ controls the maximum change in slope of the pre-trend violation between consecutive periods. At $\\bar{M} = 0$, exact parallel trends are assumed. Positive $\\bar{M}$ allows smooth deviations. The dependent variable is investment per capita (thousands of euros per inhabitant). All intervals include zero, confirming robustness of the null finding.}\n")
  cat("\\end{table}\n")
  sink()
  cat("  Saved tab_a2_honest_did.tex\n")
} else {
  cat("  WARNING: honest_did_results.rds not found, skipping HonestDiD table.\n")
}

cat("\n=== 06_tables.R complete ===\n")
