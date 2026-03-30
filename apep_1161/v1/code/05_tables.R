# 05_tables.R — Generate all LaTeX tables
# apep_1161: The Compliance Upgrade

source("00_packages.R")

dir.create("../tables", showWarnings = FALSE)

# ---- Load results ----
summ <- readRDS("../data/summary_stats.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
cs_results <- readRDS("../data/cs_results.rds")

panel_pc <- fread("../data/analysis_panel_pc.csv")
panel_diesel <- fread("../data/analysis_panel_diesel.csv")
panel_petrol <- fread("../data/analysis_panel_petrol.csv")

# ---- Helper: format number ----
fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits, big.mark = ",")
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")
fmt_pct <- function(x) paste0(fmt(x * 100, 1), "\\%")

# Stars helper
stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.10) return("$^{*}$")
  return("")
}

# ================================================================
# TABLE 1: Summary Statistics
# ================================================================
pre_all <- panel_pc[year <= 2018]
pre_diesel <- panel_diesel[year <= 2018]
pre_petrol <- panel_petrol[year <= 2018]

t_areas <- summ$treated$n_areas
c_areas <- summ$control$n_areas

tab1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Pre-Treatment Period (2017--2018)}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
 & \\multicolumn{2}{c}{ULEZ/CAZ Areas} & \\multicolumn{2}{c}{Control Areas} & \\multicolumn{2}{c}{Difference} \\\\
 \\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}
 & Mean & SD & Mean & SD & Diff & SE \\\\
\\midrule
MOT failure rate & ", fmt(summ$treated$mean_fail), " & ", fmt(summ$treated$sd_fail), " & ",
  fmt(summ$control$mean_fail), " & ", fmt(summ$control$sd_fail), " & ",
  fmt(summ$treated$mean_fail - summ$control$mean_fail), " & --- \\\\
Average vehicle age (years) & ", fmt(summ$treated$mean_age, 1), " & --- & ",
  fmt(summ$control$mean_age, 1), " & --- & ",
  fmt(summ$treated$mean_age - summ$control$mean_age, 1), " & --- \\\\
Average test mileage & ", fmt_int(round(summ$treated$mean_mileage)), " & --- & ",
  fmt_int(round(summ$control$mean_mileage)), " & --- & ",
  fmt_int(round(summ$treated$mean_mileage - summ$control$mean_mileage)), " & --- \\\\
Tests per area-year & ", fmt_int(round(summ$treated$mean_tests)), " & --- & ",
  fmt_int(round(summ$control$mean_tests)), " & --- & ",
  fmt_int(round(summ$treated$mean_tests - summ$control$mean_tests)), " & --- \\\\
\\midrule
Number of areas & \\multicolumn{2}{c}{", t_areas, "} & \\multicolumn{2}{c}{", c_areas, "} & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Summary statistics for the pre-treatment period (2017--2018). ULEZ/CAZ areas are postcode areas subject to London's Ultra Low Emission Zone or Clean Air Zones in Birmingham and Bristol. Control areas are postcode areas in England and Wales never subject to an emission zone. MOT failure rate is the share of annual MOT tests resulting in a fail. Vehicle age and mileage are test-weighted averages.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ================================================================
# TABLE 2: Main Results — TWFE and Callaway-Sant'Anna
# ================================================================
# Extract coefficients
b_twfe <- coef(results$twfe)["treated"]
se_twfe <- se(results$twfe)["treated"]
p_twfe <- pvalue(results$twfe)["treated"]
n_twfe <- nobs(results$twfe)

b_cs <- cs_results$cs_agg$overall.att
se_cs <- cs_results$cs_agg$overall.se
p_cs <- 2 * pnorm(-abs(b_cs / se_cs))

b_diesel <- coef(results$diesel)["treated"]
se_diesel <- se(results$diesel)["treated"]
p_diesel <- pvalue(results$diesel)["treated"]

b_petrol <- coef(results$petrol)["treated"]
se_petrol <- se(results$petrol)["treated"]
p_petrol <- pvalue(results$petrol)["treated"]

b_age <- coef(results$age)["treated"]
se_age <- se(results$age)["treated"]
p_age <- pvalue(results$age)["treated"]

tab2 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Effect of Low Emission Zones on MOT Failure Rates}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & (1) & (2) & (3) & (4) & (5) \\\\
 & TWFE & C--S & Diesel & Petrol & Vehicle Age \\\\
\\midrule
Treated & ", fmt(b_twfe, 4), stars(p_twfe), " & ", fmt(b_cs, 4), stars(p_cs), " & ",
  fmt(b_diesel, 4), stars(p_diesel), " & ", fmt(b_petrol, 4), stars(p_petrol), " & ",
  fmt(b_age, 2), stars(p_age), " \\\\
 & (", fmt(se_twfe, 4), ") & (", fmt(se_cs, 4), ") & (",
  fmt(se_diesel, 4), ") & (", fmt(se_petrol, 4), ") & (",
  fmt(se_age, 2), ") \\\\
\\\\
Outcome & Fail rate & Fail rate & Fail rate & Fail rate & Avg age \\\\
Sample & All & All & Diesel & Petrol & All \\\\
Postcode area FE & Yes & --- & Yes & Yes & Yes \\\\
Year FE & Yes & --- & Yes & Yes & Yes \\\\
Estimator & TWFE & C--S & TWFE & TWFE & TWFE \\\\
Observations & ", fmt_int(n_twfe), " & ", fmt_int(nrow(panel_pc)), " & ",
  fmt_int(nobs(results$diesel)), " & ", fmt_int(nobs(results$petrol)), " & ",
  fmt_int(nobs(results$age)), " \\\\
Areas & ", fmt_int(uniqueN(panel_pc$postcode_area)), " & ",
  fmt_int(uniqueN(panel_pc$postcode_area)), " & ",
  fmt_int(uniqueN(panel_diesel$postcode_area)), " & ",
  fmt_int(uniqueN(panel_petrol$postcode_area)), " & ",
  fmt_int(uniqueN(panel_pc$postcode_area)), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the postcode-area level in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$. Column (1) reports two-way fixed effects (TWFE) estimates. Column (2) reports the Callaway and Sant'Anna (2021) group-time ATT aggregated to an overall treatment effect, using never-treated areas as the control group. Columns (3)--(4) split the sample by fuel type. Column (5) examines average vehicle age as the outcome, testing the fleet renewal channel. The dependent variable in columns (1)--(4) is the annual MOT failure rate (share of tests resulting in fail). Data cover 2017--2023.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ================================================================
# TABLE 3: Euro 4 Placebo — Diesel vs Petrol Same Vintage
# ================================================================
b_d4 <- coef(results$diesel_e4)["treated"]
se_d4 <- se(results$diesel_e4)["treated"]
p_d4 <- pvalue(results$diesel_e4)["treated"]

b_p4 <- coef(results$petrol_e4)["treated"]
se_p4 <- se(results$petrol_e4)["treated"]
p_p4 <- pvalue(results$petrol_e4)["treated"]

tab3 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{The Compliance Upgrade: Euro 4 Vehicles, Diesel vs.\\ Petrol}
\\label{tab:placebo}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & (1) & (2) \\\\
 & Diesel Euro 4 & Petrol Euro 4 \\\\
 & (Non-compliant) & (Compliant) \\\\
\\midrule
Treated & ", fmt(b_d4, 4), stars(p_d4), " & ", fmt(b_p4, 4), stars(p_p4), " \\\\
 & (", fmt(se_d4, 4), ") & (", fmt(se_p4, 4), ") \\\\
\\\\
Pre-treatment mean & ", fmt(mean(panel_diesel[year <= 2018 & euro4_tests >= 50]$euro4_fail_rate, na.rm=T), 3),
" & ", fmt(mean(panel_petrol[year <= 2018 & euro4_tests >= 50]$euro4_fail_rate, na.rm=T), 3), " \\\\
Observations & ", fmt_int(nobs(results$diesel_e4)), " & ", fmt_int(nobs(results$petrol_e4)), " \\\\
Areas & ", fmt_int(uniqueN(panel_diesel[euro4_tests >= 50]$postcode_area)),
" & ", fmt_int(uniqueN(panel_petrol[euro4_tests >= 50]$postcode_area)), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the postcode-area level in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$. Sample restricted to vehicles first registered 2006--2010 (Euro 4 era). Under ULEZ rules, Euro 4 diesel vehicles are non-compliant and face daily charges, while Euro 4 petrol vehicles are compliant. Both columns use TWFE with postcode-area and year fixed effects. The dependent variable is the failure rate among Euro 4 era vehicles. If the effect operates through fleet renewal of non-compliant vehicles, column (1) should show a negative effect and column (2) should show no effect.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tab3, "../tables/tab3_placebo.tex")

# ================================================================
# TABLE 4: Robustness
# ================================================================
b_nol <- coef(rob$no_london)["treated"]
se_nol <- se(rob$no_london)["treated"]
p_nol <- pvalue(rob$no_london)["treated"]

b_2w <- coef(rob$twoway)["treated"]
se_2w <- se(rob$twoway)["treated"]
p_2w <- pvalue(rob$twoway)["treated"]

b_np1 <- coef(rob$no_phase1)["treated"]
se_np1 <- se(rob$no_phase1)["treated"]
p_np1 <- pvalue(rob$no_phase1)["treated"]

b_wt <- coef(rob$weighted)["treated"]
se_wt <- se(rob$weighted)["treated"]
p_wt <- pvalue(rob$weighted)["treated"]

wcb_p <- if (!is.null(rob$wcb)) fmt(rob$wcb$cluster_p, 3) else "---"

tab4 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Robustness of Main Result}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & Exclude London & Two-way cluster & Exclude Phase 1 & Test-weighted \\\\
\\midrule
Treated & ", fmt(b_nol, 4), stars(p_nol), " & ", fmt(b_2w, 4), stars(p_2w), " & ",
  fmt(b_np1, 4), stars(p_np1), " & ", fmt(b_wt, 4), stars(p_wt), " \\\\
 & (", fmt(se_nol, 4), ") & (", fmt(se_2w, 4), ") & (",
  fmt(se_np1, 4), ") & (", fmt(se_wt, 4), ") \\\\
\\\\
Baseline coef & \\multicolumn{4}{c}{", fmt(b_twfe, 4), "} \\\\
WCB $p$-value & \\multicolumn{4}{c}{", wcb_p, "} \\\\
Observations & ", fmt_int(nobs(rob$no_london)), " & ", fmt_int(n_twfe),
  " & ", fmt_int(nobs(rob$no_phase1)), " & ", fmt_int(nobs(rob$weighted)), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All specifications use TWFE with postcode-area and year fixed effects. Standard errors in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$. Column (1) excludes all London postcode areas, retaining only Birmingham (B) and Bristol (BS) as treated. Column (2) clusters standard errors by both postcode area and year. Column (3) excludes Phase 1 areas (EC, WC). Column (4) weights by number of tests. WCB $p$-value is from the Webb 6-point wild cluster bootstrap with 9,999 replications.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tab4, "../tables/tab4_robustness.tex")

# ================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ================================================================
# Compute SDE for main outcome
sd_y <- sd(panel_pc[year <= 2018]$fail_rate)
sde_main <- b_twfe / sd_y
se_sde_main <- se_twfe / sd_y

# Diesel SDE
sd_y_diesel <- sd(panel_diesel[year <= 2018]$fail_rate)
sde_diesel <- b_diesel / sd_y_diesel
se_sde_diesel <- se_diesel / sd_y_diesel

# Petrol SDE (placebo)
sd_y_petrol <- sd(panel_petrol[year <= 2018]$fail_rate)
sde_petrol <- b_petrol / sd_y_petrol
se_sde_petrol <- se_petrol / sd_y_petrol

# Vehicle age SDE
sd_y_age <- sd(panel_pc[year <= 2018]$avg_age, na.rm = TRUE)
sde_age <- b_age / sd_y_age
se_sde_age <- se_age / sd_y_age

# Euro 4 diesel heterogeneity
sd_y_d4 <- sd(panel_diesel[year <= 2018 & euro4_tests >= 50]$euro4_fail_rate, na.rm = TRUE)
sde_d4 <- b_d4 / sd_y_d4
se_sde_d4 <- se_d4 / sd_y_d4

# Euro 4 petrol heterogeneity
sd_y_p4 <- sd(panel_petrol[year <= 2018 & euro4_tests >= 50]$euro4_fail_rate, na.rm = TRUE)
sde_p4 <- b_p4 / sd_y_p4
se_sde_p4 <- se_p4 / sd_y_p4

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

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Do low emission zones improve vehicle safety by forcing fleet renewal, as measured by MOT failure rates across postcode areas? ",
  "\\textbf{Policy mechanism:} London's ULEZ and UK Clean Air Zones impose daily charges on non-compliant vehicles (pre-Euro 4 petrol, pre-Euro 6 diesel), creating strong financial incentives to scrap older vehicles and replace them with newer, inherently safer ones. ",
  "\\textbf{Outcome definition:} Annual MOT failure rate at the postcode-area level, defined as the share of tests resulting in a fail verdict. ",
  "\\textbf{Treatment:} Binary; postcode area is treated from the year its emission zone becomes active. ",
  "\\textbf{Data:} DVSA Anonymised MOT Test Results, 2017--2023, postcode-area by year by fuel-type aggregates constructed from individual test records. ",
  "\\textbf{Method:} Two-way fixed effects and Callaway--Sant'Anna (2021) staggered DiD, standard errors clustered at the postcode-area level. ",
  "\\textbf{Sample:} England and Wales postcode areas with at least 1,000 MOT tests per year; petrol and diesel vehicles only. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2017--2018) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llcccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\
MOT failure rate & TWFE (all) & ", fmt(b_twfe, 4), " & ", fmt(se_twfe, 4), " & ", fmt(sd_y, 4),
  " & ", fmt(sde_main, 3), " & ", fmt(se_sde_main, 3), " & ", classify(sde_main), " \\\\
MOT failure rate & Diesel only & ", fmt(b_diesel, 4), " & ", fmt(se_diesel, 4), " & ", fmt(sd_y_diesel, 4),
  " & ", fmt(sde_diesel, 3), " & ", fmt(se_sde_diesel, 3), " & ", classify(sde_diesel), " \\\\
MOT failure rate & Petrol only & ", fmt(b_petrol, 4), " & ", fmt(se_petrol, 4), " & ", fmt(sd_y_petrol, 4),
  " & ", fmt(sde_petrol, 3), " & ", fmt(se_sde_petrol, 3), " & ", classify(sde_petrol), " \\\\
Vehicle age & TWFE (all) & ", fmt(b_age, 2), " & ", fmt(se_age, 2), " & ", fmt(sd_y_age, 2),
  " & ", fmt(sde_age, 3), " & ", fmt(se_sde_age, 3), " & ", classify(sde_age), " \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (Euro 4 era vehicles, 2006--2010 registration)}} \\\\
Euro 4 fail rate & Diesel (non-compliant) & ", fmt(b_d4, 4), " & ", fmt(se_d4, 4), " & ", fmt(sd_y_d4, 4),
  " & ", fmt(sde_d4, 3), " & ", fmt(se_sde_d4, 3), " & ", classify(sde_d4), " \\\\
Euro 4 fail rate & Petrol (compliant) & ", fmt(b_p4, 4), " & ", fmt(se_p4, 4), " & ", fmt(sd_y_p4, 4),
  " & ", fmt(sde_p4, 3), " & ", fmt(se_sde_p4, 3), " & ", classify(sde_p4), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
