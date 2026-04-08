##############################################################################
# 05_tables.R — Generate all LaTeX tables
# apep_1434: When Scandals Go Dark
##############################################################################

source("00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
load("data/main_results.RData")
load("data/robustness_results.RData")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

###########################################################################
# Table 1: Summary Statistics
###########################################################################
cat("=== Table 1: Summary Statistics ===\n")

mean_h <- sprintf("%.2f", mean(panel$n_hearings))
sd_h <- sprintf("%.2f", sd(panel$n_hearings))
mean_any <- sprintf("%.3f", mean(panel$any_hearing))
mean_si <- sprintf("%.1f", mean(panel$scandal_interest, na.rm = TRUE))
sd_si <- sprintf("%.1f", sd(panel$scandal_interest, na.rm = TRUE))
mean_ci <- sprintf("%.1f", mean(panel$competing_interest, na.rm = TRUE))
sd_ci <- sprintf("%.1f", sd(panel$competing_interest, na.rm = TRUE))
pct_mega <- sprintf("%.3f", mean(panel$has_mega_event))
n_ag <- as.character(n_distinct(panel$agency_code))
n_mo <- as.character(n_distinct(panel$ym))
n_obs <- format(nrow(panel), big.mark = ",")

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Agency--Month Panel, 2009--2024}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Variable & Mean & SD \\\\",
  "\\hline",
  sprintf("Hearings per agency-month & %s & %s \\\\", mean_h, sd_h),
  sprintf("Any hearing (indicator) & %s & --- \\\\", mean_any),
  sprintf("Scandal interest (Google Trends) & %s & %s \\\\", mean_si, sd_si),
  sprintf("Competing event interest & %s & %s \\\\", mean_ci, sd_ci),
  sprintf("Mega-event month (indicator) & %s & --- \\\\", pct_mega),
  "\\hline",
  sprintf("Agencies & \\multicolumn{2}{c}{%s} \\\\", n_ag),
  sprintf("Months & \\multicolumn{2}{c}{%s} \\\\", n_mo),
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", n_obs),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Unit of observation is agency $\\times$ month for 19 major",
  "federal agencies over 192 months (January 2009--December 2024). Hearings are",
  "congressional hearings matched to agencies by title keywords from the GovInfo API.",
  "Scandal interest is the Google Trends index (0--100) for the agency name paired",
  "with ``scandal'' in U.S. searches. Competing event interest is the sum of Google",
  "Trends indices for ``Olympics'' and ``impeachment.'' Mega-event month equals one",
  "when any pre-determined mega-event (Summer/Winter Olympics, presidential impeachment,",
  "World Cup, royal event) overlaps the calendar month.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_sumstats.tex"))

###########################################################################
# Table 2: Reduced Form — Mega-events → Hearings
###########################################################################
cat("=== Table 2: Reduced Form ===\n")

tab2 <- etable(rf1, rf2, rf4, rf5,
               headers = c("(1)", "(2)", "(3)", "(4)"),
               se.below = TRUE,
               fitstat = c("n", "r2"),
               style.tex = style.tex("aer"),
               tex = TRUE)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Scandal Timing Lottery: Mega-Events Reduce Congressional Oversight}",
  "\\label{tab:reduced_form}",
  tab2,
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable: hearings count (cols.\\ 1--2),",
  "any-hearing indicator (col.\\ 3), IHS(hearings) (col.\\ 4).",
  "Mega-event is a binary indicator for months overlapping pre-determined events",
  "(Olympics, impeachments, World Cup, royal events). All dates were fixed years",
  "before any specific agency scandal. All specifications include agency FE;",
  "col.\\ 1 adds month-of-year FE; cols.\\ 2--4 add year FE.",
  "Standard errors clustered by agency. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_reduced_form.tex"))

###########################################################################
# Table 3: IV Results
###########################################################################
cat("=== Table 3: IV ===\n")

tab3 <- etable(ols1, iv1, iv2, iv3,
               headers = c("OLS", "IV (binary)", "IV (cont.)", "IV + lag"),
               se.below = TRUE,
               fitstat = c("n", "r2", "ivf"),
               style.tex = style.tex("aer"),
               tex = TRUE)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Media Salience and Congressional Oversight: OLS and IV Estimates}",
  "\\label{tab:iv_results}",
  "\\small",
  tab3,
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is count of congressional hearings.",
  "Column 1 presents OLS. Columns 2--4 present 2SLS estimates instrumenting",
  "scandal interest (IHS of Google Trends index) with competing event coverage.",
  "Col.\\ 2 uses a binary mega-event indicator; col.\\ 3 uses IHS of competing",
  "event interest; col.\\ 4 adds lagged hearings. All include agency, year, and",
  "month-of-year FE. SEs clustered by agency.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_iv.tex"))

###########################################################################
# Table 4: Heterogeneity
###########################################################################
cat("=== Table 4: Heterogeneity ===\n")

tab4 <- etable(rf_divided, rf_unified, rf_high, rf_low,
               headers = c("Divided", "Unified", "High-profile", "Low-profile"),
               se.below = TRUE,
               fitstat = c("n", "r2"),
               style.tex = style.tex("aer"),
               tex = TRUE)

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity: Government Structure and Agency Profile}",
  "\\label{tab:heterogeneity}",
  tab4,
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All columns present reduced-form estimates of the",
  "effect of mega-events on congressional hearings. Cols.\\ 1--2 split by",
  "divided government (president and at least one chamber from different parties).",
  "Cols.\\ 3--4 split by agency profile: high-profile (VA, EPA, FDA, FAA, IRS,",
  "DHS, CDC, DOJ, DOD) vs.\\ low-profile. All include agency, year, and",
  "month-of-year FE. SEs clustered by agency.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_heterogeneity.tex"))

###########################################################################
# Table 5: Robustness
###########################################################################
cat("=== Table 5: Robustness ===\n")

tab5 <- etable(rf2, rf_cluster_ay, rf_early, rf_late, rf_nocovid, rf_olympics,
               headers = c("Baseline", "2-way SE", "2009--16", "2017--24",
                           "No COVID", "Olympics"),
               se.below = TRUE,
               fitstat = c("n", "r2"),
               style.tex = style.tex("aer"),
               tex = TRUE)

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications}",
  "\\label{tab:robustness}",
  "\\small",
  tab5,
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All columns estimate the reduced-form effect of",
  "mega-events on hearings. Col.\\ 1: baseline. Col.\\ 2: two-way clustering",
  "(agency $\\times$ year). Cols.\\ 3--4: subperiod stability. Col.\\ 5: excludes",
  "2020--2021 (COVID). Col.\\ 6: Olympics only (set 7+ years in advance).",
  "Permutation test (1,000 draws, shuffling mega-event within agency):",
  sprintf("$p = %.3f$.", perm_pvalue),
  "All include agency, year, and month-of-year FE.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_robustness.tex"))

###########################################################################
# Table F1: Standardized Effect Sizes
###########################################################################
cat("=== Table F1: SDE ===\n")

sd_y_pre <- sd(panel$n_hearings[panel$year < 2014])

# Reduced form coefficient
beta_rf <- coeftable(rf2)["mega", "Estimate"]
se_rf <- coeftable(rf2)["mega", "Std. Error"]

# Extensive margin
beta_ext <- coeftable(rf4)["mega", "Estimate"]
se_ext <- coeftable(rf4)["mega", "Std. Error"]
sd_ext_pre <- sd(panel$any_hearing[panel$year < 2014])

# IHS outcome
beta_ihs <- coeftable(rf5)["mega", "Estimate"]
se_ihs <- coeftable(rf5)["mega", "Std. Error"]
sd_ihs_pre <- sd(panel$ihs_hearings[panel$year < 2014])

compute_sde <- function(beta, se, sd_y) {
  sde <- beta / sd_y
  se_sde <- abs(se / sd_y)
  class_label <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  list(sde = sde, se_sde = se_sde, class = class_label)
}

sde_main <- compute_sde(beta_rf, se_rf, sd_y_pre)
sde_ext <- compute_sde(beta_ext, se_ext, sd_ext_pre)
sde_ihs <- compute_sde(beta_ihs, se_ihs, sd_ihs_pre)

# Heterogeneity SDEs
beta_div <- coeftable(rf_divided)["mega", "Estimate"]
se_div <- coeftable(rf_divided)["mega", "Std. Error"]
sd_div_pre <- sd(panel$n_hearings[panel$divided_gov == 1 & panel$year < 2014])
sde_div <- compute_sde(beta_div, se_div, sd_div_pre)

beta_uni <- coeftable(rf_unified)["mega", "Estimate"]
se_uni <- coeftable(rf_unified)["mega", "Std. Error"]
sd_uni_pre <- sd(panel$n_hearings[panel$divided_gov == 0 & panel$year < 2014])
sde_uni <- compute_sde(beta_uni, se_uni, sd_uni_pre)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do pre-determined mega-events (Olympics, ",
  "impeachments, World Cup) reduce congressional oversight hearings of ",
  "federal agencies by displacing media coverage of agency scandals? ",
  "\\textbf{Policy mechanism:} Congressional oversight relies on media ",
  "coverage to generate public pressure; pre-determined competing events ",
  "mechanically crowd out scandal coverage, reducing the political return ",
  "to holding oversight hearings and creating a scandal timing lottery ",
  "where agencies whose failures coincide with mega-events escape scrutiny. ",
  "\\textbf{Outcome definition:} Count of congressional hearings per agency ",
  "per month, matched by title keywords from GovInfo API. ",
  "\\textbf{Treatment:} Binary; equals one when a pre-determined mega-event ",
  "(Olympic Games, presidential impeachment, FIFA World Cup, major royal ",
  "event) overlaps the calendar month. ",
  "\\textbf{Data:} GovInfo API hearing records matched to 19 federal ",
  "agencies (2009--2024); Google Trends scandal interest as mechanism ",
  "evidence; unit is agency $\\times$ month; $N = ",
  format(nrow(panel), big.mark = ","), "$. ",
  "\\textbf{Method:} Reduced-form regression of hearings on the mega-event ",
  "indicator with agency and year-by-month fixed effects; standard errors ",
  "clustered by agency; 1,000-draw permutation test confirms. ",
  "\\textbf{Sample:} 19 major federal agencies (Cabinet departments plus ",
  "FDA, FAA, FEMA, IRS, CDC, NASA) across 192 months. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation (pre-2014). Classification refers to magnitude, not ",
  "statistical significance: Large ($|$SDE$| > 0.15$), Moderate ",
  "($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Hearings (count) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_rf, se_rf, sd_y_pre, sde_main$sde, sde_main$se_sde, sde_main$class),
  sprintf("Any hearing & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_ext, se_ext, sd_ext_pre, sde_ext$sde, sde_ext$se_sde, sde_ext$class),
  sprintf("Hearings (IHS) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_ihs, se_ihs, sd_ihs_pre, sde_ihs$sde, sde_ihs$se_sde, sde_ihs$class),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\[3pt]",
  sprintf("Divided government & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_div, se_div, sd_div_pre, sde_div$sde, sde_div$se_sde, sde_div$class),
  sprintf("Unified government & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_uni, se_uni, sd_uni_pre, sde_uni$sde, sde_uni$se_sde, sde_uni$class),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
