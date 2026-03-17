## 05_tables.R — Generate all LaTeX tables
## apep_0711: Online sports betting and suicide mortality

source("00_packages.R")

cat("=== Generating Tables ===\n")

## --- Load results ---
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
panel <- results$panel

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("--- Table 1: Summary Statistics ---\n")

summ <- panel %>%
  group_by(Group = ifelse(ever_treated == 1, "Treated States", "Control States")) %>%
  summarise(
    `N (state-weeks)` = n(),
    `N States` = n_distinct(state_abbr),
    `Mean Suicide Deaths` = sprintf("%.2f", mean(suicide_median, na.rm = TRUE)),
    `SD Suicide Deaths` = sprintf("%.2f", sd(suicide_median, na.rm = TRUE)),
    `Min` = sprintf("%.2f", min(suicide_median, na.rm = TRUE)),
    `Max` = sprintf("%.2f", max(suicide_median, na.rm = TRUE)),
    .groups = "drop"
  )

## Also compute overall statistics
overall <- panel %>%
  summarise(
    Group = "Full Sample",
    `N (state-weeks)` = n(),
    `N States` = n_distinct(state_abbr),
    `Mean Suicide Deaths` = sprintf("%.2f", mean(suicide_median, na.rm = TRUE)),
    `SD Suicide Deaths` = sprintf("%.2f", sd(suicide_median, na.rm = TRUE)),
    `Min` = sprintf("%.2f", min(suicide_median, na.rm = TRUE)),
    `Max` = sprintf("%.2f", max(suicide_median, na.rm = TRUE))
  )

summ_all <- bind_rows(summ, overall)

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Weekly Suicide Deaths by Treatment Status}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & N (state-weeks) & N States & Mean & SD & Min & Max \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(summ_all)) {
  row <- summ_all[i, ]
  tab1_tex <- paste0(tab1_tex,
    row$Group, " & ", row$`N (state-weeks)`, " & ", row$`N States`, " & ",
    row$`Mean Suicide Deaths`, " & ", row$`SD Suicide Deaths`, " & ",
    row$Min, " & ", row$Max, " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Unit of observation is state-week. Suicide deaths are median model-based ",
  "provisional estimates from the CDC Early Model-Based Provisional Estimates dataset (v2g4-wqg2), ",
  "covering 51 jurisdictions and years 2016--2021. Treated states are those that legalized online sports ",
  "betting during the sample window (14 states). Control states had no online sports betting legalization ",
  "during this period (37 states plus DC).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

## ============================================================
## Table 2: Main Results (TWFE + CS-DiD)
## ============================================================
cat("--- Table 2: Main Results ---\n")

twfe <- results$twfe
cs_agg <- results$cs_agg

## Extract CS-DiD results
cs_att <- cs_agg$overall.att
cs_se <- cs_agg$overall.se

## Stars function
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

twfe_coef <- coef(twfe)["treated_post"]
twfe_se <- se(twfe)["treated_post"]
twfe_p <- pvalue(twfe)["treated_post"]

## NFL interaction
nfl <- results$nfl_int
nfl_base_coef <- coef(nfl)["treated_post"]
nfl_base_se <- se(nfl)["treated_post"]
nfl_base_p <- pvalue(nfl)["treated_post"]
nfl_int_coef <- coef(nfl)["treated_post:nfl_season"]
nfl_int_se <- se(nfl)["treated_post:nfl_season"]
nfl_int_p <- pvalue(nfl)["treated_post:nfl_season"]

## Monthly aggregation
monthly <- robust$monthly
month_coef <- coef(monthly)["treated_post"]
month_se <- se(monthly)["treated_post"]
month_p <- pvalue(monthly)["treated_post"]

## RI p-value
ri_p <- robust$ri_pvalue

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Online Sports Betting Legalization on Suicide Deaths}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & TWFE & CS-DiD & NFL Interaction & Monthly \\\\\n",
  "\\midrule\n",
  "Online Betting Legal & ", sprintf("%.3f", twfe_coef), "$", stars(twfe_p), "$ & ",
    sprintf("%.3f", cs_att), " & ",
    sprintf("%.3f", nfl_base_coef), "$", stars(nfl_base_p), "$ & ",
    sprintf("%.3f", month_coef), "$", stars(month_p), "$ \\\\\n",
  " & (", sprintf("%.3f", twfe_se), ") & (",
    sprintf("%.3f", cs_se), ") & (",
    sprintf("%.3f", nfl_base_se), ") & (",
    sprintf("%.3f", month_se), ") \\\\\n",
  " & & & & \\\\\n"
)

## Add NFL interaction row if applicable
if (!is.na(nfl_int_coef)) {
  tab2_tex <- paste0(tab2_tex,
    "$\\times$ NFL Season & & & ",
    sprintf("%.3f", nfl_int_coef), "$", stars(nfl_int_p), "$ & \\\\\n",
    " & & & (", sprintf("%.3f", nfl_int_se), ") & \\\\\n"
  )
}

tab2_tex <- paste0(tab2_tex,
  "\\midrule\n",
  "State FE & Yes & --- & Yes & Yes \\\\\n",
  "Week FE & Yes & --- & Yes & Yes \\\\\n",
  "Estimator & TWFE & CS-DiD & TWFE & TWFE \\\\\n",
  "Observations & ", format(nobs(twfe), big.mark = ","), " & ",
    format(nrow(results$cs_data), big.mark = ","), " & ",
    format(nobs(nfl), big.mark = ","), " & ",
    format(nobs(monthly), big.mark = ","), " \\\\\n",
  "RI $p$-value & ", sprintf("%.3f", ri_p), " & & & \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is median model-based provisional suicide death count at the ",
  "state-week level. Column (1) reports two-way fixed effects (TWFE) with state and week fixed effects. ",
  "Column (2) reports the Callaway and Sant'Anna (2021) doubly robust estimator using never-treated states as controls. ",
  "Column (3) adds an interaction with an NFL season indicator (weeks 36--52 and 1--7). ",
  "Column (4) aggregates to the state-month level. Standard errors clustered at the state level in parentheses. ",
  "Randomization inference (RI) $p$-value based on 999 permutations of treatment assignment across states. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

## ============================================================
## Table 3: Leave-One-Out
## ============================================================
cat("--- Table 3: Leave-One-Out ---\n")

loo <- robust$loo
loo <- loo %>% arrange(excluded_state)

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Leave-One-Out: Excluding Each Treated State}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Excluded State & Coefficient & SE & $p$-value \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(loo)) {
  tab3_tex <- paste0(tab3_tex,
    loo$excluded_state[i], " & ",
    sprintf("%.3f", loo$coef[i]), "$", stars(loo$pval[i]), "$ & (",
    sprintf("%.3f", loo$se[i]), ") & ",
    sprintf("%.3f", loo$pval[i]), " \\\\\n")
}

tab3_tex <- paste0(tab3_tex,
  "\\midrule\n",
  "Full sample & ", sprintf("%.3f", coef(twfe)["treated_post"]), "$",
    stars(pvalue(twfe)["treated_post"]), "$ & (",
    sprintf("%.3f", se(twfe)["treated_post"]), ") & ",
    sprintf("%.3f", pvalue(twfe)["treated_post"]), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row excludes the named treated state from the estimation sample. ",
  "All specifications use TWFE with state and week fixed effects. Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:loo}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_loo.tex")

## ============================================================
## Table 4: Robustness (Pre-COVID + Placebo)
## ============================================================
cat("--- Table 4: Robustness ---\n")

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness: Pre-COVID Restriction and Placebo Outcomes}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Pre-COVID & Placebo: Accidents \\\\\n",
  "\\midrule\n"
)

if (!is.null(robust$pre_covid)) {
  pc_coef <- coef(robust$pre_covid)["treated_post"]
  pc_se <- se(robust$pre_covid)["treated_post"]
  pc_p <- pvalue(robust$pre_covid)["treated_post"]
  pc_n <- nobs(robust$pre_covid)
  tab4_tex <- paste0(tab4_tex,
    "Online Betting Legal & ", sprintf("%.3f", pc_coef), "$", stars(pc_p), "$ & ")
} else {
  tab4_tex <- paste0(tab4_tex, "Online Betting Legal & --- & ")
  pc_se <- NA; pc_n <- NA
}

if (!is.null(robust$placebo)) {
  pl_coef <- coef(robust$placebo)["treated_post"]
  pl_se <- se(robust$placebo)["treated_post"]
  pl_p <- pvalue(robust$placebo)["treated_post"]
  pl_n <- nobs(robust$placebo)
  tab4_tex <- paste0(tab4_tex,
    sprintf("%.3f", pl_coef), "$", stars(pl_p), "$ \\\\\n")
} else {
  tab4_tex <- paste0(tab4_tex, "--- \\\\\n")
  pl_se <- NA; pl_n <- NA
}

## Standard errors
tab4_tex <- paste0(tab4_tex,
  " & ",
  ifelse(!is.na(pc_se), paste0("(", sprintf("%.3f", pc_se), ")"), ""),
  " & ",
  ifelse(!is.na(pl_se), paste0("(", sprintf("%.3f", pl_se), ")"), ""),
  " \\\\\n",
  "\\midrule\n",
  "State FE & Yes & Yes \\\\\n",
  "Week FE & Yes & Yes \\\\\n",
  "Sample & Pre-March 2020 & Full \\\\\n",
  "Outcome & Suicides & Transport Accidents \\\\\n",
  "Observations & ",
  ifelse(!is.na(pc_n), format(pc_n, big.mark = ","), "---"),
  " & ",
  ifelse(!is.na(pl_n), format(pl_n, big.mark = ","), "---"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) restricts the sample to the pre-COVID period (before March 2020) ",
  "using only the four earliest-treated states (NJ, PA, IN, WV) and all control states. ",
  "Column (2) estimates the same specification using transport accident deaths as a placebo outcome ",
  "from the same CDC provisional dataset. Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

## ============================================================
## Table F1: Standardized Effect Sizes (MANDATORY)
## ============================================================
cat("--- Table F1: Standardized Effect Sizes ---\n")

## Main outcome: suicide deaths
beta_main <- coef(results$twfe)["treated_post"]
se_main <- se(results$twfe)["treated_post"]
sd_y_main <- sd(panel$suicide_median, na.rm = TRUE)
sde_main <- beta_main / sd_y_main
se_sde_main <- se_main / sd_y_main

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

## SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does staggered state legalization of online sports betting increase suicide mortality in the general population? ",
  "\\textbf{Policy mechanism:} State-level legalization permits commercial operators to offer mobile/online sports wagering to residents, ",
  "dramatically expanding gambling accessibility from in-person casinos to smartphones. The treatment is the activation date of mobile betting. ",
  "\\textbf{Outcome definition:} Median model-based provisional estimate of weekly suicide deaths per state from the CDC Early ",
  "Model-Based Provisional Estimates. ",
  "\\textbf{Treatment:} Binary indicator equal to one after a state activates online sports betting. ",
  "\\textbf{Data:} CDC provisional mortality dataset (v2g4-wqg2), 51 jurisdictions, state-week observations, 2016--2021. ",
  "\\textbf{Method:} Two-way fixed effects with state and week fixed effects; Callaway--Sant'Anna doubly robust estimator for ",
  "heterogeneity-robust aggregation; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 51 U.S. jurisdictions (50 states plus DC); 14 treated states with staggered online betting activation ",
  "between June 2018 and January 2022; observations with non-missing suicide estimates retained. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of weekly suicide deaths. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "Weekly Suicide Deaths & ",
    sprintf("%.3f", beta_main), " & ",
    sprintf("%.3f", se_main), " & ",
    sprintf("%.3f", sd_y_main), " & ",
    sprintf("%.4f", sde_main), " & ",
    sprintf("%.4f", se_sde_main), " & ",
    classify(sde_main), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\n=== All Tables Generated ===\n")
cat("Files written:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_loo.tex\n")
cat("  tables/tab4_robustness.tex\n")
cat("  tables/tabF1_sde.tex\n")
