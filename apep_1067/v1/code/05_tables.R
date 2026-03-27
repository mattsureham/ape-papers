## 05_tables.R — Generate all LaTeX tables
## APEP Working Paper apep_1067

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

nbi <- fread(file.path(data_dir, "nbi_clean.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
boot <- readRDS(file.path(data_dir, "bootstrap_results.rds"))
year_bunching <- fread(file.path(data_dir, "year_bunching.csv"))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("Generating Table 1: Summary Statistics\n")

# Overall stats
stats <- nbi[, .(
  N = .N,
  mean_sr = mean(sr, na.rm = TRUE),
  sd_sr = sd(sr, na.rm = TRUE),
  median_sr = median(sr, na.rm = TRUE),
  pct_below_50 = 100 * mean(sr < 50, na.rm = TRUE),
  mean_age = mean(bridge_age, na.rm = TRUE),
  mean_adt = mean(adt, na.rm = TRUE),
  n_bridges = uniqueN(STRUCTURE_NUMBER_008),
  n_states = uniqueN(state_code)
)]

# By period
stats_period <- nbi[, .(
  N = .N,
  mean_sr = mean(sr, na.rm = TRUE),
  sd_sr = sd(sr, na.rm = TRUE),
  pct_below_50 = 100 * mean(sr < 50, na.rm = TRUE),
  mean_age = mean(bridge_age, na.rm = TRUE),
  n_bridges = uniqueN(STRUCTURE_NUMBER_008)
), by = period]

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: National Bridge Inventory, 2000--2018}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Full Sample & Pre-MAP-21 & Post-MAP-21 \\\\\n",
  " & (2000--2018) & (2000--2012) & (2013--2018) \\\\\n",
  "\\hline\n",
  sprintf("Bridge-year observations & %s & %s & %s \\\\\n",
          format(stats$N, big.mark = ","),
          format(stats_period[period == "Pre-MAP-21 (2000-2012)", N], big.mark = ","),
          format(stats_period[period == "Post-MAP-21 (2013-2018)", N], big.mark = ",")),
  sprintf("Unique bridges & %s & %s & %s \\\\\n",
          format(stats$n_bridges, big.mark = ","),
          format(stats_period[period == "Pre-MAP-21 (2000-2012)", n_bridges], big.mark = ","),
          format(stats_period[period == "Post-MAP-21 (2013-2018)", n_bridges], big.mark = ",")),
  sprintf("Mean sufficiency rating & %.1f & %.1f & %.1f \\\\\n",
          stats$mean_sr,
          stats_period[period == "Pre-MAP-21 (2000-2012)", mean_sr],
          stats_period[period == "Post-MAP-21 (2013-2018)", mean_sr]),
  sprintf("SD sufficiency rating & %.1f & %.1f & %.1f \\\\\n",
          stats$sd_sr,
          stats_period[period == "Pre-MAP-21 (2000-2012)", sd_sr],
          stats_period[period == "Post-MAP-21 (2013-2018)", sd_sr]),
  sprintf("\\%% with SR $<$ 50 & %.1f & %.1f & %.1f \\\\\n",
          stats$pct_below_50,
          stats_period[period == "Pre-MAP-21 (2000-2012)", pct_below_50],
          stats_period[period == "Post-MAP-21 (2013-2018)", pct_below_50]),
  sprintf("Mean bridge age (years) & %.1f & %.1f & %.1f \\\\\n",
          stats$mean_age,
          stats_period[period == "Pre-MAP-21 (2000-2012)", mean_age],
          stats_period[period == "Post-MAP-21 (2013-2018)", mean_age]),
  sprintf("States & %d & --- & --- \\\\\n", stats$n_states),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Data from the FHWA National Bridge Inventory (NBI), ",
  "annual delimited files. Sufficiency rating (SR) ranges from 0 to 100. ",
  "Bridges with SR $<$ 50 qualify for federal replacement funding under the ",
  "Highway Bridge Program (HBP). MAP-21 (effective October 2012) eliminated ",
  "the HBP and its sufficiency-based funding formula.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Bunching Estimates
# ============================================================

cat("Generating Table 2: Bunching Estimates\n")

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Bunching Estimates at the SR $=$ 50 Federal Funding Threshold}\n",
  "\\label{tab:bunching}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Full Sample & Pre-MAP-21 & Post-MAP-21 \\\\\n",
  " & (2000--2018) & (2000--2012) & (2013--2018) \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Bunching Estimates}} \\\\\n",
  sprintf("Normalized excess mass ($\\hat{b}$) & %.3f & %.3f & %.3f \\\\\n",
          boot$full$mean, boot$pre$mean, boot$post$mean),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          boot$full$se, boot$pre$se, boot$post$se),
  sprintf("Excess bridges below 50 & %s & %s & %s \\\\\n",
          format(round(results$full_excess), big.mark = ","),
          format(round(results$pre_bhat * results$full_excess / results$full_bhat), big.mark = ","),
          format(round(results$post_bhat * results$full_excess / results$full_bhat), big.mark = ",")),
  "[6pt]\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: McCrary Density Test}} \\\\\n",
  sprintf("Log-density gap at 50 & %.3f & %.3f & %.3f \\\\\n",
          results$mccrary_full$log_gap,
          results$mccrary_pre$log_gap,
          results$mccrary_post$log_gap),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          results$mccrary_full$se,
          results$mccrary_pre$se,
          results$mccrary_post$se),
  "[6pt]\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Difference-in-Bunching}} \\\\\n",
  sprintf("$\\hat{b}_{\\text{pre}} - \\hat{b}_{\\text{post}}$ & & \\multicolumn{2}{c}{%.3f} \\\\\n",
          boot$diff$mean),
  sprintf(" & & \\multicolumn{2}{c}{(%.3f)} \\\\\n", boot$diff$se),
  sprintf("$p$-value (one-sided) & & \\multicolumn{2}{c}{%.3f} \\\\\n",
          boot$diff$p_value),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A reports normalized excess mass ($\\hat{b}$) from a ",
  "polynomial bunching estimator (order 7) at the SR $=$ 50 threshold. ",
  "Counterfactual density estimated excluding SR $\\in$ [46, 53]. ",
  "Bootstrap standard errors (200 replications, resampled by bridge ID) in parentheses. ",
  "Panel B reports the McCrary (2008) log-density discontinuity test at SR $=$ 50 ",
  "using a bandwidth of 10 integer SR bins on each side. ",
  "Panel C tests whether bunching intensity declined after MAP-21 eliminated ",
  "the sufficiency-based funding formula.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(table_dir, "tab2_bunching.tex"))

# ============================================================
# TABLE 3: Owner Heterogeneity
# ============================================================

cat("Generating Table 3: Owner Heterogeneity\n")

# Estimate bunching by owner type and period
estimate_bunching_quick <- function(dt) {
  counts <- dt[sr_int >= 10 & sr_int <= 90, .(count = .N), by = sr_int][order(sr_int)]
  all_bins <- data.table(sr_int = 10:90)
  counts <- merge(all_bins, counts, by = "sr_int", all.x = TRUE)
  counts[is.na(count), count := 0]
  counts[, excluded := sr_int >= 46 & sr_int <= 53]
  fit_data <- counts[excluded == FALSE]
  if (nrow(fit_data) < 10) return(NA_real_)
  poly_fit <- lm(count ~ poly(sr_int, 7), data = fit_data)
  counts[, counterfactual := predict(poly_fit, newdata = counts)]
  below_50 <- counts[excluded == TRUE & sr_int < 50]
  excess <- sum(below_50$count) - sum(below_50$counterfactual)
  h0 <- counts[sr_int == 50, counterfactual]
  if (h0 <= 0) return(NA_real_)
  excess / h0
}

owner_results <- list()
for (otype in c("State DOT", "Local Government", "Federal")) {
  pre <- nbi[owner_type == otype & post_map21 == 0]
  post <- nbi[owner_type == otype & post_map21 == 1]
  full <- nbi[owner_type == otype]
  owner_results[[otype]] <- list(
    full = estimate_bunching_quick(full),
    pre = estimate_bunching_quick(pre),
    post = estimate_bunching_quick(post),
    n_full = nrow(full),
    n_pre = nrow(pre),
    n_post = nrow(post)
  )
}

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Bunching by Bridge Owner Type}\n",
  "\\label{tab:owner}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & State DOT & Local Gov't & Federal \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Full Sample (2000--2018)}} \\\\\n",
  sprintf("$\\hat{b}$ & %.3f & %.3f & %.3f \\\\\n",
          owner_results[["State DOT"]]$full,
          owner_results[["Local Government"]]$full,
          owner_results[["Federal"]]$full),
  sprintf("$N$ & %s & %s & %s \\\\\n",
          format(owner_results[["State DOT"]]$n_full, big.mark = ","),
          format(owner_results[["Local Government"]]$n_full, big.mark = ","),
          format(owner_results[["Federal"]]$n_full, big.mark = ",")),
  "[6pt]\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Pre-MAP-21 (2000--2012)}} \\\\\n",
  sprintf("$\\hat{b}$ & %.3f & %.3f & %.3f \\\\\n",
          owner_results[["State DOT"]]$pre,
          owner_results[["Local Government"]]$pre,
          owner_results[["Federal"]]$pre),
  "[6pt]\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Post-MAP-21 (2013--2018)}} \\\\\n",
  sprintf("$\\hat{b}$ & %.3f & %.3f & %.3f \\\\\n",
          owner_results[["State DOT"]]$post,
          owner_results[["Local Government"]]$post,
          owner_results[["Federal"]]$post),
  "[6pt]\n",
  "\\multicolumn{4}{l}{\\textit{Panel D: Diff-in-Bunching}} \\\\\n",
  sprintf("$\\hat{b}_{\\text{pre}} - \\hat{b}_{\\text{post}}$ & %.3f & %.3f & %.3f \\\\\n",
          owner_results[["State DOT"]]$pre - owner_results[["State DOT"]]$post,
          owner_results[["Local Government"]]$pre - owner_results[["Local Government"]]$post,
          owner_results[["Federal"]]$pre - owner_results[["Federal"]]$post),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Normalized excess mass ($\\hat{b}$) estimated separately by bridge owner type. ",
  "State DOT includes state highway agencies (owner code 01). ",
  "Local Government includes county, town, and city agencies (codes 02--04, 25). ",
  "Federal includes all federal agencies (codes 60--74). ",
  "Polynomial order 7; manipulation region SR $\\in$ [46, 53].\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(table_dir, "tab3_owner.tex"))

# ============================================================
# TABLE 4: Placebo and Robustness
# ============================================================

cat("Generating Table 4: Robustness\n")

# Polynomial sensitivity
poly_results <- sapply(5:9, function(p) {
  estimate_bunching_quick_poly <- function(dt, poly_order) {
    counts <- dt[sr_int >= 10 & sr_int <= 90, .(count = .N), by = sr_int][order(sr_int)]
    all_bins <- data.table(sr_int = 10:90)
    counts <- merge(all_bins, counts, by = "sr_int", all.x = TRUE)
    counts[is.na(count), count := 0]
    counts[, excluded := sr_int >= 46 & sr_int <= 53]
    fit_data <- counts[excluded == FALSE]
    poly_fit <- lm(count ~ poly(sr_int, poly_order), data = fit_data)
    counts[, counterfactual := predict(poly_fit, newdata = counts)]
    below_50 <- counts[excluded == TRUE & sr_int < 50]
    excess <- sum(below_50$count) - sum(below_50$counterfactual)
    h0 <- counts[sr_int == 50, counterfactual]
    excess / h0
  }
  estimate_bunching_quick_poly(nbi, p)
})

# Placebo at 60, 70, 80
placebo_results <- sapply(c(60, 70, 80), function(cutoff) {
  exc_lo <- cutoff - 4
  exc_hi <- cutoff + 3
  counts <- nbi[sr_int >= 10 & sr_int <= 95, .(count = .N), by = sr_int][order(sr_int)]
  all_bins <- data.table(sr_int = 10:95)
  counts <- merge(all_bins, counts, by = "sr_int", all.x = TRUE)
  counts[is.na(count), count := 0]
  counts[, excluded := sr_int >= exc_lo & sr_int <= exc_hi]
  fit_data <- counts[excluded == FALSE]
  poly_fit <- lm(count ~ poly(sr_int, 7), data = fit_data)
  counts[, counterfactual := predict(poly_fit, newdata = counts)]
  below <- counts[excluded == TRUE & sr_int < cutoff]
  excess <- sum(below$count) - sum(below$counterfactual)
  h0 <- counts[sr_int == cutoff, counterfactual]
  if (h0 <= 0) return(NA_real_)
  excess / h0
})

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness and Placebo Tests}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Specification & $\\hat{b}$ & Notes \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Polynomial Order Sensitivity}} \\\\\n",
  sprintf("Order 5 & %.3f & \\\\\n", poly_results[1]),
  sprintf("Order 6 & %.3f & \\\\\n", poly_results[2]),
  sprintf("Order 7 (baseline) & %.3f & \\\\\n", poly_results[3]),
  sprintf("Order 8 & %.3f & \\\\\n", poly_results[4]),
  sprintf("Order 9 & %.3f & \\\\\n", poly_results[5]),
  "[6pt]\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo Thresholds}} \\\\\n",
  sprintf("SR $=$ 60 & %.3f & No funding threshold \\\\\n", placebo_results[1]),
  sprintf("SR $=$ 70 & %.3f & No funding threshold \\\\\n", placebo_results[2]),
  sprintf("SR $=$ 80 & %.3f & Rehabilitation threshold \\\\\n", placebo_results[3]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A varies the polynomial order of the counterfactual density. ",
  "All specifications use the manipulation region SR $\\in$ [46, 53]. ",
  "Panel B estimates bunching at thresholds where no replacement-funding incentive exists. ",
  "SR $=$ 80 marks the rehabilitation eligibility threshold under the HBP, ",
  "but rehabilitation funds were less generous than replacement funds.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) Appendix
# ============================================================

cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDE for main estimates
# Treatment: binary (pre vs post MAP-21)
# Outcome: bunching intensity (excess mass ratio at SR=50)

# For the SDE, we need yearly bunching measures
yr_bunch <- year_bunching[, .(year, ratio)]
sd_y_pre <- sd(yr_bunch[year <= 2012, ratio])

# Main estimate: change in bunching ratio
beta_main <- mean(yr_bunch[year <= 2012, ratio]) - mean(yr_bunch[year >= 2013, ratio])
se_main <- sqrt(var(yr_bunch[year <= 2012, ratio]) / sum(yr_bunch$year <= 2012) +
                  var(yr_bunch[year >= 2013, ratio]) / sum(yr_bunch$year >= 2013))

sde_main <- beta_main / sd_y_pre
se_sde_main <- se_main / sd_y_pre

# Classification
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return("Small positive")
  if (abs_sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Owner heterogeneity
# State DOT vs Local: compute yearly ratios
state_dot_yr <- nbi[owner_type == "State DOT", {
  n49 <- sum(sr_int == 49)
  n50 <- sum(sr_int == 50)
  list(ratio = n49 / max(n50, 1))
}, by = year][order(year)]

local_yr <- nbi[owner_type == "Local Government", {
  n49 <- sum(sr_int == 49)
  n50 <- sum(sr_int == 50)
  list(ratio = n49 / max(n50, 1))
}, by = year][order(year)]

sd_y_state <- sd(state_dot_yr[year <= 2012, ratio])
beta_state <- mean(state_dot_yr[year <= 2012, ratio]) - mean(state_dot_yr[year >= 2013, ratio])
sde_state <- beta_state / sd_y_state

sd_y_local <- sd(local_yr[year <= 2012, ratio])
beta_local <- mean(local_yr[year <= 2012, ratio]) - mean(local_yr[year >= 2013, ratio])
sde_local <- beta_local / sd_y_local

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the elimination of sufficiency-based federal bridge funding (MAP-21, 2012) reduce strategic manipulation of bridge condition ratings by state transportation agencies? ",
  "\\textbf{Policy mechanism:} The Highway Bridge Program apportioned federal replacement funds to states based on the count of bridges with sufficiency ratings below 50; MAP-21 replaced this formula with a performance-based system using structurally deficient deck-area triggers, weakening the incentive to deflate ratings below the threshold. ",
  "\\textbf{Outcome definition:} Bunching ratio, defined as the count of bridges with integer sufficiency ratings in [46,49] divided by [50,53], measuring excess mass just below the federal funding threshold. ",
  "\\textbf{Treatment:} Binary; pre-MAP-21 (2000--2012) versus post-MAP-21 (2013--2018). ",
  "\\textbf{Data:} FHWA National Bridge Inventory, 2000--2018, bridge-year panel, approximately 11.5 million observations across 50 states and DC. ",
  "\\textbf{Method:} Polynomial bunching estimator (order 7) with difference-in-bunching pre/post MAP-21; bootstrap standard errors (200 replications, resampled by bridge ID). ",
  "\\textbf{Sample:} All public bridges in the 50 US states and DC with non-missing sufficiency ratings; excludes territories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the annual bunching ratio. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Bunching ratio (all bridges) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)),
  "[6pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by owner type)}} \\\\\n",
  sprintf("State DOT bridges & %.3f & --- & %.3f & %.3f & --- & %s \\\\\n",
          beta_state, sd_y_state, sde_state, classify_sde(sde_state)),
  sprintf("Local government bridges & %.3f & --- & %.3f & %.3f & --- & %s \\\\\n",
          beta_local, sd_y_local, sde_local, classify_sde(sde_local)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

cat("All tables generated successfully.\n")
