## 06_tables.R — Generate LaTeX tables for the paper
## apep_0561: ZRR reclassification and RN voting in France
##
## Reads CSV output from 03_main_analysis.R and writes .tex table files
## to ../tables/ using booktabs formatting.

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Helper: significance stars
# ============================================================
stars <- function(p) {
  ifelse(is.na(p), "",
         ifelse(p < 0.01, "***",
                ifelse(p < 0.05, "**",
                       ifelse(p < 0.1, "*", ""))))
}

# Helper: format number with fixed decimals
fmt <- function(x, digits = 3) {
  formatC(x, format = "f", digits = digits, big.mark = ",")
}

# Helper: format integer with LaTeX-safe comma separator
fmt_int <- function(x) {
  gsub(",", "{,}", formatC(as.integer(x), format = "d", big.mark = ","))
}

cat("=== Generating LaTeX tables ===\n\n")


# ============================================================
# Table 1: Summary Statistics (Pre-Treatment, 2012)
# ============================================================
cat("--- Table 1: Summary Statistics ---\n")

summ <- fread(file.path(data_dir, "summary_stats_2012.csv"))
balance <- fread(file.path(data_dir, "balance_tests.csv"))

# Extract loser and stayer stats
losers <- summ[group == "loser"]
stayers <- summ[group == "stayer"]

# Merge with balance test results
tab1_vars <- c("FN/RN Vote Share (%)", "Turnout (%)",
               "Registered Voters", "Valid Votes/Registered (%)")

tab1_lines <- character()
tab1_lines <- c(tab1_lines,
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Characteristics (2012 Presidential Election)}",
  "\\label{tab:summary_stats}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{ZRR Losers} & \\multicolumn{2}{c}{ZRR Stayers} & & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD & Difference & $p$-value \\\\",
  "\\midrule"
)

for (v in tab1_vars) {
  l_row <- losers[variable == v]
  s_row <- stayers[variable == v]
  b_row <- balance[variable == v]

  # Format the difference with significance stars
  diff_str <- paste0(fmt(b_row$diff), stars(b_row$p_value))

  # LaTeX-escape the variable name (% -> \%)
  v_tex <- gsub("%", "\\\\%", v)

  # Use fewer decimal places for registered voters (integers)
  if (v == "Registered Voters") {
    line <- sprintf("%-30s & %s & %s & %s & %s & %s & %s \\\\",
                    v_tex,
                    fmt(l_row$mean, 1), fmt(l_row$sd, 1),
                    fmt(s_row$mean, 1), fmt(s_row$sd, 1),
                    fmt(b_row$diff, 1),
                    fmt(b_row$p_value, 3))
  } else {
    line <- sprintf("%-30s & %s & %s & %s & %s & %s & %s \\\\",
                    v_tex,
                    fmt(l_row$mean), fmt(l_row$sd),
                    fmt(s_row$mean), fmt(s_row$sd),
                    diff_str,
                    fmt(b_row$p_value, 3))
  }
  tab1_lines <- c(tab1_lines, line)
}

# Add observation counts — use max across variables to capture full panel counts
# (some variables have slightly fewer obs due to undefined vote-share ratios)
n_losers_total <- max(losers$n)
n_stayers_total <- max(stayers$n)
tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Communes & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & & \\\\",
          fmt_int(n_losers_total), fmt_int(n_stayers_total)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\parbox{\\textwidth}{\\footnotesize",
  "\\textit{Notes:} Pre-treatment summary statistics for the 2012 presidential election (first round).",
  "ZRR Losers are communes classified as ZRR in the 2014 official list but reclassified out in the 2017--2018 reform.",
  "ZRR Stayers retained ZRR status across both classifications.",
  "Difference is Losers $-$ Stayers. $p$-values from two-sample $t$-tests.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "table1_summary_stats.tex"))
cat("  Saved: table1_summary_stats.tex\n")


# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("--- Table 2: Main DiD Results ---\n")

main_res <- fread(file.path(data_dir, "main_did_results.csv"))

# Drop the "Extended Post" specification (identical to baseline in presidential-only sample)
main_res_tab <- main_res[model != "Extended Post (2019+)"]

# Escape % for LaTeX
main_res_tab$outcome <- gsub("%", "\\\\%", main_res_tab$outcome)
main_res_tab$model <- gsub("%", "\\\\%", main_res_tab$model)

tab2_lines <- character()
tab2_lines <- c(tab2_lines,
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Losing ZRR Status on FN/RN Vote Share}",
  "\\label{tab:main_did}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\"
)

# Column headers
headers <- main_res_tab$model
tab2_lines <- c(tab2_lines,
  sprintf(" & %s & %s & %s \\\\",
          headers[1], headers[2], headers[3]),
  "\\midrule"
)

# Dependent variable row
tab2_lines <- c(tab2_lines,
  sprintf("\\textit{Dep. var.:} & %s & %s & %s \\\\",
          main_res_tab$outcome[1], main_res_tab$outcome[2],
          main_res_tab$outcome[3]),
  " & & & \\\\"
)

# Coefficient row with stars
coef_strs <- sapply(seq_len(nrow(main_res_tab)), function(i) {
  paste0(fmt(main_res_tab$coef[i]), stars(main_res_tab$p_value[i]))
})
tab2_lines <- c(tab2_lines,
  sprintf("Loser $\\times$ Post & %s & %s & %s \\\\",
          coef_strs[1], coef_strs[2], coef_strs[3])
)

# Standard errors in parentheses
se_strs <- sapply(seq_len(nrow(main_res_tab)), function(i) {
  sprintf("(%s)", fmt(main_res_tab$se[i]))
})
tab2_lines <- c(tab2_lines,
  sprintf(" & %s & %s & %s \\\\",
          se_strs[1], se_strs[2], se_strs[3])
)

# Blank separator
tab2_lines <- c(tab2_lines, " & & & \\\\")

# Fixed effects
tab2_lines <- c(tab2_lines,
  "Commune FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\"
)

# Weighted
weighted_strs <- main_res_tab$weighted
tab2_lines <- c(tab2_lines,
  sprintf("Population-weighted & %s & %s & %s \\\\",
          weighted_strs[1], weighted_strs[2], weighted_strs[3])
)

tab2_lines <- c(tab2_lines, "\\midrule")

# N observations
n_strs <- sapply(main_res_tab$n_obs, fmt_int)
tab2_lines <- c(tab2_lines,
  sprintf("Observations & %s & %s & %s \\\\",
          n_strs[1], n_strs[2], n_strs[3])
)

# N communes
nc_strs <- sapply(main_res_tab$n_communes, fmt_int)
tab2_lines <- c(tab2_lines,
  sprintf("Communes & %s & %s & %s \\\\",
          nc_strs[1], nc_strs[2], nc_strs[3])
)

# Within R-squared
r2_strs <- sapply(main_res_tab$r2_within, function(x) fmt(x, 4))
tab2_lines <- c(tab2_lines,
  sprintf("Within $R^2$ & %s & %s & %s \\\\",
          r2_strs[1], r2_strs[2], r2_strs[3])
)

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\parbox{\\textwidth}{\\footnotesize",
  "\\textit{Notes:} Two-way fixed effects estimates of the effect of losing ZRR designation on FN/RN first-round presidential vote share.",
  "Treatment group: communes that lost ZRR status in the 2017 reclassification (identified from the 2014 vs.\\ 2018 official classification lists). Control group: communes that retained ZRR status throughout.",
  "Post $= \\mathbb{1}[\\text{year} = 2022]$ (the only post-reclassification presidential election in the sample).",
  "Column (1) is the baseline specification.",
  "Column (2) weights by registered voter population.",
  "Column (3) uses the log of vote share plus one as the dependent variable.",
  "The panel covers five first-round presidential elections (2002, 2007, 2012, 2017, 2022) for 14{,}685 communes; it is near-balanced, with slight attrition from municipal mergers.",
  "Observation counts below 73{,}425 ($= 14{,}685 \\times 5$) reflect communes absent from certain elections due to mergers or dissolutions.",
  "All specifications include commune and year fixed effects.",
  "Standard errors clustered at the commune level in parentheses.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "table2_main_did.tex"))
cat("  Saved: table2_main_did.tex\n")


# ============================================================
# Table 3: Symmetric Test
# ============================================================
cat("--- Table 3: Symmetric Test ---\n")

sym_res <- fread(file.path(data_dir, "symmetric_did_results.csv"))

tab3_lines <- character()
tab3_lines <- c(tab3_lines,
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Symmetric Test: Losing vs.\\ Gaining ZRR Status}",
  "\\label{tab:symmetric}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & Losers vs.\\ Stayers & Gainers vs.\\ Never-ZRR \\\\",
  "\\midrule",
  "\\textit{Dep. var.:} & FN/RN \\% Expressed & FN/RN \\% Expressed \\\\",
  " & & \\\\"
)

# Main effect from main_did_results (Model 1: Baseline)
m1 <- main_res[model == "Baseline DiD"]

# Coefficient row
coef1_str <- paste0(fmt(m1$coef), stars(m1$p_value))
coef2_str <- paste0(fmt(sym_res$coef[1]), stars(sym_res$p_value[1]))
tab3_lines <- c(tab3_lines,
  sprintf("Treatment $\\times$ Post & %s & %s \\\\", coef1_str, coef2_str)
)

# SE row
se1_str <- sprintf("(%s)", fmt(m1$se))
se2_str <- sprintf("(%s)", fmt(sym_res$se[1]))
tab3_lines <- c(tab3_lines,
  sprintf(" & %s & %s \\\\", se1_str, se2_str),
  " & & \\\\"
)

# Fixed effects
tab3_lines <- c(tab3_lines,
  "Commune FE & Yes & Yes \\\\",
  "Year FE & Yes & Yes \\\\",
  "\\midrule"
)

# Sample info
tab3_lines <- c(tab3_lines,
  sprintf("Observations & %s & %s \\\\",
          fmt_int(m1$n_obs), fmt_int(sym_res$n_obs[1])),
  sprintf("Communes & %s & %s \\\\",
          fmt_int(m1$n_communes), fmt_int(sym_res$n_communes[1])),
  sprintf("Within $R^2$ & %s & %s \\\\",
          fmt(m1$r2_within, 4), fmt(sym_res$r2_within[1], 4))
)

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\parbox{\\textwidth}{\\footnotesize",
  "\\textit{Notes:} Column (1) reproduces the baseline DiD from Table~\\ref{tab:main_did}: communes that lost ZRR status (treatment) vs.\\ communes that retained it (control).",
  "Column (2) estimates the symmetric effect: communes that gained ZRR status in the reform (treatment) vs.\\ communes that never held ZRR status (control).",
  "If ZRR designation causally affects RN voting, losing status should increase and gaining status should decrease RN vote share.",
  "All specifications include commune and year fixed effects. Standard errors clustered at the commune level in parentheses.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "table3_symmetric.tex"))
cat("  Saved: table3_symmetric.tex\n")


# ============================================================
# Table 4: Alternative Outcomes
# ============================================================
cat("--- Table 4: Alternative Outcomes ---\n")

alt_res <- fread(file.path(data_dir, "alternative_outcomes_results.csv"))
alt_res$outcome <- gsub("%", "\\\\%", alt_res$outcome)

tab4_lines <- character()
tab4_lines <- c(tab4_lines,
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Losing ZRR Status on Alternative Electoral Outcomes}",
  "\\label{tab:alt_outcomes}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  sprintf(" & %s & %s & %s \\\\",
          alt_res$outcome[1], alt_res$outcome[2], alt_res$outcome[3]),
  "\\midrule"
)

# Coefficient row with stars
alt_coef_strs <- sapply(seq_len(nrow(alt_res)), function(i) {
  paste0(fmt(alt_res$coef[i]), stars(alt_res$p_value[i]))
})
tab4_lines <- c(tab4_lines,
  sprintf("Loser $\\times$ Post & %s & %s & %s \\\\",
          alt_coef_strs[1], alt_coef_strs[2], alt_coef_strs[3])
)

# SE row
alt_se_strs <- sapply(seq_len(nrow(alt_res)), function(i) {
  sprintf("(%s)", fmt(alt_res$se[i]))
})
tab4_lines <- c(tab4_lines,
  sprintf(" & %s & %s & %s \\\\",
          alt_se_strs[1], alt_se_strs[2], alt_se_strs[3]),
  " & & & \\\\"
)

# Fixed effects
tab4_lines <- c(tab4_lines,
  "Commune FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  "\\midrule"
)

# Sample info
alt_n_strs <- sapply(alt_res$n_obs, fmt_int)
alt_r2_strs <- sapply(alt_res$r2_within, function(x) fmt(x, 4))
tab4_lines <- c(tab4_lines,
  sprintf("Observations & %s & %s & %s \\\\",
          alt_n_strs[1], alt_n_strs[2], alt_n_strs[3]),
  sprintf("Within $R^2$ & %s & %s & %s \\\\",
          alt_r2_strs[1], alt_r2_strs[2], alt_r2_strs[3])
)

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\parbox{\\textwidth}{\\footnotesize",
  "\\textit{Notes:} Difference-in-differences estimates of the effect of losing ZRR status on alternative electoral outcomes.",
  "Column (1) uses voter turnout (\\%) as the dependent variable.",
  "Column (2) uses the abstention rate (\\%), mechanically equal to $100 -$ turnout.",
  "Column (3) uses the raw count of FN/RN votes as the dependent variable, testing whether the effect operates on the extensive margin (number of votes) rather than the intensive margin (vote share).",
  "Treatment and control groups are identical to Table~\\ref{tab:main_did}.",
  "The observation count is slightly higher than in Table~\\ref{tab:main_did} because 11 commune-elections with zero valid votes (undefined vote shares) are excluded from vote-share regressions but retained here.",
  "All specifications include commune and year fixed effects. Standard errors clustered at the commune level in parentheses.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "table4_alt_outcomes.tex"))
cat("  Saved: table4_alt_outcomes.tex\n")


# ============================================================
# Appendix Table: Heterogeneity and Placebo Results
# ============================================================
cat("--- Appendix Table: Heterogeneity & Placebo ---\n")

size_het <- fread(file.path(data_dir, "robustness_size_heterogeneity.csv"))
fn_het <- fread(file.path(data_dir, "robustness_fn_heterogeneity.csv"))
plac <- fread(file.path(data_dir, "robustness_placebo.csv"))

tab_het_lines <- character()
tab_het_lines <- c(tab_het_lines,
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity and Placebo Tests}",
  "\\label{tab:heterogeneity}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Small & Large & Low Prior FN & High Prior FN & Placebo \\\\",
  "\\midrule",
  "\\textit{Dep. var.:} & \\multicolumn{5}{c}{FN/RN Vote Share (\\%)} \\\\"
)

# Get values
small <- size_het[subgroup == "Small communes"]
large <- size_het[subgroup == "Large communes"]
low_fn <- fn_het[subgroup == "Low prior FN"]
high_fn <- fn_het[subgroup == "High prior FN"]
placebo <- plac[test == "Placebo (fake 2012 treatment)"]

coef_strs <- c(
  paste0(fmt(small$coef), stars(small$p_value)),
  paste0(fmt(large$coef), stars(large$p_value)),
  paste0(fmt(low_fn$coef), stars(low_fn$p_value)),
  paste0(fmt(high_fn$coef), stars(high_fn$p_value)),
  paste0(fmt(placebo$coef), stars(placebo$p_value))
)
se_strs <- sprintf("(%s)", c(fmt(small$se), fmt(large$se), fmt(low_fn$se), fmt(high_fn$se), fmt(placebo$se)))

tab_het_lines <- c(tab_het_lines,
  " & & & & & \\\\",
  sprintf("Treatment $\\times$ Post & %s & %s & %s & %s & %s \\\\",
          coef_strs[1], coef_strs[2], coef_strs[3], coef_strs[4], coef_strs[5]),
  sprintf(" & %s & %s & %s & %s & %s \\\\",
          se_strs[1], se_strs[2], se_strs[3], se_strs[4], se_strs[5]),
  " & & & & & \\\\",
  "Commune FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          fmt_int(small$n_obs), fmt_int(large$n_obs),
          fmt_int(low_fn$n_obs), fmt_int(high_fn$n_obs),
          fmt_int(placebo$n_obs)),
  sprintf("Communes & %s & %s & %s & %s & %s \\\\",
          fmt_int(small$n_communes), fmt_int(large$n_communes),
          fmt_int(low_fn$n_communes), fmt_int(high_fn$n_communes),
          fmt_int(14685)),  # Placebo uses the same DiD sample communes
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\vspace{0.3em}",
  "\\parbox{\\textwidth}{\\footnotesize",
  sprintf("\\textit{Notes:} Columns (1)--(2) split the sample at the median commune size (%s registered voters in 2012).", fmt_int(small$median_cutoff)),
  sprintf("Columns (3)--(4) split at the median 2012 FN/RN vote share (%s\\%%).", fmt(fn_het$median_cutoff[1], 1)),
  "Column (5) restricts the sample to pre-reform elections (2002, 2007, 2012, 2017) and defines a placebo post indicator equal to one for 2017, testing whether losers and stayers were already diverging before the reform took economic effect.",
  "All specifications include commune and year fixed effects. Standard errors clustered at the commune level.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
  "\\end{table}"
)

writeLines(tab_het_lines, file.path(table_dir, "table_heterogeneity.tex"))
cat("  Saved: table_heterogeneity.tex\n")


# ============================================================
# Summary
# ============================================================
# ============================================================
# Table: Denominator Outcomes (Electorate Composition)
# ============================================================
cat("--- Table: Denominator Outcomes ---\n")

denom_file <- file.path(data_dir, "denominator_outcomes_results.csv")
if (file.exists(denom_file)) {
  denom <- fread(denom_file)

  tab_denom_lines <- character()
  tab_denom_lines <- c(tab_denom_lines,
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Effect of Losing ZRR Status on Electorate Composition}",
    "\\label{tab:denominator}",
    "\\begin{tabular}{lccc}",
    "\\toprule",
    " & (1) & (2) & (3) \\\\",
    " & Registered & Valid Votes & Number of \\\\",
    " & Voters & (\\textit{Exprim\\'{e}s}) & Voters \\\\",
    "\\midrule"
  )

  for (i in seq_len(nrow(denom))) {
    if (i == 1) {
      tab_denom_lines <- c(tab_denom_lines,
        sprintf("Treatment $\\times$ Post & %s%s & ", fmt(denom$coef[1], 2), stars(denom$p_value[1])))
    }
  }

  # Build coefficient and SE rows
  coef_row <- paste(sapply(seq_len(nrow(denom)), function(i) {
    paste0(fmt(denom$coef[i], 2), stars(denom$p_value[i]))
  }), collapse = " & ")
  se_row <- paste(sapply(seq_len(nrow(denom)), function(i) {
    sprintf("(%s)", fmt(denom$se[i], 2))
  }), collapse = " & ")
  n_row <- paste(sapply(seq_len(nrow(denom)), function(i) {
    fmt_int(denom$n_obs[i])
  }), collapse = " & ")

  # Remove the partial line added above and rebuild properly
  tab_denom_lines <- tab_denom_lines[1:(length(tab_denom_lines) - 1)]  # remove last partial line

  tab_denom_lines <- c(tab_denom_lines,
    sprintf("Treatment $\\times$ Post & %s \\\\", coef_row),
    sprintf(" & %s \\\\", se_row),
    " & & & \\\\",
    "Commune FE & Yes & Yes & Yes \\\\",
    "Year FE & Yes & Yes & Yes \\\\",
    "\\midrule",
    sprintf("Observations & %s \\\\", n_row),
    "\\bottomrule",
    "\\end{tabular}",
    "\\vspace{0.3em}",
    "\\parbox{\\textwidth}{\\footnotesize",
    "\\textit{Notes:} DiD estimates of the effect of losing ZRR status on electorate composition outcomes.",
    "Registered voters = \\textit{inscrits}; valid votes = \\textit{exprim\\'{e}s}; number of voters = \\textit{votants}.",
    "Each column represents the count (not percentage) of the respective outcome.",
    "Positive coefficients indicate differential growth in loser communes relative to stayers.",
    "All specifications include commune and year fixed effects. Standard errors clustered at the commune level.",
    "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
    "\\end{table}"
  )

  writeLines(tab_denom_lines, file.path(table_dir, "table_denominator.tex"))
  cat("  Saved: table_denominator.tex\n")
} else {
  cat("  WARNING: denominator_outcomes_results.csv not found — skipping table.\n")
}


# ============================================================
# Table: EPCI-Level Clustering Comparison
# ============================================================
cat("--- Table: EPCI Clustering Comparison ---\n")

epci_file <- file.path(data_dir, "epci_cluster_comparison.csv")
if (file.exists(epci_file)) {
  epci_comp <- fread(epci_file)

  tab_epci_lines <- character()
  tab_epci_lines <- c(tab_epci_lines,
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Main Results: Commune-Level vs.\\ EPCI-Level Clustering}",
    "\\label{tab:epci_cluster}",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    " & (1) & (2) \\\\",
    " & Commune SE & EPCI SE \\\\",
    "\\midrule"
  )

  commune_row <- epci_comp[cluster_level == "commune"]
  epci_row <- epci_comp[cluster_level == "epci"]

  tab_epci_lines <- c(tab_epci_lines,
    sprintf("Treatment $\\times$ Post & %s%s & %s%s \\\\",
            fmt(commune_row$coef), stars(commune_row$p_value),
            fmt(epci_row$coef), stars(epci_row$p_value)),
    sprintf(" & (%s) & (%s) \\\\",
            fmt(commune_row$se), fmt(epci_row$se)),
    " & & \\\\",
    "Commune FE & Yes & Yes \\\\",
    "Year FE & Yes & Yes \\\\",
    "\\midrule",
    sprintf("Observations & %s & %s \\\\",
            fmt_int(commune_row$n_obs), fmt_int(epci_row$n_obs)),
    sprintf("Clusters & %s & %s \\\\",
            fmt_int(commune_row$n_clusters), fmt_int(epci_row$n_clusters)),
    "\\bottomrule",
    "\\end{tabular}",
    "\\vspace{0.3em}",
    "\\parbox{\\textwidth}{\\footnotesize",
    "\\textit{Notes:} Column (1) reports commune-level clustered standard errors (baseline). Column (2) reports EPCI-level clustered standard errors, which is the appropriate assignment-unit level since ZRR eligibility is determined by EPCI-level characteristics. Point estimates are identical; only inference changes. The number of EPCI clusters reflects the intercommunal groupings to which sample communes belong.",
    "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
    "\\end{table}"
  )

  writeLines(tab_epci_lines, file.path(table_dir, "table_epci_cluster.tex"))
  cat("  Saved: table_epci_cluster.tex\n")
} else {
  cat("  WARNING: epci_cluster_comparison.csv not found — skipping table.\n")
}


cat("\n=== All tables generated ===\n")
cat("  ../tables/table1_summary_stats.tex   — Summary statistics (losers vs stayers, 2012)\n")
cat("  ../tables/table2_main_did.tex        — Main DiD results (3 specifications)\n")
cat("  ../tables/table3_symmetric.tex       — Symmetric test (losers vs gainers)\n")
cat("  ../tables/table4_alt_outcomes.tex    — Alternative outcomes (turnout, abstention, raw votes)\n")
cat("  ../tables/table_heterogeneity.tex    — Heterogeneity and placebo tests\n")
cat("  ../tables/table_denominator.tex      — Denominator/electorate composition\n")
cat("  ../tables/table_epci_cluster.tex     — EPCI-level clustering comparison\n")
cat("\n=== 06_tables.R complete ===\n")
