# ============================================================
# 05b_event_study_table.R — Event-study coefficient table
# apep_0753: The Hunger Cliff and the Corner Store
# ============================================================

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"

cs_es <- readRDS(file.path(data_dir, "cs_es_results.rds"))

# Extract event-study coefficients
es_df <- data.frame(
  event_time = cs_es$egt,
  estimate = cs_es$att.egt,
  se = cs_es$se.egt,
  stringsAsFactors = FALSE
)

es_df$ci_lo <- es_df$estimate - 1.96 * es_df$se
es_df$ci_hi <- es_df$estimate + 1.96 * es_df$se
es_df$pval <- 2 * pnorm(-abs(es_df$estimate / es_df$se))

# Stars
es_df$stars <- ifelse(es_df$pval < 0.01, "***",
               ifelse(es_df$pval < 0.05, "**",
               ifelse(es_df$pval < 0.10, "*", "")))

# Build LaTeX table
tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event-Study Estimates: Convenience Store Exit Rates}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{rcccc}",
  "\\toprule",
  "Event time & Estimate & SE & 95\\% CI & \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_df))) {
  row <- es_df[i, ]
  ci_str <- paste0("[", formatC(row$ci_lo, digits = 2, format = "f"), ", ",
                   formatC(row$ci_hi, digits = 2, format = "f"), "]")
  tab5_lines <- c(tab5_lines,
    paste0(ifelse(row$event_time >= 0, paste0("+", row$event_time), row$event_time),
           " & ", formatC(row$estimate, digits = 3, format = "f"), row$stars,
           " & (", formatC(row$se, digits = 3, format = "f"), ")",
           " & ", ci_str,
           " \\\\")
  )
  # Add separator between pre and post
  if (row$event_time == -1) {
    tab5_lines <- c(tab5_lines, "\\midrule")
  }
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic ATT estimates for convenience store",
  "exit rates (per 1,000 active stores). Event time 0 is the first quarter after EA expiration.",
  "Pre-treatment periods ($< 0$) test the parallel trends assumption.",
  "Standard errors in parentheses; 95\\% confidence intervals in brackets.",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(table_dir, "tab5_eventstudy.tex"))
cat("Written tab5_eventstudy.tex\n")

# Also compute MDE for reporting in text
pre_sd <- 14.93  # pre-treatment SD of exit rate
n_states <- 51
n_quarters <- 24
n_treated <- 18  # early opt-outs (staggered variation)
se_approx <- 3.04  # observed SE from CS

# MDE at 80% power, alpha = 0.05
# MDE = (z_alpha/2 + z_beta) * SE = (1.96 + 0.84) * SE
mde <- (1.96 + 0.84) * se_approx
cat("MDE at 80% power:", round(mde, 1), "per 1,000\n")
cat("MDE as % of pre-treatment mean:", round(mde / 28.47 * 100, 1), "%\n")
cat("MDE as fraction of pre-treatment SD:", round(mde / pre_sd, 2), "\n")
