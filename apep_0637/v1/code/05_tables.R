# 05_tables.R — Generate all LaTeX tables
# apep_0637: Patent Examiner Leniency & Defensive Patenting

source("00_packages.R")

df <- readRDS("../data/analysis_clean.rds")
results <- readRDS("../data/main_results.rds")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# Helper function: format numbers
fmt <- function(x, digits = 3) formatC(x, digits = digits, format = "f")
fmt_int <- function(x) format(x, big.mark = ",")
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics...\n")

sum_vars <- tibble(
  Variable = character(),
  Mean = character(),
  SD = character(),
  Min = character(),
  Max = character(),
  N = character()
)

add_row <- function(tbl, name, x) {
  bind_rows(tbl, tibble(
    Variable = name,
    Mean = fmt(mean(x, na.rm = TRUE)),
    SD = fmt(sd(x, na.rm = TRUE)),
    Min = fmt(min(x, na.rm = TRUE)),
    Max = fmt(max(x, na.rm = TRUE)),
    N = fmt_int(sum(!is.na(x)))
  ))
}

sum_vars <- add_row(sum_vars, "Patent granted (0/1)", df$granted)
sum_vars <- add_row(sum_vars, "Examiner leniency (LOO)", df$examiner_leniency)
sum_vars <- add_row(sum_vars, "Examiner cases (AU$\\times$year)", df$exam_n_cases)
if ("class_filings_t1" %in% names(df))
  sum_vars <- add_row(sum_vars, "Class filings (t+1)", df$class_filings_t1)
if ("class_filings_2yr" %in% names(df))
  sum_vars <- add_row(sum_vars, "Class filings (t+1 to t+2)", df$class_filings_2yr)
if ("class_filings_3yr" %in% names(df))
  sum_vars <- add_row(sum_vars, "Class filings (t+1 to t+3)", df$class_filings_3yr)
if ("small_entity" %in% names(df))
  sum_vars <- add_row(sum_vars, "Small entity (0/1)", df$small_entity)
sum_vars <- add_row(sum_vars, "Filing year", df$filing_year)

# Write LaTeX
tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & SD & Min & Max & N \\\\\n",
  "\\midrule\n"
)
for (i in seq_len(nrow(sum_vars))) {
  tab1 <- paste0(tab1, paste(sum_vars[i, ], collapse = " & "), " \\\\\n")
}
tab1 <- paste0(tab1,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item Notes: Sample consists of decided utility patent applications filed ",
  min(df$filing_year), "--", max(df$filing_year),
  " at the USPTO. Examiner leniency is the leave-one-out mean grant rate of the ",
  "assigned examiner within the same art unit and filing year. Class filings count ",
  "total applications in the same USPC technology class in subsequent years. ",
  "N = ", fmt_int(nrow(df)), " application-level observations across ",
  fmt_int(n_distinct(df$examiner_art_unit)), " art units and ",
  fmt_int(n_distinct(df$examiner_id)), " examiners.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)
writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: First Stage
# ============================================================================
cat("Generating Table 2: First Stage...\n")

if ("1yr" %in% names(results)) {
  fs_fit <- feols(granted ~ examiner_leniency | au_year,
                  data = df, vcov = ~examiner_art_unit)
  fs_coef <- coef(fs_fit)["examiner_leniency"]
  fs_se <- se(fs_fit)["examiner_leniency"]
  fs_p <- fixest::pvalue(fs_fit)["examiner_leniency"]
  fs_t <- coef(fs_fit)["examiner_leniency"] / se(fs_fit)["examiner_leniency"]
  fs_f <- fs_t^2

  tab2 <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{First Stage: Examiner Leniency and Patent Grant Probability}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lc}\n",
    "\\toprule\n",
    " & Patent Granted \\\\\n",
    "\\midrule\n",
    "Examiner leniency & ", fmt(fs_coef), stars(fs_p), " \\\\\n",
    " & (", fmt(fs_se), ") \\\\\n",
    " & \\\\\n",
    "Art unit $\\times$ Year FE & Yes \\\\\n",
    "Observations & ", fmt_int(nrow(df)), " \\\\\n",
    "F-statistic & ", fmt(fs_f, 1), " \\\\\n",
    "Mean dep.\\ var. & ", fmt(mean(df$granted)), " \\\\\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item Notes: Standard errors clustered at the art-unit level in parentheses. ",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
    "Examiner leniency is the leave-one-out grant rate of the assigned examiner ",
    "within the same art unit and filing year. ",
    "The dependent variable is an indicator for whether the patent application was granted.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:first_stage}\n",
    "\\end{table}\n"
  )
  writeLines(tab2, file.path(tables_dir, "tab2_first_stage.tex"))
}

# ============================================================================
# Table 3: Main 2SLS Results
# ============================================================================
cat("Generating Table 3: Main 2SLS Results...\n")

if (all(c("1yr", "2yr", "3yr") %in% names(results))) {
  make_col <- function(fit, label) {
    b <- coef(fit)["fit_granted"]
    s <- se(fit)["fit_granted"]
    p <- fixest::pvalue(fit)["fit_granted"]
    n <- nobs(fit)
    list(label = label, coef = b, se = s, p = p, n = n)
  }

  cols <- list(
    make_col(results[["1yr"]], "1 Year"),
    make_col(results[["2yr"]], "2 Years"),
    make_col(results[["3yr"]], "3 Years")
  )

  # Also add OLS for comparison
  ols_fit <- feols(log_class_filings_t1 ~ granted | au_year,
                   data = df, vcov = ~examiner_art_unit)
  cols <- c(
    list(list(
      label = "OLS (1 Yr)",
      coef = coef(ols_fit)["granted"],
      se = se(ols_fit)["granted"],
      p = fixest::pvalue(ols_fit)["granted"],
      n = nobs(ols_fit)
    )),
    cols
  )

  ncols <- length(cols)
  headers <- paste(sapply(cols, \(x) x$label), collapse = " & ")
  coefs <- paste(sapply(cols, \(x) paste0(fmt(x$coef, 4), stars(x$p))), collapse = " & ")
  ses <- paste(sapply(cols, \(x) paste0("(", fmt(x$se, 4), ")")), collapse = " & ")
  ns <- paste(sapply(cols, \(x) fmt_int(x$n)), collapse = " & ")

  tab3 <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Effect of Patent Grant on Technology Class Filing Activity}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{l", paste(rep("c", ncols), collapse = ""), "}\n",
    "\\toprule\n",
    " & ", headers, " \\\\\n",
    " & (1) & (2) & (3) & (4) \\\\\n",
    "\\midrule\n",
    "Patent granted & ", coefs, " \\\\\n",
    " & ", ses, " \\\\\n",
    " & \\\\\n",
    "Estimator & OLS & 2SLS & 2SLS & 2SLS \\\\\n",
    "AU $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\\n",
    "Observations & ", ns, " \\\\\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item Notes: Standard errors clustered at the art-unit level in parentheses. ",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
    "The dependent variable is log(USPC class filings + 1) in the specified window ",
    "following the focal application's filing year. ",
    "Columns (2)--(4) instrument the grant indicator with examiner leniency ",
    "(leave-one-out grant rate within art unit $\\times$ year). ",
    "Class filings count all applications in the same USPC technology class.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:main}\n",
    "\\end{table}\n"
  )
  writeLines(tab3, file.path(tables_dir, "tab3_main_results.tex"))
}

# ============================================================================
# Table 4: Heterogeneity (Concentration & Entity Size)
# ============================================================================
cat("Generating Table 4: Heterogeneity...\n")

het_models <- c("concentrated", "diffuse", "small", "large")
het_available <- het_models[het_models %in% names(results)]

if (length(het_available) >= 2) {
  make_het_col <- function(name) {
    fit <- results[[name]]
    b <- coef(fit)["fit_granted"]
    s <- se(fit)["fit_granted"]
    p <- fixest::pvalue(fit)["fit_granted"]
    n <- nobs(fit)
    list(label = name, coef = b, se = s, p = p, n = n)
  }

  het_cols <- lapply(het_available, make_het_col)
  ncols <- length(het_cols)

  labels <- c("Concentrated" = "concentrated", "Diffuse" = "diffuse",
              "Small Entity" = "small", "Large Entity" = "large")
  header_names <- names(labels)[match(het_available, labels)]

  tab4 <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Heterogeneity: Technology Concentration and Entity Size}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{l", paste(rep("c", ncols), collapse = ""), "}\n",
    "\\toprule\n",
    " & ", paste(header_names, collapse = " & "), " \\\\\n",
    "\\midrule\n",
    "Patent granted & ",
    paste(sapply(het_cols, \(x) paste0(fmt(x$coef, 4), stars(x$p))), collapse = " & "),
    " \\\\\n",
    " & ",
    paste(sapply(het_cols, \(x) paste0("(", fmt(x$se, 4), ")")), collapse = " & "),
    " \\\\\n",
    " & \\\\\n",
    "Observations & ",
    paste(sapply(het_cols, \(x) fmt_int(x$n)), collapse = " & "),
    " \\\\\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item Notes: All columns report 2SLS estimates with art-unit $\\times$ year FE ",
    "and art-unit-clustered SEs. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
    "Dependent variable is log(USPC class filings + 1) in the year following the ",
    "focal application. Concentrated/diffuse split at the median art-unit size. ",
    "Small/large entity split uses the USPTO small entity indicator.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:heterogeneity}\n",
    "\\end{table}\n"
  )
  writeLines(tab4, file.path(tables_dir, "tab4_heterogeneity.tex"))
}

# ============================================================================
# Table 5: Robustness
# ============================================================================
cat("Generating Table 5: Robustness...\n")

rob_models <- c("mincases_20", "mincases_30", "mincases_50", "asinh", "levels", "separate_fe")
rob_available <- rob_models[rob_models %in% names(results)]

if (length(rob_available) >= 2) {
  rob_labels <- c(
    "mincases_20" = "$\\geq$20 cases",
    "mincases_30" = "$\\geq$30 cases",
    "mincases_50" = "$\\geq$50 cases",
    "asinh" = "Asinh",
    "levels" = "Levels",
    "separate_fe" = "AU + Year FE"
  )

  make_rob_col <- function(name) {
    fit <- results[[name]]
    coef_name <- if ("fit_granted" %in% names(coef(fit))) "fit_granted" else names(coef(fit))[1]
    b <- coef(fit)[coef_name]
    s <- se(fit)[coef_name]
    p <- fixest::pvalue(fit)[coef_name]
    n <- nobs(fit)
    list(label = rob_labels[name], coef = b, se = s, p = p, n = n)
  }

  rob_cols <- lapply(rob_available, make_rob_col)
  ncols <- length(rob_cols)

  tab5 <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Robustness Checks}\n",
    "\\begin{threeparttable}\n",
    "\\begin{adjustbox}{max width=\\textwidth}\n",
    "\\begin{tabular}{l", paste(rep("c", ncols), collapse = ""), "}\n",
    "\\toprule\n",
    " & ", paste(sapply(rob_cols, \(x) x$label), collapse = " & "), " \\\\\n",
    "\\midrule\n",
    "Patent granted & ",
    paste(sapply(rob_cols, \(x) paste0(fmt(x$coef, 4), stars(x$p))), collapse = " & "),
    " \\\\\n",
    " & ",
    paste(sapply(rob_cols, \(x) paste0("(", fmt(x$se, 4), ")")), collapse = " & "),
    " \\\\\n",
    " & \\\\\n",
    "Observations & ",
    paste(sapply(rob_cols, \(x) fmt_int(x$n)), collapse = " & "),
    " \\\\\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\end{adjustbox}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item Notes: All columns instrument patent grant with examiner leniency. ",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
    "Columns (1)--(3) vary the minimum number of examiner cases per AU$\\times$year. ",
    "``Asinh'' uses the inverse hyperbolic sine transformation. ",
    "``Levels'' uses raw filing counts. ",
    "``AU + Year FE'' uses separate (not interacted) fixed effects.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:robustness}\n",
    "\\end{table}\n"
  )
  writeLines(tab5, file.path(tables_dir, "tab5_robustness.tex"))
}

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================================
cat("Generating Table F1: SDE...\n")

if ("1yr" %in% names(results)) {
  # Get main IV estimates
  sde_rows <- list()

  outcome_map <- list(
    list(name = "1yr", label = "Class filings (1 year)", outcome = "log_class_filings_t1"),
    list(name = "2yr", label = "Class filings (2 years)", outcome = "log_class_filings_2yr"),
    list(name = "3yr", label = "Class filings (3 years)", outcome = "log_class_filings_3yr")
  )

  for (item in outcome_map) {
    if (item$name %in% names(results) && item$outcome %in% names(df)) {
      fit <- results[[item$name]]
      beta <- coef(fit)["fit_granted"]
      se_beta <- se(fit)["fit_granted"]
      sd_y <- sd(df[[item$outcome]], na.rm = TRUE)

      sde <- beta / sd_y
      se_sde <- se_beta / sd_y

      classify <- function(s) {
        if (s < -0.15) return("Large negative")
        if (s < -0.05) return("Moderate negative")
        if (s < -0.005) return("Small negative")
        if (s < 0.005) return("Null")
        if (s < 0.05) return("Small positive")
        if (s < 0.15) return("Moderate positive")
        return("Large positive")
      }

      sde_rows[[length(sde_rows) + 1]] <- list(
        outcome = item$label,
        beta = beta, se = se_beta,
        sd_y = sd_y, sde = sde, se_sde = se_sde,
        class = classify(sde)
      )
    }
  }

  if (length(sde_rows) > 0) {
    sde_body <- paste(sapply(sde_rows, function(r) {
      paste0(
        r$outcome, " & 2SLS & ", fmt(r$beta, 4), " & --- & ",
        fmt(r$sd_y, 3), " & ", fmt(r$sde, 4), " & ",
        fmt(r$se_sde, 4), " & ", r$class, " \\\\"
      )
    }), collapse = "\n")

    sde_tex <- paste0(
      "\\begin{table}[H]\n",
      "\\centering\n",
      "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
      "\\label{tab:sde}\n",
      "\\begin{adjustbox}{max width=\\textwidth}\n",
      "\\begin{tabular}{llcccccl}\n",
      "\\toprule\n",
      "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
      "\\midrule\n",
      sde_body, "\n",
      "\\bottomrule\n",
      "\\end{tabular}\n",
      "\\end{adjustbox}\n",
      "\\par\\vspace{0.3em}\n",
      "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
      "to facilitate cross-study comparison of treatment effect magnitudes. ",
      "The treatment (patent granted) is binary (0/1), so SDE $= \\hat{\\beta} / \\text{SD}(Y)$ ",
      "and SD($X$) is marked ``---''. ",
      "SD($Y$) is the unconditional standard deviation of log(class filings + 1). ",
      "\\textbf{Research question:} Does granting a patent cause increased filing activity ",
      "by competitors in the same technology class? ",
      "\\textbf{Treatment:} Binary indicator for patent grant (vs.\\ denial). ",
      "\\textbf{Data:} USPTO PatEx, ",
      min(df$filing_year), "--", max(df$filing_year),
      ", application-level, N = ", fmt_int(nrow(df)), ". ",
      "\\textbf{Method:} Examiner leniency IV (2SLS) with art-unit $\\times$ year FE, ",
      "art-unit-clustered SEs. ",
      "Classification labels refer to the magnitude of the standardized point estimate, ",
      "not to statistical significance. ``Null'' denotes a near-zero effect size ",
      "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
      "\\end{table}\n"
    )
    writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
  }
}

cat("\nAll tables generated.\n")
cat("Files in tables/:\n")
cat(paste(list.files(tables_dir), collapse = "\n"), "\n")
