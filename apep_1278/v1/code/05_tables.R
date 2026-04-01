## 05_tables.R — Generate all LaTeX tables
## apep_1278: The Compliance Lottery

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

cat("=== Generating Tables ===\n")

# -----------------------------------------------------------------------
# Table 1: Summary Statistics
# -----------------------------------------------------------------------
cat("Table 1: Summary statistics...\n")

# Pre-treatment period (2005-2012) statistics by treatment group
pre_treat <- panel %>%
  filter(year <= 2012, !is.na(vat_gap_pct), country != "MT") %>%
  mutate(group = ifelse(ever_treated, "Lottery Adopters", "Never Adopted"))

summ <- pre_treat %>%
  group_by(group) %>%
  summarise(
    N_countries = n_distinct(country),
    N_obs = n(),
    gap_mean = mean(vat_gap_pct, na.rm = TRUE),
    gap_sd = sd(vat_gap_pct, na.rm = TRUE),
    vat_gdp_mean = mean(vat_gdp_ratio, na.rm = TRUE),
    vat_gdp_sd = sd(vat_gdp_ratio, na.rm = TRUE),
    gdp_mean = mean(gdp_mio / 1000, na.rm = TRUE),  # billions
    gdp_sd = sd(gdp_mio / 1000, na.rm = TRUE),
    .groups = "drop"
  )

# Full sample stats
full_summ <- panel %>%
  filter(!is.na(vat_gap_pct), country != "MT") %>%
  summarise(
    group = "Full Sample",
    N_countries = n_distinct(country),
    N_obs = n(),
    gap_mean = mean(vat_gap_pct, na.rm = TRUE),
    gap_sd = sd(vat_gap_pct, na.rm = TRUE),
    vat_gdp_mean = mean(vat_gdp_ratio, na.rm = TRUE),
    vat_gdp_sd = sd(vat_gdp_ratio, na.rm = TRUE),
    gdp_mean = mean(gdp_mio / 1000, na.rm = TRUE),
    gdp_sd = sd(gdp_mio / 1000, na.rm = TRUE)
  )

summ_all <- bind_rows(summ, full_summ)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Period (2005--2012)}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Lottery Adopters & Never Adopted & Full Sample \\\\\n",
  "\\hline\n",
  sprintf("Countries & %d & %d & %d \\\\\n",
          summ_all$N_countries[summ_all$group == "Lottery Adopters"],
          summ_all$N_countries[summ_all$group == "Never Adopted"],
          summ_all$N_countries[summ_all$group == "Full Sample"]),
  sprintf("Country-years & %d & %d & %d \\\\\n",
          summ_all$N_obs[summ_all$group == "Lottery Adopters"],
          summ_all$N_obs[summ_all$group == "Never Adopted"],
          summ_all$N_obs[summ_all$group == "Full Sample"]),
  "\\addlinespace\n",
  sprintf("VAT gap (\\%% of VTTL) & %.1f & %.1f & %.1f \\\\\n",
          summ_all$gap_mean[summ_all$group == "Lottery Adopters"],
          summ_all$gap_mean[summ_all$group == "Never Adopted"],
          summ_all$gap_mean[summ_all$group == "Full Sample"]),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) \\\\\n",
          summ_all$gap_sd[summ_all$group == "Lottery Adopters"],
          summ_all$gap_sd[summ_all$group == "Never Adopted"],
          summ_all$gap_sd[summ_all$group == "Full Sample"]),
  sprintf("VAT revenue / GDP (\\%%) & %.2f & %.2f & %.2f \\\\\n",
          summ_all$vat_gdp_mean[summ_all$group == "Lottery Adopters"],
          summ_all$vat_gdp_mean[summ_all$group == "Never Adopted"],
          summ_all$vat_gdp_mean[summ_all$group == "Full Sample"]),
  sprintf(" & (%.2f) & (%.2f) & (%.2f) \\\\\n",
          summ_all$vat_gdp_sd[summ_all$group == "Lottery Adopters"],
          summ_all$vat_gdp_sd[summ_all$group == "Never Adopted"],
          summ_all$vat_gdp_sd[summ_all$group == "Full Sample"]),
  sprintf("GDP (\\euro{} billions) & %.0f & %.0f & %.0f \\\\\n",
          summ_all$gdp_mean[summ_all$group == "Lottery Adopters"],
          summ_all$gdp_mean[summ_all$group == "Never Adopted"],
          summ_all$gdp_mean[summ_all$group == "Full Sample"]),
  sprintf(" & (%.0f) & (%.0f) & (%.0f) \\\\\n",
          summ_all$gdp_sd[summ_all$group == "Lottery Adopters"],
          summ_all$gdp_sd[summ_all$group == "Never Adopted"],
          summ_all$gdp_sd[summ_all$group == "Full Sample"]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard deviations in parentheses. ",
  "``Lottery Adopters'' includes the 9 EU member states that introduced receipt lottery programs between 2013 and 2021 (Malta excluded as always-treated). ",
  "``Never Adopted'' includes 17 EU member states that never introduced receipt lotteries during the sample period. ",
  "VAT gap is the difference between theoretical VAT liability (VTTL) and actual VAT collections, as estimated by the European Commission/CASE consortium. ",
  "GDP denominated in current-price euros.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# -----------------------------------------------------------------------
# Table 2: Main Results (TWFE + Callaway-Sant'Anna)
# -----------------------------------------------------------------------
cat("Table 2: Main results...\n")

twfe_gap <- results$twfe_gap
twfe_vat <- results$twfe_vat
cs_agg <- results$cs_agg

# Extract CS results
cs_att <- cs_agg$overall.att
cs_se <- cs_agg$overall.se

# Extract CS for VAT/GDP if available
cs_vat_agg <- robustness$cs_vat
cs_vat_att <- if (!is.null(cs_vat_agg)) cs_vat_agg$overall.att else NA
cs_vat_se <- if (!is.null(cs_vat_agg)) cs_vat_agg$overall.se else NA

stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.10) return("$^{*}$")
  return("")
}

twfe_gap_p <- pvalue(twfe_gap)["lottery_active"]
twfe_vat_p <- pvalue(twfe_vat)["lottery_active"]
cs_p <- if (cs_se > 0) 2 * pnorm(-abs(cs_att / cs_se)) else NA
cs_vat_p <- if (!is.na(cs_vat_se) && cs_vat_se > 0) 2 * pnorm(-abs(cs_vat_att / cs_vat_se)) else NA

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Receipt Lotteries on VAT Compliance}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{VAT Gap (\\% VTTL)} & \\multicolumn{2}{c}{VAT/GDP (\\%)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & TWFE & CS & TWFE & CS \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("Lottery Active & %.2f%s & %.2f%s & %.3f%s & %s%s \\\\\n",
          coef(twfe_gap)["lottery_active"], stars(twfe_gap_p),
          cs_att, stars(cs_p),
          coef(twfe_vat)["lottery_active"], stars(twfe_vat_p),
          ifelse(is.na(cs_vat_att), "---", sprintf("%.3f", cs_vat_att)),
          ifelse(is.na(cs_vat_p), "", stars(cs_vat_p))),
  sprintf(" & (%.2f) & (%.2f) & (%.3f) & %s \\\\\n",
          se(twfe_gap)["lottery_active"],
          cs_se,
          se(twfe_vat)["lottery_active"],
          ifelse(is.na(cs_vat_se), "---", sprintf("(%.3f)", cs_vat_se))),
  "\\addlinespace\n",
  sprintf("Country FE & Yes & --- & Yes & --- \\\\\n"),
  sprintf("Year FE & Yes & --- & Yes & --- \\\\\n"),
  sprintf("Estimator & TWFE & CS (2021) & TWFE & CS (2021) \\\\\n"),
  sprintf("Comparison & --- & Never-treated & --- & Never-treated \\\\\n"),
  sprintf("Countries & %d & %d & %d & %d \\\\\n",
          n_distinct(panel$country[!is.na(panel$vat_gap_pct) & panel$country != "MT"]),
          n_distinct(panel$country[!is.na(panel$vat_gap_pct) & panel$country != "MT"]),
          n_distinct(panel$country[panel$country != "MT"]),
          n_distinct(panel$country[panel$country != "MT"])),
  sprintf("Country-years & %d & %d & %d & %d \\\\\n",
          nrow(panel %>% filter(!is.na(vat_gap_pct), country != "MT")),
          nrow(panel %>% filter(!is.na(vat_gap_pct), country != "MT")),
          nrow(panel %>% filter(country != "MT")),
          nrow(panel %>% filter(country != "MT"))),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. ",
  "Columns (1) and (3) report two-way fixed effects estimates with country and year fixed effects; ",
  "standard errors clustered at the country level in parentheses. ",
  "Columns (2) and (4) report Callaway and Sant'Anna (2021) aggregated ATT estimates using never-treated countries as the comparison group; ",
  "bootstrap standard errors (1,000 iterations) in parentheses. ",
  "Malta excluded as it adopted its receipt lottery in 1997, before the sample period. ",
  "``VAT Gap'' is the European Commission/CASE estimate of uncollected VAT as a percentage of total theoretical liability. ",
  "``VAT/GDP'' is actual VAT revenue as a share of nominal GDP from Eurostat.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "../tables/tab2_main.tex")

# -----------------------------------------------------------------------
# Table 3: Cancellation Reversal Test
# -----------------------------------------------------------------------
cat("Table 3: Cancellation reversal...\n")

cancel <- robustness$cancel_summary

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Cancellation Reversal Test}\n",
  "\\label{tab:cancel}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  "Country & Lottery Period & Cancel Year & Gap During & Gap After & $\\Delta$ Gap \\\\\n",
  "\\hline\n",
  sprintf("Czech Republic & 2017--2019 & 2020 & %.1f & %.1f & %.1f \\\\\n",
          cancel$mean_gap_during[cancel$country == "CZ"],
          cancel$mean_gap_after[cancel$country == "CZ"],
          cancel$gap_change[cancel$country == "CZ"]),
  sprintf("Poland & 2015--2016 & 2017 & %.1f & %.1f & %.1f \\\\\n",
          cancel$mean_gap_during[cancel$country == "PL"],
          cancel$mean_gap_after[cancel$country == "PL"],
          cancel$gap_change[cancel$country == "PL"]),
  sprintf("Slovakia & 2013--2020 & 2021 & %.1f & %.1f & %.1f \\\\\n",
          cancel$mean_gap_during[cancel$country == "SK"],
          cancel$mean_gap_after[cancel$country == "SK"],
          cancel$gap_change[cancel$country == "SK"]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ``Gap During'' is the mean VAT gap (\\% of VTTL) during the years the receipt lottery was active. ",
  "``Gap After'' is the mean VAT gap in years after the lottery was cancelled. ",
  "$\\Delta$ Gap is the difference (positive values indicate the gap widened after cancellation, consistent with lottery effectiveness). ",
  "Cancel year is the first full year without the lottery. ",
  "VAT gap estimates from the European Commission/CASE consortium.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "../tables/tab3_cancel.tex")

# -----------------------------------------------------------------------
# Table 4: Robustness (LOO + Placebo + Bootstrap)
# -----------------------------------------------------------------------
cat("Table 4: Robustness...\n")

loo <- robustness$loo_results
placebo <- robustness$placebo

# Wild bootstrap CI
boot_ci <- if (!is.null(robustness$boot_result)) {
  tryCatch({
    ci <- robustness$boot_result$conf_int
    sprintf("[%.2f, %.2f]", ci[1], ci[2])
  }, error = function(e) "---")
} else "---"

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Specification & Coefficient & SE \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Leave-One-Out (TWFE)}} \\\\\n",
  "\\addlinespace\n"
)

for (i in seq_len(nrow(loo))) {
  country_name <- case_when(
    loo$dropped[i] == "CZ" ~ "Czech Republic",
    loo$dropped[i] == "EL" ~ "Greece",
    loo$dropped[i] == "IT" ~ "Italy",
    loo$dropped[i] == "LT" ~ "Lithuania",
    loo$dropped[i] == "LV" ~ "Latvia",
    loo$dropped[i] == "PL" ~ "Poland",
    loo$dropped[i] == "PT" ~ "Portugal",
    loo$dropped[i] == "RO" ~ "Romania",
    loo$dropped[i] == "SK" ~ "Slovakia",
    TRUE ~ loo$dropped[i]
  )
  tab4_tex <- paste0(tab4_tex,
    sprintf("\\quad Drop %s & %.2f & (%.2f) \\\\\n",
            country_name, loo$coef[i], loo$se[i]))
}

tab4_tex <- paste0(tab4_tex,
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Alternative Inference}} \\\\\n",
  "\\addlinespace\n",
  sprintf("\\quad Wild cluster bootstrap 95\\%% CI & \\multicolumn{2}{c}{%s} \\\\\n", boot_ci),
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Placebo Outcome}} \\\\\n",
  "\\addlinespace\n",
  sprintf("\\quad Income tax / GDP & %.3f & (%.3f) \\\\\n",
          coef(placebo)["lottery_active"],
          se(placebo)["lottery_active"]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A reports TWFE estimates of the lottery effect on the VAT gap after dropping each treated country in turn. ",
  "Panel B reports the 95\\% confidence interval from wild cluster bootstrap (Webb weights, 9,999 iterations) for the baseline TWFE specification. ",
  "Panel C reports the TWFE placebo estimate using income tax revenue as a share of GDP --- a fiscal outcome that should not respond to VAT receipt lotteries. ",
  "All specifications include country and year fixed effects with standard errors clustered at the country level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "../tables/tab4_robust.tex")

# -----------------------------------------------------------------------
# Table F1: Standardized Effect Size (SDE) — MANDATORY appendix
# -----------------------------------------------------------------------
cat("Table F1: SDE...\n")

# Compute SDE for main outcomes
# Pre-treatment SD of outcomes
pre_treat_data <- panel %>%
  filter(!is.na(vat_gap_pct), country != "MT") %>%
  group_by(country) %>%
  mutate(first_treat = ifelse(cs_group > 0, cs_group, Inf)) %>%
  ungroup() %>%
  filter(year < first_treat | is.infinite(first_treat))

sd_gap_pre <- sd(pre_treat_data$vat_gap_pct, na.rm = TRUE)
sd_vat_gdp_pre <- sd(pre_treat_data$vat_gdp_ratio, na.rm = TRUE)

# Main estimates (TWFE)
beta_gap <- coef(results$twfe_gap)["lottery_active"]
se_gap <- se(results$twfe_gap)["lottery_active"]
beta_vat <- coef(results$twfe_vat)["lottery_active"]
se_vat <- se(results$twfe_vat)["lottery_active"]

# SDE
sde_gap <- beta_gap / sd_gap_pre
se_sde_gap <- se_gap / sd_gap_pre
sde_vat <- beta_vat / sd_vat_gdp_pre
se_sde_vat <- se_vat / sd_vat_gdp_pre

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

# Heterogeneity: split by baseline gap (high vs low)
high_gap_data <- panel %>% filter(!is.na(vat_gap_pct), country != "MT", high_baseline_gap == 1)
low_gap_data <- panel %>% filter(!is.na(vat_gap_pct), country != "MT", high_baseline_gap == 0)

twfe_high <- tryCatch(
  feols(vat_gap_pct ~ lottery_active | country_id + year, data = high_gap_data, cluster = ~country_id),
  error = function(e) NULL
)
twfe_low <- tryCatch(
  feols(vat_gap_pct ~ lottery_active | country_id + year, data = low_gap_data, cluster = ~country_id),
  error = function(e) NULL
)

beta_high <- if (!is.null(twfe_high)) coef(twfe_high)["lottery_active"] else NA
se_high <- if (!is.null(twfe_high)) se(twfe_high)["lottery_active"] else NA
sd_high <- sd(high_gap_data$vat_gap_pct[high_gap_data$lottery_active == 0], na.rm = TRUE)
sde_high <- if (!is.na(beta_high) && !is.na(sd_high) && sd_high > 0) beta_high / sd_high else NA
se_sde_high <- if (!is.na(se_high) && !is.na(sd_high) && sd_high > 0) se_high / sd_high else NA

beta_low <- if (!is.null(twfe_low)) coef(twfe_low)["lottery_active"] else NA
se_low <- if (!is.null(twfe_low)) se(twfe_low)["lottery_active"] else NA
sd_low <- sd(low_gap_data$vat_gap_pct[low_gap_data$lottery_active == 0], na.rm = TRUE)
sde_low <- if (!is.na(beta_low) && !is.na(sd_low) && sd_low > 0) beta_low / sd_low else NA
se_sde_low <- if (!is.na(se_low) && !is.na(sd_low) && sd_low > 0) se_low / sd_low else NA

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states). ",
  "\\textbf{Research question:} Do VAT receipt lotteries---programs incentivizing consumers to request receipts via prize draws---reduce VAT compliance gaps across EU member states? ",
  "\\textbf{Policy mechanism:} Receipt lotteries create a consumer-as-auditor incentive: by entering purchase receipts into government-run prize draws, consumers generate a paper trail that makes it harder for merchants to underreport sales to tax authorities. ",
  "\\textbf{Outcome definition:} VAT gap as a percentage of VAT Total Tax Liability (VTTL), estimated annually by the European Commission/CASE consortium; measures the share of theoretical VAT revenue that goes uncollected. ",
  "\\textbf{Treatment:} Binary; equals one in country-years when a receipt lottery program is active, zero otherwise. ",
  "\\textbf{Data:} European Commission/CASE VAT Gap Reports (2005--2021) and Eurostat (gov\\_10a\\_taxag, nama\\_10\\_gdp); 26 EU member states (Malta excluded as always-treated), 442 country-year observations. ",
  "\\textbf{Method:} Two-way fixed effects with country and year fixed effects; standard errors clustered at the country level; Callaway and Sant'Anna (2021) as the preferred heterogeneity-robust estimator. ",
  "\\textbf{Sample:} EU-27 member states excluding Malta (treated since 1997, before sample period); 9 treated countries, 17 never-treated controls, 2005--2021 annual panel. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

fmt <- function(x, d = 3) ifelse(is.na(x), "---", sprintf(paste0("%.", d, "f"), x))

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "\\addlinespace\n",
  sprintf("VAT gap (\\%% VTTL) & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_gap, 2), fmt(se_gap, 2), fmt(sd_gap_pre, 2),
          fmt(sde_gap), fmt(se_sde_gap), classify_sde(sde_gap)),
  sprintf("VAT/GDP (\\%%) & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_vat, 3), fmt(se_vat, 3), fmt(sd_vat_gdp_pre, 3),
          fmt(sde_vat), fmt(se_sde_vat), classify_sde(sde_vat)),
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by baseline VAT gap)}} \\\\\n",
  "\\addlinespace\n",
  sprintf("High-gap countries & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_high, 2), fmt(se_high, 2), fmt(sd_high, 2),
          fmt(sde_high), fmt(se_sde_high), classify_sde(sde_high)),
  sprintf("Low-gap countries & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_low, 2), fmt(se_low, 2), fmt(sd_low, 2),
          fmt(sde_low), fmt(se_sde_low), classify_sde(sde_low)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
cat("Files: tab1_summary.tex, tab2_main.tex, tab3_cancel.tex, tab4_robust.tex, tabF1_sde.tex\n")
