## 05_tables.R — Generate all LaTeX tables
## APEP paper apep_0611: CRA Lookback Cutoff and Midnight Rulemaking
## V1 format: ≤5 tables in main text + SDE appendix table

source("00_packages.R")

df <- readRDS("../data/rules_analysis.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
density_results <- readRDS("../data/density_results.rds")

dir.create("../tables", showWarnings = FALSE)

# ═══════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════════

# Compute summary stats by transition type
sumstats_cross <- df %>% filter(cross_party)
sumstats_same <- df %>% filter(!cross_party)

make_row <- function(var, label, data_cross, data_same) {
  x_c <- data_cross[[var]]
  x_s <- data_same[[var]]
  x_c <- x_c[!is.na(x_c)]
  x_s <- x_s[!is.na(x_s)]
  sprintf("%-35s & %10s & %10s & %10s & %10s & %10s & %10s \\\\",
          label,
          format(round(mean(x_c), 2), nsmall = 2),
          format(round(sd(x_c), 2), nsmall = 2),
          format(length(x_c), big.mark = ","),
          format(round(mean(x_s), 2), nsmall = 2),
          format(round(sd(x_s), 2), nsmall = 2),
          format(length(x_s), big.mark = ","))
}

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Federal Register Final Rules near CRA Lookback Cutoff}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Cross-Party Transitions} & \\multicolumn{3}{c}{Same-Party Transitions} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  "Variable & Mean & SD & N & Mean & SD & N \\\\",
  "\\midrule",
  make_row("significant", "Significant rule (0/1)", sumstats_cross, sumstats_same),
  make_row("page_length", "Page count", sumstats_cross, sumstats_same),
  make_row("n_cfr_parts", "CFR parts affected", sumstats_cross, sumstats_same),
  sprintf("%-35s & %10s & %10s & %10s & %10s & %10s & %10s \\\\",
          "CRA-vulnerable (0/1)",
          format(round(mean(sumstats_cross$cra_vulnerable), 2), nsmall = 2),
          format(round(sd(sumstats_cross$cra_vulnerable), 2), nsmall = 2),
          format(nrow(sumstats_cross), big.mark = ","),
          format(round(mean(sumstats_same$cra_vulnerable), 2), nsmall = 2),
          format(round(sd(sumstats_same$cra_vulnerable), 2), nsmall = 2),
          format(nrow(sumstats_same), big.mark = ",")),
  sprintf("%-35s & %10s & %10s & %10s & %10s & %10s & %10s \\\\",
          "Days from cutoff",
          format(round(mean(sumstats_cross$days_from_cutoff), 1), nsmall = 1),
          format(round(sd(sumstats_cross$days_from_cutoff), 1), nsmall = 1),
          format(nrow(sumstats_cross), big.mark = ","),
          format(round(mean(sumstats_same$days_from_cutoff), 1), nsmall = 1),
          format(round(sd(sumstats_same$days_from_cutoff), 1), nsmall = 1),
          format(nrow(sumstats_same), big.mark = ",")),
  "\\midrule",
  sprintf("Transitions & \\multicolumn{3}{c}{%d (2001, 2009, 2017, 2021, 2025)} & \\multicolumn{3}{c}{%d (2005, 2013)} \\\\",
          length(unique(df$transition_year[df$cross_party])),
          length(unique(df$transition_year[!df$cross_party]))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Sample includes all final rules published in the Federal Register within $\\pm$365 days of the CRA lookback cutoff for each presidential transition (1999--2025). Total N = %s. Cross-party transitions are those where the incoming president is of a different party than the outgoing president. ``Significant'' denotes rules classified as significant under E.O. 12866. CRA-vulnerable rules are those published after the CRA lookback cutoff date and thus eligible for Congressional Review Act disapproval resolutions.", format(nrow(df), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 (summary statistics) written.\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 2: Density Discontinuity Tests
# ═══════════════════════════════════════════════════════════════════════

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Density Discontinuity Tests at the CRA Lookback Cutoff}",
  "\\label{tab:density}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Transition & Type & N (left) & N (right) & T-statistic & p-value \\\\",
  "\\midrule"
)

# Add pooled results
tab2_lines <- c(tab2_lines,
  sprintf("\\textit{All transitions} & --- & %d & %d & %.3f & %.4f \\\\",
          results$density_all$N$eff_left, results$density_all$N$eff_right,
          results$density_all$test$t_jk, results$density_all$test$p_jk),
  sprintf("\\textit{Cross-party} & --- & %d & %d & %.3f & %.4f \\\\",
          results$density_cross$N$eff_left, results$density_cross$N$eff_right,
          results$density_cross$test$t_jk, results$density_cross$test$p_jk),
  sprintf("\\textit{Same-party} & --- & %d & %d & %.3f & %.4f \\\\",
          results$density_same$N$eff_left, results$density_same$N$eff_right,
          results$density_same$test$t_jk, results$density_same$test$p_jk),
  "\\midrule"
)

# Add by-year results
for (i in seq_len(nrow(density_results))) {
  row <- density_results[i, ]
  type_label <- ifelse(row$cross_party, "Cross", "Same")
  tab2_lines <- c(tab2_lines,
    sprintf("%d & %s & %d & %d & %.3f & %.4f \\\\",
            row$transition_year, type_label,
            row$n_left, row$n_right,
            row$t_stat, row$p_value))
}

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Cattaneo, Jansson, and Ma (2020) density discontinuity test at the CRA lookback cutoff. N (left) and N (right) are the effective sample sizes used within the data-driven bandwidth. A significant test statistic rejects the null of continuity in the density of rule publications at the cutoff, indicating strategic timing. Cross-party transitions: 2001, 2009, 2017, 2021, 2025. Same-party transitions: 2005, 2013.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_density.tex")
cat("Table 2 (density tests) written.\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 3: Main RDD and Diff-in-Disc Results
# ═══════════════════════════════════════════════════════════════════════

# Extract RDD results
extract_rdd <- function(rdd_obj, label) {
  if (is.null(rdd_obj)) return(NULL)
  tibble(
    label = label,
    coef = rdd_obj$coef[1],
    se_robust = rdd_obj$se[3],
    p_robust = rdd_obj$pv[3],
    bw = rdd_obj$bws[1, 1],
    n_left = rdd_obj$N_h[1],
    n_right = rdd_obj$N_h[2]
  )
}

rdd_rows <- bind_rows(
  extract_rdd(results$rdd_sig_cross, "Significant (cross-party)"),
  extract_rdd(results$rdd_sig_same, "Significant (same-party)"),
  extract_rdd(results$rdd_pages_cross, "Page length (cross-party)"),
  extract_rdd(results$rdd_pages_same, "Page length (same-party)")
)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{RDD Estimates: Rule Characteristics at the CRA Lookback Cutoff}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Significant Rule (0/1)} & \\multicolumn{2}{c}{Page Length} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Cross-Party & Same-Party & Cross-Party & Same-Party \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule"
)

# RDD estimates row
if (nrow(rdd_rows) >= 4) {
  tab3_lines <- c(tab3_lines,
    sprintf("RD Estimate & %.4f%s & %.4f%s & %.2f%s & %.2f%s \\\\",
            rdd_rows$coef[1], stars(rdd_rows$p_robust[1]),
            rdd_rows$coef[2], stars(rdd_rows$p_robust[2]),
            rdd_rows$coef[3], stars(rdd_rows$p_robust[3]),
            rdd_rows$coef[4], stars(rdd_rows$p_robust[4])),
    sprintf(" & (%.4f) & (%.4f) & (%.2f) & (%.2f) \\\\",
            rdd_rows$se_robust[1], rdd_rows$se_robust[2],
            rdd_rows$se_robust[3], rdd_rows$se_robust[4]),
    "",
    sprintf("Bandwidth (days) & %.0f & %.0f & %.0f & %.0f \\\\",
            rdd_rows$bw[1], rdd_rows$bw[2],
            rdd_rows$bw[3], rdd_rows$bw[4]),
    sprintf("N (left/right) & %d/%d & %d/%d & %d/%d & %d/%d \\\\",
            rdd_rows$n_left[1], rdd_rows$n_right[1],
            rdd_rows$n_left[2], rdd_rows$n_right[2],
            rdd_rows$n_left[3], rdd_rows$n_right[3],
            rdd_rows$n_left[4], rdd_rows$n_right[4])
  )
} else {
  # Fallback: use whatever results we have
  for (i in seq_len(nrow(rdd_rows))) {
    r <- rdd_rows[i, ]
    tab3_lines <- c(tab3_lines,
      sprintf("%s & %.4f%s & (%.4f) & %.0f & %d/%d \\\\",
              r$label, r$coef, stars(r$p_robust),
              r$se_robust, r$bw, r$n_left, r$n_right))
  }
}

# Diff-in-disc from parametric model
did_coefs <- coef(results$did_sig)
did_ses <- sqrt(diag(vcov(results$did_sig, type = "HC1")))
idx_did <- grep("cra_vulnerableTRUE:cross_partyTRUE", names(did_coefs))

if (length(idx_did) > 0) {
  did_p <- 2 * pnorm(-abs(did_coefs[idx_did] / did_ses[idx_did]))
  tab3_lines <- c(tab3_lines,
    "\\midrule",
    sprintf("\\textit{Diff-in-Disc ($\\hat{\\beta}_3$)} & \\multicolumn{2}{c}{%.4f%s} & \\multicolumn{2}{c}{} \\\\",
            did_coefs[idx_did], stars(did_p)),
    sprintf(" & \\multicolumn{2}{c}{(%.4f)} & \\multicolumn{2}{c}{} \\\\",
            did_ses[idx_did])
  )
}

# Also extract did_pages diff-in-disc
did_p_coefs <- coef(results$did_pages)
did_p_ses <- sqrt(diag(vcov(results$did_pages, type = "HC1")))
idx_did_p <- grep("cra_vulnerableTRUE:cross_partyTRUE", names(did_p_coefs))

if (length(idx_did_p) > 0) {
  did_pp <- 2 * pnorm(-abs(did_p_coefs[idx_did_p] / did_p_ses[idx_did_p]))
  tab3_lines <- c(tab3_lines,
    sprintf("\\textit{Diff-in-Disc (Pages)} & \\multicolumn{2}{c}{} & \\multicolumn{2}{c}{%.2f%s} \\\\",
            did_p_coefs[idx_did_p], stars(did_pp)),
    sprintf(" & \\multicolumn{2}{c}{} & \\multicolumn{2}{c}{(%.2f)} \\\\",
            did_p_ses[idx_did_p])
  )
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Local linear RDD estimates using triangular kernel and MSE-optimal (CCT) bandwidth selection. Robust bias-corrected confidence intervals. Columns (1)--(2): outcome is a binary indicator for whether the rule is classified as ``significant'' under E.O. 12866. Columns (3)--(4): outcome is Federal Register page count. The diff-in-disc estimate $\\hat{\\beta}_3$ compares the discontinuity at the CRA lookback cutoff in cross-party transition years against the same cutoff in same-party transition years. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_main.tex")
cat("Table 3 (main results) written.\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 4: Bandwidth Sensitivity and Placebo Cutoffs
# ═══════════════════════════════════════════════════════════════════════

bw_sens <- robustness$bw_sensitivity
bw_pages <- robustness$bw_pages_sensitivity
placebo <- robustness$placebo
excl_sens <- robustness$exclude_sensitivity

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Bandwidth Sensitivity, Placebo Cutoffs, and Transition Exclusions}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Bandwidth Sensitivity --- Diff-in-Disc, Significant Rule}} \\\\",
  "\\midrule",
  "Bandwidth (days) & Estimate & SE & p-value & N \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(bw_sens))) {
  r <- bw_sens[i, ]
  tab4_lines <- c(tab4_lines,
    sprintf("$\\pm$%d & %.4f%s & %.4f & %.4f & %s \\\\",
            r$bandwidth, r$coef, stars(r$p_value),
            r$se, r$p_value, format(r$n, big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Bandwidth Sensitivity --- Diff-in-Disc, Page Length}} \\\\",
  "\\midrule",
  "Bandwidth (days) & Estimate & SE & p-value & N \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(bw_pages))) {
  r <- bw_pages[i, ]
  tab4_lines <- c(tab4_lines,
    sprintf("$\\pm$%d & %.2f%s & %.2f & %.4f & %s \\\\",
            r$bandwidth, r$coef, stars(r$p_value),
            r$se, r$p_value, format(r$n, big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo Cutoffs (RDD on Significant, Cross-Party Only)}} \\\\",
  "\\midrule",
  "Cutoff Offset (days) & Estimate & Robust SE & p-value & N (eff.) \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(placebo))) {
  r <- placebo[i, ]
  label <- ifelse(r$offset == 0, "\\textbf{0 (true cutoff)}", sprintf("%+d", r$offset))
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %.4f%s & %.4f & %.4f & %s \\\\",
            label, r$coef, stars(r$p_value),
            r$se, r$p_value, format(round(r$n_eff), big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel D: Sensitivity to Excluding Transitions}} \\\\",
  "\\midrule",
  "Specification & Estimate & SE & p-value & N \\\\",
  "\\midrule"
)

if (!is.null(excl_sens) && nrow(excl_sens) > 0) {
  for (i in seq_len(nrow(excl_sens))) {
    r <- excl_sens[i, ]
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %.2f%s & %.2f & %.4f & %s \\\\",
              r$specification, r$coef, stars(r$p_value),
              r$se, r$p_value, format(r$n, big.mark = ",")))
  }
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Panels A--B report the diff-in-disc interaction estimate ($\\hat{\\beta}_3$: CRA-vulnerable $\\times$ cross-party) for varying bandwidths. HC1 robust standard errors. Panel C reports local linear RDD estimates at placebo cutoffs, cross-party transitions only. Panel D re-estimates the page-length diff-in-disc excluding the 2017 and/or 2025 transitions, which exhibit significant density discontinuities. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("Table 4 (robustness) written.\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 5: Midnight Rulemaking by Transition Year
# ═══════════════════════════════════════════════════════════════════════
# Descriptive table showing rule volume in the CRA window by transition

transition_stats <- df %>%
  group_by(transition_year, cross_party) %>%
  summarize(
    total_rules = n(),
    rules_in_window = sum(cra_vulnerable),
    pct_in_window = 100 * mean(cra_vulnerable),
    significant_total = sum(significant, na.rm = TRUE),
    significant_in_window = sum(significant & cra_vulnerable, na.rm = TRUE),
    avg_pages = mean(page_length, na.rm = TRUE),
    .groups = "drop"
  )

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Midnight Rulemaking: Rule Volume by Presidential Transition}",
  "\\label{tab:midnight}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccccc}",
  "\\toprule",
  "Transition & Type & Total & In CRA & \\% In CRA & Signif. & Signif. in & Avg. \\\\",
  " & & Rules & Window & Window & Total & CRA Window & Pages \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(transition_stats))) {
  r <- transition_stats[i, ]
  type_label <- ifelse(r$cross_party, "Cross", "Same")
  tab5_lines <- c(tab5_lines,
    sprintf("%d & %s & %s & %s & %.1f & %s & %s & %.1f \\\\",
            r$transition_year, type_label,
            format(r$total_rules, big.mark = ","),
            format(r$rules_in_window, big.mark = ","),
            r$pct_in_window,
            format(r$significant_total, big.mark = ","),
            format(r$significant_in_window, big.mark = ","),
            r$avg_pages))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row shows one presidential transition. ``Total Rules'' counts all final rules published in the Federal Register within $\\pm$365 days of the CRA lookback cutoff. ``In CRA Window'' counts rules published after the lookback date. ``Significant'' denotes rules classified as significant under E.O. 12866. Cross-party transitions involve a change in the party of the president; same-party transitions do not. The CRA lookback window spans approximately the final 60 Senate session days of each Congress.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_midnight.tex")
cat("Table 5 (midnight rulemaking) written.\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Sizes (SDE) — Appendix
# ═══════════════════════════════════════════════════════════════════════

classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_rows <- list()

# SDE for significant flag (binary treatment at cutoff)
if (!is.null(results$rdd_sig_cross)) {
  beta_sig <- results$rdd_sig_cross$coef[1]
  se_sig <- results$rdd_sig_cross$se[3]
  sd_y_sig <- sd(as.numeric(df$significant[df$cross_party]), na.rm = TRUE)
  sde_sig <- beta_sig / sd_y_sig
  se_sde_sig <- se_sig / sd_y_sig

  sde_rows[["sig"]] <- tibble(
    outcome = "Significant rule (0/1)",
    spec = "Loc. lin.",
    beta = beta_sig,
    sd_x = "---",
    sd_y = sd_y_sig,
    sde = sde_sig,
    se_sde = se_sde_sig,
    classification = classify_sde(sde_sig)
  )
}

# SDE for page length
if (!is.null(results$rdd_pages_cross)) {
  beta_pg <- results$rdd_pages_cross$coef[1]
  se_pg <- results$rdd_pages_cross$se[3]
  sd_y_pg <- sd(df$page_length[df$cross_party], na.rm = TRUE)
  sde_pg <- beta_pg / sd_y_pg
  se_sde_pg <- se_pg / sd_y_pg

  sde_rows[["pages"]] <- tibble(
    outcome = "Page length",
    spec = "Loc. lin.",
    beta = beta_pg,
    sd_x = "---",
    sd_y = sd_y_pg,
    sde = sde_pg,
    se_sde = se_sde_pg,
    classification = classify_sde(sde_pg)
  )
}

sde_table <- bind_rows(sde_rows)

if (nrow(sde_table) > 0) {
  sde_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Standardized Effect Sizes for Main Outcomes}",
    "\\label{tab:sde}",
    "\\begin{threeparttable}",
    "\\begin{tabular}{lccccccl}",
    "\\toprule",
    "Outcome & Spec. & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE & Class. \\\\",
    "\\midrule"
  )

  for (i in seq_len(nrow(sde_table))) {
    r <- sde_table[i, ]
    sde_lines <- c(sde_lines,
      sprintf("%s & %s & %.4f & %s & %.4f & %.4f & %.4f & %s \\\\",
              r$outcome, r$spec, r$beta, r$sd_x,
              r$sd_y, r$sde, r$se_sde, r$classification))
  }

  sde_lines <- c(sde_lines,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\footnotesize",
    sprintf("\\item \\textit{Notes:} Standardized effect sizes (SDE $= \\hat{\\beta} / \\text{SD}(Y)$) for cross-study comparison. Spec.: local linear RDD, CCT bandwidth, triangular kernel. Data: Federal Register API, cross-party transitions (2001--2025), N~=~%s. Treatment: binary (inside vs.\\ outside CRA window). Class.\\ labels refer to SDE magnitude, not statistical significance. ``Null'': $|$SDE$|<0.005$.",
            format(sum(df$cross_party), big.mark = ",")),
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\end{table}"
  )

  writeLines(sde_lines, "../tables/tabF1_sde.tex")
  cat("Table F1 (SDE) written.\n")
} else {
  cat("WARNING: No SDE results to write.\n")
}

cat("\n05_tables.R completed successfully.\n")
