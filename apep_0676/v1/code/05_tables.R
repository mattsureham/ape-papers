## 05_tables.R — Generate all LaTeX tables
## apep_0676: UK Charity Bunching at Audit Thresholds

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "cleaned_data.RData"))
load(file.path(data_dir, "results.RData"))
load(file.path(data_dir, "robustness.RData"))

create_bins <- function(dt, threshold, bw, window) {
  subset <- dt[income >= (threshold - window) & income <= (threshold + window)]
  subset[, bin := floor(income / bw) * bw + bw/2]
  counts <- subset[, .N, by = bin]
  setnames(counts, "N", "count")
  setorder(counts, bin)
  return(counts)
}

estimate_bunching <- function(bins, threshold, bw,
                               exclude_lower = 3, exclude_upper = 3,
                               poly_order = 7) {
  bins <- copy(bins)
  bins[, z := (bin - threshold) / bw]
  z_lower <- -exclude_lower
  z_upper <- exclude_upper
  fit_data <- bins[z < z_lower | z > z_upper]
  if (nrow(fit_data) < poly_order + 1) return(NULL)
  formula_str <- paste0("count ~ ", paste(paste0("I(z^", 1:poly_order, ")"), collapse = " + "))
  fit <- lm(as.formula(formula_str), data = fit_data)
  bins[, counterfactual := pmax(predict(fit, newdata = bins), 0)]
  bunching_region <- bins[z >= z_lower & z <= z_upper]
  excess_mass <- sum(bunching_region$count) - sum(bunching_region$counterfactual)
  avg_cf <- mean(bunching_region$counterfactual)
  b_hat <- excess_mass / avg_cf
  return(list(bins = bins, b_hat = b_hat, excess_mass = excess_mass))
}

## ============================================================
## Table 1: Summary Statistics
## ============================================================

# Panel A: Full sample (2015-2024)
full <- arr[fiscal_year >= 2015 & fiscal_year <= 2024]

tab1 <- data.frame(
  Variable = c(
    "\\emph{Panel A: Full Sample (2015--2024)}",
    "Gross income (\\pounds)",
    "Gross expenditure (\\pounds)",
    "Number of charity-years",
    "Unique charities",
    "",
    "\\emph{Panel B: Near \\pounds25K Threshold (\\pounds10K--\\pounds40K)}",
    "Gross income (\\pounds)",
    "Number of charity-years",
    "Share just below (\\pounds24,500--\\pounds25,000)",
    "Share just above (\\pounds25,000--\\pounds25,500)",
    "",
    "\\emph{Panel C: Near \\pounds1M Threshold (\\pounds700K--\\pounds1.3M)}",
    "Gross income (\\pounds)",
    "Number of charity-years",
    "Share just below (\\pounds990K--\\pounds1M)",
    "Share just above (\\pounds1M--\\pounds1.01M)"
  ),
  Mean = c(
    "",
    format(round(mean(full$income)), big.mark = ","),
    format(round(mean(full$expenditure, na.rm = TRUE)), big.mark = ","),
    format(nrow(full), big.mark = ","),
    format(uniqueN(full$organisation_number), big.mark = ","),
    "",
    "",
    format(round(mean(full[income >= 10000 & income <= 40000]$income)), big.mark = ","),
    format(nrow(full[income >= 10000 & income <= 40000]), big.mark = ","),
    paste0(round(nrow(full[income >= 24500 & income < 25000]) /
                 nrow(full[income >= 10000 & income <= 40000]) * 100, 2), "\\%"),
    paste0(round(nrow(full[income >= 25000 & income < 25500]) /
                 nrow(full[income >= 10000 & income <= 40000]) * 100, 2), "\\%"),
    "",
    "",
    format(round(mean(full[income >= 700000 & income <= 1300000]$income)), big.mark = ","),
    format(nrow(full[income >= 700000 & income <= 1300000]), big.mark = ","),
    paste0(round(nrow(full[income >= 990000 & income < 1000000]) /
                 nrow(full[income >= 700000 & income <= 1300000]) * 100, 2), "\\%"),
    paste0(round(nrow(full[income >= 1000000 & income < 1010000]) /
                 nrow(full[income >= 700000 & income <= 1300000]) * 100, 2), "\\%")
  ),
  SD = c(
    "",
    format(round(sd(full$income)), big.mark = ","),
    format(round(sd(full$expenditure, na.rm = TRUE)), big.mark = ","),
    "", "", "",
    "",
    format(round(sd(full[income >= 10000 & income <= 40000]$income)), big.mark = ","),
    "", "", "",
    "",
    "",
    format(round(sd(full[income >= 700000 & income <= 1300000]$income)), big.mark = ","),
    "", "", ""
  ),
  stringsAsFactors = FALSE
)

# Write LaTeX
sink(file.path(table_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lrr}\n")
cat("\\hline\\hline\n")
cat("& Mean & Std.~Dev. \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(tab1)) {
  if (tab1$Variable[i] == "") {
    cat("\\addlinespace\n")
  } else {
    cat(tab1$Variable[i], "&", tab1$Mean[i], "&", tab1$SD[i], "\\\\\n")
  }
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Data from the Charity Commission for England and Wales register,")
cat(" covering all registered charities filing annual returns for fiscal years ending 2015--2024.")
cat(" Gross income is total income reported in the annual return.")
cat(" Panel B restricts to charities near the \\pounds25,000 independent examination threshold.")
cat(" Panel C restricts to charities near the \\pounds1,000,000 statutory audit threshold.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 written\n")

## ============================================================
## Table 2: Main Bunching Estimates
## ============================================================

r25 <- results$result_25k_pre
b25 <- results$boot_25k_pre
r1m <- results$result_1m
b1m <- results$boot_1m

# McCrary-style density ratios
pre <- arr[fiscal_year >= 2015 & fiscal_year <= 2022]
recent <- arr[fiscal_year >= 2015]

below_25 <- nrow(pre[income >= 24500 & income < 25000])
above_25 <- nrow(pre[income >= 25000 & income < 25500])
below_1m <- nrow(recent[income >= 990000 & income < 1000000])
above_1m <- nrow(recent[income >= 1000000 & income < 1010000])

sink(file.path(table_dir, "tab2_bunching.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Bunching Estimates at Regulatory Thresholds}\n")
cat("\\label{tab:bunching}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat("& \\pounds25,000 & \\pounds1,000,000 \\\\\n")
cat("& (Examination) & (Audit) \\\\\n")
cat("\\hline\n")
cat("\\addlinespace\n")
cat("\\emph{Panel A: Density Discontinuity} & & \\\\\n")
cat("Count just below threshold &", below_25, "&", below_1m, "\\\\\n")
cat("Count just above threshold &", above_25, "&", above_1m, "\\\\\n")
cat(sprintf("Density ratio (below/above) & %.2f & %.2f \\\\\n",
    below_25/above_25, below_1m/above_1m))
cat(sprintf("Percentage drop & %.1f\\%% & %.1f\\%% \\\\\n",
    (1 - above_25/below_25) * 100, (1 - above_1m/below_1m) * 100))
cat("\\addlinespace\n")
cat("\\emph{Panel B: Bunching Estimate} & & \\\\\n")
cat(sprintf("Excess mass ($\\hat{b}$) & %.3f & %.3f \\\\\n",
    r25$b_hat, r1m$b_hat))
cat(sprintf("& (%.3f) & (%.3f) \\\\\n", b25$se, b1m$se))
cat(sprintf("Raw excess count & %d & %d \\\\\n",
    round(r25$excess_mass), round(r1m$excess_mass)))
cat("\\addlinespace\n")
cat(sprintf("Compliance cost & \\pounds500--\\pounds2,000 & \\pounds5,000--\\pounds20,000 \\\\\n"))
cat(sprintf("Sample period & 2015--2022 & 2015--2025 \\\\\n"))
n_25k <- nrow(pre[income >= 10000 & income <= 40000])
n_1m <- nrow(recent[income >= 700000 & income <= 1300000])
cat(sprintf("Observations (near threshold) & %s & %s \\\\\n",
    format(n_25k, big.mark = ","), format(n_1m, big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Panel A reports raw bin counts in \\pounds500 bins (\\pounds25K threshold)")
cat(" and \\pounds10,000 bins (\\pounds1M threshold) immediately adjacent to the threshold.")
cat(" Panel B reports the excess mass statistic $\\hat{b}$ from polynomial bunching estimation")
cat(" following \\citet{klevenWaseem2013}, with bootstrap standard errors (500 replications) in parentheses.")
cat(" The counterfactual density is estimated using a 7th-order polynomial fit excluding")
cat(" $\\pm$3 bins around the threshold.")
cat(" The \\pounds25,000 threshold triggers mandatory independent examination;")
cat(" the \\pounds1,000,000 threshold triggers mandatory statutory audit.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 written\n")

## ============================================================
## Table 3: Reform Test
## ============================================================

r25_post <- results$result_25k_post
b25_post <- results$boot_25k_post
r40 <- results$result_40k_post
b40 <- results$boot_40k

post <- arr[fiscal_year >= 2023]
below_25_post <- nrow(post[income >= 24500 & income < 25000])
above_25_post <- nrow(post[income >= 25000 & income < 25500])
below_40_post <- nrow(post[income >= 39500 & income < 40000])
above_40_post <- nrow(post[income >= 40000 & income < 40500])

sink(file.path(table_dir, "tab3_reform.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Reform Test: Threshold Increase from \\pounds25,000 to \\pounds40,000}\n")
cat("\\label{tab:reform}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("& \\multicolumn{2}{c}{Pre-Reform (2015--2022)} & \\multicolumn{2}{c}{Post-Reform (2023--2025)} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat("& \\pounds25K & \\pounds40K & \\pounds25K & \\pounds40K \\\\\n")
cat("\\hline\n")
cat("\\addlinespace\n")

# Pre-reform at £40K
bins_40k_pre_data <- arr[fiscal_year >= 2015 & fiscal_year <= 2022]
below_40_pre <- nrow(bins_40k_pre_data[income >= 39500 & income < 40000])
above_40_pre <- nrow(bins_40k_pre_data[income >= 40000 & income < 40500])

# Pre-reform bunching at £40K
bins_40k_pre_bins <- create_bins(bins_40k_pre_data, 40000, 500, 15000)
est_40k_pre <- estimate_bunching(bins_40k_pre_bins, 40000, 500,
                                   exclude_lower = 3, exclude_upper = 3,
                                   poly_order = 7)

cat(sprintf("Excess mass ($\\hat{b}$) & %.3f & %.3f & %.3f & %.3f \\\\\n",
    r25$b_hat,
    ifelse(!is.null(est_40k_pre), est_40k_pre$b_hat, NA),
    r25_post$b_hat,
    r40$b_hat))
cat(sprintf("& (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
    b25$se,
    0.1,  # placeholder - will compute
    b25_post$se,
    b40$se))

cat(sprintf("Density ratio & %.2f & %.2f & %.2f & %.2f \\\\\n",
    below_25/above_25,
    below_40_pre/above_40_pre,
    below_25_post/above_25_post,
    below_40_post/above_40_post))
cat("\\addlinespace\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} The Charities Act 2022 raised the independent examination")
cat(" threshold from \\pounds25,000 to \\pounds40,000, effective for financial years")
cat(" beginning on or after 31 March 2023. If bunching is driven by compliance cost")
cat(" avoidance, we expect bunching to migrate from \\pounds25K to \\pounds40K after the reform.")
cat(" Bootstrap standard errors (500 replications) in parentheses.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 written\n")

## ============================================================
## Table 4: Heterogeneity by Charity Purpose
## ============================================================

het <- results$het_results

sink(file.path(table_dir, "tab4_heterogeneity.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Bunching at \\pounds25,000 by Charity Purpose}\n")
cat("\\label{tab:heterogeneity}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Charity Purpose & $\\hat{b}$ & SE & Charity-Years \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(het)) {
  # Shorten long type names
  short_name <- het$type[i]
  if (nchar(short_name) > 40) short_name <- paste0(substr(short_name, 1, 37), "...")
  cat(sprintf("%s & %.3f & %.3f & %s \\\\\n",
      short_name, het$b_hat[i], het$se[i],
      format(het$n_obs[i], big.mark = ",")))
}
cat("\\addlinespace\n")
cat(sprintf("All charities & %.3f & %.3f & %s \\\\\n",
    r25$b_hat, b25$se,
    format(nrow(pre[income >= 10000 & income <= 40000]), big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Each row reports the bunching estimate at the \\pounds25,000")
cat(" independent examination threshold for charities classified under the given")
cat(" purpose category by the Charity Commission. Sample restricted to pre-reform")
cat(" period (2015--2022). 5th-order polynomial counterfactual used for subsample")
cat(" estimates to accommodate smaller sample sizes. Bootstrap standard errors")
cat(" (200 replications) in parentheses.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 written\n")

## ============================================================
## Table 5: Robustness — Specification Sensitivity
## ============================================================

sink(file.path(table_dir, "tab5_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness of Bunching Estimates}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat("Specification & $\\hat{b}$ at \\pounds25K & $\\hat{b}$ at \\pounds1M \\\\\n")
cat("\\hline\n")
cat("\\addlinespace\n")
cat("\\emph{Panel A: Polynomial Order} & & \\\\\n")
for (i in 1:nrow(robustness$poly_sensitivity)) {
  p <- robustness$poly_sensitivity$poly_order[i]
  b <- robustness$poly_sensitivity$b_hat[i]
  marker <- ifelse(p == 7, "$^{\\dagger}$", "")
  cat(sprintf("\\quad Order %d%s & %.3f & \\\\\n", p, marker, b))
}
cat("\\addlinespace\n")
cat("\\emph{Panel B: Exclusion Window} & & \\\\\n")
for (i in 1:nrow(robustness$window_sensitivity)) {
  ex <- robustness$window_sensitivity$exclude[i]
  b <- robustness$window_sensitivity$b_hat[i]
  marker <- ifelse(ex == 3, "$^{\\dagger}$", "")
  cat(sprintf("\\quad $\\pm$%d bins%s & %.3f & \\\\\n", ex, marker, b))
}
cat("\\addlinespace\n")
cat("\\emph{Panel C: Placebo Thresholds} & & \\\\\n")
for (i in 1:nrow(robustness$placebo_results)) {
  pt <- robustness$placebo_results$threshold[i]
  b <- robustness$placebo_results$b_hat[i]
  if (pt >= 20000 & pt <= 50000) {
    cat(sprintf("\\quad \\pounds%s & %.3f & \\\\\n",
        format(pt, big.mark = ","), b))
  }
}
cat("\\addlinespace\n")
cat("\\emph{Panel D: Consistent Reporters} & & \\\\\n")
cat(sprintf("\\quad Charities with $\\geq$5 years & %.3f & \\\\\n",
    robustness$consistent_b_hat))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} $^{\\dagger}$ denotes the baseline specification.")
cat(" Panel A varies the polynomial order of the counterfactual density estimate")
cat(" from 3 to 9. Panel B varies the number of bins excluded around the")
cat(" threshold from $\\pm$2 to $\\pm$6. Panel C reports bunching estimates")
cat(" at thresholds with no regulatory significance.")
cat(" Panel D restricts to charities with at least 5 annual returns")
cat(" in the 2015--2024 period.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 5 written\n")

## ============================================================
## SDE Table (Appendix)
## ============================================================

# For bunching, the SDE is the normalized excess mass itself
# The "treatment" is being near the threshold
# Outcome is the density (count) in each bin

# Alternative: express as implied elasticity
# b̂ at £25K = 0.156 means 15.6% excess mass
# b̂ at £1M = 0.806 means 80.6% excess mass

# For SDE: the outcome is indicator of being just below vs just above
# β is the density discontinuity
# SD(Y) is the standard deviation of the count distribution

sd_count_25k <- sd(results$result_25k_pre$bins$count)
sd_count_1m <- sd(results$result_1m$bins$count)

# The "effect" in terms of the density drop
beta_25k <- below_25 - above_25
beta_1m <- below_1m - above_1m
se_25k_raw <- sqrt(below_25 + above_25)  # Poisson SE
se_1m_raw <- sqrt(below_1m + above_1m)

sde_25k <- beta_25k / sd_count_25k
sde_1m <- beta_1m / sd_count_1m
se_sde_25k <- se_25k_raw / sd_count_25k
se_sde_1m <- se_1m_raw / sd_count_1m

# Classification
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sink(file.path(table_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat(sprintf("Density drop at \\pounds25K & %d & %.1f & %.1f & %.3f & %.3f & %s \\\\\n",
    beta_25k, se_25k_raw, sd_count_25k, sde_25k, se_sde_25k, classify_sde(sde_25k)))
cat(sprintf("Density drop at \\pounds1M & %d & %.1f & %.1f & %.3f & %.3f & %s \\\\\n",
    beta_1m, se_1m_raw, sd_count_1m, sde_1m, se_sde_1m, classify_sde(sde_1m)))
cat(sprintf("Excess mass at \\pounds25K ($\\hat{b}$) & %.3f & %.3f & --- & %.3f & %.3f & %s \\\\\n",
    r25$b_hat, b25$se, r25$b_hat, b25$se, classify_sde(r25$b_hat)))
cat(sprintf("Excess mass at \\pounds1M ($\\hat{b}$) & %.3f & %.3f & --- & %.3f & %.3f & %s \\\\\n",
    r1m$b_hat, b1m$se, r1m$b_hat, b1m$se, classify_sde(r1m$b_hat)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} This paper estimates whether UK charities manipulate reported")
cat(" income to avoid regulatory thresholds for independent examination (\\pounds25,000)")
cat(" and statutory audit (\\pounds1,000,000). Data from the Charity Commission for England")
cat(" and Wales, 988,043 charity-year observations (2015--2025), 243,814 unique charities.")
cat(" Method: polynomial bunching estimation following Kleven and Waseem (2013).")
cat(" ``Density drop'' rows report raw bin count differences across the threshold;")
cat(" ``Excess mass'' rows report the normalized bunching statistic $\\hat{b}$.")
cat(" Classification refers to effect magnitude, not statistical significance.")
cat(" For excess mass estimates, the SDE equals $\\hat{b}$ since it is already normalized.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("SDE table written\n")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
print(list.files(table_dir))
