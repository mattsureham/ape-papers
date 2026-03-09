## ============================================================================
## 06_tables.R — Generate all LaTeX tables from saved CSVs
## Paper: Demonetization by Design (apep_0555)
## ============================================================================

source(file.path(here::here(), "output", "apep_0555", "v1", "code", "00_packages.R"))

## =========================================================================
## TABLE 1: Summary Statistics
## =========================================================================

sumstats <- fread(file.path(data_dir, "sumstats_detail.csv"))
panel <- fread(file.path(data_dir, "panel.csv"))

## Overall panel statistics
overall <- panel[!is.na(cmi), .(
  n = .N,
  n_markets = n_distinct(market),
  n_states = n_distinct(state),
  n_commodities_high = n_distinct(commodity[cmi == "high"]),
  n_commodities_low = n_distinct(commodity[cmi == "low"]),
  mean_price_high = mean(price[cmi == "high"], na.rm = TRUE),
  sd_price_high = sd(price[cmi == "high"], na.rm = TRUE),
  mean_price_low = mean(price[cmi == "low"], na.rm = TRUE),
  sd_price_low = sd(price[cmi == "low"], na.rm = TRUE),
  mean_logp_high = mean(log(price[cmi == "high"]), na.rm = TRUE),
  sd_logp_high = sd(log(price[cmi == "high"]), na.rm = TRUE),
  mean_logp_low = mean(log(price[cmi == "low"]), na.rm = TRUE),
  sd_logp_low = sd(log(price[cmi == "low"]), na.rm = TRUE)
)]

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Cash-mediated (High CMI)} & \\multicolumn{2}{c}{Banking-mediated (Low CMI)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Price levels (NGN/kg)}} \\\\\n",
  sprintf("Price & %.1f & %.1f & %.1f & %.1f \\\\\n",
    overall$mean_price_high, overall$sd_price_high,
    overall$mean_price_low, overall$sd_price_low),
  sprintf("Log price & %.3f & %.3f & %.3f & %.3f \\\\\n",
    overall$mean_logp_high, overall$sd_logp_high,
    overall$mean_logp_low, overall$sd_logp_low),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Sample composition}} \\\\\n",
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
    format(panel[cmi == "high", .N], big.mark = ","),
    format(panel[cmi == "low", .N], big.mark = ",")),
  sprintf("Commodities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
    overall$n_commodities_high, overall$n_commodities_low),
  sprintf("Markets & \\multicolumn{4}{c}{%d} \\\\\n", overall$n_markets),
  sprintf("States & \\multicolumn{4}{c}{%d} \\\\\n", overall$n_states),
  "Time period & \\multicolumn{4}{c}{January 2020 -- December 2024} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Cash-mediated (High CMI) commodities include locally produced staples: millet, sorghum, maize, yam, local rice, cowpeas, cassava, groundnuts, palm oil, beans, and animal products. Banking-mediated (Low CMI) commodities include imported rice, wheat flour, sugar, pasta, vegetable oil, and salt. Source: WFP Food Price Monitoring (HDX).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tab_dir, "tab1_sumstats.tex"))
cat("Table 1 saved.\n")

## =========================================================================
## TABLE 2: Main DiD Results
## =========================================================================

main <- fread(file.path(data_dir, "main_results.csv"))

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Cash Crisis on Food Prices by Cash-Mediation Intensity}\n",
  "\\label{tab:main_did}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Acute & Extended & Rice acute & Rice extended \\\\\n",
  "\\midrule\n",
  sprintf("High CMI $\\times$ Crisis & %s%s & %s%s & & \\\\\n",
    sprintf("%.4f", main[1, estimate]),
    main[1, stars],
    sprintf("%.4f", main[2, estimate]),
    main[2, stars]),
  sprintf(" & (%s) & (%s) & & \\\\\n",
    sprintf("%.4f", main[1, se]),
    sprintf("%.4f", main[2, se])),
  sprintf("Local Rice $\\times$ Crisis & & & %s%s & %s%s \\\\\n",
    sprintf("%.4f", main[3, estimate]),
    main[3, stars],
    sprintf("%.4f", main[4, estimate]),
    main[4, stars]),
  sprintf(" & & & (%s) & (%s) \\\\\n",
    sprintf("%.4f", main[3, se]),
    sprintf("%.4f", main[4, se])),
  "\\midrule\n",
  "Commodity $\\times$ Market FE & Yes & Yes & Yes & Yes \\\\\n",
  "Market $\\times$ Time FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
    format(main[1, n_obs], big.mark = ","),
    format(main[2, n_obs], big.mark = ","),
    format(main[3, n_obs], big.mark = ","),
    format(main[4, n_obs], big.mark = ",")),
  "Crisis window & Feb--May & Feb--Dec & Feb--May & Feb--Dec \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log(price in NGN/kg). High CMI = cash-mediated local staples; Low CMI = banking-mediated imports. Columns (1)--(2): all commodities. Columns (3)--(4): local vs.\\ imported rice within the same markets. Standard errors clustered at the state level in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tab_dir, "tab2_main_did.tex"))
cat("Table 2 saved.\n")

## =========================================================================
## TABLE 3: Robustness Checks
## =========================================================================

rob <- fread(file.path(data_dir, "robustness_results.csv"))

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Estimate & SE & N \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(rob))) {
  row <- rob[i]
  se_str <- if (is.na(row$se)) "---" else sprintf("%.4f", row$se)
  tab3_tex <- paste0(tab3_tex,
    sprintf("%s & %.4f & %s & %s \\\\\n",
      row$check, row$estimate, se_str,
      format(row$n_obs, big.mark = ",")))
}

tab3_tex <- paste0(tab3_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications include commodity-by-market and market-by-time fixed effects. Main specification: High CMI $\\times$ Acute Crisis (Feb--May 2023). Standard errors clustered at the state level where applicable. Wild bootstrap uses Webb weights with 9,999 replications. Randomization inference permutes crisis timing across 500 draws.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tab_dir, "tab3_robustness.tex"))
cat("Table 3 saved.\n")

cat("\n=== ALL TABLES GENERATED ===\n")
