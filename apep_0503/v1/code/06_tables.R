## ============================================================================
## 06_tables.R — All LaTeX tables for the paper
## apep_0503: DPE Energy Labels + Rental Ban Multi-Cutoff RDD
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
RESULTS_DIR <- "../tables"
FIGURES_DIR <- "../figures"
dir.create(RESULTS_DIR, showWarnings = FALSE, recursive = TRUE)

cat("=== Loading data ===\n")
analysis <- arrow::read_parquet(file.path(DATA_DIR, "analysis.parquet"))

## ============================================================================
## TABLE 1: Summary statistics
## ============================================================================

cat("  Table 1: Summary statistics...\n")

summ_stats <- analysis %>%
  group_by(dpe_label) %>%
  summarise(
    N = n(),
    `Mean Price/m²` = mean(price_m2, na.rm = TRUE),
    `SD Price/m²` = sd(price_m2, na.rm = TRUE),
    `Mean Energy` = mean(energy_kwh_m2, na.rm = TRUE),
    `Mean Surface` = mean(surface_reelle_bati, na.rm = TRUE),
    `Pct Apartment` = mean(building_type_dvf == "Appartement", na.rm = TRUE) * 100,
    `Pct Energy-Bound` = mean(is_energy_bound, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  arrange(match(dpe_label, c("A", "B", "C", "D", "E", "F", "G")))

# LaTeX output
summ_tex <- summ_stats %>%
  mutate(
    across(c(`Mean Price/m²`, `SD Price/m²`), ~format(round(.), big.mark = ",")),
    across(c(`Mean Energy`, `Mean Surface`), ~round(., 1)),
    across(c(`Pct Apartment`, `Pct Energy-Bound`), ~round(., 1)),
    N = format(N, big.mark = ",")
  )

sink(file.path(RESULTS_DIR, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by DPE Label}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{l r r r r r r r}\n")
cat("\\hline\\hline\n")
cat("DPE & N & Mean Price/m$^2$ & SD Price/m$^2$ & Energy & Surface & \\% Apt & \\% Energy-Bound \\\\\n")
cat("Label & & (\\euro) & (\\euro) & (kWh/m$^2$/yr) & (m$^2$) & & \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(summ_tex)) {
  row <- summ_tex[i, ]
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
              row$dpe_label, row$N, row$`Mean Price/m²`, row$`SD Price/m²`,
              row$`Mean Energy`, row$`Mean Surface`,
              row$`Pct Apartment`, row$`Pct Energy-Bound`))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{\\textwidth}\n")
cat("\\small\\textit{Notes:} Sample includes property transactions (apartments and houses) matched to DPE assessments within the ADEME database (post-July 2021). Energy consumption is primary energy in kWh/m$^2$/year. ``Energy-bound'' indicates properties where the energy dimension (rather than GHG emissions) determines the DPE label under the double-seuil system.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

## ============================================================================
## TABLE 2: Main RDD results
## ============================================================================

cat("  Table 2: Main RDD results...\n")

main_file <- file.path(RESULTS_DIR, "rdd_main_results.csv")
if (file.exists(main_file)) {
  main_results <- read_csv(main_file, show_col_types = FALSE)

  sink(file.path(RESULTS_DIR, "tab2_main_rdd.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{RDD Estimates at DPE Band Boundaries}\n")
  cat("\\label{tab:main_rdd}\n")
  cat("\\begin{adjustbox}{max width=\\textwidth}\n")
  cat("\\begin{tabular}{l c c c c c c}\n")
  cat("\\hline\\hline\n")
  cat(" & \\multicolumn{3}{c}{Regulatory Cutoffs} & \\multicolumn{3}{c}{Information-Only Cutoffs} \\\\\n")
  cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n")
  cat(" & G/F & F/E & E/D & D/C & C/B & B/A \\\\\n")
  cat(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
  cat("\\hline\n")

  for (cut_name in c("F", "E", "D", "C", "B", "A")) {
    row <- main_results %>% filter(cutoff == cut_name)
    if (nrow(row) == 0) next

    stars <- case_when(
      row$pval < 0.01 ~ "^{***}",
      row$pval < 0.05 ~ "^{**}",
      row$pval < 0.10 ~ "^{*}",
      TRUE ~ ""
    )

    if (cut_name == "F") {
      cat(sprintf("Discontinuity & $%.4f%s$ ", row$estimate, stars))
    } else {
      cat(sprintf("& $%.4f%s$ ", row$estimate, stars))
    }
  }
  cat("\\\\\n")

  # Standard errors
  for (cut_name in c("F", "E", "D", "C", "B", "A")) {
    row <- main_results %>% filter(cutoff == cut_name)
    if (nrow(row) == 0) next
    if (cut_name == "F") {
      cat(sprintf(" & ($%.4f$) ", row$se_bc))
    } else {
      cat(sprintf("& ($%.4f$) ", row$se_bc))
    }
  }
  cat("\\\\\n")

  # N effective
  cat("\\hline\n")
  for (cut_name in c("F", "E", "D", "C", "B", "A")) {
    row <- main_results %>% filter(cutoff == cut_name)
    if (nrow(row) == 0) next
    if (cut_name == "F") {
      cat(sprintf("Eff. N & %s ", format(row$n_effective, big.mark = ",")))
    } else {
      cat(sprintf("& %s ", format(row$n_effective, big.mark = ",")))
    }
  }
  cat("\\\\\n")

  # Bandwidth
  for (cut_name in c("F", "E", "D", "C", "B", "A")) {
    row <- main_results %>% filter(cutoff == cut_name)
    if (nrow(row) == 0) next
    if (cut_name == "F") {
      cat(sprintf("Bandwidth & %.1f ", row$bandwidth))
    } else {
      cat(sprintf("& %.1f ", row$bandwidth))
    }
  }
  cat("\\\\\n")

  cat("Cutoff type & Reg. & Antic. & Antic. & Info & Info & Info \\\\\n")
  cat("\\hline\\hline\n")
  cat("\\end{tabular}\n")
  cat("\\end{adjustbox}\n")
  cat("\\begin{minipage}{\\textwidth}\n")
  cat("\\small\\textit{Notes:} Each column reports local polynomial RDD estimates (\\texttt{rdrobust}) at the indicated DPE band boundary. The reported discontinuity is $\\hat{\\mu}_-(c) - \\hat{\\mu}_+(c)$ (below-cutoff minus above-cutoff, i.e., better-label side minus worse-label side), consistent with the pooled specification's $B_i$ coding. The dependent variable is log price per m$^2$. Kernel: triangular. Polynomial order: 1 (local linear). Bandwidth: MSE-optimal. Standard errors (in parentheses) are robust bias-corrected (Cattaneo, Jansson, and Ma 2020). Reg. = legislated rental ban; Antic. = announced future ban; Info = no regulatory consequence. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

## ============================================================================
## TABLE 3: McCrary density tests
## ============================================================================

cat("  Table 3: McCrary tests...\n")

mccrary_file <- file.path(RESULTS_DIR, "mccrary_tests.csv")
if (file.exists(mccrary_file)) {
  mccrary <- read_csv(mccrary_file, show_col_types = FALSE)

  sink(file.path(RESULTS_DIR, "tab3_mccrary.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{McCrary Density Tests for Manipulation}\n")
  cat("\\label{tab:mccrary}\n")
  cat("\\begin{tabular}{l c c c c}\n")
  cat("\\hline\\hline\n")
  cat("Cutoff & Energy Threshold & N & Test Statistic & $p$-value \\\\\n")
  cat(" & (kWh/m$^2$/yr) & & & \\\\\n")
  cat("\\hline\n")
  for (i in 1:nrow(mccrary)) {
    row <- mccrary[i, ]
    cat(sprintf("%s/%s & %d & %s & %.3f & %.4f \\\\\n",
                row$cutoff,
                c(F="G",E="F",D="E",C="D",B="C",A="B")[row$cutoff],
                row$cutoff_value,
                format(row$n, big.mark = ","),
                row$t_stat, row$p_value))
  }
  cat("\\hline\\hline\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{0.9\\textwidth}\n")
  cat("\\small\\textit{Notes:} Cattaneo, Jansson, and Ma (2020) density discontinuity test at each DPE band boundary. The null hypothesis is continuity of the density of energy consumption scores at the cutoff. Rejection ($p < 0.05$) indicates potential manipulation/bunching.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

## ============================================================================
## TABLE 4: Pre-ban vs. post-ban comparison
## ============================================================================

cat("  Table 4: Pre/post ban comparison...\n")

prepost_file <- file.path(RESULTS_DIR, "rdd_pre_post_ban.csv")
if (file.exists(prepost_file)) {
  prepost <- read_csv(prepost_file, show_col_types = FALSE)

  pre_row <- prepost %>% filter(period == "pre_ban")
  post_row <- prepost %>% filter(period == "post_ban")
  has_post <- nrow(post_row) > 0

  sink(file.path(RESULTS_DIR, "tab4_prepost.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  if (has_post) {
    cat("\\caption{Pre-Ban vs.\\ Post-Ban RDD Estimates at G/F Cutoff}\n")
  } else {
    cat("\\caption{Pre-Ban RDD Estimate at G/F Cutoff}\n")
  }
  cat("\\label{tab:prepost}\n")

  if (has_post) {
    cat("\\begin{tabular}{l c c}\n")
    cat("\\hline\\hline\n")
    cat(" & Pre-Ban & Post-Ban \\\\\n")
    cat(" & (2021--2022) & (2025) \\\\\n")
    cat("\\hline\n")

    pre_stars <- ifelse(pre_row$pval < 0.01, "$^{***}$", ifelse(pre_row$pval < 0.05, "$^{**}$", ifelse(pre_row$pval < 0.1, "$^{*}$", "")))
    post_stars <- ifelse(post_row$pval < 0.01, "$^{***}$", ifelse(post_row$pval < 0.05, "$^{**}$", ifelse(post_row$pval < 0.1, "$^{*}$", "")))
    cat(sprintf("Discontinuity & $%.4f$%s & $%.4f$%s \\\\\n", pre_row$estimate, pre_stars, post_row$estimate, post_stars))
    cat(sprintf(" & ($%.4f$) & ($%.4f$) \\\\\n", pre_row$se_bc, post_row$se_bc))
    cat("\\hline\n")
    cat(sprintf("Eff.\\ N & %s & %s \\\\\n", format(pre_row$n_effective, big.mark = ","), format(post_row$n_effective, big.mark = ",")))
  } else {
    cat("\\begin{tabular}{l c}\n")
    cat("\\hline\\hline\n")
    cat(" & Pre-Ban \\\\\n")
    cat(" & (2021--2022) \\\\\n")
    cat("\\hline\n")

    pre_stars <- ifelse(pre_row$pval < 0.01, "$^{***}$", ifelse(pre_row$pval < 0.05, "$^{**}$", ifelse(pre_row$pval < 0.1, "$^{*}$", "")))
    cat(sprintf("Discontinuity & $%.4f$%s \\\\\n", pre_row$estimate, pre_stars))
    cat(sprintf(" & ($%.4f$) \\\\\n", pre_row$se_bc))
    cat("\\hline\n")
    cat(sprintf("Eff.\\ N & %s \\\\\n", format(pre_row$n_effective, big.mark = ",")))
  }

  cat("\\hline\\hline\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{0.7\\textwidth}\n")
  if (has_post) {
    cat("\\small\\textit{Notes:} RDD estimates at the G/F boundary (420 kWh/m$^2$/yr) separately for pre-ban (2021--2022) and post-ban (2025) periods. Specification as in Table~\\ref{tab:main_rdd}. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
  } else {
    cat("\\small\\textit{Notes:} RDD estimate at the G/F boundary (420 kWh/m$^2$/yr) for the pre-ban period (2021--2022), covering DPE assessments after the July 2021 reform but before the January 2025 G-label rental ban. The post-ban period (2025) has insufficient observations within the RDD bandwidth for reliable estimation (141 total observations near the cutoff). Specification as in Table~\\ref{tab:main_rdd}. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
  }
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

## ============================================================================
## TABLE 5: Robustness — Donut RDD and bandwidth sensitivity
## ============================================================================

cat("  Table 5: Robustness checks...\n")

donut_file <- file.path(RESULTS_DIR, "donut_rdd.csv")
bw_file <- file.path(RESULTS_DIR, "bandwidth_sensitivity.csv")

if (file.exists(donut_file) && file.exists(bw_file)) {
  donut <- read_csv(donut_file, show_col_types = FALSE) %>% filter(cutoff == "F")
  bw <- read_csv(bw_file, show_col_types = FALSE) %>% filter(cutoff == "F")

  sink(file.path(RESULTS_DIR, "tab5_robustness.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{Robustness: Donut RDD and Bandwidth Sensitivity at G/F Cutoff}\n")
  cat("\\label{tab:robustness}\n")
  cat("\\begin{tabular}{l c c c c c c}\n")
  cat("\\hline\\hline\n")
  cat("\\multicolumn{7}{c}{\\textbf{Panel A: Donut RDD}} \\\\\n")
  cat("\\hline\n")
  cat("Donut width (kWh)")
  for (i in 1:nrow(donut)) {
    cat(sprintf(" & %d", donut$donut_width[i]))
  }
  cat(" \\\\\n\\hline\n")
  cat("Estimate")
  for (i in 1:nrow(donut)) {
    cat(sprintf(" & $%.4f$", donut$estimate[i]))
  }
  cat(" \\\\\n")
  cat("SE")
  for (i in 1:nrow(donut)) {
    cat(sprintf(" & ($%.4f$)", donut$se_bc[i]))
  }
  cat(" \\\\\n")
  cat("$p$-value (BC)")
  for (i in 1:nrow(donut)) {
    cat(sprintf(" & $%.3f$", donut$pval[i]))
  }
  cat(" \\\\\n")
  cat("N")
  for (i in 1:nrow(donut)) {
    cat(sprintf(" & %s", format(donut$n_effective[i], big.mark = ",")))
  }
  cat(" \\\\\n")

  cat("\\hline\n")
  cat("\\multicolumn{7}{c}{\\textbf{Panel B: Bandwidth Sensitivity}} \\\\\n")
  cat("\\hline\n")
  cat("BW multiplier")
  for (i in 1:min(nrow(bw), 6)) {
    cat(sprintf(" & %.2f", bw$bw_multiplier[i]))
  }
  cat(" \\\\\n\\hline\n")
  cat("Estimate")
  for (i in 1:min(nrow(bw), 6)) {
    cat(sprintf(" & $%.4f$", bw$estimate[i]))
  }
  cat(" \\\\\n")
  # Use conventional SE for bandwidth sensitivity (bias-corrected SE is unstable across bandwidths)
  se_col <- if ("se_conv" %in% names(bw)) "se_conv" else "se_bc"
  pv_col <- if ("pval_conv" %in% names(bw)) "pval_conv" else "pval"
  cat("SE")
  for (i in 1:min(nrow(bw), 6)) {
    cat(sprintf(" & ($%.4f$)", bw[[se_col]][i]))
  }
  cat(" \\\\\n")
  cat("$p$-value")
  for (i in 1:min(nrow(bw), 6)) {
    cat(sprintf(" & $%.3f$", bw[[pv_col]][i]))
  }
  cat(" \\\\\n")

  cat("\\hline\\hline\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{\\textwidth}\n")
  cat("\\small\\textit{Notes:} Panel A excludes observations within the specified donut width (kWh/m$^2$/yr) of the G/F cutoff (420). Panel A reports robust bias-corrected $p$-values (BC) from \\texttt{rdrobust}. Panel B varies the bandwidth around the MSE-optimal value (multiplier = 1.0) and reports conventional $p$-values, since the bias correction is sensitive to bandwidth specification. All specifications use local linear polynomial with triangular kernel.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

## ============================================================================
## TABLE 6: Pooled multi-cutoff regression
## ============================================================================

cat("  Table 6: Pooled multi-cutoff regression...\n")

pooled_file <- file.path(RESULTS_DIR, "pooled_regression.txt")
if (file.exists(pooled_file)) {
  # Re-run the pooled regression to get exact numbers
  pooled <- analysis %>%
    filter(abs(dist_to_cutoff) <= 40) %>%
    mutate(
      is_regulatory = cutoff_type %in% c("regulatory_active", "anticipation_near"),
      below_cutoff = dist_to_cutoff < 0,
      cutoff_fe = as.factor(nearest_cutoff)
    )

  pooled_reg <- fixest::feols(
    log_price_m2 ~ below_cutoff * is_regulatory +
      dist_to_cutoff + I(dist_to_cutoff * below_cutoff) |
      cutoff_fe,
    data = pooled,
    cluster = ~code_commune_clean
  )

  coefs <- summary(pooled_reg)$coeftable

  sink(file.path(RESULTS_DIR, "tab6_pooled.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{Pooled Multi-Cutoff Regression}\n")
  cat("\\label{tab:pooled}\n")
  cat("\\begin{tabular}{l c}\n")
  cat("\\hline\\hline\n")
  cat(" & Log Price/m$^2$ \\\\\n")
  cat("\\hline\n")

  # Better-label indicator
  row_b <- coefs["below_cutoffTRUE", ]
  stars_b <- ifelse(row_b[4] < 0.01, "^{***}", ifelse(row_b[4] < 0.05, "^{**}", ifelse(row_b[4] < 0.1, "^{*}", "")))
  cat(sprintf("Below cutoff ($B_i$) & $%.4f%s$ \\\\\n", row_b[1], stars_b))
  cat(sprintf(" & ($%.4f$) \\\\\n", row_b[2]))

  # Regulatory interaction
  row_int <- coefs["below_cutoffTRUE:is_regulatoryTRUE", ]
  stars_int <- ifelse(row_int[4] < 0.01, "^{***}", ifelse(row_int[4] < 0.05, "^{**}", ifelse(row_int[4] < 0.1, "^{*}", "")))
  cat(sprintf("$B_i \\times$ Regulatory & $%.4f%s$ \\\\\n", row_int[1], stars_int))
  cat(sprintf(" & ($%.4f$) \\\\\n", row_int[2]))

  cat("\\hline\n")
  cat(sprintf("Observations & %s \\\\\n", format(nobs(pooled_reg), big.mark = ",")))
  cat("Cutoff FE & Yes \\\\\n")
  cat("Clustering & Commune \\\\\n")
  cat(sprintf("Within $R^2$ & %.4f \\\\\n", fixest::r2(pooled_reg, "wr2")))
  cat("\\hline\\hline\n")
  cat("\\end{tabular}\n")
  cat("\\begin{minipage}{0.8\\textwidth}\n")
  cat("\\small\\textit{Notes:} Pooled RDD regression across all six cutoffs. $B_i = \\mathbf{1}[\\tilde{X}_i < 0]$ indicates the property falls on the better-label side of its nearest cutoff. ``Regulatory'' indicates cutoffs with active or anticipated rental ban (G/F, F/E, E/D). Controls include distance to cutoff (linear) with separate slopes above and below, and cutoff fixed effects. Standard errors clustered at the commune level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
}

cat("\n=== All tables generated ===\n")
