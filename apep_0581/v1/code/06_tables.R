# 06_tables.R — Generate all LaTeX tables from saved CSV data
# APEP-0581: Technology Standards and Facility-Level Pollution

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

cat("Table 1: Summary statistics...\n")

sumstats_file <- file.path(data_dir, "summary_statistics.csv")
if (file.exists(sumstats_file)) {
  sumstats <- fread(sumstats_file)

  # Format for LaTeX
  sumstats[, Variable_clean := str_replace_all(Variable, "_", " ")]
  sumstats[, Variable_clean := str_to_title(Variable_clean)]

  latex_table <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Summary Statistics}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lrrrrrr}\n",
    "\\toprule\n",
    "Variable & N & Mean & SD & P25 & Median & P75 \\\\\n",
    "\\midrule\n"
  )

  for (i in seq_len(nrow(sumstats))) {
    row <- sumstats[i]
    latex_table <- paste0(latex_table,
      sprintf("%s & %s & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
              row$Variable_clean,
              format(row$N, big.mark = ","),
              row$Mean, row$SD, row$P25, row$Median, row$P75))
  }

  latex_table <- paste0(latex_table,
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item Notes: Sample includes BAT-regulated NACE sectors across EU/EEA countries. ",
    "Unit of observation: sector--country--year. ",
    "Emissions in tonnes from Eurostat air emissions accounts (env\\_ac\\_ainah\\_r2). ",
    "Log emissions use log(tonnes + 1). Panel spans 2000--2024.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:summary}\n",
    "\\end{table}\n"
  )

  writeLines(latex_table, file.path(table_dir, "tab1_summary.tex"))
  cat("  Saved tab1_summary.tex\n")
}

# ============================================================================
# TABLE 2: BAT Conclusion Timeline
# ============================================================================

cat("Table 2: BAT conclusion timeline...\n")

bat_info <- fread(file.path(data_dir, "bat_conclusions.csv"))
timing_file <- file.path(data_dir, "treatment_timing.csv")

if (file.exists(timing_file)) {
  timing <- fread(timing_file)
  bat_merged <- merge(bat_info, timing[, .(bat_sector, n_countries, n_obs)],
                       by = "bat_sector", all.x = TRUE)
} else {
  bat_merged <- bat_info
  bat_merged[, n_countries := NA_integer_]
  bat_merged[, n_obs := NA_integer_]
}

latex_bat <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{BAT Conclusion Adoption Timeline}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "BAT Sector & Adopted & Compliance & Countries & Observations \\\\\n",
  "\\midrule\n"
)

bat_merged <- bat_merged[order(bat_year)]
for (i in seq_len(nrow(bat_merged))) {
  row <- bat_merged[i]
  latex_bat <- paste0(latex_bat,
    sprintf("%s & %s & %s & %s & %s \\\\\n",
            str_trunc(row$bat_sector, 40),
            row$bat_adopted,
            row$compliance_deadline,
            ifelse(is.na(row$n_countries), "---",
                   format(row$n_countries, big.mark = ",")),
            ifelse(is.na(row$n_obs), "---",
                   format(row$n_obs, big.mark = ","))))
}

latex_bat <- paste0(latex_bat,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item Notes: BAT conclusions adopted under the EU Industrial Emissions Directive ",
  "(2010/75/EU) via Commission Implementing Decisions. Compliance deadline is 4 years ",
  "after adoption. Countries: EU/EEA countries with sector data in Eurostat. ",
  "Observations: sector--country--year cells.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:bat_timeline}\n",
  "\\end{table}\n"
)

writeLines(latex_bat, file.path(table_dir, "tab2_bat_timeline.tex"))
cat("  Saved tab2_bat_timeline.tex\n")

# ============================================================================
# TABLE 3: Main Results
# ============================================================================

cat("Table 3: Main results...\n")

twfe_file <- file.path(data_dir, "twfe_results.csv")
sa_file <- file.path(data_dir, "sun_abraham_att.csv")
cs_file <- file.path(data_dir, "cs_att.csv")
adoption_file <- file.path(data_dir, "robustness_adoption_timing.csv")

results_rows <- list()

if (file.exists(twfe_file)) {
  twfe <- fread(twfe_file)
  results_rows[["TWFE"]] <- twfe[1]
}
if (file.exists(sa_file)) {
  sa <- fread(sa_file)
  results_rows[["SA"]] <- data.table(
    model = "Sun-Abraham",
    coefficient = sa$att[1],
    se = sa$att_se[1],
    pvalue = 2 * pnorm(-abs(sa$att[1] / sa$att_se[1]))
  )
}
if (file.exists(cs_file)) {
  cs <- fread(cs_file)
  results_rows[["CS"]] <- data.table(
    model = "CS-DiD",
    coefficient = cs$att[1],
    se = cs$se[1],
    pvalue = 2 * pnorm(-abs(cs$att[1] / cs$se[1]))
  )
}
if (file.exists(adoption_file)) {
  adopt <- fread(adoption_file)
  results_rows[["Adopt"]] <- adopt[1]
}

if (length(results_rows) > 0) {
  # Format stars
  star_fn <- function(p) {
    ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  }

  latex_main <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Effect of BAT Conclusions on Facility Emissions}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lcccc}\n",
    "\\toprule\n",
    " & (1) & (2) & (3) & (4) \\\\\n",
    " & TWFE & Sun-Abraham & CS-DiD & BAT Adoption \\\\\n",
    "\\midrule\n"
  )

  # Coefficient row
  coef_row <- "Post-BAT"
  se_row <- ""
  for (name in c("TWFE", "SA", "CS", "Adopt")) {
    if (name %in% names(results_rows)) {
      r <- results_rows[[name]]
      stars <- star_fn(r$pvalue[1])
      coef_row <- paste0(coef_row, sprintf(" & %.4f%s", r$coefficient[1], stars))
      se_row <- paste0(se_row, sprintf(" & (%.4f)", r$se[1]))
    } else {
      coef_row <- paste0(coef_row, " & ---")
      se_row <- paste0(se_row, " & ")
    }
  }
  coef_row <- paste0(coef_row, " \\\\\n")
  se_row <- paste0(se_row, " \\\\\n")

  latex_main <- paste0(latex_main, coef_row, se_row,
    "\\midrule\n",
    "Facility FE & Yes & Yes & --- & Yes \\\\\n",
    "Year FE & Yes & Yes & --- & Yes \\\\\n",
    "Estimator & TWFE & IW & CS & TWFE \\\\\n",
    "Treatment & Compliance & Compliance & Compliance & Adoption \\\\\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
    "Standard errors clustered at sector level in parentheses. ",
    "Column (1): Two-way fixed effects. ",
    "Column (2): Sun and Abraham (2021) interaction-weighted estimator. ",
    "Column (3): Callaway and Sant'Anna (2021). ",
    "Column (4): Treatment defined as BAT adoption date (rather than 4-year compliance deadline). ",
    "Outcome: log sector-level air emissions (tonnes). ",
    "Sample: BAT-regulated NACE sectors in 30 EU/EEA countries, 2000--2024.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:main}\n",
    "\\end{table}\n"
  )

  writeLines(latex_main, file.path(table_dir, "tab3_main_results.tex"))
  cat("  Saved tab3_main_results.tex\n")
}

# ============================================================================
# TABLE 4: Robustness Checks
# ============================================================================

cat("Table 4: Robustness...\n")

rob_files <- c(
  "LOSO" = file.path(data_dir, "robustness_loso.csv"),
  "CO2 Placebo" = file.path(data_dir, "robustness_co2_placebo.csv"),
  "Placebo Timing" = file.path(data_dir, "robustness_placebo_timing.csv"),
  "Wild Bootstrap" = file.path(data_dir, "robustness_wild_bootstrap.csv"),
  "RI" = file.path(data_dir, "robustness_ri.csv"),
  "Alt Clustering" = file.path(data_dir, "robustness_alt_clustering.csv")
)

rob_summary <- list()
for (name in names(rob_files)) {
  f <- rob_files[[name]]
  if (file.exists(f)) {
    d <- fread(f)
    if (name == "LOSO") {
      rob_summary[[name]] <- data.table(
        check = "Leave-one-sector-out (range)",
        coef_range = paste0("[", round(min(d$coefficient), 4), ", ",
                            round(max(d$coefficient), 4), "]"),
        pvalue_range = paste0("[", round(min(d$pvalue), 3), ", ",
                              round(max(d$pvalue), 3), "]")
      )
    } else if (name == "Wild Bootstrap") {
      rob_summary[[name]] <- data.table(
        check = "Wild cluster bootstrap",
        coef_range = "---",
        pvalue_range = round(d$p_value[1], 3)
      )
    } else if (name == "RI") {
      rob_summary[[name]] <- data.table(
        check = "Randomization inference",
        coef_range = round(d$observed_coef[1], 4),
        pvalue_range = round(d$ri_pvalue[1], 3)
      )
    }
  }
}

if (length(rob_summary) > 0) {
  rob_dt <- rbindlist(rob_summary)
  fwrite(rob_dt, file.path(data_dir, "robustness_summary_table.csv"))
  cat("  Robustness summary saved.\n")
}

# ============================================================================
# TABLE 5: Multiple Outcomes
# ============================================================================

cat("Table 5: Multiple outcomes...\n")

multi_file <- file.path(data_dir, "multi_outcome_results.csv")
if (file.exists(multi_file)) {
  multi <- fread(multi_file)

  latex_multi <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Effect of BAT Conclusions Across Pollutants}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lccc}\n",
    "\\toprule\n",
    "Pollutant & Coefficient & SE & N \\\\\n",
    "\\midrule\n"
  )

  star_fn <- function(p) {
    ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  }

  for (i in seq_len(nrow(multi))) {
    row <- multi[i]
    label <- toupper(str_replace_all(row$outcome, "log_|_kg", ""))
    label <- str_replace(label, "TOTAL_EMISSIONS", "Total Emissions")
    stars <- star_fn(row$pvalue)
    latex_multi <- paste0(latex_multi,
      sprintf("%s & %.4f%s & (%.4f) & %s \\\\\n",
              label, row$coefficient, stars, row$se,
              format(row$n_obs, big.mark = ",")))
  }

  latex_multi <- paste0(latex_multi,
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
    "TWFE estimates with sector--country and year fixed effects. ",
    "Standard errors clustered at BAT sector level. ",
    "Outcome: log(sector emissions in tonnes + 1).\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:multi_outcomes}\n",
    "\\end{table}\n"
  )

  writeLines(latex_multi, file.path(table_dir, "tab5_multi_outcomes.tex"))
  cat("  Saved tab5_multi_outcomes.tex\n")
}

cat("\n=== ALL TABLES GENERATED ===\n")
