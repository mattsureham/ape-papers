## =============================================================================
## 06_tables.R — All tables for the paper
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

## ---- Table 1: Summary Statistics ----
cat("=== Table 1: Summary Statistics ===\n")

panel_nozfu <- fread(file.path(data_dir, "panel_nozfu.csv"))

tab1 <- panel_nozfu[year %in% 2010:2014, .(
  `Mean` = sprintf("%.1f", mean(n_firms_created)),
  `SD` = sprintf("%.1f", sd(n_firms_created)),
  `Median` = sprintf("%.0f", median(n_firms_created)),
  `N` = as.character(uniqueN(zus_id)),
  `N-Years` = format(.N, big.mark = ",")
), by = .(Group = fifelse(lost_status == 1, "Lost Status (Treated)",
                           "Kept Status (Control)"))]

writeLines(
  knitr::kable(tab1, format = "latex", booktabs = TRUE,
               caption = "Pre-Treatment Summary Statistics (2010--2014)",
               label = "tab:sumstats") |>
    kableExtra::kable_styling(latex_options = "hold_position"),
  file.path(tab_dir, "tab1_sumstats.tex")
)
cat("Table 1 saved.\n")

## ---- Table 2: Main DiD Results ----
cat("=== Table 2: Main DiD Results ===\n")

models <- readRDS(file.path(data_dir, "models.rds"))

# Custom modelsummary table
tab2_models <- list(
  "Levels" = models$did_main,
  "Log(firms+1)" = models$did_log,
  "Poisson" = models$did_pois,
  "Full Sample" = models$did_full
)

# Use fixest::etable for clean LaTeX output
etable(models$did_main, models$did_log, models$did_pois, models$did_full,
       headers = c("Levels", "Log(firms+1)", "Poisson", "Full Sample"),
       dict = c("lost_status:post" = "Lost Status $\\times$ Post"),
       tex = TRUE,
       file = file.path(tab_dir, "tab2_main_did.tex"),
       replace = TRUE,
       title = "Effect of Losing Priority Neighborhood Status on Firm Creation",
       fitstat = ~ n + sq.cor,
       notes = c("Clustered standard errors at the neighborhood level in parentheses.",
                 "All specifications include neighborhood and year fixed effects.",
                 "Columns 1--3 exclude ZFU neighborhoods; Column 4 includes them.")
)
cat("Table 2 saved.\n")

## ---- Table 3: Robustness ----
cat("=== Table 3: Robustness ===\n")

robustness_rows <- list()

# Static DiD
main_res <- fread(file.path(data_dir, "did_static_results.csv"))
robustness_rows[["Main (levels)"]] <- main_res[specification == "Levels"]

# Entropy balance
if (file.exists(file.path(data_dir, "entropy_balance_result.csv"))) {
  eb_res <- fread(file.path(data_dir, "entropy_balance_result.csv"))
  robustness_rows[["Entropy balanced"]] <- eb_res
}

# Placebo timing
if (file.exists(file.path(data_dir, "placebo_timing.csv"))) {
  plac_res <- fread(file.path(data_dir, "placebo_timing.csv"))
  for (i in seq_len(nrow(plac_res))) {
    robustness_rows[[plac_res$test[i]]] <- plac_res[i]
  }
}

# Dynamic effects
if (file.exists(file.path(data_dir, "dynamic_effects.csv"))) {
  dyn_res <- fread(file.path(data_dir, "dynamic_effects.csv"))
  for (i in seq_len(nrow(dyn_res))) {
    robustness_rows[[dyn_res$period[i]]] <- dyn_res[i]
  }
}

# Power
if (file.exists(file.path(data_dir, "power_mde.csv"))) {
  mde_res <- fread(file.path(data_dir, "power_mde.csv"))
  cat("MDE:", mde_res$mde_pct, "% of control mean\n")
}

# Build table
if (length(robustness_rows) > 0) {
  rob_table <- data.table(
    Specification = names(robustness_rows),
    Coefficient = sapply(robustness_rows, function(x) sprintf("%.3f", x$coef)),
    SE = sapply(robustness_rows, function(x) sprintf("(%.3f)", x$se)),
    `p-value` = sapply(robustness_rows, function(x) sprintf("%.3f", x$pval))
  )

  writeLines(
    knitr::kable(rob_table, format = "latex", booktabs = TRUE,
                 caption = "Robustness Checks",
                 label = "tab:robustness") |>
      kableExtra::kable_styling(latex_options = "hold_position"),
    file.path(tab_dir, "tab3_robustness.tex")
  )
  cat("Table 3 saved.\n")
}

## ---- Table 4: Displacement Test ----
cat("=== Table 4: Displacement ===\n")

if (file.exists(file.path(data_dir, "displacement_aggregate.csv"))) {
  disp_dt <- fread(file.path(data_dir, "displacement_aggregate.csv"))
  disp_dt[, `:=`(
    post = format(post, big.mark = ","),
    pre = format(pre, big.mark = ","),
    change = format(change, big.mark = ","),
    pct_change = sprintf("%.1f\\%%", pct_change)
  )]
  setnames(disp_dt, c("Status", "Post (10 yrs)", "Pre (5 yrs)", "Change", "Pct Change"))

  writeLines(
    knitr::kable(disp_dt, format = "latex", booktabs = TRUE, escape = FALSE,
                 caption = "Aggregate Firm Creation: Lost vs.\\ Kept Status",
                 label = "tab:displacement") |>
      kableExtra::kable_styling(latex_options = "hold_position"),
    file.path(tab_dir, "tab4_displacement.tex")
  )
  cat("Table 4 saved.\n")
}

## ---- Table 5: Threshold Sensitivity ----
cat("=== Table 5: Threshold Sensitivity ===\n")

if (file.exists(file.path(data_dir, "threshold_sensitivity.csv"))) {
  thresh_dt <- fread(file.path(data_dir, "threshold_sensitivity.csv"))
  thresh_dt[, stars := fcase(
    pval < 0.01, "***",
    pval < 0.05, "**",
    pval < 0.10, "*",
    default = ""
  )]
  thresh_dt[, result := paste0(sprintf("%.3f", coef), stars, "\n(",
                                sprintf("%.3f", se), ")")]

  writeLines(
    knitr::kable(thresh_dt[, .(
      `Lost Threshold` = lost_threshold,
      `Kept Threshold` = kept_threshold,
      `N Lost` = n_lost,
      `N Kept` = n_kept,
      `Coefficient` = sprintf("%.3f%s", coef, stars),
      `SE` = sprintf("(%.3f)", se)
    )], format = "latex", booktabs = TRUE,
    caption = "Sensitivity to Overlap Threshold Definitions",
    label = "tab:thresholds") |>
      kableExtra::kable_styling(latex_options = "hold_position"),
    file.path(tab_dir, "tab5_thresholds.tex")
  )
  cat("Table 5 saved.\n")
}

cat("\nAll tables generated.\n")
