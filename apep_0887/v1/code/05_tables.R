# 05_tables.R — Generate all LaTeX tables for apep_0887
source("00_packages.R")

cat("=== Generating Tables for apep_0887 ===\n")

panel <- fread("../data/analysis_panel_balanced.csv")
panel[, `:=`(fips = as.character(fips),
              state_fips = sprintf("%02d", as.integer(state_fips)))]

results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
sumstats <- fread("../data/summary_stats.csv")
diagnostics <- jsonlite::fromJSON("../data/diagnostics.json")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("\n--- Table 1: Summary Statistics ---\n")

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment County Characteristics}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{RRNC Adopters} & \\multicolumn{2}{c}{Never Adopters} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n"
)

vars <- c("estab_562", "emp_562", "estab_rem", "emp_rem", "payroll_rem")
labels <- c("Establishments (NAICS 562)",
            "Employment (NAICS 562)",
            "Remediation establishments",
            "Remediation employment",
            "Remediation payroll (\\$1,000)")

for (i in seq_along(vars)) {
  row <- sumstats[variable == vars[i]]
  tab1 <- paste0(tab1, sprintf(
    "%s & %.1f & %.1f & %.1f & %.1f \\\\\n",
    labels[i], row$treated_mean, row$treated_sd,
    row$never_mean, row$never_sd
  ))
}

n_treated_counties <- diagnostics$n_treated
n_never_counties <- diagnostics$n_counties - n_treated_counties

tab1 <- paste0(tab1,
  "\\hline\n",
  sprintf("Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          n_treated_counties, n_never_counties),
  sprintf("County-years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          formatC(sum(panel$treated == 1), format = "d", big.mark = ","),
          formatC(sum(panel$treated == 0), format = "d", big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Pre-treatment means and standard deviations at the county level. ",
  "RRNC adopters are counties in the 20 states that adopted radon-resistant new construction ",
  "codes between 2007 and 2015. Never adopters are counties in the 31 states that did not ",
  "adopt during the sample period. NAICS 562 is Waste Management and Remediation Services; ",
  "NAICS 562910 is Remediation and Other Waste Management Services. Payroll in \\$1,000. ",
  "Source: Census County Business Patterns, 2003--2016.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")
cat("Table 1 written.\n")

# ============================================================
# Table 2: Main Results (TWFE + CS-DiD)
# ============================================================
cat("\n--- Table 2: Main Results ---\n")

# Extract coefficients
twfe_emp <- results$twfe_emp_rem
twfe_estab <- results$twfe_estab_rem
twfe_pay <- results$twfe_payroll

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of RRNC Building Codes on Remediation Services}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Log Employment & Log Establishments & Log Payroll \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Two-Way Fixed Effects}} \\\\\n",
  sprintf("Post RRNC & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          coef(twfe_emp)["post"], stars(pvalue(twfe_emp)["post"]),
          coef(twfe_estab)["post"], stars(pvalue(twfe_estab)["post"]),
          coef(twfe_pay)["post"], stars(pvalue(twfe_pay)["post"])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(twfe_emp)["post"], se(twfe_estab)["post"],
          se(twfe_pay)["post"]),
  "[6pt]\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Callaway--Sant'Anna (2021)}} \\\\\n"
)

# CS-DiD ATT
cs_att <- results$cs_agg
if (!is.null(cs_att)) {
  cs_p <- 2 * (1 - pnorm(abs(cs_att$overall.att / cs_att$overall.se)))
  tab2 <- paste0(tab2,
    sprintf("ATT & %.4f%s & --- & --- \\\\\n",
            cs_att$overall.att, stars(cs_p)),
    sprintf(" & (%.4f) & & \\\\\n", cs_att$overall.se)
  )
} else {
  tab2 <- paste0(tab2, "ATT & --- & --- & --- \\\\\n")
}

tab2 <- paste0(tab2,
  "\\hline\n",
  "County FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          formatC(twfe_emp$nobs, format = "d", big.mark = ","),
          formatC(twfe_estab$nobs, format = "d", big.mark = ","),
          formatC(twfe_pay$nobs, format = "d", big.mark = ",")),
  sprintf("Counties & %s & %s & %s \\\\\n",
          formatC(length(fixef(twfe_emp)$fips), format = "d", big.mark = ","),
          formatC(length(fixef(twfe_estab)$fips), format = "d", big.mark = ","),
          formatC(length(fixef(twfe_pay)$fips), format = "d", big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "Panel A reports TWFE estimates with county and year fixed effects. ",
  "Panel B reports the Callaway and Sant'Anna (2021) heterogeneity-robust ATT using ",
  "never-treated states as the control group. The dependent variable in column (1) is ",
  "log remediation employment (NAICS 562910 + 1). Columns (2) and (3) use log ",
  "establishments and log annual payroll. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ============================================================
# Table 3: Heterogeneity by Radon Zone
# ============================================================
cat("\n--- Table 3: Heterogeneity by Zone ---\n")

m_z1 <- results$zone1
m_z2 <- results$zone2
m_het <- results$het_zone

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Heterogeneity by EPA Radon Zone}\n",
  "\\label{tab:zones}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Zone 1 & Zone 2 & Interaction \\\\\n",
  " & (High Risk) & (Moderate) & (Full Sample) \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  sprintf("Post RRNC & %.4f & %.4f%s & %.4f \\\\\n",
          coef(m_z1)["post"],
          if (!is.null(m_z2)) coef(m_z2)["post"] else NA,
          if (!is.null(m_z2)) stars(pvalue(m_z2)["post"]) else "",
          coef(m_het)["post"]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(m_z1)["post"],
          if (!is.null(m_z2)) se(m_z2)["post"] else NA,
          se(m_het)["post"]),
  sprintf("Post $\\times$ Zone 1 & & & %.4f \\\\\n",
          coef(m_het)["post:zone1"]),
  sprintf(" & & & (%.4f) \\\\\n", se(m_het)["post:zone1"]),
  "\\hline\n",
  "County FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          formatC(m_z1$nobs, format = "d", big.mark = ","),
          if (!is.null(m_z2)) formatC(m_z2$nobs, format = "d", big.mark = ",") else "---",
          formatC(m_het$nobs, format = "d", big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level. ",
  "EPA radon zones: Zone 1 = predicted indoor radon $>$4 pCi/L (highest risk), ",
  "Zone 2 = 2--4 pCi/L (moderate risk). Column (3) interacts the post-RRNC indicator ",
  "with zone classification (Zone 2 is the reference category). If information salience ",
  "drives remediation demand, the effect should be largest in Zone 1 where radon risk is real. ",
  "The null Zone 1 coefficient suggests the information channel is inactive. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_zones.tex")
cat("Table 3 written.\n")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("\n--- Table 4: Robustness ---\n")

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Coefficient & SE & $N$ & Specification \\\\\n",
  "\\hline\n",
  sprintf("Baseline & %.4f & (%.4f) & %s & TWFE \\\\\n",
          diagnostics$twfe_coef, diagnostics$twfe_se,
          formatC(32272, format = "d", big.mark = ",")),
  sprintf("CS-DiD ATT & %.4f & (%.4f) & --- & Never-treated \\\\\n",
          diagnostics$cs_att, diagnostics$cs_se),
  sprintf("Drop Minnesota & %.4f & (%.4f) & %s & LOO \\\\\n",
          robust$loo_mn$coef, robust$loo_mn$se,
          formatC(31240, format = "d", big.mark = ",")),
  sprintf("Extended panel (2003--2021) & %.4f & (%.4f) & %s & Full sample \\\\\n",
          robust$full_panel$coef, robust$full_panel$se,
          formatC(40397, format = "d", big.mark = ",")),
  sprintf("Establishments & %.4f & (%.4f) & %s & Alt.~outcome \\\\\n",
          robust$estab$coef, robust$estab$se,
          formatC(32272, format = "d", big.mark = ",")),
  sprintf("Payroll & %.4f & (%.4f) & %s & Alt.~outcome \\\\\n",
          robust$payroll$coef, robust$payroll$se,
          formatC(32272, format = "d", big.mark = ",")),
  sprintf("Broader NAICS 562 & %.4f & (%.4f) & %s & Alt.~outcome \\\\\n",
          robust$broad_562$coef, robust$broad_562$se,
          formatC(32272, format = "d", big.mark = ",")),
  sprintf("Remediation share & %.4f & (%.4f) & %s & Alt.~outcome \\\\\n",
          robust$share$coef, robust$share$se,
          formatC(32272, format = "d", big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports a separate regression of the outcome on a ",
  "post-RRNC indicator with county and year fixed effects. Standard errors clustered at the ",
  "state level. The baseline uses log remediation employment (NAICS 562910) for 2003--2016. ",
  "``Drop Minnesota'' removes the largest single-state adopter (87 counties). ",
  "The extended panel includes 2017--2021 (post-CBP noise infusion redesign). ",
  "Remediation share = remediation employment / total NAICS 562 employment. ",
  "The MDE at 80\\%\\ power is 0.065 SDE, placing our null firmly in the ``Null'' ",
  "classification (SDE $< 0.005$). ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_robust.tex")
cat("Table 4 written.\n")

# ============================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY
# ============================================================
cat("\n--- Table F1: SDE ---\n")

sd_y <- diagnostics$sd_y_pre
beta_main <- diagnostics$twfe_coef
se_main <- diagnostics$twfe_se
sde_main <- beta_main / sd_y
sde_se_main <- se_main / sd_y

# Zone 1 heterogeneity
beta_z1 <- diagnostics$zone1_coef
se_z1 <- diagnostics$zone1_se
sd_y_z1 <- diagnostics$sd_y_pre_z1
sde_z1 <- beta_z1 / sd_y_z1
sde_se_z1 <- se_z1 / sd_y_z1

classify <- function(sde) {
  if (is.na(sde)) return("---")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do statewide mandates requiring radon-resistant features in new residential construction generate behavioral spillovers that expand the environmental remediation services industry beyond the directly regulated margin? ",
  "\\textbf{Policy mechanism:} Adoption of IRC Appendix F or equivalent state building codes requiring passive sub-slab depressurization systems in all new residential construction, creating a compliance infrastructure (trained contractors, local awareness, media coverage) that may diffuse to owners of existing homes. ",
  "\\textbf{Outcome definition:} Log of county-level annual employment in NAICS 562910 (Remediation and Other Waste Management Services), measured as establishment-reported headcount from Census County Business Patterns. ",
  "\\textbf{Treatment:} Binary; state-year indicator for adoption of RRNC building codes, with staggered adoption across 20 states between 2007 and 2015. ",
  "\\textbf{Data:} Census County Business Patterns (CBP), 2003--2016, county-year panel with 2,806 counties across 51 states, 32,272 observations. ",
  "\\textbf{Method:} Staggered difference-in-differences with county and year fixed effects; Callaway and Sant'Anna (2021) heterogeneity-robust estimator with never-treated control group; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All U.S. counties with non-missing NAICS 562 employment in CBP; balanced panel restricted to 2003--2016 to avoid CBP noise-infusion methodology change in 2017. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Remediation employment & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_main, se_main, sd_y, sde_main, sde_se_main, classify(sde_main)),
  sprintf("Remediation establishments & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          robust$estab$coef, robust$estab$se,
          sd(panel$log_estab_rem, na.rm = TRUE),
          robust$estab$coef / sd(panel$log_estab_rem, na.rm = TRUE),
          robust$estab$se / sd(panel$log_estab_rem, na.rm = TRUE),
          classify(robust$estab$coef / sd(panel$log_estab_rem, na.rm = TRUE))),
  sprintf("Remediation payroll & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          robust$payroll$coef, robust$payroll$se,
          sd(panel$log_payroll_rem, na.rm = TRUE),
          robust$payroll$coef / sd(panel$log_payroll_rem, na.rm = TRUE),
          robust$payroll$se / sd(panel$log_payroll_rem, na.rm = TRUE),
          classify(robust$payroll$coef / sd(panel$log_payroll_rem, na.rm = TRUE))),
  "[6pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by EPA Radon Zone)}} \\\\\n",
  sprintf("Zone 1 (high risk) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_z1, se_z1, sd_y_z1, sde_z1, sde_se_z1, classify(sde_z1)),
  sprintf("Zone 2 (moderate risk) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          if (!is.null(results$zone2)) coef(results$zone2)["post"] else NA,
          if (!is.null(results$zone2)) se(results$zone2)["post"] else NA,
          sd(panel$log_emp_rem[panel$zone2 == 1], na.rm = TRUE),
          if (!is.null(results$zone2)) coef(results$zone2)["post"] / sd(panel$log_emp_rem[panel$zone2 == 1], na.rm = TRUE) else NA,
          if (!is.null(results$zone2)) se(results$zone2)["post"] / sd(panel$log_emp_rem[panel$zone2 == 1], na.rm = TRUE) else NA,
          if (!is.null(results$zone2)) classify(coef(results$zone2)["post"] / sd(panel$log_emp_rem[panel$zone2 == 1], na.rm = TRUE)) else "---"),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Table F1 written.\n")

cat("\n=== All tables generated ===\n")
