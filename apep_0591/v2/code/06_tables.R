# =============================================================================
# 06_tables.R — All table generation for v2
# APEP-0591 v2: The Erasmus Drain
# =============================================================================

source("00_packages.R")

data_dir  <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

nuts3_cross <- fread(file.path(data_dir, "nuts3_cross_section.csv"))
panel_n2    <- fread(file.path(data_dir, "nuts2_panel.csv"))
cross_n2    <- fread(file.path(data_dir, "nuts2_cross_section.csv"))
results     <- readRDS(file.path(data_dir, "main_results.rds"))
robust      <- readRDS(file.path(data_dir, "robustness_results.rds"))

has_long_diff <- !is.null(results$iv_n3_youth)

# ---------------------------------------------------------------
# Table 1: Summary Statistics (NUTS3 and NUTS2)
# ---------------------------------------------------------------
cat("Table 1: Summary Statistics...\n")

# NUTS3 stats
sum_data_n3 <- nuts3_cross[!is.na(bartik_avg) & !is.na(out_rate)]

vars_n3 <- list(
  "\\textit{Panel A: NUTS3 Cross-Section}" = NULL,
  "$\\Delta$ Youth share (25--34), pp" = "delta_youth_share",
  "Erasmus outflow rate (per 1k youth)" = "out_rate",
  "Net outflow rate (per 1k youth)" = "net_out_rate",
  "Bartik instrument (avg growth)" = "bartik_avg",
  "GDP per capita, pre-period (EUR)" = "gdp_pc_pre",
  "Youth population, 20--29 (avg)" = "pop_20_29_avg"
)

sumstats <- data.table()
for (vname in names(vars_n3)) {
  vcol <- vars_n3[[vname]]
  if (is.null(vcol)) {
    sumstats <- rbind(sumstats, data.table(
      Variable = vname, Mean = NA, SD = NA, Min = NA, Max = NA, N = NA
    ))
    next
  }
  if (vcol %in% names(sum_data_n3)) {
    vals <- sum_data_n3[[vcol]]
    vals <- vals[!is.na(vals)]
    if (length(vals) > 0) {
      sumstats <- rbind(sumstats, data.table(
        Variable = vname, Mean = round(mean(vals), 2),
        SD = round(sd(vals), 2), Min = round(min(vals), 2),
        Max = round(max(vals), 2), N = length(vals)
      ))
    }
  }
}

# NUTS2 stats
sum_data_n2 <- panel_n2[!is.na(tert_share_25_34) & !is.na(predicted_out_rate) & !is.na(out_rate)]

vars_n2 <- list(
  "\\textit{Panel B: NUTS2 Panel}" = NULL,
  "Tertiary share, 25--34 (\\%)" = "tert_share_25_34",
  "Tertiary share, 25--64 (\\%)" = "tert_share_25_64",
  "Erasmus outflow rate (per 1k youth)" = "out_rate",
  "Net outflow rate (per 1k youth)" = "net_out_rate",
  "Predicted outflow rate (Bartik IV)" = "predicted_out_rate",
  "GDP per capita (EUR)" = "gdp_pc"
)

for (vname in names(vars_n2)) {
  vcol <- vars_n2[[vname]]
  if (is.null(vcol)) {
    sumstats <- rbind(sumstats, data.table(
      Variable = vname, Mean = NA, SD = NA, Min = NA, Max = NA, N = NA
    ))
    next
  }
  if (vcol %in% names(sum_data_n2)) {
    vals <- sum_data_n2[[vcol]]
    vals <- vals[!is.na(vals)]
    if (length(vals) > 0) {
      sumstats <- rbind(sumstats, data.table(
        Variable = vname, Mean = round(mean(vals), 2),
        SD = round(sd(vals), 2), Min = round(min(vals), 2),
        Max = round(max(vals), 2), N = length(vals)
      ))
    }
  }
}

# Remove panel header rows (they have NA values) — will add as \multicolumn
sumstats_data <- sumstats[!is.na(Mean)]

# Generate LaTeX
tab1_tex <- kable(sumstats_data, format = "latex", booktabs = TRUE,
                   caption = "Summary Statistics",
                   label = "sumstats",
                   escape = FALSE) |>
  kable_styling(latex_options = c("hold_position"))

tab1_tex <- gsub("(\\\\begin\\{tabular\\})", "\\\\resizebox{\\\\textwidth}{!}{\\1", tab1_tex)
tab1_tex <- gsub("(\\\\end\\{tabular\\})", "\\1}", tab1_tex)

# Insert panel headers as \multicolumn rows (after \midrule)
tab1_tex <- sub("\\\\midrule\n(.*?Youth share)",
                "\\\\midrule\n\\\\midrule\n\\\\multicolumn{6}{l}{\\\\textit{Panel A: NUTS3 Cross-Section}} \\\\\\\\\n\\\\midrule\n\\1",
                tab1_tex)
tab1_tex <- sub("(Youth population.*?\\\\\\\\)\n(.*?Tertiary share, 25--34)",
                "\\1\n\\\\midrule\n\\\\multicolumn{6}{l}{\\\\textit{Panel B: NUTS2 Panel}} \\\\\\\\\n\\\\midrule\n\\2",
                tab1_tex)

# Add table note about GDP coverage
tab1_tex <- sub("\\\\end\\{tabular\\}\\}",
                "\\\\end{tabular}}\n\\\\par \\\\raggedright \\\\footnotesize GDP per capita has fewer observations due to missing Eurostat data for some region-years.",
                tab1_tex)

writeLines(tab1_tex, file.path(table_dir, "tab1_sumstats.tex"))
cat("  Saved\n")

# ---------------------------------------------------------------
# Table 2: First Stage (NUTS3 and NUTS2)
# ---------------------------------------------------------------
cat("Table 2: First Stage...\n")

fs_models <- list()
fs_headers <- c()

if (!is.null(results$fs_n3)) {
  fs_models <- c(fs_models, list(results$fs_n3))
  fs_headers <- c(fs_headers, "NUTS3 (cross)")
}
if (!is.null(results$fs_n3_panel)) {
  fs_models <- c(fs_models, list(results$fs_n3_panel))
  fs_headers <- c(fs_headers, "NUTS3 (panel)")
}
if (!is.null(results$fs_n3_cy)) {
  fs_models <- c(fs_models, list(results$fs_n3_cy))
  fs_headers <- c(fs_headers, "NUTS3 + C$\\times$Y")
}
fs_models <- c(fs_models, list(results$fs_n2))
fs_headers <- c(fs_headers, "NUTS2 (panel)")

if (length(fs_models) > 0) {
  tab2_tex <- etable(fs_models,
                      dict = c(out_rate = "Outflow rate",
                               bartik_avg = "Bartik (avg growth)",
                               bartik_growth = "Bartik growth",
                               predicted_out_rate = "Predicted outflow rate"),
                      headers = fs_headers,
                      tex = TRUE,
                      title = "First Stage: Bartik Instrument and Erasmus Outflows",
                      label = "tab:first_stage",
                      fitstat = ~n + r2)

  tab2_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab2_tex)
  tab2_tex <- gsub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n   \\\\begin{tabular}", tab2_tex)
  tab2_tex <- gsub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n   \\\\end{adjustbox}", tab2_tex)
  writeLines(tab2_tex, file.path(table_dir, "tab2_first_stage.tex"))
  cat("  Saved\n")
}

# ---------------------------------------------------------------
# Table 3: Main Results — NUTS3 (Primary)
# ---------------------------------------------------------------
cat("Table 3: Main Results (NUTS3)...\n")

if (has_long_diff) {
  # NUTS3 youth share results
  main_n3 <- list(results$ols_n3_youth, results$iv_n3_youth)
  main_n3 <- main_n3[!sapply(main_n3, is.null)]

  # Add NUTS2 census long-difference if available
  if (!is.null(results$iv_n2_ld)) {
    main_n3 <- c(main_n3, list(results$iv_n2_ld))
    main_headers <- c("OLS (NUTS3)", "2SLS (NUTS3)", "2SLS (NUTS2 LD)")
  } else {
    main_headers <- c("OLS", "2SLS")
  }

  tab3_tex <- etable(main_n3,
                      dict = c(delta_youth_share = "$\\Delta$ Youth share (25--34)",
                               delta_tert = "$\\Delta$ Tertiary share (25--34)",
                               out_rate = "Outflow rate",
                               fit_out_rate = "Outflow rate",
                               fit_delta_out = "$\\Delta$ Outflow"),
                      headers = main_headers,
                      tex = TRUE,
                      title = "Main Results: Long-Difference Specifications",
                      label = "tab:main_nuts3",
                      fitstat = ~n + ivf + r2,
                      notes = "Long-difference specifications. Columns 1--2: change in youth population share (25--34) across NUTS3 regions, 2014--2022. Column 3: change in tertiary share (25--34) across NUTS2 regions, early period (2014--2016 avg) to late period (2021--2022 avg). OLS sample is larger because 2SLS requires non-missing Bartik instruments. All specifications include country fixed effects.")

  tab3_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab3_tex)
  tab3_tex <- gsub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n   \\\\begin{tabular}", tab3_tex)
  tab3_tex <- gsub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n   \\\\end{adjustbox}", tab3_tex)
  writeLines(tab3_tex, file.path(table_dir, "tab3_main_nuts3.tex"))
  cat("  Saved\n")
}

# ---------------------------------------------------------------
# Table 4: NUTS2 Panel Results (Supplementary/Robustness)
# ---------------------------------------------------------------
cat("Table 4: NUTS2 Panel...\n")

n2_models <- list(results$ols_n2, results$iv_n2_main, results$iv_n2_2way,
                   results$iv_n2_cy)
n2_headers <- c("OLS", "2SLS", "2SLS (2-way)", "2SLS + C$\\times$Y")

tab4_tex <- etable(n2_models,
                    dict = c(tert_share_25_34 = "Tertiary share (25--34)",
                             out_rate = "Outflow rate",
                             fit_out_rate = "Outflow rate"),
                    headers = n2_headers,
                    tex = TRUE,
                    title = "Supplementary: NUTS2 Panel Specifications",
                    label = "tab:nuts2_panel",
                    fitstat = ~n + ivf + r2,
                    notes = "NUTS2 region $\\times$ year panel, 2014--2022. Standard errors clustered at NUTS2 (Columns 1--2, 4) or two-way by NUTS2 and year (Column 3). Column 4 adds country-by-year fixed effects to absorb national trends.")

tab4_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab4_tex)
tab4_tex <- gsub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n   \\\\begin{tabular}", tab4_tex)
tab4_tex <- gsub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n   \\\\end{adjustbox}", tab4_tex)
writeLines(tab4_tex, file.path(table_dir, "tab4_nuts2_panel.tex"))
cat("  Saved\n")

# ---------------------------------------------------------------
# Table 5: Heterogeneity
# ---------------------------------------------------------------
cat("Table 5: Heterogeneity...\n")

het_models <- list()
het_headers <- c()

if (!is.null(robust$iv_periph_n3)) {
  het_models <- c(het_models, list(robust$iv_periph_n3, robust$iv_core_n3))
  het_headers <- c(het_headers, "NUTS3 Periph.", "NUTS3 Core")
}
het_models <- c(het_models, list(robust$iv_periph_n2, robust$iv_core_n2))
het_headers <- c(het_headers, "NUTS2 Periph.", "NUTS2 Core")

# Add pooled interaction model if available
if (!is.null(robust$iv_interact_n2)) {
  het_models <- c(het_models, list(robust$iv_interact_n2))
  het_headers <- c(het_headers, "NUTS2 Pooled")
}

if (length(het_models) > 0) {
  tab5_tex <- etable(het_models,
                      dict = c(delta_youth_share = "$\\Delta$ Youth share (25--34)",
                               tert_share_25_34 = "Tertiary share (25--34)",
                               fit_out_rate = "Outflow rate",
                               fit_out_rate_periph = "Outflow $\\times$ Peripheral"),
                      headers = het_headers,
                      tex = TRUE,
                      title = "Heterogeneity: Peripheral vs.\\ Core Regions",
                      label = "tab:heterogeneity",
                      fitstat = ~n + ivf + r2,
                      notes = "Peripheral = below-median pre-period GDP per capita. All columns use NUTS2 region + year FE in panel. Columns 1--2 split the sample. Column 3 pools both groups with a peripheral $\\times$ outflow rate interaction.")

  tab5_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab5_tex)
  writeLines(tab5_tex, file.path(table_dir, "tab5_heterogeneity.tex"))
  cat("  Saved\n")
}

# ---------------------------------------------------------------
# Table 6: Distributed Lags (NUTS2)
# ---------------------------------------------------------------
cat("Table 6: Distributed Lags...\n")

lag_models <- list(results$iv_n2_main)
lag_headers <- c("Contemp.")

if (!is.null(results$iv_lag2)) {
  lag_models <- c(lag_models, list(results$iv_lag2))
  lag_headers <- c(lag_headers, "Lag 2yr")
}
if (!is.null(results$iv_lag3)) {
  lag_models <- c(lag_models, list(results$iv_lag3))
  lag_headers <- c(lag_headers, "Lag 3yr")
}

if (length(lag_models) > 1) {
  tab6_tex <- etable(lag_models,
                      dict = c(tert_share_25_34 = "Tertiary share (25--34)",
                               fit_out_rate = "Outflow rate",
                               fit_out_rate_lag2 = "Outflow rate (t-2)",
                               fit_out_rate_lag3 = "Outflow rate (t-3)"),
                      headers = lag_headers,
                      tex = TRUE,
                      title = "Distributed Lags: Addressing the Timing Mismatch",
                      label = "tab:lags",
                      fitstat = ~n + ivf + r2,
                      notes = "All specifications use 2SLS with NUTS2 region and year FE. Column 1 uses contemporaneous outflow rate. Columns 2--3 lag the treatment by 2 and 3 years to match the transition from Erasmus participation (ages 20--24) to residence as tertiary-educated adult (ages 25--34).")

  tab6_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab6_tex)
  writeLines(tab6_tex, file.path(table_dir, "tab6_lags.tex"))
  cat("  Saved\n")
}

# ---------------------------------------------------------------
# Table 7: Placebo tests
# ---------------------------------------------------------------
cat("Table 7: Placebo...\n")

placebo_models <- list(results$iv_n2_main, results$iv_n2_placebo)
placebo_headers <- c("Tert 25--34", "Tert 25--64 (placebo)")

tab7_tex <- etable(placebo_models,
                    dict = c(tert_share_25_34 = "Tertiary share (25--34)",
                             tert_share_25_64 = "Tertiary share (25--64)",
                             fit_out_rate = "Outflow rate"),
                    headers = placebo_headers,
                    tex = TRUE,
                    title = "Placebo Test: Age-Specificity of Erasmus Effects",
                    label = "tab:placebo",
                    fitstat = ~n + ivf + r2,
                    notes = "Both columns use 2SLS with NUTS2 region and year FE. Column 2 tests whether Erasmus outflows affect the broader 25--64 tertiary share; a null effect supports age-specificity of the mechanism.")

tab7_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab7_tex)
writeLines(tab7_tex, file.path(table_dir, "tab7_placebo.tex"))
cat("  Saved\n")

# ---------------------------------------------------------------
# Table C.1: Robustness (Appendix)
# ---------------------------------------------------------------
cat("Table C.1: Robustness...\n")

rob_models <- list(results$iv_n2_main, robust$iv_nocovid, robust$pretrend)
rob_headers <- c("Baseline", "No COVID", "Pre-trend (14--19)")

if (!is.null(robust$iv_akm)) {
  rob_models <- c(rob_models, list(robust$iv_akm))
  rob_headers <- c(rob_headers, "AKM cluster")
}

tab_c1_tex <- etable(rob_models,
                      dict = c(tert_share_25_34 = "Tertiary share (25--34)",
                               fit_out_rate = "Outflow rate",
                               predicted_out_rate = "Predicted outflow rate"),
                      headers = rob_headers,
                      tex = TRUE,
                      title = "Robustness: Alternative Specifications (NUTS2 Panel)",
                      label = "tab:robustness",
                      fitstat = ~n + ivf + r2)

tab_c1_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab_c1_tex)
tab_c1_tex <- gsub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n   \\\\begin{tabular}", tab_c1_tex)
tab_c1_tex <- gsub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n   \\\\end{adjustbox}", tab_c1_tex)
writeLines(tab_c1_tex, file.path(table_dir, "tabC1_robustness.tex"))
cat("  Saved\n")

# ---------------------------------------------------------------
# Table F.1: Standardized Effect Sizes
# ---------------------------------------------------------------
cat("Table F.1: SDE...\n")

main_model <- results$iv_n2_main
sd_tert <- sd(panel_n2$tert_share_25_34, na.rm = TRUE)
sd_x <- sd(panel_n2$out_rate, na.rm = TRUE)

beta_main <- coef(main_model)["fit_out_rate"]
se_main <- se(main_model)["fit_out_rate"]

sde_main <- beta_main * sd_x / sd_tert
se_sde <- se_main * sd_x / sd_tert

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

sde_rows <- data.table(
  Outcome = "Tertiary share (25--34)",
  Specification = "NUTS2 Panel 2SLS",
  `$\\hat{\\beta}$` = round(beta_main, 4),
  `SD(X)` = round(sd_x, 4),
  `SD(Y)` = round(sd_tert, 4),
  SDE = round(sde_main, 4),
  `SE(SDE)` = round(se_sde, 4),
  Classification = classify_sde(sde_main)
)

# Add NUTS3 if available
if (has_long_diff) {
  sd_delta <- sd(nuts3_cross$delta_youth_share, na.rm = TRUE)
  sd_x_n3 <- sd(nuts3_cross$out_rate, na.rm = TRUE)
  beta_n3 <- coef(results$iv_n3_youth)["fit_out_rate"]
  se_n3 <- se(results$iv_n3_youth)["fit_out_rate"]
  sde_n3 <- beta_n3 * sd_x_n3 / sd_delta
  se_sde_n3 <- se_n3 * sd_x_n3 / sd_delta

  sde_rows <- rbind(sde_rows, data.table(
    Outcome = "$\\Delta$ Youth share (25--34)",
    Specification = "NUTS3 Long-Diff 2SLS",
    `$\\hat{\\beta}$` = round(beta_n3, 4),
    `SD(X)` = round(sd_x_n3, 4),
    `SD(Y)` = round(sd_delta, 4),
    SDE = round(sde_n3, 4),
    `SE(SDE)` = round(se_sde_n3, 4),
    Classification = classify_sde(sde_n3)
  ))
}

tab_f1_tex <- kable(sde_rows, format = "latex", booktabs = TRUE,
                     escape = FALSE,
                     caption = "Standardized Effect Sizes",
                     label = "sde") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

writeLines(tab_f1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("  Saved\n")

cat("\n=== ALL TABLES GENERATED ===\n")
