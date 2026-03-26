# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# Paper: The Recertification Ripple (apep_0968)
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================

cat("Generating Table 1: Summary statistics...\n")

df_stats <- df_main %>%
  mutate(ies_label = ifelse(ies_status == 1, "IES States", "Non-IES States"))

# Overall and by IES status
stats_list <- list()
for (grp in c("All", "IES States", "Non-IES States")) {
  d <- if (grp == "All") df_stats else df_stats %>% filter(ies_label == grp)
  stats_list[[grp]] <- data.frame(
    Group = grp,
    N_states = n_distinct(d$state_abbr),
    N_obs = nrow(d),
    Mean_enrollment = round(mean(d$medicaid_enrollment, na.rm = TRUE) / 1e6, 2),
    SD_enrollment = round(sd(d$medicaid_enrollment, na.rm = TRUE) / 1e6, 2),
    Mean_abs_pct = round(mean(d$abs_pct_change, na.rm = TRUE), 3),
    SD_abs_pct = round(sd(d$abs_pct_change, na.rm = TRUE), 3),
    Mean_recert = round(mean(d$recert_intensity, na.rm = TRUE), 3),
    SD_recert = round(sd(d$recert_intensity, na.rm = TRUE), 3),
    Mean_unemp = round(mean(d$unemp_rate, na.rm = TRUE), 1),
    stringsAsFactors = FALSE
  )
}
stats_df <- bind_rows(stats_list)

# Write LaTeX table
tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & All States & IES States & Non-IES States \\\\\n",
  "\\hline\n",
  sprintf("States & %d & %d & %d \\\\\n",
          stats_df$N_states[1], stats_df$N_states[2], stats_df$N_states[3]),
  sprintf("State-month observations & %s & %s & %s \\\\\n",
          format(stats_df$N_obs[1], big.mark=","),
          format(stats_df$N_obs[2], big.mark=","),
          format(stats_df$N_obs[3], big.mark=",")),
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Medicaid Enrollment}} \\\\\n",
  sprintf("\\quad Mean (millions) & %.2f & %.2f & %.2f \\\\\n",
          stats_df$Mean_enrollment[1], stats_df$Mean_enrollment[2], stats_df$Mean_enrollment[3]),
  sprintf("\\quad SD (millions) & %.2f & %.2f & %.2f \\\\\n",
          stats_df$SD_enrollment[1], stats_df$SD_enrollment[2], stats_df$SD_enrollment[3]),
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Enrollment Volatility (\\% month-over-month)}} \\\\\n",
  sprintf("\\quad Mean $|\\Delta\\%%|$ & %.3f & %.3f & %.3f \\\\\n",
          stats_df$Mean_abs_pct[1], stats_df$Mean_abs_pct[2], stats_df$Mean_abs_pct[3]),
  sprintf("\\quad SD $|\\Delta\\%%|$ & %.3f & %.3f & %.3f \\\\\n",
          stats_df$SD_abs_pct[1], stats_df$SD_abs_pct[2], stats_df$SD_abs_pct[3]),
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{SNAP Recertification Intensity}} \\\\\n",
  sprintf("\\quad Short-cycle share ($\\leq$6 mo.) & %.3f & %.3f & %.3f \\\\\n",
          stats_df$Mean_recert[1], stats_df$Mean_recert[2], stats_df$Mean_recert[3]),
  sprintf("\\quad SD & %.3f & %.3f & %.3f \\\\\n",
          stats_df$SD_recert[1], stats_df$SD_recert[2], stats_df$SD_recert[3]),
  "\\addlinespace\n",
  sprintf("Mean unemployment rate (\\%%) & %.1f & %.1f & %.1f \\\\\n",
          stats_df$Mean_unemp[1], stats_df$Mean_unemp[2], stats_df$Mean_unemp[3]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Sample covers 51 states (including DC) from January 2018 to December 2020. ",
  "Medicaid enrollment from CMS Monthly Enrollment Reports. ",
  "SNAP recertification intensity from USDA ERS SNAP Policy Database. ",
  "IES classification from KFF (January 2025): 26 states operate integrated eligibility systems ",
  "that process SNAP and Medicaid through a single platform. ",
  "Enrollment volatility is the absolute month-over-month percent change in total Medicaid enrollment.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# =============================================================================
# Table 2: Main Results
# =============================================================================

cat("Generating Table 2: Main results...\n")

# Extract coefficients and SEs
get_coef_row <- function(model, varname) {
  ct <- coeftable(model)
  idx <- grep(paste0("^", gsub("\\.", "\\\\.", varname), "$"), rownames(ct))
  if (length(idx) == 0) return(c(NA, NA, ""))
  coef <- ct[idx, 1]
  se <- ct[idx, 2]
  pv <- ct[idx, 4]
  stars <- ifelse(pv < 0.001, "***", ifelse(pv < 0.01, "**", ifelse(pv < 0.05, "*", "")))
  c(sprintf("%.3f%s", coef, stars), sprintf("(%.3f)", se), "")
}

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{SNAP Recertification Intensity and Medicaid Enrollment Volatility}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Baseline & + Controls & Avg. Cert Period \\\\\n",
  "\\hline\n",
  sprintf("Recert. intensity & %s & %s & \\\\\n",
          get_coef_row(m1a, "recert_intensity")[1],
          get_coef_row(m1b, "recert_intensity")[1]),
  sprintf(" & %s & %s & \\\\\n",
          get_coef_row(m1a, "recert_intensity")[2],
          get_coef_row(m1b, "recert_intensity")[2]),
  sprintf("Recert. intensity $\\times$ IES & %s & %s & \\\\\n",
          get_coef_row(m1a, "recert_intensity:ies_status")[1],
          get_coef_row(m1b, "recert_intensity:ies_status")[1]),
  sprintf(" & %s & %s & \\\\\n",
          get_coef_row(m1a, "recert_intensity:ies_status")[2],
          get_coef_row(m1b, "recert_intensity:ies_status")[2]),
  sprintf("Avg. cert period & & & %s \\\\\n",
          get_coef_row(m1c, "certearnavg")[1]),
  sprintf(" & & & %s \\\\\n",
          get_coef_row(m1c, "certearnavg")[2]),
  sprintf("Avg. cert period $\\times$ IES & & & %s \\\\\n",
          get_coef_row(m1c, "certearnavg:ies_status")[1]),
  sprintf(" & & & %s \\\\\n",
          get_coef_row(m1c, "certearnavg:ies_status")[2]),
  sprintf("Unemployment rate & & %s & \\\\\n",
          get_coef_row(m1b, "unemp_rate")[1]),
  sprintf(" & & %s & \\\\\n",
          get_coef_row(m1b, "unemp_rate")[2]),
  "\\addlinespace\n",
  "State FE & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(nobs(m1a), big.mark=","),
          format(nobs(m1b), big.mark=","),
          format(nobs(m1c), big.mark=",")),
  sprintf("Adj. $R^2$ & %.3f & %.3f & %.3f \\\\\n",
          fitstat(m1a, "ar2")[[1]], fitstat(m1b, "ar2")[[1]], fitstat(m1c, "ar2")[[1]]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is the absolute month-over-month percent change ",
  "in total Medicaid enrollment. Recertification intensity is the share of SNAP households ",
  "on $\\leq$6 month certification periods. IES is an indicator for states with integrated eligibility ",
  "systems. Standard errors clustered at the state level in parentheses. ",
  "$^{***}p<0.001$; $^{**}p<0.01$; $^{*}p<0.05$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

# =============================================================================
# Table 3: Robustness
# =============================================================================

cat("Generating Table 3: Robustness...\n")

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Non-IES Only & IES Only & Pre-COVID Only \\\\\n",
  "\\hline\n",
  sprintf("Recert. intensity & %s & %s & %s \\\\\n",
          get_coef_row(r1_non_ies, "recert_intensity")[1],
          get_coef_row(r1_ies, "recert_intensity")[1],
          get_coef_row(r5, "recert_intensity")[1]),
  sprintf(" & %s & %s & %s \\\\\n",
          get_coef_row(r1_non_ies, "recert_intensity")[2],
          get_coef_row(r1_ies, "recert_intensity")[2],
          get_coef_row(r5, "recert_intensity")[2]),
  sprintf("Recert. intensity $\\times$ IES & & & %s \\\\\n",
          get_coef_row(r5, "recert_intensity:ies_status")[1]),
  sprintf(" & & & %s \\\\\n",
          get_coef_row(r5, "recert_intensity:ies_status")[2]),
  "\\addlinespace\n",
  "State FE & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(nobs(r1_non_ies), big.mark=","),
          format(nobs(r1_ies), big.mark=","),
          format(nobs(r5), big.mark=",")),
  sprintf("Adj. $R^2$ & %.3f & %.3f & %.3f \\\\\n",
          fitstat(r1_non_ies, "ar2")[[1]], fitstat(r1_ies, "ar2")[[1]], fitstat(r5, "ar2")[[1]]),
  "\\addlinespace\n",
  sprintf("RI $p$-value (1,000 permutations) & \\multicolumn{3}{c}{%.3f} \\\\\n", ri_p),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Column (1) restricts to non-IES states as a placebo test. ",
  "Column (2) restricts to IES states. Column (3) restricts to the pre-COVID period ",
  "(January 2018--February 2020). The randomization inference (RI) $p$-value permutes IES ",
  "status across states 1,000 times, preserving the number of IES states. ",
  "Standard errors clustered at the state level. ",
  "$^{***}p<0.001$; $^{**}p<0.01$; $^{*}p<0.05$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, file.path(tables_dir, "tab3_robustness.tex"))

# =============================================================================
# Table 4: Mechanism and Heterogeneity
# =============================================================================

cat("Generating Table 4: Mechanism and heterogeneity...\n")

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Mechanism and Heterogeneity}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Log Applications & Expansion & Non-Expansion \\\\\n",
  "\\hline\n",
  sprintf("Recert. intensity & %s & %s & %s \\\\\n",
          get_coef_row(m4a, "recert_intensity")[1],
          get_coef_row(r6_expanded, "recert_intensity")[1],
          get_coef_row(r6_nonexpanded, "recert_intensity")[1]),
  sprintf(" & %s & %s & %s \\\\\n",
          get_coef_row(m4a, "recert_intensity")[2],
          get_coef_row(r6_expanded, "recert_intensity")[2],
          get_coef_row(r6_nonexpanded, "recert_intensity")[2]),
  sprintf("Recert. intensity $\\times$ IES & %s & %s & %s \\\\\n",
          get_coef_row(m4a, "recert_intensity:ies_status")[1],
          get_coef_row(r6_expanded, "recert_intensity:ies_status")[1],
          get_coef_row(r6_nonexpanded, "recert_intensity:ies_status")[1]),
  sprintf(" & %s & %s & %s \\\\\n",
          get_coef_row(m4a, "recert_intensity:ies_status")[2],
          get_coef_row(r6_expanded, "recert_intensity:ies_status")[2],
          get_coef_row(r6_nonexpanded, "recert_intensity:ies_status")[2]),
  "\\addlinespace\n",
  "State FE & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(nobs(m4a), big.mark=","),
          format(nobs(r6_expanded), big.mark=","),
          format(nobs(r6_nonexpanded), big.mark=",")),
  sprintf("Adj. $R^2$ & %.3f & %.3f & %.3f \\\\\n",
          fitstat(m4a, "ar2")[[1]], fitstat(r6_expanded, "ar2")[[1]], fitstat(r6_nonexpanded, "ar2")[[1]]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Column (1) uses log new Medicaid applications as the dependent variable ",
  "to test the administrative overload mechanism. Columns (2) and (3) split the sample by ",
  "Medicaid expansion status. The dependent variable in columns (2)--(3) is the absolute ",
  "month-over-month percent change in Medicaid enrollment. ",
  "Standard errors clustered at the state level. ",
  "$^{***}p<0.001$; $^{**}p<0.01$; $^{*}p<0.05$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, file.path(tables_dir, "tab4_mechanism.tex"))

# =============================================================================
# Table F1: Standardized Effect Size (SDE) Appendix — MANDATORY
# =============================================================================

cat("Generating Table F1: SDE appendix...\n")

# Compute SDE for main outcomes
# Primary: enrollment volatility (abs_pct_change)
# Binary treatment via IES status: SDE = β_interaction / SD(Y)

sd_y_main <- sd(df_main$abs_pct_change, na.rm = TRUE)
sd_y_cv <- sd(df_cv$roll_cv_12, na.rm = TRUE)
sd_y_apps <- sd(df_apps$log_apps, na.rm = TRUE)

# For continuous treatment (recert_intensity), SDE = β × SD(X) / SD(Y)
sd_x <- sd(df_main$recert_intensity, na.rm = TRUE)

# Main interaction coefficients
beta_main <- coeftable(m1a)["recert_intensity:ies_status", 1]
se_main <- coeftable(m1a)["recert_intensity:ies_status", 2]
beta_cv <- coeftable(m2a)["recert_intensity:ies_status", 1]
se_cv <- coeftable(m2a)["recert_intensity:ies_status", 2]
beta_apps <- coeftable(m4a)["recert_intensity:ies_status", 1]
se_apps <- coeftable(m4a)["recert_intensity:ies_status", 2]

# Since treatment is continuous (recert_intensity is 0-1 scale, interacted with binary IES):
# SDE = β × SD(recert_intensity) / SD(Y)
sde_main <- beta_main * sd_x / sd_y_main
se_sde_main <- se_main * sd_x / sd_y_main
sde_cv <- beta_cv * sd_x / sd_y_cv
se_sde_cv <- se_cv * sd_x / sd_y_cv
sde_apps <- beta_apps * sd_x / sd_y_apps
se_sde_apps <- se_apps * sd_x / sd_y_apps

classify <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

# Heterogeneity: Expansion vs Non-Expansion
beta_exp <- coeftable(r6_expanded)["recert_intensity:ies_status", 1]
se_exp <- coeftable(r6_expanded)["recert_intensity:ies_status", 2]
beta_nonexp <- coeftable(r6_nonexpanded)["recert_intensity:ies_status", 1]
se_nonexp <- coeftable(r6_nonexpanded)["recert_intensity:ies_status", 2]

sd_y_exp <- sd(df_main$abs_pct_change[df_main$expanded == 1], na.rm = TRUE)
sd_y_nonexp <- sd(df_main$abs_pct_change[df_main$expanded == 0], na.rm = TRUE)

sde_exp <- beta_exp * sd_x / sd_y_exp
se_sde_exp <- se_exp * sd_x / sd_y_exp
sde_nonexp <- beta_nonexp * sd_x / sd_y_nonexp
se_sde_nonexp <- se_nonexp * sd_x / sd_y_nonexp

# Build SDE rows
sde_rows <- data.frame(
  panel = c("A","A","A","B","B"),
  outcome = c("Enrollment volatility", "Rolling CV (12-month)", "Log applications",
              "Enrollment vol. (expansion)", "Enrollment vol. (non-expansion)"),
  beta = c(beta_main, beta_cv, beta_apps, beta_exp, beta_nonexp),
  se = c(se_main, se_cv, se_apps, se_exp, se_nonexp),
  sd_y = c(sd_y_main, sd_y_cv, sd_y_apps, sd_y_exp, sd_y_nonexp),
  sde = c(sde_main, sde_cv, sde_apps, sde_exp, sde_nonexp),
  se_sde = c(se_sde_main, se_sde_cv, se_sde_apps, se_sde_exp, se_sde_nonexp),
  stringsAsFactors = FALSE
)
sde_rows$classification <- sapply(sde_rows$sde, classify)

# SDE table notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does SNAP recertification intensity increase Medicaid enrollment volatility in states with integrated eligibility systems? ",
  "\\textbf{Policy mechanism:} Integrated eligibility systems process SNAP and Medicaid through shared caseworkers and IT infrastructure; ",
  "higher SNAP recertification frequency creates administrative backlogs that spill over to Medicaid enrollment processing. ",
  "\\textbf{Outcome definition:} Absolute month-over-month percent change in total state Medicaid enrollment (primary); ",
  "12-month rolling coefficient of variation (secondary); log new Medicaid applications (mechanism). ",
  "\\textbf{Treatment:} Continuous --- share of SNAP households on certification periods of six months or less, ",
  "interacted with binary indicator for integrated eligibility system status. ",
  "\\textbf{Data:} CMS Monthly Medicaid Enrollment Reports and USDA ERS SNAP Policy Database, ",
  "January 2018 to December 2020, state-month panel, 3,621 observations. ",
  "\\textbf{Method:} OLS with state and year-month fixed effects, standard errors clustered at state level. ",
  "\\textbf{Sample:} 51 U.S.\\ states including DC; 26 integrated eligibility system states, 25 non-integrated. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of recertification intensity ",
  "and SD($Y$) is the sample standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE LaTeX table
tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in which(sde_rows$panel == "A")) {
  tabF1 <- paste0(tabF1, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    sde_rows$outcome[i], sde_rows$beta[i], sde_rows$se[i],
    sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
    sde_rows$classification[i]
  ))
}

tabF1 <- paste0(tabF1,
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Medicaid expansion status)}} \\\\\n"
)

for (i in which(sde_rows$panel == "B")) {
  tabF1 <- paste0(tabF1, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    sde_rows$outcome[i], sde_rows$beta[i], sde_rows$se[i],
    sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
    sde_rows$classification[i]
  ))
}

tabF1 <- paste0(tabF1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat(sprintf("Files: %s\n", paste(list.files(tables_dir), collapse = ", ")))
