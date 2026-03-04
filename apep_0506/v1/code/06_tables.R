## =============================================================================
## 06_tables.R — All tables for the paper
## Paper: Does Candidate Wealth Buy Development?
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir  <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

## =============================================================================
## Load data
## =============================================================================

rdd <- fread(file.path(data_dir, "rdd_analysis.csv"))
rdd[, winner_log_assets := ifelse(rich_won == 1, log_rich_assets, log_poor_assets)]
rdd[, reserved := as.integer(ac_type != "GEN" & ac_type != "")]

## =============================================================================
## Table 1: Summary Statistics
## =============================================================================

cat("Creating Table 1: Summary Statistics\n")

## Panel A: Full sample
summ_full <- data.table(
  Variable = c("Vote margin (%)", "Wealthier candidate won",
               "Rich candidate assets (Rs lakhs)", "Poor candidate assets (Rs lakhs)",
               "Wealth ratio", "Log wealth difference",
               "Rich candidate criminal cases", "Poor candidate criminal cases",
               "Reserved constituency", "Number of states", "Number of elections"),
  Mean = c(round(mean(rdd$rich_margin), 2),
           round(mean(rdd$rich_won), 3),
           round(mean(rdd$rich_assets) / 1e5, 1),
           round(mean(rdd$poor_assets) / 1e5, 1),
           round(mean(rdd$wealth_ratio, na.rm = TRUE), 1),
           round(mean(rdd$log_wealth_diff), 2),
           round(mean(rdd$rich_criminal, na.rm = TRUE), 2),
           round(mean(rdd$poor_criminal, na.rm = TRUE), 2),
           round(mean(rdd$reserved), 3),
           length(unique(rdd$state)),
           length(unique(rdd$year))),
  SD = c(round(sd(rdd$rich_margin), 2),
         round(sd(rdd$rich_won), 3),
         round(sd(rdd$rich_assets) / 1e5, 1),
         round(sd(rdd$poor_assets) / 1e5, 1),
         round(sd(rdd$wealth_ratio, na.rm = TRUE), 1),
         round(sd(rdd$log_wealth_diff), 2),
         round(sd(rdd$rich_criminal, na.rm = TRUE), 2),
         round(sd(rdd$poor_criminal, na.rm = TRUE), 2),
         round(sd(rdd$reserved), 3),
         NA_real_, NA_real_),
  Median = c(round(median(rdd$rich_margin), 2),
             NA_real_,
             round(median(rdd$rich_assets) / 1e5, 1),
             round(median(rdd$poor_assets) / 1e5, 1),
             round(median(rdd$wealth_ratio, na.rm = TRUE), 1),
             round(median(rdd$log_wealth_diff), 2),
             round(median(rdd$rich_criminal, na.rm = TRUE), 2),
             round(median(rdd$poor_criminal, na.rm = TRUE), 2),
             NA_real_, NA_real_, NA_real_),
  N = nrow(rdd)
)

## Panel B: Close elections (|margin| < 5%)
rdd_close <- rdd[abs(rich_margin) < 5]
summ_close <- data.table(
  Variable = c("Vote margin (%)", "Wealthier candidate won",
               "Rich candidate assets (Rs lakhs)", "Poor candidate assets (Rs lakhs)",
               "Wealth ratio"),
  Mean = c(round(mean(rdd_close$rich_margin), 2),
           round(mean(rdd_close$rich_won), 3),
           round(mean(rdd_close$rich_assets) / 1e5, 1),
           round(mean(rdd_close$poor_assets) / 1e5, 1),
           round(mean(rdd_close$wealth_ratio, na.rm = TRUE), 1)),
  N = nrow(rdd_close)
)

## Write LaTeX table
sink(file.path(tab_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & Mean & SD & Median & N \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Full Sample}} \\\\\n")
for (i in 1:nrow(summ_full)) {
  cat(sprintf("%s & %s & %s & %s & %s \\\\\n",
              summ_full$Variable[i],
              ifelse(is.na(summ_full$Mean[i]), "", as.character(summ_full$Mean[i])),
              ifelse(is.na(summ_full$SD[i]), "", as.character(summ_full$SD[i])),
              ifelse(is.na(summ_full$Median[i]), "", as.character(summ_full$Median[i])),
              ifelse(i <= 9, as.character(summ_full$N[i]), "")))
}
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Close Elections ($|$margin$|$ $<$ 5\\%)}} \\\\\n")
for (i in 1:nrow(summ_close)) {
  cat(sprintf("%s & %s & & & %s \\\\\n",
              summ_close$Variable[i],
              as.character(summ_close$Mean[i]),
              ifelse(i == 1, as.character(summ_close$N[i]), "")))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Summary statistics for the RDD analysis sample of constituency-elections where both the top-two vote-getters have affidavit data. The ``wealthier candidate'' is the one with higher total declared assets. Panel B restricts to elections where the absolute vote margin between the top two candidates is within 5 percentage points.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

## =============================================================================
## Table 2: Main RDD Results
## =============================================================================

cat("Creating Table 2: Main RDD Results\n")

## Run models
opt_rdd <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = 0)
opt_bw <- opt_rdd$bws[1, 1]
rdd_bw <- rdd[abs(rich_margin) <= opt_bw]

m1 <- feols(winner_log_assets ~ rich_won, data = rdd_bw, vcov = "HC1")
m2 <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin,
            data = rdd_bw, vcov = "HC1")
m3 <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin | state,
            data = rdd_bw, vcov = "HC1")
m4 <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin | state + year,
            data = rdd_bw, vcov = "HC1")

## LaTeX output
sink(file.path(tab_dir, "tab2_main_results.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Main RDD Results: Effect of Electing the Wealthier Candidate}\n")
cat("\\label{tab:main}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Simple & Local Linear & + State FE & + State, Year FE \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Dependent Variable: Winner's Log Total Assets}} \\\\\n")
cat("[0.5em]\n")

## Extract coefficients
for (i in 1:4) {
  m <- list(m1, m2, m3, m4)[[i]]
  est <- coef(m)["rich_won"]
  se_val <- sqrt(vcov(m)["rich_won", "rich_won"])
  pv <- summary(m)$coeftable["rich_won", "Pr(>|t|)"]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))

  if (i == 1) {
    cat(sprintf("Wealthier candidate won & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
                coef(m1)["rich_won"], ifelse(summary(m1)$coeftable["rich_won", "Pr(>|t|)"] < 0.01, "***", ""),
                coef(m2)["rich_won"], ifelse(summary(m2)$coeftable["rich_won", "Pr(>|t|)"] < 0.01, "***", ""),
                coef(m3)["rich_won"], ifelse(summary(m3)$coeftable["rich_won", "Pr(>|t|)"] < 0.01, "***", ""),
                coef(m4)["rich_won"], ifelse(summary(m4)$coeftable["rich_won", "Pr(>|t|)"] < 0.01, "***", "")))
    cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
                sqrt(vcov(m1)["rich_won", "rich_won"]),
                sqrt(vcov(m2)["rich_won", "rich_won"]),
                sqrt(vcov(m3)["rich_won", "rich_won"]),
                sqrt(vcov(m4)["rich_won", "rich_won"])))
    break
  }
}

cat("[0.5em]\n")
cat(sprintf("Running variable & No & Yes & Yes & Yes \\\\\n"))
cat(sprintf("State FE & No & No & Yes & Yes \\\\\n"))
cat(sprintf("Year FE & No & No & No & Yes \\\\\n"))
cat(sprintf("Bandwidth & %.1f & %.1f & %.1f & %.1f \\\\\n",
            opt_bw, opt_bw, opt_bw, opt_bw))
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            formatC(nobs(m1), big.mark = ","),
            formatC(nobs(m2), big.mark = ","),
            formatC(nobs(m3), big.mark = ","),
            formatC(nobs(m4), big.mark = ",")))
cat("\\hline\n")

## rdrobust estimates
cat("[0.5em]\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: rdrobust Estimates (MSE-Optimal Bandwidth)}} \\\\\n")
cat("[0.5em]\n")
cat(sprintf("Conventional estimate & \\multicolumn{4}{c}{%.3f (%.3f)} \\\\\n",
            opt_rdd$coef[1], opt_rdd$se[1]))
cat(sprintf("Robust bias-corrected & \\multicolumn{4}{c}{%.3f (%.3f)} \\\\\n",
            opt_rdd$coef[3], opt_rdd$se[3]))
cat(sprintf("Robust 95\\%% CI & \\multicolumn{4}{c}{[%.3f, %.3f]} \\\\\n",
            opt_rdd$ci[3, 1], opt_rdd$ci[3, 2]))
cat(sprintf("MSE-optimal bandwidth & \\multicolumn{4}{c}{%.1f} \\\\\n", opt_rdd$bws[1, 1]))
cat(sprintf("Effective N (left, right) & \\multicolumn{4}{c}{%d, %d} \\\\\n",
            opt_rdd$N_h[1], opt_rdd$N_h[2]))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Panel A reports local linear regressions of the winner's log total assets on an indicator for the wealthier candidate winning, within the MSE-optimal bandwidth. Robust (HC1) standard errors in parentheses. Panel B reports rdrobust estimates with MSE-optimal bandwidth selection following \\citet{calonico2014robust}. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

## =============================================================================
## Table 3: Covariate Balance
## =============================================================================

cat("Creating Table 3: Covariate Balance\n")

balance <- fread(file.path(data_dir, "balance_tests.csv"))

sink(file.path(tab_dir, "tab3_balance.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Covariate Balance at the Cutoff}\n")
cat("\\label{tab:balance}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat("Covariate & Estimate & SE & $p$-value & Bandwidth & Balanced? \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(balance)) {
  bal <- ifelse(balance$p_value[i] > 0.05, "Yes", "No")
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.1f & %s \\\\\n",
              balance$variable[i], balance$estimate[i], balance$se[i],
              balance$p_value[i], balance$bandwidth[i], bal))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Each row reports the robust bias-corrected RDD estimate from rdrobust for a pre-determined covariate. A covariate is ``balanced'' if the $p$-value exceeds 0.05, indicating no statistically significant discontinuity at the threshold.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

## =============================================================================
## Table 4: Robustness Checks
## =============================================================================

cat("Creating Table 4: Robustness Checks\n")

## Load robustness data
poly <- fread(file.path(data_dir, "polynomial_sensitivity.csv"))
donut <- fread(file.path(data_dir, "donut_rdd.csv"))
kernel <- fread(file.path(data_dir, "kernel_bandwidth.csv"))

sink(file.path(tab_dir, "tab4_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness of Main Results}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("Specification & Estimate & SE & $p$-value & Effective N \\\\\n")
cat("\\hline\n")

cat("\\multicolumn{5}{l}{\\textit{Panel A: Polynomial Order}} \\\\\n")
for (i in 1:nrow(poly)) {
  cat(sprintf("Order %d & %.3f & %.3f & %.4f & %d \\\\\n",
              poly$poly_order[i], poly$estimate[i], poly$se[i],
              poly$p_value[i], poly$n_eff[i]))
}

cat("[0.3em]\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Donut RDD}} \\\\\n")
for (i in 1:nrow(donut)) {
  cat(sprintf("Exclude $|$margin$|$ $<$ %.1f\\%% & %.3f & %.3f & %.4f & %d \\\\\n",
              donut$donut[i], donut$estimate[i], donut$se[i],
              donut$p_value[i], donut$n_eff[i]))
}

cat("[0.3em]\n")
cat("\\multicolumn{5}{l}{\\textit{Panel C: Alternative Kernels and Bandwidths}} \\\\\n")
for (i in 1:nrow(kernel)) {
  cat(sprintf("%s & %.3f & %.3f & %.4f & \\\\\n",
              kernel$specification[i], kernel$estimate[i], kernel$se[i],
              kernel$p_value[i]))
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} All specifications use the dependent variable winner's log total assets. Panel A varies the polynomial order in rdrobust. Panel B implements donut RDD by excluding observations within the specified margin of the cutoff. Panel C varies the kernel function and bandwidth relative to the MSE-optimal choice.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

## =============================================================================
## Table 5: Alternative Wealth Measures
## =============================================================================

cat("Creating Table 5: Alternative Wealth Measures\n")

alt <- fread(file.path(data_dir, "alt_wealth_measures.csv"))

sink(file.path(tab_dir, "tab5_alt_wealth.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Alternative Wealth Measures}\n")
cat("\\label{tab:alt_wealth}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Wealth Measure & Estimate & SE & $p$-value \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(alt)) {
  cat(sprintf("%s & %.3f & %.3f & %.4f \\\\\n",
              alt$measure[i], alt$estimate[i], alt$se[i], alt$p_value[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Each row reports the robust bias-corrected rdrobust estimate using a different measure of the winner's wealth as the dependent variable. All use MSE-optimal bandwidths.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

cat("\n=== All tables generated ===\n")
tabs <- list.files(tab_dir, pattern = "\\.tex$")
for (t in tabs) {
  cat("  ", t, "\n")
}
