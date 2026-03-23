## 05_tables.R — Generate all tables including SDE
## apep_0781: UI Taxable Wage Base and Employer Separations

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results.rds")
rob_results <- readRDS("../data/rob_results.rds")

# ── Helpers ──
get_coef <- function(fit) {
  cn <- names(coef(fit))
  idx <- grep("1:treated|treated:1", cn)
  if (length(idx) == 0) idx <- grep("treated", cn)
  if (length(idx) == 0) stop("No treatment coef in: ", paste(cn, collapse = ", "))
  idx <- idx[1]
  list(b = coef(fit)[idx], se = sqrt(diag(vcov(fit)))[idx])
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.10) "*" else ""
}

pval <- function(b, se) 2 * pnorm(-abs(b / se))
fmt_c <- function(b, se) paste0(sprintf("%.3f", b), stars(pval(b, se)))
fmt_s <- function(se) paste0("(", sprintf("%.3f", se), ")")

# ══════════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════

analysis <- panel %>% filter(group %in% c("Treated", "Control (Fed Min)"))

summ <- analysis %>%
  group_by(group, low_wage) %>%
  summarise(
    `Mean Sep` = sprintf("%.0f", mean(Sep, na.rm = TRUE)),
    `SD Sep` = sprintf("%.0f", sd(Sep, na.rm = TRUE)),
    `Mean Emp` = sprintf("%.0f", mean(Emp, na.rm = TRUE)),
    `Mean Earn` = sprintf("%.0f", mean(EarnS, na.rm = TRUE)),
    N = format(n(), big.mark = ","),
    States = as.character(n_distinct(state_fips)),
    .groups = "drop"
  ) %>%
  mutate(Sector = ifelse(low_wage, "Low-Wage", "High-Wage"))

tab1 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Summary Statistics by Treatment Group and Industry Wage Level}\n",
  "\\label{tab:summary}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccc}\n\\toprule\n",
  "Group & Sector & Mean Sep & SD Sep & Mean Emp & Mean Earn (\\$) & N & States \\\\\n\\midrule\n"
)

for (i in seq_len(nrow(summ))) {
  r <- summ[i, ]
  tab1 <- paste0(tab1, r$group, " & ", r$Sector, " & ", r$`Mean Sep`, " & ",
    r$`SD Sep`, " & ", r$`Mean Emp`, " & ", r$`Mean Earn`, " & ", r$N, " & ", r$States, " \\\\\n")
}

tab1 <- paste0(tab1,
  "\\bottomrule\n\\end{tabular}\n\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Full sample 2001Q1--2023Q4. Separations, employment, and earnings from ",
  "Census QWI at state-industry-quarter level. Low-wage: retail (NAICS 44-45) and accommodation/food ",
  "(NAICS 72). High-wage: finance (NAICS 52) and professional services (NAICS 54). ",
  "Treated states raised their UI taxable wage base above \\$7,000 federal minimum. ",
  "Control states remained at or near the federal minimum throughout (AZ, CA, FL, GA, MI, MS, NE, TN).\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ══════════════════════════════════════════════════════════════════
# Table 2: Main Results
# ══════════════════════════════════════════════════════════════════

tc_low <- get_coef(results$twfe_low)
tc_high <- get_coef(results$twfe_high)
tc_emp_low <- get_coef(results$twfe_emp_low)
tc_emp_high <- get_coef(results$twfe_emp_high)

tab2 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Effect of UI Wage Base Increases on Separations and Employment}\n",
  "\\label{tab:main}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & \\multicolumn{2}{c}{Log Separations} & \\multicolumn{2}{c}{Log Employment} \\\\\n",
  " & Low-Wage & High-Wage & Low-Wage & High-Wage \\\\\n",
  "\\midrule\n",
  "Treated $\\times$ Post & ",
    fmt_c(tc_low$b, tc_low$se), " & ",
    fmt_c(tc_high$b, tc_high$se), " & ",
    fmt_c(tc_emp_low$b, tc_emp_low$se), " & ",
    fmt_c(tc_emp_high$b, tc_emp_high$se), " \\\\\n",
  " & ", fmt_s(tc_low$se), " & ", fmt_s(tc_high$se), " & ",
    fmt_s(tc_emp_low$se), " & ", fmt_s(tc_emp_high$se), " \\\\\n",
  "\\midrule\n",
  "State FE & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "Industry FE & Yes & Yes & Yes & Yes \\\\\n",
  "N & ", format(nobs(results$twfe_low), big.mark = ","), " & ",
    format(nobs(results$twfe_high), big.mark = ","), " & ",
    format(nobs(results$twfe_emp_low), big.mark = ","), " & ",
    format(nobs(results$twfe_emp_high), big.mark = ","), " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Dependent variables are log(separations $+$ 1) and log(employment $+$ 1). ",
  "Low-wage: retail and food/accommodation. High-wage: finance and professional services (placebo). ",
  "Post = years after state raised UI taxable wage base. Standard errors clustered at state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ══════════════════════════════════════════════════════════════════
# Table 3: Triple-Difference
# ══════════════════════════════════════════════════════════════════

ddd_coefs <- coef(results$ddd)
ddd_ses <- sqrt(diag(vcov(results$ddd)))
ddd_term <- grep("treated:lw:post", names(ddd_coefs), value = TRUE)[1]

tab3 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Triple-Difference: Treated $\\times$ Low-Wage $\\times$ Post}\n",
  "\\label{tab:ddd}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lc}\n\\toprule\n",
  " & Log Separations \\\\\n\\midrule\n",
  "Treated $\\times$ Low-Wage $\\times$ Post & ",
    fmt_c(ddd_coefs[ddd_term], ddd_ses[ddd_term]), " \\\\\n",
  " & ", fmt_s(ddd_ses[ddd_term]), " \\\\\n",
  "\\midrule\n",
  "State FE & Yes \\\\\n",
  "Quarter FE & Yes \\\\\n",
  "Industry FE & Yes \\\\\n",
  "N & ", format(nobs(results$ddd), big.mark = ","), " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Triple-difference compares separations in low-wage industries (retail, food) ",
  "vs.\\ high-wage industries (finance, professional) in states that raised their UI taxable wage base ",
  "vs.\\ states at the federal minimum, before and after the increase. Absorbs state-level confounders ",
  "and industry trends. State-clustered SEs. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_ddd.tex")
cat("Table 3 written.\n")

# ══════════════════════════════════════════════════════════════════
# Table 4: Robustness
# ══════════════════════════════════════════════════════════════════

specs <- list(
  list(name = "Baseline (low-wage)", model = results$twfe_low),
  list(name = "Excl.\\ 2008--2010", model = rob_results$twfe_no_crisis),
  list(name = "Manufacturing", model = rob_results$twfe_mfg),
  list(name = "Broader controls", model = rob_results$twfe_broad),
  list(name = "Hiring (low-wage)", model = rob_results$twfe_hir)
)

tab4_rows <- ""
for (spec in specs) {
  tc <- get_coef(spec$model)
  tab4_rows <- paste0(tab4_rows,
    spec$name, " & ", fmt_c(tc$b, tc$se), " & ", fmt_s(tc$se), " & ",
    format(nobs(spec$model), big.mark = ","), " \\\\\n")
}

tab4 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  "Specification & Estimate & SE & N \\\\\n\\midrule\n",
  tab4_rows,
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} All specifications include state, quarter, and industry FE with state-clustered SEs. ",
  "Baseline is log separations in low-wage industries. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# ══════════════════════════════════════════════════════════════════
# SDE Table (Appendix F1)
# ══════════════════════════════════════════════════════════════════

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

# Pre-treatment SDs
pre_low <- analysis %>% filter(low_wage, !post_increase)
pre_high <- analysis %>% filter(high_wage, !post_increase)
pre_all <- analysis %>% filter(low_wage | high_wage, !post_increase)

sd_sep_low <- sd(pre_low$log_sep, na.rm = TRUE)
sd_sep_high <- sd(pre_high$log_sep, na.rm = TRUE)
sd_emp_low <- sd(pre_low$log_emp, na.rm = TRUE)
sd_ddd <- sd(pre_all$log_sep, na.rm = TRUE)

sde_rows <- tibble(
  Outcome = c("Separations (Low-Wage)", "Separations (High-Wage)",
              "Employment (Low-Wage)", "Separations (DDD)"),
  beta = c(tc_low$b, tc_high$b, tc_emp_low$b, ddd_coefs[ddd_term]),
  se = c(tc_low$se, tc_high$se, tc_emp_low$se, ddd_ses[ddd_term]),
  sd_y = c(sd_sep_low, sd_sep_high, sd_emp_low, sd_ddd),
  sde = c(tc_low$b, tc_high$b, tc_emp_low$b, ddd_coefs[ddd_term]) /
        c(sd_sep_low, sd_sep_high, sd_emp_low, sd_ddd),
  se_sde = c(tc_low$se, tc_high$se, tc_emp_low$se, ddd_ses[ddd_term]) /
           c(sd_sep_low, sd_sep_high, sd_emp_low, sd_ddd),
  classification = classify(
    c(tc_low$b, tc_high$b, tc_emp_low$b, ddd_coefs[ddd_term]) /
    c(sd_sep_low, sd_sep_high, sd_emp_low, sd_ddd)
  )
)

sde_body <- ""
for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i, ]
  sde_body <- paste0(sde_body,
    r$Outcome, " & ", sprintf("%.4f", r$beta), " & ", sprintf("%.4f", r$se),
    " & --- & ", sprintf("%.4f", r$sd_y), " & ", sprintf("%.4f", r$sde),
    " & ", sprintf("%.4f", r$se_sde), " & ", r$classification, " \\\\\n")
}

sde_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{@{}lrrcrrcl@{}}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n",
  sde_body,
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\scriptsize\n",
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state increases in the UI taxable wage base reduce ",
  "employer-initiated separations, particularly in low-wage industries where the marginal ",
  "tax cost increase is binding? ",
  "\\textbf{Policy mechanism:} State UI systems are experience-rated: employers who lay off ",
  "more workers face higher payroll tax rates. Raising the taxable wage base increases the ",
  "per-worker tax liability for each separation, making layoffs more expensive---especially ",
  "for workers earning below the new threshold. ",
  "\\textbf{Outcome definition:} Log quarterly separations and log quarterly employment from ",
  "Census Quarterly Workforce Indicators (QWI) at the state-industry-quarter level. ",
  "\\textbf{Treatment:} Binary indicator for state having raised its UI taxable wage base ",
  "above the \\$7,000 federal minimum by more than \\$3,000. ",
  "\\textbf{Data:} Census QWI, 2001Q1--2023Q4, state-industry-quarter level. ",
  "\\textbf{Method:} Two-way fixed effects DiD and triple-difference with state, quarter, ",
  "and industry fixed effects; state-clustered standard errors. ",
  "\\textbf{Sample:} States that raised wage bases vs.\\ states at federal minimum; ",
  "low-wage industries (retail, food) vs.\\ high-wage industries (finance, professional). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is pre-treatment SD. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), ",
  "Null ($< 0.005$).\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("SDE table written.\n\nAll tables generated.\n")
