## 06_eventstudy_table.R — Generate event study table
source("00_packages.R")
library(fixest)

r <- readRDS("../data/main_results.rds")
sa <- r$sa_es

sa_coefs <- coef(sa)
sa_ses <- sqrt(diag(vcov(sa)))
sa_names <- names(sa_coefs)
event_times <- as.integer(gsub("year::", "", sa_names))

keep <- event_times >= -5 & event_times <= 8
df_t <- event_times[keep]
df_b <- unname(sa_coefs[keep])
df_se <- unname(sa_ses[keep])
ord <- order(df_t)
df_t <- df_t[ord]; df_b <- df_b[ord]; df_se <- df_se[ord]

stars_fn <- function(b, se) {
  z <- abs(b / se)
  if (z > 2.576) return("$^{***}$")
  if (z > 1.960) return("$^{**}$")
  if (z > 1.645) return("$^{*}$")
  return("")
}

lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Sun--Abraham Estimates}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Event Time & Estimate & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (i in seq_along(df_t)) {
  ci_lo <- df_b[i] - 1.96 * df_se[i]
  ci_hi <- df_b[i] + 1.96 * df_se[i]
  sgn <- ifelse(df_t[i] >= 0, "+", "")
  lines <- c(lines,
    sprintf("$t %s %d$ & %s%s & (%.3f) & [%.3f, %.3f] \\\\",
      sgn, df_t[i],
      sprintf("%.3f", df_b[i]), stars_fn(df_b[i], df_se[i]),
      df_se[i], ci_lo, ci_hi))
}

lines <- c(lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  paste0(
    "\\item \\textit{Notes:} Sun and Abraham (2021) interaction-weighted estimator. ",
    "Panel restricted to adoption windows (post-cancellation years excluded). ",
    "Reference period: $t - 1$. Never-treated countries as controls. ",
    "Country-clustered standard errors. ",
    "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."
  ),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(lines, "../tables/tab5_eventstudy.tex")
cat("Event study table written with", length(df_t), "rows.\n")
