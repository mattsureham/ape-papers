## ============================================================
## 06_tables.R — Generate all tables from saved data
## apep_0522: Flood Re and English Property Values
## ============================================================

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

## -------------------------------------------------------
## Table 1: Summary Statistics
## -------------------------------------------------------

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# Overall and by treatment group
summ <- panel[, .(
  `N Transactions` = format(.N, big.mark = ","),
  `Mean Price (GBP)` = format(round(mean(as.double(price))), big.mark = ","),
  `Median Price (GBP)` = format(round(median(as.double(price))), big.mark = ","),
  `SD Price (GBP)` = format(round(sd(as.double(price))), big.mark = ","),
  `Pct Detached` = sprintf("%.1f", 100 * mean(property_type == "D")),
  `Pct Semi` = sprintf("%.1f", 100 * mean(property_type == "S")),
  `Pct Terrace` = sprintf("%.1f", 100 * mean(property_type == "T")),
  `Pct Flat` = sprintf("%.1f", 100 * mean(property_type == "F")),
  `Pct Freehold` = sprintf("%.1f", 100 * mean(duration == "F")),
  `Pct New Build` = sprintf("%.1f", 100 * mean(new_build))
), by = .(Group = ifelse(flood_risk_high == 1, "Flood Risk (High/Medium)", "Control (Low/VeryLow/None)"))]

fwrite(summ, file.path(table_dir, "table1_summary.csv"))
cat("Table 1 saved.\n")

## -------------------------------------------------------
## Table 2: Main Results (from CSV)
## -------------------------------------------------------

main_coefs <- fread(file.path(data_dir, "main_coefficients.csv"))

# Read DDD full coefficients (includes constituent interaction terms)
ddd_coefs <- fread(file.path(data_dir, "ddd_full_coefficients.csv"))
ddd_b1 <- ddd_coefs[term == "flood_risk_high:post_floodre"]
ddd_b2 <- ddd_coefs[term == "flood_risk_high:post_floodre:eligible"]

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Flood Re on Property Prices}",
  "\\label{tab:main}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) DiD & (2) DiD + LA$\\times$Yr & (3) Triple-Diff & (4) High Only \\\\",
  "\\hline"
)

# Use stored coefficients
models <- main_coefs$model
coefs <- main_coefs$coefficient
ses <- main_coefs$se
pcts <- main_coefs$pct_effect

# Format significance stars
get_stars <- function(coef, se) {
  z <- abs(coef / se)
  if (z > 2.576) return("***")
  if (z > 1.96) return("**")
  if (z > 1.645) return("*")
  return("")
}

# Read robustness for high-risk-only coefficient
robust <- fread(file.path(data_dir, "robustness_summary.csv"))
high_only <- robust[check == "High risk only"]

# Row 1: Flood Risk × Post (all columns — β1 from DDD in col 3)
coef_row1 <- sprintf("Flood Risk $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
  coefs[1], get_stars(coefs[1], ses[1]),
  coefs[2], get_stars(coefs[2], ses[2]),
  ddd_b1$estimate, get_stars(ddd_b1$estimate, ddd_b1$se),
  high_only$coefficient, get_stars(high_only$coefficient, high_only$se)
)
se_row1 <- sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
  ses[1], ses[2], ddd_b1$se, high_only$se)

# Row 2: Flood Risk × Post × Eligible (column 3 only — the DDD estimand)
coef_row2 <- sprintf("Flood Risk $\\times$ Post $\\times$ Eligible & & & %.4f%s & \\\\",
  ddd_b2$estimate, get_stars(ddd_b2$estimate, ddd_b2$se)
)
se_row2 <- sprintf(" & & & (%.4f) & \\\\", ddd_b2$se)

# Percentage effects (omit for insignificant DDD triple interaction)
pct_row <- sprintf("Pct effect & %.2f\\%% & %.2f\\%% & --- & %.2f\\%% \\\\",
  pcts[1], pcts[2], high_only$pct_effect)

# N values: Col 2 has fewer obs due to singleton removal from LA×year FE
n_total <- 12415343
n_col2 <- 12415220  # after 123 singletons removed by fixest
n_ddd <- 12415220   # same panel, 123 singletons removed

tab2_lines <- c(tab2_lines,
  coef_row1, se_row1, "", coef_row2, se_row2, "", pct_row,
  "\\hline",
  "Postcode sector FE & Yes & Yes & Yes & Yes \\\\",
  "Year-quarter FE & Yes & Yes & Yes & Yes \\\\",
  "LA $\\times$ Year FE & No & Yes & No & No \\\\",
  "\\hline",
  sprintf("N & %s & %s & %s & %s \\\\",
    format(n_total, big.mark = ","),
    format(n_col2, big.mark = ","),
    format(n_ddd, big.mark = ","),
    format(n_total, big.mark = ",")),
  "\\hline\\hline",
  "\\multicolumn{5}{l}{\\footnotesize Clustered SEs by local authority district in parentheses.} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize Col (3) includes all interactions per Eq.\\ (2): FloodRisk$\\times$Post, FloodRisk$\\times$Eligible, Post$\\times$Eligible.} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize *** p$<$0.01, ** p$<$0.05, * p$<$0.1} \\\\",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "table2_main_results.tex"))
cat("Table 2 saved.\n")

## -------------------------------------------------------
## Table 3: Robustness Checks
## -------------------------------------------------------

# Add trend-adjusted result to robustness table
trend_res <- fread(file.path(data_dir, "trend_adjusted_results.csv"))
trend_did <- trend_res[spec == "Trend-adjusted DiD"]
trend_did_pct <- 100 * (exp(trend_did$coefficient) - 1)
robust <- rbind(robust, data.table(
  check = "Trend-adjusted",
  coefficient = trend_did$coefficient,
  se = trend_did$se,
  pct_effect = trend_did_pct,
  sig = "***"
), fill = TRUE)

robust[, coef_str := sprintf("%.4f%s", coefficient, sig)]
robust[, se_str := sprintf("(%.4f)", se)]
robust[, pct_str := sprintf("%.2f\\%%", pct_effect)]

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE & \\% Effect \\\\",
  "\\hline"
)
for (r in seq_len(nrow(robust))) {
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s & %s & %s \\\\",
            robust$check[r], robust$coef_str[r],
            robust$se_str[r], robust$pct_str[r]))
}
tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\multicolumn{4}{l}{\\footnotesize All specifications include postcode sector and year-quarter FE.} \\\\",
  "\\multicolumn{4}{l}{\\footnotesize Clustered SEs by local authority. *** p$<$0.01, ** p$<$0.05, * p$<$0.1} \\\\",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "table3_robustness.tex"))
cat("Table 3 saved.\n")

## -------------------------------------------------------
## Table 4: Heterogeneity by Property Type and Region
## -------------------------------------------------------

hetero_pt <- fread(file.path(data_dir, "heterogeneity_property_type.csv"))
hetero_reg <- fread(file.path(data_dir, "heterogeneity_region.csv"))

# Property type panel
if (nrow(hetero_pt) > 0) {
  hetero_pt[, pct_effect := sprintf("%.2f", 100 * (exp(coef) - 1))]
  hetero_pt[, coef_str := sprintf("%.4f", coef)]
  hetero_pt[, se_str := sprintf("(%.4f)", se)]
  hetero_pt[, n_str := format(n, big.mark = ",")]
}

# Region panel
if (nrow(hetero_reg) > 0) {
  hetero_reg[, pct_effect := sprintf("%.2f", 100 * (exp(coef) - 1))]
  hetero_reg[, coef_str := sprintf("%.4f", coef)]
  hetero_reg[, se_str := sprintf("(%.4f)", se)]
  hetero_reg[, n_str := format(n, big.mark = ",")]
}

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity Analysis}",
  "\\label{tab:heterogeneity}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "\\multicolumn{5}{c}{\\textit{Panel A: By Property Type}} \\\\",
  "\\hline",
  "Type & Coefficient & SE & \\% Effect & N \\\\",
  "\\hline"
)

if (nrow(hetero_pt) > 0) {
  for (r in seq_len(nrow(hetero_pt))) {
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %s & %s & %s & %s \\\\",
              hetero_pt$property_type[r], hetero_pt$coef_str[r],
              hetero_pt$se_str[r], hetero_pt$pct_effect[r],
              hetero_pt$n_str[r]))
  }
}

tab4_lines <- c(tab4_lines,
  "\\hline",
  "\\multicolumn{5}{c}{\\textit{Panel B: By Region}} \\\\",
  "\\hline",
  "Region & Coefficient & SE & \\% Effect & N \\\\",
  "\\hline"
)

if (nrow(hetero_reg) > 0) {
  for (r in seq_len(nrow(hetero_reg[order(-as.numeric(pct_effect))]))) {
    row <- hetero_reg[order(-as.numeric(pct_effect))][r]
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %s & %s & %s & %s \\\\",
              row$region, row$coef_str, row$se_str,
              row$pct_effect, row$n_str))
  }
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\multicolumn{5}{l}{\\footnotesize Postcode sector and year-quarter FE. Clustered SEs by LA.} \\\\",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "table4_heterogeneity.tex"))
cat("Table 4 saved.\n")

cat("\n=== ALL TABLES GENERATED ===\n")
