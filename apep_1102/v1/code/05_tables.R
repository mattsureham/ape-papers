# =============================================================================
# 05_tables.R — Generate all tables for the paper
# =============================================================================

source("00_packages.R")

load("../data/models.RData")
load("../data/robustness_models.RData")
sds <- read_json("../data/pre_treatment_sds.json")
dt <- fread("../data/county_month_panel.csv")
county_avg <- dt[, .(avg_pills = mean(total_oxy_pills)), by = county_id]
keep <- county_avg[avg_pills >= 100]$county_id
dt <- dt[county_id %in% keep]

dir.create("../tables", showWarnings = FALSE)

pre_fl <- dt[fl == 1 & post == 0]
pre_ctrl <- dt[fl == 0 & post == 0]

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics\n")

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Period (January 2006--June 2011)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Florida} & \\multicolumn{2}{c}{Georgia \\& Alabama} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  sprintf("High-dose share ($\\geq$30mg) & %.3f & %.3f & %.3f & %.3f \\\\",
          mean(pre_fl$high_dose_share), sd(pre_fl$high_dose_share),
          mean(pre_ctrl$high_dose_share), sd(pre_ctrl$high_dose_share)),
  sprintf("Average mg per pill & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(pre_fl$avg_mg), sd(pre_fl$avg_mg),
          mean(pre_ctrl$avg_mg), sd(pre_ctrl$avg_mg)),
  sprintf("Oxy/(Oxy+Hydro) ratio & %.3f & %.3f & %.3f & %.3f \\\\",
          mean(pre_fl$oxy_hydro_ratio), sd(pre_fl$oxy_hydro_ratio),
          mean(pre_ctrl$oxy_hydro_ratio), sd(pre_ctrl$oxy_hydro_ratio)),
  sprintf("Monthly oxycodone pills (000s) & %.0f & %.0f & %.0f & %.0f \\\\",
          mean(pre_fl$total_oxy_pills)/1000, sd(pre_fl$total_oxy_pills)/1000,
          mean(pre_ctrl$total_oxy_pills)/1000, sd(pre_ctrl$total_oxy_pills)/1000),
  "\\midrule",
  sprintf("Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          uniqueN(pre_fl$county_id), uniqueN(pre_ctrl$county_id)),
  sprintf("County-months & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(nrow(pre_fl), big.mark=","), format(nrow(pre_ctrl), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment period is January 2006 through June 2011. High-dose share is the fraction of oxycodone pills with dosage strength $\\geq$30mg. Average mg is the pill-weighted mean dosage strength. The oxycodone ratio is oxycodone pills divided by total opioid pills (oxycodone + hydrocodone). Data: DEA ARCOS transaction-level records for Florida, Georgia, and Alabama.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ============================================================================
# Table 2: Main DiD Results (weighted and unweighted)
# ============================================================================
cat("Generating Table 2: Main Results\n")

stars <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

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
          coef(m1_uw)["treated"], stars(pvalue(m1_uw)["treated"]),
          abs(coef(m1)["treated"]), stars(pvalue(m1)["treated"]),
          abs(coef(m2)["treated"]), stars(pvalue(m2)["treated"]),
          abs(coef(m3)["treated"]), stars(pvalue(m3)["treated"])),
  sprintf(" & (%.4f) & (%.4f) & (%.3f) & (%.4f) \\\\",
          se(m1_uw)["treated"], se(m1)["treated"],
          se(m2)["treated"], se(m3)["treated"]),
  "\\\\",
  sprintf("Pre-treatment mean (FL) & %.3f & %.3f & %.1f & %.3f \\\\",
          mean(pre_fl$high_dose_share), mean(pre_fl$high_dose_share),
          mean(pre_fl$avg_mg), mean(pre_fl$oxy_hydro_ratio)),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(m1_uw$nobs, big.mark=","),
          format(m1$nobs, big.mark=","),
          format(m2$nobs, big.mark=","),
          format(m3$nobs, big.mark=",")),
  "Pill weights & No & Yes & Yes & Yes \\\\",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year-month FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the coefficient on FL $\\times$ Post from a difference-in-differences regression. Post is July 2011 onward (full enforcement of HB 7095). Control counties are in Georgia and Alabama. Pill-weighted regressions weight county-months by total oxycodone pill volume, giving more influence to high-volume counties where pill mills concentrated. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Event Study Coefficients (weighted)
# ============================================================================
cat("Generating Table 3: Event Study\n")

es_df <- as.data.table(coeftable(m_es), keep.rownames = TRUE)
setnames(es_df, c("term", "estimate", "se", "tstat", "pvalue"))
# Parse quarter: term format is "event_quarter::K:fl" where K is the quarter number
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
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(m_es$nobs, big.mark=",")),
  "County FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Year-month FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Pill weights & \\multicolumn{2}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from a pill-weighted event-study regression of the high-dose oxycodone share ($\\geq$30mg) on quarterly indicators interacted with the Florida treatment indicator. The reference period is Q2 2011 (immediately before full enforcement of HB 7095). Positive pre-treatment coefficients reflect Florida's rising high-dose share during the pill mill boom. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("Generating Table 4: Robustness\n")

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
  sprintf("Baseline (pill-weighted, $\\geq$30mg) & %.4f & (%.4f) \\\\",
          coef(m1)["treated"], se(m1)["treated"]),
  sprintf("Unweighted & %.4f & (%.4f) \\\\",
          coef(m_uw)["treated"], se(m_uw)["treated"]),
  sprintf("Donut hole (excl.\\ Oct 2010--Jun 2011) & %.4f & (%.4f) \\\\",
          coef(m_donut)["treated"], se(m_donut)["treated"]),
  sprintf("Restricted pre-period (2009+) & %.4f & (%.4f) \\\\",
          coef(m_2009)["treated"], se(m_2009)["treated"]),
  "\\midrule",
  "\\textit{Placebo} & & \\\\",
  sprintf("GA vs.\\ AL (no crackdown) & %.4f & (%.4f) \\\\",
          coef(m_placebo)["treated_placebo"], se(m_placebo)["treated_placebo"]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include county and year-month fixed effects with standard errors clustered at the state level. Unless noted, regressions are pill-weighted. The donut excludes the 9-month transition period. The restricted pre-period drops 2006--2008 to avoid the early pill mill boom. The placebo assigns Georgia as treated and Alabama as control.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE) — Mandatory Appendix
# ============================================================================
cat("Generating Table F1: SDE\n")

sd_hds <- sds$sd_high_dose_share
sd_mg <- sds$sd_avg_mg
sd_ohr <- sds$sd_oxy_hydro_ratio

beta_hds <- coef(m1)["treated"]
se_hds <- se(m1)["treated"]
sde_hds <- beta_hds / sd_hds
se_sde_hds <- se_hds / sd_hds

beta_mg <- coef(m2)["treated"]
se_mg <- se(m2)["treated"]
sde_mg <- beta_mg / sd_mg
se_sde_mg <- se_mg / sd_mg

beta_ohr <- coef(m3)["treated"]
se_ohr <- se(m3)["treated"]
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

# Heterogeneity: split FL counties by pre-treatment pill volume
dt[, county_id_chr := as.character(county_id)]
pre_county_vol <- dt[fl == 1 & post == 0, .(mean_vol = mean(total_oxy_pills)), by = county_id_chr]
med_vol <- median(pre_county_vol$mean_vol)
high_vol_counties <- pre_county_vol[mean_vol >= med_vol]$county_id_chr
low_vol_counties <- pre_county_vol[mean_vol < med_vol]$county_id_chr

dt[, weight := total_oxy_pills]

dt_high <- dt[county_id_chr %in% high_vol_counties | fl == 0]
dt_low <- dt[county_id_chr %in% low_vol_counties | fl == 0]

m_high <- feols(high_dose_share ~ treated | county_id + as.factor(ym_int),
                data = dt_high, cluster = ~BUYER_STATE, weights = ~weight)
m_low <- feols(high_dose_share ~ treated | county_id + as.factor(ym_int),
               data = dt_low, cluster = ~BUYER_STATE, weights = ~weight)

sde_high <- coef(m_high)["treated"] / sd_hds
se_sde_high <- se(m_high)["treated"] / sd_hds
sde_low <- coef(m_low)["treated"] / sd_hds
se_sde_low <- se(m_low)["treated"] / sd_hds

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does Florida's pill mill crackdown (HB 7095) shift the dosage-strength composition of oxycodone shipments, distinguishing supply-side diversion suppression from overall volume reduction? ",
  "\\textbf{Policy mechanism:} HB 7095 required pain clinic registration, restricted dispensing, and mandated a prescription drug monitoring program, effectively shutting down unregulated pain clinics that dispensed high-dose opioids for cash without legitimate medical oversight. ",
  "\\textbf{Outcome definition:} High-dose oxycodone share, defined as the fraction of oxycodone pills shipped to a county with dosage strength $\\geq$30mg out of all oxycodone pills shipped. ",
  "\\textbf{Treatment:} Binary indicator for Florida counties after July 2011 (full enforcement date). ",
  "\\textbf{Data:} DEA ARCOS transaction-level pill shipment records, 2006--2012, aggregated to county-month level for Florida, Georgia, and Alabama. ",
  sprintf("\\textbf{Method:} Pill-weighted two-way fixed effects DiD (county and year-month FE), standard errors clustered at the state level. %s county-month observations across 288 counties. ", format(m1$nobs, big.mark=",")),
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
          coef(m_high)["treated"], se(m_high)["treated"], sd_hds,
          sde_high, se_sde_high, classify_sde(sde_high)),
  sprintf("HDS (low-volume FL counties) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          coef(m_low)["treated"], se(m_low)["treated"], sd_hds,
          sde_low, se_sde_low, classify_sde(sde_low)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
