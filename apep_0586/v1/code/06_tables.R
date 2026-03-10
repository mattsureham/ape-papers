# ==============================================================================
# 06_tables.R — All LaTeX table generation
# apep_0586: Winning the Peace
# ==============================================================================

source("00_packages.R")

# Load results from CSVs
sumstats <- fread("../data/summary_stats.csv")
main_results <- fread("../data/main_results.csv")
pretrend_results <- fread("../data/pretrend_results.csv")
placebo_results <- fread("../data/placebo_results.csv")
het_occ <- fread("../data/heterogeneity_occupation.csv")
het_race <- fread("../data/heterogeneity_race.csv")
het_farm <- fread("../data/heterogeneity_farm.csv")
robustness_summary <- fread("../data/robustness_summary.csv")
state_ag <- fread("../data/state_instrument.csv")

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")
stars <- function(coef, se) {
  t <- abs(coef / se)
  if (t > 2.576) return("$^{***}$")
  if (t > 1.96) return("$^{**}$")
  if (t > 1.645) return("$^{*}$")
  return("")
}

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

cat("Generating Table 1: Summary Statistics\n")

# Reshape for clean presentation
tab1 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics by Cohort Group}
\\label{tab:sumstats}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lccc}
\\toprule
 & Draft-Eligible & Older Control & Age Placebo \\\\
 & (Born 1915--1922) & (Born 1905--1914) & (Born 1895--1904) \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Occupational Outcomes}} \\\\[3pt]
Occupational Score, 1930 & ", fmt(sumstats[cohort_group == "draft_eligible"]$mean_occscore_1930, 1),
" & ", fmt(sumstats[cohort_group == "older_control"]$mean_occscore_1930, 1),
" & ", fmt(sumstats[cohort_group == "age_placebo"]$mean_occscore_1930, 1), " \\\\
 & (", fmt(sumstats[cohort_group == "draft_eligible"]$sd_occscore_1930, 1),
") & (", fmt(sumstats[cohort_group == "older_control"]$sd_occscore_1930, 1),
") & (", fmt(sumstats[cohort_group == "age_placebo"]$sd_occscore_1930, 1), ") \\\\[3pt]
Occupational Score, 1940 & ", fmt(sumstats[cohort_group == "draft_eligible"]$mean_occscore_1940, 1),
" & ", fmt(sumstats[cohort_group == "older_control"]$mean_occscore_1940, 1),
" & ", fmt(sumstats[cohort_group == "age_placebo"]$mean_occscore_1940, 1), " \\\\
 & (", fmt(sumstats[cohort_group == "draft_eligible"]$sd_occscore_1940, 1),
") & (", fmt(sumstats[cohort_group == "older_control"]$sd_occscore_1940, 1),
") & (", fmt(sumstats[cohort_group == "age_placebo"]$sd_occscore_1940, 1), ") \\\\[3pt]
Occupational Score, 1950 & ", fmt(sumstats[cohort_group == "draft_eligible"]$mean_occscore_1950, 1),
" & ", fmt(sumstats[cohort_group == "older_control"]$mean_occscore_1950, 1),
" & ", fmt(sumstats[cohort_group == "age_placebo"]$mean_occscore_1950, 1), " \\\\
 & (", fmt(sumstats[cohort_group == "draft_eligible"]$sd_occscore_1950, 1),
") & (", fmt(sumstats[cohort_group == "older_control"]$sd_occscore_1950, 1),
") & (", fmt(sumstats[cohort_group == "age_placebo"]$sd_occscore_1950, 1), ") \\\\[3pt]
$\\Delta$ OccScore (1940--1950) & ", fmt(sumstats[cohort_group == "draft_eligible"]$mean_delta_occ_40_50, 2),
" & ", fmt(sumstats[cohort_group == "older_control"]$mean_delta_occ_40_50, 2),
" & ", fmt(sumstats[cohort_group == "age_placebo"]$mean_delta_occ_40_50, 2), " \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel B: Demographics (1940)}} \\\\[3pt]
Education (years) & ", fmt(sumstats[cohort_group == "draft_eligible"]$mean_educ_years_1940, 1),
" & ", fmt(sumstats[cohort_group == "older_control"]$mean_educ_years_1940, 1),
" & ", fmt(sumstats[cohort_group == "age_placebo"]$mean_educ_years_1940, 1), " \\\\
White (\\%) & ", fmt(sumstats[cohort_group == "draft_eligible"]$pct_white, 1),
" & ", fmt(sumstats[cohort_group == "older_control"]$pct_white, 1),
" & ", fmt(sumstats[cohort_group == "age_placebo"]$pct_white, 1), " \\\\
Married (\\%) & ", fmt(sumstats[cohort_group == "draft_eligible"]$pct_married, 1),
" & ", fmt(sumstats[cohort_group == "older_control"]$pct_married, 1),
" & ", fmt(sumstats[cohort_group == "age_placebo"]$pct_married, 1), " \\\\
Farm Resident (\\%) & ", fmt(sumstats[cohort_group == "draft_eligible"]$pct_farm, 1),
" & ", fmt(sumstats[cohort_group == "older_control"]$pct_farm, 1),
" & ", fmt(sumstats[cohort_group == "age_placebo"]$pct_farm, 1), " \\\\
In Agriculture (\\%) & ", fmt(sumstats[cohort_group == "draft_eligible"]$pct_in_ag, 1),
" & ", fmt(sumstats[cohort_group == "older_control"]$pct_in_ag, 1),
" & ", fmt(sumstats[cohort_group == "age_placebo"]$pct_in_ag, 1), " \\\\
\\midrule
Observations & ", fmt_int(sumstats[cohort_group == "draft_eligible"]$n),
" & ", fmt_int(sumstats[cohort_group == "older_control"]$n),
" & ", fmt_int(sumstats[cohort_group == "age_placebo"]$n), " \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Standard deviations in parentheses. The sample consists of men linked across the 1930, 1940, and 1950 full-count U.S. Censuses via the IPUMS Machine Learning Panel (MLP) crosswalk. Occupational income scores are from the IPUMS OCCSCORE variable, which assigns 1950 median income values to 1950 occupation codes. Education is coded from the 1940 Census EDUC variable (categorical, converted to approximate years). Draft-eligible men were born 1915--1922 (ages 18--25 in 1940); older control men were born 1905--1914 (ages 26--35 in 1940); age placebo men were born 1895--1904 (ages 36--45 in 1940).
\\end{tablenotes}
\\end{table}")

writeLines(tab1, "../tables/tab1_summary_stats.tex")

# ==============================================================================
# Table 2: Main Results
# ==============================================================================

cat("Generating Table 2: Main Results\n")

mr <- main_results
tab2 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Effect of WWII Mobilization Exposure on Post-War Outcomes}
\\label{tab:main_results}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccccc}
\\toprule
 & (1) & (2) & (3) & (4) & (5) & (6) \\\\
 & $\\Delta$OccScore & $\\Delta$OccScore & $\\Delta$OccScore & $\\Delta$Log Wage & College & Left Ag. \\\\
\\midrule
Mob. Exposure $\\times$ Draft Eligible & ",
fmt(mr[spec=="baseline"]$coef), stars(mr[spec=="baseline"]$coef, mr[spec=="baseline"]$se),
" & ", fmt(mr[spec=="controls"]$coef), stars(mr[spec=="controls"]$coef, mr[spec=="controls"]$se),
" & ", fmt(mr[spec=="mfg_control"]$coef), stars(mr[spec=="mfg_control"]$coef, mr[spec=="mfg_control"]$se),
" & ", fmt(mr[spec=="log_wage"]$coef), stars(mr[spec=="log_wage"]$coef, mr[spec=="log_wage"]$se),
" & ", fmt(mr[spec=="college"]$coef), stars(mr[spec=="college"]$coef, mr[spec=="college"]$se),
" & ", fmt(mr[spec=="left_ag"]$coef), stars(mr[spec=="left_ag"]$coef, mr[spec=="left_ag"]$se), " \\\\
 & (", fmt(mr[spec=="baseline"]$se), ") & (", fmt(mr[spec=="controls"]$se),
") & (", fmt(mr[spec=="mfg_control"]$se), ") & (", fmt(mr[spec=="log_wage"]$se),
") & (", fmt(mr[spec=="college"]$se), ") & (", fmt(mr[spec=="left_ag"]$se), ") \\\\
\\midrule
Individual Controls & No & Yes & Yes & Yes & Yes & Yes \\\\
Mfg. Share $\\times$ Draft & No & No & Yes & No & No & No \\\\
State FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\
Birth Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\
\\midrule
Observations & ", fmt_int(mr[spec=="baseline"]$n),
" & ", fmt_int(mr[spec=="controls"]$n),
" & ", fmt_int(mr[spec=="mfg_control"]$n),
" & ", fmt_int(mr[spec=="log_wage"]$n),
" & ", fmt_int(mr[spec=="college"]$n),
" & ", fmt_int(mr[spec=="left_ag"]$n), " \\\\
$R^2$ & ", fmt(mr[spec=="baseline"]$r2, 3),
" & ", fmt(mr[spec=="controls"]$r2, 3),
" & ", fmt(mr[spec=="mfg_control"]$r2, 3),
" & ", fmt(mr[spec=="log_wage"]$r2, 3),
" & ", fmt(mr[spec=="college"]$r2, 3),
" & ", fmt(mr[spec=="left_ag"]$r2, 3), " \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. Standard errors clustered at the state level in parentheses. The dependent variable in columns (1)--(3) is the change in occupational income score from 1940 to 1950. Column (4) uses the change in log wage income. Column (5) uses an indicator for any college attendance in 1950. Column (6) restricts to men employed in agriculture in 1940 and uses an indicator for leaving agriculture by 1950. Mobilization Exposure is 1 minus the state-level agricultural employment share among men aged 18--44 in 1940, standardized to mean zero and unit variance. Draft Eligible indicates birth cohorts 1915--1922 (ages 18--25 in 1940). Individual controls: 1940 education (years), 1940 occupational score, race (white), marital status, farm residence, and nativity.
\\end{tablenotes}
\\end{table}")

writeLines(tab2, "../tables/tab2_main_results.tex")

# ==============================================================================
# Table 3: Pre-Trend and Placebo Tests
# ==============================================================================

cat("Generating Table 3: Pre-Trend and Placebo Tests\n")

pt <- pretrend_results
pl <- placebo_results

tab3 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Pre-Trend and Placebo Tests}
\\label{tab:pretrend}
\\begin{tabular}{lccc}
\\toprule
 & (1) & (2) & (3) \\\\
 & $\\Delta$OccScore & $\\Delta$OccScore & $\\Delta$OccScore \\\\
 & 1930--1940 & 1930--1940 & 1940--1950 \\\\
 & (Pre-Trend) & (Pre-Trend) & (Age Placebo) \\\\
\\midrule
Mob. Exposure $\\times$ Draft Eligible & ",
fmt(pt[spec=="pretrend_baseline"]$coef), stars(pt[spec=="pretrend_baseline"]$coef, pt[spec=="pretrend_baseline"]$se),
" & ", fmt(pt[spec=="pretrend_controls"]$coef), stars(pt[spec=="pretrend_controls"]$coef, pt[spec=="pretrend_controls"]$se), " & \\\\
 & (", fmt(pt[spec=="pretrend_baseline"]$se), ") & (", fmt(pt[spec=="pretrend_controls"]$se), ") & \\\\[3pt]
Mob. Exposure & & & ",
fmt(pl$coef), stars(pl$coef, pl$se), " \\\\
 & & & (", fmt(pl$se), ") \\\\
\\midrule
Sample & Draft-Elig. + Control & Draft-Elig. + Control & Age Placebo Only \\\\
Individual Controls & No & Yes & No \\\\
State FE & Yes & Yes & Yes \\\\
Birth Year FE & Yes & Yes & Yes \\\\
\\midrule
Observations & ", fmt_int(pt[spec=="pretrend_baseline"]$n),
" & ", fmt_int(pt[spec=="pretrend_controls"]$n),
" & ", fmt_int(pl$n), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. Standard errors clustered at the state level. Columns (1)--(2) test whether WWII mobilization exposure differentially predicted occupational changes for draft-eligible cohorts in the \\textit{pre-war} decade (1930--1940), before the war and GI Bill. A zero coefficient validates the parallel pre-trends assumption. Column (3) tests whether mobilization exposure affected men born 1895--1904 (ages 36--45 in 1940), who had very low draft probability. Individual controls in column (2): 1930 occupational score, race, marital status, farm residence, and nativity.
\\end{tablenotes}
\\end{table}")

writeLines(tab3, "../tables/tab3_pretrend_placebo.tex")

# ==============================================================================
# Table 4: Heterogeneity by Pre-War Characteristics
# ==============================================================================

cat("Generating Table 4: Heterogeneity\n")

tab4 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Heterogeneity in Mobilization Effects by Pre-War Characteristics}
\\label{tab:heterogeneity}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccccccc}
\\toprule
 & \\multicolumn{5}{c}{By Pre-War Occupation Quintile} & \\multicolumn{2}{c}{By Race} & Farm \\\\
\\cmidrule(lr){2-6} \\cmidrule(lr){7-8} \\cmidrule(lr){9-9}
 & Q1 (Low) & Q2 & Q3 & Q4 & Q5 (High) & White & Non-White & Farm \\\\
\\midrule
Mob. Exp. $\\times$ Draft Elig. & ",
paste(sapply(1:nrow(het_occ), function(i)
  paste0(fmt(het_occ$coef[i]), stars(het_occ$coef[i], het_occ$se[i]))),
  collapse = " & "),
" & ",
paste(sapply(1:nrow(het_race), function(i)
  paste0(fmt(het_race$coef[i]), stars(het_race$coef[i], het_race$se[i]))),
  collapse = " & "),
" & ", fmt(het_farm[group == "Farm"]$coef), stars(het_farm[group == "Farm"]$coef, het_farm[group == "Farm"]$se), " \\\\
 & ",
paste(sapply(1:nrow(het_occ), function(i) paste0("(", fmt(het_occ$se[i]), ")")),
  collapse = " & "),
" & ",
paste(sapply(1:nrow(het_race), function(i) paste0("(", fmt(het_race$se[i]), ")")),
  collapse = " & "),
" & (", fmt(het_farm[group == "Farm"]$se), ") \\\\
\\midrule
Observations & ",
paste(sapply(1:nrow(het_occ), function(i) fmt_int(het_occ$n[i])), collapse = " & "),
" & ",
paste(sapply(1:nrow(het_race), function(i) fmt_int(het_race$n[i])), collapse = " & "),
" & ", fmt_int(het_farm[group == "Farm"]$n), " \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. Standard errors clustered at the state level. Each column reports the coefficient on Mobilization Exposure $\\times$ Draft Eligible from the preferred specification (Column 2 of Table~\\ref{tab:main_results}), estimated on the indicated subsample. Pre-war occupation quintiles are based on the distribution of 1940 occupational income scores among men with nonzero scores. Q1 represents the lowest-scoring occupations.
\\end{tablenotes}
\\end{table}")

writeLines(tab4, "../tables/tab4_heterogeneity.tex")

# ==============================================================================
# Table 5: Robustness Summary
# ==============================================================================

cat("Generating Table 5: Robustness Summary\n")

rs <- robustness_summary

tab5 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Robustness of Main Results}
\\label{tab:robustness}
\\begin{tabular}{lccc}
\\toprule
Specification & Coefficient & SE & Observations \\\\
\\midrule
",
paste(sapply(1:nrow(rs), function(i) {
  paste0(rs$test[i], " & ", fmt(rs$coef[i], 4), " & ", fmt(rs$se[i], 4),
         " & ", fmt_int(rs$n[i]), " \\\\")
}), collapse = "\n"),
"
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Each row reports the coefficient on Mobilization Exposure $\\times$ Draft Eligible from a variant of the preferred specification (Column 2 of Table~\\ref{tab:main_results}). ``LOO range'' reports the median coefficient and standard deviation across 48 leave-one-out regressions (one state dropped each time). ``RI p-value'' reports the actual t-statistic and the randomization inference p-value from 1,000 permutations of state-level mobilization exposure.
\\end{tablenotes}
\\end{table}")

writeLines(tab5, "../tables/tab5_robustness.tex")

cat("\nAll tables generated.\n")
