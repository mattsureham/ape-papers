source("code/00_packages.R")

results <- readRDS("data/results.rds")
robustness <- readRDS("data/robustness.rds")
enoe <- readRDS("data/enoe_analysis.rds")
diag <- results$diagnostics

tables_dir <- "tables"
dir.create(tables_dir, showWarnings = FALSE)

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmtN <- function(x) format(x, big.mark = ",")
stars_fn <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

get_coef <- function(model, var) {
  ct <- coeftable(model)
  if (var %in% rownames(ct)) {
    return(list(b = ct[var, "Estimate"], se = ct[var, "Std. Error"], p = ct[var, "Pr(>|t|)"]))
  }
  return(list(b = NA, se = NA, p = NA))
}

# TABLE 1: SUMMARY STATISTICS
formal_pre <- enoe[formal == 1 & post == 0]
informal_pre <- enoe[formal == 0 & post == 0]
formal_post <- enoe[formal == 1 & post == 1]
informal_post <- enoe[formal == 0 & post == 1]

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Formal and Informal Workers}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "  \\toprule",
  "  & \\multicolumn{2}{c}{Pre-Reform (2019--2022)} & \\multicolumn{2}{c}{Post-Reform (2023--2024)} \\\\",
  "  \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "  & Formal & Informal & Formal & Informal \\\\",
  "  \\midrule",
  sprintf("  Weekly hours & %s & %s & %s & %s \\\\",
    fmt(mean(formal_pre$hrsocup, na.rm=T), 1),
    fmt(mean(informal_pre$hrsocup, na.rm=T), 1),
    fmt(mean(formal_post$hrsocup, na.rm=T), 1),
    fmt(mean(informal_post$hrsocup, na.rm=T), 1)),
  sprintf("  & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(sd(formal_pre$hrsocup, na.rm=T), 1),
    fmt(sd(informal_pre$hrsocup, na.rm=T), 1),
    fmt(sd(formal_post$hrsocup, na.rm=T), 1),
    fmt(sd(informal_post$hrsocup, na.rm=T), 1)),
  sprintf("  Age & %s & %s & %s & %s \\\\",
    fmt(mean(formal_pre$eda, na.rm=T), 1),
    fmt(mean(informal_pre$eda, na.rm=T), 1),
    fmt(mean(formal_post$eda, na.rm=T), 1),
    fmt(mean(informal_post$eda, na.rm=T), 1)),
  sprintf("  Female share & %s & %s & %s & %s \\\\",
    fmt(mean(formal_pre$sex == 2, na.rm=T)),
    fmt(mean(informal_pre$sex == 2, na.rm=T)),
    fmt(mean(formal_post$sex == 2, na.rm=T)),
    fmt(mean(informal_post$sex == 2, na.rm=T))),
  "  \\midrule",
  sprintf("  Observations & %s & %s & %s & %s \\\\",
    fmtN(nrow(formal_pre)), fmtN(nrow(informal_pre)),
    fmtN(nrow(formal_post)), fmtN(nrow(informal_post))),
  "  \\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} ENOE quarterly microdata (INEGI), Q1 2019--Q3 2024. Employed individuals aged 15--65. Standard deviations in parentheses. Formal: social security enrollment (\\texttt{seg\\_soc} = 1). Pre-reform: Q1 2019--Q4 2022. Post-reform: Q1 2023--Q3 2024.",
  "\\end{tablenotes}",
  "\\end{table}")
writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written\n")

# TABLE 2: MAIN DiD
m1 <- get_coef(results$m1_hours, "treat_post")
m2 <- get_coef(results$m2_hours_controls, "treat_post")
m3 <- get_coef(results$m3_formal, "post")
m4 <- get_coef(results$m4_formal_controls, "post")
m5 <- get_coef(results$m5_wage, "post:high_dose")

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Vacation Reform on Labor Market Outcomes}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "  \\toprule",
  "  & (1) & (2) & (3) & (4) & (5) \\\\",
  "  & Hours & Hours & Formal & Formal & Log Wage \\\\",
  "  \\midrule",
  sprintf("  Formal $\\times$ Post & %s%s & %s%s & & & \\\\",
    fmt(m1$b), stars_fn(m1$p), fmt(m2$b), stars_fn(m2$p)),
  sprintf("  & (%s) & (%s) & & & \\\\", fmt(m1$se), fmt(m2$se)),
  sprintf("  Post-Reform & & & %s%s & %s%s & \\\\",
    fmt(m3$b), stars_fn(m3$p), fmt(m4$b), stars_fn(m4$p)),
  sprintf("  & & & (%s) & (%s) & \\\\", fmt(m3$se), fmt(m4$se)),
  sprintf("  Post $\\times$ High Dose & & & & & %s%s \\\\",
    fmt(m5$b), stars_fn(m5$p)),
  sprintf("  & & & & & (%s) \\\\", fmt(m5$se)),
  "  \\midrule",
  "  Controls & No & Yes & No & Yes & No \\\\",
  sprintf("  Observations & %s & %s & %s & %s & %s \\\\",
    fmtN(diag$n_obs), fmtN(diag$n_obs), fmtN(diag$n_obs), fmtN(diag$n_obs),
    fmtN(nobs(results$m5_wage))),
  "  \\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sprintf("\\item \\textit{Notes:} Columns (1)--(2): DiD estimate of the reform's effect on weekly hours; treated = formal workers, control = informal. Columns (3)--(4): effect on the formality rate. Column (5): within formal workers, high-dose (tenure $\\leq$ 2 years) wage differential post-reform. All include state and period FEs. Controls: sex, age, age$^2$. SEs clustered by state (32). $N$ = %s. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.", fmtN(diag$n_obs)),
  "\\end{tablenotes}",
  "\\end{table}")
writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written\n")

# TABLE 3: EVENT STUDY
es <- results$es_hours
es_ct <- coeftable(es)
es_df <- as.data.frame(es_ct)
es_df$term <- rownames(es_df)
es_rows <- grep("yq_factor", es_df$term)

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Formal--Informal Hours Gap by Quarter}",
  "\\label{tab:eventstudy}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "  \\toprule",
  "  Quarter & Coefficient & Std.~Error \\\\",
  "  \\midrule")

for (r in es_rows) {
  pstr <- gsub(".*::(\\d+):formal", "\\1", es_df$term[r])
  yr <- as.integer(substr(pstr, 1, 4))
  qt <- as.integer(substr(pstr, 5, 5))
  coef_val <- es_df$Estimate[r]
  se_val <- es_df$`Std. Error`[r]
  pval <- es_df$`Pr(>|t|)`[r]
  s <- stars_fn(pval)

  if (yr == 2023 & qt == 1 & !any(grepl("separator_added", tab3))) {
    tab3 <- c(tab3, "  \\midrule")
    tab3 <- c(tab3, "separator_added")
    tab3 <- tab3[tab3 != "separator_added"]
  }

  tab3 <- c(tab3, sprintf("  %dQ%d & %s%s & (%s) \\\\", yr, qt, fmt(coef_val), s, fmt(se_val)))
}

tab3 <- c(tab3,
  "  \\midrule",
  sprintf("  Observations & \\multicolumn{2}{c}{%s} \\\\", fmtN(diag$n_obs)),
  "  Reference & \\multicolumn{2}{c}{2022Q4} \\\\",
  "  \\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from interacting formal-sector status with quarter indicators. Dependent variable: weekly hours. Reference: 2022Q4. Horizontal line separates pre- and post-reform quarters. State and period FEs. SEs clustered by state. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")
writeLines(tab3, file.path(tables_dir, "tab3_eventstudy.tex"))
cat("Table 3 written\n")

# TABLE 4: HETEROGENEITY
ddd_formal <- get_coef(results$m_formal_ddd, "post:high_inf_sector")
ddd_post <- get_coef(results$m_formal_ddd, "post")

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity: Sector Informality and Tenure Dose}",
  "\\label{tab:heterogeneity}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "  \\toprule",
  "  & (1) & (2) \\\\",
  "  & Formality Rate & Hours (Formal) \\\\",
  "  \\midrule",
  sprintf("  Post $\\times$ High-Inf Sector & %s%s & \\\\", fmt(ddd_formal$b), stars_fn(ddd_formal$p)),
  sprintf("  & (%s) & \\\\", fmt(ddd_formal$se)),
  sprintf("  Post & %s%s & \\\\", fmt(ddd_post$b), stars_fn(ddd_post$p)),
  sprintf("  & (%s) & \\\\", fmt(ddd_post$se)))

if (!is.null(results$m_dose)) {
  dose <- get_coef(results$m_dose, "treat_post:high_dose")
  tab4 <- c(tab4,
    sprintf("  Post $\\times$ High Dose & & %s%s \\\\", fmt(dose$b), stars_fn(dose$p)),
    sprintf("  & & (%s) \\\\", fmt(dose$se)))
}

tab4 <- c(tab4,
  "  \\midrule",
  sprintf("  Observations & %s & %s \\\\",
    fmtN(diag$n_obs), fmtN(nobs(results$m_dose))),
  "  \\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Column (1): triple-difference testing whether formality declined more in high-informality sectors (agriculture, retail, construction, restaurants, domestic services) post-reform. Column (2): within formal workers, dose response comparing short-tenure ($\\leq$ 2 years, largest proportional vacation increase) vs.\\ long-tenure workers. State and period FEs. SEs clustered by state. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")
writeLines(tab4, file.path(tables_dir, "tab4_heterogeneity.tex"))
cat("Table 4 written\n")

# TABLE 5: ROBUSTNESS
r1 <- get_coef(robustness$no_covid, "treat_post")
r2 <- get_coef(robustness$state_trends, "treat_post")
r3 <- get_coef(robustness$placebo_2021, "pseudo_treat")
r4m <- get_coef(robustness$male, "treat_post")
r4f <- get_coef(robustness$female, "treat_post")

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "  \\toprule",
  "  & (1) & (2) & (3) & (4) & (5) \\\\",
  "  & No COVID & State Trends & Placebo 2021 & Male & Female \\\\",
  "  \\midrule",
  sprintf("  Formal $\\times$ Post & %s%s & %s%s & & %s%s & %s%s \\\\",
    fmt(r1$b), stars_fn(r1$p), fmt(r2$b), stars_fn(r2$p),
    fmt(r4m$b), stars_fn(r4m$p), fmt(r4f$b), stars_fn(r4f$p)),
  sprintf("  & (%s) & (%s) & & (%s) & (%s) \\\\",
    fmt(r1$se), fmt(r2$se), fmt(r4m$se), fmt(r4f$se)),
  sprintf("  Formal $\\times$ Pseudo-Post & & & %s%s & & \\\\",
    fmt(r3$b), stars_fn(r3$p)),
  sprintf("  & & & (%s) & & \\\\", fmt(r3$se)),
  "  \\midrule",
  sprintf("  Observations & %s & %s & %s & %s & %s \\\\",
    fmtN(nobs(robustness$no_covid)), fmtN(nobs(robustness$state_trends)),
    fmtN(nobs(robustness$placebo_2021)), fmtN(nobs(robustness$male)),
    fmtN(nobs(robustness$female))),
  "  \\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable: weekly hours. (1) Excludes COVID quarters (2020Q1--2021Q2). (2) Adds state-specific linear trends. (3) Placebo reform at 2021, pre-reform data only. (4)--(5) Sample split by sex. All include state and period FEs with SEs clustered by state. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")
writeLines(tab5, file.path(tables_dir, "tab5_robustness.tex"))
cat("Table 5 written\n")

# TABLE F1: SDE
sd_y_hours_pre <- sd(enoe[post == 0, hrsocup], na.rm = TRUE)
sd_y_formal_pre <- sd(enoe[post == 0, formal], na.rm = TRUE)

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) { if (sde > 0) return("Small positive") else return("Small negative") }
  if (abs_sde < 0.15) { if (sde > 0) return("Moderate positive") else return("Moderate negative") }
  if (sde > 0) return("Large positive") else return("Large negative")
}

sde_hours <- m1$b / sd_y_hours_pre
se_sde_hours <- m1$se / sd_y_hours_pre
sde_formal <- m3$b / sd_y_formal_pre
se_sde_formal <- m3$se / sd_y_formal_pre

r4m_b <- get_coef(robustness$male, "treat_post")
r4f_b <- get_coef(robustness$female, "treat_post")
sd_hours_male <- sd(enoe[post == 0 & sex == 1, hrsocup], na.rm = TRUE)
sd_hours_female <- sd(enoe[post == 0 & sex == 2, hrsocup], na.rm = TRUE)
sde_male <- r4m_b$b / sd_hours_male
se_sde_male <- r4m_b$se / sd_hours_male
sde_female <- r4f_b$b / sd_hours_female
se_sde_female <- r4f_b$se / sd_hours_female

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Mexico. ",
  "\\textbf{Research question:} Does doubling mandatory paid vacation for formal-sector workers shift employment toward informality in a country where 57\\% of employment is informal? ",
  "\\textbf{Policy mechanism:} The January 2023 Vacaciones Dignas reform amended Mexico's Federal Labor Law (Articles 76 and 78) to increase minimum vacation from 6 to 12 days after one year of service, applying only to formal-sector employment relationships; employers must maintain full pay plus a 25\\% vacation bonus (prima vacacional). ",
  "\\textbf{Outcome definition:} Weekly hours worked at primary occupation (ENOE variable \\texttt{hrsocup}) and formality indicator (social security enrollment, \\texttt{seg\\_soc} = 1). ",
  "\\textbf{Treatment:} Binary (formal-sector worker subject to mandate vs.\\ informal-sector worker exempt from mandate). ",
  sprintf("\\textbf{Data:} INEGI ENOE quarterly microdata, Q1 2019--Q3 2024, individual-level observations of employed persons aged 15--65, $N$ = %s. ", fmtN(diag$n_obs)),
  "\\textbf{Method:} Difference-in-differences with state and quarter fixed effects; standard errors clustered at the state level (32 clusters). ",
  "\\textbf{Sample:} Employed individuals aged 15--65 in Mexico; informal workers (no social security enrollment) serve as control group. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "  \\toprule",
  "  Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "  \\midrule",
  "  \\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("  Weekly hours & %s & %s & %s & %s & %s & %s \\\\",
    fmt(m1$b), fmt(m1$se), fmt(sd_y_hours_pre), fmt(sde_hours, 4), fmt(se_sde_hours, 4), classify_sde(sde_hours)),
  sprintf("  Formality rate & %s & %s & %s & %s & %s & %s \\\\",
    fmt(m3$b), fmt(m3$se), fmt(sd_y_formal_pre), fmt(sde_formal, 4), fmt(se_sde_formal, 4), classify_sde(sde_formal)),
  "  \\midrule",
  "  \\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sex split)}} \\\\",
  sprintf("  Hours (male) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(r4m_b$b), fmt(r4m_b$se), fmt(sd_hours_male), fmt(sde_male, 4), fmt(se_sde_male, 4), classify_sde(sde_male)),
  sprintf("  Hours (female) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(r4f_b$b), fmt(r4f_b$se), fmt(sd_hours_female), fmt(sde_female, 4), fmt(se_sde_female, 4), classify_sde(sde_female)),
  "  \\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")
writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written\n")

cat("\nAll tables generated successfully.\n")
