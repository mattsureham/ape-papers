# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# =============================================================================

source("00_packages.R")

dt <- readRDS("../data/analysis_panel.rds")
load("../data/model_objects.RData")
load("../data/robustness_objects.RData")

dir.create("../tables", showWarnings = FALSE)

# ===================================================================
# Table 1: Summary Statistics
# ===================================================================

cat("Generating Table 1: Summary Statistics\n")

# By ethnicity and treatment status
summ_cells <- dt[licensed == 1, .(
  mean_earn = mean(EarnS, na.rm = TRUE),
  sd_earn = sd(EarnS, na.rm = TRUE),
  mean_emp = mean(Emp, na.rm = TRUE),
  sd_emp = sd(Emp, na.rm = TRUE),
  mean_hire_rate = mean(HirA / Emp, na.rm = TRUE),
  n_state_q = .N
), by = .(treated_state, hispanic)]

# Overall statistics
summ_overall <- dt[licensed == 1, .(
  Variable = c("Monthly Earnings (\\$)", "Employment", "Hiring Rate",
               "Log Monthly Earnings"),
  Mean = c(mean(EarnS), mean(Emp), mean(HirA/Emp, na.rm=TRUE), mean(log_earn)),
  SD = c(sd(EarnS), sd(Emp), sd(HirA/Emp, na.rm=TRUE), sd(log_earn)),
  Min = c(min(EarnS), min(Emp), min(HirA/Emp, na.rm=TRUE), min(log_earn)),
  Max = c(max(EarnS), max(Emp), max(HirA/Emp, na.rm=TRUE), max(log_earn))
)]

# Build the table
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Licensed Industries (Construction, Health Care, Other Services)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Reform States} & \\multicolumn{2}{c}{Non-Reform States} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Hispanic & Non-Hispanic & Hispanic & Non-Hispanic \\\\",
  "\\midrule"
)

# Fill in values
for (i in 1:nrow(summ_cells)) {
  sc <- summ_cells[i]
  # We'll build manually
}

# Build rows
get_val <- function(treat, hisp, var) {
  summ_cells[treated_state == treat & hispanic == hisp, get(var)]
}

rows <- c(
  sprintf("Monthly Earnings (\\$) & %s & %s & %s & %s \\\\",
    format(round(get_val(1, 1, "mean_earn")), big.mark=","),
    format(round(get_val(1, 0, "mean_earn")), big.mark=","),
    format(round(get_val(0, 1, "mean_earn")), big.mark=","),
    format(round(get_val(0, 0, "mean_earn")), big.mark=",")),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    format(round(get_val(1, 1, "sd_earn")), big.mark=","),
    format(round(get_val(1, 0, "sd_earn")), big.mark=","),
    format(round(get_val(0, 1, "sd_earn")), big.mark=","),
    format(round(get_val(0, 0, "sd_earn")), big.mark=",")),
  sprintf("Employment & %s & %s & %s & %s \\\\",
    format(round(get_val(1, 1, "mean_emp")), big.mark=","),
    format(round(get_val(1, 0, "mean_emp")), big.mark=","),
    format(round(get_val(0, 1, "mean_emp")), big.mark=","),
    format(round(get_val(0, 0, "mean_emp")), big.mark=",")),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    format(round(get_val(1, 1, "sd_emp")), big.mark=","),
    format(round(get_val(1, 0, "sd_emp")), big.mark=","),
    format(round(get_val(0, 1, "sd_emp")), big.mark=","),
    format(round(get_val(0, 0, "sd_emp")), big.mark=",")),
  sprintf("Hiring Rate & %.3f & %.3f & %.3f & %.3f \\\\",
    get_val(1, 1, "mean_hire_rate"),
    get_val(1, 0, "mean_hire_rate"),
    get_val(0, 1, "mean_hire_rate"),
    get_val(0, 0, "mean_hire_rate")),
  "\\midrule",
  sprintf("State-Quarter Obs. & %s & %s & %s & %s \\\\",
    format(get_val(1, 1, "n_state_q"), big.mark=","),
    format(get_val(1, 0, "n_state_q"), big.mark=","),
    format(get_val(0, 1, "n_state_q"), big.mark=","),
    format(get_val(0, 0, "n_state_q"), big.mark=","))
)

tab1_lines <- c(tab1_lines, rows)

n_treat_states <- uniqueN(dt[treated_state == 1, state_fips])
n_control_states <- uniqueN(dt[treated_state == 0, state_fips])

tab1_lines <- c(tab1_lines,
  sprintf("States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          n_treat_states, n_control_states),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Standard deviations in parentheses. Sample: state $\\times$ quarter $\\times$ ethnicity cells for Construction (NAICS 23), Health Care (NAICS 62), and Other Services (NAICS 81), 2009 Q1--2025 Q1. Reform states are the %d states that enacted universal license recognition laws between 2019--2023. Earnings are average monthly earnings from QWI. Employment and hiring are aggregated from county to state level. N = %s total observations across licensed industries.", n_treat_states, format(nrow(dt[licensed == 1]), big.mark=",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ===================================================================
# Table 2: Main DDD Results
# ===================================================================

cat("Generating Table 2: Main Results\n")

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Extract results from each model
get_ddd <- function(model, var = "treat_post_hisp") {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  list(b = b, s = s, p = p, star = stars(p))
}

r1 <- get_ddd(m1)
r2 <- get_ddd(m2)
# Industry-specific
r_con <- get_ddd(ind_results[["23"]])
r_hc <- get_ddd(ind_results[["62"]])
r_os <- get_ddd(ind_results[["81"]])

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Universal License Recognition on the Hispanic--Non-Hispanic Earnings Gap}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & All Licensed & Industry FE & Construction & Health Care & Other Svc. \\\\",
  "\\midrule",
  sprintf("Reform $\\times$ Post $\\times$ Hispanic & %.4f%s & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
    r1$b, r1$star, r2$b, r2$star, r_con$b, r_con$star, r_hc$b, r_hc$star, r_os$b, r_os$star),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
    r1$s, r2$s, r_con$s, r_hc$s, r_os$s),
  sprintf(" & [%.3f] & [%.3f] & [%.3f] & [%.3f] & [%.3f] \\\\",
    r1$p, r2$p, r_con$p, r_hc$p, r_os$p),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
    format(nobs(m1), big.mark=","),
    format(nobs(m2), big.mark=","),
    format(nobs(ind_results[["23"]]), big.mark=","),
    format(nobs(ind_results[["62"]]), big.mark=","),
    format(nobs(ind_results[["81"]]), big.mark=",")),
  "State $\\times$ Ethnicity FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter $\\times$ Ethnicity FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "State $\\times$ Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Industry $\\times$ Ethnicity FE & No & Yes & -- & -- & -- \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses; $p$-values in brackets. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. The dependent variable is log average monthly earnings from QWI. ``All Licensed'' pools Construction (NAICS 23), Health Care (NAICS 62), and Other Services (NAICS 81). Reform states are the 23 states that enacted universal license recognition between 2019--2023. The triple-difference coefficient captures the differential change in the Hispanic--non-Hispanic log earnings gap in reform states after enactment, relative to the same gap in non-reform states.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ===================================================================
# Table 3: Placebo Industries
# ===================================================================

cat("Generating Table 3: Placebo Industries\n")

r_ret <- get_ddd(ind_results[["44-45"]])
r_food <- get_ddd(ind_results[["72"]])
r_mfg <- get_ddd(ind_results[["31-33"]])

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Placebo Test: Effect in Low-Licensing Industries}",
  "\\label{tab:placebo}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Retail & Accommodation/Food & Manufacturing \\\\",
  "\\midrule",
  sprintf("Reform $\\times$ Post $\\times$ Hispanic & %.4f%s & %.4f%s & %.4f%s \\\\",
    r_ret$b, r_ret$star, r_food$b, r_food$star, r_mfg$b, r_mfg$star),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\",
    r_ret$s, r_food$s, r_mfg$s),
  sprintf(" & [%.3f] & [%.3f] & [%.3f] \\\\",
    r_ret$p, r_food$p, r_mfg$p),
  "\\midrule",
  sprintf("Observations & %s & %s & %s \\\\",
    format(nobs(ind_results[["44-45"]]), big.mark=","),
    format(nobs(ind_results[["72"]]), big.mark=","),
    format(nobs(ind_results[["31-33"]]), big.mark=",")),
  "Full FE Set & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Same specification as Table~\\ref{tab:main}, Column (1), applied to industries with low licensing requirements. If universal license recognition primarily affects licensed occupations, these coefficients should be near zero. Standard errors clustered at the state level in parentheses; $p$-values in brackets.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_placebo.tex")

# ===================================================================
# Table 4: Robustness
# ===================================================================

cat("Generating Table 4: Robustness\n")

r_early <- get_ddd(m_early)
r_late_adopt <- get_ddd(m_late)
r_placebo_pre <- get_ddd(m_placebo, "fake_treat_post_hisp")

# Dynamic effects
b_dyn_early <- coef(m_dynamic)["post_early:hispanic"]
s_dyn_early <- se(m_dynamic)["post_early:hispanic"]
p_dyn_early <- pvalue(m_dynamic)["post_early:hispanic"]
b_dyn_late <- coef(m_dynamic)["hispanic:post_late"]
s_dyn_late <- se(m_dynamic)["hispanic:post_late"]
p_dyn_late <- pvalue(m_dynamic)["hispanic:post_late"]

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Coefficient & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Subsample Analysis}} \\\\",
  sprintf("\\quad Early adopters (2019--2020 cohort) & %.4f%s & (%.4f) \\\\",
    r_early$b, r_early$star, r_early$s),
  sprintf("\\quad Late adopters (2021--2023 cohort) & %.4f%s & (%.4f) \\\\",
    r_late_adopt$b, r_late_adopt$star, r_late_adopt$s),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: Pre-Period Placebo}} \\\\",
  sprintf("\\quad Fake treatment (2 years early) & %.4f%s & (%.4f) \\\\",
    r_placebo_pre$b, r_placebo_pre$star, r_placebo_pre$s),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel C: Dynamic Effects}} \\\\",
  sprintf("\\quad Early post (0--7 quarters) $\\times$ Hispanic & %.4f%s & (%.4f) \\\\",
    b_dyn_early, stars(p_dyn_early), s_dyn_early),
  sprintf("\\quad Late post (8+ quarters) $\\times$ Hispanic & %.4f%s & (%.4f) \\\\",
    b_dyn_late, stars(p_dyn_late), s_dyn_late),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel D: Leave-One-State-Out}} \\\\",
  sprintf("\\quad Range of DDD coefficient & [%.4f, %.4f] & \\\\",
    min(loo_coefs), max(loo_coefs)),
  sprintf("\\quad Full-sample coefficient & %.4f & (%.4f) \\\\",
    coef(m1)["treat_post_hisp"], se(m1)["treat_post_hisp"]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications use the same fixed-effects structure as Table~\\ref{tab:main}, Column (1). Panel A splits the sample by treatment cohort. Panel B shifts the treatment date back by 2 years and estimates the DDD on the pre-treatment window; a significant coefficient indicates pre-existing differential trends. Panel C splits the post-treatment period into early ($\\leq$7 quarters) and late ($>$7 quarters). Panel D reports the range of the DDD coefficient when each treated state is dropped in turn. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")

# ===================================================================
# Table 5 (Appendix): Event Study Coefficients
# ===================================================================

cat("Generating Table 5: Event Study\n")

es_coefs <- readRDS("../data/event_study_coefs.rds")
es_coefs <- es_coefs[order(event_time)]

# Format event study table
tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Hispanic $\\times$ Event Time Coefficients (Licensed Industries)}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Event Time & Estimate & SE & 95\\% CI & $p$-value \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Pre-Treatment}} \\\\"
)

for (i in 1:nrow(es_coefs)) {
  et <- es_coefs$event_time[i]
  b <- es_coefs$estimate[i]
  s <- es_coefs$se[i]
  lo <- es_coefs$ci_lo[i]
  hi <- es_coefs$ci_hi[i]
  p <- 2 * pnorm(-abs(b/s))
  star <- stars(p)

  if (et == 0) {
    tab5_lines <- c(tab5_lines,
      "\\midrule",
      "\\multicolumn{5}{l}{\\textit{Post-Treatment}} \\\\"
    )
  }

  tab5_lines <- c(tab5_lines,
    sprintf("$t = %+d$ & %.4f%s & (%.4f) & [%.4f, %.4f] & %.3f \\\\",
      et, b, star, s, lo, hi, p)
  )
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from a regression of log earnings on interactions of event-time dummies with a Hispanic indicator, estimated on treated states only. Reference period: $t = -1$. Event time measured in quarters relative to the state's enactment date, capped at $\\pm 12$ quarters. Fixed effects: state $\\times$ ethnicity, quarter $\\times$ ethnicity. Standard errors clustered at the state level.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_eventstudy.tex")

# ===================================================================
# Table F1: SDE (Standardized Effect Sizes)
# ===================================================================

cat("Generating SDE Table\n")

# Main outcome: log earnings, licensed industries
beta_main <- coef(m1)["treat_post_hisp"]
se_main <- se(m1)["treat_post_hisp"]
sd_y_main <- sd(dt[licensed == 1, log_earn], na.rm = TRUE)

sde_main <- beta_main / sd_y_main
se_sde_main <- se_main / sd_y_main

# Construction
beta_con <- coef(ind_results[["23"]])["treat_post_hisp"]
se_con <- se(ind_results[["23"]])["treat_post_hisp"]
sd_y_con <- sd(dt[industry == "23", log_earn], na.rm = TRUE)
sde_con <- beta_con / sd_y_con
se_sde_con <- se_con / sd_y_con

# Health care
beta_hc <- coef(ind_results[["62"]])["treat_post_hisp"]
se_hc <- se(ind_results[["62"]])["treat_post_hisp"]
sd_y_hc <- sd(dt[industry == "62", log_earn], na.rm = TRUE)
sde_hc <- beta_hc / sd_y_hc
se_sde_hc <- se_hc / sd_y_hc

# Employment outcome
beta_emp <- coef(m_emp)["treat_post_hisp"]
se_emp_val <- se(m_emp)["treat_post_hisp"]
sd_y_emp <- sd(dt[licensed == 1 & !is.na(log_emp), log_emp], na.rm = TRUE)
sde_emp <- beta_emp / sd_y_emp
se_sde_emp <- se_emp_val / sd_y_emp

# Heterogeneity: Early adopters
beta_early <- coef(m_early)["treat_post_hisp"]
se_early <- se(m_early)["treat_post_hisp"]
sde_early <- beta_early / sd_y_main
se_sde_early <- se_early / sd_y_main

# Heterogeneity: Late adopters
beta_late_val <- coef(m_late)["treat_post_hisp"]
se_late_val <- se(m_late)["treat_post_hisp"]
sde_late_val <- beta_late_val / sd_y_main
se_sde_late_val <- se_late_val / sd_y_main

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state-level enactment of universal occupational license recognition differentially affect Hispanic workers' earnings relative to non-Hispanic workers in licensed industries? ",
  "\\textbf{Policy mechanism:} Universal license recognition laws allow workers holding a valid occupational license from any US state to practice in the enacting state without re-examination or additional training, reducing cross-state mobility barriers for licensed workers. ",
  "\\textbf{Outcome definition:} Log average monthly earnings (EarnS) from the Quarterly Workforce Indicators, measuring average earnings of workers employed in a given state--quarter--industry--ethnicity cell. ",
  "\\textbf{Treatment:} Binary; state enactment of universal license recognition (23 states, 2019--2023 cohorts). ",
  "\\textbf{Data:} Census LEHD Quarterly Workforce Indicators (QWI), race/ethnicity panel, 2009 Q1--2025 Q1, state--quarter--industry--ethnicity level, 21,438 observations (licensed industries). ",
  "\\textbf{Method:} Triple-difference (reform state $\\times$ post-enactment $\\times$ Hispanic), with state$\\times$ethnicity, quarter$\\times$ethnicity, and state$\\times$quarter fixed effects, state-clustered standard errors. ",
  "\\textbf{Sample:} Licensed industries (Construction NAICS 23, Health Care NAICS 62, Other Services NAICS 81); 23 reform states and 29 non-reform states; all quarters with non-missing earnings data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of log monthly earnings. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log Earnings & Licensed Industries & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta_main, se_main, sd_y_main, sde_main, se_sde_main, classify(sde_main)),
  sprintf("Log Earnings & Construction & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta_con, se_con, sd_y_con, sde_con, se_sde_con, classify(sde_con)),
  sprintf("Log Earnings & Health Care & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta_hc, se_hc, sd_y_hc, sde_hc, se_sde_hc, classify(sde_hc)),
  sprintf("Log Employment & Licensed Industries & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta_emp, se_emp_val, sd_y_emp, sde_emp, se_sde_emp, classify(sde_emp)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Log Earnings & Early adopters (2019--2020) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta_early, se_early, sd_y_main, sde_early, se_sde_early, classify(sde_early)),
  sprintf("Log Earnings & Late adopters (2021--2023) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta_late_val, se_late_val, sd_y_main, sde_late_val, se_sde_late_val, classify(sde_late_val)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
