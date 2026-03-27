## 05_tables.R — Generate all tables for paper
## apep_1076: Conversion Therapy Bans and Adolescent Mental Health

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load all results
analysis <- fread(file.path(data_dir, "analysis_sample.csv"))
ddd_sample <- fread(file.path(data_dir, "ddd_sample.csv"))
did_results <- readRDS(file.path(data_dir, "did_results.rds"))
did_results_controls <- readRDS(file.path(data_dir, "did_results_controls.rds"))
ddd_cross <- readRDS(file.path(data_dir, "ddd_cross.rds"))
lgb_cross <- readRDS(file.path(data_dir, "lgb_cross.rds"))
het_cross <- readRDS(file.path(data_dir, "het_cross.rds"))
pre_means <- readRDS(file.path(data_dir, "pre_means.rds"))

outcomes <- c("sad_hopeless", "considered_suicide", "suicide_plan", "suicide_attempt")
outcome_labels <- c("Persistent\\\\Sadness", "Considered\\\\Suicide",
                     "Suicide\\\\Plan", "Suicide\\\\Attempt")

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================

cat("Generating Table 1: Summary Statistics\n")

# Overall statistics
overall_stats <- analysis[, .(
  N = .N,
  sad_hopeless = round(mean(sad_hopeless, na.rm = TRUE), 3),
  considered_suicide = round(mean(considered_suicide, na.rm = TRUE), 3),
  suicide_plan = round(mean(suicide_plan, na.rm = TRUE), 3),
  suicide_attempt = round(mean(suicide_attempt, na.rm = TRUE), 3),
  female_pct = round(mean(female, na.rm = TRUE), 3),
  n_states = uniqueN(state_abbr)
)]

# By treatment status
by_treat <- analysis[, .(
  N = .N,
  sad_hopeless = round(mean(sad_hopeless, na.rm = TRUE), 3),
  considered_suicide = round(mean(considered_suicide, na.rm = TRUE), 3),
  suicide_plan = round(mean(suicide_plan, na.rm = TRUE), 3),
  suicide_attempt = round(mean(suicide_attempt, na.rm = TRUE), 3),
  female_pct = round(mean(female, na.rm = TRUE), 3),
  n_states = uniqueN(state_abbr)
), by = treated]

# By sexual identity (2021-2023 subsample)
by_lgb <- ddd_sample[, .(
  N = .N,
  sad_hopeless = round(mean(sad_hopeless, na.rm = TRUE), 3),
  considered_suicide = round(mean(considered_suicide, na.rm = TRUE), 3),
  suicide_plan = round(mean(suicide_plan, na.rm = TRUE), 3),
  suicide_attempt = round(mean(suicide_attempt, na.rm = TRUE), 3)
), by = lgb]

tab1_tex <- paste0(
"\\begin{table}[t]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{1}{c}{All} & \\multicolumn{1}{c}{Ban States} & \\multicolumn{1}{c}{No-Ban States} & \\multicolumn{1}{c}{Difference} \\\\
\\hline
\\multicolumn{5}{l}{\\textit{Panel A: Full Sample (2015--2023)}} \\\\[3pt]
Persistent sadness & ", overall_stats$sad_hopeless, " & ",
  by_treat[treated == 1, sad_hopeless], " & ",
  by_treat[treated == 0, sad_hopeless], " & ",
  round(by_treat[treated == 1, sad_hopeless] - by_treat[treated == 0, sad_hopeless], 3), " \\\\
Considered suicide & ", overall_stats$considered_suicide, " & ",
  by_treat[treated == 1, considered_suicide], " & ",
  by_treat[treated == 0, considered_suicide], " & ",
  round(by_treat[treated == 1, considered_suicide] - by_treat[treated == 0, considered_suicide], 3), " \\\\
Suicide plan & ", overall_stats$suicide_plan, " & ",
  by_treat[treated == 1, suicide_plan], " & ",
  by_treat[treated == 0, suicide_plan], " & ",
  round(by_treat[treated == 1, suicide_plan] - by_treat[treated == 0, suicide_plan], 3), " \\\\
Suicide attempt & ", overall_stats$suicide_attempt, " & ",
  by_treat[treated == 1, suicide_attempt], " & ",
  by_treat[treated == 0, suicide_attempt], " & ",
  round(by_treat[treated == 1, suicide_attempt] - by_treat[treated == 0, suicide_attempt], 3), " \\\\
Female (\\%) & ", overall_stats$female_pct, " & ",
  by_treat[treated == 1, female_pct], " & ",
  by_treat[treated == 0, female_pct], " & ",
  round(by_treat[treated == 1, female_pct] - by_treat[treated == 0, female_pct], 3), " \\\\
Observations & ", format(overall_stats$N, big.mark = ","), " & ",
  format(by_treat[treated == 1, N], big.mark = ","), " & ",
  format(by_treat[treated == 0, N], big.mark = ","), " & \\\\
States & ", overall_stats$n_states, " & ",
  by_treat[treated == 1, n_states], " & ",
  by_treat[treated == 0, n_states], " & \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Sexual Identity Subsample (2021--2023)}} \\\\[3pt]
 & \\multicolumn{1}{c}{Heterosexual} & \\multicolumn{1}{c}{LGB} & & \\\\
Persistent sadness & ",
  by_lgb[lgb == 0, sad_hopeless], " & ",
  by_lgb[lgb == 1, sad_hopeless], " & & ",
  round(by_lgb[lgb == 1, sad_hopeless] - by_lgb[lgb == 0, sad_hopeless], 3), " \\\\
Considered suicide & ",
  by_lgb[lgb == 0, considered_suicide], " & ",
  by_lgb[lgb == 1, considered_suicide], " & & ",
  round(by_lgb[lgb == 1, considered_suicide] - by_lgb[lgb == 0, considered_suicide], 3), " \\\\
Suicide plan & ",
  by_lgb[lgb == 0, suicide_plan], " & ",
  by_lgb[lgb == 1, suicide_plan], " & & ",
  round(by_lgb[lgb == 1, suicide_plan] - by_lgb[lgb == 0, suicide_plan], 3), " \\\\
Suicide attempt & ",
  by_lgb[lgb == 0, suicide_attempt], " & ",
  by_lgb[lgb == 1, suicide_attempt], " & & ",
  round(by_lgb[lgb == 1, suicide_attempt] - by_lgb[lgb == 0, suicide_attempt], 3), " \\\\
Observations & ",
  format(by_lgb[lgb == 0, N], big.mark = ","), " & ",
  format(by_lgb[lgb == 1, N], big.mark = ","), " & & \\\\
\\hline\\hline
\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Panel A reports means for the full analysis sample of high school students from the CDC Youth Risk Behavior Survey (YRBSS), 2015--2023. Ban States are state-years where a conversion therapy ban was in effect. Panel B reports means by sexual identity for the subsample of students in waves where the sexual identity question was asked (2021--2023). All outcomes are binary indicators.}
\\end{tabular}
\\end{table}")

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# =============================================================================
# Table 2: Main DiD Results
# =============================================================================

cat("Generating Table 2: Main DiD Results\n")

# Format coefficient rows
fmt_coef <- function(est, var = "treated") {
  b <- coef(est)[var]
  s <- se(est)[var]
  p <- pvalue(est)[var]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  paste0(sprintf("%.4f", b), "$", stars, "$")
}

fmt_se <- function(est, var = "treated") {
  s <- se(est)[var]
  paste0("(", sprintf("%.4f", s), ")")
}

tab2_tex <- paste0(
"\\begin{table}[t]
\\centering
\\caption{Effect of Conversion Therapy Bans on Adolescent Mental Health}
\\label{tab:main}
\\begin{tabular}{l*{4}{c}}
\\hline\\hline
 & Persistent & Considered & Suicide & Suicide \\\\
 & Sadness & Suicide & Plan & Attempt \\\\
 & (1) & (2) & (3) & (4) \\\\
\\hline
\\multicolumn{5}{l}{\\textit{Panel A: No individual controls}} \\\\[3pt]
Ban enacted & ", fmt_coef(did_results[["sad_hopeless"]]), " & ",
  fmt_coef(did_results[["considered_suicide"]]), " & ",
  fmt_coef(did_results[["suicide_plan"]]), " & ",
  fmt_coef(did_results[["suicide_attempt"]]), " \\\\
 & ", fmt_se(did_results[["sad_hopeless"]]), " & ",
  fmt_se(did_results[["considered_suicide"]]), " & ",
  fmt_se(did_results[["suicide_plan"]]), " & ",
  fmt_se(did_results[["suicide_attempt"]]), " \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: With individual controls}} \\\\[3pt]
Ban enacted & ", fmt_coef(did_results_controls[["sad_hopeless"]]), " & ",
  fmt_coef(did_results_controls[["considered_suicide"]]), " & ",
  fmt_coef(did_results_controls[["suicide_plan"]]), " & ",
  fmt_coef(did_results_controls[["suicide_attempt"]]), " \\\\
 & ", fmt_se(did_results_controls[["sad_hopeless"]]), " & ",
  fmt_se(did_results_controls[["considered_suicide"]]), " & ",
  fmt_se(did_results_controls[["suicide_plan"]]), " & ",
  fmt_se(did_results_controls[["suicide_attempt"]]), " \\\\[6pt]
\\hline
Pre-treatment mean & ",
  round(pre_means$sad_hopeless_mean, 3), " & ",
  round(pre_means$considered_suicide_mean, 3), " & ",
  round(pre_means$suicide_plan_mean, 3), " & ",
  round(pre_means$suicide_attempt_mean, 3), " \\\\
State FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Individual controls & No/Yes & No/Yes & No/Yes & No/Yes \\\\
Observations & \\multicolumn{4}{c}{", format(nrow(analysis), big.mark = ","), "} \\\\
States & \\multicolumn{4}{c}{", uniqueN(analysis$state_abbr), "} \\\\
\\hline\\hline
\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Each column reports a separate difference-in-differences regression of the outcome on an indicator for whether the state had enacted a conversion therapy ban. Panel A includes state and year fixed effects only. Panel B adds individual controls (sex, race, and grade). Standard errors clustered at the state level in parentheses. Survey weights applied. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.}
\\end{tabular}
\\end{table}")

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))

# =============================================================================
# Table 3: Heterogeneity by Sexual Identity (DDD)
# =============================================================================

cat("Generating Table 3: Heterogeneity by Sexual Identity\n")

tab3_tex <- paste0(
"\\begin{table}[t]
\\centering
\\caption{Heterogeneity by Sexual Identity (2021--2023)}
\\label{tab:ddd}
\\begin{tabular}{l*{4}{c}}
\\hline\\hline
 & Persistent & Considered & Suicide & Suicide \\\\
 & Sadness & Suicide & Plan & Attempt \\\\
 & (1) & (2) & (3) & (4) \\\\
\\hline
\\multicolumn{5}{l}{\\textit{Panel A: Interaction specification}} \\\\[3pt]")

# Interaction terms from ddd_cross
for (y in outcomes) {
  est <- ddd_cross[[y]]
  cn <- names(coef(est))
  ban_name <- grep("^treated$", cn, value = TRUE)
  lgb_name <- grep("^lgb$", cn, value = TRUE)
  int_name <- grep("treated.*lgb", cn, value = TRUE)

  if (y == outcomes[1]) {
    # Print Ban effect
    tab3_tex <- paste0(tab3_tex, "\n",
      "Ban enacted & ", fmt_coef(est, "treated"), " & ",
      fmt_coef(ddd_cross[["considered_suicide"]], "treated"), " & ",
      fmt_coef(ddd_cross[["suicide_plan"]], "treated"), " & ",
      fmt_coef(ddd_cross[["suicide_attempt"]], "treated"), " \\\\")
    tab3_tex <- paste0(tab3_tex, "\n",
      " & ", fmt_se(est, "treated"), " & ",
      fmt_se(ddd_cross[["considered_suicide"]], "treated"), " & ",
      fmt_se(ddd_cross[["suicide_plan"]], "treated"), " & ",
      fmt_se(ddd_cross[["suicide_attempt"]], "treated"), " \\\\")
  }
}

# Interaction term
tab3_tex <- paste0(tab3_tex, "\n",
  "Ban $\\times$ LGB & ",
  fmt_coef(ddd_cross[["sad_hopeless"]], "treated:lgb"), " & ",
  fmt_coef(ddd_cross[["considered_suicide"]], "treated:lgb"), " & ",
  fmt_coef(ddd_cross[["suicide_plan"]], "treated:lgb"), " & ",
  fmt_coef(ddd_cross[["suicide_attempt"]], "treated:lgb"), " \\\\")
tab3_tex <- paste0(tab3_tex, "\n",
  " & ", fmt_se(ddd_cross[["sad_hopeless"]], "treated:lgb"), " & ",
  fmt_se(ddd_cross[["considered_suicide"]], "treated:lgb"), " & ",
  fmt_se(ddd_cross[["suicide_plan"]], "treated:lgb"), " & ",
  fmt_se(ddd_cross[["suicide_attempt"]], "treated:lgb"), " \\\\[6pt]")

# Panel B: Separate by identity
tab3_tex <- paste0(tab3_tex, "\n",
"\\multicolumn{5}{l}{\\textit{Panel B: LGB subsample}} \\\\[3pt]
Ban enacted & ", fmt_coef(lgb_cross[["sad_hopeless"]]), " & ",
  fmt_coef(lgb_cross[["considered_suicide"]]), " & ",
  fmt_coef(lgb_cross[["suicide_plan"]]), " & ",
  fmt_coef(lgb_cross[["suicide_attempt"]]), " \\\\
 & ", fmt_se(lgb_cross[["sad_hopeless"]]), " & ",
  fmt_se(lgb_cross[["considered_suicide"]]), " & ",
  fmt_se(lgb_cross[["suicide_plan"]]), " & ",
  fmt_se(lgb_cross[["suicide_attempt"]]), " \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel C: Heterosexual subsample}} \\\\[3pt]
Ban enacted & ", fmt_coef(het_cross[["sad_hopeless"]]), " & ",
  fmt_coef(het_cross[["considered_suicide"]]), " & ",
  fmt_coef(het_cross[["suicide_plan"]]), " & ",
  fmt_coef(het_cross[["suicide_attempt"]]), " \\\\
 & ", fmt_se(het_cross[["sad_hopeless"]]), " & ",
  fmt_se(het_cross[["considered_suicide"]]), " & ",
  fmt_se(het_cross[["suicide_plan"]]), " & ",
  fmt_se(het_cross[["suicide_attempt"]]), " \\\\[6pt]
\\hline
Year FE & Yes & Yes & Yes & Yes \\\\
Individual controls & Yes & Yes & Yes & Yes \\\\
Observations (Panel A) & \\multicolumn{4}{c}{", format(nrow(ddd_sample), big.mark = ","), "} \\\\
\\hline\\hline
\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Panel A reports the interaction of ban status with LGB identity, controlling for year fixed effects, sex, race, and grade. Panel B restricts to LGB-identified students; Panel C to heterosexual students. Standard errors clustered at the state level. Sample limited to 2021--2023 waves where the sexual identity question was asked. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.}
\\end{tabular}
\\end{table}")

writeLines(tab3_tex, file.path(tables_dir, "tab3_ddd.tex"))

# =============================================================================
# Table 4: Robustness Checks
# =============================================================================

cat("Generating Table 4: Robustness\n")

# Re-run the specifications from 04_robustness.R
# Drop early adopters
analysis_late <- analysis[!(state_abbr %in% c("CA", "NJ"))]
rob_late <- list()
for (y in outcomes) {
  fml <- as.formula(paste0(y, " ~ treated + female + i(race_clean) + i(grade_clean) | state_abbr + year"))
  rob_late[[y]] <- feols(fml, data = analysis_late, weights = ~weight, cluster = ~state_abbr, warn = FALSE)
}

# Placebo: bullying
rob_bully_school <- feols(bullied_school ~ treated + female + i(race_clean) + i(grade_clean) | state_abbr + year,
                          data = analysis, weights = ~weight, cluster = ~state_abbr, warn = FALSE)
rob_bully_elec <- feols(bullied_electronic ~ treated + female + i(race_clean) + i(grade_clean) | state_abbr + year,
                        data = analysis, weights = ~weight, cluster = ~state_abbr, warn = FALSE)

# CS aggregated ATTs
# Re-compute CS ATTs for Table 4
state_year <- readRDS(file.path(data_dir, "state_year.rds"))
cs_atts <- c()
for (y in outcomes) {
  sy_clean <- state_year[!is.na(get(y)) & is.finite(get(y))]
  tryCatch({
    cs_out <- att_gt(yname = y, tname = "year", idname = "state_id", gname = "cohort",
                     data = as.data.frame(sy_clean), control_group = "notyettreated",
                     base_period = "universal", est_method = "reg",
                     allow_unbalanced_panel = TRUE)
    cs_agg <- aggte(cs_out, type = "simple")
    cs_atts <- c(cs_atts, sprintf("%.4f", cs_agg$overall.att))
  }, error = function(e) {
    cs_atts <<- c(cs_atts, "---")
  })
}

tab4_tex <- paste0(
"\\begin{table}[t]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{tabular}{l*{4}{c}}
\\hline\\hline
 & Persistent & Considered & Suicide & Suicide \\\\
 & Sadness & Suicide & Plan & Attempt \\\\
\\hline
\\multicolumn{5}{l}{\\textit{A. Baseline (from Table \\ref{tab:main}, Panel B)}} \\\\[3pt]
Ban enacted & ", fmt_coef(did_results_controls[["sad_hopeless"]]), " & ",
  fmt_coef(did_results_controls[["considered_suicide"]]), " & ",
  fmt_coef(did_results_controls[["suicide_plan"]]), " & ",
  fmt_coef(did_results_controls[["suicide_attempt"]]), " \\\\
 & ", fmt_se(did_results_controls[["sad_hopeless"]]), " & ",
  fmt_se(did_results_controls[["considered_suicide"]]), " & ",
  fmt_se(did_results_controls[["suicide_plan"]]), " & ",
  fmt_se(did_results_controls[["suicide_attempt"]]), " \\\\[6pt]
\\multicolumn{5}{l}{\\textit{B. Callaway--Sant'Anna}} \\\\[3pt]
ATT & ", cs_atts[1], " & ", cs_atts[2], " & ", cs_atts[3], " & ", cs_atts[4], " \\\\[6pt]
\\multicolumn{5}{l}{\\textit{C. Drop early adopters (CA, NJ)}} \\\\[3pt]
Ban enacted & ", fmt_coef(rob_late[["sad_hopeless"]]), " & ",
  fmt_coef(rob_late[["considered_suicide"]]), " & ",
  fmt_coef(rob_late[["suicide_plan"]]), " & ",
  fmt_coef(rob_late[["suicide_attempt"]]), " \\\\
 & ", fmt_se(rob_late[["sad_hopeless"]]), " & ",
  fmt_se(rob_late[["considered_suicide"]]), " & ",
  fmt_se(rob_late[["suicide_plan"]]), " & ",
  fmt_se(rob_late[["suicide_attempt"]]), " \\\\[6pt]
\\multicolumn{5}{l}{\\textit{D. Placebo outcomes}} \\\\[3pt]
Bullied at school & \\multicolumn{4}{c}{", fmt_coef(rob_bully_school), "} \\\\
 & \\multicolumn{4}{c}{", fmt_se(rob_bully_school), "} \\\\
Electronic bullying & \\multicolumn{4}{c}{", fmt_coef(rob_bully_elec), "} \\\\
 & \\multicolumn{4}{c}{", fmt_se(rob_bully_elec), "} \\\\
\\hline\\hline
\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Panel A reproduces the baseline specification from Table \\ref{tab:main}. Panel B reports the aggregate ATT from the Callaway and Sant'Anna (2021) estimator using not-yet-treated states as controls. Panel C drops California and New Jersey (adopted bans in 2012--2013, with limited pre-treatment data). Panel D tests placebo outcomes that should not be directly affected by conversion therapy bans. All specifications include state and year fixed effects, individual controls, and state-clustered standard errors. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.}
\\end{tabular}
\\end{table}")

writeLines(tab4_tex, file.path(tables_dir, "tab4_robustness.tex"))

# =============================================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# =============================================================================

cat("Generating Table F1: Standardized Effect Sizes\n")

# Get coefficients and SDs
sde_data <- data.table(
  outcome = c("Persistent sadness", "Considered suicide",
              "Suicide plan", "Suicide attempt"),
  beta = sapply(did_results_controls[outcomes], function(x) coef(x)["treated"]),
  se_beta = sapply(did_results_controls[outcomes], function(x) se(x)["treated"]),
  sd_y = c(pre_means$sad_hopeless_sd, pre_means$considered_suicide_sd,
           pre_means$suicide_plan_sd, pre_means$suicide_attempt_sd)
)

# SDE = beta / SD(Y) for binary treatment
sde_data[, sde := beta / sd_y]
sde_data[, se_sde := se_beta / sd_y]

# Classify
sde_data[, classification := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  default = "Large positive"
)]

# --- Heterogeneous panel: LGB vs Heterosexual (2021-2023 cross-section) ---
lgb_pre_means <- readRDS(file.path(data_dir, "lgb_pre_means.rds"))

# LGB subsample means from untreated states
lgb_sds <- ddd_sample[treated == 0 & lgb == 1, .(
  sad_hopeless_sd = sd(sad_hopeless, na.rm = TRUE),
  considered_suicide_sd = sd(considered_suicide, na.rm = TRUE),
  suicide_plan_sd = sd(suicide_plan, na.rm = TRUE),
  suicide_attempt_sd = sd(suicide_attempt, na.rm = TRUE)
)]

het_sds <- ddd_sample[treated == 0 & lgb == 0, .(
  sad_hopeless_sd = sd(sad_hopeless, na.rm = TRUE),
  considered_suicide_sd = sd(considered_suicide, na.rm = TRUE),
  suicide_plan_sd = sd(suicide_plan, na.rm = TRUE),
  suicide_attempt_sd = sd(suicide_attempt, na.rm = TRUE)
)]

# LGB heterogeneity rows (suicide attempt — strongest DDD result)
lgb_b <- coef(lgb_cross[["suicide_attempt"]])["treated"]
lgb_se <- se(lgb_cross[["suicide_attempt"]])["treated"]
lgb_sd <- lgb_sds$suicide_attempt_sd

het_b <- coef(het_cross[["suicide_attempt"]])["treated"]
het_se <- se(het_cross[["suicide_attempt"]])["treated"]
het_sd <- het_sds$suicide_attempt_sd

het_sde_data <- data.table(
  outcome = c("Suicide attempt (LGB)", "Suicide attempt (Heterosexual)"),
  beta = c(lgb_b, het_b),
  se_beta = c(lgb_se, het_se),
  sd_y = c(lgb_sd, het_sd)
)
het_sde_data[, sde := beta / sd_y]
het_sde_data[, se_sde := se_beta / sd_y]
het_sde_data[, classification := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  default = "Large positive"
)]

# Build LaTeX table
sde_rows <- ""
for (i in 1:nrow(sde_data)) {
  r <- sde_data[i]
  sde_rows <- paste0(sde_rows,
    r$outcome, " & ",
    sprintf("%.4f", r$beta), " & ",
    sprintf("%.4f", r$se_beta), " & ",
    sprintf("%.3f", r$sd_y), " & ",
    sprintf("%.3f", r$sde), " & ",
    sprintf("%.3f", r$se_sde), " & ",
    r$classification, " \\\\\n")
}

het_rows <- ""
for (i in 1:nrow(het_sde_data)) {
  r <- het_sde_data[i]
  het_rows <- paste0(het_rows,
    r$outcome, " & ",
    sprintf("%.4f", r$beta), " & ",
    sprintf("%.4f", r$se_beta), " & ",
    sprintf("%.3f", r$sd_y), " & ",
    sprintf("%.3f", r$sde), " & ",
    sprintf("%.3f", r$se_sde), " & ",
    r$classification, " \\\\\n")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state laws banning licensed professionals from performing conversion therapy (SOGIECE) on minors reduce adolescent mental health distress? ",
  "\\textbf{Policy mechanism:} Conversion therapy bans prohibit licensed mental health professionals from attempting to change a minor's sexual orientation or gender identity, directly protecting youth from a harmful practice and signaling legislative recognition that such practices are damaging. ",
  "\\textbf{Outcome definition:} Binary indicators from the CDC Youth Risk Behavior Survey for persistent sadness/hopelessness (felt sad or hopeless almost every day for two or more weeks in a row during the past 12 months), suicidal ideation (seriously considered attempting suicide), suicide planning (made a plan about how they would attempt suicide), and suicide attempts (actually attempted suicide on one or more occasions). ",
  "\\textbf{Treatment:} Binary; equals one if the student's state had enacted a conversion therapy ban effective before or during the YRBSS survey year. ",
  "\\textbf{Data:} CDC Youth Risk Behavior Survey (YRBSS) State and District Combined (SADC) datasets, 2015--2023 (five biennial waves), individual student-level observations, $N = 743{,}593$ across 39 states. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with state and year fixed effects, individual controls (sex, race, grade), standard errors clustered at the state level, survey weights applied. ",
  "\\textbf{Sample:} High school students (grades 9--12) in states participating in the YRBSS; Panel B restricts to 2021--2023 waves where the sexual identity question was administered. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($\\lvert\\text{SDE}\\rvert > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
"\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled (all students, 2015--2023)}} \\\\[3pt]
", sde_rows,
"\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by sexual identity, 2021--2023)}} \\\\[3pt]
", het_rows,
"\\hline\\hline
\\end{tabular}
\\end{adjustbox}
\\begin{itemize}[leftmargin=*,nosep]
", sde_notes, "
\\end{itemize}
\\end{table}")

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
