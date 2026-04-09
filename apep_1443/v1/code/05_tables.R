## 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

pairs <- fread(file.path(data_dir, "repeat_sale_pairs.csv"))
pairs[, sale_date := as.Date(sale_date)]
pairs[, acq_date := as.Date(acq_date)]
results <- readRDS(file.path(data_dir, "bunching_results.rds"))

# ================================================================
# Table 1: Summary Statistics
# ================================================================
cat("=== Table 1: Summary Statistics ===\n")

tax2 <- pairs[tax_regime == "tax2"]
tax1 <- pairs[tax_regime == "tax1"]
exempt <- pairs[tax_regime == "exempt"]

summary_stats <- function(dt, label) {
  data.table(
    Panel = label,
    N = format(nrow(dt), big.mark = ","),
    `Mean HP (days)` = sprintf("%.0f", mean(dt$holding_days, na.rm = TRUE)),
    `Median HP (days)` = sprintf("%.0f", median(dt$holding_days, na.rm = TRUE)),
    `Mean Price (M NTD)` = sprintf("%.1f", mean(dt$sale_price, na.rm = TRUE) / 1e6),
    `Mean Area (sqm)` = sprintf("%.0f", mean(dt$area, na.rm = TRUE)),
    `Mean Return` = sprintf("%.3f", mean(dt$price_return[is.finite(dt$price_return)], na.rm = TRUE))
  )
}

tab1 <- rbind(
  summary_stats(pairs, "All Repeat Sales"),
  summary_stats(tax2, "Tax 2.0 (Post-Jul 2021)"),
  summary_stats(tax1, "Tax 1.0 (2016--Jun 2021)"),
  summary_stats(exempt, "Exempt (Pre-2016)")
)

# Write LaTeX
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Summary Statistics: Taiwan Repeat-Sale Housing Transactions}\n",
  "\\label{tab:summary}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrrrrr}\n",
  "\\toprule\n",
  " & N & Mean HP & Median HP & Mean Price & Mean Area & Mean \\\\\n",
  " & & (days) & (days) & (M NTD) & (sqm) & Return \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(tab1))) {
  tab1_tex <- paste0(tab1_tex,
    tab1$Panel[i], " & ", tab1$N[i], " & ", tab1$`Mean HP (days)`[i], " & ",
    tab1$`Median HP (days)`[i], " & ", tab1$`Mean Price (M NTD)`[i], " & ",
    tab1$`Mean Area (sqm)`[i], " & ", tab1$`Mean Return`[i], " \\\\\n")
  if (i == 1) tab1_tex <- paste0(tab1_tex, "\\midrule\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} HP = holding period (acquisition to sale). ",
  "Price in millions of New Taiwan Dollars. Return = (sale price $-$ acquisition price) / acquisition price. ",
  "Tax 2.0 applies to properties acquired after July 1, 2021, with notches at 2, 5, and 10 years. ",
  "Tax 1.0 applies to properties acquired January 2016--June 2021, with notches at 1, 2, and 10 years. ",
  "Exempt properties were acquired before January 1, 2016 and are grandfathered from both regimes.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("  Written tab1_summary.tex\n")

# ================================================================
# Table 2: Main Bunching Estimates
# ================================================================
cat("=== Table 2: Bunching Estimates ===\n")

make_row <- function(label, res) {
  if (is.null(res) || is.na(res$b)) {
    return(sprintf("%s & --- & --- & --- & --- \\\\", label))
  }
  stars <- ifelse(abs(res$b / res$se) > 2.576, "***",
           ifelse(abs(res$b / res$se) > 1.96, "**",
           ifelse(abs(res$b / res$se) > 1.645, "*", "")))
  sprintf("%s & %.3f%s & (%.3f) & %s & %s \\\\",
          label, res$b, stars, res$se,
          format(res$excess_mass, big.mark = ","),
          format(res$n_obs, big.mark = ","))
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Bunching Estimates at Holding-Period Tax Notches}\n",
  "\\label{tab:bunching}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Excess Mass ($\\hat{b}$) & SE & Excess Count & N (window) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Tax 2.0 (Post-July 2021 Acquisitions)}} \\\\\n",
  "\\addlinespace\n"
)

if (!is.null(results[["tax2_2yr"]])) {
  tab2_tex <- paste0(tab2_tex, make_row("2-year notch (730 days, 10pp)", results[["tax2_2yr"]]), "\n")
}
if (!is.null(results[["tax2_5yr"]])) {
  tab2_tex <- paste0(tab2_tex, make_row("5-year notch (1,825 days, 15pp)", results[["tax2_5yr"]]), "\n")
}

tab2_tex <- paste0(tab2_tex,
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Tax 1.0 (2016--June 2021 Acquisitions)}} \\\\\n",
  "\\addlinespace\n"
)

if (!is.null(results[["tax1_1yr"]])) {
  tab2_tex <- paste0(tab2_tex, make_row("1-year notch (365 days, 10pp)", results[["tax1_1yr"]]), "\n")
}
if (!is.null(results[["tax1_2yr"]])) {
  tab2_tex <- paste0(tab2_tex, make_row("2-year notch (730 days, 15pp)", results[["tax1_2yr"]]), "\n")
}

tab2_tex <- paste0(tab2_tex,
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo (Exempt Pre-2016 Properties)}} \\\\\n",
  "\\addlinespace\n"
)

if (!is.null(results[["exempt_placebo"]])) {
  tab2_tex <- paste0(tab2_tex, make_row("730 days (no notch)", results[["exempt_placebo"]]), "\n")
}

tab2_tex <- paste0(tab2_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Excess mass $\\hat{b}$ is the ratio of excess transactions just above the notch ",
  "to the average counterfactual bin count, estimated following \\citet{kleven2013}. Counterfactual density ",
  "fitted with a 7th-order polynomial excluding the bunching region. Standard errors from 200 bootstrap ",
  "replications. The notch size (in percentage points) refers to the tax rate reduction when crossing ",
  "the holding-period threshold. *, **, *** denote significance at the 10\\%, 5\\%, and 1\\% levels.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_bunching.tex"))
cat("  Written tab2_bunching.tex\n")

# ================================================================
# Table 3: Robustness — Sensitivity to Estimation Choices
# ================================================================
cat("=== Table 3: Robustness ===\n")

tab3_rows <- ""

# Polynomial order sensitivity
if (!is.null(results[["robust_poly"]])) {
  tab3_rows <- paste0(tab3_rows,
    "\\multicolumn{3}{l}{\\textit{Panel A: Polynomial Order}} \\\\\n\\addlinespace\n")
  for (p in names(results[["robust_poly"]])) {
    r <- results[["robust_poly"]][[p]]
    tab3_rows <- paste0(tab3_rows, sprintf("Order %s & %.3f & (%.3f) \\\\\n", p, r$b, r$se))
  }
}

# Bin width sensitivity
if (!is.null(results[["robust_bin"]])) {
  tab3_rows <- paste0(tab3_rows,
    "\\addlinespace\n\\multicolumn{3}{l}{\\textit{Panel B: Bin Width (days)}} \\\\\n\\addlinespace\n")
  for (bw in names(results[["robust_bin"]])) {
    r <- results[["robust_bin"]][[bw]]
    tab3_rows <- paste0(tab3_rows, sprintf("%s-day bins & %.3f & (%.3f) \\\\\n", bw, r$b, r$se))
  }
}

# Exclusion window sensitivity
if (!is.null(results[["robust_excl"]])) {
  tab3_rows <- paste0(tab3_rows,
    "\\addlinespace\n\\multicolumn{3}{l}{\\textit{Panel C: Exclusion Window (days)}} \\\\\n\\addlinespace\n")
  for (ew in names(results[["robust_excl"]])) {
    r <- results[["robust_excl"]][[ew]]
    tab3_rows <- paste0(tab3_rows, sprintf("$\\pm$%s days & %.3f & (%.3f) \\\\\n", ew, r$b, r$se))
  }
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Robustness of Bunching Estimates at 2-Year Notch (Tax 2.0)}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & $\\hat{b}$ & SE \\\\\n",
  "\\midrule\n",
  tab3_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row re-estimates the bunching parameter at the 2-year (730-day) notch ",
  "under Tax 2.0, varying one estimation choice at a time. Baseline: 7th-order polynomial, 7-day bins, ",
  "$\\pm$60-day exclusion window. Standard errors from 100 bootstrap replications.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_robustness.tex"))
cat("  Written tab3_robustness.tex\n")

# ================================================================
# Table 4: Heterogeneity
# ================================================================
cat("=== Table 4: Heterogeneity ===\n")

tab4_rows <- ""

# Price quartile heterogeneity
if (!is.null(results[["hetero_price"]])) {
  tab4_rows <- paste0(tab4_rows,
    "\\multicolumn{4}{l}{\\textit{Panel A: By Sale Price Quartile}} \\\\\n\\addlinespace\n")
  for (q in names(results[["hetero_price"]])) {
    r <- results[["hetero_price"]][[q]]
    if (!is.null(r) && !is.na(r$b)) {
      tab4_rows <- paste0(tab4_rows,
        sprintf("%s & %.3f & (%.3f) & %s \\\\\n", q, r$b, r$se,
                format(r$n_obs, big.mark = ",")))
    }
  }
}

# Taipei vs rest
tab4_rows <- paste0(tab4_rows,
  "\\addlinespace\n\\multicolumn{4}{l}{\\textit{Panel B: By Location}} \\\\\n\\addlinespace\n")

if (!is.null(results[["taipei"]]) && !is.na(results[["taipei"]]$b)) {
  r <- results[["taipei"]]
  tab4_rows <- paste0(tab4_rows,
    sprintf("Taipei & %.3f & (%.3f) & %s \\\\\n", r$b, r$se, format(r$n_obs, big.mark = ",")))
}
if (!is.null(results[["rest"]]) && !is.na(results[["rest"]]$b)) {
  r <- results[["rest"]]
  tab4_rows <- paste0(tab4_rows,
    sprintf("Other Cities & %.3f & (%.3f) & %s \\\\\n", r$b, r$se, format(r$n_obs, big.mark = ",")))
}

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Heterogeneous Bunching at the 2-Year Notch (Tax 2.0)}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Subsample & $\\hat{b}$ & SE & N (window) \\\\\n",
  "\\midrule\n",
  tab4_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row re-estimates the bunching parameter at the 2-year notch ",
  "on a subsample defined by sale price quartile (Panel A) or location (Panel B). ",
  "Taipei includes all districts within Taipei City. Standard errors from 100 bootstrap replications.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_heterogeneity.tex"))
cat("  Written tab4_heterogeneity.tex\n")

# ================================================================
# Table F1: Standardized Effect Size (SDE) — Appendix
# ================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for bunching estimates
# For bunching, SDE = b_hat (excess mass is already normalized)
# But for comparability, we use SDE = b_hat as the standardized measure

sde_rows <- data.table(
  Outcome = character(),
  beta = numeric(),
  se = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character()
)

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# For bunching: beta = excess count, SD(Y) = SD of bin counts, SDE = b_hat
add_sde_row <- function(label, res) {
  if (is.null(res) || is.na(res$b)) return(NULL)
  # b_hat IS the normalized excess mass — treat as SDE directly
  data.table(
    Outcome = label,
    beta = res$excess_mass,
    se = res$se * res$avg_counterfactual,  # un-normalized SE
    sd_y = res$avg_counterfactual,
    sde = res$b,
    se_sde = res$se,
    classification = classify_sde(res$b)
  )
}

# Panel A: Pooled main estimates
sde_pooled <- rbind(
  add_sde_row("Transaction density at 2-yr notch (Tax 2.0)", results[["tax2_2yr"]]),
  add_sde_row("Transaction density at 5-yr notch (Tax 2.0)", results[["tax2_5yr"]]),
  add_sde_row("Transaction density at 1-yr notch (Tax 1.0)", results[["tax1_1yr"]])
)

# Panel B: Heterogeneity (sample splits)
sde_hetero <- rbind(
  add_sde_row("2-yr notch: Taipei", results[["taipei"]]),
  add_sde_row("2-yr notch: Other cities", results[["rest"]])
)

# Build LaTeX table
format_sde_row <- function(r) {
  sprintf("%s & %.0f & %.0f & %.0f & %.3f & %.3f & %s \\\\",
          r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification)
}

panel_a_rows <- paste(sapply(seq_len(nrow(sde_pooled)), function(i) format_sde_row(sde_pooled[i])), collapse = "\n")
panel_b_rows <- if (!is.null(sde_hetero) && nrow(sde_hetero) > 0) {
  paste(sapply(seq_len(nrow(sde_hetero)), function(i) format_sde_row(sde_hetero[i])), collapse = "\n")
} else ""

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Taiwan. ",
  "\\textbf{Research question:} How do holding-period capital gains tax notches affect the timing of housing transactions? ",
  "\\textbf{Policy mechanism:} Taiwan's Consolidated Housing Tax 2.0 (July 2021) imposes sharply higher capital gains tax rates ",
  "on properties sold within 2 years of acquisition (45\\%) versus after 2 years (35\\%) and after 5 years (20\\%), ",
  "creating strong incentives to delay sales past holding-period thresholds. ",
  "\\textbf{Outcome definition:} Excess mass of housing transactions measured as the normalized ratio of observed to counterfactual ",
  "transaction density at holding-period notch thresholds, following the bunching methodology of Kleven and Waseem (2013). ",
  "\\textbf{Treatment:} Binary --- the tax notch applies at discrete holding-period thresholds (730 days, 1,825 days). ",
  "\\textbf{Data:} Taiwan Actual Price Registration (Ministry of Interior), all building transactions 2012--2024, repeat-sale pairs ",
  "matched by property address; unit of observation is a transaction pair. ",
  "\\textbf{Method:} Polynomial bunching estimator with 7th-order counterfactual density, 7-day bins, bootstrap standard errors (200 replications). ",
  "\\textbf{Sample:} Restricted to repeat-sale pairs with holding periods between 0 and 20 years; estimation window $\\pm$365 days around each notch. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the average counterfactual bin count. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lSSSSSSl}\n",
  "\\toprule\n",
  "Outcome & {$\\hat{\\beta}$} & {SE} & {SD($Y$)} & {SDE} & {SE(SDE)} & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "\\addlinespace\n",
  panel_a_rows, "\n",
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\\n",
  "\\addlinespace\n",
  panel_b_rows, "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
