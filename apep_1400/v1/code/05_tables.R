# =============================================================================
# 05_tables.R — Tables including SDE appendix (tabF1_sde.tex)
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
sq <- results$sa_bal  # Balanced panel
pfl_states <- readRDS("../data/pfl_states.rds")

# ============================================================================
# Table 1: Summary statistics
# ============================================================================

# Pre-treatment summary by group
pre_treat <- sq %>%
  filter(post == 0) %>%
  mutate(group = ifelse(treated == 1, "PFL States", "Non-PFL States"))

summ <- pre_treat %>%
  group_by(group) %>%
  summarise(
    `Mean Black hires` = sprintf("%.0f", mean(HirA_black, na.rm = TRUE)),
    `Mean White hires` = sprintf("%.0f", mean(HirA_white, na.rm = TRUE)),
    `Black hire share` = sprintf("%.3f", mean(hire_share_black, na.rm = TRUE)),
    `Log hire ratio` = sprintf("%.3f", mean(log_hira_ratio, na.rm = TRUE)),
    `SD log hire ratio` = sprintf("%.3f", sd(log_hira_ratio, na.rm = TRUE)),
    `Log earnings ratio` = sprintf("%.3f", mean(log_earn_ratio, na.rm = TRUE)),
    `N state-quarters` = as.character(n()),
    .groups = "drop"
  ) %>%
  pivot_longer(-group, names_to = "Variable", values_to = "value") %>%
  pivot_wider(names_from = group, values_from = value)

# Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n\\centering\n\\caption{Summary Statistics: Pre-Treatment Period}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lcc}\n\\hline\\hline\n")
cat(" & PFL States & Non-PFL States \\\\\n\\hline\n")
for (i in 1:nrow(summ)) {
  cat(sprintf("%s & %s & %s \\\\\n", summ$Variable[i], summ$`PFL States`[i], summ$`Non-PFL States`[i]))
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Pre-treatment period defined as all quarters before state's PFL adoption (or all quarters for non-PFL states). QWI race microdata, 2000--2024. Hire ratio is Black new hires divided by White new hires.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 saved.\n")

# ============================================================================
# Table 2: Main results — CS-DiD
# ============================================================================

sink("../tables/tab2_main_results.tex")
cat("\\begin{table}[htbp]\n\\centering\n\\caption{Effect of Paid Family Leave on Black--White Hiring Gap}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n\\hline\\hline\n")
cat(" & Log hire ratio & Log Black hires & Log White hires & Log earnings ratio \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n\\hline\n")

# CS-DiD row
cat(sprintf("\\textit{CS-DiD ATT} & %.4f & %.4f & %.4f & %.4f \\\\\n",
    results$agg_hira$overall.att, results$agg_black$overall.att,
    results$agg_white$overall.att, results$agg_earn$overall.att))
cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
    results$agg_hira$overall.se, results$agg_black$overall.se,
    results$agg_white$overall.se, results$agg_earn$overall.se))
cat("[0.5em]\n")

# TWFE row
cat(sprintf("\\textit{TWFE} & %.4f & %.4f & %.4f & %.4f \\\\\n",
    coef(results$twfe_ratio)["post"], coef(results$twfe_black)["post"],
    coef(results$twfe_white)["post"], coef(results$twfe_earn)["post"]))
cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
    se(results$twfe_ratio)["post"], se(results$twfe_black)["post"],
    se(results$twfe_white)["post"], se(results$twfe_earn)["post"]))
cat("[0.5em]\n")

# NYT control
cat(sprintf("\\textit{CS-DiD (NYT control)} & %.4f & & & \\\\\n",
    rob_results$agg_nyt$overall.att))
cat(sprintf(" & (%.4f) & & & \\\\\n",
    rob_results$agg_nyt$overall.se))

cat("\\hline\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
    format(nrow(sq), big.mark = ","), format(nrow(sq), big.mark = ","),
    format(nrow(sq), big.mark = ","), format(nrow(sq), big.mark = ",")))
cat(sprintf("Treated states & %d & %d & %d & %d \\\\\n",
    n_distinct(sq$state_fips[sq$treated == 1]),
    n_distinct(sq$state_fips[sq$treated == 1]),
    n_distinct(sq$state_fips[sq$treated == 1]),
    n_distinct(sq$state_fips[sq$treated == 1])))
cat(sprintf("Control states & %d & %d & %d & %d \\\\\n",
    n_distinct(sq$state_fips[sq$treated == 0]),
    n_distinct(sq$state_fips[sq$treated == 0]),
    n_distinct(sq$state_fips[sq$treated == 0]),
    n_distinct(sq$state_fips[sq$treated == 0])))

cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} CS-DiD estimates use Callaway and Sant'Anna (2021) with doubly robust estimation. TWFE shown for comparison. Standard errors in parentheses: bootstrapped (CS-DiD) or clustered at state level (TWFE). Log hire ratio is log(Black new hires / White new hires). NYT = not-yet-treated control group. QWI race microdata, 2000--2024.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 saved.\n")

# ============================================================================
# Table 3: Heterogeneity by policy design
# ============================================================================

sink("../tables/tab3_heterogeneity.tex")
cat("\\begin{table}[htbp]\n\\centering\n\\caption{Heterogeneity by PFL Policy Design}\n")
cat("\\label{tab:hetero}\n")
cat("\\begin{tabular}{lcc}\n\\hline\\hline\n")
cat(" & ATT & SE \\\\\n\\hline\n")
cat("\\textit{Panel A: Benefit generosity} & & \\\\\n")
cat(sprintf("\\quad High ($\\geq$ 75\\%% wage replacement) & %.4f & (%.4f) \\\\\n",
    rob_results$agg_high$overall.att, rob_results$agg_high$overall.se))
cat(sprintf("\\quad Low ($<$ 75\\%% wage replacement) & %.4f & (%.4f) \\\\\n",
    rob_results$agg_low$overall.att, rob_results$agg_low$overall.se))
cat("[0.5em]\n")
cat("\\textit{Panel B: Job protection} & & \\\\\n")
cat(sprintf("\\quad With job protection & %.4f & (%.4f) \\\\\n",
    rob_results$agg_jp_yes$overall.att, rob_results$agg_jp_yes$overall.se))
cat(sprintf("\\quad Without job protection & %.4f & (%.4f) \\\\\n",
    rob_results$agg_jp_no$overall.att, rob_results$agg_jp_no$overall.se))
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} CS-DiD ATTs on log(Black/White hire ratio). High-generosity states: WA, DC, MA, CT ($\\geq$ 75\\% replacement). Low: CA, NJ, RI, NY ($<$ 75\\%). Job protection: WA, NY, DC, MA, CT mandate job reinstatement. Standard errors bootstrapped (1,000 iterations).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 saved.\n")

# ============================================================================
# Table 4: PFL policy features
# ============================================================================

sink("../tables/tab4_pfl_features.tex")
cat("\\begin{table}[htbp]\n\\centering\n\\caption{State Paid Family Leave Programs}\n")
cat("\\label{tab:pfl}\n")
cat("\\begin{tabular}{lccccc}\n\\hline\\hline\n")
cat("State & Year & Benefit rate & Max weeks & Job protection & Funding \\\\\n\\hline\n")
pfl_sorted <- pfl_states %>% arrange(pfl_year)
for (i in 1:nrow(pfl_sorted)) {
  r <- pfl_sorted[i, ]
  cat(sprintf("%s & %d & %d\\%% & %d & %s & Employee payroll tax \\\\\n",
      r$state_name, r$pfl_year, round(r$benefit_rate * 100),
      r$max_weeks, ifelse(r$job_protection, "Yes", "No")))
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Year indicates when benefits became available. Benefit rates are approximate averages; some states have tiered rates. Job protection indicates statutory right to job reinstatement. All programs funded through employee payroll tax contributions. Sources: NCSL, state labor department websites.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 saved.\n")

# ============================================================================
# SDE Table (Appendix F1) — tabF1_sde.tex
# ============================================================================

# Compute SDEs
sd_y_pre <- sd(sq$log_hira_ratio[sq$post == 0], na.rm = TRUE)
sd_y_earn_pre <- sd(sq$log_earn_ratio[sq$post == 0], na.rm = TRUE)
sd_y_black_pre <- sd(sq$log_hira_black[sq$post == 0], na.rm = TRUE)
sd_y_white_pre <- sd(sq$log_hira_white[sq$post == 0], na.rm = TRUE)

classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

sde_rows <- tibble(
  outcome = c("Log Black/White hire ratio", "Log Black hires",
              "Log White hires", "Log Black/White earnings ratio"),
  beta = c(results$agg_hira$overall.att, results$agg_black$overall.att,
           results$agg_white$overall.att, results$agg_earn$overall.att),
  se_beta = c(results$agg_hira$overall.se, results$agg_black$overall.se,
              results$agg_white$overall.se, results$agg_earn$overall.se),
  sd_y = c(sd_y_pre, sd_y_black_pre, sd_y_white_pre, sd_y_earn_pre)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = sapply(sde, classify_sde)
  )

# Heterogeneity rows (Panel B): high vs low generosity
sde_hetero <- tibble(
  outcome = c("Hire ratio (high generosity)", "Hire ratio (low generosity)"),
  beta = c(rob_results$agg_high$overall.att, rob_results$agg_low$overall.att),
  se_beta = c(rob_results$agg_high$overall.se, rob_results$agg_low$overall.se),
  sd_y = c(sd_y_pre, sd_y_pre)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = sapply(sde, classify_sde)
  )

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state-level Paid Family Leave narrow or widen the Black--White gap in new hiring from non-employment? ",
  "\\textbf{Policy mechanism:} PFL provides partial wage replacement (55--90\\%) for workers taking family or medical leave, funded by employee payroll tax; by socializing leave costs, PFL may reduce the perceived hiring cost of workers expected to take leave, or conversely signal higher expected absence. ",
  "\\textbf{Outcome definition:} Log ratio of Black to White new hires from non-employment (HirA), measuring the relative flow of Black vs.\\ White workers entering employment. ",
  "\\textbf{Treatment:} Binary; state adopts PFL benefits (8 states, 2004--2022). ",
  "\\textbf{Data:} QWI race microdata (Census Bureau), state $\\times$ quarter, 2000--2024, 50 states + DC. ",
  "\\textbf{Method:} Callaway--Sant'Anna staggered DiD with doubly robust estimation; standard errors bootstrapped (1,000 iterations); never-treated states as control group. ",
  "\\textbf{Sample:} All state-quarters with non-missing Black and White new-hire counts; 8 treated states, 43 control states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n\\centering\n\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n")
cat("\\textit{Panel A: Pooled} & & & & & & \\\\\n")
for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  cat(sprintf("\\quad %s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
      r$outcome, r$beta, r$se_beta, r$sd_y, r$sde, r$se_sde, r$classification))
}
cat("[0.5em]\n")
cat("\\textit{Panel B: Heterogeneous (benefit generosity)} & & & & & & \\\\\n")
for (i in 1:nrow(sde_hetero)) {
  r <- sde_hetero[i, ]
  cat(sprintf("\\quad %s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
      r$outcome, r$beta, r$se_beta, r$sd_y, r$sde, r$se_sde, r$classification))
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("SDE table saved.\n")

cat("All tables generated.\n")
