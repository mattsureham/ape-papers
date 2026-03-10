## 06_tables.R — All table generation
## APEP Paper apep_0584: Oregon Drug Decriminalization Symmetric Test

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Table 1: Summary Statistics\n")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]

# Compute for Oregon vs. Other States, by phase
make_sumstats <- function(dt, label) {
  dt[, .(
    group = label,
    n_months = .N,
    mean_od_rate = round(mean(od_rate, na.rm = TRUE), 2),
    sd_od_rate = round(sd(od_rate, na.rm = TRUE), 2),
    mean_fent_rate = round(mean(fent_rate, na.rm = TRUE), 2),
    sd_fent_rate = round(sd(fent_rate, na.rm = TRUE), 2),
    mean_heroin_rate = round(mean(heroin_rate, na.rm = TRUE), 2),
    sd_heroin_rate = round(sd(heroin_rate, na.rm = TRUE), 2),
    mean_psycho_rate = round(mean(psycho_rate, na.rm = TRUE), 2),
    sd_psycho_rate = round(sd(psycho_rate, na.rm = TRUE), 2),
    mean_fent_share = round(mean(fent_share, na.rm = TRUE), 3),
    sd_fent_share = round(sd(fent_share, na.rm = TRUE), 3)
  )]
}

# Overall stats
ss_or <- make_sumstats(panel[oregon == 1], "Oregon")
ss_other <- make_sumstats(panel[oregon == 0], "Other States")

# By phase - Oregon
ss_or_pre <- make_sumstats(panel[oregon == 1 & phase == "pre"], "Oregon: Pre-M110")
ss_or_dec <- make_sumstats(panel[oregon == 1 & phase == "decriminalized"], "Oregon: Decriminalized")
ss_or_rec <- make_sumstats(panel[oregon == 1 & phase == "recriminalized"], "Oregon: Recriminalized")

# By phase - Others
ss_oth_pre <- make_sumstats(panel[oregon == 0 & phase == "pre"], "Others: Pre-M110")
ss_oth_dec <- make_sumstats(panel[oregon == 0 & phase == "decriminalized"], "Others: Decriminalized Era")
ss_oth_rec <- make_sumstats(panel[oregon == 0 & phase == "recriminalized"], "Others: Recriminalized Era")

sumstats_table <- rbindlist(list(ss_or, ss_other, ss_or_pre, ss_or_dec, ss_or_rec,
                                 ss_oth_pre, ss_oth_dec, ss_oth_rec))
fwrite(sumstats_table, file.path(tab_dir, "table1_summary_stats.csv"))

# LaTeX version
sink(file.path(tab_dir, "table1_summary_stats.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Summary Statistics: Drug Overdose Death Rates by Phase}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccccc}\n\\toprule\n")
cat(" & \\multicolumn{2}{c}{Total OD Rate} & \\multicolumn{2}{c}{Fentanyl Rate} & ")
cat("\\multicolumn{2}{c}{Heroin Rate} & \\multicolumn{2}{c}{Fent. Share} \\\\\n")
cat("\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\\cmidrule(lr){6-7}\\cmidrule(lr){8-9}\n")
cat(" & Mean & SD & Mean & SD & Mean & SD & Mean & SD \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(sumstats_table)) {
  r <- sumstats_table[i]
  # Use 2 decimal places for SD columns (avoids misleading 0.0 display)
  cat(sprintf("%s & %.1f & %.2f & %.1f & %.2f & %.1f & %.2f & %.3f & %.3f \\\\\n",
              r$group, r$mean_od_rate, r$sd_od_rate,
              r$mean_fent_rate, r$sd_fent_rate,
              r$mean_heroin_rate, r$sd_heroin_rate,
              r$mean_fent_share, r$sd_fent_share))
  if (i == 2) cat("\\midrule\n")
}

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} All rates are 12-month-ending counts per 100,000 population. ")
cat("``Pre-M110'' is January 2015--January 2021. ``Decriminalized'' is February 2021--August 2024. ")
cat("``Recriminalized'' is September 2024 onward. Fentanyl Share is the ratio of synthetic opioid ")
cat("deaths to total overdose deaths. ``Other States'' includes 49 states plus DC. ")
cat("Source: CDC VSRR Provisional Drug Overdose Death Counts; Census Bureau population estimates.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n")
cat("\\end{adjustbox}\n\\end{table}\n")
sink()

# ============================================================
# Table 2: Main Results — Augmented SCM
# ============================================================
cat("Table 2: Main results\n")

main_results <- fread(file.path(data_dir, "main_results.csv"))

sink(file.path(tab_dir, "table2_main_results.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Main Results: Augmented Synthetic Control Estimates}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccccc}\n\\toprule\n")
cat("Design & ATT & Std.~Error & $p$-value & RI $p$-value & Pre-periods \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(main_results)) {
  r <- main_results[i]
  stars <- ""
  if (!is.na(r$p_value)) {
    if (r$p_value < 0.01) stars <- "^{***}"
    else if (r$p_value < 0.05) stars <- "^{**}"
    else if (r$p_value < 0.10) stars <- "^{*}"
  }

  ri_str <- ifelse(is.na(r$ri_pvalue), "---",
                   sprintf("%.3f", r$ri_pvalue))

  pre <- c("73", "43", "---")

  cat(sprintf("%s & $%.3f%s$ & (%.3f) & %.3f & %s & %s \\\\\n",
              r$design, r$att, stars, r$se, r$p_value, ri_str, pre[i]))
}

cat("\\midrule\n")

# Symmetric test
sym <- fread(file.path(data_dir, "symmetric_test.csv"))
cat(sprintf("$\\hat{\\tau}_{\\text{sum}}$ & $%.3f$ & (%.3f) & %.3f & --- & --- \\\\\n",
            sym$tau_sum, sym$se_sum, sym$p_value))

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Augmented synthetic control estimates (Ben-Michael et al., 2021) ")
cat("with ridge augmentation. The outcome is the 12-month-ending drug overdose death rate per 100,000. ")
cat("Design 1 estimates the effect of decriminalization (Measure 110, February 2021). ")
cat("Design 2 estimates the effect of recriminalization (HB 4002, September 2024). ")
cat("$\\hat{\\tau}_{\\text{sum}} = \\hat{\\tau}_{\\text{decrim}} + \\hat{\\tau}_{\\text{recrim}}$; ")
cat("under full causal reversal, $\\hat{\\tau}_{\\text{sum}} = 0$. ")
cat("RI $p$-values from permutation inference across all donor states. ")
cat("$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# ============================================================
# Table 3: Drug Decomposition
# ============================================================
cat("Table 3: Drug decomposition\n")

decomp <- fread(file.path(data_dir, "drug_decomposition.csv"))

sink(file.path(tab_dir, "table3_drug_decomposition.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Drug Decomposition: Decriminalization Effect by Drug Category}\n")
cat("\\label{tab:decomp}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n\\toprule\n")
cat("Drug Category & ATT & Pre-RMSPE \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(decomp)) {
  r <- decomp[i]
  if (is.na(r$att)) next
  cat(sprintf("%s & $%.3f$ & %.3f \\\\\n",
              r$drug, r$att, r$se))
}

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Augmented synthetic control estimates for each drug-specific ")
cat("overdose death rate per 100,000 (Design 1: decriminalization, February 2021). ")
cat("Drug categories correspond to ICD-10 T-codes from CDC VSRR data. ")
cat("Pre-RMSPE is the pre-treatment root mean squared prediction error, ")
cat("a measure of synthetic control fit quality. Placebo-based inference is not ")
cat("available for individual drug categories due to convergence issues in drug-specific ")
cat("SCM optimization across the full donor pool.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# ============================================================
# Table 4: Robustness Summary
# ============================================================
cat("Table 4: Robustness\n")

robust <- fread(file.path(data_dir, "robustness_summary.csv"))

sink(file.path(tab_dir, "table4_robustness.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Robustness: Design 1 Under Alternative Specifications}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n\\toprule\n")
cat("Specification & ATT & Std.~Error \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(robust)) {
  r <- robust[i]
  if (is.na(r$att)) next
  cat(sprintf("%s & %.3f & (%.3f) \\\\\n", r$check, r$att, r$se))
}

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Each row reports the average ATT from an alternative augmented ")
cat("synthetic control specification for Design 1 (decriminalization). ``Classic SCM'' uses ")
cat("the Abadie et al.\\ (2010) estimator without ridge augmentation. ``Western states'' restricts ")
cat("the donor pool to WA, CA, NV, ID, AZ, CO, MT, UT, NM, WY. ``Fentanyl-adjusted'' includes ")
cat("synthetic opioid death share as a time-varying covariate. Pre-start rows vary the beginning ")
cat("of the pre-treatment window.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# ============================================================
# Table 5: SCM Weights
# ============================================================
cat("Table 5: SCM weights\n")

weights <- fread(file.path(data_dir, "scm_weights_decrim.csv"))
weights_top <- weights[weight > 0.01][order(-weight)]

sink(file.path(tab_dir, "table5_scm_weights.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Synthetic Control Weights: Design 1 (Top Donors)}\n")
cat("\\label{tab:weights}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lc}\n\\toprule\n")
cat("Donor State & Weight \\\\\n")
cat("\\midrule\n")

for (i in 1:min(nrow(weights_top), 15)) {
  cat(sprintf("%s & %.3f \\\\\n", weights_top$state[i], weights_top$weight[i]))
}

cat("\\midrule\n")
cat(sprintf("Other states (n=%d) & %.3f \\\\\n",
            nrow(weights[weight <= 0.01]),
            sum(weights[weight <= 0.01, weight])))

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Augmented synthetic control weights for Design 1 ")
cat("(decriminalization). Only states with weight $> 0.01$ are shown. ")
cat("Weights are constrained to sum to 1 and be non-negative.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

cat("\n=== ALL TABLES GENERATED ===\n")
cat(sprintf("Saved to: %s/\n", tab_dir))
