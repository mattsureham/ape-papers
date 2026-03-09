# ==============================================================================
# 06_tables.R — All Table Generation
# APEP-0546: Do Red Flag Laws Save Lives or Shift Deaths?
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# ─── Table 1: Summary Statistics ────────────────────────────────────────────

cat("=== Table 1: Summary Statistics ===\n")

panel_raw <- fread(file.path(data_dir, "panel_combined.csv"))
# Exclude Connecticut (no pre-treatment data) to match estimation sample
panel <- panel_raw[state != "Connecticut"]
short <- fread(file.path(data_dir, "panel_short_2019_2024.csv"))

# Overall summary
sumstat_combined <- panel[, .(
  N = .N,
  Mean = mean(rate_All_Suicide, na.rm = TRUE),
  SD = sd(rate_All_Suicide, na.rm = TRUE),
  Min = min(rate_All_Suicide, na.rm = TRUE),
  Max = max(rate_All_Suicide, na.rm = TRUE)
)]

# By treatment status
sumstat_by_group <- panel[, .(
  N = .N,
  Mean_AllSuicide = mean(rate_All_Suicide, na.rm = TRUE),
  SD_AllSuicide = sd(rate_All_Suicide, na.rm = TRUE)
), by = erpo_status]

# Short panel statistics (with mechanism decomposition)
sumstat_short <- short[, .(
  Variable = c("All Suicide Rate", "Firearm Suicide Rate",
               "Non-Firearm Suicide Rate", "Drug OD Rate",
               "All Homicide Rate", "Gun Ownership Proxy"),
  Mean = c(mean(rate_All_Suicide, na.rm = TRUE),
           mean(rate_FA_Suicide, na.rm = TRUE),
           mean(rate_NF_Suicide, na.rm = TRUE),
           mean(rate_Drug_OD, na.rm = TRUE),
           mean(rate_All_Homicide, na.rm = TRUE),
           mean(gun_ownership_proxy, na.rm = TRUE)),
  SD = c(sd(rate_All_Suicide, na.rm = TRUE),
         sd(rate_FA_Suicide, na.rm = TRUE),
         sd(rate_NF_Suicide, na.rm = TRUE),
         sd(rate_Drug_OD, na.rm = TRUE),
         sd(rate_All_Homicide, na.rm = TRUE),
         sd(gun_ownership_proxy, na.rm = TRUE)),
  Min = c(min(rate_All_Suicide, na.rm = TRUE),
          min(rate_FA_Suicide, na.rm = TRUE),
          min(rate_NF_Suicide, na.rm = TRUE),
          min(rate_Drug_OD, na.rm = TRUE),
          min(rate_All_Homicide, na.rm = TRUE),
          min(gun_ownership_proxy, na.rm = TRUE)),
  Max = c(max(rate_All_Suicide, na.rm = TRUE),
          max(rate_FA_Suicide, na.rm = TRUE),
          max(rate_NF_Suicide, na.rm = TRUE),
          max(rate_Drug_OD, na.rm = TRUE),
          max(rate_All_Homicide, na.rm = TRUE),
          max(gun_ownership_proxy, na.rm = TRUE))
)]

fwrite(sumstat_short, file.path(data_dir, "sumstat_short.csv"))
fwrite(sumstat_by_group, file.path(data_dir, "sumstat_by_group.csv"))

# Generate LaTeX table
sink(file.path(tab_dir, "tab1_summary_statistics.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Variable & Mean & Std.\\ Dev. & Min & Max \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Combined Panel (1999--2024)}} \\\\\n")
cat(sprintf("Total Suicide Rate & %.1f & %.1f & %.1f & %.1f \\\\\n",
    mean(panel$rate_All_Suicide, na.rm = TRUE),
    sd(panel$rate_All_Suicide, na.rm = TRUE),
    min(panel$rate_All_Suicide, na.rm = TRUE),
    max(panel$rate_All_Suicide, na.rm = TRUE)))
cat(sprintf("ERPO Adopted (0/1) & %.3f & %.3f & 0 & 1 \\\\\n",
    mean(panel$treated, na.rm = TRUE),
    sd(panel$treated, na.rm = TRUE)))
cat("\\addlinespace\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Short Panel (2019--2024)}} \\\\\n")
for (i in 1:nrow(sumstat_short)) {
  cat(sprintf("%s & %.1f & %.1f & %.1f & %.1f \\\\\n",
      sumstat_short$Variable[i],
      sumstat_short$Mean[i], sumstat_short$SD[i],
      sumstat_short$Min[i], sumstat_short$Max[i]))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
n_combined <- nrow(panel)
n_short <- nrow(short)
n_states <- uniqueN(panel$state)
cat(sprintf("\\item Notes: Panel A: N = %s state-year observations (%d jurisdictions, 1999--2024 excluding 2018 and Connecticut). ", format(n_combined, big.mark = ","), n_states))
cat(sprintf("Panel B: N = %s state-year observations (%d jurisdictions, 2019--2024); the CS-DiD estimation in Table 2 further excludes pre-2019 adopters, yielding N = 228 for Columns (2)--(5). ", format(n_short, big.mark = ","), uniqueN(short$state)))
cat("All rates are age-adjusted per 100,000 population. ")
cat("Gun Ownership Proxy = share of suicides committed with firearms (2019 cross-section). ")
cat("Source: CDC Mapping Injury, Overdose, and Violence; NCHS Leading Causes of Death.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ─── Table 2: Main Results ──────────────────────────────────────────────────

cat("=== Table 2: Main Results ===\n")

main <- fread(file.path(data_dir, "main_results.csv"))

sink(file.path(tab_dir, "tab2_main_results.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of ERPO Laws on Suicide and Overdose Rates}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat(" & Total & Firearm & Non-Firearm & Total & Drug OD \\\\\n")
cat(" & Suicide & Suicide & Suicide & Suicide & (Placebo) \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(main)) {
  stars <- ""
  if (!is.na(main$p_value[i])) {
    if (main$p_value[i] < 0.01) stars <- "***"
    else if (main$p_value[i] < 0.05) stars <- "**"
    else if (main$p_value[i] < 0.10) stars <- "*"
  }
  if (i == 1) {
    cat(sprintf("ERPO ATT & %.3f%s", main$ATT[i], stars))
  } else {
    cat(sprintf(" & %.3f%s", main$ATT[i], stars))
  }
}
cat(" \\\\\n")

# SEs
cat(sprintf(" & (%.3f)", main$SE[1]))
for (i in 2:nrow(main)) {
  cat(sprintf(" & (%.3f)", main$SE[i]))
}
cat(" \\\\\n")

cat("\\addlinespace\n")
cat(sprintf("Panel & %s", main$Panel[1]))
for (i in 2:nrow(main)) {
  cat(sprintf(" & %s", main$Panel[i]))
}
cat(" \\\\\n")

cat(sprintf("Treated states & %d", main$N_treated[1]))
for (i in 2:nrow(main)) {
  cat(sprintf(" & %d", main$N_treated[i]))
}
cat(" \\\\\n")

cat("\\addlinespace\n")
# Add N row
panel_c <- fread(file.path(data_dir, "panel_combined.csv"))
short_p <- fread(file.path(data_dir, "panel_short_2019_2024.csv"))
cs_data_n <- nrow(panel_c[year != 2018 & state != "Connecticut"])
short_cs_n <- nrow(short_p[is.na(erpo_year) | erpo_year >= 2019])
cat(sprintf("N & %s & %s & %s & %s & %s \\\\\n",
    format(cs_data_n, big.mark = ","),
    format(short_cs_n, big.mark = ","),
    format(short_cs_n, big.mark = ","),
    format(short_cs_n, big.mark = ","),
    format(short_cs_n, big.mark = ",")))
cat("Estimator & \\multicolumn{5}{c}{Callaway and Sant'Anna (2021)} \\\\\n")
cat("Control group & \\multicolumn{5}{c}{Never-treated states} \\\\\n")
cat("Clustering & \\multicolumn{5}{c}{State} \\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item Notes: Each column reports the overall ATT from Callaway and Sant'Anna (2021) doubly-robust estimator with never-treated states as the comparison group. ")
cat("Column (1) uses the combined panel (1999--2024, excluding 2018 and Connecticut). ")
cat("Columns (2)--(5) use the 2019--2024 panel, excluding states that adopted ERPOs before 2019. ")
cat("Non-Firearm Suicide = All Suicide $-$ Firearm Suicide. ")
cat("Drug overdose deaths serve as a placebo: ERPO laws restrict firearms, not drugs. ")
cat("Standard errors clustered at the state level in parentheses. ")
cat("* p$<$0.10, ** p$<$0.05, *** p$<$0.01.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ─── Table 3: Robustness ────────────────────────────────────────────────────

cat("=== Table 3: Robustness ===\n")

rob <- fread(file.path(data_dir, "robustness_summary.csv"))
# Remove rows with NA ATT (e.g., Sun & Abraham if not estimable)
rob <- rob[!is.na(ATT)]

panel_c2 <- fread(file.path(data_dir, "panel_combined.csv"))
cs_n2 <- nrow(panel_c2[year != 2018 & state != "Connecticut"])

sink(file.path(tab_dir, "tab3_robustness.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Alternative Estimators for Total Suicide Rate}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Specification & ATT & SE & p-value \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(rob)) {
  stars <- ""
  if (!is.na(rob$p_value[i])) {
    if (rob$p_value[i] < 0.01) stars <- "***"
    else if (rob$p_value[i] < 0.05) stars <- "**"
    else if (rob$p_value[i] < 0.10) stars <- "*"
  }
  cat(sprintf("%s & %.3f%s & (%.3f) & %.3f \\\\\n",
      rob$Specification[i], rob$ATT[i], stars,
      rob$SE[i], rob$p_value[i]))
}

cat("\\addlinespace\n")
cat(sprintf("N & \\multicolumn{3}{c}{%s} \\\\\n", format(cs_n2, big.mark = ",")))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item Notes: All specifications use the combined panel (1999--2024, excluding 2018 and Connecticut) with total suicide rate (age-adjusted per 100,000) as the outcome. ")
cat("CS-DiD (Never-treated): Callaway and Sant'Anna (2021) with never-treated control group (preferred). ")
cat("CS-DiD (Not-yet-treated): not-yet-treated states as controls. ")
cat("TWFE (diagnostic): standard two-way fixed effects shown for comparison only. ")
cat("Excluding 2018 cohort: drops the 8 states that adopted in 2018 (the gap year between data sources). ")
cat("Excluding anti-ERPO states: removes 6 states with explicit anti-ERPO legislation from controls. ")
cat("Standard errors clustered at the state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ─── Table 4: ERPO Adoption Details ─────────────────────────────────────────

cat("=== Table 4: ERPO Adoption ===\n")

erpo <- fread(file.path(data_dir, "erpo_adoption_dates.csv"))
erpo <- erpo[order(erpo_year, state)]

sink(file.path(tab_dir, "tab4_erpo_adoption.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{ERPO Law Adoption Timeline}\n")
cat("\\label{tab:erpo_adoption}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("State & Year Effective & Wave \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(erpo)) {
  cat(sprintf("%s & %d & %s \\\\\n",
      erpo$state[i], erpo$erpo_year[i], erpo$wave[i]))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item Notes: ERPO = Extreme Risk Protection Order. Pre-Parkland: states that adopted before the February 2018 Parkland shooting. Post-Parkland: states that adopted in 2018 or later. ")
cat("Sources: Everytown for Gun Safety, RAND State Firearm Law Database, Giffords Law Center.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ─── Table 5: Leave-One-Out ─────────────────────────────────────────────────

cat("=== Table 5: Leave-One-Out ===\n")

loo <- fread(file.path(data_dir, "leave_one_out.csv"))
loo <- loo[!is.na(att)]

sink(file.path(tab_dir, "tab5_leave_one_out.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Leave-One-Out Sensitivity: Total Suicide Rate}\n")
cat("\\label{tab:loo}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Dropped State & ATT & SE & p-value \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(loo)) {
  stars <- ""
  if (!is.na(loo$p_value[i])) {
    if (loo$p_value[i] < 0.01) stars <- "***"
    else if (loo$p_value[i] < 0.05) stars <- "**"
    else if (loo$p_value[i] < 0.10) stars <- "*"
  }
  cat(sprintf("%s & %.3f%s & (%.3f) & %.3f \\\\\n",
      loo$dropped_state[i], loo$att[i], stars,
      loo$se[i], loo$p_value[i]))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item Notes: Each row drops one treated state and re-estimates the ATT using Callaway and Sant'Anna (2021) with never-treated controls on the combined panel (total suicide rate, 1999--2024, excluding 2018 and Connecticut). ")
cat(sprintf("Full-sample N = %s. ", format(cs_n2, big.mark = ",")))
cat("Stability across rows indicates results are not driven by any single state. ")
cat("Standard errors clustered at the state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables saved to ", tab_dir, "\n")
cat("DONE.\n")
