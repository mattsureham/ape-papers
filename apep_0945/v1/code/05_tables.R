## 05_tables.R — Generate all tables for apep_0945 (AER: Insights format)
source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
panel <- fread("../data/panel.csv")
matched <- fread("../data/matched_durations.csv")

## =====================================================================
## Table 1: Summary Statistics
## =====================================================================
panel[, high_int := as.integer(share_econ_sig >= median(share_econ_sig, na.rm = TRUE))]
panel[, period := fifelse(year < 2017, "Pre-EO",
                   fifelse(year < 2021, "EO Active", "Post-Rescission"))]

summ <- panel[, .(
  mean_nprm = sprintf("%.2f", mean(n_nprm)),
  sd_nprm = sprintf("%.2f", sd(n_nprm)),
  mean_rule = sprintf("%.2f", mean(n_rule)),
  sd_rule = sprintf("%.2f", sd(n_rule)),
  N = sprintf("%d", .N)
), by = .(period, high_int)]
setorder(summ, period, high_int)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics by Regulatory Period and Treatment Intensity}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llccccc}",
  "\\hline\\hline",
  " & & \\multicolumn{2}{c}{NPRMs/month} & \\multicolumn{2}{c}{Rules/month} & \\\\",
  "\\cmidrule(lr){3-4}\\cmidrule(lr){5-6}",
  "Period & High Intensity & Mean & SD & Mean & SD & N \\\\",
  "\\hline"
)

period_labels <- c("Pre-EO" = "Pre-EO (2010--2016)",
                    "EO Active" = "EO Active (2017--2020)",
                    "Post-Rescission" = "Post-Rescission (2021--2024)")

for (i in 1:nrow(summ)) {
  row <- summ[i]
  pl <- period_labels[row$period]
  hi <- ifelse(row$high_int == 1, "Yes", "No")
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    pl, hi, row$mean_nprm, row$sd_nprm, row$mean_rule, row$sd_rule, row$N
  ))
  if (i %% 2 == 0 && i < nrow(summ)) tab1_lines <- c(tab1_lines, "\\addlinespace")
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Unit of observation is agency-month. ``High Intensity'' agencies are those above the median share of Economically Significant dockets in the pre-2017 Regulations.gov archive. NPRMs (Notices of Proposed Rulemaking) and Rules (Final Rules) are monthly counts per agency. 23 agencies with $\\geq$50 total dockets, balanced panel 2010--2024.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

## =====================================================================
## Table 2: Main Results
## =====================================================================
m1 <- results$m1; m2 <- results$m2; m3 <- results$m3; m4 <- results$m4; m5 <- results$m5

get_row <- function(model, var_name) {
  ct <- coeftable(model)
  if (!(var_name %in% rownames(ct))) return(list(est = "---", se = "", raw_est = NA, raw_se = NA))
  est <- ct[var_name, "Estimate"]
  se <- ct[var_name, "Std. Error"]
  pv <- ct[var_name, "Pr(>|t|)"]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  list(est = sprintf("%.3f%s", est, stars),
       se = sprintf("(%.3f)", se),
       raw_est = est, raw_se = se)
}

models <- list(m1, m2, m3, m4, m5)
col_names <- c("Log NPRMs", "Log Rules", "Log Total", "Duration", "Rule/NPRM")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Main Results: Effect of EO 13771 on Federal Rulemaking}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  sprintf(" & %s \\\\", paste(paste0("(", 1:5, ")"), collapse = " & ")),
  sprintf(" & %s \\\\", paste(col_names, collapse = " & ")),
  "\\hline"
)

eo_row <- lapply(models, function(m) get_row(m, "post_eo_x_intensity"))
tab2_lines <- c(tab2_lines,
  sprintf("Post-EO $\\times$ Intensity & %s \\\\",
    paste(sapply(eo_row, `[[`, "est"), collapse = " & ")),
  sprintf(" & %s \\\\",
    paste(sapply(eo_row, `[[`, "se"), collapse = " & ")),
  "\\addlinespace"
)

resc_row <- lapply(models, function(m) get_row(m, "post_rescission_x_intensity"))
tab2_lines <- c(tab2_lines,
  sprintf("Post-Rescission $\\times$ Intensity & %s \\\\",
    paste(sapply(resc_row, `[[`, "est"), collapse = " & ")),
  sprintf(" & %s \\\\",
    paste(sapply(resc_row, `[[`, "se"), collapse = " & "))
)

tab2_lines <- c(tab2_lines,
  "\\addlinespace",
  "\\hline",
  sprintf("Agency FE & %s \\\\", paste(rep("Yes", 5), collapse = " & ")),
  sprintf("Time FE & %s \\\\", paste(c("Month", "Month", "Month", "Year", "Month"), collapse = " & ")),
  sprintf("Observations & %s \\\\",
    paste(sapply(models, function(m) formatC(m$nobs, format = "d", big.mark = ",")),
          collapse = " & ")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the agency level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ``Intensity'' is the agency's pre-2017 share of Economically Significant rulemaking dockets. Post-EO: February 2017 onward; Post-Rescission: February 2021 onward; reference: January 2010--January 2017. Columns (1)--(3) and (5): agency-month panel, 23 agencies, 180 months. Column (4): docket-level, days from NPRM to Final Rule, restricted to NPRMs filed before 2021. Column (5) is the ratio of Final Rules to max(NPRMs, 1). ``---'' indicates variable dropped for collinearity.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

## =====================================================================
## Table 3: Event Study (selected quarterly coefficients)
## =====================================================================
es_coefs <- fread("../data/event_study_coefs.csv")
es_coefs[, rel_qtr := as.numeric(gsub(".*::([-0-9.]+):.*", "\\1", term))]
es_coefs <- es_coefs[!is.na(rel_qtr)]
setorder(es_coefs, rel_qtr)

key_qtrs <- c(-8, -6, -4, -2, 0, 2, 4, 6, 8, 10, 12, 14, 16, 20, 24, 28)
es_sub <- es_coefs[rel_qtr %in% key_qtrs]

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Quarterly Treatment Effects on Log NPRM Volume}",
  "\\label{tab:event}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Relative Quarter & Coefficient & SE \\\\",
  "\\hline"
)

for (i in 1:nrow(es_sub)) {
  row <- es_sub[i]
  pv <- row$pval
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  label <- ifelse(row$rel_qtr < 0, sprintf("$t%d$", row$rel_qtr),
            ifelse(row$rel_qtr == 0, "$t$ (EO signed)", sprintf("$t+%d$", row$rel_qtr)))
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %.3f%s & (%.3f) \\\\",
    label, row$estimate, stars, row$se
  ))
  if (row$rel_qtr == -2) tab3_lines <- c(tab3_lines, "\\hline")
  if (row$rel_qtr == 14) tab3_lines <- c(tab3_lines, "\\addlinespace",
    "\\multicolumn{3}{l}{\\textit{Post-Rescission (2021+):}} \\\\")
}

tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Each coefficient is the interaction of agency-level Intensity $\\times$ quarter relative to 2016-Q4 (omitted). Outcome: log NPRM count at the agency-quarter level. Standard errors clustered at the agency level. Horizontal line separates pre-EO period from post-EO period. Post-Rescission begins at $t+16$ (2021-Q1).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_event.tex")
cat("Table 3 written.\n")

## =====================================================================
## Table 4: Robustness
## =====================================================================
placebo <- rob$placebo
loo_epa <- rob$loo_epa
loo_faa <- rob$loo_faa
binary <- rob$binary

get_coef_str <- function(model, var_name) {
  ct <- coeftable(model)
  if (!(var_name %in% rownames(ct))) return(c("---", ""))
  est <- ct[var_name, "Estimate"]
  se <- ct[var_name, "Std. Error"]
  pv <- ct[var_name, "Pr(>|t|)"]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  c(sprintf("%.3f%s", est, stars), sprintf("(%.3f)", se))
}

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Placebo 2013 & Drop EPA & Drop FAA & Binary Q4/Q1 \\\\",
  "\\hline"
)

p1 <- get_coef_str(placebo, "post_placebo_x_intensity")
p2 <- get_coef_str(loo_epa, "post_eo_x_intensity")
p3 <- get_coef_str(loo_faa, "post_eo_x_intensity")
p4 <- get_coef_str(binary, "post_eo_x_high")

tab4_lines <- c(tab4_lines,
  sprintf("Post $\\times$ Intensity & %s & %s & %s & %s \\\\", p1[1], p2[1], p3[1], p4[1]),
  sprintf(" & %s & %s & %s & %s \\\\", p1[2], p2[2], p3[2], p4[2]),
  "\\addlinespace"
)

# Post-rescission for columns 2-4
r2 <- get_coef_str(loo_epa, "post_rescission_x_intensity")
r3 <- get_coef_str(loo_faa, "post_rescission_x_intensity")
r4 <- get_coef_str(binary, "post_rescission_x_high")

tab4_lines <- c(tab4_lines,
  sprintf("Post-Rescission $\\times$ Int. & --- & %s & %s & %s \\\\", r2[1], r3[1], r4[1]),
  sprintf(" & & %s & %s & %s \\\\", r2[2], r3[2], r4[2]),
  "\\addlinespace",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    formatC(placebo$nobs, format = "d", big.mark = ","),
    formatC(loo_epa$nobs, format = "d", big.mark = ","),
    formatC(loo_faa$nobs, format = "d", big.mark = ","),
    formatC(binary$nobs, format = "d", big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Outcome: log NPRM count. Column (1): placebo treatment at 2013, pre-EO sample only (2010--2016). Column (2): drops EPA. Column (3): drops FAA. Column (4): binary treatment comparing top-quartile to bottom-quartile agencies by Economically Significant share. Standard errors clustered at the agency level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

## =====================================================================
## Table F1: Standardized Effect Sizes
## =====================================================================
panel_pre <- panel[year < 2017]
sd_x <- sd(panel$share_econ_sig, na.rm = TRUE)

compute_sde <- function(model, outcome_var, pre_data) {
  ct <- coeftable(model)
  var_nm <- "post_eo_x_intensity"
  if (!(var_nm %in% rownames(ct))) return(list(beta=NA, se=NA, sd_y=NA, sde=NA, se_sde=NA, class=""))
  beta <- ct[var_nm, "Estimate"]
  se_beta <- ct[var_nm, "Std. Error"]
  sd_y <- sd(pre_data[[outcome_var]], na.rm = TRUE)
  if (is.na(sd_y) || sd_y == 0) return(list(beta=beta, se=se_beta, sd_y=NA, sde=NA, se_sde=NA, class=""))
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y
  abs_sde <- abs(sde)
  classification <- ifelse(abs_sde < 0.005, "Null",
                    ifelse(abs_sde < 0.05, ifelse(sde > 0, "Small positive", "Small negative"),
                    ifelse(abs_sde < 0.15, ifelse(sde > 0, "Moderate positive", "Moderate negative"),
                    ifelse(sde > 0, "Large positive", "Large negative"))))
  list(beta=beta, se=se_beta, sd_y=sd_y, sde=sde, se_sde=se_sde, class=classification)
}

sde_nprm <- compute_sde(m1, "log_nprm", panel_pre)
sde_rule <- compute_sde(m2, "log_rule", panel_pre)
sde_total <- compute_sde(m3, "log_total", panel_pre)
sde_ratio <- compute_sde(m5, "rule_nprm_ratio", panel_pre)

# Heterogeneity: large vs small agencies
large_agencies <- panel[, .(total = sum(n_nprm + n_rule)), by = agency_id]
med_total <- median(large_agencies$total)
large_ids <- large_agencies[total >= med_total]$agency_id
panel[, yearmonth := factor(paste0(year, "-", sprintf("%02d", month)))]

m1_large <- feols(log_nprm ~ post_eo_x_intensity + post_rescission_x_intensity |
                    agency_id + yearmonth, data = panel[agency_id %in% large_ids], cluster = ~agency_id)
sde_large <- compute_sde(m1_large, "log_nprm", panel_pre[agency_id %in% large_ids])

m1_small <- feols(log_nprm ~ post_eo_x_intensity + post_rescission_x_intensity |
                    agency_id + yearmonth, data = panel[!(agency_id %in% large_ids)], cluster = ~agency_id)
sde_small <- compute_sde(m1_small, "log_nprm", panel_pre[!(agency_id %in% large_ids)])

format_sde_row <- function(label, s) {
  if (is.na(s$sde)) return(sprintf("%s & --- & --- & --- & --- & --- & --- \\\\", label))
  sprintf("%s & %.3f & (%.3f) & %.3f & %.3f & (%.3f) & %s \\\\",
          label, s$beta, s$se, s$sd_y, s$sde, s$se_sde, s$class)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does executive-mandated regulatory budgeting (EO 13771's two-for-one rule) ",
  "differentially alter rulemaking volume and composition at agencies with high baseline shares of ",
  "economically significant regulations? ",
  "\\textbf{Policy mechanism:} EO 13771 required each agency proposing a new significant regulation ",
  "to identify two existing regulations for repeal and capped net annual regulatory costs at zero, ",
  "creating a shadow price on new rulemaking that binds harder at agencies with more economically significant rules. ",
  "\\textbf{Outcome definition:} Log monthly count of Notices of Proposed Rulemaking (NPRMs), ",
  "log monthly count of Final Rules, log total rulemaking volume, and the ratio of Final Rules to NPRMs. ",
  "\\textbf{Treatment:} Continuous; agency-level pre-2017 share of Economically Significant dockets ",
  "(SD $= ", sprintf("%.3f", sd_x), "$). ",
  "\\textbf{Data:} Regulations.gov API, January 2010--December 2024, agency-month panel, ",
  sprintf("%s", formatC(nrow(panel), format = "d", big.mark = ",")), " observations across ",
  sprintf("%d", uniqueN(panel$agency_id)), " agencies. ",
  "\\textbf{Method:} Two-way fixed effects (agency + month) with continuous treatment intensity; ",
  "standard errors clustered at the agency level. ",
  "\\textbf{Sample:} 23 federal agencies with $\\geq$50 total rulemaking dockets; balanced panel. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the cross-agency standard deviation of treatment intensity. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (r in list(
  list("NPRM volume (log)", sde_nprm),
  list("Final Rule volume (log)", sde_rule),
  list("Total rulemaking (log)", sde_total),
  list("Rule/NPRM ratio", sde_ratio)
)) {
  tabF1_lines <- c(tabF1_lines, format_sde_row(r[[1]], r[[2]]))
}

tabF1_lines <- c(tabF1_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by agency size)}} \\\\",
  format_sde_row("NPRM volume --- large agencies", sde_large),
  format_sde_row("NPRM volume --- small agencies", sde_small),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")
cat("\n=== All tables generated ===\n")
