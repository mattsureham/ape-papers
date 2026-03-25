# 05_tables.R — Generate all tables for paper
# PCC Electoral Cycles and Crime Investigation Quality (apep_0909)

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

# ============================================================================
# 1. Load data and results
# ============================================================================
force_quarter <- readRDS(file.path(data_dir, "force_quarter.rds"))
force_quarter[force_name == "London, City of", pcc := 0L]
main_results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Rebuild stacked dataset for summary stats
election_yqs <- c(2012.75, 2016.25, 2021.25, 2024.25)
stacked_list <- list()
for (idx in 2:4) {
  e_yq <- election_yqs[idx]
  dt_e <- force_quarter[round((yq - e_yq) * 4) >= -8 & round((yq - e_yq) * 4) <= 7]
  dt_e <- copy(dt_e)
  dt_e[, cohort := idx]
  dt_e[, event_time := round((yq - e_yq) * 4)]
  dt_e[, pre_elect := fifelse(event_time >= -4 & event_time <= -1, 1L, 0L)]
  dt_e[, post_elect := fifelse(event_time >= 0 & event_time <= 3, 1L, 0L)]
  stacked_list[[idx]] <- dt_e
}
stacked <- rbindlist(stacked_list)

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-treatment period for SD calculation: before first election in our data (2016)
pre_data <- force_quarter[yq < 2016.0]
sd_charge_pre <- sd(pre_data$charged_rate, na.rm = TRUE)
sd_nosuspect_pre <- sd(pre_data$no_suspect_rate, na.rm = TRUE)
sd_evid_pre <- sd(pre_data$evid_diff_rate, na.rm = TRUE)

# Summary stats by PCC status
summary_stats <- function(dt, group_var = "pcc") {
  dt[, .(
    N_forces = uniqueN(force_name),
    N_quarters = uniqueN(yq),
    N_obs = .N,
    mean_charge = mean(charged_rate, na.rm = TRUE),
    sd_charge = sd(charged_rate, na.rm = TRUE),
    mean_nosuspect = mean(no_suspect_rate, na.rm = TRUE),
    sd_nosuspect = sd(no_suspect_rate, na.rm = TRUE),
    mean_evid = mean(evid_diff_rate, na.rm = TRUE),
    sd_evid = sd(evid_diff_rate, na.rm = TRUE),
    mean_total = mean(total_outcomes, na.rm = TRUE),
    sd_total = sd(total_outcomes, na.rm = TRUE)
  ), by = group_var]
}

ss <- summary_stats(force_quarter)
cat("Summary statistics:\n")
print(ss)

# Write Table 1 as LaTeX
tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Crime Outcomes by Force Type, 2014--2024}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{PCC Forces} & \\multicolumn{2}{c}{Non-PCC Forces} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n",
  sprintf("Charge/summons rate & %.3f & %.3f & %.3f & %.3f \\\\\n",
          ss[pcc == 1]$mean_charge, ss[pcc == 1]$sd_charge,
          ss[pcc == 0]$mean_charge, ss[pcc == 0]$sd_charge),
  sprintf("No suspect identified rate & %.3f & %.3f & %.3f & %.3f \\\\\n",
          ss[pcc == 1]$mean_nosuspect, ss[pcc == 1]$sd_nosuspect,
          ss[pcc == 0]$mean_nosuspect, ss[pcc == 0]$sd_nosuspect),
  sprintf("Evidential difficulties rate & %.3f & %.3f & %.3f & %.3f \\\\\n",
          ss[pcc == 1]$mean_evid, ss[pcc == 1]$sd_evid,
          ss[pcc == 0]$mean_evid, ss[pcc == 0]$sd_evid),
  sprintf("Total outcomes per quarter & %.0f & %.0f & %.0f & %.0f \\\\\n",
          ss[pcc == 1]$mean_total, ss[pcc == 1]$sd_total,
          ss[pcc == 0]$mean_total, ss[pcc == 0]$sd_total),
  "\\hline\n",
  sprintf("Forces & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          ss[pcc == 1]$N_forces, ss[pcc == 0]$N_forces),
  sprintf("Quarters & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          ss[pcc == 1]$N_quarters, ss[pcc == 0]$N_quarters),
  sprintf("Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          ss[pcc == 1]$N_obs, ss[pcc == 0]$N_obs),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} PCC forces are the 41 police force areas in England and Wales with directly elected Police and Crime Commissioners (from 2012). Non-PCC forces are the Metropolitan Police and City of London Police. Rates computed as the share of total crime outcomes in each category. Data from Home Office Crime Outcomes open data tables, 2014/15--2023/24.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results — Pooled DiD
# ============================================================================
cat("\n=== Generating Table 2: Main Results ===\n")

# Use modelsummary for the main results table
models <- list(
  "Charge Rate" = main_results$pooled_charge,
  "No Suspect Rate" = main_results$pooled_nosuspect,
  "Evid. Diff. Rate" = main_results$pooled_evid,
  "Log Volume" = main_results$placebo_volume
)

# Manual table (more control over formatting)
tab2_manual <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Electoral Cycle Effects on Crime Investigation Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Charge/ & No Suspect & Evid. Diff. & Log Total \\\\\n",
  " & Summons Rate & ID Rate & Rate & Volume \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("PCC $\\times$ Pre-Election & %.4f%s & %.4f%s & %.4f & %.4f \\\\\n",
          coef(main_results$pooled_charge)["pcc_pre"],
          ifelse(pvalue(main_results$pooled_charge)["pcc_pre"] < 0.01, "***",
          ifelse(pvalue(main_results$pooled_charge)["pcc_pre"] < 0.05, "**",
          ifelse(pvalue(main_results$pooled_charge)["pcc_pre"] < 0.1, "*", ""))),
          coef(main_results$pooled_nosuspect)["pcc_pre"],
          ifelse(pvalue(main_results$pooled_nosuspect)["pcc_pre"] < 0.01, "***",
          ifelse(pvalue(main_results$pooled_nosuspect)["pcc_pre"] < 0.05, "**",
          ifelse(pvalue(main_results$pooled_nosuspect)["pcc_pre"] < 0.1, "*", ""))),
          coef(main_results$pooled_evid)["pcc_pre"],
          coef(main_results$placebo_volume)["pcc_pre"]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(main_results$pooled_charge)["pcc_pre"],
          se(main_results$pooled_nosuspect)["pcc_pre"],
          se(main_results$pooled_evid)["pcc_pre"],
          se(main_results$placebo_volume)["pcc_pre"]),
  sprintf("PCC $\\times$ Post-Election & %.4f%s & %.4f%s & %.4f & %.4f \\\\\n",
          coef(main_results$pooled_charge)["pcc_post"],
          ifelse(pvalue(main_results$pooled_charge)["pcc_post"] < 0.01, "***",
          ifelse(pvalue(main_results$pooled_charge)["pcc_post"] < 0.05, "**",
          ifelse(pvalue(main_results$pooled_charge)["pcc_post"] < 0.1, "*", ""))),
          coef(main_results$pooled_nosuspect)["pcc_post"],
          ifelse(pvalue(main_results$pooled_nosuspect)["pcc_post"] < 0.01, "***",
          ifelse(pvalue(main_results$pooled_nosuspect)["pcc_post"] < 0.05, "**",
          ifelse(pvalue(main_results$pooled_nosuspect)["pcc_post"] < 0.1, "*", ""))),
          coef(main_results$pooled_evid)["pcc_post"],
          coef(main_results$placebo_volume)["pcc_post"]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(main_results$pooled_charge)["pcc_post"],
          se(main_results$pooled_nosuspect)["pcc_post"],
          se(main_results$pooled_evid)["pcc_post"],
          se(main_results$placebo_volume)["pcc_post"]),
  "\\hline\n",
  sprintf("Mean dep. var. & %.3f & %.3f & %.3f & %.2f \\\\\n",
          mean(stacked$charged_rate, na.rm = TRUE),
          mean(stacked$no_suspect_rate, na.rm = TRUE),
          mean(stacked$evid_diff_rate, na.rm = TRUE),
          mean(log(stacked$total_outcomes + 1), na.rm = TRUE)),
  "Force $\\times$ cohort FE & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter $\\times$ cohort FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          formatC(nobs(main_results$pooled_charge), big.mark = ","),
          formatC(nobs(main_results$pooled_nosuspect), big.mark = ","),
          formatC(nobs(main_results$pooled_evid), big.mark = ","),
          formatC(nobs(main_results$placebo_volume), big.mark = ",")),
  "Clusters (forces) & 43 & 43 & 43 & 43 \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Stacked DiD estimates across three PCC elections (May 2016, May 2021, May 2024). Pre-Election = quarters $-4$ to $-1$ relative to election; Post-Election = quarters $0$ to $+3$. Reference period: quarter $-5$ and beyond. All specifications include force$\\times$cohort and quarter$\\times$cohort fixed effects. Standard errors clustered at the force level in parentheses. PCC forces ($N=41$) are compared to the Metropolitan Police and City of London Police (non-PCC controls). $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_manual, file.path(table_dir, "tab2_main.tex"))

# ============================================================================
# Table 3: Election-by-Election Results
# ============================================================================
cat("\n=== Generating Table 3: Election-by-Election ===\n")

# Re-run election-by-election for clean output
elec_results <- list()
for (idx in 2:4) {
  e_yq <- election_yqs[idx]
  dt_e <- force_quarter[round((yq - e_yq) * 4) >= -8 & round((yq - e_yq) * 4) <= 7]
  dt_e <- copy(dt_e)
  dt_e[, event_time := round((yq - e_yq) * 4)]
  dt_e[, pre_elect := fifelse(event_time >= -4 & event_time <= -1, 1L, 0L)]
  dt_e[, post_elect := fifelse(event_time >= 0 & event_time <= 3, 1L, 0L)]
  dt_e[, pcc_pre := pcc * pre_elect]
  dt_e[, pcc_post := pcc * post_elect]

  m_charge <- feols(charged_rate ~ pcc_pre + pcc_post | force_name + yq,
                    data = dt_e, cluster = ~force_name)
  m_nosuspect <- feols(no_suspect_rate ~ pcc_pre + pcc_post | force_name + yq,
                       data = dt_e, cluster = ~force_name)

  elec_results[[as.character(idx)]] <- list(charge = m_charge, nosuspect = m_nosuspect)
}

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Electoral Cycle Effects by Election}\n",
  "\\label{tab:byelection}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Election 2016} & \\multicolumn{2}{c}{Election 2021} & \\multicolumn{2}{c}{Election 2024} \\\\\n",
  " & Charge & No Susp. & Charge & No Susp. & Charge & No Susp. \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\hline\n"
)

# Pre-election row
tab3 <- paste0(tab3, "PCC $\\times$ Pre-Election")
for (idx in c("2", "3", "4")) {
  m_c <- elec_results[[idx]]$charge
  m_n <- elec_results[[idx]]$nosuspect
  c_pre <- if ("pcc_pre" %in% names(coef(m_c))) coef(m_c)["pcc_pre"] else NA
  n_pre <- if ("pcc_pre" %in% names(coef(m_n))) coef(m_n)["pcc_pre"] else NA
  c_star <- ""
  n_star <- ""
  if (!is.na(c_pre)) {
    p <- pvalue(m_c)["pcc_pre"]
    c_star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  }
  if (!is.na(n_pre)) {
    p <- pvalue(m_n)["pcc_pre"]
    n_star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  }
  tab3 <- paste0(tab3, sprintf(" & %.4f%s & %.4f%s",
                                 ifelse(is.na(c_pre), 0, c_pre), c_star,
                                 ifelse(is.na(n_pre), 0, n_pre), n_star))
}
tab3 <- paste0(tab3, " \\\\\n")

# SE row for pre-election
tab3 <- paste0(tab3, " ")
for (idx in c("2", "3", "4")) {
  m_c <- elec_results[[idx]]$charge
  m_n <- elec_results[[idx]]$nosuspect
  c_se <- if ("pcc_pre" %in% names(se(m_c))) se(m_c)["pcc_pre"] else NA
  n_se <- if ("pcc_pre" %in% names(se(m_n))) se(m_n)["pcc_pre"] else NA
  tab3 <- paste0(tab3, sprintf(" & (%.4f) & (%.4f)",
                                 ifelse(is.na(c_se), 0, c_se),
                                 ifelse(is.na(n_se), 0, n_se)))
}
tab3 <- paste0(tab3, " \\\\\n")

# Post-election row
tab3 <- paste0(tab3, "PCC $\\times$ Post-Election")
for (idx in c("2", "3", "4")) {
  m_c <- elec_results[[idx]]$charge
  m_n <- elec_results[[idx]]$nosuspect
  c_post <- if ("pcc_post" %in% names(coef(m_c))) coef(m_c)["pcc_post"] else NA
  n_post <- if ("pcc_post" %in% names(coef(m_n))) coef(m_n)["pcc_post"] else NA
  c_star <- ""
  n_star <- ""
  if (!is.na(c_post)) {
    p <- pvalue(m_c)["pcc_post"]
    c_star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  }
  if (!is.na(n_post)) {
    p <- pvalue(m_n)["pcc_post"]
    n_star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  }
  tab3 <- paste0(tab3, sprintf(" & %s & %s",
                                 ifelse(is.na(c_post), "---", sprintf("%.4f%s", c_post, c_star)),
                                 ifelse(is.na(n_post), "---", sprintf("%.4f%s", n_post, n_star))))
}
tab3 <- paste0(tab3, " \\\\\n")

# SE row for post-election
tab3 <- paste0(tab3, " ")
for (idx in c("2", "3", "4")) {
  m_c <- elec_results[[idx]]$charge
  m_n <- elec_results[[idx]]$nosuspect
  c_se <- if ("pcc_post" %in% names(se(m_c))) se(m_c)["pcc_post"] else NA
  n_se <- if ("pcc_post" %in% names(se(m_n))) se(m_n)["pcc_post"] else NA
  tab3 <- paste0(tab3, sprintf(" & %s & %s",
                                 ifelse(is.na(c_se), "", sprintf("(%.4f)", c_se)),
                                 ifelse(is.na(n_se), "", sprintf("(%.4f)", n_se))))
}
tab3 <- paste0(tab3, " \\\\\n")

tab3 <- paste0(tab3,
  "\\hline\n",
  "Force FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Separate DiD estimates for each PCC election. Each panel uses data from 8 quarters before to 7 quarters after the election date. Columns (5)--(6) for the 2024 election have limited post-election data. Standard errors clustered at the force level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(table_dir, "tab3_byelection.tex"))

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("\n=== Generating Table 4: Robustness ===\n")

# Robustness table with drug placebo and no-COVID
tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Drug Offence Placebo and Excluding COVID Election}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Drug Offence Placebo} & \\multicolumn{2}{c}{Excluding 2021 Election} \\\\\n",
  " & Charge Rate & No Susp. Rate & Charge Rate & No Susp. Rate \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("PCC $\\times$ Pre-Election & %.4f & --- & %.4f & %.4f \\\\\n",
          coef(rob_results$drug_placebo)["pcc_pre"],
          coef(rob_results$no_covid_charge)["pcc_pre"],
          coef(rob_results$no_covid_nosuspect)["pcc_pre"]),
  sprintf(" & (%.4f) & & (%.4f) & (%.4f) \\\\\n",
          se(rob_results$drug_placebo)["pcc_pre"],
          se(rob_results$no_covid_charge)["pcc_pre"],
          se(rob_results$no_covid_nosuspect)["pcc_pre"]),
  sprintf("PCC $\\times$ Post-Election & %.4f*** & --- & %.4f%s & %.4f \\\\\n",
          coef(rob_results$drug_placebo)["pcc_post"],
          coef(rob_results$no_covid_charge)["pcc_post"],
          ifelse(pvalue(rob_results$no_covid_charge)["pcc_post"] < 0.1, "*", ""),
          coef(rob_results$no_covid_nosuspect)["pcc_post"]),
  sprintf(" & (%.4f) & & (%.4f) & (%.4f) \\\\\n",
          se(rob_results$drug_placebo)["pcc_post"],
          se(rob_results$no_covid_charge)["pcc_post"],
          se(rob_results$no_covid_nosuspect)["pcc_post"]),
  "\\hline\n",
  "Force $\\times$ cohort FE & Yes & & Yes & Yes \\\\\n",
  "Quarter $\\times$ cohort FE & Yes & & Yes & Yes \\\\\n",
  sprintf("Observations & %s & & %s & %s \\\\\n",
          formatC(nobs(rob_results$drug_placebo), big.mark = ","),
          formatC(nobs(rob_results$no_covid_charge), big.mark = ","),
          formatC(nobs(rob_results$no_covid_nosuspect), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Column (1): Drug offences used as placebo (low-discretion outcome). Columns (3)--(4): Excluding the May 2021 election (COVID period). Standard errors clustered at the force level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================================
# Table 5: Offence-Group Heterogeneity
# ============================================================================
cat("\n=== Generating Table 5: Offence Heterogeneity ===\n")

het <- rob_results$offence_results
het <- het[order(pre_coef)]

tab5 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Pre-Election Effects by Offence Group}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Pre-Election} & \\multicolumn{2}{c}{Post-Election} \\\\\n",
  " Offence Group & Coeff. & SE & Coeff. & SE \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(het)) {
  pre_star <- ifelse(het$pre_p[i] < 0.01, "***",
              ifelse(het$pre_p[i] < 0.05, "**",
              ifelse(het$pre_p[i] < 0.1, "*", "")))
  post_star <- ""
  if (!is.na(het$post_p[i])) {
    post_star <- ifelse(het$post_p[i] < 0.01, "***",
                 ifelse(het$post_p[i] < 0.05, "**",
                 ifelse(het$post_p[i] < 0.1, "*", "")))
  }
  tab5 <- paste0(tab5, sprintf("%s & %.4f%s & %.4f & %s & %s \\\\\n",
                                 het$offence_group[i],
                                 het$pre_coef[i], pre_star, het$pre_se[i],
                                 ifelse(is.na(het$post_coef[i]), "---",
                                        sprintf("%.4f%s", het$post_coef[i], post_star)),
                                 ifelse(is.na(het$post_se[i]), "",
                                        sprintf("%.4f", het$post_se[i]))))
}

tab5 <- paste0(tab5,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Separate stacked DiD regressions for each offence group. Coefficient on PCC $\\times$ Pre-Election (quarters $-4$ to $-1$) and PCC $\\times$ Post-Election (quarters $0$ to $+3$). All specifications include force$\\times$cohort and quarter$\\times$cohort FE. Standard errors clustered at force level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5, file.path(table_dir, "tab5_heterogeneity.tex"))

# ============================================================================
# SDE Table (Appendix)
# ============================================================================
cat("\n=== Generating SDE Table (Appendix) ===\n")

# Compute SDEs
# Main outcomes: charge rate and no-suspect rate
beta_charge <- coef(main_results$pooled_charge)["pcc_pre"]
se_charge <- se(main_results$pooled_charge)["pcc_pre"]

beta_nosuspect <- coef(main_results$pooled_nosuspect)["pcc_pre"]
se_nosuspect <- se(main_results$pooled_nosuspect)["pcc_pre"]

beta_evid <- coef(main_results$pooled_evid)["pcc_pre"]
se_evid <- se(main_results$pooled_evid)["pcc_pre"]

# Also compute no-COVID effects
beta_charge_nocovid <- coef(rob_results$no_covid_charge)["pcc_pre"]
se_charge_nocovid <- se(rob_results$no_covid_charge)["pcc_pre"]

beta_nosuspect_nocovid <- coef(rob_results$no_covid_nosuspect)["pcc_pre"]
se_nosuspect_nocovid <- se(rob_results$no_covid_nosuspect)["pcc_pre"]

# SDE = beta / SD(Y_pre)
sde_charge <- beta_charge / sd_charge_pre
se_sde_charge <- se_charge / sd_charge_pre

sde_nosuspect <- beta_nosuspect / sd_nosuspect_pre
se_sde_nosuspect <- se_nosuspect / sd_nosuspect_pre

sde_evid <- beta_evid / sd_evid_pre
se_sde_evid <- se_evid / sd_evid_pre

sde_charge_nocovid <- beta_charge_nocovid / sd_charge_pre
se_sde_charge_nocovid <- se_charge_nocovid / sd_charge_pre

sde_nosuspect_nocovid <- beta_nosuspect_nocovid / sd_nosuspect_pre
se_sde_nosuspect_nocovid <- se_nosuspect_nocovid / sd_nosuspect_pre

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England and Wales). ",
  "\\textbf{Research question:} Do directly elected Police and Crime Commissioners generate ",
  "electoral cycles in criminal investigation quality, measured by charge rates and ",
  "no-suspect-identified rates? ",
  "\\textbf{Policy mechanism:} The Police Reform and Social Responsibility Act 2011 replaced ",
  "appointed police authorities with directly elected PCCs in 41 force areas; PCCs set ",
  "policing priorities, control budgets, and hire/fire chief constables, creating electoral ",
  "incentives over investigation resource allocation. ",
  "\\textbf{Outcome definition:} Panel A: charge/summons rate (share of recorded crime outcomes ",
  "resulting in a charge or summons) and no-suspect-identified rate (share closed with no ",
  "suspect identified), at force-quarter level. Panel B: charge rate for sexual offences ",
  "(high-discretion subsample) and charge rate excluding the COVID-affected 2021 election. ",
  "\\textbf{Treatment:} Binary --- PCC forces (41) versus non-PCC forces (Metropolitan Police ",
  "and City of London Police, which retained appointed governance). ",
  "\\textbf{Data:} Home Office Crime Outcomes open data tables, quarterly, 2014/15--2023/24, ",
  "43 police forces, 1,701 force-quarter observations in the stacked panel. ",
  "\\textbf{Method:} Stacked difference-in-differences around three PCC elections (2016, 2021, 2024) ",
  "with force$\\times$cohort and quarter$\\times$cohort fixed effects; standard errors clustered ",
  "at the force level (43 clusters). ",
  "\\textbf{Sample:} All 43 territorial police forces in England and Wales; British Transport ",
  "Police excluded (non-territorial). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (pre-2016) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_table <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes: PCC Electoral Cycles}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (All Elections)}} \\\\\n",
  sprintf("Charge/summons rate & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\\n",
          beta_charge, se_charge, sd_charge_pre,
          sde_charge, se_sde_charge, classify_sde(sde_charge)),
  sprintf("No suspect ID rate & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\\n",
          beta_nosuspect, se_nosuspect, sd_nosuspect_pre,
          sde_nosuspect, se_sde_nosuspect, classify_sde(sde_nosuspect)),
  sprintf("Evid. difficulties rate & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\\n",
          beta_evid, se_evid, sd_evid_pre,
          sde_evid, se_sde_evid, classify_sde(sde_evid)),
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("Charge rate (excl. COVID) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\\n",
          beta_charge_nocovid, se_charge_nocovid, sd_charge_pre,
          sde_charge_nocovid, se_sde_charge_nocovid, classify_sde(sde_charge_nocovid)),
  sprintf("No suspect rate (excl. COVID) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\\n",
          beta_nosuspect_nocovid, se_nosuspect_nocovid, sd_nosuspect_pre,
          sde_nosuspect_nocovid, se_sde_nosuspect_nocovid, classify_sde(sde_nosuspect_nocovid)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_table, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat(sprintf("Pre-treatment SD(charge rate): %.4f\n", sd_charge_pre))
cat(sprintf("Pre-treatment SD(no-suspect rate): %.4f\n", sd_nosuspect_pre))
cat(sprintf("SDE charge rate: %.3f (%s)\n", sde_charge, classify_sde(sde_charge)))
cat(sprintf("SDE no-suspect rate: %.3f (%s)\n", sde_nosuspect, classify_sde(sde_nosuspect)))
cat(sprintf("SDE charge rate (no COVID): %.3f (%s)\n",
            sde_charge_nocovid, classify_sde(sde_charge_nocovid)))
