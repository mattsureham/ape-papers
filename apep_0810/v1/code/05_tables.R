## 05_tables.R — Generate all tables for paper
## apep_0810: Florida Liquor License Lottery and Business Formation

source("00_packages.R")
data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE)

panel_7224 <- readRDS(file.path(data_dir, "panel_7224.rds"))
panel_7225 <- readRDS(file.path(data_dir, "panel_7225.rds"))
stacked <- readRDS(file.path(data_dir, "stacked_panel.rds"))
treatment_annual <- readRDS(file.path(data_dir, "treatment_annual.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("Generating Table 1: Summary Statistics...\n")

# Panel A: Treatment variable
treat_stats <- treatment_annual %>%
  filter(year >= 2012) %>%
  summarise(
    `New licenses (county-year)` = sprintf("%.2f", mean(new_licenses)),
    `SD new licenses` = sprintf("%.2f", sd(new_licenses)),
    `Share with any new license` = sprintf("%.2f", mean(new_licenses > 0)),
    `Cumulative licenses (mean)` = sprintf("%.1f", mean(cum_new_licenses)),
    `Population (mean)` = sprintf("%.0f", mean(population)),
    `Expected licenses (mean)` = sprintf("%.1f", mean(expected_licenses))
  )

# Panel B: Drinking places (7224)
drink_stats <- panel_7224 %>%
  summarise(
    `Employment` = sprintf("%.0f", mean(Emp, na.rm = TRUE)),
    `SD employment` = sprintf("%.0f", sd(Emp, na.rm = TRUE)),
    `Emp per 10K pop` = sprintf("%.1f", mean(emp_rate, na.rm = TRUE)),
    `Earnings per worker` = sprintf("$%.0f", mean(earn_per_worker, na.rm = TRUE)),
    `Counties` = as.character(n_distinct(county_fips)),
    `County-quarters` = as.character(n())
  )

# Panel C: Restaurants (7225)
rest_stats <- panel_7225 %>%
  summarise(
    `Employment` = sprintf("%.0f", mean(Emp, na.rm = TRUE)),
    `SD employment` = sprintf("%.0f", sd(Emp, na.rm = TRUE)),
    `Emp per 10K pop` = sprintf("%.1f", mean(emp_rate, na.rm = TRUE)),
    `Earnings per worker` = sprintf("$%.0f", mean(earn_per_worker, na.rm = TRUE)),
    `Counties` = as.character(n_distinct(county_fips)),
    `County-quarters` = as.character(n())
  )

# Write LaTeX
tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "& Mean & SD \\\\",
  "\\hline",
  "\\multicolumn{3}{l}{\\textit{Panel A: Treatment (county-year, 2012--2023)}} \\\\[3pt]",
  sprintf("New quota licenses & %s & %s \\\\", mean(treatment_annual$new_licenses[treatment_annual$year >= 2012]),
          sprintf("%.2f", sd(treatment_annual$new_licenses[treatment_annual$year >= 2012]))),
  sprintf("Share of counties receiving license & \\multicolumn{2}{c}{%.1f\\%%} \\\\",
          mean(treatment_annual$new_licenses[treatment_annual$year >= 2012] > 0) * 100),
  sprintf("Population & %s & %s \\\\",
          format(round(mean(treatment_annual$population[treatment_annual$year >= 2012])), big.mark = ","),
          format(round(sd(treatment_annual$population[treatment_annual$year >= 2012])), big.mark = ",")),
  sprintf("Expected licenses (pop/7,500) & %.1f & %.1f \\\\",
          mean(treatment_annual$expected_licenses[treatment_annual$year >= 2012]),
          sd(treatment_annual$expected_licenses[treatment_annual$year >= 2012])),
  "[6pt]",
  "\\multicolumn{3}{l}{\\textit{Panel B: Drinking places (NAICS 7224, county-quarter)}} \\\\[3pt]",
  sprintf("Employment & %.0f & %.0f \\\\", mean(panel_7224$Emp, na.rm = TRUE), sd(panel_7224$Emp, na.rm = TRUE)),
  sprintf("Employment per 10,000 pop & %.1f & %.1f \\\\",
          mean(panel_7224$emp_rate, na.rm = TRUE), sd(panel_7224$emp_rate, na.rm = TRUE)),
  sprintf("Earnings per worker (\\$) & %.0f & %.0f \\\\",
          mean(panel_7224$earn_per_worker, na.rm = TRUE), sd(panel_7224$earn_per_worker, na.rm = TRUE)),
  sprintf("Counties & \\multicolumn{2}{c}{%d} \\\\", n_distinct(panel_7224$county_fips)),
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(nrow(panel_7224), big.mark = ",")),
  "[6pt]",
  "\\multicolumn{3}{l}{\\textit{Panel C: Restaurants (NAICS 7225, county-quarter)}} \\\\[3pt]",
  sprintf("Employment & %s & %s \\\\",
          format(round(mean(panel_7225$Emp, na.rm = TRUE)), big.mark = ","),
          format(round(sd(panel_7225$Emp, na.rm = TRUE)), big.mark = ",")),
  sprintf("Employment per 10,000 pop & %.1f & %.1f \\\\",
          mean(panel_7225$emp_rate, na.rm = TRUE), sd(panel_7225$emp_rate, na.rm = TRUE)),
  sprintf("Earnings per worker (\\$) & %.0f & %.0f \\\\",
          mean(panel_7225$earn_per_worker, na.rm = TRUE), sd(panel_7225$earn_per_worker, na.rm = TRUE)),
  sprintf("Counties & \\multicolumn{2}{c}{%d} \\\\", n_distinct(panel_7225$county_fips)),
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(nrow(panel_7225), big.mark = ",")),
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.85\\textwidth}}{\\footnotesize\\textit{Notes:} QWI data from Census Bureau for Florida counties, 2012--2023. Treatment derived from Florida Statutes \\S561.19: one quota liquor license per 7,500 county residents. Panel A statistics computed at the county-year level ($N = 804$). Panels B and C at county-quarter level. Drinking places (NAICS 7224) require quota licenses; restaurants (NAICS 7225) do not.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Main Results
# ============================================================

cat("Generating Table 2: Main Results...\n")

# Re-estimate for clean table output
m_flow <- feols(log_emp ~ new_licenses | county_fips + time_id,
                data = panel_7224, cluster = ~county_fips)
m_flow_pop <- feols(log_emp ~ new_licenses + log_pop | county_fips + time_id,
                    data = panel_7224, cluster = ~county_fips)
m_cum <- feols(log_emp ~ cum_new_licenses | county_fips + time_id,
               data = panel_7224, cluster = ~county_fips)
m_cum_pop <- feols(log_emp ~ cum_new_licenses + log_pop | county_fips + time_id,
                   data = panel_7224, cluster = ~county_fips)
m_level <- feols(Emp ~ new_licenses | county_fips + time_id,
                 data = panel_7224, cluster = ~county_fips)

coef_flow <- coeftable(m_flow)
coef_flow_pop <- coeftable(m_flow_pop)
coef_cum <- coeftable(m_cum)
coef_cum_pop <- coeftable(m_cum_pop)
coef_level <- coeftable(m_level)

stars <- function(p) {
  if (p < 0.001) return("^{***}")
  if (p < 0.01) return("^{**}")
  if (p < 0.05) return("^{*}")
  if (p < 0.1) return("^{\\dagger}")
  return("")
}

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of New Quota Licenses on Drinking-Place Employment}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& \\multicolumn{2}{c}{Flow (current year)} & \\multicolumn{2}{c}{Cumulative} & Level \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-6}",
  "& log(Emp) & log(Emp) & log(Emp) & log(Emp) & Emp \\\\",
  "\\hline",
  sprintf("New licenses & %.4f%s & %.4f%s & & & %.1f%s \\\\",
          coef_flow[1,1], stars(coef_flow[1,4]),
          coef_flow_pop[1,1], stars(coef_flow_pop[1,4]),
          coef_level[1,1], stars(coef_level[1,4])),
  sprintf("& (%.4f) & (%.4f) & & & (%.1f) \\\\",
          coef_flow[1,2], coef_flow_pop[1,2], coef_level[1,2]),
  sprintf("Cumulative licenses & & & %.4f%s & %.4f%s & \\\\",
          coef_cum[1,1], stars(coef_cum[1,4]),
          coef_cum_pop[1,1], stars(coef_cum_pop[1,4])),
  sprintf("& & & (%.4f) & (%.4f) & \\\\",
          coef_cum[1,2], coef_cum_pop[1,2]),
  "Log population & & Yes & & Yes & \\\\",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(m_flow$nobs, big.mark = ","),
          format(m_flow_pop$nobs, big.mark = ","),
          format(m_cum$nobs, big.mark = ","),
          format(m_cum_pop$nobs, big.mark = ","),
          format(m_level$nobs, big.mark = ",")),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(m_flow, "wr2")[[1]],
          fitstat(m_flow_pop, "wr2")[[1]],
          fitstat(m_cum, "wr2")[[1]],
          fitstat(m_cum_pop, "wr2")[[1]],
          fitstat(m_level, "wr2")[[1]]),
  "\\hline\\hline",
  "\\multicolumn{6}{p{0.95\\textwidth}}{\\footnotesize\\textit{Notes:} The dependent variable is log employment (columns 1--4) or employment level (column 5) in drinking places (NAICS 7224) for Florida counties, 2012--2023. ``New licenses'' is the number of quota licenses allocated to the county in the current year via Florida's annual Quota Drawing. ``Cumulative licenses'' is the running total. All specifications include county and year-quarter fixed effects. Standard errors clustered at the county level in parentheses. $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$, $^{\\dagger}p<0.10$.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2, file.path(table_dir, "tab2_main.tex"))

# ============================================================
# TABLE 3: Placebo and Robustness
# ============================================================

cat("Generating Table 3: Placebo and Robustness...\n")

# Placebo
m_placebo <- feols(log_emp ~ new_licenses | county_fips + time_id,
                   data = panel_7225, cluster = ~county_fips)

# Triple-diff
m_ddd <- feols(log_emp ~ cum_treat_x_drinking + cum_new_licenses |
                 county_fips^sector + time_id^sector,
               data = stacked, cluster = ~county_fips)

# No COVID
m_nocovid <- robust$r1_nocovid

# Lagged
m_lag <- robust$r2_lag_flow

# Dose-response
panel_dose <- panel_7224 %>%
  mutate(dose_1 = as.integer(new_licenses == 1),
         dose_2plus = as.integer(new_licenses >= 2))
m_dose <- feols(log_emp ~ dose_1 + dose_2plus | county_fips + time_id,
                data = panel_dose, cluster = ~county_fips)

cp <- coeftable(m_placebo)
cd <- coeftable(m_ddd)
cnc <- coeftable(m_nocovid)
cl <- coeftable(m_lag)
cdose <- coeftable(m_dose)

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Placebo, Robustness, and Dose-Response}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& Placebo & Triple-diff & No COVID & Lagged & Dose \\\\",
  "& Restaurants & DDD & 2012--19, & $t-1$ & response \\\\",
  "& (7225) & & 2022--23 & licenses & \\\\",
  "\\hline",
  sprintf("New licenses & %.4f%s & & %.4f%s & & \\\\",
          cp[1,1], stars(cp[1,4]),
          cnc[1,1], stars(cnc[1,4])),
  sprintf("& (%.4f) & & (%.4f) & & \\\\",
          cp[1,2], cnc[1,2]),
  sprintf("Cum.\\ licenses $\\times$ Drinking & & %.4f%s & & & \\\\",
          cd[1,1], stars(cd[1,4])),
  sprintf("& & (%.4f) & & & \\\\", cd[1,2]),
  sprintf("Lagged new licenses & & & & %.4f%s & \\\\",
          cl[1,1], stars(cl[1,4])),
  sprintf("& & & & (%.4f) & \\\\", cl[1,2]),
  sprintf("1 license & & & & & %.4f%s \\\\",
          cdose[1,1], stars(cdose[1,4])),
  sprintf("& & & & & (%.4f) \\\\", cdose[1,2]),
  sprintf("2+ licenses & & & & & %.4f%s \\\\",
          cdose[2,1], stars(cdose[2,4])),
  sprintf("& & & & & (%.4f) \\\\", cdose[2,2]),
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(m_placebo$nobs, big.mark = ","),
          format(m_ddd$nobs, big.mark = ","),
          format(m_nocovid$nobs, big.mark = ","),
          format(m_lag$nobs, big.mark = ","),
          format(m_dose$nobs, big.mark = ",")),
  "\\hline\\hline",
  "\\multicolumn{6}{p{0.95\\textwidth}}{\\footnotesize\\textit{Notes:} Column 1: placebo test using restaurants (NAICS 7225), which do not require quota licenses. Column 2: triple-difference with county$\\times$sector and quarter$\\times$sector fixed effects; coefficient is the interaction of cumulative licenses with the drinking-place indicator. Column 3: excludes COVID period (2020--2021). Column 4: uses lagged (prior-year) license allocations. Column 5: dose-response separating counties receiving exactly one versus two or more licenses. All standard errors clustered at the county level. $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$, $^{\\dagger}p<0.10$.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3, file.path(table_dir, "tab3_robust.tex"))

# ============================================================
# TABLE 4: Event Study Coefficients
# ============================================================

cat("Generating Table 4: Event Study...\n")

es_coefs <- coeftable(results$m5_event)
es_years <- as.integer(gsub("event_year_binned::", "", rownames(es_coefs)))

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Log Employment Around First License Allocation}",
  "\\label{tab:event}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Years relative to & Coefficient & Std. Error & $p$-value \\\\",
  "first allocation & & & \\\\",
  "\\hline"
)

for (i in seq_along(es_years)) {
  yr <- es_years[i]
  if (yr == -1) next  # Reference year
  label <- ifelse(yr <= -4, "$\\leq -4$",
           ifelse(yr >= 6, "$\\geq 6$", as.character(yr)))
  tab4 <- c(tab4, sprintf("%s & %.4f%s & (%.4f) & [%.3f] \\\\",
                           label, es_coefs[i,1], stars(es_coefs[i,4]),
                           es_coefs[i,2], es_coefs[i,4]))
}

tab4 <- c(tab4,
  "$-1$ (reference) & 0 & --- & --- \\\\",
  "\\hline",
  sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\", format(results$m5_event$nobs, big.mark = ",")),
  "County FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Quarter FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\hline\\hline",
  "\\multicolumn{4}{p{0.8\\textwidth}}{\\footnotesize\\textit{Notes:} Event study around first quota license allocation for each county. Dependent variable is log employment in drinking places (NAICS 7224). Endpoints binned at $\\leq -4$ and $\\geq 6$ years. Year $-1$ is the reference period. Standard errors clustered at the county level. $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$, $^{\\dagger}p<0.10$.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4, file.path(table_dir, "tab4_event.tex"))

# ============================================================
# SDE TABLE (Appendix, MANDATORY)
# ============================================================

cat("Generating SDE table...\n")

# Get pre-treatment SD of outcomes
pre_sd_log_emp <- panel_7224 %>%
  filter(year < 2015) %>%  # Pre-treatment period (before most allocations)
  pull(log_emp) %>%
  sd(na.rm = TRUE)

pre_sd_emp <- panel_7224 %>%
  filter(year < 2015) %>%
  pull(Emp) %>%
  sd(na.rm = TRUE)

pre_sd_earn <- panel_7224 %>%
  filter(year < 2015) %>%
  pull(earn_per_worker) %>%
  sd(na.rm = TRUE)

# Main outcomes for SDE
# 1. Flow effect on log employment
beta_flow <- coef(m_flow)["new_licenses"]
se_flow <- coeftable(m_flow)["new_licenses", 2]
sde_flow <- beta_flow / pre_sd_log_emp
se_sde_flow <- se_flow / pre_sd_log_emp

# 2. Level effect on employment
beta_level <- coef(m_level)["new_licenses"]
se_level <- coeftable(m_level)["new_licenses", 2]
sde_level <- beta_level / pre_sd_emp
se_sde_level <- se_level / pre_sd_emp

# 3. Cumulative effect on log employment
beta_cum <- coef(m_cum)["cum_new_licenses"]
se_cum <- coeftable(m_cum)["cum_new_licenses", 2]
sde_cum <- beta_cum / pre_sd_log_emp
se_sde_cum <- se_cum / pre_sd_log_emp

# 4. Earnings per worker
m_earn <- feols(earn_per_worker ~ new_licenses | county_fips + time_id,
                data = panel_7224 %>% filter(!is.na(earn_per_worker)),
                cluster = ~county_fips)
beta_earn <- coef(m_earn)["new_licenses"]
se_earn <- coeftable(m_earn)["new_licenses", 2]
sde_earn <- beta_earn / pre_sd_earn
se_sde_earn <- se_earn / pre_sd_earn

classify <- function(sde) {
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

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States (Florida). ",
  "\\textbf{Research question:} Does expanding the supply of quota liquor licenses through Florida's annual random drawing increase employment in drinking places? ",
  "\\textbf{Policy mechanism:} Florida Statutes \\S561.19 limits quota alcoholic beverage licenses to one per 7,500 county residents and distributes new licenses exclusively through an annual random drawing; new licenses become available when county population growth crosses a 7,500-person threshold, relaxing the binding supply constraint on entry into the on-premises alcohol service sector. ",
  "\\textbf{Outcome definition:} Quarterly county-level employment and earnings in NAICS 7224 (Drinking Places) from the Census Bureau's Quarterly Workforce Indicators. ",
  "\\textbf{Treatment:} Binary at the county-year level: whether a county received one or more new quota licenses via the annual drawing (flow specification). ",
  "\\textbf{Data:} Census QWI (2012--2023), 63 Florida counties with NAICS 7224 data, county-quarter panel ($N = 2{,}297$). Treatment constructed from the statutory population threshold rule and validated against DBPR winner records. ",
  "\\textbf{Method:} Two-way fixed effects (county + year-quarter) with standard errors clustered at the county level. Placebo: restaurants (NAICS 7225). Dose-response: 1 vs.\\ 2+ licenses. ",
  "\\textbf{Sample:} Florida counties with nonzero drinking-place employment; 40 counties receive at least one new license during the sample period. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2012--2014) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sprintf("Log employment (flow) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_flow, se_flow, pre_sd_log_emp, sde_flow, se_sde_flow, classify(sde_flow)),
  sprintf("Employment level (flow) & %.1f & %.1f & %.1f & %.4f & %.4f & %s \\\\",
          beta_level, se_level, pre_sd_emp, sde_level, se_sde_level, classify(sde_level)),
  sprintf("Log employment (cumulative) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_cum, se_cum, pre_sd_log_emp, sde_cum, se_sde_cum, classify(sde_cum)),
  sprintf("Earnings per worker (flow) & %.2f & %.2f & %.2f & %.4f & %.4f & %s \\\\",
          beta_earn, se_earn, pre_sd_earn, sde_earn, se_sde_earn, classify(sde_earn)),
  "\\hline\\hline",
  sprintf("\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\begin{itemize}[leftmargin=*,nosep] %s \\end{itemize}}", sde_notes),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(sde_tab, file.path(table_dir, "tabF1_sde.tex"))

cat("All tables generated.\n")
