## 05_tables.R — Generate all tables for the paper
source("00_packages.R")

dt <- readRDS("../data/analysis_panel.rds")
models <- readRDS("../data/model_objects.rds")
rob <- readRDS("../data/robustness_results.rds")

est <- dt[state_group != "Always-Treated"]

# ======================================================================
# Table 1: Summary Statistics
# ======================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Pre-ban period (2016-2019), knowledge sectors
pre <- est[year <= 2019 & knowledge == TRUE]
summ <- pre[, .(
  N = .N,
  mean_emp = mean(Emp, na.rm = TRUE),
  mean_sep_rate = mean(sep_rate, na.rm = TRUE),
  sd_sep_rate = sd(sep_rate, na.rm = TRUE),
  mean_hire_rate = mean(hire_rate, na.rm = TRUE),
  mean_earn = mean(EarnS, na.rm = TRUE)
), by = .(state_group, race_label)]

setorder(summ, state_group, race_label)

# Also compute gaps
gaps <- pre[, .(
  sep_gap = mean(sep_rate[race == "A2"], na.rm = TRUE) -
            mean(sep_rate[race == "A1"], na.rm = TRUE),
  earn_gap = mean(EarnS[race == "A2"], na.rm = TRUE) -
             mean(EarnS[race == "A1"], na.rm = TRUE)
), by = state_group]

cat("Summary stats:\n")
print(summ)
cat("\nRacial gaps:\n")
print(gaps)

# Write LaTeX table
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Knowledge Sectors (NAICS 51, 54), Pre-Ban Period (2016--2019)}\n")
cat("\\label{tab:summary}\n")
cat("\\small\n")
cat("\\begin{tabular}{llccccc}\n")
cat("\\hline\\hline\n")
cat("State Group & Race & N & Emp & Sep Rate & Hire Rate & Earnings \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(summ)) {
  r <- summ[i]
  cat(sprintf("%s & %s & %d & %s & %.3f & %.3f & \\$%s \\\\\n",
              r$state_group, r$race_label, r$N,
              format(round(r$mean_emp), big.mark = ","),
              r$mean_sep_rate, r$mean_hire_rate,
              format(round(r$mean_earn), big.mark = ",")))
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\footnotesize \\textit{Notes:} Quarterly separation rate = Separations/Employment. Earnings are average monthly}\\\\\n")
cat("\\multicolumn{7}{l}{\\footnotesize earnings (\\$). Ban states: CO, IL, MN, OR, WA. Control: all other states excluding CA, OK, ND.}\\\\\n")
cat("\\multicolumn{7}{l}{\\footnotesize Knowledge sectors: NAICS 51 (Information) and 54 (Professional/Technical Services).}\\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tab1_summary.tex\n")

# ======================================================================
# Table 2: Main Results (DDDD)
# ======================================================================
cat("\n=== Table 2: Main Results ===\n")

# Build etable
sink("../tables/tab2_main.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Non-Compete Bans and the Racial Mobility Gap: Triple- and Quadruple-Difference Estimates}\n")
cat("\\label{tab:main}\n")
cat("\\small\n")

etable(models$m1, models$m3, models$m4, models$m5, models$m6,
       tex = TRUE,
       style.tex = style.tex("aer"),
       fitstat = c("n", "r2"),
       dict = c(
         "post" = "Post $\\times$ Ban",
         "post:knowledge" = "Post $\\times$ Ban $\\times$ Knowledge",
         "post:knowledge:black" = "Post $\\times$ Ban $\\times$ Knowledge $\\times$ Black",
         "post:black" = "Post $\\times$ Ban $\\times$ Black",
         "knowledge:black" = "Knowledge $\\times$ Black"
       ),
       headers = list(
         "Dep. Var." = c("Sep Rate", "Sep Rate", "Sep Rate", "Log Earn", "Hire Rate")
       ),
       notes = paste0(
         "Standard errors clustered at state level in parentheses. ",
         "Knowledge sectors: NAICS 51 (Information) and 54 (Professional/Technical). ",
         "Placebo sector: NAICS 72 (Accommodation/Food). ",
         "Ban states: OR/WA (2020), CO/IL (2022), MN (2023). ",
         "Column (1): simple DiD. Column (2): DDD. Columns (3)--(5): DDDD with race interaction. ",
         "Sample excludes always-treated states (CA, OK, ND). ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
       ),
       file = "../tables/tab2_main.tex",
       replace = TRUE)

sink()
cat("Wrote tab2_main.tex\n")

# ======================================================================
# Table 3: Robustness
# ======================================================================
cat("\n=== Table 3: Robustness ===\n")

# Reconstruct models for robustness table
# Placebo: NAICS 72 only
placebo_dt <- est[industry == "72"]
r2_m <- feols(sep_rate ~ post + post:black | state_abbr + yq + race,
              data = placebo_dt, cluster = ~state_abbr)

# Drop COVID
no_covid <- est[!(year == 2020 & quarter %in% c(2, 3, 4))]
r4_m <- feols(sep_rate ~ post:knowledge + post:knowledge:black + post:black +
                knowledge:black |
                state_abbr^industry^race + yq^industry^race + state_abbr^yq^race,
              data = no_covid, cluster = ~state_abbr)

# Pre-trend placebo (fake 2018 treatment) — simpler FE to avoid collinearity
pre_dt <- est[year <= 2019]
pre_dt[, fake_post := as.integer(time_q >= 2018.00)]
r3_m <- feols(sep_rate ~ i(fake_post, ban_state):knowledge:black +
                i(fake_post, ban_state):knowledge +
                i(fake_post, ban_state):black |
                state_abbr + yq + industry + race,
              data = pre_dt, cluster = ~state_abbr)

# NAICS 51 only
dt_51 <- est[industry %in% c("51", "72")]
dt_51[, knowledge_i := industry == "51"]
r5a <- feols(sep_rate ~ post:knowledge_i + post:knowledge_i:black + post:black +
               knowledge_i:black |
               state_abbr^industry^race + yq^industry^race + state_abbr^yq^race,
             data = dt_51, cluster = ~state_abbr)

# NAICS 54 only
dt_54 <- est[industry %in% c("54", "72")]
dt_54[, knowledge_i := industry == "54"]
r5b <- feols(sep_rate ~ post:knowledge_i + post:knowledge_i:black + post:black +
               knowledge_i:black |
               state_abbr^industry^race + yq^industry^race + state_abbr^yq^race,
             data = dt_54, cluster = ~state_abbr)

# Write robustness table manually (models have different coefficient names)
sink("../tables/tab3_robustness.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robust}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat(" & Baseline & No COVID & Placebo & Pre-Trend & NAICS 51 & NAICS 54 \\\\\n")
cat("\\hline\n")

# Extract key coefficients
get_coef <- function(m, pattern) {
  ct <- coeftable(m)
  idx <- grep(pattern, rownames(ct), fixed = TRUE)
  if (length(idx) == 0) return(c(NA, NA))
  c(ct[idx[1], "Estimate"], ct[idx[1], "Std. Error"])
}

fmt_coef <- function(est, se) {
  if (is.na(est)) return("---")
  stars <- ""
  pval <- 2 * pnorm(-abs(est / se))
  if (pval < 0.01) stars <- "***"
  else if (pval < 0.05) stars <- "**"
  else if (pval < 0.10) stars <- "*"
  sprintf("%.4f%s", est, stars)
}

# Row 1: Black interaction coefficient (separation rate)
c1 <- get_coef(models$m4, "knowledge:black")
c2 <- get_coef(r4_m, "knowledge:black")
c3_m <- get_coef(r2_m, "post")  # placebo: just post effect
c4 <- get_coef(r3_m, "knowledge:black")
c5 <- get_coef(r5a, "knowledge_i:black")
c6 <- get_coef(r5b, "knowledge_i:black")

cat(sprintf("DDD $\\times$ Black & %s & %s & --- & %s & %s & %s \\\\\n",
            fmt_coef(c1[1], c1[2]), fmt_coef(c2[1], c2[2]),
            fmt_coef(c4[1], c4[2]),
            fmt_coef(c5[1], c5[2]), fmt_coef(c6[1], c6[2])))
cat(sprintf(" & (%s) & (%s) & & (%s) & (%s) & (%s) \\\\\n",
            sprintf("%.4f", c1[2]), sprintf("%.4f", c2[2]),
            sprintf("%.4f", c4[2]),
            sprintf("%.4f", c5[2]), sprintf("%.4f", c6[2])))

# Row 2: Placebo (post effect in NAICS 72)
cat(sprintf("Post $\\times$ Ban (Placebo) & --- & --- & %s & --- & --- & --- \\\\\n",
            fmt_coef(c3_m[1], c3_m[2])))
cat(sprintf(" & & & (%s) & & & \\\\\n", sprintf("%.4f", c3_m[2])))

cat("\\hline\n")
cat(sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
            format(nobs(models$m4), big.mark = ","),
            format(nobs(r4_m), big.mark = ","),
            format(nobs(r2_m), big.mark = ","),
            format(nobs(r3_m), big.mark = ","),
            format(nobs(r5a), big.mark = ","),
            format(nobs(r5b), big.mark = ",")))
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\footnotesize \\textit{Notes:} Columns (1)--(2), (5)--(6): DDDD specification (separation rate).}\\\\\n")
cat("\\multicolumn{7}{l}{\\footnotesize Column (3): DD on NAICS 72 placebo sector only (no knowledge-sector exposure).}\\\\\n")
cat("\\multicolumn{7}{l}{\\footnotesize Column (4): fake 2018 treatment on pre-ban data only.}\\\\\n")
cat("\\multicolumn{7}{l}{\\footnotesize Standard errors clustered at state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.}\\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tab3_robustness.tex\n")

# ======================================================================
# Table 4: Descriptive Racial Gap Evolution (Knowledge Sectors)
# ======================================================================
cat("\n=== Table 4: Racial Gap Evolution ===\n")

es_means <- readRDS("../data/event_study_means.rds")

# Aggregate by year for cleaner table
es_yr <- est[knowledge == TRUE, .(
  sep_black_ban = mean(sep_rate[black == 1 & ban_state == TRUE], na.rm = TRUE),
  sep_white_ban = mean(sep_rate[black == 0 & ban_state == TRUE], na.rm = TRUE),
  sep_black_ctrl = mean(sep_rate[black == 1 & ban_state == FALSE], na.rm = TRUE),
  sep_white_ctrl = mean(sep_rate[black == 0 & ban_state == FALSE], na.rm = TRUE),
  earn_black_ban = mean(EarnS[black == 1 & ban_state == TRUE], na.rm = TRUE),
  earn_white_ban = mean(EarnS[black == 0 & ban_state == TRUE], na.rm = TRUE),
  earn_black_ctrl = mean(EarnS[black == 1 & ban_state == FALSE], na.rm = TRUE),
  earn_white_ctrl = mean(EarnS[black == 0 & ban_state == FALSE], na.rm = TRUE)
), by = year]
es_yr[, sep_gap_ban := sep_black_ban - sep_white_ban]
es_yr[, sep_gap_ctrl := sep_black_ctrl - sep_white_ctrl]
es_yr[, earn_gap_ban := earn_black_ban - earn_white_ban]
es_yr[, earn_gap_ctrl := earn_black_ctrl - earn_white_ctrl]
es_yr[, ddd_sep := sep_gap_ban - sep_gap_ctrl]
es_yr[, ddd_earn := earn_gap_ban - earn_gap_ctrl]
setorder(es_yr, year)

sink("../tables/tab4_gap_evolution.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Evolution of Racial Gaps in Knowledge Sectors}\n")
cat("\\label{tab:gaps}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{3}{c}{Separation Rate Gap} & \\multicolumn{3}{c}{Earnings Gap (\\$)} \\\\\n")
cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n")
cat("Year & Ban & Control & DDD & Ban & Control & DDD \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(es_yr)) {
  r <- es_yr[i]
  cat(sprintf("%d & %.3f & %.3f & %.3f & %s & %s & %s \\\\\n",
              r$year, r$sep_gap_ban, r$sep_gap_ctrl, r$ddd_sep,
              format(round(r$earn_gap_ban), big.mark = ","),
              format(round(r$earn_gap_ctrl), big.mark = ","),
              format(round(r$ddd_earn), big.mark = ",")))
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\footnotesize \\textit{Notes:} Gap = Black $-$ White mean. Ban states: CO, IL, MN, OR, WA.}\\\\\n")
cat("\\multicolumn{7}{l}{\\footnotesize Knowledge sectors: NAICS 51 and 54. First ban enactment: OR/WA, Jan 2020.}\\\\\n")
cat("\\multicolumn{7}{l}{\\footnotesize DDD = Ban gap $-$ Control gap. Negative DDD = ban states' racial gap narrowing relative to control.}\\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tab4_gap_evolution.tex\n")

# ======================================================================
# Table F1: SDE Appendix
# ======================================================================
cat("\n=== Table F1: SDE ===\n")

# Get key coefficients from DDDD model
m4_ct <- coeftable(models$m4)
m5_ct <- coeftable(models$m5)
m6_ct <- coeftable(models$m6)

# Pre-treatment SD of outcomes
pre_est <- est[year <= 2019]
sd_sep <- sd(pre_est$sep_rate, na.rm = TRUE)
sd_log_earn <- sd(pre_est$log_earn, na.rm = TRUE)
sd_hire <- sd(pre_est$hire_rate, na.rm = TRUE)

# Function to classify SDE
classify_sde <- function(sde) {
  if (is.na(sde)) return("Indeterminate")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Extract DDD coefficient (post:knowledge) and DDDD interaction (post:knowledge:black)
# Panel A: Pooled (DDD coefficient)
get_sde_row <- function(ct, coef_name, outcome_name, sd_y) {
  idx <- grep(coef_name, rownames(ct), fixed = TRUE)
  if (length(idx) == 0) return(NULL)
  beta <- ct[idx[1], "Estimate"]
  se_beta <- ct[idx[1], "Std. Error"]
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  class_label <- classify_sde(sde)
  list(outcome = outcome_name, beta = beta, se = se_beta,
       sd_y = sd_y, sde = sde, se_sde = se_sde, class = class_label)
}

# NOTE: fixest uses TRUE/FALSE suffixes in coefficient names
# DDD coefficient is absorbed into FE; use the remaining coefs

# For Panel A, we need a model without race dimension to get the DDD coef
# Re-estimate a DDD model (without race) for SDE
est_a <- dt[state_group != "Always-Treated"]
m_ddd_sep <- feols(sep_rate ~ post:knowledge | state_abbr^industry + yq^industry + state_abbr^yq,
                   data = est_a, cluster = ~state_abbr)
m_ddd_earn <- feols(log_earn ~ post:knowledge | state_abbr^industry + yq^industry + state_abbr^yq,
                    data = est_a, cluster = ~state_abbr)
m_ddd_hire <- feols(hire_rate ~ post:knowledge | state_abbr^industry + yq^industry + state_abbr^yq,
                    data = est_a, cluster = ~state_abbr)

# Panel A: DDD coefficients (pooled across races)
get_first_coef <- function(m, sd_y) {
  ct <- coeftable(m)
  # Get the first non-collinear coefficient
  beta <- ct[1, "Estimate"]
  se_beta <- ct[1, "Std. Error"]
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  class_label <- classify_sde(sde)
  list(beta = beta, se = se_beta, sd_y = sd_y, sde = sde, se_sde = se_sde, class = class_label)
}

rows_a <- list(
  c(list(outcome = "Separation Rate"), get_first_coef(m_ddd_sep, sd_sep)),
  c(list(outcome = "Log Earnings"), get_first_coef(m_ddd_earn, sd_log_earn)),
  c(list(outcome = "Hire Rate"), get_first_coef(m_ddd_hire, sd_hire))
)

# Panel B: DDDD coefficients (Black differential) — use "postTRUE:knowledgeTRUE:black"
rows_b <- list(
  get_sde_row(m4_ct, "postTRUE:knowledgeTRUE:black", "Separation Rate (Black)", sd_sep),
  get_sde_row(m5_ct, "postTRUE:knowledgeTRUE:black", "Log Earnings (Black)", sd_log_earn),
  get_sde_row(m6_ct, "postTRUE:knowledgeTRUE:black", "Hire Rate (Black)", sd_hire)
)
rows_b <- Filter(Negate(is.null), rows_b)

# Combine for display
cat("Panel A (Pooled - DDD):\n")
for (r in rows_a) cat(sprintf("  %s: beta=%.4f, SDE=%.4f, class=%s\n", r$outcome, r$beta, r$sde, r$class))
cat("Panel B (Black differential - DDDD):\n")
for (r in rows_b) cat(sprintf("  %s: beta=%.4f, SDE=%.4f, class=%s\n", r$outcome, r$beta, r$sde, r$class))

# Write SDE LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state non-compete agreement bans differentially ",
  "reduce racial disparities in worker separation rates, hiring rates, and earnings ",
  "in knowledge-intensive industries? ",
  "\\textbf{Policy mechanism:} State bans prohibit employers from enforcing non-compete ",
  "clauses, which constrain worker mobility by preventing employees from joining competitors ",
  "or starting competing firms; bans remove this constraint, particularly affecting ",
  "knowledge-intensive sectors where non-competes are prevalent. ",
  "\\textbf{Outcome definition:} Quarterly separation rate (separations divided by beginning-of-quarter employment), ",
  "log average monthly earnings, and quarterly hire rate (hires divided by employment), ",
  "all from the Quarterly Workforce Indicators. ",
  "\\textbf{Treatment:} Binary indicator for state-quarter observations after non-compete ban enactment. ",
  "\\textbf{Data:} QWI race-by-industry administrative data from the Census Bureau, 2016--2023, ",
  "state-quarter-industry-race cells, approximately 9,000 observations. ",
  "\\textbf{Method:} Triple-difference (state $\\times$ industry $\\times$ time) and quadruple-difference ",
  "(adding race), standard errors clustered at state level, with wild cluster bootstrap for inference. ",
  "\\textbf{Sample:} All U.S. states excluding always-treated (CA, OK, ND); knowledge sectors ",
  "(NAICS 51, 54) vs.\\ placebo sector (NAICS 72); White and Black workers. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled (Post $\\times$ Ban $\\times$ Knowledge)}} \\\\\n")
cat("\\hline\n")
for (r in rows_a) {
  cat(sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Post $\\times$ Ban $\\times$ Knowledge $\\times$ Black)}} \\\\\n")
cat("\\hline\n")
for (r in rows_b) {
  cat(sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{itemize}[leftmargin=*,nosep]\n")
cat(sde_notes, "\n")
cat("\\end{itemize}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
