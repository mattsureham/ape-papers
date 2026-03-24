# 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

load("../data/all_models.RData")
estimates <- fromJSON("../data/estimates.json")
robust_est <- fromJSON("../data/robust_estimates.json")
sumstats_raw <- read_csv("../data/sumstats.csv", show_col_types = FALSE)

# Helper: format number with significance stars
fmt <- function(x, digits = 4) formatC(x, format = "f", digits = digits)
stars <- function(beta, se) {
  if (is.na(beta) || is.na(se) || se == 0) return("")
  z <- abs(beta / se)
  p <- 2 * pnorm(-z)
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# ─── Table 1: Summary Statistics ───
tab1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Variable & Mean & Std.\\ Dev. & Min & Max \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Outcomes}} \\\\
Black homeownership rate & %s & %s & %s & %s \\\\
White homeownership rate & %s & %s & %s & %s \\\\
Homeownership gap (B--W)  & %s & %s & %s & %s \\\\
Median home value (\\$) & %s & %s & %s & %s \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: Demographics}} \\\\
Black households & %s & %s & %s & %s \\\\
White households & %s & %s & %s & %s \\\\
Total population & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} N = %s county-year observations from %s counties across 15 years (2009--2023). Data from ACS 5-year estimates. Sample restricted to counties with $\\geq$100 Black households in all years. Black and White homeownership rates defined as owner-occupied units divided by total occupied units for each race.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  fmt(sumstats_raw$black_homeown_rate__mean, 3),
  fmt(sumstats_raw$black_homeown_rate__sd, 3),
  fmt(sumstats_raw$black_homeown_rate__min, 3),
  fmt(sumstats_raw$black_homeown_rate__max, 3),
  fmt(sumstats_raw$white_homeown_rate__mean, 3),
  fmt(sumstats_raw$white_homeown_rate__sd, 3),
  fmt(sumstats_raw$white_homeown_rate__min, 3),
  fmt(sumstats_raw$white_homeown_rate__max, 3),
  fmt(sumstats_raw$homeown_gap__mean, 3),
  fmt(sumstats_raw$homeown_gap__sd, 3),
  fmt(sumstats_raw$homeown_gap__min, 3),
  fmt(sumstats_raw$homeown_gap__max, 3),
  fmt(sumstats_raw$med_hvalueE__mean, 0),
  fmt(sumstats_raw$med_hvalueE__sd, 0),
  fmt(sumstats_raw$med_hvalueE__min, 0),
  fmt(sumstats_raw$med_hvalueE__max, 0),
  fmt(sumstats_raw$black_totalE__mean, 0),
  fmt(sumstats_raw$black_totalE__sd, 0),
  fmt(sumstats_raw$black_totalE__min, 0),
  fmt(sumstats_raw$black_totalE__max, 0),
  fmt(sumstats_raw$white_totalE__mean, 0),
  fmt(sumstats_raw$white_totalE__sd, 0),
  fmt(sumstats_raw$white_totalE__min, 0),
  fmt(sumstats_raw$white_totalE__max, 0),
  fmt(sumstats_raw$total_popE__mean, 0),
  fmt(sumstats_raw$total_popE__sd, 0),
  fmt(sumstats_raw$total_popE__min, 0),
  fmt(sumstats_raw$total_popE__max, 0),
  formatC(nrow(panel), format = "d", big.mark = ","),
  formatC(n_distinct(panel$county_fips), format = "d", big.mark = ",")
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ─── Table 2: Main Results ───
tab2 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Effect of UPHPA on Homeownership Rates}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & (1) & (2) & (3) & (4) & (5) \\\\
 & TWFE & TWFE & TWFE & CS & Triple \\\\
 & Black & White & Gap & Black & Diff \\\\
\\midrule
UPHPA $\\times$ Post & %s%s & %s%s & %s%s & %s%s &  \\\\
 & (%s) & (%s) & (%s) & (%s) &  \\\\[0.5em]
UPHPA $\\times$ Post $\\times$ Black & & & & & %s%s \\\\
 & & & & & (%s) \\\\[0.5em]
\\midrule
County FE & Yes & Yes & Yes & -- & Yes \\\\
Year FE & Yes & Yes & Yes & -- & Yes \\\\
County-Race FE & & & & & Yes \\\\
Race-Year FE & & & & & Yes \\\\
Estimator & TWFE & TWFE & TWFE & CS & TWFE \\\\
Control group & -- & -- & -- & Never & -- \\\\
N & %s & %s & %s & %s & %s \\\\
Counties & %s & %s & %s & %s & %s \\\\
Clusters (states) & %s & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Columns (1)--(3) report TWFE estimates; Column (4) reports the Callaway and Sant'Anna (2021) overall ATT using never-treated counties as controls; Column (5) reports the triple-difference coefficient (UPHPA $\\times$ Post $\\times$ Black). The outcome in Column (3) is the Black--White homeownership gap. The sample includes counties with $\\geq$100 Black households in all years, forming a balanced panel from 2009--2023.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  fmt(estimates$twfe_main$beta), stars(estimates$twfe_main$beta, estimates$twfe_main$se),
  fmt(estimates$twfe_placebo$beta), stars(estimates$twfe_placebo$beta, estimates$twfe_placebo$se),
  fmt(estimates$twfe_gap$beta), stars(estimates$twfe_gap$beta, estimates$twfe_gap$se),
  fmt(estimates$cs_att$beta), stars(estimates$cs_att$beta, estimates$cs_att$se),
  fmt(estimates$twfe_main$se),
  fmt(estimates$twfe_placebo$se),
  fmt(estimates$twfe_gap$se),
  fmt(estimates$cs_att$se),
  fmt(estimates$triple_diff$beta), stars(estimates$triple_diff$beta, estimates$triple_diff$se),
  fmt(estimates$triple_diff$se),
  formatC(twfe_main$nobs, format = "d", big.mark = ","),
  formatC(twfe_placebo$nobs, format = "d", big.mark = ","),
  formatC(twfe_gap$nobs, format = "d", big.mark = ","),
  formatC(twfe_main$nobs, format = "d", big.mark = ","),
  formatC(triple_diff$nobs, format = "d", big.mark = ","),
  formatC(n_distinct(panel$county_fips), format = "d", big.mark = ","),
  formatC(n_distinct(panel$county_fips), format = "d", big.mark = ","),
  formatC(n_distinct(panel$county_fips), format = "d", big.mark = ","),
  formatC(n_distinct(panel$county_fips), format = "d", big.mark = ","),
  formatC(n_distinct(panel$county_fips), format = "d", big.mark = ","),
  formatC(n_distinct(panel$state_fips), format = "d", big.mark = ","),
  formatC(n_distinct(panel$state_fips), format = "d", big.mark = ","),
  formatC(n_distinct(panel$state_fips), format = "d", big.mark = ","),
  formatC(n_distinct(panel$state_fips), format = "d", big.mark = ","),
  formatC(n_distinct(panel$state_fips), format = "d", big.mark = ",")
)

writeLines(tab2, "../tables/tab2_main.tex")

# ─── Table 3: Robustness ───
tab3 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Robustness and Heterogeneity: Black Homeownership Rate}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & $\\hat{\\beta}$ & SE & N & Specification \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Alternative Estimators}} \\\\
TWFE (baseline) & %s%s & %s & %s & County + Year FE \\\\
Callaway--Sant'Anna (never-treated) & %s%s & %s & %s & CS 2021 \\\\
Callaway--Sant'Anna (not-yet-treated) & %s%s & %s & %s & CS 2021 \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: Geographic Heterogeneity}} \\\\
Southern states & %s%s & %s & %s & TWFE \\\\
Non-Southern states & %s%s & %s & %s & TWFE \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel C: Timing Heterogeneity}} \\\\
Early adopters (2011--2017) & %s%s & %s & %s & TWFE \\\\
Late adopters (2018--2023) & %s%s & %s & %s & TWFE \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel D: Population Heterogeneity}} \\\\
High Black HH share & %s%s & %s & %s & TWFE \\\\
Low Black HH share & %s%s & %s & %s & TWFE \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. All regressions include county and year fixed effects. Southern states defined as the former Confederacy plus Kentucky, Oklahoma, and West Virginia. Early adopters enacted UPHPA before the 2018 Farm Bill; late adopters after. High/low Black HH share split at the sample median. Leave-one-out: dropping each treated state, the TWFE coefficient ranges from %s to %s.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  fmt(estimates$twfe_main$beta), stars(estimates$twfe_main$beta, estimates$twfe_main$se),
  fmt(estimates$twfe_main$se),
  formatC(twfe_main$nobs, format = "d", big.mark = ","),
  fmt(estimates$cs_att$beta), stars(estimates$cs_att$beta, estimates$cs_att$se),
  fmt(estimates$cs_att$se),
  formatC(twfe_main$nobs, format = "d", big.mark = ","),
  fmt(robust_est$cs_nyt$beta), stars(robust_est$cs_nyt$beta, robust_est$cs_nyt$se),
  fmt(robust_est$cs_nyt$se),
  formatC(twfe_main$nobs, format = "d", big.mark = ","),
  fmt(robust_est$twfe_south$beta), stars(robust_est$twfe_south$beta, robust_est$twfe_south$se),
  fmt(robust_est$twfe_south$se),
  formatC(robust_est$twfe_south$n, format = "d", big.mark = ","),
  fmt(robust_est$twfe_nonsouth$beta), stars(robust_est$twfe_nonsouth$beta, robust_est$twfe_nonsouth$se),
  fmt(robust_est$twfe_nonsouth$se),
  formatC(robust_est$twfe_nonsouth$n, format = "d", big.mark = ","),
  fmt(robust_est$twfe_early$beta), stars(robust_est$twfe_early$beta, robust_est$twfe_early$se),
  fmt(robust_est$twfe_early$se),
  formatC(robust_est$twfe_early$n, format = "d", big.mark = ","),
  fmt(robust_est$twfe_late$beta), stars(robust_est$twfe_late$beta, robust_est$twfe_late$se),
  fmt(robust_est$twfe_late$se),
  formatC(robust_est$twfe_late$n, format = "d", big.mark = ","),
  fmt(robust_est$twfe_high_black$beta), stars(robust_est$twfe_high_black$beta, robust_est$twfe_high_black$se),
  fmt(robust_est$twfe_high_black$se),
  formatC(robust_est$twfe_high_black$n, format = "d", big.mark = ","),
  fmt(robust_est$twfe_low_black$beta), stars(robust_est$twfe_low_black$beta, robust_est$twfe_low_black$se),
  fmt(robust_est$twfe_low_black$se),
  formatC(robust_est$twfe_low_black$n, format = "d", big.mark = ","),
  fmt(robust_est$loo_min), fmt(robust_est$loo_max)
)

writeLines(tab3, "../tables/tab3_robustness.tex")

# ─── Table 4: Event Study Coefficients ───
es_data <- read_csv("../data/event_study.csv", show_col_types = FALSE)

es_rows <- paste(sapply(1:nrow(es_data), function(i) {
  if (is.na(es_data$se[i])) {
    sprintf("$t%s%d$ & %s & (ref.) \\\\",
            ifelse(es_data$event_time[i] >= 0, "+", ""),
            es_data$event_time[i],
            fmt(es_data$att[i]))
  } else {
    sprintf("$t%s%d$ & %s%s & (%s) \\\\",
            ifelse(es_data$event_time[i] >= 0, "+", ""),
            es_data$event_time[i],
            fmt(es_data$att[i]),
            stars(es_data$att[i], es_data$se[i]),
            fmt(es_data$se[i]))
  }
}), collapse = "\n")

tab4 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Event Study Estimates: Callaway--Sant'Anna Dynamic ATT}
\\label{tab:eventstudy}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Event Time & ATT & SE \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic aggregation. Event time relative to UPHPA enactment year. Never-treated counties as control group. Standard errors clustered at the state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}", es_rows)

writeLines(tab4, "../tables/tab4_eventstudy.tex")

# ─── Table F1: Standardized Effect Sizes ───
classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Pooled SDE
beta_main <- estimates$cs_att$beta
se_main <- estimates$cs_att$se
sde_main <- beta_main / estimates$sd_y_black
se_sde_main <- se_main / estimates$sd_y_black

# Heterogeneity: South vs Non-South (sample splits)
beta_south <- robust_est$twfe_south$beta
se_south <- robust_est$twfe_south$se
sde_south <- beta_south / estimates$sd_y_black
se_sde_south <- se_south / estimates$sd_y_black

beta_nonsouth <- robust_est$twfe_nonsouth$beta
se_nonsouth <- robust_est$twfe_nonsouth$se
sde_nonsouth <- beta_nonsouth / estimates$sd_y_black
se_sde_nonsouth <- se_nonsouth / estimates$sd_y_black

# Triple-diff SDE
beta_triple <- estimates$triple_diff$beta
se_triple <- estimates$triple_diff$se
sd_y_gap_val <- estimates$sd_y_gap
sde_triple <- beta_triple / sd_y_gap_val
se_sde_triple <- se_triple / sd_y_gap_val

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the Uniform Partition of Heirs Property Act (UPHPA), ",
  "which reforms forced partition sales of jointly inherited real estate, ",
  "affect county-level Black homeownership rates? ",
  "\\textbf{Policy mechanism:} UPHPA requires court-ordered appraisals before partition sales, ",
  "grants co-tenants a right of first refusal at appraised value, mandates open-market exposure ",
  "instead of forced auction, and requires courts to consider non-economic value of the property --- ",
  "replacing a default rule that allowed any co-tenant (including speculators who purchased ",
  "fractional interests) to force a below-market liquidation sale. ",
  "\\textbf{Outcome definition:} Black homeownership rate at the county level, defined as ",
  "Black owner-occupied housing units divided by total Black occupied housing units (ACS table B25003B). ",
  "\\textbf{Treatment:} Binary indicator for state-level UPHPA enactment (23 states, staggered 2011--2023). ",
  "\\textbf{Data:} American Community Survey 5-year estimates, county level, 2009--2023, ",
  "balanced panel of counties with at least 100 Black households in all years. ",
  "\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator for pooled ATT; ",
  "TWFE for sample splits; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties with $\\geq$100 Black households in every ACS vintage, ",
  "forming a balanced panel; 15+ never-treated states serve as controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Black homeown.\\ rate (CS ATT) & %s & %s & %s & %s & %s & %s \\\\
Homeown.\\ gap (triple-diff) & %s & %s & %s & %s & %s & %s \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\
Black homeown.\\ rate (South) & %s & %s & %s & %s & %s & %s \\\\
Black homeown.\\ rate (Non-South) & %s & %s & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  fmt(beta_main), fmt(se_main), fmt(estimates$sd_y_black),
  fmt(sde_main), fmt(se_sde_main), classify_sde(sde_main),
  fmt(beta_triple), fmt(se_triple), fmt(sd_y_gap_val),
  fmt(sde_triple), fmt(se_sde_triple), classify_sde(sde_triple),
  fmt(beta_south), fmt(se_south), fmt(estimates$sd_y_black),
  fmt(sde_south), fmt(se_sde_south), classify_sde(sde_south),
  fmt(beta_nonsouth), fmt(se_nonsouth), fmt(estimates$sd_y_black),
  fmt(sde_nonsouth), fmt(se_sde_nonsouth), classify_sde(sde_nonsouth),
  sde_notes
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables written to tables/ directory.\n")
cat("Files: tab1_summary.tex, tab2_main.tex, tab3_robustness.tex, tab4_eventstudy.tex, tabF1_sde.tex\n")
