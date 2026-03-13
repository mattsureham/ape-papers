## 05_tables.R — Generate all LaTeX tables
## APEP paper apep_0614: CEJST Justice40 RDD

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

analysis <- readRDS(file.path(data_dir, "analysis_dataset.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

rdd_full <- analysis[!is.na(income_pctile)]

add_stars <- function(pval) {
  ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
}

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

make_row <- function(dt, var, label, fmt = "%.2f") {
  vals <- dt[[var]]
  vals <- vals[!is.na(vals)]
  sprintf("%s & %s & %s & %s & %s",
          label, format(length(vals), big.mark=","),
          sprintf(fmt, mean(vals)), sprintf(fmt, sd(vals)),
          sprintf(fmt, median(vals)))
}

ss_tex <- paste0(
'\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccc}
\\toprule
 & N & Mean & SD & Median \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Full Sample}} \\\\[3pt]
', make_row(rdd_full, "income_pctile", "Income percentile", "%.3f"), ' \\\\
', make_row(rdd_full, "designated", "CEJST designated", "%.3f"), ' \\\\
', make_row(rdd_full, "any_ev_post", "Any new EV charger (post)", "%.3f"), ' \\\\
', make_row(rdd_full, "ev_count_post", "EV charger count (post)", "%.3f"), ' \\\\
', make_row(rdd_full, "ev_count_pre", "EV charger count (pre)", "%.3f"), ' \\\\
', make_row(rdd_full, "population", "Population", "%.0f"), ' \\\\
', if ("orig_post" %in% names(rdd_full)) paste0(
make_row(rdd_full[!is.na(orig_post)], "orig_post", "Mortgage originations (post)", "%.1f"), ' \\\\
', make_row(rdd_full[!is.na(orig_pre)], "orig_pre", "Mortgage originations (pre)", "%.1f"), ' \\\\') else '', '
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: Above Income Cutoff (Designated Eligible)}} \\\\[3pt]
', make_row(rdd_full[rv_centered >= 0], "designated", "Designated", "%.3f"), ' \\\\
', make_row(rdd_full[rv_centered >= 0], "any_ev_post", "Any new EV charger (post)", "%.3f"), ' \\\\
', make_row(rdd_full[rv_centered >= 0], "population", "Population", "%.0f"), ' \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel C: Below Income Cutoff}} \\\\[3pt]
', make_row(rdd_full[rv_centered < 0], "designated", "Designated", "%.3f"), ' \\\\
', make_row(rdd_full[rv_centered < 0], "any_ev_post", "Any new EV charger (post)", "%.3f"), ' \\\\
', make_row(rdd_full[rv_centered < 0], "population", "Population", "%.0f"), ' \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Unit of observation is the census tract (2010 boundaries). ``Income percentile\'\' is the CEJST low-income percentile score ($P200\\_I\\_PFS$). ``CEJST designated\'\' indicates the tract was classified as a disadvantaged community under Executive Order 14008. ``Any new EV charger (post)\'\' equals one if at least one new public EV charging station opened in the tract between November 2022 and January 2025. Mortgage originations are from HMDA and cover originated home-purchase loans in 10 large states. N = ', format(nrow(rdd_full), big.mark=","), ' census tracts.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}
')

writeLines(ss_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 done.\n")

# ============================================================
# Table 2: Main RDD Results
# ============================================================
cat("=== Table 2: Main RDD Results ===\n")

extract_rdd <- function(fit, label) {
  if (is.null(fit)) return(NULL)
  data.table(
    outcome = label,
    coef = fit$coef[1],
    se = fit$se[1],
    pval = fit$pv[1],
    bw = fit$bws[1,1],
    n_eff = fit$N_h[1] + fit$N_h[2]
  )
}

main_rows <- rbindlist(list(
  extract_rdd(results$first_stage, "First Stage: Designated"),
  extract_rdd(results$rf_ev_any, "Any New EV Charger"),
  extract_rdd(results$rf_ev_count, "EV Charger Count"),
  extract_rdd(results$rf_ev_change, "EV Charger Change (Post$-$Pre)"),
  extract_rdd(results$rf_orig, "Mortgage Originations (Post)"),
  extract_rdd(results$rf_orig_change, "Origination Change")
), fill = TRUE)
main_rows <- main_rows[!is.na(outcome)]

tex_rows <- ""
for (i in seq_len(nrow(main_rows))) {
  r <- main_rows[i]
  stars <- add_stars(r$pval)
  tex_rows <- paste0(tex_rows,
    sprintf("%s & %s%s & (%s) & %s & %s \\\\\n",
            r$outcome, sprintf("%.3f", r$coef), stars,
            sprintf("%.3f", r$se), sprintf("%.3f", r$bw),
            format(r$n_eff, big.mark=",")))
}

main_tex <- paste0(
'\\begin{table}[H]
\\centering
\\caption{Regression Discontinuity Estimates: Effect of CEJST Income Threshold}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccc}
\\toprule
Outcome & Estimate & (SE) & Bandwidth & N (eff.) \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: First Stage}} \\\\[3pt]
', main_rows[1, sprintf("%s & %s%s & (%s) & %s & %s \\\\\n",
    outcome, sprintf("%.3f", coef), add_stars(pval),
    sprintf("%.3f", se), sprintf("%.3f", bw),
    format(n_eff, big.mark=","))], '
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: Reduced Form}} \\\\[3pt]
', paste(sapply(2:nrow(main_rows), function(i) {
  r <- main_rows[i]
  sprintf("%s & %s%s & (%s) & %s & %s \\\\",
          r$outcome, sprintf("%.3f", r$coef), add_stars(r$pval),
          sprintf("%.3f", r$se), sprintf("%.3f", r$bw),
          format(r$n_eff, big.mark=","))
}), collapse = "\n"), '
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Local linear regression with triangular kernel, MSE-optimal bandwidth, and heteroskedasticity-robust standard errors (Cattaneo, Idrobo, and Titiunik 2020). Running variable is the CEJST low-income percentile score, centered at the 65th percentile cutoff. Mass points adjustment applied. The first stage shows the jump in CEJST designation probability at the income threshold. Panel B reports reduced-form effects. N = ', format(nrow(rdd_full), big.mark=","), ' census tracts. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}
')

writeLines(main_tex, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 done.\n")

# ============================================================
# Table 3: Bandwidth Sensitivity
# ============================================================
cat("=== Table 3: Bandwidth Sensitivity ===\n")

bw <- results$bw_sensitivity
bw_rows <- paste(sapply(1:nrow(bw), function(i) {
  r <- bw[i]
  stars <- add_stars(r$pval)
  sprintf("$%.2f \\times h^*$ & %.3f & %s%s & (%s) & [%s, %s] & %s",
          r$multiplier, r$bandwidth, sprintf("%.4f", r$estimate), stars,
          sprintf("%.4f", r$se), sprintf("%.4f", r$ci_lower),
          sprintf("%.4f", r$ci_upper),
          format(r$n_left + r$n_right, big.mark=","))
}), collapse = " \\\\\n")

bw_tex <- paste0(
'\\begin{table}[H]
\\centering
\\caption{Bandwidth Sensitivity: Any New EV Charger (Reduced Form)}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lccccc}
\\toprule
Bandwidth & $h$ & Estimate & (SE) & 95\\% CI & N (eff.) \\\\
\\midrule
', bw_rows, ' \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} $h^*$ is the MSE-optimal bandwidth (', sprintf("%.3f", bw$bandwidth[3]), '). Local linear regression with triangular kernel. Robust bias-corrected confidence intervals. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:bw}
\\end{table}
')

writeLines(bw_tex, file.path(tables_dir, "tab3_bandwidth.tex"))
cat("Table 3 done.\n")

# ============================================================
# Table 4: Covariate Balance
# ============================================================
cat("=== Table 4: Covariate Balance ===\n")

bal <- results$balance
if (!is.null(bal) && nrow(bal) > 0) {
  label_map <- c(
    population = "Population",
    ev_count_pre = "Pre-period EV chargers",
    DM_W = "Share White",
    DM_B = "Share Black",
    DM_H = "Share Hispanic",
    orig_pre = "Pre-period mortgage originations"
  )

  bal_rows <- paste(sapply(1:nrow(bal), function(i) {
    r <- bal[i]
    lab <- ifelse(r$covariate %in% names(label_map), label_map[r$covariate], r$covariate)
    stars <- add_stars(r$pval)
    sprintf("%s & %s%s & (%s) & %s & %s",
            lab, sprintf("%.3f", r$estimate), stars,
            sprintf("%.3f", r$se), sprintf("%.3f", r$pval),
            format(r$n_eff, big.mark=","))
  }), collapse = " \\\\\n")

  bal_tex <- paste0(
'\\begin{table}[H]
\\centering
\\caption{Covariate Balance at the Income Threshold}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Covariate & RD Estimate & (SE) & $p$-value & N (eff.) \\\\
\\midrule
', bal_rows, ' \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports a separate local linear RDD estimate of the discontinuity in the covariate at the 65th percentile income threshold. All covariates are predetermined or measured before CEJST designation (November 2022). MSE-optimal bandwidth with triangular kernel. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:balance}
\\end{table}
')

  writeLines(bal_tex, file.path(tables_dir, "tab4_balance.tex"))
  cat("Table 4 done.\n")
}

# ============================================================
# Table F1: Standardized Effect Sizes
# ============================================================
cat("=== Table F1: SDE ===\n")

compute_sde <- function(fit, var, label) {
  if (is.null(fit)) return(NULL)
  beta <- fit$coef[1]
  se_b <- fit$se[1]
  sd_y <- sd(rdd_full[[var]], na.rm = TRUE)
  if (is.na(sd_y) || sd_y == 0) return(NULL)
  sde <- beta / sd_y
  se_sde <- se_b / sd_y
  classify <- function(s) {
    if (s < -0.15) "Large negative"
    else if (s < -0.05) "Moderate negative"
    else if (s < -0.005) "Small negative"
    else if (s < 0.005) "Null"
    else if (s < 0.05) "Small positive"
    else if (s < 0.15) "Moderate positive"
    else "Large positive"
  }
  data.table(Outcome=label, beta=beta, se=se_b, sd_y=sd_y, sde=sde, se_sde=se_sde, class=classify(sde))
}

sde <- rbindlist(list(
  compute_sde(results$rf_ev_any, "any_ev_post", "Any New EV Charger"),
  compute_sde(results$rf_ev_count, "ev_count_post", "EV Charger Count"),
  compute_sde(results$rf_ev_change, "ev_change", "EV Charger Change"),
  compute_sde(results$rf_orig, "orig_post", "Mortgage Originations"),
  compute_sde(results$rf_orig_change, "orig_change", "Origination Change")
), fill = TRUE)
sde <- sde[!is.na(Outcome)]

sde_rows <- paste(sapply(1:nrow(sde), function(i) {
  r <- sde[i]
  sprintf("%s & %s & %s & %s & %s & %s & %s",
          r$Outcome, sprintf("%.4f", r$beta), sprintf("%.4f", r$se),
          sprintf("%.3f", r$sd_y), sprintf("%.4f", r$sde),
          sprintf("%.4f", r$se_sde), r$class)
}), collapse = " \\\\\n")

sde_tex <- paste0(
'\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
', sde_rows, ' \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\par\\vspace{0.3em}
{\\footnotesize \\emph{Notes:} Standardized effect sizes: SDE $= \\hat{\\beta} / \\text{SD}(Y)$. Treatment is binary CEJST disadvantaged designation (0/1) via fuzzy RDD at the 65th percentile income threshold. SD($Y$) is unconditional.

\\textbf{Research question:} Does CEJST disadvantaged community designation increase local EV infrastructure investment and mortgage credit?
\\textbf{Treatment:} Binary CEJST designation, instrumented by the income threshold.
\\textbf{Data:} CEJST (Nov 2022), NREL AFDC EV stations (2020--2025), HMDA (2021--2023), census-tract level.
\\textbf{Method:} Fuzzy RDD at 65th percentile income threshold, local linear, MSE-optimal bandwidth.
\\textbf{Sample:} ', format(nrow(rdd_full), big.mark=","), ' US census tracts.

Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$),
small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$),
small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$),
large positive ($> 0.15$).
Classification labels refer to the magnitude of the standardized point estimate,
not to statistical significance. ``Null\'\' denotes a near-zero effect size
($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}
\\end{table}
')

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("SDE table done.\n")

cat("\n=== All tables generated ===\n")
cat(paste(list.files(tables_dir), collapse = "\n"), "\n")
