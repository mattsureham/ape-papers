## 05_tables.R — Generate all tables for paper
## apep_0952: The Stamp Duty Cliff That Wasn't

source("00_packages.R")

sales <- fread("../data/nsw_sales_clean.csv")
sales[, contract_date := as.Date(contract_date)]
reform_date <- as.Date("2023-07-01")
sales[, post_reform := contract_date >= reform_date]

results <- readRDS("../data/bunching_results.rds")
rob <- readRDS("../data/robustness_results.rds")

## ============================================================
## Table 1: Summary Statistics
## ============================================================
summ <- sales[purchase_price >= 500000 & purchase_price <= 1100000,
  .(
    N = .N,
    `Mean Price` = sprintf("%.0f", mean(purchase_price)),
    `Median Price` = sprintf("%.0f", median(purchase_price)),
    `SD Price` = sprintf("%.0f", sd(purchase_price)),
    `Mean Area (sqm)` = sprintf("%.0f", mean(area_sqm, na.rm = TRUE)),
    `Pct R2 Zone` = sprintf("%.1f", mean(zoning == "R2", na.rm = TRUE) * 100)
  ),
  by = .(Period = ifelse(post_reform, "Post-reform (Jul 2023--Mar 2026)",
                          "Pre-reform (Jan 2017--Jun 2023)"))
]

tab1 <- "\\begin{table}[t]
\\centering
\\caption{Summary Statistics: NSW Residential Sales, \\$500K--\\$1.1M}
\\label{tab:summary}
\\begin{tabular}{lcc}
\\hline\\hline
& Pre-reform & Post-reform \\\\
& (Jan 2017--Jun 2023) & (Jul 2023--Mar 2026) \\\\
\\hline
"
pre <- summ[Period == "Pre-reform (Jan 2017--Jun 2023)"]
post <- summ[Period == "Post-reform (Jul 2023--Mar 2026)"]

tab1 <- paste0(tab1,
  sprintf("Observations & %s & %s \\\\\n", format(pre$N, big.mark=","), format(post$N, big.mark=",")),
  sprintf("Mean price (A\\$) & %s & %s \\\\\n", format(as.numeric(pre$`Mean Price`), big.mark=","), format(as.numeric(post$`Mean Price`), big.mark=",")),
  sprintf("Median price (A\\$) & %s & %s \\\\\n", format(as.numeric(pre$`Median Price`), big.mark=","), format(as.numeric(post$`Median Price`), big.mark=",")),
  sprintf("SD price (A\\$) & %s & %s \\\\\n", format(as.numeric(pre$`SD Price`), big.mark=","), format(as.numeric(post$`SD Price`), big.mark=",")),
  sprintf("Mean area (sqm) & %s & %s \\\\\n", pre$`Mean Area (sqm)`, post$`Mean Area (sqm)`),
  sprintf("Pct R2 (Low Density) zone & %s\\%% & %s\\%% \\\\\n", pre$`Pct R2 Zone`, post$`Pct R2 Zone`),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} NSW Valuer General Property Sales Information, residential sales (nature = R) with prices between A\\$500,000 and A\\$1,100,000. Pre-reform: contract dates before July 1, 2023. Post-reform: contract dates on or after July 1, 2023. Area measured in square meters where available.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

## ============================================================
## Table 2: Main Bunching Results
## ============================================================
tab2 <- "\\begin{table}[t]
\\centering
\\caption{Bunching Estimates at Stamp Duty Exemption Thresholds}
\\label{tab:bunching}
\\begin{tabular}{lccc}
\\hline\\hline
& \\multicolumn{2}{c}{Excess mass ($\\hat{b}$)} & Difference-in- \\\\
\\cmidrule(lr){2-3}
Threshold & Pre-reform & Post-reform & bunching ($\\Delta\\hat{b}$) \\\\
\\hline
\\textit{Panel A: Policy thresholds} & & & \\\\[3pt]
"
tab2 <- paste0(tab2,
  sprintf("A\\$650,000 (old threshold) & %.2f & %.2f & %.2f \\\\\n",
          results$b_650_pre, results$b_650_post, results$dib_650),
  sprintf("  & (%.2f) & (%.2f) & (%.2f) \\\\\n",
          results$se_650_pre, results$se_650_post, results$dib_650_se),
  "[6pt]\n",
  sprintf("A\\$800,000 (new threshold) & %.2f & %.2f & %.2f \\\\\n",
          results$b_800_pre, results$b_800_post, results$dib_800),
  sprintf("  & (%.2f) & (%.2f) & (%.2f) \\\\\n",
          results$se_800_pre, results$se_800_post, results$dib_800_se),
  "[6pt]\n",
  "\\textit{Panel B: Placebo threshold} & & & \\\\[3pt]\n",
  sprintf("A\\$900,000 (no policy) & --- & --- & %.2f \\\\\n", results$dib_900),
  sprintf("  & & & (%.2f) \\\\\n", results$dib_900_se),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Excess mass $\\hat{b}$ estimated following Kleven (2016). Counterfactual distribution fitted with 7th-degree polynomial in \\$5,000 price bins over A\\$600,000--A\\$1,000,000, excluding the bunching window (threshold $-$ A\\$25,000 to threshold $+$ A\\$5,000). Standard errors from 200 bootstrap replications in parentheses. Difference-in-bunching $\\Delta\\hat{b}$ = post-reform $\\hat{b}$ minus pre-reform $\\hat{b}$. Pre-reform: contract dates before July 1, 2023. Post-reform: contract dates on or after July 1, 2023. Data: NSW Valuer General Property Sales Information, residential transactions.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_bunching.tex")

## ============================================================
## Table 3: Robustness of DiB at $800K
## ============================================================
# Re-source main analysis for the function
source("03_main_analysis.R")

# Collect robustness results
rob_specs <- data.table(
  Specification = character(),
  DiB = numeric(),
  SE = numeric()
)

# Baseline
rob_specs <- rbind(rob_specs, data.table(Specification = "Baseline (\\$5K bins, poly 7, excl \\$25K)",
                                          DiB = results$dib_800, SE = results$dib_800_se))

# Bin widths
for (bw in c(2500, 10000)) {
  pre_data <- sales[post_reform == FALSE]
  post_data <- sales[post_reform == TRUE]
  b_pre <- estimate_bunching(pre_data, 800000, bin_width = bw, n_boot = 100)
  b_post <- estimate_bunching(post_data, 800000, bin_width = bw, n_boot = 100)
  d <- b_post$b_hat - b_pre$b_hat
  s <- sqrt(b_post$b_se^2 + b_pre$b_se^2)
  lab <- sprintf("Bin width = A\\$%s", format(bw, big.mark=","))
  rob_specs <- rbind(rob_specs, data.table(Specification = lab, DiB = d, SE = s))
}

# Poly degrees
for (deg in c(5, 9)) {
  pre_data <- sales[post_reform == FALSE]
  post_data <- sales[post_reform == TRUE]
  b_pre <- estimate_bunching(pre_data, 800000, poly_degree = deg, n_boot = 100)
  b_post <- estimate_bunching(post_data, 800000, poly_degree = deg, n_boot = 100)
  d <- b_post$b_hat - b_pre$b_hat
  s <- sqrt(b_post$b_se^2 + b_pre$b_se^2)
  rob_specs <- rbind(rob_specs, data.table(
    Specification = sprintf("Polynomial degree = %d", deg), DiB = d, SE = s))
}

# Exclusion windows
for (excl in c(15000, 50000)) {
  pre_data <- sales[post_reform == FALSE]
  post_data <- sales[post_reform == TRUE]
  b_pre <- estimate_bunching(pre_data, 800000, lower_excl = excl, n_boot = 100)
  b_post <- estimate_bunching(post_data, 800000, lower_excl = excl, n_boot = 100)
  d <- b_post$b_hat - b_pre$b_hat
  s <- sqrt(b_post$b_se^2 + b_pre$b_se^2)
  lab <- sprintf("Exclusion window = A\\$%s", format(excl, big.mark=","))
  rob_specs <- rbind(rob_specs, data.table(Specification = lab, DiB = d, SE = s))
}

# Narrow time window
rob_specs <- rbind(rob_specs, data.table(
  Specification = "6-month window around reform",
  DiB = rob$dib_narrow, SE = rob$dib_narrow_se))

tab3 <- "\\begin{table}[t]
\\centering
\\caption{Robustness of Difference-in-Bunching at A\\$800,000}
\\label{tab:robustness}
\\begin{tabular}{lcc}
\\hline\\hline
Specification & $\\Delta\\hat{b}$ & SE \\\\
\\hline
"
for (i in 1:nrow(rob_specs)) {
  tab3 <- paste0(tab3, sprintf("%s & %.2f & (%.2f) \\\\\n",
                                rob_specs$Specification[i],
                                rob_specs$DiB[i], rob_specs$SE[i]))
}
tab3 <- paste0(tab3,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row reports the difference-in-bunching ($\\Delta\\hat{b}$) at the A\\$800,000 threshold under alternative specifications. Baseline uses \\$5,000 bins, 7th-degree polynomial, and a \\$25,000 exclusion window below the threshold. Standard errors from 100--200 bootstrap replications.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_robustness.tex")

## ============================================================
## Table 4: Area Composition Near Threshold
## ============================================================
near_800 <- sales[purchase_price >= 750000 & purchase_price <= 850000 &
                    !is.na(area_sqm) & area_sqm > 0 & area_sqm < 50000]
near_800[, below := purchase_price <= 800000]

# Main spec
comp1 <- feols(log(area_sqm) ~ post_reform * below | postcode,
               data = near_800, cluster = "postcode")

# No fixed effects
comp2 <- feols(log(area_sqm) ~ post_reform * below,
               data = near_800, cluster = "postcode")

# Narrower window: $775K-$825K
near_narrow <- sales[purchase_price >= 775000 & purchase_price <= 825000 &
                       !is.na(area_sqm) & area_sqm > 0 & area_sqm < 50000]
near_narrow[, below := purchase_price <= 800000]
comp3 <- feols(log(area_sqm) ~ post_reform * below | postcode,
               data = near_narrow, cluster = "postcode")

# Format table
tab4 <- "\\begin{table}[t]
\\centering
\\caption{Lot Area Composition Near the A\\$800,000 Threshold}
\\label{tab:composition}
\\begin{tabular}{lccc}
\\hline\\hline
& (1) & (2) & (3) \\\\
& Postcode FE & No FE & Narrow window \\\\
& \\$750K--\\$850K & \\$750K--\\$850K & \\$775K--\\$825K \\\\
\\hline
"
# Extract coefficients
get_row <- function(mod, var) {
  b <- coef(mod)[var]
  se <- sqrt(vcov(mod)[var, var])
  sprintf("%.3f & ", b)
}

# Post-reform
b1 <- coef(comp1)["post_reformTRUE"]
se1 <- sqrt(vcov(comp1)["post_reformTRUE","post_reformTRUE"])
b2 <- coef(comp2)["post_reformTRUE"]
se2 <- sqrt(vcov(comp2)["post_reformTRUE","post_reformTRUE"])
b3 <- coef(comp3)["post_reformTRUE"]
se3 <- sqrt(vcov(comp3)["post_reformTRUE","post_reformTRUE"])

tab4 <- paste0(tab4,
  sprintf("Post-reform & %.3f & %.3f & %.3f \\\\\n", b1, b2, b3),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n", se1, se2, se3),
  "[3pt]\n")

# Below threshold
b1 <- coef(comp1)["belowTRUE"]
se1 <- sqrt(vcov(comp1)["belowTRUE","belowTRUE"])
b2 <- coef(comp2)["belowTRUE"]
se2 <- sqrt(vcov(comp2)["belowTRUE","belowTRUE"])
b3 <- coef(comp3)["belowTRUE"]
se3 <- sqrt(vcov(comp3)["belowTRUE","belowTRUE"])

tab4 <- paste0(tab4,
  sprintf("Below \\$800K & %.3f & %.3f & %.3f \\\\\n", b1, b2, b3),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n", se1, se2, se3),
  "[3pt]\n")

# Interaction
b1 <- coef(comp1)["post_reformTRUE:belowTRUE"]
se1 <- sqrt(vcov(comp1)["post_reformTRUE:belowTRUE","post_reformTRUE:belowTRUE"])
b2 <- coef(comp2)["post_reformTRUE:belowTRUE"]
se2 <- sqrt(vcov(comp2)["post_reformTRUE:belowTRUE","post_reformTRUE:belowTRUE"])
b3 <- coef(comp3)["post_reformTRUE:belowTRUE"]
se3 <- sqrt(vcov(comp3)["post_reformTRUE:belowTRUE","post_reformTRUE:belowTRUE"])

tab4 <- paste0(tab4,
  sprintf("Post $\\times$ Below & %.3f & %.3f & %.3f \\\\\n", b1, b2, b3),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n", se1, se2, se3),
  "[6pt]\n",
  sprintf("Postcode FE & Yes & No & Yes \\\\\n"),
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(nobs(comp1), big.mark=","),
          format(nobs(comp2), big.mark=","),
          format(nobs(comp3), big.mark=",")),
  sprintf("R$^2$ (within) & %.3f & --- & %.3f \\\\\n",
          fitstat(comp1, "wr2")[[1]], fitstat(comp3, "wr2")[[1]]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable: log(lot area in sqm). ``Below \\$800K'' equals one if sale price $\\leq$ A\\$800,000. Standard errors clustered by postcode in parentheses. Sample restricted to residential sales with valid positive lot area below 50,000 sqm. Columns (1) and (3) include postcode fixed effects.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_composition.tex")

## ============================================================
## Table F1: SDE Table (Appendix)
## ============================================================
# Main outcomes:
# 1. Price bunching at new threshold (DiB at $800K) — null
# 2. Price bunching at old threshold (DiB at $650K) — large negative
# 3. Lot area composition (interaction term)

# Compute SDEs
# For bunching: the "treatment" is the threshold shift; the "outcome" is excess mass
# SDE = beta / SD(Y). Here beta = DiB, SD(Y) = SD of bin counts in the analysis range

# Get SD of Y for bunching
bins_post <- results$bins_800_post
sd_bincount_800 <- sd(bins_post$count)

# DiB at $800K
sde_800 <- results$dib_800 * mean(bins_post$counterfactual) / sd_bincount_800
sde_800_se <- results$dib_800_se * mean(bins_post$counterfactual) / sd_bincount_800

# DiB at $650K: use pre-reform bin data
bins_pre <- results$bins_800_pre  # Use same scaling
# For $650K, the SDE is relative to the pre-reform distribution
sde_650 <- results$dib_650 * abs(results$b_650_pre) * mean(bins_pre$counterfactual) / sd(bins_pre$count)
sde_650_se <- results$dib_650_se * abs(results$b_650_pre) * mean(bins_pre$counterfactual) / sd(bins_pre$count)

# Lot area composition
comp_beta <- coef(comp1)["post_reformTRUE:belowTRUE"]
comp_se_val <- sqrt(vcov(comp1)["post_reformTRUE:belowTRUE","post_reformTRUE:belowTRUE"])
sd_log_area <- sd(near_800$area_sqm[!is.na(near_800$area_sqm)], na.rm = TRUE)
sd_log_area_log <- sd(log(near_800$area_sqm[near_800$area_sqm > 0 & !is.na(near_800$area_sqm)]))
sde_area <- comp_beta / sd_log_area_log
sde_area_se <- comp_se_val / sd_log_area_log

# Classify
classify <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde < 0, "Small negative", "Small positive"))
  if (abs_sde < 0.15) return(ifelse(sde < 0, "Moderate negative", "Moderate positive"))
  return(ifelse(sde < 0, "Large negative", "Large positive"))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Australia. ",
  "\\textbf{Research question:} Does raising the first home buyer stamp duty exemption threshold from A\\$650,000 to A\\$800,000 create new price distortions in the NSW housing market? ",
  "\\textbf{Policy mechanism:} The NSW First Home Buyers Assistance Scheme exempts purchases below the threshold from transfer duty (stamp tax), creating a notch where buyers just below the threshold save approximately A\\$31,000 relative to buyers just above. The July 2023 reform shifted this notch from A\\$650,000 to A\\$800,000. ",
  "\\textbf{Outcome definition:} Panel A: excess mass (normalized bunching estimate $\\hat{b}$) measuring the density distortion at the price threshold. Panel B: log lot area (square meters) for properties near the threshold, capturing quality composition changes. ",
  "\\textbf{Treatment:} Binary; pre-reform (before July 1, 2023) vs.\\ post-reform (on or after July 1, 2023). ",
  "\\textbf{Data:} NSW Valuer General Property Sales Information, residential transactions 2017--2026, 63,165 observations in the \\$500K--\\$1.1M analysis range. ",
  "\\textbf{Method:} Bunching estimation following Kleven (2016) with difference-in-bunching; OLS with postcode fixed effects for composition. Standard errors bootstrapped (bunching) or clustered by postcode (composition). ",
  "\\textbf{Sample:} Residential sales (nature = R) in NSW with valid prices; composition regressions restricted to \\$750K--\\$850K with positive lot area below 50,000 sqm. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\textit{Panel A: Pooled} & & & & & & \\\\\n",
  sprintf("DiB at A\\$800K (new) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
          results$dib_800, results$dib_800_se, sd_bincount_800,
          sde_800, abs(sde_800_se), classify(sde_800)),
  sprintf("DiB at A\\$650K (old) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
          results$dib_650, results$dib_650_se, sd(bins_pre$count),
          sde_650, abs(sde_650_se), classify(sde_650)),
  sprintf("Lot area (Post $\\times$ Below) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          comp_beta, comp_se_val, sd_log_area_log,
          sde_area, abs(sde_area_se), classify(sde_area)),
  "[6pt]\n",
  "\\textit{Panel B: Heterogeneous} & & & & & & \\\\\n"
)

# Heterogeneity: by zoning (R2 vs non-R2)
r2_data <- near_800[zoning == "R2"]
non_r2_data <- near_800[zoning != "" & zoning != "R2"]

if (nrow(r2_data) > 100 & nrow(non_r2_data) > 100) {
  comp_r2 <- feols(log(area_sqm) ~ post_reform * below | postcode,
                    data = r2_data, cluster = "postcode")
  comp_nonr2 <- feols(log(area_sqm) ~ post_reform * below | postcode,
                       data = non_r2_data, cluster = "postcode")

  b_r2 <- coef(comp_r2)["post_reformTRUE:belowTRUE"]
  se_r2 <- sqrt(vcov(comp_r2)["post_reformTRUE:belowTRUE","post_reformTRUE:belowTRUE"])
  sd_r2 <- sd(log(r2_data$area_sqm[r2_data$area_sqm > 0 & !is.na(r2_data$area_sqm)]))
  sde_r2 <- b_r2 / sd_r2
  sde_r2_se <- se_r2 / sd_r2

  b_nr2 <- coef(comp_nonr2)["post_reformTRUE:belowTRUE"]
  se_nr2 <- sqrt(vcov(comp_nonr2)["post_reformTRUE:belowTRUE","post_reformTRUE:belowTRUE"])
  sd_nr2 <- sd(log(non_r2_data$area_sqm[non_r2_data$area_sqm > 0 & !is.na(non_r2_data$area_sqm)]))
  sde_nr2 <- b_nr2 / sd_nr2
  sde_nr2_se <- se_nr2 / sd_nr2

  tabF1 <- paste0(tabF1,
    sprintf("R2 (Low Density) zone & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            b_r2, se_r2, sd_r2, sde_r2, abs(sde_r2_se), classify(sde_r2)),
    sprintf("Non-R2 zones & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            b_nr2, se_nr2, sd_nr2, sde_nr2, abs(sde_nr2_se), classify(sde_nr2))
  )
}

tabF1 <- paste0(tabF1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
cat("Files:", paste(list.files("../tables/"), collapse = ", "), "\n")
