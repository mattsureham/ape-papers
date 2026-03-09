## 06_tables.R — Generate all LaTeX tables
## apep_0550: India Farm Laws Symmetric Natural Experiment

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
TAB_DIR  <- file.path(dirname(getwd()), "tables")
dir.create(TAB_DIR, recursive = TRUE, showWarnings = FALSE)

monthly <- fread(file.path(DATA_DIR, "monthly_panel.csv"))
monthly[, ym := as.Date(ym)]
monthly[, high_apmc := as.integer(apmc_stringency > median(apmc_stringency, na.rm = TRUE))]
apmc <- fread(file.path(DATA_DIR, "apmc_stringency.csv"))

## ================================================================
## TABLE 1: SUMMARY STATISTICS
## ================================================================

## Panel A: By phase (use median and trimmed mean to avoid outlier distortion)
panel_stats <- monthly[, .(
  `Median Price` = median(mean_price, na.rm = TRUE),
  `Mean Price` = mean(mean_price, na.rm = TRUE),
  `Mean Log Price` = mean(log_mean_price, na.rm = TRUE),
  `SD Log Price` = sd(log_mean_price, na.rm = TRUE),
  `Avg Markets` = mean(n_markets, na.rm = TRUE),
  N = .N
), by = .(Phase = fifelse(phase == 0, "Pre (2018--May 2020)",
           fifelse(phase == 1, "ON (Jun 2020--Jan 2021)",
                   "OFF (Feb 2021--2023)")))]

## Panel B: By APMC group
group_stats <- monthly[, .(
  `Median Price` = median(mean_price, na.rm = TRUE),
  `Mean Log Price` = mean(log_mean_price, na.rm = TRUE),
  `SD Log Price` = sd(log_mean_price, na.rm = TRUE),
  `N States` = uniqueN(state),
  `N Commodities` = uniqueN(commodity),
  N = .N
), by = .(`APMC Group` = fifelse(apmc_stringency > median(apmc_stringency, na.rm = TRUE),
                                  "High APMC", "Low APMC"))]

fwrite(panel_stats, file.path(DATA_DIR, "table1_panel_a.csv"))
fwrite(group_stats, file.path(DATA_DIR, "table1_panel_b.csv"))

## Generate LaTeX — Table 1 is wrapped by paper.tex, so only emit inner content
sink(file.path(TAB_DIR, "tab1_summary.tex"))
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lrrrrrr}\n\\toprule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: By Phase}} \\\\\n")
cat("Phase & Median & Mean & Mean Log & SD Log & Avg Markets & N \\\\\n\\midrule\n")
for (i in 1:nrow(panel_stats)) {
  r <- panel_stats[i]
  cat(sprintf("%s & %.1f & %.1f & %.2f & %.2f & %.1f & %s \\\\\n",
              r$Phase, r$`Median Price`, r$`Mean Price`,
              r$`Mean Log Price`, r$`SD Log Price`,
              r$`Avg Markets`, format(r$N, big.mark=",")))
}
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: By APMC Regulation Intensity}} \\\\\n")
cat("Group & Median & Mean Log & SD Log & N States & N Commodities & N \\\\\n\\midrule\n")
for (i in 1:nrow(group_stats)) {
  r <- group_stats[i]
  cat(sprintf("%s & %.1f & %.2f & %.2f & %d & %d & %s \\\\\n",
              r$`APMC Group`, r$`Median Price`,
              r$`Mean Log Price`, r$`SD Log Price`,
              r$`N States`, r$`N Commodities`, format(r$N, big.mark=",")))
}
cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\small\\textit{Notes:} Retail prices in INR per kg. Data from WFP/VAM food price monitoring via HDX.\n")
cat("Median and Mean in levels (INR/kg); Mean Log and SD Log in log units (used in regressions).\n")
cat("APMC groups split at median of the composite stringency index.\n")
cat("ON phase: June 2020--January 2021 (farm laws active).\n")
cat("OFF phase: February 2021--December 2023 (post-Supreme Court stay and repeal).}\n")
sink()
cat("Table 1 saved\n")

## ================================================================
## TABLE 2: MAIN RESULTS
## ================================================================

## Re-estimate to capture model objects
fit1 <- feols(log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
                state_commodity + commodity_month, data = monthly, cluster = ~state)

fit2 <- feols(log_mean_price ~ high_apmc:on_phase + high_apmc:off_phase |
                state_commodity + commodity_month, data = monthly, cluster = ~state)

fit3 <- feols(log_mean_price ~ apmc_cess_pct:on_phase + apmc_cess_pct:off_phase |
                state_commodity + commodity_month, data = monthly, cluster = ~state)

## Log-transform sd_price to stabilize scale
monthly[, log_sd_price := log(sd_price + 1)]
fit4 <- feols(log_sd_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
                state_commodity + commodity_month,
              data = monthly[!is.na(sd_price) & sd_price > 0],
              cluster = ~state)

fit5 <- tryCatch(
  feols(log(n_markets + 1) ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
          state_commodity + commodity_month, data = monthly, cluster = ~state),
  error = function(e) NULL
)

## Generate Table 2 as booktabs (avoiding tabularray compatibility issues)
tab2_file <- file.path(TAB_DIR, "tab2_main_results.tex")
sink(tab2_file)
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Effect of Farm Laws on Agricultural Commodity Prices}\n")
cat("\\label{tab:main_results}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n\\toprule\n")
cat("& (1) & (2) & (3) & (4) & (5) \\\\\n")
cat("& Log Price & Log Price & Log Price & Log SD & Log Markets \\\\\n")
cat("\\midrule\n")

## Helper to format with stars
fmt_coef <- function(est, pv) {
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  sprintf("%.3f%s", est, stars)
}

## Row 1: APMC × ON
pv1 <- fixest::pvalue(fit1)
pv4 <- fixest::pvalue(fit4)
pv5 <- if (!is.null(fit5)) fixest::pvalue(fit5) else c(NA, NA)
cat(sprintf("APMC $\\times$ ON & %s & & & %s & %s \\\\\n",
            fmt_coef(coef(fit1)[1], pv1[1]),
            fmt_coef(coef(fit4)[1], pv4[1]),
            if (!is.null(fit5)) fmt_coef(coef(fit5)[1], pv5[1]) else ""))
cat(sprintf("& (%.3f) & & & (%.3f) & %s \\\\\n",
            se(fit1)[1], se(fit4)[1],
            if (!is.null(fit5)) sprintf("(%.3f)", se(fit5)[1]) else ""))

## Row 2: APMC × OFF
cat(sprintf("APMC $\\times$ OFF & %s & & & %s & %s \\\\\n",
            fmt_coef(coef(fit1)[2], pv1[2]),
            fmt_coef(coef(fit4)[2], pv4[2]),
            if (!is.null(fit5)) fmt_coef(coef(fit5)[2], pv5[2]) else ""))
cat(sprintf("& (%.3f) & & & (%.3f) & %s \\\\\n",
            se(fit1)[2], se(fit4)[2],
            if (!is.null(fit5)) sprintf("(%.3f)", se(fit5)[2]) else ""))

## Row 3: High APMC × ON
pv2 <- fixest::pvalue(fit2)
cat(sprintf("High APMC $\\times$ ON & & %s & & & \\\\\n",
            fmt_coef(coef(fit2)[1], pv2[1])))
cat(sprintf("& & (%.3f) & & & \\\\\n", se(fit2)[1]))

## Row 4: High APMC × OFF
cat(sprintf("High APMC $\\times$ OFF & & %s & & & \\\\\n",
            fmt_coef(coef(fit2)[2], pv2[2])))
cat(sprintf("& & (%.3f) & & & \\\\\n", se(fit2)[2]))

## Row 5: Cess Rate × ON
pv3 <- fixest::pvalue(fit3)
cat(sprintf("Cess Rate $\\times$ ON & & & %s & & \\\\\n",
            fmt_coef(coef(fit3)[1], pv3[1])))
cat(sprintf("& & & (%.3f) & & \\\\\n", se(fit3)[1]))

## Row 6: Cess Rate × OFF
cat(sprintf("Cess Rate $\\times$ OFF & & & %s & & \\\\\n",
            fmt_coef(coef(fit3)[2], pv3[2])))
cat(sprintf("& & & (%.3f) & & \\\\\n", se(fit3)[2]))

## Footer
cat("\\midrule\n")
cat(sprintf("Num.\\ Obs. & %s & %s & %s & %s & %s \\\\\n",
            format(nobs(fit1), big.mark=","),
            format(nobs(fit2), big.mark=","),
            format(nobs(fit3), big.mark=","),
            format(nobs(fit4), big.mark=","),
            if (!is.null(fit5)) format(nobs(fit5), big.mark=",") else ""))
cat("FE: State$\\times$Commodity & X & X & X & X & X \\\\\n")
cat("FE: Commodity$\\times$Month & X & X & X & X & X \\\\\n")
cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\small\\textit{Notes:} * $p < 0.1$, ** $p < 0.05$, *** $p < 0.01$.\n")
cat("State-clustered standard errors in parentheses.\n")
cat("ON phase: June 2020--January 2021 (farm laws enacted).\n")
cat("OFF phase: February 2021 onward (post-Supreme Court stay).\n")
cat("Columns (1)--(3): log mean retail price. Column (4): log within-state price SD.\n")
cat("Column (5): log number of reporting markets.}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 saved\n")

## ================================================================
## TABLE 3: ROBUSTNESS
## ================================================================

robust <- fread(file.path(DATA_DIR, "robustness_results.csv"))

## Re-estimate robustness to get N for each
no_protest <- monthly[!state %in% c("Punjab", "Haryana")]
no_blocked <- monthly[blocked_farm_laws == 0]
no_baseline <- monthly[apmc_abolished == 0 & apmc_stringency > 0]
narrow <- monthly[year >= 2019 & year <= 2022]

fit_r1 <- feols(log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
                  state_commodity + commodity_month, data = no_protest, cluster = ~state)
fit_r2 <- feols(log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
                  state_commodity + commodity_month, data = no_blocked, cluster = ~state)
fit_r3 <- feols(log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
                  state_commodity + commodity_month, data = no_baseline, cluster = ~state)
fit_r4 <- feols(log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
                  state_commodity + commodity_month, data = narrow, cluster = ~state)

sink(file.path(TAB_DIR, "tab3_robustness.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Robustness Checks}\n\\label{tab:robustness}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n\\toprule\n")
cat("Specification & ON Estimate & ON SE & OFF Estimate & OFF SE & N \\\\\n\\midrule\n")

## State-specific trends
monthly[, time_trend := as.integer(difftime(ym, min(ym), units = "days"))]
fit_r5 <- feols(log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
                  state_commodity + commodity_month + state[time_trend],
                data = monthly, cluster = ~state)

## Balanced sample (cells observed in all phases)
cell_phase <- monthly[, .(
  has_pre = any(on_phase == 0 & off_phase == 0),
  has_on  = any(on_phase == 1),
  has_off = any(off_phase == 1)
), by = .(state, commodity)]
balanced_cells <- cell_phase[has_pre == TRUE & has_on == TRUE & has_off == TRUE]
monthly_bal <- monthly[balanced_cells, on = .(state, commodity)]
fit_r6 <- feols(log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
                  state_commodity + commodity_month, data = monthly_bal, cluster = ~state)

rob_fits <- list(
  list(name="Baseline", fit=fit1),
  list(name="Drop Punjab/Haryana", fit=fit_r1),
  list(name="Drop blocked states", fit=fit_r2),
  list(name="Exclude Bihar/Kerala", fit=fit_r3),
  list(name="Narrow window (2019--22)", fit=fit_r4),
  list(name="State-specific trends", fit=fit_r5),
  list(name="Balanced sample", fit=fit_r6)
)

for (rf in rob_fits) {
  cat(sprintf("%s & %.3f & (%.3f) & %.3f & (%.3f) & %s \\\\\n",
              rf$name, coef(rf$fit)[1], se(rf$fit)[1],
              coef(rf$fit)[2], se(rf$fit)[2],
              format(nobs(rf$fit), big.mark=",")))
}

cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\small\\textit{Notes:} All specifications include state$\\times$commodity and commodity$\\times$month fixed effects.\n")
cat("Standard errors clustered at state level.\n")
cat("Dependent variable: log mean retail price (INR/kg).}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 saved\n")

## ================================================================
## TABLE 4: PLACEBO TESTS
## ================================================================

placebo <- fread(file.path(DATA_DIR, "placebo_results.csv"))

sink(file.path(TAB_DIR, "tab4_placebo.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Placebo Tests}\n\\label{tab:placebo}\n")
cat("\\begin{tabular}{lccccc}\n\\toprule\n")
cat("Test & ON Estimate & ON SE & OFF Estimate & OFF SE & N \\\\\n\\midrule\n")

tests <- unique(placebo$test)
for (t in tests) {
  on_row <- placebo[test == t & phase == "ON"]
  off_row <- placebo[test == t & phase == "OFF"]
  if (nrow(on_row) > 0 && nrow(off_row) > 0) {
    on_est <- ifelse(is.na(on_row$estimate), "---", sprintf("%.3f", on_row$estimate))
    on_se <- ifelse(is.na(on_row$se), "---", sprintf("(%.3f)", on_row$se))
    off_est <- ifelse(is.na(off_row$estimate), "---", sprintf("%.3f", off_row$estimate))
    off_se <- ifelse(is.na(off_row$se), "---", sprintf("(%.3f)", off_row$se))
    n_obs <- ifelse(is.na(on_row$n_obs), "---", format(on_row$n_obs, big.mark=","))
    cat(sprintf("%s & %s & %s & %s & %s & %s \\\\\n", t, on_est, on_se, off_est, off_se, n_obs))
  }
}

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\small\\textit{Notes:} Pre-period placebo: fake treatment onset in June 2019 on pre-2020 data,\n")
cat("using APMC stringency$\\times$phase interaction.\n")
cat("Reverse treatment: uses $(1 - \\text{APMC stringency})$ as the treatment variable.\n")
cat("All specifications include state$\\times$commodity and commodity$\\times$month FE,\n")
cat("standard errors clustered at state level.}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 saved\n")

## ================================================================
## TABLE 5: HETEROGENEITY BY COMMODITY
## ================================================================

het <- fread(file.path(DATA_DIR, "heterogeneity_commodity.csv"))

sink(file.path(TAB_DIR, "tab5_heterogeneity.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Heterogeneous Effects by Commodity}\n\\label{tab:heterogeneity}\n")
cat("\\begin{tabular}{lcccccc}\n\\toprule\n")
cat(" & \\multicolumn{3}{c}{ON Phase} & \\multicolumn{3}{c}{OFF Phase} \\\\\n")
cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n")
cat("Commodity & Estimate & SE & N & Estimate & SE & N \\\\\n\\midrule\n")

commodities <- unique(het$commodity)
for (c in commodities) {
  on_r <- het[commodity == c & phase == "ON"]
  off_r <- het[commodity == c & phase == "OFF"]
  if (nrow(on_r) > 0 && nrow(off_r) > 0) {
    cat(sprintf("%s & %.4f & (%.4f) & %d & %.4f & (%.4f) & %d \\\\\n",
                c, on_r$estimate, on_r$se, on_r$n_obs,
                off_r$estimate, off_r$se, off_r$n_obs))
  }
}

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} Each row is a separate regression of log mean price on APMC stringency$\\times$phase,\n")
cat("with state$\\times$commodity and commodity$\\times$month FE, clustering at state level.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 5 saved\n")

cat("\n=== ALL TABLES GENERATED ===\n")
