# =============================================================================
# 05_tables.R — Generate all LaTeX tables for apep_0773
# Collateral Damage: When Medicaid Unwinding Overwhelms the Safety Net
# =============================================================================

source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
did_rate <- readRDS(file.path(data_dir, "did_rate.rds"))
did_ln <- readRDS(file.path(data_dir, "did_ln.rds"))
did_triple <- readRDS(file.path(data_dir, "did_triple.rds"))
did_cont <- readRDS(file.path(data_dir, "did_cont.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

dir.create("../tables", showWarnings = FALSE)

# ---------------------------------------------------------------------------
# Table 1: Summary Statistics by System Type
# ---------------------------------------------------------------------------

pre <- panel[post_unwinding == 0]
post <- panel[post_unwinding == 1]

compute_stats <- function(dt, varname) {
  x <- dt[[varname]]
  x <- x[!is.na(x)]
  list(mean = mean(x), sd = sd(x), min = min(x), max = max(x))
}

int_pre <- pre[integrated == 1]
sep_pre <- pre[integrated == 0]

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics by Eligibility System Type}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Integrated} & \\multicolumn{2}{c}{Separate} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

# Compute stats
vars_info <- list(
  list("SNAP households", "snap_hh"),
  list("SNAP rate (\\%)", "snap_rate_pct"),
  list("Total households", "total_hh"),
  list("Procedural termination rate", "proc_term_rate")
)

for (v in vars_info) {
  nm <- v[[1]]
  vr <- v[[2]]
  i_s <- compute_stats(int_pre, vr)
  s_s <- compute_stats(sep_pre, vr)
  if (vr %in% c("snap_hh", "total_hh")) {
    tab1_lines <- c(tab1_lines,
      sprintf("%s & %s & %s & %s & %s \\\\", nm,
        format(round(i_s$mean), big.mark = ","),
        format(round(i_s$sd), big.mark = ","),
        format(round(s_s$mean), big.mark = ","),
        format(round(s_s$sd), big.mark = ",")))
  } else {
    tab1_lines <- c(tab1_lines,
      sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\", nm,
        i_s$mean, i_s$sd, s_s$mean, s_s$sd))
  }
}

n_int <- length(unique(int_pre$state))
n_sep <- length(unique(sep_pre$state))
n_obs_int <- nrow(panel[integrated == 1])
n_obs_sep <- nrow(panel[integrated == 0])

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\", n_int, n_sep),
  sprintf("State-months & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
    format(n_obs_int, big.mark = ","),
    format(n_obs_sep, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Pre-unwinding period (January 2019--March 2023) summary statistics. ",
  "Integrated states share Medicaid-SNAP eligibility workers and/or IT systems. ",
  "SNAP rate is SNAP households as a share of total households from Census ACS. ",
  "Procedural termination rate is the share of Medicaid disenrollments due to procedural ",
  "(non-eligibility) reasons, cumulative through December 2023 (KFF analysis of CMS data). ",
  sprintf("N = %s state-month observations across %d states and DC.",
    format(nrow(panel), big.mark = ","),
    length(unique(panel$state))),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ---------------------------------------------------------------------------
# Table 2: Main DiD Results
# ---------------------------------------------------------------------------

extract_did <- function(model, coef_name) {
  b <- coef(model)[coef_name]
  s <- se(model)[coef_name]
  p <- fixest::pvalue(model)[coef_name]
  n <- model$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = s, p = p, n = n, stars = stars)
}

r1 <- extract_did(did_rate, "integrated:post_unwinding")
r2 <- extract_did(did_ln, "integrated:post_unwinding")
r3 <- extract_did(did_cont, "post_unwinding:proc_term_rate")

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Medicaid Unwinding on SNAP Enrollment: Difference-in-Differences}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & SNAP Rate (\\%) & ln(SNAP HH) & SNAP Rate (\\%) \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Binary treatment (integrated vs.\\ separate)}} \\\\[3pt]",
  sprintf("Integrated $\\times$ Post & %.3f%s & %.3f%s & \\\\",
    r1$b, r1$stars, r2$b, r2$stars),
  sprintf(" & (%.3f) & (%.3f) & \\\\", r1$se, r2$se),
  "[6pt]",
  "\\multicolumn{4}{l}{\\textit{Panel B: Continuous treatment (procedural termination rate)}} \\\\[3pt]",
  sprintf("Post $\\times$ Proc.~Term.~Rate & & & %.3f%s \\\\",
    r3$b, r3$stars),
  sprintf(" & & & (%.3f) \\\\", r3$se),
  "\\midrule",
  sprintf("State FE & \\checkmark & \\checkmark & \\checkmark \\\\"),
  sprintf("Month FE & \\checkmark & \\checkmark & \\checkmark \\\\"),
  sprintf("EA control & \\checkmark & \\checkmark & \\checkmark \\\\"),
  sprintf("Observations & %s & %s & %s \\\\",
    format(r1$n, big.mark = ","),
    format(r2$n, big.mark = ","),
    format(r3$n, big.mark = ",")),
  sprintf("States & 51 & 51 & 51 \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Difference-in-differences estimates of Medicaid unwinding effects on SNAP enrollment. ",
  "Panel A uses a binary treatment: states with integrated Medicaid-SNAP eligibility systems (24 states) vs.\\ ",
  "states with separate systems (27 states). Panel B uses the state-level Medicaid procedural termination rate ",
  "as a continuous treatment intensity measure. All specifications include state and month fixed effects ",
  "and control for state-specific SNAP emergency allotment termination dates. ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ---------------------------------------------------------------------------
# Table 3: Triple-Difference and Heterogeneity
# ---------------------------------------------------------------------------

r_triple <- extract_did(did_triple, "integrated:post_unwinding")

# Triple interaction coefficient
triple_int_name <- grep("high_proc", names(coef(did_triple)), value = TRUE)
r_triple_int <- extract_did(did_triple, triple_int_name)

# Level results from robustness
r_level <- extract_did(rob$level, "integrated:post_unwinding")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneity: Triple-Difference and Level Outcomes}",
  "\\label{tab:triple}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & SNAP Rate (\\%) & SNAP Households \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Triple-difference (high procedural burden)}} \\\\[3pt]",
  sprintf("Integrated $\\times$ Post & %.3f%s & \\\\",
    r_triple$b, r_triple$stars),
  sprintf(" & (%.3f) & \\\\", r_triple$se),
  sprintf("Integrated $\\times$ Post $\\times$ High Proc. & %.3f%s & \\\\",
    r_triple_int$b, r_triple_int$stars),
  sprintf(" & (%.3f) & \\\\", r_triple_int$se),
  "[6pt]",
  "\\multicolumn{3}{l}{\\textit{Panel B: Level outcome}} \\\\[3pt]",
  sprintf("Integrated $\\times$ Post & & %s%s \\\\",
    format(round(r_level$b), big.mark = ","), r_level$stars),
  sprintf(" & & (%s) \\\\",
    format(round(r_level$se), big.mark = ",")),
  "\\midrule",
  "State FE & \\checkmark & \\checkmark \\\\",
  "Month FE & \\checkmark & \\checkmark \\\\",
  "EA control & \\checkmark & \\checkmark \\\\",
  sprintf("Observations & %s & %s \\\\",
    format(did_triple$nobs, big.mark = ","),
    format(rob$level$nobs, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A presents triple-difference estimates interacting the base DiD ",
  "(integrated $\\times$ post-unwinding) with a high procedural burden indicator (above-median ",
  "Medicaid procedural termination rate). Panel B estimates the DiD effect on the level of SNAP ",
  "households rather than the SNAP participation rate. All specifications include state and month ",
  "fixed effects and control for SNAP EA termination timing. Standard errors clustered at state level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab3_lines, "../tables/tab3_triple.tex")
cat("Table 3 written.\n")

# ---------------------------------------------------------------------------
# Table 4: Robustness and Placebo
# ---------------------------------------------------------------------------

r_late <- extract_did(rob$late, "integrated:post_unwinding")
r_placebo <- extract_did(rob$placebo, "integrated:fake_post")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Placebo and Subsample Tests}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Coefficient & SE & Observations \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Pre-2023 placebo (fake post = 2022)}} \\\\[3pt]",
  sprintf("Integrated $\\times$ Fake Post & %.3f%s & (%.3f) & %s \\\\",
    r_placebo$b, r_placebo$stars, r_placebo$se,
    format(r_placebo$n, big.mark = ",")),
  "[6pt]",
  "\\multicolumn{4}{l}{\\textit{Panel B: Exclude early EA states}} \\\\[3pt]",
  sprintf("Integrated $\\times$ Post & %.3f%s & (%.3f) & %s \\\\",
    r_late$b, r_late$stars, r_late$se,
    format(r_late$n, big.mark = ",")),
  "[6pt]",
  "\\multicolumn{4}{l}{\\textit{Panel C: Main specification (reference)}} \\\\[3pt]",
  sprintf("Integrated $\\times$ Post & %.3f%s & (%.3f) & %s \\\\",
    r1$b, r1$stars, r1$se,
    format(r1$n, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A tests for pre-existing differential trends by assigning a ",
  "placebo post-period starting in January 2022, using only pre-2023 data. Panel B excludes ",
  "states that terminated SNAP emergency allotments before 2023, ensuring the sample captures ",
  "only the unwinding period variation. Panel C reproduces the main specification (Table~\\ref{tab:main}, ",
  "column 1) for comparison. All specifications include state and month FE with state-clustered SEs. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# ---------------------------------------------------------------------------
# Table F1: Standardized Effect Size (SDE) Appendix
# ---------------------------------------------------------------------------

# SD(Y) from pre-unwinding period (unconditional)
sd_snap_rate <- sd(pre$snap_rate_pct, na.rm = TRUE)
sd_ln_snap <- sd(pre$ln_snap, na.rm = TRUE)
sd_proc <- sd(pre$proc_term_rate, na.rm = TRUE)

# SDE for binary treatment outcomes
beta_rate <- coef(did_rate)["integrated:post_unwinding"]
se_rate <- se(did_rate)["integrated:post_unwinding"]
sde_rate <- beta_rate / sd_snap_rate
se_sde_rate <- se_rate / sd_snap_rate

beta_ln <- coef(did_ln)["integrated:post_unwinding"]
se_ln <- se(did_ln)["integrated:post_unwinding"]
sde_ln <- beta_ln / sd_ln_snap
se_sde_ln <- se_ln / sd_ln_snap

# SDE for continuous treatment: beta * SD(X) / SD(Y)
beta_cont <- coef(did_cont)["post_unwinding:proc_term_rate"]
se_cont <- se(did_cont)["post_unwinding:proc_term_rate"]
sde_cont <- beta_cont * sd_proc / sd_snap_rate
se_sde_cont <- se_cont * sd_proc / sd_snap_rate

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows <- list(
  list("SNAP rate (\\%)", "Binary", beta_rate, "---", sd_snap_rate,
       sde_rate, se_sde_rate, classify(sde_rate)),
  list("ln(SNAP HH)", "Binary", beta_ln, "---", sd_ln_snap,
       sde_ln, se_sde_ln, classify(sde_ln)),
  list("SNAP rate (\\%)", "Continuous", beta_cont, sd_proc, sd_snap_rate,
       sde_cont, se_sde_cont, classify(sde_cont))
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the 2023--2024 Medicaid unwinding cause cross-program ",
  "administrative spillovers that reduce SNAP enrollment in states with integrated eligibility systems? ",
  "\\textbf{Policy mechanism:} The end of the COVID-era Medicaid continuous enrollment provision ",
  "triggered 94 million eligibility redeterminations starting April 2023; in states where the same ",
  "workers and IT systems process both Medicaid and SNAP applications, this administrative surge ",
  "crowded out SNAP processing capacity, causing eligible households to lose food assistance ",
  "through procedural rather than eligibility-based channels. ",
  "\\textbf{Outcome definition:} SNAP participation rate (SNAP households as share of total ",
  "households from Census ACS) and log SNAP households, at the state-month level. ",
  "\\textbf{Treatment:} Binary (integrated vs.\\ separate Medicaid-SNAP eligibility system) ",
  "and continuous (state-level Medicaid procedural termination rate from CMS data). ",
  "\\textbf{Data:} Census ACS state-level SNAP participation (2019--2023), expanded to monthly; ",
  "CMS Medicaid unwinding metrics; KFF integrated system classification. ",
  sprintf("N = %s state-month observations across %d states and DC. ",
    format(nrow(panel), big.mark = ","),
    length(unique(panel$state))),
  "\\textbf{Method:} Two-way fixed effects DiD (state + month FE) with state-clustered standard errors; ",
  "continuous treatment intensity specification uses Medicaid procedural termination rate. ",
  "\\textbf{Sample:} All 50 states and DC, January 2019 through December 2023; 24 integrated-system states ",
  "as treated, 27 separate-system states as control. ",
  "For binary treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
  "For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, ",
  "giving the effect of a one-standard-deviation change in treatment intensity. ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (r in sde_rows) {
  sdx_str <- if (is.character(r[[4]])) r[[4]] else sprintf("%.3f", r[[4]])
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %s & %.3f & %s & %.3f & %.3f & %.3f & %s \\\\",
      r[[1]], r[[2]], r[[3]], sdx_str, r[[5]], r[[6]], r[[7]], r[[8]]))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize",
  sde_notes,
  "}"  ,
  "\\end{table}")

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
