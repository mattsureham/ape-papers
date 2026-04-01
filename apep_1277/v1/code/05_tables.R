# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# Minimum Wages and the Racial Hiring Gap (apep_1277)
# =============================================================================

source("00_packages.R")
data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

# Load results
sumstats <- readRDS(paste0(data_dir, "summary_stats.rds"))
sumstats_prepost <- readRDS(paste0(data_dir, "summary_prepost.rds"))
cs_results <- readRDS(paste0(data_dir, "cs_results.rds"))
event_study <- readRDS(paste0(data_dir, "event_study.rds"))
reg_results <- readRDS(paste0(data_dir, "regression_results.rds"))
rob_results <- readRDS(paste0(data_dir, "robustness_results.rds"))
diagnostics <- jsonlite::fromJSON(paste0(data_dir, "diagnostics.json"))
analysis_state <- readRDS(paste0(data_dir, "analysis_state.rds"))
analysis_industry <- readRDS(paste0(data_dir, "analysis_industry.rds"))

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, big.mark = ",")
fmt0 <- function(x) formatC(x, format = "d", big.mark = ",")
stars <- function(p) ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics...\n")

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: QWI Race-Ethnicity Panel, 2005--2023}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{White Workers} & \\multicolumn{2}{c}{Black Workers} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n"
)

sw <- sumstats %>% filter(race == "A1")
sb <- sumstats %>% filter(race == "A2")

tab1 <- paste0(tab1,
  sprintf("Quarterly hires & %s & %s & %s & %s \\\\\n",
          fmt0(sw$mean_hires), fmt0(sw$sd_hires), fmt0(sb$mean_hires), fmt0(sb$sd_hires)),
  sprintf("Quarterly employment & %s & %s & %s & %s \\\\\n",
          fmt0(sw$mean_emp), fmt0(sw$sd_emp), fmt0(sb$mean_emp), fmt0(sb$sd_emp)),
  sprintf("Avg.\\ quarterly earnings (\\$) & %s & %s & %s & %s \\\\\n",
          fmt0(sw$mean_earnings), fmt0(sw$sd_earnings), fmt0(sb$mean_earnings), fmt0(sb$sd_earnings)),
  sprintf("\\hline\nObservations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          fmt0(sw$n_obs), fmt0(sb$n_obs)),
  sprintf("States & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          sw$n_states, sb$n_states),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Unit of observation is state $\\times$ quarter. ",
  "Data from the Census Bureau Quarterly Workforce Indicators (QWI) race-ethnicity panel, ",
  "aggregated across all industries. Hires (accessions) measure workers who began a new job ",
  "at a firm during the quarter. Earnings are average quarterly stable employment earnings.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, paste0(tables_dir, "tab1_sumstats.tex"))

# =============================================================================
# Table 2: Callaway-Sant'Anna Event Study Results
# =============================================================================
cat("Generating Table 2: CS Event Study...\n")

# Extract event study coefficients for key periods
es_periods <- c(-8, -6, -4, -2, -1, 0, 1, 2, 4, 6, 8)

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Minimum Wage Effects on Hiring by Race: Callaway-Sant'Anna Event Study}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & White & Black & Difference \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Pre-treatment (quarters relative to MW increase)}} \\\\\n"
)

for (e in c(-8, -6, -4, -2)) {
  w <- event_study %>% filter(race == "White", event_time == e)
  b <- event_study %>% filter(race == "Black", event_time == e)
  if (nrow(w) > 0 && nrow(b) > 0) {
    diff <- b$att - w$att
    diff_se <- sqrt(w$se^2 + b$se^2)
    diff_p <- 2 * pnorm(-abs(diff / diff_se))
    w_p <- 2 * pnorm(-abs(w$att / w$se))
    b_p <- 2 * pnorm(-abs(b$att / b$se))
    tab2 <- paste0(tab2,
      sprintf("$t = %d$ & $%s%s$ & $%s%s$ & $%s%s$ \\\\\n",
              e, fmt(w$att, 4), stars(w_p), fmt(b$att, 4), stars(b_p), fmt(diff, 4), stars(diff_p)),
      sprintf(" & (%s) & (%s) & (%s) \\\\\n", fmt(w$se, 4), fmt(b$se, 4), fmt(diff_se, 4))
    )
  }
}

tab2 <- paste0(tab2,
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Post-treatment}} \\\\\n"
)

for (e in c(0, 2, 4, 6, 8)) {
  w <- event_study %>% filter(race == "White", event_time == e)
  b <- event_study %>% filter(race == "Black", event_time == e)
  if (nrow(w) > 0 && nrow(b) > 0) {
    diff <- b$att - w$att
    diff_se <- sqrt(w$se^2 + b$se^2)
    diff_p <- 2 * pnorm(-abs(diff / diff_se))
    w_p <- 2 * pnorm(-abs(w$att / w$se))
    b_p <- 2 * pnorm(-abs(b$att / b$se))
    tab2 <- paste0(tab2,
      sprintf("$t = +%d$ & $%s%s$ & $%s%s$ & $%s%s$ \\\\\n",
              e, fmt(w$att, 4), stars(w_p), fmt(b$att, 4), stars(b_p), fmt(diff, 4), stars(diff_p)),
      sprintf(" & (%s) & (%s) & (%s) \\\\\n", fmt(w$se, 4), fmt(b$se, 4), fmt(diff_se, 4))
    )
  }
}

tab2 <- paste0(tab2,
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Aggregated ATT}} \\\\\n",
  sprintf("Overall & $%s%s$ & $%s%s$ & $%s%s$ \\\\\n",
          fmt(cs_results$white$att_overall$overall.att, 4),
          stars(2 * pnorm(-abs(cs_results$white$att_overall$overall.att / cs_results$white$att_overall$overall.se))),
          fmt(cs_results$black$att_overall$overall.att, 4),
          stars(2 * pnorm(-abs(cs_results$black$att_overall$overall.att / cs_results$black$att_overall$overall.se))),
          fmt(cs_results$black$att_overall$overall.att - cs_results$white$att_overall$overall.att, 4),
          stars(2 * pnorm(-abs(
            (cs_results$black$att_overall$overall.att - cs_results$white$att_overall$overall.att) /
            sqrt(cs_results$white$att_overall$overall.se^2 + cs_results$black$att_overall$overall.se^2)
          )))),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          fmt(cs_results$white$att_overall$overall.se, 4),
          fmt(cs_results$black$att_overall$overall.se, 4),
          fmt(sqrt(cs_results$white$att_overall$overall.se^2 + cs_results$black$att_overall$overall.se^2), 4)),
  "\\hline\n",
  sprintf("Treated states & %d & %d & \\\\\n",
          cs_results$white$n_treated, cs_results$black$n_treated),
  sprintf("Never-treated states & %d & %d & \\\\\n",
          cs_results$white$n_never, cs_results$black$n_never),
  sprintf("Observations & %s & %s & \\\\\n",
          fmt0(diagnostics$n_obs / 2), fmt0(diagnostics$n_obs / 2)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATT estimates for log quarterly hires. ",
  "Treatment is defined as the first quarter a state's minimum wage exceeds the federal minimum (\\$7.25). ",
  "Control group: not-yet-treated states. Event time in quarters relative to treatment. ",
  "Column (3) reports the Black--White difference with standard errors computed under independence. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, paste0(tables_dir, "tab2_event_study.tex"))

# =============================================================================
# Table 3: DDD Main Results
# =============================================================================
cat("Generating Table 3: DDD Results...\n")

# Extract coefficients from DDD models
get_coefs <- function(model, label) {
  ct <- coeftable(model)
  data.frame(
    variable = rownames(ct),
    coef = ct[, "Estimate"],
    se = ct[, "Std. Error"],
    pval = ct[, "Pr(>|t|)"],
    model = label,
    stringsAsFactors = FALSE
  )
}

ddd_coefs <- get_coefs(reg_results$ddd_main, "DDD (binary bite)")
kaitz_coefs <- get_coefs(reg_results$ddd_kaitz, "DDD (Kaitz)")
overall_coefs <- get_coefs(reg_results$did_overall, "Overall DiD")

# Build table
tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{The Racial Hiring Gap and Minimum Wage Bite: County-Level DDD}\n",
  "\\label{tab:ddd}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Overall DiD & DDD (Binary) & DDD (Kaitz) \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n"
)

# Row helper
add_row <- function(tab, label, models, varname) {
  cells <- ""
  for (m in models) {
    row <- m[grepl(varname, m$variable, fixed = TRUE), ]
    if (nrow(row) > 0) {
      row <- row[1, ]
      cells <- paste0(cells, sprintf(" & $%s%s$", fmt(row$coef, 4), stars(row$pval)))
    } else {
      cells <- paste0(cells, " & ")
    }
  }
  se_cells <- ""
  for (m in models) {
    row <- m[grepl(varname, m$variable, fixed = TRUE), ]
    if (nrow(row) > 0) {
      row <- row[1, ]
      se_cells <- paste0(se_cells, sprintf(" & (%s)", fmt(row$se, 4)))
    } else {
      se_cells <- paste0(se_cells, " & ")
    }
  }
  paste0(tab, label, cells, " \\\\\n", se_cells, " \\\\\n")
}

models_list <- list(overall_coefs, ddd_coefs, kaitz_coefs)

tab3 <- add_row(tab3, "Post $\\times$ High bite", models_list, "post:high_bite")
tab3 <- add_row(tab3, "Black $\\times$ Post", models_list, "black:post")
tab3 <- add_row(tab3, "Black $\\times$ Post $\\times$ High bite", models_list, "black:post:high_bite")
tab3 <- add_row(tab3, "Post $\\times$ Kaitz", models_list, "post:kaitz")
tab3 <- add_row(tab3, "Black $\\times$ Post $\\times$ Kaitz", models_list, "black:post:kaitz")

tab3 <- paste0(tab3,
  "\\hline\n",
  sprintf("County $\\times$ race FE & Yes & Yes & Yes \\\\\n"),
  sprintf("Quarter FE & Yes & Yes & Yes \\\\\n"),
  sprintf("Clustering & State & State & State \\\\\n"),
  sprintf("Observations & %s & %s & %s \\\\\n",
          fmt0(nobs(reg_results$did_overall)),
          fmt0(nobs(reg_results$ddd_main)),
          fmt0(nobs(reg_results$ddd_kaitz))),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log quarterly hires (accessions) from QWI. ",
  "Column (1) estimates the overall effect of MW bite on hiring. ",
  "Columns (2)--(3) add the Black $\\times$ Post $\\times$ Bite triple interaction: the racial differential in hiring response to MW increases. ",
  "High bite = county in the bottom tercile of pre-period average earnings (highest MW-to-wage ratio). ",
  "Kaitz = state MW / (county pre-period average hourly wage). ",
  "Standard errors clustered at the state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, paste0(tables_dir, "tab3_ddd.tex"))

# =============================================================================
# Table 4: Robustness
# =============================================================================
cat("Generating Table 4: Robustness...\n")

rob_placebo <- get_coefs(rob_results$placebo, "Placebo")
rob_emp <- get_coefs(rob_results$emp_ddd, "Employment")

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Main & Placebo & Employment \\\\\n",
  " & (Retail/Food) & (Prof./Finance) & (DDD) \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n"
)

# Low-wage result
lw <- get_coefs(reg_results$ind_lowwage, "Low-wage")
lw_row <- lw[grepl("black:post|post:black", lw$variable), ]
if (nrow(lw_row) > 0) {
  lw_row <- lw_row[1, ]
  tab4 <- paste0(tab4,
    sprintf("Black $\\times$ Post & $%s%s$ & & \\\\\n", fmt(lw_row$coef, 4), stars(lw_row$pval)),
    sprintf(" & (%s) & & \\\\\n", fmt(lw_row$se, 4))
  )
}

# Placebo high-wage
pl_row <- rob_placebo[grepl("black:post|post:black", rob_placebo$variable), ]
if (nrow(pl_row) > 0) {
  pl_row <- pl_row[1, ]
  tab4 <- paste0(tab4,
    sprintf("Black $\\times$ Post & & $%s%s$ & \\\\\n", fmt(pl_row$coef, 4), stars(pl_row$pval)),
    sprintf(" & & (%s) & \\\\\n", fmt(pl_row$se, 4))
  )
}

# Employment DDD
emp_row <- rob_emp[grepl("black.*post.*high_bite|high_bite.*post.*black", rob_emp$variable), ]
if (nrow(emp_row) > 0) {
  emp_row <- emp_row[1, ]
  tab4 <- paste0(tab4,
    sprintf("Black $\\times$ Post $\\times$ High bite & & & $%s%s$ \\\\\n",
            fmt(emp_row$coef, 4), stars(emp_row$pval)),
    sprintf(" & & & (%s) \\\\\n", fmt(emp_row$se, 4))
  )
}

tab4 <- paste0(tab4,
  "\\hline\n",
  sprintf("Leave-one-out range & & & [%s, %s] \\\\\n",
          fmt(min(rob_results$loo$coef), 4), fmt(max(rob_results$loo$coef), 4)),
  "Fixed effects & State$\\times$Race & State$\\times$Race & County$\\times$Race \\\\\n",
  "Quarter FE & Yes & Yes & Yes \\\\\n",
  "Clustering & State & State & State \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          fmt0(nobs(reg_results$ind_lowwage)),
          fmt0(nobs(rob_results$placebo)),
          fmt0(nobs(rob_results$emp_ddd))),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column (1): main specification restricted to low-wage industries (Retail 44--45, Accommodation/Food 72). ",
  "Column (2): placebo test using high-wage industries (Professional Services 54, Finance 52) where MW rarely binds. ",
  "Column (3): DDD using log employment (rather than log hires) as outcome. ",
  "Leave-one-out range shows the DDD triple interaction coefficient when each treated state is excluded in turn. ",
  "Standard errors clustered at the state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, paste0(tables_dir, "tab4_robustness.tex"))

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# =============================================================================
cat("Generating Table F1: SDE...\n")

# Pre-treatment SD of log hires by race
analysis_state <- readRDS(paste0(data_dir, "analysis_state.rds"))

pre_sd <- analysis_state %>%
  filter(first_treat_time == 0 | time_id < first_treat_time) %>%
  group_by(race) %>%
  summarise(sd_y = sd(log_hires, na.rm = TRUE), .groups = "drop")

sd_white <- pre_sd$sd_y[pre_sd$race == "A1"]
sd_black <- pre_sd$sd_y[pre_sd$race == "A2"]

# Classify SDE
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled results
sde_rows_a <- list()

# White hires
beta_w <- cs_results$white$att_overall$overall.att
se_w <- cs_results$white$att_overall$overall.se
sde_w <- beta_w / sd_white
se_sde_w <- se_w / sd_white
sde_rows_a[[1]] <- list(
  outcome = "Hires (White)", beta = beta_w, se = se_w,
  sd_y = sd_white, sde = sde_w, se_sde = se_sde_w,
  class = classify_sde(sde_w)
)

# Black hires
beta_b <- cs_results$black$att_overall$overall.att
se_b <- cs_results$black$att_overall$overall.se
sde_b <- beta_b / sd_black
se_sde_b <- se_b / sd_black
sde_rows_a[[2]] <- list(
  outcome = "Hires (Black)", beta = beta_b, se = se_b,
  sd_y = sd_black, sde = sde_b, se_sde = se_sde_b,
  class = classify_sde(sde_b)
)

# Racial gap (Black - White)
beta_gap <- beta_b - beta_w
se_gap <- sqrt(se_w^2 + se_b^2)
sd_gap <- sd(analysis_state$log_hires[analysis_state$first_treat_time == 0 |
              analysis_state$time_id < analysis_state$first_treat_time], na.rm = TRUE)
sde_gap <- beta_gap / sd_gap
se_sde_gap <- se_gap / sd_gap
sde_rows_a[[3]] <- list(
  outcome = "Racial gap (B$-$W)", beta = beta_gap, se = se_gap,
  sd_y = sd_gap, sde = sde_gap, se_sde = se_sde_gap,
  class = classify_sde(sde_gap)
)

# Panel B: Heterogeneous (low-wage vs high-wage industry)
sde_rows_b <- list()

# Low-wage industry effect
lw_coefs <- get_coefs(reg_results$ind_lowwage, "lw")
lw_main <- lw_coefs[grepl("black:post|post:black", lw_coefs$variable), ]
if (nrow(lw_main) > 0) {
  lw_main <- lw_main[1, ]
  sd_lw <- sd(analysis_industry$log_hires[analysis_industry$low_wage_industry == 1 &
               (analysis_industry$first_treat_time == 0 | analysis_industry$time_id < analysis_industry$first_treat_time)],
              na.rm = TRUE)
  sde_lw <- lw_main$coef / sd_lw
  sde_rows_b[[1]] <- list(
    outcome = "Gap: Retail/Food", beta = lw_main$coef, se = lw_main$se,
    sd_y = sd_lw, sde = sde_lw, se_sde = lw_main$se / sd_lw,
    class = classify_sde(sde_lw)
  )
}

# High-wage industry effect (placebo)
hw_coefs <- get_coefs(reg_results$ind_highwage, "hw")
hw_main <- hw_coefs[grepl("black:post|post:black", hw_coefs$variable), ]
if (nrow(hw_main) > 0) {
  hw_main <- hw_main[1, ]
  sd_hw <- sd(analysis_industry$log_hires[analysis_industry$low_wage_industry == 0 &
               (analysis_industry$first_treat_time == 0 | analysis_industry$time_id < analysis_industry$first_treat_time)],
              na.rm = TRUE)
  sde_hw <- hw_main$coef / sd_hw
  sde_rows_b[[2]] <- list(
    outcome = "Gap: Prof./Finance", beta = hw_main$coef, se = hw_main$se,
    sd_y = sd_hw, sde = sde_hw, se_sde = hw_main$se / sd_hw,
    class = classify_sde(sde_hw)
  )
}

# Build SDE table
sde_header <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (r in sde_rows_a) {
  sde_header <- paste0(sde_header,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
            r$outcome, fmt(r$beta, 4), fmt(r$se, 4), fmt(r$sd_y, 3),
            fmt(r$sde, 4), fmt(r$se_sde, 4), r$class))
}

sde_header <- paste0(sde_header,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by industry MW bite)}} \\\\\n"
)

for (r in sde_rows_b) {
  sde_header <- paste0(sde_header,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
            r$outcome, fmt(r$beta, 4), fmt(r$se, 4), fmt(r$sd_y, 3),
            fmt(r$sde, 4), fmt(r$se_sde, 4), r$class))
}

# --- SDE notes ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state minimum wage increases narrow or widen the Black--White gap in quarterly new hires (accessions)? ",
  "\\textbf{Policy mechanism:} State minimum wage increases compress the lower tail of the wage distribution, potentially altering employers' willingness and ability to hire minority workers through changes in the cost of wage discrimination and shifts toward non-price screening. ",
  "\\textbf{Outcome definition:} Log quarterly hires (accessions) from the Census QWI race-ethnicity panel, measuring workers who began a new job at a firm during the quarter. ",
  "\\textbf{Treatment:} Binary --- first quarter a state's effective minimum wage exceeds the federal minimum (\\$7.25/hr). ",
  "\\textbf{Data:} Census Bureau Quarterly Workforce Indicators (QWI) race-ethnicity panel, 2005--2023, state $\\times$ quarter $\\times$ race, approximately ",
  fmt0(diagnostics$n_obs), " observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with doubly-robust estimation; standard errors clustered at the state level; not-yet-treated states as control group. ",
  "\\textbf{Sample:} All 50 states plus DC; treatment defined as first above-federal MW quarter; states that never exceed federal MW serve as never-treated controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_footer <- paste0(
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(paste0(sde_header, sde_footer), paste0(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("  tab1_sumstats.tex\n")
cat("  tab2_event_study.tex\n")
cat("  tab3_ddd.tex\n")
cat("  tab4_robustness.tex\n")
cat("  tabF1_sde.tex\n")
