# ==============================================================================
# 05_tables.R — Generate LaTeX tables
# Paper: Frictionless Highways (apep_0798)
# ==============================================================================

source("code/00_packages.R")

data_dir <- "data"
table_dir <- "tables"
dir.create(table_dir, showWarnings = FALSE)

# ── Load Data and Results ────────────────────────────────────────────────────
mob <- fread(file.path(data_dir, "mobility_weekly_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))
district_treat <- fread(file.path(data_dir, "district_treatment.csv"))

# ── TABLE 1: Summary Statistics ──────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

# Panel A: District characteristics
treated_dist <- mob[has_plaza == 1, unique(sub_region_2)]
control_dist <- mob[has_plaza == 0, unique(sub_region_2)]

# Panel B: Mobility outcomes by period
summ_data <- mob[, .(
  transit_mean = mean(transit, na.rm = TRUE),
  transit_sd = sd(transit, na.rm = TRUE),
  workplace_mean = mean(workplace, na.rm = TRUE),
  workplace_sd = sd(workplace, na.rm = TRUE),
  retail_mean = mean(retail, na.rm = TRUE),
  retail_sd = sd(retail, na.rm = TRUE),
  n_dist = uniqueN(sub_region_2),
  n_obs = .N
), by = .(has_plaza, post_mandate)]

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\small\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Pre-Mandate} & \\multicolumn{2}{c}{Post-Mandate} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Plaza & No Plaza & Plaza & No Plaza \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: District Characteristics}} \\\\\n",
  sprintf("Districts & %d & %d & %d & %d \\\\\n",
          length(treated_dist), length(control_dist),
          length(treated_dist), length(control_dist)),
  sprintf("Total toll plazas & %d & 0 & %d & 0 \\\\\n",
          sum(district_treat$n_plazas), sum(district_treat$n_plazas)),
  sprintf("Mean plazas/district & %.1f & --- & %.1f & --- \\\\\n",
          mean(district_treat$n_plazas), mean(district_treat$n_plazas)),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Mobility (\\% change from baseline)}} \\\\\n",
  sprintf("Transit stations & %.1f & %.1f & %.1f & %.1f \\\\\n",
          summ_data[has_plaza == 1 & post_mandate == 0]$transit_mean,
          summ_data[has_plaza == 0 & post_mandate == 0]$transit_mean,
          summ_data[has_plaza == 1 & post_mandate == 1]$transit_mean,
          summ_data[has_plaza == 0 & post_mandate == 1]$transit_mean),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\\n",
          summ_data[has_plaza == 1 & post_mandate == 0]$transit_sd,
          summ_data[has_plaza == 0 & post_mandate == 0]$transit_sd,
          summ_data[has_plaza == 1 & post_mandate == 1]$transit_sd,
          summ_data[has_plaza == 0 & post_mandate == 1]$transit_sd),
  sprintf("Workplaces & %.1f & %.1f & %.1f & %.1f \\\\\n",
          summ_data[has_plaza == 1 & post_mandate == 0]$workplace_mean,
          summ_data[has_plaza == 0 & post_mandate == 0]$workplace_mean,
          summ_data[has_plaza == 1 & post_mandate == 1]$workplace_mean,
          summ_data[has_plaza == 0 & post_mandate == 1]$workplace_mean),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\\n",
          summ_data[has_plaza == 1 & post_mandate == 0]$workplace_sd,
          summ_data[has_plaza == 0 & post_mandate == 0]$workplace_sd,
          summ_data[has_plaza == 1 & post_mandate == 1]$workplace_sd,
          summ_data[has_plaza == 0 & post_mandate == 1]$workplace_sd),
  sprintf("Retail \\& recreation & %.1f & %.1f & %.1f & %.1f \\\\\n",
          summ_data[has_plaza == 1 & post_mandate == 0]$retail_mean,
          summ_data[has_plaza == 0 & post_mandate == 0]$retail_mean,
          summ_data[has_plaza == 1 & post_mandate == 1]$retail_mean,
          summ_data[has_plaza == 0 & post_mandate == 1]$retail_mean),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\\n",
          summ_data[has_plaza == 1 & post_mandate == 0]$retail_sd,
          summ_data[has_plaza == 0 & post_mandate == 0]$retail_sd,
          summ_data[has_plaza == 1 & post_mandate == 1]$retail_sd,
          summ_data[has_plaza == 0 & post_mandate == 1]$retail_sd),
  "\\addlinespace\n",
  sprintf("District-weeks & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(sum(summ_data[post_mandate == 0]$n_obs), big.mark = ","),
          format(sum(summ_data[post_mandate == 1]$n_obs), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Standard deviations in parentheses. ",
  "Mobility measures are percentage changes from pre-pandemic baseline (median of Jan 3--Feb 6, 2020). ",
  "``Plaza'' districts contain at least one NHAI toll plaza; ``No Plaza'' districts contain none. ",
  sprintf("Data: Google Community Mobility Reports, Feb 2020--Oct 2022, %d Indian districts. ",
          uniqueN(mob$sub_region_2)),
  "Pre-mandate: before Feb 16, 2021; Post-mandate: on or after Feb 16, 2021.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ── TABLE 2: Main DiD Results ────────────────────────────────────────────────
cat("Generating Table 2: Main DiD Results...\n")

# Extract coefficients and SEs
get_coef <- function(model) {
  ct <- coeftable(model)
  list(
    beta = ct[1, "Estimate"],
    se = ct[1, "Std. Error"],
    pval = ct[1, "Pr(>|t|)"],
    n = model$nobs,
    r2 = fitstat(model, "r2")[[1]],
    adj_r2 = fitstat(model, "ar2")[[1]]
  )
}

m1 <- get_coef(results$did1)
m2 <- get_coef(results$did2)
m3 <- get_coef(results$did3)
m4 <- get_coef(results$did_work)
m5 <- get_coef(results$did_retail)
m6 <- get_coef(results$did_resid)

stars <- function(p) {
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.1) return("^{*}")
  return("")
}

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of FASTag Mandate on Local Mobility}\n",
  "\\label{tab:main_did}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{Transit Stations} & Workplace & Retail & Residential \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-5} \\cmidrule(lr){6-6} \\cmidrule(lr){7-7}\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\midrule\n",
  sprintf("Has Plaza $\\times$ Post & $%.3f%s$ & $%.3f%s$ & & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ \\\\\n",
          m1$beta, stars(m1$pval), m2$beta, stars(m2$pval),
          m4$beta, stars(m4$pval), m5$beta, stars(m5$pval), m6$beta, stars(m6$pval)),
  sprintf(" & (%.3f) & (%.3f) & & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          m1$se, m2$se, m4$se, m5$se, m6$se),
  sprintf("Plazas (std) $\\times$ Post & & & $%.3f%s$ & & & \\\\\n",
          m3$beta, stars(m3$pval)),
  sprintf(" & & & (%.3f) & & & \\\\\n", m3$se),
  "\\addlinespace\n",
  "District FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Week FE & Yes & --- & --- & --- & --- & --- \\\\\n",
  "State $\\times$ Week FE & --- & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "\\addlinespace\n",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
          format(m1$n, big.mark = ","), format(m2$n, big.mark = ","),
          format(m3$n, big.mark = ","), format(m4$n, big.mark = ","),
          format(m5$n, big.mark = ","), format(m6$n, big.mark = ",")),
  sprintf("Adj.\\ $R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
          m1$adj_r2, m2$adj_r2, m3$adj_r2, m4$adj_r2, m5$adj_r2, m6$adj_r2),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$. ",
  "Standard errors clustered at the state level in parentheses. ",
  "Dependent variable: weekly mobility (\\% change from pre-pandemic baseline). ",
  "``Has Plaza'' = 1 if district contains $\\geq 1$ NHAI toll plaza. ",
  "``Post'' = 1 for weeks on or after February 16, 2021. ",
  "Column (3) uses standardized total plaza traffic capacity as continuous treatment. ",
  "Column (6) is a placebo: residential time should move opposite to economic activity.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(table_dir, "tab2_main_did.tex"))

# ── TABLE 3: Robustness ─────────────────────────────────────────────────────
cat("Generating Table 3: Robustness...\n")

rob_specs <- list(
  list(name = "Placebo: Oct 2020", model = rob_results$placebo_oct),
  list(name = "Placebo: Aug 2020", model = rob_results$placebo_aug),
  list(name = "Highway states only", model = rob_results$highway_only),
  list(name = "Drop Delta wave", model = rob_results$no_delta),
  list(name = "Cluster: district", model = rob_results$dist_cluster),
  list(name = "Log(1+plazas)", model = rob_results$log_plazas),
  list(name = "Short pre-period", model = rob_results$short_window)
)

tab3_rows <- ""
for (spec in rob_specs) {
  ct <- coeftable(spec$model)
  beta <- ct[1, "Estimate"]
  se_val <- ct[1, "Std. Error"]
  pval <- ct[1, "Pr(>|t|)"]
  n <- spec$model$nobs

  tab3_rows <- paste0(tab3_rows,
    sprintf("%s & $%.3f%s$ & (%.3f) & %s \\\\\n",
            spec$name, beta, stars(pval), se_val, format(n, big.mark = ",")))
}

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Alternative Specifications}\n",
  "\\label{tab:robustness}\n",
  "\\small\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Coefficient & SE & $N$ \\\\\n",
  "\\midrule\n",
  sprintf("Main specification & $%.3f%s$ & (%.3f) & %s \\\\\n",
          m2$beta, stars(m2$pval), m2$se, format(m2$n, big.mark = ",")),
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Placebo tests}} \\\\\n",
  tab3_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$. ",
  "All specifications include district and state$\\times$week fixed effects except ",
  "``Cluster: district'' which changes clustering only. ",
  "Placebo tests use pre-mandate data only. ",
  "``Drop Delta wave'' excludes April--June 2021. ",
  "``Short pre-period'' restricts to October 2020 onward.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(table_dir, "tab3_robustness.tex"))

# ── TABLE 4: Heterogeneity ──────────────────────────────────────────────────
cat("Generating Table 4: Heterogeneity...\n")

het <- results$did_het
het_ct <- coeftable(het)

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Heterogeneity by Plaza Traffic Intensity}\n",
  "\\label{tab:heterogeneity}\n",
  "\\small\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Traffic Tercile $\\times$ Post & Coefficient & SE \\\\\n",
  "\\midrule\n",
  sprintf("High Traffic & $%.3f%s$ & (%.3f) \\\\\n",
          het_ct["traffic_tercile::High Traffic:post_mandate", "Estimate"],
          stars(het_ct["traffic_tercile::High Traffic:post_mandate", "Pr(>|t|)"]),
          het_ct["traffic_tercile::High Traffic:post_mandate", "Std. Error"]),
  sprintf("Medium Traffic & $%.3f%s$ & (%.3f) \\\\\n",
          het_ct["traffic_tercile::Medium Traffic:post_mandate", "Estimate"],
          stars(het_ct["traffic_tercile::Medium Traffic:post_mandate", "Pr(>|t|)"]),
          het_ct["traffic_tercile::Medium Traffic:post_mandate", "Std. Error"]),
  sprintf("Low Traffic & $%.3f%s$ & (%.3f) \\\\\n",
          het_ct["traffic_tercile::Low Traffic:post_mandate", "Estimate"],
          stars(het_ct["traffic_tercile::Low Traffic:post_mandate", "Pr(>|t|)"]),
          het_ct["traffic_tercile::Low Traffic:post_mandate", "Std. Error"]),
  "\\addlinespace\n",
  "Reference & \\multicolumn{2}{c}{No Plaza districts} \\\\\n",
  "District FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "State $\\times$ Week FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\\n",
          format(het$nobs, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$. ",
  "Standard errors clustered at the state level. ",
  "Traffic terciles based on total design traffic capacity (PCU/day) across all plazas in a district. ",
  "Reference category: districts with no toll plazas.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(table_dir, "tab4_heterogeneity.tex"))

# ── TABLE F1: Standardized Effect Sizes (SDE) ───────────────────────────────
cat("Generating Table F1: SDE...\n")

# Compute pre-treatment SDs
pre_sd_transit <- mob[post_mandate == 0, sd(transit, na.rm = TRUE)]
pre_sd_workplace <- mob[post_mandate == 0, sd(workplace, na.rm = TRUE)]
pre_sd_retail <- mob[post_mandate == 0, sd(retail, na.rm = TRUE)]
pre_sd_residential <- mob[post_mandate == 0, sd(residential, na.rm = TRUE)]

# Main estimates (from preferred spec 2)
beta_transit <- coef(results$did2)[1]
se_transit <- se(results$did2)[1]
beta_work <- coef(results$did_work)[1]
se_work <- se(results$did_work)[1]
beta_retail <- coef(results$did_retail)[1]
se_retail <- se(results$did_retail)[1]
beta_resid <- coef(results$did_resid)[1]
se_resid <- se(results$did_resid)[1]

# SDE = beta / SD(Y)
sde_transit <- beta_transit / pre_sd_transit
sde_se_transit <- se_transit / pre_sd_transit
sde_work <- beta_work / pre_sd_workplace
sde_se_work <- se_work / pre_sd_workplace
sde_retail <- beta_retail / pre_sd_retail
sde_se_retail <- se_retail / pre_sd_retail
sde_resid <- beta_resid / pre_sd_residential
sde_se_resid <- se_resid / pre_sd_residential

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
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Did the February 2021 FASTag electronic toll collection mandate at national highway toll plazas generate local economic spillovers in surrounding districts? ",
  "\\textbf{Policy mechanism:} The mandate required all vehicles to use RFID-based electronic toll collection (FASTag) at 700+ national highway plazas, eliminating cash-based toll queues of 20--45 minutes and replacing them with sub-10-second electronic reads. Pre-mandate adoption was approximately 34\\%; post-mandate it exceeded 96\\%. ",
  "\\textbf{Outcome definition:} Google Community Mobility Reports measuring percentage change in visits to location categories (transit stations, workplaces, retail and recreation, residential) relative to a pre-pandemic baseline (median of January 3--February 6, 2020). ",
  "\\textbf{Treatment:} Binary indicator equal to one if the district contains at least one NHAI toll plaza. ",
  "\\textbf{Data:} Google Mobility Reports (daily, February 2020--October 2022), 628 Indian districts, aggregated to weekly level; NHAI toll plaza locations from geohacker/toll-plazas-india (718 plazas geocoded to districts via GADM boundaries). ",
  "\\textbf{Method:} Difference-in-differences with district and state-by-week fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All Indian districts with Google Mobility coverage; 270 treated districts (with $\\geq$ 1 toll plaza), 361 control districts; 55 pre-mandate weeks, 88 post-mandate weeks. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_rows <- sprintf(
  paste0(
    "Transit stations & $%.3f$ & $(%.3f)$ & $%.1f$ & $%.4f$ & $(%.4f)$ & %s \\\\\n",
    "Workplaces & $%.3f$ & $(%.3f)$ & $%.1f$ & $%.4f$ & $(%.4f)$ & %s \\\\\n",
    "Retail \\& recreation & $%.3f$ & $(%.3f)$ & $%.1f$ & $%.4f$ & $(%.4f)$ & %s \\\\\n",
    "Residential & $%.3f$ & $(%.3f)$ & $%.1f$ & $%.4f$ & $(%.4f)$ & %s \\\\\n"
  ),
  beta_transit, se_transit, pre_sd_transit, sde_transit, sde_se_transit, classify_sde(sde_transit),
  beta_work, se_work, pre_sd_workplace, sde_work, sde_se_work, classify_sde(sde_work),
  beta_retail, se_retail, pre_sd_retail, sde_retail, sde_se_retail, classify_sde(sde_retail),
  beta_resid, se_resid, pre_sd_residential, sde_resid, sde_se_resid, classify_sde(sde_resid)
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sde_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat(sprintf("SDE transit: %.4f (%s)\n", sde_transit, classify_sde(sde_transit)))
cat(sprintf("SDE workplace: %.4f (%s)\n", sde_work, classify_sde(sde_work)))
cat(sprintf("SDE retail: %.4f (%s)\n", sde_retail, classify_sde(sde_retail)))
