# =============================================================================
# 05_tables.R — Generate paper tables
# apep_1243: Municipal Consolidation and Residential Sorting in Switzerland
# =============================================================================

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
att <- fread(file.path(DATA_DIR, "att_summary.csv"))
robust <- fread(file.path(DATA_DIR, "robustness_summary.csv"))
comparison <- fread(file.path(DATA_DIR, "comparison_outcomes.csv"))
hetero <- fread(file.path(DATA_DIR, "heterogeneity_summary.csv"))
es <- fread(file.path(DATA_DIR, "event_study.csv"))

fmt <- function(x, digits = 3) sprintf(paste0("%.", digits, "f"), x)
star <- function(est, se) {
  p <- 2 * pnorm(-abs(est / se))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}
classify_sde <- function(x) {
  if (is.na(x)) return("")
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x <= 0.005) return("Null")
  if (x <= 0.05) return("Small positive")
  if (x <= 0.15) return("Moderate positive")
  "Large positive"
}

# ---------------------------------------------------------------------------
# Table 1: Summary statistics
# ---------------------------------------------------------------------------
pre <- panel[year <= 2014]
sum_dt <- rbindlist(list(
  pre[, .(
    group = "Treated",
    mean_foreign_share = mean(foreign_share[ever_merged == TRUE], na.rm = TRUE),
    mean_log_foreign = mean(log_foreign[ever_merged == TRUE], na.rm = TRUE),
    mean_foreign_growth = mean(foreign_growth[ever_merged == TRUE], na.rm = TRUE),
    mean_total_growth = mean(total_growth[ever_merged == TRUE], na.rm = TRUE),
    municipalities = uniqueN(current_bfs[ever_merged == TRUE])
  )],
  pre[, .(
    group = "Control",
    mean_foreign_share = mean(foreign_share[ever_merged == FALSE], na.rm = TRUE),
    mean_log_foreign = mean(log_foreign[ever_merged == FALSE], na.rm = TRUE),
    mean_foreign_growth = mean(foreign_growth[ever_merged == FALSE], na.rm = TRUE),
    mean_total_growth = mean(total_growth[ever_merged == FALSE], na.rm = TRUE),
    municipalities = uniqueN(current_bfs[ever_merged == FALSE])
  )]
))

tab1 <- c(
  "\\begin{table}[htbp]\\centering",
  "\\caption{Pre-Merger Summary Statistics (2010--2014)}",
  "\\begin{adjustbox}{max width=0.95\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Foreign share & Log foreign pop. & Foreign growth (\\%) & Total growth (\\%) & Municipalities \\\\",
  "\\midrule",
  sprintf(
    "Treated & %s & %s & %s & %s & %d \\\\",
    fmt(sum_dt[group == "Treated", mean_foreign_share]),
    fmt(sum_dt[group == "Treated", mean_log_foreign]),
    fmt(sum_dt[group == "Treated", mean_foreign_growth]),
    fmt(sum_dt[group == "Treated", mean_total_growth]),
    sum_dt[group == "Treated", municipalities]
  ),
  sprintf(
    "Control & %s & %s & %s & %s & %d \\\\",
    fmt(sum_dt[group == "Control", mean_foreign_share]),
    fmt(sum_dt[group == "Control", mean_log_foreign]),
    fmt(sum_dt[group == "Control", mean_foreign_growth]),
    fmt(sum_dt[group == "Control", mean_total_growth]),
    sum_dt[group == "Control", municipalities]
  ),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\parbox{0.95\\textwidth}{\\footnotesize \\textit{Notes:} Summary statistics use the 2010--2014 pre-merger window. Treated municipalities are current-boundary successor communes that first merge between 2015 and 2020. Control municipalities never merge during the sample. Foreign growth and total growth are year-over-year percentage changes.}",
  "\\end{table}"
)
writeLines(tab1, file.path(TABLE_DIR, "tab1_summary.tex"))

# ---------------------------------------------------------------------------
# Table 2: Main results
# ---------------------------------------------------------------------------
main_order <- c("foreign_share", "log_foreign", "foreign_growth", "foreign_share_change")
main_labels <- c(
  foreign_share = "Foreign share",
  log_foreign = "Log foreign pop.",
  foreign_growth = "Foreign growth (\\%)",
  foreign_share_change = "$\\Delta$ foreign share"
)

main_lines <- c(
  "\\begin{table}[htbp]\\centering",
  "\\caption{Municipal Mergers and Foreign Residential Composition}",
  "\\begin{adjustbox}{max width=0.95\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Foreign share & Log foreign pop. & Foreign growth (\\%) & $\\Delta$ foreign share \\\\",
  "\\midrule"
)
row_est <- "Sun-Abraham ATT"
row_se <- " "
for (out in main_order) {
  sub <- att[outcome == out & model == "SUNAB_ATT"]
  row_est <- paste0(row_est, " & ", fmt(sub$estimate), star(sub$estimate, sub$se))
  row_se <- paste0(row_se, " & (", fmt(sub$se), ")")
}
main_lines <- c(main_lines, paste0(row_est, " \\\\"), paste0(row_se, " \\\\"))

row_est <- "TWFE"
row_se <- " "
for (out in main_order) {
  sub <- att[outcome == out & model == "TWFE"]
  row_est <- paste0(row_est, " & ", fmt(sub$estimate), star(sub$estimate, sub$se))
  row_se <- paste0(row_se, " & (", fmt(sub$se), ")")
}
main_lines <- c(main_lines, paste0(row_est, " \\\\"), paste0(row_se, " \\\\"))

main_lines <- c(
  main_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\parbox{0.95\\textwidth}{\\footnotesize \\textit{Notes:} Each column reports the post-merger effect of municipal consolidation on a foreign-population outcome. The preferred estimate is the aggregated Sun-Abraham ATT with municipality and year fixed effects. TWFE is shown for comparison. Standard errors are clustered at the municipality level. Treated municipalities are those first merging between 2015 and 2020; never-merged municipalities are the control group. $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.}",
  "\\end{table}"
)
writeLines(main_lines, file.path(TABLE_DIR, "tab2_main.tex"))

# ---------------------------------------------------------------------------
# Table 3: Robustness
# ---------------------------------------------------------------------------
tab3 <- c(
  "\\begin{table}[htbp]\\centering",
  "\\caption{Robustness for Foreign Population Share}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Estimate & SE & N \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(robust))) {
  spec_label <- gsub("%", "\\\\%", robust$spec[i], fixed = TRUE)
  tab3 <- c(
    tab3,
    sprintf(
      "%s & %s%s & (%s) & %d \\\\",
      spec_label,
      fmt(robust$estimate[i]),
      star(robust$estimate[i], robust$se[i]),
      fmt(robust$se[i]),
      robust$n[i]
    )
  )
}
tab3 <- c(
  tab3,
  "\\bottomrule",
  "\\end{tabular}",
  "\\parbox{0.95\\textwidth}{\\footnotesize \\textit{Notes:} The dependent variable is the foreign population share. Column 2 absorbs canton-specific shocks with canton-by-year fixed effects. Column 3 weights observations by baseline 2014 population. Column 4 drops the largest 1\\% of municipalities by baseline size. The point estimates remain economically small across all specifications.}",
  "\\end{table}"
)
writeLines(tab3, file.path(TABLE_DIR, "tab3_robustness.tex"))

# ---------------------------------------------------------------------------
# Table 4: Comparison outcomes
# ---------------------------------------------------------------------------
tab4 <- c(
  "\\begin{table}[htbp]\\centering",
  "\\caption{Comparison Outcomes}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Outcome & Estimate & SE & N \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(comparison))) {
  tab4 <- c(
    tab4,
    sprintf(
      "%s & %s%s & (%s) & %d \\\\",
      comparison$outcome[i],
      fmt(comparison$estimate[i]),
      star(comparison$estimate[i], comparison$se[i]),
      fmt(comparison$se[i]),
      comparison$n[i]
    )
  )
}
tab4 <- c(
  tab4,
  "\\midrule",
  sprintf(
    "High baseline foreign share & %s & (%s) & %d \\\\",
    fmt(hetero$estimate[1]), fmt(hetero$se[1]), hetero$n[1]
  ),
  sprintf(
    "Low baseline foreign share & %s & (%s) & %d \\\\",
    fmt(hetero$estimate[2]), fmt(hetero$se[2]), hetero$n[2]
  ),
  "\\bottomrule",
  "\\end{tabular}",
  "\\parbox{0.95\\textwidth}{\\footnotesize \\textit{Notes:} The upper panel reports TWFE estimates for additional demographic outcomes. The lower panel splits the foreign-share specification by whether the municipality's 2014 foreign share was above or below the sample median. None of the comparison or subgroup estimates indicate large post-merger re-sorting effects.}",
  "\\end{table}"
)
writeLines(tab4, file.path(TABLE_DIR, "tab4_comparison.tex"))

# ---------------------------------------------------------------------------
# Table 5: Event study
# ---------------------------------------------------------------------------
es_fs <- es[outcome == "foreign_share" & rel_year >= -5 & rel_year <= 5]
tab5 <- c(
  "\\begin{table}[htbp]\\centering",
  "\\caption{Event Study: Foreign Population Share}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Relative year & Estimate & SE \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(es_fs))) {
  tab5 <- c(
    tab5,
    sprintf(
      "%d & %s%s & (%s) \\\\",
      es_fs$rel_year[i],
      fmt(es_fs$estimate[i]),
      star(es_fs$estimate[i], es_fs$se[i]),
      fmt(es_fs$se[i])
    )
  )
}
tab5 <- c(
  tab5,
  "\\bottomrule",
  "\\end{tabular}",
  "\\parbox{0.95\\textwidth}{\\footnotesize \\textit{Notes:} Coefficients come from a Sun-Abraham event-study specification with municipality and year fixed effects. Relative year $-1$ is omitted. Pre-treatment coefficients are small, and post-treatment coefficients remain close to zero. $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.}",
  "\\end{table}"
)
writeLines(tab5, file.path(TABLE_DIR, "tab5_eventstudy.tex"))

# ---------------------------------------------------------------------------
# SDE appendix
# ---------------------------------------------------------------------------
pre <- panel[year <= 2014]
panel[, high_foreign := baseline_foreign_share >= median(baseline_foreign_share, na.rm = TRUE)]
pre[, high_foreign := baseline_foreign_share >= median(baseline_foreign_share, na.rm = TRUE)]

sde_rows <- data.table(
  panel = c("A", "A", "A", "B", "B"),
  Outcome = c(
    "Foreign population share",
    "Log foreign population",
    "Foreign population growth",
    "Foreign share, high baseline foreign share",
    "Foreign share, low baseline foreign share"
  ),
  beta = c(
    att[outcome == "foreign_share" & model == "SUNAB_ATT", estimate],
    att[outcome == "log_foreign" & model == "SUNAB_ATT", estimate],
    att[outcome == "foreign_growth" & model == "SUNAB_ATT", estimate],
    hetero$estimate[1],
    hetero$estimate[2]
  ),
  se = c(
    att[outcome == "foreign_share" & model == "SUNAB_ATT", se],
    att[outcome == "log_foreign" & model == "SUNAB_ATT", se],
    att[outcome == "foreign_growth" & model == "SUNAB_ATT", se],
    hetero$se[1],
    hetero$se[2]
  ),
  sd_y = c(
    sd(pre$foreign_share, na.rm = TRUE),
    sd(pre$log_foreign, na.rm = TRUE),
    sd(pre$foreign_growth, na.rm = TRUE),
    sd(pre[high_foreign == TRUE, foreign_share], na.rm = TRUE),
    sd(pre[high_foreign == FALSE, foreign_share], na.rm = TRUE)
  )
)
sde_rows[, SDE := beta / sd_y]
sde_rows[, se_sde := se / sd_y]
sde_rows[, Classification := vapply(SDE, classify_sde, character(1))]

notes <- paste0(
  "\\parbox{0.95\\textwidth}{\\footnotesize \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Do voluntary municipal mergers change foreign residential composition in Swiss municipalities? ",
  "\\textbf{Policy mechanism:} Mergers replace multiple local jurisdictions with a single successor municipality, potentially altering tax-service bundles and local identity without directly targeting immigration policy. ",
  "\\textbf{Outcome definition:} Municipal foreign population share, log foreign population, and annual foreign population growth derived from BFS population-by-citizenship statistics. ",
  "\\textbf{Treatment:} Binary; indicator for years after the municipality's first merger between 2015 and 2020. ",
  "\\textbf{Data:} BFS AGVCH merger registry and BFS PXWeb population by citizenship table, 2010--2024, harmonized to current boundaries, N = ",
  format(nrow(panel), big.mark = ","),
  " municipality-year observations across ",
  uniqueN(panel$current_bfs),
  " municipalities. ",
  "\\textbf{Method:} Difference-in-differences with municipality and year fixed effects; pooled rows use the preferred Sun-Abraham ATT, heterogeneous rows use split-sample TWFE. ",
  "\\textbf{Sample:} Municipalities first merging between 2015 and 2020 and never-merged controls; heterogeneity splits municipalities at the median 2014 foreign share. ",
  "SDE $= \\hat{\\beta} / \\mathrm{SD}(Y)$ where $\\mathrm{SD}(Y)$ is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: Large ($|\\mathrm{SDE}| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).",
  "}"
)

sde_lines <- c(
  "\\begin{table}[htbp]\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\begin{adjustbox}{max width=0.95\\textwidth}",
  "\\begin{tabular}{lrrrrrr}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD$(Y)$ & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)
for (i in which(sde_rows$panel == "A")) {
  sde_lines <- c(
    sde_lines,
    sprintf(
      "%s & %s & %s & %s & %s & %s & %s \\\\",
      sde_rows$Outcome[i],
      fmt(sde_rows$beta[i]),
      fmt(sde_rows$se[i]),
      fmt(sde_rows$sd_y[i]),
      fmt(sde_rows$SDE[i]),
      fmt(sde_rows$se_sde[i]),
      sde_rows$Classification[i]
    )
  )
}
sde_lines <- c(sde_lines, "\\midrule", "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\")
for (i in which(sde_rows$panel == "B")) {
  sde_lines <- c(
    sde_lines,
    sprintf(
      "%s & %s & %s & %s & %s & %s & %s \\\\",
      sde_rows$Outcome[i],
      fmt(sde_rows$beta[i]),
      fmt(sde_rows$se[i]),
      fmt(sde_rows$sd_y[i]),
      fmt(sde_rows$SDE[i]),
      fmt(sde_rows$se_sde[i]),
      sde_rows$Classification[i]
    )
  )
}
sde_lines <- c(
  sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  notes,
  "\\end{table}"
)
writeLines(sde_lines, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat("Tables generated.\n")
