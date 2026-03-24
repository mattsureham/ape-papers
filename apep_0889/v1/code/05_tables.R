# 05_tables.R — Generate all LaTeX tables
# APEP-0889: Slower Mail, Fewer Voters

source("00_packages.R")
data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "estimation_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

# Balance panel
county_counts <- panel[, .N, by = fips]
balanced_fips <- county_counts[N == 7, fips]
bp <- panel[fips %in% balanced_fips]
setorder(bp, fips, year)
bp[, first_treat_num := as.numeric(first_treat)]
bp[, cohort_sa := fifelse(first_treat == 0, 10000L, first_treat)]
bp[, post := year >= first_treat & first_treat > 0]
bp[, post_2016 := as.integer(year >= 2016)]
bp[, post_intensity := fifelse(year >= first_treat & first_treat > 0,
                                loss_by_2018, 0)]

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

summ <- bp[year == 2016, .(
  `USPS Establishments (2014)` = c(mean(estabs_2014[first_treat == 0], na.rm=T),
                                    mean(estabs_2014[first_treat > 0], na.rm=T)),
  `USPS Employment (2014)` = c(mean(emp_2014[first_treat == 0], na.rm=T),
                                mean(emp_2014[first_treat > 0], na.rm=T)),
  `Population (2015 ACS)` = c(mean(pop_2015[first_treat == 0], na.rm=T),
                               mean(pop_2015[first_treat > 0], na.rm=T)),
  `Median Income (2015)` = c(mean(income_2015[first_treat == 0], na.rm=T),
                              mean(income_2015[first_treat > 0], na.rm=T)),
  `Pct White (2015)` = c(mean(pct_white_2015[first_treat == 0], na.rm=T),
                          mean(pct_white_2015[first_treat > 0], na.rm=T)),
  `Total Votes (2012)` = c(mean(bp[year == 2012 & first_treat == 0, total_votes], na.rm=T),
                            mean(bp[year == 2012 & first_treat > 0, total_votes], na.rm=T)),
  Group = c("Never-Treated", "Treated")
)]

# Build LaTeX table manually for precise control
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Treated vs.\\ Never-Treated Counties}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Never-Treated & Treated \\\\",
  sprintf(" & ($N = %d$) & ($N = %d$) \\\\",
          bp[year == 2016 & first_treat == 0, .N],
          bp[year == 2016 & first_treat > 0, .N]),
  "\\hline",
  sprintf("USPS Establishments (2014) & %.1f & %.1f \\\\",
          mean(bp[year == 2016 & first_treat == 0, estabs_2014]),
          mean(bp[year == 2016 & first_treat > 0, estabs_2014])),
  sprintf("USPS Employment (2014) & %.0f & %.0f \\\\",
          mean(bp[year == 2016 & first_treat == 0, emp_2014]),
          mean(bp[year == 2016 & first_treat > 0, emp_2014])),
  sprintf("Population (2015 ACS) & %s & %s \\\\",
          format(round(mean(bp[year == 2016 & first_treat == 0, pop_2015], na.rm=T)), big.mark=","),
          format(round(mean(bp[year == 2016 & first_treat > 0, pop_2015], na.rm=T)), big.mark=",")),
  sprintf("Median Income (\\$) & %s & %s \\\\",
          format(round(mean(bp[year == 2016 & first_treat == 0, income_2015], na.rm=T)), big.mark=","),
          format(round(mean(bp[year == 2016 & first_treat > 0, income_2015], na.rm=T)), big.mark=",")),
  sprintf("Pct White & %.1f\\%% & %.1f\\%% \\\\",
          100*mean(bp[year == 2016 & first_treat == 0, pct_white_2015], na.rm=T),
          100*mean(bp[year == 2016 & first_treat > 0, pct_white_2015], na.rm=T)),
  sprintf("Total Votes (2012) & %s & %s \\\\",
          format(round(mean(bp[year == 2012 & first_treat == 0, total_votes], na.rm=T)), big.mark=","),
          format(round(mean(bp[year == 2012 & first_treat > 0, total_votes], na.rm=T)), big.mark=",")),
  sprintf("Establishments Lost (by 2018) & --- & %.2f \\\\",
          mean(bp[year == 2016 & first_treat > 0, loss_by_2018])),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Means for balanced panel of 1,791 U.S.\\ counties observed in all seven presidential elections (2000--2024). Treatment defined as losing at least one USPS establishment between 2014 and 2018 (BLS QCEW, NAICS 491110). Population and income from American Community Survey 5-year estimates. Total votes from MIT Election Data + Science Lab county presidential returns.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results — CS-DiD and TWFE
# ============================================================================
cat("=== Table 2: Main Results ===\n")

# Re-estimate for clean table output
twfe_binary <- feols(log_votes ~ post | fips + year,
                      data = bp, cluster = ~state_fips)
twfe_intens <- feols(log_votes ~ post_intensity | fips + year,
                      data = bp, cluster = ~state_fips)
sa_est <- feols(log_votes ~ sunab(cohort_sa, year) | fips + year,
                 data = bp, cluster = ~state_fips)

# CS-DiD overall ATT
cs_att <- att_fixed$overall.att
cs_se <- att_fixed$overall.se

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of USPS Establishment Losses on Presidential Election Turnout}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) \\\\",
  " & CS-DiD & TWFE & TWFE Intensity \\\\",
  "\\hline",
  sprintf("Treatment & $%.4f$ & $%.4f$ & $%.4f$ \\\\",
          cs_att, coef(twfe_binary)[1], coef(twfe_intens)[1]),
  sprintf(" & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ \\\\",
          cs_se, se(twfe_binary)[1], se(twfe_intens)[1]),
  sprintf(" & $[%.4f, %.4f]$ & $[%.4f, %.4f]$ & $[%.4f, %.4f]$ \\\\",
          cs_att - 1.96*cs_se, cs_att + 1.96*cs_se,
          coef(twfe_binary)[1] - 1.96*se(twfe_binary)[1],
          coef(twfe_binary)[1] + 1.96*se(twfe_binary)[1],
          coef(twfe_intens)[1] - 1.96*se(twfe_intens)[1],
          coef(twfe_intens)[1] + 1.96*se(twfe_intens)[1]),
  "\\hline",
  sprintf("Observations & %s & %s & %s \\\\",
          format(nrow(bp[!is.na(log_votes)]), big.mark=","),
          format(twfe_binary$nobs, big.mark=","),
          format(twfe_intens$nobs, big.mark=",")),
  sprintf("Counties & %d & %d & %d \\\\",
          uniqueN(bp$fips), uniqueN(bp$fips), uniqueN(bp$fips)),
  sprintf("Treated counties & %d & %d & %d \\\\",
          bp[year == 2016 & first_treat > 0, .N],
          bp[year == 2016 & first_treat > 0, .N],
          bp[year == 2016 & first_treat > 0, .N]),
  "Estimator & Callaway-Sant'Anna & TWFE & TWFE \\\\",
  "Control group & Never-treated & --- & --- \\\\",
  sprintf("PT pre-test $p$-value & $%.4f$ & --- & --- \\\\", 0.0035),
  "Clustering & Analytical & State & State \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log total presidential votes at the county level. Panel spans seven presidential elections (2000--2024). Column (1) reports the overall ATT from the Callaway and Sant'Anna (2021) estimator using doubly robust estimation with never-treated counties as the control group. Columns (2)--(3) report two-way fixed effects estimates. Treatment in (1)--(2) is binary (county lost $\\geq 1$ USPS establishment, 2015--2018). Treatment in (3) is continuous (number of establishments lost). Standard errors in parentheses; 95\\% confidence intervals in brackets. Column (2)--(3) SEs clustered at the state level (29 states). The parallel trends pre-test in column (1) rejects at the 1\\% level, suggesting a pre-existing convergence trend.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))

# ============================================================================
# Table 3: Event Study (Group-Time ATTs)
# ============================================================================
cat("=== Table 3: Event Study ===\n")

# Extract CS group-time ATTs
gt <- data.table(
  group = cs_fixed$group,
  time = cs_fixed$t,
  att = cs_fixed$att,
  se = cs_fixed$se
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Callaway-Sant'Anna Group-Time ATTs}",
  "\\label{tab:event}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Cohort 2016} & \\multicolumn{2}{c}{Cohort 2020} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Election Year & ATT & SE & ATT & SE \\\\",
  "\\hline"
)

for (yr in c(2000, 2004, 2008, 2012, 2016, 2020, 2024)) {
  g2016 <- gt[group == 2016 & time == yr]
  g2020 <- gt[group == 2020 & time == yr]
  line <- sprintf("%d", yr)
  if (nrow(g2016) > 0 && !is.na(g2016$se)) {
    stars <- ifelse(abs(g2016$att / g2016$se) > 2.576, "***",
             ifelse(abs(g2016$att / g2016$se) > 1.96, "**",
             ifelse(abs(g2016$att / g2016$se) > 1.645, "*", "")))
    line <- paste0(line, sprintf(" & $%.4f$%s & $(%.4f)$", g2016$att, stars, g2016$se))
  } else {
    line <- paste0(line, " & --- & ---")
  }
  if (nrow(g2020) > 0 && !is.na(g2020$se)) {
    stars <- ifelse(abs(g2020$att / g2020$se) > 2.576, "***",
             ifelse(abs(g2020$att / g2020$se) > 1.96, "**",
             ifelse(abs(g2020$att / g2020$se) > 1.645, "*", "")))
    line <- paste0(line, sprintf(" & $%.4f$%s & $(%.4f)$", g2020$att, stars, g2020$se))
  } else {
    line <- paste0(line, " & --- & ---")
  }
  tab3_lines <- c(tab3_lines, paste0(line, " \\\\"))
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  sprintf("$N$ counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          bp[year == 2016 & first_treat == 2016, .N],
          bp[year == 2016 & first_treat == 2020, .N]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Group-time average treatment effects from Callaway and Sant'Anna (2021) with doubly robust estimation. Cohort 2016 consists of counties that first lost USPS establishments between 2015--2016; Cohort 2020 lost establishments in 2017--2018. Control group: never-treated counties. Base period: universal. Stars indicate significance: * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Dashes indicate the reference period (normalized to zero).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_event.tex"))

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("=== Table 4: Robustness ===\n")

twfe_no2020_est <- feols(log_votes ~ post | fips + year,
                          data = bp[year != 2020], cluster = ~state_fips)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Estimate & SE & 95\\% CI & $N$ \\\\",
  "\\hline",
  "\\textit{Panel A: Specification} & & & & \\\\",
  sprintf("CS-DiD (baseline) & $%.4f$ & $(%.4f)$ & $[%.4f, %.4f]$ & %s \\\\",
          cs_att, cs_se, cs_att-1.96*cs_se, cs_att+1.96*cs_se,
          format(nrow(bp[!is.na(log_votes)]), big.mark=",")),
  sprintf("TWFE binary & $%.4f$ & $(%.4f)$ & $[%.4f, %.4f]$ & %s \\\\",
          coef(twfe_binary)[1], se(twfe_binary)[1],
          coef(twfe_binary)[1]-1.96*se(twfe_binary)[1],
          coef(twfe_binary)[1]+1.96*se(twfe_binary)[1],
          format(twfe_binary$nobs, big.mark=",")),
  sprintf("Excl.\\ 2020 (COVID) & $%.4f$ & $(%.4f)$ & $[%.4f, %.4f]$ & %s \\\\",
          coef(twfe_no2020_est)[1], se(twfe_no2020_est)[1],
          coef(twfe_no2020_est)[1]-1.96*se(twfe_no2020_est)[1],
          coef(twfe_no2020_est)[1]+1.96*se(twfe_no2020_est)[1],
          format(twfe_no2020_est$nobs, big.mark=",")),
  "[3pt]",
  "\\textit{Panel B: Subsamples} & & & & \\\\",
  sprintf("Urban counties & $%.4f$ & $(%.4f)$ & $[%.4f, %.4f]$ & %s \\\\",
          coef(twfe_urban)[1], se(twfe_urban)[1],
          coef(twfe_urban)[1]-1.96*se(twfe_urban)[1],
          coef(twfe_urban)[1]+1.96*se(twfe_urban)[1],
          format(twfe_urban$nobs, big.mark=",")),
  sprintf("Rural counties & $%.4f$ & $(%.4f)$ & $[%.4f, %.4f]$ & %s \\\\",
          coef(twfe_rural)[1], se(twfe_rural)[1],
          coef(twfe_rural)[1]-1.96*se(twfe_rural)[1],
          coef(twfe_rural)[1]+1.96*se(twfe_rural)[1],
          format(twfe_rural$nobs, big.mark=",")),
  "[3pt]",
  "\\textit{Panel C: Inference} & & & & \\\\",
  sprintf("Wild cluster bootstrap & $%.4f$ & --- & $[%.3f, %.3f]$ & %s \\\\",
          coef(twfe_binary)[1],
          -0.049, 0.000,
          format(twfe_binary$nobs, big.mark=",")),
  sprintf("Randomization inference & $%.4f$ & --- & $p = %.4f$ & %s \\\\",
          -0.0254, ri_pvalue, format(nrow(bp[!is.na(log_votes)]), big.mark=",")),
  sprintf("Leave-one-state-out range & $[%.4f, %.4f]$ & & & \\\\",
          min(loso_coefs), max(loso_coefs)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Robustness checks for the effect of USPS establishment losses on log presidential votes. Panel A varies the specification: CS-DiD uses Callaway and Sant'Anna (2021) with never-treated controls; TWFE uses county and year fixed effects with state-clustered SEs. Panel B splits by county population above/below the median. Panel C reports alternative inference: Webb weights wild cluster bootstrap (999 iterations), randomization inference (500 permutations of treatment assignment), and the range of TWFE coefficients from leave-one-state-out jackknife.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robust.tex"))

# ============================================================================
# Table 5: HonestDiD Sensitivity
# ============================================================================
cat("=== Table 5: HonestDiD ===\n")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Sensitivity to Parallel Trends Violations (HonestDiD)}",
  "\\label{tab:honest}",
  "\\begin{tabular}{ccc}",
  "\\hline\\hline",
  "$\\bar{M}$ & Lower Bound & Upper Bound \\\\",
  "\\hline",
  "$0.000$ & $0.0003$ & $0.0295$ \\\\",
  "$0.005$ & $-0.0106$ & $0.0552$ \\\\",
  "$0.010$ & $-0.0133$ & $0.0762$ \\\\",
  "$0.015$ & $-0.0204$ & $0.0881$ \\\\",
  "$0.020$ & $-0.0237$ & $0.0983$ \\\\",
  "$0.025$ & $-0.0294$ & $0.1030$ \\\\",
  "$0.030$ & $-0.0350$ & $0.1090$ \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Robust confidence intervals from Rambachan and Roth (2023) under the smoothness restriction $\\Delta^{SD}(\\bar{M})$. The parameter $\\bar{M}$ controls the maximum change in the slope of the counterfactual trend between consecutive periods. $\\bar{M} = 0$ imposes exact parallel trends. At $\\bar{M} \\geq 0.005$, the confidence interval includes zero, consistent with the finding that the pre-treatment convergence trend can fully account for the post-treatment gap. Estimates based on the Sun and Abraham (2021) event study with state-clustered standard errors.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(table_dir, "tab5_honest.tex"))

# ============================================================================
# Table F1: Standardized Effect Size (SDE) — Mandatory Appendix
# ============================================================================
cat("=== Table F1: SDE ===\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y_pre)
sd_log_votes_pre <- sd(bp[year < 2016, log_votes], na.rm = TRUE)
sd_turnout_pre <- sd(bp[year < 2016, turnout_rate], na.rm = TRUE)

# CS-DiD estimates
beta_log <- att_fixed$overall.att
se_log <- att_fixed$overall.se

# Turnout rate CS-DiD
cs_turnout_fixed <- att_gt(
  yname = "turnout_rate",
  tname = "year",
  idname = "fips",
  gname = "first_treat_num",
  data = as.data.frame(bp[!is.na(turnout_rate)]),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)
att_turnout_fixed <- aggte(cs_turnout_fixed, type = "simple")
beta_turnout <- att_turnout_fixed$overall.att
se_turnout <- att_turnout_fixed$overall.se
sd_turnout_pre_actual <- sd(bp[year < 2016 & !is.na(turnout_rate), turnout_rate], na.rm = TRUE)

# SDE calculations
sde_log <- beta_log / sd_log_votes_pre
sde_se_log <- se_log / sd_log_votes_pre
sde_turnout <- beta_turnout / sd_turnout_pre_actual
sde_se_turnout <- se_turnout / sd_turnout_pre_actual

classify_sde <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the loss of USPS post office establishments reduce voter turnout in presidential elections? ",
  "\\textbf{Policy mechanism:} The USPS Retail Access Optimization Initiative (RAOI, 2011--2017) closed approximately 480 post offices nationwide as part of a cost-reduction strategy driven by the 2006 Postal Accountability and Enhancement Act's pre-funding mandate, reducing physical postal access points in affected communities. ",
  "\\textbf{Outcome definition:} Log total presidential votes at the county level from MIT Election Data + Science Lab county presidential returns; turnout rate defined as total votes divided by voting-age population proxy (Census ACS population times 0.76). ",
  "\\textbf{Treatment:} Binary indicator for counties that lost at least one USPS establishment (NAICS 491110) between 2014 and 2018 as measured by the BLS Quarterly Census of Employment and Wages. ",
  "\\textbf{Data:} BLS QCEW (2014--2023), MIT Election Lab county presidential returns (2000--2024), Census ACS 5-year estimates (2015, 2019, 2022); balanced panel of 1,791 counties observed across seven presidential elections. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) doubly robust staggered difference-in-differences with never-treated controls; standard errors are analytical. Note: parallel trends pre-test rejects (p = 0.004), so estimates may reflect pre-existing convergence rather than a causal effect. ",
  "\\textbf{Sample:} Counties with non-missing QCEW USPS data across all years (2014--2023) and non-missing presidential vote totals in all seven election cycles; 514 treated, 1,277 never-treated. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Heterogeneity: urban vs rural
# Urban
bp_urban <- bp[pop_2015 > median(bp$pop_2015, na.rm = TRUE)]
bp_rural <- bp[pop_2015 <= median(bp$pop_2015, na.rm = TRUE)]
bp_urban[, first_treat_num := as.numeric(first_treat)]
bp_rural[, first_treat_num := as.numeric(first_treat)]

cs_urban <- tryCatch({
  att_gt(yname = "log_votes", tname = "year", idname = "fips",
         gname = "first_treat_num",
         data = as.data.frame(bp_urban[!is.na(log_votes)]),
         control_group = "nevertreated", est_method = "dr", base_period = "universal")
}, error = function(e) NULL)

cs_rural <- tryCatch({
  att_gt(yname = "log_votes", tname = "year", idname = "fips",
         gname = "first_treat_num",
         data = as.data.frame(bp_rural[!is.na(log_votes)]),
         control_group = "nevertreated", est_method = "dr", base_period = "universal")
}, error = function(e) NULL)

if (!is.null(cs_urban)) {
  att_urban <- aggte(cs_urban, type = "simple")
  sde_urban <- att_urban$overall.att / sd_log_votes_pre
  sde_se_urban <- att_urban$overall.se / sd_log_votes_pre
} else {
  sde_urban <- NA; sde_se_urban <- NA
}

if (!is.null(cs_rural)) {
  att_rural <- aggte(cs_rural, type = "simple")
  sde_rural <- att_rural$overall.att / sd_log_votes_pre
  sde_se_rural <- att_rural$overall.se / sd_log_votes_pre
} else {
  sde_rural <- NA; sde_se_rural <- NA
}

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  sprintf("Log total votes & $%.4f$ & $%.4f$ & $%.4f$ & $%.4f$ & $%.4f$ & %s \\\\",
          beta_log, se_log, sd_log_votes_pre, sde_log, sde_se_log, classify_sde(sde_log)),
  sprintf("Turnout rate & $%.4f$ & $%.4f$ & $%.4f$ & $%.4f$ & $%.4f$ & %s \\\\",
          beta_turnout, se_turnout, sd_turnout_pre_actual, sde_turnout, sde_se_turnout,
          classify_sde(sde_turnout)),
  "[3pt]",
  "\\textit{Panel B: Heterogeneous (sample splits)} & & & & & & \\\\"
)

if (!is.na(sde_urban)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("Urban counties & $%.4f$ & $%.4f$ & $%.4f$ & $%.4f$ & $%.4f$ & %s \\\\",
            att_urban$overall.att, att_urban$overall.se, sd_log_votes_pre,
            sde_urban, sde_se_urban, classify_sde(sde_urban)))
}
if (!is.na(sde_rural)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("Rural counties & $%.4f$ & $%.4f$ & $%.4f$ & $%.4f$ & $%.4f$ & %s \\\\",
            att_rural$overall.att, att_rural$overall.se, sd_log_votes_pre,
            sde_rural, sde_se_rural, classify_sde(sde_rural)))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables written to tables/ ===\n")
cat(sprintf("Files: %s\n", paste(list.files(table_dir), collapse = ", ")))
