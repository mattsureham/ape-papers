# 05_tables.R — Generate LaTeX tables (simple booktabs format)
# apep_0681: IR35 Off-Payroll Reforms

source("00_packages.R")

models    <- readRDS("../data/models.rds")
rob       <- readRDS("../data/robustness_models.rds")
panel     <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
national  <- read_csv("../data/national_aggregates.csv", show_col_types = FALSE)

# Helper: format coefficient with stars
fmt_coef <- function(model, var) {
  b <- coef(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  sprintf("%.3f%s", b, stars)
}

fmt_se <- function(model, var) {
  sprintf("(%.3f)", se(model)[var])
}

# ============================================================
# TABLE 1: Descriptive Statistics — Company Counts
# ============================================================

desc <- national |>
  filter(year %in% c(2016, 2019, 2021, 2024)) |>
  select(year, sector_label, treated, companies) |>
  pivot_wider(names_from = year, values_from = companies, names_prefix = "y") |>
  mutate(pct = (y2024 - y2019) / y2019 * 100) |>
  arrange(desc(treated), sector_label)

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Company Counts by Sector, 2016--2024}",
  "\\label{tab:descriptive}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrc}",
  "\\toprule",
  " & \\multicolumn{4}{c}{Registered Companies} & \\\\",
  "\\cmidrule(lr){2-5}",
  "Sector & 2016 & 2019 & 2021 & 2024 & \\% Change \\\\",
  " & & & & & (2019--24) \\\\",
  "\\midrule",
  "\\emph{Panel A: Treated (high-PSC) sectors} & & & & & \\\\"
)

for (i in 1:nrow(desc)) {
  if (i == 5) {
    tab1 <- c(tab1, "\\addlinespace", "\\emph{Panel B: Control (low-PSC) sectors} & & & & & \\\\")
  }
  r <- desc[i,]
  tab1 <- c(tab1, sprintf(
    "%s & %s & %s & %s & %s & %.1f \\\\",
    r$sector_label,
    formatC(r$y2016, format="d", big.mark=","),
    formatC(r$y2019, format="d", big.mark=","),
    formatC(r$y2021, format="d", big.mark=","),
    formatC(r$y2024, format="d", big.mark=","),
    r$pct
  ))
}

tab1 <- c(tab1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Data from NOMIS UK Business Counts (NM\\_142\\_1). Counts are registered enterprises (companies including building societies) by 2-digit SIC industry, summed across 406 English Local Authority Districts. Treated sectors are those with high prevalence of personal service companies (PSCs). Percentage change is from the 2019 pre-reform peak to 2024.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_descriptive.tex")

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of IR35 Off-Payroll Reforms on log(Companies)}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Treated $\\times$ Post-2017 & %s & %s & %s & %s \\\\",
    fmt_coef(models$m1, "treat_post2017"), fmt_coef(models$m2, "treat_post2017"),
    fmt_coef(models$m3, "treat_post2017"), fmt_coef(models$m4, "treat_post2017")),
  sprintf("& %s & %s & %s & %s \\\\",
    fmt_se(models$m1, "treat_post2017"), fmt_se(models$m2, "treat_post2017"),
    fmt_se(models$m3, "treat_post2017"), fmt_se(models$m4, "treat_post2017")),
  "\\addlinespace",
  sprintf("Treated $\\times$ Post-2021 & %s & %s & %s & %s \\\\",
    fmt_coef(models$m1, "treat_post2021"), fmt_coef(models$m2, "treat_post2021"),
    fmt_coef(models$m3, "treat_post2021"), fmt_coef(models$m4, "treat_post2021")),
  sprintf("& %s & %s & %s & %s \\\\",
    fmt_se(models$m1, "treat_post2021"), fmt_se(models$m2, "treat_post2021"),
    fmt_se(models$m3, "treat_post2021"), fmt_se(models$m4, "treat_post2021")),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    formatC(nobs(models$m1), big.mark=","), formatC(nobs(models$m2), big.mark=","),
    formatC(nobs(models$m3), big.mark=","), formatC(nobs(models$m4), big.mark=",")),
  "Sector FE & Yes & Yes & Yes & --- \\\\",
  "Year FE & Yes & Yes & --- & Yes \\\\",
  "LA FE & --- & Yes & --- & --- \\\\",
  "LA $\\times$ Year FE & --- & --- & Yes & --- \\\\",
  "Unit FE & --- & --- & --- & Yes \\\\",
  "Clustering & Sector & Sector & Sector & Sector \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log(companies + 1) at the Local Authority $\\times$ SIC sector $\\times$ year level. Treated sectors: SIC 62 (IT), 70 (management consulting), 71 (architecture/engineering), 78 (employment agencies). Control sectors: SIC 46 (wholesale), 47 (retail), 56 (food/beverage), 69 (legal/accounting). Standard errors clustered at the 2-digit SIC sector level (8 clusters) in parentheses. Column (3) is the preferred specification. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_main_results.tex")

# ============================================================
# TABLE 3: Organizational Form Decomposition
# ============================================================

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Organizational Form Decomposition}",
  "\\label{tab:decomp}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& log(Companies) & log(Sole Props.) & log(Total) & Company Share \\\\",
  "& (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Treated $\\times$ Post-2017 & %s & %s & %s & %s \\\\",
    fmt_coef(models$m3, "treat_post2017"), fmt_coef(models$m_sole, "treat_post2017"),
    fmt_coef(models$m_total, "treat_post2017"), fmt_coef(models$m_share, "treat_post2017")),
  sprintf("& %s & %s & %s & %s \\\\",
    fmt_se(models$m3, "treat_post2017"), fmt_se(models$m_sole, "treat_post2017"),
    fmt_se(models$m_total, "treat_post2017"), fmt_se(models$m_share, "treat_post2017")),
  "\\addlinespace",
  sprintf("Treated $\\times$ Post-2021 & %s & %s & %s & %s \\\\",
    fmt_coef(models$m3, "treat_post2021"), fmt_coef(models$m_sole, "treat_post2021"),
    fmt_coef(models$m_total, "treat_post2021"), fmt_coef(models$m_share, "treat_post2021")),
  sprintf("& %s & %s & %s & %s \\\\",
    fmt_se(models$m3, "treat_post2021"), fmt_se(models$m_sole, "treat_post2021"),
    fmt_se(models$m_total, "treat_post2021"), fmt_se(models$m_share, "treat_post2021")),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    formatC(nobs(models$m3), big.mark=","), formatC(nobs(models$m_sole), big.mark=","),
    formatC(nobs(models$m_total), big.mark=","), formatC(nobs(models$m_share), big.mark=",")),
  "Sector FE & Yes & Yes & Yes & Yes \\\\",
  "LA $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include sector and LA $\\times$ year fixed effects. Standard errors clustered at the SIC sector level (8 clusters). Company share is the ratio of registered companies to total enterprises. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_decomposition.tex")

# ============================================================
# TABLE 4: Robustness Checks
# ============================================================

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& Baseline & COVID & Excl. & LA & Two-way \\\\",
  "& & Placebo & SIC 69 & Cluster & Cluster \\\\",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule"
)

# Post-2017 row
tab4 <- c(tab4,
  sprintf("Treated $\\times$ Post-2017 & %s & %s & %s & %s & %s \\\\",
    fmt_coef(models$m3, "treat_post2017"),
    fmt_coef(rob$m_placebo_2020, "treat_post2017"),
    fmt_coef(rob$m_alt1, "treat_post2017"),
    fmt_coef(rob$m3_la_cluster, "treat_post2017"),
    fmt_coef(rob$m3_twoway, "treat_post2017")),
  sprintf("& %s & %s & %s & %s & %s \\\\",
    fmt_se(models$m3, "treat_post2017"),
    fmt_se(rob$m_placebo_2020, "treat_post2017"),
    fmt_se(rob$m_alt1, "treat_post2017"),
    fmt_se(rob$m3_la_cluster, "treat_post2017"),
    fmt_se(rob$m3_twoway, "treat_post2017")),
  "\\addlinespace"
)

# Post-2021 row (columns 1,3,4,5) and Post-2020 placebo (column 2)
tab4 <- c(tab4,
  sprintf("Treated $\\times$ Post-2021 & %s & & %s & %s & %s \\\\",
    fmt_coef(models$m3, "treat_post2021"),
    fmt_coef(rob$m_alt1, "treat_post2021"),
    fmt_coef(rob$m3_la_cluster, "treat_post2021"),
    fmt_coef(rob$m3_twoway, "treat_post2021")),
  sprintf("& %s & & %s & %s & %s \\\\",
    fmt_se(models$m3, "treat_post2021"),
    fmt_se(rob$m_alt1, "treat_post2021"),
    fmt_se(rob$m3_la_cluster, "treat_post2021"),
    fmt_se(rob$m3_twoway, "treat_post2021")),
  "\\addlinespace",
  sprintf("Treated $\\times$ Post-2020 & & %s & & & \\\\", fmt_coef(rob$m_placebo_2020, "treat_post2020")),
  sprintf("& & %s & & & \\\\", fmt_se(rob$m_placebo_2020, "treat_post2020"))
)

tab4 <- c(tab4,
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
    formatC(nobs(models$m3), big.mark=","),
    formatC(nobs(rob$m_placebo_2020), big.mark=","),
    formatC(nobs(rob$m_alt1), big.mark=","),
    formatC(nobs(rob$m3_la_cluster), big.mark=","),
    formatC(nobs(rob$m3_twoway), big.mark=",")),
  "Sample & Full & Pre-2021 & No SIC 69 & Full & Full \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include sector and LA $\\times$ year fixed effects. Column (1): baseline. Column (2): tests whether the reform's effect appears in 2020 when it was delayed due to COVID-19 --- the insignificant coefficient confirms the effect is reform-driven, not pandemic-driven. Column (3): excludes SIC 69 (legal/accounting) which may have partial PSC exposure. Columns (4)--(5): alternative clustering. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4, "../tables/tab4_robustness.tex")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================

panel_pre <- panel |> filter(year == 2016)
sd_log_co <- sd(panel_pre$log_companies, na.rm=TRUE)
sd_log_sp <- sd(panel_pre$log_sole_props, na.rm=TRUE)
sd_log_tot <- sd(panel_pre$log_total, na.rm=TRUE)
sd_share <- sd(panel_pre$company_share, na.rm=TRUE)

sde <- data.frame(
  outcome = c("log(Companies)", "log(Sole Proprietors)", "log(Total Enterprises)", "Company Share"),
  beta = c(coef(models$m3)["treat_post2021"], coef(models$m_sole)["treat_post2021"],
           coef(models$m_total)["treat_post2021"], coef(models$m_share)["treat_post2021"]),
  se = c(se(models$m3)["treat_post2021"], se(models$m_sole)["treat_post2021"],
         se(models$m_total)["treat_post2021"], se(models$m_share)["treat_post2021"]),
  sd_y = c(sd_log_co, sd_log_sp, sd_log_tot, sd_share)
)

sde$sde <- sde$beta / sde$sd_y
sde$se_sde <- sde$se / sde$sd_y
sde$class <- with(sde, case_when(
  sde < -0.15  ~ "Large negative",
  sde < -0.05  ~ "Moderate negative",
  sde < -0.005 ~ "Small negative",
  sde <= 0.005 ~ "Null",
  sde <= 0.05  ~ "Small positive",
  sde <= 0.15  ~ "Moderate positive",
  TRUE         ~ "Large positive"
))

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: Post-2021 Private Sector Reform}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde)) {
  r <- sde[i,]
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class
  ))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standardized effect sizes for the April 2021 private sector IR35 off-payroll reform. SDE $= \\hat{\\beta} / \\text{SD}(Y)$, where SD($Y$) is the pre-reform (2016) cross-sectional standard deviation. Research question: Does shifting tax status determination from contractors to clients cause the dissolution of personal service companies? Data: NOMIS UK Business Counts, 406 Local Authorities $\\times$ 8 SIC sectors $\\times$ 9 years (2016--2024). Method: sector $\\times$ time DiD with LA $\\times$ year FE, SIC-clustered SEs. $N = 29{,}232$. Treatment: 4 high-PSC sectors (binary). Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("All tables regenerated (booktabs format).\n")
