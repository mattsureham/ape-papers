# 06_tables.R — Generate all LaTeX tables
# apep_0842 v2: The Designation Illusion

source("00_packages.R")

panel <- readRDS("../data/analysis_panel_final.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
sco_events <- readRDS("../data/sco_events.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("=== Table 1: Summary Statistics ===\n")

summ_treated <- panel %>%
  filter(sco == 1) %>%
  summarize(
    n = n(),
    recog_mean = mean(recog_rate, na.rm = TRUE),
    recog_sd = sd(recog_rate, na.rm = TRUE),
    decisions_mean = mean(total_decisions, na.rm = TRUE),
    decisions_sd = sd(total_decisions, na.rm = TRUE),
    apps_mean = mean(applications, na.rm = TRUE),
    apps_sd = sd(applications, na.rm = TRUE)
  ) %>%
  mutate(group = "Designated Safe")

summ_untreated <- panel %>%
  filter(sco == 0) %>%
  summarize(
    n = n(),
    recog_mean = mean(recog_rate, na.rm = TRUE),
    recog_sd = sd(recog_rate, na.rm = TRUE),
    decisions_mean = mean(total_decisions, na.rm = TRUE),
    decisions_sd = sd(total_decisions, na.rm = TRUE),
    apps_mean = mean(applications, na.rm = TRUE),
    apps_sd = sd(applications, na.rm = TRUE)
  ) %>%
  mutate(group = "Not Designated")

summ_all <- panel %>%
  summarize(
    n = n(),
    recog_mean = mean(recog_rate, na.rm = TRUE),
    recog_sd = sd(recog_rate, na.rm = TRUE),
    decisions_mean = mean(total_decisions, na.rm = TRUE),
    decisions_sd = sd(total_decisions, na.rm = TRUE),
    apps_mean = mean(applications, na.rm = TRUE),
    apps_sd = sd(applications, na.rm = TRUE)
  ) %>%
  mutate(group = "Full Sample")

tab1_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
 & \\multicolumn{2}{c}{Recognition Rate} & \\multicolumn{2}{c}{Total Decisions} & \\multicolumn{2}{c}{Applications} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}
 & Mean & SD & Mean & SD & Mean & SD \\\\
\\midrule
Designated Safe (SCO=1) & %.3f & %.3f & %.0f & %.0f & %.0f & %.0f \\\\
 & \\multicolumn{6}{c}{\\footnotesize $N$ = %s} \\\\[0.3em]
Not Designated (SCO=0) & %.3f & %.3f & %.0f & %.0f & %.0f & %.0f \\\\
 & \\multicolumn{6}{c}{\\footnotesize $N$ = %s} \\\\[0.3em]
\\midrule
Full Sample & %.3f & %.3f & %.0f & %.0f & %.0f & %.0f \\\\
 & \\multicolumn{6}{c}{\\footnotesize $N$ = %s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Unit of observation is origin citizenship $\\times$ destination country $\\times$ year. Recognition rate is the share of positive first-instance asylum decisions (Geneva Convention status, subsidiary protection, and humanitarian protection) among all first-instance decisions. Sample restricted to cells with $\\geq$10 total decisions. Data from Eurostat (\\texttt{migr\\_asydcfsta} and \\texttt{migr\\_asyappctza}), 2008--2023. SCO designation dates from AIDA database and national legislation.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}',
  summ_treated$recog_mean, summ_treated$recog_sd,
  summ_treated$decisions_mean, summ_treated$decisions_sd,
  summ_treated$apps_mean, summ_treated$apps_sd,
  format(summ_treated$n, big.mark = ","),
  summ_untreated$recog_mean, summ_untreated$recog_sd,
  summ_untreated$decisions_mean, summ_untreated$decisions_sd,
  summ_untreated$apps_mean, summ_untreated$apps_sd,
  format(summ_untreated$n, big.mark = ","),
  summ_all$recog_mean, summ_all$recog_sd,
  summ_all$decisions_mean, summ_all$decisions_sd,
  summ_all$apps_mean, summ_all$apps_sd,
  format(summ_all$n, big.mark = ",")
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ============================================================
# Table 2: Main Results — Triple-Diff
# ============================================================

cat("=== Table 2: Main Results ===\n")

# Extract coefficients and SEs
extract_coef <- function(model, varname = "sco") {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  n <- model$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, s = s, p = p, n = n, stars = stars)
}

r1 <- extract_coef(results$m1)
r2 <- extract_coef(results$m2)
r3 <- extract_coef(results$m3)

tab2_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Effect of Safe Country Designation on Asylum Recognition Rates}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
 & (1) & (2) & (3) \\\\
 & Baseline & Triple-Diff & Weighted \\\\
\\midrule
SCO Designation & %s%.3f%s & %s%.3f%s & %s%.3f%s \\\\
 & (%.3f) & (%.3f) & (%.3f) \\\\[0.5em]
\\midrule
Pair FE & Yes & Yes & Yes \\\\
Year FE & Yes & --- & --- \\\\
Origin $\\times$ Year FE & --- & Yes & Yes \\\\
Destination $\\times$ Year FE & --- & Yes & Yes \\\\
Weighted by decisions & --- & --- & Yes \\\\[0.3em]
Observations & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is the first-instance asylum recognition rate (positive decisions / total decisions). SCO Designation equals one if destination country $j$ designates origin country $c$ as a safe country of origin in year $t$. Column (1) includes origin$\\times$destination pair and year fixed effects. Columns (2)--(3) add origin$\\times$year and destination$\\times$year fixed effects, absorbing all origin- and destination-specific time trends. Column (3) weights by total decisions in the cell. Standard errors clustered at the destination-country level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}',
  ifelse(r1$b < 0, "$-$", ""), abs(r1$b), r1$stars,
  ifelse(r2$b < 0, "$-$", ""), abs(r2$b), r2$stars,
  ifelse(r3$b < 0, "$-$", ""), abs(r3$b), r3$stars,
  r1$s, r2$s, r3$s,
  format(r1$n, big.mark = ","),
  format(r2$n, big.mark = ","),
  format(r3$n, big.mark = ",")
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ============================================================
# Table 3: Channels — Deterrence and Diversion
# ============================================================

cat("=== Table 3: Channels ===\n")

r4 <- extract_coef(results$m4)
r5 <- extract_coef(results$m5, "share_sco_others")

tab3_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Deterrence Effects of Safe Country Designations on Asylum Applications}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & (1) & (2) \\\\
 & Own Designation & System-Wide \\\\
 & Log Applications & Log Applications \\\\
\\midrule
SCO Designation & %s%.3f%s & \\\\
 & (%.3f) & \\\\[0.5em]
Share Other Designating & & %s%.3f%s \\\\
\\quad Destinations & & (%.3f) \\\\[0.5em]
\\midrule
Pair FE & Yes & Yes \\\\
Origin $\\times$ Year FE & Yes & --- \\\\
Destination $\\times$ Year FE & Yes & Yes \\\\
Sample & Full & Non-designated cells \\\\[0.3em]
Observations & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is log(applications + 1). Column (1) estimates the own-designation deterrence effect using the full triple-difference specification. Column (2) tests whether a higher share of other EU destinations designating origin $c$ as safe reduces applications to non-designating destination $j$---evidence of system-wide deterrence rather than diversion. The Share Other Designating Destinations variable is the leave-own-out fraction of sample destinations that designate origin $c$ as safe in year $t$; it varies at the origin$\\times$year level and may partly capture correlated origin-specific shocks. Column (2) excludes origin$\\times$year FE because the regressor varies at that level, and restricts to non-designated cells. Standard errors clustered at the destination-country level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:channels}
\\end{table}',
  ifelse(r4$b < 0, "$-$", ""), abs(r4$b), r4$stars, r4$s,
  ifelse(r5$b < 0, "$-$", ""), abs(r5$b), r5$stars, r5$s,
  format(r4$n, big.mark = ","),
  format(r5$n, big.mark = ",")
)

writeLines(tab3_tex, "../tables/tab3_channels.tex")

# ============================================================
# Table 4: Heterogeneity
# ============================================================

cat("=== Table 4: Heterogeneity ===\n")

r6b <- extract_coef(results$m6_balkan)
r6o <- extract_coef(results$m6_other)
r7lg <- extract_coef(results$m7_large)
r7sm <- extract_coef(results$m7_small)

tab4_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Heterogeneity: Safe Country Designation Effects by Subgroup}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & Balkan & Non-Balkan & Large & Small \\\\
 & Origins & Origins & Destinations & Destinations \\\\
\\midrule
SCO Designation & %s%.3f%s & %s%.3f%s & %s%.3f%s & %s%.3f%s \\\\
 & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\[0.5em]
\\midrule
Pair FE & Yes & Yes & Yes & Yes \\\\
Origin $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\
Dest. $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\[0.3em]
Observations & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is the first-instance recognition rate. Columns (1)--(2) split by origin region: Balkan origins (Albania, Bosnia, Kosovo, Montenegro, North Macedonia, Serbia) vs.\\ all others. Columns (3)--(4) split by destination size: Large includes Germany, France, Austria, Italy, Sweden, and the Netherlands; Small includes all other destinations. All specifications include the full triple-difference fixed effects. Standard errors clustered at the destination level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:hetero}
\\end{table}',
  ifelse(r6b$b < 0, "$-$", ""), abs(r6b$b), r6b$stars,
  ifelse(r6o$b < 0, "$-$", ""), abs(r6o$b), r6o$stars,
  ifelse(r7lg$b < 0, "$-$", ""), abs(r7lg$b), r7lg$stars,
  ifelse(r7sm$b < 0, "$-$", ""), abs(r7sm$b), r7sm$stars,
  r6b$s, r6o$s, r7lg$s, r7sm$s,
  format(r6b$n, big.mark = ","),
  format(r6o$n, big.mark = ","),
  format(r7lg$n, big.mark = ","),
  format(r7sm$n, big.mark = ",")
)

writeLines(tab4_tex, "../tables/tab4_hetero.tex")

# ============================================================
# Table 5: Robustness
# ============================================================

cat("=== Table 5: Robustness ===\n")

r_main <- extract_coef(results$m2)
r_reject <- extract_coef(robustness$m_reject)
r_placebo <- extract_coef(robustness$m_placebo, "fake_sco")
r_restr <- extract_coef(robustness$m_restricted)

# LOO range
loo_min <- min(robustness$loo_dest$beta)
loo_max <- max(robustness$loo_dest$beta)

# Bootstrap p-value
boot_p <- if (!is.null(robustness$boot)) sprintf("%.3f", robustness$boot$p) else "N/A"

# CS estimate
cs_att_str <- if (!is.null(robustness$cs)) sprintf("%.3f", robustness$cs$att) else "---"
cs_se_str  <- if (!is.null(robustness$cs)) sprintf("(%.3f)", robustness$cs$se) else ""

# RI p-value
ri_p_str <- if (!is.null(robustness$ri)) sprintf("%.3f", robustness$ri$p) else "N/A"

# MDE
mde_str <- if (!is.null(robustness$mde)) sprintf("%.3f", robustness$mde$mde) else "N/A"

tab5_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & Main & Rejection Rate & Placebo & 2010--2020 \\\\
\\midrule
SCO Designation & %s%.3f%s & %s%.3f%s & & %s%.3f%s \\\\
 & (%.3f) & (%.3f) & & (%.3f) \\\\[0.3em]
Fake SCO & & & %s%.3f & \\\\
 & & & (%.3f) & \\\\[0.5em]
\\midrule
Bootstrap $p$ (999 reps) & %s & & & \\\\
Randomization inference $p$ & %s & & & \\\\
Callaway--Sant\\textquotesingle Anna ATT & %s & & & \\\\
 & %s & & & \\\\
LOO-dest.\\ range & [%.3f, %.3f] & & & \\\\
MDE (80\\%% power) & %s & & & \\\\[0.3em]
Observations & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Column (1) reproduces the main triple-difference estimate with additional inference: pairs cluster bootstrap (999 replications), randomization inference (999 permutations of treatment timing within years), Callaway--Sant\\textquotesingle Anna heterogeneity-robust staggered DiD using never-treated as controls, leave-one-destination-out range, and minimum detectable effect at 80\\%% power (two-sided, 5\\%% level). Column (2) uses rejection rate as the dependent variable. Column (3) randomly permutes designation years among treated pairs. Column (4) restricts to 2010--2020. All specifications include pair, origin$\\times$year, and destination$\\times$year FE. SEs clustered at destination level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robust}
\\end{table}',
  ifelse(r_main$b < 0, "$-$", ""), abs(r_main$b), r_main$stars,
  ifelse(r_reject$b < 0, "$-$", ""), abs(r_reject$b), r_reject$stars,
  ifelse(r_restr$b < 0, "$-$", ""), abs(r_restr$b), r_restr$stars,
  r_main$s, r_reject$s, r_restr$s,
  ifelse(r_placebo$b < 0, "$-$", ""), abs(r_placebo$b),
  r_placebo$s,
  boot_p,
  ri_p_str,
  cs_att_str,
  cs_se_str,
  loo_min, loo_max,
  mde_str,
  format(r_main$n, big.mark = ","),
  format(r_reject$n, big.mark = ","),
  format(r_placebo$n, big.mark = ","),
  format(r_restr$n, big.mark = ",")
)

writeLines(tab5_tex, "../tables/tab5_robust.tex")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# ============================================================

cat("=== Table F1: Standardized Effect Sizes ===\n")

# Extract from main model
beta_main <- coef(results$m2)["sco"]
se_main <- se(results$m2)["sco"]
sd_y <- sd(panel$recog_rate, na.rm = TRUE)
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

# Deterrence channel
beta_deter <- coef(results$m4)["sco"]
se_deter <- se(results$m4)["sco"]
panel_apps <- panel %>% filter(!is.na(applications) & applications > 0)
sd_y_apps <- sd(panel_apps$log_apps, na.rm = TRUE)
sde_deter <- beta_deter / sd_y_apps
se_sde_deter <- se_deter / sd_y_apps

# Heterogeneity: Balkan subsample
beta_balkan <- coef(results$m6_balkan)["sco"]
se_balkan <- se(results$m6_balkan)["sco"]
sd_y_balkan <- sd(panel$recog_rate[panel$balkan == 1], na.rm = TRUE)
sde_balkan <- beta_balkan / sd_y_balkan
se_sde_balkan <- se_balkan / sd_y_balkan

# Heterogeneity: Large destination subsample
beta_large <- coef(results$m7_large)["sco"]
se_large <- se(results$m7_large)["sco"]
sd_y_large <- sd(panel$recog_rate[panel$large_dest == 1], na.rm = TRUE)
sde_large <- beta_large / sd_y_large
se_sde_large <- se_large / sd_y_large

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (14 EU member states with safe country of origin lists). ",
  "\\textbf{Research question:} Whether a member state designating an asylum seeker's country of origin as `safe` causally reduces their probability of receiving international protection. ",
  "\\textbf{Policy mechanism:} Under the EU Asylum Procedures Directive (2013/32/EU), member states may maintain national safe country of origin lists; applicants from designated countries face accelerated procedures and a reversed burden of proof, requiring them to demonstrate why their country is unsafe for them individually. ",
  "\\textbf{Outcome definition:} First-instance asylum recognition rate, calculated as positive decisions (Geneva Convention status, subsidiary protection, and humanitarian protection combined) divided by total first-instance decisions, from Eurostat \\texttt{migr\\_asydcfsta}. ",
  "\\textbf{Treatment:} Binary indicator equal to one when destination country $j$ has designated origin country $c$ as a safe country of origin in year $t$. ",
  "\\textbf{Data:} Eurostat asylum decision and application statistics, 2008--2023, at the citizenship $\\times$ destination $\\times$ year level. ",
  "\\textbf{Method:} Triple difference-in-differences with origin$\\times$destination pair, origin$\\times$year, and destination$\\times$year fixed effects; standard errors clustered at the destination-country level. ",
  "\\textbf{Sample:} Citizenship$\\times$destination$\\times$year cells with at least 10 total first-instance decisions, covering 9 designated origin countries and 10 never-designated control origins across 22 EU+ destination countries. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\small
\\begin{tabular}{llcccccl}
\\toprule
Outcome & Spec. & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Recognition rate & Triple-diff & %.3f & %.3f & %.3f & %.3f & %s \\\\
Log applications & Triple-diff & %.3f & %.3f & %.3f & %.3f & %s \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\
Recog.\\ rate (Balkan origins) & Triple-diff & %.3f & %.3f & %.3f & %.3f & %s \\\\
Recog.\\ rate (large dests.) & Triple-diff & %.3f & %.3f & %.3f & %.3f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  beta_main, sd_y, sde_main, se_sde_main, classify(sde_main),
  beta_deter, sd_y_apps, sde_deter, se_sde_deter, classify(sde_deter),
  beta_balkan, sd_y_balkan, sde_balkan, se_sde_balkan, classify(sde_balkan),
  beta_large, sd_y_large, sde_large, se_sde_large, classify(sde_large),
  sde_notes
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

# ============================================================
# Table A1: Decision-Type Decomposition (Appendix)
# ============================================================

cat("=== Table A1: Decision-Type Decomposition ===\n")

if (!is.null(results$m_geneva) && !is.null(results$m_subsidiary)) {
  r_gen <- extract_coef(results$m_geneva)
  r_sub <- extract_coef(results$m_subsidiary)

  tabA1_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Decision-Type Decomposition: Geneva Convention vs.\\ Subsidiary Protection}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
 & (1) & (2) & (3) \\\\
 & Total Recognition & Geneva Convention & Subsidiary/Humanitarian \\\\
\\midrule
SCO Designation & %s%.3f%s & %s%.3f%s & %s%.3f%s \\\\
 & (%.3f) & (%.3f) & (%.3f) \\\\[0.5em]
\\midrule
Pair FE & Yes & Yes & Yes \\\\
Origin $\\times$ Year FE & Yes & Yes & Yes \\\\
Dest. $\\times$ Year FE & Yes & Yes & Yes \\\\[0.3em]
Observations & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is the share of first-instance decisions granting each protection type. Column (1) reproduces the main result for total recognition. Column (2) uses Geneva Convention status grants as a share of total decisions. Column (3) uses subsidiary protection and humanitarian grants combined. All specifications include the full triple-difference fixed effects. Standard errors clustered at the destination level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:decomp}
\\end{table}',
    ifelse(r2$b < 0, "$-$", ""), abs(r2$b), r2$stars,
    ifelse(r_gen$b < 0, "$-$", ""), abs(r_gen$b), r_gen$stars,
    ifelse(r_sub$b < 0, "$-$", ""), abs(r_sub$b), r_sub$stars,
    r2$s, r_gen$s, r_sub$s,
    format(r2$n, big.mark = ","),
    format(r_gen$n, big.mark = ","),
    format(r_sub$n, big.mark = ",")
  )

  writeLines(tabA1_tex, "../tables/tabA1_decomp.tex")
  cat("  Written tabA1_decomp.tex\n")
} else {
  cat("  Skipping decomposition table (insufficient data)\n")
}

cat("\n=== All tables written to tables/ ===\n")
cat(sprintf("  tab1_summary.tex\n  tab2_main.tex\n  tab3_channels.tex\n"))
cat(sprintf("  tab4_hetero.tex\n  tab5_robust.tex\n  tabA1_decomp.tex\n  tabF1_sde.tex\n"))
