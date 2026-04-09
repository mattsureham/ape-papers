# 05_tables.R — Generate all LaTeX tables for the paper
source("00_packages.R")

df <- as.data.table(readRDS("../data/analysis_sample.rds"))
results <- readRDS("../data/rdd_results.rds")
cov_results <- readRDS("../data/cov_balance_results.rds")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Below vs above cutoff
below <- df[above65 == 0]
above <- df[above65 == 1]

make_row <- function(varname, label, digits = 3) {
  b_mean <- mean(below[[varname]], na.rm = TRUE)
  b_sd <- sd(below[[varname]], na.rm = TRUE)
  a_mean <- mean(above[[varname]], na.rm = TRUE)
  a_sd <- sd(above[[varname]], na.rm = TRUE)
  sprintf("  %s & %s & (%s) & %s & (%s) \\\\",
          label,
          formatC(b_mean, format = "f", digits = digits),
          formatC(b_sd, format = "f", digits = digits),
          formatC(a_mean, format = "f", digits = digits),
          formatC(a_sd, format = "f", digits = digits))
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics by Age Group}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "  & \\multicolumn{2}{c}{Ages 55--64} & \\multicolumn{2}{c}{Ages 65--75} \\\\",
  "  & Mean & (SD) & Mean & (SD) \\\\",
  "\\hline",
  "  \\multicolumn{5}{l}{\\textit{Panel A: Demographics}} \\\\",
  make_row("female", "Female", 3),
  make_row("urban", "Urban", 3),
  make_row("education", "Years of Education", 1),
  "  \\\\",
  "  \\multicolumn{5}{l}{\\textit{Panel B: Labor Market Outcomes}} \\\\",
  make_row("lfp", "Labor Force Participation", 3),
  make_row("employed", "Employed", 3),
  make_row("hours", "Weekly Hours", 1),
  make_row("labor_income", "Monthly Labor Income (USD)", 0),
  "  \\\\",
  "  \\multicolumn{5}{l}{\\textit{Panel C: Transfer Receipt}} \\\\",
  make_row("receives_transfer", "Receives Gov. Transfer", 3),
  make_row("transfer_amount", "Transfer Amount (USD/month)", 0),
  "\\hline",
  sprintf("  Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(nrow(below), big.mark = ","), format(nrow(above), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Sample includes all individuals aged 55--75 from ENEMDU quarterly surveys (2021 Q3 -- 2023 Q4, 7 waves). Standard deviations in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("Written: tab1_summary.tex\n")

# ============================================================================
# TABLE 2: First Stage and Main RDD Results
# ============================================================================
cat("\n=== Table 2: Main RDD Results ===\n")

# Re-run key regressions to get all needed info
outcomes_list <- list(
  list(var = "receives_transfer", label = "Transfer Receipt"),
  list(var = "lfp", label = "LFP"),
  list(var = "employed", label = "Employment"),
  list(var = "hours", label = "Hours Worked"),
  list(var = "labor_income", label = "Labor Income")
)

# Full sample results
full_rows <- c()
for (o in outcomes_list) {
  rd <- rdrobust(y = df[[o$var]], x = df$age_c, c = 0)
  # Control mean (just below cutoff, ages 63-64)
  ctrl_mean <- mean(df[age %in% c(63, 64)][[o$var]], na.rm = TRUE)
  full_rows <- c(full_rows, sprintf(
    "  %s & %s & (%s) & [%s] & %s & %s \\\\",
    o$label,
    formatC(rd$coef[1], format = "f", digits = 3),
    formatC(rd$se[1], format = "f", digits = 3),
    formatC(rd$pv[1], format = "f", digits = 3),
    formatC(rd$bws[1, 1], format = "f", digits = 1),
    formatC(ctrl_mean, format = "f", digits = 3)
  ))
}

# Poor subsample
df_poor <- df[poor == 1]
poor_rows <- c()
for (o in outcomes_list) {
  rd <- rdrobust(y = df_poor[[o$var]], x = df_poor$age_c, c = 0)
  ctrl_mean <- mean(df_poor[age %in% c(63, 64)][[o$var]], na.rm = TRUE)
  poor_rows <- c(poor_rows, sprintf(
    "  %s & %s & (%s) & [%s] & %s & %s \\\\",
    o$label,
    formatC(rd$coef[1], format = "f", digits = 3),
    formatC(rd$se[1], format = "f", digits = 3),
    formatC(rd$pv[1], format = "f", digits = 3),
    formatC(rd$bws[1, 1], format = "f", digits = 1),
    formatC(ctrl_mean, format = "f", digits = 3)
  ))
}

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{RDD Estimates at Age 65: Transfer Receipt and Labor Market Outcomes}",
  "\\label{tab:main_rdd}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "  & Estimate & (SE) & [$p$-value] & Bandwidth & Control Mean \\\\",
  "\\hline",
  "  \\multicolumn{6}{l}{\\textit{Panel A: Full Sample}} \\\\",
  full_rows,
  "  \\\\",
  "  \\multicolumn{6}{l}{\\textit{Panel B: Poor Subsample (Bottom 40\\%)}} \\\\",
  poor_rows,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Sharp RDD estimates using local linear regression with triangular kernel and CCT optimal bandwidth (Cattaneo, Idrobo, and Titiunik 2020). Standard errors use nearest-neighbor variance estimator. Sample: ENEMDU 2021 Q3--2023 Q4. Full sample: 106,334 individuals aged 55--75. Poor subsample: individuals with per capita income below the 40th percentile. Control mean computed for ages 63--64.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, file.path(tables_dir, "tab2_main_rdd.tex"))
cat("Written: tab2_main_rdd.tex\n")

# ============================================================================
# TABLE 3: Covariate Balance
# ============================================================================
cat("\n=== Table 3: Covariate Balance ===\n")

cov_labels <- c(female = "Female", urban = "Urban",
                education = "Years of Education",
                no_social_security = "No Social Security")

cov_rows <- c()
for (cov in names(cov_labels)) {
  r <- cov_results[[cov]]
  ctrl_mean <- mean(df[age %in% c(63, 64)][[cov]], na.rm = TRUE)
  cov_rows <- c(cov_rows, sprintf(
    "  %s & %s & (%s) & [%s] & %s \\\\",
    cov_labels[cov],
    formatC(r$coef, format = "f", digits = 4),
    formatC(r$se, format = "f", digits = 4),
    formatC(r$pval, format = "f", digits = 3),
    formatC(ctrl_mean, format = "f", digits = 3)
  ))
}

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Covariate Balance at Age-65 Cutoff}",
  "\\label{tab:balance}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "  & RD Estimate & (SE) & [$p$-value] & Control Mean \\\\",
  "\\hline",
  cov_rows,
  "\\hline",
  "  Joint $F$-test $p$-value & \\multicolumn{4}{c}{---} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each row reports the RDD estimate of the discontinuity in the covariate at age 65, using the same local linear specification as Table~\\ref{tab:main_rdd}. No covariate shows a statistically significant jump at conventional levels, supporting the validity of the design.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, file.path(tables_dir, "tab3_balance.tex"))
cat("Written: tab3_balance.tex\n")

# ============================================================================
# TABLE 4: Heterogeneity (Urban/Rural and Male/Female)
# ============================================================================
cat("\n=== Table 4: Heterogeneity ===\n")

het_rows <- c()
for (subvar in c("urban", "female")) {
  for (val in c(1, 0)) {
    sub <- df[get(subvar) == val]
    label <- ifelse(subvar == "urban",
                    ifelse(val == 1, "Urban", "Rural"),
                    ifelse(val == 1, "Female", "Male"))
    rd_lfp <- rdrobust(y = sub$lfp, x = sub$age_c, c = 0)
    rd_emp <- rdrobust(y = sub$employed, x = sub$age_c, c = 0)
    ctrl_lfp <- mean(sub[age %in% c(63,64)]$lfp, na.rm = TRUE)
    het_rows <- c(het_rows, sprintf(
      "  %s & %s & (%s) & [%s] & %s & (%s) & [%s] & %s \\\\",
      label,
      formatC(rd_lfp$coef[1], format="f", digits=3),
      formatC(rd_lfp$se[1], format="f", digits=3),
      formatC(rd_lfp$pv[1], format="f", digits=3),
      formatC(rd_emp$coef[1], format="f", digits=3),
      formatC(rd_emp$se[1], format="f", digits=3),
      formatC(rd_emp$pv[1], format="f", digits=3),
      formatC(ctrl_lfp, format="f", digits=3)
    ))
  }
}

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneous Effects by Location and Sex}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcccccccc}",
  "\\hline\\hline",
  "  & \\multicolumn{3}{c}{LFP} & \\multicolumn{3}{c}{Employment} & Control \\\\",
  "  & Estimate & (SE) & [$p$] & Estimate & (SE) & [$p$] & LFP Mean \\\\",
  "\\hline",
  het_rows,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Subgroup-specific RDD estimates at age 65. Same specification as Table~\\ref{tab:main_rdd}. The urban-rural difference suggests that the pension enables labor market exit primarily in urban areas, where elderly workers are in wage employment. Rural elderly, predominantly in agriculture, continue working regardless of pension receipt.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, file.path(tables_dir, "tab4_heterogeneity.tex"))
cat("Written: tab4_heterogeneity.tex\n")

# ============================================================================
# TABLE 5: Robustness
# ============================================================================
cat("\n=== Table 5: Robustness ===\n")

# Run all robustness specifications for LFP
rob_rows <- c()

# 1. Baseline
rd_base <- rdrobust(y = df$lfp, x = df$age_c, c = 0)
rob_rows <- c(rob_rows, sprintf(
  "  Baseline (CCT optimal) & %s & (%s) & [%s] & %s \\\\",
  formatC(rd_base$coef[1], format="f", digits=3),
  formatC(rd_base$se[1], format="f", digits=3),
  formatC(rd_base$pv[1], format="f", digits=3),
  formatC(rd_base$bws[1,1], format="f", digits=1)
))

# 2. Uniform kernel
rd_uni <- rdrobust(y = df$lfp, x = df$age_c, c = 0, kernel = "uniform")
rob_rows <- c(rob_rows, sprintf(
  "  Uniform kernel & %s & (%s) & [%s] & %s \\\\",
  formatC(rd_uni$coef[1], format="f", digits=3),
  formatC(rd_uni$se[1], format="f", digits=3),
  formatC(rd_uni$pv[1], format="f", digits=3),
  formatC(rd_uni$bws[1,1], format="f", digits=1)
))

# 3. Quadratic polynomial
rd_q2 <- rdrobust(y = df$lfp, x = df$age_c, c = 0, p = 2)
rob_rows <- c(rob_rows, sprintf(
  "  Quadratic polynomial & %s & (%s) & [%s] & %s \\\\",
  formatC(rd_q2$coef[1], format="f", digits=3),
  formatC(rd_q2$se[1], format="f", digits=3),
  formatC(rd_q2$pv[1], format="f", digits=3),
  formatC(rd_q2$bws[1,1], format="f", digits=1)
))

# 4. Bandwidth = 5
rd_bw5 <- rdrobust(y = df$lfp, x = df$age_c, c = 0, h = 5, p = 1, q = 2)
rob_rows <- c(rob_rows, sprintf(
  "  Fixed bandwidth ($h=5$) & %s & (%s) & [%s] & 5.0 \\\\",
  formatC(rd_bw5$coef[1], format="f", digits=3),
  formatC(rd_bw5$se[1], format="f", digits=3),
  formatC(rd_bw5$pv[1], format="f", digits=3)
))

# 5. Bandwidth = 7
rd_bw7 <- rdrobust(y = df$lfp, x = df$age_c, c = 0, h = 7, p = 1, q = 2)
rob_rows <- c(rob_rows, sprintf(
  "  Fixed bandwidth ($h=7$) & %s & (%s) & [%s] & 7.0 \\\\",
  formatC(rd_bw7$coef[1], format="f", digits=3),
  formatC(rd_bw7$se[1], format="f", digits=3),
  formatC(rd_bw7$pv[1], format="f", digits=3)
))

# 6. Donut-hole
df_donut <- df[!(age %in% c(64, 65))]
rd_donut <- rdrobust(y = df_donut$lfp, x = df_donut$age_c, c = 0, h = 6, p = 1, q = 2)
rob_rows <- c(rob_rows, sprintf(
  "  Donut hole (excl.~ages 64--65) & %s & (%s) & [%s] & 6.0 \\\\",
  formatC(rd_donut$coef[1], format="f", digits=3),
  formatC(rd_donut$se[1], format="f", digits=3),
  formatC(rd_donut$pv[1], format="f", digits=3)
))

# 7. With covariates
rd_cov <- rdrobust(y = df$lfp, x = df$age_c, c = 0,
                   covs = as.matrix(df[, .(female, urban, education)]))
rob_rows <- c(rob_rows, sprintf(
  "  With covariates & %s & (%s) & [%s] & %s \\\\",
  formatC(rd_cov$coef[1], format="f", digits=3),
  formatC(rd_cov$se[1], format="f", digits=3),
  formatC(rd_cov$pv[1], format="f", digits=3),
  formatC(rd_cov$bws[1,1], format="f", digits=1)
))

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness of LFP Estimates to Alternative Specifications}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "  Specification & Estimate & (SE) & [$p$-value] & Bandwidth \\\\",
  "\\hline",
  rob_rows,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications estimate the sharp RDD at age 65 on labor force participation. Row 1 uses CCT optimal bandwidth with triangular kernel. Rows 2--7 vary the kernel, polynomial order, bandwidth, sample, and covariate adjustment. Covariates: sex, urban/rural, years of education. The estimate is stable across all specifications.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5, file.path(tables_dir, "tab5_robustness.tex"))
cat("Written: tab5_robustness.tex\n")

# ============================================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes (full sample)
# SDE = beta / SD(Y) where SD(Y) is pre-treatment SD
pre_sd <- function(var) {
  sd(df[above65 == 0][[var]], na.rm = TRUE)
}

sde_outcomes <- list(
  list(var = "lfp", label = "Labor Force Participation"),
  list(var = "employed", label = "Employment"),
  list(var = "hours", label = "Weekly Hours Worked"),
  list(var = "labor_income", label = "Monthly Labor Income")
)

# Panel A: Pooled
sde_rows_a <- c()
for (o in sde_outcomes) {
  rd <- rdrobust(y = df[[o$var]], x = df$age_c, c = 0)
  beta <- rd$coef[1]
  se_beta <- rd$se[1]
  sd_y <- pre_sd(o$var)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  # Classification
  classify <- function(s) {
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    if (s < -0.005) return("Small negative")
    if (s <= 0.005) return("Null")
    if (s <= 0.05) return("Small positive")
    if (s <= 0.15) return("Moderate positive")
    return("Large positive")
  }

  sde_rows_a <- c(sde_rows_a, sprintf(
    "  %s & %s & %s & %s & %s & %s & %s \\\\",
    o$label,
    formatC(beta, format = "f", digits = 3),
    formatC(se_beta, format = "f", digits = 3),
    formatC(sd_y, format = "f", digits = 3),
    formatC(sde, format = "f", digits = 3),
    formatC(se_sde, format = "f", digits = 3),
    classify(sde)
  ))
}

# Panel B: Heterogeneous (Urban vs Rural for LFP)
sde_rows_b <- c()
for (loc in list(list(val=1, label="Urban"), list(val=0, label="Rural"))) {
  sub <- df[urban == loc$val]
  rd <- rdrobust(y = sub$lfp, x = sub$age_c, c = 0)
  beta <- rd$coef[1]
  se_beta <- rd$se[1]
  sd_y <- sd(sub[above65 == 0]$lfp, na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  sde_rows_b <- c(sde_rows_b, sprintf(
    "  LFP --- %s & %s & %s & %s & %s & %s & %s \\\\",
    loc$label,
    formatC(beta, format = "f", digits = 3),
    formatC(se_beta, format = "f", digits = 3),
    formatC(sd_y, format = "f", digits = 3),
    formatC(sde, format = "f", digits = 3),
    formatC(se_sde, format = "f", digits = 3),
    classify(sde)
  ))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Ecuador. ",
  "\\textbf{Research question:} Does receiving a non-contributory elderly pension at the age-65 eligibility threshold reduce labor force participation among older adults? ",
  "\\textbf{Policy mechanism:} Ecuador's Pensi{\\'o}n Mis Mejores A{\\~n}os provides USD 50--100 per month to individuals aged 65 and older who lack contributory pension coverage and meet a poverty-score threshold, creating a sharp income transfer at a fixed age boundary. ",
  "\\textbf{Outcome definition:} Labor force participation is a binary indicator equal to one if the individual is employed, underemployed, or actively seeking work (ENEMDU condact codes 1--3). ",
  "\\textbf{Treatment:} Binary --- eligibility begins at exact age 65. ",
  "\\textbf{Data:} ENEMDU (Encuesta Nacional de Empleo, Desempleo y Subempleo), INEC Ecuador, 2021 Q3--2023 Q4, individual-level, 106,334 observations aged 55--75. ",
  "\\textbf{Method:} Sharp RDD with local linear regression, triangular kernel, CCT optimal bandwidth, nearest-neighbor variance estimator. ",
  "\\textbf{Sample:} Individuals aged 55--75 from nationally representative quarterly household survey; no income restriction in pooled panel. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (ages 55--64) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "  Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "  \\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sde_rows_a,
  "  \\\\",
  "  \\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Urban/Rural Split)}} \\\\",
  sde_rows_b,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("Written: tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
