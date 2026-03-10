# ============================================================================
# 06_tables.R — Generate all tables
# APEP Paper apep_0566
# ============================================================================

source("00_packages.R")

data_dir <- "../data/"
tab_dir  <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(paste0(data_dir, "analysis_panel.csv"))
panel_states <- panel[is_state == TRUE]

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

cat("Table 1: Summary statistics...\n")

vars_of_interest <- c("drug_od_rate", "drug_od_deaths", "pop")
if ("median_income" %in% names(panel_states)) {
  vars_of_interest <- c(vars_of_interest, "median_income", "poverty_rate", "pct_white")
}

sumstat_list <- list()
for (grp in c("Full Sample", "Reformed", "Never-Reformed")) {
  sub <- if (grp == "Full Sample") panel_states[year >= 2005]
         else if (grp == "Reformed") panel_states[year >= 2005 & treated_ever == TRUE]
         else panel_states[year >= 2005 & treated_ever == FALSE]

  for (v in vars_of_interest) {
    if (v %in% names(sub)) {
      vals <- sub[[v]]
      vals <- vals[!is.na(vals)]
      sumstat_list[[length(sumstat_list) + 1]] <- data.table(
        variable = v,
        group = grp,
        mean = mean(vals),
        sd = sd(vals),
        min = min(vals),
        max = max(vals),
        n = length(vals)
      )
    }
  }
}

sumstats <- rbindlist(sumstat_list)
fwrite(sumstats, paste0(data_dir, "sumstats_detailed.csv"))

# LaTeX output
sumstats_wide <- dcast(sumstats[group == "Full Sample"],
                       variable ~ ., value.var = c("mean", "sd", "min", "max", "n"))

cat("Summary statistics computed.\n")

# Generate LaTeX table
sink(paste0(tab_dir, "tab1_sumstats.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:sumstats}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat("Variable & Mean & SD & Min & Max & N \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{6}{l}{\\textit{Panel A: Full Sample (2005--2021)}} \\\\\n")

labels <- c(drug_od_rate = "Drug overdose rate (per 100K)",
            drug_od_deaths = "Drug overdose deaths",
            pop = "Population",
            median_income = "Median household income",
            poverty_rate = "Poverty rate",
            pct_white = "Percent white")

for (v in vars_of_interest) {
  row <- sumstats[group == "Full Sample" & variable == v]
  if (nrow(row) > 0) {
    lab <- if (v %in% names(labels)) labels[v] else v
    cat(sprintf("%s & %.2f & %.2f & %.2f & %.2f & %s \\\\\n",
                lab, row$mean, row$sd, row$min, row$max, format(row$n, big.mark = ",")))
  }
}

cat("\\midrule\n")
cat("\\multicolumn{6}{l}{\\textit{Panel B: Reformed States}} \\\\\n")
for (v in c("drug_od_rate", "drug_od_deaths")) {
  row <- sumstats[group == "Reformed" & variable == v]
  if (nrow(row) > 0) {
    lab <- if (v %in% names(labels)) labels[v] else v
    cat(sprintf("%s & %.2f & %.2f & %.2f & %.2f & %s \\\\\n",
                lab, row$mean, row$sd, row$min, row$max, format(row$n, big.mark = ",")))
  }
}

cat("\\midrule\n")
cat("\\multicolumn{6}{l}{\\textit{Panel C: Never-Reformed States}} \\\\\n")
for (v in c("drug_od_rate", "drug_od_deaths")) {
  row <- sumstats[group == "Never-Reformed" & variable == v]
  if (nrow(row) > 0) {
    lab <- if (v %in% names(labels)) labels[v] else v
    cat(sprintf("%s & %.2f & %.2f & %.2f & %.2f & %s \\\\\n",
                lab, row$mean, row$sd, row$min, row$max, format(row$n, big.mark = ",")))
  }
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Drug overdose death rates are age-adjusted per 100,000 population from CDC NCHS. Reformed states are those that enacted substantial civil asset forfeiture reform (conviction requirement, raised burden of proof, or abolition) between 2014 and 2021. Population and income data from Census ACS.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table 2: Main Results
# ============================================================================

cat("Table 2: Main results...\n")

main_results <- fread(paste0(data_dir, "main_results.csv"))

sink(paste0(tab_dir, "tab2_main.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of Civil Asset Forfeiture Reform on Drug Overdose Mortality}\n")
cat("\\label{tab:main}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat(" & CS-DiD & CS-DiD (Log) & TWFE \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(main_results)) {
  est <- main_results[i]
  stars <- if (est$p_value < 0.01) "***"
           else if (est$p_value < 0.05) "**"
           else if (est$p_value < 0.10) "*"
           else ""
  if (i == 1) {
    cat(sprintf("Reform & %.3f%s", est$estimate, stars))
  } else {
    cat(sprintf(" & %.3f%s", est$estimate, stars))
  }
}
cat(" \\\\\n")

for (i in 1:nrow(main_results)) {
  est <- main_results[i]
  if (i == 1) {
    cat(sprintf(" & (%.3f)", est$se))
  } else {
    cat(sprintf(" & (%.3f)", est$se))
  }
}
cat(" \\\\\n")

for (i in 1:nrow(main_results)) {
  est <- main_results[i]
  if (i == 1) {
    cat(sprintf(" & [%.3f, %.3f]", est$ci_lower, est$ci_upper))
  } else {
    cat(sprintf(" & [%.3f, %.3f]", est$ci_lower, est$ci_upper))
  }
}
cat(" \\\\\n")

cat("\\midrule\n")
cat(sprintf("Observations & %s & %s & %s \\\\\n",
            format(main_results$n_obs[1], big.mark = ","),
            format(main_results$n_obs[2], big.mark = ","),
            format(main_results$n_obs[3], big.mark = ",")))
cat(sprintf("States & %d & %d & %d \\\\\n",
            main_results$n_states[1], main_results$n_states[2], main_results$n_states[3]))
cat(sprintf("Treated states & %d & %d & %d \\\\\n",
            main_results$n_treated[1], main_results$n_treated[2], main_results$n_treated[3]))
cat("Estimator & CS & CS & TWFE \\\\\n")
cat("Control group & Not-yet-treated & Not-yet-treated & All \\\\\n")
cat("Clustering & State & State & State \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. 95\\% confidence intervals in brackets. Columns (1) and (2) report Callaway-Sant'Anna (2021) estimates using the doubly-robust estimator with not-yet-treated states as controls. Column (3) reports standard two-way fixed effects for comparison. The dependent variable is the age-adjusted drug overdose death rate per 100,000 population. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table 3: Dose-Response
# ============================================================================

cat("Table 3: Dose-response...\n")

if (file.exists(paste0(data_dir, "dose_response.csv"))) {
  dose_df <- fread(paste0(data_dir, "dose_response.csv"))

  sink(paste0(tab_dir, "tab3_dose.tex"))
  cat("\\begin{table}[H]\n")
  cat("\\centering\n")
  cat("\\caption{Dose-Response: Reform Intensity and Drug Overdose Mortality}\n")
  cat("\\label{tab:dose}\n")
  cat("\\begin{tabular}{lcc}\n")
  cat("\\toprule\n")
  cat("Reform Type & Estimate & SE \\\\\n")
  cat("\\midrule\n")
  for (i in 1:nrow(dose_df)) {
    cat(sprintf("%s & %.3f & (%.3f) \\\\\n",
                dose_df$intensity[i], dose_df$estimate[i], dose_df$se[i]))
  }
  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\begin{tablenotes}[flushleft]\n")
  cat("\\small\n")
  cat("\\item \\textit{Notes:} TWFE estimates with state and year fixed effects, standard errors clustered at the state level. Reform types ordered by restrictiveness: burden raised (least restrictive), conviction required, abolished (most restrictive). If the financial incentive channel operates, more restrictive reforms should produce larger effects.\n")
  cat("\\end{tablenotes}\n")
  cat("\\end{table}\n")
  sink()
}

# ============================================================================
# Table 4: Robustness Summary
# ============================================================================

cat("Table 4: Robustness summary...\n")

rob_rows <- list()

# Main result
main <- fread(paste0(data_dir, "main_results.csv"))
rob_rows[[1]] <- data.table(spec = "Main: CS-DiD (levels)",
                             est = main[1]$estimate, se = main[1]$se)

# Log
rob_rows[[2]] <- data.table(spec = "Log drug OD rate",
                             est = main[2]$estimate, se = main[2]$se)

# TWFE
rob_rows[[3]] <- data.table(spec = "TWFE",
                             est = main[3]$estimate, se = main[3]$se)

# Never-treated controls
if (file.exists(paste0(data_dir, "cs_event_study_nevertreated.csv"))) {
  # Use the simple ATT (not event study)
  rob_rows[[4]] <- data.table(spec = "Never-treated controls only",
                               est = NA_real_, se = NA_real_)
}

# Strict treatment
if (file.exists(paste0(data_dir, "alt_treatment_strict.csv"))) {
  strict <- fread(paste0(data_dir, "alt_treatment_strict.csv"))
  rob_rows[[5]] <- data.table(spec = "Strict (abolish + conviction only)",
                               est = strict$estimate, se = strict$se)
}

# WCB
if (file.exists(paste0(data_dir, "wcb_results.csv"))) {
  wcb <- fread(paste0(data_dir, "wcb_results.csv"))
  rob_rows[[6]] <- data.table(spec = "Wild cluster bootstrap p-value",
                               est = wcb$estimate, se = wcb$wcb_p_value)
}

# RI
if (file.exists(paste0(data_dir, "ri_results.csv"))) {
  ri <- fread(paste0(data_dir, "ri_results.csv"))
  rob_rows[[7]] <- data.table(spec = "Randomization inference p-value",
                               est = ri$actual_att, se = ri$ri_p_value)
}

rob_df <- rbindlist(rob_rows, fill = TRUE)
fwrite(rob_df, paste0(data_dir, "robustness_summary.csv"))

sink(paste0(tab_dir, "tab4_robustness.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Robustness of Main Results}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("Specification & Estimate & SE / p-value \\\\\n")
cat("\\midrule\n")
for (i in 1:nrow(rob_df)) {
  if (!is.na(rob_df$est[i])) {
    cat(sprintf("%s & %.3f & %.3f \\\\\n",
                rob_df$spec[i], rob_df$est[i], rob_df$se[i]))
  }
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} All specifications use state and year fixed effects with standard errors clustered at the state level unless otherwise noted. For the wild cluster bootstrap and randomization inference rows, the second column reports the p-value rather than the standard error.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables generated.\n")
