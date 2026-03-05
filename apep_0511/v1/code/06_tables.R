## ============================================================================
## 06_tables.R — All tables for 340B × Medicaid RDD paper
## ============================================================================

source("00_packages.R")

DATA <- "../data"
TABLES <- "../tables"
dir.create(TABLES, showWarnings = FALSE, recursive = TRUE)

analysis_xs <- readRDS(file.path(DATA, "analysis_xs.rds"))
analysis <- readRDS(file.path(DATA, "analysis_panel.rds"))
main_results <- readRDS("../results/main_results.rds")
robustness <- readRDS("../results/robustness.rds")

## ============================================================================
## Table 1: Summary Statistics
## ============================================================================

cat("Table 1: Summary Statistics\n")

rdd_10 <- analysis_xs[abs(dsh_centered) <= 10]

summ_below <- rdd_10[treated == 0, .(
  N = .N,
  dsh_pct = sprintf("%.1f", mean(dsh_pct)),
  mcaid_drug_paid = sprintf("%.0f", mean(mcaid_drug_paid)),
  mcaid_drug_claims = sprintf("%.0f", mean(mcaid_drug_claims)),
  pct_mcaid_any = sprintf("%.1f", 100 * mean(mcaid_drug_paid > 0)),
  mcaid_nondrug_paid = sprintf("%.0f", mean(mcaid_nondrug_paid)),
  mcare_drug_paid = sprintf("%.0f", mean(mcare_drug_paid))
)]

summ_above <- rdd_10[treated == 1, .(
  N = .N,
  dsh_pct = sprintf("%.1f", mean(dsh_pct)),
  mcaid_drug_paid = sprintf("%.0f", mean(mcaid_drug_paid)),
  mcaid_drug_claims = sprintf("%.0f", mean(mcaid_drug_claims)),
  pct_mcaid_any = sprintf("%.1f", 100 * mean(mcaid_drug_paid > 0)),
  mcaid_nondrug_paid = sprintf("%.0f", mean(mcaid_nondrug_paid)),
  mcare_drug_paid = sprintf("%.0f", mean(mcare_drug_paid))
)]

tab1 <- rbind(
  data.table(Group = "Below Threshold (DSH < 11.75%)", summ_below),
  data.table(Group = "Above Threshold (DSH >= 11.75%)", summ_above)
)

tab1_tex <- kable(tab1, format = "latex", booktabs = TRUE,
                   col.names = c("", "N", "DSH %", "Drug Paid ($)",
                                 "Drug Claims", "% Any Drug", "Non-Drug ($)",
                                 "Medicare Drug ($)"),
                   caption = "Summary Statistics: Hospitals Within $\\pm$10pp of 340B Threshold",
                   label = "tab:summary") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

writeLines(tab1_tex, file.path(TABLES, "tab1_summary.tex"))

## ============================================================================
## Table 2: Main RDD Results
## ============================================================================

cat("Table 2: Main RDD Results\n")

format_coef <- function(r, digits = 3) {
  stars <- ""
  if (!is.null(r$pval)) {
    if (r$pval < 0.01) stars <- "***"
    else if (r$pval < 0.05) stars <- "**"
    else if (r$pval < 0.10) stars <- "*"
  }
  sprintf("%.3f%s", r$coef, stars)
}

format_se <- function(r) sprintf("(%.3f)", r$se)

# Build table rows
outcomes <- c("mcaid_drug", "mcare_drug", "drug_share",
              "extensive_margin", "placebo_nondrug")
labels <- c("Medicaid Drug Spending (asinh)",
            "Medicare Drug Spending (asinh)",
            "Medicaid Drug Share",
            "Pr(Any Medicaid Drug Billing)",
            "Non-Drug Medicaid Spending (asinh)")

tab2_rows <- list()
for (i in seq_along(outcomes)) {
  nm <- outcomes[i]
  if (nm %in% names(main_results)) {
    r <- main_results[[nm]]
    tab2_rows[[i]] <- data.table(
      Outcome = labels[i],
      Estimate = format_coef(r),
      SE = format_se(r),
      BW = sprintf("%.1f", r$bw),
      N_left = r$n_left,
      N_right = r$n_right
    )
  }
}

tab2 <- rbindlist(tab2_rows)

tab2_tex <- kable(tab2, format = "latex", booktabs = TRUE,
                   col.names = c("Outcome", "RD Estimate", "Robust SE",
                                 "Bandwidth", "N (left)", "N (right)"),
                   caption = "Main RDD Estimates: Effect of 340B Eligibility",
                   label = "tab:main",
                   align = c("l", "c", "c", "c", "c", "c")) |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = "Sharp RDD with local linear fit, triangular kernel, and CCT optimal bandwidth. Robust bias-corrected standard errors. * p<0.10, ** p<0.05, *** p<0.01.",
           general_title = "Notes:", footnote_as_chunk = TRUE)

writeLines(tab2_tex, file.path(TABLES, "tab2_main_results.tex"))

## ============================================================================
## Table 3: Panel Specifications
## ============================================================================

cat("Table 3: Panel Specifications\n")

panel <- analysis[!is.na(dsh_centered)]
panel[, asinh_mcaid_drug := asinh(mcaid_drug_paid)]
panel[, asinh_mcare_drug := asinh(mcare_drug_paid)]

# Col 1: Year FE, ±10pp
m1 <- feols(asinh_mcaid_drug ~ treated * dsh_centered | fiscal_year,
            data = panel[abs(dsh_centered) <= 10], vcov = ~prvdr_num)

# Col 2: Year FE, ±5pp
m2 <- feols(asinh_mcaid_drug ~ treated * dsh_centered | fiscal_year,
            data = panel[abs(dsh_centered) <= 5], vcov = ~prvdr_num)

# Col 3: State + Year FE, ±10pp
m3 <- feols(asinh_mcaid_drug ~ treated * dsh_centered | state_abbr + fiscal_year,
            data = panel[abs(dsh_centered) <= 10], vcov = ~prvdr_num)

# Col 4: Medicare outcome, ±10pp
m4 <- feols(asinh_mcare_drug ~ treated * dsh_centered | fiscal_year,
            data = panel[abs(dsh_centered) <= 10], vcov = ~prvdr_num)

# Col 5: Non-drug placebo, ±10pp
panel[, asinh_nondrug := asinh(mcaid_nondrug_paid)]
m5 <- feols(asinh_nondrug ~ treated * dsh_centered | fiscal_year,
            data = panel[abs(dsh_centered) <= 10], vcov = ~prvdr_num)

tab3_tex <- etable(m1, m2, m3, m4, m5,
                    headers = c("Medicaid Drug", "Medicaid Drug", "Medicaid Drug",
                                "Medicare Drug", "Non-Drug Placebo"),
                    se.below = TRUE,
                    keep = "%treated",
                    dict = c(treated = "340B Eligible",
                             dsh_centered = "DSH Centered",
                             "treated:dsh_centered" = "340B $\\times$ DSH"),
                    tex = TRUE,
                    style.tex = style.tex("aer"),
                    fitstat = ~ n + r2,
                    notes = c("Bandwidth: $\\pm$10pp (cols 1,3-5), $\\pm$5pp (col 2).",
                              "Clustered SEs by hospital."))

writeLines(tab3_tex, file.path(TABLES, "tab3_panel.tex"))

## ============================================================================
## Table 4: Bandwidth Sensitivity
## ============================================================================

cat("Table 4: Bandwidth Sensitivity\n")

bw_df <- rbindlist(robustness$bandwidth)
bw_df[, stars := fcase(
  pval < 0.01, "***",
  pval < 0.05, "**",
  pval < 0.10, "*",
  default = ""
)]
bw_df[, Estimate := sprintf("%.3f%s", coef, stars)]
bw_df[, SE := sprintf("(%.3f)", se)]
bw_df[, N := paste0(n_left, "/", n_right)]

tab4 <- bw_df[, .(Bandwidth = sprintf("%dpp", bw), Estimate, SE, N)]

tab4_tex <- kable(tab4, format = "latex", booktabs = TRUE,
                   col.names = c("Bandwidth", "RD Estimate", "Robust SE", "N (left/right)"),
                   caption = "Bandwidth Sensitivity: Medicaid Drug Spending",
                   label = "tab:bandwidth",
                   align = c("l", "c", "c", "c")) |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = "Fixed bandwidth RDD estimates. Triangular kernel, local linear. * p<0.10, ** p<0.05, *** p<0.01.",
           general_title = "Notes:", footnote_as_chunk = TRUE)

writeLines(tab4_tex, file.path(TABLES, "tab4_bandwidth.tex"))

## ============================================================================
## Table 5: Donut Hole Sensitivity
## ============================================================================

cat("Table 5: Donut Hole\n")

donut_df <- rbindlist(robustness$donut)
donut_df[, stars := fcase(
  pval < 0.01, "***",
  pval < 0.05, "**",
  pval < 0.10, "*",
  default = ""
)]

tab5 <- data.table(
  Donut = sprintf("$\\pm$%.2fpp", donut_df$donut),
  Estimate = sprintf("%.3f%s", donut_df$coef, donut_df$stars),
  SE = sprintf("(%.3f)", donut_df$se),
  pval = sprintf("%.3f", donut_df$pval)
)

tab5_tex <- kable(tab5, format = "latex", booktabs = TRUE, escape = FALSE,
                   col.names = c("Donut", "RD Estimate", "Robust SE", "p-value"),
                   caption = "Donut Hole Sensitivity",
                   label = "tab:donut",
                   align = c("l", "c", "c", "c")) |>
  kable_styling(latex_options = c("hold_position"))

writeLines(tab5_tex, file.path(TABLES, "tab5_donut.tex"))

## ============================================================================
## Table 6: Crosswalk Validation
## ============================================================================

cat("Table 6: Crosswalk Validation\n")

xwalk_val <- readRDS(file.path(DATA, "crosswalk_validation.rds"))

tab6 <- xwalk_val$match_by_bin[, .(
  `DSH Bin` = as.character(dsh_bin),
  `Total` = n_hospitals,
  `Matched` = n_matched,
  `Rate (%)` = match_rate
)]

tab6_tex <- kable(tab6, format = "latex", booktabs = TRUE,
                   caption = "CCN-NPI Crosswalk Match Rates by DSH Bin",
                   label = "tab:crosswalk",
                   align = c("l", "c", "c", "c")) |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = "Match rates for general acute care hospitals by DSH adjustment percentage bin. Matching uses ZIP code and NPPES taxonomy 282N, with Medicaid drug billing volume as tiebreaker.",
           general_title = "Notes:", footnote_as_chunk = TRUE)

writeLines(tab6_tex, file.path(TABLES, "tab6_crosswalk.tex"))

cat("\n=== All tables saved ===\n")
