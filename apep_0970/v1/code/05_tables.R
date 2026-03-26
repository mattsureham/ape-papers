# 05_tables.R — Generate all LaTeX tables
# apep_0970: UI Duration Cuts and Education Gradient

source("00_packages.R")

panel <- readRDS("../data/qwi_panel_clean.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
sumstats <- readRDS("../data/summary_stats.rds")

# Helper: format with significance stars
fmt_coef <- function(b, se, digits = 4) {
  pval <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(pval < 0.01, "^{***}", ifelse(pval < 0.05, "^{**}", ifelse(pval < 0.10, "^{*}", "")))
  sprintf("%.${digits}f%s", b, stars)
}

# ══════════════════════════════════════════════════════════════════════
# TABLE 1: SUMMARY STATISTICS
# ══════════════════════════════════════════════════════════════════════

pre_panel <- panel %>% filter(time_t <= 17)  # pre-treatment (before 2011Q2)

# Overall stats
overall <- pre_panel %>%
  summarise(
    earn_mean = mean(earn_s, na.rm = TRUE), earn_sd = sd(earn_s, na.rm = TRUE),
    hire_mean = mean(hire_rate, na.rm = TRUE), hire_sd = sd(hire_rate, na.rm = TRUE),
    sep_mean = mean(sep_rate, na.rm = TRUE), sep_sd = sd(sep_rate, na.rm = TRUE),
    emp_mean = mean(emp / 1e6, na.rm = TRUE), emp_sd = sd(emp / 1e6, na.rm = TRUE),
    n = n()
  )

# By treatment group
by_treat <- pre_panel %>%
  group_by(treated_state) %>%
  summarise(
    earn_mean = mean(earn_s, na.rm = TRUE), earn_sd = sd(earn_s, na.rm = TRUE),
    hire_mean = mean(hire_rate, na.rm = TRUE), hire_sd = sd(hire_rate, na.rm = TRUE),
    sep_mean = mean(sep_rate, na.rm = TRUE), sep_sd = sd(sep_rate, na.rm = TRUE),
    emp_mean = mean(emp / 1e6, na.rm = TRUE), emp_sd = sd(emp / 1e6, na.rm = TRUE),
    n = n()
  )

tab1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Pre-Treatment Means (2007--2011Q1)}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
& \\multicolumn{2}{c}{All States} & \\multicolumn{2}{c}{Cut States} & \\multicolumn{2}{c}{Non-Cut States} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}
Variable & Mean & SD & Mean & SD & Mean & SD \\\\
\\midrule
Monthly earnings (\\$) & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f \\\\
Hire rate & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\
Separation rate & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\
Employment (millions) & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\
\\midrule
State-education-quarters & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{7} & \\multicolumn{2}{c}{%d} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Pre-treatment means from the Quarterly Workforce Indicators (QWI) sex$\\times$education panel, aggregated to state$\\times$education$\\times$quarter. Monthly earnings are employment-weighted averages across county-industry cells. Hire rate is total hires divided by beginning-of-quarter employment. Cut states: FL, SC, MO, MI, GA, NC, AR. Sample restricted to quarters before any state's first UI duration cut (2007Q1--2011Q1).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  overall$earn_mean, overall$earn_sd,
  by_treat$earn_mean[2], by_treat$earn_sd[2],  # treated
  by_treat$earn_mean[1], by_treat$earn_sd[1],  # control
  overall$hire_mean, overall$hire_sd,
  by_treat$hire_mean[2], by_treat$hire_sd[2],
  by_treat$hire_mean[1], by_treat$hire_sd[1],
  overall$sep_mean, overall$sep_sd,
  by_treat$sep_mean[2], by_treat$sep_sd[2],
  by_treat$sep_mean[1], by_treat$sep_sd[1],
  overall$emp_mean, overall$emp_sd,
  by_treat$emp_mean[2], by_treat$emp_sd[2],
  by_treat$emp_mean[1], by_treat$emp_sd[1],
  overall$n, by_treat$n[2], by_treat$n[1],
  n_distinct(panel$statefips),
  n_distinct(panel$statefips[!panel$treated_state])
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Written: tables/tab1_summary.tex\n")

# ══════════════════════════════════════════════════════════════════════
# TABLE 2: MAIN RESULTS — TRIPLE DIFFERENCE
# ══════════════════════════════════════════════════════════════════════

twfe_e <- results$twfe_earn
twfe_h <- results$twfe_hire
twfe_s <- results$twfe_sep

# Extract coefficients
coefs_e <- coeftable(twfe_e)
coefs_h <- coeftable(twfe_h)
coefs_s <- coeftable(twfe_s)

star <- function(p) ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))

tab2 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Effect of UI Duration Cuts on Labor Market Outcomes: Triple-Difference Estimates}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& (1) & (2) & (3) \\\\
& Log Earnings & Hire Rate & Separation Rate \\\\
\\midrule
Cut $\\times$ Post & %.4f%s & %.4f%s & %.4f%s \\\\
& (%.4f) & (%.4f) & (%.4f) \\\\[0.3em]
Cut $\\times$ Post $\\times$ HS or less & %.4f%s & %.4f%s & %.4f%s \\\\
& (%.4f) & (%.4f) & (%.4f) \\\\[0.3em]
Cut $\\times$ Post $\\times$ BA+ & %.4f%s & %.4f%s & %.4f%s \\\\
& (%.4f) & (%.4f) & (%.4f) \\\\
\\midrule
State $\\times$ Education FE & Yes & Yes & Yes \\\\
Education $\\times$ Quarter FE & Yes & Yes & Yes \\\\
Observations & %s & %s & %s \\\\
States & %d & %d & %d \\\\
R$^2$ (within) & %.4f & %.4f & %.4f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Triple-difference estimates from TWFE regressions. The omitted education category is ``Some college.'' Standard errors clustered at the state level in parentheses. Cut states reduced maximum UI benefit duration from 26 weeks to 12--23 weeks between 2011 and 2014. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  # Cut x Post row
  coefs_e[1,1], star(coefs_e[1,4]), coefs_h[1,1], star(coefs_h[1,4]), coefs_s[1,1], star(coefs_s[1,4]),
  coefs_e[1,2], coefs_h[1,2], coefs_s[1,2],
  # Cut x Post x HS or less
  coefs_e[2,1], star(coefs_e[2,4]), coefs_h[2,1], star(coefs_h[2,4]), coefs_s[2,1], star(coefs_s[2,4]),
  coefs_e[2,2], coefs_h[2,2], coefs_s[2,2],
  # Cut x Post x BA+
  coefs_e[3,1], star(coefs_e[3,4]), coefs_h[3,1], star(coefs_h[3,4]), coefs_s[3,1], star(coefs_s[3,4]),
  coefs_e[3,2], coefs_h[3,2], coefs_s[3,2],
  # N, states, R2
  format(nobs(twfe_e), big.mark = ","), format(nobs(twfe_h), big.mark = ","), format(nobs(twfe_s), big.mark = ","),
  n_distinct(panel$statefips), n_distinct(panel$statefips), n_distinct(panel$statefips),
  fitstat(twfe_e, "wr2")$wr2, fitstat(twfe_h, "wr2")$wr2, fitstat(twfe_s, "wr2")$wr2
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("Written: tables/tab2_main.tex\n")

# ══════════════════════════════════════════════════════════════════════
# TABLE 3: CS-DiD BY EDUCATION GROUP
# ══════════════════════════════════════════════════════════════════════

res <- results$results_by_edu

tab3 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Callaway--Sant'Anna ATT Estimates by Education Group}
\\label{tab:cs_edu}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
& \\multicolumn{3}{c}{Log Earnings} & \\multicolumn{3}{c}{Hire Rate} \\\\
\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}
& HS or less & Some college & BA+ & HS or less & Some college & BA+ \\\\
\\midrule
ATT & %.4f & %.4f & %.4f & %.4f & %.4f & %.4f \\\\
& (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\
95\\%% CI & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\
\\midrule
Control group & \\multicolumn{6}{c}{Never treated} \\\\
Estimator & \\multicolumn{6}{c}{Callaway--Sant'Anna (2021)} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Group-time ATTs aggregated to simple overall ATT by education group using the Callaway--Sant'Anna (2021) estimator with never-treated states as the control group. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  # ATT row - earnings
  res$E1$att_earn$overall.att, res$E2$att_earn$overall.att, res$E3$att_earn$overall.att,
  # ATT row - hire rate
  res$E1$att_hire$overall.att, res$E2$att_hire$overall.att, res$E3$att_hire$overall.att,
  # SE row
  res$E1$att_earn$overall.se, res$E2$att_earn$overall.se, res$E3$att_earn$overall.se,
  res$E1$att_hire$overall.se, res$E2$att_hire$overall.se, res$E3$att_hire$overall.se,
  # CI - earnings
  res$E1$att_earn$overall.att - 1.96*res$E1$att_earn$overall.se,
  res$E1$att_earn$overall.att + 1.96*res$E1$att_earn$overall.se,
  res$E2$att_earn$overall.att - 1.96*res$E2$att_earn$overall.se,
  res$E2$att_earn$overall.att + 1.96*res$E2$att_earn$overall.se,
  res$E3$att_earn$overall.att - 1.96*res$E3$att_earn$overall.se,
  res$E3$att_earn$overall.att + 1.96*res$E3$att_earn$overall.se,
  # CI - hire rate
  res$E1$att_hire$overall.att - 1.96*res$E1$att_hire$overall.se,
  res$E1$att_hire$overall.att + 1.96*res$E1$att_hire$overall.se,
  res$E2$att_hire$overall.att - 1.96*res$E2$att_hire$overall.se,
  res$E2$att_hire$overall.att + 1.96*res$E2$att_hire$overall.se,
  res$E3$att_hire$overall.att - 1.96*res$E3$att_hire$overall.se,
  res$E3$att_hire$overall.att + 1.96*res$E3$att_hire$overall.se
)

writeLines(tab3, "../tables/tab3_cs_edu.tex")
cat("Written: tables/tab3_cs_edu.tex\n")

# ══════════════════════════════════════════════════════════════════════
# TABLE 4: ROBUSTNESS — LEAVE-ONE-OUT
# ══════════════════════════════════════════════════════════════════════

loo <- robust$loo_results
loo_df <- tibble(
  State = names(loo),
  ATT = sapply(loo, `[[`, "att"),
  SE = sapply(loo, `[[`, "se")
) %>%
  mutate(
    pval = 2 * pnorm(-abs(ATT / SE)),
    stars = ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
  )

loo_rows <- paste(sprintf("Drop %s & %.4f%s & (%.4f) \\\\",
                          loo_df$State, loo_df$ATT, loo_df$stars, loo_df$SE),
                  collapse = "\n")

# Also include not-yet-treated and baseline
tab4 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Robustness: Leave-One-Out and Alternative Control Groups}
\\label{tab:robust}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Specification & ATT (Hire Rate) & SE \\\\
\\midrule
\\textit{Baseline (never-treated control)} & %.4f & (%.4f) \\\\[0.3em]
\\textit{Not-yet-treated control} & %.4f & (%.4f) \\\\[0.5em]
\\textit{Leave-one-out:} & & \\\\
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports the Callaway--Sant'Anna overall ATT on the hire rate. The baseline uses never-treated states as the control group. ``Not-yet-treated'' uses states that have not yet adopted cuts at a given period as controls. Leave-one-out estimates drop each cut state individually. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  results$att_hire$overall.att, results$att_hire$overall.se,
  robust$att_nyt$overall.att, robust$att_nyt$overall.se,
  loo_rows
)

writeLines(tab4, "../tables/tab4_robust.tex")
cat("Written: tables/tab4_robust.tex\n")

# ══════════════════════════════════════════════════════════════════════
# TABLE F1: STANDARDIZED EFFECT SIZES (SDE)
# ══════════════════════════════════════════════════════════════════════

# Pre-treatment standard deviations
pre_sd <- pre_panel %>%
  summarise(
    sd_hire_rate = sd(hire_rate, na.rm = TRUE),
    sd_ln_earn = sd(ln_earn_s, na.rm = TRUE)
  )

pre_sd_edu <- pre_panel %>%
  group_by(edu_label) %>%
  summarise(
    sd_hire_rate = sd(hire_rate, na.rm = TRUE),
    sd_ln_earn = sd(ln_earn_s, na.rm = TRUE),
    .groups = "drop"
  )

# SDE classification
classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Panel A: Pooled
# Overall hire rate ATT
sde_hire_pooled <- results$att_hire$overall.att / pre_sd$sd_hire_rate
se_sde_hire_pooled <- results$att_hire$overall.se / pre_sd$sd_hire_rate

# Overall earnings ATT
sde_earn_pooled <- results$att_earn$overall.att / pre_sd$sd_ln_earn
se_sde_earn_pooled <- results$att_earn$overall.se / pre_sd$sd_ln_earn

# Panel B: Heterogeneous (HS or less vs BA+)
sd_hire_e1 <- pre_sd_edu$sd_hire_rate[pre_sd_edu$edu_label == "HS or less"]
sd_hire_e3 <- pre_sd_edu$sd_hire_rate[pre_sd_edu$edu_label == "BA+"]

sde_hire_e1 <- res$E1$att_hire$overall.att / sd_hire_e1
se_sde_hire_e1 <- res$E1$att_hire$overall.se / sd_hire_e1
sde_hire_e3 <- res$E3$att_hire$overall.att / sd_hire_e3
se_sde_hire_e3 <- res$E3$att_hire$overall.se / sd_hire_e3

# Build SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether state-level reductions in maximum unemployment insurance benefit duration affect re-employment rates differently for less-educated versus more-educated workers. ",
  "\\textbf{Policy mechanism:} Seven states shortened the maximum number of weeks an unemployed worker could receive UI benefits from the federal standard of 26 weeks down to 12--23 weeks, reducing the subsidized job-search window and increasing the opportunity cost of continued unemployment. ",
  "\\textbf{Outcome definition:} Quarterly hire rate from the Census QWI, defined as total hires divided by beginning-of-quarter employment, aggregated across industries at the state-education-quarter level. ",
  "\\textbf{Treatment:} Binary (state adopted a UI duration cut), with continuous dose variation from 3 to 10 weeks cut. ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI) sex$\\times$education panel, 2007--2020, state-education-quarter level, covering all 50 states plus DC. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered difference-in-differences with never-treated states as control group, state-clustered standard errors. ",
  "\\textbf{Sample:} All private-sector employment aggregated to state$\\times$education$\\times$quarter; three education groups (HS or less, some college, BA+); 53 states including DC and territories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llcccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\
Hire rate & CS-DiD (all) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\
Log earnings & CS-DiD (all) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\
Hire rate & CS-DiD (HS or less) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\
Hire rate & CS-DiD (BA+) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  # Panel A: Pooled hire rate
  results$att_hire$overall.att, results$att_hire$overall.se, pre_sd$sd_hire_rate,
  sde_hire_pooled, se_sde_hire_pooled, classify_sde(sde_hire_pooled),
  # Panel A: Pooled earnings
  results$att_earn$overall.att, results$att_earn$overall.se, pre_sd$sd_ln_earn,
  sde_earn_pooled, se_sde_earn_pooled, classify_sde(sde_earn_pooled),
  # Panel B: HS or less
  res$E1$att_hire$overall.att, res$E1$att_hire$overall.se, sd_hire_e1,
  sde_hire_e1, se_sde_hire_e1, classify_sde(sde_hire_e1),
  # Panel B: BA+
  res$E3$att_hire$overall.att, res$E3$att_hire$overall.se, sd_hire_e3,
  sde_hire_e3, se_sde_hire_e3, classify_sde(sde_hire_e3),
  # Notes
  sde_notes
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Written: tables/tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
