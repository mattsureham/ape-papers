# 05_tables.R — Generate all LaTeX tables
# APEP Working Paper apep_0917

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

# Compute summary stats
summ_vars <- panel[, .(
  es_total_revenue,
  asinh_es_revenue,
  has_es_revenue
)]

make_row <- function(var, label, data = panel) {
  x <- data[[var]]
  sprintf("%-45s & %s & %s & %s & %s \\\\",
          label,
          formatC(mean(x, na.rm=TRUE), format="f", digits=2, big.mark=","),
          formatC(sd(x, na.rm=TRUE), format="f", digits=2, big.mark=","),
          formatC(min(x, na.rm=TRUE), format="f", digits=0, big.mark=","),
          formatC(max(x, na.rm=TRUE), format="f", digits=0, big.mark=","))
}

# By reform status
panel_reformed <- panel[reform_year > 0]
panel_control <- panel[reform_year == 0]

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Equitable Sharing Revenue by Reform Status}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & Std.\\ Dev. & Min & Max \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Full Sample (N = 63,427 agency-years)}} \\\\",
  make_row("es_total_revenue", "ES revenue (\\$)"),
  make_row("asinh_es_revenue", "ES revenue (asinh)"),
  make_row("has_es_revenue", "Any ES revenue (0/1)"),
  "\\midrule",
  sprintf("\\multicolumn{5}{l}{\\textit{Panel B: Reformed States (N = %s)}} \\\\",
          formatC(nrow(panel_reformed), big.mark=",")),
  make_row("es_total_revenue", "ES revenue (\\$)", panel_reformed),
  make_row("has_es_revenue", "Any ES revenue (0/1)", panel_reformed),
  "\\midrule",
  sprintf("\\multicolumn{5}{l}{\\textit{Panel C: Never-Reformed States (N = %s)}} \\\\",
          formatC(nrow(panel_control), big.mark=",")),
  make_row("es_total_revenue", "ES revenue (\\$)", panel_control),
  make_row("has_es_revenue", "Any ES revenue (0/1)", panel_control),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Unit of observation is agency-fiscal year. ",
         "ES revenue is total equitable sharing funds received from the DOJ ",
         "Asset Forfeiture Fund and Treasury Forfeiture Fund. ",
         "Sample covers FY2016--FY2024 for all U.S.\\ law enforcement agencies ",
         "filing annual certifications with the DOJ. ",
         "Reformed states (38) enacted civil forfeiture restrictions between 2014--2021. ",
         "Never-reformed states (13): AK, AL, DC, DE, LA, MA, ME, MS, NJ, NY, RI, VT, WA."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results
# ============================================================
cat("Generating Table 2: Main Results\n")

# Extract coefficients
twfe_b <- coef(results$twfe_asinh)["post_reform"]
twfe_se <- sqrt(diag(vcov(results$twfe_asinh)))["post_reform"]
twfe_p <- summary(results$twfe_asinh)$coeftable["post_reform", "Pr(>|t|)"]
twfe_n <- summary(results$twfe_asinh)$nobs

cs_b <- results$agg_simple$overall.att
cs_se <- results$agg_simple$overall.se

ext_twfe_b <- coef(results$twfe_ext)["post_reform"]
ext_twfe_se <- sqrt(diag(vcov(results$twfe_ext)))["post_reform"]

ext_cs_b <- results$agg_ext_simple$overall.att
ext_cs_se <- results$agg_ext_simple$overall.se

stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
pval_cs <- function(att, se) 2 * pnorm(-abs(att / se))

tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of State Forfeiture Reform on Federal Equitable Sharing Revenue}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Intensive Margin} & \\multicolumn{2}{c}{Extensive Margin} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & TWFE & CS-DiD & TWFE & CS-DiD \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Post-reform & %s%s & %s%s & %s%s & %s%s \\\\",
          formatC(twfe_b, format="f", digits=3), stars(twfe_p),
          formatC(cs_b, format="f", digits=3), stars(pval_cs(cs_b, cs_se)),
          formatC(ext_twfe_b, format="f", digits=4),
          stars(summary(results$twfe_ext)$coeftable["post_reform", "Pr(>|t|)"]),
          formatC(ext_cs_b, format="f", digits=4), stars(pval_cs(ext_cs_b, ext_cs_se))),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          formatC(twfe_se, format="f", digits=3),
          formatC(cs_se, format="f", digits=3),
          formatC(ext_twfe_se, format="f", digits=4),
          formatC(ext_cs_se, format="f", digits=4)),
  sprintf(" & [%s, %s] & [%s, %s] & & \\\\",
          formatC(twfe_b - 1.96*twfe_se, format="f", digits=3),
          formatC(twfe_b + 1.96*twfe_se, format="f", digits=3),
          formatC(cs_b - 1.96*cs_se, format="f", digits=3),
          formatC(cs_b + 1.96*cs_se, format="f", digits=3)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(twfe_n, big.mark=","),
          formatC(twfe_n, big.mark=","),
          formatC(twfe_n, big.mark=","),
          formatC(twfe_n, big.mark=",")),
  "Agencies & 7,250 & 5,839 & 7,250 & 5,839 \\\\",
  "States & 51 & 51 & 51 & 51 \\\\",
  "Agency FE & Yes & --- & Yes & --- \\\\",
  "Year FE & Yes & --- & Yes & --- \\\\",
  "Clustering & State & State & State & State \\\\",
  "Estimator & TWFE & CS (2021) & TWFE & CS (2021) \\\\",
  "Outcome & asinh(ES\\$) & asinh(ES\\$) & 1(ES\\$>0) & 1(ES\\$>0) \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses; ",
         "95\\% confidence intervals in brackets. ",
         "Columns (1)--(2) report the intensive margin effect on the inverse hyperbolic sine ",
         "of total equitable sharing revenue. ",
         "Columns (3)--(4) report the extensive margin effect on the probability of receiving ",
         "any equitable sharing revenue. ",
         "TWFE includes agency and fiscal year fixed effects. ",
         "CS-DiD uses the \\citet{callaway2021difference} estimator with never-treated states as ",
         "the comparison group and doubly robust estimation. ",
         "CS-DiD drops 1,727 agencies already treated in FY2016 (cohorts 2014--2015). ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2, file.path(table_dir, "tab2_main_results.tex"))

# ============================================================
# Table 3: Heterogeneity by Reform Strength
# ============================================================
cat("Generating Table 3: Heterogeneity\n")

strong_b <- results$agg_strong$overall.att
strong_se <- results$agg_strong$overall.se
weak_b <- results$agg_weak$overall.att
weak_se <- results$agg_weak$overall.se
anticirc_b <- results$agg_anticirc$overall.att
anticirc_se <- results$agg_anticirc$overall.se
no_anticirc_b <- results$agg_no_anticirc$overall.att
no_anticirc_se <- results$agg_no_anticirc$overall.se

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneity: Reform Strength and Anti-Circumvention Laws}",
  "\\label{tab:hetero}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Reform Strength} & \\multicolumn{2}{c}{Anti-Circumvention} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Strong & Weak & With & Without \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("ATT & %s & %s & %s & %s \\\\",
          formatC(strong_b, format="f", digits=3),
          formatC(weak_b, format="f", digits=3),
          formatC(anticirc_b, format="f", digits=3),
          formatC(no_anticirc_b, format="f", digits=3)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          formatC(strong_se, format="f", digits=3),
          formatC(weak_se, format="f", digits=3),
          formatC(anticirc_se, format="f", digits=3),
          formatC(no_anticirc_se, format="f", digits=3)),
  "\\midrule",
  "Reform type & Abolish/ & Burden/ & With anti- & Without anti- \\\\",
  " & Conviction & Reporting & circumvention & circumvention \\\\",
  "Treated states & 13 & 25 & 4 & 34 \\\\",
  "Control states & 13 & 13 & 13 & 13 \\\\",
  "Estimator & CS (2021) & CS (2021) & CS (2021) & CS (2021) \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Each column reports the Callaway--Sant'Anna (2021) ATT from a ",
         "separate estimation on a subsample of treated states plus all 13 never-reformed control states. ",
         "Standard errors clustered at the state level in parentheses. ",
         "``Strong'' reforms require criminal conviction or abolish civil forfeiture entirely (13 states). ",
         "``Weak'' reforms raise the burden of proof or impose reporting requirements (25 states). ",
         "``Anti-circumvention'' states (4: NM, NE, AZ, CO) explicitly prohibit agencies from ",
         "routing seizures through federal equitable sharing to evade state restrictions. ",
         "Outcome: asinh(equitable sharing revenue). ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3, file.path(table_dir, "tab3_heterogeneity.tex"))

# ============================================================
# Table 4: Robustness
# ============================================================
cat("Generating Table 4: Robustness\n")

# Extract robustness estimates
rob_state_b <- coef(rob$twfe_state_total)["post_reform"]
rob_state_se <- sqrt(diag(vcov(rob$twfe_state_total)))["post_reform"]

rob_log_b <- coef(rob$twfe_log)["post_reform"]
rob_log_se <- sqrt(diag(vcov(rob$twfe_log)))["post_reform"]

rob_level_b <- coef(rob$twfe_level)["post_reform"]
rob_level_se <- sqrt(diag(vcov(rob$twfe_level)))["post_reform"]

rob_bal_b <- coef(rob$twfe_balanced)["post_reform"]
rob_bal_se <- sqrt(diag(vcov(rob$twfe_balanced)))["post_reform"]

rob_late_b <- coef(rob$twfe_late)["post_reform"]
rob_late_se <- sqrt(diag(vcov(rob$twfe_late)))["post_reform"]

rob_late_cs_b <- rob$agg_late$overall.att
rob_late_cs_se <- rob$agg_late$overall.se

loo_range <- range(rob$loo_results$coef)

fmt <- function(x, d=3) formatC(x, format="f", digits=d)

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness of the Null Result}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Estimate & SE & N \\\\",
  "\\midrule",
  sprintf("\\textit{Baseline TWFE (asinh)} & %s & (%s) & 63,111 \\\\",
          fmt(twfe_b), fmt(twfe_se)),
  sprintf("\\textit{Baseline CS-DiD (asinh)} & %s & (%s) & 63,111 \\\\",
          fmt(cs_b), fmt(cs_se)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Alternative outcomes}} \\\\",
  sprintf("TWFE: log(revenue + 1) & %s & (%s) & 63,111 \\\\",
          fmt(rob_log_b), fmt(rob_log_se)),
  sprintf("TWFE: level (\\$1,000s) & %s & (%s) & 63,111 \\\\",
          fmt(rob_level_b, 1), fmt(rob_level_se, 1)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Alternative samples}} \\\\",
  sprintf("TWFE: state-level total (asinh) & %s & (%s) & 454 \\\\",
          fmt(rob_state_b), fmt(rob_state_se)),
  sprintf("TWFE: balanced panel only & %s & (%s) & 15,552 \\\\",
          fmt(rob_bal_b), fmt(rob_bal_se)),
  sprintf("TWFE: drop cohorts 2014--2015 & %s & (%s) & 55,237 \\\\",
          fmt(rob_late_b), fmt(rob_late_se)),
  sprintf("CS-DiD: drop cohorts 2014--2015 & %s & (%s) & 55,237 \\\\",
          fmt(rob_late_cs_b), fmt(rob_late_cs_se)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Stability}} \\\\",
  sprintf("Leave-one-state-out range & [%s, %s] & & 51 runs \\\\",
          fmt(loo_range[1]), fmt(loo_range[2])),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} All specifications include agency (or state) and fiscal year fixed effects ",
         "with standard errors clustered at the state level. ",
         "The baseline uses the inverse hyperbolic sine of equitable sharing revenue (asinh). ",
         "``State-level total'' aggregates revenue to the state-year level. ",
         "``Balanced panel'' restricts to 1,728 agencies observed in all 9 fiscal years. ",
         "``Drop cohorts 2014--2015'' excludes states reformed before the data window begins. ",
         "Leave-one-state-out iteratively drops each state; range reports min and max coefficients. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("Generating Table F1: SDE\n")

# SDE computation
# Main outcome: asinh(ES revenue), binary treatment
sd_y_asinh <- sd(panel$asinh_es_revenue, na.rm = TRUE)
sd_y_ext <- sd(panel$has_es_revenue, na.rm = TRUE)

# Pooled: use TWFE estimates (more precise; CS confirms direction)
beta_asinh <- twfe_b
se_asinh <- twfe_se
sde_asinh <- beta_asinh / sd_y_asinh
se_sde_asinh <- se_asinh / sd_y_asinh

beta_ext <- ext_twfe_b
se_ext <- ext_twfe_se
sde_ext <- beta_ext / sd_y_ext
se_sde_ext <- se_ext / sd_y_ext

# Heterogeneity: strong reform using TWFE on subsample
panel_strong_sub <- panel[reform_year == 0 | strong_reform == TRUE]
twfe_strong_sub <- feols(asinh_es_revenue ~ post_reform | agency_id + FORM_FY,
                          data = panel_strong_sub, cluster = "NCIC_ST")
beta_strong <- coef(twfe_strong_sub)["post_reform"]
se_strong <- sqrt(diag(vcov(twfe_strong_sub)))["post_reform"]
sd_y_strong <- sd(panel_strong_sub$asinh_es_revenue, na.rm = TRUE)
sde_strong <- beta_strong / sd_y_strong
se_sde_strong <- se_strong / sd_y_strong

# Heterogeneity: weak reform using TWFE on subsample
panel_weak_sub <- panel[reform_year == 0 | strong_reform == FALSE]
twfe_weak_sub <- feols(asinh_es_revenue ~ post_reform | agency_id + FORM_FY,
                        data = panel_weak_sub, cluster = "NCIC_ST")
beta_weak <- coef(twfe_weak_sub)["post_reform"]
se_weak <- sqrt(diag(vcov(twfe_weak_sub)))["post_reform"]
sd_y_weak <- sd(panel_weak_sub$asinh_es_revenue, na.rm = TRUE)
sde_weak <- beta_weak / sd_y_weak
se_sde_weak <- se_weak / sd_y_weak

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_row <- function(outcome, spec, beta, se_b, sd_y_val, sde_val, se_sde_val) {
  sprintf("%s & %s & %s & --- & %s & %s & %s & %s \\\\",
          outcome, spec,
          fmt(beta, 4), fmt(sd_y_val, 3),
          fmt(sde_val, 4), fmt(se_sde_val, 4),
          classify(sde_val))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level civil asset forfeiture reforms cause law enforcement agencies to increase their use of the federal equitable sharing program as a circumvention mechanism? ",
  "\\textbf{Policy mechanism:} State reforms restrict or abolish civil asset forfeiture---the practice of seizing property without criminal conviction---by raising the burden of proof, requiring conviction, or banning civil forfeiture entirely; the federal equitable sharing program allows agencies to partner with federal authorities and receive up to 80\\% of seized assets under federal law, potentially circumventing state restrictions. ",
  "\\textbf{Outcome definition:} Total equitable sharing revenue received by each law enforcement agency (inverse hyperbolic sine transformation), or an indicator for any positive equitable sharing revenue (extensive margin). ",
  "\\textbf{Treatment:} Binary indicator equal to one in fiscal years at or after the state enacted civil forfeiture reform. ",
  "\\textbf{Data:} DOJ Equitable Sharing Annual Certification (ESAC) FOIA data, FY2016--FY2024, agency-year observations, 63,427 agency-years across 7,566 agencies in 51 jurisdictions. ",
  "\\textbf{Method:} Staggered difference-in-differences using TWFE with agency and fiscal year fixed effects, and Callaway--Sant'Anna (2021) estimator with never-treated comparison group; standard errors clustered at the state level (51 clusters). ",
  "\\textbf{Sample:} All U.S.\\ law enforcement agencies filing equitable sharing certifications with the DOJ; 38 reformed states and 13 never-reformed control states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sde_row("ES revenue (asinh)", "TWFE", beta_asinh, se_asinh, sd_y_asinh, sde_asinh, se_sde_asinh),
  sde_row("Any ES revenue", "TWFE", beta_ext, se_ext, sd_y_ext, sde_ext, se_sde_ext),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by reform strength)}} \\\\",
  sde_row("ES revenue (asinh)", "Strong reform", beta_strong, se_strong, sd_y_strong, sde_strong, se_sde_strong),
  sde_row("ES revenue (asinh)", "Weak reform", beta_weak, se_weak, sd_y_weak, sde_weak, se_sde_weak),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

cat("All tables generated.\n")
cat("TABLES COMPLETE\n")
