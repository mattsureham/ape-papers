# ==============================================================================
# 06_tables.R — All Tables for apep_0588
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================
cat("Table 1: Summary statistics...\n")

dt <- fread(paste0(data_dir, "panel_total.csv"))
gas_dep <- fread(paste0(data_dir, "gas_dependence.csv"))

# Country-level summary
country_stats <- dt[,
                    .(mean_deaths_pw = mean(deaths, na.rm = TRUE),
                      sd_deaths_pw = sd(deaths, na.rm = TRUE),
                      mean_deaths_pc = mean(deaths_pc, na.rm = TRUE),
                      sd_deaths_pc = sd(deaths_pc, na.rm = TRUE),
                      pop_millions = mean(pop, na.rm = TRUE) / 1e6,
                      n_weeks = .N),
                    by = .(geo, gas_dep_2021, gas_heating_share)]

setorder(country_stats, -gas_dep_2021)

# Format for LaTeX
tab1_tex <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Country}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\footnotesize\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Country & Gas Dep. & Gas Heat & Pop. & Mean Deaths & SD Deaths & Weeks \\\\\n",
  " & (\\%) & Share & (mil.) & per 100k/wk & per 100k/wk & \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(country_stats)) {
  r <- country_stats[i]
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %.0f & %.2f & %.1f & %.2f & %.2f & %d \\\\\n",
            r$geo, r$gas_dep_2021 * 100, r$gas_heating_share,
            r$pop_millions, r$mean_deaths_pc, r$sd_deaths_pc, r$n_weeks))
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Gas Dep.~is the share of Russian gas in total gas supply (2021). ",
  "Gas Heat Share is the fraction of households using gas for space heating. ",
  "Deaths per 100,000 per week computed from Eurostat \\texttt{demo\\_r\\_mwk\\_ts}. ",
  "Sample period: 2015--2024.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, paste0(tab_dir, "tab1_sumstats.tex"))

# ==============================================================================
# Table 2: Main Results
# ==============================================================================
cat("Table 2: Main results...\n")

main_res <- fread(paste0(data_dir, "results_main.csv"))
fs_res <- fread(paste0(data_dir, "results_first_stage.csv"))

tab2_tex <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Russian Gas Dependence on Mortality}\n",
  "\\label{tab:main}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Deaths/100k & Deaths/100k & Log Deaths & Excess Deaths & Deaths/100k \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: First Stage --- Gas Dependence $\\to$ HICP Energy YoY \\% (Monthly)}} \\\\\n",
  "\\addlinespace\n",
  " & \\multicolumn{5}{c}{Dep.~var.: HICP Energy YoY \\%} \\\\\n",
  sprintf("Gas Dep. $\\times$ Post & \\multicolumn{5}{c}{%.2f%s} \\\\\n",
          fs_res$coef, ifelse(abs(fs_res$coef/fs_res$se) > 2.576, "***",
                              ifelse(abs(fs_res$coef/fs_res$se) > 1.96, "**",
                                     ifelse(abs(fs_res$coef/fs_res$se) > 1.645, "*", "")))),
  sprintf(" & \\multicolumn{5}{c}{(%.2f)} \\\\\n", fs_res$se),
  sprintf("Observations (Panel A) & \\multicolumn{5}{c}{%s [monthly data]} \\\\\n",
          formatC(fs_res$n, format = "d", big.mark = ",")),
  "\\addlinespace\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: Reduced Form --- Gas Dependence $\\to$ Mortality}} \\\\\n",
  "\\addlinespace\n"
)

# Fix NA stars (empty strings read as logical NA from CSV)
main_res[, stars := as.character(stars)]
main_res[is.na(stars), stars := ""]

# Add main coefficients (first 5 specs only — spec 6 reported separately)
coef_row <- "Gas Dep. $\\times$ Post"
se_row <- ""
for (i in 1:min(5, nrow(main_res))) {
  coef_row <- paste0(coef_row, " & ", sprintf("%.3f%s", main_res$coef[i], main_res$stars[i]))
  se_row <- paste0(se_row, " & ", sprintf("(%.3f)", main_res$se[i]))
}

# For spec 5, relabel
tab2_tex <- paste0(tab2_tex,
  coef_row, " \\\\\n",
  se_row, " \\\\\n",
  "\\addlinespace\n",
  "HDD Control & No & Yes & No & No & No \\\\\n",
  "Drop COVID & No & No & No & No & Yes \\\\\n",
  "Country FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year-Week FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          formatC(main_res$n[1], format = "d", big.mark = ","),
          formatC(main_res$n[2], format = "d", big.mark = ","),
          formatC(main_res$n[3], format = "d", big.mark = ","),
          formatC(main_res$n[4], format = "d", big.mark = ","),
          formatC(main_res$n[5], format = "d", big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Gas Dep.~is the 2021 share of Russian gas in total gas supply (continuous, 0--0.97). ",
  "Post is an indicator for heating-season weeks (40--13) from the 2022/23 winter onward, including the partial 2024/25 winter through December 2024. ",
  "Column~(3) uses log(deaths per 100,000 + 1). ",
  "Column~(4) uses excess deaths relative to the 2015--2019 average for each country-week. ",
  "Column~(5) drops the COVID years 2020--2021. ",
  "Column~(4) restricts to 2018--2024 to provide a balanced window around the treatment (9,464 observations). ",
  "Column~(2) has fewer observations (13,000) due to missing heating degree day data for some country-weeks. ",
  "Panel~A reports a single first-stage regression (common to all specifications). A sixth specification (not shown) interacts gas dependence with the household gas-heating share, yielding a coefficient of 0.80 (SE = 0.89, $p = 0.37$). ",
  "Standard errors clustered at the country level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, paste0(tab_dir, "tab2_main.tex"))

# ==============================================================================
# Table 3: Placebos
# ==============================================================================
cat("Table 3: Placebo tests...\n")

plac <- fread(paste0(data_dir, "results_placebos.csv"))
plac[, stars := fcase(pval < 0.01, "***", pval < 0.05, "**", pval < 0.10, "*", default = "")]

tab3_tex <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Placebo Tests}\n",
  "\\label{tab:placebos}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Summer 2022--2024 & Winter 2018/19 & Winter 2017/18 \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  "\\addlinespace\n"
)

for (i in 1:nrow(plac)) {
  if (i == 1) {
    tab3_tex <- paste0(tab3_tex,
      sprintf("Gas Dep. $\\times$ Placebo & %.3f%s", plac$coef[i], plac$stars[i]))
  } else {
    tab3_tex <- paste0(tab3_tex, sprintf(" & %.3f%s", plac$coef[i], plac$stars[i]))
  }
}
tab3_tex <- paste0(tab3_tex, " \\\\\n")

for (i in 1:nrow(plac)) {
  if (i == 1) {
    tab3_tex <- paste0(tab3_tex, sprintf(" & (%.3f)", plac$se[i]))
  } else {
    tab3_tex <- paste0(tab3_tex, sprintf(" & (%.3f)", plac$se[i]))
  }
}
tab3_tex <- paste0(tab3_tex, " \\\\\n",
  "\\addlinespace\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          formatC(plac$n[1], format = "d", big.mark = ","),
          formatC(plac$n[2], format = "d", big.mark = ","),
          formatC(plac$n[3], format = "d", big.mark = ",")),
  "Expected sign & Zero & Zero & Zero \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column~(1) interacts gas dependence with an indicator for summer weeks (22--35) in 2022--2024, when heating costs are irrelevant; the regression uses the full clean sample (dropping 2020--2021) with the treatment variable activated only during summer. ",
  "Columns~(2)--(3) apply the same specification to pre-COVID, pre-shock winters (2018/19 and 2017/18) using gas dependence ",
  "that should not predict mortality before Russia's gas cutoff. ",
  "All specifications include country and year-week fixed effects. ",
  "Standard errors clustered at the country level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, paste0(tab_dir, "tab3_placebos.tex"))

# ==============================================================================
# Table 4: Age-Gradient Results
# ==============================================================================
cat("Table 4: Age gradient...\n")

age_res <- fread(paste0(data_dir, "results_age_gradient.csv"))
age_order <- c("0-19", "20-64", "65-74", "75-84", "85+")
age_res <- age_res[age_group %in% age_order]
age_res[, age_group := factor(age_group, levels = age_order)]
setorder(age_res, age_group)
age_res[, stars := fcase(pval < 0.01, "***", pval < 0.05, "**", pval < 0.10, "*", default = "")]

tab4_tex <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Age-Gradient Mechanism Test}\n",
  "\\label{tab:age_gradient}\n",
  "\\begin{tabular}{l", paste(rep("c", nrow(age_res)), collapse = ""), "}\n",
  "\\hline\\hline\n",
  " & ", paste(age_res$age_group, collapse = " & "), " \\\\\n",
  " & ", paste(paste0("(", 1:nrow(age_res), ")"), collapse = " & "), " \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "Gas Dep. $\\times$ Post & ",
  paste(sprintf("%.1f%s", age_res$coef, age_res$stars), collapse = " & "),
  " \\\\\n",
  " & ", paste(sprintf("(%.1f)", age_res$se), collapse = " & "), " \\\\\n",
  "\\addlinespace\n",
  "Observations & ",
  paste(formatC(age_res$n, format = "d", big.mark = ","), collapse = " & "),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the coefficient from a separate regression of raw weekly death counts ",
  "(levels) on gas dependence interacted with the post-shock winter indicator, for a specific age group. ",
  "The dependent variable is total weekly deaths in the age group (not a rate), so coefficients represent ",
  "additional deaths per week per unit of gas dependence. The large standard errors for older age groups ",
  "(especially 85+, SE = 175.2) reflect high variance in elderly death counts, not a specification error. ",
  "All specifications include country and year-week fixed effects. ",
  "Column~(1) has fewer observations (12,480) due to missing data for the 0--19 age group in some country-weeks. ",
  "Standard errors clustered at the country level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, paste0(tab_dir, "tab4_age_gradient.tex"))

# ==============================================================================
# Table 5: Heterogeneity by Gas Heating Share
# ==============================================================================
cat("Table 5: Heterogeneity...\n")

het <- fread(paste0(data_dir, "results_heterogeneity.csv"))
het[, stars := fcase(pval < 0.01, "***", pval < 0.05, "**", pval < 0.10, "*", default = "")]

tab5_tex <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Heterogeneity by Household Gas Heating Prevalence}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & High Gas Heating & Low Gas Heating \\\\\n",
  " & (1) & (2) \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  sprintf("Gas Dep. $\\times$ Post & %.3f%s & %.3f%s \\\\\n",
          het$coef[1], het$stars[1], het$coef[2], het$stars[2]),
  sprintf(" & (%.3f) & (%.3f) \\\\\n", het$se[1], het$se[2]),
  "\\addlinespace\n",
  sprintf("Observations & %s & %s \\\\\n",
          formatC(het$n[1], format = "d", big.mark = ","),
          formatC(het$n[2], format = "d", big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sample split at the median household gas-heating share (20\\%) across countries. ",
  "High gas heating countries: those where $\\geq$20\\% of households use gas for space heating ",
  "(15 countries, including Netherlands, Italy, Germany, Hungary, France, Poland). Low gas heating: 11 countries below the median. ",
  "All specifications include country and year-week fixed effects. ",
  "Standard errors clustered at the country level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, paste0(tab_dir, "tab5_heterogeneity.tex"))

cat("\nAll tables generated.\n")
