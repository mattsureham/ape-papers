# 04_robustness.R — Event study + RDD + robustness checks
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("Loaded:", nrow(df), "obs\n")

# ============================================================
# Table 4: Event Study (pre-trend check)
# ============================================================
cat("\n=== Event Study ===\n")

# Create event-time dummies (omit t=-1 as reference)
df[, event_time := year - 2024]
df[, event_treated := treated * event_time]

# Event study with fixest's i() syntax
outcomes_es <- c("log_originations", "approval_rate", "minority_share")
outcome_labels <- c("Log Originations", "Approval Rate", "Minority Share")

es_models <- list()
for (i in seq_along(outcomes_es)) {
  yvar <- outcomes_es[i]
  form <- as.formula(paste0(yvar, " ~ i(event_time, treated, ref = -1) | census_tract + year"))
  es_models[[outcome_labels[i]]] <- feols(form, data = df, cluster = "msa_md")
}

# Extract event study coefficients for table
es_coefs <- list()
for (nm in names(es_models)) {
  ct <- coeftable(es_models[[nm]])
  es_coefs[[nm]] <- data.table(
    outcome = nm,
    term = rownames(ct),
    estimate = ct[, 1],
    se = ct[, 2],
    pval = ct[, 4]
  )
}
es_dt <- rbindlist(es_coefs)

# Reshape for LaTeX table
es_wide <- dcast(es_dt, term ~ outcome, value.var = c("estimate", "se"))

# Write event study table
tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study Estimates: CRA Reclassification Effects by Year}",
  "\\label{tab:eventstudy}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", length(outcome_labels)), collapse = "")),
  "\\toprule",
  paste0(" & ", paste(outcome_labels, collapse = " & "), " \\\\"),
  paste0(" & ", paste(paste0("(", seq_along(outcome_labels), ")"), collapse = " & "), " \\\\"),
  "\\midrule"
)

# Get unique event times in order
event_times <- sort(unique(es_dt[, as.numeric(gsub(".*::([-0-9]+):.*", "\\1",
                    gsub("event_time::(-?[0-9]+):treated", "\\1", term)))]))

for (et in event_times) {
  if (et == -1) {
    coef_line <- sprintf("$t %+d$ (ref.)", et)
    for (j in seq_along(outcome_labels)) {
      coef_line <- paste0(coef_line, " & ---")
    }
    tex_lines <- c(tex_lines, paste0(coef_line, " \\\\"))
    next
  }

  pattern <- paste0("event_time::", et, ":")
  coef_line <- sprintf("$t %+d$", et)
  se_line <- ""

  for (nm in outcome_labels) {
    row_idx <- es_dt[outcome == nm & grepl(as.character(et), term)]
    if (nrow(row_idx) > 0) {
      est <- row_idx$estimate[1]
      stderr <- row_idx$se[1]
      pv <- row_idx$pval[1]
      stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}", ifelse(pv < 0.1, "^{*}", "")))
      coef_line <- paste0(coef_line, sprintf(" & $%.4f%s$", est, stars))
      se_line <- paste0(se_line, sprintf(" & (%.4f)", stderr))
    } else {
      coef_line <- paste0(coef_line, " & ")
      se_line <- paste0(se_line, " & ")
    }
  }

  tex_lines <- c(tex_lines, paste0(coef_line, " \\\\"))
  tex_lines <- c(tex_lines, paste0(se_line, " \\\\[3pt]"))
}

tex_lines <- c(tex_lines,
  "\\midrule",
  sprintf("Observations & %s & %s & %s \\\\",
          formatC(nobs(es_models[[1]]), big.mark = ","),
          formatC(nobs(es_models[[2]]), big.mark = ","),
          formatC(nobs(es_models[[3]]), big.mark = ",")),
  "Tract FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Event study estimates of the interaction between reclassification status and year dummies, with $t = -1$ (2023) as the reference year. Standard errors clustered at the MSA/MD level. The pre-treatment coefficients ($t = -6$ to $t = -2$) test for parallel pre-trends. * p < 0.1, ** p < 0.05, *** p < 0.01.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_lines, file.path(tables_dir, "tab4_eventstudy.tex"))
cat("Wrote tab4_eventstudy.tex\n")

# Print pre-trend test
cat("\nPre-trend F-test (joint significance of pre-treatment coefficients):\n")
for (nm in names(es_models)) {
  pre_coefs <- grep("event_time::-[2-6]", names(coef(es_models[[nm]])), value = TRUE)
  if (length(pre_coefs) > 0) {
    wt <- wald(es_models[[nm]], pre_coefs)
    cat(sprintf("  %s: F = %.2f, p = %.4f\n", nm, wt$stat, wt$p))
  }
}

# ============================================================
# Table 5: RDD at 80% Threshold + Robustness
# ============================================================
cat("\n=== RDD at 80% Threshold ===\n")

# Use 2024 cross-section for RDD
# Running variable: income_pct - 80 (centered at cutoff)
df24 <- df[year == 2024]
df24[, running := income_pct - 80]

# Restrict to reasonable bandwidth around cutoff
df24_rdd <- df24[abs(running) <= 30]

rdd_outcomes <- c("log_originations", "approval_rate", "minority_share")
rdd_labels <- c("Log Originations", "Approval Rate", "Minority Share")

rdd_results <- list()
for (i in seq_along(rdd_outcomes)) {
  yvar <- rdd_outcomes[i]
  y <- df24_rdd[[yvar]]
  x <- df24_rdd$running

  # Remove NAs
  valid <- !is.na(y) & !is.na(x)
  y <- y[valid]
  x <- x[valid]

  if (length(y) > 100) {
    rdd_fit <- rdrobust(y = y, x = x, c = 0, kernel = "triangular")
    rdd_results[[rdd_labels[i]]] <- list(
      estimate = rdd_fit$coef[1],
      se = rdd_fit$se[3],  # robust SE
      pval = rdd_fit$pv[3],
      bw = rdd_fit$bws[1, 1],
      n_left = rdd_fit$N_h[1],
      n_right = rdd_fit$N_h[2]
    )
    cat(sprintf("  %s: coef = %.4f (%.4f), p = %.3f, bw = %.1f\n",
                rdd_labels[i], rdd_fit$coef[1], rdd_fit$se[3],
                rdd_fit$pv[3], rdd_fit$bws[1, 1]))
  }
}

# Write RDD + robustness table
tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: RDD at the 80\\% Income Threshold (2024 Cross-Section)}",
  "\\label{tab:rdd}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", length(rdd_labels)), collapse = "")),
  "\\toprule",
  paste0(" & ", paste(rdd_labels, collapse = " & "), " \\\\"),
  paste0(" & ", paste(paste0("(", seq_along(rdd_labels), ")"), collapse = " & "), " \\\\"),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Local Linear RDD}} \\\\"
)

coef_line <- "LMI Status"
se_line <- ""
bw_line <- "Bandwidth"
n_line <- "Effective $N$"

for (nm in rdd_labels) {
  if (!is.null(rdd_results[[nm]])) {
    r <- rdd_results[[nm]]
    stars <- ifelse(r$pval < 0.01, "^{***}", ifelse(r$pval < 0.05, "^{**}", ifelse(r$pval < 0.1, "^{*}", "")))
    coef_line <- paste0(coef_line, sprintf(" & $%.4f%s$", r$estimate, stars))
    se_line <- paste0(se_line, sprintf(" & (%.4f)", r$se))
    bw_line <- paste0(bw_line, sprintf(" & %.1f", r$bw))
    n_line <- paste0(n_line, sprintf(" & %s", formatC(r$n_left + r$n_right, big.mark = ",")))
  } else {
    coef_line <- paste0(coef_line, " & ---")
    se_line <- paste0(se_line, " & ")
    bw_line <- paste0(bw_line, " & ")
    n_line <- paste0(n_line, " & ")
  }
}

tex_lines <- c(tex_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"),
  paste0(bw_line, " \\\\"),
  paste0(n_line, " \\\\"),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: DiD Robustness}} \\\\"
)

# Donut hole: drop tracts within 2pp of 80%
df_donut <- df[abs(income_pct - 80) > 2 | treated == 0]
donut_models <- list()
for (yvar in rdd_outcomes) {
  form <- as.formula(paste0(yvar, " ~ treat_post | census_tract + year"))
  donut_models[[yvar]] <- feols(form, data = df_donut, cluster = "msa_md")
}

coef_line <- "Donut ($\\pm 2$pp)"
se_line <- ""
for (yvar in rdd_outcomes) {
  est <- coef(donut_models[[yvar]])["treat_post"]
  stderr <- se(donut_models[[yvar]])["treat_post"]
  pv <- pvalue(donut_models[[yvar]])["treat_post"]
  stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}", ifelse(pv < 0.1, "^{*}", "")))
  coef_line <- paste0(coef_line, sprintf(" & $%.4f%s$", est, stars))
  se_line <- paste0(se_line, sprintf(" & (%.4f)", stderr))
}
tex_lines <- c(tex_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\[3pt]")
)

# Temporal placebo: apply same DiD to fake treatment year (2022) among actual tracts
# Use only pre-treatment data (2018-2023) with 2022 as fake post
df_placebo <- df[year <= 2023]
df_placebo[, placebo_post := as.integer(year >= 2022)]
df_placebo[, placebo_tp := treated * placebo_post]

placebo_models <- list()
for (yvar in rdd_outcomes) {
  form <- as.formula(paste0(yvar, " ~ placebo_tp | census_tract + year"))
  placebo_models[[yvar]] <- tryCatch(
    feols(form, data = df_placebo, cluster = "msa_md"),
    error = function(e) NULL
  )
}

coef_line <- "Temporal Placebo (2022)"
se_line <- ""
for (yvar in rdd_outcomes) {
  if (!is.null(placebo_models[[yvar]])) {
    est <- coef(placebo_models[[yvar]])["placebo_tp"]
    stderr <- se(placebo_models[[yvar]])["placebo_tp"]
    pv <- pvalue(placebo_models[[yvar]])["placebo_tp"]
    stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}", ifelse(pv < 0.1, "^{*}", "")))
    coef_line <- paste0(coef_line, sprintf(" & $%.4f%s$", est, stars))
    se_line <- paste0(se_line, sprintf(" & (%.4f)", stderr))
  } else {
    coef_line <- paste0(coef_line, " & ---")
    se_line <- paste0(se_line, " & ")
  }
}

tex_lines <- c(tex_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports local linear RDD estimates using MSA-Adjusted Median Family Income as a percentage of area median as the running variable, with the LMI cutoff at 80\\%. Robust bias-corrected standard errors and MSE-optimal bandwidth (Cattaneo, Idrobo, and Titiunik 2020). Panel B reports DiD robustness checks. Donut drops tracts within 2 percentage points of the 80\\% threshold. Temporal placebo applies the same DiD specification to a fake treatment date of 2022, using only pre-treatment data (2018--2023). * p < 0.1, ** p < 0.05, *** p < 0.01.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_lines, file.path(tables_dir, "tab5_robustness.tex"))
cat("Wrote tab5_robustness.tex\n")
