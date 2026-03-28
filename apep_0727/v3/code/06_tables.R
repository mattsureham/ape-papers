## 06_tables.R — Generate LaTeX Tables for V2
## apep_0727 v2: German Solar PV Bunching at 10 kWp Threshold

source("00_packages.R")

cat("Loading results for tables...\n")
period_10 <- fread("../data/bunching_10_by_period.csv")
annual <- fread("../data/bunching_10_annual.csv")
period_30 <- fread("../data/bunching_30_by_period.csv")
period_summary <- fread("../data/period_summary.csv")
poly_dt <- fread("../data/robustness_polynomial.csv")
window_dt <- fread("../data/robustness_windows.csv")
placebo_dt <- fread("../data/robustness_placebo.csv")
module_dt <- fread("../data/mechanism_module_count.csv")
kink_notch <- fread("../data/mechanism_kink_notch.csv")
state_dt <- fread("../data/state_bunching.csv")

fmt <- function(x, ...) format(x, big.mark = ",", ...)

# ============================================================
# TABLE 1: Summary Statistics by Period
# ============================================================

cat("Table 1: Summary statistics...\n")
tab1 <- period_summary[, .(
  Period = c("Pre-FIT (2008--2011)", "FIT Kink (2012--2013)",
             "Surcharge (2014--2020)", "Post-Reform (2021--2024)"),
  N = fmt(n),
  `Mean (kWp)` = sprintf("%.2f", mean_kwp),
  `Median (kWp)` = sprintf("%.2f", median_kwp),
  `Mean Modules` = sprintf("%.1f", mean_modules),
  `Module Pct` = sprintf("%.1f\\%%", pct_modules)
)]

tab1_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Summary Statistics: Rooftop Solar Installations by Policy Period}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n\\toprule\n",
  "Period & N & Mean Capacity & Median Capacity & Mean Modules & Module Data \\\\\n",
  " & & (kWp) & (kWp) & & Coverage \\\\\n",
  "\\midrule\n",
  paste(apply(tab1, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Sample restricted to rooftop installations (Hausdach/Fassade) ",
  "with capacity between 3 and 20 kWp. Data from MaStR (Zenodo snapshot, Feb 2025).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ============================================================
# TABLE 2: Main Bunching Estimates
# ============================================================

cat("Table 2: Main bunching estimates...\n")

tab2_data <- period_10[, .(
  Period = period_label,
  N = fmt(n_installations),
  `Excess Mass` = fmt(excess_mass),
  b = sprintf("%.1f", bunching_ratio),
  SE = sprintf("(%.1f)", se),
  CI = sprintf("[%.1f, %.1f]", ci_lower, ci_upper)
)]

# Add 30 kWp post-reform
tab2_30 <- period_30[period == "4_post_reform"]

tab2_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Bunching Estimates at the 10 kWp Threshold by Policy Period}\n",
  "\\label{tab:bunching}\n",
  "\\begin{tabular}{lrrrcc}\n\\toprule\n",
  "Period & N & Excess Mass & $\\hat{b}$ & SE & 95\\% CI \\\\\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: 10 kWp threshold (rooftop, 3--20 kWp window)}} \\\\\n",
  paste(apply(tab2_data, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\midrule\n",
  sprintf("\\multicolumn{6}{l}{\\textit{Panel B: Difference-in-bunching}} \\\\\n"),
  sprintf("Surcharge $-$ Pre-FIT & & & %.1f & (%.1f) & $t = %.1f$ \\\\\n",
          period_10[period == "3_surcharge", bunching_ratio] - period_10[period == "1_pre_fit_tier", bunching_ratio],
          sqrt(period_10[period == "3_surcharge", se]^2 + period_10[period == "1_pre_fit_tier", se]^2),
          (period_10[period == "3_surcharge", bunching_ratio] - period_10[period == "1_pre_fit_tier", bunching_ratio]) /
            sqrt(period_10[period == "3_surcharge", se]^2 + period_10[period == "1_pre_fit_tier", se]^2)),
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Kleven-Waseem bunching estimates with 7th-degree polynomial counterfactual ",
  "and $[9.0, 11.0)$ kWp exclusion window. Bootstrap standard errors (200 replications). ",
  "$\\hat{b}$ = excess mass / counterfactual density at threshold.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "../tables/tab2_bunching.tex")

# ============================================================
# TABLE 3: Annual Event Study
# ============================================================

cat("Table 3: Annual bunching...\n")

tab3_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Annual Bunching Ratios at 10 kWp, 2008--2024}\n",
  "\\label{tab:annual}\n",
  "\\begin{tabular}{lcrrrr}\n\\toprule\n",
  "Year & Phase & $\\hat{b}$ & Excess Mass & $N_{9.9}$ & $N_{10.1}$ \\\\\n",
  "\\midrule\n"
)

phase_map <- c("2008" = "Pre-FIT", "2009" = "Pre-FIT", "2010" = "Pre-FIT", "2011" = "Pre-FIT",
               "2012" = "FIT kink", "2013" = "FIT kink",
               "2014" = "Surcharge", "2015" = "Surcharge", "2016" = "Surcharge",
               "2017" = "Surcharge", "2018" = "Surcharge", "2019" = "Surcharge", "2020" = "Surcharge",
               "2021" = "Post-reform", "2022" = "Post-reform", "2023" = "Post-reform", "2024" = "Post-reform")

for (i in 1:nrow(annual)) {
  r <- annual[i]
  phase <- phase_map[as.character(r$year)]
  tab3_tex <- paste0(tab3_tex,
    sprintf("%d & %s & %.1f & %s & %s & %s \\\\\n",
            r$year, phase, r$bunching_ratio, fmt(r$excess_mass),
            fmt(r$n_99), fmt(r$n_101)))
  if (r$year %in% c(2011, 2013, 2020)) {
    tab3_tex <- paste0(tab3_tex, "\\midrule\n")
  }
}

tab3_tex <- paste0(tab3_tex,
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Bunching ratio ($\\hat{b}$) estimated using Kleven-Waseem ",
  "methodology (polynomial degree 7, $[9.0, 11.0)$ exclusion window). ",
  "$N_{9.9}$ and $N_{10.1}$ are raw bin counts at 9.9 and 10.1 kWp.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "../tables/tab3_annual.tex")

# ============================================================
# TABLE 4: Mechanism Evidence
# ============================================================

cat("Table 4: Mechanism evidence...\n")

tab4_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Mechanism Evidence: Kink--Notch Decomposition and Module Counts}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{tabular}{lcc}\n\\toprule\n",
  " & Bunching Ratio & \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Kink vs.\\ Notch Decomposition}} \\\\\n",
  sprintf("2011 (no threshold) & %.1f & \\\\\n", kink_notch[year == 2011, bunching_ratio]),
  sprintf("2012 (FIT kink introduced) & %.1f & \\\\\n", kink_notch[year == 2012, bunching_ratio]),
  sprintf("2013 (FIT kink, full year) & %.1f & \\\\\n", kink_notch[year == 2013, bunching_ratio]),
  sprintf("2014 (surcharge notch added) & %.1f & \\\\\n", kink_notch[year == 2014, bunching_ratio]),
  sprintf("2015 (full notch response) & %.1f & \\\\\n", kink_notch[year == 2015, bunching_ratio]),
  "\\midrule\n",
  sprintf("Kink contribution (2013 $-$ 2011) & %.1f & \\\\\n",
          kink_notch[year == 2013, bunching_ratio] - kink_notch[year == 2011, bunching_ratio]),
  sprintf("Notch contribution (2014 $-$ 2013) & %.1f & \\\\\n",
          kink_notch[year == 2014, bunching_ratio] - kink_notch[year == 2013, bunching_ratio]),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Module Counts Near Threshold (Surcharge Period)}} \\\\\n",
  " & Median Modules & N \\\\\n",
  "\\midrule\n"
)

# Add module count rows for key bins
for (b in c(90, 95, 96, 97, 98, 99, 100, 101, 102, 105, 110)) {
  row <- module_dt[bin_int == b]
  if (nrow(row) > 0) {
    tab4_tex <- paste0(tab4_tex,
      sprintf("%.1f kWp & %.0f & %s \\\\\n",
              b / 10, row$median_modules, fmt(row$n)))
  }
}

tab4_tex <- paste0(tab4_tex,
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Panel A shows the transition from no threshold (2011) to FIT kink (2012--2013) ",
  "to surcharge notch (2014+). Panel B shows median solar module count by 0.1 kWp bin ",
  "during the surcharge period (rooftop installations, 2014--2020).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "../tables/tab4_mechanism.tex")

# ============================================================
# TABLE 5: Robustness
# ============================================================

cat("Table 5: Robustness...\n")

tab5_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Robustness: Polynomial Degree, Exclusion Window, and Placebo Tests}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n\\toprule\n",
  "Specification & $\\hat{b}$ & Excess Mass \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Polynomial Degree}} \\\\\n"
)

for (i in 1:nrow(poly_dt)) {
  r <- poly_dt[i]
  tab5_tex <- paste0(tab5_tex,
    sprintf("Degree %d & %.1f & %s \\\\\n", r$poly_degree, r$bunching_ratio, fmt(r$excess_mass)))
}

tab5_tex <- paste0(tab5_tex,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Exclusion Window}} \\\\\n"
)

for (i in 1:nrow(window_dt)) {
  r <- window_dt[i]
  tab5_tex <- paste0(tab5_tex,
    sprintf("%s kWp & %.1f & %s \\\\\n", r$excl_window, r$bunching_ratio, fmt(r$excess_mass)))
}

tab5_tex <- paste0(tab5_tex,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Placebo Thresholds (Surcharge Period)}} \\\\\n"
)

for (i in 1:nrow(placebo_dt)) {
  r <- placebo_dt[i]
  tab5_tex <- paste0(tab5_tex,
    sprintf("%.0f kWp & %.1f & %s \\\\\n", r$placebo_kwp, r$bunching_ratio, fmt(r$excess_mass)))
}

tab5_tex <- paste0(tab5_tex,
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} All estimates for the surcharge period (2014--2020), rooftop installations. ",
  "Baseline: polynomial degree 7, $[9.0, 11.0)$ kWp exclusion window. ",
  "Placebo estimates apply the same methodology at non-threshold capacity points.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab5_tex, "../tables/tab5_robustness.tex")

# ============================================================
# SDE TABLE (Required)
# ============================================================

cat("Table F1: SDE appendix...\n")

sde_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  "Outcome & Estimate & Unit & SD & SDE \\\\\n",
  "\\midrule\n",
  sprintf("Bunching ratio (surcharge) & %.1f & ratio & --- & --- \\\\\n",
          period_10[period == "3_surcharge", bunching_ratio]),
  sprintf("DiB (surcharge $-$ pre) & %.1f & ratio & --- & --- \\\\\n",
          period_10[period == "3_surcharge", bunching_ratio] - period_10[period == "1_pre_fit_tier", bunching_ratio]),
  sprintf("Excess mass & %s & installations & --- & --- \\\\\n",
          fmt(period_10[period == "3_surcharge", excess_mass])),
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Bunching estimates do not have a natural standard-deviation ",
  "denominator. The bunching ratio $\\hat{b}$ expresses excess mass relative to the ",
  "counterfactual density at the threshold. The DiB nets out pre-policy bunching.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated:\n")
cat(paste(" ", list.files("../tables/"), collapse = "\n"), "\n")
