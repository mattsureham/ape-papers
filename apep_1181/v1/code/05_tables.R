# 05_tables.R — Generate all LaTeX tables for apep_1181

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "models_robust.RData"))
episodes <- fread(file.path(data_dir, "episodes.csv"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

# Episode-level summary
ep_stats <- episodes[, .(
  N = .N,
  mean_dur = mean(duration_hours),
  sd_dur = sd(duration_hours),
  mean_price = mean(mean_price),
  sd_price = sd(mean_price)
), by = regime]

# Panel-level summary
panel_stats <- panel[, .(
  mean_export = mean(mean_export_mw),
  sd_export = sd(mean_export_mw),
  min_export = min(mean_export_mw),
  max_export = max(mean_export_mw),
  n_obs = .N
)]

# Generate LaTeX
tab1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{l S[table-format=3.0] S[table-format=2.1] S[table-format=2.1] S[table-format=3.1] S[table-format=2.1]}
\\toprule
& {N Episodes} & {Mean Duration} & {SD Duration} & {Mean Price} & {SD Price} \\\\
& & {(hours)} & {(hours)} & {(EUR/MWh)} & {(EUR/MWh)} \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel A: Negative-Price Episodes by Regime}} \\\\
6-hour rule (2019--2020) & %d & %.1f & %.1f & %.1f & %.1f \\\\
4-hour rule (2021--2023) & %d & %.1f & %.1f & %.1f & %.1f \\\\
3-hour rule (2024--2025) & %d & %.1f & %.1f & %.1f & %.1f \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel B: Cross-Border Flows During Negative-Price Episodes}} \\\\
\\multicolumn{6}{l}{\\quad Mean hourly export: %.0f MW \\quad SD: %.0f MW \\quad N obs: %s} \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reports summary statistics for consecutive negative-price episodes in the DE-LU day-ahead market, 2019--2025. An episode is defined as a maximal sequence of consecutive hours with day-ahead price below zero. Regimes reflect the EEG \\S 51 clawback threshold: renewable generators $>$400 kW lose their market premium when prices are negative for $\\geq N$ consecutive hours. Panel B reports mean bilateral flows from Germany to 11 neighbors (AT, BE, CH, CZ, DK, FR, LU, NL, NO, PL, SE) during negative-price episodes. Positive values indicate German exports. Source: Fraunhofer ISE Energy-Charts API.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
  ep_stats[regime == "6h_rule"]$N, ep_stats[regime == "6h_rule"]$mean_dur,
  ep_stats[regime == "6h_rule"]$sd_dur, ep_stats[regime == "6h_rule"]$mean_price,
  ep_stats[regime == "6h_rule"]$sd_price,
  ep_stats[regime == "4h_rule"]$N, ep_stats[regime == "4h_rule"]$mean_dur,
  ep_stats[regime == "4h_rule"]$sd_dur, ep_stats[regime == "4h_rule"]$mean_price,
  ep_stats[regime == "4h_rule"]$sd_price,
  ep_stats[regime == "3h_rule"]$N, ep_stats[regime == "3h_rule"]$mean_dur,
  ep_stats[regime == "3h_rule"]$sd_dur, ep_stats[regime == "3h_rule"]$mean_price,
  ep_stats[regime == "3h_rule"]$sd_price,
  panel_stats$mean_export, panel_stats$sd_export,
  format(panel_stats$n_obs, big.mark = ",")
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main DiD Results (2021 Reform)
# ============================================================
cat("=== Generating Table 2: Main Results (2021 Reform) ===\n")

# Extract coefficients and SEs
extract_coef <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  n <- model$nobs
  r2 <- fitstat(model, "wr2")[[1]]
  list(beta = b, se = s, n = n, r2w = r2)
}

r1 <- extract_coef(m1, "did_2021")
r2 <- extract_coef(m2, "did_2021")
r3 <- extract_coef(m3, "did_2021")
r4 <- extract_coef(m4, "did_2021")

stars <- function(b, s) {
  p <- 2 * pnorm(-abs(b / s))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

fmt_row <- function(r, label = "") {
  st <- stars(r$beta, r$se)
  sprintf("%.1f%s", r$beta, st)
}

tab2 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Effect of 2021 Clawback Threshold Tightening on Cross-Border Exports}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccc}
\\toprule
& (1) & (2) & (3) & (4) \\\\
\\midrule
Treated $\\times$ Post & %s & %s & %s & %s \\\\
                       & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\
\\\\
Neighbor FE & Yes & Yes & Yes & No \\\\
Year-month FE & No & Yes & Yes & Yes \\\\
Neighbor $\\times$ Post FE & No & No & No & Yes \\\\
Episode controls & No & No & Yes & Yes \\\\
\\\\
Observations & %s & %s & %s & %s \\\\
Within $R^2$ & %.4f & %.4f & %.4f & %.4f \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is mean hourly bilateral export from Germany (MW) during the episode. Treated episodes have duration 4--5 hours (newly subject to clawback after January 2021); control episodes have duration 1--3 hours (below the clawback threshold in both regimes). Sample: 2019--2023. Episode controls include mean day-ahead price during the episode and day of week. Standard errors clustered at the year-month level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main2021}
\\end{table}",
  fmt_row(r1), fmt_row(r2), fmt_row(r3), fmt_row(r4),
  r1$se, r2$se, r3$se, r4$se,
  format(r1$n, big.mark = ","), format(r2$n, big.mark = ","),
  format(r3$n, big.mark = ","), format(r4$n, big.mark = ","),
  r1$r2w, r2$r2w, r3$r2w, r4$r2w
)

writeLines(tab2, file.path(table_dir, "tab2_main2021.tex"))

# ============================================================
# Table 3: 2024 Reform and Pooled
# ============================================================
cat("=== Generating Table 3: 2024 Reform and Pooled ===\n")

r5 <- extract_coef(m5, "did_2024")
r6 <- extract_coef(m6, "did_2024")
r7 <- extract_coef(m7, "newly_clawbacked")
r8 <- extract_coef(m8, "newly_clawbacked")

tab3 <- sprintf("\\begin{table}[H]
\\centering
\\caption{2024 Clawback Reform and Pooled Specification}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{2024 Reform (4h $\\to$ 3h)} & \\multicolumn{2}{c}{Pooled} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
& (1) & (2) & (3) & (4) \\\\
\\midrule
DiD / Newly clawbacked & %s & %s & %s & %s \\\\
                       & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\
\\\\
Episode controls & No & Yes & No & Yes \\\\
Neighbor FE & Yes & Yes & Yes & Yes \\\\
Year-month FE & Yes & Yes & Yes & Yes \\\\
\\\\
Observations & %s & %s & %s & %s \\\\
Within $R^2$ & %.4f & %.4f & %.5f & %.4f \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Columns 1--2: DiD for the 2024 reform (4h $\\to$ 3h threshold). Treated episodes have duration 3 hours; controls have duration 1--2 hours. Sample: 2021--2025. Columns 3--4: Pooled specification stacking both reforms. ``Newly clawbacked'' equals 1 for episodes whose duration falls in the newly penalized range after the most recent threshold change. Episode controls include mean day-ahead price. Standard errors clustered at the year-month level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:reform2024}
\\end{table}",
  fmt_row(r5), fmt_row(r6), fmt_row(r7), fmt_row(r8),
  r5$se, r6$se, r7$se, r8$se,
  format(r5$n, big.mark = ","), format(r6$n, big.mark = ","),
  format(r7$n, big.mark = ","), format(r8$n, big.mark = ","),
  r5$r2w, r6$r2w, r7$r2w, r8$r2w
)

writeLines(tab3, file.path(table_dir, "tab3_2024_pooled.tex"))

# ============================================================
# Table 4: Robustness
# ============================================================
cat("=== Generating Table 4: Robustness ===\n")

r_ep <- extract_coef(m_ep_clust, "did_2021")
r_tw <- extract_coef(m_twoway, "did_2021")
r_tot <- extract_coef(m_total, "did_2021")
r_log <- extract_coef(m_log, "did_2021")
r_nocov <- extract_coef(m_nocovid, "did_nocovid")
r_plac <- extract_coef(m_placebo, "fake_did")

tab4 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Robustness Checks for the 2021 Reform}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lccc}
\\toprule
Specification & Estimate & (SE) & N \\\\
\\midrule
\\textit{Panel A: Alternative Clustering} & & & \\\\
\\quad Episode-level clustering & %.1f & (%.1f) & %s \\\\
\\quad Two-way (year-month $+$ neighbor) & %.1f & (%.1f) & %s \\\\
\\midrule
\\textit{Panel B: Alternative Outcomes} & & & \\\\
\\quad Total export (MWh) & %.1f & (%.1f) & %s \\\\
\\quad Asinh(export MW) & %.3f & (%.3f) & %s \\\\
\\midrule
\\textit{Panel C: Sample Variations} & & & \\\\
\\quad Exclude 2020--2021 (COVID) & %.1f & (%.1f) & %s \\\\
\\quad Placebo reform at 2020 & %.1f & (%.1f) & %s \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All specifications include neighbor and year-month fixed effects except the placebo (pre-period only). The baseline estimate (Table~\\ref{tab:main2021}, column 2) is 55.7 (SE 146.7). Standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robust}
\\end{table}",
  r_ep$beta, r_ep$se, format(r_ep$n, big.mark = ","),
  r_tw$beta, r_tw$se, format(r_tw$n, big.mark = ","),
  r_tot$beta, r_tot$se, format(r_tot$n, big.mark = ","),
  r_log$beta, r_log$se, format(r_log$n, big.mark = ","),
  r_nocov$beta, r_nocov$se, format(r_nocov$n, big.mark = ","),
  r_plac$beta, r_plac$se, format(r_plac$n, big.mark = ",")
)

writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# SDE for the 2021 reform (preferred spec m2)
beta_2021 <- coef(m2)["did_2021"]
se_2021 <- se(m2)["did_2021"]
sd_y_2021 <- sd(df_2021[post_2021 == 0]$mean_export_mw)
sde_2021 <- beta_2021 / sd_y_2021
se_sde_2021 <- se_2021 / sd_y_2021

# SDE for the 2024 reform (preferred spec m5)
beta_2024 <- coef(m5)["did_2024"]
se_2024 <- se(m5)["did_2024"]
sd_y_2024 <- sd(df_2024[post_2024 == 0]$mean_export_mw)
sde_2024 <- beta_2024 / sd_y_2024
se_sde_2024 <- se_2024 / sd_y_2024

# SDE for pooled (m8)
beta_pool <- coef(m8)["newly_clawbacked"]
se_pool <- se(m8)["newly_clawbacked"]
sd_y_pool <- sd(df_pooled$mean_export_mw)
sde_pool <- beta_pool / sd_y_pool
se_sde_pool <- se_pool / sd_y_pool

# Heterogeneity: high vs low interconnector capacity
beta_high <- coef(m_high)["did_2021"]
se_high <- se(m_high)["did_2021"]
sd_y_high <- sd(df_2021[post_2021 == 0 & neighbor %in% c("Austria", "France", "Switzerland", "Netherlands", "Denmark")]$mean_export_mw)
sde_high <- beta_high / sd_y_high
se_sde_high <- se_high / sd_y_high

beta_low <- coef(m_low)["did_2021"]
se_low <- se(m_low)["did_2021"]
sd_y_low <- sd(df_2021[post_2021 == 0 & !(neighbor %in% c("Austria", "France", "Switzerland", "Netherlands", "Denmark"))]$mean_export_mw)
sde_low <- beta_low / sd_y_low
se_sde_low <- se_low / sd_y_low

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

# --- Build SDE table ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Germany and 11 European neighbors (Austria, Belgium, Czechia, Denmark, France, Luxembourg, Netherlands, Norway, Poland, Sweden, Switzerland). ",
  "\\textbf{Research question:} Whether tightening Germany's EEG \\S 51 subsidy clawback threshold for renewable generators reduces bilateral electricity exports to neighboring countries during negative-price episodes. ",
  "\\textbf{Policy mechanism:} The EEG clawback suspends market premium payments to renewable generators above 400 kW when the day-ahead electricity price is negative for N or more consecutive hours; threshold tightened from 6h to 4h (January 2021) and from 4h to 3h (January 2024), creating financial incentives for generators to curtail output during extended negative-price periods. ",
  "\\textbf{Outcome definition:} Mean hourly bilateral electricity export from Germany to each neighbor (MW) during a negative-price episode, where positive values indicate power flowing from Germany to the neighbor. ",
  "\\textbf{Treatment:} Binary; equals one for episodes whose duration falls in the newly clawback-eligible window created by each threshold tightening. ",
  "\\textbf{Data:} Fraunhofer ISE Energy-Charts API, hourly bilateral cross-border flows and DE-LU day-ahead prices, 2019--2025, episode-neighbor level, 1,334--1,763 observations. ",
  "\\textbf{Method:} Difference-in-differences comparing newly clawback-eligible episodes (treated) to shorter episodes (control) before and after each threshold change, with neighbor and year-month fixed effects, standard errors clustered at the year-month level. ",
  "\\textbf{Sample:} All consecutive negative-price episodes of 1--5 hours in the DE-LU day-ahead market (excluding episodes $\\geq$6 hours that were always clawback-eligible), matched to bilateral flows for 11 neighboring countries. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$). ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis."
)

tabF1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{llcccccl}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Export (MW) & 2021 reform (6h$\\to$4h) & %.1f & %.1f & %.4f & %.4f & %s \\\\
Export (MW) & 2024 reform (4h$\\to$3h) & %.1f & %.1f & %.4f & %.4f & %s \\\\
Export (MW) & Pooled (both reforms) & %.1f & %.1f & %.4f & %.4f & %s \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by interconnector capacity)}} \\\\
Export (MW) & High-capacity neighbors & %.1f & %.1f & %.4f & %.4f & %s \\\\
Export (MW) & Low-capacity neighbors & %.1f & %.1f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  beta_2021, sd_y_2021, sde_2021, se_sde_2021, classify(sde_2021),
  beta_2024, sd_y_2024, sde_2024, se_sde_2024, classify(sde_2024),
  beta_pool, sd_y_pool, sde_pool, se_sde_pool, classify(sde_pool),
  beta_high, sd_y_high, sde_high, se_sde_high, classify(sde_high),
  beta_low, sd_y_low, sde_low, se_sde_low, classify(sde_low),
  sde_notes
)

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

# ============================================================
# Table 5: Event Study Coefficients
# ============================================================
cat("=== Generating Table 5: Event Study ===\n")

ev_coefs <- coeftable(m_event)
ev_df <- as.data.frame(ev_coefs)
ev_df$year <- c(2019, 2021, 2022, 2023)

tab5 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Event-Study Estimates: Year-by-Year Interaction with Treatment (Ref: 2020)}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Year & Estimate (MW) & SE \\\\
\\midrule
2019 & %.1f & (%.1f) \\\\
\\textit{2020 (reference)} & --- & --- \\\\
2021 & %.1f & (%.1f) \\\\
2022 & %.1f & (%.1f) \\\\
2023 & %.1f & (%.1f) \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Coefficients from interacting year dummies with the treatment indicator (episode duration 4--5 hours). Reference year is 2020 (last year of 6-hour regime). Specification includes neighbor and year fixed effects. Standard errors clustered at the year-month level. The 2021 threshold change took effect January 1, 2021.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:event}
\\end{table}",
  ev_df[1, 1], ev_df[1, 2],
  ev_df[2, 1], ev_df[2, 2],
  ev_df[3, 1], ev_df[3, 2],
  ev_df[4, 1], ev_df[4, 2]
)

writeLines(tab5, file.path(table_dir, "tab5_event.tex"))

cat("\n=== All tables generated ===\n")
cat(sprintf("Tables saved to: %s\n", normalizePath(table_dir)))
