## ============================================================
## 06_tables.R — Generate all tables
## apep_0505: Council Tax Support Localization
## ============================================================

source("00_packages.R")

## ============================================================
## Load Data and Results
## ============================================================
panel <- readRDS(file.path(DATA_DIR, "analysis_panel_final.rds"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
robustness <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))
treatment <- readRDS(file.path(DATA_DIR, "treatment_2018.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("Table 1: Summary statistics\n")

## Full panel summary
summ_full <- panel[, .(
  N = .N,
  Mean = round(mean(jsa_rate, na.rm = TRUE), 2),
  SD = round(sd(jsa_rate, na.rm = TRUE), 2),
  Min = round(min(jsa_rate, na.rm = TRUE), 2),
  Max = round(max(jsa_rate, na.rm = TRUE), 2)
)]
summ_full$Variable <- "JSA Claimant Rate"
summ_full$Period <- "Full Sample"

summ_price <- panel[!is.na(median_price), .(
  N = .N,
  Mean = round(mean(median_price / 1000, na.rm = TRUE), 1),
  SD = round(sd(median_price / 1000, na.rm = TRUE), 1),
  Min = round(min(median_price / 1000, na.rm = TRUE), 1),
  Max = round(max(median_price / 1000, na.rm = TRUE), 1)
)]
summ_price$Variable <- "Median Price (£000s)"
summ_price$Period <- "Full Sample"

summ_trans <- panel[!is.na(n_transactions), .(
  N = .N,
  Mean = round(mean(n_transactions, na.rm = TRUE), 0),
  SD = round(sd(n_transactions, na.rm = TRUE), 0),
  Min = round(min(n_transactions, na.rm = TRUE), 0),
  Max = round(max(n_transactions, na.rm = TRUE), 0)
)]
summ_trans$Variable <- "Transactions"
summ_trans$Period <- "Full Sample"

## Treatment variable
summ_treat <- treatment[!is.na(cts_wa_per_cap), .(
  N = .N,
  Mean = round(mean(cts_wa_per_cap, na.rm = TRUE), 1),
  SD = round(sd(cts_wa_per_cap, na.rm = TRUE), 1),
  Min = round(min(cts_wa_per_cap, na.rm = TRUE), 1),
  Max = round(max(cts_wa_per_cap, na.rm = TRUE), 1)
)]
summ_treat$Variable <- "CTS WA Per Capita (£)"
summ_treat$Period <- "2017/18"

## By treatment quartile
summ_q <- panel[year == 2012, .(
  mean_jsa = round(mean(jsa_rate, na.rm = TRUE), 2),
  mean_price = round(mean(median_price / 1000, na.rm = TRUE), 1),
  mean_cts = round(mean(cts_wa_per_cap, na.rm = TRUE), 1),
  n_la = .N
), by = treat_quartile][order(treat_quartile)]

## Write summary table as LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lrrrrrr}",
  "\\toprule",
  "Variable & N & Mean & SD & Min & Max & Period \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Full Sample (285 LAs, 2008--2019)}} \\\\",
  paste0("JSA Claimant Rate (\\%) & ", summ_full$N, " & ", summ_full$Mean,
         " & ", summ_full$SD, " & ", summ_full$Min, " & ", summ_full$Max,
         " & 2008--2019 \\\\"),
  paste0("Median House Price (\\pounds 000s) & ", summ_price$N, " & ", summ_price$Mean,
         " & ", summ_price$SD, " & ", summ_price$Min, " & ", summ_price$Max,
         " & 2008--2019 \\\\"),
  paste0("Transactions & ", summ_trans$N, " & ", summ_trans$Mean,
         " & ", summ_trans$SD, " & ", summ_trans$Min, " & ", summ_trans$Max,
         " & 2008--2019 \\\\"),
  paste0("CTS WA Expend. Per Capita (\\pounds) & ", summ_treat$N, " & ", summ_treat$Mean,
         " & ", summ_treat$SD, " & ", summ_treat$Min, " & ", summ_treat$Max,
         " & 2017/18 \\\\"),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Pre-Reform Means by Treatment Quartile (2012)}} \\\\",
  " & N LAs & JSA Rate & House Price & CTS/Cap & & \\\\",
  "\\cmidrule{2-5}"
)

for (i in seq_len(nrow(summ_q))) {
  qlabel <- c("Q1 (Least Generous)", "Q2", "Q3", "Q4 (Most Generous)")[i]
  tab1_lines <- c(tab1_lines,
    paste0(qlabel, " & ", summ_q$n_la[i], " & ", summ_q$mean_jsa[i],
           " & ", summ_q$mean_price[i], " & ", summ_q$mean_cts[i], " & & \\\\"))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{flushleft}",
  "\\footnotesize",
  "\\textit{Notes:} Panel A reports full-sample statistics for the analysis panel. JSA Claimant Rate is Jobseeker's Allowance claimants per 100 working-age population. CTS Working-Age Expenditure Per Capita is from Revenue Outturn 2017/18 data. Panel B shows pre-reform (2012) means by treatment quartile, where quartiles are defined by 2017/18 CTS generosity. House prices in thousands of pounds from HM Land Registry Price Paid Data.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(TAB_DIR, "tab1_summary.tex"))

## ============================================================
## Table 2: Main DiD Results
## ============================================================
cat("Table 2: Main results\n")

## Use modelsummary for clean output
models_main <- list(
  "JSA Rate\n(1)" = results$m1_jsa,
  "Log Price\n(2)" = results$m2_price,
  "Log Med.\nPrice (3)" = results$m3_level,
  "Log Trans.\n(4)" = results$m4_trans
)

cm <- c(
  "cut_intensity:post" = "Cut Intensity $\\times$ Post",
  "cut_intensity::post" = "Cut Intensity $\\times$ Post"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = 0),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 3),
  list("raw" = "FE: la_code", "clean" = "LA FE", "fmt" = 0),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = 0)
)

msummary(models_main,
         output = file.path(TAB_DIR, "tab2_main_results.tex"),
         coef_map = cm,
         gof_map = gm,
         stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
         title = "Main Difference-in-Differences Results",
         notes = c("Standard errors clustered at the Local Authority level in parentheses.",
                   "Cut Intensity = $-z$(CTS WA Expenditure Per Capita, 2017/18).",
                   "Higher values = less generous CTS scheme."),
         escape = FALSE)

## ============================================================
## Table 3: Quartile-Based DiD
## ============================================================
cat("Table 3: Quartile results\n")

models_quartile <- list(
  "JSA Rate\nQ1 vs Q4\n(1)" = results$m5_binary,
  "Log Price\nQ1 vs Q4\n(2)" = results$m6_binary_price,
  "JSA Rate\nDose-Response\n(3)" = results$m7_dose
)

cm_q <- c(
  "high_cut:post" = "Least Generous $\\times$ Post",
  "q2:post" = "Q2 $\\times$ Post",
  "post:q3" = "Q3 $\\times$ Post",
  "post:q4" = "Q4 (Most Generous) $\\times$ Post"
)

msummary(models_quartile,
         output = file.path(TAB_DIR, "tab3_quartile_did.tex"),
         coef_map = cm_q,
         gof_map = gm,
         stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
         title = "Quartile-Based Difference-in-Differences",
         notes = c("Columns 1--2 restrict to Q1 (least generous) vs Q4 (most generous) LAs.",
                   "Column 3 uses all LAs with Q1 as the reference group."),
         escape = FALSE)

## ============================================================
## Table 4: Robustness — Property Prices
## ============================================================
cat("Table 4: Robustness\n")

models_robust <- list(
  "Baseline\n(1)" = results$m2_price,
  "2010--2019\n(2)" = robustness$r1_price,
  "2010--2016\n(3)" = robustness$r2_price,
  "LA Trends\n(4)" = robustness$r3_price,
  "Excl. London\n(5)" = robustness$r5_price
)

msummary(models_robust,
         output = file.path(TAB_DIR, "tab4_robustness_prices.tex"),
         coef_map = cm,
         gof_map = gm,
         stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
         title = "Robustness: Property Price Specifications",
         notes = c("Dependent variable: log mean transaction price.",
                   "Column 4 adds LA-specific linear time trends.",
                   "Column 5 excludes 33 London boroughs."),
         escape = FALSE)

## ============================================================
## Table 5: Horse Race — WA vs Pensioner CTS
## ============================================================
cat("Table 5: Horse race\n")

if (!is.null(robustness$r4_horse)) {
  models_horse <- list(
    "JSA Rate\nWA Only\n(1)" = results$m1_jsa,
    "JSA Rate\nHorse Race\n(2)" = robustness$r4_horse,
    "Log Price\nWA Only\n(3)" = results$m2_price,
    "Log Price\nHorse Race\n(4)" = robustness$r4_horse_price
  )

  cm_h <- c(
    "cut_intensity:post" = "WA Cut Intensity $\\times$ Post",
    "post:pen_intensity" = "Pensioner Intensity $\\times$ Post",
    "pen_intensity:post" = "Pensioner Intensity $\\times$ Post"
  )

  msummary(models_horse,
           output = file.path(TAB_DIR, "tab5_horse_race.tex"),
           coef_map = cm_h,
           gof_map = gm,
           stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
           title = "Working-Age vs.~Pensioner CTS Intensity",
           notes = c("WA Cut Intensity = $-z$(Working-Age CTS Expenditure Per Capita).",
                     "Pensioner Intensity = $-z$(Pensioner CTS Expenditure Per Capita).",
                     "Pensioners were legally protected from CTS scheme changes."),
           escape = FALSE)
}

## ============================================================
## Table 6: Pensioner Placebo
## ============================================================
cat("Table 6: Pensioner placebo\n")

if (!is.null(results$m8_placebo_jsa)) {
  models_placebo <- list(
    "JSA Rate\nWA Treatment\n(1)" = results$m1_jsa,
    "JSA Rate\nPensioner\n(2)" = results$m8_placebo_jsa,
    "Log Price\nWA Treatment\n(3)" = results$m2_price,
    "Log Price\nPensioner\n(4)" = results$m9_placebo_price
  )

  cm_pl <- c(
    "cut_intensity:post" = "WA Cut Intensity $\\times$ Post",
    "pen_intensity:post" = "Pensioner Intensity $\\times$ Post"
  )

  msummary(models_placebo,
           output = file.path(TAB_DIR, "tab6_pensioner_placebo.tex"),
           coef_map = cm_pl,
           gof_map = gm,
           stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
           title = "Pensioner Placebo Test",
           notes = c("Pensioner CTS was protected by statute post-2013.",
                     "If identification is valid, pensioner intensity should not predict outcomes."),
           escape = FALSE)
}

## ============================================================
## Done
## ============================================================
cat("\nAll tables saved to:", TAB_DIR, "\n")
cat("Files:", paste(list.files(TAB_DIR), collapse = ", "), "\n")
