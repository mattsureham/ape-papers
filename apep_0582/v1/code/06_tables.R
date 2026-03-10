# 06_tables.R — Generate all tables
# apep_0582: The Resilience Puzzle — European Manufacturing and the Russian Gas Shock

source("00_packages.R")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("Table 1: Summary statistics\n")

summ <- panel[, .(
  mean_prod = mean(prod_index, na.rm = TRUE),
  sd_prod = sd(prod_index, na.rm = TRUE),
  mean_log_prod = mean(log_prod, na.rm = TRUE),
  sd_log_prod = sd(log_prod, na.rm = TRUE)
)]

country_summ <- panel[, .(
  russian_gas_share = first(russian_gas_share),
  subsidy_pct_gdp = first(subsidy_pct_gdp)
), by = geo]

sector_summ <- panel[, .(
  gas_intensity = first(gas_intensity)
), by = nace]

stats_table <- data.table(
  Variable = c("Industrial Production Index", "Log Production Index",
                "Russian Gas Share (country)", "Sector Gas Intensity",
                "Energy Subsidies (% GDP)", "Gas Exposure (country × sector)"),
  Mean = c(summ$mean_prod, summ$mean_log_prod,
           mean(country_summ$russian_gas_share, na.rm = TRUE),
           mean(sector_summ$gas_intensity, na.rm = TRUE),
           mean(country_summ$subsidy_pct_gdp, na.rm = TRUE),
           mean(panel$exposure, na.rm = TRUE)),
  SD = c(summ$sd_prod, summ$sd_log_prod,
         sd(country_summ$russian_gas_share, na.rm = TRUE),
         sd(sector_summ$gas_intensity, na.rm = TRUE),
         sd(country_summ$subsidy_pct_gdp, na.rm = TRUE),
         sd(panel$exposure, na.rm = TRUE)),
  Min = c(min(panel$prod_index, na.rm = TRUE), min(panel$log_prod, na.rm = TRUE),
          min(country_summ$russian_gas_share, na.rm = TRUE),
          min(sector_summ$gas_intensity, na.rm = TRUE),
          min(country_summ$subsidy_pct_gdp, na.rm = TRUE),
          min(panel$exposure, na.rm = TRUE)),
  Max = c(max(panel$prod_index, na.rm = TRUE), max(panel$log_prod, na.rm = TRUE),
          max(country_summ$russian_gas_share, na.rm = TRUE),
          max(sector_summ$gas_intensity, na.rm = TRUE),
          max(country_summ$subsidy_pct_gdp, na.rm = TRUE),
          max(panel$exposure, na.rm = TRUE)),
  N = c(nrow(panel), nrow(panel),
        nrow(country_summ), nrow(sector_summ),
        sum(!is.na(country_summ$subsidy_pct_gdp)),
        nrow(panel))
)

# Round for display
stats_table[, Mean := round(Mean, 3)]
stats_table[, SD := round(SD, 3)]
stats_table[, Min := round(Min, 3)]
stats_table[, Max := round(Max, 3)]

fwrite(stats_table, file.path(data_dir, "summary_stats.csv"))

# LaTeX output
latex_tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  "Variable & Mean & SD & Min & Max & N \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(stats_table))) {
  latex_tab1 <- paste0(latex_tab1,
    stats_table$Variable[i], " & ",
    stats_table$Mean[i], " & ",
    stats_table$SD[i], " & ",
    stats_table$Min[i], " & ",
    stats_table$Max[i], " & ",
    format(stats_table$N[i], big.mark = ","), " \\\\\n")
}

latex_tab1 <- paste0(latex_tab1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\footnotesize\n",
  "\\textit{Notes:} Industrial production index (2015 = 100) from Eurostat STS\\_INPR\\_M, monthly, seasonally and calendar adjusted. Russian gas share is the country's 2021 share of gas imports from Russia (Eurostat NRG\\_TI\\_GAS). Gas intensity is the sector's share of natural gas in total energy consumption (Eurostat NRG\\_BAL\\_C), normalized to [0,1]. Energy subsidies are cumulative government energy support measures 2021--2023 as percentage of 2021 GDP (Bruegel tracker). Gas exposure = Russian gas share $\\times$ gas intensity.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(latex_tab1, file.path(tab_dir, "tab1_summary_stats.tex"))

# ============================================================================
# TABLE 2: Main Results
# ============================================================================
cat("Table 2: Main results\n")

main_res <- fread(file.path(data_dir, "main_results.csv"))

# Re-estimate for clean etable output
m1 <- feols(log_prod ~ exposure:post | cs_id + ym, data = panel, cluster = ~geo)
m2 <- feols(log_prod ~ exposure:post | cs_id + ct_id, data = panel, cluster = ~geo)
m3 <- feols(log_prod ~ exposure:post | cs_id + ct_id + st_id, data = panel, cluster = ~geo)

# Subsidy interactions
panel[, high_subsidy := as.integer(subsidy_pct_gdp >= median(unique(subsidy_pct_gdp), na.rm = TRUE))]
m4 <- feols(log_prod ~ exposure:post + exposure:post:high_subsidy |
              cs_id + ct_id + st_id, data = panel, cluster = ~geo)
m5 <- feols(log_prod ~ exposure:post + exposure:post:subsidy_pct_gdp |
              cs_id + ct_id + st_id, data = panel, cluster = ~geo)

etable_tex <- etable(m1, m2, m3, m4, m5,
                      headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
                      se.below = TRUE,
                      signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
                      tex = TRUE,
                      file = file.path(tab_dir, "tab2_main_results.tex"),
                      title = "Main Results: Gas Exposure and Industrial Production",
                      label = "tab:main",
                      notes = c(
                        "Dependent variable: log industrial production index (2015 = 100).",
                        "Gas Exposure = Russian gas share (country, 2021) $\\times$ gas intensity (sector).",
                        "Post = 1 after March 2022. High Subsidy = above-median energy subsidies (\\% GDP).",
                        "Standard errors clustered by country in parentheses.",
                        "Columns (1)--(3) add progressively richer fixed effects.",
                        "Column (4) interacts with a binary high-subsidy indicator; column (5) uses continuous subsidies.",
                        "*** p$<$0.01, ** p$<$0.05, * p$<$0.1."
                      ),
                      fixef.group = list(
                        "Country $\\times$ Sector FE" = "cs_id",
                        "Time FE" = "ym",
                        "Country $\\times$ Time FE" = "ct_id",
                        "Sector $\\times$ Time FE" = "st_id"
                      ))

# ============================================================================
# TABLE 3: Mechanism Tests
# ============================================================================
cat("Table 3: Mechanism tests\n")

# Heterogeneity by intensity
het_dt <- fread(file.path(data_dir, "heterogeneity_intensity.csv"))

# PPI results
ppi_res <- fread(file.path(data_dir, "ppi_results.csv"))

# Fiscal shield
fiscal_res <- fread(file.path(data_dir, "fiscal_shield_results.csv"))

mech_table <- data.table(
  Test = c(
    "A. Production by gas intensity",
    "  High-intensity sectors",
    "  Medium-intensity sectors",
    "  Low-intensity sectors",
    "",
    "B. Price pass-through",
    "  Producer prices (log PPI)",
    "",
    "C. Fiscal shield (continuous)",
    "  Gas Exposure $\\times$ Post",
    "  Gas Exposure $\\times$ Post $\\times$ Subsidy (\\% GDP)"
  ),
  Coefficient = c(
    "", round(het_dt[intensity_group == "High", coef], 4),
    round(het_dt[intensity_group == "Medium", coef], 4),
    round(het_dt[intensity_group == "Low", coef], 4),
    "",
    "", ifelse(is.na(ppi_res$coef), "---", round(ppi_res$coef, 4)),
    "",
    "", round(fiscal_res$coef_main, 4),
    round(fiscal_res$coef_interaction, 4)
  ),
  SE = c(
    "", paste0("(", round(het_dt[intensity_group == "High", se], 4), ")"),
    paste0("(", round(het_dt[intensity_group == "Medium", se], 4), ")"),
    paste0("(", round(het_dt[intensity_group == "Low", se], 4), ")"),
    "",
    "", ifelse(is.na(ppi_res$se), "", paste0("(", round(ppi_res$se, 4), ")")),
    "",
    "", paste0("(", round(fiscal_res$se_main, 4), ")"),
    paste0("(", round(fiscal_res$se_interaction, 4), ")")
  )
)

fwrite(mech_table, file.path(data_dir, "mechanism_tests.csv"))

# Generate LaTeX
latex_tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Mechanism Tests: Why Did European Manufacturing Survive?}\n",
  "\\label{tab:mechanisms}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Coefficient & SE \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(mech_table))) {
  latex_tab3 <- paste0(latex_tab3,
    mech_table$Test[i], " & ", mech_table$Coefficient[i], " & ", mech_table$SE[i], " \\\\\n")
}

latex_tab3 <- paste0(latex_tab3,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\footnotesize\n",
  "\\textit{Notes:} Panel A estimates the effect of country-level Russian gas share on log industrial production separately for sectors in each gas-intensity tercile. Panel B estimates the triple-interaction effect on log producer price indices. Panel C adds a continuous interaction with cumulative energy subsidies (\\% of GDP). All specifications include country $\\times$ sector, country $\\times$ month, and sector $\\times$ month fixed effects (except Panel A, which omits sector $\\times$ month). Standard errors clustered by country.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(latex_tab3, file.path(tab_dir, "tab3_mechanisms.tex"))

# ============================================================================
# TABLE 4: Robustness Summary
# ============================================================================
cat("Table 4: Robustness\n")

loo_dt <- fread(file.path(data_dir, "leave_one_out.csv"))
boot_res <- fread(file.path(data_dir, "wild_bootstrap.csv"))
ri_res <- fread(file.path(data_dir, "randomization_inference.csv"))
placebo_dt <- fread(file.path(data_dir, "placebo_tests.csv"))
alt_dt <- fread(file.path(data_dir, "alternative_post_dates.csv"))
covid_dt <- fread(file.path(data_dir, "exclude_covid.csv"))

rob_table <- rbind(
  data.table(Test = "Baseline (Triple FE)", Coef = main_res[spec == "Triple FE", coef_exposure_post],
             SE = main_res[spec == "Triple FE", se], p_value = NA_real_),
  data.table(Test = paste0("LOO range [", round(min(loo_dt$coef), 3), ", ", round(max(loo_dt$coef), 3), "]"),
             Coef = NA, SE = NA, p_value = NA),
  data.table(Test = "Wild cluster bootstrap", Coef = main_res[spec == "Triple FE", coef_exposure_post],
             SE = NA, p_value = boot_res$p_value),
  data.table(Test = "Randomization inference", Coef = ri_res$actual_coef,
             SE = NA, p_value = ri_res$ri_p_value),
  placebo_dt[, .(Test = paste0("Placebo: ", placebo_date), Coef = coef, SE = se, p_value = NA)],
  alt_dt[, .(Test = paste0("Post = ", post_date), Coef = coef, SE = se, p_value = NA)],
  covid_dt[, .(Test = "Exclude COVID period", Coef = coef, SE = se, p_value = NA)]
)

rob_table[, Coef := round(Coef, 4)]
rob_table[, SE := round(SE, 4)]
rob_table[, p_value := round(p_value, 4)]

fwrite(rob_table, file.path(data_dir, "robustness_summary.csv"))

# LaTeX robustness table
latex_tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness and Sensitivity}\n",
  "\\label{tab:robustness}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Specification & Coefficient & SE & p-value \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(rob_table))) {
  coef_str <- ifelse(is.na(rob_table$Coef[i]), "---", as.character(rob_table$Coef[i]))
  se_str <- ifelse(is.na(rob_table$SE[i]), "---", paste0("(", rob_table$SE[i], ")"))
  p_str <- ifelse(is.na(rob_table$p_value[i]), "---", as.character(rob_table$p_value[i]))
  latex_tab4 <- paste0(latex_tab4,
    rob_table$Test[i], " & ", coef_str, " & ", se_str, " & ", p_str, " \\\\\n")
}

latex_tab4 <- paste0(latex_tab4,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\footnotesize\n",
  "\\textit{Notes:} All specifications estimate the coefficient on Gas Exposure $\\times$ Post, where Gas Exposure = Russian gas share (country) $\\times$ gas intensity (sector). Baseline includes country $\\times$ sector, country $\\times$ month, and sector $\\times$ month fixed effects with country-clustered standard errors. Wild cluster bootstrap uses Webb weights with 999 iterations. Randomization inference permutes Russian gas shares across countries (500 permutations). Placebo tests use pre-treatment fake dates on the pre-March 2022 sample.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(latex_tab4, file.path(tab_dir, "tab4_robustness.tex"))

cat("\nAll tables generated.\n")
