## 05_tables.R — Generate all LaTeX tables
## APEP-0745: The Freeport Gamble

source("00_packages.R")

cat("=== Generating Tables ===\n")
panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results_main.rds")
rob_results <- readRDS("../data/results_robustness.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("--- Table 1: Summary Statistics ---\n")

sum_treated_pre <- panel[treated_la == TRUE & post == FALSE, .(
  mean_inc = mean(n_inc),
  sd_inc = sd(n_inc),
  mean_log = mean(log_inc),
  sd_log = sd(log_inc),
  n_la_months = .N
)]
sum_treated_post <- panel[treated_la == TRUE & post == TRUE, .(
  mean_inc = mean(n_inc),
  sd_inc = sd(n_inc),
  mean_log = mean(log_inc),
  sd_log = sd(log_inc),
  n_la_months = .N
)]
sum_control <- panel[treated_la == FALSE, .(
  mean_inc = mean(n_inc),
  sd_inc = sd(n_inc),
  mean_log = mean(log_inc),
  sd_log = sd(log_inc),
  n_la_months = .N
)]

# Build table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Monthly Firm Incorporations by Local Authority}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Freeport LAs} & Control LAs \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4}",
  " & Pre-Activation & Post-Activation & \\\\",
  "\\hline",
  sprintf("Monthly incorporations & %.1f & %.1f & %.1f \\\\",
    sum_treated_pre$mean_inc, sum_treated_post$mean_inc, sum_control$mean_inc),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) \\\\",
    sum_treated_pre$sd_inc, sum_treated_post$sd_inc, sum_control$sd_inc),
  sprintf("Log(1 + incorporations) & %.3f & %.3f & %.3f \\\\",
    sum_treated_pre$mean_log, sum_treated_post$mean_log, sum_control$mean_log),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\",
    sum_treated_pre$sd_log, sum_treated_post$sd_log, sum_control$sd_log),
  sprintf("LA-months & %s & %s & %s \\\\",
    format(sum_treated_pre$n_la_months, big.mark = ","),
    format(sum_treated_post$n_la_months, big.mark = ","),
    format(sum_control$n_la_months, big.mark = ",")),
  sprintf("Unique LAs & %d & %d & %d \\\\",
    n_distinct(panel$la_code[panel$treated_la & !panel$post]),
    n_distinct(panel$la_code[panel$treated_la & panel$post]),
    n_distinct(panel$la_code[!panel$treated_la])),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard deviations in parentheses. Unit of observation is Local Authority $\\times$ month. Freeport LAs are those containing designated freeport tax sites. Pre-activation is January 2016 to the month before each freeport's tax site became active. Post-activation begins with the designated activation month. Control LAs are all other English Local Authorities.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================
# Table 2: Main Results (TWFE, CS-DiD, Poisson)
# ============================================================
cat("--- Table 2: Main Results ---\n")

# Extract estimates
twfe_est <- coef(results$twfe_main)["treat_post"]
twfe_se <- se(results$twfe_main)["treat_post"]
twfe_n <- results$twfe_main$nobs
twfe_r2 <- fitstat(results$twfe_main, "r2")$r2

cs_est <- results$cs_agg$overall.att
cs_se <- results$cs_agg$overall.se

pois_est <- coef(results$pois_main)["treat_post"]
pois_se <- se(results$pois_main)["treat_post"]
pois_n <- results$pois_main$nobs

# Stars function
stars <- function(est, se) {
  pval <- 2 * pnorm(-abs(est / se))
  if (pval < 0.01) return("***")
  if (pval < 0.05) return("**")
  if (pval < 0.1) return("*")
  return("")
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Freeport Designation on Firm Incorporations}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Monthly Firm Incorporations} \\\\",
  "\\cmidrule(lr){2-4}",
  " & (1) TWFE & (2) CS-DiD & (3) Poisson \\\\",
  " & log(1+N) & log(1+N) & Count \\\\",
  "\\hline",
  sprintf("Freeport $\\times$ Post & %.4f%s & %.4f%s & %.4f%s \\\\",
    twfe_est, stars(twfe_est, twfe_se),
    cs_est, stars(cs_est, cs_se),
    pois_est, stars(pois_est, pois_se)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\",
    twfe_se, cs_se, pois_se),
  "\\hline",
  "LA FE & Yes & --- & Yes \\\\",
  "Month FE & Yes & --- & Yes \\\\",
  sprintf("Observations & %s & %s & %s \\\\",
    format(twfe_n, big.mark = ","),
    format(twfe_n, big.mark = ","),
    format(pois_n, big.mark = ",")),
  sprintf("R$^2$ & %.3f & --- & --- \\\\", twfe_r2),
  sprintf("Treated LAs & %d & %d & %d \\\\",
    n_distinct(panel$la_code[panel$treated_la]),
    n_distinct(panel$la_code[panel$treated_la]),
    n_distinct(panel$la_code[panel$treated_la])),
  sprintf("Control LAs & %d & %d & %d \\\\",
    n_distinct(panel$la_code[!panel$treated_la]),
    n_distinct(panel$la_code[!panel$treated_la]),
    n_distinct(panel$la_code[!panel$treated_la])),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1. Standard errors clustered at the LA level in parentheses. Column (1) reports two-way fixed effects estimates with LA and year-month fixed effects. Column (2) reports Callaway and Sant'Anna (2021) group-time average treatment effects aggregated to an overall ATT. Column (3) reports Poisson pseudo-maximum likelihood estimates. The dependent variable is the monthly count of new company incorporations registered with Companies House, 2016--2025.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ============================================================
# Table 3: Robustness
# ============================================================
cat("--- Table 3: Robustness ---\n")

rob_specs <- list(
  list(name = "Baseline", model = results$twfe_main, var = "treat_post"),
  list(name = "Excl.\\ London", model = rob_results$twfe_nolon, var = "treat_post"),
  list(name = "Excl.\\ Thames", model = rob_results$twfe_nothames, var = "treat_post"),
  list(name = "Levels (N)", model = rob_results$twfe_levels, var = "treat_post"),
  list(name = "Placebo ($-$12m)", model = rob_results$twfe_placebo, var = "placebo_treat")
)

tab3_header <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  paste0("\\begin{tabular}{l", paste(rep("c", length(rob_specs)), collapse = ""), "}"),
  "\\hline\\hline"
)

# Column headers
col_names <- paste(sapply(seq_along(rob_specs), function(i)
  sprintf("(%d)", i)), collapse = " & ")
col_labels <- paste(sapply(rob_specs, function(x) x$name), collapse = " & ")
tab3_header <- c(tab3_header,
  paste0(" & ", col_names, " \\\\"),
  paste0(" & ", col_labels, " \\\\"),
  "\\hline"
)

# Coefficients row
coef_vals <- sapply(rob_specs, function(x) {
  est <- coef(x$model)[x$var]
  se_val <- se(x$model)[x$var]
  sprintf("%.4f%s", est, stars(est, se_val))
})
se_vals <- sapply(rob_specs, function(x) {
  sprintf("(%.4f)", se(x$model)[x$var])
})
n_vals <- sapply(rob_specs, function(x) {
  format(x$model$nobs, big.mark = ",")
})

tab3_body <- c(
  paste0("Estimate & ", paste(coef_vals, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_vals, collapse = " & "), " \\\\"),
  "\\hline",
  paste0("Observations & ", paste(n_vals, collapse = " & "), " \\\\"),
  "LA FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\"
)

tab3_footer <- c(
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1. Standard errors clustered at the LA level. Column (1) is the baseline specification from Table \\ref{tab:main}. Column (2) excludes London boroughs. Column (3) excludes the Thames freeport LAs (Thurrock, Barking and Dagenham, Havering). Column (4) uses the level of incorporations rather than the log transformation. Column (5) is a placebo test assigning a false treatment 12 months before actual activation, estimated on the pre-treatment sample only.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(c(tab3_header, tab3_body, tab3_footer), "../tables/tab3_robustness.tex")
cat("Table 3 written.\n")

# ============================================================
# Table 4: Event Study Coefficients
# ============================================================
cat("--- Table 4: Event Study ---\n")

cs_es <- results$cs_es
es_dt <- data.table(
  rel_time = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt
)
es_dt[, pval := 2 * pnorm(-abs(att / se))]
es_dt[, star := ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.1, "*", "")))]

# Select key periods
key_periods <- es_dt[rel_time %in% c(-24, -18, -12, -6, -1, 0, 6, 12, 18, 24, 36)]

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Dynamic Treatment Effects: Event Study Estimates}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Months Relative to Activation & ATT & SE \\\\",
  "\\hline",
  "\\textit{Pre-treatment} & & \\\\"
)

for (i in seq_len(nrow(key_periods))) {
  r <- key_periods[i]
  label <- if (r$rel_time < 0) sprintf("$t %d$", r$rel_time) else sprintf("$t + %d$", r$rel_time)
  if (r$rel_time == 0) label <- "$t = 0$ (activation)"
  if (r$rel_time == -1) {
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %.4f%s & (%.4f) \\\\", label, r$att, r$star, r$se),
      "\\hline",
      "\\textit{Post-treatment} & & \\\\"
    )
  } else {
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %.4f%s & (%.4f) \\\\", label, r$att, r$star, r$se)
    )
  }
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1. Callaway and Sant'Anna (2021) dynamic event study estimates. Period 0 is the month of freeport tax site activation. Pre-treatment coefficients test the parallel trends assumption. Standard errors in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")
cat("Table 4 written.\n")

# ============================================================
# Table F1: SDE Table (Appendix — MANDATORY)
# ============================================================
cat("--- Table F1: Standardized Effect Sizes ---\n")

# Calculate SDE for main outcomes
sd_y_pre <- sd(panel[treated_la == TRUE & post == FALSE]$log_inc)
beta_main <- coef(results$twfe_main)["treat_post"]
se_main <- se(results$twfe_main)["treat_post"]
sde_main <- beta_main / sd_y_pre
sde_se_main <- se_main / sd_y_pre

# Classification
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_class <- classify_sde(sde_main)

# Logistics sector
sd_y_logi <- sd(panel[treated_la == TRUE & post == FALSE]$n_logistics)
beta_logi <- coef(results$twfe_logistics)["treat_post"]
se_logi <- se(results$twfe_logistics)["treat_post"]
# For log outcome, SDE = beta / SD(log(1+Y))
sd_y_logi_log <- sd(log(1 + panel[treated_la == TRUE & post == FALSE]$n_logistics))
sde_logi <- beta_logi / sd_y_logi_log
sde_se_logi <- se_logi / sd_y_logi_log
sde_class_logi <- classify_sde(sde_logi)

# Levels SDE
sd_y_levels <- sd(panel[treated_la == TRUE & post == FALSE]$n_inc)
beta_levels <- coef(rob_results$twfe_levels)["treat_post"]
se_levels <- se(rob_results$twfe_levels)["treat_post"]
sde_levels <- beta_levels / sd_y_levels
sde_se_levels <- se_levels / sd_y_levels
sde_class_levels <- classify_sde(sde_levels)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Do freeport tax site designations increase monthly firm incorporations in treated Local Authorities relative to untreated English Local Authorities? ",
  "\\textbf{Policy mechanism:} Eight freeport tax sites designated 2021--2022 offering zero employer NICs, enhanced capital allowances, full business rates relief for five years, and SDLT relief to firms locating within the designated zone. ",
  "\\textbf{Outcome definition:} Monthly count of new company incorporations registered with Companies House in each Local Authority, measured as log(1+N) for the primary specification and count N for the levels specification. ",
  "\\textbf{Treatment:} Binary indicator equal to one for LA-months after the freeport tax site activation date. ",
  "\\textbf{Data:} Companies House bulk data (February 2026 snapshot), January 2016 to December 2025, Local Authority $\\times$ month panel. ",
  sprintf("Sample: %s LA-month observations across %d treated and %d control LAs. ",
    format(nrow(panel), big.mark = ","),
    n_distinct(panel$la_code[panel$treated_la]),
    n_distinct(panel$la_code[!panel$treated_la])),
  "\\textbf{Method:} Two-way fixed effects (LA and year-month FE) with standard errors clustered at LA level; Callaway-Sant'Anna (2021) as heterogeneity-robust alternative. ",
  "\\textbf{Sample:} All English Local Authorities with valid postcode-matched incorporations; excludes Scotland, Wales, Northern Ireland. ",
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
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sprintf("All incorporations (log) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta_main, se_main, sd_y_pre, sde_main, sde_se_main, sde_class),
  sprintf("Logistics (log) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta_logi, se_logi, sd_y_logi_log, sde_logi, sde_se_logi, sde_class_logi),
  sprintf("All incorporations (level) & %.2f & %.2f & %.1f & %.4f & %.4f & %s \\\\",
    beta_levels, se_levels, sd_y_levels, sde_levels, sde_se_levels, sde_class_levels),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
