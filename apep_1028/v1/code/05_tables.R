## 05_tables.R — Generate all tables for paper
## apep_1028: Right-to-Counsel and Community-Level Homelessness

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
rtc <- readRDS("../data/rtc_treatment.rds")

panel <- panel |>
  mutate(coc_id = as.integer(factor(coc_code)))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

pre_panel <- panel |> filter(year <= 2016)

summ_treated <- pre_panel |>
  filter(first_treat > 0) |>
  summarise(
    n = n_distinct(coc_code),
    mean_total = mean(total_homeless, na.rm = TRUE),
    sd_total = sd(total_homeless, na.rm = TRUE),
    mean_sheltered = mean(sheltered, na.rm = TRUE),
    sd_sheltered = sd(sheltered, na.rm = TRUE),
    mean_unsheltered = mean(unsheltered, na.rm = TRUE),
    sd_unsheltered = sd(unsheltered, na.rm = TRUE),
    mean_family = mean(homeless_family, na.rm = TRUE),
    sd_family = sd(homeless_family, na.rm = TRUE)
  )

summ_control <- pre_panel |>
  filter(first_treat == 0) |>
  summarise(
    n = n_distinct(coc_code),
    mean_total = mean(total_homeless, na.rm = TRUE),
    sd_total = sd(total_homeless, na.rm = TRUE),
    mean_sheltered = mean(sheltered, na.rm = TRUE),
    sd_sheltered = sd(sheltered, na.rm = TRUE),
    mean_unsheltered = mean(unsheltered, na.rm = TRUE),
    sd_unsheltered = sd(unsheltered, na.rm = TRUE),
    mean_family = mean(homeless_family, na.rm = TRUE),
    sd_family = sd(homeless_family, na.rm = TRUE)
  )

# Build LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Means (2007--2016)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{RTC CoCs ($N=14$)} & \\multicolumn{2}{c}{Control CoCs ($N=358$)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\hline",
  sprintf("Total Homeless & %s & %s & %s & %s \\\\",
          formatC(summ_treated$mean_total, format = "f", digits = 0, big.mark = ","),
          formatC(summ_treated$sd_total, format = "f", digits = 0, big.mark = ","),
          formatC(summ_control$mean_total, format = "f", digits = 0, big.mark = ","),
          formatC(summ_control$sd_total, format = "f", digits = 0, big.mark = ",")),
  sprintf("\\quad Sheltered & %s & %s & %s & %s \\\\",
          formatC(summ_treated$mean_sheltered, format = "f", digits = 0, big.mark = ","),
          formatC(summ_treated$sd_sheltered, format = "f", digits = 0, big.mark = ","),
          formatC(summ_control$mean_sheltered, format = "f", digits = 0, big.mark = ","),
          formatC(summ_control$sd_sheltered, format = "f", digits = 0, big.mark = ",")),
  sprintf("\\quad Unsheltered & %s & %s & %s & %s \\\\",
          formatC(summ_treated$mean_unsheltered, format = "f", digits = 0, big.mark = ","),
          formatC(summ_treated$sd_unsheltered, format = "f", digits = 0, big.mark = ","),
          formatC(summ_control$mean_unsheltered, format = "f", digits = 0, big.mark = ","),
          formatC(summ_control$sd_unsheltered, format = "f", digits = 0, big.mark = ",")),
  sprintf("\\quad Families & %s & %s & %s & %s \\\\",
          formatC(summ_treated$mean_family, format = "f", digits = 0, big.mark = ","),
          formatC(summ_treated$sd_family, format = "f", digits = 0, big.mark = ","),
          formatC(summ_control$mean_family, format = "f", digits = 0, big.mark = ","),
          formatC(summ_control$sd_family, format = "f", digits = 0, big.mark = ",")),
  sprintf("CoCs & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          summ_treated$n, summ_control$n),
  sprintf("CoC-Years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          formatC(nrow(pre_panel |> filter(first_treat > 0)), big.mark = ","),
          formatC(nrow(pre_panel |> filter(first_treat == 0)), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre-treatment period means and standard deviations for HUD Point-in-Time (PIT) homeless counts by Continuum of Care (CoC), 2007--2016. RTC CoCs are those where at least one city adopted Right-to-Counsel for eviction proceedings between 2017 and 2023. Control CoCs never adopted RTC during the sample period. Balanced panel requires CoCs to appear in at least 16 of 18 years (2007--2024).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================
# TABLE 2: Treatment Adoption Details
# ============================================================
cat("=== Table 2: RTC Adoption Details ===\n")

# Get pre-treatment means for each treated CoC
treated_details <- panel |>
  filter(first_treat > 0) |>
  group_by(coc_code, first_treat) |>
  summarise(
    pre_mean = mean(total_homeless[year < first_treat], na.rm = TRUE),
    .groups = "drop"
  ) |>
  left_join(rtc |> select(coc_code, cities), by = "coc_code") |>
  arrange(first_treat, coc_code)

tab2_rows <- treated_details |>
  mutate(row = sprintf("%s & %s & %d & %s \\\\",
                       cities, coc_code, first_treat,
                       formatC(pre_mean, format = "f", digits = 0, big.mark = ","))) |>
  pull(row)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Right-to-Counsel Adoption by Continuum of Care}",
  "\\label{tab:adoption}",
  "\\begin{tabular}{llcc}",
  "\\hline\\hline",
  "City & CoC Code & Adoption Year & Pre-Treatment Mean \\\\",
  "\\hline",
  tab2_rows,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Cities that adopted Right-to-Counsel (RTC) for eviction proceedings, mapped to HUD Continuum of Care (CoC) areas. Pre-treatment mean is the average annual PIT total homeless count before the adoption year. Where multiple cities share a CoC (e.g., Newark and Jersey City in NJ-500), the earliest adoption year is used. Sources: National Coalition for a Civil Right to Counsel (NCCRC), individual city ordinances.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_adoption.tex")
cat("Table 2 written.\n")

# ============================================================
# TABLE 3: Main Results (CS-DiD)
# ============================================================
cat("=== Table 3: Main Results ===\n")

# Extract CS ATT results
extract_att <- function(att_obj) {
  list(
    est = att_obj$overall.att,
    se = att_obj$overall.se,
    ci_lo = att_obj$overall.att - 1.96 * att_obj$overall.se,
    ci_hi = att_obj$overall.att + 1.96 * att_obj$overall.se
  )
}

att_t <- extract_att(results$att_total)
att_s <- extract_att(results$att_sheltered)
att_u <- extract_att(results$att_unsheltered)
att_f <- extract_att(results$att_family)

stars <- function(est, se) {
  p <- 2 * pnorm(-abs(est / se))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

fmt_est <- function(est, se) {
  s <- stars(est, se)
  sprintf("%.4f%s", est, s)
}

# Pre-treatment SD(Y) for each outcome
pre_sd <- panel |>
  filter(year <= 2016) |>
  summarise(
    sd_log_total = sd(log_total, na.rm = TRUE),
    sd_log_sheltered = sd(log_sheltered, na.rm = TRUE),
    sd_log_unsheltered = sd(log_unsheltered, na.rm = TRUE),
    sd_log_family = sd(log_family, na.rm = TRUE)
  )

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Right-to-Counsel on Community-Level Homelessness}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Total & Sheltered & Unsheltered & Families \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway-Sant'Anna}} \\\\[4pt]",
  sprintf("ATT & %s & %s & %s & %s \\\\",
          fmt_est(att_t$est, att_t$se),
          fmt_est(att_s$est, att_s$se),
          fmt_est(att_u$est, att_u$se),
          fmt_est(att_f$est, att_f$se)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          att_t$se, att_s$se, att_u$se, att_f$se),
  sprintf("95\\%% CI & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\[6pt]",
          att_t$ci_lo, att_t$ci_hi, att_s$ci_lo, att_s$ci_hi,
          att_u$ci_lo, att_u$ci_hi, att_f$ci_lo, att_f$ci_hi),
  "\\multicolumn{5}{l}{\\textit{Panel B: TWFE}} \\\\[4pt]",
  sprintf("Treated & %s & %s & %s & %s \\\\",
          fmt_est(coef(results$twfe_total)["treated"],
                  se(results$twfe_total)["treated"]),
          fmt_est(coef(results$twfe_sheltered)["treated"],
                  se(results$twfe_sheltered)["treated"]),
          fmt_est(coef(results$twfe_unsheltered)["treated"],
                  se(results$twfe_unsheltered)["treated"]),
          fmt_est(coef(results$twfe_family)["treated"],
                  se(results$twfe_family)["treated"])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]",
          se(results$twfe_total)["treated"],
          se(results$twfe_sheltered)["treated"],
          se(results$twfe_unsheltered)["treated"],
          se(results$twfe_family)["treated"]),
  "\\hline",
  sprintf("Pre-treatment SD($Y$) & %.3f & %.3f & %.3f & %.3f \\\\",
          pre_sd$sd_log_total, pre_sd$sd_log_sheltered,
          pre_sd$sd_log_unsheltered, pre_sd$sd_log_family),
  sprintf("CoCs & %d & %d & %d & %d \\\\",
          372, 372, 372, 372),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nrow(panel), big.mark = ","),
          formatC(nrow(panel), big.mark = ","),
          formatC(nrow(panel), big.mark = ","),
          formatC(nrow(panel), big.mark = ",")),
  sprintf("Treated CoCs & %d & %d & %d & %d \\\\",
          n_distinct(panel$coc_code[panel$first_treat > 0]),
          n_distinct(panel$coc_code[panel$first_treat > 0]),
          n_distinct(panel$coc_code[panel$first_treat > 0]),
          n_distinct(panel$coc_code[panel$first_treat > 0])),
  "Control group & Never-treated & Never-treated & Never-treated & Never-treated \\\\",
  "CoC \\& Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports Callaway-Sant'Anna (2021) staggered DiD ATT estimates using never-treated CoCs as the control group with universal base period. Panel B reports TWFE estimates with CoC and year fixed effects. All outcomes are in logs (log($Y + 1$)). Standard errors clustered at the CoC level in parentheses. The 95\\% confidence intervals are based on the pointwise Wald test. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_main.tex")
cat("Table 3 written.\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

rob_precovid <- extract_att(robust$att_precovid)
rob_nyt <- extract_att(robust$att_nyt)
rob_no_nyc <- extract_att(robust$att_no_nyc)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness of the Total Homelessness Null}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Specification & ATT & SE & 95\\% CI & $N$ \\\\",
  "\\hline",
  sprintf("\\textit{Baseline (CS, never-treated)} & %.4f & %.4f & [%.3f, %.3f] & %s \\\\",
          att_t$est, att_t$se, att_t$ci_lo, att_t$ci_hi,
          formatC(nrow(panel), big.mark = ",")),
  sprintf("Pre-COVID cohorts only (2017--2019) & %.4f & %.4f & [%.3f, %.3f] & %s \\\\",
          rob_precovid$est, rob_precovid$se, rob_precovid$ci_lo, rob_precovid$ci_hi,
          formatC(4716, big.mark = ",")),
  sprintf("Not-yet-treated controls & %.4f & %.4f & [%.3f, %.3f] & %s \\\\",
          rob_nyt$est, rob_nyt$se, rob_nyt$ci_lo, rob_nyt$ci_hi,
          formatC(nrow(panel), big.mark = ",")),
  sprintf("Drop NYC (NY-600) & %.4f & %.4f & [%.3f, %.3f] & %s \\\\",
          rob_no_nyc$est, rob_no_nyc$se, rob_no_nyc$ci_lo, rob_no_nyc$ci_hi,
          formatC(nrow(panel) - 18, big.mark = ",")),
  sprintf("Size-matched controls (>500) & %.4f & %.4f & & %s \\\\",
          coef(robust$twfe_large)["treated"],
          se(robust$twfe_large)["treated"],
          formatC(4338, big.mark = ",")),
  sprintf("TWFE, pct of pre-mean & %.2f & %.2f & & %s \\\\",
          coef(robust$twfe_pct)["treated"],
          se(robust$twfe_pct)["treated"],
          formatC(nrow(panel), big.mark = ",")),
  sprintf("Placebo ($t - 3$) & %.4f & %.4f & & %s \\\\",
          coef(robust$twfe_placebo)["treated_placebo"],
          se(robust$twfe_placebo)["treated_placebo"],
          formatC(6625, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each row reports the estimated effect of RTC on log total homeless counts under a different specification. Row 1 is the baseline Callaway-Sant'Anna estimate from Table~\\ref{tab:main}. Pre-COVID restricts to 2017--2019 adoption cohorts with data through 2019. Not-yet-treated uses later adopters as controls. Drop NYC removes the largest treated CoC (NY-600). Size-matched restricts controls to CoCs with pre-treatment mean $> 500$. Percent of pre-mean normalizes by each CoC's 2007--2016 average. Placebo shifts treatment dates back 3 years and uses only pre-treatment observations.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")
cat("Table 4 written.\n")

# ============================================================
# TABLE 5: Event Study Coefficients
# ============================================================
cat("=== Table 5: Event Study ===\n")

es <- results$es_total
es_df <- data.frame(
  event_time = es$egt,
  att = es$att.egt,
  se = es$se.egt
) |> filter(!is.na(se))

tab5_rows <- es_df |>
  mutate(
    s = sapply(1:n(), function(i) stars(att[i], se[i])),
    row = sprintf("$%+d$ & %s%s & (%.4f) \\\\",
                  event_time,
                  formatC(att, format = "f", digits = 4), s,
                  se)
  ) |>
  pull(row)

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event-Study Estimates: Log Total Homelessness}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Event Time & ATT & SE \\\\",
  "\\hline",
  tab5_rows,
  "\\hline",
  sprintf("Overall ATT & %s & (%.4f) \\\\",
          fmt_est(att_t$est, att_t$se), att_t$se),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Callaway-Sant'Anna (2021) dynamic ATT estimates by event time relative to RTC adoption year. Period $-1$ is the reference (normalized to zero). Never-treated CoCs serve as the comparison group. Standard errors clustered at the CoC level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_eventstudy.tex")
cat("Table 5 written.\n")

# ============================================================
# TABLE F1: SDE Appendix (MANDATORY)
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# SDE = beta / SD(Y), using pre-treatment SD
sde_total <- att_t$est / pre_sd$sd_log_total
sde_total_se <- att_t$se / pre_sd$sd_log_total

sde_sheltered <- att_s$est / pre_sd$sd_log_sheltered
sde_sheltered_se <- att_s$se / pre_sd$sd_log_sheltered

sde_unsheltered <- att_u$est / pre_sd$sd_log_unsheltered
sde_unsheltered_se <- att_u$se / pre_sd$sd_log_unsheltered

sde_family <- att_f$est / pre_sd$sd_log_family
sde_family_se <- att_f$se / pre_sd$sd_log_family

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_rows_a <- c(
  sprintf("Total Homeless & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          att_t$est, att_t$se, pre_sd$sd_log_total,
          sde_total, sde_total_se, classify(sde_total)),
  sprintf("Sheltered & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          att_s$est, att_s$se, pre_sd$sd_log_sheltered,
          sde_sheltered, sde_sheltered_se, classify(sde_sheltered)),
  sprintf("Unsheltered & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          att_u$est, att_u$se, pre_sd$sd_log_unsheltered,
          sde_unsheltered, sde_unsheltered_se, classify(sde_unsheltered)),
  sprintf("Families & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          att_f$est, att_f$se, pre_sd$sd_log_family,
          sde_family, sde_family_se, classify(sde_family))
)

# Panel B: Heterogeneous — Pre-COVID vs all cohorts
# Pre-COVID (2017-2019 adopters only)
att_pre <- extract_att(robust$att_precovid)
sde_precovid <- att_pre$est / pre_sd$sd_log_total
sde_precovid_se <- att_pre$se / pre_sd$sd_log_total

# Without NYC
att_nonyc <- extract_att(robust$att_no_nyc)
sde_nonyc <- att_nonyc$est / pre_sd$sd_log_total
sde_nonyc_se <- att_nonyc$se / pre_sd$sd_log_total

sde_rows_b <- c(
  sprintf("Pre-COVID Cohorts & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          att_pre$est, att_pre$se, pre_sd$sd_log_total,
          sde_precovid, sde_precovid_se, classify(sde_precovid)),
  sprintf("Excluding NYC & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          att_nonyc$est, att_nonyc$se, pre_sd$sd_log_total,
          sde_nonyc, sde_nonyc_se, classify(sde_nonyc))
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the adoption of Right-to-Counsel (RTC) in eviction proceedings reduce community-level homelessness in the adopting metropolitan area? ",
  "\\textbf{Policy mechanism:} RTC mandates that tenants below an income threshold (typically 200\\% FPL) receive free legal representation in eviction court, potentially reducing eviction execution rates and downstream housing instability. ",
  "\\textbf{Outcome definition:} Annual Point-in-Time (PIT) homeless count conducted by each Continuum of Care (CoC), measured in logs (log($Y + 1$)). ",
  "\\textbf{Treatment:} Binary; 1 if any city in the CoC adopted RTC by year $t$, 0 otherwise. ",
  "\\textbf{Data:} HUD PIT counts, 2007--2024, CoC-by-year panel, 372 CoCs, 6,693 observations. ",
  "\\textbf{Method:} Callaway-Sant'Anna staggered DiD with never-treated controls, standard errors clustered at CoC level. ",
  "\\textbf{Sample:} Balanced panel of CoCs present in $\\geq$16 of 18 years; 14 treated CoCs across 7 adoption cohorts (2017--2023), 358 never-treated controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome across all CoCs (2007--2016). ",
  "Classification refers to magnitude, not statistical significance: ",
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
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[4pt]",
  sde_rows_a,
  "[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\[4pt]",
  sde_rows_b,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 written.\n")

cat("\n=== All tables generated ===\n")
list.files("../tables/")
