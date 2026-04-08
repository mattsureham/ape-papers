## 05_tables.R — Generate SDE table (mandatory appendix)
## apep_1416: The Legal Status Premium in Local Housing Markets

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

est <- readRDS(file.path(data_dir, "estimates.rds"))

## Load panel for heterogeneity
if (file.exists(file.path(data_dir, "analysis.csv"))) {
  panel <- fread(file.path(data_dir, "analysis.csv"))
  if (!"code" %in% names(panel)) panel[, code := final_court]
  if (!"year" %in% names(panel)) panel[, year := comp_year]
} else {
  panel <- fread(file.path(data_dir, "analysis_panel.csv"))
}
if (!"log_rent" %in% names(panel)) panel[, log_rent := log(median_rent)]
if (!"log_home_value" %in% names(panel)) panel[, log_home_value := log(median_home_value)]
panel <- panel[!is.na(log_rent) & !is.na(log_home_value) & !is.na(grant_rate) &
               !is.na(leniency_iv) & is.finite(log_rent) & is.finite(log_home_value)]

## SDE = beta * SD(X) / SD(Y) for continuous treatment
sde <- function(beta, sd_x, sd_y) beta * sd_x / sd_y
classify <- function(s) {
  if (s > 0.15) "Large positive"
  else if (s > 0.05) "Moderate positive"
  else if (s > 0.005) "Small positive"
  else if (s > -0.005) "Null"
  else if (s > -0.05) "Small negative"
  else if (s > -0.15) "Moderate negative"
  else "Large negative"
}

sd_x <- est$sd_grant

rows_a <- data.table(
  Outcome = c("Log Median Rent", "Log Median Home Value",
              "Homeownership Rate", "Noncitizen Share"),
  Beta = c(est$beta_rent_iv, est$beta_hv_iv, est$beta_own_iv, est$beta_noncit_iv),
  SE = c(est$se_rent_iv, est$se_hv_iv, est$se_own_iv, est$se_noncit_iv),
  SD_Y = c(est$sd_rent, est$sd_hv, est$sd_own, est$sd_noncit),
  SDE = c(sde(est$beta_rent_iv, sd_x, est$sd_rent),
          sde(est$beta_hv_iv, sd_x, est$sd_hv),
          sde(est$beta_own_iv, sd_x, est$sd_own),
          sde(est$beta_noncit_iv, sd_x, est$sd_noncit)),
  SE_SDE = c(sde(est$se_rent_iv, sd_x, est$sd_rent),
             sde(est$se_hv_iv, sd_x, est$sd_hv),
             sde(est$se_own_iv, sd_x, est$sd_own),
             sde(est$se_noncit_iv, sd_x, est$sd_noncit))
)
rows_a[, Class := sapply(SDE, classify)]

## Panel B: Heterogeneity (high vs low rent)
panel[, high_rent := as.integer(median_rent > median(median_rent, na.rm = TRUE))]

iv_high <- feols(log_rent ~ 1 | code + year | grant_rate ~ leniency_iv,
                 data = panel[high_rent == 1], cluster = ~code)
iv_low <- feols(log_rent ~ 1 | code + year | grant_rate ~ leniency_iv,
                data = panel[high_rent == 0], cluster = ~code)

make_row <- function(mod, subset_data, label) {
  b <- coef(mod)["fit_grant_rate"]
  s <- se(mod)["fit_grant_rate"]
  sdy <- sd(subset_data$log_rent, na.rm = TRUE)
  sdx <- sd(subset_data$grant_rate, na.rm = TRUE)
  data.table(Outcome = label, Beta = b, SE = s, SD_Y = sdy,
             SDE = sde(b, sdx, sdy), SE_SDE = sde(s, sdx, sdy),
             Class = classify(sde(b, sdx, sdy)))
}

rows_b <- rbind(
  make_row(iv_high, panel[high_rent == 1], "High-Rent Markets"),
  make_row(iv_low, panel[high_rent == 0], "Low-Rent Markets")
)

## Write SDE table
sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Standardized Effect Sizes: Legal Status and Housing Markets}\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (i in seq_len(nrow(rows_a))) {
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    rows_a$Outcome[i], rows_a$Beta[i], rows_a$SE[i],
    rows_a$SD_Y[i], rows_a$SDE[i], rows_a$SE_SDE[i], rows_a$Class[i]))
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Log Rent by Market Tightness)}} \\\\\n")
for (i in seq_len(nrow(rows_b))) {
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    rows_b$Outcome[i], rows_b$Beta[i], rows_b$SE[i],
    rows_b$SD_Y[i], rows_b$SDE[i], rows_b$SE_SDE[i], rows_b$Class[i]))
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} ")
cat("\\textbf{Country:} United States. ")
cat("\\textbf{Research question:} Does granting legal immigration status through asylum adjudication affect local housing markets (rents, home values, homeownership, immigrant concentration)? ")
cat("\\textbf{Policy mechanism:} Asylum grants confer work authorization, credit access, and eligibility for formal housing markets including mortgages and Section 8 vouchers; quasi-random judge assignment within immigration courts creates exogenous variation in the share of cases granted relief, isolating the legal status channel from immigration volume. ")
cat("\\textbf{Outcome definition:} Log median gross rent (ACS B25064), log median home value (ACS B25077), homeownership rate (owner-occupied/total tenure, ACS B25003), noncitizen share of population (ACS B05001). ")
cat("\\textbf{Treatment:} Continuous --- court-year asylum grant rate instrumented by case-weighted leave-one-out judge leniency. ")
cat("\\textbf{Data:} EOIR case-level proceedings (10.6 million cases, 2001--2023) merged with ACS 5-year county estimates (2010--2022); 68 immigration courts matched to 92 counties; 799 court-year observations. ")
cat("\\textbf{Method:} 2SLS with court and year fixed effects; standard errors clustered at court level; first-stage F $>$ 200. ")
cat("\\textbf{Sample:} Immigration courts with $\\geq$ 50 completed cases per year; counties matched via modal respondent FIPS from case addresses. ")
cat("SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-court standard deviation of grant rates and SD($Y$) is the outcome standard deviation. ")
cat("Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate (0.05---0.15), Small (0.005---0.05), Null ($< 0.005$).\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

cat("SDE table saved.\n")
for (i in seq_len(nrow(rows_a))) {
  cat(sprintf("  %s: SDE=%.3f [%s]\n", rows_a$Outcome[i], rows_a$SDE[i], rows_a$Class[i]))
}
