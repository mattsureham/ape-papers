## 05_tables.R — Generate all tables (V1: zero figures, all results in tables)
## apep_0652: EPCS Mandates and Opioid Mortality

source("00_packages.R")

panel <- data.table::fread("../data/analysis_panel.csv")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
message("Generating Table 1: Summary Statistics...")

# Compute summary stats
sum_vars <- c("rx_opioid_rate", "synth_opioid_rate", "heroin_rate",
              "all_opioid_rate", "cocaine_rate", "psychostim_rate",
              "total_overdose_rate", "population")

labels <- c("Rx opioid deaths per 100K (T40.2)",
            "Synthetic opioid deaths per 100K (T40.4)",
            "Heroin deaths per 100K (T40.1)",
            "All opioid deaths per 100K",
            "Cocaine deaths per 100K (T40.5)",
            "Psychostimulant deaths per 100K (T43.6)",
            "Total overdose deaths per 100K",
            "Population (millions)")

stats_list <- lapply(seq_along(sum_vars), function(i) {
  v <- sum_vars[i]
  x <- panel[[v]]
  if (v == "population") x <- x / 1e6
  data.frame(
    Variable = labels[i],
    Mean = round(mean(x, na.rm = TRUE), 2),
    SD = round(sd(x, na.rm = TRUE), 2),
    Min = round(min(x, na.rm = TRUE), 2),
    Max = round(max(x, na.rm = TRUE), 2),
    N = sum(!is.na(x))
  )
})
stats_df <- do.call(rbind, stats_list)

# Write LaTeX table
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lrrrrr}\n")
cat("\\toprule\n")
cat("Variable & Mean & SD & Min & Max & N \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{6}{l}{\\textit{Panel A: Opioid mortality rates (per 100,000)}} \\\\\n")
for (i in 1:4) {
  cat(sprintf("%s & %.2f & %.2f & %.2f & %.2f & %d \\\\\n",
              stats_df$Variable[i], stats_df$Mean[i], stats_df$SD[i],
              stats_df$Min[i], stats_df$Max[i], stats_df$N[i]))
}
cat("\\addlinespace\n")
cat("\\multicolumn{6}{l}{\\textit{Panel B: Placebo outcomes (per 100,000)}} \\\\\n")
for (i in 5:7) {
  cat(sprintf("%s & %.2f & %.2f & %.2f & %.2f & %d \\\\\n",
              stats_df$Variable[i], stats_df$Mean[i], stats_df$SD[i],
              stats_df$Min[i], stats_df$Max[i], stats_df$N[i]))
}
cat("\\addlinespace\n")
cat("\\multicolumn{6}{l}{\\textit{Panel C: Demographics}} \\\\\n")
cat(sprintf("%s & %.2f & %.2f & %.2f & %.2f & %d \\\\\n",
            stats_df$Variable[8], stats_df$Mean[8], stats_df$SD[8],
            stats_df$Min[8], stats_df$Max[8], stats_df$N[8]))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
n_states <- uniqueN(panel$state_abbr)
n_years <- paste(range(panel$year), collapse = "--")
n_obs <- nrow(panel)
n_treated <- uniqueN(panel[group > 0, state_abbr])
cat(sprintf("\\item \\textit{Notes:} N = %d state-years (%d states, %s). %d states adopted EPCS mandates during the sample period. Mortality rates are 12-month rolling counts per 100,000 population. Source: CDC VSRR Provisional Drug Overdose Deaths and Census ACS.\n",
            n_obs, n_states, n_years, n_treated))
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table 2: Main Results — Opioid Subtype Decomposition
# ============================================================================
message("Generating Table 2: Main Results...")

# Extract all CS-DiD results
make_row <- function(agg, label) {
  att <- agg$overall.att
  se_val <- agg$overall.se
  p <- 2 * pnorm(-abs(att / se_val))
  ci_lo <- att - 1.96 * se_val
  ci_hi <- att + 1.96 * se_val
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  list(label = label, att = att, se = se_val, p = p, ci_lo = ci_lo, ci_hi = ci_hi, stars = stars)
}

rows <- list(
  make_row(results$agg_rx, "Rx opioid rate (T40.2)"),
  make_row(results$agg_synth, "Synthetic opioid rate (T40.4)"),
  make_row(results$agg_heroin, "Heroin rate (T40.1)"),
  make_row(results$agg_total_opioid, "All opioid rate"),
  make_row(results$agg_cocaine, "Cocaine rate (T40.5)"),
  make_row(results$agg_psychostim, "Psychostimulant rate (T43.6)")
)

sink("../tables/tab2_main.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of EPCS Mandates on Drug Overdose Mortality by Substance Type}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Outcome & ATT & SE & 95\\% CI & Channel \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Opioid outcomes (targeted by EPCS)}} \\\\\n")
for (i in 1:4) {
  r <- rows[[i]]
  channel <- c("Direct (prescription)", "Substitution (illicit)", "Substitution (illicit)", "Net effect")[i]
  cat(sprintf("%s & %.3f%s & (%.3f) & [%.3f, %.3f] & %s \\\\\n",
              r$label, r$att, r$stars, r$se, r$ci_lo, r$ci_hi, channel))
}
cat("\\addlinespace\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Placebo outcomes (not targeted by EPCS)}} \\\\\n")
for (i in 5:6) {
  r <- rows[[i]]
  cat(sprintf("%s & %.3f%s & (%.3f) & [%.3f, %.3f] & Placebo \\\\\n",
              r$label, r$att, r$stars, r$se, r$ci_lo, r$ci_hi))
}
cat("\\midrule\n")
cat(sprintf("States & \\multicolumn{4}{c}{%d} \\\\\n", uniqueN(panel$state_abbr)))
cat(sprintf("Treated states & \\multicolumn{4}{c}{%d} \\\\\n", uniqueN(panel[group > 0, state_abbr])))
cat(sprintf("State-years & \\multicolumn{4}{c}{%d} \\\\\n", nrow(panel)))
cat("Estimator & \\multicolumn{4}{c}{Callaway--Sant'Anna} \\\\\n")
cat("Control group & \\multicolumn{4}{c}{Not-yet-treated} \\\\\n")
cat("Clustering & \\multicolumn{4}{c}{State} \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Each row reports the overall ATT from a Callaway--Sant'Anna (2021) staggered DiD estimator with doubly robust estimation. The outcome is the 12-month rolling death count per 100,000 population. Standard errors in parentheses, 95\\% confidence intervals in brackets. Panel A shows outcomes directly or indirectly affected by EPCS mandates. Panel B shows placebo outcomes not targeted by e-prescribing requirements. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table 3: Event Study Coefficients
# ============================================================================
message("Generating Table 3: Event Study...")

es_rx <- results$es_rx

sink("../tables/tab3_eventstudy.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Event Study: Effect of EPCS Mandates on Prescription Opioid Death Rate}\n")
cat("\\label{tab:eventstudy}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Event Time & ATT & SE & 95\\% CI \\\\\n")
cat("\\midrule\n")

for (i in seq_along(es_rx$egt)) {
  e <- es_rx$egt[i]
  att <- es_rx$att.egt[i]
  se_val <- es_rx$se.egt[i]
  ci_lo <- att - 1.96 * se_val
  ci_hi <- att + 1.96 * se_val
  p <- 2 * pnorm(-abs(att / se_val))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

  if (e == -1) cat("\\addlinespace\n")  # visual separator before ref period
  if (e == 0) {
    cat("\\addlinespace\n")
    cat(sprintf("$e = %d$ & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\\n",
                e, att, stars, se_val, ci_lo, ci_hi))
  } else {
    cat(sprintf("$e = %d$ & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\\n",
                e, att, stars, se_val, ci_lo, ci_hi))
  }
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Event study coefficients from Callaway--Sant'Anna (2021) estimator, aggregated by event time. The outcome is the prescription opioid (T40.2) death rate per 100,000. Event time $e = 0$ is the year of EPCS mandate adoption. Pre-treatment coefficients ($e < 0$) test parallel trends. Standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table 4: Robustness
# ============================================================================
message("Generating Table 4: Robustness...")

sa_rx_agg <- aggregate(rob_results$sa_rx, agg = "ATT")
sa_coef <- sa_rx_agg["ATT", "Estimate"]
sa_se <- sa_rx_agg["ATT", "Std. Error"]

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Robustness of EPCS Effect on Prescription Opioid Death Rate}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Specification & ATT & SE & 95\\% CI & N \\\\\n")
cat("\\midrule\n")

# Baseline
b <- results$agg_rx
cat(sprintf("Baseline CS-DiD & %.3f & (%.3f) & [%.3f, %.3f] & %d \\\\\n",
            b$overall.att, b$overall.se,
            b$overall.att - 1.96 * b$overall.se, b$overall.att + 1.96 * b$overall.se,
            nrow(panel)))

# Sun-Abraham
cat(sprintf("Sun--Abraham & %.3f & (%.3f) & [%.3f, %.3f] & %d \\\\\n",
            sa_coef, sa_se, sa_coef - 1.96 * sa_se, sa_coef + 1.96 * sa_se,
            nrow(panel[group != 2024])))

# Never-treated controls
nt <- rob_results$agg_rx_nt
cat(sprintf("Never-treated controls & %.3f & (%.3f) & [%.3f, %.3f] & %d \\\\\n",
            nt$overall.att, nt$overall.se,
            nt$overall.att - 1.96 * nt$overall.se, nt$overall.att + 1.96 * nt$overall.se,
            nrow(panel)))

# Leave-one-out (no NY)
nny <- rob_results$agg_rx_no_ny
cat(sprintf("Drop New York & %.3f & (%.3f) & [%.3f, %.3f] & %d \\\\\n",
            nny$overall.att, nny$overall.se,
            nny$overall.att - 1.96 * nny$overall.se, nny$overall.att + 1.96 * nny$overall.se,
            nrow(panel[state_abbr != "NY"])))

# Restrict to 2015-2021
r21 <- rob_results$agg_rx_2021
cat(sprintf("Restrict 2015--2021 & %.3f & (%.3f) & [%.3f, %.3f] & %d \\\\\n",
            r21$overall.att, r21$overall.se,
            r21$overall.att - 1.96 * r21$overall.se, r21$overall.att + 1.96 * r21$overall.se,
            nrow(panel[year <= 2021])))

# TWFE
twfe <- results$twfe_rx
twfe_b <- coef(twfe)["treated"]
twfe_s <- se(twfe)["treated"]
cat(sprintf("TWFE & %.3f & (%.3f) & [%.3f, %.3f] & %d \\\\\n",
            twfe_b, twfe_s, twfe_b - 1.96 * twfe_s, twfe_b + 1.96 * twfe_s,
            nrow(panel)))

cat("\\midrule\n")
cat(sprintf("Wild cluster bootstrap $p$-value & \\multicolumn{4}{c}{%.4f} \\\\\n",
            rob_results$boot_rx$p_val))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Each row reports an alternative estimate of the effect of EPCS mandates on the prescription opioid (T40.2) death rate per 100,000. The baseline uses the Callaway--Sant'Anna (2021) estimator with not-yet-treated controls and doubly robust estimation. Wild cluster bootstrap uses Webb weights with 999 iterations. Standard errors in parentheses, 95\\% confidence intervals in brackets.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table F1: Standardized Effect Sizes (MANDATORY)
# ============================================================================
message("Generating SDE table...")

# Compute SDEs for main outcomes
outcomes <- list(
  list(name = "Rx opioid rate (T40.2)", var = "rx_opioid_rate",
       agg = results$agg_rx, spec = "CS-DiD"),
  list(name = "Synth opioid rate (T40.4)", var = "synth_opioid_rate",
       agg = results$agg_synth, spec = "CS-DiD"),
  list(name = "Heroin rate (T40.1)", var = "heroin_rate",
       agg = results$agg_heroin, spec = "CS-DiD"),
  list(name = "All opioid rate", var = "all_opioid_rate",
       agg = results$agg_total_opioid, spec = "CS-DiD"),
  list(name = "Total overdose rate", var = "total_overdose_rate",
       agg = NULL, spec = "CS-DiD")
)

# For total overdose, get from TWFE if CS not available
if (is.null(outcomes[[5]]$agg)) {
  twfe_total <- feols(total_overdose_rate ~ treated | state_id + year,
                      data = panel[, state_id := as.integer(factor(state_abbr))],
                      cluster = ~state_id)
  outcomes[[5]]$beta <- coef(twfe_total)["treated"]
  outcomes[[5]]$se_val <- se(twfe_total)["treated"]
}

classify_sde <- function(s) {
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

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{llcccccc}\n")
cat("\\toprule\n")
cat("Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")

for (o in outcomes) {
  sd_y <- sd(panel[[o$var]], na.rm = TRUE)
  if (!is.null(o$agg)) {
    beta <- o$agg$overall.att
    se_val <- o$agg$overall.se
  } else {
    beta <- o$beta
    se_val <- o$se_val
  }
  sde <- beta / sd_y
  se_sde <- se_val / sd_y
  classif <- classify_sde(sde)
  cat(sprintf("%s & %s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
              o$name, o$spec, beta, se_val, sd_y, sde, se_sde, classif))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) column is omitted. SD($Y$) is the unconditional standard deviation from the summary statistics, before conditioning on fixed effects.\n")
cat("\n")
cat("\\textbf{Research question:} Do state EPCS mandates reduce opioid overdose mortality, and if so, through which channel (prescription vs.\\ illicit)?\n")
cat("\\textbf{Treatment:} Binary; state adopted mandatory electronic prescribing for controlled substances.\n")
cat(sprintf("\\textbf{Data:} CDC VSRR Provisional Drug Overdose Deaths, %d--%d, state-year panel, N = %d.\n",
            min(panel$year), max(panel$year), nrow(panel)))
cat("\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator, state-clustered standard errors.\n")
cat(sprintf("\\textbf{Sample:} %d states, %d treated.\n",
            uniqueN(panel$state_abbr), uniqueN(panel[group > 0, state_abbr])))
cat("\n")
cat("Classification thresholds (7 categories): large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$). Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n")
cat("\\end{table}\n")
sink()

message("\n=== All tables generated ===")
message("Tables saved to: ../tables/")
