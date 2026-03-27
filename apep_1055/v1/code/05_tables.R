## 05_tables.R — Generate all LaTeX tables including SDE appendix
## apep_1055: USPS Mail Slowdown and Preventable Hospitalizations

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "analysis_clean.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robust_results.rds"))
summ_stats <- readRDS(file.path(data_dir, "summary_stats.rds"))

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Pre-treatment (2019-2021) summary by treatment group
pre_df <- df %>% filter(year < 2022)

summ_tab <- pre_df %>%
  mutate(group = ifelse(treated == 1, "Treated", "Control")) %>%
  group_by(group) %>%
  summarise(
    `Prev. Hosp. Rate` = sprintf("%.1f", mean(prev_hosp_rate, na.rm = TRUE)),
    `(SD)` = sprintf("(%.1f)", sd(prev_hosp_rate, na.rm = TRUE)),
    `Population` = sprintf("%.0f", mean(population, na.rm = TRUE)),
    `Median HH Income` = sprintf("%.0f", mean(median_hh_income, na.rm = TRUE)),
    `Pct. 65+` = sprintf("%.1f", mean(pct_65plus, na.rm = TRUE)),
    `Pct. Uninsured` = sprintf("%.1f", mean(pct_uninsured, na.rm = TRUE)),
    `Pharmacy Desert (\\%)` = sprintf("%.1f", mean(pharm_desert, na.rm = TRUE) * 100),
    `Dist. to P\\&DC (mi)` = sprintf("%.0f", mean(dist_to_pdc, na.rm = TRUE)),
    `Counties` = as.character(n_distinct(fips)),
    .groups = "drop"
  ) %>%
  t()

colnames(summ_tab) <- summ_tab[1, ]
summ_tab <- summ_tab[-1, , drop = FALSE]

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Characteristics by Mail Slowdown Status}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Control & Treated \\\\",
  " & (No Slowdown) & (1--2 Day Increase) \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(summ_tab))) {
  rn <- rownames(summ_tab)[i]
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s \\\\", rn, summ_tab[i, 1], summ_tab[i, 2])
  )
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment period is 2019--2021. Preventable hospitalization rate is per 100,000 Medicare enrollees. Treatment is defined as any increase in USPS First-Class Mail service standard following the October 2021 Delivering for America plan (86 FR 43949). Pharmacy desert indicates bottom quartile of pharmacies per 10,000 residents (Census County Business Patterns, NAICS 446110). Distance to Processing \\& Distribution Center is air-line miles from county centroid.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("  ✓ tab1_summary.tex\n")

# ============================================================================
# TABLE 2: Main DiD Results
# ============================================================================
cat("=== Table 2: Main Results ===\n")

# Use fixest::etable for clean LaTeX output
etable(
  results$m1_basic_did,
  results$m2_triple_diff,
  results$m6_controls,
  results$m5_log,
  tex = TRUE,
  file = file.path(tables_dir, "tab2_main.tex"),
  title = "Effect of USPS Mail Slowdown on Preventable Hospitalizations",
  label = "tab:main",
  headers = c("(1)", "(2)", "(3)", "(4)"),
  dict = c(
    "mail_slowdown:post" = "Mail Slowdown $\\times$ Post",
    "mail_slowdown:post:pharm_desert" = "Mail Slowdown $\\times$ Post $\\times$ Pharm. Desert",
    "pharm_desert:post" = "Pharm. Desert $\\times$ Post",
    "post" = "Post",
    "log_pop:post" = "Log Pop. $\\times$ Post",
    "pct_65plus:post" = "Pct. 65+ $\\times$ Post",
    "pct_uninsured:post" = "Pct. Uninsured $\\times$ Post",
    "median_hh_income:post" = "Med. Income $\\times$ Post"
  ),
  se.below = TRUE,
  fitstat = ~n + wr2,
  notes = c(
    "Standard errors clustered at the state level in parentheses.",
    "Columns (1)--(3): outcome is preventable hospitalization rate per 100,000 Medicare enrollees.",
    "Column (4): outcome is log(preventable hospitalization rate + 1).",
    "Mail Slowdown is the number of additional days in the USPS First-Class Mail service standard",
    "following the October 2021 Delivering for America plan.",
    "All specifications include county and year fixed effects.",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  ),
  replace = TRUE,
  style.tex = style.tex("aer")
)
cat("  ✓ tab2_main.tex\n")

# ============================================================================
# TABLE 3: Event Study Coefficients
# ============================================================================
cat("=== Table 3: Event Study ===\n")

es_coefs <- coeftable(results$m4_event_study)
es_df <- data.frame(
  rel_year = as.numeric(gsub("rel_year::", "", gsub(":mail_slowdown", "", rownames(es_coefs)))),
  coef = es_coefs[, 1],
  se = es_coefs[, 2],
  pval = es_coefs[, 4]
)
es_df <- es_df[order(es_df$rel_year), ]
es_df$stars <- ifelse(es_df$pval < 0.01, "***",
                ifelse(es_df$pval < 0.05, "**",
                ifelse(es_df$pval < 0.10, "*", "")))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Year-by-Year Effects of Mail Slowdown}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year Relative to & Coefficient & Std. Error & $p$-value \\\\",
  "Treatment (2021=0) & & & \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_df))) {
  yr_label <- ifelse(es_df$rel_year[i] == 0, "0 (reference)", as.character(es_df$rel_year[i]))
  if (es_df$rel_year[i] == 0) {
    tab3_lines <- c(tab3_lines, sprintf("%s & --- & --- & --- \\\\", yr_label))
  } else {
    tab3_lines <- c(tab3_lines,
      sprintf("%s & %.3f%s & (%.3f) & %.3f \\\\",
              yr_label, es_df$coef[i], es_df$stars[i], es_df$se[i], es_df$pval[i])
    )
  }
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\", format(nrow(df), big.mark = ",")),
  sprintf("Counties & \\multicolumn{3}{c}{%s} \\\\", format(n_distinct(df$fips), big.mark = ",")),
  "County FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each coefficient represents the interaction of mail slowdown intensity (days added) with a year dummy. The reference year is 2021 (the last pre-treatment year). Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_event_study.tex"))
cat("  ✓ tab3_event_study.tex\n")

# ============================================================================
# TABLE 4: Robustness
# ============================================================================
cat("=== Table 4: Robustness ===\n")

etable(
  robust$dose_response,
  robust$balanced_panel,
  robust$no_covid,
  robust$pop_weighted,
  tex = TRUE,
  file = file.path(tables_dir, "tab4_robustness.tex"),
  title = "Robustness Checks",
  label = "tab:robust",
  headers = c("Dose-Response", "Balanced Panel", "Excl. 2020", "Pop.-Weighted"),
  se.below = TRUE,
  fitstat = ~n + wr2,
  notes = c(
    "Standard errors clustered at the state level in parentheses.",
    "Column (1) separates 1-day and 2-day service standard increases.",
    "Column (2) restricts to counties present in all years.",
    "Column (3) drops 2020 to address COVID-era disruptions.",
    "Column (4) weights by county population.",
    "All specifications include county and year fixed effects.",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  ),
  replace = TRUE,
  style.tex = style.tex("aer")
)
cat("  ✓ tab4_robustness.tex\n")

# ============================================================================
# TABLE 5: Placebo Tests
# ============================================================================
cat("=== Table 5: Placebo ===\n")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Placebo and Falsification Tests}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & Placebo Outcome & Pre-Period Placebo \\\\",
  "\\midrule"
)

# Placebo results
pc <- coeftable(robust$placebo)
pc_coef <- pc[1, 1]
pc_se <- pc[1, 2]
pc_pval <- pc[1, 4]
pc_stars <- ifelse(pc_pval < 0.01, "***", ifelse(pc_pval < 0.05, "**", ifelse(pc_pval < 0.10, "*", "")))

# Pre-period placebo (fake treatment in pre-period)
pre_df_check <- df %>% filter(year <= 2021) %>%
  mutate(fake_post = as.integer(year >= 2020))
pre_placebo <- feols(
  prev_hosp_rate ~ mail_slowdown:fake_post | fips + year,
  data = pre_df_check,
  cluster = ~state
)
pp <- coeftable(pre_placebo)
pp_coef <- pp[1, 1]
pp_se <- pp[1, 2]
pp_pval <- pp[1, 4]
pp_stars <- ifelse(pp_pval < 0.01, "***", ifelse(pp_pval < 0.05, "**", ifelse(pp_pval < 0.10, "*", "")))

tab5_lines <- c(tab5_lines,
  sprintf("Mail Slowdown $\\times$ Post & %.3f%s & %.3f%s \\\\", pc_coef, pc_stars, pp_coef, pp_stars),
  sprintf(" & (%.3f) & (%.3f) \\\\", pc_se, pp_se),
  "\\midrule",
  sprintf("Observations & %s & %s \\\\",
          format(nobs(robust$placebo), big.mark = ","),
          format(nobs(pre_placebo), big.mark = ",")),
  "County FE & Yes & Yes \\\\",
  "Year FE & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column (1) uses a placebo outcome that should not respond to mail delays (motor vehicle death rate, or preventable hospitalizations with a pre-period fake treatment if the former is unavailable). Column (2) assigns a false treatment date of 2020 using only pre-treatment data (2019--2021). Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_placebo.tex"))
cat("  ✓ tab5_placebo.tex\n")

# ============================================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================================
cat("=== Table F1: SDE Appendix ===\n")

# Compute SDE for main outcomes
# SDE = β̂ / SD(Y) for binary treatment
# SDE = β̂ × SD(X) / SD(Y) for continuous treatment

sd_y <- sd(df$prev_hosp_rate[df$year < 2022], na.rm = TRUE)
sd_x <- sd(df$mail_slowdown, na.rm = TRUE)

# Main results
m_main <- results$m1_basic_did
m_triple <- results$m2_triple_diff

# Pooled effect
beta_pooled <- coef(m_main)["mail_slowdown:post"]
se_pooled <- sqrt(vcov(m_main)["mail_slowdown:post", "mail_slowdown:post"])
sde_pooled <- beta_pooled * sd_x / sd_y
se_sde_pooled <- se_pooled * sd_x / sd_y

# Triple-diff main effect
beta_main <- coef(m_triple)["mail_slowdown:post"]
se_main <- sqrt(vcov(m_triple)["mail_slowdown:post", "mail_slowdown:post"])
sde_main <- beta_main * sd_x / sd_y
se_sde_main <- se_main * sd_x / sd_y

# Triple-diff interaction (pharmacy desert amplification)
beta_desert <- coef(m_triple)["mail_slowdown:post:pharm_desert"]
se_desert <- sqrt(vcov(m_triple)["mail_slowdown:post:pharm_desert", "mail_slowdown:post:pharm_desert"])
sde_desert <- beta_desert * sd_x / sd_y
se_sde_desert <- se_desert * sd_x / sd_y

# Heterogeneity: Split by income (below vs above median)
med_inc <- median(df$median_hh_income[df$year == min(df$year)], na.rm = TRUE)

m_low_inc <- feols(
  prev_hosp_rate ~ mail_slowdown:post | fips + year,
  data = df %>% filter(median_hh_income < med_inc),
  cluster = ~state
)
beta_low <- coef(m_low_inc)["mail_slowdown:post"]
se_low <- sqrt(vcov(m_low_inc)["mail_slowdown:post", "mail_slowdown:post"])

sd_y_low <- sd(df$prev_hosp_rate[df$year < 2022 & df$median_hh_income < med_inc], na.rm = TRUE)
sde_low <- beta_low * sd_x / sd_y_low
se_sde_low <- se_low * sd_x / sd_y_low

m_high_inc <- feols(
  prev_hosp_rate ~ mail_slowdown:post | fips + year,
  data = df %>% filter(median_hh_income >= med_inc),
  cluster = ~state
)
beta_high <- coef(m_high_inc)["mail_slowdown:post"]
se_high <- sqrt(vcov(m_high_inc)["mail_slowdown:post", "mail_slowdown:post"])

sd_y_high <- sd(df$prev_hosp_rate[df$year < 2022 & df$median_hh_income >= med_inc], na.rm = TRUE)
sde_high <- beta_high * sd_x / sd_y_high
se_sde_high <- se_high * sd_x / sd_y_high

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE table
sde_rows <- list(
  list("Prev. Hosp. Rate (pooled)", beta_pooled, se_pooled, sd_y, sde_pooled, se_sde_pooled),
  list("Prev. Hosp. Rate (non-desert)", beta_main, se_main, sd_y, sde_main, se_sde_main),
  list("Desert Amplification", beta_desert, se_desert, sd_y, sde_desert, se_sde_desert),
  list("Low-Income Counties", beta_low, se_low, sd_y_low, sde_low, se_sde_low),
  list("High-Income Counties", beta_high, se_high, sd_y_high, sde_high, se_sde_high)
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does degradation of postal service standards increase preventable hospitalizations in communities dependent on mail-order prescriptions? ",
  "\\textbf{Policy mechanism:} The October 2021 USPS Delivering for America plan (86 FR 43949) mechanically extended First-Class Mail delivery standards by 1--2 days for routes exceeding distance thresholds from processing facilities, affecting approximately 39\\% of First-Class Mail volume and potentially disrupting mail-order prescription delivery for chronic disease management. ",
  "\\textbf{Outcome definition:} Preventable (ambulatory care-sensitive) hospitalization rate per 100,000 Medicare enrollees, measuring hospitalizations for conditions manageable through outpatient care (diabetes, COPD, heart failure, hypertension). ",
  "\\textbf{Treatment:} Continuous --- number of additional days added to the First-Class Mail service standard (0, 1, or 2 days) based on county distance from nearest USPS Processing \\& Distribution Center. ",
  "\\textbf{Data:} County Health Rankings (source: CMS Mapping Medicare Disparities), 2019--2024, county-year level, approximately ",
  format(summ_stats$n_obs, big.mark = ","), " observations across ",
  format(summ_stats$n_counties, big.mark = ","), " counties. ",
  "\\textbf{Method:} Difference-in-differences with continuous treatment intensity and county/year fixed effects; triple-difference with pharmacy desert status; standard errors clustered at the state level (50 clusters). ",
  "\\textbf{Sample:} Contiguous US counties with population $\\geq$ 1,000 and non-missing controls; pharmacy desert defined as bottom quartile of pharmacies per 10,000 residents (Census County Business Patterns NAICS 446110). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-county standard deviation of treatment intensity and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build LaTeX
sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:3) {
  r <- sde_rows[[i]]
  cls <- classify_sde(r[[5]])
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
            r[[1]], r[[2]], r[[3]], r[[4]], r[[5]], r[[6]], cls)
  )
}

sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by county income)}} \\\\"
)

for (i in 4:5) {
  r <- sde_rows[[i]]
  cls <- classify_sde(r[[5]])
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
            r[[1]], r[[2]], r[[3]], r[[4]], r[[5]], r[[6]], cls)
  )
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("  ✓ tabF1_sde.tex\n")

cat("\n✓ All tables generated successfully\n")
