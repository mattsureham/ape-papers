# 05_tables.R — Generate LaTeX tables (manual formatting)
# apep_0685: Canada carbon pricing backstop

source("00_packages.R")

cat("=== Generating Tables ===\n")

analysis <- readRDS("../data/panel_analysis.rds")
models <- readRDS("../data/main_models.rds")
rob_models <- readRDS("../data/robustness_models.rds")

# Helper: format coefficient with stars
fmt_coef <- function(model, var = NULL) {
  ct <- coeftable(model)
  if (!is.null(var)) ct <- ct[var, , drop = FALSE]
  beta <- ct[1, 1]
  se <- ct[1, 2]
  pv <- ct[1, 4]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  list(
    coef = sprintf("%.3f%s", beta, stars),
    se = sprintf("(%.3f)", se),
    beta = beta, se_val = se, pval = pv
  )
}

# =========================================================================
# Table 1: Summary Statistics
# =========================================================================
cat("--- Table 1: Summary Stats ---\n")

# Compute stats
stats_fn <- function(x) {
  c(mean = mean(x, na.rm = TRUE),
    sd = sd(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE))
}

vars_list <- list(
  c("Total CO2e (kt)", "total_co2e", 1000),
  c("CO2 (kt)", "co2_tonnes", 1000),
  c("CH4 (CO2e kt)", "ch4_co2e", 1000),
  c("N2O (CO2e kt)", "n2o_co2e", 1000)
)

tab1_lines <- character()
for (v in vars_list) {
  label <- v[1]; col <- v[2]; divisor <- as.numeric(v[3])
  all_s <- stats_fn(analysis[[col]] / divisor)
  bk_s <- stats_fn(analysis[treated == 1][[col]] / divisor)
  ct_s <- stats_fn(analysis[treated == 0][[col]] / divisor)
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
    label, all_s["mean"], all_s["sd"],
    bk_s["mean"], bk_s["sd"],
    ct_s["mean"], ct_s["sd"]
  ))
}

n_bk <- uniqueN(analysis[treated == 1]$facility_id)
n_ct <- uniqueN(analysis[treated == 0]$facility_id)
n_bk_fy <- nrow(analysis[treated == 1])
n_ct_fy <- nrow(analysis[treated == 0])

tab1_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Facility-Level Greenhouse Gas Emissions}
\\label{tab:summary}
\\small
\\begin{tabular}{l cc cc cc}
\\hline\\hline
 & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Backstop} & \\multicolumn{2}{c}{Control} \\\\
 & Mean & SD & Mean & SD & Mean & SD \\\\
\\hline
", paste(tab1_lines, collapse = "\n"), "
\\hline
Facilities & \\multicolumn{2}{c}{", formatC(n_bk + n_ct, big.mark = ","),
"} & \\multicolumn{2}{c}{", n_bk,
"} & \\multicolumn{2}{c}{", n_ct, "} \\\\
Facility-years & \\multicolumn{2}{c}{", formatC(nrow(analysis), big.mark = ","),
"} & \\multicolumn{2}{c}{", formatC(n_bk_fy, big.mark = ","),
"} & \\multicolumn{2}{c}{", formatC(n_ct_fy, big.mark = ","), "} \\\\
Years & \\multicolumn{2}{c}{2004--2023} & \\multicolumn{2}{c}{2004--2023} & \\multicolumn{2}{c}{2004--2023} \\\\
\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\footnotesize
\\textit{Notes:} Emissions in kilotonnes (kt) of CO2 equivalent from ECCC's Greenhouse Gas Reporting Program (GHGRP). Facilities report if annual emissions $\\geq$ 10 kt CO2e. Backstop provinces: Ontario, Saskatchewan, Manitoba, New Brunswick (federal carbon pricing imposed April 2019). Control provinces: British Columbia (carbon tax since 2008), Quebec (cap-and-trade since 2013).
\\end{minipage}
\\end{table}")

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# =========================================================================
# Table 2: Main Results
# =========================================================================
cat("--- Table 2: Main Results ---\n")

m1 <- fmt_coef(models$twfe_base)
m2 <- fmt_coef(models$twfe_wti, "treat_post")
m2_wti <- fmt_coef(models$twfe_wti, "wti_energy")
m3 <- fmt_coef(models$sector_energy)
m4 <- fmt_coef(models$sector_nonenergy)

tab2_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Effect of Carbon Pricing Backstop on Facility Emissions}
\\label{tab:main}
\\begin{tabular}{l cccc}
\\hline\\hline
 & (1) & (2) & (3) & (4) \\\\
 & All & All & Energy-Int. & Non-Energy \\\\
\\hline
Backstop $\\times$ Post & ", m1$coef, " & ", m2$coef, " & ", m3$coef, " & ", m4$coef, " \\\\
 & ", m1$se, " & ", m2$se, " & ", m3$se, " & ", m4$se, " \\\\[6pt]
WTI $\\times$ Energy-Int. & & ", m2_wti$coef, " & & \\\\
 & & ", m2_wti$se, " & & \\\\[6pt]
\\hline
Facility FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Observations & ", formatC(nobs(models$twfe_base), big.mark = ","),
" & ", formatC(nobs(models$twfe_wti), big.mark = ","),
" & ", formatC(nobs(models$sector_energy), big.mark = ","),
" & ", formatC(nobs(models$sector_nonenergy), big.mark = ","), " \\\\
Within $R^2$ & ", sprintf("%.3f", fitstat(models$twfe_base, "wr2")$wr2),
" & ", sprintf("%.3f", fitstat(models$twfe_wti, "wr2")$wr2),
" & ", sprintf("%.3f", fitstat(models$sector_energy, "wr2")$wr2),
" & ", sprintf("%.3f", fitstat(models$sector_nonenergy, "wr2")$wr2), " \\\\
\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\footnotesize
\\textit{Notes:} Standard errors clustered by province in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Dependent variable: log total CO2e emissions. Columns (1)--(2): all sectors. Column (3): energy-intensive sectors (NAICS 21--33: mining, utilities, manufacturing). Column (4): non-energy-intensive sectors. Backstop provinces: ON, SK, MB, NB. Control: BC, QC.
\\end{minipage}
\\end{table}")

writeLines(tab2_tex, "../tables/tab2_main.tex")

# =========================================================================
# Table 3: Gas Decomposition
# =========================================================================
cat("--- Table 3: Gas Decomposition ---\n")

g_total <- fmt_coef(models$twfe_base)
g_co2 <- fmt_coef(models$gas_co2)
g_ch4 <- fmt_coef(models$gas_ch4)
g_n2o <- fmt_coef(models$gas_n2o)

tab3_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Gas Decomposition: Backstop Effects by Greenhouse Gas}
\\label{tab:gas}
\\begin{tabular}{l cccc}
\\hline\\hline
 & (1) & (2) & (3) & (4) \\\\
 & Total CO2e & CO2 & CH4 (CO2e) & N2O (CO2e) \\\\
\\hline
Backstop $\\times$ Post & ", g_total$coef, " & ", g_co2$coef, " & ", g_ch4$coef, " & ", g_n2o$coef, " \\\\
 & ", g_total$se, " & ", g_co2$se, " & ", g_ch4$se, " & ", g_n2o$se, " \\\\[6pt]
\\hline
Facility FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Observations & \\multicolumn{4}{c}{", formatC(nobs(models$twfe_base), big.mark = ","), "} \\\\
\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\footnotesize
\\textit{Notes:} Standard errors clustered by province in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Each column uses log emissions of the respective gas as dependent variable. CO2 in tonnes; CH4 and N2O converted to CO2-equivalent tonnes. The CO2-dominant effect is consistent with fuel switching rather than process changes.
\\end{minipage}
\\end{table}")

writeLines(tab3_tex, "../tables/tab3_gas.tex")

# =========================================================================
# Table 4: Robustness
# =========================================================================
cat("--- Table 4: Robustness ---\n")

r_base <- fmt_coef(models$twfe_base)
r_drop <- fmt_coef(rob_models$drop_2020)
r_ab <- fmt_coef(rob_models$include_ab, "treat_post_ab")
r_bal <- fmt_coef(rob_models$balanced)
r_plac <- fmt_coef(rob_models$placebo_2015, "placebo_treat")

tab4_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks}
\\label{tab:robust}
\\begin{tabular}{l ccccc}
\\hline\\hline
 & (1) & (2) & (3) & (4) & (5) \\\\
 & Baseline & Drop 2020 & Incl.\\ Alberta & Balanced & Placebo \\\\
\\hline
Backstop $\\times$ Post & ", r_base$coef, " & ", r_drop$coef, " & ", r_ab$coef, " & ", r_bal$coef, " & \\\\
 & ", r_base$se, " & ", r_drop$se, " & ", r_ab$se, " & ", r_bal$se, " & \\\\[6pt]
Placebo $\\times$ Post 2015 & & & & & ", r_plac$coef, " \\\\
 & & & & & ", r_plac$se, " \\\\[6pt]
\\hline
Facility FE & Yes & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes & Yes \\\\
Observations & ", formatC(nobs(models$twfe_base), big.mark = ","),
" & ", formatC(nobs(rob_models$drop_2020), big.mark = ","),
" & ", formatC(nobs(rob_models$include_ab), big.mark = ","),
" & ", formatC(nobs(rob_models$balanced), big.mark = ","),
" & ", formatC(nobs(rob_models$placebo_2015), big.mark = ","), " \\\\
\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\footnotesize
\\textit{Notes:} Standard errors clustered by province in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Dependent variable: log total CO2e. Column (1): baseline specification. Column (2): excludes 2020 (COVID-19). Column (3): adds Alberta (own carbon pricing system) as additional control. Column (4): balanced panel of facilities present in all 20 years (N=119). Column (5): placebo test assigning fake treatment in 2015, estimated on pre-period only (2004--2018).
\\end{minipage}
\\end{table}")

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# =========================================================================
# Table F1: SDE
# =========================================================================
cat("--- Table F1: SDE ---\n")

compute_sde <- function(model, outcome_var, data, label) {
  beta <- coef(model)[1]
  se_beta <- coeftable(model)[1, "Std. Error"]
  sd_y <- sd(data[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  class_label <- dplyr::case_when(
    sde < -0.15 ~ "Large neg.",
    sde < -0.05 ~ "Mod.\\ neg.",
    sde < -0.005 ~ "Small neg.",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small pos.",
    sde <= 0.15 ~ "Mod.\\ pos.",
    TRUE ~ "Large pos."
  )
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          label, beta, se_beta, sd_y, sde, se_sde, class_label)
}

sde_lines <- c(
  compute_sde(models$twfe_base, "log_total_co2e", analysis, "Total CO2e"),
  compute_sde(models$gas_co2, "log_co2", analysis, "CO2"),
  compute_sde(models$gas_ch4, "log_ch4_co2e", analysis, "CH4 (CO2e)"),
  compute_sde(models$gas_n2o, "log_n2o_co2e", analysis, "N2O (CO2e)"),
  compute_sde(models$sector_energy, "log_total_co2e",
              analysis[energy_intensive == 1], "Energy-int.\\ sectors"),
  compute_sde(models$sector_nonenergy, "log_total_co2e",
              analysis[energy_intensive == 0], "Non-energy sectors")
)

sde_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\small
\\begin{tabular}{l cccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
", paste(sde_lines, collapse = "\n"), "
\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\footnotesize
\\textit{Notes:} Standardized effect sizes computed as SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment.
Research question: Does mandatory carbon pricing reduce facility-level industrial greenhouse gas emissions?
Data: ECCC GHGRP, 2004--2023 ($N = ", formatC(nrow(analysis), big.mark = ","),
"$ facility-years). Method: TWFE DiD with facility and year fixed effects.
Treatment: federal carbon pricing backstop imposed on ON, SK, MB, NB (April 2019).
Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.
SDE $< -0.15$: large negative; $[-0.15, -0.05)$: moderate negative; $[-0.05, -0.005)$: small negative;
$[-0.005, 0.005]$: null; $(0.005, 0.05]$: small positive; $(0.05, 0.15]$: moderate positive; $> 0.15$: large positive.
\\end{minipage}
\\end{table}")

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
