## 05_tables.R — Generate all LaTeX tables
## apep_1315: The Forever Chemical Discount

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))
zip_treat <- readRDS(file.path(data_dir, "zip_treatment.rds"))
system_treat <- readRDS(file.path(data_dir, "system_treatment.rds"))
diag <- fromJSON(file.path(data_dir, "diagnostics.json"))

## ---- Rebuild balanced panel for summary stats ----
panel <- panel[is.finite(hpi) & hpi > 0]
panel[, log_hpi := log(hpi)]
panel <- panel[order(zip5, year)]
zip_counts <- panel[, .N, by = zip5]
balanced_zips <- zip_counts[N == 11, zip5]
panel_bal <- panel[zip5 %in% balanced_zips]
panel_bal[, max_pfas_ppt := pmax(max_pfoa_ppt, max_pfos_ppt)]

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================
cat("Generating Table 1: Summary Statistics...\n")

pre_data <- panel_bal[year < 2024]

make_summ <- function(dt, label) {
  data.frame(
    Group = label,
    N_ZIPs = uniqueN(dt$zip5),
    Mean_HPI = round(mean(dt$hpi, na.rm = TRUE), 1),
    SD_HPI = round(sd(dt$hpi, na.rm = TRUE), 1),
    Mean_logHPI = round(mean(dt$log_hpi, na.rm = TRUE), 3),
    SD_logHPI = round(sd(dt$log_hpi, na.rm = TRUE), 3),
    Mean_PFAS_ppt = round(mean(dt$max_pfas_ppt, na.rm = TRUE), 1),
    Median_PFAS_ppt = round(median(dt$max_pfas_ppt, na.rm = TRUE), 1)
  )
}

tab1 <- rbind(
  make_summ(pre_data, "Full Sample"),
  make_summ(pre_data[treat == 1], "Above MCL"),
  make_summ(pre_data[treat == 0], "Below MCL"),
  make_summ(pre_data[treat == 1 & prior_state_mcl == TRUE], "Above MCL, Prior State MCL"),
  make_summ(pre_data[treat == 1 & prior_state_mcl == FALSE], "Above MCL, No Prior MCL")
)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Period (2014--2023)}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccccc}\n",
  "\\hline\\hline\n",
  " & ZIP & \\multicolumn{2}{c}{HPI (level)} & \\multicolumn{2}{c}{log(HPI)} & \\multicolumn{2}{c}{Max PFAS (ppt)} \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6} \\cmidrule(lr){7-8}\n",
  " & Codes & Mean & SD & Mean & SD & Mean & Median \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(tab1)) {
  tab1_tex <- paste0(tab1_tex,
    tab1$Group[i], " & ",
    format(tab1$N_ZIPs[i], big.mark = ","), " & ",
    format(tab1$Mean_HPI[i], nsmall = 1), " & ",
    format(tab1$SD_HPI[i], nsmall = 1), " & ",
    format(tab1$Mean_logHPI[i], nsmall = 3), " & ",
    format(tab1$SD_logHPI[i], nsmall = 3), " & ",
    format(tab1$Mean_PFAS_ppt[i], nsmall = 1), " & ",
    format(tab1$Median_PFAS_ppt[i], nsmall = 1), " \\\\\n"
  )
  if (i == 1 || i == 3) tab1_tex <- paste0(tab1_tex, "\\hline\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Sample restricted to ZIP codes in the balanced panel (all 11 years observed). ",
  "HPI is the FHFA Annual All-Transactions House Price Index (base year 1995). ",
  "PFAS concentrations are maximum detected PFOA or PFOS from UCMR~5 monitoring. ",
  "MCL threshold is 4 parts per trillion (ppt). ",
  "Prior State MCL states: NJ, MA, MI, NH, PA, VT, WI.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

## ============================================================
## TABLE 2: Main Results (DiD and DDD)
## ============================================================
cat("Generating Table 2: Main Results...\n")

did_main <- results$did_main
ddd <- results$ddd
dose <- results$dose_response
did_styr <- rob_results$did_state_year

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Federal PFAS MCL on House Prices}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & DiD & DDD & Dose--Response & State$\\times$Year FE \\\\\n",
  "\\hline\n",
  "Above MCL $\\times$ Post & ",
    sprintf("%.4f", coef(did_main)["treat_post"]), " & ",
    sprintf("%.4f", coef(ddd)["treat_post"]), " & & ",
    sprintf("%.4f", coef(did_styr)["treat_post"]), " \\\\\n",
  " & (", sprintf("%.4f", se(did_main)["treat_post"]), ") & (",
    sprintf("%.4f", se(ddd)["treat_post"]), ") & & (",
    sprintf("%.4f", se(did_styr)["treat_post"]), ") \\\\\n",
  " & [", sprintf("%.3f", pvalue(did_main)["treat_post"]), "] & [",
    sprintf("%.3f", pvalue(ddd)["treat_post"]), "] & & [",
    sprintf("%.3f", pvalue(did_styr)["treat_post"]), "] \\\\\n",
  "[0.5em]\n",
  "Above MCL $\\times$ Post $\\times$ No Prior MCL & & ",
    sprintf("%.4f", coef(ddd)["treat_post_noprior"]), " & & \\\\\n",
  " & & (", sprintf("%.4f", se(ddd)["treat_post_noprior"]), ") & & \\\\\n",
  " & & [", sprintf("%.3f", pvalue(ddd)["treat_post_noprior"]), "] & & \\\\\n",
  "[0.5em]\n",
  "log(PFAS ppt) $\\times$ Post & & & ",
    sprintf("%.4f", coef(dose)["log_pfas:post"]), " & \\\\\n",
  " & & & (", sprintf("%.4f", se(dose)["log_pfas:post"]), ") & \\\\\n",
  " & & & [", sprintf("%.3f", pvalue(dose)["log_pfas:post"]), "] & \\\\\n",
  "\\hline\n",
  "ZIP FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & \\\\\n",
  "State $\\times$ Year FE & & & & Yes \\\\\n",
  "Observations & ", format(nobs(did_main), big.mark = ","), " & ",
    format(nobs(ddd), big.mark = ","), " & ",
    format(nobs(dose), big.mark = ","), " & ",
    format(nobs(did_styr), big.mark = ","), " \\\\\n",
  "ZIP Codes & ", format(diag$n_treated + diag$n_control, big.mark = ","), " & ",
    format(diag$n_treated + diag$n_control, big.mark = ","), " & ",
    format(diag$n_treated + diag$n_control, big.mark = ","), " & ",
    format(diag$n_treated + diag$n_control, big.mark = ","), " \\\\\n",
  "Treated ZIPs & ", format(diag$n_treated, big.mark = ","), " & ",
    format(diag$n_treated, big.mark = ","), " & ",
    format(diag$n_treated, big.mark = ","), " & ",
    format(diag$n_treated, big.mark = ","), " \\\\\n",
  "Clusters (States) & ", diag$n_clusters_state, " & ",
    diag$n_clusters_state, " & ",
    diag$n_clusters_state, " & ",
    diag$n_clusters_state, " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log(HPI). ",
  "Standard errors clustered at state level in parentheses; $p$-values in brackets. ",
  "``Above MCL'' indicates ZIP codes served by water systems with maximum detected PFOA or PFOS exceeding 4~ppt. ",
  "``Post'' is an indicator for 2024, the year the EPA finalized the PFAS MCL. ",
  "``No Prior MCL'' indicates states without pre-existing enforceable state PFAS standards (i.e., not NJ, MA, MI, NH, PA, VT, or WI). ",
  "Column~(2) adds a triple-difference isolating the effect in states receiving new regulatory information. ",
  "Column~(3) replaces the binary treatment with log(maximum PFAS concentration + 1). ",
  "Column~(4) adds state-by-year fixed effects, absorbing all state-level time-varying confounders. ",
  "Sample: balanced panel of 5,130 ZIP codes observed annually 2014--2024.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))

## ============================================================
## TABLE 3: Event Study Coefficients
## ============================================================
cat("Generating Table 3: Event Study...\n")

es <- results$event_study
es_coefs <- data.frame(
  event_time = as.integer(gsub("event_time::(-?[0-9]+):treat", "\\1", names(coef(es)))),
  coef = as.numeric(coef(es)),
  se = as.numeric(se(es)),
  pval = as.numeric(pvalue(es))
)
es_coefs <- es_coefs[order(es_coefs$event_time), ]

# Add reference period
es_coefs <- rbind(es_coefs[es_coefs$event_time < -1, ],
                  data.frame(event_time = -1, coef = 0, se = NA, pval = NA),
                  es_coefs[es_coefs$event_time >= 0, ])

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Log(HPI) Relative to $t=-1$}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Event Time & Coefficient & Std.~Error & $p$-value \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(es_coefs)) {
  yr_label <- ifelse(es_coefs$event_time[i] == 0, "0 (2024)",
              paste0(es_coefs$event_time[i], " (", 2024 + es_coefs$event_time[i], ")"))
  if (es_coefs$event_time[i] == -1) {
    tab3_tex <- paste0(tab3_tex, yr_label, " & [Reference] & & \\\\\n")
  } else {
    tab3_tex <- paste0(tab3_tex, yr_label, " & ",
      sprintf("%.4f", es_coefs$coef[i]), " & (",
      sprintf("%.4f", es_coefs$se[i]), ") & ",
      sprintf("%.3f", es_coefs$pval[i]), " \\\\\n")
  }
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\n",
  "ZIP FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "Observations & \\multicolumn{3}{c}{", format(nobs(results$event_study), big.mark = ","), "} \\\\\n",
  "Clusters & \\multicolumn{3}{c}{", diag$n_clusters_state, " states} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each coefficient represents the differential log(HPI) for above-MCL ZIP codes relative to below-MCL ZIP codes at event time $\\tau$, with $\\tau = -1$ (2023) as the reference period. ",
  "Standard errors clustered at state level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_eventstudy.tex"))

## ============================================================
## TABLE 4: Robustness Checks
## ============================================================
cat("Generating Table 4: Robustness...\n")

placebo <- rob_results$placebo_2020

# Collect specifications
specs <- list(
  list(name = "Baseline (state clusters)", coef = coef(did_main)["treat_post"],
       se = se(did_main)["treat_post"], pval = pvalue(did_main)["treat_post"],
       n = nobs(did_main)),
  list(name = "ZIP-level clusters", coef = coef(results$did_zip_clust)["treat_post"],
       se = se(results$did_zip_clust)["treat_post"],
       pval = pvalue(results$did_zip_clust)["treat_post"],
       n = nobs(results$did_zip_clust)),
  list(name = "State $\\times$ year FE", coef = coef(did_styr)["treat_post"],
       se = se(did_styr)["treat_post"], pval = pvalue(did_styr)["treat_post"],
       n = nobs(did_styr)),
  list(name = "Excluding top-decile PFAS", coef = coef(rob_results$did_no_extreme)["treat_post"],
       se = se(rob_results$did_no_extreme)["treat_post"],
       pval = pvalue(rob_results$did_no_extreme)["treat_post"],
       n = nobs(rob_results$did_no_extreme)),
  list(name = "Placebo (2020 treatment)", coef = coef(placebo)["fake_treat_post"],
       se = se(placebo)["fake_treat_post"], pval = pvalue(placebo)["fake_treat_post"],
       n = nobs(placebo))
)

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Specification & Coefficient & Std.~Error & $p$-value & $N$ \\\\\n",
  "\\hline\n"
)

for (s in specs) {
  tab4_tex <- paste0(tab4_tex,
    s$name, " & ",
    sprintf("%.4f", s$coef), " & (",
    sprintf("%.4f", s$se), ") & ",
    sprintf("%.3f", s$pval), " & ",
    format(s$n, big.mark = ","), " \\\\\n")
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} All specifications include ZIP code and year fixed effects ",
  "(except state$\\times$year FE, which replaces year FE). ",
  "Dependent variable is log(HPI). ",
  "Baseline uses state-level clustering; row~2 reports ZIP-level clustering of the same model. ",
  "``Excluding top-decile PFAS'' removes ZIPs with the highest 10\\% of contamination (potential prior awareness). ",
  "``Placebo'' tests for a treatment effect at 2020 using only 2014--2022 data.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))

## ============================================================
## TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY
## ============================================================
cat("Generating SDE Table (tabF1_sde.tex)...\n")

sd_y <- diag$sd_y_pre

# Panel A: Pooled main results
sde_rows_a <- list(
  list(outcome = "House Price Index (DiD)", beta = coef(did_main)["treat_post"],
       se_beta = se(did_main)["treat_post"]),
  list(outcome = "House Price Index (DDD, prior MCL states)", beta = coef(ddd)["treat_post"],
       se_beta = se(ddd)["treat_post"]),
  list(outcome = "House Price Index (DDD, no-prior-MCL differential)", beta = coef(ddd)["treat_post_noprior"],
       se_beta = se(ddd)["treat_post_noprior"])
)

# Panel B: Heterogeneous — split by prior state MCL status
# Re-run DiD separately for prior-MCL and no-prior-MCL subsamples
panel_bal <- panel[zip5 %in% balanced_zips]
panel_bal[, `:=`(
  treat_post = treat * as.integer(year >= 2024),
  max_pfas_ppt = pmax(max_pfoa_ppt, max_pfos_ppt)
)]

did_prior <- feols(log_hpi ~ treat_post | zip5 + year,
  data = panel_bal[prior_state_mcl == TRUE], cluster = ~state)
did_noprior <- feols(log_hpi ~ treat_post | zip5 + year,
  data = panel_bal[prior_state_mcl == FALSE], cluster = ~state)

sd_y_prior <- sd(panel_bal$log_hpi[panel_bal$prior_state_mcl == TRUE & panel_bal$year < 2024], na.rm = TRUE)
sd_y_noprior <- sd(panel_bal$log_hpi[panel_bal$prior_state_mcl == FALSE & panel_bal$year < 2024], na.rm = TRUE)

sde_rows_b <- list(
  list(outcome = "HPI: Prior State MCL", beta = coef(did_prior)["treat_post"],
       se_beta = se(did_prior)["treat_post"], sd_y_local = sd_y_prior),
  list(outcome = "HPI: No Prior State MCL", beta = coef(did_noprior)["treat_post"],
       se_beta = se(did_noprior)["treat_post"], sd_y_local = sd_y_noprior)
)

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether the first-ever federal Maximum Contaminant Level (MCL) for PFAS in drinking water capitalized into local housing prices, and whether the effect differed between states with and without pre-existing PFAS regulations. ",
  "\\textbf{Policy mechanism:} The April 2024 EPA rule established enforceable MCLs of 4 parts per trillion for PFOA and PFOS in public drinking water, requiring approximately 1,700 water systems to undertake remediation by 2029; the UCMR~5 monitoring program simultaneously disclosed system-level contamination data to the public. ",
  "\\textbf{Outcome definition:} Log of the FHFA Annual All-Transactions House Price Index at the five-digit ZIP code level, measuring cumulative nominal house price appreciation. ",
  "\\textbf{Treatment:} Binary indicator for ZIP codes served by public water systems with maximum detected PFOA or PFOS concentrations exceeding 4 ppt. ",
  "\\textbf{Data:} EPA UCMR~5 occurrence data (1.93 million analytical records from 10,299 water systems, 2023--2025), UCMR~5 ZIP code crosswalk (31,107 system-to-ZIP mappings), and FHFA ZIP5 HPI (annual, 2014--2024); balanced panel of 5,130 ZIP codes and 56,430 ZIP-year observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD (ZIP and year FE) with common treatment timing (April 2024); triple-difference exploiting prior state PFAS MCLs as a within-treatment placebo; standard errors clustered at state level. ",
  "\\textbf{Sample:} ZIP codes with both UCMR~5 monitoring data and FHFA HPI coverage for all years 2014--2024, covering 1,681 treated and 3,449 control ZIP codes across 56 states and territories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation of log(HPI). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (r in sde_rows_a) {
  sde_val <- as.numeric(r$beta) / sd_y
  se_sde <- as.numeric(r$se_beta) / sd_y
  tabF1_tex <- paste0(tabF1_tex,
    r$outcome, " & ",
    sprintf("%.4f", r$beta), " & ",
    sprintf("%.4f", r$se_beta), " & ",
    sprintf("%.3f", sd_y), " & ",
    sprintf("%.4f", sde_val), " & ",
    sprintf("%.4f", se_sde), " & ",
    classify_sde(sde_val), " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n"
)

for (r in sde_rows_b) {
  local_sd <- if (!is.null(r$sd_y_local)) r$sd_y_local else sd_y
  sde_val <- as.numeric(r$beta) / local_sd
  se_sde <- as.numeric(r$se_beta) / local_sd
  tabF1_tex <- paste0(tabF1_tex,
    r$outcome, " & ",
    sprintf("%.4f", r$beta), " & ",
    sprintf("%.4f", r$se_beta), " & ",
    sprintf("%.3f", local_sd), " & ",
    sprintf("%.4f", sde_val), " & ",
    sprintf("%.4f", se_sde), " & ",
    classify_sde(sde_val), " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("All tables generated successfully.\n")
cat("Files:", paste(list.files(table_dir), collapse = ", "), "\n")
