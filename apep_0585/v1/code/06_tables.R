## 06_tables.R — All tables for LaTeX
## APEP-0585: EU Medical Device Regulation (MDR) and Innovation

source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

cat("=== Table 1: Summary Statistics ===\n")

panel <- fread(paste0(data_dir, "panel_production_with_intensity.csv"))
eu_panel <- panel[is_eu == TRUE & balanced == TRUE]

# Panel A: Production index by sector and period
summ_a <- eu_panel[, .(
  Mean = round(mean(prod_index, na.rm = TRUE), 1),
  SD = round(sd(prod_index, na.rm = TRUE), 1),
  Min = round(min(prod_index, na.rm = TRUE), 1),
  Max = round(max(prod_index, na.rm = TRUE), 1),
  N = .N,
  Countries = n_distinct(geo)
), by = .(Sector = nace, Period = ifelse(post_mdr, "Post-MDR (2021--2025)", "Pre-MDR (2015--2020)"))]

summ_a <- summ_a[order(Sector, Period)]

# Panel B: EUDAMED devices by risk class
risk_dist <- fread(paste0(data_dir, "eudamed_risk_distribution.csv"))
# Safety filter: keep only standard risk classes
risk_dist <- risk_dist[risk_class_clean %in% c("Class I", "Class IIa", "Class IIb", "Class III")]

# Panel C: FDA 510(k) clearances
fda <- fread(paste0(data_dir, "fda_510k_annual.csv"))
fda_summ <- fda[device_class == 0 & year >= 2015, .(
  Mean = round(mean(clearances), 0),
  SD = round(sd(clearances), 0),
  Min = min(clearances),
  Max = max(clearances),
  Years = .N
), by = .(Period = ifelse(year < 2021, "Pre-MDR (2015--2020)", "Post-MDR (2021--2025)"))]

# Write LaTeX
sink(paste0(tab_dir, "tab1_summary_stats.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{llrrrrrr}\n")
cat("\\toprule\n")
cat(" & Period & Mean & SD & Min & Max & N & Countries \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{8}{l}{\\textit{Panel A: EU Industrial Production Index (2021 = 100)}} \\\\\n")

for (i in 1:nrow(summ_a)) {
  cat(sprintf("%s & %s & %.1f & %.1f & %.1f & %.1f & %d & %d \\\\\n",
              summ_a$Sector[i], summ_a$Period[i],
              summ_a$Mean[i], summ_a$SD[i], summ_a$Min[i], summ_a$Max[i],
              summ_a$N[i], summ_a$Countries[i]))
}

cat("\\midrule\n")
cat("\\multicolumn{8}{l}{\\textit{Panel B: EUDAMED Device Registrations (as of March 2026)}} \\\\\n")
cat(" & & \\multicolumn{2}{c}{Total Devices} & & & & \\\\\n")

for (i in 1:nrow(risk_dist)) {
  cat(sprintf("%s & & \\multicolumn{2}{c}{%s} & & & & \\\\\n",
              risk_dist$risk_class_clean[i],
              format(risk_dist$total_devices[i], big.mark = ",")))
}

cat("\\midrule\n")
cat("\\multicolumn{8}{l}{\\textit{Panel C: FDA 510(k) Clearances (United States)}} \\\\\n")

for (i in 1:nrow(fda_summ)) {
  cat(sprintf("All classes & %s & %s & %s & %d & %d & %d & \\\\\n",
              fda_summ$Period[i],
              format(fda_summ$Mean[i], big.mark = ","),
              format(fda_summ$SD[i], big.mark = ","),
              fda_summ$Min[i], fda_summ$Max[i], fda_summ$Years[i]))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} Panel A reports the Eurostat annual industrial production index (base year 2021 = 100) for all EU countries with available data in each sector. Country coverage varies: C325 and C265 are available in 6 countries; C21 in 15 countries; C26 in 14 countries. C325 = manufacture of medical and dental instruments (treated by EU MDR). C21 = manufacture of pharmaceuticals (control). C265 = manufacture of measuring and testing instruments (control). C26 = manufacture of computer, electronic, and optical products (control). Panel B reports device registrations from the EUDAMED UDI-DI database restricted to the four standard MDR risk classes (1,238,105 of 1,293,060 total records; the remaining 4.3\\% carry other or transitional classifications). Panel C reports annual FDA 510(k) clearances in the United States.}\n")
cat("\\end{table}\n")
sink()

cat("  Saved tab1_summary_stats.tex\n")


# ============================================================================
# TABLE 2: Main DiD Results
# ============================================================================

cat("=== Table 2: Main results ===\n")

models <- readRDS(paste0(data_dir, "regression_models.rds"))

sink(paste0(tab_dir, "tab2_main_results.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of EU MDR on Medical Device Production}\n")
cat("\\label{tab:main_results}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Year FE & Country-Year FE & Sector Trends & DDD \\\\\n")
cat("\\midrule\n")

# Extract results
m1_coef <- round(coef(models$m1)["treat"], 3)
m1_se <- round(se(models$m1)["treat"], 3)
m2_coef <- round(coef(models$m2)["treat"], 3)
m2_se <- round(se(models$m2)["treat"], 3)
m3_coef <- round(coef(models$m3)["treat"], 3)
m3_se <- round(se(models$m3)["treat"], 3)
m4_coef <- round(coef(models$m_ddd)["treat_ddd"], 3)
m4_se <- round(se(models$m_ddd)["treat_ddd"], 3)

cat(sprintf("C325 $\\times$ Post-MDR & %.3f & %.3f & %.3f & --- \\\\\n", m1_coef, m2_coef, m3_coef))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & \\\\\n", m1_se, m2_se, m3_se))
cat(sprintf("EU $\\times$ C325 $\\times$ Post-MDR & --- & --- & --- & %.3f \\\\\n", m4_coef))
cat(sprintf(" & & & & (%.3f) \\\\\n", m4_se))
cat("\\midrule\n")
cat(sprintf("Country $\\times$ Sector FE & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Year FE & Yes & --- & --- & --- \\\\\n"))
cat(sprintf("Country $\\times$ Year FE & --- & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Sector Trends & --- & --- & Yes & --- \\\\\n"))
cat(sprintf("Observations & %d & %d & %d & %d \\\\\n",
            nobs(models$m1), nobs(models$m2), nobs(models$m3), nobs(models$m_ddd)))
cat(sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
            r2(models$m1, "r2"), r2(models$m2, "r2"), r2(models$m3, "r2"), r2(models$m_ddd, "r2")))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} The dependent variable is the Eurostat annual industrial production index (2021 = 100). The treatment is NACE C325 (medical/dental instruments) $\\times$ Post-MDR (2021--2025). Control sectors: C21 (pharmaceuticals), C265 (measuring instruments), C26 (electronics). Columns (1)--(3) use EU countries only; column (4) adds non-EU countries (Turkey, Switzerland, North Macedonia, Norway). All columns include country $\\times$ sector fixed effects. Column (1) adds year fixed effects; column (2) adds country $\\times$ year fixed effects (preferred specification); column (3) adds country $\\times$ year fixed effects and sector-specific linear trends; column (4) is a triple-difference specification with country $\\times$ sector and country $\\times$ year fixed effects; the C325 $\\times$ Post-MDR double interaction is included as a covariate (coefficient not reported; marked ``---'' in the table). Standard errors clustered at the country level in parentheses. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.}\n")
cat("\\end{table}\n")
sink()

cat("  Saved tab2_main_results.tex\n")


# ============================================================================
# TABLE 3: Robustness Summary
# ============================================================================

cat("=== Table 3: Robustness ===\n")

rob <- fread(paste0(data_dir, "robustness_summary.csv"))
loo <- fread(paste0(data_dir, "robustness_loo.csv"))
alt <- fread(paste0(data_dir, "robustness_alt_controls.csv"))

# Load robustness models for SEs in Panel A
rob_models <- readRDS(paste0(data_dir, "robustness_models.rds"))

sink(paste0(tab_dir, "tab3_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lrrrr}\n")
cat("\\toprule\n")
cat("Specification & Coefficient & SE & $p$-value & $N$ \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Diagnostic Tests}} \\\\\n")

# Main DiD
main_se <- se(models$m2)["treat"]
cat(sprintf("Main DiD (Country-Year FE) & %.3f & (%.3f) & %.3f & %d \\\\\n",
            rob$coef[1], main_se, rob$pval[1], nobs(models$m2)))

# COVID delay placebo
placebo_se <- se(rob_models$m_placebo)["placebo_treat"]
cat(sprintf("COVID delay placebo (2020) & %.3f & (%.3f) & %.3f & %d \\\\\n",
            rob$coef[2], placebo_se, rob$pval[2], nobs(rob_models$m_placebo)))

# Turkey placebo
if (!is.null(rob_models$m_turkey)) {
  turkey_se <- se(rob_models$m_turkey)["treat_tr"]
  cat(sprintf("Turkey placebo & %.3f & (%.3f) & %.3f & %d \\\\\n",
              rob$coef[3], turkey_se, rob$pval[3], nobs(rob_models$m_turkey)))
}

# RI p-value
cat(sprintf("Randomization inference & \\multicolumn{2}{c}{999 permutations} & %.3f & --- \\\\\n",
            rob$pval[4]))

cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Alternative Control Sectors}} \\\\\n")

for (i in 1:nrow(alt)) {
  cat(sprintf("Control: %s & %.3f & (%.3f) & %.3f & %d \\\\\n",
              alt$control_sector[i], alt$coef[i], alt$se[i], alt$pval[i], alt$n[i]))
}

cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel C: Leave-One-Country-Out}} \\\\\n")

for (i in 1:nrow(loo)) {
  cat(sprintf("Drop %s & %.3f & (%.3f) & %.3f & %d \\\\\n",
              loo$dropped[i], loo$coef[i], loo$se[i], loo$pval[i], loo$n[i]))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} Panel A reports diagnostic tests. ``COVID delay placebo'' uses May 2020 as a false treatment date on pre-period data only. ``Turkey placebo'' tests whether Turkish medical device production (not subject to MDR) shows a differential change after 2021. ``Randomization inference'' permutes the sector treatment assignment 999 times and reports the two-sided RI $p$-value. Panel B uses alternative control sectors individually against C325. Panel C drops each EU country in turn. All specifications include country $\\times$ sector and country $\\times$ year fixed effects (except Turkey placebo, which uses sector and year FE for a single country), with standard errors clustered at the country level.}\n")
cat("\\end{table}\n")
sink()

cat("  Saved tab3_robustness.tex\n")


# ============================================================================
# TABLE A1 (Appendix): SBS Enterprise Characteristics
# ============================================================================

cat("=== Table A1: SBS characteristics ===\n")

sbs <- fread(paste0(data_dir, "eurostat_sbs_c325.csv"))
sbs_wide <- dcast(sbs[geo %in% c("DE", "FR", "IT", "ES", "EL", "LT")],
                  geo + year ~ indicator_label, value.var = "value")

sink(paste0(tab_dir, "tabA1_sbs_characteristics.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Medical Device Industry Characteristics: SBS Data (2015--2020)}\n")
cat("\\label{tab:sbs}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lrrrrrr}\n")
cat("\\toprule\n")
cat("Country & \\multicolumn{3}{c}{Enterprises} & \\multicolumn{3}{c}{Turnover (M EUR)} \\\\\n")
cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n")
cat(" & 2015 & 2018 & 2020 & 2015 & 2018 & 2020 \\\\\n")
cat("\\midrule\n")

for (country in c("DE", "ES", "FR", "IT", "EL", "LT")) {
  d <- sbs_wide[geo == country]
  ent <- d[, .(`Number of enterprises`)]
  turn <- d[, .(`Turnover (million EUR)`)]

  e15 <- d[year == 2015, `Number of enterprises`]
  e18 <- d[year == 2018, `Number of enterprises`]
  e20 <- d[year == 2020, `Number of enterprises`]
  t15 <- d[year == 2015, `Turnover (million EUR)`]
  t18 <- d[year == 2018, `Turnover (million EUR)`]
  t20 <- d[year == 2020, `Turnover (million EUR)`]

  cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
              country,
              ifelse(length(e15) == 1 && !is.na(e15), format(e15, big.mark = ","), "--"),
              ifelse(length(e18) == 1 && !is.na(e18), format(e18, big.mark = ","), "--"),
              ifelse(length(e20) == 1 && !is.na(e20), format(e20, big.mark = ","), "--"),
              ifelse(length(t15) == 1 && !is.na(t15), format(round(t15), big.mark = ","), "--"),
              ifelse(length(t18) == 1 && !is.na(t18), format(round(t18), big.mark = ","), "--"),
              ifelse(length(t20) == 1 && !is.na(t20), format(round(t20), big.mark = ","), "--")))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} Data from Eurostat Structural Business Statistics (NACE Rev.~2, C325: Manufacture of medical and dental instruments and supplies). Enterprise counts and turnover in million EUR. Countries shown are those with complete C325 production index data used in the main analysis. ``--'' indicates data suppressed by Eurostat for confidentiality.}\n")
cat("\\end{table}\n")
sink()

cat("  Saved tabA1_sbs_characteristics.tex\n")

cat("\nAll tables generated.\n")
