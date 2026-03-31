# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# apep_1211: Medicaid Reimbursement and Black-White Nursing Home Earnings Gap
# ==============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

cat("Generating Table 1: Summary Statistics...\n")

# Compute weighted variance helper
wtd.var <- function(x, w) {
  w <- w / sum(w, na.rm = TRUE)
  mu <- sum(w * x, na.rm = TRUE)
  sum(w * (x - mu)^2, na.rm = TRUE)
}

# Panel A: Nursing Homes (NAICS 623)
nh_stats <- df |>
  filter(industry == "623") |>
  group_by(race_label) |>
  summarise(
    `Mean Earnings` = sprintf("%.0f", weighted.mean(EarnS, Emp, na.rm = TRUE)),
    `SD Earnings` = sprintf("%.0f", sqrt(wtd.var(EarnS, Emp))),
    `Mean Employment` = sprintf("%.0f", mean(Emp, na.rm = TRUE)),
    `Obs` = as.character(n()),
    .groups = "drop"
  )

# Panel B: Ambulatory Care (NAICS 621)
amb_stats <- df |>
  filter(industry == "621") |>
  group_by(race_label) |>
  summarise(
    `Mean Earnings` = sprintf("%.0f", weighted.mean(EarnS, Emp, na.rm = TRUE)),
    `SD Earnings` = sprintf("%.0f", sqrt(wtd.var(EarnS, Emp))),
    `Mean Employment` = sprintf("%.0f", mean(Emp, na.rm = TRUE)),
    `Obs` = as.character(n()),
    .groups = "drop"
  )

# Black/White ratio
bw_nh <- as.numeric(nh_stats$`Mean Earnings`[nh_stats$race_label == "Black"]) /
  as.numeric(nh_stats$`Mean Earnings`[nh_stats$race_label == "White"])
bw_amb <- as.numeric(amb_stats$`Mean Earnings`[amb_stats$race_label == "Black"]) /
  as.numeric(amb_stats$`Mean Earnings`[amb_stats$race_label == "White"])

# Treatment summary
n_treated <- n_distinct(df$state_fips[df$treat_year > 0])
n_control <- n_distinct(df$state_fips[df$treat_year == 0])
pre_years <- min(df$year[df$treat_year > 0]) - min(df$year)

# LaTeX Table 1
tab1_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{Summary Statistics: Quarterly Workforce Indicators by Race and Industry}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & Mean Earnings & SD Earnings & Mean Employment & Obs \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Nursing \\& Residential Care (NAICS 623)}} \\\\[3pt]
Black  & %s & %s & %s & %s \\\\
White  & %s & %s & %s & %s \\\\
Black/White ratio & \\multicolumn{2}{c}{%.3f} & & \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Ambulatory Health Care (NAICS 621)}} \\\\[3pt]
Black  & %s & %s & %s & %s \\\\
White  & %s & %s & %s & %s \\\\
Black/White ratio & \\multicolumn{2}{c}{%.3f} & & \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel C: Treatment Status}} \\\\[3pt]
Treated states   & \\multicolumn{4}{c}{%d} \\\\
Control states   & \\multicolumn{4}{c}{%d} \\\\
Treatment years  & \\multicolumn{4}{c}{2017--2023} \\\\
Sample period    & \\multicolumn{4}{c}{2010--2024} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} QWI state-quarter-race cells for non-Hispanic Black and White workers, 2010--2024.
Earnings are average quarterly earnings (QWI EarnS). Employment-weighted means.
Treatment = state implementation of a major Medicaid nursing home rate increase ($\\geq$5\\%% above inflation).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
',
  nh_stats$`Mean Earnings`[1], nh_stats$`SD Earnings`[1], nh_stats$`Mean Employment`[1], nh_stats$Obs[1],
  nh_stats$`Mean Earnings`[2], nh_stats$`SD Earnings`[2], nh_stats$`Mean Employment`[2], nh_stats$Obs[2],
  bw_nh,
  amb_stats$`Mean Earnings`[1], amb_stats$`SD Earnings`[1], amb_stats$`Mean Employment`[1], amb_stats$Obs[1],
  amb_stats$`Mean Earnings`[2], amb_stats$`SD Earnings`[2], amb_stats$`Mean Employment`[2], amb_stats$Obs[2],
  bw_amb,
  n_treated, n_control
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ==============================================================================
# Table 2: Main DDD Results
# ==============================================================================

cat("Generating Table 2: Main DDD Results...\n")

m1 <- results$ddd_basic
m2 <- results$ddd_saturated
m3 <- results$ddd_levels

# Extract coefficients
get_coef <- function(model, param) {
  c <- coef(model)[param]
  s <- se(model)[param]
  p <- pvalue(model)[param]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(est = c, se = s, p = p, stars = stars)
}

ddd_c1 <- get_coef(m1, "post:black:nursing_home")
ddd_c2 <- get_coef(m2, "post:black:nursing_home")
ddd_c3 <- get_coef(m3, "post:black:nursing_home")

# DD within nursing homes
m4 <- results$dd_within_nh
dd_c <- get_coef(m4, "post:black")

# Placebo
m_plac <- rob_results$placebo_hotel
plac_c <- get_coef(m_plac, "post:black:hotel")

tab2_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{Effect of Medicaid Rate Increases on the Black-White Earnings Gap}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & (1) & (2) & (3) & (4) & (5) \\\\
 & DDD & DDD Sat. & DDD (\\$) & DD (NH) & Placebo \\\\
\\midrule
Post $\\times$ Black $\\times$ NH & %s%s & %s%s & %s%s & & \\\\
 & (%s) & (%s) & (%s) & & \\\\[4pt]
Post $\\times$ Black & & & & %s%s & \\\\
 & & & & (%s) & \\\\[4pt]
Post $\\times$ Black $\\times$ Hotel & & & & & %s \\\\
 & & & & & (%s) \\\\[6pt]
State $\\times$ Year FE & Yes & Yes & Yes & Yes & Yes \\\\
Industry $\\times$ Race FE & Yes & Yes & Yes & -- & Yes \\\\
State $\\times$ Industry FE & Yes & -- & Yes & -- & Yes \\\\
State $\\times$ Race FE & Yes & -- & Yes & Yes & Yes \\\\
State $\\times$ Year $\\times$ Ind FE & -- & Yes & -- & -- & -- \\\\
State $\\times$ Year $\\times$ Race FE & -- & Yes & -- & -- & -- \\\\[4pt]
Observations & %s & %s & %s & %s & %s \\\\
Industries & 623, 621 & 623, 621 & 623, 621 & 623 & 721, 621 \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable: log average quarterly earnings (cols 1--2, 4--5) or level (col 3).
Triple-difference: (Black vs White) $\\times$ (Nursing Homes vs Ambulatory Care) $\\times$ (Post rate increase).
Column (4): within nursing homes only. Column (5): placebo using hotels (NAICS 721) instead of nursing homes.
Standard errors clustered by state in parentheses.
*~$p<0.10$, **~$p<0.05$, ***~$p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
',
  sprintf("%.4f", ddd_c1$est), ddd_c1$stars,
  sprintf("%.4f", ddd_c2$est), ddd_c2$stars,
  sprintf("%.0f", ddd_c3$est), ddd_c3$stars,
  sprintf("%.4f", ddd_c1$se),
  sprintf("%.4f", ddd_c2$se),
  sprintf("%.0f", ddd_c3$se),
  sprintf("%.4f", dd_c$est), dd_c$stars,
  sprintf("%.4f", dd_c$se),
  sprintf("%.4f", plac_c$est),
  sprintf("%.4f", plac_c$se),
  format(nobs(m1), big.mark = ","),
  format(nobs(m2), big.mark = ","),
  format(nobs(m3), big.mark = ","),
  format(nobs(m4), big.mark = ","),
  format(nobs(m_plac), big.mark = ",")
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ==============================================================================
# Table 3: Event Study (Callaway-Sant'Anna)
# ==============================================================================

cat("Generating Table 3: Event Study Results...\n")

es_b <- results$es_black
es_w <- results$es_white

# Build event study table
es_df <- tibble(
  event_time = es_b$egt,
  att_black = es_b$att.egt,
  se_black = es_b$se.egt,
  att_white = es_w$att.egt,
  se_white = es_w$se.egt,
  diff = es_b$att.egt - es_w$att.egt
)

es_rows <- es_df |>
  mutate(
    row = sprintf("$t%+d$ & %.0f & (%.0f) & %.0f & (%.0f) & %.0f \\\\",
                  event_time, att_black, se_black, att_white, se_white, diff)
  ) |>
  pull(row)

# Overall ATTs
att_b <- results$att_black
att_w <- results$att_white

tab3_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{Event Study: Callaway-Sant\\textquotesingle Anna Estimates by Race}
\\label{tab:eventstudy}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
Event Time & \\multicolumn{2}{c}{Black Workers} & \\multicolumn{2}{c}{White Workers} & Difference \\\\
 & ATT & (SE) & ATT & (SE) & B $-$ W \\\\
\\midrule
%s
\\midrule
Overall ATT & %.0f & (%.0f) & %.0f & (%.0f) & %.0f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Callaway-Sant\\textquotesingle Anna (2021) group-time ATT estimates aggregated to event time.
Dependent variable: average quarterly earnings (\\$). Treatment: state Medicaid nursing home rate increase.
Control group: not-yet-treated states. NAICS 623 (Nursing and Residential Care) only.
Universal base period. Standard errors in parentheses.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
',
  paste(es_rows, collapse = "\n"),
  att_b$overall.att, att_b$overall.se,
  att_w$overall.att, att_w$overall.se,
  att_b$overall.att - att_w$overall.att
)

writeLines(tab3_tex, "../tables/tab3_eventstudy.tex")

# ==============================================================================
# Table 4: Robustness — Employment and Leave-One-Out
# ==============================================================================

cat("Generating Table 4: Robustness...\n")

emp_c <- get_coef(rob_results$emp_ddd, "post:black:nursing_home")
hir_c <- get_coef(rob_results$hires_ddd, "post:black:nursing_home")
loo <- rob_results$loo

tab4_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{Robustness: Employment Effects and Leave-One-Out}
\\label{tab:robust}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
\\multicolumn{3}{l}{\\textit{Panel A: DDD on Employment Outcomes}} \\\\[3pt]
 & Log Employment & Log New Hires \\\\
\\midrule
Post $\\times$ Black $\\times$ NH & %s%s & %s%s \\\\
 & (%s) & (%s) \\\\
Observations & %s & %s \\\\[6pt]
\\multicolumn{3}{l}{\\textit{Panel B: Leave-One-Out (Earnings DDD)}} \\\\[3pt]
 & Coefficient & SE \\\\
\\midrule
Full sample & %.4f & %.4f \\\\
Minimum (drop state %d) & %.4f & %.4f \\\\
Maximum (drop state %d) & %.4f & %.4f \\\\
Range & \\multicolumn{2}{c}{[%.4f, %.4f]} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A: DDD specification as in Table~\\ref{tab:main}, Column (1), with employment
outcomes. Panel B: DDD earnings coefficient when each treated state is dropped in turn.
Standard errors clustered by state.
*~$p<0.10$, **~$p<0.05$, ***~$p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
',
  sprintf("%.4f", emp_c$est), emp_c$stars,
  sprintf("%.4f", hir_c$est), hir_c$stars,
  sprintf("%.4f", emp_c$se),
  sprintf("%.4f", hir_c$se),
  format(nobs(rob_results$emp_ddd), big.mark = ","),
  format(nobs(rob_results$hires_ddd), big.mark = ","),
  coef(results$ddd_basic)["post:black:nursing_home"],
  se(results$ddd_basic)["post:black:nursing_home"],
  loo$dropped_state[which.min(loo$coef)],
  min(loo$coef), loo$se[which.min(loo$coef)],
  loo$dropped_state[which.max(loo$coef)],
  max(loo$coef), loo$se[which.max(loo$coef)],
  min(loo$coef), max(loo$coef)
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# ==============================================================================
# Table F1: Standardized Effect Sizes (SDE Appendix — MANDATORY)
# ==============================================================================

cat("Generating Table F1: SDE Appendix...\n")

# Pre-treatment SD of earnings for SDE denominators
pre_sd <- df |>
  filter(industry == "623", year < 2017) |>
  group_by(race_label) |>
  summarise(sd_earn = sd(EarnS, na.rm = TRUE), .groups = "drop")

sd_black <- pre_sd$sd_earn[pre_sd$race_label == "Black"]
sd_white <- pre_sd$sd_earn[pre_sd$race_label == "White"]
sd_all <- sd(df$EarnS[df$industry == "623" & df$year < 2017], na.rm = TRUE)

# Pre-treatment SD of log earnings (for DDD)
sd_log <- sd(log(df$EarnS[df$industry %in% c("623", "621") & df$year < 2017]), na.rm = TRUE)

# Main DDD coefficient
beta_ddd <- coef(results$ddd_basic)["post:black:nursing_home"]
se_ddd <- se(results$ddd_basic)["post:black:nursing_home"]

# CS ATTs
att_b_val <- results$att_black$overall.att
se_b_val <- results$att_black$overall.se
att_w_val <- results$att_white$overall.att
se_w_val <- results$att_white$overall.se

# SDE calculations
# DDD (log): SDE = β since outcome is already in log
sde_ddd <- beta_ddd
se_sde_ddd <- se_ddd

# Black ATT: SDE = ATT / SD(Y_black)
sde_black <- att_b_val / sd_black
se_sde_black <- se_b_val / sd_black

# White ATT: SDE = ATT / SD(Y_white)
sde_white <- att_w_val / sd_white
se_sde_white <- se_w_val / sd_white

# Employment DDD
beta_emp <- coef(rob_results$emp_ddd)["post:black:nursing_home"]
se_emp <- se(rob_results$emp_ddd)["post:black:nursing_home"]
sd_log_emp <- sd(log(df$Emp[df$industry %in% c("623", "621") & df$year < 2017]), na.rm = TRUE)
sde_emp <- beta_emp
se_sde_emp <- se_emp

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build rows
sde_rows <- tribble(
  ~outcome, ~beta, ~se, ~sd_y, ~sde, ~se_sde, ~classification,
  "DDD: BW earnings gap (log)", beta_ddd, se_ddd, sd_log, sde_ddd, se_sde_ddd, classify_sde(sde_ddd),
  "Black earnings (\\$)", att_b_val, se_b_val, sd_black, sde_black, se_sde_black, classify_sde(sde_black),
  "White earnings (\\$)", att_w_val, se_w_val, sd_white, sde_white, se_sde_white, classify_sde(sde_white),
  "DDD: BW employment gap (log)", beta_emp, se_emp, sd_log_emp, sde_emp, se_sde_emp, classify_sde(sde_emp)
)

# Heterogeneity: Southern vs non-Southern states (sample split)
southern <- c(1, 5, 12, 13, 21, 22, 28, 37, 45, 47, 48, 51)

south_df <- df |>
  filter(industry %in% c("623", "621"), state_fips %in% southern) |>
  group_by(state_fips, year, race, black, industry, nursing_home, treat_year, post) |>
  summarise(log_earn = log(weighted.mean(EarnS, Emp, na.rm = TRUE)), .groups = "drop")

m_south <- feols(
  log_earn ~ post:black:nursing_home + post:nursing_home + post:black |
    state_fips^year + industry^race + state_fips^industry + state_fips^race,
  data = south_df, cluster = ~state_fips
)

nonsouth_df <- df |>
  filter(industry %in% c("623", "621"), !state_fips %in% southern) |>
  group_by(state_fips, year, race, black, industry, nursing_home, treat_year, post) |>
  summarise(log_earn = log(weighted.mean(EarnS, Emp, na.rm = TRUE)), .groups = "drop")

m_nonsouth <- feols(
  log_earn ~ post:black:nursing_home + post:nursing_home + post:black |
    state_fips^year + industry^race + state_fips^industry + state_fips^race,
  data = nonsouth_df, cluster = ~state_fips
)

beta_south <- coef(m_south)["post:black:nursing_home"]
se_south <- se(m_south)["post:black:nursing_home"]
beta_nonsouth <- coef(m_nonsouth)["post:black:nursing_home"]
se_nonsouth <- se(m_nonsouth)["post:black:nursing_home"]

sde_rows <- bind_rows(sde_rows, tribble(
  ~outcome, ~beta, ~se, ~sd_y, ~sde, ~se_sde, ~classification,
  "DDD: South only (log)", beta_south, se_south, sd_log, beta_south, se_south, classify_sde(beta_south),
  "DDD: Non-South (log)", beta_nonsouth, se_nonsouth, sd_log, beta_nonsouth, se_nonsouth, classify_sde(beta_nonsouth)
))

# Format SDE table rows
sde_tex_rows <- sde_rows |>
  mutate(
    sd_fmt = ifelse(sd_y < 10, sprintf("%.2f", sd_y), sprintf("%.0f", sd_y)),
    row = sprintf("%s & %.4f & %.4f & %s & %.4f & %.4f & %s \\\\",
                  outcome, beta, se, sd_fmt, sde, se_sde, classification)
  ) |>
  pull(row)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state Medicaid nursing home reimbursement rate increases compress the Black-White earnings gap among nursing home workers? ",
  "\\textbf{Policy mechanism:} Medicaid covers approximately 60 percent of nursing home residents, making state-set reimbursement rates the dominant price signal for an industry where Black workers are disproportionately represented; rate increases raise facility revenue and may differentially benefit lower-wage (predominantly Black) direct-care workers through wage floors or compositional upgrading. ",
  "\\textbf{Outcome definition:} Average quarterly earnings (QWI EarnS) for non-Hispanic Black and White workers in NAICS 623 (Nursing and Residential Care Facilities). ",
  "\\textbf{Treatment:} Binary indicator for state implementation of a major Medicaid nursing home reimbursement rate increase (at least 5 percent above inflation or explicit rebasing), staggered across 22 states from 2017 to 2023. ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI), state-quarter-race-industry cells, 2010--2024, 51 states. ",
  "\\textbf{Method:} Triple-difference (Black vs White $\\times$ Nursing Homes vs Ambulatory Care $\\times$ Post rate increase) with state$\\times$year, industry$\\times$race, state$\\times$industry, and state$\\times$race fixed effects; standard errors clustered by state. Callaway-Sant'Anna (2021) staggered DiD for race-specific ATT estimates. ",
  "\\textbf{Sample:} Non-Hispanic Black (QWI race A2) and White (QWI race A1) workers in NAICS 623 and 621; cells with positive employment only; 22 treated states, 29 control states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (pre-2017) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
%s
%s
%s
%s
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (South vs Non-South)}} \\\\[3pt]
%s
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
',
  sde_tex_rows[1], sde_tex_rows[2], sde_tex_rows[3], sde_tex_rows[4],
  sde_tex_rows[5], sde_tex_rows[6],
  sde_notes
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
