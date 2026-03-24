## 05_tables.R — Generate all tables for paper
## APEP-0861: Austerity Triage and Domestic Abuse Justice

source("00_packages.R")
setwd("..")

panel <- readRDS("data/analysis_panel.rds")
models <- readRDS("data/main_models.rds")
robustness <- readRDS("data/robustness_models.rds")

# Prepare variables
panel <- panel %>%
  mutate(
    austerity_intensity = -officer_change_pct,
    post_uplift = as.integer(year >= 2020),
    log_officers = log(officer_fte),
    charge_rate = charge_rate_pct * 100,
    no_suspect = no_suspect_pct * 100,
    victim_nosupport = victim_nosupport_pct * 100,
    success_rate = success_rate_pct * 100
  )

median_cut <- panel %>% filter(year == 2018) %>% pull(officer_change_pct) %>% median(na.rm = TRUE)
austerity_class <- panel %>%
  filter(year == 2018) %>%
  mutate(high_austerity = as.integer(officer_change_pct < median_cut)) %>%
  select(force_std, high_austerity)
panel <- panel %>% left_join(austerity_class, by = "force_std")

# ===============================================================
# TABLE 1: Summary Statistics
# ===============================================================
cat("=== TABLE 1: Summary Statistics ===\n")

summ_vars <- panel %>%
  filter(!is.na(charge_rate)) %>%
  summarise(
    `Victim-based charge rate (\\%)` = sprintf("%.2f & %.2f & %.2f & %.2f & %d",
      mean(charge_rate), sd(charge_rate), min(charge_rate), max(charge_rate), n()),
    `Victim withdrawal rate (\\%)` = sprintf("%.2f & %.2f & %.2f & %.2f & %d",
      mean(victim_nosupport, na.rm = TRUE), sd(victim_nosupport, na.rm = TRUE),
      min(victim_nosupport, na.rm = TRUE), max(victim_nosupport, na.rm = TRUE),
      sum(!is.na(victim_nosupport))),
    `No suspect identified (\\%)` = sprintf("%.2f & %.2f & %.2f & %.2f & %d",
      mean(no_suspect, na.rm = TRUE), sd(no_suspect, na.rm = TRUE),
      min(no_suspect, na.rm = TRUE), max(no_suspect, na.rm = TRUE),
      sum(!is.na(no_suspect))),
    `Successful outcome rate (\\%)` = sprintf("%.2f & %.2f & %.2f & %.2f & %d",
      mean(success_rate, na.rm = TRUE), sd(success_rate, na.rm = TRUE),
      min(success_rate, na.rm = TRUE), max(success_rate, na.rm = TRUE),
      sum(!is.na(success_rate))),
    `Officer FTE` = sprintf("%.0f & %.0f & %.0f & %.0f & %d",
      mean(officer_fte), sd(officer_fte), min(officer_fte), max(officer_fte), n()),
    `Officer change from 2010 (\\%)` = sprintf("%.1f & %.1f & %.1f & %.1f & %d",
      mean(officer_change_pct), sd(officer_change_pct),
      min(officer_change_pct), max(officer_change_pct), n())
  )

tab1_lines <- c(
  "\\begin{table}[!ht]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max & N \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel A: Crime Outcomes (\\% of investigations closed)}} \\\\",
  "\\addlinespace"
)
for (nm in names(summ_vars)[1:4]) {
  tab1_lines <- c(tab1_lines, paste0(nm, " & ", summ_vars[[nm]], " \\\\"))
}
tab1_lines <- c(tab1_lines,
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: Police Workforce}} \\\\",
  "\\addlinespace"
)
for (nm in names(summ_vars)[5:6]) {
  tab1_lines <- c(tab1_lines, paste0(nm, " & ", summ_vars[[nm]], " \\\\"))
}
tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\multicolumn{6}{p{0.92\\textwidth}}{\\footnotesize \\textit{Notes:} Panel of 43 police forces in England and Wales, 2016--2023. Crime outcomes are from the Home Office Supplementary Crime Outcomes Metrics (rolling annual, Q4 snapshot). Police workforce data are from the Home Office Police Workforce Open Data Tables (as at 31 March each year). Officer change is the percentage change in police officer FTE relative to the 2010 baseline.}",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ===============================================================
# TABLE 2: Main Results
# ===============================================================
cat("=== TABLE 2: Main Results ===\n")

# Rerun models for this script's variable definitions
m1 <- feols(charge_rate ~ log_officers | force_std + year,
            data = panel, cluster = ~force_std)
m5 <- feols(victim_nosupport ~ log_officers | force_std + year,
            data = panel, cluster = ~force_std)
m6 <- feols(no_suspect ~ log_officers | force_std + year,
            data = panel, cluster = ~force_std)
m7 <- feols(success_rate ~ log_officers | force_std + year,
            data = panel, cluster = ~force_std)

tab2 <- etable(m1, m5, m6, m7,
               headers = c("Charge Rate", "Victim Withdrawal", "No Suspect", "Success Rate"),
               se.below = TRUE,
               fitstat = c("n", "r2", "wr2"),
               dict = c(log_officers = "Log(Officer FTE)"),
               notes = "Panel of 43 police forces, 2016--2023. All models include force and year fixed effects. Standard errors clustered at the force level in parentheses. Outcomes are percentages of investigations closed. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
               tex = TRUE,
               file = "tables/tab2_main.tex",
               replace = TRUE,
               title = "Police Staffing and Crime Investigation Outcomes",
               label = "tab:main")
cat("Table 2 written.\n")

# ===============================================================
# TABLE 3: Event Study (High vs Low Austerity)
# ===============================================================
cat("=== TABLE 3: Event Study ===\n")

m3 <- feols(charge_rate ~ i(year, high_austerity, ref = 2016) | force_std + year,
            data = panel, cluster = ~force_std)

# Extract coefficients for event study table
es_coefs <- data.frame(
  year = 2017:2023,
  coef = coef(m3),
  se = se(m3),
  pval = pvalue(m3)
) %>% mutate(
  stars = case_when(pval < 0.01 ~ "***", pval < 0.05 ~ "**", pval < 0.1 ~ "*", TRUE ~ ""),
  coef_str = sprintf("%.3f%s", coef, stars),
  se_str = sprintf("(%.3f)", se)
)

tab3_lines <- c(
  "\\begin{table}[!ht]",
  "\\centering",
  "\\caption{Event Study: Charge Rate Gap Between High- and Low-Austerity Forces}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Year & Coefficient & Std. Error \\\\",
  "\\hline",
  "2016 (ref.) & --- & --- \\\\"
)
for (i in 1:nrow(es_coefs)) {
  tab3_lines <- c(tab3_lines,
    sprintf("%d & %s & %s \\\\", es_coefs$year[i], es_coefs$coef_str[i], es_coefs$se_str[i]))
}

# Joint F-test
joint_f <- wald(m3, keep = "high_austerity")
tab3_lines <- c(tab3_lines,
  "\\hline",
  sprintf("Joint F-stat & \\multicolumn{2}{c}{%.2f (p = %.3f)} \\\\", joint_f$stat, joint_f$p),
  sprintf("Forces & \\multicolumn{2}{c}{%d} \\\\", n_distinct(panel$force_std[!is.na(panel$charge_rate)])),
  sprintf("Observations & \\multicolumn{2}{c}{%d} \\\\", sum(!is.na(panel$charge_rate))),
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Coefficients from a regression of victim-based charge rate (\\%) on year $\\times$ high-austerity interactions, with force and year fixed effects. High austerity is defined as officer FTE change from 2010 to 2018 below the median ($",
  sprintf("%.1f\\%%", median_cut),
  "$). Standard errors clustered at the force level. Reference year: 2016. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab3_lines, "tables/tab3_eventstudy.tex")
cat("Table 3 written.\n")

# ===============================================================
# TABLE 4: Robustness
# ===============================================================
cat("=== TABLE 4: Robustness ===\n")

r1 <- robustness$r1_no_met
r2 <- robustness$r2_placebo
r3 <- robustness$r3_total_fte

tab4 <- etable(m1, r1, r3, r2,
               headers = c("Baseline", "Excl. Met", "Total FTE", "Non-Victim (Placebo)"),
               se.below = TRUE,
               fitstat = c("n", "r2"),
               dict = c(log_officers = "Log(Officer FTE)",
                        log_total = "Log(Total FTE)"),
               notes = "All models include force and year fixed effects. Column (1) is the baseline specification from Table 2. Column (2) excludes the Metropolitan Police. Column (3) uses total policing FTE (officers + PCSOs). Column (4) is a placebo test using the charge rate for non-victim-based offenses. Standard errors clustered at the force level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
               tex = TRUE,
               file = "tables/tab4_robustness.tex",
               replace = TRUE,
               title = "Robustness Checks",
               label = "tab:robust")
cat("Table 4 written.\n")

# ===============================================================
# TABLE F1: SDE Appendix
# ===============================================================
cat("=== TABLE F1: Standardized Effect Size ===\n")

# Compute SDE for main outcomes
sd_y_charge <- sd(panel$charge_rate[panel$year <= 2018], na.rm = TRUE)
sd_y_nosup <- sd(panel$victim_nosupport[panel$year <= 2018], na.rm = TRUE)
sd_y_nosusp <- sd(panel$no_suspect[panel$year <= 2018], na.rm = TRUE)
sd_y_success <- sd(panel$success_rate[panel$year <= 2018], na.rm = TRUE)

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_x <- sd(panel$log_officers, na.rm = TRUE)

make_sde_row <- function(model, outcome_name, sd_y) {
  b <- coef(model)[1]
  se_b <- se(model)[1]
  sde <- b * sd_x / sd_y
  se_sde <- se_b * sd_x / sd_y
  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  sprintf("%s & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\",
          outcome_name, b, se_b, sd_y, sde, se_sde, bucket)
}

# Panel A: Pooled
row_charge <- make_sde_row(m1, "Victim-based charge rate", sd_y_charge)
row_nosup <- make_sde_row(m5, "Victim withdrawal rate", sd_y_nosup)
row_nosusp <- make_sde_row(m6, "No suspect identified", sd_y_nosusp)
row_success <- make_sde_row(m7, "Successful outcome rate", sd_y_success)

# Panel B: Heterogeneous (high vs low austerity)
panel_hi <- panel %>% filter(high_austerity == 1)
panel_lo <- panel %>% filter(high_austerity == 0)

m1_hi <- feols(charge_rate ~ log_officers | force_std + year,
               data = panel_hi, cluster = ~force_std)
m1_lo <- feols(charge_rate ~ log_officers | force_std + year,
               data = panel_lo, cluster = ~force_std)

sd_y_hi <- sd(panel_hi$charge_rate[panel_hi$year <= 2018], na.rm = TRUE)
sd_y_lo <- sd(panel_lo$charge_rate[panel_lo$year <= 2018], na.rm = TRUE)

row_hi <- make_sde_row(m1_hi, "Charge rate (high austerity)", sd_y_hi)
row_lo <- make_sde_row(m1_lo, "Charge rate (low austerity)", sd_y_lo)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England and Wales). ",
  "\\textbf{Research question:} Does police officer staffing affect the rate at which victim-based criminal investigations result in charges, using austerity-driven variation in officer numbers across 43 police forces? ",
  "\\textbf{Policy mechanism:} The 2010 Comprehensive Spending Review cut central government police grants by 20\\% in real terms, forcing differentially deep officer reductions in forces dependent on central funding; the 2019 Police Uplift Programme partially reversed these cuts. ",
  "\\textbf{Outcome definition:} Victim-based charge rate, defined as the percentage of closed investigations into victim-based offenses where an offender is issued a charge outcome (Home Office Supplementary Crime Outcomes Metrics). ",
  "\\textbf{Treatment:} Continuous; log police officer FTE (full-time equivalent). ",
  "\\textbf{Data:} Home Office Police Workforce Open Data Tables and Supplementary Crime Outcomes Metrics, 2016--2023, 43 police force areas, 344 force-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (force and year FE), standard errors clustered at the force level. ",
  "\\textbf{Sample:} All territorial police forces in England and Wales excluding British Transport Police (no crime outcomes data). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-2019 ",
  "standard deviation and SD($X$) is the standard deviation of log officer FTE. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[!ht]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace",
  row_charge,
  row_nosup,
  row_nosusp,
  row_success,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: By Austerity Exposure}} \\\\",
  "\\addlinespace",
  row_hi,
  row_lo,
  "\\hline\\hline",
  "\\end{tabular}",
  paste0("\\begin{itemize}[leftmargin=*,nosep]"),
  sde_notes,
  "\\end{itemize}",
  "\\end{table}"
)
writeLines(tabF1_lines, "tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
