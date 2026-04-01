## 05_tables.R — apep_1238
## Generate SDE table (tabF1_sde.tex)

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

df <- fread(file.path(data_dir, "analysis_dataset.csv"))
df[, log_tot_spend := log(TOT_MDCR_STDZD_PYMT_PC)]
df[, log_pop := ifelse(pop > 0, log(pop), NA)]
df[, competitive := as.integer(n_hospitals >= 2)]
df[, state_fips_fac := factor(state_fips2)]
df_hosp <- df[n_hospitals >= 1]

controls <- "BENE_AVG_RISK_SCRE + log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT + BENE_RACE_BLACK_PCT"

## ============================================================
## Compute SDE for main specifications
## ============================================================

## SD of outcomes (pre-treatment = full cross-section for cross-sectional design)
sd_log_tot <- sd(df_hosp$log_tot_spend, na.rm = TRUE)
sd_log_ip <- sd(log(df_hosp$IP_MDCR_STDZD_PYMT_PC[df_hosp$IP_MDCR_STDZD_PYMT_PC > 0]), na.rm = TRUE)

## --- Panel A: Pooled ---

## OLS with state FE: log(spending) ~ log(HHI)
ols_main <- feols(as.formula(paste("log_tot_spend ~ log(hhi_count) +", controls, "| state_fips_fac")),
                   data = df_hosp, vcov = "HC1")
beta_ols <- coef(ols_main)["log(hhi_count)"]
se_ols <- sqrt(vcov(ols_main)["log(hhi_count)", "log(hhi_count)"])

## For continuous treatment (log HHI), SDE = beta * SD(X) / SD(Y)
sd_log_hhi <- sd(log(df_hosp$hhi_count), na.rm = TRUE)
sde_ols <- beta_ols * sd_log_hhi / sd_log_tot
se_sde_ols <- se_ols * sd_log_hhi / sd_log_tot

## IV: log(spending) ~ log(HHI) instrumented by inv_pci_1950
iv_sample <- df_hosp[!is.na(inv_pci_1950)]
iv_main <- feols(as.formula(paste("log_tot_spend ~", controls, "| 0 | log(hhi_count) ~ inv_pci_1950")),
                  data = iv_sample, vcov = "HC1")
beta_iv <- coef(iv_main)["fit_log(hhi_count)"]
se_iv <- sqrt(vcov(iv_main)["fit_log(hhi_count)", "fit_log(hhi_count)"])
sde_iv <- beta_iv * sd_log_hhi / sd_log_tot
se_sde_iv <- se_iv * sd_log_hhi / sd_log_tot

## Inpatient only (mechanism: direct hospital spending)
df_hosp[, log_ip := ifelse(IP_MDCR_STDZD_PYMT_PC > 0, log(IP_MDCR_STDZD_PYMT_PC), NA)]
ols_ip <- feols(as.formula(paste("log_ip ~ log(hhi_count) +", controls, "| state_fips_fac")),
                 data = df_hosp, vcov = "HC1")
beta_ip <- coef(ols_ip)["log(hhi_count)"]
se_ip <- sqrt(vcov(ols_ip)["log(hhi_count)", "log(hhi_count)"])
sde_ip <- beta_ip * sd_log_hhi / sd_log_ip
se_sde_ip <- se_ip * sd_log_hhi / sd_log_ip

## --- Panel B: Heterogeneous (sample splits) ---

## Urban vs Rural
med_pop <- median(df_hosp$pop, na.rm = TRUE)

## Urban
ols_urban <- feols(as.formula(paste("log_tot_spend ~ log(hhi_count) +", controls, "| state_fips_fac")),
                    data = df_hosp[pop > med_pop], vcov = "HC1")
beta_urban <- coef(ols_urban)["log(hhi_count)"]
se_urban <- sqrt(vcov(ols_urban)["log(hhi_count)", "log(hhi_count)"])
sd_y_urban <- sd(df_hosp[pop > med_pop]$log_tot_spend, na.rm = TRUE)
sde_urban <- beta_urban * sd_log_hhi / sd_y_urban
se_sde_urban <- se_urban * sd_log_hhi / sd_y_urban

## Rural
ols_rural <- feols(as.formula(paste("log_tot_spend ~ log(hhi_count) +", controls, "| state_fips_fac")),
                    data = df_hosp[pop <= med_pop & !is.na(log_pop)], vcov = "HC1")
beta_rural <- coef(ols_rural)["log(hhi_count)"]
se_rural <- sqrt(vcov(ols_rural)["log(hhi_count)", "log(hhi_count)"])
sd_y_rural <- sd(df_hosp[pop <= med_pop]$log_tot_spend, na.rm = TRUE)
sde_rural <- beta_rural * sd_log_hhi / sd_y_rural
se_sde_rural <- se_rural * sd_log_hhi / sd_y_rural

## ============================================================
## Classify SDE buckets
## ============================================================
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05)  return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15)  return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

## Build SDE table data
sde_rows <- data.frame(
  Outcome = c(
    "Total Medicare spending (OLS)", "Total Medicare spending (IV)",
    "Inpatient spending (OLS)",
    "Total spending, urban (OLS)", "Total spending, rural (OLS)"
  ),
  Beta = round(c(beta_ols, beta_iv, beta_ip, beta_urban, beta_rural), 4),
  SE = round(c(se_ols, se_iv, se_ip, se_urban, se_rural), 4),
  SD_Y = round(c(sd_log_tot, sd_log_tot, sd_log_ip, sd_y_urban, sd_y_rural), 4),
  SDE = round(c(sde_ols, sde_iv, sde_ip, sde_urban, sde_rural), 4),
  SE_SDE = round(c(se_sde_ols, se_sde_iv, se_sde_ip, se_sde_urban, se_sde_rural), 4),
  Classification = sapply(c(sde_ols, sde_iv, sde_ip, sde_urban, sde_rural), classify_sde),
  stringsAsFactors = FALSE
)

cat("\nSDE Table:\n")
print(sde_rows)

## ============================================================
## Generate LaTeX SDE table
## ============================================================

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does hospital market concentration, shaped by historical federal hospital construction policy, increase county-level Medicare spending per beneficiary? ",
  "\\textbf{Policy mechanism:} The Hill-Burton Act (1946--1971) allocated federal construction grants inversely to state per capita income, creating persistent cross-county variation in hospital supply that determines current market structure. ",
  "\\textbf{Outcome definition:} Log standardized Medicare fee-for-service per capita spending (CMS Geographic Variation PUF), price-adjusted to remove geographic payment differences. ",
  "\\textbf{Treatment:} Continuous; log Herfindahl--Hirschman Index based on equal-share hospital counts per county. ",
  "\\textbf{Data:} CMS Geographic Variation PUF (2019), CMS Hospital Compare (2024), BEA state personal income (1950), ACS 5-year (2022); 1,620 counties with $\\geq 1$ hospital and non-missing controls. ",
  "\\textbf{Method:} IV/2SLS with inverse 1950 state per capita income as instrument, heteroskedasticity-robust standard errors; OLS specifications include state fixed effects. ",
  "\\textbf{Sample:} Counties with at least one Medicare-certified hospital (Acute Care, Critical Access, or VA); excludes counties with fewer than 100 FFS beneficiaries. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, where SD($X$) and SD($Y$) are cross-sectional standard deviations. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:3) {
  sde_tex <- c(sde_tex, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
    sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
    sde_rows$Classification[i]))
}

sde_tex <- c(sde_tex,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\"
)

for (i in 4:5) {
  sde_tex <- c(sde_tex, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
    sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
    sde_rows$Classification[i]))
}

sde_tex <- c(sde_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("\nSDE table saved to tables/tabF1_sde.tex\n")
