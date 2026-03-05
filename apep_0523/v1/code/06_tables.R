## 06_tables.R — Generate all tables
## TLV Vacancy Tax Expansion — apep_0523

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
cat("=== Table 1: Summary Statistics ===\n")

panel <- fread(file.path(data_dir, "balanced_panel.csv"))
pre_data <- panel[year_q < 2024 & group %in% c("newly_treated_2023", "never_treated", "always_treated")]

# Compute stats by group
stats_fn <- function(dt, grp) {
  dt[group == grp, .(
    `N Communes` = uniqueN(codgeo),
    `Mean Trans/Q` = sprintf("%.2f", mean(n_transactions, na.rm = TRUE)),
    `Med. Price/m2` = sprintf("%.0f", median(median_prix_m2, na.rm = TRUE)),
    `Med. Total Price` = sprintf("%.0f", median(median_price, na.rm = TRUE)),
    `Mean Surface (m2)` = sprintf("%.1f", mean(mean_surface, na.rm = TRUE)),
    `Pct. Apartments` = sprintf("%.1f%%", 100 * mean(pct_apartment, na.rm = TRUE))
  )]
}

t1_newly <- stats_fn(pre_data, "newly_treated_2023")
t1_never <- stats_fn(pre_data, "never_treated")
t1_always <- stats_fn(pre_data, "always_treated")

t1 <- rbind(
  cbind(Group = "Newly Treated (2023)", t1_newly),
  cbind(Group = "Never Treated", t1_never),
  cbind(Group = "Always Treated (2013)", t1_always)
)

fwrite(t1, file.path(tab_dir, "table1_summary.csv"))
cat("Table 1 saved.\n")

# LaTeX table
t1_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Period (2020Q1--2023Q2)}\n",
  "\\label{tab:summary}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  " & N Communes & Mean Trans/Q & Med. Price/m\\textsuperscript{2} (\\euro{}) & Med. Total Price (\\euro{}) & Mean Surface (m\\textsuperscript{2}) & Pct. Apartments \\\\\n",
  "\\hline\n"
)
for (i in seq_len(nrow(t1))) {
  row <- t1[i, ]
  t1_tex <- paste0(t1_tex, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
                                    row$Group, row$`N Communes`, row$`Mean Trans/Q`,
                                    row$`Med. Price/m2`, row$`Med. Total Price`,
                                    row$`Mean Surface (m2)`, row$`Pct. Apartments`))
}
t1_tex <- paste0(t1_tex, "\\hline\\hline\n\\end{tabular}\n\\end{adjustbox}\n",
                 "\\begin{minipage}{0.95\\textwidth}\n\\footnotesize\n",
                 "\\textit{Notes:} This table reports pre-treatment summary statistics for ",
                 "commune-quarter observations in the balanced panel. ``Newly Treated'' communes ",
                 "were added to the TLV zone by D\\'{e}cret n\\degree 2023-822 of August 25, 2023. ",
                 "``Always Treated'' communes have been subject to TLV since D\\'{e}cret n\\degree 2013-392. ",
                 "``Never Treated'' communes remain outside TLV zones. Trans/Q = average number of ",
                 "residential property transactions per commune-quarter.\n",
                 "\\end{minipage}\n\\end{table}\n")

writeLines(t1_tex, file.path(tab_dir, "table1_summary.tex"))

# ===========================================================================
# Table 2: Main DiD Results
# ===========================================================================
cat("\n=== Table 2: Main DiD Results ===\n")

did_sum <- fread(file.path(data_dir, "did_summary.csv"))
fwrite(did_sum, file.path(tab_dir, "table2_did.csv"))

# Generate LaTeX using fixest etable
results <- readRDS(file.path(data_dir, "main_results.rds"))

etable(results$m1_vol, results$m2_vol, results$m1_price, results$m2_price,
       results$m1_totprice,
       headers = c("Volume", "Volume", "Price/m2", "Price/m2", "Total Price"),
       dict = c(treat_post = "TLV $\\times$ Post"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       file = file.path(tab_dir, "table2_did.tex"),
       replace = TRUE,
       label = "tab:did_main",
       title = "Effect of TLV Expansion on Transaction Volume and Prices")

cat("Table 2 saved.\n")

# ===========================================================================
# Table 3: Robustness
# ===========================================================================
cat("\n=== Table 3: Robustness ===\n")

rob_sum <- fread(file.path(data_dir, "robustness_summary.csv"))
rob_sum[, stars := fcase(pval < 0.01, "***", pval < 0.05, "**", pval < 0.10, "*", default = "")]
rob_sum[, coef_display := sprintf("%.4f%s", coef, stars)]
rob_sum[, se_display := sprintf("(%.4f)", se)]

fwrite(rob_sum, file.path(tab_dir, "table3_robustness.csv"))

# LaTeX robustness table
t3_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcc}\n\\hline\\hline\n",
  "Specification & Coefficient & Std. Error \\\\\n",
  "\\hline\n"
)
for (i in seq_len(nrow(rob_sum))) {
  row <- rob_sum[i, ]
  t3_tex <- paste0(t3_tex, sprintf("%s & %s & %s \\\\\n",
                                    row$test, row$coef_display, row$se_display))
}
t3_tex <- paste0(t3_tex, "\\hline\\hline\n\\end{tabular}\n\\end{adjustbox}\n",
                 "\\begin{minipage}{0.95\\textwidth}\n\\footnotesize\n",
                 "\\textit{Notes:} All models include commune and quarter fixed effects. ",
                 "Standard errors clustered at the commune level unless otherwise noted. ",
                 "*** p$<$0.01, ** p$<$0.05, * p$<$0.10.\n",
                 "\\end{minipage}\n\\end{table}\n")

writeLines(t3_tex, file.path(tab_dir, "table3_robustness.tex"))

# ===========================================================================
# Table 4: Composition Effects
# ===========================================================================
cat("\n=== Table 4: Composition ===\n")

etable(results$m_apt, results$m_surf, results$m_rooms,
       headers = c("Apt. Share", "Avg. Surface", "Avg. Rooms"),
       dict = c(treat_post = "TLV $\\times$ Post"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       file = file.path(tab_dir, "table4_composition.tex"),
       replace = TRUE,
       label = "tab:composition",
       title = "Composition Effects: Property Characteristics")

cat("Table 4 saved.\n")

cat("\nAll tables generated.\n")
