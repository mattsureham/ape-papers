# 05_tables.R — Generate all LaTeX tables for APEP 1006

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE)

# Load data and results
full_panel <- fread(file.path(data_dir, "corridor_panel.csv"))
cs_sample <- fread(file.path(data_dir, "cs_sample.csv"))
main_res <- fromJSON(file.path(data_dir, "main_results.json"))
robust_res <- fromJSON(file.path(data_dir, "robustness_results.json"))
es_dt <- fread(file.path(data_dir, "event_study_results.csv"))
models <- readRDS(file.path(data_dir, "main_models.rds"))
robust_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")
fmt3 <- function(x) formatC(x, format = "f", digits = 3)
fmt4 <- function(x) formatC(x, format = "f", digits = 4)
fmtN <- function(x) formatC(x, format = "d", big.mark = ",")

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics\n")

# Overall
overall <- full_panel[, .(
  cost_mean = mean(avg_cost, na.rm = TRUE),
  cost_sd = sd(avg_cost, na.rm = TRUE),
  fx_mean = mean(avg_fx_margin, na.rm = TRUE),
  fx_sd = sd(avg_fx_margin, na.rm = TRUE),
  prov_mean = mean(n_firms, na.rm = TRUE),
  prov_sd = sd(n_firms, na.rm = TRUE),
  grey_mean = mean(grey_listed),
  N = .N
)]

# By grey-list status
by_grey <- full_panel[, .(
  cost_mean = mean(avg_cost, na.rm = TRUE),
  cost_sd = sd(avg_cost, na.rm = TRUE),
  fx_mean = mean(avg_fx_margin, na.rm = TRUE),
  fx_sd = sd(avg_fx_margin, na.rm = TRUE),
  prov_mean = mean(n_firms, na.rm = TRUE),
  prov_sd = sd(n_firms, na.rm = TRUE),
  N = .N
), by = grey_listed]

tab1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Remittance Corridor Panel}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{l rrrr rr}
\\toprule
& \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Grey-Listed} & \\multicolumn{2}{c}{Not Listed} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}
Variable & Mean & SD & Mean & SD & Mean & SD \\\\
\\midrule
Total cost (\\% of \\$200) & ", fmt(overall$cost_mean), " & ", fmt(overall$cost_sd),
" & ", fmt(by_grey[grey_listed == 1, cost_mean]), " & ", fmt(by_grey[grey_listed == 1, cost_sd]),
" & ", fmt(by_grey[grey_listed == 0, cost_mean]), " & ", fmt(by_grey[grey_listed == 0, cost_sd]), " \\\\
FX margin (\\%) & ", fmt(overall$fx_mean), " & ", fmt(overall$fx_sd),
" & ", fmt(by_grey[grey_listed == 1, fx_mean]), " & ", fmt(by_grey[grey_listed == 1, fx_sd]),
" & ", fmt(by_grey[grey_listed == 0, fx_mean]), " & ", fmt(by_grey[grey_listed == 0, fx_sd]), " \\\\
Providers per corridor & ", fmt(overall$prov_mean, 1), " & ", fmt(overall$prov_sd, 1),
" & ", fmt(by_grey[grey_listed == 1, prov_mean], 1), " & ", fmt(by_grey[grey_listed == 1, prov_sd], 1),
" & ", fmt(by_grey[grey_listed == 0, prov_mean], 1), " & ", fmt(by_grey[grey_listed == 0, prov_sd], 1), " \\\\
Grey-listed (\\%) & ", fmt(100 * overall$grey_mean, 1), " & & & & & \\\\
\\midrule
Corridor-quarters & \\multicolumn{2}{c}{", fmtN(overall$N), "} & \\multicolumn{2}{c}{",
fmtN(by_grey[grey_listed == 1, N]), "} & \\multicolumn{2}{c}{", fmtN(by_grey[grey_listed == 0, N]), "} \\\\
Unique corridors & \\multicolumn{2}{c}{", fmtN(uniqueN(full_panel$corridor_id)), "} & & & & \\\\
Sending countries & \\multicolumn{2}{c}{", fmtN(uniqueN(full_panel$source_code)), "} & & & & \\\\
Receiving countries & \\multicolumn{2}{c}{", fmtN(uniqueN(full_panel$destination_code)), "} & & & & \\\\
Quarters & \\multicolumn{2}{c}{", fmtN(uniqueN(full_panel$time_index)), "} & & & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel of corridor-quarter averages, 2011Q1--2025Q1. Total cost is the average percentage cost of sending \\$200 through all providers in the corridor, from the World Bank Remittance Prices Worldwide database. FX margin is the exchange rate markup charged by providers. Grey-listed indicates the receiving country was on the FATF ``Jurisdictions under Increased Monitoring'' list during that quarter. Provider count is the number of distinct remittance service providers observed in the corridor-quarter.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# TABLE 2: Main Results
# ============================================================================
cat("Generating Table 2: Main Results\n")

# Get CS-DiD results
cs_att <- main_res$cs_att
cs_se <- main_res$cs_se

# Get model stats
twfe_basic <- models$twfe_basic
twfe_strict <- models$twfe_strict

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# p-values
cs_p <- 2 * pnorm(-abs(cs_att / cs_se))
nyt_p <- 2 * pnorm(-abs(robust_res$nyt_att / robust_res$nyt_se))
twfe_b_p <- pvalue(twfe_basic)["grey_listed"]
twfe_s_p <- pvalue(twfe_strict)["grey_listed"]

tab2 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Effect of FATF Grey-Listing on Remittance Costs}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{l cccc}
\\toprule
& (1) & (2) & (3) & (4) \\\\
& CS-DiD & CS-DiD & TWFE & TWFE \\\\
& Never-treated & Not-yet-treated & Basic & Strict \\\\
\\midrule
Grey-listed & ", fmt4(cs_att), stars(cs_p), " & ", fmt4(robust_res$nyt_att), stars(nyt_p),
" & ", fmt4(main_res$twfe_coef), stars(twfe_b_p), " & ", fmt4(main_res$twfe_strict_coef), stars(twfe_s_p), " \\\\
& (", fmt4(cs_se), ") & (", fmt4(robust_res$nyt_se), ") & (", fmt4(main_res$twfe_se),
") & (", fmt4(main_res$twfe_strict_se), ") \\\\
& & & & \\\\
95\\% CI & [", fmt3(main_res$cs_ci_lo), ", ", fmt3(main_res$cs_ci_hi), "] & & & \\\\
\\midrule
Estimator & CS (2021) & CS (2021) & OLS & OLS \\\\
Control group & Never-treated & Not-yet-treated & --- & --- \\\\
Corridor FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\
Time FE & \\checkmark & \\checkmark & \\checkmark & --- \\\\
Source $\\times$ Time FE & --- & --- & --- & \\checkmark \\\\
Clustering & Corridor & Corridor & Destination & Destination \\\\
Observations & ", fmtN(main_res$n_obs_cs), " & ", fmtN(main_res$n_obs_cs),
" & ", fmtN(main_res$n_obs_cs), " & ", fmtN(nrow(full_panel)), " \\\\
Corridors & ", fmtN(main_res$n_corridors_cs), " & ", fmtN(main_res$n_corridors_cs),
" & ", fmtN(main_res$n_corridors_cs), " & ", fmtN(uniqueN(full_panel$corridor_id)), " \\\\
Treated corridors & ", fmtN(main_res$n_treated_corridors), " & ", fmtN(main_res$n_treated_corridors),
" & ", fmtN(main_res$n_treated_corridors), " & --- \\\\
Treatment cohorts & ", fmtN(main_res$n_cohorts), " & ", fmtN(main_res$n_cohorts), " & --- & --- \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is average total remittance cost (\\% of \\$200 sent) in the corridor-quarter. Columns (1)--(2) report the Callaway and Sant'Anna (2021) aggregate ATT, using doubly robust estimation. Column (1) uses never-treated corridors as controls; column (2) uses not-yet-treated corridors. Column (3) is two-way fixed effects with corridor and quarter fixed effects. Column (4) replaces quarter FE with source-country $\\times$ quarter FE. Standard errors in parentheses, clustered at the corridor level for CS-DiD and at the receiving-country level for TWFE. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

# ============================================================================
# TABLE 3: Event Study Coefficients
# ============================================================================
cat("Generating Table 3: Event Study\n")

es_rows <- ""
for (i in seq_len(nrow(es_dt))) {
  p_val <- 2 * pnorm(-abs(es_dt$att[i] / es_dt$se[i]))
  es_rows <- paste0(es_rows,
    "$", ifelse(es_dt$event_time[i] >= 0, "+", ""), es_dt$event_time[i], "$ & ",
    fmt4(es_dt$att[i]), stars(p_val), " & (",
    fmt4(es_dt$se[i]), ") & [",
    fmt3(es_dt$ci_lo[i]), ", ", fmt3(es_dt$ci_hi[i]), "] \\\\\n")
}

tab3 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Event Study: Dynamic Effects of Grey-Listing on Remittance Costs}
\\label{tab:eventstudy}
\\begin{threeparttable}
\\begin{tabular}{l ccc}
\\toprule
Event time & ATT & (SE) & 95\\% CI \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Pre-treatment}} \\\\
", paste(sapply(which(es_dt$event_time < 0), function(i) {
  p_val <- 2 * pnorm(-abs(es_dt$att[i] / es_dt$se[i]))
  paste0("$", es_dt$event_time[i], "$ & ", fmt4(es_dt$att[i]), stars(p_val),
         " & (", fmt4(es_dt$se[i]), ") & [", fmt3(es_dt$ci_lo[i]), ", ", fmt3(es_dt$ci_hi[i]), "] \\\\")
}), collapse = "\n"), "
\\midrule
\\multicolumn{4}{l}{\\textit{Post-treatment}} \\\\
", paste(sapply(which(es_dt$event_time >= 0), function(i) {
  p_val <- 2 * pnorm(-abs(es_dt$att[i] / es_dt$se[i]))
  paste0("$+", es_dt$event_time[i], "$ & ", fmt4(es_dt$att[i]), stars(p_val),
         " & (", fmt4(es_dt$se[i]), ") & [", fmt3(es_dt$ci_lo[i]), ", ", fmt3(es_dt$ci_hi[i]), "] \\\\")
}), collapse = "\n"), "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic aggregation with 8 pre-treatment and 12 post-treatment quarters. Estimates are the average treatment effect on the treated for each event time, with pointwise uniform confidence intervals. Pre-treatment coefficients test the parallel trends assumption.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab3, file.path(tables_dir, "tab3_eventstudy.tex"))

# ============================================================================
# TABLE 4: Robustness and Mechanisms
# ============================================================================
cat("Generating Table 4: Robustness\n")

# Compute p-values for robustness results
p_send <- robust_res$sending_placebo_p
p_bank <- if (!is.na(robust_res$bank_coef)) 2 * pnorm(-abs(robust_res$bank_coef / robust_res$bank_se)) else NA
p_mto <- 2 * pnorm(-abs(robust_res$mto_coef / robust_res$mto_se))
p_prov <- 2 * pnorm(-abs(robust_res$provider_coef / robust_res$provider_se))
p_fx <- 2 * pnorm(-abs(robust_res$fx_coef / robust_res$fx_se))

tab4 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Robustness Checks and Mechanism Tests}
\\label{tab:robust}
\\begin{threeparttable}
\\begin{tabular}{l ccc}
\\toprule
Specification & Coefficient & SE & $p$-value \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Placebo and Alternative Controls}} \\\\
Sending-country placebo & ", fmt4(robust_res$sending_placebo_coef), " & ", fmt4(robust_res$sending_placebo_se), " & ", fmt3(p_send), " \\\\
Not-yet-treated controls (CS-DiD) & ", fmt4(robust_res$nyt_att), " & ", fmt4(robust_res$nyt_se), " & ", fmt3(2 * pnorm(-abs(robust_res$nyt_att / robust_res$nyt_se))), " \\\\
FX margin (alternative outcome) & ", fmt4(robust_res$fx_coef), " & ", fmt4(robust_res$fx_se), " & ", fmt3(p_fx), " \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel B: Channel Heterogeneity}} \\\\
Bank channel only & ", fmt4(robust_res$bank_coef), " & ", fmt4(robust_res$bank_se), " & ", fmt3(p_bank), " \\\\
MTO channel only & ", fmt4(robust_res$mto_coef), " & ", fmt4(robust_res$mto_se), " & ", fmt3(p_mto), " \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel C: Extensive Margin}} \\\\
Log providers (all types) & ", fmt4(robust_res$provider_coef), " & ", fmt4(robust_res$provider_se), " & ", fmt3(p_prov), " \\\\
Bank provider count & ", fmt4(robust_res$bank_count_coef), " & ", fmt4(robust_res$bank_count_se), " & ", fmt3(2 * pnorm(-abs(robust_res$bank_count_coef / robust_res$bank_count_se))), " \\\\
MTO provider count & ", fmt4(robust_res$mto_count_coef), " & ", fmt4(robust_res$mto_count_se), " & ", fmt3(2 * pnorm(-abs(robust_res$mto_count_coef / robust_res$mto_count_se))), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A tests the identifying assumption and alternative specifications. The sending-country placebo tests whether grey-listing the \\textit{sending} country affects remittance costs to a non-listed destination (expected null). Panel B estimates the effect separately for bank and MTO providers. Panel C examines the extensive margin (provider exit). All specifications include corridor and time fixed effects with standard errors clustered at the receiving-country level (TWFE) or corridor level (CS-DiD). $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================================
cat("Generating Table F1: SDE\n")

# Main outcome: remittance cost
beta_main <- main_res$cs_att
se_main <- main_res$cs_se
sd_y <- main_res$sd_cost
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

# Bank channel
beta_bank <- robust_res$bank_coef
se_bank <- robust_res$bank_se
sd_y_bank <- full_panel[, sd(avg_cost, na.rm = TRUE)]  # approx
sde_bank <- beta_bank / sd_y_bank
se_sde_bank <- se_bank / sd_y_bank

# MTO channel
beta_mto <- robust_res$mto_coef
se_mto <- robust_res$mto_se
sd_y_mto <- full_panel[, sd(avg_cost, na.rm = TRUE)]
sde_mto <- beta_mto / sd_y_mto
se_sde_mto <- se_mto / sd_y_mto

# FX margin
beta_fx <- robust_res$fx_coef
se_fx <- robust_res$fx_se
sd_y_fx <- full_panel[!is.na(avg_fx_margin), sd(avg_fx_margin, na.rm = TRUE)]
sde_fx <- beta_fx / sd_y_fx
se_sde_fx <- se_fx / sd_y_fx

# Classification function
classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Heterogeneity: high-remittance-dependence vs low
wdi <- fread(file.path(data_dir, "wdi_remittances.csv"))
# Get average remittance % GDP by country
wdi_avg <- wdi[!is.na(remit_pct_gdp) & remit_pct_gdp > 0,
               .(avg_remit_gdp = mean(remit_pct_gdp, na.rm = TRUE)),
               by = .(iso3c)]
median_remit <- median(wdi_avg$avg_remit_gdp, na.rm = TRUE)
high_dep <- wdi_avg[avg_remit_gdp >= median_remit, iso3c]

# Split CS sample
cs_high <- cs_sample[destination_code %in% high_dep]
cs_low <- cs_sample[!destination_code %in% high_dep]

# Simple means for heterogeneity
mean_cost_high <- mean(cs_high$avg_cost, na.rm = TRUE)
mean_cost_low <- mean(cs_low$avg_cost, na.rm = TRUE)
sd_cost_high <- sd(cs_high$avg_cost, na.rm = TRUE)
sd_cost_low <- sd(cs_low$avg_cost, na.rm = TRUE)

# TWFE for heterogeneity subgroups
cs_high[, corridor_num := as.integer(factor(corridor_id))]
cs_low[, corridor_num := as.integer(factor(corridor_id))]

if (nrow(cs_high[grey_listed == 1]) > 10 && uniqueN(cs_high[grey_listed == 1, destination_code]) > 1) {
  twfe_high <- feols(avg_cost ~ grey_listed | corridor_num + time_index,
                     data = cs_high, cluster = ~destination_code)
  beta_high <- coef(twfe_high)["grey_listed"]
  se_high <- se(twfe_high)["grey_listed"]
} else {
  beta_high <- NA; se_high <- NA
}

if (nrow(cs_low[grey_listed == 1]) > 10 && uniqueN(cs_low[grey_listed == 1, destination_code]) > 1) {
  twfe_low <- feols(avg_cost ~ grey_listed | corridor_num + time_index,
                    data = cs_low, cluster = ~destination_code)
  beta_low <- coef(twfe_low)["grey_listed"]
  se_low <- se(twfe_low)["grey_listed"]
} else {
  beta_low <- NA; se_low <- NA
}

sde_high <- if (!is.na(beta_high)) beta_high / sd_cost_high else NA
se_sde_high <- if (!is.na(se_high)) se_high / sd_cost_high else NA
sde_low <- if (!is.na(beta_low)) beta_low / sd_cost_low else NA
se_sde_low <- if (!is.na(se_low)) se_low / sd_cost_low else NA

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Multi-country (49 sending, 111 receiving countries). ",
  "\\textbf{Research question:} Does placement on the FATF grey list (``Jurisdictions under Increased Monitoring'') raise the cost of sending remittances to listed countries? ",
  "\\textbf{Policy mechanism:} FATF grey-listing publicly identifies countries with anti-money-laundering deficiencies, triggering enhanced due diligence requirements for global banks and potentially leading to ``de-risking'' --- withdrawal of correspondent banking relationships from listed jurisdictions. ",
  "\\textbf{Outcome definition:} Average total cost of sending \\$200 through all remittance providers in the corridor (fees plus exchange rate margin), as a percentage of the amount sent. ",
  "\\textbf{Treatment:} Binary indicator for whether the receiving country is currently on the FATF grey list. ",
  "\\textbf{Data:} World Bank Remittance Prices Worldwide, 2011Q1--2025Q1, 378 corridors, 16,849 corridor-quarter observations aggregated from 247,490 firm-level price quotes. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with doubly robust estimation for Panel A; TWFE with corridor and time fixed effects for Panel B; standard errors clustered at the receiving-country level. ",
  "\\textbf{Sample:} All corridors in the RPW database; CS-DiD sample excludes corridors to destinations that were already grey-listed at the start of the sample period (2011Q1). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of remittance costs in the analysis sample. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Total cost (\\% of \\$200) & ", fmt4(beta_main), " & ", fmt4(se_main), " & ", fmt(sd_y), " & ", fmt4(sde_main), " & ", fmt4(se_sde_main), " & ", classify(sde_main), " \\\\
FX margin (\\%) & ", fmt4(beta_fx), " & ", fmt4(se_fx), " & ", fmt(sd_y_fx), " & ", fmt4(sde_fx), " & ", fmt4(se_sde_fx), " & ", classify(sde_fx), " \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by remittance dependence)}} \\\\",
if (!is.na(sde_high)) paste0("
High-dependence destinations & ", fmt4(beta_high), " & ", fmt4(se_high), " & ", fmt(sd_cost_high), " & ", fmt4(sde_high), " & ", fmt4(se_sde_high), " & ", classify(sde_high), " \\\\") else "",
if (!is.na(sde_low)) paste0("
Low-dependence destinations & ", fmt4(beta_low), " & ", fmt4(se_low), " & ", fmt(sd_cost_low), " & ", fmt4(sde_low), " & ", fmt4(se_sde_low), " & ", classify(sde_low), " \\\\") else "", "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("All tables generated in", tables_dir, "\n")
