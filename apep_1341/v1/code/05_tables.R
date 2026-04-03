# 05_tables.R — Generate all LaTeX tables
# apep_1341: RCRA Hazardous Waste Generator Thresholds

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# Load data
panel <- readRDS(file.path(data_dir, "handler_cycle_panel.rds"))
results <- readRDS(file.path(data_dir, "bunching_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

recent <- panel %>% filter(cycle == max(cycle))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

summ_stats <- recent %>%
  filter(gen_kg_month > 0) %>%
  summarise(
    n = n(),
    mean_kg = mean(gen_kg_month, na.rm = TRUE),
    sd_kg = sd(gen_kg_month, na.rm = TRUE),
    median_kg = median(gen_kg_month, na.rm = TRUE),
    p25_kg = quantile(gen_kg_month, 0.25, na.rm = TRUE),
    p75_kg = quantile(gen_kg_month, 0.75, na.rm = TRUE),
    pct_lqg = mean(gen_kg_month >= 1000, na.rm = TRUE) * 100,
    pct_sqg = mean(gen_kg_month >= 100 & gen_kg_month < 1000, na.rm = TRUE) * 100,
    n_streams_mean = mean(n_waste_streams, na.rm = TRUE),
    n_streams_sd = sd(n_waste_streams, na.rm = TRUE)
  )

# Window sample (200-2500 kg/month)
window_stats <- recent %>%
  filter(gen_kg_month >= 200 & gen_kg_month <= 2500) %>%
  summarise(
    n = n(),
    mean_kg = mean(gen_kg_month, na.rm = TRUE),
    sd_kg = sd(gen_kg_month, na.rm = TRUE),
    median_kg = median(gen_kg_month, na.rm = TRUE)
  )

tab1 <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lrr}
\\toprule
& Full Sample & Analysis Window \\\\
\\midrule
\\textit{Panel A: Generation} & & \\\\
Mean generation (kg/month) & %.0f & %.0f \\\\
Std.\\ dev. & %.0f & %.0f \\\\
Median & %.0f & %.0f \\\\
\\midrule
\\textit{Panel B: Classification} & & \\\\
Pct.\\ LQG ($\\geq$1,000 kg/month) & %.1f\\%%%% & --- \\\\
Pct.\\ SQG (100--999 kg/month) & %.1f\\%%%% & --- \\\\
\\midrule
\\textit{Panel C: Complexity} & & \\\\
Mean waste streams per handler & %.1f & --- \\\\
Std.\\ dev. & %.1f & --- \\\\
\\midrule
Observations & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Data from EPA Biennial Report, %d cycle. Full sample includes all handlers with positive generation. Analysis window restricts to 200--2,500 kg/month for bunching estimation. Generation is total annual hazardous waste generation (summed across all waste streams per handler) divided by 12 to obtain monthly average. One short ton = 907.185 kg.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}',
  summ_stats$mean_kg, window_stats$mean_kg,
  summ_stats$sd_kg, window_stats$sd_kg,
  summ_stats$median_kg, window_stats$median_kg,
  summ_stats$pct_lqg,
  summ_stats$pct_sqg,
  summ_stats$n_streams_mean,
  summ_stats$n_streams_sd,
  format(summ_stats$n, big.mark = ","),
  format(window_stats$n, big.mark = ","),
  max(panel$cycle))

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Bunching Estimates
# ============================================================
cat("Generating Table 2: Bunching Estimates...\n")

b_main <- results$main$b
se_main <- results$main$se
b_pooled <- results$pooled$b

# Significance stars
stars <- function(b, se) {
  t <- abs(b / se)
  if (t > 2.576) return("***")
  if (t > 1.96) return("**")
  if (t > 1.645) return("*")
  return("")
}

tab2 <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Bunching Estimates at the 1,000 kg/month Threshold}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
& Most Recent Cycle & Pooled (All Cycles) \\\\
\\midrule
Normalized excess mass ($b$) & %.3f%s & %.3f \\\\
& (%.3f) & \\\\
Excess mass (handlers) & %.0f & %.0f \\\\
Missing mass (handlers) & %.0f & %.0f \\\\
\\midrule
Counterfactual at threshold & %.0f & %.0f \\\\
Observations in window & %s & %s \\\\
Polynomial order & 7 & 7 \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Bunching estimation following \\citet{kleven2013}. Excess mass is estimated relative to a 7th-order polynomial counterfactual fitted to 25 kg/month bins, excluding the region [850, 1050] kg/month. Analysis window: [200, 2500] kg/month. Bootstrap standard errors (200 replications) in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:bunching}
\\end{table}',
  b_main, stars(b_main, se_main),
  b_pooled,
  se_main,
  results$main$excess_mass, results$pooled$excess_mass,
  results$main$missing_mass, results$pooled$missing_mass,
  results$main$counterfactual_at_kink, results$pooled$counterfactual_at_kink,
  format(results$main$n_total, big.mark = ","),
  format(results$pooled$n_total, big.mark = ","))

writeLines(tab2, file.path(tables_dir, "tab2_bunching.tex"))

# ============================================================
# Table 3: Placebo Tests
# ============================================================
cat("Generating Table 3: Placebo Tests...\n")

placebo_rows <- c()
for (pt_name in names(rob_results$placebo)) {
  res <- rob_results$placebo[[pt_name]]
  if (!is.na(res$b_normalized)) {
    placebo_rows <- c(placebo_rows, sprintf(
      "%s & %.3f & %.0f \\\\",
      format(as.numeric(pt_name), big.mark = ","),
      res$b_normalized, res$excess_mass))
  }
}

# Add the real threshold for comparison
placebo_rows <- c(
  sprintf("1,000 (regulatory) & %.3f%s & %.0f \\\\",
          b_main, stars(b_main, se_main), results$main$excess_mass),
  "\\midrule",
  placebo_rows)

tab3 <- paste0('
\\begin{table}[H]
\\centering
\\caption{Placebo Tests at Non-Regulatory Round Numbers}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Threshold (kg/month) & Normalized $b$ & Excess Mass \\\\
\\midrule
', paste(placebo_rows, collapse = "\n"), '
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Same bunching methodology applied at round-number thresholds with no regulatory significance. Excluded region set symmetrically around each placebo threshold. The 1,000 kg/month result (top row) is the main estimate from \\Cref{tab:bunching} for comparison. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:placebo}
\\end{table}')

writeLines(tab3, file.path(tables_dir, "tab3_placebo.tex"))

# ============================================================
# Table 4: Industry Heterogeneity
# ============================================================
cat("Generating Table 4: Industry Heterogeneity...\n")

# NAICS 2-digit labels
naics_labels <- c(
  "31" = "Manufacturing (food/textile)",
  "32" = "Manufacturing (chemical/plastic)",
  "33" = "Manufacturing (metal/electronic)",
  "21" = "Mining/extraction",
  "23" = "Construction",
  "42" = "Wholesale trade",
  "44" = "Retail trade",
  "48" = "Transportation",
  "54" = "Professional services",
  "56" = "Waste management services",
  "62" = "Health care",
  "72" = "Accommodation/food service",
  "81" = "Other services",
  "92" = "Public administration",
  "11" = "Agriculture"
)

ind_rows <- c()
for (ind in names(rob_results$industry)) {
  res <- rob_results$industry[[ind]]
  label <- ifelse(ind %in% names(naics_labels), naics_labels[ind], paste("NAICS", ind))
  n_handlers <- nrow(recent %>% filter(naics2 == ind))
  ind_rows <- c(ind_rows, sprintf(
    "%s & %.3f & %.0f & %s \\\\",
    label, res$b_normalized, res$excess_mass,
    format(n_handlers, big.mark = ",")))
}

tab4 <- paste0('
\\begin{table}[H]
\\centering
\\caption{Bunching Estimates by Industry Sector}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Sector (NAICS 2-digit) & Normalized $b$ & Excess Mass & Handlers \\\\
\\midrule
', paste(ind_rows, collapse = "\n"), '
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Separate bunching estimates for the top 5 industries by handler count. Same methodology as \\Cref{tab:bunching} applied to each sector independently. Most recent reporting cycle.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:industry}
\\end{table}')

writeLines(tab4, file.path(tables_dir, "tab4_industry.tex"))

# ============================================================
# Table 5: Robustness
# ============================================================
cat("Generating Table 5: Robustness...\n")

# Polynomial sensitivity - re-estimate
poly_rows <- c()
for (p in 5:9) {
  source("03_main_analysis.R")  # ensure estimate_bunching is loaded
  res <- estimate_bunching(recent, 1000, poly_order = p)
  poly_rows <- c(poly_rows, sprintf(
    "Polynomial order %d & %.3f & %.0f \\\\", p, res$b_normalized, res$excess_mass))
}

# McCrary density ratio
mccrary_row <- sprintf(
  "McCrary density ratio (below/above) & \\multicolumn{2}{c}{%.2f} \\\\",
  rob_results$mccrary_ratio)

tab5 <- paste0('
\\begin{table}[H]
\\centering
\\caption{Robustness of Bunching Estimates}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Specification & Normalized $b$ & Excess Mass \\\\
\\midrule
\\textit{Panel A: Polynomial order} & & \\\\
', paste(poly_rows, collapse = "\n"), '
\\midrule
\\textit{Panel B: Density test} & & \\\\
', mccrary_row, '
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A varies the polynomial order for the counterfactual density. Baseline is 7th order. Panel B reports the ratio of handler counts in the 100 kg/month bin just below the threshold (900--999) to just above (1,000--1,099). A ratio above 1 indicates excess density below the threshold.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robustness}
\\end{table}')

writeLines(tab5, file.path(tables_dir, "tab5_robustness.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("Generating SDE table...\n")

# For bunching, the "treatment" is being near the threshold
# The SDE equivalent: b (normalized excess mass) is already a standardized measure
# But we need to map it to the framework
# Treatment: binary indicator for being in the "bunching region" (850-1000 kg/month)
# Outcome: count of handlers (density)
# beta_hat = excess mass count
# SD(Y) = std dev of bin counts in the counterfactual

binned <- results$binned_data
cf_sd <- sd(binned$counterfactual[!binned$excluded], na.rm = TRUE)

# Main pooled estimate
beta_hat <- results$main$excess_mass
se_hat <- beta_hat * (se_main / b_main)  # scale SE proportionally
sde_main <- beta_hat / cf_sd
se_sde_main <- se_hat / cf_sd

classify <- function(s) {
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

# Industry heterogeneity for Panel B
mfg_b <- if (!is.null(rob_results$industry[["32"]])) rob_results$industry[["32"]]$b_normalized else NA
non_mfg_industries <- setdiff(names(rob_results$industry), c("31", "32", "33"))
non_mfg_b <- if (length(non_mfg_industries) > 0) {
  mean(sapply(rob_results$industry[non_mfg_industries], function(x) x$b_normalized), na.rm = TRUE)
} else NA

# SDE for heterogeneity (using b directly as the standardized measure)
sde_mfg <- ifelse(!is.na(mfg_b), mfg_b, 0)
sde_nonmfg <- ifelse(!is.na(non_mfg_b), non_mfg_b, 0)

# Notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the RCRA 1,000 kg/month hazardous waste generator threshold induce strategic waste reclassification among regulated generators? ",
  "\\textbf{Policy mechanism:} Generators crossing 1,000 kg/month face halved storage time (90 vs 180 days), mandatory contingency plans, emergency training, and biennial reporting---a discrete cost increase that incentivizes threshold avoidance via waste stream reclassification. ",
  "\\textbf{Outcome definition:} Normalized excess mass ($b$) in the density distribution of monthly hazardous waste generation at the regulatory threshold, measuring the fraction of generators strategically positioning below the cutoff. ",
  "\\textbf{Treatment:} Continuous---monthly hazardous waste generation in kg/month with a regulatory notch at 1,000. ",
  "\\textbf{Data:} EPA Biennial Report via Envirofacts API, 2019--2023 cycles, handler-cycle observations aggregated from waste-stream-level records. ",
  "\\textbf{Method:} Bunching estimation following Kleven and Waseem (2013) with 7th-order polynomial counterfactual and bootstrap inference. ",
  "\\textbf{Sample:} All SQG and LQG handlers with positive generation in the analysis window (200--2,500 kg/month). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the standard deviation of counterfactual bin counts. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Excess mass & Baseline (7th poly) & %.0f & %.1f & %.3f & %.3f & %s \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\
Excess mass & Manufacturing & --- & --- & %.3f & --- & %s \\\\
Excess mass & Non-manufacturing & --- & --- & %.3f & --- & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\footnotesize
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  beta_hat, cf_sd, sde_main, se_sde_main, classify(sde_main),
  sde_mfg, classify(sde_mfg),
  sde_nonmfg, classify(sde_nonmfg),
  sde_notes)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat("05_tables.R complete.\n")
