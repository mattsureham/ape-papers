# 05_tables.R — Generate all tables for the paper
# apep_0896: Does the Right to Repair Create Repairers?

source("00_packages.R")

load("../data/main_results.RData")
load("../data/robustness_results.RData")
panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)

# ══════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ══════════════════════════════════════════════════════════

df_8112 <- panel %>% filter(naics_code == "8112")

# Pre-treatment (before 2023Q3)
pre <- df_8112 %>% filter(time_q < 19)
pre_treated <- pre %>% filter(first_treat_q > 0)
pre_control <- pre %>% filter(first_treat_q == 0)

make_summ_row <- function(data, varname, label) {
  x <- data[[varname]]
  x <- x[!is.na(x)]
  tibble(
    Variable = label,
    Mean = mean(x),
    SD = sd(x),
    Min = min(x),
    Max = max(x)
  )
}

summ_all <- bind_rows(
  make_summ_row(pre, "estabs", "Establishments (NAICS 8112)"),
  make_summ_row(pre, "emp", "Employment (avg. monthly)"),
  make_summ_row(pre, "avg_wkly_wage", "Average weekly wage (\\$)")
)

summ_treated <- bind_rows(
  make_summ_row(pre_treated, "estabs", "Establishments"),
  make_summ_row(pre_treated, "emp", "Employment"),
  make_summ_row(pre_treated, "avg_wkly_wage", "Avg. weekly wage (\\$)")
)

summ_control <- bind_rows(
  make_summ_row(pre_control, "estabs", "Establishments"),
  make_summ_row(pre_control, "emp", "Employment"),
  make_summ_row(pre_control, "avg_wkly_wage", "Avg. weekly wage (\\$)")
)

tab1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Electronic Repair Sector (NAICS 8112), Pre-Treatment}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lrrrr}
\\toprule
Variable & Mean & SD & Min & Max \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: All States (Pre-Treatment, 2019Q1--2023Q2)}} \\\\
Establishments & ", sprintf("%.0f", summ_all$Mean[1]), " & ", sprintf("%.0f", summ_all$SD[1]), " & ", sprintf("%.0f", summ_all$Min[1]), " & ", sprintf("%.0f", summ_all$Max[1]), " \\\\
Employment (avg.\\ monthly) & ", sprintf("%.0f", summ_all$Mean[2]), " & ", sprintf("%.0f", summ_all$SD[2]), " & ", sprintf("%.0f", summ_all$Min[2]), " & ", sprintf("%.0f", summ_all$Max[2]), " \\\\
Average weekly wage (\\$) & ", sprintf("%.0f", summ_all$Mean[3]), " & ", sprintf("%.0f", summ_all$SD[3]), " & ", sprintf("%.0f", summ_all$Min[3]), " & ", sprintf("%.0f", summ_all$Max[3]), " \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: RTR States (NY, CA, MN, OR, CO)}} \\\\
Establishments & ", sprintf("%.0f", summ_treated$Mean[1]), " & ", sprintf("%.0f", summ_treated$SD[1]), " & ", sprintf("%.0f", summ_treated$Min[1]), " & ", sprintf("%.0f", summ_treated$Max[1]), " \\\\
Employment (avg.\\ monthly) & ", sprintf("%.0f", summ_treated$Mean[2]), " & ", sprintf("%.0f", summ_treated$SD[2]), " & ", sprintf("%.0f", summ_treated$Min[2]), " & ", sprintf("%.0f", summ_treated$Max[2]), " \\\\
Average weekly wage (\\$) & ", sprintf("%.0f", summ_treated$Mean[3]), " & ", sprintf("%.0f", summ_treated$SD[3]), " & ", sprintf("%.0f", summ_treated$Min[3]), " & ", sprintf("%.0f", summ_treated$Max[3]), " \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel C: Non-RTR States}} \\\\
Establishments & ", sprintf("%.0f", summ_control$Mean[1]), " & ", sprintf("%.0f", summ_control$SD[1]), " & ", sprintf("%.0f", summ_control$Min[1]), " & ", sprintf("%.0f", summ_control$Max[1]), " \\\\
Employment (avg.\\ monthly) & ", sprintf("%.0f", summ_control$Mean[2]), " & ", sprintf("%.0f", summ_control$SD[2]), " & ", sprintf("%.0f", summ_control$Min[2]), " & ", sprintf("%.0f", summ_control$Max[2]), " \\\\
Average weekly wage (\\$) & ", sprintf("%.0f", summ_control$Mean[3]), " & ", sprintf("%.0f", summ_control$SD[3]), " & ", sprintf("%.0f", summ_control$Min[3]), " & ", sprintf("%.0f", summ_control$Max[3]), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Data from BLS Quarterly Census of Employment and Wages (QCEW), 2019Q1--2023Q2, private sector establishments in NAICS 8112 (Electronic and Precision Equipment Repair and Maintenance). Unit of observation is state-quarter. RTR states enacted electronics right-to-repair legislation with effective dates: NY (July 2023), CA and MN (July 2024), OR and CO (January 2025). N = ", nrow(pre), " state-quarter observations (", n_distinct(pre$state_fips), " states $\\times$ ", n_distinct(pre$time_q), " quarters).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab1, "../tables/tab1_summary.tex")

# ══════════════════════════════════════════════════════════
# TABLE 2: Main Results (CS-DiD ATTs)
# ══════════════════════════════════════════════════════════

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

p_estabs <- 2 * pnorm(-abs(agg_estabs$overall.att / agg_estabs$overall.se))
p_emp <- 2 * pnorm(-abs(agg_emp$overall.att / agg_emp$overall.se))
p_wage <- 2 * pnorm(-abs(agg_wage$overall.att / agg_wage$overall.se))

# Sun-Abraham estimates
sa_estabs_res <- summary(feols(log_estabs ~ sunab(cohort, time_q) | state_id + time_q,
  data = df, cluster = ~state_id), agg = "ATT")
sa_emp_res <- summary(feols(log_emp ~ sunab(cohort, time_q) | state_id + time_q,
  data = df, cluster = ~state_id), agg = "ATT")
sa_wage_res <- summary(feols(log_avg_wage ~ sunab(cohort, time_q) | state_id + time_q,
  data = df, cluster = ~state_id), agg = "ATT")

sa_estabs_coef <- sa_estabs_res$coeftable["ATT",]
sa_emp_coef <- sa_emp_res$coeftable["ATT",]
sa_wage_coef <- sa_wage_res$coeftable["ATT",]

tab2 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Effect of Right-to-Repair Laws on the Electronic Repair Sector}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
 & (1) & (2) & (3) \\\\
 & Log Estabs. & Log Emp. & Log Avg.\\ Wage \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Callaway--Sant'Anna ATT}} \\\\[0.3em]
RTR Law & ", sprintf("%.4f%s", agg_estabs$overall.att, stars(p_estabs)), " & ",
  sprintf("%.4f%s", agg_emp$overall.att, stars(p_emp)), " & ",
  sprintf("%.4f%s", agg_wage$overall.att, stars(p_wage)), " \\\\
 & (", sprintf("%.4f", agg_estabs$overall.se), ") & (",
  sprintf("%.4f", agg_emp$overall.se), ") & (",
  sprintf("%.4f", agg_wage$overall.se), ") \\\\
 & [", sprintf("%.4f", p_estabs), "] & [",
  sprintf("%.4f", p_emp), "] & [",
  sprintf("%.4f", p_wage), "] \\\\[0.5em]
\\multicolumn{4}{l}{\\textit{Panel B: Sun--Abraham ATT}} \\\\[0.3em]
RTR Law & ", sprintf("%.4f%s", sa_estabs_coef[1], stars(sa_estabs_coef[4])), " & ",
  sprintf("%.4f%s", sa_emp_coef[1], stars(sa_emp_coef[4])), " & ",
  sprintf("%.4f%s", sa_wage_coef[1], stars(sa_wage_coef[4])), " \\\\
 & (", sprintf("%.4f", sa_estabs_coef[2]), ") & (",
  sprintf("%.4f", sa_emp_coef[2]), ") & (",
  sprintf("%.4f", sa_wage_coef[2]), ") \\\\[0.5em]
\\multicolumn{4}{l}{\\textit{Panel C: TWFE}} \\\\[0.3em]
RTR Law & ", sprintf("%.4f%s", coef(twfe_estabs), stars(pvalue(twfe_estabs))), " & ",
  sprintf("%.4f%s", coef(twfe_emp), stars(pvalue(twfe_emp))), " & ",
  sprintf("%.4f%s", coef(twfe_wage), stars(pvalue(twfe_wage))), " \\\\
 & (", sprintf("%.4f", se(twfe_estabs)), ") & (",
  sprintf("%.4f", se(twfe_emp)), ") & (",
  sprintf("%.4f", se(twfe_wage)), ") \\\\
\\midrule
State FE & Yes & Yes & Yes \\\\
Quarter FE & Yes & Yes & Yes \\\\
States & 53 & 53 & 53 \\\\
Observations & ", format(nrow(df), big.mark = ","), " & ",
  format(nrow(df), big.mark = ","), " & ",
  format(nrow(df), big.mark = ","), " \\\\
Treated states & 5 & 5 & 5 \\\\
Control states & 48 & 48 & 48 \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses; $p$-values in brackets (Panel A). * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Panel A: Callaway and Sant'Anna (2021) estimator with never-treated states as controls and universal base period. Panel B: Sun and Abraham (2021) interaction-weighted estimator. Panel C: Two-way fixed effects. Outcomes are in logs. Treatment is defined by the effective date of state right-to-repair legislation: NY (2023Q3), CA and MN (2024Q3), OR and CO (2025Q1). Data: BLS QCEW, NAICS 8112, private sector, 2019Q1--2025Q2.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab2, "../tables/tab2_main.tex")

# ══════════════════════════════════════════════════════════
# TABLE 3: Placebo Test (NAICS 8111 — Automotive Repair)
# ══════════════════════════════════════════════════════════

p_plac_e <- 2 * pnorm(-abs(agg_placebo_estabs$overall.att / agg_placebo_estabs$overall.se))
p_plac_emp <- 2 * pnorm(-abs(agg_placebo_emp$overall.att / agg_placebo_emp$overall.se))

tab3 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Placebo Test: Effect of RTR Laws on Automotive Repair (NAICS 8111)}
\\label{tab:placebo}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & (1) & (2) \\\\
 & Log Estabs. & Log Emp. \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel A: Electronic Repair (NAICS 8112) --- Treatment Sector}} \\\\[0.3em]
RTR Law & ", sprintf("%.4f%s", agg_estabs$overall.att, stars(p_estabs)), " & ",
  sprintf("%.4f%s", agg_emp$overall.att, stars(p_emp)), " \\\\
 & (", sprintf("%.4f", agg_estabs$overall.se), ") & (",
  sprintf("%.4f", agg_emp$overall.se), ") \\\\[0.5em]
\\multicolumn{3}{l}{\\textit{Panel B: Automotive Repair (NAICS 8111) --- Placebo Sector}} \\\\[0.3em]
RTR Law & ", sprintf("%.4f%s", agg_placebo_estabs$overall.att, stars(p_plac_e)), " & ",
  sprintf("%.4f%s", agg_placebo_emp$overall.att, stars(p_plac_emp)), " \\\\
 & (", sprintf("%.4f", agg_placebo_estabs$overall.se), ") & (",
  sprintf("%.4f", agg_placebo_emp$overall.se), ") \\\\
\\midrule
Estimator & CS-DiD & CS-DiD \\\\
States & 53 & 53 \\\\
Observations & ", format(nrow(df), big.mark = ","), " & ",
  format(nrow(df), big.mark = ","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Callaway and Sant'Anna (2021) ATT estimates with never-treated controls. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. NAICS 8111 (Automotive Repair and Maintenance) serves as a placebo: these establishments repair vehicles, not electronics, and are unaffected by right-to-repair legislation targeting electronic equipment.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab3, "../tables/tab3_placebo.tex")

# ══════════════════════════════════════════════════════════
# TABLE 4: Robustness — Leave-One-Out and Cohort ATTs
# ══════════════════════════════════════════════════════════

# Combine LOO wages with cohort ATTs
tab4 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Robustness: Leave-One-Out and Cohort-Specific Estimates}
\\label{tab:robust}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & Log Estabs. & Log Emp. & Log Wage & $p$-value (Wage) \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Leave-One-Out (Establishments and Wages)}} \\\\[0.3em]
Baseline (all 5 states) & ", sprintf("%.4f", agg_estabs$overall.att), " & ", sprintf("%.4f", agg_emp$overall.att), " & ", sprintf("%.4f", agg_wage$overall.att), " & ", sprintf("%.3f", p_wage), " \\\\",
paste(sapply(1:nrow(loo_df), function(i) {
  sprintf("\nDrop %s & %.4f & --- & %.4f & %.3f \\\\",
    loo_df$dropped[i], loo_df$att[i],
    loo_wage_df$att[i], loo_wage_df$p[i])
}), collapse = ""),
"
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: Cohort-Specific ATTs (Callaway--Sant'Anna)}} \\\\[0.3em]
NY (2023Q3) & ", sprintf("%.4f", agg_estabs_group$att.egt[1]), " & ",
  sprintf("%.4f", agg_emp_group$att.egt[1]), " & ",
  sprintf("%.4f", agg_wage_group$att.egt[1]), " & --- \\\\
 & (", sprintf("%.4f", agg_estabs_group$se.egt[1]), ") & (",
  sprintf("%.4f", agg_emp_group$se.egt[1]), ") & (",
  sprintf("%.4f", agg_wage_group$se.egt[1]), ") & \\\\
CA/MN (2024Q3) & ", sprintf("%.4f", agg_estabs_group$att.egt[2]), " & ",
  sprintf("%.4f", agg_emp_group$att.egt[2]), " & ",
  sprintf("%.4f", agg_wage_group$att.egt[2]), " & --- \\\\
 & (", sprintf("%.4f", agg_estabs_group$se.egt[2]), ") & (",
  sprintf("%.4f", agg_emp_group$se.egt[2]), ") & (",
  sprintf("%.4f", agg_wage_group$se.egt[2]), ") & \\\\
OR/CO (2025Q1) & ", sprintf("%.4f", agg_estabs_group$att.egt[3]), " & ",
  sprintf("%.4f", agg_emp_group$att.egt[3]), " & ",
  sprintf("%.4f", agg_wage_group$att.egt[3]), " & --- \\\\
 & (", sprintf("%.4f", agg_estabs_group$se.egt[3]), ") & (",
  sprintf("%.4f", agg_emp_group$se.egt[3]), ") & (",
  sprintf("%.4f", agg_wage_group$se.egt[3]), ") & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A: each row drops one treated state and re-estimates the Callaway--Sant'Anna ATT. Panel B: group-specific ATTs from Callaway and Sant'Anna (2021). Standard errors in parentheses, clustered at the state level.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab4, "../tables/tab4_robust.tex")

# ══════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Sizes (SDE)
# ══════════════════════════════════════════════════════════

# Pre-treatment standard deviations
sd_log_estabs <- sd(df$log_estabs[df$time_q < 19])
sd_log_emp <- sd(df$log_emp[df$time_q < 19])
sd_log_wage <- sd(df$log_avg_wage[df$time_q < 19])

# SDE calculations
beta_estabs <- agg_estabs$overall.att
se_beta_estabs <- agg_estabs$overall.se
sde_estabs <- beta_estabs / sd_log_estabs
se_sde_estabs <- se_beta_estabs / sd_log_estabs

beta_emp <- agg_emp$overall.att
se_beta_emp <- agg_emp$overall.se
sde_emp <- beta_emp / sd_log_emp
se_sde_emp <- se_beta_emp / sd_log_emp

beta_wage <- agg_wage$overall.att
se_beta_wage <- agg_wage$overall.se
sde_wage <- beta_wage / sd_log_wage
se_sde_wage <- se_beta_wage / sd_log_wage

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

# Heterogeneity: large vs small sector (wages)
beta_large_w <- agg_large_wage$overall.att
se_large_w <- agg_large_wage$overall.se
sde_large_w <- beta_large_w / sd_log_wage
se_sde_large_w <- se_large_w / sd_log_wage

beta_small_w <- agg_small_wage$overall.att
se_small_w <- agg_small_wage$overall.se
sde_small_w <- beta_small_w / sd_log_wage
se_sde_small_w <- se_small_w / sd_log_wage

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level electronics right-to-repair (RTR) laws, which mandate manufacturer provision of diagnostic tools and parts to independent repair shops, affect repair-sector establishment counts, employment, and wages? ",
  "\\textbf{Policy mechanism:} RTR laws require original equipment manufacturers to make diagnostic and repair information, tools, firmware, and parts available to independent repair providers and consumers on fair and reasonable terms, thereby reducing barriers to independent repair market entry. ",
  "\\textbf{Outcome definition:} Log quarterly establishments (NAICS 8112), log average monthly employment (NAICS 8112), and log average weekly wages (NAICS 8112) from BLS Quarterly Census of Employment and Wages. ",
  "\\textbf{Treatment:} Binary; state has an effective electronics RTR law. Five treated states with staggered adoption: NY (2023Q3), CA and MN (2024Q3), OR and CO (2025Q1). ",
  "\\textbf{Data:} BLS QCEW, 2019Q1--2025Q2, state-quarter level, private sector NAICS 8112; N = 1,378 state-quarter observations across 53 states/territories. ",
  "\\textbf{Method:} Staggered difference-in-differences using Callaway and Sant'Anna (2021) with never-treated states as controls; state-clustered standard errors. ",
  "\\textbf{Sample:} All 50 states plus DC and territories with non-suppressed QCEW data for NAICS 8112 (Electronic and Precision Equipment Repair and Maintenance); pre-treatment period 2019Q1--2023Q2. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Log Establishments & CS-DiD ATT & ", sprintf("%.4f", beta_estabs), " & ", sprintf("%.4f", sd_log_estabs), " & ", sprintf("%.4f", sde_estabs), " & ", sprintf("%.4f", se_sde_estabs), " & ", classify(sde_estabs), " \\\\
Log Employment & CS-DiD ATT & ", sprintf("%.4f", beta_emp), " & ", sprintf("%.4f", sd_log_emp), " & ", sprintf("%.4f", sde_emp), " & ", sprintf("%.4f", se_sde_emp), " & ", classify(sde_emp), " \\\\
Log Avg.\\ Weekly Wage & CS-DiD ATT & ", sprintf("%.4f", beta_wage), " & ", sprintf("%.4f", sd_log_wage), " & ", sprintf("%.4f", sde_wage), " & ", sprintf("%.4f", se_sde_wage), " & ", classify(sde_wage), " \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Wages by Pre-Treatment Sector Size)}} \\\\
Wage, Large Sector & CS-DiD ATT & ", sprintf("%.4f", beta_large_w), " & ", sprintf("%.4f", sd_log_wage), " & ", sprintf("%.4f", sde_large_w), " & ", sprintf("%.4f", se_sde_large_w), " & ", classify(sde_large_w), " \\\\
Wage, Small Sector & CS-DiD ATT & ", sprintf("%.4f", beta_small_w), " & ", sprintf("%.4f", sd_log_wage), " & ", sprintf("%.4f", sde_small_w), " & ", sprintf("%.4f", se_sde_small_w), " & ", classify(sde_small_w), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated successfully.\n")
cat(sprintf("SD(log_estabs) = %.4f\n", sd_log_estabs))
cat(sprintf("SD(log_emp) = %.4f\n", sd_log_emp))
cat(sprintf("SD(log_wage) = %.4f\n", sd_log_wage))
cat(sprintf("SDE estabs: %.4f (%s)\n", sde_estabs, classify(sde_estabs)))
cat(sprintf("SDE emp: %.4f (%s)\n", sde_emp, classify(sde_emp)))
cat(sprintf("SDE wage: %.4f (%s)\n", sde_wage, classify(sde_wage)))
