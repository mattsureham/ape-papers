## 05_tables.R — Generate all LaTeX tables for apep_1230
## Tables:
##   1. Summary statistics (pre/post, treated/control)
##   2. Main DiD results
##   3. Event study coefficients
##   4. Robustness checks
##   F1. SDE appendix table

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "state_quarter_panel.rds"))
models <- readRDS(file.path(data_dir, "main_models.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))
ri <- readRDS(file.path(data_dir, "ri_results.rds"))
es_coefs <- readRDS(file.path(data_dir, "event_study_coefs.rds"))
quality <- readRDS(file.path(data_dir, "quality_cross_section.rds"))

valid_states <- c(state.abb, "DC")
panel <- panel[state %in% valid_states]
quality <- quality[state %in% valid_states]

ppeo_states <- c("AZ", "CA", "NV", "TX")
ppeo_start_yq <- 2023.5

pre <- panel[year_qtr < ppeo_start_yq]
post_d <- panel[year_qtr >= ppeo_start_yq]

# Helper: format numbers
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, big.mark = ",")
fmt0 <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
fmt_p <- function(p) {
  if (p < 0.001) return("$<$0.001")
  return(fmt(p, 3))
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("Generating Table 1: Summary Statistics...\n")

# Compute stats for panel
pre_treat <- pre[treated_state == 1]
pre_ctrl <- pre[treated_state == 0]
post_treat <- post_d[treated_state == 1]
post_ctrl <- post_d[treated_state == 0]

# Quality stats
q_treat <- quality[treated_state == 1]
q_ctrl <- quality[treated_state == 0]

tab1 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Hospice Enrollment and Quality}
\\label{tab:sumstats}
\\small
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{PPEO States} & \\multicolumn{2}{c}{Non-PPEO States} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & Mean & SD & Mean & SD \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: State $\\times$ Quarter Enrollment (2017 Q1--2023 Q2)}} \\\\[3pt]
New enrollments/quarter & ", fmt(mean(pre_treat$new_enrollments), 1), " & ", fmt(sd(pre_treat$new_enrollments), 1), " & ", fmt(mean(pre_ctrl$new_enrollments), 1), " & ", fmt(sd(pre_ctrl$new_enrollments), 1), " \\\\
\\quad For-profit & ", fmt(mean(pre_treat$new_fp), 1), " & ", fmt(sd(pre_treat$new_fp), 1), " & ", fmt(mean(pre_ctrl$new_fp), 1), " & ", fmt(sd(pre_ctrl$new_fp), 1), " \\\\
\\quad Nonprofit & ", fmt(mean(pre_treat$new_np), 1), " & ", fmt(sd(pre_treat$new_np), 1), " & ", fmt(mean(pre_ctrl$new_np), 1), " & ", fmt(sd(pre_ctrl$new_np), 1), " \\\\
For-profit share & ", fmt(mean(pre_treat$new_fp, na.rm = TRUE) / mean(pre_treat$new_enrollments), 2), " & & ", fmt(mean(pre_ctrl$new_fp, na.rm = TRUE) / max(mean(pre_ctrl$new_enrollments), 0.01), 2), " & \\\\
States & \\multicolumn{2}{c}{4} & \\multicolumn{2}{c}{47} \\\\
State $\\times$ quarter obs. & \\multicolumn{2}{c}{", fmt0(nrow(pre_treat)), "} & \\multicolumn{2}{c}{", fmt0(nrow(pre_ctrl)), "} \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Provider Quality (Cross-Section, Apr 2024--Mar 2025)}} \\\\[3pt]
Hospice Care Index & ", fmt(mean(q_treat$hci_score, na.rm = TRUE), 1), " & ", fmt(sd(q_treat$hci_score, na.rm = TRUE), 1), " & ", fmt(mean(q_ctrl$hci_score, na.rm = TRUE), 1), " & ", fmt(sd(q_ctrl$hci_score, na.rm = TRUE), 1), " \\\\
Visits near death (\\%) & ", fmt(mean(q_treat$visits_near_death, na.rm = TRUE), 1), " & ", fmt(sd(q_treat$visits_near_death, na.rm = TRUE), 1), " & ", fmt(mean(q_ctrl$visits_near_death, na.rm = TRUE), 1), " & ", fmt(sd(q_ctrl$visits_near_death, na.rm = TRUE), 1), " \\\\
Providers & \\multicolumn{2}{c}{", fmt0(nrow(q_treat)), "} & \\multicolumn{2}{c}{", fmt0(nrow(q_ctrl)), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Panel A reports means and standard deviations for state-quarter new hospice enrollments in the pre-PPEO period (Q1 2017 through Q2 2023). PPEO states are Arizona, California, Nevada, and Texas, where CMS activated the Provisional Period of Enhanced Oversight for new hospice enrollments in July 2023. Panel B reports provider-level Hospice Care Index scores and visits near death for the April 2024--March 2025 measurement period from CMS Hospice Quality Reporting.
\\end{tablenotes}
\\end{table}"
)
writeLines(tab1, file.path(tables_dir, "tab1_sumstats.tex"))

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================

cat("Generating Table 2: Main DiD Results...\n")

# Extract coefficients
get_coef <- function(m, var = "did") {
  list(
    est = coef(m)[var],
    se = se(m)[var],
    p = pvalue(m)[var]
  )
}

c1 <- get_coef(models$m1)
c3 <- get_coef(models$m3)
c4 <- get_coef(models$m4)
c_noca <- get_coef(robust$m_noca, "did_noca")

stars <- function(p) {
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  return("")
}

tab2 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Effect of PPEO on New Hospice Enrollments}
\\label{tab:main_did}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & All & For-Profit & Nonprofit & Excl.\\ CA \\\\
\\midrule
PPEO $\\times$ Post & ", fmt(c1$est, 2), stars(c1$p), " & ", fmt(c3$est, 2), stars(c3$p), " & ", fmt(c4$est, 3), stars(c4$p), " & ", fmt(c_noca$est, 2), stars(c_noca$p), " \\\\
 & (", fmt(c1$se, 2), ") & (", fmt(c3$se, 2), ") & (", fmt(c4$se, 3), ") & (", fmt(c_noca$se, 2), ") \\\\
 & & & & \\\\
RI $p$-value & ", fmt(ri$ri_pval, 3), " & ", fmt(robust$ri_fp_pval, 3), " & --- & --- \\\\
WCB $p$-value & ", fmt(robust$wcb_pval, 3), " & --- & --- & --- \\\\[6pt]
Pre-treatment mean & ", fmt(mean(pre[treated_state == 1]$new_enrollments), 1), " & ", fmt(mean(pre[treated_state == 1]$new_fp), 1), " & ", fmt(mean(pre[treated_state == 1]$new_np), 1), " & ", fmt(mean(pre[treated_state == 1 & state != "CA"]$new_enrollments), 1), " \\\\
\\% change & ", fmt(100 * c1$est / mean(pre[treated_state == 1]$new_enrollments), 0), "\\% & ", fmt(100 * c3$est / mean(pre[treated_state == 1]$new_fp), 0), "\\% & --- & ", fmt(100 * c_noca$est / mean(pre[treated_state == 1 & state != "CA"]$new_enrollments), 0), "\\% \\\\[6pt]
State FE & Yes & Yes & Yes & Yes \\\\
Quarter FE & Yes & Yes & Yes & Yes \\\\
Observations & ", fmt0(nrow(panel)), " & ", fmt0(nrow(panel)), " & ", fmt0(nrow(panel)), " & ", fmt0(nrow(panel[state != "CA"])), " \\\\
States & 51 & 51 & 51 & 50 \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Each column reports estimates from a difference-in-differences regression of new hospice enrollments per state-quarter on the interaction of PPEO state status (AZ, CA, NV, TX) and post-July 2023 period, with state and quarter fixed effects. Standard errors clustered by state in parentheses. RI $p$-value is from randomization inference (1,000 permutations of treatment across states). WCB $p$-value is from wild cluster bootstrap (999 replications, Rademacher weights). Column (4) excludes California, which imposed its own hospice enrollment moratorium in January 2022. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$ (cluster-robust).
\\end{tablenotes}
\\end{table}"
)
writeLines(tab2, file.path(tables_dir, "tab2_main_did.tex"))

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================

cat("Generating Table 3: Event Study...\n")

es_select <- es_coefs[rel_qtr %in% c(-8, -6, -4, -2, 0, 1, 2, 4, 6, 8)]
es_select <- es_select[order(rel_qtr)]

es_rows <- ""
for (i in 1:nrow(es_select)) {
  row <- es_select[i]
  star <- stars(row$pval)
  q_label <- ifelse(row$rel_qtr == 0, "Treatment quarter",
             ifelse(row$rel_qtr < 0, paste0("$t", row$rel_qtr, "$"),
                    paste0("$t+", row$rel_qtr, "$")))
  es_rows <- paste0(es_rows, q_label, " & ", fmt(row$estimate, 2), star,
                    " & (", fmt(row$se, 2), ") \\\\\n")
}

tab3 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Event Study: Dynamic Effects of PPEO on New Hospice Enrollments}
\\label{tab:event_study}
\\begin{tabular}{lcc}
\\toprule
Quarter relative to PPEO & Estimate & SE \\\\
\\midrule
", es_rows,
"\\midrule
Reference period & \\multicolumn{2}{c}{$t-1$ (Q2 2023)} \\\\
Pre-period quarters & \\multicolumn{2}{c}{26 (Q1 2017--Q2 2023)} \\\\
Post-period quarters & \\multicolumn{2}{c}{10 (Q3 2023--Q4 2025)} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Coefficients from a regression of new hospice enrollments per state-quarter on interactions of PPEO state status with event-time indicators, controlling for state and quarter fixed effects. Standard errors clustered by state. $t-1$ (Q2 2023) is the omitted reference period. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}"
)
writeLines(tab3, file.path(tables_dir, "tab3_event_study.tex"))

# ============================================================
# TABLE 4: Robustness — Leave-One-Out
# ============================================================

cat("Generating Table 4: Robustness...\n")

loo <- robust$loo_results
loo_rows <- ""
for (i in 1:nrow(loo)) {
  row <- loo[i]
  star <- stars(row$pval)
  loo_rows <- paste0(loo_rows, "Drop ", row$dropped, " & ",
                      fmt(row$estimate, 2), star, " & (", fmt(row$se, 2),
                      ") & ", fmt(row$pval, 3), " \\\\\n")
}

tab4 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Robustness: Leave-One-Out and Quality Comparison}
\\label{tab:robustness}
\\small
\\begin{tabular}{lccc}
\\toprule
 & Estimate & SE & $p$-value \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Leave-One-Out (Drop Each Treated State)}} \\\\[3pt]
", loo_rows,
"\\midrule
\\multicolumn{4}{l}{\\textit{Panel B: Cross-Sectional Quality (Provider Level)}} \\\\[3pt]
HCI Score & ", fmt(coef(models$mq1)["treated_state"], 2), stars(pvalue(models$mq1)["treated_state"]), " & (", fmt(se(models$mq1)["treated_state"], 2), ") & ", fmt_p(pvalue(models$mq1)["treated_state"]), " \\\\
Visits near death (\\%) & ", fmt(coef(models$mq2)["treated_state"], 2), stars(pvalue(models$mq2)["treated_state"]), " & (", fmt(se(models$mq2)["treated_state"], 2), ") & ", fmt_p(pvalue(models$mq2)["treated_state"]), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Panel A reports DiD estimates when each treated state is dropped in turn; remaining treated states form the treatment group. Panel B reports cross-sectional regressions of quality measures on a PPEO state indicator, using provider-level data from CMS Hospice Quality Reporting (Apr 2024--Mar 2025). Standard errors clustered by state in all specifications. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}"
)
writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) Appendix
# ============================================================

cat("Generating Table F1: SDE...\n")

# Compute SDE for main outcomes
pre_sd_enroll <- sd(pre[treated_state == 1]$new_enrollments)
pre_sd_fp <- sd(pre[treated_state == 1]$new_fp)
pre_sd_np <- sd(pre[treated_state == 1]$new_np)

# For excl-CA
pre_noca <- panel[state %in% c("AZ", "NV", "TX") & year_qtr < ppeo_start_yq]
pre_sd_noca <- sd(pre_noca$new_enrollments)

sde_enroll <- c1$est / pre_sd_enroll
sde_se_enroll <- c1$se / pre_sd_enroll
sde_fp <- c3$est / pre_sd_fp
sde_se_fp <- c3$se / pre_sd_fp
sde_np <- c4$est / pre_sd_np
sde_se_np <- c4$se / pre_sd_np
sde_noca <- c_noca$est / pre_sd_noca
sde_se_noca <- c_noca$se / pre_sd_noca

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE table rows
sde_rows <- paste0(
"\\multicolumn{7}{l}{\\textit{Panel A: Pooled Effects}} \\\\[3pt]\n",
"New enrollments (all) & ", fmt(c1$est, 2), " & (", fmt(c1$se, 2), ") & ", fmt(pre_sd_enroll, 2), " & ", fmt(sde_enroll, 3), " & (", fmt(sde_se_enroll, 3), ") & ", classify(sde_enroll), " \\\\\n",
"New enrollments (for-profit) & ", fmt(c3$est, 2), " & (", fmt(c3$se, 2), ") & ", fmt(pre_sd_fp, 2), " & ", fmt(sde_fp, 3), " & (", fmt(sde_se_fp, 3), ") & ", classify(sde_fp), " \\\\\n",
"New enrollments (nonprofit) & ", fmt(c4$est, 3), " & (", fmt(c4$se, 3), ") & ", fmt(pre_sd_np, 3), " & ", fmt(sde_np, 3), " & (", fmt(sde_se_np, 3), ") & ", classify(sde_np), " \\\\[6pt]\n",
"\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous Effects}} \\\\[3pt]\n",
"Excl.\\ California & ", fmt(c_noca$est, 2), " & (", fmt(c_noca$se, 2), ") & ", fmt(pre_sd_noca, 2), " & ", fmt(sde_noca, 3), " & (", fmt(sde_se_noca, 3), ") & ", classify(sde_noca), " \\\\\n"
)

# LOO heterogeneity
for (i in 1:nrow(loo)) {
  row <- loo[i]
  # Get pre-period SD for remaining treated states
  remaining <- setdiff(ppeo_states, row$dropped)
  pre_sd_loo <- sd(panel[state %in% remaining & year_qtr < ppeo_start_yq]$new_enrollments)
  sde_loo <- row$estimate / pre_sd_loo
  sde_se_loo <- row$se / pre_sd_loo
  sde_rows <- paste0(sde_rows,
    "Drop ", row$dropped, " & ", fmt(row$estimate, 2), " & (", fmt(row$se, 2),
    ") & ", fmt(pre_sd_loo, 2), " & ", fmt(sde_loo, 3), " & (", fmt(sde_se_loo, 3),
    ") & ", classify(sde_loo), " \\\\\n")
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does CMS enhanced oversight of new hospice provider enrollment (PPEO) reduce market entry, and does this effect concentrate among for-profit providers? ",
  "\\textbf{Policy mechanism:} The Provisional Period of Enhanced Oversight subjects newly enrolling hospice providers in Arizona, California, Nevada, and Texas to prepayment claim review and heightened scrutiny for up to one year, raising the cost and risk of fraudulent entry. ",
  "\\textbf{Outcome definition:} Count of new PECOS hospice enrollments per state per quarter, from CMS Provider Enrollment data. ",
  "\\textbf{Treatment:} Binary; states where CMS activated PPEO in July 2023 versus all other states. ",
  "\\textbf{Data:} CMS PECOS Hospice Enrollments (January 2026 extract), state-quarter panel, 51 states, 2017--2025 (1,836 observations). ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with state and quarter fixed effects; standard errors clustered by state; randomization inference (1,000 permutations) and wild cluster bootstrap (999 replications) for few-cluster inference. ",
  "\\textbf{Sample:} All 51 U.S.\\ states (including DC); 4 treated states selected by CMS based on concentration of new hospice certifications (86\\% of national new certifications in 2021). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation of new enrollments in treated states. ",
  "Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\small
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
", sde_rows,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}
", sde_notes, "
\\end{tablenotes}
\\end{table}"
)
writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("  tab1_sumstats.tex\n")
cat("  tab2_main_did.tex\n")
cat("  tab3_event_study.tex\n")
cat("  tab4_robustness.tex\n")
cat("  tabF1_sde.tex\n")
