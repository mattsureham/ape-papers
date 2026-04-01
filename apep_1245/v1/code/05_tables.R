# =============================================================================
# 05_tables.R — Generate all LaTeX tables for the paper
# =============================================================================

source("00_packages.R")

# ---------------------------------------------------------------------------
# Load results
# ---------------------------------------------------------------------------

stocks <- fread("../data/stocks_clean.csv")
car_all <- fread("../data/car_events.csv")
chars <- fread("../data/pre_ban_characteristics.csv")
overpricing <- fread("../data/overpricing.csv")
vr_all <- fread("../data/variance_ratios.csv")
stocks[, date := as.Date(date)]

load("../data/main_results.RData")
load("../data/robustness_results.RData")

dir.create("../tables", showWarnings = FALSE, recursive = TRUE)

n_stocks <- uniqueN(stocks$ticker)

# ==========================================================================
# TABLE 1: Summary Statistics
# ==========================================================================

# Panel A: Stock characteristics
panel_a <- chars[, .(
  Variable = c("Price (KRW)", "Daily Volume (millions)", "Annual Volatility",
               "Daily Turnover (KRW billions)", "Amihud Illiquidity (×10⁶)"),
  Mean = c(
    formatC(mean(pre_ban_close, na.rm = TRUE), format = "f", digits = 0, big.mark = ","),
    formatC(mean(pre_ban_avg_volume, na.rm = TRUE) / 1e6, format = "f", digits = 2),
    formatC(mean(pre_ban_volatility, na.rm = TRUE), format = "f", digits = 3),
    formatC(mean(pre_ban_avg_turnover, na.rm = TRUE) / 1e9, format = "f", digits = 2),
    formatC(mean(pre_ban_amihud, na.rm = TRUE) * 1e6, format = "f", digits = 3)
  ),
  SD = c(
    formatC(sd(pre_ban_close, na.rm = TRUE), format = "f", digits = 0, big.mark = ","),
    formatC(sd(pre_ban_avg_volume, na.rm = TRUE) / 1e6, format = "f", digits = 2),
    formatC(sd(pre_ban_volatility, na.rm = TRUE), format = "f", digits = 3),
    formatC(sd(pre_ban_avg_turnover, na.rm = TRUE) / 1e9, format = "f", digits = 2),
    formatC(sd(pre_ban_amihud, na.rm = TRUE) * 1e6, format = "f", digits = 3)
  ),
  P25 = c(
    formatC(quantile(pre_ban_close, 0.25, na.rm = TRUE), format = "f", digits = 0, big.mark = ","),
    formatC(quantile(pre_ban_avg_volume, 0.25, na.rm = TRUE) / 1e6, format = "f", digits = 2),
    formatC(quantile(pre_ban_volatility, 0.25, na.rm = TRUE), format = "f", digits = 3),
    formatC(quantile(pre_ban_avg_turnover, 0.25, na.rm = TRUE) / 1e9, format = "f", digits = 2),
    formatC(quantile(pre_ban_amihud, 0.25, na.rm = TRUE) * 1e6, format = "f", digits = 3)
  ),
  Median = c(
    formatC(median(pre_ban_close, na.rm = TRUE), format = "f", digits = 0, big.mark = ","),
    formatC(median(pre_ban_avg_volume, na.rm = TRUE) / 1e6, format = "f", digits = 2),
    formatC(median(pre_ban_volatility, na.rm = TRUE), format = "f", digits = 3),
    formatC(median(pre_ban_avg_turnover, na.rm = TRUE) / 1e9, format = "f", digits = 2),
    formatC(median(pre_ban_amihud, na.rm = TRUE) * 1e6, format = "f", digits = 3)
  ),
  P75 = c(
    formatC(quantile(pre_ban_close, 0.75, na.rm = TRUE), format = "f", digits = 0, big.mark = ","),
    formatC(quantile(pre_ban_avg_volume, 0.75, na.rm = TRUE) / 1e6, format = "f", digits = 2),
    formatC(quantile(pre_ban_volatility, 0.75, na.rm = TRUE), format = "f", digits = 3),
    formatC(quantile(pre_ban_avg_turnover, 0.75, na.rm = TRUE) / 1e9, format = "f", digits = 2),
    formatC(quantile(pre_ban_amihud, 0.75, na.rm = TRUE) * 1e6, format = "f", digits = 3)
  )
)]

# Panel B: Returns by period
panel_b_data <- stocks[, .(
  mean_ret = mean(ret, na.rm = TRUE) * 100,
  sd_ret = sd(ret, na.rm = TRUE) * 100,
  mean_ar = mean(ar, na.rm = TRUE) * 100,
  n_days = uniqueN(date)
), by = period]

# Write Table 1
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\small\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & Mean & SD & P25 & Median & P75 \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Panel A: Pre-Ban Stock Characteristics (", n_stocks, " stocks)}} \\\\\n", sep = "")
for (i in 1:nrow(panel_a)) {
  cat(panel_a$Variable[i], " & ", panel_a$Mean[i], " & ", panel_a$SD[i], " & ",
    panel_a$P25[i], " & ", panel_a$Median[i], " & ", panel_a$P75[i], " \\\\\n", sep = "")
}
cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Panel B: Daily Returns by Period (\\%)}} \\\\\n")
cat(" & Mean Return & SD Return & Mean Abn.~Return & Trading Days & \\\\\n")
cat("\\hline\n")
for (p in c("pre_ban", "during_ban", "post_ban")) {
  row <- panel_b_data[period == p]
  plabel <- switch(p, pre_ban = "Pre-ban (Jan 2022--Nov 2023)", during_ban = "During ban (Nov 2023--Mar 2025)", post_ban = "Post-ban (Apr 2025--)")
  cat(plabel, " & ", formatC(row$mean_ret, format = "f", digits = 3), " & ",
    formatC(row$sd_ret, format = "f", digits = 3), " & ",
    formatC(row$mean_ar, format = "f", digits = 3), " & ",
    row$n_days, " & \\\\\n", sep = "")
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Panel A reports pre-ban (60 trading days before November 6, 2023) stock characteristics for ", n_stocks, " stocks traded on KOSPI and KOSDAQ. Price in Korean won. Daily volume in millions of shares. Annual volatility is annualized standard deviation of daily returns. Amihud illiquidity is $|r_t|/\\text{Volume}_t$ scaled by $10^6$. Panel B reports average daily returns and abnormal returns (market-adjusted) by period.\n", sep = "")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 1 written.\n")

# ==========================================================================
# TABLE 2: Event Study — CARs around Ban Imposition and Lift
# ==========================================================================

# Prepare CAR summary for each event and window
car_summary <- car_all[, .(
  mean_car = mean(car, na.rm = TRUE),
  se = sd(car, na.rm = TRUE) / sqrt(.N),
  pct_pos = mean(car > 0, na.rm = TRUE),
  n = .N
), by = .(event, window)]

# Merge with characteristics for cross-sectional tests
car_ban_1_1 <- car_all[event == "ban_imposition" & window == "ban_1_1"]
car_lift_1_1 <- car_all[event == "ban_lift" & window == "lift_1_1"]

sink("../tables/tab2_event_study.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Cumulative Abnormal Returns Around Ban Events}\n")
cat("\\label{tab:event_study}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & Mean CAR (\\%) & SE & \\% Positive & $N$ \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Ban Imposition (November 6, 2023)}} \\\\\n")
for (w in c("ban_0_0", "ban_1_1", "ban_1_5", "ban_1_10")) {
  row <- car_summary[event == "ban_imposition" & window == w]
  wlabel <- switch(w,
    ban_0_0 = "Day 0",
    ban_1_1 = "[$-1$, $+1$]",
    ban_1_5 = "[$-1$, $+5$]",
    ban_1_10 = "[$-1$, $+10$]"
  )
  stars <- ifelse(abs(row$mean_car / row$se) > 2.58, "***",
    ifelse(abs(row$mean_car / row$se) > 1.96, "**",
      ifelse(abs(row$mean_car / row$se) > 1.65, "*", "")))
  cat(wlabel, " & ", formatC(row$mean_car * 100, format = "f", digits = 2), stars,
    " & (", formatC(row$se * 100, format = "f", digits = 2), ")",
    " & ", formatC(row$pct_pos * 100, format = "f", digits = 1),
    " & ", row$n, " \\\\\n", sep = "")
}
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Ban Lift (March 31, 2025)}} \\\\\n")
for (w in c("lift_0_0", "lift_1_1", "lift_1_5", "lift_1_10")) {
  row <- car_summary[event == "ban_lift" & window == w]
  wlabel <- switch(w,
    lift_0_0 = "Day 0",
    lift_1_1 = "[$-1$, $+1$]",
    lift_1_5 = "[$-1$, $+5$]",
    lift_1_10 = "[$-1$, $+10$]"
  )
  stars <- ifelse(abs(row$mean_car / row$se) > 2.58, "***",
    ifelse(abs(row$mean_car / row$se) > 1.96, "**",
      ifelse(abs(row$mean_car / row$se) > 1.65, "*", "")))
  cat(wlabel, " & ", formatC(row$mean_car * 100, format = "f", digits = 2), stars,
    " & (", formatC(row$se * 100, format = "f", digits = 2), ")",
    " & ", formatC(row$pct_pos * 100, format = "f", digits = 1),
    " & ", row$n, " \\\\\n", sep = "")
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Cumulative abnormal returns (CARs) computed as the sum of market-adjusted daily returns over each window. Market return is the KOSPI Composite Index. \\% Positive is the fraction of stocks with positive CARs. Standard errors in parentheses are cross-sectional (across ", n_stocks, " stocks). *, **, *** denote significance at the 10\\%, 5\\%, and 1\\% levels.\n", sep = "")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 2 written.\n")

# ==========================================================================
# TABLE 3: Cross-Sectional Determinants of CARs
# ==========================================================================

sink("../tables/tab3_cross_section.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Cross-Sectional Determinants of Cumulative Abnormal Returns}\n")
cat("\\label{tab:cross_section}\n")
cat("\\small\n")

# Use etable to generate the body
tab3_tex <- capture.output(etable(
  reg_ban_1, reg_ban_2, reg_ban_3,
  reg_lift_1, reg_lift_2, reg_lift_3,
  tex = TRUE,
  headers = c("(1)", "(2)", "(3)", "(4)", "(5)", "(6)"),
  depvar = FALSE,
  se.below = TRUE,
  fitstat = c("n", "r2"),
  dict = c(
    pre_ban_volatility = "Pre-Ban Volatility",
    "log(pre_ban_avg_turnover + 1)" = "Log Turnover",
    "log(pre_ban_close)" = "Log Price",
    pre_ban_amihud = "Amihud Illiquidity"
  )
))

# Write multicolumn header manually
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{3}{c}{Ban Imposition CAR[$-1$,$+1$]} & \\multicolumn{3}{c}{Ban Lift CAR[$-1$,$+1$]} \\\\\n")
cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n")
cat(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat("\\hline\n")

# Extract coefficient rows from etable
in_body <- FALSE
for (line in tab3_tex) {
  if (grepl("Pre-Ban Volatility|Log Turnover|Log Price|Amihud|Exchange FE|Observations|Adj\\. R", line)) {
    cat(line, "\n")
  } else if (grepl("^\\s*\\(", line) && in_body) {
    cat(line, "\n")
  }
  if (grepl("Pre-Ban Volatility", line)) in_body <- TRUE
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} OLS regressions of cumulative abnormal returns (market-adjusted) on pre-ban stock characteristics. Columns (1)--(3) use the ban imposition event (November 6, 2023); columns (4)--(6) use the ban lift (March 31, 2025). Pre-ban volatility is annualized standard deviation of daily returns over the 60 trading days before the ban. Amihud illiquidity is $|r_t|/\\text{Volume}_t$. Columns (3) and (6) include exchange (KOSPI/KOSDAQ) fixed effects. Heteroskedasticity-robust standard errors in parentheses. *, **, *** denote significance at 10\\%, 5\\%, 1\\%.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 3 written.\n")

# ==========================================================================
# TABLE 4: Price Efficiency — Variance Ratios
# ==========================================================================

# Summary VR by period
vr_summary <- vr_all[, .(
  mean_vr = mean(vr_5, na.rm = TRUE),
  sd_vr = sd(vr_5, na.rm = TRUE),
  mean_dev = mean(abs(vr_5 - 1), na.rm = TRUE),
  n = .N
), by = period]

sink("../tables/tab4_efficiency.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Price Efficiency: Variance Ratios Across Periods}\n")
cat("\\label{tab:efficiency}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & Mean VR(5) & SD & $|$VR(5)$-1|$ & $N$ \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Variance Ratio Summary}} \\\\\n")
for (p in c(0, 1, 2)) {
  row <- vr_summary[period == p]
  plabel <- switch(as.character(p), "0" = "Pre-ban", "1" = "During ban", "2" = "Post-ban")
  cat(plabel, " & ", formatC(row$mean_vr, format = "f", digits = 3),
    " & ", formatC(row$sd_vr, format = "f", digits = 3),
    " & ", formatC(row$mean_dev, format = "f", digits = 3),
    " & ", row$n, " \\\\\n", sep = "")
}
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Regression --- $|$VR(5)$-1|$ on Period Indicators}} \\\\\n")
cat(" & (1) & (2) & (3) & \\\\\n")
cat("\\hline\n")

# Extract regression coefficients
for (reg_name in c("reg_vr_1", "reg_vr_2", "reg_vr_3")) {
  reg <- get(reg_name)
  coefs <- coef(reg)
  ses <- sqrt(diag(vcov(reg)))
}

# Use etable for Panel B
vr_tex <- capture.output(etable(reg_vr_1, reg_vr_2, reg_vr_3,
  tex = TRUE, se.below = TRUE,
  fitstat = c("n", "r2"),
  dict = c(
    during_ban = "During Ban",
    post_ban = "Post-Ban",
    pre_ban_volatility = "Pre-Ban Volatility",
    "during_ban:pre_ban_volatility" = "During Ban $\\times$ Volatility",
    "post_ban:pre_ban_volatility" = "Post-Ban $\\times$ Volatility"
  )
))

for (line in vr_tex) {
  if (grepl("During|Post-Ban|Volatility|Stock FE|Observations|Adj\\. R|\\(0\\.", line)) {
    cat(line, "\n")
  }
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Panel A reports 5-day variance ratios VR(5) $= \\text{Var}(r_{5d}) / (5 \\times \\text{Var}(r_{1d}))$ by period. Under the random walk hypothesis, VR(5) $= 1$; values above 1 indicate positive autocorrelation (momentum), values below 1 indicate mean reversion. $|$VR(5)$-1|$ measures deviation from efficiency. Panel B regresses $|$VR(5)$-1|$ on period indicators; column (2) interacts with pre-ban volatility; column (3) adds stock fixed effects. Standard errors in parentheses. *, **, *** denote significance at 10\\%, 5\\%, 1\\%.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 4 written.\n")

# ==========================================================================
# TABLE 5: Robustness — Placebo Tests and Alternative Specifications
# ==========================================================================

# Also need the placebo regression
car_ban_1_1 <- car_all[event == "ban_imposition" & window == "ban_1_1"]
car_lift_1_1 <- car_all[event == "ban_lift" & window == "lift_1_1"]

sink("../tables/tab5_robustness.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\small\n")

rob_tex <- capture.output(etable(
  reg_ban_3, reg_ban_w5, reg_ban_w10,
  reg_placebo, reg_amihud_ban,
  tex = TRUE,
  se.below = TRUE,
  fitstat = c("n", "r2"),
  headers = c("Baseline", "[-1,+5]", "[-1,+10]", "Placebo", "Amihud"),
  dict = c(
    pre_ban_volatility = "Pre-Ban Volatility",
    "log(pre_ban_avg_turnover + 1)" = "Log Turnover",
    "log(pre_ban_close)" = "Log Price",
    pre_ban_amihud = "Amihud Illiquidity"
  )
))

cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & Baseline & \\multicolumn{2}{c}{Alt.~Windows} & Placebo & Alt.~Intensity \\\\\n")
cat("\\cmidrule(lr){3-4}\n")
cat(" & [$-1$,$+1$] & [$-1$,$+5$] & [$-1$,$+10$] & Nov 2022 & Amihud \\\\\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat("\\hline\n")

for (line in rob_tex) {
  if (grepl("Pre-Ban Volatility|Log Turnover|Log Price|Amihud|Exchange FE|Observations|Adj\\. R|^\\s+\\(", line)) {
    cat(line, "\n")
  }
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Column (1) reproduces the baseline specification from Table \\ref{tab:cross_section} column (3). Columns (2)--(3) use wider event windows. Column (4) runs a placebo test using November 7, 2022 as a false ban date; under the null of no effect, pre-ban volatility should not predict CARs. Column (5) uses Amihud illiquidity instead of volatility as the treatment intensity measure. All specifications include exchange fixed effects and heteroskedasticity-robust standard errors. *, **, *** denote significance at 10\\%, 5\\%, 1\\%.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 5 written.\n")

# ==========================================================================
# SDE TABLE (Appendix)
# ==========================================================================

# Compute SDEs from the main regressions
# Primary outcome: CAR[-1,+1] around ban imposition
# Treatment: pre-ban volatility (continuous)

car_ban_1_1 <- car_all[event == "ban_imposition" & window == "ban_1_1"]
car_lift_1_1 <- car_all[event == "ban_lift" & window == "lift_1_1"]

# SD of outcomes
sd_car_ban <- sd(car_ban_1_1$car, na.rm = TRUE)
sd_car_lift <- sd(car_lift_1_1$car, na.rm = TRUE)

# SD of treatment (continuous)
sd_vol <- sd(car_ban_1_1$pre_ban_volatility, na.rm = TRUE)

# Coefficients from baseline spec (columns 3 and 6)
beta_ban <- coef(reg_ban_3)["pre_ban_volatility"]
se_ban <- sqrt(vcov(reg_ban_3)["pre_ban_volatility", "pre_ban_volatility"])
beta_lift <- coef(reg_lift_3)["pre_ban_volatility"]
se_lift <- sqrt(vcov(reg_lift_3)["pre_ban_volatility", "pre_ban_volatility"])

# Overpricing: cum_ar_ban on volatility
sd_cum_ar_ban <- sd(overpricing$cum_ar_ban, na.rm = TRUE)
sd_cum_ar_post10 <- sd(overpricing$cum_ar_post10, na.rm = TRUE)
beta_over_ban <- coef(reg_symm_ban)["pre_ban_volatility"]
se_over_ban <- sqrt(vcov(reg_symm_ban)["pre_ban_volatility", "pre_ban_volatility"])
beta_over_post <- coef(reg_symm_post)["pre_ban_volatility"]
se_over_post <- sqrt(vcov(reg_symm_post)["pre_ban_volatility", "pre_ban_volatility"])

# VR deviation
sd_vr_dev <- sd(vr_all$vr_deviation[vr_all$during_ban == 1], na.rm = TRUE)
beta_vr <- coef(reg_vr_2)["during_ban:pre_ban_volatility"]
se_vr <- sqrt(vcov(reg_vr_2)["during_ban:pre_ban_volatility", "during_ban:pre_ban_volatility"])

# Compute SDEs: SDE = beta * SD(X) / SD(Y) for continuous treatment
sde_ban <- beta_ban * sd_vol / sd_car_ban
se_sde_ban <- se_ban * sd_vol / sd_car_ban
sde_lift <- beta_lift * sd_vol / sd_car_lift
se_sde_lift <- se_lift * sd_vol / sd_car_lift
sde_over_ban <- beta_over_ban * sd_vol / sd_cum_ar_ban
se_sde_over_ban <- se_over_ban * sd_vol / sd_cum_ar_ban
sde_over_post <- beta_over_post * sd_vol / sd_cum_ar_post10
se_sde_over_post <- se_over_post * sd_vol / sd_cum_ar_post10
sde_vr <- beta_vr * sd_vol / sd_vr_dev
se_sde_vr <- se_vr * sd_vol / sd_vr_dev

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("--")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Build SDE rows
sde_rows <- data.frame(
  Outcome = c(
    "CAR[$-1$,$+1$]: Ban imposition",
    "CAR[$-1$,$+1$]: Ban lift",
    "Cum.~abnormal return: Ban period",
    "Cum.~abnormal return: Post-lift (10 days)",
    "$|$VR(5)$-1|$: During ban"
  ),
  Beta = c(beta_ban, beta_lift, beta_over_ban, beta_over_post, beta_vr),
  SE = c(se_ban, se_lift, se_over_ban, se_over_post, se_vr),
  SD_Y = c(sd_car_ban, sd_car_lift, sd_cum_ar_ban, sd_cum_ar_post10, sd_vr_dev),
  SDE = c(sde_ban, sde_lift, sde_over_ban, sde_over_post, sde_vr),
  SE_SDE = c(se_sde_ban, se_sde_lift, se_sde_over_ban, se_sde_over_post, se_sde_vr),
  stringsAsFactors = FALSE
)
sde_rows$Classification <- sapply(sde_rows$SDE, classify_sde)

# Heterogeneous SDEs: KOSPI vs KOSDAQ
car_ban_kospi <- car_all[event == "ban_imposition" & window == "ban_1_1" & exchange == "KOSPI"]
car_ban_kosdaq <- car_all[event == "ban_imposition" & window == "ban_1_1" & exchange == "KOSDAQ"]

reg_kospi_sde <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) + log(pre_ban_close), data = car_ban_kospi)
reg_kosdaq_sde <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) + log(pre_ban_close), data = car_ban_kosdaq)

sd_car_kospi <- sd(car_ban_kospi$car, na.rm = TRUE)
sd_car_kosdaq <- sd(car_ban_kosdaq$car, na.rm = TRUE)
sd_vol_kospi <- sd(car_ban_kospi$pre_ban_volatility, na.rm = TRUE)
sd_vol_kosdaq <- sd(car_ban_kosdaq$pre_ban_volatility, na.rm = TRUE)

beta_kospi <- coef(reg_kospi_sde)["pre_ban_volatility"]
se_kospi <- sqrt(vcov(reg_kospi_sde)["pre_ban_volatility", "pre_ban_volatility"])
beta_kosdaq <- coef(reg_kosdaq_sde)["pre_ban_volatility"]
se_kosdaq <- sqrt(vcov(reg_kosdaq_sde)["pre_ban_volatility", "pre_ban_volatility"])

sde_kospi <- beta_kospi * sd_vol_kospi / sd_car_kospi
se_sde_kospi <- se_kospi * sd_vol_kospi / sd_car_kospi
sde_kosdaq <- beta_kosdaq * sd_vol_kosdaq / sd_car_kosdaq
se_sde_kosdaq <- se_kosdaq * sd_vol_kosdaq / sd_car_kosdaq

het_rows <- data.frame(
  Outcome = c(
    "CAR[$-1$,$+1$]: KOSPI stocks",
    "CAR[$-1$,$+1$]: KOSDAQ stocks"
  ),
  Beta = c(beta_kospi, beta_kosdaq),
  SE = c(se_kospi, se_kosdaq),
  SD_Y = c(sd_car_kospi, sd_car_kosdaq),
  SDE = c(sde_kospi, sde_kosdaq),
  SE_SDE = c(se_sde_kospi, se_sde_kosdaq),
  stringsAsFactors = FALSE
)
het_rows$Classification <- sapply(het_rows$SDE, classify_sde)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\\\item \\\\textit{Notes:} ",
  "\\\\textbf{Country:} South Korea. ",
  "\\\\textbf{Research question:} Does a complete short-selling ban protect retail investors or induce overpricing that harms them when the ban lifts? ",
  "\\\\textbf{Policy mechanism:} The Financial Services Commission imposed a total ban on short selling of all KOSPI, KOSDAQ, and KONEX securities from November 6, 2023 to March 31, 2025, removing negative-information channels from the market. ",
  "\\\\textbf{Outcome definition:} Cumulative abnormal returns (market-adjusted) around ban imposition and lift events, cumulative abnormal returns over the full ban and post-lift periods, and variance ratio deviation from random walk. ",
  "\\\\textbf{Treatment:} Continuous; pre-ban annualized volatility (proxy for short-selling demand), measured over the 60 trading days preceding the ban. ",
  "\\\\textbf{Data:} Yahoo Finance daily OHLCV for ", n_stocks, " KOSPI and KOSDAQ stocks, January 2022 to March 2026, yielding approximately ",
  formatC(nrow(stocks), format = "d", big.mark = ","), " stock-day observations. ",
  "\\\\textbf{Method:} Cross-sectional event study with OLS; market model benchmark using KOSPI Composite Index; heteroskedasticity-robust standard errors. ",
  "\\\\textbf{Sample:} Major KOSPI and KOSDAQ stocks with at least 60 pre-ban trading days and continuous trading throughout the sample period. ",
  "SDE $= \\\\hat{\\\\beta} \\\\times \\\\text{SD}(X) / \\\\text{SD}(Y)$ where SD($X$) is the cross-sectional standard deviation of pre-ban volatility and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (i in 1:nrow(sde_rows)) {
  cat(sde_rows$Outcome[i], " & ",
    formatC(sde_rows$Beta[i], format = "f", digits = 4), " & ",
    formatC(sde_rows$SE[i], format = "f", digits = 4), " & ",
    formatC(sde_rows$SD_Y[i], format = "f", digits = 4), " & ",
    formatC(sde_rows$SDE[i], format = "f", digits = 3), " & ",
    formatC(sde_rows$SE_SDE[i], format = "f", digits = 3), " & ",
    sde_rows$Classification[i], " \\\\\n", sep = "")
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (KOSPI vs KOSDAQ)}} \\\\\n")
for (i in 1:nrow(het_rows)) {
  cat(het_rows$Outcome[i], " & ",
    formatC(het_rows$Beta[i], format = "f", digits = 4), " & ",
    formatC(het_rows$SE[i], format = "f", digits = 4), " & ",
    formatC(het_rows$SD_Y[i], format = "f", digits = 4), " & ",
    formatC(het_rows$SDE[i], format = "f", digits = 3), " & ",
    formatC(het_rows$SE_SDE[i], format = "f", digits = 3), " & ",
    het_rows$Classification[i], " \\\\\n", sep = "")
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("SDE table written.\n")
cat("All tables complete.\n")
