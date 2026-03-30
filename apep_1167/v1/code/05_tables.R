## 05_tables.R — Generate all tables for the paper

library(dplyr)
library(readr)
library(fixest)
library(modelsummary)
library(kableExtra)
library(jsonlite)

load("data/regression_results.RData")
load("data/robustness_results.RData")

# ─────────────────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

summ_vars <- df |>
  summarise(
    `SA Completions (pre, 2006-2009)` = sprintf("%.1f", mean(pre_comp)),
    `SA Completions (post, 2018-2021)` = sprintf("%.1f", mean(post_comp)),
    `Change in SA Completions` = sprintf("%.1f", mean(delta_comp)),
    `Log Total Pills (2006-2009)` = sprintf("%.2f", mean(log_pills_total)),
    `Total Pills (millions)` = sprintf("%.1f", mean(pills_boom) / 1e6),
    `Triplicate State (share)` = sprintf("%.3f", mean(triplicate)),
    `Counties` = as.character(nrow(df)),
    `States` = as.character(n_distinct(df$buyer_state))
  )

# Write as LaTeX
tab1_rows <- data.frame(
  Variable = c(
    "SA Completions (pre, 2006--2009)", "SA Completions (post, 2018--2021)",
    "$\\Delta$ SA Completions", "Log Total Pills (2006--2009)",
    "Total Pills (millions)", "Triplicate State",
    "Counties", "States"
  ),
  Mean = c(
    sprintf("%.1f", mean(df$pre_comp)), sprintf("%.1f", mean(df$post_comp)),
    sprintf("%.1f", mean(df$delta_comp)), sprintf("%.2f", mean(df$log_pills_total)),
    sprintf("%.1f", mean(df$pills_boom)/1e6), sprintf("%.3f", mean(df$triplicate)),
    as.character(nrow(df)), as.character(n_distinct(df$buyer_state))
  ),
  SD = c(
    sprintf("%.1f", sd(df$pre_comp)), sprintf("%.1f", sd(df$post_comp)),
    sprintf("%.1f", sd(df$delta_comp)), sprintf("%.2f", sd(df$log_pills_total)),
    sprintf("%.1f", sd(df$pills_boom)/1e6), sprintf("%.3f", sd(df$triplicate)),
    "", ""
  ),
  Min = c(
    sprintf("%.0f", min(df$pre_comp)), sprintf("%.0f", min(df$post_comp)),
    sprintf("%.0f", min(df$delta_comp)), sprintf("%.2f", min(df$log_pills_total)),
    sprintf("%.1f", min(df$pills_boom)/1e6), "0", "", ""
  ),
  Max = c(
    sprintf("%.0f", max(df$pre_comp)), sprintf("%.0f", max(df$post_comp)),
    sprintf("%.0f", max(df$delta_comp)), sprintf("%.2f", max(df$log_pills_total)),
    sprintf("%.1f", max(df$pills_boom)/1e6), "1", "", ""
  )
)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Variable & Mean & SD & Min & Max \\\\\n",
  "\\midrule\n",
  paste(apply(tab1_rows, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Unit of observation is the US county. SA completions are annual averages of IPEDS awards in CIP 51.15xx (Substance Abuse/Addiction Counseling). Pills are total opioid dosage units shipped to the county during 2006--2009, from DEA ARCOS. Triplicate state indicates counties in states that required triplicate prescriptions (CA, ID, IL, IN, NY, TX), used as an instrument for pill supply.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "tables/tab1_summary.tex")

# ─────────────────────────────────────────────────────────
# Table 2: Main Results — OLS Long Differences
# ─────────────────────────────────────────────────────────
cat("Generating Table 2: Main Results...\n")

tab2_tex <- etable(m1, m2, m3, m4, m5,
  title = "Opioid Pill Supply and Substance Abuse Counseling Completions",
  label = "tab:main",
  headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
  dict = c(
    log_pills_total = "Log Pills (2006-2009)",
    pre_comp = "Baseline SA Completions",
    delta_comp = "$\\Delta$ SA Completions",
    log_delta_sa = "Log Growth SA"
  ),
  fixef.group = list("State FE" = "state_fe"),
  notes = "\\textit{Notes:} Columns 1--3: dependent variable is the change in annual average SA counseling completions (2018--2021 minus 2006--2009). Columns 4--5: dependent variable is log growth in SA completions; sample restricted to counties with positive pre-period completions. Standard errors are heteroskedasticity-robust. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  tex = TRUE,
  file = "tables/tab2_main.tex",
  replace = TRUE
)

# ─────────────────────────────────────────────────────────
# Table 3: IV Results
# ─────────────────────────────────────────────────────────
cat("Generating Table 3: IV Results...\n")

tab3_tex <- etable(fs1, iv1, iv2,
  title = "Instrumental Variable Estimates: Triplicate-State Instrument",
  label = "tab:iv",
  headers = c("First Stage", "IV", "IV + Region FE"),
  dict = c(
    triplicateTRUE = "Triplicate State",
    log_pills_total = "Log Pills (2006-2009)",
    fit_log_pills_total = "Log Pills (2006-2009)"
  ),
  fixef.group = list("Region FE" = "region"),
  notes = "\\textit{Notes:} Column 1: first-stage regression of log pills on triplicate-state indicator. Columns 2--3: two-stage least squares estimates of the effect of pill supply on the change in SA counseling completions. Triplicate states (CA, ID, IL, IN, NY, TX) required triplicate prescriptions, reducing OxyContin penetration (Alpert et al.\\ 2022). Standard errors are heteroskedasticity-robust.",
  tex = TRUE,
  file = "tables/tab3_iv.tex",
  replace = TRUE
)

# ─────────────────────────────────────────────────────────
# Table 4: Robustness — Panel DiD and Placebos
# ─────────────────────────────────────────────────────────
cat("Generating Table 4: Robustness...\n")

tab4_tex <- etable(panel_m1, m_growth_fe, m_eng, m_bus,
  title = "Robustness: Panel DiD, Growth Rates, and Placebo Outcomes",
  label = "tab:robust",
  headers = c("Panel DiD", "Growth Rate", "Engineering", "Business"),
  dict = c(
    pills_x_post = "Log Pills $\\times$ Post",
    log_pills_total = "Log Pills",
    delta_eng = "$\\Delta$ Engineering",
    delta_bus = "$\\Delta$ Business",
    growth_sa = "Growth Rate SA"
  ),
  fixef.group = list("County FE" = "county_fips", "Year FE" = "year", "State FE" = "state_fe"),
  notes = "\\textit{Notes:} Column 1: county-year panel (2000--2024) with county and year fixed effects; dependent variable is annual SA counseling completions; standard errors clustered at the state level. Column 2: growth rate specification (post/pre ratio) with state fixed effects; sample restricted to counties with $\\geq$5 pre-period completions. Columns 3--4: placebo regressions using engineering and business completions as outcomes.",
  tex = TRUE,
  file = "tables/tab4_robust.tex",
  replace = TRUE
)

# ─────────────────────────────────────────────────────────
# Table F1: Standardized Effect Sizes (SDE)
# ─────────────────────────────────────────────────────────
cat("Generating SDE table...\n")

# Compute SDE for main outcomes
sd_y_pre <- sd(df$pre_comp)
sd_y_delta <- sd(df$delta_comp)
sd_x <- sd(df$log_pills_total)

# Main OLS: beta = 32.79, SE = 8.15
beta_ols <- coef(m1)["log_pills_total"]
se_ols <- sqrt(vcov(m1)["log_pills_total", "log_pills_total"])
sde_ols <- beta_ols * sd_x / sd_y_delta
se_sde_ols <- se_ols * sd_x / sd_y_delta

# Panel DiD: beta = 33.78, SE = 8.36
beta_panel <- coef(panel_m1)["pills_x_post"]
se_panel <- sqrt(vcov(panel_m1)["pills_x_post", "pills_x_post"])
sd_y_panel <- sd(read_csv("data/county_year_completions.csv", show_col_types = FALSE) |>
  filter(field_group == "sa_counseling") |> pull(completions), na.rm = TRUE)
sde_panel <- beta_panel * sd_x / sd_y_panel
se_sde_panel <- se_panel * sd_x / sd_y_panel

# Growth rate: beta = 1.035
beta_growth <- coef(m_growth_fe)["log_pills_total"]
se_growth <- sqrt(vcov(m_growth_fe)["log_pills_total", "log_pills_total"])
df_growth <- df |> filter(has_pre_sa, pre_comp >= 5) |> mutate(growth_sa = (post_comp - pre_comp) / pre_comp)
sd_y_growth <- sd(df_growth$growth_sa)
sde_growth <- beta_growth * sd_x / sd_y_growth
se_sde_growth <- se_growth * sd_x / sd_y_growth

classify_sde <- function(s) {
  if (is.na(s)) return("NA")
  abs_s <- abs(s)
  dir <- ifelse(s > 0, "positive", "negative")
  if (abs_s > 0.15) return(paste("Large", dir))
  if (abs_s > 0.05) return(paste("Moderate", dir))
  if (abs_s > 0.005) return(paste("Small", dir))
  return("Null")
}

sde_rows <- data.frame(
  Outcome = c("$\\Delta$ SA Completions (OLS)", "SA Completions (Panel DiD)", "SA Growth Rate"),
  Beta = c(sprintf("%.2f", beta_ols), sprintf("%.2f", beta_panel), sprintf("%.3f", beta_growth)),
  SE = c(sprintf("%.2f", se_ols), sprintf("%.2f", se_panel), sprintf("%.3f", se_growth)),
  SD_Y = c(sprintf("%.1f", sd_y_delta), sprintf("%.1f", sd_y_panel), sprintf("%.2f", sd_y_growth)),
  SDE = c(sprintf("%.3f", sde_ols), sprintf("%.3f", sde_panel), sprintf("%.3f", sde_growth)),
  SE_SDE = c(sprintf("%.3f", se_sde_ols), sprintf("%.3f", se_sde_panel), sprintf("%.3f", se_sde_growth)),
  Classification = c(classify_sde(sde_ols), classify_sde(sde_panel), classify_sde(sde_growth))
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does county-level opioid prescription pill supply intensity during the 2006--2009 boom predict subsequent growth in substance abuse counseling credential production at local higher education institutions? ",
  "\\textbf{Policy mechanism:} The prescription opioid boom created geographically concentrated substance abuse crises, generating local labor market demand for addiction counselors; higher education institutions responded by expanding or creating SA counseling programs (CIP 51.15xx), producing a demand-induced credential pipeline. ",
  "\\textbf{Outcome definition:} Row 1: change in annual average IPEDS SA counseling completions (2018--2021 minus 2006--2009). Row 2: annual SA counseling completions in county-year panel (2000--2024). Row 3: proportional growth rate (post/pre). ",
  "\\textbf{Treatment:} Continuous: log total opioid dosage units shipped to the county during 2006--2009 (DEA ARCOS). ",
  "\\textbf{Data:} DEA ARCOS (178.6M transactions, 3,089 counties, 2006--2012) linked to IPEDS completions (842 institutions, 651 counties, 2000--2024); analysis sample: 378 counties. ",
  "\\textbf{Method:} Cross-sectional long differences (OLS, rows 1 and 3) and county-year panel with two-way fixed effects (row 2); heteroskedasticity-robust standard errors (rows 1, 3) and state-clustered (row 2). ",
  "\\textbf{Sample:} US counties with at least one IPEDS institution reporting SA counseling completions and non-missing ARCOS pill shipment data. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(apply(sde_rows, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by triplicate-state status)}} \\\\\n"
)

# Panel B: Split by triplicate status
df_trip <- df |> filter(triplicate)
df_notrip <- df |> filter(!triplicate)
m_trip <- feols(delta_comp ~ log_pills_total, data = df_trip, vcov = "HC1")
m_notrip <- feols(delta_comp ~ log_pills_total, data = df_notrip, vcov = "HC1")

beta_trip <- coef(m_trip)["log_pills_total"]
se_trip <- sqrt(vcov(m_trip)["log_pills_total", "log_pills_total"])
sde_trip <- beta_trip * sd(df_trip$log_pills_total) / sd(df_trip$delta_comp)
se_sde_trip <- se_trip * sd(df_trip$log_pills_total) / sd(df_trip$delta_comp)

beta_notrip <- coef(m_notrip)["log_pills_total"]
se_notrip <- sqrt(vcov(m_notrip)["log_pills_total", "log_pills_total"])
sde_notrip <- beta_notrip * sd(df_notrip$log_pills_total) / sd(df_notrip$delta_comp)
se_sde_notrip <- se_notrip * sd(df_notrip$log_pills_total) / sd(df_notrip$delta_comp)

sde_tex <- paste0(sde_tex,
  sprintf("Triplicate states & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\\n",
          beta_trip, se_trip, sd(df_trip$delta_comp), sde_trip, se_sde_trip, classify_sde(sde_trip)),
  sprintf("Non-triplicate states & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\\n",
          beta_notrip, se_notrip, sd(df_notrip$delta_comp), sde_notrip, se_sde_notrip, classify_sde(sde_notrip)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "tables/tabF1_sde.tex")

cat("\nAll tables generated in tables/\n")
cat("Files:", paste(list.files("tables/"), collapse=", "), "\n")
