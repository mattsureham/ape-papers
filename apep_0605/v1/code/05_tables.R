# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# apep_0605: Asymmetric Resource Curse in US Shale Counties
# =============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, fips := sprintf("%05s", as.character(fips))]
load("../data/main_results.RData")

es_combined <- fread("../data/event_study_results.csv")

# =============================================================================
# TABLE 1: SUMMARY STATISTICS
# =============================================================================

cat("Generating Table 1: Summary Statistics...\n")

# Split by shale/non-shale
summ_shale <- panel[shale == 1, .(
  `Total Employment` = mean(total_emp, na.rm = TRUE),
  `Mining Employment` = mean(mining_emp, na.rm = TRUE),
  `Non-Mining Employment` = mean(nonmining_emp, na.rm = TRUE),
  `Mining Share (\\%)` = mean(mining_share * 100, na.rm = TRUE),
  `Avg Monthly Earnings (\\$)` = mean(total_earnings, na.rm = TRUE),
  N = .N
)]

summ_nonshale <- panel[shale == 0, .(
  `Total Employment` = mean(total_emp, na.rm = TRUE),
  `Mining Employment` = mean(mining_emp, na.rm = TRUE),
  `Non-Mining Employment` = mean(nonmining_emp, na.rm = TRUE),
  `Mining Share (\\%)` = mean(mining_share * 100, na.rm = TRUE),
  `Avg Monthly Earnings (\\$)` = mean(total_earnings, na.rm = TRUE),
  N = .N
)]

sd_shale <- panel[shale == 1, .(
  `Total Employment` = sd(total_emp, na.rm = TRUE),
  `Mining Employment` = sd(mining_emp, na.rm = TRUE),
  `Non-Mining Employment` = sd(nonmining_emp, na.rm = TRUE),
  `Mining Share (\\%)` = sd(mining_share * 100, na.rm = TRUE),
  `Avg Monthly Earnings (\\$)` = sd(total_earnings, na.rm = TRUE)
)]

sd_nonshale <- panel[shale == 0, .(
  `Total Employment` = sd(total_emp, na.rm = TRUE),
  `Mining Employment` = sd(mining_emp, na.rm = TRUE),
  `Non-Mining Employment` = sd(nonmining_emp, na.rm = TRUE),
  `Mining Share (\\%)` = sd(mining_share * 100, na.rm = TRUE),
  `Avg Monthly Earnings (\\$)` = sd(total_earnings, na.rm = TRUE)
)]

# Build table manually for precise formatting
vars <- c("Total Employment", "Mining Employment", "Non-Mining Employment",
          "Mining Share (\\%)", "Avg Monthly Earnings (\\$)")

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Shale vs.\\ Non-Shale Counties}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Shale Counties} & \\multicolumn{2}{c}{Non-Shale Counties} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (v in vars) {
  ms <- as.numeric(summ_shale[[v]])
  ss <- as.numeric(sd_shale[[v]])
  mn <- as.numeric(summ_nonshale[[v]])
  sn <- as.numeric(sd_nonshale[[v]])

  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
            v,
            formatC(ms, format = "f", digits = 1, big.mark = ","),
            formatC(ss, format = "f", digits = 1, big.mark = ","),
            formatC(mn, format = "f", digits = 1, big.mark = ","),
            formatC(sn, format = "f", digits = 1, big.mark = ",")))
}

n_shale <- uniqueN(panel[shale == 1]$fips)
n_nonshale <- uniqueN(panel[shale == 0]$fips)

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Counties & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          formatC(n_shale, big.mark = ","), formatC(n_nonshale, big.mark = ",")),
  sprintf("County-years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          formatC(nrow(panel[shale == 1]), big.mark = ","),
          formatC(nrow(panel[shale == 0]), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Data from Census QWI (LEHD), 2001--2023. ",
         "Shale counties are those overlying one of seven major US shale plays ",
         "(Barnett, Bakken, Marcellus/Utica, Haynesville, Eagle Ford, Permian, Niobrara). ",
         "Employment is average quarterly employment. Earnings are average monthly earnings. ",
         "Mining is NAICS sector 21 (Mining, Quarrying, and Oil and Gas Extraction)."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Table 1 saved.\n")

# =============================================================================
# TABLE 2: MAIN RESULTS (CS-DiD ATTs)
# =============================================================================

cat("Generating Table 2: Main Results...\n")

# Overall ATTs from CS-DiD
results_df <- data.table(
  outcome = c("Log Total Emp", "Log Mining Emp", "Log Non-Mining Emp", "Log Earnings"),
  att = c(agg_total$overall.att, agg_mining$overall.att,
          agg_nonmining$overall.att, agg_earnings$overall.att),
  se = c(agg_total$overall.se, agg_mining$overall.se,
         agg_nonmining$overall.se, agg_earnings$overall.se)
)
results_df[, stars := ifelse(abs(att/se) > 2.576, "***",
                    ifelse(abs(att/se) > 1.96, "**",
                    ifelse(abs(att/se) > 1.645, "*", "")))]

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Main Results: Effect of Shale Exposure on County Employment}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Total Emp & Mining Emp & Non-Mining Emp & Earnings \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway--Sant'Anna ATT}} \\\\[3pt]"
)

att_row <- sprintf("ATT & %s%s & %s%s & %s%s & %s%s \\\\",
  formatC(results_df$att[1], format = "f", digits = 4), results_df$stars[1],
  formatC(results_df$att[2], format = "f", digits = 4), results_df$stars[2],
  formatC(results_df$att[3], format = "f", digits = 4), results_df$stars[3],
  formatC(results_df$att[4], format = "f", digits = 4), results_df$stars[4])

se_row <- sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
  formatC(results_df$se[1], format = "f", digits = 4),
  formatC(results_df$se[2], format = "f", digits = 4),
  formatC(results_df$se[3], format = "f", digits = 4),
  formatC(results_df$se[4], format = "f", digits = 4))

tab2_lines <- c(tab2_lines, att_row, se_row)

# Panel B: Boom vs Bust split
boom_coef <- coef(split_reg)["post_boom"]
bust_coef <- coef(split_reg)["post_bust"]
boom_se <- se(split_reg)["post_boom"]
bust_se <- se(split_reg)["post_bust"]

boom_stars <- ifelse(abs(boom_coef/boom_se) > 2.576, "***",
              ifelse(abs(boom_coef/boom_se) > 1.96, "**",
              ifelse(abs(boom_coef/boom_se) > 1.645, "*", "")))
bust_stars <- ifelse(abs(bust_coef/bust_se) > 2.576, "***",
              ifelse(abs(bust_coef/bust_se) > 1.96, "**",
              ifelse(abs(bust_coef/bust_se) > 1.645, "*", "")))

tab2_lines <- c(tab2_lines,
  "\\\\",
  "\\multicolumn{5}{l}{\\textit{Panel B: Boom vs.\\ Bust (TWFE, Total Employment)}} \\\\[3pt]",
  sprintf("Post $\\times$ Boom & %s%s & & & \\\\",
          formatC(boom_coef, format = "f", digits = 4), boom_stars),
  sprintf(" & (%s) & & & \\\\",
          formatC(boom_se, format = "f", digits = 4)),
  sprintf("Post $\\times$ Bust & %s%s & & & \\\\",
          formatC(bust_coef, format = "f", digits = 4), bust_stars),
  sprintf(" & (%s) & & & \\\\",
          formatC(bust_se, format = "f", digits = 4)),
  sprintf("Wald: Boom $=$ Bust & \\multicolumn{4}{c}{$F = %s$, $p = %s$} \\\\",
          formatC(wald_stat, format = "f", digits = 2),
          formatC(wald_p, format = "f", digits = 3))
)

tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("County FE & \\multicolumn{4}{c}{Yes} \\\\"),
  sprintf("Year FE & \\multicolumn{4}{c}{Yes} \\\\"),
  sprintf("Control group & \\multicolumn{4}{c}{Never-treated} \\\\"),
  sprintf("Clustering & \\multicolumn{4}{c}{State} \\\\"),
  sprintf("Counties & \\multicolumn{4}{c}{%s} \\\\",
          formatC(uniqueN(panel$fips), big.mark = ",")),
  sprintf("Treated counties & \\multicolumn{4}{c}{%s} \\\\",
          formatC(uniqueN(panel[shale == 1]$fips), big.mark = ",")),
  sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\",
          formatC(nrow(panel), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Panel A reports Callaway and Sant'Anna (2021) overall ATT ",
         "estimates using never-treated counties as the control group. ",
         "Panel B reports TWFE estimates interacting post-treatment with boom (2001--2014) ",
         "and bust (2015--2023) indicators. Outcomes are in logs. ",
         "Standard errors clustered at the state level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Table 2 saved.\n")

# =============================================================================
# TABLE 3: EVENT STUDY COEFFICIENTS
# =============================================================================

cat("Generating Table 3: Event Study...\n")

es_total_dt <- es_combined[outcome == "total_emp"]
es_total_dt[, ci_lo := att - 1.96 * se]
es_total_dt[, ci_hi := att + 1.96 * se]
es_total_dt[, stars := ifelse(abs(att/se) > 2.576, "***",
                       ifelse(abs(att/se) > 1.96, "**",
                       ifelse(abs(att/se) > 1.645, "*", "")))]

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Dynamic Treatment Effects: Log Total Employment}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccl}",
  "\\toprule",
  "Event Time & ATT & SE & 95\\% CI & \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_total_dt)) {
  row <- es_total_dt[i]
  tab3_lines <- c(tab3_lines,
    sprintf("$k = %+d$ & %s%s & (%s) & [%s, %s] & \\\\",
            row$event_time,
            formatC(row$att, format = "f", digits = 4), row$stars,
            formatC(row$se, format = "f", digits = 4),
            formatC(row$ci_lo, format = "f", digits = 4),
            formatC(row$ci_hi, format = "f", digits = 4)))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic ATT estimates. ",
         "Event time $k$ is years relative to first significant shale production. ",
         "Standard errors clustered at the state level. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:eventstudy}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")
cat("  Table 3 saved.\n")

# =============================================================================
# TABLE 4: ROBUSTNESS (Leave-one-out + alternative controls)
# =============================================================================

cat("Generating Table 4: Robustness...\n")

load("../data/robustness_results.RData")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Leave-One-Out and Alternative Specifications}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & ATT & SE & Treated Counties \\\\",
  "\\midrule",
  sprintf("Baseline & %s & (%s) & %s \\\\",
          formatC(agg_total$overall.att, format = "f", digits = 4),
          formatC(agg_total$overall.se, format = "f", digits = 4),
          uniqueN(panel[shale == 1]$fips)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Leave-one-out by play:}} \\\\"
)

if (nrow(loo_results) > 0) {
  for (i in 1:nrow(loo_results)) {
    row <- loo_results[i]
    tab4_lines <- c(tab4_lines,
      sprintf("\\quad Excl.\\ %s & %s & (%s) & %d \\\\",
              row$excluded_play,
              formatC(row$att, format = "f", digits = 4),
              formatC(row$se, format = "f", digits = 4),
              row$n_treated))
  }
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Each row re-estimates the CS-DiD model excluding one shale play. ",
         "Baseline uses all seven plays. Control group: never-treated counties. ",
         "Standard errors clustered at the state level."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:robust}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("  Table 4 saved.\n")

# =============================================================================
# TABLE F1: STANDARDIZED EFFECT SIZES (SDE) — MANDATORY
# =============================================================================

cat("Generating SDE Table...\n")

# Extract beta, SE from CS-DiD results
outcomes <- c("Total Employment", "Mining Employment", "Non-Mining Employment", "Avg Earnings")
betas <- c(agg_total$overall.att, agg_mining$overall.att,
           agg_nonmining$overall.att, agg_earnings$overall.att)
ses <- c(agg_total$overall.se, agg_mining$overall.se,
         agg_nonmining$overall.se, agg_earnings$overall.se)

# SD(Y) — unconditional standard deviation of each log outcome
sd_y <- c(
  sd(panel$log_total_emp, na.rm = TRUE),
  sd(panel$log_mining_emp, na.rm = TRUE),
  sd(panel$log_nonmining_emp, na.rm = TRUE),
  sd(panel$log_earnings, na.rm = TRUE)
)

# SDE = beta / SD(Y) for binary treatment
sde <- betas / sd_y
se_sde <- ses / sd_y

# Classification
classify_sde <- function(s) {
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

classifications <- classify_sde(sde)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_along(outcomes)) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            outcomes[i],
            formatC(betas[i], format = "f", digits = 4),
            formatC(ses[i], format = "f", digits = 4),
            formatC(sd_y[i], format = "f", digits = 3),
            formatC(sde[i], format = "f", digits = 4),
            formatC(se_sde[i], format = "f", digits = 4),
            classifications[i]))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  paste0("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
         "to facilitate cross-study comparison. ",
         "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. ",
         "SD($Y$) is the unconditional standard deviation of the log outcome."),
  "",
  paste0("\\textbf{Research question:} Effect of shale play exposure (hydraulic fracturing boom) ",
         "on county-level employment and earnings."),
  paste0("\\textbf{Treatment:} Binary indicator for county overlying a major US shale play."),
  paste0("\\textbf{Data:} Census QWI (LEHD), 2001--2023, county-year panel."),
  paste0("\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator, ",
         "state-clustered standard errors."),
  sprintf("\\textbf{Sample:} %s counties, %s county-years.",
          formatC(uniqueN(panel$fips), big.mark = ","),
          formatC(nrow(panel), big.mark = ",")),
  "",
  paste0("Classification thresholds: large negative ($< -0.15$), ",
         "moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), ",
         "null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), ",
         "moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$). ",
         "Classification labels refer to the magnitude of the standardized point estimate, ",
         "not to statistical significance. ``Null'' denotes a near-zero effect size ",
         "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}"),
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("  SDE table saved.\n")

cat("\nAll tables generated successfully.\n")
