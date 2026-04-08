# 05_tables.R — Generate all tables including SDE
# BVG Conversion Rate and Capital Withdrawal Choice

source("00_packages.R")

cat("=== Generating Tables ===\n")

# ---------------------------------------------------------------
# Load data and results
# ---------------------------------------------------------------
panel_agg <- readRDS("../data/panel_aggregate.rds")
gender_panel <- readRDS("../data/panel_gender.rds")
risk_panel <- readRDS("../data/panel_risk_type.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("Table 1: Summary statistics...\n")

summ_rows <- function(var, label, data = panel_agg) {
  x <- data[[var]]
  x <- x[!is.na(x)]
  data.frame(
    Variable = label,
    N = length(x),
    Mean = round(mean(x), 4),
    SD = round(sd(x), 4),
    Min = round(min(x), 4),
    Max = round(max(x), 4)
  )
}

tab1 <- rbind(
  summ_rows("conversion_rate", "BVG conversion rate (\\%)"),
  summ_rows("rate_cut", "Cumulative rate cut (pp)"),
  summ_rows("capital_share", "Capital withdrawal share"),
  summ_rows("capital_amount_share", "Capital amount share"),
  data.frame(Variable = "Capital beneficiaries",
             N = nrow(panel_agg),
             Mean = round(mean(panel_agg$capital_beneficiaries)),
             SD = round(sd(panel_agg$capital_beneficiaries)),
             Min = min(panel_agg$capital_beneficiaries),
             Max = max(panel_agg$capital_beneficiaries)),
  data.frame(Variable = "Annuity beneficiaries",
             N = nrow(panel_agg),
             Mean = round(mean(panel_agg$annuity_beneficiaries)),
             SD = round(sd(panel_agg$annuity_beneficiaries)),
             Min = min(panel_agg$annuity_beneficiaries),
             Max = max(panel_agg$annuity_beneficiaries)),
  data.frame(Variable = "Active insured (thousands)",
             N = nrow(panel_agg),
             Mean = round(mean(panel_agg$active_insured / 1000)),
             SD = round(sd(panel_agg$active_insured / 1000)),
             Min = round(min(panel_agg$active_insured / 1000)),
             Max = round(max(panel_agg$active_insured / 1000)))
)

# LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Swiss Occupational Pension System, 2004--2024}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  "Variable & N & Mean & SD & Min & Max \\\\\n",
  "\\midrule\n",
  paste0(apply(tab1, 1, function(r) {
    paste0(r[1], " & ", r[2], " & ",
           format(as.numeric(r[3]), big.mark = ","), " & ",
           format(as.numeric(r[4]), big.mark = ","), " & ",
           format(as.numeric(r[5]), big.mark = ","), " & ",
           format(as.numeric(r[6]), big.mark = ","), " \\\\")
  }), collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Data from the Swiss Federal Statistical Office (BFS) Pensionskassenstatistik. ",
  "Capital withdrawal share is the number of capital payment beneficiaries divided by total beneficiaries ",
  "(capital + annuity). The BVG conversion rate is the federal minimum rate translating mandatory ",
  "occupational pension capital into an annual annuity.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ---------------------------------------------------------------
# Table 2: Main Results
# ---------------------------------------------------------------
cat("Table 2: Main results...\n")

extract_row <- function(model, label, outcome_label = "") {
  beta <- coef(model)["rate_cut"]
  se <- sqrt(vcov(model)["rate_cut", "rate_cut"])
  n <- nobs(model)
  r2 <- r2(model, type = "r2")
  data.frame(
    Specification = label,
    Outcome = outcome_label,
    Estimate = round(beta, 5),
    SE = round(se, 5),
    N = n,
    R2 = round(r2, 3)
  )
}

tab2_rows <- rbind(
  extract_row(results$m1, "(1) Baseline", "Capital share"),
  extract_row(results$m1_trend, "(2) + Linear trend", "Capital share"),
  extract_row(results$m3_men, "(3) Men only", "Capital share (flow)"),
  extract_row(results$m3_women, "(4) Women only", "Capital share (flow)"),
  extract_row(results$m4, "(5) Intensive margin", "Avg. capital (CHF)"),
  extract_row(results$m5, "(6) Placebo: disability", "Disab. capital share")
)

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of BVG Conversion Rate Cut on Capital Withdrawal}\n",
  "\\label{tab:main_results}\n",
  "\\begin{tabular}{llrrrr}\n",
  "\\toprule\n",
  " & Outcome & $\\hat{\\beta}$ & SE & N & $R^2$ \\\\\n",
  "\\midrule\n",
  paste0(apply(tab2_rows, 1, function(r) {
    paste0(r[1], " & ", r[2], " & ", r[3], " & (", r[4], ") & ", r[5], " & ", r[6], " \\\\")
  }), collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on the cumulative conversion rate cut (in percentage points from 7.2\\%). ",
  "Heteroskedasticity-robust standard errors in parentheses. ",
  "Specifications (1)--(2) use the aggregate capital withdrawal share (beneficiary count). ",
  "Specifications (3)--(4) use flow-based capital share at retirement by gender. ",
  "Specification (5) uses the average capital payment per beneficiary in CHF. ",
  "Specification (6) is a placebo test using the disability pension capital share, which should be unaffected by the conversion rate.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "../tables/tab2_main_results.tex")

# ---------------------------------------------------------------
# Table 3: Robustness
# ---------------------------------------------------------------
cat("Table 3: Robustness checks...\n")

rob_rows <- list()

# Structural breaks
brk <- rob_results$r2_breaks
brk_coefs <- coef(brk)
brk_ses <- sqrt(diag(vcov(brk)))

rob_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Structural Break Estimates}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lrr}\n",
  "\\toprule\n",
  "Reform Step & Estimate & SE \\\\\n",
  "\\midrule\n",
  "Post-2005 (7.1\\%) & ", round(brk_coefs["post_2005"], 5), " & (", round(brk_ses["post_2005"], 5), ") \\\\\n",
  "Post-2007 (7.0\\%) & ", round(brk_coefs["post_2007"], 5), " & (", round(brk_ses["post_2007"], 5), ") \\\\\n",
  "Post-2010 (6.9\\%) & ", round(brk_coefs["post_2010"], 5), " & (", round(brk_ses["post_2010"], 5), ") \\\\\n",
  "Post-2014 (6.8\\%) & ", round(brk_coefs["post_2014"], 5), " & (", round(brk_ses["post_2014"], 5), ") \\\\\n",
  "\\midrule\n",
  "N & \\multicolumn{2}{c}{", nobs(brk), "} \\\\\n",
  "$R^2$ & \\multicolumn{2}{c}{", round(r2(brk, type = "r2"), 3), "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Estimates from a single regression of capital withdrawal share on four reform step dummies. ",
  "Each coefficient represents the cumulative change in capital share relative to the pre-reform period (2004). ",
  "Heteroskedasticity-robust standard errors in parentheses.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(rob_tex, "../tables/tab3_robustness.tex")

# ---------------------------------------------------------------
# Table 4: Fund-type heterogeneity
# ---------------------------------------------------------------
cat("Table 4: Fund-type heterogeneity...\n")

fund_types <- c("Autonomous", "Semi-autonomous", "Collective")
fund_rows <- lapply(fund_types, function(a) {
  mi <- feols(capital_share ~ rate_cut,
              data = risk_panel[autonomy == a & !is.na(capital_share)],
              vcov = "hetero")
  data.frame(
    Fund = a,
    Estimate = round(coef(mi)["rate_cut"], 5),
    SE = round(sqrt(vcov(mi)["rate_cut", "rate_cut"]), 5),
    N = nobs(mi),
    R2 = round(r2(mi, type = "r2"), 3)
  )
})
fund_tab <- do.call(rbind, fund_rows)

fund_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Heterogeneity by Pension Fund Autonomy Type}\n",
  "\\label{tab:fund_type}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\toprule\n",
  "Fund Type & $\\hat{\\beta}$ & SE & N & $R^2$ \\\\\n",
  "\\midrule\n",
  paste0(apply(fund_tab, 1, function(r) {
    paste0(r[1], " & ", r[2], " & (", r[3], ") & ", r[4], " & ", r[5], " \\\\")
  }), collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports a separate regression of capital share on the cumulative rate cut, ",
  "estimated within the indicated pension fund type. Autonomous funds set their own conversion rates above the BVG minimum; ",
  "collective funds apply rates set by their insurance company, typically closer to the BVG minimum. ",
  "Heteroskedasticity-robust standard errors in parentheses.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(fund_tex, "../tables/tab4_fund_heterogeneity.tex")

# ---------------------------------------------------------------
# SDE Table (MANDATORY — Appendix F1)
# ---------------------------------------------------------------
cat("Generating SDE table...\n")

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (is.na(sde)) return("NA")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Main outcomes with SDE
sd_x <- results$sd_rate_cut

# 1. Capital share (main)
b1 <- coef(results$m1)["rate_cut"]
se1 <- sqrt(vcov(results$m1)["rate_cut", "rate_cut"])
sd_y1 <- results$sd_capital_share_pre
sde1 <- b1 * sd_x / sd_y1
se_sde1 <- se1 * sd_x / sd_y1

# 2. Capital amount share
b2 <- coef(rob_results$r4_amount_share)["rate_cut"]
se2 <- sqrt(vcov(rob_results$r4_amount_share)["rate_cut", "rate_cut"])
sd_y2 <- sd(panel_agg[year <= 2004, capital_amount_share], na.rm = TRUE)
if (is.na(sd_y2) || sd_y2 == 0) sd_y2 <- sd(panel_agg$capital_amount_share)
sde2 <- b2 * sd_x / sd_y2
se_sde2 <- se2 * sd_x / sd_y2

# 3. Average capital per beneficiary
b3 <- coef(results$m4)["rate_cut"]
se3 <- sqrt(vcov(results$m4)["rate_cut", "rate_cut"])
sd_y3 <- results$sd_cap_pre
sde3 <- b3 * sd_x / sd_y3
se_sde3 <- se3 * sd_x / sd_y3

# 4. Disability capital share (placebo)
b4 <- coef(results$m5)["rate_cut"]
se4 <- sqrt(vcov(results$m5)["rate_cut", "rate_cut"])
sd_y4 <- results$sd_disab_pre
if (!is.na(sd_y4) && sd_y4 > 0) {
  sde4 <- b4 * sd_x / sd_y4
  se_sde4 <- se4 * sd_x / sd_y4
} else {
  sde4 <- NA; se_sde4 <- NA
}

# Panel A: Pooled
panel_a <- data.frame(
  Outcome = c("Capital withdrawal share",
              "Capital amount share",
              "Avg. capital per beneficiary (CHF)",
              "Disability capital share (placebo)"),
  Beta = c(b1, b2, b3, b4),
  SE = c(se1, se2, se3, se4),
  SD_Y = c(sd_y1, sd_y2, sd_y3, sd_y4),
  SDE = c(sde1, sde2, sde3, sde4),
  SE_SDE = c(se_sde1, se_sde2, se_sde3, se_sde4),
  Classification = sapply(c(sde1, sde2, sde3, sde4), classify_sde)
)

# Panel B: Heterogeneous (men vs women, flow-based capital share)
gp <- gender_panel[year > 2004]
gp_men <- gp[!is.na(capital_share_flow_men)]
gp_women <- gp[!is.na(capital_share_flow_women)]

m_men <- feols(capital_share_flow_men ~ rate_cut, data = gp_men, vcov = "hetero")
m_women <- feols(capital_share_flow_women ~ rate_cut, data = gp_women, vcov = "hetero")

b_men <- coef(m_men)["rate_cut"]
se_men <- sqrt(vcov(m_men)["rate_cut", "rate_cut"])
sd_y_men <- sd(gp_men[year <= 2006, capital_share_flow_men], na.rm = TRUE)
if (is.na(sd_y_men) || sd_y_men == 0) sd_y_men <- sd(gp_men$capital_share_flow_men)
sde_men <- b_men * sd_x / sd_y_men
se_sde_men <- se_men * sd_x / sd_y_men

b_women <- coef(m_women)["rate_cut"]
se_women <- sqrt(vcov(m_women)["rate_cut", "rate_cut"])
sd_y_women <- sd(gp_women[year <= 2006, capital_share_flow_women], na.rm = TRUE)
if (is.na(sd_y_women) || sd_y_women == 0) sd_y_women <- sd(gp_women$capital_share_flow_women)
sde_women <- b_women * sd_x / sd_y_women
se_sde_women <- se_women * sd_x / sd_y_women

panel_b <- data.frame(
  Outcome = c("Capital share (flow): Men",
              "Capital share (flow): Women"),
  Beta = c(b_men, b_women),
  SE = c(se_men, se_women),
  SD_Y = c(sd_y_men, sd_y_women),
  SDE = c(sde_men, sde_women),
  SE_SDE = c(se_sde_men, se_sde_women),
  Classification = sapply(c(sde_men, sde_women), classify_sde)
)

# Format numbers for LaTeX
fmt <- function(x, d = 4) {
  ifelse(is.na(x), "---", formatC(round(x, d), format = "f", digits = d))
}

# Build LaTeX SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does a reduction in the mandatory occupational pension conversion rate shift retirees from annuity payouts toward lump-sum capital withdrawals? ",
  "\\textbf{Policy mechanism:} The BVG reform reduced the federal minimum conversion rate that translates mandatory Pillar~2 pension capital into annual annuity income, making annuities mechanically less generous relative to lump-sum alternatives. ",
  "\\textbf{Outcome definition:} Capital withdrawal share is the number of beneficiaries receiving a lump-sum capital payment at retirement divided by total retirement beneficiaries (capital plus new annuity). ",
  "\\textbf{Treatment:} Continuous; cumulative percentage point reduction in the BVG conversion rate from the 7.2\\% baseline. ",
  "\\textbf{Data:} BFS Pensionskassenstatistik (tables px-x-1303030000\\_101, \\_141, \\_142), 2004--2024, annual aggregate observations, $N = 21$ years. ",
  "\\textbf{Method:} OLS with heteroskedasticity-robust standard errors; event-study step dummies; gender-specific and fund-type heterogeneity. ",
  "\\textbf{Sample:} All registered Swiss occupational pension funds reporting to the BFS; disability pensions serve as placebo. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-reform ",
  "standard deviation and SD($X$) is the standard deviation of the treatment variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lrrrrrrr}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste0(apply(panel_a, 1, function(r) {
    paste0(r[1], " & ", fmt(as.numeric(r[2])), " & ", fmt(as.numeric(r[3])),
           " & ", fmt(as.numeric(r[4])), " & ", fmt(as.numeric(r[5])),
           " & ", fmt(as.numeric(r[6])), " & ", r[7], " \\\\")
  }), collapse = "\n"),
  "\n\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by gender)}} \\\\\n",
  paste0(apply(panel_b, 1, function(r) {
    paste0(r[1], " & ", fmt(as.numeric(r[2])), " & ", fmt(as.numeric(r[3])),
           " & ", fmt(as.numeric(r[4])), " & ", fmt(as.numeric(r[5])),
           " & ", fmt(as.numeric(r[6])), " & ", r[7], " \\\\")
  }), collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables saved ===\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main_results.tex\n")
cat("  tables/tab3_robustness.tex\n")
cat("  tables/tab4_fund_heterogeneity.tex\n")
cat("  tables/tabF1_sde.tex\n")
