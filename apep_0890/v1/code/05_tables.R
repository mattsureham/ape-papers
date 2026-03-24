# 05_tables.R — Generate all tables
# apep_0890: Craigslist Entry and Local Journalism Employment

source("00_packages.R")
setwd(file.path(getwd(), "..", "data"))

results <- readRDS("results_main.rds")
robustness <- readRDS("results_robustness.rds")
params <- readRDS("params.rds")
pre_stats <- readRDS("pre_stats.rds")
panel <- readRDS("panel_clean.rds")

tables_dir <- file.path("..", "tables")
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("=== Table 1: Summary Statistics ===\n")

panel_annual <- panel %>%
  group_by(fips, year, state_fips, g, treated_ever) %>%
  summarise(
    emp = mean(emp, na.rm = TRUE),
    ln_emp = mean(ln_emp, na.rm = TRUE),
    hir_n = mean(hir_n, na.rm = TRUE),
    sep = mean(sep, na.rm = TRUE),
    earn_s = mean(earn_s, na.rm = TRUE),
    .groups = "drop"
  )

# Pre-treatment summary by treatment status
pre_panel <- panel_annual %>% filter(year < 2001 | (g > 0 & year < g) | (g == 0))

make_sumstat <- function(df, label) {
  df %>%
    summarise(
      Group = label,
      `Mean Emp` = sprintf("%.1f", mean(emp, na.rm = TRUE)),
      `SD Emp` = sprintf("%.1f", sd(emp, na.rm = TRUE)),
      `Mean Log Emp` = sprintf("%.3f", mean(ln_emp, na.rm = TRUE)),
      `Mean Hires` = sprintf("%.1f", mean(hir_n, na.rm = TRUE)),
      `Mean Separations` = sprintf("%.1f", mean(sep, na.rm = TRUE)),
      `Mean Earnings ($)` = sprintf("%.0f", mean(earn_s, na.rm = TRUE)),
      `Counties` = as.character(n_distinct(fips)),
      `Obs` = as.character(n())
    )
}

# Full sample, treated, never-treated
tab1 <- bind_rows(
  make_sumstat(panel_annual, "Full sample"),
  make_sumstat(panel_annual %>% filter(treated_ever), "Treated (MSA w/ Craigslist)"),
  make_sumstat(panel_annual %>% filter(!treated_ever), "Never-treated (non-MSA)")
)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Publishing Industry Employment by County}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccccc}\n",
  "\\toprule\n",
  " & Mean & SD & Mean Log & Mean & Mean & Mean & & \\\\\n",
  " & Emp & Emp & Emp & Hires & Sep & Earnings & Counties & Obs \\\\\n",
  "\\midrule\n",
  paste(apply(tab1, 1, function(row) {
    paste(row, collapse = " & ")
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} County-year observations from QWI NAICS 3-digit publishing industry, 2001--2015. Employment, hires, and separations are quarterly averages within each county-year. Earnings are average monthly earnings of stable workers. Treated counties are those in MSAs where Craigslist entered between 2000 and 2006. Never-treated counties are non-MSA counties or MSA counties without a Craigslist entry date.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(tables_dir, "tab1_sumstats.tex"))

# =============================================================================
# Table 2: Main Results — CS-DiD ATT
# =============================================================================
cat("=== Table 2: Main Results ===\n")

cs <- results$cs_agg
cs_hires <- results$cs_hires_agg
cs_sep <- results$cs_sep_agg
cs_earn <- results$cs_earn_agg
twfe <- results$twfe

# Stars function
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Format coefficient
fmt_coef <- function(est, se, p) {
  s <- stars(p)
  sprintf("%.4f%s", est, s)
}

# Build table rows
tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Craigslist Entry on Publishing Industry Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Log Emp & Log Hires & Log Sep & Log Earnings \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway-Sant'Anna ATT}} \\\\\n",
  sprintf("Craigslist Entry & %s & %s & %s & %s \\\\\n",
    fmt_coef(cs$overall.att, cs$overall.se, 2*pnorm(-abs(cs$overall.att / cs$overall.se))),
    fmt_coef(cs_hires$overall.att, cs_hires$overall.se, 2*pnorm(-abs(cs_hires$overall.att / cs_hires$overall.se))),
    fmt_coef(cs_sep$overall.att, cs_sep$overall.se, 2*pnorm(-abs(cs_sep$overall.att / cs_sep$overall.se))),
    fmt_coef(cs_earn$overall.att, cs_earn$overall.se, 2*pnorm(-abs(cs_earn$overall.att / cs_earn$overall.se)))),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
    cs$overall.se, cs_hires$overall.se, cs_sep$overall.se, cs_earn$overall.se),
  " & & & & \\\\\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: TWFE (for comparison)}} \\\\\n",
  sprintf("Post $\\times$ Treated & %s & & & \\\\\n",
    fmt_coef(coef(twfe)["post"], se(twfe)["post"], pvalue(twfe)["post"])),
  sprintf(" & (%.4f) & & & \\\\\n", se(twfe)["post"]),
  "\\midrule\n",
  sprintf("Counties & %s & %s & %s & %s \\\\\n",
    format(params$n_counties, big.mark = ","),
    format(params$n_counties, big.mark = ","),
    format(params$n_counties, big.mark = ","),
    format(params$n_counties, big.mark = ",")),
  sprintf("Treated & %s & %s & %s & %s \\\\\n",
    format(params$n_treated, big.mark = ","),
    format(params$n_treated, big.mark = ","),
    format(params$n_treated, big.mark = ","),
    format(params$n_treated, big.mark = ",")),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
    format(nrow(panel_annual), big.mark = ","),
    format(nrow(panel_annual), big.mark = ","),
    format(nrow(panel_annual), big.mark = ","),
    format(nrow(panel_annual), big.mark = ",")),
  "Clustering & State & State & State & State \\\\\n",
  "Control group & Not-yet-treated & Not-yet-treated & Not-yet-treated & Not-yet-treated \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATT estimates aggregated to an overall ATT. Treatment is the entry of Craigslist into the county's MSA. All outcomes are in logs. Panel B reports the TWFE DiD coefficient for comparison; this estimator is biased under heterogeneous treatment effects with staggered adoption. Standard errors (in parentheses) are clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))

# =============================================================================
# Table 3: Robustness
# =============================================================================
cat("=== Table 3: Robustness ===\n")

sa_coef <- robustness$sa_coefs$coef
sa_se <- robustness$sa_coefs$se
sa_p <- robustness$sa_coefs$pval

cs_never <- robustness$cs_never_agg

# Placebo
if (!is.null(robustness$cs_placebo_agg)) {
  plac_att <- robustness$cs_placebo_agg$overall.att
  plac_se <- robustness$cs_placebo_agg$overall.se
  plac_p <- 2*pnorm(-abs(plac_att / plac_se))
} else {
  plac_att <- NA; plac_se <- NA; plac_p <- NA
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Effect on Log Publishing Employment}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & ATT & SE \\\\\n",
  "\\midrule\n",
  sprintf("\\textit{Main:} CS-DiD, not-yet-treated & %s & (%.4f) \\\\\n",
    fmt_coef(cs$overall.att, cs$overall.se, 2*pnorm(-abs(cs$overall.att/cs$overall.se))),
    cs$overall.se),
  sprintf("Sun-Abraham & %s & (%.4f) \\\\\n",
    fmt_coef(sa_coef, sa_se, sa_p), sa_se),
  sprintf("CS-DiD, never-treated control & %s & (%.4f) \\\\\n",
    fmt_coef(cs_never$overall.att, cs_never$overall.se,
             2*pnorm(-abs(cs_never$overall.att/cs_never$overall.se))),
    cs_never$overall.se),
  ifelse(!is.na(plac_att),
    sprintf("\\textit{Placebo:} Utilities (NAICS 221) & %s & (%.4f) \\\\\n",
      fmt_coef(plac_att, plac_se, plac_p), plac_se),
    "\\textit{Placebo:} Utilities (NAICS 221) & --- & --- \\\\\n"),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Leave-one-cohort-out:}} \\\\\n",
  paste(apply(robustness$loco_df, 1, function(row) {
    sprintf("\\quad Drop %s cohort & %s & (%.4f)",
      row["dropped_cohort"],
      fmt_coef(as.numeric(row["att"]), as.numeric(row["se"]),
               2*pnorm(-abs(as.numeric(row["att"])/as.numeric(row["se"])))),
      as.numeric(row["se"]))
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the overall ATT from a different specification. The main specification uses Callaway and Sant'Anna (2021) with not-yet-treated counties as the control group. Sun-Abraham uses the interaction-weighted estimator via \\texttt{fixest::sunab()}. The placebo test applies the same design to Utilities (NAICS 221), an industry unaffected by classified advertising disruption. Leave-one-cohort-out drops each entry-year cohort in turn. Standard errors clustered at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(tables_dir, "tab3_robustness.tex"))

# =============================================================================
# Table 4: Event Study Coefficients
# =============================================================================
cat("=== Table 4: Event Study ===\n")

es <- results$cs_dynamic
es_df <- data.frame(
  e = es$egt,
  att = es$att.egt,
  se = es$se.egt,
  ci_lo = es$att.egt - 1.96 * es$se.egt,
  ci_hi = es$att.egt + 1.96 * es$se.egt
)
es_df$p <- 2 * pnorm(-abs(es_df$att / es_df$se))

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Log Publishing Employment Relative to Craigslist Entry}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{rcccc}\n",
  "\\toprule\n",
  "Event Time & ATT & SE & 95\\% CI & \\\\\n",
  "\\midrule\n",
  paste(apply(es_df, 1, function(row) {
    e <- as.numeric(row["e"])
    att <- as.numeric(row["att"])
    se <- as.numeric(row["se"])
    p <- as.numeric(row["p"])
    sprintf("%+d & %s & (%.4f) & [%.4f, %.4f]",
      e, fmt_coef(att, se, p), se,
      as.numeric(row["ci_lo"]), as.numeric(row["ci_hi"]))
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATTs aggregated to event time. Event time 0 is the year of Craigslist entry into the county's MSA. Pre-treatment coefficients (negative event times) test the parallel trends assumption. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(tables_dir, "tab4_eventstudy.tex"))

# =============================================================================
# Table F1: SDE Appendix (MANDATORY)
# =============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

sd_y <- pre_stats$sd_ln_emp

# Panel A: Pooled estimates
sde_rows_a <- data.frame(
  Outcome = c("Log Employment", "Log New Hires", "Log Separations", "Log Earnings"),
  beta = c(cs$overall.att, cs_hires$overall.att, cs_sep$overall.att, cs_earn$overall.att),
  se_beta = c(cs$overall.se, cs_hires$overall.se, cs_sep$overall.se, cs_earn$overall.se),
  sd_y = sd_y
)

sde_rows_a$sde <- sde_rows_a$beta / sde_rows_a$sd_y
sde_rows_a$se_sde <- sde_rows_a$se_beta / sde_rows_a$sd_y
sde_rows_a$class <- cut(sde_rows_a$sde,
  breaks = c(-Inf, -0.15, -0.05, -0.005, 0.005, 0.05, 0.15, Inf),
  labels = c("Large neg.", "Moderate neg.", "Small neg.", "Null",
             "Small pos.", "Moderate pos.", "Large pos."))

# Panel B: Heterogeneous (early vs late cohorts)
panel_annual_het <- panel %>%
  group_by(fips, year, state_fips, g, treated_ever) %>%
  summarise(
    ln_emp = mean(log(emp + 1), na.rm = TRUE),
    .groups = "drop"
  )

# Early cohort: entered 2000-2002; Late cohort: entered 2003+
early_panel <- panel_annual_het %>% filter(g <= 2002 | g == 0)
late_panel <- panel_annual_het %>% filter(g >= 2003 | g == 0)

cs_early <- tryCatch({
  cs_e <- att_gt(yname = "ln_emp", tname = "year", idname = "fips",
                 gname = "g", data = early_panel,
                 control_group = "notyettreated", clustervars = "state_fips",
                 base_period = "universal")
  aggte(cs_e, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))

cs_late <- tryCatch({
  cs_l <- att_gt(yname = "ln_emp", tname = "year", idname = "fips",
                 gname = "g", data = late_panel,
                 control_group = "notyettreated", clustervars = "state_fips",
                 base_period = "universal")
  aggte(cs_l, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))

sde_rows_b <- data.frame(
  Outcome = c("Log Employment (Early cohort: 2000--2002)",
              "Log Employment (Late cohort: 2003+)"),
  beta = c(cs_early$overall.att, cs_late$overall.att),
  se_beta = c(cs_early$overall.se, cs_late$overall.se),
  sd_y = sd_y
)
sde_rows_b$sde <- sde_rows_b$beta / sde_rows_b$sd_y
sde_rows_b$se_sde <- sde_rows_b$se_beta / sde_rows_b$sd_y
sde_rows_b$class <- cut(sde_rows_b$sde,
  breaks = c(-Inf, -0.15, -0.05, -0.005, 0.005, 0.05, 0.15, Inf),
  labels = c("Large neg.", "Moderate neg.", "Small neg.", "Null",
             "Small pos.", "Moderate pos.", "Large pos."))

# Build SDE table
fmt_sde_row <- function(row) {
  sprintf("%s & %.4f & (%.4f) & %.3f & %.3f & (%.3f) & %s",
    row$Outcome, row$beta, row$se_beta, row$sd_y,
    row$sde, row$se_sde, as.character(row$class))
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the entry of Craigslist into metropolitan areas cause declines in local publishing industry employment, and does the effect operate through reduced hiring or increased separations? ",
  "\\textbf{Policy mechanism:} Craigslist provides free online classified advertisements, destroying the classified advertising revenue that funded approximately 40 percent of local newspaper revenue, forcing cost reductions including workforce downsizing. ",
  "\\textbf{Outcome definition:} Quarterly Workforce Indicators (QWI) beginning-of-quarter employment, new hires, separations, and average monthly earnings for NAICS 3-digit publishing industries, averaged to county-year level and measured in natural logarithms. ",
  "\\textbf{Treatment:} Binary; indicator for Craigslist having opened a dedicated city page for the county's Core Based Statistical Area. ",
  "\\textbf{Data:} Census Bureau QWI via LEHD, 2001--2015, county-year panel with approximately ",
  format(nrow(panel_annual), big.mark = ","),
  " observations across ",
  format(params$n_counties, big.mark = ","),
  " counties. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) group-time ATT estimator with not-yet-treated control group; standard errors clustered at state level. ",
  "\\textbf{Sample:} Counties with at least 8 quarters of positive publishing employment; restricted to 2001--2015 to avoid NAICS reclassification. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(sapply(1:nrow(sde_rows_a), function(i) fmt_sde_row(sde_rows_a[i,])), collapse = " \\\\\n"),
  " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Entry Cohort)}} \\\\\n",
  paste(sapply(1:nrow(sde_rows_b), function(i) fmt_sde_row(sde_rows_b[i,])), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables written to", tables_dir, "\n")
cat("  tab1_sumstats.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_robustness.tex\n")
cat("  tab4_eventstudy.tex\n")
cat("  tabF1_sde.tex\n")
