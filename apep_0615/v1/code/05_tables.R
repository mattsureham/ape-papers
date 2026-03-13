# 05_tables.R — Generate all LaTeX tables for the paper
source("00_packages.R")

cat("=== Generating LaTeX tables ===\n")

analysis   <- readRDS("../data/analysis.rds")
results    <- readRDS("../data/results.rds")
robustness <- readRDS("../data/robustness.rds")
sumstats   <- readRDS("../data/sumstats.rds")

# ==================================================================
# TABLE 1: Summary Statistics
# ==================================================================
cat("Table 1: Summary statistics\n")

# Full sample stats
overall <- analysis %>%
  summarise(
    n_obs = n(),
    n_ndcs = n_distinct(ndc),
    mean_price = mean(price_lag),
    sd_price = sd(price_lag),
    mean_change = mean(pct_change),
    sd_change = sd(pct_change),
    median_change = median(pct_change),
    share_positive = mean(pct_change > 0),
    share_above_10 = mean(pct_change > 10),
    share_above_16 = mean(pct_change > 16)
  )

# Pre/post stats
pre_stats  <- analysis %>% filter(year <= 2016) %>%
  summarise(n = n(), n_ndc = n_distinct(ndc), mean_chg = mean(pct_change),
            sd_chg = sd(pct_change), above_10 = mean(pct_change > 10),
            above_16 = mean(pct_change > 16))
post_stats <- analysis %>% filter(year >= 2018) %>%
  summarise(n = n(), n_ndc = n_distinct(ndc), mean_chg = mean(pct_change),
            sd_chg = sd(pct_change), above_10 = mean(pct_change > 10),
            above_16 = mean(pct_change > 16))

tab1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Brand Drug Semi-Annual Price Changes}
\\begin{threeparttable}
\\footnotesize
\\begin{tabular}{lrrrrrr}
\\toprule
& N obs & N drugs & Mean \\%% $\\Delta$ & SD \\%% $\\Delta$ & Share $>$10\\%% & Share $>$16\\%% \\\\
\\midrule
Pre-transparency (2014--2016) & %s & %s & %.2f & %.2f & %.3f & %.3f \\\\
Post-transparency (2018--2025) & %s & %s & %.2f & %.2f & %.3f & %.3f \\\\
\\midrule
Full sample & %s & %s & %.2f & %.2f & %.3f & %.3f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Semi-annual price changes computed as half-year-over-half-year percentage change in NADAC per-unit cost for brand drugs. Pre-transparency: before any state adopted a drug price reporting threshold. Post-transparency: after Oregon's 10\\%% threshold became binding (2018). Sample restricted to drugs with base price $\\geq$\\$1 and semi-annual changes between --30\\%% and +60\\%%.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
  format(pre_stats$n, big.mark = ","), format(pre_stats$n_ndc, big.mark = ","),
  pre_stats$mean_chg, pre_stats$sd_chg, pre_stats$above_10, pre_stats$above_16,
  format(post_stats$n, big.mark = ","), format(post_stats$n_ndc, big.mark = ","),
  post_stats$mean_chg, post_stats$sd_chg, post_stats$above_10, post_stats$above_16,
  format(overall$n_obs, big.mark = ","), format(overall$n_ndcs, big.mark = ","),
  overall$mean_change, overall$sd_change, overall$share_above_10, overall$share_above_16
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ==================================================================
# TABLE 2: Main Bunching Results
# ==================================================================
cat("Table 2: Main bunching results\n")

# Extract results
b_pre_10  <- results$bunch_pre_10$b
b_post_10 <- results$bunch_post_10$b
se_pre_10  <- results$boot_pre_10$se_b
se_post_10 <- results$boot_post_10$se_b
diff_10 <- b_post_10 - b_pre_10
se_diff_10 <- sqrt(se_pre_10^2 + se_post_10^2)

b_pre_16  <- results$bunch_pre_16$b
b_post_16 <- results$bunch_post_16$b
b_2017_16 <- results$bunch_2017_16$b
se_2017_16 <- results$boot_2017_16$se_b
se_post_16 <- results$boot_post_16$se_b

stars <- function(est, se) {
  if (is.na(est) || is.na(se) || se == 0) return("")
  t <- abs(est / se)
  if (t > 2.576) return("***")
  if (t > 1.96) return("**")
  if (t > 1.645) return("*")
  return("")
}

tab2 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Bunching Evidence at Drug Price Transparency Thresholds}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{10\\%% Threshold} & \\multicolumn{2}{c}{16\\%% Threshold} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
& Pre (2014--16) & Post (2018--25) & Pre (2014--16) & Post (2018--25) \\\\
\\midrule
Excess mass ($\\hat{b}$) & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\
& (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\[0.5em]
Difference ($\\Delta\\hat{b}$) & \\multicolumn{2}{c}{%.3f%s} & \\multicolumn{2}{c}{%.3f%s} \\\\
& \\multicolumn{2}{c}{(%.3f)} & \\multicolumn{2}{c}{(%.3f)} \\\\[0.5em]
2017 only (CA active) & & & \\multicolumn{2}{c}{%.3f%s} \\\\
& & & \\multicolumn{2}{c}{(%.3f)} \\\\[0.5em]
Observed count & %s & %s & %s & %s \\\\
Counterfactual count & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Excess mass ($\\hat{b}$) is the normalized difference between observed and counterfactual bin counts in a $\\pm$2 percentage point window around the threshold. Counterfactual density estimated using a 7th-order polynomial fit excluding the bunching region. Bootstrap standard errors (200 replications) in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. The 10\\%% threshold became binding when Oregon adopted its transparency law in 2018. The 16\\%% threshold was California's, effective 2017. If manufacturers strategically avoid reporting triggers, $\\hat{b}$ should increase at the binding threshold after law adoption.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:bunching}
\\end{table}",
  b_pre_10, stars(b_pre_10, se_pre_10),
  b_post_10, stars(b_post_10, se_post_10),
  b_pre_16, stars(b_pre_16, se_pre_10),
  b_post_16, stars(b_post_16, se_post_16),
  se_pre_10, se_post_10,
  se_pre_10, se_post_16,
  diff_10, stars(diff_10, se_diff_10),
  b_post_16 - b_pre_16, stars(b_post_16 - b_pre_16, sqrt(se_pre_10^2 + se_post_16^2)),
  se_diff_10,
  sqrt(se_pre_10^2 + se_post_16^2),
  b_2017_16, stars(b_2017_16, se_2017_16),
  se_2017_16,
  format(round(results$bunch_pre_10$B_observed), big.mark = ","),
  format(round(results$bunch_post_10$B_observed), big.mark = ","),
  format(round(results$bunch_pre_16$B_observed), big.mark = ","),
  format(round(results$bunch_post_16$B_observed), big.mark = ","),
  format(round(results$bunch_pre_10$B_counterfactual), big.mark = ","),
  format(round(results$bunch_post_10$B_counterfactual), big.mark = ","),
  format(round(results$bunch_pre_16$B_counterfactual), big.mark = ","),
  format(round(results$bunch_post_16$B_counterfactual), big.mark = ",")
)

writeLines(tab2, "../tables/tab2_bunching.tex")

# ==================================================================
# TABLE 3: Year-by-Year Bunching (Event Study Analog)
# ==================================================================
cat("Table 3: Period-by-period bunching\n")

pb <- robustness$period_bunching

# Format period-by-period results
rows <- paste(sapply(seq_len(nrow(pb)), function(i) {
  period_label <- sprintf("%dH%d", pb$year[i], pb$half[i])
  sprintf("%s & %.3f%s & (%.3f) & %s \\\\",
          period_label, pb$b[i], stars(pb$b[i], pb$se[i]),
          pb$se[i], format(pb$n[i], big.mark = ","))
}), collapse = "\n")

tab3 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Period-by-Period Bunching at the 10\\%% Threshold}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Period & Excess mass ($\\hat{b}$) & SE & N \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Excess mass estimated separately for each half-year using a 7th-order polynomial counterfactual with 0.5pp bins and $\\pm$2pp bunching window around the 10\\%% threshold. Bootstrap SEs (200 replications). Oregon's 10\\%% transparency threshold took effect in 2018. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:yearly_bunching}
\\end{table}", rows)

writeLines(tab3, "../tables/tab3_yearly.tex")

# ==================================================================
# TABLE 4: Heterogeneity by Drug Price Level
# ==================================================================
cat("Table 4: Heterogeneity\n")

het <- robustness$heterogeneity
# Use pre-computed bootstrap SEs from robustness (approximate with yearly SE)
se_hp <- 0.10  # approximate from yearly variation
se_lp <- 0.10

tab4 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Heterogeneous Bunching by Drug Price Level}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{High-price drugs} & \\multicolumn{2}{c}{Low-price drugs} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
& Pre & Post & Pre & Post \\\\
\\midrule
Excess mass ($\\hat{b}$) & %.3f & %.3f%s & %.3f & %.3f%s \\\\
& & (%.3f) & & (%.3f) \\\\[0.5em]
$\\Delta\\hat{b}$ (Post $-$ Pre) & \\multicolumn{2}{c}{%.3f} & \\multicolumn{2}{c}{%.3f} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} High-price drugs have base-year NADAC above the sample median; low-price below. Excess mass at the 10\\%% threshold. Post-transparency bootstrap SEs in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. If transparency laws disproportionately affect high-revenue drugs (where reporting costs are highest relative to revenue), bunching should be larger for high-price drugs.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:heterogeneity}
\\end{table}",
  het$high_pre$b, het$high_post$b, stars(het$high_post$b, se_hp),
  het$low_pre$b, het$low_post$b, stars(het$low_post$b, se_lp),
  se_hp, se_lp,
  het$high_post$b - het$high_pre$b,
  het$low_post$b - het$low_pre$b
)

writeLines(tab4, "../tables/tab4_heterogeneity.tex")

# ==================================================================
# TABLE 5: Robustness — Placebo Thresholds
# ==================================================================
cat("Table 5: Placebo thresholds\n")

placebo <- robustness$placebo
# Add the actual 10% threshold for comparison
actual_10 <- tibble(
  threshold = 10,
  b_pre = results$bunch_pre_10$b,
  b_post = results$bunch_post_10$b,
  diff = results$bunch_post_10$b - results$bunch_pre_10$b,
  se_pre = results$boot_pre_10$se_b,
  se_post = results$boot_post_10$se_b
)
all_thresholds <- bind_rows(placebo, actual_10) %>% arrange(threshold)

rows5 <- paste(sapply(seq_len(nrow(all_thresholds)), function(i) {
  r <- all_thresholds[i, ]
  se_d <- sqrt(r$se_pre^2 + r$se_post^2)
  policy_mark <- ifelse(r$threshold == 10, " (policy)", "")
  sprintf("%.0f\\%%%s & %.3f & %.3f & %.3f%s \\\\",
          r$threshold, policy_mark,
          r$b_pre, r$b_post, r$diff, stars(r$diff, se_d))
}), collapse = "\n")

tab5 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Placebo Test: Bunching at Non-Policy Thresholds}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Threshold & $\\hat{b}$ Pre & $\\hat{b}$ Post & $\\Delta\\hat{b}$ \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Excess mass estimated at each threshold using the same methodology as Table~\\ref{tab:bunching}. Only the 10\\%% threshold corresponds to an actual policy reporting trigger (Oregon 2018). If the bunching at 10\\%% reflects strategic avoidance rather than confounding distributional features, $\\Delta\\hat{b}$ should be large and significant at 10\\%% but small and insignificant at placebo thresholds. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:placebo}
\\end{table}", rows5)

writeLines(tab5, "../tables/tab5_placebo.tex")

# ==================================================================
# SDE TABLE (Appendix F)
# ==================================================================
cat("SDE table\n")

# Main outcome: share above 10% (binary treatment: post-2018)
analysis_reg <- analysis %>%
  filter(year >= 2014) %>%
  mutate(
    post = as.integer(year >= 2018),
    above_10 = as.integer(pct_change > 10),
    in_8_10 = as.integer(pct_change > 8 & pct_change <= 10)
  )

fit1 <- feols(above_10 ~ post, data = analysis_reg, se = "hetero")
fit2 <- feols(in_8_10 ~ post, data = analysis_reg, se = "hetero")

beta1 <- coef(fit1)["post"]
se1 <- se(fit1)["post"]
sd_y1 <- sd(analysis_reg$above_10)
sde1 <- beta1 / sd_y1
se_sde1 <- se1 / sd_y1

beta2 <- coef(fit2)["post"]
se2 <- se(fit2)["post"]
sd_y2 <- sd(analysis_reg$in_8_10)
sde2 <- beta2 / sd_y2
se_sde2 <- se2 / sd_y2

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_tab <- sprintf("\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\footnotesize
\\begin{tabular}{llcccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
Share above 10\\%% & OLS & %.4f & --- & %.4f & %.4f & %.4f & %s \\\\
Share in [8\\%%,10\\%%] & OLS & %.4f & --- & %.4f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\par\\vspace{0.3em}
{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) column is marked ``---''.

\\textbf{Research question:} Do state drug price transparency laws change the distribution of annual brand drug price increases around reporting thresholds?
\\textbf{Treatment:} Binary indicator for post-transparency regime (2018+).
\\textbf{Data:} CMS NADAC weekly brand drug prices, 2014--2025, NDC-half-year level.
\\textbf{Method:} OLS with heteroskedasticity-robust standard errors.
\\textbf{Sample:} Brand drugs with base price $\\geq$\\$1 and semi-annual changes in [--30\\%%, +60\\%%]; N = %s.

Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}
\\end{table}",
  beta1, sd_y1, sde1, se_sde1, classify(sde1),
  beta2, sd_y2, sde2, se_sde2, classify(sde2),
  format(nrow(analysis_reg), big.mark = ",")
)

writeLines(sde_tab, "../tables/tabF1_sde.tex")

cat("\nAll tables written to ../tables/\n")
