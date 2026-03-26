# 06_tables.R — Generate all LaTeX tables
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry

source("00_packages.R")

# Load analysis results
load("../data/main_models.RData")
load("../data/robustness_models.RData")
df_border <- fread("../data/border_panel.csv")
df_border <- df_border[sector != "total"]
exposure <- fread("../data/biometric_exposure.csv")

cat("=== GENERATING TABLES ===\n")

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("Table 1: Summary statistics\n")

summary_dt <- df_border[, .(
  Mean_Emp = mean(employment, na.rm = TRUE),
  SD_Emp = sd(employment, na.rm = TRUE),
  Mean_Estab = mean(establishments, na.rm = TRUE),
  SD_Estab = sd(establishments, na.rm = TRUE),
  Mean_Wage = mean(avg_weekly_wage, na.rm = TRUE),
  SD_Wage = sd(avg_weekly_wage, na.rm = TRUE),
  Bio_Exposure = mean(bio_exposure_std, na.rm = TRUE),
  N_Counties = uniqueN(area_fips),
  N_Obs = .N
), by = .(Group = fifelse(illinois == 1, "Illinois Border", "Control Border"))]

# Also by sector
sector_summary <- df_border[, .(
  Mean_Emp = mean(employment, na.rm = TRUE),
  SD_Emp = sd(employment, na.rm = TRUE),
  Bio_Exposure = mean(bio_exposure_std, na.rm = TRUE),
  N_Counties = uniqueN(area_fips),
  N_Obs = .N
), by = sector][order(-Bio_Exposure)]

# Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Border Counties, 2015--2024}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat(" & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Establishments} & \\multicolumn{2}{c}{Weekly Wage (\\$)} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n")
cat(" & Mean & SD & Mean & SD & Mean & SD \\\\\n")
cat("\\midrule\n")
for (i in 1:nrow(summary_dt)) {
  cat(sprintf("%s & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f \\\\\n",
              summary_dt$Group[i],
              summary_dt$Mean_Emp[i], summary_dt$SD_Emp[i],
              summary_dt$Mean_Estab[i], summary_dt$SD_Estab[i],
              summary_dt$Mean_Wage[i], summary_dt$SD_Wage[i]))
}
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: By Sector (Border Counties)}} \\\\\n")
cat("\\midrule\n")
cat(" & Mean Emp & SD & Exposure & Counties & Obs & \\\\\n")
cat("\\midrule\n")
for (i in 1:nrow(sector_summary)) {
  cat(sprintf("%s & %.0f & %.0f & %.2f & %d & %s & \\\\\n",
              gsub("_", " ", tools::toTitleCase(sector_summary$sector[i])),
              sector_summary$Mean_Emp[i], sector_summary$SD_Emp[i],
              sector_summary$Bio_Exposure[i],
              sector_summary$N_Counties[i],
              formatC(sector_summary$N_Obs[i], format = "d", big.mark = ",")))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Data from BLS Quarterly Census of Employment and Wages (QCEW), 2015Q1--2024Q4. ")
cat("Border counties are those sharing a boundary with Illinois (treated) or with a neighboring state (control). ")
cat("Biometric exposure index constructed from O*NET Technology Skills and Work Context data, ")
cat("with GLBA/HIPAA preemption adjustments for Finance and Healthcare sectors. ")
cat("Weekly wage is the average across all workers in the county-sector-quarter cell.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table 2: Main Results
# ============================================================

cat("Table 2: Main results\n")

format_coef <- function(model, var = "triple_cont") {
  ct <- coeftable(model)
  if (var %in% rownames(ct)) {
    b <- ct[var, 1]
    se <- ct[var, 2]
    p <- ct[var, 4]
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
    list(coef = sprintf("%.3f%s", b, stars), se = sprintf("(%.3f)", se))
  } else {
    list(coef = "---", se = "")
  }
}

sink("../tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{The Litigation Tax: Continuous-Exposure Triple-Difference}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccccccc}\n")
cat("\\toprule\n")
cat(" & \\multicolumn{4}{c}{Border Counties} & \\multicolumn{4}{c}{All Counties} \\\\\n")
cat("\\cmidrule(lr){2-5} \\cmidrule(lr){6-9}\n")
cat(" & Log Emp & Log Estab & Log Wage & Log Size & Log Emp & Log Estab & Log Wage & Log Size \\\\\n")
cat(" & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\\\\n")
cat("\\midrule\n")

models <- list(m1_border, m2_border, m3_border, m4_border, m5_all, m6_all, m7_all, m8_all)
coefs <- lapply(models, format_coef)
cat(sprintf("IL $\\times$ Post $\\times$ Exposure & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
            coefs[[1]]$coef, coefs[[2]]$coef, coefs[[3]]$coef, coefs[[4]]$coef,
            coefs[[5]]$coef, coefs[[6]]$coef, coefs[[7]]$coef, coefs[[8]]$coef))
cat(sprintf(" & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
            coefs[[1]]$se, coefs[[2]]$se, coefs[[3]]$se, coefs[[4]]$se,
            coefs[[5]]$se, coefs[[6]]$se, coefs[[7]]$se, coefs[[8]]$se))

cat("\\midrule\n")
cat(sprintf("County $\\times$ Sector FE & Yes & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Observations & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
            formatC(nobs(m1_border), big.mark = ","),
            formatC(nobs(m2_border), big.mark = ","),
            formatC(nobs(m3_border), big.mark = ","),
            formatC(nobs(m4_border), big.mark = ","),
            formatC(nobs(m5_all), big.mark = ","),
            formatC(nobs(m6_all), big.mark = ","),
            formatC(nobs(m7_all), big.mark = ","),
            formatC(nobs(m8_all), big.mark = ",")))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. ")
cat("Standard errors clustered at the state level in parentheses. ")
cat("The dependent variable in each column is the log of the indicated outcome. ")
cat("IL $\\times$ Post $\\times$ Exposure is the triple interaction of an Illinois indicator, ")
cat("a post-Rosenbach indicator (2019Q1 onward), and the continuous biometric exposure index. ")
cat("Log Size is log average establishment size (employment/establishments). ")
cat("Border counties share a boundary with Illinois or a neighboring state. ")
cat("All models include lower-order interactions.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table 3: Sector-Specific Effects
# ============================================================

cat("Table 3: Sector-specific effects\n")

sink("../tables/tab3_sectors.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Employment Effects Track Biometric Exposure}\n")
cat("\\label{tab:sectors}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat("Sector & Biometric & IL $\\times$ Post & Std. & & \\\\\n")
cat(" & Exposure & Coefficient & Error & $p$-value & Obs. \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(sector_dt)) {
  s <- sector_dt[i]
  p <- s$pval
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  cat(sprintf("%s & %.2f & %.3f%s & (%.3f) & %.3f & \\\\\n",
              gsub("_", " ", tools::toTitleCase(s$sector)),
              s$bio_exposure, s$coef, stars, s$se, s$pval))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Each row reports the Illinois $\\times$ Post coefficient from a ")
cat("separate difference-in-differences regression within the indicated sector, using border ")
cat("counties only. Standard errors clustered at the state level. Biometric Exposure is the ")
cat("O*NET-based index (Section~\\ref{sec:data}). Sectors ordered by descending exposure.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table 4: Robustness
# ============================================================

cat("Table 4: Robustness\n")

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Employment Effects Under Alternative Specifications}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Specification & Coefficient & Std. Error & $p$-value \\\\\n")
cat("\\midrule\n")

# Main result
ct_main <- coeftable(m1_border)["triple_cont", ]
cat(sprintf("\\textit{Baseline (border counties)} & %.3f*** & (%.3f) & $<$0.001 \\\\\n",
            ct_main[1], ct_main[2]))

# Pre-COVID
ct_pre <- coeftable(m_precovid)["triple_cont", ]
p_pre <- ct_pre[4]
stars_pre <- ifelse(p_pre < 0.01, "***", ifelse(p_pre < 0.05, "**", ifelse(p_pre < 0.10, "*", "")))
cat(sprintf("Pre-COVID (2015--2019) & %.3f%s & (%.3f) & %.3f \\\\\n",
            ct_pre[1], stars_pre, ct_pre[2], p_pre))

# State x Quarter FE
ct_sq <- coeftable(m_state_qtr)["triple_cont", ]
p_sq <- ct_sq[4]
stars_sq <- ifelse(p_sq < 0.01, "***", ifelse(p_sq < 0.05, "**", ifelse(p_sq < 0.10, "*", "")))
cat(sprintf("State $\\times$ Quarter FE & %.3f%s & (%.3f) & %.3f \\\\\n",
            ct_sq[1], stars_sq, ct_sq[2], p_sq))

# Sector x Quarter FE
ct_secq <- coeftable(m_sector_qtr)["triple_cont", ]
p_secq <- ct_secq[4]
stars_secq <- ifelse(p_secq < 0.01, "***", ifelse(p_secq < 0.05, "**", ifelse(p_secq < 0.10, "*", "")))
cat(sprintf("Sector $\\times$ Quarter FE & %.3f%s & (%.3f) & %.3f \\\\\n",
            ct_secq[1], stars_secq, ct_secq[2], p_secq))

# LOSO
cat(sprintf("Leave-one-state-out range & [%.3f, %.3f] & --- & --- \\\\\n",
            min(loso_dt$coef), max(loso_dt$coef)))

# Placebo
ct_plac <- coeftable(m_placebo)["triple_placebo", ]
cat(sprintf("Placebo (2017Q1) & %.3f & (%.3f) & %.3f \\\\\n",
            ct_plac[1], ct_plac[2], ct_plac[4]))

# Simple DiD
ct_simp <- coeftable(m_simple)["il_post", ]
cat(sprintf("Simple DiD (no industry) & %.3f & (%.3f) & %.3f \\\\\n",
            ct_simp[1], ct_simp[2], ct_simp[4]))

# RI
if (file.exists("../data/ri_summary.json")) {
  ri <- jsonlite::fromJSON("../data/ri_summary.json")
  cat(sprintf("RI $p$-value (state permutation) & --- & --- & %.3f \\\\\n", ri$ri_pval_state))
  cat(sprintf("RI $p$-value (timing permutation) & --- & --- & %.3f \\\\\n", ri$ri_pval_time))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} All specifications use log employment as the dependent variable. ")
cat("The baseline specification includes county-sector and quarter fixed effects with standard ")
cat("errors clustered at the state level. State $\\times$ Quarter FE absorbs state-specific ")
cat("time shocks (including differential COVID responses). Sector $\\times$ Quarter FE absorbs ")
cat("nationwide sector-specific trends. LOSO drops each of five control states in turn. ")
cat("RI permutes the treatment state (5 placebos) and treatment timing (pre-period quarters).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================

cat("Table F1: SDE\n")

# Compute SDEs
pre_data <- df_border[post == 0 & sector != "total"]
sd_emp <- sd(pre_data$log_emp, na.rm = TRUE)
sd_estab <- sd(pre_data$log_estab, na.rm = TRUE)
sd_wage <- sd(pre_data$log_wage, na.rm = TRUE)

ct1 <- coeftable(m1_border)["triple_cont", ]
ct2 <- coeftable(m2_border)["triple_cont", ]
ct3 <- coeftable(m3_border)["triple_cont", ]

sde_emp <- ct1[1] / sd_emp
sde_estab <- ct2[1] / sd_estab
sde_wage <- ct3[1] / sd_wage

se_sde_emp <- ct1[2] / sd_emp
se_sde_estab <- ct2[2] / sd_estab
se_sde_wage <- ct3[2] / sd_wage

classify <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(paste0(ifelse(sde < 0, "Small negative", "Small positive")))
  if (abs_sde < 0.15) return(paste0(ifelse(sde < 0, "Moderate negative", "Moderate positive")))
  return(paste0(ifelse(sde < 0, "Large negative", "Large positive")))
}

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat("\\midrule\n")
cat(sprintf("Employment & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            ct1[1], ct1[2], sd_emp, sde_emp, se_sde_emp, classify(sde_emp)))
cat(sprintf("Establishments & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            ct2[1], ct2[2], sd_estab, sde_estab, se_sde_estab, classify(sde_estab)))
cat(sprintf("Wages & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            ct3[1], ct3[2], sd_wage, sde_wage, se_sde_wage, classify(sde_wage)))

# Panel B: Heterogeneous (by high vs low exposure)
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (High vs. Low Exposure)}} \\\\\n")
cat("\\midrule\n")

# High exposure = information + professional + management
high_exp <- df_border[sector %in% c("information", "professional", "management") & post == 0]
sd_high <- sd(high_exp$log_emp, na.rm = TRUE)
# Use information sector coefficient as proxy for high exposure
info_coef <- sector_dt[sector == "information"]
sde_high <- info_coef$coef / sd_high
se_sde_high <- info_coef$se / sd_high
cat(sprintf("Employment (high exposure) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            info_coef$coef, info_coef$se, sd_high, sde_high, se_sde_high, classify(sde_high)))

# Low exposure = finance + healthcare
low_exp <- df_border[sector %in% c("finance", "healthcare") & post == 0]
sd_low <- sd(low_exp$log_emp, na.rm = TRUE)
fin_coef <- sector_dt[sector == "finance"]
sde_low <- fin_coef$coef / sd_low
se_sde_low <- fin_coef$se / sd_low
cat(sprintf("Employment (low exposure) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            fin_coef$coef, fin_coef$se, sd_low, sde_low, se_sde_low, classify(sde_low)))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} How does a judicial ruling expanding private enforcement of biometric privacy law affect employment and firm structure in exposed industries? ",
  "\\textbf{Policy mechanism:} The 2019 Illinois Supreme Court \\textit{Rosenbach v. Six Flags} ruling eliminated the injury-in-fact requirement for Biometric Information Privacy Act (BIPA) lawsuits, transforming a dormant statute into the most aggressively enforced state privacy law by dramatically increasing expected litigation damages for firms collecting biometric identifiers (fingerprints, face geometry, retina scans). ",
  "\\textbf{Outcome definition:} Log quarterly employment (average of three monthly employment levels) at the county-sector-quarter level from BLS QCEW. ",
  "\\textbf{Treatment:} Continuous biometric exposure index (0--1 scale) constructed from O*NET Technology Skills and Work Context data, measuring the share of occupations in each 2-digit NAICS sector that use biometric or identity-authentication technology, with GLBA and HIPAA preemption discounts for Finance and Healthcare. ",
  "\\textbf{Data:} BLS QCEW, 2015Q1--2024Q4, county-sector-quarter observations for 79 border counties (35 Illinois, 44 neighboring states) across 9 sectors, $N = 19{,}737$. ",
  "\\textbf{Method:} Continuous-exposure triple-difference (Illinois $\\times$ Post-Rosenbach $\\times$ Biometric Exposure) with county-sector and quarter fixed effects, standard errors clustered at the state level. ",
  "\\textbf{Sample:} Border counties sharing a state boundary between Illinois and Indiana, Wisconsin, Missouri, Iowa, or Kentucky; restricted to private-sector employment in sectors with non-suppressed data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (.05$--.15$), Small (.005$--.05$), Null ($< 0.005$)."
)

cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes)
cat("\n\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("\n=== TABLES COMPLETE ===\n")
cat(sprintf("Tables saved to: %s\n", normalizePath("../tables/")))
