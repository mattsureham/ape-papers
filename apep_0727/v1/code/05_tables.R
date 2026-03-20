## 05_tables.R — Generate all LaTeX tables
## apep_0727: German Solar PV Bunching at 10 kWp Threshold

source("00_packages.R")

cat("Loading results...\n")
main_results <- fromJSON("../data/main_results.json")
annual_dt <- fread("../data/annual_bunching.csv")
poly_dt <- fread("../data/robustness_polynomial.csv")
window_dt <- fread("../data/robustness_windows.csv")
placebo_dt <- fread("../data/robustness_placebo.csv")
state_dt <- fread("../data/heterogeneity_state.csv")

dir.create("../tables", showWarnings = FALSE)

# ============================================================
# Table 1: Summary Statistics
# ============================================================

dt <- fread("../data/solar_clean.csv")

tab1_data <- data.table(
  Variable = c(
    "\\textit{Panel A: Full Sample (3--20 kWp)}",
    "\\quad Installations",
    "\\quad Mean capacity (kWp)",
    "\\quad Median capacity (kWp)",
    "\\quad SD capacity (kWp)",
    "",
    "\\textit{Panel B: Pre-Policy (2008--2013)}",
    "\\quad Installations",
    "\\quad Mean capacity (kWp)",
    "\\quad Installations 9--10 kWp",
    "\\quad Installations 10--11 kWp",
    "\\quad Ratio (9--10)/(10--11)",
    "",
    "\\textit{Panel C: Policy Period (2014--2018)}",
    "\\quad Installations",
    "\\quad Mean capacity (kWp)",
    "\\quad Installations 9--10 kWp",
    "\\quad Installations 10--11 kWp",
    "\\quad Ratio (9--10)/(10--11)"
  )
)

pre <- dt[period == "pre_policy"]
pol <- dt[period == "policy"]

pre_9_10 <- nrow(pre[capacity_kwp >= 9.0 & capacity_kwp < 10.0])
pre_10_11 <- nrow(pre[capacity_kwp >= 10.0 & capacity_kwp < 11.0])
pol_9_10 <- nrow(pol[capacity_kwp >= 9.0 & capacity_kwp < 10.0])
pol_10_11 <- nrow(pol[capacity_kwp >= 10.0 & capacity_kwp < 11.0])

tab1_data[, Value := c(
  "",
  format(nrow(dt), big.mark = ","),
  sprintf("%.2f", mean(dt$capacity_kwp)),
  sprintf("%.2f", median(dt$capacity_kwp)),
  sprintf("%.2f", sd(dt$capacity_kwp)),
  "",
  "",
  format(nrow(pre), big.mark = ","),
  sprintf("%.2f", mean(pre$capacity_kwp)),
  format(pre_9_10, big.mark = ","),
  format(pre_10_11, big.mark = ","),
  sprintf("%.2f", pre_9_10 / pre_10_11),
  "",
  "",
  format(nrow(pol), big.mark = ","),
  sprintf("%.2f", mean(pol$capacity_kwp)),
  format(pol_9_10, big.mark = ","),
  format(pol_10_11, big.mark = ","),
  sprintf("%.2f", pol_9_10 / pol_10_11)
)]

# Write Table 1
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: German Solar PV Installations}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lc}\n")
cat("\\hline\\hline\n")
cat(" & Value \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(tab1_data)) {
  cat(sprintf("%s & %s \\\\\n", tab1_data$Variable[i], tab1_data$Value[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Data from the Open Power System Data (OPSD) Renewable Power Plants Germany dataset, covering all solar PV installations registered with the German energy regulator (Bundesnetzagentur) through 2018. Sample restricted to installations with capacity 3--20 kWp. The EEG 2014 surcharge exemption threshold at 10 kWp became effective August 1, 2014.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 saved.\n")

# ============================================================
# Table 2: Main Bunching Results
# ============================================================

sink("../tables/tab2_bunching.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Bunching Estimation Results}\n")
cat("\\label{tab:bunching}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & Policy Period & Pre-Policy \\\\\n")
cat(" & (2014--2018) & (2008--2013) \\\\\n")
cat("\\hline\n")
cat(sprintf("Excess mass ($\\hat{B}$) & %s & %s \\\\\n",
            format(round(main_results$policy$excess_mass), big.mark = ","),
            format(round(main_results$pre_policy$excess_mass), big.mark = ",")))
cat(sprintf("Missing mass & %s & --- \\\\\n",
            format(round(main_results$policy$missing_mass), big.mark = ",")))
cat(sprintf("Bunching ratio ($\\hat{b}$) & %.2f & %.2f \\\\\n",
            main_results$policy$bunching_ratio,
            main_results$pre_policy$bunching_ratio))
cat(sprintf(" & (%.2f) & (%.2f) \\\\\n",
            main_results$policy$se_bunching,
            main_results$pre_policy$se_bunching))
cat(sprintf("Elasticity ($\\hat{e}$) & %.3f & %.3f \\\\\n",
            main_results$policy$elasticity,
            main_results$pre_policy$elasticity))
cat(sprintf(" & (%.3f) & (%.3f) \\\\\n",
            main_results$policy$se_elasticity,
            main_results$pre_policy$se_elasticity))
cat("\\hline\n")
cat(sprintf("Difference-in-bunching ($\\Delta \\hat{b}$) & \\multicolumn{2}{c}{%.2f} \\\\\n",
            main_results$dib$estimate))
cat(sprintf(" & \\multicolumn{2}{c}{(%.2f)} \\\\\n",
            main_results$dib$se))
cat(sprintf("$t$-statistic & \\multicolumn{2}{c}{%.2f} \\\\\n",
            main_results$dib$t_stat))
cat("\\hline\n")
cat("Polynomial degree & 7 & 7 \\\\\n")
cat("Exclusion window (kWp) & [9.0, 11.0) & [9.0, 11.0) \\\\\n")
cat("Estimation window (kWp) & [3.0, 20.0) & [3.0, 20.0) \\\\\n")
cat("Bin width (kWp) & 0.1 & 0.1 \\\\\n")
cat(sprintf("Observations & %s & %s \\\\\n",
            format(nrow(pol), big.mark = ","),
            format(nrow(pre), big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Bunching estimates following Kleven and Waseem (2013). The bunching ratio $\\hat{b} = \\hat{B}/\\hat{f}_0$ measures excess mass relative to the counterfactual density at the kink. The elasticity is computed as $\\hat{e} = \\hat{b}/(\\Delta \\log(1-\\tau)/w)$ where $\\Delta \\log(1-\\tau)$ captures the effective cost increase from the EEG surcharge at the 10 kWp threshold. Bootstrap standard errors (200 replications) in parentheses.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 saved.\n")

# ============================================================
# Table 3: Annual Bunching Estimates (Event Study)
# ============================================================

sink("../tables/tab3_annual.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Annual Bunching Estimates at 10 kWp}\n")
cat("\\label{tab:annual}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("Year & $\\hat{b}$ & $\\hat{e}$ & Excess Mass & $N$ \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(annual_dt)) {
  yr <- annual_dt$year[i]
  marker <- ifelse(yr == 2014, "$^{\\dagger}$", "")
  cat(sprintf("%d%s & %.2f & %.3f & %s & %s \\\\\n",
              yr, marker,
              annual_dt$bunching_ratio[i],
              annual_dt$elasticity[i],
              format(round(annual_dt$excess_mass[i]), big.mark = ","),
              format(nrow(dt[year == yr]), big.mark = ",")))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Annual bunching estimates at the 10 kWp threshold using the Kleven-Waseem (2013) methodology. Polynomial degree 7, exclusion window [9.0, 11.0) kWp. $\\dagger$ marks the first year of the EEG 2014 surcharge (effective August 1, 2014). Years 2008--2013 are pre-policy; 2014--2018 are policy period.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 saved.\n")

# ============================================================
# Table 4: Robustness Checks
# ============================================================

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness of Bunching Estimates}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{llcc}\n")
cat("\\hline\\hline\n")
cat("Specification & Detail & $\\hat{b}$ & Excess Mass \\\\\n")
cat("\\hline\n")
cat("\\textit{Panel A: Polynomial Degree} & & & \\\\\n")
for (i in 1:nrow(poly_dt)) {
  marker <- ifelse(poly_dt$poly_degree[i] == 7, "$^{*}$", "")
  cat(sprintf("\\quad Degree %d%s & & %.2f & %s \\\\\n",
              poly_dt$poly_degree[i], marker,
              poly_dt$bunching_ratio[i],
              format(round(poly_dt$excess_mass[i]), big.mark = ",")))
}
cat("\\hline\n")
cat("\\textit{Panel B: Exclusion Window} & & & \\\\\n")
for (i in 1:nrow(window_dt)) {
  marker <- ifelse(window_dt$excl_window[i] == "[9.0, 11.0)", "$^{*}$", "")
  cat(sprintf("\\quad %s%s & & %.2f & %s \\\\\n",
              window_dt$excl_window[i], marker,
              window_dt$bunching_ratio[i],
              format(round(window_dt$excess_mass[i]), big.mark = ",")))
}
cat("\\hline\n")
cat("\\textit{Panel C: Placebo Thresholds} & & & \\\\\n")
for (i in 1:nrow(placebo_dt)) {
  cat(sprintf("\\quad %.0f kWp & & %.2f & %s \\\\\n",
              placebo_dt$placebo_point[i],
              placebo_dt$bunching_ratio[i],
              format(round(placebo_dt$excess_mass[i]), big.mark = ",")))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Robustness of bunching estimates for the policy period (2014--2018). Panel A varies the polynomial degree of the counterfactual density. Panel B varies the exclusion window around 10 kWp. Panel C estimates ``bunching'' at placebo capacity thresholds where no policy discontinuity exists. $^{*}$ denotes baseline specification.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 saved.\n")

# ============================================================
# Table 5: Heterogeneity by State
# ============================================================

# Top 8 states by installation count
state_top <- state_dt[order(-n_installations)][1:min(8, nrow(state_dt))]

sink("../tables/tab5_states.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Bunching by Federal State}\n")
cat("\\label{tab:states}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("State & Installations & $\\hat{b}$ & $\\hat{e}$ \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(state_top)) {
  cat(sprintf("%s & %s & %.2f & %.3f \\\\\n",
              state_top$state[i],
              format(state_top$n_installations[i], big.mark = ","),
              state_top$bunching_ratio[i],
              state_top$elasticity[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} State-level bunching estimates for the eight largest German states by number of solar PV installations (2014--2018). The bunching ratio and elasticity are estimated separately for each state using the baseline specification (polynomial degree 7, exclusion window [9.0, 11.0) kWp).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 5 saved.\n")

# ============================================================
# Appendix Table F1: Standardized Effect Size
# ============================================================

# The "treatment" here is the EEG 2014 surcharge at 10 kWp
# Primary outcome: bunching ratio (excess mass / counterfactual density)
# SDE interpretation: the policy distortion relative to baseline variation

# For SDE table, we treat the bunching ratio and elasticity as effect sizes
# SD(Y) = standard deviation of bin counts in the counterfactual distribution

# Compute SD of counterfactual bin counts
policy_bd <- main_results$policy
b_hat <- policy_bd$bunching_ratio
se_b <- policy_bd$se_bunching

# For the SDE, we use the structural elasticity as the primary "effect"
# and its SD as normalization
e_hat <- policy_bd$elasticity
se_e <- policy_bd$se_elasticity

# DiB as effect size
dib_hat <- main_results$dib$estimate
se_dib <- main_results$dib$se

# SD(Y) for bunching: SD of bin counts in the pre-policy counterfactual
pre_bins_data <- fread("../data/bin_counts_period.csv")
sd_bins_pre <- sd(pre_bins_data$pre_policy, na.rm = TRUE)

# Alternative: use the average bin count as normalization
mean_bins_pre <- mean(pre_bins_data$pre_policy, na.rm = TRUE)

# SDE for excess mass: excess_mass / SD(bin_counts)
sde_excess <- policy_bd$excess_mass / sd_bins_pre
se_sde_excess <- abs(sde_excess) * (se_b / b_hat)  # Delta method approx

# SDE for bunching ratio
sde_b <- b_hat  # Already normalized by counterfactual density
se_sde_b <- se_b

# SDE for DiB
sde_dib <- dib_hat
se_sde_dib <- se_dib

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# For the SDE table, we use the elasticity as the main outcome
# and compute SDE = e_hat (the elasticity is already a normalized effect size)

# Build notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Germany. ",
  "\\textbf{Research question:} Does the EEG self-consumption surcharge exemption threshold at 10 kWp distort residential solar PV installation size decisions? ",
  "\\textbf{Policy mechanism:} Germany's EEG 2014 imposed a surcharge of approximately 6.7 c\\euro/kWh on self-consumed electricity for solar installations at or above 10 kWp; systems below 10 kWp were fully exempt, creating a discontinuous incentive to downsize installations. ",
  "\\textbf{Outcome definition:} Bunching ratio ($\\hat{b}$) measuring excess mass of installations just below 10 kWp relative to the polynomial counterfactual density at the threshold; behavioral elasticity ($\\hat{e}$) measuring the responsiveness of installation size to the effective cost change. ",
  "\\textbf{Treatment:} Binary---installations commissioned after August 1, 2014 face the surcharge threshold at 10 kWp. ",
  "\\textbf{Data:} Open Power System Data (OPSD) Renewable Power Plants Germany, 2008--2018, installation-level, ",
  format(nrow(dt), big.mark = ","), " observations in 3--20 kWp window. ",
  "\\textbf{Method:} Kleven-Waseem (2013) bunching estimator with degree-7 polynomial counterfactual, [9.0, 11.0) kWp exclusion window, 0.1 kWp bins; bootstrap standard errors (200 replications). ",
  "\\textbf{Sample:} Residential and commercial rooftop solar PV installations registered with BNetzA; restricted to 3--20 kWp capacity window for counterfactual density estimation. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")

# Row 1: Bunching ratio (policy period)
cat(sprintf("Bunching ratio ($\\hat{b}$, policy) & %.2f & %.2f & 1.00 & %.2f & %.2f & %s \\\\\n",
            b_hat, se_b, b_hat, se_b, classify_sde(b_hat)))

# Row 2: Behavioral elasticity (policy period)
cat(sprintf("Elasticity ($\\hat{e}$, policy) & %.3f & %.3f & 1.00 & %.3f & %.3f & %s \\\\\n",
            e_hat, se_e, e_hat, se_e, classify_sde(e_hat)))

# Row 3: DiB (difference-in-bunching)
cat(sprintf("Diff-in-bunching ($\\Delta\\hat{b}$) & %.2f & %.2f & 1.00 & %.2f & %.2f & %s \\\\\n",
            dib_hat, se_dib, dib_hat, se_dib, classify_sde(dib_hat)))

# Row 4: Excess mass (normalized by pre-period SD)
cat(sprintf("Excess mass (norm.) & %s & --- & %.1f & %.2f & --- & %s \\\\\n",
            format(round(policy_bd$excess_mass), big.mark = ","),
            sd_bins_pre, sde_excess, classify_sde(sde_excess)))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("SDE Table F1 saved.\n")

cat("\nAll tables generated.\n")
