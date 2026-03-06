# ==============================================================================
# 06_tables.R — All tables
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
models <- readRDS(file.path(data_dir, "all_models.rds"))
sumstats <- fread(file.path(data_dir, "summary_stats.csv"))

# ==============================================================================
# TABLE 1: SUMMARY STATISTICS
# ==============================================================================
cat("Table 1: Summary Statistics\n")

var_labels <- c(
  climate_search = "Climate search index",
  agricultural = "Agricultural search index",
  placebo = "Placebo search index (cricket/Bollywood)",
  tavg_anomaly = "Temperature anomaly ($^\\circ$C)",
  tavg_z = "Temperature z-score",
  precip_anomaly = "Precipitation anomaly (mm)",
  ag_emp_share = "Agricultural employment share",
  crop_area_share = "Crop area share",
  heat_extreme = "Heat extreme (z $>$ 1.5)",
  internet_pen_2015 = "Internet penetration (per 100)"
)

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "Variable & N & Mean & SD & Min & Max \\\\",
  "\\midrule"
)

for (v in names(var_labels)) {
  row <- sumstats[Variable == v]
  if (nrow(row) > 0) {
    tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s & %s \\\\",
      var_labels[v],
      format(row$N, big.mark = ","),
      round(row$Mean, 3), round(row$SD, 3),
      round(row$Min, 3), round(row$Max, 3)))
  }
}

tab1 <- c(tab1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} State-month panel, 2004--2024, 21 Indian states. Climate and agricultural search indices from Google Trends (0--100 scale). Temperature anomalies computed from NASA POWER gridded data relative to 1981--2010 normals. Agricultural employment share from Census of India 2001.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, file.path(tab_dir, "table1_sumstats.tex"))
cat("  Saved table1_sumstats.tex\n")

# ==============================================================================
# TABLE 2: PRIMARY OLS RESULTS
# ==============================================================================
cat("Table 2: Primary Results\n")

etable(models$ols_baseline, models$ols_precip, models$ols_main,
       models$ols_both, models$ols_log,
       tex = TRUE,
       file = file.path(tab_dir, "table2_ols.tex"),
       replace = TRUE,
       title = "Temperature Anomalies and Climate Search Interest",
       label = "tab:primary",
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
       dict = c(tavg_anomaly = "Temp. Anomaly ($^\\circ$C)",
                tavg_x_ag = "Temp. $\\times$ Ag Share",
                precip_anomaly = "Precip. Anomaly (mm)",
                precip_x_ag = "Precip. $\\times$ Ag Share",
                tavg_x_crop = "Temp. $\\times$ Crop Share"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       notes = "Dependent variable: Google Trends climate search index (columns 1--4) or log(index + 1) (column 5). State and time (year-month) fixed effects in all models. Standard errors clustered at state level in parentheses.")

cat("  Saved table2_ols.tex\n")

# ==============================================================================
# TABLE 3: SUBSTITUTION — Climate vs Agricultural search
# ==============================================================================
cat("Table 3: Substitution\n")

etable(models$sub_climate, models$sub_agricultural, models$sub_placebo,
       models$sub_ag_log,
       tex = TRUE,
       file = file.path(tab_dir, "table3_substitution.tex"),
       replace = TRUE,
       title = "Attention Substitution: Climate vs.\\ Agricultural Search Responses to Temperature",
       label = "tab:substitution",
       headers = c("Climate", "Agricultural", "Placebo", "Log Ag."),
       dict = c(tavg_anomaly = "Temp. Anomaly ($^\\circ$C)",
                tavg_x_ag = "Temp. $\\times$ Ag Share"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       notes = "Each column uses a different dependent variable. Climate = average of ``global warming'' and ``climate change'' search indices. Agricultural = average of ``crop damage,'' ``rain forecast,'' ``crop insurance,'' and ``mandi price'' indices. Placebo = average of ``cricket'' and ``Bollywood'' indices. All models include state and time FE with state-clustered SEs.")

cat("  Saved table3_substitution.tex\n")

# ==============================================================================
# TABLE 4: SEASONAL SPLIT
# ==============================================================================
cat("Table 4: Seasonal Split\n")

etable(models$seas_nonmonsoon, models$seas_monsoon, models$seas_hot,
       models$seas_ag_monsoon, models$seas_ag_nonmonsoon,
       tex = TRUE,
       file = file.path(tab_dir, "table4_seasonal.tex"),
       replace = TRUE,
       title = "Seasonal Heterogeneity: Monsoon vs.\\ Non-Monsoon",
       label = "tab:seasonal",
       headers = c("Non-Mon.", "Monsoon", "Hot (M-M)", "Ag: Mon.", "Ag: Non-M."),
       dict = c(tavg_anomaly = "Temp. Anomaly ($^\\circ$C)",
                tavg_x_ag = "Temp. $\\times$ Ag Share"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       notes = "Columns 1--3: climate search outcome. Columns 4--5: agricultural search outcome. Non-monsoon = October--May; Monsoon = June--September; Hot = March--May. State and time FE, state-clustered SEs.")

cat("  Saved table4_seasonal.tex\n")

# ==============================================================================
# TABLE 5: PLACEBO AND PERSISTENCE
# ==============================================================================
cat("Table 5: Placebo Tests\n")

etable(models$placebo_outcome, models$placebo_lead1, models$placebo_lead3,
       models$distributed_lags,
       tex = TRUE,
       file = file.path(tab_dir, "table5_placebo.tex"),
       replace = TRUE,
       title = "Placebo Tests and Persistence",
       label = "tab:placebo",
       headers = c("Placebo Out.", "Lead 1m", "Lead 3m", "Dist. Lags"),
       dict = c(tavg_anomaly = "Temp. Anomaly",
                tavg_lead1 = "Temp. Lead (1m)",
                tavg_lead3 = "Temp. Lead (3m)",
                tavg_lag1 = "Temp. Lag (1m)",
                tavg_lag3 = "Temp. Lag (3m)",
                tavg_lag6 = "Temp. Lag (6m)",
                tavg_lag12 = "Temp. Lag (12m)"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       notes = "Column 1: placebo outcome (cricket/Bollywood search). Columns 2--3: future temperature should not predict current climate search. Column 4: distributed lag model. State and time FE, state-clustered SEs.")

cat("  Saved table5_placebo.tex\n")

# ==============================================================================
# TABLE 6: ROBUSTNESS
# ==============================================================================
cat("Table 6: Robustness\n")

rob <- fread(file.path(data_dir, "robustness_summary.csv"))

tab6 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Interaction of Temperature with Agricultural Share}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & N \\\\",
  "\\midrule",
  sprintf("Baseline (Table \\ref{tab:primary}, col. 3) & %s & (%s) & %s \\\\",
    round(coef(models$ols_main)["tavg_x_ag"], 3),
    round(se(models$ols_main)["tavg_x_ag"], 3),
    format(models$ols_main$nobs, big.mark = ","))
)

for (i in 1:nrow(rob)) {
  tab6 <- c(tab6, sprintf("%s & %s & (%s) & %s \\\\",
    rob$spec[i],
    ifelse(is.na(rob$interaction_coef[i]), "--", round(rob$interaction_coef[i], 3)),
    ifelse(is.na(rob$interaction_se[i]), "--", round(rob$interaction_se[i], 3)),
    format(rob$n_obs[i], big.mark = ",")))
}

tab6 <- c(tab6,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the coefficient on Temp.\\ Anomaly $\\times$ Ag Employment Share from a separate regression. State and time FE, state-clustered SEs throughout.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab6, file.path(tab_dir, "table6_robustness.tex"))
cat("  Saved table6_robustness.tex\n")

# ==============================================================================
# TABLE 7: INTERNET HETEROGENEITY
# ==============================================================================
cat("Table 7: Internet Heterogeneity\n")

etable(models$het_high_internet, models$het_low_internet,
       tex = TRUE,
       file = file.path(tab_dir, "table7_internet.tex"),
       replace = TRUE,
       title = "Heterogeneity by Internet Penetration",
       label = "tab:internet",
       headers = c("High Internet", "Low Internet"),
       dict = c(tavg_anomaly = "Temp. Anomaly ($^\\circ$C)",
                tavg_x_ag = "Temp. $\\times$ Ag Share"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       notes = "Sample split at median state-level internet penetration (TRAI 2015). State and time FE, state-clustered SEs.")

cat("  Saved table7_internet.tex\n")

cat("\n=== All tables complete ===\n")
