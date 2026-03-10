## ============================================================================
## 06_tables.R — Generate LaTeX tables
## Schengen Border Controls and Regional Economic Activity
## ============================================================================

source("00_packages.R")

tables_dir <- "../tables/"

cat("=== Generating LaTeX Tables ===\n")

## ---------------------------------------------------------------------------
## Table 1: Summary Statistics
## ---------------------------------------------------------------------------
cat("Table 1: Summary stats...\n")

sum_stats <- fread(file.path(tables_dir, "tab1_summary_stats.csv"))

# Build LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: NUTS3 Regions by Treatment Status}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Region Type & Mean GDP/cap & SD GDP/cap & Mean Emp (000s) & SD Emp (000s) & Regions & Obs \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sum_stats))) {
  row <- sum_stats[i]
  type_label <- gsub("_", " ", row$region_type)
  type_label <- paste0(toupper(substr(type_label, 1, 1)), substr(type_label, 2, nchar(type_label)))
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %d & %s \\\\",
    type_label,
    format(round(row$mean_gdp_pc, 0), big.mark = ","),
    format(round(row$sd_gdp_pc, 0), big.mark = ","),
    format(round(row$mean_emp, 1), big.mark = ","),
    format(round(row$sd_emp, 1), big.mark = ","),
    row$n_regions,
    format(row$n_obs, big.mark = ",")
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment period (2003--2014). GDP per capita in EUR. Employment in thousands.",
  "Treated border regions are NUTS3 regions adjacent to Schengen internal borders where controls were reintroduced.",
  "Control border regions are NUTS3 regions on unaffected Schengen borders (e.g., Germany--Netherlands, Austria--Italy).",
  "Interior regions are non-border NUTS3 regions in the same countries.",
  "Source: Eurostat (nama\\_10r\\_3gdp, nama\\_10r\\_3empers).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary_stats.tex"))

## ---------------------------------------------------------------------------
## Table 2: Main Results
## ---------------------------------------------------------------------------
cat("Table 2: Main results...\n")

main <- fread(file.path(tables_dir, "tab2_main_results.csv"))

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Schengen Border Controls on Regional Economic Activity}",
  "\\label{tab:main}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & Log GDP/cap & Log Emp & Log GVA & Log GVA Trade & Log GVA Manuf & Log GDP/cap \\\\",
  " & TWFE & TWFE & TWFE & TWFE & TWFE & CS \\\\",
  "\\midrule"
)

# Add coefficient rows
coef_row <- "Border Control"
se_row <- ""
for (i in seq_len(nrow(main))) {
  est <- main[i, estimate]
  s <- main[i, se]
  stars <- main[i, stars]
  coef_row <- paste0(coef_row, " & ", sprintf("%.4f%s", est, stars))
  se_row <- paste0(se_row, " & (", sprintf("%.4f", s), ")")
}
coef_row <- paste0(coef_row, " \\\\")
se_row <- paste0(se_row, " \\\\")

# N row
n_row <- "Observations"
for (i in seq_len(nrow(main))) {
  n_row <- paste0(n_row, " & ", format(main[i, n_obs], big.mark = ","))
}
n_row <- paste0(n_row, " \\\\")

tab2_lines <- c(tab2_lines, coef_row, se_row,
  "\\midrule",
  n_row,
  "Region FE & Yes & Yes & Yes & Yes & Yes & --- \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes & --- \\\\",
  "Estimator & TWFE & TWFE & TWFE & TWFE & TWFE & CS (DR) \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns (1)--(5) report two-way fixed effects estimates with NUTS3 region and year fixed effects.",
  "Column (6) reports the Callaway and Sant'Anna (2021) doubly-robust estimator using not-yet-treated regions as controls.",
  "Standard errors clustered at the NUTS3 region level in parentheses.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "Source: Eurostat NUTS3 regional accounts, 2003--2023.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main_results.tex"))

## ---------------------------------------------------------------------------
## Table 3: Sun-Abraham Event Study
## ---------------------------------------------------------------------------
cat("Table 3: Event study...\n")

es <- fread(file.path(tables_dir, "tab3_event_study.csv"))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Sun--Abraham Event Study Estimates}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Event Time & Estimate & Std. Error & 95\\% CI \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es))) {
  row <- es[i]
  ci <- sprintf("[%.4f, %.4f]", row$estimate - 1.96 * row$se, row$estimate + 1.96 * row$se)
  star <- ifelse(row$p_value < 0.01, "***", ifelse(row$p_value < 0.05, "**",
                 ifelse(row$p_value < 0.1, "*", "")))
  tab3_lines <- c(tab3_lines, sprintf(
    "$t%+d$ & %.4f%s & (%.4f) & %s \\\\",
    row$event_time, row$estimate, star, row$se, ci
  ))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Sun and Abraham (2021) interaction-weighted estimator.",
  "Outcome: log GDP per capita. NUTS3 region and year fixed effects.",
  "Standard errors clustered at the region level.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_event_study.tex"))

## ---------------------------------------------------------------------------
## Table 4: Heterogeneity by Border Segment
## ---------------------------------------------------------------------------
cat("Table 4: Heterogeneity...\n")

het <- fread(file.path(tables_dir, "tab4_heterogeneity.csv"))

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Border Segment}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Border Segment & Estimate & Std. Error & $p$-value & Treated Regions \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(het))) {
  row <- het[i]
  star <- ifelse(row$p_value < 0.01, "***", ifelse(row$p_value < 0.05, "**",
                 ifelse(row$p_value < 0.1, "*", "")))
  tab4_lines <- c(tab4_lines, sprintf(
    "%s & %.4f%s & (%.4f) & %.3f & %d \\\\",
    row$segment, row$estimate, star, row$se, row$p_value, row$n_treated
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports a separate TWFE regression restricted to treated regions",
  "in the named border segment plus all control regions. Outcome: log GDP per capita.",
  "Standard errors clustered at the region level.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_heterogeneity.tex"))

cat("\n06_tables.R complete.\n")
