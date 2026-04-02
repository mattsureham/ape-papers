# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# ==============================================================================

source("00_packages.R")

# --- Load models ---
summ_stats <- readRDS("../data/summ_stats.rds")
main_models <- readRDS("../data/main_models.rds")
sector_models <- readRDS("../data/sector_models.rds")
es_models <- readRDS("../data/event_study_models.rds")
rob_models <- readRDS("../data/robustness_models.rds")
qwi <- readRDS("../data/analysis_total.rds")

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================
cat("Generating Table 1: Summary Statistics\n")

baseline <- qwi[year == 2012 & quarter == 1]
high_fed <- baseline[fed_share >= quantile(fed_share, 0.75)]
low_fed <- baseline[fed_share < quantile(fed_share, 0.75)]

tab1 <- sprintf("\\begin{table}[t]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{tabular}{l *{4}{r}}
\\hline\\hline
& \\multicolumn{2}{c}{All Counties} & \\multicolumn{1}{c}{High Fed.} & \\multicolumn{1}{c}{Low Fed.} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-5}
& Mean & SD & Mean & Mean \\\\
\\hline
Federal employment share & %s & %s & %s & %s \\\\
Federal employment & %s & %s & %s & %s \\\\
Total employment & %s & %s & %s & %s \\\\
Private-sector employment & %s & %s & %s & %s \\\\
Private-sector avg.\\ earnings (\\$) & %s & %s & %s & %s \\\\
Population & %s & %s & %s & %s \\\\
\\hline
Counties & \\multicolumn{2}{c}{%s} & %s & %s \\\\
County $\\times$ quarter obs. & \\multicolumn{2}{c}{%s} & & \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Summary statistics at the county level from the 2012 baseline. Federal employment share is the ratio of federal government employment (QCEW, own\\_code = 5) to total covered employment. Private-sector outcomes are from QWI (2010--2022). High (low) federal share counties are those above (below) the 75th percentile of the federal employment share distribution. Employment and earnings are quarterly averages.
\\end{tablenotes}
\\end{table}",
  formatC(mean(baseline$fed_share), format = "f", digits = 3),
  formatC(sd(baseline$fed_share), format = "f", digits = 3),
  formatC(mean(high_fed$fed_share), format = "f", digits = 3),
  formatC(mean(low_fed$fed_share), format = "f", digits = 3),
  format(round(mean(baseline$fed_emp)), big.mark = ","),
  format(round(sd(baseline$fed_emp)), big.mark = ","),
  format(round(mean(high_fed$fed_emp)), big.mark = ","),
  format(round(mean(low_fed$fed_emp)), big.mark = ","),
  format(round(mean(baseline$total_emp)), big.mark = ","),
  format(round(sd(baseline$total_emp)), big.mark = ","),
  format(round(mean(high_fed$total_emp)), big.mark = ","),
  format(round(mean(low_fed$total_emp)), big.mark = ","),
  format(round(mean(baseline$private_emp, na.rm = TRUE)), big.mark = ","),
  format(round(sd(baseline$private_emp, na.rm = TRUE)), big.mark = ","),
  format(round(mean(high_fed$private_emp, na.rm = TRUE)), big.mark = ","),
  format(round(mean(low_fed$private_emp, na.rm = TRUE)), big.mark = ","),
  format(round(mean(baseline$private_earn, na.rm = TRUE)), big.mark = ","),
  format(round(sd(baseline$private_earn, na.rm = TRUE)), big.mark = ","),
  format(round(mean(high_fed$private_earn, na.rm = TRUE)), big.mark = ","),
  format(round(mean(low_fed$private_earn, na.rm = TRUE)), big.mark = ","),
  format(round(mean(baseline$population)), big.mark = ","),
  format(round(sd(baseline$population)), big.mark = ","),
  format(round(mean(high_fed$population)), big.mark = ","),
  format(round(mean(low_fed$population)), big.mark = ","),
  format(uniqueN(baseline$fips), big.mark = ","),
  format(uniqueN(high_fed$fips), big.mark = ","),
  format(uniqueN(low_fed$fips), big.mark = ","),
  format(nrow(qwi), big.mark = ",")
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ==============================================================================
# TABLE 2: Main DiD Results
# ==============================================================================
cat("Generating Table 2: Main DiD Results\n")

etable(main_models$m1, main_models$m2, main_models$m3, main_models$m4, main_models$m5,
       tex = TRUE,
       file = "../tables/tab2_main.tex",
       replace = TRUE,
       title = "Government Shutdowns and Private-Sector Outcomes",
       label = "tab:main",
       headers = c("ln(Emp)", "ln(Emp)", "Emp/1K pop", "ln(Earn)", "ln(Hires)"),
       dict = c(treat_shutdown = "FedShare $\\times$ Shutdown",
                treat_shutdown_2013 = "FedShare $\\times$ Shutdown 2013",
                treat_shutdown_2019 = "FedShare $\\times$ Shutdown 2019"),
       style.tex = style.tex("aer"),
       fitstat = ~ n + r2 + wr2,
       notes = c("County and quarter fixed effects in all columns.",
                  "Standard errors clustered at the state level in parentheses.",
                  "FedShare is the 2012 QCEW ratio of federal to total employment.",
                  "Shutdown is an indicator for 2013Q4 (16-day) and 2019Q1 (35-day)."))

# ==============================================================================
# TABLE 3: Sector Decomposition
# ==============================================================================
cat("Generating Table 3: Sector Decomposition\n")

etable(sector_models[["72"]], sector_models[["44-45"]],
       sector_models[["31-33"]], sector_models[["62"]],
       tex = TRUE,
       file = "../tables/tab3_sectors.tex",
       replace = TRUE,
       title = "Sector Decomposition: Consumption-Sensitive vs.\\ Placebo Industries",
       label = "tab:sectors",
       headers = c("Accomm./Food", "Retail", "Manufacturing", "Healthcare"),
       dict = c(treat_shutdown = "FedShare $\\times$ Shutdown"),
       style.tex = style.tex("aer"),
       fitstat = ~ n + wr2,
       notes = c("Dependent variable: ln(sector employment).",
                  "County and quarter fixed effects in all columns.",
                  "Standard errors clustered at the state level in parentheses.",
                  "Accommodation \\& Food (NAICS 72) and Retail (NAICS 44-45) are consumption-sensitive.",
                  "Manufacturing (NAICS 31-33) and Healthcare (NAICS 62) serve as placebo sectors."))

# ==============================================================================
# TABLE 4: Event Study Coefficients
# ==============================================================================
cat("Generating Table 4: Event Study\n")

es_2013 <- es_models$es_2013
es_2019 <- es_models$es_2019

# Extract coefficients for event study table
extract_es <- function(model, name) {
  cf <- coef(model)
  se_vals <- se(model)
  pv <- pvalue(model)
  # Get event-time coefficients
  idx <- grep("^et::", names(cf))
  et_names <- gsub("et::", "", names(cf)[idx])
  et_names <- gsub(":fed_share", "", et_names)
  data.frame(
    event_time = as.integer(et_names),
    coef = cf[idx],
    se = se_vals[idx],
    pval = pv[idx],
    event = name,
    stringsAsFactors = FALSE
  )
}

es_df_2013 <- extract_es(es_2013, "2013")
es_df_2019 <- extract_es(es_2019, "2019")

# Build LaTeX table manually
es_rows <- ""
for (t in -8:4) {
  if (t == -1) {
    es_rows <- paste0(es_rows, sprintf("$t = %d$ & \\multicolumn{2}{c}{---} & \\multicolumn{2}{c}{---} \\\\\n", t))
    next
  }
  r13 <- es_df_2013[es_df_2013$event_time == t, ]
  r19 <- es_df_2019[es_df_2019$event_time == t, ]

  c13 <- if (nrow(r13) > 0) sprintf("%.4f", r13$coef) else ""
  s13 <- if (nrow(r13) > 0) sprintf("(%.4f)", r13$se) else ""
  c19 <- if (nrow(r19) > 0) sprintf("%.4f", r19$coef) else ""
  s19 <- if (nrow(r19) > 0) sprintf("(%.4f)", r19$se) else ""

  # Stars
  star13 <- if (nrow(r13) > 0 && r13$pval < 0.01) "***" else if (nrow(r13) > 0 && r13$pval < 0.05) "**" else if (nrow(r13) > 0 && r13$pval < 0.1) "*" else ""
  star19 <- if (nrow(r19) > 0 && r19$pval < 0.01) "***" else if (nrow(r19) > 0 && r19$pval < 0.05) "**" else if (nrow(r19) > 0 && r19$pval < 0.1) "*" else ""

  es_rows <- paste0(es_rows, sprintf("$t = %d$ & %s%s & %s & %s%s & %s \\\\\n",
                                      t, c13, star13, s13, c19, star19, s19))
}

tab4 <- sprintf("\\begin{table}[t]
\\centering
\\caption{Event Study: Dynamic Effects of Shutdown on ln(Private Employment)}
\\label{tab:eventstudy}
\\begin{tabular}{l cc cc}
\\hline\\hline
& \\multicolumn{2}{c}{2013 Shutdown} & \\multicolumn{2}{c}{2019 Shutdown} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Quarter & Coeff. & SE & Coeff. & SE \\\\
\\hline
%s\\hline
County FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\
Quarter FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Coefficients on FedShare $\\times$ event-time indicators. $t = -1$ is the omitted reference quarter. Standard errors clustered at the state level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.
\\end{tablenotes}
\\end{table}", es_rows)
writeLines(tab4, "../tables/tab4_eventstudy.tex")

# ==============================================================================
# TABLE 5: Robustness
# ==============================================================================
cat("Generating Table 5: Robustness\n")

etable(main_models$m1,
       rob_models$alt_exposure,
       rob_models$excl_dc_va,
       rob_models$separations,
       rob_models$placebo,
       tex = TRUE,
       file = "../tables/tab5_robustness.tex",
       replace = TRUE,
       title = "Robustness Checks",
       label = "tab:robustness",
       headers = c("Baseline", "Alt. Exposure", "Excl. DC+VA", "Separations", "Placebo"),
       dict = c(treat_shutdown = "FedShare $\\times$ Shutdown",
                treat_shutdown_alt = "FedShare(2010) $\\times$ Shutdown",
                treat_placebo = "FedShare $\\times$ Placebo"),
       style.tex = style.tex("aer"),
       fitstat = ~ n + wr2,
       notes = c("Column 1 replicates the baseline from Table 2.",
                  "Column 2 uses 2010 QCEW federal share instead of 2012.",
                  "Column 3 excludes Washington DC and Virginia counties.",
                  "Column 4 uses ln(separations) as the dependent variable.",
                  "Column 5 uses a placebo shutdown in 2016Q4."))

# ==============================================================================
# TABLE F1: Standardized Effect Size (SDE) — Appendix
# ==============================================================================
cat("Generating SDE Table\n")

# Compute SDE for main outcomes
m1_coef <- coef(main_models$m1)["treat_shutdown"]
m1_se <- se(main_models$m1)["treat_shutdown"]

# Pre-treatment SD of outcomes
pre <- qwi[year < 2013]
sd_ln_emp <- sd(pre$ln_emp, na.rm = TRUE)
sd_emp_pc <- sd(pre$emp_pc, na.rm = TRUE)
sd_ln_earn <- sd(pre$ln_earn, na.rm = TRUE)
sd_ln_hires <- sd(log(pre$private_hires + 1), na.rm = TRUE)
sd_ln_sep <- sd(log(pre$private_sep + 1), na.rm = TRUE)

# SD of treatment variable
sd_treat <- sd(qwi[year == 2012 & quarter == 1]$fed_share, na.rm = TRUE)

# SDE for continuous treatment: β × SD(X) / SD(Y)
compute_sde <- function(beta, se_beta, sd_x, sd_y) {
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y
  bucket <- ifelse(abs(sde) < 0.005, "Null",
            ifelse(abs(sde) < 0.05, ifelse(sde > 0, "Small positive", "Small negative"),
            ifelse(abs(sde) < 0.15, ifelse(sde > 0, "Moderate positive", "Moderate negative"),
            ifelse(sde > 0, "Large positive", "Large negative"))))
  list(sde = sde, se_sde = se_sde, bucket = bucket)
}

outcomes <- data.frame(
  Outcome = c("Private employment (ln)", "Employment per capita",
              "Private earnings (ln)", "Private hires (ln)", "Private separations (ln)"),
  beta = c(coef(main_models$m1)["treat_shutdown"],
           coef(main_models$m3)["treat_shutdown"],
           coef(main_models$m4)["treat_shutdown"],
           coef(main_models$m5)["treat_shutdown"],
           coef(rob_models$separations)["treat_shutdown"]),
  se = c(se(main_models$m1)["treat_shutdown"],
         se(main_models$m3)["treat_shutdown"],
         se(main_models$m4)["treat_shutdown"],
         se(main_models$m5)["treat_shutdown"],
         se(rob_models$separations)["treat_shutdown"]),
  sd_y = c(sd_ln_emp, sd_emp_pc, sd_ln_earn, sd_ln_hires, sd_ln_sep),
  stringsAsFactors = FALSE
)

sde_results <- lapply(1:nrow(outcomes), function(i) {
  res <- compute_sde(outcomes$beta[i], outcomes$se[i], sd_treat, outcomes$sd_y[i])
  data.frame(
    Outcome = outcomes$Outcome[i],
    beta = outcomes$beta[i],
    se = outcomes$se[i],
    sd_y = outcomes$sd_y[i],
    sde = res$sde,
    se_sde = res$se_sde,
    Classification = res$bucket,
    stringsAsFactors = FALSE
  )
})
sde_df <- do.call(rbind, sde_results)

# Panel B: Heterogeneous — by sector (Accomm/Food vs Manufacturing)
sec_accom <- sector_models[["72"]]
sec_manuf <- sector_models[["31-33"]]
qwi_sec <- readRDS("../data/analysis_sector.rds")
pre_accom <- qwi_sec[industry == "72" & year < 2013]
pre_manuf <- qwi_sec[industry == "31-33" & year < 2013]

sde_accom <- compute_sde(coef(sec_accom)["treat_shutdown"], se(sec_accom)["treat_shutdown"],
                          sd_treat, sd(log(pre_accom$emp + 1), na.rm = TRUE))
sde_manuf <- compute_sde(coef(sec_manuf)["treat_shutdown"], se(sec_manuf)["treat_shutdown"],
                          sd_treat, sd(log(pre_manuf$emp + 1), na.rm = TRUE))

# Build SDE LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do federal government shutdowns reduce private-sector employment in counties with high federal employment concentration through local consumption multiplier effects? ",
  "\\textbf{Policy mechanism:} Government shutdowns furlough approximately 800,000 federal employees, temporarily halting their paychecks and reducing consumer spending in the local economy; the payroll interruption is exogenous to local economic conditions and operates through the consumption channel rather than the procurement channel. ",
  "\\textbf{Outcome definition:} Log of quarterly private-sector employment from the Quarterly Workforce Indicators (QWI), measuring total beginning-of-quarter jobs at private-sector establishments. ",
  "\\textbf{Treatment:} Continuous --- county-level federal employment share (ratio of federal government employment to total covered employment from QCEW 2012 baseline), interacted with shutdown quarter indicator. ",
  "\\textbf{Data:} QWI county-quarter private-sector employment (2010--2022) merged with QCEW 2012 federal employment shares; approximately ",
  format(nrow(qwi), big.mark = ","),
  " county-quarter observations across ",
  format(uniqueN(qwi$fips), big.mark = ","),
  " US counties. ",
  "\\textbf{Method:} Two-way fixed effects (county and quarter FE), continuous treatment DiD, standard errors clustered at the state level (51 clusters). ",
  "\\textbf{Sample:} All US counties with non-missing QWI employment and QCEW federal employment data, 2010Q1--2022Q4. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional ",
  "standard deviation of federal employment share and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- sprintf("\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{l *{6}{r} l}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
%s \\\\
%s \\\\
%s \\\\
%s \\\\
%s \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by sector)}} \\\\
Accommodation \\& Food (NAICS 72) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
Manufacturing (NAICS 31-33) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
%s
\\end{tablenotes}
\\end{table}",
  # Panel A rows
  paste(apply(sde_df, 1, function(r) {
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s", r[1], as.numeric(r[2]), as.numeric(r[3]),
            as.numeric(r[4]), as.numeric(r[5]), as.numeric(r[6]), r[7])
  }), collapse = " \\\\\n"),
  "", "", "", "",
  # Panel B
  coef(sec_accom)["treat_shutdown"], se(sec_accom)["treat_shutdown"],
  sd(log(pre_accom$emp + 1), na.rm = TRUE),
  sde_accom$sde, sde_accom$se_sde, sde_accom$bucket,
  coef(sec_manuf)["treat_shutdown"], se(sec_manuf)["treat_shutdown"],
  sd(log(pre_manuf$emp + 1), na.rm = TRUE),
  sde_manuf$sde, sde_manuf$se_sde, sde_manuf$bucket,
  sde_notes
)
writeLines(sde_tab, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
