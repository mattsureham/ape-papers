## 05_tables.R — apep_1136: Generate all LaTeX tables + SDE appendix
source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel_wide.rds"))
panel_long <- readRDS(file.path(data_dir, "panel_long.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ============================================================
## Helper: format numbers
## ============================================================
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmt0 <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
stars <- function(p) ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}",
                     ifelse(p < 0.1, "^{*}", "")))

## ============================================================
## Table 1: Summary Statistics
## ============================================================
pre <- panel %>% filter(date >= "2010-01-01" & date < "2018-09-01")
post_rule <- panel %>% filter(date >= "2018-09-01" & date < "2020-03-01")
post_covid <- panel %>% filter(date >= "2021-10-01" & date <= "2025-03-31")

## Shorten period labels for table width
make_summ <- function(df, label) {
  data.frame(
    Period = label,
    CC_mean = mean(df$cc_outstanding, na.rm = TRUE),
    CC_sd = sd(df$cc_outstanding, na.rm = TRUE),
    PL_mean = mean(df$pl_outstanding, na.rm = TRUE),
    PL_sd = sd(df$pl_outstanding, na.rm = TRUE),
    Share_mean = mean(df$cc_share, na.rm = TRUE),
    NL_mean = mean(df$cc_net_lending, na.rm = TRUE),
    Rate_CC = mean(df$cc_interest_rate, na.rm = TRUE),
    Rate_PL = mean(df$pl_interest_rate, na.rm = TRUE),
    N = nrow(df)
  )
}

summ <- bind_rows(
  make_summ(pre, "Pre-rule"),
  make_summ(post_rule, "Rule active"),
  make_summ(post_covid, "Post-COVID")
)

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Summary Statistics: UK Consumer Credit Markets}\n",
  "\\label{tab:summary}\n",
  "\\footnotesize\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Outstanding (\\pounds m)} & CC Share & Net Lending & \\multicolumn{2}{c}{Interest Rate (\\%)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){6-7}\n",
  "Period & Credit Card & Personal Loan & of Total & (\\pounds m/mo) & CC & PL \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(summ)) {
  s <- summ[i, ]
  tab1 <- paste0(tab1, sprintf(
    "%s & %s & %s & %.3f & %s & %.1f & %.1f \\\\\n",
    s$Period,
    fmt0(s$CC_mean), fmt0(s$PL_mean),
    s$Share_mean, fmt0(s$NL_mean),
    s$Rate_CC, s$Rate_PL
  ))
  tab1 <- paste0(tab1, sprintf(
    "\\quad (SD) & (%s) & (%s) & & & & \\\\\n",
    fmt0(s$CC_sd), fmt0(s$PL_sd)
  ))
}

tab1 <- paste0(tab1,
  "\\midrule\n",
  sprintf("Months & \\multicolumn{6}{c}{%d (Jan 2010--Mar 2025)} \\\\\n",
          nrow(panel %>% filter(date >= "2010-01-01" & date <= "2025-03-31"))),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Bank of England Bankstats monthly series. Credit card outstanding (LPMVZRJ), other consumer credit outstanding (LPMVZRI), credit card net lending (LPMVZQX), credit card effective interest rate (IUMCCTL), personal loan effective rate (IUMTLMV). All amounts in millions of pounds sterling, seasonally adjusted.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(tab_dir, "tab1_summary.tex"))
cat("Wrote: tab1_summary.tex\n")

## ============================================================
## Table 2: Main DiD Results
## ============================================================
## Extract coefficients from fixest models
get_fixest_coef <- function(model, var) {
  ct <- coeftable(model)
  if (var %in% rownames(ct)) {
    return(list(b = ct[var, "Estimate"], se = ct[var, "Std. Error"],
                p = ct[var, "Pr(>|t|)"]))
  }
  return(list(b = NA, se = NA, p = NA))
}

## Model columns:
## (1) Simple DiD, full sample
## (2) Pre-COVID window
## (3) Product-specific trend
## (4) Multi-phase DiD

m1_did <- get_fixest_coef(results$m1_simple_did, "did")
m2_precovid <- get_fixest_coef(robust$precovid, "did")
m3_trend <- get_fixest_coef(robust$trend_adjusted, "did")

## Multi-phase from model 2
m2_ct <- coeftable(results$m2_multiphase)
m4_rule <- list(b = m2_ct["treated:post_rule", "Estimate"],
                se = m2_ct["treated:post_rule", "Std. Error"],
                p = m2_ct["treated:post_rule", "Pr(>|t|)"])
m4_covid <- list(b = m2_ct["treated:covid_suspend", "Estimate"],
                 se = m2_ct["treated:covid_suspend", "Std. Error"],
                 p = m2_ct["treated:covid_suspend", "Pr(>|t|)"])
m4_post <- list(b = m2_ct["treated:post_covid", "Estimate"],
                se = m2_ct["treated:post_covid", "Std. Error"],
                p = m2_ct["treated:post_covid", "Pr(>|t|)"])

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Cross-Product Difference-in-Differences: Log Outstanding Amounts}\n",
  "\\label{tab:did}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Full Sample & Pre-COVID & Trend-Adj. & Multi-Phase \\\\\n",
  "\\midrule\n",
  sprintf("CC $\\times$ Post & %s$%s$ & %s$%s$ & %s$%s$ & \\\\\n",
          fmt(m1_did$b), stars(m1_did$p),
          fmt(m2_precovid$b), stars(m2_precovid$p),
          fmt(m3_trend$b), stars(m3_trend$p)),
  sprintf(" & (%s) & (%s) & (%s) & \\\\\n",
          fmt(m1_did$se), fmt(m2_precovid$se), fmt(m3_trend$se)),
  "\\\\[4pt]\n",
  sprintf("CC $\\times$ Rule Active & & & & %s$%s$ \\\\\n",
          fmt(m4_rule$b), stars(m4_rule$p)),
  sprintf(" & & & & (%s) \\\\\n", fmt(m4_rule$se)),
  sprintf("CC $\\times$ COVID Suspend & & & & %s$%s$ \\\\\n",
          fmt(m4_covid$b), stars(m4_covid$p)),
  sprintf(" & & & & (%s) \\\\\n", fmt(m4_covid$se)),
  sprintf("CC $\\times$ Post-COVID & & & & %s$%s$ \\\\\n",
          fmt(m4_post$b), stars(m4_post$p)),
  sprintf(" & & & & (%s) \\\\\n", fmt(m4_post$se)),
  "\\\\[4pt]\n",
  "CC-specific trend & No & No & Yes & No \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %d & %d & %d & %d \\\\\n",
          nobs(results$m1_simple_did),
          nobs(robust$precovid),
          nobs(robust$trend_adjusted),
          nobs(results$m2_multiphase)),
  sprintf("$R^2$ & %s & %s & %s & %s \\\\\n",
          fmt(r2(results$m1_simple_did, "ar2")),
          fmt(r2(robust$precovid, "ar2")),
          fmt(r2(robust$trend_adjusted, "ar2")),
          fmt(r2(results$m2_multiphase, "ar2"))),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log outstanding amounts. Panel of two products (credit cards and personal loans) observed monthly, January 2010--March 2025. Column (2) restricts to the pre-COVID window ending February 2020. Column (3) includes a credit-card-specific linear trend. Column (4) allows separate treatment effects for each policy phase: Rule Active (September 2018--February 2020), COVID Suspension (March 2020--September 2021), and Post-COVID (October 2021 onward). Newey-West standard errors with 12 lags in parentheses. $^{***}$, $^{**}$, $^{*}$ denote significance at the 1\\%, 5\\%, and 10\\% levels.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(tab_dir, "tab2_did.tex"))
cat("Wrote: tab2_did.tex\n")

## ============================================================
## Table 3: Escalation Timing
## ============================================================
esc <- robust$escalation_hac

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Escalation Timing: Log Gap at Intervention Thresholds}\n",
  "\\label{tab:escalation}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Coefficient & SE \\\\\n",
  "\\midrule\n",
  sprintf("Post 18 months (first contact) & %s$%s$ & (%s) \\\\\n",
          fmt(esc["post_18m", "Estimate"]), stars(esc["post_18m", "Pr(>|t|)"]),
          fmt(esc["post_18m", "Std. Error"])),
  sprintf("Post 27 months (repayment plan) & %s$%s$ & (%s) \\\\\n",
          fmt(esc["post_27m", "Estimate"]), stars(esc["post_27m", "Pr(>|t|)"]),
          fmt(esc["post_27m", "Std. Error"])),
  sprintf("Post 36 months (suspend/cancel) & %s$%s$ & (%s) \\\\\n",
          fmt(esc["post_36m", "Estimate"]), stars(esc["post_36m", "Pr(>|t|)"]),
          fmt(esc["post_36m", "Std. Error"])),
  sprintf("Monthly trend & %s$%s$ & (%s) \\\\\n",
          fmt(esc["months_post", "Estimate"], 4), stars(esc["months_post", "Pr(>|t|)"]),
          fmt(esc["months_post", "Std. Error"], 4)),
  "\\midrule\n",
  "Month FE & Yes \\\\\n",
  sprintf("Observations & %d \\\\\n",
          nrow(panel %>% filter(date >= "2018-09-01" & date <= "2025-03-31"))),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is the log gap: $\\ln(\\text{CC outstanding}) - \\ln(\\text{PL outstanding})$. Sample restricted to post-rule period (September 2018--March 2025). Breaks at 18, 27, and 36 months correspond to the FCA's escalating intervention thresholds under CONC 6.7.27--6.7.40: initial contact (18 months), repayment plan requirement (27 months), and account suspension or cancellation (36 months). Newey-West standard errors with 12 lags. $^{***}$, $^{**}$, $^{*}$ denote significance at the 1\\%, 5\\%, and 10\\% levels.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(tab_dir, "tab3_escalation.tex"))
cat("Wrote: tab3_escalation.tex\n")

## ============================================================
## Table 4: Mechanism — Interest Rates, Net Lending, Write-offs
## ============================================================
## Extract HAC results from main analysis
rate_hac <- results$m6_hac
nl_hac <- results$m5_hac
share_hac <- results$m4_hac

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Mechanism Tests: Pricing, Lending, and Credit Share}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Rate Spread & Net Lending & CC Share \\\\\n",
  " & (ppt) & (\\pounds m/mo) & (proportion) \\\\\n",
  "\\midrule\n",
  sprintf("Post Rule & %s$%s$ & %s$%s$ & %s$%s$ \\\\\n",
          fmt(rate_hac["post_rule", "Estimate"], 2), stars(rate_hac["post_rule", "Pr(>|t|)"]),
          fmt0(nl_hac["post_rule", "Estimate"]), stars(nl_hac["post_rule", "Pr(>|t|)"]),
          fmt(share_hac["post_rule", "Estimate"], 4), stars(share_hac["post_rule", "Pr(>|t|)"])),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          fmt(rate_hac["post_rule", "Std. Error"], 2),
          fmt0(nl_hac["post_rule", "Std. Error"]),
          fmt(share_hac["post_rule", "Std. Error"], 4)),
  "\\\\[4pt]\n",
  sprintf("COVID Suspension & %s$%s$ & %s$%s$ & %s$%s$ \\\\\n",
          fmt(rate_hac["covid_suspend", "Estimate"], 2), stars(rate_hac["covid_suspend", "Pr(>|t|)"]),
          fmt0(nl_hac["covid_suspend", "Estimate"]), stars(nl_hac["covid_suspend", "Pr(>|t|)"]),
          fmt(share_hac["covid_suspend", "Estimate"], 4), stars(share_hac["covid_suspend", "Pr(>|t|)"])),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          fmt(rate_hac["covid_suspend", "Std. Error"], 2),
          fmt0(nl_hac["covid_suspend", "Std. Error"]),
          fmt(share_hac["covid_suspend", "Std. Error"], 4)),
  "\\\\[4pt]\n",
  sprintf("Post-COVID & %s$%s$ & %s$%s$ & %s$%s$ \\\\\n",
          fmt(rate_hac["post_covid", "Estimate"], 2), stars(rate_hac["post_covid", "Pr(>|t|)"]),
          fmt0(nl_hac["post_covid", "Estimate"]), stars(nl_hac["post_covid", "Pr(>|t|)"]),
          fmt(share_hac["post_covid", "Estimate"], 4), stars(share_hac["post_covid", "Pr(>|t|)"])),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          fmt(rate_hac["post_covid", "Std. Error"], 2),
          fmt0(nl_hac["post_covid", "Std. Error"]),
          fmt(share_hac["post_covid", "Std. Error"], 4)),
  "\\midrule\n",
  "Pre-rule mean & 13.2 & 218 & 0.201 \\\\\n",
  "Month FE & Yes & Yes & Yes \\\\\n",
  "Linear trend & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column (1): interest rate spread between credit cards and personal loans (percentage points). Column (2): monthly credit card net lending flow (\\pounds m). Column (3): credit card share of total consumer credit (outstanding amounts). All regressions include a linear trend and month fixed effects. Newey-West HAC standard errors with 12 lags. $^{***}$, $^{**}$, $^{*}$ denote significance at the 1\\%, 5\\%, and 10\\% levels.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(tab_dir, "tab4_mechanism.tex"))
cat("Wrote: tab4_mechanism.tex\n")

## ============================================================
## Table 5: Robustness Summary
## ============================================================
placebo_ct <- coeftable(robust$placebo)
placebo_did <- list(b = placebo_ct["did", "Estimate"],
                    se = placebo_ct["did", "Std. Error"],
                    p = placebo_ct["did", "Pr(>|t|)"])

tab5 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Robustness and Placebo Tests}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & DiD & SE & p-value & Notes \\\\\n",
  "\\midrule\n",
  sprintf("\\textit{Panel A: Main result} & & & & \\\\\n"),
  sprintf("Full sample & %s & %s & %s & Baseline \\\\\n",
          fmt(m1_did$b), fmt(m1_did$se), fmt(m1_did$p, 4)),
  sprintf("Pre-COVID only & %s & %s & %s & To Feb 2020 \\\\\n",
          fmt(m2_precovid$b), fmt(m2_precovid$se), fmt(m2_precovid$p, 4)),
  sprintf("Trend-adjusted & %s & %s & %s & CC-specific trend \\\\\n",
          fmt(m3_trend$b), fmt(m3_trend$se), fmt(m3_trend$p, 4)),
  "\\\\[4pt]\n",
  sprintf("\\textit{Panel B: Placebo} & & & & \\\\\n"),
  sprintf("Dealership vs Student & %s & %s & %s & No rule exposure \\\\\n",
          fmt(placebo_did$b), fmt(placebo_did$se), fmt(placebo_did$p, 4)),
  "\\\\[4pt]\n",
  sprintf("\\textit{Panel C: Inference} & & & & \\\\\n"),
  sprintf("Permutation $p$-value & & & %s & 500 random dates \\\\\n",
          fmt(robust$perm_p, 3)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A reports the cross-product DiD coefficient on log outstanding amounts under alternative specifications. Panel B applies the same design to two untreated products (dealership finance and student loans). Panel C reports the one-sided permutation $p$-value from 500 placebo treatment dates drawn uniformly from January 2012 to January 2023. Newey-West standard errors with 12 lags. The placebo test indicates that product-specific trends confound the simple cross-product design; the escalation timing analysis (Table~\\ref{tab:escalation}) provides stronger within-treatment variation.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab5, file.path(tab_dir, "tab5_robustness.tex"))
cat("Wrote: tab5_robustness.tex\n")

## ============================================================
## SDE Table (Mandatory Appendix)
## ============================================================
## Main outcome: CC share of consumer credit (proportion)
## Using the DiD coefficient from the pre-COVID specification (cleanest)

## Compute SD(Y) for outcomes in pre-treatment period
pre_data <- panel %>% filter(date >= "2010-01-01" & date < "2018-09-01")

sd_share <- sd(pre_data$cc_share, na.rm = TRUE)
sd_lngap <- sd(pre_data$ln_gap, na.rm = TRUE)
sd_nl    <- sd(pre_data$cc_net_lending, na.rm = TRUE)
sd_rate  <- sd(pre_data$rate_spread, na.rm = TRUE)

## SDE calculations
## Outcome 1: Log gap (DiD, pre-COVID)
beta_lngap <- m2_precovid$b
se_lngap <- m2_precovid$se
sde_lngap <- beta_lngap / sd_lngap
se_sde_lngap <- se_lngap / sd_lngap

## Outcome 2: CC share (time-series, post_rule coefficient)
beta_share <- share_hac["post_rule", "Estimate"]
se_share <- share_hac["post_rule", "Std. Error"]
sde_share <- beta_share / sd_share
se_sde_share <- se_share / sd_share

## Outcome 3: Net lending (time-series)
beta_nl <- nl_hac["post_rule", "Estimate"]
se_nl <- nl_hac["post_rule", "Std. Error"]
sde_nl <- beta_nl / sd_nl
se_sde_nl <- se_nl / sd_nl

## Outcome 4: Rate spread (time-series)
beta_rate <- rate_hac["post_rule", "Estimate"]
se_rate <- rate_hac["post_rule", "Std. Error"]
sde_rate <- beta_rate / sd_rate
se_sde_rate <- se_rate / sd_rate

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

## Heterogeneity: pre-COVID vs post-COVID effects
## Pre-COVID DiD for log gap
sde_precovid <- beta_lngap / sd_lngap
## Post-COVID multi-phase: treated:post_covid
beta_postcovid <- m2_ct["treated:post_covid", "Estimate"]
se_postcovid <- m2_ct["treated:post_covid", "Std. Error"]
sde_postcovid <- beta_postcovid / sd_lngap
se_sde_postcovid <- se_postcovid / sd_lngap

## --- Build SDE table ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does the FCA's persistent debt rule, which requires lender intervention when credit card customers pay more in interest than principal for 18 or more months, reduce credit card indebtedness or displace borrowing to other consumer credit products? ",
  "\\textbf{Policy mechanism:} The rule creates escalating mandatory interventions at 18, 27, and 36 months of persistent debt: initial customer contact, formal repayment plan proposals, and account suspension or cancellation, imposing compliance costs on lenders and behavioral nudges on borrowers. ",
  "\\textbf{Outcome definition:} Panel A reports effects on the cross-product log gap between credit card and personal loan outstanding amounts (log points), credit card share of total consumer credit (proportion), monthly credit card net lending flow (pounds sterling, millions), and the credit card--personal loan interest rate spread (percentage points). Panel B splits by policy phase. ",
  "\\textbf{Treatment:} Binary; credit card products subject to FCA CONC 6.7.27--6.7.40, effective September 2018. ",
  "\\textbf{Data:} Bank of England Bankstats monthly series, January 2010--March 2025, seasonally adjusted; two products (credit cards and personal loans) observed monthly, 366 product-month observations. ",
  "\\textbf{Method:} Cross-product difference-in-differences with Newey-West HAC standard errors (12 lags); escalation-break regressions for within-treatment timing. ",
  "\\textbf{Sample:} All UK monetary financial institutions reporting to the Bank of England; aggregate market-level series. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (Post-Rule)}} \\\\\n",
  sprintf("Log gap (CC/PL) & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_lngap), fmt(se_lngap), fmt(sd_lngap),
          fmt(sde_lngap), fmt(se_sde_lngap), classify_sde(sde_lngap)),
  sprintf("CC share & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_share, 4), fmt(se_share, 4), fmt(sd_share, 4),
          fmt(sde_share), fmt(se_sde_share), classify_sde(sde_share)),
  sprintf("Net lending & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt0(beta_nl), fmt0(se_nl), fmt0(sd_nl),
          fmt(sde_nl), fmt(se_sde_nl), classify_sde(sde_nl)),
  sprintf("Rate spread & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_rate, 2), fmt(se_rate, 2), fmt(sd_rate, 2),
          fmt(sde_rate), fmt(se_sde_rate), classify_sde(sde_rate)),
  "\\\\[4pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Policy Phase)}} \\\\\n",
  sprintf("Log gap: Rule active & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_lngap), fmt(se_lngap), fmt(sd_lngap),
          fmt(sde_precovid), fmt(se_sde_lngap), classify_sde(sde_precovid)),
  sprintf("Log gap: Post-COVID & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_postcovid), fmt(se_postcovid), fmt(sd_lngap),
          fmt(sde_postcovid), fmt(se_sde_postcovid), classify_sde(sde_postcovid)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tab, file.path(tab_dir, "tabF1_sde.tex"))
cat("Wrote: tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
