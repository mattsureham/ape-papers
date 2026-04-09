# 05_tables.R — All table generation for apep_1442
# Generates tables as LaTeX files for inclusion in paper.tex

source("00_packages.R")

cases <- fread("../data/pins_analysis.csv")

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================

cat("=== Table 1: Summary Statistics ===\n")

# Case-level summary
case_stats <- data.table(
  Variable = c(
    "Appeal allowed (=1)", "Inspector leniency (standardized)",
    "Inspector leniency (raw)", "Filing lag (days)",
    "Case type: Householder", "Case type: Planning",
    "Case type: Enforcement", "Case type: Other"
  ),
  Mean = c(
    mean(cases$allowed),
    mean(cases$leniency, na.rm = TRUE),
    mean(cases$leniency_raw, na.rm = TRUE),
    mean(as.numeric(cases$decision_date_parsed - cases$start_date_parsed), na.rm = TRUE),
    mean(cases$case_type_clean == "Householder"),
    mean(cases$case_type_clean == "Planning"),
    mean(cases$case_type_clean == "Enforcement"),
    mean(cases$case_type_clean %in% c("LDC", "Commercial", "Other"))
  ),
  SD = c(
    sd(cases$allowed),
    sd(cases$leniency, na.rm = TRUE),
    sd(cases$leniency_raw, na.rm = TRUE),
    sd(as.numeric(cases$decision_date_parsed - cases$start_date_parsed), na.rm = TRUE),
    NA, NA, NA, NA
  )
)

# Format
case_stats[, Mean := sprintf("%.3f", Mean)]
case_stats[, SD := ifelse(is.na(SD), "", sprintf("%.3f", as.numeric(SD)))]

# Panel B: Inspector-level
insp_stats_dt <- cases[, .(
  n_cases = .N,
  allow_rate = mean(allowed),
  n_lpas = uniqueN(lpa_clean)
), by = inspector]

insp_panel <- data.table(
  Variable = c("Cases per inspector", "Inspector allow rate", "LPAs per inspector"),
  Mean = sprintf("%.1f", c(mean(insp_stats_dt$n_cases), mean(insp_stats_dt$allow_rate),
                            mean(insp_stats_dt$n_lpas))),
  SD = sprintf("%.1f", c(sd(insp_stats_dt$n_cases), sd(insp_stats_dt$allow_rate),
                           sd(insp_stats_dt$n_lpas)))
)

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  sprintf("\\begin{tabular}{lcc}"),
  "\\hline\\hline",
  " & Mean & SD \\\\",
  "\\hline",
  "\\multicolumn{3}{l}{\\textit{Panel A: Case-Level}} \\\\[3pt]"
)

for (i in seq_len(nrow(case_stats))) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s \\\\", case_stats$Variable[i], case_stats$Mean[i], case_stats$SD[i]))
}

tab1_lines <- c(tab1_lines,
  "[6pt]",
  "\\multicolumn{3}{l}{\\textit{Panel B: Inspector-Level}} \\\\[3pt]"
)

for (i in seq_len(nrow(insp_panel))) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s \\\\", insp_panel$Variable[i], insp_panel$Mean[i], insp_panel$SD[i]))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("\\multicolumn{3}{l}{\\footnotesize Cases: %s. Inspectors: %s. LPAs: %s.} \\\\",
          formatC(nrow(cases), big.mark = ","),
          formatC(uniqueN(cases$inspector), big.mark = ","),
          formatC(uniqueN(cases$lpa_clean), big.mark = ",")),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# =============================================================================
# Table 2: First Stage and Balance Tests
# =============================================================================

cat("=== Table 2: First Stage ===\n")

case_results <- readRDS("../data/case_results.rds")

# Extract coefficients
extract_row <- function(fit, label) {
  coefs <- coef(fit)
  ses <- se(fit)
  var_name <- names(coefs)[1]
  data.table(
    Specification = label,
    Coefficient = sprintf("%.4f", coefs[var_name]),
    SE = sprintf("(%.4f)", ses[var_name]),
    N = as.character(fit$nobs),
    FEs = ""
  )
}

fs_rows <- rbind(
  extract_row(case_results$fs_1, "Leniency (cell-specific)"),
  extract_row(case_results$fs_2, "Leniency (simple FEs)")
)
fs_rows$FEs <- c("LPA$\\times$Type + Year$\\times$Type", "LPA + Type + Year")

# F-statistics (t^2 since single instrument OLS first stage)
f1 <- (coef(case_results$fs_1)["leniency"] / se(case_results$fs_1)["leniency"])^2
f2 <- (coef(case_results$fs_2)["leniency"] / se(case_results$fs_2)["leniency"])^2

# Balance test rows
bal_rows <- rbind(
  extract_row(case_results$bal_lag, "Filing lag (days)"),
  extract_row(case_results$bal_type, "Householder type (=1)")
)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{First Stage: Inspector Leniency Predicts Appeal Outcomes}",
  "\\label{tab:first_stage}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Coefficient & $N$ & Fixed Effects \\\\",
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel A: First Stage (Dep. Var.: Appeal Allowed)}} \\\\[3pt]"
)

for (i in seq_len(nrow(fs_rows))) {
  tab2_lines <- c(tab2_lines,
    sprintf("%s & %s & %s & %s \\\\",
            fs_rows$Specification[i], fs_rows$Coefficient[i], fs_rows$N[i], fs_rows$FEs[i]),
    sprintf(" & %s & & \\\\", fs_rows$SE[i])
  )
}

tab2_lines <- c(tab2_lines,
  sprintf("First-stage $F$ & %.1f / %.1f & & \\\\", f1, f2),
  "[6pt]",
  "\\multicolumn{4}{l}{\\textit{Panel B: Balance Tests (Dep. Var. in Left Column)}} \\\\[3pt]"
)

for (i in seq_len(nrow(bal_rows))) {
  tab2_lines <- c(tab2_lines,
    sprintf("%s & %s & %s & \\\\", bal_rows$Specification[i], bal_rows$Coefficient[i], bal_rows$N[i]),
    sprintf(" & %s & & \\\\", bal_rows$SE[i])
  )
}

tab2_lines <- c(tab2_lines,
  "\\hline",
  "\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Panel~A reports the first stage of the inspector leniency IV. The dependent variable is an indicator for the appeal being allowed. Leniency is the leave-one-out inspector allow rate within case-type$\\times$year cells, standardized to mean zero and unit variance. Panel~B reports balance tests: leniency should not predict case characteristics within cells. Standard errors clustered at LPA level in parentheses.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_first_stage.tex")
cat("Table 2 written.\n")

# =============================================================================
# Table 3: IV Results (if LPA-level merge worked)
# =============================================================================

cat("=== Table 3: IV Results ===\n")

if (file.exists("../data/iv_results.rds")) {
  iv <- readRDS("../data/iv_results.rds")

  tab3_lines <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Effect of Appeal Outcomes on Housing Market Outcomes (2SLS)}",
    "\\label{tab:iv_results}",
    "\\begin{tabular}{lccc}",
    "\\hline\\hline",
    " & ln(New Builds) & ln(Median Price) & ln(Transactions) \\\\",
    " & (1) & (2) & (3) \\\\",
    "\\hline",
    "\\multicolumn{4}{l}{\\textit{Panel A: 2SLS (IV: Inspector Leniency)}} \\\\[3pt]"
  )

  # Extract 2SLS coefficients
  models <- list(iv$iv_newbuild, iv$iv_price, iv$iv_txn)
  coef_row <- paste(sapply(models, function(m) sprintf("%.3f", coef(m)[1])), collapse = " & ")
  se_row <- paste(sapply(models, function(m) sprintf("(%.3f)", se(m)[1])), collapse = " & ")
  n_row <- paste(sapply(models, function(m) formatC(m$nobs, big.mark = ",")), collapse = " & ")

  tab3_lines <- c(tab3_lines,
    sprintf("Appeal allow rate & %s \\\\", coef_row),
    sprintf(" & %s \\\\", se_row),
    "[6pt]",
    "\\multicolumn{4}{l}{\\textit{Panel B: OLS}} \\\\[3pt]"
  )

  # OLS comparison (only for new builds)
  ols_coef <- sprintf("%.3f", coef(iv$ols_newbuild)[1])
  ols_se <- sprintf("(%.3f)", se(iv$ols_newbuild)[1])
  tab3_lines <- c(tab3_lines,
    sprintf("Appeal allow rate & %s & --- & --- \\\\", ols_coef),
    sprintf(" & %s & & \\\\", ols_se)
  )

  # First stage F (from LPA-level first stage)
  fs_f <- tryCatch(fitstat(iv$iv_newbuild, "ivf")$ivf$stat,
                   error = function(e) NA)

  tab3_lines <- c(tab3_lines,
    "\\hline",
    sprintf("$N$ & %s \\\\", n_row),
    sprintf("First-stage $F$ & \\multicolumn{3}{c}{%.1f} \\\\", fs_f),
    "LPA + Quarter FEs & \\multicolumn{3}{c}{Yes} \\\\",
    "\\hline",
    "\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Panel~A reports 2SLS estimates where the LPA-quarter appeal allow rate is instrumented by the average inspector leniency score assigned to that LPA-quarter. Panel~B reports OLS. New builds measured from Land Registry new-build transactions. All specifications include LPA and year-quarter fixed effects. Standard errors clustered at LPA level in parentheses.} \\\\",
    "\\end{tabular}",
    "\\end{table}"
  )

  writeLines(tab3_lines, "../tables/tab3_iv_results.tex")
  cat("Table 3 written.\n")
} else {
  cat("No IV results file — Table 3 will use reduced-form results.\n")

  # Alternative Table 3: Reduced form results
  tab3_lines <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Reduced Form: Inspector Leniency and Appeal Outcomes}",
    "\\label{tab:reduced_form}",
    "\\begin{tabular}{lcccc}",
    "\\hline\\hline",
    " & \\multicolumn{2}{c}{Appeal Allowed} & \\multicolumn{2}{c}{Leniency Quintile} \\\\",
    " & (1) & (2) & Allow Rate & $N$ \\\\",
    "\\hline"
  )

  # Load monotonicity data if available
  if (file.exists("../data/robustness_results.rds")) {
    rob <- readRDS("../data/robustness_results.rds")
    mono <- rob$mono_check
    for (i in seq_len(nrow(mono))) {
      tab3_lines <- c(tab3_lines,
        sprintf("Quintile %s & & & %.3f & %s \\\\",
                mono$leniency_quintile[i], mono$allow_rate[i],
                formatC(mono$n, big.mark = ",")))
    }
  }

  tab3_lines <- c(tab3_lines,
    "\\hline",
    "\\end{tabular}",
    "\\end{table}"
  )

  writeLines(tab3_lines, "../tables/tab3_reduced_form.tex")
  cat("Table 3 (reduced form) written.\n")
}

# =============================================================================
# Table 4: Robustness
# =============================================================================

cat("=== Table 4: Robustness ===\n")

if (file.exists("../data/robustness_results.rds")) {
  rob <- readRDS("../data/robustness_results.rds")

  tab4_lines <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Robustness of the First Stage}",
    "\\label{tab:robustness}",
    "\\begin{tabular}{lcccc}",
    "\\hline\\hline",
    "Specification & Coefficient & SE & $N$ & $F$-stat \\\\",
    "\\hline"
  )

  # Main specification
  main <- case_results$fs_1
  main_fstat <- (coef(main)[1] / se(main)[1])^2
  tab4_lines <- c(tab4_lines,
    sprintf("Baseline (cell-specific LOO) & %.4f & %.4f & %s & %.1f \\\\",
            coef(main)[1], se(main)[1], formatC(main$nobs, big.mark = ","),
            main_fstat))

  # Overall leniency
  tab4_lines <- c(tab4_lines,
    sprintf("Overall LOO (no cells) & %.4f & %.4f & %s & \\\\",
            coef(rob$fs_overall)[1], se(rob$fs_overall)[1],
            formatC(rob$fs_overall$nobs, big.mark = ",")))

  # Ex-LPA leniency
  tab4_lines <- c(tab4_lines,
    sprintf("Excluding same-LPA cases & %.4f & %.4f & %s & \\\\",
            coef(rob$fs_exlpa)[1], se(rob$fs_exlpa)[1],
            formatC(rob$fs_exlpa$nobs, big.mark = ",")))

  # LOIO range
  tab4_lines <- c(tab4_lines,
    sprintf("Leave-one-inspector-out range & [%.4f, %.4f] & & & \\\\",
            min(rob$loio_results$coef), max(rob$loio_results$coef)))

  tab4_lines <- c(tab4_lines,
    "\\hline",
    "\\multicolumn{5}{p{0.9\\textwidth}}{\\footnotesize \\textit{Notes:} Each row reports the first-stage coefficient from a regression of appeal outcome (allowed=1) on inspector leniency with LPA$\\times$case-type and year$\\times$case-type fixed effects, except where noted. ``Excluding same-LPA cases'' computes each inspector's leniency from all cases outside the current LPA. Leave-one-inspector-out range drops each of the 20 most prolific inspectors in turn. Standard errors clustered at LPA level.} \\\\",
    "\\end{tabular}",
    "\\end{table}"
  )

  writeLines(tab4_lines, "../tables/tab4_robustness.tex")
  cat("Table 4 written.\n")
}

# =============================================================================
# Table F1: SDE Appendix (MANDATORY)
# =============================================================================

cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDEs from the main results
# We need: beta_hat, SE, SD(Y)

# For case-level first stage: beta = leniency coefficient, Y = allowed
beta_fs <- coef(case_results$fs_1)["leniency"]
se_fs <- se(case_results$fs_1)["leniency"]
sd_y_allowed <- sd(cases$allowed)
sde_fs <- beta_fs / sd_y_allowed
se_sde_fs <- se_fs / sd_y_allowed

# Classification function
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

# Build SDE rows
sde_rows <- data.table(
  Outcome = "Appeal allowed (first stage)",
  Beta = sprintf("%.4f", beta_fs),
  SE = sprintf("%.4f", se_fs),
  SD_Y = sprintf("%.3f", sd_y_allowed),
  SDE = sprintf("%.4f", sde_fs),
  SE_SDE = sprintf("%.4f", se_sde_fs),
  Classification = classify_sde(sde_fs)
)

# Add IV results if available
if (file.exists("../data/iv_results.rds")) {
  iv <- readRDS("../data/iv_results.rds")
  lpa_iv <- fread("../data/lpa_quarter_panel.csv")

  # Try to get SD(Y) from the data
  if (file.exists("../data/lr_district_panel.csv")) {
    lr_panel <- fread("../data/lr_district_panel.csv")
    sd_y_nb <- sd(log(lr_panel$n_new_build + 1), na.rm = TRUE)
    sd_y_price <- sd(log(lr_panel$median_price), na.rm = TRUE)

    beta_nb <- coef(iv$iv_newbuild)[1]
    se_nb <- se(iv$iv_newbuild)[1]
    sde_nb <- beta_nb / sd_y_nb
    se_sde_nb <- se_nb / sd_y_nb

    beta_price <- coef(iv$iv_price)[1]
    se_price <- se(iv$iv_price)[1]
    sde_price <- beta_price / sd_y_price
    se_sde_price <- se_price / sd_y_price

    sde_rows <- rbind(sde_rows, data.table(
      Outcome = c("ln(New builds) (2SLS)", "ln(Median price) (2SLS)"),
      Beta = c(sprintf("%.4f", beta_nb), sprintf("%.4f", beta_price)),
      SE = c(sprintf("%.4f", se_nb), sprintf("%.4f", se_price)),
      SD_Y = c(sprintf("%.3f", sd_y_nb), sprintf("%.3f", sd_y_price)),
      SDE = c(sprintf("%.4f", sde_nb), sprintf("%.4f", sde_price)),
      SE_SDE = c(sprintf("%.4f", se_sde_nb), sprintf("%.4f", se_sde_price)),
      Classification = c(classify_sde(sde_nb), classify_sde(sde_price))
    ))
  }
}

# Heterogeneity: Householder vs Planning appeals (first stage)
cases_hh <- cases[case_type_clean == "Householder"]
cases_plan <- cases[case_type_clean == "Planning"]

if (nrow(cases_hh) > 50 && nrow(cases_plan) > 50) {
  fit_hh <- feols(allowed ~ leniency | lpa_clean + decision_year, data = cases_hh, cluster = ~lpa_clean)
  fit_plan <- feols(allowed ~ leniency | lpa_clean + decision_year, data = cases_plan, cluster = ~lpa_clean)

  sd_y_hh <- sd(cases_hh$allowed)
  sd_y_plan <- sd(cases_plan$allowed)

  sde_rows <- rbind(sde_rows, data.table(
    Outcome = c("Allowed: Householder appeals", "Allowed: Planning appeals"),
    Beta = c(sprintf("%.4f", coef(fit_hh)[1]), sprintf("%.4f", coef(fit_plan)[1])),
    SE = c(sprintf("%.4f", se(fit_hh)[1]), sprintf("%.4f", se(fit_plan)[1])),
    SD_Y = c(sprintf("%.3f", sd_y_hh), sprintf("%.3f", sd_y_plan)),
    SDE = c(sprintf("%.4f", coef(fit_hh)[1] / sd_y_hh), sprintf("%.4f", coef(fit_plan)[1] / sd_y_plan)),
    SE_SDE = c(sprintf("%.4f", se(fit_hh)[1] / sd_y_hh), sprintf("%.4f", se(fit_plan)[1] / sd_y_plan)),
    Classification = c(classify_sde(coef(fit_hh)[1] / sd_y_hh), classify_sde(coef(fit_plan)[1] / sd_y_plan))
  ))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Does quasi-random assignment to more lenient planning inspectors increase the probability of appeal success and subsequent housing construction in England? ",
  "\\textbf{Policy mechanism:} England's Planning Inspectorate assigns professional inspectors from a national pool to adjudicate planning appeals; inspectors bring systematically different professional judgments, creating stable variation in strictness that is orthogonal to case characteristics within local planning authority and case-type cells. ",
  "\\textbf{Outcome definition:} Panel~A pooled outcome is a binary indicator for whether the planning appeal was allowed (1) or dismissed (0); Panel~B splits by householder vs.\\ full planning appeals. ",
  "\\textbf{Treatment:} Binary (allowed vs.\\ dismissed), instrumented by leave-one-out inspector leniency score. ",
  "\\textbf{Data:} UK Planning Inspectorate Appeal Case Portal, case-level records with inspector identities extracted from decision letter PDFs, covering England 2019--2023. ",
  "\\textbf{Method:} Inspector leniency IV following Dobbie, Goldin, and Yang (2018); leave-one-out leniency constructed within case-type-by-year cells; LPA-clustered standard errors; balance tests confirm quasi-random assignment. ",
  "\\textbf{Sample:} Planning appeals decided by PINS inspectors in England; restricted to inspectors with at least 5 observed decisions for stable leniency estimation. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sprintf("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]")
)

# Panel A: pooled rows (first 1-3 rows)
n_pooled <- min(nrow(sde_rows), 3)
for (i in seq_len(n_pooled)) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
            sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
            sde_rows$Classification[i]))
}

# Panel B: heterogeneous rows
if (nrow(sde_rows) > n_pooled) {
  sde_lines <- c(sde_lines,
    "[6pt]",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by appeal type)}} \\\\[3pt]"
  )
  for (i in (n_pooled + 1):nrow(sde_rows)) {
    sde_lines <- c(sde_lines,
      sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
              sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
              sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
              sde_rows$Classification[i]))
  }
}

sde_lines <- c(sde_lines,
  "\\hline",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\begin{itemize}[leftmargin=*]",
  sde_notes,
  "\\end{itemize}",
  "\\end{minipage}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== ALL TABLES COMPLETE ===\n")
