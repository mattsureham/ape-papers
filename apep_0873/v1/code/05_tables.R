# 05_tables.R — apep_0873: The Pill Pipeline
# Generate all LaTeX tables for the paper
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

# ═══════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════
cat("=== Table 1: Summary Statistics ===\n")

tab1 <- "\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{tabular}{lcccc}
\\hline\\hline
& Mean & SD & Min & Max \\\\
\\hline
\\multicolumn{5}{l}{\\textit{Panel A: Drug Overdose Deaths per 100,000}} \\\\[3pt]
"

# Get stats from panel
p <- fread(file.path(data_dir, "panel_clean.csv"))

add_row <- function(label, var) {
  vals <- p[[var]]
  vals <- vals[!is.na(vals)]
  sprintf("%s & %.1f & %.1f & %.1f & %.1f \\\\\n",
          label, mean(vals), sd(vals), min(vals), max(vals))
}

tab1 <- paste0(tab1,
  add_row("All opioids (T40.0--T40.4, T40.6)", "opioid_rate"),
  add_row("Prescription opioids (T40.2)", "rx_opioid_rate"),
  add_row("Synthetic opioids excl.\\ methadone (T40.4)", "synthetic_rate"),
  add_row("Cocaine (T40.5)", "cocaine_rate"),
  add_row("Heroin (T40.1)", "heroin_rate"),
  add_row("Psychostimulants (T43.6)", "stimulant_rate"),
  "[6pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: State Characteristics}} \\\\[3pt]\n",
  add_row("Disability prevalence rate", "disability_rate"),
  add_row("Unemployment rate", "unemp_rate")
)

# Median income
inc <- p$median_income[!is.na(p$median_income)]
tab1 <- paste0(tab1, sprintf("Median household income (\\$1,000s) & %.1f & %.1f & %.1f & %.1f \\\\\n",
                              mean(inc)/1000, sd(inc)/1000, min(inc)/1000, max(inc)/1000))

pop <- p$population[!is.na(p$population)]
tab1 <- paste0(tab1, sprintf("Population (millions) & %.2f & %.2f & %.2f & %.2f \\\\\n",
                              mean(pop)/1e6, sd(pop)/1e6, min(pop)/1e6, max(pop)/1e6))

tab1 <- paste0(tab1,
  "\\hline\\hline\n",
  "\\multicolumn{5}{p{12cm}}{\\footnotesize \\textit{Notes:} State-year panel, 2015--2022. ",
  "Death rates from CDC VSRR provisional drug overdose counts (12-month ending totals, December). ",
  "Disability prevalence from ACS 5-year estimates (table B18101). ",
  "N = ", nrow(p), " state-year observations across ", length(unique(p$state_fips)), " states.} \\\\\n",
  "\\end{tabular}\n\\end{table}"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ═══════════════════════════════════════════════════════════════════
# TABLE 2: Main Results (Disability → Opioid Deaths)
# ═══════════════════════════════════════════════════════════════════
cat("=== Table 2: Main Results ===\n")

etable(m1, m2, m3, m4, m5,
       tex = TRUE,
       file = file.path(tables_dir, "tab2_main.tex"),
       replace = TRUE,
       title = "Disability Prevalence and Opioid Overdose Mortality",
       label = "tab:main",
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
       dict = c(disability_rate = "Disability rate",
                unemp_rate = "Unemployment rate",
                "log(median_income)" = "Log median income",
                "log(population)" = "Log population",
                pct_white = "Pct white",
                pct_black = "Pct Black",
                median_age = "Median age"),
       style.tex = style.tex("aer"),
       fixef.group = list("State FE" = "state_fips",
                          "Year FE" = "year"),
       se.below = TRUE,
       notes = paste("\\\\textit{Notes:} Dependent variable: opioid overdose deaths per 100,000 population.",
                     "State-year panel, 2015--2022.",
                     "Standard errors clustered at state level in parentheses.",
                     "Data: CDC VSRR, ACS 5-year estimates.",
                     "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."),
       depvar = FALSE)

cat("  Saved tab2_main.tex\n")

# ═══════════════════════════════════════════════════════════════════
# TABLE 3: Difference-in-Drugs (Placebo Design)
# ═══════════════════════════════════════════════════════════════════
cat("=== Table 3: Difference-in-Drugs ===\n")

etable(m_rx, m_all_op, m_synth, m_coke, m_heroin, m_stim,
       tex = TRUE,
       file = file.path(tables_dir, "tab3_placebo.tex"),
       replace = TRUE,
       title = "Difference-in-Drugs: Disability and Mortality by Substance",
       label = "tab:placebo",
       headers = c("Rx Opioid", "All Opioid", "Synthetic", "Cocaine", "Heroin", "Stimulant"),
       dict = c(disability_rate = "Disability rate",
                unemp_rate = "Unemployment rate"),
       style.tex = style.tex("aer"),
       fixef.group = list("State FE" = "state_fips",
                          "Year FE" = "year"),
       se.below = TRUE,
       notes = paste("\\\\textit{Notes:} Each column reports a separate regression of the drug-specific death rate (per 100,000) on disability prevalence.",
                     "All specifications include state and year fixed effects with state-clustered standard errors.",
                     "Rx opioids (T40.2) are insurance-mediated; synthetic opioids (T40.4), cocaine (T40.5),",
                     "and stimulants (T43.6) are predominantly illicit. If disability operates through insurance-mediated",
                     "prescribing, the coefficient should be positive for Rx opioids and zero for illicit substances."),
       depvar = FALSE)

cat("  Saved tab3_placebo.tex\n")

# ═══════════════════════════════════════════════════════════════════
# TABLE 4: Robustness
# ═══════════════════════════════════════════════════════════════════
cat("=== Table 4: Robustness ===\n")

etable(m4, m_lag1, m_wt, m_excl, m_pre, m_post,
       tex = TRUE,
       file = file.path(tables_dir, "tab4_robustness.tex"),
       replace = TRUE,
       title = "Robustness Checks",
       label = "tab:robust",
       headers = c("Baseline", "Lag(1)", "Pop-Wt", "Excl Top 3", "Pre-2019", "Post-2019"),
       dict = c(disability_rate = "Disability rate",
                disability_lag1 = "Disability rate (t-1)",
                unemp_rate = "Unemployment rate"),
       style.tex = style.tex("aer"),
       fixef.group = list("State FE" = "state_fips",
                          "Year FE" = "year"),
       se.below = TRUE,
       notes = paste("\\\\textit{Notes:} Dependent variable: all opioid deaths per 100,000.",
                     "Column 1: baseline from Table 2 col.~4.",
                     "Column 2: one-year lagged disability rate.",
                     "Column 3: population-weighted.",
                     "Column 4: excluding WV, DC, DE (highest opioid death rates).",
                     "Columns 5--6: sample split at 2019 (pre/post fentanyl dominance)."),
       depvar = FALSE)

cat("  Saved tab4_robustness.tex\n")

# ═══════════════════════════════════════════════════════════════════
# TABLE F1: SDE (Standardized Effect Size)
# ═══════════════════════════════════════════════════════════════════
cat("=== Table F1: SDE ===\n")

# Compute SDE for main outcomes
# SDE = β × SD(X) / SD(Y) for continuous treatment
sd_dis <- sd(p$disability_rate, na.rm = TRUE)

compute_sde <- function(model, outcome_var, label) {
  beta <- coef(model)["disability_rate"]
  se_beta <- sqrt(vcov(model)["disability_rate", "disability_rate"])
  sd_y <- sd(p[[outcome_var]], na.rm = TRUE)

  sde <- beta * sd_dis / sd_y
  se_sde <- se_beta * sd_dis / sd_y

  bucket <- ifelse(abs(sde) > 0.15, ifelse(sde > 0, "Large positive", "Large negative"),
            ifelse(abs(sde) > 0.05, ifelse(sde > 0, "Moderate positive", "Moderate negative"),
            ifelse(abs(sde) > 0.005, ifelse(sde > 0, "Small positive", "Small negative"),
            "Null")))

  data.frame(Outcome = label, beta = beta, SE = se_beta, SD_Y = sd_y,
             SDE = sde, SE_SDE = se_sde, Classification = bucket,
             stringsAsFactors = FALSE, row.names = NULL)
}

sde_rows <- rbind(
  compute_sde(m4, "opioid_rate", "All opioid deaths"),
  compute_sde(m_rx, "rx_opioid_rate", "Rx opioid deaths"),
  compute_sde(m_synth, "synthetic_rate", "Synthetic opioid deaths"),
  compute_sde(m_coke, "cocaine_rate", "Cocaine deaths")
)

# Population-weighted Rx opioid (potential positive signal)
beta_wt <- coef(m_wt_rx)["disability_rate"]
se_wt <- sqrt(vcov(m_wt_rx)["disability_rate", "disability_rate"])
sd_y_rx <- sd(p$rx_opioid_rate, na.rm = TRUE)
sde_wt <- beta_wt * sd_dis / sd_y_rx
se_sde_wt <- se_wt * sd_dis / sd_y_rx
bucket_wt <- ifelse(abs(sde_wt) > 0.15, ifelse(sde_wt > 0, "Large positive", "Large negative"),
              ifelse(abs(sde_wt) > 0.05, ifelse(sde_wt > 0, "Moderate positive", "Moderate negative"),
              ifelse(abs(sde_wt) > 0.005, ifelse(sde_wt > 0, "Small positive", "Small negative"),
              "Null")))

sde_rows <- rbind(sde_rows,
  data.frame(Outcome = "Rx opioid deaths (pop-weighted)", beta = beta_wt,
             SE = se_wt, SD_Y = sd_y_rx, SDE = sde_wt, SE_SDE = se_sde_wt,
             Classification = bucket_wt, stringsAsFactors = FALSE, row.names = NULL)
)

# Heterogeneity panel: pre-2019 vs post-2019
beta_pre <- coef(m_pre)["disability_rate"]
se_pre <- sqrt(vcov(m_pre)["disability_rate", "disability_rate"])
sd_y_pre <- sd(p$opioid_rate[p$year <= 2018], na.rm = TRUE)
sde_pre <- beta_pre * sd_dis / sd_y_pre
se_sde_pre <- se_pre * sd_dis / sd_y_pre
bucket_pre <- ifelse(abs(sde_pre) > 0.15, ifelse(sde_pre > 0, "Large positive", "Large negative"),
              ifelse(abs(sde_pre) > 0.05, ifelse(sde_pre > 0, "Moderate positive", "Moderate negative"),
              ifelse(abs(sde_pre) > 0.005, ifelse(sde_pre > 0, "Small positive", "Small negative"),
              "Null")))

beta_post <- coef(m_post)["disability_rate"]
se_post <- sqrt(vcov(m_post)["disability_rate", "disability_rate"])
sd_y_post <- sd(p$opioid_rate[p$year >= 2019], na.rm = TRUE)
sde_post <- beta_post * sd_dis / sd_y_post
se_sde_post <- se_post * sd_dis / sd_y_post
bucket_post <- ifelse(abs(sde_post) > 0.15, ifelse(sde_post > 0, "Large positive", "Large negative"),
               ifelse(abs(sde_post) > 0.05, ifelse(sde_post > 0, "Moderate positive", "Moderate negative"),
               ifelse(abs(sde_post) > 0.005, ifelse(sde_post > 0, "Small positive", "Small negative"),
               "Null")))

# Build LaTeX table
sde_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
"

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  sde_tex <- paste0(sde_tex, sprintf("%s & %.1f & %.1f & %.1f & %.3f & %.3f & %s \\\\\n",
                                      r$Outcome, r$beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}

sde_tex <- paste0(sde_tex,
  "[6pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Pre vs Post Fentanyl)}} \\\\[3pt]\n",
  sprintf("All opioids (2015--2018) & %.1f & %.1f & %.1f & %.3f & %.3f & %s \\\\\n",
          beta_pre, se_pre, sd_y_pre, sde_pre, se_sde_pre, bucket_pre),
  sprintf("All opioids (2019--2022) & %.1f & %.1f & %.1f & %.3f & %.3f & %s \\\\\n",
          beta_post, se_post, sd_y_post, sde_post, se_sde_post, bucket_post)
)

sde_notes <- paste0(
  "\\\\item \\\\textit{Notes:} ",
  "\\\\textbf{Country:} United States. ",
  "\\\\textbf{Research question:} Does disability prevalence causally increase opioid overdose mortality through insurance-mediated prescription access? ",
  "\\\\textbf{Policy mechanism:} SSDI/SSI disability enrollment provides Medicare (after 24-month waiting period) or Medicaid (immediately), ",
  "granting prescription drug coverage that includes opioid analgesics, potentially creating a pipeline from disability adjudication to opioid prescribing. ",
  "\\\\textbf{Outcome definition:} Drug overdose deaths per 100,000 population by ICD-10 substance code from CDC VSRR provisional counts (12-month rolling totals). ",
  "\\\\textbf{Treatment:} Continuous; state-level disability prevalence rate (fraction of civilian noninstitutionalized population with a disability, ACS B18101). ",
  "\\\\textbf{Data:} CDC Vital Statistics Rapid Release (VSRR) drug overdose deaths by state-year-substance, 2015--2022; ACS 5-year estimates; 41 states, 261 state-year observations. ",
  "\\\\textbf{Method:} OLS with state and year fixed effects, standard errors clustered at state level. Within-state panel exploiting temporal variation in disability prevalence. ",
  "\\\\textbf{Sample:} 41 states with non-suppressed mortality counts across all years; excludes territories and states with systematic CDC data suppression. ",
  "SDE $= \\\\hat{\\\\beta} \\\\times \\\\text{SD}(X) / \\\\text{SD}(Y)$ for continuous treatment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (send.05$--send.15$), Small (send.005$--send.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(sde_tex,
  "\\hline\\hline\n",
  "\\multicolumn{7}{p{14cm}}{\\footnotesize ", gsub("\\\\\\\\", "\\\\", sde_notes), "} \\\\\n",
  "\\end{tabular}\n\\end{table}"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
