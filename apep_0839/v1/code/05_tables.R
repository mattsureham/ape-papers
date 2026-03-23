# 05_tables.R — Generate all LaTeX tables
# apep_0839: TFP Revision and Food Security

source("00_packages.R")

this_dir <- tryCatch(
  dirname(rstudioapi::getSourceEditorContext()$path),
  error = function(e) {
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("--file=", args, value = TRUE)
    if (length(file_arg) > 0) dirname(sub("--file=", "", file_arg))
    else getwd()
  }
)
setwd(this_dir)

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

load(paste0(data_dir, "main_results.RData"))
load(paste0(data_dir, "robustness_results.RData"))
panel <- fread(paste0(data_dir, "analysis_panel.csv"))

cat("=== GENERATING TABLES: APEP_0839 ===\n\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════
cat("--- Table 1: Summary Statistics ---\n")

panel_clean <- panel[year != 2021]
pre <- panel_clean[post_tfp == 0]
post <- panel_clean[post_tfp == 1]

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Pre-TFP (2014--2019)} & \\multicolumn{2}{c}{Post-TFP (2022--2023)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\hline",
  sprintf("SNAP participation (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(pre$snap_rate_pct), sd(pre$snap_rate_pct),
          mean(post$snap_rate_pct), sd(post$snap_rate_pct)),
  sprintf("Poverty rate (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(pre$poverty_rate_pct), sd(pre$poverty_rate_pct),
          mean(post$poverty_rate_pct), sd(post$poverty_rate_pct)),
  sprintf("Median HH income (\\$) & %s & %s & %s & %s \\\\",
          format(round(mean(pre$median_hh_income)), big.mark = ","),
          format(round(sd(pre$median_hh_income)), big.mark = ","),
          format(round(mean(post$median_hh_income)), big.mark = ","),
          format(round(sd(post$median_hh_income)), big.mark = ",")),
  sprintf("Unemployment rate (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(pre$unemp_rate, na.rm = TRUE), sd(pre$unemp_rate, na.rm = TRUE),
          mean(post$unemp_rate, na.rm = TRUE), sd(post$unemp_rate, na.rm = TRUE)),
  sprintf("Population (000s) & %s & %s & %s & %s \\\\",
          format(round(mean(pre$population) / 1000), big.mark = ","),
          format(round(sd(pre$population) / 1000), big.mark = ","),
          format(round(mean(post$population) / 1000), big.mark = ","),
          format(round(sd(post$population) / 1000), big.mark = ",")),
  "\\hline",
  sprintf("\\multicolumn{5}{l}{\\textit{Treatment dosage (2019 values):}} \\\\"),
  sprintf("SNAP rate, 2019 (\\%%) & \\multicolumn{4}{c}{Mean = %.1f, SD = %.1f, Range = [%.1f, %.1f]} \\\\",
          mean(panel$snap_rate_2019 * 100), sd(panel$snap_rate_2019 * 100),
          min(panel$snap_rate_2019 * 100), max(panel$snap_rate_2019 * 100)),
  sprintf("Early EA-ending states & \\multicolumn{4}{c}{%d of 51 (%.0f\\%%)} \\\\",
          uniqueN(panel[early_ea_end == 1, fips]),
          100 * uniqueN(panel[early_ea_end == 1, fips]) / 51),
  "\\hline",
  sprintf("Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          nrow(pre), nrow(post)),
  sprintf("States & \\multicolumn{4}{c}{%d} \\\\", uniqueN(panel$fips)),
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.9\\textwidth}}{\\footnotesize \\textit{Notes:} Unit of observation is state-year. Pre-TFP period is 2014--2019; post-TFP period is 2022--2023. The ACS 1-year estimates were not released in 2020 due to COVID-19 data collection disruptions. The year 2021, when the TFP revision took partial effect (October 2021), is excluded from main specifications. SNAP participation rate is the share of households receiving SNAP/Food Stamp benefits (ACS Table B22003). Early EA-ending states ended Emergency Allotments before October 2021.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, paste0(tables_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 2: Main Results — Poverty Rate
# ═══════════════════════════════════════════════════════════════
cat("--- Table 2: Main Results (Poverty) ---\n")

# Format coefficient helper
fmt_coef <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  sprintf("%.3f%s", b, stars)
}
fmt_se <- function(model, var) sprintf("(%.3f)", se(model)[var])

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of the TFP Revision on State Poverty Rates}",
  "\\label{tab:poverty}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  paste0("SNAP Rate$_{2019}$ $\\times$ Post & $", fmt_coef(m1, "treat_intensity"), "$ & $",
         fmt_coef(m2, "treat_intensity"), "$ & $",
         fmt_coef(m3, "treat_intensity"), "$ & $",
         fmt_coef(m4, "treat_intensity"), "$ \\\\"),
  paste0(" & $", fmt_se(m1, "treat_intensity"), "$ & $",
         fmt_se(m2, "treat_intensity"), "$ & $",
         fmt_se(m3, "treat_intensity"), "$ & $",
         fmt_se(m4, "treat_intensity"), "$ \\\\"),
  paste0("SNAP Rate$_{2019}$ $\\times$ Partial$_{2021}$ & & & & $",
         fmt_coef(m4, "treat_intensity_partial"), "$ \\\\"),
  paste0(" & & & & $", fmt_se(m4, "treat_intensity_partial"), "$ \\\\"),
  "\\hline",
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "Unemployment control & No & Yes & No & No \\\\",
  "Population weights & No & No & Yes & No \\\\",
  "Include 2021 & No & No & No & Yes \\\\",
  sprintf("Wild bootstrap $p$-value & %.3f & & & \\\\", boot_m1$p_val),
  "\\hline",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(m1), nobs(m2), nobs(m3), nobs(m4)),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          r2(m1, "ar2"), r2(m2, "ar2"), r2(m3, "ar2"), r2(m4, "ar2")),
  "\\hline\\hline",
  paste0("\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} ",
         "Dependent variable is the state poverty rate (\\%). ",
         "Treatment intensity is the interaction of the state's 2019 SNAP household participation rate ",
         "with a post-TFP indicator (= 1 for 2022--2023). ",
         "Column (1) is the baseline specification with state and year fixed effects. ",
         "Column (2) adds the state unemployment rate as a control. ",
         "Column (3) weights by 2019 state population. ",
         "Column (4) includes 2021 with a separate interaction for the partial-treatment year. ",
         "Standard errors clustered by state in parentheses. ",
         "Wild cluster bootstrap (Webb weights, 9,999 draws) $p$-value reported for column (1). ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\"),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2_lines, paste0(tables_dir, "tab2_poverty.tex"))
cat("  Saved tab2_poverty.tex\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 3: Main Results — SNAP Participation
# ═══════════════════════════════════════════════════════════════
cat("--- Table 3: Main Results (SNAP Take-up) ---\n")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of the TFP Revision on SNAP Participation Rates}",
  "\\label{tab:snap}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) \\\\",
  "\\hline",
  paste0("SNAP Rate$_{2019}$ $\\times$ Post & $", fmt_coef(m5, "treat_intensity"), "$ & $",
         fmt_coef(m6, "treat_intensity"), "$ & $",
         fmt_coef(m7, "treat_intensity"), "$ \\\\"),
  paste0(" & $", fmt_se(m5, "treat_intensity"), "$ & $",
         fmt_se(m6, "treat_intensity"), "$ & $",
         fmt_se(m7, "treat_intensity"), "$ \\\\"),
  "\\hline",
  "State FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  "Unemployment control & No & Yes & No \\\\",
  "Population weights & No & No & Yes \\\\",
  sprintf("Wild bootstrap $p$-value & %.3f & & \\\\", boot_m5$p_val),
  "\\hline",
  sprintf("Observations & %d & %d & %d \\\\", nobs(m5), nobs(m6), nobs(m7)),
  sprintf("$R^2$ & %.3f & %.3f & %.3f \\\\", r2(m5, "ar2"), r2(m6, "ar2"), r2(m7, "ar2")),
  "\\hline\\hline",
  paste0("\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} ",
         "Dependent variable is the state SNAP household participation rate (\\%). ",
         "Treatment intensity is the interaction of the state's 2019 SNAP household participation rate ",
         "with a post-TFP indicator (= 1 for 2022--2023). ",
         "Specifications mirror Table \\ref{tab:poverty}. ",
         "Standard errors clustered by state in parentheses. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\"),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, paste0(tables_dir, "tab3_snap.tex"))
cat("  Saved tab3_snap.tex\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 4: Triple-Difference and Event Study
# ═══════════════════════════════════════════════════════════════
cat("--- Table 4: Triple-Difference Results ---\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Triple-Difference: Emergency Allotment Timing and TFP Effects}",
  "\\label{tab:triple}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Poverty Rate} & SNAP Rate \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4}",
  " & (1) & (2) & (3) \\\\",
  "\\hline",
  paste0("SNAP$_{2019}$ $\\times$ Post & $", fmt_coef(m8, "treat_intensity"), "$ & $",
         fmt_coef(m9, "treat_intensity"), "$ & $",
         fmt_coef(m10, "treat_intensity"), "$ \\\\"),
  paste0(" & $", fmt_se(m8, "treat_intensity"), "$ & $",
         fmt_se(m9, "treat_intensity"), "$ & $",
         fmt_se(m10, "treat_intensity"), "$ \\\\"),
  "[6pt]",
  paste0("SNAP$_{2019}$ $\\times$ Post $\\times$ Early EA & $", fmt_coef(m8, "triple_diff"), "$ & $",
         fmt_coef(m9, "triple_diff"), "$ & $",
         fmt_coef(m10, "triple_diff"), "$ \\\\"),
  paste0(" & $", fmt_se(m8, "triple_diff"), "$ & $",
         fmt_se(m9, "triple_diff"), "$ & $",
         fmt_se(m10, "triple_diff"), "$ \\\\"),
  "\\hline",
  "State FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  "Unemployment control & No & Yes & No \\\\",
  "\\hline",
  sprintf("Observations & %d & %d & %d \\\\", nobs(m8), nobs(m9), nobs(m10)),
  sprintf("$R^2$ & %.3f & %.3f & %.3f \\\\", r2(m8, "ar2"), r2(m9, "ar2"), r2(m10, "ar2")),
  "\\hline\\hline",
  paste0("\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} ",
         "Dependent variables are the state poverty rate (columns 1--2) and SNAP participation rate (column 3), both in percentage points. ",
         "``Early EA'' indicates states that ended COVID-19 Emergency Allotments before October 2021, when the TFP revision took effect. ",
         "The triple-interaction tests whether TFP effects are larger in states where SNAP recipients ",
         "experienced the new benefit formula immediately (rather than being topped up to the EA maximum). ",
         "Standard errors clustered by state in parentheses. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\"),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4_lines, paste0(tables_dir, "tab4_triple.tex"))
cat("  Saved tab4_triple.tex\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 5: Robustness
# ═══════════════════════════════════════════════════════════════
cat("--- Table 5: Robustness Checks ---\n")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: Effect on Poverty Rate}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Coefficient & SE \\\\",
  "\\hline",
  "\\textit{Panel A: Main specification} & & \\\\",
  sprintf("\\quad Baseline (Table \\ref{tab:poverty}, col.~1) & $%s$ & $%s$ \\\\",
          fmt_coef(m1, "treat_intensity"), fmt_se(m1, "treat_intensity")),
  "[6pt]",
  "\\textit{Panel B: Alternative dosage} & & \\\\",
  sprintf("\\quad 2019 poverty rate as dosage & $%s$ & $%s$ \\\\",
          fmt_coef(r1, "treat_poverty"), fmt_se(r1, "treat_poverty")),
  "[6pt]",
  "\\textit{Panel C: Placebo (pre-treatment)} & & \\\\",
  sprintf("\\quad Fake treatment at 2019 (2017--2019 only) & $%s$ & $%s$ \\\\",
          fmt_coef(r2_pov, "fake_treat"), fmt_se(r2_pov, "fake_treat")),
  "[6pt]",
  "\\textit{Panel D: Sample restrictions} & & \\\\",
  sprintf("\\quad Trim top/bottom 10\\%% dosage & $%s$ & $%s$ \\\\",
          fmt_coef(r3_pov, "treat_intensity"), fmt_se(r3_pov, "treat_intensity")),
  "[6pt]",
  "\\textit{Panel E: Alternative specification} & & \\\\",
  sprintf("\\quad State-specific linear trends & $%s$ & $%s$ \\\\",
          fmt_coef(r5_pov, "treat_intensity"), fmt_se(r5_pov, "treat_intensity")),
  "[6pt]",
  "\\textit{Panel F: Leave-one-out} & & \\\\",
  sprintf("\\quad Range of coefficients & [%.3f, %.3f] & \\\\",
          min(loo_coefs), max(loo_coefs)),
  "\\hline\\hline",
  paste0("\\multicolumn{3}{p{0.8\\textwidth}}{\\footnotesize \\textit{Notes:} ",
         "Each row reports the coefficient on the treatment intensity variable from a separate regression. ",
         "Panel A reproduces the baseline specification. ",
         "Panel B replaces the 2019 SNAP rate with the 2019 poverty rate as the dosage measure. ",
         "Panel C runs a placebo test restricting to 2017--2019 with a fake treatment at 2019. ",
         "Panel D trims states in the top and bottom 10\\% of the 2019 SNAP rate distribution. ",
         "Panel E adds state-specific linear time trends. ",
         "Panel F reports the range of coefficients from 51 leave-one-out regressions. ",
         "All specifications include state and year fixed effects. ",
         "Standard errors clustered by state. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\"),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab5_lines, paste0(tables_dir, "tab5_robustness.tex"))
cat("  Saved tab5_robustness.tex\n")

# ═══════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ═══════════════════════════════════════════════════════════════
cat("--- Table F1: Standardized Effect Sizes ---\n")

# Compute SDEs for main outcomes
pre_panel <- panel[year <= 2019]
sd_pov <- sd(pre_panel$poverty_rate_pct)
sd_snap <- sd(pre_panel$snap_rate_pct)
sd_income <- sd(pre_panel$ln_median_income, na.rm = TRUE)

# Dosage is continuous: SDE = β × SD(X) / SD(Y)
sd_treat <- sd(panel[year != 2021, treat_intensity])

# Poverty
beta_pov <- coef(m1)["treat_intensity"]
se_pov <- se(m1)["treat_intensity"]
sde_pov <- beta_pov * sd_treat / sd_pov
se_sde_pov <- se_pov * sd_treat / sd_pov

# SNAP
beta_snap <- coef(m5)["treat_intensity"]
se_snap <- se(m5)["treat_intensity"]
sde_snap <- beta_snap * sd_treat / sd_snap
se_sde_snap <- se_snap * sd_treat / sd_snap

# Income
beta_inc <- coef(m_inc)["treat_intensity"]
se_inc <- se(m_inc)["treat_intensity"]
sde_inc <- beta_inc * sd_treat / sd_income
se_sde_inc <- se_inc * sd_treat / sd_income

# Classify SDE
classify_sde <- function(sde_val) {
  abs_sde <- abs(sde_val)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde_val > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde_val > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde_val > 0) return("Large positive") else return("Large negative")
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the 2021 Thrifty Food Plan revision, which permanently increased SNAP benefits by 21 percent, reduce state-level poverty and increase program participation? ",
  "\\textbf{Policy mechanism:} The TFP revision updated the SNAP benefit formula to reflect contemporary dietary guidelines and food prices, raising the maximum monthly benefit by approximately 36 dollars per person; the revision operates through the purchasing power channel, increasing household food budgets for all current and potential SNAP recipients. ",
  "\\textbf{Outcome definition:} Poverty rate is the share of individuals below the federal poverty line from ACS Table B17001; SNAP participation rate is the share of households receiving SNAP benefits from ACS Table B22003; log median household income is from ACS Table B19013. ",
  "\\textbf{Treatment:} Continuous; state-level 2019 SNAP household participation rate interacted with a post-October-2021 indicator, measuring per-capita exposure to the benefit increase. ",
  "\\textbf{Data:} American Community Survey 1-year estimates, 51 states including DC, 2014--2023 excluding 2020, approximately 408 state-year observations. ",
  "\\textbf{Method:} Continuous difference-in-differences with state and year fixed effects; standard errors clustered by state with wild cluster bootstrap. ",
  "\\textbf{Sample:} All 50 states plus DC; 2021 excluded from main specification as a partial-treatment year; ACS 2020 unavailable due to COVID-19 data collection disruption. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the standard deviation of the continuous treatment variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sprintf("Poverty rate (\\%%) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_pov, se_pov, sd_pov, sde_pov, se_sde_pov, classify_sde(sde_pov)),
  sprintf("SNAP participation (\\%%) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_snap, se_snap, sd_snap, sde_snap, se_sde_snap, classify_sde(sde_snap)),
  sprintf("Log median HH income & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_inc, se_inc, sd_income, sde_inc, se_sde_inc, classify_sde(sde_inc)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "\\begin{minipage}{0.95\\textwidth}",
  "{\\footnotesize",
  paste0("\\begin{itemize}[leftmargin=*]"),
  sde_notes,
  "\\end{itemize}}",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tabF1_lines, paste0(tables_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== ALL TABLES GENERATED ===\n")

# Print SDE summary for log
cat("\nSDE Summary:\n")
cat(sprintf("  Poverty: SDE=%.4f (%s)\n", sde_pov, classify_sde(sde_pov)))
cat(sprintf("  SNAP: SDE=%.4f (%s)\n", sde_snap, classify_sde(sde_snap)))
cat(sprintf("  Income: SDE=%.4f (%s)\n", sde_inc, classify_sde(sde_inc)))
