## 06_tables.R — Generate all LaTeX tables
## apep_0501: Municipal Mergers and Direct Democracy in Switzerland

source("00_packages.R")

DATA_DIR <- "../data"
TAB_DIR <- "../tables"
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, vote_date := as.Date(vote_date)]
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))

# =============================================================================
# TABLE 1: SUMMARY STATISTICS
# =============================================================================

cat("Table 1: Summary statistics\n")

summary_data <- panel[, .(
  group = fifelse(treated, "Treated", "Control"),
  turnout = turnout_final,
  eligible = as.numeric(eligible),
  yes_share = yes_share,
  vote_year = vote_year
)]

tab1_rows <- list()
for (g in c("Full Sample", "Treated", "Control")) {
  if (g == "Full Sample") {
    d <- summary_data
  } else {
    d <- summary_data[group == g]
  }
  tab1_rows[[g]] <- data.table(
    Group = g,
    N = format(nrow(d), big.mark = ","),
    Communes = uniqueN(panel[if(g == "Full Sample") TRUE else treated == (g == "Treated"), commune_code]),
    `Mean Turnout` = sprintf("%.1f", mean(d$turnout, na.rm = TRUE)),
    `SD Turnout` = sprintf("%.1f", sd(d$turnout, na.rm = TRUE)),
    `Mean Eligible` = format(round(mean(d$eligible, na.rm = TRUE)), big.mark = ","),
    `Median Eligible` = format(round(median(d$eligible, na.rm = TRUE)), big.mark = ","),
    `Mean Yes Share` = sprintf("%.1f", mean(d$yes_share, na.rm = TRUE))
  )
}
tab1 <- rbindlist(tab1_rows)

# LaTeX output
sink(file.path(TAB_DIR, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccccc}\n")
cat("\\toprule\n")
cat(" & N & Communes & Mean & SD & Mean & Median & Mean \\\\\n")
cat(" & & & Turnout & Turnout & Eligible & Eligible & Yes \\% \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(tab1))) {
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
              tab1$Group[i], tab1$N[i], tab1$Communes[i],
              tab1$`Mean Turnout`[i], tab1$`SD Turnout`[i],
              tab1$`Mean Eligible`[i], tab1$`Median Eligible`[i],
              tab1$`Mean Yes Share`[i]))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.9\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\emph{Notes:} Commune-referendum level panel. Turnout is the percentage of eligible voters casting a ballot. ``Treated'' communes are the successor entities (TerminalCode in BFS mutations data) of mergers between 2000 and 2020. ``Control'' communes never experienced a merger during 2000--2020.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("  Saved tab1_summary.tex\n")

# =============================================================================
# TABLE 2: MAIN RESULTS
# =============================================================================

cat("Table 2: Main results\n")

# Collect coefficients from different specifications
specs <- data.table(
  Specification = character(),
  ATT = character(),
  SE = character(),
  N = character(),
  Communes = character()
)

# (1) TWFE baseline
specs <- rbind(specs, data.table(
  Specification = "TWFE",
  ATT = sprintf("%.3f", results$att_twfe),
  SE = sprintf("(%.3f)", results$se_twfe),
  N = format(nrow(panel), big.mark = ","),
  Communes = as.character(results$n_treated + results$n_control)
))

# (2) CS-DiD (if available)
if (!is.null(results$att_cs)) {
  specs <- rbind(specs, data.table(
    Specification = "Callaway--Sant'Anna",
    ATT = sprintf("%.3f", results$att_cs),
    SE = sprintf("(%.3f)", results$se_cs),
    N = format(nrow(panel), big.mark = ","),
    Communes = as.character(results$n_treated + results$n_control)
  ))
}

# (3) Stacked DiD
if (!is.null(results$att_stacked)) {
  stacked_n <- if (!is.null(results$n_stacked)) format(results$n_stacked, big.mark = ",") else "---"
  stacked_communes <- if (!is.null(results$communes_stacked)) as.character(results$communes_stacked) else "---"
  specs <- rbind(specs, data.table(
    Specification = "Stacked DiD",
    ATT = sprintf("%.3f", results$att_stacked),
    SE = sprintf("(%.3f)", results$se_stacked),
    N = stacked_n,
    Communes = stacked_communes
  ))
}

# (4) Matched DiD
if (!is.null(results$att_matched)) {
  matched_n <- if (!is.null(results$n_matched)) format(results$n_matched, big.mark = ",") else "---"
  matched_communes <- if (!is.null(results$communes_matched)) as.character(results$communes_matched) else "---"
  specs <- rbind(specs, data.table(
    Specification = "Matched DiD",
    ATT = sprintf("%.3f", results$att_matched),
    SE = sprintf("(%.3f)", results$se_matched),
    N = matched_n,
    Communes = matched_communes
  ))
}

# (5) Excl. Glarus
if (!is.null(results$att_no_glarus)) {
  noglarus_n <- if (!is.null(results$n_no_glarus)) format(results$n_no_glarus, big.mark = ",") else "---"
  noglarus_communes <- if (!is.null(results$communes_no_glarus)) as.character(results$communes_no_glarus) else "---"
  specs <- rbind(specs, data.table(
    Specification = "Excl.\\ Glarus",
    ATT = sprintf("%.3f", results$att_no_glarus),
    SE = sprintf("(%.3f)", results$se_no_glarus),
    N = noglarus_n,
    Communes = noglarus_communes
  ))
}

sink(file.path(TAB_DIR, "tab2_main_results.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Municipal Mergers on Referendum Turnout}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Specification & ATT (pp) & SE & N & Communes \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(specs))) {
  cat(sprintf("%s & %s & %s & %s & %s \\\\\n",
              specs$Specification[i], specs$ATT[i], specs$SE[i],
              specs$N[i], specs$Communes[i]))
}
cat("\\midrule\n")
cat("Commune FE & \\multicolumn{4}{c}{Yes} \\\\\n")
cat("Vote-date FE & \\multicolumn{4}{c}{Yes} \\\\\n")
cat("Clustering & \\multicolumn{4}{c}{Commune} \\\\\n")
if (!is.null(results$ri_pval)) {
  cat(sprintf("RI $p$-value & \\multicolumn{4}{c}{%.3f} \\\\\n", results$ri_pval))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.9\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\emph{Notes:} Dependent variable is federal referendum turnout (\\%). ATT is the average treatment effect on the treated, where treatment is the merger event. Standard errors clustered at the commune level in parentheses. Row (1) reports the two-way fixed effects estimate. Row (2) uses stacked cohort-specific DiD with $\\pm 5$-year windows; N exceeds the base panel because control communes appear in each cohort-specific sub-experiment. Row (3) matches treated to control communes on pre-merger turnout. Row (4) excludes the Glarus mega-merger (25$\\to$3 successor communes in 2011), reducing both total and treated counts by 3.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("  Saved tab2_main_results.tex\n")

# =============================================================================
# TABLE 3: PRE-TREND TEST
# =============================================================================

cat("Table 3: Pre-trend test\n")

es_file <- file.path(DATA_DIR, "event_study_twfe.csv")
if (file.exists(es_file)) {
  es <- fread(es_file)
  pre <- es[event_time < -1]

  sink(file.path(TAB_DIR, "tab3_pretrend.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{Pre-Trend Diagnostics}\n")
  cat("\\label{tab:pretrend}\n")
  cat("\\begin{tabular}{lcc}\n")
  cat("\\toprule\n")
  cat("Event Time & Estimate (pp) & SE \\\\\n")
  cat("\\midrule\n")
  for (i in seq_len(nrow(es[order(event_time)]))) {
    r <- es[order(event_time)][i]
    stars <- ""
    if (!is.na(r$pvalue)) {
      if (r$pvalue < 0.01) stars <- "***"
      else if (r$pvalue < 0.05) stars <- "**"
      else if (r$pvalue < 0.10) stars <- "*"
    }
    cat(sprintf("$t %+d$ & %.3f%s & (%.3f) \\\\\n",
                r$event_time, r$estimate, stars, r$se))
  }
  cat("\\midrule\n")
  if (nrow(pre) > 0) {
    f_stat <- sum(pre$estimate^2 / pre$se^2) / nrow(pre)
    cat(sprintf("Joint $F$-test (pre) & \\multicolumn{2}{c}{$F = %.2f$} \\\\\n", f_stat))
  }
  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{0.8\\textwidth}\n")
  cat("\\footnotesize\n")
  cat("\\emph{Notes:} Event-study coefficients from TWFE estimation. Reference period is $t = -1$. Stars: *** $p<0.01$, ** $p<0.05$, * $p<0.10$.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
  cat("  Saved tab3_pretrend.tex\n")
}

cat("All tables generated.\n")
