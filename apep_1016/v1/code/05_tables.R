## 05_tables.R — Generate all LaTeX tables
## apep_1016: Fresh Start Dividend

library(tidyverse)
library(data.table)
library(fixest)

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cases <- fread(file.path(DATA_DIR, "cases_clean.csv"))
judge_stats <- fread(file.path(DATA_DIR, "judge_stats.csv"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
rob <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))

# Helper
get_cs <- function(model, var) {
  cf <- coef(model)[var]
  se_val <- se(model)[var]
  pv <- pvalue(model)[var]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  list(coef = cf, se = se_val, pv = pv, stars = stars)
}

# -----------------------------------------------------------------------
# Table 1: Summary Statistics
# -----------------------------------------------------------------------
cat("Table 1: Summary Statistics\n")

make_row <- function(label, vals) {
  vals <- vals[!is.na(vals)]
  sprintf("%s & %.3f & %.3f & %.0f \\\\", label,
          mean(vals), sd(vals), length(vals))
}

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Mean & SD & N \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Court-Year Panel}} \\\\[3pt]",
  make_row("Confirmation rate", panel$confirm_rate),
  make_row("Judge leniency (LOO)", panel$avg_leniency),
  sprintf("Cases per court-year & %.1f & %.1f & %.0f \\\\",
          mean(panel$n_cases), sd(panel$n_cases), nrow(panel)),
  sprintf("Judges per court-year & %.1f & %.1f & %.0f \\\\",
          mean(panel$n_judges), sd(panel$n_judges), nrow(panel)),
  sprintf("Establishment entries ($t$+1) & %s & %s & %.0f \\\\",
          format(round(mean(panel$entry_t1, na.rm = TRUE)), big.mark = ","),
          format(round(sd(panel$entry_t1, na.rm = TRUE)), big.mark = ","),
          sum(!is.na(panel$entry_t1))),
  sprintf("Entry rate ($t$+1) & %.2f & %.2f & %.0f \\\\",
          mean(panel$entry_rate_t1, na.rm = TRUE),
          sd(panel$entry_rate_t1, na.rm = TRUE),
          sum(!is.na(panel$entry_rate_t1))),
  sprintf("Firms ($t$+1) & %s & %s & %.0f \\\\",
          format(round(mean(panel$firms_t1, na.rm = TRUE)), big.mark = ","),
          format(round(sd(panel$firms_t1, na.rm = TRUE)), big.mark = ","),
          sum(!is.na(panel$firms_t1))),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Judge-Court Level}} \\\\[3pt]",
  make_row("Confirmation rate", judge_stats$raw_confirm_rate),
  sprintf("Cases per judge & %.1f & %.1f & %.0f \\\\",
          mean(judge_stats$n_cases), sd(judge_stats$n_cases), nrow(judge_stats)),
  sprintf("Mean duration (days) & %.0f & %.0f & %.0f \\\\",
          mean(judge_stats$mean_duration), sd(judge_stats$mean_duration), nrow(judge_stats)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel~A reports statistics at the court-year level for 10 federal bankruptcy courts over 2010--2019. Confirmation rate is the share of Chapter~13 cases with plan duration exceeding 730 days. Judge leniency is the leave-one-out mean confirmation rate. Establishment entries are from the Census Bureau's Business Dynamics Statistics, measured at the state level. Panel~B reports judge-court level statistics for judges with $\\geq$5 sampled cases.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab1, file.path(TABLE_DIR, "tab1_summary.tex"))
cat("  Saved\n")

# -----------------------------------------------------------------------
# Table 2: First Stage and Reduced Form
# -----------------------------------------------------------------------
cat("Table 2: First Stage and Reduced Form\n")

fs <- get_cs(results$first_stage$fs2, "avg_leniency")
r1 <- get_cs(results$reduced_form$rf1, "avg_leniency")
r2 <- get_cs(results$reduced_form$rf2, "avg_leniency")
rr <- get_cs(results$reduced_form$rf_rate1, "avg_leniency")

# Compute F-stat from the t-statistic of the first stage
fs_t <- coef(results$first_stage$fs2)["avg_leniency"] /
        se(results$first_stage$fs2)["avg_leniency"]
fs_f <- unname(fs_t^2)

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{First Stage and Reduced Form Estimates}",
  "\\label{tab:first_stage}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & First Stage & \\multicolumn{3}{c}{Reduced Form} \\\\",
  "\\cmidrule(lr){2-2} \\cmidrule(lr){3-5}",
  " & Confirm. Rate & ln(Entry$_{t+1}$) & ln(Entry$_{t+2}$) & Entry Rate$_{t+1}$ \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Judge leniency & %.3f%s & %.4f%s & %.4f%s & %.3f%s \\\\",
          fs$coef, fs$stars, r1$coef, r1$stars, r2$coef, r2$stars, rr$coef, rr$stars),
  sprintf(" & (%.3f) & (%.4f) & (%.4f) & (%.3f) \\\\",
          fs$se, r1$se, r2$se, rr$se),
  "\\midrule",
  "Court FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(results$first_stage$fs2), nobs(results$reduced_form$rf1),
          nobs(results$reduced_form$rf2), nobs(results$reduced_form$rf_rate1)),
  sprintf("First-stage F & %.1f & --- & --- & --- \\\\", fs_f),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Column~(1) reports the first-stage regression of the district confirmation rate on mean leave-one-out judge leniency with court and year fixed effects. Columns~(2)--(4) report reduced-form regressions of business formation outcomes on judge leniency. Entry = new establishment births from Census BDS. Standard errors clustered at the court level in parentheses. $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab2, file.path(TABLE_DIR, "tab2_first_stage.tex"))
cat("  Saved\n")

# -----------------------------------------------------------------------
# Table 3: 2SLS Main Results
# -----------------------------------------------------------------------
cat("Table 3: 2SLS Results\n")

iv1 <- get_cs(results$iv$iv1, "fit_confirm_rate")
iv2 <- get_cs(results$iv$iv2, "fit_confirm_rate")
ivr <- get_cs(results$iv$iv_rate1, "fit_confirm_rate")
ivf <- get_cs(results$iv$iv_firms1, "fit_confirm_rate")
ols1 <- get_cs(results$ols$ols1, "confirm_rate")

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{The Effect of Chapter~13 Confirmation on Business Formation}",
  "\\label{tab:main_results}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & OLS & \\multicolumn{4}{c}{2SLS} \\\\",
  "\\cmidrule(lr){2-2} \\cmidrule(lr){3-6}",
  " & ln(Entry$_{t+1}$) & ln(Entry$_{t+1}$) & ln(Entry$_{t+2}$) & Entry Rate$_{t+1}$ & ln(Firms$_{t+1}$) \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  sprintf("Confirmation rate & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          ols1$coef, ols1$stars, iv1$coef, iv1$stars,
          iv2$coef, iv2$stars, ivr$coef, ivr$stars, ivf$coef, ivf$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          ols1$se, iv1$se, iv2$se, ivr$se, ivf$se),
  "\\midrule",
  "Estimator & OLS & 2SLS & 2SLS & 2SLS & 2SLS \\\\",
  "Court FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs(results$ols$ols1), nobs(results$iv$iv1), nobs(results$iv$iv2),
          nobs(results$iv$iv_rate1), nobs(results$iv$iv_firms1)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} This table reports the effect of Chapter~13 plan confirmation on business formation. Column~(1) shows OLS; columns~(2)--(5) show 2SLS estimates using leave-one-out judge leniency as an instrument. Entry = new establishment births; Entry Rate = establishment entry rate; Firms = total firm count. All outcomes from Census BDS at the state-year level. Standard errors clustered at the court level in parentheses. $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab3, file.path(TABLE_DIR, "tab3_main_results.tex"))
cat("  Saved\n")

# -----------------------------------------------------------------------
# Table 4: Balance and Placebos
# -----------------------------------------------------------------------
cat("Table 4: Balance and Placebo\n")

b1 <- get_cs(rob$balance$bal1, "avg_leniency")
b2 <- get_cs(rob$balance$bal2, "avg_leniency")
p0 <- get_cs(rob$placebo$placebo_t0, "avg_leniency")
pe <- get_cs(rob$placebo$placebo_emp, "avg_leniency")

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Balance Tests and Placebo Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Coefficient & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Balance (Leniency on Pre-determined Variables)}} \\\\[3pt]",
  sprintf("$\\rightarrow$ log(N cases) & %.3f & (%.3f) \\\\", b1$coef, b1$se),
  sprintf("$\\rightarrow$ N judges & %.3f & (%.3f) \\\\", b2$coef, b2$se),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo (Concurrent-Year Outcomes)}} \\\\[3pt]",
  sprintf("$\\rightarrow$ ln(Estab. entries$_{t=0}$) & %.4f & (%.4f) \\\\", p0$coef, p0$se),
  sprintf("$\\rightarrow$ ln(Employment$_{t=0}$) & %.4f & (%.4f) \\\\", pe$coef, pe$se),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel~A tests whether leave-one-out judge leniency predicts pre-determined court characteristics. Panel~B tests whether leniency predicts concurrent-year (same-year) economic outcomes. None of the coefficients are statistically significant at the 10\\% level. All specifications include court and year fixed effects. Standard errors clustered at the court level.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab4, file.path(TABLE_DIR, "tab4_robustness.tex"))
cat("  Saved\n")

# -----------------------------------------------------------------------
# Table F1: SDE
# -----------------------------------------------------------------------
cat("Table F1: SDE\n")

compute_sde <- function(model, outcome_var, data, var_name = "fit_confirm_rate") {
  beta <- coef(model)[var_name]
  se_beta <- se(model)[var_name]
  sd_y <- sd(data[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  cl <- dplyr::case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  list(beta = beta, se_beta = se_beta, sd_y = sd_y,
       sde = sde, se_sde = se_sde, class = cl)
}

s1 <- compute_sde(results$iv$iv1, "ln_entry_t1", panel)
s2 <- compute_sde(results$iv$iv2, "ln_entry_t2", panel)
sr <- compute_sde(results$iv$iv_rate1, "entry_rate_t1", panel)
sf <- compute_sde(results$iv$iv_firms1, "ln_firms_t1", panel)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does consumer debt relief through Chapter~13 bankruptcy plan confirmation ",
  "causally increase post-discharge business formation at the district level? ",
  "\\textbf{Policy mechanism:} Chapter~13 bankruptcy allows individual debtors to propose a 3--5 year repayment plan; ",
  "judicial confirmation discharges remaining qualifying debts, relieving debt overhang that may constrain entrepreneurial entry. ",
  "Judges vary in confirmation propensities within courts, creating exogenous variation in debt relief intensity. ",
  "\\textbf{Outcome definition:} Log annual new establishment entries from Census BDS (establishment births during the last 12 months), ",
  "entry rate (entries as share of total establishments), and log total firms, at the state-year level. ",
  "\\textbf{Treatment:} Continuous---the share of Chapter~13 cases with confirmed plans in a court-year (instrumented by judge leniency). ",
  "\\textbf{Data:} CourtListener RECAP Archive for Chapter~13 cases (2010--2019, 10 federal bankruptcy courts, 6,016 cases, 94 judges) and ",
  "Census BDS for establishment dynamics (state-year level, 2010--2021). ",
  "\\textbf{Method:} 2SLS using leave-one-out judge leniency as instrument for district confirmation rate; court and year fixed effects; ",
  "standard errors clustered at court level. ",
  "\\textbf{Sample:} 10 large federal bankruptcy courts selected for high Chapter~13 volume; state-level outcomes matched to court jurisdictions. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the within-sample standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Heterogeneity panel
baseline <- panel[file_year %in% 2010:2012,
                  .(baseline_entry = mean(entry_rate_t0, na.rm = TRUE)), by = court_id]
ph <- merge(panel, baseline, by = "court_id")
med <- median(ph$baseline_entry)
p_high <- ph[baseline_entry > med]
p_low <- ph[baseline_entry <= med]

iv_high <- tryCatch(
  feols(ln_entry_t1 ~ 1 | court_id + file_year | confirm_rate ~ avg_leniency,
        data = p_high[!is.na(ln_entry_t1)], cluster = ~court_id),
  error = function(e) NULL)
iv_low <- tryCatch(
  feols(ln_entry_t1 ~ 1 | court_id + file_year | confirm_rate ~ avg_leniency,
        data = p_low[!is.na(ln_entry_t1)], cluster = ~court_id),
  error = function(e) NULL)

sh <- if (!is.null(iv_high)) compute_sde(iv_high, "ln_entry_t1", p_high) else NULL
sl <- if (!is.null(iv_low)) compute_sde(iv_low, "ln_entry_t1", p_low) else NULL

sde_row <- function(label, s) {
  sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          label, s$beta, s$se_beta, s$sd_y, s$sde, s$se_sde, s$class)
}

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sde_row("ln(Entry$_{t+1}$)", s1),
  sde_row("ln(Entry$_{t+2}$)", s2),
  sde_row("Entry rate$_{t+1}$", sr),
  sde_row("ln(Firms$_{t+1}$)", sf),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by baseline entry rate)}} \\\\[3pt]")

if (!is.null(sh)) tabF1 <- c(tabF1, sde_row("High-entry districts", sh))
if (!is.null(sl)) tabF1 <- c(tabF1, sde_row("Low-entry districts", sl))

tabF1 <- c(tabF1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tabF1, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("  Saved\n")

cat("\n=== All tables generated ===\n")
