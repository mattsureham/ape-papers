## 05_tables.R — Generate all tables for the paper
## apep_0731: Nonprofit bunching at state audit thresholds

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

bmf_clean <- fread(file.path(data_dir, "bmf_clean.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ══════════════════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ══════════════════════════════════════════════════════════════════════════

## Summary by audit mandate status
summ <- bmf_clean[revenue > 0, .(
  N = format(.N, big.mark = ","),
  Mean_Rev = paste0("\\$", format(round(mean(revenue)), big.mark = ",")),
  Median_Rev = paste0("\\$", format(round(median(revenue)), big.mark = ",")),
  SD_Rev = paste0("\\$", format(round(sd(revenue)), big.mark = ",")),
  Pct_Below_1M = paste0(round(mean(revenue < 1000000) * 100, 1), "\\%")
), by = .(Group = fifelse(has_audit_mandate, "Audit-Mandate States", "No-Mandate States"))]

## Add overall row
overall <- bmf_clean[revenue > 0, .(
  Group = "All Organizations",
  N = format(.N, big.mark = ","),
  Mean_Rev = paste0("\\$", format(round(mean(revenue)), big.mark = ",")),
  Median_Rev = paste0("\\$", format(round(median(revenue)), big.mark = ",")),
  SD_Rev = paste0("\\$", format(round(sd(revenue)), big.mark = ",")),
  Pct_Below_1M = paste0(round(mean(revenue < 1000000) * 100, 1), "\\%")
)]

summ_all <- rbind(summ, overall)

## Generate LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Tax-Exempt Organizations by State Audit Mandate}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & $N$ & Mean Rev. & Median Rev. & SD Rev. & \\% Below \\$1M \\\\",
  "\\hline"
)
for (i in 1:nrow(summ_all)) {
  tab1_lines <- c(tab1_lines,
    paste0(summ_all$Group[i], " & ", summ_all$N[i], " & ",
           summ_all$Mean_Rev[i], " & ", summ_all$Median_Rev[i], " & ",
           summ_all$SD_Rev[i], " & ", summ_all$Pct_Below_1M[i], " \\\\"))
}
tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Data from IRS Exempt Organizations Business Master File (2024). Revenue is annual total revenue (\\texttt{REVENUE\\_AMT}). Audit-mandate states are those requiring independent CPA audit above a state-specific revenue threshold. Sample restricted to organizations with positive reported revenue.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

## ══════════════════════════════════════════════════════════════════════════
## TABLE 2: Pooled bunching estimates by threshold group
## ══════════════════════════════════════════════════════════════════════════

by_state <- results$by_state
threshold_groups <- by_state[, .(
  N_States = .N,
  N_Orgs = format(sum(n_orgs), big.mark = ","),
  Mean_Bunching = round(mean(bunching_ratio), 3),
  Median_Bunching = round(median(bunching_ratio), 3),
  Min_Bunching = round(min(bunching_ratio), 3),
  Max_Bunching = round(max(bunching_ratio), 3)
), by = threshold]
threshold_groups <- threshold_groups[order(threshold)]

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Bunching Estimates by State Audit Threshold Level}",
  "\\label{tab:bunching_by_threshold}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Threshold & States & Orgs. & Mean $\\hat{b}$ & Median $\\hat{b}$ & Min $\\hat{b}$ & Max $\\hat{b}$ \\\\",
  "\\hline"
)
for (i in 1:nrow(threshold_groups)) {
  thr_label <- paste0("\\$", formatC(threshold_groups$threshold[i], format = "f", digits = 0, big.mark = ","))
  tab2_lines <- c(tab2_lines,
    paste0(thr_label, " & ",
           threshold_groups$N_States[i], " & ",
           threshold_groups$N_Orgs[i], " & ",
           threshold_groups$Mean_Bunching[i], " & ",
           threshold_groups$Median_Bunching[i], " & ",
           threshold_groups$Min_Bunching[i], " & ",
           threshold_groups$Max_Bunching[i], " \\\\"))
}
tab2_lines <- c(tab2_lines,
  "\\hline",
  paste0("Pooled \\$500K & ", results$pooled_500k$n_states, " & ",
         format(results$pooled_500k$n_orgs, big.mark = ","), " & ",
         round(results$pooled_500k$bunching_ratio, 3), " & --- & --- & --- \\\\"),
  paste0(" & & & (", round(results$pooled_500k$se, 3), ") & & & \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Bunching ratio $\\hat{b}$ is the excess mass below the threshold divided by the average counterfactual bin count, estimated using a degree-7 polynomial. The pooled estimate uses organizations from all states with a \\$500,000 threshold. Bootstrap standard error (500 replications, resampling within state) in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, file.path(tables_dir, "tab2_bunching.tex"))
cat("Table 2 written.\n")

## ══════════════════════════════════════════════════════════════════════════
## TABLE 3: Difference-in-bunching (audit vs no-audit states)
## ══════════════════════════════════════════════════════════════════════════

dib <- results$dib
tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Difference-in-Bunching: Audit-Mandate vs.\\ No-Mandate States at \\$500,000}",
  "\\label{tab:dib}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Below \\$500K & Above \\$500K \\\\",
  " & (\\$475K--\\$500K) & (\\$500K--\\$525K) \\\\",
  "\\hline",
  paste0("Audit-mandate states & ", round(dib$mandate_below, 5),
         " & ", round(dib$mandate_above, 5), " \\\\"),
  paste0("No-mandate states & ", round(dib$no_mandate_below, 5),
         " & ", round(dib$no_mandate_above, 5), " \\\\"),
  "\\hline",
  paste0("Difference-in-bunching & \\multicolumn{2}{c}{",
         round(dib$dib_estimate, 5), "} \\\\"),
  paste0(" & \\multicolumn{2}{c}{(",
         round(dib$dib_se, 5), ")} \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Cells report the fraction of each group's organizations in the given revenue bin. The difference-in-bunching is $(d^{\\text{mandate}}_{\\text{below}} - d^{\\text{no-mandate}}_{\\text{below}}) - (d^{\\text{mandate}}_{\\text{above}} - d^{\\text{no-mandate}}_{\\text{above}})$. Bootstrap standard error (500 replications, resampling within state) in parentheses. Positive values indicate excess bunching attributable to audit mandates rather than round-number effects.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(tables_dir, "tab3_dib.tex"))
cat("Table 3 written.\n")

## ══════════════════════════════════════════════════════════════════════════
## TABLE 4: Robustness — Polynomial order and donut specifications
## ══════════════════════════════════════════════════════════════════════════

poly_dt <- robustness$polynomial
donut_dt <- robustness$donut

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Polynomial Order and Excluded-Region Sensitivity}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc|lcc}",
  "\\hline\\hline",
  "\\multicolumn{3}{c|}{Panel A: Polynomial Order} & \\multicolumn{3}{c}{Panel B: Excluded Region} \\\\",
  "Order & Excess Mass & $\\hat{b}$ & Width & Excess Mass & $\\hat{b}$ \\\\",
  "\\hline"
)

max_rows <- max(nrow(poly_dt), nrow(donut_dt))
for (i in 1:max_rows) {
  left_part <- if (i <= nrow(poly_dt)) {
    paste0(poly_dt$poly_order[i], " & ", poly_dt$excess_mass[i], " & ", poly_dt$bunching_ratio[i])
  } else "& &"

  right_part <- if (i <= nrow(donut_dt)) {
    paste0("\\$", format(donut_dt$donut_width[i], big.mark = ","), " & ",
           donut_dt$excess_mass[i], " & ", donut_dt$bunching_ratio[i])
  } else "& &"

  tab4_lines <- c(tab4_lines, paste0(left_part, " & ", right_part, " \\\\"))
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A varies the polynomial order of the counterfactual density estimator from 5 to 9. Panel B varies the width of the excluded region around the \\$500,000 threshold. The baseline specification uses polynomial order 7 and a \\$25,000 excluded region. All estimates use organizations from states with a \\$500,000 audit threshold.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

## ══════════════════════════════════════════════════════════════════════════
## TABLE 5: Placebo tests at round numbers in no-audit states
## ══════════════════════════════════════════════════════════════════════════

placebo_dt <- robustness$placebo

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Placebo Bunching at Round-Number Thresholds in No-Mandate States}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Placebo Threshold & Excess Mass & Bunching Ratio $\\hat{b}$ \\\\",
  "\\hline"
)

if (!is.null(placebo_dt) && nrow(placebo_dt) > 0) {
  for (i in 1:nrow(placebo_dt)) {
    thr_label <- paste0("\\$", format(placebo_dt$threshold[i], big.mark = ","))
    tab5_lines <- c(tab5_lines,
      paste0(thr_label, " & ", placebo_dt$excess_mass[i], " & ",
             placebo_dt$bunching_ratio[i], " \\\\"))
  }
}

## Add the $500K placebo in no-mandate states
if (!is.null(results$placebo_500k)) {
  tab5_lines <- c(tab5_lines,
    paste0("\\$500,000 (no-mandate) & ",
           round(results$placebo_500k$excess_mass, 1), " & ",
           round(results$placebo_500k$bunching_ratio, 3), " \\\\"))
}

## Add the real $500K estimate for comparison
tab5_lines <- c(tab5_lines,
  "\\hline",
  paste0("\\textit{Actual \\$500K threshold} & ",
         round(results$pooled_500k$excess_mass, 1), " & ",
         round(results$pooled_500k$bunching_ratio, 3), " \\\\"),
  paste0(" & & (", round(results$pooled_500k$se, 3), ") \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Placebo bunching estimated at round-number thresholds using only organizations in states without charitable audit mandates (AK, AZ, DE, FL, IA, ID, IN, LA, MT, ND, NE, NV, SD, TX, VT, WA, WY). The actual \\$500,000 estimate (last row) uses organizations from audit-mandate states. Bootstrap standard error in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab5_lines, file.path(tables_dir, "tab5_placebo.tex"))
cat("Table 5 written.\n")

## ══════════════════════════════════════════════════════════════════════════
## SDE TABLE (Appendix F1 — Mandatory)
## ══════════════════════════════════════════════════════════════════════════

## For bunching design, the "effect" is the bunching ratio itself
## SDE = bunching_ratio (already standardized as excess mass / avg density)
## We interpret this as the behavioral distortion in units of counterfactual density

pooled <- results$pooled_500k
b_hat <- pooled$bunching_ratio
b_se <- pooled$se

## SDE classification
classify_sde <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  return("Small negative")
}

## Build SDE table
## Main outcome: bunching ratio at $500K threshold
## The "SD(Y)" is the standard deviation of the bin counts
sd_y_bins <- sd(bmf_clean[STATE %in% bmf_clean[threshold == 500000 & has_audit_mandate == TRUE, unique(STATE)] &
                           revenue >= 250000 & revenue <= 750000,
                           .N, by = .(bin = floor(revenue / 5000) * 5000)]$N)

## For bunching, SDE = excess_mass / SD(bin counts)
sde_val <- pooled$excess_mass / sd_y_bins
sde_se <- pooled$se * (pooled$excess_mass / pooled$bunching_ratio) / sd_y_bins
sde_class <- classify_sde(sde_val)

## Density discontinuity outcome
density_ratio <- results$density_test$ratio
sd_density <- sd(bmf_clean[STATE %in% bmf_clean[threshold == 500000 & has_audit_mandate == TRUE, unique(STATE)] &
                            revenue >= 250000 & revenue <= 750000,
                            .N, by = .(bin = floor(revenue / 5000) * 5000)]$N)
sde_density <- (results$density_test$below - results$density_test$above) / sd_density
sde_density_class <- classify_sde(sde_density)

## DiB outcome
dib_sde <- results$dib$dib_estimate / sd(c(results$dib$mandate_below, results$dib$no_mandate_below,
                                            results$dib$mandate_above, results$dib$no_mandate_above))
dib_sde_class <- classify_sde(dib_sde)

## SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-mandated charitable audit thresholds distort nonprofit revenue reporting, and how large is the behavioral response to compliance cost discontinuities? ",
  "\\textbf{Policy mechanism:} Thirty-four US states require charitable nonprofits to submit independently audited financial statements when annual revenue exceeds a state-specific threshold (ranging from \\$300,000 to \\$2,000,000), creating a discontinuous jump in compliance costs of \\$10,000--\\$100,000 at the threshold. ",
  "\\textbf{Outcome definition:} Bunching ratio measures excess mass of organizations reporting revenue just below the threshold relative to counterfactual polynomial density; density discontinuity measures the ratio of bin counts in the \\$25,000 window below vs.\\ above the threshold. ",
  "\\textbf{Treatment:} Binary -- organizations face audit mandate if revenue exceeds state-specific threshold (primary analysis at \\$500,000, the modal threshold). ",
  "\\textbf{Data:} IRS Exempt Organizations Business Master File (2024 extract), all 501(c)(3) organizations with positive revenue across 50 states plus DC; approximately 555,000 organizations in audit-mandate states. ",
  "\\textbf{Method:} Polynomial bunching estimation following Kleven and Waseem (2013) with degree-7 counterfactual density, bootstrap standard errors (200 replications resampled within state), and difference-in-bunching comparing mandate vs.\\ no-mandate states. ",
  "\\textbf{Sample:} Restricted to organizations with revenue within $\\pm$50\\% of their state's audit threshold; 34 states with audit mandates provide independent replications. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-bin standard deviation of organization counts. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  paste0("Bunching ratio ($\\hat{b}$) & ",
         round(pooled$excess_mass, 1), " & ",
         round(pooled$se * (pooled$excess_mass / pooled$bunching_ratio), 1), " & ",
         round(sd_y_bins, 1), " & ",
         round(sde_val, 3), " & ",
         round(sde_se, 3), " & ",
         sde_class, " \\\\"),
  paste0("Density discontinuity & ",
         results$density_test$below - results$density_test$above, " & --- & ",
         round(sd_density, 1), " & ",
         round(sde_density, 3), " & --- & ",
         sde_density_class, " \\\\"),
  paste0("Diff.-in-bunching & ",
         round(results$dib$dib_estimate, 5), " & --- & --- & ",
         round(dib_sde, 3), " & --- & ",
         dib_sde_class, " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("SDE table written.\n")

cat("\nAll tables generated.\n")
