# 03_main_analysis.R — Main DiD analysis: CRA reclassification effect on mortgage lending
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("Loaded:", nrow(df), "obs,", uniqueN(df$census_tract), "tracts\n")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

pre <- df[year < 2024]

# By treatment status
sum_stats <- pre[, .(
  `Mean Originations`     = round(mean(n_originated, na.rm = TRUE), 1),
  `Mean Approval Rate`    = round(mean(approval_rate, na.rm = TRUE), 3),
  `Mean Denial Rate`      = round(mean(denial_rate, na.rm = TRUE), 3),
  `Mean Loan Amount ($K)` = round(mean(mean_loan_amount, na.rm = TRUE) / 1000, 1),
  `Minority Share`        = round(mean(minority_share, na.rm = TRUE), 3),
  `Mean Rate Spread`      = round(mean(mean_rate_spread, na.rm = TRUE), 3),
  `Income Pct of MSA`     = round(mean(income_pct, na.rm = TRUE), 1),
  `Tract Population`      = round(mean(tract_pop, na.rm = TRUE), 0),
  `Minority Population %` = round(mean(minority_pct, na.rm = TRUE), 1),
  N                       = uniqueN(census_tract)
), by = .(Group = ifelse(treated == 1, "Reclassified", "Control"))]

print(sum_stats)

# Transpose for LaTeX
vars <- setdiff(names(sum_stats), "Group")
tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Means (2018--2023)}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Control & Reclassified \\\\",
  "\\midrule"
)

for (v in vars) {
  ctrl_val <- sum_stats[Group == "Control"][[v]]
  treat_val <- sum_stats[Group == "Reclassified"][[v]]
  tex_lines <- c(tex_lines,
    sprintf("%s & %s & %s \\\\", v,
            formatC(ctrl_val, format = "f", big.mark = ",",
                    digits = ifelse(v == "N" || v == "Tract Population", 0,
                             ifelse(ctrl_val > 10, 1, 3))),
            formatC(treat_val, format = "f", big.mark = ",",
                    digits = ifelse(v == "N" || v == "Tract Population", 0,
                             ifelse(treat_val > 10, 1, 3)))))
}

tex_lines <- c(tex_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre-treatment means for the balanced panel of census tracts in 15 US states, 2018--2023. Reclassified tracts changed LMI status between 2023 and 2024 due to OMB MSA boundary redefinitions. Approval rate is originations divided by total applications. Minority share is the fraction of originated loans to Black or Hispanic borrowers. Rate spread is the difference between the loan APR and the comparable Treasury yield, available for higher-priced loans.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_lines, file.path(tables_dir, "tab1_sumstats.tex"))
cat("Wrote tab1_sumstats.tex\n")

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("\n=== Table 2: Main DiD Results ===\n")

# Outcome variables
outcomes <- list(
  "log_originations" = "Log Originations",
  "approval_rate"    = "Approval Rate",
  "minority_share"   = "Minority Share",
  "log_amount"       = "Log Total Amount",
  "mean_rate_spread" = "Rate Spread"
)

# Run regressions with tract and year FE, clustered at MSA level
models <- list()
for (yvar in names(outcomes)) {
  form <- as.formula(paste0(yvar, " ~ treat_post | census_tract + year"))
  models[[yvar]] <- feols(form, data = df, cluster = "msa_md")
  cat(sprintf("  %s: coef = %.4f, se = %.4f, p = %.4f\n",
              outcomes[[yvar]],
              coef(models[[yvar]])["treat_post"],
              se(models[[yvar]])["treat_post"],
              pvalue(models[[yvar]])["treat_post"]))
}

# Generate LaTeX table
cm <- setNames(
  "Reclassified $\\times$ Post",
  "treat_post"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) formatC(x, format = "d", big.mark = ",")),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = 3),
  list("raw" = "FE: census_tract", "clean" = "Tract FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

options("modelsummary_format_numeric_latex" = "plain")

# Generate table manually with etable for cleaner LaTeX
setFixest_dict(c(
  treat_post = "Reclassified $\\times$ Post",
  log_originations = "Log Originations",
  approval_rate = "Approval Rate",
  minority_share = "Minority Share",
  log_amount = "Log Amount",
  mean_rate_spread = "Rate Spread"
))

etable(models,
  file = file.path(tables_dir, "tab2_main_did.tex"),
  style.tex = style.tex("aer"),
  fitstat = ~ n + r2,
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  title = "Effect of CRA Reclassification on Mortgage Lending",
  label = "tab:main_did",
  notes = c(
    "Standard errors clustered at the MSA/MD level in parentheses.",
    "Sample: balanced panel of census tracts in 12 US states, 2018--2024.",
    "Reclassified tracts changed LMI status due to 2024 OMB MSA boundary redefinitions."
  ),
  replace = TRUE
)
cat("Wrote tab2_main_did.tex\n")

# ============================================================
# Table 3: Asymmetric Effects (Gained vs Lost LMI)
# ============================================================
cat("\n=== Table 3: Gained vs Lost LMI ===\n")

models_asym <- list()
for (yvar in names(outcomes)) {
  form <- as.formula(paste0(yvar, " ~ gained_post + lost_post | census_tract + year"))
  models_asym[[yvar]] <- feols(form, data = df, cluster = "msa_md")
  cat(sprintf("  %s: gained=%.4f (p=%.3f), lost=%.4f (p=%.3f)\n",
              outcomes[[yvar]],
              coef(models_asym[[yvar]])["gained_post"],
              pvalue(models_asym[[yvar]])["gained_post"],
              coef(models_asym[[yvar]])["lost_post"],
              pvalue(models_asym[[yvar]])["lost_post"]))
}

cm_asym <- c(
  "gained_post" = "Gained LMI $\\times$ Post",
  "lost_post"   = "Lost LMI $\\times$ Post"
)

setFixest_dict(c(
  gained_post = "Gained LMI $\\times$ Post",
  lost_post = "Lost LMI $\\times$ Post",
  log_originations = "Log Originations",
  approval_rate = "Approval Rate",
  minority_share = "Minority Share",
  log_amount = "Log Amount",
  mean_rate_spread = "Rate Spread"
))

etable(models_asym,
  file = file.path(tables_dir, "tab3_asymmetric.tex"),
  style.tex = style.tex("aer"),
  fitstat = ~ n + r2,
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  title = "Asymmetric Effects: Gaining vs.\\ Losing CRA Eligibility",
  label = "tab:asymmetric",
  notes = c(
    "Standard errors clustered at the MSA/MD level in parentheses.",
    "Gained LMI: tracts reclassified from non-LMI to LMI in 2024.",
    "Lost LMI: tracts reclassified from LMI to non-LMI in 2024."
  ),
  replace = TRUE
)
cat("Wrote tab3_asymmetric.tex\n")

# ============================================================
# Save diagnostics for validate_v1.py
# ============================================================
diag <- list(
  n_treated = uniqueN(df[treated == 1]$census_tract),
  n_pre     = length(unique(df[year < 2024]$year)),
  n_obs     = nrow(df)
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics:", toJSON(diag, auto_unbox = TRUE), "\n")
