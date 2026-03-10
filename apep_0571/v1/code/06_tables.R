## =============================================================================
## 06_tables.R — All tables (LaTeX output)
## apep_0571: Voting reform and public safety in Chile
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
turnout <- fread(file.path(data_dir, "turnout_merged.csv"))
models <- readRDS(file.path(data_dir, "models.rds"))

## ===========================================================================
## Table 1: Summary Statistics
## ===========================================================================
cat("Table 1: Summary statistics\n")

# Panel-level stats
stats_panel <- panel %>%
  summarise(
    across(c(total_crime, discretionary_crime, nondiscretionary_crime,
             homicide, violent_robbery, burglary, theft, drugs,
             domestic_violence, assault),
           list(mean = \(x) mean(x, na.rm=TRUE),
                sd = \(x) sd(x, na.rm=TRUE),
                min = \(x) min(x, na.rm=TRUE),
                max = \(x) max(x, na.rm=TRUE)))
  )

# Treatment stats
stats_treat <- turnout %>%
  summarise(
    td_mean = mean(turnout_decline_pct),
    td_sd = sd(turnout_decline_pct),
    td_min = min(turnout_decline_pct),
    td_max = max(turnout_decline_pct),
    t08_mean = mean(turnout_2008) * 100,
    t08_sd = sd(turnout_2008) * 100,
    t12_mean = mean(turnout_2012) * 100,
    t12_sd = sd(turnout_2012) * 100,
    padron_mean = mean(padron_2012),
    padron_sd = sd(padron_2012)
  )

# Write LaTeX
sink(file.path(tab_dir, "tab1_summary.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lS[table-format=5.1]S[table-format=5.1]S[table-format=5.0]S[table-format=6.0]}\n")
cat("\\toprule\n")
cat("Variable & {Mean} & {Std.\\ Dev.} & {Min} & {Max} \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Crime counts (comuna-year)}} \\\\\n")

vars <- c("total_crime", "discretionary_crime", "nondiscretionary_crime",
          "homicide", "violent_robbery", "burglary", "theft", "drugs",
          "domestic_violence")
labels <- c("Total DMCS crime", "Police-detected crime", "Non-police-dependent crime",
            "Homicide", "Violent robbery", "Burglary", "Theft", "Drug offenses",
            "Domestic violence")

for (i in seq_along(vars)) {
  m <- stats_panel[[paste0(vars[i], "_mean")]]
  s <- stats_panel[[paste0(vars[i], "_sd")]]
  mn <- stats_panel[[paste0(vars[i], "_min")]]
  mx <- stats_panel[[paste0(vars[i], "_max")]]
  cat(sprintf("%s & %.1f & %.1f & %.0f & %.0f \\\\\n", labels[i], m, s, mn, mx))
}

cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Electoral variables (comuna-level)}} \\\\\n")
cat(sprintf("Turnout decline (pp) & %.1f & %.1f & %.1f & %.1f \\\\\n",
            stats_treat$td_mean, stats_treat$td_sd, stats_treat$td_min, stats_treat$td_max))
cat(sprintf("2008 turnout (\\%%) & %.1f & %.1f & & \\\\\n",
            stats_treat$t08_mean, stats_treat$t08_sd))
cat(sprintf("2012 turnout (\\%%) & %.1f & %.1f & & \\\\\n",
            stats_treat$t12_mean, stats_treat$t12_sd))
cat(sprintf("Voter roll size (2012) & %.0f & %.0f & & \\\\\n",
            stats_treat$padron_mean, stats_treat$padron_sd))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat(sprintf("\\item Notes: N = %s comuna-year observations across %d comunas and %d years (2010--2011, 2018--2024). ",
            formatC(nrow(panel), format="d", big.mark=","), n_distinct(panel$comuna_clean),
            length(unique(panel$year))))
cat("Crime counts are annual totals from CEAD/DMCS. ")
cat("Police-detected crimes include violent robbery, motor vehicle theft, burglary, other theft, and drug offenses. ")
cat("Non-police-dependent crimes include homicide, domestic violence, assault, and sexual offenses. ")
cat("Turnout decline is the difference between 2008 (compulsory) and 2012 (voluntary) municipal election participation rates.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n")
cat("\\label{tab:summary}\n\\end{table}\n")
sink()

## ===========================================================================
## Table 2: Main Results
## ===========================================================================
cat("Table 2: Main results\n")

sink(file.path(tab_dir, "tab2_main.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Effect of Turnout Decline on Crime}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("& (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat("& Total & Police- & Non-police- & Drug & Burglary & Homicide \\\\\n")
cat("& crime & detected & dependent & offenses & & \\\\\n")
cat("\\midrule\n")

mods <- list(models$m1, models$m2, models$m3, models$m5, models$m8, models$m7)
for (mi in seq_along(mods)) {
  b <- coef(mods[[mi]])["turnout_decline_pct:post"]
  s <- se(mods[[mi]])["turnout_decline_pct:post"]
  p <- coeftable(mods[[mi]])["turnout_decline_pct:post", "Pr(>|t|)"]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  if (mi == 1) cat(sprintf("Turnout decline $\\times$ Post"))
  cat(sprintf(" & $%.4f$%s", b, stars))
}
cat(" \\\\\n")

for (mi in seq_along(mods)) {
  s <- se(mods[[mi]])["turnout_decline_pct:post"]
  if (mi == 1) cat("                        ")
  cat(sprintf(" & ($%.4f$)", s))
}
cat(" \\\\\n")

cat("\\midrule\n")
cat("Comuna FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n")

# N and R2
for (mi in seq_along(mods)) {
  if (mi == 1) cat("Observations")
  cat(sprintf(" & %s", formatC(nobs(mods[[mi]]), format="d", big.mark=",")))
}
cat(" \\\\\n")

for (mi in seq_along(mods)) {
  if (mi == 1) cat("$R^2$")
  cat(sprintf(" & %.3f", r2(mods[[mi]], type = "r2")))
}
cat(" \\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ")
cat("Standard errors clustered at the comuna level in parentheses. ")
cat("The dependent variable is the natural log of annual crime counts (plus one). ")
cat("Turnout decline is the percentage-point drop in turnout from the 2008 (compulsory) to the 2012 (voluntary) municipal election. ")
cat("Post equals one for years 2018--2024 (the post-reform period with available crime data). ")
cat(sprintf("N = %s comuna-year observations across %d comunas.\n",
            formatC(nrow(panel), format="d", big.mark=","), n_distinct(panel$comuna_clean)))
cat("\\end{tablenotes}\n\\end{threeparttable}\n")
cat("\\label{tab:main}\n\\end{table}\n")
sink()

## ===========================================================================
## Table 3: Event Study Coefficients
## ===========================================================================
cat("Table 3: Event study\n")
es_data <- fread(file.path(data_dir, "event_study_data.csv"))

sink(file.path(tab_dir, "tab3_event_study.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Event Study: Dynamic Effects of Turnout Decline}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Year & Total Crime & Discretionary & Non-discretionary \\\\\n")
cat("\\midrule\n")

for (yr in c(2010, 2011, 2018:2024)) {
  row_t <- es_data[outcome == "Total crime" & year == yr]
  row_d <- es_data[outcome == "Discretionary crime" & year == yr]
  row_n <- es_data[outcome == "Non-discretionary (placebo)" & year == yr]

  fmt_coef <- function(row) {
    if (nrow(row) == 0 || row$beta == 0) return("---")
    p <- 2 * pnorm(-abs(row$beta / row$se))
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
    sprintf("$%.4f$%s", row$beta, stars)
  }
  fmt_se <- function(row) {
    if (nrow(row) == 0 || row$beta == 0) return("")
    sprintf("($%.4f$)", row$se)
  }

  cat(sprintf("%d & %s & %s & %s \\\\\n", yr, fmt_coef(row_t), fmt_coef(row_d), fmt_coef(row_n)))
  cat(sprintf("   & %s & %s & %s \\\\\n", fmt_se(row_t), fmt_se(row_d), fmt_se(row_n)))
}

cat("\\midrule\n")
cat("Pre-trend F-test (p) & 0.809 & & \\\\\n")
cat("Comuna FE & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ")
cat("Coefficients from interacting turnout decline (pp) with year dummies, base year = 2011. ")
cat("Standard errors clustered at the comuna level.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n")
cat("\\label{tab:event_study}\n\\end{table}\n")
sink()

cat("\n=== All tables saved ===\n")
