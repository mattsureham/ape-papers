## 05_tables.R — Generate all tables for the paper
## APEP-0739: GP Practice Closures and A&E Utilization

source("code/00_packages.R")

ae_qtr     <- readRDS("data/ae_analysis.rds")
results    <- readRDS("data/main_results.rds")
robust     <- readRDS("data/robustness_results.rds")
gp_closures <- readRDS("data/gp_closures_mapped.rds")

dir.create("tables", showWarnings = FALSE, recursive = TRUE)


cat("=== TABLE 1: Summary Statistics ===\n")

## Panel A: GP Closures
closure_summary <- gp_closures[, .(
  n_closures = .N,
  mean_dist_km = round(mean(dist_to_trust_km), 1),
  median_dist_km = round(median(dist_to_trust_km), 1)
), by = closure_year][order(closure_year)]

## Panel B: A&E Trust Outcomes
trust_summary <- ae_qtr[, .(
  mean_type1 = round(mean(type1_att, na.rm = TRUE), 0),
  sd_type1 = round(sd(type1_att, na.rm = TRUE), 0),
  mean_total = round(mean(total_att, na.rm = TRUE), 0),
  sd_total = round(sd(total_att, na.rm = TRUE), 0)
), by = .(Group = ifelse(first_treat_qtr > 0, "Treated (closure within 15 km)", "Never-treated"))]

## Panel C: Overall
overall <- data.table(
  Statistic = c("NHS trusts in sample", "Trust-quarters", "GP closures (2015--2024)",
                "Treated trusts", "Never-treated trusts", "Quarters covered"),
  Value = c(
    uniqueN(ae_qtr$provider_code),
    nrow(ae_qtr),
    nrow(gp_closures),
    uniqueN(ae_qtr[first_treat_qtr > 0, provider_code]),
    uniqueN(ae_qtr[first_treat_qtr == 0, provider_code]),
    paste0(min(ae_qtr$qtr_num), "--", max(ae_qtr$qtr_num), " (2018Q2--2025Q1)")
  )
)

## Write LaTeX
tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{5}{l}{\\textit{Panel A: GP Practice Closures by Year}} \\\\",
  "\\hline",
  "Year & Closures & Mean Dist. (km) & Median Dist. (km) & \\\\",
  "\\hline"
)
for (i in seq_len(nrow(closure_summary))) {
  r <- closure_summary[i]
  tab1 <- c(tab1, sprintf("%d & %d & %.1f & %.1f & \\\\", r$closure_year, r$n_closures, r$mean_dist_km, r$median_dist_km))
}
tab1 <- c(tab1,
  sprintf("Total & %d & %.1f & %.1f & \\\\", nrow(gp_closures), mean(gp_closures$dist_to_trust_km), median(gp_closures$dist_to_trust_km)),
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{5}{l}{\\textit{Panel B: A\\&E Attendances by Treatment Status}} \\\\",
  "\\hline",
  " & Mean Type 1 & SD Type 1 & Mean Total & SD Total \\\\",
  "\\hline"
)
for (i in seq_len(nrow(trust_summary))) {
  r <- trust_summary[i]
  tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s \\\\", r$Group, format(r$mean_type1, big.mark = ","), format(r$sd_type1, big.mark = ","), format(r$mean_total, big.mark = ","), format(r$sd_total, big.mark = ",")))
}
tab1 <- c(tab1,
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{5}{l}{\\textit{Panel C: Sample}} \\\\",
  "\\hline"
)
for (i in seq_len(nrow(overall))) {
  tab1 <- c(tab1, sprintf("%s & \\multicolumn{4}{c}{%s} \\\\", overall$Statistic[i], overall$Value[i]))
}
tab1 <- c(tab1, "\\hline\\hline", "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} GP closures identified from NHS ODS API (inactive practices with role RO177). A\\&E attendances from NHS England monthly provider statistics. Type~1 = major emergency departments. Treated trusts have at least one GP closure within 15~km during the sample period. Distance measured as Haversine distance between practice and trust postcodes.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1, "tables/tab1_summary.tex")
cat("Table 1 written.\n")


cat("\n=== TABLE 2: Main Results ===\n")

## Extract coefficients
twfe1 <- results$twfe1
twfe2 <- results$twfe2
twfe3 <- results$twfe3
twfe4 <- results$twfe4
cs_overall <- results$cs_overall

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of GP Practice Closures on A\\&E Attendances}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Log Type 1 & Log Type 1 & Type 1 & Log Total & CS-DiD \\\\",
  " & Binary & Intensity & Levels & Binary & \\\\",
  "\\hline",
  sprintf("Post $\\times$ Treated & %.4f & & %.1f & %.4f & %.4f \\\\",
          coef(twfe1)[1], coef(twfe3)[1], coef(twfe4)[1], cs_overall$overall.att),
  sprintf(" & (%.4f) & & (%.1f) & (%.4f) & (%.4f) \\\\",
          se(twfe1)[1], se(twfe3)[1], se(twfe4)[1], cs_overall$overall.se),
  sprintf("Cumulative closures & & %.4f & & & \\\\", coef(twfe2)[1]),
  sprintf(" & & (%.4f) & & & \\\\", se(twfe2)[1]),
  "\\\\[-1.0ex]",
  "\\hline",
  "Trust FE & Yes & Yes & Yes & Yes & -- \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & -- \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(twfe1), big.mark = ","),
          format(nobs(twfe2), big.mark = ","),
          format(nobs(twfe3), big.mark = ","),
          format(nobs(twfe4), big.mark = ","),
          format(cs_overall$DIDparams$n, big.mark = ",")),
  sprintf("Trusts & %d & %d & %d & %d & %d \\\\",
          length(fixef(twfe1)$provider_code),
          length(fixef(twfe2)$provider_code),
          length(fixef(twfe3)$provider_code),
          length(fixef(twfe4)$provider_code),
          cs_overall$DIDparams$n_group),
  "Estimator & TWFE & TWFE & TWFE & TWFE & CS \\\\",
  "Clustering & Trust & Trust & Trust & Trust & Trust \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Columns~(1)--(4) report two-way fixed effects estimates. Column~(5) reports the overall ATT from Callaway and Sant'Anna (2021) using doubly robust estimation with never-treated trusts as the control group. The dependent variable is the natural log of quarterly Type~1 (major) A\\&E attendances in columns~(1)--(2) and~(5), Type~1 levels in column~(3), and log total attendances (all types) in column~(4). Post $\\times$ Treated equals one in quarters after the first GP closure within 15~km. Cumulative closures counts all closures within 15~km up to quarter~$t$. Standard errors clustered at the trust level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2, "tables/tab2_main.tex")
cat("Table 2 written.\n")


cat("\n=== TABLE 3: Event Study ===\n")

## Extract TWFE event study coefficients
twfe_es <- results$twfe_es
es_coefs <- data.table(
  event_time = c(-6:-2, 0:6),
  beta = coef(twfe_es),
  se = se(twfe_es)
)

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: A\\&E Attendances Around GP Closure}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  "Event Quarter & Coefficient & Std. Error & 95\\% CI \\\\",
  "\\hline"
)
for (i in seq_len(nrow(es_coefs))) {
  r <- es_coefs[i]
  ci_lo <- r$beta - 1.96 * r$se
  ci_hi <- r$beta + 1.96 * r$se
  stars <- ifelse(abs(r$beta / r$se) > 2.576, "$^{***}$",
           ifelse(abs(r$beta / r$se) > 1.96, "$^{**}$",
           ifelse(abs(r$beta / r$se) > 1.645, "$^{*}$", "")))
  label <- ifelse(r$event_time == -1, "$-1$ (ref.)", as.character(r$event_time))
  if (r$event_time == -1) {
    tab3 <- c(tab3, sprintf("$-1$ (ref.) & 0 & -- & -- \\\\"))
  }
  tab3 <- c(tab3, sprintf("$%+d$ & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\",
                           r$event_time, r$beta, stars, r$se, ci_lo, ci_hi))
}
tab3 <- c(tab3,
  "\\hline",
  sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\", format(nobs(twfe_es), big.mark = ",")),
  sprintf("Trusts & \\multicolumn{3}{c}{%d} \\\\", length(fixef(twfe_es)$provider_code)),
  "Trust FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Quarter FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} TWFE event study estimates of the effect of GP practice closures on log Type~1 A\\&E quarterly attendances. Event time 0 is the quarter of first GP closure within 15~km. Reference period is $-1$. Endpoints ($-6$ and $+6$) are binned. Standard errors clustered at the trust level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3, "tables/tab3_eventstudy.tex")
cat("Table 3 written.\n")


cat("\n=== TABLE 4: Robustness Checks ===\n")

dist_results <- robust$dist_sensitivity

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  " & Coefficient & Std. Error & Treated & Obs. \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Distance Bandwidth}} \\\\"
)
for (i in seq_len(nrow(dist_results))) {
  r <- dist_results[i]
  tab4 <- c(tab4, sprintf("  %d km & %.4f & (%.4f) & %d & %s \\\\",
                           r$dist_km, r$beta, r$se, r$n_treated, format(r$n_obs, big.mark = ",")))
}
tab4 <- c(tab4,
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel B: Sample Restrictions}} \\\\",
  sprintf("  Excluding COVID & %.4f & (%.4f) & -- & %s \\\\",
          coef(robust$twfe_nocovid), se(robust$twfe_nocovid), format(nobs(robust$twfe_nocovid), big.mark = ",")),
  sprintf("  Excluding London & %.4f & (%.4f) & -- & %s \\\\",
          coef(robust$twfe_nolon), se(robust$twfe_nolon), format(nobs(robust$twfe_nolon), big.mark = ",")),
  sprintf("  Pre-2023 closures only & %.4f & (%.4f) & %d & %s \\\\",
          coef(robust$twfe_pre23), se(robust$twfe_pre23), robust$n_treated_pre23, format(nobs(robust$twfe_pre23), big.mark = ",")),
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo Outcome}} \\\\",
  sprintf("  Log total attendances & %.4f & (%.4f) & -- & %s \\\\",
          coef(robust$twfe_total), se(robust$twfe_total), format(nobs(robust$twfe_total), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All specifications include trust and quarter fixed effects with standard errors clustered at the trust level. Panel~A varies the maximum distance between a GP closure and the A\\&E trust to define treatment. Panel~B restricts the sample: COVID (2020Q1--2021Q2) quarters dropped, London trusts excluded, or only pre-2023 closures used for treatment definition. Panel~C uses log total attendances (Type~1 + 2 + 3) as a placebo: if closures mainly shift urgent care, total attendances (which include walk-in minor injury units) should show a different pattern.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4, "tables/tab4_robustness.tex")
cat("Table 4 written.\n")


cat("\n=== SDE TABLE (Appendix) ===\n")

## Compute SDEs from main results
## Primary outcome: log Type 1 A&E attendances
## SDE = β / SD(Y) for log outcome; but since Y is already logged,
## β IS the approximate percentage change
## For proper SDE: use levels specification and divide by pre-treatment SD

## From levels regression (twfe3)
beta_levels <- coef(results$twfe3)[1]
se_levels <- se(results$twfe3)[1]

## Pre-treatment SD of Type 1 attendances
pre_data <- ae_qtr[first_treat_qtr == 0 | qtr_num < first_treat_qtr]
sd_type1 <- sd(pre_data$type1_att, na.rm = TRUE)

sde_type1 <- beta_levels / sd_type1
se_sde_type1 <- se_levels / sd_type1

## Classification
classify_sde <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde >= 0.005 & sde < 0.05) return("Small positive")
  if (sde >= 0.05 & sde < 0.15) return("Moderate positive")
  if (sde >= 0.15) return("Large positive")
  if (sde <= -0.005 & sde > -0.05) return("Small negative")
  if (sde <= -0.05 & sde > -0.15) return("Moderate negative")
  if (sde <= -0.15) return("Large negative")
}

class_type1 <- classify_sde(sde_type1)
cat(sprintf("SDE for Type 1 A&E: %.4f (classification: %s)\n", sde_type1, class_type1))

## Also compute for log specification
beta_log <- coef(results$twfe1)[1]
se_log <- se(results$twfe1)[1]
sd_log <- sd(pre_data$log_type1, na.rm = TRUE)
sde_log <- beta_log / sd_log
se_sde_log <- se_log / sd_log
class_log <- classify_sde(sde_log)

## SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Do GP practice closures increase emergency department utilization, creating a fiscal externality from primary care consolidation? ",
  "\\textbf{Policy mechanism:} NHS GP practices that become inactive (through closure, merger, or reorganization) may reduce local primary care access, potentially forcing displaced patients to substitute toward costlier A\\&E departments for conditions treatable in general practice. ",
  "\\textbf{Outcome definition:} Quarterly Type~1 (major) A\\&E attendances at NHS acute trust level, measured from NHS England monthly provider statistics. ",
  "\\textbf{Treatment:} Binary indicator equal to one after the first GP practice closure within 15~km of the A\\&E trust. ",
  "\\textbf{Data:} NHS ODS API (GP closures) and NHS England A\\&E monthly statistics, 2018Q2--2025Q1, 261 trusts, 4,471 trust-quarters. ",
  "\\textbf{Method:} Two-way fixed effects with trust and quarter fixed effects; standard errors clustered at trust level. Robustness with Callaway--Sant'Anna (2021) doubly robust estimator. ",
  "\\textbf{Sample:} All NHS acute trusts with Type~1 A\\&E departments in England, 2018--2025. Treated trusts have at least one GP closure within 15~km. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sprintf("Type 1 A\\&E (levels) & %.1f & (%.1f) & %.1f & %.4f & %.4f & %s \\\\",
          beta_levels, se_levels, sd_type1, sde_type1, se_sde_type1, class_type1),
  sprintf("Type 1 A\\&E (log) & %.4f & (%.4f) & %.4f & %.4f & %.4f & %s \\\\",
          beta_log, se_log, sd_log, sde_log, se_sde_log, class_log),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabF1, "tables/tabF1_sde.tex")
cat("SDE table written.\n")

cat("\nAll tables generated.\n")
