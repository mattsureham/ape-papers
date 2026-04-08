# 05_tables.R — Generate all tables for Pipeline Scars paper
source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")
df <- readRDS("../data/incidents_clean.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")

tab_dir <- "../tables"

# -------------------------------------------------------
# Table 1: Summary statistics
# -------------------------------------------------------
cat("Table 1: Summary statistics...\n")

# Full sample stats
stats <- df[, .(
  Variable = c("Total Cost (current \\$)", "Normalized Cost", "Significant (\\%)",
               "Fatalities", "Injuries"),
  N = c(.N, .N, .N, .N, .N),
  Mean = c(mean(TOTAL_COST_CURRENT, na.rm = TRUE), mean(norm_cost, na.rm = TRUE),
           mean(significant) * 100,
           mean(as.numeric(FATAL), na.rm = TRUE), mean(as.numeric(INJURE), na.rm = TRUE)),
  SD = c(sd(TOTAL_COST_CURRENT, na.rm = TRUE), sd(norm_cost, na.rm = TRUE),
         sd(significant) * 100,
         sd(as.numeric(FATAL), na.rm = TRUE), sd(as.numeric(INJURE), na.rm = TRUE))
)]

# Near threshold stats
near <- analysis[abs(norm_cost_centered) < 0.2]
stats_near <- data.table(
  Variable = c("Future Incidents (t+1 to t+3)", "Future Cost (t+1 to t+3)",
               "Pre-Incidents (t-3 to t-1)", "Pre-Rate (annual)"),
  N = rep(nrow(near), 4),
  Mean = c(mean(near$future_incidents), mean(near$future_cost),
           mean(near$pre_incidents), mean(near$pre_rate)),
  SD = c(sd(near$future_incidents), sd(near$future_cost),
         sd(near$pre_incidents), sd(near$pre_rate))
)

all_stats <- rbind(stats, stats_near)

# Write LaTeX
sink(file.path(tab_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Variable & N & Mean & SD \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: All Incidents (2010--2022)}} \\\\\n")
for (i in 1:5) {
  cat(sprintf("%s & %s & %s & %s \\\\\n",
    all_stats$Variable[i],
    format(all_stats$N[i], big.mark = ","),
    format(round(all_stats$Mean[i], 2), nsmall = 2),
    format(round(all_stats$SD[i], 2), nsmall = 2)))
}
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: Near-Threshold Sample ($\\pm$20\\%)}} \\\\\n")
for (i in 6:9) {
  cat(sprintf("%s & %s & %s & %s \\\\\n",
    all_stats$Variable[i],
    format(all_stats$N[i], big.mark = ","),
    format(round(all_stats$Mean[i], 2), nsmall = 2),
    format(round(all_stats$SD[i], 2), nsmall = 2)))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\small\n")
cat("\\textit{Notes:} Data from PHMSA Pipeline Safety Program, 2010--2022. ",
    "Panel A reports statistics for all reported incidents. ",
    "Panel B reports statistics for incidents within 20\\% of the CPI-adjusted ",
    "significant incident threshold. Normalized cost equals reported total cost ",
    "divided by the CPI-adjusted threshold (\\$50,000 in 1984 dollars). ",
    "Future outcomes measured over the three years following the index incident.\n")
cat("}\n")
cat("\\end{table}\n")
sink()

# -------------------------------------------------------
# Table 2: Main RDD results
# -------------------------------------------------------
cat("Table 2: Main RDD results...\n")

# Re-run RDD for multiple outcomes to build table
rd_inc <- rdrobust(y = analysis$future_incidents, x = analysis$norm_cost_centered,
  c = 0, kernel = "triangular", bwselect = "mserd", cluster = analysis$operator_id)

rd_cost <- rdrobust(y = log1p(analysis$future_cost), x = analysis$norm_cost_centered,
  c = 0, kernel = "triangular", bwselect = "mserd", cluster = analysis$operator_id)

analysis[, any_future := as.integer(future_incidents > 0)]
rd_any <- rdrobust(y = analysis$any_future, x = analysis$norm_cost_centered,
  c = 0, kernel = "triangular", bwselect = "mserd", cluster = analysis$operator_id)

rd_norm <- rdrobust(y = analysis$norm_future, x = analysis$norm_cost_centered,
  c = 0, kernel = "triangular", bwselect = "mserd", cluster = analysis$operator_id)

sink(file.path(tab_dir, "tab2_main_rdd.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Significant Incident Label on Future Pipeline Safety}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Future & Log Future & Any Future & Normalized \\\\\n")
cat(" & Incidents & Cost & Incident & Future Rate \\\\\n")
cat("\\hline\n")
cat(sprintf("Significant Label & %.3f & %.3f & %.3f & %.3f \\\\\n",
  rd_inc$coef[1], rd_cost$coef[1], rd_any$coef[1], rd_norm$coef[1]))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
  rd_inc$se[3], rd_cost$se[3], rd_any$se[3], rd_norm$se[3]))
cat(sprintf(" & {[}%.3f, %.3f{]} & {[}%.3f, %.3f{]} & {[}%.3f, %.3f{]} & {[}%.3f, %.3f{]} \\\\\n",
  rd_inc$ci[3, 1], rd_inc$ci[3, 2],
  rd_cost$ci[3, 1], rd_cost$ci[3, 2],
  rd_any$ci[3, 1], rd_any$ci[3, 2],
  rd_norm$ci[3, 1], rd_norm$ci[3, 2]))
cat("\\hline\n")
cat(sprintf("Bandwidth & %.3f & %.3f & %.3f & %.3f \\\\\n",
  rd_inc$bws[1, 1], rd_cost$bws[1, 1], rd_any$bws[1, 1], rd_norm$bws[1, 1]))
cat(sprintf("N (left/right) & %d/%d & %d/%d & %d/%d & %d/%d \\\\\n",
  rd_inc$N_h[1], rd_inc$N_h[2], rd_cost$N_h[1], rd_cost$N_h[2],
  rd_any$N_h[1], rd_any$N_h[2], rd_norm$N_h[1], rd_norm$N_h[2]))
cat(sprintf("Mean dep. var (below) & %.2f & %.2f & %.2f & %.2f \\\\\n",
  mean(analysis[norm_cost_centered < 0]$future_incidents),
  mean(log1p(analysis[norm_cost_centered < 0]$future_cost)),
  mean(analysis[norm_cost_centered < 0]$any_future),
  mean(analysis[norm_cost_centered < 0]$norm_future)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\small\n")
cat("\\textit{Notes:} Local polynomial RDD estimates using \\texttt{rdrobust} ",
    "with triangular kernel and MSE-optimal bandwidth. Robust standard errors in ",
    "parentheses, robust 95\\% confidence intervals in brackets, clustered by operator. ",
    "The running variable is normalized incident cost (total cost divided by the ",
    "CPI-adjusted \\$50,000 threshold in 1984 dollars). Treatment is receiving the ",
    "``significant incident'' label. Outcomes measured over the three years following the index incident.\n")
cat("}\n")
cat("\\end{table}\n")
sink()

# -------------------------------------------------------
# Table 3: Robustness — bandwidth sensitivity
# -------------------------------------------------------
cat("Table 3: Bandwidth sensitivity...\n")

bw_tab <- rob$bandwidth_sensitivity

sink(file.path(tab_dir, "tab3_bandwidth.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Bandwidth Sensitivity}\n")
cat("\\label{tab:bandwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("Bandwidth & Estimate & Robust SE & 95\\% CI & N \\\\\n")
cat("\\hline\n")
for (i in seq_len(nrow(bw_tab))) {
  label <- ifelse(bw_tab$frac[i] == 1, paste0(sprintf("%.3f", bw_tab$bandwidth[i]), " (CCT optimal)"),
                  sprintf("%.3f (%.0f\\%%)", bw_tab$bandwidth[i], bw_tab$frac[i] * 100))
  cat(sprintf("%s & %.3f & %.3f & [%.3f, %.3f] & %d \\\\\n",
    label, bw_tab$coef[i], bw_tab$se[i], bw_tab$ci_low[i], bw_tab$ci_high[i],
    bw_tab$n_left[i] + bw_tab$n_right[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\small\n")
cat("\\textit{Notes:} RDD estimates of the effect of the significant incident label on future ",
    "incident count (t+1 to t+3). All specifications use triangular kernel and cluster standard errors ",
    "by operator. CCT optimal bandwidth selected by MSE-optimal method.\n")
cat("}\n")
cat("\\end{table}\n")
sink()

# -------------------------------------------------------
# Table F1: SDE table (Appendix)
# -------------------------------------------------------
cat("Table F1: SDE table...\n")

# Compute SDE for main outcomes
sd_y_future <- sd(analysis[norm_cost_centered < 0]$future_incidents)
sd_y_cost <- sd(log1p(analysis[norm_cost_centered < 0]$future_cost))
sd_y_any <- sd(analysis[norm_cost_centered < 0]$any_future)

sde_inc <- rd_inc$coef[1] / sd_y_future
sde_inc_se <- rd_inc$se[3] / sd_y_future
sde_cost <- rd_cost$coef[1] / sd_y_cost
sde_cost_se <- rd_cost$se[3] / sd_y_cost
sde_any <- rd_any$coef[1] / sd_y_any
sde_any_se <- rd_any$se[3] / sd_y_any

classify_sde <- function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s < 0.005) "Null"
  else if (s < 0.05) "Small positive"
  else if (s < 0.15) "Moderate positive"
  else "Large positive"
}

sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does receiving PHMSA's ``significant incident'' label --- triggered by a CPI-adjusted cost threshold --- causally reduce subsequent pipeline safety incidents for the labeled operator? ",
  "\\textbf{Policy mechanism:} Pipeline incidents exceeding \\$50,000 in 1984 dollars (approximately \\$105,000--\\$141,000 nominal, 2010--2022) receive PHMSA's ``significant incident'' designation, which publicly flags the operator, triggers mandatory federal enforcement review, and exposes the operator to civil penalty proceedings. ",
  "\\textbf{Outcome definition:} Future incidents is the count of all PHMSA-reported pipeline incidents by the same operator in the three years following the index incident; log future cost is the natural log of one plus total incident costs over the same window; any future incident is a binary indicator for at least one subsequent incident. ",
  "\\textbf{Treatment:} Binary --- whether the index incident's total cost exceeds the CPI-adjusted significant incident threshold. ",
  "\\textbf{Data:} PHMSA Pipeline Safety Program incident reports via jmceager/phmsa\\_clean GitHub repository, 2010--2022, incident-level observations, ", nrow(analysis), " incidents within 20\\% bandwidth. ",
  "\\textbf{Method:} Sharp regression discontinuity design using \\texttt{rdrobust} with triangular kernel and MSE-optimal (CCT) bandwidth selection; standard errors clustered by operator. ",
  "\\textbf{Sample:} All gas and hazardous liquid pipeline incidents with positive reported total cost, 2010--2022; restricted to incidents within the CCT-optimal bandwidth of the CPI-adjusted threshold for RDD estimation. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-threshold (below-cutoff) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tab_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Future Incidents & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
  rd_inc$coef[1], rd_inc$se[3], sd_y_future, sde_inc, sde_inc_se, classify_sde(sde_inc)))
cat(sprintf("Log Future Cost & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
  rd_cost$coef[1], rd_cost$se[3], sd_y_cost, sde_cost, sde_cost_se, classify_sde(sde_cost)))
cat(sprintf("Any Future Incident & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
  rd_any$coef[1], rd_any$se[3], sd_y_any, sde_any, sde_any_se, classify_sde(sde_any)))
cat("\\hline\n")

# Panel B: Heterogeneity by operator size (split at median pre-incidents)
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by operator size)}} \\\\\n")

med_pre <- median(analysis$pre_incidents)
large_ops <- analysis[pre_incidents >= med_pre]
small_ops <- analysis[pre_incidents < med_pre]

if (nrow(large_ops) > 40 && nrow(small_ops) > 40) {
  rd_large <- tryCatch(
    rdrobust(y = large_ops$future_incidents, x = large_ops$norm_cost_centered,
      c = 0, kernel = "triangular", bwselect = "mserd", cluster = large_ops$operator_id),
    error = function(e) NULL)
  rd_small <- tryCatch(
    rdrobust(y = small_ops$future_incidents, x = small_ops$norm_cost_centered,
      c = 0, kernel = "triangular", bwselect = "mserd", cluster = small_ops$operator_id),
    error = function(e) NULL)

  if (!is.null(rd_large)) {
    sd_large <- sd(large_ops[norm_cost_centered < 0]$future_incidents)
    sde_l <- rd_large$coef[1] / sd_large
    sde_l_se <- rd_large$se[3] / sd_large
    cat(sprintf("Large Operators & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
      rd_large$coef[1], rd_large$se[3], sd_large, sde_l, sde_l_se, classify_sde(sde_l)))
  }
  if (!is.null(rd_small)) {
    sd_small <- sd(small_ops[norm_cost_centered < 0]$future_incidents)
    sde_s <- rd_small$coef[1] / sd_small
    sde_s_se <- rd_small$se[3] / sd_small
    cat(sprintf("Small Operators & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
      rd_small$coef[1], rd_small$se[3], sd_small, sde_s, sde_s_se, classify_sde(sde_s)))
  }
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("}\n")
cat("\\end{table}\n")
sink()

cat("All tables saved to", tab_dir, "\n")
