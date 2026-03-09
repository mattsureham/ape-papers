# ==============================================================================
# 06_tables.R — All Table Generation
# The Credential Cliff: Multi-Cutoff RDD on South Africa Matric Pass Levels
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# TABLE 1: Summary Statistics — NSC Examination
# ==============================================================================
cat("Table 1: NSC summary statistics\n")

nsc <- fread(file.path(data_dir, "nsc_national.csv"))

# Panel A: NSC national statistics (2008-2022)
nsc_stats <- nsc %>%
  summarise(
    `Candidates (thousands)` = sprintf("%.0f", mean(total_wrote / 1000)),
    `Candidates SD` = sprintf("%.0f", sd(total_wrote / 1000)),
    `Pass rate (\\%%)` = sprintf("%.1f", mean(pass_rate)),
    `Pass rate SD` = sprintf("%.1f", sd(pass_rate)),
    `Bachelor's rate (\\%%)` = sprintf("%.1f", mean(bachelors_rate)),
    `Bachelor's SD` = sprintf("%.1f", sd(bachelors_rate)),
    `Diploma rate (\\%%)` = sprintf("%.1f", mean(diploma_rate)),
    `HC rate (\\%%)` = sprintf("%.1f", mean(higher_cert_rate)),
    Years = n()
  )

# Panel B: Latest year snapshot (2022)
nsc_2022 <- nsc %>% filter(year == 2022) %>%
  mutate(across(c(total_wrote, total_passed, bachelors_pass, diploma_pass,
                  higher_cert_pass, failed),
                ~format(.x, big.mark = ",")))

# Save as LaTeX
tab1_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: National Senior Certificate Examination}",
  "\\label{tab:summary_nsc}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & Mean & SD & Min & Max & N (years) \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: National statistics, 2008--2022}} \\\\",
  sprintf("Total candidates (thousands) & %.0f & %.0f & %.0f & %.0f & %d \\\\",
          mean(nsc$total_wrote/1000), sd(nsc$total_wrote/1000),
          min(nsc$total_wrote/1000), max(nsc$total_wrote/1000), nrow(nsc)),
  sprintf("Pass rate (\\%%) & %.1f & %.1f & %.1f & %.1f & %d \\\\",
          mean(nsc$pass_rate), sd(nsc$pass_rate),
          min(nsc$pass_rate), max(nsc$pass_rate), nrow(nsc)),
  sprintf("Bachelor's pass rate (\\%%) & %.1f & %.1f & %.1f & %.1f & %d \\\\",
          mean(nsc$bachelors_rate), sd(nsc$bachelors_rate),
          min(nsc$bachelors_rate), max(nsc$bachelors_rate), nrow(nsc)),
  sprintf("Diploma pass rate (\\%%) & %.1f & %.1f & %.1f & %.1f & %d \\\\",
          mean(nsc$diploma_rate), sd(nsc$diploma_rate),
          min(nsc$diploma_rate), max(nsc$diploma_rate), nrow(nsc)),
  sprintf("Higher certificate rate (\\%%) & %.1f & %.1f & %.1f & %.1f & %d \\\\",
          mean(nsc$higher_cert_rate), sd(nsc$higher_cert_rate),
          min(nsc$higher_cert_rate), max(nsc$higher_cert_rate), nrow(nsc)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} N = 15 years (2008--2022). All rates are percentages of total candidates who wrote the examination. Bachelor's pass requires 50\\%+ in four 20-credit subjects (excluding Life Orientation). Diploma pass requires 40\\%+ in four 20-credit subjects. Higher Certificate requires minimum 30\\% thresholds. Source: Department of Basic Education, National Senior Certificate Technical Reports (2008--2022).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary_nsc.tex"))

# ==============================================================================
# TABLE 2: Employment Outcomes by Education Level
# ==============================================================================
cat("Table 2: Employment by education\n")

qlfs <- fread(file.path(data_dir, "qlfs_clean.csv"))

qlfs_avg <- qlfs %>%
  filter(year >= 2014 & year <= 2019) %>%
  group_by(education, educ_order) %>%
  summarise(
    mean_abs = mean(absorption_rate),
    sd_abs = sd(absorption_rate),
    mean_unemp = mean(unemployment_rate),
    sd_unemp = sd(unemployment_rate),
    .groups = "drop"
  ) %>%
  arrange(educ_order)

tab2_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Employment Outcomes by Education Level, South Africa 2014--2019}",
  "\\label{tab:employment_education}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Absorption Rate (\\%)} & \\multicolumn{2}{c}{Unemployment Rate (\\%)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Education Level & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in 1:nrow(qlfs_avg)) {
  tab2_tex <- c(tab2_tex,
    sprintf("%s & %.1f & %.1f & %.1f & %.1f \\\\",
            qlfs_avg$education[i], qlfs_avg$mean_abs[i], qlfs_avg$sd_abs[i],
            qlfs_avg$mean_unemp[i], qlfs_avg$sd_unemp[i]))
}

tab2_tex <- c(tab2_tex,
  "\\midrule",
  sprintf("Matric $\\rightarrow$ Certificate/Diploma step & \\multicolumn{2}{c}{+%.1f pp} & \\multicolumn{2}{c}{$-$%.1f pp} \\\\",
          qlfs_avg$mean_abs[4] - qlfs_avg$mean_abs[3],
          qlfs_avg$mean_unemp[3] - qlfs_avg$mean_unemp[4]),
  sprintf("Certificate $\\rightarrow$ Bachelor's step & \\multicolumn{2}{c}{+%.1f pp} & \\multicolumn{2}{c}{$-$%.1f pp} \\\\",
          qlfs_avg$mean_abs[5] - qlfs_avg$mean_abs[4],
          qlfs_avg$mean_unemp[4] - qlfs_avg$mean_unemp[5]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Absorption rate is the employment-to-population ratio for ages 15--64. Unemployment rate follows the ILO narrow definition. Averages computed over QLFS Q4 surveys, 2014--2019 (pre-COVID). The ``credential cliff'' is the marginal increase in employment probability from advancing one education level. Source: Stats SA Quarterly Labour Force Survey (P0211).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_employment_education.tex"))

# ==============================================================================
# TABLE 3: Matric Pass Type Returns
# ==============================================================================
cat("Table 3: Pass type returns\n")

pto <- fread(file.path(data_dir, "pass_type_clean.csv"))

pto_avg <- pto %>%
  filter(year >= 2014 & year <= 2019) %>%
  group_by(credential_short, credential_order) %>%
  summarise(
    mean_abs = mean(absorption),
    sd_abs = sd(absorption),
    mean_earn = mean(median_earnings),
    sd_earn = sd(median_earnings),
    mean_log = mean(log_earnings),
    sd_log = sd(log_earnings),
    .groups = "drop"
  ) %>%
  arrange(credential_order)

tab3_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Labour Market Returns by Matric Credential Type, 2014--2019}",
  "\\label{tab:pass_type_returns}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Absorption (\\%)} & \\multicolumn{2}{c}{Earnings (ZAR)} & \\multicolumn{2}{c}{Log Earnings} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Credential & Mean & SD & Median & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in 1:nrow(pto_avg)) {
  tab3_tex <- c(tab3_tex,
    sprintf("%s & %.1f & %.1f & %s & %s & %.2f & %.2f \\\\",
            pto_avg$credential_short[i],
            pto_avg$mean_abs[i], pto_avg$sd_abs[i],
            format(round(pto_avg$mean_earn[i]), big.mark = ","),
            format(round(pto_avg$sd_earn[i]), big.mark = ","),
            pto_avg$mean_log[i], pto_avg$sd_log[i]))
}

# Add step differences
tab3_tex <- c(tab3_tex,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Pairwise credential steps:}} \\\\",
  sprintf("HC $\\rightarrow$ Diploma matric & +%.1f & & & & +%.2f & \\\\",
          pto_avg$mean_abs[2] - pto_avg$mean_abs[1],
          pto_avg$mean_log[2] - pto_avg$mean_log[1]),
  sprintf("HC $\\rightarrow$ Post-school diploma & +%.1f & & & & +%.2f & \\\\",
          pto_avg$mean_abs[3] - pto_avg$mean_abs[1],
          pto_avg$mean_log[3] - pto_avg$mean_log[1]),
  sprintf("Diploma matric $\\rightarrow$ University & +%.1f & & & & +%.2f & \\\\",
          pto_avg$mean_abs[4] - pto_avg$mean_abs[2],
          pto_avg$mean_log[4] - pto_avg$mean_log[2]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Absorption rate is the employment-to-population ratio. Earnings are median monthly earnings in ZAR (nominal). Pre-COVID averages (2014--2019). HC = Higher Certificate (matric pass with minimum thresholds). ``Diploma matric'' = Diploma-eligible matric pass. ``Post-school diploma'' = completed post-secondary diploma/certificate programme. ``University'' = completed bachelor's degree or higher. Source: Published aggregate statistics from the DHET Post-School Education Monitor (various years), Stats SA QLFS special tabulations by education/credential category, and DBE NSC Technical Reports. The within-matric credential breakdown (HC Pass vs.\\\\ Diploma Pass) is constructed from these published aggregate tabulations, not from individual-level QLFS microdata.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_pass_type_returns.tex"))

# ==============================================================================
# TABLE 4: Cross-Country Comparison
# ==============================================================================
cat("Table 4: Cross-country comparison\n")

xc <- fread(file.path(data_dir, "cross_country_premium.csv"))

# Select key comparators
xc_select <- xc %>%
  filter(country_code %in% c("ZA", "BR", "MX", "TR", "MY",
                               "TH", "CO", "CL", "BW", "KE")) %>%
  arrange(-mean_unemp)

tab4_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Cross-Country Comparison: Unemployment and Education Premium}",
  "\\label{tab:cross_country}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & Unemp. & Youth & Adv. Educ. & Education & Tertiary & GDP p.c. \\\\",
  " & Rate & Unemp. & Unemp. & Premium & Enroll. & (PPP) \\\\",
  "\\midrule"
)

for (i in 1:nrow(xc_select)) {
  is_za <- isTRUE(xc_select$is_south_africa[i])
  prefix <- if (is_za) "\\textbf{" else ""
  suffix <- if (is_za) "}" else ""
  tab4_tex <- c(tab4_tex,
    sprintf("%s%s%s & %s%.1f%s & %s%.1f%s & %s%.1f%s & %s%.1f%s & %s%.1f%s & %s%s%s \\\\",
            prefix, xc_select$country_name[i], suffix,
            prefix, xc_select$mean_unemp[i], suffix,
            prefix, xc_select$mean_youth_unemp[i], suffix,
            prefix, xc_select$mean_unemp_adv[i], suffix,
            prefix, xc_select$education_premium[i], suffix,
            prefix, xc_select$mean_tertiary[i], suffix,
            prefix, format(round(xc_select$mean_gdp[i]), big.mark = ","), suffix))
}

tab4_tex <- c(tab4_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Selected comparator countries (see Appendix Table C1 for full sample). Averages over 2015--2019. Unemployment and youth unemployment follow ILO narrow definition. ``Adv. Educ. Unemp.'' is the unemployment rate among those with advanced education (WDI indicator SL.UEM.ADVN.ZS: unemployment with advanced education, \\% of total labor force with advanced education). ``Education Premium'' = total unemployment minus advanced-education unemployment (percentage points). GDP per capita in PPP (current international \\$). South Africa highlighted in bold. Source: World Bank World Development Indicators.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_cross_country.tex"))

# ==============================================================================
# TABLE 5: Province-Level Variation
# ==============================================================================
cat("Table 5: Province variation\n")

prov <- fread(file.path(data_dir, "province_nsc_clean.csv"))
prov_trends <- fread(file.path(data_dir, "province_trends.csv"))

tab5_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Provincial Variation in NSC Bachelor's Pass Rates}",
  "\\label{tab:province}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & Mean Pass & Mean Bach. & Trend & SE & $R^2$ & $N$ \\\\",
  " & Rate (\\%) & Rate (\\%) & (pp/yr) & & & \\\\",
  "\\midrule"
)

for (i in 1:nrow(prov_trends)) {
  tab5_tex <- c(tab5_tex,
    sprintf("%s & %.1f & %.1f & %.2f & (%.2f) & %.2f & 9 \\\\",
            prov_trends$province[i],
            prov_trends$mean_pass[i],
            prov_trends$mean_bach[i],
            prov_trends$slope[i],
            prov_trends$se[i],
            prov_trends$r2[i]))
}

tab5_tex <- c(tab5_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Province-level averages over 2014--2022 ($N = 9$ years per province, 81 province-year observations total). Trend is the OLS slope of Bachelor's pass rate on year (pp per year). Standard errors in parentheses. Source: DBE NSC Technical Reports.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_tex, file.path(table_dir, "tab5_province.tex"))

cat("\n=== Table generation complete ===\n")
cat("Tables saved to:", table_dir, "\n")
for (f in list.files(table_dir, pattern = "\\.tex$")) {
  cat("  ", f, "\n")
}
