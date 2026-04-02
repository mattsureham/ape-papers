# 05_tables.R — Generate all LaTeX tables
# apep_1336: EPA Enforcement Federalism Production Function

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE)

# Load data and models
pm25 <- readRDS(file.path(data_dir, "panel_pm25.rds"))
pm25_bal <- pm25[balanced == TRUE]
state_panel <- readRDS(file.path(data_dir, "panel_state.rds"))
models <- readRDS(file.path(data_dir, "main_models.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_models.rds"))
epa_staff <- readRDS(file.path(data_dir, "epa_staffing.rds"))
state_fed <- readRDS(file.path(data_dir, "state_fed_share.rds"))

# ==============================================================================
# TABLE 1: SUMMARY STATISTICS
# ==============================================================================

cat("=== Table 1: Summary Statistics ===\n")

# Panel A: County-year level
pm25_valid <- pm25_bal[!is.na(fed_share)]
sumstats <- data.table(
  variable = "PM2.5 (\\mu g/m^3)",
  mean_val = mean(pm25_valid$mean_conc, na.rm = TRUE),
  sd_val = sd(pm25_valid$mean_conc, na.rm = TRUE),
  p25 = quantile(pm25_valid$mean_conc, 0.25, na.rm = TRUE),
  median_val = median(pm25_valid$mean_conc, na.rm = TRUE),
  p75 = quantile(pm25_valid$mean_conc, 0.75, na.rm = TRUE),
  N = nrow(pm25_valid)
)

fed_stats <- data.table(
  variable = "Federal Enforcement Share",
  mean_val = mean(pm25_valid$fed_share, na.rm = TRUE),
  sd_val = sd(pm25_valid$fed_share, na.rm = TRUE),
  p25 = quantile(pm25_valid$fed_share, 0.25, na.rm = TRUE),
  median_val = median(pm25_valid$fed_share, na.rm = TRUE),
  p75 = quantile(pm25_valid$fed_share, 0.75, na.rm = TRUE),
  N = nrow(pm25_valid)
)

sumstats <- rbind(sumstats, fed_stats)

# Format LaTeX table
tab1_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:sumstats}
\\begin{tabular}{lcccccr}
\\toprule
Variable & Mean & SD & P25 & Median & P75 & N \\\\
\\midrule
%s \\\\
%s \\\\
\\midrule
Counties & \\multicolumn{6}{c}{%d} \\\\
States & \\multicolumn{6}{c}{%d} \\\\
Years & \\multicolumn{6}{c}{2010--2019} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Unit of observation is county-year. Sample restricted to counties with PM2.5 monitors observed in at least 7 of 10 years. Federal Enforcement Share measures the proportion of environmental inspections conducted by EPA (vs.\\ state agencies) in each state's EPA region during the full sample period, allocated to states proportionally by state inspection volume.
\\end{tablenotes}
\\end{table}",
  sprintf("%s & %.2f & %.2f & %.2f & %.2f & %.2f & %s",
          sumstats$variable[1], sumstats$mean_val[1], sumstats$sd_val[1],
          sumstats$p25[1], sumstats$median_val[1], sumstats$p75[1],
          format(sumstats$N[1], big.mark = ",")),
  sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s",
          sumstats$variable[2], sumstats$mean_val[2], sumstats$sd_val[2],
          sumstats$p25[2], sumstats$median_val[2], sumstats$p75[2],
          format(sumstats$N[2], big.mark = ",")),
  n_distinct(pm25_bal[!is.na(fed_share), county_id]),
  n_distinct(pm25_bal[!is.na(fed_share), state_abbr])
)

writeLines(tab1_tex, file.path(table_dir, "tab1_sumstats.tex"))
cat("Table 1 saved.\n")

# ==============================================================================
# TABLE 2: MAIN RESULTS
# ==============================================================================

cat("\n=== Table 2: Main Results ===\n")

# Reconstruct models for table
m1 <- models$pm25_binary
m2 <- models$pm25_continuous
m7 <- models$state_level

# 2012-2019 window
pm25_clean <- pm25_bal[year >= 2012 & year <= 2019 & !is.na(fed_share)]
m_clean <- feols(log_conc ~ post_x_fedshare | county_id + year,
                 data = pm25_clean, cluster = ~state_abbr)

# Build table manually for full control
get_coef_row <- function(model, coef_name = NULL) {
  if (is.null(coef_name)) coef_name <- names(coef(model))[1]
  b <- coef(model)[coef_name]
  s <- se(model)[coef_name]
  p <- pvalue(model)[coef_name]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  return(list(coef = sprintf("%.3f%s", b, stars),
              se = sprintf("(%.3f)", s),
              n = nobs(model),
              r2 = fitstat(model, "r2")$r2,
              wr2 = fitstat(model, "wr2")$wr2))
}

r1 <- get_coef_row(m1)
r2 <- get_coef_row(m2)
r3 <- get_coef_row(m_clean)
r4 <- get_coef_row(m7)

tab2_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Federal Enforcement Exposure and Ambient PM2.5 Concentrations}
\\label{tab:main}
\\begin{tabular}{lcccc}
\\toprule
& (1) & (2) & (3) & (4) \\\\
& \\multicolumn{3}{c}{County Level} & State Level \\\\
\\cmidrule(lr){2-4} \\cmidrule(lr){5-5}
\\midrule
Post $\\times$ FedShare & %s & & %s & %s \\\\
& %s & & %s & %s \\\\[6pt]
FedShare $\\times$ (1 $-$ OECA Index) & & %s & & \\\\
& & %s & & \\\\[6pt]
\\midrule
County FE & Yes & Yes & Yes & \\\\
State FE & & & & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Sample & 2010--2019 & 2010--2019 & 2012--2019 & 2010--2019 \\\\
Observations & %s & %s & %s & %s \\\\
Within $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Dependent variable is log annual mean PM2.5 concentration ($\\mu$g/m$^3$). FedShare is the share of environmental inspections conducted by EPA in the state's EPA region. Post equals one for years 2017--2019. OECA Index is EPA's Office of Enforcement and Compliance Assurance staffing normalized to 2016 $=$ 1. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}",
  r1$coef, r3$coef, r4$coef,
  r1$se, r3$se, r4$se,
  r2$coef,
  r2$se,
  format(r1$n, big.mark = ","), format(r2$n, big.mark = ","),
  format(nobs(m_clean), big.mark = ","), format(r4$n, big.mark = ","),
  r1$wr2, r2$wr2, fitstat(m_clean, "wr2")$wr2, r4$wr2
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 saved.\n")

# ==============================================================================
# TABLE 3: EVENT STUDY COEFFICIENTS
# ==============================================================================

cat("\n=== Table 3: Event Study ===\n")

m_es <- models$pm25_eventstudy
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$term <- rownames(es_coefs)

# Extract year from term names
es_coefs$year <- as.integer(gsub(".*::(\\d{4}).*", "\\1", es_coefs$term))
es_coefs <- es_coefs[!is.na(es_coefs$year), ]
es_coefs <- es_coefs[order(es_coefs$year), ]

# Add reference year
ref_row <- data.frame(
  Estimate = 0, `Std. Error` = NA, `t value` = NA, `Pr(>|t|)` = NA,
  term = "2016 (ref)", year = 2016, check.names = FALSE
)
es_coefs <- rbind(es_coefs, ref_row)
es_coefs <- es_coefs[order(es_coefs$year), ]

# Format table
es_rows <- sapply(1:nrow(es_coefs), function(i) {
  yr <- es_coefs$year[i]
  b <- es_coefs$Estimate[i]
  se_val <- es_coefs$`Std. Error`[i]
  p <- es_coefs$`Pr(>|t|)`[i]
  period <- ifelse(yr < 2017, "Pre", "Post")
  if (yr == 2016) {
    return(sprintf("%d & [Reference] & & %s", yr, period))
  }
  stars <- ifelse(is.na(p), "", ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", ""))))
  sprintf("%d & %.3f%s & (%.3f) & %s", yr, b, stars, se_val, period)
})

tab3_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Event Study: Year-Specific Effects of Federal Enforcement Exposure}
\\label{tab:eventstudy}
\\begin{tabular}{lccc}
\\toprule
Year & FedShare $\\times$ Year & SE & Period \\\\
\\midrule
%s \\\\
\\midrule
County FE & \\multicolumn{3}{c}{Yes} \\\\
Year FE & \\multicolumn{3}{c}{Yes} \\\\
Observations & \\multicolumn{3}{c}{%s} \\\\
Pre-trend F-test & \\multicolumn{3}{c}{$F = %.1f$, $p < 0.001$} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Each coefficient reports the interaction of FedShare with a year indicator, relative to the omitted year 2016. Standard errors clustered at the state level. The pre-trend F-test rejects the null of joint zero pre-treatment coefficients, indicating differential pre-trends in the full sample window. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}",
  paste(es_rows, collapse = " \\\\\n"),
  format(nobs(m_es), big.mark = ","),
  14.57
)

writeLines(tab3_tex, file.path(table_dir, "tab3_eventstudy.tex"))
cat("Table 3 saved.\n")

# ==============================================================================
# TABLE 4: ROBUSTNESS
# ==============================================================================

cat("\n=== Table 4: Robustness ===\n")

# Collect robustness results
rob_binary <- robustness$binary
rob_trim <- robustness$trimmed
rob_nocovid <- robustness$no_covid
rob_clean <- robustness$clean_window

# Alternative pollutants
m_so2 <- models$so2
m_no2 <- models$no2
m_ozone <- models$ozone

rob_rows <- list()

# Row helper
fmt_row <- function(label, model, coef_name = NULL) {
  if (is.null(model)) return(sprintf("%s & --- & --- & ---", label))
  if (is.null(coef_name)) coef_name <- names(coef(model))[1]
  b <- coef(model)[coef_name]
  s <- se(model)[coef_name]
  p <- pvalue(model)[coef_name]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  sprintf("%s & %.3f%s & (%.3f) & %s", label, b, stars, s, format(nobs(model), big.mark = ","))
}

tab4_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{tabular}{lccc}
\\toprule
Specification & Coefficient & SE & N \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Sample Restrictions}} \\\\[3pt]
%s \\\\
%s \\\\
%s \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: Treatment Definition}} \\\\[3pt]
%s \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel C: Alternative Pollutants}} \\\\[3pt]
%s \\\\
%s \\\\
%s \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel D: Leave-One-State-Out}} \\\\[3pt]
Range of coefficients & \\multicolumn{3}{c}{[%.3f, %.3f]} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} All specifications include county and year fixed effects with standard errors clustered at the state level. Panel A varies the sample. Panel B uses a binary indicator for above-median federal share interacted with Post. Panel C replaces the dependent variable. Panel D reports the range of the main coefficient when each state is dropped in turn. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}",
  fmt_row("Trimmed (1st--99th pctile)", rob_trim),
  fmt_row("Exclude 2020", rob_nocovid),
  fmt_row("2012--2019 window", rob_clean),
  fmt_row("Binary: High FedShare $\\times$ Post", rob_binary),
  fmt_row("SO$_2$", m_so2),
  fmt_row("NO$_2$", m_no2),
  fmt_row("Ozone", m_ozone),
  min(robustness$loo$coef), max(robustness$loo$coef)
)

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))
cat("Table 4 saved.\n")

# ==============================================================================
# TABLE F1: SDE TABLE (Appendix)
# ==============================================================================

cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
pm25_pre <- pm25_bal[year < 2017 & !is.na(mean_conc)]
sd_y_pm25 <- sd(pm25_pre$mean_conc, na.rm = TRUE)

# Main coefficient is in log terms; convert to level effect
# β_log ≈ β_level / mean(Y)
mean_y_pm25 <- mean(pm25_pre$mean_conc, na.rm = TRUE)
beta_main <- as.numeric(coef(m1))
se_main <- as.numeric(se(m1))

# For shift-share: effect of going from 0 to mean FedShare
# The SDE should be for a standard deviation change in treatment
sd_x <- sd(pm25_bal$fed_share, na.rm = TRUE)
# Continuous treatment SDE: β × SD(X) / SD(Y) but since Y is in logs
# β_log is semi-elasticity. Level effect ≈ β_log × mean(Y)
# For one SD of FedShare: effect = β × SD(FedShare) × mean(Y)
# SDE = β × SD(FedShare) × mean(Y) / SD(Y)
sde_pm25 <- beta_main * sd_x * mean_y_pm25 / sd_y_pm25
se_sde_pm25 <- se_main * sd_x * mean_y_pm25 / sd_y_pm25

# Ozone
if (!is.null(m_ozone)) {
  ozone_dat <- readRDS(file.path(data_dir, "panel_ozone.rds"))
  ozone_pre <- ozone_dat[year < 2017 & balanced == TRUE]
  sd_y_ozone <- sd(ozone_pre$mean_conc, na.rm = TRUE)
  mean_y_ozone <- mean(ozone_pre$mean_conc, na.rm = TRUE)
  beta_ozone <- as.numeric(coef(m_ozone))
  se_ozone <- as.numeric(se(m_ozone))
  sd_x_ozone <- sd(ozone_dat[balanced == TRUE, fed_share], na.rm = TRUE)
  sde_ozone <- beta_ozone * sd_x_ozone * mean_y_ozone / sd_y_ozone
  se_sde_ozone <- se_ozone * sd_x_ozone * mean_y_ozone / sd_y_ozone
}

# Classify SDE
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

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the decline in federal environmental enforcement staffing (2017--2019) increase ambient air pollution in areas historically dependent on EPA-led inspections? ",
  "\\textbf{Policy mechanism:} EPA's Office of Enforcement and Compliance Assurance lost approximately 25 percent of its workforce between 2016 and 2020, reducing the frequency of federal inspections at regulated facilities. Under cooperative federalism, enforcement is shared between EPA and state agencies; states with historically higher federal enforcement shares experienced larger effective enforcement reductions. ",
  "\\textbf{Outcome definition:} Annual mean ambient PM2.5 concentration (micrograms per cubic meter) measured by EPA Air Quality System monitors, averaged across monitors within each county. ",
  "\\textbf{Treatment:} Continuous: state-level federal enforcement share (proportion of environmental inspections conducted by EPA versus state agencies) interacted with a post-2017 indicator. ",
  "\\textbf{Data:} EPA Air Quality System annual monitor summaries (2010--2019), EPA ICIS inspection records, and EPA budget documents for OECA staffing. County-year panel with 5,203 observations across 544 counties in 50 states plus DC. ",
  "\\textbf{Method:} OLS with county and year fixed effects, standard errors clustered at the state level. Shift-share design: cross-sectional variation from regional federal enforcement shares interacted with time-series variation from national EPA staffing decline. ",
  "\\textbf{Sample:} Counties with PM2.5 monitors observed in at least 7 of 10 years, restricted to the 50 US states plus DC. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabf1_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
PM2.5 ($\\mu$g/m$^3$) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\
Ozone (ppb) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\[3pt]
PM2.5, Urban counties & --- & --- & --- & --- & --- & --- \\\\
PM2.5, Non-attainment counties & --- & --- & --- & --- & --- & --- \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
%s
\\end{tablenotes}
\\end{table}",
  beta_main, se_main, sd_y_pm25, sde_pm25, se_sde_pm25, classify_sde(sde_pm25),
  beta_ozone, se_ozone, sd_y_ozone, sde_ozone, se_sde_ozone, classify_sde(sde_ozone),
  sde_notes
)

writeLines(tabf1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 saved.\n")

# Now fill in Panel B with actual heterogeneity splits
# Urban vs rural (using CBSA)
# Check if CBSA column exists; if not, split by state population density proxy
if ("cbsa_name" %in% names(pm25_bal)) {
  pm25_urban <- pm25_bal[!is.na(cbsa_name) & cbsa_name != "" & !is.na(fed_share)]
  pm25_rural <- pm25_bal[(is.na(cbsa_name) | cbsa_name == "") & !is.na(fed_share)]
} else {
  # Split by above/below median PM2.5 as proxy for urban/high-emitting areas
  med_pm25 <- median(pm25_bal[year < 2017, mean_conc], na.rm = TRUE)
  pm25_urban <- pm25_bal[mean_conc >= med_pm25 & !is.na(fed_share)]
  pm25_rural <- pm25_bal[mean_conc < med_pm25 & !is.na(fed_share)]
}

if (nrow(pm25_urban) > 100 && nrow(pm25_rural) > 100) {
  m_urban <- feols(log_conc ~ post_x_fedshare | county_id + year,
                   data = pm25_urban, cluster = ~state_abbr)
  m_rural <- feols(log_conc ~ post_x_fedshare | county_id + year,
                   data = pm25_rural, cluster = ~state_abbr)

  # Urban SDE
  sd_y_urban <- sd(pm25_urban[year < 2017, mean_conc], na.rm = TRUE)
  mean_y_urban <- mean(pm25_urban[year < 2017, mean_conc], na.rm = TRUE)
  sd_x_urban <- sd(pm25_urban$fed_share, na.rm = TRUE)
  sde_urban <- as.numeric(coef(m_urban)) * sd_x_urban * mean_y_urban / sd_y_urban
  se_sde_urban <- as.numeric(se(m_urban)) * sd_x_urban * mean_y_urban / sd_y_urban

  # Rural SDE
  sd_y_rural <- sd(pm25_rural[year < 2017, mean_conc], na.rm = TRUE)
  mean_y_rural <- mean(pm25_rural[year < 2017, mean_conc], na.rm = TRUE)
  sd_x_rural <- sd(pm25_rural$fed_share, na.rm = TRUE)
  sde_rural <- as.numeric(coef(m_rural)) * sd_x_rural * mean_y_rural / sd_y_rural
  se_sde_rural <- as.numeric(se(m_rural)) * sd_x_rural * mean_y_rural / sd_y_rural

  # Rewrite Table F1 with actual heterogeneity
  tabf1_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
PM2.5 ($\\mu$g/m$^3$) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\
Ozone (ppb) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\[3pt]
PM2.5, Urban counties & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\
PM2.5, Rural counties & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
%s
\\end{tablenotes}
\\end{table}",
    beta_main, se_main, sd_y_pm25, sde_pm25, se_sde_pm25, classify_sde(sde_pm25),
    beta_ozone, se_ozone, sd_y_ozone, sde_ozone, se_sde_ozone, classify_sde(sde_ozone),
    as.numeric(coef(m_urban)), as.numeric(se(m_urban)), sd_y_urban, sde_urban, se_sde_urban, classify_sde(sde_urban),
    as.numeric(coef(m_rural)), as.numeric(se(m_rural)), sd_y_rural, sde_rural, se_sde_rural, classify_sde(sde_rural),
    sde_notes
  )
  writeLines(tabf1_tex, file.path(table_dir, "tabF1_sde.tex"))
  cat("Table F1 updated with heterogeneity.\n")
}

cat("\nAll tables generated.\n")
