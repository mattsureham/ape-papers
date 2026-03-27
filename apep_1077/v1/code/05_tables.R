# 05_tables.R — Generate all tables for paper
# apep_1077: Child Labor Law Rollbacks DDD

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
load("../data/main_results.RData")
load("../data/robustness_results.RData")

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics\n")

sumstats <- panel[, .(
  mean_emp = mean(emp, na.rm = TRUE),
  sd_emp = sd(emp, na.rm = TRUE),
  mean_hires = mean(hires, na.rm = TRUE),
  sd_hires = sd(hires, na.rm = TRUE),
  mean_sep_rate = mean(sep_rate, na.rm = TRUE),
  sd_sep_rate = sd(sep_rate, na.rm = TRUE),
  mean_earnings = mean(earnings, na.rm = TRUE),
  sd_earnings = sd(earnings, na.rm = TRUE),
  n_state_qtrs = .N
), by = .(teen, food_retail)]

sumstats[, group := fcase(
  teen == 1 & food_retail == 1, "Teens, Food/Retail",
  teen == 1 & food_retail == 0, "Teens, Professional",
  teen == 0 & food_retail == 1, "Young Adults, Food/Retail",
  teen == 0 & food_retail == 0, "Young Adults, Professional"
)]

# Format for LaTeX
fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: State-Quarter Employment by Age Group and Industry}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Hires} & Sep.\\ Rate & Earnings \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD & Mean & Mean \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sumstats)) {
  row <- sumstats[i]
  tab1 <- paste0(tab1,
    row$group, " & ",
    fmt(row$mean_emp), " & ",
    fmt(row$sd_emp), " & ",
    fmt(row$mean_hires), " & ",
    fmt(row$sd_hires), " & ",
    fmt(row$mean_sep_rate, 3), " & ",
    fmt(row$mean_earnings, 0), " \\\\\n"
  )
}

# Add treated vs control summary
treat_sum <- panel[food_retail == 1 & teen == 1, .(
  mean_emp_treat = mean(emp[treated_state == 1], na.rm = TRUE),
  mean_emp_ctrl = mean(emp[treated_state == 0], na.rm = TRUE),
  n_treated = uniqueN(state_fips[treated_state == 1]),
  n_control = uniqueN(state_fips[treated_state == 0])
)]

tab1 <- paste0(tab1,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Teen food/retail employment, by treatment status:}} \\\\\n",
  "Rollback states ($N = ", treat_sum$n_treated, "$) & ",
  fmt(treat_sum$mean_emp_treat), " & & & & & \\\\\n",
  "Control states ($N = ", treat_sum$n_control, "$) & ",
  fmt(treat_sum$mean_emp_ctrl), " & & & & & \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} QWI state-quarter-industry-age cells, 2018Q1--2025Q1. ",
  "Employment is beginning-of-quarter count. Hires are all hires during the quarter. ",
  "Separation rate is separations divided by employment. Earnings are average monthly ",
  "earnings (\\$). Food/Retail includes NAICS 72 and 44--45. Professional is NAICS 54. ",
  "Teens are age 14--18 (QWI group A01); Young Adults are 19--21 (A02). ",
  "States: 12 rollback, 39 control (including DC).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")
cat("  Saved tab1_sumstats.tex\n")

# ============================================================================
# TABLE 2: Main DDD Results
# ============================================================================
cat("Generating Table 2: Main DDD Results\n")

# Extract coefficients from the four models
extract_ddd <- function(mod, coef_name = "post:teen:food_retail") {
  idx <- grep(coef_name, names(coef(mod)), fixed = TRUE)
  if (length(idx) == 0) return(list(beta = NA, se = NA, pval = NA))
  list(
    beta = coef(mod)[idx],
    se = se(mod)[idx],
    pval = pvalue(mod)[idx]
  )
}

r1 <- extract_ddd(m1_emp)
r2 <- extract_ddd(m2_sep)
r3 <- extract_ddd(m3_hires)
r4 <- extract_ddd(m4_earn)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

fmtc <- function(x, d = 4) {
  if (is.na(x)) return("---")
  formatC(x, format = "f", digits = d)
}

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{The Protection Illusion: Triple-Difference Estimates of Child Labor Law Rollbacks}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Log Emp & Sep.\\ Rate & Log Hires & Log Earnings \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "Post $\\times$ Teen $\\times$ Food/Retail & ",
  fmtc(r1$beta), stars(r1$pval), " & ",
  fmtc(r2$beta), stars(r2$pval), " & ",
  fmtc(r3$beta), stars(r3$pval), " & ",
  fmtc(r4$beta), stars(r4$pval), " \\\\\n",
  " & (", fmtc(r1$se), ") & (", fmtc(r2$se), ") & (", fmtc(r3$se), ") & (", fmtc(r4$se), ") \\\\\n",
  "\\midrule\n",
  "State $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "Industry $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "Age $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "State $\\times$ Industry $\\times$ Age FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", fmt(nobs(m1_emp)), " & ", fmt(nobs(m2_sep)), " & ",
  fmt(nobs(m3_hires)), " & ", fmt(nobs(m4_earn)), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each column reports the triple-difference coefficient ",
  "$\\hat{\\beta}$ from $Y_{siat} = \\beta \\cdot \\text{Post}_{st} \\times \\text{Teen}_a ",
  "\\times \\text{FoodRetail}_i + \\text{FE} + \\varepsilon$. The coefficient measures ",
  "the differential change in teen employment in food services and retail (relative to ",
  "young adults in professional services) in rollback states after law weakening. ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("  Saved tab2_main.tex\n")

# ============================================================================
# TABLE 3: Robustness
# ============================================================================
cat("Generating Table 3: Robustness\n")

# Extract robustness coefficients
r_excl <- extract_ddd(m_excl_covid)
r_dose <- list(
  beta = coef(m_dose)["dose"],
  se = se(m_dose)["dose"],
  pval = pvalue(m_dose)["dose"]
)
r_placebo <- list(
  beta = coef(m_placebo)["post:food_retail"],
  se = se(m_placebo)["post:food_retail"],
  pval = pvalue(m_placebo)["post:food_retail"]
)

# Randomization inference p-value
boot_pval <- if (!is.null(boot_result)) fmtc(boot_result$p_val, 3) else "---"

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Baseline & Excl.\\ NH/NJ & Dose-Response & Placebo (25--34) \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "DDD: Post $\\times$ Teen $\\times$ Food/Retail & ",
  fmtc(r1$beta), stars(r1$pval), " & ",
  fmtc(r_excl$beta), stars(r_excl$pval), " & & \\\\\n",
  " & (", fmtc(r1$se), ") & (", fmtc(r_excl$se), ") & & \\\\\n",
  "[0.5em]\n",
  "Dose: Post $\\times$ Teen $\\times$ Food/Retail $\\times$ Provisions & & & ",
  fmtc(r_dose$beta), stars(r_dose$pval), " & \\\\\n",
  " & & & (", fmtc(r_dose$se), ") & \\\\\n",
  "[0.5em]\n",
  "DD: Post $\\times$ Food/Retail (adults 25--34) & & & & ",
  fmtc(r_placebo$beta), stars(r_placebo$pval), " \\\\\n",
  " & & & & (", fmtc(r_placebo$se), ") \\\\\n",
  "\\midrule\n",
  "Randomization inference $p$-value & ", boot_pval, " & & & \\\\\n",
  "Observations & ", fmt(nobs(m1_emp)), " & ", fmt(nobs(m_excl_covid)), " & ",
  fmt(nobs(m_dose)), " & ", fmt(nobs(m_placebo)), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column (1) reproduces the baseline DDD from Table~\\ref{tab:main}. ",
  "Column (2) excludes New Hampshire and New Jersey, which adopted rollbacks during ",
  "COVID-19 recovery. Column (3) replaces the binary DDD interaction with a continuous ",
  "dose measure (number of provisions weakened: 1--3). Column (4) is a placebo test ",
  "using adults aged 25--34 (QWI group A04) instead of teens; the DD (Post $\\times$ ",
  "Food/Retail) should be zero if rollbacks specifically affect the teen margin. ",
  "Randomization inference permutes treatment assignment across states 999 times. ",
  "Standard errors clustered at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robust.tex")
cat("  Saved tab3_robust.tex\n")

# ============================================================================
# TABLE 4: Event Study Coefficients
# ============================================================================
cat("Generating Table 4: Event Study\n")

es_ct <- coeftable(es_ddd)
es_names <- rownames(es_ct)
# Parse relative time from coefficient names
rel_times <- as.integer(gsub(".*::(-?\\d+):.*", "\\1", es_names))

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: DDD Coefficients by Relative Quarter}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Relative Quarter & Coefficient & SE \\\\\n",
  "\\midrule\n"
)

for (i in order(rel_times)) {
  rt <- rel_times[i]
  if (rt == -1) {
    tab4 <- paste0(tab4, rt, " (ref.) & 0 & --- \\\\\n")
  } else {
    tab4 <- paste0(tab4,
      rt, " & ", fmtc(es_ct[i, "Estimate"]), stars(es_ct[i, "Pr(>|t|)"]),
      " & (", fmtc(es_ct[i, "Std. Error"]), ") \\\\\n")
  }
}

tab4 <- paste0(tab4,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Coefficients from the DDD event study on treated states only. ",
  "Each coefficient is the interaction of a relative-quarter indicator with ",
  "Teen $\\times$ Food/Retail. Reference period: quarter $-1$. Relative quarters ",
  "beyond $\\pm 8$ are binned. Standard errors clustered at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_eventstudy.tex")
cat("  Saved tab4_eventstudy.tex\n")

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ============================================================================
cat("Generating Table F1: SDE\n")

# Pre-treatment SD of outcomes (pre = before any state's rollback, i.e., before 2022Q1)
pre_data <- panel[yq < 2022.0 & food_retail == 1 & teen == 1]
sd_log_emp_pre <- sd(pre_data$log_emp, na.rm = TRUE)
sd_sep_rate_pre <- sd(pre_data$sep_rate, na.rm = TRUE)
sd_log_hires_pre <- sd(log(pre_data$hires + 1), na.rm = TRUE)
sd_log_earn_pre <- sd(log(pre_data$earnings + 1), na.rm = TRUE)

# For adults in food/retail (heterogeneity panel)
pre_adult <- panel[yq < 2022.0 & food_retail == 1 & teen == 0]
sd_log_emp_adult <- sd(pre_adult$log_emp, na.rm = TRUE)

# DDD approach: treatment is binary, so SDE = beta / SD(Y)
compute_sde <- function(beta, se_beta, sd_y) {
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  classify <- function(s) {
    if (is.na(s)) return("---")
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    if (s < -0.005) return("Small negative")
    if (s <= 0.005) return("Null")
    if (s <= 0.05) return("Small positive")
    if (s <= 0.15) return("Moderate positive")
    return("Large positive")
  }
  list(sde = sde, se_sde = se_sde, class = classify(sde))
}

sde1 <- compute_sde(r1$beta, r1$se, sd_log_emp_pre)
sde2 <- compute_sde(r2$beta, r2$se, sd_sep_rate_pre)
sde3 <- compute_sde(r3$beta, r3$se, sd_log_hires_pre)
sde4 <- compute_sde(r4$beta, r4$se, sd_log_earn_pre)

# Heterogeneity: strong rollback states (IA, AR, FL, IN, OH) vs weak (rest)
panel[, strong_rollback := as.integer(state_abbr %in% c("IA", "AR", "FL", "IN", "OH"))]

m_strong <- feols(
  log_emp ~ post:teen:food_retail + post:teen + post:food_retail + teen:food_retail |
    state_fips^time_period + industry^time_period + agegrp^time_period +
    state_fips^industry^agegrp,
  data = panel[strong_rollback == 1 | treated_state == 0],
  cluster = ~state_fips
)

m_weak <- feols(
  log_emp ~ post:teen:food_retail + post:teen + post:food_retail + teen:food_retail |
    state_fips^time_period + industry^time_period + agegrp^time_period +
    state_fips^industry^agegrp,
  data = panel[strong_rollback == 0],
  cluster = ~state_fips
)

r_strong <- extract_ddd(m_strong)
r_weak <- extract_ddd(m_weak)
sde_strong <- compute_sde(r_strong$beta, r_strong$se, sd_log_emp_pre)
sde_weak <- compute_sde(r_weak$beta, r_weak$se, sd_log_emp_pre)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether state-level rollbacks of child labor protections ",
  "(extending hours, eliminating permits, lowering age floors) increase teenage employment in food services and retail. ",
  "\\textbf{Policy mechanism:} Twelve states (2022--2024) weakened child labor laws by relaxing hour ",
  "limits for minors, eliminating parental work-permit requirements, or lowering minimum working ages, ",
  "thereby reducing legal barriers to teenage employment in service-sector industries. ",
  "\\textbf{Outcome definition:} Log beginning-of-quarter employment count from QWI, measuring the stock ",
  "of employed teenagers aged 14--18 in food services (NAICS 72) and retail (NAICS 44--45). ",
  "\\textbf{Treatment:} Binary; coded as 1 from the quarter the rollback law took effect. ",
  "\\textbf{Data:} Census QWI (Quarterly Workforce Indicators), 2018Q1--2025Q1, state-quarter-industry-age cells, ",
  "51 states (12 treated, 39 control), 3 industries, 2 age groups. ",
  "\\textbf{Method:} Triple-difference (state $\\times$ industry $\\times$ age group) with state$\\times$quarter, ",
  "industry$\\times$quarter, age$\\times$quarter, and state$\\times$industry$\\times$age fixed effects; ",
  "standard errors clustered at the state level. ",
  "\\textbf{Sample:} All U.S. states with non-suppressed QWI data for teens and young adults ",
  "in food services, retail, and professional services. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Log employment & ", fmtc(r1$beta), " & ", fmtc(r1$se), " & ",
  fmtc(sd_log_emp_pre, 3), " & ", fmtc(sde1$sde), " & ", fmtc(sde1$se_sde), " & ",
  sde1$class, " \\\\\n",
  "Separation rate & ", fmtc(r2$beta), " & ", fmtc(r2$se), " & ",
  fmtc(sd_sep_rate_pre, 3), " & ", fmtc(sde2$sde), " & ", fmtc(sde2$se_sde), " & ",
  sde2$class, " \\\\\n",
  "Log hires & ", fmtc(r3$beta), " & ", fmtc(r3$se), " & ",
  fmtc(sd_log_hires_pre, 3), " & ", fmtc(sde3$sde), " & ", fmtc(sde3$se_sde), " & ",
  sde3$class, " \\\\\n",
  "Log earnings & ", fmtc(r4$beta), " & ", fmtc(r4$se), " & ",
  fmtc(sd_log_earn_pre, 3), " & ", fmtc(sde4$sde), " & ", fmtc(sde4$se_sde), " & ",
  sde4$class, " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (log employment, sample splits)}} \\\\\n",
  "Strong rollbacks (3+ provisions) & ", fmtc(r_strong$beta), " & ",
  fmtc(r_strong$se), " & ", fmtc(sd_log_emp_pre, 3), " & ",
  fmtc(sde_strong$sde), " & ", fmtc(sde_strong$se_sde), " & ",
  sde_strong$class, " \\\\\n",
  "Weak rollbacks (1 provision) & ", fmtc(r_weak$beta), " & ",
  fmtc(r_weak$se), " & ", fmtc(sd_log_emp_pre, 3), " & ",
  fmtc(sde_weak$sde), " & ", fmtc(sde_weak$se_sde), " & ",
  sde_weak$class, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("  Saved tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
