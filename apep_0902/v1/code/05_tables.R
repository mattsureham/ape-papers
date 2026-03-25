# ============================================================================
# 05_tables.R — Generate all tables for RTF paper (V1: no figures)
# ============================================================================

source("00_packages.R")

panel_112 <- readRDS("../data/panel_112.rds")
panel_111 <- readRDS("../data/panel_111.rds")
treatment_dates <- readRDS("../data/treatment_dates.rds")
qwi_rh <- readRDS("../data/qwi_rh_clean.rds")
cs_agg <- readRDS("../data/cs_agg.rds")
cs_dynamic <- readRDS("../data/cs_dynamic.rds")
cs_group <- readRDS("../data/cs_group.rds")
twfe_main <- readRDS("../data/twfe_main.rds")
sa_main <- readRDS("../data/sa_main.rds")
twfe_outcomes <- readRDS("../data/twfe_outcomes.rds")
robustness <- readRDS("../data/robustness_results.rds")
diagnostics <- jsonlite::fromJSON("../data/diagnostics.json")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ============================================================================
# Helper: star function
# ============================================================================
stars <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
}

fmt <- function(x, d = 3) formatC(x, digits = d, format = "f")
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment SD for treated states (for SDE)
pre_treat_112 <- panel_112 %>%
  filter(treated_state, yq < treat_yq)

sd_y_pre <- sd(pre_treat_112$log_emp, na.rm = TRUE)

# Summary by treatment group
sum_treated <- panel_112 %>%
  filter(treated_state) %>%
  summarize(
    across(c(Emp, HirN, Sep, FrmJbGn, FrmJbLs, EarnS),
      list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)),
      .names = "{.col}_{.fn}"
    ),
    N = n(),
    n_counties = n_distinct(county_fips)
  )

sum_control <- panel_112 %>%
  filter(!treated_state) %>%
  summarize(
    across(c(Emp, HirN, Sep, FrmJbGn, FrmJbLs, EarnS),
      list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)),
      .names = "{.col}_{.fn}"
    ),
    N = n(),
    n_counties = n_distinct(county_fips)
  )

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Animal Production (NAICS 112), 2005--2024}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{RTF States} & \\multicolumn{2}{c}{Control States} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  sprintf("Employment & %s & %s & %s & %s \\\\",
    fmt(sum_treated$Emp_mean, 1), fmt(sum_treated$Emp_sd, 1),
    fmt(sum_control$Emp_mean, 1), fmt(sum_control$Emp_sd, 1)),
  sprintf("New hires & %s & %s & %s & %s \\\\",
    fmt(sum_treated$HirN_mean, 1), fmt(sum_treated$HirN_sd, 1),
    fmt(sum_control$HirN_mean, 1), fmt(sum_control$HirN_sd, 1)),
  sprintf("Separations & %s & %s & %s & %s \\\\",
    fmt(sum_treated$Sep_mean, 1), fmt(sum_treated$Sep_sd, 1),
    fmt(sum_control$Sep_mean, 1), fmt(sum_control$Sep_sd, 1)),
  sprintf("Job creation & %s & %s & %s & %s \\\\",
    fmt(sum_treated$FrmJbGn_mean, 1), fmt(sum_treated$FrmJbGn_sd, 1),
    fmt(sum_control$FrmJbGn_mean, 1), fmt(sum_control$FrmJbGn_sd, 1)),
  sprintf("Job destruction & %s & %s & %s & %s \\\\",
    fmt(sum_treated$FrmJbLs_mean, 1), fmt(sum_treated$FrmJbLs_sd, 1),
    fmt(sum_control$FrmJbLs_mean, 1), fmt(sum_control$FrmJbLs_sd, 1)),
  sprintf("Avg monthly earnings (\\$) & %s & %s & %s & %s \\\\",
    fmt(sum_treated$EarnS_mean, 0), fmt(sum_treated$EarnS_sd, 0),
    fmt(sum_control$EarnS_mean, 0), fmt(sum_control$EarnS_sd, 0)),
  "\\midrule",
  sprintf("County-quarters & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
    fmt_int(sum_treated$N), fmt_int(sum_control$N)),
  sprintf("Counties & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
    fmt_int(sum_treated$n_counties), fmt_int(sum_control$n_counties)),
  "States & \\multicolumn{2}{c}{6} & \\multicolumn{2}{c}{8} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Data from the Quarterly Workforce Indicators (QWI), county-quarter level. RTF states: ND (2012), NC (2013), MO (2014), IA (2018), GA (2019), TX (2021). Control states: KS, NE, WI, TN, VA, SD, KY, MT. Sample restricted to county-quarters with non-suppressed NAICS 112 employment. N = %s county-quarter observations.",
    fmt_int(sum_treated$N + sum_control$N)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results — CS, TWFE, Sun-Abraham
# ============================================================================

cat("Generating Table 2: Main Results...\n")

# Extract CS results
cs_beta <- cs_agg$overall.att
cs_se <- cs_agg$overall.se

# Extract TWFE results
twfe_beta <- coef(twfe_main)["treat_indicator"]
twfe_se <- se(twfe_main)["treat_indicator"]
twfe_pval <- pvalue(twfe_main)["treat_indicator"]

# Extract SA results — aggregate ATT from POST-TREATMENT coefficients only
sa_coefs <- coef(sa_main)
sa_ses <- se(sa_main)
sa_pvals <- pvalue(sa_main)
# sunab() names coefficients as "time_id::N" where N is event time
# Post-treatment = event time >= 0
sa_event_times <- as.integer(gsub(".*::", "", names(sa_coefs)))
sa_post_idx <- which(sa_event_times >= 0)
if (length(sa_post_idx) > 0) {
  sa_beta <- mean(sa_coefs[sa_post_idx])
  sa_se <- sqrt(mean(sa_ses[sa_post_idx]^2))
  cat(sprintf("SA aggregate ATT (post-treatment mean): %.4f (SE: %.4f)\n", sa_beta, sa_se))
  cat(sprintf("  Based on %d post-treatment event-time coefficients\n", length(sa_post_idx)))
} else {
  sa_beta <- sa_coefs[1]
  sa_se <- sa_ses[1]
  cat("WARNING: No post-treatment SA coefficients found; using first coefficient.\n")
}

# N observations
n_obs <- nobs(twfe_main)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of RTF Constitutional Amendments on Animal Production Employment}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & CS (2021) & TWFE & Sun-Abraham \\\\",
  "\\midrule",
  sprintf("RTF Amendment & %s%s & %s%s & %s%s \\\\",
    fmt(cs_beta, 4), stars(2 * pnorm(-abs(cs_beta / cs_se))),
    fmt(twfe_beta, 4), stars(twfe_pval),
    fmt(sa_beta, 4), stars(2 * pnorm(-abs(sa_beta / sa_se)))),
  sprintf(" & (%s) & (%s) & (%s) \\\\",
    fmt(cs_se, 4), fmt(twfe_se, 4), fmt(sa_se, 4)),
  sprintf(" & [%s] & & \\\\",
    fmt(2 * pnorm(-abs(cs_beta / cs_se)), 4)),
  "\\\\",
  sprintf("County-quarter obs. & %s & %s & %s \\\\",
    fmt_int(n_obs), fmt_int(n_obs), fmt_int(n_obs)),
  sprintf("Counties & %s & %s & %s \\\\",
    fmt_int(diagnostics$n_counties), fmt_int(diagnostics$n_counties), fmt_int(diagnostics$n_counties)),
  "Clusters (states) & 14 & 14 & 14 \\\\",
  "County FE & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes \\\\",
  "Control group & Not-yet-treated & All untreated & Not-yet-treated \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log county-quarter employment in NAICS 112 (Animal Production and Aquaculture). Column (1) reports the aggregate ATT from the Callaway and Sant'Anna (2021) estimator with not-yet-treated control group. Column (2) reports a standard two-way fixed effects estimate. Column (3) reports the Sun and Abraham (2021) interaction-weighted estimator. Standard errors clustered at the state level in parentheses. $p$-values in brackets (column 1). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ============================================================================
# Table 3: Multiple Outcomes
# ============================================================================

cat("Generating Table 3: Multiple Outcomes...\n")

outcome_names <- c("Employment", "New Hires", "Separations", "Job Creation", "Job Destruction", "Earnings")
outcome_fits <- list(twfe_main, twfe_outcomes$hires, twfe_outcomes$sep,
                     twfe_outcomes$jbgn, twfe_outcomes$jbls, twfe_outcomes$earn)

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of RTF Amendments on Multiple Labor Market Outcomes}",
  "\\label{tab:outcomes}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  paste0(" & ", paste(outcome_names, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Coefficient row
coef_row <- "RTF Amendment"
se_row <- ""
n_row <- "N"

for (fit in outcome_fits) {
  b <- coef(fit)["treat_indicator"]
  s <- se(fit)["treat_indicator"]
  p <- pvalue(fit)["treat_indicator"]
  n <- nobs(fit)
  coef_row <- paste0(coef_row, sprintf(" & %s%s", fmt(b, 4), stars(p)))
  se_row <- paste0(se_row, sprintf(" & (%s)", fmt(s, 4)))
  n_row <- paste0(n_row, sprintf(" & %s", fmt_int(n)))
}

tab3_lines <- c(tab3_lines,
  paste0(coef_row, " \\\\"),
  paste0(se_row, " \\\\"),
  "\\\\",
  paste0(n_row, " \\\\"),
  "County FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the TWFE estimate of RTF constitutional amendment effects on the log of the indicated QWI outcome variable at the county-quarter level for NAICS 112 (Animal Production). Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_outcomes.tex"))

# ============================================================================
# Table 4: Robustness — Placebo, Wild Bootstrap, Leave-One-Out
# ============================================================================

cat("Generating Table 4: Robustness...\n")

# Wild cluster bootstrap
boot_ci <- robustness$boot$conf_int
boot_p <- robustness$boot$p_val

# Leave-one-out summary
loo_df <- data.frame(
  dropped = names(robustness$loo),
  coef = sapply(robustness$loo, function(x) x$coef),
  se = sapply(robustness$loo, function(x) x$se),
  pval = sapply(robustness$loo, function(x) x$pval)
)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Estimate & SE & $p$-value & 95\\% CI \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Main and Placebo}} \\\\",
  sprintf("NAICS 112 (Animal Production) & %s%s & %s & %s & \\\\",
    fmt(twfe_beta, 4), stars(twfe_pval), fmt(twfe_se, 4), fmt(twfe_pval, 4)),
  sprintf("NAICS 111 (Crop Production, placebo) & %s%s & %s & %s & \\\\",
    fmt(coef(robustness$placebo_twfe)["treat_indicator"], 4),
    stars(pvalue(robustness$placebo_twfe)["treat_indicator"]),
    fmt(se(robustness$placebo_twfe)["treat_indicator"], 4),
    fmt(pvalue(robustness$placebo_twfe)["treat_indicator"], 4)),
  "\\\\",
  "\\multicolumn{5}{l}{\\textit{Panel B: Wild Cluster Bootstrap}} \\\\",
  sprintf("Bootstrap (Rademacher, 9,999 reps) & %s & & %s & [%s, %s] \\\\",
    fmt(twfe_beta, 4), fmt(boot_p, 4),
    fmt(boot_ci[1], 4), fmt(boot_ci[2], 4)),
  "\\\\",
  "\\multicolumn{5}{l}{\\textit{Panel C: Leave-One-Out (drop each treated state)}} \\\\"
)

for (i in seq_len(nrow(loo_df))) {
  tab4_lines <- c(tab4_lines,
    sprintf("Drop %s & %s%s & %s & %s & \\\\",
      loo_df$dropped[i],
      fmt(loo_df$coef[i], 4), stars(loo_df$pval[i]),
      fmt(loo_df$se[i], 4), fmt(loo_df$pval[i], 4))
  )
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A compares the main TWFE estimate on NAICS 112 (Animal Production) with a placebo test using NAICS 111 (Crop Production), which should not be affected by RTF amendments that specifically shield animal operations. Panel B reports wild cluster bootstrap inference (Rademacher weights, 9,999 replications) to address the small number of clusters (14 states). Panel C drops each treated state in turn to verify no single state drives the result. All specifications include county and quarter fixed effects. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robust.tex"))

# ============================================================================
# Table 5: Event Study Coefficients
# ============================================================================

cat("Generating Table 5: Event Study...\n")

es_df <- data.frame(
  event_time = cs_dynamic$egt,
  att = cs_dynamic$att.egt,
  se = cs_dynamic$se.egt
)
es_df$pval <- 2 * pnorm(-abs(es_df$att / es_df$se))
es_df$ci_lo <- es_df$att - 1.96 * es_df$se
es_df$ci_hi <- es_df$att + 1.96 * es_df$se

# Show select event times (not all — keep table compact)
# Pre: -12, -8, -4, -1. Post: 0, 4, 8, 12, 16
select_times <- c(-12, -8, -4, -1, 0, 4, 8, 12, 16)
es_show <- es_df %>% filter(event_time %in% select_times)

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Dynamic Treatment Effects: Event Study (Callaway--Sant'Anna)}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Quarters relative & ATT & SE & $p$-value & \\multicolumn{2}{c}{95\\% CI} \\\\",
  "to RTF amendment & & & & Lower & Upper \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_show))) {
  label <- ifelse(es_show$event_time[i] < 0,
    sprintf("$t%d$", es_show$event_time[i]),
    sprintf("$t+%d$", es_show$event_time[i]))
  tab5_lines <- c(tab5_lines,
    sprintf("%s & %s%s & %s & %s & %s & %s \\\\",
      label,
      fmt(es_show$att[i], 4), stars(es_show$pval[i]),
      fmt(es_show$se[i], 4),
      fmt(es_show$pval[i], 4),
      fmt(es_show$ci_lo[i], 4),
      fmt(es_show$ci_hi[i], 4))
  )
}

tab5_lines <- c(tab5_lines,
  "\\midrule",
  sprintf("Pre-trend joint test ($p$) & \\multicolumn{5}{c}{%s} \\\\",
    fmt(cs_dynamic$Wpval, 4)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dynamic treatment effects from the Callaway and Sant'Anna (2021) estimator with not-yet-treated control group. Each row shows the average treatment effect at the indicated quarters relative to RTF amendment adoption. Selected event times shown for parsimony. Pre-trend joint test is the Wald test of all pre-treatment coefficients equaling zero. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_eventstudy.tex"))

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ============================================================================

cat("Generating SDE Table (tabF1_sde.tex)...\n")

# Pre-treatment SD of log employment for treated counties
sd_y <- sd_y_pre
cat(sprintf("Pre-treatment SD(log_emp) = %.4f\n", sd_y))

# --- Panel A: Pooled ---
main_beta <- coef(twfe_main)["treat_indicator"]
main_se <- se(twfe_main)["treat_indicator"]
sde_main <- main_beta / sd_y
se_sde_main <- main_se / sd_y

# Hires
hires_beta <- coef(twfe_outcomes$hires)["treat_indicator"]
hires_se <- se(twfe_outcomes$hires)["treat_indicator"]
sd_y_hires <- sd(log(panel_112$HirN[panel_112$treated_state & panel_112$yq < panel_112$treat_yq & panel_112$HirN > 0]), na.rm = TRUE)
sde_hires <- hires_beta / sd_y_hires
se_sde_hires <- hires_se / sd_y_hires

# Earnings
earn_beta <- coef(twfe_outcomes$earn)["treat_indicator"]
earn_se <- se(twfe_outcomes$earn)["treat_indicator"]
sd_y_earn <- sd(panel_112$log_earn[panel_112$treated_state & panel_112$yq < panel_112$treat_yq], na.rm = TRUE)
sde_earn <- earn_beta / sd_y_earn
se_sde_earn <- earn_se / sd_y_earn

# --- Panel B: Heterogeneous (Hispanic vs Non-Hispanic) ---
if (!is.null(robustness$hisp) && !is.null(robustness$nonhisp)) {
  hisp_beta <- coef(robustness$hisp)["treat_indicator"]
  hisp_se <- se(robustness$hisp)["treat_indicator"]
  # Approximate SD from the Hispanic subsample
  hisp_data <- qwi_rh %>% filter(ethnicity == "A2", !is.na(Emp), Emp > 0, treated_state, yq < treat_yq)
  sd_y_hisp <- sd(log(hisp_data$Emp), na.rm = TRUE)
  sde_hisp <- hisp_beta / sd_y_hisp
  se_sde_hisp <- hisp_se / sd_y_hisp

  nonhisp_beta <- coef(robustness$nonhisp)["treat_indicator"]
  nonhisp_se <- se(robustness$nonhisp)["treat_indicator"]
  nonhisp_data <- qwi_rh %>% filter(ethnicity == "A1", !is.na(Emp), Emp > 0, treated_state, yq < treat_yq)
  sd_y_nonhisp <- sd(log(nonhisp_data$Emp), na.rm = TRUE)
  sde_nonhisp <- nonhisp_beta / sd_y_nonhisp
  se_sde_nonhisp <- nonhisp_se / sd_y_nonhisp
} else {
  # Fallback: use crop production placebo as Panel B row
  placebo_beta <- coef(robustness$placebo_twfe)["treat_indicator"]
  placebo_se <- se(robustness$placebo_twfe)["treat_indicator"]
  sd_y_placebo <- sd(panel_111$log_emp[panel_111$treated_state & panel_111$yq < panel_111$treat_yq], na.rm = TRUE)
  sde_placebo <- placebo_beta / sd_y_placebo
  se_sde_placebo <- placebo_se / sd_y_placebo
}

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

# --- Build SDE notes ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level constitutional Right-to-Farm amendments, which immunize concentrated animal feeding operations from nuisance litigation and local zoning, increase county-level animal production employment? ",
  "\\textbf{Policy mechanism:} Constitutional RTF amendments create a legal shield that eliminates or severely restricts the ability of neighbors, local governments, and environmental groups to sue large-scale animal operations for nuisance, odor, water contamination, or zoning violations---effectively removing a major regulatory cost and litigation risk for facility operators. ",
  "\\textbf{Outcome definition:} Quarterly county-level beginning-of-quarter employment count in NAICS 112 (Animal Production and Aquaculture) from the Census Bureau's Quarterly Workforce Indicators, measured in logs. ",
  "\\textbf{Treatment:} Binary indicator for state adoption of a constitutional RTF amendment or major legislative RTF strengthening, with staggered timing across six states between 2012 and 2021. ",
  "\\textbf{Data:} QWI county-quarter panel, 2005Q1--2024Q4, covering 14 states (6 treated, 8 agricultural controls). ",
  "\\textbf{Method:} Staggered difference-in-differences with TWFE estimator, county and quarter fixed effects, standard errors clustered at the state level (14 clusters), supplemented by wild cluster bootstrap for finite-sample inference. ",
  "\\textbf{Sample:} County-quarters with non-suppressed NAICS 112 employment in 6 RTF-strengthening states (ND, NC, MO, IA, GA, TX) and 8 agricultural control states (KS, NE, WI, TN, VA, SD, KY, MT) without RTF changes during the sample period. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation of log employment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# --- Assemble table ---
sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Employment (log) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(main_beta, 4), fmt(main_se, 4), fmt(sd_y, 4),
    fmt(sde_main, 4), fmt(se_sde_main, 4), classify(sde_main)),
  sprintf("New hires (log) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(hires_beta, 4), fmt(hires_se, 4), fmt(sd_y_hires, 4),
    fmt(sde_hires, 4), fmt(se_sde_hires, 4), classify(sde_hires)),
  sprintf("Earnings (log) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(earn_beta, 4), fmt(earn_se, 4), fmt(sd_y_earn, 4),
    fmt(sde_earn, 4), fmt(se_sde_earn, 4), classify(sde_earn)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by worker ethnicity)}} \\\\"
)

if (!is.null(robustness$hisp) && !is.null(robustness$nonhisp)) {
  sde_lines <- c(sde_lines,
    sprintf("Employment, Hispanic & %s & %s & %s & %s & %s & %s \\\\",
      fmt(hisp_beta, 4), fmt(hisp_se, 4), fmt(sd_y_hisp, 4),
      fmt(sde_hisp, 4), fmt(se_sde_hisp, 4), classify(sde_hisp)),
    sprintf("Employment, Non-Hispanic & %s & %s & %s & %s & %s & %s \\\\",
      fmt(nonhisp_beta, 4), fmt(nonhisp_se, 4), fmt(sd_y_nonhisp, 4),
      fmt(sde_nonhisp, 4), fmt(se_sde_nonhisp, 4), classify(sde_nonhisp))
  )
} else {
  sde_lines <- c(sde_lines,
    sprintf("Crop Production placebo & %s & %s & %s & %s & %s & %s \\\\",
      fmt(placebo_beta, 4), fmt(placebo_se, 4), fmt(sd_y_placebo, 4),
      fmt(sde_placebo, 4), fmt(se_sde_placebo, 4), classify(sde_placebo))
  )
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in tables/\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_outcomes.tex\n")
cat("  tab4_robust.tex\n")
cat("  tab5_eventstudy.tex\n")
cat("  tabF1_sde.tex\n")
