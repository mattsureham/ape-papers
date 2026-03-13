# ==============================================================================
# 05_tables.R — Generate all LaTeX tables (including SDE appendix)
# APEP Paper apep_0651: The Spotlight Effect on Mine Safety Enforcement
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

analysis <- readRDS(file.path(data_dir, "analysis.rds"))
main_results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Ensure log outcomes exist
for (y in c("insp_post_90", "viol_post_90", "penalty_post_90",
            "insp_pre_365", "viol_pre_365", "penalty_pre_365",
            "insp_post_180", "viol_post_180", "penalty_post_180",
            "insp_post_365", "viol_post_365", "penalty_post_365",
            "ss_pre_365", "ss_post_90")) {
  if (y %in% names(analysis)) {
    analysis[, paste0("log_", y) := log(get(y) + 1)]
  }
}

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================

cat("Generating Table 1: Summary Statistics...\n")

sum_vars <- c(
  "n_killed", "n_disasters", "log_disasters",
  "insp_pre_365", "insp_post_90", "insp_post_180", "insp_post_365",
  "viol_pre_365", "viol_post_90", "viol_post_180", "viol_post_365",
  "penalty_pre_365", "penalty_post_90", "penalty_post_180", "penalty_post_365",
  "ss_pre_365", "ss_post_90"
)
sum_vars <- intersect(sum_vars, names(analysis))

var_labels <- c(
  n_killed = "Fatalities per event",
  n_disasters = "FEMA disasters (fatality week)",
  log_disasters = "Log FEMA disasters",
  insp_pre_365 = "Inspections (365d pre)",
  insp_post_90 = "Inspections (90d post)",
  insp_post_180 = "Inspections (180d post)",
  insp_post_365 = "Inspections (365d post)",
  viol_pre_365 = "Violations (365d pre)",
  viol_post_90 = "Violations (90d post)",
  viol_post_180 = "Violations (180d post)",
  viol_post_365 = "Violations (365d post)",
  penalty_pre_365 = "Penalties (\\$, 365d pre)",
  penalty_post_90 = "Penalties (\\$, 90d post)",
  penalty_post_180 = "Penalties (\\$, 180d post)",
  penalty_post_365 = "Penalties (\\$, 365d post)",
  ss_pre_365 = "S\\&S violations (365d pre)",
  ss_post_90 = "S\\&S violations (90d post)"
)

sum_stats <- data.table(
  Variable = var_labels[sum_vars],
  Mean = sapply(sum_vars, function(v) sprintf("%.2f", mean(analysis[[v]], na.rm = TRUE))),
  SD = sapply(sum_vars, function(v) sprintf("%.2f", sd(analysis[[v]], na.rm = TRUE))),
  Min = sapply(sum_vars, function(v) sprintf("%.0f", min(analysis[[v]], na.rm = TRUE))),
  Max = sapply(sum_vars, function(v) sprintf("%.0f", max(analysis[[v]], na.rm = TRUE)))
)

n_obs <- nrow(analysis)
n_mines <- uniqueN(analysis$mine_id)
year_range <- paste(min(analysis$year), max(analysis$year), sep = "--")

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & SD & Min & Max \\\\\n",
  "\\midrule\n",
  paste0("\\multicolumn{5}{l}{\\textit{Panel A: Fatality Event Characteristics}} \\\\\n"),
  paste(apply(sum_stats[1:min(3, nrow(sum_stats))], 1, function(r) paste(r, collapse = " & ")),
        collapse = " \\\\\n"), " \\\\\n",
  "\\addlinespace\n",
  paste0("\\multicolumn{5}{l}{\\textit{Panel B: Enforcement Outcomes}} \\\\\n"),
  paste(apply(sum_stats[min(4, nrow(sum_stats)):nrow(sum_stats)], 1,
              function(r) paste(r, collapse = " & ")),
        collapse = " \\\\\n"), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} N = ", format(n_obs, big.mark = ","),
  " fatality events at ", format(n_mines, big.mark = ","),
  " unique mines, ", year_range,
  ". FEMA disasters measure the number of distinct federal disaster declarations in the week of each mine fatality.",
  " Enforcement outcomes are counts (inspections, violations, S\\&S citations)",
  " and dollar amounts (proposed penalties) at the mine in the specified window",
  " around the fatality date. S\\&S = Significant and Substantial violations.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("  Table 1 saved.\n")

# ==============================================================================
# TABLE 2: Balancing Test
# ==============================================================================

cat("Generating Table 2: Balancing Test...\n")

bal_vars <- intersect(
  c("n_killed", "is_coal", "log_employment", "large_mine", "insp_pre_365", "viol_pre_365"),
  names(analysis)
)

bal_fits <- list()
for (v in bal_vars) {
  if (all(is.na(analysis[[v]]))) next
  fml <- as.formula(paste(v, "~ z_disasters | yq_fe"))
  bal_fits[[v]] <- feols(fml, data = analysis, vcov = "hetero")
}

bal_labels <- c(
  n_killed = "Fatalities per event",
  is_coal = "Coal mine (=1)",
  log_employment = "Log employment",
  large_mine = "Large mine ($\\geq$50 employees)",
  insp_pre_365 = "Inspections (365d pre)",
  viol_pre_365 = "Violations (365d pre)"
)

if (length(bal_fits) > 0) {
  # Build table manually for control
  bal_rows <- sapply(names(bal_fits), function(v) {
    fit <- bal_fits[[v]]
    b <- coef(fit)["z_disasters"]
    s <- se(fit)["z_disasters"]
    p <- pvalue(fit)["z_disasters"]
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
    paste0(bal_labels[v], " & ", sprintf("%.4f%s", b, stars),
           " & (", sprintf("%.4f", s), ") & ",
           format(nobs(fit), big.mark = ","), " \\\\")
  })

  tab2_tex <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Balancing Test: News Competition and Mine Characteristics}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lccc}\n",
    "\\toprule\n",
    "Dependent Variable & Coefficient & SE & N \\\\\n",
    "\\midrule\n",
    paste(bal_rows, collapse = "\n"),
    "\n\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item \\textit{Notes:} Each row reports the coefficient on the standardized",
    " log weekly FEMA disaster declarations from a separate regression of the dependent variable",
    " on the instrument, with year-quarter fixed effects.",
    " Heteroskedasticity-robust standard errors in parentheses.",
    " The instrument should be uncorrelated with mine characteristics",
    " conditional on time fixed effects.",
    " \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\).\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:balance}\n",
    "\\end{table}\n"
  )

  writeLines(tab2_tex, file.path(table_dir, "tab2_balance.tex"))
  cat("  Table 2 saved.\n")
}

# ==============================================================================
# TABLE 3: Main Results — Reduced Form
# ==============================================================================

cat("Generating Table 3: Main Results...\n")

# Extract the 4 specs for each of 3 outcomes
outcome_names <- c("insp_post_90", "viol_post_90", "penalty_post_90")
outcome_labels <- c("Log inspections\n(90 days)", "Log violations\n(90 days)", "Log penalties\n(90 days)")

spec_keys <- c("s1", "s2", "s3", "s4")
spec_labels <- c("(1)", "(2)", "(3)", "(4)")

# Build table for inspections (primary outcome) across 4 specs
insp_fits <- list()
for (s in spec_keys) {
  key <- paste0("insp_post_90_", s)
  if (key %in% names(main_results)) {
    insp_fits[[s]] <- main_results[[key]]
  }
}

viol_fits <- list()
for (s in spec_keys) {
  key <- paste0("viol_post_90_", s)
  if (key %in% names(main_results)) {
    viol_fits[[s]] <- main_results[[key]]
  }
}

pen_fits <- list()
for (s in spec_keys) {
  key <- paste0("penalty_post_90_", s)
  if (key %in% names(main_results)) {
    pen_fits[[s]] <- main_results[[key]]
  }
}

# Build main results table manually
format_coef_row <- function(fits, varname, label) {
  coef_cells <- sapply(fits, function(f) {
    if (is.null(f)) return("")
    b <- coef(f)[varname]
    s <- se(f)[varname]
    p <- pvalue(f)[varname]
    if (is.na(b)) return("")
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
    sprintf("%.4f%s", b, stars)
  })
  se_cells <- sapply(fits, function(f) {
    if (is.null(f)) return("")
    s <- se(f)[varname]
    if (is.na(s)) return("")
    sprintf("(%.4f)", s)
  })
  paste0(label, " & ", paste(coef_cells, collapse = " & "), " \\\\\n",
         " & ", paste(se_cells, collapse = " & "), " \\\\")
}

# Combine all fits: 4 specs for inspections, then 4 for violations, then 4 for penalties
# Actually, present as: each outcome in a panel, 4 specs each
all_outcomes <- list(
  list(fits = insp_fits, label = "Panel A: Log inspections (90 days post-fatality)"),
  list(fits = viol_fits, label = "Panel B: Log violations (90 days post-fatality)"),
  list(fits = pen_fits, label = "Panel C: Log penalties (90 days post-fatality)")
)

panel_rows <- character()
for (panel in all_outcomes) {
  fits <- panel$fits
  if (length(fits) == 0) next

  panel_rows <- c(panel_rows,
    paste0("\\addlinespace\n\\multicolumn{5}{l}{\\textit{", panel$label, "}} \\\\"))

  # Disaster pressure row
  coef_cells <- sapply(fits, function(f) {
    b <- coef(f)["z_disasters"]; s <- se(f)["z_disasters"]; p <- pvalue(f)["z_disasters"]
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
    sprintf("%.4f%s", b, stars)
  })
  se_cells <- sapply(fits, function(f) sprintf("(%.4f)", se(f)["z_disasters"]))
  n_cells <- sapply(fits, function(f) format(nobs(f), big.mark = ","))
  r2_cells <- sapply(fits, function(f) sprintf("%.3f", r2(f, type = "r2")))

  panel_rows <- c(panel_rows,
    paste0("Disaster pressure (std.) & ", paste(coef_cells, collapse = " & "), " \\\\"),
    paste0(" & ", paste(se_cells, collapse = " & "), " \\\\"),
    paste0("Observations & ", paste(n_cells, collapse = " & "), " \\\\"),
    paste0("R$^2$ & ", paste(r2_cells, collapse = " & "), " \\\\")
  )
}

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{The Spotlight Effect: Disaster Pressure and Post-Fatality Enforcement}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  paste(panel_rows, collapse = "\n"), "\n",
  "\\midrule\n",
  "Year-quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "Fatality severity & & Yes & Yes & Yes \\\\\n",
  "Mine characteristics & & & Yes & Yes \\\\\n",
  "State FE & & & & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each cell reports the OLS coefficient on the standardized",
  " log of weekly FEMA disaster declarations in the week of the mine fatality.",
  " The dependent variable is the log of enforcement outcomes in the 90 days",
  " following the fatality. Fatality severity is the number of workers killed.",
  " Mine characteristics include coal/metal indicator and log average employment.",
  " Heteroskedasticity-robust standard errors in parentheses.",
  " \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_main.tex"))
cat("  Table 3 saved.\n")

# ==============================================================================
# TABLE 4: Robustness — Placebo, Poisson, Leave-One-Out
# ==============================================================================

cat("Generating Table 4: Robustness...\n")

# Collect robustness fits
rob_fits <- list()
rob_labels <- c()

# Placebo (pre-fatality inspections)
if ("placebo_insp_pre_365" %in% names(robustness_results)) {
  rob_fits[["Placebo: pre-365d inspections"]] <- robustness_results[["placebo_insp_pre_365"]]
}
if ("placebo_viol_pre_365" %in% names(robustness_results)) {
  rob_fits[["Placebo: pre-365d violations"]] <- robustness_results[["placebo_viol_pre_365"]]
}

# Levels specification
if ("levels_insp_post_90" %in% names(robustness_results)) {
  rob_fits[["Levels: inspections (90d)"]] <- robustness_results[["levels_insp_post_90"]]
}
if ("levels_viol_post_90" %in% names(robustness_results)) {
  rob_fits[["Levels: violations (90d)"]] <- robustness_results[["levels_viol_post_90"]]
}

# Single-fatality only
if ("single_insp_post_90" %in% names(robustness_results)) {
  rob_fits[["Single fatality: inspections"]] <- robustness_results[["single_insp_post_90"]]
}

if (length(rob_fits) > 0) {
  rob_rows <- sapply(names(rob_fits), function(nm) {
    f <- rob_fits[[nm]]
    b <- coef(f)["z_disasters"]; s <- se(f)["z_disasters"]; p <- pvalue(f)["z_disasters"]
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
    paste0(nm, " & ", sprintf("%.4f%s", b, stars),
           " & (", sprintf("%.4f", s), ") & ",
           format(nobs(f), big.mark = ","), " \\\\")
  })

  tab4_tex <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Robustness and Placebo Tests}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lccc}\n",
    "\\toprule\n",
    "Specification & Coefficient & SE & N \\\\\n",
    "\\midrule\n",
    paste(rob_rows, collapse = "\n"), "\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item \\textit{Notes:} Each row reports the coefficient on the standardized",
    " disaster pressure instrument from a separate regression.",
    " All specifications include year-quarter and state fixed effects,",
    " fatality severity, and mine characteristics.",
    " Placebo regressions use pre-fatality enforcement (365 days before) as the dependent variable.",
    " The single-fatality sample excludes events with multiple deaths.",
    " Heteroskedasticity-robust standard errors in parentheses.",
    " \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\).\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:robustness}\n",
    "\\end{table}\n"
  )

  writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))
  cat("  Table 4 saved.\n")
}

# ==============================================================================
# TABLE F1: Standardized Effect Sizes (MANDATORY)
# ==============================================================================

cat("Generating SDE Table...\n")

# Get main specification results (spec 4 = full controls)
sde_outcomes <- c("insp_post_90", "viol_post_90", "penalty_post_90")
sde_labels <- c("Inspections (90d post)", "Violations (90d post)", "Penalties (90d post)")

sde_rows <- list()
for (i in seq_along(sde_outcomes)) {
  y <- sde_outcomes[i]
  key <- paste0(y, "_s4")

  if (!(key %in% names(main_results))) next
  fit <- main_results[[key]]

  log_y <- paste0("log_", y)
  if (!(log_y %in% names(analysis))) next

  beta <- coef(fit)["z_disasters"]
  se_beta <- se(fit)["z_disasters"]
  sd_y <- sd(analysis[[log_y]], na.rm = TRUE)

  # Treatment is continuous (standardized), so SDE = beta * SD(X) / SD(Y)
  # Since X is already standardized (SD=1), SDE = beta / SD(Y)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

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

  sde_rows[[i]] <- data.frame(
    outcome = sde_labels[i],
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sde_df <- do.call(rbind, sde_rows)

if (nrow(sde_df) > 0) {
  sde_tex_rows <- apply(sde_df, 1, function(r) {
    paste0(r["outcome"], " & ",
           sprintf("%.4f", as.numeric(r["beta"])), " & ",
           sprintf("%.4f", as.numeric(r["se"])), " & ",
           "---", " & ",
           sprintf("%.3f", as.numeric(r["sd_y"])), " & ",
           sprintf("%.4f", as.numeric(r["sde"])), " & ",
           sprintf("%.4f", as.numeric(r["se_sde"])), " & ",
           r["classification"], " \\\\")
  })

  sde_tex <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
    "\\label{tab:sde}\n",
    "\\begin{adjustbox}{max width=\\textwidth}\n",
    "\\begin{tabular}{lccccccl}\n",
    "\\toprule\n",
    "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
    "\\midrule\n",
    paste(sde_tex_rows, collapse = "\n"), "\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\end{adjustbox}\n",
    "\\par\\vspace{0.3em}\n",
    "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
    "to facilitate cross-study comparison of treatment effect magnitudes. ",
    "The treatment variable (news competition) is the standardized log of weekly FEMA disaster declarations, ",
    "so SD($X$) = 1 by construction (marked ``---''). ",
    "SDE $= \\hat{\\beta} / \\text{SD}(Y)$, measuring the effect of a one-standard-deviation ",
    "increase in news competition on the outcome in standard deviation units. ",
    "\\textbf{Research question:} Does news competition reduce post-fatality mine safety enforcement? ",
    "\\textbf{Treatment:} Continuous (standardized log weekly FEMA disaster declarations). ",
    "\\textbf{Data:} MSHA accidents, inspections, violations; FEMA disaster declarations; ",
    format(nrow(analysis), big.mark = ","), " fatality events, ",
    min(analysis$year), "--", max(analysis$year), ". ",
    "\\textbf{Method:} OLS reduced form with year-quarter and state fixed effects, ",
    "heteroskedasticity-robust standard errors. ",
    "\\textbf{Sample:} All mine fatalities with matching FEMA weekly disaster data. ",
    "Classification labels refer to the magnitude of the standardized point estimate, ",
    "not to statistical significance. ``Null'' denotes a near-zero effect size ",
    "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
    "\\end{table}\n"
  )

  writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))
  cat("  SDE table saved.\n")
}

cat("\n=== All tables generated ===\n")
