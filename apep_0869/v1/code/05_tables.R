# 05_tables.R — Generate all LaTeX tables
# APEP-0869: The Litigation Tax on Biometrics

source("00_packages.R")

# ============================================================
# Load models and data
# ============================================================

load("../data/main_models.RData")
load("../data/robustness_models.RData")
df <- fread("../data/analysis_panel.csv")
df_border <- fread("../data/border_panel.csv")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("Generating Table 1: Summary Statistics\n")

df_summ <- df_border[sector != "total"]

# Pre-period only for SD(Y) calculations
df_pre <- df_summ[post == 0]

# Summary by IL vs control, exposed vs exempt
summ_groups <- df_summ[, .(
  `Mean Employment` = mean(employment, na.rm = TRUE),
  `SD Employment` = sd(employment, na.rm = TRUE),
  `Mean Establishments` = mean(establishments, na.rm = TRUE),
  `SD Establishments` = sd(establishments, na.rm = TRUE),
  `Mean Weekly Wage` = mean(avg_weekly_wage, na.rm = TRUE),
  `SD Weekly Wage` = sd(avg_weekly_wage, na.rm = TRUE),
  `Counties` = uniqueN(area_fips),
  `Observations` = .N
), by = .(Group = fifelse(illinois == 1, "Illinois", "Border States"),
          Industry = fifelse(exposed == 1, "Biometric-Exposed", "BIPA-Exempt"))]

# Format table
tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Border Counties, 2015--2023}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llrrrrrr}\n",
  "\\toprule\n",
  " & & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Establishments} & \\multicolumn{2}{c}{Avg Weekly Wage} \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6} \\cmidrule(lr){7-8}\n",
  "Group & Industry & Mean & SD & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(summ_groups)) {
  row <- summ_groups[i]
  tab1_tex <- paste0(tab1_tex, sprintf(
    "%s & %s & %s & %s & %s & %s & \\$%s & \\$%s \\\\\n",
    row$Group, row$Industry,
    formatC(round(row$`Mean Employment`), format = "d", big.mark = ","),
    formatC(round(row$`SD Employment`), format = "d", big.mark = ","),
    formatC(round(row$`Mean Establishments`), format = "d", big.mark = ","),
    formatC(round(row$`SD Establishments`), format = "d", big.mark = ","),
    formatC(round(row$`Mean Weekly Wage`), format = "d", big.mark = ","),
    formatC(round(row$`SD Weekly Wage`), format = "d", big.mark = ",")
  ))
}

n_il <- uniqueN(df_summ[illinois == 1]$area_fips)
n_ctrl <- uniqueN(df_summ[illinois == 0]$area_fips)
n_obs <- nrow(df_summ)

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sprintf("\\item \\textit{Notes:} N = %s county-sector-quarter observations from %d Illinois border counties and %d neighboring-state border counties, 2015Q1--2023Q4. Biometric-exposed industries: Information (NAICS 51), Professional/Technical Services (54), Manufacturing (31--33). BIPA-exempt industries: Finance (52, covered by GLBA), Healthcare (62, covered by HIPAA). Employment is the average of three monthly levels per quarter from BLS QCEW.\n",
           formatC(n_obs, format = "d", big.mark = ","), n_il, n_ctrl),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ============================================================
# TABLE 2: Main Triple-Difference Results
# ============================================================

cat("Generating Table 2: Main Results\n")

# Extract triple-diff coefficients
extract_coef <- function(model, varname = "triple") {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  n <- model$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = s, pval = p, n = n, stars = stars)
}

results <- list(
  emp_all = extract_coef(m1_emp_all),
  estab_all = extract_coef(m1_estab_all),
  wage_all = extract_coef(m1_wage_all),
  emp_border = extract_coef(m1_emp_border),
  estab_border = extract_coef(m1_estab_border),
  wage_border = extract_coef(m1_wage_border)
)

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{The Litigation Tax: Triple-Difference Estimates}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{All Counties} & \\multicolumn{3}{c}{Border Counties} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  " & Log Emp & Log Estab & Log Wage & Log Emp & Log Estab & Log Wage \\\\\n",
  "\\midrule\n",
  sprintf("IL $\\times$ Exposed $\\times$ Post & %s%s & %s%s & %s%s & %s%s & %s%s & %s%s \\\\\n",
          formatC(results$emp_all$b, format = "f", digits = 4), results$emp_all$stars,
          formatC(results$estab_all$b, format = "f", digits = 4), results$estab_all$stars,
          formatC(results$wage_all$b, format = "f", digits = 4), results$wage_all$stars,
          formatC(results$emp_border$b, format = "f", digits = 4), results$emp_border$stars,
          formatC(results$estab_border$b, format = "f", digits = 4), results$estab_border$stars,
          formatC(results$wage_border$b, format = "f", digits = 4), results$wage_border$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) & (%s) \\\\\n",
          formatC(results$emp_all$se, format = "f", digits = 4),
          formatC(results$estab_all$se, format = "f", digits = 4),
          formatC(results$wage_all$se, format = "f", digits = 4),
          formatC(results$emp_border$se, format = "f", digits = 4),
          formatC(results$estab_border$se, format = "f", digits = 4),
          formatC(results$wage_border$se, format = "f", digits = 4)),
  "\\midrule\n",
  "County $\\times$ Sector FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
          formatC(results$emp_all$n, format = "d", big.mark = ","),
          formatC(results$estab_all$n, format = "d", big.mark = ","),
          formatC(results$wage_all$n, format = "d", big.mark = ","),
          formatC(results$emp_border$n, format = "d", big.mark = ","),
          formatC(results$estab_border$n, format = "d", big.mark = ","),
          formatC(results$wage_border$n, format = "d", big.mark = ",")
          ),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the coefficient on the triple interaction IL $\\times$ Exposed $\\times$ Post from equation (1). Exposed industries: Information (NAICS 51), Professional/Technical Services (54), Manufacturing (31--33). Exempt industries: Finance (52), Healthcare (62). Post = 2019Q1 onward (after \\textit{Rosenbach v.~Six Flags}, Jan 25, 2019). Columns 1--3 use all counties in Illinois, Indiana, Wisconsin, Missouri, Iowa, and Kentucky. Columns 4--6 restrict to border counties (adjacent across state lines). Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ============================================================
# TABLE 3: Robustness checks
# ============================================================

cat("Generating Table 3: Robustness\n")

# Collect robustness results
r_precovid <- extract_coef(m_precovid_emp)
r_narrow <- extract_coef(m_narrow, "triple_narrow")
r_placebo <- extract_coef(m_placebo, "fake_triple")
r_simple <- extract_coef(m_simple, "il_post")

# LOSO range
loso_range <- sprintf("[%s, %s]",
                      formatC(min(loso_dt$coef), format = "f", digits = 4),
                      formatC(max(loso_dt$coef), format = "f", digits = 4))

# WCB p-value
wcb_pval <- if (!is.null(boot_result)) formatC(boot_result$p_val, format = "f", digits = 3) else "---"

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Specification & Coefficient & SE & $p$-value & $N$ \\\\\n",
  "\\midrule\n",
  sprintf("\\textit{Panel A: Alternative samples} & & & & \\\\\n"),
  sprintf("Pre-COVID (2015--2019) & %s%s & (%s) & %s & %s \\\\\n",
          formatC(r_precovid$b, format = "f", digits = 4), r_precovid$stars,
          formatC(r_precovid$se, format = "f", digits = 4),
          formatC(r_precovid$pval, format = "f", digits = 3),
          formatC(r_precovid$n, format = "d", big.mark = ",")),
  sprintf("Leave-one-state-out range & %s & & & \\\\\n", loso_range),
  "\\midrule\n",
  sprintf("\\textit{Panel B: Alternative specifications} & & & & \\\\\n"),
  sprintf("Info vs Healthcare only & %s%s & (%s) & %s & %s \\\\\n",
          formatC(r_narrow$b, format = "f", digits = 4), r_narrow$stars,
          formatC(r_narrow$se, format = "f", digits = 4),
          formatC(r_narrow$pval, format = "f", digits = 3),
          formatC(r_narrow$n, format = "d", big.mark = ",")),
  sprintf("Simple DiD (all sectors) & %s%s & (%s) & %s & %s \\\\\n",
          formatC(r_simple$b, format = "f", digits = 4), r_simple$stars,
          formatC(r_simple$se, format = "f", digits = 4),
          formatC(r_simple$pval, format = "f", digits = 3),
          formatC(r_simple$n, format = "d", big.mark = ",")),
  "\\midrule\n",
  sprintf("\\textit{Panel C: Placebo and inference} & & & & \\\\\n"),
  sprintf("Placebo (fake treatment 2017Q1) & %s%s & (%s) & %s & %s \\\\\n",
          formatC(r_placebo$b, format = "f", digits = 4), r_placebo$stars,
          formatC(r_placebo$se, format = "f", digits = 4),
          formatC(r_placebo$pval, format = "f", digits = 3),
          formatC(r_placebo$n, format = "d", big.mark = ",")),
  sprintf("Wild cluster bootstrap $p$ & & & %s & \\\\\n", wcb_pval),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications use the border-county sample unless noted. Panel A varies the sample: pre-COVID restricts to 2015Q1--2019Q4; leave-one-state-out drops each control state in turn. Panel B varies the specification: ``Info vs Healthcare'' restricts to NAICS 51 and 62; ``Simple DiD'' pools all sectors. Panel C: placebo assigns fake treatment at 2017Q1 using pre-period data only; wild cluster bootstrap uses Webb weights with 9,999 replications. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_robustness.tex")

# ============================================================
# TABLE 4: Industry-level heterogeneity
# ============================================================

cat("Generating Table 4: Industry Heterogeneity\n")

df_het <- df_border[sector != "total"]
df_het[, il_post := illinois * post]

# Run separate DiD for each exposed sector
sectors_exposed <- c("information", "professional")
het_results <- list()

for (sec in sectors_exposed) {
  df_sec <- df_het[sector == sec | exposed == 0]
  df_sec[, treated_sec := fifelse(sector == sec, 1L, 0L)]
  df_sec[, triple_sec := illinois * treated_sec * post]
  df_sec[, il_treated := illinois * treated_sec]
  df_sec[, treated_post := treated_sec * post]

  m_sec <- feols(log_emp ~ triple_sec + il_post + treated_post + il_treated |
                   county_sector + yearqtr,
                 data = df_sec,
                 cluster = ~state_fips)
  het_results[[sec]] <- extract_coef(m_sec, "triple_sec")
}

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Industry Heterogeneity: Effect on Log Employment by Sector}\n",
  "\\label{tab:het}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Information & Professional \\\\\n",
  " & (NAICS 51) & (NAICS 54) \\\\\n",
  "\\midrule\n",
  sprintf("IL $\\times$ Sector $\\times$ Post & %s%s & %s%s \\\\\n",
          formatC(het_results$information$b, format = "f", digits = 4), het_results$information$stars,
          formatC(het_results$professional$b, format = "f", digits = 4), het_results$professional$stars),
  sprintf(" & (%s) & (%s) \\\\\n",
          formatC(het_results$information$se, format = "f", digits = 4),
          formatC(het_results$professional$se, format = "f", digits = 4)),
  "\\midrule\n",
  "County $\\times$ Sector FE & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s \\\\\n",
          formatC(het_results$information$n, format = "d", big.mark = ","),
          formatC(het_results$professional$n, format = "d", big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the triple-difference coefficient for a specific exposed sector versus the two exempt sectors (Finance and Healthcare) in Illinois border counties relative to neighboring-state border counties. Information (NAICS 51) includes data processing, telecommunications, and publishing. Professional Services (NAICS 54) includes computer systems design, engineering, and consulting. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_heterogeneity.tex")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================

cat("Generating Table F1: Standardized Effect Sizes\n")

# Pre-treatment SDs for SDE calculation
sd_log_emp <- sd(df_border[sector != "total" & post == 0]$log_emp, na.rm = TRUE)
sd_log_estab <- sd(df_border[sector != "total" & post == 0]$log_estab, na.rm = TRUE)
sd_log_wage <- sd(df_border[sector != "total" & post == 0]$log_wage, na.rm = TRUE)

# SDE classification
classify_sde <- function(s) {
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

# Panel A: Pooled (border-county triple-diff)
beta_emp <- coef(m1_emp_border)["triple"]
se_emp <- se(m1_emp_border)["triple"]
sde_emp <- beta_emp / sd_log_emp
se_sde_emp <- se_emp / sd_log_emp

beta_estab <- coef(m1_estab_border)["triple"]
se_estab <- se(m1_estab_border)["triple"]
sde_estab <- beta_estab / sd_log_estab
se_sde_estab <- se_estab / sd_log_estab

beta_wage <- coef(m1_wage_border)["triple"]
se_wage <- se(m1_wage_border)["triple"]
sde_wage <- beta_wage / sd_log_wage
se_sde_wage <- se_wage / sd_log_wage

# Panel B: Heterogeneous (Information vs Manufacturing)
# Information subsample
beta_info <- het_results$information$b
se_info <- het_results$information$se
sd_log_emp_info <- sd(df_border[sector %in% c("information", "finance", "healthcare") & post == 0]$log_emp, na.rm = TRUE)
sde_info <- beta_info / sd_log_emp_info
se_sde_info <- se_info / sd_log_emp_info

# Professional subsample
beta_prof <- het_results$professional$b
se_prof <- het_results$professional$se
sd_log_emp_prof <- sd(df_border[sector %in% c("professional", "finance", "healthcare") & post == 0]$log_emp, na.rm = TRUE)
sde_prof <- beta_prof / sd_log_emp_prof
se_sde_prof <- se_prof / sd_log_emp_prof

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the 2019 Illinois Supreme Court ruling in \\textit{Rosenbach v.~Six Flags}, which eliminated the injury requirement for biometric privacy lawsuits under BIPA, reduce employment and business activity in biometric-exposed industries in Illinois relative to neighboring states? ",
  "\\textbf{Policy mechanism:} The ruling transformed BIPA from a dormant statute into the most actively litigated privacy law in the US by allowing any individual whose biometric data was collected without proper consent to sue for statutory damages (\\$1,000--\\$5,000 per violation), even without demonstrating actual harm; this created enormous litigation exposure for firms using fingerprint scanners, facial recognition, or other biometric technologies. ",
  "\\textbf{Outcome definition:} Log quarterly county-level employment (average of three monthly levels from QCEW) and log quarterly establishment counts, by NAICS sector. ",
  "\\textbf{Treatment:} Binary: Illinois counties in biometric-exposed industries (Information, Manufacturing, Professional/Technical Services) versus BIPA-exempt industries (Finance under GLBA, Healthcare under HIPAA) after the January 25, 2019 ruling. ",
  "\\textbf{Data:} BLS Quarterly Census of Employment and Wages (QCEW), 2015Q1--2023Q4, county-sector-quarter panel for Illinois and five border states (Indiana, Wisconsin, Missouri, Iowa, Kentucky). ",
  "\\textbf{Method:} Triple-difference (Illinois $\\times$ exposed industry $\\times$ post-ruling) with county-sector and quarter fixed effects; standard errors clustered at the state level; wild cluster bootstrap for few-cluster inference. ",
  "\\textbf{Sample:} Border counties only (counties sharing a state boundary between Illinois and neighboring states) to sharpen geographic comparison. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build SDE table
sde_tex <- paste0(
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
  sprintf("Log Employment & Border triple-diff & %s & %s & %s & %s & %s & %s \\\\\n",
          formatC(beta_emp, format = "f", digits = 4),
          formatC(se_emp, format = "f", digits = 4),
          formatC(sd_log_emp, format = "f", digits = 3),
          formatC(sde_emp, format = "f", digits = 4),
          formatC(se_sde_emp, format = "f", digits = 4),
          classify_sde(sde_emp)),
  sprintf("Log Establishments & Border triple-diff & %s & %s & %s & %s & %s & %s \\\\\n",
          formatC(beta_estab, format = "f", digits = 4),
          formatC(se_estab, format = "f", digits = 4),
          formatC(sd_log_estab, format = "f", digits = 3),
          formatC(sde_estab, format = "f", digits = 4),
          formatC(se_sde_estab, format = "f", digits = 4),
          classify_sde(sde_estab)),
  sprintf("Log Weekly Wage & Border triple-diff & %s & %s & %s & %s & %s & %s \\\\\n",
          formatC(beta_wage, format = "f", digits = 4),
          formatC(se_wage, format = "f", digits = 4),
          formatC(sd_log_wage, format = "f", digits = 3),
          formatC(sde_wage, format = "f", digits = 4),
          formatC(se_sde_wage, format = "f", digits = 4),
          classify_sde(sde_wage)),
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("Log Emp (Information) & Info vs exempt & %s & %s & %s & %s & %s & %s \\\\\n",
          formatC(beta_info, format = "f", digits = 4),
          formatC(se_info, format = "f", digits = 4),
          formatC(sd_log_emp_info, format = "f", digits = 3),
          formatC(sde_info, format = "f", digits = 4),
          formatC(se_sde_info, format = "f", digits = 4),
          classify_sde(sde_info)),
  sprintf("Log Emp (Professional) & Prof vs exempt & %s & %s & %s & %s & %s & %s \\\\\n",
          formatC(beta_prof, format = "f", digits = 4),
          formatC(se_prof, format = "f", digits = 4),
          formatC(sd_log_emp_prof, format = "f", digits = 3),
          formatC(sde_prof, format = "f", digits = 4),
          formatC(se_sde_prof, format = "f", digits = 4),
          classify_sde(sde_prof)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Files written:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_robustness.tex\n")
cat("  tables/tab4_heterogeneity.tex\n")
cat("  tables/tabF1_sde.tex\n")
