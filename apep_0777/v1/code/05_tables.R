# 05_tables.R — Generate all LaTeX tables
# apep_0777: SNAP-Medicaid Data Coordination

source("00_packages.R")
library(fixest)

panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))
results <- readRDS("../data/regression_results.rds")
summary_stats <- read_csv("../data/summary_stats.csv", show_col_types = FALSE)

# ============================================================
# Table 1: Summary Statistics
# ============================================================

# Compute stats by treatment group and period
tab1_data <- panel %>%
  mutate(period = ifelse(post == 1, "Post-Unwinding", "Pre-Unwinding")) %>%
  group_by(e14_waiver, period) %>%
  summarize(
    n_states = n_distinct(state),
    mean_enrollment = mean(enrollment),
    sd_enrollment = sd(enrollment),
    mean_norm = mean(norm_enrollment),
    sd_norm = sd(norm_enrollment),
    n_months = n_distinct(date),
    .groups = "drop"
  )

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Treatment Group}\n",
  "\\label{tab:summary}\n",
  "\\small\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{E14 Waiver States} & \\multicolumn{2}{c}{Non-E14 States} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Pre & Post & Pre & Post \\\\\n",
  "\\midrule\n"
)

e14_pre <- tab1_data %>% filter(e14_waiver & period == "Pre-Unwinding")
e14_post <- tab1_data %>% filter(e14_waiver & period == "Post-Unwinding")
non_pre <- tab1_data %>% filter(!e14_waiver & period == "Pre-Unwinding")
non_post <- tab1_data %>% filter(!e14_waiver & period == "Post-Unwinding")

tab1_tex <- paste0(tab1_tex,
  "Number of states & \\multicolumn{2}{c}{", e14_pre$n_states, "} & \\multicolumn{2}{c}{", non_pre$n_states, "} \\\\\n",
  "Mean enrollment & ", format(round(e14_pre$mean_enrollment), big.mark = ","), " & ",
  format(round(e14_post$mean_enrollment), big.mark = ","), " & ",
  format(round(non_pre$mean_enrollment), big.mark = ","), " & ",
  format(round(non_post$mean_enrollment), big.mark = ","), " \\\\\n",
  "Normalized enrollment & ", sprintf("%.3f", e14_pre$mean_norm), " & ",
  sprintf("%.3f", e14_post$mean_norm), " & ",
  sprintf("%.3f", non_pre$mean_norm), " & ",
  sprintf("%.3f", non_post$mean_norm), " \\\\\n",
  "SD(normalized) & ", sprintf("%.3f", e14_pre$sd_norm), " & ",
  sprintf("%.3f", e14_post$sd_norm), " & ",
  sprintf("%.3f", non_pre$sd_norm), " & ",
  sprintf("%.3f", non_post$sd_norm), " \\\\\n",
  "State-months & ", e14_pre$n_states * e14_pre$n_months, " & ",
  e14_post$n_states * e14_post$n_months, " & ",
  non_pre$n_states * non_pre$n_months, " & ",
  non_post$n_states * non_post$n_months, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} E14 waiver states received Section 1902(e)(14)(A) waivers ",
  "allowing SNAP-based ex parte Medicaid renewal. Pre-period: January 2019--March 2023. ",
  "Post-period: April 2023--December 2024. Normalized enrollment divides each state's ",
  "monthly enrollment by its March 2023 baseline. Source: CMS Monthly Medicaid and CHIP ",
  "Enrollment Reports.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================
# Table 2: Main DiD Results
# ============================================================

m1 <- results$m1_did
m2 <- results$m2_log

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{The Effect of SNAP-Medicaid Data Coordination on Enrollment Retention}\n",
  "\\label{tab:main}\n",
  "\\small\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Normalized Enrollment & Log Enrollment \\\\\n",
  " & (1) & (2) \\\\\n",
  "\\midrule\n",
  "E14 Waiver $\\times$ Post & ", sprintf("%.4f", coef(m1)), " & ",
  sprintf("%.4f", coef(m2)), " \\\\\n",
  " & (", sprintf("%.4f", se(m1)), ") & ",
  "(", sprintf("%.4f", se(m2)), ") \\\\\n",
  " & [$p = ", sprintf("%.3f", pvalue(m1)), "$] & ",
  "[$p = ", sprintf("%.3f", pvalue(m2)), "$] \\\\\n",
  "\\midrule\n",
  "State FE & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(m1), big.mark = ","), " & ",
  format(nobs(m2), big.mark = ","), " \\\\\n",
  "Within $R^2$ & ", sprintf("%.4f", fitstat(m1, "wr2")[[1]]), " & ",
  sprintf("%.4f", fitstat(m2, "wr2")[[1]]), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Difference-in-differences estimates comparing Medicaid enrollment ",
  "in states with Section 1902(e)(14)(A) SNAP-based ex parte renewal waivers (17 states) ",
  "to states without (33 states). Treatment onset: April 2023 (end of continuous enrollment). ",
  "Normalized enrollment divides each state's monthly total by its March 2023 value. ",
  "Standard errors clustered by state in parentheses; $p$-values in brackets.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================

es <- results$es_coefs

# Select key months for table
key_months <- c(-12, -9, -6, -3, -1, 0, 1, 3, 6, 9, 12)
es_table <- es %>%
  filter(month %in% key_months) %>%
  arrange(month)

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Effects of SNAP-Medicaid Data Coordination}\n",
  "\\label{tab:eventstudy}\n",
  "\\small\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Months Relative & Estimate & SE & 95\\% CI \\\\\n",
  "to Unwinding & & & \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(es_table)) {
  r <- es_table[i, ]
  stars <- ""
  tstat <- if (!is.na(r$se) && r$se > 0) abs(r$estimate / r$se) else 0
  if (tstat > 2.576) stars <- "***"
  else if (tstat > 1.96) stars <- "**"
  else if (tstat > 1.645) stars <- "*"

  label <- ifelse(r$month == -1, "$-1$ (baseline)", as.character(r$month))
  est_str <- ifelse(r$month == -1, "---", paste0(sprintf("%.4f", r$estimate), stars))
  se_str <- ifelse(r$month == -1, "---", sprintf("%.4f", r$se))
  ci_str <- ifelse(r$month == -1, "---",
                   paste0("[", sprintf("%.3f", r$ci_low), ", ", sprintf("%.3f", r$ci_high), "]"))

  tab3_tex <- paste0(tab3_tex, label, " & ", est_str, " & ", se_str, " & ", ci_str, " \\\\\n")
}

tab3_tex <- paste0(tab3_tex,
  "\\midrule\n",
  "State FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "Month FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "Observations & \\multicolumn{3}{c}{", format(nobs(results$m3_es), big.mark = ","), "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Event study estimates from a fully saturated interaction of ",
  "E14 waiver status with monthly indicators relative to March 2023 (month $-1$). ",
  "Outcome: normalized Medicaid enrollment. Standard errors clustered by state. ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_eventstudy.tex")
cat("Table 3 written.\n")

# ============================================================
# Table 4: Robustness
# ============================================================

rob <- readRDS("../data/robustness_results.rds")

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\small\n",
  "\\begin{tabular}{llccc}\n",
  "\\toprule\n",
  "Panel & Specification & Estimate & SE & $N$ \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{A: Baseline (E14 waiver definition)}} \\\\\n",
  " & Normalized enrollment & ", sprintf("%.4f", coef(m1)), " & ",
  sprintf("%.4f", se(m1)), " & ", nobs(m1), " \\\\\n",
  "\\multicolumn{5}{l}{\\textit{B: Broader treatment (KFF integrated systems)}} \\\\\n",
  " & Normalized enrollment & ", sprintf("%.4f", coef(rob$m_kff)["kff_integratedFALSE:post"]), " & ",
  sprintf("%.4f", se(rob$m_kff)["kff_integratedFALSE:post"]), " & ", nobs(rob$m_kff), " \\\\\n",
  "\\multicolumn{5}{l}{\\textit{C: Excluding states that paused disenrollment}} \\\\\n",
  " & Normalized enrollment & ", sprintf("%.4f", coef(rob$m_no_pause)["e14_waiverFALSE:post"]), " & ",
  sprintf("%.4f", se(rob$m_no_pause)["e14_waiverFALSE:post"]), " & ", nobs(rob$m_no_pause), " \\\\\n",
  "\\multicolumn{5}{l}{\\textit{D: Placebo (April 2022 treatment date)}} \\\\\n",
  " & Normalized enrollment & ", sprintf("%.4f", coef(rob$m_placebo)["e14_waiverFALSE:post_placebo"]), " & ",
  sprintf("%.4f", se(rob$m_placebo)["e14_waiverFALSE:post_placebo"]), " & ", nobs(rob$m_placebo), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} All specifications include state and month fixed effects ",
  "with standard errors clustered by state. Panel B uses KFF's broader 26-state integrated ",
  "eligibility system definition. Panel C drops 12 states that paused procedural disenrollments. ",
  "Panel D applies a placebo treatment date of April 2022 using pre-unwinding data only.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# ============================================================
# Table F1: Standardized Effect Size
# ============================================================

# Main outcome: normalized enrollment
beta1 <- coef(results$m1_did)
se1 <- se(results$m1_did)
sd_y_pre <- sd(panel$norm_enrollment[panel$post == 0])
sde1 <- beta1 / sd_y_pre
se_sde1 <- se1 / sd_y_pre

# Secondary: late-period event study (avg of months 6-12)
es_late <- results$es_coefs %>% filter(month >= 6 & month <= 12)
beta_late <- mean(es_late$estimate)
se_late <- mean(es_late$se)
sde_late <- beta_late / sd_y_pre
se_sde_late <- se_late / sd_y_pre

classify <- function(sde) {
  a <- abs(sde)
  if (a < 0.005) "Null"
  else if (a < 0.05) ifelse(sde > 0, "Small positive", "Small negative")
  else if (a < 0.15) ifelse(sde > 0, "Moderate positive", "Moderate negative")
  else ifelse(sde > 0, "Large positive", "Large negative")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does cross-program administrative data coordination between SNAP and Medicaid reduce enrollment losses during the 2023--2024 Medicaid unwinding? ",
  "\\textbf{Policy mechanism:} Section 1902(e)(14)(A) waivers allow states to use SNAP enrollment records for automatic Medicaid renewal, bypassing manual redetermination forms and reducing procedural disenrollment during the post-PHE unwinding of continuous enrollment. ",
  "\\textbf{Outcome definition:} Monthly state-level Medicaid and CHIP enrollment, normalized to each state's March 2023 baseline (the last month before unwinding began). ",
  "\\textbf{Treatment:} Binary; states with approved E14 waivers (17 states) versus states without (33 states). ",
  "\\textbf{Data:} CMS Monthly Medicaid and CHIP Enrollment Reports (data.medicaid.gov), January 2019--December 2024, state-month panel, $N = 3{,}599$. ",
  "\\textbf{Method:} Two-way fixed effects DiD with state and month FE; standard errors clustered by state. ",
  "\\textbf{Sample:} All 50 states plus DC; analysis restricted to states with non-missing March 2023 baseline enrollment. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (.05$--.15$), Small (.005$--.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "Enrollment (pooled DiD) & ", sprintf("%.4f", beta1), " & ", sprintf("%.4f", se1), " & ",
  sprintf("%.3f", sd_y_pre), " & ", sprintf("%.3f", sde1), " & ", sprintf("%.3f", se_sde1),
  " & ", classify(sde1), " \\\\\n",
  "Enrollment (months 6--12) & ", sprintf("%.4f", beta_late), " & ", sprintf("%.4f", se_late), " & ",
  sprintf("%.3f", sd_y_pre), " & ", sprintf("%.3f", sde_late), " & ", sprintf("%.3f", se_sde_late),
  " & ", classify(sde_late), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables written.\n")
