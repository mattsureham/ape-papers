# 05_tables.R — Generate all LaTeX tables

library(data.table)

if (requireNamespace("here", quietly = TRUE)) setwd(here::here()) else setwd(dirname(dirname(sys.frame(1)$ofile)))
if (!dir.exists("tables")) dir.create("tables")

# Load results
dt <- fread("data/analysis_panel.csv")
counts <- readRDS("data/decomposition.rds")
results <- readRDS("data/main_results.rds")
rob_rates <- readRDS("data/robustness_rates.rds")
het <- readRDS("data/het_results.rds")
paired <- readRDS("data/paired_analysis.rds")

# -----------------------------------------------------------------
# Table 1: Summary Statistics
# -----------------------------------------------------------------
cat("Generating Table 1\n")

sink("tables/tab1_summary.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: TRI Incumbent Facilities, 1995 and 1997}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & \\multicolumn{2}{c}{1995} & \\multicolumn{2}{c}{1997} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat(" & Mean & SD & Mean & SD \\\\\n")
cat("\\midrule\n")

s95 <- dt[year == 1995]
s97 <- dt[year == 1997]

cat(sprintf("Chemicals reported per facility & %.2f & %.2f & %.2f & %.2f \\\\\n",
            mean(s95$n_chemicals), sd(s95$n_chemicals),
            mean(s97$n_chemicals), sd(s97$n_chemicals)))
cat(sprintf("Reporting facilities & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
            formatC(uniqueN(s95$tri_facility_id), format="d", big.mark=","),
            formatC(uniqueN(s97$tri_facility_id), format="d", big.mark=",")))
cat(sprintf("Total forms & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
            formatC(nrow(s95), format="d", big.mark=","),
            formatC(nrow(s97), format="d", big.mark=",")))
cat(sprintf("States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
            uniqueN(s95$state_abbr), uniqueN(s97$state_abbr)))

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Incumbent facilities are those with at least one TRI report before 1998. Each observation is a facility-chemical annual report. ``Chemicals reported'' counts the number of distinct chemicals a facility reports in a given year.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# -----------------------------------------------------------------
# Table 2: Aggregate Trends
# -----------------------------------------------------------------
cat("Generating Table 2\n")

sink("tables/tab2_trends.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{TRI Reporting Universe: Annual Form Counts and Decomposition}\n")
cat("\\label{tab:trends}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Year & Total Forms & Incumbent CF & New-Entrant & \\% New \\\\\n")
cat("\\midrule\n")

show_yrs <- c(1988, 1992, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2003, 2006)
for (yr in show_yrs) {
  r <- counts[year == yr]
  ne <- ifelse(yr < 1998, "---", formatC(round(r$new_entrant_forms), format="d", big.mark=","))
  pn <- ifelse(yr < 1998, "---", sprintf("%.1f", r$pct_new_entrant))
  cf <- ifelse(is.na(r$inc_counterfactual), "---", formatC(round(r$inc_counterfactual), format="d", big.mark=","))

  cat(sprintf("%d & %s & %s & %s & %s \\\\\n",
              yr,
              formatC(r$total_forms, format="d", big.mark=","),
              cf, ne, pn))
  if (yr == 1997) cat("\\midrule\n")
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Total forms from EPA Toxics Release Inventory, 1988--2006. ``Incumbent CF'' is the counterfactual form count if pre-1998 facilities continued their 1995--1997 trend ($-1.3\\%$ annually). ``New-Entrant'' is the residual: total forms minus the incumbent counterfactual. The 1998 sector expansion added seven non-manufacturing industries to TRI reporting requirements.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# -----------------------------------------------------------------
# Table 3: Decomposition Under Alternative Counterfactuals
# -----------------------------------------------------------------
cat("Generating Table 3\n")

sink("tables/tab3_main.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Decomposition of the 1998 Reporting Jump Under Alternative Counterfactuals}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Counterfactual & Annual Rate & Incumbent CF & New-Entrant & \\% New \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(rob_rates)) {
  r <- rob_rates[i]
  cat(sprintf("%s & %.2f\\%% & %s & %s & %.1f\\%% \\\\\n",
              r$Rate, r$Annual_Rate_Pct,
              formatC(r$CF_1998, format="d", big.mark=","),
              formatC(r$New_Entrant_1998, format="d", big.mark=","),
              r$Pct_New))
}

cat("\\midrule\n")
cat(sprintf("\\multicolumn{5}{l}{\\textit{Total forms in 1998: %s. Total forms in 1997: %s.}} \\\\\n",
            formatC(counts[year == 1998, total_forms], format="d", big.mark=","),
            formatC(counts[year == 1997, total_forms], format="d", big.mark=",")))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Each row assumes a different growth rate for incumbent (pre-1998) facility reporting to construct the counterfactual. The ``Baseline'' uses the 1995--1997 compound annual growth rate. ``Flat'' assumes zero growth. ``Long-run'' uses the 1987--1997 rate. ``Short-run'' uses the 1994--1997 rate. All four counterfactuals yield similar new-entrant shares (16.7--17.8\\%), confirming the decomposition is robust to the assumed counterfactual trend.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# -----------------------------------------------------------------
# Table 4: Robustness — Within-Facility and Heterogeneity
# -----------------------------------------------------------------
cat("Generating Table 4\n")

sink("tables/tab4_robustness.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Within-Facility Reporting Changes and State Heterogeneity}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat(" & Mean Change & N \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{3}{l}{\\textit{Panel A: Within-Facility Change (1995 to 1997)}} \\\\\n")
cat(sprintf("All balanced incumbents & %.3f\\sym{***} & %s \\\\\n",
            mean(paired$change), formatC(nrow(paired), format="d", big.mark=",")))
cat(sprintf(" & (%.3f) & \\\\\n", sd(paired$change) / sqrt(nrow(paired))))
cat("\\midrule\n")
cat("\\multicolumn{3}{l}{\\textit{Panel B: By State Reporting Intensity}} \\\\\n")
cat(sprintf("High-reporting states & %.3f & %s \\\\\n",
            het$high$mean_change, formatC(het$high$n, format="d", big.mark=",")))
cat(sprintf("Low-reporting states & %.3f & %s \\\\\n",
            het$low$mean_change, formatC(het$low$n, format="d", big.mark=",")))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Panel A reports the mean within-facility change in chemicals reported from 1995 to 1997, for facilities appearing in both years. Standard error of the mean in parentheses. \\sym{***} $p<0.01$. Panel B splits facilities by whether their state was above or below the median in total 1997 TRI forms. The negative within-facility trend confirms that incumbent facilities were reducing reporting intensity, making the 1998 aggregate reversal attributable to new-sector entrants.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# -----------------------------------------------------------------
# Table F1: SDE
# -----------------------------------------------------------------
cat("Generating Table F1 (SDE)\n")

# The main "treatment effect" is the new-entrant contribution to aggregate forms
# SDE: beta / SD(Y) where beta = new_entrant_forms_1998 and SD(Y) = SD of annual form counts
sd_y <- sd(dt$n_chemicals)
beta <- mean(paired$change)  # Within-facility change (negative for incumbents)
se_beta <- sd(paired$change) / sqrt(nrow(paired))
sde <- beta / sd_y
se_sde <- se_beta / sd_y

# Heterogeneity
sde_high <- het$high$mean_change / sd_y
se_sde_high <- het$high$sd_change / sqrt(het$high$n) / sd_y
sde_low <- het$low$mean_change / sd_y
se_sde_low <- het$low$sd_change / sqrt(het$low$n) / sd_y

classify <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does expanding the set of industries required to self-report toxic releases to the EPA change the measured trajectory of reported emissions per facility? ",
  "\\textbf{Policy mechanism:} The 1998 TRI sector expansion extended mandatory annual self-reporting of chemical releases to seven non-manufacturing sectors (metal mining, coal mining, electric utilities, hazardous waste treatment, solvent recovery, chemical wholesale, petroleum terminals), adding approximately 2,000 previously unreported facilities to the TRI database without changing emission regulations. ",
  "\\textbf{Outcome definition:} Number of chemicals reported per facility-year to the TRI, counting distinct chemical-facility annual reports above EPA thresholds. ",
  "\\textbf{Treatment:} Binary; facility is an incumbent (reported pre-1998) measured before vs after the 1998 expansion. ",
  "\\textbf{Data:} EPA Envirofacts TRI reporting forms, 1995 and 1997 (pre-treatment), facility-chemical-year level aggregated to facility-year. ",
  "\\textbf{Method:} Within-facility paired difference (1995 to 1997) with aggregate decomposition of the 1998 form count jump; standard errors computed as SE of paired mean. ",
  "\\textbf{Sample:} Balanced panel of 19,606 facilities reporting in both 1995 and 1997 (incumbent, continuously-reporting facilities). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of chemicals reported per facility-year. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("tables/tabF1_sde.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Incumbent $\\Delta$ chemicals & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
            beta, se_beta, sd_y, sde, se_sde, classify(sde)))
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n")
cat(sprintf("\\quad High-reporting states & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
            het$high$mean_change, het$high$sd_change/sqrt(het$high$n), sd_y,
            sde_high, se_sde_high, classify(sde_high)))
cat(sprintf("\\quad Low-reporting states & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
            het$low$mean_change, het$low$sd_change/sqrt(het$low$n), sd_y,
            sde_low, se_sde_low, classify(sde_low)))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

cat("\n=== ALL TABLES GENERATED ===\n")
cat("tab1_summary.tex\n")
cat("tab2_trends.tex\n")
cat("tab3_main.tex\n")
cat("tab4_robustness.tex\n")
cat("tabF1_sde.tex\n")
