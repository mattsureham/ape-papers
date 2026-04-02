# 03_main_analysis.R — Main regression analysis for apep_1319
# Continuous-treatment DiD: ASB toolkit consolidation

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load cleaned panel
df <- fread(file.path(data_dir, "asb_panel_clean.csv"))
df[, year_month := as.Date(year_month)]

cat("Panel loaded:", nrow(df), "obs,", uniqueN(df$cjs_area), "forces\n")

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

cat("\n=== Summary Statistics ===\n")

# Pre-period summary
pre <- df[post == 0]
post_df <- df[post == 1]

sumstats <- data.table(
  Variable = c(
    "ASB incidents (monthly)", "ASB rate per 100k",
    "Burglary incidents (monthly)", "Burglary rate per 100k",
    "ASBO issuance total (1999-2013)", "ASBO rate per 100k",
    "Population (2014)"
  ),
  `Pre-Mean` = c(
    round(mean(pre$asb_count, na.rm = TRUE), 0),
    round(mean(pre$asb_rate, na.rm = TRUE), 1),
    round(mean(pre$burglary_count, na.rm = TRUE), 0),
    round(mean(pre$burglary_rate, na.rm = TRUE), 1),
    round(mean(df[, first(asbo_total), by = cjs_area]$V1), 0),
    round(mean(df[, first(asbo_rate_pc), by = cjs_area]$V1), 1),
    round(mean(df[, first(population_2014), by = cjs_area]$V1), 0)
  ),
  `Pre-SD` = c(
    round(sd(pre$asb_count, na.rm = TRUE), 0),
    round(sd(pre$asb_rate, na.rm = TRUE), 1),
    round(sd(pre$burglary_count, na.rm = TRUE), 0),
    round(sd(pre$burglary_rate, na.rm = TRUE), 1),
    round(sd(df[, first(asbo_total), by = cjs_area]$V1), 0),
    round(sd(df[, first(asbo_rate_pc), by = cjs_area]$V1), 1),
    round(sd(df[, first(population_2014), by = cjs_area]$V1), 0)
  ),
  `Post-Mean` = c(
    round(mean(post_df$asb_count, na.rm = TRUE), 0),
    round(mean(post_df$asb_rate, na.rm = TRUE), 1),
    round(mean(post_df$burglary_count, na.rm = TRUE), 0),
    round(mean(post_df$burglary_rate, na.rm = TRUE), 1),
    NA_real_, NA_real_, NA_real_
  ),
  N = c(
    nrow(df), nrow(df),
    sum(!is.na(df$burglary_count)), sum(!is.na(df$burglary_count)),
    uniqueN(df$cjs_area), uniqueN(df$cjs_area), uniqueN(df$cjs_area)
  )
)

print(sumstats)

# Write summary stats table to LaTeX
sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & Pre-Reform Mean & Pre-Reform SD & Post-Reform Mean & N \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Outcome Variables (force $\\times$ month)}} \\\\\n")
cat(sprintf("ASB incidents & %s & %s & %s & %s \\\\\n",
            format(sumstats$`Pre-Mean`[1], big.mark = ","),
            format(sumstats$`Pre-SD`[1], big.mark = ","),
            format(sumstats$`Post-Mean`[1], big.mark = ","),
            format(sumstats$N[1], big.mark = ",")))
cat(sprintf("ASB rate per 100k & %.1f & %.1f & %.1f & %s \\\\\n",
            sumstats$`Pre-Mean`[2], sumstats$`Pre-SD`[2], sumstats$`Post-Mean`[2],
            format(sumstats$N[2], big.mark = ",")))
cat(sprintf("Burglary incidents & %s & %s & %s & %s \\\\\n",
            format(sumstats$`Pre-Mean`[3], big.mark = ","),
            format(sumstats$`Pre-SD`[3], big.mark = ","),
            format(sumstats$`Post-Mean`[3], big.mark = ","),
            format(sumstats$N[3], big.mark = ",")))
cat(sprintf("Burglary rate per 100k & %.1f & %.1f & %.1f & %s \\\\\n",
            sumstats$`Pre-Mean`[4], sumstats$`Pre-SD`[4], sumstats$`Post-Mean`[4],
            format(sumstats$N[4], big.mark = ",")))
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Treatment Intensity (cross-section)}} \\\\\n")
cat(sprintf("ASBO total (1999--2013) & %s & %s & --- & %d \\\\\n",
            format(sumstats$`Pre-Mean`[5], big.mark = ","),
            format(sumstats$`Pre-SD`[5], big.mark = ","),
            sumstats$N[5]))
cat(sprintf("ASBO rate per 100k & %.1f & %.1f & --- & %d \\\\\n",
            sumstats$`Pre-Mean`[6], sumstats$`Pre-SD`[6], sumstats$N[6]))
cat(sprintf("Population (mid-2014) & %s & %s & --- & %d \\\\\n",
            format(sumstats$`Pre-Mean`[7], big.mark = ","),
            format(sumstats$`Pre-SD`[7], big.mark = ","),
            sumstats$N[7]))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Panel A reports force-by-month observations from May 2013 to December 2019. ")
cat("Pre-reform period is May 2013--September 2014; post-reform begins November 2014 (October 2014 excluded as partial treatment month). ")
cat("Panel B reports cross-sectional treatment intensity. ASBO totals are cumulative Anti-Social Behaviour Orders issued 1999--2013 from the Home Office Statistical Bulletin. ")
cat("Population is ONS mid-2014 estimate by police force area.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 1 saved.\n")

# ============================================================================
# TABLE 2: Main Results — Continuous-Treatment DiD
# ============================================================================

cat("\n=== Main Regressions ===\n")

# Model 1: Basic DiD with force and time FE
m1 <- feols(asb_rate ~ post_asbo_std | cjs_area + year_month,
            data = df, cluster = ~cjs_area)

# Model 2: Add force-specific linear trends
df[, force_trend := as.integer(year_month - min(year_month))]
m2 <- feols(asb_rate ~ post_asbo_std + i(cjs_area, force_trend) | cjs_area + year_month,
            data = df, cluster = ~cjs_area)

# Model 3: Use log outcome
df[, log_asb_rate := log(asb_rate + 1)]
m3 <- feols(log_asb_rate ~ post_asbo_std | cjs_area + year_month,
            data = df, cluster = ~cjs_area)

# Model 4: Use raw ASBO rate (unstandardized) for magnitude interpretation
m4 <- feols(asb_rate ~ post_asbo | cjs_area + year_month,
            data = df, cluster = ~cjs_area)

cat("\nModel 1 (baseline):\n")
summary(m1)
cat("\nModel 3 (log outcome):\n")
summary(m3)
cat("\nModel 4 (raw ASBO rate):\n")
summary(m4)

# Export Table 2
models_list <- list(
  "(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4
)

# Write main results table
sink(file.path(tables_dir, "tab2_main_results.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of ASB Toolkit Consolidation on Anti-Social Behaviour}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & ASB Rate & ASB Rate & Log ASB Rate & ASB Rate \\\\\n")
cat("\\hline\n")

# Extract coefficients and SEs
coef1 <- coef(m1)["post_asbo_std"]
se1 <- sqrt(vcov(m1)["post_asbo_std", "post_asbo_std"])
coef2 <- coef(m2)["post_asbo_std"]
se2 <- sqrt(vcov(m2)["post_asbo_std", "post_asbo_std"])
coef3 <- coef(m3)["post_asbo_std"]
se3 <- sqrt(vcov(m3)["post_asbo_std", "post_asbo_std"])
coef4 <- coef(m4)["post_asbo"]
se4 <- sqrt(vcov(m4)["post_asbo", "post_asbo"])

stars <- function(p) {
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

p1 <- 2 * pnorm(-abs(coef1/se1))
p2 <- 2 * pnorm(-abs(coef2/se2))
p3 <- 2 * pnorm(-abs(coef3/se3))
p4 <- 2 * pnorm(-abs(coef4/se4))

cat(sprintf("Post $\\times$ ASBO Rate (std) & %.3f%s & %.3f%s & %.4f%s & \\\\\n",
            coef1, stars(p1), coef2, stars(p2), coef3, stars(p3)))
cat(sprintf(" & (%.3f) & (%.3f) & (%.4f) & \\\\\n", se1, se2, se3))
cat(sprintf("Post $\\times$ ASBO Rate (raw) & & & & %.4f%s \\\\\n", coef4, stars(p4)))
cat(sprintf(" & & & & (%.4f) \\\\\n", se4))
cat("\\hline\n")
cat(sprintf("Force FE & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Month FE & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Force trends & No & Yes & No & No \\\\\n"))
n_forces <- uniqueN(df$cjs_area)
cat(sprintf("Clusters & %d & %d & %d & %d \\\\\n", n_forces, n_forces, n_forces, n_forces))
cat(sprintf("Forces & %d & %d & %d & %d \\\\\n", n_forces, n_forces, n_forces, n_forces))
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nobs(m1), big.mark = ","),
            format(nobs(m2), big.mark = ","),
            format(nobs(m3), big.mark = ","),
            format(nobs(m4), big.mark = ",")))
cat(sprintf("R$^2$ (within) & %.3f & %.3f & %.3f & %.3f \\\\\n",
            fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]],
            fitstat(m3, "wr2")[[1]], fitstat(m4, "wr2")[[1]]))
pre_sd <- sd(df[post == 0]$asb_rate, na.rm = TRUE)
cat(sprintf("Pre-reform SD(Y) & %.1f & %.1f & --- & %.1f \\\\\n", pre_sd, pre_sd, pre_sd))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Each column reports a separate regression of the outcome on ")
cat("Post $\\times$ ASBO Rate, with force area and year-month fixed effects. ")
cat("``ASBO Rate (std)'' is the standardized (mean zero, unit variance) pre-reform ")
cat("cumulative ASBO issuance rate per 100,000. ``ASBO Rate (raw)'' uses the unstandardized rate. ")
cat("Standard errors clustered by police force area in parentheses. ")
cat("$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 2 saved.\n")

# ============================================================================
# TABLE 3: Event Study
# ============================================================================

cat("\n=== Event Study ===\n")

# Create quarter index for event study
# Our data has quarterly observations; assign sequential quarter indices
df[, quarter_idx := as.integer(factor(year_month))]
quarter_dates <- df[, .(date_label = as.character(first(year_month))), by = quarter_idx][order(quarter_idx)]

# Find the last pre-reform quarter (2014-06) as reference
ref_quarter <- df[year_month == as.Date("2014-06-01"), first(quarter_idx)]

# Relative quarter
df[, rel_quarter := quarter_idx - ref_quarter]

# Event study: interact each relative quarter with ASBO intensity
es_model <- feols(asb_rate ~ i(rel_quarter, asbo_rate_std, ref = 0) | cjs_area + year_month,
                  data = df, cluster = ~cjs_area)

cat("Event study coefficients:\n")
print(coef(es_model))

# Extract event study coefficients
es_names <- names(coef(es_model))
# fixest names look like "rel_quarter::-4:asbo_rate_std" — extract the number
es_periods <- as.integer(gsub("^rel_quarter::(-?\\d+):asbo_rate_std$", "\\1", es_names))

es_coefs <- data.table(
  rel_q = es_periods,
  coef = as.numeric(coef(es_model)),
  se = as.numeric(sqrt(diag(vcov(es_model))))
)
es_coefs[, ci_lo := coef - 1.96 * se]
es_coefs[, ci_hi := coef + 1.96 * se]

# Merge date labels
quarter_map <- df[, .(date_label = as.character(first(year_month)),
                       rel_q = first(rel_quarter)), by = quarter_idx]
es_coefs <- merge(es_coefs, quarter_map[, .(rel_q, date_label)], by = "rel_q", all.x = TRUE)

# Write event study table
sink(file.path(tables_dir, "tab3_event_study.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Event Study: ASB Rate by Quarter}\n")
cat("\\label{tab:eventstudy}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("Quarter & Date & Coefficient & SE & 95\\% CI \\\\\n")
cat("\\hline\n")

es_coefs <- es_coefs[order(rel_q)]
for (i in seq_len(nrow(es_coefs))) {
  rq <- es_coefs$rel_q[i]
  dl <- es_coefs$date_label[i]
  p <- 2 * pnorm(-abs(es_coefs$coef[i] / es_coefs$se[i]))
  cat(sprintf("$q%+d$ & %s & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\\n",
              rq, dl, es_coefs$coef[i], stars(p), es_coefs$se[i],
              es_coefs$ci_lo[i], es_coefs$ci_hi[i]))
}
cat("\\hline\n")
cat(sprintf("Reference & \\multicolumn{4}{c}{$q0$ = 2014-06 (omitted)} \\\\\n"))
cat(sprintf("Forces & \\multicolumn{4}{c}{%d} \\\\\n", uniqueN(df$cjs_area)))
cat(sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\\n", format(nobs(es_model), big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Each coefficient reports the interaction of a quarter indicator ")
cat("with the standardized pre-reform ASBO rate per 100,000. The reference quarter is 2014Q2 ")
cat("(the last full pre-reform quarter). ")
cat("Force area and quarter fixed effects included. Standard errors clustered by force area.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 3 saved.\n")

# ============================================================================
# Save diagnostics.json for validate_v1.py
# ============================================================================

diagnostics <- list(
  n_treated = uniqueN(df$cjs_area),  # All forces are "treated" (continuous intensity)
  n_pre = uniqueN(df[post == 0]$year_month),
  n_obs = nrow(df),
  n_forces = uniqueN(df$cjs_area),
  n_months = uniqueN(df$year_month),
  pre_sd_asb_rate = sd(df[post == 0]$asb_rate, na.rm = TRUE),
  mean_asb_rate_pre = mean(df[post == 0]$asb_rate, na.rm = TRUE),
  main_coef = as.numeric(coef(m1)["post_asbo_std"]),
  main_se = as.numeric(se1),
  main_p = as.numeric(p1)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("diagnostics.json saved.\n")

# Save key objects for robustness checks
saveRDS(list(df = df, m1 = m1, m3 = m3, m4 = m4, pre_sd = pre_sd),
        file.path(data_dir, "main_results.rds"))
cat("Main results saved for robustness checks.\n")
