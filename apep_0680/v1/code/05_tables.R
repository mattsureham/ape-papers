## 05_tables.R — Generate all LaTeX tables
## apep_0680: ZFE Spatial RDD on Property Values

source("code/00_packages.R")

cat("=== Generating Tables ===\n\n")

dvf <- readRDS("data/analysis_data.rds")
results <- readRDS("data/main_results.rds")
rob <- readRDS("data/robustness_results.rds")
rdd_cov_model <- readRDS("data/rdd_cov_model.rds")
did_model <- readRDS("data/did_boundary_model.rds")

# Helper: format number with stars
stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.1) return("$^{*}$")
  return("")
}

format_coef <- function(val, se_val, pval = NA) {
  star <- if (!is.na(pval)) stars(pval) else {
    z <- abs(val / se_val)
    p <- 2 * (1 - pnorm(z))
    stars(p)
  }
  sprintf("%.4f%s", val, star)
}

# ======================================================
# TABLE 1: Summary Statistics
# ======================================================
cat("--- Table 1: Summary Statistics ---\n")
sample <- dvf[in_sample_1km == TRUE]

# Compute stats by inside/outside
make_stats <- function(dt, label) {
  data.frame(
    Group = label,
    N = format(nrow(dt), big.mark = ","),
    `Price_m2` = sprintf("%.0f", mean(dt$price_m2, na.rm = TRUE)),
    `SD_Price` = sprintf("%.0f", sd(dt$price_m2, na.rm = TRUE)),
    `Surface` = sprintf("%.1f", mean(dt$surface_reelle_bati, na.rm = TRUE)),
    `Rooms` = sprintf("%.1f", mean(dt$rooms, na.rm = TRUE)),
    `Pct_Apt` = sprintf("%.1f", 100 * mean(dt$is_apartment, na.rm = TRUE))
  )
}

stats_inside <- make_stats(sample[inside_zfe == TRUE], "Inside ZFE")
stats_outside <- make_stats(sample[inside_zfe == FALSE], "Outside ZFE")
stats_all <- make_stats(sample, "Full Sample")

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Property Transactions Within 1km of ZFE Boundary}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & N & Price/m$^2$ & SD(Price/m$^2$) & Surface (m$^2$) & Rooms & \\% Apt. \\\\\n",
  "\\midrule\n",
  sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
          stats_inside$Group, stats_inside$N, stats_inside$Price_m2,
          stats_inside$SD_Price, stats_inside$Surface, stats_inside$Rooms, stats_inside$Pct_Apt),
  sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
          stats_outside$Group, stats_outside$N, stats_outside$Price_m2,
          stats_outside$SD_Price, stats_outside$Surface, stats_outside$Rooms, stats_outside$Pct_Apt),
  "\\midrule\n",
  sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
          stats_all$Group, stats_all$N, stats_all$Price_m2,
          stats_all$SD_Price, stats_all$Surface, stats_all$Rooms, stats_all$Pct_Apt),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Sample includes all residential property transactions (apartments and houses) ",
  "within 1km of the Lyon ZFE boundary, 2018--2024. Price per m$^2$ is the transaction value divided by ",
  "built surface area. Source: DVF (Demandes de Valeurs Fonci\\`eres).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, "tables/tab1_summary.tex")

# ======================================================
# TABLE 2: Main RDD Results
# ======================================================
cat("--- Table 2: Main RDD Results ---\n")

r <- results$rdd_main
rc <- results$rdd_cov
did <- results$did_boundary

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of ZFE on Property Values: Spatial RDD Estimates}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & RDD & RDD + Covariates & Diff-in-Disc \\\\\n",
  "\\midrule\n",
  sprintf("Inside ZFE & %s & %s & %s \\\\\n",
          format_coef(r$tau, r$se_robust),
          format_coef(rc$tau, rc$se),
          format_coef(did$tau, did$se)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\\n", r$se_robust, rc$se, did$se),
  "[0.5em]\n",
  sprintf("Bandwidth (km) & %.3f & 1.000 & 1.000 \\\\\n", r$bw),
  sprintf("Effective N & %s & %s & %s \\\\\n",
          format(r$n_eff, big.mark = ","),
          format(nobs(rdd_cov_model), big.mark = ","),
          format(nobs(did_model), big.mark = ",")),
  "Covariates & No & Yes & Yes \\\\\n",
  "Year-Quarter FE & No & Yes & Yes \\\\\n",
  "Kernel & Triangular & --- & --- \\\\\n",
  "Polynomial & Linear & Linear & Linear \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log(price/m$^2$). Column (1) reports the local polynomial ",
  "RDD estimate using \\texttt{rdrobust} with MSE-optimal bandwidth and triangular kernel. Column (2) ",
  "adds property controls (surface area, rooms, apartment indicator) and year-quarter fixed effects within ",
  "a 1km bandwidth. Column (3) reports the difference-in-discontinuities estimate (post$\\times$inside\\_ZFE), ",
  "netting out any pre-existing boundary effect. Robust standard errors in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, "tables/tab2_main.tex")

# ======================================================
# TABLE 3: Heterogeneity and Phase Decomposition
# ======================================================
cat("--- Table 3: Heterogeneity ---\n")

p1 <- results$phase1
p2 <- results$phase2
apt <- results$apartments
hs <- results$houses
plb <- results$placebo

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Heterogeneity and Phase Decomposition}\n",
  "\\label{tab:hetero}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Phase 1 & Phase 2 & Apartments & Houses & Placebo \\\\\n",
  " & (Crit'Air 5) & (Crit'Air 3) & & & (Pre-ZFE) \\\\\n",
  "\\midrule\n",
  sprintf("Inside ZFE & %s & %s & %s & %s & %s \\\\\n",
          format_coef(p1$tau, p1$se),
          if (!is.null(p2)) format_coef(p2$tau, p2$se) else "---",
          format_coef(apt$tau, apt$se),
          if (!is.null(hs)) format_coef(hs$tau, hs$se) else "---",
          format_coef(plb$tau, plb$se_robust)),
  sprintf(" & (%.4f) & %s & (%.4f) & %s & (%.4f) \\\\\n",
          p1$se,
          if (!is.null(p2)) sprintf("(%.4f)", p2$se) else "---",
          apt$se,
          if (!is.null(hs)) sprintf("(%.4f)", hs$se) else "---",
          plb$se_robust),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} All columns report \\texttt{rdrobust} estimates with MSE-optimal bandwidth ",
  "and triangular kernel. Phase 1 covers September 2022--December 2023 (Crit'Air 5 ban). ",
  "Phase 2 covers January 2024 onward (Crit'Air 3 ban). Column (5) is a placebo using pre-ZFE ",
  "transactions (2018--August 2022). Robust standard errors in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, "tables/tab3_hetero.tex")

# ======================================================
# TABLE 4: Bandwidth Sensitivity
# ======================================================
cat("--- Table 4: Bandwidth Sensitivity ---\n")

bw_df <- rob$bandwidth_sensitivity
tab4_rows <- ""
for (i in seq_len(nrow(bw_df))) {
  tab4_rows <- paste0(tab4_rows,
    sprintf("%.1f & %s & (%.4f) & %s \\\\\n",
            bw_df$bandwidth_km[i],
            format_coef(bw_df$tau[i], bw_df$se_robust[i]),
            bw_df$se_robust[i],
            format(bw_df$n_eff[i], big.mark = ",")))
}

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Bandwidth Sensitivity}\n",
  "\\label{tab:bandwidth}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Bandwidth (km) & $\\hat{\\tau}$ & SE & Effective N \\\\\n",
  "\\midrule\n",
  tab4_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row re-estimates the RDD with a fixed bandwidth using \\texttt{rdrobust} ",
  "with triangular kernel and linear polynomial. Robust bias-corrected standard errors in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, "tables/tab4_bandwidth.tex")

# ======================================================
# TABLE 5: Validity Tests
# ======================================================
cat("--- Table 5: Validity Tests ---\n")

bal <- rob$balance
bal_rows <- ""
for (i in seq_len(nrow(bal))) {
  bal_rows <- paste0(bal_rows,
    sprintf("%s & %.2f & %.2f & %.2f & %.3f \\\\\n",
            gsub("_", "\\\\_", bal$variable[i]),
            bal$mean_inside[i], bal$mean_outside[i],
            bal$diff[i], bal$pval[i]))
}

tab5 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Validity: Covariate Balance and Density Tests}\n",
  "\\label{tab:validity}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Covariate Balance (within 500m of boundary)}} \\\\\n",
  "\\midrule\n",
  "Variable & Inside & Outside & Difference & $p$-value \\\\\n",
  "\\midrule\n",
  bal_rows,
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: McCrary Density Tests}} \\\\\n",
  "\\midrule\n",
  sprintf("Post-ZFE period & \\multicolumn{3}{c}{$p$-value = %.3f} & %s \\\\\n",
          rob$mccrary_pval,
          ifelse(rob$mccrary_pval > 0.05, "No bunching", "Bunching detected")),
  sprintf("Pre-ZFE period & \\multicolumn{3}{c}{$p$-value = %.3f} & %s \\\\\n",
          rob$mccrary_pre_pval,
          ifelse(rob$mccrary_pre_pval > 0.05, "No bunching", "Bunching detected")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A reports mean covariate values for post-ZFE transactions within 500m ",
  "of the boundary, comparing inside vs.\\ outside. $p$-values from two-sample $t$-tests. ",
  "Panel B reports Cattaneo, Jansson \\& Ma (2020) density discontinuity tests. ",
  "A non-significant result ($p > 0.05$) supports the absence of sorting at the boundary.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab5, "tables/tab5_validity.tex")

# ======================================================
# SDE TABLE (Appendix)
# ======================================================
cat("--- SDE Appendix Table ---\n")

sd_y <- sd(dvf[in_sample_1km == TRUE & post == 1]$log_price_m2, na.rm = TRUE)
r <- results$rdd_main

# Main outcome
sde_main <- r$tau / sd_y
se_sde_main <- r$se_robust / sd_y

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_class <- classify_sde(sde_main)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sprintf("Log price/m$^2$ & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          r$tau, r$se_robust, sd_y, sde_main, se_sde_main, sde_class),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} This table reports standardized effect sizes for the main RDD estimates. ",
  "The research question is whether Lyon's ZFE (Low-Emission Zone) affects residential property values. ",
  "Data: DVF property transactions (2022--2024), spatial RDD at the ZFE boundary. ",
  "SDE = $\\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. ",
  "Classification refers to effect magnitude, not statistical significance. ",
  "N = ", format(r$n_eff, big.mark = ","), " transactions in the RDD effective sample.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
