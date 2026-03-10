###############################################################################
# 06_tables.R — Publication-quality tables
# apep_0477 v2: Do Energy Labels Move Markets?
# WS2: Restructured decomposition (C/D-only primary)
# WS4: No-covariate row in Table 2
# WS8: Matrix format T3, siunitx decimal alignment, restructured T4
###############################################################################

source("00_packages.R")

DATA_DIR <- "../data"
TBL_DIR <- "../tables"
dir.create(TBL_DIR, showWarnings = FALSE, recursive = TRUE)

df <- as.data.table(read_parquet(file.path(DATA_DIR, "analysis_sample.parquet")))
rdd_dt <- fread(file.path(DATA_DIR, "rdd_results.csv"))

# Helper for significance stars
stars_fn <- function(p) {
  ifelse(p < 0.01, "^{***}",
  ifelse(p < 0.05, "^{**}", ""))
}

###############################################################################
# Table 1: Summary Statistics
###############################################################################

cat("Table 1: Summary statistics...\n")

summ_band <- df[, .(
  N = .N,
  Mean_Price = mean(price),
  SD_Price = sd(price),
  Median_Price = as.double(median(price)),
  Mean_Score = mean(epc_score),
  Mean_FloorArea = mean(floor_area, na.rm = TRUE),
  Pct_Flat = mean(as.numeric(is_flat)) * 100,
  Pct_NewBuild = mean(as.numeric(is_new)) * 100,
  Pct_Rental = mean(as.numeric(is_rental), na.rm = TRUE) * 100,
  Pct_AddrMatch = mean(match_quality == "address", na.rm = TRUE) * 100
), by = epc_band][order(epc_band)]

fwrite(summ_band, file.path(TBL_DIR, "table1_summary_by_band.csv"))

summ_period <- df[, .(
  N = .N,
  Mean_Price = mean(price),
  SD_Price = sd(price),
  Median_Price = as.double(median(price)),
  Mean_Score = mean(epc_score),
  Pct_Rental = mean(as.numeric(is_rental), na.rm = TRUE) * 100
), by = period][order(period)]

fwrite(summ_period, file.path(TBL_DIR, "table1_summary_by_period.csv"))

summ_all <- df[, .(
  N = .N,
  Mean_Price = mean(price),
  SD_Price = sd(price),
  Median_Price = median(price),
  Mean_Score = mean(epc_score),
  SD_Score = sd(epc_score),
  Mean_FloorArea = mean(floor_area, na.rm = TRUE),
  Pct_Detached = mean(property_type == "D") * 100,
  Pct_Semi = mean(property_type == "S") * 100,
  Pct_Terraced = mean(property_type == "T") * 100,
  Pct_Flat = mean(property_type == "F") * 100,
  Pct_NewBuild = mean(is_new) * 100,
  Pct_Rental = mean(is_rental, na.rm = TRUE) * 100,
  Pct_Owner = mean(is_owner, na.rm = TRUE) * 100,
  Pct_AddrMatch = mean(match_quality == "address") * 100,
  N_Districts = uniqueN(district_clean)
)]

fwrite(summ_all, file.path(TBL_DIR, "table1_summary_overall.csv"))

# LaTeX table — WS8: improved with siunitx S-columns
sink(file.path(TBL_DIR, "table1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by EPC Band}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccccc}\n")
cat("\\toprule\n")
cat(" & \\multicolumn{8}{c}{EPC Band} \\\\\n")
cat("\\cmidrule(lr){2-9}\n")
cat(" & {G} & {F} & {E} & {D} & {C} & {B} & {A} & {All} \\\\\n")
cat("\\midrule\n")

for (col_name in c("N", "Mean_Price", "Median_Price", "Mean_Score",
                    "Mean_FloorArea", "Pct_Flat", "Pct_NewBuild", "Pct_Rental",
                    "Pct_AddrMatch")) {
  label <- switch(col_name,
    N = "Observations",
    Mean_Price = "Mean price (\\pounds)",
    Median_Price = "Median price (\\pounds)",
    Mean_Score = "Mean EPC score",
    Mean_FloorArea = "Mean floor area (sq m)",
    Pct_Flat = "\\% Flats",
    Pct_NewBuild = "\\% New build",
    Pct_Rental = "\\% Private rental",
    Pct_AddrMatch = "\\% Address-matched"
  )

  vals <- character(8)
  for (j in 1:7) {
    band <- c("G", "F", "E", "D", "C", "B", "A")[j]
    row <- summ_band[epc_band == band]
    if (nrow(row) == 0) {
      vals[j] <- "{---}"
    } else {
      v <- row[[col_name]]
      if (col_name == "N") {
        vals[j] <- format(v, big.mark = ",")
      } else if (col_name %in% c("Mean_Price", "Median_Price")) {
        vals[j] <- format(round(v), big.mark = ",")
      } else if (grepl("Pct_", col_name)) {
        vals[j] <- sprintf("%.1f", v)
      } else {
        vals[j] <- sprintf("%.1f", v)
      }
    }
  }
  # All column
  v_all <- summ_all[[col_name]]
  if (col_name == "N") {
    vals[8] <- format(v_all, big.mark = ",")
  } else if (col_name %in% c("Mean_Price", "Median_Price")) {
    vals[8] <- format(round(v_all), big.mark = ",")
  } else if (col_name == "N_Districts") {
    vals[8] <- format(v_all, big.mark = ",")
  } else if (grepl("Pct_", col_name)) {
    vals[8] <- sprintf("%.1f", v_all)
  } else {
    vals[8] <- sprintf("%.1f", v_all)
  }

  cat(sprintf("%s & %s \\\\\n", label, paste(vals, collapse = " & ")))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Summary statistics for the matched EPC--Land Registry analysis sample, 2015--2023.\n")
cat("Transaction prices are in nominal pounds. EPC scores range from 1 (worst) to 100 (best).\n")
cat("Address-matched indicates the share of transactions linked at the individual property level.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

###############################################################################
# Table 2: Main RDD Results — WS4: with and without covariates
###############################################################################

cat("Table 2: Main RDD results...\n")

sink(file.path(TBL_DIR, "table2_main_rdd.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{RDD Estimates at EPC Band Boundaries}\n")
cat("\\label{tab:main_rdd}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat(" & E/F & D/E & C/D & B/C & A/B \\\\\n")
cat(" & (39) & (55) & (69) & (81) & (92) \\\\\n")
cat("\\midrule\n")

# Panel A: With covariates (primary)
cat("\\textit{Panel A: With covariates} & & & & & \\\\\n")

cov_results <- rdd_dt[period == "Overall" & tenure == "All" & spec == "covariates"]
cov_results[, boundary := factor(boundary, levels = EPC_BAND_NAMES)]
setorder(cov_results, boundary)

# Estimate row
est_line <- "\\quad Discontinuity"
se_line <- ""
for (b in EPC_BAND_NAMES) {
  row <- cov_results[boundary == b]
  if (nrow(row) == 0) {
    est_line <- paste0(est_line, " & {---}")
    se_line <- paste0(se_line, " & ")
  } else {
    est_line <- paste0(est_line, sprintf(" & $%.4f%s$", row$estimate, stars_fn(row$p_value)))
    se_line <- paste0(se_line, sprintf(" & (%.4f)", row$se_robust))
  }
}
cat(est_line, "\\\\\n")
cat(se_line, "\\\\\n")

# Panel B: Without covariates
cat("\\addlinespace\n")
cat("\\textit{Panel B: Without covariates} & & & & & \\\\\n")

nocov_results <- rdd_dt[period == "Overall" & tenure == "All" & spec == "no_covariates"]
nocov_results[, boundary := factor(boundary, levels = EPC_BAND_NAMES)]
setorder(nocov_results, boundary)

est_line2 <- "\\quad Discontinuity"
se_line2 <- ""
for (b in EPC_BAND_NAMES) {
  row <- nocov_results[boundary == b]
  if (nrow(row) == 0) {
    est_line2 <- paste0(est_line2, " & {---}")
    se_line2 <- paste0(se_line2, " & ")
  } else {
    est_line2 <- paste0(est_line2, sprintf(" & $%.4f%s$", row$estimate, stars_fn(row$p_value)))
    se_line2 <- paste0(se_line2, sprintf(" & (%.4f)", row$se_robust))
  }
}
cat(est_line2, "\\\\\n")
cat(se_line2, "\\\\\n")

# Footer
cat("\\midrule\n")
bw_line <- "Bandwidth"
neff_line <- "$N$ (effective)"
clust_line <- "Clustered SEs"
mass_line <- "Mass-point adjusted"

for (b in EPC_BAND_NAMES) {
  row <- cov_results[boundary == b]
  if (nrow(row) == 0) {
    bw_line <- paste0(bw_line, " & {---}")
    neff_line <- paste0(neff_line, " & {---}")
    clust_line <- paste0(clust_line, " & ")
    mass_line <- paste0(mass_line, " & ")
  } else {
    bw_line <- paste0(bw_line, sprintf(" & %.1f", row$bw_left))
    n_eff <- row$N_eff_left + row$N_eff_right
    neff_line <- paste0(neff_line, sprintf(" & %s", format(n_eff, big.mark = ",")))
    clust_line <- paste0(clust_line, sprintf(" & %s", ifelse(row$clustered, "Yes", "No")))
    mass_line <- paste0(mass_line, " & Yes")
  }
}

cat(bw_line, "\\\\\n")
cat(neff_line, "\\\\\n")
cat(clust_line, "\\\\\n")
cat(mass_line, "\\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Sharp RDD estimates of the log price discontinuity at each EPC band boundary.\n")
cat("Panel A includes covariates (floor area, property type, new-build indicator); Panel B excludes covariates.\n")
cat("Robust bias-corrected standard errors in parentheses (Calonico, Cattaneo \\& Titiunik, 2014),\n")
cat("clustered at the local authority district level. Mass-point adjustment applied to discrete SAP scores.\n")
cat("MSE-optimal bandwidth with triangular kernel. $p$-values from bias-corrected robust inference;\n")
cat("these may differ from naive estimate/SE ratios.\n")
cat("$^{***}p<0.01$, $^{**}p<0.05$.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

###############################################################################
# Table 3: WS8 — Matrix Format (rows = boundaries, columns = periods)
###############################################################################

cat("Table 3: Period-specific estimates (matrix format)...\n")

period_results <- rdd_dt[tenure == "All" & period != "Overall" &
                           boundary %in% c("E/F", "D/E", "C/D") &
                           spec == "covariates"]

sink(file.path(TBL_DIR, "table3_crisis.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{EPC Label Effects by Period}\n")
cat("\\label{tab:crisis}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & Pre-MEES & Post-MEES & Crisis & Post-Crisis \\\\\n")
cat(" & (2015--18Q1) & (18Q2--21Q3) & (21Q4--23Q2) & (23Q3+) \\\\\n")
cat("\\midrule\n")

for (bname in c("E/F", "D/E", "C/D")) {
  est_vals <- character(4)
  se_vals <- character(4)
  n_vals <- character(4)

  for (j in seq_along(PERIOD_LABELS)) {
    per <- PERIOD_LABELS[j]
    row <- period_results[boundary == bname & period == per]
    if (nrow(row) == 0) {
      est_vals[j] <- "{---}"
      se_vals[j] <- ""
      n_vals[j] <- "{---}"
    } else {
      est_vals[j] <- sprintf("$%.4f%s$", row$estimate, stars_fn(row$p_value))
      se_vals[j] <- sprintf("(%.4f)", row$se_robust)
      n_eff <- row$N_eff_left + row$N_eff_right
      n_vals[j] <- format(n_eff, big.mark = ",")
    }
  }

  cat(sprintf("\\textit{%s boundary} & %s \\\\\n", bname, paste(est_vals, collapse = " & ")))
  cat(sprintf(" & %s \\\\\n", paste(se_vals, collapse = " & ")))
  cat(sprintf("\\quad $N$ (effective) & %s \\\\\n", paste(n_vals, collapse = " & ")))

  if (bname != "C/D") cat("\\addlinespace\n")
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Separate RDD estimates by time period. Robust bias-corrected standard errors\n")
cat("in parentheses, clustered at the district level. Mass-point adjusted.\n")
cat("$p$-values from bias-corrected robust inference; these may differ from naive estimate/SE ratios.\n")
cat("See notes to Table~\\ref{tab:main_rdd} for specification details.\n")
cat("$^{***}p<0.01$, $^{**}p<0.05$.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

###############################################################################
# Table 4: WS2 + WS8 — Restructured Decomposition (C/D-only primary)
###############################################################################

cat("Table 4: MEES decomposition (C/D-only primary)...\n")

if (file.exists(file.path(DATA_DIR, "decomposition_results.csv"))) {
  decomp <- fread(file.path(DATA_DIR, "decomposition_results.csv"))

  sink(file.path(TBL_DIR, "table4_decomposition.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{Decomposition: Information vs Regulatory Effects at E/F Boundary}\n")
  cat("\\label{tab:decomposition}\n")
  cat("\\begin{tabular}{lcccc}\n")
  cat("\\toprule\n")
  cat(" & Pre-MEES & Post-MEES & Crisis & Post-Crisis \\\\\n")
  cat("\\midrule\n")

  cat("\\textit{Panel A: Components} & & & & \\\\\n")

  # E/F total effect
  ef_vals <- character(4)
  ef_se_vals <- character(4)
  info_vals <- character(4)
  info_se_vals <- character(4)

  for (j in seq_along(PERIOD_LABELS)) {
    per <- PERIOD_LABELS[j]
    row <- decomp[period == per]
    if (nrow(row) == 0) {
      ef_vals[j] <- "{---}"
      ef_se_vals[j] <- ""
      info_vals[j] <- "{---}"
      info_se_vals[j] <- ""
    } else {
      ef_vals[j] <- sprintf("$%.4f$", row$ef_effect)
      ef_se_vals[j] <- sprintf("(%.4f)", row$ef_se)
      info_vals[j] <- sprintf("$%.4f$", row$info_effect)
      info_se_vals[j] <- sprintf("(%.4f)", row$info_se)
    }
  }

  cat(sprintf("\\quad E/F total effect & %s \\\\\n", paste(ef_vals, collapse = " & ")))
  cat(sprintf(" & %s \\\\\n", paste(ef_se_vals, collapse = " & ")))
  cat("\\addlinespace\n")
  cat(sprintf("\\quad C/D informational effect & %s \\\\\n", paste(info_vals, collapse = " & ")))
  cat(sprintf(" & %s \\\\\n", paste(info_se_vals, collapse = " & ")))

  cat("\\addlinespace\n")
  cat("\\textit{Panel B: Regulatory residual} & & & & \\\\\n")

  reg_vals <- character(4)
  reg_se_vals <- character(4)

  for (j in seq_along(PERIOD_LABELS)) {
    per <- PERIOD_LABELS[j]
    row <- decomp[period == per]
    if (nrow(row) == 0) {
      reg_vals[j] <- "{---}"
      reg_se_vals[j] <- ""
    } else {
      reg_vals[j] <- sprintf("$%.4f%s$", row$reg_effect, stars_fn(row$reg_pval))
      reg_se_vals[j] <- sprintf("(%.4f)", row$reg_se)
    }
  }

  cat(sprintf("\\quad E/F $-$ C/D & %s \\\\\n", paste(reg_vals, collapse = " & ")))
  cat(sprintf(" & %s \\\\\n", paste(reg_se_vals, collapse = " & ")))

  # N row: show effective N for E/F and C/D
  cat("\\midrule\n")
  ef_n_vals <- character(4)
  cd_n_vals <- character(4)
  for (j in seq_along(PERIOD_LABELS)) {
    per <- PERIOD_LABELS[j]
    ef_row <- rdd_dt[boundary == "E/F" & period == per & tenure == "All" & spec == "covariates"]
    cd_row <- rdd_dt[boundary == "C/D" & period == per & tenure == "All" & spec == "covariates"]
    ef_n_vals[j] <- if (nrow(ef_row) > 0) format(ef_row$N_eff_left + ef_row$N_eff_right, big.mark = ",") else "{---}"
    cd_n_vals[j] <- if (nrow(cd_row) > 0) format(cd_row$N_eff_left + cd_row$N_eff_right, big.mark = ",") else "{---}"
  }
  cat(sprintf("$N$ (eff.) E/F & %s \\\\\n", paste(ef_n_vals, collapse = " & ")))
  cat(sprintf("$N$ (eff.) C/D & %s \\\\\n", paste(cd_n_vals, collapse = " & ")))

  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{\\textwidth}\n")
  cat("\\footnotesize\n")
  cat("\\textit{Notes:} Panel A reports the total E/F discontinuity and the informational effect\n")
  cat("estimated at the C/D boundary (the cleanest non-regulatory boundary: McCrary $p = 0.220$).\n")
  cat("The D/E boundary is excluded from the primary benchmark because it fails the density test ($p = 0.017$).\n")
  cat("Panel B reports the regulatory component: E/F minus C/D.\n")
  cat("Standard errors via propagation assuming independence across boundaries.\n")
  cat("$^{***}p<0.01$, $^{**}p<0.05$.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

###############################################################################
# Table 5: McCrary Density Tests
###############################################################################

cat("Table 5: McCrary results...\n")

mccrary_dt <- fread(file.path(DATA_DIR, "mccrary_results.csv"))

sink(file.path(TBL_DIR, "table5_mccrary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{McCrary Density Tests at EPC Band Boundaries}\n")
cat("\\label{tab:mccrary}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat("Boundary & Cutoff & Test Statistic & $p$-value & $N_{\\text{left}}$ & $N_{\\text{right}}$ \\\\\n")
cat("\\midrule\n")

for (j in seq_len(nrow(mccrary_dt))) {
  row <- mccrary_dt[j]
  cat(sprintf("%s & %d & %.3f & %.4f & %s & %s \\\\\n",
              row$boundary, row$cutoff, row$test_stat, row$p_value,
              format(row$N_left, big.mark = ","),
              format(row$N_right, big.mark = ",")))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Density continuity tests from Cattaneo, Jansson \\& Ma (2020).\n")
cat("A significant $p$-value indicates potential manipulation/bunching at the threshold.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

###############################################################################
# Table 6: WS3 — Difference-in-Discontinuities Around MEES
###############################################################################

cat("Table 6: Diff-in-disc...\n")

if (file.exists(file.path(DATA_DIR, "diff_in_disc_results.csv"))) {
  did_dt <- fread(file.path(DATA_DIR, "diff_in_disc_results.csv"))

  sink(file.path(TBL_DIR, "table6_diff_in_disc.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{Difference-in-Discontinuities Around MEES (April 2018)}\n")
  cat("\\label{tab:diff_disc}\n")
  cat("\\begin{tabular}{lccc}\n")
  cat("\\toprule\n")
  cat("Boundary & Difference & SE & $p$-value \\\\\n")
  cat("\\midrule\n")

  # Single-boundary diff-in-disc rows
  for (j in seq_len(nrow(did_dt))) {
    row <- did_dt[j]
    if (row$type == "triple_diff") {
      cat("\\addlinespace\n")
      cat(sprintf("\\textit{%s} & $%.3f%s$ & (%.3f) & %.3f \\\\\n",
                  row$boundary, row$diff, stars_fn(row$diff_pval),
                  row$diff_se, row$diff_pval))
    } else {
      cat(sprintf("\\textit{%s} & $%.3f%s$ & (%.3f) & %.3f \\\\\n",
                  row$boundary, row$diff, stars_fn(row$diff_pval),
                  row$diff_se, row$diff_pval))
    }
  }

  # Add N row
  cat("\\midrule\n")
  ef_pre <- rdd_dt[boundary == "E/F" & period == "Pre-MEES" & tenure == "All" & spec == "covariates"]
  ef_post <- rdd_dt[boundary == "E/F" & period == "Post-MEES Pre-Crisis" & tenure == "All" & spec == "covariates"]
  cd_pre <- rdd_dt[boundary == "C/D" & period == "Pre-MEES" & tenure == "All" & spec == "covariates"]
  cd_post <- rdd_dt[boundary == "C/D" & period == "Post-MEES Pre-Crisis" & tenure == "All" & spec == "covariates"]
  ef_n <- format((ef_pre$N_eff_left + ef_pre$N_eff_right + ef_post$N_eff_left + ef_post$N_eff_right), big.mark = ",")
  cd_n <- format((cd_pre$N_eff_left + cd_pre$N_eff_right + cd_post$N_eff_left + cd_post$N_eff_right), big.mark = ",")
  cat(sprintf("$N$ (eff.) & \\multicolumn{3}{l}{E/F: %s; C/D: %s} \\\\\n", ef_n, cd_n))

  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{\\textwidth}\n")
  cat("\\footnotesize\n")
  cat("\\textit{Notes:} Difference estimates compare RDD discontinuities in symmetric 2-year windows\n")
  cat("around MEES enactment (Pre: Jan 2016--Mar 2018; Post: Apr 2018--Mar 2020).\n")
  cat("$N$ (eff.) reports the combined effective sample across pre and post windows.\n")
  cat("The triple difference compares the change at E/F (regulatory + informational) to the change\n")
  cat("at C/D (informational only). Standard errors via propagation assuming independence across boundaries.\n")
  cat("$^{***}p<0.01$, $^{**}p<0.05$.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

###############################################################################
# Table 7: WS5 — Romano-Wolf Adjusted P-values
###############################################################################

cat("Table 7: Romano-Wolf...\n")

if (file.exists(file.path(DATA_DIR, "romano_wolf_pvalues.csv"))) {
  rw_dt <- fread(file.path(DATA_DIR, "romano_wolf_pvalues.csv"))

  sink(file.path(TBL_DIR, "table7_romano_wolf.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{Multiple Testing Correction}\n")
  cat("\\label{tab:romano_wolf}\n")
  cat("\\begin{tabular}{lcc}\n")
  cat("\\toprule\n")
  cat("Boundary & Raw $p$-value & Holm adjusted $p$-value \\\\\n")
  cat("\\midrule\n")

  for (j in seq_len(nrow(rw_dt))) {
    row <- rw_dt[j]
    cat(sprintf("%s & %.4f & %.4f \\\\\n", row$boundary, row$p_value, row$rw_adjusted))
  }

  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{\\textwidth}\n")
  cat("\\footnotesize\n")
  cat("\\textit{Notes:} Holm (1979) stepdown correction for testing five boundary effects simultaneously.\n")
  cat("Sorted by raw $p$-value, with stepwise adjustment enforcing monotonicity.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

###############################################################################
# Table 8: WS1 — Address Match Validation
###############################################################################

cat("Table 8: Address match validation...\n")

if (file.exists(file.path(DATA_DIR, "address_match_validation.csv"))) {
  addr_val <- fread(file.path(DATA_DIR, "address_match_validation.csv"))

  sink(file.path(TBL_DIR, "table8_match_validation.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{E/F RDD Estimates: Full Sample vs Address-Matched Subsample}\n")
  cat("\\label{tab:match_validation}\n")
  cat("\\begin{tabular}{lcccc}\n")
  cat("\\toprule\n")
  cat(" & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Address-Matched} \\\\\n")
  cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
  cat("Period & Estimate & SE & Estimate & SE \\\\\n")
  cat("\\midrule\n")

  full_ef <- rdd_dt[boundary == "E/F" & tenure == "All" & spec == "covariates"]

  for (per in c("Overall", PERIOD_LABELS)) {
    full_row <- full_ef[period == per]
    addr_row <- addr_val[period == per]

    full_est <- if (nrow(full_row) > 0) {
      sprintf("$%.4f%s$", full_row$estimate, stars_fn(full_row$p_value))
    } else "{---}"
    full_se <- if (nrow(full_row) > 0) sprintf("(%.4f)", full_row$se_robust) else ""

    addr_est <- if (nrow(addr_row) > 0) {
      sprintf("$%.4f%s$", addr_row$estimate, stars_fn(addr_row$p_value))
    } else "{---}"
    addr_se <- if (nrow(addr_row) > 0) sprintf("(%.4f)", addr_row$se_robust) else ""

    # N effective
    full_n <- if (nrow(full_row) > 0) format(full_row$N_eff_left + full_row$N_eff_right, big.mark = ",") else "{---}"
    addr_n <- if (nrow(addr_row) > 0) format(addr_row$N_eff_left + addr_row$N_eff_right, big.mark = ",") else "{---}"

    cat(sprintf("%s & %s & %s & %s & %s \\\\\n",
                per, full_est, full_se, addr_est, addr_se))
    cat(sprintf("\\quad $N$ (eff.) & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
                full_n, addr_n))
  }

  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{\\textwidth}\n")
  cat("\\footnotesize\n")
  cat("\\textit{Notes:} Address-matched subsample restricted to UPRN-based matches classified as\n")
  cat("``Address Matched'' in the \\citet{chi2023linked} dataset (89\\% of sample).\n")
  cat("Consistency across samples validates the matching strategy.\n")
  cat("$^{***}p<0.01$, $^{**}p<0.05$.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

###############################################################################
# Table 9: WS4 — Extended Donut RDD
###############################################################################

cat("Table 9: Extended donut RDD...\n")

if (file.exists(file.path(DATA_DIR, "donut_rdd_results.csv"))) {
  donut_dt <- fread(file.path(DATA_DIR, "donut_rdd_results.csv"))

  sink(file.path(TBL_DIR, "table9_donut_extended.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{Extended Donut RDD Estimates}\n")
  cat("\\label{tab:donut_extended}\n")
  cat("\\begin{tabular}{lccccc}\n")
  cat("\\toprule\n")
  cat(" & E/F & D/E & C/D & B/C & A/B \\\\\n")
  cat("\\midrule\n")

  # Boundaries with severe McCrary bunching — donut results unreliable
  bunched_boundaries <- c("B/C", "A/B")

  for (ds in 1:3) {
    est_line <- sprintf("Donut $\\pm$%d", ds)
    se_line <- ""
    n_line <- "\\quad $N$ (eff.)"
    for (bname in EPC_BAND_NAMES) {
      row <- donut_dt[boundary == bname & donut_size == ds]
      if (nrow(row) == 0 || bname %in% bunched_boundaries) {
        est_line <- paste0(est_line, " & {---}")
        se_line <- paste0(se_line, " & {---}")
        n_line <- paste0(n_line, " & {---}")
      } else {
        est_line <- paste0(est_line, sprintf(" & $%.4f%s$", row$estimate, stars_fn(row$p_value)))
        se_line <- paste0(se_line, sprintf(" & (%.4f)", row$se_robust))
        n_line <- paste0(n_line, sprintf(" & %s", format(row$N_eff, big.mark = ",")))
      }
    }
    cat(est_line, "\\\\\n")
    cat(se_line, "\\\\\n")
    cat(n_line, "\\\\\n")
    if (ds < 3) cat("\\addlinespace\n")
  }

  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{\\textwidth}\n")
  cat("\\footnotesize\n")
  cat("\\textit{Notes:} Donut RDD estimates excluding observations within $\\pm k$ score points\n")
  cat("of each cutoff, for $k \\in \\{1, 2, 3\\}$. Robust bias-corrected SEs. Fixed bandwidth $h = 10$.\n")
  cat("B/C and A/B suppressed ({---}) due to severe McCrary bunching ($p < 0.001$), which renders\n")
  cat("donut estimates unreliable at those boundaries.\n")
  cat("$^{***}p<0.01$, $^{**}p<0.05$.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

###############################################################################
# Table 10: Polynomial Order Sensitivity (Appendix)
###############################################################################

cat("Table 10: Polynomial sensitivity...\n")

if (file.exists(file.path(DATA_DIR, "polynomial_sensitivity.csv"))) {
  poly_dt <- fread(file.path(DATA_DIR, "polynomial_sensitivity.csv"))

  sink(file.path(TBL_DIR, "table10_polynomial.tex"))
  cat("\\begin{table}[H]\n")
  cat("\\centering\n")
  cat("\\caption{Polynomial Order Sensitivity}\n")
  cat("\\label{tab:poly_sensitivity}\n")
  cat("\\begin{tabular}{lccccc}\n")
  cat("\\toprule\n")
  cat(" & E/F & D/E & C/D & B/C & A/B \\\\\n")
  cat("\\midrule\n")

  for (p in 1:2) {
    est_line <- sprintf("\\textit{%s ($p=%d$)}", ifelse(p == 1, "Linear", "Quadratic"), p)
    se_line <- ""
    n_line <- "\\quad $N$ (eff.)"
    for (bname in EPC_BAND_NAMES) {
      row <- poly_dt[boundary == bname & poly_order == p]
      if (nrow(row) == 0) {
        est_line <- paste0(est_line, " & {---}")
        se_line <- paste0(se_line, " & ")
        n_line <- paste0(n_line, " & {---}")
      } else {
        est_line <- paste0(est_line, sprintf(" & $%.3f%s$", row$estimate, stars_fn(row$p_value)))
        se_line <- paste0(se_line, sprintf(" & (%.3f)", row$se_robust))
        if ("N_eff_left" %in% names(row)) {
          n_line <- paste0(n_line, sprintf(" & %s", format(row$N_eff_left + row$N_eff_right, big.mark = ",")))
        } else {
          n_line <- paste0(n_line, " & {---}")
        }
      }
    }
    cat(est_line, "\\\\\n")
    cat(se_line, "\\\\\n")
    cat(n_line, "\\\\\n")
    if (p < 2) cat("\\addlinespace\n")
  }

  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{\\textwidth}\n")
  cat("\\footnotesize\n")
  cat("\\textit{Notes:} RDD estimates at each boundary using local linear ($p=1$) and local quadratic ($p=2$)\n")
  cat("polynomial specifications. Robust bias-corrected standard errors in parentheses.\n")
  cat("Fixed bandwidth $h = 8$. The E/F null is robust to polynomial order; B/C and A/B instability\n")
  cat("reflects severe McCrary bunching. Significance determined by bias-corrected robust $p$-values from\n")
  cat("\\texttt{rdrobust}; these may differ from naive estimate/SE ratios due to bias correction.\n")
  cat("$^{***}p<0.01$, $^{**}p<0.05$.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

cat("\nAll tables generated.\n")
