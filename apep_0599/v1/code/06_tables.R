# ============================================================================
# 06_tables.R — Publication-quality LaTeX tables
# Denmark's 2013 Disability Pension Reform (apep_0599)
#
# Inputs:  ../data/panel_benefits.csv, panel_employment.csv,
#          reg_did_main.csv, reg_ddd_main.csv, reg_dose_response.csv,
#          rob_placebo.csv, rob_alt_bandwidth.csv, rob_log_spec.csv,
#          rob_ri.csv, rob_sex_het.csv, reg_models.rds
# Outputs: ../tables/tab1_summary.tex, tab2_did_main.tex, tab3_ddd.tex,
#          tab4_dose_response.tex, tab5_robustness.tex, tab6_sex.tex,
#          tabF1_sde.tex
# ============================================================================

source("00_packages.R")

DATA_DIR  <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

cat("=== 06_tables.R: Generating LaTeX tables ===\n")

# ============================================================================
# Helper: format coefficient with significance stars
# ============================================================================

fmt_coef <- function(est, se, pval, digits = 3) {
  stars <- ""
  if (!is.na(pval)) {
    if (pval < 0.01)      stars <- "***"
    else if (pval < 0.05) stars <- "**"
    else if (pval < 0.1)  stars <- "*"
  }
  coef_str <- paste0(formatC(est, format = "f", digits = digits), stars)
  se_str   <- paste0("(", formatC(se, format = "f", digits = digits), ")")
  c(coef_str, se_str)
}

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

cat("\n--- Table 1: Summary Statistics ---\n")

panel <- fread(file.path(DATA_DIR, "panel_benefits.csv"))
panel_emp <- fread(file.path(DATA_DIR, "panel_employment.csv"))

# Set factor levels
panel[, treat_group := factor(treat_group,
                              levels = c("High (25-39)", "Moderate (40-49)",
                                         "Control (50-59)"))]
panel_emp[, treat_group := factor(treat_group,
                                  levels = c("High (25-39)", "Moderate (40-49)",
                                             "Control (50-59)"))]

# Panel A: Pre-reform (2008-2012), Panel B: Post-reform (2013-2024)
# Benefits panel is quarterly
panel[, period := ifelse(year < 2013, "Pre-reform (2008--2012)",
                         "Post-reform (2013--2025)")]
# Employment panel is annual
panel_emp[, period := ifelse(year < 2013, "Pre-reform (2008--2012)",
                             "Post-reform (2013--2025)")]

# Compute means for benefits panel by treat_group x period
ben_stats <- panel[, .(
  Population     = mean(population, na.rm = TRUE),
  `DP rate`      = mean(rate_fp, na.rm = TRUE),
  `Flex job rate` = mean(rate_fl, na.rm = TRUE),
  `Resource scheme rate` = mean(rate_res, na.rm = TRUE),
  `Cash benefits rate`   = mean(rate_kh, na.rm = TRUE),
  `Sickness benefits rate` = mean(rate_sy, na.rm = TRUE),
  `Unemployment rate`    = mean(rate_ly, na.rm = TRUE)
), by = .(treat_group, period)]

# Compute employment means
emp_stats <- panel_emp[, .(
  `Employment rate` = mean(emp_rate, na.rm = TRUE)
), by = .(treat_group, period)]

# Merge
sum_stats <- merge(ben_stats, emp_stats, by = c("treat_group", "period"), all.x = TRUE)

# Build the table: columns = High, Moderate, Control; rows = variables
# Do one panel per period
make_summary_panel <- function(dt, period_label) {
  dt_sub <- dt[period == period_label]
  # Ensure column order
  dt_sub <- dt_sub[order(treat_group)]

  vars <- c("Population", "DP rate", "Flex job rate", "Resource scheme rate",
            "Cash benefits rate", "Sickness benefits rate",
            "Unemployment rate", "Employment rate")

  out <- data.frame(Variable = vars, stringsAsFactors = FALSE)

  for (grp in c("High (25-39)", "Moderate (40-49)", "Control (50-59)")) {
    row_data <- dt_sub[treat_group == grp]
    vals <- c()
    for (v in vars) {
      val <- row_data[[v]]
      if (length(val) == 0 || is.na(val)) {
        vals <- c(vals, "--")
      } else if (v == "Population") {
        vals <- c(vals, formatC(round(val), format = "d", big.mark = ","))
      } else {
        vals <- c(vals, formatC(val, format = "f", digits = 2))
      }
    }
    out[[grp]] <- vals
  }
  out
}

panel_a <- make_summary_panel(sum_stats, "Pre-reform (2008--2012)")
panel_b <- make_summary_panel(sum_stats, "Post-reform (2013--2025)")

# Build LaTeX manually for proper panel structure
tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Treatment Group and Period}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{l*{3}{c}}",
  "\\toprule",
  " & High (25--39) & Moderate (40--49) & Control (50--59) \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Pre-reform (2008--2012)}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(panel_a))) {
  tex_lines <- c(tex_lines, paste0(
    panel_a$Variable[i], " & ",
    panel_a[["High (25-39)"]][i], " & ",
    panel_a[["Moderate (40-49)"]][i], " & ",
    panel_a[["Control (50-59)"]][i], " \\\\"
  ))
}

tex_lines <- c(tex_lines,
  "\\addlinespace",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Post-reform (2013--2025)}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(panel_b))) {
  tex_lines <- c(tex_lines, paste0(
    panel_b$Variable[i], " & ",
    panel_b[["High (25-39)"]][i], " & ",
    panel_b[["Moderate (40-49)"]][i], " & ",
    panel_b[["Control (50-59)"]][i], " \\\\"
  ))
}

tex_lines <- c(tex_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Unweighted means of municipality-level quarterly rates per 1,000 population, except Population (mean quarterly count) and Employment rate (annual percentage from RAS200, available through 2024). Pre-reform: 2008Q1--2012Q4; post-reform: 2013Q1--2025Q3 for benefit variables, 2013--2024 for employment. Treatment groups defined by age: High (25--39), Moderate (40--49), Control (50--59). DP = disability pension. Figures 1--2 show population-weighted national averages, which may differ from unweighted municipality means reported here. Source: Statistics Denmark (StatBank).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_lines, file.path(TABLE_DIR, "tab1_summary.tex"))
cat("  Saved: tab1_summary.tex\n")

# ============================================================================
# Table 2: Main DiD Results
# ============================================================================

cat("\n--- Table 2: Main DiD Results ---\n")

did_main <- fread(file.path(DATA_DIR, "reg_did_main.csv"))

# Try to load model objects for richer table; fall back to CSV
models_loaded <- FALSE
tryCatch({
  all_models <- readRDS(file.path(DATA_DIR, "reg_models.rds"))
  did_models <- all_models$did
  if (!is.null(did_models) && length(did_models) > 0) {
    models_loaded <- TRUE
  }
}, error = function(e) {
  cat("  Note: Could not load reg_models.rds; using CSV fallback.\n")
})

if (models_loaded) {
  # Use fixest::etable for proper formatting
  # Define the order we want
  outcome_order <- c("rate_fp", "rate_fl", "rate_res", "rate_kh", "rate_sy", "rate_ja")
  outcome_labels <- c("DP Rate", "Flex Jobs", "Resource Sch.", "Cash Ben.",
                       "Sickness", "Job Clar.")

  # Filter to available models
  avail <- intersect(outcome_order, names(did_models))
  mod_list <- did_models[avail]
  col_labels <- outcome_labels[match(avail, outcome_order)]

  etable_tex <- etable(
    mod_list,
    headers = col_labels,
    se.below = TRUE,
    signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
    fitstat = c("n", "r2"),
    style.tex = style.tex(
      depvar.title = "",
      fixef.title = "\\midrule",
      fixef.suffix = " FE",
      yesNo = c("Yes", "No"),
      tablefoot = FALSE
    ),
    tex = TRUE,
    file = file.path(TABLE_DIR, "tab2_did_main.tex"),
    replace = TRUE
  )
  cat("  Saved: tab2_did_main.tex (via etable)\n")

} else {
  # Manual construction from CSV
  cat("  Building Table 2 from CSV...\n")
  outcome_order <- c("Disability Pension", "Flex Jobs", "Rehabilitation",
                     "Cash Benefits", "Sickness Benefits", "Job Clarification")
  col_labels <- c("DP Rate", "Flex Jobs", "Resource Sch.",
                  "Cash Ben.", "Sickness", "Job Clar.")

  tex2 <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Difference-in-Differences Estimates: Young (25--39) vs.\\ Control (50--59)}",
    "\\label{tab:did_main}",
    "\\small",
    paste0("\\begin{tabular}{l*{", length(outcome_order), "}{c}}"),
    "\\toprule",
    paste0(" & ", paste(col_labels, collapse = " & "), " \\\\"),
    paste0(" & ", paste(rep("(per 1,000)", length(col_labels)), collapse = " & "), " \\\\"),
    "\\midrule"
  )

  # Coefficient row
  coef_vals <- c()
  se_vals   <- c()
  n_vals    <- c()

  for (oc in outcome_order) {
    row <- did_main[outcome == oc & grepl("young.*post", term)]
    if (nrow(row) > 0) {
      fc <- fmt_coef(row$estimate[1], row$std_error[1], row$p_value[1])
      coef_vals <- c(coef_vals, fc[1])
      se_vals   <- c(se_vals, fc[2])
      n_vals    <- c(n_vals, formatC(row$nobs[1], format = "d", big.mark = ","))
    } else {
      coef_vals <- c(coef_vals, "--")
      se_vals   <- c(se_vals, "")
      n_vals    <- c(n_vals, "--")
    }
  }

  tex2 <- c(tex2,
    paste0("Young $\\times$ Post & ", paste(coef_vals, collapse = " & "), " \\\\"),
    paste0(" & ", paste(se_vals, collapse = " & "), " \\\\"),
    "\\midrule",
    paste0("Observations & ", paste(n_vals, collapse = " & "), " \\\\"),
    paste0("Age group FE & ", paste(rep("Yes", length(outcome_order)), collapse = " & "), " \\\\"),
    paste0("Quarter FE & ", paste(rep("Yes", length(outcome_order)), collapse = " & "), " \\\\"),
    paste0("Clustering & ", paste(rep("Municipality", length(outcome_order)), collapse = " & "), " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}",
    "\\small",
    "\\item \\textit{Notes:} Each column reports the coefficient on Young $\\times$ Post from a separate DiD regression. Young = ages 25--39 (treatment); Control = ages 50--59 (comparison). Post = 2013Q1 onward. Outcomes are quarterly rates per 1,000 population. Standard errors clustered at the municipality level in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tex2, file.path(TABLE_DIR, "tab2_did_main.tex"))
  cat("  Saved: tab2_did_main.tex (CSV fallback)\n")
}

# ============================================================================
# Table 3: Triple-Difference Results
# ============================================================================

cat("\n--- Table 3: Triple-Difference (DDD) Results ---\n")

ddd_main <- fread(file.path(DATA_DIR, "reg_ddd_main.csv"))

# Filter to the triple-interaction term
ddd_triple <- ddd_main[grepl("young.*post.*high_base_dp", term)]

outcome_order_ddd <- c("Disability Pension", "Flex Jobs", "Cash Benefits", "Rehabilitation")
col_labels_ddd <- c("DP Rate", "Flex Jobs", "Cash Ben.", "Resource Sch.")

tex3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Triple-Difference Estimates: Young $\\times$ Post $\\times$ High Baseline DP}",
  "\\label{tab:ddd}",
  "\\small",
  paste0("\\begin{tabular}{l*{", length(outcome_order_ddd), "}{c}}"),
  "\\toprule",
  paste0(" & ", paste(col_labels_ddd, collapse = " & "), " \\\\"),
  paste0(" & ", paste(rep("(per 1,000)", length(col_labels_ddd)), collapse = " & "), " \\\\"),
  "\\midrule"
)

coef_vals3 <- c()
se_vals3   <- c()
n_vals3    <- c()

for (oc in outcome_order_ddd) {
  row <- ddd_triple[outcome == oc]
  if (nrow(row) > 0) {
    fc <- fmt_coef(row$estimate[1], row$std_error[1], row$p_value[1])
    coef_vals3 <- c(coef_vals3, fc[1])
    se_vals3   <- c(se_vals3, fc[2])
    n_vals3    <- c(n_vals3, formatC(row$nobs[1], format = "d", big.mark = ","))
  } else {
    coef_vals3 <- c(coef_vals3, "--")
    se_vals3   <- c(se_vals3, "")
    n_vals3    <- c(n_vals3, "--")
  }
}

tex3 <- c(tex3,
  paste0("Young $\\times$ Post $\\times$ High Baseline & ",
         paste(coef_vals3, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_vals3, collapse = " & "), " \\\\"),
  "\\midrule",
  paste0("Observations & ", paste(n_vals3, collapse = " & "), " \\\\"),
  paste0("Age $\\times$ Municipality FE & ", paste(rep("Yes", length(outcome_order_ddd)), collapse = " & "), " \\\\"),
  paste0("Age $\\times$ Quarter FE & ", paste(rep("Yes", length(outcome_order_ddd)), collapse = " & "), " \\\\"),
  paste0("Municipality $\\times$ Quarter FE & ", paste(rep("Yes", length(outcome_order_ddd)), collapse = " & "), " \\\\"),
  paste0("Clustering & ", paste(rep("Municipality", length(outcome_order_ddd)), collapse = " & "), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the triple-interaction coefficient from a DDD specification: $Y_{amt} = \\beta \\cdot \\text{Young}_a \\times \\text{Post}_t \\times \\text{HighBaseline}_m + \\text{FE} + \\varepsilon_{amt}$. HighBaseline is a binary indicator equal to one for municipalities with above-median pre-reform mean DP rate among 25--39 year-olds (49 high, 49 low municipalities). Young = ages 25--39; Control = ages 50--59. Post = 2013Q1 onward. Outcomes are quarterly rates per 1,000 population. Standard errors clustered at the municipality level in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex3, file.path(TABLE_DIR, "tab3_ddd.tex"))
cat("  Saved: tab3_ddd.tex\n")

# ============================================================================
# Table 4: Dose-Response
# ============================================================================

cat("\n--- Table 4: Dose-Response ---\n")

dose <- fread(file.path(DATA_DIR, "reg_dose_response.csv"))

dose_outcomes <- c("Disability Pension", "Flex Jobs", "Rehabilitation")
dose_col_labels <- c("DP Rate", "Flex Jobs", "Resource Sch.")

tex4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Dose-Response Estimates: High vs.\\ Moderate Treatment Intensity}",
  "\\label{tab:dose_response}",
  "\\small",
  paste0("\\begin{tabular}{l*{", length(dose_outcomes), "}{c}}"),
  "\\toprule",
  paste0(" & ", paste(dose_col_labels, collapse = " & "), " \\\\"),
  paste0(" & ", paste(rep("(per 1,000)", length(dose_col_labels)), collapse = " & "), " \\\\"),
  "\\midrule"
)

# High x Post row
coef_high <- c()
se_high   <- c()
coef_mod  <- c()
se_mod    <- c()
n_vals4   <- c()

for (oc in dose_outcomes) {
  # High x Post
  h_row <- dose[outcome == oc & grepl("high.*post|post.*high", term, ignore.case = TRUE)]
  if (nrow(h_row) > 0) {
    fc <- fmt_coef(h_row$estimate[1], h_row$std_error[1], h_row$p_value[1])
    coef_high <- c(coef_high, fc[1])
    se_high   <- c(se_high, fc[2])
  } else {
    coef_high <- c(coef_high, "--")
    se_high   <- c(se_high, "")
  }

  # Moderate x Post
  m_row <- dose[outcome == oc & grepl("moderate.*post|post.*moderate", term, ignore.case = TRUE)]
  if (nrow(m_row) > 0) {
    fc <- fmt_coef(m_row$estimate[1], m_row$std_error[1], m_row$p_value[1])
    coef_mod <- c(coef_mod, fc[1])
    se_mod   <- c(se_mod, fc[2])
    n_vals4  <- c(n_vals4, formatC(m_row$nobs[1], format = "d", big.mark = ","))
  } else {
    coef_mod <- c(coef_mod, "--")
    se_mod   <- c(se_mod, "")
    n_vals4  <- c(n_vals4, "--")
  }
}

tex4 <- c(tex4,
  paste0("High (25--39) $\\times$ Post & ",
         paste(coef_high, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_high, collapse = " & "), " \\\\"),
  "\\addlinespace",
  paste0("Moderate (40--49) $\\times$ Post & ",
         paste(coef_mod, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_mod, collapse = " & "), " \\\\"),
  "\\midrule",
  paste0("Observations & ", paste(n_vals4, collapse = " & "), " \\\\"),
  paste0("Age group FE & ", paste(rep("Yes", length(dose_outcomes)), collapse = " & "), " \\\\"),
  paste0("Quarter FE & ", paste(rep("Yes", length(dose_outcomes)), collapse = " & "), " \\\\"),
  paste0("Clustering & ", paste(rep("Municipality", length(dose_outcomes)), collapse = " & "), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each column reports coefficients from a dose-response regression including all three age groups: High (25--39), Moderate (40--49), and Control (50--59, reference). Monotonic ordering ($|\\hat{\\beta}_{\\text{High}}| > |\\hat{\\beta}_{\\text{Moderate}}|$) supports a dose-response interpretation. Outcomes are quarterly rates per 1,000 population. Standard errors clustered at the municipality level in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex4, file.path(TABLE_DIR, "tab4_dose_response.tex"))
cat("  Saved: tab4_dose_response.tex\n")

# ============================================================================
# Table 5: Robustness Summary
# ============================================================================

cat("\n--- Table 5: Robustness Summary ---\n")

rob_placebo   <- fread(file.path(DATA_DIR, "rob_placebo.csv"))
rob_bw        <- fread(file.path(DATA_DIR, "rob_alt_bandwidth.csv"))
rob_log       <- fread(file.path(DATA_DIR, "rob_log_spec.csv"))
rob_ri        <- fread(file.path(DATA_DIR, "rob_ri.csv"))

rob_col_labels <- c("DP Rate", "Flex Jobs", "Resource Sch.")
rob_outcomes_dp <- c("Disability Pension", "Disability Pension (log)")
rob_outcomes_fl <- c("Flex Jobs", "Flex Jobs (log)")
rob_outcomes_res <- c("Resource Scheme", "Rehabilitation")

# Helper: find coefficient for a given outcome in a dataset
find_coef <- function(dt, outcome_patterns, digits = 3) {
  for (pat in outcome_patterns) {
    rows <- dt[grepl(pat, outcome, ignore.case = TRUE)]
    if (nrow(rows) > 0) {
      # Pick the interaction term row
      int_row <- rows[grepl("young|high|narrow|wide|post", term, ignore.case = TRUE)]
      if (nrow(int_row) > 0) {
        return(fmt_coef(int_row$estimate[1], int_row$std_error[1],
                        int_row$p_value[1], digits))
      }
    }
  }
  return(c("---", "---"))
}

# Row 1: Placebo timing (2010)
plac_dp  <- find_coef(rob_placebo, c("Disability Pension"))
plac_fl  <- find_coef(rob_placebo, c("Flex Jobs"))
# Placebo may not have resource scheme
plac_res <- find_coef(rob_placebo, c("Resource Scheme", "Rehabilitation", "Resource"))

# Row 2: Narrow bandwidth (30-34 vs 50-54)
narrow <- rob_bw[grepl("Narrow", spec)]
nar_dp  <- find_coef(narrow, c("Disability Pension"))
nar_res <- find_coef(narrow, c("Resource Scheme", "Rehabilitation", "Resource"))
# Narrow bandwidth may not have flex jobs
nar_fl  <- find_coef(narrow, c("Flex Jobs"))

# Row 3: Wide bandwidth (25-39 vs 45-59)
wide <- rob_bw[grepl("Wide", spec)]
wide_dp  <- find_coef(wide, c("Disability Pension"))
wide_res <- find_coef(wide, c("Resource Scheme", "Rehabilitation", "Resource"))
wide_fl  <- find_coef(wide, c("Flex Jobs"))

# Row 4: Log specification
log_dp  <- find_coef(rob_log, c("Disability Pension"))
log_fl  <- find_coef(rob_log, c("Flex Jobs"))
log_res <- find_coef(rob_log, c("Resource Scheme", "Rehabilitation", "Resource"))

# Row 5: RI p-value (single value for DP)
ri_actual <- rob_ri[is_actual == TRUE]
ri_pval <- if (nrow(ri_actual) > 0) {
  formatC(ri_actual$ri_pvalue[1], format = "f", digits = 3)
} else {
  "--"
}

tex5 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{l*{3}{c}}",
  "\\toprule",
  paste0(" & ", paste(rob_col_labels, collapse = " & "), " \\\\"),
  "\\midrule",
  "\\addlinespace",
  "\\multicolumn{4}{l}{\\textit{Panel A: Placebo and Bandwidth}} \\\\",
  "\\addlinespace",
  # Row 1: Placebo
  paste0("Placebo (2010) & ", plac_dp[1], " & ", plac_fl[1], " & ", plac_res[1], " \\\\"),
  paste0(" & ", plac_dp[2], " & ", plac_fl[2], " & ", plac_res[2], " \\\\"),
  "\\addlinespace",
  # Row 2: Narrow
  paste0("Narrow bandwidth (30--34 vs 50--54) & ", nar_dp[1], " & ", nar_fl[1], " & ", nar_res[1], " \\\\"),
  paste0(" & ", nar_dp[2], " & ", nar_fl[2], " & ", nar_res[2], " \\\\"),
  "\\addlinespace",
  # Row 3: Wide
  paste0("Wide bandwidth (25--39 vs 45--59) & ", wide_dp[1], " & ", wide_fl[1], " & ", wide_res[1], " \\\\"),
  paste0(" & ", wide_dp[2], " & ", wide_fl[2], " & ", wide_res[2], " \\\\"),
  "\\addlinespace",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Alternative Specifications}} \\\\",
  "\\addlinespace",
  # Row 4: Log
  paste0("Log specification & ", log_dp[1], " & ", log_fl[1], " & ", log_res[1], " \\\\"),
  paste0(" & ", log_dp[2], " & ", log_fl[2], " & ", log_res[2], " \\\\"),
  "\\addlinespace",
  # Row 5: RI p-value
  paste0("Randomization inference $p$-value & ", ri_pval, " & --- & --- \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports coefficients from alternative placebo timing and sample bandwidth specifications. The placebo test assigns a false reform date of 2010Q1 and estimates the DiD on the pre-reform sample (2008--2012). Narrow bandwidth restricts ages to 30--34 (treated) vs.\\ 50--54 (control); wide bandwidth uses 25--39 vs.\\ 45--59. Panel B reports alternative functional forms. The log specification uses $\\log(\\text{rate} + 0.1)$ as the outcome. The randomization inference (RI) $p$-value is computed from 500 permutations of treatment assignment for the disability pension outcome. ``---'' indicates the specification is not applicable for that outcome: the resource scheme did not exist before 2013, precluding placebo or log-transformed estimates with meaningful variation; flex job alternative bandwidths use different age-group definitions that do not isolate flex-specific variation. Standard errors clustered at the municipality level in parentheses. Main specification $N = 34{,}790$; placebo $N$ restricted to pre-reform quarters; alternative bandwidths modify the age group composition. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex5, file.path(TABLE_DIR, "tab5_robustness.tex"))
cat("  Saved: tab5_robustness.tex\n")

# ============================================================================
# Table 6: Sex Heterogeneity
# ============================================================================

cat("\n--- Table 6: Sex Heterogeneity ---\n")

sex_het <- fread(file.path(DATA_DIR, "rob_sex_het.csv"))

sex_outcomes <- c("Disability Pension", "Flex Jobs")
sex_labels   <- c("DP Rate", "Flex Jobs")

tex6 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Sex}",
  "\\label{tab:sex}",
  "\\small",
  "\\begin{tabular}{l*{2}{c}}",
  "\\toprule",
  " & Men & Women \\\\",
  "\\midrule"
)

for (i in seq_along(sex_outcomes)) {
  oc <- sex_outcomes[i]
  lab <- sex_labels[i]

  men_row <- sex_het[outcome == oc & sex == "Men" & grepl("young.*post", term)]
  women_row <- sex_het[outcome == oc & sex == "Women" & grepl("young.*post", term)]

  if (nrow(men_row) > 0) {
    fc_m <- fmt_coef(men_row$estimate[1], men_row$std_error[1], men_row$p_value[1])
  } else {
    fc_m <- c("--", "")
  }

  if (nrow(women_row) > 0) {
    fc_w <- fmt_coef(women_row$estimate[1], women_row$std_error[1], women_row$p_value[1])
  } else {
    fc_w <- c("--", "")
  }

  tex6 <- c(tex6,
    paste0(lab, " & ", fc_m[1], " & ", fc_w[1], " \\\\"),
    paste0(" & ", fc_m[2], " & ", fc_w[2], " \\\\")
  )

  if (i < length(sex_outcomes)) {
    tex6 <- c(tex6, "\\addlinespace")
  }
}

# N from any row
n_sex <- if (nrow(sex_het) > 0) {
  formatC(sex_het$nobs[1], format = "d", big.mark = ",")
} else {
  "--"
}

tex6 <- c(tex6,
  "\\midrule",
  paste0("Observations & ", n_sex, " & ", n_sex, " \\\\"),
  "Age group FE & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes \\\\",
  "Clustering & Municipality & Municipality \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each cell reports the Young $\\times$ Post coefficient from a separate DiD regression estimated on the indicated sex subsample. Young = ages 25--39; Control = ages 50--59. Outcomes are quarterly rates per 1,000 population. Standard errors clustered at the municipality level in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex6, file.path(TABLE_DIR, "tab6_sex.tex"))
cat("  Saved: tab6_sex.tex\n")

# ============================================================================
# Table F1: Standardized Effect Sizes (Appendix — MANDATORY)
# ============================================================================

cat("\n--- Table F1: Standardized Effect Sizes ---\n")

# We need: beta_hat, SE, and SD(Y) for main outcomes
# beta_hat and SE come from reg_did_main.csv
# SD(Y) must come from unconditional standard deviation of the outcome variable

# Compute unconditional SD from the panel data
sd_fp  <- sd(panel$rate_fp, na.rm = TRUE)
sd_fl  <- sd(panel$rate_fl, na.rm = TRUE)
sd_res <- sd(panel$rate_res, na.rm = TRUE)

sde_outcomes <- c("Disability Pension", "Flex Jobs", "Rehabilitation")
sde_labels   <- c("DP Rate", "Flex Jobs", "Resource Scheme")
sde_sds      <- c(sd_fp, sd_fl, sd_res)

# Classify SDE
classify_sde <- function(sde_val) {
  if (sde_val < -0.15) return("Large negative")
  if (sde_val < -0.05) return("Moderate negative")
  if (sde_val < -0.005) return("Small negative")
  if (sde_val <= 0.005) return("Null")
  if (sde_val <= 0.05)  return("Small positive")
  if (sde_val <= 0.15)  return("Moderate positive")
  return("Large positive")
}

sde_rows <- list()
for (i in seq_along(sde_outcomes)) {
  oc <- sde_outcomes[i]
  row <- did_main[outcome == oc & grepl("young.*post", term)]
  if (nrow(row) > 0) {
    beta_hat <- row$estimate[1]
    se_hat   <- row$std_error[1]
    sd_y     <- sde_sds[i]
    sde      <- beta_hat / sd_y
    se_sde   <- se_hat / sd_y
    class_label <- classify_sde(sde)

    sde_rows[[i]] <- data.frame(
      Outcome = sde_labels[i],
      beta_hat = formatC(beta_hat, format = "f", digits = 3),
      SE = formatC(se_hat, format = "f", digits = 3),
      SD_Y = formatC(sd_y, format = "f", digits = 3),
      SDE = formatC(sde, format = "f", digits = 3),
      SE_SDE = formatC(se_sde, format = "f", digits = 3),
      Classification = class_label,
      stringsAsFactors = FALSE
    )
  }
}

sde_df <- do.call(rbind, sde_rows)

texF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_df))) {
  texF1 <- c(texF1, paste0(
    sde_df$Outcome[i], " & ",
    sde_df$beta_hat[i], " & ",
    sde_df$SE[i], " & ",
    sde_df$SD_Y[i], " & ",
    sde_df$SDE[i], " & ",
    sde_df$SE_SDE[i], " & ",
    sde_df$Classification[i], " \\\\"
  ))
}

texF1 <- c(texF1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Standardized effect sizes (SDE) are computed as $\\text{SDE} = \\hat{\\beta} / \\text{SD}(Y)$, where $\\hat{\\beta}$ is the DiD coefficient on Young $\\times$ Post from the preferred specification (Table~\\ref{tab:did_main}), SE is the corresponding clustered standard error, and SD($Y$) is the unconditional standard deviation of the outcome variable across all municipality-quarter observations. SE(SDE) $= \\text{SE} / \\text{SD}(Y)$. Classification thresholds: large negative ($<-0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($>0.15$). Young = ages 25--39; Control = ages 50--59. Outcomes are quarterly rates per 1,000 population. All SDE values are computed from a binary treatment indicator.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(texF1, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("  Saved: tabF1_sde.tex\n")

# ============================================================================
# Summary
# ============================================================================

cat("\n============================================================\n")
cat("All tables saved to:", TABLE_DIR, "\n")
cat("  tab1_summary.tex       — Summary statistics\n")
cat("  tab2_did_main.tex      — Main DiD results\n")
cat("  tab3_ddd.tex           — Triple-difference results\n")
cat("  tab4_dose_response.tex — Dose-response estimates\n")
cat("  tab5_robustness.tex    — Robustness checks\n")
cat("  tab6_sex.tex           — Sex heterogeneity\n")
cat("  tabF1_sde.tex          — Standardized effect sizes (appendix)\n")
cat("============================================================\n")
cat("06_tables.R complete.\n")
