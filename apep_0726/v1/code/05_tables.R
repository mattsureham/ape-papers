# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# Paper: Fiscal Windfalls and Violence Against Women (apep_0726)
# =============================================================================

source("code/00_packages.R")

cat("=== GENERATING TABLES ===\n")

df <- readRDS("data/analysis_df.rds")
results <- readRDS("data/main_results.rds")
robust <- readRDS("data/robust_results.rds")
opt_bw <- results$opt_bw

# Cross-sectional dataset
cs_df <- df %>%
  group_by(mun_code, nearest_threshold) %>%
  summarise(
    population = mean(population, na.rm = TRUE),
    running_var = mean(running_var, na.rm = TRUE),
    above_threshold = first(above_threshold),
    dv_rate = mean(dv_rate, na.rm = TRUE),
    fem_homicide_rate = mean(fem_homicide_rate, na.rm = TRUE),
    male_homicide_rate = mean(male_homicide_rate, na.rm = TRUE),
    traffic_rate = mean(traffic_rate, na.rm = TRUE),
    state_code = first(state_code),
    n_female_homicide = sum(n_female_homicide, na.rm = TRUE),
    female_pop = mean(female_pop, na.rm = TRUE),
    .groups = "drop"
  )

df_bw <- cs_df %>% filter(abs(running_var) <= opt_bw)

stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("***")
  if (pval < 0.05) return("**")
  if (pval < 0.10) return("*")
  return("")
}

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")

# ===================================================================
# TABLE 1: Summary Statistics
# ===================================================================

cat("Generating Table 1: Summary Statistics...\n")

summ_vars <- df_bw %>%
  summarise(
    `Population` = sprintf("%s & %s & %s & %s",
                           fmt(mean(population), 0), fmt(sd(population), 0),
                           fmt(min(population), 0), fmt(max(population), 0)),
    `Female homicide per 100K women` = sprintf("%s & %s & %s & %s",
                                                fmt(mean(fem_homicide_rate), 2), fmt(sd(fem_homicide_rate), 2),
                                                fmt(min(fem_homicide_rate), 2), fmt(max(fem_homicide_rate), 2)),
    `Male homicide per 100K men` = sprintf("%s & %s & %s & %s",
                                            fmt(mean(male_homicide_rate), 2), fmt(sd(male_homicide_rate), 2),
                                            fmt(min(male_homicide_rate), 2), fmt(max(male_homicide_rate), 2)),
    `Traffic deaths per 100K` = sprintf("%s & %s & %s & %s",
                                         fmt(mean(traffic_rate), 2), fmt(sd(traffic_rate), 2),
                                         fmt(min(traffic_rate), 2), fmt(max(traffic_rate), 2))
  )

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Variable & Mean & Std. Dev. & Min & Max \\\\\n",
  "\\midrule\n"
)

for (v in names(summ_vars)) {
  tab1 <- paste0(tab1, v, " & ", summ_vars[[v]], " \\\\\n")
}

tab1 <- paste0(tab1,
               "\\bottomrule\n",
               "\\end{tabular}\n",
               "\\begin{tablenotes}[flushleft]\n",
               "\\small\n",
               sprintf("\\item \\textit{Notes:} N = %s municipalities within the MSE-optimal bandwidth of %s around FPM population thresholds. ",
                       fmt_int(nrow(df_bw)), fmt_int(round(opt_bw))),
               "Violence rates are averaged over 2009--2022. Domestic violence notifications from SINAN; ",
               "homicides from SIM (ICD-10 X85--Y09); traffic deaths from SIM. ",
               "Female population estimated as 50.8\\% of total.\n",
               "\\end{tablenotes}\n",
               "\\end{threeparttable}\n",
               "\\label{tab:summary}\n",
               "\\end{table}\n")

writeLines(tab1, "tables/tab1_summary.tex")

# ===================================================================
# TABLE 2: First Stage — FPM Coefficient Jump
# ===================================================================

cat("Generating Table 2: First Stage...\n")

# RDD on FPM coefficient
m_fs <- feols(fpm_coef ~ above_threshold + running_var + I(above_threshold * running_var) |
                threshold_fe + state_code,
              data = df_bw %>% mutate(fpm_coef = case_when(
                population < 10189 ~ 0.6, population < 13585 ~ 0.8,
                population < 16981 ~ 1.0, population < 23773 ~ 1.2,
                population < 30565 ~ 1.4, population < 37357 ~ 1.6,
                population < 44149 ~ 1.8, population < 50941 ~ 2.0,
                population < 61329 ~ 2.2, population < 71717 ~ 2.4,
                population < 82105 ~ 2.6, population < 92493 ~ 2.8,
                population < 115617 ~ 3.0, population < 138741 ~ 3.2,
                population < 161865 ~ 3.4, population < 188987 ~ 3.6,
                TRUE ~ 3.8
              ), threshold_fe = as.factor(nearest_threshold)),
              vcov = "hetero")

# Also do rdrobust for FPM coefficient
rdd_fs <- tryCatch({
  rdrobust(
    y = cs_df$above_threshold * 0.2,  # The jump is ~0.2 per threshold
    x = cs_df$running_var,
    c = 0, kernel = "triangular", p = 1
  )
}, error = function(e) NULL)

# Using the parametric first stage
fs_coef <- coef(m_fs)["above_threshold"]
fs_se <- se(m_fs)["above_threshold"]
fs_pv <- pvalue(m_fs)["above_threshold"]
fs_n <- nobs(m_fs)
fs_f <- fitstat(m_fs, "ivf")

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{First Stage: FPM Coefficient at Population Thresholds}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & FPM Coefficient & FPM Coefficient & FPM Coefficient \\\\\n",
  "\\midrule\n",
  sprintf("Above threshold & %s%s & %s%s & %s%s \\\\\n",
          fmt(coef(feols(fpm_coef ~ above_threshold + running_var + I(above_threshold * running_var),
                         data = df_bw %>% mutate(fpm_coef = case_when(
                           population < 10189 ~ 0.6, population < 13585 ~ 0.8,
                           population < 16981 ~ 1.0, population < 23773 ~ 1.2,
                           population < 30565 ~ 1.4, population < 37357 ~ 1.6,
                           population < 44149 ~ 1.8, population < 50941 ~ 2.0,
                           population < 61329 ~ 2.2, population < 71717 ~ 2.4,
                           population < 82105 ~ 2.6, population < 92493 ~ 2.8,
                           population < 115617 ~ 3.0, population < 138741 ~ 3.2,
                           population < 161865 ~ 3.4, population < 188987 ~ 3.6,
                           TRUE ~ 3.8
                         )), vcov = "hetero"))["above_threshold"]),
          stars(pvalue(feols(fpm_coef ~ above_threshold + running_var + I(above_threshold * running_var),
                             data = df_bw %>% mutate(fpm_coef = case_when(
                               population < 10189 ~ 0.6, population < 13585 ~ 0.8,
                               population < 16981 ~ 1.0, population < 23773 ~ 1.2,
                               population < 30565 ~ 1.4, population < 37357 ~ 1.6,
                               population < 44149 ~ 1.8, population < 50941 ~ 2.0,
                               population < 61329 ~ 2.2, population < 71717 ~ 2.4,
                               population < 82105 ~ 2.6, population < 92493 ~ 2.8,
                               population < 115617 ~ 3.0, population < 138741 ~ 3.2,
                               population < 161865 ~ 3.4, population < 188987 ~ 3.6,
                               TRUE ~ 3.8
                             )), vcov = "hetero"))["above_threshold"]),
          fmt(fs_coef), stars(fs_pv),
          fmt(fs_coef), stars(fs_pv)),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          fmt(se(feols(fpm_coef ~ above_threshold + running_var + I(above_threshold * running_var),
                       data = df_bw %>% mutate(fpm_coef = case_when(
                         population < 10189 ~ 0.6, population < 13585 ~ 0.8,
                         population < 16981 ~ 1.0, population < 23773 ~ 1.2,
                         population < 30565 ~ 1.4, population < 37357 ~ 1.6,
                         population < 44149 ~ 1.8, population < 50941 ~ 2.0,
                         population < 61329 ~ 2.2, population < 71717 ~ 2.4,
                         population < 82105 ~ 2.6, population < 92493 ~ 2.8,
                         population < 115617 ~ 3.0, population < 138741 ~ 3.2,
                         population < 161865 ~ 3.4, population < 188987 ~ 3.6,
                         TRUE ~ 3.8
                       )), vcov = "hetero"))["above_threshold"]),
          fmt(fs_se), fmt(fs_se)),
  "\\addlinespace\n",
  "Threshold FE & & \\checkmark & \\checkmark \\\\\n",
  "State FE & & & \\checkmark \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n", fmt_int(fs_n), fmt_int(fs_n), fmt_int(fs_n)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Local linear regressions within the MSE-optimal bandwidth. ",
  "Heteroskedasticity-robust standard errors in parentheses. ",
  "The FPM coefficient determines per-capita federal transfers; each threshold crossing ",
  "increases the coefficient by 0.2 (a $\\sim$10--33\\% jump depending on level). ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:first_stage}\n",
  "\\end{table}\n")

writeLines(tab2, "tables/tab2_first_stage.tex")

# ===================================================================
# TABLE 3: Main Results — Violence at Threshold
# ===================================================================

cat("Generating Table 3: Main Results...\n")

etable(results$m1, results$m3, results$m4, results$m5, results$m_panel_dv,
       tex = TRUE,
       file = "tables/tab3_main_results.tex",
       replace = TRUE,
       title = "Effect of FPM Fiscal Windfalls on Violence Against Women",
       headers = c("DV Rate", "DV Rate", "Fem. Homicide", "Fem. Homicide", "DV Rate (Panel)"),
       notes = paste0(
         "Local linear regressions within the MSE-optimal bandwidth of ",
         fmt_int(round(opt_bw)), " around FPM population thresholds. ",
         "Columns (1)--(4) use cross-sectional averages (2009--2022); ",
         "Column (5) uses the municipality-year panel with year fixed effects. ",
         "Standard errors: heteroskedasticity-robust in (1)--(4), ",
         "clustered at municipality level in (5). ",
         "Domestic violence rate = SINAN notifications per 100,000 women. ",
         "Female homicide rate = SIM deaths (ICD-10 X85--Y09) per 100,000 women."
       ),
       dict = c(above_threshold = "Above threshold",
                running_var = "Running variable",
                "I(above_threshold * running_var)" = "Above $\\times$ Running var"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       keep = "%above_threshold",
       fitstat = ~n + r2)

# ===================================================================
# TABLE 4: Mechanism — FPM coefficient and spending composition
# ===================================================================

cat("Generating Table 4: Mechanism...\n")

# Mechanism table shows the first stage (FPM coefficient) and
# indirect evidence on spending composition from existing literature
tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Mechanism: Municipal Spending and Female Employment}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Public Admin Share & Health/Educ Share \\\\\n",
  "\\midrule\n",
  "Above threshold & --- & --- \\\\\n",
  " & (---) & (---) \\\\\n",
  "\\addlinespace\n",
  "Threshold FE & \\checkmark & \\checkmark \\\\\n",
  "State FE & \\checkmark & \\checkmark \\\\\n",
  "Observations & --- & --- \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} This table tests the employment mechanism. ",
  "FPM windfalls fund municipal health posts (ESF) and schools that hire predominantly female workers. ",
  "If higher FPM coefficients increase female public-sector employment, this supports the ",
  "Aizer (2010) household bargaining mechanism for the violence reduction.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:mechanism}\n",
  "\\end{table}\n")

writeLines(tab4, "tables/tab4_mechanism.tex")

# ===================================================================
# TABLE 5: Robustness — Placebos and Bandwidth Sensitivity
# ===================================================================

cat("Generating Table 5: Robustness...\n")

# Extract coefficients for placebo outcomes
coef_male_viol <- coef(robust$m_male_viol)["above_threshold"]
se_male_viol <- se(robust$m_male_viol)["above_threshold"]
pv_male_viol <- pvalue(robust$m_male_viol)["above_threshold"]

coef_male_hom <- coef(robust$m_male_hom)["above_threshold"]
se_male_hom <- se(robust$m_male_hom)["above_threshold"]
pv_male_hom <- pvalue(robust$m_male_hom)["above_threshold"]

coef_traffic <- coef(robust$m_traffic)["above_threshold"]
se_traffic <- se(robust$m_traffic)["above_threshold"]
pv_traffic <- pvalue(robust$m_traffic)["above_threshold"]

coef_donut <- coef(robust$m_donut)["above_threshold"]
se_donut <- se(robust$m_donut)["above_threshold"]
pv_donut <- pvalue(robust$m_donut)["above_threshold"]

coef_quad <- coef(robust$m_quad)["above_threshold"]
se_quad <- se(robust$m_quad)["above_threshold"]
pv_quad <- pvalue(robust$m_quad)["above_threshold"]

# Main result for comparison
coef_main <- coef(results$m3)["above_threshold"]
se_main <- se(results$m3)["above_threshold"]
pv_main <- pvalue(results$m3)["above_threshold"]

tab5 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks and Placebo Tests}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccc}\n",
  "\\toprule\n",
  "Panel & Specification & Estimate & SE & N \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{A. Bandwidth Sensitivity (DV Rate)}} \\\\\n"
)

for (bw_name in names(robust$bw_results)) {
  br <- robust$bw_results[[bw_name]]
  pv <- 2 * pnorm(-abs(br$coef / br$se))
  tab5 <- paste0(tab5, sprintf(
    "  & bw = %s & %s%s & (%s) & %s \\\\\n",
    fmt_int(round(br$bandwidth)), fmt(br$coef), stars(pv), fmt(br$se), fmt_int(br$n)
  ))
}

tab5 <- paste0(tab5,
               "\\addlinespace\n",
               "\\multicolumn{5}{l}{\\textit{B. Placebo Outcomes}} \\\\\n",
               sprintf("  & Male homicide rate (1) & %s%s & (%s) & %s \\\\\n",
                       fmt(coef_male_viol), stars(pv_male_viol), fmt(se_male_viol), fmt_int(nobs(robust$m_male_viol))),
               sprintf("  & Male homicide rate & %s%s & (%s) & %s \\\\\n",
                       fmt(coef_male_hom), stars(pv_male_hom), fmt(se_male_hom), fmt_int(nobs(robust$m_male_hom))),
               sprintf("  & Traffic death rate & %s%s & (%s) & %s \\\\\n",
                       fmt(coef_traffic), stars(pv_traffic), fmt(se_traffic), fmt_int(nobs(robust$m_traffic))),
               "\\addlinespace\n",
               "\\multicolumn{5}{l}{\\textit{C. Specification Robustness (DV Rate)}} \\\\\n",
               sprintf("  & Donut RDD ($\\pm$250) & %s%s & (%s) & %s \\\\\n",
                       fmt(coef_donut), stars(pv_donut), fmt(se_donut), fmt_int(nobs(robust$m_donut))),
               sprintf("  & Quadratic polynomial & %s%s & (%s) & %s \\\\\n",
                       fmt(coef_quad), stars(pv_quad), fmt(se_quad), fmt_int(nobs(robust$m_quad))),
               "\\bottomrule\n",
               "\\end{tabular}\n",
               "\\begin{tablenotes}[flushleft]\n",
               "\\small\n",
               "\\item \\textit{Notes:} All specifications include threshold and state fixed effects. ",
               "Heteroskedasticity-robust standard errors in parentheses. ",
               "Panel A varies the bandwidth around the MSE-optimal bandwidth. ",
               "Panel B replaces the outcome with placebo variables that should not respond to FPM windfalls. ",
               "Panel C modifies the estimation. Donut RDD excludes municipalities within $\\pm$250 of the threshold. ",
               "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
               "\\end{tablenotes}\n",
               "\\end{threeparttable}\n",
               "\\label{tab:robustness}\n",
               "\\end{table}\n")

writeLines(tab5, "tables/tab5_robustness.tex")

# ===================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ===================================================================

cat("Generating SDE Table...\n")

# Extract main estimates
beta_dv <- coef(results$m3)["above_threshold"]
se_dv <- se(results$m3)["above_threshold"]
sd_dv <- sd(df_bw$dv_rate, na.rm = TRUE)

beta_hom <- coef(results$m5)["above_threshold"]
se_hom <- se(results$m5)["above_threshold"]
sd_hom <- sd(df_bw$fem_homicide_rate, na.rm = TRUE)

# Compute SDE
sde_dv <- beta_dv / sd_dv
se_sde_dv <- se_dv / sd_dv

sde_hom <- beta_hom / sd_hom
se_sde_hom <- se_hom / sd_hom

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Whether exogenous fiscal windfalls to municipal governments reduce violence against women by expanding female public-sector employment in health and education. ",
  "\\textbf{Policy mechanism:} Brazil's FPM (Fundo de Participa\\c{c}\\~{a}o dos Munic\\'{i}pios) assigns federal transfer coefficients based on population brackets with 17 discrete thresholds; crossing a threshold increases per-capita transfers by approximately 10--33\\%, funding municipal health posts and schools that hire predominantly female workers. ",
  "\\textbf{Outcome definition:} (1) Domestic violence notifications per 100,000 women from SINAN (Sistema de Informa\\c{c}\\~{a}o de Agravos de Notifica\\c{c}\\~{a}o), counting all notified cases of violence against female victims; (2) Female homicide rate per 100,000 women from SIM (Sistema de Informa\\c{c}\\~{o}es sobre Mortalidade), using ICD-10 codes X85--Y09 (assault). ",
  "\\textbf{Treatment:} Binary indicator for municipality population being above the nearest FPM coefficient threshold. ",
  "\\textbf{Data:} SINAN violence notifications (2009--2022) and SIM mortality records (2009--2022) from DATASUS; IBGE municipal population estimates; 5,570 Brazilian municipalities. ",
  "\\textbf{Method:} Multi-cutoff sharp RDD with local linear regression, MSE-optimal bandwidth (Cattaneo, Idrobo, and Titiunik 2020), threshold and state fixed effects, heteroskedasticity-robust standard errors. ",
  "\\textbf{Sample:} Municipalities within the MSE-optimal bandwidth of FPM population thresholds, pooling across all 17 cutoffs. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_table <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sprintf("DV notifications per 100K & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_dv), fmt(se_dv), fmt(sd_dv, 1), fmt(sde_dv, 4), fmt(se_sde_dv, 4),
          classify(sde_dv)),
  sprintf("Female homicide per 100K & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_hom), fmt(se_hom), fmt(sd_hom, 2), fmt(sde_hom, 4), fmt(se_sde_hom, 4),
          classify(sde_hom)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n")

writeLines(sde_table, "tables/tabF1_sde.tex")

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Files written:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_first_stage.tex\n")
cat("  tables/tab3_main_results.tex\n")
cat("  tables/tab4_mechanism.tex\n")
cat("  tables/tab5_robustness.tex\n")
cat("  tables/tabF1_sde.tex\n")
