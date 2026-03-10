## =============================================================================
## 06_tables.R — All tables for the paper
## APEP-0587: Bunching at the UK High Income Child Benefit Charge Notch
## =============================================================================
source("00_packages.R")

data_dir  <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

## ---- Load results -----------------------------------------------------------
bunching_spi   <- fread(file.path(data_dir, "bunching_by_year_spi.csv"))
bunching_ashe  <- fread(file.path(data_dir, "bunching_by_year_ashe.csv"))
boot_results   <- fread(file.path(data_dir, "bunching_bootstrap.csv"))
dib            <- fread(file.path(data_dir, "difference_in_bunching.csv"))
cb_admin       <- fread(file.path(data_dir, "cb_admin.csv"))
summary_stats  <- fread(file.path(data_dir, "summary_bunching.csv"))
pension_dt     <- fread(file.path(data_dir, "pension_by_income.csv"))
se_income      <- fread(file.path(data_dir, "selfemployment_by_income.csv"))
poly_summary   <- fread(file.path(data_dir, "robustness_polynomial_summary.csv"))
window_summary <- fread(file.path(data_dir, "robustness_window_summary.csv"))
placebo_summary <- fread(file.path(data_dir, "robustness_placebo_summary.csv"))
spi_pct        <- fread(file.path(data_dir, "spi_percentiles.csv"))

## =============================================================================
## TABLE 1: Summary Statistics
## =============================================================================

# Income distribution characteristics near £50k threshold
pct_near_50k <- spi_pct[percentile %in% c(80, 85, 90) & tax_year %in% c(2012, 2015, 2018, 2022)]
pct_wide <- dcast(pct_near_50k, tax_year ~ percentile, value.var = "income")
setnames(pct_wide, c("Tax Year", "P80", "P85", "P90"))

# Admin data summary
admin_summary <- cb_admin[year %in% c(2013, 2016, 2019, 2022, 2024),
                           .(year, families_opted_out_k, hicbc_liable_k,
                             hicbc_revenue_m, cb_takeup_pct)]

tab1_income <- data.table(
  Variable = c("Total UK income taxpayers (millions, 2022/23)",
               "P80 total income, 2012 (pre-HICBC)",
               "P80 total income, 2022 (post-HICBC)",
               "P85 total income, 2012",
               "P85 total income, 2022",
               "HICBC threshold (2013\u20132024)",
               "HICBC threshold (2024\u2013present)",
               "Individuals liable for HICBC (thousands, 2022/23)",
               "HICBC revenue (\u00a3 millions, 2022/23)",
               "Families opted out of CB (thousands, 2024)",
               "CB take-up rate, 2012 (%)",
               "CB take-up rate, 2022 (%)"),
  Value = c("34,500", format(pct_wide[`Tax Year` == 2012, P80], big.mark = ","),
            format(pct_wide[`Tax Year` == 2022, P80], big.mark = ","),
            format(pct_wide[`Tax Year` == 2012, P85], big.mark = ","),
            format(pct_wide[`Tax Year` == 2022, P85], big.mark = ","),
            "\u00a350,000", "\u00a360,000", "440", "\u00a3525", "712",
            "97", "88")
)

fwrite(tab1_income, file.path(table_dir, "tab1_summary.csv"))
cat("Table 1 saved.\n")

## =============================================================================
## TABLE 2: Main Bunching Estimates
## =============================================================================

tab2 <- boot_results[, .(
  `Tax Year` = tax_year,
  `$\\hat{b}$` = sprintf("%.4f", b_hat),
  `SE` = sprintf("%.4f", se),
  `$t$-stat` = sprintf("%.2f", t_stat),
  `$p$-value` = sprintf("%.3f", p_value)
)]

fwrite(tab2, file.path(table_dir, "tab2_bunching_main.csv"))
cat("Table 2 saved.\n")

## =============================================================================
## TABLE 3: Channel Decomposition (SPI vs ASHE)
## =============================================================================

# Average bunching by period and data source
tab3_data <- dib[tax_year >= 2005]
pre <- tab3_data[tax_year < 2013]
post <- tab3_data[tax_year >= 2013]

tab3 <- data.table(
  Panel = c("A. All taxpayers (SPI)", "", "",
            "B. PAYE employees (ASHE)", "", "",
            "C. Residual (A \u2013 B)", "", ""),
  Period = rep(c("Pre-HICBC (2005\u20132012)", "Post-HICBC (2013\u20132022)",
                 "Difference"), 3),
  `Mean $\\hat{b}$` = c(
    sprintf("%.4f", mean(pre$b_spi, na.rm = TRUE)),
    sprintf("%.4f", mean(post$b_spi, na.rm = TRUE)),
    sprintf("%.4f", mean(post$b_spi, na.rm = TRUE) - mean(pre$b_spi, na.rm = TRUE)),
    sprintf("%.4f", mean(pre$b_ashe, na.rm = TRUE)),
    sprintf("%.4f", mean(post$b_ashe, na.rm = TRUE)),
    sprintf("%.4f", mean(post$b_ashe, na.rm = TRUE) - mean(pre$b_ashe, na.rm = TRUE)),
    sprintf("%.4f", mean(pre$b_diff, na.rm = TRUE)),
    sprintf("%.4f", mean(post$b_diff, na.rm = TRUE)),
    sprintf("%.4f", mean(post$b_diff, na.rm = TRUE) - mean(pre$b_diff, na.rm = TRUE))
  ),
  N = c(nrow(pre[!is.na(b_spi)]), nrow(post[!is.na(b_spi)]), "",
        nrow(pre[!is.na(b_ashe)]), nrow(post[!is.na(b_ashe)]), "",
        "", "", "")
)

fwrite(tab3, file.path(table_dir, "tab3_channel_decomposition.csv"))
cat("Table 3 saved.\n")

## =============================================================================
## TABLE 4: Pension Contributions by Income Band (HMRC Table 3.5)
## =============================================================================

if (nrow(pension_dt) > 0) {
  pension_dt[, income_label := paste0("\u00a3", format(income_lower, big.mark = ","))]
  pension_dt[, pct_with_pension := round(n_with_pension_k / n_total_k * 100, 1)]
  pension_dt[, mean_pension := round(pension_relief_m / n_with_pension_k * 1000, 0)]

  tab4 <- pension_dt[income_lower >= 20000 & income_lower <= 100000,
                      .(Income = income_label,
                        `Taxpayers (000s)` = format(round(n_total_k), big.mark = ","),
                        `With pension (000s)` = format(round(n_with_pension_k), big.mark = ","),
                        `% with pension` = pct_with_pension,
                        `Mean pension (GBP)` = format(mean_pension, big.mark = ","))]

  fwrite(tab4, file.path(table_dir, "tab4_pension_by_income.csv"))
  cat("Table 4 saved.\n")
}

## =============================================================================
## TABLE 5: Self-Employment Income by Band
## =============================================================================

if (nrow(se_income) > 0) {
  se_income[, income_label := paste0("\u00a3", format(income_lower, big.mark = ","))]
  tab5 <- se_income[income_lower >= 20000 & income_lower <= 100000,
                     .(Income = income_label,
                       `Self-employed (000s)` = format(round(n_se_k), big.mark = ","),
                       `SE income (GBP m)` = format(round(se_income_m), big.mark = ","))]

  fwrite(tab5, file.path(table_dir, "tab5_selfemployment_by_income.csv"))
  cat("Table 5 saved.\n")
}

## =============================================================================
## TABLE 6: Administrative Evidence (CB Opt-Outs, HICBC)
## =============================================================================

tab6 <- cb_admin[, .(
  Year = year,
  `Opted out (000s)` = families_opted_out_k,
  `HICBC liable (000s)` = hicbc_liable_k,
  `Revenue (GBP m)` = hicbc_revenue_m,
  `Take-up (%)` = cb_takeup_pct
)]

fwrite(tab6, file.path(table_dir, "tab6_admin_evidence.csv"))
cat("Table 6 saved.\n")

## =============================================================================
## TABLE C.1 (Appendix): Robustness — Polynomial sensitivity
## =============================================================================

tabC1 <- poly_summary[, .(`Poly. degree` = poly_deg,
                            `Mean $\\hat{b}$` = sprintf("%.4f", mean_b),
                            `SD` = sprintf("%.4f", sd_b))]
fwrite(tabC1, file.path(table_dir, "tabC1_poly_sensitivity.csv"))

## =============================================================================
## TABLE C.2 (Appendix): Robustness — Window sensitivity
## =============================================================================

tabC2 <- window_summary[, .(Window = window,
                              `Mean $\\hat{b}$` = sprintf("%.4f", mean_b),
                              `SD` = sprintf("%.4f", sd_b))]
fwrite(tabC2, file.path(table_dir, "tabC2_window_sensitivity.csv"))

## =============================================================================
## TABLE C.3 (Appendix): Robustness — Round-number placebo
## =============================================================================

placebo_summary[, Income := paste0("\u00a3", format(placebo_income, big.mark = ","))]
tabC3 <- placebo_summary[, .(Income,
                               `Mean $\\hat{b}$` = sprintf("%.4f", mean_b),
                               `SD` = sprintf("%.4f", sd_b))]
fwrite(tabC3, file.path(table_dir, "tabC3_placebo.csv"))

cat("\nAll tables saved to", table_dir, "\n")
