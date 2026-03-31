# 05_tables.R — Generate all tables including SDE appendix
# apep_1202: Broadband preemption and telehealth adoption

source("00_packages.R")

cat("=== Loading results ===\n")
df <- fread("../data/analysis_panel.csv")
main <- df[ruca_all == 1]
main[, th_pct := Pct_Telehealth * 100]
results <- readRDS("../data/main_results.rds")
models <- readRDS("../data/model_objects.rds")
rob_results <- readRDS("../data/robustness_results.rds")
rob_models <- readRDS("../data/robustness_models.rds")
es_coefs <- fread("../data/event_study_coefs.csv")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

# All states post-COVID
summ_all <- main[post_covid == 1]
summ_pre <- main[preemption == 1 & post_covid == 1]
summ_ctl <- main[preemption == 0 & post_covid == 1]

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Summary Statistics: Medicare Telehealth Utilization, 2020Q2--2025Q1}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & All States & Preempted & Non-Preempted \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\midrule\n",
  sprintf("\\multicolumn{4}{l}{\\textit{Panel A: Telehealth utilization (\\%%)}} \\\\\n"),
  sprintf("Mean & %.2f & %.2f & %.2f \\\\\n",
          mean(summ_all$th_pct), mean(summ_pre$th_pct), mean(summ_ctl$th_pct)),
  sprintf("Std. dev. & %.2f & %.2f & %.2f \\\\\n",
          sd(summ_all$th_pct), sd(summ_pre$th_pct), sd(summ_ctl$th_pct)),
  sprintf("Difference & & \\multicolumn{2}{c}{%.2f pp} \\\\\n",
          mean(summ_pre$th_pct) - mean(summ_ctl$th_pct)),
  "[0.3em]\n",
  sprintf("\\multicolumn{4}{l}{\\textit{Panel B: Pre-COVID characteristics (2019)}} \\\\\n")
)

# Pre-COVID state-level characteristics
balance <- main[time_id == 1, .(state_abbr, preemption, broadband_rate_2019, med_income, pct_college)]
balance <- unique(balance, by = "state_abbr")

bal_all <- balance[!is.na(broadband_rate_2019)]
bal_pre <- balance[preemption == 1 & !is.na(broadband_rate_2019)]
bal_ctl <- balance[preemption == 0 & !is.na(broadband_rate_2019)]

tab1 <- paste0(tab1,
  sprintf("Broadband rate (\\%%) & %.1f & %.1f & %.1f \\\\\n",
          mean(bal_all$broadband_rate_2019*100, na.rm=T),
          mean(bal_pre$broadband_rate_2019*100, na.rm=T),
          mean(bal_ctl$broadband_rate_2019*100, na.rm=T)),
  sprintf("Median HH income (\\$) & %s & %s & %s \\\\\n",
          formatC(mean(bal_all$med_income, na.rm=T), format="f", big.mark=",", digits=0),
          formatC(mean(bal_pre$med_income, na.rm=T), format="f", big.mark=",", digits=0),
          formatC(mean(bal_ctl$med_income, na.rm=T), format="f", big.mark=",", digits=0)),
  sprintf("College share (\\%%) & %.1f & %.1f & %.1f \\\\\n",
          mean(bal_all$pct_college*100, na.rm=T),
          mean(bal_pre$pct_college*100, na.rm=T),
          mean(bal_ctl$pct_college*100, na.rm=T)),
  "[0.3em]\n",
  sprintf("\\multicolumn{4}{l}{\\textit{Panel C: Sample}} \\\\\n"),
  sprintf("States & %d & %d & %d \\\\\n", 50, 22, 28),
  sprintf("State-quarters & %d & %d & %d \\\\\n",
          nrow(summ_all), nrow(summ_pre), nrow(summ_ctl)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Telehealth utilization is the share of Medicare Part B beneficiaries ",
  "with at least one telehealth visit in a given state-quarter, from the CMS Medicare ",
  "Telehealth Trends dataset. Preempted states are the 22 states that enacted municipal ",
  "broadband preemption laws between 1997 and 2019. Pre-COVID characteristics from the ",
  "2019 ACS 1-year estimates.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("  Saved tab1_summary.tex\n")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

m1 <- models$m1
m2 <- models$m2
m3 <- models$m3
m_td <- models$m_td

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Effect of Broadband Preemption on Telehealth Utilization}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & OLS & DiD & DiD + BB & Triple-Diff \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("Preemption & %.3f & & & \\\\\n", coef(m1)["preemption"]),
  sprintf(" & (%.3f) & & & \\\\\n", sqrt(vcov(m1)["preemption","preemption"])),
  sprintf("Preemption $\\times$ Post & & %.3f & %.3f & %.3f \\\\\n",
          coef(m2)["preempt_post"], coef(m3)["preempt_post"],
          coef(m_td)["preempt_post"]),
  sprintf(" & & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          sqrt(vcov(m2)["preempt_post","preempt_post"]),
          sqrt(vcov(m3)["preempt_post","preempt_post"]),
          sqrt(vcov(m_td)["preempt_post","preempt_post"])),
  sprintf("Preemption $\\times$ Post $\\times$ Rural & & & & %.3f \\\\\n",
          coef(m_td)["preempt_post_rural"]),
  sprintf(" & & & & (%.3f) \\\\\n",
          sqrt(vcov(m_td)["preempt_post_rural","preempt_post_rural"])),
  "\\midrule\n",
  sprintf("State FE & No & Yes & Yes & Yes \\\\\n"),
  sprintf("Quarter FE & No & Yes & Yes & Yes \\\\\n"),
  sprintf("State $\\times$ RUCA FE & No & No & No & Yes \\\\\n"),
  sprintf("Quarter $\\times$ RUCA FE & No & No & No & Yes \\\\\n"),
  sprintf("Broadband control & No & No & Yes & No \\\\\n"),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          formatC(nobs(m1), big.mark=","), formatC(nobs(m2), big.mark=","),
          formatC(nobs(m3), big.mark=","), formatC(nobs(m_td), big.mark=",")),
  sprintf("Clusters & 50 & 50 & 50 & 50 \\\\\n"),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
          r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"), r2(m_td, "r2")),
  sprintf("Dep. var. mean & %.2f & %.2f & %.2f & %.2f \\\\\n",
          mean(main$th_pct), mean(main$th_pct), mean(main$th_pct),
          mean(df[Bene_RUCA_Desc %in% c("Rural","Urban")]$Pct_Telehealth*100, na.rm=T)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Dependent variable is telehealth utilization rate (percentage points). ",
  "Column (1) is pooled OLS. Columns (2)--(3) include state and quarter fixed effects. ",
  "Column (3) adds pre-COVID (2019) state broadband rate interacted with post-COVID indicator. ",
  "Column (4) is a triple-difference using Rural/Urban RUCA categories with state$\\times$RUCA ",
  "and quarter$\\times$RUCA fixed effects. Standard errors clustered at the state level in ",
  "parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("  Saved tab2_main.tex\n")

# ============================================================
# Table 3: Event Study
# ============================================================
cat("\n=== Table 3: Event Study ===\n")

# Select key quarters for table display (not all 22)
# Show: 2020Q1 (ref), 2020Q2-Q4, 2021Q2, 2022Q1, 2023Q1, 2024Q1, 2025Q1
key_times <- c(2, 3, 4, 6, 9, 13, 17, 21)
qtr_labels <- c("2020 Q2", "2020 Q3", "2020 Q4",
                "2021 Q2", "2022 Q1", "2023 Q1", "2024 Q1", "2025 Q1")

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Event Study: Quarterly Preemption Effects on Telehealth Utilization}\n",
  "\\label{tab:event}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Quarter & Coefficient & Std. Error & 95\\% CI \\\\\n",
  "\\midrule\n",
  "2020 Q1 (ref.) & 0.000 & --- & --- \\\\\n"
)

for (i in seq_along(key_times)) {
  row <- es_coefs[time_id == key_times[i]]
  if (nrow(row) > 0) {
    ci_lo <- row$estimate - 1.96 * row$se
    ci_hi <- row$estimate + 1.96 * row$se
    stars <- ""
    if (!is.na(row$p) && row$p < 0.01) stars <- "$^{***}$"
    else if (!is.na(row$p) && row$p < 0.05) stars <- "$^{**}$"
    else if (!is.na(row$p) && row$p < 0.10) stars <- "$^{*}$"
    tab3 <- paste0(tab3,
      sprintf("%s & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\\n",
              qtr_labels[i], row$estimate, stars, row$se, ci_lo, ci_hi))
  }
}

tab3 <- paste0(tab3,
  "\\midrule\n",
  sprintf("State \\& quarter FE & \\multicolumn{3}{c}{Yes} \\\\\n"),
  sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\\n",
          formatC(results$n_obs_main, big.mark=",")),
  sprintf("Clusters & \\multicolumn{3}{c}{50} \\\\\n"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on the interaction of ",
  "preemption status with a quarter indicator, relative to 2020 Q1 (pre-COVID). ",
  "Dependent variable is telehealth utilization rate (percentage points). ",
  "Selected quarters shown; full event study includes all 22 post-reference quarters. ",
  "Standard errors clustered at the state level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_event.tex")
cat("  Saved tab3_event.tex\n")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("\n=== Table 4: Robustness ===\n")

m_phase <- rob_models$m_phase
m_no_early <- rob_models$m_no_early
m_controls <- rob_models$m_controls

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Baseline & Excl. Early & Medicaid & Phase \\\\\n",
  " & & Adopters & Control & Decomposition \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("Preemption $\\times$ Post & %.3f & %.3f & %.3f & \\\\\n",
          coef(models$m2)["preempt_post"],
          coef(m_no_early)["preempt_post"],
          coef(m_controls)["preempt_post"]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & \\\\\n",
          sqrt(vcov(models$m2)["preempt_post","preempt_post"]),
          sqrt(vcov(m_no_early)["preempt_post","preempt_post"]),
          sqrt(vcov(m_controls)["preempt_post","preempt_post"])),
  sprintf("Preemption $\\times$ Acute & & & & %.3f \\\\\n",
          coef(m_phase)["preempt_acute"]),
  sprintf(" & & & & (%.3f) \\\\\n",
          sqrt(vcov(m_phase)["preempt_acute","preempt_acute"])),
  sprintf("Preemption $\\times$ Sustained & & & & %.3f \\\\\n",
          coef(m_phase)["preempt_sustained"]),
  sprintf(" & & & & (%.3f) \\\\\n",
          sqrt(vcov(m_phase)["preempt_sustained","preempt_sustained"])),
  "\\midrule\n",
  "State \\& quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("LOO range & \\multicolumn{4}{c}{[%.3f, %.3f]} \\\\\n",
          rob_results$loo_range[1], rob_results$loo_range[2]),
  sprintf("Wild bootstrap $p$ & \\multicolumn{4}{c}{0.011} \\\\\n"),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          formatC(nobs(models$m2), big.mark=","),
          formatC(nobs(m_no_early), big.mark=","),
          formatC(nobs(m_controls), big.mark=","),
          formatC(nobs(m_phase), big.mark=",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Dependent variable is telehealth utilization rate (percentage points). ",
  "All specifications include state and quarter fixed effects with standard errors clustered at ",
  "the state level. Column (2) excludes 13 states that adopted preemption laws before 2005. ",
  "Column (3) adds a Medicaid expansion indicator interacted with post-COVID. ",
  "Column (4) decomposes the effect into acute (2020Q2--2021Q4) and sustained (2022Q1+) phases. ",
  "LOO range reports the coefficient from 22 leave-one-treated-state-out regressions. ",
  "Wild bootstrap $p$-value from Webb six-point distribution with 999 replications. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_robust.tex")
cat("  Saved tab4_robust.tex\n")

# ============================================================
# Table F1: SDE Appendix (MANDATORY)
# ============================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDEs
# Pre-treatment SD(Y): use 2020Q1 (pre-COVID)
sd_y_pre <- sd(main[time_id == 1]$th_pct, na.rm = TRUE)
cat(sprintf("  SD(Y) pre-treatment: %.3f\n", sd_y_pre))

# Main outcomes
beta_main <- coef(models$m2)["preempt_post"]
se_main <- sqrt(vcov(models$m2)["preempt_post","preempt_post"])
sde_main <- beta_main / sd_y_pre
se_sde_main <- se_main / sd_y_pre

# Acute phase
beta_acute <- coef(m_phase)["preempt_acute"]
se_acute <- sqrt(vcov(m_phase)["preempt_acute","preempt_acute"])
sde_acute <- beta_acute / sd_y_pre
se_sde_acute <- se_acute / sd_y_pre

# Sustained phase
beta_sust <- coef(m_phase)["preempt_sustained"]
se_sust <- sqrt(vcov(m_phase)["preempt_sustained","preempt_sustained"])
sde_sust <- beta_sust / sd_y_pre
se_sde_sust <- se_sust / sd_y_pre

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: acute vs sustained, exclude early adopters
beta_noearl <- coef(m_no_early)["preempt_post"]
se_noearl <- sqrt(vcov(m_no_early)["preempt_post","preempt_post"])
sde_noearl <- beta_noearl / sd_y_pre
se_sde_noearl <- se_noearl / sd_y_pre

# Heterogeneity 2: Medicaid expansion states only
medicaid_expanded <- c("AK", "AZ", "AR", "CA", "CO", "CT", "DE", "HI",
                       "ID", "IL", "IN", "IA", "KY", "LA", "ME", "MD", "MA",
                       "MI", "MN", "MT", "NE", "NV", "NH", "NJ", "NM", "NY",
                       "ND", "OH", "OK", "OR", "PA", "RI", "UT", "VA", "VT",
                       "WA", "WV", "WI")
main_medexp <- main[state_abbr %in% medicaid_expanded]
m_medexp <- feols(th_pct ~ preempt_post | state_id + time_id,
                  data = main_medexp, vcov = ~state_abbr)
beta_medexp <- coef(m_medexp)["preempt_post"]
se_medexp <- sqrt(vcov(m_medexp)["preempt_post","preempt_post"])
sde_medexp <- beta_medexp / sd_y_pre
se_sde_medexp <- se_medexp / sd_y_pre

cat(sprintf("  SDE (overall): %.3f [%s]\n", sde_main, classify_sde(sde_main)))
cat(sprintf("  SDE (acute): %.3f [%s]\n", sde_acute, classify_sde(sde_acute)))
cat(sprintf("  SDE (sustained): %.3f [%s]\n", sde_sust, classify_sde(sde_sust)))

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state municipal broadband preemption laws reduce Medicare telehealth utilization during and after the COVID-19 pandemic? ",
  "\\textbf{Policy mechanism:} Twenty-two states enacted laws restricting local governments from building or operating broadband networks, reducing competition and broadband infrastructure investment in underserved areas, thereby constraining the digital capacity available for telehealth when the pandemic forced healthcare online. ",
  "\\textbf{Outcome definition:} Quarterly state-level share of Medicare Part B beneficiaries with at least one telehealth visit, from the CMS Medicare Telehealth Trends public use file. ",
  "\\textbf{Treatment:} Binary indicator for states with municipal broadband preemption laws enacted between 1997 and 2019, all predetermined before COVID-19. ",
  "\\textbf{Data:} CMS Medicare Telehealth Trends, 2020Q1--2025Q1, state-quarter panel, 50 states, 1,150 state-quarter observations. ",
  "\\textbf{Method:} Two-way fixed effects (state and quarter) with standard errors clustered at the state level; wild cluster bootstrap confirmation. ",
  "\\textbf{Sample:} All 50 US states (excluding DC due to unique geography); 22 treated states with preemption laws, 28 controls without. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2020 Q1) ",
  "standard deviation of telehealth utilization across states. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Telehealth (overall) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)),
  sprintf("Telehealth (acute) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_acute, se_acute, sd_y_pre, sde_acute, se_sde_acute, classify_sde(sde_acute)),
  sprintf("Telehealth (sustained) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_sust, se_sust, sd_y_pre, sde_sust, se_sde_sust, classify_sde(sde_sust)),
  "[0.3em]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("Excl. early adopters & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_noearl, se_noearl, sd_y_pre, sde_noearl, se_sde_noearl, classify_sde(sde_noearl)),
  sprintf("Medicaid expansion only & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_medexp, se_medexp, sd_y_pre, sde_medexp, se_sde_medexp, classify_sde(sde_medexp)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("  Saved tabF1_sde.tex\n")

cat("\n=== ALL TABLES COMPLETE ===\n")
