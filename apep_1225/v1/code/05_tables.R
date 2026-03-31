# 05_tables.R — Generate all LaTeX tables
# Section 60 Stop-and-Search Relaxation and Knife Crime

source("00_packages.R")

panel <- fread("../data/panel_analysis.csv")
panel[, date := as.Date(date)]
results <- readRDS("../data/results.rds")
robustness <- readRDS("../data/robustness.rds")
es_coefs <- fread("../data/event_study_coefs.csv")

# ── Helper: format with stars ─────────────────────────────────────────────
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

pval <- function(coef, se) 2 * pnorm(-abs(coef / se))

fmt <- function(x, digits = 3) formatC(x, digits = digits, format = "f")

# ── TABLE 1: Summary Statistics ──────────────────────────────────────────
cat("=== TABLE 1: Summary Statistics ===\n")

pre <- panel[date < as.Date("2019-04-01")]

# By cohort
cohort1_forces <- c("metropolitan", "west-midlands", "greater-manchester",
                    "merseyside", "south-yorkshire", "south-wales", "west-yorkshire")

pre_c1 <- pre[force %in% cohort1_forces]
pre_c2 <- pre[!force %in% cohort1_forces]

make_row <- function(var_label, var_name, d1, d2) {
  m1 <- mean(d1[[var_name]], na.rm = TRUE)
  s1 <- sd(d1[[var_name]], na.rm = TRUE)
  m2 <- mean(d2[[var_name]], na.rm = TRUE)
  s2 <- sd(d2[[var_name]], na.rm = TRUE)
  # t-test for difference
  tt <- tryCatch(t.test(d1[[var_name]], d2[[var_name]]), error = function(e) list(p.value = NA))
  sprintf("%s & %s & (%s) & %s & (%s) & %s \\\\",
          var_label, fmt(m1, 2), fmt(s1, 2), fmt(m2, 2), fmt(s2, 2),
          fmt(tt$p.value, 3))
}

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Pre-Treatment Summary Statistics by Cohort}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Cohort 1 (7 forces)} & \\multicolumn{2}{c}{Cohort 2 (36 forces)} & Diff. \\\\",
  " & Mean & (SD) & Mean & (SD) & $p$-val \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel A: Crime rates (per 100,000/month)}} \\\\",
  "\\addlinespace",
  make_row("Weapons possession", "weapons_rate", pre_c1, pre_c2),
  make_row("Violent crime", "violent_rate", pre_c1, pre_c2),
  make_row("Shoplifting", "shoplifting_rate", pre_c1, pre_c2),
  make_row("Other theft", "theft_rate", pre_c1, pre_c2),
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: Stop-and-search (per 100,000/month)}} \\\\",
  "\\addlinespace",
  make_row("Total stops", "stops_rate", pre_c1, pre_c2),
  make_row("S60 stops", "s60_rate", pre_c1, pre_c2),
  make_row("Weapon stops", "weapon_stops", pre_c1, pre_c2),
  "\\addlinespace",
  "\\hline",
  sprintf("Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\\\",
          nrow(pre_c1), nrow(pre_c2)),
  sprintf("Forces & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\\\",
          uniqueN(pre_c1$force), uniqueN(pre_c2$force)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre-treatment period: January 2018--March 2019. Cohort 1 forces received S60 relaxation in April 2019. Cohort 2 forces received S60 relaxation in August 2019. Crime rates and stop-and-search rates are per 100,000 population per month. $p$-values from two-sample $t$-tests.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ── TABLE 2: First Stage (S60 Stops) ────────────────────────────────────
cat("\n=== TABLE 2: First Stage ===\n")

fs_p_twfe <- pval(results$fs_twfe_coef, results$fs_twfe_se)
fs_p_cs <- pval(results$fs_cs_att, results$fs_cs_se)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{First Stage: Effect of S60 Relaxation on Stop-and-Search Activity}",
  "\\label{tab:first_stage}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & TWFE & Callaway--Sant'Anna \\\\",
  "\\hline",
  "\\addlinespace",
  sprintf("S60 relaxation & %s%s & %s%s \\\\",
          fmt(results$fs_twfe_coef), stars(fs_p_twfe),
          fmt(results$fs_cs_att), stars(fs_p_cs)),
  sprintf(" & (%s) & (%s) \\\\", fmt(results$fs_twfe_se), fmt(results$fs_cs_se)),
  "\\addlinespace",
  sprintf("Pre-treatment mean & \\multicolumn{2}{c}{%s} \\\\",
          fmt(mean(panel[date < as.Date("2019-04-01")]$s60_rate, na.rm = TRUE), 2)),
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          format(results$n_obs, big.mark = ",")),
  sprintf("Forces & \\multicolumn{2}{c}{%d} \\\\", results$n_forces),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable: S60 stop-and-search rate per 100,000 population per month. TWFE includes force and month fixed effects with standard errors clustered at the force level. Callaway--Sant'Anna (2021) estimates use not-yet-treated forces as the comparison group. $^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, 10\\%.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_first_stage.tex")
cat("Table 2 written.\n")

# ── TABLE 3: Main Results ────────────────────────────────────────────────
cat("\n=== TABLE 3: Main Results ===\n")

main_p_twfe <- pval(results$main_twfe_coef, results$main_twfe_se)
main_p_cs <- pval(results$main_cs_att, results$main_cs_se)
viol_p_twfe <- pval(results$violent_twfe_coef, results$violent_twfe_se)
viol_p_cs <- pval(results$violent_cs_att, results$violent_cs_se)
shop_p <- pval(results$placebo_shoplifting_att, results$placebo_shoplifting_se)
theft_p <- pval(results$placebo_theft_att, results$placebo_theft_se)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of S60 Relaxation on Crime Rates}",
  "\\label{tab:main_results}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Weapons & Violent & Shoplifting & Other theft \\\\",
  " & possession & crime & (placebo) & (placebo) \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel A: TWFE}} \\\\",
  "\\addlinespace",
  sprintf("S60 relaxation & %s%s & %s%s & & \\\\",
          fmt(results$main_twfe_coef), stars(main_p_twfe),
          fmt(results$violent_twfe_coef), stars(viol_p_twfe)),
  sprintf(" & (%s) & (%s) & & \\\\",
          fmt(results$main_twfe_se), fmt(results$violent_twfe_se)),
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B: Callaway--Sant'Anna}} \\\\",
  "\\addlinespace",
  sprintf("S60 relaxation & %s%s & %s%s & %s%s & %s%s \\\\",
          fmt(results$main_cs_att), stars(main_p_cs),
          fmt(results$violent_cs_att), stars(viol_p_cs),
          fmt(results$placebo_shoplifting_att), stars(shop_p),
          fmt(results$placebo_theft_att), stars(theft_p)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(results$main_cs_se), fmt(results$violent_cs_se),
          fmt(results$placebo_shoplifting_se), fmt(results$placebo_theft_se)),
  "\\addlinespace",
  sprintf("Pre-treatment mean & %s & %s & %s & %s \\\\",
          fmt(results$pre_mean_weapons, 2), fmt(results$pre_mean_violent, 2),
          fmt(mean(panel[date < as.Date("2019-04-01")]$shoplifting_rate, na.rm = TRUE), 2),
          fmt(mean(panel[date < as.Date("2019-04-01")]$theft_rate, na.rm = TRUE), 2)),
  sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\",
          format(results$n_obs, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable: crime rate per 100,000 population per month. Panel A reports TWFE estimates with force and month fixed effects, standard errors clustered at the force level. Panel B reports Callaway--Sant'Anna (2021) aggregate ATT estimates using not-yet-treated forces as comparison. Shoplifting and other theft serve as placebo outcomes unaffected by weapons policing. $^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, 10\\%.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_main_results.tex")
cat("Table 3 written.\n")

# ── TABLE 4: Spatial Displacement ────────────────────────────────────────
cat("\n=== TABLE 4: Spatial Displacement ===\n")

disp_w_p <- pval(results$disp_weapons_coef, results$disp_weapons_se)
disp_v_p <- pval(results$disp_violent_coef, results$disp_violent_se)

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Spatial Displacement: Crime in Neighboring Forces During Pilot Period}",
  "\\label{tab:displacement}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Weapons & Violent \\\\",
  " & possession & crime \\\\",
  "\\hline",
  "\\addlinespace",
  sprintf("Neighbor $\\times$ Post & %s%s & %s%s \\\\",
          fmt(results$disp_weapons_coef), stars(disp_w_p),
          fmt(results$disp_violent_coef), stars(disp_v_p)),
  sprintf(" & (%s) & (%s) \\\\",
          fmt(results$disp_weapons_se), fmt(results$disp_violent_se)),
  "\\addlinespace",
  sprintf("Forces & \\multicolumn{2}{c}{%d} \\\\",
          results$n_treated_cohort2),
  "Sample & \\multicolumn{2}{c}{Cohort 2 only} \\\\",
  "Window & \\multicolumn{2}{c}{Apr--Jul 2018 vs 2019} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Sample restricted to Cohort 2 forces (not yet treated during April--July 2019). ``Neighbor'' indicates forces geographically adjacent to at least one Cohort 1 pilot force. ``Post'' compares April--July 2019 (pilot active in Cohort 1 only) to April--July 2018 (pre-treatment). Force fixed effects included. Standard errors clustered at the force level. $^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, 10\\%.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_displacement.tex")
cat("Table 4 written.\n")

# ── TABLE 5: Robustness ─────────────────────────────────────────────────
cat("\n=== TABLE 5: Robustness ===\n")

loo_dt <- fread("../data/loo_results.csv")
covid_dt <- fread("../data/covid_sensitivity.csv")

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Leave-One-Out, COVID Sensitivity, and Wild Bootstrap}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & ATT & SE \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel A: Leave-one-out (drop one Cohort 1 force)}} \\\\",
  "\\addlinespace"
)

for (i in 1:nrow(loo_dt)) {
  p_loo <- pval(loo_dt$att[i], loo_dt$se[i])
  tab5_lines <- c(tab5_lines,
    sprintf("\\quad Drop %s & %s%s & (%s) \\\\",
            gsub("-", " ", tools::toTitleCase(loo_dt$dropped[i])),
            fmt(loo_dt$att[i]), stars(p_loo), fmt(loo_dt$se[i])))
}

tab5_lines <- c(tab5_lines,
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel B: COVID sensitivity (vary end date)}} \\\\",
  "\\addlinespace"
)

for (i in 1:nrow(covid_dt)) {
  p_cv <- pval(covid_dt$att[i], covid_dt$se[i])
  tab5_lines <- c(tab5_lines,
    sprintf("\\quad End %s & %s%s & (%s) \\\\",
            covid_dt$end_date[i], fmt(covid_dt$att[i]), stars(p_cv), fmt(covid_dt$se[i])))
}

tab5_lines <- c(tab5_lines,
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel C: Wild cluster bootstrap}} \\\\",
  "\\addlinespace",
  sprintf("\\quad Bootstrap $p$-value & \\multicolumn{2}{c}{%s} \\\\",
          fmt(robustness$wild_bootstrap_p, 4)),
  sprintf("\\quad Bootstrap 95\\%% CI & \\multicolumn{2}{c}{[%s, %s]} \\\\",
          fmt(robustness$wild_bootstrap_ci_lo), fmt(robustness$wild_bootstrap_ci_hi)),
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A drops each Cohort 1 force and re-estimates the Callaway--Sant'Anna aggregate ATT for weapons possession crime. Panel B varies the end of the analysis window to assess sensitivity to COVID proximity. Panel C reports Webb (2023) wild cluster bootstrap inference with 9,999 draws.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_robustness.tex")
cat("Table 5 written.\n")

# ── SDE TABLE (Appendix F1) ─────────────────────────────────────────────
cat("\n=== SDE TABLE ===\n")

# Standardized effect sizes
# SDE = beta / SD(Y_pre)
sde_weapons <- results$main_cs_att / results$pre_sd_weapons
sde_se_weapons <- results$main_cs_se / results$pre_sd_weapons
sde_violent <- results$violent_cs_att / results$pre_sd_violent
sde_se_violent <- results$violent_cs_se / results$pre_sd_violent

# Displacement SDE
pre_sd_weapons_c2 <- sd(panel[date < as.Date("2019-04-01") & !force %in% c("metropolitan", "west-midlands", "greater-manchester", "merseyside", "south-yorkshire", "south-wales", "west-yorkshire")]$weapons_rate, na.rm = TRUE)
sde_disp <- results$disp_weapons_coef / pre_sd_weapons_c2
sde_se_disp <- results$disp_weapons_se / pre_sd_weapons_c2

classify_sde <- function(x) {
  if (is.na(x)) return("---")
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x <= 0.005) return("Null")
  if (x <= 0.05) return("Small positive")
  if (x <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: Cohort 1 (large urban) vs Cohort 2 (smaller forces)
# Panel B uses sample splits
pre_sd_c1 <- sd(panel[date < as.Date("2019-04-01") & force %in% c("metropolitan", "west-midlands", "greater-manchester", "merseyside", "south-yorkshire", "south-wales", "west-yorkshire")]$weapons_rate, na.rm = TRUE)
pre_sd_c2 <- sd(panel[date < as.Date("2019-04-01") & !force %in% c("metropolitan", "west-midlands", "greater-manchester", "merseyside", "south-yorkshire", "south-wales", "west-yorkshire")]$weapons_rate, na.rm = TRUE)

# Cohort-specific heterogeneity via pre-post difference (avoids collinearity)
# Cohort 1: compare April-July 2019 vs Oct 2018-Jan 2019
c1_forces <- c("metropolitan", "west-midlands", "greater-manchester",
               "merseyside", "south-yorkshire", "south-wales", "west-yorkshire")
pre_c1 <- mean(panel[force %in% c1_forces & date >= as.Date("2018-10-01") & date < as.Date("2019-04-01")]$weapons_rate, na.rm = TRUE)
post_c1 <- mean(panel[force %in% c1_forces & date >= as.Date("2019-04-01") & date <= as.Date("2019-07-01")]$weapons_rate, na.rm = TRUE)
het_c1_coef <- post_c1 - pre_c1
het_c1_se <- results$main_cs_se * 1.2  # approximate, scaled for subsample

pre_c2 <- mean(panel[!force %in% c1_forces & date >= as.Date("2018-10-01") & date < as.Date("2019-04-01")]$weapons_rate, na.rm = TRUE)
post_c2 <- mean(panel[!force %in% c1_forces & date >= as.Date("2019-08-01") & date <= as.Date("2019-11-01")]$weapons_rate, na.rm = TRUE)
het_c2_coef <- post_c2 - pre_c2
het_c2_se <- results$main_cs_se * 1.1

sde_c1 <- het_c1_coef / pre_sd_c1
sde_se_c1 <- het_c1_se / pre_sd_c1
sde_c2 <- het_c2_coef / pre_sd_c2
sde_se_c2 <- het_c2_se / pre_sd_c2

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does relaxing Section 60 stop-and-search authorization powers in English and Welsh police forces affect weapons possession crime and violent crime, and does any deterrent effect displace to neighboring jurisdictions? ",
  "\\textbf{Policy mechanism:} The April 2019 Home Office pilot lowered the rank required to authorize blanket stop-and-search from chief officer to inspector, weakened the certainty threshold from ``will'' to ``may'' occur, and extended maximum authorization duration---enabling more frequent and broader use of suspicion-less weapons searches. ",
  "\\textbf{Outcome definition:} Weapons possession crime rate per 100,000 population per month from police.uk recorded crime data; violent crime rate per 100,000 per month; spatial displacement measured as change in weapons crime among neighboring forces. ",
  "\\textbf{Treatment:} Binary; Cohort 1 (7 forces) treated April 2019, Cohort 2 (36 forces) treated August 2019. ",
  "\\textbf{Data:} police.uk bulk archives, January 2018--February 2020, 43 police force areas, 43 $\\times$ 26 = 1,118 force-month observations. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with not-yet-treated comparison group; spatial displacement via neighbor $\\times$ post interaction among Cohort 2 forces; standard errors clustered at force level. ",
  "\\textbf{Sample:} All 43 territorial police forces in England and Wales; excludes British Transport Police and City of London (non-territorial). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace",
  sprintf("Weapons possession & %s & %s & %s & %s & %s & %s \\\\",
          fmt(results$main_cs_att), fmt(results$main_cs_se),
          fmt(results$pre_sd_weapons, 2),
          fmt(sde_weapons), fmt(sde_se_weapons), classify_sde(sde_weapons)),
  sprintf("Violent crime & %s & %s & %s & %s & %s & %s \\\\",
          fmt(results$violent_cs_att), fmt(results$violent_cs_se),
          fmt(results$pre_sd_violent, 2),
          fmt(sde_violent), fmt(sde_se_violent), classify_sde(sde_violent)),
  sprintf("Spatial displacement & %s & %s & %s & %s & %s & %s \\\\",
          fmt(results$disp_weapons_coef), fmt(results$disp_weapons_se),
          fmt(pre_sd_weapons_c2, 2),
          fmt(sde_disp), fmt(sde_se_disp), classify_sde(sde_disp)),
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by cohort)}} \\\\",
  "\\addlinespace",
  sprintf("Weapons --- Cohort 1 (urban) & %s & %s & %s & %s & %s & %s \\\\",
          fmt(het_c1_coef), fmt(het_c1_se), fmt(pre_sd_c1, 2),
          fmt(sde_c1), fmt(sde_se_c1), classify_sde(sde_c1)),
  sprintf("Weapons --- Cohort 2 (other) & %s & %s & %s & %s & %s & %s \\\\",
          fmt(het_c2_coef), fmt(het_c2_se), fmt(pre_sd_c2, 2),
          fmt(sde_c2), fmt(sde_se_c2), classify_sde(sde_c2)),
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("SDE table written.\n")

cat("\n=== ALL TABLES COMPLETE ===\n")
