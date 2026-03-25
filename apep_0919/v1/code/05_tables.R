# ===========================================================================
# 05_tables.R — Generate all LaTeX tables for apep_0919
# Whistleblower Shield and Corruption Exposure
# ===========================================================================

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(paste0(data_dir, "analysis_panel.csv"))
results <- readRDS(paste0(data_dir, "main_results.rds"))
rob_results <- readRDS(paste0(data_dir, "robustness_results.rds"))
diag <- jsonlite::read_json(paste0(data_dir, "diagnostics.json"))

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================

cat("Generating Table 1: Summary Statistics...\n")

make_sumstat_row <- function(var, label, dt = panel) {
  x <- dt[[var]]
  x <- x[!is.na(x)]
  sprintf("%s & %.2f & %.2f & %.2f & %.2f & %d \\\\",
    label, mean(x), sd(x), min(x), max(x), length(x))
}

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max & N \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Outcomes}} \\\\[3pt]",
  make_sumstat_row("corruption_pc", "Corruption offenses per 100k"),
  make_sumstat_row("fraud_pc", "Fraud offenses per 100k"),
  make_sumstat_row("cpi_score", "CPI score (0--100)"),
  make_sumstat_row("court_exp_pc", "Court expenditure per capita (EUR)"),
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel B: Controls}} \\\\[3pt]",
  make_sumstat_row("gdp_pc", "GDP per capita (EUR)"),
  sprintf("Population (millions) & %.2f & %.2f & %.2f & %.2f & %d \\\\",
    mean(panel$population/1e6, na.rm=T), sd(panel$population/1e6, na.rm=T),
    min(panel$population/1e6, na.rm=T), max(panel$population/1e6, na.rm=T),
    sum(!is.na(panel$population))),
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel C: Treatment}} \\\\[3pt]",
  sprintf("Treated & %.2f & %.2f & 0 & 1 & %d \\\\",
    mean(panel$treated), sd(panel$treated), nrow(panel)),
  sprintf("Treatment cohorts & \\multicolumn{4}{c}{%s} & %d \\\\",
    paste(sort(unique(panel$g[panel$g > 0])), collapse = ", "),
    panel[g > 0, uniqueN(g)]),
  "\\hline\\hline",
  "\\multicolumn{6}{p{0.9\\textwidth}}{\\footnotesize \\textit{Notes:} Unit of observation is country--year for 27 EU member states, 2015--2023. Corruption and fraud offenses from Eurostat \\texttt{crim\\_off\\_cat} (ICCS codes 0703 and 0701). CPI scores from Eurostat \\texttt{sdg\\_16\\_50} (Transparency International, higher = less corrupt). Court expenditure from Eurostat \\texttt{gov\\_10a\\_exp} (COFOG GF0303). GDP from \\texttt{nama\\_10\\_gdp}. Treatment defined as the year of national transposition of EU Directive 2019/1937 (Whistleblower Protection).} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, paste0(tables_dir, "tab1_sumstats.tex"))

# ===========================================================================
# Table 2: Main Results (TWFE + CS-DiD)
# ===========================================================================

cat("Generating Table 2: Main Results...\n")

# Extract CS-DiD results
cs_corr_att <- diag$att_corruption
cs_corr_se <- diag$att_corruption_se
cs_fraud_att <- diag$att_fraud
cs_fraud_se <- diag$att_fraud_se
cs_cpi_att <- diag$att_cpi
cs_cpi_se <- diag$att_cpi_se

# Stars function
stars <- function(coef, se) {
  if (is.na(coef) || is.na(se) || se == 0) return("")
  z <- abs(coef / se)
  if (z > 2.576) return("$^{***}$")
  if (z > 1.960) return("$^{**}$")
  if (z > 1.645) return("$^{*}$")
  return("")
}

fmt <- function(x, d = 4) sprintf(paste0("%.", d, "f"), x)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Whistleblower Protection on Recorded Crime and Corruption Perceptions}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Detection} & Deterrence & Enforcement \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-5}",
  " & (1) & (2) & (3) & (4) \\\\",
  " & ln(Corruption/100k) & ln(Fraud/100k) & CPI Score & Court Exp/cap \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Two-Way Fixed Effects}} \\\\[3pt]",
  sprintf("Treated & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(coef(results$twfe_corruption)["treated"]),
    stars(coef(results$twfe_corruption)["treated"], se(results$twfe_corruption)["treated"]),
    fmt(coef(results$twfe_fraud)["treated"]),
    stars(coef(results$twfe_fraud)["treated"], se(results$twfe_fraud)["treated"]),
    fmt(coef(results$twfe_cpi)["treated"]),
    stars(coef(results$twfe_cpi)["treated"], se(results$twfe_cpi)["treated"]),
    fmt(coef(results$twfe_court)["treated"]),
    stars(coef(results$twfe_court)["treated"], se(results$twfe_court)["treated"])),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(se(results$twfe_corruption)["treated"]),
    fmt(se(results$twfe_fraud)["treated"]),
    fmt(se(results$twfe_cpi)["treated"]),
    fmt(se(results$twfe_court)["treated"])),
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel B: Callaway--Sant'Anna (2021)}} \\\\[3pt]",
  sprintf("ATT & %s%s & %s%s & %s%s & \\\\",
    fmt(cs_corr_att), stars(cs_corr_att, cs_corr_se),
    fmt(cs_fraud_att), stars(cs_fraud_att, cs_fraud_se),
    fmt(cs_cpi_att), stars(cs_cpi_att, cs_cpi_se)),
  sprintf(" & (%s) & (%s) & (%s) & \\\\",
    fmt(cs_corr_se), fmt(cs_fraud_se), fmt(cs_cpi_se)),
  "\\hline",
  sprintf("Country FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("GDP control & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Countries & %d & %d & %d & %d \\\\",
    results$twfe_corruption$nobs, results$twfe_fraud$nobs,
    results$twfe_cpi$nobs, results$twfe_court$nobs),
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Panel A reports TWFE estimates with country and year fixed effects, clustered standard errors at country level in parentheses. Panel B reports Callaway and Sant'Anna (2021) aggregate ATT using not-yet-treated as control group with universal base period. Treatment is transposition of EU Directive 2019/1937 (Whistleblower Protection). Columns 1--2 test the detection channel (recorded crime should increase); Column 3 tests the deterrence channel (CPI should improve, i.e., increase); Column 4 tests enforcement capacity. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2_lines, paste0(tables_dir, "tab2_main.tex"))

# ===========================================================================
# Table 3: Event Study Coefficients
# ===========================================================================

cat("Generating Table 3: Event Study...\n")

# Extract event study coefficients from fixest
es_corr_coefs <- coef(results$es_corruption)
es_corr_se <- se(results$es_corruption)
es_fraud_coefs <- coef(results$es_fraud)
es_fraud_se <- se(results$es_fraud)
es_cpi_coefs <- coef(results$es_cpi)
es_cpi_se <- se(results$es_cpi)

# Build event study table
tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Pre-Trends and Dynamic Treatment Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Relative Year & ln(Corruption/100k) & ln(Fraud/100k) & CPI Score \\\\",
  "\\hline"
)

# Event time labels
event_times <- c(-4, -3, -2, 0, 1, 2, 3)
event_labels <- c("$t-4$", "$t-3$", "$t-2$", "$t$ (adoption)", "$t+1$", "$t+2$", "$t+3$")

for (i in seq_along(event_times)) {
  et <- event_times[i]
  lab <- event_labels[i]

  # Get coefficients (fixest names them as rel_time_capped::X)
  cname <- paste0("rel_time_capped::", et)

  corr_c <- if (cname %in% names(es_corr_coefs)) es_corr_coefs[cname] else NA
  corr_s <- if (cname %in% names(es_corr_se)) es_corr_se[cname] else NA
  fraud_c <- if (cname %in% names(es_fraud_coefs)) es_fraud_coefs[cname] else NA
  fraud_s <- if (cname %in% names(es_fraud_se)) es_fraud_se[cname] else NA
  cpi_c <- if (cname %in% names(es_cpi_coefs)) es_cpi_coefs[cname] else NA
  cpi_s <- if (cname %in% names(es_cpi_se)) es_cpi_se[cname] else NA

  coef_str <- sprintf("%s & %s%s & %s%s & %s%s \\\\",
    lab,
    if (!is.na(corr_c)) paste0(fmt(corr_c), stars(corr_c, corr_s)) else "",
    "",
    if (!is.na(fraud_c)) paste0(fmt(fraud_c), stars(fraud_c, fraud_s)) else "",
    "",
    if (!is.na(cpi_c)) paste0(fmt(cpi_c), stars(cpi_c, cpi_s)) else "",
    "")

  se_str <- sprintf(" & %s & %s & %s \\\\",
    if (!is.na(corr_s)) paste0("(", fmt(corr_s), ")") else "",
    if (!is.na(fraud_s)) paste0("(", fmt(fraud_s), ")") else "",
    if (!is.na(cpi_s)) paste0("(", fmt(cpi_s), ")") else "")

  tab3_lines <- c(tab3_lines, coef_str, se_str)

  if (et == -2) tab3_lines <- c(tab3_lines, "\\hline")
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  "Reference period & \\multicolumn{3}{c}{$t-1$} \\\\",
  "Country FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Event-study estimates using TWFE with country and year fixed effects. Reference period is $t-1$ (one year before transposition). Standard errors clustered at the country level in parentheses. Sample restricted to eventually-treated countries. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, paste0(tables_dir, "tab3_eventstudy.tex"))

# ===========================================================================
# Table 4: Robustness
# ===========================================================================

cat("Generating Table 4: Robustness...\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: Corruption per Capita}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Baseline & Excl.\\ COVID & Log Counts & Placebo: GDP \\\\",
  "\\hline",
  sprintf("Treated & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(coef(results$twfe_corruption)["treated"]),
    stars(coef(results$twfe_corruption)["treated"], se(results$twfe_corruption)["treated"]),
    fmt(coef(rob_results$twfe_nocovid)["treated"]),
    stars(coef(rob_results$twfe_nocovid)["treated"], se(rob_results$twfe_nocovid)["treated"]),
    fmt(coef(rob_results$twfe_counts)["treated"]),
    stars(coef(rob_results$twfe_counts)["treated"], se(rob_results$twfe_counts)["treated"]),
    fmt(coef(rob_results$placebo_gdp)["treated"]),
    stars(coef(rob_results$placebo_gdp)["treated"], se(rob_results$placebo_gdp)["treated"])),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(se(results$twfe_corruption)["treated"]),
    fmt(se(rob_results$twfe_nocovid)["treated"]),
    fmt(se(rob_results$twfe_counts)["treated"]),
    fmt(se(rob_results$placebo_gdp)["treated"])),
  sprintf("WCB $p$-value & %s & & & \\\\",
    fmt(rob_results$wcb_corruption$p_val, 3)),
  "\\hline",
  sprintf("Excl.\\ 2020--2021 & No & Yes & No & No \\\\"),
  sprintf("Outcome & Per capita & Per capita & Counts & ln(GDP/cap) \\\\"),
  "Country FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.9\\textwidth}}{\\footnotesize \\textit{Notes:} All specifications include country and year fixed effects with standard errors clustered at the country level. Column 1 reproduces the baseline TWFE estimate with wild cluster bootstrap $p$-value (Webb weights, 9,999 replications). Column 2 drops 2020--2021 to address COVID contamination of the pre-period. Column 3 uses log crime counts with log population as control. Column 4 is a placebo test using log GDP per capita as outcome. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4_lines, paste0(tables_dir, "tab4_robustness.tex"))

# ===========================================================================
# Table 5: Heterogeneity
# ===========================================================================

cat("Generating Table 5: Heterogeneity...\n")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity: Prior Whistleblower Frameworks and Adoption Timing}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & (1) & (2) \\\\",
  " & By Prior WB Law & By Adoption Timing \\\\",
  "\\hline",
  sprintf("Treated $\\times$ Prior WB law & %s%s & \\\\",
    fmt(coef(rob_results$het_prior)["treated:has_prior_wb"]),
    stars(coef(rob_results$het_prior)["treated:has_prior_wb"],
          se(rob_results$het_prior)["treated:has_prior_wb"])),
  sprintf(" & (%s) & \\\\",
    fmt(se(rob_results$het_prior)["treated:has_prior_wb"])),
  sprintf("Treated $\\times$ No prior WB law & %s%s & \\\\",
    fmt(coef(rob_results$het_prior)["treated:I(1 - has_prior_wb)"]),
    stars(coef(rob_results$het_prior)["treated:I(1 - has_prior_wb)"],
          se(rob_results$het_prior)["treated:I(1 - has_prior_wb)"])),
  sprintf(" & (%s) & \\\\",
    fmt(se(rob_results$het_prior)["treated:I(1 - has_prior_wb)"])),
  sprintf("Treated $\\times$ Early adopter ($\\leq$ 2022) & & %s%s \\\\",
    fmt(coef(rob_results$het_early)["treated:early_adopter"]),
    stars(coef(rob_results$het_early)["treated:early_adopter"],
          se(rob_results$het_early)["treated:early_adopter"])),
  sprintf(" & & (%s) \\\\",
    fmt(se(rob_results$het_early)["treated:early_adopter"])),
  sprintf("Treated $\\times$ Late adopter ($\\geq$ 2023) & & %s%s \\\\",
    fmt(coef(rob_results$het_early)["treated:I(1 - early_adopter)"]),
    stars(coef(rob_results$het_early)["treated:I(1 - early_adopter)"],
          se(rob_results$het_early)["treated:I(1 - early_adopter)"])),
  sprintf(" & & (%s) \\\\",
    fmt(se(rob_results$het_early)["treated:I(1 - early_adopter)"])),
  "\\hline",
  "Country FE & Yes & Yes \\\\",
  "Year FE & Yes & Yes \\\\",
  "GDP control & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.8\\textwidth}}{\\footnotesize \\textit{Notes:} Dependent variable is ln(corruption offenses per 100,000). Column 1 interacts treatment with an indicator for countries that had pre-existing (partial) whistleblower protection laws before the directive (FR, IE, IT, NL, SE, DK, LU, HR). Column 2 interacts treatment with early adoption ($\\leq$ 2022) versus late adoption ($\\geq$ 2023). Standard errors clustered at the country level. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab5_lines, paste0(tables_dir, "tab5_heterogeneity.tex"))

# ===========================================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ===========================================================================

cat("Generating Table F1: SDE...\n")

# Compute SDEs
sd_corruption <- diag$outcome_sd_corruption
sd_fraud <- diag$outcome_sd_fraud
sd_cpi <- diag$outcome_sd_cpi

# Panel A: Pooled
sde_corruption <- diag$att_corruption / sd_corruption
sde_corruption_se <- diag$att_corruption_se / sd_corruption
sde_fraud <- diag$att_fraud / sd_fraud
sde_fraud_se <- diag$att_fraud_se / sd_fraud
sde_cpi <- diag$att_cpi / sd_cpi
sde_cpi_se <- diag$att_cpi_se / sd_cpi

# Court exp SDE from TWFE
court_coef <- coef(results$twfe_court)["treated"]
court_se <- se(results$twfe_court)["treated"]
sd_court <- sd(fread(paste0(data_dir, "analysis_panel.csv"))$court_exp_pc, na.rm = TRUE)
sde_court <- court_coef / sd_court
sde_court_se <- court_se / sd_court

classify <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel B: Heterogeneous (prior WB framework split)
# Countries WITH prior WB law
het_prior_coefs <- coef(rob_results$het_prior)
het_prior_ses <- se(rob_results$het_prior)
sde_corr_prior <- het_prior_coefs["treated:has_prior_wb"] / sd_corruption
sde_corr_prior_se <- het_prior_ses["treated:has_prior_wb"] / sd_corruption
sde_corr_noprior <- het_prior_coefs["treated:I(1 - has_prior_wb)"] / sd_corruption
sde_corr_noprior_se <- het_prior_ses["treated:I(1 - has_prior_wb)"] / sd_corruption

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} 27 European Union member states. ",
  "\\textbf{Research question:} Does the EU Whistleblower Protection Directive (2019/1937), which mandated internal and external reporting channels and anti-retaliation protections, affect police-recorded corruption and fraud, corruption perceptions, and judicial enforcement capacity? ",
  "\\textbf{Policy mechanism:} Requires organizations with 50+ employees to establish confidential reporting channels, protects whistleblowers from retaliation (dismissal, demotion, harassment), and creates external reporting pathways to designated authorities; staggered transposition across 27 member states between 2021 and 2024. ",
  "\\textbf{Outcome definition:} Panel A: ln(police-recorded corruption offenses per 100,000 from Eurostat crim\\_off\\_cat ICCS0703), ln(fraud per 100,000 from ICCS0701), CPI score from Eurostat sdg\\_16\\_50, court expenditure per capita from gov\\_10a\\_exp COFOG GF0303. Panel B: ln(corruption per 100,000) split by pre-existing whistleblower framework. ",
  "\\textbf{Treatment:} Binary indicator for national transposition of the directive into law. ",
  "\\textbf{Data:} Eurostat crime statistics, CPI, government expenditure, 27 EU member states, 2015--2023, country--year panel. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) with not-yet-treated controls and universal base period; standard errors clustered at country level. ",
  "\\textbf{Sample:} All 27 EU member states observed over 2015--2023 (up to 243 country--year observations); crime data available for subset of countries and years. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the full-sample standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Corruption/100k (ln) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(diag$att_corruption), fmt(diag$att_corruption_se), fmt(sd_corruption, 3),
    fmt(sde_corruption, 3), fmt(sde_corruption_se, 3), classify(sde_corruption)),
  sprintf("Fraud/100k (ln) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(diag$att_fraud), fmt(diag$att_fraud_se), fmt(sd_fraud, 3),
    fmt(sde_fraud, 3), fmt(sde_fraud_se, 3), classify(sde_fraud)),
  sprintf("CPI score & %s & %s & %s & %s & %s & %s \\\\",
    fmt(diag$att_cpi), fmt(diag$att_cpi_se), fmt(sd_cpi, 3),
    fmt(sde_cpi, 3), fmt(sde_cpi_se, 3), classify(sde_cpi)),
  sprintf("Court exp/capita & %s & %s & %s & %s & %s & %s \\\\",
    fmt(court_coef), fmt(court_se), fmt(sd_court, 3),
    fmt(sde_court, 3), fmt(sde_court_se, 3), classify(sde_court)),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Prior Whistleblower Framework)}} \\\\[3pt]",
  sprintf("Corruption --- Prior WB law & %s & %s & %s & %s & %s & %s \\\\",
    fmt(het_prior_coefs["treated:has_prior_wb"]), fmt(het_prior_ses["treated:has_prior_wb"]),
    fmt(sd_corruption, 3), fmt(sde_corr_prior, 3), fmt(sde_corr_prior_se, 3),
    classify(sde_corr_prior)),
  sprintf("Corruption --- No prior WB law & %s & %s & %s & %s & %s & %s \\\\",
    fmt(het_prior_coefs["treated:I(1 - has_prior_wb)"]), fmt(het_prior_ses["treated:I(1 - has_prior_wb)"]),
    fmt(sd_corruption, 3), fmt(sde_corr_noprior, 3), fmt(sde_corr_noprior_se, 3),
    classify(sde_corr_noprior)),
  "\\hline\\hline",
  sprintf("\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\begin{itemize}[leftmargin=*,nosep] %s \\end{itemize}} \\\\", sde_notes),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tabF1_lines, paste0(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files in:", normalizePath(tables_dir), "\n")
