# ==============================================================================
# 06_tables.R — Generate all tables
# Paper: Who Bears the Tax Cut? (apep_0512)
# ==============================================================================

source("00_packages.R")

# Load data and results
dvf <- fread(file.path(data_dir, "dvf_analysis.csv"))
commune <- fread(file.path(data_dir, "commune_panel.csv"))
treat <- fread(file.path(data_dir, "treatment_intensity.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

commune_clean <- commune[!is.na(th_share_pre) & !is.na(taux_tfb)]

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================

cat("Table 1: Summary statistics\n")

stats_dvf_pre <- dvf[year < 2018, .(
  `Price/m2` = weighted.mean(exp(log_price_m2), n_total_sales, na.rm = TRUE),
  `Transactions` = sum(n_total_sales, na.rm = TRUE),
  `Communes` = uniqueN(code_insee)
)]
stats_dvf_post <- dvf[year >= 2018, .(
  `Price/m2` = weighted.mean(exp(log_price_m2), n_total_sales, na.rm = TRUE),
  `Transactions` = sum(n_total_sales, na.rm = TRUE),
  `Communes` = uniqueN(code_insee)
)]

stats_rei_pre <- commune_clean[year < 2018, .(
  `TH Rate` = mean(taux_th, na.rm = TRUE),
  `TF Rate` = mean(taux_tfb, na.rm = TRUE),
  `TH Share` = mean(th_share, na.rm = TRUE),
  `Communes` = uniqueN(code_insee)
)]
stats_rei_post <- commune_clean[year >= 2018, .(
  `TH Rate` = mean(taux_th, na.rm = TRUE),
  `TF Rate` = mean(taux_tfb, na.rm = TRUE),
  `TH Share` = mean(th_share, na.rm = TRUE),
  `Communes` = uniqueN(code_insee)
)]

sink(file.path(tab_dir, "tab1_summary_stats.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat(" & Pre-Reform (2014--2017) & Post-Reform (2018--2024) \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{3}{l}{\\textit{Panel A: Property Transactions (DVF)}} \\\\\n")
cat(sprintf("  Mean Price/m\\textsuperscript{2} (\\euro) & %s & %s \\\\\n",
            format(round(stats_dvf_pre$`Price/m2`), big.mark = ","),
            format(round(stats_dvf_post$`Price/m2`), big.mark = ",")))
cat(sprintf("  Total Transactions & %s & %s \\\\\n",
            format(stats_dvf_pre$Transactions, big.mark = ","),
            format(stats_dvf_post$Transactions, big.mark = ",")))
cat(sprintf("  Communes & %s & %s \\\\\n",
            format(stats_dvf_pre$Communes, big.mark = ","),
            format(stats_dvf_post$Communes, big.mark = ",")))
cat("\\addlinespace\n")
cat("\\multicolumn{3}{l}{\\textit{Panel B: Commune Tax Rates (REI)}} \\\\\n")
cat(sprintf("  TH Rate (\\%%) & %.2f & %.2f \\\\\n",
            stats_rei_pre$`TH Rate`, stats_rei_post$`TH Rate`))
cat(sprintf("  TF Rate (\\%%) & %.2f & %.2f \\\\\n",
            stats_rei_pre$`TF Rate`, stats_rei_post$`TF Rate`))
cat(sprintf("  TH Revenue Share & %.3f & %.3f \\\\\n",
            stats_rei_pre$`TH Share`, stats_rei_post$`TH Share`))
cat(sprintf("  Communes & %s & %s \\\\\n",
            format(stats_rei_pre$Communes, big.mark = ","),
            format(stats_rei_post$Communes, big.mark = ",")))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\end{table}\n")
sink()

# ==============================================================================
# TABLE 2: Main Results — Capitalization
# ==============================================================================

cat("Table 2: Main capitalization results\n")

tab2_models <- list(
  "(1) Weighted" = results$main_model,
  "(2) Unweighted" = results$unweighted_model,
  "(3) Q4 vs Q1" = results$quartile_model
)

msummary(tab2_models,
         output = file.path(tab_dir, "tab2_capitalization.tex"),
         stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
         coef_rename = c("treat_post" = "TH Rate $\\times$ Post",
                         "high_th:post" = "High TH $\\times$ Post"),
         gof_map = c("nobs", "r.squared", "FE: code_insee", "FE: year"),
         title = "Tax Capitalization into Property Prices",
         notes = "Standard errors clustered at commune level in parentheses.")

# ==============================================================================
# TABLE 3: Fiscal Displacement
# ==============================================================================

cat("Table 3: Fiscal displacement results\n")

tab3_models <- list(
  "(1) TF Level" = results$fiscal_model,
  "(2) TF Change" = results$fiscal_delta
)

msummary(tab3_models,
         output = file.path(tab_dir, "tab3_fiscal_displacement.tex"),
         stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
         coef_rename = c("th_depend_post" = "TH Dependence $\\times$ Post",
                         "th_share_pre:post" = "TH Share $\\times$ Post"),
         gof_map = c("nobs", "r.squared", "FE: code_insee", "FE: year"),
         title = "Fiscal Displacement: Taxe Fonciere Rate Response",
         notes = "Standard errors clustered at commune level in parentheses.")

# ==============================================================================
# TABLE 4: Robustness
# ==============================================================================

cat("Table 4: Robustness checks\n")

tab4_models <- list(
  "(1) Baseline" = results$main_model,
  "(2) Pre-COVID" = robust$precovid,
  "(3) Dept x Year" = robust$dept_year,
  "(4) Excl. IDF" = robust$no_idf,
  "(5) Trimmed" = robust$trimmed
)

msummary(tab4_models,
         output = file.path(tab_dir, "tab4_robustness.tex"),
         stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
         coef_rename = c("treat_post" = "TH Rate $\\times$ Post"),
         gof_map = c("nobs", "r.squared"),
         title = "Robustness: Tax Capitalization Estimates",
         notes = "Standard errors clustered at commune level.")

# ==============================================================================
# TABLE 5: Net Incidence Decomposition
# ==============================================================================

cat("Table 5: Net incidence decomposition\n")

beta_A <- coef(results$main_model)["treat_post"]
se_A <- se(results$main_model)["treat_post"]
beta_B <- coef(results$fiscal_model)["th_depend_post"]
se_B <- se(results$fiscal_model)["th_depend_post"]
gamma_TF <- coef(results$tfb_cap)["taux_tfb_annual"]
se_gamma <- se(results$tfb_cap)["taux_tfb_annual"]

avg_th <- mean(dvf$th_rate_pre, na.rm = TRUE)
avg_share <- mean(commune_clean$th_share_pre, na.rm = TRUE)

gross <- beta_A * avg_th
offset_val <- gamma_TF * beta_B * avg_share
net <- gross - offset_val
offset_pct <- abs(offset_val) / abs(gross) * 100

sink(file.path(tab_dir, "tab5_net_incidence.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Net Incidence Decomposition}\n")
cat("\\label{tab:incidence}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("Component & Estimate & Std.\\ Error \\\\\n")
cat("\\midrule\n")
cat(sprintf("TH Rate $\\times$ Post ($\\hat{\\beta}_A$) & %.4f & (%.4f) \\\\\n",
            beta_A, se_A))
cat(sprintf("TH Dependence $\\times$ Post ($\\hat{\\phi}_B$) & %.4f & (%.4f) \\\\\n",
            beta_B, se_B))
cat(sprintf("TF $\\rightarrow$ Prices ($\\hat{\\gamma}$) & %.4f & (%.4f) \\\\\n",
            gamma_TF, se_gamma))
cat("\\addlinespace\n")
cat(sprintf("Gross capitalization ($\\hat{\\beta}_A \\times \\bar{r}_{TH}$) & %.4f & \\\\\n",
            gross))
cat(sprintf("TF offset ($\\hat{\\gamma} \\times \\hat{\\phi}_B \\times \\bar{s}_{TH}$) & %.4f & \\\\\n",
            offset_val))
cat(sprintf("Net capitalization & %.4f & \\\\\n", net))
cat(sprintf("Offset share & %.1f\\%% & \\\\\n", offset_pct))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

cat("\n=== All tables saved to", tab_dir, "===\n")
