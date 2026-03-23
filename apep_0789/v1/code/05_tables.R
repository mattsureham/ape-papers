# 05_tables.R — Generate all LaTeX tables
library(data.table)
library(fixest)
library(lubridate)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
setwd(dirname(script_dir))

panel <- readRDS("data/analysis_panel.rds")
results <- readRDS("data/main_results.rds")
robust <- readRDS("data/robustness_results.rds")
first_restart <- readRDS("data/first_restart.rds")

if (!dir.exists("tables")) dir.create("tables")

# ─── Helper: format with significance stars ───────────────────────────────
stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.10) return("$^{*}$")
  return("")
}

# ═══════════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary Statistics...\n")

pre_panel <- panel[year_month < "2015-08-01"]
post_panel <- panel[year_month >= "2015-08-01"]

# By treatment group
summ_treated_pre <- pre_panel[treated == TRUE, .(
  mean = mean(price_mean), sd = sd(price_mean),
  p10 = mean(price_p10), p90 = mean(price_p90),
  N = .N
)]
summ_control_pre <- pre_panel[treated == FALSE, .(
  mean = mean(price_mean), sd = sd(price_mean),
  p10 = mean(price_p10), p90 = mean(price_p90),
  N = .N
)]
summ_treated_post <- post_panel[treated == TRUE, .(
  mean = mean(price_mean), sd = sd(price_mean),
  p10 = mean(price_p10), p90 = mean(price_p90),
  N = .N
)]
summ_control_post <- post_panel[treated == FALSE, .(
  mean = mean(price_mean), sd = sd(price_mean),
  p10 = mean(price_p10), p90 = mean(price_p90),
  N = .N
)]

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Monthly Wholesale Electricity Prices}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Pre-Restart (2012--2015)} & \\multicolumn{2}{c}{Post-Restart (2015--2025)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Treated & Control & Treated & Control \\\\\n",
  "\\hline\n",
  sprintf("Mean price (\\textyen/kWh) & %.2f & %.2f & %.2f & %.2f \\\\\n",
          summ_treated_pre$mean, summ_control_pre$mean,
          summ_treated_post$mean, summ_control_post$mean),
  sprintf("SD price & %.2f & %.2f & %.2f & %.2f \\\\\n",
          summ_treated_pre$sd, summ_control_pre$sd,
          summ_treated_post$sd, summ_control_post$sd),
  sprintf("10th percentile & %.2f & %.2f & %.2f & %.2f \\\\\n",
          summ_treated_pre$p10, summ_control_pre$p10,
          summ_treated_post$p10, summ_control_post$p10),
  sprintf("90th percentile & %.2f & %.2f & %.2f & %.2f \\\\\n",
          summ_treated_pre$p90, summ_control_pre$p90,
          summ_treated_post$p90, summ_control_post$p90),
  sprintf("Region-months & %d & %d & %d & %d \\\\\n",
          summ_treated_pre$N, summ_control_pre$N,
          summ_treated_post$N, summ_control_post$N),
  "Regions & 5 & 4 & 5 & 4 \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Treated regions are those with at least one NRA-approved nuclear reactor restart (Kyushu, Kansai, Shikoku, Tohoku, Chugoku). Control regions have no restarts through 2025 (Tokyo, Chubu, Hokuriku, Hokkaido). Prices are area-level JEPX day-ahead spot auction prices aggregated to monthly means from half-hourly settlement data. Pre-restart period ends July 2015 (month before first restart in Kyushu). All prices in nominal Yen per kilowatt-hour.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, "tables/tab1_summary.tex")

# ═══════════════════════════════════════════════════════════════════════════
# TABLE 2: Main Results
# ═══════════════════════════════════════════════════════════════════════════
cat("Generating Table 2: Main Results...\n")

# Re-run regressions to get objects
twfe <- feols(price_mean ~ post | region_id + time_int,
              data = panel, cluster = ~region_id)
twfe_log <- feols(log_price ~ post | region_id + time_int,
                  data = panel, cluster = ~region_id)
twfe_peak <- feols(price_peak ~ post | region_id + time_int,
                   data = panel, cluster = ~region_id)
twfe_offpeak <- feols(price_offpeak ~ post | region_id + time_int,
                      data = panel, cluster = ~region_id)

# CS results
cs_att <- results$cs_att
cs_se <- results$cs_att_se
cs_pval <- 2 * pnorm(-abs(cs_att / cs_se))

# Sun-Abraham
panel[, cohort_sa := fifelse(treated, as.integer(format(treat_month, "%Y")) * 12 +
        as.integer(format(treat_month, "%m")), 100000L)]
panel[, year_month_int := as.integer(format(year_month, "%Y")) * 12 +
        as.integer(format(year_month, "%m"))]
sa_est <- feols(price_mean ~ sunab(cohort_sa, year_month_int) | region_id + year_month_int,
                data = panel, cluster = ~region_id)
sa_agg <- summary(sa_est, agg = "ATT")
sa_coef <- sa_agg$coeftable["ATT", "Estimate"]
sa_se_val <- sa_agg$coeftable["ATT", "Std. Error"]
sa_pval <- sa_agg$coeftable["ATT", "Pr(>|t|)"]

fmt <- function(x) sprintf("%.3f", x)
se_fmt <- function(x) sprintf("(%.3f)", x)

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Nuclear Restarts on Wholesale Electricity Prices}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Mean Price (\\textyen/kWh)} & Log & \\multicolumn{2}{c}{Time of Day} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-5} \\cmidrule(lr){6-7}\n",
  " & TWFE & CS & SA & TWFE & Peak & Off-Peak \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\hline\n",
  sprintf("Post-Restart & %s%s & %s%s & %s%s & %s%s & %s%s & %s%s \\\\\n",
          fmt(coef(twfe)["postTRUE"]), stars(pvalue(twfe)["postTRUE"]),
          fmt(cs_att), stars(cs_pval),
          fmt(sa_coef), stars(sa_pval),
          fmt(coef(twfe_log)["postTRUE"]), stars(pvalue(twfe_log)["postTRUE"]),
          fmt(coef(twfe_peak)["postTRUE"]), stars(pvalue(twfe_peak)["postTRUE"]),
          fmt(coef(twfe_offpeak)["postTRUE"]), stars(pvalue(twfe_offpeak)["postTRUE"])),
  sprintf(" & %s & %s & %s & %s & %s & %s \\\\\n",
          se_fmt(se(twfe)["postTRUE"]),
          se_fmt(cs_se),
          se_fmt(sa_se_val),
          se_fmt(se(twfe_log)["postTRUE"]),
          se_fmt(se(twfe_peak)["postTRUE"]),
          se_fmt(se(twfe_offpeak)["postTRUE"])),
  "\\hline\n",
  sprintf("WCB $p$-value & %.3f & & & & & \\\\\n", robust$wcb_pval),
  sprintf("RI $p$-value & %.3f & & & & & \\\\\n", robust$ri_pval),
  "Region FE & Yes & --- & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & --- & Yes & Yes & Yes & Yes \\\\\n",
  "Control group & All & NYT & All & All & All & All \\\\\n",
  sprintf("Pre-treatment mean & %.2f & %.2f & %.2f & %.2f & & \\\\\n",
          results$pre_mean_price, results$pre_mean_price, results$pre_mean_price,
          mean(log(panel[year_month < "2015-08-01"]$price_mean))),
  sprintf("Observations & %d & %d & %d & %d & %d & %d \\\\\n",
          nrow(panel), nrow(panel), nrow(panel), nrow(panel), nrow(panel), nrow(panel)),
  "Regions & 9 & 9 & 9 & 9 & 9 & 9 \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each column reports the average treatment effect of nuclear reactor restarts on wholesale electricity prices. TWFE = two-way fixed effects; CS = Callaway and Sant'Anna (2021) with not-yet-treated control group; SA = Sun and Abraham (2021). Standard errors clustered at the region level in parentheses. WCB = wild cluster bootstrap $p$-value using the Webb 6-point distribution (9,999 replications). RI = exact randomization inference $p$-value over all 126 permutations of 5 treated among 9 regions. Peak hours are 8:00--20:00; off-peak hours are 20:00--8:00. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, "tables/tab2_main.tex")

# ═══════════════════════════════════════════════════════════════════════════
# TABLE 3: Robustness
# ═══════════════════════════════════════════════════════════════════════════
cat("Generating Table 3: Robustness...\n")

# Compute p-values for robustness specs
weekly_pval <- 2 * pt(-abs(robust$weekly_coef / robust$weekly_se), df = 7)
donut_pval <- 2 * pt(-abs(robust$donut_coef / robust$donut_se), df = 7)
median_pval <- 2 * pt(-abs(robust$median_coef / robust$median_se), df = 7)
dosage_pval <- 2 * pt(-abs(robust$dosage_coef / robust$dosage_se), df = 7)

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Weekly & Donut & Median & Volatility & Dosage \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\hline\n",
  sprintf("Post-Restart & %s%s & %s%s & %s%s & %s & \\\\\n",
          fmt(robust$weekly_coef), stars(weekly_pval),
          fmt(robust$donut_coef), stars(donut_pval),
          fmt(robust$median_coef), stars(median_pval),
          fmt(robust$vol_coef)),
  sprintf(" & %s & %s & %s & %s & \\\\\n",
          se_fmt(robust$weekly_se), se_fmt(robust$donut_se),
          se_fmt(robust$median_se), se_fmt(robust$vol_se)),
  sprintf("Cumulative GW & & & & & %s%s \\\\\n",
          fmt(robust$dosage_coef), stars(dosage_pval)),
  sprintf(" & & & & & %s \\\\\n", se_fmt(robust$dosage_se)),
  "\\hline\n",
  "Region FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Time FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Aggregation & Weekly & Monthly & Monthly & Monthly & Monthly \\\\\n",
  "Transition excluded & No & $\\pm$3 months & No & No & No \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} All specifications include region and time fixed effects with standard errors clustered at the region level. Column~(1) aggregates half-hourly prices to weekly means. Column~(2) drops the three months before and after each region's first restart. Column~(3) uses the median rather than mean monthly price. Column~(4) estimates the effect on within-month price standard deviation. Column~(5) replaces the binary post-restart indicator with cumulative restarted nuclear capacity in gigawatts. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, "tables/tab3_robustness.tex")

# ═══════════════════════════════════════════════════════════════════════════
# TABLE 4: Region-Level Heterogeneity
# ═══════════════════════════════════════════════════════════════════════════
cat("Generating Table 4: Region Heterogeneity...\n")

# Region-specific TWFE estimates
region_results <- list()
for (r in unique(panel[treated == TRUE]$region)) {
  sub <- panel[region == r | treated == FALSE]
  sub[, post_r := region == r & post]
  fit <- feols(price_mean ~ post_r | region_id + time_int,
               data = sub, cluster = ~region_id)
  region_results[[r]] <- list(
    coef = coef(fit)["post_rTRUE"],
    se = se(fit)["post_rTRUE"],
    pval = pvalue(fit)["post_rTRUE"],
    n_reactors = first_restart[region == r]$n_reactors,
    cap_gw = first_restart[region == r]$total_capacity_mw / 1000,
    first_date = format(first_restart[region == r]$first_restart_date, "%b %Y")
  )
}

tab4_rows <- ""
for (r in c("Kyushu", "Kansai", "Shikoku", "Tohoku", "Chugoku")) {
  rr <- region_results[[r]]
  tab4_rows <- paste0(tab4_rows,
    sprintf("%s & %s & %.1f & %s%s & %s \\\\\n",
            r, rr$first_date, rr$cap_gw,
            fmt(rr$coef), stars(rr$pval), se_fmt(rr$se)))
}

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Heterogeneity by Region}\n",
  "\\label{tab:hetero}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Region & First Restart & Capacity (GW) & $\\hat{\\beta}$ & SE \\\\\n",
  "\\hline\n",
  tab4_rows,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports the TWFE estimate of the region-specific treatment effect, estimated as the coefficient on the interaction of region and post-restart indicators. Control group is all four never-treated regions. Standard errors clustered at the region level. Capacity is total restarted nuclear capacity through 2025 in gigawatts. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, "tables/tab4_heterogeneity.tex")

# ═══════════════════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY
# ═══════════════════════════════════════════════════════════════════════════
cat("Generating Table F1: Standardized Effect Sizes...\n")

pre_sd <- results$pre_sd_price
pre_sd_log <- sd(panel[year_month < "2015-08-01"]$log_price)
pre_sd_peak <- sd(panel[year_month < "2015-08-01"]$price_peak)
pre_sd_offpeak <- sd(panel[year_month < "2015-08-01"]$price_offpeak)

# SDE = beta / SD(Y)
sde_mean <- results$cs_att / pre_sd
sde_log <- results$cs_log_att / pre_sd_log
sde_peak <- results$peak_coef / pre_sd_peak
sde_offpeak <- results$offpeak_coef / pre_sd_offpeak

# SE(SDE) = SE(beta) / SD(Y)
se_sde_mean <- results$cs_att_se / pre_sd
se_sde_log <- results$cs_log_att_se / pre_sd_log
se_sde_peak <- results$peak_se / pre_sd_peak
se_sde_offpeak <- results$offpeak_se / pre_sd_offpeak

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# SDE table data
sde_data <- data.table(
  outcome = c("Mean price", "Log price", "Peak price", "Off-peak price"),
  beta = c(results$cs_att, results$cs_log_att, results$peak_coef, results$offpeak_coef),
  se = c(results$cs_att_se, results$cs_log_att_se, results$peak_se, results$offpeak_se),
  sd_y = c(pre_sd, pre_sd_log, pre_sd_peak, pre_sd_offpeak),
  sde = c(sde_mean, sde_log, sde_peak, sde_offpeak),
  se_sde = c(se_sde_mean, se_sde_log, se_sde_peak, se_sde_offpeak)
)
sde_data[, class := sapply(sde, classify)]

# Build SDE notes (rich, no numbers leaking)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Japan. ",
  "\\textbf{Research question:} Do post-Fukushima nuclear reactor restarts, approved through Japan's Nuclear Regulation Authority safety review process, reduce wholesale electricity prices in the affected regional grid? ",
  "\\textbf{Policy mechanism:} NRA-approved reactor restarts add low-marginal-cost nuclear baseload generation to regional electricity grids, potentially displacing high-cost LNG-fired generation from the merit order and reducing the market-clearing price in the Japan Electric Power Exchange day-ahead auction. ",
  "\\textbf{Outcome definition:} Monthly mean (or log, peak, off-peak) of half-hourly JEPX day-ahead spot auction settlement prices in Yen per kilowatt-hour at the regional area level. ",
  "\\textbf{Treatment:} Binary indicator for whether any reactor in a region has restarted (first restart ranges from August 2015 to December 2024 across five treated regions). ",
  "\\textbf{Data:} JEPX day-ahead spot prices from japanesepower.org, 9 regions, January 2012 to December 2025, aggregated to 1,512 region-months from 2.5 million half-hourly observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with not-yet-treated control group; standard errors via multiplier bootstrap. ",
  "\\textbf{Sample:} Nine JEPX electricity regions (excluding Okinawa); five treated regions with NRA-approved restarts and four never-treated control regions; Japan's 50Hz/60Hz frequency split limits cross-regional price spillovers. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_rows <- ""
for (i in seq_len(nrow(sde_data))) {
  tabF1_rows <- paste0(tabF1_rows,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            sde_data$outcome[i], sde_data$beta[i], sde_data$se[i],
            sde_data$sd_y[i], sde_data$sde[i], sde_data$se_sde[i],
            sde_data$class[i]))
}

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  tabF1_rows,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "tables/tabF1_sde.tex")

cat("All tables generated.\n")
