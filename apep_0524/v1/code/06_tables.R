## ============================================================
## 06_tables.R — Generate all LaTeX tables from saved data
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"
TAB_DIR <- "../tables"
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

## ---- Load saved data ----
sumstats <- fread(file.path(DATA_DIR, "summary_statistics.csv"))
agg_results <- fread(file.path(DATA_DIR, "aggregate_atts.csv"))
twfe_results <- fread(file.path(DATA_DIR, "twfe_results.csv"))
sex_results <- fread(file.path(DATA_DIR, "sex_heterogeneity.csv"))
robustness_table <- fread(file.path(DATA_DIR, "robustness_table.csv"))
ri_results <- fread(file.path(DATA_DIR, "ri_results.csv"))
crown_dates <- fread(file.path(DATA_DIR, "crown_act_dates.csv"))

## Stars helper
add_stars <- function(pval) {
  ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
}

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================

get_val <- function(race, period_str, var) {
  val <- sumstats[race_group == race & period == period_str, get(var)]
  if (length(val) == 0 || is.na(val)) return("---")
  return(val)
}

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Labor Market Outcomes by Race and CROWN Act Status}",
  "\\label{tab:sumstats}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-CROWN Act} & \\multicolumn{2}{c}{Post-CROWN Act} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Black & White & Black & White \\\\",
  "\\midrule",
  sprintf("Employment rate & %.3f & %.3f & %.3f & %.3f \\\\",
    get_val("Black","Pre-CROWN","emp_rate"), get_val("White","Pre-CROWN","emp_rate"),
    get_val("Black","Post-CROWN","emp_rate"), get_val("White","Post-CROWN","emp_rate")),
  sprintf("LFP rate & %.3f & %.3f & %.3f & %.3f \\\\",
    get_val("Black","Pre-CROWN","lfp_rate"), get_val("White","Pre-CROWN","lfp_rate"),
    get_val("Black","Post-CROWN","lfp_rate"), get_val("White","Post-CROWN","lfp_rate")),
  sprintf("Share in professional occ. & %.3f & %.3f & %.3f & %.3f \\\\",
    get_val("Black","Pre-CROWN","share_professional"), get_val("White","Pre-CROWN","share_professional"),
    get_val("Black","Post-CROWN","share_professional"), get_val("White","Post-CROWN","share_professional")),
  sprintf("Share in customer-facing occ. & %.3f & %.3f & %.3f & %.3f \\\\",
    get_val("Black","Pre-CROWN","share_customer_facing"), get_val("White","Pre-CROWN","share_customer_facing"),
    get_val("Black","Post-CROWN","share_customer_facing"), get_val("White","Post-CROWN","share_customer_facing")),
  "\\midrule",
  sprintf("State-year observations & %d & %d & %d & %d \\\\",
    get_val("Black","Pre-CROWN","n_state_years"), get_val("White","Pre-CROWN","n_state_years"),
    get_val("Black","Post-CROWN","n_state_years"), get_val("White","Post-CROWN","n_state_years")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Population-weighted means using ACS 1-Year Summary Tables (2015--2019, 2021--2023). Customer-facing occupations include service and sales/office occupations (SOC groups). Professional occupations include management, business, science, and arts (SOC groups). The 2020 ACS 1-Year was not released by the Census Bureau due to low response rates during COVID-19. Sample: working-age adults (16--64) in 50 states, D.C., and Puerto Rico (52 state-equivalents). The 54 post-CROWN state-year observations are: 2019 cohort (2 states $\\times$ 4 post-years) $+$ 2020 cohort (5 $\\times$ 3) $+$ 2021 cohort (5 $\\times$ 3) $+$ 2022 cohort (6 $\\times$ 2) $+$ 2023 cohort (4 $\\times$ 1) $= 8 + 15 + 15 + 12 + 4 = 54$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(TAB_DIR, "tab1_summary_stats.tex"))
cat("Saved Table 1: Summary statistics\n")

## ============================================================
## TABLE 2: Main Results — CS-DiD and TWFE Triple-Diff
## ============================================================

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{CROWN Act Effects on Black-White Labor Market Gaps}",
  "\\label{tab:main_results}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Employment & Log Median & Professional & Customer-Facing \\\\",
  " & Rate Gap & Earnings Gap & Occ.\\ Share Gap & Occ.\\ Share Gap \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway--Sant'Anna (doubly robust, never-treated control)}} \\\\"
)

tab2_lines <- c(tab2_lines,
  sprintf("ATT & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
    agg_results$att[1], add_stars(agg_results$pval[1]),
    agg_results$att[2], add_stars(agg_results$pval[2]),
    agg_results$att[3], add_stars(agg_results$pval[3]),
    agg_results$att[4], add_stars(agg_results$pval[4])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
    agg_results$se[1], agg_results$se[2], agg_results$se[3], agg_results$se[4]),
  sprintf("95\\%% CI & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\",
    agg_results$ci_lower[1], agg_results$ci_upper[1],
    agg_results$ci_lower[2], agg_results$ci_upper[2],
    agg_results$ci_lower[3], agg_results$ci_upper[3],
    agg_results$ci_lower[4], agg_results$ci_upper[4]),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: TWFE Triple-Diff (state$\\times$year, state$\\times$race, race$\\times$year FEs)}} \\\\"
)

tab2_lines <- c(tab2_lines,
  sprintf("Black $\\times$ CROWN $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
    twfe_results$coef[1], add_stars(twfe_results$pval[1]),
    twfe_results$coef[2], add_stars(twfe_results$pval[2]),
    twfe_results$coef[3], add_stars(twfe_results$pval[3]),
    twfe_results$coef[4], add_stars(twfe_results$pval[4])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
    twfe_results$se[1], twfe_results$se[2], twfe_results$se[3], twfe_results$se[4]),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    format(twfe_results$n_obs[1], big.mark=","),
    format(twfe_results$n_obs[2], big.mark=","),
    format(twfe_results$n_obs[3], big.mark=","),
    format(twfe_results$n_obs[4], big.mark=",")),
  sprintf("Adj.\\ $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
    twfe_results$r2[1], twfe_results$r2[2], twfe_results$r2[3], twfe_results$r2[4]),
  sprintf("Adoption cohorts & %d & %d & %d & %d \\\\",
    agg_results$n_groups[1], agg_results$n_groups[2],
    agg_results$n_groups[3], agg_results$n_groups[4]),
  sprintf("States & %d & %d & %d & %d \\\\",
    agg_results$n_states[1], agg_results$n_states[2],
    agg_results$n_states[3], agg_results$n_states[4]),
  "Clustering & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports Callaway and Sant'Anna (2021) aggregate ATTs using doubly robust estimation with never-treated states as the control group and a universal base period. The gap panel has 416 state-year observations (52 states $\\times$ 8 years). Panel B reports TWFE triple-difference coefficients on Black $\\times$ CROWN State $\\times$ Post with state$\\times$year, state$\\times$race, and race$\\times$year interaction fixed effects; the observation counts refer to the triple-difference panel (state $\\times$ race $\\times$ year, max $52 \\times 8 \\times 2 = 832$). Actual N is below 832 because the Census Bureau suppresses estimates for small-population state-race cells (e.g., Black population in low-population states). Standard errors (in parentheses) clustered at the state level. Adoption cohorts: 5 distinct treatment-timing groups (2019--2023) comprising 22 treated states. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(TAB_DIR, "tab2_main_results.tex"))
cat("Saved Table 2: Main results\n")

## ============================================================
## TABLE 3: Heterogeneity by Sex (CS-DiD)
## ============================================================

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{CROWN Act Effects on Employment Gap by Sex}",
  "\\label{tab:sex_heterogeneity}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Women & Men \\\\",
  " & (1) & (2) \\\\",
  "\\midrule",
  sprintf("CS-DiD ATT & %.4f%s & %.4f%s \\\\",
    sex_results$att[1], add_stars(sex_results$pval[1]),
    sex_results$att[2], add_stars(sex_results$pval[2])),
  sprintf(" & (%.4f) & (%.4f) \\\\",
    sex_results$se[1], sex_results$se[2]),
  sprintf("95\\%% CI & [%.3f, %.3f] & [%.3f, %.3f] \\\\",
    sex_results$ci_lower[1], sex_results$ci_upper[1],
    sex_results$ci_lower[2], sex_results$ci_upper[2]),
  "\\midrule",
  "State-year observations & 416 & 416 \\\\",
  "Treated states & 22 & 22 \\\\",
  sprintf("Adoption cohorts & %d & %d \\\\",
    sex_results$n_groups[1], sex_results$n_groups[2]),
  "Estimator & \\multicolumn{2}{c}{CS-DiD (doubly robust)} \\\\",
  "Control group & \\multicolumn{2}{c}{Never-treated states} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the Callaway--Sant'Anna aggregate ATT on the Black-White employment rate gap for the indicated sex subsample. The dependent variable is the state-level gap between sex-specific Black and White employment rates. Standard errors (in parentheses) are analytically computed. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(TAB_DIR, "tab3_sex_heterogeneity.tex"))
cat("Saved Table 3: Sex heterogeneity\n")

## ============================================================
## TABLE 4: Robustness Checks
## ============================================================

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Outcome & Estimate & S.E. \\\\",
  "\\midrule"
)

outcomes <- c("Emp. gap", "Emp. gap", "Emp. gap (placebo)", "Emp. gap", "Cust.-facing gap")
for (i in seq_len(nrow(robustness_table))) {
  r <- robustness_table[i, ]
  est_str <- ifelse(is.na(r$estimate), "---", sprintf("%.4f%s", r$estimate, r$stars))
  se_str <- ifelse(is.na(r$se), "---", sprintf("(%.4f)", r$se))
  oc <- ifelse(i <= length(outcomes), outcomes[i], "Emp. gap")
  tab4_lines <- c(tab4_lines, sprintf("%s & %s & %s & %s \\\\", r$specification, oc, est_str, se_str))
}

tab4_lines <- c(tab4_lines,
  sprintf("\\midrule\nRandomization inference $p$-value & \\multicolumn{2}{c}{%.3f} \\\\",
    ri_results$ri_pvalue[1]),
  sprintf("Number of permutations & \\multicolumn{2}{c}{%d} \\\\",
    ri_results$n_permutations[1]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Rows 1--4 report effects on the Black-White employment rate gap. Row 5 reports the TWFE triple-difference effect on the customer-facing occupation share gap (the paper's main finding). Row 1: baseline CS-DiD. Row 2: restricted to states adopting CROWN Act after 2020 (excludes early adopters overlapping with COVID onset). Row 3: placebo test replacing Black workers with Asian workers. Rows 4--5: TWFE triple-difference coefficients. The randomization inference $p$-value is based on 494 permutations of CROWN Act treatment assignment. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(TAB_DIR, "tab4_robustness.tex"))
cat("Saved Table 4: Robustness checks\n")

## ============================================================
## TABLE A1: CROWN Act Adoption Dates
## ============================================================

crown_sorted <- crown_dates[order(crown_year, state_name), ]

tab_a1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{CROWN Act Adoption Dates by State}",
  "\\label{tab:crown_dates}",
  "\\begin{tabular}{llc}",
  "\\toprule",
  "State & Effective Date & Adoption Year \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(crown_sorted))) {
  r <- crown_sorted[i, ]
  tab_a1_lines <- c(tab_a1_lines,
    sprintf("%s & %s & %d \\\\", r$state_name, r$crown_effective, r$crown_year))
}

tab_a1_lines <- c(tab_a1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dates compiled from state legislative records. The CROWN Act (Creating a Respectful and Open World for Natural Hair) prohibits employment discrimination based on hair texture and protective hairstyles associated with race. The adoption year determines the treatment cohort in the staggered difference-in-differences design.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab_a1_lines, file.path(TAB_DIR, "tab_a1_crown_dates.tex"))
cat("Saved Table A1: CROWN Act dates\n")

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Files saved to:", TAB_DIR, "\n")
list.files(TAB_DIR) %>% cat(sep = "\n")
