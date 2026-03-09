## ============================================================
## 06_tables.R — All table generation
## Cap On, Cap Off: Kenya's Interest Rate Ceiling (2016-2019)
## ============================================================

source("00_packages.R")

## --- Load Data ---
tier_panel   <- fread(file.path(DATA_DIR, "tier_panel_clean.csv"))
cc_all       <- fread(file.path(DATA_DIR, "cross_country_clean.csv"))
tier_summary <- fread(file.path(DATA_DIR, "tier_summary.csv"))
main_tier    <- fread(file.path(DATA_DIR, "main_results_tier.csv"))
main_cc      <- fread(file.path(DATA_DIR, "main_results_cc.csv"))
symmetry     <- fread(file.path(DATA_DIR, "symmetry_test.csv"))

# Recreate variables
tier_panel <- tier_panel |>
  mutate(
    is_tier3 = as.integer(tier == "Tier3"),
    cap_on = as.integer(year >= 2017 & year <= 2019),
    repeal = as.integer(year >= 2020),
    exposure_cap = exposure * cap_on,
    exposure_repeal = exposure * repeal
  )

cc_all <- cc_all |> mutate(treated = as.integer(country == "KE"))

## ============================================================
## TABLE 1: Summary Statistics by Tier and Period
## ============================================================

tab1 <- tier_panel |>
  mutate(
    period_broad = case_when(
      year < 2017 ~ "Pre-Cap (2010-2016)",
      year <= 2019 ~ "Cap On (2017-2019)",
      TRUE ~ "Post-Repeal (2020-2023)"
    )
  ) |>
  group_by(tier, period_broad) |>
  summarise(
    Years = n(),
    `Assets (KES bn)` = sprintf("%.0f", mean(total_assets_bn)),
    `Loans (KES bn)` = sprintf("%.0f", mean(loans_advances_bn)),
    `Loan/Asset` = sprintf("%.3f", mean(loan_asset_ratio)),
    `Govt Sec/Asset` = sprintf("%.3f", mean(govt_sec_ratio)),
    `NPL Ratio (\\%)` = sprintf("%.1f", mean(npl_ratio)),
    `N Banks` = sprintf("%.0f", mean(n_banks)),
    .groups = "drop"
  ) |>
  arrange(tier, period_broad)

# Write LaTeX
tab1_latex <- kbl(tab1, format = "latex", booktabs = TRUE, escape = FALSE,
                  caption = "Summary Statistics by Bank Tier and Policy Period",
                  label = "tab:summary") |>
  kable_styling(latex_options = "hold_position") |>
  pack_rows("Tier 1 (Large)", 1, 3) |>
  pack_rows("Tier 2 (Medium)", 4, 6) |>
  pack_rows("Tier 3 (Small)", 7, 9) |>
  footnote(general = "Source: Central Bank of Kenya Annual Reports, 2010--2023. Tier classification follows CBK peer grouping. Loan/Asset is the ratio of loans and advances to total assets. Govt Sec/Asset is government securities holdings divided by total assets. NPL ratio is non-performing loans as a percentage of total loans.",
           threeparttable = TRUE)

writeLines(as.character(tab1_latex), file.path(TAB_DIR, "tab1_summary.tex"))
cat("Saved: tab1_summary.tex\n")

## ============================================================
## TABLE 2: Main DiD Results — Tier-Level Analysis
## ============================================================

# Re-run models for consistent table
m_loan  <- feols(loan_asset_ratio ~ is_tier3:cap_on + is_tier3:repeal | tier + year,
                 data = tier_panel, cluster = ~tier)
m_govt  <- feols(govt_sec_ratio ~ is_tier3:cap_on + is_tier3:repeal | tier + year,
                 data = tier_panel, cluster = ~tier)
m_npl   <- feols(npl_ratio ~ is_tier3:cap_on + is_tier3:repeal | tier + year,
                 data = tier_panel, cluster = ~tier)
m_lloan <- feols(log(loans_advances_bn) ~ is_tier3:cap_on + is_tier3:repeal | tier + year,
                 data = tier_panel, cluster = ~tier)

# Modelsummary output
tab2_models <- list(
  "Loan/Asset" = m_loan,
  "Govt Sec/Asset" = m_govt,
  "NPL Ratio" = m_npl,
  "Log Loans" = m_lloan
)

tab2_latex <- modelsummary(
  tab2_models,
  output = "latex",
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_rename = c(
    "is_tier3:cap_on" = "Tier 3 $\\times$ Cap On",
    "is_tier3:repeal" = "Tier 3 $\\times$ Post-Repeal"
  ),
  gof_map = c("nobs", "r.squared", "FE: tier", "FE: year"),
  title = "Differential Impact of Interest Rate Cap by Bank Tier",
  notes = c(
    "Standard errors clustered at the bank-tier level in parentheses.",
    "Tier 3 banks are small, SME-focused banks (n$\\approx$21).",
    "Cap On covers 2017--2019 (full cap years). Post-Repeal covers 2020--2023.",
    "All specifications include bank-tier and year fixed effects.",
    "Source: CBK Annual Reports, 2010--2023."
  ),
  escape = FALSE
)

tab2_str <- as.character(tab2_latex)
tab2_str <- sub("(caption=\\{[^}]+\\})",
                "\\1,\nlabel={tab:main_did},", tab2_str)
writeLines(tab2_str, file.path(TAB_DIR, "tab2_main_did.tex"))
cat("Saved: tab2_main_did.tex\n")

## ============================================================
## TABLE 3: Cross-Country DiD Results
## ============================================================

m_cc_credit <- feols(credit_gdp ~ treated:cap_on + treated:repeal | country + year,
                     data = cc_all |> filter(!is.na(credit_gdp)), cluster = ~country)
m_cc_rate   <- feols(lending_rate ~ treated:cap_on + treated:repeal | country + year,
                     data = cc_all |> filter(!is.na(lending_rate)), cluster = ~country)
m_cc_npl    <- feols(npl_ratio ~ treated:cap_on + treated:repeal | country + year,
                     data = cc_all |> filter(!is.na(npl_ratio)), cluster = ~country)

tab3_models <- list(
  "Credit/GDP" = m_cc_credit,
  "Lending Rate" = m_cc_rate,
  "NPL Ratio" = m_cc_npl
)

tab3_latex <- modelsummary(
  tab3_models,
  output = "latex",
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  coef_rename = c(
    "treated:cap_on" = "Kenya $\\times$ Cap On",
    "treated:repeal" = "Kenya $\\times$ Post-Repeal"
  ),
  gof_map = c("nobs", "r.squared", "FE: country", "FE: year"),
  title = "Cross-Country Difference-in-Differences: Kenya vs.~East African Peers",
  notes = c(
    "Standard errors clustered at the country level in parentheses.",
    "Control countries: Uganda, Tanzania, Rwanda.",
    "Credit/GDP is domestic credit to private sector as percentage of GDP.",
    "Source: World Bank World Development Indicators, 2010--2023."
  ),
  escape = FALSE
)

tab3_str <- as.character(tab3_latex)
tab3_str <- sub("(caption=\\{[^}]+\\})",
                "\\1,\nlabel={tab:crosscountry},", tab3_str)
writeLines(tab3_str, file.path(TAB_DIR, "tab3_cross_country.tex"))
cat("Saved: tab3_cross_country.tex\n")

## ============================================================
## TABLE 4: Symmetry/Hysteresis Test
## ============================================================

# Test: Does repeal reverse the cap effect?
sym_results <- tibble(
  Outcome = c("Loan/Asset Ratio", "Govt Sec/Asset Ratio", "NPL Ratio"),
  `$\\hat{\\beta}_{\\text{Cap}}$` = c(
    coef(m_loan)["is_tier3:cap_on"],
    coef(m_govt)["is_tier3:cap_on"],
    coef(m_npl)["is_tier3:cap_on"]
  ),
  `$\\hat{\\beta}_{\\text{Repeal}}$` = c(
    coef(m_loan)["is_tier3:repeal"],
    coef(m_govt)["is_tier3:repeal"],
    coef(m_npl)["is_tier3:repeal"]
  )
) |>
  mutate(
    # Round coefficients to 4 decimal places first
    cap_rounded = round(`$\\hat{\\beta}_{\\text{Cap}}$`, 4),
    rep_rounded = round(`$\\hat{\\beta}_{\\text{Repeal}}$`, 4),
    `Reversal (\\%)` = sprintf("%.1f",
      -(rep_rounded - cap_rounded) / cap_rounded * 100),
    `Sum` = cap_rounded + rep_rounded,
    across(where(is.numeric), ~ sprintf("%.4f", .))
  ) |>
  select(-cap_rounded, -rep_rounded)

tab4_latex <- kbl(sym_results, format = "latex", booktabs = TRUE, escape = FALSE,
                  caption = "Symmetry Test: Does Repeal Reverse Credit Rationing?",
                  label = "tab:symmetry") |>
  kable_styling(latex_options = "hold_position") |>
  footnote(general = c(
    "Full reversal implies $\\hat{\\beta}_{\\text{Repeal}} = 0$ (outcomes return to baseline), i.e., Reversal = 100\\%.",
    "Full hysteresis implies $\\hat{\\beta}_{\\text{Repeal}} \\approx \\hat{\\beta}_{\\text{Cap}}$ (damage persists), i.e., Reversal $\\approx$ 0\\%.",
    "All specifications include tier and year fixed effects."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(as.character(tab4_latex), file.path(TAB_DIR, "tab4_symmetry.tex"))
cat("Saved: tab4_symmetry.tex\n")

## ============================================================
## TABLE 5: Robustness Summary
## ============================================================

# Load robustness results
rob_alt   <- fread(file.path(DATA_DIR, "robustness_alt_exposure.csv"))
rob_loo   <- fread(file.path(DATA_DIR, "robustness_loo.csv"))
rob_plac  <- fread(file.path(DATA_DIR, "robustness_placebo.csv"))
rob_ri    <- fread(file.path(DATA_DIR, "robustness_ri.csv"))

# Helper: add significance stars based on |coef/se|
add_stars <- function(coef_val, se_val) {
  if (is.na(coef_val) || is.na(se_val) || se_val == 0) return(sprintf("%.4f", coef_val))
  tstat <- abs(coef_val / se_val)
  stars <- ifelse(tstat >= 2.576, "***", ifelse(tstat >= 1.96, "**", ifelse(tstat >= 1.645, "*", "")))
  paste0(sprintf("%.4f", coef_val), stars)
}

# Gather coefficients and SEs for each robustness row
baseline_coef <- coef(m_loan)["is_tier3:cap_on"]
baseline_se   <- coeftable(m_loan)["is_tier3:cap_on", 2]

cont_row <- main_tier |> filter(model == "Loan/Asset (Continuous)", grepl("exposure_cap", term))
cont_coef <- cont_row$estimate[1]
cont_se   <- cont_row$std_error[1]

tier2_coef <- rob_alt$coef_cap[1]
tier2_se   <- rob_alt$se_cap[1]

govt_coef <- rob_alt$coef_cap[2]
govt_se   <- rob_alt$se_cap[2]

# Pre-COVID: re-estimate to get SE
pre_covid_data <- tier_panel |> filter(year <= 2019)
m_precovid_tab <- feols(loan_asset_ratio ~ is_tier3:cap_on | tier + year,
                        data = pre_covid_data, cluster = ~tier)
precovid_coef <- coef(m_precovid_tab)[1]
precovid_se   <- coeftable(m_precovid_tab)[1, 2]

ri_coef <- rob_ri$obs_stat
ri_pval <- rob_ri$ri_pvalue
ri_stars <- ifelse(ri_pval <= 0.01, "***", ifelse(ri_pval <= 0.05, "**", ifelse(ri_pval <= 0.1, "*", "")))

rob_summary <- tibble(
  Specification = c(
    "Baseline (Tier 3 $\\times$ Cap On)",
    "Continuous exposure $\\times$ Cap On",
    "Tier 2 vs Tier 1",
    "Low govt sec exposure",
    "Pre-COVID only (2010--2019)",
    "Randomization Inference"
  ),
  Coefficient = c(
    add_stars(baseline_coef, baseline_se),
    add_stars(cont_coef, cont_se),
    sprintf("%.4f", tier2_coef),  # No stars: only 2 comparison groups, asymptotic inference unreliable
    add_stars(govt_coef, govt_se),
    add_stars(precovid_coef, precovid_se),
    paste0(sprintf("%.4f", ri_coef), ri_stars)
  ),
  `Std.~Error` = c(
    sprintf("(%.4f)", baseline_se),
    sprintf("(%.4f)", cont_se),
    sprintf("(%.4f)$^\\dagger$", tier2_se),
    sprintf("(%.4f)", govt_se),
    sprintf("(%.4f)", precovid_se),
    sprintf("RI $p$ = %.3f", max(ri_pval, 1/1001))
  )
)

tab5_latex <- kbl(rob_summary, format = "latex", booktabs = TRUE, escape = FALSE,
                  caption = "Robustness: Alternative Specifications for Loan/Asset Ratio",
                  label = "tab:robustness") |>
  kable_styling(latex_options = "hold_position") |>
  footnote(general = "All specifications include tier and year fixed effects. Standard errors clustered at tier level in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$. $^\\dagger$ Only two comparison groups (Tier 1, Tier 2); asymptotic inference unreliable. RI p-value based on 1,000 permutations of tier labels.",
           threeparttable = TRUE, escape = FALSE)

writeLines(as.character(tab5_latex), file.path(TAB_DIR, "tab5_robustness.tex"))
cat("Saved: tab5_robustness.tex\n")

cat("\n=== All tables generated ===\n")
