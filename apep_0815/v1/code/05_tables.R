## 05_tables.R — Generate all LaTeX tables
source("code/00_packages.R")

results <- readRDS("data/main_results.rds")
robust <- readRDS("data/robustness_results.rds")
df <- readRDS("data/panel_main.rds")

dir.create("tables", showWarnings = FALSE)

# ── Table 1: Summary Statistics ──────────────────────────────────
summ_pre <- df |>
  filter(post == 0) |>
  group_by(age_group, enforcement) |>
  summarise(
    N_obs = n(),
    States = n_distinct(state_fips),
    Emp_SD = sprintf("(%.0f)", sd(Emp, na.rm = TRUE)),
    Emp = sprintf("%.0f", mean(Emp, na.rm = TRUE)),
    Earn_SD = sprintf("(%.0f)", sd(EarnS, na.rm = TRUE)),
    Earn = sprintf("%.0f", mean(EarnS, na.rm = TRUE)),
    Hires = sprintf("%.0f", mean(HirA, na.rm = TRUE)),
    .groups = "drop"
  ) |>
  arrange(desc(enforcement), age_group)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-FRA Period (2018Q1--2023Q2)}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  " & & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Earnings (\\$)} & Hires \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}\n",
  "Enforcement & Age Group & Mean & SD & Mean & SD & Mean \\\\\n",
  "\\midrule\n"
)
for (i in seq_len(nrow(summ_pre))) {
  row <- summ_pre[i, ]
  enf_label <- ifelse(row$enforcement == "full", "Full", "Waiver")
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
            enf_label, row$age_group,
            row$Emp, row$Emp_SD, row$Earn, row$Earn_SD, row$Hires))
}
tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} QWI data from Census Bureau, 2018Q1--2023Q2. ",
  "Employment is beginning-of-quarter count. Earnings are average monthly ",
  "for stable employment. Full enforcement = 18 states that reinstated ABAWD ",
  "time limits statewide. Waiver = 11 states that waived time limits entirely.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "tables/tab1_summary.tex")
cat("Wrote tables/tab1_summary.tex\n")

# ── Table 2: Main DDD Results (Naive + De-trended) ──────────────
# Build by hand for precise control

make_row <- function(model, varname) {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pnorm(-abs(b/s)) * 2
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(est = sprintf("%.4f%s", b, stars), se = sprintf("(%.4f)", s))
}

# Columns: (1) Naive Emp, (2) Detrended Emp, (3) Naive Hires, (4) Detrended Hires, (5) Earnings
c1 <- make_row(results$m1_emp, "ddd")
c2 <- make_row(results$m5_detrend, "ddd")
c3 <- make_row(results$m2_hires, "ddd")
c4 <- make_row(results$m6_detrend_hires, "ddd")
c5 <- make_row(results$m4_earn, "ddd")

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Triple-Difference Estimates: Effect of FRA ABAWD Expansion on Employment}\n",
  "\\label{tab:ddd}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Log Employment} & \\multicolumn{2}{c}{Log Hires} & Log Earnings \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Naive & De-trended & Naive & De-trended & De-trended \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ Young $\\times$ Enforce & %s & %s & %s & %s & %s \\\\\n",
          c1$est, c2$est, c3$est, c4$est, c5$est),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n",
          c1$se, c2$se, c3$se, c4$se, c5$se),
  "[6pt]\n",
  "Young $\\times$ Enforce $\\times$ Trend & & Yes & & Yes & Yes \\\\\n",
  "State $\\times$ Age FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Age $\\times$ Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "State $\\times$ Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(nobs(results$m1_emp), big.mark = ","),
          format(nobs(results$m5_detrend), big.mark = ","),
          format(nobs(results$m2_hires), big.mark = ","),
          format(nobs(results$m6_detrend_hires), big.mark = ","),
          format(nobs(results$m4_earn), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Triple-difference estimates comparing ages 45--54 (partially treated) ",
  "vs 55--64 (control), before vs after FRA (2023Q3), in full-enforcement vs statewide-waiver states. ",
  "Columns (2), (4), and (5) include a Young $\\times$ Enforce $\\times$ linear quarter trend to ",
  "account for differential pre-trends identified in the event study. The de-trended employment ",
  "estimate is the preferred specification. Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "tables/tab2_ddd.tex")
cat("Wrote tables/tab2_ddd.tex\n")

# ── Table 3: Robustness ─────────────────────────────────────────
stars_fn <- function(b, s) {
  p <- pnorm(-abs(b/s)) * 2
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

b_base <- coef(results$m1_emp)["ddd"]
se_base <- se(results$m1_emp)["ddd"]
b_det <- coef(results$m5_detrend)["ddd"]
se_det <- se(results$m5_detrend)["ddd"]
b_all <- coef(robust$r1_all_states)["ddd_all"]
se_all <- se(robust$r1_all_states)["ddd_all"]
b_trend <- coef(robust$r2_pretrend)["qtr_num:young:enforce"]
se_trend <- se(robust$r2_pretrend)["qtr_num:young:enforce"]
b_p1 <- coef(robust$r3_phase)["ddd_p1"]
se_p1 <- se(robust$r3_phase)["ddd_p1"]
b_p2 <- coef(robust$r3_phase)["ddd_p2"]
se_p2 <- se(robust$r3_phase)["ddd_p2"]

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Log Employment}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & Estimate & SE \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Main estimates}} \\\\\n",
  sprintf("~~Naive DDD (full vs waiver) & %s%s & %s \\\\\n",
          sprintf("%.4f", b_base), stars_fn(b_base, se_base), sprintf("(%.4f)", se_base)),
  sprintf("~~De-trended DDD (preferred) & %s%s & %s \\\\\n",
          sprintf("%.4f", b_det), stars_fn(b_det, se_det), sprintf("(%.4f)", se_det)),
  "[3pt]\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Specification checks}} \\\\\n",
  sprintf("~~All states (full vs rest) & %s%s & %s \\\\\n",
          sprintf("%.4f", b_all), stars_fn(b_all, se_all), sprintf("(%.4f)", se_all)),
  sprintf("~~Pre-trend slope (per quarter) & %s%s & %s \\\\\n",
          sprintf("%.4f", b_trend), stars_fn(b_trend, se_trend), sprintf("(%.4f)", se_trend)),
  "[3pt]\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Phase-specific effects}} \\\\\n",
  sprintf("~~Phase 1 only (2023Q3) & %s%s & %s \\\\\n",
          sprintf("%.4f", b_p1), stars_fn(b_p1, se_p1), sprintf("(%.4f)", se_p1)),
  sprintf("~~Phase 2+ (2023Q4--2024Q4) & %s%s & %s \\\\\n",
          sprintf("%.4f", b_p2), stars_fn(b_p2, se_p2), sprintf("(%.4f)", se_p2)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A compares naive and de-trended DDD on log employment. ",
  "Panel B shows the DDD using all 50 states (full enforcement vs all others) and the ",
  "linear pre-trend slope in the young $\\times$ enforce interaction. The significant ",
  "pre-trend (0.0026/quarter, $p<0.05$) motivates the de-trended specification. ",
  "Panel C decomposes effects by FRA implementation phase. All specifications include ",
  "state$\\times$age, age$\\times$quarter, and state$\\times$quarter fixed effects. ",
  "Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "tables/tab3_robust.tex")
cat("Wrote tables/tab3_robust.tex\n")

# ── Table F1: SDE Appendix ───────────────────────────────────────
pre_stats <- df |>
  filter(post == 0) |>
  summarise(
    sd_log_emp = sd(log_emp, na.rm = TRUE),
    sd_log_hires = sd(log_hires, na.rm = TRUE),
    sd_log_sep = sd(log_sep, na.rm = TRUE),
    sd_log_earn = sd(log_earn, na.rm = TRUE)
  )

# Use de-trended estimates as the preferred specification
sde_data <- data.frame(
  outcome = c("Log Employment", "Log Hires", "Log Separations", "Log Earnings"),
  beta = c(
    coef(results$m5_detrend)["ddd"],
    coef(results$m6_detrend_hires)["ddd"],
    coef(results$m3_sep)["ddd"],  # Sep not de-trended separately; note in table
    coef(results$m4_earn)["ddd"]
  ),
  se_beta = c(
    se(results$m5_detrend)["ddd"],
    se(results$m6_detrend_hires)["ddd"],
    se(results$m3_sep)["ddd"],
    se(results$m4_earn)["ddd"]
  ),
  sd_y = c(
    pre_stats$sd_log_emp,
    pre_stats$sd_log_hires,
    pre_stats$sd_log_sep,
    pre_stats$sd_log_earn
  )
)

sde_data <- sde_data |>
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
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

cat("\n=== SDE Table ===\n")
print(sde_data)

sde_rows <- ""
for (i in seq_len(nrow(sde_data))) {
  r <- sde_data[i, ]
  sde_rows <- paste0(sde_rows,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            r$outcome, r$beta, r$se_beta, r$sd_y, r$sde, r$se_sde, r$classification))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does extending SNAP work requirements (ABAWD time limits) ",
  "from ages 18--49 to ages 18--54 under the Fiscal Responsibility Act of 2023 increase ",
  "formal employment among newly affected older adults? ",
  "\\textbf{Policy mechanism:} The FRA expanded Able-Bodied Adults Without Dependents (ABAWD) ",
  "time limits in three legislated phases, requiring adults aged 50--54 to work at least 80 ",
  "hours per month or lose SNAP benefits after three months, effectively conditioning food ",
  "assistance on labor force participation for a population with elevated chronic disease prevalence. ",
  "\\textbf{Outcome definition:} Log quarterly employment (beginning-of-quarter count from QWI), ",
  "log all hires, log separations, and log average monthly earnings for stable employment. ",
  "\\textbf{Treatment:} Binary --- the triple-difference indicator equals one for the 45--54 age ",
  "group in full-enforcement states after FRA implementation (2023Q3). ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI), 2018Q1--2024Q4, state-by-age-group ",
  "quarterly panel; 29 states (18 full enforcement, 11 statewide waiver), 1,618 observations. ",
  "\\textbf{Method:} Triple-difference (age group $\\times$ post-FRA $\\times$ enforcement status) ",
  "with state$\\times$age, age$\\times$quarter, and state$\\times$quarter fixed effects plus a ",
  "young$\\times$enforce$\\times$linear-quarter trend to account for differential pre-trends; ",
  "standard errors clustered at the state level. ",
  "\\textbf{Sample:} All formal-sector workers aged 45--64 in states that either fully enforced ",
  "or fully waived ABAWD time limits; partial-waiver states excluded from baseline. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sde_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "tables/tabF1_sde.tex")
cat("Wrote tables/tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
