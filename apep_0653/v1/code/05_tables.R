# 05_tables.R — Generate all LaTeX tables
# apep_0653: Data Breach Notification Laws and Firm Dynamics

source("00_packages.R")

panel_agg <- readRDS("../data/panel_aggregate.rds")
panel_naics <- readRDS("../data/panel_naics.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

summ <- panel_agg %>%
  summarise(
    entry_mean = mean(ESTABS_ENTRY_RATE, na.rm = TRUE),
    entry_sd = sd(ESTABS_ENTRY_RATE, na.rm = TRUE),
    entry_min = min(ESTABS_ENTRY_RATE, na.rm = TRUE),
    entry_max = max(ESTABS_ENTRY_RATE, na.rm = TRUE),
    exit_mean = mean(ESTABS_EXIT_RATE, na.rm = TRUE),
    exit_sd = sd(ESTABS_EXIT_RATE, na.rm = TRUE),
    exit_min = min(ESTABS_EXIT_RATE, na.rm = TRUE),
    exit_max = max(ESTABS_EXIT_RATE, na.rm = TRUE),
    netjc_mean = mean(NET_JOB_CREATION_RATE, na.rm = TRUE),
    netjc_sd = sd(NET_JOB_CREATION_RATE, na.rm = TRUE),
    netjc_min = min(NET_JOB_CREATION_RATE, na.rm = TRUE),
    netjc_max = max(NET_JOB_CREATION_RATE, na.rm = TRUE),
    emp_mean = mean(EMP, na.rm = TRUE) / 1000,
    emp_sd = sd(EMP, na.rm = TRUE) / 1000,
    firm_mean = mean(FIRM, na.rm = TRUE) / 1000,
    firm_sd = sd(FIRM, na.rm = TRUE) / 1000
  )

tab1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Business Dynamics by State-Year}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Variable & Mean & SD & Min & Max \\\\
\\midrule
Establishment entry rate (\\%) & ", sprintf("%.2f", summ$entry_mean), " & ", sprintf("%.2f", summ$entry_sd), " & ", sprintf("%.2f", summ$entry_min), " & ", sprintf("%.2f", summ$entry_max), " \\\\
Establishment exit rate (\\%) & ", sprintf("%.2f", summ$exit_mean), " & ", sprintf("%.2f", summ$exit_sd), " & ", sprintf("%.2f", summ$exit_min), " & ", sprintf("%.2f", summ$exit_max), " \\\\
Net job creation rate (\\%) & ", sprintf("%.2f", summ$netjc_mean), " & ", sprintf("%.2f", summ$netjc_sd), " & ", sprintf("%.2f", summ$netjc_min), " & ", sprintf("%.2f", summ$netjc_max), " \\\\
Employment (thousands) & ", sprintf("%.0f", summ$emp_mean), " & ", sprintf("%.0f", summ$emp_sd), " & & \\\\
Firms (thousands) & ", sprintf("%.0f", summ$firm_mean), " & ", sprintf("%.0f", summ$firm_sd), " & & \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Treatment}} \\\\
BNL adopted (\\% of state-years) & \\multicolumn{4}{c}{", sprintf("%.1f", 100 * mean(panel_agg$treated)), "} \\\\
Adoption year range & \\multicolumn{4}{c}{2003--2018} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} N = ", format(nrow(panel_agg), big.mark = ","), " state-year observations (51 states $\\times$ ", length(unique(panel_agg$year)), " years, 1998--2022). Business Dynamics Statistics from the Census Bureau. Entry and exit rates are establishment-level (entries or exits / lagged establishments $\\times$ 100). Net job creation rate is (job creation $-$ job destruction) / employment $\\times$ 100.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab1, "../tables/tab1_summary.tex")
cat("-> tables/tab1_summary.tex\n")

# ==============================================================================
# Table 2: Main CS-DiD Results
# ==============================================================================

cs_entry <- results$cs_entry_agg
cs_exit <- results$cs_exit_agg
cs_netjc <- results$cs_netjc_agg

# TWFE
twfe_e <- results$twfe_entry
twfe_x <- results$twfe_exit
twfe_n <- results$twfe_netjc

stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("***")
  if (pval < 0.05) return("**")
  if (pval < 0.10) return("*")
  return("")
}

cs_entry_p <- 2 * pnorm(-abs(cs_entry$overall.att / cs_entry$overall.se))
cs_exit_p <- 2 * pnorm(-abs(cs_exit$overall.att / cs_exit$overall.se))
cs_netjc_p <- 2 * pnorm(-abs(cs_netjc$overall.att / cs_netjc$overall.se))

tab2 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Main Results: Effect of Data Breach Notification Laws on Firm Dynamics}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
& \\multicolumn{3}{c}{Callaway--Sant'Anna} & \\multicolumn{3}{c}{TWFE} \\\\
\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}
& Entry Rate & Exit Rate & Net JC Rate & Entry Rate & Exit Rate & Net JC Rate \\\\
& (1) & (2) & (3) & (4) & (5) & (6) \\\\
\\midrule
ATT / $\\hat{\\beta}$ & ",
  sprintf("%.3f%s", cs_entry$overall.att, stars(cs_entry_p)), " & ",
  sprintf("%.3f%s", cs_exit$overall.att, stars(cs_exit_p)), " & ",
  sprintf("%.3f%s", cs_netjc$overall.att, stars(cs_netjc_p)), " & ",
  sprintf("%.3f%s", coef(twfe_e), stars(pvalue(twfe_e))), " & ",
  sprintf("%.3f%s", coef(twfe_x), stars(pvalue(twfe_x))), " & ",
  sprintf("%.3f%s", coef(twfe_n), stars(pvalue(twfe_n))), " \\\\
& (",
  sprintf("%.3f", cs_entry$overall.se), ") & (",
  sprintf("%.3f", cs_exit$overall.se), ") & (",
  sprintf("%.3f", cs_netjc$overall.se), ") & (",
  sprintf("%.3f", se(twfe_e)), ") & (",
  sprintf("%.3f", se(twfe_x)), ") & (",
  sprintf("%.3f", se(twfe_n)), ") \\\\
\\midrule
State FE & \\multicolumn{6}{c}{Yes} \\\\
Year FE & \\multicolumn{6}{c}{Yes} \\\\
Clustering & \\multicolumn{6}{c}{State} \\\\
States & \\multicolumn{6}{c}{51} \\\\
Observations & \\multicolumn{3}{c}{", format(nrow(panel_agg), big.mark = ","), "} & \\multicolumn{3}{c}{", format(nrow(panel_agg), big.mark = ","), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Columns (1)--(3) report aggregate ATT from Callaway--Sant'Anna (2021) staggered DiD with doubly robust estimation and not-yet-treated controls. Columns (4)--(6) report TWFE estimates with state and year fixed effects. Dependent variables are establishment entry rate (entries / lagged establishments $\\times$ 100), establishment exit rate, and net job creation rate. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab2, "../tables/tab2_main.tex")
cat("-> tables/tab2_main.tex\n")

# ==============================================================================
# Table 3: Industry Mechanism Test
# ==============================================================================

ind_res <- results$industry_results

# Build rows
ind_rows <- ""
for (naics_code in c("51", "52", "54", "23", "11")) {
  r <- ind_res[[naics_code]]
  if (is.null(r)) next
  p <- 2 * pnorm(-abs(r$att / r$se))
  ind_rows <- paste0(ind_rows,
    r$label, " & ", sprintf("%.3f%s", r$att, stars(p)),
    " & (", sprintf("%.3f", r$se), ") & ", format(r$n, big.mark = ","),
    " \\\\\n")
}

tab3 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Industry Mechanism: BNL Effects by Data Intensity}
\\label{tab:industry}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Sector & ATT & SE & N \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{High data exposure}} \\\\
", ind_rows,
"\\midrule
State FE & \\multicolumn{3}{c}{Yes} \\\\
Year FE & \\multicolumn{3}{c}{Yes} \\\\
Estimator & \\multicolumn{3}{c}{CS-DiD (not-yet-treated)} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports the aggregate ATT from separate Callaway--Sant'Anna (2021) estimations on sector-specific BDS panels. Entry rate = establishments entering / lagged establishments $\\times$ 100. High data exposure sectors handle large volumes of personal consumer data; Construction and Agriculture serve as placebos due to minimal consumer data handling. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab3, "../tables/tab3_industry.tex")
cat("-> tables/tab3_industry.tex\n")

# ==============================================================================
# Table 4: Event Study Coefficients
# ==============================================================================

es <- results$cs_entry_es
es_df <- data.frame(
  e = es$egt,
  att = es$att.egt,
  se = es$se.egt
) %>%
  filter(!is.na(att), !is.na(se), se > 0) %>%
  mutate(
    pval = 2 * pnorm(-abs(att / se)),
    star = sapply(pval, stars)
  )

es_rows <- ""
for (i in 1:nrow(es_df)) {
  r <- es_df[i, ]
  label <- ifelse(r$e < 0, paste0("$k = ", r$e, "$"), paste0("$k = +", r$e, "$"))
  es_rows <- paste0(es_rows,
    label, " & ", sprintf("%.3f%s", r$att, r$star),
    " & (", sprintf("%.3f", r$se), ") \\\\\n")
}

tab4 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Event Study: Dynamic Effects of BNL Adoption on Entry Rate}
\\label{tab:eventstudy}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Event Time & ATT & SE \\\\
\\midrule
", es_rows,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dynamic ATT estimates from Callaway--Sant'Anna (2021) aggregated by event time relative to BNL adoption ($k=0$). Dependent variable is establishment entry rate. Pre-treatment coefficients ($k < 0$) test the parallel trends assumption. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab4, "../tables/tab4_eventstudy.tex")
cat("-> tables/tab4_eventstudy.tex\n")

# ==============================================================================
# Table 5: Robustness
# ==============================================================================

sa_entry_s <- summary(rob$sa_entry, agg = "ATT")$coeftable
sa_exit_s <- summary(rob$sa_exit, agg = "ATT")$coeftable
sa_netjc_s <- summary(rob$sa_netjc, agg = "ATT")$coeftable

tab5 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Robustness: Alternative Estimators and Sample Restrictions}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lccc}
\\toprule
Specification & Entry Rate & Exit Rate & Net JC Rate \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Alternative estimators}} \\\\
Callaway--Sant'Anna (baseline) & ",
  sprintf("%.3f%s", results$cs_entry_agg$overall.att, stars(cs_entry_p)),
  " & ", sprintf("%.3f%s", results$cs_exit_agg$overall.att, stars(cs_exit_p)),
  " & ", sprintf("%.3f%s", results$cs_netjc_agg$overall.att, stars(cs_netjc_p)), " \\\\
& (", sprintf("%.3f", results$cs_entry_agg$overall.se),
  ") & (", sprintf("%.3f", results$cs_exit_agg$overall.se),
  ") & (", sprintf("%.3f", results$cs_netjc_agg$overall.se), ") \\\\[3pt]
Sun--Abraham & ",
  sprintf("%.3f%s", sa_entry_s[1,1], stars(sa_entry_s[1,4])),
  " & ", sprintf("%.3f%s", sa_exit_s[1,1], stars(sa_exit_s[1,4])),
  " & ", sprintf("%.3f%s", sa_netjc_s[1,1], stars(sa_netjc_s[1,4])), " \\\\
& (", sprintf("%.3f", sa_entry_s[1,2]),
  ") & (", sprintf("%.3f", sa_exit_s[1,2]),
  ") & (", sprintf("%.3f", sa_netjc_s[1,2]), ") \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: Sample restrictions}} \\\\
Exclude California & ",
  sprintf("%.3f", rob$cs_noca_agg$overall.att), " & & \\\\
& (", sprintf("%.3f", rob$cs_noca_agg$overall.se), ") & & \\\\[3pt]
Exclude 2005 mega-cohort & ",
  sprintf("%.3f", rob$cs_no2005_agg$overall.att), " & & \\\\
& (", sprintf("%.3f", rob$cs_no2005_agg$overall.se), ") & & \\\\[3pt]
\\midrule
LOO cohort range (entry rate) & \\multicolumn{3}{c}{[",
  sprintf("%.3f", min(rob$loo_results$att, na.rm = TRUE)), ", ",
  sprintf("%.3f", max(rob$loo_results$att, na.rm = TRUE)), "]} \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A compares the baseline Callaway--Sant'Anna (2021) aggregate ATT with Sun--Abraham (2021) interaction-weighted estimates. Panel B shows entry rate ATT under sample restrictions: excluding California (first adopter, tech hub) and excluding the 2005 mega-cohort (23 states). LOO range shows the minimum and maximum aggregate ATT when each adoption cohort is excluded in turn. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab5, "../tables/tab5_robustness.tex")
cat("-> tables/tab5_robustness.tex\n")

# ==============================================================================
# SDE Table (Appendix)
# ==============================================================================

# Compute SDE for main outcomes
outcomes <- list(
  list(label = "Establishment Entry Rate", att = cs_entry$overall.att,
       se_att = cs_entry$overall.se, outcome_var = "ESTABS_ENTRY_RATE"),
  list(label = "Establishment Exit Rate", att = cs_exit$overall.att,
       se_att = cs_exit$overall.se, outcome_var = "ESTABS_EXIT_RATE"),
  list(label = "Net Job Creation Rate", att = cs_netjc$overall.att,
       se_att = cs_netjc$overall.se, outcome_var = "NET_JOB_CREATION_RATE")
)

# Add industry mechanism results
for (naics_code in c("51", "23")) {
  r <- results$industry_results[[naics_code]]
  if (!is.null(r)) {
    outcomes[[length(outcomes) + 1]] <- list(
      label = paste0("Entry Rate --- ", r$label),
      att = r$att,
      se_att = r$se,
      outcome_var = "ESTABS_ENTRY_RATE",
      naics = naics_code
    )
  }
}

classify <- function(s) {
  case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_rows <- ""
for (o in outcomes) {
  # Get SD(Y)
  if (!is.null(o$naics)) {
    sd_y <- sd(panel_naics$ESTABS_ENTRY_RATE[panel_naics$NAICS == o$naics], na.rm = TRUE)
  } else {
    sd_y <- sd(panel_agg[[o$outcome_var]], na.rm = TRUE)
  }

  sde <- o$att / sd_y
  se_sde <- o$se_att / sd_y
  cls <- classify(sde)

  sde_rows <- paste0(sde_rows,
    o$label, " & ", sprintf("%.3f", o$att),
    " & (", sprintf("%.3f", o$se_att), ")",
    " & ", sprintf("%.2f", sd_y),
    " & ", sprintf("%.4f", sde),
    " & (", sprintf("%.4f", se_sde), ")",
    " & ", cls, " \\\\\n")
}

tab_sde <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
", sde_rows,
"\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\par\\vspace{0.3em}
{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE $= \\hat{\\beta} / \\text{SD}(Y)$) for each main outcome.
Treatment is binary (state adopted data breach notification law).
SD($Y$) is the unconditional standard deviation of the outcome variable across the full state-year panel.

\\textbf{Research question:} Do state data breach notification laws deter new business formation through compliance costs, and is this effect concentrated in data-intensive industries?
\\textbf{Treatment:} Binary indicator for state adoption of a data breach notification law (staggered 2003--2018, all 50 states + DC).
\\textbf{Data:} Census Bureau Business Dynamics Statistics, 51 states, 1998--2022, N = ", format(nrow(panel_agg), big.mark = ","), " state-year observations.
\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator, not-yet-treated controls, state-clustered standard errors.
\\textbf{Sample:} All US states with non-missing BDS data, annual frequency.

Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$),
small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$),
small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$),
large positive ($> 0.15$).
Classification labels refer to the magnitude of the standardized point estimate,
not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$),
not a failure to reject a null hypothesis.}
\\end{table}")

writeLines(tab_sde, "../tables/tabF1_sde.tex")
cat("-> tables/tabF1_sde.tex\n")
