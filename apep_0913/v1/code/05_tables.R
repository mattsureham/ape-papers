## 05_tables.R — Generate all tables for the paper
## apep_0913: Wilderness spatial RDD

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")
table_dir <- file.path(dirname(getwd()), "tables")
dir.create(table_dir, showWarnings = FALSE)

df <- readRDS(file.path(data_dir, "analysis_clean.rds"))
results <- readRDS(file.path(data_dir, "rdd_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

df_main <- df %>% filter(forested == 1, within_5km)

# Create summary by inside/outside wilderness
sum_stats <- df_main %>%
  group_by(wilderness) %>%
  summarise(
    n = n(),
    mean_loss = mean(any_loss, na.rm = TRUE),
    sd_loss = sd(any_loss, na.rm = TRUE),
    mean_tc2000 = mean(treecover2000, na.rm = TRUE),
    sd_tc2000 = sd(treecover2000, na.rm = TRUE),
    mean_elev = mean(elevation, na.rm = TRUE),
    sd_elev = sd(elevation, na.rm = TRUE),
    pct_high_forest = mean(high_forest, na.rm = TRUE),
    .groups = "drop"
  )

# Format as LaTeX table
tab1_rows <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Forested Pixels Within 5km of Wilderness Boundaries}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Inside Wilderness} & \\multicolumn{2}{c}{Outside Wilderness} & \\\\",
  "Variable & Mean & SD & Mean & SD & Diff. \\\\",
  "\\hline"
)

inside <- sum_stats %>% filter(wilderness == 1)
outside <- sum_stats %>% filter(wilderness == 0)

# Helper function
fmt_row <- function(label, var_mean, var_sd) {
  in_m <- inside[[var_mean]]
  in_s <- inside[[var_sd]]
  out_m <- outside[[var_mean]]
  out_s <- outside[[var_sd]]
  diff_val <- out_m - in_m
  sprintf("%s & %.3f & (%.3f) & %.3f & (%.3f) & %.3f \\\\",
          label, in_m, in_s, out_m, out_s, diff_val)
}

tab1_rows <- c(tab1_rows,
  fmt_row("Any tree cover loss, 2001--2023", "mean_loss", "sd_loss"),
  fmt_row("Baseline tree cover, 2000 (\\%)", "mean_tc2000", "sd_tc2000"),
  fmt_row("Elevation (m)", "mean_elev", "sd_elev"),
  sprintf("High forest ($\\geq$ 50\\%%) & %.3f & & %.3f & & %.3f \\\\",
          inside$pct_high_forest, outside$pct_high_forest,
          outside$pct_high_forest - inside$pct_high_forest)
)

tab1_rows <- c(tab1_rows,
  "\\hline",
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\\\",
          format(inside$n, big.mark = ","), format(outside$n, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Sample consists of forested pixels (baseline tree cover $\\geq$ 25\\%) within 5km of federal wilderness area boundaries in the western United States. Tree cover loss is from the Hansen Global Forest Change dataset (2001--2023). Baseline tree cover and elevation are pre-treatment covariates. Diff.~reports the outside minus inside mean difference.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_rows, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main RDD Results
# ============================================================
cat("Generating Table 2: Main RDD Results\n")

tab2_rows <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Wilderness Designation on Tree Cover Loss: RDD Estimates}",
  "\\label{tab:main_rdd}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) \\\\",
  " & Baseline & Elevation Control & High Forest \\\\",
  "\\hline",
  sprintf("Wilderness & %.4f & %.4f & %.4f \\\\",
          results$main$coef_bc,
          ifelse(is.na(results$elev_control$coef_bc), 0, results$elev_control$coef_bc),
          ifelse(is.na(results$high_forest$coef_bc), 0, results$high_forest$coef_bc)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\",
          results$main$se_rb,
          ifelse(is.na(results$elev_control$se_rb), 0, results$elev_control$se_rb),
          ifelse(is.na(results$high_forest$se_rb), 0, results$high_forest$se_rb)),
  "\\hline",
  sprintf("Bandwidth (km) & %.2f & %.2f & %.2f \\\\",
          results$main$bw, results$main$bw, results$main$bw),
  "Elevation control & No & Yes & No \\\\",
  sprintf("Sample & Forested & Forested & High forest \\\\"),
  sprintf("Outcome mean (outside) & %.3f & %.3f & %.3f \\\\",
          results$sample$mean_loss_outside,
          results$sample$mean_loss_outside,
          results$sample$mean_loss_outside),
  sprintf("$N$ (left/right) & %s / %s & %s / %s & %s / %s \\\\",
          format(results$main$n_left, big.mark = ","),
          format(results$main$n_right, big.mark = ","),
          format(results$main$n_left, big.mark = ","),
          format(results$main$n_right, big.mark = ","),
          format(results$main$n_left, big.mark = ","),
          format(results$main$n_right, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Local linear RDD estimates using \\texttt{rdrobust} with MSE-optimal bandwidth and triangular kernel. Bias-corrected point estimates with robust standard errors in parentheses. The outcome is an indicator for any tree cover loss during 2001--2023 from the Hansen Global Forest Change dataset. The running variable is signed distance (km) to the nearest wilderness boundary (negative = inside wilderness). Column (1) is the baseline specification on forested pixels ($\\geq$ 25\\% baseline tree cover). Column (2) adds elevation as a covariate. Column (3) restricts to high-forest pixels ($\\geq$ 50\\% baseline tree cover). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_rows, file.path(table_dir, "tab2_main_rdd.tex"))

# ============================================================
# Table 3: Robustness — Bandwidth Sensitivity
# ============================================================
cat("Generating Table 3: Bandwidth Sensitivity\n")

bw_df <- robust$bandwidth

tab3_rows <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Bandwidth Sensitivity}",
  "\\label{tab:bandwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  paste0("Bandwidth (km) & ", paste(sprintf("%.1f", bw_df$bandwidth), collapse = " & "), " \\\\"),
  "\\hline",
  paste0("Wilderness & ", paste(sprintf("%.4f", bw_df$coef_bc), collapse = " & "), " \\\\"),
  paste0(" & ", paste(sprintf("(%.4f)", bw_df$se_rb), collapse = " & "), " \\\\"),
  "\\hline",
  paste0("$N$ & ", paste(format(bw_df$n_left + bw_df$n_right, big.mark = ","), collapse = " & "), " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Local linear RDD estimates across varying bandwidths. Bias-corrected estimates with robust standard errors in parentheses. All specifications use triangular kernel.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_rows, file.path(table_dir, "tab3_bandwidth.tex"))

# ============================================================
# Table 4: Covariate Balance and Density Test
# ============================================================
cat("Generating Table 4: Validity Tests\n")

tab4_rows <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{RDD Validity: Covariate Balance and Density Test}",
  "\\label{tab:validity}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Estimate & Robust SE \\\\",
  "\\hline",
  "\\textit{Panel A: Covariate balance at boundary} & & \\\\",
  sprintf("\\quad Baseline tree cover (\\%%) & %.2f & (%.2f) \\\\",
          results$balance$tc2000_coef, results$balance$tc2000_se),
  sprintf("\\quad Elevation (m) & %.2f & (%.2f) \\\\",
          ifelse(is.na(results$balance$elev_coef), 0, results$balance$elev_coef),
          ifelse(is.na(results$balance$elev_se), 0, results$balance$elev_se)),
  "\\hline",
  "\\textit{Panel B: Manipulation test} & & \\\\",
  sprintf("\\quad Density discontinuity ($T$-statistic) & %.3f & \\\\",
          results$density_test$T_stat),
  sprintf("\\quad $p$-value & %.3f & \\\\",
          results$density_test$p_val),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports RDD estimates at the wilderness boundary using pre-treatment covariates as outcomes. If the RDD design is valid, covariates should be continuous at the boundary (estimates near zero). Panel B reports the Cattaneo, Jansson, and Ma (2020) density manipulation test. The null hypothesis is no discontinuity in the density of observations at the boundary.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_rows, file.path(table_dir, "tab4_validity.tex"))

# ============================================================
# Table 5: Placebo Cutoffs
# ============================================================
cat("Generating Table 5: Placebo Cutoffs\n")

pl_df <- robust$placebo

tab5_rows <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Placebo Tests: RDD at False Boundaries}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  paste0("Cutoff (km) & ", paste(sprintf("%.0f", pl_df$cutoff), collapse = " & "), " \\\\"),
  "\\hline",
  paste0("Estimate & ", paste(sprintf("%.4f", pl_df$coef_bc), collapse = " & "), " \\\\"),
  paste0(" & ", paste(sprintf("(%.4f)", pl_df$se_rb), collapse = " & "), " \\\\"),
  paste0("$p$-value & ", paste(sprintf("%.3f", pl_df$pval), collapse = " & "), " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} RDD estimates using false boundaries at various distances from the true wilderness boundary. Negative cutoffs are inside wilderness; positive cutoffs are outside. We should not observe significant discontinuities at false boundaries if the treatment effect is specific to the true legal boundary.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_rows, file.path(table_dir, "tab5_placebo.tex"))

# ============================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================
cat("Generating SDE Table (Appendix)\n")

sd_y <- results$sample$sd_loss
main_beta <- results$main$coef_bc
main_se <- results$main$se_rb

# SDE = beta / SD(Y)
sde_main <- main_beta / sd_y
sde_se <- main_se / sd_y

# Classification buckets
classify_sde <- function(sde) {
  if (is.na(sde)) return("N/A")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_pooled <- data.frame(
  outcome = "Any tree cover loss (2001--2023)",
  beta = main_beta,
  se = main_se,
  sd_y = sd_y,
  sde = sde_main,
  sde_se = sde_se,
  classification = classify_sde(sde_main)
)

# Panel B: Heterogeneous (sample splits)
# Split 1: High forest vs moderate forest
het_tc <- robust$het_treecover
sde_het_rows <- list()

if (nrow(het_tc) > 0) {
  for (i in 1:nrow(het_tc)) {
    grp <- het_tc[i, ]
    sde_val <- grp$coef_bc / sd_y
    sde_het_rows[[length(sde_het_rows) + 1]] <- data.frame(
      outcome = paste0("Tree cover loss (", grp$tc_group, " baseline)"),
      beta = grp$coef_bc,
      se = grp$se_rb,
      sd_y = sd_y,
      sde = sde_val,
      sde_se = grp$se_rb / sd_y,
      classification = classify_sde(sde_val)
    )
  }
}

# Split 2: By elevation quintile (lowest vs highest)
het_elev <- robust$het_elevation
if (nrow(het_elev) >= 2) {
  low_elev <- het_elev[het_elev$quintile == min(het_elev$quintile), ]
  high_elev <- het_elev[het_elev$quintile == max(het_elev$quintile), ]

  for (row_data in list(
    list(df = low_elev, label = "Low elevation"),
    list(df = high_elev, label = "High elevation")
  )) {
    if (nrow(row_data$df) > 0) {
      sde_val <- row_data$df$coef_bc[1] / sd_y
      sde_het_rows[[length(sde_het_rows) + 1]] <- data.frame(
        outcome = paste0("Tree cover loss (", row_data$label, ")"),
        beta = row_data$df$coef_bc[1],
        se = row_data$df$se_rb[1],
        sd_y = sd_y,
        sde = sde_val,
        sde_se = row_data$df$se_rb[1] / sd_y,
        classification = classify_sde(sde_val)
      )
    }
  }
}

sde_het <- if (length(sde_het_rows) > 0) do.call(rbind, sde_het_rows) else data.frame()

# Build LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does federal wilderness designation under the 1964 Wilderness Act reduce tree cover loss at the legal boundary where commercial timber harvest transitions from prohibited to permitted? ",
  "\\textbf{Policy mechanism:} The Wilderness Act prohibits commercial timber harvesting, road building, and motorized vehicle use inside designated wilderness areas, while adjacent National Forest land permits managed timber harvest under USFS forest plans. Congress drew boundaries through political compromise, creating a sharp legal discontinuity in permitted land use. ",
  "\\textbf{Outcome definition:} Binary indicator for any tree cover loss during 2001--2023 from the Hansen Global Forest Change v1.11 dataset (30m Landsat-derived). ",
  "\\textbf{Treatment:} Binary; pixel located inside vs.~outside a federally designated wilderness area. ",
  "\\textbf{Data:} Hansen GFC (30m, 2001--2023), WDPA wilderness boundaries, and SRTM elevation; unit of observation is a 30m pixel within 5km of wilderness boundaries in the western United States; sample of approximately ", format(nrow(df_main), big.mark = ","), " forested pixels. ",
  "\\textbf{Method:} Local linear spatial RDD (\\texttt{rdrobust}) with MSE-optimal bandwidth and triangular kernel; bias-corrected estimates with robust standard errors. ",
  "\\textbf{Sample:} Restricted to forested pixels (baseline tree cover $\\geq$ 25\\%) within 5km of wilderness boundaries in the western United States; heterogeneity uses sample splits by baseline tree cover category and elevation quintile. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the full-sample standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)

sde_tab <- c(sde_tab,
  sprintf("\\quad %s & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          sde_pooled$outcome, sde_pooled$beta, sde_pooled$se,
          sde_pooled$sd_y, sde_pooled$sde, sde_pooled$sde_se,
          sde_pooled$classification)
)

if (nrow(sde_het) > 0) {
  sde_tab <- c(sde_tab,
    "\\hline",
    "\\textit{Panel B: Heterogeneous (sample splits)} & & & & & & \\\\"
  )
  for (j in 1:nrow(sde_het)) {
    sde_tab <- c(sde_tab,
      sprintf("\\quad %s & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
              sde_het$outcome[j], sde_het$beta[j], sde_het$se[j],
              sde_het$sd_y[j], sde_het$sde[j], sde_het$sde_se[j],
              sde_het$classification[j])
    )
  }
}

sde_tab <- c(sde_tab,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tab, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in:", table_dir, "\n")
cat("Files:", paste(list.files(table_dir), collapse = ", "), "\n")
