## 05_tables.R — apep_0931: IAP and Economic Development
## Generate all LaTeX tables

source("code/00_packages.R")

df <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")
robust <- readRDS("data/robustness_results.rds")

dir.create("tables", showWarnings = FALSE)

# ── Table 1: Summary Statistics ─────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment (1994-2010) statistics by group
pre <- df[year <= 2010]

# Census 2011 data for cross-sectional stats
pca11 <- fread("data/pca11_district.csv")
pca11_summ <- pca11[, .(
  pc11_district_id,
  pop = pc11_pca_tot_p,
  lit_rate = fifelse(pc11_pca_tot_p > 0, pc11_pca_p_lit / pc11_pca_tot_p, NA),
  st_share = fifelse(pc11_pca_tot_p > 0, pc11_pca_p_st / pc11_pca_tot_p, NA),
  sc_share = fifelse(pc11_pca_tot_p > 0, pc11_pca_p_sc / pc11_pca_tot_p, NA),
  worker_share = fifelse(pc11_pca_tot_p > 0,
                          (pc11_pca_main_al_p + pc11_pca_main_cl_p +
                           pc11_pca_main_hh_p + pc11_pca_main_ot_p) /
                          pc11_pca_tot_p, NA)
)]
iap_ids <- fread("data/iap_districts.csv")$pc11_district_id
pca11_summ[, iap := as.integer(pc11_district_id %in% iap_ids)]

# Compute statistics
make_row <- function(var, label, data, digits = 2) {
  iap_vals <- data[iap == 1][[var]]
  ctrl_vals <- data[iap == 0][[var]]
  sprintf("%-35s & %s & %s & %s & %s \\\\",
          label,
          formatC(mean(iap_vals, na.rm = TRUE), format = "f", digits = digits),
          formatC(sd(iap_vals, na.rm = TRUE), format = "f", digits = digits),
          formatC(mean(ctrl_vals, na.rm = TRUE), format = "f", digits = digits),
          formatC(sd(ctrl_vals, na.rm = TRUE), format = "f", digits = digits))
}

# Nightlights stats (district-year level, pre-treatment)
pre_summ <- pre[, .(light = mean(dmsp_total_light_cal), ln_light = mean(ln_light)),
                by = .(pc11_district_id, iap)]

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: IAP and Non-IAP Districts}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{IAP Districts} & \\multicolumn{2}{c}{Non-IAP Districts} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Nightlights (Pre-Treatment Mean, 1994--2010)}} \\\\\n",
  make_row("light", "Total light (calibrated)", pre_summ, 0), "\n",
  make_row("ln_light", "Log(total light + 1)", pre_summ, 2), "\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Census 2011 Characteristics}} \\\\\n",
  make_row("pop", "Population", pca11_summ, 0), "\n",
  make_row("lit_rate", "Literacy rate", pca11_summ, 3), "\n",
  make_row("st_share", "Scheduled Tribe share", pca11_summ, 3), "\n",
  make_row("sc_share", "Scheduled Caste share", pca11_summ, 3), "\n",
  make_row("worker_share", "Worker share", pca11_summ, 3), "\n",
  "\\midrule\n",
  sprintf("%-35s & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          "Number of districts", 60,
          uniqueN(df[iap == 0]$pc11_district_id)), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A reports district-level means of calibrated DMSP nightlights over the pre-treatment period (1994--2010). Panel B reports Census 2011 demographic characteristics. IAP districts are the 60 tribal and backward districts designated under the Integrated Action Plan in November 2010.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1, "tables/tab1_summary.tex")

# ── Table 2: Main Results ───────────────────────────────────────────
cat("Generating Table 2: Main Results...\n")

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of IAP on Nighttime Luminosity}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & All & Within-State & State $\\times$ Year & District Trends \\\\\n",
  "\\midrule\n",
  sprintf("IAP $\\times$ Post & %s & %s & %s & %s \\\\",
          sprintf("%.3f%s", coef(results$m1)["treat_post"],
                  ifelse(pvalue(results$m1)["treat_post"] < 0.01, "***",
                         ifelse(pvalue(results$m1)["treat_post"] < 0.05, "**",
                                ifelse(pvalue(results$m1)["treat_post"] < 0.10, "*", "")))),
          sprintf("%.3f%s", coef(results$m2)["treat_post"],
                  ifelse(pvalue(results$m2)["treat_post"] < 0.01, "***", "")),
          sprintf("%.3f%s", coef(results$m3)["treat_post"],
                  ifelse(pvalue(results$m3)["treat_post"] < 0.01, "***", "")),
          sprintf("%.3f%s", coef(robust$m_trend)["treat_post"],
                  ifelse(pvalue(robust$m_trend)["treat_post"] < 0.01, "***", ""))),
  "\n",
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          formatC(se(results$m1)["treat_post"], format = "f", digits = 3),
          formatC(se(results$m2)["treat_post"], format = "f", digits = 3),
          formatC(se(results$m3)["treat_post"], format = "f", digits = 3),
          formatC(se(robust$m_trend)["treat_post"], format = "f", digits = 3)),
  "\n",
  " & & & & \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(results$m1), format = "d", big.mark = ","),
          formatC(nobs(results$m2), format = "d", big.mark = ","),
          formatC(nobs(results$m3), format = "d", big.mark = ","),
          formatC(nobs(robust$m_trend), format = "d", big.mark = ",")),
  "\n",
  sprintf("Districts & %d & %d & %d & %d \\\\",
          640, 308, 640, 640),
  "\n",
  "District FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & --- & Yes \\\\\n",
  "State $\\times$ Year FE & No & No & Yes & No \\\\\n",
  "District Trends & No & No & No & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log(calibrated nightlights + 1). IAP $\\times$ Post equals one for the 60 IAP-designated districts in years 2011--2013. Standard errors clustered at the district level in parentheses. Column (2) restricts to the 9 states containing IAP districts. Column (3) includes state-by-year fixed effects. Column (4) includes district-specific linear time trends. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2, "tables/tab2_main.tex")

# ── Table 3: Event Study Coefficients ───────────────────────────────
cat("Generating Table 3: Event Study...\n")

es_coefs <- robust$es_coefs_sxy[order(event_time)]
tab3_rows <- ""
for (i in 1:nrow(es_coefs)) {
  et <- es_coefs$event_time[i]
  stars <- ifelse(abs(es_coefs$coef[i] / es_coefs$se[i]) > 2.576, "***",
                  ifelse(abs(es_coefs$coef[i] / es_coefs$se[i]) > 1.96, "**",
                         ifelse(abs(es_coefs$coef[i] / es_coefs$se[i]) > 1.645, "*", "")))
  tab3_rows <- paste0(tab3_rows,
    sprintf("$%+d$ & %.3f%s & (%.3f) \\\\\n", et, es_coefs$coef[i], stars, es_coefs$se[i]))
}

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: IAP Effect on Log Nightlights (State $\\times$ Year FE)}\n",
  "\\label{tab:event}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Event Time & Coefficient & SE \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Pre-Treatment}} \\\\\n",
  tab3_rows,
  "\\midrule\n",
  "$-1$ & \\multicolumn{2}{c}{(reference)} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Event study estimates from a regression of log(nightlights + 1) on interactions of IAP indicator with event-time dummies, controlling for district and state-by-year fixed effects. Event time 0 corresponds to 2010. Standard errors clustered at the district level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3, "tables/tab3_event.tex")

# ── Table 4: Heterogeneity ─────────────────────────────────────────
cat("Generating Table 4: Heterogeneity...\n")

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Heterogeneity by Tribal Population Share}\n",
  "\\label{tab:hetero}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & High ST Share & Low ST Share \\\\\n",
  "\\midrule\n",
  sprintf("IAP $\\times$ Post & %.3f%s & %.3f%s \\\\",
          coef(results$m_high_st)["treat_post"],
          ifelse(pvalue(results$m_high_st)["treat_post"] < 0.01, "***", ""),
          coef(results$m_low_st)["treat_post"],
          ifelse(pvalue(results$m_low_st)["treat_post"] < 0.01, "***",
                 ifelse(pvalue(results$m_low_st)["treat_post"] < 0.05, "**", ""))),
  "\n",
  sprintf(" & (%.3f) & (%.3f) \\\\",
          se(results$m_high_st)["treat_post"],
          se(results$m_low_st)["treat_post"]),
  "\n",
  " & & \\\\\n",
  sprintf("Observations & %s & %s \\\\",
          formatC(nobs(results$m_high_st), format = "d", big.mark = ","),
          formatC(nobs(results$m_low_st), format = "d", big.mark = ",")),
  "\n",
  "District FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} The sample in each column includes all non-IAP districts plus the IAP districts in the specified subgroup. High (Low) ST Share indicates IAP districts above (below) the median Scheduled Tribe population share (34.5\\%) among IAP districts, based on Census 2011. Dependent variable is log(calibrated nightlights + 1). Standard errors clustered at the district level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4, "tables/tab4_hetero.tex")

# ── Table F1: SDE Table ─────────────────────────────────────────────
cat("Generating SDE table...\n")

# Preferred specification: district linear trends (most conservative)
beta_main <- coef(robust$m_trend)["treat_post"]
se_main <- se(robust$m_trend)["treat_post"]
sd_y <- sd(df[year <= 2010]$ln_light, na.rm = TRUE)

sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

# Heterogeneity
beta_high <- coef(results$m_high_st)["treat_post"]
se_high <- se(results$m_high_st)["treat_post"]
sde_high <- beta_high / sd_y
se_sde_high <- se_high / sd_y

beta_low <- coef(results$m_low_st)["treat_post"]
se_low <- se(results$m_low_st)["treat_post"]
sde_low <- beta_low / sd_y
se_sde_low <- se_low / sd_y

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
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Whether the Integrated Action Plan --- a combined security-and-development block grant targeting Naxal-affected tribal districts --- improved local economic activity measured by nighttime luminosity. ",
  "\\textbf{Policy mechanism:} The IAP provided Rs 25--30 crore per year to 60 districts selected based on Left-Wing Extremism and tribal backwardness criteria, with funds controlled by a committee of the district collector, superintendent of police, and district forest officer, for roads, schools, health facilities, electrification, and livelihood programs. ",
  "\\textbf{Outcome definition:} Log-transformed calibrated DMSP-OLS annual nighttime luminosity sum at the district level, a standard proxy for local economic activity. ",
  "\\textbf{Treatment:} Binary indicator for the 60 districts designated under the IAP in November 2010. ",
  "\\textbf{Data:} SHRUG v2.1 DMSP calibrated nightlights, 640 districts, 1994--2013, 20,480 district-year observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with district-specific linear time trends and district-level clustered standard errors. ",
  "\\textbf{Sample:} All Indian districts with non-missing nightlights. IAP districts defined by the CCEA November 2010 designation of 60 tribal and backward districts in 9 states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log nightlights. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Log nightlights & District trends & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_main, se_main, sd_y, sde_main, se_sde_main, classify(sde_main)),
  "\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("Log nightlights & High ST share & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_high, se_high, sd_y, sde_high, se_sde_high, classify(sde_high)),
  "\n",
  sprintf("Log nightlights & Low ST share & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_low, se_low, sd_y, sde_low, se_sde_low, classify(sde_low)),
  "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize\n",
  "\\begin{itemize}[leftmargin=*]\n",
  sde_notes, "\n",
  "\\end{itemize}}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(sde_tab, "tables/tabF1_sde.tex")

cat("All tables generated.\n")
