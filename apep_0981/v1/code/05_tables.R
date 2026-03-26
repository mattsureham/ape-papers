## 05_tables.R — Generate LaTeX tables including SDE appendix
## apep_0981: Good Samaritan Laws and Opioid Treatment Entry

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robust_results.rds"))

# ============================================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

sumstat_vars <- c("bup_rx", "opioid_rx", "bup_rate", "opioid_rate")
sumstat_labels <- c("Buprenorphine prescriptions",
                     "Opioid painkiller prescriptions",
                     "Buprenorphine per 100K pop.",
                     "Opioid painkillers per 100K pop.")

tab1_rows <- lapply(seq_along(sumstat_vars), function(i) {
  v <- panel[[sumstat_vars[i]]]
  v <- v[!is.na(v)]
  data.frame(
    Variable = sumstat_labels[i],
    Mean = sprintf("%.0f", mean(v)),
    SD = sprintf("%.0f", sd(v)),
    Min = sprintf("%.0f", min(v)),
    Max = sprintf("%.0f", max(v)),
    stringsAsFactors = FALSE
  )
})
tab1_df <- do.call(rbind, tab1_rows)

# Add N, states, years
n_obs <- nrow(panel)
n_states <- uniqueN(panel$state)
n_years <- uniqueN(panel$year)

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & SD & Min & Max \\\\\n",
  "\\midrule\n",
  paste(apply(tab1_df, 1, function(r) {
    paste(r, collapse = " & ")
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sprintf("\\item \\textit{Notes:} N = %s state-year observations across %d states and %d years (2006--2022). ",
          format(n_obs, big.mark=","), n_states, n_years),
  "Buprenorphine prescriptions include Suboxone, Subutex, Zubsolv, and generic buprenorphine/naloxone products ",
  "reimbursed by Medicaid. Opioid painkiller prescriptions include oxycodone and hydrocodone products. ",
  "Per-capita rates computed using Census Bureau state population estimates.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("  Written tab1_summary.tex\n")

# ============================================================================
# TABLE 2: MAIN RESULTS — CS DiD + TWFE
# ============================================================================
cat("=== Table 2: Main Results ===\n")

# Extract CS ATT results
cs_att <- results$cs_att
cs_att_opi <- results$cs_att_opi
cs_att_rate <- results$cs_att_rate
twfe_bup <- results$twfe_bup
twfe_opi <- results$twfe_opi

# Stars function
stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("^{***}")
  if (pval < 0.05) return("^{**}")
  if (pval < 0.10) return("^{*}")
  return("")
}

# CS p-values
cs_bup_p <- 2 * (1 - pnorm(abs(cs_att$overall.att / cs_att$overall.se)))
cs_opi_p <- 2 * (1 - pnorm(abs(cs_att_opi$overall.att / cs_att_opi$overall.se)))
cs_rate_p <- 2 * (1 - pnorm(abs(cs_att_rate$overall.att / cs_att_rate$overall.se)))

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Good Samaritan Laws on Medicaid Prescriptions}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Log(Bup Rx) & Log(Opioid Rx) & Log(Bup Rate) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Callaway--Sant'Anna}} \\\\\n",
  sprintf("GSL & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ \\\\\n",
          cs_att$overall.att, stars(cs_bup_p),
          cs_att_opi$overall.att, stars(cs_opi_p),
          cs_att_rate$overall.att, stars(cs_rate_p)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          cs_att$overall.se, cs_att_opi$overall.se, cs_att_rate$overall.se),
  sprintf(" & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\\n",
          cs_att$overall.att - 1.96*cs_att$overall.se,
          cs_att$overall.att + 1.96*cs_att$overall.se,
          cs_att_opi$overall.att - 1.96*cs_att_opi$overall.se,
          cs_att_opi$overall.att + 1.96*cs_att_opi$overall.se,
          cs_att_rate$overall.att - 1.96*cs_att_rate$overall.se,
          cs_att_rate$overall.att + 1.96*cs_att_rate$overall.se),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: TWFE}} \\\\\n",
  sprintf("GSL & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ \\\\\n",
          coef(twfe_bup)["treated"], stars(pvalue(twfe_bup)["treated"]),
          coef(twfe_opi)["treated"], stars(pvalue(twfe_opi)["treated"]),
          coef(results$twfe_rate)["treated"], stars(pvalue(results$twfe_rate)["treated"])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          se(twfe_bup)["treated"], se(twfe_opi)["treated"],
          se(results$twfe_rate)["treated"]),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(n_obs, big.mark=","), format(n_obs, big.mark=","), format(n_obs, big.mark=",")),
  sprintf("States & %d & %d & %d \\\\\n", n_states, n_states, n_states),
  "State \\& Year FE & Yes & Yes & Yes \\\\\n",
  "Clustering & State & State & State \\\\\n",
  sprintf("Estimator & CS (NYT) & CS (NYT) & CS (NYT) \\\\\n"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses; ",
  "95\\% confidence intervals in brackets. ",
  "Panel A reports the Callaway--Sant'Anna (2021) aggregated ATT using not-yet-treated states as the comparison group. ",
  "Panel B reports two-way fixed effects estimates for comparison. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("  Written tab2_main.tex\n")

# ============================================================================
# TABLE 3: TRIPLE-DIFFERENCE + CONTROLS
# ============================================================================
cat("=== Table 3: DDD and Controls ===\n")

ddd <- robust$ddd
twfe_med <- robust$twfe_med

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Triple-Difference and Policy Controls}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & DDD & +Medicaid & +Medicaid+NAL \\\\\n",
  " & Log(Rx) & Log(Bup Rx) & Log(Bup Rx) \\\\\n",
  "\\midrule\n",
  sprintf("GSL & $%.3f%s$ & $%.3f$ & $%.3f$ \\\\\n",
          coef(ddd)["treated"], stars(pvalue(ddd)["treated"]),
          coef(twfe_med)["treated"], coef(robust$twfe_both)["treated"]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          se(ddd)["treated"], se(twfe_med)["treated"], se(robust$twfe_both)["treated"]),
  sprintf("GSL $\\times$ Buprenorphine & $%.3f%s$ & & \\\\\n",
          coef(ddd)["treated:is_bup"], stars(pvalue(ddd)["treated:is_bup"])),
  sprintf(" & (%.3f) & & \\\\\n", se(ddd)["treated:is_bup"]),
  sprintf("Medicaid Expansion & & $%.3f%s$ & $%.3f%s$ \\\\\n",
          coef(twfe_med)["medicaid_expanded"], stars(pvalue(twfe_med)["medicaid_expanded"]),
          coef(robust$twfe_both)["medicaid_expanded"], stars(pvalue(robust$twfe_both)["medicaid_expanded"])),
  sprintf(" & & (%.3f) & (%.3f) \\\\\n",
          se(twfe_med)["medicaid_expanded"], se(robust$twfe_both)["medicaid_expanded"]),
  sprintf("Naloxone Access Law & & & $%.3f$ \\\\\n",
          coef(robust$twfe_both)["naloxone_law"]),
  sprintf(" & & & (%.3f) \\\\\n", se(robust$twfe_both)["naloxone_law"]),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(nrow(panel)*2, big.mark=","), format(n_obs, big.mark=","), format(n_obs, big.mark=",")),
  "State \\& Year FE & Yes & Yes & Yes \\\\\n",
  "Drug Type FE & Yes & No & No \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) stacks buprenorphine and opioid painkiller prescriptions and estimates a triple-difference: ",
  "GSL $\\times$ Buprenorphine isolates the differential effect on MAT relative to pain opioids. ",
  "Columns (2)--(3) add concurrent policy controls. Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:ddd}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(table_dir, "tab3_ddd.tex"))
cat("  Written tab3_ddd.tex\n")

# ============================================================================
# TABLE 4: ROBUSTNESS
# ============================================================================
cat("=== Table 4: Robustness ===\n")

cs_precovid <- robust$cs_att_precovid
cs_post2012 <- robust$cs_att_post2012

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Baseline CS & Pre-COVID & Post-2012 & Asinh \\\\\n",
  "\\midrule\n",
  sprintf("GSL & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ \\\\\n",
          results$cs_att$overall.att,
          cs_precovid$overall.att,
          cs_post2012$overall.att,
          coef(robust$twfe_asinh)["treated"]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          results$cs_att$overall.se,
          cs_precovid$overall.se,
          cs_post2012$overall.se,
          se(robust$twfe_asinh)["treated"]),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(n_obs, big.mark=","),
          format(nrow(panel[year <= 2019]), big.mark=","),
          format(nrow(panel[first_treat == 0 | first_treat >= 2012]), big.mark=","),
          format(n_obs, big.mark=",")),
  "Estimator & CS & CS & CS & TWFE \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) reproduces the baseline CS estimate. Column (2) restricts the sample to 2006--2019 (pre-COVID). ",
  "Column (3) drops early adopters (2007--2011 cohorts). Column (4) uses inverse hyperbolic sine transformation with TWFE. ",
  "All specifications include state and year fixed effects with state-clustered standard errors. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))
cat("  Written tab4_robustness.tex\n")

# ============================================================================
# TABLE F1: STANDARDIZED EFFECT SIZES (SDE)
# ============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Extract coefficients
beta_bup <- results$cs_att$overall.att
se_bup <- results$cs_att$overall.se
sd_y_bup <- sd(panel$log_bup_rx)

beta_opi <- results$cs_att_opi$overall.att
se_opi <- results$cs_att_opi$overall.se
sd_y_opi <- sd(panel$log_opioid_rx)

# DDD coefficient
beta_ddd <- coef(robust$ddd)["treated:is_bup"]
se_ddd <- se(robust$ddd)["treated:is_bup"]
sd_y_ddd <- sd(c(panel$log_bup_rx, panel$log_opioid_rx))

# SDE = beta / SD(Y) for binary treatment
sde_bup <- beta_bup / sd_y_bup
se_sde_bup <- se_bup / sd_y_bup

sde_opi <- beta_opi / sd_y_opi
se_sde_opi <- se_opi / sd_y_opi

sde_ddd <- beta_ddd / sd_y_ddd
se_sde_ddd <- se_ddd / sd_y_ddd

# Heterogeneity: expansion vs non-expansion
cs_exp <- robust$cs_att_exp
beta_exp <- cs_exp$overall.att
se_exp <- cs_exp$overall.se
sde_exp <- beta_exp / sd_y_bup
se_sde_exp <- se_exp / sd_y_bup

# Classification function
classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether state Good Samaritan overdose immunity laws increase ",
  "medication-assisted treatment entry among Medicaid enrollees with opioid use disorder. ",
  "\\textbf{Policy mechanism:} Good Samaritan Laws provide legal immunity from drug possession charges ",
  "to individuals who call 911 during an overdose, reducing the fear of arrest that deters help-seeking ",
  "and potentially channeling overdose survivors into the treatment system through emergency department referrals. ",
  "\\textbf{Outcome definition:} Log of annual state-level Medicaid buprenorphine prescriptions (Suboxone, Subutex, ",
  "Zubsolv, and generic buprenorphine/naloxone products), the gold-standard medication for opioid use disorder treatment. ",
  "\\textbf{Treatment:} Binary indicator for whether a state has enacted a Good Samaritan overdose immunity law. ",
  "\\textbf{Data:} CMS Medicaid State Drug Utilization Data, 2006--2022, state-year level, 51 states including DC. ",
  "\\textbf{Method:} Staggered difference-in-differences with Callaway--Sant'Anna (2021) estimator using not-yet-treated ",
  "states as the comparison group and doubly robust estimation; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 50 US states plus DC with non-zero Medicaid buprenorphine utilization; 50 states adopted GSLs ",
  "between 2007 and 2021, one state (Kansas) serves as never-treated comparison. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation ",
  "of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Log(Bup Rx) & CS ATT & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_bup, sd_y_bup, sde_bup, se_sde_bup, classify(sde_bup)),
  sprintf("Log(Opioid Rx) & CS ATT & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_opi, sd_y_opi, sde_opi, se_sde_opi, classify(sde_opi)),
  sprintf("DDD: Bup vs Opioid & TWFE & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_ddd, sd_y_ddd, sde_ddd, se_sde_ddd, classify(sde_ddd)),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("Log(Bup Rx), Expansion & CS ATT & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_exp, sd_y_bup, sde_exp, se_sde_exp, classify(sde_exp)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat("\n=== ALL TABLES GENERATED ===\n")
