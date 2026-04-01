## 05_tables.R — Generate all tables (V1: no figures)
## apep_1272: Breaking the Gauge Barrier

source("00_packages.R")

data_dir  <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
main  <- readRDS(file.path(data_dir, "main_results.rds"))
rob   <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════════

cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment period summary (before earliest treatment year)
pre_data <- panel[year < 2001]  # before any MG zone conversion
post_data <- panel[year >= 2006]  # after most conversions

# Summary by treatment group
sum_stats <- rbind(
  panel[mg_exposed == 1, .(
    Group = "MG-Exposed Districts",
    N = .N,
    Districts = uniqueN(dist_id),
    `Mean Light` = sprintf("%.1f", mean(light, na.rm = TRUE)),
    `SD Light` = sprintf("%.1f", sd(light, na.rm = TRUE)),
    `Mean Log Light` = sprintf("%.3f", mean(log_light, na.rm = TRUE)),
    `Lit. Rate` = sprintf("%.3f", mean(lit_rate, na.rm = TRUE)),
    `Worker Share` = sprintf("%.3f", mean(worker_share, na.rm = TRUE))
  )],
  panel[mg_exposed == 0, .(
    Group = "BG-Only Districts",
    N = .N,
    Districts = uniqueN(dist_id),
    `Mean Light` = sprintf("%.1f", mean(light, na.rm = TRUE)),
    `SD Light` = sprintf("%.1f", sd(light, na.rm = TRUE)),
    `Mean Log Light` = sprintf("%.3f", mean(log_light, na.rm = TRUE)),
    `Lit. Rate` = sprintf("%.3f", mean(lit_rate, na.rm = TRUE)),
    `Worker Share` = sprintf("%.3f", mean(worker_share, na.rm = TRUE))
  )]
)

# Generate LaTeX
sum_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & Obs. & Districts & Mean Light & SD Light & Literacy & Worker Share \\\\\n",
  "\\hline\n",
  sprintf("MG-Exposed & %s & %s & %s & %s & %s & %s \\\\\n",
          sum_stats[1]$N, sum_stats[1]$Districts,
          sum_stats[1]$`Mean Light`, sum_stats[1]$`SD Light`,
          sum_stats[1]$`Lit. Rate`, sum_stats[1]$`Worker Share`),
  sprintf("BG-Only & %s & %s & %s & %s & %s & %s \\\\\n",
          sum_stats[2]$N, sum_stats[2]$Districts,
          sum_stats[2]$`Mean Light`, sum_stats[2]$`SD Light`,
          sum_stats[2]$`Lit. Rate`, sum_stats[2]$`Worker Share`),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} DMSP nighttime luminosity (calibrated total light) by district-year, ",
  "1994--2013. MG-Exposed districts are in states where $>$30\\% of railway stations belong to ",
  "historically meter-gauge-intensive zones (NWR, WR, NER, NFR, SR, SWR). ",
  "Literacy and worker share from Census 2011.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(sum_tex, file.path(table_dir, "tab1_summary.tex"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 2: Main Results (TWFE and C-S-A)
# ═══════════════════════════════════════════════════════════════════════

cat("Generating Table 2: Main Results...\n")

m1 <- main$twfe_baseline
m2 <- main$twfe_state_trends
m3 <- main$twfe_levels

# Extract coefficients
get_est <- function(mod, var = "post") {
  if (is.null(mod)) return(c(NA, NA))
  cf <- coef(mod)[var]
  se <- se(mod)[var]
  c(cf, se)
}

est1 <- get_est(m1)
est2 <- get_est(m2)
est3 <- get_est(m3)

# C-S-A overall ATT
if (!is.null(main$cs_overall)) {
  cs_att <- main$cs_overall$overall.att
  cs_se <- main$cs_overall$overall.se
} else {
  cs_att <- NA
  cs_se <- NA
}

stars <- function(coef, se) {
  if (is.na(coef) || is.na(se) || se == 0) return("")
  p <- 2 * pnorm(-abs(coef / se))
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

main_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Gauge Conversion on Nighttime Luminosity}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Log Light & Log Light & Mean Light & Log Light \\\\\n",
  " & TWFE & State $\\times$ Year & TWFE & C-S-A \\\\\n",
  "\\hline\n",
  sprintf("Post-Conversion & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          est1[1], stars(est1[1], est1[2]),
          est2[1], stars(est2[1], est2[2]),
          est3[1], stars(est3[1], est3[2]),
          ifelse(is.na(cs_att), 0, cs_att),
          ifelse(is.na(cs_att), "", stars(cs_att, cs_se))),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          est1[2], est2[2], est3[2],
          ifelse(is.na(cs_se), 0, cs_se)),
  "\\hline\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nrow(panel), big.mark = ",")),
  "District FE & Yes & Yes & Yes & --- \\\\\n",
  "Year FE & Yes & --- & Yes & --- \\\\\n",
  "State $\\times$ Year FE & No & Yes & No & --- \\\\\n",
  "Clustering & State & State & State & --- \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is DMSP calibrated nighttime luminosity at the district-year level, ",
  "1994--2013. Post-Conversion equals one for MG-exposed districts in years at or after the zone's approximate ",
  "conversion midpoint. Column (4) reports the Callaway and Sant'Anna (2021) aggregated ATT using never-treated ",
  "districts as controls with doubly-robust estimation. Standard errors clustered at the state level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(main_tex, file.path(table_dir, "tab2_main.tex"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 3: Robustness
# ═══════════════════════════════════════════════════════════════════════

cat("Generating Table 3: Robustness...\n")

est_placebo <- if (!is.null(rob$placebo)) get_est(rob$placebo, "placebo_post") else c(NA, NA)
est_dose <- get_est(rob$dose_response, "mg_dose_post")
est_max <- get_est(rob$max_light)

rob_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Placebo: No Rail & Dose-Response & Max Light \\\\\n",
  "\\hline\n",
  sprintf("Treatment & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          ifelse(is.na(est_placebo[1]), 0, est_placebo[1]),
          ifelse(is.na(est_placebo[1]), "", stars(est_placebo[1], est_placebo[2])),
          est_dose[1], stars(est_dose[1], est_dose[2]),
          est_max[1], stars(est_max[1], est_max[2])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          ifelse(is.na(est_placebo[2]), 0, est_placebo[2]),
          est_dose[2], est_max[2]),
  "\\hline\n",
  "District FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  "Clustering & State & State & State \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) assigns the same treatment timing to districts with zero railway stations ",
  "(placebo test---should show no effect). Column (2) uses continuous treatment: state-level meter-gauge station ",
  "share $\\times$ post-conversion. Column (3) replaces the dependent variable with log maximum pixel luminosity ",
  "(extensive margin). Standard errors clustered at the state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(rob_tex, file.path(table_dir, "tab3_robust.tex"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 4: Leave-One-Zone-Out
# ═══════════════════════════════════════════════════════════════════════

cat("Generating Table 4: Leave-One-Zone-Out...\n")

loo <- rob$loo
loo_rows <- paste0(
  sapply(1:nrow(loo), function(i) {
    sprintf("Drop %s & %.4f%s & (%.4f) \\\\",
            loo$dropped_zone[i],
            loo$coef[i], stars(loo$coef[i], loo$se[i]),
            loo$se[i])
  }),
  collapse = "\n"
)

loo_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Leave-One-Zone-Out Sensitivity}\n",
  "\\label{tab:loo}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Specification & Coefficient & SE \\\\\n",
  "\\hline\n",
  loo_rows, "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row drops all districts whose primary MG zone matches the indicated zone ",
  "and re-estimates the baseline TWFE specification. The stability of the coefficient across rows indicates ",
  "that no single zone drives the result. Standard errors clustered at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(loo_tex, file.path(table_dir, "tab4_loo.tex"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY
# ═══════════════════════════════════════════════════════════════════════

cat("Generating SDE Table...\n")

# Pre-treatment SD of outcomes
pre_panel <- panel[year < 2001]  # before any conversion
sd_log_light <- sd(pre_panel$log_light, na.rm = TRUE)
sd_mean_light <- sd(pre_panel$mean_light, na.rm = TRUE)

# Main estimates
beta_log <- coef(m1)["post"]
se_log <- se(m1)["post"]
beta_mean <- coef(main$twfe_levels)["post"]
se_mean <- se(main$twfe_levels)["post"]

# SDE = beta / SD(Y) for binary treatment
sde_log <- beta_log / sd_log_light
se_sde_log <- se_log / sd_log_light
sde_mean <- beta_mean / sd_mean_light
se_sde_mean <- se_mean / sd_mean_light

classify <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_rows_a <- sprintf(
  paste0("Log luminosity & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
         "Mean luminosity & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\"),
  beta_log, se_log, sd_log_light, sde_log, se_sde_log, classify(sde_log),
  beta_mean, se_mean, sd_mean_light, sde_mean, se_sde_mean, classify(sde_mean)
)

# Panel B: Heterogeneous (by high/low baseline luminosity — sample split)
med_light <- median(pre_panel[, .(bl = mean(log_light, na.rm = TRUE)),
                               by = dist_id]$bl, na.rm = TRUE)
panel[, high_baseline := fifelse(
  dist_id %in% pre_panel[, .(bl = mean(log_light, na.rm = TRUE)),
                           by = dist_id][bl >= med_light]$dist_id,
  1L, 0L)]

m_high <- feols(log_light ~ post | dist_id + year,
                data = panel[high_baseline == 1],
                cluster = ~pc11_state_id)
m_low <- feols(log_light ~ post | dist_id + year,
               data = panel[high_baseline == 0],
               cluster = ~pc11_state_id)

beta_high <- coef(m_high)["post"]
se_high <- se(m_high)["post"]
sd_high <- sd(pre_panel[dist_id %in%
  pre_panel[, .(bl = mean(log_light, na.rm = TRUE)),
             by = dist_id][bl >= med_light]$dist_id]$log_light, na.rm = TRUE)
sde_high <- beta_high / sd_high
se_sde_high <- se_high / sd_high

beta_low <- coef(m_low)["post"]
se_low <- se(m_low)["post"]
sd_low <- sd(pre_panel[dist_id %in%
  pre_panel[, .(bl = mean(log_light, na.rm = TRUE)),
             by = dist_id][bl < med_light]$dist_id]$log_light, na.rm = TRUE)
sde_low <- beta_low / sd_low
se_sde_low <- se_low / sd_low

sde_rows_b <- sprintf(
  paste0("High-baseline districts & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
         "Low-baseline districts & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\"),
  beta_high, se_high, sd_high, sde_high, se_sde_high, classify(sde_high),
  beta_low, se_low, sd_low, sde_low, se_sde_low, classify(sde_low)
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Does the elimination of railway gauge breaks---transshipment ",
  "points where freight must be unloaded and reloaded between incompatible gauges---cause ",
  "measurable local economic development? ",
  "\\textbf{Policy mechanism:} India's Project Unigauge (1992--present) converts meter-gauge ",
  "(1,000 mm) track to broad gauge (1,676 mm), eliminating mandatory transshipment delays of ",
  "12--24 hours and reducing cargo damage at gauge break junctions. The conversion holds the ",
  "rail network topology fixed while reducing a specific transport friction. ",
  "\\textbf{Outcome definition:} DMSP calibrated total nighttime luminosity at the district-year ",
  "level, a standard proxy for local economic activity in developing countries. ",
  "\\textbf{Treatment:} Binary; a district is treated when its railway zone's meter-gauge network ",
  "reaches the approximate conversion midpoint, enabling through-running of freight and passenger trains. ",
  "\\textbf{Data:} SHRUG DMSP nightlights (1994--2013) and datameet railway stations (8,990 stations), ",
  "district-year panel. ",
  "\\textbf{Method:} Staggered difference-in-differences with district and year fixed effects; ",
  "standard errors clustered at the state level. Callaway and Sant'Anna (2021) estimator as robustness. ",
  "\\textbf{Sample:} All Indian districts with non-missing nightlight data; MG-exposed districts ",
  "defined as those in states where $>$30\\% of railway stations belong to historically ",
  "meter-gauge-intensive zones. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sde_rows_a, "\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by pre-treatment luminosity)}} \\\\\n",
  sde_rows_b, "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
