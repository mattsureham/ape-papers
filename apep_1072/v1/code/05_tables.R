# 05_tables.R — Generate all tables for paper
# apep_1072: Dam Removal and Water Quality

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and results
temp_yearly  <- readRDS(file.path(data_dir, "temp_yearly.rds"))
do_yearly    <- readRDS(file.path(data_dir, "do_yearly.rds"))
dams         <- readRDS(file.path(data_dir, "dams_clean.rds"))
results      <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results  <- readRDS(file.path(data_dir, "robustness_results.rds"))
temp_matches <- readRDS(file.path(data_dir, "temp_matches.rds"))

# ============================================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-treatment statistics for treated gauges
temp_pre_treated <- temp_yearly %>% filter(treated == 1, year < first_treat)
temp_pre_control <- temp_yearly %>% filter(treated == 0)
do_pre_treated   <- do_yearly %>% filter(treated == 1, year < first_treat)
do_pre_control   <- do_yearly %>% filter(treated == 0)

# Build summary table
sumstats <- data.frame(
  Variable = c(
    "\\textit{Panel A: Temperature Sample}",
    "\\quad Water temperature ($^{\\circ}$C)",
    "\\quad Gauge-year observations",
    "\\quad Unique gauges",
    "",
    "\\textit{Panel B: Dissolved Oxygen Sample}",
    "\\quad Dissolved oxygen (mg/L)",
    "\\quad Gauge-year observations",
    "\\quad Unique gauges",
    "",
    "\\textit{Panel C: Dam Characteristics}",
    "\\quad Dam height (ft)",
    "\\quad Year removed",
    "\\quad Dam removals (2000--2020)"
  ),
  Treated_Mean = c(
    "",
    sprintf("%.2f", mean(temp_pre_treated$temp_mean, na.rm = TRUE)),
    sprintf("%s", format(nrow(temp_pre_treated), big.mark = ",")),
    sprintf("%d", n_distinct(temp_pre_treated$site_no)),
    "",
    "",
    sprintf("%.2f", mean(do_pre_treated$do_mean, na.rm = TRUE)),
    sprintf("%s", format(nrow(do_pre_treated), big.mark = ",")),
    sprintf("%d", n_distinct(do_pre_treated$site_no)),
    "",
    "",
    sprintf("%.1f", mean(dams$dam_height_ft, na.rm = TRUE)),
    sprintf("%.0f", mean(dams$year_removed)),
    sprintf("%s", format(nrow(dams), big.mark = ","))
  ),
  Treated_SD = c(
    "",
    sprintf("(%.2f)", sd(temp_pre_treated$temp_mean, na.rm = TRUE)),
    "", "",
    "",
    "",
    sprintf("(%.2f)", sd(do_pre_treated$do_mean, na.rm = TRUE)),
    "", "",
    "",
    "",
    sprintf("(%.1f)", sd(dams$dam_height_ft, na.rm = TRUE)),
    sprintf("(%.1f)", sd(dams$year_removed)),
    ""
  ),
  Control_Mean = c(
    "",
    sprintf("%.2f", mean(temp_pre_control$temp_mean, na.rm = TRUE)),
    sprintf("%s", format(nrow(temp_pre_control), big.mark = ",")),
    sprintf("%d", n_distinct(temp_pre_control$site_no)),
    "",
    "",
    sprintf("%.2f", mean(do_pre_control$do_mean, na.rm = TRUE)),
    sprintf("%s", format(nrow(do_pre_control), big.mark = ",")),
    sprintf("%d", n_distinct(do_pre_control$site_no)),
    "",
    "",
    "---",
    "---",
    "---"
  ),
  Control_SD = c(
    "",
    sprintf("(%.2f)", sd(temp_pre_control$temp_mean, na.rm = TRUE)),
    "", "",
    "",
    "",
    sprintf("(%.2f)", sd(do_pre_control$do_mean, na.rm = TRUE)),
    "", "",
    "",
    "",
    "", "", ""
  )
)

# Write LaTeX
tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Treated Gauges} & \\multicolumn{2}{c}{Control Gauges} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(sumstats))) {
  row <- sumstats[i, ]
  if (row$Variable == "") {
    tab1 <- paste0(tab1, " \\\\\n")
  } else {
    tab1 <- paste0(tab1, sprintf("%s & %s & %s & %s & %s \\\\\n",
                                 row$Variable, row$Treated_Mean, row$Treated_SD,
                                 row$Control_Mean, row$Control_SD))
  }
}

tab1 <- paste0(tab1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item \\textit{Notes:} Summary statistics for the analysis sample. ",
  "Treated gauges are USGS stream monitoring stations within 20 km of a dam ",
  "removed between 2000 and 2020. Control gauges are stations on rivers with ",
  "no dam removals in the same states. Statistics for treated gauges are ",
  "computed using pre-treatment observations only. Data source: American Rivers ",
  "Dam Removal Database (Figshare) and USGS National Water Information System.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(table_dir, "tab1_sumstats.tex"))

# ============================================================================
# TABLE 2: MAIN RESULTS (SA event study, key coefficients)
# ============================================================================

cat("=== Generating Table 2: Main Results ===\n")

es_temp <- results$es_temp_coefs
es_do   <- results$es_do_coefs

# Select key event-time coefficients for table
key_events <- c(-3, -2, -1, 0, 1, 2, 3, 5, 8, 10)

temp_rows <- es_temp %>%
  filter(e %in% key_events) %>%
  arrange(e)

do_rows <- es_do %>%
  filter(e %in% key_events) %>%
  arrange(e)

# Build table
tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Dam Removal on Water Quality: Sun-Abraham Estimates}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Temperature ($^{\\circ}$C)} & \\multicolumn{2}{c}{Dissolved Oxygen (mg/L)} \\\\\n",
  "Event Year & Estimate & SE & Estimate & SE \\\\\n",
  "\\hline\n",
  "\\textit{Pre-treatment} \\\\\n"
)

for (e_val in key_events) {
  label <- ifelse(e_val < 0,
                  sprintf("$t %d$", e_val),
                  ifelse(e_val == 0, "$t = 0$", sprintf("$t + %d$", e_val)))

  # Divider before post-treatment
  if (e_val == 0 && !grepl("Post-treatment", tab2)) {
    tab2 <- paste0(tab2, "\\hline\n\\textit{Post-treatment} \\\\\n")
  }

  t_row <- temp_rows %>% filter(e == e_val)
  d_row <- do_rows %>% filter(e == e_val)

  t_est <- ifelse(nrow(t_row) > 0, sprintf("%.3f%s",
    t_row$att, ifelse(abs(t_row$att / t_row$se) > 2.576, "***",
                      ifelse(abs(t_row$att / t_row$se) > 1.96, "**",
                             ifelse(abs(t_row$att / t_row$se) > 1.645, "*", "")))), "---")
  t_se  <- ifelse(nrow(t_row) > 0, sprintf("(%.3f)", t_row$se), "")

  d_est <- ifelse(nrow(d_row) > 0, sprintf("%.3f%s",
    d_row$att, ifelse(abs(d_row$att / d_row$se) > 2.576, "***",
                      ifelse(abs(d_row$att / d_row$se) > 1.96, "**",
                             ifelse(abs(d_row$att / d_row$se) > 1.645, "*", "")))), "---")
  d_se  <- ifelse(nrow(d_row) > 0, sprintf("(%.3f)", d_row$se), "")

  tab2 <- paste0(tab2, sprintf("%s & %s & %s & %s & %s \\\\\n",
                                label, t_est, t_se, d_est, d_se))
}

# Add overall ATT row
tab2 <- paste0(tab2,
  "\\hline\n",
  sprintf("Overall ATT & %.3f & (%.3f) & %.3f & (%.3f) \\\\\n",
          results$att_temp, results$att_temp_se,
          results$att_do, results$att_do_se),
  sprintf("TWFE estimate & %.3f & (%.3f) & %.3f & (%.3f) \\\\\n",
          coef(results$twfe_temp)["post_twfe"], se(results$twfe_temp)["post_twfe"],
          coef(results$twfe_do)["post_twfe"], se(results$twfe_do)["post_twfe"]),
  "\\hline\n",
  sprintf("Gauge-years & %s & & %s & \\\\\n",
          format(nrow(temp_yearly), big.mark = ","),
          format(nrow(do_yearly), big.mark = ",")),
  sprintf("Treated gauges & %d & & %d & \\\\\n",
          n_distinct(temp_yearly$site_no[temp_yearly$treated == 1]),
          n_distinct(do_yearly$site_no[do_yearly$treated == 1])),
  sprintf("Control gauges & %d & & %d & \\\\\n",
          n_distinct(temp_yearly$site_no[temp_yearly$treated == 0]),
          n_distinct(do_yearly$site_no[do_yearly$treated == 0])),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sun-Abraham (2021) heterogeneity-robust estimates of the ",
  "effect of dam removal on downstream water quality. Each column reports interaction-weighted ",
  "estimates by event year (years since dam removal). The treatment is the removal of a dam, ",
  "with timing from the American Rivers Dam Removal Database (2000--2020). Outcomes are annual ",
  "mean water temperature ($^{\\circ}$C) and dissolved oxygen (mg/L) from USGS continuous stream ",
  "gauges within 20 km of the removal site. All specifications include gauge and year fixed effects. ",
  "Standard errors clustered at the gauge level. The ``Overall ATT'' averages post-treatment event-time ",
  "coefficients. The ``TWFE estimate'' reports the conventional two-way fixed effects estimator for comparison. ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(table_dir, "tab2_main.tex"))

# ============================================================================
# TABLE 3: ROBUSTNESS
# ============================================================================

cat("=== Generating Table 3: Robustness ===\n")

# Collect robustness estimates
rob_specs <- data.frame(
  Specification = c(
    "Main (Sun-Abraham, 20 km)",
    "TWFE (for comparison)",
    "Close gauges ($\\leq$ 10 km)",
    "Far gauges ($>$ 10 km)",
    "Placebo (random treatment year)",
    "Leave-one-state-out (range)"
  ),
  Temperature = c(
    sprintf("%.3f (%.3f)", results$att_temp, results$att_temp_se),
    sprintf("%.3f (%.3f)", coef(results$twfe_temp)["post_twfe"],
            se(results$twfe_temp)["post_twfe"]),
    sprintf("%.3f (%.3f)", coef(rob_results$sa_close)["post_twfe"],
            se(rob_results$sa_close)["post_twfe"]),
    sprintf("%.3f (%.3f)", coef(rob_results$sa_far)["post_twfe"],
            se(rob_results$sa_far)["post_twfe"]),
    sprintf("%.3f", mean(rob_results$placebo_coefs$att[rob_results$placebo_coefs$e >= 0])),
    sprintf("[%.3f, %.3f]", min(rob_results$loso_df$coef), max(rob_results$loso_df$coef))
  ),
  stringsAsFactors = FALSE
)

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Water Temperature}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lc}\n",
  "\\hline\\hline\n",
  "Specification & Temperature ($^{\\circ}$C) \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(rob_specs))) {
  tab3 <- paste0(tab3, sprintf("%s & %s \\\\\n",
                                rob_specs$Specification[i], rob_specs$Temperature[i]))
}

tab3 <- paste0(tab3,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item \\textit{Notes:} Robustness of the temperature result to alternative specifications. ",
  "Row 1 reports the Sun-Abraham overall ATT. Row 2 is the conventional TWFE estimate. ",
  "Rows 3--4 split by gauge-to-dam distance. Row 5 assigns random treatment years to control gauges. ",
  "Row 6 reports the range of TWFE coefficients from sequentially dropping each state with treated gauges. ",
  "Standard errors (in parentheses) clustered at the gauge level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(table_dir, "tab3_robust.tex"))

# ============================================================================
# TABLE 4: DOSE-RESPONSE (Dam Height)
# ============================================================================

cat("=== Generating Table 4: Dose-Response ===\n")

if (!is.null(rob_results$dose_temp)) {
  tab4 <- paste0(
    "\\begin{table}[t]\n",
    "\\centering\n",
    "\\caption{Dose-Response: Dam Height and Temperature Effects}\n",
    "\\label{tab:dose}\n",
    "\\begin{tabular}{lcc}\n",
    "\\hline\\hline\n",
    " & (1) & (2) \\\\\n",
    " & Temperature & Temperature \\\\\n",
    "\\hline\n",
    sprintf("Post $\\times$ Dam Height (std.) & & %.3f \\\\\n",
            coef(rob_results$dose_temp)["post_twfe:height_std"]),
    sprintf(" & & (%.3f) \\\\\n",
            se(rob_results$dose_temp)["post_twfe:height_std"]),
    sprintf("Post & %.3f & %.3f \\\\\n",
            coef(results$twfe_temp)["post_twfe"],
            coef(rob_results$dose_temp)["post_twfe"]),
    sprintf(" & (%.3f) & (%.3f) \\\\\n",
            se(results$twfe_temp)["post_twfe"],
            se(rob_results$dose_temp)["post_twfe"]),
    "\\hline\n",
    "Gauge FE & Yes & Yes \\\\\n",
    "Year FE & Yes & Yes \\\\\n",
    "Sample & All treated & Height available \\\\\n",
    "\\hline\\hline\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}\n",
    "\\small\n",
    "\\item \\textit{Notes:} Column (1) reproduces the TWFE baseline on all treated gauges. ",
    "Column (2) restricts to gauges matched to dams with recorded height and interacts the ",
    "post-treatment indicator with standardized dam height (mean zero, unit variance). ",
    "A negative interaction means taller dams produce larger temperature reductions. ",
    "Standard errors clustered at the gauge level. ",
    "*** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
    "\\end{tablenotes}\n",
    "\\end{table}\n"
  )
  writeLines(tab4, file.path(table_dir, "tab4_dose.tex"))
}

# ============================================================================
# TABLE F1: SDE TABLE (MANDATORY)
# ============================================================================

cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# Pre-treatment SDs
sd_temp_pre <- sd(temp_yearly$temp_mean[temp_yearly$treated == 1 &
                                         temp_yearly$year < temp_yearly$first_treat], na.rm = TRUE)
sd_do_pre   <- sd(do_yearly$do_mean[do_yearly$treated == 1 &
                                     do_yearly$year < do_yearly$first_treat], na.rm = TRUE)

# Main estimates
beta_temp <- results$att_temp
se_temp   <- results$att_temp_se
beta_do   <- results$att_do
se_do     <- results$att_do_se

# SDE calculations
sde_temp    <- beta_temp / sd_temp_pre
se_sde_temp <- se_temp / sd_temp_pre
sde_do      <- beta_do / sd_do_pre
se_sde_do   <- se_do / sd_do_pre

# Classify
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

class_temp <- classify_sde(sde_temp)
class_do   <- classify_sde(sde_do)

# Heterogeneous SDE: by dam height (tall vs short)
# Use close gauges vs far gauges as heterogeneity
sde_close <- coef(rob_results$sa_close)["post_twfe"] / sd_temp_pre
se_sde_close <- se(rob_results$sa_close)["post_twfe"] / sd_temp_pre
class_close <- classify_sde(sde_close)

sde_far <- coef(rob_results$sa_far)["post_twfe"] / sd_temp_pre
se_sde_far <- se(rob_results$sa_far)["post_twfe"] / sd_temp_pre
class_far <- classify_sde(sde_far)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does removing a dam improve downstream water quality ",
  "as measured by continuous sensor readings at USGS stream gauges? ",
  "\\textbf{Policy mechanism:} Dam removal physically eliminates a barrier that creates ",
  "a warm-water impoundment, restoring natural flow regimes, thermal cycling, and sediment transport. ",
  "\\textbf{Outcome definition:} Panel A reports annual mean water temperature (degrees Celsius, ",
  "USGS parameter 00010) and annual mean dissolved oxygen concentration (mg/L, parameter 00300) ",
  "at stream gauges. Panel B splits the temperature outcome by gauge proximity to the removal site. ",
  "\\textbf{Treatment:} Binary---dam removed (year of removal from American Rivers Database). ",
  "\\textbf{Data:} American Rivers Dam Removal Database (1,341 removals, 2000--2020) matched to ",
  "USGS National Water Information System daily stream gauge readings; 9,204 gauge-year observations ",
  "for temperature, 2,719 for dissolved oxygen, 1995--2023. ",
  "\\textbf{Method:} Sun-Abraham (2021) interaction-weighted estimator with gauge and year fixed effects; ",
  "standard errors clustered at the gauge level; overall ATT averages post-treatment event-time coefficients. ",
  "\\textbf{Sample:} USGS stream gauges within 20 km of a dam removal site (treated) or on rivers with no ",
  "removals in the same states (control); restricted to gauges with at least 5 years of data and 6 months ",
  "per year. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build SDE table
tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\textit{Panel A: Pooled} \\\\\n",
  sprintf("Water temperature ($^{\\circ}$C) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
          beta_temp, se_temp, sd_temp_pre, sde_temp, se_sde_temp, class_temp),
  sprintf("Dissolved oxygen (mg/L) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
          beta_do, se_do, sd_do_pre, sde_do, se_sde_do, class_do),
  "[0.5em]\n",
  "\\textit{Panel B: Heterogeneous (by proximity)} \\\\\n",
  sprintf("Temperature, $\\leq$ 10 km & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
          coef(rob_results$sa_close)["post_twfe"], se(rob_results$sa_close)["post_twfe"],
          sd_temp_pre, sde_close, se_sde_close, class_close),
  sprintf("Temperature, $>$ 10 km & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
          coef(rob_results$sa_far)["post_twfe"], se(rob_results$sa_far)["post_twfe"],
          sd_temp_pre, sde_far, se_sde_far, class_far),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("  tab1_sumstats.tex\n  tab2_main.tex\n  tab3_robust.tex\n  tab4_dose.tex\n  tabF1_sde.tex\n")
