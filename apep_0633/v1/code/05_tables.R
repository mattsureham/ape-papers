## 05_tables.R — Generate all LaTeX tables
## apep_0633: Marijuana tax earmarking and education spending fungibility

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"

panel <- read_csv(file.path(data_dir, "analysis_panel.csv"), show_col_types = FALSE)
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ──────────────────────────────────────────────────
## Table 1: Summary Statistics
## ──────────────────────────────────────────────────

# Summary stats by treatment status
summ <- panel %>%
  filter(!is.na(exp_pp)) %>%
  mutate(group = if_else(treatment_year > 0, "Legalizing States", "Non-Legalizing States")) %>%
  group_by(group) %>%
  summarise(
    n_states = n_distinct(state_abbr),
    n_obs = n(),
    mean_exp = mean(exp_pp, na.rm = TRUE),
    sd_exp = sd(exp_pp, na.rm = TRUE),
    mean_rev = mean(rev_pp, na.rm = TRUE),
    sd_rev = sd(rev_pp, na.rm = TRUE),
    mean_strev = mean(st_rev_pp, na.rm = TRUE),
    sd_strev = sd(st_rev_pp, na.rm = TRUE),
    mean_locrev = mean(loc_rev_pp, na.rm = TRUE),
    sd_locrev = sd(loc_rev_pp, na.rm = TRUE),
    mean_fedrev = mean(fed_rev_pp, na.rm = TRUE),
    sd_fedrev = sd(fed_rev_pp, na.rm = TRUE),
    mean_curexp = mean(cur_exp_pp, na.rm = TRUE),
    sd_curexp = sd(cur_exp_pp, na.rm = TRUE),
    .groups = "drop"
  )

# Format table
tab1_tex <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Education Finance by Marijuana Legalization Status}
\\label{tab:summary}
\\small
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{Legalizing States} & \\multicolumn{2}{c}{Non-Legalizing States} \\\\
 & \\multicolumn{2}{c}{(N=%d, States=%d)} & \\multicolumn{2}{c}{(N=%d, States=%d)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Variable & Mean & SD & Mean & SD \\\\
\\hline
Total expenditure PP (\\$) & %s & %s & %s & %s \\\\
Total revenue PP (\\$) & %s & %s & %s & %s \\\\
State revenue PP (\\$) & %s & %s & %s & %s \\\\
Local revenue PP (\\$) & %s & %s & %s & %s \\\\
Federal revenue PP (\\$) & %s & %s & %s & %s \\\\
Current spending PP (\\$) & %s & %s & %s & %s \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} State-year panel, 2008--2022. Per-pupil (PP) amounts in nominal dollars. Legalizing states are the 20 states that began recreational marijuana sales by 2023. Census Annual Survey of School System Finances.
\\end{tablenotes}
\\end{table}
",
  summ$n_obs[summ$group == "Legalizing States"],
  summ$n_states[summ$group == "Legalizing States"],
  summ$n_obs[summ$group == "Non-Legalizing States"],
  summ$n_states[summ$group == "Non-Legalizing States"],
  format(round(summ$mean_exp[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$sd_exp[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$mean_exp[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$sd_exp[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$mean_rev[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$sd_rev[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$mean_rev[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$sd_rev[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$mean_strev[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$sd_strev[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$mean_strev[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$sd_strev[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$mean_locrev[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$sd_locrev[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$mean_locrev[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$sd_locrev[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$mean_fedrev[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$sd_fedrev[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$mean_fedrev[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$sd_fedrev[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$mean_curexp[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$sd_curexp[summ$group == "Legalizing States"]), big.mark = ","),
  format(round(summ$mean_curexp[summ$group == "Non-Legalizing States"]), big.mark = ","),
  format(round(summ$sd_curexp[summ$group == "Non-Legalizing States"]), big.mark = ",")
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

## ──────────────────────────────────────────────────
## Table 2: Main CS-DiD Results
## ──────────────────────────────────────────────────

# Helper to format coefficients
fmt_coef <- function(att, se, digits = 0) {
  stars <- ""
  p_approx <- 2 * (1 - pnorm(abs(att / se)))
  if (p_approx < 0.01) stars <- "^{***}"
  else if (p_approx < 0.05) stars <- "^{**}"
  else if (p_approx < 0.10) stars <- "^{*}"

  coef_str <- format(round(att, digits), big.mark = ",")
  se_str <- format(round(se, digits), big.mark = ",")
  sprintf("%s%s & (%s)", coef_str, stars, se_str)
}

# Main CS-DiD results
tab2_tex <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Effect of Recreational Marijuana Legalization on Education Finance}
\\label{tab:main}
\\small
\\begin{tabular}{lcc}
\\hline\\hline
 & CS-DiD ATT & TWFE \\\\
\\hline
\\textit{Panel A: Expenditure} & & \\\\[3pt]
Total expenditure PP & %s & %s \\\\[6pt]
Current spending PP & %s & \\\\[6pt]
Capital outlay PP & %s & \\\\[12pt]
\\textit{Panel B: Revenue decomposition} & & \\\\[3pt]
Total revenue PP & %s & \\\\[6pt]
State revenue PP & %s & %s \\\\[6pt]
Local revenue PP & %s & %s \\\\[6pt]
Federal revenue PP (placebo) & %s & %s \\\\[6pt]
\\hline
Observations & %d & %d \\\\
States & 51 & 51 \\\\
Treated states & 20 & 20 \\\\
Years & 2008--2022 & 2008--2022 \\\\
Never-treated controls & 31 & 31 \\\\
Estimator & CS (2021) & TWFE \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Per-pupil amounts in nominal dollars. CS-DiD: Callaway and Sant'Anna (2021) doubly robust estimator with never-treated states as controls. TWFE: two-way fixed effects (state + year) with state-clustered standard errors. Treatment = first year of recreational marijuana sales. Standard errors in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.
\\end{tablenotes}
\\end{table}
",
  fmt_coef(results$agg_exp$overall.att, results$agg_exp$overall.se),
  fmt_coef(coef(results$twfe_exp)["postTRUE"], se(results$twfe_exp)["postTRUE"]),
  fmt_coef(results$agg_cur$overall.att, results$agg_cur$overall.se),
  fmt_coef(robust$agg_cap$overall.att, robust$agg_cap$overall.se),
  fmt_coef(results$agg_rev$overall.att, results$agg_rev$overall.se),
  fmt_coef(results$agg_strev$overall.att, results$agg_strev$overall.se),
  fmt_coef(coef(results$twfe_strev)["postTRUE"], se(results$twfe_strev)["postTRUE"]),
  fmt_coef(results$agg_locrev$overall.att, results$agg_locrev$overall.se),
  fmt_coef(coef(results$twfe_locrev)["postTRUE"], se(results$twfe_locrev)["postTRUE"]),
  fmt_coef(results$agg_fedrev$overall.att, results$agg_fedrev$overall.se),
  fmt_coef(coef(results$twfe_fedrev)["postTRUE"], se(results$twfe_fedrev)["postTRUE"]),
  nrow(panel), nrow(panel)
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

## ──────────────────────────────────────────────────
## Table 3: Robustness
## ──────────────────────────────────────────────────

tab3_tex <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Robustness: Effect on Total Expenditure Per Pupil}
\\label{tab:robust}
\\small
\\begin{tabular}{lcc}
\\hline\\hline
Specification & ATT & SE \\\\
\\hline
Baseline (all states) & %s & (%s) \\\\
Exclude Alaska & %s & (%s) \\\\
Log expenditure PP & %s & (%s) \\\\
Exclude 2020--2021 (COVID) & %s & (%s) \\\\
TWFE (state + year FE) & %s & (%s) \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} All specifications use per-pupil total education expenditure as the outcome except log specification. Baseline: Callaway-Sant'Anna (2021) with never-treated controls. Alaska excluded due to extreme per-pupil spending (\\$23,000+ vs.~national average \\$14,000). COVID exclusion drops 2020--2021 and restricts to pre-2020 treatment cohorts. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.
\\end{tablenotes}
\\end{table}
",
  format(round(results$agg_exp$overall.att), big.mark = ","),
  format(round(results$agg_exp$overall.se), big.mark = ","),
  format(round(robust$agg_exp_no_ak$overall.att), big.mark = ","),
  format(round(robust$agg_exp_no_ak$overall.se), big.mark = ","),
  sprintf("%.3f", robust$agg_log_exp$overall.att),
  sprintf("%.3f", robust$agg_log_exp$overall.se),
  format(round(robust$agg_exp_no_covid$overall.att), big.mark = ","),
  format(round(robust$agg_exp_no_covid$overall.se), big.mark = ","),
  format(round(coef(results$twfe_exp)["postTRUE"]), big.mark = ","),
  format(round(se(results$twfe_exp)["postTRUE"]), big.mark = ",")
)

writeLines(tab3_tex, file.path(table_dir, "tab3_robust.tex"))
cat("Table 3 written.\n")

## ──────────────────────────────────────────────────
## Table 4: Heterogeneity by Earmarking Status
## ──────────────────────────────────────────────────

tab4_tex <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Heterogeneity: Education Earmarking}
\\label{tab:earmark}
\\small
\\begin{tabular}{lccc}
\\hline\\hline
 & Earmark States & No-Earmark States & Difference \\\\
\\hline
ATT (total expenditure PP) & %s & %s & %s \\\\
 & (%s) & (%s) & \\\\[6pt]
Treated states & 7 & 13 & \\\\
States with earmarking & CO, OR, NV, IL, & WA, AK, CA, MA, & \\\\
 & MI, VT, MD & ME, AZ, MT, NJ, & \\\\
 & & NM, CT, MO, NY, RI & \\\\[6pt]
Avg.~MJ revenue PP (\\$) & %s & %s & \\\\
Implied passthrough & %s & --- & \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Earmark states direct a specified share of marijuana tax revenue to K--12 education or school construction funds. No-earmark states direct revenue to general funds, social programs, or non-education purposes. Implied passthrough = ATT / average marijuana revenue per pupil; values above 1.0 indicate spending increases exceeding direct marijuana revenue. Callaway-Sant'Anna (2021) with never-treated controls. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.
\\end{tablenotes}
\\end{table}
",
  format(round(robust$agg_earmark$overall.att), big.mark = ","),
  format(round(robust$agg_no_earmark$overall.att), big.mark = ","),
  format(round(robust$agg_earmark$overall.att - robust$agg_no_earmark$overall.att), big.mark = ","),
  format(round(robust$agg_earmark$overall.se), big.mark = ","),
  format(round(robust$agg_no_earmark$overall.se), big.mark = ","),
  "227", "198",
  sprintf("%.1f", robust$agg_earmark$overall.att / 227),
  sprintf("%.1f", robust$agg_no_earmark$overall.att / 198)
)

writeLines(tab4_tex, file.path(table_dir, "tab4_earmark.tex"))
cat("Table 4 written.\n")

## ──────────────────────────────────────────────────
## Table F1: Standardized Effect Sizes (SDE) — Appendix
## ──────────────────────────────────────────────────

# Using exclude-Alaska estimates as preferred specification
sd_exp <- sd(panel$exp_pp[panel$state_abbr != "AK"], na.rm = TRUE)
sd_strev <- sd(panel$st_rev_pp[panel$state_abbr != "AK"], na.rm = TRUE)
sd_fedrev <- sd(panel$fed_rev_pp, na.rm = TRUE)
sd_locrev <- sd(panel$loc_rev_pp, na.rm = TRUE)
sd_curexp <- sd(panel$cur_exp_pp[panel$state_abbr != "AK"], na.rm = TRUE)

# For binary treatment, SDE = beta / SD(Y)
sde_data <- tibble(
  outcome = c("Total expenditure PP", "Current spending PP",
              "State revenue PP", "Local revenue PP",
              "Federal revenue PP"),
  beta = c(robust$agg_exp_no_ak$overall.att,
           results$agg_cur$overall.att,
           results$agg_strev$overall.att,
           results$agg_locrev$overall.att,
           results$agg_fedrev$overall.att),
  se = c(robust$agg_exp_no_ak$overall.se,
         results$agg_cur$overall.se,
         results$agg_strev$overall.se,
         results$agg_locrev$overall.se,
         results$agg_fedrev$overall.se),
  sd_y = c(sd_exp, sd_curexp, sd_strev, sd_locrev, sd_fedrev)
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

sde_rows <- paste(apply(sde_data, 1, function(r) {
  sprintf("%s & %s & (%s) & %s & %.3f & (%.3f) & %s",
          r["outcome"],
          format(round(as.numeric(r["beta"])), big.mark = ","),
          format(round(as.numeric(r["se"])), big.mark = ","),
          format(round(as.numeric(r["sd_y"])), big.mark = ","),
          as.numeric(r["sde"]),
          as.numeric(r["se_sde"]),
          r["classification"])
}), collapse = " \\\\\n")

tabF1_tex <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\small
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & (SE) & SD($Y$) & SDE & (SE) & Classification \\\\
\\hline
%s \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} This paper estimates the causal effect of recreational marijuana legalization on per-pupil education finance outcomes using Callaway-Sant'Anna (2021) difference-in-differences. Data: Census Annual Survey of School System Finances, 51 states, 2008--2022. $N=765$ state-year observations; 20 treated states, 31 never-treated controls. Treatment: binary indicator for recreational marijuana sales. SDE = $\\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. Classification refers to effect magnitude, not statistical significance. Preferred specification excludes Alaska.
\\end{tablenotes}
\\end{table}
", sde_rows)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
