# 03_main_analysis.R — Main analysis for apep_0661
# UK Asylum Dispersal and Local Crime: Shift-Share IV

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$csp_name), "CSPs,",
    uniqueN(panel$yq), "quarters\n")

# Helper: make LaTeX table manually
make_tex_row <- function(...) paste(c(...), collapse = " & ") |> paste0(" \\\\")

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("\n=== Table 1: Summary Statistics ===\n")

vars <- c("total_crime", "crime_rate", "asylum_total", "asylum_dispersal",
          "dispersal_rate", "population", "vacancy_share",
          "violence_rate", "theft_rate", "drugs_rate", "public_order_rate")
var_labels <- c("Total recorded crime (quarterly)",
                "Crime rate (per 1,000 pop.)",
                "Asylum seekers supported (total)",
                "Asylum seekers in dispersal",
                "Dispersal rate (per 1,000 pop.)",
                "Population",
                "2011 Census vacancy share",
                "Violence rate (per 1,000)",
                "Theft rate (per 1,000)",
                "Drug offence rate (per 1,000)",
                "Public order rate (per 1,000)")

summ_rows <- character()
for (i in seq_along(vars)) {
  v <- panel[[vars[i]]]
  summ_rows <- c(summ_rows, make_tex_row(
    var_labels[i],
    sprintf("%.3f", mean(v, na.rm = TRUE)),
    sprintf("%.3f", sd(v, na.rm = TRUE)),
    sprintf("%.3f", min(v, na.rm = TRUE)),
    sprintf("%.3f", max(v, na.rm = TRUE)),
    format(sum(!is.na(v)), big.mark = ",")))
}

summ_tex <- c(
  "\\begin{table}[t]", "\\centering", "\\caption{Summary Statistics}", "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lccccc}", "\\hline\\hline",
  "Variable & Mean & SD & Min & Max & N \\\\", "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Crime (CSP-quarter, 2016--2024)}} \\\\",
  summ_rows[1:2], "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel B: Asylum Dispersal}} \\\\",
  summ_rows[3:5], "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel C: Controls \\& Instrument}} \\\\",
  summ_rows[6:7], "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel D: Crime Categories (per 1,000 pop.)}} \\\\",
  summ_rows[8:11],
  "\\hline\\hline", "\\end{tabular}",
  "\\begin{tablenotes}\\small",
  "\\item \\textit{Notes:} Unit of observation is CSP--quarter. Crime data from Home Office Police Recorded Crime open data. Asylum data from Home Office Asy\\_D11. Population from ONS mid-year estimates. Vacancy share from 2011 Census. Sample: 291 CSPs in England and Wales, 2016Q2--2024Q4.",
  "\\end{tablenotes}", "\\end{table}")
writeLines(summ_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 saved.\n")

# =============================================================================
# REGRESSIONS
# =============================================================================
cat("\n=== Running regressions ===\n")

# OLS
ols1 <- feols(crime_rate ~ dispersal_rate | csp_id + time_id,
              cluster = ~csp_id, data = panel)
panel[, log_crime := log(crime_rate + 0.01)]
ols2 <- feols(log_crime ~ dispersal_rate | csp_id + time_id,
              cluster = ~csp_id, data = panel)

# IV
iv1 <- feols(crime_rate ~ 1 | csp_id + time_id | dispersal_rate ~ ssiv,
             cluster = ~csp_id, data = panel)
iv2 <- feols(log_crime ~ 1 | csp_id + time_id | dispersal_rate ~ ssiv,
             cluster = ~csp_id, data = panel)
iv3 <- feols(crime_rate ~ 1 | csp_id + time_id | asylum_rate ~ ssiv,
             cluster = ~csp_id, data = panel)

# First stage
fs <- feols(dispersal_rate ~ ssiv | csp_id + time_id,
            cluster = ~csp_id, data = panel)

cat("\nFirst stage:\n")
cat(sprintf("  Coef on SSIV: %.6f (SE: %.6f, t=%.2f)\n",
            coef(fs)["ssiv"], se(fs)["ssiv"],
            coef(fs)["ssiv"] / se(fs)["ssiv"]))

# Compute first-stage F manually
fs_t <- coef(fs)["ssiv"] / se(fs)["ssiv"]
fs_F <- fs_t^2
cat(sprintf("  First-stage F: %.1f\n", fs_F))

cat("\nMain results:\n")
cat(sprintf("  OLS:  %.4f (%.4f), p=%.4f\n",
            coef(ols1)["dispersal_rate"], se(ols1)["dispersal_rate"],
            pvalue(ols1)["dispersal_rate"]))
cat(sprintf("  IV:   %.4f (%.4f), p=%.4f\n",
            coef(iv1)["fit_dispersal_rate"], se(iv1)["fit_dispersal_rate"],
            pvalue(iv1)["fit_dispersal_rate"]))

# =============================================================================
# TABLE 2: Main Results
# =============================================================================
cat("\n=== Table 2: Main Results ===\n")

# Helper for coefficient rows
coef_row <- function(model, varname, label) {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(
    coef = sprintf("%.3f%s", b, stars),
    se = sprintf("(%.3f)", s)
  )
}

ols1_r <- coef_row(ols1, "dispersal_rate", "")
ols2_r <- coef_row(ols2, "dispersal_rate", "")
iv1_r <- coef_row(iv1, "fit_dispersal_rate", "")
iv2_r <- coef_row(iv2, "fit_dispersal_rate", "")
iv3_r <- coef_row(iv3, "fit_asylum_rate", "")

# First-stage F for IV models
fs_f_disp <- (coef(feols(dispersal_rate ~ ssiv | csp_id + time_id,
                          cluster = ~csp_id, data = panel))["ssiv"] /
              se(feols(dispersal_rate ~ ssiv | csp_id + time_id,
                        cluster = ~csp_id, data = panel))["ssiv"])^2
fs_f_total <- (coef(feols(asylum_rate ~ ssiv | csp_id + time_id,
                           cluster = ~csp_id, data = panel))["ssiv"] /
               se(feols(asylum_rate ~ ssiv | csp_id + time_id,
                         cluster = ~csp_id, data = panel))["ssiv"])^2

tab2 <- c(
  "\\begin{table}[t]", "\\centering",
  "\\caption{Asylum Dispersal and Local Crime: OLS and IV Estimates}",
  "\\label{tab:main}", "\\small",
  "\\begin{tabular}{lccccc}", "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & OLS & OLS & IV & IV & IV \\\\",
  "Dep. var: & Crime rate & log(Crime) & Crime rate & log(Crime) & Crime rate \\\\",
  "\\hline",
  make_tex_row("Dispersal rate", ols1_r$coef, ols2_r$coef,
               iv1_r$coef, iv2_r$coef, ""),
  make_tex_row("", ols1_r$se, ols2_r$se, iv1_r$se, iv2_r$se, ""),
  make_tex_row("Asylum rate (total)", "", "", "", "", iv3_r$coef),
  make_tex_row("", "", "", "", "", iv3_r$se),
  "\\hline",
  make_tex_row("CSP FE", "Yes", "Yes", "Yes", "Yes", "Yes"),
  make_tex_row("Quarter FE", "Yes", "Yes", "Yes", "Yes", "Yes"),
  make_tex_row("First-stage F", "", "",
               sprintf("%.1f", fs_f_disp), sprintf("%.1f", fs_f_disp),
               sprintf("%.1f", fs_f_total)),
  make_tex_row("Observations", format(nobs(ols1), big.mark = ","),
               format(nobs(ols2), big.mark = ","),
               format(nobs(iv1), big.mark = ","),
               format(nobs(iv2), big.mark = ","),
               format(nobs(iv3), big.mark = ",")),
  make_tex_row("R$^2$", sprintf("%.3f", r2(ols1, "ar2")),
               sprintf("%.3f", r2(ols2, "ar2")),
               sprintf("%.3f", r2(iv1, "ar2")),
               sprintf("%.3f", r2(iv2, "ar2")),
               sprintf("%.3f", r2(iv3, "ar2"))),
  "\\hline\\hline", "\\end{tabular}",
  "\\begin{tablenotes}\\small",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Standard errors clustered at CSP level. Instrument: 2011 Census vacancy share $\\times$ national quarterly asylum inflow. Crime rate measured per 1,000 population. Dispersal rate = asylum seekers in dispersal accommodation per 1,000 population. Asylum rate (total) includes all accommodation types.",
  "\\end{tablenotes}", "\\end{table}")
writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 saved.\n")

# =============================================================================
# TABLE 3: Crime Category Decomposition (IV)
# =============================================================================
cat("\n=== Table 3: Crime Decomposition ===\n")

categories <- c("violence_rate", "theft_rate", "criminal_damage_rate",
                 "drugs_rate", "public_order_rate", "robbery_rate")
cat_labels <- c("Violence", "Theft", "Crim. Damage", "Drugs", "Public Order", "Robbery")
cat_means <- sapply(categories, function(v) mean(panel[[v]], na.rm = TRUE))

cat_coefs <- character()
cat_ses <- character()
for (i in seq_along(categories)) {
  m <- feols(as.formula(paste(categories[i], "~ 1 | csp_id + time_id | dispersal_rate ~ ssiv")),
             cluster = ~csp_id, data = panel)
  b <- coef(m)["fit_dispersal_rate"]
  s <- se(m)["fit_dispersal_rate"]
  p <- pvalue(m)["fit_dispersal_rate"]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  cat_coefs[i] <- sprintf("%.3f%s", b, stars)
  cat_ses[i] <- sprintf("(%.3f)", s)
  cat(sprintf("  %s: %.4f (%.4f) p=%.3f\n", cat_labels[i], b, s, p))
}

tab3 <- c(
  "\\begin{table}[t]", "\\centering",
  "\\caption{IV Estimates by Crime Category}", "\\label{tab:categories}", "\\small",
  "\\begin{tabular}{lcccccc}", "\\hline\\hline",
  make_tex_row("", cat_labels),
  make_tex_row("", paste0("(", 1:6, ")")),
  "\\hline",
  make_tex_row("Dispersal rate", cat_coefs),
  make_tex_row("", cat_ses),
  "\\hline",
  make_tex_row("Dep. var. mean", sprintf("%.2f", cat_means)),
  make_tex_row("CSP \\& Quarter FE", rep("Yes", 6)),
  make_tex_row("Observations", rep(format(nrow(panel), big.mark = ","), 6)),
  "\\hline\\hline", "\\end{tabular}",
  "\\begin{tablenotes}\\small",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. IV estimates using 2011 Census vacancy share $\\times$ national asylum inflow as instrument. Standard errors clustered at CSP level. All outcomes per 1,000 population.",
  "\\end{tablenotes}", "\\end{table}")
writeLines(tab3, file.path(tables_dir, "tab3_categories.tex"))
cat("Table 3 saved.\n")

# =============================================================================
# Save results
# =============================================================================
results <- list(
  n_obs = nrow(panel),
  n_csp = uniqueN(panel$csp_name),
  n_quarters = uniqueN(panel$yq),
  n_with_dispersal = uniqueN(panel[asylum_dispersal > 0]$csp_name),
  ols_coef = round(coef(ols1)["dispersal_rate"], 4),
  ols_se = round(se(ols1)["dispersal_rate"], 4),
  ols_p = round(pvalue(ols1)["dispersal_rate"], 4),
  iv_coef = round(coef(iv1)["fit_dispersal_rate"], 4),
  iv_se = round(se(iv1)["fit_dispersal_rate"], 4),
  iv_p = round(pvalue(iv1)["fit_dispersal_rate"], 4),
  first_stage_f = round(fs_F, 1),
  mean_crime_rate = round(mean(panel$crime_rate, na.rm = TRUE), 2),
  mean_dispersal = round(mean(panel$dispersal_rate, na.rm = TRUE), 3)
)
jsonlite::write_json(results, file.path(data_dir, "results.json"), auto_unbox = TRUE)

# Update diagnostics
jsonlite::write_json(list(
  n_obs = nrow(panel),
  n_treated = uniqueN(panel[asylum_dispersal > 0]$csp_name),
  n_pre = length(unique(panel[cal_year < 2020]$yq)),
  n_csp = uniqueN(panel$csp_name)
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
