# =============================================================================
# 05_tables.R — Generate all tables for apep_1237
# =============================================================================

source("00_packages.R")

# Load all results
panel <- readRDS("../data/panel.rds")
panel_industry <- readRDS("../data/panel_industry.rds")
treatment <- readRDS("../data/treatment.rds")
first_stage <- readRDS("../data/first_stage.rds")
inst_emp_trend <- readRDS("../data/inst_emp_trend.rds")
es_cont <- readRDS("../data/es_cont.rds")
es_binary <- readRDS("../data/es_binary.rds")
did_static <- readRDS("../data/did_static.rds")
did_static_binary <- readRDS("../data/did_static_binary.rds")
did_earn <- readRDS("../data/did_earn.rds")
sector_results <- readRDS("../data/sector_results.rds")
boot_result <- readRDS("../data/boot_result.rds")
jackknife_coefs <- readRDS("../data/jackknife_coefs.rds")
did_reversal <- readRDS("../data/did_reversal.rds")
first_stage_reg <- readRDS("../data/first_stage_reg.rds")
did_hbcu_states <- readRDS("../data/did_hbcu_states.rds")
did_weighted <- readRDS("../data/did_weighted.rds")

# ---- Table 1: Summary Statistics ----
hbcu_panel <- panel %>% filter(hbcu_county == 1, event_q == -1)
nonhbcu_panel <- panel %>% filter(hbcu_county == 0, event_q == -1)

# Summary stats
hbcu_stats <- hbcu_panel %>%
  summarize(
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    sd_earn = sd(EarnS, na.rm = TRUE),
    n = n()
  )

nonhbcu_stats <- nonhbcu_panel %>%
  summarize(
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    sd_earn = sd(EarnS, na.rm = TRUE),
    n = n()
  )

treat_stats <- treatment %>%
  summarize(
    mean_share = mean(hbcu_share),
    sd_share = sd(hbcu_share),
    min_share = min(hbcu_share),
    max_share = max(hbcu_share),
    mean_enroll = mean(hbcu_enroll_pre),
    n_counties = n()
  )

tab1_tex <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{HBCU Counties} & \\multicolumn{2}{c}{Non-HBCU Counties} \\\\
 \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & Mean & SD & Mean & SD \\\\
\\hline
\\addlinespace
\\multicolumn{5}{l}{\\textit{Panel A: County Characteristics (2012Q2)}} \\\\
\\addlinespace
Total employment & %s & %s & %s & %s \\\\
Avg quarterly earnings (\\$) & %s & %s & %s & %s \\\\
Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%s} \\\\
\\addlinespace
\\multicolumn{5}{l}{\\textit{Panel B: Treatment Intensity (HBCU Counties Only)}} \\\\
\\addlinespace
HBCU enrollment share & %.4f & %.4f & & \\\\
HBCU enrollment (avg 2010--11) & %s & & & \\\\
Number of HBCUs per county & %.1f & & & \\\\
\\addlinespace
\\multicolumn{5}{l}{\\textit{Panel C: HBCU Enrollment Trends}} \\\\
\\addlinespace
Peak enrollment (2011) & \\multicolumn{4}{c}{%s} \\\\
Trough enrollment (2015) & \\multicolumn{4}{c}{%s} \\\\
Decline (\\%%) & \\multicolumn{4}{c}{%.1f} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Panel A reports county-level means and standard deviations in the reference quarter (2012Q2). Employment and earnings are from the Quarterly Workforce Indicators (QWI). Panel B reports the distribution of treatment intensity among HBCU-hosting counties, where HBCU enrollment share is defined as average 2010--2011 total HBCU enrollment divided by average county employment. Panel C reports aggregate HBCU enrollment from IPEDS.
\\end{tablenotes}
\\end{table}",
  format(round(hbcu_stats$mean_emp), big.mark = ","),
  format(round(hbcu_stats$sd_emp), big.mark = ","),
  format(round(nonhbcu_stats$mean_emp), big.mark = ","),
  format(round(nonhbcu_stats$sd_emp), big.mark = ","),
  format(round(hbcu_stats$mean_earn), big.mark = ","),
  format(round(hbcu_stats$sd_earn), big.mark = ","),
  format(round(nonhbcu_stats$mean_earn), big.mark = ","),
  format(round(nonhbcu_stats$sd_earn), big.mark = ","),
  treat_stats$n_counties,
  format(nonhbcu_stats$n, big.mark = ","),
  treat_stats$mean_share, treat_stats$sd_share,
  format(round(treat_stats$mean_enroll), big.mark = ","),
  mean(treatment$n_hbcus),
  format(first_stage$total_enrollment[first_stage$year == 2011], big.mark = ","),
  format(first_stage$total_enrollment[first_stage$year == 2015], big.mark = ","),
  first_stage$pct_change[first_stage$year == 2015]
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ---- Table 2: Main Results ----
tab2_tex <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Effect of HBCU Enrollment Shock on County Employment}
\\label{tab:main}
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{Log Employment} & \\multicolumn{2}{c}{Log Earnings} \\\\
 \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & Continuous & Binary & Continuous & Binary \\\\
 & (1) & (2) & (3) & (4) \\\\
\\hline
\\addlinespace
HBCU Share $\\times$ Post & %.4f & & %.4f & \\\\
 & (%.4f) & & (%.4f) & \\\\
HBCU County $\\times$ Post & & %.4f & & \\\\
 & & (%.4f) & & \\\\
\\addlinespace
\\hline
County FE & Yes & Yes & Yes & Yes \\\\
State $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\
Observations & %s & %s & %s & %s \\\\
Counties & %s & %s & %s & %s \\\\
HBCU counties & %d & %d & %d & %d \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} The dependent variable is log county-level employment (columns 1--2) and log average quarterly earnings (columns 3--4) from QWI, 2008Q1--2016Q4. ``HBCU Share'' is the average 2010--2011 HBCU enrollment divided by average county employment (continuous treatment intensity). ``HBCU County'' is an indicator for counties hosting at least one HBCU (binary treatment). ``Post'' equals one from 2012Q3 onward (PLUS loan credit-standard tightening). All specifications include county and state-by-quarter fixed effects. Standard errors clustered at the state level in parentheses.%s
\\end{tablenotes}
\\end{table}",
  coef(did_static)["hbcu_share:post"],
  coef(did_earn)["hbcu_share:post"],
  se(did_static)["hbcu_share:post"],
  se(did_earn)["hbcu_share:post"],
  coef(did_static_binary)["hbcu_county:post"],
  se(did_static_binary)["hbcu_county:post"],
  format(nobs(did_static), big.mark = ","),
  format(nobs(did_static_binary), big.mark = ","),
  format(nobs(did_earn), big.mark = ","),
  format(nobs(did_static), big.mark = ","),
  format(n_distinct(panel$county_fips), big.mark = ","),
  format(n_distinct(panel$county_fips), big.mark = ","),
  format(n_distinct(panel$county_fips), big.mark = ","),
  format(n_distinct(panel$county_fips), big.mark = ","),
  n_distinct(panel$county_fips[panel$hbcu_county == 1]),
  n_distinct(panel$county_fips[panel$hbcu_county == 1]),
  n_distinct(panel$county_fips[panel$hbcu_county == 1]),
  n_distinct(panel$county_fips[panel$hbcu_county == 1]),
  if (!is.null(boot_result)) sprintf(" Wild cluster bootstrap $p$-value for column (1): %.3f.", boot_result$p_val) else ""
)
writeLines(tab2_tex, "../tables/tab2_main.tex")

# ---- Table 3: Sector-Level Mechanism ----
sector_names <- c("Education\n(NAICS 61)", "Accommodation\n\\& Food (72)",
                   "Retail\n(44--45)", "Agriculture\n(11)", "Mining\n(21)")
sector_keys <- c("education", "food", "retail", "agriculture", "mining")

# Build table rows
sector_coefs <- sapply(sector_keys, function(k) {
  if (is.null(sector_results[[k]])) return(c(NA, NA))
  c(coef(sector_results[[k]])["hbcu_share:post"],
    se(sector_results[[k]])["hbcu_share:post"])
})

tab3_tex <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Sector-Level Effects: Mechanism and Placebo Tests}
\\label{tab:sectors}
\\begin{tabular}{lccccc}
\\hline\\hline
 & Education & Accomm. & Retail & Agriculture & Mining \\\\
 & (NAICS 61) & \\& Food (72) & (44--45) & (11) & (21) \\\\
 & (1) & (2) & (3) & (4) & (5) \\\\
\\hline
\\addlinespace
HBCU Share $\\times$ Post & %.4f & %.4f & %.4f & %.4f & %.4f \\\\
 & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\
\\addlinespace
\\hline
County FE & Yes & Yes & Yes & Yes & Yes \\\\
State $\\times$ Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Each column reports the coefficient on HBCU Share $\\times$ Post from a separate regression where the dependent variable is log sector-level employment from QWI. Columns (1)--(3) test the predicted transmission mechanism: education employment (direct HBCU hiring), accommodation and food services, and retail trade (student spending multiplier). Columns (4)--(5) are placebo sectors with no plausible HBCU spending channel. Standard errors clustered at the state level.
\\end{tablenotes}
\\end{table}",
  sector_coefs[1,1], sector_coefs[1,2], sector_coefs[1,3], sector_coefs[1,4], sector_coefs[1,5],
  sector_coefs[2,1], sector_coefs[2,2], sector_coefs[2,3], sector_coefs[2,4], sector_coefs[2,5]
)
writeLines(tab3_tex, "../tables/tab3_sectors.tex")

# ---- Table 4: Robustness ----
# Extract first-stage regression stats
fs_coef <- coef(first_stage_reg)["hbcu_share"]
fs_se <- summary(first_stage_reg)$coefficients["hbcu_share", "Std. Error"]
fs_r2 <- summary(first_stage_reg)$r.squared
fs_n <- nobs(first_stage_reg)

tab4_tex <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Robustness and First-Stage Evidence}
\\label{tab:robustness}
\\begin{tabular}{lcc}
\\hline\\hline
 & Coefficient & SE \\\\
\\hline
\\addlinespace
\\multicolumn{3}{l}{\\textit{Panel A: County-Level First Stage}} \\\\
\\addlinespace
HBCU Share $\\rightarrow$ $\\Delta$ Enrollment / Employment (2011--2015) & %.4f & (%.4f) \\\\
\\quad $R^2$ = %.3f, $N$ = %d counties & & \\\\
\\addlinespace
\\multicolumn{3}{l}{\\textit{Panel B: Shock vs.\\ Reversal Periods}} \\\\
\\addlinespace
HBCU Share $\\times$ Shock (2012Q3--2014Q2) & %.4f & (%.4f) \\\\
HBCU Share $\\times$ Reversal (2014Q3--2016Q4) & %.4f & (%.4f) \\\\
\\addlinespace
\\multicolumn{3}{l}{\\textit{Panel C: Alternative Samples and Weighting}} \\\\
\\addlinespace
HBCU-hosting states only ($N_{\\text{states}}$ = %d) & %.4f & (%.4f) \\\\
Employment-weighted & %.4f & (%.4f) \\\\
\\addlinespace
\\multicolumn{3}{l}{\\textit{Panel D: Leave-One-State-Out Jackknife}} \\\\
\\addlinespace
Minimum coefficient (drop state) & \\multicolumn{2}{c}{%.4f} \\\\
Maximum coefficient (drop state) & \\multicolumn{2}{c}{%.4f} \\\\
Main estimate & \\multicolumn{2}{c}{%.4f} \\\\
\\addlinespace
\\multicolumn{3}{l}{\\textit{Panel E: Wild Cluster Bootstrap}} \\\\
\\addlinespace
Bootstrap $p$-value & \\multicolumn{2}{c}{%s} \\\\
Bootstrap 95\\%% CI & \\multicolumn{2}{c}{%s} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Panel A reports a county-level OLS regression of the change in HBCU enrollment scaled by pre-period county employment (2011 to 2015) on pre-shock HBCU enrollment share; more-exposed counties experienced larger enrollment-per-employment declines ($p = 0.006$). Panel B splits the post period into the initial shock window and the reversal period. Panel C restricts the sample to the %d states that host at least one HBCU (column 1) and weights by pre-period average county employment (column 2). Panel D reports the range of the main coefficient across specifications that each drop one HBCU-hosting state. Panel E reports wild cluster bootstrap inference with 9,999 Webb weights. All DiD specifications include county and state-by-quarter fixed effects, with standard errors clustered at the state level.
\\end{tablenotes}
\\end{table}",
  fs_coef, fs_se, fs_r2, fs_n,
  coef(did_reversal)["hbcu_share:shock_period"],
  se(did_reversal)["hbcu_share:shock_period"],
  coef(did_reversal)["hbcu_share:reversal_period"],
  se(did_reversal)["hbcu_share:reversal_period"],
  length(unique(panel$state_fips[panel$hbcu_county == 1])),
  coef(did_hbcu_states)["hbcu_share:post"],
  se(did_hbcu_states)["hbcu_share:post"],
  coef(did_weighted)["hbcu_share:post"],
  se(did_weighted)["hbcu_share:post"],
  min(jackknife_coefs),
  max(jackknife_coefs),
  coef(readRDS("../data/did_static.rds"))["hbcu_share:post"],
  if (!is.null(boot_result)) sprintf("%.3f", boot_result$p_val) else "---",
  if (!is.null(boot_result)) sprintf("[%.4f, %.4f]", boot_result$conf_int[1], boot_result$conf_int[2]) else "---",
  length(unique(panel$state_fips[panel$hbcu_county == 1]))
)
writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# ---- Table F1: Standardized Effect Sizes (SDE Appendix) ----
# Compute SDE for main outcomes
did_static <- readRDS("../data/did_static.rds")

# Pre-treatment SD(Y) for each outcome
pre_panel <- panel %>% filter(event_q < 0)
sd_log_emp <- sd(pre_panel$log_emp, na.rm = TRUE)
sd_log_earn <- sd(pre_panel$log_earn, na.rm = TRUE)

# SD of treatment
sd_treatment <- sd(panel$hbcu_share[panel$hbcu_county == 1], na.rm = TRUE)

# Main specification: continuous treatment
beta_emp <- coef(did_static)["hbcu_share:post"]
se_emp <- se(did_static)["hbcu_share:post"]
sde_emp <- beta_emp * sd_treatment / sd_log_emp
se_sde_emp <- se_emp * sd_treatment / sd_log_emp

beta_earn <- coef(readRDS("../data/did_earn.rds"))["hbcu_share:post"]
se_earn_val <- se(readRDS("../data/did_earn.rds"))["hbcu_share:post"]
sde_earn <- beta_earn * sd_treatment / sd_log_earn
se_sde_earn <- se_earn_val * sd_treatment / sd_log_earn

# Sector SDEs
pre_educ <- panel_industry %>% filter(industry == "61", event_q < 0)
sd_log_emp_educ <- sd(pre_educ$log_emp, na.rm = TRUE)
beta_educ <- coef(sector_results$education)["hbcu_share:post"]
se_educ <- se(sector_results$education)["hbcu_share:post"]
sde_educ <- beta_educ * sd_treatment / sd_log_emp_educ
se_sde_educ <- se_educ * sd_treatment / sd_log_emp_educ

pre_food <- panel_industry %>% filter(industry == "72", event_q < 0)
sd_log_emp_food <- sd(pre_food$log_emp, na.rm = TRUE)
beta_food <- coef(sector_results$food)["hbcu_share:post"]
se_food <- se(sector_results$food)["hbcu_share:post"]
sde_food <- beta_food * sd_treatment / sd_log_emp_food
se_sde_food <- se_food * sd_treatment / sd_log_emp_food

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde < 0) return("Small negative") else return("Small positive")
  }
  if (abs_sde < 0.15) {
    if (sde < 0) return("Moderate negative") else return("Moderate positive")
  }
  if (sde < 0) return("Large negative") else return("Large positive")
}

# Heterogeneity: high vs low treatment intensity counties
median_share <- median(treatment$hbcu_share)
panel_high <- panel %>% filter(hbcu_share > median_share | hbcu_county == 0)
panel_low <- panel %>% filter(hbcu_share <= median_share & hbcu_share > 0 | hbcu_county == 0)

did_high <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel_high, cluster = ~state_fips
)
did_low <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel_low, cluster = ~state_fips
)

beta_high <- coef(did_high)["hbcu_share:post"]
se_high <- se(did_high)["hbcu_share:post"]
sde_high <- beta_high * sd_treatment / sd_log_emp
se_sde_high <- se_high * sd_treatment / sd_log_emp

beta_low <- coef(did_low)["hbcu_share:post"]
se_low <- se(did_low)["hbcu_share:post"]
sde_low <- beta_low * sd_treatment / sd_log_emp
se_sde_low <- se_low * sd_treatment / sd_log_emp

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the September 2012 tightening of Parent PLUS loan credit standards---which caused an 11\\% enrollment decline at Historically Black Colleges and Universities---reduce employment in HBCU-hosting counties? ",
  "\\textbf{Policy mechanism:} The Department of Education raised the credit-check bar for Parent PLUS loans, a federal student aid instrument disproportionately used by HBCU families; the resulting enrollment and revenue losses contracted institutional spending and student consumption in host communities. ",
  "\\textbf{Outcome definition:} Log total county quarterly employment from the Quarterly Workforce Indicators (QWI), measuring all private and public employment. ",
  "\\textbf{Treatment:} Continuous---pre-shock (2010--2011) HBCU enrollment share of county employment; SDE uses one-SD increase in treatment intensity. ",
  "\\textbf{Data:} QWI county-quarter panel (2008Q1--2016Q4) merged with IPEDS institutional data; approximately ",
  format(nrow(panel), big.mark = ","), " county-quarter observations across ",
  format(n_distinct(panel$county_fips), big.mark = ","), " counties. ",
  "\\textbf{Method:} Two-way fixed effects event-study DiD with county and state-by-quarter fixed effects; standard errors clustered at the state level; wild cluster bootstrap for inference. ",
  "\\textbf{Sample:} All US counties with non-missing QWI employment data, 2008--2016; treatment intensity varies continuously across approximately ",
  n_distinct(panel$county_fips[panel$hbcu_county == 1]), " HBCU-hosting counties. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-county standard deviation of HBCU enrollment share among treated counties and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\addlinespace
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
\\addlinespace
Total employment & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
Quarterly earnings & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
Education employment & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
Food \\& accommodation emp. & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
\\addlinespace
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits by Treatment Intensity)}} \\\\
\\addlinespace
Total emp. (high HBCU share) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
Total emp. (low HBCU share) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
%s
\\end{tablenotes}
\\end{table}",
  beta_emp, se_emp, sd_log_emp, sde_emp, se_sde_emp, classify_sde(sde_emp),
  beta_earn, se_earn_val, sd_log_earn, sde_earn, se_sde_earn, classify_sde(sde_earn),
  beta_educ, se_educ, sd_log_emp_educ, sde_educ, se_sde_educ, classify_sde(sde_educ),
  beta_food, se_food, sd_log_emp_food, sde_food, se_sde_food, classify_sde(sde_food),
  beta_high, se_high, sd_log_emp, sde_high, se_sde_high, classify_sde(sde_high),
  beta_low, se_low, sd_log_emp, sde_low, se_sde_low, classify_sde(sde_low),
  sde_notes
)
writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

message("All tables generated successfully.")
