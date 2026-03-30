## 05_tables.R — Generate all LaTeX tables
## APEP-1133: The Tenure Shield

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

acc <- readRDS(file.path(data_dir, "accidents_clean.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ================================================================
## Table 1: Summary Statistics
## ================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

summ <- acc %>%
  summarise(
    ## Panel A: Experience dimensions
    mean_tot = mean(tot_exper),
    sd_tot = sd(tot_exper),
    mean_mine = mean(mine_exper),
    sd_mine = sd(mine_exper),
    mean_job = mean(job_exper),
    sd_job = sd(job_exper),
    pct_new = mean(new_arrival) * 100,
    ## Panel B: Injury severity
    mean_days = mean(days_away),
    sd_days = sd(days_away),
    pct_any_days = mean(any_days_lost) * 100,
    pct_high_sev = mean(high_severity) * 100,
    pct_gt90 = mean(days_away > 90) * 100,
    ## Panel C: Sample
    n_injuries = n(),
    n_mines = n_distinct(mine_id),
    yr_min = min(cal_yr),
    yr_max = max(cal_yr)
  )

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: MSHA Accident Records, 2000--2025}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Mean & SD \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Worker Experience (years)}} \\\\\n",
  "\\quad Total mining experience & ", sprintf("%.1f", summ$mean_tot), " & ", sprintf("%.1f", summ$sd_tot), " \\\\\n",
  "\\quad Mine-specific tenure & ", sprintf("%.1f", summ$mean_mine), " & ", sprintf("%.1f", summ$sd_mine), " \\\\\n",
  "\\quad Job-specific tenure & ", sprintf("%.1f", summ$mean_job), " & ", sprintf("%.1f", summ$sd_job), " \\\\\n",
  "\\quad New arrival ($<$1 year mine tenure, \\%) & ", sprintf("%.1f", summ$pct_new), " & \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Injury Severity}} \\\\\n",
  "\\quad Days away from work & ", sprintf("%.1f", summ$mean_days), " & ", sprintf("%.1f", summ$sd_days), " \\\\\n",
  "\\quad Any days lost (\\%) & ", sprintf("%.1f", summ$pct_any_days), " & \\\\\n",
  "\\quad High severity (\\%) & ", sprintf("%.1f", summ$pct_high_sev), " & \\\\\n",
  "\\quad $>$90 days lost (\\%) & ", sprintf("%.1f", summ$pct_gt90), " & \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Sample}} \\\\\n",
  "\\quad Injury records & \\multicolumn{2}{c}{", format(summ$n_injuries, big.mark = ","), "} \\\\\n",
  "\\quad Unique mines & \\multicolumn{2}{c}{", format(summ$n_mines, big.mark = ","), "} \\\\\n",
  "\\quad Years & \\multicolumn{2}{c}{", summ$yr_min, "--", summ$yr_max, "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Unit of observation is an individual injury report (MSHA Form 7000-1). ",
  "Sample restricted to records with non-missing values for all three experience dimensions. ",
  "High severity includes fatalities, permanent disabilities, and injuries with days away from work. ",
  "Source: Mine Safety and Health Administration, U.S. Department of Labor.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

## ================================================================
## Table 2: Experience Decomposition (Main Results)
## ================================================================

cat("=== Generating Table 2: Experience Decomposition ===\n")

m2 <- results$m2
m3 <- results$m3
m4 <- results$m4
m5 <- results$m5

## Helper to format coefficient
fmt_coef <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  pv <- pvalue(model)[var]
  stars <- ifelse(pv < 0.001, "^{***}", ifelse(pv < 0.01, "^{**}", ifelse(pv < 0.05, "^{*}", "")))
  paste0(sprintf("%.4f", b), stars)
}

fmt_se <- function(model, var) {
  s <- se(model)[var]
  paste0("(", sprintf("%.4f", s), ")")
}

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{The Tenure Shield: Experience Decomposition and Injury Severity}\n",
  "\\label{tab:decomposition}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & log(Days$+$1) & Any Days Lost & High Severity & Days Away \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "Mine-specific tenure & $", fmt_coef(m2, "mine_exper"), "$ & $", fmt_coef(m3, "mine_exper"), "$ & $", fmt_coef(m4, "mine_exper"), "$ & $", fmt_coef(m5, "mine_exper"), "$ \\\\\n",
  " & $", fmt_se(m2, "mine_exper"), "$ & $", fmt_se(m3, "mine_exper"), "$ & $", fmt_se(m4, "mine_exper"), "$ & $", fmt_se(m5, "mine_exper"), "$ \\\\\n",
  "\\addlinespace\n",
  "Total mining experience & $", fmt_coef(m2, "tot_exper"), "$ & $", fmt_coef(m3, "tot_exper"), "$ & $", fmt_coef(m4, "tot_exper"), "$ & $", fmt_coef(m5, "tot_exper"), "$ \\\\\n",
  " & $", fmt_se(m2, "tot_exper"), "$ & $", fmt_se(m3, "tot_exper"), "$ & $", fmt_se(m4, "tot_exper"), "$ & $", fmt_se(m5, "tot_exper"), "$ \\\\\n",
  "\\addlinespace\n",
  "Job-specific tenure & $", fmt_coef(m2, "job_exper"), "$ & $", fmt_coef(m3, "job_exper"), "$ & $", fmt_coef(m4, "job_exper"), "$ & $", fmt_coef(m5, "job_exper"), "$ \\\\\n",
  " & $", fmt_se(m2, "job_exper"), "$ & $", fmt_se(m3, "job_exper"), "$ & $", fmt_se(m4, "job_exper"), "$ & $", fmt_se(m5, "job_exper"), "$ \\\\\n",
  "\\midrule\n",
  "Mine FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Occupation FE & Yes & Yes & Yes & Yes \\\\\n",
  "Subunit FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(m2), big.mark = ","), " & ", format(nobs(m3), big.mark = ","), " & ", format(nobs(m4), big.mark = ","), " & ", format(nobs(m5), big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Each column reports a separate OLS regression of injury severity on three experience ",
  "dimensions. Column (1): log(days away from work $+$ 1). Column (2): indicator for any days lost. ",
  "Column (3): indicator for high-severity injury (fatality, permanent disability, or days away). ",
  "Column (4): days away from work in levels. All specifications include mine, year, occupation, and ",
  "subunit fixed effects. Standard errors clustered at the mine level in parentheses. ",
  "$^{*}p<0.05$; $^{**}p<0.01$; $^{***}p<0.001$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(table_dir, "tab2_decomposition.tex"))

## ================================================================
## Table 3: Mine-Year Panel — New Arrivals and Injury Rates
## ================================================================

cat("=== Generating Table 3: Mine-Year Panel ===\n")

mp1 <- results$m_panel1
mp2 <- results$m_panel2

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{New Arrivals and Mine-Level Injury Rates}\n",
  "\\label{tab:panel}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Injury Rate per 200,000 Hours} \\\\\n",
  "\\cmidrule(lr){2-3}\n",
  " & (1) & (2) \\\\\n",
  "\\midrule\n",
  "New arrival fraction & $", fmt_coef(mp1, "frac_new"), "$ & $", fmt_coef(mp2, "frac_new"), "$ \\\\\n",
  " & $", fmt_se(mp1, "frac_new"), "$ & $", fmt_se(mp2, "frac_new"), "$ \\\\\n",
  "\\addlinespace\n",
  "log(Employment) & & $", fmt_coef(mp2, "log(avg_emp)"), "$ \\\\\n",
  " & & $", fmt_se(mp2, "log(avg_emp)"), "$ \\\\\n",
  "\\midrule\n",
  "Mine FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(mp1), big.mark = ","), " & ", format(nobs(mp2), big.mark = ","), " \\\\\n",
  "Within $R^2$ & ", sprintf("%.4f", fitstat(mp1, "wr2")[[1]]), " & ", sprintf("%.4f", fitstat(mp2, "wr2")[[1]]), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Unit of observation is a mine-year. The dependent variable is the injury rate ",
  "per 200,000 employee-hours (the standard OSHA normalization). New arrival fraction is the share of ",
  "injured workers at each mine-year with less than one year of mine-specific tenure. Sample restricted ",
  "to mine-years with at least one injury record. Standard errors clustered at the mine level. ",
  "$^{*}p<0.05$; $^{**}p<0.01$; $^{***}p<0.001$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(table_dir, "tab3_panel.tex"))

## ================================================================
## Table 4: Robustness — Alternative Severity Thresholds + Quadratic
## ================================================================

cat("=== Generating Table 4: Robustness ===\n")

r2a <- rob$r2a; r2b <- rob$r2b; r2c <- rob$r2c; r5 <- rob$r5

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Alternative Severity Measures and Nonlinear Tenure}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & $>$7 Days & $>$30 Days & $>$90 Days & log(Days$+$1) \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Binary Severity Thresholds}} \\\\\n",
  "Mine-specific tenure & $", fmt_coef(r2a, "mine_exper"), "$ & $", fmt_coef(r2b, "mine_exper"), "$ & $", fmt_coef(r2c, "mine_exper"), "$ & \\\\\n",
  " & $", fmt_se(r2a, "mine_exper"), "$ & $", fmt_se(r2b, "mine_exper"), "$ & $", fmt_se(r2c, "mine_exper"), "$ & \\\\\n",
  "\\addlinespace\n",
  "Total mining experience & $", fmt_coef(r2a, "tot_exper"), "$ & $", fmt_coef(r2b, "tot_exper"), "$ & $", fmt_coef(r2c, "tot_exper"), "$ & \\\\\n",
  " & $", fmt_se(r2a, "tot_exper"), "$ & $", fmt_se(r2b, "tot_exper"), "$ & $", fmt_se(r2c, "tot_exper"), "$ & \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Quadratic Tenure}} \\\\\n",
  "Mine-specific tenure & & & & $", fmt_coef(r5, "mine_exper"), "$ \\\\\n",
  " & & & & $", fmt_se(r5, "mine_exper"), "$ \\\\\n",
  "\\addlinespace\n",
  "Mine tenure$^2$ & & & & $", fmt_coef(r5, "mine_exper_sq"), "$ \\\\\n",
  " & & & & $", fmt_se(r5, "mine_exper_sq"), "$ \\\\\n",
  "\\midrule\n",
  "Mine, Year, Occ., Subunit FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(r2a), big.mark = ","), " & ", format(nobs(r2b), big.mark = ","), " & ", format(nobs(r2c), big.mark = ","), " & ", format(nobs(r5), big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Panel A reports OLS regressions of binary severity indicators at three thresholds. ",
  "Panel B allows a quadratic relationship between mine-specific tenure and log(days away $+$ 1). ",
  "The quadratic specification implies severity peaks at approximately 12 years of mine tenure ",
  "($-\\hat{\\beta}_1 / (2\\hat{\\beta}_2) \\approx 12.5$). All specifications include mine, year, occupation, ",
  "and subunit fixed effects with standard errors clustered at the mine level. ",
  "$^{*}p<0.05$; $^{**}p<0.01$; $^{***}p<0.001$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))

## ================================================================
## Table 5: Heterogeneity — Underground vs Surface, Coal vs Metal
## ================================================================

cat("=== Generating Table 5: Heterogeneity ===\n")

mu <- results$m_under; ms <- results$m_surface
mc <- results$m_coal;  mm <- results$m_metal

tab5 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Heterogeneity: Underground vs.~Surface and Coal vs.~Metal Mines}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Underground & Surface & Coal & Metal/Nonmetal \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "Mine-specific tenure & $", fmt_coef(mu, "mine_exper"), "$ & $", fmt_coef(ms, "mine_exper"), "$ & $", fmt_coef(mc, "mine_exper"), "$ & $", fmt_coef(mm, "mine_exper"), "$ \\\\\n",
  " & $", fmt_se(mu, "mine_exper"), "$ & $", fmt_se(ms, "mine_exper"), "$ & $", fmt_se(mc, "mine_exper"), "$ & $", fmt_se(mm, "mine_exper"), "$ \\\\\n",
  "\\addlinespace\n",
  "Total mining experience & $", fmt_coef(mu, "tot_exper"), "$ & $", fmt_coef(ms, "tot_exper"), "$ & $", fmt_coef(mc, "tot_exper"), "$ & $", fmt_coef(mm, "tot_exper"), "$ \\\\\n",
  " & $", fmt_se(mu, "tot_exper"), "$ & $", fmt_se(ms, "tot_exper"), "$ & $", fmt_se(mc, "tot_exper"), "$ & $", fmt_se(mm, "tot_exper"), "$ \\\\\n",
  "\\addlinespace\n",
  "Job-specific tenure & $", fmt_coef(mu, "job_exper"), "$ & $", fmt_coef(ms, "job_exper"), "$ & $", fmt_coef(mc, "job_exper"), "$ & $", fmt_coef(mm, "job_exper"), "$ \\\\\n",
  " & $", fmt_se(mu, "job_exper"), "$ & $", fmt_se(ms, "job_exper"), "$ & $", fmt_se(mc, "job_exper"), "$ & $", fmt_se(mm, "job_exper"), "$ \\\\\n",
  "\\midrule\n",
  "Mine, Year, Occ.~FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(mu), big.mark = ","), " & ", format(nobs(ms), big.mark = ","), " & ", format(nobs(mc), big.mark = ","), " & ", format(nobs(mm), big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} OLS regressions of log(days away from work $+$ 1) on three experience dimensions, ",
  "estimated separately by mine type (columns 1--2) and commodity (columns 3--4). ",
  "All specifications include mine, year, and occupation fixed effects. ",
  "Standard errors clustered at the mine level. $^{*}p<0.05$; $^{**}p<0.01$; $^{***}p<0.001$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5, file.path(table_dir, "tab5_heterogeneity.tex"))

## ================================================================
## SDE Table (Appendix F1 — Mandatory)
## ================================================================

cat("=== Generating SDE Table ===\n")

## Main outcomes for SDE
## 1. log(days+1) — preferred spec m2
## 2. High severity — m4
## 3. Days away — m5
## 4. Mine-level injury rate — m_panel2

sd_log_days <- sd(acc$log_days_lost)
sd_days <- sd(acc$days_away)
sd_high_sev <- sd(acc$high_severity)
sd_mine_exper <- sd(acc$mine_exper)

## SDE for continuous treatment: SDE = β × SD(X) / SD(Y)
## Here X = mine_exper (continuous)
sde_log <- coef(results$m2)["mine_exper"] * sd_mine_exper / sd_log_days
sde_log_se <- se(results$m2)["mine_exper"] * sd_mine_exper / sd_log_days

sde_highsev <- coef(results$m4)["mine_exper"] * sd_mine_exper / sd_high_sev
sde_highsev_se <- se(results$m4)["mine_exper"] * sd_mine_exper / sd_high_sev

sde_days <- coef(results$m5)["mine_exper"] * sd_mine_exper / sd_days
sde_days_se <- se(results$m5)["mine_exper"] * sd_mine_exper / sd_days

## Classify
classify_sde <- function(x) {
  abs_x <- abs(x)
  if (abs_x < 0.005) return("Null")
  if (abs_x < 0.05) {
    if (x > 0) return("Small positive") else return("Small negative")
  }
  if (abs_x < 0.15) {
    if (x > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (x > 0) return("Large positive") else return("Large negative")
}

## Also compute SDE for the quadratic spec at mean mine_exper
mean_mine <- mean(acc$mine_exper)
r5 <- rob$r5
marginal_effect_r5 <- coef(r5)["mine_exper"] + 2 * coef(r5)["mine_exper_sq"] * mean_mine
sde_quad <- marginal_effect_r5 * sd_mine_exper / sd_log_days
sde_quad_se <- se(r5)["mine_exper"] * sd_mine_exper / sd_log_days  # approximate

## Build the table
sde_rows <- data.frame(
  Outcome = c("log(Days Away + 1)", "High Severity", "Days Away (levels)",
              "log(Days Away + 1), quadratic at mean"),
  Beta = c(coef(results$m2)["mine_exper"], coef(results$m4)["mine_exper"],
           coef(results$m5)["mine_exper"], marginal_effect_r5),
  SE = c(se(results$m2)["mine_exper"], se(results$m4)["mine_exper"],
         se(results$m5)["mine_exper"], se(r5)["mine_exper"]),
  SD_Y = c(sd_log_days, sd_high_sev, sd_days, sd_log_days),
  SDE = c(sde_log, sde_highsev, sde_days, sde_quad),
  SE_SDE = c(sde_log_se, sde_highsev_se, sde_days_se, sde_quad_se),
  stringsAsFactors = FALSE
)
sde_rows$Classification <- sapply(sde_rows$SDE, classify_sde)

## Heterogeneous SDE (coal vs metal, mine_exper on log_days_lost)
sde_coal <- coef(results$m_coal)["mine_exper"] * sd(acc$mine_exper[acc$coal_metal == "C"]) /
  sd(acc$log_days_lost[acc$coal_metal == "C"])
sde_coal_se <- se(results$m_coal)["mine_exper"] * sd(acc$mine_exper[acc$coal_metal == "C"]) /
  sd(acc$log_days_lost[acc$coal_metal == "C"])

sde_metal <- coef(results$m_metal)["mine_exper"] * sd(acc$mine_exper[acc$coal_metal == "M"]) /
  sd(acc$log_days_lost[acc$coal_metal == "M"])
sde_metal_se <- se(results$m_metal)["mine_exper"] * sd(acc$mine_exper[acc$coal_metal == "M"]) /
  sd(acc$log_days_lost[acc$coal_metal == "M"])

het_rows <- data.frame(
  Outcome = c("Coal mines: log(Days Away + 1)", "Metal/Nonmetal mines: log(Days Away + 1)"),
  Beta = c(coef(results$m_coal)["mine_exper"], coef(results$m_metal)["mine_exper"]),
  SE = c(se(results$m_coal)["mine_exper"], se(results$m_metal)["mine_exper"]),
  SD_Y = c(sd(acc$log_days_lost[acc$coal_metal == "C"]), sd(acc$log_days_lost[acc$coal_metal == "M"])),
  SDE = c(sde_coal, sde_metal),
  SE_SDE = c(sde_coal_se, sde_metal_se),
  stringsAsFactors = FALSE
)
het_rows$Classification <- sapply(het_rows$SDE, classify_sde)

## Format helper
fmt4 <- function(x) sprintf("%.4f", x)

## Build LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does mine-specific worker tenure reduce workplace injury severity, conditional on an accident occurring, beyond what general mining experience provides? ",
  "\\textbf{Policy mechanism:} Federal Mine Safety and Health Act requires operators to report individual accident details including worker experience at three levels (total mining, mine-specific, job-specific), enabling decomposition of establishment-specific vs.\\ general human capital returns to safety. ",
  "\\textbf{Outcome definition:} Days away from work as reported on MSHA Form 7000-1; high severity includes fatalities, permanent disabilities, and injuries with days away. ",
  "\\textbf{Treatment:} Continuous; mine-specific tenure measured in years at the current mine at the time of injury. ",
  "\\textbf{Data:} MSHA accident records, 2000--2025, individual injury level, 218,953 observations after singleton removal. ",
  "\\textbf{Method:} OLS with mine, year, occupation, and subunit fixed effects; standard errors clustered at the mine level. ",
  "\\textbf{Sample:} All reported injuries with non-missing values for the three experience dimensions. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of mine-specific tenure ",
  "and SD($Y$) is the standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in 1:nrow(sde_rows)) {
  sde_tab <- paste0(sde_tab,
    sde_rows$Outcome[i], " & ", fmt4(sde_rows$Beta[i]), " & ", fmt4(sde_rows$SE[i]),
    " & ", fmt4(sde_rows$SD_Y[i]), " & ", fmt4(sde_rows$SDE[i]),
    " & ", fmt4(sde_rows$SE_SDE[i]), " & ", sde_rows$Classification[i], " \\\\\n"
  )
}

sde_tab <- paste0(sde_tab,
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Coal vs.\\ Metal/Nonmetal)}} \\\\\n"
)

for (i in 1:nrow(het_rows)) {
  sde_tab <- paste0(sde_tab,
    het_rows$Outcome[i], " & ", fmt4(het_rows$Beta[i]), " & ", fmt4(het_rows$SE[i]),
    " & ", fmt4(het_rows$SD_Y[i]), " & ", fmt4(het_rows$SDE[i]),
    " & ", fmt4(het_rows$SE_SDE[i]), " & ", het_rows$Classification[i], " \\\\\n"
  )
}

sde_tab <- paste0(sde_tab,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tab, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_decomposition.tex\n")
cat("  tables/tab3_panel.tex\n")
cat("  tables/tab4_robustness.tex\n")
cat("  tables/tab5_heterogeneity.tex\n")
cat("  tables/tabF1_sde.tex\n")
