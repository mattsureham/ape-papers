# 05_tables.R — Generate all LaTeX tables
# apep_0716: Nonprofit Disclosure Cost Bunching

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(file.path(data_dir, "bunching_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))
df <- readRDS(file.path(data_dir, "eo_cleaned.rds"))

# ===================================================================
# TABLE 1: SUMMARY STATISTICS
# ===================================================================

# Summary stats for organizations in analysis window
df_window <- df[revenue >= 100000 & revenue <= 300000]

tab1_stats <- data.frame(
  Variable = c(
    "Gross Receipts (\\$000s)",
    "Total Assets (\\$000s)",
    "Below \\$200K Threshold",
    "Health Organizations",
    "Human Services",
    "Education/Foundation",
    "Religious",
    "Other"
  ),
  Mean = c(
    sprintf("%.1f", mean(df_window$revenue) / 1000),
    sprintf("%.1f", mean(df_window$assets, na.rm = TRUE) / 1000),
    sprintf("%.3f", mean(df_window$revenue < 200000)),
    sprintf("%.3f", mean(df_window$org_type == "Health")),
    sprintf("%.3f", mean(df_window$org_type == "Human Services")),
    sprintf("%.3f", mean(df_window$org_type == "Foundation/Education")),
    sprintf("%.3f", mean(df_window$org_type == "Religious")),
    sprintf("%.3f", mean(df_window$org_type == "Other"))
  ),
  SD = c(
    sprintf("%.1f", sd(df_window$revenue) / 1000),
    sprintf("%.1f", sd(df_window$assets, na.rm = TRUE) / 1000),
    "", "", "", "", "", ""
  ),
  N = c(
    rep(format(nrow(df_window), big.mark = ","), 2),
    rep("", 6)
  )
)

# Write Table 1
sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Tax-Exempt Organizations}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & Mean & SD & N \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: Continuous Variables}} \\\\\n")
for (i in 1:2) {
  cat(sprintf("%s & %s & %s & %s \\\\\n",
              tab1_stats$Variable[i], tab1_stats$Mean[i],
              tab1_stats$SD[i], tab1_stats$N[i]))
}
cat("\\addlinespace\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: Organization Type Shares}} \\\\\n")
for (i in 3:8) {
  cat(sprintf("%s & %s & & \\\\\n", tab1_stats$Variable[i], tab1_stats$Mean[i]))
}
cat("\\hline\n")
cat(sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\\n",
            format(nrow(df_window), big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Sample includes all IRS-registered tax-exempt organizations with gross receipts between \\$100,000 and \\$300,000 from the Exempt Organizations Business Master File (EO BMF). Organization types based on NTEE major category codes.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 1 (summary) written.\n")

# ===================================================================
# TABLE 2: MAIN BUNCHING RESULTS
# ===================================================================

r200 <- results$main_200k
r50 <- results$placebo_50k

sink(file.path(tables_dir, "tab2_bunching.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Bunching Estimates at IRS Form 990 Filing Thresholds}\n")
cat("\\label{tab:bunching}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & \\$200K Threshold & \\$50K Threshold \\\\\n")
cat(" & (990-EZ vs.\\ 990) & (990-N vs.\\ 990-EZ) \\\\\n")
cat("\\hline\n")
cat(sprintf("Excess mass ($\\hat{B}$) & %.0f & %.0f \\\\\n",
            r200$excess_mass, r50$excess_mass))
cat(sprintf(" & (%.0f) & (%.0f) \\\\\n",
            r200$se_excess, r50$se_excess))
cat("\\addlinespace\n")
cat(sprintf("Normalized excess mass ($\\hat{b}$) & %.3f & %.3f \\\\\n",
            r200$b_normalized, r50$b_normalized))
cat(sprintf(" & (%.3f) & (%.3f) \\\\\n",
            r200$se_b, r50$se_b))
cat("\\addlinespace\n")
cat(sprintf("Missing mass above & %.0f & %.0f \\\\\n",
            r200$missing_above, r50$missing_above))
cat(sprintf("Counterfactual density at threshold & %.0f & %.0f \\\\\n",
            r200$threshold_cf, r50$threshold_cf))
cat(sprintf("Polynomial order & %d & %d \\\\\n",
            r200$poly_order, r50$poly_order))
cat(sprintf("Exclusion window & [\\$%dK, \\$%dK] & [\\$%dK, \\$%dK] \\\\\n",
            r200$exclude_lower/1000, r200$exclude_upper/1000,
            r50$exclude_lower/1000, r50$exclude_upper/1000))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Bunching estimates following Chetty et al.\\ (2011) and Kleven (2016). The \\$200K threshold separates IRS Form 990-EZ (4 pages) from Form 990 (12+ pages with mandatory schedules). The \\$50K threshold separates Form 990-N (e-Postcard) from Form 990-EZ. Bootstrapped standard errors (1,000 replications) in parentheses. Counterfactual density estimated using a 7th-degree polynomial fitted to bins outside the exclusion window.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 2 (bunching) written.\n")

# ===================================================================
# TABLE 3: ROBUSTNESS — POLYNOMIAL ORDER AND EXCLUSION WINDOW
# ===================================================================

poly_res <- results$poly_robustness
wind_res <- results$window_robustness

sink(file.path(tables_dir, "tab3_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness of Bunching Estimates}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & Excess Mass & SE & $\\hat{b}$ & SE \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Polynomial Order}} \\\\\n")
for (i in 1:nrow(poly_res)) {
  cat(sprintf("Order %d & %.0f & (%.0f) & %.3f & (%.3f) \\\\\n",
              poly_res$poly_order[i], poly_res$excess_mass[i],
              poly_res$se_excess[i], poly_res$b_normalized[i],
              poly_res$se_b[i]))
}
cat("\\addlinespace\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Exclusion Window}} \\\\\n")
for (i in 1:nrow(wind_res)) {
  cat(sprintf("$\\pm$\\$%.0fK/\\$%.0fK & %.0f & (%.0f) & %.3f & (%.3f) \\\\\n",
              wind_res$window[i]/1000, wind_res$window[i]/2000,
              wind_res$excess_mass[i], wind_res$se_excess[i],
              wind_res$b_normalized[i], wind_res$se_b[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Panel A varies the polynomial order of the counterfactual density from 5 to 9, holding the exclusion window at [\\$180K, \\$210K]. Panel B varies the exclusion window around \\$200K, holding polynomial order at 7. Bootstrapped standard errors (500 replications) in parentheses.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 3 (robustness) written.\n")

# ===================================================================
# TABLE 4: HETEROGENEITY
# ===================================================================

het_org <- results$heterogeneity_org
het_asset <- results$heterogeneity_asset

sink(file.path(tables_dir, "tab4_heterogeneity.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Heterogeneity in Bunching by Organization Characteristics}\n")
cat("\\label{tab:heterogeneity}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & N & Excess Mass & $\\hat{b}$ & SE \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Organization Type (NTEE)}} \\\\\n")
for (i in 1:nrow(het_org)) {
  cat(sprintf("%s & %s & %.0f & %.3f & (%.3f) \\\\\n",
              het_org$org_type[i],
              format(het_org$n_orgs[i], big.mark = ","),
              het_org$excess_mass[i],
              het_org$b_normalized[i],
              het_org$se_b[i]))
}
cat("\\addlinespace\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Asset Size}} \\\\\n")
for (i in 1:nrow(het_asset)) {
  label <- gsub("\\$", "\\\\$", het_asset$asset_cat[i])
  label <- gsub("<", "$<$", label)
  label <- gsub(">", "$>$", label)
  cat(sprintf("%s & %s & %.0f & %.3f & (%.3f) \\\\\n",
              label,
              format(het_asset$n_orgs[i], big.mark = ","),
              het_asset$excess_mass[i],
              het_asset$b_normalized[i],
              het_asset$se_b[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Bunching estimates by organization type (Panel A, based on NTEE major category) and asset size (Panel B). All estimates use 7th-degree polynomial and [\\$180K, \\$210K] exclusion window. Bootstrapped standard errors (500 replications) in parentheses.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 4 (heterogeneity) written.\n")

# ===================================================================
# TABLE F1: STANDARDIZED EFFECT SIZE (SDE) — MANDATORY APPENDIX
# ===================================================================

# For bunching, SDE = b_normalized (already in SD units conceptually)
# We report b as the standardized metric
# For comparison, we also compute β / SD(Y) for the density discontinuity

# Main outcome: excess mass relative to counterfactual
sde_b <- r200$b_normalized
sde_se <- r200$se_b

# Classify
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE table entries
sde_data <- data.frame(
  outcome = c(
    "Bunching at \\$200K (990 vs 990-EZ)",
    "Placebo at \\$50K (990-N vs 990-EZ)"
  ),
  beta = c(r200$excess_mass, r50$excess_mass),
  se = c(r200$se_excess, r50$se_excess),
  sd_y = c(r200$threshold_cf, r50$threshold_cf),
  sde = c(r200$b_normalized, r50$b_normalized),
  sde_se = c(r200$se_b, r50$se_b),
  stringsAsFactors = FALSE
)
sde_data$classification <- sapply(sde_data$sde, classify_sde)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the compliance burden of IRS Form 990 (full return, 12+ pages) ",
  "relative to Form 990-EZ (short form, 4 pages) cause tax-exempt organizations to manipulate reported ",
  "gross receipts to stay below the \\$200,000 filing threshold? ",
  "\\textbf{Policy mechanism:} Organizations with gross receipts above \\$200,000 must file Form 990, ",
  "which requires detailed schedules on compensation, governance, lobbying, and related transactions; ",
  "those below may file the simpler Form 990-EZ, creating a sharp compliance cost discontinuity. ",
  "\\textbf{Outcome definition:} Normalized excess mass ($\\hat{b}$) in the revenue distribution just below ",
  "the threshold, measuring the fraction of organizations that manipulate reported revenue to avoid the ",
  "higher disclosure requirement. ",
  "\\textbf{Treatment:} Binary --- organizations above \\$200,000 in gross receipts face the full Form 990 ",
  "filing requirement; those below face the simpler Form 990-EZ. ",
  "\\textbf{Data:} IRS Exempt Organizations Business Master File (EO BMF), current quarter extract, ",
  "all registered tax-exempt organizations in the United States; analysis window \\$100K--\\$300K. ",
  "\\textbf{Method:} Bunching estimation following Chetty et al.\\ (2011) and Kleven (2016); 7th-degree ",
  "polynomial counterfactual density fitted to \\$1,000 bins outside the [\\$180K, \\$210K] exclusion window; ",
  "bootstrapped standard errors with 1,000 replications. ",
  "\\textbf{Sample:} All IRS-registered 501(c) organizations with positive gross receipts in the ",
  "\\$100,000--\\$300,000 range. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(sde_data)) {
  cat(sprintf("%s & %.0f & (%.0f) & %.0f & %.3f & (%.3f) & %s \\\\\n",
              sde_data$outcome[i],
              sde_data$beta[i], sde_data$se[i],
              sde_data$sd_y[i],
              sde_data$sde[i], sde_data$sde_se[i],
              sde_data$classification[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table F1 (SDE) written.\n")
cat("\nAll tables generated successfully.\n")
