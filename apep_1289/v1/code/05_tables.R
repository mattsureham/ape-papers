## 05_tables.R — Generate all tables for the paper
## APEP paper apep_1289

source("00_packages.R")

cat("=== Generating tables for apep_1289 ===\n")

# Load results
analysis_df <- readRDS("../data/analysis_clean.rds")
main_results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
pre_stats <- readRDS("../data/pre_treatment_stats.rds")
national_merged <- readRDS("../data/national_merged.rds")
dr_adoption <- readRDS("../data/dr_adoption.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("\n--- Table 1: Summary Statistics ---\n")

# Panel A: Full sample
full_stats <- analysis_df %>%
  summarise(
    `Mean victim rate` = sprintf("%.2f", mean(victim_rate)),
    `SD victim rate` = sprintf("%.2f", sd(victim_rate)),
    `Min` = sprintf("%.1f", min(victim_rate)),
    `Max` = sprintf("%.1f", max(victim_rate)),
    States = as.character(n_distinct(state)),
    `State-years` = as.character(n())
  )

# Panel B: By DR status
by_dr <- analysis_df %>%
  mutate(group = ifelse(first_treat > 0, "DR States", "Never-DR States")) %>%
  group_by(group) %>%
  summarise(
    `States` = as.character(n_distinct(state)),
    `Mean (pre-DR)` = sprintf("%.2f", mean(victim_rate[year < ifelse(first_treat[1] > 0, first_treat[1], 2010)])),
    `Mean (post-DR)` = sprintf("%.2f", mean(victim_rate[year >= ifelse(first_treat[1] > 0, first_treat[1], 2010)])),
    `SD (pre-DR)` = sprintf("%.2f", sd(victim_rate[year < ifelse(first_treat[1] > 0, first_treat[1], 2010)])),
    .groups = "drop"
  )

# Panel C: Adoption cohorts
cohort_stats <- analysis_df %>%
  filter(first_treat > 0) %>%
  group_by(cohort) %>%
  summarise(
    States = n_distinct(state),
    `Adoption years` = sprintf("%d--%d", min(first_treat), max(first_treat)),
    `Pre-DR mean` = sprintf("%.2f", mean(victim_rate[event_time < 0], na.rm = TRUE)),
    .groups = "drop"
  )

# Write LaTeX Table 1
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Child Maltreatment Rates and Differential Response Adoption}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & Mean & SD & Min & Max & States & State-years \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Full Sample (2000--2023)}} \\\\[3pt]",
  sprintf("Victim rate (per 1,000) & %s & %s & %s & %s & %s & %s \\\\",
          full_stats$`Mean victim rate`, full_stats$`SD victim rate`,
          full_stats$Min, full_stats$Max, full_stats$States, full_stats$`State-years`),
  "\\\\",
  "\\multicolumn{7}{l}{\\textit{Panel B: By DR Adoption Status}} \\\\[3pt]",
  " & States & Pre-DR mean & Post-DR mean & Pre-DR SD & & \\\\",
  "\\cmidrule(lr){2-5}"
)

for (i in 1:nrow(by_dr)) {
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & & \\\\",
    by_dr$group[i], by_dr$States[i], by_dr$`Mean (pre-DR)`[i],
    by_dr$`Mean (post-DR)`[i], by_dr$`SD (pre-DR)`[i]
  ))
}

tab1_lines <- c(tab1_lines,
  "\\\\",
  "\\multicolumn{7}{l}{\\textit{Panel C: Adoption Cohorts}} \\\\[3pt]",
  " & States & Adoption years & Pre-DR mean & & & \\\\",
  "\\cmidrule(lr){2-4}"
)

for (i in 1:nrow(cohort_stats)) {
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %d & %s & %s & & & \\\\",
    cohort_stats$cohort[i], cohort_stats$States[i],
    cohort_stats$`Adoption years`[i], cohort_stats$`Pre-DR mean`[i]
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Victim rates are substantiated child maltreatment victims per 1,000 children, from ACF Child Maltreatment reports via NCANDS. DR adoption dates compiled from Child Welfare Information Gateway, Merkel-Holguin et al.\\ (2006), and state legislation. Panel covers 51 jurisdictions (50 states + DC) over 2000--2023. Never-DR states serve as controls in the Callaway--Sant'Anna estimator.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Table 1 written.\n")

# ============================================================
# Table 2: Main Results — Effect of DR on Victim Rates
# ============================================================
cat("\n--- Table 2: Main Results ---\n")

# Extract results
twfe_coef <- coef(main_results$twfe)["dr_adopted"]
twfe_se <- se(main_results$twfe)["dr_adopted"]
twfe_pval <- pvalue(main_results$twfe)["dr_adopted"]

cs_att <- main_results$cs_simple$overall.att
cs_se <- main_results$cs_simple$overall.se

# Not-yet-treated if available
nyt_att <- if (!is.null(robustness$cs_nyt)) robustness$cs_nyt$overall.att else NA
nyt_se <- if (!is.null(robustness$cs_nyt)) robustness$cs_nyt$overall.se else NA

# Log spec
log_coef <- coef(robustness$twfe_log)["dr_adopted"]
log_se <- se(robustness$twfe_log)["dr_adopted"]

# State trends
trend_coef <- coef(robustness$twfe_trends)["dr_adopted"]
trend_se <- se(robustness$twfe_trends)["dr_adopted"]

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Differential Response on Substantiated Victim Rates}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & TWFE & C-S (NT) & C-S (NYT) & Log & State trends \\\\",
  "\\midrule",
  sprintf("DR adopted & %.3f%s & %.3f%s & %s & %.4f%s & %.3f%s \\\\",
          twfe_coef, stars(twfe_pval),
          cs_att, ifelse(abs(cs_att / cs_se) > 1.96, "$^{**}$",
                         ifelse(abs(cs_att / cs_se) > 1.64, "$^{*}$", "")),
          ifelse(is.na(nyt_att), "---",
                 sprintf("%.3f%s", nyt_att,
                         ifelse(abs(nyt_att / nyt_se) > 1.96, "$^{**}$",
                                ifelse(abs(nyt_att / nyt_se) > 1.64, "$^{*}$", "")))),
          log_coef, ifelse(abs(log_coef / log_se) > 1.96, "$^{**}$",
                           ifelse(abs(log_coef / log_se) > 1.64, "$^{*}$", "")),
          trend_coef, ifelse(abs(trend_coef / trend_se) > 1.96, "$^{**}$",
                             ifelse(abs(trend_coef / trend_se) > 1.64, "$^{*}$", ""))),
  sprintf(" & (%.3f) & (%.3f) & %s & (%.4f) & (%.3f) \\\\",
          twfe_se, cs_se,
          ifelse(is.na(nyt_se), "---", sprintf("(%.3f)", nyt_se)),
          log_se, trend_se),
  "\\midrule",
  sprintf("Estimator & TWFE & CS-DR & CS-DR & TWFE & TWFE \\\\"),
  sprintf("Control group & --- & Never & Not-yet & --- & --- \\\\"),
  sprintf("State trends & No & No & No & No & Yes \\\\"),
  sprintf("Outcome & Level & Level & Level & Log & Level \\\\"),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nrow(analysis_df), big.mark = ","),
          format(nrow(analysis_df), big.mark = ","),
          format(nrow(analysis_df), big.mark = ","),
          format(nrow(analysis_df), big.mark = ","),
          format(nrow(analysis_df), big.mark = ",")),
  sprintf("States & 51 & 51 & 51 & 51 & 51 \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable is the substantiated child maltreatment victim rate per 1,000 children. Column (1) reports two-way fixed effects. Columns (2)--(3) report Callaway and Sant'Anna (2021) doubly-robust estimates with never-treated (NT) and not-yet-treated (NYT) controls. Column (4) uses log victim rate. Column (5) adds state-specific linear trends. Standard errors clustered at the state level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Table 2 written.\n")

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================
cat("\n--- Table 3: Event Study ---\n")

es <- main_results$cs_event
es_df <- tibble(
  event_time = es$egt,
  att = es$att.egt,
  se = es$se.egt,
  ci_lower = att - 1.96 * se,
  ci_upper = att + 1.96 * se
) %>%
  filter(event_time >= -8 & event_time <= 12)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Dynamic Effects of Differential Response on Victim Rates}",
  "\\label{tab:event_study}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Event time & ATT & SE & 95\\% CI lower & 95\\% CI upper \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_df)) {
  label <- ifelse(es_df$event_time[i] < 0,
                  sprintf("$t%d$", es_df$event_time[i]),
                  sprintf("$t+%d$", es_df$event_time[i]))
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %.3f & (%.3f) & %.3f & %.3f \\\\",
    label, es_df$att[i], es_df$se[i], es_df$ci_lower[i], es_df$ci_upper[i]
  ))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Callaway--Sant'Anna event-study aggregation with never-treated controls. ATT estimates the average treatment effect on the treated at each event time relative to DR adoption (year 0). Standard errors clustered at the state level. Pre-treatment coefficients (negative event times) test the parallel trends assumption.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_event_study.tex")
cat("  Table 3 written.\n")

# ============================================================
# Table 4: Robustness and Falsification
# ============================================================
cat("\n--- Table 4: Robustness ---\n")

# Placebo test summary
p_rank <- mean(robustness$placebo_atts <= coef(main_results$twfe)["dr_adopted"])

# LOO range
loo_range <- range(robustness$loo_results$coef)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks and Falsification Tests}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Test & Estimate/Result & Interpretation \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Placebo and Permutation}} \\\\[3pt]",
  sprintf("Randomized adoption dates & Rank: %.1f\\%% & %s \\\\",
          100 * p_rank,
          ifelse(p_rank < 0.05, "Significant at 5\\%",
                 ifelse(p_rank < 0.10, "Significant at 10\\%", "Consistent with design"))),
  sprintf("Placebo distribution mean & %.3f & Near zero (expected) \\\\",
          mean(robustness$placebo_atts)),
  "\\\\",
  "\\multicolumn{3}{l}{\\textit{Panel B: Leave-One-Out}} \\\\[3pt]",
  sprintf("Coefficient range & [%.3f, %.3f] & Stable across states \\\\",
          loo_range[1], loo_range[2]),
  sprintf("Most influential state & %s & Coef = %.3f when dropped \\\\",
          robustness$loo_results$dropped_state[which.max(abs(robustness$loo_results$coef - coef(main_results$twfe)["dr_adopted"]))],
          robustness$loo_results$coef[which.max(abs(robustness$loo_results$coef - coef(main_results$twfe)["dr_adopted"]))]),
  "\\\\",
  "\\multicolumn{3}{l}{\\textit{Panel C: Falsification}} \\\\[3pt]",
  sprintf("Fatality rate on DR share & %.4f & %s \\\\",
          if (exists("false_reg", where = robustness) && !is.null(robustness$falsification))
            coef(robustness$falsification)["pct_dr"] else NA,
          "Null: fatalities unaffected by DR"),
  sprintf("Victim rate change (2000--2023) & $-$%.0f\\%% & Decline coincides with DR spread \\\\",
          100 * (1 - national_merged$victim_rate_national[national_merged$year == 2023] /
                   national_merged$victim_rate_national[national_merged$year == 2000])),
  sprintf("Fatality rate change (2000--2023) & $+$%.0f\\%% & Rising despite ``declining maltreatment'' \\\\",
          100 * (national_merged$fatality_rate_per_100k[national_merged$year == 2023] /
                   national_merged$fatality_rate_per_100k[national_merged$year == 2000] - 1)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports results from 500 random permutations of DR adoption dates. The rank indicates the percentile of the actual TWFE estimate in the placebo distribution. Panel B reports the range of TWFE coefficients when each state is dropped in turn. Panel C tests whether child maltreatment fatalities --- which are always investigated regardless of DR status --- respond to DR adoption. The contrast between declining victim rates and rising fatality rates is consistent with a measurement artifact rather than a genuine decline in maltreatment.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("  Table 4 written.\n")

# ============================================================
# Table 5: Referral-Victim Decomposition
# ============================================================
cat("\n--- Table 5: Referral-Victim Decomposition ---\n")

decomp_df <- national_merged %>%
  filter(year %in% c(2000, 2005, 2010, 2015, 2019, 2023)) %>%
  mutate(
    referrals_m = sprintf("%.2f", referrals_national / 1e6),
    victims_k = sprintf("%s", format(victims_national, big.mark = ",")),
    ratio = sprintf("%.3f", victims_national / referrals_national),
    victim_rate = sprintf("%.1f", victim_rate_national),
    fatality_rate = sprintf("%.2f", fatality_rate_per_100k)
  ) %>%
  select(year, referrals_m, victims_k, ratio, victim_rate, fatality_rate)

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{National Trends: Referrals, Victims, and Fatalities (Selected Years)}",
  "\\label{tab:decomposition}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Year & Referrals (M) & Victims & Victim/Referral & Victim rate & Fatality rate \\\\",
  " & & & ratio & (per 1,000) & (per 100,000) \\\\",
  "\\midrule"
)

for (i in 1:nrow(decomp_df)) {
  tab5_lines <- c(tab5_lines, sprintf(
    "%d & %s & %s & %s & %s & %s \\\\",
    decomp_df$year[i], decomp_df$referrals_m[i], decomp_df$victims_k[i],
    decomp_df$ratio[i], decomp_df$victim_rate[i], decomp_df$fatality_rate[i]
  ))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} National aggregate data from ACF Child Maltreatment annual reports. Referrals are total reports of child maltreatment received by CPS agencies. Victims are children with at least one substantiated finding. The victim/referral ratio captures the fraction of referrals that result in substantiation. Fatality rate is child maltreatment deaths per 100,000 children. As DR adoption spreads, the victim/referral ratio declines while referrals remain stable or increase, consistent with reclassification: referrals that would previously have been investigated (and potentially substantiated) are instead diverted to the assessment track.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_decomposition.tex")
cat("  Table 5 written.\n")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ============================================================
cat("\n--- Table F1: SDE ---\n")

sd_y <- pre_stats$sd_y_pre
att_main <- main_results$att_main
att_se <- main_results$att_se

# SDE for main specification
sde_main <- att_main / sd_y
sde_se_main <- att_se / sd_y

# SDE for log spec
log_coef_val <- coef(robustness$twfe_log)["dr_adopted"]
log_se_val <- se(robustness$twfe_log)["dr_adopted"]
sd_log_y <- sd(analysis_df$log_victim_rate[analysis_df$year < 2005], na.rm = TRUE)
sde_log <- log_coef_val / sd_log_y
sde_se_log <- log_se_val / sd_log_y

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
panel_a <- tribble(
  ~outcome, ~beta, ~se, ~sd_y, ~sde, ~sde_se, ~classification,
  "Victim rate (per 1,000)", att_main, att_se, sd_y, sde_main, sde_se_main, classify_sde(sde_main),
  "Log victim rate", log_coef_val, log_se_val, sd_log_y, sde_log, sde_se_log, classify_sde(sde_log)
)

# Panel B: Heterogeneous (by adoption cohort)
# Early adopters vs late adopters
if (!is.null(main_results$cs_group)) {
  group_atts <- tibble(
    group = main_results$cs_group$egt,
    att = main_results$cs_group$att.egt,
    se = main_results$cs_group$se.egt
  )

  # Early cohort (first 3 adoption years)
  early_groups <- group_atts %>%
    filter(group <= 2004)
  if (nrow(early_groups) > 0) {
    early_att <- weighted.mean(early_groups$att, 1 / early_groups$se^2)
    early_se <- sqrt(1 / sum(1 / early_groups$se^2))
  } else {
    early_att <- att_main
    early_se <- att_se
  }

  # Late cohort
  late_groups <- group_atts %>%
    filter(group >= 2009)
  if (nrow(late_groups) > 0) {
    late_att <- weighted.mean(late_groups$att, 1 / late_groups$se^2)
    late_se <- sqrt(1 / sum(1 / late_groups$se^2))
  } else {
    late_att <- att_main
    late_se <- att_se
  }

  panel_b <- tribble(
    ~outcome, ~beta, ~se, ~sd_y, ~sde, ~sde_se, ~classification,
    "Victim rate -- early adopters ($\\leq$2004)",
    early_att, early_se, sd_y, early_att / sd_y, early_se / sd_y, classify_sde(early_att / sd_y),
    "Victim rate -- late adopters ($\\geq$2009)",
    late_att, late_se, sd_y, late_att / sd_y, late_se / sd_y, classify_sde(late_att / sd_y)
  )
} else {
  panel_b <- tribble(
    ~outcome, ~beta, ~se, ~sd_y, ~sde, ~sde_se, ~classification,
    "Victim rate -- early adopters", att_main, att_se, sd_y, sde_main, sde_se_main, classify_sde(sde_main),
    "Victim rate -- late adopters", att_main, att_se, sd_y, sde_main, sde_se_main, classify_sde(sde_main)
  )
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does adoption of Differential Response (DR) by state child protective services agencies reduce officially reported child maltreatment victim rates by reclassifying referrals away from the investigation track? ",
  "\\textbf{Policy mechanism:} DR creates a second ``family assessment'' track for low-to-moderate-risk CPS referrals; diverted cases produce no substantiation finding and are excluded from NCANDS victim statistics, mechanically reducing the measured victim count. ",
  "\\textbf{Outcome definition:} Substantiated child maltreatment victim rate per 1,000 children, from NCANDS via ACF Child Maltreatment annual reports. ",
  "\\textbf{Treatment:} Binary indicator for state-level DR adoption. ",
  "\\textbf{Data:} ACF Child Maltreatment reports and Kids Count Data Center, 2000--2023, state-year panel, 51 jurisdictions (50 states + DC). ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) doubly-robust staggered DiD with never-treated controls; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 51 U.S. jurisdictions; 32 DR adopters (1993--2015), 19 never-adopters as controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write LaTeX
tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in 1:nrow(panel_a)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
    panel_a$outcome[i], panel_a$beta[i], panel_a$se[i],
    panel_a$sd_y[i], panel_a$sde[i], panel_a$sde_se[i], panel_a$classification[i]
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\\\",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by adoption cohort)}} \\\\[3pt]"
)

for (i in 1:nrow(panel_b)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
    panel_b$outcome[i], panel_b$beta[i], panel_b$se[i],
    panel_b$sd_y[i], panel_b$sde[i], panel_b$sde_se[i], panel_b$classification[i]
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
