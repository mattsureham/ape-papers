# 05_tables.R — Generate all LaTeX tables
# apep_0937: Grenfell fire and fire safety industry formation

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "regression_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

diagnostics <- jsonlite::read_json(file.path(data_dir, "diagnostics.json"))

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
cat("=== Table 1: Summary Statistics ===\n")

panel[, inc_ym := as.Date(inc_ym)]

pre <- panel[post_grenfell == 0]
post <- panel[post_grenfell == 1]

make_summ_row <- function(var, label, dt_pre, dt_post) {
  sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
    label,
    mean(dt_pre[[var]], na.rm = TRUE),
    sd(dt_pre[[var]], na.rm = TRUE),
    median(dt_pre[[var]], na.rm = TRUE),
    mean(dt_post[[var]], na.rm = TRUE),
    sd(dt_post[[var]], na.rm = TRUE),
    median(dt_post[[var]], na.rm = TRUE)
  )
}

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: LA-Month Panel}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Pre-Grenfell} & \\multicolumn{3}{c}{Post-Grenfell} \\\\",
  " & \\multicolumn{3}{c}{(2008m1--2017m6)} & \\multicolumn{3}{c}{(2017m7--2024m12)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Mean & SD & Median & Mean & SD & Median \\\\",
  "\\hline",
  make_summ_row("fire_incorp", "Fire safety incorporations", pre, post),
  make_summ_row("control_incorp", "Control construction incorp.", pre, post),
  sprintf("Flat share (time-invariant) & %.3f & %.3f & %.3f & & & \\\\",
          mean(pre$flat_share, na.rm = TRUE),
          sd(pre$flat_share, na.rm = TRUE),
          median(pre$flat_share, na.rm = TRUE)),
  sprintf("Total dwellings (000s) & %.1f & %.1f & %.1f & & & \\\\",
          mean(pre$total_dwellings, na.rm = TRUE) / 1000,
          sd(pre$total_dwellings, na.rm = TRUE) / 1000,
          median(pre$total_dwellings, na.rm = TRUE) / 1000),
  "\\hline",
  sprintf("Observations & \\multicolumn{3}{c}{%s} & \\multicolumn{3}{c}{%s} \\\\",
          format(nrow(pre), big.mark = ","),
          format(nrow(post), big.mark = ",")),
  sprintf("Local authorities & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
          uniqueN(pre$la_code), uniqueN(post$la_code)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Unit of observation is LA-month. Fire safety SIC codes: 84250 (Fire service activities), 71200 (Technical testing), 80200 (Security systems), 71121/71129 (Engineering), 43999 (Other specialised construction). Control SIC codes: 43210 (Electrical installation), 43220 (Plumbing), 43290 (Other construction installation). Flat share from Census dwelling data.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ===========================================================================
# Table 2: Main DiD Results
# ===========================================================================
cat("=== Table 2: Main DiD Results ===\n")

# Extract model statistics
get_stats <- function(model, label) {
  cf <- coeftable(model)
  row <- cf["treat_x_post", ]
  list(
    label = label,
    coef = row[1],
    se = row[2],
    pval = row[4],
    n = nobs(model),
    r2 = fitstat(model, "r2")$r2
  )
}

stats <- list(
  get_stats(m1, "OLS"),
  get_stats(m2, "OLS + Controls"),
  get_stats(m3, "Log(Y+1)"),
  get_stats(m4, "Poisson")
)

# Placebo
pl_cf <- coeftable(m_placebo)
placebo_stats <- list(
  label = "Placebo (Control SICs)",
  coef = pl_cf["treat_x_post", 1],
  se = pl_cf["treat_x_post", 2],
  pval = pl_cf["treat_x_post", 4],
  n = nobs(m_placebo),
  r2 = fitstat(m_placebo, "r2")$r2
)

stars <- function(p) {
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Flat Share on Fire Safety Firm Formation After Grenfell}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & OLS & OLS & Log & Poisson & Placebo \\\\",
  " & & + Controls & & & (Control SICs) \\\\",
  "\\hline",
  sprintf("Flat Share $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          stats[[1]]$coef, stars(stats[[1]]$pval),
          stats[[2]]$coef, stars(stats[[2]]$pval),
          stats[[3]]$coef, stars(stats[[3]]$pval),
          stats[[4]]$coef, stars(stats[[4]]$pval),
          placebo_stats$coef, stars(placebo_stats$pval)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          stats[[1]]$se, stats[[2]]$se, stats[[3]]$se, stats[[4]]$se, placebo_stats$se),
  "\\hline",
  "LA FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Control SIC incorp. & No & Yes & No & No & --- \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(stats[[1]]$n, big.mark = ","),
          format(stats[[2]]$n, big.mark = ","),
          format(stats[[3]]$n, big.mark = ","),
          format(stats[[4]]$n, big.mark = ","),
          format(placebo_stats$n, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports a separate regression of fire safety firm incorporations on the interaction of pre-Grenfell flat share (continuous, 0--1) with a post-June 2017 indicator. Standard errors clustered at the local authority level in parentheses. Column (5) replaces the dependent variable with control construction SIC incorporations (electrical, plumbing, other installation). $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

# ===========================================================================
# Table 3: Event Study / Regulatory Phases
# ===========================================================================
cat("=== Table 3: Regulatory Phase Results ===\n")

phase_cf <- coeftable(m_phases)
phase_names <- rownames(phase_cf)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Regulatory Cascade: Phase-Specific Effects on Fire Safety Firm Formation}",
  "\\label{tab:phases}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Phase & Coefficient & SE \\\\",
  "\\hline",
  "\\textit{Reference: Pre-Grenfell (2008--2017m6)} & --- & --- \\\\"
)

for (i in seq_along(phase_names)) {
  pn <- phase_names[i]
  # Extract readable name
  readable <- gsub("phase_f::", "", pn)
  readable <- gsub(":flat_share", "", readable)
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %.4f%s & (%.4f) \\\\",
            readable,
            phase_cf[i, 1], stars(phase_cf[i, 4]),
            phase_cf[i, 2]))
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  "LA FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Month FE & \\multicolumn{2}{c}{Yes} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          format(nobs(m_phases), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each coefficient reports the interaction of pre-Grenfell flat share with the indicated regulatory phase indicator. The omitted category is the pre-Grenfell period (2008m1--2017m6). Phase 1 covers the immediate aftermath (2017m7--2017m12). Phase 2 follows the Hackitt Review (2018m1--2019m12). Phase 3 follows the EWS1 requirement (2020m1--2021m10). Phase 4 follows the Building Safety Act (2021m11--2024m12). Standard errors clustered at the LA level. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_phases.tex"))
cat("  Saved tab3_phases.tex\n")

# ===========================================================================
# Table 4: Robustness Checks
# ===========================================================================
cat("=== Table 4: Robustness ===\n")

rob_models <- list(
  list(m = m_binary, name = "Binary (Q4 vs Q1)", coef_name = "binary_treat"),
  list(m = m_ddd, name = "Triple-diff (Fire vs Control)", coef_name = "triple"),
  list(m = m_no_london, name = "Excluding London", coef_name = "treat_x_post"),
  list(m = m_quarterly, name = "Quarterly aggregation", coef_name = "treat_x_post")
)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE & $N$ \\\\",
  "\\hline",
  sprintf("\\textit{Baseline} & %.4f%s & (%.4f) & %s \\\\",
          coef(m1)["treat_x_post"], stars(pvalue(m1)["treat_x_post"]),
          se(m1)["treat_x_post"],
          format(nobs(m1), big.mark = ","))
)

for (rm in rob_models) {
  cf <- coeftable(rm$m)
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %.4f%s & (%.4f) & %s \\\\",
            rm$name,
            cf[rm$coef_name, 1], stars(cf[rm$coef_name, 4]),
            cf[rm$coef_name, 2],
            format(nobs(rm$m), big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Row 1 reproduces the baseline from Table~\\ref{tab:main}, column (1). ``Binary'' compares LAs in the top quartile of flat share to the bottom quartile. ``Triple-diff'' interacts Flat Share $\\times$ Post with a fire-safety SIC indicator (vs.\\ control construction SICs). ``Excluding London'' drops all London boroughs (E09 codes). ``Quarterly'' aggregates the dependent variable to LA-quarter. All models include LA and time fixed effects. Standard errors clustered at the LA level. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))
cat("  Saved tab4_robustness.tex\n")

# ===========================================================================
# Table F1: SDE Appendix (MANDATORY)
# ===========================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
sd_y_pre <- diagnostics$sd_y_pre
main_beta <- diagnostics$main_coef
main_se <- diagnostics$main_se

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_x <- sd(panel[post_grenfell == 0]$flat_share, na.rm = TRUE)
sde_main <- main_beta * sd_x / sd_y_pre
sde_se <- main_se * sd_x / sd_y_pre

# Control SIC (placebo)
sd_y_control_pre <- sd(panel[post_grenfell == 0]$control_incorp, na.rm = TRUE)
placebo_beta <- diagnostics$placebo_coef
placebo_se_val <- coeftable(m_placebo)["treat_x_post", 2]
sde_placebo <- placebo_beta * sd_x / sd_y_control_pre
sde_placebo_se <- placebo_se_val * sd_x / sd_y_control_pre

# Classify SDE
classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

# Phase-specific SDEs for heterogeneity panel
phase_cf <- coeftable(m_phases)
phase_sdes <- list()
for (i in seq_len(nrow(phase_cf))) {
  phase_sdes[[i]] <- list(
    beta = phase_cf[i, 1],
    se = phase_cf[i, 2],
    sde = phase_cf[i, 1] * sd_x / sd_y_pre,
    sde_se = phase_cf[i, 2] * sd_x / sd_y_pre
  )
}

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Does a disaster-induced regulatory cascade (the 2017 Grenfell Tower fire and subsequent building safety legislation) cause formation of a new compliance-service industry, and does this industry form faster in local authorities with greater exposure to the affected building stock? ",
  "\\textbf{Policy mechanism:} The Grenfell fire revealed widespread dangerous cladding in high-rise buildings, triggering four major regulatory responses (Hackitt Review, EWS1 form requirement, Fire Safety Act, Building Safety Act) that collectively mandated fire safety assessments, cladding remediation certificates, and building safety cases for residential buildings above 18 metres, creating demand for specialist firms that barely existed before 2017. ",
  "\\textbf{Outcome definition:} Monthly count of new company incorporations in fire safety SIC codes (84250, 71200, 80200, 71121, 71129, 43999) registered at Companies House within each local authority. ",
  "\\textbf{Treatment:} Continuous; pre-Grenfell (2016) share of dwellings classified as flats in each local authority, interacted with a post-June 2017 indicator. ",
  "\\textbf{Data:} Companies House Free Company Data Product (275,439 firms in target SICs, 2008--2024) linked to local authorities via postcodes.io; dwelling stock from Census via NOMIS; ",
  format(nrow(panel), big.mark = ","), " LA-month observations across ",
  uniqueN(panel$la_code), " English local authorities. ",
  "\\textbf{Method:} OLS with LA and year-month fixed effects; standard errors clustered at the LA level. ",
  "\\textbf{Sample:} English local authorities only; Scotland excluded (devolved building regulations). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-LA standard deviation of flat share and SD($Y$) is the pre-treatment ",
  "standard deviation of monthly fire safety incorporations. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build table
tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Fire safety incorporations & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          main_beta, main_se, sd_y_pre, sde_main, sde_se, classify_sde(sde_main)),
  sprintf("Control construction (placebo) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          placebo_beta, placebo_se_val, sd_y_control_pre,
          sde_placebo, sde_placebo_se, classify_sde(sde_placebo)),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by regulatory phase)}} \\\\"
)

phase_labels <- c(
  "Phase 1: Fire (2017H2)",
  "Phase 2: Hackitt (2018--19)",
  "Phase 3: EWS1 (2020--21)",
  "Phase 4: BSA (2022--24)"
)

for (i in seq_along(phase_sdes)) {
  ps <- phase_sdes[[i]]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            phase_labels[i], ps$beta, ps$se, sd_y_pre,
            ps$sde, ps$sde_se, classify_sde(ps$sde)))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
