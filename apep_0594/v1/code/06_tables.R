## 06_tables.R — Generate all LaTeX tables
## apep_0594: Spain's 2022 Temporary Contract Ban

source("00_packages.R")

cat("=== Generating Tables ===\n")

# Load data
summ <- fread(file.path(data_dir, "summary_stats.csv"))
main_res <- fread(file.path(data_dir, "main_results.csv"))
boot_res <- fread(file.path(data_dir, "bootstrap_results.csv"))
ri_res <- fread(file.path(data_dir, "ri_results.csv"))
sector_res <- fread(file.path(data_dir, "sector_summary.csv"))
alt_specs <- fread(file.path(data_dir, "robustness_alt_specs.csv"))
dt <- fread(file.path(data_dir, "analysis_panel.csv"))

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================

cat("Table 1: Summary statistics\n")

# Clean variable names
summ[, variable_clean := case_when(
  variable == "temp_share" ~ "Temporary Employment Share",
  variable == "perm_share" ~ "Permanent Employment Share",
  variable == "wage_earners_total" ~ "Total Wage Earners (thousands)",
  variable == "pre_temp_share" ~ "Pre-Reform Temp Share (treatment)",
  variable == "unemployment" ~ "Unemployment Rate (\\%)",
  variable == "employment" ~ "Employment Rate (\\%)",
  TRUE ~ variable
)]

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & Std.\\ Dev. & Min & Max & N \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(summ))) {
  row <- summ[i]
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            row$variable_clean,
            row$mean, row$sd, row$min, row$max,
            format(row$n, big.mark = ",")))
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item Notes: N = ", format(nrow(dt), big.mark = ","),
  " region-quarter observations across 19 Autonomous Communities and 60 quarters (2010Q4--2025Q3). ",
  "Temporary and permanent employment shares are computed as the fraction of total wage earners. ",
  "Wage earners are reported in thousands. ",
  "Pre-reform temporary share is the 2021 annual average for each region, used as treatment intensity in the shift-share design.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tab_dir, "tab1_summary.tex"))

# =============================================================================
# TABLE 2: Main Results
# =============================================================================

cat("Table 2: Main results\n")

# Load models for additional info
load(file.path(data_dir, "main_models.RData"))

# Load population-weighted model
load(file.path(data_dir, "weighted_model.RData"))

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Reform Exposure on Labor Market Outcomes}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Temp.\\ Share & Log Emp. & Temp.\\ Share \\\\\n",
  " & (Unweighted) & (Unweighted) & (Pop.-Weighted) \\\\\n",
  "\\midrule\n"
)

# Row: coefficient — Columns: temp unweighted, log emp, temp weighted
betas <- c(coef(m1)["treat"], coef(m3)["treat"], coef(m_weighted)["treat"])
ses <- c(se(m1)["treat"], se(m3)["treat"], se(m_weighted)["treat"])
pvals <- c(fixest::pvalue(m1)["treat"], fixest::pvalue(m3)["treat"],
           fixest::pvalue(m_weighted)["treat"])

stars_fn <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# Coefficient row
tab2_tex <- paste0(tab2_tex, "Pre-Reform Temp Share $\\times$ Post")
for (i in 1:3) {
  tab2_tex <- paste0(tab2_tex, sprintf(" & %.4f%s", betas[i], stars_fn(pvals[i])))
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

# SE row
tab2_tex <- paste0(tab2_tex, " ")
for (i in 1:3) {
  tab2_tex <- paste0(tab2_tex, sprintf(" & (%.4f)", ses[i]))
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

# Wild bootstrap p-value row
tab2_tex <- paste0(tab2_tex, "Wild bootstrap $p$-value")
bp1 <- boot_res$boot_pval[1]  # temp share
bp3 <- boot_res$boot_pval[3]  # log emp (third in boot_res)
# Load weighted bootstrap result
wt_boot <- fread(file.path(data_dir, "weighted_bootstrap.csv"))
bp_wt <- wt_boot$boot_pval[1]
tab2_tex <- paste0(tab2_tex,
  sprintf(" & [%.3f]", bp1),
  sprintf(" & [%.3f]", bp3),
  if (!is.na(bp_wt)) sprintf(" & [%.3f]", bp_wt) else " & ---")
tab2_tex <- paste0(tab2_tex, " \\\\\n")

# Add rows
nobs <- c(m1$nobs, m3$nobs, m_weighted$nobs)

# Dep var means
dep_mean_log_emp <- mean(log(dt$wage_earners_total[dt$wage_earners_total > 0]), na.rm = TRUE)

tab2_tex <- paste0(tab2_tex,
  "\\midrule\n",
  "Region FE & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Quarter FE & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Population weights & & & \\checkmark \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(nobs[1], big.mark = ","),
          format(nobs[2], big.mark = ","),
          format(nobs[3], big.mark = ",")),
  "Regions & 19 & 19 & 19 \\\\\n",
  sprintf("Dep.\\ Var.\\ Mean & %.3f & %.3f & %.3f \\\\\n",
          mean(dt$temp_share, na.rm = TRUE),
          dep_mean_log_emp,
          mean(dt$temp_share, na.rm = TRUE)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item Notes: Each column reports the coefficient on the interaction of ",
  "pre-reform regional temporary employment share (2021 average) with a post-reform indicator (2022Q2 onwards). ",
  "Standard errors clustered at the region level in parentheses. ",
  "Wild cluster bootstrap $p$-values (Webb weights, 9,999 iterations) in brackets. ",
  "Column~(3) uses 2021 average total wage earners as population weights. ",
  "Since temporary and permanent employment shares sum to unity by construction, ",
  "the permanent share coefficient is mechanically equal in magnitude and opposite in sign to Column~(1); we omit it for parsimony. ",
  "$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tab_dir, "tab2_main.tex"))

# =============================================================================
# TABLE 3: Sector-level changes
# =============================================================================

cat("Table 3: Sector decomposition\n")

sector_res <- sector_res[order(change)]

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Change in Temporary Employment Share by Sector}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrr}\n",
  "\\toprule\n",
  "Sector & Pre-Reform & Post-Reform & Change \\\\\n",
  " & (2010--2021) & (2023--2025) & (pp) \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(sector_res))) {
  row <- sector_res[i]
  tab3_tex <- paste0(tab3_tex,
    sprintf("%s & %.1f\\%% & %.1f\\%% & %.1f \\\\\n",
            row$sector,
            row$pre_temp_share * 100,
            row$post_temp_share * 100,
            row$change * 100))
}

tab3_tex <- paste0(tab3_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item Notes: Pre-reform period is 2010Q4--2021Q4; post-reform is 2023Q1--2025Q3. ",
  "Temporary employment share is the ratio of wage earners with temporary contracts ",
  "to total wage earners in each sector. Source: INE EPA Table 65133.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:sector}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tab_dir, "tab3_sector.tex"))

# =============================================================================
# TABLE C1 (Appendix): Robustness — alternative specifications
# =============================================================================

cat("Table C1: Alternative specifications\n")

tabC1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness: Alternative Specifications}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\toprule\n",
  "Specification & Coefficient & SE & 95\\% CI & N \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(alt_specs))) {
  row <- alt_specs[i]
  tabC1_tex <- paste0(tabC1_tex,
    sprintf("%s & %.4f & (%.4f) & [%.4f, %.4f] & %s \\\\\n",
            row$specification, row$beta, row$se, row$ci_lo, row$ci_hi,
            format(row$n, big.mark = ",")))
}

tabC1_tex <- paste0(tabC1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item Notes: Dependent variable is temporary employment share. ",
  "All specifications include region and quarter fixed effects with ",
  "standard errors clustered at the region level. ",
  "The population-weighted specification uses the 2021 average total wage earners as weights.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)

writeLines(tabC1_tex, file.path(tab_dir, "tabC1_alt_specs.tex"))

# =============================================================================
# TABLE F1 (Appendix): Standardized Effect Sizes
# =============================================================================

cat("Table F1: Standardized effect sizes\n")

sd_temp_share <- sd(dt$temp_share, na.rm = TRUE)
sd_log_total <- sd(log(dt$wage_earners_total), na.rm = TRUE)
# Treatment is continuous: SD of pre_temp_share
sd_treatment <- sd(dt$pre_temp_share, na.rm = TRUE)

sde_rows <- data.table(
  outcome = c("Temp.\\\\ Share (Unwt.)", "Log Employment", "Temp.\\\\ Share (Wt.)"),
  spec = c("Table 2, Col.\\ 1", "Table 2, Col.\\ 2", "Table 2, Col.\\ 3"),
  beta = c(coef(m1)["treat"], coef(m3)["treat"], coef(m_weighted)["treat"]),
  se_beta = c(se(m1)["treat"], se(m3)["treat"], se(m_weighted)["treat"]),
  sd_x = sd_treatment,
  sd_y = c(sd_temp_share, sd_log_total, sd_temp_share)
)

sde_rows[, sde := beta * sd_x / sd_y]
sde_rows[, se_sde := se_beta * sd_x / sd_y]

# Classification
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows[, classification := sapply(sde, classify_sde)]

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\begin{threeparttable}\n",
  "\\footnotesize\n",
  "\\begin{tabular}{llrrrrrl}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(sde_rows))) {
  row <- sde_rows[i]
  tabF1_tex <- paste0(tabF1_tex,
    sprintf("%s & %s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            row$outcome, row$spec, row$beta, row$sd_x, row$sd_y,
            row$sde, row$se_sde, row$classification))
}

tabF1_tex <- paste0(tabF1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item Notes: This table reports standardized effect sizes (SDE) for the main outcomes of the paper. ",
  "The paper evaluates Spain's 2022 labor reform (RDL 32/2021), which banned most temporary contracts. ",
  "Data: INE EPA quarterly Labor Force Survey, 2010Q4--2025Q3, at the Autonomous Community level ",
  "(19 regions $\\times$ 60 quarters = 1,140 observations). ",
  "Estimation: OLS with region and quarter fixed effects; treatment is continuous (pre-reform regional temporary employment share $\\times$ post-reform indicator). ",
  "SDE = $\\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, where SD($X$) is the standard deviation of pre-reform temporary employment share across regions. ",
  "SE(SDE) = SE($\\hat{\\beta}$) $\\times$ SD($X$) / SD($Y$). ",
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:sde}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(tab_dir, "tabF1_sde.tex"))

# Save SDE data for reference
fwrite(sde_rows, file.path(data_dir, "sde_results.csv"))

cat("\n=== All tables saved to", tab_dir, "===\n")
