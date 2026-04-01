## ============================================================================
## 05_tables.R — Generate all tables for paper
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
robustness <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))

## ============================================================================
## TABLE 1: SUMMARY STATISTICS
## ============================================================================

cat("=== Table 1: Summary Statistics ===\n")

## Summary by treatment group (2017 values)
pre <- panel[year == 2017]

tab1_data <- pre[, .(
  treatment_label = unique(treatment),
  N = .N,
  fn_rn_mean = round(mean(fn_rn_pct), 2),
  fn_rn_sd = round(sd(fn_rn_pct), 2),
  pop_mean = round(mean(habitants)),
  pop_sd = round(sd(habitants)),
  tx2014_mean = round(mean(tx_2014, na.rm=T), 2),
  tx2014_sd = round(sd(tx_2014, na.rm=T), 2),
  gap_mean = round(mean(housing_gap), 2),
  gap_sd = round(sd(housing_gap), 2),
  target_mean = round(mean(tx_legal), 1)
), by = treatment]

## Write LaTeX table 1
sink(file.path(TABLE_DIR, "tab1_summary.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: SRU-Subject Communes in Deficit (2017)}\n")
cat("\\label{tab:summary}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat(" & Carenc\\'{e}e & Deficit, Not Carenc\\'{e}e \\\\\n")
cat("\\midrule\n")

# Get values
ca <- tab1_data[treatment == "carencee"]
nc <- tab1_data[treatment == "deficit_not_carencee"]

cat(sprintf("FN/RN vote share (\\%%) & %.2f (%.2f) & %.2f (%.2f) \\\\\n",
            ca$fn_rn_mean, ca$fn_rn_sd, nc$fn_rn_mean, nc$fn_rn_sd))
cat(sprintf("Population & %s (%s) & %s (%s) \\\\\n",
            format(ca$pop_mean, big.mark=","), format(ca$pop_sd, big.mark=","),
            format(nc$pop_mean, big.mark=","), format(nc$pop_sd, big.mark=",")))
cat(sprintf("Social housing rate 2014 (\\%%) & %.2f (%.2f) & %.2f (%.2f) \\\\\n",
            ca$tx2014_mean, ca$tx2014_sd, nc$tx2014_mean, nc$tx2014_sd))
cat(sprintf("Housing gap (pp) & %.2f (%.2f) & %.2f (%.2f) \\\\\n",
            ca$gap_mean, ca$gap_sd, nc$gap_mean, nc$gap_sd))
cat(sprintf("Legal target (\\%%) & %.1f & %.1f \\\\\n",
            ca$target_mean, nc$target_mean))
cat(sprintf("$N$ communes & %d & %d \\\\\n", ca$N, nc$N))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Means with standard deviations in parentheses, measured at the 2017 presidential election. Carenc\\'{e}e communes were declared deficient by the prefect during the 2017--2019 SRU triennial review. Housing gap is the difference between the legal social housing target and the 2019 actual rate.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 written.\n")

## ============================================================================
## TABLE 2: MAIN RESULTS
## ============================================================================

cat("=== Table 2: Main Results ===\n")

m1 <- results$m1
m2 <- results$m2
m3 <- results$m3

sink(file.path(TABLE_DIR, "tab2_main.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Effect of Carence Declaration on FN/RN Vote Share}\n")
cat("\\label{tab:main}\n")
cat("\\small\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat(" & TWFE & Dept $\\times$ Year FE & Housing Gap \\\\\n")
cat("\\midrule\n")

# Model 1: treated × post
c1 <- coeftable(m1)
cat(sprintf("Carenc\\'{e}e $\\times$ Post & %.3f & & \\\\\n", c1[1,1]))
cat(sprintf(" & (%.3f) & & \\\\\n", c1[1,2]))

# Model 2: treated × post with dept x year FE
c2 <- coeftable(m2)
cat(sprintf("Carenc\\'{e}e $\\times$ Post & & %.3f & \\\\\n", c2[1,1]))
cat(sprintf(" & & (%.3f) & \\\\\n", c2[1,2]))

# Model 3: housing gap × post
c3 <- coeftable(m3)
cat(sprintf("Housing Gap $\\times$ Post & & & %.4f \\\\\n", c3[1,1]))
cat(sprintf(" & & & (%.4f) \\\\\n", c3[1,2]))

cat("\\midrule\n")
cat(sprintf("Commune FE & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Year FE & Yes & & Yes \\\\\n"))
cat(sprintf("Dept $\\times$ Year FE & & Yes & \\\\\n"))
cat(sprintf("Observations & %s & %s & %s \\\\\n",
            format(m1$nobs, big.mark=","),
            format(m2$nobs, big.mark=","),
            format(m3$nobs, big.mark=",")))
cat(sprintf("Communes & 904 & 898 & 904 \\\\\n"))
cat(sprintf("$R^2$ (within) & %.4f & %.4f & %.4f \\\\\n",
            fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]], fitstat(m3, "wr2")[[1]]))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Dependent variable is the FN/RN first-round presidential vote share (\\%). Post = 1 for the 2022 election. Column (1) includes commune and year fixed effects. Column (2) replaces year FE with department $\\times$ year FE. Column (3) uses the housing gap (legal target minus actual social housing rate, in pp) as a continuous treatment intensity. Standard errors clustered at the commune level in parentheses. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 written.\n")

## ============================================================================
## TABLE 3: EVENT STUDY
## ============================================================================

cat("=== Table 3: Event Study ===\n")

es <- results$es
es_ct <- coeftable(es)

sink(file.path(TABLE_DIR, "tab3_eventstudy.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Event Study: Carencée $\\times$ Election Year Interactions}\n")
cat("\\label{tab:eventstudy}\n")
cat("\\small\n")
cat("\\begin{tabular}{lc}\n")
cat("\\toprule\n")
cat(" & FN/RN Vote Share (\\%) \\\\\n")
cat("\\midrule\n")

years_label <- c("2002", "2007", "2012", "2022")
for (i in 1:nrow(es_ct)) {
  stars <- ""
  if (es_ct[i, 4] < 0.01) stars <- "$^{***}$"
  else if (es_ct[i, 4] < 0.05) stars <- "$^{**}$"
  else if (es_ct[i, 4] < 0.10) stars <- "$^{*}$"
  cat(sprintf("Carenc\\'{e}e $\\times$ %s & %.3f%s \\\\\n", years_label[i], es_ct[i,1], stars))
  cat(sprintf(" & (%.3f) \\\\\n", es_ct[i,2]))
}
cat("Carenc\\'{e}e $\\times$ 2017 & \\multicolumn{1}{c}{---} \\\\\n")
cat(" & \\multicolumn{1}{c}{\\textit{(reference)}} \\\\\n")

cat("\\midrule\n")
cat("Commune FE & Yes \\\\\n")
cat("Year FE & Yes \\\\\n")
cat(sprintf("Observations & %s \\\\\n", format(es$nobs, big.mark=",")))
cat("Communes & 904 \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Coefficients on the interaction of the carenc\\'{e}e indicator with election year dummies, with 2017 as the reference year. The carence declaration occurred during the 2017--2019 triennial review period, after the April 2017 election. Commune and year fixed effects included. Standard errors clustered at the commune level. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 written.\n")

## ============================================================================
## TABLE 4: ROBUSTNESS AND PLACEBO
## ============================================================================

cat("=== Table 4: Robustness ===\n")

sink(file.path(TABLE_DIR, "tab4_robustness.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks and Placebo Outcomes}\n")
cat("\\label{tab:robustness}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & FN/RN & Left & Right & FN/RN \\\\\n")
cat(" & Baseline & Placebo & Placebo & All SRU \\\\\n")
cat("\\midrule\n")

# Col 1: Main result
c_main <- coeftable(results$m1)
stars1 <- ifelse(c_main[1,4] < 0.01, "$^{***}$", ifelse(c_main[1,4] < 0.05, "$^{**}$", ifelse(c_main[1,4] < 0.1, "$^{*}$", "")))
cat(sprintf("Treated $\\times$ Post & %.3f%s & & & \\\\\n", c_main[1,1], stars1))
cat(sprintf(" & (%.3f) & & & \\\\\n", c_main[1,2]))

# Col 2: Left placebo
c_left <- coeftable(robustness$placebo_left)
stars2 <- ifelse(c_left[1,4] < 0.01, "$^{***}$", ifelse(c_left[1,4] < 0.05, "$^{**}$", ""))
cat(sprintf("Carenc\\'{e}e $\\times$ Post & & %.3f%s & & \\\\\n", c_left[1,1], stars2))
cat(sprintf(" & & (%.3f) & & \\\\\n", c_left[1,2]))

# Col 3: Right placebo
c_right <- coeftable(robustness$placebo_right)
stars3 <- ifelse(c_right[1,4] < 0.01, "$^{***}$", ifelse(c_right[1,4] < 0.05, "$^{**}$", ""))
cat(sprintf("Carenc\\'{e}e $\\times$ Post & & & %.3f%s & \\\\\n", c_right[1,1], stars3))
cat(sprintf(" & & & (%.3f) & \\\\\n", c_right[1,2]))

# Col 4: All SRU communes
c_all <- coeftable(robustness$all_sru_control)
stars4 <- ifelse(c_all[1,4] < 0.01, "$^{***}$", ifelse(c_all[1,4] < 0.05, "$^{**}$", ""))
cat(sprintf("Carenc\\'{e}e $\\times$ Post & & & & %.3f%s \\\\\n", c_all[1,1], stars4))
cat(sprintf(" & & & & (%.3f) \\\\\n", c_all[1,2]))

cat("\\midrule\n")
cat("Commune FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(results$m1$nobs, big.mark=","),
            format(robustness$placebo_left$nobs, big.mark=","),
            format(robustness$placebo_right$nobs, big.mark=","),
            format(robustness$all_sru_control$nobs, big.mark=",")))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Column (1) reproduces the baseline TWFE specification. Columns (2) and (3) replace the dependent variable with left-wing and mainstream-right candidate vote shares as placebo outcomes. Column (4) expands the control group to include all SRU-subject communes (both deficit and compliant). Standard errors clustered at the commune level. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 written.\n")

## ============================================================================
## TABLE 5 (APPENDIX): HETEROGENEITY
## ============================================================================

cat("=== Table 5: Heterogeneity ===\n")

sink(file.path(TABLE_DIR, "tab5_heterogeneity.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Heterogeneity by Commune Size and Housing Gap}\n")
cat("\\label{tab:heterogeneity}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & \\multicolumn{2}{c}{Population} & \\multicolumn{2}{c}{Housing Gap} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat(" & Large & Small & Large & Small \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\midrule\n")

specs <- list(robustness$het_large_commune, robustness$het_small_commune,
              robustness$het_large_gap, robustness$het_small_gap)

for (i in 1:4) {
  ct <- coeftable(specs[[i]])
  stars <- ifelse(ct[1,4] < 0.01, "$^{***}$", ifelse(ct[1,4] < 0.05, "$^{**}$", ifelse(ct[1,4] < 0.1, "$^{*}$", "")))
  if (i == 1) {
    cat(sprintf("Carenc\\'{e}e $\\times$ Post & %.3f%s", ct[1,1], stars))
  } else {
    cat(sprintf(" & %.3f%s", ct[1,1], stars))
  }
}
cat(" \\\\\n")

for (i in 1:4) {
  ct <- coeftable(specs[[i]])
  if (i == 1) {
    cat(sprintf(" & (%.3f)", ct[1,2]))
  } else {
    cat(sprintf(" & (%.3f)", ct[1,2]))
  }
}
cat(" \\\\\n")

cat("\\midrule\n")
cat("Commune FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(specs[[1]]$nobs, big.mark=","),
            format(specs[[2]]$nobs, big.mark=","),
            format(specs[[3]]$nobs, big.mark=","),
            format(specs[[4]]$nobs, big.mark=",")))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Sample split by median value of each characteristic. Large (small) population refers to communes above (below) the median population of 6,783. Large (small) housing gap refers to communes with a gap above (below) the median of 10.4 percentage points. Standard errors clustered at the commune level. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 5 written.\n")

## ============================================================================
## TABLE F1: SDE APPENDIX (MANDATORY)
## ============================================================================

cat("=== Table F1: Standardized Effect Sizes ===\n")

## Compute SDE for main outcomes
## SDE = beta / SD(Y_pre)
sd_y_pre <- panel[year < 2022, sd(fn_rn_pct, na.rm = TRUE)]
cat("SD(Y) pre-treatment:", round(sd_y_pre, 4), "\n")

## Main specifications
specs_sde <- list(
  list(name = "FN/RN (TWFE)", beta = coef(results$m1)[1], se = se(results$m1)[1]),
  list(name = "FN/RN (Dept$\\times$Year)", beta = coef(results$m2)[1], se = se(results$m2)[1])
)

## Heterogeneity
panel_het <- panel[year == 2017]
med_pop <- median(panel_het$habitants, na.rm = TRUE)
med_gap <- median(panel_het$housing_gap, na.rm = TRUE)

sd_y_large <- panel[year < 2022 & habitants >= med_pop, sd(fn_rn_pct, na.rm = TRUE)]
sd_y_small <- panel[year < 2022 & habitants < med_pop, sd(fn_rn_pct, na.rm = TRUE)]

het_specs <- list(
  list(name = "Large communes", beta = coef(robustness$het_large_commune)[1],
       se = se(robustness$het_large_commune)[1], sd_y = sd_y_large),
  list(name = "Small communes", beta = coef(robustness$het_small_commune)[1],
       se = se(robustness$het_small_commune)[1], sd_y = sd_y_small)
)

## SDE classification
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

## SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does state enforcement of social housing mandates via carence declarations shift commune-level far-right vote shares? ",
  "\\textbf{Policy mechanism:} The SRU law requires communes above population thresholds to maintain 20--25\\% social housing; prefects declare non-compliant communes ``carenc\\'{e}es,'' triggering multiplied financial penalties, state preemption rights, and direct prefectoral control of building permits. ",
  "\\textbf{Outcome definition:} Front National / Rassemblement National first-round presidential vote share (\\% of expressed votes), at the commune level. ",
  "\\textbf{Treatment:} Binary indicator for commune declared carenc\\'{e}e during the 2017--2019 SRU triennial review period. ",
  "\\textbf{Data:} data.gouv.fr SRU transparency inventory and aggregated election Parquet files, 2002--2022, 904 SRU-subject communes in deficit. ",
  "\\textbf{Method:} Two-way fixed effects DiD (commune + year FE), standard errors clustered at commune level. ",
  "\\textbf{Sample:} SRU-subject communes that were in deficit as of the 2017--2019 review: 270 declared carenc\\'{e}e (treated), 634 in deficit but not declared carenc\\'{e}e (control). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

for (s in specs_sde) {
  sde_val <- s$beta / sd_y_pre
  sde_se <- s$se / sd_y_pre
  class_label <- classify_sde(sde_val)
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
              s$name, s$beta, s$se, sd_y_pre, sde_val, sde_se, class_label))
}

cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by commune population)}} \\\\\n")

for (s in het_specs) {
  sde_val <- s$beta / s$sd_y
  sde_se <- s$se / s$sd_y
  class_label <- classify_sde(sde_val)
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
              s$name, s$beta, s$se, s$sd_y, sde_val, sde_se, class_label))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table F1 written.\n")

cat("\n=== All tables generated ===\n")
