#' 06_tables.R — All table generation
#' REACH 2018 Deadline and Chemical Industry Restructuring

source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE)

panel <- fread(paste0(data_dir, "analysis_panel.csv"))
models <- readRDS(paste0(data_dir, "model_objects.rds"))

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
cat("Table 1: Summary statistics...\n")

# Compute by sector group
summ_all <- panel[, .(
  Variable = "All",
  N = .N,
  mean_ent = mean(enterprises, na.rm = TRUE),
  sd_ent = sd(enterprises, na.rm = TRUE),
  mean_emp = mean(employment, na.rm = TRUE),
  sd_emp = sd(employment, na.rm = TRUE),
  mean_turn = mean(turnover, na.rm = TRUE),
  sd_turn = sd(turnover, na.rm = TRUE),
  mean_ln_ent = mean(ln_enterprises, na.rm = TRUE),
  sd_ln_ent = sd(ln_enterprises, na.rm = TRUE),
  mean_ln_emp = mean(ln_employment, na.rm = TRUE),
  sd_ln_emp = sd(ln_employment, na.rm = TRUE),
  mean_ln_turn = mean(ln_turnover, na.rm = TRUE),
  sd_ln_turn = sd(ln_turnover, na.rm = TRUE)
)]

summ_chem <- panel[nace_r2 == "C20", .(
  Variable = "Chemicals (C20)",
  N = .N,
  mean_ent = mean(enterprises, na.rm = TRUE),
  sd_ent = sd(enterprises, na.rm = TRUE),
  mean_emp = mean(employment, na.rm = TRUE),
  sd_emp = sd(employment, na.rm = TRUE),
  mean_turn = mean(turnover, na.rm = TRUE),
  sd_turn = sd(turnover, na.rm = TRUE),
  mean_ln_ent = mean(ln_enterprises, na.rm = TRUE),
  sd_ln_ent = sd(ln_enterprises, na.rm = TRUE),
  mean_ln_emp = mean(ln_employment, na.rm = TRUE),
  sd_ln_emp = sd(ln_employment, na.rm = TRUE),
  mean_ln_turn = mean(ln_turnover, na.rm = TRUE),
  sd_ln_turn = sd(ln_turnover, na.rm = TRUE)
)]

summ_ctrl <- panel[nace_r2 != "C20", .(
  Variable = "Controls (C22-C25)",
  N = .N,
  mean_ent = mean(enterprises, na.rm = TRUE),
  sd_ent = sd(enterprises, na.rm = TRUE),
  mean_emp = mean(employment, na.rm = TRUE),
  sd_emp = sd(employment, na.rm = TRUE),
  mean_turn = mean(turnover, na.rm = TRUE),
  sd_turn = sd(turnover, na.rm = TRUE),
  mean_ln_ent = mean(ln_enterprises, na.rm = TRUE),
  sd_ln_ent = sd(ln_enterprises, na.rm = TRUE),
  mean_ln_emp = mean(ln_employment, na.rm = TRUE),
  sd_ln_emp = sd(ln_employment, na.rm = TRUE),
  mean_ln_turn = mean(ln_turnover, na.rm = TRUE),
  sd_ln_turn = sd(ln_turnover, na.rm = TRUE)
)]

summ_table <- rbind(summ_all, summ_chem, summ_ctrl)

# Generate LaTeX
micro_int <- fread(paste0(data_dir, "micro_intensity.csv"))

tab1_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{l *{3}{S[table-format=5.0] S[table-format=5.0]}}
\\toprule
 & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Chemicals (C20)} & \\multicolumn{2}{c}{Controls (C22--C25)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}
 & {Mean} & {Std.\\ Dev.} & {Mean} & {Std.\\ Dev.} & {Mean} & {Std.\\ Dev.} \\\\
\\midrule
Enterprises & %s & %s & %s & %s & %s & %s \\\\
Employment (persons) & %s & %s & %s & %s & %s & %s \\\\
Turnover (million EUR) & %s & %s & %s & %s & %s & %s \\\\
Log enterprises & %s & %s & %s & %s & %s & %s \\\\
Log employment & %s & %s & %s & %s & %s & %s \\\\
Log turnover & %s & %s & %s & %s & %s & %s \\\\
\\midrule
Micro-firm share (C20, pre-treatment) & %s & %s & & & & \\\\
\\midrule
Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
Countries & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Sample covers %d EU member states, years %d--%d. Chemicals = NACE C20 (manufacture of chemicals and chemical products). Controls = NACE C22 (rubber and plastics), C23 (non-metallic minerals), C24 (basic metals), C25 (fabricated metals). Micro-firm share is the pre-treatment (2014--2017) average share of enterprises with fewer than 10 employees in C20, computed from Eurostat SBS by size class (sbs\\_sc\\_ind\\_r2).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  # Row: Enterprises
  format(round(summ_all$mean_ent), big.mark = ","), format(round(summ_all$sd_ent), big.mark = ","),
  format(round(summ_chem$mean_ent), big.mark = ","), format(round(summ_chem$sd_ent), big.mark = ","),
  format(round(summ_ctrl$mean_ent), big.mark = ","), format(round(summ_ctrl$sd_ent), big.mark = ","),
  # Row: Employment
  format(round(summ_all$mean_emp), big.mark = ","), format(round(summ_all$sd_emp), big.mark = ","),
  format(round(summ_chem$mean_emp), big.mark = ","), format(round(summ_chem$sd_emp), big.mark = ","),
  format(round(summ_ctrl$mean_emp), big.mark = ","), format(round(summ_ctrl$sd_emp), big.mark = ","),
  # Row: Turnover
  format(round(summ_all$mean_turn), big.mark = ","), format(round(summ_all$sd_turn), big.mark = ","),
  format(round(summ_chem$mean_turn), big.mark = ","), format(round(summ_chem$sd_turn), big.mark = ","),
  format(round(summ_ctrl$mean_turn), big.mark = ","), format(round(summ_ctrl$sd_turn), big.mark = ","),
  # Row: Log enterprises
  format(round(summ_all$mean_ln_ent, 2)), format(round(summ_all$sd_ln_ent, 2)),
  format(round(summ_chem$mean_ln_ent, 2)), format(round(summ_chem$sd_ln_ent, 2)),
  format(round(summ_ctrl$mean_ln_ent, 2)), format(round(summ_ctrl$sd_ln_ent, 2)),
  # Row: Log employment
  format(round(summ_all$mean_ln_emp, 2)), format(round(summ_all$sd_ln_emp, 2)),
  format(round(summ_chem$mean_ln_emp, 2)), format(round(summ_chem$sd_ln_emp, 2)),
  format(round(summ_ctrl$mean_ln_emp, 2)), format(round(summ_ctrl$sd_ln_emp, 2)),
  # Row: Log turnover
  format(round(summ_all$mean_ln_turn, 2)), format(round(summ_all$sd_ln_turn, 2)),
  format(round(summ_chem$mean_ln_turn, 2)), format(round(summ_chem$sd_ln_turn, 2)),
  format(round(summ_ctrl$mean_ln_turn, 2)), format(round(summ_ctrl$sd_ln_turn, 2)),
  # Row: Micro-firm share
  format(round(mean(micro_int$micro_share_pre), 3)),
  format(round(sd(micro_int$micro_share_pre), 3)),
  # Observations
  format(summ_all$N, big.mark = ","),
  format(summ_chem$N, big.mark = ","),
  format(summ_ctrl$N, big.mark = ","),
  # Countries
  uniqueN(panel$geo), uniqueN(panel[nace_r2 == "C20"]$geo), uniqueN(panel[nace_r2 != "C20"]$geo),
  # Notes
  uniqueN(panel$geo), min(panel$year), max(panel$year)
)

writeLines(tab1_tex, paste0(tab_dir, "tab1_summary_stats.tex"))

# ===========================================================================
# Table 2: Main DDD Results (hand-crafted LaTeX)
# ===========================================================================
cat("Table 2: Main results...\n")

n_countries <- uniqueN(panel$geo)

# Helper: format coefficient with stars
fmt_coef <- function(coef, pval) {
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
  sprintf("%.4f%s", coef, stars)
}

# Extract from models
m_list <- list(models$m2_ent, models$m2_emp, models$m2_turn, models$m2_tpe)
ddd_coefs <- sapply(m_list, function(m) coef(m)["ddd_2018"])
ddd_ses <- sapply(m_list, function(m) se(m)["ddd_2018"])
ddd_pvals <- sapply(m_list, function(m) pvalue(m)["ddd_2018"])
ddd_nobs <- sapply(m_list, function(m) m$nobs)
ddd_r2 <- sapply(m_list, function(m) r2(m, "r2"))

tab2_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Main Results: Effect of REACH 2018 Deadline on Chemical Industry}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{l*{4}{c}}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & Log Enterprises & Log Employment & Log Turnover & Log Turn./Ent. \\\\
\\midrule
C20 $\\times$ Post-2018 $\\times$ Micro-share & %s & %s & %s & %s \\\\
 & (%s) & (%s) & (%s) & (%s) \\\\
\\midrule
Country $\\times$ Sector FE & Yes & Yes & Yes & Yes \\\\
Country $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\
Sector $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\
Observations & %s & %s & %s & %s \\\\
$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the country level in parentheses (%d clusters). All regressions include country $\\times$ sector, country $\\times$ year, and sector $\\times$ year fixed effects. The C20 $\\times$ Post-2018 interaction is absorbed by sector $\\times$ year fixed effects. Micro-share is the pre-treatment (2014--2017) average share of enterprises with $<$10 employees in NACE C20 chemicals, ranging from 0.23 (Luxembourg) to 0.86 (Czechia). * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  fmt_coef(ddd_coefs[1], ddd_pvals[1]), fmt_coef(ddd_coefs[2], ddd_pvals[2]),
  fmt_coef(ddd_coefs[3], ddd_pvals[3]), fmt_coef(ddd_coefs[4], ddd_pvals[4]),
  sprintf("%.4f", ddd_ses[1]), sprintf("%.4f", ddd_ses[2]),
  sprintf("%.4f", ddd_ses[3]), sprintf("%.4f", ddd_ses[4]),
  format(ddd_nobs[1], big.mark=","), format(ddd_nobs[2], big.mark=","),
  format(ddd_nobs[3], big.mark=","), format(ddd_nobs[4], big.mark=","),
  ddd_r2[1], ddd_r2[2], ddd_r2[3], ddd_r2[4],
  n_countries
)

writeLines(tab2_tex, paste0(tab_dir, "tab2_main_results.tex"))

# ===========================================================================
# Table 3: Placebo and Falsification
# ===========================================================================
cat("Table 3: Placebo and falsification...\n")

# Extract placebo coefficients
plc_coef <- coef(models$m_placebo)["ddd_2013"]
plc_se <- se(models$m_placebo)["ddd_2013"]
plc_pval <- pvalue(models$m_placebo)["ddd_2013"]
plc_nobs <- models$m_placebo$nobs
plc_r2 <- r2(models$m_placebo, "r2")

tab3_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Falsification: REACH 2013 Deadline (Large Firms Only)}
\\label{tab:placebo}
\\begin{threeparttable}
\\begin{tabular}{l*{2}{c}}
\\toprule
 & (1) & (2) \\\\
 & 2018 DDD & 2013 Placebo \\\\
\\midrule
C20 $\\times$ Post-2018 $\\times$ Micro-share & %s & \\\\
 & (%s) & \\\\
C20 $\\times$ Post-2013 $\\times$ Micro-share & & %s \\\\
 & & (%s) \\\\
\\midrule
Sample & 2008--2020 & 2008--2017 \\\\
Country $\\times$ Sector FE & Yes & Yes \\\\
Country $\\times$ Year FE & Yes & Yes \\\\
Sector $\\times$ Year FE & Yes & Yes \\\\
Observations & %s & %s \\\\
$R^2$ & %.3f & %.3f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the country level in parentheses. Column (1) reproduces the main specification. Column (2) restricts to pre-2018 data and estimates the DDD around the May 2013 deadline, which targeted substances $\\geq$100 tonnes/year (predominantly large firms). Under our identification assumption, the 2013 deadline should not differentially affect countries with high micro-firm shares, since large firms were the primary registrants. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  fmt_coef(ddd_coefs[1], ddd_pvals[1]), sprintf("%.4f", ddd_ses[1]),
  fmt_coef(plc_coef, plc_pval), sprintf("%.4f", plc_se),
  format(ddd_nobs[1], big.mark=","), format(plc_nobs, big.mark=","),
  ddd_r2[1], plc_r2
)

writeLines(tab3_tex, paste0(tab_dir, "tab3_placebo.tex"))

# ===========================================================================
# Table C1: Leave-one-out
# ===========================================================================
cat("Table C1: Leave-one-out...\n")

loo <- fread(paste0(data_dir, "robustness_loo.csv"))
loo[, stars := ifelse(pval < 0.01, "***",
              ifelse(pval < 0.05, "**",
              ifelse(pval < 0.10, "*", "")))]

loo_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Leave-One-Country-Out: DDD Coefficient Stability}
\\label{tab:loo}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Country Dropped & Coefficient & Std. Error & p-value & N \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row drops one country from the sample and re-estimates the main DDD specification (log enterprises). Standard errors clustered at the country level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  paste(sprintf("%s & %.4f%s & (%.4f) & %.3f & %s \\\\",
    loo$dropped, loo$coef, loo$stars, loo$se, loo$pval,
    format(loo$N, big.mark = ",")),
    collapse = "\n"))

writeLines(loo_tex, paste0(tab_dir, "tab_c1_loo.tex"))

# ===========================================================================
# Table C2: Alternative control sectors
# ===========================================================================
cat("Table C2: Alternative controls...\n")

alt <- fread(paste0(data_dir, "robustness_alt_controls.csv"))
alt[, stars := ifelse(pval < 0.01, "***",
              ifelse(pval < 0.05, "**",
              ifelse(pval < 0.10, "*", "")))]

alt_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Alternative Control Sectors}
\\label{tab:alt_controls}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Control group & DDD Coefficient & Std. Error & p-value & N \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Row 1 reproduces the baseline specification (C22--C25 as controls). Row 2 uses only C22 (rubber/plastics) and C23 (non-metallic minerals). Row 3 uses only C24 (basic metals) and C25 (fabricated metals). All regressions include the full set of two-way fixed effects and cluster standard errors at the country level.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  paste(sprintf("%s & %.4f%s & (%.4f) & %.3f & %s \\\\",
    alt$specification, alt$coef, alt$stars, alt$se, alt$pval,
    format(alt$N, big.mark = ",")),
    collapse = "\n"))

writeLines(alt_tex, paste0(tab_dir, "tab_c2_alt_controls.tex"))

# ===========================================================================
# Table C3: Alternative timing
# ===========================================================================
cat("Table C3: Alternative timing...\n")

timing <- fread(paste0(data_dir, "robustness_timing.csv"))
timing[, stars := ifelse(pval < 0.01, "***",
                 ifelse(pval < 0.05, "**",
                 ifelse(pval < 0.10, "*", "")))]

timing_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Alternative Treatment Timing}
\\label{tab:timing}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Treatment timing & DDD Coefficient & Std. Error & p-value \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row re-estimates the main DDD specification with an alternative treatment date. Row 1 uses 2017 to test for anticipation effects. Row 2 is the baseline specification (May 2018 deadline). Row 3 uses 2019 to test for delayed effects.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  paste(sprintf("%s & %.4f%s & (%.4f) & %.3f \\\\",
    timing$timing, timing$coef, timing$stars, timing$se, timing$pval),
    collapse = "\n"))

writeLines(timing_tex, paste0(tab_dir, "tab_c3_timing.tex"))

# ===========================================================================
# Table 3 (UPDATED): Placebo with both enterprise and employment outcomes
# ===========================================================================
cat("Table 3 (updated): Placebo with employment...\n")

plc_emp_coef <- coef(models$m_placebo_emp)["ddd_2013"]
plc_emp_se <- se(models$m_placebo_emp)["ddd_2013"]
plc_emp_pval <- pvalue(models$m_placebo_emp)["ddd_2013"]
plc_emp_nobs <- models$m_placebo_emp$nobs
plc_emp_r2 <- r2(models$m_placebo_emp, "r2")

tab3_tex_updated <- sprintf("\\begin{table}[H]
\\centering
\\caption{Falsification: REACH 2013 Deadline (Large Firms Only)}
\\label{tab:placebo}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{l*{4}{c}}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & Log Enterprises & Log Employment & Log Enterprises & Log Employment \\\\
 & 2018 DDD & 2018 DDD & 2013 Placebo & 2013 Placebo \\\\
\\midrule
C20 $\\times$ Post $\\times$ Micro-share & %s & %s & %s & %s \\\\
 & (%s) & (%s) & (%s) & (%s) \\\\
\\midrule
Sample & 2008--2020 & 2008--2020 & 2008--2017 & 2008--2017 \\\\
Micro-share measure & 2014--2017 & 2014--2017 & 2008--2012 & 2008--2012 \\\\
Country $\\times$ Sector FE & Yes & Yes & Yes & Yes \\\\
Country $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\
Sector $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\
Observations & %s & %s & %s & %s \\\\
$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\par\\vspace{0.3em}
{\\footnotesize \\textit{Notes:} Standard errors clustered at the country level in parentheses. Columns (1)--(2) reproduce the main specification using the 2014--2017 average micro-firm share. Columns (3)--(4) restrict to pre-2018 data and estimate the DDD around the May 2013 deadline using a pre-2013 micro-firm share (2008--2012 average) to avoid post-treatment contamination. The 2013 deadline targeted substances $\\geq$100 tonnes/year (predominantly large firms). * p$<$0.10, ** p$<$0.05, *** p$<$0.01.}
\\end{table}",
  fmt_coef(ddd_coefs[1], ddd_pvals[1]), fmt_coef(ddd_coefs[2], ddd_pvals[2]),
  fmt_coef(plc_coef, plc_pval), fmt_coef(plc_emp_coef, plc_emp_pval),
  sprintf("%.4f", ddd_ses[1]), sprintf("%.4f", ddd_ses[2]),
  sprintf("%.4f", plc_se), sprintf("%.4f", plc_emp_se),
  format(ddd_nobs[1], big.mark=","), format(ddd_nobs[2], big.mark=","),
  format(plc_nobs, big.mark=","), format(plc_emp_nobs, big.mark=","),
  ddd_r2[1], ddd_r2[2], plc_r2, plc_emp_r2
)

writeLines(tab3_tex_updated, paste0(tab_dir, "tab3_placebo.tex"))

# ===========================================================================
# Table C4: Employment Robustness (combined)
# ===========================================================================
cat("Table C4: Employment robustness...\n")

loo_emp <- fread(paste0(data_dir, "robustness_loo_employment.csv"))
alt_emp <- fread(paste0(data_dir, "robustness_alt_controls_emp.csv"))
timing_emp <- fread(paste0(data_dir, "robustness_timing_emp.csv"))
ri_emp <- fread(paste0(data_dir, "robustness_ri_emp.csv"))
excl_hr <- fread(paste0(data_dir, "robustness_excl_croatia.csv"))

fmt <- function(x) sprintf("%.4f", x)
fmt_star <- function(coef, pval) {
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
  sprintf("$%s$%s", fmt(coef), stars)
}

tab_c4_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Employment Robustness Checks}
\\label{tab:emp_robust}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lccccc}
\\toprule
Specification & DDD Coeff. & Std.\\ Error & $p$-value & $N$ & Notes \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel A: Alternative Control Sectors}} \\\\
Baseline (C22--C25) & %s & (%s) & %s & %s & \\\\
Narrow (C22--C23) & %s & (%s) & %s & %s & \\\\
Metals (C24--C25) & %s & (%s) & %s & %s & \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel B: Alternative Treatment Timing}} \\\\
2017 (anticipation) & %s & (%s) & %s & %s & \\\\
2018 (baseline) & %s & (%s) & %s & %s & \\\\
2019 (delayed) & %s & (%s) & %s & %s & \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel C: Sample Restrictions}} \\\\
Exclude Croatia & %s & (%s) & %s & %s & EU member from 2013 \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel D: Inference}} \\\\
Leave-one-out range & \\multicolumn{4}{l}{[%s, %s]} & 27 jackknife samples \\\\
Randomization inference & \\multicolumn{4}{l}{$p = %s$} & 1,000 permutations \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\par\\vspace{0.3em}
{\\footnotesize \\textit{Notes:} All specifications use log employment as the dependent variable with country $\\times$ sector, country $\\times$ year, and sector $\\times$ year fixed effects and country-clustered standard errors. Panel A varies the control sectors. Panel B varies the treatment date. Panel C excludes Croatia (EU member only from July 2013). Panel D reports the range of LOO jackknife coefficients and the two-sided Fisher exact $p$-value from permuting country-level micro-firm shares. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.}
\\end{table}",
  # Panel A
  fmt_star(alt_emp$coef[1], alt_emp$pval[1]), fmt(alt_emp$se[1]), fmt(alt_emp$pval[1]), format(alt_emp$N[1], big.mark=","),
  fmt_star(alt_emp$coef[2], alt_emp$pval[2]), fmt(alt_emp$se[2]), fmt(alt_emp$pval[2]), format(alt_emp$N[2], big.mark=","),
  fmt_star(alt_emp$coef[3], alt_emp$pval[3]), fmt(alt_emp$se[3]), fmt(alt_emp$pval[3]), format(alt_emp$N[3], big.mark=","),
  # Panel B
  fmt_star(timing_emp$coef[1], timing_emp$pval[1]), fmt(timing_emp$se[1]), fmt(timing_emp$pval[1]), format(timing_emp$N[1], big.mark=","),
  fmt_star(timing_emp$coef[2], timing_emp$pval[2]), fmt(timing_emp$se[2]), fmt(timing_emp$pval[2]), format(timing_emp$N[2], big.mark=","),
  fmt_star(timing_emp$coef[3], timing_emp$pval[3]), fmt(timing_emp$se[3]), fmt(timing_emp$pval[3]), format(timing_emp$N[3], big.mark=","),
  # Panel C
  fmt_star(excl_hr$coef[2], excl_hr$pval[2]), fmt(excl_hr$se[2]), fmt(excl_hr$pval[2]), format(excl_hr$N[2], big.mark=","),
  # Panel D
  fmt(min(loo_emp$coef, na.rm = TRUE)), fmt(max(loo_emp$coef, na.rm = TRUE)),
  sprintf("%.3f", ri_emp$ri_pval)
)

writeLines(tab_c4_tex, paste0(tab_dir, "tab_c4_emp_robust.tex"))

# ===========================================================================
# Table 4: Sensitivity to Identification Assumptions
# ===========================================================================
cat("Table 4: Sensitivity specifications...\n")

# Load trend-adjusted and alternative intensity models
trend_models <- models  # Already in model_objects.rds from 03_main_analysis.R

# Read window results
windows <- fread(paste0(data_dir, "robustness_windows.csv"))

# Build table rows
sens_rows <- list(
  list(spec = "Baseline",
       ent_c = coef(models$m2_ent)["ddd_2018"], ent_s = se(models$m2_ent)["ddd_2018"],
       ent_p = pvalue(models$m2_ent)["ddd_2018"], ent_n = models$m2_ent$nobs,
       emp_c = coef(models$m2_emp)["ddd_2018"], emp_s = se(models$m2_emp)["ddd_2018"],
       emp_p = pvalue(models$m2_emp)["ddd_2018"], emp_n = models$m2_emp$nobs),
  list(spec = "With differential trend",
       ent_c = coef(models$m_trend_ent)["ddd_2018"], ent_s = se(models$m_trend_ent)["ddd_2018"],
       ent_p = pvalue(models$m_trend_ent)["ddd_2018"], ent_n = models$m_trend_ent$nobs,
       emp_c = coef(models$m_trend_emp)["ddd_2018"], emp_s = se(models$m_trend_emp)["ddd_2018"],
       emp_p = pvalue(models$m_trend_emp)["ddd_2018"], emp_n = models$m_trend_emp$nobs),
  list(spec = "2008 micro-share (pre-REACH)",
       ent_c = coef(models$m_early_ent)[1], ent_s = se(models$m_early_ent)[1],
       ent_p = pvalue(models$m_early_ent)[1], ent_n = models$m_early_ent$nobs,
       emp_c = coef(models$m_early_emp)[1], emp_s = se(models$m_early_emp)[1],
       emp_p = pvalue(models$m_early_emp)[1], emp_n = models$m_early_emp$nobs),
  list(spec = "Common sample",
       ent_c = coef(models$m_common_ent)[1], ent_s = se(models$m_common_ent)[1],
       ent_p = pvalue(models$m_common_ent)[1], ent_n = models$m_common_ent$nobs,
       emp_c = coef(models$m_common_emp)[1], emp_s = se(models$m_common_emp)[1],
       emp_p = pvalue(models$m_common_emp)[1], emp_n = models$m_common_emp$nobs),
  list(spec = "Drop 2020 (2008--2019)",
       ent_c = windows$ent_coef[2], ent_s = windows$ent_se[2],
       ent_p = windows$ent_pval[2], ent_n = windows$ent_N[2],
       emp_c = windows$emp_coef[2], emp_s = windows$emp_se[2],
       emp_p = windows$emp_pval[2], emp_n = windows$emp_N[2]),
  list(spec = "Short window (2014--2019)",
       ent_c = windows$ent_coef[3], ent_s = windows$ent_se[3],
       ent_p = windows$ent_pval[3], ent_n = windows$ent_N[3],
       emp_c = windows$emp_coef[3], emp_s = windows$emp_se[3],
       emp_p = windows$emp_pval[3], emp_n = windows$emp_N[3])
)

sens_body <- paste(sapply(sens_rows, function(r) {
  sprintf("%s & %s & %s & %s & %s \\\\
 & (%s) & (%s) & & \\\\",
    r$spec,
    fmt_coef(r$ent_c, r$ent_p), fmt_coef(r$emp_c, r$emp_p),
    format(r$ent_n, big.mark=","), format(r$emp_n, big.mark=","),
    sprintf("%.4f", r$ent_s), sprintf("%.4f", r$emp_s))
}), collapse = "\n")

tab4_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Sensitivity to Identification Assumptions}
\\label{tab:sensitivity}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{l*{4}{c}}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & Log Enterprises & Log Employment & $N$ (Ent.) & $N$ (Emp.) \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\par\\vspace{0.3em}
{\\footnotesize \\textit{Notes:} All specifications include country $\\times$ sector, country $\\times$ year, and sector $\\times$ year fixed effects with standard errors clustered at the country level. Row 1 is the baseline. Row 2 adds C20 $\\times$ micro-share $\\times$ year (centered) to control for differential linear trends. Row 3 uses 2008-only micro-firm shares (pre-REACH entry into force) as treatment intensity. Row 4 restricts to the common sample with non-missing values for both outcomes. Row 5 drops 2020 (COVID). Row 6 uses a short symmetric window (2014--2019). * p$<$0.10, ** p$<$0.05, *** p$<$0.01.}
\\end{table}", sens_body)

writeLines(tab4_tex, paste0(tab_dir, "tab4_sensitivity.tex"))

cat("\nAll tables saved to", tab_dir, "\n")
