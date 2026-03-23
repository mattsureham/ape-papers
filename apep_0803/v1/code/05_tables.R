## 05_tables.R — Generate all tables for apep_0803
## Who Gets the New Jobs? Medicaid Expansion and Racial Employment in Healthcare

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

options(modelsummary_factory_latex = "kableExtra")
options("modelsummary_format_numeric_latex" = "plain")
cat("=== TABLE GENERATION ===\n")

## Load results
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

## Load panel data for summary stats
state_race <- fread(file.path(data_dir, "panel_state_race.csv"))
annual_ddd_raw <- fread(file.path(data_dir, "panel_ddd.csv"))

## Reconstruct annual panels
annual_race <- state_race[, .(
  emp = sum(emp, na.rm = TRUE),
  hires = sum(hires, na.rm = TRUE)
), by = .(state, state_fips, year, race, race_label, expansion_year, expanded)]
annual_ddd <- annual_ddd_raw[, .(
  emp_White = sum(emp_White, na.rm = TRUE),
  emp_Black = sum(emp_Black, na.rm = TRUE),
  hires_White = sum(hires_White, na.rm = TRUE),
  hires_Black = sum(hires_Black, na.rm = TRUE)
), by = .(state, state_fips, year, expansion_year, expanded)]
annual_ddd[, black_share := emp_Black / (emp_Black + emp_White)]

## ─────────────────────────────────────────────────────────
## Table 1: Summary Statistics
## ─────────────────────────────────────────────────────────
cat("\n--- Table 1: Summary Statistics ---\n")

pre <- annual_ddd[year < 2014]

sumstat_exp <- pre[expanded == TRUE, .(
  mean_white = mean(emp_White, na.rm = TRUE),
  sd_white = sd(emp_White, na.rm = TRUE),
  mean_black = mean(emp_Black, na.rm = TRUE),
  sd_black = sd(emp_Black, na.rm = TRUE),
  mean_share = mean(black_share, na.rm = TRUE),
  sd_share = sd(black_share, na.rm = TRUE),
  n = .N
)]

sumstat_ctrl <- pre[expanded == FALSE, .(
  mean_white = mean(emp_White, na.rm = TRUE),
  sd_white = sd(emp_White, na.rm = TRUE),
  mean_black = mean(emp_Black, na.rm = TRUE),
  sd_black = sd(emp_Black, na.rm = TRUE),
  mean_share = mean(black_share, na.rm = TRUE),
  sd_share = sd(black_share, na.rm = TRUE),
  n = .N
)]

## Format summary stats table
tab1_body <- sprintf(
"\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Pre-Expansion Healthcare Employment by Race}
\\label{tab:sumstats}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{Expansion States} & \\multicolumn{2}{c}{Non-Expansion States} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
& Mean & SD & Mean & SD \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Employment (thousands)}} \\\\[3pt]
White healthcare employment & %s & %s & %s & %s \\\\
Black healthcare employment & %s & %s & %s & %s \\\\
[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Workforce composition}} \\\\[3pt]
Black share of healthcare emp. & %s & %s & %s & %s \\\\
[6pt]
\\midrule
Number of states & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
State-year observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Pre-expansion period (2001--2013). Healthcare = NAICS 62 (Healthcare and Social Assistance). Employment from QWI race-ethnicity panel, private sector, all ages and education levels. Expansion states = 40 states that expanded Medicaid under ACA. Non-expansion states = AL, FL, GA, KS, MS, NC, SC, TN, TX, WI, WY.
\\end{tablenotes}
\\end{table}",
  formatC(sumstat_exp$mean_white / 1000, format = "f", digits = 1, big.mark = ","),
  formatC(sumstat_exp$sd_white / 1000, format = "f", digits = 1, big.mark = ","),
  formatC(sumstat_ctrl$mean_white / 1000, format = "f", digits = 1, big.mark = ","),
  formatC(sumstat_ctrl$sd_white / 1000, format = "f", digits = 1, big.mark = ","),
  formatC(sumstat_exp$mean_black / 1000, format = "f", digits = 1, big.mark = ","),
  formatC(sumstat_exp$sd_black / 1000, format = "f", digits = 1, big.mark = ","),
  formatC(sumstat_ctrl$mean_black / 1000, format = "f", digits = 1, big.mark = ","),
  formatC(sumstat_ctrl$sd_black / 1000, format = "f", digits = 1, big.mark = ","),
  formatC(sumstat_exp$mean_share, format = "f", digits = 3),
  formatC(sumstat_exp$sd_share, format = "f", digits = 3),
  formatC(sumstat_ctrl$mean_share, format = "f", digits = 3),
  formatC(sumstat_ctrl$sd_share, format = "f", digits = 3),
  length(unique(pre[expanded == TRUE]$state)),
  length(unique(pre[expanded == FALSE]$state)),
  nrow(pre[expanded == TRUE]),
  nrow(pre[expanded == FALSE])
)

writeLines(tab1_body, file.path(table_dir, "tab1_sumstats.tex"))
cat("  Written tab1_sumstats.tex\n")

## ─────────────────────────────────────────────────────────
## Table 2: Main Results — Race-Specific Employment Effects
## ─────────────────────────────────────────────────────────
cat("\n--- Table 2: Main Results ---\n")

tab2 <- modelsummary(
  list(
    "All Races" = results$twfe_agg,
    "White" = results$white,
    "Black" = results$black,
    "Asian" = results$asian,
    "DDD" = results$ddd
  ),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = c("post" = "Expansion $\\times$ Post",
               "post:black" = "Expansion $\\times$ Post $\\times$ Black"),
  gof_map = c("nobs", "adj.r.squared", "FE: state", "FE: year",
              "FE: state^race", "FE: year^race", "FE: state^year"),
  output = file.path(table_dir, "tab2_main.tex"),
  title = "Medicaid Expansion and Healthcare Employment by Race",
  notes = list("Standard errors clustered at the state level. Outcome: log quarterly healthcare employment (NAICS 62). Columns 1--4: state and year fixed effects. Column 5: state$\\times$race, year$\\times$race, and state$\\times$year fixed effects. Expansion = 1 for states that expanded Medicaid, in post-expansion years. Sample: 51 states, 2001--2023."),
  escape = FALSE
)

cat("  Written tab2_main.tex\n")

## ─────────────────────────────────────────────────────────
## Table 3: Black Share and Hires Decomposition
## ─────────────────────────────────────────────────────────
cat("\n--- Table 3: Black Share and Hires ---\n")

tab3 <- modelsummary(
  list(
    "Black Share" = results$black_share,
    "Black Hires" = results$hires_black,
    "White Hires" = results$hires_white,
    "Hires DDD" = results$hires_ddd
  ),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = c("post" = "Expansion $\\times$ Post",
               "post:black" = "Exp. $\\times$ Post $\\times$ Black"),
  gof_map = c("nobs", "adj.r.squared"),
  output = file.path(table_dir, "tab3_shares.tex"),
  title = "Black Share of Healthcare Employment and Hiring Flows",
  notes = list("Standard errors clustered at the state level. Column 1: outcome = Black share of healthcare employment. Columns 2--3: outcome = log hires by race. Column 4: DDD on log hires (state$\\times$race, year$\\times$race, state$\\times$year FE). Sun-Abraham ATT for Black share: 0.0048 (SE 0.0025, $p = 0.064$). Sun-Abraham ATT for log Black employment: 0.100 (SE 0.034, $p = 0.005$)."),
  escape = FALSE
)

cat("  Written tab3_shares.tex\n")

## ─────────────────────────────────────────────────────────
## Table 4: Robustness
## ─────────────────────────────────────────────────────────
cat("\n--- Table 4: Robustness ---\n")

tab4 <- modelsummary(
  list(
    "Baseline" = results$black_share,
    "2014 Cohort" = rob_results$only2014,
    "Retail Placebo" = rob_results$retail,
    "Hires Share" = rob_results$hires_share
  ),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = c("post" = "Expansion $\\times$ Post"),
  gof_map = c("nobs", "adj.r.squared"),
  output = file.path(table_dir, "tab4_robustness.tex"),
  title = "Robustness: Black Share of Healthcare Employment",
  notes = list("Standard errors clustered at the state level. Column 1: Baseline TWFE on Black share. Column 2: 2014 expansion cohort vs.~never-treated only. Column 3: Retail trade placebo (log employment). Column 4: Black share of healthcare \\textit{hires}. Sun-Abraham ATT for Black share: 0.0048 (SE 0.0025, $p = 0.064$). Pre-trend test ($p = 0.737$): no differential trend."),
  escape = FALSE
)

cat("  Written tab4_robustness.tex\n")

## ─────────────────────────────────────────────────────────
## Table F1: Standardized Effect Sizes (SDE)
## ─────────────────────────────────────────────────────────
cat("\n--- Table F1: SDE ---\n")

## Compute SDEs for main outcomes
## SD(Y) from pre-treatment period
pre_share <- annual_ddd[year < 2014]$black_share
sd_share <- sd(pre_share, na.rm = TRUE)

pre_log_emp_black <- log(annual_race[race == "A2" & year < 2014 & emp > 0]$emp)
sd_log_emp_black <- sd(pre_log_emp_black, na.rm = TRUE)

pre_log_emp_white <- log(annual_race[race == "A1" & year < 2014 & emp > 0]$emp)
sd_log_emp_white <- sd(pre_log_emp_white, na.rm = TRUE)

## Main estimates
beta_share <- coef(results$black_share)["post"]
se_share <- se(results$black_share)["post"]
sde_share <- beta_share / sd_share
se_sde_share <- se_share / sd_share

beta_black <- coef(results$black)["post"]
se_black <- se(results$black)["post"]
sde_black <- beta_black / sd_log_emp_black
se_sde_black <- se_black / sd_log_emp_black

beta_white <- coef(results$white)["post"]
se_white <- se(results$white)["post"]
sde_white <- beta_white / sd_log_emp_white
se_sde_white <- se_white / sd_log_emp_white

## SA estimate for Black employment
beta_sa_black <- 0.100441  # from Sun-Abraham ATT
se_sa_black <- 0.034018
sde_sa_black <- beta_sa_black / sd_log_emp_black
se_sde_sa_black <- se_sa_black / sd_log_emp_black

## Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

rows <- data.table(
  Outcome = c(
    "Black share of HC emp.",
    "Log Black HC employment",
    "Log White HC employment",
    "Log Black HC emp. (SA)"
  ),
  beta = c(beta_share, beta_black, beta_white, beta_sa_black),
  se = c(se_share, se_black, se_white, se_sa_black),
  sd_y = c(sd_share, sd_log_emp_black, sd_log_emp_white, sd_log_emp_black),
  sde = c(sde_share, sde_black, sde_white, sde_sa_black),
  se_sde = c(se_sde_share, se_sde_black, se_sde_white, se_sde_sa_black)
)
rows[, classification := sapply(sde, classify_sde)]

## Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does Medicaid expansion under the ACA increase Black workers' share of healthcare employment relative to White workers? ",
  "\\textbf{Policy mechanism:} Medicaid expansion extends public health insurance coverage to adults up to 138\\% FPL, ",
  "increasing hospital and clinic revenue in expansion states and inducing healthcare hiring; the question is whether ",
  "new hiring disproportionately benefits minority workers through community health centers in underserved areas or ",
  "reinforces existing racial segmentation through credentialing and network-based referrals. ",
  "\\textbf{Outcome definition:} Black share = Black healthcare employment divided by Black plus White healthcare employment (NAICS 62); ",
  "log employment = natural log of quarterly private-sector healthcare employment by race from QWI. ",
  "\\textbf{Treatment:} Binary state-level Medicaid expansion adoption under ACA (40 states expanded, 11 did not). ",
  "\\textbf{Data:} Census QWI race-ethnicity panel (LEHD), state $\\times$ year $\\times$ race, 2001--2023, 51 states. ",
  "\\textbf{Method:} TWFE DiD with state and year FE; Sun-Abraham heterogeneity-robust estimator for staggered adoption; ",
  "triple-difference (state $\\times$ race $\\times$ year); clustered SEs at state level. ",
  "\\textbf{Sample:} All 51 states (including DC), private sector healthcare (NAICS 62), all ages and education levels, restricted to race-specific totals (sex/age/education aggregated). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- sprintf(
"\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
%s \\\\
%s \\\\
%s \\\\
%s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
%s
\\end{tablenotes}
\\end{table}",
  sprintf("%s & %s & %s & %s & %s & %s & %s",
          rows$Outcome[1],
          formatC(rows$beta[1], format = "f", digits = 4),
          formatC(rows$se[1], format = "f", digits = 4),
          formatC(rows$sd_y[1], format = "f", digits = 4),
          formatC(rows$sde[1], format = "f", digits = 4),
          formatC(rows$se_sde[1], format = "f", digits = 4),
          rows$classification[1]),
  sprintf("%s & %s & %s & %s & %s & %s & %s",
          rows$Outcome[2],
          formatC(rows$beta[2], format = "f", digits = 4),
          formatC(rows$se[2], format = "f", digits = 4),
          formatC(rows$sd_y[2], format = "f", digits = 4),
          formatC(rows$sde[2], format = "f", digits = 4),
          formatC(rows$se_sde[2], format = "f", digits = 4),
          rows$classification[2]),
  sprintf("%s & %s & %s & %s & %s & %s & %s",
          rows$Outcome[3],
          formatC(rows$beta[3], format = "f", digits = 4),
          formatC(rows$se[3], format = "f", digits = 4),
          formatC(rows$sd_y[3], format = "f", digits = 4),
          formatC(rows$sde[3], format = "f", digits = 4),
          formatC(rows$se_sde[3], format = "f", digits = 4),
          rows$classification[3]),
  sprintf("%s & %s & %s & %s & %s & %s & %s",
          rows$Outcome[4],
          formatC(rows$beta[4], format = "f", digits = 4),
          formatC(rows$se[4], format = "f", digits = 4),
          formatC(rows$sd_y[4], format = "f", digits = 4),
          formatC(rows$sde[4], format = "f", digits = 4),
          formatC(rows$se_sde[4], format = "f", digits = 4),
          rows$classification[4]),
  sde_notes
)

writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat("\n=== TABLE GENERATION COMPLETE ===\n")
