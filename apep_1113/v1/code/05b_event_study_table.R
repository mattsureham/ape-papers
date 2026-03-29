source("00_packages.R")
results <- readRDS("../data/main_results.rds")

# Extract event study coefficients for URM share
es <- results$es_urm
ct <- coeftable(es)

sink("../tables/tab5_event_study.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Event Study: URM Enrollment Share by Year Relative to SFFA}\n")
cat("\\label{tab:eventstudy}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Year Relative to SFFA & Coefficient & SE & $p$-value \\\\\n")
cat("\\midrule\n")

# Get row names and values
rnames <- rownames(ct)
for (i in seq_len(nrow(ct))) {
  # Parse rel_year from name like "rel_year::-6:intensity"
  yr <- gsub("rel_year::|:intensity", "", rnames[i])
  b <- ct[i, "Estimate"]
  s <- ct[i, "Std. Error"]
  p <- ct[i, "Pr(>|t|)"]
  star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  cat(sprintf("$t%s$ & %.3f%s & (%.3f) & %.3f \\\\\n", yr, b, star, s, p))
}

cat("\\midrule\n")
cat("$t-1$ (reference) & --- & --- & --- \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Each row reports the coefficient on the interaction of treatment intensity (1 $-$ pre-SFFA admission rate) with a year indicator, from a single regression with institution and year fixed effects. Reference year: 2022 ($t-1$). Year $t=0$ is the SFFA decision year (2023); $t+1$ is Fall 2024 (first full post-SFFA cohort). Standard errors clustered at the state level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("Event study table generated.\n")
