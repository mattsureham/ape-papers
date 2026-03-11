# 06_tables.R — All table generation
# APEP-0598: Greece Capital Controls & Shadow Economy Formalization

source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# LOAD DATA AND MODELS
# ============================================================

summary_stats <- fread(file.path(data_dir, "summary_stats.csv"))
sector_summary <- fread(file.path(data_dir, "sector_summary.csv"))
weights_df <- fread(file.path(data_dir, "scm_weights.csv"))
rmspe <- fread(file.path(data_dir, "scm_rmspe.csv"))
country_map <- fread(file.path(data_dir, "country_map.csv"))
scm_as <- fread(file.path(data_dir, "scm_actual_synthetic.csv"))
turnover <- fread(file.path(data_dir, "retail_turnover.csv"))
pre_treat <- fread(file.path(data_dir, "pre_treatment_covariates.csv"))

load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# Country name lookup
country_names <- c(
  "EL" = "Greece", "PT" = "Portugal", "ES" = "Spain", "IT" = "Italy",
  "IE" = "Ireland", "CY" = "Cyprus", "BG" = "Bulgaria", "RO" = "Romania",
  "HR" = "Croatia", "SK" = "Slovakia", "SI" = "Slovenia", "LT" = "Lithuania",
  "LV" = "Latvia", "EE" = "Estonia", "MT" = "Malta"
)

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("Generating Table 1: Summary Statistics...\n")

# Panel A: Country-level summary (G47 total retail)
panel_a <- turnover %>%
  filter(nace == "G47") %>%
  group_by(country) %>%
  summarise(
    N = n(),
    Mean = mean(value, na.rm = TRUE),
    SD = sd(value, na.rm = TRUE),
    Min = min(value, na.rm = TRUE),
    Max = max(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(Country = country_names[country]) %>%
  arrange(desc(country == "EL"), Country) %>%
  select(Country, N, Mean, SD, Min, Max)

# Panel B: Greece sector-level
panel_b <- sector_summary %>%
  select(Sector = sector_label, `Cash Share` = cash_share,
         N = n_months, Mean = mean_turnover, SD = sd_turnover,
         `Jul 2015 Drop (%)` = pct_drop)

tab1_a <- kable(panel_a, format = "latex", booktabs = TRUE, digits = 1,
                caption = "Summary Statistics: Monthly Retail Trade Turnover (2015 = 100)",
                label = "tab1") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  pack_rows("Panel A: Country-Level (G47 Total Retail)", 1, nrow(panel_a)) %>%
  footnote(general = "Source: Eurostat STS\\_TRTU\\_M. Seasonally and calendar adjusted. Index base 2015 = 100.",
           threeparttable = TRUE)

# Write Panel A
writeLines(tab1_a, file.path(tab_dir, "tab1_summary.tex"))

# Panel B separately
tab1_b <- kable(panel_b, format = "latex", booktabs = TRUE, digits = 2,
                caption = "Greece Retail Sectors by Cash Intensity",
                label = "tab1b") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Cash share from ECB Survey on Use of Cash (2016). July 2015 drop calculated relative to June 2015.",
           threeparttable = TRUE)

writeLines(tab1_b, file.path(tab_dir, "tab1b_sectors.tex"))

cat("Table 1 saved.\n")

# ============================================================
# TABLE 2: SCM Donor Weights
# ============================================================

cat("Generating Table 2: SCM Weights...\n")

weights_tab <- weights_df %>%
  mutate(Country = country_names[country]) %>%
  select(Country, Weight = weight) %>%
  arrange(desc(Weight))

tab2 <- kable(weights_tab, format = "latex", booktabs = TRUE, digits = 4,
              caption = "Synthetic Control Weights",
              label = "tab2") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Weights estimated by the Synth package (Abadie et al. 2010). Only countries with weight $>$ 0.001 shown.",
           threeparttable = TRUE)

writeLines(tab2, file.path(tab_dir, "tab2_weights.tex"))

cat("Table 2 saved.\n")

# ============================================================
# TABLE 3: Main SCM Results
# ============================================================

cat("Generating Table 3: SCM Results...\n")

# Compute gaps at key horizons
scm_as_dt <- as.data.table(scm_as)
treatment_idx <- (2015 - 2010) * 12 + 7

scm_results <- data.frame(
  Period = c("Impact month (Jul 2015)",
             "First 3 months", "First 6 months",
             "First 12 months", "Full post-period",
             "After control removal (Sep 2019+)"),
  `Avg Gap` = c(
    scm_as_dt[time_index == treatment_idx, actual - synthetic],
    scm_as_dt[time_index >= treatment_idx & time_index < treatment_idx + 3,
              mean(actual - synthetic)],
    scm_as_dt[time_index >= treatment_idx & time_index < treatment_idx + 6,
              mean(actual - synthetic)],
    scm_as_dt[time_index >= treatment_idx & time_index < treatment_idx + 12,
              mean(actual - synthetic)],
    scm_as_dt[time_index >= treatment_idx, mean(actual - synthetic)],
    scm_as_dt[time_index >= (2019 - 2010) * 12 + 9, mean(actual - synthetic)]
  ),
  check.names = FALSE
)

# Add percent gap
scm_results$`Pct Gap` <- round(scm_results$`Avg Gap` /
  mean(scm_as_dt[time_index < treatment_idx]$actual, na.rm = TRUE) * 100, 2)

tab3 <- kable(scm_results, format = "latex", booktabs = TRUE, digits = 2,
              caption = "Synthetic Control Estimates: Gap Between Greece and Synthetic Greece",
              label = "tab3",
              col.names = c("Period", "Gap (index points)", "Gap (\\\\\\%)")) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Gap = Greece minus Synthetic Greece. Negative values indicate Greece underperforming counterfactual. Percentage calculated relative to pre-treatment mean.",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab3, file.path(tab_dir, "tab3_scm_results.tex"))

cat("Table 3 saved.\n")

# ============================================================
# TABLE 4: Cross-Sector DiD Results
# ============================================================

cat("Generating Table 4: DiD Results...\n")

# Extract DiD results manually for kable
did_ct1 <- coeftable(did_main)
did_ct2 <- coeftable(did_binary)

did_results <- data.frame(
  Variable = c("Cash Share $\\times$ Post", "High Cash $\\times$ Post"),
  Estimate = c(did_ct1[1, "Estimate"], did_ct2[1, "Estimate"]),
  SE = c(did_ct1[1, "Std. Error"], did_ct2[1, "Std. Error"]),
  `t value` = c(did_ct1[1, "t value"], did_ct2[1, "t value"]),
  `p value` = c(did_ct1[1, "Pr(>|t|)"], did_ct2[1, "Pr(>|t|)"]),
  N = c(nobs(did_main), nobs(did_binary)),
  check.names = FALSE
)

tab4 <- kable(did_results, format = "latex", booktabs = TRUE, digits = 3,
              caption = "Cross-Sector Difference-in-Differences: Cash Intensity and Retail Turnover",
              label = "tab4", escape = FALSE) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Dependent variable: retail turnover index (2015 = 100). Cash Share is the pre-2015 share of transactions in cash (continuous). High Cash = 1 if cash share $\\geq$ 0.75. Both specifications include sector and time fixed effects. Standard errors clustered by sector.",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab4, file.path(tab_dir, "tab4_did.tex"))

cat("Table 4 saved.\n")

# ============================================================
# TABLE 5: VAT Mechanism
# ============================================================

cat("Generating Table 5: VAT Results...\n")

vat_ct <- coeftable(vat_did)

vat_results <- data.frame(
  Variable = "Greece $\\times$ Post-2015",
  Estimate = vat_ct[1, "Estimate"],
  SE = vat_ct[1, "Std. Error"],
  `t value` = vat_ct[1, "t value"],
  `p value` = vat_ct[1, "Pr(>|t|)"],
  N = nobs(vat_did),
  check.names = FALSE
)

tab5 <- kable(vat_results, format = "latex", booktabs = TRUE, digits = 3,
              caption = "VAT Revenue: Greece vs. Donor Countries",
              label = "tab5", escape = FALSE) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Dependent variable: VAT revenue indexed to 2014 = 100. Country and year fixed effects. Standard errors clustered by country.",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab5, file.path(tab_dir, "tab5_vat.tex"))

cat("Table 5 saved.\n")

# ============================================================
# TABLE 5b: VAT-to-GDP Ratio
# ============================================================

cat("Generating Table 5b: VAT-to-GDP Ratio...\n")

vat_gdp_ct <- coeftable(vat_gdp_did)

vat_gdp_results <- data.frame(
  Variable = "Greece $\\times$ Post-2015",
  Estimate = vat_gdp_ct[1, "Estimate"],
  SE = vat_gdp_ct[1, "Std. Error"],
  `t value` = vat_gdp_ct[1, "t value"],
  `p value` = vat_gdp_ct[1, "Pr(>|t|)"],
  N = nobs(vat_gdp_did),
  check.names = FALSE
)

tab5b <- kable(vat_gdp_results, format = "latex", booktabs = TRUE, digits = 3,
               caption = "VAT-to-GDP Ratio: Greece vs. Donor Countries",
               label = "tab5b", escape = FALSE) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Dependent variable: VAT revenue as a share of GDP (\\%), indexed to 2014 = 100. Country and year fixed effects. Standard errors clustered by country.",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab5b, file.path(tab_dir, "tab5b_vat_gdp.tex"))

cat("Table 5b saved.\n")

# ============================================================
# TABLE 6: Pre-Treatment Balance
# ============================================================

cat("Generating Table 6: Pre-Treatment Balance...\n")

# Compare Greece to donor average on pre-treatment covariates
greece_pre <- pre_treat %>% filter(country == "EL")
donor_pre <- pre_treat %>% filter(country != "EL")

balance_tab <- data.frame(
  Variable = c("GDP per capita (EUR, chain-linked 2010)",
               "Unemployment rate (%)",
               "VAT revenue (EUR millions)",
               "Avg retail turnover 2010",
               "Avg retail turnover 2012",
               "Avg retail turnover 2014"),
  Greece = c(greece_pre$mean_gdp_pc,
             greece_pre$mean_unemp,
             greece_pre$mean_vat,
             greece_pre$turnover_2010,
             greece_pre$turnover_2012,
             greece_pre$turnover_2014),
  `Donor Mean` = c(
    mean(donor_pre$mean_gdp_pc, na.rm = TRUE),
    mean(donor_pre$mean_unemp, na.rm = TRUE),
    mean(donor_pre$mean_vat, na.rm = TRUE),
    mean(donor_pre$turnover_2010, na.rm = TRUE),
    mean(donor_pre$turnover_2012, na.rm = TRUE),
    mean(donor_pre$turnover_2014, na.rm = TRUE)
  ),
  `Donor SD` = c(
    sd(donor_pre$mean_gdp_pc, na.rm = TRUE),
    sd(donor_pre$mean_unemp, na.rm = TRUE),
    sd(donor_pre$mean_vat, na.rm = TRUE),
    sd(donor_pre$turnover_2010, na.rm = TRUE),
    sd(donor_pre$turnover_2012, na.rm = TRUE),
    sd(donor_pre$turnover_2014, na.rm = TRUE)
  ),
  check.names = FALSE
)

tab6 <- kable(balance_tab, format = "latex", booktabs = TRUE, digits = 1,
              caption = "Pre-Treatment Covariate Balance: Greece vs. Donor Pool (2010--2014 Averages)",
              label = "tab6") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Source: Eurostat. Donor pool: Portugal, Spain, Italy, Ireland, Cyprus, Bulgaria, Romania, Croatia, Slovakia, Slovenia, Lithuania, Latvia, Estonia, Malta.",
           threeparttable = TRUE)

writeLines(tab6, file.path(tab_dir, "tab6_balance.tex"))

cat("Table 6 saved.\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (Appendix F)
# ============================================================

cat("Generating Table F1: Standardized Effect Sizes...\n")

sector_panel <- fread(file.path(data_dir, "sector_panel.csv"))

# Get SD of outcomes
turnover_g47 <- turnover %>% filter(nace == "G47", country == "EL")
sd_turnover <- sd(turnover_g47$value, na.rm = TRUE)

# SCM effect (binary treatment: 0/1)
scm_gap_all <- mean(scm_as$gap[scm_as$time_index >= (2015-2010)*12+7], na.rm = TRUE)
# For SCM, use the average gap as beta_hat; SE approximated from post-treatment SD of gaps
se_scm <- sd(scm_as$gap[scm_as$time_index >= (2015-2010)*12+7], na.rm = TRUE) /
  sqrt(sum(scm_as$time_index >= (2015-2010)*12+7))

sde_scm <- scm_gap_all / sd_turnover
se_sde_scm <- se_scm / sd_turnover

# DiD effect (continuous treatment: cash_share)
beta_did <- coef(did_main)["cash_share:post"]
se_did <- sqrt(diag(vcov(did_main)))["cash_share:post"]
sd_cash <- sd(sector_panel$cash_share, na.rm = TRUE)
sd_sector_turnover <- sd(sector_panel$value, na.rm = TRUE)

sde_did <- beta_did * sd_cash / sd_sector_turnover
se_sde_did <- se_did * sd_cash / sd_sector_turnover

# VAT effect (binary treatment)
beta_vat <- coef(vat_did)["treated:post"]
se_vat <- sqrt(diag(vcov(vat_did)))["treated:post"]
vat_panel_data <- fread(file.path(data_dir, "vat_panel.csv"))
sd_vat <- sd(vat_panel_data$vat_index, na.rm = TRUE)

sde_vat <- beta_vat / sd_vat
se_sde_vat <- se_vat / sd_vat

# Classification function
classify_sde <- function(x) {
  case_when(
    x < -0.15 ~ "Large negative",
    x < -0.05 ~ "Moderate negative",
    x < -0.005 ~ "Small negative",
    x <= 0.005 ~ "Null",
    x <= 0.05 ~ "Small positive",
    x <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_table <- data.frame(
  Outcome = c("Retail turnover (SCM)",
               "Retail turnover (sector DiD)",
               "VAT revenue index"),
  Specification = c("Table 5, full post",
                     "Table 4, Col. 1",
                     "Table 7, Col. 1"),
  Beta = c(scm_gap_all, beta_did, beta_vat),
  `SD(X)` = c("--", round(sd_cash, 3), "--"),
  `SD(Y)` = c(round(sd_turnover, 2), round(sd_sector_turnover, 2), round(sd_vat, 2)),
  SDE = c(sde_scm, sde_did, sde_vat),
  `SE(SDE)` = c(se_sde_scm, se_sde_did, se_sde_vat),
  Classification = c(classify_sde(sde_scm), classify_sde(sde_did), classify_sde(sde_vat)),
  check.names = FALSE
)

tabF1 <- kable(sde_table, format = "latex", booktabs = TRUE, digits = 3,
               caption = "Standardized Effect Sizes",
               label = "tabF1") %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = c(
    "This table reports standardized effect sizes (SDE) for comparability across outcomes and studies.",
    "SDE = $\\hat{\\beta}$ / SD(Y) for binary treatments (SCM, VAT); SDE = $\\hat{\\beta} \\times$ SD(X) / SD(Y) for continuous treatments (sector DiD).",
    "SD(Y) is the unconditional standard deviation of the outcome variable.",
    "The paper studies the effect of Greece's June 2015 capital controls on retail trade turnover and VAT revenue, using monthly Eurostat data (2010--2023) for 15 EU countries.",
    "SCM uses 14 EU donor countries; sector DiD exploits cross-sector cash intensity variation within Greece; VAT DiD compares Greece to donor countries.",
    "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(tabF1, file.path(tab_dir, "tabF1_sde.tex"))

cat("Table F1 saved.\n")

cat("\n=== ALL TABLES SAVED ===\n")
