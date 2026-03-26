## 05_tables.R — Generate all LaTeX tables
## apep_1018: The Spotlight Effect on Safety Reporting

source("00_packages.R")

cat("=== Loading results ===\n")
panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
main <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

# --------------------------------------------------------------------------
# Table 1: Summary Statistics
# --------------------------------------------------------------------------
cat("\n=== Table 1: Summary Statistics ===\n")

panel_clean <- panel %>% filter(!is.na(sir_rate) & is.finite(sir_rate))

vars_data <- list(
  list("SIR Reports (count)", panel$sir_count),
  list("Peer SIR (same sector, other states)", panel$peer_sir),
  list("SIR Rate (per 100K emp.)", panel_clean$sir_rate),
  list("Employment (state-sector est.)", panel$state_emp_est)
)

tab1_lines <- "\\begin{table}[t]\n\\centering\n\\caption{Summary Statistics}\\label{tab:summary}\n\\begin{tabular}{lrrrr}\n\\toprule\nVariable & Mean & SD & Min & Max \\\\\n\\midrule\n"

for (v in vars_data) {
  x <- v[[2]]
  tab1_lines <- paste0(tab1_lines,
    v[[1]], " & ",
    formatC(mean(x, na.rm=TRUE), format="f", digits=2, big.mark=","), " & ",
    formatC(sd(x, na.rm=TRUE), format="f", digits=2, big.mark=","), " & ",
    formatC(min(x, na.rm=TRUE), format="f", digits=0, big.mark=","), " & ",
    formatC(max(x, na.rm=TRUE), format="f", digits=0, big.mark=","), " \\\\\n")
}

n_obs <- nrow(panel)
n_cells <- n_distinct(panel$cell_id)
n_qtrs <- n_distinct(panel$yearqtr)

tab1_lines <- paste0(tab1_lines,
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel: ", n_cells,
  " sector-state cells $\\times$ ", n_qtrs, " quarters = ",
  format(n_obs, big.mark=","), " observations}} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Unit of observation is NAICS 2-digit sector $\\times$ state $\\times$ quarter, 2015Q1--2024Q3. SIR Reports are OSHA Severe Injury Reports (hospitalizations, amputations, eye losses). Peer SIR counts reports in the same 2-digit NAICS sector but different states. Sample restricted to sectors with $\\geq$500 total reports and states with $\\geq$200 total reports over the sample period.\n",
  "\\end{tablenotes}\n\\end{table}\n")

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 saved\n")

# --------------------------------------------------------------------------
# Table 2: Main OLS
# --------------------------------------------------------------------------
cat("\n=== Table 2: Main OLS ===\n")

etable(main$ols_baseline, main$ols_log, main$ols_rate, main$ols_stateqtr,
       headers = c("Count", "Log-Log", "Rate", "State$\\times$Qtr FE"),
       tex = TRUE, file = "../tables/tab2_ols.tex",
       title = "Peer Severe Injury Reports and Own Reporting",
       label = "tab:ols", depvar = TRUE,
       style.tex = style.tex("aer"),
       notes = "Unit of observation is NAICS 2-digit sector $\\times$ state $\\times$ quarter, 2015Q1--2024Q3. Peer SIR is the count of severe injury reports in the same sector but different states. Columns 1--3 include cell (sector $\\times$ state) and year-quarter fixed effects with state-clustered standard errors. Column 4 adds state $\\times$ year-quarter fixed effects with sector-clustered standard errors. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
       replace = TRUE)

cat("Table 2 saved\n")

# --------------------------------------------------------------------------
# Table 3: Mechanisms (injury type + inspection + heterogeneity)
# --------------------------------------------------------------------------
cat("\n=== Table 3: Mechanisms ===\n")

etable(main$mech_injury_type, main$mech_inspection,
       main$het_highrisk, main$het_lowrisk,
       headers = c("Injury Type", "Inspection", "High-Risk", "Low-Risk"),
       tex = TRUE, file = "../tables/tab3_mechanisms.tex",
       title = "Mechanism Tests: Injury Severity, Inspection Visibility, and Sector Risk",
       label = "tab:mechanisms", depvar = TRUE,
       style.tex = style.tex("aer"),
       notes = "Column 1 decomposes peer events into amputations (more gruesome/newsworthy) and hospitalizations. Column 2 separates OSHA inspection-linked events from uninspected events. Columns 3--4 split the sample at the median sector-level SIR rate. All specifications include cell and year-quarter fixed effects with state-clustered standard errors. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
       replace = TRUE)

cat("Table 3 saved\n")

# --------------------------------------------------------------------------
# Table 4: Identification Tests (placebo + lead + horse race)
# --------------------------------------------------------------------------
cat("\n=== Table 4: Identification Tests ===\n")

etable(robust$placebo_cross, robust$horse_race,
       robust$lead_placebo, robust$lag_structure,
       headers = c("Cross-Sector", "Horse Race", "Lead Test", "Lag Structure"),
       tex = TRUE, file = "../tables/tab4_identification.tex",
       title = "Identification Tests: Cross-Sector Placebo and Temporal Structure",
       label = "tab:identification", depvar = TRUE,
       style.tex = style.tex("aer"),
       notes = "Column 1 uses cross-sector peer SIR (same state, different sector) as a placebo. Column 2 includes both within-sector and cross-sector peer measures. Column 3 tests whether future (lead) peer SIR predicts current reporting. Column 4 estimates the lag structure of the peer effect. All specifications include cell and year-quarter fixed effects with state-clustered standard errors. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
       replace = TRUE)

cat("Table 4 saved\n")

# --------------------------------------------------------------------------
# Table 5: Robustness
# --------------------------------------------------------------------------
cat("\n=== Table 5: Robustness ===\n")

etable(robust$no_covid, robust$cluster_sector, robust$cluster_twoway,
       headers = c("Excl. COVID", "Sector Cluster", "Two-Way Cluster"),
       tex = TRUE, file = "../tables/tab5_robustness.tex",
       title = "Robustness Checks",
       label = "tab:robustness", depvar = TRUE,
       style.tex = style.tex("aer"),
       notes = "Column 1 excludes 2020--2021 (COVID period). Column 2 clusters standard errors at the NAICS 2-digit sector level. Column 3 uses two-way clustering (state $\\times$ year-quarter). All specifications include cell and year-quarter fixed effects. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
       replace = TRUE)

cat("Table 5 saved\n")

# --------------------------------------------------------------------------
# SDE Appendix Table (MANDATORY)
# --------------------------------------------------------------------------
cat("\n=== SDE Table ===\n")

# Coefficients and SDs
beta1 <- coef(main$ols_baseline)["peer_sir"]
se1 <- sqrt(vcov(main$ols_baseline)["peer_sir", "peer_sir"])
sdy1 <- sd(panel$sir_count)
sde1 <- beta1 / sdy1; sde_se1 <- se1 / sdy1

beta2 <- coef(main$ols_log)["log_peer_sir"]
se2 <- sqrt(vcov(main$ols_log)["log_peer_sir", "log_peer_sir"])
sdy2 <- sd(log1p(panel$sir_count))
sde2 <- beta2 / sdy2; sde_se2 <- se2 / sdy2

beta3 <- coef(main$ols_rate)["peer_sir"]
se3 <- sqrt(vcov(main$ols_rate)["peer_sir", "peer_sir"])
sdy3 <- sd(panel_clean$sir_rate)
sde3 <- beta3 / sdy3; sde_se3 <- se3 / sdy3

# Heterogeneity (sample splits)
beta_hi <- coef(main$het_highrisk)["peer_sir"]
se_hi <- sqrt(vcov(main$het_highrisk)["peer_sir", "peer_sir"])
sdy_hi <- sd(panel$sir_count[panel$high_risk == 1])
sde_hi <- beta_hi / sdy_hi; sde_se_hi <- se_hi / sdy_hi

beta_lo <- coef(main$het_lowrisk)["peer_sir"]
se_lo <- sqrt(vcov(main$het_lowrisk)["peer_sir", "peer_sir"])
sdy_lo <- sd(panel$sir_count[panel$high_risk == 0])
sde_lo <- beta_lo / sdy_lo; sde_se_lo <- se_lo / sdy_lo

classify <- function(s) {
  a <- abs(s)
  if (a < 0.005) "Null"
  else if (a < 0.05) { if (s > 0) "Small positive" else "Small negative" }
  else if (a < 0.15) { if (s > 0) "Moderate positive" else "Moderate negative" }
  else { if (s > 0) "Large positive" else "Large negative" }
}

fe <- function(x) formatC(x, format="f", digits=4)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the volume of severe workplace injuries reported by peer firms in the same industry predict a firm's own compliance with OSHA's mandatory severe injury reporting requirement (29 CFR 1904.39)? ",
  "\\textbf{Policy mechanism:} OSHA's 2015 severe injury reporting rule mandates that employers report hospitalizations, amputations, and eye losses within 24 hours; DOL estimates over 50 percent non-compliance; peer-firm injury reports may increase own reporting through enforcement salience, reputational contagion, or common regulatory attention. ",
  "\\textbf{Outcome definition:} Quarterly count of OSHA Severe Injury Reports filed per NAICS 2-digit sector and state cell. ",
  "\\textbf{Treatment:} Continuous---number of peer-firm SIR filings in the same NAICS 2-digit sector but different states during the same quarter. ",
  "\\textbf{Data:} OSHA SIR database (97,284 reports, 2015--2024), BLS QCEW (national sector-quarter employment). Unit of observation: sector $\\times$ state $\\times$ quarter. ",
  "\\textbf{Method:} OLS with cell (sector $\\times$ state) and year-quarter fixed effects; standard errors clustered at state level. ",
  "\\textbf{Sample:} 21 NAICS 2-digit sectors with $\\geq$500 reports and 32 states with $\\geq$200 reports; 26,208 observations. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-cell standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textbf{Panel A: Pooled}} \\\\\n",
  "SIR Count (OLS) & ", fe(beta1), " & ", fe(se1), " & ", fe(sdy1),
  " & ", fe(sde1), " & ", fe(sde_se1), " & ", classify(sde1), " \\\\\n",
  "Log SIR (OLS) & ", fe(beta2), " & ", fe(se2), " & ", fe(sdy2),
  " & ", fe(sde2), " & ", fe(sde_se2), " & ", classify(sde2), " \\\\\n",
  "SIR Rate (OLS) & ", fe(beta3), " & ", fe(se3), " & ", fe(sdy3),
  " & ", fe(sde3), " & ", fe(sde_se3), " & ", classify(sde3), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textbf{Panel B: Heterogeneous (Sample Splits)}} \\\\\n",
  "High-Risk Sectors & ", fe(beta_hi), " & ", fe(se_hi), " & ", fe(sdy_hi),
  " & ", fe(sde_hi), " & ", fe(sde_se_hi), " & ", classify(sde_hi), " \\\\\n",
  "Low-Risk Sectors & ", fe(beta_lo), " & ", fe(se_lo), " & ", fe(sdy_lo),
  " & ", fe(sde_lo), " & ", fe(sde_se_lo), " & ", classify(sde_lo), " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("SDE table saved\n")

cat("\nAll tables:\n")
cat(paste(list.files("../tables/", pattern="\\.tex$"), collapse=", "), "\n")
