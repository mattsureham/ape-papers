# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# =============================================================================
source("00_packages.R")

panel <- read_csv("../data/panel_main.csv", show_col_types = FALSE)
panel_full <- read_csv("../data/panel_full.csv", show_col_types = FALSE)
load("../data/models.RData")
load("../data/robustness.RData")

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
sumstat <- panel %>%
  group_by(high_contam, drug_type) %>%
  summarise(
    mean_rate = mean(death_rate, na.rm = TRUE),
    sd_rate = sd(death_rate, na.rm = TRUE),
    min_rate = min(death_rate, na.rm = TRUE),
    max_rate = max(death_rate, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(high_contam), drug_type)

cat("Summary statistics:\n")
print(sumstat)

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Drug Overdose Death Rates by Drug Type}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llrrrr}\n",
  "\\toprule\n",
  "Category & Drug Type & Mean & Std.\\ Dev. & Min & Max \\\\\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: High-Contamination Drugs}} \\\\\n"
)

for (i in seq_len(nrow(sumstat))) {
  row <- sumstat[i, ]
  if (i == sum(sumstat$high_contam == 1) + 1) {
    tab1_tex <- paste0(tab1_tex,
      "\\midrule\n",
      "\\multicolumn{6}{l}{\\textit{Panel B: Low-Contamination Drugs}} \\\\\n"
    )
  }
  label <- ifelse(row$high_contam == 1, "High", "Low")
  drug_label <- gsub("_", " ", row$drug_type)
  tab1_tex <- paste0(tab1_tex,
    label, " & ", drug_label, " & ",
    sprintf("%.2f", row$mean_rate), " & ",
    sprintf("%.2f", row$sd_rate), " & ",
    sprintf("%.2f", row$min_rate), " & ",
    sprintf("%.2f", row$max_rate), " \\\\\n"
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Death rates per 100,000 population. N = ",
  format(nrow(panel), big.mark = ","), " state-year-drug observations across ",
  length(unique(panel$state_name)), " states and ",
  length(unique(panel$year)), " years (2015--2023). ",
  "High-contamination drugs (cocaine, heroin) face significant fentanyl adulteration risk in illicit markets. ",
  "Low-contamination drugs (methadone, natural/semi-synthetic opioids) are primarily obtained through clinical or pharmaceutical channels.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: Main DDD Results
# =============================================================================
tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Triple-Difference Estimates: Effect of FTS Legalization on Drug Overdose Death Rates}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Baseline & Incl.\\ Synthetics \\\\\n",
  "\\midrule\n",
  "Post $\\times$ High-Contam & ",
  sprintf("%.3f", coef(m1)["post_x_high"]),
  ifelse(abs(coef(m1)["post_x_high"] / se(m1)["post_x_high"]) > 2.576, "\\sym{***}",
    ifelse(abs(coef(m1)["post_x_high"] / se(m1)["post_x_high"]) > 1.96, "\\sym{**}",
      ifelse(abs(coef(m1)["post_x_high"] / se(m1)["post_x_high"]) > 1.645, "\\sym{*}", ""))),
  " & ",
  sprintf("%.3f", coef(m3)["post_x_high"]),
  ifelse(abs(coef(m3)["post_x_high"] / se(m3)["post_x_high"]) > 2.576, "\\sym{***}",
    ifelse(abs(coef(m3)["post_x_high"] / se(m3)["post_x_high"]) > 1.96, "\\sym{**}",
      ifelse(abs(coef(m3)["post_x_high"] / se(m3)["post_x_high"]) > 1.645, "\\sym{*}", ""))),
  " \\\\\n",
  " & (", sprintf("%.3f", se(m1)["post_x_high"]), ") & (",
  sprintf("%.3f", se(m3)["post_x_high"]), ") \\\\\n",
  "\\midrule\n",
  "State $\\times$ Drug FE & Yes & Yes \\\\\n",
  "Drug $\\times$ Year FE & Yes & Yes \\\\\n",
  "State $\\times$ Year FE & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(m1), big.mark = ","),
  " & ", format(nobs(m3), big.mark = ","), " \\\\\n",
  "High-contam drugs & Cocaine, Heroin & + Synth.\\ Opioids \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Outcome is the annual overdose death rate per 100,000 population. ",
  "The coefficient on Post $\\times$ High-Contam is the triple-difference estimand: ",
  "the differential effect of FTS legalization on high-contamination drug deaths ",
  "(cocaine, heroin) relative to low-contamination drug deaths (methadone, natural opioids), ",
  "after absorbing all state-level and drug-type-level trends.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# =============================================================================
# TABLE 3: Drug-Specific Effects
# =============================================================================
drug_models <- list(
  "Heroin" = m2_heroin,
  "Cocaine" = m2_cocaine,
  "Methadone" = m2_methadone,
  "Nat. Opioids" = m2_natopi
)

get_stars <- function(t_val) {
  if (abs(t_val) > 2.576) return("\\sym{***}")
  if (abs(t_val) > 1.96) return("\\sym{**}")
  if (abs(t_val) > 1.645) return("\\sym{*}")
  return("")
}

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Drug-Specific Effects of FTS Legalization on Overdose Death Rates}\n",
  "\\label{tab:drugspec}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Heroin & Cocaine & Methadone & Nat.\\ Opioids \\\\\n",
  " & \\textit{High} & \\textit{High} & \\textit{Low} & \\textit{Low} \\\\\n",
  "\\midrule\n",
  "Post FTS & "
)

for (i in seq_along(drug_models)) {
  m <- drug_models[[i]]
  b <- coef(m)["post_fts"]
  s <- se(m)["post_fts"]
  t_val <- b / s
  tab3_tex <- paste0(tab3_tex,
    sprintf("%.3f", b), get_stars(t_val),
    ifelse(i < length(drug_models), " & ", " \\\\\n")
  )
}

tab3_tex <- paste0(tab3_tex, " & ")
for (i in seq_along(drug_models)) {
  m <- drug_models[[i]]
  s <- se(m)["post_fts"]
  tab3_tex <- paste0(tab3_tex,
    "(", sprintf("%.3f", s), ")",
    ifelse(i < length(drug_models), " & ", " \\\\\n")
  )
}

tab3_tex <- paste0(tab3_tex,
  "\\midrule\n",
  "State FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n"
)

# Add N for each
tab3_tex <- paste0(tab3_tex, "Observations & ")
for (i in seq_along(drug_models)) {
  m <- drug_models[[i]]
  tab3_tex <- paste0(tab3_tex,
    format(nobs(m), big.mark = ","),
    ifelse(i < length(drug_models), " & ", " \\\\\n")
  )
}

tab3_tex <- paste0(tab3_tex,
  "Contamination risk & High & High & Low & Low \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column is a separate two-way FE regression of drug-specific death rates ",
  "on a post-FTS indicator. Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "High-contamination drugs face fentanyl adulteration risk; low-contamination drugs do not.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_drugspec.tex")

# =============================================================================
# TABLE 4: Robustness Checks
# =============================================================================
tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness: Alternative Specifications and Inference}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & State$\\times$Drug & Log Deaths & Psych.\\ Placebo \\\\\n",
  " & Clustering & & \\\\\n",
  "\\midrule\n",
  "Post $\\times$ High-Contam & ",
  sprintf("%.3f", coef(r1)["post_x_high"]),
  get_stars(coef(r1)["post_x_high"] / se(r1)["post_x_high"]),
  " & ",
  sprintf("%.3f", coef(r2)["post_x_high"]),
  get_stars(coef(r2)["post_x_high"] / se(r2)["post_x_high"]),
  " & \\\\\n",
  " & (", sprintf("%.3f", se(r1)["post_x_high"]), ") & (",
  sprintf("%.3f", se(r2)["post_x_high"]), ") & \\\\\n",
  "Post FTS & & & ",
  sprintf("%.3f", coef(r5)["post_fts"]),
  get_stars(coef(r5)["post_fts"] / se(r5)["post_fts"]),
  " \\\\\n",
  " & & & (", sprintf("%.3f", se(r5)["post_fts"]), ") \\\\\n",
  "\\midrule\n",
  "RI $p$-value & & & \\\\\n",
  "\\quad (500 permutations) & \\multicolumn{2}{c}{",
  sprintf("%.3f", ri_pvalue), "} & \\\\\n",
  "LOO range & \\multicolumn{2}{c}{[",
  sprintf("%.3f", min(loo_results$beta)), ", ",
  sprintf("%.3f", max(loo_results$beta)), "]} & \\\\\n",
  "\\midrule\n",
  "Observations & ", format(nobs(r1), big.mark = ","),
  " & ", format(nobs(r2), big.mark = ","),
  " & ", format(nobs(r5), big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) clusters standard errors at the state$\\times$drug level. ",
  "Column (2) uses log deaths as the outcome (dropping zero-death observations). ",
  "Column (3) estimates the effect of FTS legalization on psychostimulant deaths ",
  "(methamphetamine, MDMA) --- a drug class with intermediate fentanyl contamination risk. ",
  "RI $p$-value reports the two-sided randomization inference $p$-value from 500 permutations ",
  "of FTS treatment timing across states. LOO range shows the range of the DDD coefficient ",
  "when each state is excluded one at a time.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robust.tex")

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY
# =============================================================================
sd_y_all <- sd(panel$death_rate, na.rm = TRUE)

# Panel A: Pooled DDD
beta_pool <- coef(m1)["post_x_high"]
se_pool <- se(m1)["post_x_high"]
sde_pool <- beta_pool / sd_y_all
se_sde_pool <- se_pool / sd_y_all

# Panel B: Heterogeneous — split by drug type
# Heroin
beta_her <- coef(m2_heroin)["post_fts"]
se_her <- se(m2_heroin)["post_fts"]
sd_y_her <- sd(panel$death_rate[panel$drug_type == "Heroin"], na.rm = TRUE)
sde_her <- beta_her / sd_y_her
se_sde_her <- se_her / sd_y_her

# Cocaine
beta_coc <- coef(m2_cocaine)["post_fts"]
se_coc <- se(m2_cocaine)["post_fts"]
sd_y_coc <- sd(panel$death_rate[panel$drug_type == "Cocaine"], na.rm = TRUE)
sde_coc <- beta_coc / sd_y_coc
se_sde_coc <- se_coc / sd_y_coc

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether state legalization of fentanyl test strips reduces drug overdose mortality differentially across drug types with varying fentanyl contamination risk. ",
  "\\textbf{Policy mechanism:} FTS legalization exempts fentanyl test strips from drug paraphernalia laws, enabling users to test illicit drugs for fentanyl contamination before consumption and potentially adjust dosing, discard contaminated drugs, or use with naloxone on hand. ",
  "\\textbf{Outcome definition:} Annual drug-specific overdose death rate per 100,000 population, from CDC VSRR provisional drug overdose death counts by ICD-10 T-code. ",
  "\\textbf{Treatment:} Binary: state legalized FTS (1) vs.\\ not yet legalized (0). ",
  "\\textbf{Data:} CDC VSRR Provisional Drug Overdose Deaths, 2015--2023, state-year-drug type panel. ",
  "\\textbf{Method:} Triple-difference (state $\\times$ drug type $\\times$ time) with state-drug, drug-year, and state-year fixed effects; state-clustered standard errors. ",
  "\\textbf{Sample:} All 50 states and DC, four drug types (heroin, cocaine, methadone, natural opioids), restricted to state-year-drug observations with at least 6 months of reported data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of the drug-specific death rate. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Death rate (DDD) & Post $\\times$ HighContam & ",
  sprintf("%.3f", beta_pool), " & ",
  sprintf("%.3f", sd_y_all), " & ",
  sprintf("%.4f", sde_pool), " & ",
  sprintf("%.4f", se_sde_pool), " & ",
  classify(sde_pool), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by drug type)}} \\\\\n",
  "Heroin deaths & Post FTS & ",
  sprintf("%.3f", beta_her), " & ",
  sprintf("%.3f", sd_y_her), " & ",
  sprintf("%.4f", sde_her), " & ",
  sprintf("%.4f", se_sde_her), " & ",
  classify(sde_her), " \\\\\n",
  "Cocaine deaths & Post FTS & ",
  sprintf("%.3f", beta_coc), " & ",
  sprintf("%.3f", sd_y_coc), " & ",
  sprintf("%.4f", sde_coc), " & ",
  sprintf("%.4f", se_sde_coc), " & ",
  classify(sde_coc), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables written to tables/\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_drugspec.tex\n")
cat("  tab4_robust.tex\n")
cat("  tabF1_sde.tex\n")
