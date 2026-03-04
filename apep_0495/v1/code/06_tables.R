## 06_tables.R — Publication-quality tables
## apep_0495: Private School VAT and State School Housing Premium

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

cat("=== GENERATING TABLES ===\n")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date_transfer := as.Date(date_transfer)]
panel[, prop_type := factor(property_type)]
la_treatment <- fread(file.path(data_dir, "la_treatment_intensity.csv"))

load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

## =========================================================================
## Table 1: Summary Statistics
## =========================================================================
cat("--- Table 1: Summary Statistics ---\n")

## Pre-treatment (2015-2023) vs post-treatment (2025-2026)
panel[, period := fcase(
  date_transfer < as.Date("2024-07-01"), "Pre-Announcement",
  date_transfer >= as.Date("2024-07-01") & date_transfer < as.Date("2025-01-01"), "Anticipation",
  date_transfer >= as.Date("2025-01-01"), "Post-VAT"
)]

sumstats <- panel[, .(
  `Mean Price (£)` = format(round(mean(price, na.rm = TRUE)), big.mark = ","),
  `Median Price (£)` = format(round(median(price, na.rm = TRUE)), big.mark = ","),
  `SD Log Price` = round(sd(log_price, na.rm = TRUE), 3),
  `Pct Detached` = round(100 * mean(property_type == "D", na.rm = TRUE), 1),
  `Pct Flat` = round(100 * mean(property_type == "F", na.rm = TRUE), 1),
  `Pct Near Good School` = round(100 * mean(near_good_school, na.rm = TRUE), 1),
  `Mean Private Share (%)` = round(100 * mean(private_share, na.rm = TRUE), 1),
  `N Transactions` = format(.N, big.mark = ","),
  `N LAs` = uniqueN(la_code),
  `N Postcode Sectors` = format(uniqueN(pc_sector), big.mark = ",")
), by = period]

## Transpose for LaTeX
sumstats_t <- t(sumstats)
colnames(sumstats_t) <- sumstats_t[1, ]
sumstats_t <- sumstats_t[-1, , drop = FALSE]

## Write LaTeX table
cat("\\begin{table}[htbp]\n", file = file.path(tables_dir, "summary_stats.tex"))
cat("\\centering\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\caption{Summary Statistics by Period}\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\label{tab:sumstats}\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\begin{adjustbox}{max width=\\textwidth}\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\begin{tabular}{lccc}\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\hline\\hline\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat(" & Pre-Announcement & Anticipation & Post-VAT \\\\\n",
    file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat(" & (2015--Jun 2024) & (Jul--Dec 2024) & (Jan 2025--) \\\\\n",
    file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\hline\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)

row_names <- rownames(sumstats_t)
for (i in seq_len(nrow(sumstats_t))) {
  row_vals <- paste(sumstats_t[i, ], collapse = " & ")
  cat(row_names[i], " & ", row_vals, " \\\\\n",
      file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
}

cat("\\hline\\hline\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\end{tabular}\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\end{adjustbox}\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\begin{tablenotes}\\small\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\item \\textit{Notes:} Sample includes all standard residential property transactions in England from HM Land Registry Price Paid Data (Category A). ``Near Good School'' defined as within 3km of an Outstanding or Good-rated state secondary school. ``Private Share'' is the LA-level share of pupils enrolled in independent schools, from DfE GIAS.\n",
    file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\end{tablenotes}\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)
cat("\\end{table}\n", file = file.path(tables_dir, "summary_stats.tex"), append = TRUE)

cat("  Saved summary_stats.tex\n")

## =========================================================================
## Table 2: Main Results (DDD)
## =========================================================================
cat("--- Table 2: Main Results ---\n")

etable(m_dd, m1, m2, m3,
       title = "The Effect of Private School VAT on State School Housing Premium",
       headers = c("DD", "DDD (LA FE)", "DDD (PC Sector FE)", "DDD (Continuous)"),
       dict = c(
         "high_private:post_vat" = "High Private $\\times$ Post",
         "high_private:near_good_school:post_vat" = "High Private $\\times$ Near Good $\\times$ Post",
         "private_share:near_good_school:post_vat" = "Private Share $\\times$ Near Good $\\times$ Post",
         "high_private:near_good_school" = "High Private $\\times$ Near Good",
         "near_good_school:post_vat" = "Near Good $\\times$ Post",
         "high_private:post_vat" = "High Private $\\times$ Post"
       ),
       label = "tab:main",
       notes = c(
         "Standard errors clustered at the Local Authority level in parentheses.",
         "``High Private'' is an indicator for LAs above the median private school pupil share.",
         "``Near Good'' is an indicator for properties within 3km of an Outstanding/Good-rated state secondary.",
         "``Post'' is an indicator for transactions after January 1, 2025.",
         "All models include property type, new-build, and tenure controls.",
         "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
       ),
       file = file.path(tables_dir, "main_results.tex"),
       style.tex = style.tex("aer"),
       replace = TRUE)
cat("  Saved main_results.tex\n")

## =========================================================================
## Table 3: Announcement Decomposition
## =========================================================================
cat("--- Table 3: Announcement Decomposition ---\n")

etable(m4,
       title = "Decomposing the Policy Effect: Announcement, Budget, and Implementation",
       dict = c(
         "high_private:near_good_school:post_announce" = "High Priv $\\times$ Near Good $\\times$ Post-Election",
         "high_private:near_good_school:post_budget" = "High Priv $\\times$ Near Good $\\times$ Post-Budget",
         "high_private:near_good_school:post_vat" = "High Priv $\\times$ Near Good $\\times$ Post-VAT"
       ),
       label = "tab:announce",
       notes = c(
         "Standard errors clustered at the Local Authority level in parentheses.",
         "Post-Election: after July 4, 2024. Post-Budget: after October 30, 2024. Post-VAT: after January 1, 2025.",
         "Model includes postcode-sector and year-month fixed effects, property controls.",
         "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
       ),
       file = file.path(tables_dir, "announcement_decomp.tex"),
       style.tex = style.tex("aer"),
       replace = TRUE)
cat("  Saved announcement_decomp.tex\n")

## =========================================================================
## Table 4: Heterogeneity (London vs non-London, by property type)
## =========================================================================
cat("--- Table 4: Heterogeneity ---\n")

het_models <- list()
if (exists("m_london") && length(m_london) >= 2) {
  het_models[["Non-London"]] <- m_london[[1]]
  ## London subsample excluded: too few LA clusters for reliable inference
}
het_models[["Houses"]] <- m_houses
het_models[["Flats"]] <- m_flats

if (length(het_models) > 0) {
  etable(het_models,
         title = "Heterogeneity by Property Type and Geography",
         dict = c(
           "high_private:near_good_school:post_vat" = "High Priv $\\times$ Near Good $\\times$ Post"
         ),
         label = "tab:heterogeneity",
         notes = c(
           "Standard errors clustered at the Local Authority level in parentheses.",
           "Each column restricts the sample to the indicated subgroup.",
           "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
         ),
         file = file.path(tables_dir, "heterogeneity.tex"),
         style.tex = style.tex("aer"),
         replace = TRUE)
  cat("  Saved heterogeneity.tex\n")
}

## =========================================================================
## Table 5: Placebo Tests
## =========================================================================
cat("--- Table 5: Placebo Tests ---\n")

rob_summary <- fread(file.path(tables_dir, "robustness_summary.csv"))

## Write LaTeX
cat("\\begin{table}[htbp]\n", file = file.path(tables_dir, "placebos.tex"))
cat("\\centering\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\caption{Placebo Tests and Robustness}\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\label{tab:placebos}\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\begin{tabular}{lcc}\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\hline\\hline\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("Test & Coefficient & SE \\\\\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\hline\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)

for (i in seq_len(nrow(rob_summary))) {
  cat(rob_summary$Test[i], " & ",
      sprintf("%.4f%s", rob_summary$Coefficient[i], rob_summary$Stars[i]), " & (",
      sprintf("%.4f", rob_summary$SE[i]), ") \\\\\n",
      file = file.path(tables_dir, "placebos.tex"), append = TRUE)
}

cat("\\hline\\hline\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\end{tabular}\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\begin{tablenotes}\\small\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\item \\textit{Notes:} Each row reports the DDD coefficient from a separate regression. ``Temporal placebo'' uses January 2020 as a fake treatment date on pre-2024 data. ``Flats only'' and ``Houses only'' restrict by property type. Distance rows vary the school proximity cutoff. Standard errors clustered at LA level.\n",
    file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\end{tablenotes}\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)
cat("\\end{table}\n", file = file.path(tables_dir, "placebos.tex"), append = TRUE)

cat("  Saved placebos.tex\n")

## =========================================================================
## Table 6: Within-LA Dispersion
## =========================================================================
cat("--- Table 6: Within-LA Price Dispersion ---\n")

etable(m_disp,
       title = "Within-LA Price Dispersion: Does VAT Increase Spatial Inequality?",
       dict = c("high_private:post_vat" = "High Private $\\times$ Post-VAT"),
       label = "tab:dispersion",
       notes = c(
         "Dependent variable: P90/P10 price ratio within LA-month cells.",
         "Sample restricted to LA-months with at least 20 transactions.",
         "Weighted by number of transactions. LA and year-month fixed effects.",
         "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
       ),
       file = file.path(tables_dir, "dispersion.tex"),
       style.tex = style.tex("aer"),
       replace = TRUE)
cat("  Saved dispersion.tex\n")

cat("\n=== ALL TABLES GENERATED ===\n")
