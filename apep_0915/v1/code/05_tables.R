## 05_tables.R — Generate all LaTeX tables
## apep_0915: HAP Emission Bunching at CAA Thresholds
## V1 format: ≤5 tables (no figures)

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

## --- Load all results ---
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "analysis_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ================================================================
## TABLE 1: Summary Statistics
## ================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Overall sample
sum_all <- panel[, .(
  mean_max_hap = mean(max_single_hap_tons),
  sd_max_hap = sd(max_single_hap_tons),
  mean_total_hap = mean(total_hap_tons),
  sd_total_hap = sd(total_hap_tons),
  mean_n_pollutants = mean(n_pollutants),
  pct_above_10 = mean(above_10ton) * 100,
  pct_above_25 = mean(above_25ton) * 100,
  n = .N,
  n_fac = uniqueN(facility_id)
)]

# By period
sum_period <- panel[, .(
  mean_max_hap = mean(max_single_hap_tons),
  sd_max_hap = sd(max_single_hap_tons),
  mean_total_hap = mean(total_hap_tons),
  sd_total_hap = sd(total_hap_tons),
  pct_above_10 = mean(above_10ton) * 100,
  pct_above_25 = mean(above_25ton) * 100,
  n = .N,
  n_fac = uniqueN(facility_id)
), by = .(period = ifelse(post_oiai == 1, "Post-2018", "Pre-2018"))]

# Near-threshold sample
did_sample <- panel[max_single_hap_tons >= 3 & max_single_hap_tons <= 25]
sum_near <- did_sample[, .(
  mean_max_hap = mean(max_single_hap_tons),
  sd_max_hap = sd(max_single_hap_tons),
  pct_above_10 = mean(above_10ton) * 100,
  n = .N,
  n_fac = uniqueN(facility_id)
), by = .(period = ifelse(post_oiai == 1, "Post-2018", "Pre-2018"))]

# Write Table 1
tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: NEI Facility-Level HAP Emissions}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{l",
  paste(rep("c", 4), collapse = ""), "}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Near-Threshold Sample} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Pre-2018 & Post-2018 & Pre-2018 & Post-2018 \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Emission Levels}} \\\\\n",
  sprintf("Max single HAP (tons) & %.2f & %.2f & %.2f & %.2f \\\\\n",
          sum_period[period == "Pre-2018"]$mean_max_hap,
          sum_period[period == "Post-2018"]$mean_max_hap,
          sum_near[period == "Pre-2018"]$mean_max_hap,
          sum_near[period == "Post-2018"]$mean_max_hap),
  sprintf(" & (%.2f) & (%.2f) & (%.2f) & (%.2f) \\\\\n",
          sum_period[period == "Pre-2018"]$sd_max_hap,
          sum_period[period == "Post-2018"]$sd_max_hap,
          sum_near[period == "Pre-2018"]$sd_max_hap,
          sum_near[period == "Post-2018"]$sd_max_hap),
  sprintf("Total HAP (tons) & %.2f & %.2f & --- & --- \\\\\n",
          sum_period[period == "Pre-2018"]$mean_total_hap,
          sum_period[period == "Post-2018"]$mean_total_hap),
  sprintf(" & (%.2f) & (%.2f) & & \\\\\n",
          sum_period[period == "Pre-2018"]$sd_total_hap,
          sum_period[period == "Post-2018"]$sd_total_hap),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Threshold Indicators}} \\\\\n",
  sprintf("\\%% above 10-ton threshold & %.1f & %.1f & %.1f & %.1f \\\\\n",
          sum_period[period == "Pre-2018"]$pct_above_10,
          sum_period[period == "Post-2018"]$pct_above_10,
          sum_near[period == "Pre-2018"]$pct_above_10,
          sum_near[period == "Post-2018"]$pct_above_10),
  sprintf("\\%% above 25-ton threshold & %.1f & %.1f & --- & --- \\\\\n",
          sum_period[period == "Pre-2018"]$pct_above_25,
          sum_period[period == "Post-2018"]$pct_above_25),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Sample Size}} \\\\\n",
  sprintf("Facility-years & %s & %s & %s & %s \\\\\n",
          format(sum_period[period == "Pre-2018"]$n, big.mark = ","),
          format(sum_period[period == "Post-2018"]$n, big.mark = ","),
          format(sum_near[period == "Pre-2018"]$n, big.mark = ","),
          format(sum_near[period == "Post-2018"]$n, big.mark = ",")),
  sprintf("Unique facilities & %s & %s & %s & %s \\\\\n",
          format(sum_period[period == "Pre-2018"]$n_fac, big.mark = ","),
          format(sum_period[period == "Post-2018"]$n_fac, big.mark = ","),
          format(sum_near[period == "Pre-2018"]$n_fac, big.mark = ","),
          format(sum_near[period == "Post-2018"]$n_fac, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard deviations in parentheses. ",
  "Full sample includes all NEI-reporting facilities with positive HAP emissions, 2012--2021. ",
  "Near-threshold sample restricts to facilities with max single-HAP emissions between 3 and 25 tons/year. ",
  "``Max single HAP'' is the highest emission of any individual HAP compound at the facility in a given year. ",
  "``Total HAP'' sums all HAP emissions at the facility. ",
  "The 10-ton and 25-ton thresholds are the CAA Section 112 major source cutoffs for single and combined HAPs, respectively.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))
cat("  Written tab1_summary.tex\n")

## ================================================================
## TABLE 2: Bunching Estimates (10-ton and 25-ton thresholds)
## ================================================================
cat("=== Table 2: Bunching Estimates ===\n")

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Bunching Estimates at HAP Major Source Thresholds}\n",
  "\\label{tab:bunching}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{10-Ton Threshold} & \\multicolumn{2}{c}{25-Ton Threshold} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Single HAP & Combined HAP & Single HAP & Combined HAP \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Normalized Excess Mass}} \\\\\n",
  sprintf("Pre-OIAI (2012--2017) & %.3f & & & %.3f \\\\\n",
          results$pre_bunch_10$normalized,
          results$pre_bunch_25$normalized),
  sprintf("Post-OIAI (2018--2021) & %.3f & & & %.3f \\\\\n",
          results$post_bunch_10$normalized,
          results$post_bunch_25$normalized),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Difference-in-Bunching}} \\\\\n",
  sprintf("$\\Delta$ Excess Mass & %.4f & & & %.4f \\\\\n",
          results$dib_10,
          results$dib_25),
  sprintf(" & (%.4f) & & & (%.4f) \\\\\n",
          results$boot_10$se,
          results$boot_25$se),
  sprintf(" & [%.4f, %.4f] & & & [%.4f, %.4f] \\\\\n",
          results$boot_10$ci_lo,
          results$boot_10$ci_hi,
          results$boot_25$ci_lo,
          results$boot_25$ci_hi),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Sample}} \\\\\n",
  sprintf("Facility-years in window & %s & & & %s \\\\\n",
          format(results$pre_bunch_10$actual + results$post_bunch_10$actual, big.mark = ","),
          format(results$pre_bunch_25$actual + results$post_bunch_25$actual, big.mark = ",")),
  "Polynomial order & 5 & & & 5 \\\\\n",
  "Bootstrap replications & 500 & & & 500 \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ",
  "Bunching estimates follow \\citet{Kleven2016}. ",
  "Normalized excess mass is the ratio of actual to counterfactual density just below each threshold. ",
  "The counterfactual distribution is estimated by fitting a 5th-order polynomial to bin counts outside the excluded region [8, 12] tons for the 10-ton threshold and [20, 30] tons for the 25-ton threshold. ",
  "Bootstrap standard errors in parentheses and 95\\% confidence intervals in brackets, ",
  "obtained by resampling facilities with replacement (500 replications). ",
  "The ``Once In Always In'' (OIAI) guidance was withdrawn on January 25, 2018.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(table_dir, "tab2_bunching.tex"))
cat("  Written tab2_bunching.tex\n")

## ================================================================
## TABLE 3: DiD Regression Results
## ================================================================
cat("=== Table 3: DiD Regression Results ===\n")

# Extract coefficients
did_main <- results$did_main
did_dist <- results$did_dist
did_event <- results$did_event

# Stars function
stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("^{***}")
  if (pval < 0.05) return("^{**}")
  if (pval < 0.10) return("^{*}")
  return("")
}

# Get p-values
# Get the coefficient name (interaction term)
coef_name <- names(coef(did_main))[1]  # near_threshold:post_oiai
pv_main <- pvalue(did_main)[coef_name]
pv_dist <- pvalue(did_dist)[coef_name]

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Difference-in-Differences: Effect of OIAI Withdrawal on Threshold Classification}\n",
  "\\label{tab:did}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & $\\mathbb{1}$[Below 10 tons] & Distance to 10 tons \\\\\n",
  "\\midrule\n",
  sprintf("Near $\\times$ Post-OIAI & $%.4f%s$ & $%.4f%s$ \\\\\n",
          coef(did_main)[coef_name], stars(pv_main),
          coef(did_dist)[coef_name], stars(pv_dist)),
  sprintf(" & (%.4f) & (%.4f) \\\\\n",
          se(did_main)[coef_name],
          se(did_dist)[coef_name]),
  "\\midrule\n",
  "Facility FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "Clustering & State & State \\\\\n",
  sprintf("Pre-treatment mean & %.3f & --- \\\\\n",
          results$mean_below10_pre),
  sprintf("Observations & %s & %s \\\\\n",
          format(nobs(did_main), big.mark = ","),
          format(nobs(did_dist), big.mark = ",")),
  sprintf("Facilities & %s & %s \\\\\n",
          format(results$n_near_10 / 10, big.mark = ","),  # approx
          format(results$n_near_10 / 10, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ",
  "Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Sample restricted to facilities with max single-HAP emissions between 3 and 25 tons/year. ",
  "Column (1): outcome is an indicator for having emissions below the 10-ton major source threshold. ",
  "Column (2): outcome is the distance (in tons) between the facility's max single-HAP emission and the 10-ton threshold ",
  "(negative values = below threshold). ",
  "All specifications include facility and year fixed effects.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(table_dir, "tab3_did.tex"))
cat("  Written tab3_did.tex\n")

## ================================================================
## TABLE 4: Heterogeneity (Manufacturing vs. Non-Manufacturing,
##           Strict vs. Non-Strict State Regulation)
## ================================================================
cat("=== Table 4: Heterogeneity ===\n")

het_coef_name <- names(coef(results$did_mfg))[1]
pv_mfg <- pvalue(results$did_mfg)[het_coef_name]
pv_nonmfg <- pvalue(results$did_nonmfg)[het_coef_name]
pv_strict <- pvalue(results$did_strict)[het_coef_name]
pv_nonstrict <- pvalue(results$did_nonstrict)[het_coef_name]

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Heterogeneity: OIAI Withdrawal Effects by Sector and State Regulation}\n",
  "\\label{tab:hetero}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Manufacturing & Non-Mfg & Strict States & Non-Strict \\\\\n",
  "\\midrule\n",
  sprintf("Near $\\times$ Post & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\\n",
          coef(results$did_mfg)[het_coef_name], stars(pv_mfg),
          coef(results$did_nonmfg)[het_coef_name], stars(pv_nonmfg),
          coef(results$did_strict)[het_coef_name], stars(pv_strict),
          coef(results$did_nonstrict)[het_coef_name], stars(pv_nonstrict)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(results$did_mfg)[het_coef_name], se(results$did_nonmfg)[het_coef_name],
          se(results$did_strict)[het_coef_name], se(results$did_nonstrict)[het_coef_name]),
  "\\midrule\n",
  "Facility FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Clustering & State & State & State & State \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(results$did_mfg), big.mark = ","),
          format(nobs(results$did_nonmfg), big.mark = ","),
          format(nobs(results$did_strict), big.mark = ","),
          format(nobs(results$did_nonstrict), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ",
  "Outcome is $\\mathbb{1}$[below 10-ton threshold]. ",
  "Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Manufacturing includes NAICS 31--33. ",
  "``Strict states'' are those with their own HAP regulatory programs (CA, NJ, MA, NY, CT, ME, OR, WA). ",
  "All specifications include facility and year fixed effects. ",
  "Sample restricted to facilities with max single-HAP emissions between 3 and 25 tons/year.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(table_dir, "tab4_heterogeneity.tex"))
cat("  Written tab4_heterogeneity.tex\n")

## ================================================================
## TABLE 5: Robustness
## ================================================================
cat("=== Table 5: Robustness ===\n")

# Donut
donut_coef <- names(coef(robust$donut))[1]
placebo_coef <- names(coef(robust$placebo_time))[1]
fac_coef <- names(coef(robust$clustering$facility))[1]
naics_coef <- names(coef(robust$clustering$naics))[1]
pv_donut <- pvalue(robust$donut)[donut_coef]
pv_placebo <- pvalue(robust$placebo_time)[placebo_coef]
pv_fac <- pvalue(robust$clustering$facility)[fac_coef]
pv_naics <- pvalue(robust$clustering$naics)[naics_coef]

tab5 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Donut DiD & Placebo 2015 & Cluster: Facility & Cluster: NAICS \\\\\n",
  "\\midrule\n",
  sprintf("Near $\\times$ Post / Placebo & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\\n",
          coef(robust$donut)[donut_coef], stars(pv_donut),
          coef(robust$placebo_time)[placebo_coef], stars(pv_placebo),
          coef(robust$clustering$facility)[fac_coef], stars(pv_fac),
          coef(robust$clustering$naics)[naics_coef], stars(pv_naics)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(robust$donut)[donut_coef], se(robust$placebo_time)[placebo_coef],
          se(robust$clustering$facility)[fac_coef], se(robust$clustering$naics)[naics_coef]),
  "\\midrule\n",
  "Facility FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(robust$donut), big.mark = ","),
          format(nobs(robust$placebo_time), big.mark = ","),
          format(nobs(robust$clustering$facility), big.mark = ","),
          format(nobs(robust$clustering$naics), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ",
  "Outcome is $\\mathbb{1}$[below 10-ton threshold] in all columns. ",
  "Standard errors in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Column (1): excludes facilities within 1 ton of the threshold (9--11 tons). ",
  "Column (2): placebo treatment at 2015 using pre-period data only (2012--2017). ",
  "Columns (3)--(4): alternative clustering levels (facility and 2-digit NAICS). ",
  "Baseline clustering is at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab5, file.path(table_dir, "tab5_robustness.tex"))
cat("  Written tab5_robustness.tex\n")

## ================================================================
## SDE TABLE (Appendix F1)
## ================================================================
cat("=== SDE Table ===\n")

# Main outcome: below 10-ton indicator
sde_coef_name <- names(coef(results$did_main))[1]
beta_main <- coef(results$did_main)[sde_coef_name]
se_main <- se(results$did_main)[sde_coef_name]
sd_y_main <- results$sd_below10

sde_main <- beta_main / sd_y_main
se_sde_main <- se_main / sd_y_main

# Classification function
classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Heterogeneity: manufacturing
het_sde_name <- names(coef(results$did_mfg))[1]
beta_mfg <- coef(results$did_mfg)[het_sde_name]
se_mfg <- se(results$did_mfg)[het_sde_name]
did_data_mfg <- panel[max_single_hap_tons >= 3 & max_single_hap_tons <= 25]
did_data_mfg[, below_10 := as.integer(max_single_hap_tons < 10)]
did_data_mfg[, naics_2digit := substr(as.character(naics), 1, 2)]
did_data_mfg[, manufacturing := as.integer(naics_2digit %in% c("31", "32", "33"))]
sd_y_mfg <- sd(did_data_mfg[manufacturing == 1]$below_10)
sde_mfg <- beta_mfg / sd_y_mfg
se_sde_mfg <- se_mfg / sd_y_mfg

# Heterogeneity: non-manufacturing
beta_nonmfg <- coef(results$did_nonmfg)[het_sde_name]
se_nonmfg <- se(results$did_nonmfg)[het_sde_name]
sd_y_nonmfg <- sd(did_data_mfg[manufacturing == 0]$below_10)
sde_nonmfg <- beta_nonmfg / sd_y_nonmfg
se_sde_nonmfg <- se_nonmfg / sd_y_nonmfg

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the removal of the ``Once In Always In'' regulatory constraint cause industrial facilities to strategically reduce reported hazardous air pollutant emissions below the Clean Air Act major source threshold? ",
  "\\textbf{Policy mechanism:} The 2018 EPA withdrawal of the OIAI guidance removed the rule that facilities classified as major HAP sources must permanently remain under costly MACT standards, creating a new escape hatch that allows major sources to reclassify as area sources by reducing any single HAP below 10 tons per year. ",
  "\\textbf{Outcome definition:} Binary indicator equal to one if a facility's highest individual HAP emission is below the 10-ton-per-year major source threshold in the NEI annual facility summary. ",
  "\\textbf{Treatment:} Binary; equal to one for all facility-years after January 25, 2018 (OIAI withdrawal date). ",
  "\\textbf{Data:} EPA National Emissions Inventory Facility Summaries, 2012--2021, facility-by-year panel. ",
  "\\textbf{Method:} Two-way fixed effects (facility and year FE), state-clustered standard errors. ",
  "\\textbf{Sample:} Facilities with max single-HAP emissions between 3 and 25 tons per year (near-threshold sample). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$). ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis."
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Below 10-ton & Baseline & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_main, sd_y_main, sde_main, se_sde_main, classify_sde(sde_main)),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("Below 10-ton & Manufacturing & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_mfg, sd_y_mfg, sde_mfg, se_sde_mfg, classify_sde(sde_mfg)),
  sprintf("Below 10-ton & Non-Manufacturing & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_nonmfg, sd_y_nonmfg, sde_nonmfg, se_sde_nonmfg, classify_sde(sde_nonmfg)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
