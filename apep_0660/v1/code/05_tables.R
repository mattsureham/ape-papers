# 05_tables.R — Generate all LaTeX tables
# apep_0660: FCC Cellular Lottery and Local Economic Development
# RSA design: state-level treatment timing from CMA alphabetical ordering

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))
bea_results <- readRDS(file.path(data_dir, "bea_results.rds"))

# Prepare balanced panel (same as main analysis)
panel_bal <- panel %>%
  filter(!is.na(log_emp) & is.finite(log_emp)) %>%
  group_by(fips) %>%
  filter(n() >= 15) %>%
  ungroup()

# Helper: format numbers
fmt <- function(x, digits = 3) formatC(round(x, digits), format = "f", digits = digits)
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")
stars <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
}

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================
cat("=== Table 1: Summary Statistics ===\n")

summ_vars <- panel_bal %>%
  summarize(
    emp_mean = mean(emp, na.rm = TRUE),
    emp_sd = sd(emp, na.rm = TRUE),
    emp_p25 = quantile(emp, 0.25, na.rm = TRUE),
    emp_p75 = quantile(emp, 0.75, na.rm = TRUE),
    estab_mean = mean(estab, na.rm = TRUE),
    estab_sd = sd(estab, na.rm = TRUE),
    estab_p25 = quantile(estab, 0.25, na.rm = TRUE),
    estab_p75 = quantile(estab, 0.75, na.rm = TRUE),
    payann_mean = mean(payann, na.rm = TRUE),
    payann_sd = sd(payann, na.rm = TRUE),
    payann_p25 = quantile(payann, 0.25, na.rm = TRUE),
    payann_p75 = quantile(payann, 0.75, na.rm = TRUE),
    log_emp_mean = mean(log_emp, na.rm = TRUE),
    log_emp_sd = sd(log_emp, na.rm = TRUE),
    log_estab_mean = mean(log_estab, na.rm = TRUE),
    log_estab_sd = sd(log_estab, na.rm = TRUE)
  )

n_obs <- nrow(panel_bal)
n_counties <- n_distinct(panel_bal$fips)
n_states <- n_distinct(panel_bal$state_fips)
n_years <- n_distinct(panel_bal$year)
year_range <- range(panel_bal$year)

# Treatment cohort breakdown
cohort_tab <- panel_bal %>%
  filter(year == min(year)) %>%
  count(treat_year)

tab1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Variable & Mean & Std. Dev. & P25 & P75 \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: County-Level Outcomes}} \\\\[3pt]
Employment & %s & %s & %s & %s \\\\
Establishments & %s & %s & %s & %s \\\\
Annual payroll (\\$1,000) & %s & %s & %s & %s \\\\
Log employment & %s & %s & --- & --- \\\\
Log establishments & %s & %s & --- & --- \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Treatment Assignment}} \\\\[3pt]
Treatment year & %s & %s & %s & %s \\\\
Counties in 1987 cohort & \\multicolumn{4}{c}{%s} \\\\
Counties in 1988 cohort & \\multicolumn{4}{c}{%s} \\\\
Counties in 1989 cohort & \\multicolumn{4}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} N = %s county-year observations spanning %s counties across %s states, %d--%d. Employment, establishments, and payroll are from the Census Bureau's County Business Patterns. Treatment year reflects when a state's Rural Service Area (RSA) cellular licenses were granted via the FCC lottery. RSA Cellular Market Areas (CMAs 307--734) were numbered alphabetically by state name; the FCC processed applications in CMA-number order during 1987--1989, creating staggered treatment timing across states.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
  fmt_int(round(summ_vars$emp_mean)), fmt_int(round(summ_vars$emp_sd)),
  fmt_int(round(summ_vars$emp_p25)), fmt_int(round(summ_vars$emp_p75)),
  fmt_int(round(summ_vars$estab_mean)), fmt_int(round(summ_vars$estab_sd)),
  fmt_int(round(summ_vars$estab_p25)), fmt_int(round(summ_vars$estab_p75)),
  fmt_int(round(summ_vars$payann_mean)), fmt_int(round(summ_vars$payann_sd)),
  fmt_int(round(summ_vars$payann_p25)), fmt_int(round(summ_vars$payann_p75)),
  fmt(summ_vars$log_emp_mean, 2), fmt(summ_vars$log_emp_sd, 2),
  fmt(summ_vars$log_estab_mean, 2), fmt(summ_vars$log_estab_sd, 2),
  fmt(mean(panel_bal$treat_year), 1), fmt(sd(panel_bal$treat_year), 1),
  fmt(quantile(panel_bal$treat_year, 0.25), 0),
  fmt(quantile(panel_bal$treat_year, 0.75), 0),
  fmt_int(cohort_tab$n[cohort_tab$treat_year == 1987]),
  fmt_int(cohort_tab$n[cohort_tab$treat_year == 1988]),
  fmt_int(cohort_tab$n[cohort_tab$treat_year == 1989]),
  fmt_int(n_obs), fmt_int(n_counties), fmt_int(n_states),
  year_range[1], year_range[2]
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written\n")

# ==============================================================================
# TABLE 2: Main Results (CS ATT)
# ==============================================================================
cat("=== Table 2: Main Results ===\n")

agg_emp <- results$agg_emp
agg_estab <- results$agg_estab
agg_pay <- results$agg_pay

twfe_emp <- results$twfe_emp
twfe_estab <- results$twfe_estab
twfe_pay <- results$twfe_pay

p_cs_emp <- 2 * pnorm(-abs(agg_emp$overall.att / agg_emp$overall.se))
p_cs_estab <- 2 * pnorm(-abs(agg_estab$overall.att / agg_estab$overall.se))
p_cs_pay <- 2 * pnorm(-abs(agg_pay$overall.att / agg_pay$overall.se))

p_twfe_emp <- fixest::pvalue(twfe_emp)["treated"]
p_twfe_estab <- fixest::pvalue(twfe_estab)["treated"]
p_twfe_pay <- fixest::pvalue(twfe_pay)["treated"]

ci_cs_emp <- c(agg_emp$overall.att - 1.96 * agg_emp$overall.se,
               agg_emp$overall.att + 1.96 * agg_emp$overall.se)
ci_cs_estab <- c(agg_estab$overall.att - 1.96 * agg_estab$overall.se,
                 agg_estab$overall.att + 1.96 * agg_estab$overall.se)
ci_cs_pay <- c(agg_pay$overall.att - 1.96 * agg_pay$overall.se,
               agg_pay$overall.att + 1.96 * agg_pay$overall.se)

# Payroll sample
panel_pay <- panel_bal %>% filter(!is.na(log_payann) & is.finite(log_payann) & payann > 0)

tab2 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Effect of Cellular Service on County Economic Activity}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
 & (1) & (2) & (3) \\\\
 & Log Empl. & Log Estab. & Log Payroll \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Callaway--Sant'Anna ATT}} \\\\[3pt]
Cellular service & %s%s & %s%s & %s%s \\\\
 & (%s) & (%s) & (%s) \\\\
 & [%s, %s] & [%s, %s] & [%s, %s] \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: TWFE (benchmark)}} \\\\[3pt]
Cellular service & %s%s & %s%s & %s%s \\\\
 & (%s) & (%s) & (%s) \\\\[6pt]
\\midrule
Observations & %s & %s & %s \\\\
Counties & %s & %s & %s \\\\
State clusters & %s & %s & %s \\\\
Treatment cohorts & \\multicolumn{3}{c}{3 (1987, 1988, 1989)} \\\\
Control group & \\multicolumn{3}{c}{Not-yet-treated} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses; 95\\%% confidence intervals in brackets (Panel A). * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Panel A reports the simple aggregate ATT from Callaway and Sant'Anna (2021) using not-yet-treated counties as the control group. Panel B reports two-way fixed effects (county + year FE) as a benchmark. Treatment equals one after the state's RSA cellular licenses were granted via the FCC lottery. Outcomes are in logs. Sample: U.S. counties in RSA lottery states, %d--%d.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}",
  # CS row
  fmt(agg_emp$overall.att, 4), stars(p_cs_emp),
  fmt(agg_estab$overall.att, 4), stars(p_cs_estab),
  fmt(agg_pay$overall.att, 4), stars(p_cs_pay),
  fmt(agg_emp$overall.se, 4),
  fmt(agg_estab$overall.se, 4),
  fmt(agg_pay$overall.se, 4),
  fmt(ci_cs_emp[1], 4), fmt(ci_cs_emp[2], 4),
  fmt(ci_cs_estab[1], 4), fmt(ci_cs_estab[2], 4),
  fmt(ci_cs_pay[1], 4), fmt(ci_cs_pay[2], 4),
  # TWFE row
  fmt(coef(twfe_emp)["treated"], 4), stars(p_twfe_emp),
  fmt(coef(twfe_estab)["treated"], 4), stars(p_twfe_estab),
  fmt(coef(twfe_pay)["treated"], 4), stars(p_twfe_pay),
  fmt(se(twfe_emp)["treated"], 4),
  fmt(se(twfe_estab)["treated"], 4),
  fmt(se(twfe_pay)["treated"], 4),
  # N rows
  fmt_int(n_obs), fmt_int(n_obs), fmt_int(nrow(panel_pay)),
  fmt_int(n_counties), fmt_int(n_counties), fmt_int(n_distinct(panel_pay$fips)),
  fmt_int(n_states), fmt_int(n_states), fmt_int(n_distinct(panel_pay$state_fips)),
  year_range[1], year_range[2]
)

writeLines(tab2, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 written\n")

# ==============================================================================
# TABLE 3: Event Study Coefficients
# ==============================================================================
cat("=== Table 3: Extended Pre-Trends (BEA REIS) ===\n")

# BEA event study — extended pre-trends (7 pre-treatment years)
es_bea <- bea_results$es_wages
es_bea_df <- data.frame(
  event_time = es_bea$egt,
  att = es_bea$att.egt,
  se = es_bea$se.egt
)
es_bea_df$p <- 2 * pnorm(-abs(es_bea_df$att / es_bea_df$se))
es_bea_df$ci_lo <- es_bea_df$att - 1.96 * es_bea_df$se
es_bea_df$ci_hi <- es_bea_df$att + 1.96 * es_bea_df$se

# Show pre-treatment and early post-treatment periods
es_show <- es_bea_df %>% filter(event_time >= -7 & event_time <= 5)

es_rows <- ""
for (i in seq_len(nrow(es_show))) {
  label <- ifelse(es_show$event_time[i] < 0,
                  sprintf("$k = %d$", es_show$event_time[i]),
                  sprintf("$k = +%d$", es_show$event_time[i]))
  if (is.na(es_show$se[i])) {
    es_rows <- paste0(es_rows, sprintf(
      "%s & \\multicolumn{3}{c}{\\textit{(reference period)}} \\\\\n", label))
  } else {
    es_rows <- paste0(es_rows, sprintf(
      "%s & %s%s & (%s) & [%s, %s] \\\\\n",
      label,
      fmt(es_show$att[i], 4), stars(es_show$p[i]),
      fmt(es_show$se[i], 4),
      fmt(es_show$ci_lo[i], 4), fmt(es_show$ci_hi[i], 4)
    ))
  }
}

tab3 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Extended Event Study: BEA Wages and Salaries, 1980--2005}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Event Time & ATT & SE & 95\\%% CI \\\\
\\midrule
%s\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Event-study coefficients from the Callaway--Sant'Anna (2021) estimator using BEA REIS county-level wages and salaries (1980--2005). Standard errors clustered at the state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Pre-treatment coefficients ($k < 0$) test the parallel trends assumption with 7 pre-treatment years. The aggregate CS ATT on log wages is %s (SE = %s).
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:eventstudy}
\\end{table}",
  es_rows,
  fmt(bea_results$agg_wages$overall.att, 4),
  fmt(bea_results$agg_wages$overall.se, 4)
)

writeLines(tab3, file.path(table_dir, "tab3_eventstudy.tex"))
cat("Table 3 written\n")

# ==============================================================================
# TABLE 4: Sector Heterogeneity
# ==============================================================================
cat("=== Table 4: Sector Heterogeneity ===\n")

sec_res <- robustness$sector
if (length(sec_res) > 0) {
  sec_rows <- ""
  for (sec_name in c("services", "fire", "retail", "manufacturing")) {
    if (sec_name %in% names(sec_res)) {
      s <- sec_res[[sec_name]]
      p_val <- 2 * pnorm(-abs(s$coef / s$se))
      display_name <- switch(sec_name,
        "services" = "Services (SIC 70--89)",
        "fire" = "FIRE (SIC 60--67)",
        "retail" = "Retail (SIC 52--59)",
        "manufacturing" = "Manufacturing (SIC 20--39)"
      )
      sec_rows <- paste0(sec_rows, sprintf(
        "%s & %s%s & (%s) & %s & %s \\\\\n",
        display_name,
        fmt(s$coef, 4), stars(p_val),
        fmt(s$se, 4),
        fmt_int(s$n),
        fmt_int(s$n_counties)
      ))
    }
  }

  tab4 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Sector Heterogeneity: Effect of Cellular Service on Log Employment by Industry}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Sector & Coefficient & SE & N & Counties \\\\
\\midrule
%s\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports a separate TWFE regression of log sector employment on a cellular service indicator, with county and year fixed effects. Standard errors clustered at the state level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Information-intensive sectors (Services, FIRE) are expected to benefit more from mobile communication technology than goods-producing sectors (Manufacturing). Sector-level employment is from the County Business Patterns, SIC classification.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:sectors}
\\end{table}",
    sec_rows
  )
} else {
  tab4 <- "% Table 4: No sector results available"
}

writeLines(tab4, file.path(table_dir, "tab4_sectors.tex"))
cat("Table 4 written\n")

# ==============================================================================
# TABLE 5: Robustness
# ==============================================================================
cat("=== Table 5: Robustness ===\n")

rob <- robustness
p_county <- 2 * pnorm(-abs(rob$county_cluster$coef / rob$county_cluster$se))
p_level <- 2 * pnorm(-abs(rob$level_emp$coef / rob$level_emp$se))
p_level_estab <- 2 * pnorm(-abs(rob$level_estab$coef / rob$level_estab$se))

pre_trend_str <- if (!is.null(rob$pre_trend) && length(rob$pre_trend$max_abs) > 0) {
  # Report max absolute pre-treatment coefficient
  sprintf("Max $|$pre-ATT$|$ = %s", fmt(rob$pre_trend$max_abs, 4))
} else {
  "---"
}

# Cohort-specific ATTs
cohort_rows <- ""
if (length(rob$cohort) > 0) {
  for (yr in sort(as.integer(names(rob$cohort)))) {
    c <- rob$cohort[[as.character(yr)]]
    cohort_rows <- paste0(cohort_rows, sprintf(
      "Cohort %d & %s%s & (%s) \\\\\n",
      yr, fmt(c$coef, 4), stars(c$p), fmt(c$se, 4)))
  }
}

tab5 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Robustness Checks: Effect of Cellular Service on Employment}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Specification & Estimate & SE \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel A: Baseline}} \\\\[3pt]
CS ATT, log employment & %s%s & (%s) \\\\
TWFE, log employment & %s%s & (%s) \\\\[6pt]
\\multicolumn{3}{l}{\\textit{Panel B: Cohort-specific ATTs}} \\\\[3pt]
%s\\multicolumn{3}{l}{\\textit{Panel C: Alternative inference}} \\\\[3pt]
County-clustered SEs & %s%s & (%s) \\\\[6pt]
\\multicolumn{3}{l}{\\textit{Panel D: Pre-trends and levels}} \\\\[3pt]
Pre-treatment test & \\multicolumn{2}{c}{%s} \\\\
Employment (levels) & %s%s & (%s) \\\\
Establishments (levels) & %s%s & (%s) \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reproduces the baseline CS ATT and TWFE estimates from Table~\\ref{tab:main}. Panel B reports cohort-specific ATTs from the Callaway--Sant'Anna estimator (group-level aggregation). Panel C reports the TWFE estimate with county-level clustering (less conservative than the baseline state-level clustering). Panel D reports a pre-treatment trend test (coefficient on relative time among pre-treatment observations) and level specifications. All regressions include county and year fixed effects. Standard errors clustered at the state level except where noted. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robust}
\\end{table}",
  # Panel A
  fmt(agg_emp$overall.att, 4), stars(p_cs_emp),
  fmt(agg_emp$overall.se, 4),
  fmt(coef(twfe_emp)["treated"], 4), stars(p_twfe_emp),
  fmt(se(twfe_emp)["treated"], 4),
  # Panel B
  cohort_rows,
  # Panel C
  fmt(rob$county_cluster$coef, 4), stars(p_county), fmt(rob$county_cluster$se, 4),
  # Panel D
  pre_trend_str,
  fmt(rob$level_emp$coef, 1), stars(p_level), fmt(rob$level_emp$se, 1),
  fmt(rob$level_estab$coef, 1), stars(p_level_estab), fmt(rob$level_estab$se, 1)
)

writeLines(tab5, file.path(table_dir, "tab5_robust.tex"))
cat("Table 5 written\n")

# ==============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ==============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

beta_emp <- agg_emp$overall.att
se_emp <- agg_emp$overall.se
sd_y_emp <- sd(panel_bal$log_emp, na.rm = TRUE)

beta_estab <- agg_estab$overall.att
se_estab <- agg_estab$overall.se
sd_y_estab <- sd(panel_bal$log_estab, na.rm = TRUE)

beta_pay <- agg_pay$overall.att
se_pay <- agg_pay$overall.se
sd_y_pay <- sd(panel_pay$log_payann, na.rm = TRUE)

sde_emp <- beta_emp / sd_y_emp
se_sde_emp <- se_emp / sd_y_emp

sde_estab <- beta_estab / sd_y_estab
se_sde_estab <- se_estab / sd_y_estab

sde_pay <- beta_pay / sd_y_pay
se_sde_pay <- se_pay / sd_y_pay

tabF1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{tabular}{llccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
Log employment & %s & %s & %s & %s & %s & %s \\\\
Log establishments & %s & %s & %s & %s & %s & %s \\\\
Log annual payroll & %s & %s & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\par\\vspace{0.3em}
{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$. SD($Y$) is the unconditional standard deviation.

\\textbf{Research question:} Does earlier receipt of cellular service via the FCC RSA lottery affect county-level employment, establishments, and payroll?
\\textbf{Treatment:} Binary indicator equal to one after a state's RSA cellular licenses were granted via FCC lottery.
\\textbf{Data:} County Business Patterns, %d--%d, U.S. counties in RSA lottery states.
\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator, state-clustered SEs.
\\textbf{Sample:} %s county-year observations, %s counties, %s states.

Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$). Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}
\\end{table}",
  fmt(beta_emp, 4), fmt(se_emp, 4), fmt(sd_y_emp, 3),
  fmt(sde_emp, 4), fmt(se_sde_emp, 4), classify_sde(sde_emp),
  fmt(beta_estab, 4), fmt(se_estab, 4), fmt(sd_y_estab, 3),
  fmt(sde_estab, 4), fmt(se_sde_estab, 4), classify_sde(sde_estab),
  fmt(beta_pay, 4), fmt(se_pay, 4), fmt(sd_y_pay, 3),
  fmt(sde_pay, 4), fmt(se_sde_pay, 4), classify_sde(sde_pay),
  year_range[1], year_range[2],
  fmt_int(n_obs), fmt_int(n_counties), fmt_int(n_states)
)

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 written\n")

cat("\n=== All tables generated ===\n")
cat(sprintf("Tables directory: %s\n", normalizePath(table_dir)))
cat("Files:\n")
cat(paste("  ", list.files(table_dir, pattern = "\\.tex$"), collapse = "\n"), "\n")
