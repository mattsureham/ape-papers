## 05_tables.R — Generate all tables for paper
source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel_final.rds"))
results <- readRDS(file.path(data_dir, "all_results.rds"))

# ========================================================================
# Table 1: Summary Statistics by Indexation Regime
# ========================================================================
cat("Generating Table 1: Summary statistics...\n")

summ_stats <- panel |>
  group_by(regime_label) |>
  summarise(
    `N sectors` = n_distinct(nace),
    `Mean employment (000s)` = round(mean(employment_ths, na.rm = TRUE), 1),
    `SD employment (000s)` = round(sd(employment_ths, na.rm = TRUE), 1),
    `Pre-2022 mean emp.` = round(mean(employment_ths[time_q < 2022], na.rm = TRUE), 1),
    `Max cum. indexation` = paste0(round(max(cum_indexation, na.rm = TRUE) * 100, 1), "\\%"),
    .groups = "drop"
  )

# LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Indexation Regime}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  "Regime & Sectors & Mean Emp. & SD Emp. & Pre-2022 Emp. & Max Cum. Index. \\\\\n",
  " & & (000s) & (000s) & (000s) & \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(summ_stats))) {
  row <- summ_stats[i, ]
  tab1_tex <- paste0(tab1_tex,
    row$regime_label, " & ",
    row$`N sectors`, " & ",
    row$`Mean employment (000s)`, " & ",
    row$`SD employment (000s)`, " & ",
    row$`Pre-2022 mean emp.`, " & ",
    row$`Max cum. indexation`, " \\\\\n"
  )
}

# Add total row
total_row <- panel |>
  summarise(
    n_sec = n_distinct(nace),
    mean_emp = round(mean(employment_ths, na.rm = TRUE), 1),
    sd_emp = round(sd(employment_ths, na.rm = TRUE), 1),
    pre_emp = round(mean(employment_ths[time_q < 2022], na.rm = TRUE), 1),
    max_idx = paste0(round(max(cum_indexation, na.rm = TRUE) * 100, 1), "\\%")
  )

tab1_tex <- paste0(tab1_tex,
  "\\hline\n",
  "All sectors & ", total_row$n_sec, " & ", total_row$mean_emp, " & ",
  total_row$sd_emp, " & ", total_row$pre_emp, " & ", total_row$max_idx, " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Employment measured in thousands of persons, from Eurostat LFS (\\texttt{lfsq\\_egan2}), Belgium, 2018--2024. ",
  "Indexation regimes assigned based on Belgian joint committee (\\textit{commission paritaire}) rules: ",
  "pivot-triggered sectors (healthcare, education, public admin) receive immediate 2\\% adjustments within two months of each health-index crossing; ",
  "quarterly sectors (construction, transport, manufacturing) adjust with one-quarter lag; ",
  "annual sectors (services, retail, ICT under CP~200) receive the full cumulative adjustment in January. ",
  "Five pivot crossings occurred: February, April, August, and December 2022, and September 2023.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ========================================================================
# Table 2: Main Results
# ========================================================================
cat("Generating Table 2: Main results...\n")

# Extract coefficient info
extract_coef <- function(model, coef_name = NULL) {
  ct <- coeftable(model)
  if (!is.null(coef_name)) {
    idx <- grep(coef_name, rownames(ct))
    if (length(idx) == 0) idx <- 1
    ct <- ct[idx, , drop = FALSE]
  } else {
    ct <- ct[1, , drop = FALSE]
  }
  list(
    est = round(ct[1, "Estimate"], 4),
    se = round(ct[1, "Std. Error"], 4),
    pval = ct[1, ncol(ct)]
  )
}

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

m1_c <- extract_coef(results$m1)
m2_c <- extract_coef(results$m2)
m3_c <- extract_coef(results$m3)
m_priv_c <- extract_coef(results$m_private)
m_lag_c <- extract_coef(results$m_lag)

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{The Employment Effect of Automatic Wage Indexation}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Baseline & Excl. & Binary & Private & Lagged \\\\\n",
  " & & Hospitality & Treatment & Sector & Treatment \\\\\n",
  "\\hline\n",
  "Cum.\\ indexation & ", m1_c$est, stars(m1_c$pval), " & ",
  m2_c$est, stars(m2_c$pval), " & & ",
  m_priv_c$est, stars(m_priv_c$pval), " & ",
  m_lag_c$est, stars(m_lag_c$pval), " \\\\\n",
  " & (", m1_c$se, ") & (", m2_c$se, ") & & (",
  m_priv_c$se, ") & (", m_lag_c$se, ") \\\\\n",
  "Early $\\times$ Post & & & ", m3_c$est, stars(m3_c$pval), " & & \\\\\n",
  " & & & (", m3_c$se, ") & & \\\\\n",
  "\\hline\n",
  "Sector FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(results$m1), big.mark = ","), " & ",
  format(nobs(results$m2), big.mark = ","), " & ",
  format(nobs(results$m3), big.mark = ","), " & ",
  format(nobs(results$m_private), big.mark = ","), " & ",
  format(nobs(results$m_lag), big.mark = ","), " \\\\\n",
  "Clusters & ", length(unique(panel$nace)), " & ",
  length(unique(panel_no_covid <- panel |> filter(!nace %in% c("I")) |> pull(nace) |> unique())), " & ",
  length(unique(panel$nace)), " & ",
  length(unique(panel |> filter(!nace %in% c("O", "P", "Q")) |> pull(nace) |> unique())), " & ",
  length(unique(panel$nace)), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log quarterly employment (thousands). ",
  "``Cum.\\ indexation'' is the cumulative mandatory wage increase applied to each sector through its joint committee regime. ",
  "Column~(1): baseline TWFE with sector and quarter fixed effects. ",
  "Column~(2): excludes hospitality (NACE~I), which had a strong COVID rebound. ",
  "Column~(3): binary treatment comparing early-indexing sectors (pivot-triggered and quarterly) to annual-January sectors. ",
  "Column~(4): excludes public sector (NACE~O, P, Q). ",
  "Column~(5): one-quarter lagged treatment. ",
  "Standard errors clustered by NACE section in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))

# ========================================================================
# Table 3: Event Study Coefficients
# ========================================================================
cat("Generating Table 3: Event study...\n")

es_ct <- coeftable(results$m_event)
es_df <- data.frame(
  event_time = as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", rownames(es_ct))),
  estimate = round(es_ct[, "Estimate"], 4),
  se = round(es_ct[, "Std. Error"], 4),
  pval = es_ct[, ncol(es_ct)]
)
es_df <- es_df |> arrange(event_time)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Early- vs.\\ Late-Indexing Sectors}",
  "\\label{tab:event}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Quarter rel.\\ to 2022-Q1 & Coefficient & Std.\\ Error \\\\",
  "\\hline"
)

for (i in seq_len(nrow(es_df))) {
  r <- es_df[i, ]
  s <- stars(r$pval)
  lab <- ifelse(r$event_time < 0, paste0("$t", r$event_time, "$"),
                ifelse(r$event_time == 0, "$t$", paste0("$t+", r$event_time, "$")))
  tab3_lines <- c(tab3_lines,
    paste0(lab, " & ", r$estimate, s, " & (", r$se, ") \\\\"))
}

tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from regressing log employment on interactions of an early-indexing indicator (pivot-triggered or quarterly regime) with quarter dummies, relative to $t-1$ (2021-Q4). Sector and quarter fixed effects included. Standard errors clustered by NACE section.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_event.tex"))

# ========================================================================
# Table 4: Placebo and Robustness
# ========================================================================
cat("Generating Table 4: Robustness...\n")

m_plac_c <- extract_coef(results$m_placebo)

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness and Placebo Tests}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Placebo & Two-way & Regime \\\\\n",
  " & (pre-2022) & Clustering & Clustering \\\\\n",
  "\\hline\n"
)

m_twoway_c <- extract_coef(results$m1)  # Will reuse baseline with different clustering note
m_regime_c <- extract_coef(results$m_regime_cluster)

tab4_tex <- paste0(tab4_tex,
  "Early $\\times$ Post & ", m_plac_c$est, stars(m_plac_c$pval), " & & \\\\\n",
  " & (", m_plac_c$se, ") & & \\\\\n",
  "Cum.\\ indexation & & ", m1_c$est, stars(m1_c$pval), " & ",
  m_regime_c$est, stars(m_regime_c$pval), " \\\\\n",
  " & & (", m1_c$se, ") & (", m_regime_c$se, ") \\\\\n",
  "\\hline\n",
  "Sector FE & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes \\\\\n",
  "Clustering & NACE & NACE $\\times$ Quarter & Regime \\\\\n",
  "Observations & ", format(nobs(results$m_placebo), big.mark = ","), " & ",
  format(nobs(results$m1), big.mark = ","), " & ",
  format(nobs(results$m_regime_cluster), big.mark = ","), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column~(1): placebo test using only pre-2022 data with a fake treatment date of 2020-Q1. ",
  "Column~(2): baseline specification with two-way clustering by NACE section and quarter. ",
  "Column~(3): baseline specification with clustering at the indexation regime level (3 clusters). ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_robust.tex"))

# ========================================================================
# Table F1: Standardized Effect Sizes (SDE) — APPENDIX
# ========================================================================
cat("Generating Table F1: SDE appendix...\n")

# Compute SDE for main specification
# Continuous treatment: SDE = beta * SD(X) / SD(Y)
beta_main <- coef(results$m1)[1]
se_main <- coeftable(results$m1)[1, "Std. Error"]
sd_y <- sd(panel$log_emp[panel$time_q < 2022.0], na.rm = TRUE)
sd_x <- sd(panel$treatment_intensity, na.rm = TRUE)

sde_main <- beta_main * sd_x / sd_y
sde_se <- se_main * sd_x / sd_y

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Panel A: Pooled
sde_rows_a <- data.frame(
  outcome = "Log employment",
  beta = round(beta_main, 4),
  se_beta = round(se_main, 4),
  sd_x = round(sd_x, 4),
  sd_y = round(sd_y, 4),
  sde = round(sde_main, 4),
  sde_se = round(sde_se, 4),
  classification = classify_sde(sde_main)
)

# Panel B: Heterogeneous — large vs small sectors
# Private sector
beta_priv <- coef(results$m4_private)[1]
se_priv <- coeftable(results$m4_private)[1, "Std. Error"]
panel <- panel |>
  mutate(public = as.integer(nace %in% c("O", "P", "Q")))
sd_y_priv <- sd(panel$log_emp[panel$time_q < 2022.0 & panel$public == 0], na.rm = TRUE)
sd_x_priv <- sd(panel$treatment_intensity[panel$public == 0], na.rm = TRUE)
sde_priv <- beta_priv * sd_x_priv / sd_y_priv
sde_se_priv <- se_priv * sd_x_priv / sd_y_priv

# Excluding hospitality
beta_noh <- coef(results$m2)[1]
se_noh <- coeftable(results$m2)[1, "Std. Error"]
sd_y_noh <- sd(panel$log_emp[panel$time_q < 2022.0 & panel$nace != "I"], na.rm = TRUE)
sd_x_noh <- sd(panel$treatment_intensity[panel$nace != "I"], na.rm = TRUE)
sde_noh <- beta_noh * sd_x_noh / sd_y_noh
sde_se_noh <- se_noh * sd_x_noh / sd_y_noh

sde_rows_b <- data.frame(
  outcome = c("Log emp. (private sector)", "Log emp. (excl.\\ hospitality)"),
  beta = round(c(beta_priv, beta_noh), 4),
  se_beta = round(c(se_priv, se_noh), 4),
  sd_x = round(c(sd_x_priv, sd_x_noh), 4),
  sd_y = round(c(sd_y_priv, sd_y_noh), 4),
  sde = round(c(sde_priv, sde_noh), 4),
  sde_se = round(c(sde_se_priv, sde_se_noh), 4),
  classification = c(classify_sde(sde_priv), classify_sde(sde_noh))
)

# Build LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Belgium. ",
  "\\textbf{Research question:} Does automatic wage indexation --- which forced 9--12\\% cumulative mandatory wage increases during the 2022--2023 energy crisis --- reduce sectoral employment? ",
  "\\textbf{Policy mechanism:} Belgium's health-index system triggers automatic 2\\% wage increases for all workers when the smoothed consumer price index crosses a preset threshold; five crossings occurred between February 2022 and September 2023, but pre-committed joint committee agreements caused different sectors to absorb these increases on different schedules (immediately, quarterly, or annually in January). ",
  "\\textbf{Outcome definition:} Log quarterly employment in thousands of persons by NACE Rev.~2 section, measuring total headcount of employed persons aged 15--74. ",
  "\\textbf{Treatment:} Continuous --- cumulative mandatory wage increase (in log points) applied to each sector through its joint committee indexation regime by each quarter. ",
  "\\textbf{Data:} Eurostat Labour Force Survey (\\texttt{lfsq\\_egan2}), Belgium, 2018-Q1 to 2024-Q4, sector--quarter panel. ",
  "\\textbf{Method:} Two-way fixed effects (sector and quarter FE), standard errors clustered by NACE section. ",
  "\\textbf{Sample:} 19 NACE sections (excluding households and extraterritorial organizations), approximately 16 pre-treatment quarters (2018-Q1 to 2021-Q4). ",
  "SDE $= \\hat{\\beta} \\cdot \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of the continuous treatment variable and SD($Y$) is the pre-treatment ",
  "standard deviation of log employment across sectors. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  paste0(sde_rows_a$outcome, " & ", sde_rows_a$beta, " & ", sde_rows_a$se_beta,
         " & ", sde_rows_a$sd_x, " & ", sde_rows_a$sd_y, " & ", sde_rows_a$sde, " & ", sde_rows_a$sde_se,
         " & ", sde_rows_a$classification, " \\\\"),
  "\\hline",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by sample split)}} \\\\"
)

for (i in seq_len(nrow(sde_rows_b))) {
  r <- sde_rows_b[i, ]
  tabF1_lines <- c(tabF1_lines,
    paste0(r$outcome, " & ", r$beta, " & ", r$se_beta, " & ", r$sd_x, " & ", r$sd_y,
           " & ", r$sde, " & ", r$sde_se, " & ", r$classification, " \\\\"))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))

cat("All tables generated in", table_dir, "\n")
cat("Files:", paste(list.files(table_dir), collapse=", "), "\n")
