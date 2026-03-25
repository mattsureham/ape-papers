## 05_tables.R — Generate all LaTeX tables (V1: zero figures)
## apep_0944: AVR and Federal Jury Acquittal Rates

library(data.table)
library(jsonlite)

# setwd handled by caller

panel <- fread("data/analysis_panel.csv")
main_res <- fromJSON("data/main_results.json")
robust_res <- fromJSON("data/robust_results.json")
summary_stats <- fromJSON("data/summary_stats.json")
cs_es <- fread("data/cs_event_study.csv")
loo_dt <- fread("data/loo_results.csv")
sa_es <- fread("data/sa_event_study.csv")

dir.create("tables", showWarnings = FALSE)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

fmt <- function(x, d = 3) formatC(round(x, d), format = "f", digits = d)

# ── Table 1: Summary Statistics ──────────────────────────────────────────
cat("Generating Table 1: Summary Statistics\n")

# Compute stats from panel
pre_panel <- panel[fiscalyr < 2016]
post_panel <- panel[fiscalyr >= 2016]

avr_pre <- panel[first_treat > 0 & fiscalyr < first_treat]
avr_post <- panel[first_treat > 0 & fiscalyr >= first_treat]
ctrl_all <- panel[first_treat == 0]

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Federal Jury Verdicts by District}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{AVR Districts} & \\multicolumn{2}{c}{Non-AVR Districts} & \\\\\n",
  " & Mean & SD & Mean & SD & Diff \\\\\n",
  "\\hline\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Pre-treatment (2000--2015)}} \\\\\n",
  "Acquittal rate & ", fmt(mean(avr_pre$acquittal_rate)), " & ", fmt(sd(avr_pre$acquittal_rate)), " & ",
    fmt(mean(ctrl_all[fiscalyr < 2016]$acquittal_rate)), " & ", fmt(sd(ctrl_all[fiscalyr < 2016]$acquittal_rate)), " & ",
    fmt(mean(avr_pre$acquittal_rate) - mean(ctrl_all[fiscalyr < 2016]$acquittal_rate)), " \\\\\n",
  "Jury verdicts/year & ", fmt(mean(avr_pre$n_verdicts), 1), " & ", fmt(sd(avr_pre$n_verdicts), 1), " & ",
    fmt(mean(ctrl_all[fiscalyr < 2016]$n_verdicts), 1), " & ", fmt(sd(ctrl_all[fiscalyr < 2016]$n_verdicts), 1), " & ",
    fmt(mean(avr_pre$n_verdicts) - mean(ctrl_all[fiscalyr < 2016]$n_verdicts), 1), " \\\\\n",
  "Acquittals/year & ", fmt(mean(avr_pre$n_acquittals), 1), " & ", fmt(sd(avr_pre$n_acquittals), 1), " & ",
    fmt(mean(ctrl_all[fiscalyr < 2016]$n_acquittals), 1), " & ", fmt(sd(ctrl_all[fiscalyr < 2016]$n_acquittals), 1), " & ",
    fmt(mean(avr_pre$n_acquittals) - mean(ctrl_all[fiscalyr < 2016]$n_acquittals), 1), " \\\\\n",
  "\\hline\n",
  "Districts & \\multicolumn{2}{c}{", summary_stats$n_treated_districts, "} & ",
    "\\multicolumn{2}{c}{", summary_stats$n_control_districts, "} & \\\\\n",
  "District-years & \\multicolumn{2}{c}{", nrow(avr_pre), "} & ",
    "\\multicolumn{2}{c}{", nrow(ctrl_all[fiscalyr < 2016]), "} & \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Unit of observation is a federal judicial district-fiscal year. ",
  "AVR districts are in states that adopted automatic voter registration between 2016 and 2023. ",
  "Acquittal rate is the share of jury trial verdicts resulting in acquittal. ",
  "Total jury verdicts: ", formatC(summary_stats$total_verdicts, format = "d", big.mark = ","), ". ",
  "Data from the FJC Integrated Database, 2000--2024.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, "tables/tab1_summary.tex")

# ── Table 2: Main Results ────────────────────────────────────────────────
cat("Generating Table 2: Main Results\n")

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Automatic Voter Registration on Jury Acquittal Rates}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & TWFE & TWFE & Callaway-- \\\\\n",
  " & Unweighted & Verdict-weighted & Sant'Anna \\\\\n",
  "\\hline\n",
  "AVR $\\times$ Post & ", fmt(main_res$twfe_coef, 4), stars(main_res$twfe_pval), " & ",
    fmt(main_res$twfe_w_coef, 4), stars(main_res$twfe_w_pval), " & ",
    fmt(main_res$cs_att, 4), " \\\\\n",
  " & (", fmt(main_res$twfe_se, 4), ") & (",
    fmt(main_res$twfe_w_se, 4), ") & (",
    fmt(main_res$cs_se, 4), ") \\\\\n",
  " & & & [", fmt(main_res$cs_ci_lower, 4), ", ", fmt(main_res$cs_ci_upper, 4), "] \\\\\n",
  "\\hline\n",
  "District FE & Yes & Yes & --- \\\\\n",
  "Year FE & Yes & Yes & --- \\\\\n",
  "Clustering & State & State & --- \\\\\n",
  "Observations & ", formatC(main_res$n_obs, format = "d", big.mark = ","), " & ",
    formatC(main_res$n_obs, format = "d", big.mark = ","), " & ",
    formatC(main_res$n_obs, format = "d", big.mark = ","), " \\\\\n",
  "Districts & ", main_res$n_districts, " & ", main_res$n_districts, " & ", main_res$n_districts, " \\\\\n",
  "Treated districts & ", main_res$n_treated, " & ", main_res$n_treated, " & ", main_res$n_treated, " \\\\\n",
  "Clusters & ", main_res$n_clusters, " & ", main_res$n_clusters, " & ", main_res$n_clusters, " \\\\\n",
  "Pre-trend $F$-test ($p$) & \\multicolumn{3}{c}{", fmt(main_res$pre_trend_p, 3), "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is the jury acquittal rate (acquittals/total jury verdicts) ",
  "at the federal district-year level. Column (1) reports two-way fixed effects with district and year FE. ",
  "Column (2) weights by the number of jury verdicts. Column (3) uses the Callaway and Sant'Anna (2021) ",
  "estimator with never-treated districts as controls. Standard errors clustered at the state level in ",
  "parentheses; 95\\% confidence intervals in brackets. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, "tables/tab2_main.tex")

# ── Table 3: Event Study Coefficients ────────────────────────────────────
cat("Generating Table 3: Event Study\n")

es_show <- cs_es[event_time >= -5 & event_time <= 5]
es_rows <- paste(sapply(1:nrow(es_show), function(i) {
  et <- es_show$event_time[i]
  p <- 2 * (1 - pnorm(abs(es_show$estimate[i] / es_show$se[i])))
  paste0("$t", ifelse(et >= 0, "+", ""), et, "$ & ",
         fmt(es_show$estimate[i], 4), stars(p), " & (",
         fmt(es_show$se[i], 4), ") & [",
         fmt(es_show$ci_lower[i], 4), ", ", fmt(es_show$ci_upper[i], 4), "] \\\\")
}), collapse = "\n")

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Effects of AVR on Acquittal Rates}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Event time & Estimate & SE & 95\\% CI \\\\\n",
  "\\hline\n",
  es_rows, "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Callaway--Sant'Anna dynamic aggregation. Event time is years relative to ",
  "state AVR effective date. Estimates are average treatment effects on the treated by event time. ",
  "Standard errors in parentheses; 95\\% confidence intervals in brackets.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, "tables/tab3_event_study.tex")

# ── Table 4: Robustness ─────────────────────────────────────────────────
cat("Generating Table 4: Robustness\n")

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Specification & Estimate & SE \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Main estimates}} \\\\\n",
  "Callaway--Sant'Anna (baseline) & ", fmt(main_res$cs_att, 4), " & (", fmt(main_res$cs_se, 4), ") \\\\\n",
  "TWFE (unweighted) & ", fmt(main_res$twfe_coef, 4), " & (", fmt(main_res$twfe_se, 4), ") \\\\\n",
  "TWFE (verdict-weighted) & ", fmt(main_res$twfe_w_coef, 4), " & (", fmt(main_res$twfe_w_se, 4), ") \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Specification checks}} \\\\\n",
  "Excluding COVID years (2020--2021) & ", fmt(robust_res$nocovid_att, 4), " & (", fmt(robust_res$nocovid_se, 4), ") \\\\\n",
  "Placebo (treatment shifted $-3$ years) & ", fmt(robust_res$placebo_att, 4), " & (", fmt(robust_res$placebo_se, 4), ") \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Alternative outcomes}} \\\\\n",
  "Log(jury verdicts) & ", fmt(robust_res$log_verdicts_coef, 4), " & (", fmt(robust_res$log_verdicts_se, 4), ") \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel D: Inference}} \\\\\n",
  "Leave-one-state-out range & \\multicolumn{2}{c}{[",
    fmt(robust_res$loo_range[1], 4), ", ", fmt(robust_res$loo_range[2], 4), "]} \\\\\n",
  "Randomization inference $p$-value & \\multicolumn{2}{c}{", fmt(robust_res$ri_pval, 3), "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A shows main specifications. Panel B tests sensitivity to COVID disruption ",
  "and placebo timing. Panel C uses log jury verdicts as an alternative outcome (extensive margin). ",
  "Panel D reports leave-one-state-out range of Callaway--Sant'Anna ATT estimates ",
  "and randomization inference $p$-value (500 permutations, treatment permuted at state level). ",
  "All standard errors clustered at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, "tables/tab4_robustness.tex")

# ── Table F1: SDE Appendix ──────────────────────────────────────────────
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDE for main outcome
sd_y_pre <- sd(panel[fiscalyr < 2016, acquittal_rate])
sde_main <- main_res$cs_att / sd_y_pre
se_sde_main <- main_res$cs_se / sd_y_pre

# Classify
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_class <- classify_sde(sde_main)

# Panel B: Heterogeneity by early vs late adopters
early_states <- unique(panel[first_treat > 0 & first_treat <= 2018, state_abbr])
late_states <- unique(panel[first_treat > 2018, state_abbr])

# Compute early/late effects using TWFE on subsamples
library(fixest)
panel_early <- panel[state_abbr %in% early_states | first_treat == 0]
panel_late <- panel[state_abbr %in% late_states | first_treat == 0]

twfe_early <- feols(acquittal_rate ~ treated | dist_id + fiscalyr,
                    data = panel_early, cluster = ~state_abbr)
twfe_late <- feols(acquittal_rate ~ treated | dist_id + fiscalyr,
                   data = panel_late, cluster = ~state_abbr)

sde_early <- coef(twfe_early)["treated"] / sd_y_pre
se_sde_early <- se(twfe_early)["treated"] / sd_y_pre
sde_late <- coef(twfe_late)["treated"] / sd_y_pre
se_sde_late <- se(twfe_late)["treated"] / sd_y_pre

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does automatic voter registration (AVR) affect federal criminal jury acquittal rates by expanding voter rolls used for jury pool selection? ",
  "\\textbf{Policy mechanism:} AVR automatically registers eligible citizens at DMV interactions unless they opt out, expanding voter registration rolls by 9--94\\% with disproportionately younger and more diverse new registrants, thereby mechanically reshaping the jury pool in federal courts that draw jurors from voter lists. ",
  "\\textbf{Outcome definition:} Jury acquittal rate, defined as the number of jury trial acquittals divided by total jury trial verdicts (acquittals plus convictions) per federal judicial district per fiscal year. ",
  "\\textbf{Treatment:} Binary; equals one for district-years after the state adopted AVR. ",
  "\\textbf{Data:} Federal Judicial Center Integrated Database (IDB), criminal defendant records 2000--2024, 94 federal judicial districts, ",
  formatC(summary_stats$n_obs, format = "d", big.mark = ","), " district-year observations with ",
  formatC(summary_stats$total_verdicts, format = "d", big.mark = ","), " jury verdicts. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered difference-in-differences with never-treated districts as controls; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Federal judicial districts in US states and DC with at least 3 jury verdicts per year on average and 10+ years of data; territories (PR, VI, GU, MP) excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the acquittal rate (", fmt(sd_y_pre, 3), "). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Acquittal rate & ", fmt(main_res$cs_att, 4), " & ", fmt(main_res$cs_se, 4), " & ",
    fmt(sd_y_pre), " & ", fmt(sde_main, 3), " & ", fmt(se_sde_main, 3), " & ", sde_class, " \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n",
  "Early adopters ($\\leq$2018) & ", fmt(coef(twfe_early)["treated"], 4), " & ", fmt(se(twfe_early)["treated"], 4), " & ",
    fmt(sd_y_pre), " & ", fmt(sde_early, 3), " & ", fmt(se_sde_early, 3), " & ", classify_sde(sde_early), " \\\\\n",
  "Late adopters ($>$2018) & ", fmt(coef(twfe_late)["treated"], 4), " & ", fmt(se(twfe_late)["treated"], 4), " & ",
    fmt(sd_y_pre), " & ", fmt(sde_late, 3), " & ", fmt(se_sde_late, 3), " & ", classify_sde(sde_late), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_event_study.tex\n")
cat("  tables/tab4_robustness.tex\n")
cat("  tables/tabF1_sde.tex\n")

cat("\n=== 05_tables.R complete ===\n")
