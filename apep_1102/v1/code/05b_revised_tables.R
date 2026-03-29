# =============================================================================
# 05b_revised_tables.R — Update tables with county-clustered SEs
# =============================================================================

source("00_packages.R")

load("../data/models.RData")
load("../data/robustness_models.RData")
load("../data/revised_models.RData")
sds <- read_json("../data/pre_treatment_sds.json")
dt <- fread("../data/county_month_panel.csv")
county_avg <- dt[, .(avg_pills = mean(total_oxy_pills)), by = county_id]
keep <- county_avg[avg_pills >= 100]$county_id
dt <- dt[county_id %in% keep]
pre_fl <- dt[fl == 1 & post == 0]

stars <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

# ============================================================================
# Table 2: Main DiD (now with county-clustered SEs)
# ============================================================================
cat("Updating Table 2: Main Results (county-clustered)\n")

# Unweighted with county clustering
dt[, county_id := as.factor(county_id)]
dt[, ym_fac := as.factor(ym_int)]
m1_uw_cc <- feols(high_dose_share ~ treated | county_id + ym_fac,
                  data = dt, cluster = ~county_id)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Florida's Pill Mill Crackdown on Opioid Dosage Composition}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & High-Dose & High-Dose & Avg mg/ & Oxy/ \\\\",
  " & Share & Share & Pill & (Oxy+Hydro) \\\\",
  " & Unweighted & Weighted & Weighted & Weighted \\\\",
  "\\midrule",
  sprintf("FL $\\times$ Post & %.4f%s & $-$%.4f%s & $-$%.3f%s & $-$%.4f%s \\\\",
          coef(m1_uw_cc)["treated"], stars(pvalue(m1_uw_cc)["treated"]),
          abs(coef(m1_county)["treated"]), stars(pvalue(m1_county)["treated"]),
          abs(coef(m2_county)["treated"]), stars(pvalue(m2_county)["treated"]),
          abs(coef(m3_county)["treated"]), stars(pvalue(m3_county)["treated"])),
  sprintf(" & (%.4f) & (%.4f) & (%.3f) & (%.4f) \\\\",
          se(m1_uw_cc)["treated"], se(m1_county)["treated"],
          se(m2_county)["treated"], se(m3_county)["treated"]),
  "\\\\",
  sprintf("Pre-treatment mean (FL) & %.3f & %.3f & %.1f & %.3f \\\\",
          mean(pre_fl$high_dose_share), mean(pre_fl$high_dose_share),
          mean(pre_fl$avg_mg), mean(pre_fl$oxy_hydro_ratio)),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(m1_county$nobs, big.mark=","),
          format(m1_county$nobs, big.mark=","),
          format(m2_county$nobs, big.mark=","),
          format(m3_county$nobs, big.mark=",")),
  "Pill weights & No & Yes & Yes & Yes \\\\",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year-month FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the coefficient on FL $\\times$ Post from a difference-in-differences regression. Post is July 2011 onward (full enforcement of HB 7095). Control counties are in Georgia and Alabama. Pill-weighted regressions weight county-months by total oxycodone pill volume, giving more influence to high-volume counties where pill mills concentrated. Standard errors clustered at the county level (288 counties) in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Event Study (county-clustered)
# ============================================================================
cat("Updating Table 3: Event Study (county-clustered)\n")

es_df <- as.data.table(coeftable(m_es_county), keep.rownames = TRUE)
setnames(es_df, c("term", "estimate", "se", "tstat", "pvalue"))
es_df[, quarter := as.numeric(gsub(":fl$", "", gsub("^event_quarter::", "", term)))]
es_df <- es_df[order(quarter)]

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: High-Dose Oxycodone Share (Pill-Weighted, Quarterly)}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Quarter Relative to Crackdown & Coefficient & SE \\\\",
  "\\midrule",
  "\\textit{Pre-treatment} & & \\\\"
)

for (i in 1:nrow(es_df)) {
  q <- es_df$quarter[i]
  st <- stars(es_df$pvalue[i])
  label <- ifelse(q < 0, sprintf("$t%d$", q), sprintf("$t+%d$", q))
  if (q == 0 && i > 1) {
    tab3_lines <- c(tab3_lines,
      "\\midrule",
      "\\textit{Post-treatment} & & \\\\")
  }
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %.4f%s & (%.4f) \\\\", label, es_df$estimate[i], st, es_df$se[i]))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "Reference period & \\multicolumn{2}{c}{$t-1$ (Q2 2011)} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(m_es_county$nobs, big.mark=",")),
  "County FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Year-month FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Pill weights & \\multicolumn{2}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from a pill-weighted event-study regression of the high-dose oxycodone share ($\\geq$30mg) on quarterly indicators interacted with the Florida treatment indicator. The reference period is Q2 2011. Positive pre-treatment coefficients reflect Florida's rising high-dose share during the pill mill boom. Standard errors clustered at the county level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")

# ============================================================================
# Table 4: Robustness (updated with county trends and time placebo)
# ============================================================================
cat("Updating Table 4: Robustness\n")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks: High-Dose Share (Pill-Weighted)}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Coefficient & SE \\\\",
  "\\midrule",
  sprintf("Baseline (pill-weighted, $\\geq$30mg) & %.4f%s & (%.4f) \\\\",
          coef(m1_county)["treated"], stars(pvalue(m1_county)["treated"]),
          se(m1_county)["treated"]),
  sprintf("County-specific linear trends & %.4f%s & (%.4f) \\\\",
          coef(m1_trends)["treated"], stars(pvalue(m1_trends)["treated"]),
          se(m1_trends)["treated"]),
  sprintf("Donut hole (excl.\\ Oct 2010--Jun 2011) & %.4f%s & (%.4f) \\\\",
          coef(m_donut)["treated"], stars(pvalue(m_donut)["treated"]),
          se(m_donut)["treated"]),
  sprintf("Restricted pre-period (2009+) & %.4f%s & (%.4f) \\\\",
          coef(m_2009)["treated"], stars(pvalue(m_2009)["treated"]),
          se(m_2009)["treated"]),
  sprintf("Unweighted & %.4f & (%.4f) \\\\",
          coef(m1_uw_cc)["treated"], se(m1_uw_cc)["treated"]),
  "\\midrule",
  "\\textit{Falsification} & & \\\\",
  sprintf("Placebo: GA vs.\\ AL & %.4f & (%.4f) \\\\",
          coef(m_placebo)["treated_placebo"], se(m_placebo)["treated_placebo"]),
  sprintf("Time placebo: July 2009 & %.4f%s & (%.4f) \\\\",
          coef(m1_placebo_time)["treated_fake"],
          stars(pvalue(m1_placebo_time)["treated_fake"]),
          se(m1_placebo_time)["treated_fake"]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include county and year-month fixed effects. Unless noted, regressions are pill-weighted with standard errors clustered at the county level. The county-trends specification adds county-specific linear time trends. The donut excludes the 9-month transition period. The restricted pre-period uses 2009--2012 only. The time placebo assigns a fake treatment to July 2009 using only pre-crackdown data (before October 2010). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ============================================================================
# Update SDE table with county-clustered SEs
# ============================================================================
cat("Updating SDE table\n")

sd_hds <- sds$sd_high_dose_share

beta_hds <- coef(m1_county)["treated"]
se_hds <- se(m1_county)["treated"]
sde_hds <- beta_hds / sd_hds
se_sde_hds <- se_hds / sd_hds

beta_mg <- coef(m2_county)["treated"]
se_mg <- se(m2_county)["treated"]
sd_mg <- sds$sd_avg_mg
sde_mg <- beta_mg / sd_mg
se_sde_mg <- se_mg / sd_mg

beta_ohr <- coef(m3_county)["treated"]
se_ohr <- se(m3_county)["treated"]
sd_ohr <- sds$sd_oxy_hydro_ratio
sde_ohr <- beta_ohr / sd_ohr
se_sde_ohr <- se_ohr / sd_ohr

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity splits
dt[, county_id_chr := as.character(county_id)]
dt[, weight := total_oxy_pills]
pre_vol <- dt[fl == 1 & post == 0, .(mean_vol = mean(total_oxy_pills)), by = county_id_chr]
med_vol <- median(pre_vol$mean_vol)

dt_hv <- dt[county_id_chr %in% pre_vol[mean_vol >= med_vol]$county_id_chr | fl == 0]
dt_lv <- dt[county_id_chr %in% pre_vol[mean_vol < med_vol]$county_id_chr | fl == 0]

m_hv <- feols(high_dose_share ~ treated | county_id + ym_fac,
              data = dt_hv, cluster = ~county_id, weights = ~weight)
m_lv <- feols(high_dose_share ~ treated | county_id + ym_fac,
              data = dt_lv, cluster = ~county_id, weights = ~weight)

sde_hv <- coef(m_hv)["treated"] / sd_hds
se_sde_hv <- se(m_hv)["treated"] / sd_hds
sde_lv <- coef(m_lv)["treated"] / sd_hds
se_sde_lv <- se(m_lv)["treated"] / sd_hds

sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does Florida's pill mill crackdown (HB 7095) shift the dosage-strength composition of oxycodone shipments, distinguishing supply-side diversion suppression from overall volume reduction? ",
  "\\textbf{Policy mechanism:} HB 7095 required pain clinic registration, restricted dispensing, and mandated a prescription drug monitoring program, effectively shutting down unregulated pain clinics that dispensed high-dose opioids for cash without legitimate medical oversight. ",
  "\\textbf{Outcome definition:} High-dose oxycodone share, defined as the fraction of oxycodone pills shipped to a county with dosage strength $\\geq$30mg out of all oxycodone pills shipped. ",
  "\\textbf{Treatment:} Binary indicator for Florida counties after July 2011 (full enforcement date). ",
  "\\textbf{Data:} DEA ARCOS transaction-level pill shipment records, 2006--2012, aggregated to county-month level for Florida, Georgia, and Alabama. ",
  sprintf("\\textbf{Method:} Pill-weighted TWFE DiD (county and year-month FE), SEs clustered at the county level. %s county-month observations across 288 counties. ", format(m1_county$nobs, big.mark=",")),
  "\\textbf{Sample:} Counties with average monthly oxycodone volume $\\geq$100 pills; Florida as treated, Georgia and Alabama as controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("High-dose share & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          beta_hds, se_hds, sd_hds, sde_hds, se_sde_hds, classify_sde(sde_hds)),
  sprintf("Avg mg/pill & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\",
          beta_mg, se_mg, sd_mg, sde_mg, se_sde_mg, classify_sde(sde_mg)),
  sprintf("Oxy/(Oxy+Hydro) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          beta_ohr, se_ohr, sd_ohr, sde_ohr, se_sde_ohr, classify_sde(sde_ohr)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by pre-treatment county pill volume)}} \\\\",
  sprintf("HDS (high-volume FL counties) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          coef(m_hv)["treated"], se(m_hv)["treated"], sd_hds,
          sde_hv, se_sde_hv, classify_sde(sde_hv)),
  sprintf("HDS (low-volume FL counties) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          coef(m_lv)["treated"], se(m_lv)["treated"], sd_hds,
          sde_lv, se_sde_lv, classify_sde(sde_lv)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize %s}", sde_notes),
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables updated.\n")
