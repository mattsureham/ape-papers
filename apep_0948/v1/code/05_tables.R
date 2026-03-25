# 05_tables.R — Generate all LaTeX tables
# Paper: The Fiscal Shadow of the Pill Mill (apep_0948)

source("00_packages.R")

df <- arrow::read_parquet("../data/analysis_state.parquet")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

# Helper: format coefficient with stars
fmt_coef <- function(coef, se, digits = 3) {
  t_stat <- abs(coef / se)
  stars <- ifelse(t_stat > 2.576, "^{***}",
           ifelse(t_stat > 1.96, "^{**}",
           ifelse(t_stat > 1.645, "^{*}", "")))
  fmt <- paste0("%.", digits, "f%s")
  sprintf(fmt, coef, stars)
}

fmt_se <- function(se, digits = 3) {
  fmt <- paste0("(%.", digits, "f)")
  sprintf(fmt, se)
}

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics...\n")

trip <- df |> filter(triplicate == 1)
nontrip <- df |> filter(triplicate == 0)

make_row <- function(varname, label, digits = 2) {
  all_vals <- df[[varname]]
  trip_vals <- trip[[varname]]
  nontrip_vals <- nontrip[[varname]]

  diff_se <- sqrt(var(trip_vals, na.rm = TRUE)/sum(!is.na(trip_vals)) +
                  var(nontrip_vals, na.rm = TRUE)/sum(!is.na(nontrip_vals)))
  diff_mean <- mean(nontrip_vals, na.rm = TRUE) - mean(trip_vals, na.rm = TRUE)
  t_stat <- abs(diff_mean / diff_se)
  stars <- ifelse(t_stat > 2.576, "^{***}",
           ifelse(t_stat > 1.96, "^{**}",
           ifelse(t_stat > 1.645, "^{*}", "")))

  fmt <- paste0("%.", digits, "f")
  paste0(label, " & ",
         sprintf(fmt, mean(all_vals, na.rm = TRUE)), " & ",
         sprintf(fmt, sd(all_vals, na.rm = TRUE)), " & ",
         sprintf(fmt, mean(trip_vals, na.rm = TRUE)), " & ",
         sprintf(fmt, mean(nontrip_vals, na.rm = TRUE)), " & ",
         sprintf(paste0(fmt, "%s"), diff_mean, stars),
         " \\\\")
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Opioid Supply and Medicaid Treatment by Triplicate Status}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & All & & Triplicate & Non-Triplicate & Difference \\\\",
  " & Mean & SD & Mean & Mean & (Non-Trip $-$ Trip) \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel A: Opioid Supply (ARCOS, 2006--2012 avg.)}} \\\\",
  "\\addlinespace",
  make_row("oxy_pc", "Oxycodone pills per capita (annual)", 1),
  make_row("oxy_share", "Oxycodone share of total pills", 3),
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: Medicaid MAT Treatment (T-MSIS, 2018--2024 avg.)}} \\\\",
  "\\addlinespace",
  make_row("mat_claims_pc", "MAT claims per 1,000 pop.", 2),
  make_row("mat_beneficiaries_pc", "MAT beneficiaries per 1,000 pop.", 2),
  make_row("mat_paid_pc", "MAT spending per capita (\\$)", 2),
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel C: State Characteristics}} \\\\",
  "\\addlinespace",
  make_row("population", "Population (millions)", 0),
  make_row("poverty_rate", "Poverty rate", 3),
  make_row("uninsured_rate", "Uninsured rate", 3),
  "\\addlinespace",
  "\\hline",
  sprintf("Observations & %d & & %d & %d & \\\\", nrow(df), nrow(trip), nrow(nontrip)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} ARCOS data from DEA via Washington Post (2006--2012 annual pill shipments). T-MSIS from HHS Medicaid Provider Spending (2018--2024 monthly claims). MAT codes: methadone (H0020), buprenorphine (J0571--J0575), naltrexone (J2315). Triplicate states: CA, ID, IL, IN, NY, TX, WA. Stars on difference: $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$ from two-sample $t$-test.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# =============================================================================
# Table 2: First Stage (Triplicate → Pills per capita)
# =============================================================================
cat("Generating Table 2: First Stage...\n")

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{First Stage: Triplicate Programs and Opioid Supply}",
  "\\label{tab:first_stage}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Dep.\\ var.: Log oxycodone per capita} \\\\",
  " & (1) & (2) \\\\",
  "\\hline",
  "\\addlinespace",
  sprintf("Triplicate state & %s & %s \\\\",
          fmt_coef(results$fs_base$coef, results$fs_base$se),
          fmt_coef(results$fs_controls$coef, results$fs_controls$se)),
  sprintf(" & %s & %s \\\\",
          fmt_se(results$fs_base$se),
          fmt_se(results$fs_controls$se)),
  "\\addlinespace",
  "\\hline",
  sprintf("Controls & No & Yes \\\\"),
  sprintf("$F$-statistic & %.1f & %.1f \\\\",
          results$fs_base$f_stat, results$fs_controls$f_stat),
  sprintf("Observations & %d & %d \\\\",
          results$fs_base$n, results$fs_controls$n),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable is log average annual oxycodone pills per capita (ARCOS, 2006--2012). Triplicate state = 1 for CA, ID, IL, IN, NY, TX, WA (states adopting triplicate prescription programs before 1988). Controls: log population, poverty rate, uninsured rate. HC1 robust standard errors in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_first_stage.tex")

# =============================================================================
# Table 3: Main IV Results
# =============================================================================
cat("Generating Table 3: Main IV Results...\n")

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Supply-to-Treatment Pipeline: IV Estimates}",
  "\\label{tab:iv_results}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{OLS} & \\multicolumn{2}{c}{IV/2SLS} \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel A: Dep.\\ var.\\ = Log MAT claims per 1,000 pop.}} \\\\",
  "\\addlinespace",
  sprintf("Log oxycodone per capita & %s & %s & %s & %s \\\\",
          fmt_coef(results$ols_base$coef, results$ols_base$se),
          fmt_coef(results$ols_controls$coef, results$ols_controls$se),
          fmt_coef(results$iv_base$coef, results$iv_base$se),
          fmt_coef(results$iv_controls$coef, results$iv_controls$se)),
  sprintf(" & %s & %s & %s & %s \\\\",
          fmt_se(results$ols_base$se),
          fmt_se(results$ols_controls$se),
          fmt_se(results$iv_base$se),
          fmt_se(results$iv_controls$se)),
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B: Dep.\\ var.\\ = Log MAT beneficiaries per 1,000 pop.}} \\\\",
  "\\addlinespace",
  sprintf("Log oxycodone per capita & & & & %s \\\\",
          fmt_coef(results$iv_bene$coef, results$iv_bene$se)),
  sprintf(" & & & & %s \\\\",
          fmt_se(results$iv_bene$se)),
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel C: Dep.\\ var.\\ = Log MAT spending per capita}} \\\\",
  "\\addlinespace",
  sprintf("Log oxycodone per capita & & & & %s \\\\",
          fmt_coef(results$iv_paid$coef, results$iv_paid$se)),
  sprintf(" & & & & %s \\\\",
          fmt_se(results$iv_paid$se)),
  "\\addlinespace",
  "\\hline",
  "Controls & No & Yes & No & Yes \\\\",
  sprintf("First-stage $F$ & & & %.1f & %.1f \\\\",
          results$iv_base$f_stat, results$iv_controls$f_stat),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          results$ols_base$n, results$ols_controls$n,
          results$iv_base$n, results$iv_controls$n),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each cell reports a separate regression. Endogenous variable: log average annual oxycodone pills per capita (ARCOS, 2006--2012). Instrument: triplicate state indicator. Outcomes: T-MSIS Medicaid claims (2018--2024 average). Controls: log population, poverty rate, uninsured rate. HC1 robust standard errors in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_iv_results.tex")

# =============================================================================
# Table 4: Placebo — Non-Opioid SUD
# =============================================================================
cat("Generating Table 4: Placebo Test...\n")

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Placebo Test: Opioid Supply and Non-Opioid SUD Treatment}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Reduced Form & IV/2SLS \\\\",
  " & (1) & (2) \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Dep.\\ var.\\ = Log non-opioid SUD claims per 1,000 pop.}} \\\\",
  "\\addlinespace",
  sprintf("Triplicate state & %s & \\\\",
          fmt_coef(robustness$placebo_rf$coef, robustness$placebo_rf$se)),
  sprintf(" & %s & \\\\",
          fmt_se(robustness$placebo_rf$se)),
  "\\addlinespace",
  sprintf("Log oxycodone per capita & & %s \\\\",
          fmt_coef(robustness$placebo_iv$coef, robustness$placebo_iv$se)),
  sprintf(" & & %s \\\\",
          fmt_se(robustness$placebo_iv$se)),
  "\\addlinespace",
  "\\hline",
  "Controls & Yes & Yes \\\\",
  sprintf("Observations & %d & %d \\\\",
          robustness$placebo_rf$n, robustness$placebo_iv$n),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Non-opioid SUD codes: alcohol/drug counseling (H0015), treatment services (H0016, H0005--H0007, H2035--H2036). If the exclusion restriction holds, opioid supply should not predict non-opioid SUD treatment demand. Controls: log population, poverty rate, uninsured rate. HC1 robust standard errors. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, "../tables/tab4_placebo.tex")

# =============================================================================
# Table 5: Robustness — Leave-One-Out + Specifications
# =============================================================================
cat("Generating Table 5: Robustness...\n")

loo <- robustness$loo

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Leave-One-Out and Alternative Specifications}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Coeff. & SE & $F$-stat & $N$ \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel A: Leave-one-out (dropping each triplicate state)}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(loo))) {
  tab5 <- c(tab5, sprintf("Drop %s & %s & %s & %.1f & %d \\\\",
                           loo$dropped[i],
                           fmt_coef(loo$coef[i], loo$se[i]),
                           fmt_se(loo$se[i]),
                           loo$f_stat[i],
                           nrow(df) - 1))
}

tab5 <- c(tab5,
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B: Alternative specifications}} \\\\",
  "\\addlinespace",
  sprintf("No controls & %s & %s & %.1f & %d \\\\",
          fmt_coef(robustness$iv_nocontrols$coef, robustness$iv_nocontrols$se),
          fmt_se(robustness$iv_nocontrols$se),
          robustness$iv_nocontrols$f_stat, nrow(df)),
  sprintf("Population only & %s & %s & %.1f & %d \\\\",
          fmt_coef(robustness$iv_pop$coef, robustness$iv_pop$se),
          fmt_se(robustness$iv_pop$se),
          robustness$iv_pop$f_stat, nrow(df)),
  sprintf("+ Medicaid expansion & %s & %s & %.1f & %d \\\\",
          fmt_coef(robustness$iv_expansion$coef, robustness$iv_expansion$se),
          fmt_se(robustness$iv_expansion$se),
          robustness$iv_expansion$f_stat, nrow(df)),
  sprintf("Anderson-Rubin $p$-value & \\multicolumn{4}{c}{$p = %.4f$} \\\\",
          robustness$ar_test$pval),
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications use IV/2SLS with triplicate state as instrument for log oxycodone per capita. Dependent variable: log MAT claims per 1,000 population. Panel A drops one triplicate state at a time. Panel B varies the control set. Anderson-Rubin test is weak-IV-robust. HC1 robust standard errors. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5, "../tables/tab5_robustness.tex")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# =============================================================================
cat("Generating Table F1: SDE...\n")

# Compute SDE for main outcomes
# SDE = β̂ × SD(X) / SD(Y) for continuous treatment (log-log)
# In log-log specification: SDE ≈ β̂ × SD(log X) / SD(log Y)
sd_x <- sd(df$log_oxy_pc, na.rm = TRUE)

# Main spec coefficients
beta_claims <- results$iv_controls$coef
se_claims <- results$iv_controls$se
sd_y_claims <- sd(df$log_mat_claims_pc, na.rm = TRUE)
sde_claims <- beta_claims * sd_x / sd_y_claims
se_sde_claims <- se_claims * sd_x / sd_y_claims

beta_bene <- results$iv_bene$coef
se_bene <- results$iv_bene$se
sd_y_bene <- sd(df$log_mat_bene_pc, na.rm = TRUE)
sde_bene <- beta_bene * sd_x / sd_y_bene
se_sde_bene <- se_bene * sd_x / sd_y_bene

beta_paid <- results$iv_paid$coef
se_paid <- results$iv_paid$se
sd_y_paid <- sd(df$log_mat_paid_pc, na.rm = TRUE)
sde_paid <- beta_paid * sd_x / sd_y_paid
se_sde_paid <- se_paid * sd_x / sd_y_paid

# Placebo
beta_placebo <- robustness$placebo_iv$coef
se_placebo <- robustness$placebo_iv$se
sd_y_placebo <- sd(df$log_nonopioid_claims_pc, na.rm = TRUE)
sde_placebo <- beta_placebo * sd_x / sd_y_placebo
se_sde_placebo <- se_placebo * sd_x / sd_y_placebo

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: Split by Medicaid expansion status
df_exp <- df |> filter(medicaid_expansion == 1)
df_noexp <- df |> filter(medicaid_expansion == 0)

# IV on expansion states only
iv_exp <- tryCatch({
  feols(log_mat_claims_pc ~ log_population + poverty_rate + uninsured_rate |
          log_oxy_pc ~ triplicate, data = df_exp, vcov = "HC1")
}, error = function(e) NULL)

iv_noexp <- tryCatch({
  feols(log_mat_claims_pc ~ log_population + poverty_rate + uninsured_rate |
          log_oxy_pc ~ triplicate, data = df_noexp, vcov = "HC1")
}, error = function(e) NULL)

make_sde_row <- function(outcome, beta, se, sd_y, sde, se_sde) {
  sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          outcome, beta, se, sd_y, sde, se_sde, classify_sde(sde))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does pharmaceutical opioid supply exposure (ARCOS pill shipments, 2006--2012) causally increase downstream Medicaid addiction treatment demand (T-MSIS MAT claims, 2018--2024)? ",
  "\\textbf{Policy mechanism:} Seven states adopted triplicate prescription programs before 1988, requiring carbon-copy prescriptions for Schedule~II drugs; Purdue Pharma subsequently under-marketed OxyContin in these states, creating persistent cross-state variation in opioid supply exposure that feeds into differential addiction treatment burdens decades later. ",
  "\\textbf{Outcome definition:} Log Medicaid MAT claims per 1,000 population, including methadone administration (H0020), buprenorphine injections (J0571--J0575), and naltrexone injections (J2315), averaged over 2018--2024. ",
  "\\textbf{Treatment:} Continuous; log average annual oxycodone pills per capita shipped via ARCOS (2006--2012). ",
  "\\textbf{Data:} DEA ARCOS pill shipments (2006--2012, state-level aggregates from county-annual data) and HHS T-MSIS Medicaid Provider Spending (2018--2024 monthly claims, geocoded via NPPES); cross-sectional analysis of 50 states plus DC. ",
  "\\textbf{Method:} IV/2SLS using pre-1988 triplicate prescription program adoption as instrument; HC1 robust standard errors. ",
  "\\textbf{Sample:} All 50 states and DC with non-missing ARCOS supply and T-MSIS MAT claims; 7 triplicate states provide identifying variation. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(\\log X) / \\text{SD}(\\log Y)$ for continuous treatment in log-log specification, ",
  "where SD is the cross-state standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace",
  make_sde_row("MAT claims per 1,000", beta_claims, se_claims, sd_y_claims, sde_claims, se_sde_claims),
  make_sde_row("MAT beneficiaries per 1,000", beta_bene, se_bene, sd_y_bene, sde_bene, se_sde_bene),
  make_sde_row("MAT spending per capita", beta_paid, se_paid, sd_y_paid, sde_paid, se_sde_paid),
  make_sde_row("Non-opioid SUD (placebo)", beta_placebo, se_placebo, sd_y_placebo, sde_placebo, se_sde_placebo),
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Medicaid expansion)}} \\\\",
  "\\addlinespace"
)

if (!is.null(iv_exp)) {
  beta_exp <- coef(iv_exp)["fit_log_oxy_pc"]
  se_exp <- sqrt(vcov(iv_exp)["fit_log_oxy_pc", "fit_log_oxy_pc"])
  sd_y_exp <- sd(df_exp$log_mat_claims_pc, na.rm = TRUE)
  sde_exp <- beta_exp * sd(df_exp$log_oxy_pc, na.rm = TRUE) / sd_y_exp
  se_sde_exp <- se_exp * sd(df_exp$log_oxy_pc, na.rm = TRUE) / sd_y_exp
  tabF1 <- c(tabF1, make_sde_row("Expansion states", beta_exp, se_exp, sd_y_exp, sde_exp, se_sde_exp))
} else {
  tabF1 <- c(tabF1, "Expansion states & \\multicolumn{6}{c}{Insufficient variation} \\\\")
}

if (!is.null(iv_noexp)) {
  beta_noexp <- coef(iv_noexp)["fit_log_oxy_pc"]
  se_noexp <- sqrt(vcov(iv_noexp)["fit_log_oxy_pc", "fit_log_oxy_pc"])
  sd_y_noexp <- sd(df_noexp$log_mat_claims_pc, na.rm = TRUE)
  sde_noexp <- beta_noexp * sd(df_noexp$log_oxy_pc, na.rm = TRUE) / sd_y_noexp
  se_sde_noexp <- se_noexp * sd(df_noexp$log_oxy_pc, na.rm = TRUE) / sd_y_noexp
  tabF1 <- c(tabF1, make_sde_row("Non-expansion states", beta_noexp, se_noexp, sd_y_noexp, sde_noexp, se_sde_noexp))
} else {
  tabF1 <- c(tabF1, "Non-expansion states & \\multicolumn{6}{c}{Insufficient variation} \\\\")
}

tabF1 <- c(tabF1,
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_first_stage.tex\n")
cat("  tables/tab3_iv_results.tex\n")
cat("  tables/tab4_placebo.tex\n")
cat("  tables/tab5_robustness.tex\n")
cat("  tables/tabF1_sde.tex\n")
