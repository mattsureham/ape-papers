## 06_tables.R — Generate all LaTeX tables
## APEP-0548: Selective Licensing and Housing Markets in England

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

## ===================================================================
## TABLE 1: Summary Statistics
## ===================================================================
cat("Table 1: Summary statistics...\n")

la_qtr <- fread(file.path(data_dir, "la_quarter_panel.csv"))

## Summary stats by treatment status (pre-treatment)
pre_treat <- la_qtr[treated == 0]

stats_by_group <- pre_treat[, .(
  `Mean log price` = mean(mean_log_price, na.rm = TRUE),
  `SD log price` = sd(mean_log_price, na.rm = TRUE),
  `Median price (£)` = mean(median_price, na.rm = TRUE),
  `Transactions/qtr` = mean(n_transactions, na.rm = TRUE),
  `Pct detached` = mean(pct_detached, na.rm = TRUE) * 100,
  `Pct flat` = mean(pct_flat, na.rm = TRUE) * 100,
  `Pct new build` = mean(pct_new, na.rm = TRUE) * 100,
  `N (LA-quarters)` = .N,
  `N (LAs)` = n_distinct(la_name)
), by = treated_ever]

## Reshape for LaTeX table
stats_long <- melt(stats_by_group, id.vars = "treated_ever",
                   variable.name = "Variable")
stats_wide <- dcast(stats_long, Variable ~ treated_ever,
                    value.var = "value")
setnames(stats_wide, c("Variable", "Never Licensed", "Ever Licensed"))

## Add full sample column
full_sample <- pre_treat[, .(
  `Mean log price` = mean(mean_log_price, na.rm = TRUE),
  `SD log price` = sd(mean_log_price, na.rm = TRUE),
  `Median price (£)` = mean(median_price, na.rm = TRUE),
  `Transactions/qtr` = mean(n_transactions, na.rm = TRUE),
  `Pct detached` = mean(pct_detached, na.rm = TRUE) * 100,
  `Pct flat` = mean(pct_flat, na.rm = TRUE) * 100,
  `Pct new build` = mean(pct_new, na.rm = TRUE) * 100,
  `N (LA-quarters)` = .N,
  `N (LAs)` = n_distinct(la_name)
)]
full_long <- melt(full_sample, measure.vars = names(full_sample),
                  variable.name = "Variable", value.name = "Full Sample")
stats_wide <- merge(stats_wide, full_long, by = "Variable", all.x = TRUE)

fwrite(stats_wide, file.path(data_dir, "summary_stats_table.csv"))

## Generate LaTeX
sink(file.path(tab_dir, "tab1_summary_stats.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics (Pre-Treatment Periods)}\n")
cat("\\label{tab:sumstats}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & Never Licensed & Ever Licensed & Full Sample \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(stats_wide))) {
  v <- stats_wide$Variable[i]
  nl <- stats_wide$`Never Licensed`[i]
  el <- stats_wide$`Ever Licensed`[i]
  fs <- stats_wide$`Full Sample`[i]

  if (v %in% c("N (LA-quarters)", "N (LAs)")) {
    cat(sprintf("%s & %s & %s & %s \\\\\n", v,
                formatC(nl, format = "d", big.mark = ","),
                formatC(el, format = "d", big.mark = ","),
                formatC(fs, format = "d", big.mark = ",")))
  } else if (v == "Median price (£)") {
    cat(sprintf("%s & %s & %s & %s \\\\\n", v,
                formatC(round(nl), format = "d", big.mark = ","),
                formatC(round(el), format = "d", big.mark = ","),
                formatC(round(fs), format = "d", big.mark = ",")))
  } else {
    cat(sprintf("%s & %.3f & %.3f & %.3f \\\\\n", v, nl, el, fs))
  }
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Summary statistics computed over pre-treatment ")
cat("LA-quarter observations. ``Ever Licensed'' includes all LAs that adopted ")
cat("selective licensing at any point during 2008--2024. Prices from HM Land ")
cat("Registry Price Paid Data. Percentages refer to composition of transactions ")
cat("within each LA-quarter.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ===================================================================
## TABLE 2: Main Results
## ===================================================================
cat("Table 2: Main results...\n")

## Load all results
twfe_res <- fread(file.path(data_dir, "twfe_results.csv"))
cs_res_file <- file.path(data_dir, "cs_did_overall_att.csv")
hedonic_file <- file.path(data_dir, "hedonic_results.csv")

results_list <- list()
results_list[["TWFE"]] <- twfe_res[1]
results_list[["TWFE + Controls"]] <- twfe_res[2]

if (file.exists(cs_res_file)) {
  cs_res <- fread(cs_res_file)
  results_list[["CS-DiD"]] <- data.table(
    model = "CS-DiD", coef = cs_res$att, se = cs_res$se,
    pval = 2 * pnorm(-abs(cs_res$att / cs_res$se)), n = NA
  )
}
if (file.exists(hedonic_file)) {
  results_list[["Hedonic"]] <- fread(hedonic_file)
}

main_results <- rbindlist(results_list, fill = TRUE)

## LaTeX output
sink(file.path(tab_dir, "tab2_main_results.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Effect of Selective Licensing on Property Prices}\n")
cat("\\label{tab:main}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & TWFE & TWFE + Controls & CS-DiD & Hedonic \\\\\n")
cat("\\midrule\n")

## Treatment effect row
cat("Selective Licensing")
for (i in seq_len(nrow(main_results))) {
  stars <- ""
  if (!is.na(main_results$pval[i])) {
    if (main_results$pval[i] < 0.01) stars <- "***"
    else if (main_results$pval[i] < 0.05) stars <- "**"
    else if (main_results$pval[i] < 0.10) stars <- "*"
  }
  cat(sprintf(" & %.4f%s", main_results$coef[i], stars))
}
cat(" \\\\\n")

## SE row
cat(" ")
for (i in seq_len(nrow(main_results))) {
  cat(sprintf(" & (%.4f)", main_results$se[i]))
}
cat(" \\\\\n")

cat("\\midrule\n")

## Fixed effects
cat("LA FE & Yes & Yes & -- & Yes \\\\\n")
cat("Year FE & Yes & Yes & -- & Year-Qtr \\\\\n")
cat("Property controls & No & Yes & No & Yes \\\\\n")
cat("Estimator & OLS & OLS & DR & OLS \\\\\n")

## N row
cat("Observations")
for (i in seq_len(nrow(main_results))) {
  if (!is.na(main_results$n[i])) {
    cat(sprintf(" & %s", formatC(main_results$n[i], format = "d", big.mark = ",")))
  } else {
    cat(" & --")
  }
}
cat(" \\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Dependent variable is log transaction price ")
cat("(Columns 1--3: LA-quarter mean; Column 4: individual transaction). ")
cat("Column 1: Two-way FE (LA + year). Column 2: adds composition controls ")
cat("(share detached, flat, new build, log transactions). Column 3: ")
cat("Callaway and Sant'Anna (2021) doubly-robust estimator with ")
cat("not-yet-treated comparison group. Column 4: transaction-level hedonic ")
cat("model with property-type, tenure, and age controls. Standard errors ")
cat("clustered at the LA level in parentheses. ")
cat("$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ===================================================================
## TABLE 3: Robustness — Placebo by Property Type
## ===================================================================
cat("Table 3: Placebo by property type...\n")

placebo_file <- file.path(data_dir, "placebo_property_type.csv")
if (file.exists(placebo_file)) {
  placebo <- fread(placebo_file)
  fwrite(placebo, file.path(tab_dir, "tab3_placebo_data.csv"))

  sink(file.path(tab_dir, "tab3_placebo.tex"))
  cat("\\begin{table}[t]\n")
  cat("\\centering\n")
  cat("\\caption{Treatment Effect by Property Type (Placebo Test)}\n")
  cat("\\label{tab:placebo}\n")
  cat("\\begin{tabular}{lccc}\n")
  cat("\\toprule\n")
  cat("Property Type & Coefficient & SE & N \\\\\n")
  cat("\\midrule\n")
  for (i in seq_len(nrow(placebo))) {
    stars <- ""
    if (placebo$pval[i] < 0.01) stars <- "***"
    else if (placebo$pval[i] < 0.05) stars <- "**"
    else if (placebo$pval[i] < 0.10) stars <- "*"
    cat(sprintf("%s & %.4f%s & (%.4f) & %s \\\\\n",
                placebo$label[i], placebo$coef[i], stars,
                placebo$se[i],
                formatC(placebo$n[i], format = "d", big.mark = ",")))
  }
  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\begin{tablenotes}[flushleft]\n")
  cat("\\small\n")
  cat("\\item \\textit{Notes:} TWFE estimates (LA + year FE) by property type. ")
  cat("Selective licensing targets the private rented sector, which is ")
  cat("disproportionately composed of flats and terraced houses. If licensing ")
  cat("operates through PRS quality improvements, effects should be largest ")
  cat("for flats and terraced houses (highest PRS share) and smallest for ")
  cat("detached houses (lowest PRS share). Standard errors clustered at LA level.\n")
  cat("\\end{tablenotes}\n")
  cat("\\end{table}\n")
  sink()
}

## ===================================================================
## TABLE 4: Randomization Inference Summary
## ===================================================================
cat("Table 4: RI summary...\n")

ri_file <- file.path(data_dir, "ri_summary.csv")
if (file.exists(ri_file)) {
  ri_sum <- fread(ri_file)
  fwrite(ri_sum, file.path(tab_dir, "tab4_ri_data.csv"))
}

cat("\n=== All tables generated ===\n")
cat("Tables saved to: ", tab_dir, "\n")
