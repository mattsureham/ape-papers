## ============================================================================
## 06_tables.R — Networked Anxiety (apep_0562)
## Generate all LaTeX tables from saved CSV data
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
TAB_DIR <- "../tables"
dir.create(TAB_DIR, showWarnings = FALSE)

## ============================================================================
## TABLE 1: Summary Statistics
## ============================================================================

cat("\n=== Table 1: Summary Statistics ===\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))

## Full panel summary
vars_summary <- panel[, .(
  mean_rn = mean(rn_share, na.rm = TRUE),
  sd_rn = sd(rn_share, na.rm = TRUE),
  mean_nd = mean(network_dispersal, na.rm = TRUE),
  sd_nd = sd(network_dispersal, na.rm = TRUE),
  mean_own = mean(own_new_places, na.rm = TRUE),
  sd_own = sd(own_new_places, na.rm = TRUE),
  mean_votes = mean(total_votes, na.rm = TRUE),
  sd_votes = sd(total_votes, na.rm = TRUE),
  n_depts = n_distinct(dept_code),
  n_elections = n_distinct(election_label),
  n_obs = .N
)]

## Pre/post breakdown
period_stats <- panel[, .(
  mean_rn = round(mean(rn_share), 1),
  sd_rn = round(sd(rn_share), 1),
  n = .N
), by = post]

## Build LaTeX table
sumstats_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Variable & Mean & SD & Min & Max \\\\",
  "\\midrule",
  sprintf("RN Vote Share (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\",
          vars_summary$mean_rn, vars_summary$sd_rn,
          min(panel$rn_share), max(panel$rn_share)),
  sprintf("Network Dispersal & %.2f & %.2f & %.2f & %.2f \\\\",
          vars_summary$mean_nd, vars_summary$sd_nd,
          min(panel$network_dispersal, na.rm = TRUE),
          max(panel$network_dispersal, na.rm = TRUE)),
  sprintf("Own New Places & %.1f & %.1f & %.1f & %.1f \\\\",
          vars_summary$mean_own, vars_summary$sd_own,
          min(panel$own_new_places, na.rm = TRUE),
          max(panel$own_new_places, na.rm = TRUE)),
  sprintf("Total Votes & %s & %s & %s & %s \\\\",
          format(round(vars_summary$mean_votes), big.mark = ","),
          format(round(vars_summary$sd_votes), big.mark = ","),
          format(round(min(panel$total_votes)), big.mark = ","),
          format(round(max(panel$total_votes)), big.mark = ",")),
  "\\midrule",
  sprintf("Departments & \\multicolumn{4}{c}{%d} \\\\", vars_summary$n_depts),
  sprintf("Elections & \\multicolumn{4}{c}{%d} \\\\", vars_summary$n_elections),
  sprintf("Observations & \\multicolumn{4}{c}{%d} \\\\", vars_summary$n_obs),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\small\\textit{Notes:} Panel of metropolitan French departments across national elections (2014--2024). RN Vote Share is the first-round vote share of Rassemblement National (formerly Front National) and extreme-right allies. Network Dispersal is the SCI-weighted sum of new asylum reception places created in connected departments under the Sch\\'ema National d'Accueil 2021--2023. Own New Places measures direct asylum capacity expansion within each department.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(sumstats_tex, file.path(TAB_DIR, "tab1_sumstats.tex"))
cat("  Table 1 saved.\n")

## ============================================================================
## TABLE 2: Main Results
## ============================================================================

cat("\n=== Table 2: Main Results ===\n")

load(file.path(DATA_DIR, "main_models.RData"))
results_main <- fread(file.path(DATA_DIR, "results_main.csv"))

## Use fixest's etable for LaTeX output
etable(m1, m2, m3, m4, m5,
       se.below = TRUE,
       dict = c(nd_post = "NetworkDispersal $\\times$ Post",
                own_post = "OwnDispersal $\\times$ Post",
                nd_std_post = "NetworkDispersal(std) $\\times$ Post",
                nd_post_nonhost = "NetDisp $\\times$ Post $\\times$ NonHost",
                nd_post_host = "NetDisp $\\times$ Post $\\times$ Host"),
       title = "Effect of Network Asylum Exposure on RN Vote Share",
       label = "tab:main",
       notes = c("Department-clustered standard errors in parentheses.",
                  "All specifications include department and election fixed effects.",
                  "NetworkDispersal is the SCI-weighted sum of new asylum reception places.",
                  "Col. (3)-(4) standardize to unit SD. Col. (5) decomposes by hosting status."),
       tex = TRUE,
       file = file.path(TAB_DIR, "tab2_main.tex"))

cat("  Table 2 saved.\n")

## ============================================================================
## TABLE 3: Robustness Checks
## ============================================================================

cat("\n=== Table 3: Robustness ===\n")

rob <- fread(file.path(DATA_DIR, "robustness_summary.csv"))

## Fix p-values: replace exact 0 with <0.001 for finite-sample simulations
for (col_name in c("coef", "se")) {
  vals <- rob[[col_name]]
  vals[vals == "0"] <- "$<$0.001"
  rob[[col_name]] <- vals
}

rob_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Coefficient & SE / p-value \\\\",
  "\\midrule"
)

for (i in 1:nrow(rob)) {
  rob_tex <- c(rob_tex,
    sprintf("%s & %s & %s \\\\",
            rob$specification[i], rob$coef[i], rob$se[i]))
}

rob_tex <- c(rob_tex,
  "\\midrule",
  "Observations & \\multicolumn{2}{c}{480} \\\\",
  "Clusters & \\multicolumn{2}{c}{96} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\small\\textit{Notes:} All specifications use the same sample (N = 480, 96 departments $\\times$ 5 elections) and include department and election fixed effects with department-clustered standard errors. The `Baseline' reports the preferred specification. `Log SCI weights' and `Binary treatment' vary the SCI normalization. `Leave-one-out range' shows the coefficient range when each shift department is excluded (dashes indicate no single SE applies). `RI p-value' is from 1,000 permutations of SCI weights ($p < 0.001$ indicates 0 of 1,000 exceeded the observed coefficient; dash indicates not an SE). `Wild cluster bootstrap p-value' uses 999 Rademacher-weight replications. `Non-RN share (mechanical)' is $100 - \\text{RN share}$, mechanically the negative of the baseline; included as a consistency check, not a true placebo.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(rob_tex, file.path(TAB_DIR, "tab3_robustness.tex"))
cat("  Table 3 saved.\n")

## ============================================================================
## TABLE 4: Inference Comparison
## ============================================================================

cat("\n=== Table 4: Inference Comparison ===\n")

inf <- fread(file.path(DATA_DIR, "inference_comparison.csv"))

inf_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Inference Methods for Shift-Share Design}",
  "\\label{tab:inference}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Method & Coefficient & SE & t-statistic \\\\",
  "\\midrule"
)

for (i in 1:nrow(inf)) {
  inf_tex <- c(inf_tex,
    sprintf("%s & %.4f & %.4f & %.2f \\\\",
            inf$method[i], inf$coef[i], inf$se[i], inf$t_stat[i]))
}

inf_tex <- c(inf_tex,
  "\\midrule",
  sprintf("Observations & \\multicolumn{3}{c}{480} \\\\"),
  sprintf("Clusters & \\multicolumn{3}{c}{96} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\small\\textit{Notes:} All rows report the coefficient on NetworkDispersal $\\times$ Post from the baseline specification with department and election fixed effects (N = 480, 96 departments $\\times$ 5 elections). Department-clustered SEs account for within-department serial correlation. HC1 SEs are heteroskedasticity-robust. Following \\citet{adao2019shift}, we recommend department-clustered SEs as the conservative baseline for shift-share designs.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(inf_tex, file.path(TAB_DIR, "tab4_inference.tex"))
cat("  Table 4 saved.\n")

cat("\nAll tables generated.\n")
