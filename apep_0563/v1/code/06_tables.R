## ============================================================================
## 06_tables.R — All Table Generation
## Japan Dual-Rate Consumption Tax Paper (apep_0563)
## ============================================================================

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

cpi <- fread(file.path(data_dir, "cpi_analysis.csv"))
cpi[, date := as.Date(date)]
panel <- fread(file.path(data_dir, "cpi_panel.csv"))
summ <- fread(file.path(data_dir, "summary_statistics.csv"))
results <- fread(file.path(data_dir, "main_results.csv"))
bw <- fread(file.path(data_dir, "bandwidth_sensitivity.csv"))

## ============================================================================
## TABLE 1: Summary Statistics
## ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Compute detailed summary stats
pre <- cpi[yyyymm >= 201710 & yyyymm < 201910]
post_clean <- cpi[yyyymm >= 201910 & yyyymm < 202002]
post_full <- cpi[yyyymm >= 201910]

make_row <- function(var_name, label) {
  data.table(
    Variable = label,
    Pre_Mean = sprintf("%.2f", mean(pre[[var_name]])),
    Pre_SD = sprintf("%.2f", sd(pre[[var_name]])),
    Post_Clean_Mean = sprintf("%.2f", mean(post_clean[[var_name]])),
    Post_Full_Mean = sprintf("%.2f", mean(post_full[[var_name]])),
    Diff = sprintf("%.2f", mean(post_clean[[var_name]]) - mean(pre[[var_name]]))
  )
}

tab1 <- rbindlist(list(
  make_row("eating_out", "Eating out CPI"),
  make_row("cooked_food", "Cooked food CPI"),
  make_row("alcoholic_beverages", "Alcoholic beverages CPI"),
  make_row("beverages", "Non-alcoholic beverages CPI"),
  make_row("food", "All food CPI"),
  make_row("all_items", "All items CPI"),
  make_row("relative_eatin_takeout", "Relative price (eat-in/takeout)")
))

fwrite(tab1, file.path(table_dir, "table1_summary.csv"))

# Generate LaTeX
latex1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: CPI Indices by Food Category}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-treatment} & \\multicolumn{2}{c}{Post-treatment} & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Clean & Full & Difference \\\\",
  "\\midrule"
)
for (i in 1:nrow(tab1)) {
  latex1 <- c(latex1, sprintf("%s & %s & %s & %s & %s & %s \\\\",
    tab1$Variable[i], tab1$Pre_Mean[i], tab1$Pre_SD[i],
    tab1$Post_Clean_Mean[i], tab1$Post_Full_Mean[i], tab1$Diff[i]))
}
latex1 <- c(latex1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item Notes: N = ", nrow(pre), " pre-treatment months (Oct 2017--Sep 2019), ",
         nrow(post_clean), " clean post-treatment months (Oct 2019--Jan 2020), ",
         nrow(post_full), " total post-treatment months. ",
         "CPI indices are chain-linked with 2020 base year = 100. ",
         "Source: Japan Statistics Bureau."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)
writeLines(latex1, file.path(table_dir, "table1_summary.tex"))

## ============================================================================
## TABLE 2: Main Results
## ============================================================================
cat("=== Table 2: Main Results ===\n")

# Re-run regressions to get proper output
# Use Newey-West (12 lags) as primary for time-series specifications
cpi[, unit := 1L]
setorder(cpi, yyyymm)

panel_3 <- panel[category %in% c("eating_out", "cooked_food", "alcoholic_beverages")]
panel_3[, category_f := factor(category)]

dd_full <- feols(log_relative_eatin ~ post | month_factor, data = cpi,
                 vcov = NW(12) ~ unit + yyyymm)
cpi_clean <- cpi[yyyymm < 202002 | post == 0]
dd_clean <- feols(log_relative_eatin ~ post | month_factor, data = cpi_clean,
                  vcov = NW(12) ~ unit + yyyymm)
dd_covid <- feols(log_relative_eatin ~ post + covid | month_factor, data = cpi,
                  vcov = NW(12) ~ unit + yyyymm)
# Narrow window: Oct 2017-Jan 2020 (24 months pre + 4 months post = 28)
cpi_narrow <- cpi[yyyymm >= 201710 & yyyymm < 202002]
cpi_narrow[, unit := 1L]
setorder(cpi_narrow, yyyymm)
dd_narrow <- feols(log_relative_eatin ~ post | month_factor, data = cpi_narrow,
                   vcov = NW(12) ~ unit + yyyymm)

# Build LaTeX table manually
benchmark <- log(1.10/1.08)  # 0.01835 log points
make_coef_row <- function(model, var_name, label) {
  b <- coef(model)[var_name]
  se <- sqrt(diag(vcov(model))[var_name])
  p <- 2 * pnorm(-abs(b/se))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  # Test H0: beta = benchmark (full pass-through)
  t_full <- (b - benchmark) / se
  p_full <- 2 * pnorm(-abs(t_full))
  list(label = label, coef = sprintf("%.4f%s", b, stars),
       se = sprintf("(%.4f)", se), n = nobs(model),
       p_full = p_full)
}

r1 <- make_coef_row(dd_full, "post", "Full sample")
r2 <- make_coef_row(dd_clean, "post", "Pre-COVID")
r3 <- make_coef_row(dd_narrow, "post", "Narrow Window")
r4 <- make_coef_row(dd_covid, "post", "COVID control")

# Format p-value for full pass-through test
fmt_p <- function(p) {
  if (p < 0.01) return(sprintf("%.3f", p))
  if (p < 0.10) return(sprintf("%.2f", p))
  return(sprintf("%.2f", p))
}

latex2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Main Results: Differential Tax Pass-Through}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Full Sample & Pre-COVID & Narrow Window & COVID Control \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Differential & %s & %s & %s & %s \\\\", r1$coef, r2$coef, r3$coef, r4$coef),
  sprintf(" & %s & %s & %s & %s \\\\", r1$se, r2$se, r3$se, r4$se),
  "\\\\",
  "Month FE & Yes & Yes & Yes & Yes \\\\",
  "COVID control & No & --- & --- & Yes \\\\",
  sprintf("$p$-value ($H_0{:}\\,\\beta = 0.0183$) & %s & %s & %s & %s \\\\",
          fmt_p(r1$p_full), fmt_p(r2$p_full), fmt_p(r3$p_full), fmt_p(r4$p_full)),
  sprintf("N & %d & %d & %d & %d \\\\", r1$n, r2$n, r3$n, r4$n),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Dependent variable is log(CPI eating out / CPI cooked food). ",
  "Newey-West standard errors (12 lags) in parentheses. ",
  "* p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
  "Post = 1 for months $\\geq$ October 2019. ",
  "Full sample: January 2015--December 2024 ($N = 120$). ",
  "Column (2) restricts to January 2015--January 2020, dropping February 2020 onward ($N = 61$). ",
  "Column (3) uses a narrow window: October 2017--January 2020 ($N = 28$). ",
  "Column (4) includes a COVID indicator for February 2020 onward. ",
  "The row $p(H_0{:}\\,\\beta = 0.0183)$ tests whether the estimate equals the full-pass-through ",
  "benchmark ($\\log(1.10/1.08) = 0.0183$).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}"
)
writeLines(latex2, file.path(table_dir, "table2_main.tex"))

## ============================================================================
## TABLE 3: Robustness — Bandwidth Sensitivity
## ============================================================================
cat("=== Table 3: Bandwidth Sensitivity ===\n")

# Filter out bandwidth=6 (too few degrees of freedom)
bw_valid <- bw[!is.na(se) & bandwidth > 6]

latex3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Bandwidth Sensitivity}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Bandwidth (months) & Estimate & SE & 95\\% CI & N \\\\",
  "\\midrule"
)
for (i in 1:nrow(bw_valid)) {
  p <- 2 * pnorm(-abs(bw_valid$t_stat[i]))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  latex3 <- c(latex3, sprintf("$\\pm$%d & %.4f%s & (%.4f) & [%.4f, %.4f] & %d \\\\",
    bw_valid$bandwidth[i], bw_valid$estimate[i], stars, bw_valid$se[i],
    bw_valid$ci_lower[i], bw_valid$ci_upper[i], bw_valid$n_months[i]))
}
latex3 <- c(latex3,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Each row reports the DD estimate of Post on log(CPI eating out / CPI cooked food) ",
  "using symmetric bandwidths around October 2019. Month fixed effects included. ",
  "HC1 robust standard errors. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
  "$N$ = months in the symmetric window (e.g., $\\pm 12$ around Oct 2019 = Oct 2018--Oct 2020 = 25 months). ",
  "The full sample ($N = 120$, Table 2) uses all available data from Jan 2015--Dec 2024. ",
  "The $\\pm$6 bandwidth is omitted due to insufficient degrees of freedom for month fixed effects.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:bandwidth}",
  "\\end{table}"
)
writeLines(latex3, file.path(table_dir, "table3_bandwidth.tex"))

## ============================================================================
## TABLE 4: Pass-Through Decomposition
## ============================================================================
cat("=== Table 4: Pass-Through ===\n")

magnitude <- fread(file.path(data_dir, "magnitude_decomposition.csv"))

latex4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Tax Pass-Through Decomposition}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Eating Out & Cooked Food & Alcohol & Differential & Pass-Through \\\\",
  " & (10\\%) & (8\\%) & (10\\%) & (Eat-in $-$ Takeout) & Rate \\\\",
  "\\midrule"
)
for (i in 1:nrow(magnitude)) {
  latex4 <- c(latex4, sprintf("%s & %.2f\\%% & %.2f\\%% & %.2f\\%% & %.2f\\%% & %.0f\\%% \\\\",
    magnitude$comparison[i], magnitude$eating_out_pct[i], magnitude$cooked_food_pct[i],
    magnitude$alcohol_pct[i], magnitude$differential_pct[i], magnitude$passthrough_pct[i]))
}
latex4 <- c(latex4,
  "\\midrule",
  "Predicted (full pass-through) & --- & --- & --- & 1.85\\% & 100\\% \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: The predicted differential of 1.85\\% = 2/108 reflects the tax wedge ",
  "between the 10\\% eat-in rate and the 8\\% takeout rate. ",
  "Pass-through rate = observed differential / predicted differential $\\times$ 100.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{adjustbox}",
  "\\label{tab:passthrough}",
  "\\end{table}"
)
writeLines(latex4, file.path(table_dir, "table4_passthrough.tex"))

cat("\n✓ All tables generated.\n")
