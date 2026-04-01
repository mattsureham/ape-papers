## 05b_event_study_table.R — Event study appendix table
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
load(file.path(data_dir, "robustness_results.RData"))

# Extract binned event study coefficients
es_roa_coefs <- coef(es_binned_roa)
es_roa_ses <- se(es_binned_roa)
es_roa_pvals <- pvalue(es_binned_roa)

es_roe_coefs <- coef(es_binned_roe)
es_roe_ses <- se(es_binned_roe)
es_roe_pvals <- pvalue(es_binned_roe)

# Extract event half labels
labels <- names(es_roa_coefs)
halves <- as.integer(gsub("event_half::(-?\\d+):treated", "\\1", labels))

# Map half indices to period labels
period_labels <- c(
  "-6" = "$\\leq -30$m",
  "-5" = "$-30$ to $-24$m",
  "-4" = "$-24$ to $-18$m",
  "-3" = "$-18$ to $-12$m",
  "-2" = "$-12$ to $-6$m",
  "0"  = "$0$ to $5$m",
  "1"  = "$6$ to $11$m",
  "2"  = "$12$ to $17$m",
  "3"  = "$18$ to $23$m",
  "4"  = "$24$ to $29$m",
  "5"  = "$30$ to $35$m",
  "6"  = "$36$ to $41$m",
  "7"  = "$42$ to $47$m",
  "8"  = "$48$ to $53$m",
  "9"  = "$54$ to $59$m",
  "10" = "$60$ to $65$m",
  "11" = "$\\geq 66$m"
)

star <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

tab_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Semi-Annual Binned Event Study: ROA and ROE}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{ROA} & \\multicolumn{2}{c}{ROE} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Period & Coef. & SE & Coef. & SE \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Pre-treatment}} \\\\"
)

for (i in seq_along(halves)) {
  h <- halves[i]
  label <- period_labels[as.character(h)]
  if (is.na(label)) next

  roa_c <- sprintf("%.4f%s", es_roa_coefs[i], star(es_roa_pvals[i]))
  roa_s <- sprintf("(%.4f)", es_roa_ses[i])
  roe_c <- sprintf("%.4f%s", es_roe_coefs[i], star(es_roe_pvals[i]))
  roe_s <- sprintf("(%.4f)", es_roe_ses[i])

  if (h == 0) {
    tab_lines <- c(tab_lines,
      "\\midrule",
      "\\multicolumn{5}{l}{\\textit{Post-treatment (grey-listing)}} \\\\"
    )
  }
  if (h == 9) {
    tab_lines <- c(tab_lines,
      "\\midrule",
      "\\multicolumn{5}{l}{\\textit{Post-delisting}} \\\\"
    )
  }

  tab_lines <- c(tab_lines,
    sprintf("%s & %s & %s & %s & %s \\\\", label, roa_c, roa_s, roe_c, roe_s)
  )
}

tab_lines <- c(tab_lines,
  "\\midrule",
  "Reference period & \\multicolumn{4}{c}{$-6$ to $-1$ months} \\\\",
  "Bank-type FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Month FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Observations & \\multicolumn{4}{c}{244} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports coefficients from a semi-annual binned event study specification, where the interaction of International License bank type with each six-month bin is estimated relative to the last pre-treatment bin ($-6$ to $-1$ months before grey-listing). Driscoll-Kraay standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab_lines, file.path(tables_dir, "tab5_eventstudy.tex"))
cat("Event study table written.\n")
