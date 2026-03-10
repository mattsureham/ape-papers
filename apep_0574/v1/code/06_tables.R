## 06_tables.R — Publication-quality LaTeX tables
## APEP-0574: Gas Shock Import Substitution
## Inputs:  CSVs from data/
## Outputs: LaTeX .tex files in ../tables/

source("00_packages.R")

data_dir <- "../data/"
tab_dir  <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# =====================================================================
# TABLE 1: Summary Statistics
# =====================================================================
cat("=== Table 1: Summary statistics ===\n")

sumstats <- fread(file.path(data_dir, "summary_stats.csv"))

# Format for display
sumstats[, mean_fmt  := sprintf("%.2f", mean)]
sumstats[, sd_fmt    := sprintf("%.2f", sd)]
sumstats[, min_fmt   := sprintf("%.2f", min)]
sumstats[, max_fmt   := sprintf("%.2f", max)]
sumstats[, n_fmt     := formatC(n, format = "d", big.mark = ",")]

# Clean variable names for display
sumstats[, var_label := fcase(
  variable == "import_mio_eur",      "Extra-EU imports (million EUR)",
  variable == "log_imports",         "Log(extra-EU imports)",
  variable == "gas_dep",             "Russian gas share (2021)",
  variable == "energy_intensive",    "Energy-intensive sector (0/1)",
  variable == "post_shock",          "Post-shock period (0/1)",
  variable == "prod_index",          "Production index (2021 = 100)",
  variable == "energy_intensity_mj", "Energy intensity (MJ/EUR GVA)",
  default = variable
)]

# Split by panel
trade_stats <- sumstats[panel == "trade",
                         .(var_label, mean_fmt, sd_fmt, min_fmt, max_fmt, n_fmt)]
prod_stats  <- sumstats[panel == "production",
                         .(var_label, mean_fmt, sd_fmt, min_fmt, max_fmt, n_fmt)]

# Write LaTeX table
tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Mean & SD & Min & Max & N \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Annual Trade Panel (SITC $\\times$ Country $\\times$ Year)}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(trade_stats))) {
  tex_lines <- c(tex_lines,
    sprintf("%s & %s & %s & %s & %s & %s \\\\",
            trade_stats$var_label[i], trade_stats$mean_fmt[i],
            trade_stats$sd_fmt[i], trade_stats$min_fmt[i],
            trade_stats$max_fmt[i], trade_stats$n_fmt[i]))
}

tex_lines <- c(tex_lines,
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: Monthly Production Panel (NACE $\\times$ Country $\\times$ Month)}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(prod_stats))) {
  tex_lines <- c(tex_lines,
    sprintf("%s & %s & %s & %s & %s & %s \\\\",
            prod_stats$var_label[i], prod_stats$mean_fmt[i],
            prod_stats$sd_fmt[i], prod_stats$min_fmt[i],
            prod_stats$max_fmt[i], prod_stats$n_fmt[i]))
}

tex_lines <- c(tex_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A covers extra-EU imports for five SITC product groups across 27 EU member states, 2017--2024. Panel B covers monthly industrial production indices for nine NACE manufacturing sectors across EU member states, 2019--2024. Russian gas share is the country-level share of natural gas imports from Russia in 2021. Energy-intensive sectors: SITC 5 (chemicals) and SITC 6+8 (manufactured goods) in Panel A; NACE C20 (chemicals), C23 (glass/ceramics), and C24 (basic metals) in Panel B.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_lines, file.path(tab_dir, "tab1_summary_stats.tex"))
cat("  Saved tab1_summary_stats.tex\n")

# =====================================================================
# TABLE 2: Main Triple-Diff Results (Trade Panel)
# =====================================================================
cat("=== Table 2: Main triple-diff results ===\n")

r1       <- fread(file.path(data_dir, "main_tripleDiD_results.csv"))
r1_fit   <- fread(file.path(data_dir, "main_tripleDiD_fit.csv"))

# Helper: format coefficient and stars
format_coef <- function(est, pval) {
  stars <- ifelse(pval < 0.01, "^{***}",
           ifelse(pval < 0.05, "^{**}",
           ifelse(pval < 0.10, "^{*}", "")))
  sprintf("%.3f%s", est, stars)
}
format_se <- function(se_val) sprintf("(%.3f)", se_val)

# Extract triple-interaction for each model
models <- c("triple_did_main", "triple_did_clean", "triple_did_exposure", "triple_did_binary")
model_labels <- c("(1)", "(2)", "(3)", "(4)")

# Get triple-diff coefficient for each
triple_rows <- r1[grepl("gas_dep.*ei.*post|gas_exposure.*ei.*post|gas_dep_binary.*ei.*post", term)]

tex2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Triple-Difference Estimates: Extra-EU Import Substitution}",
  "\\label{tab:triple_did}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", length(models)), collapse = "")),
  "\\toprule",
  sprintf(" & %s \\\\", paste(model_labels, collapse = " & ")),
  "\\midrule",
  sprintf("\\multicolumn{%d}{l}{\\textit{Dependent variable: Log(extra-EU imports, million EUR)}} \\\\",
          length(models) + 1),
  "\\addlinespace"
)

# Row: triple-diff coefficient
coef_vals <- sapply(seq_along(models), function(i) {
  row <- triple_rows[model == models[i]]
  if (nrow(row) > 0) format_coef(row$estimate[1], row$pvalue[1]) else "---"
})
se_vals <- sapply(seq_along(models), function(i) {
  row <- triple_rows[model == models[i]]
  if (nrow(row) > 0) format_se(row$se[1]) else ""
})

# Treatment measure label
treat_labels <- c("Gas share", "Gas share", "Gas exposure", "Binary gas dep.")

tex2 <- c(tex2,
  sprintf("Treatment $\\times$ EI $\\times$ Post & %s \\\\",
          paste(paste0("$", coef_vals, "$"), collapse = " & ")),
  sprintf(" & %s \\\\",
          paste(se_vals, collapse = " & ")),
  "\\addlinespace"
)

# Treatment measure row
tex2 <- c(tex2,
  sprintf("Treatment measure & %s \\\\", paste(treat_labels, collapse = " & ")),
  "\\addlinespace"
)

# Fixed effects rows
fe_rows <- list(
  c("Country $\\times$ Year FE", "Yes", "Yes", "Yes", "No"),
  c("SITC $\\times$ Year FE", "Yes", "Yes", "Yes", "Yes"),
  c("Country $\\times$ SITC FE", "Yes", "Yes", "Yes", "Yes")
)

for (fe in fe_rows) {
  tex2 <- c(tex2, sprintf("%s & %s \\\\", fe[1],
                          paste(fe[2:length(fe)], collapse = " & ")))
}

tex2 <- c(tex2, "\\addlinespace")

# Fit statistics
n_vals <- sapply(seq_along(models), function(i) {
  row <- r1_fit[model == models[i]]
  if (nrow(row) > 0) formatC(row$n_obs[1], format = "d", big.mark = ",") else "---"
})
r2_vals <- sapply(seq_along(models), function(i) {
  row <- r1_fit[model == models[i]]
  if (nrow(row) > 0) sprintf("%.3f", row$r2[1]) else "---"
})

tex2 <- c(tex2,
  sprintf("Observations & %s \\\\", paste(n_vals, collapse = " & ")),
  sprintf("Adj.\\ $R^2$ & %s \\\\", paste(r2_vals, collapse = " & ")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the triple-difference coefficient $\\hat{\\beta}$ from $\\log(\\text{imports})_{cst} = \\beta \\cdot \\text{Treatment}_c \\times \\text{EI}_s \\times \\text{Post}_t + \\gamma \\cdot X + \\text{FE} + \\varepsilon_{cst}$. Column (1): continuous Russian gas share with all two-way interactions. Column (2): two-way interactions absorbed by fixed effects. Column (3): gas exposure = Russian share $\\times$ gas/TPES share. Column (4): binary gas dependence (above/below median). Standard errors clustered at the country level in parentheses. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex2, file.path(tab_dir, "tab2_triple_did.tex"))
cat("  Saved tab2_triple_did.tex\n")

# =====================================================================
# TABLE 3: Production Event Study (Selected Months)
# =====================================================================
cat("=== Table 3: Production event study (selected months) ===\n")

es_prod <- fread(file.path(data_dir, "event_study_production.csv"))

# Select key months for the table
key_months <- c(-12, -6, -3, -1, 0, 1, 3, 6, 12, 18, 24)
es_selected <- es_prod[rel_month %in% key_months]
es_selected <- es_selected[order(rel_month)]

# Map relative months to calendar dates
es_selected[, cal_date := format(as.Date("2022-02-01") %m+% months(rel_month), "%b %Y")]

tex3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Production Event Study: Selected Monthly Coefficients}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Calendar date & Relative month & $\\hat{\\beta}_t$ & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_selected))) {
  row <- es_selected[i]
  stars <- ""
  if (!is.na(row$pvalue)) {
    stars <- ifelse(row$pvalue < 0.01, "$^{***}$",
             ifelse(row$pvalue < 0.05, "$^{**}$",
             ifelse(row$pvalue < 0.10, "$^{*}$", "")))
  }
  tex3 <- c(tex3,
    sprintf("%s & %d & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\",
            row$cal_date, row$rel_month, row$estimate, stars,
            row$se, row$ci_lower, row$ci_upper))
}

# Add observations row
es_fit <- fread(file.path(data_dir, "event_study_fit.csv"))
tex3 <- c(tex3,
  "\\addlinespace",
  sprintf("\\multicolumn{5}{l}{Observations: %s; Clusters (countries): %s} \\\\",
          formatC(es_fit$n_obs[1], format = "d", big.mark = ","),
          ifelse(!is.null(es_fit$n_clusters) && !is.na(es_fit$n_clusters[1]),
                 as.character(es_fit$n_clusters[1]), "27")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from $\\text{Production}_{cst} = \\sum_t \\beta_t \\cdot \\text{Gas dep}_c \\times \\text{EI}_s \\times \\mathbb{1}(t) + \\alpha_{cs} + \\delta_{st} + \\varepsilon_{cst}$, with $t = -1$ (January 2022) as reference. Production index: 2021 = 100, seasonally adjusted. Standard errors clustered at the country level. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex3, file.path(tab_dir, "tab3_event_study.tex"))
cat("  Saved tab3_event_study.tex\n")

# =====================================================================
# TABLE 4: Persistence Test Results
# =====================================================================
cat("=== Table 4: Persistence test ===\n")

persist <- fread(file.path(data_dir, "persistence_results.csv"))

# Extract triple-interaction terms
persist_triple <- persist[grepl("gas_dep.*ei.*(shock|post_norm)", term)]

# Organize by panel and period
persist_triple[, period := fcase(
  grepl("shock_year", term) | grepl("shock_phase", term), "Shock period",
  grepl("post_norm", term), "Post-normalization"
)]
persist_triple[, panel := fcase(
  grepl("trade", model), "Trade",
  grepl("production", model), "Production"
)]

tex4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Persistence of Import Substitution: Shock vs.\\ Post-Normalization}",
  "\\label{tab:persistence}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Trade panel & Production panel \\\\",
  " & Log(imports) & Production index \\\\",
  "\\midrule"
)

# Shock period
for (per in c("Shock period", "Post-normalization")) {
  trade_row <- persist_triple[panel == "Trade" & period == per]
  prod_row  <- persist_triple[panel == "Production" & period == per]

  t_coef <- if (nrow(trade_row) > 0) format_coef(trade_row$estimate[1], trade_row$pvalue[1]) else "---"
  t_se   <- if (nrow(trade_row) > 0) format_se(trade_row$se[1]) else ""
  p_coef <- if (nrow(prod_row) > 0) format_coef(prod_row$estimate[1], prod_row$pvalue[1]) else "---"
  p_se   <- if (nrow(prod_row) > 0) format_se(prod_row$se[1]) else ""

  period_label <- if (per == "Shock period") "Gas dep. $\\times$ EI $\\times$ Shock (2022)" else
                   "Gas dep. $\\times$ EI $\\times$ Post-norm. (2023--24)"

  tex4 <- c(tex4,
    sprintf("%s & $%s$ & $%s$ \\\\", period_label, t_coef, p_coef),
    sprintf(" & %s & %s \\\\", t_se, p_se),
    "\\addlinespace"
  )
}

# Read fit stats for observations
persist_fit <- tryCatch(fread(file.path(data_dir, "persistence_fit.csv")),
                        error = function(e) NULL)
n_trade <- if (!is.null(persist_fit)) formatC(persist_fit[model == "persistence_trade"]$n_obs[1],
                                               format = "d", big.mark = ",") else "1,080"
n_prod  <- if (!is.null(persist_fit)) formatC(persist_fit[model == "persistence_production"]$n_obs[1],
                                               format = "d", big.mark = ",") else "---"

tex4 <- c(tex4,
  "Country $\\times$ Year / NACE $\\times$ Month FE & Yes & Yes \\\\",
  "SITC $\\times$ Year / Country $\\times$ NACE FE & Yes & Yes \\\\",
  "Country $\\times$ SITC FE & Yes & --- \\\\",
  "\\addlinespace",
  sprintf("Observations & %s & %s \\\\", n_trade, n_prod),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} This table tests whether import substitution effects persist after gas prices normalized in 2023--2024. The shock period is 2022 for the trade panel (March--December 2022 for production). The post-normalization period covers 2023--2024. The production panel baseline is restricted to one year pre-shock (March 2021--February 2022) to avoid confounding from COVID-era production disruptions. Standard errors clustered at the country level in parentheses. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex4, file.path(tab_dir, "tab4_persistence.tex"))
cat("  Saved tab4_persistence.tex\n")

# =====================================================================
# SUMMARY
# =====================================================================
cat("\n=== ALL TABLES COMPLETE ===\n")
cat(sprintf("Saved %d tables to %s\n",
            length(list.files(tab_dir, pattern = "\\.tex$")), tab_dir))
