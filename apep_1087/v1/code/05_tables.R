## 05_tables.R — Generate all LaTeX tables
## apep_1087: Healthcare WVP Mandates and Worker Injuries

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

## Load data and results
hc <- data.table::fread(file.path(data_dir, "panel_healthcare.csv"))
panel <- data.table::fread(file.path(data_dir, "panel_full.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
pre_stats <- readRDS(file.path(data_dir, "pre_stats.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

## Apply same cleaning as main analysis
hc <- hc[!is.na(state_fips)]
hc[state_abbr == "CT", wvp_year := 0]
hc[state_abbr == "TX", wvp_year := 0]
hc[, wvp_year := as.numeric(wvp_year)]

## Helper functions
stars <- function(est, se_val) {
  if (is.na(est) || is.na(se_val) || se_val == 0) return("")
  p <- 2 * pnorm(-abs(est / se_val))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

fmt <- function(x, digits = 3) {
  if (is.na(x)) return("---")
  formatC(round(x, digits), format = "f", digits = digits)
}

## ============================================================
## Table 1: Summary Statistics
## ============================================================

pre <- hc[wvp_year == 0 | year < wvp_year]
treated_pre <- hc[wvp_year > 0 & year < wvp_year]
control_pre <- hc[wvp_year == 0]

n_states_total <- length(unique(hc$state_fips))
n_treated <- length(unique(hc[wvp_year > 0]$state_fips))
n_control <- n_states_total - n_treated
n_years <- length(unique(hc$year))

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Healthcare Establishments (Pre-Treatment)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{All States} & Treated & Control \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-5}",
  " & Mean & SD & Mean & Mean \\\\",
  "\\midrule",
  paste0("DAFW rate & ", fmt(mean(pre$dafw_rate, na.rm=TRUE)),
         " & ", fmt(sd(pre$dafw_rate, na.rm=TRUE)),
         " & ", fmt(mean(treated_pre$dafw_rate, na.rm=TRUE)),
         " & ", fmt(mean(control_pre$dafw_rate, na.rm=TRUE)), " \\\\"),
  paste0("Injury rate & ", fmt(mean(pre$injury_rate, na.rm=TRUE)),
         " & ", fmt(sd(pre$injury_rate, na.rm=TRUE)),
         " & ", fmt(mean(treated_pre$injury_rate, na.rm=TRUE)),
         " & ", fmt(mean(control_pre$injury_rate, na.rm=TRUE)), " \\\\"),
  paste0("Total employees & ", fmt(mean(pre$total_employees, na.rm=TRUE), 0),
         " & ", fmt(sd(pre$total_employees, na.rm=TRUE), 0),
         " & ", fmt(mean(treated_pre$total_employees, na.rm=TRUE), 0),
         " & ", fmt(mean(control_pre$total_employees, na.rm=TRUE), 0), " \\\\"),
  paste0("Establishments & ", fmt(mean(pre$n_establishments, na.rm=TRUE), 0),
         " & ", fmt(sd(pre$n_establishments, na.rm=TRUE), 0),
         " & ", fmt(mean(treated_pre$n_establishments, na.rm=TRUE), 0),
         " & ", fmt(mean(control_pre$n_establishments, na.rm=TRUE), 0), " \\\\"),
  paste0("DAFW cases & ", fmt(mean(pre$dafw_cases, na.rm=TRUE), 0),
         " & ", fmt(sd(pre$dafw_cases, na.rm=TRUE), 0),
         " & ", fmt(mean(treated_pre$dafw_cases, na.rm=TRUE), 0),
         " & ", fmt(mean(control_pre$dafw_cases, na.rm=TRUE), 0), " \\\\"),
  "\\midrule",
  paste0("States & ", n_states_total, " & & ", n_treated, " & ", n_control, " \\\\"),
  paste0("Years & ", n_years, " & & & \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Summary statistics for the pre-treatment period. ",
         "DAFW rate and injury rate are measured per 100 full-time equivalent workers ",
         "(OSHA standard: cases $\\times$ 200,000 / total hours worked). ",
         "Treated states are those that adopted healthcare-specific WVP mandates between 2017 and 2023. ",
         "Connecticut (adopted 2012, before sample period) and Texas (adopted 2024, after sample period) ",
         "are classified as never-treated. ",
         "Data: OSHA Injury Tracking Application 300A Summary, 2016--2023."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

## ============================================================
## Table 2: Main Results
## ============================================================

## CS DiD results
cs_att <- results$agg_dafw$overall.att
cs_se <- results$agg_dafw$overall.se
cs_inj_att <- results$agg_inj$overall.att
cs_inj_se <- results$agg_inj$overall.se

## TWFE results
twfe_coef <- coef(results$twfe_dafw)["post"]
twfe_se_val <- se(results$twfe_dafw)["post"]
twfe_inj_coef <- coef(results$twfe_inj)["post"]
twfe_inj_se_val <- se(results$twfe_inj)["post"]

## DDD results
ddd_coef <- coef(results$ddd_dafw)["post:hc"]
ddd_se_val <- se(results$ddd_dafw)["post:hc"]

## Excluding 2023 (preferred spec)
no23_att <- rob_results$no23_att
no23_se <- rob_results$no23_se

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of WVP Mandates on Healthcare Worker Injuries}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{DAFW Rate} & \\multicolumn{2}{c}{Injury Rate} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\textit{Panel A: Full sample (2016--2023)} & & & & \\\\",
  paste0("CS DiD & ", fmt(cs_att), stars(cs_att, cs_se),
         " & & ", fmt(cs_inj_att), stars(cs_inj_att, cs_inj_se), " & \\\\"),
  paste0(" & (", fmt(cs_se), ") & & (", fmt(cs_inj_se), ") & \\\\"),
  "\\addlinespace",
  paste0("TWFE & & ", fmt(twfe_coef), stars(twfe_coef, twfe_se_val),
         " & & ", fmt(twfe_inj_coef), stars(twfe_inj_coef, twfe_inj_se_val), " \\\\"),
  paste0(" & & (", fmt(twfe_se_val), ") & & (", fmt(twfe_inj_se_val), ") \\\\"),
  "\\addlinespace",
  "\\textit{Panel B: Preferred (2016--2022)} & & & & \\\\",
  paste0("CS DiD & ", fmt(no23_att), stars(no23_att, no23_se),
         " & & & \\\\"),
  paste0(" & (", fmt(no23_se), ") & & & \\\\"),
  "\\addlinespace",
  "\\textit{Panel C: Triple-difference} & & & & \\\\",
  paste0("Post $\\times$ Healthcare & ", fmt(ddd_coef), stars(ddd_coef, ddd_se_val),
         " & & & \\\\"),
  paste0(" & (", fmt(ddd_se_val), ") & & & \\\\"),
  "\\midrule",
  paste0("State FE & Yes & Yes & Yes & Yes \\\\"),
  paste0("Year FE & Yes & Yes & Yes & Yes \\\\"),
  paste0("States & ", n_states_total, " & ", n_states_total,
         " & ", n_states_total, " & ", n_states_total, " \\\\"),
  paste0("Treated states & ", n_treated, " & ", n_treated,
         " & ", n_treated, " & ", n_treated, " \\\\"),
  paste0("Pre-treatment mean & ", fmt(pre_stats$mean_dafw), " & ",
         fmt(pre_stats$mean_dafw), " & ",
         fmt(pre_stats$mean_inj), " & ", fmt(pre_stats$mean_inj), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
         "Outcomes are per 100 FTE workers (OSHA standard rate). ",
         "Panel A reports full-sample estimates; the CS DiD result is driven entirely by 2023 data. ",
         "Panel B excludes 2023 and drops the 2023 treatment cohort; this is the preferred specification. ",
         "Panel C reports triple-difference estimates using non-healthcare establishments as within-state controls. ",
         "CS DiD uses Callaway and Sant'Anna (2021) with never-treated controls. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

## ============================================================
## Table 3: Event Study
## ============================================================

es <- results$es_dafw
es_df <- data.frame(
  e = es$egt,
  att = es$att.egt,
  se = es$se.egt
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: DAFW Rate Relative to WVP Mandate Adoption}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Event Time & ATT & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_df)) {
  ci_lo <- es_df$att[i] - 1.96 * es_df$se[i]
  ci_hi <- es_df$att[i] + 1.96 * es_df$se[i]
  label <- ifelse(es_df$e[i] >= 0, paste0("+", es_df$e[i]), as.character(es_df$e[i]))
  tab3_lines <- c(tab3_lines,
    paste0("$e = ", label, "$ & ",
           fmt(es_df$att[i]), stars(es_df$att[i], es_df$se[i]),
           " & (", fmt(es_df$se[i]), ")",
           " & [", fmt(ci_lo), ", ", fmt(ci_hi), "] \\\\")
  )
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Callaway--Sant'Anna (2021) event-study estimates, full sample 2016--2023. ",
         "Event time $e$ denotes years relative to WVP mandate adoption. ",
         "Never-treated states serve as controls. ",
         "Standard errors clustered at the state level. ",
         "The large positive estimates at longer post-treatment horizons are driven by the 2023 data year; ",
         "see Table~\\ref{tab:robustness} for estimates excluding 2023. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_eventstudy.tex"))
cat("Table 3 written.\n")

## ============================================================
## Table 4: Robustness
## ============================================================

## LOO range
loo <- rob_results$loo
loo_valid <- loo[!is.na(loo$att), ]

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: DAFW Rate}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & ATT & SE \\\\",
  "\\midrule",
  paste0("\\textit{Full sample (2016--2023)} & ", fmt(cs_att),
         stars(cs_att, cs_se), " & (", fmt(cs_se), ") \\\\"),
  "\\addlinespace",
  paste0("Preferred: Excluding 2023 & ", fmt(no23_att),
         stars(no23_att, no23_se), " & (", fmt(no23_se), ") \\\\"),
  paste0("Log specification & ", fmt(rob_results$log_att),
         stars(rob_results$log_att, rob_results$log_se),
         " & (", fmt(rob_results$log_se), ") \\\\"),
  paste0("TWFE with state trends & ", fmt(rob_results$trend_coef),
         stars(rob_results$trend_coef, rob_results$trend_se),
         " & (", fmt(rob_results$trend_se), ") \\\\"),
  paste0("Placebo: Non-healthcare & ", fmt(rob_results$placebo_att),
         stars(rob_results$placebo_att, rob_results$placebo_se),
         " & (", fmt(rob_results$placebo_se), ") \\\\")
)

if (nrow(loo_valid) > 0) {
  tab4_lines <- c(tab4_lines,
    "\\addlinespace",
    paste0("Leave-one-out range & [", fmt(min(loo_valid$att)),
           ", ", fmt(max(loo_valid$att)), "] & \\\\")
  )
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} All specifications use the DAFW rate (per 100 FTE) as the outcome. ",
         "Full-sample CS DiD uses Callaway--Sant'Anna (2021) with never-treated controls. ",
         "The preferred specification excludes 2023 data and drops the 2023 treatment cohort. ",
         "Log specification uses $\\log(\\text{DAFW rate} + 0.01)$. ",
         "State trends adds state-specific linear time trends to TWFE. ",
         "The placebo test applies the same CS estimator to non-healthcare establishments. ",
         "Leave-one-out drops each treated state in turn (full sample). ",
         "Standard errors clustered at the state level. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

## ============================================================
## Table F1: Standardized Effect Sizes (SDE)
## ============================================================

## Use PREFERRED specification (excluding 2023) for SDE
## This is the honest result
sde_main <- no23_att / pre_stats$sd_dafw
sde_main_se <- no23_se / pre_stats$sd_dafw

## Full sample for comparison
sde_full <- cs_att / pre_stats$sd_dafw
sde_full_se <- cs_se / pre_stats$sd_dafw

## Injury rate
sde_inj <- cs_inj_att / pre_stats$sd_inj
sde_inj_se <- cs_inj_se / pre_stats$sd_inj

## Classification
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

## Heterogeneity: early vs late adopters (using preferred spec excl 2023)
## Early = adopted 2017-2019, Late = adopted 2020-2022
## Run CS on subsamples
hc_pref <- hc[year <= 2022]
hc_pref[wvp_year == 2023, wvp_year := 0]
hc_pref[, post := as.integer(year >= wvp_year & wvp_year > 0)]

early_states <- unique(hc_pref[wvp_year > 0 & wvp_year <= 2019]$state_fips)
late_states <- unique(hc_pref[wvp_year > 2019 & wvp_year <= 2022]$state_fips)

hc_early <- hc_pref[state_fips %in% early_states | wvp_year == 0]
hc_late <- hc_pref[state_fips %in% late_states | wvp_year == 0]

cs_early_agg <- tryCatch({
  out <- did::att_gt(yname = "dafw_rate", tname = "year", idname = "state_fips",
    gname = "wvp_year", data = as.data.frame(hc_early),
    control_group = "nevertreated", anticipation = 0, base_period = "varying")
  did::aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))

cs_late_agg <- tryCatch({
  out <- did::att_gt(yname = "dafw_rate", tname = "year", idname = "state_fips",
    gname = "wvp_year", data = as.data.frame(hc_late),
    control_group = "nevertreated", anticipation = 0, base_period = "varying")
  did::aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))

early_att <- cs_early_agg$overall.att
early_se <- cs_early_agg$overall.se
late_att <- cs_late_agg$overall.att
late_se <- cs_late_agg$overall.se

sde_early <- early_att / pre_stats$sd_dafw
sde_early_se <- early_se / pre_stats$sd_dafw
sde_late <- late_att / pre_stats$sd_dafw
sde_late_se <- late_se / pre_stats$sd_dafw

n_obs <- nrow(hc)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-mandated workplace violence prevention (WVP) programs ",
  "for healthcare employers reduce days-away-from-work injuries among healthcare workers? ",
  "\\textbf{Policy mechanism:} State WVP mandates require healthcare employers to conduct workplace ",
  "violence risk assessments, develop written prevention plans, train staff in de-escalation and ",
  "reporting protocols, and maintain incident logs --- creating administrative and behavioral ",
  "infrastructure intended to reduce violent incidents against healthcare workers. ",
  "\\textbf{Outcome definition:} DAFW rate, measured as total days-away-from-work injury cases ",
  "per 100 full-time equivalent workers (OSHA standard: cases $\\times$ 200,000 / total hours worked) ",
  "among NAICS 62 (healthcare and social assistance) establishments. ",
  "\\textbf{Treatment:} Binary; state has enacted a healthcare-specific WVP mandate (effective date). ",
  "\\textbf{Data:} OSHA Injury Tracking Application (ITA) 300A Summary, 2016--2022 (preferred sample ",
  "excludes anomalous 2023 reporting year), state-by-year panel aggregated from establishment-level records, ",
  n_obs, " state-year observations across ", length(unique(hc$state_abbr)), " states. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with never-treated controls; ",
  "standard errors clustered at the state level. ",
  "\\textbf{Sample:} All US states with OSHA ITA reporting establishments in NAICS 62; ",
  "balanced panel restricted to states observed in all years; Connecticut (pre-sample adoption) ",
  "and Texas (post-sample adoption) classified as never-treated. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled (preferred, 2016--2022)} & & & & & & \\\\",
  paste0("DAFW rate & ", fmt(no23_att), " & ", fmt(no23_se),
         " & ", fmt(pre_stats$sd_dafw), " & ", fmt(sde_main),
         " & ", fmt(sde_main_se), " & ", classify_sde(sde_main), " \\\\"),
  paste0("Injury rate & ", fmt(cs_inj_att), " & ", fmt(cs_inj_se),
         " & ", fmt(pre_stats$sd_inj), " & ", fmt(sde_inj),
         " & ", fmt(sde_inj_se), " & ", classify_sde(sde_inj), " \\\\"),
  "\\addlinespace",
  "\\textit{Panel B: Heterogeneous (DAFW rate, 2016--2022)} & & & & & & \\\\",
  paste0("Early adopters ($\\leq$2019) & ", fmt(early_att), " & ", fmt(early_se),
         " & ", fmt(pre_stats$sd_dafw), " & ", fmt(sde_early),
         " & ", fmt(sde_early_se), " & ", classify_sde(sde_early), " \\\\"),
  paste0("Late adopters (2020--2022) & ", fmt(late_att), " & ", fmt(late_se),
         " & ", fmt(pre_stats$sd_dafw), " & ", fmt(sde_late),
         " & ", fmt(sde_late_se), " & ", classify_sde(sde_late), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
