# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# Marijuana legalization and labor market firm dynamics
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
agg_panel <- results$agg_panel

dir.create("../tables", showWarnings = FALSE)

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
cat("Generating Table 1: Summary Statistics...\n")

summ_data <- agg_panel %>%
  summarise(
    across(c(emp, frm_jb_gn, frm_jb_ls, net_firm_jb, hir_a, earn_s),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)))
  )

vars <- c("emp", "frm_jb_gn", "frm_jb_ls", "net_firm_jb", "hir_a", "earn_s")
labels <- c("Employment", "Firm Job Gains", "Firm Job Losses",
            "Net Firm Job Creation", "All Hires", "Avg Quarterly Earnings (\\$)")

tab1_rows <- ""
for (i in seq_along(vars)) {
  v <- vars[i]
  m <- format(round(summ_data[[paste0(v, "_mean")]], 0), big.mark = ",")
  s <- format(round(summ_data[[paste0(v, "_sd")]], 0), big.mark = ",")
  mn <- format(round(summ_data[[paste0(v, "_min")]], 0), big.mark = ",")
  mx <- format(round(summ_data[[paste0(v, "_max")]], 0), big.mark = ",")
  tab1_rows <- paste0(tab1_rows, labels[i], " & ", m, " & ", s,
                      " & ", mn, " & ", mx, " \\\\\n")
}

n_obs <- format(nrow(agg_panel), big.mark = ",")
n_states <- n_distinct(agg_panel$state_fips)
n_treated <- n_distinct(agg_panel$state_fips[agg_panel$g_time > 0])
n_never <- n_states - n_treated

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: State-Quarter QWI Panel, 2005--2024}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & Std. Dev. & Min & Max \\\\\n",
  "\\midrule\n",
  tab1_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} N = ", n_obs, " state-quarter observations ",
  "covering ", n_states, " states and DC (", n_treated,
  " legalizing, ", n_never, " never-treated) ",
  "from 2005 Q1 to 2024 Q4. All-industry totals (NAICS 00). ",
  "Employment and flow variables from the Quarterly Workforce Indicators (QWI). ",
  "Firm Job Gains and Losses capture employment changes at establishments that ",
  "are expanding or contracting, respectively.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ===========================================================================
# Table 2: Main CS-DiD Results
# ===========================================================================
cat("Generating Table 2: Main Results...\n")

format_coef <- function(att, se) {
  stars <- ""
  p <- 2 * (1 - pnorm(abs(att / se)))
  if (p < 0.01) stars <- "***"
  else if (p < 0.05) stars <- "**"
  else if (p < 0.10) stars <- "*"
  list(
    coef = paste0(format(round(att, 4), nsmall = 4), stars),
    se = paste0("(", format(round(se, 4), nsmall = 4), ")"),
    p = p
  )
}

# CS-DiD results
cs_emp_f <- format_coef(results$overall_emp$overall.att, results$overall_emp$overall.se)
cs_net_f <- format_coef(results$overall_net$overall.att, results$overall_net$overall.se)
cs_gains_f <- format_coef(results$overall_gains$overall.att, results$overall_gains$overall.se)
cs_losses_f <- format_coef(results$overall_losses$overall.att, results$overall_losses$overall.se)
cs_earn_f <- format_coef(results$overall_earn$overall.att, results$overall_earn$overall.se)

# TWFE results
twfe_emp_c <- coef(results$twfe_emp)["post"]
twfe_emp_s <- se(results$twfe_emp)["post"]
twfe_emp_f <- format_coef(twfe_emp_c, twfe_emp_s)

twfe_net_c <- coef(results$twfe_net)["post"]
twfe_net_s <- se(results$twfe_net)["post"]
twfe_net_f <- format_coef(twfe_net_c, twfe_net_s)

twfe_gains_c <- coef(results$twfe_gains)["post"]
twfe_gains_s <- se(results$twfe_gains)["post"]
twfe_gains_f <- format_coef(twfe_gains_c, twfe_gains_s)

twfe_losses_c <- coef(results$twfe_losses)["post"]
twfe_losses_s <- se(results$twfe_losses)["post"]
twfe_losses_f <- format_coef(twfe_losses_c, twfe_losses_s)

twfe_earn_c <- coef(results$twfe_earn)["post"]
twfe_earn_s <- se(results$twfe_earn)["post"]
twfe_earn_f <- format_coef(twfe_earn_c, twfe_earn_s)

n_row <- format(nrow(agg_panel), big.mark = ",")

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Recreational Marijuana Legalization on Labor Market Outcomes}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Log(Emp) & Net Firm & Firm Job & Firm Job & Avg \\\\\n",
  " &  & Job Creation & Gains & Losses & Earnings \\\\\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Callaway-Sant'Anna}} \\\\\n",
  "\\addlinespace\n",
  "ATT & ", cs_emp_f$coef, " & ", cs_net_f$coef, " & ", cs_gains_f$coef,
  " & ", cs_losses_f$coef, " & ", cs_earn_f$coef, " \\\\\n",
  " & ", cs_emp_f$se, " & ", cs_net_f$se, " & ", cs_gains_f$se,
  " & ", cs_losses_f$se, " & ", cs_earn_f$se, " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: TWFE}} \\\\\n",
  "\\addlinespace\n",
  "Post & ", twfe_emp_f$coef, " & ", twfe_net_f$coef, " & ", twfe_gains_f$coef,
  " & ", twfe_losses_f$coef, " & ", twfe_earn_f$coef, " \\\\\n",
  " & ", twfe_emp_f$se, " & ", twfe_net_f$se, " & ", twfe_gains_f$se,
  " & ", twfe_losses_f$se, " & ", twfe_earn_f$se, " \\\\\n",
  "\\midrule\n",
  "N & ", n_row, " & ", n_row, " & ", n_row, " & ", n_row, " & ", n_row, " \\\\\n",
  "States & ", n_states, " & ", n_states, " & ", n_states, " & ", n_states,
  " & ", n_states, " \\\\\n",
  "Treated states & ", n_treated, " & ", n_treated, " & ", n_treated,
  " & ", n_treated, " & ", n_treated, " \\\\\n",
  "Control group & Never & Never & Never & Never & Never \\\\\n",
  "Clustering & State & State & State & State & State \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A reports the overall ATT from the \\citet{callaway2021} estimator ",
  "with never-treated states as controls. Panel B reports static TWFE coefficients with state and ",
  "quarter fixed effects. Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Employment is in logs; firm job creation variables are in levels (thousands). ",
  "Treatment is the quarter of first legal recreational marijuana retail sales.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ===========================================================================
# Table 3: Industry Decomposition
# ===========================================================================
cat("Generating Table 3: Industry Decomposition...\n")

ind_res <- results$industry_results
ind_labels <- c("44-45" = "Retail Trade", "72" = "Accommodation \\& Food",
                "62" = "Health Care", "31-33" = "Manufacturing",
                "54" = "Professional Services", "11" = "Agriculture")

tab3_rows <- ""
for (code in names(ind_res)) {
  r <- ind_res[[code]]
  f <- format_coef(r$att, r$se)
  label <- ind_labels[code]
  tab3_rows <- paste0(tab3_rows,
    label, " & ", f$coef, " & ", f$se, " & ", r$n_treated, " \\\\\n")
}

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{CS-DiD Effects on Log Employment by Industry}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Industry & ATT & SE & Treated States \\\\\n",
  "\\midrule\n",
  tab3_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the overall ATT from a separate Callaway-Sant'Anna ",
  "estimation on state-quarter log employment within the given NAICS sector. Never-treated states ",
  "serve as controls. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:industry}\n",
  "\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_industry.tex")

# ===========================================================================
# Table 4: Robustness
# ===========================================================================
cat("Generating Table 4: Robustness...\n")

# Placebo
ph_f <- format_coef(rob$placebo_health_att, rob$placebo_health_se)
pe_f <- format_coef(rob$placebo_edu_att, rob$placebo_edu_se)

# Not-yet-treated
nyt_f <- format_coef(rob$overall_nyt$overall.att, rob$overall_nyt$overall.se)

# LOO range
loo_min <- min(rob$loo_results$att)
loo_max <- max(rob$loo_results$att)

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & ATT & SE \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Placebo Outcomes}} \\\\\n",
  "\\addlinespace\n",
  "Health Care (NAICS 62) & ", ph_f$coef, " & ", ph_f$se, " \\\\\n",
  "Education (NAICS 61) & ", pe_f$coef, " & ", pe_f$se, " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Alternative Control Group}} \\\\\n",
  "\\addlinespace\n",
  "Not-yet-treated & ", nyt_f$coef, " & ", nyt_f$se, " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Leave-One-State-Out}} \\\\\n",
  "\\addlinespace\n",
  "ATT range & [", format(round(loo_min, 4), nsmall = 4), ", ",
  format(round(loo_max, 4), nsmall = 4), "] & --- \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel D: Pre-Trend Test}} \\\\\n",
  "\\addlinespace\n",
  "Wald $\\chi^2$(", rob$wald_df, ") & ",
  format(round(rob$wald_stat, 2), nsmall = 2), " & $p$ = ",
  format(round(rob$wald_p, 3), nsmall = 3), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications use the Callaway-Sant'Anna estimator on log employment. ",
  "Panel A tests placebo outcomes that should be unaffected by marijuana legalization. ",
  "Panel B uses not-yet-treated states as the control group instead of never-treated. ",
  "Panel C reports the range of ATT estimates when dropping each treated state in turn. ",
  "Panel D reports a joint Wald test for pre-treatment event-study coefficients.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_robustness.tex")

# ===========================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ===========================================================================
cat("Generating SDE table...\n")

# Extract SDE components from CS-DiD
sde_rows <- list()

# Employment (log)
beta_emp <- results$overall_emp$overall.att
se_emp <- results$overall_emp$overall.se
sd_y_emp <- sd(agg_panel$log_emp, na.rm = TRUE)
sde_emp <- beta_emp / sd_y_emp
se_sde_emp <- se_emp / sd_y_emp

# Net firm job creation
beta_net <- results$overall_net$overall.att
se_net <- results$overall_net$overall.se
sd_y_net <- sd(agg_panel$net_firm_jb, na.rm = TRUE)
sde_net <- beta_net / sd_y_net
se_sde_net <- se_net / sd_y_net

# Firm job gains
beta_gains <- results$overall_gains$overall.att
se_gains <- results$overall_gains$overall.se
sd_y_gains <- sd(agg_panel$frm_jb_gn, na.rm = TRUE)
sde_gains <- beta_gains / sd_y_gains
se_sde_gains <- se_gains / sd_y_gains

# Firm job losses
beta_losses <- results$overall_losses$overall.att
se_losses <- results$overall_losses$overall.se
sd_y_losses <- sd(agg_panel$frm_jb_ls, na.rm = TRUE)
sde_losses <- beta_losses / sd_y_losses
se_sde_losses <- se_losses / sd_y_losses

# Earnings
beta_earn <- results$overall_earn$overall.att
se_earn <- results$overall_earn$overall.se
sd_y_earn <- sd(agg_panel$earn_s, na.rm = TRUE)
sde_earn <- beta_earn / sd_y_earn
se_sde_earn <- se_earn / sd_y_earn

classify_sde <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

fmt <- function(x) format(round(x, 4), nsmall = 4)

sde_table_rows <- paste0(
  "Log(Employment) & CS-DiD & ", fmt(beta_emp), " & --- & ", fmt(sd_y_emp),
  " & ", fmt(sde_emp), " & ", fmt(se_sde_emp), " & ", classify_sde(sde_emp), " \\\\\n",
  "Net Firm Job Creation & CS-DiD & ", fmt(beta_net), " & --- & ", fmt(sd_y_net),
  " & ", fmt(sde_net), " & ", fmt(se_sde_net), " & ", classify_sde(sde_net), " \\\\\n",
  "Firm Job Gains & CS-DiD & ", fmt(beta_gains), " & --- & ", fmt(sd_y_gains),
  " & ", fmt(sde_gains), " & ", fmt(se_sde_gains), " & ", classify_sde(sde_gains), " \\\\\n",
  "Firm Job Losses & CS-DiD & ", fmt(beta_losses), " & --- & ", fmt(sd_y_losses),
  " & ", fmt(sde_losses), " & ", fmt(se_sde_losses), " & ", classify_sde(sde_losses), " \\\\\n",
  "Avg Earnings & CS-DiD & ", fmt(beta_earn), " & --- & ", fmt(sd_y_earn),
  " & ", fmt(sde_earn), " & ", fmt(se_sde_earn), " & ", classify_sde(sde_earn), " \\\\\n"
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sde_table_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
  "to facilitate cross-study comparison of treatment effect magnitudes. ",
  "For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) ",
  "column is marked ``---''. ",
  "SD($Y$) is the unconditional standard deviation from the full analysis sample.\n\n",
  "\\textbf{Country:} United States.\n",
  "\\textbf{Research question:} Whether state-level recreational marijuana legalization affects ",
  "aggregate employment, firm creation, firm destruction, and earnings.\n",
  "\\textbf{Policy mechanism:} State laws permitting licensed retail sale of recreational cannabis ",
  "to adults over 21, creating a new legal market with licensed cultivators, processors, and ",
  "dispensaries while imposing excise and sales taxes on cannabis products.\n",
  "\\textbf{Outcome definition:} QWI all-industry state-quarter totals: Employment (beginning-of-quarter ",
  "count), Firm Job Gains (jobs added at expanding/opening establishments), Firm Job Losses (jobs lost ",
  "at contracting/closing establishments), Net Firm Job Creation (gains minus losses), Average Quarterly ",
  "Earnings (average over all workers at all firms).\n",
  "\\textbf{Treatment:} Binary --- state legalized recreational marijuana retail sales.\n",
  "\\textbf{Data:} Census Bureau Quarterly Workforce Indicators (QWI), sex-by-age-by-NAICS files, ",
  "aggregated to state-quarter-industry, 2005 Q1--2024 Q4.\n",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with never-treated states as controls, ",
  "state-clustered standard errors.\n",
  "\\textbf{Sample:} All 50 states plus DC; 24 legalizing states with staggered retail-sale dates ",
  "(2014--2024), 27 never-treated controls.\n\n",
  "Classification thresholds (7 categories): ",
  "large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), ",
  "small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), ",
  "small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), ",
  "large positive ($> 0.15$). ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables written to tables/\n")
