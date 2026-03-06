##============================================================
## 06_tables.R — Generate all tables
## APEP-0543: Rent Control and Property Values in France
##============================================================

source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE)

## Force modelsummary to use kableExtra backend (not tinytable)
options(modelsummary_factory_latex = "kableExtra")

## ─── Load data and models ────────────────────────────────
analysis <- as.data.table(read_parquet(file.path(data_dir, "dvf_analysis.parquet")))
analysis[, log_price := log(valeur_fonciere)]

main_models <- readRDS(file.path(data_dir, "main_models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))
city_results <- fread(file.path(data_dir, "city_by_city_results.csv"))
loo_results <- fread(file.path(data_dir, "robustness_loo.csv"))
ri_results <- fread(file.path(data_dir, "ri_results.csv"))

## ──────────────────────────────────────────────────────────
## TABLE 1: Summary Statistics
## ──────────────────────────────────────────────────────────

cat("Table 1: Summary statistics...\n")

make_summary <- function(dt, label) {
  data.table(
    Group = label,
    N = nrow(dt),
    `Median Price (€)` = median(dt$valeur_fonciere),
    `Mean Price (€)` = round(mean(dt$valeur_fonciere)),
    `Median m²` = median(dt$surface_reelle_bati, na.rm = TRUE),
    `Median €/m²` = median(dt$price_sqm, na.rm = TRUE),
    `% Apartments` = round(mean(dt$type_local == "Appartement") * 100, 1),
    `% Investment` = round(mean(dt$investment_type) * 100, 1),
    `Mean Rooms` = round(mean(dt$nombre_pieces_principales, na.rm = TRUE), 1)
  )
}

analysis[, price_sqm := fifelse(
  !is.na(surface_reelle_bati) & surface_reelle_bati > 0,
  valeur_fonciere / surface_reelle_bati, NA_real_
)]

summ_table <- rbind(
  make_summary(analysis, "Full Sample"),
  make_summary(analysis[treated_commune == TRUE & !post_treatment], "Treated: Pre"),
  make_summary(analysis[treated_commune == TRUE & post_treatment], "Treated: Post"),
  make_summary(analysis[control_city == TRUE], "Control Cities"),
  make_summary(analysis[investment_type == TRUE], "Investment-Type"),
  make_summary(analysis[investment_type == FALSE], "Owner-Occupier")
)

fwrite(summ_table, file.path(tab_dir, "table1_summary.csv"))

## LaTeX version
summ_latex <- kbl(summ_table, format = "latex", booktabs = TRUE,
                  caption = "Summary Statistics",
                  label = "tab:summary",
                  format.args = list(big.mark = ",")) %>%
  kable_styling(latex_options = c("scale_down", "hold_position"))

writeLines(summ_latex, file.path(tab_dir, "table1_summary.tex"))

## ──────────────────────────────────────────────────────────
## TABLE 2: Main Results
## ──────────────────────────────────────────────────────────

cat("Table 2: Main results...\n")

## Use modelsummary for clean output
main_table <- modelsummary(
  main_models,
  output = "latex",
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = c(
    "post_treatmentTRUE" = "Post $\\times$ Treated",
    "investment_typeTRUE" = "Investment Type",
    "post_treatmentTRUE:investment_typeTRUE" = "Post $\\times$ Treated $\\times$ Investment",
    "post_treatmentTRUE:rental_score" = "Post $\\times$ Treated $\\times$ Rental Score",
    "rental_score" = "Rental Score",
    "surface_reelle_bati" = "Surface (m$^2$)",
    "I(surface_reelle_bati^2)" = "Surface$^2$",
    "nombre_pieces_principales" = "Rooms"
  ),
  gof_map = c("nobs", "r.squared", "FE: code_commune", "FE: year_quarter"),
  title = "Effect of Rent Control on Property Prices",
  notes = c("Standard errors clustered at commune level in parentheses.",
            "All specifications include commune and year-quarter fixed effects."),
  escape = FALSE
)

writeLines(main_table, file.path(tab_dir, "table2_main_results.tex"))

## Also save as CSV for verification
main_csv <- modelsummary(main_models, output = "dataframe",
                          stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01))
fwrite(main_csv, file.path(tab_dir, "table2_main_results.csv"))

## ──────────────────────────────────────────────────────────
## TABLE 3: Robustness
## ──────────────────────────────────────────────────────────

cat("Table 3: Robustness...\n")

rob_table <- modelsummary(
  c(main_models["DDD"], rob_models),
  output = "latex",
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = c(
    "post_treatmentTRUE:investment_typeTRUE" = "DDD Coefficient",
    "post_treatmentTRUE" = "Post $\\times$ Treated",
    "postTRUE" = "Post $\\times$ Treated"
  ),
  gof_map = c("nobs", "r.squared"),
  title = "Robustness Checks",
  notes = c("Column 1: baseline DDD. Column 2: excluding 2020Q2-Q4.",
            "Column 3: post-COVID cities only (Lyon, Bordeaux, Montpellier).",
            "Column 4: apartment size heterogeneity."),
  escape = FALSE
)

writeLines(rob_table, file.path(tab_dir, "table3_robustness.tex"))

## ──────────────────────────────────────────────────────────
## TABLE 4: City-by-city estimates
## ──────────────────────────────────────────────────────────

cat("Table 4: City-by-city...\n")

city_table <- city_results[, .(
  City = city,
  `DDD Coef.` = round(ddd_coef, 4),
  `Std. Error` = round(ddd_se, 4),
  `p-value` = round(ddd_pval, 3),
  N = format(n_obs, big.mark = ","),
  `N Treated` = format(n_treated, big.mark = ",")
)]

city_latex <- kbl(city_table, format = "latex", booktabs = TRUE,
                  caption = "City-by-City Triple-Difference Estimates",
                  label = "tab:city_estimates",
                  align = "lccccr") %>%
  kable_styling(latex_options = "hold_position")

writeLines(city_latex, file.path(tab_dir, "table4_city_estimates.tex"))
fwrite(city_table, file.path(tab_dir, "table4_city_estimates.csv"))

## ──────────────────────────────────────────────────────────
## TABLE 5: Leave-one-out
## ──────────────────────────────────────────────────────────

cat("Table 5: Leave-one-out...\n")

loo_table <- loo_results[, .(
  `Dropped City` = dropped_city,
  `DDD Coef.` = round(ddd_coef, 4),
  `Std. Error` = round(ddd_se, 4),
  `p-value` = round(ddd_pval, 3),
  N = format(n_obs, big.mark = ",")
)]

loo_latex <- kbl(loo_table, format = "latex", booktabs = TRUE,
                 caption = "Leave-One-Out Stability: Triple-Difference Estimates",
                 label = "tab:loo",
                 align = "lcccc") %>%
  kable_styling(latex_options = "hold_position")

writeLines(loo_latex, file.path(tab_dir, "table5_leave_one_out.tex"))
fwrite(loo_table, file.path(tab_dir, "table5_leave_one_out.csv"))

cat("\n06_tables.R complete. All tables saved to tables/\n")
cat("Generated:", length(list.files(tab_dir)), "table files\n")
