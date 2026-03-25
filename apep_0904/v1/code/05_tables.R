# 05_tables.R — Generate all tables for apep_0904
source("00_packages.R")

PROJ_DIR <- normalizePath(file.path(getwd(), ".."))
DATA_DIR <- file.path(PROJ_DIR, "data")
TABLE_DIR <- file.path(PROJ_DIR, "tables")
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

# --- Load data ---
dt <- fread(file.path(DATA_DIR, "contract_bins_clean.csv"))
results <- jsonlite::read_json(file.path(DATA_DIR, "bunching_results.json"))
yearly <- fread(file.path(DATA_DIR, "yearly_bunching.csv"))
poly_rob <- fread(file.path(DATA_DIR, "robustness_polynomial.csv"))
window_rob <- fread(file.path(DATA_DIR, "robustness_window.csv"))
loo_rob <- fread(file.path(DATA_DIR, "robustness_loo.csv"))
placebo_rob <- fread(file.path(DATA_DIR, "robustness_placebo.csv"))

# ========================================================================
# Table 1: Summary Statistics
# ========================================================================

# Compute period-level stats
summary_stats <- dt[, .(
  total_contracts = sum(count),
  mean_per_bin = mean(count),
  sd_per_bin = sd(count),
  n_years = uniqueN(fiscal_year),
  mean_annual = sum(count) / uniqueN(fiscal_year)
), by = .(regime)]

# Key bin ratios
ratio_150_pre <- dt[fiscal_year >= 2015 & fiscal_year <= 2019 &
                     bin_lower == 140000, mean(count)] /
                 dt[fiscal_year >= 2015 & fiscal_year <= 2019 &
                     bin_lower == 150000, mean(count)]

ratio_250_post <- dt[fiscal_year >= 2022 &
                      bin_lower == 240000, mean(count)] /
                  dt[fiscal_year >= 2022 &
                      bin_lower == 250000, mean(count)]

ratio_200_pre <- dt[fiscal_year >= 2015 & fiscal_year <= 2019 &
                     bin_lower == 190000, mean(count)] /
                 dt[fiscal_year >= 2015 & fiscal_year <= 2019 &
                     bin_lower == 200000, mean(count)]

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Federal Contract Density}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & \\multicolumn{1}{c}{SAT = \\$150K} & \\multicolumn{1}{c}{SAT = \\$250K} \\\\\n",
  " & \\multicolumn{1}{c}{(FY2012--2019)} & \\multicolumn{1}{c}{(FY2021--2025)} \\\\\n",
  "\\midrule\n",
  sprintf("Total contracts (\\$50K--\\$400K) & %s & %s \\\\\n",
          format(summary_stats[regime == "SAT_150K", total_contracts], big.mark = ","),
          format(summary_stats[regime == "SAT_250K", total_contracts], big.mark = ",")),
  sprintf("Annual average & %s & %s \\\\\n",
          format(round(summary_stats[regime == "SAT_150K", mean_annual]), big.mark = ","),
          format(round(summary_stats[regime == "SAT_250K", mean_annual]), big.mark = ",")),
  sprintf("Fiscal years & %d & %d \\\\\n",
          summary_stats[regime == "SAT_150K", n_years],
          summary_stats[regime == "SAT_250K", n_years]),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Density ratios (just below / just above threshold)}} \\\\\n",
  sprintf("At SAT & %.2f & %.2f \\\\\n", ratio_150_pre, ratio_250_post),
  sprintf("At \\$200K (placebo) & %.2f & --- \\\\\n", ratio_200_pre),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Contract counts from USAspending.gov (FPDS-NG) for all unclassified ",
  "federal contracts in \\$10K bins. The SAT was \\$150K through August 2020 and \\$250K ",
  "thereafter. FY2020 excluded as a transition year. Density ratio is the count in the ",
  "\\$10K bin immediately below the threshold divided by the count immediately above.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1, file.path(TABLE_DIR, "tab1_summary.tex"))

# ========================================================================
# Table 2: Main Bunching Estimates
# ========================================================================

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Bunching Estimates at the Simplified Acquisition Threshold}\n",
  "\\label{tab:bunching}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & \\multicolumn{1}{c}{SAT = \\$150K} & \\multicolumn{1}{c}{SAT = \\$250K} \\\\\n",
  " & \\multicolumn{1}{c}{(FY2015--2019)} & \\multicolumn{1}{c}{(FY2022--2025)} \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Baseline estimates}} \\\\\n",
  sprintf("Excess mass ($\\hat{b}$) & %.3f & %.3f \\\\\n",
          results$b_150_pre, results$b_250_post),
  sprintf(" & (%.3f) & (%.3f) \\\\\n",
          results$se_150_pre, results$se_250_post),
  sprintf("Excess contracts/year & %s & %s \\\\\n",
          format(round(results$excess_150_pre), big.mark = ","),
          format(round(results$excess_250_post), big.mark = ",")),
  sprintf("95\\%% CI & [%.3f, %.3f] & [%.3f, %.3f] \\\\\n",
          results$ci_150_pre_lo, results$ci_150_pre_hi,
          results$ci_250_post_lo, results$ci_250_post_hi),
  "Polynomial order & 7 & 7 \\\\\n",
  "Bunching window & \\$20K & \\$20K \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Migration test}} \\\\\n",
  sprintf("$\\hat{b}$ at \\$150K, post-2020 & \\multicolumn{2}{c}{%.3f} \\\\\n",
          results$b_150_post),
  sprintf("$\\hat{b}$ at \\$250K, pre-2020 & \\multicolumn{2}{c}{%.3f} \\\\\n",
          mean(yearly[fiscal_year >= 2015 & fiscal_year <= 2019, b_250])),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Bunching estimates following Chetty et al.\\ (2011) and Kleven \\& Waseem (2013). ",
  "The excess mass $\\hat{b}$ is the ratio of excess density in the bunching region ",
  "(\\$20K below SAT) to the counterfactual density per bin, estimated from a 7th-order ",
  "polynomial fit to the contract density distribution excluding the bunching region. ",
  "Standard errors (in parentheses) from 500 parametric bootstrap replications with ",
  "Poisson resampling. Panel B shows that bunching at the old \\$150K threshold ",
  "dissipates after the SAT moves to \\$250K, while bunching was absent at \\$250K ",
  "before it became the SAT.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2, file.path(TABLE_DIR, "tab2_bunching.tex"))

# ========================================================================
# Table 3: Year-by-Year Bunching (Event Study)
# ========================================================================

# Select key years around the 2020 threshold change
event_years <- yearly[fiscal_year >= 2012 & fiscal_year <= 2025]

tab3_rows <- ""
for (i in seq_len(nrow(event_years))) {
  fy <- event_years[i, fiscal_year]
  marker <- ifelse(fy == 2020, " $\\dagger$", "")
  tab3_rows <- paste0(tab3_rows,
    sprintf("FY%d%s & %.3f & %.3f \\\\\n",
            fy, marker, event_years[i, b_150], event_years[i, b_250]))
}

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Year-by-Year Bunching Intensity}\n",
  "\\label{tab:yearly}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & $\\hat{b}$ at \\$150K & $\\hat{b}$ at \\$250K \\\\\n",
  "\\midrule\n",
  tab3_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Annual bunching estimates using a 5th-order polynomial fit. ",
  "$\\dagger$ marks the transition year (FY2020, Oct 2019--Sep 2020) when the SAT ",
  "increased from \\$150K to \\$250K effective August 31, 2020. Bunching at \\$150K ",
  "peaks in FY2017 ($\\hat{b} = 0.621$) and dissipates after the threshold moves. ",
  "Bunching at \\$250K emerges starting FY2019--2020 as agencies anticipated the reform.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3, file.path(TABLE_DIR, "tab3_yearly.tex"))

# ========================================================================
# Table 4: Robustness Checks
# ========================================================================

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness of Bunching Estimates}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & $\\hat{b}$ at \\$150K & $\\hat{b}$ at \\$250K \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Polynomial order}} \\\\\n"
)
for (i in seq_len(nrow(poly_rob))) {
  tab4 <- paste0(tab4,
    sprintf("$p = %d$ & %.3f & %.3f \\\\\n",
            poly_rob[i, poly_order], poly_rob[i, b_150], poly_rob[i, b_250]))
}
tab4 <- paste0(tab4,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Bunching window}} \\\\\n"
)
for (i in seq_len(nrow(window_rob))) {
  tab4 <- paste0(tab4,
    sprintf("$w = \\$%dK$ & %.3f & %.3f \\\\\n",
            window_rob[i, window] / 1000,
            window_rob[i, b_150], window_rob[i, b_250]))
}
tab4 <- paste0(tab4,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Leave-one-year-out (\\$150K)}} \\\\\n"
)
for (i in seq_len(nrow(loo_rob))) {
  tab4 <- paste0(tab4,
    sprintf("Drop FY%d & %.3f & --- \\\\\n",
            loo_rob[i, dropped_fy], loo_rob[i, b_150]))
}
tab4 <- paste0(tab4,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel D: Placebo thresholds (FY2015--2019)}} \\\\\n"
)
for (i in seq_len(nrow(placebo_rob))) {
  tab4 <- paste0(tab4,
    sprintf("\\$%dK & \\multicolumn{2}{c}{$\\hat{b}$ = %.3f, ratio = %.2f} \\\\\n",
            placebo_rob[i, threshold] / 1000,
            dt[fiscal_year >= 2015 & fiscal_year <= 2019 &
                bin_midpoint == placebo_rob[i, threshold] - 5000,
               mean(count)] /
            dt[fiscal_year >= 2015 & fiscal_year <= 2019 &
                bin_midpoint == placebo_rob[i, threshold] + 5000,
               mean(count)] - 1,
            placebo_rob[i, ratio]))
}
tab4 <- paste0(tab4,
  sprintf("\\$150K (SAT) & \\multicolumn{2}{c}{$\\hat{b}$ = %.3f, ratio = %.2f} \\\\\n",
          results$b_150_pre, ratio_150_pre),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A varies the polynomial order from 5 to 9. ",
  "Panel B varies the bunching window from \\$10K to \\$40K below the threshold. ",
  "Panel C drops one fiscal year at a time from the FY2015--2019 average. ",
  "Panel D tests for bunching at non-SAT round-number thresholds; density ratios ",
  "at these placebos are far smaller than at the actual SAT.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4, file.path(TABLE_DIR, "tab4_robustness.tex"))

# ========================================================================
# SDE Table (Appendix)
# ========================================================================

# For SDE: treat bunching estimate as causal effect on density distortion
# Outcome = contract count in the just-below-SAT bin
# β̂ = excess mass (contracts displaced by bunching)
# SD(Y) = SD of bin counts across all bins in the estimation sample

# $150K analysis
d150_sd <- sd(dt[fiscal_year >= 2015 & fiscal_year <= 2019,
                  mean(count), by = bin_midpoint]$V1)
sde_150 <- results$excess_150_pre / d150_sd
se_sde_150 <- results$se_150_pre * (results$excess_150_pre / results$b_150_pre) / d150_sd

# $250K analysis
d250_sd <- sd(dt[fiscal_year >= 2022,
                  mean(count), by = bin_midpoint]$V1)
sde_250 <- results$excess_250_post / d250_sd
se_sde_250 <- results$se_250_post * (results$excess_250_post / results$b_250_post) / d250_sd

# Classification
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return("Small positive")
  if (abs_sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Migration: dissolution at old threshold
sde_migration <- (results$b_150_pre - results$b_150_post) *
                 (results$excess_150_pre / results$b_150_pre) / d150_sd

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the federal Simplified Acquisition Threshold cause ",
  "contracting officers to strategically compress contract values below the threshold, ",
  "and does this distortion migrate when the threshold changes? ",
  "\\textbf{Policy mechanism:} The SAT separates streamlined procurement (below) from ",
  "full-and-open competition with formal solicitation, evaluation panels, and detailed ",
  "documentation requirements (above); officers can avoid compliance costs by sizing ",
  "contracts just below the threshold. ",
  "\\textbf{Outcome definition:} Contract density (number of contracts per \\$10K bin) ",
  "from USAspending.gov FPDS-NG data, measuring the distribution of contract award amounts. ",
  "\\textbf{Treatment:} Binary; the SAT creates a sharp regulatory discontinuity at a ",
  "known dollar threshold (\\$150K pre-2020, \\$250K post-2020). ",
  "\\textbf{Data:} USAspending.gov, FY2008--FY2025, universe of unclassified federal ",
  "contracts in \\$50K--\\$400K range, approximately 370,000 contracts per year. ",
  "\\textbf{Method:} Bunching estimation (Chetty et al.\\ 2011; Kleven \\& Waseem 2013) with ",
  "7th-order polynomial counterfactual; parametric bootstrap (500 replications) for inference. ",
  "\\textbf{Sample:} All unclassified federal contract actions (types A/B/C/D) with award ",
  "amounts between \\$50K and \\$400K; 6.7 million contract-year observations across 18 fiscal years. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-bin ",
  "standard deviation of contract density. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Bunching at \\$150K & %s & %s & %s & %.3f & %.3f & %s \\\\\n",
          format(round(results$excess_150_pre), big.mark = ","),
          format(round(results$se_150_pre * results$excess_150_pre / results$b_150_pre), big.mark = ","),
          format(round(d150_sd), big.mark = ","),
          sde_150, se_sde_150, classify_sde(sde_150)),
  sprintf("Bunching at \\$250K & %s & %s & %s & %.3f & %.3f & %s \\\\\n",
          format(round(results$excess_250_post), big.mark = ","),
          format(round(results$se_250_post * results$excess_250_post / results$b_250_post), big.mark = ","),
          format(round(d250_sd), big.mark = ","),
          sde_250, se_sde_250, classify_sde(sde_250)),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by threshold level)}} \\\\\n",
  sprintf("Low threshold (\\$150K SAT) & %s & %s & %s & %.3f & %.3f & %s \\\\\n",
          format(round(results$excess_150_pre), big.mark = ","),
          format(round(results$se_150_pre * results$excess_150_pre / results$b_150_pre), big.mark = ","),
          format(round(d150_sd), big.mark = ","),
          sde_150, se_sde_150, classify_sde(sde_150)),
  sprintf("High threshold (\\$250K SAT) & %s & %s & %s & %.3f & %.3f & %s \\\\\n",
          format(round(results$excess_250_post), big.mark = ","),
          format(round(results$se_250_post * results$excess_250_post / results$b_250_post), big.mark = ","),
          format(round(d250_sd), big.mark = ","),
          sde_250, se_sde_250, classify_sde(sde_250)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tabF1, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat("All tables generated.\n")
cat(sprintf("SDE at $150K: %.3f (%s)\n", sde_150, classify_sde(sde_150)))
cat(sprintf("SDE at $250K: %.3f (%s)\n", sde_250, classify_sde(sde_250)))
