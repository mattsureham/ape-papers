## 05_tables.R — Generate all LaTeX tables
## apep_1350: The Segregation Dividend

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
bw <- arrow::read_parquet("../data/analysis_panel_624.parquet") |> as_tibble()

# ── Table 1: Summary Statistics ──
cat("Generating Table 1: Summary Statistics\n")

# Pre-period stats (before any expansion)
pre <- bw |> filter(yq < 2014)
post <- bw |> filter(yq >= 2014)

summ <- tribble(
  ~Variable, ~Mean, ~SD, ~Min, ~Max, ~N,
  "B/W Earnings Ratio", mean(bw$bw_earn_ratio, na.rm=T), sd(bw$bw_earn_ratio, na.rm=T),
    min(bw$bw_earn_ratio, na.rm=T), max(bw$bw_earn_ratio, na.rm=T), sum(!is.na(bw$bw_earn_ratio)),
  "Black Employment Share", mean(bw$black_emp_share, na.rm=T), sd(bw$black_emp_share, na.rm=T),
    min(bw$black_emp_share, na.rm=T), max(bw$black_emp_share, na.rm=T), sum(!is.na(bw$black_emp_share)),
  "Avg. Quarterly Earnings, Black (\\$)", mean(bw$EarnS_A2, na.rm=T), sd(bw$EarnS_A2, na.rm=T),
    min(bw$EarnS_A2, na.rm=T), max(bw$EarnS_A2, na.rm=T), sum(!is.na(bw$EarnS_A2)),
  "Avg. Quarterly Earnings, White (\\$)", mean(bw$EarnS_A1, na.rm=T), sd(bw$EarnS_A1, na.rm=T),
    min(bw$EarnS_A1, na.rm=T), max(bw$EarnS_A1, na.rm=T), sum(!is.na(bw$EarnS_A1)),
  "Black Employment (624)", mean(bw$Emp_A2, na.rm=T), sd(bw$Emp_A2, na.rm=T),
    min(bw$Emp_A2, na.rm=T), max(bw$Emp_A2, na.rm=T), sum(!is.na(bw$Emp_A2)),
  "White Employment (624)", mean(bw$Emp_A1, na.rm=T), sd(bw$Emp_A1, na.rm=T),
    min(bw$Emp_A1, na.rm=T), max(bw$Emp_A1, na.rm=T), sum(!is.na(bw$Emp_A1))
)

# Format numbers
tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: NAICS 624 (Social Assistance), State-Quarter Panel}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\hline\\hline\n",
  "Variable & Mean & SD & Min & Max & N \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(summ)) {
  tab1_tex <- paste0(tab1_tex, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    summ$Variable[i],
    summ$Mean[i], summ$SD[i], summ$Min[i], summ$Max[i],
    format(summ$N[i], big.mark = ",")
  ))
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\n",
  "\\multicolumn{6}{l}{\\footnotesize \\textit{Notes:} Unit of observation is state $\\times$ quarter. }\\\\\n",
  "\\multicolumn{6}{l}{\\footnotesize QWI race/ethnicity $\\times$ 3-digit NAICS, all states, 2001Q1--2024Q4.}\\\\\n",
  "\\multicolumn{6}{l}{\\footnotesize Race categories: White alone (A1), Black alone (A2), both sexes combined.}\\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_sumstats.tex")

# ── Table 2: Main DiD Results ──
cat("Generating Table 2: Main DiD Results\n")

cs_ratio_agg <- results$cs_ratio_agg
cs_share_agg <- results$cs_share_agg
cs_lnearn_agg <- results$cs_lnearn_agg
twfe_ddd <- results$twfe_ddd

# Format helper
fmt_coef <- function(est, se, stars = TRUE) {
  if (is.na(est) || is.na(se) || se == 0) return("---")
  pval <- 2 * pnorm(-abs(est / se))
  star <- ""
  if (stars && !is.na(pval)) {
    if (pval < 0.01) star <- "***"
    else if (pval < 0.05) star <- "**"
    else if (pval < 0.10) star <- "*"
  }
  sprintf("%.4f%s", est, star)
}

fmt_se <- function(se) sprintf("(%.4f)", se)

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Medicaid Expansion on Racial Earnings Gap in Social Assistance}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Callaway--Sant'Anna} & Triple-Diff \\\\\n",
  " \\cmidrule(lr){2-4} \\cmidrule(lr){5-5}\n",
  " & B/W Ratio & Black Share & ln(Earn$_B$) & ln(Earn) \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n"
)

# Race-decomposed CS results
cs_black_earn_agg <- results$cs_black_earn_agg
cs_white_earn_agg <- results$cs_white_earn_agg
cs_black_emp_agg <- results$cs_black_emp_agg
cs_white_emp_agg <- results$cs_white_emp_agg

n_cs <- format(nrow(results$bw_cs), big.mark = ",")
n_states <- n_distinct(results$bw_cs$state_fips)

tab2_tex <- paste0(tab2_tex,
  "\\multicolumn{5}{l}{\\textit{Panel A: B/W Ratio and Composition}} \\\\\n",
  sprintf("ATT & %s & %s & & \\\\\n",
    fmt_coef(cs_ratio_agg$overall.att, cs_ratio_agg$overall.se),
    fmt_coef(cs_share_agg$overall.att, cs_share_agg$overall.se)),
  sprintf(" & %s & %s & & \\\\\n",
    fmt_se(cs_ratio_agg$overall.se),
    fmt_se(cs_share_agg$overall.se)),
  "[6pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Race-Specific Earnings and Employment}} \\\\\n",
  sprintf(" & ln(Earn$_B$) & ln(Earn$_W$) & ln(Emp$_B$) & ln(Emp$_W$) \\\\\n"),
  sprintf("ATT & %s & %s & %s & %s \\\\\n",
    fmt_coef(cs_black_earn_agg$overall.att, cs_black_earn_agg$overall.se),
    fmt_coef(cs_white_earn_agg$overall.att, cs_white_earn_agg$overall.se),
    fmt_coef(cs_black_emp_agg$overall.att, cs_black_emp_agg$overall.se),
    fmt_coef(cs_white_emp_agg$overall.att, cs_white_emp_agg$overall.se)),
  sprintf(" & %s & %s & %s & %s \\\\\n",
    fmt_se(cs_black_earn_agg$overall.se),
    fmt_se(cs_white_earn_agg$overall.se),
    fmt_se(cs_black_emp_agg$overall.se),
    fmt_se(cs_white_emp_agg$overall.se)),
  "\\hline\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n", n_cs, n_cs, n_cs, n_cs),
  sprintf("States & %d & %d & %d & %d \\\\\n", n_states, n_states, n_states, n_states),
  "Estimator & \\multicolumn{4}{c}{Callaway--Sant'Anna (2021)} \\\\\n",
  "Comparison & \\multicolumn{4}{c}{Never-treated states} \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\footnotesize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$. SEs clustered at state level.}\\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize \\textit{Notes:} All columns use Callaway--Sant'Anna (2021) with never-treated states}\\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize as comparison and universal base period. Panel A outcomes: Black-to-White}\\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize quarterly earnings ratio and Black employment share. Panel B: log outcomes by race.}\\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ── Table 3: Event Study (CS dynamic ATT) ──
cat("Generating Table 3: Event Study\n")

es <- results$cs_ratio_es
es_df <- data.frame(
  event_time = es$egt,
  att = es$att.egt,
  se = es$se.egt
) |>
  filter(abs(event_time) <= 12) |>
  mutate(
    ci_lower = att - 1.96 * se,
    ci_upper = att + 1.96 * se,
    pval = 2 * pnorm(-abs(att / se)),
    star = case_when(pval < 0.01 ~ "***", pval < 0.05 ~ "**", pval < 0.10 ~ "*", TRUE ~ "")
  )

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Event Study: B/W Earnings Ratio in Social Assistance Around Medicaid Expansion}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{rrrcc}\n",
  "\\hline\\hline\n",
  "Quarters & ATT & SE & 95\\% CI & \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(es_df)) {
  tab3_tex <- paste0(tab3_tex, sprintf(
    "%+d & %s & %.4f & [%.4f, %.4f] & \\\\\n",
    es_df$event_time[i],
    paste0(sprintf("%.4f", es_df$att[i]), es_df$star[i]),
    es_df$se[i],
    es_df$ci_lower[i], es_df$ci_upper[i]
  ))
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\n",
  "\\multicolumn{5}{l}{\\footnotesize \\textit{Notes:} Callaway--Sant'Anna dynamic ATT estimates. Event time}\\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize in quarters relative to Medicaid expansion. Never-treated states as comparison.}\\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_eventstudy.tex")

# ── Table 4: Placebo Tests ──
cat("Generating Table 4: Placebo Tests\n")

cs_62 <- robust$cs_62_agg
cs_72 <- robust$cs_72_agg
placebo_twfe <- robust$twfe_placebo

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Placebo Tests: Alternative Industries and Pre-Period Falsification}\n",
  "\\label{tab:placebo}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & NAICS 62 & NAICS 72 & Pre-2014 \\\\\n",
  " & Health Care & Accommodation & Falsification \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  sprintf("ATT / Treatment & %s & %s & %s \\\\\n",
    fmt_coef(cs_62$overall.att, cs_62$overall.se),
    fmt_coef(cs_72$overall.att, cs_72$overall.se),
    fmt_coef(coef(placebo_twfe)["fake_treatTRUE"], se(placebo_twfe)["fake_treatTRUE"])),
  sprintf(" & %s & %s & %s \\\\\n",
    fmt_se(cs_62$overall.se),
    fmt_se(cs_72$overall.se),
    fmt_se(se(placebo_twfe)["fake_treatTRUE"])),
  "\\hline\n",
  "Estimator & CS & CS & TWFE \\\\\n",
  "Sample & Full & Full & Pre-2014 \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\footnotesize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$.}\\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize \\textit{Notes:} Outcome is B/W earnings ratio. NAICS 62 = Health Care}\\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize (excl.\\ Social Assistance); NAICS 72 = Accommodation/Food Services.}\\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize Column (3) assigns false treatment at 2010Q1 using pre-expansion data only.}\\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_placebo.tex")

# ── Table F1: Standardized Effect Sizes (SDE) ──
cat("Generating Table F1: Standardized Effect Sizes\n")

# Pre-treatment SD of outcomes
pre_data <- bw |> filter(yq < 2014)
sd_ratio <- sd(pre_data$bw_earn_ratio, na.rm = TRUE)
sd_share <- sd(pre_data$black_emp_share, na.rm = TRUE)
sd_lnearn <- sd(pre_data$ln_earn_black, na.rm = TRUE)

# Panel A: Pooled
sde_ratio <- cs_ratio_agg$overall.att / sd_ratio
sde_share <- cs_share_agg$overall.att / sd_share
sde_lnearn <- cs_lnearn_agg$overall.att / sd_lnearn

se_sde_ratio <- cs_ratio_agg$overall.se / sd_ratio
se_sde_share <- cs_share_agg$overall.se / sd_share
se_sde_lnearn <- cs_lnearn_agg$overall.se / sd_lnearn

classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# Panel B: Heterogeneous (expansion-wave splits)
# Early expanders (2014) vs late expanders (2015+)
bw_early <- bw |> filter(!is.na(expansion_yq), expansion_yq <= 2014)
bw_late <- bw |> filter(!is.na(expansion_yq), expansion_yq > 2014)

# Simple pre/post means for early vs late
early_pre <- mean(bw_early$bw_earn_ratio[bw_early$yq < 2014], na.rm=TRUE)
early_post <- mean(bw_early$bw_earn_ratio[bw_early$yq >= 2014], na.rm=TRUE)
late_pre <- mean(bw_late$bw_earn_ratio[bw_late$yq < bw_late$expansion_yq], na.rm=TRUE)
late_post <- mean(bw_late$bw_earn_ratio[bw_late$yq >= bw_late$expansion_yq], na.rm=TRUE)

early_diff <- early_post - early_pre
late_diff <- late_post - late_pre
sde_early <- early_diff / sd_ratio
sde_late <- late_diff / sd_ratio

# SDE Notes (for Oracle training data)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does Medicaid expansion under the ACA widen the Black-White ",
  "earnings gap in social assistance (NAICS 624) by expanding a low-wage, racially segregated sector? ",
  "\\textbf{Policy mechanism:} Medicaid expansion extends health insurance coverage to adults below ",
  "138\\% of the federal poverty line, increasing demand for home- and community-based services; these ",
  "new positions disproportionately employ Black workers at entry-level wages. ",
  "\\textbf{Outcome definition:} Black-to-White average quarterly earnings ratio in NAICS 624 ",
  "(Social Assistance) from the Quarterly Workforce Indicators. ",
  "\\textbf{Treatment:} Binary indicator for state Medicaid expansion under the ACA. ",
  "\\textbf{Data:} Census QWI race/ethnicity $\\times$ 3-digit NAICS, state-quarter panel, 2001Q1--2024Q4, ",
  "51 states/DC. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) with never-treated comparison group, universal base ",
  "period, SEs clustered at state level. ",
  "\\textbf{Sample:} All states with non-suppressed QWI data for White and Black workers in NAICS 624. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("B/W Earnings Ratio & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    cs_ratio_agg$overall.att, cs_ratio_agg$overall.se, sd_ratio,
    sde_ratio, se_sde_ratio, classify_sde(sde_ratio)),
  sprintf("Black Emp.\\ Share & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    cs_share_agg$overall.att, cs_share_agg$overall.se, sd_share,
    sde_share, se_sde_share, classify_sde(sde_share)),
  sprintf("ln(Black Earnings) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    cs_lnearn_agg$overall.att, cs_lnearn_agg$overall.se, sd_lnearn,
    sde_lnearn, se_sde_lnearn, classify_sde(sde_lnearn)),
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by expansion wave)}} \\\\\n",
  sprintf("B/W Ratio, Early (2014) & %.4f & --- & %.4f & %.4f & --- & %s \\\\\n",
    early_diff, sd_ratio, sde_early, classify_sde(sde_early)),
  sprintf("B/W Ratio, Late (2015+) & %.4f & --- & %.4f & %.4f & --- & %s \\\\\n",
    late_diff, sd_ratio, sde_late, classify_sde(sde_late)),
  "\\hline\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\begin{itemize}[leftmargin=*,nosep]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "\\end{minipage}\n",
  "\\\\\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables written to tables/\n")
cat("05_tables.R complete.\n")
