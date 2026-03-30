# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
state_panel <- readRDS("../data/state_panel.rds")
county_panel <- readRDS("../data/county_panel.rds")
state_exposure <- readRDS("../data/state_exposure.rds")
county_exposure <- readRDS("../data/county_exposure.rds")
steel_ppi <- readRDS("../data/steel_ppi.rds")

dir.create("../tables", showWarnings = FALSE)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics\n")

# State panel summary by education
summ_by_edu <- state_panel %>%
  group_by(edu_label) %>%
  summarise(
    mean_emp = mean(emp, na.rm = TRUE),
    sd_emp = sd(emp, na.rm = TRUE),
    mean_earn = mean(earn_beg, na.rm = TRUE),
    sd_earn = sd(earn_beg, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )

# Overall summary
summ_overall <- state_panel %>%
  summarise(
    mean_emp = mean(emp, na.rm = TRUE),
    sd_emp = sd(emp, na.rm = TRUE),
    mean_earn = mean(earn_beg, na.rm = TRUE),
    sd_earn = sd(earn_beg, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    n_obs = n()
  ) %>%
  mutate(edu_label = "All workers")

summ_all <- bind_rows(summ_overall, summ_by_edu) %>%
  mutate(
    edu_label = factor(edu_label,
      levels = c("All workers", "Less than HS", "HS diploma",
                 "Some college", "Bachelor's+"))
  ) %>%
  arrange(edu_label)

# Exposure summary
exp_summ <- state_exposure %>%
  summarise(
    mean_exp = mean(exposure, na.rm = TRUE),
    sd_exp = sd(exposure, na.rm = TRUE),
    min_exp = min(exposure, na.rm = TRUE),
    max_exp = max(exposure, na.rm = TRUE),
    p25 = quantile(exposure, 0.25, na.rm = TRUE),
    p75 = quantile(exposure, 0.75, na.rm = TRUE),
    n_states = n()
  )

# Write Table 1
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Downstream Steel-Using Manufacturing}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Earnings (\\$/qtr)} & \\multicolumn{2}{c}{Separation Rate} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Education Group & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ_all)) {
  r <- summ_all[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    r$edu_label,
    format(round(r$mean_emp), big.mark = ","),
    format(round(r$sd_emp), big.mark = ","),
    format(round(r$mean_earn), big.mark = ","),
    format(round(r$sd_earn), big.mark = ","),
    sprintf("%.3f", r$mean_sep_rate),
    sprintf("%.3f", r$sd_sep_rate)
  ))
  if (i == 1) tab1_lines <- c(tab1_lines, "\\midrule")
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("\\multicolumn{7}{l}{\\textit{Downstream exposure:} Mean = %.3f, SD = %.3f, Min = %.3f, Max = %.3f} \\\\",
          exp_summ$mean_exp, exp_summ$sd_exp, exp_summ$min_exp, exp_summ$max_exp),
  sprintf("\\multicolumn{7}{l}{\\textit{Panel:} %s states, %s quarters (2013Q1--2019Q4), %s state-education-quarter obs} \\\\",
          n_distinct(state_panel$state_fips),
          n_distinct(state_panel$time_id),
          format(nrow(state_panel), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\textit{Notes:} Panel of state $\\times$ education group $\\times$ quarter observations for downstream steel-using manufacturing (NAICS 332, 333, 336). Employment and earnings are from the QWI. Downstream exposure is the state's 2016Q1 share of manufacturing employment in steel-using industries. Separation rate is quarterly separations divided by beginning-of-quarter employment.",
  "}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# =============================================================================
# Table 2: Main DDD Results (State Level)
# =============================================================================
cat("Generating Table 2: Main DDD Results\n")

# Extract coefficients and SEs from models
extract_coefs <- function(model, coef_names) {
  ct <- coeftable(model)
  sapply(coef_names, function(cn) {
    if (cn %in% rownames(ct)) {
      list(est = ct[cn, "Estimate"], se = ct[cn, "Std. Error"],
           pval = ct[cn, "Pr(>|t|)"])
    } else {
      list(est = NA, se = NA, pval = NA)
    }
  }, simplify = FALSE)
}

stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.10) return("$^{*}$")
  return("")
}

# Models to include: state DDD (emp, sep, earn) and county DDD (emp)
models_list <- list(results$m1_emp, results$m1_sep, results$m1_earn,
                    results$m3_emp, results$m3_sep, results$m3_earn)
dep_vars <- c("Log Emp", "Sep Rate", "Log Earn",
              "Log Emp", "Sep Rate", "Log Earn")
geo_level <- c(rep("State", 3), rep("County", 3))

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Triple-Difference Estimates: Section 232 Tariff Effects on Downstream Manufacturing}",
  "\\label{tab:main_ddd}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{State Level} & \\multicolumn{3}{c}{County Level} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  paste0(" & ", paste(dep_vars, collapse = " & "), " \\\\"),
  paste0(" & ", paste(paste0("(", 1:6, ")"), collapse = " & "), " \\\\"),
  "\\midrule"
)

# Row: Exposure × Post
row_exp <- " Exposure $\\times$ Post"
for (m in models_list) {
  ct <- coeftable(m)
  cn <- "exposure_post"
  if (cn %in% rownames(ct)) {
    est <- ct[cn, "Estimate"]
    se <- ct[cn, "Std. Error"]
    pv <- ct[cn, "Pr(>|t|)"]
    row_exp <- paste0(row_exp, sprintf(" & %s%s", sprintf("%.4f", est), stars(pv)))
  } else {
    row_exp <- paste0(row_exp, " & ")
  }
}
row_exp <- paste0(row_exp, " \\\\")

row_exp_se <- " "
for (m in models_list) {
  ct <- coeftable(m)
  cn <- "exposure_post"
  if (cn %in% rownames(ct)) {
    se <- ct[cn, "Std. Error"]
    row_exp_se <- paste0(row_exp_se, sprintf(" & (%s)", sprintf("%.4f", se)))
  } else {
    row_exp_se <- paste0(row_exp_se, " & ")
  }
}
row_exp_se <- paste0(row_exp_se, " \\\\[3pt]")

# Row: Exposure × Post × High Edu
row_int <- " Exposure $\\times$ Post $\\times$ High Edu"
for (m in models_list) {
  ct <- coeftable(m)
  cn <- "exposure_post_highedu"
  if (cn %in% rownames(ct)) {
    est <- ct[cn, "Estimate"]
    pv <- ct[cn, "Pr(>|t|)"]
    row_int <- paste0(row_int, sprintf(" & %s%s", sprintf("%.4f", est), stars(pv)))
  } else {
    row_int <- paste0(row_int, " & ")
  }
}
row_int <- paste0(row_int, " \\\\")

row_int_se <- " "
for (m in models_list) {
  ct <- coeftable(m)
  cn <- "exposure_post_highedu"
  if (cn %in% rownames(ct)) {
    se <- ct[cn, "Std. Error"]
    row_int_se <- paste0(row_int_se, sprintf(" & (%s)", sprintf("%.4f", se)))
  } else {
    row_int_se <- paste0(row_int_se, " & ")
  }
}
row_int_se <- paste0(row_int_se, " \\\\")

# Fixed effects row
fe_row <- " FE: Geo$\\times$Edu, Edu$\\times$Time, Geo$\\times$Time & \\checkmark & \\checkmark & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\"

# N and clusters
n_row <- paste0(" Observations",
  paste0(sapply(models_list, function(m) sprintf(" & %s", format(m$nobs, big.mark = ","))), collapse = ""),
  " \\\\")

tab2_lines <- c(tab2_lines,
  row_exp, row_exp_se, row_int, row_int_se,
  "\\midrule",
  fe_row,
  n_row,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Triple-difference estimates of Section 232 steel/aluminum tariff effects on downstream manufacturing (NAICS 332, 333, 336). Exposure is the state (or county) share of manufacturing employment in downstream steel-using industries measured in 2016Q1. Post = 1 for quarters $\\geq$ 2018Q2. High Edu = 1 for workers with some college or bachelor's degree. All specifications include geographic-unit $\\times$ education, education $\\times$ time, and geographic-unit $\\times$ time fixed effects. Standard errors clustered at the state level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main_ddd.tex")

# =============================================================================
# Table 3: Education-Specific Effects
# =============================================================================
cat("Generating Table 3: Education-Specific Effects\n")

edu_coefs <- c("exp_post_E1", "exp_post_E2", "exp_post_E3", "exp_post_E4")
edu_labels <- c("Less than HS", "HS diploma", "Some college", "Bachelor's+")

models_edu <- list(results$m2_emp, results$m2_sep, results$m2_earn)
dep_edu <- c("Log Emp", "Sep Rate", "Log Earn")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Education-Specific Tariff Effects on Downstream Manufacturing}",
  "\\label{tab:edu_specific}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  paste0(" & ", paste(dep_edu, collapse = " & "), " \\\\"),
  paste0(" & ", paste(paste0("(", 1:3, ")"), collapse = " & "), " \\\\"),
  "\\midrule"
)

for (j in seq_along(edu_coefs)) {
  row_est <- sprintf(" Exposure $\\times$ Post $\\times$ %s", edu_labels[j])
  row_se <- " "
  for (m in models_edu) {
    ct <- coeftable(m)
    cn <- edu_coefs[j]
    if (cn %in% rownames(ct)) {
      est <- ct[cn, "Estimate"]
      se <- ct[cn, "Std. Error"]
      pv <- ct[cn, "Pr(>|t|)"]
      row_est <- paste0(row_est, sprintf(" & %s%s", sprintf("%.4f", est), stars(pv)))
      row_se <- paste0(row_se, sprintf(" & (%s)", sprintf("%.4f", se)))
    } else {
      row_est <- paste0(row_est, " & ")
      row_se <- paste0(row_se, " & ")
    }
  }
  spacing <- if (j < length(edu_coefs)) "[3pt]" else ""
  tab3_lines <- c(tab3_lines, paste0(row_est, " \\\\"), paste0(row_se, " \\\\", spacing))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  " FE: State$\\times$Edu, Edu$\\times$Time, State$\\times$Time & \\checkmark & \\checkmark & \\checkmark \\\\",
  sprintf(" Observations & %s & %s & %s \\\\",
    format(results$m2_emp$nobs, big.mark = ","),
    format(results$m2_sep$nobs, big.mark = ","),
    format(results$m2_earn$nobs, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Education-group-specific effects of downstream steel exposure after Section 232 tariffs. Each coefficient is the interaction of continuous state-level downstream exposure with a post-tariff indicator and the education group indicator. The omitted base is absorbed by fixed effects. Standard errors clustered at the state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_edu_specific.tex")

# =============================================================================
# Table 4: Robustness Checks
# =============================================================================
cat("Generating Table 4: Robustness\n")

rob_models <- list(
  results$m1_emp,       # (1) Baseline state
  robust$r2_drop_2019h2, # (2) Drop 2019H2
  robust$r4_binary,     # (3) Binary exposure
  robust$r3_placebo,    # (4) Placebo: non-downstream
  robust$r1_county_cluster # (5) County clustering
)

rob_labels <- c("Baseline", "Drop 2019H2", "Binary Exp.",
                "Placebo: Non-DS", "County Clust.")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste0(" & ", paste(rob_labels, collapse = " & "), " \\\\"),
  paste0(" & ", paste(paste0("(", 1:5, ")"), collapse = " & "), " \\\\"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Dependent variable: Log employment}} \\\\[3pt]"
)

# Exposure × Post row
coef_names_main <- c("exposure_post", "exposure_post", "high_exp_post",
                     "exposure_post", "exposure_post")
row_main <- " Exposure $\\times$ Post"
row_main_se <- " "
for (k in seq_along(rob_models)) {
  ct <- coeftable(rob_models[[k]])
  cn <- coef_names_main[k]
  if (cn %in% rownames(ct)) {
    est <- ct[cn, "Estimate"]
    se <- ct[cn, "Std. Error"]
    pv <- ct[cn, "Pr(>|t|)"]
    row_main <- paste0(row_main, sprintf(" & %s%s", sprintf("%.4f", est), stars(pv)))
    row_main_se <- paste0(row_main_se, sprintf(" & (%s)", sprintf("%.4f", se)))
  } else {
    row_main <- paste0(row_main, " & ")
    row_main_se <- paste0(row_main_se, " & ")
  }
}

# Interaction row
coef_names_int <- c("exposure_post_highedu", "exposure_post_highedu",
                    "high_exp_post_highedu", "exposure_post_highedu",
                    "exposure_post_highedu")
row_int <- " Exp $\\times$ Post $\\times$ High Edu"
row_int_se <- " "
for (k in seq_along(rob_models)) {
  ct <- coeftable(rob_models[[k]])
  cn <- coef_names_int[k]
  if (cn %in% rownames(ct)) {
    est <- ct[cn, "Estimate"]
    se <- ct[cn, "Std. Error"]
    pv <- ct[cn, "Pr(>|t|)"]
    row_int <- paste0(row_int, sprintf(" & %s%s", sprintf("%.4f", est), stars(pv)))
    row_int_se <- paste0(row_int_se, sprintf(" & (%s)", sprintf("%.4f", se)))
  } else {
    row_int <- paste0(row_int, " & ")
    row_int_se <- paste0(row_int_se, " & ")
  }
}

n_row <- paste0(" Observations",
  paste0(sapply(rob_models, function(m) sprintf(" & %s", format(m$nobs, big.mark = ","))), collapse = ""),
  " \\\\")

tab4_lines <- c(tab4_lines,
  paste0(row_main, " \\\\"), paste0(row_main_se, " \\\\[3pt]"),
  paste0(row_int, " \\\\"), paste0(row_int_se, " \\\\"),
  "\\midrule",
  n_row,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Robustness checks for the triple-difference specification. Column (1) reproduces the baseline state-level estimate. Column (2) drops 2019Q3--Q4 to exclude trade war escalation. Column (3) uses binary exposure (above/below median). Column (4) runs the placebo on non-downstream manufacturing industries. Column (5) uses county-level data with county-clustered standard errors. All specifications include three-way fixed effects. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE Appendix)
# =============================================================================
cat("Generating Table F1: SDE\n")

# In the DDD design, exposure_post is absorbed by geo×time FE.
# The surviving coefficient is exposure_post_highedu (the DDD interaction).
# This IS the main estimand: the differential tariff effect on high- vs low-edu workers.

# Pre-treatment SD of outcomes
pre_stats <- state_panel %>%
  filter(post == 0) %>%
  summarise(
    sd_log_emp = sd(log_emp, na.rm = TRUE),
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    sd_log_earn = sd(log_earn, na.rm = TRUE)
  )

sd_exposure <- sd(state_exposure$exposure, na.rm = TRUE)

# Use county-level results (preferred specification) for SDE
ct_emp_c <- coeftable(results$m3_emp)
ct_sep_c <- coeftable(results$m3_sep)
ct_earn_c <- coeftable(results$m3_earn)

# Pre-treatment SDs from county panel
pre_stats_county <- county_panel %>%
  filter(post == 0) %>%
  summarise(
    sd_log_emp = sd(log_emp, na.rm = TRUE),
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    sd_log_earn = sd(log_earn, na.rm = TRUE)
  )

sd_exposure_county <- sd(county_exposure$exposure, na.rm = TRUE)

compute_sde <- function(beta, se, sd_x, sd_y) {
  sde <- beta * sd_x / sd_y
  sde_se <- se * sd_x / sd_y
  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  list(sde = sde, sde_se = sde_se, bucket = bucket)
}

# Panel A: Pooled DDD interaction (exposure × post × high_edu)
sde_rows_pooled <- list()

cn <- "exposure_post_highedu"

# Employment
sde_emp <- compute_sde(ct_emp_c[cn, "Estimate"], ct_emp_c[cn, "Std. Error"],
                        sd_exposure_county, pre_stats_county$sd_log_emp)
sde_rows_pooled$emp <- list(
  outcome = "Log employment (DDD)",
  beta = ct_emp_c[cn, "Estimate"],
  se = ct_emp_c[cn, "Std. Error"],
  sd_y = pre_stats_county$sd_log_emp,
  sde = sde_emp$sde, sde_se = sde_emp$sde_se, bucket = sde_emp$bucket
)

# Separation rate
sde_sep <- compute_sde(ct_sep_c[cn, "Estimate"], ct_sep_c[cn, "Std. Error"],
                        sd_exposure_county, pre_stats_county$sd_sep_rate)
sde_rows_pooled$sep <- list(
  outcome = "Separation rate (DDD)",
  beta = ct_sep_c[cn, "Estimate"],
  se = ct_sep_c[cn, "Std. Error"],
  sd_y = pre_stats_county$sd_sep_rate,
  sde = sde_sep$sde, sde_se = sde_sep$sde_se, bucket = sde_sep$bucket
)

# Earnings
sde_earn <- compute_sde(ct_earn_c[cn, "Estimate"], ct_earn_c[cn, "Std. Error"],
                         sd_exposure_county, pre_stats_county$sd_log_earn)
sde_rows_pooled$earn <- list(
  outcome = "Log earnings (DDD)",
  beta = ct_earn_c[cn, "Estimate"],
  se = ct_earn_c[cn, "Std. Error"],
  sd_y = pre_stats_county$sd_log_earn,
  sde = sde_earn$sde, sde_se = sde_earn$sde_se, bucket = sde_earn$bucket
)

# Panel B: Heterogeneous — E1 vs E2 (education-specific from county model)
ct_m4 <- coeftable(results$m4_emp)

pre_E1 <- county_panel %>% filter(post == 0, education == "E1") %>%
  summarise(sd_y = sd(log_emp, na.rm = TRUE))
pre_E2 <- county_panel %>% filter(post == 0, education == "E2") %>%
  summarise(sd_y = sd(log_emp, na.rm = TRUE))

sde_rows_het <- list()

sde_e1 <- compute_sde(ct_m4["exp_post_E1", "Estimate"], ct_m4["exp_post_E1", "Std. Error"],
                       sd_exposure_county, pre_E1$sd_y)
sde_rows_het$e1 <- list(
  outcome = "Log emp (Less than HS, rel. to BA+)",
  beta = ct_m4["exp_post_E1", "Estimate"],
  se = ct_m4["exp_post_E1", "Std. Error"],
  sd_y = pre_E1$sd_y,
  sde = sde_e1$sde, sde_se = sde_e1$sde_se, bucket = sde_e1$bucket
)

sde_e2 <- compute_sde(ct_m4["exp_post_E2", "Estimate"], ct_m4["exp_post_E2", "Std. Error"],
                       sd_exposure_county, pre_E2$sd_y)
sde_rows_het$e2 <- list(
  outcome = "Log emp (HS diploma, rel. to BA+)",
  beta = ct_m4["exp_post_E2", "Estimate"],
  se = ct_m4["exp_post_E2", "Std. Error"],
  sd_y = pre_E2$sd_y,
  sde = sde_e2$sde, sde_se = sde_e2$sde_se, bucket = sde_e2$bucket
)

# Write SDE table
sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do Section 232 steel and aluminum tariffs impose downstream employment costs that fall disproportionately on higher-educated workers in manufacturing? ",
  "\\textbf{Policy mechanism:} Section 232 tariffs (25\\% steel, 10\\% aluminum, effective March 2018) raise input costs for downstream manufacturers in fabricated metals, machinery, and transportation equipment, potentially reducing employment through higher production costs and reduced competitiveness. ",
  "\\textbf{Outcome definition:} Log quarterly employment from the QWI, measuring beginning-of-quarter headcount in downstream steel-using manufacturing industries (NAICS 332, 333, 336). ",
  "\\textbf{Treatment:} Continuous --- state-level share of manufacturing employment in downstream steel-using industries, measured in 2016Q1 as pre-treatment exposure intensity. ",
  "\\textbf{Data:} Quarterly Workforce Indicators (QWI) by state, education group, and 3-digit NAICS industry, 2013Q1--2019Q4, with approximately ",
  format(nrow(state_panel), big.mark = ","), " state-education-quarter observations across ",
  n_distinct(state_panel$state_fips), " states. ",
  "\\textbf{Method:} Triple-difference (state $\\times$ education $\\times$ time) with state-education, education-time, and state-time fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} States with at least 100 total manufacturing workers in 2016Q1; education groups E1 (less than HS) through E4 (bachelor's or higher); pre-COVID sample ending 2019Q4. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-state standard deviation of downstream exposure and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (r in sde_rows_pooled) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    r$outcome,
    sprintf("%.4f", r$beta), sprintf("%.4f", r$se),
    sprintf("%.3f", r$sd_y),
    sprintf("%.4f", r$sde), sprintf("%.4f", r$sde_se),
    r$bucket
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (employment by education)}} \\\\"
)

for (r in sde_rows_het) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    r$outcome,
    sprintf("%.4f", r$beta), sprintf("%.4f", r$se),
    sprintf("%.3f", r$sd_y),
    sprintf("%.4f", r$sde), sprintf("%.4f", r$sde_se),
    r$bucket
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  paste0("{\\footnotesize ", sde_notes, "}"),
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
