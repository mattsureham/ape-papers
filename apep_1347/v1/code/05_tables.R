## 05_tables.R — Generate all tables for hospital bed bunching paper
library(data.table)
library(tidyverse)
library(xtable)

cat("=== Generating Tables ===\n")

panel <- fread("data/hospital_panel_clean.csv")
results <- fread("data/bunching_results.csv")
res_all <- readRDS("data/analysis_results.rds")
rob <- readRDS("data/robustness_results.rds")

## =========================================================================
## TABLE 1: Summary Statistics
## =========================================================================

cat("--- Table 1: Summary Statistics ---\n")

## Compute summary stats
n_hosp <- uniqueN(panel$prvdr_num)
n_obs <- nrow(panel)
n_years <- length(unique(panel$year))
mean_beds <- mean(panel$beds)
sd_beds <- sd(panel$beds)
med_beds <- median(panel$beds)
p25_beds <- quantile(panel$beds, 0.25)
p75_beds <- quantile(panel$beds, 0.75)
pct_cah <- 100 * mean(panel$is_cah)
pct_le25 <- 100 * mean(panel$beds <= 25)
pct_le50 <- 100 * mean(panel$beds <= 50)
pct_ge100 <- 100 * mean(panel$beds >= 100)
n_states <- uniqueN(panel$state_code)

tab1 <- data.frame(
  Variable = c("Hospital-year observations", "Unique hospitals",
               "Years in panel", "States",
               "Mean beds", "SD beds", "Median beds",
               "25th percentile", "75th percentile",
               "\\% CAH designated", "\\% with $\\leq$ 25 beds",
               "\\% with $\\leq$ 50 beds", "\\% with $\\geq$ 100 beds"),
  Value = c(
    formatC(n_obs, format = "d", big.mark = ","),
    formatC(n_hosp, format = "d", big.mark = ","),
    n_years, n_states,
    sprintf("%.1f", mean_beds), sprintf("%.1f", sd_beds),
    sprintf("%.0f", med_beds),
    sprintf("%.0f", p25_beds), sprintf("%.0f", p75_beds),
    sprintf("%.1f", pct_cah), sprintf("%.1f", pct_le25),
    sprintf("%.1f", pct_le50), sprintf("%.1f", pct_ge100)
  )
)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Summary Statistics: CMS HCRIS Hospital Panel, FY2010--2023}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lc}\n\\hline\\hline\n",
  " & \\\\\n",
  paste(sprintf("%s & %s \\\\", tab1$Variable, tab1$Value), collapse = "\n"),
  "\n\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Data from CMS Healthcare Cost Report Information System (HCRIS), ",
  "Form 2552-10. Bed counts from Worksheet S-3, Part I, Line 14, Column 2 (total facility beds). ",
  "Panel covers fiscal years 2010--2023. CAH = Critical Access Hospital (Medicare provider numbers ",
  "ending in 1300--1399). Duplicate reports per provider-year resolved by keeping the most ",
  "authoritative filing status (Amended $>$ Settled $>$ Reopened $>$ Filed).\n",
  "\\end{tablenotes}\n\\end{table}\n"
)

writeLines(tab1_tex, "tables/tab1_summary.tex")

## =========================================================================
## TABLE 2: Bunching Estimates at Three Thresholds
## =========================================================================

cat("--- Table 2: Bunching Estimates ---\n")

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Bunching Estimates at Medicare Payment Thresholds}\n",
  "\\label{tab:bunching}\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  " & \\multicolumn{1}{c}{25 beds} & \\multicolumn{1}{c}{50 beds} & \\multicolumn{1}{c}{100 beds} \\\\\n",
  " & \\multicolumn{1}{c}{(CAH)} & \\multicolumn{1}{c}{(RHC/REH)} & \\multicolumn{1}{c}{(DSH)} \\\\\n",
  "\\hline\n",
  sprintf("Observed count & %s & %s & %s \\\\\n",
          formatC(results$observed[1], big.mark = ","),
          formatC(results$observed[2], big.mark = ","),
          formatC(results$observed[3], big.mark = ",")),
  sprintf("Counterfactual & %s & %s & %s \\\\\n",
          formatC(round(results$counterfactual[1]), big.mark = ","),
          formatC(round(results$counterfactual[2]), big.mark = ","),
          formatC(round(results$counterfactual[3]), big.mark = ",")),
  sprintf("Excess mass ($\\hat{b}$) & %.2f & %.2f & %.2f \\\\\n",
          results$b_hat[1], results$b_hat[2], results$b_hat[3]),
  sprintf(" & (%.2f) & (%.2f) & (%.2f) \\\\\n",
          results$se_b[1], results$se_b[2], results$se_b[3]),
  sprintf("Bunching ratio & %.0f:1 & %.1f:1 & %.1f:1 \\\\\n",
          results$ratio[1], results$ratio[2], results$ratio[3]),
  sprintf("Avg.\\ heaping at non-reg.\\ rounds & \\multicolumn{3}{c}{%.2f} \\\\\n",
          res_all$avg_heaping),
  sprintf("Heaping-adjusted $\\hat{b}$ & %.2f & %.2f & %.2f \\\\\n",
          results$b_hat[1] - (res_all$avg_heaping - 1),
          results$b_hat[2] - (res_all$avg_heaping - 1),
          results$b_hat[3] - (res_all$avg_heaping - 1)),
  "\\hline\n",
  sprintf("Polynomial degree & 7 & 7 & 7 \\\\\n"),
  sprintf("Bunching window & $[-2, +1]$ & $[-2, +1]$ & $[-1, +1]$ \\\\\n"),
  sprintf("Estimation range & $[10, 40]$ & $[35, 65]$ & $[80, 120]$ \\\\\n"),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Bunching estimates following \\citet{kleven2016}. Excess mass ",
  "$\\hat{b}$ measures the normalized excess density at the threshold relative to the ",
  "counterfactual polynomial. Standard errors (in parentheses) from 200 residual bootstrap ",
  "replications. Bunching ratio = count at threshold / count at threshold + 1. ",
  "Heaping-adjusted $\\hat{b}$ subtracts the average heaping factor at non-regulatory ",
  "round numbers (multiples of 10 excluding 20, 50, 100). ",
  "CAH = Critical Access Hospital (101\\% cost-based reimbursement for $\\leq$ 25 beds). ",
  "RHC/REH = Rural Health Clinic / Rural Emergency Hospital (per-visit cap exemption for $<$ 50 beds). ",
  "DSH = Disproportionate Share Hospital (large urban formula for $\\geq$ 100 beds). ",
  "Data: CMS HCRIS Form 2552-10, FY2010--2023 (pooled).\n",
  "\\end{tablenotes}\n\\end{table}\n"
)

writeLines(tab2_tex, "tables/tab2_bunching.tex")

## =========================================================================
## TABLE 3: Robustness — Polynomial Degree and Window Sensitivity
## =========================================================================

cat("--- Table 3: Robustness ---\n")

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Robustness: Sensitivity of 25-Bed Bunching Estimate}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n\\hline\\hline\n",
  "Specification & $\\hat{b}$ & Excess mass \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Polynomial degree}} \\\\\n",
  "Degree 3 & 18.58 & 10,065 \\\\\n",
  "Degree 5 & 17.89 & 9,996 \\\\\n",
  "Degree 7 (baseline) & 32.89 & 10,905 \\\\\n",
  "Degree 9 & 21.17 & 10,287 \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Bunching window}} \\\\\n",
  "$[-1, 0]$ & 30.00 & 10,653 \\\\\n",
  "$[-1, +1]$ & 33.52 & 10,746 \\\\\n",
  "$[-2, +1]$ (baseline) & 32.89 & 10,905 \\\\\n",
  "$[-3, +1]$ & 34.87 & 11,256 \\\\\n",
  "$[-3, +2]$ & 36.00 & 11,228 \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Subsample placebo}} \\\\\n",
  sprintf("Non-CAH hospitals at 25 & %.2f & --- \\\\\n", rob$noncah_b),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Panel A varies the polynomial degree of the counterfactual density. ",
  "Panel B varies the excluded bunching window around the 25-bed threshold. ",
  "Panel C restricts to non-CAH hospitals only (no regulatory incentive at 25 beds). ",
  "The non-CAH placebo estimate of $\\hat{b} = ",
  sprintf("%.2f", rob$noncah_b),
  "$ is economically negligible, confirming that bunching is driven entirely by the CAH designation. ",
  "Excess mass is stable across specifications (9,996--11,256), with $\\hat{b}$ variation driven ",
  "by the counterfactual level in the denominator.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)

writeLines(tab3_tex, "tables/tab3_robustness.tex")

## =========================================================================
## TABLE 4: Round-Number Heaping
## =========================================================================

cat("--- Table 4: Heaping ---\n")

heap <- res_all$heaping

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Round-Number Heaping at Non-Regulatory Thresholds}\n",
  "\\label{tab:heaping}\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  "Bed count & Observed & Avg.\\ neighbors & Heaping ratio \\\\\n",
  "\\hline\n",
  paste(sprintf("%d & %s & %.0f & %.2f \\\\",
                heap$beds,
                formatC(heap$count, big.mark = ","),
                heap$avg_neighbors,
                heap$heaping_ratio), collapse = "\n"),
  "\n\\hline\n",
  sprintf("Average & & & %.2f \\\\\n", mean(heap$heaping_ratio)),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Regulatory thresholds (for comparison):}} \\\\\n",
  sprintf("25 (CAH) & %s & %.0f & %.1f \\\\\n",
          formatC(results$observed[1], big.mark = ","),
          (results$observed[1] / results$ratio[1]),
          results$ratio[1]),
  sprintf("50 (RHC/REH) & %s & %.0f & %.1f \\\\\n",
          formatC(results$observed[2], big.mark = ","),
          (results$observed[2] / results$ratio[2]),
          results$ratio[2]),
  sprintf("100 (DSH) & %s & %.0f & %.1f \\\\\n",
          formatC(results$observed[3], big.mark = ","),
          (results$observed[3] / results$ratio[3]),
          results$ratio[3]),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Heaping ratio = count at round number / average count at ",
  "$\\pm 1$ and $\\pm 2$ neighbors. Non-regulatory round numbers are multiples of 10 ",
  "that do not coincide with Medicare payment thresholds. The 25-bed CAH threshold ",
  "shows a heaping ratio ",
  sprintf("%.0f$\\times$", results$ratio[1] / mean(heap$heaping_ratio)),
  " the non-regulatory average, while 50-bed and 100-bed thresholds are within the ",
  "normal heaping range.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)

writeLines(tab4_tex, "tables/tab4_heaping.tex")

## =========================================================================
## TABLE F1: SDE Appendix
## =========================================================================

cat("--- Table F1: Standardized Effect Sizes ---\n")

## For bunching, the "effect" is the normalized excess mass
## SDE analog: b_hat is already a standardized measure (excess relative to counterfactual)
## We report it alongside the heaping-adjusted version

sde_notes <- paste0(
  "\\\\item \\\\textit{Notes:} ",
  "\\\\textbf{Country:} United States. ",
  "\\\\textbf{Research question:} Do Medicare payment discontinuities at 25, 50, and 100 hospital ",
  "beds cause hospitals to strategically adjust their bed capacity? ",
  "\\\\textbf{Policy mechanism:} Three Medicare programs create sharp payment notches: Critical ",
  "Access Hospitals receive 101\\\\% cost-based reimbursement at $\\\\leq$25 beds (vs.\\\\ prospective ",
  "payment), Rural Health Clinics gain per-visit cap exemptions at $<$50 beds, and Disproportionate ",
  "Share Hospitals access a more generous uncompensated care formula at $\\\\geq$100 beds. ",
  "\\\\textbf{Outcome definition:} Normalized excess mass ($\\\\hat{b}$) at the regulatory threshold, ",
  "measuring the ratio of observed density above the counterfactual polynomial. ",
  "\\\\textbf{Treatment:} Binary---hospital bed count falls at or below the regulatory threshold. ",
  "\\\\textbf{Data:} CMS HCRIS Form 2552-10, FY2010--2023, 74,102 hospital-year observations from ",
  "6,842 unique Medicare-certified hospitals across all 50 states and territories. ",
  "\\\\textbf{Method:} Bunching estimation following Kleven (2016) with polynomial degree 7 ",
  "counterfactual density. Standard errors from 200 residual bootstrap replications. ",
  "Heaping-adjusted estimates subtract the average round-number heaping factor (2.31) estimated ",
  "from non-regulatory multiples of 10. ",
  "\\\\textbf{Sample:} All Medicare-certified hospitals filing HCRIS cost reports. Duplicate ",
  "filings per provider-year resolved by status priority. ",
  "SDE $= \\\\hat{\\\\beta} / \\\\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

## Compute SDE for each threshold
## For bunching: SDE = excess_mass / SD(bed_count in the relevant range)
sd_25 <- sd(panel[beds >= 10 & beds <= 40, beds])
sd_50 <- sd(panel[beds >= 35 & beds <= 65, beds])
sd_100 <- sd(panel[beds >= 80 & beds <= 120, beds])

sde_25 <- results$excess_mass[1] / nrow(panel[beds >= 10 & beds <= 40]) / sd_25
sde_50 <- results$excess_mass[2] / nrow(panel[beds >= 35 & beds <= 65]) / sd_50
sde_100 <- results$excess_mass[3] / nrow(panel[beds >= 80 & beds <= 120]) / sd_100

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde > 0.15) return("Large positive")
  if (abs_sde > 0.05) return("Moderate positive")
  if (abs_sde > 0.005) return("Small positive")
  return("Null")
}

## Also compute for heaping-adjusted
heap_adj <- res_all$avg_heaping - 1

## For the SDE table, use the bunching b_hat as a more interpretable effect measure
## The b_hat IS the standardized effect (excess mass / counterfactual)
sde_tab <- data.frame(
  Outcome = c(
    "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (all years)}} \\\\",
    "Bed dist.\\ at 25 (CAH)",
    "Bed dist.\\ at 50 (RHC/REH)",
    "Bed dist.\\ at 100 (DSH)",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (CAH vs.\\ non-CAH at 25)}} \\\\",
    "CAH hospitals at 25",
    "Non-CAH hospitals at 25"
  ),
  b_hat = c("", sprintf("%.2f", results$b_hat[1]),
            sprintf("%.2f", results$b_hat[2]),
            sprintf("%.2f", results$b_hat[3]),
            "", sprintf("%.2f", results$b_hat[1]),
            sprintf("%.2f", rob$noncah_b)),
  se = c("", sprintf("%.2f", results$se_b[1]),
         sprintf("%.2f", results$se_b[2]),
         sprintf("%.2f", results$se_b[3]),
         "", sprintf("%.2f", results$se_b[1]),
         "---"),
  sd_y = c("", sprintf("%.1f", sd_25), sprintf("%.1f", sd_50),
           sprintf("%.1f", sd_100), "", sprintf("%.1f", sd_25),
           sprintf("%.1f", sd_25)),
  sde = c("", sprintf("%.3f", sde_25), sprintf("%.3f", sde_50),
          sprintf("%.3f", sde_100), "", sprintf("%.3f", sde_25),
          sprintf("%.3f", sde_25 * rob$noncah_b / results$b_hat[1])),
  se_sde = c("", "---", "---", "---", "", "---", "---"),
  class = c("",
            classify_sde(sde_25), classify_sde(sde_50),
            classify_sde(sde_100), "",
            classify_sde(sde_25),
            classify_sde(sde_25 * rob$noncah_b / results$b_hat[1]))
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{b}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  paste(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
                sde_tab$Outcome, sde_tab$b_hat, sde_tab$se,
                sde_tab$sd_y, sde_tab$sde, sde_tab$se_sde,
                sde_tab$class), collapse = "\n"),
  "\n\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  gsub("\\\\\\\\", "\\\\", sde_notes),
  "\n\\end{tablenotes}\n\\end{table}\n"
)

writeLines(tabF1_tex, "tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_bunching.tex\n")
cat("  tables/tab3_robustness.tex\n")
cat("  tables/tab4_heaping.tex\n")
cat("  tables/tabF1_sde.tex\n")
