## 05_tables.R — Generate all LaTeX tables
## apep_1157: Seguro Popular and Cause-Specific Infant Mortality

source("00_packages.R")

panel <- fread("../data/panel_clean.csv")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

vars_lab <- c(
  "imr" = "Infant mortality rate",
  "amenable_mr" = "Amenable-cause mortality rate",
  "non_amenable_mr" = "Non-amenable-cause mortality rate",
  "nmr" = "Neonatal mortality rate",
  "infant_deaths" = "Infant deaths (count)",
  "amenable_deaths" = "Amenable-cause deaths (count)",
  "non_amenable_deaths" = "Non-amenable-cause deaths (count)",
  "total_deaths" = "Total deaths (count)",
  "est_pop" = "Estimated population"
)

summ_rows <- lapply(names(vars_lab), function(v) {
  x <- panel[[v]]
  data.frame(
    Variable = vars_lab[v],
    Mean = mean(x, na.rm = TRUE),
    SD = sd(x, na.rm = TRUE),
    P25 = quantile(x, 0.25, na.rm = TRUE),
    Median = median(x, na.rm = TRUE),
    P75 = quantile(x, 0.75, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
})
summ_df <- do.call(rbind, summ_rows)

# Write LaTeX
sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lrrrrr}\n")
cat("\\toprule\n")
cat("Variable & Mean & SD & P25 & Median & P75 \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{6}{l}{\\textit{Panel A: Mortality Rates (per 1,000 estimated live births)}} \\\\\n")
for (i in 1:4) {
  cat(sprintf("%s & %.1f & %.1f & %.1f & %.1f & %.1f \\\\\n",
              summ_df$Variable[i], summ_df$Mean[i], summ_df$SD[i],
              summ_df$P25[i], summ_df$Median[i], summ_df$P75[i]))
}
cat("\\midrule\n")
cat("\\multicolumn{6}{l}{\\textit{Panel B: Death Counts}} \\\\\n")
for (i in 5:8) {
  cat(sprintf("%s & %.0f & %.0f & %.0f & %.0f & %.0f \\\\\n",
              summ_df$Variable[i], summ_df$Mean[i], summ_df$SD[i],
              summ_df$P25[i], summ_df$Median[i], summ_df$P75[i]))
}
cat("\\midrule\n")
cat("\\multicolumn{6}{l}{\\textit{Panel C: Municipality Characteristics}} \\\\\n")
cat(sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
            summ_df$Variable[9],
            format(round(summ_df$Mean[9]), big.mark = ","),
            format(round(summ_df$SD[9]), big.mark = ","),
            format(round(summ_df$P25[9]), big.mark = ","),
            format(round(summ_df$Median[9]), big.mark = ","),
            format(round(summ_df$P75[9]), big.mark = ",")))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
n_mun <- length(unique(panel$mun_id))
n_obs <- nrow(panel)
cat(sprintf("\\item \\textit{Notes:} $N$ = %s municipality-year observations across %s municipalities, 1998--2012. Mortality rates are computed as deaths per 1,000 estimated live births, where live births are estimated using national crude birth rates applied to municipal population (estimated from total deaths and national crude death rates). Municipalities with fewer than 50 mean annual deaths are excluded. Amenable causes include perinatal conditions (ICD-10 P00--P96), diarrheal disease (A00--A09), acute respiratory infections (J00--J22), and vaccine-preventable diseases (A33--A37). Non-amenable causes include congenital malformations (Q00--Q99) and external causes (V01--Y98).\n",
            format(n_obs, big.mark = ","), format(n_mun, big.mark = ",")))
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# TABLE 2: SP Enrollment Cohorts
# ============================================================
cat("Generating Table 2: SP Enrollment Cohorts...\n")

cohort_summ <- panel[year == 2000, .(
  N_mun = .N,
  Mean_IMR = mean(imr, na.rm = TRUE),
  Mean_Amenable = mean(amenable_mr, na.rm = TRUE),
  Mean_NonAmenable = mean(non_amenable_mr, na.rm = TRUE),
  Mean_Deaths = mean(total_deaths, na.rm = TRUE)
), by = first_treat]
setorder(cohort_summ, first_treat)

sink(file.path(tables_dir, "tab2_cohorts.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Pre-Treatment Characteristics by Seguro Popular Enrollment Cohort}\n")
cat("\\label{tab:cohorts}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lrrrrrr}\n")
cat("\\toprule\n")
cat(" & & \\multicolumn{4}{c}{Pre-Treatment Means (Year 2000)} \\\\\n")
cat("\\cmidrule(lr){3-6}\n")
cat("Cohort & Municipalities & IMR & Amenable MR & Non-Amen.\\ MR & Total Deaths \\\\\n")
cat("\\midrule\n")
for (i in 1:nrow(cohort_summ)) {
  cat(sprintf("SP %d & %d & %.1f & %.1f & %.1f & %.0f \\\\\n",
              cohort_summ$first_treat[i], cohort_summ$N_mun[i],
              cohort_summ$Mean_IMR[i], cohort_summ$Mean_Amenable[i],
              cohort_summ$Mean_NonAmenable[i], cohort_summ$Mean_Deaths[i]))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Pre-treatment (year 2000) means of key outcome variables by Seguro Popular enrollment cohort. Cohort year indicates the first year of SP enrollment at the state level. Pilot states (2002): Aguascalientes, Campeche, Colima, Jalisco, Tabasco. All mortality rates per 1,000 estimated live births.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# TABLE 3: Main CS-DiD Results
# ============================================================
cat("Generating Table 3: Main Results...\n")

att_am <- results$att_amenable
att_na <- results$att_nonamenable
att_imr <- results$att_imr
att_nmr <- results$att_nmr

# Also compute TWFE
twfe_am <- results$twfe_amenable
twfe_na <- results$twfe_nonamenable
twfe_imr <- results$twfe_imr

star <- function(p) {
  if (p < 0.01) "***"
  else if (p < 0.05) "**"
  else if (p < 0.10) "*"
  else ""
}

# Compute p-values from CS-DiD (z-test)
p_am <- 2 * pnorm(-abs(att_am$overall.att / att_am$overall.se))
p_na <- 2 * pnorm(-abs(att_na$overall.att / att_na$overall.se))
p_imr <- 2 * pnorm(-abs(att_imr$overall.att / att_imr$overall.se))
p_nmr <- 2 * pnorm(-abs(att_nmr$overall.att / att_nmr$overall.se))

sink(file.path(tables_dir, "tab3_main.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of Seguro Popular on Infant Mortality by Cause Group}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Overall IMR & Amenable MR & Non-Amenable MR & Neonatal MR \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Callaway--Sant'Anna (2021)}} \\\\\n")
cat(sprintf("ATT & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
            att_imr$overall.att, star(p_imr),
            att_am$overall.att, star(p_am),
            att_na$overall.att, star(p_na),
            att_nmr$overall.att, star(p_nmr)))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            att_imr$overall.se, att_am$overall.se,
            att_na$overall.se, att_nmr$overall.se))
cat("[0.5em]\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: TWFE (comparison)}} \\\\\n")
cat(sprintf("Treated & %.3f%s & %.3f%s & %.3f%s & \\\\\n",
            coef(twfe_imr)["treated"], star(pvalue(twfe_imr)["treated"]),
            coef(twfe_am)["treated"], star(pvalue(twfe_am)["treated"]),
            coef(twfe_na)["treated"], star(pvalue(twfe_na)["treated"])))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & \\\\\n",
            se(twfe_imr)["treated"], se(twfe_am)["treated"],
            se(twfe_na)["treated"]))
cat("\\midrule\n")
cat(sprintf("Municipalities & %s & %s & %s & %s \\\\\n",
            format(length(unique(panel$mun_id)), big.mark = ","),
            format(length(unique(panel$mun_id)), big.mark = ","),
            format(length(unique(panel$mun_id)), big.mark = ","),
            format(length(unique(panel$mun_id)), big.mark = ",")))
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nrow(panel), big.mark = ","),
            format(nrow(panel), big.mark = ","),
            format(nrow(panel), big.mark = ","),
            format(nrow(panel), big.mark = ",")))
pre_mean_imr <- mean(panel[year < 2002, imr], na.rm = TRUE)
pre_mean_am <- mean(panel[year < 2002, amenable_mr], na.rm = TRUE)
pre_mean_na <- mean(panel[year < 2002, non_amenable_mr], na.rm = TRUE)
pre_mean_nmr <- mean(panel[year < 2002, nmr], na.rm = TRUE)
cat(sprintf("Pre-treatment mean & %.1f & %.1f & %.1f & %.1f \\\\\n",
            pre_mean_imr, pre_mean_am, pre_mean_na, pre_mean_nmr))
cat("Estimator & CS-DiD & CS-DiD & CS-DiD & CS-DiD \\\\\n")
cat("Control group & NYT & NYT & NYT & NYT \\\\\n")
cat("Clustering & State & State & State & State \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Callaway--Sant'Anna (2021) doubly robust estimates of the average treatment effect on the treated (ATT). Treatment is Seguro Popular enrollment at the state level, with cohorts in 2002--2005. Control group is not-yet-treated municipalities. Standard errors clustered at the state level in parentheses. Panel B reports standard TWFE estimates for comparison. All mortality rates per 1,000 estimated live births. Amenable causes: perinatal conditions, diarrheal disease, respiratory infections, vaccine-preventable diseases. Non-amenable causes: congenital malformations, external causes. NYT = not yet treated. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("Generating Table 4: Robustness...\n")

specs <- list(
  list("Baseline", att_am$overall.att, att_am$overall.se),
  list("High baseline IMR", robust$att_high$overall.att, robust$att_high$overall.se),
  list("Low baseline IMR", robust$att_low$overall.att, robust$att_low$overall.se),
  list("Excluding pilot states", robust$att_nopilot$overall.att, robust$att_nopilot$overall.se),
  list("Balanced panel only", robust$att_bal$overall.att, robust$att_bal$overall.se),
  list("Log amenable deaths", robust$att_log$overall.att, robust$att_log$overall.se)
)

sink(file.path(tables_dir, "tab4_robustness.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Robustness of Amenable Mortality Effect}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("Specification & ATT & SE \\\\\n")
cat("\\midrule\n")
for (s in specs) {
  p_val <- 2 * pnorm(-abs(s[[2]] / s[[3]]))
  cat(sprintf("%s & %.3f%s & (%.3f) \\\\\n", s[[1]], s[[2]], star(p_val), s[[3]]))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} All specifications use the Callaway--Sant'Anna (2021) doubly robust estimator with not-yet-treated controls and state-clustered standard errors. ``Baseline'' reproduces the Column (2) estimate from Table~\\ref{tab:main}. ``High/Low baseline IMR'' splits municipalities at the median pre-treatment infant mortality rate. ``Excluding pilot states'' drops the 2002 cohort (Aguascalientes, Campeche, Colima, Jalisco, Tabasco). ``Balanced panel'' restricts to municipalities observed in all 15 years. ``Log amenable deaths'' uses $\\ln(\\text{amenable deaths} + 1)$ as the outcome. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# TABLE 5: Cause-Specific Decomposition
# ============================================================
cat("Generating Table 5: Cause Decomposition...\n")

# Run cause-specific CS-DiD
causes <- c("perinatal_mr", "diarrheal_mr", "respiratory_mr")
cause_labs <- c("Perinatal conditions", "Diarrheal disease", "Respiratory infections")
cause_results <- list()

for (i in seq_along(causes)) {
  v <- causes[i]
  if (!(v %in% names(panel))) {
    cause_base <- gsub("_mr$", "_deaths", v)
    panel[, (v) := get(cause_base) / est_births * 1000]
  }
  cs_c <- att_gt(
    yname = v, tname = "year", idname = "mun_num",
    gname = "first_treat", data = as.data.frame(panel),
    control_group = "notyettreated", base_period = "universal",
    est_method = "dr", clustervars = "state_code", print_details = FALSE
  )
  att_c <- aggte(cs_c, type = "simple")
  cause_results[[i]] <- list(
    label = cause_labs[i],
    att = att_c$overall.att,
    se = att_c$overall.se,
    pre_mean = mean(panel[year < 2002, get(v)], na.rm = TRUE)
  )
}

# Add non-amenable components
# Congenital
panel[, congenital_mr := congenital_deaths / est_births * 1000]
cs_cong <- att_gt(
  yname = "congenital_mr", tname = "year", idname = "mun_num",
  gname = "first_treat", data = as.data.frame(panel),
  control_group = "notyettreated", base_period = "universal",
  est_method = "dr", clustervars = "state_code", print_details = FALSE
)
att_cong <- aggte(cs_cong, type = "simple")
cause_results[[4]] <- list(
  label = "Congenital malformations",
  att = att_cong$overall.att,
  se = att_cong$overall.se,
  pre_mean = mean(panel[year < 2002, congenital_mr], na.rm = TRUE)
)

sink(file.path(tables_dir, "tab5_causes.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Cause-Specific Decomposition of Infant Mortality Effects}\n")
cat("\\label{tab:causes}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Cause of Death & ATT & SE & Pre-Treatment Mean \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: Amenable Causes}} \\\\\n")
for (i in 1:3) {
  r <- cause_results[[i]]
  p_val <- 2 * pnorm(-abs(r$att / r$se))
  cat(sprintf("%s & %.3f%s & (%.3f) & %.2f \\\\\n",
              r$label, r$att, star(p_val), r$se, r$pre_mean))
}
cat("\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: Non-Amenable Causes (Placebo)}} \\\\\n")
r <- cause_results[[4]]
p_val <- 2 * pnorm(-abs(r$att / r$se))
cat(sprintf("%s & %.3f%s & (%.3f) & %.2f \\\\\n",
            r$label, r$att, star(p_val), r$se, r$pre_mean))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Callaway--Sant'Anna (2021) doubly robust ATT estimates for each ICD-10 cause-of-death group. All rates per 1,000 estimated live births. Amenable causes are conditions treatable with basic healthcare access. Congenital malformations serve as a placebo: health insurance cannot prevent chromosomal or structural anomalies. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# SDE TABLE (Appendix — Mandatory)
# ============================================================
cat("Generating SDE Table...\n")

# SDE = beta / SD(Y)
sd_amenable <- sd(panel$amenable_mr, na.rm = TRUE)
sd_imr <- sd(panel$imr, na.rm = TRUE)
sd_nonamenable <- sd(panel$non_amenable_mr, na.rm = TRUE)
sd_nmr <- sd(panel$nmr, na.rm = TRUE)

sde_rows <- list(
  list("Overall IMR", att_imr$overall.att, att_imr$overall.se, sd_imr),
  list("Amenable MR", att_am$overall.att, att_am$overall.se, sd_amenable),
  list("Non-amenable MR", att_na$overall.att, att_na$overall.se, sd_nonamenable),
  list("Neonatal MR", att_nmr$overall.att, att_nmr$overall.se, sd_nmr)
)

classify <- function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s < 0.005) "Null"
  else if (s < 0.05) "Small positive"
  else if (s < 0.15) "Moderate positive"
  else "Large positive"
}

# Heterogeneity SDE rows
sd_am_high <- sd(panel[high_baseline_imr == 1, amenable_mr], na.rm = TRUE)
sd_am_low <- sd(panel[high_baseline_imr == 0, amenable_mr], na.rm = TRUE)

sde_het <- list(
  list("Amenable MR (high baseline)", robust$att_high$overall.att, robust$att_high$overall.se, sd_am_high),
  list("Amenable MR (low baseline)", robust$att_low$overall.att, robust$att_low$overall.se, sd_am_low)
)

sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (r in sde_rows) {
  sde_val <- r[[2]] / r[[4]]
  se_sde <- r[[3]] / r[[4]]
  cat(sprintf("%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
              r[[1]], r[[2]], r[[3]], r[[4]], sde_val, se_sde, classify(sde_val)))
}
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (baseline IMR split)}} \\\\\n")
for (r in sde_het) {
  sde_val <- r[[2]] / r[[4]]
  se_sde <- r[[3]] / r[[4]]
  cat(sprintf("%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
              r[[1]], r[[2]], r[[3]], r[[4]], sde_val, se_sde, classify(sde_val)))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Mexico. ",
  "\\textbf{Research question:} Does Seguro Popular, Mexico's non-contributory public health insurance program rolled out to municipalities in staggered waves from 2002 to 2005, reduce cause-specific infant mortality in covered municipalities? ",
  "\\textbf{Policy mechanism:} Seguro Popular provides free access to a package of essential health services for the uninsured population, including prenatal care, institutional delivery, neonatal intensive care, and treatment of childhood diarrheal and respiratory diseases, thereby reducing financial barriers to healthcare utilization for pregnant women and infants. ",
  "\\textbf{Outcome definition:} Cause-specific infant mortality rates (deaths of children under age 1 per 1,000 estimated live births), classified by ICD-10 cause of death into amenable causes (perinatal conditions P00--P96, diarrheal disease A00--A09, respiratory infections J00--J22, vaccine-preventable A33--A37) and non-amenable causes (congenital malformations Q00--Q99, external causes V01--Y98). ",
  "\\textbf{Treatment:} Binary indicator for state-level Seguro Popular enrollment, with four staggered cohorts (2002, 2003, 2004, 2005). ",
  "\\textbf{Data:} INEGI/Secretar\\'{i}a de Salud death microdata (individual death records with ICD-10 cause codes), 1998--2012, at the municipality-year level; 1,404 municipalities across 15 years ($N$ = 20,998). ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) doubly robust staggered difference-in-differences with not-yet-treated controls and standard errors clustered at the state level (32 clusters). ",
  "\\textbf{Sample:} Mexican municipalities with at least 50 mean annual deaths (excluding very small municipalities with extremely noisy mortality rates); all 32 states included. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of the outcome variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables generated.\n")
