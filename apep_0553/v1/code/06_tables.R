## 06_tables.R — Generate LaTeX tables for the paper
## apep_0553: Do Export Controls Have Teeth?

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

## ============================================================
## Load regression results
## ============================================================

panel <- fread(file.path(DATA_DIR, "panel_hs6.csv"))
has_control <- any(panel$role == "control")
main_coefs <- fread(file.path(DATA_DIR, "main_regression_coefs.csv"))
tier_coefs <- fread(file.path(DATA_DIR, "tier_regression_coefs.csv"))
sumstats <- fread(file.path(DATA_DIR, "summary_statistics.csv"))
leakage <- fread(file.path(DATA_DIR, "leakage_rates.csv"))
robust_coefs <- tryCatch(fread(file.path(DATA_DIR, "robustness_coefs.csv")),
                         error = function(e) data.table())
loo_dt <- tryCatch(fread(file.path(DATA_DIR, "leave_one_out.csv")),
                   error = function(e) data.table())

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================

if (has_control) {
  analysis <- panel[role %in% c("transit", "control")]
} else {
  analysis <- panel[role == "transit"]
}

tab1_data <- analysis[, .(
  `Mean Trade (\\$)` = sprintf("%.0f", mean(fob_value)),
  `SD Trade (\\$)` = sprintf("%.0f", sd(fob_value)),
  `\\% Positive` = sprintf("%.1f", mean(trade_positive) * 100),
  `N` = format(.N, big.mark = ",")
), by = .(Role = ifelse(role == "transit", "Transit", "Control"),
          Product = ifelse(is_chpl, "CHPL", "Non-CHPL"),
          Period = fcase(
            year <= 2021, "Pre-sanctions (2015-2021)",
            year %in% 2022:2023, "Post-sanctions (2022-2023)",
            year == 2024, "Post-CHPL (2024)"
          ))]

tab1_data <- tab1_data[order(Role, Product, Period)]

tab1_latex <- kbl(tab1_data, format = "latex", booktabs = TRUE, escape = FALSE,
                  caption = "Summary Statistics: Bilateral Trade at HS6 Level",
                  label = "tab:sumstats") |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = "Source: UN Comtrade. Trade values are FOB exports to Russia (partner code 643). Transit countries: Kyrgyzstan, Armenia, Kazakhstan. CHPL = Common High Priority Items List (24 HS6 codes from the full 46-code list). Data downloaded February 2026; full-year 2024 data confirmed available for all three countries.",
           general_title = "Notes:", threeparttable = TRUE)

writeLines(tab1_latex, file.path(TABLE_DIR, "table1_sumstats.tex"))
cat("Table 1 saved.\n")

## ============================================================
## TABLE 2: Main DDD Results
## ============================================================

# Re-run regressions to build modelsummary table
analysis[, is_chpl_num := as.integer(is_chpl)]
analysis[, is_transit_num := as.integer(is_transit)]
analysis[, chpl_post := is_chpl_num * post_sanctions]
analysis[, chpl_post_chpl := is_chpl_num * post_chpl]
analysis[, transit_post := is_transit_num * post_sanctions]
analysis[, transit_chpl_post := is_transit_num * is_chpl_num * post_sanctions]
analysis[, transit_chpl_postchpl := is_transit_num * is_chpl_num * post_chpl]
analysis[, hs2_year := paste0(hs2, "_", year)]

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = 3),
  list("raw" = "FE: cp", "clean" = "Country $\\times$ Product FE", "fmt" = function(x) ifelse(x > 0, "\\checkmark", "")),
  list("raw" = "FE: hs2_year", "clean" = "HS2 $\\times$ Year FE", "fmt" = function(x) ifelse(x > 0, "\\checkmark", "")),
  list("raw" = "FE: ct", "clean" = "Country $\\times$ Year FE", "fmt" = function(x) ifelse(x > 0, "\\checkmark", ""))
)

if (has_control) {
  m1 <- feols(log_trade ~ transit_post | cp + pt + ct, data = analysis, cluster = ~reporter_code)
  m2 <- feols(log_trade ~ transit_post + transit_chpl_post |
                cp + pt + ct, data = analysis, cluster = ~reporter_code)
  m3 <- feols(log_trade ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                cp + pt + ct, data = analysis, cluster = ~reporter_code)
  m5 <- feols(trade_positive ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                cp + pt + ct, data = analysis, cluster = ~reporter_code)
  m6 <- feols(asinh_trade ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                cp + pt + ct, data = analysis, cluster = ~reporter_code)
  models_list <- list(
    "(1) DD" = m1, "(2) DDD" = m2, "(3) Main" = m3,
    "(4) Extensive" = m5, "(5) Asinh" = m6
  )
  cm <- c(
    "transit_post" = "Transit $\\times$ Post-sanctions",
    "transit_chpl_post" = "Transit $\\times$ CHPL $\\times$ Post-sanctions",
    "transit_chpl_postchpl" = "Transit $\\times$ CHPL $\\times$ Post-CHPL"
  )
  gm[[4]] <- list("raw" = "FE: pt", "clean" = "Product $\\times$ Year FE",
                   "fmt" = function(x) ifelse(x > 0, "\\checkmark", ""))
  tab2_title <- "Main Results: Triple-Difference Estimates of CHPL Enforcement Effect"
} else {
  m1 <- feols(log_trade ~ chpl_post | cp + ct, data = analysis, cluster = ~hs6)
  m2 <- feols(log_trade ~ chpl_post | cp + ct + hs2_year, data = analysis, cluster = ~hs6)
  m3 <- feols(log_trade ~ chpl_post + chpl_post_chpl |
                cp + ct + hs2_year, data = analysis, cluster = ~hs6)
  m5 <- feols(trade_positive ~ chpl_post + chpl_post_chpl |
                cp + ct + hs2_year, data = analysis, cluster = ~hs6)
  m6 <- feols(asinh_trade ~ chpl_post + chpl_post_chpl |
                cp + ct + hs2_year, data = analysis, cluster = ~hs6)
  models_list <- list(
    "(1) Base" = m1, "(2) + Sector FE" = m2, "(3) Main" = m3,
    "(4) Extensive" = m5, "(5) Asinh" = m6
  )
  cm <- c(
    "chpl_post" = "CHPL $\\times$ Post-sanctions",
    "chpl_post_chpl" = "CHPL $\\times$ Post-CHPL"
  )
  tab2_title <- "Main Results: Difference-in-Differences Estimates of CHPL Enforcement Effect"
}

options("modelsummary_format_numeric_latex" = "plain")

tab2 <- modelsummary(models_list,
                     coef_map = cm,
                     gof_map = gm,
                     stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
                     output = file.path(TABLE_DIR, "table2_main_results.tex"),
                     title = tab2_title,
                     escape = FALSE)
cat("Table 2 saved.\n")

## ============================================================
## TABLE 3: Tier-Specific Results
## ============================================================

chpl_only <- analysis[is_chpl_num == 1]

min_obs <- 30

if (has_control) {
  tier_formula <- log_trade ~ transit_post | cp + pt + ct
  tier_cluster <- ~reporter_code
  cm_tier <- c(
    "transit_post" = "Transit $\\times$ Post-sanctions"
  )
} else {
  tier_formula <- log_trade ~ post_sanctions + post_chpl | cp
  tier_cluster <- ~hs6
  cm_tier <- c(
    "post_sanctions" = "Post-sanctions",
    "post_chpl" = "Post-CHPL"
  )
}

m_t12 <- if (nrow(chpl_only[tier_group == "Tier1_2"]) > min_obs)
  feols(tier_formula, data = chpl_only[tier_group == "Tier1_2"], cluster = tier_cluster) else NULL
m_t3 <- if (nrow(chpl_only[tier_group == "Tier3"]) > min_obs)
  feols(tier_formula, data = chpl_only[tier_group == "Tier3"], cluster = tier_cluster) else NULL
m_t4 <- if (nrow(chpl_only[tier_group == "Tier4"]) > min_obs)
  feols(tier_formula, data = chpl_only[tier_group == "Tier4"], cluster = tier_cluster) else NULL

tier_models <- list()
if (!is.null(m_t12)) tier_models[["(1) Tier 1--2"]] <- m_t12
if (!is.null(m_t3)) tier_models[["(2) Tier 3"]] <- m_t3
if (!is.null(m_t4)) tier_models[["(3) Tier 4"]] <- m_t4

if (length(tier_models) > 0) {
  tab3 <- modelsummary(tier_models,
                       coef_map = cm_tier,
                       gof_map = gm,
                       stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
                       output = file.path(TABLE_DIR, "table3_tier_results.tex"),
                       title = "Heterogeneity by CHPL Tier: Enforcement Effects on Critical vs.~Peripheral Components",
                       escape = FALSE)
  cat("Table 3 saved.\n")
}

## ============================================================
## TABLE 4: Sanctions Leakage Rates
## ============================================================

if (nrow(leakage) > 0) {
  leakage_display <- leakage[, .(
    `Product Type` = ifelse(is_chpl, "CHPL", "Non-CHPL"),
    `Pre-Sanctions (\\$M)` = sprintf("%.1f", transit_rerouting_pre / 1e6),
    `Peak (\\$M)` = sprintf("%.1f", transit_rerouting_post / 1e6),
    `Post-CHPL (\\$M)` = sprintf("%.1f", transit_post_chpl / 1e6),
    `Peak/Pre Ratio` = sprintf("%.1fx", transit_rerouting_post / transit_rerouting_pre),
    `\\% Decline from Peak` = sprintf("%.0f\\%%",
      (transit_rerouting_post - transit_post_chpl) / transit_rerouting_post * 100)
  )]

  tab4 <- kbl(leakage_display, format = "latex", booktabs = TRUE, escape = FALSE,
              caption = "Rerouting Magnitude: Transit-Country Exports to Russia",
              label = "tab:leakage") |>
    kable_styling(latex_options = c("hold_position")) |>
    footnote(general = "Source: UN Comtrade. Transit countries: Kyrgyzstan, Armenia, Kazakhstan. Pre-Sanctions: average annual FOB exports to Russia (2015--2021). Peak: 2023 FOB exports. Post-CHPL: 2024 FOB exports. Peak/Pre Ratio measures the rerouting surge. \\% Decline from Peak measures the enforcement effect.",
             general_title = "Notes:", threeparttable = TRUE)

  writeLines(tab4, file.path(TABLE_DIR, "table4_leakage.tex"))
  cat("Table 4 saved.\n")
}

## ============================================================
## TABLE A1: Robustness Summary (Appendix)
## ============================================================

if (nrow(robust_coefs) > 0) {
  fwrite(robust_coefs, file.path(TABLE_DIR, "tableA1_robustness_raw.csv"))
  cat("Table A1 raw data saved.\n")
}

cat("\n=== ALL TABLES GENERATED ===\n")
