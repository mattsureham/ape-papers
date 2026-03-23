## =============================================================================
## 05_tables.R — Generate all tables including SDE
## apep_0778
## =============================================================================

source("00_packages.R")

cat("=== Loading results ===\n")
df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

stars <- function(est, se) {
  t <- abs(est / se)
  if (t > 2.576) return("***")
  if (t > 1.96) return("**")
  if (t > 1.645) return("*")
  return("")
}

## ---- Table 1: Summary Statistics ----
cat("\n=== Table 1: Summary Statistics ===\n")

ss_treat <- df %>% filter(treated == 1) %>%
  summarize(n = n_distinct(state_abbr), obs = n(),
            m_rate = mean(snap_rate), s_rate = sd(snap_rate),
            m_hh = mean(snap_hh), s_hh = sd(snap_hh),
            m_tot = mean(total_hh), s_tot = sd(total_hh))
ss_ctrl <- df %>% filter(treated == 0) %>%
  summarize(n = n_distinct(state_abbr), obs = n(),
            m_rate = mean(snap_rate), s_rate = sd(snap_rate),
            m_hh = mean(snap_hh), s_hh = sd(snap_hh),
            m_tot = mean(total_hh), s_tot = sd(total_hh))

tab1 <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{Treated} & \\multicolumn{2}{c}{Never-Treated} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Variable & Mean & SD & Mean & SD \\\\
\\midrule
SNAP participation rate & %.3f & %.3f & %.3f & %.3f \\\\
SNAP households & %s & %s & %s & %s \\\\
Total households & %s & %s & %s & %s \\\\
\\midrule
States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
State-year observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} SNAP participation rate is the share of households receiving SNAP benefits in the past 12 months (ACS 1-year estimates). Treated states adopted transitional SNAP benefits between 2001 and 2016 (24 states). Never-treated states had not adopted by 2023 (27 states). Panel covers 2005--2023.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  ss_treat$m_rate, ss_treat$s_rate, ss_ctrl$m_rate, ss_ctrl$s_rate,
  format(round(ss_treat$m_hh), big.mark=","), format(round(ss_treat$s_hh), big.mark=","),
  format(round(ss_ctrl$m_hh), big.mark=","), format(round(ss_ctrl$s_hh), big.mark=","),
  format(round(ss_treat$m_tot), big.mark=","), format(round(ss_treat$s_tot), big.mark=","),
  format(round(ss_ctrl$m_tot), big.mark=","), format(round(ss_ctrl$s_tot), big.mark=","),
  ss_treat$n, ss_ctrl$n,
  format(ss_treat$obs, big.mark=","), format(ss_ctrl$obs, big.mark=","))

writeLines(tab1, "../tables/tab1_summary.tex")
cat("  Written: tab1_summary.tex\n")

## ---- Table 2: Main Results ----
cat("\n=== Table 2: Main Results ===\n")

agg_rate <- results$agg_rate
agg_log <- results$agg_log
twfe_r <- results$twfe_rate
twfe_l <- results$twfe_log

twfe_r_coef <- coef(twfe_r)["post"]
twfe_r_se <- sqrt(diag(vcov(twfe_r)))["post"]
twfe_l_coef <- coef(twfe_l)["post"]
twfe_l_se <- sqrt(diag(vcov(twfe_l)))["post"]

tab2 <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Effect of Transitional SNAP Benefits on SNAP Participation}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & CS-DiD & TWFE & CS-DiD & TWFE \\\\
 & SNAP Rate & SNAP Rate & log(SNAP HH) & log(SNAP HH) \\\\
\\midrule
Transitional Benefits & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\
 & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\
\\\\
States & %d & %d & %d & %d \\\\
State-years & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Columns (1) and (3) report the overall ATT from \\citet{callaway2021difference} using never-treated controls and doubly robust estimation. Columns (2) and (4) report two-way fixed effects with state and year fixed effects, standard errors clustered at the state level. SNAP rate is the share of households receiving SNAP (ACS). log(SNAP HH) is the natural log of SNAP-receiving households.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  agg_rate$overall.att, stars(agg_rate$overall.att, agg_rate$overall.se),
  twfe_r_coef, stars(twfe_r_coef, twfe_r_se),
  agg_log$overall.att, stars(agg_log$overall.att, agg_log$overall.se),
  twfe_l_coef, stars(twfe_l_coef, twfe_l_se),
  agg_rate$overall.se, twfe_r_se, agg_log$overall.se, twfe_l_se,
  n_distinct(df$state_abbr), n_distinct(df$state_abbr),
  n_distinct(df$state_abbr), n_distinct(df$state_abbr),
  format(nrow(df), big.mark=","), format(nrow(df), big.mark=","),
  format(nrow(df), big.mark=","), format(nrow(df), big.mark=","))

writeLines(tab2, "../tables/tab2_main.tex")
cat("  Written: tab2_main.tex\n")

## ---- Table 3: Event Study ----
cat("\n=== Table 3: Event Study ===\n")

es_df <- results$es_df
es_rows <- ""
for (i in 1:nrow(es_df)) {
  e <- es_df[i,]
  star <- stars(e$att, e$se)
  es_rows <- paste0(es_rows, sprintf(
    "  $t%+d$ & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\\n",
    e$event_time, e$att, star, e$se, e$ci_lower, e$ci_upper))
}

tab3 <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Event Study: Dynamic Treatment Effects on SNAP Rate}
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
\\item \\textit{Notes:} Dynamic treatment effects from \\citet{callaway2021difference}. Event time 0 is the year of transitional benefits adoption. Never-treated states serve as controls. Doubly robust estimation. Outcome is SNAP participation rate (share of households receiving SNAP).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}', es_rows)

writeLines(tab3, "../tables/tab3_event_study.tex")
cat("  Written: tab3_event_study.tex\n")

## ---- Table 4: Robustness ----
cat("\n=== Table 4: Robustness ===\n")

rob <- robustness
tab4 <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Specification & ATT & SE \\\\
\\midrule
\\textit{Main (CS-DiD, never-treated)} & %.4f & (%.4f) \\\\
\\\\
\\textit{Alternative controls} & & \\\\
\\quad Not-yet-treated & %.4f & (%.4f) \\\\
\\\\
\\textit{Sample restrictions} & & \\\\
\\quad 2006+ cohorts only & %.4f & (%.4f) \\\\
\\quad Excl.\\ Great Recession (2008--2010) & %s & %s \\\\
\\\\
\\textit{Specification} & & \\\\
\\quad 1-year anticipation & %.4f & (%.4f) \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All specifications use \\citet{callaway2021difference} with doubly robust estimation unless noted. ``2006+ cohorts only" excludes states that adopted before the ACS data window (2005). Randomization inference p-value (TWFE): %.3f.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  results$agg_rate$overall.att, results$agg_rate$overall.se,
  rob$nyt$att, rob$nyt$se,
  rob$late_only$att, rob$late_only$se,
  ifelse(is.na(rob$no_gr$att), "---", sprintf("%.4f", rob$no_gr$att)),
  ifelse(is.na(rob$no_gr$se), "---", sprintf("(%.4f)", rob$no_gr$se)),
  rob$anticipation$att, rob$anticipation$se,
  rob$ri_p)

writeLines(tab4, "../tables/tab4_robustness.tex")
cat("  Written: tab4_robustness.tex\n")

## ---- Table 5: Heterogeneity by cohort ----
cat("\n=== Table 5: Heterogeneity ===\n")

gdf <- results$group_df
g_rows <- ""
for (i in 1:nrow(gdf)) {
  g <- gdf[i,]
  star <- stars(g$att, g$se)
  g_rows <- paste0(g_rows, sprintf(
    "  %d & %.4f%s & (%.4f) \\\\\n", g$group, g$att, star, g$se))
}

tab5 <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Heterogeneity by Adoption Cohort}
\\label{tab:heterogeneity}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Cohort & ATT & SE \\\\
\\midrule
%s\\midrule
Overall & %.4f & (%.4f) \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Group-specific ATTs from \\citet{callaway2021difference}. Each row reports the average treatment effect for states that adopted transitional SNAP benefits in the indicated year. Only cohorts with pre-treatment data in the ACS (2006+) are shown.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}', g_rows,
  results$agg_rate$overall.att, results$agg_rate$overall.se)

writeLines(tab5, "../tables/tab5_heterogeneity.tex")
cat("  Written: tab5_heterogeneity.tex\n")

## ---- SDE Table ----
cat("\n=== SDE Table ===\n")

beta <- results$agg_rate$overall.att
se_beta <- results$agg_rate$overall.se
sd_y <- sd(df$snap_rate, na.rm = TRUE)
sde <- beta / sd_y
se_sde <- se_beta / sd_y

classify <- function(s) dplyr::case_when(
  s < -0.15 ~ "Large negative", s < -0.05 ~ "Moderate negative",
  s < -0.005 ~ "Small negative", s < 0.005 ~ "Null",
  s < 0.05 ~ "Small positive", s < 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive")

class_main <- classify(sde)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does automatic SNAP continuation for families leaving TANF ",
  "reduce the bureaucratic gap in food assistance and increase SNAP participation? ",
  "\\textbf{Policy mechanism:} Transitional SNAP benefits provide automatic 5-month SNAP ",
  "eligibility for families exiting TANF cash assistance, eliminating the requirement to ",
  "separately reapply for food benefits during the welfare-to-work transition. ",
  "\\textbf{Outcome definition:} SNAP participation rate, defined as the share of households ",
  "that received SNAP/food stamp benefits in the past 12 months from the ACS 1-year estimates. ",
  "\\textbf{Treatment:} Binary --- state adopted transitional SNAP benefits versus never-adopted control. ",
  "\\textbf{Data:} Census ACS 1-year state-level estimates, 2005--2023, covering 51 jurisdictions ",
  "(", nrow(df), " state-year observations). ",
  "\\textbf{Method:} Staggered difference-in-differences using \\citet{callaway2021difference} ",
  "with doubly robust estimation and never-treated controls. ",
  "\\textbf{Sample:} All 50 US states plus DC; 24 treated states adopted transitional benefits ",
  "2001--2016, 27 never-treated controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation ",
  "of the SNAP participation rate. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (.05$--.15$), Small (.005$--.05$), Null ($< 0.005$).")

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
SNAP rate & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  beta, se_beta, sd_y, sde, se_sde, class_main, sde_notes)

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat(sprintf("  SDE: %.4f (%s)\n", sde, class_main))
cat("  Written: tabF1_sde.tex\n")

cat("\n  ALL TABLES DONE.\n")
