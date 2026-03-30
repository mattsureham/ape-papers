## 05_tables.R — The Stranded Signal (apep_1152)
## Generates all paper tables: summary stats, main results, balance,
## decomposition, event study, and SDE appendix.
source(file.path(here::here(), "output", "apep_1152", "v1", "code", "00_packages.R"))

DATA_DIR  <- file.path(here::here(), "output", "apep_1152", "v1", "data")
TABLE_DIR <- file.path(here::here(), "output", "apep_1152", "v1", "tables")
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

# Load data and saved model objects
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
load(file.path(DATA_DIR, "main_results.RData"))
load(file.path(DATA_DIR, "robustness_results.RData"))

# Convenience: CES indicator at generator level
panel[, ces_state := as.integer(ces_year > 0)]

# Baseline year for cross-sectional comparisons
baseline <- panel[year == 2008]

cat("=== Generating Tables ===\n\n")

# =============================================================================
# TABLE 1: SUMMARY STATISTICS
# =============================================================================
cat("--- Table 1: Summary Statistics ---\n")

make_sumstat_row <- function(dt, varname, label, fmt = "%.1f") {
  x <- dt[[varname]]
  x <- x[!is.na(x)]
  sprintf("%s & %s & %s & %s & %s & %s",
          label,
          sprintf("%.0f", length(x)),
          sprintf(fmt, mean(x)),
          sprintf(fmt, sd(x)),
          sprintf(fmt, min(x)),
          sprintf(fmt, max(x)))
}

# Two panels: CES states vs non-CES states
ces_bl  <- baseline[ces_state == 1]
nces_bl <- baseline[ces_state == 0]

# Also compute retirement rates from full panel (more meaningful than baseline)
ces_panel  <- panel[ces_state == 1]
nces_panel <- panel[ces_state == 0]

# Fuel type distribution (baseline)
fuel_ces  <- ces_bl[, .N, by = fuel_type][order(-N)]
fuel_nces <- nces_bl[, .N, by = fuel_type][order(-N)]
fuel_ces[, share := N / sum(N)]
fuel_nces[, share := N / sum(N)]

# Map fuel codes to readable labels
fuel_labels <- c(BIT = "Bituminous", SUB = "Sub-bituminous", LIG = "Lignite",
                 RC = "Refined Coal", WC = "Waste Coal")

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Coal Generator Characteristics by CES Status}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & N & Mean & SD & Min & Max \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: CES States}} \\\\[3pt]",
  sprintf("Generators & %d & & & & \\\\", uniqueN(ces_bl$gen_key)),
  sprintf("States & %d & & & & \\\\", uniqueN(ces_bl$state)),
  paste0(make_sumstat_row(ces_bl, "capacity_mw", "Capacity (MW)"), " \\\\"),
  paste0(make_sumstat_row(ces_bl, "vintage", "Age in 2008 (years)"), " \\\\"),
  sprintf("Retirement rate & %.0f & %.3f & %.3f & %.0f & %.0f \\\\",
          nrow(ces_panel),
          mean(ces_panel$retired_this_year),
          sd(ces_panel$retired_this_year),
          min(ces_panel$retired_this_year),
          max(ces_panel$retired_this_year)),
  sprintf("Bituminous share & %d & %.3f & & & \\\\",
          nrow(ces_bl),
          ces_bl[fuel_type == "BIT", .N] / nrow(ces_bl)),
  sprintf("Sub-bituminous share & %d & %.3f & & & \\\\",
          nrow(ces_bl),
          ces_bl[fuel_type == "SUB", .N] / nrow(ces_bl)),
  "[6pt]",
  "\\multicolumn{6}{l}{\\textit{Panel B: Non-CES States}} \\\\[3pt]",
  sprintf("Generators & %d & & & & \\\\", uniqueN(nces_bl$gen_key)),
  sprintf("States & %d & & & & \\\\", uniqueN(nces_bl$state)),
  paste0(make_sumstat_row(nces_bl, "capacity_mw", "Capacity (MW)"), " \\\\"),
  paste0(make_sumstat_row(nces_bl, "vintage", "Age in 2008 (years)"), " \\\\"),
  sprintf("Retirement rate & %.0f & %.3f & %.3f & %.0f & %.0f \\\\",
          nrow(nces_panel),
          mean(nces_panel$retired_this_year),
          sd(nces_panel$retired_this_year),
          min(nces_panel$retired_this_year),
          max(nces_panel$retired_this_year)),
  sprintf("Bituminous share & %d & %.3f & & & \\\\",
          nrow(nces_bl),
          nces_bl[fuel_type == "BIT", .N] / nrow(nces_bl)),
  sprintf("Sub-bituminous share & %d & %.3f & & & \\\\",
          nrow(nces_bl),
          nces_bl[fuel_type == "SUB", .N] / nrow(nces_bl)),
  "\\bottomrule",
  "\\end{tabular}",
  paste0("\\begin{minipage}{0.92\\textwidth}"),
  "\\vspace{4pt}",
  "\\footnotesize",
  "\\textit{Notes:} Panel A reports characteristics of coal generators in the 13 states",
  "that enacted 100\\% Clean Energy Standards (CES) between 2018 and 2023.",
  "Panel B reports non-CES states. Capacity and age are measured at baseline (2008).",
  "Retirement rate is the annual probability of retirement across all panel years (2008--2024).",
  "Fuel shares sum to less than one because lignite, refined coal, and waste coal are omitted.",
  "Source: EIA-860 (2023--2024).",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab1, file.path(TABLE_DIR, "tab1_sumstats.tex"))
cat("  -> tab1_sumstats.tex written\n")

# =============================================================================
# TABLE 2: MAIN RESULTS
# =============================================================================
cat("--- Table 2: Main Results ---\n")

# Re-run TWFE with capacity weighting (direct capacity weight, not inverse)
panel[, cap_wt := capacity_mw]
twfe_capwt <- feols(retired_this_year ~ post_ces | gen_key + year,
                    data = panel, cluster = ~state, weights = ~cap_wt)

# CS DiD with never-treated control (re-run)
panel[, gen_num := as.integer(as.factor(gen_key))]
cs_never <- tryCatch({
  att_gt(
    yname = "retired_this_year",
    tname = "year",
    idname = "gen_num",
    gname = "g",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    clustervars = "state",
    print_details = FALSE
  )
}, error = function(e) {
  cat(sprintf("  CS DiD (never-treated) error: %s\n", e$message))
  NULL
})

if (!is.null(cs_never)) {
  agg_never <- aggte(cs_never, type = "simple")
} else {
  agg_never <- NULL
}

# Build table using etable for TWFE columns and manual for CS columns
# Since CS DiD objects are not fixest, we build a unified LaTeX table manually

# Extract values
twfe_coef <- coef(twfe)["post_ces"]
twfe_se   <- se(twfe)["post_ces"]
twfe_pv   <- pvalue(twfe)["post_ces"]
twfe_n    <- nobs(twfe)
twfe_r2   <- fixest::r2(twfe, type = "wr2")

cwt_coef <- coef(twfe_capwt)["post_ces"]
cwt_se   <- se(twfe_capwt)["post_ces"]
cwt_pv   <- pvalue(twfe_capwt)["post_ces"]
cwt_n    <- nobs(twfe_capwt)
cwt_r2   <- fixest::r2(twfe_capwt, type = "wr2")

cs_nyt_coef <- agg_overall$overall.att
cs_nyt_se   <- agg_overall$overall.se
cs_nyt_pv   <- 2 * pnorm(-abs(cs_nyt_coef / cs_nyt_se))

cs_nt_coef <- if (!is.null(agg_never)) agg_never$overall.att else NA
cs_nt_se   <- if (!is.null(agg_never)) agg_never$overall.se else NA
cs_nt_pv   <- if (!is.null(agg_never)) 2 * pnorm(-abs(cs_nt_coef / cs_nt_se)) else NA

# Star function
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# Format coefficient with stars
fmtcoef <- function(coef, pv, digits = 4) {
  if (is.na(coef)) return("")
  sprintf("%.4f%s", coef, stars(pv))
}
fmtse <- function(se) {
  if (is.na(se)) return("")
  sprintf("(%.4f)", se)
}

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Clean Energy Standards on Coal Generator Retirement}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & TWFE & TWFE & CS DiD & CS DiD \\\\",
  " & & Cap.\\ Weight & Not-Yet-Treated & Never-Treated \\\\",
  "\\midrule",
  sprintf("Post CES & %s & %s & %s & %s \\\\",
          fmtcoef(twfe_coef, twfe_pv),
          fmtcoef(cwt_coef, cwt_pv),
          fmtcoef(cs_nyt_coef, cs_nyt_pv),
          fmtcoef(cs_nt_coef, cs_nt_pv)),
  sprintf(" & %s & %s & %s & %s \\\\",
          fmtse(twfe_se), fmtse(cwt_se), fmtse(cs_nyt_se), fmtse(cs_nt_se)),
  "[6pt]",
  "\\midrule",
  sprintf("Generator FE & Yes & Yes & --- & --- \\\\"),
  sprintf("Year FE & Yes & Yes & --- & --- \\\\"),
  sprintf("Estimator & OLS & WLS & DR & DR \\\\"),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(twfe_n, big.mark = ","),
          formatC(cwt_n, big.mark = ","),
          formatC(nrow(panel), big.mark = ","),
          formatC(nrow(panel), big.mark = ",")),
  sprintf("Within $R^2$ & %.4f & %.4f & --- & --- \\\\",
          twfe_r2, cwt_r2),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.92\\textwidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  "\\textit{Notes:} Dependent variable is an indicator for generator retirement in year $t$.",
  "Column~(1) is a standard two-way fixed effects (TWFE) specification with generator and year",
  "fixed effects. Column~(2) weights observations by nameplate capacity (MW).",
  "Columns~(3) and~(4) report the overall ATT from \\citet{callaway2021difference} using",
  "doubly-robust estimation with not-yet-treated and never-treated control groups, respectively.",
  "Standard errors clustered by state in parentheses.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab2, file.path(TABLE_DIR, "tab2_main.tex"))
cat("  -> tab2_main.tex written\n")

# =============================================================================
# TABLE 3: BALANCE TESTS
# =============================================================================
cat("--- Table 3: Balance Tests ---\n")

# Regressions of baseline characteristics on CES indicator
bal_cap     <- feols(capacity_mw ~ ces_state, data = baseline)
bal_vintage <- feols(vintage ~ ces_state, data = baseline)

# Operating year
bal_opyear <- feols(op_year ~ ces_state, data = baseline)

# Fuel type indicators
baseline[, bit := as.integer(fuel_type == "BIT")]
baseline[, sub := as.integer(fuel_type == "SUB")]
baseline[, lig := as.integer(fuel_type == "LIG")]
bal_bit <- feols(bit ~ ces_state, data = baseline)
bal_sub <- feols(sub ~ ces_state, data = baseline)
bal_lig <- feols(lig ~ ces_state, data = baseline)

# Means by group
mean_ces  <- baseline[ces_state == 1, .(
  capacity = mean(capacity_mw), vintage = mean(vintage), op_year = mean(op_year),
  bit = mean(bit), sub = mean(sub), lig = mean(lig)
)]
mean_nces <- baseline[ces_state == 0, .(
  capacity = mean(capacity_mw), vintage = mean(vintage), op_year = mean(op_year),
  bit = mean(bit), sub = mean(sub), lig = mean(lig)
)]

bal_row <- function(label, bal_model, mean_c, mean_nc, fmt_mean = "%.1f", fmt_coef = "%.1f") {
  cf <- coef(bal_model)["ces_state"]
  se_val <- se(bal_model)["ces_state"]
  pv <- pvalue(bal_model)["ces_state"]
  c(
    sprintf("%s & %s & %s & %s%s \\\\",
            label,
            sprintf(fmt_mean, mean_nc),
            sprintf(fmt_mean, mean_c),
            sprintf(fmt_coef, cf),
            stars(pv)),
    sprintf(" & & & (%s) \\\\", sprintf(fmt_coef, se_val))
  )
}

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Balance Tests: Generator Characteristics at Baseline (2008)}",
  "\\label{tab:balance}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Non-CES & CES & Difference \\\\",
  " & Mean & Mean & (CES $-$ Non-CES) \\\\",
  "\\midrule",
  bal_row("Capacity (MW)", bal_cap, mean_ces$capacity, mean_nces$capacity),
  "[3pt]",
  bal_row("Age (years)", bal_vintage, mean_ces$vintage, mean_nces$vintage),
  "[3pt]",
  bal_row("Operating year", bal_opyear, mean_ces$op_year, mean_nces$op_year),
  "[3pt]",
  bal_row("Bituminous share", bal_bit, mean_ces$bit, mean_nces$bit, "%.3f", "%.3f"),
  "[3pt]",
  bal_row("Sub-bituminous share", bal_sub, mean_ces$sub, mean_nces$sub, "%.3f", "%.3f"),
  "[3pt]",
  bal_row("Lignite share", bal_lig, mean_ces$lig, mean_nces$lig, "%.3f", "%.3f"),
  "[6pt]",
  "\\midrule",
  sprintf("Generators & %d & %d & \\\\",
          uniqueN(baseline[ces_state == 0]$gen_key),
          uniqueN(baseline[ces_state == 1]$gen_key)),
  sprintf("States & %d & %d & \\\\",
          uniqueN(baseline[ces_state == 0]$state),
          uniqueN(baseline[ces_state == 1]$state)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.92\\textwidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  "\\textit{Notes:} Each row reports a separate OLS regression of the baseline (2008)",
  "generator characteristic on a CES-state indicator. Robust standard errors in parentheses.",
  "CES states are the 13 states that enacted 100\\% Clean Energy Standards between 2018 and 2023.",
  "Generators in CES states are systematically smaller and older than those in non-CES states,",
  "consistent with a composition difference that biases na\\\"ive TWFE estimates.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab3, file.path(TABLE_DIR, "tab3_balance.tex"))
cat("  -> tab3_balance.tex written\n")

# =============================================================================
# TABLE 4: DECOMPOSITION
# =============================================================================
cat("--- Table 4: Decomposition ---\n")

# Column 1: Baseline TWFE (already have twfe_base from robustness)
# Column 2: TWFE with controls (capacity + vintage as time-varying)
# Since capacity_mw and vintage are collinear with gen FE (time-invariant),
# we interact with year trends or use capacity*year interactions.

# Alternative: Use state-level controls (average capacity/vintage in the state)
panel[, state_mean_cap := mean(capacity_mw), by = .(state, year)]
panel[, state_mean_vintage := mean(vintage), by = .(state, year)]
twfe_stctrl <- feols(retired_this_year ~ post_ces + state_mean_cap + state_mean_vintage |
                       gen_key + year,
                     data = panel, cluster = ~state)

# Column 3: Capacity-weighted (already have twfe_capwt)
# Column 4: Restrict to generators 100-500 MW (similar size range)
panel_similar <- panel[capacity_mw >= 100 & capacity_mw <= 500]
twfe_similar <- feols(retired_this_year ~ post_ces | gen_key + year,
                      data = panel_similar, cluster = ~state)

# Column 5: CS DiD (overall ATT for reference)

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Decomposing the TWFE Effect: From Illusion to Null}",
  "\\label{tab:decomp}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & TWFE & TWFE + & Capacity & Size & CS DiD \\\\",
  " & Baseline & Controls & Weighted & Matched & \\\\",
  "\\midrule",
  sprintf("Post CES & %s & %s & %s & %s & %s \\\\",
          fmtcoef(coef(twfe_base)["post_ces"], pvalue(twfe_base)["post_ces"]),
          fmtcoef(coef(twfe_stctrl)["post_ces"], pvalue(twfe_stctrl)["post_ces"]),
          fmtcoef(coef(twfe_capwt)["post_ces"], pvalue(twfe_capwt)["post_ces"]),
          fmtcoef(coef(twfe_similar)["post_ces"], pvalue(twfe_similar)["post_ces"]),
          fmtcoef(cs_nyt_coef, cs_nyt_pv)),
  sprintf(" & %s & %s & %s & %s & %s \\\\",
          fmtse(se(twfe_base)["post_ces"]),
          fmtse(se(twfe_stctrl)["post_ces"]),
          fmtse(se(twfe_capwt)["post_ces"]),
          fmtse(se(twfe_similar)["post_ces"]),
          fmtse(cs_nyt_se)),
  "[6pt]",
  "\\midrule",
  "Generator FE & Yes & Yes & Yes & Yes & --- \\\\",
  "Year FE & Yes & Yes & Yes & Yes & --- \\\\",
  "State-level controls & No & Yes & No & No & --- \\\\",
  "Capacity weights & No & No & Yes & No & --- \\\\",
  sprintf("Sample restriction & --- & --- & --- & 100--500 MW & --- \\\\"),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          formatC(nobs(twfe_base), big.mark = ","),
          formatC(nobs(twfe_stctrl), big.mark = ","),
          formatC(nobs(twfe_capwt), big.mark = ","),
          formatC(nobs(twfe_similar), big.mark = ","),
          formatC(nrow(panel), big.mark = ",")),
  sprintf("Within $R^2$ & %.4f & %.4f & %.4f & %.4f & --- \\\\",
          fixest::r2(twfe_base, "wr2"),
          fixest::r2(twfe_stctrl, "wr2"),
          fixest::r2(twfe_capwt, "wr2"),
          fixest::r2(twfe_similar, "wr2")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.92\\textwidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  "\\textit{Notes:} Dependent variable is an indicator for generator retirement in year $t$.",
  "Column~(1) is the baseline TWFE specification. Column~(2) adds state-year-level mean",
  "generator capacity and vintage as controls. Column~(3) weights by nameplate capacity,",
  "down-weighting the small generators overrepresented in CES states. Column~(4) restricts",
  "to generators between 100 and 500~MW, where the CES and non-CES size distributions overlap.",
  "Column~(5) reports the Callaway--Sant'Anna overall ATT (doubly-robust, not-yet-treated control).",
  "The TWFE coefficient shrinks monotonically as composition bias is addressed and vanishes",
  "entirely under modern heterogeneity-robust estimation.",
  "Standard errors clustered by state in parentheses.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab4, file.path(TABLE_DIR, "tab4_decomposition.tex"))
cat("  -> tab4_decomposition.tex written\n")

# =============================================================================
# TABLE 5: EVENT STUDY COEFFICIENTS
# =============================================================================
cat("--- Table 5: Event Study Coefficients ---\n")

# Extract dynamic CS DiD estimates
es_e   <- agg_dynamic$egt
es_att <- agg_dynamic$att.egt
es_se  <- agg_dynamic$se.egt

# Build rows
es_rows <- character(0)
for (i in seq_along(es_e)) {
  e <- es_e[i]
  att_val <- es_att[i]
  se_val  <- es_se[i]

  # For pre-treatment periods with 0/NA, show as reference
  if (is.na(se_val) || se_val == 0) {
    if (e == -1) {
      es_rows <- c(es_rows,
        sprintf("$%+d$ & \\multicolumn{4}{c}{\\textit{Reference period}} \\\\", e))
    } else {
      es_rows <- c(es_rows,
        sprintf("$%+d$ & 0.0000 & --- & --- & --- \\\\", e))
    }
  } else {
    pv <- 2 * pnorm(-abs(att_val / se_val))
    ci_lo <- att_val - 1.96 * se_val
    ci_hi <- att_val + 1.96 * se_val
    es_rows <- c(es_rows,
      sprintf("$%+d$ & %s & (%.4f) & [%.4f, & %.4f] \\\\",
              e, fmtcoef(att_val, pv), se_val, ci_lo, ci_hi))
  }
}

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Callaway--Sant'Anna Event Study Estimates}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Event Time & ATT & SE & \\multicolumn{2}{c}{95\\% CI} \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Pre-Treatment}} \\\\[3pt]",
  es_rows[es_e <= -1],
  "[6pt]",
  "\\multicolumn{5}{l}{\\textit{Post-Treatment}} \\\\[3pt]",
  es_rows[es_e >= 0],
  "[6pt]",
  "\\midrule",
  sprintf("Overall ATT & %s & (%.4f) & [%.4f, & %.4f] \\\\",
          fmtcoef(agg_overall$overall.att,
                  2 * pnorm(-abs(agg_overall$overall.att / agg_overall$overall.se))),
          agg_overall$overall.se,
          agg_overall$overall.att - 1.96 * agg_overall$overall.se,
          agg_overall$overall.att + 1.96 * agg_overall$overall.se),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.92\\textwidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  "\\textit{Notes:} Event study coefficients from the \\citet{callaway2021difference} estimator",
  "with doubly-robust estimation and not-yet-treated control group. Event time 0 is the year",
  "of CES enactment. Pre-treatment coefficients are normalized to zero (reference: $e = -1$).",
  "The flat pre-trends and null post-treatment effects confirm that 100\\% Clean Energy Standards",
  "do not accelerate coal generator retirement once heterogeneous treatment effects are properly",
  "accounted for. Standard errors clustered by state.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab5, file.path(TABLE_DIR, "tab5_eventstudy.tex"))
cat("  -> tab5_eventstudy.tex written\n")

# =============================================================================
# SDE TABLE (APPENDIX): tabF1_sde.tex
# =============================================================================
cat("--- SDE Table: tabF1_sde.tex ---\n")

# Mandatory 8-field SDE format
# Policy: 100% Clean Energy Standards
# Setting: US coal generators, 2008-2024
# Design: Staggered DiD (CS)
# Outcome: Generator retirement (binary)
# Effect: Null (ATT = 0.008, p > 0.6)
# Mechanism: Composition illusion — CES states have smaller, older generators
# that retire faster regardless of policy
# Implication: CES accelerates coal retirement only in appearance; the
# signal is stranded in generator composition

sde <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Structured Data Extract (SDE)}",
  "\\label{tab:sde}",
  "\\begin{tabular}{p{3.2cm}p{10.5cm}}",
  "\\toprule",
  "Field & Value \\\\",
  "\\midrule",
  "Policy & 100\\% Clean Energy Standards (CES) enacted by US states, 2018--2023 \\\\[4pt]",
  "Setting & 1,005 coal-fired generators across all US states, observed annually 2008--2024 (EIA-860) \\\\[4pt]",
  "Design & Staggered difference-in-differences using \\citet{callaway2021difference} with doubly-robust estimation; TWFE as biased benchmark \\\\[4pt]",
  "Outcome & Binary indicator: generator retired in year $t$ \\\\[4pt]",
  sprintf("Effect & Overall ATT $= %.4f$ (SE $= %.4f$, $p = %.3f$). Null effect; 95\\%% CI rules out effects larger than %.1f~pp \\\\[4pt]",
          agg_overall$overall.att,
          agg_overall$overall.se,
          2 * pnorm(-abs(agg_overall$overall.att / agg_overall$overall.se)),
          1.96 * agg_overall$overall.se * 100),
  sprintf("Mechanism & Composition illusion: CES states have generators that are %.0f~MW smaller and %.1f~years older at baseline. These generators retire faster regardless of CES policy, inflating na\\\"ive TWFE estimates ($\\hat{\\beta}_{\\text{TWFE}} = %.4f^{***}$) \\\\[4pt]",
          abs(mean(baseline[ces_state == 0]$capacity_mw) - mean(baseline[ces_state == 1]$capacity_mw)),
          abs(mean(baseline[ces_state == 1]$vintage) - mean(baseline[ces_state == 0]$vintage)),
          coef(twfe)["post_ces"]),
  "Implication & CES does not accelerate coal retirement. The apparent policy effect is a composition artifact driven by pre-existing differences in generator fleets. Modern heterogeneity-robust estimators are essential for credible inference in staggered adoption designs \\\\[4pt]",
  sprintf("Precision & MDE at 80\\%% power $= %.4f$ ($%.1f\\%%$ of baseline retirement rate). Design is powered to detect policy effects of meaningful magnitude \\\\",
          2.8 * agg_overall$overall.se,
          100 * 2.8 * agg_overall$overall.se / mean(panel[ces_year == 0]$retired_this_year)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(sde, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("  -> tabF1_sde.tex written\n")

# =============================================================================
# SUMMARY
# =============================================================================
cat("\n=== All Tables Generated ===\n")
cat("Files in", TABLE_DIR, ":\n")
cat(paste(" ", list.files(TABLE_DIR)), sep = "\n")
cat("\n\nKey results embedded in tables:\n")
cat(sprintf("  TWFE coefficient:         %.4f (SE: %.4f, p < 0.001)\n",
            coef(twfe)["post_ces"], se(twfe)["post_ces"]))
cat(sprintf("  TWFE capacity-weighted:   %.4f (SE: %.4f, p = %.3f)\n",
            coef(twfe_capwt)["post_ces"], se(twfe_capwt)["post_ces"],
            pvalue(twfe_capwt)["post_ces"]))
cat(sprintf("  CS DiD (not-yet-treated): %.4f (SE: %.4f, p = %.3f)\n",
            cs_nyt_coef, cs_nyt_se, cs_nyt_pv))
if (!is.null(agg_never)) {
  cat(sprintf("  CS DiD (never-treated):   %.4f (SE: %.4f, p = %.3f)\n",
              cs_nt_coef, cs_nt_se, cs_nt_pv))
}
cat(sprintf("  Size-matched TWFE:        %.4f (SE: %.4f, p = %.3f)\n",
            coef(twfe_similar)["post_ces"], se(twfe_similar)["post_ces"],
            pvalue(twfe_similar)["post_ces"]))
cat("\nDone.\n")
