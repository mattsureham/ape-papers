# 05_tables.R — Generate all LaTeX tables
# apep_1335: Cannabis Lottery and Local Economic Renewal

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Helper: format number with stars
fmt_coef <- function(est, se, digits = 4) {
  pval <- 2 * pnorm(-abs(est / se))
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.1, "*", "")))
  sprintf("%s%s", formatC(est, format = "f", digits = digits), stars)
}

fmt_se <- function(se, digits = 4) {
  sprintf("(%s)", formatC(se, format = "f", digits = digits))
}

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

cat("=== Table 1: Summary Statistics ===\n")

pre_panel <- panel %>% filter(time_period < 14)

# Compute stats by group
compute_stats <- function(df, var, label) {
  data.frame(
    Variable = label,
    mean_treated = mean(df[[var]][df$first_treat > 0], na.rm = TRUE),
    sd_treated = sd(df[[var]][df$first_treat > 0], na.rm = TRUE),
    mean_control = mean(df[[var]][df$first_treat == 0], na.rm = TRUE),
    sd_control = sd(df[[var]][df$first_treat == 0], na.rm = TRUE)
  )
}

stats_rows <- bind_rows(
  compute_stats(pre_panel, "emp_retail", "Retail employment (NAICS 44-45)"),
  compute_stats(pre_panel, "emp_food", "Food service employment (NAICS 7225)"),
  compute_stats(pre_panel, "emp_total", "Total private employment"),
  compute_stats(pre_panel, "earn_retail", "Retail quarterly earnings (\\$)"),
  compute_stats(pre_panel, "earn_total", "Total quarterly earnings (\\$)")
)

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Pre-Treatment Summary Statistics by Treatment Status}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Treated Counties} & \\multicolumn{2}{c}{Never-Treated Counties} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD \\\\",
  "\\hline"
)

for (i in seq_len(nrow(stats_rows))) {
  row <- stats_rows[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s \\\\",
    row$Variable,
    formatC(row$mean_treated, format = "f", digits = 0, big.mark = ","),
    formatC(row$sd_treated, format = "f", digits = 0, big.mark = ","),
    formatC(row$mean_control, format = "f", digits = 0, big.mark = ","),
    formatC(row$sd_control, format = "f", digits = 0, big.mark = ",")
  ))
}

n_treated <- n_distinct(panel$county_fips[panel$first_treat > 0])
n_control <- n_distinct(panel$county_fips[panel$first_treat == 0])

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          n_treated, n_control),
  sprintf("County-quarters & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          formatC(nrow(pre_panel[pre_panel$first_treat > 0, ]), big.mark = ","),
          formatC(nrow(pre_panel[pre_panel$first_treat == 0, ]), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment (2018Q1--2021Q2) means and standard deviations of county-quarter employment and earnings from Census QWI. Treated counties are those receiving at least one lottery-allocated cannabis dispensary license after July 2021. Employment is measured as beginning-of-quarter employment counts. Earnings are average monthly earnings at beginning of quarter.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ============================================================================
# TABLE 2: Main Results (CS DiD)
# ============================================================================

cat("=== Table 2: Main Results ===\n")

# Extract ATT estimates
att_r <- results$att_retail
att_f <- results$att_food
att_t <- results$att_total
att_e <- results$att_earn

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Lottery Dispensary Entry on Local Employment and Earnings}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Retail & Food Service & Total & Retail \\\\",
  " & Employment & Employment & Employment & Earnings \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway-Sant'Anna (not-yet-treated)}} \\\\[3pt]",
  sprintf("ATT & %s & %s & %s & %s \\\\",
    fmt_coef(att_r$overall.att, att_r$overall.se),
    fmt_coef(att_f$overall.att, att_f$overall.se),
    fmt_coef(att_t$overall.att, att_t$overall.se),
    fmt_coef(att_e$overall.att, att_e$overall.se)),
  sprintf(" & %s & %s & %s & %s \\\\[3pt]",
    fmt_se(att_r$overall.se),
    fmt_se(att_f$overall.se),
    fmt_se(att_t$overall.se),
    fmt_se(att_e$overall.se))
)

# Add TWFE comparison
tw_r <- results$twfe_retail
tw_f <- results$twfe_food
tw_t <- results$twfe_total
tw_e <- results$twfe_earn

tab2_lines <- c(tab2_lines,
  "\\multicolumn{5}{l}{\\textit{Panel B: Two-Way Fixed Effects}} \\\\[3pt]",
  sprintf("Treated & %s & %s & %s & %s \\\\",
    fmt_coef(coef(tw_r)["treated"], sqrt(vcov(tw_r)["treated", "treated"])),
    fmt_coef(coef(tw_f)["treated"], sqrt(vcov(tw_f)["treated", "treated"])),
    fmt_coef(coef(tw_t)["treated"], sqrt(vcov(tw_t)["treated", "treated"])),
    fmt_coef(coef(tw_e)["treated"], sqrt(vcov(tw_e)["treated", "treated"]))),
  sprintf(" & %s & %s & %s & %s \\\\[6pt]",
    fmt_se(sqrt(vcov(tw_r)["treated", "treated"])),
    fmt_se(sqrt(vcov(tw_f)["treated", "treated"])),
    fmt_se(sqrt(vcov(tw_t)["treated", "treated"])),
    fmt_se(sqrt(vcov(tw_e)["treated", "treated"]))),
  "\\hline",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    formatC(nobs(tw_r), big.mark = ","),
    formatC(nobs(tw_f), big.mark = ","),
    formatC(nobs(tw_t), big.mark = ","),
    formatC(nobs(tw_e), big.mark = ",")),
  sprintf("Counties & %d & %d & %d & %d \\\\",
    102, 102, 102, 102),
  sprintf("Treated counties & %d & %d & %d & %d \\\\",
    n_treated, n_treated, n_treated, n_treated),
  "Clustering & County & County & County & County \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log employment or log earnings at the county-quarter level. Panel~A reports Callaway and Sant'Anna (2021) doubly-robust estimates using not-yet-treated counties as the comparison group. Panel~B reports standard two-way fixed effects estimates. Treatment is defined as the quarter in which the first lottery-allocated cannabis dispensary opens in a county (license date plus two-quarter buildout lag). Standard errors clustered at the county level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# ============================================================================
# TABLE 3: Event Study Coefficients (Food Service)
# ============================================================================

cat("=== Table 3: Event Study ===\n")

es_f <- results$es_food

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Food Service Employment Response to Lottery Dispensary Entry}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Event time & Estimate & Std. Error & 95\\% CI \\\\",
  "\\hline"
)

for (i in seq_along(es_f$egt)) {
  e <- es_f$egt[i]
  est <- es_f$att.egt[i]
  se_val <- es_f$se.egt[i]
  ci_lo <- est - 1.96 * se_val
  ci_hi <- est + 1.96 * se_val

  prefix <- ifelse(e == -1, "\\textit{", "")
  suffix <- ifelse(e == -1, "} (ref.)", "")

  tab3_lines <- c(tab3_lines, sprintf(
    "%s$t %+d$%s & %s & %s & [%s, %s] \\\\",
    prefix, e, suffix,
    fmt_coef(est, se_val),
    formatC(se_val, format = "f", digits = 4),
    formatC(ci_lo, format = "f", digits = 4),
    formatC(ci_hi, format = "f", digits = 4)
  ))
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  "\\multicolumn{4}{l}{Overall ATT (post-treatment):} \\\\",
  sprintf(" & %s & %s & \\\\",
    fmt_coef(es_f$overall.att, es_f$overall.se),
    fmt_se(es_f$overall.se)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) event-study estimates for log food service employment (NAICS 7225). Event time 0 is the quarter of first lottery dispensary opening. Estimation uses doubly-robust method with not-yet-treated comparison group. Standard errors based on multiplier bootstrap with 1,000 iterations. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_eventstudy.tex"))
cat("Table 3 written.\n")

# ============================================================================
# TABLE 4: Robustness
# ============================================================================

cat("=== Table 4: Robustness ===\n")

att_nt <- robustness$att_food_nt
att_lg <- robustness$att_food_large
att_mfg <- robustness$att_mfg

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Specification & ATT & SE \\\\",
  "\\hline",
  "\\multicolumn{3}{l}{\\textit{Panel A: Food Service Employment (main outcome)}} \\\\[3pt]",
  sprintf("Baseline (not-yet-treated) & %s & %s \\\\",
    fmt_coef(results$att_food$overall.att, results$att_food$overall.se),
    fmt_se(results$att_food$overall.se)),
  sprintf("Never-treated controls & %s & %s \\\\",
    fmt_coef(att_nt$overall.att, att_nt$overall.se),
    fmt_se(att_nt$overall.se))
)

if (!is.null(att_lg)) {
  tab4_lines <- c(tab4_lines,
    sprintf("Large counties only & %s & %s \\\\",
      fmt_coef(att_lg$overall.att, att_lg$overall.se),
      fmt_se(att_lg$overall.se)))
}

tab4_lines <- c(tab4_lines,
  "[6pt]",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo Outcomes}} \\\\[3pt]"
)

if (!is.null(att_mfg)) {
  tab4_lines <- c(tab4_lines,
    sprintf("Manufacturing employment & %s & %s \\\\",
      fmt_coef(att_mfg$overall.att, att_mfg$overall.se),
      fmt_se(att_mfg$overall.se)))
}

tab4_lines <- c(tab4_lines,
  sprintf("Retail employment & %s & %s \\\\",
    fmt_coef(results$att_retail$overall.att, results$att_retail$overall.se),
    fmt_se(results$att_retail$overall.se)),
  sprintf("Total employment & %s & %s \\\\",
    fmt_coef(results$att_total$overall.att, results$att_total$overall.se),
    fmt_se(results$att_total$overall.se)),
  sprintf("Retail earnings & %s & %s \\\\",
    fmt_coef(results$att_earn$overall.att, results$att_earn$overall.se),
    fmt_se(results$att_earn$overall.se)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All specifications use Callaway and Sant'Anna (2021) doubly-robust estimator. Panel~A varies the comparison group and sample for food service employment. Panel~B tests outcomes that should not respond to dispensary entry. Manufacturing employment (NAICS 31-33) serves as the primary placebo. Standard errors from multiplier bootstrap (1,000 iterations). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ============================================================================

cat("=== Table F1: SDE ===\n")

# Compute SD(Y) from pre-treatment period
pre_sds <- panel %>%
  filter(time_period < 14) %>%
  summarise(
    sd_retail = sd(log_emp_retail, na.rm = TRUE),
    sd_food = sd(log_emp_food, na.rm = TRUE),
    sd_total = sd(log_emp_total, na.rm = TRUE),
    sd_earn = sd(log_earn_retail, na.rm = TRUE)
  )

# SDE = beta_hat / SD(Y) for binary treatment
sde_retail <- results$att_retail$overall.att / pre_sds$sd_retail
sde_food <- results$att_food$overall.att / pre_sds$sd_food
sde_total <- results$att_total$overall.att / pre_sds$sd_total
sde_earn <- results$att_earn$overall.att / pre_sds$sd_earn

se_sde_retail <- results$att_retail$overall.se / pre_sds$sd_retail
se_sde_food <- results$att_food$overall.se / pre_sds$sd_food
se_sde_total <- results$att_total$overall.se / pre_sds$sd_total
se_sde_earn <- results$att_earn$overall.se / pre_sds$sd_earn

# Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled results
sde_rows_a <- data.frame(
  Outcome = c("Retail employment", "Food service employment",
               "Total employment", "Retail earnings"),
  beta = c(results$att_retail$overall.att, results$att_food$overall.att,
           results$att_total$overall.att, results$att_earn$overall.att),
  se = c(results$att_retail$overall.se, results$att_food$overall.se,
         results$att_total$overall.se, results$att_earn$overall.se),
  sd_y = c(pre_sds$sd_retail, pre_sds$sd_food, pre_sds$sd_total, pre_sds$sd_earn),
  sde = c(sde_retail, sde_food, sde_total, sde_earn),
  se_sde = c(se_sde_retail, se_sde_food, se_sde_total, se_sde_earn)
)
sde_rows_a$Classification <- sapply(sde_rows_a$sde, classify_sde)

# Panel B: Heterogeneity (large counties)
sde_het <- if (!is.null(robustness$att_food_large)) {
  att_lg <- robustness$att_food_large
  sde_lg <- att_lg$overall.att / pre_sds$sd_food
  se_sde_lg <- att_lg$overall.se / pre_sds$sd_food
  data.frame(
    Outcome = "Food service (large counties)",
    beta = att_lg$overall.att,
    se = att_lg$overall.se,
    sd_y = pre_sds$sd_food,
    sde = sde_lg,
    se_sde = se_sde_lg,
    Classification = classify_sde(sde_lg)
  )
} else NULL

# Placebo heterogeneity
sde_placebo <- if (!is.null(robustness$att_mfg)) {
  att_m <- robustness$att_mfg
  sd_mfg <- panel %>%
    filter(time_period < 14, !is.na(log_emp_food)) %>%
    summarise(s = sd(log_emp_total, na.rm = TRUE)) %>%
    pull(s)
  sde_m <- att_m$overall.att / sd_mfg
  se_sde_m <- att_m$overall.se / sd_mfg
  data.frame(
    Outcome = "Manufacturing (placebo)",
    beta = att_m$overall.att,
    se = att_m$overall.se,
    sd_y = sd_mfg,
    sde = sde_m,
    se_sde = se_sde_m,
    Classification = classify_sde(sde_m)
  )
} else NULL

sde_rows_b <- bind_rows(sde_het, sde_placebo)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does lottery-based allocation of cannabis dispensary licenses to social equity applicants generate local employment and earnings gains in Illinois counties? ",
  "\\textbf{Policy mechanism:} Illinois distributed 185 adult-use cannabis dispensary licenses through random lotteries (2021--2023) as part of the Cannabis Regulation and Tax Act social equity program, creating exogenous variation in new retail cannabis market entry across counties. ",
  "\\textbf{Outcome definition:} Log beginning-of-quarter employment counts from Census QWI, by NAICS industry (44-45 retail, 7225 food service, total private). ",
  "\\textbf{Treatment:} Binary; whether a county has received its first lottery-allocated dispensary (license date plus two-quarter buildout lag). ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI) and IDFPR dispensary license records, 2018Q1--2024Q4, 102 Illinois counties, 2,856 county-quarter observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) doubly-robust staggered DiD with not-yet-treated comparison group; standard errors from multiplier bootstrap (1,000 iterations) clustered at county level. ",
  "\\textbf{Sample:} All 102 Illinois counties; 36 treated (receiving lottery dispensaries), 66 never-treated. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in seq_len(nrow(sde_rows_a))) {
  r <- sde_rows_a[i, ]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    r$Outcome,
    formatC(r$beta, format = "f", digits = 4),
    formatC(r$se, format = "f", digits = 4),
    formatC(r$sd_y, format = "f", digits = 4),
    formatC(r$sde, format = "f", digits = 4),
    formatC(r$se_sde, format = "f", digits = 4),
    r$Classification
  ))
}

if (!is.null(sde_rows_b) && nrow(sde_rows_b) > 0) {
  tabF1_lines <- c(tabF1_lines,
    "[6pt]",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\[3pt]"
  )
  for (i in seq_len(nrow(sde_rows_b))) {
    r <- sde_rows_b[i, ]
    tabF1_lines <- c(tabF1_lines, sprintf(
      "%s & %s & %s & %s & %s & %s & %s \\\\",
      r$Outcome,
      formatC(r$beta, format = "f", digits = 4),
      formatC(r$se, format = "f", digits = 4),
      formatC(r$sd_y, format = "f", digits = 4),
      formatC(r$sde, format = "f", digits = 4),
      formatC(r$se_sde, format = "f", digits = 4),
      r$Classification
    ))
  }
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
cat("Files:", paste(list.files(tables_dir), collapse = ", "), "\n")
