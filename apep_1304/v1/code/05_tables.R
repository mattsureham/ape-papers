# 05_tables.R — Generate all LaTeX tables
# The Deportation Dividend: Immigration Judge Leniency and Origin-Country Remittances

source("00_packages.R")

results <- readRDS("../data/results.rds")
robust <- readRDS("../data/robustness.rds")
analysis <- readRDS("../data/analysis.rds")

# ===================================================================
# Table 1: Summary Statistics
# ===================================================================
cat("=== Table 1: Summary Statistics ===\n")

summ_vars <- analysis[, .(
  Variable = c("Annual cases per country", "Grant rate",
               "LOO judge leniency (IV)", "Remittances (billion USD)",
               "Remittances/GDP (%)", "GDP growth (%)",
               "Number of judges per country-year"),
  N = c(rep(.N, 7)),
  Mean = c(mean(n_cases), mean(grant_rate), mean(leniency_iv),
           mean(remittances_usd) / 1e9, mean(remit_gdp_share, na.rm = TRUE),
           mean(gdp_growth, na.rm = TRUE), mean(n_judges)),
  SD = c(sd(n_cases), sd(grant_rate), sd(leniency_iv),
         sd(remittances_usd) / 1e9, sd(remit_gdp_share, na.rm = TRUE),
         sd(gdp_growth, na.rm = TRUE), sd(n_judges)),
  Min = c(min(n_cases), min(grant_rate), min(leniency_iv),
          min(remittances_usd) / 1e9, min(remit_gdp_share, na.rm = TRUE),
          min(gdp_growth, na.rm = TRUE), min(n_judges)),
  Max = c(max(n_cases), max(grant_rate), max(leniency_iv),
          max(remittances_usd) / 1e9, max(remit_gdp_share, na.rm = TRUE),
          max(gdp_growth, na.rm = TRUE), max(n_judges))
)]

tab1_tex <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "Variable & N & Mean & SD & Min & Max \\\\",
  "\\hline"
)

for (i in seq_len(nrow(summ_vars))) {
  row <- summ_vars[i]
  tab1_tex <- c(tab1_tex, sprintf(
    "%s & %d & %.3f & %.3f & %.3f & %.3f \\\\",
    row$Variable, row$N, row$Mean, row$SD, row$Min, row$Max
  ))
}

tab1_tex <- c(tab1_tex,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Unit of observation is country $\\times$ year. Sample restricted to country-years with $\\geq$ 100 completed immigration court cases and non-missing World Bank remittance data. LOO judge leniency is the case-weighted average of each judge's leave-nationality-out grant rate. Remittances are total inflows from all sources (World Bank WDI indicator BX.TRF.PWKR.CD.DT).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ===================================================================
# Table 2: First Stage and IV Results
# ===================================================================
cat("=== Table 2: Main Results ===\n")

fs <- results$fs
ols1 <- results$ols1
iv1 <- results$iv1
rf <- results$rf

n_obs <- nobs(iv1)
n_countries <- uniqueN(results$est_sample$iso3)

# Extract coefficients and standard errors
get_coef <- function(model, varname) {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model)))
  idx <- grep(varname, names(cf))[1]
  if (is.na(idx)) return(c(NA, NA))
  c(cf[idx], se[idx])
}

# First stage
fs_coef <- get_coef(fs, "leniency_iv")
fs_fstat <- tryCatch(fitstat(fs, "ivf")$ivf$stat, error = function(e) NA)

# OLS
ols_coef <- get_coef(ols1, "grant_rate")

# IV
iv_coef <- get_coef(iv1, "fit_grant_rate")

# Reduced form
rf_coef <- get_coef(rf, "leniency_iv")

tab2_tex <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Immigration Judge Leniency, Asylum Grant Rates, and Remittance Inflows}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & First Stage & OLS & 2SLS & Reduced Form \\\\",
  " & Grant Rate & $\\log$(Remit.) & $\\log$(Remit.) & $\\log$(Remit.) \\\\",
  "\\hline"
)

# First stage coefficient
tab2_tex <- c(tab2_tex, sprintf(
  "LOO judge leniency & %.4f & & & %.4f \\\\", fs_coef[1], rf_coef[1]))
tab2_tex <- c(tab2_tex, sprintf(
  " & (%.4f) & & & (%.4f) \\\\", fs_coef[2], rf_coef[2]))

# Grant rate coefficient (OLS and IV)
tab2_tex <- c(tab2_tex, sprintf(
  "Grant rate & & %.4f & %.4f & \\\\", ols_coef[1], iv_coef[1]))
tab2_tex <- c(tab2_tex, sprintf(
  " & & (%.4f) & (%.4f) & \\\\", ols_coef[2], iv_coef[2]))

tab2_tex <- c(tab2_tex,
  "\\hline",
  sprintf("Country FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("GDP growth control & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Observations & %d & %d & %d & %d \\\\", n_obs, n_obs, n_obs, n_obs),
  sprintf("Countries & %d & %d & %d & %d \\\\", n_countries, n_countries, n_countries, n_countries),
  if (!is.na(fs_fstat)) sprintf("First-stage $F$ & %.1f & & %.1f & \\\\", fs_fstat, fs_fstat) else "",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Standard errors clustered by origin country in parentheses. The dependent variable in column~(1) is the nationality-year asylum grant rate. In columns~(2)--(4), it is $\\log$ total remittance inflows to the origin country (World Bank WDI). The instrument is the case-weighted average leave-nationality-out judge grant rate: for each judge hearing cases of nationality $c$, the instrument uses the judge's grant rate computed over all \\emph{other} nationalities. All specifications include origin-country and year fixed effects and control for origin-country GDP growth. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ===================================================================
# Table 3: Robustness
# ===================================================================
cat("=== Table 3: Robustness ===\n")

# Lead placebo
lead_coef <- get_coef(robust$placebo_lead, "leniency_lead2")

# Dynamic (lag1)
dyn_coef <- get_coef(robust$dynamic1, "leniency_iv")
lag1_coef <- get_coef(robust$dynamic1, "leniency_lag1")

# Two-way clustering
tw_coef <- get_coef(robust$iv_twoway, "fit_grant_rate")

# FDI placebo
fdi_coef <- get_coef(robust$placebo_fdi, "leniency_iv")

# LOCO
loco_min <- min(robust$loco_coefs)
loco_max <- max(robust$loco_coefs)

tab3_tex <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Robustness and Placebo Tests}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Lead Placebo & Dynamic & Two-Way Cluster & FDI Placebo \\\\",
  " & $\\log$(Remit.) & $\\log$(Remit.) & $\\log$(Remit.) & $\\log$(FDI) \\\\",
  "\\hline",
  sprintf("Leniency$_{t+2}$ & %.4f & & & \\\\", lead_coef[1]),
  sprintf(" & (%.4f) & & & \\\\", lead_coef[2]),
  sprintf("Leniency$_{t}$ & & %.4f & & \\\\", dyn_coef[1]),
  sprintf(" & & (%.4f) & & \\\\", dyn_coef[2]),
  sprintf("Leniency$_{t-1}$ & & %.4f & & \\\\", lag1_coef[1]),
  sprintf(" & & (%.4f) & & \\\\", lag1_coef[2]),
  sprintf("Grant rate (2SLS) & & & %.4f & \\\\", tw_coef[1]),
  sprintf(" & & & (%.4f) & \\\\", tw_coef[2]),
  sprintf("Leniency (RF) & & & & %.4f \\\\", fdi_coef[1]),
  sprintf(" & & & & (%.4f) \\\\", fdi_coef[2]),
  "\\hline",
  "Country FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("LOCO range & \\multicolumn{4}{c}{[%.3f, %.3f]} \\\\", loco_min, loco_max),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Column~(1) is a pre-period placebo: leniency two years ahead should not predict current remittances. Column~(2) includes contemporaneous and one-year lagged leniency. Column~(3) reports the main 2SLS specification with two-way clustering by country and year. Column~(4) tests whether judge leniency predicts a placebo outcome---FDI inflows---that should not be affected by asylum decisions. LOCO range reports the minimum and maximum 2SLS coefficient when sequentially dropping each origin country. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, "../tables/tab3_robust.tex")

# ===================================================================
# Table 4: Heterogeneity by Region and Remittance Dependence
# ===================================================================
cat("=== Table 4: Heterogeneity ===\n")

est <- results$est_sample

# Define regions
latam <- c("MEX", "GTM", "HND", "SLV", "COL", "ECU", "PER", "DOM",
           "JAM", "NIC", "VEN", "CUB", "GUY", "TTO", "CRI", "PAN", "URY", "BRA", "HTI")
asia <- c("CHN", "IND", "PAK", "PHL", "VNM", "BGD")
africa <- c("NGA", "ETH", "GHA", "KEN", "EGY")

est[, region := fifelse(iso3 %in% latam, "Latin America",
              fifelse(iso3 %in% asia, "Asia",
              fifelse(iso3 %in% africa, "Africa", "Other")))]

# Remittance dependence: above/below median remittance/GDP share
est[, high_remit_dep := as.integer(remit_gdp_share > median(remit_gdp_share, na.rm = TRUE))]

# Run by region
iv_latam <- feols(log_remit ~ gdp_growth | iso3 + year | grant_rate ~ leniency_iv,
                  data = est[region == "Latin America"], cluster = ~iso3)
iv_asia <- feols(log_remit ~ gdp_growth | iso3 + year | grant_rate ~ leniency_iv,
                 data = est[region == "Asia"], cluster = ~iso3)

# By remittance dependence
iv_high <- feols(log_remit ~ gdp_growth | iso3 + year | grant_rate ~ leniency_iv,
                 data = est[high_remit_dep == 1], cluster = ~iso3)
iv_low <- feols(log_remit ~ gdp_growth | iso3 + year | grant_rate ~ leniency_iv,
                data = est[high_remit_dep == 0], cluster = ~iso3)

het_latam <- get_coef(iv_latam, "fit_grant_rate")
het_asia <- get_coef(iv_asia, "fit_grant_rate")
het_high <- get_coef(iv_high, "fit_grant_rate")
het_low <- get_coef(iv_low, "fit_grant_rate")

tab4_tex <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Heterogeneity by Region and Remittance Dependence}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Latin America & Asia & High Dep. & Low Dep. \\\\",
  "\\hline",
  sprintf("Grant rate (2SLS) & %.4f & %.4f & %.4f & %.4f \\\\",
          het_latam[1], het_asia[1], het_high[1], het_low[1]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          het_latam[2], het_asia[2], het_high[2], het_low[2]),
  "\\hline",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(iv_latam), nobs(iv_asia), nobs(iv_high), nobs(iv_low)),
  sprintf("Countries & %d & %d & %d & %d \\\\",
          uniqueN(est[region == "Latin America"]$iso3),
          uniqueN(est[region == "Asia"]$iso3),
          uniqueN(est[high_remit_dep == 1]$iso3),
          uniqueN(est[high_remit_dep == 0]$iso3)),
  "Country + Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} 2SLS estimates with grant rate instrumented by LOO judge leniency. Standard errors clustered by origin country. Columns~(1)--(2) split by region. Columns~(3)--(4) split at the median remittance/GDP share. ``High dependence'' countries derive a larger share of GDP from remittance inflows. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_tex, "../tables/tab4_heterogeneity.tex")

# ===================================================================
# Table F1: Standardized Effect Sizes (SDE Appendix)
# ===================================================================
cat("=== Table F1: SDE ===\n")

# Compute SDE for main outcomes
# SDE = beta * SD(X) / SD(Y) for continuous treatment
# Here X = grant_rate, Y = log(remittances)
beta_iv <- coef(results$iv1)["fit_grant_rate"]
se_iv <- sqrt(diag(vcov(results$iv1)))["fit_grant_rate"]
sd_x <- sd(est$grant_rate)
sd_y <- sd(est$log_remit)

sde_main <- beta_iv * sd_x / sd_y
se_sde_main <- se_iv * sd_x / sd_y

# Per-capita remittances
beta_pc <- coef(results$iv2)["fit_grant_rate"]
se_pc <- sqrt(diag(vcov(results$iv2)))["fit_grant_rate"]
sd_y_pc <- sd(est$log_remit_pc, na.rm = TRUE)
sde_pc <- beta_pc * sd_x / sd_y_pc
se_sde_pc <- se_pc * sd_x / sd_y_pc

classify_sde <- function(sde) {
  if (abs(sde) < 0.005) "Null"
  else if (sde >= 0.005 & sde < 0.05) "Small positive"
  else if (sde >= 0.05 & sde < 0.15) "Moderate positive"
  else if (sde >= 0.15) "Large positive"
  else if (sde <= -0.005 & sde > -0.05) "Small negative"
  else if (sde <= -0.05 & sde > -0.15) "Moderate negative"
  else "Large negative"
}

# Heterogeneity panel: Latin America vs Asia
beta_latam <- tryCatch(coef(iv_latam)["fit_grant_rate"], error = function(e) NA)
se_latam <- tryCatch(sqrt(diag(vcov(iv_latam)))["fit_grant_rate"], error = function(e) NA)
sd_y_latam <- sd(est[region == "Latin America"]$log_remit)
sde_latam <- beta_latam * sd(est[region == "Latin America"]$grant_rate) / sd_y_latam
se_sde_latam <- se_latam * sd(est[region == "Latin America"]$grant_rate) / sd_y_latam

beta_high <- tryCatch(coef(iv_high)["fit_grant_rate"], error = function(e) NA)
se_high <- tryCatch(sqrt(diag(vcov(iv_high)))["fit_grant_rate"], error = function(e) NA)
sd_y_high <- sd(est[high_remit_dep == 1]$log_remit)
sde_high <- beta_high * sd(est[high_remit_dep == 1]$grant_rate) / sd_y_high
se_sde_high <- se_high * sd(est[high_remit_dep == 1]$grant_rate) / sd_y_high

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Multiple origin countries (primarily Latin America, Asia, Africa). ",
  "\\textbf{Research question:} Whether quasi-random variation in US immigration court asylum grant rates causally affects remittance inflows to immigrants' origin countries. ",
  "\\textbf{Policy mechanism:} Immigration judges are quasi-randomly assigned to asylum cases within courts; lenient judges grant asylum at higher rates, enabling immigrants to obtain work authorization, formal employment, and legal remittance channels, thereby increasing financial flows to origin countries. ",
  "\\textbf{Outcome definition:} Log total remittance inflows to origin country from all sources (World Bank WDI indicator BX.TRF.PWKR.CD.DT, current USD). ",
  "\\textbf{Treatment:} Continuous --- nationality-year asylum grant rate in US immigration courts. ",
  "\\textbf{Data:} EOIR case-level records (10.6M cases, 2001--2023) linked to World Bank bilateral remittance data; unit of observation is origin country $\\times$ year. ",
  "\\textbf{Method:} 2SLS with leave-nationality-out judge leniency as instrument; country and year fixed effects; standard errors clustered by origin country. ",
  "\\textbf{Sample:} Country-years with $\\geq$ 100 completed immigration court cases and non-missing remittance data. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabf1_tex <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log remittances & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_iv, se_iv, sd_y, sde_main, se_sde_main, classify_sde(sde_main)),
  sprintf("Log remit. per capita & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_pc, se_pc, sd_y_pc, sde_pc, se_sde_pc, classify_sde(sde_pc)),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Latin America & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_latam, se_latam, sd_y_latam, sde_latam, se_sde_latam, classify_sde(sde_latam)),
  sprintf("High remit. dependence & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_high, se_high, sd_y_high, sde_high, se_sde_high, classify_sde(sde_high)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabf1_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
