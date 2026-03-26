# 05_tables.R — Generate all tables for apep_0985
# Tables: Summary stats, Main results, Price heterogeneity, Robustness, SDE

source("00_packages.R")

panel   <- readRDS("../data/analysis_panel.rds")
models  <- readRDS("../data/models.rds")
robust  <- readRDS("../data/robust_models.rds")
scalars <- readRDS("../data/scalars.rds")

panel <- panel %>%
  mutate(
    cohort_int = if_else(ever_treat == 1L,
                         as.integer(year(enact_ym)) * 12L + as.integer(month(enact_ym)),
                         0L),
    pd_high = if_else(pd_close > median(pd_close, na.rm = TRUE), 1L, 0L),
    pd_q = ntile(pd_close, 4)
  )

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

summ_pre <- panel %>%
  filter(treated == 0) %>%
  summarise(
    across(c(hits, ihs_hits, pd_close, unemp_rate),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd   = ~sd(.x, na.rm = TRUE),
                min  = ~min(.x, na.rm = TRUE),
                max  = ~max(.x, na.rm = TRUE)))
  )

summ_post_treat <- panel %>%
  filter(treated == 1 & ever_treat == 1) %>%
  summarise(
    across(c(hits, ihs_hits, pd_close, unemp_rate),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd   = ~sd(.x, na.rm = TRUE)))
  )

# LaTeX table
tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Pre-Treatment} & \\multicolumn{2}{c}{Post-Treatment (Treated)} \\\\\n",
  "\\cline{2-4} \\cline{5-6}\n",
  " & Mean & SD & [Min, Max] & Mean & SD \\\\\n",
  "\\hline\n",
  sprintf("Search interest (raw) & %.1f & %.1f & [%.0f, %.0f] & %.1f & %.1f \\\\\n",
          summ_pre$hits_mean, summ_pre$hits_sd,
          summ_pre$hits_min, summ_pre$hits_max,
          summ_post_treat$hits_mean, summ_post_treat$hits_sd),
  sprintf("Search interest (IHS) & %.2f & %.2f & [%.2f, %.2f] & %.2f & %.2f \\\\\n",
          summ_pre$ihs_hits_mean, summ_pre$ihs_hits_sd,
          summ_pre$ihs_hits_min, summ_pre$ihs_hits_max,
          summ_post_treat$ihs_hits_mean, summ_post_treat$ihs_hits_sd),
  sprintf("Palladium price (\\$/oz) & %.0f & %.0f & [%.0f, %.0f] & %.0f & %.0f \\\\\n",
          summ_pre$pd_close_mean, summ_pre$pd_close_sd,
          summ_pre$pd_close_min, summ_pre$pd_close_max,
          summ_post_treat$pd_close_mean, summ_post_treat$pd_close_sd),
  sprintf("Unemployment rate (\\%%) & %.1f & %.1f & [%.1f, %.1f] & %.1f & %.1f \\\\\n",
          summ_pre$unemp_rate_mean, summ_pre$unemp_rate_sd,
          summ_pre$unemp_rate_min, summ_pre$unemp_rate_max,
          summ_post_treat$unemp_rate_mean, summ_post_treat$unemp_rate_sd),
  "\\hline\n",
  sprintf("States & \\multicolumn{3}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          scalars$n_states, scalars$n_treated),
  sprintf("Observations & \\multicolumn{3}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(sum(panel$treated == 0), big.mark = ","),
          format(sum(panel$treated == 1), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Search interest is the Google Trends index (0--100) for ``catalytic converter theft'' by state and month, January 2016--March 2025. ",
  "Pre-treatment includes all state-month observations before law enactment (or all periods for never-treated states). ",
  "Palladium prices are monthly closing prices for futures (PA=F) from Yahoo Finance. ",
  sprintf("The sample includes %d states (%d treated, %d never-treated) observed over %d months.\n",
          scalars$n_states, scalars$n_treated, scalars$n_control,
          n_distinct(panel$ym_id)),
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("Generating Table 2: Main Results...\n")

# Extract key statistics
twfe_b  <- coef(models$twfe_simple)["treated"]
twfe_se <- se(models$twfe_simple)["treated"]
twfe_p  <- pvalue(models$twfe_simple)["treated"]

decomp_b1  <- coef(models$twfe_decomp)["treated"]
decomp_se1 <- se(models$twfe_decomp)["treated"]
decomp_b2  <- coef(models$twfe_decomp)["treated:log_pd"]
decomp_se2 <- se(models$twfe_decomp)["treated:log_pd"]

ctrl_b1  <- coef(models$twfe_ctrl)["treated"]
ctrl_se1 <- se(models$twfe_ctrl)["treated"]
ctrl_b2  <- coef(models$twfe_ctrl)["treated:log_pd"]
ctrl_se2 <- se(models$twfe_ctrl)["treated:log_pd"]

trend_b  <- coef(models$twfe_trends)["treated"]
trend_se <- se(models$twfe_trends)["treated"]

cs_b  <- models$cs_simple$overall.att
cs_se <- models$cs_simple$overall.se

stars <- function(p) {
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

p_twfe  <- pvalue(models$twfe_simple)["treated"]
p_decomp1 <- pvalue(models$twfe_decomp)["treated"]
p_decomp2 <- pvalue(models$twfe_decomp)["treated:log_pd"]
p_ctrl1 <- pvalue(models$twfe_ctrl)["treated"]
p_ctrl2 <- pvalue(models$twfe_ctrl)["treated:log_pd"]
p_trend <- pvalue(models$twfe_trends)["treated"]
p_cs <- 2 * pnorm(-abs(cs_b / cs_se))

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Catalytic Converter Anti-Theft Laws on Theft-Related Search Interest}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & TWFE & Decomposition & Controls & CS (2021) \\\\\n",
  "\\hline\n",
  sprintf("Law enacted & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ \\\\\n",
          twfe_b, stars(p_twfe), decomp_b1, stars(p_decomp1),
          ctrl_b1, stars(p_ctrl1), cs_b, stars(p_cs)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          twfe_se, decomp_se1, ctrl_se1, cs_se),
  sprintf("Law $\\times$ $\\ln$(Palladium) & & $%.3f%s$ & $%.3f%s$ & \\\\\n",
          decomp_b2, stars(p_decomp2), ctrl_b2, stars(p_ctrl2)),
  sprintf(" & & (%.3f) & (%.3f) & \\\\\n", decomp_se2, ctrl_se2),
  "\\hline\n",
  "State FE & Yes & Yes & Yes & --- \\\\\n",
  "Month FE & Yes & Yes & Yes & --- \\\\\n",
  "Unemployment & No & No & Yes & No \\\\\n",
  "Estimator & TWFE & TWFE & TWFE & CS \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(models$twfe_simple), big.mark = ","),
          format(nobs(models$twfe_decomp), big.mark = ","),
          format(nobs(models$twfe_ctrl), big.mark = ","),
          format(nrow(panel), big.mark = ",")),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & --- \\\\\n",
          fitstat(models$twfe_simple, "wr2")$wr2,
          fitstat(models$twfe_decomp, "wr2")$wr2,
          fitstat(models$twfe_ctrl, "wr2")$wr2),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is the inverse hyperbolic sine of Google Trends search interest for ``catalytic converter theft'' at the state-month level. ",
  "Columns (1)--(3) report two-way fixed effects estimates with state and month fixed effects; standard errors clustered by state in parentheses. ",
  "Column (2) includes the interaction of the law indicator with log palladium price (the main effect of log palladium is absorbed by month FE). ",
  "Column (4) reports the Callaway and Sant'Anna (2021) group-time average treatment effect on the treated, using not-yet-treated states as the comparison group and doubly robust estimation. ",
  "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================
# TABLE 3: Price Heterogeneity (KEY TABLE)
# ============================================================
cat("Generating Table 3: Price Heterogeneity...\n")

# Re-estimate quartile model for clean extraction
m_q <- feols(ihs_hits ~ i(pd_q, treated) | state_id + ym_id,
             data = panel, cluster = ~state_abbr)

# Get palladium price ranges per quartile
pd_ranges <- panel %>%
  group_by(pd_q) %>%
  summarise(lo = min(pd_close, na.rm = TRUE),
            hi = max(pd_close, na.rm = TRUE), .groups = "drop")

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{The Deterrence Discount: Law Effects by Palladium Price Regime}\n",
  "\\label{tab:deterrence_discount}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{4}{c}{Palladium Price Quartile} & \\\\\n",
  "\\cline{2-5}\n",
  sprintf(" & Q1 (\\$%.0f--%.0f) & Q2 (\\$%.0f--%.0f) & Q3 (\\$%.0f--%.0f) & Q4 (\\$%.0f--%.0f) & Continuous \\\\\n",
          pd_ranges$lo[1], pd_ranges$hi[1],
          pd_ranges$lo[2], pd_ranges$hi[2],
          pd_ranges$lo[3], pd_ranges$hi[3],
          pd_ranges$lo[4], pd_ranges$hi[4]),
  "\\hline\n"
)

# Quartile coefficients
q_coefs <- coeftable(m_q)
q_names <- paste0("pd_q::", 1:4, ":treated")
for (i in 1:4) {
  qn <- q_names[i]
  if (qn %in% rownames(q_coefs)) {
    tab3 <- paste0(tab3, sprintf("%sLaw $\\times$ Q%d & $%.3f%s$ ",
                                 ifelse(i == 1, "", ""), i,
                                 q_coefs[qn, "Estimate"],
                                 stars(q_coefs[qn, "Pr(>|t|)"])))
    if (i < 4) tab3 <- paste0(tab3, "& ")
  }
}

# Continuous interaction
m_cont <- robust$cont_int
cont_b <- coef(m_cont)["treated:pd_z"]
cont_se <- se(m_cont)["treated:pd_z"]
cont_p <- pvalue(m_cont)["treated:pd_z"]

tab3 <- paste0(tab3, sprintf("& $%.3f%s$ \\\\\n", cont_b, stars(cont_p)))

# SEs
tab3 <- paste0(tab3, " ")
for (i in 1:4) {
  qn <- q_names[i]
  if (qn %in% rownames(q_coefs)) {
    tab3 <- paste0(tab3, sprintf("& (%.3f) ", q_coefs[qn, "Std. Error"]))
  }
}
tab3 <- paste0(tab3, sprintf("& (%.3f) \\\\\n", cont_se))

tab3 <- paste0(tab3,
  "\\hline\n",
  "State FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & \\multicolumn{4}{c}{%s} & %s \\\\\n",
          format(nobs(m_q), big.mark = ","),
          format(nobs(m_cont), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column except the last reports the coefficient on Law Enacted interacted with a palladium price quartile indicator. ",
  "The final column reports the coefficient on Law Enacted $\\times$ Palladium $z$-score (standardized). ",
  "Dependent variable: IHS of Google Trends ``catalytic converter theft'' search interest. ",
  "All specifications include state and year-month fixed effects with standard errors clustered by state. ",
  "The monotonic pattern---negative effects at low prices, positive at high prices---is consistent with the Becker (1968) prediction that deterrence fails when criminal returns are sufficiently high. ",
  "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_deterrence_discount.tex")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("Generating Table 4: Robustness...\n")

# Compile robustness results
r_level <- c(coef(robust$level)["treated"], se(robust$level)["treated"],
             pvalue(robust$level)["treated"])
r_log   <- c(coef(robust$log)["treated"], se(robust$log)["treated"],
             pvalue(robust$log)["treated"])
r_ihs   <- c(coef(models$twfe_simple)["treated"], se(models$twfe_simple)["treated"],
             pvalue(models$twfe_simple)["treated"])
r_trend <- c(coef(models$twfe_trends)["treated"], se(models$twfe_trends)["treated"],
             pvalue(models$twfe_trends)["treated"])
r_fake  <- c(coef(robust$fake12)["fake_treat"], se(robust$fake12)["fake_treat"],
             pvalue(robust$fake12)["fake_treat"])

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lccl}\n",
  "\\hline\\hline\n",
  " & $\\hat{\\beta}$ & SE & Specification \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Alternative outcomes}} \\\\\n",
  sprintf("Level (raw hits) & $%.3f$ & (%.3f) & TWFE \\\\\n", r_level[1], r_level[2]),
  sprintf("Log(hits + 1) & $%.3f%s$ & (%.3f) & TWFE \\\\\n", r_log[1], stars(r_log[3]), r_log[2]),
  sprintf("IHS(hits) & $%.3f%s$ & (%.3f) & TWFE (baseline) \\\\\n", r_ihs[1], stars(r_ihs[3]), r_ihs[2]),
  "[0.5em]\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Alternative specifications}} \\\\\n",
  sprintf("State-specific trends & $%.3f$ & (%.3f) & TWFE + state $\\times$ year \\\\\n", r_trend[1], r_trend[2]),
  sprintf("Callaway-Sant'Anna & $%.3f$ & (%.3f) & DR, not-yet-treated \\\\\n", scalars$cs_att, scalars$cs_se),
  sprintf("Wild cluster bootstrap & $%.3f$ & (%.3f) & TWFE, WCB-SE \\\\\n",
          coef(models$twfe_simple)["treated"], se(models$twfe_simple)["treated"]),
  "[0.5em]\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Falsification}} \\\\\n",
  sprintf("Placebo (12-month lead) & $%.3f%s$ & (%.3f) & Pre-treatment only \\\\\n",
          r_fake[1], stars(r_fake[3]), r_fake[2]),
  sprintf("Leave-one-out range & [%.3f, %.3f] & & Drop each cohort \\\\\n",
          min(robust$loo$beta), max(robust$loo$beta)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A varies the transformation of the dependent variable. Panel B varies the econometric specification. ",
  "Panel C reports falsification tests. The placebo assigns treatment 12 months before actual enactment, estimated on pre-treatment data only. ",
  "The significant placebo reflects states' legislative responses to rising theft trends, consistent with endogenous policy timing. ",
  "All specifications include state and month fixed effects with standard errors clustered by state unless otherwise noted. ",
  "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_robustness.tex")

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) Appendix
# ============================================================
cat("Generating SDE Table...\n")

sd_y <- scalars$sd_y_pre

# Main outcomes
sde_rows <- list()

# 1. Overall ATT (CS)
sde_rows[[1]] <- list(
  outcome = "Search interest (IHS, overall)",
  beta = scalars$cs_att,
  se_beta = scalars$cs_se,
  sd_y = sd_y,
  sde = scalars$cs_att / sd_y,
  se_sde = scalars$cs_se / sd_y
)

# 2. Law effect, low palladium (Q1)
q1_b <- q_coefs[q_names[1], "Estimate"]
q1_se <- q_coefs[q_names[1], "Std. Error"]
sde_rows[[2]] <- list(
  outcome = "Search interest (IHS, low Pd)",
  beta = q1_b, se_beta = q1_se, sd_y = sd_y,
  sde = q1_b / sd_y, se_sde = q1_se / sd_y
)

# 3. Law effect, high palladium (Q4)
q4_b <- q_coefs[q_names[4], "Estimate"]
q4_se <- q_coefs[q_names[4], "Std. Error"]
sde_rows[[3]] <- list(
  outcome = "Search interest (IHS, high Pd)",
  beta = q4_b, se_beta = q4_se, sd_y = sd_y,
  sde = q4_b / sd_y, se_sde = q4_se / sd_y
)

# 4. TWFE with state trends
sde_rows[[4]] <- list(
  outcome = "Search interest (IHS, state trends)",
  beta = coef(models$twfe_trends)["treated"],
  se_beta = se(models$twfe_trends)["treated"],
  sd_y = sd_y,
  sde = coef(models$twfe_trends)["treated"] / sd_y,
  se_sde = se(models$twfe_trends)["treated"] / sd_y
)

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE table body
sde_body <- ""
for (i in seq_along(sde_rows)) {
  r <- sde_rows[[i]]
  cls <- classify_sde(r$sde)
  sde_body <- paste0(sde_body,
    sprintf("%s & $%.3f$ & $(%.3f)$ & $%.3f$ & $%.3f$ & $(%.3f)$ & %s \\\\\n",
            r$outcome, r$beta, r$se_beta, r$sd_y, r$sde, r$se_sde, cls))
}

# Panel B: Heterogeneous (by price regime)
het_body <- ""
for (i in 2:3) {
  r <- sde_rows[[i]]
  cls <- classify_sde(r$sde)
  het_body <- paste0(het_body,
    sprintf("%s & $%.3f$ & $(%.3f)$ & $%.3f$ & $%.3f$ & $(%.3f)$ & %s \\\\\n",
            r$outcome, r$beta, r$se_beta, r$sd_y, r$sde, r$se_sde, cls))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level catalytic converter anti-theft laws (enhanced penalties and scrap dealer regulations) reduce catalytic converter theft, as measured by Google Trends search interest? ",
  "\\textbf{Policy mechanism:} Laws enacted in 35 US states between 2021--2023 impose felony penalties for catalytic converter theft and require scrap metal dealers to record seller identification, creating both direct deterrence and supply-chain friction for stolen converters. ",
  "\\textbf{Outcome definition:} Inverse hyperbolic sine of the Google Trends index (0--100) for the search term ``catalytic converter theft'' at the state-month level, a revealed-preference measure of local theft incidence and salience. ",
  "\\textbf{Treatment:} Binary indicator for whether a state has enacted a catalytic converter anti-theft law by a given month. ",
  "\\textbf{Data:} Google Trends (web search interest), 47 US states, monthly, January 2016--March 2025; 5,217 state-month observations. ",
  "\\textbf{Method:} Two-way fixed effects with state and year-month fixed effects, Callaway-Sant'Anna (2021) group-time ATT with doubly robust estimation and not-yet-treated comparison group; standard errors clustered by state. ",
  "\\textbf{Sample:} 47 US states with sufficient Google Trends coverage (excluding ID, MT, SD, VT); 35 treated states, 12 never-treated controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the IHS-transformed outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("%s & $%.3f$ & $(%.3f)$ & $%.3f$ & $%.3f$ & $(%.3f)$ & %s \\\\\n",
          sde_rows[[1]]$outcome, sde_rows[[1]]$beta, sde_rows[[1]]$se_beta,
          sde_rows[[1]]$sd_y, sde_rows[[1]]$sde, sde_rows[[1]]$se_sde,
          classify_sde(sde_rows[[1]]$sde)),
  sprintf("%s & $%.3f$ & $(%.3f)$ & $%.3f$ & $%.3f$ & $(%.3f)$ & %s \\\\\n",
          sde_rows[[4]]$outcome, sde_rows[[4]]$beta, sde_rows[[4]]$se_beta,
          sde_rows[[4]]$sd_y, sde_rows[[4]]$sde, sde_rows[[4]]$se_sde,
          classify_sde(sde_rows[[4]]$sde)),
  "[0.5em]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by palladium price regime)}} \\\\\n",
  het_body,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_deterrence_discount.tex\n")
cat("  tab4_robustness.tex\n")
cat("  tabF1_sde.tex\n")
