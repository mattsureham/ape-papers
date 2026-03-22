## =============================================================================
## 05_tables.R — Generate all LaTeX tables
## Paper: Estrato Boundaries and Educational Sorting in Colombia (apep_0755)
## =============================================================================

source("00_packages.R")

cat("=== Generating LaTeX Tables ===\n")

## Load results
main_results  <- readRDS("../data/main_results_dt.rds")
results_list  <- readRDS("../data/main_results.rds")
balance_res   <- readRDS("../data/balance_results.rds")
school_res    <- readRDS("../data/school_results.rds")
robust_res    <- readRDS("../data/robustness_results.rds")
df            <- fread("../data/icfes_clean.csv")

## Helper: format number with stars
fmt_coef <- function(coef, se, pval) {
  stars <- ifelse(pval < 0.01, "^{***}",
           ifelse(pval < 0.05, "^{**}",
           ifelse(pval < 0.10, "^{*}", "")))
  sprintf("%.2f%s", coef, stars)
}

fmt_se <- function(se) sprintf("(%.2f)", se)

## =============================================================================
## TABLE 1: Summary Statistics by Estrato
## =============================================================================
cat("\n--- Table 1: Summary Statistics ---\n")

summ <- df[, .(
  N = format(.N, big.mark = ","),
  `Global Score` = sprintf("%.1f", mean(punt_global, na.rm = TRUE)),
  `SD Score` = sprintf("%.1f", sd(punt_global, na.rm = TRUE)),
  `Math Score` = sprintf("%.1f", mean(punt_matematicas, na.rm = TRUE)),
  `Reading Score` = sprintf("%.1f", mean(punt_lectura_critica, na.rm = TRUE)),
  `Has Internet` = sprintf("%.2f", mean(has_internet, na.rm = TRUE)),
  `Has Computer` = sprintf("%.2f", mean(has_computer, na.rm = TRUE)),
  `Parent Educ` = sprintf("%.1f", mean(max_parent_educ, na.rm = TRUE)),
  `Pct Official` = sprintf("%.2f", mean(official, na.rm = TRUE))
), by = estrato][order(estrato)]

subsidy_rates <- c("60\\%", "40\\%", "15\\%", "0\\%", "$-$20\\%", "$-$20\\%")
summ[, `Utility Subsidy` := subsidy_rates]

## Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Estrato}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccccccc}",
  "\\toprule",
  "Estrato & Subsidy & N & Global & SD & Math & Reading & Internet & Computer & Parent Ed & Official \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ)) {
  row <- summ[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%d & %s & %s & %s & %s & %s & %s & %s & %s & %s & %s \\\\",
    row$estrato, row$`Utility Subsidy`, row$N, row$`Global Score`,
    row$`SD Score`, row$`Math Score`, row$`Reading Score`,
    row$`Has Internet`, row$`Has Computer`, row$`Parent Educ`, row$`Pct Official`
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} ICFES Saber 11 data from datos.gov.co, covering five major Colombian cities (Bogot\\'a, Medell\\'in, Cali, Barranquilla, Cartagena), main exam periods 2011--2022. Global Score is the combined standardized test score (scale 0--500). Subsidy rates are approximate utility subsidy percentages under Law 142/1994; negative values indicate surcharges paid by higher estratos. Parent Education is coded on a 0--9 ordinal scale (0 = none, 9 = postgraduate).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

## =============================================================================
## TABLE 2: Main Results — Score Discontinuity at Each Boundary
## =============================================================================
cat("\n--- Table 2: Main RDD Results ---\n")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Test Score Discontinuity at Estrato Boundaries}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{5}{c}{Boundary} \\\\",
  "\\cmidrule(lr){2-6}",
  " & 1$|$2 & 2$|$3 & 3$|$4 & 4$|$5 & 5$|$6 \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Global Score (no controls)}} \\\\"
)

## Panel A: No controls
coefs_a <- se_a <- pval_a <- c()
for (k in 1:5) {
  r <- main_results[boundary == paste0(k, "|", k + 1)]
  if (nrow(r) > 0) {
    coefs_a <- c(coefs_a, fmt_coef(r$coef_main, r$se_main, r$pval_main))
    se_a <- c(se_a, fmt_se(r$se_main))
  } else {
    coefs_a <- c(coefs_a, "---")
    se_a <- c(se_a, "")
  }
}
tab2_lines <- c(tab2_lines,
  sprintf("Higher Estrato & %s \\\\", paste(coefs_a, collapse = " & ")),
  sprintf(" & %s \\\\", paste(se_a, collapse = " & ")),
  "[0.5em]",
  "\\multicolumn{6}{l}{\\textit{Panel B: Global Score (with controls)}} \\\\"
)

## Panel B: With controls
coefs_b <- se_b <- c()
for (k in 1:5) {
  r <- main_results[boundary == paste0(k, "|", k + 1)]
  if (nrow(r) > 0) {
    pval_b <- pvalue(results_list[[paste0("b", k)]]$reg_controls)["treated"]
    coefs_b <- c(coefs_b, fmt_coef(r$coef_ctrl, r$se_ctrl, pval_b))
    se_b <- c(se_b, fmt_se(r$se_ctrl))
  } else {
    coefs_b <- c(coefs_b, "---")
    se_b <- c(se_b, "")
  }
}
tab2_lines <- c(tab2_lines,
  sprintf("Higher Estrato & %s \\\\", paste(coefs_b, collapse = " & ")),
  sprintf(" & %s \\\\", paste(se_b, collapse = " & ")),
  "[0.5em]",
  "\\multicolumn{6}{l}{\\textit{Panel C: Math Score}} \\\\"
)

## Panel C: Math
coefs_c <- se_c <- c()
for (k in 1:5) {
  r <- main_results[boundary == paste0(k, "|", k + 1)]
  if (nrow(r) > 0) {
    pval_c <- pvalue(results_list[[paste0("b", k)]]$reg_math)["treated"]
    coefs_c <- c(coefs_c, fmt_coef(r$coef_math, r$se_math, pval_c))
    se_c <- c(se_c, fmt_se(r$se_math))
  } else {
    coefs_c <- c(coefs_c, "---")
    se_c <- c(se_c, "")
  }
}
tab2_lines <- c(tab2_lines,
  sprintf("Higher Estrato & %s \\\\", paste(coefs_c, collapse = " & ")),
  sprintf(" & %s \\\\", paste(se_c, collapse = " & ")),
  "[0.5em]",
  "\\multicolumn{6}{l}{\\textit{Panel D: Reading Score}} \\\\"
)

## Panel D: Reading
coefs_d <- se_d <- c()
for (k in 1:5) {
  r <- main_results[boundary == paste0(k, "|", k + 1)]
  if (nrow(r) > 0) {
    pval_d <- pvalue(results_list[[paste0("b", k)]]$reg_reading)["treated"]
    coefs_d <- c(coefs_d, fmt_coef(r$coef_reading, r$se_reading, pval_d))
    se_d <- c(se_d, fmt_se(r$se_reading))
  } else {
    coefs_d <- c(coefs_d, "---")
    se_d <- c(se_d, "")
  }
}
tab2_lines <- c(tab2_lines,
  sprintf("Higher Estrato & %s \\\\", paste(coefs_d, collapse = " & ")),
  sprintf(" & %s \\\\", paste(se_d, collapse = " & "))
)

## Footer with N and controls
n_vals <- c()
for (k in 1:5) {
  r <- main_results[boundary == paste0(k, "|", k + 1)]
  if (nrow(r) > 0) {
    n_vals <- c(n_vals, format(r$n_obs, big.mark = ","))
  } else {
    n_vals <- c(n_vals, "---")
  }
}

tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("Observations & %s \\\\", paste(n_vals, collapse = " & ")),
  "Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Student Controls & No/Yes & No/Yes & No/Yes & No/Yes & No/Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each column estimates the test score discontinuity at an estrato boundary using within-municipality variation. Panel A reports the unconditional difference; Panel B adds student controls (gender, internet, computer, car, washing machine, parental education). Panels C and D show subject-specific scores. Standard errors clustered at the municipality level in parentheses. The 5$|$6 boundary serves as a built-in placebo: both estratos pay utility surcharges, so any effect reflects label/stigma rather than subsidy channels. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

## =============================================================================
## TABLE 3: Covariate Balance
## =============================================================================
cat("\n--- Table 3: Covariate Balance ---\n")

## Reshape balance results to wide format (boundaries as columns)
cov_labels <- c(
  "female" = "Female",
  "has_internet" = "Has Internet",
  "has_computer" = "Has Computer",
  "has_car" = "Has Car",
  "has_washer" = "Has Washer",
  "max_parent_educ" = "Parent Education",
  "asset_index" = "Asset Index"
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Covariate Balance at Estrato Boundaries}",
  "\\label{tab:balance}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{5}{c}{Boundary} \\\\",
  "\\cmidrule(lr){2-6}",
  "Covariate & 1$|$2 & 2$|$3 & 3$|$4 & 4$|$5 & 5$|$6 \\\\",
  "\\midrule"
)

for (cov in names(cov_labels)) {
  coef_row <- c()
  se_row <- c()
  for (k in 1:5) {
    bnd <- paste0(k, "|", k + 1)
    r <- balance_res[boundary == bnd & covariate == cov]
    if (nrow(r) > 0) {
      coef_row <- c(coef_row, fmt_coef(r$coef, r$se, r$pval))
      se_row <- c(se_row, fmt_se(r$se))
    } else {
      coef_row <- c(coef_row, "---")
      se_row <- c(se_row, "")
    }
  }
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s \\\\", cov_labels[cov], paste(coef_row, collapse = " & ")),
    sprintf(" & %s \\\\", paste(se_row, collapse = " & ")),
    "[0.3em]"
  )
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each cell reports the coefficient from regressing the covariate on a higher-estrato indicator with municipality fixed effects. Standard errors clustered at the municipality level. Significant discontinuities in pre-determined covariates would cast doubt on the as-good-as-random assignment assumption at boundaries. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_balance.tex")

## =============================================================================
## TABLE 4: Robustness — Mechanism and Donut Tests
## =============================================================================
cat("\n--- Table 4: Robustness ---\n")

mech_dt <- robust_res$mechanism
donut_dt <- robust_res$donut
year_dt  <- robust_res$year_stability

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Mechanisms and Specification Sensitivity}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Coef. & SE & N & $p$-value \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Official vs.~Private Schools}} \\\\"
)

for (i in 1:nrow(mech_dt)) {
  r <- mech_dt[i]
  tab4_lines <- c(tab4_lines, sprintf(
    "\\quad %s, %s & %s & %s & %s & %.3f \\\\",
    r$boundary, r$school_type,
    fmt_coef(r$coef, r$se, r$pval), fmt_se(r$se),
    format(r$n, big.mark = ","), r$pval
  ))
}

tab4_lines <- c(tab4_lines,
  "[0.5em]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Donut Test (Pure Schools Only, $>$70\\% Modal Estrato)}} \\\\"
)

if (nrow(donut_dt) > 0) {
  for (i in 1:nrow(donut_dt)) {
    r <- donut_dt[i]
    tab4_lines <- c(tab4_lines, sprintf(
      "\\quad Boundary %s & %s & %s & %s & %.3f \\\\",
      r$boundary, fmt_coef(r$coef, r$se, r$pval), fmt_se(r$se),
      format(r$n_schools, big.mark = ","), r$pval
    ))
  }
}

tab4_lines <- c(tab4_lines,
  "[0.5em]",
  "\\multicolumn{5}{l}{\\textit{Panel C: Year-by-Year Stability (3$|$4 Boundary)}} \\\\"
)

for (i in 1:nrow(year_dt)) {
  r <- year_dt[i]
  pval_yr <- 2 * pnorm(-abs(r$coef / r$se))
  tab4_lines <- c(tab4_lines, sprintf(
    "\\quad %d & %s & %s & %s & %.3f \\\\",
    r$year, fmt_coef(r$coef, r$se, pval_yr), fmt_se(r$se),
    format(r$n, big.mark = ","), pval_yr
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Panel A decomposes the boundary effect by school type (official/public vs.~private). Panel B restricts to schools where $>$70\\% of students share the modal estrato, excluding heavily mixed schools. Panel C shows the 3$|$4 boundary effect estimated separately by year. All specifications include municipality fixed effects with standard errors clustered at the municipality level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

## =============================================================================
## TABLE F1: Standardized Effect Sizes (SDE) — Mandatory Appendix
## =============================================================================
cat("\n--- Table F1: Standardized Effect Sizes ---\n")

## Compute SDE for each boundary's main outcome (global score)
sde_rows <- list()
for (k in 1:5) {
  r <- main_results[boundary == paste0(k, "|", k + 1)]
  if (nrow(r) == 0) next

  beta <- r$coef_main
  se_beta <- r$se_main
  sd_y <- r$sd_y

  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  ## Classification
  classify <- function(s) {
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    if (s < -0.005) return("Small negative")
    if (s < 0.005) return("Null")
    if (s < 0.05) return("Small positive")
    if (s < 0.15) return("Moderate positive")
    return("Large positive")
  }

  sde_rows[[paste0("b", k)]] <- data.table(
    outcome = sprintf("Global Score (Boundary %d$|$%d)", k, k + 1),
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sde_dt <- rbindlist(sde_rows)
cat("SDE results:\n")
print(sde_dt)

## SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Colombia. ",
  "\\textbf{Research question:} Whether government-assigned socioeconomic block classifications (estratos 1--6) ",
  "cause discontinuous jumps in student test scores at administrative boundaries, identifying the causal effect ",
  "of neighborhood stratification on educational outcomes. ",
  "\\textbf{Policy mechanism:} Colombia's estrato system (Law 142/1994) classifies every urban city block into ",
  "six socioeconomic tiers that determine utility subsidy rates (60\\% for estrato 1 down to 20\\% surcharges ",
  "for estratos 5--6), social program eligibility, and school zoning---creating residential sorting incentives ",
  "that concentrate educational advantage by neighborhood. ",
  "\\textbf{Outcome definition:} ICFES Saber 11 Global Score, the national standardized university entrance ",
  "examination combining mathematics, reading, science, social studies, and English (scale 0--500). ",
  "\\textbf{Treatment:} Binary: student resides in the higher estrato at each boundary ($k+1$ vs.~$k$). ",
  "\\textbf{Data:} ICFES Saber 11 microdata from datos.gov.co (2011--2022), five major Colombian cities, ",
  sprintf("%s students at unit of student-exam. ", format(sum(main_results$n_obs), big.mark = ",")),
  "\\textbf{Method:} Multi-cutoff boundary discontinuity design with municipality fixed effects; standard errors ",
  "clustered at the municipality level. ",
  "\\textbf{Sample:} Urban students in Bogot\\'a, Medell\\'in, Cali, Barranquilla, and Cartagena taking the ",
  "main Saber 11 exam; restricted to students reporting valid estrato (1--6). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the lower-estrato group. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_dt)) {
  r <- sde_dt[i]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files written to ../tables/:\n")
cat(paste(list.files("../tables/"), collapse = "\n"), "\n")
