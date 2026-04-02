# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# Paper: The Racial Dividend of the Warehouse Boom (apep_1300)
# ==============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
panel <- readRDS("../data/analysis_panel.rds")
treatment <- readRDS("../data/treatment_timing.rds")
pre_sd <- readRDS("../data/pre_treatment_sd.rds")
pre_means <- readRDS("../data/pre_treatment_means.rds")

dir.create("../tables", showWarnings = FALSE)

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================

cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment period summary (2001-2007)
summ_pre <- panel %>%
  filter(year <= 2007) %>%
  group_by(race_group, treated_county) %>%
  summarise(
    mean_emp = round(mean(employment, na.rm = TRUE), 1),
    sd_emp = round(sd(employment, na.rm = TRUE), 1),
    mean_earn = round(mean(avg_earnings, na.rm = TRUE), 0),
    sd_earn = round(sd(avg_earnings, na.rm = TRUE), 0),
    mean_hires = round(mean(hires_all, na.rm = TRUE), 1),
    n_counties = n_distinct(county_fips),
    .groups = "drop"
  ) %>%
  mutate(group = ifelse(treated_county, "FC Counties", "Control Counties"))

# Format for LaTeX
latex_t1 <- "\\begin{table}[t]
\\centering
\\caption{Pre-Treatment Summary Statistics: Warehousing Employment by Race}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{FC Counties} & \\multicolumn{2}{c}{Control Counties} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
& Mean & SD & Mean & SD \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Employment (avg. quarterly workers)}} \\\\[3pt]
"

for (rc in c("All", "White", "Black", "Asian")) {
  row_fc <- summ_pre %>% filter(race_group == rc, treated_county == TRUE)
  row_ctrl <- summ_pre %>% filter(race_group == rc, treated_county == FALSE)

  if (nrow(row_fc) > 0 && nrow(row_ctrl) > 0) {
    latex_t1 <- paste0(latex_t1, sprintf(
      "\\quad %s & %s & %s & %s & %s \\\\\n",
      rc,
      formatC(row_fc$mean_emp, format = "f", digits = 1, big.mark = ","),
      formatC(row_fc$sd_emp, format = "f", digits = 1, big.mark = ","),
      formatC(row_ctrl$mean_emp, format = "f", digits = 1, big.mark = ","),
      formatC(row_ctrl$sd_emp, format = "f", digits = 1, big.mark = ",")
    ))
  }
}

latex_t1 <- paste0(latex_t1, "\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: Average Monthly Earnings (\\$)}} \\\\[3pt]
")

for (rc in c("All", "White", "Black")) {
  row_fc <- summ_pre %>% filter(race_group == rc, treated_county == TRUE)
  row_ctrl <- summ_pre %>% filter(race_group == rc, treated_county == FALSE)

  if (nrow(row_fc) > 0 && nrow(row_ctrl) > 0) {
    latex_t1 <- paste0(latex_t1, sprintf(
      "\\quad %s & %s & %s & %s & %s \\\\\n",
      rc,
      formatC(row_fc$mean_earn, format = "f", digits = 0, big.mark = ","),
      formatC(row_fc$sd_earn, format = "f", digits = 0, big.mark = ","),
      formatC(row_ctrl$mean_earn, format = "f", digits = 0, big.mark = ","),
      formatC(row_ctrl$sd_earn, format = "f", digits = 0, big.mark = ",")
    ))
  }
}

# Add N counties
n_fc <- summ_pre %>% filter(race_group == "All", treated_county == TRUE) %>% pull(n_counties)
n_ctrl <- summ_pre %>% filter(race_group == "All", treated_county == FALSE) %>% pull(n_counties)

latex_t1 <- paste0(latex_t1, sprintf(
  "\\midrule
Counties & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Pre-treatment period: 2001--2007. Employment is average quarterly beginning-of-quarter employment from the Quarterly Workforce Indicators (QWI), NAICS 48--49 (Transportation and Warehousing). Earnings are average monthly earnings. FC counties are those receiving their first Amazon fulfillment center between 1997 and 2016.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  formatC(n_fc, big.mark = ","),
  formatC(n_ctrl, big.mark = ",")
))

writeLines(latex_t1, "../tables/tab1_summary.tex")

# ==============================================================================
# TABLE 2: Main DiD Results — Employment by Race
# ==============================================================================

cat("Generating Table 2: Main Employment Results...\n")

# Extract ATTs
att_all <- results$agg_all
att_black <- results$results_by_race$Black$agg
att_white <- results$results_by_race$White$agg
att_asian <- results$results_by_race$Asian$agg

# TWFE comparison
twfe_all <- results$twfe_all
twfe_black <- results$twfe_black
twfe_white <- results$twfe_white

format_coef <- function(est, se, stars = TRUE) {
  p <- 2 * pnorm(-abs(est / se))
  star <- ""
  if (stars) {
    if (p < 0.01) star <- "***"
    else if (p < 0.05) star <- "**"
    else if (p < 0.10) star <- "*"
  }
  list(
    coef = sprintf("%.4f%s", est, star),
    se = sprintf("(%.4f)", se)
  )
}

# CS estimates
cs_all_fmt <- format_coef(att_all$overall.att, att_all$overall.se)
cs_black_fmt <- format_coef(att_black$overall.att, att_black$overall.se)
cs_white_fmt <- format_coef(att_white$overall.att, att_white$overall.se)
cs_asian_fmt <- format_coef(att_asian$overall.att, att_asian$overall.se)

# TWFE estimates
tw_all_fmt <- format_coef(coef(twfe_all)["post"], se(twfe_all)["post"])
tw_black_fmt <- format_coef(coef(twfe_black)["post"], se(twfe_black)["post"])
tw_white_fmt <- format_coef(coef(twfe_white)["post"], se(twfe_white)["post"])

# Racial dividend: Black ATT minus White ATT
dividend <- att_black$overall.att - att_white$overall.att
dividend_se <- sqrt(att_black$overall.se^2 + att_white$overall.se^2)
div_fmt <- format_coef(dividend, dividend_se)

latex_t2 <- sprintf("\\begin{table}[t]
\\centering
\\caption{Effect of Amazon FC Entry on Warehousing Employment by Race}
\\label{tab:main_results}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& All & White & Black & Asian \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Callaway-Sant'Anna (2021)}} \\\\[3pt]
\\quad ATT & %s & %s & %s & %s \\\\
& %s & %s & %s & %s \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: TWFE}} \\\\[3pt]
\\quad Post $\\times$ Treated & %s & %s & %s & --- \\\\
& %s & %s & %s & \\\\[6pt]
\\midrule
\\multicolumn{5}{l}{\\textit{Panel C: Racial Dividend}} \\\\[3pt]
\\quad Black $-$ White ATT & \\multicolumn{4}{c}{%s} \\\\
& \\multicolumn{4}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is log quarterly employment in NAICS 48--49 (Transportation and Warehousing). Panel A reports Callaway and Sant'Anna (2021) staggered DiD estimates using never-treated counties as controls. Panel B reports standard TWFE with county and year fixed effects. Panel C reports the difference between the Black and White ATTs as a test of the racial dividend hypothesis. Standard errors clustered at the county level in parentheses. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  cs_all_fmt$coef, cs_white_fmt$coef, cs_black_fmt$coef, cs_asian_fmt$coef,
  cs_all_fmt$se, cs_white_fmt$se, cs_black_fmt$se, cs_asian_fmt$se,
  tw_all_fmt$coef, tw_white_fmt$coef, tw_black_fmt$coef,
  tw_all_fmt$se, tw_white_fmt$se, tw_black_fmt$se,
  div_fmt$coef, div_fmt$se
)

writeLines(latex_t2, "../tables/tab2_main_results.tex")

# ==============================================================================
# TABLE 3: Earnings Results
# ==============================================================================

cat("Generating Table 3: Earnings Results...\n")

earn_all <- results$earnings_results$All$agg
earn_black <- results$earnings_results$Black$agg
earn_white <- results$earnings_results$White$agg

e_all_fmt <- format_coef(earn_all$overall.att, earn_all$overall.se)
e_black_fmt <- format_coef(earn_black$overall.att, earn_black$overall.se)
e_white_fmt <- format_coef(earn_white$overall.att, earn_white$overall.se)

# Earnings dividend
earn_div <- earn_black$overall.att - earn_white$overall.att
earn_div_se <- sqrt(earn_black$overall.se^2 + earn_white$overall.se^2)
earn_div_fmt <- format_coef(earn_div, earn_div_se)

# Hires
hires_all <- results$hires_results$All$agg
hires_black <- results$hires_results$Black$agg
hires_white <- results$hires_results$White$agg

h_all_fmt <- format_coef(hires_all$overall.att, hires_all$overall.se)
h_black_fmt <- format_coef(hires_black$overall.att, hires_black$overall.se)
h_white_fmt <- format_coef(hires_white$overall.att, hires_white$overall.se)

latex_t3 <- sprintf("\\begin{table}[t]
\\centering
\\caption{Effect of Amazon FC Entry on Earnings and Hires by Race}
\\label{tab:earnings_hires}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& All & White & Black \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Log Average Monthly Earnings}} \\\\[3pt]
\\quad ATT & %s & %s & %s \\\\
& %s & %s & %s \\\\[3pt]
\\quad Black $-$ White & \\multicolumn{3}{c}{%s} \\\\
& \\multicolumn{3}{c}{%s} \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: Log All Hires}} \\\\[3pt]
\\quad ATT & %s & %s & %s \\\\
& %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Callaway and Sant'Anna (2021) staggered DiD estimates. Panel A: dependent variable is log average monthly earnings in NAICS 48--49. Panel B: dependent variable is log all hires. Never-treated counties as controls. Standard errors clustered at the county level in parentheses. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  e_all_fmt$coef, e_white_fmt$coef, e_black_fmt$coef,
  e_all_fmt$se, e_white_fmt$se, e_black_fmt$se,
  earn_div_fmt$coef, earn_div_fmt$se,
  h_all_fmt$coef, h_white_fmt$coef, h_black_fmt$coef,
  h_all_fmt$se, h_white_fmt$se, h_black_fmt$se
)

writeLines(latex_t3, "../tables/tab3_earnings_hires.tex")

# ==============================================================================
# TABLE 4: Robustness
# ==============================================================================

cat("Generating Table 4: Robustness...\n")

robust <- readRDS("../data/robustness_results.rds")
loco <- robust$loco_results

latex_t4 <- "\\begin{table}[t]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Specification & ATT & SE \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel A: Leave-One-Cohort-Out (All Races)}} \\\\[3pt]
"

for (i in seq_len(nrow(loco))) {
  latex_t4 <- paste0(latex_t4, sprintf(
    "\\quad Drop %d cohort ($n = %d$) & %.4f & (%.4f) \\\\\n",
    loco$dropped_cohort[i], loco$n_dropped[i], loco$att[i], loco$se[i]
  ))
}

latex_t4 <- paste0(latex_t4, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A shows Callaway-Sant'Anna ATT estimates when each treatment cohort is dropped in turn. Dependent variable is log quarterly employment in NAICS 48--49 (all races). Never-treated counties as controls.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(latex_t4, "../tables/tab4_robustness.tex")

# ==============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ==============================================================================

cat("Generating Table F1: SDE...\n")

# Get pre-treatment SDs
sd_all <- pre_sd %>% filter(race_group == "All")
sd_black <- pre_sd %>% filter(race_group == "Black")
sd_white <- pre_sd %>% filter(race_group == "White")

# Compute SDEs for main outcomes
compute_sde <- function(att, se, sd_y) {
  sde <- att / sd_y
  se_sde <- se / sd_y
  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  list(sde = sde, se_sde = se_sde, bucket = bucket)
}

# Panel A: Pooled
sde_emp_all <- compute_sde(results$agg_all$overall.att, results$agg_all$overall.se, sd_all$sd_log_emp)
sde_earn_all <- compute_sde(results$earnings_results$All$agg$overall.att,
                            results$earnings_results$All$agg$overall.se, sd_all$sd_log_earn)
sde_hires_all <- compute_sde(results$hires_results$All$agg$overall.att,
                             results$hires_results$All$agg$overall.se, sd_all$sd_log_hires)

# Panel B: Heterogeneous (Black vs White)
sde_emp_black <- compute_sde(results$results_by_race$Black$agg$overall.att,
                              results$results_by_race$Black$agg$overall.se, sd_black$sd_log_emp)
sde_emp_white <- compute_sde(results$results_by_race$White$agg$overall.att,
                              results$results_by_race$White$agg$overall.se, sd_white$sd_log_emp)

format_sde_row <- function(outcome, beta, se, sd_y, sde_obj) {
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s",
          outcome, beta, se, sd_y, sde_obj$sde, sde_obj$se_sde, sde_obj$bucket)
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does Amazon fulfillment center entry disproportionately increase Black employment and earnings in county-level warehousing labor markets? ",
  "\\textbf{Policy mechanism:} Amazon's staggered opening of large fulfillment centers (typically 500,000--1,200,000 sq ft) in US counties creates discrete demand shocks for logistics workers; these positions require no college degree and draw from a labor pool where Black workers are over-represented (16--22\\% of NAICS 48--49 employment). ",
  "\\textbf{Outcome definition:} Log quarterly beginning-of-quarter employment in NAICS 48--49 (Transportation and Warehousing) from the Census Bureau's Quarterly Workforce Indicators (QWI), disaggregated by race. ",
  "\\textbf{Treatment:} Binary: county receives its first Amazon fulfillment center (staggered, 1997--2016). ",
  "\\textbf{Data:} QWI race panel (county $\\times$ quarter $\\times$ race), NAICS 48--49, 2001--2023; Amazon FC locations from MWPVL International compilation. ",
  sprintf("\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with never-treated controls; standard errors clustered at the county level; %d treated counties, %d+ control counties. ",
    nrow(treatment), n_distinct(panel$county_fips[!panel$treated_county])),
  "\\textbf{Sample:} US counties with non-missing QWI warehousing employment and at least 15 years of panel data; excludes counties with missing race-specific employment throughout. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

latex_sde <- sprintf("\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
%s \\\\
%s \\\\
%s \\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Race)}} \\\\[3pt]
%s \\\\
%s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  format_sde_row("Employment (All)", results$agg_all$overall.att, results$agg_all$overall.se,
                 sd_all$sd_log_emp, sde_emp_all),
  format_sde_row("Earnings (All)", results$earnings_results$All$agg$overall.att,
                 results$earnings_results$All$agg$overall.se, sd_all$sd_log_earn, sde_earn_all),
  format_sde_row("Hires (All)", results$hires_results$All$agg$overall.att,
                 results$hires_results$All$agg$overall.se, sd_all$sd_log_hires, sde_hires_all),
  format_sde_row("Employment (Black)", results$results_by_race$Black$agg$overall.att,
                 results$results_by_race$Black$agg$overall.se, sd_black$sd_log_emp, sde_emp_black),
  format_sde_row("Employment (White)", results$results_by_race$White$agg$overall.att,
                 results$results_by_race$White$agg$overall.se, sd_white$sd_log_emp, sde_emp_white),
  sde_notes
)

writeLines(latex_sde, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
