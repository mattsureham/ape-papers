## ============================================================================
## 06_tables.R — All tables for the paper
## ============================================================================

source("00_packages.R")

DATA <- "../data"
TABLES <- "../tables"
dir.create(TABLES, showWarnings = FALSE)

main_sample <- readRDS(file.path(DATA, "main_sample.rds"))
waiver_dates <- fread(file.path(DATA, "waiver_dates.csv"))

## ---- Table 1: Summary Statistics ----
cat("=== Table 1: Summary Statistics ===\n")

# Pre-treatment period (Jan 2018 - June 2018, before any post-2018 waiver)
pre_period <- main_sample[month_date <= "2018-06-30"]

sumstats <- pre_period[, .(
  mean_val = sapply(.SD, mean, na.rm = TRUE),
  sd_val = sapply(.SD, sd, na.rm = TRUE),
  min_val = sapply(.SD, min, na.rm = TRUE),
  max_val = sapply(.SD, max, na.rm = TRUE)
), .SDcols = c("bh_providers", "sud_providers", "mat_providers",
               "bh_claims", "sud_claims",
               "bh_beneficiaries", "sud_beneficiaries",
               "pc_providers", "total_providers",
               "bh_paid", "sud_paid")]

sumstats[, variable := c("BH Providers", "SUD Providers", "MAT Providers",
                          "BH Claims", "SUD Claims",
                          "BH Beneficiaries", "SUD Beneficiaries",
                          "Personal Care Providers", "Total Providers",
                          "BH Paid ($)", "SUD Paid ($)")]

fwrite(sumstats[, .(variable, mean_val, sd_val, min_val, max_val)],
       file.path(TABLES, "tab1_summary_stats.csv"))

# LaTeX version
tab1_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Pre-Treatment Period (January--June 2018)}
\\label{tab:sumstats}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lrrrr}
\\toprule
Variable & Mean & SD & Min & Max \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} State-month observations from the main analysis sample (excluding always-treated states). Pre-treatment defined as January--June 2018, before any post-2018 SUD waiver approval. Provider counts are monthly active billing NPIs. BH = Behavioral Health (all H-codes). SUD = substance use disorder--specific H-codes. MAT = medication-assisted treatment J-codes.
\\end{tablenotes}
\\end{table}",
  paste(sprintf("%s & %s & %s & %s & %s \\\\",
                sumstats$variable,
                format(round(sumstats$mean_val, 1), big.mark = ","),
                format(round(sumstats$sd_val, 1), big.mark = ","),
                format(round(sumstats$min_val, 0), big.mark = ","),
                format(round(sumstats$max_val, 0), big.mark = ",")),
        collapse = "\n"))

writeLines(tab1_tex, file.path(TABLES, "tab1_summary_stats.tex"))

## ---- Table 2: Waiver Adoption Timeline ----
cat("=== Table 2: Waiver Adoption Timeline ===\n")

waiver_timeline <- waiver_dates[, .(
  n_states = .N,
  states = paste(state, collapse = ", ")
), by = cohort_label]
setorder(waiver_timeline, cohort_label)

fwrite(waiver_timeline, file.path(TABLES, "tab2_waiver_timeline.csv"))

tab2_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Section 1115 SUD Waiver Adoption Timeline}
\\label{tab:waiver_timeline}
\\begin{tabular}{lrl}
\\toprule
Cohort & States & \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Section 1115 SUD demonstration waivers approved by CMS. Early adopters (pre-July 2018) are excluded from the main CS-DiD analysis due to insufficient pre-treatment data in T-MSIS. Never-treated states serve as the control group. Waiver approval dates from CMS State Waivers List and KFF Medicaid Waiver Tracker.
\\end{tablenotes}
\\end{table}",
  paste(sprintf("%s & %d & %s \\\\",
                waiver_timeline$cohort_label,
                waiver_timeline$n_states,
                waiver_timeline$states),
        collapse = "\n"))

writeLines(tab2_tex, file.path(TABLES, "tab2_waiver_timeline.tex"))

## ---- Table 3: Main Results ----
cat("=== Table 3: Main Results ===\n")

results <- fread(file.path(DATA, "results_summary.csv"))

tab3_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Main Results: Effect of 1115 SUD Waivers on Provider Supply}
\\label{tab:main_results}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lccccc}
\\toprule
Outcome & ATT & SE & $t$-stat & $p$-value & \\%% Change \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Callaway--Sant'Anna (2021) group-time ATTs aggregated via simple weighting. Doubly-robust estimation with never-treated states as controls. Standard errors clustered at the state level. Outcomes in logs; \\%% Change = $(e^{\\hat{\\beta}} - 1) \\times 100$. Personal Care Providers is a placebo outcome (HCBS T-codes unrelated to SUD treatment).
\\end{tablenotes}
\\end{table}",
  paste(sprintf("%s & %.4f & %.4f & %.2f & %.3f & %.1f\\%%%% \\\\",
                results$outcome,
                results$att,
                results$se,
                results$t_stat,
                results$p_value,
                results$pct_change),
        collapse = "\n"))

writeLines(tab3_tex, file.path(TABLES, "tab3_main_results.tex"))

## ---- Table 4: Robustness ----
cat("=== Table 4: Robustness ===\n")

robust <- fread(file.path(DATA, "robustness_summary.csv"))

tab4_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks: BH Provider Supply}
\\label{tab:robustness}
\\begin{tabular}{lcc}
\\toprule
Specification & Estimate & SE \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All specifications use log active behavioral health providers as the outcome. CS-DiD = Callaway--Sant'Anna (2021). TWFE = two-way fixed effects (state + month). Stacked DiD follows Sun \\& Abraham (2021). COVID exclusion drops March--December 2020. State trends add state-specific linear time trends. RI and WCB report $p$-values.
\\end{tablenotes}
\\end{table}",
  paste(sprintf("%s & %s & %s \\\\",
                robust$specification,
                fifelse(!is.na(robust$estimate), sprintf("%.4f", robust$estimate), "---"),
                fifelse(!is.na(robust$se), sprintf("%.4f", robust$se), "---")),
        collapse = "\n"))

writeLines(tab4_tex, file.path(TABLES, "tab4_robustness.tex"))

## ---- Table 5: Mechanism Decomposition ----
cat("=== Table 5: Mechanism Decomposition ===\n")

# Entity type decomposition
entity_means <- main_sample[, .(
  pre_org = mean(org_providers[treated == 0], na.rm = TRUE),
  post_org = mean(org_providers[treated == 1], na.rm = TRUE),
  pre_indiv = mean(indiv_providers[treated == 0], na.rm = TRUE),
  post_indiv = mean(indiv_providers[treated == 1], na.rm = TRUE),
  pre_claims_pp = mean(bh_claims_per_provider[treated == 0], na.rm = TRUE),
  post_claims_pp = mean(bh_claims_per_provider[treated == 1], na.rm = TRUE),
  pre_benef_pp = mean(bh_benef_per_provider[treated == 0], na.rm = TRUE),
  post_benef_pp = mean(bh_benef_per_provider[treated == 1], na.rm = TRUE)
), by = .(has_waiver = !is.na(waiver_date))]

fwrite(entity_means, file.path(TABLES, "tab5_mechanism.csv"))

cat("\n=== All tables generated ===\n")
cat(sprintf("Tables saved to: %s\n", normalizePath(TABLES)))
