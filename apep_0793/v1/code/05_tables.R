## 05_tables.R — Generate all LaTeX tables
## apep_0793: The Innovation Supply Chain

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
models <- readRDS("../data/models.rds")
rob_models <- readRDS("../data/rob_models.rds")

dir.create("../tables", showWarnings = FALSE)

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
cat("Generating Table 1: Summary Statistics...\n")

sum_vars <- panel %>%
  summarise(
    across(c(stem_completions, emp, earn_s, hir_all, firm_job_gain, firm_job_loss,
             emp_food, earn_food, ba_plus_share, skill_premium),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE),
                min = ~min(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE),
                n = ~sum(!is.na(.x))),
           .names = "{.col}__{.fn}")
  ) %>%
  pivot_longer(everything()) %>%
  separate(name, into = c("variable", "stat"), sep = "__") %>%
  pivot_wider(names_from = stat, values_from = value)

# Format for LaTeX
var_labels <- c(
  stem_completions = "STEM completions (CS + Eng.)",
  emp = "Info sector employment",
  earn_s = "Info sector avg. earnings (\\$)",
  hir_all = "Info sector annual hires",
  firm_job_gain = "Info sector firm job gains",
  firm_job_loss = "Info sector firm job losses",
  emp_food = "Food sector employment",
  earn_food = "Food sector avg. earnings (\\$)",
  ba_plus_share = "BA+ share in Info sector",
  skill_premium = "Skill premium (BA/Some college)"
)

tab1_rows <- sum_vars %>%
  mutate(label = var_labels[variable]) %>%
  filter(!is.na(label)) %>%
  mutate(row = sprintf("  %s & %s & %s & %s & %s \\\\",
                        label,
                        formatC(mean, format = "f", digits = 1, big.mark = ","),
                        formatC(sd, format = "f", digits = 1, big.mark = ","),
                        formatC(min, format = "f", digits = 1, big.mark = ","),
                        formatC(max, format = "f", digits = 0, big.mark = ",")))

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & Std.\\ Dev. & Min & Max \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: STEM Supply (County-Year)}} \\\\\n",
  tab1_rows$row[1], "\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Information Sector Outcomes}} \\\\\n",
  paste(tab1_rows$row[2:6], collapse = "\n"), "\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo Sector (Accommodation/Food)}} \\\\\n",
  paste(tab1_rows$row[7:8], collapse = "\n"), "\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel D: Skill Composition}} \\\\\n",
  paste(tab1_rows$row[9:10], collapse = "\n"), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sprintf("\\item \\textit{Notes:} N = %s county-year observations across %d counties and %d years (2009--2022). ",
          formatC(nrow(panel), big.mark = ","),
          n_distinct(panel$county_fips),
          n_distinct(panel$year)),
  "STEM completions are annual CS (CIP 11) and Engineering (CIP 14) bachelor's and master's degrees from IPEDS. ",
  "Information sector (NAICS 51) outcomes are from the Quarterly Workforce Indicators, annualized. ",
  "Skill premium is the ratio of BA-holder to some-college earnings within the Information sector.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ===========================================================================
# Table 2: First Stage and Reduced Form
# ===========================================================================
cat("Generating Table 2: First Stage and Reduced Form...\n")

fs <- models$fs
rf_emp <- models$rf_emp
rf_earn <- models$rf_earn

fs_coef <- coeftable(fs)
rf_emp_coef <- coeftable(rf_emp)
rf_earn_coef <- coeftable(rf_earn)

fmt_coef <- function(est, se, stars) {
  sprintf("%s%s \\\\\n  & (%s)",
          formatC(est, format = "f", digits = 3),
          stars,
          formatC(se, format = "f", digits = 3))
}

get_stars <- function(p) {
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{First Stage and Reduced Form}\n",
  "\\label{tab:first_stage}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Log STEM & Log Info & Log Info \\\\\n",
  " & Completions & Employment & Earnings \\\\\n",
  "\\midrule\n",
  sprintf("Bartik IV & %s & %s & %s \\\\\n",
          fmt_coef(fs_coef[1,1], fs_coef[1,2], get_stars(fs_coef[1,4])),
          fmt_coef(rf_emp_coef[1,1], rf_emp_coef[1,2], get_stars(rf_emp_coef[1,4])),
          fmt_coef(rf_earn_coef[1,1], rf_earn_coef[1,2], get_stars(rf_earn_coef[1,4]))),
  "\\addlinespace\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          formatC(nobs(fs), big.mark = ","),
          formatC(nobs(rf_emp), big.mark = ","),
          formatC(nobs(rf_earn), big.mark = ",")),
  sprintf("Effective F & %.1f & --- & --- \\\\\n", coeftable(fs)[1,3]^2),
  "County FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "The Bartik IV is the product of the county's 2009 share of national CS+Engineering completions ",
  "and the national growth rate of CS+Engineering completions. ",
  "Column (1) is the first stage; columns (2)--(3) are reduced-form effects on Information sector outcomes. ",
  "The effective F-statistic for the first stage is the squared t-statistic from column (1).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_first_stage.tex")

# ===========================================================================
# Table 3: Main 2SLS Results
# ===========================================================================
cat("Generating Table 3: Main 2SLS Results...\n")

make_iv_row <- function(model, varname = "fit_log_stem") {
  ct <- coeftable(model)
  est <- ct[varname, 1]
  se <- ct[varname, 2]
  p <- ct[varname, 4]
  stars <- get_stars(p)
  list(est = est, se = se, stars = stars, n = nobs(model))
}

iv_emp <- make_iv_row(models$iv_emp)
iv_earn <- make_iv_row(models$iv_earn)
iv_hir <- make_iv_row(models$iv_hir)
iv_fjg <- make_iv_row(models$iv_fjg)
iv_fjl <- make_iv_row(models$iv_fjl)

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of STEM Expansion on Information Sector Outcomes (2SLS)}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Log & Log & Log & Firm Job & Firm Job \\\\\n",
  " & Employment & Earnings & Hires & Gain Rate & Loss Rate \\\\\n",
  "\\midrule\n",
  sprintf("Log STEM completions & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          iv_emp$est, iv_emp$stars,
          iv_earn$est, iv_earn$stars,
          iv_hir$est, iv_hir$stars,
          iv_fjg$est, iv_fjg$stars,
          iv_fjl$est, iv_fjl$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          iv_emp$se, iv_earn$se, iv_hir$se, iv_fjg$se, iv_fjl$se),
  "\\addlinespace\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          formatC(iv_emp$n, big.mark = ","),
          formatC(iv_earn$n, big.mark = ","),
          formatC(iv_hir$n, big.mark = ","),
          formatC(iv_fjg$n, big.mark = ","),
          formatC(iv_fjl$n, big.mark = ",")),
  "First-stage F & \\multicolumn{5}{c}{6.4} \\\\\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} 2SLS estimates. Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Log STEM completions is instrumented using the Bartik IV (2009 county share $\\times$ national growth). ",
  "Firm job gain and loss rates are annual gains (losses) divided by average employment. ",
  "All specifications include county and year fixed effects.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_main.tex")

# ===========================================================================
# Table 4: Skill Composition
# ===========================================================================
cat("Generating Table 4: Skill Composition...\n")

iv_ba_r <- make_iv_row(models$iv_ba)
iv_sp_r <- make_iv_row(models$iv_sp)

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of STEM Expansion on Information Sector Skill Composition (2SLS)}\n",
  "\\label{tab:skill}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & BA+ Share & Log Skill Premium \\\\\n",
  "\\midrule\n",
  sprintf("Log STEM completions & %.3f%s & %.3f%s \\\\\n",
          iv_ba_r$est, iv_ba_r$stars,
          iv_sp_r$est, iv_sp_r$stars),
  sprintf(" & (%.3f) & (%.3f) \\\\\n", iv_ba_r$se, iv_sp_r$se),
  "\\addlinespace\n",
  sprintf("Observations & %s & %s \\\\\n",
          formatC(iv_ba_r$n, big.mark = ","), formatC(iv_sp_r$n, big.mark = ",")),
  "County FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} 2SLS estimates. Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "BA+ Share is the fraction of Information sector workers with a bachelor's degree or higher from QWI education breakdowns. ",
  "The skill premium is the ratio of BA-holder to some-college average quarterly earnings. ",
  "Log STEM completions instrumented with the Bartik IV.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_skill.tex")

# ===========================================================================
# Table 5: Robustness
# ===========================================================================
cat("Generating Table 5: Robustness...\n")

placebo_r <- make_iv_row(rob_models$placebo_emp)
loo_r <- make_iv_row(rob_models$iv_loo)
nosup_r <- make_iv_row(rob_models$iv_no_super)

tab5_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Baseline & Placebo & Leave-One- & Excl.\\ Top & OLS \\\\\n",
  " & 2SLS & (Food Sec.) & Out Bartik & 5\\% & \\\\\n",
  "\\midrule\n",
  sprintf("Log STEM & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          iv_emp$est, iv_emp$stars,
          placebo_r$est, placebo_r$stars,
          loo_r$est, loo_r$stars,
          nosup_r$est, nosup_r$stars,
          coeftable(models$ols_emp)[1,1], get_stars(coeftable(models$ols_emp)[1,4])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          iv_emp$se, placebo_r$se, loo_r$se, nosup_r$se,
          coeftable(models$ols_emp)[1,2]),
  "\\addlinespace\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          formatC(iv_emp$n, big.mark = ","),
          formatC(placebo_r$n, big.mark = ","),
          formatC(loo_r$n, big.mark = ","),
          formatC(nosup_r$n, big.mark = ","),
          formatC(nobs(models$ols_emp), big.mark = ",")),
  "Dep.\\ Var. & Log Info Emp & Log Food Emp & Log Info Emp & Log Info Emp & Log Info Emp \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) reproduces the baseline 2SLS from Table \\ref{tab:main}. ",
  "Column (2) replaces the dependent variable with log Accommodation/Food employment (placebo). ",
  "Column (3) uses a leave-one-out Bartik IV that excludes own-state completions from the national shift. ",
  "Column (4) drops the top 5\\% of counties by baseline STEM share. ",
  "Column (5) is the OLS estimate without instrumentation. ",
  "All columns include county and year FE; SEs clustered at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, "../tables/tab5_robust.tex")

# ===========================================================================
# SDE Table (Appendix — Mandatory)
# ===========================================================================
cat("Generating SDE Table...\n")

# Main outcomes from 2SLS
outcomes <- list(
  list(name = "Info Sector Employment", model = models$iv_emp,
       var = "log_emp", outcome_col = "log_emp", treatment = "log_stem"),
  list(name = "Info Sector Earnings", model = models$iv_earn,
       var = "log_earn", outcome_col = "log_earn", treatment = "log_stem"),
  list(name = "Info Sector Hires", model = models$iv_hir,
       var = "log_hir", outcome_col = "log_hir", treatment = "log_stem"),
  list(name = "BA+ Share", model = models$iv_ba,
       var = "ba_plus_share", outcome_col = "ba_plus_share", treatment = "log_stem")
)

classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_rows <- lapply(outcomes, function(o) {
  ct <- coeftable(o$model)
  beta <- ct["fit_log_stem", 1]
  se_beta <- ct["fit_log_stem", 2]
  sd_y <- sd(panel[[o$var]], na.rm = TRUE)
  sd_x <- sd(panel[["log_stem"]], na.rm = TRUE)
  # Continuous treatment: SDE = beta * SD(X) / SD(Y)
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y
  tibble(
    outcome = o$name,
    beta = beta, se = se_beta,
    sd_x = sd_x, sd_y = sd_y,
    sde = sde, se_sde = se_sde,
    classification = classify_sde(sde)
  )
})

sde_df <- bind_rows(sde_rows)

# Format SDE table
sde_rows_tex <- sde_df %>%
  mutate(row = sprintf("  %s & %.3f & (%.3f) & %.2f & %.2f & %.3f & (%.3f) & %s \\\\",
                        outcome, beta, se, sd_x, sd_y, sde, se_sde, classification))

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the expansion of university CS and Engineering degree programs increase local technology sector employment, earnings, and workforce composition in U.S. counties? ",
  "\\textbf{Policy mechanism:} The doubling of CS and Engineering bachelor's and master's degree completions between 2009 and 2022, ",
  "driven by student demand shifts and institutional expansion, created county-level variation in STEM labor supply through ",
  "pre-existing university STEM capacity differences. ",
  "\\textbf{Outcome definition:} Information sector (NAICS 51) quarterly employment, average quarterly earnings, annual hires, ",
  "and BA-plus worker share from the Quarterly Workforce Indicators. ",
  "\\textbf{Treatment:} Continuous --- log county-level CS and Engineering completions (bachelor's and master's combined), instrumented via Bartik IV. ",
  "\\textbf{Data:} IPEDS completions (2009--2022) merged with QWI county-quarter panels; 723 counties, 14 years, 10,084 county-year observations. ",
  "\\textbf{Method:} 2SLS with Bartik shift-share IV (2009 county share $\\times$ national growth), county and year fixed effects, state-clustered standard errors. ",
  "\\textbf{Sample:} Counties with at least one STEM-granting institution in IPEDS and Information sector employment data in QWI for all years 2009--2022. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) and SD($Y$) are unconditional standard deviations. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  paste(sde_rows_tex$row, collapse = "\n"), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("Files: tab1_summary.tex, tab2_first_stage.tex, tab3_main.tex, tab4_skill.tex, tab5_robust.tex, tabF1_sde.tex\n")
