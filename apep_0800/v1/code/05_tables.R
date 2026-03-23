# =============================================================================
# 05_tables.R — Generate all tables including SDE appendix
# APEP Working Paper apep_0800
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
df <- arrow::read_parquet("../data/analysis_panel.parquet")
df_fin <- df %>% filter(industry == "52")

# ---------------------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

summ <- df_fin %>%
  group_by(ban_state, race) %>%
  summarise(
    `Mean New Hires` = mean(HirN, na.rm = TRUE),
    `SD New Hires` = sd(HirN, na.rm = TRUE),
    `Mean Employment` = mean(Emp, na.rm = TRUE),
    `SD Employment` = sd(Emp, na.rm = TRUE),
    `Mean Earnings (New Hires)` = mean(EarnHirNS, na.rm = TRUE),
    `SD Earnings (New Hires)` = sd(EarnHirNS, na.rm = TRUE),
    `Counties` = n_distinct(county_fips),
    `Observations` = n(),
    .groups = "drop"
  ) %>%
  mutate(
    Group = case_when(
      ban_state & race == "A2" ~ "Ban States, Black",
      ban_state & race == "A1" ~ "Ban States, White",
      !ban_state & race == "A2" ~ "Non-Ban States, Black",
      !ban_state & race == "A1" ~ "Non-Ban States, White"
    )
  ) %>%
  select(Group, everything(), -ban_state, -race)

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Finance Sector (NAICS 52), 2002--2018}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{New Hires} & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{New Hire Earnings} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Group & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ)) {
  row <- summ[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.1f & %.1f & %.1f & %.1f & \\$%.0f & \\$%.0f \\\\",
    row$Group,
    row$`Mean New Hires`, row$`SD New Hires`,
    row$`Mean Employment`, row$`SD Employment`,
    row$`Mean Earnings (New Hires)`, row$`SD Earnings (New Hires)`
  ))
  if (i == 2) tab1_lines <- c(tab1_lines, "\\addlinespace")
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("\\multicolumn{7}{l}{\\textit{Counties:} Ban states: %d; Non-ban states: %d. \\textit{Quarters:} %d (2002Q1--2018Q4).} \\\\",
          n_distinct(df_fin$county_fips[df_fin$ban_state]),
          n_distinct(df_fin$county_fips[!df_fin$ban_state]),
          n_distinct(df_fin$cal_quarter)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Data from the Quarterly Workforce Indicators (QWI), county $\\times$ quarter $\\times$ race panel, 2002--2018. Sample restricted to NAICS 52 (Finance and Insurance). New Hires (\\texttt{HirN}) counts all new hires in the quarter; Employment (\\texttt{Emp}) is beginning-of-quarter employment; New Hire Earnings (\\texttt{EarnHirNS}) is average monthly earnings for new hires. Ban states enacted restrictions on employer use of credit history in hiring between 2007 and 2013: WA (2007), HI (2009), OR and IL (2010), CA, MD, CT, and DC (2011), VT (2012), NV and CO (2013).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Written tables/tab1_summary.tex\n")

# ---------------------------------------------------------------------------
# Table 2: Main Triple-Difference Results (TWFE)
# ---------------------------------------------------------------------------
cat("\n=== Table 2: Main DDD Results ===\n")

# Extract coefficients
coef_hirn <- coef(results$twfe_hirn)["ddd"]
se_hirn <- sqrt(vcov(results$twfe_hirn)["ddd", "ddd"])

coef_emp <- coef(results$twfe_emp)["ddd"]
se_emp <- sqrt(vcov(results$twfe_emp)["ddd", "ddd"])

coef_earn <- coef(results$twfe_earn)["ddd"]
se_earn <- sqrt(vcov(results$twfe_earn)["ddd", "ddd"])

# CS estimates
cs_hirn_est <- results$cs_agg_hirn$overall.att
cs_hirn_se <- results$cs_agg_hirn$overall.se

cs_emp_est <- results$cs_agg_emp$overall.att
cs_emp_se <- results$cs_agg_emp$overall.se

if (!is.null(results$cs_agg_earn)) {
  cs_earn_est <- results$cs_agg_earn$overall.att
  cs_earn_se <- results$cs_agg_earn$overall.se
} else {
  cs_earn_est <- NA_real_
  cs_earn_se <- NA_real_
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

pval <- function(coef, se) {
  if (is.na(coef) || is.na(se)) return(NA_real_)
  2 * pnorm(-abs(coef / se))
}

fmt <- function(x, d = 4) {
  if (is.na(x)) return("---")
  formatC(x, format = "f", digits = d)
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Credit Check Bans on the Black--White Gap in Finance}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & New Hires & Employment & New Hire \\\\",
  " & (asinh) & (asinh) & Earnings (log) \\\\",
  "\\midrule",
  "\\addlinespace",
  "\\multicolumn{4}{l}{\\textit{Panel A: TWFE Triple-Difference}} \\\\",
  "\\addlinespace",
  sprintf("Black $\\times$ Ban $\\times$ Post & %.4f%s & %.4f%s & %.4f%s \\\\",
          coef_hirn, stars(pval(coef_hirn, se_hirn)),
          coef_emp, stars(pval(coef_emp, se_emp)),
          coef_earn, stars(pval(coef_earn, se_earn))),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\", se_hirn, se_emp, se_earn),
  "\\addlinespace",
  sprintf("Observations & %s & %s & %s \\\\",
          format(nobs(results$twfe_hirn), big.mark = ","),
          format(nobs(results$twfe_emp), big.mark = ","),
          format(nobs(results$twfe_earn), big.mark = ",")),
  "\\addlinespace",
  "\\multicolumn{4}{l}{\\textit{Panel B: Callaway--Sant'Anna on Black--White Gap}} \\\\",
  "\\addlinespace",
  sprintf("ATT (simple) & %s%s & %s%s & %s%s \\\\",
          fmt(cs_hirn_est), stars(pval(cs_hirn_est, cs_hirn_se)),
          fmt(cs_emp_est), stars(pval(cs_emp_est, cs_emp_se)),
          fmt(cs_earn_est), stars(pval(cs_earn_est, cs_earn_se))),
  sprintf(" & (%s) & (%s) & (%s) \\\\", fmt(cs_hirn_se), fmt(cs_emp_se), fmt(cs_earn_se)),
  "\\addlinespace",
  "County $\\times$ Race FE & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports TWFE triple-difference estimates: $\\delta$ from $Y_{ctr} = \\alpha_{cr} + \\gamma_t + \\delta(\\text{Black} \\times \\text{Ban} \\times \\text{Post}) + \\text{controls} + \\varepsilon$. Panel B reports Callaway--Sant'Anna (2021) ATT estimates on the within-county Black--White gap (asinh or log), using never-treated counties as controls. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Written tables/tab2_main.tex\n")

# ---------------------------------------------------------------------------
# Table 3: Robustness
# ---------------------------------------------------------------------------
cat("\n=== Table 3: Robustness ===\n")

# Extract coefficients from robustness models
rob_specs <- list(
  "Agriculture placebo (NAICS 11)" = rob$ag_placebo,
  "Excluding Washington" = rob$no_wa,
  "Employment stock" = rob$emp_stock,
  "Log specification" = rob$log_spec,
  "Annual aggregation" = rob$annual
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Coefficient & SE & $p$-value & $N$ \\\\",
  "\\midrule"
)

for (spec_name in names(rob_specs)) {
  m <- rob_specs[[spec_name]]
  ddd_coef <- coef(m)["ddd"]
  if (is.na(ddd_coef)) {
    # For models without the triple interaction (white placebo)
    ddd_coef <- coef(m)["post"]
    ddd_se <- sqrt(vcov(m)["post", "post"])
  } else {
    ddd_se <- sqrt(vcov(m)["ddd", "ddd"])
  }
  p <- pval(ddd_coef, ddd_se)
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %.4f%s & (%.4f) & %.3f & %s \\\\",
    spec_name, ddd_coef, stars(p), ddd_se, p,
    format(nobs(m), big.mark = ",")
  ))
}

# Add wild bootstrap row if available
if (!is.null(rob$boot_result)) {
  tab3_lines <- c(tab3_lines,
    "\\addlinespace",
    sprintf("Wild cluster bootstrap $p$-value & \\multicolumn{4}{c}{%.3f} \\\\",
            rob$boot_result$p_val)
  )
}

# White worker placebo
m_w <- rob$white_placebo
w_coef <- coef(m_w)["post"]
w_se <- sqrt(vcov(m_w)["post", "post"])
w_p <- pval(w_coef, w_se)
tab3_lines <- c(tab3_lines,
  "\\addlinespace",
  sprintf("White worker placebo (ban states) & %.4f%s & (%.4f) & %.3f & %s \\\\",
          w_coef, stars(w_p), w_se, w_p, format(nobs(m_w), big.mark = ","))
)

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the triple-difference coefficient (Black $\\times$ Ban $\\times$ Post) from a separate regression, except the agriculture placebo (NAICS 11 instead of NAICS 52), the white worker placebo (simple DD of Post within ban states, white workers only), and the wild cluster bootstrap row (Webb six-point distribution, 9,999 iterations). All specifications include county$\\times$race and quarter fixed effects with state-level clustering.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("Written tables/tab3_robustness.tex\n")

# ---------------------------------------------------------------------------
# Table 4: Event Study Coefficients
# ---------------------------------------------------------------------------
cat("\n=== Table 4: Event Study ===\n")

es_df <- readRDS("../data/cs_event_study.rds")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study Coefficients: Black--White Hiring Gap (Callaway--Sant'Anna)}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{rcc}",
  "\\toprule",
  "Quarters Relative & ATT & 95\\% CI \\\\",
  "to Ban & & \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_df)) {
  row <- es_df[i, ]
  ci_str <- if (is.na(row$ci_lo) || is.na(row$ci_hi)) {
    "---"
  } else {
    sprintf("[%.4f, %.4f]", row$ci_lo, row$ci_hi)
  }
  tab4_lines <- c(tab4_lines, sprintf(
    "%+d & %.4f%s & %s \\\\",
    row$event_time, row$att, stars(pval(row$att, row$se)),
    ci_str
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Callaway--Sant'Anna (2021) group-time ATT estimates aggregated to event-time, using never-treated counties as the control group with universal base period. The outcome is the within-county Black--White gap in asinh(new hires) in NAICS 52 (Finance). Confidence intervals based on standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_event_study.tex")
cat("Written tables/tab4_event_study.tex\n")

# ---------------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE Appendix)
# ---------------------------------------------------------------------------
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute pre-treatment SD(Y) for each outcome
pre_fin <- df_fin %>% filter(year < 2007)

sd_hirn_pre <- sd(pre_fin$asinh_hirn, na.rm = TRUE)
sd_emp_pre <- sd(pre_fin$asinh_emp, na.rm = TRUE)
sd_earn_pre <- sd(pre_fin$log_earn_hir, na.rm = TRUE)

# Use TWFE DDD estimates (preferred specification)
sde_rows <- data.frame(
  outcome = c("New Hires (asinh)", "Employment (asinh)", "New Hire Earnings (log)"),
  beta = c(coef_hirn, coef_emp, coef_earn),
  se = c(se_hirn, se_emp, se_earn),
  sd_y = c(sd_hirn_pre, sd_emp_pre, sd_earn_pre)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state bans on employer credit history checks reduce the Black--White gap in finance-sector hiring? ",
  "\\textbf{Policy mechanism:} Ten states (2007--2013) prohibited employers from using applicant credit history in most hiring decisions, removing a screening tool that disproportionately excludes Black workers who are 1.7--2$\\times$ more likely to have subprime credit records due to historical discrimination and income volatility. ",
  "\\textbf{Outcome definition:} New hires (HirN) from QWI measuring total quarterly new hires; employment (Emp) measuring beginning-of-quarter employment stock; new hire earnings (EarnHirNS) measuring average monthly earnings of new hires. All measured as Black--White within-county gaps. ",
  "\\textbf{Treatment:} Binary; state enactment of employer credit check restriction (staggered 2007--2013). ",
  "\\textbf{Data:} Census Bureau Quarterly Workforce Indicators (QWI), county $\\times$ quarter $\\times$ race $\\times$ industry panel, 2002--2018, NAICS 52 (Finance and Insurance). ",
  "\\textbf{Method:} TWFE triple-difference (Black $\\times$ Ban $\\times$ Post) with county$\\times$race and calendar-quarter fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties with non-missing QWI data for both Black and White workers in finance; approximately 3,100 counties across 50 states plus DC. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Written tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
