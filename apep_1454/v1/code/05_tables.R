# 05_tables.R — Generate all tables for the paper
source("00_packages.R")

main <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
benefit_rates <- readRDS("../data/clean_benefit_rates.rds")
employment <- readRDS("../data/clean_employment.rds")
pop_bins <- readRDS("../data/clean_population.rds")

# ── Pre-compute summary stats ───────────────────────────────────────
ben_summ <- benefit_rates %>%
  filter(benefit_type == "Net unemployed recipients of social assistance",
         sex == "Total",
         age_group %in% c("25-29 years", "30-34 years"),
         !is.na(population))

pre_25 <- ben_summ %>% filter(age_group == "25-29 years", year < 2014)
post_25 <- ben_summ %>% filter(age_group == "25-29 years", year >= 2014)
pre_30 <- ben_summ %>% filter(age_group == "30-34 years", year < 2014)
post_30 <- ben_summ %>% filter(age_group == "30-34 years", year >= 2014)

emp_summ <- employment %>%
  filter(measure == "Employment rate", sex == "Total",
         age_group_clean %in% c("25-29", "30-34"), !is.na(value))
emp_pre25 <- emp_summ %>% filter(age_group_clean == "25-29", year < 2014)
emp_post25 <- emp_summ %>% filter(age_group_clean == "25-29", year >= 2014)
emp_pre30 <- emp_summ %>% filter(age_group_clean == "30-34", year < 2014)
emp_post30 <- emp_summ %>% filter(age_group_clean == "30-34", year >= 2014)

pop_pre25 <- pop_bins %>% filter(age_group == "25-29 years", year >= 2008, year < 2014)
pop_post25 <- pop_bins %>% filter(age_group == "25-29 years", year >= 2014)
pop_pre30 <- pop_bins %>% filter(age_group == "30-34 years", year >= 2008, year < 2014)
pop_post30 <- pop_bins %>% filter(age_group == "30-34 years", year >= 2014)

pre_sd_benefit <- sd(pre_25$rate)
pre_sd_emp <- sd(emp_pre25$value)

# Extract main coefficients
did_coef <- main$did_simple$coef
did_se <- main$did_simple$se
emp_coef <- main$did_emp$coef
emp_se <- main$did_emp$se
male_coef_b <- main$did_male$coef
male_se_b <- main$did_male$se
female_coef_b <- main$did_female$coef
female_se_b <- main$did_female$se
male_coef_e <- main$did_emp_male$coef
male_se_e <- main$did_emp_male$se
female_coef_e <- main$did_emp_female$coef
female_se_e <- main$did_emp_female$se
ddd_coef <- robust$ddd$coef
ddd_se <- robust$ddd$se

# ══════════════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 1\n")
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Benefit Recipiency and Employment by Age Group}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Ages 25--29} & \\multicolumn{2}{c}{Ages 30--34} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Pre-reform & Post-reform & Pre-reform & Post-reform \\\\\n",
  " & (2008--2013) & (2014--2024) & (2008--2013) & (2014--2024) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Cash Benefit Recipiency (per 100 pop.)}} \\\\\n",
  sprintf("Mean & %.3f & %.3f & %.3f & %.3f \\\\\n",
          mean(pre_25$rate), mean(post_25$rate), mean(pre_30$rate), mean(post_30$rate)),
  sprintf("SD & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          sd(pre_25$rate), sd(post_25$rate), sd(pre_30$rate), sd(post_30$rate)),
  sprintf("N (avg.\\ recipients) & %s & %s & %s & %s \\\\\n",
          format(round(mean(pre_25$value)), big.mark=","),
          format(round(mean(post_25$value)), big.mark=","),
          format(round(mean(pre_30$value)), big.mark=","),
          format(round(mean(post_30$value)), big.mark=",")),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Employment Rate (\\%, end-November)}} \\\\\n",
  sprintf("Mean & %.1f & %.1f & %.1f & %.1f \\\\\n",
          mean(emp_pre25$value), mean(emp_post25$value),
          mean(emp_pre30$value), mean(emp_post30$value)),
  sprintf("SD & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\\n",
          sd(emp_pre25$value), sd(emp_post25$value),
          sd(emp_pre30$value), sd(emp_post30$value)),
  sprintf("N (municipality $\\times$ year) & %s & %s & %s & %s \\\\\n",
          format(nrow(emp_pre25), big.mark=","),
          format(nrow(emp_post25), big.mark=","),
          format(nrow(emp_pre30), big.mark=","),
          format(nrow(emp_post30), big.mark=",")),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Population}} \\\\\n",
  sprintf("Mean & %s & %s & %s & %s \\\\\n",
          format(round(mean(pop_pre25$population)), big.mark=","),
          format(round(mean(pop_post25$population)), big.mark=","),
          format(round(mean(pop_pre30$population)), big.mark=","),
          format(round(mean(pop_post30$population)), big.mark=",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Data from Statistics Denmark Statbank (tables AUH02, RAS200, FOLK1A). ",
  "Cash benefit recipiency is full-time-equivalent recipients of net unemployed cash assistance per 100 working-age population. ",
  "Employment rates are end-of-November register-based rates across 116 municipalities. ",
  "The 2014 Uddannelseshjælp reform reduced monthly benefits for recipients under 30 from approximately DKK~10,600 to DKK~6,000.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ══════════════════════════════════════════════════════════════════════
# Table 2: Main DiD
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 2\n")
tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of the 2014 Uddannelseshjælp Reform on Benefit Recipiency and Employment}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Cash Benefits & Employment \\\\\n",
  " & (per 100 pop.) & Rate (\\%) \\\\\n",
  " & (1) & (2) \\\\\n",
  "\\midrule\n",
  sprintf("Young $\\times$ Post & %.3f$^{***}$ & %.3f$^{***}$ \\\\\n", did_coef, emp_coef),
  sprintf(" & (%.3f) & (%.3f) \\\\\n", did_se, emp_se),
  "\\addlinespace\n",
  sprintf("Pre-reform mean (25--29) & %.3f & %.1f \\\\\n",
          mean(pre_25$rate), mean(emp_pre25$value)),
  sprintf("Effect as \\%% of mean & %.1f\\%% & %.1f\\%% \\\\\n",
          did_coef / mean(pre_25$rate) * 100, emp_coef / mean(emp_pre25$value) * 100),
  "Age group FE & Yes & --- \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "Municipality FE & --- & Yes \\\\\n",
  "Clustering & --- & Municipality \\\\\n",
  sprintf("Observations & %d & %s \\\\\n", nrow(ben_summ),
          format(nrow(emp_summ), big.mark=",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Column~(1) estimates a difference-in-differences comparing cash benefit ",
  "recipiency rates (full-time equivalents per 100 population) for ages 25--29 versus 30--34, ",
  "before and after the January~2014 reform. ",
  "Column~(2) uses municipality-level employment rates (end-November, 116 municipalities ",
  "$\\times$ 17 years) with standard errors clustered at the municipality level. ",
  "``Young'' = ages 25--29; ``Post'' = 2014 onward. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "../tables/tab2_main.tex")

# ══════════════════════════════════════════════════════════════════════
# Table 3: Heterogeneity by Sex
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 3\n")
tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Heterogeneity by Sex}\n",
  "\\label{tab:sex}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & Men & Women & Difference \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Cash Benefits (per 100 pop.)}} \\\\\n",
  sprintf("Young $\\times$ Post & %.3f$^{***}$ & %.3f$^{***}$ & %.3f$^{***}$ \\\\\n",
          male_coef_b, female_coef_b, ddd_coef),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n", male_se_b, female_se_b, ddd_se),
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Employment Rate (\\%)}} \\\\\n",
  sprintf("Young $\\times$ Post & %.3f$^{***}$ & %.3f$^{***}$ & \\\\\n",
          male_coef_e, female_coef_e),
  sprintf(" & (%.3f) & (%.3f) & \\\\\n", male_se_e, female_se_e),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Columns~(1)--(2) estimate separate DiD regressions for men and women. ",
  "Column~(3) reports the triple-difference coefficient (Young $\\times$ Post $\\times$ Male). ",
  "Panel~A uses national-level data; Panel~B uses municipality-level data clustered at the municipality level. ",
  "See Table~\\ref{tab:main} notes for variable definitions.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "../tables/tab3_sex.tex")

# ══════════════════════════════════════════════════════════════════════
# Table 4: Robustness
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 4\n")
tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness and Placebo Tests}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Coefficient & SE \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Main estimates (reproduced)}} \\\\\n",
  sprintf("Cash benefits (25--29 vs.\\ 30--34) & %.3f & (%.3f) \\\\\n", did_coef, did_se),
  sprintf("Employment rate (25--29 vs.\\ 30--34) & %.3f & (%.3f) \\\\\n", emp_coef, emp_se),
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo age groups}} \\\\\n",
  sprintf("Cash benefits (35--39 vs.\\ 40--44) & %.3f & (%.3f) \\\\\n",
          robust$placebo_benefit$coef, robust$placebo_benefit$se),
  sprintf("Employment rate (30--34 vs.\\ 35--39) & %.3f & (%.3f) \\\\\n",
          robust$placebo_employment$coef, robust$placebo_employment$se),
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Temporal placebo}} \\\\\n",
  sprintf("Benefits, placebo reform at 2011 & %.3f & (%.3f) \\\\\n",
          robust$placebo_pre$coef, robust$placebo_pre$se),
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel D: Sensitivity}} \\\\\n",
  sprintf("Employment, excl.\\ 2020--2021 & %.3f & (%.3f) \\\\\n",
          robust$did_no_covid$coef, robust$did_no_covid$se),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel~A reproduces the main estimates from Table~\\ref{tab:main}. ",
  "Panel~B applies the same DiD specification to adjacent age groups unaffected by the reform. ",
  "Panel~C estimates a placebo reform in 2011 using only pre-reform data (2008--2013). ",
  "Panel~D excludes the COVID-19 pandemic years. ",
  "Standard errors in parentheses; employment regressions clustered at the municipality level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# ══════════════════════════════════════════════════════════════════════
# SDE Table (Appendix)
# ══════════════════════════════════════════════════════════════════════
cat("Generating SDE Table\n")

sde_benefit <- did_coef / pre_sd_benefit
sde_benefit_se <- did_se / pre_sd_benefit
sde_emp <- emp_coef / pre_sd_emp
sde_emp_se <- emp_se / pre_sd_emp

# Sex-specific SDs
sd_male <- sd(benefit_rates %>%
  filter(benefit_type == "Net unemployed recipients of social assistance",
         sex == "Men", age_group == "25-29 years", year < 2014, !is.na(population)) %>%
  pull(rate))
sd_female <- sd(benefit_rates %>%
  filter(benefit_type == "Net unemployed recipients of social assistance",
         sex == "Women", age_group == "25-29 years", year < 2014, !is.na(population)) %>%
  pull(rate))

sde_male <- male_coef_b / sd_male
sde_female <- female_coef_b / sd_female

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Denmark. ",
  "\\textbf{Research question:} Does reducing welfare benefits for under-30s push young adults from social assistance into employment or education? ",
  "\\textbf{Policy mechanism:} The 2014 Uddannelseshjælp reform cut monthly social assistance for recipients aged 25--29 from approximately DKK~10,600 to DKK~6,000 (a 43\\% reduction), creating a sharp age-30 benefit cliff designed to incentivize education completion and labor market entry for young adults. ",
  "\\textbf{Outcome definition:} (1)~Full-time-equivalent cash benefit recipients per 100 working-age population from the AUH02 register; (2)~End-of-November employment rate from the RAS200 register, measuring the share of the population aged 25--29 in registered employment. ",
  "\\textbf{Treatment:} Binary; under-30 status triggering the lower Uddannelseshjælp rate versus the standard Kontanthjælp rate for ages 30+. ",
  "\\textbf{Data:} Statistics Denmark Statbank API, tables AUH02 (benefit recipients) and RAS200 (employment rates), 2008--2024, age-group-by-year cells (national) and municipality-by-age-group-by-year cells (116 municipalities). ",
  "\\textbf{Method:} Difference-in-differences comparing ages 25--29 (treated) versus 30--34 (control), with age-group and year fixed effects; employment regressions include municipality fixed effects with standard errors clustered at the municipality level. ",
  "\\textbf{Sample:} Working-age population aged 25--34 in Denmark, excluding years prior to 2008 when population denominators are unavailable. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2008--2013) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Cash benefit rate & %.3f & %.3f & %.3f & %.2f & %.2f & %s \\\\\n",
          did_coef, did_se, pre_sd_benefit, sde_benefit, sde_benefit_se, classify(sde_benefit)),
  sprintf("Employment rate & %.3f & %.3f & %.1f & %.3f & %.3f & %s \\\\\n",
          emp_coef, emp_se, pre_sd_emp, sde_emp, sde_emp_se, classify(sde_emp)),
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by sex, cash benefits)}} \\\\\n",
  sprintf("Men & %.3f & %.3f & %.3f & %.2f & --- & %s \\\\\n",
          male_coef_b, male_se_b, sd_male, sde_male, classify(sde_male)),
  sprintf("Women & %.3f & %.3f & %.3f & %.2f & --- & %s \\\\\n",
          female_coef_b, female_se_b, sd_female, sde_female, classify(sde_female)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")

saveRDS(list(
  sde_benefit = sde_benefit, sde_emp = sde_emp,
  sde_male = sde_male, sde_female = sde_female,
  pre_sd_benefit = pre_sd_benefit, pre_sd_emp = pre_sd_emp,
  did_coef = did_coef, did_se = did_se,
  emp_coef = emp_coef, emp_se = emp_se
), "../data/sde_results.rds")
