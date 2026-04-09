# 05_tables.R — Generate all LaTeX tables for HACRP RDD paper
source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

analysis <- readRDS(file.path(data_dir, "analysis.rds"))
cutoff <- readRDS(file.path(data_dir, "cutoff.rds"))
results <- readRDS(file.path(data_dir, "results.rds"))
bw_sens <- readRDS(file.path(data_dir, "bw_sensitivity.rds"))

# Helper: format stars
fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits)
fmt_paren <- function(x, digits = 3) paste0("(", fmt(x, digits), ")")
stars_p <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

analysis[, stars := as.numeric(hospital_overall_rating)]
analysis[, safety_worse := as.numeric(count_of_safety_measures_worse)]
analysis[, is_nonprofit := as.integer(grepl("Voluntary|Non-Profit", hospital_ownership, ignore.case = TRUE))]
analysis[, is_forprofit := as.integer(grepl("Proprietary|For-Profit", hospital_ownership, ignore.case = TRUE))]
analysis[, is_government := as.integer(grepl("Government", hospital_ownership, ignore.case = TRUE))]
analysis[, has_emergency := as.integer(emergency_services == "Yes")]

# Define variables
summ_vars <- c("total_hac_score", "psi_90_w_z_score", "clabsi_w_z_score",
               "cauti_w_z_score", "ssi_w_z_score", "cdi_w_z_score",
               "mrsa_w_z_score", "stars", "safety_worse",
               "is_nonprofit", "is_forprofit", "is_government", "has_emergency")
summ_labels <- c("Total HAC Score", "PSI-90 Z-Score", "CLABSI Z-Score",
                 "CAUTI Z-Score", "SSI Z-Score", "C. diff Z-Score",
                 "MRSA Z-Score", "Overall Star Rating", "Safety Measures Worse",
                 "Nonprofit", "For-Profit", "Government", "Emergency Services")

# Full sample, penalized, not penalized
tab1_lines <- c()
tab1_lines <- c(tab1_lines,
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: HACRP-Eligible Hospitals, FY2026}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "& \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Not Penalized} & \\multicolumn{2}{c}{Penalized} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "& Mean & SD & Mean & SD & Mean & SD \\\\"
)
tab1_lines <- c(tab1_lines, "\\midrule")
tab1_lines <- c(tab1_lines, "\\addlinespace[3pt]",
  "\\multicolumn{7}{l}{\\textit{Panel A: HAC Scores}} \\\\",
  "\\addlinespace[2pt]")

for (i in 1:7) {
  v <- summ_vars[i]
  l <- summ_labels[i]
  vals <- analysis[[v]]
  pen_vals <- analysis[penalized == 1][[v]]
  nopen_vals <- analysis[penalized == 0][[v]]
  line <- sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    l,
    fmt(mean(vals, na.rm = TRUE)), fmt(sd(vals, na.rm = TRUE)),
    fmt(mean(nopen_vals, na.rm = TRUE)), fmt(sd(nopen_vals, na.rm = TRUE)),
    fmt(mean(pen_vals, na.rm = TRUE)), fmt(sd(pen_vals, na.rm = TRUE)))
  tab1_lines <- c(tab1_lines, line)
}

tab1_lines <- c(tab1_lines, "\\addlinespace[3pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Hospital Characteristics}} \\\\",
  "\\addlinespace[2pt]")

for (i in 8:13) {
  v <- summ_vars[i]
  l <- summ_labels[i]
  vals <- analysis[[v]]
  pen_vals <- analysis[penalized == 1][[v]]
  nopen_vals <- analysis[penalized == 0][[v]]
  line <- sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    l,
    fmt(mean(vals, na.rm = TRUE)), fmt(sd(vals, na.rm = TRUE)),
    fmt(mean(nopen_vals, na.rm = TRUE)), fmt(sd(nopen_vals, na.rm = TRUE)),
    fmt(mean(pen_vals, na.rm = TRUE)), fmt(sd(pen_vals, na.rm = TRUE)))
  tab1_lines <- c(tab1_lines, line)
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Observations & %d & & %d & & %d & \\\\",
    nrow(analysis), sum(analysis$penalized == 0), sum(analysis$penalized == 1)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Data from CMS Hospital-Acquired Condition Reduction Program FY2026 results and Hospital Compare. Total HAC Score is the equally weighted average of six domain-specific Winsorized z-scores. Hospitals with Total HAC Score above the 75th percentile (0.379) receive a 1\\% Medicare payment reduction. Star ratings range from 1 to 5. HAI SIRs are Standardized Infection Ratios where 1.0 equals the national benchmark.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1_lines, file.path(table_dir, "tab1_sumstats.tex"))

# ============================================================
# Table 2: Main RDD Results
# ============================================================
cat("=== Table 2: Main RDD Results ===\n")

# Rerun RDD for each outcome to get consistent format
run_rdd <- function(y, x, label) {
  valid <- !is.na(y) & !is.na(x)
  rdd <- tryCatch({
    rdrobust(y = y[valid], x = x[valid], c = 0, kernel = "triangular", bwselect = "mserd")
  }, error = function(e) NULL)
  if (is.null(rdd)) return(NULL)
  list(
    label = label,
    coef = rdd$coef[1],
    se_conv = rdd$se[1],
    se_robust = rdd$se[3],
    pval_robust = rdd$pv[3],
    bw = rdd$bws[1, 1],
    n_left = rdd$N_h[1],
    n_right = rdd$N_h[2],
    mean_left = mean(y[valid & x < 0], na.rm = TRUE)
  )
}

outcomes <- list(
  run_rdd(analysis$stars, analysis$score_centered, "Star Rating (1--5)"),
  run_rdd(analysis$safety_worse, analysis$score_centered, "Safety Measures Worse"),
  run_rdd(as.numeric(analysis$HAI_1_SIR), analysis$score_centered, "CLABSI SIR"),
  run_rdd(as.numeric(analysis$HAI_2_SIR), analysis$score_centered, "CAUTI SIR"),
  run_rdd(as.numeric(analysis$HAI_5_SIR), analysis$score_centered, "MRSA SIR"),
  run_rdd(as.numeric(analysis$HAI_6_SIR), analysis$score_centered, "C. diff SIR")
)
outcomes <- Filter(Negate(is.null), outcomes)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{RDD Estimates at the HACRP Penalty Threshold}",
  "\\label{tab:rdd_main}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  paste0("& ", paste(sapply(outcomes, function(o) sprintf("(%d)", which(sapply(outcomes, function(x) x$label) == o$label))), collapse = " & "), " \\\\"),
  paste0("& ", paste(sapply(outcomes, function(o) o$label), collapse = " & "), " \\\\"),
  "\\midrule"
)

# Coefficient row
coef_row <- paste0("RDD Estimate & ", paste(sapply(outcomes, function(o)
  paste0(fmt(o$coef), stars_p(o$pval_robust))), collapse = " & "), " \\\\")
tab2_lines <- c(tab2_lines, coef_row)

# SE row
se_row <- paste0("& ", paste(sapply(outcomes, function(o)
  fmt_paren(o$se_robust)), collapse = " & "), " \\\\")
tab2_lines <- c(tab2_lines, se_row)

# Control mean
mean_row <- paste0("Control Mean & ", paste(sapply(outcomes, function(o)
  fmt(o$mean_left)), collapse = " & "), " \\\\")
tab2_lines <- c(tab2_lines, "\\addlinespace", mean_row)

# Bandwidth
bw_row <- paste0("Bandwidth & ", paste(sapply(outcomes, function(o)
  fmt(o$bw)), collapse = " & "), " \\\\")
tab2_lines <- c(tab2_lines, bw_row)

# Eff N
n_row <- paste0("Eff. $N$ & ", paste(sapply(outcomes, function(o)
  formatC(o$n_left + o$n_right, big.mark = ",")), collapse = " & "), " \\\\")
tab2_lines <- c(tab2_lines, n_row)

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each column reports a separate sharp RDD estimate at the 75th percentile of the Total HAC Score (0.379). Local linear regression with triangular kernel and MSE-optimal bandwidth (Calonico, Cattaneo, and Titiunik 2014). Robust bias-corrected standard errors in parentheses. Star Rating is the CMS Hospital Overall Rating (1--5). SIR is the Standardized Infection Ratio from CDC NHSN, where 1.0 equals the national benchmark. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2_lines, file.path(table_dir, "tab2_rdd_main.tex"))

# ============================================================
# Table 3: Balance Tests
# ============================================================
cat("=== Table 3: Balance Tests ===\n")

balance_outcomes <- list(
  run_rdd(analysis$is_nonprofit, analysis$score_centered, "Nonprofit"),
  run_rdd(analysis$is_forprofit, analysis$score_centered, "For-Profit"),
  run_rdd(analysis$is_government, analysis$score_centered, "Government"),
  run_rdd(analysis$has_emergency, analysis$score_centered, "Emergency Svcs.")
)
balance_outcomes <- Filter(Negate(is.null), balance_outcomes)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Balance Tests at the HACRP Penalty Threshold}",
  "\\label{tab:balance}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Variable & RDD Estimate & Robust SE & $p$-value \\\\",
  "\\midrule"
)

for (o in balance_outcomes) {
  line <- sprintf("%s & %s%s & %s & %s \\\\",
    o$label, fmt(o$coef), stars_p(o$pval_robust),
    fmt(o$se_robust), fmt(o$pval_robust))
  tab3_lines <- c(tab3_lines, line)
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("McCrary Density ($p$-value) & \\multicolumn{3}{c}{%s} \\\\",
    fmt(results$density_test$test$p_jk)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each row tests for a discontinuity in a predetermined covariate at the HACRP penalty threshold. Specifications identical to Table~\\ref{tab:rdd_main}. McCrary density test uses the Cattaneo, Jansson, and Ma (2020) estimator with jackknife standard errors. A large $p$-value supports the null of no manipulation. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3_lines, file.path(table_dir, "tab3_balance.tex"))

# ============================================================
# Table 4: Bandwidth Sensitivity and Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Bandwidth Sensitivity and Alternative Specifications}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Estimate & Robust SE & $p$-value & Eff. $N$ \\\\",
  "\\midrule",
  "\\addlinespace[3pt]",
  "\\multicolumn{5}{l}{\\textit{Panel A: Bandwidth Sensitivity (Star Rating)}} \\\\",
  "\\addlinespace[2pt]"
)

for (j in 1:nrow(bw_sens)) {
  line <- sprintf("$%s \\times h^*$ ($h = %s$) & %s%s & %s & %s & %s \\\\",
    fmt(bw_sens$multiplier[j], 2), fmt(bw_sens$bandwidth[j]),
    fmt(bw_sens$coef[j]), stars_p(bw_sens$pval_robust[j]),
    fmt(bw_sens$se_robust[j]), fmt(bw_sens$pval_robust[j]),
    formatC(bw_sens$n_eff[j], big.mark = ","))
  tab4_lines <- c(tab4_lines, line)
}

# Donut hole results
tab4_lines <- c(tab4_lines,
  "\\addlinespace[3pt]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Donut Hole RDD (Star Rating)}} \\\\",
  "\\addlinespace[2pt]")

for (donut in c(0.01, 0.02, 0.05)) {
  donut_sample <- analysis[abs(score_centered) > donut]
  rdd_d <- tryCatch({
    rdrobust(y = donut_sample$stars, x = donut_sample$score_centered, c = 0)
  }, error = function(e) NULL)
  if (!is.null(rdd_d)) {
    line <- sprintf("Donut $= %s$ & %s%s & %s & %s & %s \\\\",
      fmt(donut, 2), fmt(rdd_d$coef[1]), stars_p(rdd_d$pv[3]),
      fmt(rdd_d$se[3]), fmt(rdd_d$pv[3]),
      formatC(sum(rdd_d$N_h), big.mark = ","))
    tab4_lines <- c(tab4_lines, line)
  }
}

# Placebo
tab4_lines <- c(tab4_lines,
  "\\addlinespace[3pt]",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo Cutoffs (Star Rating)}} \\\\",
  "\\addlinespace[2pt]")

for (pct in c(0.25, 0.50, 0.90)) {
  pc <- quantile(analysis$total_hac_score, pct, na.rm = TRUE)
  rdd_pl <- tryCatch({
    rdrobust(y = analysis$stars, x = analysis$total_hac_score - pc, c = 0)
  }, error = function(e) NULL)
  if (!is.null(rdd_pl)) {
    line <- sprintf("Cutoff at $p_{%d}$ ($= %s$) & %s%s & %s & %s & %s \\\\",
      as.integer(100 * pct), fmt(pc), fmt(rdd_pl$coef[1]), stars_p(rdd_pl$pv[3]),
      fmt(rdd_pl$se[3]), fmt(rdd_pl$pv[3]),
      formatC(sum(rdd_pl$N_h), big.mark = ","))
    tab4_lines <- c(tab4_lines, line)
  }
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Panel A varies the bandwidth around the MSE-optimal value $h^* = 0.294$. Panel B excludes hospitals within the stated distance of the cutoff to address potential sorting. Panel C places the cutoff at non-penalty percentiles as a falsification test. All specifications use the star rating as the outcome. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================
# Table 5: Heterogeneity by Ownership
# ============================================================
cat("=== Table 5: Heterogeneity ===\n")

het_results <- list()
for (sub_label in c("Nonprofit", "For-Profit", "Government")) {
  sub_var <- switch(sub_label,
    "Nonprofit" = "is_nonprofit",
    "For-Profit" = "is_forprofit",
    "Government" = "is_government")
  sub_data <- analysis[get(sub_var) == 1]

  het_outcomes <- list(
    run_rdd(sub_data$stars, sub_data$score_centered, "Stars"),
    run_rdd(as.numeric(sub_data$HAI_1_SIR), sub_data$score_centered, "CLABSI"),
    run_rdd(as.numeric(sub_data$HAI_6_SIR), sub_data$score_centered, "C. diff")
  )
  het_outcomes <- Filter(Negate(is.null), het_outcomes)
  het_results[[sub_label]] <- list(data = sub_data, outcomes = het_outcomes)
}

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity by Hospital Ownership}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "& Star Rating & CLABSI SIR & C. diff SIR \\\\",
  "\\midrule"
)

for (sub_label in c("Nonprofit", "For-Profit", "Government")) {
  hr <- het_results[[sub_label]]
  tab5_lines <- c(tab5_lines,
    sprintf("\\addlinespace[3pt]"),
    sprintf("\\multicolumn{4}{l}{\\textit{%s ($N = %s$)}} \\\\",
      sub_label, formatC(nrow(hr$data), big.mark = ",")),
    "\\addlinespace[2pt]")

  outs <- hr$outcomes
  if (length(outs) >= 1) {
    coef_line <- paste0("RDD Estimate & ",
      paste(sapply(outs, function(o) paste0(fmt(o$coef), stars_p(o$pval_robust))),
            collapse = " & "), " \\\\")
    se_line <- paste0("& ",
      paste(sapply(outs, function(o) fmt_paren(o$se_robust)),
            collapse = " & "), " \\\\")
    tab5_lines <- c(tab5_lines, coef_line, se_line)
  }
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each cell is a separate RDD estimate. Specifications identical to Table~\\ref{tab:rdd_main}. Sample restricted to the indicated ownership type. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab5_lines, file.path(table_dir, "tab5_heterogeneity.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================
cat("=== SDE Table ===\n")

# Compute SDEs
# SDE = beta / SD(Y) using control-group (non-penalized) SD
sde_outcomes <- list()

# Stars
y_stars <- analysis$stars
sd_stars <- sd(y_stars[analysis$penalized == 0], na.rm = TRUE)
rdd_s <- rdrobust(y = y_stars, x = analysis$score_centered, c = 0)
sde_stars <- rdd_s$coef[1] / sd_stars
se_sde_stars <- rdd_s$se[3] / sd_stars

# CLABSI SIR
y_clabsi <- as.numeric(analysis$HAI_1_SIR)
sd_clabsi <- sd(y_clabsi[analysis$penalized == 0], na.rm = TRUE)
rdd_c <- rdrobust(y = y_clabsi, x = analysis$score_centered, c = 0)
sde_clabsi <- rdd_c$coef[1] / sd_clabsi
se_sde_clabsi <- rdd_c$se[3] / sd_clabsi

# C. diff SIR
y_cdiff <- as.numeric(analysis$HAI_6_SIR)
sd_cdiff <- sd(y_cdiff[analysis$penalized == 0], na.rm = TRUE)
rdd_d <- rdrobust(y = y_cdiff, x = analysis$score_centered, c = 0)
sde_cdiff <- rdd_d$coef[1] / sd_cdiff
se_sde_cdiff <- rdd_d$se[3] / sd_cdiff

# For-profit star rating (heterogeneous)
fp_data <- analysis[is_forprofit == 1]
y_fp <- fp_data$stars
sd_fp <- sd(y_fp[fp_data$penalized == 0], na.rm = TRUE)
rdd_fp <- rdrobust(y = y_fp, x = fp_data$score_centered, c = 0)
sde_fp <- rdd_fp$coef[1] / sd_fp
se_sde_fp <- rdd_fp$se[3] / sd_fp

# Classification function
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

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the HACRP 1\\% Medicare payment penalty for hospitals above the 75th percentile of the Total HAC Score cause improvements in hospital quality and infection outcomes? ",
  "\\textbf{Policy mechanism:} The Hospital-Acquired Condition Reduction Program imposes a 1\\% reduction in all Medicare DRG payments on the worst-performing quartile of hospitals, as scored by a peer-referenced z-score composite of six healthcare-associated infection and patient safety measures; the peer-referencing means a hospital's penalty status depends on the entire distribution, not just its own performance. ",
  "\\textbf{Outcome definition:} Panel A: CMS Hospital Overall Star Rating (1--5 composite of mortality, safety, readmission, patient experience, and timely care) and CLABSI/C.~diff Standardized Infection Ratios from CDC NHSN (1.0 = national benchmark). Panel B: Star Rating for for-profit hospitals only. ",
  "\\textbf{Treatment:} Binary (above vs.\\ below 75th percentile of Total HAC Score; threshold = 0.379 in FY2026). ",
  "\\textbf{Data:} CMS HACRP FY2026 hospital-level results merged with Hospital Compare and Healthcare Associated Infections data; 2,929 HACRP-eligible hospitals. ",
  "\\textbf{Method:} Sharp regression discontinuity with local linear regression, triangular kernel, MSE-optimal bandwidth (Calonico, Cattaneo, and Titiunik 2014); robust bias-corrected inference. ",
  "\\textbf{Sample:} All subsection (d) hospitals eligible for HACRP in FY2026; excludes hospitals with fewer than the minimum number of cases required for measure calculation. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the standard deviation among non-penalized hospitals. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\addlinespace[3pt]",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace[2pt]",
  sprintf("Star Rating & %s & %s & %s & %s & %s & %s \\\\",
    fmt(rdd_s$coef[1]), fmt(rdd_s$se[3]), fmt(sd_stars),
    fmt(sde_stars), fmt(se_sde_stars), classify_sde(sde_stars)),
  sprintf("CLABSI SIR & %s & %s & %s & %s & %s & %s \\\\",
    fmt(rdd_c$coef[1]), fmt(rdd_c$se[3]), fmt(sd_clabsi),
    fmt(sde_clabsi), fmt(se_sde_clabsi), classify_sde(sde_clabsi)),
  sprintf("C. diff SIR & %s & %s & %s & %s & %s & %s \\\\",
    fmt(rdd_d$coef[1]), fmt(rdd_d$se[3]), fmt(sd_cdiff),
    fmt(sde_cdiff), fmt(se_sde_cdiff), classify_sde(sde_cdiff)),
  "\\addlinespace[3pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (For-Profit Hospitals)}} \\\\",
  "\\addlinespace[2pt]",
  sprintf("Star Rating & %s & %s & %s & %s & %s & %s \\\\",
    fmt(rdd_fp$coef[1]), fmt(rdd_fp$se[3]), fmt(sd_fp),
    fmt(sde_fp), fmt(se_sde_fp), classify_sde(sde_fp)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files:\n")
print(list.files(table_dir, pattern = "\\.tex$"))
