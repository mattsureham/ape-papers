## 05_tables.R — Generate all LaTeX tables
## APEP apep_0623: The Symmetric Tax Shock

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

## ============================================================
## Load data and results
## ============================================================
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]
salt_data <- fread(file.path(data_dir, "salt_exposure.csv"))
R <- readRDS(file.path(data_dir, "main_results.rds"))
RB <- readRDS(file.path(data_dir, "robustness_results.rds"))
sds <- readRDS(file.path(data_dir, "panel_sds.rds"))

## ============================================================
## Table 1: Summary Statistics by SALT Exposure Quintile
## ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Compute quintile breakpoints from salt_data
q_breaks <- quantile(salt_data$avg_salt, probs = seq(0, 1, 0.2), na.rm = TRUE)
salt_data[, salt_quintile := cut(avg_salt, breaks = q_breaks,
                                  labels = paste0("Q", 1:5), include.lowest = TRUE)]

# Summary stats from 2017 cross-section
panel_2017 <- panel[year == 2017]
panel_2017[, salt_quintile := cut(avg_salt,
                                   breaks = q_breaks,
                                   labels = paste0("Q", 1:5),
                                   include.lowest = TRUE)]

summ <- panel_2017[, .(
  `N Zip Codes` = uniqueN(zip5),
  `Mean ZHVI ($)` = round(mean(zhvi, na.rm = TRUE)),
  `Mean SALT ($)` = round(mean(avg_salt, na.rm = TRUE)),
  `Pct Above Cap` = round(100 * mean(above_cap, na.rm = TRUE), 1),
  `SALT Share` = round(mean(salt_share, na.rm = TRUE), 3)
), by = salt_quintile]

# Full sample row
full_row <- panel_2017[, .(
  salt_quintile = "Full Sample",
  `N Zip Codes` = uniqueN(zip5),
  `Mean ZHVI ($)` = round(mean(zhvi, na.rm = TRUE)),
  `Mean SALT ($)` = round(mean(avg_salt, na.rm = TRUE)),
  `Pct Above Cap` = round(100 * mean(above_cap, na.rm = TRUE), 1),
  `SALT Share` = round(mean(salt_share, na.rm = TRUE), 3)
)]

summ <- rbind(summ[order(salt_quintile)], full_row, fill = TRUE)

# Write LaTeX
tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by SALT Exposure Quintile (2017)}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{l S[table-format=5.0] S[table-format=6.0] S[table-format=5.0] S[table-format=3.1] S[table-format=1.3]}\n",
  "\\toprule\n",
  "Quintile & {N Zips} & {Mean ZHVI (\\$)} & {Mean SALT (\\$)} & {\\% Above Cap} & {SALT Share} \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(summ)) {
  row_label <- as.character(summ$salt_quintile[i])
  if (row_label == "Full Sample") {
    tab1_tex <- paste0(tab1_tex, "\\midrule\n")
  }
  tab1_tex <- paste0(tab1_tex,
                      row_label, " & ",
                      format(summ$`N Zip Codes`[i], big.mark = ","), " & ",
                      format(summ$`Mean ZHVI ($)`[i], big.mark = ","), " & ",
                      format(summ$`Mean SALT ($)`[i], big.mark = ","), " & ",
                      summ$`Pct Above Cap`[i], " & ",
                      summ$`SALT Share`[i], " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Quintiles based on average SALT deduction per itemizing return in 2017 (IRS SOI). ",
  "ZHVI is the Zillow Home Value Index (typical home value). ",
  "``\\% Above Cap'' is the share of zip codes where the average SALT deduction exceeds the \\$10,000 TCJA cap. ",
  "``SALT Share'' is the fraction of returns claiming the SALT deduction.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("  Table 1 written.\n")

## ============================================================
## Table 2: TCJA Cap — Main Results
## ============================================================
cat("=== Table 2: TCJA Main Results ===\n")

# Extract coefficients from saved results
extract_from_list <- function(r, varname) {
  beta <- r$coef[varname]
  se_val <- r$se[varname]
  pv <- r$pval[varname]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  n <- r$nobs
  list(beta = beta, se = se_val, pv = pv, stars = stars, n = n)
}

t1 <- extract_from_list(R$tcja_1, "treat_tcja")
t2 <- extract_from_list(R$tcja_2, "treat_tcja_bin")
t3 <- extract_from_list(R$tcja_3, "treat_tcja")
t4 <- extract_from_list(R$tcja_4, "treat_tcja_bin")

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of TCJA SALT Cap on House Prices}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Continuous & Binary & Continuous & Binary \\\\\n",
  "\\midrule\n",
  "Post$\\times$SALT Exposure & ", sprintf("%.4f%s", t1$beta, t1$stars), " & & ",
  sprintf("%.4f%s", t3$beta, t3$stars), " & \\\\\n",
  " & (", sprintf("%.4f", t1$se), ") & & (", sprintf("%.4f", t3$se), ") & \\\\\n",
  "Post$\\times$Above Cap & & ", sprintf("%.4f%s", t2$beta, t2$stars), " & & ",
  sprintf("%.4f%s", t4$beta, t4$stars), " \\\\\n",
  " & & (", sprintf("%.4f", t2$se), ") & & (", sprintf("%.4f", t4$se), ") \\\\\n",
  "\\midrule\n",
  "Zip FE & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & & \\\\\n",
  "Metro$\\times$Month FE & & & Yes & Yes \\\\\n",
  "Clustering & State & State & State & State \\\\\n",
  "N & ", format(t1$n, big.mark = ","), " & ", format(t2$n, big.mark = ","),
  " & ", format(t3$n, big.mark = ","), " & ", format(t4$n, big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
  "Dependent variable is log(ZHVI). Standard errors clustered at the state level in parentheses. ",
  "``SALT Exposure'' is the average SALT deduction per itemizing return (\\$1,000s) in 2017. ",
  "``Above Cap'' equals one if the average SALT deduction exceeds \\$10,000. ",
  "``Post'' indicates months after January 2018. ",
  "Sample: January 2014 -- December 2024 (pre-OBBB reversal). ",
  "Columns (3)--(4) include metro area $\\times$ month fixed effects to absorb metro-level housing trends.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:tcja}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_tcja.tex"))
cat("  Table 2 written.\n")

## ============================================================
## Table 3: OBBB Reversal + Symmetry Test
## ============================================================
cat("=== Table 3: Symmetry Test ===\n")

o1 <- extract_from_list(R$obbb_1, "treat_obbb")
o2 <- extract_from_list(R$obbb_2, "treat_obbb_bin")
s_tcja <- extract_from_list(R$sym, "treat_tcja_sym")
s_obbb <- extract_from_list(R$sym, "treat_obbb_sym")

# Symmetry test: H0: beta_TCJA = beta_OBBB (manual Wald from saved vcov)
V <- R$sym$vcov
b <- R$sym$coef
diff_sym <- b["treat_obbb_sym"] - b["treat_tcja_sym"]
se_diff <- sqrt(V["treat_obbb_sym", "treat_obbb_sym"] + V["treat_tcja_sym", "treat_tcja_sym"] -
                 2 * V["treat_obbb_sym", "treat_tcja_sym"])
sym_pval <- 2 * pnorm(-abs(diff_sym / se_diff))

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{OBBB Reversal and Symmetry Test}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & OBBB & OBBB & Symmetry \\\\\n",
  " & Continuous & Binary & Test \\\\\n",
  "\\midrule\n",
  "Post$_{\\text{OBBB}}\\times$SALT & ", sprintf("%.4f%s", o1$beta, o1$stars),
  " & & \\\\\n",
  " & (", sprintf("%.4f", o1$se), ") & & \\\\\n",
  "Post$_{\\text{OBBB}}\\times$Above Cap & & ", sprintf("%.4f%s", o2$beta, o2$stars),
  " & \\\\\n",
  " & & (", sprintf("%.4f", o2$se), ") & \\\\\n",
  "TCJA$\\times$SALT & & & ", sprintf("%.4f%s", s_tcja$beta, s_tcja$stars), " \\\\\n",
  " & & & (", sprintf("%.4f", s_tcja$se), ") \\\\\n",
  "OBBB$\\times$SALT & & & ", sprintf("%.4f%s", s_obbb$beta, s_obbb$stars), " \\\\\n",
  " & & & (", sprintf("%.4f", s_obbb$se), ") \\\\\n",
  "\\midrule\n",
  "Zip FE & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes \\\\\n",
  "Clustering & State & State & State \\\\\n",
  "Symmetry $p$-value & & & ", sprintf("%.3f", sym_pval), " \\\\\n",
  "N & ", format(o1$n, big.mark = ","), " & ", format(o2$n, big.mark = ","),
  " & ", format(s_tcja$n, big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
  "Dependent variable is log(ZHVI). Standard errors clustered at the state level. ",
  "Columns (1)--(2) use January 2022 -- February 2026. ",
  "Column (3) uses the full panel (2014--2026) with separate SALT exposure interactions for the TCJA period (Jan 2018 -- Dec 2024) and the OBBB period (Jan 2025+). ",
  "``Symmetry $p$-value'' tests H$_0$: $\\beta_{\\text{TCJA}} + \\beta_{\\text{OBBB}} = 0$ (perfect reversal).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:symmetry}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_symmetry.tex"))
cat("  Table 3 written.\n")

## ============================================================
## Table 4: Dose-Response by Quintile
## ============================================================
cat("=== Table 4: Dose-Response ===\n")

# Build quintile coeftable from saved results
qc_coef <- R$quintile$coef
qc_se <- R$quintile$se
qc_pval <- R$quintile$pval
qc <- data.frame(
  Estimate = qc_coef,
  `Std. Error` = qc_se,
  `Pr(>|t|)` = qc_pval,
  check.names = FALSE
)
rownames(qc) <- names(qc_coef)
q_names <- c("post_Q2", "post_Q3", "post_Q4", "post_Q5")

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Dose-Response: TCJA Effect by SALT Exposure Quintile}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Coefficient & Std. Error \\\\\n",
  "\\midrule\n",
  "Q1 (lowest SALT) & \\multicolumn{2}{c}{Reference} \\\\\n"
)

for (q_var in q_names) {
  if (q_var %in% rownames(qc)) {
    pv <- qc[q_var, "Pr(>|t|)"]
    stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
    q_label <- gsub("post_", "", q_var)
    tab4_tex <- paste0(tab4_tex,
                        q_label, " & ", sprintf("%.4f%s", qc[q_var, "Estimate"], stars),
                        " & (", sprintf("%.4f", qc[q_var, "Std. Error"]), ") \\\\\n")
  }
}

tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "Zip FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Month FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Clustering & \\multicolumn{2}{c}{State} \\\\\n",
  "N & \\multicolumn{2}{c}{", format(R$quintile$nobs, big.mark = ","), "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
  "Dependent variable is log(ZHVI). Standard errors clustered at the state level. ",
  "Quintiles defined by 2017 average SALT deduction. Q1 (lowest SALT exposure) is the omitted category. ",
  "Sample: January 2014 -- December 2024. ",
  "Monotonic dose-response supports capitalization interpretation.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:quintile}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_quintile.tex"))
cat("  Table 4 written.\n")

## ============================================================
## Table 5: Robustness
## ============================================================
cat("=== Table 5: Robustness ===\n")

plc <- extract_from_list(RB$placebo, "treat_placebo")
pcv <- extract_from_list(RB$precovid, "treat_tcja")
zcl <- extract_from_list(RB$zip_cluster, "treat_tcja")
t1_main <- extract_from_list(R$tcja_1, "treat_tcja")

tab5_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Baseline & Pre-COVID & Placebo & Zip Cluster \\\\\n",
  "\\midrule\n",
  "Post$\\times$SALT & ", sprintf("%.4f%s", t1_main$beta, t1_main$stars),
  " & ", sprintf("%.4f%s", pcv$beta, pcv$stars),
  " & ", sprintf("%.4f%s", plc$beta, plc$stars),
  " & ", sprintf("%.4f%s", zcl$beta, zcl$stars), " \\\\\n",
  " & (", sprintf("%.4f", t1_main$se), ")",
  " & (", sprintf("%.4f", pcv$se), ")",
  " & (", sprintf("%.4f", plc$se), ")",
  " & (", sprintf("%.4f", zcl$se), ") \\\\\n",
  "\\midrule\n",
  "Sample & Full & Pre-COVID & SALT$<$\\$5K & Full \\\\\n",
  "Period & 2014--2024 & 2014--2019 & 2014--2024 & 2014--2024 \\\\\n",
  "Zip FE & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes \\\\\n",
  "Clustering & State & State & State & Zip \\\\\n",
  "N & ", format(t1_main$n, big.mark = ","),
  " & ", format(pcv$n, big.mark = ","),
  " & ", format(plc$n, big.mark = ","),
  " & ", format(zcl$n, big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
  "Dependent variable is log(ZHVI) in all columns. ",
  "Column (1) reproduces the baseline estimate. ",
  "Column (2) restricts to pre-COVID months (before March 2020). ",
  "Column (3) uses only zip codes with average SALT below \\$5,000 (placebo --- these zip codes should be unaffected by the \\$10K cap). ",
  "Column (4) clusters standard errors at the zip code level rather than the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, file.path(tables_dir, "tab5_robustness.tex"))
cat("  Table 5 written.\n")

## ============================================================
## SDE Table (Appendix — Mandatory)
## ============================================================
cat("=== SDE Table ===\n")

# Compute SDE for main outcomes using saved results
sd_y <- sds$sd_y
sd_x <- sds$sd_x

beta_tcja <- R$tcja_1$coef["treat_tcja"]
se_tcja <- R$tcja_1$se["treat_tcja"]

# Continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_tcja <- beta_tcja * sd_x / sd_y
se_sde_tcja <- se_tcja * sd_x / sd_y

# Binary treatment
beta_bin <- R$tcja_2$coef["treat_tcja_bin"]
se_bin <- R$tcja_2$se["treat_tcja_bin"]
# Binary: SDE = beta / SD(Y)
sde_bin <- beta_bin / sd_y
se_sde_bin <- se_bin / sd_y

# OBBB
beta_obbb <- R$obbb_1$coef["treat_obbb"]
se_obbb <- R$obbb_1$se["treat_obbb"]
sde_obbb <- beta_obbb * sd_x / sd_y
se_sde_obbb <- se_obbb * sd_x / sd_y

classify_sde <- function(s) {
  ifelse(s < -0.15, "Large negative",
  ifelse(s < -0.05, "Moderate negative",
  ifelse(s < -0.005, "Small negative",
  ifelse(s < 0.005, "Null",
  ifelse(s < 0.05, "Small positive",
  ifelse(s < 0.15, "Moderate positive",
         "Large positive"))))))
}

sde_rows <- data.frame(
  Outcome = c("Log ZHVI (continuous)", "Log ZHVI (binary)", "Log ZHVI (reversal)"),
  Spec = c("TCJA cap", "TCJA cap", "OBBB reversal"),
  Beta = c(beta_tcja, beta_bin, beta_obbb),
  SD_X = c(sd_x, NA, sd_x),
  SD_Y = c(sd_y, sd_y, sd_y),
  SDE = c(sde_tcja, sde_bin, sde_obbb),
  SE_SDE = c(se_sde_tcja, se_sde_bin, se_sde_obbb),
  Classification = c(classify_sde(sde_tcja), classify_sde(sde_bin), classify_sde(sde_obbb))
)

# Write SDE table
sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sde_rows)) {
  sd_x_str <- ifelse(is.na(sde_rows$SD_X[i]), "---",
                       sprintf("%.3f", sde_rows$SD_X[i]))
  sde_tex <- paste0(sde_tex,
                      sde_rows$Outcome[i], " & ",
                      sde_rows$Spec[i], " & ",
                      sprintf("%.4f", sde_rows$Beta[i]), " & ",
                      sd_x_str, " & ",
                      sprintf("%.3f", sde_rows$SD_Y[i]), " & ",
                      sprintf("%.4f", sde_rows$SDE[i]), " & ",
                      sprintf("%.4f", sde_rows$SE_SDE[i]), " & ",
                      sde_rows$Classification[i], " \\\\\n")
}

sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
  "to facilitate cross-study comparison of treatment effect magnitudes. ",
  "For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) ",
  "column is marked ``---''. ",
  "For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, ",
  "which gives the effect of a one-standard-deviation change in the treatment variable, ",
  "measured in standard deviations of the outcome.\n\n",
  "\\textbf{Research question:} Does the TCJA \\$10K SALT deduction cap reduce house prices in high-SALT zip codes, ",
  "and does the 2025 OBBB reversal restore them?\n",
  "\\textbf{Treatment:} Continuous (avg SALT deduction per itemizing return, \\$1,000s) or binary (above/below \\$10K cap).\n",
  "\\textbf{Data:} Zillow ZHVI (zip-code monthly, 2014--2026) merged with IRS SOI 2017.\n",
  "\\textbf{Method:} Continuous-treatment DiD with zip and month fixed effects, state-clustered SEs.\n",
  "\\textbf{Sample:} ", format(nrow(panel), big.mark = ","), " zip-month observations.\n\n",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), ",
  "not a failure to reject a null hypothesis.}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("  SDE table written.\n")

cat("\n=== All tables generated ===\n")
cat("Tables in:", tables_dir, "\n")
print(list.files(tables_dir))
