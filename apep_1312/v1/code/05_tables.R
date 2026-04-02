# 05_tables.R — Generate all LaTeX tables for apep_1312
source("00_packages.R")

dt <- fread("../data/wages_estimation.csv")
dt[, high_exposure := as.integer(exposure >= 0.5)]
dt[, gross_net_gap := gross_wage - net_wage]
dt[, ln_gap := log(gross_net_gap)]
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

stats_full <- dt[, .(
  mean_gross = mean(gross_wage, na.rm = TRUE),
  sd_gross = sd(gross_wage, na.rm = TRUE),
  mean_net = mean(net_wage, na.rm = TRUE),
  sd_net = sd(net_wage, na.rm = TRUE),
  n_obs = .N,
  n_sectors = uniqueN(sector),
  n_months = uniqueN(ym)
)]

stats_group <- dt[, .(
  mean_gross = mean(gross_wage, na.rm = TRUE),
  sd_gross = sd(gross_wage, na.rm = TRUE),
  mean_net = mean(net_wage, na.rm = TRUE),
  sd_net = sd(net_wage, na.rm = TRUE),
  mean_exposure = mean(exposure),
  n_sectors = uniqueN(sector),
  n_obs = .N
), by = .(exposure_group)]

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Obs. & Sectors \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Full Sample (2012--2024)}} \\\\\n",
  sprintf("Gross wage (MKD) & %s & %s & %s & %d \\\\\n",
          formatC(stats_full$mean_gross, format = "f", digits = 0, big.mark = ","),
          formatC(stats_full$sd_gross, format = "f", digits = 0, big.mark = ","),
          formatC(stats_full$n_obs, format = "d", big.mark = ","),
          stats_full$n_sectors),
  sprintf("Net wage (MKD) & %s & %s & & \\\\\n",
          formatC(stats_full$mean_net, format = "f", digits = 0, big.mark = ","),
          formatC(stats_full$sd_net, format = "f", digits = 0, big.mark = ",")),
  sprintf("Months & & & & %d \\\\\n", stats_full$n_months),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: By Exposure Group}} \\\\\n"
)

for (g in c("High", "Low")) {
  row <- stats_group[exposure_group == g]
  tab1 <- paste0(tab1,
    sprintf("%s exposure (mean $=$ %.2f) & %s & %s & %s & %d \\\\\n",
            g, row$mean_exposure,
            formatC(row$mean_gross, format = "f", digits = 0, big.mark = ","),
            formatC(row$sd_gross, format = "f", digits = 0, big.mark = ","),
            formatC(row$n_obs, format = "d", big.mark = ","),
            row$n_sectors))
}

tab1 <- paste0(tab1,
  "\\hline\\hline\n",
  "\\multicolumn{5}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} ",
  "Monthly average gross and net wages per employee in Macedonian denars (MKD) by NACE Rev.2 sector ",
  "from Statistics North Macedonia. High-exposure sectors have 2018 mean gross wage $\\geq$ 50\\% of the ",
  "MKD 90,000 progressive tax threshold. Sample: January 2012 to December 2024.}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

m1 <- feols(ln_gross ~ reform_x_exposure + post_x_exposure | sector + ym,
            data = dt, cluster = ~sector)

dt[, reform_x_high := reform_2019 * high_exposure]
dt[, post_x_high := post_2020 * high_exposure]
m2 <- feols(ln_gross ~ reform_x_high + post_x_high | sector + ym,
            data = dt, cluster = ~sector)

m3 <- feols(ln_net ~ reform_x_exposure + post_x_exposure | sector + ym,
            data = dt, cluster = ~sector)

m4 <- feols(ln_gap ~ reform_x_exposure + post_x_exposure | sector + ym,
            data = dt, cluster = ~sector)

format_coef <- function(coef_val, se_val, boot_p = NULL) {
  stars <- ""
  p_use <- if (!is.null(boot_p)) boot_p else 2 * pnorm(-abs(coef_val / se_val))
  if (p_use < 0.01) stars <- "^{***}"
  else if (p_use < 0.05) stars <- "^{**}"
  else if (p_use < 0.1) stars <- "^{*}"
  c(sprintf("$%.4f%s$", coef_val, stars),
    sprintf("($%.4f$)", se_val))
}

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{The Reporting Boomerang: Wage Responses to Progressive Taxation}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & ln(Gross) & ln(Gross) & ln(Net) & ln(Gap) \\\\\n",
  " & Continuous & Binary & Continuous & Continuous \\\\\n",
  "\\hline\n"
)

r1 <- format_coef(coef(m1)["reform_x_exposure"], se(m1)["reform_x_exposure"], results$m1_reform$boot_p)
r2 <- format_coef(coef(m2)["reform_x_high"], se(m2)["reform_x_high"], results$m5_reform$boot_p)
r3 <- format_coef(coef(m3)["reform_x_exposure"], se(m3)["reform_x_exposure"], results$m2_reform$boot_p)
r4 <- format_coef(coef(m4)["reform_x_exposure"], se(m4)["reform_x_exposure"])

tab2 <- paste0(tab2,
  sprintf("Reform$_{2019}$ $\\times$ Exposure & %s & %s & %s & %s \\\\\n",
          r1[1], r2[1], r3[1], r4[1]),
  sprintf(" & %s & %s & %s & %s \\\\\n", r1[2], r2[2], r3[2], r4[2])
)

p1 <- format_coef(coef(m1)["post_x_exposure"], se(m1)["post_x_exposure"], results$m1_post$boot_p)
p2 <- format_coef(coef(m2)["post_x_high"], se(m2)["post_x_high"])
p3 <- format_coef(coef(m3)["post_x_exposure"], se(m3)["post_x_exposure"])
p4 <- format_coef(coef(m4)["post_x_exposure"], se(m4)["post_x_exposure"])

tab2 <- paste0(tab2,
  sprintf("Post$_{2020+}$ $\\times$ Exposure & %s & %s & %s & %s \\\\\n",
          p1[1], p2[1], p3[1], p4[1]),
  sprintf(" & %s & %s & %s & %s \\\\\n", p1[2], p2[2], p3[2], p4[2])
)

tab2 <- paste0(tab2,
  "\\hline\n",
  "Sector FE & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          formatC(nobs(m1), big.mark = ","),
          formatC(nobs(m2), big.mark = ","),
          formatC(nobs(m3), big.mark = ","),
          formatC(nobs(m4), big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
          r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"), r2(m4, "r2")),
  sprintf("Bootstrap $p$ (Reform) & %.3f & %.3f & %.3f & --- \\\\\n",
          results$m1_reform$boot_p, results$m5_reform$boot_p, results$m2_reform$boot_p),
  "\\hline\\hline\n",
  "\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} ",
  "Dependent variables: log gross wage (cols 1--2), log net wage (col 3), log gross-net gap (col 4). ",
  "``Exposure'' is the sector's 2018 mean gross wage divided by the MKD 90,000 progressive tax threshold. ",
  "Column 2 uses a binary indicator for high-exposure sectors (exposure $\\geq$ 0.5). ",
  "Reform$_{2019}$ $=$ 1 for all months in 2019; Post$_{2020+}$ $=$ 1 for January 2020 onward. ",
  "Standard errors clustered by sector in parentheses. Bootstrap $p$-values from wild cluster bootstrap ",
  "(Rademacher weights, 999 replications). ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$ based on bootstrap $p$-values where available.}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ============================================================
# TABLE 3: Robustness
# ============================================================
cat("\n=== Table 3: Robustness ===\n")

loo <- fread("../data/loo_results.csv")

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Reform$_{2019}$ $\\times$ Exposure & Post$_{2020+}$ $\\times$ Exposure \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Leave-One-Out (drop each high-exposure sector)}} \\\\\n"
)

for (i in seq_len(nrow(loo))) {
  rc <- format_coef(loo$coef_reform[i], loo$se_reform[i])
  pc <- format_coef(loo$coef_post[i], loo$se_post[i])
  tab3 <- paste0(tab3,
    sprintf("Drop %s & %s & %s \\\\\n", loo$dropped[i], rc[1], pc[1]),
    sprintf(" & %s & %s \\\\\n", rc[2], pc[2]))
}

tab3 <- paste0(tab3,
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Alternative Sample Periods}} \\\\\n",
  sprintf("2016--2022 & %s & \\\\\n",
          format_coef(robustness$short_window$coef, robustness$short_window$se)[1]),
  sprintf(" & %s & \\\\\n",
          format_coef(robustness$short_window$coef, robustness$short_window$se)[2]),
  sprintf("Full sample (2005--2024) & %s & \\\\\n",
          format_coef(robustness$long_window$coef, robustness$long_window$se)[1]),
  sprintf(" & %s & \\\\\n",
          format_coef(robustness$long_window$coef, robustness$long_window$se)[2]),
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Inference}} \\\\\n",
  sprintf("Permutation $p$-value (500 draws) & %.3f & \\\\\n", robustness$perm_p),
  sprintf("January$\\times$Exposure (pre-2019) & %s & \\\\\n",
          format_coef(robustness$january$coef, robustness$january$se)[1]),
  sprintf(" & %s & \\\\\n",
          format_coef(robustness$january$coef, robustness$january$se)[2]),
  "\\hline\\hline\n",
  "\\multicolumn{3}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} ",
  "Panel A drops each high-exposure sector from the estimation sample. ",
  "Panel B varies the sample window. Panel C reports permutation inference ",
  "(randomly assigning 12-month treatment windows to non-2019 years, 500 replications) ",
  "and a pre-period January seasonality test. All specifications include sector and month fixed effects ",
  "with standard errors clustered by sector.}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robustness.tex")
cat("Table 3 written.\n")

# ============================================================
# TABLE 4: Event Study Coefficients
# ============================================================
cat("\n=== Table 4: Event Study ===\n")

es <- fread("../data/event_study_coefs.csv")
es <- es[order(event_time)]

key_times <- c(-12, -6, -3, -1, 0, 3, 6, 12, 18, 24)
es_tab <- es[event_time %in% key_times]

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Monthly Coefficients on Exposure $\\times$ Event Time}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Event Month & Coefficient & SE & 95\\% CI \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(es_tab))) {
  et <- es_tab$event_time[i]
  label <- if (et == 0) "Jan 2019 (reform onset)"
           else if (et == 12) "Jan 2020 (repeal)"
           else if (et < 0) sprintf("$t%d$", et)
           else sprintf("$t+%d$", et)
  tab4 <- paste0(tab4,
    sprintf("%s & %.4f & %.4f & [%.4f, %.4f] \\\\\n",
            label, es_tab$coef[i], es_tab$se[i],
            es_tab$ci_lo[i], es_tab$ci_hi[i]))
}

tab4 <- paste0(tab4,
  "\\hline\\hline\n",
  "\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} ",
  "Coefficients from regressing log gross wages on interactions between sector exposure and ",
  "event-time indicators, with sector and month fixed effects. Reference period: $t=-1$ (December 2018). ",
  "Standard errors clustered by sector. Pre-treatment coefficients test parallel trends; ",
  "reform-period coefficients (0--11) measure wage suppression; post-repeal coefficients ($\\geq 12$) ",
  "test the boomerang.}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_eventstudy.tex")
cat("Table 4 written.\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

dt_pre <- dt[year < 2019]
sd_gross_pre <- sd(dt_pre$ln_gross, na.rm = TRUE)
sd_net_pre <- sd(dt_pre$ln_net, na.rm = TRUE)
sd_gap_pre <- sd(dt_pre$ln_gap, na.rm = TRUE)
sd_exposure <- sd(dt$exposure)

sde_gross <- results$m1_reform$coef * sd_exposure / sd_gross_pre
se_sde_gross <- results$m1_reform$se * sd_exposure / sd_gross_pre

sde_net <- results$m2_reform$coef * sd_exposure / sd_net_pre
se_sde_net <- results$m2_reform$se * sd_exposure / sd_net_pre

sde_gap <- results$m3_reform$coef * sd_exposure / sd_gap_pre
se_sde_gap <- results$m3_reform$se * sd_exposure / sd_gap_pre

sde_post <- results$m1_post$coef * sd_exposure / sd_gross_pre
se_sde_post <- results$m1_post$se * sd_exposure / sd_gross_pre

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} North Macedonia. ",
  "\\textbf{Research question:} Does a temporary progressive income tax suppress reported wages in high-exposure sectors, and do wages rebound upon repeal? ",
  "\\textbf{Policy mechanism:} The January 2019 reform replaced a flat 10\\% personal income tax with a two-bracket system (10\\%/18\\% above MKD~90,000/month), increasing the marginal tax rate on high earners by 8 percentage points; full reversion to flat 10\\% in January 2020 creates a symmetric on-off experiment. ",
  "\\textbf{Outcome definition:} Log monthly gross wage per employee by NACE Rev.2 sector from Statistics North Macedonia, measuring average reported compensation including bonuses and supplements. ",
  "\\textbf{Treatment:} Continuous --- sector-level exposure defined as pre-reform (2018) mean gross wage divided by the MKD~90,000 threshold (range: 0.29 to 0.68). ",
  "\\textbf{Data:} Statistics North Macedonia PXWeb API, monthly sector-level wage data, 19 NACE sectors, 2012--2024 (156 months, ",
  formatC(nrow(dt), big.mark = ",", format = "d"),
  " sector-month observations). ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with sector and year-month fixed effects; inference via wild cluster bootstrap (Rademacher weights, 999 replications) and permutation inference (500 draws). ",
  "\\textbf{Sample:} All 19 NACE Rev.2 sectors with non-missing monthly gross wage data; no sample restrictions beyond balanced panel requirement. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sector standard deviation of exposure ",
  "and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Heterogeneity: Implied effects at high vs low exposure means
# From the main continuous-exposure model, the implied effect for a group is
# beta_1 × mean(exposure | group)
mean_exp_high <- mean(dt[high_exposure == 1, exposure])
mean_exp_low <- mean(dt[high_exposure == 0, exposure])

# Re-estimate main model
m_main <- feols(ln_gross ~ reform_x_exposure + post_x_exposure | sector + ym,
                data = dt, cluster = ~sector)
beta_reform <- coef(m_main)["reform_x_exposure"]
se_reform <- se(m_main)["reform_x_exposure"]

# Implied effects
implied_high <- beta_reform * mean_exp_high
se_implied_high <- se_reform * mean_exp_high
implied_low <- beta_reform * mean_exp_low
se_implied_low <- se_reform * mean_exp_low

sd_high_pre <- sd(dt[high_exposure == 1 & year < 2019, ln_gross], na.rm = TRUE)
sd_low_pre <- sd(dt[high_exposure == 0 & year < 2019, ln_gross], na.rm = TRUE)

sde_high <- implied_high / sd_high_pre
se_sde_high <- se_implied_high / sd_high_pre
sde_low <- implied_low / sd_low_pre
se_sde_low <- se_implied_low / sd_low_pre

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled Effects}} \\\\\n",
  sprintf("Gross wage (reform) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          results$m1_reform$coef, results$m1_reform$se, sd_gross_pre,
          sde_gross, se_sde_gross, classify_sde(sde_gross)),
  sprintf("Net wage (reform) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          results$m2_reform$coef, results$m2_reform$se, sd_net_pre,
          sde_net, se_sde_net, classify_sde(sde_net)),
  sprintf("Gross-net gap (reform) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          results$m3_reform$coef, results$m3_reform$se, sd_gap_pre,
          sde_gap, se_sde_gap, classify_sde(sde_gap)),
  sprintf("Gross wage (post-repeal) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          results$m1_post$coef, results$m1_post$se, sd_gross_pre,
          sde_post, se_sde_post, classify_sde(sde_post)),
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous Effects (Sample Splits)}} \\\\\n",
  sprintf("High-exposure sectors & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          implied_high, se_implied_high, sd_high_pre,
          sde_high, se_sde_high, classify_sde(sde_high)),
  sprintf("Low-exposure sectors & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          implied_low, se_implied_low, sd_low_pre,
          sde_low, se_sde_low, classify_sde(sde_low)),
  "\\hline\\hline\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\begin{itemize}[leftmargin=*]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "\\end{minipage}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
