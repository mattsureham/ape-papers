## 05_tables.R — Generate all LaTeX tables for apep_1163

source("00_packages.R")

# --- Load results ---
payments <- readRDS("../data/payments_clean.rds")
thresholds <- read.csv("../data/thresholds.csv")
results_df <- readRDS("../data/results_table.rds")
results <- readRDS("../data/bunching_results.rds")
het_results <- readRDS("../data/het_results.rds")
pooled_est <- readRDS("../data/pooled_est.rds")
robustness <- readRDS("../data/robustness_results.rds")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

summary_stats <- payments[, .(
  N = format(.N, big.mark = ","),
  Mean = sprintf("%.2f", mean(amount)),
  SD = sprintf("%.2f", sd(amount)),
  Median = sprintf("%.2f", median(amount)),
  P10 = sprintf("%.2f", quantile(amount, 0.10)),
  P90 = sprintf("%.2f", quantile(amount, 0.90)),
  Pct_Food = sprintf("%.1f", 100 * mean(payment_type == "Food & Beverage")),
  Threshold = sprintf("$%.2f", threshold[1])
), by = .(Year = program_year)]

tab1_tex <- "\\begin{table}[t]
\\centering
\\caption{Summary Statistics: CMS Open Payments, \\$2--\\$30 Range}
\\label{tab:summary}
\\begin{tabular}{lrrrrrrrc}
\\toprule
Year & N & Mean & SD & Median & P10 & P90 & \\% Food & Threshold \\\\
\\midrule\n"

for (i in 1:nrow(summary_stats)) {
  row <- summary_stats[i]
  tab1_tex <- paste0(tab1_tex, sprintf(
    "%d & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
    row$Year, row$N, row$Mean, row$SD, row$Median, row$P10, row$P90,
    row$Pct_Food, row$Threshold
  ))
}

tab1_tex <- paste0(tab1_tex,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Each row summarizes CMS Open Payments general payment records
with amounts between \\$2 and \\$30 for the indicated program year. \\% Food is the share
classified as Food and Beverage. Threshold is the CPI-indexed per-transaction reporting
minimum published in the Federal Register.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 (Summary Statistics) written.\n")

# ============================================================
# TABLE 2: Bunching Estimates by Year
# ============================================================

tab2_tex <- "\\begin{table}[t]
\\centering
\\caption{Bunching at the Reporting Threshold by Program Year}
\\label{tab:bunching_year}
\\begin{tabular}{lccccc}
\\toprule
Year & Threshold & Excess Mass & $\\hat{b}$ & SE($\\hat{b}$) & Missing Mass \\\\
\\midrule\n"

for (i in 1:nrow(results_df)) {
  row <- results_df[i]
  tab2_tex <- paste0(tab2_tex, sprintf(
    "%d & \\$%.2f & %s & %s & %s & %s \\\\\n",
    row$Year, row$Threshold,
    ifelse(is.na(row$Excess_Mass), "---",
           format(round(row$Excess_Mass), big.mark = ",")),
    ifelse(is.na(row$b_Normalized), "---", sprintf("%.3f", row$b_Normalized)),
    ifelse(is.na(row$SE), "---", sprintf("%.3f", row$SE)),
    ifelse(is.na(row$Missing_Mass), "---",
           format(round(row$Missing_Mass), big.mark = ","))
  ))
}

# Add pooled row
tab2_tex <- paste0(tab2_tex, "\\midrule\n")
tab2_tex <- paste0(tab2_tex, sprintf(
  "Pooled & --- & %s & %s & %s & %s \\\\\n",
  ifelse(is.na(pooled_est$excess_mass), "---",
         format(round(pooled_est$excess_mass), big.mark = ",")),
  ifelse(is.na(pooled_est$b_normalized), "---", sprintf("%.3f", pooled_est$b_normalized)),
  ifelse(is.na(pooled_est$se), "---", sprintf("%.3f", pooled_est$se)),
  ifelse(is.na(pooled_est$missing_mass), "---",
         format(round(pooled_est$missing_mass), big.mark = ","))
))

tab2_tex <- paste0(tab2_tex,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Bunching estimates from a polynomial counterfactual (order 7)
fitted to \\$0.25 bins in [$\\tau - 3$, $\\tau + 3$], excluding the manipulation region
[$\\tau - 1.5$, $\\tau + 0.5$]. $\\hat{b}$ is the normalized excess mass
(excess bunching / counterfactual density at threshold). Standard errors from
200 Poisson bootstrap replications. Pooled estimate centers each year's distribution
on its own threshold before aggregating.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab2_tex, "../tables/tab2_bunching.tex")
cat("Table 2 (Bunching by Year) written.\n")

# ============================================================
# TABLE 3: Heterogeneity by Payment Type
# ============================================================

tab3_tex <- "\\begin{table}[t]
\\centering
\\caption{Bunching Heterogeneity: Food \\& Beverage vs.\\ Other Payment Types}
\\label{tab:het_type}
\\begin{tabular}{lccc}
\\toprule
Payment Type & $\\hat{b}$ & SE($\\hat{b}$) & Share of Records (\\%) \\\\
\\midrule\n"

food_share <- 100 * payments[, mean(payment_type == "Food & Beverage")]
other_share <- 100 - food_share

food_est <- het_results[["Food & Beverage"]]
other_est <- het_results[["Other"]]

tab3_tex <- paste0(tab3_tex, sprintf(
  "Food \\& Beverage & %s & %s & %.1f \\\\\n",
  ifelse(is.na(food_est$b_normalized), "---", sprintf("%.3f", food_est$b_normalized)),
  ifelse(is.na(food_est$se), "---", sprintf("%.3f", food_est$se)),
  food_share
))

tab3_tex <- paste0(tab3_tex, sprintf(
  "All Other Types & %s & %s & %.1f \\\\\n",
  ifelse(is.na(other_est$b_normalized), "---", sprintf("%.3f", other_est$b_normalized)),
  ifelse(is.na(other_est$se), "---", sprintf("%.3f", other_est$se)),
  other_share
))

tab3_tex <- paste0(tab3_tex,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Bunching estimates by payment type, pooled across years.
Food \\& Beverage payments have highly elastic amounts (meals can be sized to any value),
while other types (consulting fees, education, compensation) tend to be set at
negotiated round numbers. Same polynomial specification as Table~\\ref{tab:bunching_year}.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab3_tex, "../tables/tab3_heterogeneity.tex")
cat("Table 3 (Heterogeneity) written.\n")

# ============================================================
# TABLE 4: Robustness Checks
# ============================================================

poly_sens <- robustness$poly_sensitivity
bw_sens <- robustness$bw_sensitivity
excl_sens <- robustness$excl_sensitivity

tab4_tex <- "\\begin{table}[t]
\\centering
\\caption{Robustness of Bunching Estimates}
\\label{tab:robustness}
\\begin{tabular}{llcc}
\\toprule
Specification & Variation & $\\hat{b}$ & SE($\\hat{b}$) \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Polynomial Order}} \\\\
\\addlinespace\n"

for (i in 1:nrow(poly_sens)) {
  tab4_tex <- paste0(tab4_tex, sprintf(
    " & Order %d%s & %s & %s \\\\\n",
    poly_sens$poly_order[i],
    ifelse(poly_sens$poly_order[i] == 7, " (baseline)", ""),
    sprintf("%.3f", poly_sens$b[i]),
    sprintf("%.3f", poly_sens$se[i])
  ))
}

tab4_tex <- paste0(tab4_tex, "\\addlinespace\n\\multicolumn{4}{l}{\\textit{Panel B: Bandwidth}} \\\\
\\addlinespace\n")

for (i in 1:nrow(bw_sens)) {
  tab4_tex <- paste0(tab4_tex, sprintf(
    " & \\$%d%s & %s & %s \\\\\n",
    bw_sens$bandwidth[i],
    ifelse(bw_sens$bandwidth[i] == 3, " (baseline)", ""),
    sprintf("%.3f", bw_sens$b[i]),
    sprintf("%.3f", bw_sens$se[i])
  ))
}

tab4_tex <- paste0(tab4_tex, "\\addlinespace\n\\multicolumn{4}{l}{\\textit{Panel C: Exclusion Region (below threshold)}} \\\\
\\addlinespace\n")

for (i in 1:nrow(excl_sens)) {
  tab4_tex <- paste0(tab4_tex, sprintf(
    " & \\$%.1f%s & %s & %s \\\\\n",
    excl_sens$excl_below[i],
    ifelse(excl_sens$excl_below[i] == 1.5, " (baseline)", ""),
    sprintf("%.3f", excl_sens$b[i]),
    sprintf("%.3f", excl_sens$se[i])
  ))
}

tab4_tex <- paste0(tab4_tex,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Sensitivity of the pooled bunching estimate to polynomial order
(Panel A), analysis bandwidth (Panel B), and the width of the excluded manipulation
region below the threshold (Panel C). Baseline specification: 7th-order polynomial,
\\$3 bandwidth, exclusion [$\\tau - 1.5$, $\\tau + 0.5$].
\\end{tablenotes}
\\end{table}\n")

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("Table 4 (Robustness) written.\n")

# ============================================================
# TABLE 5: Placebo Tests
# ============================================================

placebo <- robustness$placebo_results
prior_yr_placebo <- robustness$prior_year_placebo

tab5_tex <- "\\begin{table}[t]
\\centering
\\caption{Placebo Tests: Bunching at Non-Threshold Amounts}
\\label{tab:placebo}
\\begin{tabular}{llcc}
\\toprule
Test & Description & $\\hat{b}$ & SE($\\hat{b}$) \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Round-Number Placebos}} \\\\
\\addlinespace\n"

if (nrow(placebo) > 0) {
  for (i in 1:nrow(placebo)) {
    tab5_tex <- paste0(tab5_tex, sprintf(
      " & \\$%d & %s & %s \\\\\n",
      placebo$placebo[i],
      ifelse(is.na(placebo$b[i]), "---", sprintf("%.3f", placebo$b[i])),
      ifelse(is.na(placebo$se[i]), "---", sprintf("%.3f", placebo$se[i]))
    ))
  }
}

tab5_tex <- paste0(tab5_tex, "\\addlinespace\n\\multicolumn{4}{l}{\\textit{Panel B: Prior-Year Threshold Placebos}} \\\\
\\addlinespace\n")

if (nrow(prior_yr_placebo) > 0) {
  for (i in 1:nrow(prior_yr_placebo)) {
    tab5_tex <- paste0(tab5_tex, sprintf(
      " & %d at \\$%.2f & %s & %s \\\\\n",
      prior_yr_placebo$year[i],
      prior_yr_placebo$tested_at[i],
      ifelse(is.na(prior_yr_placebo$b[i]), "---", sprintf("%.3f", prior_yr_placebo$b[i])),
      ifelse(is.na(prior_yr_placebo$se[i]), "---", sprintf("%.3f", prior_yr_placebo$se[i]))
    ))
  }
}

tab5_tex <- paste0(tab5_tex,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Panel A tests for bunching at round-dollar amounts that are not
reporting thresholds. Panel B tests for bunching in year $t$ at year $t-1$'s threshold
(which no longer governs reporting). If bunching reflects strategic disclosure avoidance,
it should track the current threshold, not prior thresholds or arbitrary round numbers.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab5_tex, "../tables/tab5_placebo.tex")
cat("Table 5 (Placebos) written.\n")

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================

# Compute SDE for main bunching estimate
# SDE = b_normalized (already in SD units by construction)
# For bunching: b = excess_mass / counterfactual_density
# This is the intensive margin analogue of an SDE

# Pooled estimate
b_pooled <- pooled_est$b_normalized
se_pooled <- pooled_est$se

# SD of amount distribution (for alternative SDE computation)
sd_y <- payments[, sd(amount)]

# Food & Beverage
b_food <- het_results[["Food & Beverage"]]$b_normalized
se_food <- het_results[["Food & Beverage"]]$se

# Other types
b_other <- het_results[["Other"]]$b_normalized
se_other <- het_results[["Other"]]$se

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Build SDE table
sde_rows <- list(
  list("Pooled (all types)", b_pooled, se_pooled),
  list("Food \\& Beverage only", b_food, se_food),
  list("Non-food types", b_other, se_other)
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does pharmaceutical manufacturer disclosure avoidance at CMS Open Payments ",
  "per-transaction reporting thresholds distort the distribution of physician payments? ",
  "\\textbf{Policy mechanism:} The Physician Payments Sunshine Act (ACA Section 6002) requires manufacturers ",
  "to publicly report individual payments to physicians exceeding a CPI-indexed per-transaction minimum; ",
  "payments below are exempt unless the annual aggregate exceeds a separate threshold, creating an incentive ",
  "to keep individual payment amounts just below the per-transaction cutoff. ",
  "\\textbf{Outcome definition:} Normalized excess mass ($\\hat{b}$) of the payment amount distribution ",
  "just below the reporting threshold, measuring the share of payments shifted below the cutoff relative ",
  "to the counterfactual density. ",
  "\\textbf{Treatment:} Binary: payment subject to per-transaction reporting threshold (CPI-adjusted, ",
  "\\$10.42 in 2018 to \\$12.70 in 2024). ",
  "\\textbf{Data:} CMS Open Payments General Payment Data, 2018--2024, individual payment-level, ",
  "payments in \\$2--\\$30 range. ",
  "\\textbf{Method:} Polynomial bunching estimator (order 7) with Poisson bootstrap standard errors ",
  "(200 replications); exclusion region [threshold $-$ \\$1.50, threshold $+$ \\$0.50]. ",
  "\\textbf{Sample:} General (non-research, non-ownership) payments in the \\$2--\\$30 range; ",
  "excludes payments above \\$30 and below \\$2. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- "\\begin{table}[t]
\\centering
\\caption{Standardized Disclosure Avoidance Estimates}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{b}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
\\addlinespace\n"

# Panel A: Pooled
row <- sde_rows[[1]]
sde_val <- ifelse(is.na(row[[2]]), NA, row[[2]])
se_sde <- ifelse(is.na(row[[3]]), NA, row[[3]])
tabF1_tex <- paste0(tabF1_tex, sprintf(
  "%s & %s & %s & %.2f & %s & %s & %s \\\\\n",
  row[[1]],
  ifelse(is.na(row[[2]]), "---", sprintf("%.3f", row[[2]])),
  ifelse(is.na(row[[3]]), "---", sprintf("%.3f", row[[3]])),
  sd_y,
  ifelse(is.na(sde_val), "---", sprintf("%.3f", sde_val)),
  ifelse(is.na(se_sde), "---", sprintf("%.3f", se_sde)),
  classify_sde(sde_val)
))

tabF1_tex <- paste0(tabF1_tex, "\\addlinespace\n\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\
\\addlinespace\n")

# Panel B: Heterogeneous
for (k in 2:3) {
  row <- sde_rows[[k]]
  sde_val <- ifelse(is.na(row[[2]]), NA, row[[2]])
  se_sde <- ifelse(is.na(row[[3]]), NA, row[[3]])
  tabF1_tex <- paste0(tabF1_tex, sprintf(
    "%s & %s & %s & %.2f & %s & %s & %s \\\\\n",
    row[[1]],
    ifelse(is.na(row[[2]]), "---", sprintf("%.3f", row[[2]])),
    ifelse(is.na(row[[3]]), "---", sprintf("%.3f", row[[3]])),
    sd_y,
    ifelse(is.na(sde_val), "---", sprintf("%.3f", sde_val)),
    ifelse(is.na(se_sde), "---", sprintf("%.3f", se_sde)),
    classify_sde(sde_val)
  ))
}

tabF1_tex <- paste0(tabF1_tex, sprintf(
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}
%s
\\end{tablenotes}
\\end{table}\n", sde_notes))

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
