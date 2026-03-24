# 05_tables.R — Generate all LaTeX tables

library(tidyverse)
library(fixest)
library(did)

data_dir <- file.path(dirname(getwd()), "data")
tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE)

load(file.path(data_dir, "analysis_panel.RData"))
load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================

# Compute summary stats
summ_data <- panel %>%
  group_by(treated) %>%
  summarise(
    n_states = n_distinct(state_fips),
    mean_estab = mean(estab, na.rm = TRUE),
    sd_estab = sd(estab, na.rm = TRUE),
    mean_emp = mean(emp, na.rm = TRUE),
    sd_emp = sd(emp, na.rm = TRUE),
    mean_payann = mean(payann, na.rm = TRUE) / 1000,
    sd_payann = sd(payann, na.rm = TRUE) / 1000,
    .groups = "drop"
  )

# Pre-treatment means
pre_summ <- panel %>%
  filter(year < 2022) %>%
  group_by(treated) %>%
  summarise(
    mean_estab_pre = mean(estab, na.rm = TRUE),
    sd_estab_pre = sd(estab, na.rm = TRUE),
    mean_emp_pre = mean(emp, na.rm = TRUE),
    sd_emp_pre = sd(emp, na.rm = TRUE),
    .groups = "drop"
  )

# Palladium prices
pd_summ <- palladium %>%
  filter(year >= 2017, year <= 2023) %>%
  summarise(
    mean_pd = mean(avg_palladium),
    sd_pd = sd(avg_palladium),
    min_pd = min(avg_palladium),
    max_pd = max(avg_palladium)
  )

fmt <- function(x, d = 1) formatC(round(x, d), format = "f", digits = d, big.mark = ",")

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Treated States} & \\multicolumn{2}{c}{Never-Treated States} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Scrap Dealers (NAICS 423930)}} \\\\\n",
  "Establishments & ", fmt(summ_data$mean_estab[2]), " & ", fmt(summ_data$sd_estab[2]), " & ",
  fmt(summ_data$mean_estab[1]), " & ", fmt(summ_data$sd_estab[1]), " \\\\\n",
  "Employment & ", fmt(summ_data$mean_emp[2]), " & ", fmt(summ_data$sd_emp[2]), " & ",
  fmt(summ_data$mean_emp[1]), " & ", fmt(summ_data$sd_emp[1]), " \\\\\n",
  "Annual payroll (\\$1000s) & ", fmt(summ_data$mean_payann[2]), " & ", fmt(summ_data$sd_payann[2]), " & ",
  fmt(summ_data$mean_payann[1]), " & ", fmt(summ_data$sd_payann[1]), " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Pre-Treatment Means (2017--2021)}} \\\\\n",
  "Establishments & ", fmt(pre_summ$mean_estab_pre[2]), " & ", fmt(pre_summ$sd_estab_pre[2]), " & ",
  fmt(pre_summ$mean_estab_pre[1]), " & ", fmt(pre_summ$sd_estab_pre[1]), " \\\\\n",
  "Employment & ", fmt(pre_summ$mean_emp_pre[2]), " & ", fmt(pre_summ$sd_emp_pre[2]), " & ",
  fmt(pre_summ$mean_emp_pre[1]), " & ", fmt(pre_summ$sd_emp_pre[1]), " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Palladium Prices (\\$/oz, 2017--2023)}} \\\\\n",
  "Annual average & \\multicolumn{2}{c}{", fmt(pd_summ$mean_pd, 0), "} & \\multicolumn{2}{c}{(SD: ", fmt(pd_summ$sd_pd, 0), ")} \\\\\n",
  "Range & \\multicolumn{4}{c}{\\$", fmt(pd_summ$min_pd, 0), " -- \\$", fmt(pd_summ$max_pd, 0), "} \\\\\n",
  "\\addlinespace\n",
  "Number of states & \\multicolumn{2}{c}{", summ_data$n_states[2], "} & \\multicolumn{2}{c}{", summ_data$n_states[1], "} \\\\\n",
  "State $\\times$ year observations & \\multicolumn{4}{c}{", nrow(panel), "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Establishments, employment, and payroll are from the Census Bureau's County Business Patterns (CBP) for NAICS 423930 (Recyclable Material Merchant Wholesalers), 2017--2023. Treated states are those that enacted catalytic converter anti-theft legislation by 2023. Palladium prices are annual averages of monthly closing prices from Yahoo Finance.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ============================================================
# Table 2: Main Results
# ============================================================

# Get CS-DiD results
att_e <- round(agg_estab$overall.att, 4)
se_e <- round(agg_estab$overall.se, 4)
pval_e <- 2 * pnorm(-abs(att_e / se_e))

att_emp_val <- round(agg_emp$overall.att, 4)
se_emp_val <- round(agg_emp$overall.se, 4)
pval_emp <- 2 * pnorm(-abs(att_emp_val / se_emp_val))

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# TWFE results
twfe_e_coef <- round(coef(twfe_estab)["post"], 4)
twfe_e_se <- round(se(twfe_estab)["post"], 4)
twfe_e_pval <- 2 * pnorm(-abs(twfe_e_coef / twfe_e_se))

twfe_emp_coef <- round(coef(twfe_emp)["post"], 4)
twfe_emp_se <- round(se(twfe_emp)["post"], 4)
twfe_emp_pval <- 2 * pnorm(-abs(twfe_emp_coef / twfe_emp_se))

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Catalytic Converter Laws on Scrap Dealer Activity}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Log Establishments} & \\multicolumn{2}{c}{Log Employment} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & TWFE & CS-DiD & TWFE & CS-DiD \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "Post $\\times$ Treated & ", twfe_e_coef, stars(twfe_e_pval), " & ", att_e, stars(pval_e),
  " & ", twfe_emp_coef, stars(twfe_emp_pval), " & ", att_emp_val, stars(pval_emp), " \\\\\n",
  " & (", twfe_e_se, ") & (", se_e, ") & (", twfe_emp_se, ") & (", se_emp_val, ") \\\\\n",
  "\\addlinespace\n",
  "State FE & Yes & --- & Yes & --- \\\\\n",
  "Year FE & Yes & --- & Yes & --- \\\\\n",
  "Estimator & TWFE & CS (2021) & TWFE & CS (2021) \\\\\n",
  "Control group & --- & Never-treated & --- & Never-treated \\\\\n",
  "Observations & ", nrow(panel), " & ", nrow(panel), " & ", nrow(panel), " & ", nrow(panel), " \\\\\n",
  "States & ", n_distinct(panel$state_fips), " & ", n_distinct(panel$state_fips),
  " & ", n_distinct(panel$state_fips), " & ", n_distinct(panel$state_fips), " \\\\\n",
  "Pre-treatment mean & ", fmt(mean(panel$estab[panel$year < 2022], na.rm = TRUE)), " & &",
  fmt(mean(panel$emp[panel$year < 2022], na.rm = TRUE)), " & \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variables are log(establishments + 1) and log(employment + 1) for NAICS 423930 (Recyclable Material Merchant Wholesalers). Columns (1) and (3) report two-way fixed effects estimates with state-clustered standard errors. Columns (2) and (4) report Callaway and Sant'Anna (2021) estimates using never-treated states as the control group. Treatment is defined as the first full calendar year after law enactment. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# ============================================================
# Table 3: Price Decomposition & Heterogeneity
# ============================================================

# Price decomposition results
# Note: pd_std is collinear with year FE (varies only by year), so it's dropped
# The interaction post:pd_std survives because it varies by state x year
price_post <- round(coef(twfe_price)["post"], 4)
price_post_se <- round(se(twfe_price)["post"], 4)
price_int <- if ("post:pd_std" %in% names(coef(twfe_price))) {
  round(coef(twfe_price)["post:pd_std"], 4)
} else { NA_real_ }
price_int_se <- if ("post:pd_std" %in% names(se(twfe_price))) {
  round(se(twfe_price)["post:pd_std"], 4)
} else { NA_real_ }

# Price p-values
pp_post <- 2 * pnorm(-abs(price_post / price_post_se))
pp_int <- if (!is.na(price_int) && !is.na(price_int_se)) {
  2 * pnorm(-abs(price_int / price_int_se))
} else { NA_real_ }

# Heterogeneity by law type
panel <- panel %>%
  mutate(
    dealer_reg = if_else(!is.na(law_type) & grepl("dealer", law_type), 1L, 0L),
    post_dealer = post * dealer_reg,
    post_penalty = post * (1L - dealer_reg)
  )
twfe_hetero <- feols(log_estab ~ post_dealer + post_penalty | state_fips + year,
                     data = panel, cluster = ~state_fips)

het_dealer <- round(coef(twfe_hetero)["post_dealer"], 4)
het_dealer_se <- round(se(twfe_hetero)["post_dealer"], 4)
het_penalty <- round(coef(twfe_hetero)["post_penalty"], 4)
het_penalty_se <- round(se(twfe_hetero)["post_penalty"], 4)

hp_dealer <- 2 * pnorm(-abs(het_dealer / het_dealer_se))
hp_penalty <- 2 * pnorm(-abs(het_penalty / het_penalty_se))

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Price Decomposition and Law-Type Heterogeneity}\n",
  "\\label{tab:decomposition}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Log Establishments} \\\\\n",
  "\\cmidrule(lr){2-3}\n",
  " & Price Decomp. & Law-Type Hetero. \\\\\n",
  " & (1) & (2) \\\\\n",
  "\\midrule\n",
  "Post $\\times$ Treated & ", price_post, stars(pp_post), " & \\\\\n",
  " & (", price_post_se, ") & \\\\\n",
  "Post $\\times$ Palladium & ", ifelse(is.na(price_int), "---", price_int), ifelse(is.na(pp_int), "", stars(pp_int)), " & \\\\\n",
  " & ", ifelse(is.na(price_int_se), "", paste0("(", price_int_se, ")")), " & \\\\\n",
  "\\addlinespace\n",
  "Post $\\times$ Dealer regulation & & ", het_dealer, stars(hp_dealer), " \\\\\n",
  " & & (", het_dealer_se, ") \\\\\n",
  "Post $\\times$ Enhanced penalty & & ", het_penalty, stars(hp_penalty), " \\\\\n",
  " & & (", het_penalty_se, ") \\\\\n",
  "\\addlinespace\n",
  "State FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "Observations & ", nrow(panel), " & ", nrow(panel), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log(establishments + 1) for NAICS 423930. Column (1) decomposes the treatment effect by including the standardized annual palladium price and its interaction with the treatment indicator. Column (2) separates the treatment effect by law type: dealer regulation (VIN marking, holding periods, purchase restrictions) versus enhanced criminal penalties only. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(tables_dir, "tab3_decomposition.tex"))
cat("Table 3 written.\n")

# ============================================================
# Table 4: Robustness
# ============================================================

# Get coefficients
rob_results <- tibble(
  spec = c("Baseline TWFE",
           "Drop Texas (first mover)",
           "Drop California",
           "Employment outcome",
           "Levels (establishments)",
           "Placebo: Auto repair",
           "Placebo: Auto parts stores"),
  coef = c(round(coef(twfe_estab)["post"], 4),
           round(coef(loo_tx)["post"], 4),
           round(coef(loo_ca)["post"], 4),
           round(coef(rob_emp)["post"], 4),
           round(coef(levels_estab)["post"], 2),
           round(coef(placebo_repair)["post"], 4),
           round(coef(placebo_parts)["post"], 4)),
  se = c(round(se(twfe_estab)["post"], 4),
         round(se(loo_tx)["post"], 4),
         round(se(loo_ca)["post"], 4),
         round(se(rob_emp)["post"], 4),
         round(se(levels_estab)["post"], 2),
         round(se(placebo_repair)["post"], 4),
         round(se(placebo_parts)["post"], 4)),
  outcome = c("Log estab.", "Log estab.", "Log estab.",
              "Log emp.", "Estab. (levels)",
              "Log estab.", "Log estab."),
  naics = c(rep("423930", 5), "811111", "441310")
)

rob_results <- rob_results %>%
  mutate(pval = 2 * pnorm(-abs(coef / se)),
         star = sapply(pval, stars))

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks and Placebo Tests}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccc}\n",
  "\\toprule\n",
  "Specification & Outcome & Coefficient & SE & NAICS \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(rob_results)) {
  r <- rob_results[i, ]
  tab4 <- paste0(tab4,
    r$spec, " & ", r$outcome, " & ", r$coef, r$star, " & (", r$se, ") & ", r$naics, " \\\\\n")
}

tab4 <- paste0(tab4,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications include state and year fixed effects with standard errors clustered at the state level. Placebo outcomes use establishment counts in industries that should not be directly affected by catalytic converter anti-theft legislation. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

# ============================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY
# ============================================================

# Compute SDE for main outcomes
sd_y_estab_pre <- sd(panel$log_estab[panel$year < 2022], na.rm = TRUE)
sd_y_emp_pre <- sd(panel$log_emp[panel$year < 2022], na.rm = TRUE)

sde_estab <- att_e / sd_y_estab_pre
se_sde_estab <- se_e / sd_y_estab_pre

sde_emp <- att_emp_val / sd_y_emp_pre
se_sde_emp <- se_emp_val / sd_y_emp_pre

# Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: dealer regulation vs enhanced penalty
panel_dealer <- panel %>% filter(dealer_reg == 1 | !treated)
panel_penalty <- panel %>% filter(dealer_reg == 0 | !treated)

twfe_dealer_sub <- feols(log_estab ~ post | state_fips + year,
                         data = panel_dealer, cluster = ~state_fips)
twfe_penalty_sub <- feols(log_estab ~ post | state_fips + year,
                          data = panel_penalty, cluster = ~state_fips)

sde_dealer <- round(coef(twfe_dealer_sub)["post"], 4) / sd_y_estab_pre
se_sde_dealer <- round(se(twfe_dealer_sub)["post"], 4) / sd_y_estab_pre
sde_penalty <- round(coef(twfe_penalty_sub)["post"], 4) / sd_y_estab_pre
se_sde_penalty <- round(se(twfe_penalty_sub)["post"], 4) / sd_y_estab_pre

fmt4 <- function(x) formatC(round(x, 4), format = "f", digits = 4)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state catalytic converter anti-theft laws reduce scrap metal recycling establishment counts and employment? ",
  "\\textbf{Policy mechanism:} States enacted laws requiring scrap metal dealers to verify seller identity, record vehicle identification numbers, observe holding periods before resale, and meet minimum purchase price thresholds for catalytic converters, creating compliance costs that may deter marginal dealers from operating. ",
  "\\textbf{Outcome definition:} Log of annual establishment count (log(ESTAB + 1)) and log of annual employment (log(EMP + 1)) for NAICS 423930 (Recyclable Material Merchant Wholesalers) from Census County Business Patterns. ",
  "\\textbf{Treatment:} Binary; equals one in the first full calendar year after state enactment of catalytic converter anti-theft legislation. ",
  "\\textbf{Data:} Census County Business Patterns (CBP), 2017--2023, state-year level, ", nrow(panel), " observations across ", n_distinct(panel$state_fips), " states. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered difference-in-differences with never-treated states as control group; TWFE shown for comparison; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 50 U.S.\\ states excluding D.C.; 33 treated states (laws enacted 2021--2024), 17 never-treated through 2023. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Establishments & ", fmt4(att_e), " & ", fmt4(se_e), " & ", fmt4(sd_y_estab_pre),
  " & ", fmt4(sde_estab), " & ", fmt4(se_sde_estab), " & ", classify_sde(sde_estab), " \\\\\n",
  "Employment & ", fmt4(att_emp_val), " & ", fmt4(se_emp_val), " & ", fmt4(sd_y_emp_pre),
  " & ", fmt4(sde_emp), " & ", fmt4(se_sde_emp), " & ", classify_sde(sde_emp), " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Law Type)}} \\\\\n",
  "Estab. (dealer regulation) & ", fmt4(coef(twfe_dealer_sub)["post"]), " & ",
  fmt4(se(twfe_dealer_sub)["post"]), " & ", fmt4(sd_y_estab_pre),
  " & ", fmt4(sde_dealer), " & ", fmt4(se_sde_dealer), " & ", classify_sde(sde_dealer), " \\\\\n",
  "Estab. (enhanced penalty) & ", fmt4(coef(twfe_penalty_sub)["post"]), " & ",
  fmt4(se(twfe_penalty_sub)["post"]), " & ", fmt4(sd_y_estab_pre),
  " & ", fmt4(sde_penalty), " & ", fmt4(se_sde_penalty), " & ", classify_sde(sde_penalty), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

# ============================================================
# Table 5: Event Study Coefficients
# ============================================================

es_data <- tibble(
  period = es_estab$egt,
  att = round(es_estab$att.egt, 4),
  se = round(es_estab$se.egt, 4)
) %>%
  mutate(pval = 2 * pnorm(-abs(att / se)),
         star = sapply(pval, stars))

tab5 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study Estimates: Log Establishments}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Period Relative to Treatment & ATT & SE \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(es_data)) {
  r <- es_data[i, ]
  label <- if_else(r$period < 0, paste0("$t", r$period, "$"), paste0("$t+", r$period, "$"))
  tab5 <- paste0(tab5, label, " & ", r$att, r$star, " & (", r$se, ") \\\\\n")
}

tab5 <- paste0(tab5,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic treatment effect estimates for log(establishments + 1) of NAICS 423930. Never-treated states serve as the control group. Standard errors are reported in parentheses. Period 0 is the first full year of treatment. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab5, file.path(tables_dir, "tab5_eventstudy.tex"))
cat("Table 5 written.\n")

cat("\nAll tables generated.\n")
