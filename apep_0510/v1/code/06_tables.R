# =============================================================================
# 06_tables.R — Pills and Diplomas (apep_0510)
# =============================================================================
# All tables read from saved data files. Generates LaTeX output.
# =============================================================================

source("code/00_packages.R")

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))

# =============================================================================
# TABLE 1: SUMMARY STATISTICS
# =============================================================================
cat("=== Table 1: Summary statistics ===\n")

# Panel summary
panel_4yr <- panel[inst_type == "4-year"]

summ_vars <- panel_4yr[, .(
  ret_pcf_mean = mean(ret_pcf, na.rm = TRUE),
  ret_pcf_sd = sd(ret_pcf, na.rm = TRUE),
  enrollment_mean = mean(total_enrollment, na.rm = TRUE),
  enrollment_sd = sd(total_enrollment, na.rm = TRUE),
  completions_mean = mean(total_completions, na.rm = TRUE),
  completions_sd = sd(total_completions, na.rm = TRUE),
  unemp_rate_mean = mean(unemp_rate, na.rm = TRUE),
  unemp_rate_sd = sd(unemp_rate, na.rm = TRUE)
)]

# By treatment status
summ_by_treat <- panel_4yr[, .(
  N = .N,
  n_inst = length(unique(unitid)),
  ret_pcf = mean(ret_pcf, na.rm = TRUE),
  enrollment = mean(total_enrollment, na.rm = TRUE),
  completions = mean(total_completions, na.rm = TRUE),
  unemp_rate = mean(unemp_rate, na.rm = TRUE),
  pct_public = mean(control == 1, na.rm = TRUE) * 100,
  pct_hbcu = mean(hbcu == 1, na.rm = TRUE) * 100
), by = .(pdmp_treated)]

fwrite(summ_by_treat, file.path(DATA_DIR, "summary_by_treatment.csv"))

# LaTeX output
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by PDMP Mandate Status}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lrr}",
  "\\toprule",
  " & Pre-Mandate & Post-Mandate \\\\",
  "\\midrule",
  sprintf("Observations & %s & %s \\\\",
          format(summ_by_treat[pdmp_treated == 0]$N, big.mark = ","),
          format(summ_by_treat[pdmp_treated == 1]$N, big.mark = ",")),
  sprintf("Institutions & %s & %s \\\\",
          format(summ_by_treat[pdmp_treated == 0]$n_inst, big.mark = ","),
          format(summ_by_treat[pdmp_treated == 1]$n_inst, big.mark = ",")),
  sprintf("Retention rate (\\%%) & %.1f & %.1f \\\\",
          summ_by_treat[pdmp_treated == 0]$ret_pcf,
          summ_by_treat[pdmp_treated == 1]$ret_pcf),
  sprintf("Total enrollment & %s & %s \\\\",
          format(round(summ_by_treat[pdmp_treated == 0]$enrollment), big.mark = ","),
          format(round(summ_by_treat[pdmp_treated == 1]$enrollment), big.mark = ",")),
  sprintf("Total completions & %s & %s \\\\",
          format(round(summ_by_treat[pdmp_treated == 0]$completions), big.mark = ","),
          format(round(summ_by_treat[pdmp_treated == 1]$completions), big.mark = ",")),
  sprintf("State unemployment rate (\\%%) & %.1f & %.1f \\\\",
          summ_by_treat[pdmp_treated == 0]$unemp_rate,
          summ_by_treat[pdmp_treated == 1]$unemp_rate),
  sprintf("Public institutions (\\%%) & %.1f & %.1f \\\\",
          summ_by_treat[pdmp_treated == 0]$pct_public,
          summ_by_treat[pdmp_treated == 1]$pct_public),
  sprintf("HBCU (\\%%) & %.1f & %.1f \\\\",
          summ_by_treat[pdmp_treated == 0]$pct_hbcu,
          summ_by_treat[pdmp_treated == 1]$pct_hbcu),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Sample includes 4-year degree-granting institutions in the 50 US states and DC, 2003--2023. Pre-Mandate includes never-treated institution-years and pre-treatment institution-years. Post-Mandate includes institution-years after the state enacted a mandatory PDMP consultation law. Source: IPEDS.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(TABLE_DIR, "tab1_summary.tex"))
cat("  Table 1 saved.\n")

# =============================================================================
# TABLE 2: MAIN RESULTS
# =============================================================================
cat("=== Table 2: Main results ===\n")

main_results <- fread(file.path(DATA_DIR, "main_results_summary.csv"))

# Extract rows by outcome and estimator
get_row <- function(outcome_pat) main_results[grepl(outcome_pat, outcome)]

ret_cs <- get_row("Retention.*CS-DiD")
ret_tw <- get_row("Retention.*TWFE")
enr_cs <- get_row("enrollment.*CS-DiD")
enr_tw <- get_row("enrollment.*TWFE")
comp_cs <- get_row("completions.*CS-DiD")
comp_tw <- get_row("completions.*TWFE")

star_fn <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

fmt_row <- function(label, cs, tw) {
  cs_stars <- star_fn(cs$pvalue)
  tw_stars <- star_fn(tw$pvalue)
  c(
    sprintf("%s & %.3f%s & %.3f%s \\\\", label,
            cs$estimate, cs_stars, tw$estimate, tw_stars),
    sprintf(" & (%.3f) & (%.3f) \\\\", cs$se, tw$se)
  )
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of PDMP Mandates on Higher Education Outcomes}",
  "\\label{tab:main_results}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & CS-DiD & TWFE \\\\",
  "\\midrule",
  "\\textit{Panel A: Retention Rate (pp)} & & \\\\",
  fmt_row("PDMP mandate", ret_cs, ret_tw),
  sprintf("$N$ & %s & %s \\\\",
          format(ret_cs$n, big.mark = ","), format(ret_tw$n, big.mark = ",")),
  "\\addlinespace",
  "\\textit{Panel B: Log Enrollment} & & \\\\",
  fmt_row("PDMP mandate", enr_cs, enr_tw),
  sprintf("$N$ & %s & %s \\\\",
          format(enr_cs$n, big.mark = ","), format(enr_tw$n, big.mark = ",")),
  "\\addlinespace",
  "\\textit{Panel C: Log Completions} & & \\\\",
  fmt_row("PDMP mandate", comp_cs, comp_tw),
  sprintf("$N$ & %s & %s \\\\",
          format(comp_cs$n, big.mark = ","), format(comp_tw$n, big.mark = ",")),
  "\\midrule",
  "Institution FE & \\checkmark & \\checkmark \\\\",
  "Year FE & \\checkmark & \\checkmark \\\\",
  "Concurrent policies & & \\checkmark \\\\",
  "State unemployment & & \\checkmark \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} CS-DiD estimates use the Callaway and Sant'Anna (2021) doubly-robust estimator with never-treated institutions as the control group. TWFE estimates include controls for naloxone access laws, Good Samaritan laws, Medicaid expansion, recreational cannabis legalization, and state unemployment rate. Standard errors (in parentheses) clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2_lines, file.path(TABLE_DIR, "tab2_main_results.tex"))
cat("  Table 2 saved.\n")

# =============================================================================
# TABLE 3: DRUG-TYPE DECOMPOSITION
# =============================================================================
cat("=== Table 3: Drug decomposition ===\n")

decomp <- fread(file.path(DATA_DIR, "drug_decomposition.csv"))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{The Substitution Test: PDMP Effects by Drug Type}",
  "\\label{tab:substitution}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Drug Category & Estimate & SE & 95\\% CI & N \\\\",
  "\\midrule"
)

drug_labels <- c(
  prescription = "Prescription opioids (T40.2)",
  fentanyl = "Synthetic opioids/fentanyl (T40.4)",
  heroin = "Heroin (T40.1)",
  total_od = "Total drug overdose deaths"
)

for (i in 1:nrow(decomp)) {
  r <- decomp[i]
  stars <- ifelse(abs(r$coef / r$se) > 2.576, "***",
                  ifelse(abs(r$coef / r$se) > 1.96, "**",
                         ifelse(abs(r$coef / r$se) > 1.645, "*", "")))
  lab <- drug_labels[r$drug_type]
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %.3f%s & (%.3f) & [%.3f, %.3f] & %s \\\\",
    lab, r$coef, stars, r$se, r$ci_lower, r$ci_upper,
    format(r$n, big.mark = ",")
  ))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "State FE & \\multicolumn{4}{c}{\\checkmark} \\\\",
  "Year FE & \\multicolumn{4}{c}{\\checkmark} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log(deaths + 1) for each drug category. State-year panel from VSRR provisional overdose death counts, 2015--2023. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(TABLE_DIR, "tab3_substitution.tex"))
cat("  Table 3 saved.\n")

# =============================================================================
# TABLE 4: TREATMENT COHORT DISTRIBUTION
# =============================================================================
cat("=== Table 4: Treatment cohorts ===\n")

pdmp <- fread(file.path(DATA_DIR, "pdmp_mandate_dates.csv"))

cohort_dist <- panel[inst_type == "4-year" & g > 0 & !is.na(ret_pcf),
                     .(n_institutions = length(unique(unitid))),
                     by = .(cohort_year = g)]
cohort_dist <- merge(cohort_dist, pdmp[, .N, by = .(cohort_year = pdmp_mandate_year)],
                     by = "cohort_year", all = TRUE)
setnames(cohort_dist, "N", "n_states")
setorder(cohort_dist, cohort_year)

fwrite(cohort_dist, file.path(DATA_DIR, "treatment_cohorts.csv"))

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{PDMP Mandate Adoption Cohorts}",
  "\\label{tab:cohorts}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{ccc}",
  "\\toprule",
  "Adoption Year & Jurisdictions & 4-Year Institutions (Treated) \\\\",
  "\\midrule"
)

for (i in 1:nrow(cohort_dist)) {
  r <- cohort_dist[i]
  tab4_lines <- c(tab4_lines, sprintf(
    "%d & %d & %s \\\\",
    r$cohort_year, r$n_states,
    format(r$n_institutions, big.mark = ",")
  ))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  sprintf("Total & %d & %s \\\\",
          sum(cohort_dist$n_states, na.rm = TRUE),
          format(sum(cohort_dist$n_institutions, na.rm = TRUE), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Adoption year is the year the state or jurisdiction enacted a mandatory PDMP consultation law. ``States'' includes the District of Columbia. Institution counts reflect 4-year degree-granting institutions with non-missing retention data in the estimation sample. Source: Gunadi (2023), Buchmueller and Carey (2018).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4_lines, file.path(TABLE_DIR, "tab4_cohorts.tex"))
cat("  Table 4 saved.\n")

cat("\nAll tables complete.\n")
