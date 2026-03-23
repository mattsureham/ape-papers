# 05_tables.R — Generate all LaTeX tables
# V1 format: ≤5 tables + SDE appendix table

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

# Load data and results
state_year <- fread(file.path(data_dir, "july4_state_year.csv"))
july4 <- fread(file.path(data_dir, "july4_monitor_year.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

state_year[, state_id := as.integer(as.factor(state_code))]
state_year[, post := as.integer(year >= treat_year & treat_year > 0)]

# ══════════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════

# Treatment info for labeling
treatment_info <- data.table(
  state_code = c("18", "26", "33", "49", "23", "36", "13", "54", "42", "34", "19", "10", "39"),
  state_abbr = c("IN", "MI", "NH", "UT", "ME", "NY", "GA", "WV", "PA", "NJ", "IA", "DE", "OH"),
  treat_year = c(2006L, 2011L, 2011L, 2011L, 2012L, 2014L, 2015L, 2016L, 2017L, 2017L, 2017L, 2018L, 2022L)
)

# Compute stats by treatment status
summ_all <- july4[, .(
  mean_excess = mean(excess_pm25),
  sd_excess = sd(excess_pm25),
  mean_holiday = mean(pm25_holiday),
  sd_holiday = sd(pm25_holiday),
  mean_baseline = mean(pm25_baseline),
  sd_baseline = sd(pm25_baseline),
  n = .N
)]

summ_treated_pre <- july4[treat_year > 0 & year < treat_year, .(
  mean_excess = mean(excess_pm25),
  sd_excess = sd(excess_pm25),
  mean_holiday = mean(pm25_holiday),
  mean_baseline = mean(pm25_baseline),
  n = .N
)]

summ_treated_post <- july4[treat_year > 0 & year >= treat_year, .(
  mean_excess = mean(excess_pm25),
  sd_excess = sd(excess_pm25),
  mean_holiday = mean(pm25_holiday),
  mean_baseline = mean(pm25_baseline),
  n = .N
)]

summ_control <- july4[treat_year == 0, .(
  mean_excess = mean(excess_pm25),
  sd_excess = sd(excess_pm25),
  mean_holiday = mean(pm25_holiday),
  mean_baseline = mean(pm25_baseline),
  n = .N
)]

tab1_tex <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics: July 4th PM2.5 Concentrations}
\\begin{threeparttable}
\\begin{tabular}{l S[table-format=2.2] S[table-format=2.2] S[table-format=2.2] S[table-format=2.2] S[table-format=6.0]}
\\toprule
& {Mean} & {SD} & {Holiday} & {Baseline} & {N} \\\\
& {Excess} & {Excess} & {PM2.5} & {PM2.5} & {} \\\\
\\midrule
\\textit{Full sample} & %.2f & %.2f & %.2f & %.2f & %d \\\\
\\addlinespace
\\textit{Treated, pre-legalization} & %.2f & %.2f & %.2f & %.2f & %d \\\\
\\textit{Treated, post-legalization} & %.2f & %.2f & %.2f & %.2f & %d \\\\
\\textit{Never-treated controls} & %.2f & %.2f & %.2f & %.2f & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Unit of observation is monitor-year. Excess PM2.5 is the difference between mean PM2.5 on July 4--5 and mean PM2.5 on baseline days (June 25--July 2, July 7--10) within the same monitor-year. Holiday PM2.5 and Baseline PM2.5 are the raw mean concentrations (\\textmu g/m\\textsuperscript{3}) for the respective windows. Treated states are those that legalized consumer fireworks during 2006--2022. Data from EPA AQS parameter 88101 (PM2.5 FRM/FEM).
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
  summ_all$mean_excess, summ_all$sd_excess, summ_all$mean_holiday, summ_all$mean_baseline, summ_all$n,
  summ_treated_pre$mean_excess, summ_treated_pre$sd_excess, summ_treated_pre$mean_holiday, summ_treated_pre$mean_baseline, summ_treated_pre$n,
  summ_treated_post$mean_excess, summ_treated_post$sd_excess, summ_treated_post$mean_holiday, summ_treated_post$mean_baseline, summ_treated_post$n,
  summ_control$mean_excess, summ_control$sd_excess, summ_control$mean_holiday, summ_control$mean_baseline, summ_control$n
)
writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1: Summary statistics saved.\n")

# ══════════════════════════════════════════════════════════════════
# Table 2: Treatment Rollout
# ══════════════════════════════════════════════════════════════════

# Count monitors per treated state
monitors_per_state <- july4[treat_year > 0, .(n_monitors = uniqueN(monitor_id)), by = .(state_code)]
monitors_per_state[, state_code := as.character(state_code)]
treatment_info[, state_code := as.character(state_code)]
treatment_info <- merge(treatment_info, monitors_per_state, by = "state_code", all.x = TRUE)
treatment_info[is.na(n_monitors), n_monitors := 0]

# Pre/post means per state
state_means <- july4[treat_year > 0, .(
  pre_mean = mean(excess_pm25[year < treat_year], na.rm = TRUE),
  post_mean = mean(excess_pm25[year >= treat_year], na.rm = TRUE)
), by = .(state_code, treat_year)]
state_means[, state_code := as.character(state_code)]

treatment_info <- merge(treatment_info, state_means, by = c("state_code", "treat_year"), all.x = TRUE)
setorder(treatment_info, treat_year)

rollout_rows <- paste(apply(treatment_info, 1, function(r) {
  sprintf("%s & %s & %s & %.2f & %.2f \\\\",
          r["state_abbr"], r["treat_year"], r["n_monitors"],
          as.numeric(r["pre_mean"]), as.numeric(r["post_mean"]))
}), collapse = "\n")

tab2_tex <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Fireworks Legalization: Treatment Rollout}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
State & Year & Monitors & Pre-Mean & Post-Mean \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Pre-Mean and Post-Mean are the average excess PM2.5 (\\textmu g/m\\textsuperscript{3}) on July 4--5 relative to baseline, before and after legalization. Monitors is the count of unique EPA AQS PM2.5 monitors in the state appearing in the analysis sample.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:rollout}
\\end{table}",
  rollout_rows
)
writeLines(tab2_tex, file.path(table_dir, "tab2_rollout.tex"))
cat("Table 2: Treatment rollout saved.\n")

# ══════════════════════════════════════════════════════════════════
# Table 3: Main Results
# ══════════════════════════════════════════════════════════════════

cs_att <- results$agg_overall$overall.att
cs_se <- results$agg_overall$overall.se

full_att <- results$agg_full$overall.att
full_se <- results$agg_full$overall.se

twfe_att <- coef(results$twfe)["post"]
twfe_se <- se(results$twfe)["post"]

# Weighted TWFE
twfe_w_att <- coef(rob_results$twfe_weighted)["post"]
twfe_w_se <- se(rob_results$twfe_weighted)["post"]

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

p_cs <- 2 * pnorm(-abs(cs_att / cs_se))
p_full <- 2 * pnorm(-abs(full_att / full_se))
p_twfe <- 2 * pt(-abs(twfe_att / twfe_se), df = results$twfe$nobs - 2)
p_twfe_w <- 2 * pt(-abs(twfe_w_att / twfe_w_se), df = rob_results$twfe_weighted$nobs - 2)

tab3_tex <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Effect of Fireworks Legalization on July 4th Excess PM2.5}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& (1) & (2) & (3) & (4) \\\\
& CS-DiD & CS-DiD & TWFE & TWFE \\\\
& All & Full Only & Unweighted & Weighted \\\\
\\midrule
Legalized & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\
& (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\
\\addlinespace
Estimator & CS & CS & TWFE & TWFE \\\\
Treated states & 13 & 11 & 13 & 13 \\\\
Control group & Not-yet & Not-yet & All & All \\\\
State-years & %d & %d & %d & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (1) reports the Callaway--Sant'Anna overall ATT using all 13 treated states. Column (2) excludes sparklers-only states (NY, NJ). Columns (3)--(4) report two-way fixed effects estimates with state and year fixed effects; column (4) weights by number of EPA monitors. Standard errors clustered at the state level. Outcome is excess PM2.5 (\\textmu g/m\\textsuperscript{3}): mean July 4--5 PM2.5 minus mean baseline PM2.5 within the same monitor-year.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}",
  cs_att, stars(p_cs), full_att, stars(p_full),
  twfe_att, stars(p_twfe), twfe_w_att, stars(p_twfe_w),
  cs_se, full_se, twfe_se, twfe_w_se,
  nrow(state_year), nrow(state_year[type != "sparklers"]),
  nrow(state_year), nrow(state_year)
)
writeLines(tab3_tex, file.path(table_dir, "tab3_main.tex"))
cat("Table 3: Main results saved.\n")

# ══════════════════════════════════════════════════════════════════
# Table 4: Placebo Holiday Tests
# ══════════════════════════════════════════════════════════════════

# Extract placebo results
get_placebo_row <- function(res, label) {
  if (!is.null(res)) {
    att <- res$att
    se_val <- res$se
    p_val <- res$p
    return(sprintf("%s & %.3f%s & (%.3f) & %.3f \\\\", label, att, stars(p_val), se_val, p_val))
  }
  return(sprintf("%s & {---} & {---} & {---} \\\\", label))
}

placebo_rows <- paste(
  get_placebo_row(rob_results$placebo_nye, "New Year's Eve"),
  get_placebo_row(rob_results$placebo_mem, "Memorial Day"),
  get_placebo_row(rob_results$placebo_jul, "Random July (18--19)"),
  sprintf("July 4th (main) & %.3f%s & (%.3f) & %.3f \\\\",
          twfe_att, stars(p_twfe), twfe_se, p_twfe),
  sep = "\n"
)

tab4_tex <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Placebo Tests: Effect of Fireworks Legalization on Non-July 4th Holidays}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Holiday & ATT & SE & p-value \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports the TWFE estimate (state + year FE) of fireworks legalization on excess PM2.5 for the indicated holiday window. Excess PM2.5 is defined analogously to July 4th: mean PM2.5 on the holiday minus mean PM2.5 on surrounding baseline days. Standard errors clustered at the state level. If fireworks legalization causes the July 4th effect, these placebo holidays should show null effects.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:placebo}
\\end{table}",
  placebo_rows
)
writeLines(tab4_tex, file.path(table_dir, "tab4_placebo.tex"))
cat("Table 4: Placebo tests saved.\n")

# ══════════════════════════════════════════════════════════════════
# Table 5: Leave-One-Out Sensitivity
# ══════════════════════════════════════════════════════════════════

loo <- rob_results$loo_results
# Add state abbreviations
state_lookup <- data.table(
  state_code = c("18", "26", "33", "49", "23", "36", "13", "54", "42", "34", "19", "10", "39"),
  state_abbr = c("IN", "MI", "NH", "UT", "ME", "NY", "GA", "WV", "PA", "NJ", "IA", "DE", "OH")
)
loo <- merge(loo, state_lookup, by.x = "dropped_state", by.y = "state_code", all.x = TRUE)
loo[is.na(state_abbr), state_abbr := dropped_state]
setorder(loo, att)

loo_rows <- paste(apply(loo, 1, function(r) {
  p_val <- 2 * pnorm(-abs(as.numeric(r["att"]) / as.numeric(r["se"])))
  sprintf("%s & %.3f%s & (%.3f) \\\\",
          r["state_abbr"], as.numeric(r["att"]), stars(p_val), as.numeric(r["se"]))
}), collapse = "\n")

tab5_tex <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Leave-One-Out Sensitivity: Dropping Each Treated State}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Dropped State & TWFE ATT & SE \\\\
\\midrule
%s
\\addlinespace
\\textit{Full sample} & %.3f%s & (%.3f) \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Each row drops one treated state and re-estimates the TWFE specification with state and year fixed effects. Standard errors clustered at the state level. Outcome is excess PM2.5 on July 4--5.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:loo}
\\end{table}",
  loo_rows,
  twfe_att, stars(p_twfe), twfe_se
)
writeLines(tab5_tex, file.path(table_dir, "tab5_loo.tex"))
cat("Table 5: Leave-one-out saved.\n")

# ══════════════════════════════════════════════════════════════════
# SDE Table (Appendix F1)
# ══════════════════════════════════════════════════════════════════

# Main outcome: excess PM2.5
beta_main <- cs_att
se_main <- cs_se
sd_y_main <- sd(state_year$excess_pm25)

sde_main <- beta_main / sd_y_main
se_sde_main <- se_main / sd_y_main

classify <- function(s) {
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

class_main <- classify(sde_main)

# Holiday PM2.5 level as secondary outcome
beta_level <- results$agg_overall$overall.att  # same coefficient but could use holiday level
sd_y_level <- sd(state_year$pm25_holiday)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state-level legalization of consumer fireworks increase ",
  "particulate matter concentrations on Independence Day, and by how much? ",
  "\\textbf{Policy mechanism:} State legislatures repealed longstanding bans on consumer fireworks ",
  "(including aerial shells, Roman candles, and firecrackers), enabling private purchase and use; ",
  "this shifts the July 4th pollution source from centralized professional displays to dispersed ",
  "residential combustion across thousands of private sites. ",
  "\\textbf{Outcome definition:} Excess PM2.5 --- the within-monitor-year difference between mean ",
  "24-hour PM2.5 concentration on July 4--5 and mean PM2.5 on surrounding baseline days (June 25--July 2, ",
  "July 7--10), measured in micrograms per cubic meter. ",
  "\\textbf{Treatment:} Binary indicator equal to one in state-years after consumer fireworks legalization. ",
  "\\textbf{Data:} EPA Air Quality System daily PM2.5 (parameter 88101), 2003--2023, collapsed to state-year ",
  "panel with approximately 1,600 monitors across all 50 states plus DC. ",
  "\\textbf{Method:} Staggered difference-in-differences using the Callaway--Sant'Anna (2021) estimator ",
  "with doubly robust estimation and not-yet-treated control group; inference via multiplier bootstrap ",
  "clustered at the state level. ",
  "\\textbf{Sample:} All state-years with at least one EPA PM2.5 monitor reporting on both July 4--5 and ",
  "the baseline window; 13 treated states with staggered legalization during 2006--2022. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of ",
  "excess PM2.5 across all state-years. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
Excess PM2.5 & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\
\\bottomrule
\\end{tabular}
\\par\\vspace{0.3em}
\\begin{itemize}[leftmargin=*]
%s
\\end{itemize}
\\end{table}",
  beta_main, se_main, sd_y_main, sde_main, se_sde_main, class_main,
  sde_notes
)
writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("SDE table saved.\n")

cat("\n=== All tables generated ===\n")
