## 05_tables.R — Generate all LaTeX tables
## Paper: Carbon Border Deflection (apep_0788)

source("00_packages.R")

trade <- readRDS("../data/trade_panel.rds")
main_results <- readRDS("../data/main_results.rds")
robust_results <- readRDS("../data/robust_results.rds")
es_coefs <- readRDS("../data/es_coefs.rds")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

# Panel A: By destination × coverage status
sumstats <- trade |>
  mutate(
    group = case_when(
      eu_dest == 1 & cbam_covered == 1 ~ "EU, Covered",
      eu_dest == 1 & cbam_covered == 0 ~ "EU, Uncovered",
      eu_dest == 0 & cbam_covered == 1 ~ "Non-EU, Covered",
      eu_dest == 0 & cbam_covered == 0 ~ "Non-EU, Uncovered"
    ),
    period_label = ifelse(post == 0, "Pre-CBAM", "Post-CBAM")
  ) |>
  group_by(group, period_label) |>
  summarise(
    `Mean (M USD)` = mean(trade_value_m, na.rm = TRUE),
    `SD (M USD)` = sd(trade_value_m, na.rm = TRUE),
    `Share Zero` = mean(trade_value == 0, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  ) |>
  arrange(group, period_label)

# Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Monthly Bilateral Trade Flows}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{llrrrr}\n")
cat("\\hline\\hline\n")
cat("Group & Period & Mean (M\\$) & SD (M\\$) & Share Zero & N \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(sumstats)) {
  row <- sumstats[i, ]
  cat(sprintf("%s & %s & %.1f & %.1f & %.3f & %s \\\\\n",
              row$group, row$period_label,
              row$`Mean (M USD)`, row$`SD (M USD)`,
              row$`Share Zero`, formatC(row$N, format = "d", big.mark = ",")))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Monthly bilateral trade values in millions of USD from UN Comtrade. ")
cat("``Covered'' products are iron and steel (HS 72) and aluminium (HS 76), which fall under EU CBAM. ")
cat("``Uncovered'' products are articles of iron or steel (HS 73), which are not subject to CBAM. ")
cat("EU destinations comprise EU-27 member states. Non-EU destinations are the US, Japan, and the UK. ")
cat("Pre-CBAM: January 2020--September 2023. Post-CBAM: October 2023--December 2024. ")
cat("Exporters: China, India, Turkey, Russia, Ukraine, Vietnam, Taiwan, Brazil.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 written: tables/tab1_summary.tex\n")

# ============================================================
# TABLE 2: Main DDD Results
# ============================================================

sink("../tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{CBAM and Trade Deflection: Triple-Difference Estimates}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat(" & OLS & OLS & OLS & OLS & PPML \\\\\n")
cat("\\hline\n")

models <- list(main_results$m1, main_results$m2, main_results$m3,
               main_results$m4, main_results$m5)
var_name <- "post_eu_covered"

for (col in 1:5) {
  m <- models[[col]]
  cf <- coef(m)[var_name]
  se_val <- se(m)[var_name]
  pv <- pvalue(m)[var_name]
  stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}", ifelse(pv < 0.1, "^{*}", "")))

  if (col == 1) {
    cat(sprintf("Post $\\times$ EU $\\times$ Covered & $%.3f%s$ & ", cf, stars))
  } else if (col == 5) {
    cat(sprintf("$%.3f%s$ \\\\\n", cf, stars))
  } else {
    cat(sprintf("$%.3f%s$ & ", cf, stars))
  }
}

# SE row
for (col in 1:5) {
  m <- models[[col]]
  se_val <- se(m)[var_name]
  if (col == 1) {
    cat(sprintf(" & ($%.3f$) & ", se_val))
  } else if (col == 5) {
    cat(sprintf("($%.3f$) \\\\\n", se_val))
  } else {
    cat(sprintf("($%.3f$) & ", se_val))
  }
}

cat("\\hline\n")
cat("Cell FE (Exp$\\times$Dest$\\times$Prod) & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Month FE & Yes & & & & \\\\\n")
cat("Exporter$\\times$Month FE & & Yes & Yes & Yes & Yes \\\\\n")
cat("Destination$\\times$Month FE & & & Yes & Yes & Yes \\\\\n")
cat("Product$\\times$Month FE & & & & Yes & Yes \\\\\n")

# Observations and R-squared
for (col in 1:5) {
  m <- models[[col]]
  n_obs <- nobs(m)
  if (col == 1) {
    cat(sprintf("Observations & %s & ", formatC(n_obs, format = "d", big.mark = ",")))
  } else if (col == 5) {
    cat(sprintf("%s \\\\\n", formatC(n_obs, format = "d", big.mark = ",")))
  } else {
    cat(sprintf("%s & ", formatC(n_obs, format = "d", big.mark = ",")))
  }
}

# R-squared (OLS only)
for (col in 1:5) {
  m <- models[[col]]
  if (col <= 4) {
    r2_val <- sprintf("%.3f", fitstat(m, type = "r2")[[1]])
  } else {
    r2_val <- "---"  # PPML has pseudo R²
  }
  if (col == 1) {
    cat(sprintf("$R^2$ & %s & ", r2_val))
  } else if (col == 5) {
    cat(sprintf("%s \\\\\n", r2_val))
  } else {
    cat(sprintf("%s & ", r2_val))
  }
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Triple-difference estimates. The dependent variable is log(trade value + 1) in columns 1--4 ")
cat("and trade value in levels in column 5 (PPML). ``Post'' = October 2023 onward (CBAM transitional phase). ")
cat("``EU'' = EU-27 destination. ``Covered'' = HS 72 (iron/steel) or HS 76 (aluminium). ")
cat("The omitted category is uncovered products (HS 73: articles of iron/steel) shipped to non-EU destinations (US, Japan, UK). ")
cat("Standard errors clustered at the exporter$\\times$destination level in parentheses. ")
cat("$^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, 10\\%.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 written: tables/tab2_main.tex\n")

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================

sink("../tables/tab3_eventstudy.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Event Study: Monthly Triple-Difference Coefficients}\n")
cat("\\label{tab:eventstudy}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("Event Month & Coefficient & SE & 95\\% CI Lower & 95\\% CI Upper \\\\\n")
cat("\\hline\n")

# Show key pre and post periods
show_times <- c(-12, -9, -6, -3, -1, 0, 1, 3, 6, 9, 12)
es_show <- es_coefs |> filter(event_time %in% show_times)

for (i in 1:nrow(es_show)) {
  row <- es_show[i, ]
  et_label <- ifelse(row$event_time == -1, "$t = -1$ (ref.)",
                     sprintf("$t = %+d$", row$event_time))
  if (row$event_time == -1) {
    cat(sprintf("%s & 0.000 & --- & --- & --- \\\\\n", et_label))
  } else {
    pv <- 2 * pnorm(-abs(row$coef / row$se))
    stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}", ifelse(pv < 0.1, "^{*}", "")))
    cat(sprintf("%s & $%.3f%s$ & (%.3f) & %.3f & %.3f \\\\\n",
                et_label, row$coef, stars, row$se, row$ci_lo, row$ci_hi))
  }
}

cat("\\hline\n")

# Add pre-trend test
cat("\\multicolumn{5}{l}{Pre-trend joint $F$-test $p$-value: ")
pre_count <- sum(es_coefs$event_time < -1)
if (pre_count > 0) {
  # Calculate joint test from coefficients
  pre_coefs_vals <- es_coefs |> filter(event_time < -1)
  f_stat <- sum((pre_coefs_vals$coef / pre_coefs_vals$se)^2) / nrow(pre_coefs_vals)
  p_val <- pf(f_stat, nrow(pre_coefs_vals), nobs(readRDS("../data/es_model.rds")) - 50, lower.tail = FALSE)
  cat(sprintf("%.3f", p_val))
} else {
  cat("---")
}
cat("} \\\\\n")

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Coefficients from an event study interacting monthly dummies (relative to $t = -1$, September 2023) ")
cat("with EU destination and CBAM-covered product indicators. The dependent variable is log(trade value $+ 1$). ")
cat("All models include exporter$\\times$destination$\\times$product, exporter$\\times$month, destination$\\times$month, ")
cat("and product$\\times$month fixed effects. Standard errors clustered at the exporter$\\times$destination level. ")
cat("$^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, 10\\%. ")
cat("$t = 0$ corresponds to October 2023 (CBAM transitional phase onset).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 written: tables/tab3_eventstudy.tex\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat(" & Baseline & Excl.\\ RU/UA & Excl.\\ 2020 & Excl.\\ US & Steel only \\\\\n")
cat("\\hline\n")

rob_models <- list(
  main_results$m4,
  robust_results$no_ruua,
  robust_results$no_2020,
  robust_results$no_us,
  robust_results$steel_only
)

var_name <- "post_eu_covered"

# Coefficient row
coef_parts <- c()
se_parts <- c()
n_parts <- c()

for (col in 1:5) {
  m <- rob_models[[col]]
  cf <- coef(m)[var_name]
  se_val <- se(m)[var_name]
  pv <- pvalue(m)[var_name]
  stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}", ifelse(pv < 0.1, "^{*}", "")))
  coef_parts <- c(coef_parts, sprintf("$%.3f%s$", cf, stars))
  se_parts <- c(se_parts, sprintf("($%.3f$)", se_val))
  n_parts <- c(n_parts, formatC(nobs(m), format = "d", big.mark = ","))
}

cat(sprintf("Post $\\times$ EU $\\times$ Covered & %s \\\\\n", paste(coef_parts, collapse = " & ")))
cat(sprintf(" & %s \\\\\n", paste(se_parts, collapse = " & ")))
cat("\\hline\n")

# Placebo row
placebo_m <- robust_results$placebo_uncovered
# Get the Post × EU coefficient for uncovered products
placebo_coefs <- coeftable(placebo_m)
placebo_var <- rownames(placebo_coefs)[grepl("post.*eu_dest", rownames(placebo_coefs), ignore.case = TRUE)][1]
if (!is.na(placebo_var)) {
  placebo_cf <- placebo_coefs[placebo_var, "Estimate"]
  placebo_se <- placebo_coefs[placebo_var, "Std. Error"]
  placebo_pv <- placebo_coefs[placebo_var, "Pr(>|t|)"]
  placebo_stars <- ifelse(placebo_pv < 0.01, "^{***}", ifelse(placebo_pv < 0.05, "^{**}", ifelse(placebo_pv < 0.1, "^{*}", "")))
  cat(sprintf("\\multicolumn{5}{l}{Placebo (uncovered only): Post $\\times$ EU $= %.3f%s$ (SE: %.3f)} \\\\\n",
              placebo_cf, placebo_stars, placebo_se))
}

# Placebo date row
placebo_date_m <- robust_results$placebo_date
pd_cf <- coef(placebo_date_m)["post_eu_covered_placebo"]
pd_se <- se(placebo_date_m)["post_eu_covered_placebo"]
pd_pv <- pvalue(placebo_date_m)["post_eu_covered_placebo"]
pd_stars <- ifelse(pd_pv < 0.01, "^{***}", ifelse(pd_pv < 0.05, "^{**}", ifelse(pd_pv < 0.1, "^{*}", "")))
cat(sprintf("\\multicolumn{5}{l}{Placebo date (Oct 2022): $%.3f%s$ (SE: %.3f)} \\\\\n",
            pd_cf, pd_stars, pd_se))

# Dose-response row
dose_m <- robust_results$dose_response
dose_coefs <- coeftable(dose_m)
dose_interaction <- rownames(dose_coefs)[grepl("co2_intensity", rownames(dose_coefs))][1]
if (!is.na(dose_interaction)) {
  dose_cf <- dose_coefs[dose_interaction, "Estimate"]
  dose_se <- dose_coefs[dose_interaction, "Std. Error"]
  dose_pv <- dose_coefs[dose_interaction, "Pr(>|t|)"]
  dose_stars <- ifelse(dose_pv < 0.01, "^{***}", ifelse(dose_pv < 0.05, "^{**}", ifelse(dose_pv < 0.1, "^{*}", "")))
  cat(sprintf("\\multicolumn{5}{l}{Dose-response (CO$_2$ intensity): $%.3f%s$ (SE: %.3f)} \\\\\n",
              dose_cf, dose_stars, dose_se))
}

cat("\\hline\n")
cat(sprintf("Observations & %s \\\\\n", paste(n_parts, collapse = " & ")))
cat("All FEs & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} All specifications include exporter$\\times$destination$\\times$product, exporter$\\times$month, ")
cat("destination$\\times$month, and product$\\times$month fixed effects. Dependent variable: log(trade value $+ 1$). ")
cat("Column 1 reproduces the baseline (Table~\\ref{tab:main}, column 4). ")
cat("Column 2 excludes Russia and Ukraine (war disruption). ")
cat("Column 3 excludes 2020 (COVID). Column 4 excludes the US (Section 232 tariffs). ")
cat("Column 5 restricts to iron/steel products only (HS 72 vs HS 73). ")
cat("Placebo: uncovered products (HS 73) tested for differential EU trends. ")
cat("Placebo date: false treatment at October 2022 using only pre-CBAM data. ")
cat("Dose-response: interaction of the triple-difference with exporter CO$_2$ intensity (tCO$_2$/t steel). ")
cat("Standard errors clustered at the exporter$\\times$destination level. ")
cat("$^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, 10\\%.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 written: tables/tab4_robustness.tex\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================

# Get pre-treatment SD of log trade for covered EU-bound products
pre_eu_covered <- trade |>
  filter(post == 0, eu_dest == 1, cbam_covered == 1)
sd_y_eu <- sd(pre_eu_covered$log_trade, na.rm = TRUE)

# Get pre-treatment SD for non-EU covered products
pre_noneu_covered <- trade |>
  filter(post == 0, eu_dest == 0, cbam_covered == 1)
sd_y_noneu <- sd(pre_noneu_covered$log_trade, na.rm = TRUE)

# Main DDD coefficient
m4 <- main_results$m4
beta_ddd <- coef(m4)["post_eu_covered"]
se_ddd <- se(m4)["post_eu_covered"]

# Use the overall pre-treatment SD for the DDD outcome
pre_all <- trade |> filter(post == 0)
sd_y_all <- sd(pre_all$log_trade, na.rm = TRUE)

# Decomposition results
decomp <- readRDS("../data/decomp_results.rds")
eu_coefs <- coeftable(decomp$eu)
noneu_coefs <- coeftable(decomp$noneu)

# EU-bound DiD
eu_var <- rownames(eu_coefs)[grepl("cbam_covered", rownames(eu_coefs))][1]
beta_eu <- eu_coefs[eu_var, "Estimate"]
se_eu <- eu_coefs[eu_var, "Std. Error"]

# Non-EU-bound DiD
noneu_var <- rownames(noneu_coefs)[grepl("cbam_covered", rownames(noneu_coefs))][1]
beta_noneu <- noneu_coefs[noneu_var, "Estimate"]
se_noneu <- noneu_coefs[noneu_var, "Std. Error"]

# Compute SDEs
sde_ddd <- beta_ddd / sd_y_all
se_sde_ddd <- se_ddd / sd_y_all

sde_eu <- beta_eu / sd_y_eu
se_sde_eu <- se_eu / sd_y_eu

sde_noneu <- beta_noneu / sd_y_noneu
se_sde_noneu <- se_noneu / sd_y_noneu

classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_table <- tibble(
  Outcome = c(
    "CBAM Deflection (DDD)",
    "EU-Bound Covered Imports (DiD)",
    "Non-EU-Bound Covered Imports (DiD)"
  ),
  beta = c(beta_ddd, beta_eu, beta_noneu),
  se = c(se_ddd, se_eu, se_noneu),
  sd_y = c(sd_y_all, sd_y_eu, sd_y_noneu),
  sde = c(sde_ddd, sde_eu, sde_noneu),
  se_sde = c(se_sde_ddd, se_sde_eu, se_sde_noneu),
  classification = sapply(c(sde_ddd, sde_eu, sde_noneu), classify_sde)
)

# Write SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (EU-27) and non-EU destinations (United States, Japan, United Kingdom). ",
  "\\textbf{Research question:} Does the EU Carbon Border Adjustment Mechanism (CBAM) deflect high-carbon metal exports ",
  "from major producers away from the EU toward non-CBAM markets? ",
  "\\textbf{Policy mechanism:} CBAM imposes carbon-cost reporting requirements on imports of iron/steel (HS 72) and aluminium (HS 76) ",
  "entering the EU, effective October 2023 in its transitional phase; importers must report embedded emissions, ",
  "creating compliance costs and signaling future carbon pricing that may redirect trade flows to unregulated destinations. ",
  "\\textbf{Outcome definition:} Log monthly bilateral trade value (USD) plus one, measuring the intensive margin of metal exports ",
  "from major producers to EU versus non-EU destinations. ",
  "\\textbf{Treatment:} Binary; onset of CBAM transitional phase in October 2023. ",
  "\\textbf{Data:} UN Comtrade monthly bilateral imports, 8 exporters $\\times$ 4 destinations $\\times$ 3 product groups, ",
  "January 2020--December 2024 (approximately 7,000 observations). ",
  "\\textbf{Method:} Triple-difference (destination $\\times$ product $\\times$ time) estimated via OLS with ",
  "exporter$\\times$destination$\\times$product, exporter$\\times$month, destination$\\times$month, and product$\\times$month fixed effects; ",
  "standard errors clustered at the exporter$\\times$destination level. ",
  "\\textbf{Sample:} Restricted to 8 major metal-exporting countries (China, India, Turkey, Russia, Ukraine, Vietnam, Taiwan, Brazil) ",
  "and 4 destination markets; HS 73 (articles of iron/steel) serves as the within-sector uncovered placebo. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")

for (i in 1:nrow(sde_table)) {
  row <- sde_table[i, ]
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
              row$Outcome, row$beta, row$se, row$sd_y,
              row$sde, row$se_sde, row$classification))
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table F1 written: tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
