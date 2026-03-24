# 05_tables.R — Generate all tables for apep_0847

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")
tab_dir  <- file.path(dirname(getwd()), "tables")
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

main_results   <- readRDS(file.path(data_dir, "main_results.rds"))
robust_results <- readRDS(file.path(data_dir, "robust_results.rds"))
smoking_panel  <- readRDS(file.path(data_dir, "smoking_panel.rds"))
quits_panel    <- readRDS(file.path(data_dir, "quits_panel.rds"))
copd_panel     <- readRDS(file.path(data_dir, "copd_panel.rds"))
placebo_panel  <- readRDS(file.path(data_dir, "placebo_panel.rds"))
baseline       <- readRDS(file.path(data_dir, "grants_baseline.rds"))

# ========== TABLE 1: Summary Statistics ==========
cat("Generating Table 1: Summary Statistics\n")

med_grant <- median(baseline$baseline_pc)

# Pre-period (2011-2014) by grant group
pre_smoking <- smoking_panel %>%
  filter(year_start <= 2014) %>%
  mutate(group = ifelse(baseline_pc > med_grant, "Above Median", "Below Median"))

pre_quits <- quits_panel %>%
  filter(year_start <= 2014) %>%
  mutate(group = ifelse(baseline_pc > med_grant, "Above Median", "Below Median"))

pre_copd <- copd_panel %>%
  filter(year_start <= 2014) %>%
  mutate(group = ifelse(baseline_pc > med_grant, "Above Median", "Below Median"))

stats_smoking <- pre_smoking %>%
  group_by(group) %>%
  summarise(mean = mean(value, na.rm = TRUE), sd = sd(value, na.rm = TRUE),
            n = n_distinct(area_code), .groups = "drop")

stats_quits <- pre_quits %>%
  group_by(group) %>%
  summarise(mean = mean(value, na.rm = TRUE), sd = sd(value, na.rm = TRUE),
            n = n_distinct(area_code), .groups = "drop")

stats_copd <- pre_copd %>%
  group_by(group) %>%
  summarise(mean = mean(value, na.rm = TRUE), sd = sd(value, na.rm = TRUE),
            n = n_distinct(area_code), .groups = "drop")

# Grant stats
grant_stats <- baseline %>%
  mutate(group = ifelse(baseline_pc > med_grant, "Above Median", "Below Median")) %>%
  group_by(group) %>%
  summarise(mean_grant = mean(baseline_pc), sd_grant = sd(baseline_pc),
            n = n(), .groups = "drop")

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Baseline Grant Group}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Below Median Grant} & \\multicolumn{2}{c}{Above Median Grant} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Grant Characteristics}} \\\\\n",
  sprintf("Baseline grant per head (\\pounds) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          grant_stats$mean_grant[1], grant_stats$sd_grant[1],
          grant_stats$mean_grant[2], grant_stats$sd_grant[2]),
  sprintf("N local authorities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          grant_stats$n[1], grant_stats$n[2]),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Pre-Period Health Outcomes (2011--2014)}} \\\\\n",
  sprintf("Smoking prevalence (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          stats_smoking$mean[1], stats_smoking$sd[1],
          stats_smoking$mean[2], stats_smoking$sd[2]),
  sprintf("CO-validated quit rate (per 100k) & %.0f & %.0f & %.0f & %.0f \\\\\n",
          stats_quits$mean[1], stats_quits$sd[1],
          stats_quits$mean[2], stats_quits$sd[2]),
  sprintf("COPD admissions (per 100k) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          stats_copd$mean[1], stats_copd$sd[1],
          stats_copd$mean[2], stats_copd$sd[2]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Local authorities split at median baseline public health grant per head (\\pounds",
  sprintf("%.1f", med_grant),
  "). Smoking prevalence from Annual Population Survey via Fingertips (indicator 92443). ",
  "CO-validated quit rate from OHID (indicator 1211). COPD emergency admissions from ",
  "Fingertips (indicator 92302). Pre-period defined as 2011--2014 (smoking) or 2013--2014 (quits).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, file.path(tab_dir, "tab1_summary.tex"))

# ========== TABLE 2: Main Results ==========
cat("Generating Table 2: Main Results\n")

# Extract coefficients
coef_smoke <- coeftable(main_results$smoking_did)
coef_quit  <- coeftable(main_results$quit_did)
coef_copd  <- coeftable(main_results$copd_did)
coef_plac  <- coeftable(main_results$placebo_did)

format_coef <- function(ct, row = 1) {
  est <- ct[row, "Estimate"]
  se  <- ct[row, "Std. Error"]
  pv  <- ct[row, "Pr(>|t|)"]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  sprintf("%.3f%s & (%.3f)", est, stars, se)
}

# Pre-treatment SDs for each outcome
sd_smoke_pre <- sd(smoking_panel$value[smoking_panel$year_start <= 2014], na.rm = TRUE)
sd_quit_pre  <- sd(quits_panel$value[quits_panel$year_start <= 2014], na.rm = TRUE)
sd_copd_pre  <- sd(copd_panel$value[copd_panel$year_start <= 2014], na.rm = TRUE)

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Baseline Grant Intensity on Health Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Smoking & Quit Rate & COPD & Sexual Health \\\\\n",
  " & Prevalence & (per 100k) & Admissions & (Placebo) \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("Baseline Grant$_z$ $\\times$ Post & %s & %s & %s & %s \\\\\n",
          format_coef(coef_smoke), format_coef(coef_quit),
          format_coef(coef_copd), format_coef(coef_plac)),
  "\\hline\n",
  sprintf("Pre-treatment SD(Y) & %.2f & %.0f & %.1f & --- \\\\\n",
          sd_smoke_pre, sd_quit_pre, sd_copd_pre),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nrow(smoking_panel), big.mark = ","),
          format(nrow(quits_panel), big.mark = ","),
          format(nrow(copd_panel), big.mark = ","),
          format(nrow(placebo_panel), big.mark = ",")),
  sprintf("Local Authorities & %d & %d & %d & %d \\\\\n",
          n_distinct(smoking_panel$area_code), n_distinct(quits_panel$area_code),
          n_distinct(copd_panel$area_code), n_distinct(placebo_panel$area_code)),
  "LA FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each column reports a separate regression of the health outcome on ",
  "the standardized baseline per-capita public health grant (2015/16) interacted with a post-2015 ",
  "indicator. Standard errors clustered at the local authority level in parentheses. ",
  "Column (4) reports a placebo test using chlamydia screening rates, which should not be ",
  "affected by stop smoking service cuts. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, file.path(tab_dir, "tab2_main.tex"))

# ========== TABLE 3: Quit Rate Event Study ==========
cat("Generating Table 3: Quit Rate Event Study\n")

quit_es <- coeftable(main_results$quit_es)
quit_la_trends <- coeftable(robust_results$quit_la_trends)

# Build event study table
es_rows <- rownames(quit_es)
years <- as.integer(str_extract(es_rows, "\\d{4}"))

tab3_body <- ""
for (i in seq_along(years)) {
  yr <- years[i]
  est1 <- quit_es[i, "Estimate"]
  se1  <- quit_es[i, "Std. Error"]
  pv1  <- quit_es[i, "Pr(>|t|)"]
  stars1 <- ifelse(pv1 < 0.01, "***", ifelse(pv1 < 0.05, "**", ifelse(pv1 < 0.1, "*", "")))

  tab3_body <- paste0(tab3_body,
    sprintf("%d & %.1f%s & (%.1f) \\\\\n", yr, est1, stars1, se1))
}

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{CO-Validated Quit Rate Event Study}\n",
  "\\label{tab:quit_es}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Year & \\multicolumn{2}{c}{Quit Rate (per 100k)} \\\\\n",
  " & Coefficient & SE \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Pre-treatment}} \\\\\n",
  tab3_body,
  "\\hline\n",
  "Reference year & \\multicolumn{2}{c}{2014} \\\\\n",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\\n",
          format(nrow(quits_panel), big.mark = ",")),
  sprintf("Local Authorities & \\multicolumn{2}{c}{%d} \\\\\n",
          n_distinct(quits_panel$area_code)),
  "LA FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each coefficient is the interaction of the standardized baseline ",
  "per-capita public health grant with a year indicator, with 2014 as the reference year. ",
  "CO-validated quit rates from OHID Fingertips (indicator 1211). The pre-treatment coefficient ",
  "(2013) tests for differential pre-trends. Standard errors clustered at the local authority level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, file.path(tab_dir, "tab3_quit_es.tex"))

# ========== TABLE 4: Robustness ==========
cat("Generating Table 4: Robustness\n")

# Robustness for quit rate (the robust finding)
coef_quit_base <- coeftable(main_results$quit_did)
coef_quit_trend <- coeftable(robust_results$quit_la_trends)
coef_quit_nocov <- coeftable(robust_results$quit_nocovid)

# Smoking robustness
coef_smoke_base <- coeftable(main_results$smoking_did)
coef_smoke_ctrl <- coeftable(robust_results$smoke_baseline_control)
coef_smoke_trend <- coeftable(robust_results$smoke_la_trends)

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Quit Rate} & \\multicolumn{3}{c}{Smoking Prevalence} \\\\\n",
  " & Baseline & LA Trends & Pre-COVID & Baseline & Smoking$\\times$Trend & LA Trends \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\hline\n",
  sprintf("Grant$_z$ $\\times$ Post & %s & %s & %s & %s & %s & %s \\\\\n",
          format_coef(coef_quit_base),
          format_coef(coef_quit_trend),
          format_coef(coef_quit_nocov),
          format_coef(coef_smoke_base),
          format_coef(coeftable(robust_results$smoke_baseline_control)),
          format_coef(coef_smoke_trend)),
  "\\hline\n",
  "LA FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "LA-specific trends & No & Yes & No & No & No & Yes \\\\\n",
  "Baseline smoking $\\times$ trend & No & No & No & No & Yes & No \\\\\n",
  "Sample & Full & Full & 2013--19 & Full & Full & Full \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Columns (1)--(3) report quit rate regressions under alternative specifications. ",
  "Column (2) adds LA-specific linear trends. Column (3) excludes COVID years (2020--2022). ",
  "Columns (4)--(6) report smoking prevalence regressions. Column (5) controls for baseline ",
  "smoking prevalence interacted with a linear trend to address convergence. Column (6) adds ",
  "LA-specific trends, which absorb the smoking prevalence effect entirely. ",
  "The quit rate effect is robust across all specifications; the smoking prevalence effect ",
  "reflects convergence (corr(baseline grant, baseline smoking) $= 0.49$). ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, file.path(tab_dir, "tab4_robust.tex"))

# ========== TABLE F1: SDE Appendix ==========
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDE for each outcome
# SDE = β / SD(Y_pre)

# Quit rate (the robust result with LA trends)
beta_quit <- coef_quit_trend[1, "Estimate"]
se_quit   <- coef_quit_trend[1, "Std. Error"]
sde_quit  <- beta_quit / sd_quit_pre
se_sde_quit <- se_quit / sd_quit_pre

# Smoking prevalence (with baseline smoking control — honest null)
coef_smoke_r <- coeftable(robust_results$smoke_baseline_control)
beta_smoke <- coef_smoke_r[1, "Estimate"]
se_smoke   <- coef_smoke_r[1, "Std. Error"]
sde_smoke  <- beta_smoke / sd_smoke_pre
se_sde_smoke <- se_smoke / sd_smoke_pre

# COPD (noisy pre-trends, less credible)
beta_copd <- coeftable(main_results$copd_did)[1, "Estimate"]
se_copd   <- coeftable(main_results$copd_did)[1, "Std. Error"]
sde_copd  <- beta_copd / sd_copd_pre
se_sde_copd <- se_copd / sd_copd_pre

classify_sde <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  return("Small negative")
}

# Heterogeneity: tercile analysis for quit rate
# High-grant tercile
tercile_breaks <- quantile(baseline$baseline_pc, probs = c(1/3, 2/3))

quits_high <- quits_panel %>%
  filter(baseline_pc > tercile_breaks[2])
m_quit_high <- feols(value ~ treat_post | area_code + year_start,
                     data = quits_high, cluster = ~area_code)
beta_quit_high <- coeftable(m_quit_high)[1, "Estimate"]
se_quit_high   <- coeftable(m_quit_high)[1, "Std. Error"]
sd_quit_high   <- sd(quits_high$value[quits_high$year_start <= 2014], na.rm = TRUE)
sde_quit_high  <- beta_quit_high / sd_quit_high
se_sde_quit_high <- se_quit_high / sd_quit_high

quits_low <- quits_panel %>%
  filter(baseline_pc <= tercile_breaks[1])
m_quit_low <- feols(value ~ treat_post | area_code + year_start,
                    data = quits_low, cluster = ~area_code)
beta_quit_low <- coeftable(m_quit_low)[1, "Estimate"]
se_quit_low   <- coeftable(m_quit_low)[1, "Std. Error"]
sd_quit_low   <- sd(quits_low$value[quits_low$year_start <= 2014], na.rm = TRUE)
sde_quit_low  <- beta_quit_low / sd_quit_low
se_sde_quit_low <- se_quit_low / sd_quit_low

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Did austerity-driven cuts to local authority public health grants ",
  "reduce stop smoking service capacity and worsen respiratory health outcomes? ",
  "\\textbf{Policy mechanism:} From 2015/16, HM Treasury imposed real-terms cuts to the ring-fenced ",
  "public health grant transferred to 152 English upper-tier local authorities in 2013; ",
  "LAs exercised discretion over which services to cut, and stop smoking services experienced ",
  "disproportionate reductions nationally (36\\% spending decline by 2022/23). ",
  "\\textbf{Outcome definition:} CO-validated quit rate (successful 4-week quits per 100,000 population); ",
  "smoking prevalence (percentage of adults 18+ who currently smoke, APS); ",
  "COPD emergency hospital admissions per 100,000 adults aged 35+. ",
  "\\textbf{Treatment:} Continuous: standardized baseline (2015/16) per-capita public health ",
  "grant allocation (needs-based formula), interacted with post-2015 indicator. ",
  "\\textbf{Data:} OHID Fingertips indicators 92443, 1211, 92302; DHSC grant allocations 2015/16; ",
  "upper-tier LA annual panel 2011--2024 (smoking), 2013--2022 (quits). ",
  "\\textbf{Method:} Two-way fixed effects (LA + year FE), standard errors clustered at LA level; ",
  "preferred specification includes LA-specific linear trends for quit rate. ",
  "\\textbf{Sample:} 148--149 upper-tier English local authorities with matched grant and outcome data; ",
  "excludes Isles of Scilly and City of London (populations under 10,000). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("CO-validated quit rate & %.1f & %.1f & %.0f & %.3f & %.3f & %s \\\\\n",
          beta_quit, se_quit, sd_quit_pre, sde_quit, se_sde_quit, classify_sde(sde_quit)),
  sprintf("Smoking prevalence & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
          beta_smoke, se_smoke, sd_smoke_pre, sde_smoke, se_sde_smoke, classify_sde(sde_smoke)),
  sprintf("COPD admissions & %.1f & %.1f & %.1f & %.3f & %.3f & %s \\\\\n",
          beta_copd, se_copd, sd_copd_pre, sde_copd, se_sde_copd, classify_sde(sde_copd)),
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Quit Rate by Grant Tercile)}} \\\\\n",
  sprintf("Top tercile (grant $>$ \\pounds%.0f) & %.1f & %.1f & %.0f & %.3f & %.3f & %s \\\\\n",
          tercile_breaks[2], beta_quit_high, se_quit_high, sd_quit_high,
          sde_quit_high, se_sde_quit_high, classify_sde(sde_quit_high)),
  sprintf("Bottom tercile (grant $\\leq$ \\pounds%.0f) & %.1f & %.1f & %.0f & %.3f & %.3f & %s \\\\\n",
          tercile_breaks[1], beta_quit_low, se_quit_low, sd_quit_low,
          sde_quit_low, se_sde_quit_low, classify_sde(sde_quit_low)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1, file.path(tab_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat("Files in tables/:\n")
cat(paste(list.files(tab_dir), collapse = "\n"), "\n")
