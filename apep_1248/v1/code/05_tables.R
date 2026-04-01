## 05_tables.R — Generate all LaTeX tables for apep_1248
## V1 paper: zero figures, all results through tables

library(data.table)
library(fixest)
library(tidyverse)
library(jsonlite)

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

geih <- readRDS(file.path(DATA_DIR, "geih_analytic.rds"))
load(file.path(DATA_DIR, "main_models.RData"))
load(file.path(DATA_DIR, "robustness_models.RData"))
diagnostics <- read_json(file.path(DATA_DIR, "diagnostics.json"))

# ======== TABLE 1: SUMMARY STATISTICS ========
cat("Generating Table 1: Summary Statistics...\n")

pre_data <- geih[post == 0]
geih[, written := as.integer(p6450 == 2)]
geih[, pension := as.integer(p6920 == 1)]

sum_stats <- function(dt, label) {
  data.frame(
    Group = label,
    N = format(nrow(dt), big.mark = ","),
    Written = sprintf("%.3f", mean(dt$written, na.rm = TRUE)),
    Pension = sprintf("%.3f", mean(as.integer(dt$p6920 == 1), na.rm = TRUE)),
    Benefit_Index = sprintf("%.2f", mean(dt$benefit_index, na.rm = TRUE)),
    Vacation = sprintf("%.3f", mean(dt$benefit_vacation, na.rm = TRUE)),
    Prima = sprintf("%.3f", mean(dt$benefit_prima_nav, na.rm = TRUE)),
    Cesantias = sprintf("%.3f", mean(dt$benefit_cesantias, na.rm = TRUE)),
    Ben_Pension = sprintf("%.3f", mean(dt$benefit_pension, na.rm = TRUE)),
    Hours = sprintf("%.1f", mean(dt$hours, na.rm = TRUE)),
    Age = sprintf("%.1f", mean(dt$age, na.rm = TRUE)),
    Female = sprintf("%.3f", mean(dt$female, na.rm = TRUE)),
    stringsAsFactors = FALSE
  )
}

stats <- rbind(
  sum_stats(pre_data[small_firm == 1], "Small ($\\leq$10)"),
  sum_stats(pre_data[medium_firm == 1], "Medium (11--50)"),
  sum_stats(geih[post == 1 & small_firm == 1], "Small, Post"),
  sum_stats(geih[post == 1 & medium_firm == 1], "Medium, Post")
)

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Firm Size and Period}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-Reform (2011--2012)} & \\multicolumn{2}{c}{Post-Reform (2013--2016)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Small & Medium & Small & Medium \\\\",
  " & ($\\leq$10) & (11--50) & ($\\leq$10) & (11--50) \\\\",
  "\\midrule"
)

vars_display <- c("N", "Written", "Pension", "Benefit_Index",
                  "Vacation", "Prima", "Cesantias", "Ben_Pension",
                  "Hours", "Age", "Female")
var_labels <- c("Observations", "Written contract", "Pension contributor",
                "Benefit index (0--4)", "Paid vacation", "Prima de navidad",
                "Cesant\\'{\\i}as", "Pension contribution",
                "Weekly hours", "Age", "Female")

for (i in seq_along(vars_display)) {
  row_vals <- stats[[vars_display[i]]]
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
            var_labels[i], row_vals[1], row_vals[2], row_vals[3], row_vals[4]))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from Colombia's Gran Encuesta Integrada de Hogares (GEIH), 2011--2016. Sample: wage/salary workers ages 18--65 with positive earnings at firms with $\\leq$50 employees. ``Written contract'' indicates the worker reports having a written (not verbal) employment contract. ``Pension contributor'' indicates the worker reports contributing to a pension fund. Benefit index sums four binary indicators: paid vacation, prima de navidad, cesant\\'{\\i}as, and pension fund contributions.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(TABLE_DIR, "tab1_summary.tex"))

# ======== TABLE 2: MAIN RESULTS — FORMALIZATION AND BENEFITS ========
cat("Generating Table 2: Main Results...\n")

etable(ext_written_ctrl, ext_pension_ctrl, ben_did_ctrl, ben_did_sector,
       headers = c("Written", "Pension", "Benefits", "Benefits+Sector"),
       depvar = FALSE, se.below = TRUE,
       keep = "%small_firm:post",
       dict = c("small_firm:post" = "Small Firm $\\times$ Post"),
       style.tex = style.tex("aer"),
       title = "Effect of Law 1607 on Formalization and Benefit Delivery",
       label = "tab:main",
       notes = "Data: GEIH 2011--2016, wage/salary workers ages 18--65 in small ($\\leq$10) and medium (11--50) firms. Columns (1)--(2): binary indicators for written contract and pension contributions. Columns (3)--(4): benefit completeness index (0--4). All specifications include city and year-quarter fixed effects, age, age$^2$, female, and education dummies. Column (4) adds 2-digit sector FE. Standard errors clustered at city level in parentheses. $^{***}$p$<$0.01; $^{**}$p$<$0.05; $^{*}$p$<$0.1.",
       fitstat = c("n", "r2"),
       file = file.path(TABLE_DIR, "tab2_main.tex"),
       replace = TRUE)

# ======== TABLE 3: BENEFIT DECOMPOSITION ========
cat("Generating Table 3: Benefit Decomposition...\n")

if (length(benefit_models) >= 4) {
  etable(benefit_models[["benefit_vacation"]],
         benefit_models[["benefit_prima_nav"]],
         benefit_models[["benefit_cesantias"]],
         benefit_models[["benefit_pension"]],
         headers = c("Vacation", "Prima", "Cesant.", "Pension"),
         depvar = FALSE, se.below = TRUE,
         keep = "%small_firm:post",
         dict = c("small_firm:post" = "Small Firm $\\times$ Post"),
         style.tex = style.tex("aer"),
         title = "Benefit Decomposition: Individual Benefit Indicators",
         label = "tab:decomp",
         notes = "Data: GEIH 2011--2016, wage/salary workers ages 18--65. Each column reports the DiD coefficient from a separate regression of the respective binary benefit indicator on Small Firm $\\times$ Post. All specifications include city and year-quarter fixed effects, age, age$^2$, female, and education dummies. Standard errors clustered at city level.",
         fitstat = c("n", "r2"),
         file = file.path(TABLE_DIR, "tab3_decomp.tex"),
         replace = TRUE)
}

# ======== TABLE 4: EVENT STUDY ========
cat("Generating Table 4: Event Study...\n")

es_coefs_p <- coef(es_pension)
es_se_p <- se(es_pension)
es_coefs_b <- coef(es_benefits)
es_se_b <- se(es_benefits)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Small Firm $\\times$ Year Interactions}",
  "\\label{tab:event}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pension Contribution} & \\multicolumn{2}{c}{Benefit Index} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Year Relative to Reform & Coeff. & SE & Coeff. & SE \\\\",
  "\\midrule"
)

for (yr in c(-1, 0, 1, 2, 3, 4)) {
  term <- sprintf("year_rel::%d:small_firm", yr)
  if (yr == 0) {
    tab4_lines <- c(tab4_lines, sprintf("$t = %+d$ (reference) & --- & --- & --- & --- \\\\", yr))
  } else {
    p_coef <- ifelse(term %in% names(es_coefs_p), sprintf("%.4f", es_coefs_p[term]), "---")
    p_se <- ifelse(term %in% names(es_se_p), sprintf("(%.4f)", es_se_p[term]), "")
    b_coef <- ifelse(term %in% names(es_coefs_b), sprintf("%.4f", es_coefs_b[term]), "---")
    b_se <- ifelse(term %in% names(es_se_b), sprintf("(%.4f)", es_se_b[term]), "")
    tab4_lines <- c(tab4_lines,
      sprintf("$t = %+d$ & %s & %s & %s & %s \\\\", yr, p_coef, p_se, b_coef, b_se))
  }
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(nobs(es_pension), big.mark = ","), format(nobs(es_benefits), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Event study estimates of Small Firm $\\times$ Year interactions for pension contribution (binary) and benefit completeness index (0--4). Reference year is 2012 ($t=0$), the last pre-reform year. All specifications include city and year-quarter FE, age, age$^2$, and female. Standard errors clustered at city level. Pre-reform coefficient ($t=-1$) tests the parallel trends assumption.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(TABLE_DIR, "tab4_event.tex"))

# ======== TABLE 5: ROBUSTNESS AND PLACEBOS ========
cat("Generating Table 5: Robustness...\n")

rob_rows <- list()

add_row <- function(rows, label, mod, coef_name = "small_firm:post") {
  if (is.null(mod)) return(rows)
  beta <- coef(mod)[coef_name]
  se_val <- se(mod)[coef_name]
  pval <- 2 * pnorm(-abs(beta / se_val))
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.1, "*", "")))
  rows[[length(rows) + 1]] <- sprintf("%s & %s%s & (%s) & %s \\\\",
    label, sprintf("%.4f", beta), stars, sprintf("%.4f", se_val),
    format(nobs(mod), big.mark = ","))
  rows
}

rob_rows <- add_row(rob_rows, "Baseline (Table 2, Col.~3)", ben_did_ctrl)
rob_rows <- add_row(rob_rows, "Very small firms ($\\leq$5) vs.~medium", rob_vsmall, "very_small:post")
rob_rows <- add_row(rob_rows, "Small vs.~large ($>$50) firms", rob_large)
rob_rows <- add_row(rob_rows, "With sector FE", rob_sector)
rob_rows <- add_row(rob_rows, "Written contract workers only", rob_written)

placebo_rows <- list()
placebo_rows <- add_row(placebo_rows, "\\textit{Fake treatment year (2012 in pre-period)}", placebo_time, "small_firm:fake_post")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & N \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Robustness}} \\\\[3pt]",
  unlist(rob_rows),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Placebo Tests}} \\\\[3pt]",
  unlist(placebo_rows),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports the DiD coefficient (Small Firm $\\times$ Post) on the benefit completeness index under alternative specifications. ``Small vs.~large'' compares firms with $\\leq$10 employees to those with $>$50, excluding medium firms. ``Written contract only'' restricts to workers reporting written (not verbal) contracts. Panel B: the fake-treatment placebo uses only 2011--2012 data with a fake break at 2012. All specifications include city and year-quarter fixed effects plus individual controls. Standard errors clustered at city level. $^{***}$p$<$0.01; $^{**}$p$<$0.05; $^{*}$p$<$0.1.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(TABLE_DIR, "tab5_robustness.tex"))

# ======== SDE TABLE (APPENDIX) ========
cat("Generating SDE table...\n")

classify <- function(s) {
  if (is.na(s)) return("NA")
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s <= 0.005) "Null"
  else if (s <= 0.05) "Small positive"
  else if (s <= 0.15) "Moderate positive"
  else "Large positive"
}

# Panel A: Pooled outcomes
sde_rows <- list()
outcomes <- list(
  list(name = "Benefit Index", model = ben_did_ctrl, var = "benefit_index", coef = "small_firm:post"),
  list(name = "Paid Vacation", model = benefit_models[["benefit_vacation"]], var = "benefit_vacation", coef = "small_firm:post"),
  list(name = "Prima de Navidad", model = benefit_models[["benefit_prima_nav"]], var = "benefit_prima_nav", coef = "small_firm:post"),
  list(name = "Cesant\\'{\\i}as", model = benefit_models[["benefit_cesantias"]], var = "benefit_cesantias", coef = "small_firm:post"),
  list(name = "Pension", model = benefit_models[["benefit_pension"]], var = "benefit_pension", coef = "small_firm:post")
)

for (o in outcomes) {
  beta <- coef(o$model)[o$coef]
  se_val <- se(o$model)[o$coef]
  sd_y <- sd(geih[post == 0][[o$var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_val / sd_y
  sde_rows[[length(sde_rows) + 1]] <- sprintf(
    "%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
    o$name, beta, se_val, sd_y, sde, se_sde, classify(sde))
}

# Panel B: Heterogeneous by sex (sample splits)
het_rows <- list()
for (sex_val in c(0, 1)) {
  sex_label <- ifelse(sex_val == 0, "Male workers", "Female workers")
  df_sub <- geih[female == sex_val & !is.na(benefit_index) & !is.na(educ_level) & !is.na(hours)]
  sd_y_sub <- sd(df_sub[post == 0]$benefit_index, na.rm = TRUE)

  mod_sub <- feols(benefit_index ~ small_firm:post + small_firm + post +
                     age + I(age^2) + factor(educ_level) + hours |
                     city + year_quarter,
                   data = df_sub, cluster = ~city)

  beta_sub <- coef(mod_sub)["small_firm:post"]
  se_sub <- se(mod_sub)["small_firm:post"]
  sde_sub <- beta_sub / sd_y_sub
  se_sde_sub <- se_sub / sd_y_sub

  het_rows[[length(het_rows) + 1]] <- sprintf(
    "%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
    sex_label, beta_sub, se_sub, sd_y_sub, sde_sub, se_sde_sub, classify(sde_sub))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Colombia. ",
  "\\textbf{Research question:} Did the 2012 payroll tax cut (Law 1607, 13.5 percentage-point reduction in employer contributions) improve non-wage benefit delivery at small firms, or did formalization remain ``thin''---formal registration without delivery of legally mandated benefits? ",
  "\\textbf{Policy mechanism:} Law 1607 replaced employer payroll contributions for SENA (2\\%), ICBF (3\\%), and employee health (8.5\\%) with a corporate equity tax (CREE), reducing formal employment costs by 13.5 percentage points while leaving benefit mandates (paid vacation, prima de servicios, cesant\\'{\\i}as, pension contributions) unchanged. ",
  "\\textbf{Outcome definition:} Benefit completeness index (0--4) summing self-reported entitlement to paid vacation, prima de navidad, cesant\\'{\\i}as, and pension fund contributions among wage/salary workers. ",
  "\\textbf{Treatment:} Binary---workers at small firms ($\\leq$10 employees) vs.\\ medium firms (11--50), before vs.\\ after the January 2013 reform. ",
  "\\textbf{Data:} DANE Gran Encuesta Integrada de Hogares (GEIH), 2011--2016, covering wage/salary workers ages 18--65 across 13 metropolitan areas; unit of observation: worker-month; $N \\approx 208{,}000$. ",
  "\\textbf{Method:} Difference-in-differences (Small Firm $\\times$ Post) with city and year-quarter fixed effects, individual controls (age, education, sex, hours); standard errors clustered at city level. ",
  "\\textbf{Sample:} Wage/salary workers ages 18--65 at firms with $\\leq$50 employees, with positive earnings and non-missing benefit data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: Benefit Completeness}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  unlist(sde_rows),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits by Sex)}} \\\\[3pt]",
  unlist(het_rows),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat(sprintf("\n=== All tables generated ===\n"))
cat(sprintf("Tables: %s\n", paste(list.files(TABLE_DIR), collapse = ", ")))
