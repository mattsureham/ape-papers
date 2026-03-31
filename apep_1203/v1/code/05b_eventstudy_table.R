## 05b_eventstudy_table.R — Generate event study table for appendix
source("00_packages.R")

results <- readRDS("../data/main_results.rds")
es <- results$es_model
ct <- coeftable(es)

# Extract quarterly event study coefficients
es_rows <- grep("event_quarter", rownames(ct))
quarters <- as.numeric(gsub(".*::([-0-9]+):.*", "\\1", rownames(ct)[es_rows]))
estimates <- ct[es_rows, "Estimate"]
ses <- ct[es_rows, "Std. Error"]

tab_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: SAS Registrations in CABA vs.\\ Control Provinces}",
  "\\label{tab:es}",
  "\\begin{tabular}{rrrrl}",
  "\\toprule",
  "Quarter & Estimate & SE & 95\\% CI & Period \\\\",
  "\\midrule"
)

for (i in seq_along(quarters)) {
  q <- quarters[i]
  est <- estimates[i]
  se <- ses[i]
  ci_lo <- est - 1.96 * se
  ci_hi <- est + 1.96 * se
  period <- ifelse(q < 0, "Pre-ban",
                   ifelse(q < 48, "Ban",
                          "Post-reactivation"))
  if (q == -3) next  # reference period

  tab_lines <- c(tab_lines, sprintf(
    "%d & %.1f & %.1f & [%.1f, %.1f] & %s \\\\",
    q, est, se, ci_lo, ci_hi, period
  ))
}

tab_lines <- c(tab_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}\\begin{minipage}{\\textwidth}\\footnotesize",
  "\\textit{Notes:} Quarterly event-study coefficients from a regression of monthly SAS registrations on interactions between CABA indicator and quarterly event-time dummies, with province and month fixed effects. Reference period: $q = -3$ (the quarter immediately preceding the March 2020 ban). Standard errors clustered at the province level.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab_lines, "../tables/tabA1_eventstudy.tex")
cat("Wrote tabA1_eventstudy.tex\n")
