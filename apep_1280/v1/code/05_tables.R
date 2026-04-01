# ==============================================================================
# 05_tables.R — Generate all tables (V1: tables only, no figures)
# ==============================================================================

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

analysis <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================
cat("=== Table 1: Summary Statistics ===\n")

low_wage <- analysis |> filter(industry_group == "low_wage")
high_wage <- analysis |> filter(industry_group == "high_wage")

summ_fn <- function(d, label) {
  d |>
    summarize(
      Panel = label,
      `N obs` = n(),
      `Mean B/W Earnings Ratio` = sprintf("%.3f", mean(earns_A2 / earns_A1, na.rm = TRUE)),
      `SD B/W Earnings Ratio` = sprintf("%.3f", sd(earns_A2 / earns_A1, na.rm = TRUE)),
      `Mean B/W Employment Ratio` = sprintf("%.3f", mean(emp_A2 / emp_A1, na.rm = TRUE)),
      `Mean Effective MW ($)` = sprintf("%.2f", mean(effective_mw, na.rm = TRUE)),
      `Mean MW/Federal Ratio` = sprintf("%.2f", mean(mw_ratio, na.rm = TRUE))
    )
}

tab1 <- bind_rows(
  summ_fn(low_wage, "Low-Wage Industries"),
  summ_fn(high_wage, "High-Wage Industries (Placebo)")
)

# Write LaTeX
tab1_tex <- "\\begin{table}[!htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & Low-Wage & High-Wage (Placebo) \\\\
\\midrule"

# Build rows from summary
for (var in c("N obs", "Mean B/W Earnings Ratio", "SD B/W Earnings Ratio",
              "Mean B/W Employment Ratio", "Mean Effective MW ($)", "Mean MW/Federal Ratio")) {
  v1 <- tab1 |> filter(Panel == "Low-Wage Industries") |> pull(var)
  v2 <- tab1 |> filter(Panel == "High-Wage Industries (Placebo)") |> pull(var)
  varname <- gsub("\\$", "\\\\$", var)
  tab1_tex <- paste0(tab1_tex, "\n", varname, " & ", v1, " & ", v2, " \\\\")
}

tab1_tex <- paste0(tab1_tex, "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Low-wage industries are NAICS 44--45 (Retail), 72 (Accommodation/Food Service), and 56 (Administrative Support). High-wage placebo industries are NAICS 52 (Finance) and 54 (Professional Services). B/W ratios are Black-to-White. Data from QWI race $\\times$ industry files (2005--2023).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Wrote tab1_summary.tex\n")

# ==============================================================================
# Table 2: Main Results — Decomposition
# ==============================================================================
cat("\n=== Table 2: Main Results ===\n")

# Use modelsummary for the main regression table
tab2_models <- list(
  "Earnings Gap" = results$m1_earns,
  "Employment Gap" = results$m1_emp,
  "Wage Bill Gap" = results$m1_wb
)

tab2_tex <- modelsummary(
  tab2_models,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  gof_map = c("nobs", "r.squared"),
  coef_rename = c("log_mw" = "Log Minimum Wage"),
  output = "latex_tabular"
)

# Wrap in table environment manually
tab2_full <- paste0("\\begin{table}[!htbp]\n\\centering\n",
  "\\caption{Minimum Wages and the Black-White Gap in Low-Wage Industries}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  tab2_tex, "\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} State and year-quarter fixed effects included. ",
  "Standard errors clustered at the state level in parentheses. ",
  "Outcomes are log(Black/White) ratios: positive coefficients indicate the gap narrows. ",
  "Low-wage industries: NAICS 44--45, 56, 72. QWI data 2005--2023.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}")

writeLines(tab2_full, "../tables/tab2_main.tex")
cat("Wrote tab2_main.tex\n")

# ==============================================================================
# Table 3: Triple-Difference
# ==============================================================================
cat("\n=== Table 3: Triple-Difference ===\n")

tab3_models <- list(
  "Earnings Gap" = results$m2_earns,
  "Employment Gap" = results$m2_emp,
  "Wage Bill Gap" = results$m2_wb
)

tab3_tex <- modelsummary(
  tab3_models,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  gof_map = c("nobs", "r.squared"),
  coef_rename = c(
    "mw_x_lowwage" = "Log MW $\\times$ Low-Wage",
    "log_mw" = "Log MW"
  ),
  output = "latex_tabular"
)

tab3_full <- paste0("\\begin{table}[!htbp]\n\\centering\n",
  "\\caption{Triple-Difference: Low-Wage vs.\\ High-Wage Industries}\n",
  "\\label{tab:ddd}\n",
  "\\begin{threeparttable}\n",
  tab3_tex, "\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} State $\\times$ industry and year-quarter fixed effects. ",
  "Standard errors clustered at the state level. ",
  "Low-wage: NAICS 44--45, 56, 72. High-wage placebo: NAICS 52, 54. ",
  "Interaction term identifies MW effects specific to low-wage industries.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}")

writeLines(tab3_full, "../tables/tab3_ddd.tex")
cat("Wrote tab3_ddd.tex\n")

# ==============================================================================
# Table 4: Robustness (High-wage placebo + LOSO + bootstrap)
# ==============================================================================
cat("\n=== Table 4: Robustness ===\n")

tab4_models <- list(
  "Placebo: Earnings" = rob_results$placebo_earns,
  "Placebo: Employment" = rob_results$placebo_emp,
  "Placebo: Wage Bill" = rob_results$placebo_wb
)

tab4_tex <- modelsummary(
  tab4_models,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  gof_map = c("nobs", "r.squared"),
  coef_rename = c("log_mw" = "Log Minimum Wage"),
  output = "latex_tabular"
)

tab4_full <- paste0("\\begin{table}[!htbp]\n\\centering\n",
  "\\caption{Placebo Test: High-Wage Industries}\n",
  "\\label{tab:placebo}\n",
  "\\begin{threeparttable}\n",
  tab4_tex, "\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} High-wage industries (NAICS 52, 54) where MW is non-binding. ",
  "State and year-quarter FE; SE clustered at state level.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}")

writeLines(tab4_full, "../tables/tab4_robustness.tex")
cat("Wrote tab4_robustness.tex\n")

# ==============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ==============================================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y)
compute_sde <- function(model, data, yvar, label) {
  beta <- coef(model)["log_mw"]
  se_beta <- se(model)["log_mw"]
  sd_y <- sd(data[[yvar]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  classify <- function(s) {
    if (s > 0.15) return("Large positive")
    if (s > 0.05) return("Moderate positive")
    if (s > 0.005) return("Small positive")
    if (s > -0.005) return("Null")
    if (s > -0.05) return("Small negative")
    if (s > -0.15) return("Moderate negative")
    return("Large negative")
  }

  tibble(
    Outcome = label,
    Beta = sprintf("%.4f", beta),
    SE = sprintf("%.4f", se_beta),
    `SD(Y)` = sprintf("%.4f", sd_y),
    SDE = sprintf("%.4f", sde),
    `SE(SDE)` = sprintf("%.4f", se_sde),
    Classification = classify(sde)
  )
}

sde_panel_a <- bind_rows(
  compute_sde(results$m1_earns, low_wage, "log_earns_ratio", "B/W Earnings Ratio"),
  compute_sde(results$m1_emp, low_wage, "log_emp_ratio", "B/W Employment Ratio"),
  compute_sde(results$m1_wb, low_wage, "log_wage_bill_ratio", "B/W Wage Bill Ratio")
)

# Panel B: Heterogeneity — early vs late treaters (sample splits)
# Early: first treated before 2014; Late: first treated 2014+
early <- low_wage |> filter(first_treat_period > 0, first_treat_period < 8057)  # Before 2014Q2
late <- low_wage |> filter(first_treat_period >= 8057)  # 2014Q2 or later (including never-treated)

m_early <- feols(log_earns_ratio ~ log_mw | state_id + yq_id,
                 data = early, cluster = ~state_fips)
m_late <- feols(log_earns_ratio ~ log_mw | state_id + yq_id,
                data = late, cluster = ~state_fips)

sde_panel_b <- bind_rows(
  compute_sde(m_early, early, "log_earns_ratio", "Early Adopters (pre-2014)"),
  compute_sde(m_late, late, "log_earns_ratio", "Late Adopters (2014+)")
)

# Combine and write LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state minimum wage increases narrow the Black-to-White total labor income gap in low-wage service industries? ",
  "\\textbf{Policy mechanism:} State minimum wage floors raise the wage at the bottom of the earnings distribution where Black workers are disproportionately concentrated, compressing the racial earnings gap---but may simultaneously reduce employment of low-wage workers, partially or fully offsetting earnings gains. ",
  "\\textbf{Outcome definition:} Log ratio of Black-to-White average quarterly earnings (EarnS from QWI), where a positive value indicates the gap narrows. ",
  "\\textbf{Treatment:} Continuous---log real state minimum wage level (dollars per hour). ",
  "\\textbf{Data:} QWI race $\\times$ 3-digit NAICS files, 2005--2023, state-quarter-industry level across 51 states. ",
  "\\textbf{Method:} Two-way fixed effects (state + year-quarter); standard errors clustered at the state level; Callaway-Sant'Anna staggered DiD as primary specification. ",
  "\\textbf{Sample:} Low-wage industries (NAICS 44--45, 56, 72) with positive Black and White employment; state-quarters with non-missing earnings data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0("\\begin{table}[!htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled (Low-Wage Industries)}} \\\\
")

for (i in seq_len(nrow(sde_panel_a))) {
  row <- sde_panel_a[i, ]
  sde_tex <- paste0(sde_tex,
    row$Outcome, " & ", row$Beta, " & ", row$SE, " & ", row$`SD(Y)`,
    " & ", row$SDE, " & ", row$`SE(SDE)`, " & ", row$Classification, " \\\\\n")
}

sde_tex <- paste0(sde_tex, "\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Industry Splits)}} \\\\
")

for (i in seq_len(nrow(sde_panel_b))) {
  row <- sde_panel_b[i, ]
  sde_tex <- paste0(sde_tex,
    row$Outcome, " & ", row$Beta, " & ", row$SE, " & ", row$`SD(Y)`,
    " & ", row$SDE, " & ", row$`SE(SDE)`, " & ", row$Classification, " \\\\\n")
}

sde_tex <- paste0(sde_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("Wrote tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
