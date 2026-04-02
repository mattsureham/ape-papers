## 06_tables.R — V2 Tables (including SDE appendix)

source("00_packages.R")

results <- readRDS("../data/results_v2.rds")
rob_results <- readRDS("../data/robustness_v2.rds")
panel_did <- readRDS("../data/panel_did.rds")

tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

# ================================================================
# Table 1: Summary Statistics
# ================================================================
cat("=== Table 1: Summary Statistics ===\n")

sum_treat <- panel_did[treated == 1, .(
  mean_def = round(mean(n_deficiencies), 2),
  sd_def = round(sd(n_deficiencies), 2),
  mean_obs = round(mean(n_observation), 2),
  mean_doc = round(mean(n_documentation), 2),
  mean_rpt = round(mean(n_report), 2),
  mean_low = round(mean(n_low_severity), 2),
  mean_high = round(mean(n_high_severity), 2),
  mean_infect = round(mean(n_infection), 2),
  n = .N
)]

sum_control <- panel_did[treated == 0, .(
  mean_def = round(mean(n_deficiencies), 2),
  sd_def = round(sd(n_deficiencies), 2),
  mean_obs = round(mean(n_observation), 2),
  mean_doc = round(mean(n_documentation), 2),
  mean_rpt = round(mean(n_report), 2),
  mean_low = round(mean(n_low_severity), 2),
  mean_high = round(mean(n_high_severity), 2),
  mean_infect = round(mean(n_infection), 2),
  n = .N
)]

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Deficiency Citations by Treatment Status}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Treatment & Control \\\\",
  " & (Mandate states, post) & (All other obs.) \\\\",
  "\\midrule",
  sprintf("Total deficiencies & %.2f & %.2f \\\\", sum_treat$mean_def, sum_control$mean_def),
  sprintf(" & (%.2f) & (%.2f) \\\\", sum_treat$sd_def, sum_control$sd_def),
  sprintf("Observation-dependent & %.2f & %.2f \\\\", sum_treat$mean_obs, sum_control$mean_obs),
  sprintf("Documentation-dependent & %.2f & %.2f \\\\", sum_treat$mean_doc, sum_control$mean_doc),
  sprintf("Report-dependent & %.2f & %.2f \\\\", sum_treat$mean_rpt, sum_control$mean_rpt),
  sprintf("Low severity (A--F) & %.2f & %.2f \\\\", sum_treat$mean_low, sum_control$mean_low),
  sprintf("High severity (G--L) & %.2f & %.2f \\\\", sum_treat$mean_high, sum_control$mean_high),
  sprintf("Infection control & %.2f & %.2f \\\\", sum_treat$mean_infect, sum_control$mean_infect),
  "\\midrule",
  sprintf("Observations & %s & %s \\\\",
          formatC(sum_treat$n, format = "d", big.mark = ","),
          formatC(sum_control$n, format = "d", big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "Standard deviations in parentheses. Treatment group: facility-survey observations in mandate states after mandate adoption. Control group: all other observations in non-always-treated states.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tab_dir, "tab1_summary.tex"))
cat("Saved tab1_summary.tex\n")

# ================================================================
# Table 2: Main Results — NY Primary + Pooled Secondary
# ================================================================
cat("=== Table 2: Main Results ===\n")

# Helper to format coefficient
fmt_coef <- function(model, var = "ny_post") {
  if (is.null(model)) return(c("---", ""))
  b <- coef(model)[var]
  se <- sqrt(vcov(model)[var, var])
  p <- 2 * pnorm(-abs(b/se))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  c(sprintf("%.3f%s", b, stars), sprintf("(%.3f)", se))
}

ny <- results$ny
pl <- results$pooled

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Staffing Mandates and Deficiency Citations by Detection Mode}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Total & Observation & Documentation & Report & Infection \\\\",
  " & & dependent & dependent & dependent & control \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: New York (primary specification)}} \\\\[0.3em]",
  paste(c("Mandate", fmt_coef(ny$twfe)[1], fmt_coef(ny$obs)[1],
          fmt_coef(ny$doc)[1], fmt_coef(ny$rpt)[1], fmt_coef(ny$infect)[1]),
        collapse = " & ") %>% paste0(" \\\\"),
  paste(c("", fmt_coef(ny$twfe)[2], fmt_coef(ny$obs)[2],
          fmt_coef(ny$doc)[2], fmt_coef(ny$rpt)[2], fmt_coef(ny$infect)[2]),
        collapse = " & ") %>% paste0(" \\\\[0.5em]"),
  "\\multicolumn{6}{l}{\\textit{Panel B: Pooled (all 6 mandate states)}} \\\\[0.3em]",
  paste(c("Mandate", fmt_coef(pl$twfe, "treated")[1], fmt_coef(pl$obs, "treated")[1],
          fmt_coef(pl$doc, "treated")[1], fmt_coef(pl$rpt, "treated")[1],
          fmt_coef(pl$infect, "treated")[1]),
        collapse = " & ") %>% paste0(" \\\\"),
  paste(c("", fmt_coef(pl$twfe, "treated")[2], fmt_coef(pl$obs, "treated")[2],
          fmt_coef(pl$doc, "treated")[2], fmt_coef(pl$rpt, "treated")[2],
          fmt_coef(pl$infect, "treated")[2]),
        collapse = " & ") %>% paste0(" \\\\"),
  "\\midrule",
  "Facility FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "Panel A: NY Safe Staffing Act (2022); control = never-treated states. Panel B: six mandate states (CT, RI, CA, AZ, WA, NY); control = never-treated, excluding always-treated. Detection taxonomy based on CMS State Operations Manual inspection methodology. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tab_dir, "tab2_main.tex"))
cat("Saved tab2_main.tex\n")

# ================================================================
# Table 3: Severity Decomposition
# ================================================================
cat("=== Table 3: Severity Decomposition ===\n")

sev <- rob_results$severity
ny_sev <- results$ny

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Extra Citations by Severity Level}",
  "\\label{tab:severity}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Minimal (A--C) & Moderate (D--F) & Actual Harm (G--I) & Jeopardy (J--L) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: New York}} \\\\[0.3em]",
  paste(c("Mandate", fmt_coef(ny_sev$low)[1], "---", fmt_coef(ny_sev$high)[1], "---"),
        collapse = " & ") %>% paste0(" \\\\"),
  paste(c("", fmt_coef(ny_sev$low)[2], "", fmt_coef(ny_sev$high)[2], ""),
        collapse = " & ") %>% paste0(" \\\\[0.5em]"),
  "\\multicolumn{5}{l}{\\textit{Panel B: Pooled}} \\\\[0.3em]",
  paste(c("Mandate",
          fmt_coef(sev$minimal, "treated")[1], fmt_coef(sev$moderate, "treated")[1],
          fmt_coef(sev$harm, "treated")[1], fmt_coef(sev$jeopardy, "treated")[1]),
        collapse = " & ") %>% paste0(" \\\\"),
  paste(c("",
          fmt_coef(sev$minimal, "treated")[2], fmt_coef(sev$moderate, "treated")[2],
          fmt_coef(sev$harm, "treated")[2], fmt_coef(sev$jeopardy, "treated")[2]),
        collapse = " & ") %>% paste0(" \\\\"),
  "\\midrule",
  "Facility FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "CMS scope-severity grades: A--C = no actual harm/minimal potential; D--F = no actual harm/potential for more than minimal harm; G--I = actual harm not jeopardy; J--L = immediate jeopardy. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tab_dir, "tab3_severity.tex"))
cat("Saved tab3_severity.tex\n")

# ================================================================
# Table 4: Robustness
# ================================================================
cat("=== Table 4: Robustness ===\n")

base_coef <- coef(results$pooled$twfe)["treated"]
base_se <- sqrt(vcov(results$pooled$twfe)["treated", "treated"])

loo <- rob_results$loo
nocovid <- rob_results$nocovid
fac_cl <- rob_results$fac_cluster

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Coefficient & SE \\\\",
  "\\midrule",
  sprintf("Baseline (pooled TWFE) & %.3f & (%.3f) \\\\", base_coef, base_se),
  sprintf("Excluding COVID (2020Q2--2021Q1) & %.3f & (%.3f) \\\\",
          coef(nocovid)["treated"], sqrt(vcov(nocovid)["treated", "treated"])),
  sprintf("Facility-level clustering & %.3f & (%.3f) \\\\",
          coef(fac_cl)["treated"], sqrt(vcov(fac_cl)["treated", "treated"])),
  sprintf("Leave-one-out range & [%.3f, %.3f] & \\\\",
          min(loo$coef), max(loo$coef)),
  sprintf("Complaint deficiency placebo & %.3f & (%.3f) \\\\",
          coef(rob_results$placebo_complaint)["treated"],
          sqrt(vcov(rob_results$placebo_complaint)["treated", "treated"])),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "All specifications include facility and year fixed effects. Baseline clusters at the state level. Leave-one-out drops each treated state in turn.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tab_dir, "tab4_robustness.tex"))
cat("Saved tab4_robustness.tex\n")

# ================================================================
# Table 5: Heterogeneity
# ================================================================
cat("=== Table 5: Heterogeneity ===\n")

het <- results$het

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Ownership and Size}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Coefficient & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{By ownership type}} \\\\[0.3em]",
  sprintf("For-profit & %.3f & (%.3f) \\\\",
          coef(het$fp)["treated"], sqrt(vcov(het$fp)["treated", "treated"])),
  sprintf("Nonprofit & %.3f & (%.3f) \\\\",
          coef(het$np)["treated"], sqrt(vcov(het$np)["treated", "treated"])),
  "[0.3em]",
  "\\multicolumn{3}{l}{\\textit{By facility size}} \\\\[0.3em]",
  sprintf("Small ($\\leq$60 beds) & %.3f & (%.3f) \\\\",
          coef(het$small)["treated"], sqrt(vcov(het$small)["treated", "treated"])),
  sprintf("Large ($>$120 beds) & %.3f & (%.3f) \\\\",
          coef(het$large)["treated"], sqrt(vcov(het$large)["treated", "treated"])),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "All specifications include facility and year fixed effects, clustered at the state level. Pooled sample (6 mandate states).",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tab_dir, "tab5_heterogeneity.tex"))
cat("Saved tab5_heterogeneity.tex\n")

# ================================================================
# SDE Appendix Table (Required)
# ================================================================
cat("=== SDE Appendix Table ===\n")

diag <- results$diagnostics
ny_coef <- coef(results$ny$twfe)["ny_post"]
ny_se <- sqrt(vcov(results$ny$twfe)["ny_post", "ny_post"])
ny_sd_y <- sd(panel_did$n_deficiencies[panel_did$state != "NY" | panel_did$survey_year < 2022], na.rm = TRUE)
pooled_coef <- coef(results$pooled$twfe)["treated"]
pooled_se <- sqrt(vcov(results$pooled$twfe)["treated", "treated"])
pooled_sd_y <- sd(panel_did$n_deficiencies[panel_did$treated == 0], na.rm = TRUE)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Design Elements}",
  "\\label{tab:sde}",
  "\\begin{tabular}{ll}",
  "\\toprule",
  "Element & Value \\\\",
  "\\midrule",
  "\\multicolumn{2}{l}{\\textit{Design}} \\\\",
  "Method & Staggered DiD (TWFE + Sun-Abraham) \\\\",
  sprintf("Treatment states & %d (primary: NY only) \\\\", diag$n_treatment_states),
  sprintf("Treatment cohorts & %d (2017, 2018, 2019, 2022) \\\\", diag$n_treatment_cohorts),
  sprintf("Control group & Never-treated states (excl. always-treated) \\\\"),
  sprintf("Observations & %s \\\\", formatC(diag$n_obs, format = "d", big.mark = ",")),
  sprintf("Facilities & %s \\\\", formatC(diag$n_facilities, format = "d", big.mark = ",")),
  sprintf("States & %d \\\\", diag$n_states),
  sprintf("Year range & %s \\\\", diag$year_range),
  "[0.3em]",
  "\\multicolumn{2}{l}{\\textit{Primary specification (NY only)}} \\\\",
  sprintf("Point estimate & %.3f \\\\", ny_coef),
  sprintf("Standard error (state cluster) & %.3f \\\\", ny_se),
  sprintf("SD of outcome (control) & %.3f \\\\", ny_sd_y),
  sprintf("SDE (effect / SD) & %.3f \\\\", ny_coef / ny_sd_y),
  "[0.3em]",
  "\\multicolumn{2}{l}{\\textit{Pooled specification (all 6 states)}} \\\\",
  sprintf("Point estimate & %.3f \\\\", pooled_coef),
  sprintf("Standard error (state cluster) & %.3f \\\\", pooled_se),
  sprintf("SD of outcome (control) & %.3f \\\\", pooled_sd_y),
  sprintf("SDE (effect / SD) & %.3f \\\\", pooled_coef / pooled_sd_y),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tab_dir, "tabF1_sde.tex"))
cat("Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
