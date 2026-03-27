## 05_tables.R — Generate all tables including SDE appendix
## apep_1095: Induced seismicity and self-regulation in Texas Permian Basin

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds") %>%
  filter(!is.na(treated)) %>%
  mutate(post_treat = as.integer(treated & post))
mr <- readRDS("../data/models.rds")  # coefficient tables
rob_models <- readRDS("../data/robustness_models.rds")
comparison <- readRDS("../data/ok_tx_comparison.rds")
earthquakes <- readRDS("../data/earthquakes_raw.rds")
ring_panel <- readRDS("../data/ring_panel.rds")

dir.create("../tables", showWarnings = FALSE)

# ========================================================================
# Table 1: Summary Statistics
# ========================================================================
cat("Generating Table 1: Summary Statistics\n")

# Grid-cell level stats
stats_treat <- panel %>%
  filter(in_any_sra) %>%
  summarize(
    `Mean eq/cell-month` = sprintf("%.3f", mean(eq_count)),
    `SD eq/cell-month` = sprintf("%.3f", sd(eq_count)),
    `Mean eq M2.5+` = sprintf("%.3f", mean(eq_count_m25)),
    `Grid-cell-months` = format(n(), big.mark = ","),
    `Grid cells` = format(n_distinct(grid_id), big.mark = ",")
  ) %>%
  mutate(Group = "SRA grid cells")

stats_control <- panel %>%
  filter(!in_any_sra) %>%
  summarize(
    `Mean eq/cell-month` = sprintf("%.3f", mean(eq_count)),
    `SD eq/cell-month` = sprintf("%.3f", sd(eq_count)),
    `Mean eq M2.5+` = sprintf("%.3f", mean(eq_count_m25)),
    `Grid-cell-months` = format(n(), big.mark = ","),
    `Grid cells` = format(n_distinct(grid_id), big.mark = ",")
  ) %>%
  mutate(Group = "Non-SRA grid cells")

stats_all <- bind_rows(stats_treat, stats_control) %>%
  dplyr::select(Group, everything())

# LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Permian Basin Grid Cells, 2017--2024}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & Mean Eq./Cell-Mo. & SD & Mean M2.5+ & Cell-Months & Grid Cells \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(stats_all)) {
  tab1_tex <- paste0(tab1_tex,
    stats_all$Group[i], " & ",
    stats_all$`Mean eq/cell-month`[i], " & ",
    stats_all$`SD eq/cell-month`[i], " & ",
    stats_all$`Mean eq M2.5+`[i], " & ",
    stats_all$`Grid-cell-months`[i], " & ",
    stats_all$`Grid cells`[i], " \\\\\n"
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Grid cells are 0.1\\textdegree{} $\\times$ 0.1\\textdegree{} (approximately 11km $\\times$ 11km). SRA grid cells fall within one of three Seismic Response Areas designated by the Texas Railroad Commission (Gardendale, September 2021; Northern Culberson-Reeves, March 2022; Stanton, January 2022). Earthquake counts from USGS ComCat for M2.0+ events in the Permian Basin region (30--33.5\\textdegree{}N, 100.5--105\\textdegree{}W).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

cat(tab1_tex, file = "../tables/tab1_summary.tex")

# ========================================================================
# Table 2: Main Results
# ========================================================================
cat("Generating Table 2: Main Results\n")

# Extract coefficients manually for full control
extract_from_ct <- function(ct, coef_name) {
  idx <- grep(coef_name, ct$term, fixed = TRUE)
  if (length(idx) == 0) return(list(est = NA, se = NA, pval = NA))
  pcol <- grep("^Pr\\(", names(ct), value = TRUE)
  pval <- if (length(pcol) > 0) ct[[pcol[1]]][idx[1]] else NA
  list(est = ct$Estimate[idx[1]], se = ct$`Std. Error`[idx[1]], pval = pval)
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

c1 <- extract_from_ct(mr$m1_pois_ct, "post_treat")
c2 <- extract_from_ct(mr$m2_dose_ct, "treat_intensity")
c3 <- extract_from_ct(mr$m3_ols_ct, "post_treat")
c4 <- extract_from_ct(mr$m4_log_ct, "post_treat")

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of SRA Designation on Earthquake Frequency}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Poisson FE} & OLS FE & Log OLS FE \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-5}\n",
  " & (1) Binary & (2) Dose & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("SRA $\\times$ Post & %.4f%s & & %.4f%s & %.4f%s \\\\\n",
          c1$est, stars(c1$pval), c3$est, stars(c3$pval), c4$est, stars(c4$pval)),
  sprintf(" & (%.4f) & & (%.4f) & (%.4f) \\\\\n", c1$se, c3$se, c4$se),
  sprintf("Treatment Intensity & & %.4f%s & & \\\\\n", c2$est, stars(c2$pval)),
  sprintf(" & & (%.4f) & & \\\\\n", c2$se),
  "\\midrule\n",
  "Grid-cell FE & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is the count of M2.0+ earthquakes per grid cell per month (columns 1--3) or log(1 + count) (column 4). Column 1 reports the binary SRA $\\times$ Post interaction. Column 2 uses treatment intensity (fraction of injection volume reduction: 1.0 for Gardendale full suspension, 0.54 for NCR, 0.40 for Stanton). Standard errors clustered by SRA region and month in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

cat(tab2_tex, file = "../tables/tab2_main.tex")

# ========================================================================
# Table 3: Displacement (Ring-Zone Analysis)
# ========================================================================
cat("Generating Table 3: Displacement Analysis\n")

c_ring <- extract_from_ct(mr$m_ring_did_ct, "post_close")
c_gard <- extract_from_ct(mr$m_sra_specific_ct, "post_gardendale")
c_ncr <- extract_from_ct(mr$m_sra_specific_ct, "post_ncr")
c_stan <- extract_from_ct(mr$m_sra_specific_ct, "post_stanton")

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Displacement and SRA-Specific Effects}\n",
  "\\label{tab:displacement}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) Displacement & (2) SRA-Specific \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Displacement}} \\\\\n",
  sprintf("Within SRA $\\times$ Post & %.4f%s & \\\\\n", c_ring$est, stars(c_ring$pval)),
  sprintf(" & (%.4f) & \\\\\n", c_ring$se),
  "[0.5em]\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: SRA-Specific Effects}} \\\\\n",
  sprintf("Gardendale $\\times$ Post & & %.4f%s \\\\\n", c_gard$est, stars(c_gard$pval)),
  sprintf(" & & (%.4f) \\\\\n", c_gard$se),
  sprintf("NCR $\\times$ Post & & %.4f%s \\\\\n", c_ncr$est, stars(c_ncr$pval)),
  sprintf(" & & (%.4f) \\\\\n", c_ncr$se),
  sprintf("Stanton $\\times$ Post & & %.4f%s \\\\\n", c_stan$est, stars(c_stan$pval)),
  sprintf(" & & (%.4f) \\\\\n", c_stan$se),
  "\\midrule\n",
  "Fixed Effects & Zone + Month & Cell + Month \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A tests for spatial displacement: whether seismicity within SRAs decreased relative to 0--50km buffer zones. Panel B estimates SRA-specific treatment effects using Poisson fixed-effects models. Gardendale implemented full deep-disposal suspension; NCR and Stanton used operator-led volume reduction plans. Standard errors clustered by SRA region and month. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

cat(tab3_tex, file = "../tables/tab3_displacement.tex")

# ========================================================================
# Table 4: Robustness Checks
# ========================================================================
cat("Generating Table 4: Robustness\n")

# For robustness models, extract from the stored model objects
extract_coef_model <- function(model, coef_name) {
  ct <- as.data.frame(coeftable(model))
  ct$term <- rownames(ct)
  idx <- grep(coef_name, ct$term, fixed = TRUE)
  if (length(idx) == 0) return(list(est = NA, se = NA, pval = NA))
  pcol <- grep("^Pr\\(", names(ct), value = TRUE)
  pval <- if (length(pcol) > 0) ct[[pcol[1]]][idx[1]] else NA
  list(est = ct$Estimate[idx[1]], se = ct$`Std. Error`[idx[1]], pval = pval)
}
c_m25 <- extract_coef_model(rob_models$m_m25, "post_treat")
c_m30 <- extract_coef_model(rob_models$m_m30, "post_treat")
c_placebo <- extract_coef_model(rob_models$m_placebo, "fake_treat")

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) M2.5+ & (2) M3.0+ & (3) Placebo 2019 \\\\\n",
  "\\midrule\n",
  sprintf("SRA $\\times$ Post & %.4f%s & %.4f%s & \\\\\n",
          c_m25$est, stars(c_m25$pval), c_m30$est, stars(c_m30$pval)),
  sprintf(" & (%.4f) & (%.4f) & \\\\\n", c_m25$se, c_m30$se),
  sprintf("Fake SRA $\\times$ Post (2019) & & & %.4f%s \\\\\n",
          c_placebo$est, stars(c_placebo$pval)),
  sprintf(" & & & (%.4f) \\\\\n", c_placebo$se),
  "[0.5em]\n",
  sprintf("RI $p$-value (main spec) & \\multicolumn{3}{c}{%.3f} \\\\\n", rob_models$ri_pvalue),
  "\\midrule\n",
  "Grid-cell FE & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} All specifications use Poisson fixed effects with SEs clustered by SRA region and month. Columns 1--2 vary the magnitude threshold (M2.5+ and M3.0+). Column 3 assigns a placebo treatment date of June 2019 using only pre-SRA data (2017--August 2021). The RI $p$-value is from 500 permutations of SRA designation timing. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

cat(tab4_tex, file = "../tables/tab4_robustness.tex")

# ========================================================================
# Table 5: Texas vs. Oklahoma Comparison
# ========================================================================
cat("Generating Table 5: Cross-State Comparison\n")

comp_wide <- comparison %>%
  pivot_wider(names_from = state, values_from = eq_count) %>%
  mutate(
    `Texas (Permian)` = replace_na(`Texas (Permian)`, 0L),
    Oklahoma = replace_na(Oklahoma, 0L)
  )

# Compute % change from peak
tx_peak <- max(comp_wide$`Texas (Permian)`, na.rm = TRUE)
ok_peak <- max(comp_wide$Oklahoma, na.rm = TRUE)

comp_wide <- comp_wide %>%
  mutate(
    `TX \\% of Peak` = sprintf("%.0f\\%%", 100 * `Texas (Permian)` / tx_peak),
    `OK \\% of Peak` = sprintf("%.0f\\%%", 100 * Oklahoma / ok_peak)
  )

tab5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Cross-State Comparison: Texas (Operator-Led) vs.~Oklahoma (Mandatory)}\n",
  "\\label{tab:comparison}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Year & TX Permian & OK & TX \\% Peak & OK \\% Peak \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(comp_wide)) {
  tab5_tex <- paste0(tab5_tex,
    sprintf("%d & %s & %s & %s & %s \\\\\n",
            comp_wide$year[i],
            format(comp_wide$`Texas (Permian)`[i], big.mark = ","),
            format(comp_wide$Oklahoma[i], big.mark = ","),
            comp_wide$`TX \\% of Peak`[i],
            comp_wide$`OK \\% of Peak`[i])
  )
}

tab5_tex <- paste0(tab5_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Annual M2.0+ earthquake counts. Texas covers the Permian Basin region (30--33.5\\textdegree{}N, 100.5--105\\textdegree{}W). Oklahoma covers the Arbuckle zone (34--37\\textdegree{}N, 96--100\\textdegree{}W). Oklahoma implemented mandatory injection volume caps through OCC directives beginning in 2015--2016. Texas designated SRAs with operator-led response plans beginning September 2021. Source: USGS ComCat.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

cat(tab5_tex, file = "../tables/tab5_comparison.tex")

# ========================================================================
# SDE Appendix Table (MANDATORY)
# ========================================================================
cat("Generating SDE Table\n")

# Compute SDEs for main outcomes
# Pre-treatment SD of Y
pre_sd_eq <- sd(panel$eq_count[!panel$post & panel$in_any_sra], na.rm = TRUE)
pre_sd_m25 <- sd(panel$eq_count_m25[!panel$post & panel$in_any_sra], na.rm = TRUE)

# For Poisson: coefficient is log-rate ratio, so marginal effect ≈ β × mean(Y)
# SDE = β × mean(Y_pre) / SD(Y_pre) for Poisson
pre_mean_eq <- mean(panel$eq_count[!panel$post & panel$in_any_sra], na.rm = TRUE)

# Main effect (Model 1: Poisson binary)
beta1 <- c1$est  # log rate ratio
se1 <- c1$se
# Marginal effect: (exp(β) - 1) × E[Y] for count interpretation
# SDE = marginal_effect / SD(Y)
marg_effect1 <- (exp(beta1) - 1) * pre_mean_eq
sde1 <- marg_effect1 / pre_sd_eq
se_sde1 <- abs(exp(beta1) * pre_mean_eq / pre_sd_eq) * se1  # delta method approx

# M2.5+ effect
pre_mean_m25 <- mean(panel$eq_count_m25[!panel$post & panel$in_any_sra], na.rm = TRUE)
beta_m25 <- c_m25$est
se_m25 <- c_m25$se
marg_effect_m25 <- (exp(beta_m25) - 1) * pre_mean_m25
sde_m25 <- marg_effect_m25 / pre_sd_m25
se_sde_m25 <- abs(exp(beta_m25) * pre_mean_m25 / pre_sd_m25) * se_m25

# Displacement (ring zone)
pre_sd_ring <- sd(ring_panel$eq_count[ring_panel$within_sra & !ring_panel$post_any], na.rm = TRUE)
pre_mean_ring <- mean(ring_panel$eq_count[ring_panel$within_sra & !ring_panel$post_any], na.rm = TRUE)
beta_ring <- c_ring$est
se_ring <- c_ring$se
marg_effect_ring <- (exp(beta_ring) - 1) * pre_mean_ring
sde_ring <- marg_effect_ring / pre_sd_ring
se_sde_ring <- abs(exp(beta_ring) * pre_mean_ring / pre_sd_ring) * se_ring

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("N/A")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE rows
sde_rows <- data.frame(
  Outcome = c(
    "Earthquake count (M2.0+)",
    "Earthquake count (M2.5+)",
    "Within-SRA vs. buffer"
  ),
  beta = c(beta1, beta_m25, beta_ring),
  se = c(se1, se_m25, se_ring),
  sd_y = c(pre_sd_eq, pre_sd_m25, pre_sd_ring),
  sde = c(sde1, sde_m25, sde_ring),
  se_sde = c(se_sde1, se_sde_m25, se_sde_ring),
  stringsAsFactors = FALSE
) %>%
  mutate(classification = sapply(sde, classify_sde))

# Heterogeneity panel: SRA-specific
sde_het <- data.frame(
  Outcome = c("Gardendale (full suspension)", "NCR (operator-led)"),
  beta = c(c_gard$est, c_ncr$est),
  se = c(c_gard$se, c_ncr$se),
  sd_y = c(pre_sd_eq, pre_sd_eq),
  stringsAsFactors = FALSE
) %>%
  mutate(
    sde = (exp(beta) - 1) * pre_mean_eq / sd_y,
    se_sde = abs(exp(beta) * pre_mean_eq / sd_y) * se,
    classification = sapply(sde, classify_sde)
  )

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do operator-led seismic response plans (Texas SRA designations, 2021--2022) reduce induced earthquake frequency in the Permian Basin? ",
  "\\textbf{Policy mechanism:} Texas Railroad Commission designated three Seismic Response Areas requiring wastewater injection operators to submit and follow volume reduction plans, differing from Oklahoma's mandatory government-imposed injection caps that achieved a 97\\% seismicity reduction. ",
  "\\textbf{Outcome definition:} Monthly count of M2.0+ earthquakes per 0.1\\textdegree{} grid cell from USGS ComCat catalog. ",
  "\\textbf{Treatment:} Binary (grid cell inside vs.\\ outside designated SRA boundaries after enforcement date). ",
  "\\textbf{Data:} USGS ComCat earthquake catalog and Texas RRC injection well records, 2017--2024, 0.1\\textdegree{} grid-cell $\\times$ month panel. ",
  "\\textbf{Method:} Poisson fixed-effects regression with grid-cell and year-month fixed effects; standard errors clustered by SRA region and month; randomization inference with 500 permutations. ",
  "\\textbf{Sample:} Permian Basin region (30--33.5\\textdegree{}N, 100.5--105\\textdegree{}W); grid cells with at least one M2.0+ earthquake during 2017--2024. ",
  "SDE $= (\\exp(\\hat{\\beta}) - 1) \\times \\bar{Y}_{\\text{pre}} / \\text{SD}(Y_{\\text{pre}})$ where $\\bar{Y}_{\\text{pre}}$ and SD($Y_{\\text{pre}}$) are the pre-treatment ",
  "mean and standard deviation of earthquake counts in SRA grid cells. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build LaTeX table
tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in 1:nrow(sde_rows)) {
  tabF1_tex <- paste0(tabF1_tex,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            sde_rows$Outcome[i], sde_rows$beta[i], sde_rows$se[i],
            sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
            sde_rows$classification[i])
  )
}

tabF1_tex <- paste0(tabF1_tex,
  "[0.5em]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by SRA regulatory approach)}} \\\\\n"
)

for (i in 1:nrow(sde_het)) {
  tabF1_tex <- paste0(tabF1_tex,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            sde_het$Outcome[i], sde_het$beta[i], sde_het$se[i],
            sde_het$sd_y[i], sde_het$sde[i], sde_het$se_sde[i],
            sde_het$classification[i])
  )
}

tabF1_tex <- paste0(tabF1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

cat(tabF1_tex, file = "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
