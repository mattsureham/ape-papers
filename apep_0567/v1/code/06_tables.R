# ==============================================================================
# 06_tables.R — Generate all LaTeX tables from CSV results
# Paper: Protecting Landscapes, Punishing Renters (apep_0567)
# Lex Weber / Second Homes Initiative — Swiss rental market effects
# ==============================================================================

source("00_packages.R")

# Paths
data_dir   <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------

stars <- function(p) {

  ifelse(is.na(p), "",
    ifelse(p < 0.01, "$^{***}$",
      ifelse(p < 0.05, "$^{**}$",
        ifelse(p < 0.10, "$^{*}$", ""))))
}

fmt <- function(x, digits = 3) {
  formatC(round(x, digits), format = "f", digits = digits, big.mark = ",")
}

fmt_int <- function(x) {
  formatC(round(x, 0), format = "d", big.mark = ",")
}

write_tex <- function(lines, filename) {
  outfile <- file.path(tables_dir, filename)
  con <- file(outfile, "w")
  writeLines(lines, con)
  close(con)
  cat("Wrote:", outfile, "\n")
}


# ==============================================================================
# TABLE 1: Summary Statistics (Pre-Treatment, 2010-2012)
# ==============================================================================

cat("\n--- Table 1: Summary Statistics ---\n")

sumstats <- fread(file.path(data_dir, "sumstats.csv"))

# Data is long format: variable, n, mean, sd, median, p25, p75, group
# Reshape to wide: one row per variable with treated/control columns

treated  <- sumstats[group == "treated"]
control  <- sumstats[group == "control"]
ss_wide  <- merge(treated, control, by = "variable", suffixes = c("_t", "_c"))

# Variable labels for display — use actual variables in the data
var_labels <- c(
  "vacancy_rate"        = "Vacancy rate (\\%)",
  "population"          = "Population",
  "emp_total"           = "Total employment",
  "emp_secondary"       = "Secondary sector employment",
  "emp_tertiary"        = "Tertiary sector employment",
  "second_home_share"   = "Second-home share (\\%)"
)

# Order for display
var_order <- c("vacancy_rate", "population", "emp_total", "emp_secondary",
               "emp_tertiary", "second_home_share")
ss_wide <- ss_wide[match(var_order, ss_wide$variable), ]
ss_wide <- ss_wide[!is.na(ss_wide$variable), ]

lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Municipality Characteristics (2010--2012)}",
  "\\label{tab:sumstats}",
  "\\small",
  "\\begin{tabular}{l cc cc c}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Treated} & \\multicolumn{2}{c}{Control} & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD & Difference \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(ss_wide))) {
  row <- ss_wide[i]
  vname <- as.character(row$variable)
  label <- ifelse(vname %in% names(var_labels), var_labels[vname], vname)

  diff_val <- row$mean_t - row$mean_c

  # Use integer formatting for large count variables
  if (vname %in% c("population", "emp_total", "emp_secondary", "emp_tertiary")) {
    tmean <- fmt_int(row$mean_t)
    tsd   <- fmt_int(row$sd_t)
    cmean <- fmt_int(row$mean_c)
    csd   <- fmt_int(row$sd_c)
    diff  <- fmt_int(diff_val)
  } else {
    tmean <- fmt(row$mean_t, 2)
    tsd   <- fmt(row$sd_t, 2)
    cmean <- fmt(row$mean_c, 2)
    csd   <- fmt(row$sd_c, 2)
    diff  <- fmt(diff_val, 2)
  }

  lines <- c(lines, paste0(
    label, " & ", tmean, " & (", tsd, ") & ",
    cmean, " & (", csd, ") & ", diff, " \\\\"
  ))
}

lines <- c(lines,
  "\\bottomrule",
  "\\multicolumn{6}{l}{\\footnotesize \\textit{Notes:} Means and standard deviations computed over 2010--2012 pre-treatment period.} \\\\",
  "\\multicolumn{6}{l}{\\footnotesize Treated municipalities are those where the second-home share exceeded 20\\% as of the 2012 vote.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

write_tex(lines, "tab_sumstats.tex")


# ==============================================================================
# TABLE 2: Main DiD Results
# ==============================================================================

cat("\n--- Table 2: Main DiD Results ---\n")

did_main <- fread(file.path(data_dir, "did_main.csv"))

# Columns: outcome, coefficient, se, t_stat, p_value, n_obs, n_units, r2_within
outcome_order <- c("vacancy_rate", "log_pop", "log_emp_total", "log_emp_tertiary")
outcome_labels <- c(
  "vacancy_rate"       = "Vacancy Rate",
  "log_pop"            = "Log Population",
  "log_emp_total"      = "Log Total Emp.",
  "log_emp_tertiary"   = "Log Tertiary Emp."
)

# Subset and order
did_main <- did_main[match(outcome_order, did_main$outcome), ]
did_main <- did_main[!is.na(did_main$outcome), ]

ncols <- nrow(did_main)
col_align <- paste0("l", paste(rep("c", ncols), collapse = ""))

lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of the Second Homes Initiative on Municipal Outcomes}",
  "\\label{tab:did_main}",
  "\\small",
  paste0("\\begin{tabular}{", col_align, "}"),
  "\\toprule"
)

# Header row
header <- " "
for (o in did_main$outcome) {
  header <- paste0(header, " & ", outcome_labels[o])
}
header <- paste0(header, " \\\\")
lines <- c(lines,
  header,
  paste0(" & ", paste(paste0("(", seq_len(ncols), ")"), collapse = " & "), " \\\\"),
  "\\midrule"
)

# Coefficient row
coef_row <- "Treated $\\times$ Post"
for (i in seq_len(ncols)) {
  coef_row <- paste0(coef_row, " & ", fmt(did_main$coefficient[i], 3), stars(did_main$p_value[i]))
}
coef_row <- paste0(coef_row, " \\\\")
lines <- c(lines, coef_row)

# SE row
se_row <- " "
for (i in seq_len(ncols)) {
  se_row <- paste0(se_row, " & (", fmt(did_main$se[i], 3), ")")
}
se_row <- paste0(se_row, " \\\\[6pt]")
lines <- c(lines, se_row)

# N row
n_row <- "Observations"
for (i in seq_len(ncols)) {
  n_row <- paste0(n_row, " & ", fmt_int(did_main$n_obs[i]))
}
n_row <- paste0(n_row, " \\\\")
lines <- c(lines, n_row)

# Municipalities row
muni_row <- "Municipalities"
for (i in seq_len(ncols)) {
  muni_row <- paste0(muni_row, " & ", fmt_int(did_main$n_units[i]))
}
muni_row <- paste0(muni_row, " \\\\")
lines <- c(lines, muni_row)

# FE rows
fe_muni <- paste0("Municipality FE", paste(rep(" & Yes", ncols), collapse = ""), " \\\\")
fe_year <- paste0("Year FE", paste(rep(" & Yes", ncols), collapse = ""), " \\\\")
lines <- c(lines, fe_muni, fe_year)

lines <- c(lines,
  "\\bottomrule",
  paste0("\\multicolumn{", ncols + 1, "}{l}{\\footnotesize \\textit{Notes:} Standard errors clustered at the municipality level in parentheses.} \\\\"),
  paste0("\\multicolumn{", ncols + 1, "}{l}{\\footnotesize $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.} \\\\"),
  paste0("\\multicolumn{", ncols + 1, "}{l}{\\footnotesize Treatment: municipality second-home share $>$ 20\\% at time of 2012 vote.} \\\\"),
  "\\end{tabular}",
  "\\end{table}"
)

write_tex(lines, "tab_did_main.tex")


# ==============================================================================
# TABLE 3: Mechanism -- Sectoral Employment (3 columns: total, secondary, tertiary)
# ==============================================================================

cat("\n--- Table 3: Sectoral Employment ---\n")

sectors <- fread(file.path(data_dir, "mechanism_sectors.csv"))

# Columns: outcome, coefficient, se, t_stat, p_value, n_obs, n_units, r2_within
# Outcomes: log_emp_total, log_emp_secondary, log_emp_tertiary
sector_order <- c("log_emp_total", "log_emp_secondary", "log_emp_tertiary")
sector_labels <- c(
  "log_emp_total"     = "Total",
  "log_emp_secondary" = "Secondary",
  "log_emp_tertiary"  = "Tertiary"
)

sectors <- sectors[match(sector_order, sectors$outcome), ]
sectors <- sectors[!is.na(sectors$outcome), ]

nsec <- nrow(sectors)
col_align <- paste0("l", paste(rep("c", nsec), collapse = ""))

lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Sectoral Employment Effects of the Second Homes Initiative}",
  "\\label{tab:mechanism_sectors}",
  "\\small",
  paste0("\\begin{tabular}{", col_align, "}"),
  "\\toprule"
)

# Header
header <- " "
for (i in seq_len(nsec)) {
  s <- as.character(sectors$outcome[i])
  lab <- ifelse(s %in% names(sector_labels), sector_labels[s], s)
  header <- paste0(header, " & ", lab)
}
header <- paste0(header, " \\\\")
col_nums <- paste0(" & ", paste(paste0("(", seq_len(nsec), ")"), collapse = " & "), " \\\\")
lines <- c(lines, header, col_nums, "\\midrule")

# Coefficient
coef_row <- "Treated $\\times$ Post"
for (i in seq_len(nsec)) {
  coef_row <- paste0(coef_row, " & ", fmt(sectors$coefficient[i], 3), stars(sectors$p_value[i]))
}
lines <- c(lines, paste0(coef_row, " \\\\"))

# SE
se_row <- " "
for (i in seq_len(nsec)) {
  se_row <- paste0(se_row, " & (", fmt(sectors$se[i], 3), ")")
}
lines <- c(lines, paste0(se_row, " \\\\[6pt]"))

# N
n_row <- "Observations"
for (i in seq_len(nsec)) {
  n_row <- paste0(n_row, " & ", fmt_int(sectors$n_obs[i]))
}
lines <- c(lines, paste0(n_row, " \\\\"))

# Municipalities
muni_row <- "Municipalities"
for (i in seq_len(nsec)) {
  muni_row <- paste0(muni_row, " & ", fmt_int(sectors$n_units[i]))
}
lines <- c(lines, paste0(muni_row, " \\\\"))

# FE rows
fe_muni <- paste0("Municipality FE", paste(rep(" & Yes", nsec), collapse = ""), " \\\\")
fe_year <- paste0("Year FE", paste(rep(" & Yes", nsec), collapse = ""), " \\\\")
lines <- c(lines, fe_muni, fe_year)

lines <- c(lines,
  "\\bottomrule",
  paste0("\\multicolumn{", nsec + 1, "}{l}{\\footnotesize \\textit{Notes:} Each column reports the Treated $\\times$ Post coefficient from a separate regression.} \\\\"),
  paste0("\\multicolumn{", nsec + 1, "}{l}{\\footnotesize Dependent variable: log sectoral employment. Standard errors clustered at the municipality level.} \\\\"),
  paste0("\\multicolumn{", nsec + 1, "}{l}{\\footnotesize $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.} \\\\"),
  "\\end{tabular}",
  "\\end{table}"
)

write_tex(lines, "tab_mechanism_sectors.tex")


# ==============================================================================
# TABLE 4: RDD Results
# ==============================================================================

cat("\n--- Table 4: RDD Results ---\n")

rdd <- fread(file.path(data_dir, "rdd_results.csv"))

# Columns: outcome, rd_estimate, rd_se, rd_p_value, rd_bw, rd_n_left, rd_n_right,
#           rd_bc_estimate, rd_robust_ci_l, rd_robust_ci_u, density_p
rdd_outcome_labels <- c(
  "vacancy_rate"       = "Vacancy Rate",
  "log_pop"            = "Log Population",
  "log_emp_total"      = "Log Total Emp.",
  "log_emp_tertiary"   = "Log Tertiary Emp."
)

nrdd <- nrow(rdd)
col_align <- paste0("l", paste(rep("c", nrdd), collapse = ""))

lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Regression Discontinuity Estimates at the 20\\% Second-Home Threshold}",
  "\\label{tab:rdd}",
  "\\small",
  paste0("\\begin{tabular}{", col_align, "}"),
  "\\toprule"
)

# Header
header <- " "
for (i in seq_len(nrdd)) {
  o <- as.character(rdd$outcome[i])
  lab <- ifelse(o %in% names(rdd_outcome_labels), rdd_outcome_labels[o], o)
  header <- paste0(header, " & ", lab)
}
header <- paste0(header, " \\\\")
col_nums <- paste0(" & ", paste(paste0("(", seq_len(nrdd), ")"), collapse = " & "), " \\\\")
lines <- c(lines, header, col_nums, "\\midrule")

# RD Estimate
coef_row <- "RD Estimate"
for (i in seq_len(nrdd)) {
  coef_row <- paste0(coef_row, " & ", fmt(rdd$rd_estimate[i], 3), stars(rdd$rd_p_value[i]))
}
lines <- c(lines, paste0(coef_row, " \\\\"))

# SE
se_row <- " "
for (i in seq_len(nrdd)) {
  se_row <- paste0(se_row, " & (", fmt(rdd$rd_se[i], 3), ")")
}
lines <- c(lines, paste0(se_row, " \\\\[6pt]"))

# Bias-corrected estimate
bc_row <- "BC Estimate"
for (i in seq_len(nrdd)) {
  bc_row <- paste0(bc_row, " & ", fmt(rdd$rd_bc_estimate[i], 3))
}
lines <- c(lines, paste0(bc_row, " \\\\"))

# Bandwidth
bw_row <- "Bandwidth"
for (i in seq_len(nrdd)) {
  bw_row <- paste0(bw_row, " & ", fmt(rdd$rd_bw[i], 2))
}
lines <- c(lines, paste0(bw_row, " \\\\"))

# Effective N (left)
nl_row <- "Eff.\\ $N$ (left)"
for (i in seq_len(nrdd)) {
  nl_row <- paste0(nl_row, " & ", fmt_int(rdd$rd_n_left[i]))
}
lines <- c(lines, paste0(nl_row, " \\\\"))

# Effective N (right)
nr_row <- "Eff.\\ $N$ (right)"
for (i in seq_len(nrdd)) {
  nr_row <- paste0(nr_row, " & ", fmt_int(rdd$rd_n_right[i]))
}
lines <- c(lines, paste0(nr_row, " \\\\"))

# Robust CI (from actual rd_robust_ci_l and rd_robust_ci_u columns)
rci_row <- "95\\% Robust CI"
for (i in seq_len(nrdd)) {
  rci_row <- paste0(rci_row, " & [", fmt(rdd$rd_robust_ci_l[i], 3), ", ", fmt(rdd$rd_robust_ci_u[i], 3), "]")
}
lines <- c(lines, paste0(rci_row, " \\\\"))

# Density test p-value
dens_row <- "Density $p$"
for (i in seq_len(nrdd)) {
  dens_row <- paste0(dens_row, " & ", fmt(rdd$density_p[i], 3))
}
lines <- c(lines, paste0(dens_row, " \\\\"))

lines <- c(lines,
  "\\bottomrule",
  paste0("\\multicolumn{", nrdd + 1, "}{l}{\\footnotesize \\textit{Notes:} Local polynomial RD estimates using MSE-optimal bandwidth (Calonico, Cattaneo, and Titiunik, 2014).} \\\\"),
  paste0("\\multicolumn{", nrdd + 1, "}{l}{\\footnotesize Running variable: municipality second-home share centered at 20\\%. Triangular kernel.} \\\\"),
  paste0("\\multicolumn{", nrdd + 1, "}{l}{\\footnotesize BC = bias-corrected. Robust CI from Calonico, Cattaneo, and Farrell (2020).} \\\\"),
  paste0("\\multicolumn{", nrdd + 1, "}{l}{\\footnotesize $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.} \\\\"),
  "\\end{tabular}",
  "\\end{table}"
)

write_tex(lines, "tab_rdd.tex")


# ==============================================================================
# APPENDIX TABLE F.1: Standardized Effect Sizes
# ==============================================================================

cat("\n--- Appendix Table F.1: Standardized Effect Sizes ---\n")

# Re-read both sources
did_sde    <- fread(file.path(data_dir, "did_main.csv"))
sumstats_f <- fread(file.path(data_dir, "sumstats.csv"))

# Use control group SDs for standardization
control_ss <- sumstats_f[group == "control"]

# Map outcome names to sumstats variable names for SD lookup
outcome_to_sumstat <- c(
  "vacancy_rate"       = "vacancy_rate",
  "log_pop"            = "population",
  "log_emp_total"      = "emp_total",
  "log_emp_tertiary"   = "emp_tertiary"
)

sde_labels <- c(
  "vacancy_rate"       = "Vacancy Rate",
  "log_pop"            = "Log Population",
  "log_emp_total"      = "Log Total Employment",
  "log_emp_tertiary"   = "Log Tertiary Employment"
)

# Classification thresholds (Cohen's d convention adapted for policy)
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  ifelse(abs_sde < 0.10, "Negligible",
    ifelse(abs_sde < 0.20, "Small",
      ifelse(abs_sde < 0.50, "Medium", "Large")))
}

sde_outcome_order <- c("vacancy_rate", "log_pop", "log_emp_total", "log_emp_tertiary")

lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main DiD Estimates}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{l c c c c l}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & Classification \\\\",
  "\\midrule"
)

for (o in sde_outcome_order) {
  did_row <- did_sde[outcome == o]
  if (nrow(did_row) == 0) next

  beta_hat <- did_row$coefficient[1]

  # Get SD from sumstats: use control SD as baseline
  sv <- outcome_to_sumstat[o]
  ss_row <- control_ss[variable == sv]

  if (nrow(ss_row) > 0) {
    sd_y <- ss_row$sd[1]
  } else {
    # Fallback: use SE * sqrt(N) as rough proxy
    sd_y <- did_row$se[1] * sqrt(did_row$n_obs[1])
  }

  sde_val <- beta_hat / sd_y
  classif <- classify_sde(sde_val)

  lab <- ifelse(o %in% names(sde_labels), sde_labels[o], o)

  lines <- c(lines, paste0(
    lab, " & TWFE DiD & ",
    fmt(beta_hat, 3), " & ",
    fmt(sd_y, 3), " & ",
    fmt(sde_val, 3), " & ",
    classif, " \\\\"
  ))
}

lines <- c(lines,
  "\\bottomrule",
  "\\multicolumn{6}{l}{\\footnotesize \\textit{Notes:} Standardized effect size (SDE) = $\\hat{\\beta}$ / SD($Y$), where SD($Y$) is the control-group} \\\\",
  "\\multicolumn{6}{l}{\\footnotesize pre-treatment standard deviation. Classification follows adapted Cohen's $d$ thresholds:} \\\\",
  "\\multicolumn{6}{l}{\\footnotesize Negligible ($<0.10$), Small ($0.10$--$0.20$), Medium ($0.20$--$0.50$), Large ($>0.50$).} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

write_tex(lines, "tab_sde.tex")


# ==============================================================================
# Summary
# ==============================================================================

cat("\n====================================================\n")
cat("All tables written to:", tables_dir, "\n")
cat("  tab_sumstats.tex          (Table 1)\n")
cat("  tab_did_main.tex          (Table 2)\n")
cat("  tab_mechanism_sectors.tex (Table 3)\n")
cat("  tab_rdd.tex               (Table 4)\n")
cat("  tab_sde.tex               (Appendix F.1)\n")
cat("====================================================\n")
