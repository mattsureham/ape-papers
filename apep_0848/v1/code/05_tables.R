# =============================================================================
# 05_tables.R — Generate all LaTeX tables for apep_0848
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
panel_hc <- readRDS("../data/panel_healthcare.rds")
summary_stats <- readRDS("../data/summary_stats.rds")
diagnostics <- jsonlite::fromJSON("../data/diagnostics.json")

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================

# Compute overall summary stats
overall_stats <- panel_hc %>%
  summarise(
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    sd_hire_rate = sd(hire_rate, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    sd_earn = sd(EarnS, na.rm = TRUE),
    mean_turnover = mean(turnover_rate, na.rm = TRUE),
    sd_turnover = sd(turnover_rate, na.rm = TRUE),
    n_obs = n()
  )

# Split by treatment status
stats_by_group <- panel_hc %>%
  filter(yearqtr < 2018) %>%
  mutate(enlc = ifelse(group == "never", "Control", "eNLC")) %>%
  group_by(enlc) %>%
  summarise(
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    sd_hire_rate = sd(hire_rate, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    sd_earn = sd(EarnS, na.rm = TRUE),
    mean_turnover = mean(turnover_rate, na.rm = TRUE),
    sd_turnover = sd(turnover_rate, na.rm = TRUE),
    n_counties = n_distinct(county_fips),
    n_obs = n(),
    .groups = "drop"
  )

tab1_enlc <- stats_by_group %>% filter(enlc == "eNLC")
tab1_ctrl <- stats_by_group %>% filter(enlc == "Control")

tab1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Healthcare Sector, Pre-Treatment (2014--2017)}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{eNLC States} & \\multicolumn{2}{c}{Control States} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Variable & Mean & SD & Mean & SD \\\\
\\midrule
Employment & %s & %s & %s & %s \\\\
Hire rate & %.3f & %.3f & %.3f & %.3f \\\\
Separation rate & %.3f & %.3f & %.3f & %.3f \\\\
Avg. quarterly earnings (\\$) & %s & %s & %s & %s \\\\
Turnover rate & %.3f & %.3f & %.3f & %.3f \\\\
\\midrule
Counties & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
County-quarter-industry obs. & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Pre-treatment means and standard deviations (2014Q1--2017Q4) for county $\\times$ quarter $\\times$ 3-digit NAICS cells in healthcare (NAICS 621, 622, 623). eNLC states are those that adopted the Enhanced Nurse Licensure Compact by 2023. Control states (CA, NY, IL, MI, OR, WA, CT, HI, AK, MN, MA) never adopted. Hire rate = all hires / beginning-of-quarter employment. Separation and turnover rates defined analogously. Source: Census QWI.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  format(round(tab1_enlc$mean_emp), big.mark = ","),
  format(round(tab1_enlc$sd_emp), big.mark = ","),
  format(round(tab1_ctrl$mean_emp), big.mark = ","),
  format(round(tab1_ctrl$sd_emp), big.mark = ","),
  tab1_enlc$mean_hire_rate, tab1_enlc$sd_hire_rate,
  tab1_ctrl$mean_hire_rate, tab1_ctrl$sd_hire_rate,
  tab1_enlc$mean_sep_rate, tab1_enlc$sd_sep_rate,
  tab1_ctrl$mean_sep_rate, tab1_ctrl$sd_sep_rate,
  format(round(tab1_enlc$mean_earn), big.mark = ","),
  format(round(tab1_enlc$sd_earn), big.mark = ","),
  format(round(tab1_ctrl$mean_earn), big.mark = ","),
  format(round(tab1_ctrl$sd_earn), big.mark = ","),
  tab1_enlc$mean_turnover, tab1_enlc$sd_turnover,
  tab1_ctrl$mean_turnover, tab1_ctrl$sd_turnover,
  format(tab1_enlc$n_counties, big.mark = ","),
  format(tab1_ctrl$n_counties, big.mark = ","),
  format(tab1_enlc$n_obs, big.mark = ","),
  format(tab1_ctrl$n_obs, big.mark = ",")
)

writeLines(tab1, "../tables/tab1_summary.tex")

# =============================================================================
# Table 2: Main DiD Results (TWFE + C&S)
# =============================================================================

# Helper for significance stars
stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("***")
  if (pval < 0.05) return("**")
  if (pval < 0.10) return("*")
  return("")
}

# Extract TWFE results
twfe_coefs <- sapply(results$twfe, function(m) coef(m)["treated"])
twfe_ses <- sapply(results$twfe, function(m) se(m)["treated"])
twfe_pvals <- sapply(results$twfe, function(m) pvalue(m)["treated"])
twfe_n <- sapply(results$twfe, function(m) m$nobs)

# Extract C&S results
cs_coefs <- c(
  results$cs_agg$emp$overall.att,
  results$cs_agg$hire$overall.att,
  results$cs_agg$sep$overall.att,
  results$cs_agg$earn$overall.att,
  results$cs_agg$turn$overall.att
)
cs_ses <- c(
  results$cs_agg$emp$overall.se,
  results$cs_agg$hire$overall.se,
  results$cs_agg$sep$overall.se,
  results$cs_agg$earn$overall.se,
  results$cs_agg$turn$overall.se
)
cs_pvals <- 2 * pnorm(-abs(cs_coefs / cs_ses))

outcomes <- c("Log employment", "Hire rate", "Separation rate",
              "Log earnings", "Turnover rate")

tab2_rows <- ""
for (i in seq_along(outcomes)) {
  # Format TWFE
  twfe_star <- stars(twfe_pvals[i])
  twfe_str <- sprintf("%.4f%s", twfe_coefs[i], twfe_star)
  twfe_se_str <- sprintf("(%.4f)", twfe_ses[i])

  # Format C&S
  cs_star <- stars(cs_pvals[i])
  cs_str <- sprintf("%.4f%s", cs_coefs[i], cs_star)
  cs_se_str <- sprintf("(%.4f)", cs_ses[i])

  tab2_rows <- paste0(tab2_rows, sprintf(
    "%s & %s & %s \\\\\n & %s & %s \\\\\n",
    outcomes[i], twfe_str, cs_str, twfe_se_str, cs_se_str
  ))
  if (i < length(outcomes)) tab2_rows <- paste0(tab2_rows, "[0.5em]\n")
}

tab2 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Effect of eNLC Adoption on Healthcare Labor Markets}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
& (1) & (2) \\\\
& TWFE & Callaway--Sant'Anna \\\\
\\midrule
%s
\\midrule
County $\\times$ industry FE & Yes & --- \\\\
Quarter FE & Yes & --- \\\\
Clustering & State & Bootstrap \\\\
Observations & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Column (1) reports two-way fixed effects estimates with county $\\times$ industry and quarter fixed effects, standard errors clustered at the state level. Column (2) reports the overall ATT from \\citet{callaway2021difference} using never-treated states as the comparison group, with doubly robust estimation and bootstrap standard errors (1,000 iterations). Treatment is state adoption of the Enhanced Nurse Licensure Compact. Sample: county $\\times$ quarter $\\times$ 3-digit NAICS cells for healthcare industries (621, 622, 623), 2014Q1--2023Q4. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  tab2_rows,
  format(twfe_n[1], big.mark = ","),
  format(twfe_n[1], big.mark = ",")
)

writeLines(tab2, "../tables/tab2_main.tex")

# =============================================================================
# Table 3: Subsector Heterogeneity
# =============================================================================

ind_labels <- c("621" = "Ambulatory Care", "622" = "Hospitals", "623" = "Nursing/Residential")
tab3_rows <- ""

for (ind in c("621", "622", "623")) {
  m <- results$twfe_by_ind[[ind]]
  for (outcome in c("emp", "hire", "sep", "earn", "turn")) {
    b <- coef(m[[outcome]])["treated"]
    s <- se(m[[outcome]])["treated"]
    p <- pvalue(m[[outcome]])["treated"]
    st <- stars(p)

    if (outcome == "emp") {
      tab3_rows <- paste0(tab3_rows, sprintf(
        "\\multirow{5}{*}{%s} & Log employment & %.4f%s \\\\\n & & (%.4f) \\\\\n",
        ind_labels[ind], b, st, s
      ))
    } else {
      oname <- switch(outcome,
                      "hire" = "Hire rate",
                      "sep" = "Separation rate",
                      "earn" = "Log earnings",
                      "turn" = "Turnover rate")
      tab3_rows <- paste0(tab3_rows, sprintf(
        " & %s & %.4f%s \\\\\n & & (%.4f) \\\\\n",
        oname, b, st, s
      ))
    }
  }
  if (ind != "623") tab3_rows <- paste0(tab3_rows, "\\midrule\n")
}

tab3 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{eNLC Effects by Healthcare Subsector}
\\label{tab:subsector}
\\begin{threeparttable}
\\begin{tabular}{llc}
\\toprule
Subsector & Outcome & TWFE \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} TWFE estimates with county $\\times$ industry and quarter fixed effects, standard errors clustered at state level. NAICS 621 = ambulatory healthcare (physician offices, outpatient clinics); 622 = hospitals; 623 = nursing and residential care facilities. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
", tab3_rows)

writeLines(tab3, "../tables/tab3_subsector.tex")

# =============================================================================
# Table 4: Robustness — Triple-DiD and Placebo
# =============================================================================

# Triple-DiD coefficients
triple_coefs <- c(
  coef(robustness$triple$emp)["healthcare:enlc_state:post"],
  coef(robustness$triple$hire)["healthcare:enlc_state:post"],
  coef(robustness$triple$sep)["healthcare:enlc_state:post"]
)
triple_ses <- c(
  se(robustness$triple$emp)["healthcare:enlc_state:post"],
  se(robustness$triple$hire)["healthcare:enlc_state:post"],
  se(robustness$triple$sep)["healthcare:enlc_state:post"]
)
triple_pvals <- c(
  pvalue(robustness$triple$emp)["healthcare:enlc_state:post"],
  pvalue(robustness$triple$hire)["healthcare:enlc_state:post"],
  pvalue(robustness$triple$sep)["healthcare:enlc_state:post"]
)

# Placebo: retail
retail_coefs <- c(
  coef(robustness$placebo[["Retail"]]$emp)["treated"],
  coef(robustness$placebo[["Retail"]]$hire)["treated"],
  coef(robustness$placebo[["Retail"]]$sep)["treated"]
)
retail_ses <- c(
  se(robustness$placebo[["Retail"]]$emp)["treated"],
  se(robustness$placebo[["Retail"]]$hire)["treated"],
  se(robustness$placebo[["Retail"]]$sep)["treated"]
)
retail_pvals <- c(
  pvalue(robustness$placebo[["Retail"]]$emp)["treated"],
  pvalue(robustness$placebo[["Retail"]]$hire)["treated"],
  pvalue(robustness$placebo[["Retail"]]$sep)["treated"]
)

# Pre-COVID
precovid_coefs <- c(
  coef(robustness$precovid$emp)["treated"],
  coef(robustness$precovid$hire)["treated"],
  coef(robustness$precovid$sep)["treated"]
)
precovid_ses <- c(
  se(robustness$precovid$emp)["treated"],
  se(robustness$precovid$hire)["treated"],
  se(robustness$precovid$sep)["treated"]
)
precovid_pvals <- c(
  pvalue(robustness$precovid$emp)["treated"],
  pvalue(robustness$precovid$hire)["treated"],
  pvalue(robustness$precovid$sep)["treated"]
)

rob_outcomes <- c("Log employment", "Hire rate", "Separation rate")
tab4_rows <- ""
for (i in 1:3) {
  tab4_rows <- paste0(tab4_rows, sprintf(
    "%s & %.4f%s & %.4f%s & %.4f%s \\\\\n & (%.4f) & (%.4f) & (%.4f) \\\\\n",
    rob_outcomes[i],
    triple_coefs[i], stars(triple_pvals[i]),
    retail_coefs[i], stars(retail_pvals[i]),
    precovid_coefs[i], stars(precovid_pvals[i]),
    triple_ses[i], retail_ses[i], precovid_ses[i]
  ))
  if (i < 3) tab4_rows <- paste0(tab4_rows, "[0.5em]\n")
}

tab4 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Robustness: Triple-DiD, Placebo Sector, and Pre-COVID Window}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& (1) & (2) & (3) \\\\
& Triple-DiD & Placebo: Retail & Pre-COVID \\\\
& (HC $\\times$ eNLC $\\times$ Post) & (NAICS 44--45) & (2014--2019) \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Column (1): triple-difference estimate (healthcare $\\times$ eNLC state $\\times$ post-2018), including healthcare and non-healthcare sectors (retail, accommodation). Column (2): placebo test on retail trade (NAICS 44--45), which should not respond to nurse licensure reform. Column (3): restricts sample to 2014--2019 to exclude COVID-era confounders. All specifications include county $\\times$ industry and quarter fixed effects with state-clustered standard errors. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
", tab4_rows)

writeLines(tab4, "../tables/tab4_robustness.tex")

# =============================================================================
# Table 5 (Appendix F): Standardized Effect Sizes
# =============================================================================

# Pre-treatment SDs for SDE computation
pre_sds <- panel_hc %>%
  filter(yearqtr < 2018) %>%
  summarise(
    sd_log_emp = sd(log_emp, na.rm = TRUE),
    sd_hire_rate = sd(hire_rate, na.rm = TRUE),
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    sd_log_earn = sd(log_earn, na.rm = TRUE),
    sd_turnover = sd(turnover_rate, na.rm = TRUE)
  )

# C&S ATT estimates
# Limit to 4 main outcomes (drop turnover which is near zero)
sde_data <- data.frame(
  outcome = c("Log employment", "Hire rate", "Separation rate",
              "Log earnings"),
  beta = cs_coefs[1:4],
  se = cs_ses[1:4],
  sd_y = c(pre_sds$sd_log_emp, pre_sds$sd_hire_rate, pre_sds$sd_sep_rate,
           pre_sds$sd_log_earn),
  stringsAsFactors = FALSE
)

sde_data <- sde_data %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Heterogeneity: Nursing/Residential (623) vs Ambulatory (621) for main outcomes
het_data <- data.frame(
  outcome = character(0), beta = numeric(0), se = numeric(0),
  sd_y = numeric(0), specification = character(0),
  stringsAsFactors = FALSE
)

# 623 subsector
sub623 <- panel_hc %>% filter(industry == "623")
pre_sd_623 <- sub623 %>%
  filter(yearqtr < 2018) %>%
  summarise(sd_log_emp = sd(log_emp, na.rm = TRUE),
            sd_hire_rate = sd(hire_rate, na.rm = TRUE))

het_data <- rbind(het_data, data.frame(
  outcome = c("Log employment (NAICS 623)"),
  beta = c(coef(results$twfe_by_ind[["623"]]$emp)["treated"]),
  se = c(se(results$twfe_by_ind[["623"]]$emp)["treated"]),
  sd_y = c(pre_sd_623$sd_log_emp),
  specification = "NAICS 623 (Nursing/Residential)",
  stringsAsFactors = FALSE
))

# 621 subsector
sub621 <- panel_hc %>% filter(industry == "621")
pre_sd_621 <- sub621 %>%
  filter(yearqtr < 2018) %>%
  summarise(sd_log_emp = sd(log_emp, na.rm = TRUE),
            sd_hire_rate = sd(hire_rate, na.rm = TRUE))

het_data <- rbind(het_data, data.frame(
  outcome = c("Log employment (NAICS 621)"),
  beta = c(coef(results$twfe_by_ind[["621"]]$emp)["treated"]),
  se = c(se(results$twfe_by_ind[["621"]]$emp)["treated"]),
  sd_y = c(pre_sd_621$sd_log_emp),
  specification = "NAICS 621 (Ambulatory Care)",
  stringsAsFactors = FALSE
))

het_data <- het_data %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Build SDE table
sde_rows_a <- ""
for (i in seq_len(nrow(sde_data))) {
  sde_rows_a <- paste0(sde_rows_a, sprintf(
    "%s & %.4f & --- & %.4f & %.4f & %.4f & %s \\\\\n",
    sde_data$outcome[i], sde_data$beta[i], sde_data$sd_y[i],
    sde_data$sde[i], sde_data$se_sde[i], sde_data$classification[i]
  ))
}

sde_rows_b <- ""
for (i in seq_len(nrow(het_data))) {
  sde_rows_b <- paste0(sde_rows_b, sprintf(
    "%s & %.4f & --- & %.4f & %.4f & %.4f & %s \\\\\n",
    het_data$outcome[i], het_data$beta[i], het_data$sd_y[i],
    het_data$sde[i], het_data$se_sde[i], het_data$classification[i]
  ))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the Enhanced Nurse Licensure Compact, which allows registered nurses to practice across member states without additional licensure, affect healthcare employer hiring dynamics, workforce separations, and earnings? ",
  "\\textbf{Policy mechanism:} The eNLC replaces state-by-state nurse licensure with a multistate compact: nurses holding a license from a member state can practice in any other member state without applying for a new license, reducing the fixed cost of cross-state labor supply and expanding the geographic labor pool available to healthcare employers. ",
  "\\textbf{Outcome definition:} County-level quarterly workforce indicators from Census QWI: beginning-of-quarter employment, all hires (including recalls), new hires, separations, average quarterly earnings, and turnover (sum of hires and separations). Rates computed as flows divided by beginning-of-quarter employment. ",
  "\\textbf{Treatment:} Binary --- state adopted the eNLC (founding states in 2018Q1; later adopters 2019--2023). ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI), county $\\times$ quarter $\\times$ 3-digit NAICS, 2014Q1--2023Q4, ", format(diagnostics$n_obs, big.mark = ","), " county-quarter-industry observations. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with doubly robust estimation, never-treated states as comparison group, bootstrap inference (1,000 iterations). Panel A reports pooled ATT from Callaway--Sant'Anna. Panel B reports TWFE estimates by healthcare subsector (county and quarter fixed effects, state-clustered standard errors). ",
  "\\textbf{Sample:} Healthcare industries (NAICS 621 ambulatory care, 622 hospitals, 623 nursing/residential care); counties with at least 12 pre-treatment quarters of non-missing data; excluding suppressed cells. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled (Callaway--Sant'Anna ATT)}} \\\\
%s
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (TWFE by Subsector)}} \\\\
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
", sde_rows_a, sde_rows_b, sde_notes)

writeLines(tabF1, "../tables/tabF1_sde.tex")

message("All tables generated successfully.")
message("  tab1_summary.tex")
message("  tab2_main.tex")
message("  tab3_subsector.tex")
message("  tab4_robustness.tex")
message("  tabF1_sde.tex")
