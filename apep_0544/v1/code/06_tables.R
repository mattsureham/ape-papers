## =============================================================
## 06_tables.R — All table generation
## apep_0544: Russian Gas Shock and European Manufacturing
## =============================================================

source("00_packages.R")

cat("=== GENERATING TABLES ===\n")

## -----------------------------------------------------------------
## Load results
## -----------------------------------------------------------------
results     <- readRDS(file.path(DATA_DIR, "main_results.rds"))
panel       <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
key_results <- fread(file.path(DATA_DIR, "key_results.csv"))
sum_stats   <- fread(file.path(DATA_DIR, "summary_statistics.csv"))
loo_results <- fread(file.path(DATA_DIR, "loo_results.csv"))
robustness  <- fread(file.path(DATA_DIR, "robustness_summary.csv"))
country_sum <- fread(file.path(DATA_DIR, "country_summary.csv"))
sector_sum  <- fread(file.path(DATA_DIR, "sector_summary.csv"))

## -----------------------------------------------------------------
## Table 1: Summary Statistics
## -----------------------------------------------------------------
cat("  Table 1: Summary statistics...\n")

tab1_tex <- kable(sum_stats[, .(Variable, N, Mean = round(mean, 2),
                                 SD = round(sd, 2),
                                 Min = round(min, 2),
                                 Max = round(max, 2))],
                   format = "latex", booktabs = TRUE,
                   caption = "Summary Statistics",
                   label = "tab:sumstats") |>
  kable_styling(latex_options = c("hold_position"))

writeLines(tab1_tex, file.path(TABLE_DIR, "tab1_summary_stats.tex"))

## -----------------------------------------------------------------
## Table 2: Main Results — Building up fixed effects
## -----------------------------------------------------------------
cat("  Table 2: Main results...\n")

m1 <- results$main_models$m1
m2 <- results$main_models$m2
m3 <- results$main_models$m3
m4 <- results$main_models$m4

# Map coefficient names for display
cm <- c("treatment_intensity:post" = "Gas Dependence $\\times$ Post")

# Fixed effects rows
fe_rows <- data.frame(
  term = c("Country FE", "Sector FE", "Month FE",
           "Country $\\times$ Sector FE",
           "Sector $\\times$ Month FE",
           "Country $\\times$ Month FE"),
  `(1)` = c("Yes", "Yes", "Yes", "", "", ""),
  `(2)` = c("", "", "Yes", "Yes", "", ""),
  `(3)` = c("", "", "", "Yes", "Yes", ""),
  `(4)` = c("", "", "", "Yes", "Yes", "Yes"),
  check.names = FALSE
)
attr(fe_rows, "position") <- c(5, 6, 7, 8, 9, 10)

options("modelsummary_format_numeric_latex" = "plain")

modelsummary(
  list("(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = cm,
  gof_map = c("nobs", "r.squared"),
  add_rows = fe_rows,
  output = file.path(TABLE_DIR, "tab2_main_results.tex"),
  title = "Effect of Russian Gas Dependence on Manufacturing Production",
  notes = list(
    "Dependent variable: log industrial production index (2015=100).",
    "Treatment intensity = Russian gas import share (2021) x sector gas intensity (2019) x Post (Mar 2022+).",
    "Standard errors clustered by country and sector in parentheses."
  )
)

## -----------------------------------------------------------------
## Table 3: Robustness checks
## -----------------------------------------------------------------
cat("  Table 3: Robustness...\n")

tab3_tex <- kable(robustness,
                   format = "latex", booktabs = TRUE,
                   col.names = c("Specification", "Estimate"),
                   caption = "Robustness Checks",
                   label = "tab:robustness") |>
  kable_styling(latex_options = c("hold_position"))

writeLines(tab3_tex, file.path(TABLE_DIR, "tab3_robustness.tex"))

## -----------------------------------------------------------------
## Table 4: Country-level Russian gas dependence (2021)
## -----------------------------------------------------------------
cat("  Table 4: Country gas dependence...\n")

country_tab <- country_sum[, .(Country = geo,
                                `Gas Share` = round(russian_gas_share, 3),
                                Sectors = n_sectors,
                                Months = n_months,
                                `Mean IP` = round(mean_ip, 1),
                                `SD IP` = round(sd_ip, 1))]
country_tab <- country_tab[order(-`Gas Share`)]

tab4_tex <- kable(country_tab,
                   format = "latex", booktabs = TRUE,
                   caption = "Country-Level Russian Gas Dependence and Sample Coverage",
                   label = "tab:countries") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

writeLines(tab4_tex, file.path(TABLE_DIR, "tab4_countries.tex"))

## -----------------------------------------------------------------
## Table 5: Sector-level gas intensity
## -----------------------------------------------------------------
cat("  Table 5: Sector gas intensity...\n")

sector_tab <- sector_sum[, .(Sector = nace_r2,
                              `Gas Intensity` = round(gas_intensity, 3),
                              Countries = n_countries,
                              `Mean IP` = round(mean_ip, 1),
                              `SD IP` = round(sd_ip, 1))]
sector_tab <- sector_tab[order(-`Gas Intensity`)]

tab5_tex <- kable(sector_tab,
                   format = "latex", booktabs = TRUE,
                   caption = "Sector-Level Gas Intensity and Sample Coverage",
                   label = "tab:sectors") |>
  kable_styling(latex_options = c("hold_position"))

writeLines(tab5_tex, file.path(TABLE_DIR, "tab5_sectors.tex"))

## -----------------------------------------------------------------
## Table 6: Mechanism — Producer prices
## -----------------------------------------------------------------
cat("  Table 6: Mechanism...\n")

if (!is.null(results$mechanism_pp)) {
  m_pp <- results$mechanism_pp

  modelsummary(
    list("Production" = m4, "Producer Prices" = m_pp),
    stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
    coef_map = cm,
    gof_map = c("nobs", "r.squared"),
    output = file.path(TABLE_DIR, "tab6_mechanism.tex"),
    title = "Mechanism: Production Decline and Price Pass-Through",
    notes = list(
      "Column 1: log industrial production index. Column 2: log producer price index.",
      "Both specifications include country x sector, country x month, and sector x month FE.",
      "Standard errors clustered by country and sector."
    )
  )
}

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Tables saved to:", TABLE_DIR, "\n")
