# 05_tables.R — Generate all tables
# apep_0644: Pay Transparency Mandates and Employer Adjustment

source("00_packages.R")

cat("=== Generating Tables ===\n")

load("../data/main_results.RData")
load("../data/robustness_results.RData")
df <- readRDS("../data/analysis_data.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

sum_stats <- df %>%
  summarize(
    across(
      c(new_hire_rate, recall_rate, job_creation_rate, job_destruction_rate,
        sep_rate, turnover_rate, Emp, EarnS, EarnHirNS),
      list(
        mean = ~mean(.x, na.rm = TRUE),
        sd = ~sd(.x, na.rm = TRUE),
        p25 = ~quantile(.x, 0.25, na.rm = TRUE),
        p75 = ~quantile(.x, 0.75, na.rm = TRUE)
      )
    )
  )

# Prepare for treated vs control
sum_treated <- df %>% filter(treated_state) %>%
  summarize(
    across(c(new_hire_rate, recall_rate, job_creation_rate, job_destruction_rate,
             sep_rate, turnover_rate, Emp, EarnS, EarnHirNS),
           list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)))
  )

sum_control <- df %>% filter(!treated_state) %>%
  summarize(
    across(c(new_hire_rate, recall_rate, job_creation_rate, job_destruction_rate,
             sep_rate, turnover_rate, Emp, EarnS, EarnHirNS),
           list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)))
  )

# Build LaTeX table
var_labels <- c(
  "New hire rate (HirN/Emp)",
  "Recall rate ((HirA-HirN)/Emp)",
  "Job creation rate (FrmJbGn/Emp)",
  "Job destruction rate (FrmJbLs/Emp)",
  "Separation rate (Sep/Emp)",
  "Turnover rate (TurnOvrS/Emp)",
  "Employment (level)",
  "Avg. quarterly earnings (\\$)",
  "New hire earnings (\\$)"
)

var_names <- c("new_hire_rate", "recall_rate", "job_creation_rate", "job_destruction_rate",
               "sep_rate", "turnover_rate", "Emp", "EarnS", "EarnHirNS")

n_treated <- nrow(df %>% filter(treated_state))
n_control <- nrow(df %>% filter(!treated_state))

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: County-Quarter-Industry Observations}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Treated States} & \\multicolumn{2}{c}{Control States} & \\multicolumn{2}{c}{Full Sample} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Variable & Mean & SD & Mean & SD & Mean & SD \\\\"
)
tab1_lines <- c(tab1_lines, "\\midrule")

for (i in seq_along(var_names)) {
  v <- var_names[i]
  fmt <- ifelse(v %in% c("Emp", "EarnS", "EarnHirNS"), "%.0f", "%.4f")

  row <- sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    var_labels[i],
    sprintf(fmt, sum_treated[[paste0(v, "_mean")]]),
    sprintf(fmt, sum_treated[[paste0(v, "_sd")]]),
    sprintf(fmt, sum_control[[paste0(v, "_mean")]]),
    sprintf(fmt, sum_control[[paste0(v, "_sd")]]),
    sprintf(fmt, mean(df[[v]], na.rm = TRUE)),
    sprintf(fmt, sd(df[[v]], na.rm = TRUE))
  )
  tab1_lines <- c(tab1_lines, row)
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(n_treated, big.mark = ","),
          format(n_control, big.mark = ","),
          format(nrow(df), big.mark = ",")),
  sprintf("Counties & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(n_distinct(df$county_fips[df$treated_state]), big.mark = ","),
          format(n_distinct(df$county_fips[!df$treated_state]), big.mark = ","),
          format(n_distinct(df$county_fips), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Data from the Quarterly Workforce Indicators (QWI), 2015Q1--2024Q4. Unit of observation is county-quarter-industry (2-digit NAICS). Treated states are Colorado (mandate effective 2021Q1), California (2023Q1), Washington (2023Q1), and New York (2023Q4). Rates are computed as the ratio of the flow variable to beginning-of-quarter employment. Earnings are average quarterly earnings. N = %s county-quarter-industry observations.",
          format(nrow(df), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ============================================================
# Table 2: Main Results — Callaway-Sant'Anna ATT
# ============================================================
cat("Generating Table 2: Main Results\n")

# Build main results table from results_summary
stars_fn <- function(p) {
  case_when(p < 0.01 ~ "***", p < 0.05 ~ "**", p < 0.10 ~ "*", TRUE ~ "")
}

rs <- results_summary %>%
  mutate(
    att_str = sprintf("%.4f%s", att, stars_fn(p_value)),
    se_str = sprintf("(%.4f)", se),
    ci_str = sprintf("[%.4f, %.4f]", ci_low, ci_high)
  )

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Main Results: Effect of Pay Transparency Mandates on Labor Market Flows}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & New Hire & Recall & Job Creation & Separation & Turnover & Log NH \\\\",
  " & Rate & Rate & Rate & Rate & Rate & Earnings \\\\",
  "\\midrule"
)

# ATT row
att_row <- paste0("CS ATT & ",
  paste(rs$att_str, collapse = " & "),
  " \\\\")
se_row <- paste0(" & ",
  paste(rs$se_str, collapse = " & "),
  " \\\\")
ci_row <- paste0("95\\% CI & ",
  paste(rs$ci_str, collapse = " & "),
  " \\\\")

n_obs <- nrow(state_df)
n_units <- n_distinct(state_df$panel_id)
n_treated_units <- n_distinct(state_df$panel_id[state_df$treated_state])

tab2_lines <- c(tab2_lines, att_row, se_row, "", ci_row,
  "\\midrule",
  sprintf("Observations & \\multicolumn{6}{c}{%s} \\\\", format(n_obs, big.mark = ",")),
  sprintf("State-industry units & \\multicolumn{6}{c}{%s} \\\\", format(n_units, big.mark = ",")),
  sprintf("Treated units & \\multicolumn{6}{c}{%s} \\\\", format(n_treated_units, big.mark = ",")),
  "Treatment cohorts & \\multicolumn{6}{c}{4 (CO 2021Q1, CA 2023Q1, WA 2023Q1, NY 2023Q4)} \\\\",
  "Control group & \\multicolumn{6}{c}{Never-treated states} \\\\",
  "Estimator & \\multicolumn{6}{c}{Callaway--Sant'Anna (doubly robust)} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the Callaway--Sant'Anna (2021) overall ATT, aggregated across group-time effects using doubly robust estimation. Standard errors in parentheses. The unit of observation is state-industry-quarter. New hire rate is new hires divided by employment; recall rate is recalls (total hires minus new hires) divided by employment; job creation rate is gross firm job gains divided by employment; separation rate is total separations divided by employment; turnover rate is stable worker turnover divided by employment; log NH earnings is log average quarterly earnings of new hires. \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ============================================================
# Table 3: Industry Heterogeneity
# ============================================================
cat("Generating Table 3: Industry Heterogeneity\n")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Industry Heterogeneity: High vs.\\ Low Wage-Dispersion Industries}",
  "\\label{tab:heterogeneity}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & All Industries & High Dispersion & Low Dispersion \\\\",
  "\\midrule",
  sprintf("CS ATT & %s%s & %s%s & %s%s \\\\",
    sprintf("%.4f", cs_new_hire_agg$overall.att),
    stars_fn(2 * pnorm(-abs(cs_new_hire_agg$overall.att / cs_new_hire_agg$overall.se))),
    sprintf("%.4f", cs_high_agg$overall.att),
    stars_fn(2 * pnorm(-abs(cs_high_agg$overall.att / cs_high_agg$overall.se))),
    sprintf("%.4f", cs_low_agg$overall.att),
    stars_fn(2 * pnorm(-abs(cs_low_agg$overall.att / cs_low_agg$overall.se)))),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\",
    cs_new_hire_agg$overall.se, cs_high_agg$overall.se, cs_low_agg$overall.se),
  "\\midrule",
  "Industries & All private & NAICS 51-55 & NAICS 44-45, 56, 72 \\\\",
  "Estimator & \\multicolumn{3}{c}{Callaway--Sant'Anna (doubly robust)} \\\\",
  "Control group & \\multicolumn{3}{c}{Never-treated states} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Outcome is new hire rate (HirN/Emp). High wage-dispersion industries: Information (51), Finance (52), Professional Services (54), Management (55). Low wage-dispersion industries: Retail (44-45), Administrative Services (56), Accommodation and Food Services (72). Classification based on BLS Occupational Employment and Wage Statistics inter-quartile range. Standard errors in parentheses. \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_heterogeneity.tex")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("Generating Table 4: Robustness\n")

gov_att <- if (!is.null(cs_gov_agg) && !is.na(cs_gov_agg$overall.att)) cs_gov_agg$overall.att else NA
gov_se <- if (!is.null(cs_gov_agg) && !is.na(cs_gov_agg$overall.se)) cs_gov_agg$overall.se else NA

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications and Samples}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & ATT & SE \\\\",
  "\\midrule",
  "\\textit{Panel A: Main Result} & & \\\\",
  sprintf("Baseline (all industries) & %.4f%s & (%.4f) \\\\",
    cs_new_hire_agg$overall.att,
    stars_fn(2 * pnorm(-abs(cs_new_hire_agg$overall.att / cs_new_hire_agg$overall.se))),
    cs_new_hire_agg$overall.se),
  "\\midrule",
  "\\textit{Panel B: Alternative Samples} & & \\\\",
  sprintf("Colorado border states only & %.4f%s & (%.4f) \\\\",
    cs_border_agg$overall.att,
    stars_fn(2 * pnorm(-abs(cs_border_agg$overall.att / cs_border_agg$overall.se))),
    cs_border_agg$overall.se),
  sprintf("Male workers only & %.4f%s & (%.4f) \\\\",
    cs_male_agg$overall.att,
    stars_fn(2 * pnorm(-abs(cs_male_agg$overall.att / cs_male_agg$overall.se))),
    cs_male_agg$overall.se),
  sprintf("Female workers only & %.4f%s & (%.4f) \\\\",
    cs_female_agg$overall.att,
    stars_fn(2 * pnorm(-abs(cs_female_agg$overall.att / cs_female_agg$overall.se))),
    cs_female_agg$overall.se),
  "\\midrule",
  "\\textit{Panel C: Placebo} & & \\\\",
  ifelse(!is.na(gov_att),
    sprintf("Government sector (NAICS 92) & %.4f%s & (%.4f) \\\\",
      gov_att, stars_fn(2 * pnorm(-abs(gov_att / gov_se))), gov_se),
    "Government sector (NAICS 92) & --- & --- \\\\"),
  "\\midrule",
  "\\textit{Panel D: Leave-One-State-Out} & & \\\\"
)

for (i in 1:nrow(loo_results)) {
  p <- 2 * pnorm(-abs(loo_results$att[i] / loo_results$se[i]))
  tab4_lines <- c(tab4_lines,
    sprintf("Drop %s & %.4f%s & (%.4f) \\\\",
      loo_results$dropped_state[i], loo_results$att[i], stars_fn(p), loo_results$se[i]))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Outcome is new hire rate (HirN/Emp). All specifications use the Callaway--Sant'Anna (2021) estimator with doubly robust estimation and never-treated control group. Panel B restricts the sample: border analysis uses Colorado and its 7 bordering states; gender specifications use sex-disaggregated QWI data. Panel C uses public administration (NAICS 92) as a placebo sector, as government employers are generally exempt from salary posting requirements. Panel D drops each treated state in turn to assess sensitivity. \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ============================================================
# Table 5: Group-Specific ATTs
# ============================================================
cat("Generating Table 5: Group-Specific ATTs\n")

# CA and WA share 2023Q1 treatment timing, so CS treats them as one group
# Map group labels to CS group IDs
n_groups <- length(cs_new_hire_group$att.egt)
group_labels <- if (n_groups == 3) {
  c("Colorado (2021Q1)", "California \\& Washington (2023Q1)", "New York (2023Q4)")
} else {
  c("Colorado (2021Q1)", "California (2023Q1)",
    "Washington (2023Q1)", "New York (2023Q4)")
}

group_df <- tibble(
  cohort = group_labels,
  att = cs_new_hire_group$att.egt,
  se = cs_new_hire_group$se.egt
) %>%
  mutate(
    p = 2 * pnorm(-abs(att / se)),
    ci_low = att - 1.96 * se,
    ci_high = att + 1.96 * se
  )

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Group-Specific ATTs by Treatment Cohort}",
  "\\label{tab:group_att}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Cohort & ATT & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (i in 1:nrow(group_df)) {
  tab5_lines <- c(tab5_lines,
    sprintf("%s & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\",
      group_df$cohort[i], group_df$att[i], stars_fn(group_df$p[i]),
      group_df$se[i], group_df$ci_low[i], group_df$ci_high[i]))
}

tab5_lines <- c(tab5_lines,
  "\\midrule",
  sprintf("Overall (simple) & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\",
    cs_new_hire_agg$overall.att,
    stars_fn(2 * pnorm(-abs(cs_new_hire_agg$overall.att / cs_new_hire_agg$overall.se))),
    cs_new_hire_agg$overall.se,
    cs_new_hire_agg$overall.att - 1.96 * cs_new_hire_agg$overall.se,
    cs_new_hire_agg$overall.att + 1.96 * cs_new_hire_agg$overall.se),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Outcome is new hire rate (HirN/Emp). Group-specific ATTs from the Callaway--Sant'Anna (2021) estimator, aggregated within each treatment cohort. Standard errors in parentheses. 95\\% confidence intervals in brackets. \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_group_att.tex")

# ============================================================
# SDE Table (Appendix — MANDATORY)
# ============================================================
cat("Generating SDE Table\n")

sde_outcomes <- results_summary %>%
  mutate(
    sd_y = c(
      sd(df$new_hire_rate, na.rm = TRUE),
      sd(df$recall_rate, na.rm = TRUE),
      sd(df$job_creation_rate, na.rm = TRUE),
      sd(df$sep_rate, na.rm = TRUE),
      sd(df$turnover_rate, na.rm = TRUE),
      sd(df$log_earn_new_hire, na.rm = TRUE)
    ),
    sde = att / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_outcomes)) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
      sde_outcomes$outcome[i],
      sde_outcomes$att[i], sde_outcomes$se[i], sde_outcomes$sd_y[i],
      sde_outcomes$sde[i], sde_outcomes$se_sde[i], sde_outcomes$classification[i]))
}

n_total <- nrow(df)

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. For binary treatments (mandate vs.\\ no mandate), SDE $= \\hat{\\beta} / \\text{SD}(Y)$. SD($Y$) is the unconditional standard deviation from the full sample. \\textbf{Research question:} Do state salary-range-in-job-posting mandates affect employer hiring flows, job creation, and turnover? \\textbf{Treatment:} Binary (state mandate enacted vs.\\ no mandate). \\textbf{Data:} QWI county-quarter-industry, 2015Q1--2024Q4, %s observations. \\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator, state-clustered inference. \\textbf{Sample:} All US counties with non-missing QWI data, private-sector 2-digit NAICS industries. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
    format(n_total, big.mark = ",")),
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files written to tables/:\n")
list.files("../tables/", pattern = "\\.tex$")
