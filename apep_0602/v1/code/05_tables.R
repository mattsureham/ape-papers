## 05_tables.R — Generate all LaTeX tables
## apep_0602: CDR Threshold and For-Profit College Behavior

library(tidyverse)

set.seed(20260312)

analysis <- readRDS("data/analysis_panel.rds")
main_results <- readRDS("data/main_results.rds")
robustness <- readRDS("data/robustness_results.rds")

if (!dir.exists("tables")) dir.create("tables")

# Helper: format p-value stars
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# Helper: format number
fmt <- function(x, digits = 3) {
  if (is.na(x)) return("---")
  formatC(round(x, digits), format = "f", digits = digits)
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

# Split by above/below 30%
below <- analysis %>% filter(above_30 == 0)
above <- analysis %>% filter(above_30 == 1)

# Focus on bandwidth sample
bw <- main_results$enrollment$bw_left
bw_below <- analysis %>% filter(cdr3_pct >= (30 - bw) & cdr3_pct < 30)
bw_above <- analysis %>% filter(cdr3_pct >= 30 & cdr3_pct <= (30 + bw))

summ_vars <- list(
  list(var = "cdr3_pct", label = "Cohort Default Rate (\\%)"),
  list(var = "total_enrollment", label = "Total Enrollment"),
  list(var = "completion_rate", label = "Completion Rate"),
  list(var = "pell_share", label = "Pell Recipient Share"),
  list(var = "closed_3yr", label = "Closed Within 3 Years"),
  list(var = "cdr3_denom", label = "CDR Cohort Size")
)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: For-Profit Institutions by CDR Position}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Full Sample} & \\multicolumn{3}{c}{Bandwidth Sample} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Below 30\\% & Above 30\\% & Diff. & Below 30\\% & Above 30\\% & Diff. \\\\",
  "\\midrule"
)

for (v in summ_vars) {
  b_full <- below[[v$var]]
  a_full <- above[[v$var]]
  b_bw <- bw_below[[v$var]]
  a_bw <- bw_above[[v$var]]

  m_b <- mean(b_full, na.rm = TRUE)
  m_a <- mean(a_full, na.rm = TRUE)
  m_b_bw <- mean(b_bw, na.rm = TRUE)
  m_a_bw <- mean(a_bw, na.rm = TRUE)

  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    v$label,
    fmt(m_b), fmt(m_a), fmt(m_a - m_b),
    fmt(m_b_bw), fmt(m_a_bw), fmt(m_a_bw - m_b_bw)
  ))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Observations & %s & %s & & %s & %s & \\\\",
          formatC(nrow(below), big.mark = ","),
          formatC(nrow(above), big.mark = ","),
          formatC(nrow(bw_below), big.mark = ","),
          formatC(nrow(bw_above), big.mark = ",")),
  sprintf("Institutions & %s & %s & & %s & %s & \\\\",
          formatC(n_distinct(below$unitid), big.mark = ","),
          formatC(n_distinct(above$unitid), big.mark = ","),
          formatC(n_distinct(bw_below$unitid), big.mark = ","),
          formatC(n_distinct(bw_above$unitid), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  paste0("\\begin{minipage}{0.95\\textwidth}"),
  paste0("\\vspace{0.5em}\\footnotesize"),
  paste0("\\textit{Notes:} Summary statistics for for-profit postsecondary institutions with CDR cohort size $\\geq$ 30, fiscal years 2009--2019. ",
         "``Bandwidth Sample'' restricts to institutions within the CCT optimal bandwidth of the 30\\% cutoff. ",
         "CDR is the 3-year cohort default rate from the College Scorecard. Enrollment is total 12-month unduplicated headcount from IPEDS. ",
         "Completion rate is total completions divided by enrollment. Pell share is the fraction of enrolled students receiving Pell Grants. ",
         "Closure indicates the institution ceased operations within 3 years."),
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")

# ============================================================
# TABLE 2: Main RDD Results
# ============================================================
cat("Generating Table 2: Main RDD Results...\n")

outcomes <- c("enrollment", "completion", "closure", "pell_share")
outcome_labels <- c("Log Enrollment", "Completion Rate", "3-Year Closure", "Pell Share")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Crossing the 30\\% CDR Threshold on Institutional Outcomes}",
  "\\label{tab:main_rdd}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  sprintf(" & %s \\\\", paste(outcome_labels, collapse = " & ")),
  "\\midrule"
)

# Conventional estimate
coefs <- sapply(outcomes, function(o) {
  r <- main_results[[o]]
  sprintf("%s%s", fmt(r$coef_conv, 3), stars(r$pv_conv))
})
tab2_lines <- c(tab2_lines, sprintf("Above 30\\%% & %s \\\\", paste(coefs, collapse = " & ")))

# SE
ses <- sapply(outcomes, function(o) sprintf("(%s)", fmt(main_results[[o]]$se_conv, 3)))
tab2_lines <- c(tab2_lines, sprintf(" & %s \\\\", paste(ses, collapse = " & ")))

# Bias-corrected estimate
tab2_lines <- c(tab2_lines, "[0.5em]")
coefs_bc <- sapply(outcomes, function(o) {
  r <- main_results[[o]]
  sprintf("%s%s", fmt(r$coef_bc, 3), stars(r$pv_bc))
})
tab2_lines <- c(tab2_lines, sprintf("Bias-corrected & %s \\\\", paste(coefs_bc, collapse = " & ")))

ses_bc <- sapply(outcomes, function(o) sprintf("(%s)", fmt(main_results[[o]]$se_robust, 3)))
tab2_lines <- c(tab2_lines, sprintf(" & %s \\\\", paste(ses_bc, collapse = " & ")))

# Robust CI
cis <- sapply(outcomes, function(o) {
  r <- main_results[[o]]
  sprintf("[%s, %s]", fmt(r$ci_lower, 3), fmt(r$ci_upper, 3))
})
tab2_lines <- c(tab2_lines, sprintf("95\\%% Robust CI & %s \\\\", paste(cis, collapse = " & ")))

# Bandwidth and N
bws <- sapply(outcomes, function(o) fmt(main_results[[o]]$bw_left, 1))
tab2_lines <- c(tab2_lines, "\\midrule")
tab2_lines <- c(tab2_lines, sprintf("Bandwidth (pp) & %s \\\\", paste(bws, collapse = " & ")))

n_effs <- sapply(outcomes, function(o) {
  r <- main_results[[o]]
  formatC(r$N_left + r$N_right, big.mark = ",")
})
tab2_lines <- c(tab2_lines, sprintf("Eff. observations & %s \\\\", paste(n_effs, collapse = " & ")))

# Mean below cutoff
means <- sapply(outcomes, function(o) {
  var_name <- switch(o,
    enrollment = "log_enrollment",
    completion = "completion_rate",
    closure = "closed_3yr",
    pell_share = "pell_share"
  )
  bw_val <- main_results[[o]]$bw_left
  samp <- analysis %>%
    filter(cdr3_pct >= (30 - bw_val) & cdr3_pct < 30, !is.na(.data[[var_name]]))
  fmt(mean(samp[[var_name]], na.rm = TRUE), 3)
})
tab2_lines <- c(tab2_lines, sprintf("Mean below cutoff & %s \\\\", paste(means, collapse = " & ")))

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.5em}\\footnotesize",
  paste0("\\textit{Notes:} Local polynomial RDD estimates at the 30\\% cohort default rate threshold. ",
         "Running variable is the 3-year CDR from the College Scorecard. ",
         "Estimation uses a local linear specification with triangular kernel and CCT optimal bandwidth. ",
         "Conventional, bias-corrected, and robust inference reported following \\citet{cattaneo2020}. ",
         "Sample restricted to for-profit institutions with CDR cohort size $\\geq$ 30, fiscal years 2009--2019. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main_rdd.tex")

# ============================================================
# TABLE 3: Robustness — Bandwidth Sensitivity
# ============================================================
cat("Generating Table 3: Bandwidth Sensitivity...\n")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Bandwidth Sensitivity: Effect on Log Enrollment}",
  "\\label{tab:bw_sensitivity}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "& 0.5$\\times$ & 0.75$\\times$ & 1.0$\\times$ & 1.25$\\times$ & 1.5$\\times$ & 2.0$\\times$ \\\\",
  "\\midrule"
)

coefs_bw <- sapply(names(robustness$bandwidth_sensitivity), function(m) {
  r <- robustness$bandwidth_sensitivity[[m]]
  sprintf("%s%s", fmt(r$coef, 3), stars(r$pv))
})
tab3_lines <- c(tab3_lines, sprintf("Above 30\\%% & %s \\\\", paste(coefs_bw, collapse = " & ")))

ses_bw <- sapply(names(robustness$bandwidth_sensitivity), function(m) {
  sprintf("(%s)", fmt(robustness$bandwidth_sensitivity[[m]]$se, 3))
})
tab3_lines <- c(tab3_lines, sprintf(" & %s \\\\", paste(ses_bw, collapse = " & ")))

bws_bw <- sapply(names(robustness$bandwidth_sensitivity), function(m) {
  fmt(robustness$bandwidth_sensitivity[[m]]$bandwidth, 1)
})
tab3_lines <- c(tab3_lines, "\\midrule")
tab3_lines <- c(tab3_lines, sprintf("Bandwidth (pp) & %s \\\\", paste(bws_bw, collapse = " & ")))

ns_bw <- sapply(names(robustness$bandwidth_sensitivity), function(m) {
  r <- robustness$bandwidth_sensitivity[[m]]
  formatC(r$n_left + r$n_right, big.mark = ",")
})
tab3_lines <- c(tab3_lines, sprintf("Observations & %s \\\\", paste(ns_bw, collapse = " & ")))

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.5em}\\footnotesize",
  paste0("\\textit{Notes:} RDD estimates of the 30\\% CDR threshold effect on log enrollment, ",
         "varying the bandwidth as a multiple of the CCT optimal bandwidth. ",
         "Bias-corrected point estimates with robust standard errors in parentheses. ",
         "Triangular kernel. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_bw_sensitivity.tex")

# ============================================================
# TABLE 4: Placebo and Validity Tests
# ============================================================
cat("Generating Table 4: Placebo and Validity...\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Validity Tests: McCrary Density, Covariate Balance, and Placebo Cutoffs}",
  "\\label{tab:validity}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Test & Estimate & $p$-value \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Density and Balance}} \\\\[0.3em]",
  sprintf("McCrary density test & %s & %s \\\\",
          fmt(main_results$density$test_stat, 3),
          fmt(main_results$density$p_value, 3)),
  sprintf("Covariate: Log cohort size & %s & %s \\\\",
          fmt(main_results$cohort_balance$coef, 3),
          fmt(main_results$cohort_balance$pv, 3)),
  "[0.5em]",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo Cutoffs (Log Enrollment)}} \\\\[0.3em]"
)

for (pc in names(robustness$placebo_cutoffs)) {
  r <- robustness$placebo_cutoffs[[pc]]
  tab4_lines <- c(tab4_lines,
    sprintf("Cutoff at %s\\%% & %s & %s \\\\",
            pc, fmt(r$coef, 3), fmt(r$pv, 3)))
}

# Add donut-hole results
tab4_lines <- c(tab4_lines,
  "[0.5em]",
  "\\multicolumn{3}{l}{\\textit{Panel C: Donut-Hole RDD (Log Enrollment)}} \\\\[0.3em]"
)

for (d in names(robustness$donut_hole)) {
  r <- robustness$donut_hole[[d]]
  tab4_lines <- c(tab4_lines,
    sprintf("Exclude $\\pm$%spp & %s%s & %s \\\\",
            d, fmt(r$coef, 3), stars(r$pv), fmt(r$pv, 3)))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.5em}\\footnotesize",
  paste0("\\textit{Notes:} Panel A reports the McCrary (2008) density test at 30\\% and an RDD balance test ",
         "using log CDR cohort size as the outcome. Panel B reports RDD estimates at placebo cutoffs where ",
         "no regulatory threshold exists. Panel C excludes observations within the specified distance of the ",
         "30\\% cutoff to address potential manipulation. Bias-corrected estimates with robust standard errors. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_validity.tex")

# ============================================================
# TABLE F1: Standardized Effect Size Appendix (MANDATORY)
# ============================================================
cat("Generating Table F1: Standardized Effect Sizes...\n")

# Compute SD(Y) for each outcome below the cutoff (within bandwidth)
bw_val <- main_results$enrollment$bw_left
bw_data <- analysis %>% filter(cdr3_pct >= (30 - bw_val) & cdr3_pct < 30)

sde_data <- list(
  list(
    outcome = "Log Enrollment",
    beta = main_results$enrollment$coef_bc,
    se = main_results$enrollment$se_robust,
    sd_y = sd(bw_data$log_enrollment, na.rm = TRUE)
  ),
  list(
    outcome = "Completion Rate",
    beta = main_results$completion$coef_bc,
    se = main_results$completion$se_robust,
    sd_y = sd(bw_data$completion_rate, na.rm = TRUE)
  ),
  list(
    outcome = "3-Year Closure",
    beta = main_results$closure$coef_bc,
    se = main_results$closure$se_robust,
    sd_y = sd(bw_data$closed_3yr, na.rm = TRUE)
  ),
  list(
    outcome = "Pell Share",
    beta = main_results$pell_share$coef_bc,
    se = main_results$pell_share$se_robust,
    sd_y = sd(bw_data$pell_share, na.rm = TRUE)
  )
)

classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (s in sde_data) {
  sde <- s$beta / s$sd_y
  se_sde <- s$se / s$sd_y
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            s$outcome, fmt(s$beta, 3), fmt(s$se, 3), fmt(s$sd_y, 3),
            fmt(sde, 3), fmt(se_sde, 3), classify_sde(sde)))
}

n_obs <- nrow(analysis)
n_inst <- n_distinct(analysis$unitid)

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.5em}\\footnotesize",
  paste0("\\textit{Notes:} Standardized effect sizes (SDE $= \\hat{\\beta} / \\text{SD}(Y)$) for the main outcomes ",
         "of crossing the 30\\% cohort default rate threshold. ",
         "This is a binary treatment (above vs.\\ below 30\\%), so SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
         "SD($Y$) computed among below-cutoff institutions within the CCT optimal bandwidth. ",
         "Bias-corrected RDD estimates with robust standard errors following \\citet{cattaneo2020}. ",
         sprintf("Sample: %s for-profit institution-year observations (%s unique institutions), FY 2009--2019. ",
                 formatC(n_obs, big.mark = ","), formatC(n_inst, big.mark = ",")),
         "Classification is based on the magnitude of the SDE point estimate, not statistical significance. ",
         "Buckets: Large ($|$SDE$|>0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($|$SDE$|<0.005$)."),
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
