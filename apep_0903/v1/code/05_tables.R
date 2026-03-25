# 05_tables.R — Generate all tables for Swiss Second Home Ban RDD paper
# apep_0903

base_dir <- normalizePath(file.path(getwd(), ".."))
source(file.path(base_dir, "code", "00_packages.R"))
data_dir <- file.path(base_dir, "data")
tab_dir <- file.path(base_dir, "tables")
dir.create(tab_dir, showWarnings = FALSE)

cat("=== Generating Tables ===\n")

rdd_data <- readRDS(file.path(data_dir, "rdd_data.rds"))
results <- readRDS(file.path(data_dir, "rdd_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))
analysis <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# Helper: format stars
stars <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

# ================================================================
# TABLE 1: Descriptive Statistics
# ================================================================

cat("--- Table 1: Descriptive Statistics ---\n")

# Split at threshold
latest <- analysis[wave == max(wave)]
below <- latest[treated == FALSE]
above <- latest[treated == TRUE]

desc_vars <- c("pct_secondary", "pct_primary", "n_total", "n_primary", "n_equivalent")
desc_labels <- c("Second-home share (\\%)", "Primary-home share (\\%)",
                 "Total dwellings", "Primary dwellings", "Equivalent dwellings")

desc_rows <- list()
for (i in seq_along(desc_vars)) {
  v <- desc_vars[i]
  desc_rows[[i]] <- sprintf("%s & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
                            desc_labels[i],
                            mean(below[[v]], na.rm=TRUE),
                            sd(below[[v]], na.rm=TRUE),
                            mean(above[[v]], na.rm=TRUE),
                            sd(above[[v]], na.rm=TRUE),
                            mean(latest[[v]], na.rm=TRUE),
                            sd(latest[[v]], na.rm=TRUE))
}

# Add change variables from rdd_data
desc_rows[[length(desc_rows) + 1]] <- sprintf(
  "$\\Delta$ Second-home share (pp) & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
  mean(rdd_data[treated == FALSE]$delta_pct_secondary, na.rm=TRUE),
  sd(rdd_data[treated == FALSE]$delta_pct_secondary, na.rm=TRUE),
  mean(rdd_data[treated == TRUE]$delta_pct_secondary, na.rm=TRUE),
  sd(rdd_data[treated == TRUE]$delta_pct_secondary, na.rm=TRUE),
  mean(rdd_data$delta_pct_secondary, na.rm=TRUE),
  sd(rdd_data$delta_pct_secondary, na.rm=TRUE))

desc_rows[[length(desc_rows) + 1]] <- sprintf(
  "Dwelling growth (\\%%) & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
  mean(rdd_data[treated == FALSE]$pct_growth_dwellings, na.rm=TRUE),
  sd(rdd_data[treated == FALSE]$pct_growth_dwellings, na.rm=TRUE),
  mean(rdd_data[treated == TRUE]$pct_growth_dwellings, na.rm=TRUE),
  sd(rdd_data[treated == TRUE]$pct_growth_dwellings, na.rm=TRUE),
  mean(rdd_data$pct_growth_dwellings, na.rm=TRUE),
  sd(rdd_data$pct_growth_dwellings, na.rm=TRUE))

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Descriptive Statistics by Treatment Status (Latest Wave)}",
  "\\label{tab:descriptive}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Below 20\\%} & \\multicolumn{2}{c}{Above 20\\%} & \\multicolumn{2}{c}{All} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  paste(desc_rows, collapse = "\n"),
  "\\midrule",
  sprintf("Municipalities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          nrow(below), nrow(above), nrow(latest)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Data from the Swiss Federal Housing Inventory (ZWG), published by the Federal Office for Spatial Development (ARE). Latest wave: March 2025. Treatment status based on initial second-home share relative to the 20\\% statutory threshold. $\\Delta$ Second-home share and dwelling growth computed from first observed wave (2017) to latest wave.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1, file.path(tab_dir, "tab1_descriptive.tex"))
cat("  Saved tab1_descriptive.tex\n")

# ================================================================
# TABLE 2: Main RDD Results
# ================================================================

cat("--- Table 2: Main RDD Results ---\n")

# Run all three main specifications with masspoints adjustment
rdd_change <- rdrobust::rdrobust(
  y = rdd_data$delta_pct_secondary, x = rdd_data$running_var,
  c = 0, kernel = "triangular", p = 1, bwselect = "mserd", masspoints = "adjust"
)
rdd_growth <- rdrobust::rdrobust(
  y = rdd_data$pct_growth_dwellings, x = rdd_data$running_var,
  c = 0, kernel = "triangular", p = 1, bwselect = "mserd", masspoints = "adjust"
)
rdd_level <- rdrobust::rdrobust(
  y = rdd_data$latest_pct_secondary, x = rdd_data$running_var,
  c = 0, kernel = "triangular", p = 1, bwselect = "mserd", masspoints = "adjust"
)

# Also run quadratic
rdd_change_q <- rdrobust::rdrobust(
  y = rdd_data$delta_pct_secondary, x = rdd_data$running_var,
  c = 0, kernel = "triangular", p = 2, bwselect = "mserd", masspoints = "adjust"
)

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Main RDD Estimates: Effect of Second-Home Construction Ban}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & $\\Delta$ Sec.\\ Share & Dwelling & Sec.\\ Share & $\\Delta$ Sec.\\ Share \\\\",
  " & (pp) & Growth (\\%) & Level (\\%) & (pp) \\\\",
  "\\midrule",
  sprintf("RD Estimate & %.3f & %.3f & %.3f & %.3f \\\\",
          rdd_change$coef[1], rdd_growth$coef[1],
          rdd_level$coef[1], rdd_change_q$coef[1]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          rdd_change$se[3], rdd_growth$se[3],
          rdd_level$se[3], rdd_change_q$se[3]),
  sprintf("Robust $p$-value & %.3f & %.3f & %.3f & %.3f \\\\",
          rdd_change$pv[3], rdd_growth$pv[3],
          rdd_level$pv[3], rdd_change_q$pv[3]),
  sprintf("Robust 95\\%% CI & [%.2f, %.2f] & [%.2f, %.2f] & [%.2f, %.2f] & [%.2f, %.2f] \\\\",
          rdd_change$ci[3,1], rdd_change$ci[3,2],
          rdd_growth$ci[3,1], rdd_growth$ci[3,2],
          rdd_level$ci[3,1], rdd_level$ci[3,2],
          rdd_change_q$ci[3,1], rdd_change_q$ci[3,2]),
  "\\midrule",
  sprintf("Bandwidth (pp) & %.2f & %.2f & %.2f & %.2f \\\\",
          rdd_change$bws[1,1], rdd_growth$bws[1,1],
          rdd_level$bws[1,1], rdd_change_q$bws[1,1]),
  sprintf("Eff.\\ $N$ (left/right) & %d/%d & %d/%d & %d/%d & %d/%d \\\\",
          rdd_change$N_h[1], rdd_change$N_h[2],
          rdd_growth$N_h[1], rdd_growth$N_h[2],
          rdd_level$N_h[1], rdd_level$N_h[2],
          rdd_change_q$N_h[1], rdd_change_q$N_h[2]),
  "Polynomial order & 1 & 1 & 1 & 2 \\\\",
  "Kernel & Triangular & Triangular & Triangular & Triangular \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Sharp RDD estimates at the 20\\% second-home share threshold. Column (1): change in secondary home share from 2017 to 2025 (percentage points). Column (2): total dwelling stock growth rate (\\%). Column (3): secondary home share level in 2025 (\\%). Column (4): same as (1) with local quadratic polynomial. Robust standard errors and bias-corrected confidence intervals following Calonico, Cattaneo, and Titiunik (2014). MSE-optimal bandwidth selection.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2, file.path(tab_dir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

# ================================================================
# TABLE 3: Robustness — Bandwidth and Specification Sensitivity
# ================================================================

cat("--- Table 3: Robustness ---\n")

bw <- robustness$bw_sensitivity

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Bandwidth and Specification Sensitivity}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Estimate & Robust SE & $p$-value & Eff.\\ $N$ \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Bandwidth sensitivity}} \\\\")

for (i in 1:nrow(bw)) {
  lab <- ifelse(bw$multiplier[i] == 1, sprintf("$h = %.2f$ (MSE-optimal)", bw$bandwidth[i]),
                sprintf("$h = %.2f$ ($%.1f \\times$ optimal)", bw$bandwidth[i], bw$multiplier[i]))
  tab3 <- c(tab3, sprintf("%s & %.3f & %.3f & %.3f & %d \\\\",
                          lab, bw$coef[i], bw$se_robust[i], bw$p_value[i], bw$n_eff[i]))
}

tab3 <- c(tab3,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Donut RDD}} \\\\")

donut <- robustness$donut
for (i in 1:nrow(donut)) {
  tab3 <- c(tab3, sprintf("Exclude $\\pm %.1f$ pp & %.3f & %.3f & %.3f & %d \\\\",
                          donut$donut_pp[i], donut$coef[i], donut$se_robust[i],
                          donut$p_value[i], donut$n_eff[i]))
}

tab3 <- c(tab3,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo cutoffs}} \\\\")

plac <- robustness$placebo_cutoffs
for (i in 1:nrow(plac)) {
  tab3 <- c(tab3, sprintf("Cutoff at %d\\%% & %.3f & %.3f & %.3f & %d \\\\",
                          plac$cutoff[i], plac$coef[i], plac$se_robust[i],
                          plac$p_value[i], plac$n_eff[i]))
}

tab3 <- c(tab3,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications use local linear regression with triangular kernel. Outcome: change in secondary home share (pp) from 2017 to 2025. Panel A varies the bandwidth around the MSE-optimal value. Panel B excludes observations within the stated distance of the 20\\% threshold. Panel C estimates RDD at placebo cutoffs where no policy discontinuity exists. Robust bias-corrected inference following Calonico, Cattaneo, and Titiunik (2014).",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3, file.path(tab_dir, "tab3_robustness.tex"))
cat("  Saved tab3_robustness.tex\n")

# ================================================================
# TABLE 4: Wave-Specific (Event Study) RDD Estimates
# ================================================================

cat("--- Table 4: Wave-Specific Estimates ---\n")

ws <- robustness$wave_specific
# Select key waves (not all 15 — pick every other year)
ws[, year := year(wave_date)]
# Keep one observation per year (March waves, plus latest)
ws_display <- ws[grepl("-03$", wave) | wave == "2018" | wave == max(wave)]
if (nrow(ws_display) > 8) ws_display <- ws_display[1:8]

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Wave-Specific RDD Estimates: Dynamic Treatment Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Wave & Estimate (pp) & Robust SE & $p$-value & Eff.\\ $N$ \\\\",
  "\\midrule")

for (i in 1:nrow(ws_display)) {
  tab4 <- c(tab4, sprintf("%s & %.3f%s & %.3f & %.3f & %d \\\\",
                          ws_display$wave[i],
                          ws_display$coef[i],
                          stars(ws_display$p_value[i]),
                          ws_display$se_robust[i],
                          ws_display$p_value[i],
                          ws_display$n_eff[i]))
}

tab4 <- c(tab4,
  "\\midrule",
  "\\multicolumn{5}{l}{McCrary density test: $p = 0.395$} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports a separate sharp RDD at the 20\\% threshold for the change in secondary home share from the first observed wave (2017) to the wave indicated. Local linear, triangular kernel, MSE-optimal bandwidth. *, **, *** denote significance at 10\\%, 5\\%, 1\\% levels using robust bias-corrected $p$-values. McCrary density test (Cattaneo, Jansson, and Ma 2020) for manipulation of the running variable at the threshold.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4, file.path(tab_dir, "tab4_eventstudy.tex"))
cat("  Saved tab4_eventstudy.tex\n")

# ================================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ================================================================

cat("--- Table F1: SDE ---\n")

# Compute SDE for main outcomes
sd_y_change <- sd(rdd_data$delta_pct_secondary, na.rm = TRUE)
sd_y_growth <- sd(rdd_data$pct_growth_dwellings, na.rm = TRUE)

# Main estimates
beta_change <- rdd_change$coef[1]
se_change <- rdd_change$se[3]
beta_growth <- rdd_growth$coef[1]
se_growth <- rdd_growth$se[3]

sde_change <- beta_change / sd_y_change
se_sde_change <- se_change / sd_y_change
sde_growth <- beta_growth / sd_y_growth
se_sde_growth <- se_growth / sd_y_growth

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

class_change <- classify_sde(sde_change)
class_growth <- classify_sde(sde_growth)

# Heterogeneity: Alpine vs non-Alpine municipalities (sample split)
# Alpine municipalities tend to have higher second-home shares
# Split at median first_pct_secondary among treated municipalities
median_sec <- median(rdd_data[treated == TRUE]$first_pct_secondary, na.rm = TRUE)

# High second-home municipalities (above median among treated)
high_sec <- rdd_data[first_pct_secondary >= median_sec]
low_sec <- rdd_data[first_pct_secondary < median_sec]

if (nrow(high_sec) > 50 & nrow(low_sec) > 50) {
  rdd_high <- tryCatch(
    rdrobust::rdrobust(y = high_sec$delta_pct_secondary, x = high_sec$running_var,
                       c = 0, kernel = "triangular", p = 1, bwselect = "mserd",
                       masspoints = "adjust"),
    error = function(e) NULL
  )
  rdd_low <- tryCatch(
    rdrobust::rdrobust(y = low_sec$delta_pct_secondary, x = low_sec$running_var,
                       c = 0, kernel = "triangular", p = 1, bwselect = "mserd",
                       masspoints = "adjust"),
    error = function(e) NULL
  )
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does a statutory ban on new second-home construction in municipalities exceeding a 20\\% second-home share convert housing stock from vacation to permanent residential use? ",
  "\\textbf{Policy mechanism:} The 2012 Second Home Initiative (Art.\\ 75b Federal Constitution) and implementing ZWG (SR 702, in force January 2016) prohibit new second-home authorization in municipalities above the threshold, aiming to redirect housing supply toward permanent residents in Alpine tourist communities. ",
  "\\textbf{Outcome definition:} (1) Change in municipality-level second-home share (percentage points) from 2017 to 2025, computed from the Federal Housing Inventory (ZWG); (2) total dwelling stock growth rate (\\%). ",
  "\\textbf{Treatment:} Binary --- municipality second-home share above versus below the 20\\% statutory threshold. ",
  "\\textbf{Data:} Federal Housing Inventory (ARE/BFS), 16 semi-annual waves 2017--2025, 2,131--2,255 municipalities per wave; cross-sectional RDD sample $N = 2{,}290$. ",
  "\\textbf{Method:} Sharp regression discontinuity design with local linear estimation, triangular kernel, MSE-optimal bandwidth (Calonico, Cattaneo, and Titiunik 2014), bias-corrected robust inference, mass-point adjustment. ",
  "\\textbf{Sample:} All Swiss municipalities with non-missing housing inventory data; treatment determined by initial (2017) second-home share. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-sectional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabf1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("$\\Delta$ Sec.\\ home share (pp) & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
          beta_change, se_change, sd_y_change, sde_change, se_sde_change, class_change),
  sprintf("Dwelling growth (\\%%) & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
          beta_growth, se_growth, sd_y_growth, sde_growth, se_sde_growth, class_growth),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample split by baseline second-home intensity)}} \\\\")

if (!is.null(rdd_high) && !is.null(rdd_low)) {
  sd_high <- sd(high_sec$delta_pct_secondary, na.rm = TRUE)
  sd_low <- sd(low_sec$delta_pct_secondary, na.rm = TRUE)
  sde_high <- rdd_high$coef[1] / sd_high
  sde_low <- rdd_low$coef[1] / sd_low
  se_sde_high <- rdd_high$se[3] / sd_high
  se_sde_low <- rdd_low$se[3] / sd_low

  tabf1 <- c(tabf1,
    sprintf("High intensity ($\\geq$ %.0f\\%%) & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
            median_sec, rdd_high$coef[1], rdd_high$se[3], sd_high,
            sde_high, se_sde_high, classify_sde(sde_high)),
    sprintf("Low intensity ($<$ %.0f\\%%) & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
            median_sec, rdd_low$coef[1], rdd_low$se[3], sd_low,
            sde_low, se_sde_low, classify_sde(sde_low)))
} else {
  tabf1 <- c(tabf1,
    "High intensity & --- & --- & --- & --- & --- & --- \\\\",
    "Low intensity & --- & --- & --- & --- & --- & --- \\\\")
}

tabf1 <- c(tabf1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabf1, file.path(tab_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
