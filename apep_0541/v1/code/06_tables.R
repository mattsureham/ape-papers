###############################################################################
# 06_tables.R — Generate all tables
# APEP-0541: How Many Generics Does It Take?
###############################################################################

source("00_packages.R")

data_dir   <- "../data"
table_dir  <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

# Load results
panel         <- fread(file.path(data_dir, "analysis_panel.csv"))
np_coefs      <- fread(file.path(data_dir, "nonparam_curve.csv"))
cross_by_n    <- fread(file.path(data_dir, "cross_section_by_n.csv"))
compare       <- fread(file.path(data_dir, "cross_vs_within.csv"))
main_results  <- fread(file.path(data_dir, "main_regression_results.csv"))
rob_summary   <- fread(file.path(data_dir, "robustness_summary.csv"))
marginal      <- fread(file.path(data_dir, "marginal_curve.csv"))
pretrend      <- fread(file.path(data_dir, "pretrend_tests.csv"))
placebo       <- tryCatch(fread(file.path(data_dir, "placebo_results.csv")),
                          error = function(e) NULL)

# ==========================================================================
# Table 1: Summary Statistics
# ==========================================================================

cat("Table 1: Summary statistics\n")

# Compute from panel
summ <- panel[, .(
  Variable = c("NADAC Per Unit ($)", "Log Price", "N Competitors",
               "Markets", "Market-Weeks", "Weeks"),
  Mean = c(sprintf("%.3f", mean(avg_price, na.rm=TRUE)),
           sprintf("%.3f", mean(log_price, na.rm=TRUE)),
           sprintf("%.1f", mean(n_competitors)),
           formatC(uniqueN(market), big.mark=","),
           formatC(.N, big.mark=","),
           as.character(uniqueN(week))),
  SD = c(sprintf("%.3f", sd(avg_price, na.rm=TRUE)),
         sprintf("%.3f", sd(log_price, na.rm=TRUE)),
         sprintf("%.1f", sd(n_competitors)),
         "", "", ""),
  Median = c(sprintf("%.3f", median(avg_price, na.rm=TRUE)),
             sprintf("%.3f", median(log_price, na.rm=TRUE)),
             as.character(median(n_competitors)),
             "", "", ""),
  Min = c(sprintf("%.3f", min(avg_price, na.rm=TRUE)),
          sprintf("%.3f", min(log_price, na.rm=TRUE)),
          as.character(min(n_competitors)),
          "", "", ""),
  Max = c(sprintf("%.3f", max(avg_price, na.rm=TRUE)),
          sprintf("%.3f", max(log_price, na.rm=TRUE)),
          as.character(max(n_competitors)),
          "", "", "")
)]

tab1_latex <- kbl(summ, format = "latex", booktabs = TRUE,
                  caption = "Summary Statistics: Generic Drug Markets, 2023--2024",
                  label = "tab:summary",
                  align = c("l", "r", "r", "r", "r", "r")) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  pack_rows("Panel Variables", 1, 3) %>%
  pack_rows("Sample Dimensions", 4, 6) %>%
  footnote(general = paste(
    "Data from CMS National Average Drug Acquisition Cost (NADAC), 2023--2024.",
    "Each observation is a drug market $\\\\times$ week.",
    "A market is defined by the NADAC drug description (ingredient $\\\\times$ form $\\\\times$ strength).",
    "N Competitors = number of unique NDC codes observed in that market-week."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(tab1_latex, file.path(table_dir, "table1_summary.tex"))

# ==========================================================================
# Table 2: Main Regression Results
# ==========================================================================

cat("Table 2: Main regression results\n")

# Rebuild regressions for modelsummary
panel[, week_date := as.Date(week)]
panel[, log_n := log(n_competitors)]
panel[, n_bin := pmin(n_competitors, 15)]

est_main <- feols(log_price ~ n_competitors | market_id + week_date,
                  data = panel, cluster = ~market_id)
est_loglog <- feols(log_price ~ log_n | market_id + week_date,
                    data = panel, cluster = ~market_id)
est_cross <- feols(log_price ~ n_competitors | week_date,
                   data = panel, cluster = ~market_id)
est_min <- feols(log_min_price ~ n_competitors | market_id + week_date,
                 data = panel, cluster = ~market_id)

# Create table
models <- list(
  "Cross-Section" = est_cross,
  "Within-Market" = est_main,
  "Log-Log" = est_loglog,
  "Min Price" = est_min
)

options("modelsummary_format_numeric_latex" = "plain")
modelsummary(models,
  output = file.path(table_dir, "table2_regressions.tex"),
  fmt = function(x) formatC(x, digits = 4, format = "f"),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_rename = c("n_competitors" = "N Competitors",
                  "log_n" = "Log(N Competitors)"),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  title = "Effect of Generic Competition on Drug Acquisition Cost",
  notes = c(
    "Dependent variable: log(NADAC per unit) in columns 1--3; log(minimum NADAC) in column 4.",
    "All specifications include calendar-week FE. Columns 2--4 add drug-market FE.",
    "Standard errors clustered by drug market. 4,512 markets, 51,643 market-weeks.",
    "* p < 0.10, ** p < 0.05, *** p < 0.01."
  )
)

# ==========================================================================
# Table 3: Selection Gap — Cross-Section vs Within-Market
# ==========================================================================

cat("Table 3: Selection gap\n")

gap_data <- compare[n_competitors <= 10]
gap_wide <- dcast(gap_data, n_competitors ~ specification, value.var = c("estimate", "se"))

tab3 <- gap_wide[, .(
  `N` = n_competitors,
  `Cross-Section` = sprintf("%.3f", estimate_cross_section),
  `(SE)` = sprintf("(%.3f)", se_cross_section),
  `Within-Market` = sprintf("%.3f", estimate_within_market),
  `(SE) ` = sprintf("(%.3f)", se_within_market),
  `Selection Bias` = sprintf("%.3f", estimate_cross_section - estimate_within_market)
)]

tab3_latex <- kbl(tab3, format = "latex", booktabs = TRUE,
                  caption = "Decomposing the Competition--Price Gradient: Selection vs.\\ Causation",
                  label = "tab:selection_gap",
                  align = c("c", "r", "r", "r", "r", "r")) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  add_header_above(c(" " = 1, "Cross-Section" = 2, "Within-Market" = 2, " " = 1)) %>%
  footnote(general = paste(
    "Both specifications use indicator variables for each competitor count (N=2,...,15), with N=1 as reference.",
    "Cross-section includes calendar-week FE only.",
    "Within-market adds drug-market FE, isolating within-market variation over time.",
    "Selection Bias = Cross-Section $-$ Within-Market.",
    "Standard errors clustered by drug market."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(tab3_latex, file.path(table_dir, "table3_selection_gap.tex"))

# ==========================================================================
# Table 4: Robustness Summary
# ==========================================================================

cat("Table 4: Robustness summary\n")

tab4_latex <- kbl(rob_summary[, .(Specification = specification,
                                   Coefficient = sprintf("%.5f", coefficient),
                                   Status = status)],
                  format = "latex", booktabs = TRUE,
                  caption = "Robustness: Linear Competition Effect Across Specifications",
                  label = "tab:robustness",
                  align = c("l", "r", "c")) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste(
    "Each row reports the estimated coefficient on N (number of competitors) or the average post-entry effect.",
    "Main specification: log(price) regressed on N with drug-market and calendar-week FE.",
    "Standard errors clustered by drug market in all panel specifications.",
    "Placebo: 100 permutations of shuffled market competitor assignments."
  ), threeparttable = TRUE)

writeLines(tab4_latex, file.path(table_dir, "table4_robustness.tex"))

# ==========================================================================
# Table 5: Cross-Section by Competitor Count
# ==========================================================================

cat("Table 5: Cross-section by N\n")

cs_tab <- cross_by_n[n_competitors <= 15, .(
  `N` = n_competitors,
  `Avg Price ($)` = sprintf("%.3f", avg_price),
  `Median Price ($)` = sprintf("%.3f", med_price),
  `Markets` = formatC(n_markets, big.mark = ","),
  `Observations` = formatC(n_obs, big.mark = ",")
)]

tab5_latex <- kbl(cs_tab, format = "latex", booktabs = TRUE,
                  caption = "Drug Acquisition Cost by Number of Generic Competitors",
                  label = "tab:cross_section",
                  align = c("c", "r", "r", "r", "r")) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste(
    "Each row summarizes all market-week observations with the given number of active generic NDCs.",
    "Prices are NADAC per-unit acquisition costs in dollars.",
    "The strong cross-sectional gradient (prices fall with N) reflects market sorting,",
    "not the causal effect of competition."
  ), threeparttable = TRUE)

writeLines(tab5_latex, file.path(table_dir, "table5_cross_section.tex"))

# ==========================================================================
# Table 6: Pre-Trend and Placebo Diagnostics
# ==========================================================================

cat("Table 6: Diagnostic tests\n")

diag_rows <- data.table(
  Test = c("Pre-trend F-test (pooled event study)",
           "Placebo (permuted market assignments)"),
  Statistic = c(sprintf("F = %.2f", pretrend$f_stat),
                sprintf("Actual = %.5f", placebo$actual_effect)),
  `p-value` = c(sprintf("%.4f", pretrend$p_value),
                sprintf("%.3f", placebo$placebo_p)),
  Result = c(ifelse(pretrend$passes, "Pass", "Fail"),
             ifelse(placebo$placebo_p > 0.05, "Pass", "Fail"))
)

tab6_latex <- kbl(diag_rows, format = "latex", booktabs = TRUE,
                  caption = "Diagnostic Tests",
                  label = "tab:diagnostics",
                  align = c("l", "r", "r", "c")) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste(
    "Pre-trend test: joint F-test that all pre-entry event-study coefficients equal zero.",
    "Placebo test: 100 permutations of shuffled market-level competitor counts.",
    "p-value reports the fraction of permuted effects exceeding the actual effect in magnitude."
  ), threeparttable = TRUE)

writeLines(tab6_latex, file.path(table_dir, "table6_diagnostics.tex"))

cat("\nAll tables saved to:", normalizePath(table_dir), "\n")
