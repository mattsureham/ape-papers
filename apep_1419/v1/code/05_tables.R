## 05_tables.R — Generate all tables for paper
## apep_1419: UK Auto-Enrollment Contribution Step-Up and Wages

source("00_packages.R")
data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "analysis_panel.RData"))
load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

## ========================================================================
## Table 1: Summary Statistics
## ========================================================================
cat("Generating Table 1: Summary Statistics...\n")

pre_data <- panel_bal %>% filter(year < 2019)

sumstat_all <- pre_data %>%
  summarise(
    `Mean annual pay (GBP)` = mean(median_annual_pay, na.rm = TRUE),
    `SD annual pay` = sd(median_annual_pay, na.rm = TRUE),
    `Mean hourly pay (GBP)` = mean(median_hourly_pay, na.rm = TRUE),
    `Small-firm share` = mean(small_share, na.rm = TRUE),
    `Micro-firm share` = mean(micro_share, na.rm = TRUE),
    N = n(),
    `N LAs` = n_distinct(la_code)
  ) %>%
  mutate(Panel = "All LAs") %>%
  select(Panel, everything())

sumstat_high <- pre_data %>%
  filter(high_small == 1) %>%
  summarise(
    `Mean annual pay (GBP)` = mean(median_annual_pay, na.rm = TRUE),
    `SD annual pay` = sd(median_annual_pay, na.rm = TRUE),
    `Mean hourly pay (GBP)` = mean(median_hourly_pay, na.rm = TRUE),
    `Small-firm share` = mean(small_share, na.rm = TRUE),
    `Micro-firm share` = mean(micro_share, na.rm = TRUE),
    N = n(),
    `N LAs` = n_distinct(la_code)
  ) %>%
  mutate(Panel = "High small-firm LAs") %>%
  select(Panel, everything())

sumstat_low <- pre_data %>%
  filter(high_small == 0) %>%
  summarise(
    `Mean annual pay (GBP)` = mean(median_annual_pay, na.rm = TRUE),
    `SD annual pay` = sd(median_annual_pay, na.rm = TRUE),
    `Mean hourly pay (GBP)` = mean(median_hourly_pay, na.rm = TRUE),
    `Small-firm share` = mean(small_share, na.rm = TRUE),
    `Micro-firm share` = mean(micro_share, na.rm = TRUE),
    N = n(),
    `N LAs` = n_distinct(la_code)
  ) %>%
  mutate(Panel = "Low small-firm LAs") %>%
  select(Panel, everything())

sumstat <- bind_rows(sumstat_all, sumstat_high, sumstat_low)

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Local Authority Characteristics (2015--2018)}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & All LAs & High small-firm & Low small-firm \\\\",
  "\\midrule"
)

vars <- c("Mean annual pay (GBP)", "SD annual pay", "Mean hourly pay (GBP)",
          "Small-firm share", "Micro-firm share", "N", "N LAs")

for (v in vars) {
  vals <- sapply(list(sumstat_all, sumstat_high, sumstat_low), function(s) {
    val <- s[[v]]
    if (v %in% c("Small-firm share", "Micro-firm share")) {
      sprintf("%.3f", val)
    } else if (v %in% c("N", "N LAs")) {
      format(round(val), big.mark = ",")
    } else {
      format(round(val), big.mark = ",")
    }
  })
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s \\\\", v, vals[1], vals[2], vals[3]))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment summary statistics (2015--2018) for the balanced panel of English and Welsh local authorities. ``High small-firm'' LAs have above-median share of business units with fewer than 50 employees. Annual and hourly pay are ASHE workplace analysis medians. Business structure from 2018 UK Business Counts.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1_lines, file.path(tables_dir, "tab1_sumstats.tex"))

## ========================================================================
## Table 2: Main DiD Results
## ========================================================================
cat("Generating Table 2: Main Results...\n")

tab2_models <- list(
  "(1)" = m1,
  "(2)" = m_binary,
  "(3)" = m_hourly,
  "(4)" = m_weighted
)

# Build manually for precise control
get_coef_se <- function(model, pattern) {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model)))
  idx <- grep(pattern, names(cf))
  if (length(idx) == 0) return(c(NA, NA))
  c(cf[idx[1]], se[idx[1]])
}

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Contribution Step-Up on Median Wages}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log annual & Log annual & Log hourly & Log annual \\\\",
  " & pay & pay & pay & pay (wtd) \\\\",
  "\\midrule"
)

# Row 1: continuous treatment × post
cs1 <- get_coef_se(m1, "treat_intensity:post")
cs4 <- get_coef_se(m_weighted, "treat_intensity:post")

tab2_lines <- c(tab2_lines,
  sprintf("Small-firm share $\\times$ Post & %.4f & & & %.4f \\\\", cs1[1], cs4[1]),
  sprintf(" & (%.4f) & & & (%.4f) \\\\", cs1[2], cs4[2])
)

# Row 2: binary treatment × post
cs2 <- get_coef_se(m_binary, "high_small:post")
tab2_lines <- c(tab2_lines,
  sprintf("High small-firm $\\times$ Post & & %.4f & & \\\\", cs2[1]),
  sprintf(" & & (%.4f) & & \\\\", cs2[2])
)

# Row 3: hourly
cs3 <- get_coef_se(m_hourly, "treat_intensity:post")
tab2_lines <- c(tab2_lines,
  sprintf("Small-firm share $\\times$ Post (hourly) & & & %.4f & \\\\", cs3[1]),
  sprintf(" & & & (%.4f) & \\\\", cs3[2])
)

tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("LA FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Employment weights & No & No & No & Yes \\\\"),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","),
          format(nobs(m_binary), big.mark = ","),
          format(nobs(m_hourly), big.mark = ","),
          format(nobs(m_weighted), big.mark = ",")),
  sprintf("R$^2$ (within) & %.4f & %.4f & %.4f & %.4f \\\\",
          fitstat(m1, "wr2")[[1]], fitstat(m_binary, "wr2")[[1]],
          fitstat(m_hourly, "wr2")[[1]], fitstat(m_weighted, "wr2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Difference-in-differences estimates of the April 2019 employer contribution step-up (2\\% to 3\\%) on median log wages. Treatment intensity is the pre-treatment (2018) share of business units with fewer than 50 employees in each local authority. Post $= 1$ for years $\\geq 2019$. Standard errors clustered at the local authority level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

## ========================================================================
## Table 3: Event Study Coefficients
## ========================================================================
cat("Generating Table 3: Event Study...\n")

es_coefs <- coef(m_event)
es_se <- sqrt(diag(vcov(m_event)))
es_pval <- 2 * pnorm(-abs(es_coefs / es_se))

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event-Study Estimates: Year-by-Year Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Year & Coefficient & SE \\\\",
  "\\midrule"
)

for (yr in c(2015, 2016, 2017, 2019, 2020, 2021, 2022, 2023)) {
  idx <- grep(as.character(yr), names(es_coefs))
  if (length(idx) > 0) {
    stars <- ifelse(es_pval[idx[1]] < 0.01, "$^{***}$",
             ifelse(es_pval[idx[1]] < 0.05, "$^{**}$",
             ifelse(es_pval[idx[1]] < 0.1, "$^{*}$", "")))
    tab3_lines <- c(tab3_lines,
      sprintf("%d & %.4f%s & (%.4f) \\\\", yr, es_coefs[idx[1]], stars, es_se[idx[1]]))
  }
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "2018 (reference) & 0 & --- \\\\",
  "\\midrule",
  sprintf("Pre-trend F-test p-value & \\multicolumn{2}{c}{%.3f} \\\\",
          {
            pre_idx <- grep("2015|2016|2017", names(es_coefs))
            if (length(pre_idx) >= 2) {
              wald <- tryCatch(wald(m_event, keep = names(es_coefs)[pre_idx])$p, error = function(e) NA)
            } else NA
          }),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Event-study coefficients from the interaction of small-firm share with year indicators. Dependent variable is log median annual pay. The omitted year is 2018 (last pre-treatment year). All specifications include LA and year fixed effects. Standard errors clustered at the LA level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3_lines, file.path(tables_dir, "tab3_eventstudy.tex"))

## ========================================================================
## Table 4: Robustness
## ========================================================================
cat("Generating Table 4: Robustness...\n")

rob_models <- list(m_micro, m_large, m_nolon, m_nocovid, m_placebo, m_tercile)
rob_names <- c("Micro share", "Large share (placebo)", "Excl. London",
               "Excl. COVID", "Placebo 2017", "Top vs bottom tercile")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  paste0(" & ", paste(rob_names, collapse = " & "), " \\\\"),
  "\\midrule"
)

coef_row <- "Treatment $\\times$ Post"
se_row <- ""
n_row <- "Observations"

coef_vals <- c()
se_vals <- c()
n_vals <- c()

for (mod in rob_models) {
  cf <- coef(mod)
  se <- sqrt(diag(vcov(mod)))
  # Get the interaction coefficient (first one)
  coef_vals <- c(coef_vals, sprintf("%.4f", cf[1]))
  se_vals <- c(se_vals, sprintf("(%.4f)", se[1]))
  n_vals <- c(n_vals, format(nobs(mod), big.mark = ","))
}

tab4_lines <- c(tab4_lines,
  paste0(coef_row, " & ", paste(coef_vals, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_vals, collapse = " & "), " \\\\"),
  "\\midrule",
  paste0(n_row, " & ", paste(n_vals, collapse = " & "), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Robustness checks for the main DiD specification. Column (1) uses micro-firm share (0--9 employees) as treatment intensity. Column (2) uses large-firm share (250+) as a placebo. Column (3) excludes London boroughs. Column (4) excludes 2020--2021. Column (5) applies a placebo treatment date of 2017 using only pre-step-up data (2015--2018). Column (6) compares top vs.\\ bottom tercile of small-firm share. All specifications include LA and year FE with LA-clustered SEs.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4_lines, file.path(tables_dir, "tab4_robust.tex"))

## ========================================================================
## Table F1: Standardized Effect Sizes (SDE)
## ========================================================================
cat("Generating Table F1: SDE...\n")

# Compute SDE for main outcomes
sd_y_annual <- sd(panel_bal$log_annual_pay[panel_bal$year < 2019], na.rm = TRUE)
sd_y_hourly <- sd(panel_bal$log_hourly_pay[panel_bal$year < 2019], na.rm = TRUE)
sd_x <- sd(panel_bal$treat_intensity[panel_bal$year == 2018], na.rm = TRUE)

# Main continuous treatment coefficients
beta_annual <- coef(m1)[1]
se_annual <- sqrt(diag(vcov(m1)))[1]
beta_hourly <- coef(m_hourly)[1]
se_hourly <- sqrt(diag(vcov(m_hourly)))[1]

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sde_annual <- beta_annual * sd_x / sd_y_annual
se_sde_annual <- se_annual * sd_x / sd_y_annual
sde_hourly <- beta_hourly * sd_x / sd_y_hourly
se_sde_hourly <- se_hourly * sd_x / sd_y_hourly

# Binary treatment
beta_binary <- coef(m_binary)[1]
se_binary <- sqrt(diag(vcov(m_binary)))[1]
sde_binary <- beta_binary / sd_y_annual
se_sde_binary <- se_binary / sd_y_annual

# No-COVID
beta_nocovid <- coef(m_nocovid)[1]
se_nocovid <- sqrt(diag(vcov(m_nocovid)))[1]
sde_nocovid <- beta_nocovid * sd_x / sd_y_annual
se_sde_nocovid <- se_nocovid * sd_x / sd_y_annual

classify_sde <- function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s < 0.005) "Null"
  else if (s < 0.05) "Small positive"
  else if (s < 0.15) "Moderate positive"
  else "Large positive"
}

# Heterogeneity: split by region (North vs South)
# Using a simple split: LAs in northern regions vs southern
north_pattern <- "Durham|Tyne|Sunderland|Middlesbrough|Hartlepool|Stockton|Redcar|Northumberland|Gateshead|Newcastle|Blackburn|Blackpool|Bolton|Bury|Manchester|Oldham|Rochdale|Salford|Stockport|Tameside|Trafford|Wigan|Knowsley|Liverpool|Sefton|Wirral|Barnsley|Doncaster|Rotherham|Sheffield|Bradford|Calderdale|Kirklees|Leeds|Wakefield|Hull|East Riding|North East|North Lincolnshire|York"

panel_bal$north <- as.integer(grepl(north_pattern, panel_bal$la_name, ignore.case = TRUE))

m_north <- feols(log_annual_pay ~ treat_intensity:post | la_code + year,
                 data = panel_bal %>% filter(north == 1), cluster = ~la_code)
m_south <- feols(log_annual_pay ~ treat_intensity:post | la_code + year,
                 data = panel_bal %>% filter(north == 0), cluster = ~la_code)

beta_north <- coef(m_north)[1]
se_north <- sqrt(diag(vcov(m_north)))[1]
sd_y_north <- sd(panel_bal$log_annual_pay[panel_bal$year < 2019 & panel_bal$north == 1], na.rm = TRUE)
sde_north <- beta_north * sd_x / sd_y_north
se_sde_north <- se_north * sd_x / sd_y_north

beta_south <- coef(m_south)[1]
se_south <- sqrt(diag(vcov(m_south)))[1]
sd_y_south <- sd(panel_bal$log_annual_pay[panel_bal$year < 2019 & panel_bal$north == 0], na.rm = TRUE)
sde_south <- beta_south * sd_x / sd_y_south
se_sde_south <- se_south * sd_x / sd_y_south

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does the April 2019 doubling of mandatory employer pension contributions (from 2\\% to 3\\% of qualifying earnings) reduce median wages in local authorities with higher shares of small firms, consistent with the Summers (1989) mandate-tax hypothesis? ",
  "\\textbf{Policy mechanism:} The Pensions Act 2008 auto-enrollment regime forces employers to enroll workers into a workplace pension and make minimum contributions; the April 2019 step-up raised the employer floor from 2\\% to 3\\%, with small firms disproportionately at the minimum and thus facing a larger effective cost shock. ",
  "\\textbf{Outcome definition:} Log median annual gross pay from the ONS Annual Survey of Hours and Earnings (ASHE) workplace analysis, measured at the local authority level. ",
  "\\textbf{Treatment:} Continuous --- pre-treatment (2018) share of business units with fewer than 50 employees in each local authority, interacted with a post-2019 indicator. ",
  "\\textbf{Data:} ONS ASHE via NOMIS (annual, 2015--2023) merged with UK Business Counts (2018) at the local authority level; balanced panel of English and Welsh LAs. ",
  "\\textbf{Method:} Two-way fixed effects (LA + year) difference-in-differences with continuous treatment intensity; standard errors clustered at the LA level. ",
  "\\textbf{Sample:} English and Welsh local authorities with non-missing ASHE data in at least 8 of 9 years. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-LA standard deviation of the small-firm share and SD($Y$) is the pre-treatment standard deviation of log annual pay. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_rows <- data.frame(
  Panel = c(rep("A", 4), rep("B", 2)),
  Outcome = c("Log annual pay (continuous)", "Log annual pay (binary)",
              "Log hourly pay", "Log annual pay (excl. COVID)",
              "Northern LAs", "Southern LAs"),
  Beta = c(beta_annual, beta_binary, beta_hourly, beta_nocovid, beta_north, beta_south),
  SE = c(se_annual, se_binary, se_hourly, se_nocovid, se_north, se_south),
  SD_Y = c(sd_y_annual, sd_y_annual, sd_y_hourly, sd_y_annual, sd_y_north, sd_y_south),
  SDE = c(sde_annual, sde_binary, sde_hourly, sde_nocovid, sde_north, sde_south),
  SE_SDE = c(se_sde_annual, se_sde_binary, se_sde_hourly, se_sde_nocovid, se_sde_north, se_sde_south),
  stringsAsFactors = FALSE
)
sde_rows$Class <- sapply(sde_rows$SDE, classify_sde)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  " & Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_rows)) {
  if (i == 5) {
    tabF1_lines <- c(tabF1_lines,
      "\\midrule",
      "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (North vs.\\ South)}} \\\\"
    )
  }
  tabF1_lines <- c(tabF1_lines,
    sprintf(" & %s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
            sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
            sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i], sde_rows$Class[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in tables/ directory.\n")

# Save heterogeneity models for reference
save(m_north, m_south, file = file.path(data_dir, "heterogeneity_results.RData"))
