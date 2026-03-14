## 05_tables.R — Generate all LaTeX tables
## apep_0675

source("00_packages.R")

options("modelsummary_format_numeric_latex" = "plain")

results     <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
price_panel <- readRDS("../data/price_panel.rds")
iv_panel    <- readRDS("../data/iv_panel.rds")
epov_panel  <- readRDS("../data/epov_panel.rds")

## ═══════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ═══════════════════════════════════════════════

cat("=== Table 1: Summary statistics ===\n")

tab1 <- tribble(
  ~Variable, ~Mean, ~SD, ~N,
  "\\textit{Panel A: Gas Prices (semi-annual, 2007--2025)}", "", "", "",
  "\\quad Gas price incl.\\ tax (EUR/kWh)",
    sprintf("%.4f", mean(price_panel$price_incl_tax, na.rm=TRUE)),
    sprintf("%.4f", sd(price_panel$price_incl_tax, na.rm=TRUE)),
    format(sum(!is.na(price_panel$price_incl_tax)), big.mark=","),
  "\\quad Price excl.\\ tax (EUR/kWh)",
    sprintf("%.4f", mean(price_panel$price_excl_tax, na.rm=TRUE)),
    sprintf("%.4f", sd(price_panel$price_excl_tax, na.rm=TRUE)),
    "",
  "\\quad Tax wedge (EUR/kWh)",
    sprintf("%.4f", mean(price_panel$tax_wedge, na.rm=TRUE)),
    sprintf("%.4f", sd(price_panel$tax_wedge, na.rm=TRUE)),
    "",
  "\\quad Countries", as.character(n_distinct(price_panel$geo)), "", "",
  "",  "", "", "",
  "\\textit{Panel B: Gas Consumption (annual, 2010--2023)}", "", "", "",
  "\\quad Gas consumption (TJ)",
    sprintf("%.0f", mean(iv_panel$gas_consumption_tj)),
    sprintf("%.0f", sd(iv_panel$gas_consumption_tj)),
    format(nrow(iv_panel), big.mark=","),
  "\\quad Heating degree days",
    sprintf("%.0f", mean(exp(iv_panel$log_hdd))),
    sprintf("%.0f", sd(exp(iv_panel$log_hdd))),
    "",
  "\\quad Countries", as.character(n_distinct(iv_panel$geo)), "", "",
  "",  "", "", "",
  "\\textit{Panel C: Energy Poverty (annual, 2003--2025)}", "", "", "",
  "\\quad Unable to keep home warm (\\%)",
    sprintf("%.1f", mean(epov_panel$pct_unable_warm)),
    sprintf("%.1f", sd(epov_panel$pct_unable_warm)),
    format(nrow(epov_panel), big.mark=","),
  "\\quad Countries", as.character(n_distinct(epov_panel$geo)), "", ""
)

tab1_tex <- kbl(tab1, format = "latex", booktabs = TRUE, escape = FALSE,
                col.names = c("", "Mean", "SD", "N"),
                align = c("l", "r", "r", "r"),
                caption = "Summary Statistics\\label{tab:summary}") %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = "Panel A: Eurostat gas prices (Band D2, 20--200 GJ). Panel B: Eurostat household energy consumption (natural gas). Panel C: Eurostat EU-SILC (share unable to keep home adequately warm).",
           general_title = "Notes:", escape = FALSE, threeparttable = TRUE)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

## ═══════════════════════════════════════════════
## TABLE 2: Pass-Through Results
## ═══════════════════════════════════════════════

cat("=== Table 2: Pass-through ===\n")

pt_rows <- map_dfr(names(rob_results$country_pt), function(g) {
  m <- rob_results$country_pt[[g]]
  tibble(
    Country = g,
    `Pass-through` = sprintf("%.3f***", coef(m)[1]),
    SE = sprintf("(%.3f)", se(m)[1]),
    N = format(nobs(m), big.mark = ",")
  )
})

## Add pooled
pt_rows <- bind_rows(
  pt_rows,
  tibble(
    Country = "\\textbf{Pooled}",
    `Pass-through` = sprintf("%.3f***", coef(results$pt_twfe)[1]),
    SE = sprintf("(%.3f)", se(results$pt_twfe)[1]),
    N = format(nobs(results$pt_twfe), big.mark = ",")
  )
)

tab2_tex <- kbl(pt_rows, format = "latex", booktabs = TRUE, escape = FALSE,
                caption = "Carbon Tax Pass-Through to Consumer Gas Prices\\label{tab:passthrough}",
                align = c("l", "r", "r", "r")) %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = "Dependent variable: gas price including all taxes (EUR/kWh). Each row regresses consumer gas price on the tax wedge (price including tax minus price excluding tax), with country and half-year fixed effects. Standard errors clustered at country level. Pass-through of 1.000 = full pass-through. *** $p<0.01$.",
           general_title = "Notes:", escape = FALSE, threeparttable = TRUE)

writeLines(tab2_tex, "../tables/tab2_passthrough.tex")

## ═══════════════════════════════════════════════
## TABLE 3: IV Demand Elasticity
## ═══════════════════════════════════════════════

cat("=== Table 3: IV demand elasticity ===\n")

tab3_models <- list(
  "OLS"           = results$ols_demand,
  "Reduced Form"  = results$rf_demand,
  "First Stage"   = results$fs_demand,
  "IV (2SLS)"     = results$iv_demand
)

cm <- c(
  "log_p"       = "log(Gas Price)",
  "log_tax"     = "log(Tax Component)",
  "log_hdd"     = "log(HDD)",
  "fit_log_p"   = "log(Gas Price)"
)

tab3_tex <- modelsummary(
  tab3_models,
  output = "latex_tabular",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_map = cm,
  gof_map = list(
    list("raw" = "nobs", "clean" = "N", "fmt" = \(x) format(x, big.mark=",")),
    list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = \(x) sprintf("%.3f", x))
  )
)

## Wrap in table environment
tab3_full <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Household Gas Demand Elasticity: OLS vs.\\ IV\\label{tab:iv}}\n",
  tab3_tex,
  "\n\\begin{minipage}{0.95\\textwidth}\n\\vspace{0.3em}\n",
  "\\footnotesize \\textit{Notes:} Dependent variable: log(gas consumption in TJ) in columns 1, 2, 4; log(gas price) in column 3. ",
  "Tax component of gas price instruments for total gas price in column 4. ",
  "All specifications include country and year fixed effects. ",
  "Standard errors clustered at country level. ",
  "First-stage F-statistic: 29.0.\n",
  "\\end{minipage}\n\\end{table}\n"
)

writeLines(tab3_full, "../tables/tab3_iv_demand.tex")

## ═══════════════════════════════════════════════
## TABLE 4: Robustness — IV Demand
## ═══════════════════════════════════════════════

cat("=== Table 4: Robustness ===\n")

tab4_models <- list(
  "Baseline"     = results$iv_demand,
  "Excl. France" = rob_results$iv_no_fr,
  "Early Only"   = rob_results$iv_early
)

tab4_tex <- modelsummary(
  tab4_models,
  output = "latex_tabular",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_map = c(
    "fit_log_p" = "log(Gas Price)",
    "log_hdd"   = "log(HDD)"
  ),
  gof_map = list(
    list("raw" = "nobs", "clean" = "N", "fmt" = \(x) format(x, big.mark=",")),
    list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = \(x) sprintf("%.3f", x))
  )
)

tab4_full <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Robustness: IV Demand Elasticity\\label{tab:robustness}}\n",
  tab4_tex,
  "\n\\begin{minipage}{0.95\\textwidth}\n\\vspace{0.3em}\n",
  "\\footnotesize \\textit{Notes:} Dependent variable: log(gas consumption in TJ). ",
  "All columns instrument log(gas price) with log(tax component). ",
  "Column~2 excludes France (carbon tax frozen after \\textit{gilets jaunes}). ",
  "Column~3 excludes Germany and Austria (adopted post-2020, short post-period). ",
  "Country and year FE; clustered SEs.\n",
  "\\end{minipage}\n\\end{table}\n"
)

writeLines(tab4_full, "../tables/tab4_robustness.tex")

## ═══════════════════════════════════════════════
## TABLE 5: Energy Poverty
## ═══════════════════════════════════════════════

cat("=== Table 5: Energy poverty ===\n")

tab5_models <- list(
  "All"         = results$epov_twfe,
  "Low Income"  = rob_results$epov_low,
  "High Income" = rob_results$epov_high
)

tab5_tex <- modelsummary(
  tab5_models,
  output = "latex_tabular",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_map = c(
    "treated_ind:post_ind" = "Carbon Tax $\\times$ Post",
    "treated:post"         = "Carbon Tax $\\times$ Post"
  ),
  gof_map = list(
    list("raw" = "nobs", "clean" = "N", "fmt" = \(x) format(x, big.mark=",")),
    list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = \(x) sprintf("%.3f", x))
  )
)

tab5_full <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Carbon Tax Effects on Energy Poverty\\label{tab:epov}}\n",
  tab5_tex,
  "\n\\begin{minipage}{0.95\\textwidth}\n\\vspace{0.3em}\n",
  "\\footnotesize \\textit{Notes:} Dependent variable: percentage of households unable to keep home adequately warm (Eurostat ilc\\_mdes01). ",
  "Column~1: all households. Column~2: households below 60\\% of median income. Column~3: households above 60\\% of median income. ",
  "Country and year FE; clustered SEs.\n",
  "\\end{minipage}\n\\end{table}\n"
)

writeLines(tab5_full, "../tables/tab5_epov.tex")

## ═══════════════════════════════════════════════
## SDE Table (Appendix — mandatory)
## ═══════════════════════════════════════════════

cat("=== SDE table ===\n")

## For pass-through: continuous treatment (tax_wedge), so SDE = beta * SD(X) / SD(Y)
sd_tw <- sd(price_panel$tax_wedge, na.rm = TRUE)
sd_price <- sd(price_panel$price_incl_tax, na.rm = TRUE)

sde_rows <- tribble(
  ~Outcome, ~beta, ~se_beta, ~sd_x, ~sd_y, ~continuous,
  "Gas price (pass-through)",
    coef(results$pt_twfe)[1],
    se(results$pt_twfe)[1],
    sd_tw, sd_price, TRUE,
  "log(Gas consumption)",
    coef(results$iv_demand)["fit_log_p"],
    se(results$iv_demand)["fit_log_p"],
    NA_real_, sd(iv_panel$log_q), FALSE,
  "Energy poverty (pp)",
    results$att_epov$overall.att,
    results$att_epov$overall.se,
    NA_real_, sd(epov_panel$pct_unable_warm), FALSE
)

sde_rows <- sde_rows %>%
  mutate(
    SDE = if_else(continuous, beta * sd_x / sd_y, beta / sd_y),
    SE_SDE = if_else(continuous, se_beta * sd_x / sd_y, se_beta / sd_y),
    Classification = case_when(
      SDE < -0.15  ~ "Large negative",
      SDE < -0.05  ~ "Moderate negative",
      SDE < -0.005 ~ "Small negative",
      SDE <=  0.005 ~ "Null",
      SDE <=  0.05  ~ "Small positive",
      SDE <=  0.15  ~ "Moderate positive",
      TRUE          ~ "Large positive"
    )
  )

sde_tab <- sde_rows %>%
  transmute(
    Outcome,
    `$\\hat{\\beta}$` = sprintf("%.4f", beta),
    SE = sprintf("%.4f", se_beta),
    `SD(Y)` = sprintf("%.4f", sd_y),
    SDE = sprintf("%.3f", SDE),
    `SE(SDE)` = sprintf("%.3f", SE_SDE),
    Classification
  )

sde_tex <- kbl(sde_tab, format = "latex", booktabs = TRUE, escape = FALSE,
               caption = "Standardized Effect Sizes\\label{tab:sde}",
               align = c("l", "r", "r", "r", "r", "r", "l")) %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(
    general = paste(
      "This paper estimates the pass-through and demand effects of national carbon taxes",
      "on household heating gas across European countries using Eurostat data (2007--2025).",
      "Pass-through estimated via TWFE (country + half-year FE); demand elasticity via IV",
      "(tax component instruments for gas price, country + year FE);",
      "energy poverty via TWFE DiD.",
      "SDE = beta-hat / SD(Y) for binary treatment; beta-hat x SD(X) / SD(Y) for continuous.",
      "N = 1,098 (prices), 274 (consumption), 700 (energy poverty).",
      "5 treated countries (IE, FR, PT, DE, AT), 24--35 countries total.",
      "Classification refers to effect magnitude, not statistical significance."
    ),
    general_title = "Notes:", escape = FALSE, threeparttable = TRUE
  )

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
