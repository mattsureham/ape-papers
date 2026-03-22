## =============================================================================
## 05_tables.R — Generate all tables including SDE appendix
## apep_0762
## =============================================================================

source("00_packages.R")

cat("=== Loading results ===\n")
df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
overall_stats <- readRDS("../data/overall_stats.rds")

## ---- Table 1: Summary Statistics ----
cat("\n=== Table 1: Summary Statistics ===\n")

sumstats_treated <- df %>%
  filter(treated == 1) %>%
  summarize(
    mean_zhvi = mean(zhvi, na.rm = TRUE),
    sd_zhvi = sd(zhvi, na.rm = TRUE),
    mean_log_zhvi = mean(log_zhvi, na.rm = TRUE),
    sd_log_zhvi = sd(log_zhvi, na.rm = TRUE),
    n_obs = n(),
    n_zips = n_distinct(zip_code)
  )

sumstats_control <- df %>%
  filter(treated == 0) %>%
  summarize(
    mean_zhvi = mean(zhvi, na.rm = TRUE),
    sd_zhvi = sd(zhvi, na.rm = TRUE),
    mean_log_zhvi = mean(log_zhvi, na.rm = TRUE),
    sd_log_zhvi = sd(log_zhvi, na.rm = TRUE),
    n_obs = n(),
    n_zips = n_distinct(zip_code)
  )

tab1_tex <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{Treated} & \\multicolumn{2}{c}{Control} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Variable & Mean & SD & Mean & SD \\\\
\\midrule
ZHVI (\\$) & %s & %s & %s & %s \\\\
log(ZHVI) & %.2f & %.2f & %.2f & %.2f \\\\
\\midrule
Zip codes & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
Zip-year observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Sample includes %d treated zip codes in DarkSky International certified communities and %d matched control zip codes. Panel spans %d--%d. ZHVI is the Zillow Home Value Index (smoothed, seasonally adjusted median home value). Controls selected via nearest-neighbor matching on pre-treatment log(ZHVI).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  format(round(sumstats_treated$mean_zhvi), big.mark = ","),
  format(round(sumstats_treated$sd_zhvi), big.mark = ","),
  format(round(sumstats_control$mean_zhvi), big.mark = ","),
  format(round(sumstats_control$sd_zhvi), big.mark = ","),
  sumstats_treated$mean_log_zhvi, sumstats_treated$sd_log_zhvi,
  sumstats_control$mean_log_zhvi, sumstats_control$sd_log_zhvi,
  sumstats_treated$n_zips, sumstats_control$n_zips,
  format(sumstats_treated$n_obs, big.mark = ","),
  format(sumstats_control$n_obs, big.mark = ","),
  sumstats_treated$n_zips, sumstats_control$n_zips,
  min(df$year), max(df$year)
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Written: tab1_summary.tex\n")

## ---- Table 2: Main Results ----
cat("\n=== Table 2: Main Results ===\n")

agg <- results$agg_simple
twfe <- results$twfe
agg_levels <- robustness$levels

# Extract TWFE coefficient and SE
twfe_coef <- coef(twfe)["post"]
twfe_se <- sqrt(diag(vcov(twfe)))["post"]

# Stars function
stars <- function(est, se) {
  t <- abs(est / se)
  if (t > 2.576) return("***")
  if (t > 1.96) return("**")
  if (t > 1.645) return("*")
  return("")
}

tab2_tex <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Effect of Dark Sky Designation on Home Values}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
 & (1) & (2) & (3) \\\\
 & CS-DiD & TWFE & CS-DiD (Levels) \\\\
\\midrule
Dark Sky Designation & %.4f%s & %.4f%s & %s%s \\\\
 & (%.4f) & (%.4f) & (%s) \\\\
\\\\
Percent effect & %.1f\\%%%% &  %.1f\\%%%% & --- \\\\
Dollar effect & --- & --- & \\$%s \\\\
\\\\
Zip codes & %d & %d & %d \\\\
Observations & %s & %s & %s \\\\
Estimator & CS (2021) & TWFE & CS (2021) \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (1) reports the overall ATT from \\citet{callaway2021difference} using never-treated controls and doubly robust estimation. Column (2) reports two-way fixed effects with zip code and year fixed effects, standard errors clustered at the zip-code level. Column (3) reports CS-DiD with ZHVI in levels (dollars). The percent effect in columns (1)--(2) is $100 \\times (e^{\\hat{\\beta}} - 1)$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  agg$overall.att, stars(agg$overall.att, agg$overall.se),
  twfe_coef, stars(twfe_coef, twfe_se),
  format(round(agg_levels$att), big.mark = ","), stars(agg_levels$att, agg_levels$se),
  agg$overall.se, twfe_se,
  format(round(agg_levels$se), big.mark = ","),
  (exp(agg$overall.att) - 1) * 100,
  (exp(twfe_coef) - 1) * 100,
  format(round(agg_levels$att), big.mark = ","),
  n_distinct(df$zip_code), n_distinct(df$zip_code), n_distinct(df$zip_code),
  format(nrow(df), big.mark = ","),
  format(nrow(df), big.mark = ","),
  format(nrow(df), big.mark = ",")
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("  Written: tab2_main.tex\n")

## ---- Table 3: Event Study ----
cat("\n=== Table 3: Event Study Estimates ===\n")

es_df <- results$es_df

# Format event study table
es_rows <- ""
for (i in 1:nrow(es_df)) {
  e <- es_df[i, ]
  star <- stars(e$att, e$se)
  es_rows <- paste0(es_rows, sprintf(
    "  $t%+d$ & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\\n",
    e$event_time, e$att, star, e$se, e$ci_lower, e$ci_upper
  ))
}

tab3_tex <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Event Study: Dynamic Treatment Effects}
\\label{tab:event_study}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Event Time & ATT & SE & 95\\%% CI \\\\
\\midrule
%s\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dynamic treatment effect estimates from \\citet{callaway2021difference}. Event time 0 is the year of Dark Sky Community certification. Never-treated zip codes serve as controls. Doubly robust estimation. Confidence intervals are pointwise.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}', es_rows)

writeLines(tab3_tex, "../tables/tab3_event_study.tex")
cat("  Written: tab3_event_study.tex\n")

## ---- Table 4: Robustness ----
cat("\n=== Table 4: Robustness Checks ===\n")

rob <- robustness

tab4_tex <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Specification & ATT & SE \\\\
\\midrule
\\textit{Main result (CS-DiD, never-treated)} & %.4f & (%.4f) \\\\
\\\\
\\textit{Alternative control group} & & \\\\
\\quad Not-yet-treated & %.4f & (%.4f) \\\\
\\\\
\\textit{Sample restrictions} & & \\\\
\\quad Excluding tourism hubs & %s & %s \\\\
\\\\
\\textit{Specification checks} & & \\\\
\\quad 1-year anticipation & %.4f & (%.4f) \\\\
\\quad ZHVI in levels (\\$) & %s & (%s) \\\\
\\\\
\\textit{Placebo check} & & \\\\
\\quad 5-year early treatment & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All specifications use \\citet{callaway2021difference} with doubly robust estimation unless noted. ``Tourism hubs" excludes Flagstaff, Sedona, and Tucson. Placebo shifts treatment dates 5 years earlier and estimates effects during the pre-treatment period only. Main result randomization inference p-value (999 permutations): %s.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  results$agg_simple$overall.att, results$agg_simple$overall.se,
  rob$nyt$att, rob$nyt$se,
  ifelse(is.na(rob$no_tourism$att), "---", sprintf("%.4f", rob$no_tourism$att)),
  ifelse(is.na(rob$no_tourism$se), "---", sprintf("(%.4f)", rob$no_tourism$se)),
  rob$anticipation$att, rob$anticipation$se,
  format(round(rob$levels$att), big.mark = ","),
  format(round(rob$levels$se), big.mark = ","),
  ifelse(is.na(rob$placebo$att), "---", sprintf("%.4f", rob$placebo$att)),
  ifelse(is.na(rob$placebo$se), "---", sprintf("(%.4f)", rob$placebo$se)),
  ifelse(!is.null(rob$wcb), sprintf("%.3f", rob$wcb$p_val), "---")  # RI p-value
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("  Written: tab4_robustness.tex\n")

## ---- Table 5: Group-level heterogeneity ----
cat("\n=== Table 5: Heterogeneity by Cohort ===\n")

group_df <- results$group_df

group_rows <- ""
for (i in 1:nrow(group_df)) {
  g <- group_df[i, ]
  star <- stars(g$att, g$se)
  pct <- (exp(g$att) - 1) * 100
  group_rows <- paste0(group_rows, sprintf(
    "  %d & %.4f%s & (%.4f) & %.1f\\%%%% \\\\\n",
    g$group, g$att, star, g$se, pct
  ))
}

tab5_tex <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Heterogeneity by Certification Cohort}
\\label{tab:heterogeneity}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Cohort (Year) & ATT & SE & Percent Effect \\\\
\\midrule
%s\\midrule
Overall & %.4f & (%.4f) & %.1f\\%%%% \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Group-specific ATTs from \\citet{callaway2021difference}. Each row reports the average treatment effect for zip codes whose community received Dark Sky certification in the indicated year. Doubly robust estimation with never-treated controls.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  group_rows,
  results$agg_simple$overall.att, results$agg_simple$overall.se,
  (exp(results$agg_simple$overall.att) - 1) * 100
)

writeLines(tab5_tex, "../tables/tab5_heterogeneity.tex")
cat("  Written: tab5_heterogeneity.tex\n")

## ---- SDE Table (MANDATORY) ----
cat("\n=== SDE Table ===\n")

beta_main <- results$agg_simple$overall.att
se_main <- results$agg_simple$overall.se
sd_y <- sd(df$log_zhvi, na.rm = TRUE)

sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

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

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does certification as an International Dark Sky Community --- requiring ",
  "adoption of a legally enforceable outdoor lighting ordinance --- increase residential property values? ",
  "\\textbf{Policy mechanism:} DarkSky International certification requires communities to pass legally binding ",
  "outdoor lighting codes that mandate shielded fixtures, limit lumens, restrict color temperature, and impose ",
  "curfews on decorative lighting; compliance is verified through on-site audits and annual reporting. ",
  "\\textbf{Outcome definition:} Zillow Home Value Index (ZHVI), the smoothed seasonally adjusted median home ",
  "value estimate at the zip-code level, measured in natural logarithm. ",
  "\\textbf{Treatment:} Binary --- zip code is in a community that received Dark Sky certification versus ",
  "never-certified matched control. ",
  "\\textbf{Data:} Zillow Research ZHVI zip-level monthly panel, annualized to January observations, ",
  "%d--%d, with %d treated and %d control zip codes (%s zip-year observations). ",
  "\\textbf{Method:} Staggered difference-in-differences using \\citet{callaway2021difference} with ",
  "doubly robust estimation, never-treated controls, and varying base period. ",
  "\\textbf{Sample:} Treated zip codes are those in the 29 US communities certified by DarkSky International ",
  "(2001--2023); controls selected via nearest-neighbor matching on pre-treatment log(ZHVI) within state. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of log(ZHVI). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (.05$--.15$), Small (.005$--.05$), Null ($< 0.005$)."
)

sde_notes <- sprintf(sde_notes,
  min(df$year), max(df$year),
  n_distinct(df$zip_code[df$treated == 1]),
  n_distinct(df$zip_code[df$treated == 0]),
  format(nrow(df), big.mark = ",")
)

sde_tex <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
log(ZHVI) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  beta_main, se_main, sd_y, sde_main, se_sde_main, class_main,
  sde_notes
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat(sprintf("  SDE: %.4f (%s)\n", sde_main, class_main))
cat("  Written: tabF1_sde.tex\n")

cat("\n  ALL TABLES DONE.\n")
