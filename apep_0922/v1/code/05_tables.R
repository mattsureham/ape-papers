## 05_tables.R — Generate all LaTeX tables
## APEP paper apep_0922: Alkaline Hydrolysis and Funeral Industry Competition

source("00_packages.R")

## ── Load results ─────────────────────────────────────────────────────────────
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
county <- readRDS("../data/county_panel.rds")
state_panel <- readRDS("../data/state_panel.rds")

county_did <- results$county_did
state_did <- results$state_did

## ── Helper: format numbers ───────────────────────────────────────────────────
fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits, big.mark = ",")
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")
fmt_pct <- function(x, digits = 1) formatC(x * 100, format = "f", digits = digits)
stars <- function(p) ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))

## ══════════════════════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ══════════════════════════════════════════════════════════════════════════════

## County-level stats
county_stats <- county_did[, .(
  mean_estabs = mean(estabs, na.rm = TRUE),
  sd_estabs = sd(estabs, na.rm = TRUE),
  min_estabs = min(estabs, na.rm = TRUE),
  max_estabs = max(estabs, na.rm = TRUE)
)]

## State-level stats
state_stats <- state_did[, .(
  mean_empl = mean(employment, na.rm = TRUE),
  sd_empl = sd(employment, na.rm = TRUE),
  min_empl = min(employment, na.rm = TRUE),
  max_empl = max(employment, na.rm = TRUE),
  mean_wage = mean(avg_wkly_wage, na.rm = TRUE),
  sd_wage = sd(avg_wkly_wage, na.rm = TRUE),
  min_wage = min(avg_wkly_wage, na.rm = TRUE),
  max_wage = max(avg_wkly_wage, na.rm = TRUE),
  mean_state_estabs = mean(estabs, na.rm = TRUE),
  sd_state_estabs = sd(estabs, na.rm = TRUE)
)]

## Treatment breakdown
n_counties <- uniqueN(county_did$county_fips)
n_county_obs <- nrow(county_did)
n_states <- uniqueN(state_did$state_fips)
n_state_obs <- nrow(state_did)
n_treated_states <- uniqueN(county_did[cohort > 0, state_fips])
n_control_states <- uniqueN(county_did[cohort == 0, state_fips])

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Variable & Mean & Std.~Dev. & Min & Max \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: County-Level (NAICS 812210)}} \\\\\n",
  sprintf("Funeral home establishments & %s & %s & %s & %s \\\\\n",
          fmt(county_stats$mean_estabs, 2), fmt(county_stats$sd_estabs, 2),
          fmt_int(county_stats$min_estabs), fmt_int(county_stats$max_estabs)),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: State-Level (NAICS 812210)}} \\\\\n",
  sprintf("Funeral home employment & %s & %s & %s & %s \\\\\n",
          fmt(state_stats$mean_empl, 0), fmt(state_stats$sd_empl, 0),
          fmt_int(state_stats$min_empl), fmt_int(state_stats$max_empl)),
  sprintf("Avg.~weekly wage (\\$) & %s & %s & %s & %s \\\\\n",
          fmt(state_stats$mean_wage, 0), fmt(state_stats$sd_wage, 0),
          fmt_int(state_stats$min_wage), fmt_int(state_stats$max_wage)),
  sprintf("Funeral home establishments & %s & %s & --- & --- \\\\\n",
          fmt(state_stats$mean_state_estabs, 0), fmt(state_stats$sd_state_estabs, 0)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sprintf("\\item \\textit{Notes:} Panel A: N = %s county-year observations across %s counties ",
          fmt_int(n_county_obs), fmt_int(n_counties)),
  sprintf("in %d states (%d treated, %d never-treated), 2014--2023. ",
          n_states, n_treated_states, n_control_states),
  "Establishments are annual average counts from the BLS Quarterly Census of Employment and Wages (QCEW). ",
  sprintf("Panel B: N = %s state-year observations. ", fmt_int(n_state_obs)),
  "Employment and wages are annual averages for NAICS 812210 (Funeral Homes and Funeral Services), private sector.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

## ══════════════════════════════════════════════════════════════════════════════
## TABLE 2: Main DiD Results
## ══════════════════════════════════════════════════════════════════════════════

agg_e <- results$agg_estabs
agg_l <- results$agg_empl
agg_w <- results$agg_wage
twfe_e <- results$twfe_estabs
twfe_l <- results$twfe_empl
twfe_w <- results$twfe_wage

## CS-DiD p-values (two-sided normal approximation)
p_cs_e <- 2 * pnorm(-abs(agg_e$overall.att / agg_e$overall.se))
p_cs_l <- 2 * pnorm(-abs(agg_l$overall.att / agg_l$overall.se))
p_cs_w <- 2 * pnorm(-abs(agg_w$overall.att / agg_w$overall.se))

## TWFE p-values
p_twfe_e <- pvalue(twfe_e)["treated"]
p_twfe_l <- pvalue(twfe_l)["treated"]
p_twfe_w <- pvalue(twfe_w)["treated"]

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Alkaline Hydrolysis Legalization on the Funeral Industry}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Establishments & ln(Employment) & ln(Wage) \\\\\n",
  " & County-level & State-level & State-level \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Callaway--Sant'Anna (2021)}} \\\\\n",
  sprintf("ATT & %s%s & %s%s & %s%s \\\\\n",
          fmt(agg_e$overall.att), stars(p_cs_e),
          fmt(agg_l$overall.att), stars(p_cs_l),
          fmt(agg_w$overall.att), stars(p_cs_w)),
  sprintf("     & (%s) & (%s) & (%s) \\\\\n",
          fmt(agg_e$overall.se), fmt(agg_l$overall.se), fmt(agg_w$overall.se)),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: TWFE}} \\\\\n",
  sprintf("Treated & %s%s & %s%s & %s%s \\\\\n",
          fmt(coef(twfe_e)["treated"]), stars(p_twfe_e),
          fmt(coef(twfe_l)["treated"]), stars(p_twfe_l),
          fmt(coef(twfe_w)["treated"]), stars(p_twfe_w)),
  sprintf("        & (%s) & (%s) & (%s) \\\\\n",
          fmt(se(twfe_e)["treated"]), fmt(se(twfe_l)["treated"]), fmt(se(twfe_w)["treated"])),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          fmt_int(nrow(county_did)), fmt_int(nrow(state_did)), fmt_int(nrow(state_did))),
  sprintf("Units & %s counties & %d states & %d states \\\\\n",
          fmt_int(uniqueN(county_did$county_fips)), uniqueN(state_did$state_fips),
          uniqueN(state_did$state_fips)),
  "Control group & Not-yet-treated & Not-yet-treated & Not-yet-treated \\\\\n",
  "Clustering & State & --- & --- \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A reports the overall average treatment effect on the treated (ATT) ",
  "from \\citet{callaway2021difference}. Panel B reports two-way fixed effects (TWFE) estimates. ",
  "Standard errors in parentheses, clustered at the state level. ",
  "Column (1) uses county-level annual establishment counts. ",
  "Columns (2)--(3) use state-level log employment and log average weekly wage. ",
  "Treatment cohorts: 2017 (AL, CA, NV), 2018 (NC, UT), 2020 (WA), 2021 (OK), 2022 (AZ, HI), 2023 (VA). ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

## ══════════════════════════════════════════════════════════════════════════════
## TABLE 3: Event Study Coefficients
## ══════════════════════════════════════════════════════════════════════════════

es_e <- results$es_estabs
es_l <- results$es_empl
es_w <- results$es_wage

## Extract event-time coefficients
es_data <- data.table(
  e = es_e$egt,
  att_estabs = es_e$att.egt,
  se_estabs = es_e$se.egt,
  att_empl = es_l$att.egt,
  se_empl = es_l$se.egt,
  att_wage = es_w$att.egt,
  se_wage = es_w$se.egt
)

## Compute p-values
es_data[, `:=`(
  p_estabs = 2 * pnorm(-abs(att_estabs / se_estabs)),
  p_empl = 2 * pnorm(-abs(att_empl / se_empl)),
  p_wage = 2 * pnorm(-abs(att_wage / se_wage))
)]

es_rows <- ""
for (i in seq_len(nrow(es_data))) {
  r <- es_data[i]
  if (r$e == -1) {
    ## Reference period: coefficient is 0 by construction
    es_rows <- paste0(es_rows,
      "$t-1$ & \\multicolumn{3}{c}{\\textit{Reference period}} \\\\\n"
    )
  } else {
    es_rows <- paste0(es_rows,
      sprintf("$t%+d$ & %s%s & %s%s & %s%s \\\\\n",
              r$e,
              fmt(r$att_estabs), stars(r$p_estabs),
              fmt(r$att_empl), stars(r$p_empl),
              fmt(r$att_wage), stars(r$p_wage)),
      sprintf("       & (%s) & (%s) & (%s) \\\\\n",
              fmt(r$se_estabs), fmt(r$se_empl), fmt(r$se_wage))
    )
  }
}

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Treatment Effects}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Event time & Establishments & ln(Employment) & ln(Wage) \\\\\n",
  "\\midrule\n",
  es_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dynamic ATT estimates from Callaway--Sant'Anna (2021), ",
  "aggregated by event time $e$ (years relative to legalization). ",
  "Standard errors in parentheses. Columns as in Table~\\ref{tab:main}. ",
  "$t-1$ is the omitted reference period. ",
  "Pre-treatment coefficients ($e < 0$) test the parallel trends assumption. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:eventstudy}\n",
  "\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_eventstudy.tex")

## ══════════════════════════════════════════════════════════════════════════════
## TABLE 4: Mechanisms and Heterogeneity
## ══════════════════════════════════════════════════════════════════════════════

## 812220 results
agg_220_att <- if (!is.null(robust$agg_220)) robust$agg_220$overall.att else NA
agg_220_se <- if (!is.null(robust$agg_220)) robust$agg_220$overall.se else NA
p_220 <- if (!is.na(agg_220_att)) 2 * pnorm(-abs(agg_220_att / agg_220_se)) else NA

## State-level 812220 employment
twfe_220_coef <- coef(robust$twfe_220_empl)["treated"]
twfe_220_se <- se(robust$twfe_220_empl)["treated"]
p_220_empl <- pvalue(robust$twfe_220_empl)["treated"]

## Heterogeneity
twfe_large_coef <- coef(robust$twfe_large)["treated"]
twfe_large_se <- se(robust$twfe_large)["treated"]
p_large <- pvalue(robust$twfe_large)["treated"]

twfe_small_coef <- coef(robust$twfe_small)["treated"]
twfe_small_se <- se(robust$twfe_small)["treated"]
p_small <- pvalue(robust$twfe_small)["treated"]

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Mechanisms and Heterogeneity}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Establishments & ln(Employment) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Substitution (NAICS 812220, Cemeteries/Crematories)}} \\\\\n",
  sprintf("CS-DiD ATT & %s%s & --- \\\\\n",
          ifelse(!is.na(agg_220_att), paste0(fmt(agg_220_att), stars(p_220)), "---"),
          ""),
  sprintf("           & %s & \\\\\n",
          ifelse(!is.na(agg_220_se), paste0("(", fmt(agg_220_se), ")"), "")),
  sprintf("TWFE & --- & %s%s \\\\\n",
          fmt(twfe_220_coef), stars(p_220_empl)),
  sprintf("     &     & (%s) \\\\\n", fmt(twfe_220_se)),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Heterogeneity by State Size (NAICS 812210)}} \\\\\n",
  sprintf("Large states (CA, NY, TX, FL, IL) & %s%s & \\\\\n",
          fmt(twfe_large_coef), stars(p_large)),
  sprintf("                                  & (%s) & \\\\\n", fmt(twfe_large_se)),
  sprintf("Other states & %s%s & \\\\\n",
          fmt(twfe_small_coef), stars(p_small)),
  sprintf("             & (%s) & \\\\\n", fmt(twfe_small_se)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A tests whether AH legalization affects the related crematory sector. ",
  "CS-DiD uses Callaway--Sant'Anna with not-yet-treated control group. ",
  "Panel B splits the county-level establishment sample by state population size. ",
  "Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:mechanisms}\n",
  "\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_mechanisms.tex")

## ══════════════════════════════════════════════════════════════════════════════
## TABLE 5: Robustness
## ══════════════════════════════════════════════════════════════════════════════

## Never-treated control
never_att <- if (!is.null(robust$agg_never)) robust$agg_never$overall.att else NA
never_se <- if (!is.null(robust$agg_never)) robust$agg_never$overall.se else NA
p_never <- if (!is.na(never_att)) 2 * pnorm(-abs(never_att / never_se)) else NA

## State-level establishments
state_att <- if (!is.null(robust$agg_state_estabs)) robust$agg_state_estabs$overall.att else NA
state_se <- if (!is.null(robust$agg_state_estabs)) robust$agg_state_estabs$overall.se else NA
p_state <- if (!is.na(state_att)) 2 * pnorm(-abs(state_att / state_se)) else NA

## Main result for comparison
main_att <- results$agg_estabs$overall.att
main_se <- results$agg_estabs$overall.se
p_main <- 2 * pnorm(-abs(main_att / main_se))

## LOO range
loo_min <- min(robust$loo_dt$att, na.rm = TRUE)
loo_max <- max(robust$loo_dt$att, na.rm = TRUE)

tab5 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Funeral Home Establishments}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & ATT & SE \\\\\n",
  "\\midrule\n",
  sprintf("Main (CS-DiD, not-yet-treated) & %s%s & (%s) \\\\\n",
          fmt(main_att), stars(p_main), fmt(main_se)),
  sprintf("Never-treated control only & %s%s & (%s) \\\\\n",
          ifelse(!is.na(never_att), fmt(never_att), "---"),
          ifelse(!is.na(p_never), stars(p_never), ""),
          ifelse(!is.na(never_se), fmt(never_se), "---")),
  sprintf("State-level aggregation & %s%s & (%s) \\\\\n",
          ifelse(!is.na(state_att), fmt(state_att), "---"),
          ifelse(!is.na(p_state), stars(p_state), ""),
          ifelse(!is.na(state_se), fmt(state_se), "---")),
  sprintf("Leave-one-cohort-out range & [%s, %s] & \\\\\n",
          fmt(loo_min), fmt(loo_max)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications estimate the effect of alkaline hydrolysis legalization on funeral home establishments. ",
  "Row 1: baseline Callaway--Sant'Anna with not-yet-treated control group. ",
  "Row 2: restricts control group to never-treated states only. ",
  "Row 3: aggregates to state-year level. ",
  "Row 4: range of ATT estimates when each treatment cohort is dropped in turn. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)
writeLines(tab5, "../tables/tab5_robustness.tex")

## ══════════════════════════════════════════════════════════════════════════════
## TABLE F1: Standardized Effect Sizes (SDE)
## ══════════════════════════════════════════════════════════════════════════════

## Main outcomes — pooled
beta_estabs <- results$agg_estabs$overall.att
se_estabs_raw <- results$agg_estabs$overall.se
sd_y_estabs <- sd(county_did$estabs, na.rm = TRUE)
sde_estabs <- beta_estabs / sd_y_estabs
se_sde_estabs <- se_estabs_raw / sd_y_estabs

beta_empl <- results$agg_empl$overall.att
se_empl_raw <- results$agg_empl$overall.se
sd_y_empl <- sd(state_did$ln_empl, na.rm = TRUE)
sde_empl <- beta_empl / sd_y_empl
se_sde_empl <- se_empl_raw / sd_y_empl

beta_wage <- results$agg_wage$overall.att
se_wage_raw <- results$agg_wage$overall.se
sd_y_wage <- sd(state_did$ln_wage, na.rm = TRUE)
sde_wage <- beta_wage / sd_y_wage
se_sde_wage <- se_wage_raw / sd_y_wage

## Heterogeneity — sample splits
beta_large <- coef(robust$twfe_large)["treated"]
se_large <- se(robust$twfe_large)["treated"]
sde_large <- beta_large / sd_y_estabs
se_sde_large <- se_large / sd_y_estabs

beta_small <- coef(robust$twfe_small)["treated"]
se_small <- se(robust$twfe_small)["treated"]
sde_small <- beta_small / sd_y_estabs
se_sde_small <- se_small / sd_y_estabs

## Classification function
classify <- function(s) dplyr::case_when(
  s < -0.15 ~ "Large negative",
  s < -0.05 ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s < 0.005 ~ "Null",
  s < 0.05 ~ "Small positive",
  s < 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state-level legalization of alkaline hydrolysis (water cremation) ",
  "affect the structure, employment, and wages of the funeral services industry? ",
  "\\textbf{Policy mechanism:} States that legalize alkaline hydrolysis permit licensed facilities ",
  "to dissolve human remains in a heated alkaline solution as an alternative to flame cremation or burial, ",
  "removing a legal barrier to entry for a lower-cost disposition technology. ",
  "\\textbf{Outcome definition:} Establishments: annual average count of funeral home establishments (NAICS 812210) ",
  "from the BLS Quarterly Census of Employment and Wages; Employment: log of annual average employment; ",
  "Wage: log of annual average weekly wage. ",
  "\\textbf{Treatment:} Binary indicator equal to one in state-years after alkaline hydrolysis legalization. ",
  "\\textbf{Data:} BLS QCEW, 2014--2023, county-year (establishments) and state-year (employment, wages). ",
  "\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator, not-yet-treated control group, ",
  "state-clustered standard errors. ",
  "\\textbf{Sample:} 10 treatment cohorts (2017--2023) and 28 never-treated states; ",
  "13 always-treated states excluded from CS-DiD estimation. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Establishments & CS-DiD & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_estabs), fmt(se_estabs_raw), fmt(sd_y_estabs, 2),
          fmt(sde_estabs), fmt(se_sde_estabs), classify(sde_estabs)),
  sprintf("ln(Employment) & CS-DiD & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_empl), fmt(se_empl_raw), fmt(sd_y_empl, 2),
          fmt(sde_empl), fmt(se_sde_empl), classify(sde_empl)),
  sprintf("ln(Wage) & CS-DiD & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_wage), fmt(se_wage_raw), fmt(sd_y_wage, 2),
          fmt(sde_wage), fmt(se_sde_wage), classify(sde_wage)),
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (Establishments by State Size)}} \\\\\n",
  sprintf("Large states & TWFE & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_large), fmt(se_large), fmt(sd_y_estabs, 2),
          fmt(sde_large), fmt(se_sde_large), classify(sde_large)),
  sprintf("Other states & TWFE & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_small), fmt(se_small), fmt(sd_y_estabs, 2),
          fmt(sde_small), fmt(se_sde_small), classify(sde_small)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

message("All tables generated in tables/")
