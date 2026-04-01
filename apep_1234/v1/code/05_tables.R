## 05_tables.R — Generate all LaTeX tables
## APEP paper apep_1234: FATF Grey-Listing and Panama Banking

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load results
load(file.path(data_dir, "regression_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))
panel <- read_csv(file.path(data_dir, "panel_indicators.csv"), show_col_types = FALSE) %>%
  mutate(date = floor_date(date, "month"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================

summ_df <- panel %>%
  dplyr::filter(treat_group %in% c("International License", "Panamanian Private", "Foreign Private")) %>%
  mutate(period = case_when(
    date < as.Date("2019-06-01") ~ "Pre",
    date < as.Date("2023-10-01") ~ "Grey-listed",
    TRUE ~ "Post-delist"
  ))

# Full-sample summary
full_summ <- summ_df %>%
  dplyr::filter(treat_group %in% c("International License", "Panamanian Private")) %>%
  group_by(treat_group) %>%
  summarise(
    roa_mean = sprintf("%.3f", mean(roa, na.rm = TRUE)),
    roa_sd = sprintf("%.3f", sd(roa, na.rm = TRUE)),
    roaa_mean = sprintf("%.3f", mean(roaa, na.rm = TRUE)),
    roaa_sd = sprintf("%.3f", sd(roaa, na.rm = TRUE)),
    roe_mean = sprintf("%.3f", mean(roe, na.rm = TRUE)),
    roe_sd = sprintf("%.3f", sd(roe, na.rm = TRUE)),
    min_mean = sprintf("%.3f", mean(min, na.rm = TRUE)),
    min_sd = sprintf("%.3f", sd(min, na.rm = TRUE)),
    n = as.character(n()),
    .groups = "drop"
  )

# By period
period_summ <- summ_df %>%
  dplyr::filter(treat_group %in% c("International License", "Panamanian Private")) %>%
  group_by(treat_group, period) %>%
  summarise(
    roa_mean = sprintf("%.3f", mean(roa, na.rm = TRUE)),
    roa_sd = sprintf("%.3f", sd(roa, na.rm = TRUE)),
    roe_mean = sprintf("%.3f", mean(roe, na.rm = TRUE)),
    roe_sd = sprintf("%.3f", sd(roe, na.rm = TRUE)),
    n = as.character(n()),
    .groups = "drop"
  )

# Write Table 1
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Financial Indicators by Bank Type}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{ROA} & \\multicolumn{2}{c}{ROE} & \\multicolumn{2}{c}{Capital Adequacy} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Full Sample (Jan 2016--Feb 2026)}} \\\\[3pt]"
)

for (i in 1:nrow(full_summ)) {
  row <- full_summ[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    row$treat_group, row$roa_mean, row$roa_sd, row$roe_mean, row$roe_sd,
    row$min_mean, row$min_sd
  ))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: By Period}} \\\\[3pt]"
)

for (grp in c("International License", "Panamanian Private")) {
  tab1_lines <- c(tab1_lines, sprintf("\\multicolumn{7}{l}{\\quad %s} \\\\", grp))
  for (per in c("Pre", "Grey-listed", "Post-delist")) {
    row <- period_summ %>% dplyr::filter(treat_group == grp, period == per)
    if (nrow(row) > 0) {
      period_label <- case_when(
        per == "Pre" ~ "\\quad\\quad Pre (Jan 2016--May 2019)",
        per == "Grey-listed" ~ "\\quad\\quad Grey-listed (Jun 2019--Sep 2023)",
        per == "Post-delist" ~ "\\quad\\quad Post-delist (Oct 2023--Feb 2026)"
      )
      tab1_lines <- c(tab1_lines, sprintf(
        "%s & %s & %s & %s & %s & & \\\\",
        period_label, row$roa_mean, row$roa_sd, row$roe_mean, row$roe_sd
      ))
    }
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} ROA is return on assets, ROE is return on equity, and Capital Adequacy is the capital adequacy ratio (MIN). All indicators are monthly percentages reported by the Superintendencia de Bancos de Panam\\'a (SBP). International License banks are restricted to cross-border operations; Panamanian Private banks hold General Licenses with domestic deposit bases. $N$ = 122 bank-type-month observations per group.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 (summary statistics) written.\n")

# ============================================================
# Table 2: Main DiD Results
# ============================================================

# Extract results
get_row <- function(model, varname, label) {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(label = label, coef = sprintf("%.4f%s", b, stars), se = sprintf("(%.4f)", s))
}

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of FATF Grey-Listing on Bank Performance: Difference-in-Differences}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & ROA & ROE & ROAA & Capital Adequacy \\\\",
  "\\midrule"
)

# Grey-listing effect
models <- list(m1_roa, m1_roe, m1_roaa, m1_min)
coefs_grey <- sapply(models, function(m) {
  b <- coef(m)["did"]; s <- se(m)["did"]; p <- pvalue(m)["did"]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  sprintf("%.4f%s", b, stars)
})
ses_grey <- sapply(models, function(m) sprintf("(%.4f)", se(m)["did"]))

coefs_delist <- sapply(models, function(m) {
  b <- coef(m)["did_delist"]; s <- se(m)["did_delist"]; p <- pvalue(m)["did_delist"]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  sprintf("%.4f%s", b, stars)
})
ses_delist <- sapply(models, function(m) sprintf("(%.4f)", se(m)["did_delist"]))

n_obs <- sapply(models, function(m) nobs(m))
r2 <- sapply(models, function(m) sprintf("%.3f", fixest::r2(m, "wr2")))

tab2_lines <- c(tab2_lines,
  sprintf("International $\\times$ Grey-listed & %s & %s & %s & %s \\\\",
          coefs_grey[1], coefs_grey[2], coefs_grey[3], coefs_grey[4]),
  sprintf(" & %s & %s & %s & %s \\\\[6pt]",
          ses_grey[1], ses_grey[2], ses_grey[3], ses_grey[4]),
  sprintf("International $\\times$ Post-delist & %s & %s & %s & %s \\\\",
          coefs_delist[1], coefs_delist[2], coefs_delist[3], coefs_delist[4]),
  sprintf(" & %s & %s & %s & %s \\\\",
          ses_delist[1], ses_delist[2], ses_delist[3], ses_delist[4]),
  "\\midrule",
  "Bank-type FE & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d \\\\", n_obs[1], n_obs[2], n_obs[3], n_obs[4]),
  sprintf("Within $R^2$ & %s & %s & %s & %s \\\\", r2[1], r2[2], r2[3], r2[4]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports a separate DiD regression of the outcome on the interaction of International License bank type with the grey-listing period (June 2019--September 2023) and the post-delisting period (October 2023--February 2026), controlling for bank-type and month fixed effects. The omitted period is pre-treatment (January 2016--May 2019). Driscoll-Kraay standard errors with automatic bandwidth in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 (main DiD) written.\n")

# ============================================================
# Table 3: Robustness
# ============================================================

# Extract key robustness results
rob_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks for Grey-Listing Effect on ROA}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Baseline & Extended & Pre-COVID & DDD \\\\",
  " & & Sample & Window & \\\\",
  "\\midrule"
)

# Baseline (m1_roa)
b1 <- coef(m1_roa)["did"]; s1 <- se(m1_roa)["did"]; p1 <- pvalue(m1_roa)["did"]
st1 <- ifelse(p1 < 0.01, "***", ifelse(p1 < 0.05, "**", ifelse(p1 < 0.1, "*", "")))

# Extended sample (m2_roa)
b2 <- coef(m2_roa)["did"]; s2 <- se(m2_roa)["did"]; p2 <- pvalue(m2_roa)["did"]
st2 <- ifelse(p2 < 0.01, "***", ifelse(p2 < 0.05, "**", ifelse(p2 < 0.1, "*", "")))

# Pre-COVID (m3_roa)
b3 <- coef(m3_roa)["did"]; s3 <- se(m3_roa)["did"]; p3 <- pvalue(m3_roa)["did"]
st3 <- ifelse(p3 < 0.01, "***", ifelse(p3 < 0.05, "**", ifelse(p3 < 0.1, "*", "")))

# DDD (m_ddd_roa)
b4 <- coef(m_ddd_roa)["did_int"]; s4 <- se(m_ddd_roa)["did_int"]; p4 <- pvalue(m_ddd_roa)["did_int"]
st4 <- ifelse(p4 < 0.01, "***", ifelse(p4 < 0.05, "**", ifelse(p4 < 0.1, "*", "")))

rob_lines <- c(rob_lines,
  sprintf("Grey-listing $\\times$ International & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          b1, st1, b2, st2, b3, st3, b4, st4),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\", s1, s2, s3, s4),
  "\\midrule",
  "Bank-type FE & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Control groups & Pan. Priv. & Pan.+For. & Pan. Priv. & Pan.+For. \\\\"),
  sprintf("Sample period & Full & Full & Pre-COVID & Full \\\\"),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(m1_roa), nobs(m2_roa), nobs(m3_roa), nobs(m_ddd_roa)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} The dependent variable is ROA (return on assets). Column (1) is the baseline specification from Table~\\ref{tab:main}. Column (2) adds Foreign Private banks as an additional control group. Column (3) restricts the sample to January 2016--February 2020 (pre-COVID). Column (4) reports a triple-difference specification where both International and Foreign Private banks are compared to Panamanian Private banks. Driscoll-Kraay standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(rob_lines, file.path(tables_dir, "tab3_robustness.tex"))
cat("Table 3 (robustness) written.\n")

# ============================================================
# Table 4: Placebo and De-listing Tests
# ============================================================

plac_b <- coef(placebo_roa)["fake_did"]; plac_s <- se(placebo_roa)["fake_did"]
plac_p <- pvalue(placebo_roa)["fake_did"]
plac_st <- ifelse(plac_p < 0.01, "***", ifelse(plac_p < 0.05, "**", ifelse(plac_p < 0.1, "*", "")))

del_roa_b <- coef(m_delist_roa)["delist_did"]; del_roa_s <- se(m_delist_roa)["delist_did"]
del_roa_p <- pvalue(m_delist_roa)["delist_did"]
del_roa_st <- ifelse(del_roa_p < 0.01, "***", ifelse(del_roa_p < 0.05, "**", ifelse(del_roa_p < 0.1, "*", "")))

del_roe_b <- coef(m_delist_roe)["delist_did"]; del_roe_s <- se(m_delist_roe)["delist_did"]
del_roe_p <- pvalue(m_delist_roe)["delist_did"]
del_roe_st <- ifelse(del_roe_p < 0.01, "***", ifelse(del_roe_p < 0.05, "**", ifelse(del_roe_p < 0.1, "*", "")))

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Placebo Test and De-listing Reversal}",
  "\\label{tab:placebo}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Placebo & De-listing & De-listing \\\\",
  " & ROA & ROA & ROE \\\\",
  "\\midrule",
  sprintf("International $\\times$ Fake grey-listing & %.4f%s & & \\\\", plac_b, plac_st),
  sprintf(" & (%.4f) & & \\\\[6pt]", plac_s),
  sprintf("International $\\times$ Post-delist & & %.4f%s & %.4f%s \\\\", del_roa_b, del_roa_st, del_roe_b, del_roe_st),
  sprintf(" & & (%.4f) & (%.4f) \\\\", del_roa_s, del_roe_s),
  "\\midrule",
  "Bank-type FE & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d \\\\",
          nobs(placebo_roa), nobs(m_delist_roa), nobs(m_delist_roe)),
  "Sample & Pre-treat. & Grey+Post & Grey+Post \\\\",
  "Fake treatment & Jan 2018 & --- & --- \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column (1) assigns a placebo grey-listing date of January 2018 using only the pre-treatment sample (January 2016--May 2019). Columns (2)--(3) estimate the de-listing reversal effect by comparing the grey-listing period (June 2019--September 2023) to the post-delisting period (October 2023--February 2026). Driscoll-Kraay standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_placebo.tex"))
cat("Table 4 (placebo + de-listing) written.\n")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================

# Compute SDE for main outcomes
outcomes <- list(
  list(model = m1_roa, var = "did", outcome = "ROA", yvar = "roa"),
  list(model = m1_roe, var = "did", outcome = "ROE", yvar = "roe"),
  list(model = m1_roaa, var = "did", outcome = "ROAA", yvar = "roaa"),
  list(model = m1_min, var = "did", outcome = "Capital adequacy", yvar = "min")
)

# Pre-treatment SD
pre_df <- df %>% dplyr::filter(date < as.Date("2019-06-01"))

sde_rows_pooled <- lapply(outcomes, function(o) {
  beta <- coef(o$model)[o$var]
  se_beta <- se(o$model)[o$var]
  sd_y <- sd(pre_df[[o$yvar]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  classify <- dplyr::case_when(
    sde < -0.15  ~ "Large negative",
    sde < -0.05  ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <  0.005 ~ "Null",
    sde <  0.05  ~ "Small positive",
    sde <  0.15  ~ "Moderate positive",
    TRUE         ~ "Large positive"
  )
  tibble(
    outcome = o$outcome,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify
  )
}) %>% bind_rows()

# Heterogeneity: Pre-COVID window
pre_covid_beta <- coef(m3_roa)["did"]
pre_covid_se <- se(m3_roa)["did"]
pre_covid_sd_y <- sd(df_precovid$roa[df_precovid$date < as.Date("2019-06-01")], na.rm = TRUE)
pre_covid_sde <- pre_covid_beta / pre_covid_sd_y
pre_covid_se_sde <- pre_covid_se / pre_covid_sd_y
pre_covid_class <- dplyr::case_when(
  pre_covid_sde < -0.15  ~ "Large negative",
  pre_covid_sde < -0.05  ~ "Moderate negative",
  pre_covid_sde < -0.005 ~ "Small negative",
  pre_covid_sde <  0.005 ~ "Null",
  pre_covid_sde <  0.05  ~ "Small positive",
  pre_covid_sde <  0.15  ~ "Moderate positive",
  TRUE                   ~ "Large positive"
)

# Extended sample heterogeneity
ext_beta <- coef(m2_roa)["did"]
ext_se <- se(m2_roa)["did"]
ext_sd_y <- sd(df_ext$roa[df_ext$date < as.Date("2019-06-01")], na.rm = TRUE)
ext_sde <- ext_beta / ext_sd_y
ext_se_sde <- ext_se / ext_sd_y
ext_class <- dplyr::case_when(
  ext_sde < -0.15  ~ "Large negative",
  ext_sde < -0.05  ~ "Moderate negative",
  ext_sde < -0.005 ~ "Small negative",
  ext_sde <  0.005 ~ "Null",
  ext_sde <  0.05  ~ "Small positive",
  ext_sde <  0.15  ~ "Moderate positive",
  TRUE             ~ "Large positive"
)

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Panama. ",
  "\\textbf{Research question:} Does FATF grey-listing differentially reduce profitability for internationally-oriented banks relative to domestically-focused banks within the same jurisdiction? ",
  "\\textbf{Policy mechanism:} FATF grey-listing triggers enhanced due diligence requirements by global banks for all Panamanian counterparties, raising compliance costs for correspondent banking relationships and cross-border transactions disproportionately for banks whose operations are legally restricted to international business. ",
  "\\textbf{Outcome definition:} Monthly return on assets (ROA), return on equity (ROE), return on average assets (ROAA), and capital adequacy ratio (MIN) reported by the Superintendencia de Bancos de Panam\\'a. ",
  "\\textbf{Treatment:} Binary; FATF grey-listing of Panama in June 2019 (removed October 2023). ",
  "\\textbf{Data:} SBP monthly financial indicators by bank license type, January 2016 to February 2026, 244 bank-type-month observations. ",
  "\\textbf{Method:} Two-group difference-in-differences with bank-type and month fixed effects, Driscoll-Kraay standard errors. ",
  "\\textbf{Sample:} International License banks (treatment, restricted to cross-border operations) versus Panamanian Private banks with General Licenses (control, domestic deposit bases). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_rows_pooled)) {
  r <- sde_rows_pooled[i, ]
  sde_tab_lines <- c(sde_tab_lines, sprintf(
    "%s & Baseline & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

sde_tab_lines <- c(sde_tab_lines,
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("ROA & Pre-COVID & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          pre_covid_beta, pre_covid_se, pre_covid_sd_y, pre_covid_sde, pre_covid_se_sde, pre_covid_class),
  sprintf("ROA & Extended sample & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          ext_beta, ext_se, ext_sd_y, ext_sde, ext_se_sde, ext_class),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_tab_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated in:", tables_dir, "\n")
cat("Files:\n")
cat(paste(" ", list.files(tables_dir), collapse = "\n"), "\n")
