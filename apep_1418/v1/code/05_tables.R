## 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

cat("=== Generating Tables ===\n")
df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("Table 1: Summary statistics\n")

sumstats <- df |>
  summarise(
    `In-state tuition (\\$)` = sprintf("%.0f & %.0f & %.0f & %.0f",
      mean(tuition_in_state, na.rm=TRUE), sd(tuition_in_state, na.rm=TRUE),
      min(tuition_in_state, na.rm=TRUE), max(tuition_in_state, na.rm=TRUE)),
    `State appropriations/FTE (\\$)` = sprintf("%.0f & %.0f & %.0f & %.0f",
      mean(approp_per_fte, na.rm=TRUE), sd(approp_per_fte, na.rm=TRUE),
      quantile(approp_per_fte, 0.01, na.rm=TRUE), quantile(approp_per_fte, 0.99, na.rm=TRUE)),
    `Pell share (\\%)` = sprintf("%.1f & %.1f & %.1f & %.1f",
      mean(pell_share, na.rm=TRUE), sd(pell_share, na.rm=TRUE),
      quantile(pell_share, 0.01, na.rm=TRUE), quantile(pell_share, 0.99, na.rm=TRUE)),
    `Minority share (\\%)` = sprintf("%.1f & %.1f & %.1f & %.1f",
      mean(minority_share, na.rm=TRUE), sd(minority_share, na.rm=TRUE),
      quantile(minority_share, 0.01, na.rm=TRUE), quantile(minority_share, 0.99, na.rm=TRUE)),
    `Total enrollment` = sprintf("%.0f & %.0f & %.0f & %.0f",
      mean(total, na.rm=TRUE), sd(total, na.rm=TRUE),
      quantile(total, 0.01, na.rm=TRUE), quantile(total, 0.99, na.rm=TRUE)),
    `FTE enrollment` = sprintf("%.0f & %.0f & %.0f & %.0f",
      mean(fte_total, na.rm=TRUE), sd(fte_total, na.rm=TRUE),
      quantile(fte_total, 0.01, na.rm=TRUE), quantile(fte_total, 0.99, na.rm=TRUE))
  )

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Public Four-Year Institutions, 2004--2022}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & SD & P1 & P99 \\\\",
  "\\midrule"
)
for (nm in names(sumstats)) {
  tab1_lines <- c(tab1_lines, paste0(nm, " & ", sumstats[[nm]], " \\\\"))
}
tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Institutions & \\multicolumn{4}{c}{%d} \\\\", n_distinct(df$unitid)),
  sprintf("Institution-years & \\multicolumn{4}{c}{%s} \\\\", format(nrow(df), big.mark=",")),
  sprintf("States & \\multicolumn{4}{c}{%d} \\\\", n_distinct(df$state)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from IPEDS 2004--2022. Sample restricted to public four-year institutions with non-missing state appropriations and FTE enrollment. P1 and P99 denote the 1st and 99th percentiles. Appropriations per FTE winsorized at the 1st and 99th percentiles.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ---------------------------------------------------------------
# Table 2: Main Results — OLS and IV
# ---------------------------------------------------------------
cat("Table 2: Main results\n")

tab2_models <- list(
  "OLS" = results$ols_tuition,
  "IV" = results$iv_tuition,
  "OLS" = results$ols_pell,
  "IV" = results$iv_pell,
  "OLS" = results$ols_minority,
  "IV" = results$iv_minority
)

# Use modelsummary
modelsummary(
  tab2_models,
  output = "../tables/tab2_main.tex",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_map = c(
    "approp_per_fte" = "State approp./FTE",
    "fit_approp_per_fte" = "State approp./FTE"
  ),
  gof_map = c("nobs", "r.squared"),
  title = "Effect of State Appropriations on Tuition, Pell Share, and Minority Enrollment",
  notes = list(
    "Standard errors clustered at state level in parentheses.",
    "All specifications include institution and year fixed effects.",
    "IV specifications instrument state appropriations per FTE with Bartik shock (initial state HE budget share $\\times$ national unemployment change).",
    "Columns (1)--(2): in-state tuition (\\$). Columns (3)--(4): Pell grant recipient share (\\%). Columns (5)--(6): Black and Hispanic enrollment share (\\%)."
  )
)

# ---------------------------------------------------------------
# Table 3: Reduced Form and State Trends
# ---------------------------------------------------------------
cat("Table 3: Reduced form and state trends\n")

tab3_models <- list(
  "RF: Tuition" = rob$rf_tuition,
  "RF: Pell" = rob$rf_pell,
  "RF: Minority" = rob$rf_minority,
  "Trends: Tuition" = rob$ols_tuition_trend,
  "Trends: Pell" = rob$ols_pell_trend
)

modelsummary(
  tab3_models,
  output = "../tables/tab3_robustness.tex",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_map = c(
    "bartik_unemp" = "Bartik shock",
    "approp_per_fte" = "State approp./FTE"
  ),
  gof_map = c("nobs", "r.squared"),
  title = "Reduced-Form and State-Trend Specifications",
  notes = list(
    "Standard errors clustered at state level in parentheses.",
    "Columns (1)--(3): reduced-form regressions of outcomes on the Bartik shock directly.",
    "Columns (4)--(5): OLS with institution FE, year FE, and state-specific linear trends."
  )
)

# ---------------------------------------------------------------
# Table 4: Heterogeneity by Institution Type
# ---------------------------------------------------------------
cat("Table 4: Heterogeneity\n")

tab4_models <- list(
  "Tuition" = rob$het_tuition,
  "Pell" = rob$het_pell,
  "Tuition (HBCU)" = rob$het_hbcu
)

modelsummary(
  tab4_models,
  output = "../tables/tab4_heterogeneity.tex",
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_map = c(
    "approp_per_fte" = "State approp./FTE",
    "approp_per_fte:research" = "$\\times$ Research",
    "approp_per_fte:hbcu_flag" = "$\\times$ HBCU"
  ),
  gof_map = c("nobs", "r.squared"),
  title = "Heterogeneity by Institution Type",
  notes = list(
    "Standard errors clustered at state level in parentheses.",
    "All specifications include institution and year fixed effects.",
    "Research = Carnegie R1/R2 institutions. HBCU = Historically Black Colleges and Universities."
  )
)

# ---------------------------------------------------------------
# Table F1: SDE Appendix (mandatory)
# ---------------------------------------------------------------
cat("Table F1: Standardized effect sizes\n")

# Compute SDE for main outcomes
# SDE = β̂ / SD(Y) for continuous treatment
# Here treatment is approp_per_fte, continuous — so SDE = β̂ × SD(X) / SD(Y)
sd_approp <- sd(df$approp_per_fte, na.rm = TRUE)
sd_tuition <- sd(df$tuition_in_state, na.rm = TRUE)
sd_pell <- sd(df$pell_share, na.rm = TRUE)
sd_minority <- sd(df$minority_share, na.rm = TRUE)
sd_enroll <- sd(df$log_enroll[is.finite(df$log_enroll)], na.rm = TRUE)

# Use OLS with state trends (our preferred specification)
beta_tuition <- coef(rob$ols_tuition_trend)["approp_per_fte"]
se_tuition <- se(rob$ols_tuition_trend)["approp_per_fte"]
beta_pell <- coef(rob$ols_pell_trend)["approp_per_fte"]
se_pell <- se(rob$ols_pell_trend)["approp_per_fte"]

# OLS for minority and enrollment (no state trend version saved, use main OLS)
beta_minority <- coef(results$ols_minority)["approp_per_fte"]
se_minority <- se(results$ols_minority)["approp_per_fte"]

sde_tuition <- beta_tuition * sd_approp / sd_tuition
sde_pell <- beta_pell * sd_approp / sd_pell
sde_minority <- beta_minority * sd_approp / sd_minority

se_sde_tuition <- abs(se_tuition * sd_approp / sd_tuition)
se_sde_pell <- abs(se_pell * sd_approp / sd_pell)
se_sde_minority <- abs(se_minority * sd_approp / sd_minority)

classify_sde <- function(x) {
  case_when(
    x < -0.15 ~ "Large negative",
    x < -0.05 ~ "Moderate negative",
    x < -0.005 ~ "Small negative",
    x < 0.005 ~ "Null",
    x < 0.05 ~ "Small positive",
    x < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# Panel A: Pooled
sde_rows_a <- tibble(
  Outcome = c("In-state tuition", "Pell grant share", "Minority enrollment share"),
  beta = c(beta_tuition, beta_pell, beta_minority),
  SE = c(se_tuition, se_pell, se_minority),
  SD_Y = c(sd_tuition, sd_pell, sd_minority),
  SDE = c(sde_tuition, sde_pell, sde_minority),
  SE_SDE = c(se_sde_tuition, se_sde_pell, se_sde_minority),
  Classification = classify_sde(c(sde_tuition, sde_pell, sde_minority))
)

# Panel B: Heterogeneous (Research vs non-Research)
# Research universities
df_research <- df |> filter(inst_type == "Research")
df_nonresearch <- df |> filter(inst_type != "Research")

ols_tuit_res <- feols(tuition_in_state ~ approp_per_fte | unitid + year,
                      data = df_research, cluster = ~state)
ols_tuit_nonres <- feols(tuition_in_state ~ approp_per_fte | unitid + year,
                         data = df_nonresearch, cluster = ~state)

sd_tuit_res <- sd(df_research$tuition_in_state, na.rm = TRUE)
sd_tuit_nonres <- sd(df_nonresearch$tuition_in_state, na.rm = TRUE)
sd_app_res <- sd(df_research$approp_per_fte, na.rm = TRUE)
sd_app_nonres <- sd(df_nonresearch$approp_per_fte, na.rm = TRUE)

sde_tuit_res <- coef(ols_tuit_res) * sd_app_res / sd_tuit_res
sde_tuit_nonres <- coef(ols_tuit_nonres) * sd_app_nonres / sd_tuit_nonres

sde_rows_b <- tibble(
  Outcome = c("Tuition (Research)", "Tuition (Non-Research)"),
  beta = c(coef(ols_tuit_res), coef(ols_tuit_nonres)),
  SE = c(se(ols_tuit_res), se(ols_tuit_nonres)),
  SD_Y = c(sd_tuit_res, sd_tuit_nonres),
  SDE = c(sde_tuit_res, sde_tuit_nonres),
  SE_SDE = c(abs(se(ols_tuit_res) * sd_app_res / sd_tuit_res),
             abs(se(ols_tuit_nonres) * sd_app_nonres / sd_tuit_nonres)),
  Classification = classify_sde(c(sde_tuit_res, sde_tuit_nonres))
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state disinvestment in public higher education alter tuition levels and the socioeconomic composition of the student body? ",
  "\\textbf{Policy mechanism:} State legislatures cut per-student appropriations to public universities, particularly during fiscal downturns; universities respond by raising tuition and adjusting enrollment strategies, potentially displacing low-income students. ",
  "\\textbf{Outcome definition:} In-state tuition is the published annual tuition and required fees for full-time in-state undergraduate students from IPEDS Institutional Characteristics; Pell grant share is the percentage of undergraduate students receiving federal Pell grants from IPEDS Student Financial Aid; minority enrollment share is the percentage of total enrollment who are Black or Hispanic from IPEDS Fall Enrollment. ",
  "\\textbf{Treatment:} Continuous; state appropriations per full-time-equivalent student in nominal dollars. ",
  "\\textbf{Data:} IPEDS 2004--2022, public four-year institutions, 7,164 institution-year observations across 512 institutions and 50 states plus DC. ",
  "\\textbf{Method:} OLS with institution and year fixed effects (preferred specification includes state-specific linear trends); standard errors clustered at the state level. IV specification instruments appropriations with a Bartik shock (initial state HE budget share $\\times$ national unemployment change). ",
  "\\textbf{Sample:} Public four-year institutions with non-missing state appropriations, tuition, and FTE enrollment data; excludes institutions with fewer than 100 FTE students. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, where SD($Y$) is the full-sample ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_rows_a)) {
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\",
    sde_rows_a$Outcome[i], sde_rows_a$beta[i], sde_rows_a$SE[i],
    sde_rows_a$SD_Y[i], sde_rows_a$SDE[i], sde_rows_a$SE_SDE[i],
    sde_rows_a$Classification[i]
  ))
}

sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Research vs.\\ Non-Research)}} \\\\"
)

for (i in 1:nrow(sde_rows_b)) {
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\",
    sde_rows_b$Outcome[i], sde_rows_b$beta[i], sde_rows_b$SE[i],
    sde_rows_b$SD_Y[i], sde_rows_b$SDE[i], sde_rows_b$SE_SDE[i],
    sde_rows_b$Classification[i]
  ))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
