# 05_tables.R — Generate all LaTeX tables
# apep_1020/v1

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load results
results_dt <- fread(file.path(data_dir, "bunching_results.csv"))
ctrl_dt <- fread(file.path(data_dir, "robustness_n_controls.csv"))
prop_dt <- fread(file.path(data_dir, "robustness_property_type.csv"))
wales_dt <- fread(file.path(data_dir, "robustness_wales_placebo.csv"))
bw_dt <- fread(file.path(data_dir, "robustness_bin_width.csv"))
ppd_eng <- fread(file.path(data_dir, "ppd_england.csv"))
ppd_eng[, date_transfer := as.Date(date_transfer)]

# ============================================================
# Table 1: Summary Statistics
# ============================================================
ppd_eng[, regime := fcase(
  date_transfer >= as.Date("2023-01-01") & date_transfer <= as.Date("2024-09-30"), "pre",
  date_transfer >= as.Date("2024-10-01") & date_transfer <= as.Date("2025-03-31"), "anticipation",
  date_transfer >= as.Date("2025-05-01"), "post",
  default = NA_character_
)]

summ <- ppd_eng[!is.na(regime), .(
  N = .N,
  Mean_Price = mean(as.numeric(price)),
  Median_Price = as.double(median(as.numeric(price))),
  SD_Price = sd(as.numeric(price)),
  Pct_Detached = 100 * mean(property_type == "D"),
  Pct_Flat = 100 * mean(property_type == "F"),
  Pct_New = 100 * mean(old_new == "Y")
), by = regime]

summ <- summ[order(match(regime, c("pre", "anticipation", "post")))]

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: England Residential Transactions}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Pre-Reversion & Anticipation & Post-Reversion \\\\\n",
  " & (Jan 2023--Sep 2024) & (Oct 2024--Mar 2025) & (May--Dec 2025) \\\\\n",
  "\\hline\n",
  sprintf("Transactions & %s & %s & %s \\\\\n",
    formatC(summ$N[1], format = "d", big.mark = ","),
    formatC(summ$N[2], format = "d", big.mark = ","),
    formatC(summ$N[3], format = "d", big.mark = ",")),
  sprintf("Mean price (\\pounds) & %s & %s & %s \\\\\n",
    formatC(round(summ$Mean_Price[1]), format = "d", big.mark = ","),
    formatC(round(summ$Mean_Price[2]), format = "d", big.mark = ","),
    formatC(round(summ$Mean_Price[3]), format = "d", big.mark = ",")),
  sprintf("Median price (\\pounds) & %s & %s & %s \\\\\n",
    formatC(round(summ$Median_Price[1]), format = "d", big.mark = ","),
    formatC(round(summ$Median_Price[2]), format = "d", big.mark = ","),
    formatC(round(summ$Median_Price[3]), format = "d", big.mark = ",")),
  sprintf("SD price (\\pounds) & %s & %s & %s \\\\\n",
    formatC(round(summ$SD_Price[1]), format = "d", big.mark = ","),
    formatC(round(summ$SD_Price[2]), format = "d", big.mark = ","),
    formatC(round(summ$SD_Price[3]), format = "d", big.mark = ",")),
  sprintf("\\%% Detached & %.1f & %.1f & %.1f \\\\\n",
    summ$Pct_Detached[1], summ$Pct_Detached[2], summ$Pct_Detached[3]),
  sprintf("\\%% Flat & %.1f & %.1f & %.1f \\\\\n",
    summ$Pct_Flat[1], summ$Pct_Flat[2], summ$Pct_Flat[3]),
  sprintf("\\%% New build & %.1f & %.1f & %.1f \\\\\n",
    summ$Pct_New[1], summ$Pct_New[2], summ$Pct_New[3]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} HM Land Registry Price Paid Data, Category A (standard price paid) transactions in England. Pre-reversion period covers the stable SDLT regime under September 2022 Growth Plan thresholds. Anticipation window begins with the October 30, 2024 budget announcement. Post-reversion begins May 2025 (April excluded as transition).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
cat(tab1_tex, file = file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results — Round-Number-Adjusted Bunching Ratios
# ============================================================
tab2_rows <- ""
for (i in 1:nrow(results_dt)) {
  r <- results_dt[i]
  stars <- ""
  if (!is.na(r$dir) && !is.na(r$dir_se) && r$dir_se > 0) {
    tstat <- abs(r$dir / r$dir_se)
    if (tstat > 2.576) stars <- "$^{***}$"
    else if (tstat > 1.96) stars <- "$^{**}$"
    else if (tstat > 1.645) stars <- "$^{*}$"
  }

  tab2_rows <- paste0(tab2_rows,
    sprintf("%s & %d & %d & %.3f & %.3f & %.3f%s \\\\\n",
      r$label, r$pre_kink_pp, r$post_kink_pp,
      r$ratio_pre, r$ratio_post, r$dir, stars),
    sprintf(" & & & & & (%.3f) \\\\\n", r$dir_se)
  )
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Round-Number-Adjusted Bunching at SDLT Thresholds}\n",
  "\\label{tab:main_bunching}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  "Threshold & \\multicolumn{2}{c}{Rate Jump (pp)} & \\multicolumn{3}{c}{Bunching Ratio} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-6}\n",
  " & Pre & Post & $R_{\\text{pre}}$ & $R_{\\text{post}}$ & $\\Delta R$ \\\\\n",
  "\\hline\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Treated thresholds}} \\\\\n",
  tab2_rows,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} The bunching ratio $R$ is the count of transactions in the \\pounds 1,000 bin at the threshold divided by the mean count across six adjacent \\pounds 5,000 round-number control bins. A ratio above 1 indicates excess transactions above the round-number baseline. $\\Delta R = R_{\\text{post}} - R_{\\text{pre}}$ is the difference-in-ratios. Poisson bootstrap standard errors (1,000 replications) in parentheses. $^{***}$ $p < 0.01$; $^{**}$ $p < 0.05$; $^{*}$ $p < 0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
cat(tab2_tex, file = file.path(tables_dir, "tab2_main_bunching.tex"))

# ============================================================
# Table 3: Robustness (control points + bin widths)
# ============================================================
tab3_rows <- "\\multicolumn{5}{l}{\\textit{Panel A: Number of control round numbers (\\pounds 250K)}} \\\\\n"
for (j in 1:nrow(ctrl_dt)) {
  r <- ctrl_dt[j]
  tab3_rows <- paste0(tab3_rows,
    sprintf("%d controls & %.3f & %.3f & %.3f & --- \\\\\n",
      r$n_controls, r$ratio_pre, r$ratio_post, r$dir)
  )
}
tab3_rows <- paste0(tab3_rows,
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Bin width (\\pounds 250K)}} \\\\\n"
)
for (j in 1:nrow(bw_dt)) {
  r <- bw_dt[j]
  tab3_rows <- paste0(tab3_rows,
    sprintf("\\pounds %s bins & %.3f & %.3f & %.3f & --- \\\\\n",
      formatC(r$bin_width, format = "d", big.mark = ","),
      r$ratio_pre, r$ratio_post, r$dir)
  )
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Control Points and Bin Width at \\pounds 250K}\n",
  "\\label{tab:robustness_bw}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Specification & $R_{\\text{pre}}$ & $R_{\\text{post}}$ & $\\Delta R$ & SE \\\\\n",
  "\\hline\n",
  tab3_rows,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A varies the number of adjacent \\pounds 5K round-number bins used as controls (baseline: 6). Panel B varies the bin width for computing transaction counts (baseline: \\pounds 1,000). All specifications show a decline in the bunching ratio at \\pounds 250K after the April 2025 reversion.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
cat(tab3_tex, file = file.path(tables_dir, "tab3_robustness.tex"))

# ============================================================
# Table 4: Placebo (£925K + Wales)
# ============================================================
r925 <- results_dt[threshold == 925000]
stars_925 <- ""
if (!is.na(r925$dir_se) && r925$dir_se > 0 && abs(r925$dir / r925$dir_se) > 1.96) stars_925 <- "$^{**}$"

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Placebo Tests}\n",
  "\\label{tab:placebo}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Test & $R_{\\text{pre}}$ & $R_{\\text{post}}$ & $\\Delta R$ \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Unchanged threshold (England)}} \\\\\n",
  sprintf("\\pounds 925K (5pp$\\rightarrow$5pp) & %.3f & %.3f & %.3f%s \\\\\n",
    r925$ratio_pre, r925$ratio_post, r925$dir, stars_925),
  sprintf(" & & & (%.3f) \\\\\n", r925$dir_se),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Wales geographic placebo}} \\\\\n",
  sprintf("Wales \\pounds 250K (LTT, no SDLT change) & %.3f & %.3f & %.3f \\\\\n",
    wales_dt$ratio_pre[1], wales_dt$ratio_post[1], wales_dt$dir[1]),
  sprintf(" & & & (%.3f) \\\\\n", wales_dt$dir_se[1]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A: the \\pounds 925K threshold where the 5pp rate jump was unchanged by the April 2025 reversion. Panel B: the \\pounds 250K price point in Wales, which uses the Land Transaction Tax (\\pounds 225K nil-rate) unaffected by SDLT. Poisson bootstrap SE in parentheses.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
cat(tab4_tex, file = file.path(tables_dir, "tab4_placebo.tex"))

# ============================================================
# Table 5: Heterogeneity by Property Type at £250K
# ============================================================
tab5_rows <- ""
for (j in 1:nrow(prop_dt)) {
  r <- prop_dt[j]
  stars <- ""
  if (!is.na(r$dir_se) && r$dir_se > 0) {
    tstat <- abs(r$dir / r$dir_se)
    if (tstat > 2.576) stars <- "$^{***}$"
    else if (tstat > 1.96) stars <- "$^{**}$"
    else if (tstat > 1.645) stars <- "$^{*}$"
  }
  tab5_rows <- paste0(tab5_rows,
    sprintf("%s & %.3f & %.3f & %.3f%s \\\\\n",
      r$property_type, r$ratio_pre, r$ratio_post, r$dir, stars),
    sprintf(" & & & (%.3f) \\\\\n", r$dir_se)
  )
}

tab5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Heterogeneity: Bunching at \\pounds 250K by Property Type}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Property Type & $R_{\\text{pre}}$ & $R_{\\text{post}}$ & $\\Delta R$ \\\\\n",
  "\\hline\n",
  tab5_rows,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Round-number-adjusted bunching ratio at \\pounds 250K estimated separately by property type. The SDLT kink at \\pounds 250K shrank from 5pp to 3pp. All property types show negative $\\Delta R$. Semi-detached homes, concentrated at this price point, drive the aggregate result. Poisson bootstrap SE in parentheses. $^{**}$ $p < 0.05$; $^{*}$ $p < 0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
cat(tab5_tex, file = file.path(tables_dir, "tab5_heterogeneity.tex"))

# ============================================================
# Table F1: SDE Appendix
# ============================================================
main_res <- results_dt[threshold != 925000]
sd_dir <- sd(main_res$dir, na.rm = TRUE)

sde_rows_a <- ""
for (j in 1:nrow(main_res)) {
  r <- main_res[j]
  sde_val <- r$dir / sd_dir
  se_sde <- r$dir_se / sd_dir
  classification <- ifelse(abs(sde_val) > 0.15, ifelse(sde_val > 0, "Large positive", "Large negative"),
    ifelse(abs(sde_val) > 0.05, ifelse(sde_val > 0, "Moderate positive", "Moderate negative"),
    ifelse(abs(sde_val) > 0.005, ifelse(sde_val > 0, "Small positive", "Small negative"),
    "Null")))

  sde_rows_a <- paste0(sde_rows_a,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
      r$label, r$dir, r$dir_se, sd_dir, sde_val, se_sde, classification)
  )
}

# Panel B: property type splits
sde_rows_b <- ""
for (j in 1:min(2, nrow(prop_dt))) {
  r <- prop_dt[j]
  sde_val <- r$dir / sd_dir
  se_sde <- r$dir_se / sd_dir
  classification <- ifelse(abs(sde_val) > 0.15, ifelse(sde_val > 0, "Large positive", "Large negative"),
    ifelse(abs(sde_val) > 0.05, ifelse(sde_val > 0, "Moderate positive", "Moderate negative"),
    ifelse(abs(sde_val) > 0.005, ifelse(sde_val > 0, "Small positive", "Small negative"),
    "Null")))

  sde_rows_b <- paste0(sde_rows_b,
    sprintf("\\pounds 250K: %s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
      r$property_type, r$dir, r$dir_se, sd_dir, sde_val, se_sde, classification)
  )
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Does housing transaction price bunching migrate when stamp duty thresholds move, and is the behavioral response proportional to the change in marginal rate? ",
  "\\textbf{Policy mechanism:} The April 2025 SDLT reversion simultaneously shifted four kink points in England's marginal stamp duty schedule, creating new bunching incentives at lower price thresholds while attenuating incentives at higher thresholds; the mechanism operates through the marginal tax rate on the last pound of the transaction price. ",
  "\\textbf{Outcome definition:} Round-number-adjusted bunching ratio ($R$) at each threshold, measuring the transaction count in the \\pounds 1,000 threshold bin divided by the mean count in six adjacent \\pounds 5,000 round-number control bins; $\\Delta R$ is the post-minus-pre change. ",
  "\\textbf{Treatment:} Binary (pre- vs.\\ post-reversion regime); each threshold experienced a different change in marginal rate jump (0 to 5 percentage points). ",
  "\\textbf{Data:} HM Land Registry Price Paid Data, Category A transactions, England, January 2023--December 2025; approximately 1.56 million transactions across pre and post periods. ",
  "\\textbf{Method:} Round-number-adjusted difference-in-ratios estimator; ratio computed as threshold bin count divided by mean of six nearest non-SDLT \\pounds 5K round-number bins; Poisson bootstrap SEs (1,000 replications). ",
  "\\textbf{Sample:} Standard price paid (Category A) residential transactions in England; Wales excluded (different tax system); April 2025 excluded as transition month. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-threshold standard deviation of $\\Delta R$ estimates. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (all thresholds)}} \\\\\n",
  sde_rows_a,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (property type at \\pounds 250K)}} \\\\\n",
  sde_rows_b,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
cat(sde_tex, file = file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
