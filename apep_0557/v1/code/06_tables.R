## ============================================================
## 06_tables.R — All tables for the paper
## Paper: Does Foreign Aid Buffer Oil Revenue Shocks?
##        Geocoded Evidence from Nigeria
## ============================================================

source("00_packages.R")

DATA_DIR  <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## Table 1: Summary Statistics
## ============================================================

cat("--- Table 1: Summary Statistics ---\n")

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))

## Create summary by pre/post and high/low aid
vars_to_summarize <- c("n_events", "n_state_based", "n_non_state", "fatalities",
                       "civ_deaths", "aid_projects_2007", "oil_price")

## Overall summary
overall <- panel[, lapply(.SD, function(x) {
  list(mean = mean(x, na.rm = TRUE),
       sd = sd(x, na.rm = TRUE),
       min = min(x, na.rm = TRUE),
       max = max(x, na.rm = TRUE),
       n = sum(!is.na(x)))
}), .SDcols = vars_to_summarize]

## Build table manually for LaTeX
sumstat_rows <- list()
for (v in vars_to_summarize) {
  vals <- panel[[v]]
  vals <- vals[!is.na(vals)]
  sumstat_rows[[v]] <- data.table(
    Variable = v,
    Mean = mean(vals),
    SD = sd(vals),
    Min = min(vals),
    Max = max(vals),
    N = length(vals)
  )
}
sumstats <- rbindlist(sumstat_rows)

## Rename for paper
sumstats[Variable == "n_events", Variable := "Conflict events (monthly)"]
sumstats[Variable == "n_state_based", Variable := "State-based conflict"]
sumstats[Variable == "n_non_state", Variable := "Non-state conflict"]
sumstats[Variable == "fatalities", Variable := "Fatalities (best estimate)"]
sumstats[Variable == "civ_deaths", Variable := "Civilian deaths"]
sumstats[Variable == "aid_projects_2007", Variable := "Aid projects (as of 2007)"]
sumstats[Variable == "oil_price", Variable := "Brent crude (\\$/bbl)"]

fwrite(sumstats, file.path(DATA_DIR, "table1_sumstats.csv"))

## LaTeX output
latex_tab1 <- xtable(sumstats, digits = c(0, 0, 2, 2, 0, 0, 0),
                     caption = "Summary Statistics",
                     label = "tab:sumstats")
print(latex_tab1,
      file = file.path(TABLE_DIR, "table1_sumstats.tex"),
      include.rownames = FALSE,
      sanitize.text.function = identity,
      booktabs = TRUE)
cat("Saved table1_sumstats.tex\n")

## ============================================================
## Table 2: Main DiD Results (modelsummary)
## ============================================================

cat("--- Table 2: Main DiD Results ---\n")

load(file.path(DATA_DIR, "main_models.RData"))

## modelsummary for main results — write directly to LaTeX file
options("modelsummary_format_numeric_latex" = "plain")
tab2_file <- file.path(TABLE_DIR, "table2_main_did.tex")
msummary(list(
  "(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4, "(5)" = m5
),
  coef_map = c(
    "log_aid_x_post" = "Log(Aid) $\\times$ Post",
    "high_aid_x_post" = "High Aid $\\times$ Post",
    "aid_x_post" = "Aid Projects $\\times$ Post",
    "oil_price" = "Oil Price",
    "oil_state:post_shock" = "Oil State $\\times$ Post"
  ),
  gof_map = c("nobs", "r.squared", "adj.r.squared",
              "FE: state", "FE: ym"),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title = "Main DiD Results: Aid Exposure and Conflict",
  notes = "Standard errors clustered at the state level in parentheses.",
  output = tab2_file,
  escape = FALSE
)
## Inject label into the generated file (tabularray uses caption={...} syntax)
tab2_lines <- readLines(tab2_file)
tab2_lines <- gsub("(caption=\\{[^}]+\\},)",
                    "\\1\nlabel={tab:main_did},", tab2_lines)
writeLines(tab2_lines, tab2_file)
cat("Saved table2_main_did.tex\n")

## ============================================================
## Table 3: Outcome Heterogeneity
## ============================================================

cat("--- Table 3: Outcome Heterogeneity ---\n")

tab3_file <- file.path(TABLE_DIR, "table3_outcome_het.tex")
msummary(list(
  "State-Based" = m_state_based,
  "Non-State" = m_non_state,
  "Fatalities" = m_fatal,
  "Civilian Deaths" = m_civ
),
  coef_map = c("log_aid_x_post" = "Log(Aid) $\\times$ Post"),
  gof_map = c("nobs", "r.squared"),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title = "Outcome Heterogeneity: Aid Exposure and Conflict Types",
  notes = "Standard errors clustered at the state level in parentheses.",
  output = tab3_file,
  escape = FALSE
)
## Inject label into the generated file (tabularray uses caption={...} syntax)
tab3_lines <- readLines(tab3_file)
tab3_lines <- gsub("(caption=\\{[^}]+\\},)",
                    "\\1\nlabel={tab:outcome_het},", tab3_lines)
writeLines(tab3_lines, tab3_file)
cat("Saved table3_outcome_het.tex\n")

## ============================================================
## Table 4: Robustness Summary
## ============================================================

cat("--- Table 4: Robustness Summary ---\n")

robustness <- fread(file.path(DATA_DIR, "robustness_summary.csv"))

## Add N to robustness table
robustness[, N := c(7992L, 666L, 7776L, 7992L, 7992L)[1:.N]]

## Format for LaTeX
rob_latex <- robustness[, .(
  Specification = test,
  N = format(N, big.mark = ","),
  Estimate = sprintf("%.4f", estimate),
  SE = fifelse(is.na(se), "---", sprintf("%.4f", se)),
  `p-value` = sprintf("%.4f", pvalue),
  `95\\% CI` = fifelse(is.na(ci_lo), "---",
                       sprintf("[%.4f, %.4f]", ci_lo, ci_hi))
)]

latex_tab4 <- xtable(rob_latex,
                     caption = "Robustness Checks",
                     label = "tab:robustness")
print(latex_tab4,
      file = file.path(TABLE_DIR, "table4_robustness.tex"),
      include.rownames = FALSE,
      sanitize.text.function = identity,
      booktabs = TRUE)
cat("Saved table4_robustness.tex\n")

## ============================================================
## Table 5: State-level descriptives
## ============================================================

cat("--- Table 5: Top 15 states by aid exposure ---\n")

state_summary <- fread(file.path(DATA_DIR, "state_summary.csv"))
state_top <- state_summary[order(-aid_projects)][1:15]
state_top[, .(State = state,
              `Aid Projects` = aid_projects,
              `Mean Events/Month` = round(mean_events, 2),
              `Total Fatalities` = total_fatalities,
              `Oil Producing` = ifelse(oil_producing == 1, "Yes", "No"))]

latex_tab5 <- xtable(
  state_top[, .(State = state,
                `Aid Projects` = aid_projects,
                `Mean Monthly Events` = round(mean_events, 2),
                `Total Fatalities` = total_fatalities,
                `Oil State` = ifelse(oil_producing == 1, "Yes", "No"))],
  caption = "Top 15 States by Geocoded Aid Exposure (as of December 2007)",
  label = "tab:state_descriptives"
)
print(latex_tab5,
      file = file.path(TABLE_DIR, "table5_state_desc.tex"),
      include.rownames = FALSE,
      booktabs = TRUE)
cat("Saved table5_state_desc.tex\n")

## ============================================================
## Table A1: Alternative shock windows
## ============================================================

cat("--- Table A1: Alternative shock windows ---\n")

alt_shocks <- fread(file.path(DATA_DIR, "alt_shock_results.csv"))
alt_shocks[, shock_date := as.character(shock_date)]
alt_latex <- alt_shocks[, .(
  `Shock Date` = format(as.Date(shock_date), "%b %Y"),
  N = "7,992",
  Estimate = sprintf("%.4f", estimate),
  SE = sprintf("%.4f", se),
  `p-value` = sprintf("%.4f", pvalue),
  `95\\% CI` = sprintf("[%.4f, %.4f]", ci_lo, ci_hi)
)]

latex_tabA1 <- xtable(alt_latex,
                      caption = "Sensitivity to Alternative Shock Dates",
                      label = "tab:alt_shocks")
print(latex_tabA1,
      file = file.path(TABLE_DIR, "tableA1_alt_shocks.tex"),
      include.rownames = FALSE,
      sanitize.text.function = identity,
      booktabs = TRUE)
cat("Saved tableA1_alt_shocks.tex\n")

## ============================================================
## Table A2: Placebo shocks
## ============================================================

cat("--- Table A2: Placebo shocks ---\n")

placebos <- fread(file.path(DATA_DIR, "placebo_results.csv"))
placebos[, placebo_date := as.character(placebo_date)]
## Placebo sample sizes: pre-shock placebos use ym < 2008-09-01 (5180 obs)
## Post-recovery placebo uses ym >= 2010-01-01 (2220 obs)
plac_n <- c("5,180", "5,180", "2,220")
plac_latex <- placebos[, .(
  `Placebo Date` = format(as.Date(placebo_date), "%b %Y"),
  N = plac_n,
  Estimate = sprintf("%.4f", estimate),
  SE = sprintf("%.4f", se),
  `p-value` = sprintf("%.4f", pvalue),
  `95\\% CI` = sprintf("[%.4f, %.4f]", ci_lo, ci_hi)
)]

latex_tabA2 <- xtable(plac_latex,
                      caption = "Placebo Shock Tests (Non-Event Dates)",
                      label = "tab:placebo_shocks")
print(latex_tabA2,
      file = file.path(TABLE_DIR, "tableA2_placebo.tex"),
      include.rownames = FALSE,
      sanitize.text.function = identity,
      booktabs = TRUE)
cat("Saved tableA2_placebo.tex\n")

cat("\nAll tables complete.\n")
