## 05_tables.R — Generate all tables for paper

source("00_packages.R")

panel <- fread("../data/panel_clean.csv")
elec <- panel[industry == "electricity"]
models <- readRDS("../data/main_models.rds")
rob_models <- readRDS("../data/robustness_models.rds")
ri_results <- jsonlite::fromJSON("../data/ri_results.json")
diag <- jsonlite::fromJSON("../data/diagnostics.json")

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("=== Generating Table 1: Summary Statistics ===\n")

# Electricity sector by period
sumstats <- elec[, .(
  mean_emp = round(mean(employment), 1),
  sd_emp = round(sd(employment), 1),
  min_emp = round(min(employment), 1),
  max_emp = round(max(employment), 1),
  mean_log_emp = round(mean(log_emp), 3),
  sd_log_emp = round(sd(log_emp), 3),
  n_obs = .N
), by = period]
sumstats[, period := factor(period, levels = c("pre", "tax", "post_repeal"))]
setorder(sumstats, period)

# Overall summary stats for the paper
overall_stats <- elec[, .(
  mean_emp = round(mean(employment), 1),
  sd_emp = round(sd(employment), 1),
  mean_coal = round(mean(coal_share), 2),
  sd_coal = round(sd(coal_share), 2),
  n_states = length(unique(state)),
  n_quarters = length(unique(yq))
)]

# State-level means for treatment variation table
state_summ <- elec[, .(
  mean_emp = round(mean(employment), 1),
  coal_share = unique(coal_share),
  carbon_int = unique(carbon_intensity)
), by = state][order(-coal_share)]

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Electricity-Sector Employment by State}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "State & Coal Share & Carbon Intensity & Mean Employment & Obs. \\\\\n",
  " & (2010--11) & (CO\\textsubscript{2}-adj.) & (thousands) & \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: High-Carbon States}} \\\\\n",
  sprintf("Victoria & %.2f & %.3f & %.1f & %d \\\\\n",
          state_summ[state == "VIC"]$coal_share, state_summ[state == "VIC"]$carbon_int,
          state_summ[state == "VIC"]$mean_emp, nrow(elec[state == "VIC"])),
  sprintf("New South Wales & %.2f & %.3f & %.1f & %d \\\\\n",
          state_summ[state == "NSW"]$coal_share, state_summ[state == "NSW"]$carbon_int,
          state_summ[state == "NSW"]$mean_emp, nrow(elec[state == "NSW"])),
  sprintf("Queensland & %.2f & %.3f & %.1f & %d \\\\\n",
          state_summ[state == "QLD"]$coal_share, state_summ[state == "QLD"]$carbon_int,
          state_summ[state == "QLD"]$mean_emp, nrow(elec[state == "QLD"])),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Medium-Carbon States}} \\\\\n",
  sprintf("Western Australia & %.2f & %.3f & %.1f & %d \\\\\n",
          state_summ[state == "WA"]$coal_share, state_summ[state == "WA"]$carbon_int,
          state_summ[state == "WA"]$mean_emp, nrow(elec[state == "WA"])),
  sprintf("South Australia & %.2f & %.3f & %.1f & %d \\\\\n",
          state_summ[state == "SA"]$coal_share, state_summ[state == "SA"]$carbon_int,
          state_summ[state == "SA"]$mean_emp, nrow(elec[state == "SA"])),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Low-Carbon States}} \\\\\n",
  sprintf("Tasmania & %.2f & %.3f & %.1f & %d \\\\\n",
          state_summ[state == "TAS"]$coal_share, state_summ[state == "TAS"]$carbon_int,
          state_summ[state == "TAS"]$mean_emp, nrow(elec[state == "TAS"])),
  sprintf("Northern Territory & %.2f & %.3f & %.1f & %d \\\\\n",
          state_summ[state == "NT"]$coal_share, state_summ[state == "NT"]$carbon_int,
          state_summ[state == "NT"]$mean_emp, nrow(elec[state == "NT"])),
  sprintf("Australian Capital Territory & %.2f & %.3f & %.1f & %d \\\\\n",
          state_summ[state == "ACT"]$coal_share, state_summ[state == "ACT"]$carbon_int,
          state_summ[state == "ACT"]$mean_emp, nrow(elec[state == "ACT"])),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} N = 480 state-quarter observations (8 states $\\times$ 60 quarters, 2005Q1--2019Q4). ",
  "Employment is from ABS Cat.\\ 6291.0.55.001 Table 5 (ANZSIC Division D: Electricity, Gas, Water and Waste Services), ",
  "in thousands of persons, quarterly, original series. ",
  "Coal share is the proportion of electricity generated from coal in the 2010--11 fiscal year (BREE \\emph{Australian Energy Statistics} 2012). ",
  "Carbon intensity adjusts coal share upward by 40\\% for Victoria's brown coal (lignite), ",
  "which emits approximately 1.2--1.4 tonnes CO\\textsubscript{2} per MWh compared to 0.8--1.0 for black coal.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ---------------------------------------------------------------
# Table 2: Main Results
# ---------------------------------------------------------------
cat("=== Generating Table 2: Main Results ===\n")

m1 <- models$m1; m2 <- models$m2; m3 <- models$m3; m4 <- models$m4

# Extract coefficients
get_coef <- function(mod, var) {
  cf <- coef(mod)[var]
  se <- sqrt(vcov(mod)[var, var])
  pv <- 2 * pt(abs(cf/se), df = mod$nobs - length(coef(mod)) - mod$fixef_sizes[1] - mod$fixef_sizes[2], lower.tail = FALSE)
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  list(coef = cf, se = se, pval = pv, stars = stars)
}

fmt_coef <- function(x) sprintf("%.3f%s", x$coef, x$stars)
fmt_se <- function(x) sprintf("(%.3f)", x$se)

# Build table
tax_vars <- c("coal_x_tax", "carbon_x_tax", "coal_x_tax", "high_x_tax")
post_vars <- c("coal_x_post", "carbon_x_post", "coal_x_post", "high_x_post")

m1_tax <- get_coef(m1, "coal_x_tax")
m1_post <- get_coef(m1, "coal_x_post")
m2_tax <- get_coef(m2, "carbon_x_tax")
m2_post <- get_coef(m2, "carbon_x_post")
m3_tax <- get_coef(m3, "coal_x_tax")
m3_post <- get_coef(m3, "coal_x_post")
m4_tax <- get_coef(m4, "high_x_tax")
m4_post <- get_coef(m4, "high_x_post")

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Carbon Tax on Log Electricity Employment}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Coal Share & Carbon Int. & Controls & Binary \\\\\n",
  "\\midrule\n",
  sprintf("Treatment $\\times$ Tax Period & %s & %s & %s & %s \\\\\n",
          fmt_coef(m1_tax), fmt_coef(m2_tax), fmt_coef(m3_tax), fmt_coef(m4_tax)),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          fmt_se(m1_tax), fmt_se(m2_tax), fmt_se(m3_tax), fmt_se(m4_tax)),
  "[0.5em]\n",
  sprintf("Treatment $\\times$ Post-Repeal & %s & %s & %s & %s \\\\\n",
          fmt_coef(m1_post), fmt_coef(m2_post), fmt_coef(m3_post), fmt_coef(m4_post)),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          fmt_se(m1_post), fmt_se(m2_post), fmt_se(m3_post), fmt_se(m4_post)),
  "\\midrule\n",
  "Treatment intensity & Coal share & Carbon int. & Coal share & Binary \\\\\n",
  "State economic controls & No & No & Yes & No \\\\\n",
  "State FE & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %d & %d & %d & %d \\\\\n", m1$nobs, m2$nobs, m3$nobs, m4$nobs),
  "States & 8 & 8 & 8 & 8 \\\\\n",
  sprintf("Adj.\\ $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
          fitstat(m1, "ar2")[[1]], fitstat(m2, "ar2")[[1]],
          fitstat(m3, "ar2")[[1]], fitstat(m4, "ar2")[[1]]),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Dependent variable is log quarterly electricity-sector employment (ANZSIC Division D). ",
  "Column (1): treatment intensity is baseline coal share of electricity generation (2010--11). ",
  "Column (2): coal share adjusted for Victoria's higher-carbon brown coal. ",
  "Column (3): adds log non-electricity employment as state-level economic control. ",
  "Column (4): binary indicator for high-coal states (NSW, VIC, QLD: coal share $\\geq$ 0.60). ",
  "Tax Period = 2012Q3--2014Q2. Post-Repeal = 2014Q3--2019Q4. ",
  "Sample: 8 Australian states and territories, 2005Q1--2019Q4.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "../tables/tab2_main.tex")

# ---------------------------------------------------------------
# Table 3: Placebo Tests
# ---------------------------------------------------------------
cat("=== Generating Table 3: Placebo Tests ===\n")

pm <- rob_models$placebo_mining
pf <- rob_models$placebo_manuf
pc <- rob_models$placebo_constr

pm_tax <- get_coef(pm, "coal_x_tax")
pm_post <- get_coef(pm, "coal_x_post")
pf_tax <- get_coef(pf, "coal_x_tax")
pf_post <- get_coef(pf, "coal_x_post")
pc_tax <- get_coef(pc, "coal_x_tax")
pc_post <- get_coef(pc, "coal_x_post")

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Placebo Tests: Non-Electricity Industries}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Mining & Manufacturing & Construction \\\\\n",
  "\\midrule\n",
  sprintf("Coal Share $\\times$ Tax Period & %s & %s & %s \\\\\n",
          fmt_coef(pm_tax), fmt_coef(pf_tax), fmt_coef(pc_tax)),
  sprintf(" & %s & %s & %s \\\\\n",
          fmt_se(pm_tax), fmt_se(pf_tax), fmt_se(pc_tax)),
  "[0.5em]\n",
  sprintf("Coal Share $\\times$ Post-Repeal & %s & %s & %s \\\\\n",
          fmt_coef(pm_post), fmt_coef(pf_post), fmt_coef(pc_post)),
  sprintf(" & %s & %s & %s \\\\\n",
          fmt_se(pm_post), fmt_se(pf_post), fmt_se(pc_post)),
  "\\midrule\n",
  "State FE & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %d & %d & %d \\\\\n", pm$nobs, pf$nobs, pc$nobs),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Same specification as Table~\\ref{tab:main} Column (1), applied to non-electricity industries. ",
  "The carbon tax targeted electricity generation; these industries were not directly exposed ",
  "through generation costs. Mining had 26 observations dropped due to zero employment (ACT). ",
  "Null effects in all placebo sectors support the parallel trends assumption.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:placebo}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "../tables/tab3_placebo.tex")

# ---------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------
cat("=== Generating Table 4: Robustness ===\n")

rt <- rob_models$state_trends
rb <- rob_models$exclude_small
rn <- rob_models$exclude_transition
rd <- rob_models$ddd

rt_tax <- get_coef(rt, "coal_x_tax")
rt_post <- get_coef(rt, "coal_x_post")
rb_tax <- get_coef(rb, "coal_x_tax")
rb_post <- get_coef(rb, "coal_x_post")
rn_tax <- get_coef(rn, "coal_x_tax")
rn_post <- get_coef(rn, "coal_x_post")
rd_tax <- get_coef(rd, "elec_coal_tax")
rd_post <- get_coef(rd, "elec_coal_post")

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & State Trends & Excl.\\ Small & Excl.\\ Trans. & Triple Diff. \\\\\n",
  "\\midrule\n",
  sprintf("Treatment $\\times$ Tax Period & %s & %s & %s & %s \\\\\n",
          fmt_coef(rt_tax), fmt_coef(rb_tax), fmt_coef(rn_tax), fmt_coef(rd_tax)),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          fmt_se(rt_tax), fmt_se(rb_tax), fmt_se(rn_tax), fmt_se(rd_tax)),
  "[0.5em]\n",
  sprintf("Treatment $\\times$ Post-Repeal & %s & %s & %s & %s \\\\\n",
          fmt_coef(rt_post), fmt_coef(rb_post), fmt_coef(rn_post), fmt_coef(rd_post)),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          fmt_se(rt_post), fmt_se(rb_post), fmt_se(rn_post), fmt_se(rd_post)),
  "\\midrule\n",
  "State-specific trends & Yes & No & No & No \\\\\n",
  "Excl.\\ ACT \\& NT & No & Yes & No & No \\\\\n",
  "Excl.\\ transition Q & No & No & Yes & No \\\\\n",
  "Manufacturing control & No & No & No & Yes \\\\\n",
  sprintf("Observations & %d & %d & %d & %d \\\\\n", rt$nobs, rb$nobs, rn$nobs, rd$nobs),
  sprintf("RI $p$-value (tax) & \\multicolumn{4}{c}{%.3f} \\\\\n", ri_results$ri_pval_tax),
  sprintf("RI $p$-value (post) & \\multicolumn{4}{c}{%.3f} \\\\\n", ri_results$ri_pval_post),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Column (1): adds state-specific linear time trends. ",
  "Column (2): drops ACT and NT (electricity sectors $<$ 3,000 employees). ",
  "Column (3): excludes the transition quarters (2012Q3, 2014Q3) when the tax started and ended. ",
  "Column (4): triple-difference using manufacturing as within-state control industry. ",
  sprintf("Randomization inference (RI) $p$-values based on %d permutations of coal shares across states.\n",
          ri_results$n_permutations),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "../tables/tab4_robust.tex")

# ---------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE)
# ---------------------------------------------------------------
cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# Main specification (Model 1)
beta_tax <- coef(models$m1)["coal_x_tax"]
se_tax <- sqrt(vcov(models$m1)["coal_x_tax", "coal_x_tax"])
beta_post <- coef(models$m1)["coal_x_post"]
se_post <- sqrt(vcov(models$m1)["coal_x_post", "coal_x_post"])

# SD(Y) — unconditional SD of log employment
sd_y <- sd(elec$log_emp)
# SD(X) — treatment is continuous (coal_share × period indicator)
# For continuous DiD, SDE = beta * SD(X) / SD(Y)
sd_x_tax <- sd(elec$coal_x_tax)
sd_x_post <- sd(elec$coal_x_post)

sde_tax <- beta_tax * sd_x_tax / sd_y
se_sde_tax <- se_tax * sd_x_tax / sd_y
sde_post <- beta_post * sd_x_post / sd_y
se_sde_post <- se_post * sd_x_post / sd_y

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

# Heterogeneity: high-coal vs medium-coal states
elec_high <- elec[coal_share >= 0.60]
elec_med <- elec[coal_share > 0 & coal_share < 0.60]

m_high <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq, data = elec_high, cluster = ~state)
m_med <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq, data = elec_med, cluster = ~state)

beta_high <- coef(m_high)["coal_x_tax"]
se_high <- sqrt(vcov(m_high)["coal_x_tax", "coal_x_tax"])
sd_y_high <- sd(elec_high$log_emp)
sd_x_high <- sd(elec_high$coal_x_tax)
sde_high <- beta_high * sd_x_high / sd_y_high
se_sde_high <- se_high * sd_x_high / sd_y_high

beta_med <- coef(m_med)["coal_x_tax"]
se_med <- sqrt(vcov(m_med)["coal_x_tax", "coal_x_tax"])
sd_y_med <- sd(elec_med$log_emp)
sd_x_med <- sd(elec_med$coal_x_tax)
sde_med <- beta_med * sd_x_med / sd_y_med
se_sde_med <- se_med * sd_x_med / sd_y_med

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{llccccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{9}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Log employment & Tax period & %.4f & %.4f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_tax, se_tax, sd_x_tax, sd_y, sde_tax, se_sde_tax, classify(sde_tax)),
  sprintf("Log employment & Post-repeal & %.4f & %.4f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_post, se_post, sd_x_post, sd_y, sde_post, se_sde_post, classify(sde_post)),
  "\\midrule\n",
  "\\multicolumn{9}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("High-coal states & Tax period & %.4f & %.4f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_high, se_high, sd_x_high, sd_y_high, sde_high, se_sde_high, classify(sde_high)),
  sprintf("Medium-coal states & Tax period & %.4f & %.4f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_med, se_med, sd_x_med, sd_y_med, sde_med, se_sde_med, classify(sde_med)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize\n",
  "\\begin{itemize}[leftmargin=*]\n",
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Australia. ",
  "\\textbf{Research question:} Did Australia's carbon pricing mechanism (AUD 23--24/tonne CO\\textsubscript{2}, July 2012--July 2014) reduce electricity-sector employment in coal-intensive states? ",
  "\\textbf{Policy mechanism:} The Clean Energy Act 2011 imposed a carbon price on approximately 500 entities covering 60\\% of Australia's emissions, directly increasing the cost of coal-fired electricity generation relative to gas and renewables, with the policy repealed after two years. ",
  "\\textbf{Outcome definition:} Log quarterly employment in ANZSIC Division D (Electricity, Gas, Water and Waste Services) from ABS Cat.\\ 6291.0.55.001, measuring the total number of employed persons in the electricity-sector workforce. ",
  "\\textbf{Treatment:} Continuous --- baseline coal share of state electricity generation (2010--11), ranging from 0.00 (ACT, NT) to 0.92 (Victoria). ",
  "\\textbf{Data:} ABS Labour Force Detailed (Cat.\\ 6291.0.55.001) Table 5, quarterly, 2005Q1--2019Q4, 8 states and territories, 480 state-quarter observations. ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with state and quarter fixed effects, standard errors clustered at the state level. ",
  "\\textbf{Sample:} All eight Australian states and territories; electricity sector only (ANZSIC Division D). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of the treatment interaction ",
  "and SD($Y$) is the unconditional standard deviation of log employment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).\n",
  "\\end{itemize}}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
cat("Files:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_placebo.tex\n")
cat("  tables/tab4_robust.tex\n")
cat("  tables/tabF1_sde.tex\n")
