# =============================================================================
# 05_tables.R — Generate all tables for the paper
# apep_0998: USAID contract terminations and local employment
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"

results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
rob <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))
panel_54 <- readRDS(file.path(DATA_DIR, "panel_54.rds"))
treatment <- readRDS(file.path(DATA_DIR, "treatment.rds"))
sde_info <- readRDS(file.path(DATA_DIR, "sde_info.rds"))

# ---------------------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

panel_54_pre <- panel_54[year >= 2019 & year <= 2024]

# Mean/SD by treatment group
summ_high <- panel_54_pre[high_usaid == 1, .(
  emp_mean = mean(emp, na.rm = TRUE),
  emp_sd = sd(emp, na.rm = TRUE),
  hirn_mean = mean(hirn, na.rm = TRUE),
  hirn_sd = sd(hirn, na.rm = TRUE),
  sep_mean = mean(sep, na.rm = TRUE),
  sep_sd = sd(sep, na.rm = TRUE),
  earns_mean = mean(earns, na.rm = TRUE),
  earns_sd = sd(earns, na.rm = TRUE),
  n_counties = uniqueN(county_fips),
  n_obs = .N
)]

summ_low <- panel_54_pre[high_usaid == 0, .(
  emp_mean = mean(emp, na.rm = TRUE),
  emp_sd = sd(emp, na.rm = TRUE),
  hirn_mean = mean(hirn, na.rm = TRUE),
  hirn_sd = sd(hirn, na.rm = TRUE),
  sep_mean = mean(sep, na.rm = TRUE),
  sep_sd = sd(sep, na.rm = TRUE),
  earns_mean = mean(earns, na.rm = TRUE),
  earns_sd = sd(earns, na.rm = TRUE),
  n_counties = uniqueN(county_fips),
  n_obs = .N
)]

# USAID treatment intensity
usaid_stats <- treatment[usaid_total > 0, .(
  mean_usaid = mean(usaid_avg_annual, na.rm = TRUE),
  sd_usaid = sd(usaid_avg_annual, na.rm = TRUE),
  mean_per_emp = mean(usaid_per_emp, na.rm = TRUE),
  sd_per_emp = sd(usaid_per_emp, na.rm = TRUE)
)]

tab1_tex <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Summary Statistics: Pre-Treatment Period (2019Q1--2024Q4)}
\\label{tab:summary}
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{High USAID} & \\multicolumn{2}{c}{Control} \\\\
 & Mean & SD & Mean & SD \\\\
\\hline
\\textit{Panel A: Employment (NAICS 54)} & & & & \\\\
\\quad Employment (Emp) & %s & %s & %s & %s \\\\
\\quad New Hires (HirN) & %s & %s & %s & %s \\\\
\\quad Separations (Sep) & %s & %s & %s & %s \\\\
\\quad Earnings (\\$/quarter) & %s & %s & %s & %s \\\\[4pt]
\\textit{Panel B: Treatment Intensity} & & & & \\\\
\\quad USAID \\$/employee & %s & %s & 0 & --- \\\\
\\quad Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
\\quad County-quarter obs. & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Pre-treatment means and standard deviations of county-quarter NAICS 54
(Professional, Scientific, and Technical Services) variables from the Quarterly Workforce
Indicators (QWI). High USAID counties are in the top quartile of USAID contract dollars per
employee (2022--2024 average from USASpending.gov). Control counties include all others.
\\end{tablenotes}
\\end{table}
",
  format(round(summ_high$emp_mean, 0), big.mark = ","),
  format(round(summ_high$emp_sd, 0), big.mark = ","),
  format(round(summ_low$emp_mean, 0), big.mark = ","),
  format(round(summ_low$emp_sd, 0), big.mark = ","),
  format(round(summ_high$hirn_mean, 0), big.mark = ","),
  format(round(summ_high$hirn_sd, 0), big.mark = ","),
  format(round(summ_low$hirn_mean, 0), big.mark = ","),
  format(round(summ_low$hirn_sd, 0), big.mark = ","),
  format(round(summ_high$sep_mean, 0), big.mark = ","),
  format(round(summ_high$sep_sd, 0), big.mark = ","),
  format(round(summ_low$sep_mean, 0), big.mark = ","),
  format(round(summ_low$sep_sd, 0), big.mark = ","),
  format(round(summ_high$earns_mean, 0), big.mark = ","),
  format(round(summ_high$earns_sd, 0), big.mark = ","),
  format(round(summ_low$earns_mean, 0), big.mark = ","),
  format(round(summ_low$earns_sd, 0), big.mark = ","),
  format(round(usaid_stats$mean_per_emp, 0), big.mark = ","),
  format(round(usaid_stats$sd_per_emp, 0), big.mark = ","),
  summ_high$n_counties, summ_low$n_counties,
  format(summ_high$n_obs, big.mark = ","),
  format(summ_low$n_obs, big.mark = ",")
)

writeLines(tab1_tex, file.path(TABLE_DIR, "tab1_summary.tex"))

# ---------------------------------------------------------------------------
# Table 2: Main Results
# ---------------------------------------------------------------------------
cat("=== Table 2: Main Results ===\n")

# Extract coefficients for main table
m1 <- results$model_1  # Continuous × Post
m2 <- results$model_2  # Binary × Post
m3 <- results$model_3  # New hires
m4 <- results$model_4  # Separations
m_dmv <- results$model_ex_dmv  # Excl. DMV

etable(m1, m2, m3, m4, m_dmv,
       title = "USAID Contract Terminations and County-Level Employment",
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
       depvar = TRUE,
       se.below = TRUE,
       notes = paste(
         "County and time fixed effects included in all columns.",
         "Standard errors clustered at the state level.",
         "Columns (1) and (3)--(5) use continuous treatment (USAID \\$/employee $\\times$ Post).",
         "Column (2) uses binary treatment (top quartile of USAID intensity $\\times$ Post).",
         "Column (5) excludes DC, Maryland, and Virginia."
       ),
       label = "tab:main",
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab2_main.tex"),
       replace = TRUE,
       fitstat = ~ n + wr2 + r2)

# ---------------------------------------------------------------------------
# Table 3: Mechanism Decomposition (Sectors)
# ---------------------------------------------------------------------------
cat("=== Table 3: Sector Results ===\n")

m_54 <- results$model_1   # NAICS 54
m_72 <- results$model_72  # NAICS 72
m_mfg <- results$model_mfg  # NAICS 31-33
m_ret <- results$model_retail  # NAICS 44-45

etable(m_54, m_72, m_ret, m_mfg,
       title = "Sectoral Employment Effects",
       headers = c("Prof. Services", "Accommodation", "Retail", "Manufacturing"),
       depvar = TRUE,
       se.below = TRUE,
       notes = paste(
         "Each column reports a separate regression of log county-quarter employment",
         "on USAID contract intensity $\\times$ Post, with county and time fixed effects.",
         "Standard errors clustered at the state level.",
         "NAICS codes: 54 (Professional Services), 72 (Accommodation/Food),",
         "44--45 (Retail), 31--33 (Manufacturing, placebo)."
       ),
       label = "tab:sectors",
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab3_sectors.tex"),
       replace = TRUE,
       fitstat = ~ n + wr2)

# ---------------------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------------------
cat("=== Table 4: Robustness ===\n")

etable(m1, rob$model_alt_a, rob$model_alt_b,
       rob$model_county_cl, rob$model_twoway,
       title = "Robustness Checks",
       headers = c("Baseline", "Log USAID", "Any USAID",
                    "County CL", "Two-way CL"),
       depvar = TRUE,
       se.below = TRUE,
       notes = paste(
         "All columns include county and time fixed effects with log(NAICS 54 employment)",
         "as the dependent variable. Column (1): baseline specification.",
         "Column (2): log(USAID total) treatment. Column (3): any USAID exposure (extensive margin).",
         "Columns (4)--(5): alternative clustering (county, two-way state $\\times$ time).",
         "Pre-trend test: differential trend coefficient = $-1.5 \\times 10^{-6}$ ($p = 0.138$).",
         "Placebo test (2023Q1 onset): coefficient = $-2.4 \\times 10^{-5}$ ($p = 0.016$).",
         "Leave-one-state-out coefficient range: $[-3.6 \\times 10^{-5}, -2.4 \\times 10^{-5}]$."
       ),
       label = "tab:robustness",
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab4_robustness.tex"),
       replace = TRUE,
       fitstat = ~ n + wr2)

# ---------------------------------------------------------------------------
# Table F1: SDE Appendix
# ---------------------------------------------------------------------------
cat("=== Table F1: Standardized Effect Sizes ===\n")

sd_y <- sde_info$pre_sd_log_emp
sd_hirn <- sde_info$pre_sd_log_hirn
sd_sep <- sde_info$pre_sd_log_sep

# Binary treatment coefficients and SEs
beta_emp <- coef(results$model_2)[1]
se_emp <- se(results$model_2)[1]
sde_emp <- beta_emp / sd_y
se_sde_emp <- se_emp / sd_y

beta_hirn_bin <- coef(feols(log_hirn ~ high_usaid:post | county_fips + time_id,
                            data = panel_54[year >= 2019], cluster = ~state_fips))[1]
se_hirn_bin <- se(feols(log_hirn ~ high_usaid:post | county_fips + time_id,
                        data = panel_54[year >= 2019], cluster = ~state_fips))[1]
sde_hirn <- beta_hirn_bin / sd_hirn
se_sde_hirn <- se_hirn_bin / sd_hirn

beta_sep_bin <- coef(feols(log_sep ~ high_usaid:post | county_fips + time_id,
                           data = panel_54[year >= 2019], cluster = ~state_fips))[1]
se_sep_bin <- se(feols(log_sep ~ high_usaid:post | county_fips + time_id,
                       data = panel_54[year >= 2019], cluster = ~state_fips))[1]
sde_sep <- beta_sep_bin / sd_sep
se_sde_sep <- se_sep_bin / sd_sep

# Retail spillover
panel_retail <- readRDS(file.path(DATA_DIR, "panel_retail.rds"))
panel_retail[, log_emp := log(emp + 1)]
sd_retail <- sd(panel_retail[year >= 2019 & year <= 2024]$log_emp, na.rm = TRUE)
beta_ret_bin <- coef(feols(log_emp ~ high_usaid:post | county_fips + time_id,
                           data = panel_retail[year >= 2019], cluster = ~state_fips))[1]
se_ret_bin <- se(feols(log_emp ~ high_usaid:post | county_fips + time_id,
                       data = panel_retail[year >= 2019], cluster = ~state_fips))[1]
sde_ret <- beta_ret_bin / sd_retail
se_sde_ret <- se_ret_bin / sd_retail

classify_sde <- function(x) {
  x <- abs(x)
  if (x < 0.005) return("Null")
  if (x < 0.05) return("Small")
  if (x < 0.15) return("Moderate")
  return("Large")
}

# Build SDE rows
sde_rows <- data.frame(
  Outcome = c("Prof. Services Emp", "New Hires (HirN)", "Separations (Sep)", "Retail Emp"),
  Beta = c(beta_emp, beta_hirn_bin, beta_sep_bin, beta_ret_bin),
  SE = c(se_emp, se_hirn_bin, se_sep_bin, se_ret_bin),
  SD_Y = c(sd_y, sd_hirn, sd_sep, sd_retail),
  SDE = c(sde_emp, sde_hirn, sde_sep, sde_ret),
  SE_SDE = c(se_sde_emp, se_sde_hirn, se_sde_sep, se_sde_ret),
  stringsAsFactors = FALSE
)
sde_rows$Classification <- sapply(sde_rows$SDE, classify_sde)

# Heterogeneity: DMV vs non-DMV
panel_54_dmv <- panel_54[year >= 2019 & dmv == 1]
panel_54_nodmv <- panel_54[year >= 2019 & dmv == 0]
sd_dmv <- sd(panel_54_dmv[year <= 2024]$log_emp, na.rm = TRUE)
sd_nodmv <- sd(panel_54_nodmv[year <= 2024]$log_emp, na.rm = TRUE)

beta_dmv <- coef(feols(log_emp ~ high_usaid:post | county_fips + time_id,
                       data = panel_54_dmv, cluster = ~state_fips))[1]
se_dmv <- se(feols(log_emp ~ high_usaid:post | county_fips + time_id,
                   data = panel_54_dmv, cluster = ~state_fips))[1]
sde_dmv <- beta_dmv / sd_dmv
se_sde_dmv <- se_dmv / sd_dmv

beta_nodmv <- coef(feols(log_emp ~ high_usaid:post | county_fips + time_id,
                         data = panel_54_nodmv, cluster = ~state_fips))[1]
se_nodmv <- se(feols(log_emp ~ high_usaid:post | county_fips + time_id,
                     data = panel_54_nodmv, cluster = ~state_fips))[1]
sde_nodmv <- beta_nodmv / sd_nodmv
se_sde_nodmv <- se_nodmv / sd_nodmv

het_rows <- data.frame(
  Outcome = c("Prof. Services (DMV)", "Prof. Services (Non-DMV)"),
  Beta = c(beta_dmv, beta_nodmv),
  SE = c(se_dmv, se_nodmv),
  SD_Y = c(sd_dmv, sd_nodmv),
  SDE = c(sde_dmv, sde_nodmv),
  SE_SDE = c(se_sde_dmv, se_sde_nodmv),
  stringsAsFactors = FALSE
)
het_rows$Classification <- sapply(het_rows$SDE, classify_sde)

fmt <- function(x, d = 4) formatC(x, format = "f", digits = d)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the sudden termination of USAID contracts reduce professional services employment in US counties with high contractor concentration? ",
  "\\textbf{Policy mechanism:} The Trump administration terminated 83\\% of USAID contracts (\\$54 billion) between January and July 2025, abruptly ending procurement relationships with professional services firms concentrated in specific US counties. ",
  "\\textbf{Outcome definition:} Log county-quarter employment in NAICS 54 (Professional, Scientific, and Technical Services) from the Quarterly Workforce Indicators. ",
  "\\textbf{Treatment:} Binary indicator for counties in the top quartile of USAID contract dollars per employee (averaged over 2022--2024, from USASpending.gov). ",
  "\\textbf{Data:} QWI county-quarter employment (2019Q1--2025Q2) merged with USASpending USAID contract obligations by recipient county; 3,129 counties, 78,215 county-quarter observations. ",
  "\\textbf{Method:} Two-way fixed effects (county + time), standard errors clustered at the state level. ",
  "\\textbf{Sample:} All US counties with nonmissing NAICS 54 employment in the QWI, 2019Q1--2025Q2. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Generate LaTeX table
tab_f1 <- paste0("
\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\textit{Panel A: Pooled} & & & & & & \\\\
")

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  tab_f1 <- paste0(tab_f1, sprintf(
    "\\quad %s & %s & %s & %s & %s & %s & %s \\\\\n",
    r$Outcome, fmt(r$Beta), fmt(r$SE), fmt(r$SD_Y, 3),
    fmt(r$SDE), fmt(r$SE_SDE), r$Classification
  ))
}

tab_f1 <- paste0(tab_f1, "\\hline\n\\textit{Panel B: Heterogeneous (DMV split)} & & & & & & \\\\\n")

for (i in 1:nrow(het_rows)) {
  r <- het_rows[i, ]
  tab_f1 <- paste0(tab_f1, sprintf(
    "\\quad %s & %s & %s & %s & %s & %s & %s \\\\\n",
    r$Outcome, fmt(r$Beta), fmt(r$SE), fmt(r$SD_Y, 3),
    fmt(r$SDE), fmt(r$SE_SDE), r$Classification
  ))
}

tab_f1 <- paste0(tab_f1, "
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
", sde_notes, "
\\end{tablenotes}
\\end{table}
")

writeLines(tab_f1, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat("All tables generated.\n")
