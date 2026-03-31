# ==============================================================================
# 05_tables.R — Generate all LaTeX tables for CRNA opt-out paper
# ==============================================================================

source("00_packages.R")

results    <- readRDS("../data/all_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
panel_full <- readRDS("../data/analysis_panel.rds")
panel_main <- readRDS("../data/panel_main.rds")

main <- panel_main %>%
  filter(year >= 1998 & year <= 2023)

# Helper: format coefficient with stars
fmt_coef <- function(est, se, digits = 3) {
  p <- 2 * pnorm(-abs(est / se))
  stars <- ifelse(p < 0.01, "^{***}",
           ifelse(p < 0.05, "^{**}",
           ifelse(p < 0.10, "^{*}", "")))
  fmt <- paste0("%.", digits, "f%s")
  sprintf(fmt, est, stars)
}

fmt_se <- function(se, digits = 3) {
  fmt <- paste0("(%.", digits, "f)")
  sprintf(fmt, se)
}

# ==========================================================================
# TABLE 1: Summary Statistics
# ==========================================================================

cat("Generating Table 1: Summary Statistics\n")

# Summary stats by treatment group, BA+ ambulatory
summ_treated <- main %>%
  filter(g_period > 0) %>%
  summarise(
    n_states  = n_distinct(state_abbr),
    mean_emp  = mean(emp, na.rm = TRUE),
    sd_emp    = sd(emp, na.rm = TRUE),
    mean_earn = mean(earn, na.rm = TRUE),
    sd_earn   = sd(earn, na.rm = TRUE),
    mean_hires = mean(hires, na.rm = TRUE),
    n_obs     = n()
  )

summ_control <- main %>%
  filter(g_period == 0) %>%
  summarise(
    n_states  = n_distinct(state_abbr),
    mean_emp  = mean(emp, na.rm = TRUE),
    sd_emp    = sd(emp, na.rm = TRUE),
    mean_earn = mean(earn, na.rm = TRUE),
    sd_earn   = sd(earn, na.rm = TRUE),
    mean_hires = mean(hires, na.rm = TRUE),
    n_obs     = n()
  )

tab1 <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: BA+ Workers in Ambulatory Health Care (NAICS 621)}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & Opt-Out States & Never Opt-Out \\\\
\\midrule
Number of states & %d & %d \\\\
\\addlinespace
\\textit{Panel A: Employment} & & \\\\
\\quad Mean quarterly employment & %s & %s \\\\
\\quad SD & (%s) & (%s) \\\\
\\addlinespace
\\textit{Panel B: Earnings} & & \\\\
\\quad Mean quarterly earnings (\\$) & %s & %s \\\\
\\quad SD & (%s) & (%s) \\\\
\\addlinespace
\\textit{Panel C: Hiring} & & \\\\
\\quad Mean annual hires & %s & %s \\\\
\\addlinespace
State-year observations & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Data from the Census Bureau Quarterly Workforce Indicators (QWI), 2000--2023. Sample restricted to workers with bachelor's degree or higher (education group E4) in NAICS 621 (Ambulatory Health Care Services). Opt-out states are the 19 states that opted out of the CMS physician supervision requirement for CRNAs between 2001 and 2020. Earnings are average monthly earnings per worker.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  summ_treated$n_states, summ_control$n_states,
  format(round(summ_treated$mean_emp), big.mark = ","),
  format(round(summ_control$mean_emp), big.mark = ","),
  format(round(summ_treated$sd_emp), big.mark = ","),
  format(round(summ_control$sd_emp), big.mark = ","),
  format(round(summ_treated$mean_earn), big.mark = ","),
  format(round(summ_control$mean_earn), big.mark = ","),
  format(round(summ_treated$sd_earn), big.mark = ","),
  format(round(summ_control$sd_earn), big.mark = ","),
  format(round(summ_treated$mean_hires), big.mark = ","),
  format(round(summ_control$mean_hires), big.mark = ","),
  format(summ_treated$n_obs, big.mark = ","),
  format(summ_control$n_obs, big.mark = ",")
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ==========================================================================
# TABLE 2: Main Results (TWFE, C-S, Sun-Abraham, DDD)
# ==========================================================================

cat("Generating Table 2: Main Results\n")

# Extract coefficients (fixest appends "TRUE" to logical variables)
twfe_est <- coef(results$twfe_main)[1]
twfe_se  <- se(results$twfe_main)[1]
twfe_n   <- nobs(results$twfe_main)

cs_est <- results$cs_agg$overall.att
cs_se  <- results$cs_agg$overall.se

# Sun-Abraham: compute aggregate ATT from post-treatment coefficients
sa_coefs <- coef(results$sa_result)
sa_ses   <- se(results$sa_result)
# Post-treatment coefficients have "year::0", "year::1", etc.
post_idx <- grep("^year::[0-9]", names(sa_coefs))
sa_est <- mean(sa_coefs[post_idx], na.rm = TRUE)
# SE via delta method (simple average of independent estimates)
sa_se <- sqrt(mean(sa_ses[post_idx]^2, na.rm = TRUE)) / sqrt(length(post_idx))

# DDD: interaction coefficient (post_optoutTRUE:ambulatory)
ddd_coefs <- coef(results$ddd_result)
ddd_idx <- grep("ambulatory", names(ddd_coefs))
ddd_est <- ddd_coefs[ddd_idx[1]]
ddd_se  <- se(results$ddd_result)[ddd_idx[1]]
ddd_n   <- nobs(results$ddd_result)

tab2 <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Effect of CRNA Supervision Opt-Out on Ambulatory Employment}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & TWFE & C-S & Sun-Abraham & DDD \\\\
 & (1) & (2) & (3) & (4) \\\\
\\midrule
Opt-Out & %s & %s & %s & %s \\\\
 & %s & %s & %s & %s \\\\
\\addlinespace
Outcome & Log Emp & Log Emp & Log Emp & Log Emp \\\\
Sample & BA+, 621 & BA+, 621 & BA+, 621 & BA+, 621/622 \\\\
State FE & Yes & --- & Yes & Yes \\\\
Year FE & Yes & --- & Yes & Yes \\\\
Industry FE & --- & --- & --- & Yes \\\\
Control group & --- & Not-yet & --- & --- \\\\
Observations & %s & %s & %s & %s \\\\
\\# Clusters & 51 & 51 & 51 & 51 \\\\
\\# Treated states & 19 & 19 & 19 & 19 \\\\
Mean dep. var. & %.2f & %.2f & %.2f & --- \\\\
SD dep. var. & %.2f & %.2f & %.2f & --- \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Standard errors clustered at the state level in parentheses. The dependent variable is log average quarterly employment of workers with a bachelor's degree or higher in NAICS 621 (Ambulatory Health Care Services). Column (1): two-way fixed effects. Column (2): Callaway and Sant'Anna (2021) with doubly robust estimation and not-yet-treated control group. Column (3): Sun and Abraham (2021) interaction-weighted estimator. Column (4): triple difference using NAICS 622 (Hospitals) as the within-state control industry with state$\\times$industry and year$\\times$industry fixed effects. Data: QWI, 2000--2023.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  fmt_coef(twfe_est, twfe_se), fmt_coef(cs_est, cs_se),
  fmt_coef(sa_est, sa_se), fmt_coef(ddd_est, ddd_se),
  fmt_se(twfe_se), fmt_se(cs_se), fmt_se(sa_se), fmt_se(ddd_se),
  format(twfe_n, big.mark = ","),
  format(nrow(main), big.mark = ","),
  format(nrow(main), big.mark = ","),
  format(ddd_n, big.mark = ","),
  results$panel_main_summary$mean_log_emp,
  results$panel_main_summary$mean_log_emp,
  results$panel_main_summary$mean_log_emp,
  results$panel_main_summary$sd_log_emp,
  results$panel_main_summary$sd_log_emp,
  results$panel_main_summary$sd_log_emp
)

writeLines(tab2, "../tables/tab2_main.tex")

# ==========================================================================
# TABLE 3: Placebo and Mechanism Tests
# ==========================================================================

cat("Generating Table 3: Placebo Tests\n")

# Education placebo (non-BA in 621)
plac_ed_est <- coef(results$twfe_placebo_ed)[1]
plac_ed_se  <- se(results$twfe_placebo_ed)[1]
plac_ed_n   <- nobs(results$twfe_placebo_ed)

# Industry placebo (BA+ in 623)
plac_ind_est <- coef(results$twfe_placebo_ind)[1]
plac_ind_se  <- se(results$twfe_placebo_ind)[1]
plac_ind_n   <- nobs(results$twfe_placebo_ind)

# Hospital (BA+ in 622) — substitution test
hosp_est <- coef(robustness$twfe_622)[1]
hosp_se  <- se(robustness$twfe_622)[1]
hosp_n   <- nobs(robustness$twfe_622)

# Earnings
earn_est <- coef(results$twfe_earn)[1]
earn_se  <- se(results$twfe_earn)[1]
earn_n   <- nobs(results$twfe_earn)

# Hires
hires_est <- coef(robustness$twfe_hires)[1]
hires_se  <- se(robustness$twfe_hires)[1]
hires_n   <- nobs(robustness$twfe_hires)

tab3 <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Placebo Tests and Secondary Outcomes}
\\label{tab:placebo}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & Non-BA & BA+ & BA+ & BA+ & BA+ \\\\
 & Amb. (621) & Nursing (623) & Hospital (622) & Earnings & Hires \\\\
 & (1) & (2) & (3) & (4) & (5) \\\\
\\midrule
Opt-Out & %s & %s & %s & %s & %s \\\\
 & %s & %s & %s & %s & %s \\\\
\\addlinespace
Placebo & Yes & Yes & No & No & No \\\\
Observations & %s & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. All regressions include state and year fixed effects with state-clustered standard errors. Column (1): non-BA workers in ambulatory care (should be null if the effect operates through advanced-practice providers). Column (2): BA+ workers in nursing and residential care facilities (should be null if CRNAs do not work in this sector). Column (3): BA+ hospital workers (tests hospital-to-ambulatory substitution). Column (4): log average quarterly earnings. Column (5): log annual hires. Data: QWI, 2000--2023.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  fmt_coef(plac_ed_est, plac_ed_se),
  fmt_coef(plac_ind_est, plac_ind_se),
  fmt_coef(hosp_est, hosp_se),
  fmt_coef(earn_est, earn_se),
  fmt_coef(hires_est, hires_se),
  fmt_se(plac_ed_se), fmt_se(plac_ind_se), fmt_se(hosp_se),
  fmt_se(earn_se), fmt_se(hires_se),
  format(plac_ed_n, big.mark = ","),
  format(plac_ind_n, big.mark = ","),
  format(hosp_n, big.mark = ","),
  format(earn_n, big.mark = ","),
  format(hires_n, big.mark = ",")
)

writeLines(tab3, "../tables/tab3_placebo.tex")

# ==========================================================================
# TABLE 4: Robustness — Leave-One-Wave-Out + Alternative Control
# ==========================================================================

cat("Generating Table 4: Robustness\n")

lowo <- robustness$lowo_results
cs_never_est <- robustness$cs_never_agg$overall.att
cs_never_se  <- robustness$cs_never_agg$overall.se

# Build LOWO rows
lowo_rows <- ""
for (w in names(lowo)) {
  r <- lowo[[w]]
  lowo_rows <- paste0(lowo_rows, sprintf(
    "Drop wave %s (%d states) & %s & %s \\\\\n",
    w, r$n_states, fmt_coef(r$coef, r$se), fmt_se(r$se)
  ))
}

tab4 <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Robustness: Leave-One-Wave-Out and Alternative Controls}
\\label{tab:robust}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Specification & Coefficient & SE \\\\
\\midrule
\\textit{Panel A: Baseline} & & \\\\
TWFE & %s & %s \\\\
C-S (not-yet-treated) & %s & %s \\\\
C-S (never-treated only) & %s & %s \\\\
\\addlinespace
\\textit{Panel B: Leave-one-wave-out} & & \\\\
%s\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Panel A compares the baseline TWFE and Callaway--Sant'Anna estimates under not-yet-treated and never-treated control groups. Panel B sequentially drops each adoption wave. The number of treated states remaining is shown in parentheses after the wave year. Dependent variable: log BA+ employment in NAICS 621. Data: QWI, 2000--2023.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  fmt_coef(twfe_est, twfe_se), fmt_se(twfe_se),
  fmt_coef(cs_est, cs_se), fmt_se(cs_se),
  fmt_coef(cs_never_est, cs_never_se), fmt_se(cs_never_se),
  lowo_rows
)

writeLines(tab4, "../tables/tab4_robust.tex")

# ==========================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ==========================================================================

cat("Generating Table F1: SDE\n")

# Compute SDEs
sd_y_log_emp  <- results$panel_main_summary$sd_log_emp
sd_y_log_earn <- results$panel_main_summary$sd_log_earn

# Panel A: Pooled
sde_emp <- twfe_est / sd_y_log_emp
se_sde_emp <- twfe_se / sd_y_log_emp

sde_earn <- earn_est / sd_y_log_earn
se_sde_earn <- earn_se / sd_y_log_earn

main$log_hires <- log(pmax(main$hires, 1))
sde_hires_sd <- sd(main$log_hires, na.rm = TRUE)
sde_hires <- hires_est / sde_hires_sd
se_sde_hires <- hires_se / sde_hires_sd

classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel B: Heterogeneous — early vs late adopters
early_states <- main %>% filter(g_period > 0 & g_period <= 2005)
late_states  <- main %>% filter(g_period > 0 & g_period > 2005)

# Split sample: early adopters only
early_panel <- main %>% filter(g_period <= 2005 | g_period == 0)
late_panel  <- main %>% filter(g_period == 0 | g_period > 2005)

twfe_early <- feols(log_emp ~ post_optout | state_id + year,
                     data = early_panel, cluster = ~state_id)
twfe_late  <- feols(log_emp ~ post_optout | state_id + year,
                     data = late_panel, cluster = ~state_id)

sde_early <- coef(twfe_early)[1] / sd_y_log_emp
se_sde_early <- se(twfe_early)[1] / sd_y_log_emp

sde_late <- coef(twfe_late)[1] / sd_y_log_emp
se_sde_late <- se(twfe_late)[1] / sd_y_log_emp

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does removing Medicare's physician supervision requirement for Certified Registered Nurse Anesthetists (CRNAs) expand ambulatory health care employment? ",
  "\\textbf{Policy mechanism:} State governors opt out of a 2001 CMS Conditions of Participation rule that required physician supervision of CRNAs in hospitals and ambulatory surgical centers, enabling CRNAs to practice independently and bill Medicare without physician oversight. ",
  "\\textbf{Outcome definition:} Log average quarterly employment of workers with a bachelor's degree or higher (QWI education group E4) in NAICS 621 (Ambulatory Health Care Services). ",
  "\\textbf{Treatment:} Binary; a state-year is treated from the year its governor's opt-out takes effect onward. ",
  "\\textbf{Data:} Census Bureau Quarterly Workforce Indicators (QWI), 2000--2023, state-year panel, 51 states (19 treated, 32 never-treated), ",
  format(nrow(main), big.mark = ","), " state-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (state + year) with state-clustered standard errors; robustness via Callaway--Sant'Anna (2021) doubly robust estimator with not-yet-treated controls. ",
  "\\textbf{Sample:} All 50 states plus DC; restricted to BA+ education group to isolate advanced-practice providers (CRNAs, NPs, PAs). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-state standard deviation of the outcome variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\textit{Panel A: Pooled} & & & & & & \\\\
Log employment (BA+, 621) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\
Log earnings (BA+, 621)   & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\
Log hires (BA+, 621)      & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\
\\addlinespace
\\textit{Panel B: Heterogeneous} & & & & & & \\\\
Early adopters (2002--2005) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\
Late adopters (2009--2020)  & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  twfe_est, twfe_se, sd_y_log_emp, sde_emp, se_sde_emp, classify_sde(sde_emp),
  earn_est, earn_se, sd_y_log_earn, sde_earn, se_sde_earn, classify_sde(sde_earn),
  hires_est, hires_se, sde_hires_sd, sde_hires, se_sde_hires, classify_sde(sde_hires),
  coef(twfe_early)[1], se(twfe_early)[1], sd_y_log_emp,
  sde_early, se_sde_early, classify_sde(sde_early),
  coef(twfe_late)[1], se(twfe_late)[1], sd_y_log_emp,
  sde_late, se_sde_late, classify_sde(sde_late),
  sde_notes
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated successfully.\n")
