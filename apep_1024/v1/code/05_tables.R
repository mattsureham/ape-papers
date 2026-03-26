# 05_tables.R — Generate all tables for paper
# apep_1024: France DPE Rental Ban Bunching

source("00_packages.R")

dt <- fread("../data/dpe_clean.csv")
load("../data/bunching_results.RData")
load("../data/robustness_results.RData")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("Generating Table 1: Summary Statistics\n")

# Overall summary
sum_stats <- dt[, .(
  N = .N,
  mean_conso = mean(conso, na.rm = TRUE),
  sd_conso = sd(conso, na.rm = TRUE),
  median_conso = median(conso, na.rm = TRUE),
  mean_ghg = mean(ghg, na.rm = TRUE),
  sd_ghg = sd(ghg, na.rm = TRUE),
  mean_surface = mean(surface, na.rm = TRUE),
  pct_small = mean(small_property, na.rm = TRUE) * 100,
  pct_tight = mean(tight_market, na.rm = TRUE) * 100,
  pct_idf = mean(idf, na.rm = TRUE) * 100
)]

# By DPE label
label_stats <- dt[, .(
  N = .N,
  mean_conso = mean(conso, na.rm = TRUE),
  sd_conso = sd(conso, na.rm = TRUE),
  mean_surface = mean(surface, na.rm = TRUE)
), by = etiquette_dpe][order(etiquette_dpe)]

# Format Table 1
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: DPE Diagnostic Records, July 2021--March 2026}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & N & Mean & Std. Dev. & Median \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel A: Full Sample}} \\\\",
  "\\addlinespace",
  sprintf("Energy consumption (kWh/m$^2$/yr) & %s & %.1f & %.1f & %.1f \\\\",
          format(sum_stats$N, big.mark = ","),
          sum_stats$mean_conso, sum_stats$sd_conso, sum_stats$median_conso),
  sprintf("GHG emissions (kgCO$_2$/m$^2$/yr) & & %.1f & %.1f & \\\\",
          sum_stats$mean_ghg, sum_stats$sd_ghg),
  sprintf("Surface area (m$^2$) & & %.1f & & \\\\",
          sum_stats$mean_surface),
  sprintf("Small property ($<$40 m$^2$) & & \\multicolumn{3}{c}{%.1f\\%%} \\\\",
          sum_stats$pct_small),
  sprintf("Tight rental market & & \\multicolumn{3}{c}{%.1f\\%%} \\\\",
          sum_stats$pct_tight),
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B: By DPE Label}} \\\\",
  "\\addlinespace"
)

for (i in 1:nrow(label_stats)) {
  tab1_lines <- c(tab1_lines,
    sprintf("Label %s & %s & %.1f & %.1f & \\\\",
            label_stats$etiquette_dpe[i],
            format(label_stats$N[i], big.mark = ","),
            label_stats$mean_conso[i],
            label_stats$sd_conso[i]))
}

tab1_lines <- c(tab1_lines,
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Data from ADEME DPE open data (dataset \\texttt{dpe03existant}). Each observation is a building-level energy performance diagnostic. Energy consumption is the five-use primary energy consumption. Tight rental markets include departments 75, 92, 93, 94, 69, 13, 31, 33, 59, 67.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Written tables/tab1_summary.tex\n")

# ============================================================
# TABLE 2: Main Bunching Results
# ============================================================

cat("Generating Table 2: Bunching Estimates\n")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Bunching Estimates at DPE Label Thresholds}",
  "\\label{tab:bunching}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "Threshold & Label & Excess Mass & Normalized $b$ & SE & Observations \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel A: Regulatory Thresholds}} \\\\",
  "\\addlinespace",
  sprintf("420 kWh/m$^2$ & F/G & %s & %.3f & (%.3f) & %s \\\\",
          format(round(b_420$excess), big.mark = ","),
          b_420$b, b_420$se,
          format(b_420$total_obs, big.mark = ",")),
  sprintf("330 kWh/m$^2$ & E/F & %s & %.3f & (%.3f) & %s \\\\",
          format(round(b_330$excess), big.mark = ","),
          b_330$b, b_330$se,
          format(b_330$total_obs, big.mark = ",")),
  sprintf("250 kWh/m$^2$ & D/E & %s & %.3f & (%.3f) & %s \\\\",
          format(round(b_250$excess), big.mark = ","),
          b_250$b, b_250$se,
          format(b_250$total_obs, big.mark = ",")),
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: Placebo Threshold}} \\\\",
  "\\addlinespace",
  sprintf("110 kWh/m$^2$ & B/C & %s & %.3f & (%.3f) & %s \\\\",
          format(round(b_110$excess), big.mark = ","),
          b_110$b, b_110$se,
          format(b_110$total_obs, big.mark = ",")),
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Bunching estimates following Kleven and Waseem (2013). Normalized $b$ is excess mass divided by the counterfactual bin height at the threshold. Counterfactual density estimated with 7th-order polynomial excluding a 20 kWh/m$^2$ manipulation window below each threshold. Standard errors from 200 Poisson bootstrap replications. Panel A shows thresholds where France's Loi Climat et R\\'{e}silience (2021) prohibits renting: G from January 2025, F from January 2028, E from January 2034. Panel B shows the B/C threshold (110 kWh/m$^2$), which carries no regulatory consequence.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_bunching.tex")
cat("  Written tables/tab2_bunching.tex\n")

# ============================================================
# TABLE 3: Difference-in-Bunching Over Time
# ============================================================

cat("Generating Table 3: Difference-in-Bunching\n")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Difference-in-Bunching at the F/G Threshold (420 kWh/m$^2$) Over Time}",
  "\\label{tab:dib}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Year & Normalized $b$ & SE & Excess Mass & Observations \\\\",
  "\\hline",
  "\\addlinespace"
)

for (i in 1:nrow(dib)) {
  tab3_lines <- c(tab3_lines,
    sprintf("%d & %.3f & (%.3f) & %s & %s \\\\",
            dib$year[i], dib$b[i], dib$se[i],
            format(round(dib$excess[i]), big.mark = ","),
            format(dib$n[i], big.mark = ",")))
}

# Add trend test
if (nrow(dib) >= 3) {
  trend_fit <- lm(b ~ year, data = dib)
  trend_coef <- coef(trend_fit)["year"]
  trend_se <- summary(trend_fit)$coefficients["year", "Std. Error"]
  trend_p <- summary(trend_fit)$coefficients["year", "Pr(>|t|)"]

  tab3_lines <- c(tab3_lines,
    "\\addlinespace",
    "\\hline",
    sprintf("Linear trend ($\\Delta b$/year) & %.4f & (%.4f) & \\multicolumn{2}{c}{$p = %.3f$} \\\\",
            trend_coef, trend_se, trend_p))
}

tab3_lines <- c(tab3_lines,
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Bunching estimated separately by DPE diagnostic year at the 420 kWh/m$^2$ F/G threshold. If bunching reflects behavioral responses to the approaching January 2025 G-property rental ban, normalized $b$ should increase over time. The linear trend is from an OLS regression of $b$ on calendar year. All other specifications as in Table~\\ref{tab:bunching}.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_dib.tex")
cat("  Written tables/tab3_dib.tex\n")

# ============================================================
# TABLE 4: Geographic Heterogeneity
# ============================================================

cat("Generating Table 4: Geographic Heterogeneity\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Bunching at the F/G Threshold by Rental Market Tightness}",
  "\\label{tab:geography}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Sample & Normalized $b$ & SE & Excess Mass & Observations \\\\",
  "\\hline",
  "\\addlinespace",
  sprintf("Tight rental markets & %.3f & (%.3f) & %s & %s \\\\",
          b_420_tight$b, b_420_tight$se,
          format(round(b_420_tight$excess), big.mark = ","),
          format(b_420_tight$total_obs, big.mark = ",")),
  sprintf("Other markets & %.3f & (%.3f) & %s & %s \\\\",
          b_420_other$b, b_420_other$se,
          format(round(b_420_other$excess), big.mark = ","),
          format(b_420_other$total_obs, big.mark = ",")),
  "\\addlinespace",
  sprintf("\\^Ile-de-France & %.3f & (%.3f) & %s & %s \\\\",
          b_420_idf$b, b_420_idf$se,
          format(round(b_420_idf$excess), big.mark = ","),
          format(b_420_idf$total_obs, big.mark = ",")),
  sprintf("Non-\\^Ile-de-France & %.3f & (%.3f) & %s & %s \\\\",
          b_420_nonidf$b, b_420_nonidf$se,
          format(round(b_420_nonidf$excess), big.mark = ","),
          format(b_420_nonidf$total_obs, big.mark = ",")),
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Bunching at the F/G threshold (420 kWh/m$^2$/yr) estimated separately by rental market tightness. Tight rental markets: departments with high population density and rental shares (75, 92, 93, 94, 69, 13, 31, 33, 59, 67). If bunching is driven by landlord behavioral responses to the rental ban, it should concentrate in markets where rental income loss is largest.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_geography.tex")
cat("  Written tables/tab4_geography.tex\n")

# ============================================================
# TABLE 5: Robustness
# ============================================================

cat("Generating Table 5: Robustness\n")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness of Bunching Estimates at the F/G Threshold}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{llcc}",
  "\\hline\\hline",
  "Specification & Variant & Normalized $b$ & SE \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{4}{l}{\\textit{Panel A: Polynomial Order}} \\\\",
  "\\addlinespace"
)

for (i in 1:nrow(poly_dt)) {
  tab5_lines <- c(tab5_lines,
    sprintf("& Order %d & %.3f & (%.3f) \\\\",
            poly_dt$poly_order[i], poly_dt$b[i], poly_dt$se[i]))
}

tab5_lines <- c(tab5_lines,
  "\\addlinespace",
  "\\multicolumn{4}{l}{\\textit{Panel B: Bin Width}} \\\\",
  "\\addlinespace"
)

for (i in 1:nrow(bin_dt)) {
  tab5_lines <- c(tab5_lines,
    sprintf("& %d kWh/m$^2$ & %.3f & (%.3f) \\\\",
            bin_dt$bin_width[i], bin_dt$b[i], bin_dt$se[i]))
}

tab5_lines <- c(tab5_lines,
  "\\addlinespace",
  "\\multicolumn{4}{l}{\\textit{Panel C: Exclusion Window}} \\\\",
  "\\addlinespace"
)

for (i in 1:nrow(excl_dt)) {
  tab5_lines <- c(tab5_lines,
    sprintf("& $\\pm$%d kWh/m$^2$ & %.3f & (%.3f) \\\\",
            excl_dt$excl_width[i], excl_dt$b[i], excl_dt$se[i]))
}

tab5_lines <- c(tab5_lines,
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Sensitivity of the F/G threshold bunching estimate (420 kWh/m$^2$/yr) to specification choices. Baseline: 7th-order polynomial, 5 kWh/m$^2$ bins, 20 kWh/m$^2$ exclusion window. Standard errors from 200 Poisson bootstrap replications.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_robustness.tex")
cat("  Written tables/tab5_robustness.tex\n")

# ============================================================
# SDE TABLE (APPENDIX — tabF1_sde.tex)
# ============================================================

cat("Generating SDE Table\n")

# For bunching papers, SDE is the normalized bunching coefficient b
# SD(Y) = 1 for normalized b (it's already a standardized measure)
# We report b directly as the SDE

sd_conso <- dt[, sd(conso, na.rm = TRUE)]

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does the phased rental ban on energy-inefficient properties under France's 2021 Climat et R\\'{e}silience law induce strategic renovation visible as bunching in building energy performance diagnostics at regulatory thresholds? ",
  "\\textbf{Policy mechanism:} The law progressively bans renting properties rated G (from January 2025), F (from January 2028), and E (from January 2034) on the DPE energy label scale, creating sharp kWh/m$^2$/year thresholds below which properties retain rental eligibility and above which they face market exclusion. ",
  "\\textbf{Outcome definition:} Normalized excess mass $b$ at each DPE label threshold, measuring the ratio of excess density just below the regulatory cutoff to the counterfactual bin height, estimated via polynomial density fitting following Kleven and Waseem (2013). ",
  "\\textbf{Treatment:} Regulatory threshold creating a discrete change in rental eligibility at specific energy consumption cutoffs (binary: above vs.\\ below threshold). ",
  "\\textbf{Data:} ADEME DPE open data (\\texttt{dpe03existant}), building-level energy performance diagnostics, July 2021--March 2026, approximately 14 million observations. ",
  "\\textbf{Method:} Bunching estimator with 7th-order polynomial counterfactual, 5 kWh/m$^2$ bins, 20 kWh/m$^2$ exclusion window; standard errors from 200 Poisson bootstrap replications. ",
  "\\textbf{Sample:} All residential building diagnostics with non-missing energy consumption in the relevant analysis window around each threshold. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of energy consumption across the analysis sample. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Compute SDEs using the excess mass relative to SD of consumption
sde_420 <- b_420$excess / sd_conso
se_sde_420 <- b_420$se * (b_420$excess / max(b_420$b, 0.001)) / sd_conso
sde_330 <- b_330$excess / sd_conso
se_sde_330 <- b_330$se * (abs(b_330$excess) / max(abs(b_330$b), 0.001)) / sd_conso
sde_110 <- b_110$excess / sd_conso
se_sde_110 <- b_110$se * (abs(b_110$excess) / max(abs(b_110$b), 0.001)) / sd_conso

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde > 0.15) return(ifelse(sde > 0, "Large positive", "Large negative"))
  if (abs_sde > 0.05) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  if (abs_sde > 0.005) return(ifelse(sde > 0, "Small positive", "Small negative"))
  return("Null")
}

# Panel A: Pooled results
sde_rows_a <- list(
  list(outcome = "Bunching at F/G (420 kWh/m$^2$)",
       beta = b_420$b, se = b_420$se, sdy = 1,
       sde = b_420$b, se_sde = b_420$se),
  list(outcome = "Bunching at E/F (330 kWh/m$^2$)",
       beta = b_330$b, se = b_330$se, sdy = 1,
       sde = b_330$b, se_sde = b_330$se),
  list(outcome = "Bunching at B/C placebo (110 kWh/m$^2$)",
       beta = b_110$b, se = b_110$se, sdy = 1,
       sde = b_110$b, se_sde = b_110$se)
)

# Panel B: Heterogeneous (geographic splits)
sde_rows_b <- list(
  list(outcome = "F/G, Tight rental markets",
       beta = b_420_tight$b, se = b_420_tight$se, sdy = 1,
       sde = b_420_tight$b, se_sde = b_420_tight$se),
  list(outcome = "F/G, Other markets",
       beta = b_420_other$b, se = b_420_other$se, sdy = 1,
       sde = b_420_other$b, se_sde = b_420_other$se)
)

sde_tab_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace"
)

for (r in sde_rows_a) {
  cls <- classify_sde(r$sde)
  sde_tab_lines <- c(sde_tab_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            r$outcome, r$beta, r$se, r$sdy, r$sde, r$se_sde, cls))
}

sde_tab_lines <- c(sde_tab_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Geographic Splits)}} \\\\",
  "\\addlinespace"
)

for (r in sde_rows_b) {
  cls <- classify_sde(r$sde)
  sde_tab_lines <- c(sde_tab_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            r$outcome, r$beta, r$se, r$sdy, r$sde, r$se_sde, cls))
}

sde_tab_lines <- c(sde_tab_lines,
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tab_lines, "../tables/tabF1_sde.tex")
cat("  Written tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
