## 05_tables.R — Generate all tables including SDE appendix
## apep_0865: Last Call for Competition

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

panel[, fips_f := as.factor(fips)]
panel[, year_f := as.factor(year)]

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

# Key variables
sumstats <- panel[!is.na(emp_drink), .(
  N = .N,
  Counties = length(unique(fips)),
  `Mean Pop.` = round(mean(POP, na.rm = TRUE), 0),
  `Mean Drink. Emp.` = round(mean(emp_drink, na.rm = TRUE), 1),
  `SD Drink. Emp.` = round(sd(emp_drink, na.rm = TRUE), 1),
  `Mean Drink. Estabs.` = round(mean(estabs_drink, na.rm = TRUE), 1),
  `SD Drink. Estabs.` = round(sd(estabs_drink, na.rm = TRUE), 1),
  `Mean Rest. Emp.` = round(mean(emp_rest, na.rm = TRUE), 1),
  `Mean New Lic./yr` = round(mean(new_licenses_yr, na.rm = TRUE), 2),
  `Pct Gained Lic.` = round(100 * mean(gained_license, na.rm = TRUE), 1)
)]

# Split by treatment status
sumstats_treat <- panel[!is.na(emp_drink), .(
  N = .N,
  `Mean Drink. Emp.` = round(mean(emp_drink, na.rm = TRUE), 1),
  `SD Drink. Emp.` = round(sd(emp_drink, na.rm = TRUE), 1),
  `Mean Drink. Estabs.` = round(mean(estabs_drink, na.rm = TRUE), 1),
  `Mean Pop.` = round(mean(POP, na.rm = TRUE), 0),
  `Mean New Lic.` = round(mean(new_licenses_yr, na.rm = TRUE), 2)
), by = .(gained_license)]

cat("Summary stats (overall):\n")
print(sumstats)
cat("\nSummary stats by treatment:\n")
print(sumstats_treat)

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Florida Counties, 2010--2023}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{5}{l}{\\textit{Panel A: Outcome Variables}} \\\\",
  "\\\\[-1.8ex]"
)

# Compute full stats
vars_out <- list(
  list("Drinking-place employment", "emp_drink"),
  list("Drinking-place establishments", "estabs_drink"),
  list("Restaurant employment (placebo)", "emp_rest"),
  list("Avg. weekly wage, drinking places (\\$)", "wage_drink")
)

for (v in vars_out) {
  vals <- panel[[v[[2]]]]
  vals <- vals[!is.na(vals)]
  if (length(vals) > 0) {
    tab1_lines <- c(tab1_lines, sprintf(
      "%s & %.1f & %.1f & %.1f & %.1f \\\\",
      v[[1]], mean(vals), sd(vals), min(vals), max(vals)
    ))
  }
}

tab1_lines <- c(tab1_lines,
  "\\\\[-1.8ex]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Treatment Variables}} \\\\",
  "\\\\[-1.8ex]"
)

vars_treat <- list(
  list("Population", "POP"),
  list("New licenses (annual flow)", "new_licenses_yr"),
  list("Cumulative new licenses (stock)", "new_licenses_cumul"),
  list("Gained any license (binary)", "gained_license")
)

for (v in vars_treat) {
  vals <- panel[[v[[2]]]]
  vals <- vals[!is.na(vals)]
  if (length(vals) > 0) {
    tab1_lines <- c(tab1_lines, sprintf(
      "%s & %.1f & %.1f & %.0f & %.0f \\\\",
      v[[1]], mean(vals), sd(vals), min(vals), max(vals)
    ))
  }
}

n_obs <- nrow(panel[!is.na(emp_drink)])
n_counties <- length(unique(panel$fips[!is.na(panel$emp_drink)]))

tab1_lines <- c(tab1_lines,
  "\\\\[-1.8ex]",
  "\\hline",
  sprintf("County-years & \\multicolumn{4}{c}{%s} \\\\", format(n_obs, big.mark = ",")),
  sprintf("Counties & \\multicolumn{4}{c}{%d} \\\\", n_counties),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  paste0("\\item \\textit{Notes:} Data from BLS QCEW (NAICS 7224, 7225) and Census population estimates. ",
         "New licenses computed from FL Statute 561.20: one quota license per 7,500 residents, benchmarked to 2000 population. ",
         "Employment and establishment counts are annual averages of quarterly QCEW data."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_sumstats.tex"))
cat("Saved Table 1.\n")

# ============================================================
# Table 2: Main Results — Panel Fixed Effects
# ============================================================
cat("\n=== Generating Table 2: Main Results ===\n")

# Get coefficients
get_coef_row <- function(model, varname = "new_licenses_yr") {
  cf <- coef(model)[varname]
  se <- sqrt(vcov(model)[varname, varname])
  pv <- 2 * pnorm(-abs(cf / se))
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  list(coef = cf, se = se, pval = pv, stars = stars)
}

r1 <- get_coef_row(m1)
r2 <- get_coef_row(m2)
r3 <- get_coef_row(m3)
r4 <- get_coef_row(m4)
r5 <- get_coef_row(m5)
r6 <- get_coef_row(m6)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of New Quota Licenses on County-Level Outcomes}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & Drink. & Drink. & Log Drink. & Drink. Emp. & Rest. & Drink. \\\\",
  " & Emp. & Estabs. & Emp. & per 10K & Emp. & Wage \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  sprintf("New licenses & %.3f%s & %.3f%s & %.4f%s & %.4f%s & %.3f%s & %.3f%s \\\\",
          r1$coef, r1$stars, r2$coef, r2$stars, r3$coef, r3$stars,
          r4$coef, r4$stars, r5$coef, r5$stars, r6$coef, r6$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.4f) & (%.4f) & (%.3f) & (%.3f) \\\\",
          r1$se, r2$se, r3$se, r4$se, r5$se, r6$se),
  "\\\\[-1.8ex]",
  sprintf("Mean dep. var. & %.1f & %.1f & %.2f & %.2f & %.1f & %.1f \\\\",
          mean(panel$emp_drink, na.rm = TRUE),
          mean(panel$estabs_drink, na.rm = TRUE),
          mean(panel$log_emp_drink[is.finite(panel$log_emp_drink)], na.rm = TRUE),
          mean(panel$emp_drink_pc, na.rm = TRUE),
          mean(panel$emp_rest, na.rm = TRUE),
          mean(panel$wage_drink, na.rm = TRUE)),
  "County FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(m4), big.mark = ","),
          format(nobs(m5), big.mark = ","),
          format(nobs(m6), big.mark = ",")),
  sprintf("Counties & %d & %d & %d & %d & %d & %d \\\\",
          length(unique(panel$fips[!is.na(panel$emp_drink)])),
          length(unique(panel$fips[!is.na(panel$estabs_drink)])),
          length(unique(panel$fips[!is.na(panel$log_emp_drink) & is.finite(panel$log_emp_drink)])),
          length(unique(panel$fips[!is.na(panel$emp_drink_pc)])),
          length(unique(panel$fips[!is.na(panel$emp_rest)])),
          length(unique(panel$fips[!is.na(panel$wage_drink)]))),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  paste0("\\item \\textit{Notes:} OLS with county and year fixed effects. ",
         "Standard errors clustered at the county level in parentheses. ",
         "New licenses is the annual flow of newly entitled quota liquor licenses from FL Statute 561.20 threshold crossings. ",
         "Column (5) is a placebo: restaurant employment is not subject to quota licensing. ",
         "\\textsuperscript{***}$p<0.01$, \\textsuperscript{**}$p<0.05$, \\textsuperscript{*}$p<0.1$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))
cat("Saved Table 2.\n")

# ============================================================
# Table 3: RDD Results
# ============================================================
cat("\n=== Generating Table 3: RDD Results ===\n")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Regression Discontinuity at Population Threshold}",
  "\\label{tab:rdd}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & (1) & (2) \\\\",
  " & Drink. Emp. & Drink. Estabs. \\\\",
  "\\hline",
  "\\\\[-1.8ex]"
)

if (!is.na(rdd_coef_emp)) {
  tab3_lines <- c(tab3_lines,
    sprintf("RDD estimate & %.3f & %.3f \\\\", rdd_coef_emp, rdd_coef_estabs),
    sprintf(" & (%.3f) & (%.3f) \\\\", rdd_se_emp, rdd_se_estabs),
    "Bandwidth & MSE-optimal & MSE-optimal \\\\"
  )
} else {
  tab3_lines <- c(tab3_lines,
    "RDD estimate & --- & --- \\\\",
    " & & \\\\",
    "Bandwidth & --- & --- \\\\"
  )
}

# Add McCrary test
if (!is.null(density_test)) {
  tab3_lines <- c(tab3_lines,
    sprintf("McCrary p-value & \\multicolumn{2}{c}{%.3f} \\\\", density_test$test$p_jk)
  )
}

tab3_lines <- c(tab3_lines,
  "\\\\[-1.8ex]",
  "Kernel & Triangular & Triangular \\\\",
  "Polynomial order & 1 & 1 \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  paste0("\\item \\textit{Notes:} Local polynomial RDD estimates using rdrobust (Cattaneo, Idrobo, and Titiunik 2020). ",
         "Running variable is county population distance from the nearest 7,500-resident quota threshold. ",
         "Robust bias-corrected standard errors in parentheses. ",
         "McCrary (2008) density test p-value tests for manipulation at the threshold."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_rdd.tex"))
cat("Saved Table 3.\n")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("\n=== Generating Table 4: Robustness ===\n")

r_binary <- get_coef_row(m_binary, "gained_license")
r_pop <- get_coef_row(m_pop, "new_licenses_yr")
r_nodade <- get_coef_row(m_no_dade, "new_licenses_yr")
r_pc <- get_coef_row(m_pc, "new_licenses_yr")
r_cumul <- get_coef_row(m7, "new_licenses_cumul")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Binary & Pop. & Excl. & Per Capita & Cumul. \\\\",
  " & Treatment & Control & Miami-Dade & Emp. & Licenses \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  sprintf("Treatment & %.3f%s & %.3f%s & %.3f%s & %.4f%s & %.3f%s \\\\",
          r_binary$coef, r_binary$stars, r_pop$coef, r_pop$stars,
          r_nodade$coef, r_nodade$stars, r_pc$coef, r_pc$stars,
          r_cumul$coef, r_cumul$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.4f) & (%.3f) \\\\",
          r_binary$se, r_pop$se, r_nodade$se, r_pc$se, r_cumul$se),
  "\\\\[-1.8ex]",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(m_binary), big.mark = ","),
          format(nobs(m_pop), big.mark = ","),
          format(nobs(m_no_dade), big.mark = ","),
          format(nobs(m_pc), big.mark = ","),
          format(nobs(m7), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  paste0("\\item \\textit{Notes:} Dependent variable is drinking-place employment except column (4) which uses employment per 10,000 residents. ",
         "Column (1) uses a binary indicator for any new license allocation. ",
         "Column (2) adds county population as a control. ",
         "Column (3) excludes Miami-Dade County (FIPS 12086). ",
         "Column (5) uses cumulative new licenses since 2000 as treatment. ",
         "All models include county and year FE with county-clustered SEs. ",
         "\\textsuperscript{***}$p<0.01$, \\textsuperscript{**}$p<0.05$, \\textsuperscript{*}$p<0.1$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robust.tex"))
cat("Saved Table 4.\n")

# ============================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# ============================================================
cat("\n=== Generating SDE Table ===\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y) for binary treatment
# For continuous treatment (new_licenses_yr): SDE = beta * SD(X) / SD(Y)

sd_x <- sd(panel$new_licenses_yr, na.rm = TRUE)
sd_emp <- sd(panel$emp_drink, na.rm = TRUE)
sd_estabs <- sd(panel$estabs_drink, na.rm = TRUE)
sd_emp_rest <- sd(panel$emp_rest, na.rm = TRUE)
sd_wage <- sd(panel$wage_drink, na.rm = TRUE)

# Pooled results
sde_emp <- coef(m1)["new_licenses_yr"] * sd_x / sd_emp
sde_emp_se <- sqrt(vcov(m1)["new_licenses_yr", "new_licenses_yr"]) * sd_x / sd_emp

sde_estabs <- coef(m2)["new_licenses_yr"] * sd_x / sd_estabs
sde_estabs_se <- sqrt(vcov(m2)["new_licenses_yr", "new_licenses_yr"]) * sd_x / sd_estabs

sde_rest <- coef(m5)["new_licenses_yr"] * sd_x / sd_emp_rest
sde_rest_se <- sqrt(vcov(m5)["new_licenses_yr", "new_licenses_yr"]) * sd_x / sd_emp_rest

sde_wage <- coef(m6)["new_licenses_yr"] * sd_x / sd_wage
sde_wage_se <- sqrt(vcov(m6)["new_licenses_yr", "new_licenses_yr"]) * sd_x / sd_wage

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: large vs small counties (sample split)
median_pop <- median(panel$POP, na.rm = TRUE)
m_large <- feols(emp_drink ~ new_licenses_yr | fips_f + year_f,
                 data = panel[!is.na(emp_drink) & POP >= median_pop],
                 cluster = ~fips_f)
m_small <- feols(emp_drink ~ new_licenses_yr | fips_f + year_f,
                 data = panel[!is.na(emp_drink) & POP < median_pop],
                 cluster = ~fips_f)

sd_emp_large <- sd(panel$emp_drink[panel$POP >= median_pop], na.rm = TRUE)
sd_emp_small <- sd(panel$emp_drink[panel$POP < median_pop], na.rm = TRUE)
sd_x_large <- sd(panel$new_licenses_yr[panel$POP >= median_pop], na.rm = TRUE)
sd_x_small <- sd(panel$new_licenses_yr[panel$POP < median_pop], na.rm = TRUE)

sde_large <- coef(m_large)["new_licenses_yr"] * sd_x_large / sd_emp_large
sde_large_se <- sqrt(vcov(m_large)["new_licenses_yr", "new_licenses_yr"]) * sd_x_large / sd_emp_large
sde_small <- coef(m_small)["new_licenses_yr"] * sd_x_small / sd_emp_small
sde_small_se <- sqrt(vcov(m_small)["new_licenses_yr", "new_licenses_yr"]) * sd_x_small / sd_emp_small

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States (Florida). ",
  "\\textbf{Research question:} Whether marginal alcohol outlet entry, driven by Florida's statutory quota liquor license system, affects drinking-place employment, establishment counts, restaurant employment, and wages at the county level. ",
  "\\textbf{Policy mechanism:} FL Statute 561.20 caps quota liquor licenses at one per 7,500 county residents benchmarked to the 2000 Census population; as counties grow past successive 7,500-resident increments, additional quota licenses become available, and applicants are selected by public lottery when demand exceeds supply. ",
  "\\textbf{Outcome definition:} Drinking-place employment is the annual average of quarterly county-level employment in NAICS 7224 (Drinking Places) from the BLS Quarterly Census of Employment and Wages; establishment counts are the corresponding QCEW establishment count; restaurant employment (NAICS 7225) serves as a within-county placebo; weekly wages are average weekly wages in NAICS 7224. ",
  "\\textbf{Treatment:} Continuous --- the number of newly entitled quota liquor licenses in a county-year from population threshold crossings. ",
  "\\textbf{Data:} BLS QCEW and Census population estimates, 2010--2023, county-year level, 67 Florida counties. ",
  "\\textbf{Method:} Two-way fixed effects (county + year FE) with standard errors clustered at the county level; complemented by RDD at the 7,500-resident population threshold. ",
  "\\textbf{Sample:} All 67 Florida counties with non-missing QCEW data; Panel B splits at the median county population. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of annual new license allocations and SD($Y$) is the unconditional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\\\[-1.8ex]",
  sprintf("Drinking-place emp. & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
          coef(m1)["new_licenses_yr"],
          sqrt(vcov(m1)["new_licenses_yr", "new_licenses_yr"]),
          sd_emp, sde_emp, sde_emp_se, classify_sde(sde_emp)),
  sprintf("Drinking-place estabs. & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
          coef(m2)["new_licenses_yr"],
          sqrt(vcov(m2)["new_licenses_yr", "new_licenses_yr"]),
          sd_estabs, sde_estabs, sde_estabs_se, classify_sde(sde_estabs)),
  sprintf("Restaurant emp. (placebo) & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
          coef(m5)["new_licenses_yr"],
          sqrt(vcov(m5)["new_licenses_yr", "new_licenses_yr"]),
          sd_emp_rest, sde_rest, sde_rest_se, classify_sde(sde_rest)),
  sprintf("Avg. weekly wage & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
          coef(m6)["new_licenses_yr"],
          sqrt(vcov(m6)["new_licenses_yr", "new_licenses_yr"]),
          sd_wage, sde_wage, sde_wage_se, classify_sde(sde_wage)),
  "\\\\[-1.8ex]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample split by median county population)}} \\\\",
  "\\\\[-1.8ex]",
  sprintf("Drink. emp. (large counties) & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
          coef(m_large)["new_licenses_yr"],
          sqrt(vcov(m_large)["new_licenses_yr", "new_licenses_yr"]),
          sd_emp_large, sde_large, sde_large_se, classify_sde(sde_large)),
  sprintf("Drink. emp. (small counties) & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
          coef(m_small)["new_licenses_yr"],
          sqrt(vcov(m_small)["new_licenses_yr", "new_licenses_yr"]),
          sd_emp_small, sde_small, sde_small_se, classify_sde(sde_small)),
  "\\\\[-1.8ex]",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("Saved SDE Table.\n")

cat("\n=== All tables generated ===\n")
