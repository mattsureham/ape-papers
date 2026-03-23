# 05_tables.R — Generate all LaTeX tables
# apep_0801: California School Start Time Mandate and Teen Traffic Fatalities

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

# Load results
models <- readRDS(file.path(data_dir, "model_objects.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))
panel <- fread(file.path(data_dir, "panel_state_month.csv"))
diagnostics <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

tm <- panel[age_group == "teen" & hour_block == "morning"]

# Summary stats by CA vs Control, Pre vs Post
sum_stats <- panel[age_group %in% c("teen", "adult") & hour_block %in% c("morning", "evening")]

make_stats <- function(dt, label) {
  data.frame(
    Panel = label,
    Mean = sprintf("%.3f", mean(dt$fatality_rate, na.rm = TRUE)),
    SD = sprintf("%.3f", sd(dt$fatality_rate, na.rm = TRUE)),
    Min = sprintf("%.3f", min(dt$fatality_rate, na.rm = TRUE)),
    Max = sprintf("%.3f", max(dt$fatality_rate, na.rm = TRUE)),
    N = format(nrow(dt), big.mark = ","),
    stringsAsFactors = FALSE
  )
}

stats_rows <- rbind(
  make_stats(tm[ca == 1 & post == 0], "CA, Morning, Pre-SB 328"),
  make_stats(tm[ca == 1 & post == 1], "CA, Morning, Post-SB 328"),
  make_stats(tm[ca == 0 & post == 0], "Other States, Morning, Pre"),
  make_stats(tm[ca == 0 & post == 1], "Other States, Morning, Post"),
  make_stats(panel[age_group == "teen" & hour_block == "evening" & ca == 1 & post == 0], "CA, Evening, Pre-SB 328"),
  make_stats(panel[age_group == "teen" & hour_block == "evening" & ca == 1 & post == 1], "CA, Evening, Post-SB 328")
)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Teen (15--19) Traffic Fatality Rates per 100,000}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccr}\n",
  "\\toprule\n",
  " & Mean & SD & Min & Max & N \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(stats_rows)) {
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
            stats_rows$Panel[i], stats_rows$Mean[i], stats_rows$SD[i],
            stats_rows$Min[i], stats_rows$Max[i], stats_rows$N[i]))
  if (i == 4) tab1_tex <- paste0(tab1_tex, "\\midrule\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Unit of observation is state $\\times$ month. ",
  "Fatality rate is computed as (fatalities / population) $\\times$ 100,000. ",
  "Morning hours are 6:00--8:59am; evening hours are 6:00--8:59pm. ",
  "Pre-SB 328: January 2015--June 2022. Post-SB 328: July 2022--December 2023. ",
  "Data: NHTSA FARS (2015--2023), Census ACS.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results
# ============================================================
cat("Generating Table 2: Main Results\n")

sdid_beta <- as.numeric(diagnostics$sdid_estimate)
sdid_se <- as.numeric(diagnostics$sdid_se)

twfe_beta <- as.numeric(coef(models$twfe1)["treat"])
twfe_se <- as.numeric(sqrt(vcov(models$twfe1)["treat", "treat"]))

ddd_beta <- as.numeric(coef(models$ddd_reg)["ddd_coef"])
ddd_se <- as.numeric(sqrt(vcov(models$ddd_reg)["ddd_coef", "ddd_coef"]))

pois_beta <- as.numeric(coef(models$pois1)["treat"])
pois_se <- as.numeric(sqrt(vcov(models$pois1)["treat", "treat"]))

school_beta <- as.numeric(coef(models$twfe_school)["treat"])
school_se <- as.numeric(sqrt(vcov(models$twfe_school)["treat", "treat"]))

make_stars <- function(beta, se) {
  beta <- as.numeric(beta)
  se <- as.numeric(se)
  if (is.na(se) || is.na(beta) || se == 0) return("")
  p <- 2 * pnorm(-abs(beta / se))
  if (p < 0.01) return("\\sym{***}")
  if (p < 0.05) return("\\sym{**}")
  if (p < 0.10) return("\\sym{*}")
  return("")
}

format_coef <- function(beta, se) {
  beta <- as.numeric(beta)
  stars <- make_stars(beta, se)
  sprintf("%.4f%s", beta, stars)
}

# Dep var means
pre_mean <- tm[post == 0, mean(fatality_rate, na.rm = TRUE)]

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of California SB 328 on Teen Morning Traffic Fatalities}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & SDID & TWFE & Triple-Diff & Poisson & School Only \\\\\n",
  "\\midrule\n",
  sprintf("CA $\\times$ Post & %s & %s & %s & %s & %s \\\\\n",
          format_coef(sdid_beta, sdid_se),
          format_coef(twfe_beta, twfe_se),
          format_coef(ddd_beta, ddd_se),
          format_coef(pois_beta, pois_se),
          format_coef(school_beta, school_se)),
  sprintf(" & %s & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          if (is.na(sdid_se)) "--" else sprintf("(%.4f)", sdid_se),
          twfe_se, ddd_se, pois_se, school_se),
  "\\midrule\n",
  "State FE & Yes & Yes & -- & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & -- & Yes & Yes \\\\\n",
  "Cell FE & -- & -- & Yes & -- & -- \\\\\n",
  sprintf("Dep.\\ var.\\ mean & %.3f & %.3f & -- & -- & %.3f \\\\\n",
          pre_mean, pre_mean, tm[post == 0 & school_session == 1, mean(fatality_rate, na.rm = TRUE)]),
  "Clustering & State & State & State & State & State \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(nrow(tm), big.mark = ","),
          format(nrow(tm), big.mark = ","),
          format(nrow(panel[age_group %in% c("teen","adult") & hour_block %in% c("morning","evening")]), big.mark = ","),
          format(nrow(tm), big.mark = ","),
          format(nrow(tm[school_session == 1]), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is teen (15--19) morning (6:00--8:59am) traffic fatality rate per 100,000 in columns (1), (2), and (5); ",
  "fatality count with population offset in column (4); and the triple-differenced rate in column (3). ",
  "Column (1) uses the synthetic difference-in-differences estimator (Arkhangelsky et al., 2021) with placebo variance. ",
  "Column (3) interacts CA $\\times$ Teen $\\times$ Morning $\\times$ Post with cell (state $\\times$ age-group $\\times$ hour-block) and month fixed effects. ",
  "Column (5) restricts to school-session months (September--May). ",
  "Standard errors clustered by state in parentheses. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Placebo Tests and Robustness
# ============================================================
cat("Generating Table 3: Placebo and Robustness\n")

plac_adult_b <- robustness$placebo_adult$beta
plac_adult_se <- robustness$placebo_adult$se
plac_eve_b <- robustness$placebo_evening$beta
plac_eve_se <- robustness$placebo_evening$se
wide_b <- robustness$twfe_wide$beta
wide_se <- robustness$twfe_wide$se
narrow_b <- robustness$twfe_narrow$beta
narrow_se <- robustness$twfe_narrow$se

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Placebo Tests and Robustness}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Adult Morning & Teen Evening & Wide Morning & Narrow Morning \\\\\n",
  " & (Placebo) & (Placebo) & (5--9am) & (7--8am) \\\\\n",
  "\\midrule\n",
  sprintf("CA $\\times$ Post & %s & %s & %s & %s \\\\\n",
          format_coef(plac_adult_b, plac_adult_se),
          format_coef(plac_eve_b, plac_eve_se),
          format_coef(wide_b, wide_se),
          format_coef(narrow_b, narrow_se)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          plac_adult_se, plac_eve_se, wide_se, narrow_se),
  "\\midrule\n",
  "State FE & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes \\\\\n",
  "Clustering & State & State & State & State \\\\\n",
  sprintf("Permutation $p$-value & & & %.3f & \\\\\n", robustness$permutation_p),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) replaces teen (15--19) fatalities with adult (25--54) fatalities during morning hours. ",
  "Column (2) uses teen fatalities during evening hours (6:00--8:59pm). ",
  "Both placebos should show null effects if SB 328 operates through the school-commute mechanism. ",
  "Column (3) widens the morning window to 5:00--9:59am; column (4) narrows it to 7:00--8:59am. ",
  "Permutation $p$-value reassigns treatment to each state in turn and computes the rank of California's estimate. ",
  "Standard errors clustered by state in parentheses. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_robustness.tex"))

# ============================================================
# Table 4: Hour-of-Day Distribution Shift
# ============================================================
cat("Generating Table 4: Hour Distribution\n")

hour_pre <- robustness$hour_dist_pre
hour_post <- robustness$hour_dist_post

# Focus on 5am-10am hours
morning_hours <- 5:10

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{California Teen Fatality Distribution Across Morning Hours (School Months)}\n",
  "\\label{tab:hours}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  "Hour & Pre-SB 328 & Share (\\%) & Post-SB 328 & Share (\\%) & $\\Delta$ Share (pp) \\\\\n",
  "\\midrule\n"
)

for (h in morning_hours) {
  pre_n <- hour_pre[HOUR == h, fat]
  post_n <- hour_post[HOUR == h, fat]
  pre_s <- hour_pre[HOUR == h, share] * 100
  post_s <- hour_post[HOUR == h, share] * 100
  delta <- post_s - pre_s

  tab4_tex <- paste0(tab4_tex,
    sprintf("%d:00--%d:59 & %d & %.1f & %d & %.1f & %+.1f \\\\\n",
            h, h, pre_n, pre_s, post_n, post_s, delta))
}

tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  sprintf("Total (all hours) & %d & 100.0 & %d & 100.0 & \\\\\n",
          sum(hour_pre$fat), sum(hour_post$fat)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Fatality counts and shares for California teens (15--19) during school months (September--May). ",
  "Pre-SB 328: 2015--2021; Post-SB 328: 2022--2023. ",
  "If SB 328 shifts commute timing, we expect a reduction in the share of fatalities at 6:00--7:59am ",
  "and a potential increase at 8:00--9:59am. ",
  "Data: NHTSA FARS.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_hours.tex"))

# ============================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================
cat("Generating Table F1: SDE\n")

pre_sd_y <- as.numeric(diagnostics$ca_pre_sd_y)
if (is.na(pre_sd_y) | pre_sd_y == 0) pre_sd_y <- as.numeric(diagnostics$pre_sd_y)

# Main outcomes for SDE
sde_rows <- list(
  list(
    outcome = "Morning fatality rate (SDID)",
    beta = as.numeric(diagnostics$sdid_estimate),
    se = as.numeric(diagnostics$sdid_se),
    sd_y = pre_sd_y
  ),
  list(
    outcome = "Morning fatality rate (TWFE)",
    beta = as.numeric(diagnostics$twfe_estimate),
    se = as.numeric(diagnostics$twfe_se),
    sd_y = pre_sd_y
  ),
  list(
    outcome = "Morning fatality rate (school months)",
    beta = as.numeric(coef(models$twfe_school)["treat"]),
    se = as.numeric(sqrt(vcov(models$twfe_school)["treat", "treat"])),
    sd_y = tm[post == 0 & school_session == 1, sd(fatality_rate, na.rm = TRUE)]
  )
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (row in sde_rows) {
  beta_n <- as.numeric(row$beta)
  se_n <- as.numeric(row$se)
  sdy_n <- as.numeric(row$sd_y)

  if (is.na(beta_n) || is.na(sdy_n) || sdy_n == 0) next

  sde_val <- beta_n / sdy_n
  sde_se <- if (!is.na(se_n)) se_n / sdy_n else NA_real_
  abs_sde <- abs(sde_val)

  classification <- if (abs_sde < 0.005) "Null"
    else if (abs_sde < 0.05 & sde_val > 0) "Small positive"
    else if (abs_sde < 0.05 & sde_val < 0) "Small negative"
    else if (abs_sde < 0.15 & sde_val > 0) "Moderate positive"
    else if (abs_sde < 0.15 & sde_val < 0) "Moderate negative"
    else if (sde_val > 0) "Large positive"
    else "Large negative"

  se_str <- if (is.na(sde_se)) "--" else sprintf("%.4f", sde_se)
  se_beta_str <- if (is.na(se_n)) "--" else sprintf("%.4f", se_n)

  tabF1_tex <- paste0(tabF1_tex,
    sprintf("%s & %.4f & %s & %.4f & %.4f & %s & %s \\\\\n",
            row$outcome, beta_n, se_beta_str, sdy_n, sde_val, se_str, classification))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does California's mandatory later school start time (SB 328, effective July 2022) reduce adolescent traffic fatalities during morning commute hours? ",
  "\\textbf{Policy mechanism:} SB 328 requires all public high schools to begin no earlier than 8:30am, shifting the school commute window approximately 30--60 minutes later and thereby reducing the overlap between drowsy teen driving and peak morning traffic. ",
  "\\textbf{Outcome definition:} Monthly state-level traffic fatality rate per 100,000 for persons aged 15--19 killed in motor vehicle crashes during morning hours (6:00--8:59am), from NHTSA FARS. ",
  "\\textbf{Treatment:} Binary; California after July 2022 vs.\\ all other states. ",
  "\\textbf{Data:} NHTSA Fatality Analysis Reporting System (FARS) person-level records, 2015--2023; Census ACS 1-year population estimates; 51 states (including DC) $\\times$ 108 months. ",
  "\\textbf{Method:} Synthetic Difference-in-Differences (Arkhangelsky et al., 2021) and two-way fixed effects with state and month fixed effects; standard errors clustered by state; permutation inference across 51 placebo states. ",
  "\\textbf{Sample:} All persons aged 15--19 killed in fatal motor vehicle crashes (FARS INJ\\_SEV = 4) during morning hours (6:00--8:59am) across all US states, 2015--2023. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the California monthly fatality rate. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(tabF1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
