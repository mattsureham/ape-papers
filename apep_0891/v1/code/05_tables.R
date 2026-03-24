## 05_tables.R — Generate all tables for paper
## SNAP EA Expiration and Eviction Filings

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

monthly <- readRDS(file.path(data_dir, "ets_panel_monthly.rds"))
monthly[median_income < 0, median_income := NA_real_]

## Load saved estimation objects
twfe_main <- readRDS(file.path(data_dir, "twfe_main.rds"))
cs_out <- readRDS(file.path(data_dir, "cs_out.rds"))
cs_es <- readRDS(file.path(data_dir, "cs_event_study.rds"))
dose_cont <- readRDS(file.path(data_dir, "dose_cont.rds"))
dose_q <- readRDS(file.path(data_dir, "dose_quartile.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))
loso <- readRDS(file.path(data_dir, "loso_results.rds"))
diag <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))

## ═══════════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ═══════════════════════════════════════════════════════════════════

## Pre-treatment period only
pre <- monthly[year_month < as.Date("2021-04-01")]

summ_fn <- function(dt, label) {
  data.table(
    Group = label,
    `Tracts` = length(unique(dt$GEOID)),
    `Monthly filings` = round(mean(dt$filings, na.rm = TRUE), 2),
    `Filing rate` = round(mean(dt$filing_rate, na.rm = TRUE), 2),
    `SD(filing rate)` = round(sd(dt$filing_rate, na.rm = TRUE), 2),
    `SNAP rate` = round(mean(dt$snap_rate, na.rm = TRUE), 3),
    `Renter rate` = round(mean(dt$renter_rate, na.rm = TRUE), 3),
    `Median income ($)` = format(round(mean(dt$median_income, na.rm = TRUE), 0),
                                  big.mark = ","),
    `Pct. Black` = round(mean(dt$pct_black, na.rm = TRUE) * 100, 1),
    `Tract-months` = format(nrow(dt), big.mark = ",")
  )
}

tab1_data <- rbind(
  summ_fn(pre[early_optout == TRUE], "Early opt-out states"),
  summ_fn(pre[early_optout == FALSE], "Control states"),
  summ_fn(pre, "Full sample")
)

## Write LaTeX
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Tract Characteristics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & Early Opt-Out & Control & Full Sample \\\\\n",
  "\\midrule\n",
  sprintf("Tracts & %s & %s & %s \\\\\n",
          tab1_data$Tracts[1], tab1_data$Tracts[2], tab1_data$Tracts[3]),
  sprintf("Monthly filings (mean) & %s & %s & %s \\\\\n",
          tab1_data$`Monthly filings`[1], tab1_data$`Monthly filings`[2],
          tab1_data$`Monthly filings`[3]),
  sprintf("Filing rate (per 1,000 renters) & %s & %s & %s \\\\\n",
          tab1_data$`Filing rate`[1], tab1_data$`Filing rate`[2],
          tab1_data$`Filing rate`[3]),
  sprintf("SD(filing rate) & %s & %s & %s \\\\\n",
          tab1_data$`SD(filing rate)`[1], tab1_data$`SD(filing rate)`[2],
          tab1_data$`SD(filing rate)`[3]),
  sprintf("SNAP participation rate & %s & %s & %s \\\\\n",
          tab1_data$`SNAP rate`[1], tab1_data$`SNAP rate`[2],
          tab1_data$`SNAP rate`[3]),
  sprintf("Renter share & %s & %s & %s \\\\\n",
          tab1_data$`Renter rate`[1], tab1_data$`Renter rate`[2],
          tab1_data$`Renter rate`[3]),
  sprintf("Median household income (\\$) & %s & %s & %s \\\\\n",
          tab1_data$`Median income ($)`[1], tab1_data$`Median income ($)`[2],
          tab1_data$`Median income ($)`[3]),
  sprintf("Pct.\\ Black & %s & %s & %s \\\\\n",
          tab1_data$`Pct. Black`[1], tab1_data$`Pct. Black`[2],
          tab1_data$`Pct. Black`[3]),
  sprintf("Tract-months & %s & %s & %s \\\\\n",
          tab1_data$`Tract-months`[1], tab1_data$`Tract-months`[2],
          tab1_data$`Tract-months`[3]),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Pre-treatment period (January 2020--March 2021). ",
  "Filing rate is monthly eviction filings per 1,000 renter-occupied housing units. ",
  "SNAP participation rate and demographics from 2019 ACS 5-year estimates. ",
  "Early opt-out states are those that terminated SNAP Emergency Allotments ",
  "before the national termination in March 2023.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

## ═══════════════════════════════════════════════════════════════════
## TABLE 2: Main Results
## ═══════════════════════════════════════════════════════════════════

## CS aggregated ATT
cs_agg <- aggte(cs_out, type = "simple")

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of SNAP EA Expiration on Eviction Filing Rates}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & TWFE & CS & Dose-Response & SNAP Q4 \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ EA Ended & %s & %s & %s & \\\\\n",
          round(coef(twfe_main)["post"], 3),
          round(cs_agg$overall.att, 3),
          round(coef(dose_cont)["post"], 3)),
  sprintf(" & (%s) & (%s) & (%s) & \\\\\n",
          round(se(twfe_main)["post"], 3),
          round(cs_agg$overall.se, 3),
          round(se(dose_cont)["post"], 3)),
  sprintf("Post $\\times$ SNAP Rate & & & %s & \\\\\n",
          round(coef(dose_cont)["post:snap_rate"], 3)),
  sprintf(" & & & (%s) & \\\\\n",
          round(se(dose_cont)["post:snap_rate"], 3)),
  sprintf("Post $\\times$ Q4 (High SNAP) & & & & %s \\\\\n",
          round(coef(dose_q)["post:snap_quartileQ4_high"], 3)),
  sprintf(" & & & & (%s) \\\\\n",
          round(se(dose_q)["post:snap_quartileQ4_high"], 3)),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(twfe_main), big.mark = ","),
          format(nobs(twfe_main), big.mark = ","),
          format(nobs(dose_cont), big.mark = ","),
          format(nobs(dose_q), big.mark = ",")),
  sprintf("Tracts & %s & %s & %s & %s \\\\\n",
          format(length(unique(monthly$GEOID)), big.mark = ","),
          format(length(unique(monthly$GEOID)), big.mark = ","),
          format(length(unique(monthly$GEOID)), big.mark = ","),
          format(length(unique(monthly$GEOID)), big.mark = ",")),
  "Tract FE & Yes & --- & Yes & Yes \\\\\n",
  "Month FE & Yes & --- & Yes & Yes \\\\\n",
  "Estimator & TWFE & CS & TWFE & TWFE \\\\\n",
  sprintf("Treated states & %d & %d & %d & %d \\\\\n",
          diag$n_treated, diag$n_treated, diag$n_treated, diag$n_treated),
  sprintf("Pre-treatment SD$(Y)$ & %s & %s & %s & %s \\\\\n",
          diag$sd_y_pre, diag$sd_y_pre, diag$sd_y_pre, diag$sd_y_pre),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is monthly eviction filings per 1,000 renter-occupied ",
  "housing units. Column (1) reports two-way fixed effects with tract and month fixed effects. ",
  "Column (2) reports the Callaway and Sant'Anna (2021) ATT using not-yet-treated states as controls. ",
  "Column (3) interacts the treatment indicator with continuous SNAP participation rate. ",
  "Column (4) reports the treatment effect for the highest SNAP participation quartile. ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

## ═══════════════════════════════════════════════════════════════════
## TABLE 3: Robustness
## ═══════════════════════════════════════════════════════════════════

## Re-run Poisson for coefficient storage
pois <- fepois(
  filings ~ post | GEOID + month_num,
  data = monthly[filings >= 0],
  cluster = ~state_abbr
)

## Log specification
monthly[, log_filing := log(filing_rate + 0.01)]
log_fit <- feols(
  log_filing ~ post | GEOID + month_num,
  data = monthly,
  cluster = ~state_abbr
)

## Wave 1
wave1_states <- c("FL", "MO", "TN")
wave1_data <- monthly[state_abbr %in% wave1_states | early_optout == FALSE]
wave1_data[, post_w1 := as.integer(year_month >= as.Date("2021-04-01") & early_optout)]
wave1_fit <- feols(
  filing_rate ~ post_w1 | GEOID + month_num,
  data = wave1_data,
  cluster = ~state_abbr
)

## No-COVID
nocovid_data <- monthly[year_month < as.Date("2020-03-01") | year_month >= as.Date("2021-01-01")]
nocovid_fit <- feols(
  filing_rate ~ post | GEOID + month_num,
  data = nocovid_data,
  cluster = ~state_abbr
)

## Format stars
star <- function(p) {
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Alternative Specifications and Samples}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Baseline & Log & Poisson & Wave 1 & No COVID \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ EA Ended & %s%s & %s%s & %s%s & %s%s & %s%s \\\\\n",
          round(coef(twfe_main)["post"], 3),
          star(fixest::pvalue(twfe_main)["post"]),
          round(coef(log_fit)["post"], 3),
          star(fixest::pvalue(log_fit)["post"]),
          round(coef(pois)["post"], 3),
          star(fixest::pvalue(pois)["post"]),
          round(coef(wave1_fit)["post_w1"], 3),
          star(fixest::pvalue(wave1_fit)["post_w1"]),
          round(coef(nocovid_fit)["post"], 3),
          star(fixest::pvalue(nocovid_fit)["post"])),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\\n",
          round(se(twfe_main)["post"], 3),
          round(se(log_fit)["post"], 3),
          round(se(pois)["post"], 3),
          round(se(wave1_fit)["post_w1"], 3),
          round(se(nocovid_fit)["post"], 3)),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(nobs(twfe_main), big.mark = ","),
          format(nobs(log_fit), big.mark = ","),
          format(nobs(pois), big.mark = ","),
          format(nobs(wave1_fit), big.mark = ","),
          format(nobs(nocovid_fit), big.mark = ",")),
  "Outcome & Level & Log & Count & Level & Level \\\\\n",
  sprintf("Treated states & 8 & 8 & 8 & 3 & 8 \\\\\n"),
  "RI $p$-value & 0.415 & --- & --- & --- & --- \\\\\n",
  sprintf("LOSO range & [%s, %s] & --- & --- & --- & --- \\\\\n",
          round(min(loso$att), 3), round(max(loso$att), 3)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} All specifications include tract and month fixed effects with standard errors ",
  "clustered at the state level. Column (1) is the baseline from Table~\\ref{tab:main}. ",
  "Column (2) uses log(filing rate + 0.01). Column (3) estimates a Poisson model for filing counts. ",
  "Column (4) restricts to April 2021 opt-out states (FL, MO, TN) against control states. ",
  "Column (5) excludes March--December 2020 to remove the COVID eviction moratorium period. ",
  "RI $p$-value is from 1,000 randomization inference permutations of state treatment assignment. ",
  "LOSO is the leave-one-state-out range of point estimates. ",
  "$^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(table_dir, "tab3_robustness.tex"))
cat("Table 3 written.\n")

## ═══════════════════════════════════════════════════════════════════
## TABLE 4: Event Study Coefficients
## ═══════════════════════════════════════════════════════════════════

## Select key event times
es_key <- cs_es[cs_es$event_time %in% c(-12, -9, -6, -3, -1, 0, 3, 6, 9, 12, 15, 18), ]

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Dynamic Treatment Effects: Callaway-Sant'Anna Event Study}\n",
  "\\label{tab:event}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Months Relative to EA End & ATT & SE & 95\\% CI \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Pre-treatment}} \\\\\n"
)

for (i in seq_len(nrow(es_key))) {
  r <- es_key[i, ]
  if (r$event_time == 0) {
    tab4_tex <- paste0(tab4_tex,
      "\\midrule\n",
      "\\multicolumn{4}{l}{\\textit{Post-treatment}} \\\\\n"
    )
  }
  ci_str <- sprintf("[%s, %s]", round(r$ci_lower, 3), round(r$ci_upper, 3))
  tab4_tex <- paste0(tab4_tex,
    sprintf("$t = %+d$ & %s & (%s) & %s \\\\\n",
            r$event_time, round(r$att, 3), round(r$se, 3), ci_str))
}

tab4_tex <- paste0(tab4_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATTs ",
  "aggregated to dynamic event-time effects. The dependent variable is ",
  "monthly eviction filings per 1,000 renter-occupied housing units. ",
  "Period $t = -1$ is the omitted reference period. Standard errors ",
  "clustered at the state level. Control group: not-yet-treated states.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(table_dir, "tab4_event_study.tex"))
cat("Table 4 written.\n")

## ═══════════════════════════════════════════════════════════════════
## TABLE F1: Standardized Effect Size (SDE) Appendix
## ═══════════════════════════════════════════════════════════════════

## Pre-treatment SD of outcome
sd_y_pre <- sd(monthly[post == 0, filing_rate], na.rm = TRUE)

## Main outcomes for SDE
outcomes <- data.table(
  panel = c(rep("A", 3), rep("B", 2)),
  outcome = c(
    "Eviction filing rate (TWFE)",
    "Eviction filing rate (CS)",
    "Eviction filing rate (Poisson, log scale)",
    "Filing rate, high-SNAP tracts (Q4)",
    "Filing rate, low-income tracts (Q1)"
  ),
  beta = c(
    coef(twfe_main)["post"],
    cs_agg$overall.att,
    coef(pois)["post"],
    coef(dose_q)["post:snap_quartileQ4_high"],
    ## Q1 income: re-estimate
    {
      monthly[, income_quartile := cut(median_income,
                                        breaks = quantile(median_income,
                                                          probs = c(0, 0.25, 0.5, 0.75, 1),
                                                          na.rm = TRUE),
                                        labels = c("Q1_low", "Q2", "Q3", "Q4_high"),
                                        include.lowest = TRUE)]
      fit_q1 <- feols(filing_rate ~ post | GEOID + month_num,
                       data = monthly[income_quartile == "Q1_low"],
                       cluster = ~state_abbr)
      coef(fit_q1)["post"]
    }
  ),
  se_beta = c(
    se(twfe_main)["post"],
    cs_agg$overall.se,
    se(pois)["post"],
    se(dose_q)["post:snap_quartileQ4_high"],
    se(fit_q1)["post"]
  ),
  sd_y = c(
    sd_y_pre, sd_y_pre,
    sd(log(monthly[post == 0, filings] + 1), na.rm = TRUE),
    sd(monthly[post == 0 & snap_quartile == "Q4_high", filing_rate], na.rm = TRUE),
    sd(monthly[post == 0 & income_quartile == "Q1_low", filing_rate], na.rm = TRUE)
  )
)

outcomes[, sde := beta / sd_y]
outcomes[, se_sde := se_beta / sd_y]

## Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (is.na(sde)) return("---")
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

outcomes[, classification := sapply(sde, classify_sde)]

## Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the termination of SNAP Emergency Allotments ",
  "cause an increase in eviction filings in affected neighborhoods? ",
  "\\textbf{Policy mechanism:} The Families First Coronavirus Response Act (2020) ",
  "authorized Emergency Allotments that raised SNAP benefits to the maximum for each ",
  "household size; termination reduced monthly benefits by \\$95--250 per household, ",
  "tightening budgets for rent-burdened families. ",
  "\\textbf{Outcome definition:} Monthly eviction filings per 1,000 renter-occupied ",
  "housing units, from Princeton Eviction Lab Eviction Tracking System. ",
  "\\textbf{Treatment:} Binary (state opted out of EA before national termination). ",
  "\\textbf{Data:} Eviction Lab ETS tract-level weekly filings (2020--2023) merged with ",
  "Census ACS 2019 5-year estimates; 12,469 tracts across 20 states; 473,822 tract-months. ",
  "\\textbf{Method:} TWFE and Callaway-Sant'Anna DiD with tract and month fixed effects; ",
  "standard errors clustered at the state level. ",
  "\\textbf{Sample:} Census tracts in Eviction Lab coverage areas with positive ",
  "renter-occupied housing units; 8 treated states with ETS coverage. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD$(Y)$ & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in seq_len(nrow(outcomes))) {
  r <- outcomes[i]
  if (r$panel == "B" && i == which(outcomes$panel == "B")[1]) {
    tabF1_tex <- paste0(tabF1_tex,
      "\\midrule\n",
      "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n"
    )
  }
  tabF1_tex <- paste0(tabF1_tex,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
            r$outcome,
            round(r$beta, 3),
            round(r$se_beta, 3),
            round(r$sd_y, 3),
            round(r$sde, 3),
            round(r$se_sde, 3),
            r$classification))
}

tabF1_tex <- paste0(tabF1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
