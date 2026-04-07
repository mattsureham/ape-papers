# ==============================================================================
# 05_tables.R — Generate all tables including SDE appendix
# ==============================================================================

source("00_packages.R")

load("../data/main_results.RData")
load("../data/robustness_results.RData")

df <- arrow::read_parquet("../data/analysis_sample.parquet")
setDT(df)

main <- df[cohort_group %in% c("pre", "exposed")]

# --------------------------------------------------------------------------
# Table 1: Summary Statistics
# --------------------------------------------------------------------------

cat("Table 1: Summary statistics...\n")

# Build summary by participant x exposed
ss_groups <- main[, .(
  N = .N,
  `Mean Wage` = mean(incwage_1950, na.rm = TRUE),
  `SD Wage` = sd(incwage_1950, na.rm = TRUE),
  `Mean Education` = mean(educ_years, na.rm = TRUE),
  `SD Education` = sd(educ_years, na.rm = TRUE),
  `Mean Occ. Score` = mean(occscore_1950, na.rm = TRUE),
  `Pct Male` = mean(male, na.rm = TRUE) * 100,
  `Pct White` = mean(white, na.rm = TRUE) * 100,
  `Pct Rural (1930)` = mean(rural_1930, na.rm = TRUE) * 100
), by = .(participant, exposed)]

ss_groups[, Group := paste0(
  fifelse(participant == 1, "Participant", "Non-Participant"),
  " × ",
  fifelse(exposed == 1, "Exposed", "Pre-Treatment")
)]

# LaTeX table
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n\\centering\n\\caption{Summary Statistics by Treatment Group}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n\\toprule\n")
cat(" & \\multicolumn{2}{c}{Participating States} & \\multicolumn{2}{c}{Non-Participating (MA, CT, IL)} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat(" & Pre-Treatment & Exposed & Pre-Treatment & Exposed \\\\\n")
cat(" & (Born 1912--1921) & (Born 1922--1928) & (Born 1912--1921) & (Born 1922--1928) \\\\\n")
cat("\\midrule\n")

# Get values in order: part-pre, part-exp, nonpart-pre, nonpart-exp
vals <- ss_groups[order(-participant, exposed)]

cat(sprintf("N & %s & %s & %s & %s \\\\\n",
            format(vals$N[1], big.mark = ","),
            format(vals$N[2], big.mark = ","),
            format(vals$N[3], big.mark = ","),
            format(vals$N[4], big.mark = ",")))
cat(sprintf("Mean Wage Income (\\$1950) & %.0f & %.0f & %.0f & %.0f \\\\\n",
            vals$`Mean Wage`[1], vals$`Mean Wage`[2],
            vals$`Mean Wage`[3], vals$`Mean Wage`[4]))
cat(sprintf("SD Wage Income & %.0f & %.0f & %.0f & %.0f \\\\\n",
            vals$`SD Wage`[1], vals$`SD Wage`[2],
            vals$`SD Wage`[3], vals$`SD Wage`[4]))
cat(sprintf("Mean Education (years) & %.1f & %.1f & %.1f & %.1f \\\\\n",
            vals$`Mean Education`[1], vals$`Mean Education`[2],
            vals$`Mean Education`[3], vals$`Mean Education`[4]))
cat(sprintf("Mean Occ. Income Score & %.1f & %.1f & %.1f & %.1f \\\\\n",
            vals$`Mean Occ. Score`[1], vals$`Mean Occ. Score`[2],
            vals$`Mean Occ. Score`[3], vals$`Mean Occ. Score`[4]))
cat(sprintf("Pct Male & %.1f & %.1f & %.1f & %.1f \\\\\n",
            vals$`Pct Male`[1], vals$`Pct Male`[2],
            vals$`Pct Male`[3], vals$`Pct Male`[4]))
cat(sprintf("Pct White & %.1f & %.1f & %.1f & %.1f \\\\\n",
            vals$`Pct White`[1], vals$`Pct White`[2],
            vals$`Pct White`[3], vals$`Pct White`[4]))
cat(sprintf("Pct Rural (1930) & %.1f & %.1f & %.1f & %.1f \\\\\n",
            vals$`Pct Rural (1930)`[1], vals$`Pct Rural (1930)`[2],
            vals$`Pct Rural (1930)`[3], vals$`Pct Rural (1930)`[4]))

cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Data from the IPUMS Multigenerational Longitudinal Panel (MLP), linking individuals across the 1930, 1940, and 1950 full-count censuses. Participating states accepted federal Sheppard-Towner Act funds (1921--1929). Non-participating states (Massachusetts, Connecticut, Illinois) refused on states' rights grounds. Wage income and occupational income score measured in 1950.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# --------------------------------------------------------------------------
# Table 2: Main DDD Results
# --------------------------------------------------------------------------

cat("Table 2: Main results...\n")

# Use etable from fixest for LaTeX output
etable(m1, m2, m3, m4, m5, m6,
       headers = c("Wage", "Wage", "Wage", "Log Wage", "Education", "Occ. Score"),
       dict = c(ddd = "Participant $\\times$ Exposed",
                participant = "Participant",
                exposed = "Exposed",
                male = "Male",
                white = "White"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       file = "../tables/tab2_main_results.tex",
       replace = TRUE,
       label = "tab:main",
       title = "Sheppard-Towner Exposure and Long-Run Outcomes: Triple-Difference Estimates",
       notes = c("Data: IPUMS MLP 1930--1940--1950 linked panel. Sample: US-born individuals, birth cohorts 1912--1928.",
                 "Non-participating states: MA, CT, IL. Standard errors clustered by birth state in parentheses.",
                 "All specifications include birth-year and birth-state fixed effects.",
                 "$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$."))

# --------------------------------------------------------------------------
# Table 3: Robustness
# --------------------------------------------------------------------------

cat("Table 3: Robustness...\n")

etable(m2, border_m, placebo_m, m_post, m_emp, m_married,
       headers = c("Main", "Border", "Placebo", "Post-Repeal", "Employment", "Marriage"),
       dict = c(ddd = "Participant $\\times$ Exposed",
                fake_ddd = "Placebo DDD",
                post_ddd = "Post-Repeal DDD"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       file = "../tables/tab3_robustness.tex",
       replace = TRUE,
       label = "tab:robust",
       title = "Robustness Checks and Additional Outcomes",
       notes = c("Column 1: baseline. Column 2: restricted to states bordering MA, CT, or IL.",
                 "Column 3: placebo test using only pre-treatment cohorts (born 1905--1921), with fake exposure window 1912--1918.",
                 "Column 4: post-repeal cohorts (born 1929--1932) vs. pre-treatment, testing whether effects fade.",
                 "Columns 5--6: extensive-margin outcomes. Standard errors clustered by birth state.",
                 "$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$."))

# --------------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# --------------------------------------------------------------------------

cat("Table F1: SDE table...\n")

# Compute SDE for main outcomes
# Pre-treatment SD of Y (control group, pre-period)
pre_control <- main[participant == 0 & exposed == 0]

sd_wage <- sd(pre_control$incwage_1950, na.rm = TRUE)
sd_educ <- sd(pre_control$educ_years, na.rm = TRUE)
sd_occ <- sd(pre_control$occscore_1950, na.rm = TRUE)

# Panel A: Pooled
beta_wage <- coef(m2)["ddd"]
se_wage_val <- se(m2)["ddd"]
sde_wage <- beta_wage / sd_wage
se_sde_wage <- se_wage_val / sd_wage

beta_educ <- coef(m5)["ddd"]
se_educ_val <- se(m5)["ddd"]
sde_educ <- beta_educ / sd_educ
se_sde_educ <- se_educ_val / sd_educ

beta_occ <- coef(m6)["ddd"]
se_occ_val <- se(m6)["ddd"]
sde_occ <- beta_occ / sd_occ
se_sde_occ <- se_occ_val / sd_occ

classify_sde <- function(s) {
  s <- abs(as.numeric(s))  # Ensure numeric
  if (is.na(s)) return("N/A")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small")
  if (s < 0.15) return("Moderate")
  return("Large")
}

# Determine sign for classification
classify_sde_signed <- function(s) {
  val <- as.numeric(s)
  if (is.na(val)) return("N/A")
  mag <- classify_sde(val)
  if (mag == "Null") return("Null")
  dir <- ifelse(val > 0, "positive", "negative")
  return(paste(mag, dir))
}

# Panel B: Heterogeneity (sample splits)
# Black subsample
pre_control_black <- main[participant == 0 & exposed == 0 & black == 1]
sd_wage_black <- sd(pre_control_black$incwage_1950, na.rm = TRUE)
beta_black <- coef(m_black)["ddd"]
se_black <- se(m_black)["ddd"]
sde_black <- beta_black / sd_wage_black
se_sde_black <- se_black / sd_wage_black

# Rural subsample
pre_control_rural <- main[participant == 0 & exposed == 0 & rural_1930 == 1]
sd_wage_rural <- sd(pre_control_rural$incwage_1950, na.rm = TRUE)
beta_rural <- coef(m_rural)["ddd"]
se_rural_val <- se(m_rural)["ddd"]
sde_rural <- beta_rural / sd_wage_rural
se_sde_rural <- se_rural_val / sd_wage_rural

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does prenatal and infant exposure to America's first federal public health program (Sheppard-Towner Act, 1921--1929) produce lasting human capital gains measurable in adult wage income, education, and occupational attainment? ",
  "\\textbf{Policy mechanism:} The Act provided federal matching funds to states for maternal and infant health education, establishing approximately 3,000 prenatal clinics and deploying visiting nurses for over 3 million home visits targeting expectant and new mothers. Three states (Massachusetts, Connecticut, Illinois) refused participation on states' rights grounds. ",
  "\\textbf{Outcome definition:} Panel A reports wage income in 1950 dollars (incwage\\_1950), years of completed schooling (educ\\_1950), and occupational income score (occscore\\_1950). Panel B reports wage income for Black individuals and rural-born individuals separately. ",
  "\\textbf{Treatment:} Binary --- born 1922--1928 in a state that accepted Sheppard-Towner funds vs.\\ born in a non-participating state or in a pre-treatment cohort. ",
  "\\textbf{Data:} IPUMS Multigenerational Longitudinal Panel (MLP) linking individuals across 1930, 1940, and 1950 full-count censuses; birth cohorts 1912--1928; US-born individuals. ",
  "\\textbf{Method:} Triple-differences (DDD) with birth-year and birth-state fixed effects, demographic controls, standard errors clustered by birth state. ",
  "\\textbf{Sample:} US-born individuals observed in all three census decades, restricted to birth cohorts 1912--1928, with valid wage income in 1950. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation (non-participating states, pre-1922 cohorts). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Standardized Effect Sizes: Sheppard-Towner Act Exposure}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Wage Income & %.1f & %.1f & %.1f & %.4f & %.4f & %s \\\\\n",
            beta_wage, se_wage_val, sd_wage, sde_wage, se_sde_wage, classify_sde_signed(sde_wage)))
cat(sprintf("Education (years) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
            beta_educ, se_educ_val, sd_educ, sde_educ, se_sde_educ, classify_sde_signed(sde_educ)))
cat(sprintf("Occ. Income Score & %.2f & %.2f & %.2f & %.4f & %.4f & %s \\\\\n",
            beta_occ, se_occ_val, sd_occ, sde_occ, se_sde_occ, classify_sde_signed(sde_occ)))
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Wage Income)}} \\\\\n")
cat(sprintf("Black subsample & %.1f & %.1f & %.1f & %.4f & %.4f & %s \\\\\n",
            beta_black, se_black, sd_wage_black, sde_black, se_sde_black, classify_sde_signed(sde_black)))
cat(sprintf("Rural-born subsample & %.1f & %.1f & %.1f & %.4f & %.4f & %s \\\\\n",
            beta_rural, se_rural_val, sd_wage_rural, sde_rural, se_sde_rural, classify_sde_signed(sde_rural)))
cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("All tables saved.\n")
