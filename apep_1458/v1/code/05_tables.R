source("00_packages.R")

cat("=== Generating Tables ===\n")

df_full <- readRDS("../data/analysis_full.rds")
df_rdd <- readRDS("../data/analysis_rdd.rds")
results <- readRDS("../data/rdd_results.rds")
robust <- readRDS("../data/robustness_results.rds")
thresholds <- readRDS("../data/thresholds.rds")

fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")
stars <- function(p) ifelse(is.na(p), "", ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", ""))))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("--- Table 1 ---\n")

bw <- results$any_coliform_mcl$bws[1, 1]
df_bw <- df_rdd %>% filter(abs(dist_to_cutoff) <= bw)

make_col <- function(d) {
  c(
    fmt(mean(d$pop), 0), fmt(median(d$pop), 0),
    fmt(mean(d$connections, na.rm = TRUE), 0),
    fmt(mean(d$source_type == "Groundwater") * 100, 1),
    fmt(mean(d$source_type == "Surface water") * 100, 1),
    fmt(mean(d$required_samples), 1),
    fmt(mean(d$any_coliform_mcl) * 100, 1),
    fmt(mean(d$any_health) * 100, 1),
    fmt(mean(d$any_noncoliform) * 100, 1),
    fmt(mean(d$n_coliform_mcl), 2),
    fmt(nrow(d), 0)
  )
}

col_all <- make_col(df_full)
col_bw <- make_col(df_bw)

rows <- c(
  "\\textit{System characteristics} & & \\\\",
  paste0("Population served (mean) & ", col_all[1], " & ", col_bw[1], " \\\\"),
  paste0("Population served (median) & ", col_all[2], " & ", col_bw[2], " \\\\"),
  paste0("Service connections (mean) & ", col_all[3], " & ", col_bw[3], " \\\\"),
  paste0("Groundwater source (\\%) & ", col_all[4], " & ", col_bw[4], " \\\\"),
  paste0("Surface water source (\\%) & ", col_all[5], " & ", col_bw[5], " \\\\"),
  paste0("Required samples/month (mean) & ", col_all[6], " & ", col_bw[6], " \\\\"),
  "\\midrule",
  "\\textit{Violation outcomes} & & \\\\",
  paste0("Any coliform MCL violation (\\%) & ", col_all[7], " & ", col_bw[7], " \\\\"),
  paste0("Any health-based violation (\\%) & ", col_all[8], " & ", col_bw[8], " \\\\"),
  paste0("Any non-coliform MCL violation (\\%) & ", col_all[9], " & ", col_bw[9], " \\\\"),
  paste0("Coliform MCL violations (mean) & ", col_all[10], " & ", col_bw[10], " \\\\"),
  "\\midrule",
  paste0("Observations & ", col_all[11], " & ", col_bw[11], " \\\\")
)

tab1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & All CWS & RDD Sample \\\\
 & (1) & (2) \\\\
\\midrule
", paste(rows, collapse = "\n"), "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Column~(1) includes all active community water systems (CWS) in EPA SDWIS. Column~(2) restricts to systems within the MSE-optimal bandwidth (", fmt(bw, 0), " persons) of the nearest monitoring threshold. Coliform MCL violations include total coliform (contaminant 2950) and \\textit{E.~coli} (contaminant 3100) maximum contaminant level exceedances. Required samples per month follow 40~CFR~\\S141.21(a)(2).
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}")
writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================
# Table 2: Main RDD Results
# ============================================================
cat("--- Table 2 ---\n")

extract <- function(fit) {
  if (is.null(fit)) return(list(est = NA, se = NA, pv = NA, bw = NA, nl = NA, nr = NA))
  list(est = fit$coef[1], se = fit$se[3], pv = fit$pv[3],
       bw = fit$bws[1,1], nl = fit$N_h[1], nr = fit$N_h[2])
}

outcomes <- list(
  list(nm = "any_coliform_mcl", label = "Any coliform MCL violation"),
  list(nm = "any_health", label = "Any health-based violation"),
  list(nm = "any_noncoliform", label = "Any non-coliform MCL violation"),
  list(nm = "n_coliform_mcl", label = "Number of coliform violations")
)

tab2_rows <- sapply(outcomes, function(o) {
  r <- extract(results[[o$nm]])
  if (is.na(r$est)) return(paste0(o$label, " & --- & --- & --- & --- \\\\"))
  paste0(
    o$label, " & ", fmt(r$est, 4), stars(r$pv), " & ",
    fmt(r$bw, 0), " & ",
    fmt(r$nl, 0), " / ", fmt(r$nr, 0), " & ",
    fmt(r$pv, 3), " \\\\\n",
    " & (", fmt(r$se, 4), ") & & & \\\\"
  )
})

tab2 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Multi-Cutoff RDD: Effect of Monitoring Intensity on Violations}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Outcome & Estimate & Bandwidth & $N$ (left/right) & $p$-value \\\\
\\midrule
", paste(tab2_rows, collapse = "\n"), "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports a separate local linear RDD. The running variable is population served, normalized as distance to the nearest of nine monitoring thresholds (1,000; 2,500; 3,300; 4,100; 4,900; 5,800; 6,700; 7,600; 8,500). Triangular kernel with MSE-optimal bandwidth \\citep{calonico2014robust}. Bias-corrected robust standard errors in parentheses and $p$-values. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}")
writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================
# Table 3: Threshold-Specific Results
# ============================================================
cat("--- Table 3 ---\n")

cutoff_info <- tibble(
  cutoff = c("1000", "2500", "3300", "4100", "4900"),
  label = c("1,000", "2,500", "3,300", "4,100", "4,900"),
  jump = c("1$\\to$2 (100\\%)", "2$\\to$3 (50\\%)", "3$\\to$4 (33\\%)",
           "4$\\to$5 (25\\%)", "5$\\to$6 (20\\%)")
)

tab3_rows <- sapply(1:nrow(cutoff_info), function(i) {
  fit <- results$threshold[[cutoff_info$cutoff[i]]]
  r <- extract(fit)
  if (is.na(r$est)) {
    paste0(cutoff_info$label[i], " & ", cutoff_info$jump[i], " & --- & --- & --- & --- \\\\")
  } else {
    paste0(cutoff_info$label[i], " & ", cutoff_info$jump[i], " & ",
           fmt(r$est, 4), stars(r$pv), " & (", fmt(r$se, 4), ") & ",
           fmt(r$bw, 0), " & ", fmt(r$nl + r$nr, 0), " \\\\")
  }
})

dens <- robust$density_by_cutoff
dens_rows <- sapply(1:nrow(cutoff_info), function(i) {
  d <- dens %>% filter(cutoff == as.numeric(cutoff_info$cutoff[i]))
  if (nrow(d) == 0 || is.na(d$p_value)) return("")
  paste0("\\quad \\textit{Density $p$-value} & & & (", fmt(d$p_value, 3), ") & & \\\\")
})

tab3 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Threshold-Specific RDD Estimates: Coliform MCL Violations}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
Threshold & Monitoring & Estimate & SE & Bandwidth & $N$ \\\\
(pop.) & change & & & & \\\\
\\midrule
", paste(sapply(1:5, function(i) paste(c(tab3_rows[i], dens_rows[i]), collapse = "\n")),
         collapse = "\n"), "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row estimates a separate local linear RDD at the indicated population threshold. The outcome is an indicator for any coliform MCL violation. Density $p$-values from \\citet{cattaneo2020simple} manipulation test. The 3,300 threshold shows significant density discontinuity ($p=0.003$), consistent with the America's Water Infrastructure Act of 2018 creating a known administrative boundary. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:threshold}
\\end{table}")
writeLines(tab3, "../tables/tab3_thresholds.tex")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("--- Table 4 ---\n")

bw_r <- robust$bandwidth
poly_r <- robust$polynomial
donut_r <- robust$donut
placebo_r <- robust$placebo

tab4_lines <- c(
  "\\textit{Panel A: Bandwidth sensitivity} & & & \\\\",
  sapply(1:nrow(bw_r), function(i) {
    if (is.na(bw_r$est[i])) return(paste0("\\quad $h=", bw_r$bandwidth[i], "$ & --- & --- & --- \\\\"))
    paste0("\\quad $h=", fmt(bw_r$bandwidth[i], 0), "$ & ",
           fmt(bw_r$est[i], 4), stars(bw_r$pv[i]), " & (",
           fmt(bw_r$se[i], 4), ") & ", fmt(bw_r$n_eff[i], 0), " \\\\")
  }),
  "\\midrule",
  "\\textit{Panel B: Polynomial order} & & & \\\\",
  sapply(1:nrow(poly_r), function(i) {
    paste0("\\quad Order ", poly_r$poly_order[i], " & ",
           fmt(poly_r$est[i], 4), stars(poly_r$pv[i]), " & (",
           fmt(poly_r$se[i], 4), ") & --- \\\\")
  }),
  "\\midrule",
  "\\textit{Panel C: Donut RDD} & & & \\\\",
  sapply(1:nrow(donut_r), function(i) {
    paste0("\\quad Exclude $|\\Delta\\text{pop}| \\leq ", donut_r$donut_size[i], "$ & ",
           fmt(donut_r$est[i], 4), stars(donut_r$pv[i]), " & (",
           fmt(donut_r$se[i], 4), ") & ", fmt(donut_r$n_eff[i], 0), " \\\\")
  }),
  "\\midrule",
  "\\textit{Panel D: Placebo cutoffs} & & & \\\\",
  sapply(1:nrow(placebo_r), function(i) {
    if (is.na(placebo_r$est[i])) return(paste0("\\quad Pop.~", fmt(placebo_r$cutoff[i], 0), " & --- & --- & --- \\\\"))
    paste0("\\quad Pop.~", fmt(placebo_r$cutoff[i], 0), " & ",
           fmt(placebo_r$est[i], 4), stars(placebo_r$pv[i]), " & (",
           fmt(placebo_r$se[i], 4), ") & --- \\\\")
  })
)

tab4 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Robustness of Multi-Cutoff RDD Estimates}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Specification & Estimate & SE & $N$ \\\\
\\midrule
", paste(tab4_lines, collapse = "\n"), "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All rows estimate the effect of crossing a monitoring threshold on the probability of any coliform MCL violation. Panel~A varies the sample window around thresholds, letting \\texttt{rdrobust} select its own bandwidth within each window. Panel~B varies the polynomial order. Panel~C excludes systems within the indicated population distance of a threshold. Panel~D places fictitious thresholds at midpoints between actual monitoring cutoffs. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robust}
\\end{table}")
writeLines(tab4, "../tables/tab4_robustness.tex")

# ============================================================
# Table F1: SDE
# ============================================================
cat("--- Table F1 ---\n")

sd_coliform <- sd(df_rdd$any_coliform_mcl)
sd_health <- sd(df_rdd$any_health)
sd_noncol <- sd(df_rdd$any_noncoliform)

classify_sde <- function(s) case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_panel_a <- tibble(
  outcome = c("Coliform MCL viol.", "Health-based viol.", "Non-coliform MCL viol."),
  beta = c(results$any_coliform_mcl$coef[1], results$any_health$coef[1], results$any_noncoliform$coef[1]),
  se = c(results$any_coliform_mcl$se[3], results$any_health$se[3], results$any_noncoliform$se[3]),
  sd_y = c(sd_coliform, sd_health, sd_noncol)
) %>% mutate(sde = beta / sd_y, se_sde = se / sd_y, class = classify_sde(sde))

het_gw <- extract(results$het_groundwater)
het_sw <- extract(results$het_surface_water)

sde_panel_b <- tibble(
  outcome = c("Coliform (groundwater)", "Coliform (surface water)"),
  beta = c(het_gw$est, het_sw$est),
  se = c(het_gw$se, het_sw$se),
  sd_y = sd_coliform
) %>% filter(!is.na(beta)) %>%
  mutate(sde = beta / sd_y, se_sde = se / sd_y, class = classify_sde(sde))

make_sde_row <- function(r) {
  paste0(r$outcome, " & ", fmt(r$beta, 4), " & ", fmt(r$se, 4), " & ",
         fmt(r$sd_y, 3), " & ", fmt(r$sde, 4), " & ", fmt(r$se_sde, 4),
         " & ", r$class, " \\\\")
}

pa_rows <- sapply(1:nrow(sde_panel_a), function(i) make_sde_row(sde_panel_a[i,]))
pb_rows <- if (nrow(sde_panel_b) > 0) {
  sapply(1:nrow(sde_panel_b), function(i) make_sde_row(sde_panel_b[i,]))
} else "--- & --- & --- & --- & --- & --- & --- \\\\"

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does increasing the regulatory monitoring frequency for coliform bacteria in community water systems reduce health-based drinking water violations, or does it primarily increase detection of pre-existing contamination? ",
  "\\textbf{Policy mechanism:} The Safe Drinking Water Act requires community water systems to collect coliform samples at a frequency that increases in steps with population served; crossing each of nine population thresholds between 1,000 and 8,500 adds one required sample per month, mechanically increasing the probability of detecting positive results and triggering Maximum Contaminant Level violations. ",
  "\\textbf{Outcome definition:} Binary indicator for whether a community water system recorded any Maximum Contaminant Level violation for total coliform (contaminant 2950) or \\textit{E.~coli} (contaminant 3100) in EPA SDWIS. ",
  "\\textbf{Treatment:} Binary---crossing a population threshold that increases required monthly coliform samples by one. ",
  "\\textbf{Data:} EPA Safe Drinking Water Information System (SDWIS) via Envirofacts API, all years through 2025, community water system level, ", fmt(nrow(df_full), 0), " systems total. ",
  "\\textbf{Method:} Multi-cutoff local linear RDD pooling nine population thresholds (1,000 through 8,500), triangular kernel, MSE-optimal bandwidth, bias-corrected robust inference (Calonico, Cattaneo, and Titiunik 2014). ",
  "\\textbf{Sample:} Active community water systems serving between 25 and 3.96 million persons; analysis sample restricted to systems within bandwidth of nearest monitoring threshold. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
", paste(pa_rows, collapse = "\n"), "
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by source water type)}} \\\\
", paste(pb_rows, collapse = "\n"), "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
