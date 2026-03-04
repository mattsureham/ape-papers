## =============================================================================
## 06_tables.R — All tables for paper
## APEP-0498: The Austerity Mortality Gradient
## =============================================================================

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))

panel_pre_covid <- panel[year <= 2019]

## ---------------------------------------------------------------------------
## Table 1: Summary Statistics
## ---------------------------------------------------------------------------
cat("Creating Table 1: Summary statistics...\n")

## Pre-period (2006-2014) vs Post-period (2015-2019)
sum_vars <- c("drug_death_rate", "alcohol_mortality", "under75_mortality",
              "drug_treatment_opiate", "ph_grant_per_head", "cancer_mortality",
              "liver_disease_mortality")

sum_labels <- c("Drug misuse deaths (per 100k)", "Alcohol-specific mortality (per 100k)",
                "Under-75 all-cause mortality (per 100k)", "Opiate treatment completion (%)",
                "Real PH spend per head (£)", "Cancer mortality under-75 (per 100k)",
                "Liver disease mortality under-75 (per 100k)")

make_summary <- function(dt, vars, labels) {
  out <- data.table()
  for (i in seq_along(vars)) {
    v <- vars[i]
    if (v %in% names(dt)) {
      x <- dt[[v]]
      x <- x[!is.na(x)]
      out <- rbind(out, data.table(
        Variable = labels[i],
        Mean = round(mean(x), 2),
        SD = round(sd(x), 2),
        Min = round(min(x), 2),
        Max = round(max(x), 2),
        N = length(x)
      ))
    }
  }
  out
}

sum_pre <- make_summary(panel[year %in% 2006:2014], sum_vars, sum_labels)
sum_post <- make_summary(panel[year %in% 2015:2019], sum_vars, sum_labels)
sum_full <- make_summary(panel, sum_vars, sum_labels)

## Combine
sum_table <- merge(
  sum_full[, .(Variable, `Full Mean` = Mean, `Full SD` = SD, N)],
  merge(
    sum_pre[, .(Variable, `Pre Mean` = Mean, `Pre SD` = SD)],
    sum_post[, .(Variable, `Post Mean` = Mean, `Post SD` = SD)],
    by = "Variable", all = TRUE
  ),
  by = "Variable", all = TRUE
)

fwrite(sum_table, file.path(TABLE_DIR, "table1_summary.csv"))
cat("  Saved: table1_summary.csv\n")
print(sum_table)

## ---------------------------------------------------------------------------
## Table 2: Main Results — Continuous Treatment DiD
## ---------------------------------------------------------------------------
cat("\nCreating Table 2: Main results...\n")

main_models <- list()
if ("primary_drug" %in% names(results)) main_models$`(1) Drug Deaths` <- results$primary_drug
if ("primary_alc" %in% names(results)) main_models$`(2) Alcohol` <- results$primary_alc
if ("primary_u75" %in% names(results)) main_models$`(3) Under-75` <- results$primary_u75
if ("primary_treat" %in% names(results)) main_models$`(4) Treatment` <- results$primary_treat

if (length(main_models) > 0) {
  ## Export regression table
  tab2 <- modelsummary(main_models,
                       stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
                       gof_map = c("nobs", "r.squared", "adj.r.squared"),
                       output = "data.frame")
  fwrite(as.data.table(tab2), file.path(TABLE_DIR, "table2_main_results.csv"))
  cat("  Saved: table2_main_results.csv\n")

  ## Also save as LaTeX
  modelsummary(main_models,
               stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
               gof_map = c("nobs", "r.squared"),
               title = "Effect of Public Health Spending on Mortality Outcomes (2006--2019)",
               notes = "Clustered standard errors at LA level in parentheses. All regressions include LA and year fixed effects.",
               output = file.path(TABLE_DIR, "table2_main_results.tex"))
  cat("  Saved: table2_main_results.tex\n")
}

## ---------------------------------------------------------------------------
## Table 3: Tercile-Based DiD
## ---------------------------------------------------------------------------
cat("\nCreating Table 3: Tercile DiD...\n")

terc_models <- list()
if ("tercile_drug" %in% names(results)) terc_models$`(1) Drug Deaths` <- results$tercile_drug
if ("tercile_alc" %in% names(results)) terc_models$`(2) Alcohol` <- results$tercile_alc

if (length(terc_models) > 0) {
  tab3 <- modelsummary(terc_models,
                       stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
                       gof_map = c("nobs", "r.squared"),
                       output = "data.frame")
  fwrite(as.data.table(tab3), file.path(TABLE_DIR, "table3_tercile_did.csv"))

  modelsummary(terc_models,
               stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
               gof_map = c("nobs", "r.squared"),
               title = "Mortality Effects by Grant Cut Tercile",
               notes = "Omitted category: Protected tercile (smallest cuts/increases). Standard errors clustered at LA level.",
               output = file.path(TABLE_DIR, "table3_tercile_did.tex"))
  cat("  Saved: table3_tercile_did.csv and .tex\n")
}

## ---------------------------------------------------------------------------
## Table 4: Full Panel with COVID Controls
## ---------------------------------------------------------------------------
cat("\nCreating Table 4: Full panel...\n")

full_models <- list()
if ("full_drug" %in% names(results)) full_models$`(1) Drug Deaths` <- results$full_drug
if ("full_alc" %in% names(results)) full_models$`(2) Alcohol` <- results$full_alc
if ("full_u75" %in% names(results)) full_models$`(3) Under-75` <- results$full_u75

if (length(full_models) > 0) {
  tab4 <- modelsummary(full_models,
                       stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
                       gof_map = c("nobs", "r.squared"),
                       output = "data.frame")
  fwrite(as.data.table(tab4), file.path(TABLE_DIR, "table4_full_panel.csv"))

  modelsummary(full_models,
               stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
               gof_map = c("nobs", "r.squared"),
               title = "Full Panel Results Including COVID Period (2006--2024)",
               notes = "COVID period (2020--2021) controlled with indicator variable.",
               output = file.path(TABLE_DIR, "table4_full_panel.tex"))
  cat("  Saved: table4_full_panel.csv and .tex\n")
}

## ---------------------------------------------------------------------------
## Table 5: Placebo Outcomes
## ---------------------------------------------------------------------------
cat("\nCreating Table 5: Placebo results...\n")

placebo_models <- list()
if ("placebo_cancer" %in% names(results)) {
  placebo_models$`(1) Cancer\n(Placebo)` <- results$placebo_cancer
}

## Re-estimate liver disease as positive control
m_liver <- tryCatch({
  feols(liver_disease_mortality ~ ph_grant_per_head | la_code + year,
        data = panel_pre_covid[!is.na(liver_disease_mortality) & !is.na(ph_grant_per_head)],
        cluster = ~la_code)
}, error = function(e) NULL)

if (!is.null(m_liver)) placebo_models$`(2) Liver Disease\n(Positive Control)` <- m_liver

## Main drug result for comparison
if ("primary_drug" %in% names(results)) {
  placebo_models$`(3) Drug Deaths\n(Main)` <- results$primary_drug
}

if (length(placebo_models) > 0) {
  tab5 <- modelsummary(placebo_models,
                       stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
                       gof_map = c("nobs", "r.squared"),
                       output = "data.frame")
  fwrite(as.data.table(tab5), file.path(TABLE_DIR, "table5_placebos.csv"))

  modelsummary(placebo_models,
               stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
               gof_map = c("nobs", "r.squared"),
               title = "Placebo and Positive Control Outcomes",
               notes = "Cancer mortality (long latency) should not respond to PH cuts. Liver disease should respond. Drug deaths = main result for comparison.",
               output = file.path(TABLE_DIR, "table5_placebos.tex"))
  cat("  Saved: table5_placebos.csv and .tex\n")
}

## ---------------------------------------------------------------------------
## Table 6: Grant Tercile Characteristics
## ---------------------------------------------------------------------------
cat("\nCreating Table 6: Tercile characteristics...\n")

if ("grant_tercile" %in% names(panel)) {
  tercile_chars <- panel[year == 2014 & !is.na(grant_tercile), .(
    `N LAs` = .N,
    `Mean Drug Death Rate` = round(mean(drug_death_rate, na.rm = TRUE), 1),
    `Mean Alcohol Mortality` = round(mean(alcohol_mortality, na.rm = TRUE), 1),
    `Mean PH Spend per Head` = round(mean(ph_grant_per_head, na.rm = TRUE), 0),
    `Mean Treatment Completion` = round(mean(drug_treatment_opiate, na.rm = TRUE), 1)
  ), by = grant_tercile]

  fwrite(tercile_chars, file.path(TABLE_DIR, "table6_tercile_chars.csv"))
  cat("  Saved: table6_tercile_chars.csv\n")
  print(tercile_chars)
}

cat("\n✓ All tables saved to:", TABLE_DIR, "\n")
cat("  Files:", paste(list.files(TABLE_DIR), collapse = ", "), "\n")
