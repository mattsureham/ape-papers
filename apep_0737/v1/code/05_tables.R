## 05_tables.R — Generate all LaTeX tables
## APEP paper apep_0737: Dodd-Frank $10B Bunching

source("00_packages.R")

bank_data <- readRDS("../data/bank_data_clean.rds")
results <- readRDS("../data/bunching_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

fmt_coef <- function(est, se, digits = 3) {
  t <- abs(est / se)
  stars <- ifelse(t > 2.576, "$^{***}$",
           ifelse(t > 1.960, "$^{**}$",
           ifelse(t > 1.645, "$^{*}$", "")))
  sprintf("%.3f%s", est, stars)
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

window_data <- bank_data %>%
  filter(total_assets_B >= 5, total_assets_B <= 15,
         period %in% c("pre_dodd_frank", "post_dodd_frank", "post_egrrcpa"))

summary_stats <- window_data %>%
  group_by(period) %>%
  summarise(
    n_obs = n(),
    n_banks = n_distinct(cert),
    n_qtrs = n_distinct(yearq),
    mean_assets = mean(total_assets_B),
    med_assets = median(total_assets_B),
    pct_below = mean(below_10B) * 100,
    pct_window = mean(in_bunching_window) * 100,
    .groups = "drop"
  )

period_labels <- c(
  pre_dodd_frank = "Pre-Dodd-Frank (2001--2009)",
  post_dodd_frank = "Post-Dodd-Frank (2011--2017)",
  post_egrrcpa = "Post-EGRRCPA (2019--2024)"
)

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics: FDIC-Insured Banks, \\$5B--\\$15B Assets}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  " & Bank-Qtr & Unique & & Mean & Median & \\% Below & \\% in \\\\",
  " & Obs. & Banks & Qtrs & (\\$B) & (\\$B) & \\$10B & \\$8--10B \\\\",
  "\\midrule"
)

for (p in c("pre_dodd_frank", "post_dodd_frank", "post_egrrcpa")) {
  r <- summary_stats %>% filter(period == p)
  tab1 <- c(tab1, sprintf(
    "%s & %s & %d & %d & %.2f & %.2f & %.1f & %.1f \\\\",
    period_labels[p], format(r$n_obs, big.mark = ","),
    r$n_banks, r$n_qtrs, r$mean_assets, r$med_assets, r$pct_below, r$pct_window
  ))
}

tab1 <- c(tab1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Data from FDIC BankFind Suite quarterly Call Reports (Schedule RC, RCFD2170). Sample: FDIC-insured institutions with \\$5--15B in total consolidated assets. Transition years (2010, 2018) excluded. The \\$10B threshold triggers CFPB supervisory authority and Durbin Amendment interchange fee caps under Dodd-Frank (2010). EGRRCPA (2018) raised the stress test threshold to \\$250B but left Durbin caps unchanged.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================
# TABLE 2: Main Bunching Results
# ============================================================
cat("=== Table 2: Main Bunching ===\n")

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Bunching at the \\$10 Billion Regulatory Threshold}",
  "\\label{tab:bunching}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Pre-DF & Post-DF & Post-EGRRCPA \\\\",
  " & (2001--2009) & (2011--2017) & (2019--2024) \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Kleven-Waseem Bunching}} \\\\",
  "\\addlinespace",
  sprintf("Excess mass ($\\hat{b}$) & %s & %s & %s \\\\",
          fmt_coef(results$pre$b_hat, results$pre$se_b),
          fmt_coef(results$post$b_hat, results$post$se_b),
          fmt_coef(results$egrrcpa$b_hat, results$egrrcpa$se_b)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\",
          results$pre$se_b, results$post$se_b, results$egrrcpa$se_b),
  "\\addlinespace",
  sprintf("Diff-in-Bunching & \\multicolumn{2}{c}{%s} & \\\\",
          fmt_coef(results$dib$estimate, results$dib$se)),
  sprintf("(Post -- Pre) & \\multicolumn{2}{c}{(%.3f)} & \\\\", results$dib$se),
  "\\addlinespace",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Share Below \\$10B in \\$8--12B Window}} \\\\",
  "\\addlinespace"
)

share_data <- results$share_by_period
for (i in seq_len(nrow(share_data))) {
  r <- share_data[i, ]
  plabel <- period_labels[r$period]
  if (is.na(plabel)) next
  tab2 <- c(tab2, sprintf("Share below & \\multicolumn{3}{c}{%.3f (%.3f)} \\\\  %%  %s",
                           r$share_below, r$se, plabel))
}

# Add regression results
reg <- results$share_reg
reg_coefs <- coef(reg)
reg_se <- sqrt(diag(vcov(reg)))

tab2 <- c(tab2,
  "\\addlinespace",
  sprintf("$\\Delta$ Post-DF & \\multicolumn{3}{c}{%s} \\\\",
          fmt_coef(reg_coefs["post_df"], reg_se["post_df"])),
  sprintf(" & \\multicolumn{3}{c}{(%.4f)} \\\\", reg_se["post_df"]),
  sprintf("$\\Delta$ Post-EGRRCPA & \\multicolumn{3}{c}{%s} \\\\",
          fmt_coef(reg_coefs["post_egrrcpa"], reg_se["post_egrrcpa"])),
  sprintf(" & \\multicolumn{3}{c}{(%.4f)} \\\\", reg_se["post_egrrcpa"]),
  "\\addlinespace",
  "\\midrule",
  sprintf("Observations & %s & %s & %s \\\\",
          format(results$pre$n_obs, big.mark = ","),
          format(results$post$n_obs, big.mark = ","),
          format(results$egrrcpa$n_obs, big.mark = ",")),
  sprintf("Banks & %d & %d & %d \\\\",
          results$pre$n_banks, results$post$n_banks, results$egrrcpa$n_banks),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A: Kleven-Waseem (2013) bunching estimates. $\\hat{b}$ is the normalized excess mass of banks below \\$10B relative to the polynomial counterfactual. Fitted on \\$5--15B window, excluded region [\\$9B, \\$11B), 5th-degree polynomial, \\$250M bins. Block bootstrap SEs (500 replications, clustered by bank) in parentheses. Panel B: OLS regression of an indicator for being below \\$10B on period dummies, restricted to banks in the \\$8--12B window, with calendar-quarter fixed effects and heteroskedasticity-robust SEs. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2, "../tables/tab2_bunching.tex")

# ============================================================
# TABLE 3: Placebo Thresholds
# ============================================================
cat("=== Table 3: Placebo ===\n")

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Placebo Tests at Non-Regulatory Thresholds}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Threshold & $\\hat{b}$ & SE & $t$ \\\\",
  "\\midrule",
  sprintf("\\$10B (regulatory) & %s & %.3f & %.2f \\\\",
          fmt_coef(results$post$b_hat, results$post$se_b),
          results$post$se_b, results$post$t_stat),
  "\\addlinespace"
)

for (thresh_name in names(robustness$placebo)) {
  res <- robustness$placebo[[thresh_name]]
  tab3 <- c(tab3, sprintf(
    "\\$%sB (placebo) & %s & %.3f & %.2f \\\\",
    thresh_name, fmt_coef(res$b_hat, res$se_b), res$se_b, res$t_stat
  ))
}

# McCrary
mcc <- robustness$mccrary
mcc_coef <- coef(mcc)["above"]
mcc_se <- summary(mcc)$coefficients["above", "Std. Error"]
mcc_t <- summary(mcc)$coefficients["above", "t value"]

tab3 <- c(tab3,
  "\\addlinespace",
  "\\midrule",
  sprintf("McCrary density test & %s & %.3f & %.2f \\\\",
          fmt_coef(mcc_coef, mcc_se), mcc_se, mcc_t),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Top panel: Kleven-Waseem excess mass at stated thresholds (post-Dodd-Frank 2011--2017). The \\$10B threshold triggers CFPB and Durbin; placebo thresholds carry no regulatory significance. Bottom: log-density discontinuity at \\$10B from local linear regression on \\$250M bin counts. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3, "../tables/tab3_placebo.tex")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Robustness of Bunching Estimates}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & $\\hat{b}$ & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Polynomial Order}} \\\\",
  "\\addlinespace"
)

for (p in names(robustness$polynomial)) {
  res <- robustness$polynomial[[p]]
  tab4 <- c(tab4, sprintf("Order %s & %s & (%.3f) \\\\",
                           p, fmt_coef(res$b_hat, res$se_b), res$se_b))
}

tab4 <- c(tab4, "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel B: Bin Width}} \\\\",
  "\\addlinespace")

for (bw in names(robustness$bin_width)) {
  res <- robustness$bin_width[[bw]]
  tab4 <- c(tab4, sprintf("\\$%sM & %s & (%.3f) \\\\",
                           format(as.numeric(bw) * 1000, big.mark = ","),
                           fmt_coef(res$b_hat, res$se_b), res$se_b))
}

tab4 <- c(tab4, "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel C: Excluded Region}} \\\\",
  "\\addlinespace")

for (w in names(robustness$window)) {
  res <- robustness$window[[w]]
  tab4 <- c(tab4, sprintf("%s & %s & (%.3f) \\\\",
                           w, fmt_coef(res$b_hat, res$se_b), res$se_b))
}

tab4 <- c(tab4,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Kleven-Waseem excess mass estimates at \\$10B using post-Dodd-Frank data (2011--2017). Baseline: 5th-degree polynomial, \\$250M bins, excluded region [\\$9B, \\$11B). Each panel varies one parameter. 200 bootstrap replications. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4, "../tables/tab4_robustness.tex")

# ============================================================
# TABLE 5: Year-by-Year
# ============================================================
cat("=== Table 5: Year-by-Year ===\n")

yearly_df <- readRDS("../data/yearly_bunching.rds")

tab5 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Year-by-Year Bunching at \\$10B}",
  "\\label{tab:yearly}",
  "\\begin{tabular}{llcc}",
  "\\toprule",
  "Year & Regime & $\\hat{b}$ & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(yearly_df))) {
  r <- yearly_df[i, ]
  tab5 <- c(tab5, sprintf(
    "%d & %s & %s & (%.3f) \\\\",
    r$year, r$period, fmt_coef(r$b_hat, r$se_b), r$se_b
  ))
}

tab5 <- c(tab5,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Kleven-Waseem excess mass using all four quarters of the indicated year. Dodd-Frank signed July 2010; EGRRCPA signed May 2018. 100 bootstrap replications per year. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab5, "../tables/tab5_yearly.tex")

# ============================================================
# TABLE F1: SDE (Mandatory)
# ============================================================
cat("=== Table F1: SDE ===\n")

# SDE for the share-based test (most precisely estimated)
pre_window <- bank_data %>%
  filter(period == "pre_dodd_frank", total_assets_B >= 8, total_assets_B <= 12)
post_window <- bank_data %>%
  filter(period == "post_dodd_frank", total_assets_B >= 8, total_assets_B <= 12)
egrrcpa_window <- bank_data %>%
  filter(period == "post_egrrcpa", total_assets_B >= 8, total_assets_B <= 12)

sd_y_pre <- sd(pre_window$below_10B)

# Outcome 1: Share below $10B (post-DF vs pre)
beta1 <- coef(results$share_reg)["post_df"]
se1 <- sqrt(vcov(results$share_reg)["post_df", "post_df"])
sde1 <- beta1 / sd_y_pre
se_sde1 <- se1 / sd_y_pre

# Outcome 2: Share below $10B (post-EGRRCPA vs pre)
beta2 <- coef(results$share_reg)["post_egrrcpa"]
se2 <- sqrt(vcov(results$share_reg)["post_egrrcpa", "post_egrrcpa"])
sde2 <- beta2 / sd_y_pre
se_sde2 <- se2 / sd_y_pre

# Outcome 3: Bunching statistic (DiB)
beta3 <- results$dib$estimate
se3 <- results$dib$se
sd_y3 <- results$pre$se_b * sqrt(500)
if (sd_y3 < 0.01) sd_y3 <- abs(results$pre$b_hat) + results$pre$se_b
sde3 <- beta3 / sd_y3
se_sde3 <- se3 / sd_y3

classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the Dodd-Frank Act's \\$10 billion asset threshold induce FDIC-insured banks to strategically constrain growth, and did the 2018 EGRRCPA rollback reverse this distortion? ",
  "\\textbf{Policy mechanism:} Crossing \\$10 billion in total consolidated assets triggers Consumer Financial Protection Bureau supervisory authority, Durbin Amendment debit interchange fee caps (reducing per-transaction revenue by roughly 50 percent), and enhanced stress testing requirements, creating a discrete jump in the effective regulatory cost schedule for depository institutions. ",
  "\\textbf{Outcome definition:} (1--2) Binary indicator equal to one if the bank's total assets fall below \\$10 billion, measured for banks in the \\$8--12 billion window; (3) Kleven-Waseem normalized excess mass statistic measuring the fraction by which observed density below \\$10B exceeds a smooth polynomial counterfactual. ",
  "\\textbf{Treatment:} Binary; Dodd-Frank Wall Street Reform Act enacted July 2010, EGRRCPA enacted May 2018 (partial rollback). ",
  "\\textbf{Data:} FDIC BankFind Suite quarterly Call Reports (RCFD2170 total assets), 2001Q1--2024Q4, bank-quarter level. ",
  "\\textbf{Method:} OLS with heteroskedasticity-robust standard errors and quarter fixed effects (Outcomes 1--2); Kleven-Waseem polynomial bunching estimation with block bootstrap (Outcome 3). ",
  "\\textbf{Sample:} FDIC-insured depository institutions with \\$8--12 billion in assets (Outcomes 1--2) or \\$5--15 billion (Outcome 3); transition years excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Share below \\$10B (post-DF) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta1, se1, sd_y_pre, sde1, se_sde1, classify_sde(sde1)),
  sprintf("Share below \\$10B (post-EGRRCPA) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta2, se2, sd_y_pre, sde2, se_sde2, classify_sde(sde2)),
  sprintf("Excess mass $\\hat{b}$ (DiB) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta3, se3, sd_y3, sde3, se_sde3, classify_sde(sde3)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables written.\n")
