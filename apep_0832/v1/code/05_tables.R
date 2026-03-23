## 05_tables.R — Generate all LaTeX tables
## apep_0832: The Access Cost of Fraud Prevention

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

panel <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")
rob_results <- readRDS("data/robustness_results.rds")

## Create rel_time for event study
panel[, rel_time := pmin(pmax(years_since_ebt, -5), 5)]

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

## Compute stats
pre <- panel[post_ebt == 0]
post <- panel[post_ebt == 1]
full <- panel

stats_tab <- data.table(
  Variable = c(
    "Low birth weight rate (\\%)",
    "Infant mortality rate",
    "Years since EBT adoption",
    "States",
    "State-years"
  ),
  `Full Sample Mean` = c(
    sprintf("%.3f", mean(full$lbw_rate_pct, na.rm=TRUE)),
    sprintf("%.2f", mean(full$im_rate, na.rm=TRUE)),
    sprintf("%.1f", mean(full$years_since_ebt, na.rm=TRUE)),
    as.character(uniqueN(full$state_code)),
    as.character(nrow(full))
  ),
  `Full Sample SD` = c(
    sprintf("%.3f", sd(full$lbw_rate_pct, na.rm=TRUE)),
    sprintf("%.2f", sd(full$im_rate, na.rm=TRUE)),
    sprintf("%.1f", sd(full$years_since_ebt, na.rm=TRUE)),
    "", ""
  ),
  `Pre-EBT Mean` = c(
    sprintf("%.3f", mean(pre$lbw_rate_pct, na.rm=TRUE)),
    sprintf("%.2f", mean(pre$im_rate, na.rm=TRUE)),
    "", as.character(uniqueN(pre$state_code)),
    as.character(nrow(pre))
  ),
  `Post-EBT Mean` = c(
    sprintf("%.3f", mean(post$lbw_rate_pct, na.rm=TRUE)),
    sprintf("%.2f", mean(post$im_rate, na.rm=TRUE)),
    "", as.character(uniqueN(post$state_code)),
    as.character(nrow(post))
  )
)

## Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Full Sample} & Pre-EBT & Post-EBT \\\\",
  "\\cmidrule(lr){2-3}",
  " & Mean & SD & Mean & Mean \\\\",
  "\\hline",
  sprintf("Low birth weight rate (\\%%) & %s & %s & %s & %s \\\\",
          stats_tab[1, `Full Sample Mean`], stats_tab[1, `Full Sample SD`],
          stats_tab[1, `Pre-EBT Mean`], stats_tab[1, `Post-EBT Mean`]),
  sprintf("States & %s & & %s & %s \\\\",
          stats_tab[4, `Full Sample Mean`], stats_tab[4, `Pre-EBT Mean`],
          stats_tab[4, `Post-EBT Mean`]),
  sprintf("State-year observations & %s & & %s & %s \\\\",
          stats_tab[5, `Full Sample Mean`], stats_tab[5, `Pre-EBT Mean`],
          stats_tab[5, `Post-EBT Mean`]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} State-year panel from County Health Rankings, 2010--2024. Low birth weight rate is the percentage of live births with weight below 2,500 grams, based on multi-year averages from the National Vital Statistics System. Pre-EBT observations are state-years before WIC EBT adoption (with a 2-year data lag adjustment); post-EBT are those after.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("Table 1 written.\n")

## ============================================================
## Table 2: Main Results
## ============================================================
cat("=== Generating Table 2: Main Results ===\n")

## Run regressions
twfe_main <- feols(lbw_rate_pct ~ post_ebt | state_code + year,
                   data = panel, cluster = ~state_code)

twfe_trend <- feols(lbw_rate_pct ~ post_ebt | state_code + year + state_code[year],
                    data = panel, cluster = ~state_code)

## CS-DiD
cs_panel <- panel[cohort_year > min(year)]
cs_panel[, state_id := as.integer(as.factor(state_code))]
cs_result <- tryCatch({
  att_gt(
    yname = "lbw_rate_pct", tname = "year", idname = "state_id",
    gname = "cohort_year", data = as.data.frame(cs_panel),
    control_group = "notyettreated", est_method = "dr",
    bstrap = TRUE, biters = 1000
  )
}, error = function(e) NULL)

cs_att <- if (!is.null(cs_result)) aggte(cs_result, type = "simple") else NULL

## Late adopters TWFE
late_panel <- panel[ebt_year >= 2011]
twfe_late <- feols(lbw_rate_pct ~ post_ebt | state_code + year,
                   data = late_panel, cluster = ~state_code)

## Narrow window
narrow <- panel[abs(years_since_ebt) <= 3]
twfe_narrow <- feols(lbw_rate_pct ~ post_ebt | state_code + year,
                     data = narrow, cluster = ~state_code)

## Build table manually for control
tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of WIC EBT Adoption on Low Birth Weight Rate}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & TWFE & State & CS-DiD & Late & Narrow \\\\",
  " & & Trends & & Adopters & Window \\\\",
  "\\hline",
  sprintf("Post EBT & %s & %s & %s & %s & %s \\\\",
    sprintf("%.4f", coef(twfe_main)["post_ebt"]),
    sprintf("%.4f", coef(twfe_trend)["post_ebt"]),
    if (!is.null(cs_att)) sprintf("%.4f", cs_att$overall.att) else "---",
    sprintf("%.4f", coef(twfe_late)["post_ebt"]),
    sprintf("%.4f", coef(twfe_narrow)["post_ebt"])
  ),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
    sprintf("%.4f", se(twfe_main)["post_ebt"]),
    sprintf("%.4f", se(twfe_trend)["post_ebt"]),
    if (!is.null(cs_att)) sprintf("%.4f", cs_att$overall.se) else "---",
    sprintf("%.4f", se(twfe_late)["post_ebt"]),
    sprintf("%.4f", se(twfe_narrow)["post_ebt"])
  ),
  "\\hline",
  sprintf("State FE & Yes & Yes & --- & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & --- & Yes & Yes \\\\"),
  sprintf("State trends & No & Yes & --- & No & No \\\\"),
  sprintf("Estimator & TWFE & TWFE & CS-DiD & TWFE & TWFE \\\\"),
  sprintf("States & %d & %d & %d & %d & %d \\\\",
    uniqueN(panel$state_code), uniqueN(panel$state_code),
    uniqueN(cs_panel$state_code), uniqueN(late_panel$state_code),
    uniqueN(narrow$state_code)),
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
    nrow(panel), nrow(panel), nrow(cs_panel), nrow(late_panel), nrow(narrow)),
  sprintf("Dep. var. mean & \\multicolumn{5}{c}{%.3f} \\\\", mean(panel$lbw_rate_pct, na.rm=TRUE)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is the state-level low birth weight rate (percent). Column~(1) is two-way fixed effects with state and year fixed effects. Column~(2) adds state-specific linear time trends. Column~(3) reports the overall ATT from the Callaway and Sant'Anna (2021) estimator using not-yet-treated states as the comparison group and doubly robust estimation. Column~(4) drops the four states adopting WIC EBT before 2011 (Michigan, Nevada, Kentucky, Texas), which have no pre-treatment periods in our panel. Column~(5) restricts to a $\\pm$3-year window around each state's EBT adoption. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")
cat("Table 2 written.\n")

## ============================================================
## Table 3: Robustness — Bootstrap, Placebo, Intensity
## ============================================================
cat("=== Generating Table 3: Robustness ===\n")

## Intensity
twfe_intensity <- feols(lbw_rate_pct ~ ebt_exposure | state_code + year,
                        data = panel[, ebt_exposure := pmax(0, year - 2 - ebt_year)],
                        cluster = ~state_code)

## Placebo
panel[, fake_post := as.integer((year - 2) >= (ebt_year - 3))]
pre_only <- panel[year - 2 < ebt_year]
twfe_placebo <- feols(lbw_rate_pct ~ fake_post | state_code + year,
                      data = pre_only, cluster = ~state_code)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Bootstrap, Placebo, and Intensity}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & TWFE & Bootstrap & Placebo & Intensity \\\\",
  " & (Baseline) & 95\\% CI & ($-3$ Years) & (Years Exposed) \\\\",
  "\\hline",
  sprintf("Post EBT & %.4f & & %.4f & \\\\",
    coef(twfe_main)["post_ebt"], coef(twfe_placebo)["fake_post"]),
  sprintf(" & (%.4f) & & (%.4f) & \\\\",
    se(twfe_main)["post_ebt"], se(twfe_placebo)["fake_post"]),
  sprintf("EBT exposure (years) & & & & %.5f \\\\",
    coef(twfe_intensity)["ebt_exposure"]),
  sprintf(" & & & & (%.5f) \\\\",
    se(twfe_intensity)["ebt_exposure"]),
  sprintf("Bootstrap 95\\%% CI & & [%.3f, %.3f] & & \\\\",
    rob_results$boot_ci[1], rob_results$boot_ci[2]),
  "\\hline",
  sprintf("State FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nrow(panel), nrow(panel), nrow(pre_only), nrow(panel)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column~(1) reproduces the baseline TWFE estimate. Column~(2) reports 95\\% confidence intervals from a pairs cluster bootstrap (999 replications, resampling states). Column~(3) runs a placebo test using only pre-treatment observations, with a fake treatment date 3 years before actual EBT adoption. Column~(4) replaces the binary treatment indicator with years of EBT exposure (capped at zero for pre-treatment). Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_robustness.tex")
cat("Table 3 written.\n")

## ============================================================
## Table 4: Adoption Timing and Treatment Variation
## ============================================================
cat("=== Generating Table 4: Adoption Timing ===\n")

adoption_stats <- panel[, .(
  n_states = uniqueN(state_code),
  mean_lbw_pre = mean(lbw_rate_pct[post_ebt == 0], na.rm = TRUE),
  mean_lbw_post = mean(lbw_rate_pct[post_ebt == 1], na.rm = TRUE),
  n_pre = sum(post_ebt == 0),
  n_post = sum(post_ebt == 1)
), by = adoption_group]

setorder(adoption_stats, adoption_group)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{WIC EBT Adoption Timing and Birth Outcomes by Cohort}",
  "\\label{tab:adoption}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "Adoption Group & States & Pre-EBT & Post-EBT & Pre & Post \\\\",
  " & & LBW (\\%) & LBW (\\%) & Obs & Obs \\\\",
  "\\hline"
)

for (i in 1:nrow(adoption_stats)) {
  tab4_lines <- c(tab4_lines, sprintf(
    "%s & %d & %.3f & %.3f & %d & %d \\\\",
    adoption_stats$adoption_group[i],
    adoption_stats$n_states[i],
    adoption_stats$mean_lbw_pre[i],
    adoption_stats$mean_lbw_post[i],
    adoption_stats$n_pre[i],
    adoption_stats$n_post[i]
  ))
}

tab4_lines <- c(tab4_lines,
  "\\hline",
  sprintf("All & %d & %.3f & %.3f & %d & %d \\\\",
    uniqueN(panel$state_code),
    mean(panel$lbw_rate_pct[panel$post_ebt == 0], na.rm=TRUE),
    mean(panel$lbw_rate_pct[panel$post_ebt == 1], na.rm=TRUE),
    sum(panel$post_ebt == 0),
    sum(panel$post_ebt == 1)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} States grouped by WIC EBT adoption year. Early adopters (Michigan 2004, Nevada 2005, Kentucky and Texas 2006) implemented EBT before the Healthy, Hunger-Free Kids Act mandate. LBW rates are the percentage of live births below 2,500 grams from County Health Rankings.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_adoption.tex")
cat("Table 4 written.\n")

## ============================================================
## Table F1: Standardized Effect Size (SDE) Appendix
## ============================================================
cat("=== Generating Table F1: SDE ===\n")

sd_lbw_pre <- sd(panel$lbw_rate_pct[panel$post_ebt == 0], na.rm = TRUE)

## TWFE estimate
twfe_beta <- coef(twfe_main)["post_ebt"]
twfe_se_val <- se(twfe_main)["post_ebt"]
sde_twfe <- twfe_beta / sd_lbw_pre
sde_se_twfe <- twfe_se_val / sd_lbw_pre

## CS-DiD estimate
cs_beta <- if (!is.null(cs_att)) cs_att$overall.att else NA
cs_se_val <- if (!is.null(cs_att)) cs_att$overall.se else NA
sde_cs <- cs_beta / sd_lbw_pre
sde_se_cs <- cs_se_val / sd_lbw_pre

## Classify
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

## SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the mandatory transition from paper vouchers to ",
  "Electronic Benefit Transfer (EBT) in the Special Supplemental Nutrition Program for ",
  "Women, Infants, and Children (WIC) affect infant health outcomes through ",
  "reduced vendor access? ",
  "\\textbf{Policy mechanism:} The Healthy, Hunger-Free Kids Act of 2010 required all ",
  "states to implement WIC EBT by October 2020, replacing paper food instruments with ",
  "electronic cards; this reduced fraud opportunities for small retailers, causing ",
  "independent vendor exits that potentially increased travel distance to authorized stores. ",
  "\\textbf{Outcome definition:} Low birth weight rate: percentage of live births with ",
  "birth weight below 2,500 grams, from multi-year National Vital Statistics System data ",
  "aggregated to the state-year level by County Health Rankings. ",
  "\\textbf{Treatment:} Binary indicator for state having completed WIC EBT implementation ",
  "(with a 2-year lag to account for data reporting windows). ",
  "\\textbf{Data:} County Health Rankings analytic data files 2010--2024, covering 51 states ",
  "(including DC) across 15 annual releases; underlying natality data from NCHS NVSS; ",
  "WIC EBT adoption dates from USDA FNS; 765 state-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (state + year FE) with state-clustered standard errors; ",
  "Callaway--Sant'Anna (2021) doubly robust estimator with not-yet-treated comparison; ",
  "wild cluster bootstrap (999 replications). ",
  "\\textbf{Sample:} All 50 states plus DC, annual observations 2010--2024; early adopters ",
  "(4 states, EBT pre-2007) have no pre-treatment panel observations. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sprintf("LBW rate (TWFE) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    twfe_beta, twfe_se_val, sd_lbw_pre, sde_twfe, sde_se_twfe, classify_sde(sde_twfe)),
  sprintf("LBW rate (CS-DiD) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    cs_beta, cs_se_val, sd_lbw_pre, sde_cs, sde_se_cs, classify_sde(sde_cs)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

## ============================================================
## Summary
## ============================================================
cat("\n=== All tables generated ===\n")
cat("Files in tables/:", paste(list.files("tables/"), collapse = ", "), "\n")
