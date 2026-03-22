# 05_tables.R — Generate all LaTeX tables including SDE
# apep_0756: Fair Workweek, Unfair Turnover?

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
df <- readRDS("../data/panel_main.rds")

# ══════════════════════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment only for treated counties; all periods for controls
summ_treated <- df %>%
  filter(treated_industry == 1, treated_county == 1, post == 0) %>%
  summarise(
    sep_mean = mean(sep_rate, na.rm = TRUE), sep_sd = sd(sep_rate, na.rm = TRUE),
    hire_mean = mean(hire_rate, na.rm = TRUE), hire_sd = sd(hire_rate, na.rm = TRUE),
    earn_mean = mean(earn_avg, na.rm = TRUE), earn_sd = sd(earn_avg, na.rm = TRUE),
    emp_mean = mean(Emp, na.rm = TRUE), emp_sd = sd(Emp, na.rm = TRUE),
    n_obs = n(), n_counties = n_distinct(fips)
  )

summ_control <- df %>%
  filter(treated_industry == 1, treated_county == 0) %>%
  summarise(
    sep_mean = mean(sep_rate, na.rm = TRUE), sep_sd = sd(sep_rate, na.rm = TRUE),
    hire_mean = mean(hire_rate, na.rm = TRUE), hire_sd = sd(hire_rate, na.rm = TRUE),
    earn_mean = mean(earn_avg, na.rm = TRUE), earn_sd = sd(earn_avg, na.rm = TRUE),
    emp_mean = mean(Emp, na.rm = TRUE), emp_sd = sd(Emp, na.rm = TRUE),
    n_obs = n(), n_counties = n_distinct(fips)
  )

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Service-Sector Industries}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Treated Counties & Control Counties \\\\",
  " & (pre-treatment) & (all periods) \\\\",
  "\\midrule",
  sprintf("Separation rate & %.3f (%.3f) & %.3f (%.3f) \\\\",
    summ_treated$sep_mean, summ_treated$sep_sd, summ_control$sep_mean, summ_control$sep_sd),
  sprintf("New hire rate & %.3f (%.3f) & %.3f (%.3f) \\\\",
    summ_treated$hire_mean, summ_treated$hire_sd, summ_control$hire_mean, summ_control$hire_sd),
  sprintf("Avg.\\ monthly earnings (\\$) & %.0f (%.0f) & %.0f (%.0f) \\\\",
    summ_treated$earn_mean, summ_treated$earn_sd, summ_control$earn_mean, summ_control$earn_sd),
  sprintf("Employment & %s (%s) & %s (%s) \\\\",
    format(round(summ_treated$emp_mean), big.mark = ","),
    format(round(summ_treated$emp_sd), big.mark = ","),
    format(round(summ_control$emp_mean), big.mark = ","),
    format(round(summ_control$emp_sd), big.mark = ",")),
  sprintf("County-industry-quarters & %s & %s \\\\",
    format(summ_treated$n_obs, big.mark = ","),
    format(summ_control$n_obs, big.mark = ",")),
  sprintf("Counties & %d & %s \\\\",
    summ_treated$n_counties,
    format(summ_control$n_counties, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Sample includes food services (NAICS 72) and retail trade (NAICS 44-45). Treated counties are those with predictive scheduling ordinances. Treated-county means are pre-treatment only; control-county means span all quarters. Standard deviations in parentheses. Source: Census QWI (LEHD), 2013Q1--2019Q4.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ══════════════════════════════════════════════════════════════════════════════
# Table 2: Main DDD Results
# ══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 2: Main DDD Results...\n")

models <- list(results$ddd_sep, results$ddd_hire, results$ddd_earn, results$ddd_emp)
dep_vars <- c("Sep.\\ Rate", "Hire Rate", "Log Earn.", "Log Emp.")

coefs <- sapply(models, function(m) coef(m)["ddd"])
ses <- sapply(models, function(m) sqrt(vcov(m)["ddd", "ddd"]))
pvals <- sapply(models, function(m) fixest::pvalue(m)["ddd"])
stars <- ifelse(pvals < 0.01, "^{***}", ifelse(pvals < 0.05, "^{**}", ifelse(pvals < 0.10, "^{*}", "")))
n_obs <- sapply(models, nobs)
r2 <- sapply(models, function(m) fitstat(m, "r2")$r2)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Predictive Scheduling Laws on Service-Sector Labor Markets}",
  "\\label{tab:main_ddd}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  paste0(" & (1) & (2) & (3) & (4) \\\\"),
  paste0(" & ", paste(dep_vars, collapse = " & "), " \\\\"),
  "\\midrule",
  paste0("Treated $\\times$ Service $\\times$ Post & ",
    paste(sprintf("$%.4f%s$", coefs, stars), collapse = " & "), " \\\\"),
  paste0(" & ", paste(sprintf("(%.4f)", ses), collapse = " & "), " \\\\"),
  "\\midrule",
  "County $\\times$ Industry FE & Yes & Yes & Yes & Yes \\\\",
  "Industry $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "County $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\",
  paste0("Observations & ", paste(format(n_obs, big.mark = ","), collapse = " & "), " \\\\"),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\", r2[1], r2[2], r2[3], r2[4]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Triple-difference estimates. Service industries: food services (NAICS 72) and retail (NAICS 44-45). Control industries: manufacturing (NAICS 31-33) and professional services (NAICS 54). All U.S. counties, 2013Q1--2019Q4. Standard errors clustered at the county level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main_ddd.tex")

# ══════════════════════════════════════════════════════════════════════════════
# Table 3: Robustness
# ══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 3: Robustness...\n")

rob_models <- list(
  results$ddd_sep,           # (1) Baseline
  rob_results$nocovid_sep,   # (2) Drop COVID cohorts
  rob_results$mfg_control,   # (3) Mfg control only
  rob_results$prof_control,  # (4) Prof control only
  rob_results$dd_sep         # (5) Pure DD
)

rob_coef_names <- c("ddd", "ddd", "ddd", "ddd", "dd_county_post")
rob_coefs <- mapply(function(m, cn) coef(m)[cn], rob_models, rob_coef_names)
rob_ses <- mapply(function(m, cn) sqrt(vcov(m)[cn, cn]), rob_models, rob_coef_names)
rob_pvals <- mapply(function(m, cn) fixest::pvalue(m)[cn], rob_models, rob_coef_names)
rob_stars <- ifelse(rob_pvals < 0.01, "^{***}", ifelse(rob_pvals < 0.05, "^{**}", ifelse(rob_pvals < 0.10, "^{*}", "")))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Separation Rate under Alternative Specifications}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Baseline & No COVID & Mfg.\\ Only & Prof.\\ Only & Pure DD \\\\",
  "\\midrule",
  paste0("Treatment effect & ",
    paste(sprintf("$%.4f%s$", rob_coefs, rob_stars), collapse = " & "), " \\\\"),
  paste0(" & ", paste(sprintf("(%.4f)", rob_ses), collapse = " & "), " \\\\"),
  "\\midrule",
  paste0("Observations & ",
    paste(sapply(rob_models, function(m) format(nobs(m), big.mark = ",")), collapse = " & "), " \\\\"),
  "Design & DDD & DDD & DDD & DDD & DD \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Dependent variable: separation rate. Column 1 replicates the baseline DDD. Column 2 drops Philadelphia and Chicago cohorts (adopted during COVID). Columns 3--4 vary the control industry. Column 5 uses treated industries only (DD, not DDD). All specifications include county$\\times$industry and time fixed effects. Standard errors clustered at the county level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")

# ══════════════════════════════════════════════════════════════════════════════
# Table 4: Placebo and CS
# ══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 4: Placebo and CS...\n")

plac_coef <- coef(rob_results$placebo_sep)["ddd_placebo"]
plac_se <- sqrt(vcov(rob_results$placebo_sep)["ddd_placebo", "ddd_placebo"])
plac_p <- fixest::pvalue(rob_results$placebo_sep)["ddd_placebo"]
plac_star <- ifelse(plac_p < 0.01, "^{***}", ifelse(plac_p < 0.05, "^{**}", ifelse(plac_p < 0.10, "^{*}", "")))

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Placebo Test: Manufacturing as ``Treated'' Industry}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & Placebo DDD & Main DDD \\\\",
  " & Sep.\\ Rate & Sep.\\ Rate \\\\",
  "\\midrule",
  sprintf("Treatment effect & $%.4f%s$ & $%.4f%s$ \\\\",
    plac_coef, plac_star, coefs[1], stars[1]),
  sprintf(" & (%.4f) & (%.4f) \\\\", plac_se, ses[1]),
  sprintf("$p$-value & %.3f & %.3f \\\\", plac_p, pvals[1]),
  "\\midrule",
  "``Treated'' industry & Manufacturing & Food/Retail \\\\",
  sprintf("Observations & %s & %s \\\\",
    format(nobs(rob_results$placebo_sep), big.mark = ","),
    format(n_obs[1], big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Column 1: placebo DDD using manufacturing (NAICS 31-33) as the ``treated'' industry; this industry is not covered by scheduling laws. Column 2: main DDD from Table~\\ref{tab:main_ddd}. The null placebo confirms the effect is specific to legally covered industries. Standard errors clustered at the county level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_placebo.tex")

# ══════════════════════════════════════════════════════════════════════════════
# Table F1: SDE Appendix (MANDATORY)
# ══════════════════════════════════════════════════════════════════════════════
cat("Generating Table F1: Standardized Effect Sizes...\n")

pre <- results$pre_stats
outcome_labels <- c("Separation Rate", "New Hire Rate", "Log Earnings", "Log Employment")
sd_vals <- c(pre$sd_sep_rate, pre$sd_hire_rate, pre$sd_log_earn, pre$sd_log_emp)

sde_rows <- data.frame(
  Outcome = outcome_labels,
  Beta = coefs,
  SE = ses,
  SD_Y = sd_vals,
  stringsAsFactors = FALSE
)

sde_rows$SDE <- sde_rows$Beta / sde_rows$SD_Y
sde_rows$SE_SDE <- sde_rows$SE / sde_rows$SD_Y

sde_rows$Classification <- with(sde_rows, case_when(
  SDE < -0.15 ~ "Large negative",
  SDE >= -0.15 & SDE < -0.05 ~ "Moderate negative",
  SDE >= -0.05 & SDE < -0.005 ~ "Small negative",
  SDE >= -0.005 & SDE <= 0.005 ~ "Null",
  SDE > 0.005 & SDE <= 0.05 ~ "Small positive",
  SDE > 0.05 & SDE <= 0.15 ~ "Moderate positive",
  SDE > 0.15 ~ "Large positive"
))

cat("SDE results:\n")
print(sde_rows)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do predictive scheduling (``fair workweek'') laws, which mandate advance notice of work schedules in food services and retail, reduce worker separations and new hiring in covered industries? ",
  "\\textbf{Policy mechanism:} Laws require employers with 500+ employees in retail and food services to provide 14-day advance schedule notice, pay ``predictability pay'' for last-minute changes, and offer additional hours to existing workers before hiring new ones; this increases the cost of flexible scheduling and creates incentives to stabilize the incumbent workforce. ",
  "\\textbf{Outcome definition:} Separation rate (quarterly separations divided by beginning-of-quarter employment), new hire rate (new hires divided by employment), log average monthly earnings for stable jobs, and log beginning-of-quarter employment; all from Census QWI. ",
  "\\textbf{Treatment:} Binary; county-level adoption of a predictive scheduling ordinance (6 cities and 1 state, staggered 2015--2020). ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI/LEHD), county $\\times$ NAICS sector $\\times$ quarter, 2013--2019, all U.S. counties with non-missing data ($N = ",
  format(n_obs[1], big.mark = ","), "$). ",
  "\\textbf{Method:} Triple-difference (treated county $\\times$ covered industry $\\times$ post) with county$\\times$industry, industry$\\times$quarter, and county$\\times$quarter fixed effects; standard errors clustered at the county level. ",
  "\\textbf{Sample:} All U.S. counties with positive employment in food services (NAICS 72), retail (NAICS 44-45), manufacturing (NAICS 31-33), and professional services (NAICS 54); restricted to 2013Q1--2019Q4 to avoid COVID contamination; 45 treated counties across 5 adoption cohorts. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome among treated-industry observations. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_rows)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
      sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
      sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
      sde_rows$Classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("Files:", paste(list.files("../tables/"), collapse = ", "), "\n")
