#' 06_tables.R — Generate all tables as LaTeX
#' Publication-quality tables for APEP-0517

source("00_packages.R")

DATA_DIR <- "../data"
TAB_DIR <- "../tables"
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

# ===================================================================
# Table 1: Summary statistics
# ===================================================================
cat("=== Table 1: Summary statistics ===\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))

# Near-boundary subsample
near <- panel[dist_km <= 5 & !is.na(dist_km)]

if (nrow(near) > 0) {
  sum_vars <- c("total_crime", "dist_km")
  crime_cols <- intersect(
    c("anti_social_behaviour", "violent_crime", "violence_and_sexual_offences",
      "burglary", "vehicle_crime", "criminal_damage_and_arson",
      "drugs", "other_theft", "shoplifting", "public_order", "robbery"),
    names(near)
  )
  sum_vars <- c(sum_vars, crime_cols)
  if ("imd_rank" %in% names(near)) sum_vars <- c(sum_vars, "imd_rank")

  sum_stats <- data.table(
    Variable = sum_vars,
    Mean = sapply(sum_vars, function(v) round(mean(near[[v]], na.rm = TRUE), 2)),
    SD = sapply(sum_vars, function(v) round(sd(near[[v]], na.rm = TRUE), 2)),
    Min = sapply(sum_vars, function(v) round(min(near[[v]], na.rm = TRUE), 2)),
    Max = sapply(sum_vars, function(v) round(max(near[[v]], na.rm = TRUE), 2)),
    N = sapply(sum_vars, function(v) sum(!is.na(near[[v]])))
  )

  # Clean variable names
  sum_stats[, Variable := gsub("_", " ", Variable)]
  sum_stats[, Variable := tools::toTitleCase(Variable)]

  # Write LaTeX
  latex_tab1 <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Summary Statistics: LSOAs Within 5km of PFA Boundaries}",
    "\\label{tab:summary}",
    "\\begin{adjustbox}{max width=\\textwidth}",
    "\\begin{tabular}{lccccc}",
    "\\toprule",
    "Variable & Mean & SD & Min & Max & N \\\\",
    "\\midrule",
    apply(sum_stats, 1, function(r)
      paste(r, collapse = " & ") %>% paste0(" \\\\")),
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{adjustbox}",
    "\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} Unit of observation is LSOA $\\times$ year. Sample restricted to LSOAs with population-weighted centroids within 5km of a Police Force Area boundary. Crime counts are annualized.}",
    "\\end{table}"
  )
  writeLines(latex_tab1, file.path(TAB_DIR, "tab1_summary.tex"))
  cat("  Saved tab1_summary.tex\n")
}

# ===================================================================
# Table 2: Main RDD results
# ===================================================================
cat("\n=== Table 2: Main RDD results ===\n")

main_result <- fread(file.path(DATA_DIR, "rdd_main_result.csv"))
type_results <- fread(file.path(DATA_DIR, "rdd_by_crime_type.csv"))

if (nrow(main_result) > 0 && !is.na(main_result$coef[1])) {
  # Combine main + key crime types, dropping any rows with NA p-values
  all_results <- rbind(main_result[, .(outcome, coef, se, p_value, n_eff)],
                        type_results[!is.na(p_value), .(outcome, coef, se, p_value, n_eff)],
                        fill = TRUE)
  all_results <- all_results[!is.na(p_value) & se > 0]

  # Format for LaTeX
  all_results[, stars := fcase(
    p_value < 0.01, "***",
    p_value < 0.05, "**",
    p_value < 0.10, "*",
    default = ""
  )]

  all_results[, coef_str := sprintf("%.4f%s", coef, stars)]
  all_results[, se_str := sprintf("(%.4f)", se)]
  all_results[, outcome_clean := gsub("^log_", "", outcome)]
  all_results[, outcome_clean := gsub("_", " ", outcome_clean)]
  all_results[, outcome_clean := tools::toTitleCase(outcome_clean)]

  latex_tab2 <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{RDD Estimates at Police Force Area Boundaries}",
    "\\label{tab:main_rdd}",
    "\\begin{adjustbox}{max width=\\textwidth}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Outcome & Coefficient & SE & $N_{\\text{eff}}$ & $p$-value \\\\",
    "\\midrule"
  )

  fmt_pval <- function(p) ifelse(p < 0.001, "$<$0.001", sprintf("%.3f", p))

  for (i in seq_len(nrow(all_results))) {
    r <- all_results[i]
    if (i == 2) latex_tab2 <- c(latex_tab2, "\\midrule",
      "\\multicolumn{4}{l}{\\textit{By Crime Type}} \\\\")
    latex_tab2 <- c(latex_tab2,
      sprintf("%s & %s & %s & %s & %s \\\\",
        r$outcome_clean, r$coef_str, r$se_str,
        format(r$n_eff, big.mark = ","),
        fmt_pval(r$p_value)))
  }

  latex_tab2 <- c(latex_tab2,
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{adjustbox}",
    "\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} Local polynomial RDD estimates using fixed bandwidth of 2 km (Keele and Titiunik 2015). Triangular kernel. Standard errors clustered by boundary pair. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.}",
    "\\end{table}"
  )
  writeLines(latex_tab2, file.path(TAB_DIR, "tab2_main_rdd.tex"))
  cat("  Saved tab2_main_rdd.tex\n")
}

# ===================================================================
# Table 3: Robustness — bandwidth, donut, COVID
# ===================================================================
cat("\n=== Table 3: Robustness ===\n")

bw_file <- file.path(DATA_DIR, "bandwidth_sensitivity.csv")
donut_file <- file.path(DATA_DIR, "donut_rdd.csv")
covid_file <- file.path(DATA_DIR, "covid_robustness.csv")

robust_rows <- list()

if (file.exists(bw_file)) {
  bw <- fread(bw_file)
  for (i in seq_len(nrow(bw))) {
    r <- bw[i]
    robust_rows[[paste0("bw_", i)]] <- data.table(
      spec = sprintf("BW = %.1f km (%.1f$\\times$ baseline)", r$bandwidth_km, r$bw_multiplier),
      coef = r$coef, se = r$se, p_value = r$p_value, n_eff = r$n_eff
    )
  }
}

# Note: donut RDD excluded from main table because dropping observations
# within 2km of boundary while using 2km bandwidth is mechanically incompatible.
# The donut RDD with 2km hole uses MSE-optimal bandwidth (wider), making it
# not directly comparable to the fixed-bandwidth main specification.

if (file.exists(covid_file)) {
  covid <- fread(covid_file)
  for (i in seq_len(nrow(covid))) {
    r <- covid[i]
    robust_rows[[paste0("covid_", i)]] <- data.table(
      spec = "Exclude 2020--2021",
      coef = r$coef, se = r$se, p_value = r$p_value,
      n_eff = if ("n_eff" %in% names(r) && !is.na(r$n_eff)) r$n_eff else NA_integer_
    )
  }
}

if (length(robust_rows) > 0) {
  robust_dt <- rbindlist(robust_rows, fill = TRUE)
  robust_dt[, stars := fcase(
    p_value < 0.01, "***",
    p_value < 0.05, "**",
    p_value < 0.10, "*",
    default = ""
  )]

  latex_tab3 <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Robustness Checks}",
    "\\label{tab:robustness}",
    "\\begin{adjustbox}{max width=\\textwidth}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Specification & Coefficient & SE & $p$-value & $N_{\\text{eff}}$ \\\\",
    "\\midrule"
  )

  for (i in seq_len(nrow(robust_dt))) {
    r <- robust_dt[i]
    n_str <- ifelse(is.na(r$n_eff), "---",
                    format(as.integer(r$n_eff), big.mark = ","))
    p_str <- ifelse(r$p_value < 0.001, "$<$0.001", sprintf("%.3f", r$p_value))
    latex_tab3 <- c(latex_tab3,
      sprintf("%s & %.4f%s & (%.4f) & %s & %s \\\\",
        r$spec, r$coef, r$stars, r$se, p_str, n_str))
  }

  latex_tab3 <- c(latex_tab3,
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{adjustbox}",
    "\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} Bandwidth sensitivity uses multiples of the main specification bandwidth (2 km). All specifications use local polynomial RDD with triangular kernel. Standard errors clustered by boundary pair. Post-austerity period (2015--2023). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.}",
    "\\end{table}"
  )
  writeLines(latex_tab3, file.path(TAB_DIR, "tab3_robustness.tex"))
  cat("  Saved tab3_robustness.tex\n")
}

# ===================================================================
# Table 4: Balance tests
# ===================================================================
cat("\n=== Table 4: Balance tests ===\n")

bal_file <- file.path(DATA_DIR, "balance_tests.csv")
if (file.exists(bal_file)) {
  bal <- fread(bal_file)
  if (nrow(bal) > 0) {
    bal[, variable_clean := gsub("_", " ", variable)]
    bal[, variable_clean := tools::toTitleCase(variable_clean)]

    latex_tab4 <- c(
      "\\begin{table}[htbp]",
      "\\centering",
      "\\caption{Balance Tests at PFA Boundaries}",
      "\\label{tab:balance}",
      "\\begin{tabular}{lcccc}",
      "\\toprule",
      "Variable & Coefficient & SE & $p$-value & $N_{\\text{eff}}$ \\\\",
      "\\midrule"
    )

    for (i in seq_len(nrow(bal))) {
      r <- bal[i]
      n_str <- ifelse("n_eff" %in% names(bal) && !is.na(r$n_eff),
                       format(as.integer(r$n_eff), big.mark = ","), "---")
      p_str_bal <- ifelse(r$p_value < 0.001, "$<$0.001", sprintf("%.3f", r$p_value))
      latex_tab4 <- c(latex_tab4,
        sprintf("%s & %.4f & (%.4f) & %s & %s \\\\",
          r$variable_clean, r$coef, r$se, p_str_bal, n_str))
    }

    latex_tab4 <- c(latex_tab4,
      "\\bottomrule",
      "\\end{tabular}",
      "\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} RDD estimates of early-period (2011--2012) crime at the PFA boundary. Fixed bandwidth of 2 km, triangular kernel, standard errors clustered by boundary pair. A significant coefficient indicates a pre-existing discontinuity, suggesting geographic sorting rather than a causal effect of differential policing.}",
      "\\end{table}"
    )
    writeLines(latex_tab4, file.path(TAB_DIR, "tab4_balance.tex"))
    cat("  Saved tab4_balance.tex\n")
  }
}

cat("\n=== All tables generated ===\n")
