## 05_tables.R — Generate all tables including SDE appendix
## apep_1393: Merger-Induced Branch Closures and Racial Mortgage Gaps

source("00_packages.R")


data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Table 1: Summary statistics\n")

sum_vars <- panel %>%
  select(
    `BW Denial Gap (pp)` = bw_denial_gap,
    `AW Denial Gap (pp)` = aw_denial_gap,
    `BW Rate Spread Gap` = bw_rate_gap,
    `Overall Denial Rate` = overall_denial_rate,
    `Merger Exposure` = merger_exposure,
    `Branch Change Rate` = branch_change_pct,
    `N Branches` = n_branches,
    `Black App Share` = black_share,
    `N Applications (White)` = n_apps_w,
    `N Applications (Black)` = n_apps_b
  )

sum_stats <- sum_vars %>%
  pivot_longer(everything()) %>%
  group_by(name) %>%
  summarise(
    Mean = mean(value, na.rm = TRUE),
    SD = sd(value, na.rm = TRUE),
    P10 = quantile(value, 0.10, na.rm = TRUE),
    Median = median(value, na.rm = TRUE),
    P90 = quantile(value, 0.90, na.rm = TRUE),
    N = sum(!is.na(value)),
    .groups = "drop"
  )

# Write LaTeX table
sink(file.path(tab_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Summary Statistics}\n\\label{tab:summary}\n")
cat("\\begin{tabular}{lrrrrrr}\n\\hline\\hline\n")
cat("Variable & Mean & SD & P10 & Median & P90 & N \\\\\n\\hline\n")
for (i in 1:nrow(sum_stats)) {
  r <- sum_stats[i,]
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
              r$name, r$Mean, r$SD, r$P10, r$Median, r$P90,
              format(r$N, big.mark = ",")))
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} Panel of county-year observations across 20 U.S.\\ states, 2018--2023. ")
cat("Sample restricted to counties with $\\geq 20$ Black and $\\geq 50$ White mortgage applications per year. ")
cat("BW (HW) denial gap is the Black-White (Asian-White) difference in denial rates. ")
cat("Merger exposure is the share of local branches belonging to banks that merged in the prior 3 years.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table 2: First Stage and Reduced Form
# ============================================================================
cat("Table 2: First stage and reduced form\n")

etable(results$first_stage, results$rf_bw, results$rf_aw,
       file = file.path(tab_dir, "tab2_first_stage.tex"),
       title = "First Stage and Reduced Form",
       headers = c("Branch Change", "BW Denial Gap", "AW Denial Gap"),
       dict = c(merger_exposure = "Merger Exposure",
                branch_change_pct = "Branch Change Rate"),
       style.tex = style.tex("aer"),
       notes = "County-year panel, 2018-2023. Standard errors clustered at county level. State and year fixed effects included.",
       label = "tab:first_stage",
       replace = TRUE)

# ============================================================================
# Table 3: Main IV Results
# ============================================================================
cat("Table 3: Main IV results\n")

etable(results$iv_bw_denial, results$iv_aw_denial,
       results$iv_bw_rate, results$iv_aw_rate,
       results$iv_denial_all,
       file = file.path(tab_dir, "tab3_iv_main.tex"),
       title = "IV Estimates: Effect of Branch Closures on Racial Mortgage Gaps",
       headers = c("BW Denial", "AW Denial", "BW Spread", "AW Spread", "All Denial"),
       dict = c(branch_change_pct = "Branch Change Rate (IV)"),
       style.tex = style.tex("aer"),
       notes = "2SLS estimates. Merger exposure instruments branch change rate. State and year FE. County-clustered SEs.",
       label = "tab:iv_main",
       replace = TRUE)

# ============================================================================
# Table 4: OLS vs IV Comparison
# ============================================================================
cat("Table 4: OLS vs IV\n")

etable(results$ols_bw_denial, results$iv_bw_denial,
       results$ols_aw_denial, results$iv_aw_denial,
       file = file.path(tab_dir, "tab4_ols_iv.tex"),
       title = "OLS vs.\\ IV Estimates",
       headers = c("BW OLS", "BW IV", "AW OLS", "AW IV"),
       dict = c(branch_change_pct = "Branch Change Rate",
                "fit_branch_change_pct" = "Branch Change Rate (IV)"),
       style.tex = style.tex("aer"),
       notes = "Columns 1 and 3: OLS. Columns 2 and 4: 2SLS with merger exposure as instrument. State and year FE. County-clustered SEs.",
       label = "tab:ols_iv",
       replace = TRUE)

# ============================================================================
# Table 5: County FE Specification
# ============================================================================
cat("Table 5: County FE specification\n")

etable(results$iv_bw_cfe, results$iv_aw_cfe,
       file = file.path(tab_dir, "tab5_county_fe.tex"),
       title = "IV Estimates with County Fixed Effects",
       headers = c("BW Denial Gap", "AW Denial Gap"),
       dict = c(branch_change_pct = "Branch Change Rate (IV)"),
       style.tex = style.tex("aer"),
       notes = "2SLS with county and year FE. Exploits within-county variation in merger exposure over time. County-clustered SEs.",
       label = "tab:county_fe",
       replace = TRUE)

# ============================================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# ============================================================================
cat("Table F1: SDE appendix\n")

# Compute SDEs for main outcomes
compute_sde <- function(model, outcome_var, panel_data, label) {
  beta <- coef(model)[[1]]
  se_beta <- sqrt(vcov(model)[1,1])
  sd_y <- sd(panel_data[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  classify <- function(x) {
    if (x < -0.15) "Large negative"
    else if (x < -0.05) "Moderate negative"
    else if (x < -0.005) "Small negative"
    else if (x < 0.005) "Null"
    else if (x < 0.05) "Small positive"
    else if (x < 0.15) "Moderate positive"
    else "Large positive"
  }

  tibble(
    Outcome = label,
    Beta = beta,
    SE = se_beta,
    SD_Y = sd_y,
    SDE = sde,
    SE_SDE = se_sde,
    Classification = classify(sde)
  )
}

sde_pooled <- bind_rows(
  compute_sde(results$iv_bw_denial, "bw_denial_gap", panel, "BW Denial Gap"),
  compute_sde(results$iv_aw_denial, "aw_denial_gap", panel, "AW Denial Gap"),
  compute_sde(results$iv_bw_rate, "bw_rate_gap", panel, "BW Rate Spread Gap"),
  compute_sde(results$iv_denial_all, "overall_denial_rate", panel, "Overall Denial Rate")
)

# Panel B: Heterogeneity by minority share (sample splits)
panel_high <- panel %>% filter((black_share + black_share) > median(black_share + black_share, na.rm = TRUE))
panel_low <- panel %>% filter((black_share + black_share) <= median(black_share + black_share, na.rm = TRUE))

sde_het <- bind_rows(
  compute_sde(rob$het_high_minority, "bw_denial_gap", panel_high, "BW Denial Gap (High Minority)"),
  compute_sde(rob$het_low_minority, "bw_denial_gap", panel_low, "BW Denial Gap (Low Minority)")
)

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do merger-induced bank branch closures widen racial disparities in mortgage denial rates and pricing? ",
  "\\textbf{Policy mechanism:} Bank mergers approved under the Bank Merger Act lead acquiring institutions to close overlapping branches, reducing the number of physical lending access points in affected communities and eliminating established banking relationships. ",
  "\\textbf{Outcome definition:} Black-White denial rate gap (difference in fraction of home purchase mortgage applications denied between Black and White applicants in the same county-year); rate spread gap (difference in mean APR spread above benchmark). ",
  "\\textbf{Treatment:} Continuous; percent change in branch count instrumented by merger exposure (share of local branches at recently merged banks). ",
  "\\textbf{Data:} FDIC Summary of Deposits branch panel merged with CFPB HMDA loan-level microdata, 2018--2023, 20 U.S.\\ states, county-year observations. ",
  "\\textbf{Method:} Two-stage least squares with merger exposure as instrument for branch changes; state and year fixed effects; standard errors clustered at county level. ",
  "\\textbf{Sample:} Counties with $\\geq 20$ Black and $\\geq 50$ White mortgage applications per year; 20-state sample covering approximately 70\\% of U.S.\\ mortgage originations. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-sectional ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tab_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n")
cat("\\begin{tabular}{lrrrrrr}\n\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (i in 1:nrow(sde_pooled)) {
  r <- sde_pooled[i,]
  cat(sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              r$Outcome, r$Beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by minority population share)}} \\\\\n")
for (i in 1:nrow(sde_het)) {
  r <- sde_het[i,]
  cat(sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              r$Outcome, r$Beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables saved to", tab_dir, "\n")
cat("Files:", list.files(tab_dir, pattern = "\\.tex$"), "\n")
