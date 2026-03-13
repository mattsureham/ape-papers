## 05_tables.R — Generate all LaTeX tables
## APEP Paper apep_0619: H-1B Visa Lottery and Firm R&D Investment

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

est_sample <- readRDS(file.path(data_dir, "est_sample.rds"))
results <- readRDS(file.path(data_dir, "regression_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

cat("=== Generating LaTeX Tables ===\n")

# ---- Table 1: Summary Statistics ----
cat("  Table 1: Summary Statistics\n")

sum_df <- est_sample |>
  filter(horizon == 0)

make_sum_row <- function(x, label) {
  x <- x[!is.na(x)]
  sprintf("%s & %.1f & %.1f & %.1f & %.1f & %s \\\\",
          label, mean(x), sd(x), median(x),
          quantile(x, 0.75) - quantile(x, 0.25),
          format(length(x), big.mark = ","))
}

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  " & Mean & Std.\\ Dev. & Median & IQR & N \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\emph{Panel A: H-1B Lottery Variables}} \\\\",
  make_sum_row(sum_df$n_registered, "Registrations per firm"),
  make_sum_row(sum_df$n_selected, "Selected in lottery"),
  make_sum_row(sum_df$win_rate, "Win rate"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\emph{Panel B: Financial Variables (\\$ millions)}} \\\\",
  make_sum_row(sum_df$rd_millions[!is.na(sum_df$rd_millions)], "R\\&D Expenditure"),
  make_sum_row(sum_df$rev_millions[!is.na(sum_df$rev_millions)], "Revenue"),
  make_sum_row(sum_df$assets_millions[!is.na(sum_df$assets_millions)], "Total Assets"),
  make_sum_row(sum_df$opinc_millions[!is.na(sum_df$opinc_millions)], "Operating Income"),
  make_sum_row(sum_df$ppe_millions[!is.na(sum_df$ppe_millions)], "PP\\&E (net)"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\emph{Panel C: Derived Variables}} \\\\",
  make_sum_row(sum_df$rd_intensity[!is.na(sum_df$rd_intensity) & is.finite(sum_df$rd_intensity)], "R\\&D Intensity (R\\&D/Revenue)"),
  make_sum_row(sum_df$h1b_per_rev[!is.na(sum_df$h1b_per_rev) & is.finite(sum_df$h1b_per_rev)], "H-1B per \\$100M Revenue"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\emph{Notes:} Sample consists of %s publicly traded firms matched between the Bloomberg FOIA H-1B lottery dataset and SEC EDGAR financial filings, pooled across FY2021--FY2022 lotteries. Panel A reports the number of H-1B registrations submitted per firm, lottery selections, and the firm-level win rate (selected/registered). Panel B reports annual financial data from 10-K filings. IQR is the interquartile range.", format(length(unique(sum_df$cik)), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

# ---- Table 2: Balance Test ----
cat("  Table 2: Balance Test\n")

pre_data <- est_sample |>
  filter(horizon < 0) |>
  group_by(cik, fiscal_year) |>
  summarize(
    win_rate = first(win_rate),
    n_registered = first(n_registered),
    log_rd = mean(log_rd, na.rm = TRUE),
    log_rev = mean(log_rev, na.rm = TRUE),
    log_assets = mean(log_assets, na.rm = TRUE),
    .groups = "drop"
  )

bal_models <- list()
for (v in c("log_rd", "log_rev", "log_assets")) {
  df_v <- pre_data[is.finite(pre_data[[v]]), ]
  if (nrow(df_v) > 10) {
    bal_models[[v]] <- feols(as.formula(paste0(v, " ~ win_rate + log(n_registered) | fiscal_year")),
                             data = df_v, vcov = "hetero")
  }
}

if (length(bal_models) > 0) {
  tab2_tex <- etable(bal_models, tex = TRUE,
                      title = "Balance Test: Pre-Lottery Outcomes on Win Rate",
                      dict = c(log_rd = "log(R\\&D)", log_rev = "log(Revenue)",
                               log_assets = "log(Assets)", win_rate = "Win Rate",
                               `log(n_registered)` = "log(Registrations)"),
                      label = "tab:balance",
                      notes = "Pre-lottery financial outcomes (3-year average before lottery) regressed on the H-1B lottery win rate. Columns report OLS with fiscal year fixed effects and heteroskedasticity-robust standard errors. If the lottery is random conditional on registration count, win rate should not predict pre-lottery financial variables.",
                      style.tex = style.tex("aer"))
  writeLines(tab2_tex, file.path(table_dir, "tab2_balance.tex"))
}

# ---- Table 3: Main Results ----
cat("  Table 3: Main Results\n")

main_models <- list()
model_names <- c()

if (!is.null(results$m1_rd)) { main_models$`(1)` <- results$m1_rd; model_names <- c(model_names, "(1)") }
if (!is.null(results$m2_rd)) { main_models$`(2)` <- results$m2_rd; model_names <- c(model_names, "(2)") }
if (!is.null(results$m1_rev)) { main_models$`(3)` <- results$m1_rev; model_names <- c(model_names, "(3)") }
if (!is.null(results$m1_rdi)) { main_models$`(4)` <- results$m1_rdi; model_names <- c(model_names, "(4)") }
if (!is.null(results$m3_rd)) { main_models$`(5)` <- results$m3_rd; model_names <- c(model_names, "(5)") }

if (length(main_models) > 0) {
  tab3_tex <- etable(main_models, tex = TRUE,
                      title = "Effect of H-1B Lottery Win Rate on Firm Financial Outcomes",
                      dict = c(win_rate = "Win Rate", log_rd = "log(R\\&D)",
                               log_rev = "log(Revenue)", rd_intensity = "R\\&D/Revenue",
                               `log(n_registered)` = "log(Registrations)"),
                      label = "tab:main",
                      notes = "Each column reports a separate regression of the indicated financial outcome on the firm-level H-1B lottery win rate (selected/registered), controlling for log number of registrations. Standard errors clustered at the firm level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
                      style.tex = style.tex("aer"))
  writeLines(tab3_tex, file.path(table_dir, "tab3_main.tex"))
}

# ---- Table 4: Heterogeneity ----
cat("  Table 4: Heterogeneity\n")

het_models <- list()
if (!is.null(results$m1_rd)) het_models$`All Firms` <- results$m1_rd
if (!is.null(results$m_tech)) het_models$`Tech Firms` <- results$m_tech
if (!is.null(results$m_nontech)) het_models$`Non-Tech` <- results$m_nontech
if (!is.null(rob_results$dose)) het_models$`Interaction` <- rob_results$dose

if (length(het_models) >= 2) {
  tab4_tex <- etable(het_models, tex = TRUE,
                      title = "Heterogeneity by Industry and H-1B Dependence",
                      dict = c(win_rate = "Win Rate",
                               `log(n_registered)` = "log(Registrations)",
                               high_h1b_dependenceTRUE = "High H-1B Dependence",
                               `win_rate:high_h1b_dependenceTRUE` = "Win Rate $\\times$ High Dep."),
                      label = "tab:het",
                      notes = "Columns (1)--(3) report separate regressions for all firms, technology-sector firms (SIC 28, 35--38, 48, 73, 87), and non-technology firms. Column (4) interacts the win rate with an indicator for above-median H-1B dependence (registrations per \\$100M revenue). All specifications include fiscal year fixed effects and cluster standard errors at the firm level.",
                      style.tex = style.tex("aer"))
  writeLines(tab4_tex, file.path(table_dir, "tab4_het.tex"))
}

# ---- Table 5: Robustness ----
cat("  Table 5: Robustness\n")

rob_models <- list()
if (!is.null(results$m1_rd)) rob_models$`Baseline` <- results$m1_rd
if (!is.null(rob_results$rd_level)) rob_models$`Level R\\&D` <- rob_results$rd_level
if (!is.null(rob_results$placebo_rd)) rob_models$`Placebo (Pre)` <- rob_results$placebo_rd
if (!is.null(rob_results$opinc)) rob_models$`Op. Income` <- rob_results$opinc
if (!is.null(rob_results$ppe)) rob_models$`PP\\&E` <- rob_results$ppe

if (length(rob_models) >= 2) {
  tab5_tex <- etable(rob_models, tex = TRUE,
                      title = "Robustness: Alternative Outcomes and Placebo Test",
                      dict = c(win_rate = "Win Rate",
                               `log(n_registered)` = "log(Registrations)"),
                      label = "tab:robust",
                      notes = "Column (1) reproduces the baseline log(R\\&D) specification. Column (2) uses R\\&D level in millions (winsorized at 1\\%). Column (3) is a placebo test using pre-lottery outcomes — a significant coefficient would indicate selection bias. Columns (4)--(5) examine alternative financial outcomes. All specifications include fiscal year fixed effects and firm-clustered standard errors.",
                      style.tex = style.tex("aer"))
  writeLines(tab5_tex, file.path(table_dir, "tab5_robust.tex"))
}

# ---- Table F1: SDE Appendix ----
cat("  Table F1: Standardized Effect Sizes\n")

# Compute SDE for main outcomes from stored regression objects
sde_rows <- list()

compute_sde <- function(model, outcome_var, data, outcome_label, spec_label) {
  if (is.null(model)) return(NULL)
  beta <- coef(model)["win_rate"]
  se_beta <- se(model)["win_rate"]
  sd_y <- sd(data[[outcome_var]], na.rm = TRUE)
  if (is.na(sd_y) || sd_y == 0) return(NULL)
  # Win rate is continuous: SDE = beta * SD(X) / SD(Y)
  sd_x <- sd(data$win_rate, na.rm = TRUE)
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y

  classify <- function(s) {
    if (s < -0.15) "Large negative"
    else if (s < -0.05) "Moderate negative"
    else if (s < -0.005) "Small negative"
    else if (s < 0.005) "Null"
    else if (s < 0.05) "Small positive"
    else if (s < 0.15) "Moderate positive"
    else "Large positive"
  }

  tibble(
    Outcome = outcome_label,
    Specification = spec_label,
    beta = beta,
    sd_x = sd_x,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

post_h0 <- est_sample |> filter(horizon == 0)

sde_rows <- bind_rows(
  compute_sde(results$m1_rd, "log_rd", post_h0, "log(R\\&D)", "Baseline"),
  compute_sde(results$m1_rev, "log_rev", post_h0, "log(Revenue)", "Baseline"),
  compute_sde(results$m1_assets, "log_assets", post_h0, "log(Assets)", "Baseline"),
  compute_sde(results$m1_rdi, "rd_intensity", post_h0, "R\\&D Intensity", "Baseline")
)

if (nrow(sde_rows) > 0) {
  sde_tex <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Standardized Effect Sizes for Main Outcomes}",
    "\\label{tab:sde}",
    "\\begin{tabular}{llcccccl}",
    "\\toprule",
    "Outcome & Spec. & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
    "\\midrule"
  )

  for (i in seq_len(nrow(sde_rows))) {
    r <- sde_rows[i, ]
    sde_tex <- c(sde_tex,
      sprintf("%s & %s & %.4f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
              r$Outcome, r$Specification, r$beta, r$sd_x, r$sd_y,
              r$sde, r$se_sde, r$classification))
  }

  n_firms <- length(unique(post_h0$cik))
  n_obs <- nrow(post_h0)

  sde_tex <- c(sde_tex,
    "\\bottomrule",
    "\\end{tabular}",
    "\\par\\vspace{0.3em}",
    sprintf("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, which gives the effect of a one-standard-deviation change in the lottery win rate, measured in standard deviations of the outcome. SD($Y$) and SD($X$) are unconditional standard deviations from the estimation sample. \\textbf{Research question:} Does the H-1B visa lottery win rate affect publicly traded firms' R\\&D investment and financial performance? \\textbf{Treatment:} Continuous firm-level lottery win rate (0--1). \\textbf{Data:} Bloomberg FOIA H-1B lottery data matched to SEC EDGAR 10-K filings, FY2021--FY2022, %s firms, %s firm-year observations. \\textbf{Method:} Reduced-form OLS with fiscal year fixed effects and firm-clustered standard errors. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
    format(n_firms, big.mark = ","), format(n_obs, big.mark = ",")),
    "\\end{table}"
  )

  writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))
}

cat("\n=== All tables generated ===\n")
cat(sprintf("Files in %s/:\n", table_dir))
cat(paste("  ", list.files(table_dir), collapse = "\n"), "\n")
