## =============================================================================
## 06_tables.R — apep_0590
## All LaTeX tables for the paper
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "clean_panel.csv"))

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Table 1: Summary statistics\n")

# Pre-treatment period (2001-2018) summary by treatment status
pre <- panel[year <= 2018]
pre[, treated_ever := first_treat > 0]

sumstats <- pre[, .(
  `Tree cover loss (ha)` = mean(tree_cover_loss_ha, na.rm = TRUE),
  `SD tree cover loss` = sd(tree_cover_loss_ha, na.rm = TRUE),
  `asinh(tree cover loss)` = mean(asinh_loss, na.rm = TRUE),
  `Baseline forest area (ha)` = mean(forest_area_ha_2000, na.rm = TRUE),
  `Baseline forest share (%)` = mean(forest_share_2000, na.rm = TRUE),
  `Loss rate (per 1000 ha)` = mean(loss_rate, na.rm = TRUE),
  `Municipality area (ha)` = mean(muni_area_ha, na.rm = TRUE),
  `N municipality-years` = .N,
  `N municipalities` = uniqueN(GID_2)
), by = treated_ever]

# Transpose for LaTeX
vars <- setdiff(names(sumstats), "treated_ever")
tab1_data <- data.frame(
  Variable = vars,
  Treated = unlist(sumstats[treated_ever == TRUE, ..vars]),
  Control = unlist(sumstats[treated_ever == FALSE, ..vars])
)
tab1_data$Difference <- tab1_data$Treated - tab1_data$Control

# Format numbers
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Period (2001--2018)}",
  "\\label{tab:sumstats}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Treated & Control & Difference \\\\",
  " & Municipalities & Municipalities & \\\\",
  "\\midrule"
)

for (i in 1:nrow(tab1_data)) {
  v <- tab1_data$Variable[i]
  d <- ifelse(grepl("N ", v), 0, 2)
  line <- paste0(v, " & ", fmt(tab1_data$Treated[i], d),
                 " & ", fmt(tab1_data$Control[i], d),
                 " & ", fmt(tab1_data$Difference[i], d), " \\\\")
  tab1_lines <- c(tab1_lines, line)
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment means computed over 2001--2018. Treated municipalities are those in states where Sembrando Vida operated by 2021. Tree cover loss from Hansen/UMD Global Forest Change v1.12 (30m resolution). Baseline forest area defined as pixels with $\\geq$25\\% canopy closure in 2000.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tab_dir, "tab1_sumstats.tex"))

# =============================================================================
# Table 2: Main Results
# =============================================================================
cat("Table 2: Main results\n")

main <- fread(file.path(data_dir, "main_results_summary.csv"))

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Sembrando Vida on Tree Cover Loss}",
  "\\label{tab:main_results}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & asinh(Loss) & Loss (ha) & Loss Rate & TWFE \\\\",
  "\\midrule"
)

for (i in 1:nrow(main)) {
  est_line <- paste0("ATT & ", fmt(main$estimate[i], 4),
                     " & ", fmt(main$estimate[min(i+1, nrow(main))], 4))
  # Build row by row
}

# More structured approach
tab2_lines <- c(tab2_lines,
  paste0("ATT & ", fmt(main$estimate[1], 4),
         " & ", fmt(main$estimate[2], 2),
         " & ", fmt(main$estimate[3], 4),
         " & ", fmt(main$estimate[4], 4), " \\\\"),
  paste0(" & (", fmt(main$se[1], 4), ")",
         " & (", fmt(main$se[2], 2), ")",
         " & (", fmt(main$se[3], 4), ")",
         " & (", fmt(main$se[4], 4), ") \\\\"),
  paste0(" & [", fmt(main$ci_lower[1], 4), ", ", fmt(main$ci_upper[1], 4), "]",
         " & [", fmt(main$ci_lower[2], 2), ", ", fmt(main$ci_upper[2], 2), "]",
         " & [", fmt(main$ci_lower[3], 4), ", ", fmt(main$ci_upper[3], 4), "]",
         " & [", fmt(main$ci_lower[4], 4), ", ", fmt(main$ci_upper[4], 4), "] \\\\"),
  "\\midrule",
  "Estimator & CS-DiD & CS-DiD & CS-DiD & TWFE \\\\",
  "Control group & Never-treated & Never-treated & Never-treated & --- \\\\",
  paste0("Observations & ", formatC(nrow(panel), big.mark = ","),
         " & ", formatC(nrow(panel), big.mark = ","),
         " & ", formatC(nrow(panel), big.mark = ","),
         " & ", formatC(nrow(panel), big.mark = ","), " \\\\"),
  paste0("Municipalities & ", formatC(uniqueN(panel$GID_2), big.mark = ","),
         " & ", formatC(uniqueN(panel$GID_2), big.mark = ","),
         " & ", formatC(uniqueN(panel$GID_2), big.mark = ","),
         " & ", formatC(uniqueN(panel$GID_2), big.mark = ","), " \\\\"),
  paste0("Treated munis & ", formatC(uniqueN(panel[first_treat > 0, GID_2]), big.mark = ","),
         " & ", formatC(uniqueN(panel[first_treat > 0, GID_2]), big.mark = ","),
         " & ", formatC(uniqueN(panel[first_treat > 0, GID_2]), big.mark = ","),
         " & ", formatC(uniqueN(panel[first_treat > 0, GID_2]), big.mark = ","), " \\\\"),
  "Inference & Bootstrap & Bootstrap & Bootstrap & State-clustered \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns 1--3 report Callaway and Sant'Anna (2021) ATT estimates using never-treated municipalities as the control group and doubly-robust estimation. Column 4 reports standard two-way fixed effects for comparison. Standard errors in parentheses; 95\\% confidence intervals in brackets. The outcome in Column 1 is the inverse hyperbolic sine of tree cover loss (hectares), Column 2 is tree cover loss in hectares, Column 3 is tree cover loss per 1,000 hectares of municipality area. Columns 1--3 use the multiplier bootstrap (1,000 iterations) for inference; Column 4 uses state-clustered standard errors.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tab_dir, "tab2_main_results.tex"))

# =============================================================================
# Table 3: Heterogeneity by Ecosystem and Forest Cover
# =============================================================================
cat("Table 3: Heterogeneity\n")

eco <- fread(file.path(data_dir, "heterogeneity_ecosystem.csv"))
forest_het <- fread(file.path(data_dir, "heterogeneity_forest_cover.csv"))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneous Effects by Ecosystem and Baseline Forest Cover}",
  "\\label{tab:heterogeneity}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & ATT & SE & 95\\% CI & Treated & Control \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: By Ecosystem Type}} \\\\"
)

for (i in 1:nrow(eco)) {
  ci <- paste0("[", fmt(eco$att[i] - 1.96 * eco$se[i], 4), ", ",
               fmt(eco$att[i] + 1.96 * eco$se[i], 4), "]")
  tab3_lines <- c(tab3_lines,
    paste0("\\quad ", eco$ecosystem[i],
           " & ", fmt(eco$att[i], 4),
           " & (", fmt(eco$se[i], 4), ")",
           " & ", ci,
           " & ", formatC(eco$n_treated[i], big.mark = ","),
           " & ", formatC(eco$n_control[i], big.mark = ","), " \\\\"))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: By Baseline Forest Cover}} \\\\"
)

for (i in 1:nrow(forest_het)) {
  ci <- paste0("[", fmt(forest_het$att[i] - 1.96 * forest_het$se[i], 4), ", ",
               fmt(forest_het$att[i] + 1.96 * forest_het$se[i], 4), "]")
  tab3_lines <- c(tab3_lines,
    paste0("\\quad ", forest_het$subsample[i],
           " & ", fmt(forest_het$att[i], 4),
           " & (", fmt(forest_het$se[i], 4), ")",
           " & ", ci,
           " & ", formatC(forest_het$n_treated[i], big.mark = ","),
           " & ", formatC(forest_het$n_control[i], big.mark = ","), " \\\\"))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All estimates use Callaway and Sant'Anna (2021) with never-treated controls and doubly-robust estimation. Outcome is asinh(tree cover loss in hectares). Panel A splits municipalities by baseline ecosystem type (classified by tree cover density in 2000). Panel B splits at the median baseline forest share among treated municipalities. Standard errors in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tab_dir, "tab3_heterogeneity.tex"))

# =============================================================================
# Table 4: Robustness (for Appendix)
# =============================================================================
cat("Table 4: Robustness summary\n")

rob <- fread(file.path(data_dir, "robustness_summary.csv"))

# Compute sample sizes for each specification
n_obs_main <- nrow(panel)
n_munis_main <- uniqueN(panel$GID_2)
n_treated_main <- uniqueN(panel[first_treat > 0, GID_2])

# Placebo uses pre-2018 data and drops some units
panel_placebo_check <- panel[year <= 2018]
panel_placebo_check[, ftp := fifelse(first_treat > 0, first_treat - 4, 0L)]
panel_placebo_check <- panel_placebo_check[ftp >= 2005 | ftp == 0]
n_obs_placebo <- nrow(panel_placebo_check)
n_munis_placebo <- uniqueN(panel_placebo_check$GID_2)
n_treated_placebo <- uniqueN(panel_placebo_check[ftp > 0, GID_2])

rob_n_obs <- c(n_obs_main, n_obs_main, n_obs_main, n_obs_placebo)
rob_n_munis <- c(n_munis_main, n_munis_main, n_munis_main, n_munis_placebo)
rob_n_treated <- c(n_treated_main, n_treated_main, n_treated_main, n_treated_placebo)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & ATT & SE & Observations & Municipalities \\\\",
  "\\midrule"
)

for (i in 1:nrow(rob)) {
  tab4_lines <- c(tab4_lines,
    paste0(rob$specification[i],
           " & ", fmt(rob$estimate[i], 4),
           " & (", fmt(rob$se[i], 4), ")",
           " & ", formatC(rob_n_obs[i], big.mark = ","),
           " & ", formatC(rob_n_munis[i], big.mark = ","),
           " (", formatC(rob_n_treated[i], big.mark = ","), " treated) \\\\"))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All CS-DiD specifications use doubly-robust estimation with multiplier bootstrap inference (1,000 iterations). Main result uses never-treated controls. Not-yet-treated uses later-treated municipalities as additional controls. TWFE reports standard two-way fixed effects with state-clustered SEs for comparison. Placebo shifts treatment 4 years earlier and uses pre-2019 data only. Outcome is asinh(tree cover loss in hectares) throughout.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tab_dir, "tab4_robustness.tex"))

# =============================================================================
# Table 5: Leave-One-State-Out (for Appendix)
# =============================================================================
cat("Table 5: Leave-one-state-out\n")

loo <- fread(file.path(data_dir, "leave_one_state_out.csv"))
loo[, ci_lower := att - 1.96 * se]
loo[, ci_upper := att + 1.96 * se]

# Compute N obs and N munis for each excluded state
loo[, n_obs := NA_integer_]
loo[, n_munis := NA_integer_]
for (i in 1:nrow(loo)) {
  sub <- panel[NAME_1 != loo$excluded_state[i]]
  loo[i, n_obs := nrow(sub)]
  loo[i, n_munis := uniqueN(sub$GID_2)]
}

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Leave-One-State-Out Sensitivity}",
  "\\label{tab:loo}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Excluded State & ATT & SE & 95\\% CI & N (munis) \\\\",
  "\\midrule"
)

for (i in 1:nrow(loo)) {
  ci <- paste0("[", fmt(loo$ci_lower[i], 4), ", ", fmt(loo$ci_upper[i], 4), "]")
  tab5_lines <- c(tab5_lines,
    paste0(loo$excluded_state[i],
           " & ", fmt(loo$att[i], 4),
           " & (", fmt(loo$se[i], 4), ")",
           " & ", ci,
           " & ", formatC(loo$n_obs[i], big.mark = ","),
           " (", formatC(loo$n_munis[i], big.mark = ","), ") \\\\"))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the Callaway and Sant'Anna (2021) ATT after excluding all municipalities from the named state. N reports municipality-year observations with number of municipalities in parentheses. Stability across exclusions indicates no single state drives the result.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tab_dir, "tab5_loo.tex"))

cat("\nAll tables generated.\n")
