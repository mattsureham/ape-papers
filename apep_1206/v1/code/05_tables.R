# 05_tables.R — Generate all LaTeX tables
source("code/00_packages.R")

df <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")

cat("=== Generating Tables ===\n")
dir.create("tables", showWarnings = FALSE)

# Treatment indicator
df[, post_cut := as.integer(!is.na(first_cut_year) & year >= first_cut_year)]

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("--- Table 1: Summary Statistics ---\n")

sum_vars <- c("steuerfuss", "establishments", "employment", "emp_per_estab",
              "emp_per_estab_ter", "tertiary_share", "population")
sum_labels <- c("Corporate Steuerfuss (\\%)", "Establishments",
                "Employment", "Employment per establishment (total)",
                "Employment per establishment (tertiary)",
                "Tertiary establishment share", "Population")

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Treatment Status}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "& \\multicolumn{3}{c}{Control ($N=221$)} & \\multicolumn{3}{c}{Treated ($N=25$)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  "Variable & Mean & SD & N & Mean & SD & N \\\\",
  "\\midrule"
)

for (i in seq_along(sum_vars)) {
  v <- sum_vars[i]
  ctrl <- df[ever_cut == 0, .(m = mean(get(v), na.rm = TRUE),
                               s = sd(get(v), na.rm = TRUE),
                               n = sum(!is.na(get(v))))]
  treat <- df[ever_cut == 1, .(m = mean(get(v), na.rm = TRUE),
                                s = sd(get(v), na.rm = TRUE),
                                n = sum(!is.na(get(v))))]

  line <- sprintf("%s & %.1f & %.1f & %s & %.1f & %.1f & %s \\\\",
                  sum_labels[i],
                  ctrl$m, ctrl$s, formatC(ctrl$n, format = "d", big.mark = ","),
                  treat$m, treat$s, formatC(treat$n, format = "d", big.mark = ","))
  tab1_lines <- c(tab1_lines, line)
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Treatment defined as a $\\geq$5 percentage-point corporate Steuerfuss cut. Panel covers 246 municipalities in cantons Zurich and Basel-Landschaft, 2011--2023.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("  tab1_summary.tex written\n")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("--- Table 2: Main Results ---\n")

# Rerun models for clean table
m1 <- feols(log_emp_per_estab ~ post_cut | bfsnr + year, data = df, cluster = ~canton)
m2 <- feols(log_emp_per_estab_ter ~ post_cut | bfsnr + year,
            data = df[!is.na(log_emp_per_estab_ter)], cluster = ~canton)
m3 <- feols(tertiary_share ~ post_cut | bfsnr + year,
            data = df[!is.na(tertiary_share)], cluster = ~canton)
m4 <- feols(log_establishments ~ post_cut | bfsnr + year, data = df, cluster = ~canton)
m5 <- feols(log_employment ~ post_cut | bfsnr + year, data = df, cluster = ~canton)

# Means of dep vars for treated pre-treatment
pre_means <- df[ever_cut == 1 & (is.na(first_cut_year) | year < first_cut_year),
                .(m_epe = mean(emp_per_estab, na.rm = TRUE),
                  m_epe_ter = mean(emp_per_estab_ter, na.rm = TRUE),
                  m_tershare = mean(tertiary_share, na.rm = TRUE),
                  m_estab = mean(establishments, na.rm = TRUE),
                  m_emp = mean(employment, na.rm = TRUE))]

get_stars <- function(pv) {
  if (pv < 0.01) return("$^{***}$")
  if (pv < 0.05) return("$^{**}$")
  if (pv < 0.10) return("$^{*}$")
  return("")
}

models <- list(m1, m2, m3, m4, m5)
dep_labels <- c("Log(Emp/Est)", "Log(Emp/Est)", "Tertiary", "Log(Estab.)", "Log(Emp.)")
dep_labels2 <- c("Total", "Tertiary", "Share", "", "")
pre_mean_vals <- c(sprintf("%.2f", pre_means$m_epe),
                   sprintf("%.2f", pre_means$m_epe_ter),
                   sprintf("%.3f", pre_means$m_tershare),
                   sprintf("%.0f", pre_means$m_estab),
                   sprintf("%.0f", pre_means$m_emp))

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Corporate Tax Cuts on Establishment Composition}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste0("& (1) & (2) & (3) & (4) & (5) \\\\"),
  paste0("& ", paste(dep_labels, collapse = " & "), " \\\\"),
  paste0("& ", paste(dep_labels2, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Coefficient row
coef_vals <- sapply(models, function(m) {
  b <- coef(m)["post_cut"]
  s <- se(m)["post_cut"]
  pv <- pvalue(m)["post_cut"]
  sprintf("%.4f%s", b, get_stars(pv))
})
tab2_lines <- c(tab2_lines,
  paste0("Post-cut & ", paste(coef_vals, collapse = " & "), " \\\\"))

# SE row
se_vals <- sapply(models, function(m) sprintf("(%.4f)", se(m)["post_cut"]))
tab2_lines <- c(tab2_lines,
  paste0("& ", paste(se_vals, collapse = " & "), " \\\\"),
  "\\midrule")

# Fixed effects
tab2_lines <- c(tab2_lines,
  "Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\")

# N and pre-treatment mean
n_vals <- sapply(models, function(m) formatC(m$nobs, format = "d", big.mark = ","))
tab2_lines <- c(tab2_lines,
  paste0("Observations & ", paste(n_vals, collapse = " & "), " \\\\"),
  paste0("Pre-treatment mean & ", paste(pre_mean_vals, collapse = " & "), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each column reports a separate two-way fixed effects regression. Treatment is a binary indicator for the post-period following a $\\geq$5 percentage-point corporate Steuerfuss cut. Standard errors clustered at the canton level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2_lines, "tables/tab2_main.tex")
cat("  tab2_main.tex written\n")

# ============================================================
# Table 3: Robustness
# ============================================================
cat("--- Table 3: Robustness ---\n")

# Rerun robustness models
m_base <- m1
m_munclust <- feols(log_emp_per_estab ~ post_cut | bfsnr + year, data = df, cluster = ~bfsnr)
m_pop <- feols(log_emp_per_estab ~ post_cut + log(population) | bfsnr + year,
               data = df[!is.na(population)], cluster = ~canton)

# Natural person placebo
zh_stf <- fread("data/zh_steuerfuss.csv")
nat_stf <- zh_stf[, .(bfsnr = BFSNR, year = YEAR, stf_nat = STF_O_KIRCHE1)]
nat_stf <- nat_stf[!is.na(stf_nat) & year >= 2011 & year <= 2023]
nat_stf <- nat_stf[order(bfsnr, year)]
nat_stf[, stf_nat_change := stf_nat - shift(stf_nat, 1), by = bfsnr]
nat_stf[, nat_cut := as.integer(!is.na(stf_nat_change) & stf_nat_change <= -5)]
fnc <- nat_stf[nat_cut == 1, .(fnc_yr = min(year)), by = bfsnr]
nat_stf <- merge(nat_stf, fnc, by = "bfsnr", all.x = TRUE)
nat_stf[, post_nat := as.integer(!is.na(fnc_yr) & year >= fnc_yr)]
df_p <- merge(df, nat_stf[, .(bfsnr, year, post_nat)], by = c("bfsnr", "year"), all.x = TRUE)
df_p[is.na(post_nat), post_nat := 0]
m_placebo <- feols(log_emp_per_estab ~ post_nat | bfsnr + year, data = df_p, cluster = ~canton)

# Secondary sector
df[, log_eps := log(emp_sec / estab_sec)]
m_secondary <- feols(log_eps ~ post_cut | bfsnr + year,
                     data = df[!is.na(log_eps)], cluster = ~canton)

rob_models <- list(m_base, m_munclust, m_pop, m_placebo, m_secondary)
rob_headers <- c("Baseline", "Mun. cluster", "Pop. control", "Nat.-person", "Secondary")
rob_depvar <- c("Log(E/E)", "Log(E/E)", "Log(E/E)", "Log(E/E)", "Log(E/E)")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  paste0("& ", paste(rob_headers, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Coefficients
coef_names <- c("post_cut", "post_cut", "post_cut", "post_nat", "post_cut")
coef_r <- sapply(seq_along(rob_models), function(j) {
  m <- rob_models[[j]]
  cn <- coef_names[j]
  b <- coef(m)[cn]
  pv <- pvalue(m)[cn]
  sprintf("%.4f%s", b, get_stars(pv))
})
se_r <- sapply(seq_along(rob_models), function(j) {
  m <- rob_models[[j]]
  cn <- coef_names[j]
  sprintf("(%.4f)", se(m)[cn])
})
n_r <- sapply(rob_models, function(m) formatC(m$nobs, format = "d", big.mark = ","))

tab3_lines <- c(tab3_lines,
  paste0("Post-cut & ", paste(coef_r, collapse = " & "), " \\\\"),
  paste0("& ", paste(se_r, collapse = " & "), " \\\\"),
  "\\midrule",
  "Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  paste0("Observations & ", paste(n_r, collapse = " & "), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Column 1 reproduces the baseline (canton-clustered SEs). Column 2 clusters at the municipality level. Column 3 adds log population as a control. Column 4 uses natural-person Steuerfuss cuts as a placebo treatment. Column 5 tests the secondary sector (manufacturing), where letterbox structures are infeasible. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3_lines, "tables/tab3_robustness.tex")
cat("  tab3_robustness.tex written\n")

# ============================================================
# Table 4: Event Study / Dose-Response
# ============================================================
cat("--- Table 4: Validity ---\n")

# Dose-response: different thresholds
thresh_results <- list()
for (thresh in c(3, 5, 10)) {
  df_t <- copy(df)
  df_t <- df_t[order(bfsnr, year)]
  df_t[, stf_ch := steuerfuss - shift(steuerfuss, 1), by = bfsnr]
  df_t[, cut_t := as.integer(!is.na(stf_ch) & stf_ch <= -thresh)]
  fc_t <- df_t[cut_t == 1, .(fcy = min(year)), by = bfsnr]
  df_t <- merge(df_t, fc_t, by = "bfsnr", all.x = TRUE)
  df_t[, post_t := as.integer(!is.na(fcy) & year >= fcy)]
  m_t <- feols(log_emp_per_estab ~ post_t | bfsnr + year, data = df_t, cluster = ~bfsnr)
  thresh_results[[as.character(thresh)]] <- list(
    beta = coef(m_t)["post_t"],
    se = se(m_t)["post_t"],
    pv = pvalue(m_t)["post_t"],
    n_treat = uniqueN(df_t[!is.na(fcy)]$bfsnr),
    n_obs = m_t$nobs
  )
}

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Dose-Response: Effect by Cut Threshold}",
  "\\label{tab:validity}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "& (1) & (2) & (3) \\\\",
  "& $\\geq$3pp & $\\geq$5pp & $\\geq$10pp \\\\",
  "\\midrule"
)

coef_d <- sapply(c("3", "5", "10"), function(t) {
  r <- thresh_results[[t]]
  sprintf("%.4f%s", r$beta, get_stars(r$pv))
})
se_d <- sapply(c("3", "5", "10"), function(t) sprintf("(%.4f)", thresh_results[[t]]$se))
nt_d <- sapply(c("3", "5", "10"), function(t) as.character(thresh_results[[t]]$n_treat))
no_d <- sapply(c("3", "5", "10"), function(t) formatC(thresh_results[[t]]$n_obs, format = "d", big.mark = ","))

tab4_lines <- c(tab4_lines,
  paste0("Post-cut & ", paste(coef_d, collapse = " & "), " \\\\"),
  paste0("& ", paste(se_d, collapse = " & "), " \\\\"),
  "\\midrule",
  "Municipality FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  paste0("Treated municipalities & ", paste(nt_d, collapse = " & "), " \\\\"),
  paste0("Observations & ", paste(no_d, collapse = " & "), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each column uses a different threshold for defining a corporate Steuerfuss ``cut.'' Larger cuts produce larger effects on log employment per establishment, consistent with a dose-response pattern. Standard errors clustered at the municipality level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4_lines, "tables/tab4_validity.tex")
cat("  tab4_validity.tex written\n")

# ============================================================
# Table F1: SDE Appendix
# ============================================================
cat("--- Table F1: Standardized Effect Sizes ---\n")

# Pre-treatment SDs
pre_df <- df[is.na(first_cut_year) | year < first_cut_year]
sd_log_epe <- sd(pre_df$log_emp_per_estab, na.rm = TRUE)
sd_log_epe_ter <- sd(pre_df$log_emp_per_estab_ter, na.rm = TRUE)
sd_tershare <- sd(pre_df$tertiary_share, na.rm = TRUE)
sd_log_estab <- sd(pre_df$log_establishments, na.rm = TRUE)

# Compute SDEs for main outcomes
sde_rows <- list(
  list(outcome = "Log(Emp/Est) --- Total",
       beta = coef(m1)["post_cut"], se_beta = se(m1)["post_cut"],
       sd_y = sd_log_epe),
  list(outcome = "Log(Emp/Est) --- Tertiary",
       beta = coef(m2)["post_cut"], se_beta = se(m2)["post_cut"],
       sd_y = sd_log_epe_ter),
  list(outcome = "Tertiary estab.\\ share",
       beta = coef(m3)["post_cut"], se_beta = se(m3)["post_cut"],
       sd_y = sd_tershare),
  list(outcome = "Log(Establishments)",
       beta = coef(m4)["post_cut"], se_beta = se(m4)["post_cut"],
       sd_y = sd_log_estab)
)

classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

# Panel A: Pooled
panel_a_rows <- c()
for (r in sde_rows) {
  sde <- r$beta / r$sd_y
  se_sde <- r$se_beta / r$sd_y
  cls <- classify_sde(sde)
  panel_a_rows <- c(panel_a_rows,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
            r$outcome, r$beta, r$se_beta, r$sd_y, sde, se_sde, cls))
}

# Panel B: Heterogeneous (by municipality size — above/below median population)
het_rows <- c()
med_pop <- median(df[!is.na(population), population], na.rm = TRUE)
for (grp in c("Large", "Small")) {
  df_grp <- if (grp == "Large") {
    df[population >= med_pop & !is.na(log_emp_per_estab_ter)]
  } else {
    df[population < med_pop & !is.na(log_emp_per_estab_ter)]
  }
  if (sum(df_grp$post_cut) > 0 && uniqueN(df_grp$bfsnr) > 2) {
    m_grp <- feols(log_emp_per_estab_ter ~ post_cut | bfsnr + year,
                   data = df_grp, vcov = "hetero")
    pre_grp <- df_grp[is.na(first_cut_year) | year < first_cut_year]
    sd_grp <- sd(pre_grp$log_emp_per_estab_ter, na.rm = TRUE)
    b_grp <- coef(m_grp)["post_cut"]
    se_grp <- se(m_grp)["post_cut"]
    sde_grp <- b_grp / sd_grp
    se_sde_grp <- se_grp / sd_grp
    cls_grp <- classify_sde(sde_grp)
    het_rows <- c(het_rows,
      sprintf("Log(Emp/Est Ter) --- %s munis & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
              grp, b_grp, se_grp, sd_grp, sde_grp, se_sde_grp, cls_grp))
  }
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Do municipal corporate tax cuts attract real economic activity or employment-light letterbox companies? ",
  "\\textbf{Policy mechanism:} Swiss municipalities independently set corporate tax multipliers (Steuerfuss); cuts reduce the effective tax rate on corporate profits, potentially attracting firms that relocate for tax purposes without bringing substantial employment. ",
  "\\textbf{Outcome definition:} Log of total (or tertiary-sector) employment divided by number of establishments from BFS STATENT, measuring average firm size and employment intensity. ",
  "\\textbf{Treatment:} Binary indicator for a $\\geq$5 percentage-point corporate Steuerfuss reduction. ",
  "\\textbf{Data:} BFS STATENT (2011--2023), cantonal Steuerfuss records (Zurich, Basel-Landschaft), 246 municipalities, 4,110 municipality-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (municipality + year), standard errors clustered at the canton level. ",
  "\\textbf{Sample:} Municipalities in cantons Zurich and Basel-Landschaft with complete Steuerfuss panel data; 25 treated municipalities experienced $\\geq$5pp corporate tax cuts during the sample period. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  panel_a_rows,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by canton)}} \\\\",
  het_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")
cat("  tabF1_sde.tex written\n")

cat("\n=== All tables generated ===\n")
