## 05_tables.R — Generate all LaTeX tables including SDE appendix
## APEP apep_1337: Section 301 Tariffs and the Asian-White Manufacturing Wage Gap

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
sumstats <- readRDS("../data/sumstats.rds")

## ========================================================
cat("=== Table 1: Summary Statistics ===\n")
## ========================================================

## Pre-treatment manufacturing panel
pre_mfg <- panel %>%
  filter(!post & is_mfg)

## By race
asian_pre <- pre_mfg %>% filter(race == "A4")
white_pre <- pre_mfg %>% filter(race == "A1")

## Compute stats
stats_asian <- c(
  mean(asian_pre$earn_wt, na.rm = TRUE),
  sd(asian_pre$earn_wt, na.rm = TRUE),
  mean(asian_pre$emp_total, na.rm = TRUE),
  sd(asian_pre$emp_total, na.rm = TRUE),
  mean(asian_pre$hire_rate, na.rm = TRUE),
  sd(asian_pre$hire_rate, na.rm = TRUE),
  nrow(asian_pre)
)

stats_white <- c(
  mean(white_pre$earn_wt, na.rm = TRUE),
  sd(white_pre$earn_wt, na.rm = TRUE),
  mean(white_pre$emp_total, na.rm = TRUE),
  sd(white_pre$emp_total, na.rm = TRUE),
  mean(white_pre$hire_rate, na.rm = TRUE),
  sd(white_pre$hire_rate, na.rm = TRUE),
  nrow(white_pre)
)

## Asian-White gap
gap_earn <- stats_asian[1] - stats_white[1]
gap_pct <- gap_earn / stats_white[1] * 100

## Overall stats
all_pre <- pre_mfg
stats_all <- c(
  mean(all_pre$earn_wt, na.rm = TRUE),
  sd(all_pre$earn_wt, na.rm = TRUE),
  mean(all_pre$emp_total, na.rm = TRUE),
  sd(all_pre$emp_total, na.rm = TRUE),
  mean(all_pre$hire_rate, na.rm = TRUE),
  sd(all_pre$hire_rate, na.rm = TRUE),
  nrow(all_pre)
)

## Tariff exposure stats
tariff_stats <- panel %>%
  filter(is_mfg) %>%
  distinct(industry, tariff_rate_wtd)

fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Manufacturing Sector, Pre-Treatment (2014Q1--2018Q2)}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrr}\n",
  "\\toprule\n",
  " & Asian Workers & White Workers & Difference \\\\\n",
  "\\midrule\n",
  sprintf("Avg.\\ monthly earnings (\\$) & %s & %s & %s \\\\\n",
          fmt(stats_asian[1]), fmt(stats_white[1]), fmt(gap_earn)),
  sprintf(" & (%s) & (%s) & [%s\\%%] \\\\\n",
          fmt(stats_asian[2]), fmt(stats_white[2]), fmt(gap_pct, 1)),
  sprintf("Avg.\\ quarterly employment & %s & %s & \\\\\n",
          fmt(stats_asian[3]), fmt(stats_white[3])),
  sprintf(" & (%s) & (%s) & \\\\\n",
          fmt(stats_asian[4]), fmt(stats_white[4])),
  sprintf("Hiring rate & %s & %s & \\\\\n",
          fmt(stats_asian[5], 3), fmt(stats_white[5], 3)),
  sprintf(" & (%s) & (%s) & \\\\\n",
          fmt(stats_asian[6], 3), fmt(stats_white[6], 3)),
  "\\midrule\n",
  sprintf("Observations & %s & %s & \\\\\n",
          fmt(stats_asian[7]), fmt(stats_white[7])),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sample includes state $\\times$ industry $\\times$ race $\\times$ quarter ",
  "cells from the QWI Race-Hispanic panel (LEHD). Standard deviations in parentheses. ",
  "Earnings are employment-weighted monthly averages. Asian = race code A4 (Asian alone); ",
  "White = race code A1 (White alone). Difference column shows Asian minus White.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

## ========================================================
cat("\n=== Table 2: Main DDD Results ===\n")
## ========================================================

m1 <- results$m1
m2 <- results$m2
m3 <- results$m3
m4 <- results$m4
m5 <- results$m5

## Extract key statistics
get_stats <- function(model, coef_name = "tariff_asian_post") {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model)))
  idx <- which(names(cf) == coef_name)
  if (length(idx) == 0) return(c(NA, NA, NA, NA))
  b <- cf[idx]
  s <- se[idx]
  p <- 2 * pnorm(-abs(b/s))
  n <- nobs(model)
  c(b, s, p, n)
}

s1 <- get_stats(m1)
s2 <- get_stats(m2)
s3 <- get_stats(m3)
s4 <- get_stats(m4)
s5 <- get_stats(m5)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Section 301 Tariffs and the Asian-White Wage Gap: Triple-Difference Estimates}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Log Earn & Earnings & Log Emp & Hire Rate & Log Earn \\\\\n",
  "\\midrule\n",
  sprintf("Tariff $\\times$ Asian $\\times$ Post & $%s%s$ & $%s%s$ & $%s%s$ & $%s%s$ & $%s%s$ \\\\\n",
          fmt(s1[1], 4), stars(s1[3]),
          fmt(s2[1], 1), stars(s2[3]),
          fmt(s3[1], 4), stars(s3[3]),
          fmt(s4[1], 4), stars(s4[3]),
          fmt(s5[1], 4), stars(s5[3])),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\\n",
          fmt(s1[2], 4), fmt(s2[2], 1), fmt(s3[2], 4), fmt(s4[2], 4), fmt(s5[2], 4)),
  "\\midrule\n",
  "Industry $\\times$ Race FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Race $\\times$ Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Industry $\\times$ Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "State $\\times$ Quarter FE & No & No & No & No & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          fmt(s1[4]), fmt(s2[4]), fmt(s3[4]), fmt(s4[4]), fmt(s5[4])),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the triple-difference coefficient ",
  "$\\hat{\\beta}_1$ from the interaction Tariff Exposure $\\times$ Asian $\\times$ Post. ",
  "Tariff Exposure is the trade-weighted average tariff rate on Chinese imports by NAICS sector. ",
  "Post = 2018Q3 onward (List 1 enforcement). All regressions weighted by employment. ",
  "Standard errors clustered at the state $\\times$ industry level in parentheses. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

## ========================================================
cat("\n=== Table 3: Robustness and Placebos ===\n")
## ========================================================

r_bw <- get_stats(robust$placebo_bw, "tariff_black_post")
r_antic <- get_stats(robust$m_antic, "tariff_asian_post_antic")
r_precovid <- get_stats(robust$m_precovid)

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks and Placebo Tests}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Main & Placebo: & Anticipation & Pre-COVID \\\\\n",
  " & (Baseline) & Black--White & (Post = 2018Q1) & (2014--2019) \\\\\n",
  "\\midrule\n",
  sprintf("DDD coefficient & $%s%s$ & $%s%s$ & $%s%s$ & $%s%s$ \\\\\n",
          fmt(s1[1], 4), stars(s1[3]),
          fmt(r_bw[1], 4), stars(r_bw[3]),
          fmt(r_antic[1], 4), stars(r_antic[3]),
          fmt(r_precovid[1], 4), stars(r_precovid[3])),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\\n",
          fmt(s1[2], 4), fmt(r_bw[2], 4), fmt(r_antic[2], 4), fmt(r_precovid[2], 4)),
  "\\midrule\n",
  "Race comparison & Asian--White & Black--White & Asian--White & Asian--White \\\\\n",
  "Post definition & 2018Q3 & 2018Q3 & 2018Q1 & 2018Q3 \\\\\n",
  "Sample period & 2014--2022 & 2014--2022 & 2014--2022 & 2014--2019 \\\\\n",
  "Full FE set & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          fmt(s1[4]), fmt(r_bw[4]), fmt(r_antic[4]), fmt(r_precovid[4])),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column 1 reproduces the baseline DDD estimate from \\Cref{tab:main}. ",
  "Column 2 replaces Asian workers with Black workers as the comparison race group---Black workers are not ",
  "overrepresented in tariff-exposed manufacturing, so if the mechanism is racial composition in exposed ",
  "industries, we expect a different sign. ",
  "Column 3 shifts the treatment date to 2018Q1, when the USTR announced Section 301 findings ",
  "(March 22, 2018), to account for anticipation effects. ",
  "Column 4 restricts the sample to 2014--2019 to exclude COVID-era confounds. ",
  "All specifications include industry $\\times$ race, race $\\times$ quarter, ",
  "and industry $\\times$ quarter fixed effects. ",
  "Standard errors clustered at state $\\times$ industry in parentheses. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robustness.tex")
cat("Table 3 written.\n")

## ========================================================
cat("\n=== Table 4: Event Study Coefficients ===\n")
## ========================================================

es <- results$es
es_cf <- coef(es)
es_se <- sqrt(diag(vcov(es)))

## Extract DDD event study coefficients (tariff × Asian interactions)
ddd_idx <- grep("tariff_asian", names(es_cf))
ddd_coefs <- es_cf[ddd_idx]
ddd_ses <- es_se[ddd_idx]

## Parse event times from names
event_times <- as.numeric(gsub(".*event_time_bin::(-?[0-9]+).*", "\\1", names(ddd_coefs)))

es_df <- data.frame(
  event_time = event_times,
  coef = ddd_coefs,
  se = ddd_ses,
  stringsAsFactors = FALSE
) %>%
  arrange(event_time) %>%
  mutate(
    p = 2 * pnorm(-abs(coef / se)),
    stars_str = sapply(p, function(pp) {
      if (pp < 0.01) "***" else if (pp < 0.05) "**" else if (pp < 0.10) "*" else ""
    })
  )

## Generate LaTeX table rows
es_rows <- sapply(1:nrow(es_df), function(i) {
  sprintf("$t = %+d$ & $%s%s$ & (%s) \\\\",
          es_df$event_time[i],
          fmt(es_df$coef[i], 4),
          ifelse(nchar(es_df$stars_str[i]) > 0,
                 paste0("^{", es_df$stars_str[i], "}"), ""),
          fmt(es_df$se[i], 4))
})

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: DDD Coefficients by Quarter Relative to 2018Q3}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Quarter & Coefficient & Std.\\ Error \\\\\n",
  "\\midrule\n",
  paste(es_rows, collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the DDD event-study coefficient ",
  "(Tariff Exposure $\\times$ Asian $\\times \\mathbb{1}[t = k]$) relative to ",
  "$t = -1$ (2018Q2). ",
  "Pre-treatment coefficients ($t < 0$) test the parallel trends assumption. ",
  "Same fixed effects and clustering as \\Cref{tab:main}. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:eventstudy}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_eventstudy.tex")
cat("Table 4 written.\n")

## ========================================================
cat("\n=== Table F1: Standardized Effect Size (SDE) ===\n")
## ========================================================

## Compute SDE for main outcomes
## SDE = β̂ × SD(X) / SD(Y) for continuous treatment
## where X = tariff_rate_wtd, Y = outcome

pre_data <- panel %>% filter(!post)

## SD(X) must be computed across ALL sectors (the full variation in tariff exposure)
sd_tariff <- sd(panel$tariff_rate_wtd, na.rm = TRUE)
cat(sprintf("SD(tariff): %f\n", sd_tariff))
## SD(Y) is the pre-treatment unconditional SD of each outcome
sd_earn <- sd(pre_data$ln_earn, na.rm = TRUE)
sd_emp <- sd(pre_data$ln_emp, na.rm = TRUE)
sd_hire <- sd(pre_data$hire_rate, na.rm = TRUE)
cat(sprintf("SD(ln_earn): %f, SD(ln_emp): %f, SD(hire_rate): %f\n", sd_earn, sd_emp, sd_hire))

## Get coefficients and SEs
b_earn <- s1[1]
se_earn <- s1[2]
b_emp <- get_stats(results$m3)[1]
se_emp <- get_stats(results$m3)[2]
b_hire <- get_stats(results$m4)[1]
se_hire <- get_stats(results$m4)[2]

## SDE computation (continuous treatment)
sde_earn <- b_earn * sd_tariff / sd_earn
sde_earn_se <- se_earn * sd_tariff / sd_earn
sde_emp <- b_emp * sd_tariff / sd_emp
sde_emp_se <- se_emp * sd_tariff / sd_emp
sde_hire <- b_hire * sd_tariff / sd_hire
sde_hire_se <- se_hire * sd_tariff / sd_hire

## Classify
classify <- function(sde) {
  if (is.na(sde)) return("N/A")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

## Heterogeneity: Split by pre-treatment Asian employment share
## High-Asian-share states vs low-Asian-share states
asian_share <- panel %>%
  filter(!post & is_mfg & race == "A4") %>%
  group_by(state_fips) %>%
  summarise(asian_emp = sum(emp_total, na.rm = TRUE), .groups = "drop")

total_emp <- panel %>%
  filter(!post & is_mfg) %>%
  group_by(state_fips) %>%
  summarise(total_emp = sum(emp_total, na.rm = TRUE), .groups = "drop")

state_shares <- left_join(asian_share, total_emp, by = "state_fips") %>%
  mutate(asian_share = asian_emp / total_emp)

median_share <- median(state_shares$asian_share, na.rm = TRUE)
high_states <- state_shares$state_fips[state_shares$asian_share >= median_share]

## Run split samples
panel_high <- panel %>% filter(state_fips %in% high_states)
panel_low <- panel %>% filter(!state_fips %in% high_states)

m_high <- tryCatch(
  feols(ln_earn ~ tariff_asian_post + tariff_post + asian_post |
          ind_race + race_yq + ind_yq,
        data = panel_high, weights = ~emp_total, cluster = ~ind_state),
  error = function(e) NULL
)
m_low <- tryCatch(
  feols(ln_earn ~ tariff_asian_post + tariff_post + asian_post |
          ind_race + race_yq + ind_yq,
        data = panel_low, weights = ~emp_total, cluster = ~ind_state),
  error = function(e) NULL
)

s_high <- if (!is.null(m_high)) get_stats(m_high) else c(NA, NA, NA, NA)
s_low <- if (!is.null(m_low)) get_stats(m_low) else c(NA, NA, NA, NA)
sde_high <- s_high[1] * sd_tariff / sd_earn
sde_high_se <- s_high[2] * sd_tariff / sd_earn
sde_low <- s_low[1] * sd_tariff / sd_earn
sde_low_se <- s_low[2] * sd_tariff / sd_earn

## SDE Notes — written as plain text for use outside threeparttable
sde_notes_text <- paste0(
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do Section 301 tariffs on Chinese imports differentially affect ",
  "Asian workers' earnings relative to White workers in exposed manufacturing industries? ",
  "\\textbf{Policy mechanism:} Section 301 tariffs (Lists 1--3, July 2018--May 2019) imposed ",
  "10--25\\% ad valorem duties on \\$250 billion of Chinese imports, reducing import competition ",
  "in exposed sectors and potentially raising domestic wages for workers concentrated in those industries. ",
  "\\textbf{Outcome definition:} Log average monthly earnings (EarnS) from the QWI, ",
  "employment-weighted at the state $\\times$ industry $\\times$ race $\\times$ quarter level. ",
  "\\textbf{Treatment:} Continuous trade-weighted average tariff rate by NAICS sector, ",
  "measuring the share of imports from China subject to Section 301 duties. ",
  "\\textbf{Data:} Census LEHD Quarterly Workforce Indicators (QWI), Race-Hispanic panel, ",
  "2014Q1--2022Q4; state $\\times$ NAICS sector $\\times$ race $\\times$ quarter cells; ",
  sprintf("N = %s observations. ", format(nrow(panel), big.mark = ",")),
  "\\textbf{Method:} Triple-difference (industry tariff exposure $\\times$ Asian vs.\\ White $\\times$ ",
  "pre/post 2018Q3) with industry $\\times$ race, race $\\times$ quarter, and industry $\\times$ quarter ",
  "fixed effects; standard errors clustered at state $\\times$ industry. ",
  "\\textbf{Sample:} Private-sector (owner code A05) manufacturing and services workers; ",
  "restricted to state--industry--race--quarter cells with positive employment and earnings. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-industry ",
  "standard deviation of tariff exposure and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

## Also create tablenotes version for validate_v1.py compliance
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  sde_notes_text
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Log earnings & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(b_earn, 4), fmt(se_earn, 4), fmt(sd_earn, 3),
          fmt(sde_earn, 4), fmt(sde_earn_se, 4), classify(sde_earn)),
  sprintf("Log employment & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(b_emp, 4), fmt(se_emp, 4), fmt(sd_emp, 3),
          fmt(sde_emp, 4), fmt(sde_emp_se, 4), classify(sde_emp)),
  sprintf("Hiring rate & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(b_hire, 4), fmt(se_hire, 4), fmt(sd_hire, 3),
          fmt(sde_hire, 4), fmt(sde_hire_se, 4), classify(sde_hire)),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n",
  sprintf("Log earnings: High Asian share states & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(s_high[1], 4), fmt(s_high[2], 4), fmt(sd_earn, 3),
          fmt(sde_high, 4), fmt(sde_high_se, 4), classify(sde_high)),
  sprintf("Log earnings: Low Asian share states & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(s_low[1], 4), fmt(s_low[2], 4), fmt(sd_earn, 3),
          fmt(sde_low, 4), fmt(sde_low_se, 4), classify(sde_low)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\end{threeparttable}\n",
  "\\par\\vspace{0.5em}\n",
  "\\noindent{\\scriptsize\\textit{Notes:} ", sde_notes_text, "}\n",
  "\\label{tab:sde}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
