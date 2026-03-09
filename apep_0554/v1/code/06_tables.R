## ============================================================
## 06_tables.R — All table generation
## apep_0554: Can Shorter Workweeks Save Fertility?
## ============================================================

source("00_packages.R")

## Load data
panel   <- fread(file.path(data_dir, "scm_panel.csv"))
kor_ind <- fread(file.path(data_dir, "korea_industry_panel.csv"))
sumstat <- fread(file.path(data_dir, "summary_stats.csv"))

T0 <- 2018

## ============================================================
## Table 1: Summary Statistics
## ============================================================

cat("=== Table 1: Summary Statistics ===\n")

## Expand summary statistics
kor <- panel[iso3 == "KOR" & year >= 2005]
donors <- panel[iso3 != "KOR" & year >= 2005]

vars_to_summarize <- c("tfr", "cbr", "mean_weekly_hours", "gdp_pc", "flfp", "unemp")
var_labels <- c("Total fertility rate", "Crude birth rate (per 1,000)",
                "Mean weekly hours", "GDP per capita (2015 USD)",
                "Female LFP (%)", "Unemployment rate (%)")

tab1 <- data.table(
  Variable = var_labels,
  Korea_Mean = sapply(vars_to_summarize, function(v) {
    x <- kor[[v]]; if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
  }),
  Korea_SD = sapply(vars_to_summarize, function(v) {
    x <- kor[[v]]; if (all(is.na(x))) NA_real_ else sd(x, na.rm = TRUE)
  }),
  OECD_Mean = sapply(vars_to_summarize, function(v) {
    x <- donors[[v]]; if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
  }),
  OECD_SD = sapply(vars_to_summarize, function(v) {
    x <- donors[[v]]; if (all(is.na(x))) NA_real_ else sd(x, na.rm = TRUE)
  }),
  N_Korea = sapply(vars_to_summarize, function(v) sum(!is.na(kor[[v]]))),
  N_OECD = sapply(vars_to_summarize, function(v) sum(!is.na(donors[[v]])))
)

print(tab1)
fwrite(tab1, file.path(data_dir, "table1_summary_stats.csv"))

## LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Summary Statistics: South Korea vs.\\ OECD Donors, 2005--2023}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  " & \\multicolumn{2}{c}{South Korea} & \\multicolumn{2}{c}{OECD Donors} & \\multicolumn{2}{c}{$N$} \\\\\n",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\\cmidrule(lr){6-7}\n",
  " Variable & Mean & SD & Mean & SD & Korea & OECD \\\\\n",
  "\\hline\n"
)
for (i in 1:nrow(tab1)) {
  tab1_tex <- paste0(tab1_tex, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %d & %d \\\\\n",
    tab1$Variable[i], tab1$Korea_Mean[i], tab1$Korea_SD[i],
    tab1$OECD_Mean[i], tab1$OECD_SD[i],
    tab1$N_Korea[i], tab1$N_OECD[i]
  ))
}
tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\footnotesize\\textit{Notes:} Sample covers 38 OECD member countries, 2005--2023. ",
  "South Korea is the treated unit; remaining 37 countries serve as the donor pool. ",
  "Mean weekly hours from ILO ILOSTAT. All other variables from World Bank WDI. ",
  "GDP per capita in constant 2015 US dollars.\n",
  "\\end{minipage}\n\\end{table}"
)
writeLines(tab1_tex, file.path(table_dir, "table1_sumstats.tex"))

## ============================================================
## Table 2: Main SCM Results
## ============================================================

cat("\n=== Table 2: SCM Results ===\n")

scm_hours <- fread(file.path(data_dir, "scm_hours_results.csv"))
scm_tfr   <- fread(file.path(data_dir, "scm_tfr_results.csv"))

## Compute pre-treatment fit and post-treatment effects
scm_summary <- data.table(
  Outcome = c("Weekly hours", "Total fertility rate"),
  Pre_RMSPE = c(sqrt(mean(scm_hours[year < T0, gap^2])),
                sqrt(mean(scm_tfr[year < T0, gap^2]))),
  Gap_2018 = c(scm_hours[year == 2018, gap], scm_tfr[year == 2018, gap]),
  Gap_2019 = c(scm_hours[year == 2019, gap], scm_tfr[year == 2019, gap]),
  Gap_2023 = c(scm_hours[year == 2023, gap], scm_tfr[year == 2023, gap]),
  Avg_Post_Gap = c(mean(scm_hours[year >= T0, gap]),
                   mean(scm_tfr[year >= T0, gap]))
)
print(scm_summary)
fwrite(scm_summary, file.path(data_dir, "table2_scm_results.csv"))

tab2_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Synthetic Control Estimates: Effect of the 52-Hour Cap}\n",
  "\\label{tab:scm}\n",
  "\\begin{tabular}{lccccc}\n\\hline\\hline\n",
  " & Pre-RMSPE & \\multicolumn{3}{c}{Gap (Actual $-$ Synthetic)} & Avg.\\ Post \\\\\n",
  "\\cmidrule(lr){3-5}\n",
  " Outcome & & 2018 & 2019 & 2023 & Gap \\\\\n",
  "\\hline\n"
)
for (i in 1:nrow(scm_summary)) {
  tab2_tex <- paste0(tab2_tex, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
    scm_summary$Outcome[i], scm_summary$Pre_RMSPE[i],
    scm_summary$Gap_2018[i], scm_summary$Gap_2019[i],
    scm_summary$Gap_2023[i], scm_summary$Avg_Post_Gap[i]
  ))
}
tab2_tex <- paste0(tab2_tex,
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\footnotesize\\textit{Notes:} Synthetic control estimates using 37 OECD donor countries. ",
  "Pre-RMSPE is the root mean squared prediction error over 2005--2017. ",
  "Gap = actual Korea value minus synthetic Korea value. ",
  "Negative TFR gaps indicate Korea's fertility fell \\emph{more} than the synthetic control. ",
  "Hours SCM donors: Mexico (68\\%), Norway (17\\%), Iceland (15\\%). ",
  "TFR SCM donors: Japan (85\\%), Norway (15\\%).\n",
  "\\end{minipage}\n\\end{table}"
)
writeLines(tab2_tex, file.path(table_dir, "table2_scm.tex"))

## ============================================================
## Table 3: Cross-Country DiD Results
## ============================================================

cat("\n=== Table 3: Cross-Country DiD ===\n")

panel[, treated := as.integer(iso3 == "KOR")]
panel[, post := as.integer(year >= T0)]

## Multiple specifications
m1 <- feols(mean_weekly_hours ~ treated:post | iso3 + year,
            data = panel[!is.na(mean_weekly_hours) & year >= 2005],
            cluster = ~iso3)
m2 <- feols(tfr ~ treated:post | iso3 + year,
            data = panel[!is.na(tfr) & year >= 2005],
            cluster = ~iso3)
m3 <- feols(tfr ~ treated:post + gdp_pc + flfp + unemp | iso3 + year,
            data = panel[!is.na(tfr) & year >= 2005],
            cluster = ~iso3)
## Pre-COVID only
m4 <- feols(mean_weekly_hours ~ treated:post | iso3 + year,
            data = panel[!is.na(mean_weekly_hours) & year >= 2005 & year <= 2019],
            cluster = ~iso3)
m5 <- feols(tfr ~ treated:post | iso3 + year,
            data = panel[!is.na(tfr) & year >= 2005 & year <= 2019],
            cluster = ~iso3)

## Save as fixest etable
etable(m1, m2, m3, m4, m5,
       headers = c("Hours", "TFR", "TFR + Controls", "Hours (Pre-COVID)", "TFR (Pre-COVID)"),
       tex = TRUE,
       file = file.path(table_dir, "table3_did.tex"),
       title = "Cross-Country Difference-in-Differences: 52-Hour Cap Effects",
       label = "tab:did",
       notes = paste("Standard errors clustered at the country level in parentheses.",
                     "All specifications include country and year fixed effects.",
                     "Columns (4)-(5) restrict to 2005-2019 (pre-COVID window).",
                     "Source: World Bank WDI and ILO ILOSTAT."))

## Also save to CSV
did_results <- data.table(
  Specification = c("Hours", "TFR", "TFR + Controls",
                    "Hours (Pre-COVID)", "TFR (Pre-COVID)"),
  Coefficient = c(coef(m1), coef(m2), coef(m3)["treated:post"],
                  coef(m4), coef(m5)),
  SE = c(se(m1), se(m2), se(m3)["treated:post"],
         se(m4), se(m5)),
  P_value = c(pvalue(m1), pvalue(m2), pvalue(m3)["treated:post"],
              pvalue(m4), pvalue(m5)),
  N = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5))
)
print(did_results)
fwrite(did_results, file.path(data_dir, "table3_did_results.csv"))

## ============================================================
## Table 4: Industry-Level DiD
## ============================================================

cat("\n=== Table 4: Industry DiD ===\n")

kor_ind[, post := as.integer(year >= T0)]
median_hours <- kor_ind[, median(unique(baseline_hours), na.rm = TRUE)]
kor_ind[, high_overtime := as.integer(baseline_hours > median_hours)]

i1 <- feols(hours ~ treatment_intensity:post | industry + year,
            data = kor_ind[!is.na(hours)], cluster = ~industry)
i2 <- feols(hours ~ high_overtime:post | industry + year,
            data = kor_ind[!is.na(hours)], cluster = ~industry)

## Weighted by employment
i3 <- feols(hours ~ treatment_intensity:post | industry + year,
            data = kor_ind[!is.na(hours) & !is.na(emp_share)],
            cluster = ~industry,
            weights = kor_ind[!is.na(hours) & !is.na(emp_share)]$emp_share)

etable(i1, i2, i3,
       headers = c("Continuous", "Binary", "Emp-Weighted"),
       tex = TRUE,
       file = file.path(table_dir, "table4_industry.tex"),
       title = "Industry-Level First Stage: Hours Reduction by Baseline Overtime",
       label = "tab:industry",
       notes = paste("Standard errors clustered at the industry level.",
                     "Treatment intensity = max(baseline hours - 40, 0).",
                     "Binary: 1 if baseline hours above median.",
                     "Column (3) weighted by baseline employment share.",
                     "Source: ILO ILOSTAT."))

cat("\n=== ALL TABLES GENERATED ===\n")
