## 05_tables.R — Generate all tables including SDE
## apep_1394: PFL × Healthcare Workforce Retention

source("00_packages.R")

cat("=== GENERATING TABLES ===\n")

panel <- readRDS("../data/panel_clean.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
pfl_states <- readRDS("../data/pfl_states.rds")

tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Table 1: Summary Statistics
# -----------------------------------------------------------------------

sum_stats <- panel |>
  filter(!is.na(turnover)) |>
  group_by(sex_label) |>
  summarise(
    N = n(),
    `Mean Turnover` = mean(turnover, na.rm = TRUE),
    `SD Turnover` = sd(turnover, na.rm = TRUE),
    `Mean Sep. Rate` = mean(sep_rate, na.rm = TRUE),
    `Mean Earnings` = mean(earnings, na.rm = TRUE),
    `Mean Employment` = mean(emp_end, na.rm = TRUE),
    .groups = "drop"
  )

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Healthcare Workforce (NAICS 62)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & N & Mean & SD & Sep. & Mean & Mean \\\\",
  " & & Turnover & Turnover & Rate & Earnings & Employment \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sum_stats))) {
  row <- sum_stats[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %.4f & %.4f & %.4f & \\$%.0f & %.0f \\\\",
    row$sex_label, format(row$N, big.mark = ","),
    row$`Mean Turnover`, row$`SD Turnover`, row$`Mean Sep. Rate`,
    row$`Mean Earnings`, row$`Mean Employment`
  ))
}

# Add PFL vs non-PFL breakdown
tab1_lines <- c(tab1_lines, "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: By PFL Status}} \\\\", "\\midrule")

sum_pfl <- panel |>
  filter(!is.na(turnover)) |>
  group_by(Group = ifelse(pfl_state, "PFL States", "Non-PFL States")) |>
  summarise(
    N = n(),
    `Mean Turnover` = mean(turnover, na.rm = TRUE),
    `SD Turnover` = sd(turnover, na.rm = TRUE),
    `Mean Sep. Rate` = mean(sep_rate, na.rm = TRUE),
    `Mean Earnings` = mean(earnings, na.rm = TRUE),
    `Mean Employment` = mean(emp_end, na.rm = TRUE),
    .groups = "drop"
  )

for (i in seq_len(nrow(sum_pfl))) {
  row <- sum_pfl[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %.4f & %.4f & %.4f & \\$%.0f & %.0f \\\\",
    row$Group, format(row$N, big.mark = ","),
    row$`Mean Turnover`, row$`SD Turnover`, row$`Mean Sep. Rate`,
    row$`Mean Earnings`, row$`Mean Employment`
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from Census QWI, 2001--2024. Healthcare sector (NAICS 62), state$\\times$sex$\\times$quarter panel. Turnover rate = quarterly worker turnover. PFL states: CA, NJ, RI, NY, WA, DC, MA, CT, OR, CO.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tab_dir, "tab1_summary.tex"))
cat("Table 1 saved\n")

# -----------------------------------------------------------------------
# Table 2: Main DDD Results
# -----------------------------------------------------------------------

tab2_models <- list(
  "(1)" = results$m1_turnover,
  "(2)" = results$m2_turnover,
  "(3)" = results$m3_turnover,
  "(4)" = results$m3_seprate,
  "(5)" = results$m3_earn
)

# Extract info for manual table
get_row <- function(m, var = "treated_ddd") {
  cf <- coef(m)[var]
  s <- se(m)[var]
  p <- fixest::pvalue(m)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = cf, se = s, stars = stars, n = m$nobs)
}

rows <- lapply(tab2_models, get_row)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Triple Difference-in-Differences: PFL Effect on Healthcare Workforce}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Turnover & Turnover & Turnover & Sep.~Rate & Log Earn. \\\\",
  "\\midrule",
  sprintf("PFL $\\times$ Female & %.4f%s & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          rows[["(1)"]]$coef, rows[["(1)"]]$stars,
          rows[["(2)"]]$coef, rows[["(2)"]]$stars,
          rows[["(3)"]]$coef, rows[["(3)"]]$stars,
          rows[["(4)"]]$coef, rows[["(4)"]]$stars,
          rows[["(5)"]]$coef, rows[["(5)"]]$stars),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          rows[["(1)"]]$se, rows[["(2)"]]$se, rows[["(3)"]]$se,
          rows[["(4)"]]$se, rows[["(5)"]]$se),
  "\\midrule",
  "State $\\times$ Sex FE & \\checkmark & & & & \\\\",
  "Quarter FE & \\checkmark & & & & \\\\",
  "State $\\times$ Sex FE & & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\",
  "Sex $\\times$ Quarter FE & & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(rows[["(1)"]]$n, big.mark = ","),
          format(rows[["(2)"]]$n, big.mark = ","),
          format(rows[["(3)"]]$n, big.mark = ","),
          format(rows[["(4)"]]$n, big.mark = ","),
          format(rows[["(5)"]]$n, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable indicated in column header. All specifications include the indicated fixed effects. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tab_dir, "tab2_main.tex"))
cat("Table 2 saved\n")

# -----------------------------------------------------------------------
# Table 3: Robustness
# -----------------------------------------------------------------------

rob_specs <- list(
  "Male placebo" = list(m = robust$male_placebo, var = "post_pfl"),
  "Female only" = list(m = robust$female_only, var = "post_pfl"),
  "Finance (NAICS 52)" = list(m = robust$finance_falsification, var = "treated_ddd"),
  "Nursing (NAICS 623)" = list(m = robust$nursing_subsector, var = "treated_ddd"),
  "Excl. California" = list(m = robust$no_california, var = "treated_ddd"),
  "Excl. COVID" = list(m = robust$no_covid, var = "treated_ddd"),
  "Age 25--44" = list(m = robust$young_age, var = "treated_ddd"),
  "Age 45+" = list(m = robust$older_age, var = "treated_ddd")
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & N \\\\",
  "\\midrule"
)

for (nm in names(rob_specs)) {
  spec <- rob_specs[[nm]]
  r <- get_row(spec$m, spec$var)
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %.4f%s & (%.4f) & %s \\\\",
    nm, r$coef, r$stars, r$se, format(r$n, big.mark = ",")
  ))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each row is a separate regression. Dependent variable: quarterly turnover rate. All DDD specifications include state$\\times$sex and sex$\\times$quarter fixed effects. Male/female-only regressions include state and quarter FE. Standard errors clustered at state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tab_dir, "tab3_robustness.tex"))
cat("Table 3 saved\n")

# -----------------------------------------------------------------------
# Table 4: PFL Adoption Details
# -----------------------------------------------------------------------

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Paid Family Leave Adoption Timeline}",
  "\\label{tab:pfl_timeline}",
  "\\begin{tabular}{llcc}",
  "\\toprule",
  "State & Effective Date & Pre-Periods & Post-Periods \\\\",
  "\\midrule"
)

max_q <- max(panel$time_id, na.rm = TRUE)
for (i in seq_len(nrow(pfl_states))) {
  s <- pfl_states[i, ]
  treat_t <- (s$pfl_year - 2001) * 4 + s$pfl_quarter
  pre <- treat_t - 1
  post <- max_q - treat_t + 1
  tab4_lines <- c(tab4_lines, sprintf(
    "%s & %s & %d & %d \\\\",
    s$state_abbr, format(s$pfl_date, "%B %Y"), pre, post
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre- and post-periods measured in quarters relative to QWI panel (2001Q1--2024Q4).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tab_dir, "tab4_pfl_timeline.tex"))
cat("Table 4 saved\n")

# -----------------------------------------------------------------------
# Table 5: Heterogeneity by cohort
# -----------------------------------------------------------------------

# Early adopters (CA, NJ, RI) vs late (2018+)
early_states <- c(6, 34, 44)
late_states <- c(36, 53, 11, 25, 9, 41, 8)

m_early <- feols(
  turnover ~ treated_ddd | state_fips^female + time_id^female,
  data = panel |> filter((state_fips %in% early_states) | !pfl_state, !is.na(turnover)),
  cluster = ~state_fips
)

m_late <- feols(
  turnover ~ treated_ddd | state_fips^female + time_id^female,
  data = panel |> filter((state_fips %in% late_states) | !pfl_state, !is.na(turnover)),
  cluster = ~state_fips
)

r_early <- get_row(m_early)
r_late <- get_row(m_late)

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Adoption Cohort}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Early Adopters & Late Adopters \\\\",
  " & (CA, NJ, RI: 2004--2014) & (NY--CO: 2018--2024) \\\\",
  "\\midrule",
  sprintf("PFL $\\times$ Female & %.4f%s & %.4f%s \\\\",
          r_early$coef, r_early$stars, r_late$coef, r_late$stars),
  sprintf(" & (%.4f) & (%.4f) \\\\", r_early$se, r_late$se),
  sprintf("Observations & %s & %s \\\\",
          format(r_early$n, big.mark = ","), format(r_late$n, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column restricts PFL states to the indicated cohort while retaining all never-treated states as controls. State$\\times$sex and sex$\\times$quarter FE. Standard errors clustered at state level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tab_dir, "tab5_heterogeneity.tex"))
cat("Table 5 saved\n")

# -----------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# -----------------------------------------------------------------------

# Compute SDE for main outcomes
compute_sde <- function(model, outcome_var, var_name = "treated_ddd", panel_df = panel, pre_only = TRUE) {
  b <- coef(model)[var_name]
  se_b <- se(model)[var_name]

  if (pre_only) {
    sd_y <- sd(panel_df[[outcome_var]][panel_df$post_pfl == 0], na.rm = TRUE)
  } else {
    sd_y <- sd(panel_df[[outcome_var]], na.rm = TRUE)
  }

  sde <- b / sd_y
  se_sde <- se_b / sd_y

  classify <- function(x) {
    abs_x <- abs(x)
    if (abs_x < 0.005) return("Null")
    if (abs_x < 0.05) {
      if (x > 0) return("Small positive") else return("Small negative")
    }
    if (abs_x < 0.15) {
      if (x > 0) return("Moderate positive") else return("Moderate negative")
    }
    if (x > 0) return("Large positive") else return("Large negative")
  }

  list(b = b, se_b = se_b, sd_y = sd_y, sde = sde, se_sde = se_sde, class = classify(sde))
}

sde_turnover <- compute_sde(results$m3_turnover, "turnover")
sde_seprate <- compute_sde(results$m3_seprate, "sep_rate")
sde_earn <- compute_sde(results$m3_earn, "ln_earn", panel_df = panel |> filter(!is.na(earnings)))

# Heterogeneity: young vs older
# For heterogeneous SDE, use pre-treatment SD from main panel as reference
sde_young <- compute_sde(robust$young_age, "turnover", panel_df = panel, pre_only = TRUE)
sde_older <- compute_sde(robust$older_age, "turnover", panel_df = panel, pre_only = TRUE)

sde_rows <- list(
  list(name = "Turnover rate", d = sde_turnover),
  list(name = "Separation rate", d = sde_seprate),
  list(name = "Log earnings", d = sde_earn),
  list(name = "Turnover (age 25--44)", d = sde_young),
  list(name = "Turnover (age 45+)", d = sde_older)
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level paid family leave mandates reduce female healthcare worker turnover relative to male healthcare workers in the same sector? ",
  "\\textbf{Policy mechanism:} Paid family leave programs provide wage-replacement benefits for parental bonding and family caregiving, funded through payroll contributions, reducing the cost of taking leave and thereby lowering involuntary job separations among workers with caregiving responsibilities. ",
  "\\textbf{Outcome definition:} Quarterly turnover rate (TurnOvrS) from Census QWI, measuring the fraction of stable workers who separate from their employer each quarter. ",
  "\\textbf{Treatment:} Binary; state-level PFL adoption (10 states, 2004--2024 staggered). ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI), 2001--2024, state-sex-quarter panel for NAICS 62 (Healthcare and Social Assistance), approximately 9,500 observations. ",
  "\\textbf{Method:} Triple difference-in-differences (state $\\times$ sex $\\times$ time) with state-sex and sex-quarter fixed effects; standard errors clustered at state level. ",
  "\\textbf{Sample:} All 51 states/DC, restricted to healthcare sector (NAICS 62), both sexes, working-age population. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
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
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\midrule"
)

for (i in 1:3) {
  r <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
    r$name, r$d$b, r$d$se_b, r$d$sd_y, r$d$sde, r$d$se_sde, r$d$class
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Age)}} \\\\",
  "\\midrule"
)

for (i in 4:5) {
  r <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
    r$name, r$d$b, r$d$se_b, r$d$sd_y, r$d$sde, r$d$se_sde, r$d$class
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tab_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) saved\n")

cat("\n=== ALL TABLES GENERATED ===\n")
