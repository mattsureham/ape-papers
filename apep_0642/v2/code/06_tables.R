## 06_tables.R — Generate all LaTeX tables
## APEP-0642 v2: Regulatory Whack-a-Mole

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# Load models
models <- readRDS(file.path(data_dir, "models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))
df <- fread(file.path(data_dir, "analysis_panel.csv"))

# Helper: format numbers with significance stars
fmt_coef <- function(est, se, pval) {
  stars <- ""
  if (!is.na(pval)) {
    if (pval < 0.01) stars <- "***"
    else if (pval < 0.05) stars <- "**"
    else if (pval < 0.1) stars <- "*"
  }
  paste0(sprintf("%.4f", est), stars)
}

fmt_se <- function(se_val) {
  sprintf("(%.4f)", se_val)
}

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

summ <- df[, .(mean = mean(releases, na.rm = TRUE),
               sd = sd(releases, na.rm = TRUE),
               median = median(releases, na.rm = TRUE),
               pct_zero = mean(releases == 0, na.rm = TRUE) * 100,
               n = .N),
           by = medium_cat][order(match(medium_cat, c("Air", "Water", "Land", "POTW")))]

# CWA/RCRA stats
n_fac <- uniqueN(df$frs_id)
n_chem <- uniqueN(df$cas)
n_fc <- uniqueN(df$fc_id)
n_cwa <- if ("cwa_inspected" %in% names(df)) uniqueN(df$frs_id[df$cwa_inspected == 1]) else 0
n_rcra <- if ("rcra_inspected" %in% names(df)) uniqueN(df$frs_id[df$rcra_inspected == 1]) else 0
caa_share <- round(mean(df[medium_cat == "Air", caa_chemical == "YES"]) * 100, 1)

tab1 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{tabular}{lrrrrr}
\\toprule
& Mean & SD & Median & \\% Zero & N \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel A: Releases by Medium (pounds)}} \\\\[3pt]
Air releases & ", sprintf("%.1f", summ[medium_cat == "Air", mean]), " & ",
  sprintf("%.1f", summ[medium_cat == "Air", sd]), " & ",
  sprintf("%.1f", summ[medium_cat == "Air", median]), " & ",
  sprintf("%.1f", summ[medium_cat == "Air", pct_zero]), " & ",
  format(summ[medium_cat == "Air", n], big.mark = ","), " \\\\
Water releases & ", sprintf("%.1f", summ[medium_cat == "Water", mean]), " & ",
  sprintf("%.1f", summ[medium_cat == "Water", sd]), " & ",
  sprintf("%.1f", summ[medium_cat == "Water", median]), " & ",
  sprintf("%.1f", summ[medium_cat == "Water", pct_zero]), " & ",
  format(summ[medium_cat == "Water", n], big.mark = ","), " \\\\
Land releases & ", sprintf("%.1f", summ[medium_cat == "Land", mean]), " & ",
  sprintf("%.1f", summ[medium_cat == "Land", sd]), " & ",
  sprintf("%.1f", summ[medium_cat == "Land", median]), " & ",
  sprintf("%.1f", summ[medium_cat == "Land", pct_zero]), " & ",
  format(summ[medium_cat == "Land", n], big.mark = ","), " \\\\
POTW transfers & ", sprintf("%.1f", summ[medium_cat == "POTW", mean]), " & ",
  sprintf("%.1f", summ[medium_cat == "POTW", sd]), " & ",
  sprintf("%.1f", summ[medium_cat == "POTW", median]), " & ",
  sprintf("%.1f", summ[medium_cat == "POTW", pct_zero]), " & ",
  format(summ[medium_cat == "POTW", n], big.mark = ","), " \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel B: Sample Characteristics}} \\\\[3pt]
Facilities & \\multicolumn{5}{l}{", format(n_fac, big.mark = ","), "} \\\\
Chemicals & \\multicolumn{5}{l}{", format(n_chem, big.mark = ","), "} \\\\
Facility-chemicals & \\multicolumn{5}{l}{", format(n_fc, big.mark = ","), "} \\\\
CAA-regulated (\\%) & \\multicolumn{5}{l}{", caa_share, "} \\\\
CWA-inspected facilities & \\multicolumn{5}{l}{", format(n_cwa, big.mark = ","), "} \\\\
RCRA-inspected facilities & \\multicolumn{5}{l}{", format(n_rcra, big.mark = ","), "} \\\\
Years & \\multicolumn{5}{l}{", paste(range(df$YEAR), collapse = "--"), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Pre-inspection releases in the analysis sample (event window $\\pm 5$ years). The panel is at the facility $\\times$ chemical $\\times$ medium $\\times$ year level. CWA (Clean Water Act) and RCRA (Resource Conservation and Recovery Act) inspections from EPA ICIS-NPDES and RCRAInfo databases. CAA-regulated share based on TRI chemical designation (Column 42).
\\end{minipage}
\\end{table}")

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Triple-Difference (baseline + CWA controls)
# ============================================================
cat("=== Table 2: Main Triple-Difference ===\n")

m1 <- models$m1_baseline
m2 <- models$m2_cwa
m3 <- models$m3_cwa_rcra

tab2 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Cross-Media Pollution Substitution: Main Results}
\\label{tab:main}
\\begin{tabular}{lccc}
\\toprule
& (1) & (2) & (3) \\\\
& Baseline & CWA Controls & CWA + RCRA \\\\
\\midrule
Post $\\times$ Air & ", fmt_coef(coef(m1)["post_air"], se(m1)["post_air"], pvalue(m1)["post_air"]), " & ",
  fmt_coef(coef(m2)["post_air"], se(m2)["post_air"], pvalue(m2)["post_air"]), " & ",
  fmt_coef(coef(m3)["post_air"], se(m3)["post_air"], pvalue(m3)["post_air"]), " \\\\
& ", fmt_se(se(m1)["post_air"]), " & ", fmt_se(se(m2)["post_air"]), " & ", fmt_se(se(m3)["post_air"]), " \\\\[6pt]
Post $\\times$ Non-Air & ", fmt_coef(coef(m1)["post_nonair"], se(m1)["post_nonair"], pvalue(m1)["post_nonair"]), " & ",
  fmt_coef(coef(m2)["post_nonair"], se(m2)["post_nonair"], pvalue(m2)["post_nonair"]), " & ",
  fmt_coef(coef(m3)["post_nonair"], se(m3)["post_nonair"], pvalue(m3)["post_nonair"]), " \\\\
& ", fmt_se(se(m1)["post_nonair"]), " & ", fmt_se(se(m2)["post_nonair"]), " & ", fmt_se(se(m3)["post_nonair"]), " \\\\[6pt]",
if ("cwa_inspected" %in% names(coef(m2))) paste0("
CWA Inspected & & ", fmt_coef(coef(m2)["cwa_inspected"], se(m2)["cwa_inspected"], pvalue(m2)["cwa_inspected"]), " & ",
  fmt_coef(coef(m3)["cwa_inspected"], se(m3)["cwa_inspected"], pvalue(m3)["cwa_inspected"]), " \\\\
& & ", fmt_se(se(m2)["cwa_inspected"]), " & ", fmt_se(se(m3)["cwa_inspected"]), " \\\\[6pt]") else "", "
\\midrule
Observations & ", format(nobs(m1), big.mark = ","), " & ",
  format(nobs(m2), big.mark = ","), " & ", format(nobs(m3), big.mark = ","), " \\\\
Facility $\\times$ Chem $\\times$ Medium FE & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes \\\\
Clustering & Facility & Facility & Facility \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Dependent variable is log(releases + 1), winsorized at the 99th percentile by medium. Column~(1) reproduces the baseline triple-difference. Column~(2) adds CWA inspection controls. Column~(3) adds both CWA and RCRA inspection controls. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Medium-Specific Decomposition [CENTRAL TABLE]
# ============================================================
cat("=== Table 3: Medium-Specific Decomposition ===\n")

mn <- models$medium_results_noctl
mc <- models$medium_results_ctl

tab3_rows <- ""
for (m in c("Air", "Water", "Land", "POTW")) {
  noctl <- mn[[m]]
  ctl <- mc[[m]]
  tab3_rows <- paste0(tab3_rows, "
", m, " & ",
    fmt_coef(coef(noctl)["post"], se(noctl)["post"], pvalue(noctl)["post"]), " & ",
    fmt_coef(coef(ctl)["post"], se(ctl)["post"], pvalue(ctl)["post"]), " \\\\
& ", fmt_se(se(noctl)["post"]), " & ", fmt_se(se(ctl)["post"]), " \\\\[6pt]")
}

tab3 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Medium-Specific Decomposition: Effect of CAA Inspections by Release Pathway}
\\label{tab:decomp}
\\begin{tabular}{lcc}
\\toprule
& (1) & (2) \\\\
& Without Enforcement & With CWA/RCRA \\\\
& Controls & Controls \\\\
\\midrule", tab3_rows, "
\\midrule
Facility $\\times$ Chemical FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
CWA/RCRA Controls & No & Yes \\\\
Clustering & Facility & Facility \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Each row reports the post-inspection coefficient from a separate regression of log(releases + 1) on a post-inspection indicator, estimated within each release medium. Column~(1) includes no cross-program enforcement controls. Column~(2) adds indicators for contemporaneous CWA and RCRA inspections. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab3, file.path(tables_dir, "tab3_decomp.tex"))

# ============================================================
# Table 4: CAA vs Non-CAA Mechanism
# ============================================================
cat("=== Table 4: Mechanism (CAA vs Non-CAA) ===\n")

m_caa <- models$m_caa_ctl
m_nc  <- models$m_noncaa_ctl

tab4 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Mechanism Test: CAA-Regulated vs.\\ Non-CAA Chemicals}
\\label{tab:mechanism}
\\begin{tabular}{lcc}
\\toprule
& (1) & (2) \\\\
& CAA Chemicals & Non-CAA Chemicals \\\\
\\midrule
Post $\\times$ Air & ", fmt_coef(coef(m_caa)["post_air"], se(m_caa)["post_air"], pvalue(m_caa)["post_air"]), " & ",
  fmt_coef(coef(m_nc)["post_air"], se(m_nc)["post_air"], pvalue(m_nc)["post_air"]), " \\\\
& ", fmt_se(se(m_caa)["post_air"]), " & ", fmt_se(se(m_nc)["post_air"]), " \\\\[6pt]
Post $\\times$ Non-Air & ", fmt_coef(coef(m_caa)["post_nonair"], se(m_caa)["post_nonair"], pvalue(m_caa)["post_nonair"]), " & ",
  fmt_coef(coef(m_nc)["post_nonair"], se(m_nc)["post_nonair"], pvalue(m_nc)["post_nonair"]), " \\\\
& ", fmt_se(se(m_caa)["post_nonair"]), " & ", fmt_se(se(m_nc)["post_nonair"]), " \\\\[6pt]
\\midrule
Observations & ", format(nobs(m_caa), big.mark = ","), " & ", format(nobs(m_nc), big.mark = ","), " \\\\
Facilities & ", uniqueN(df[caa_chemical == "YES", frs_id]), " & ", uniqueN(df[caa_chemical == "NO", frs_id]), " \\\\
Facility $\\times$ Chem $\\times$ Medium FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
CWA/RCRA Controls & Yes & Yes \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} The sample is split by whether the chemical is classified as regulated under the Clean Air Act (TRI Column 42). Both specifications include CWA and RCRA inspection controls. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab4, file.path(tables_dir, "tab4_mechanism.tex"))

# ============================================================
# Table 5: Callaway-Sant'Anna vs TWFE
# ============================================================
cat("=== Table 5: CS vs TWFE ===\n")

# TWFE coefficients (medium-specific post)
twfe_air  <- models$medium_results_ctl$Air
twfe_land <- models$medium_results_ctl$Land

tab5_content <- "\\multicolumn{3}{l}{\\textit{Panel A: Air Releases}} \\\\[3pt]\n"
tab5_content <- paste0(tab5_content,
"TWFE & ", fmt_coef(coef(twfe_air)["post"], se(twfe_air)["post"], pvalue(twfe_air)["post"]),
" & ", fmt_se(se(twfe_air)["post"]), " \\\\\n")

if (!is.null(models$att_air_cs)) {
  cs_att <- models$att_air_cs
  tab5_content <- paste0(tab5_content,
"Callaway-Sant'Anna & ", fmt_coef(cs_att$overall.att, cs_att$overall.se,
                                    2 * pnorm(-abs(cs_att$overall.att / cs_att$overall.se))),
" & (", sprintf("%.4f", cs_att$overall.se), ") \\\\\n")
} else {
  tab5_content <- paste0(tab5_content,
"Callaway-Sant'Anna & \\multicolumn{2}{c}{Not estimated} \\\\\n")
}

tab5_content <- paste0(tab5_content,
"\\midrule\n\\multicolumn{3}{l}{\\textit{Panel B: Land Releases}} \\\\[3pt]\n")
tab5_content <- paste0(tab5_content,
"TWFE & ", fmt_coef(coef(twfe_land)["post"], se(twfe_land)["post"], pvalue(twfe_land)["post"]),
" & ", fmt_se(se(twfe_land)["post"]), " \\\\\n")

if (!is.null(models$att_land_cs)) {
  cs_land_att <- models$att_land_cs
  tab5_content <- paste0(tab5_content,
"Callaway-Sant'Anna & ", fmt_coef(cs_land_att$overall.att, cs_land_att$overall.se,
                                     2 * pnorm(-abs(cs_land_att$overall.att / cs_land_att$overall.se))),
" & (", sprintf("%.4f", cs_land_att$overall.se), ") \\\\\n")
} else {
  tab5_content <- paste0(tab5_content,
"Callaway-Sant'Anna & \\multicolumn{2}{c}{Not estimated} \\\\\n")
}

tab5 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Staggered DiD Robustness: TWFE vs.\\ Callaway-Sant'Anna}
\\label{tab:cs}
\\begin{tabular}{lcc}
\\toprule
& Estimate & SE \\\\
\\midrule
", tab5_content, "
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} TWFE estimates are from the medium-specific regressions with CWA/RCRA controls (Table~\\ref{tab:decomp}, Column 2). Callaway-Sant'Anna estimates use not-yet-treated facilities as the control group with no anticipation. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab5, file.path(tables_dir, "tab5_cs.tex"))

# ============================================================
# Table 6: Robustness
# ============================================================
cat("=== Table 6: Robustness ===\n")

rm <- rob_models
tab6 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks}
\\label{tab:robust}
\\begin{tabular}{lccccc}
\\toprule
& (1) & (2) & (3) & (4) & (5) \\\\
& Baseline & State & Two-Way & $\\pm 3$ Yr & Excl.\\ 2020 \\\\
\\midrule
Post $\\times$ Air & ",
fmt_coef(coef(rm$m_fac)["post_air"], se(rm$m_fac)["post_air"], pvalue(rm$m_fac)["post_air"]), " & ",
fmt_coef(coef(rm$m_state)["post_air"], se(rm$m_state)["post_air"], pvalue(rm$m_state)["post_air"]), " & ",
fmt_coef(coef(rm$m_2way)["post_air"], se(rm$m_2way)["post_air"], pvalue(rm$m_2way)["post_air"]), " & ",
fmt_coef(coef(rm$m_w3)["post_air"], se(rm$m_w3)["post_air"], pvalue(rm$m_w3)["post_air"]), " & ",
fmt_coef(coef(rm$m_nocovid)["post_air"], se(rm$m_nocovid)["post_air"], pvalue(rm$m_nocovid)["post_air"]), " \\\\
& ", fmt_se(se(rm$m_fac)["post_air"]), " & ",
fmt_se(se(rm$m_state)["post_air"]), " & ",
fmt_se(se(rm$m_2way)["post_air"]), " & ",
fmt_se(se(rm$m_w3)["post_air"]), " & ",
fmt_se(se(rm$m_nocovid)["post_air"]), " \\\\[6pt]
Post $\\times$ Non-Air & ",
fmt_coef(coef(rm$m_fac)["post_nonair"], se(rm$m_fac)["post_nonair"], pvalue(rm$m_fac)["post_nonair"]), " & ",
fmt_coef(coef(rm$m_state)["post_nonair"], se(rm$m_state)["post_nonair"], pvalue(rm$m_state)["post_nonair"]), " & ",
fmt_coef(coef(rm$m_2way)["post_nonair"], se(rm$m_2way)["post_nonair"], pvalue(rm$m_2way)["post_nonair"]), " & ",
fmt_coef(coef(rm$m_w3)["post_nonair"], se(rm$m_w3)["post_nonair"], pvalue(rm$m_w3)["post_nonair"]), " & ",
fmt_coef(coef(rm$m_nocovid)["post_nonair"], se(rm$m_nocovid)["post_nonair"], pvalue(rm$m_nocovid)["post_nonair"]), " \\\\
& ", fmt_se(se(rm$m_fac)["post_nonair"]), " & ",
fmt_se(se(rm$m_state)["post_nonair"]), " & ",
fmt_se(se(rm$m_2way)["post_nonair"]), " & ",
fmt_se(se(rm$m_w3)["post_nonair"]), " & ",
fmt_se(se(rm$m_nocovid)["post_nonair"]), " \\\\[6pt]
\\midrule
Observations & ", format(nobs(rm$m_fac), big.mark = ","), " & ",
format(nobs(rm$m_state), big.mark = ","), " & ",
format(nobs(rm$m_2way), big.mark = ","), " & ",
format(nobs(rm$m_w3), big.mark = ","), " & ",
format(nobs(rm$m_nocovid), big.mark = ","), " \\\\
Clustering & Facility & State & Fac + Year & Facility & Facility \\\\
\\midrule
RI $p$-value (Air) & \\multicolumn{5}{c}{", sprintf("%.3f", rm$ri_p_air), "} \\\\
RI $p$-value (Non-Air) & \\multicolumn{5}{c}{", sprintf("%.3f", rm$ri_p_nonair), "} \\\\
Pre-trend Wald $p$ & \\multicolumn{5}{c}{", sprintf("%.3f", rm$wald_pre_p), "} \\\\
Balance test $p$ & \\multicolumn{5}{c}{", sprintf("%.3f", rm$balance_results$p_value), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} All specifications include facility $\\times$ chemical $\\times$ medium and year fixed effects. RI $p$-values from 500 permutations of inspection timing. Pre-trend Wald test: joint significance of $t = -5$ through $t = -2$ event-study coefficients. Balance test: $F$-test from regression of first inspection year on pre-treatment facility characteristics. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab6, file.path(tables_dir, "tab6_robust.tex"))

# ============================================================
# Table 7: Heterogeneity
# ============================================================
cat("=== Table 7: Heterogeneity ===\n")

# Build heterogeneity table from models
het_rows <- ""
# Enforcement intensity
het_rows <- paste0(het_rows,
"High enforcement & ",
fmt_coef(coef(rm$m_high)["post_air"], se(rm$m_high)["post_air"], pvalue(rm$m_high)["post_air"]), " & ",
fmt_coef(coef(rm$m_high)["post_nonair"], se(rm$m_high)["post_nonair"], pvalue(rm$m_high)["post_nonair"]), " & ",
format(nobs(rm$m_high), big.mark = ","), " \\\\\n",
"& ", fmt_se(se(rm$m_high)["post_air"]), " & ", fmt_se(se(rm$m_high)["post_nonair"]), " & \\\\\n",
"Low enforcement & ",
fmt_coef(coef(rm$m_low)["post_air"], se(rm$m_low)["post_air"], pvalue(rm$m_low)["post_air"]), " & ",
fmt_coef(coef(rm$m_low)["post_nonair"], se(rm$m_low)["post_nonair"], pvalue(rm$m_low)["post_nonair"]), " & ",
format(nobs(rm$m_low), big.mark = ","), " \\\\\n",
"& ", fmt_se(se(rm$m_low)["post_air"]), " & ", fmt_se(se(rm$m_low)["post_nonair"]), " & \\\\[3pt]\n")

# Switching capacity
if (!is.null(models$m_switch_has)) {
  het_rows <- paste0(het_rows, "\\midrule\n",
"Pre-existing land pathway & ",
fmt_coef(coef(models$m_switch_has)["post_air"], se(models$m_switch_has)["post_air"],
         pvalue(models$m_switch_has)["post_air"]), " & ",
fmt_coef(coef(models$m_switch_has)["post_nonair"], se(models$m_switch_has)["post_nonair"],
         pvalue(models$m_switch_has)["post_nonair"]), " & ",
format(nobs(models$m_switch_has), big.mark = ","), " \\\\\n",
"& ", fmt_se(se(models$m_switch_has)["post_air"]), " & ",
fmt_se(se(models$m_switch_has)["post_nonair"]), " & \\\\\n",
"No pre-existing land & ",
fmt_coef(coef(models$m_switch_no)["post_air"], se(models$m_switch_no)["post_air"],
         pvalue(models$m_switch_no)["post_air"]), " & ",
fmt_coef(coef(models$m_switch_no)["post_nonair"], se(models$m_switch_no)["post_nonair"],
         pvalue(models$m_switch_no)["post_nonair"]), " & ",
format(nobs(models$m_switch_no), big.mark = ","), " \\\\\n",
"& ", fmt_se(se(models$m_switch_no)["post_air"]), " & ",
fmt_se(se(models$m_switch_no)["post_nonair"]), " & \\\\[3pt]\n")
}

tab7 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Heterogeneity Analysis}
\\label{tab:heterogeneity}
\\begin{tabular}{lccc}
\\toprule
& Post $\\times$ Air & Post $\\times$ Non-Air & N \\\\
\\midrule
", het_rows, "
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Each row reports coefficients from a separate triple-difference regression on the indicated subsample. High enforcement: top 15 states by CAA inspection count. Pre-existing land pathway: facility-chemicals with any positive land release in the pre-inspection period. All specifications include facility $\\times$ chemical $\\times$ medium and year fixed effects, clustered at facility level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab7, file.path(tables_dir, "tab7_heterogeneity.tex"))

# ============================================================
# Table 8: Offset/Magnitudes
# ============================================================
cat("=== Table 8: Magnitudes ===\n")

# Use levels specification for physical magnitudes
m_lev <- rob_models$m_levels

# Get pre-inspection means for each medium
pre_means <- df[post == 0, .(pre_mean = mean(releases, na.rm = TRUE)),
                by = medium_cat]

tab8 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Magnitudes and Environmental Relevance}
\\label{tab:magnitudes}
\\begin{tabular}{lcccc}
\\toprule
& Air & Water & Land & POTW \\\\
\\midrule
Pre-inspection mean (lbs) & ",
sprintf("%.0f", pre_means[medium_cat == "Air", pre_mean]), " & ",
sprintf("%.0f", pre_means[medium_cat == "Water", pre_mean]), " & ",
sprintf("%.0f", pre_means[medium_cat == "Land", pre_mean]), " & ",
sprintf("%.0f", pre_means[medium_cat == "POTW", pre_mean]), " \\\\[3pt]
Log-point change & ",
sprintf("%.4f", coef(models$medium_results_ctl$Air)["post"]), " & ",
sprintf("%.4f", coef(models$medium_results_ctl$Water)["post"]), " & ",
sprintf("%.4f", coef(models$medium_results_ctl$Land)["post"]), " & ",
sprintf("%.4f", coef(models$medium_results_ctl$POTW)["post"]), " \\\\
\\% change & ",
sprintf("%.1f\\%%", (exp(coef(models$medium_results_ctl$Air)["post"]) - 1) * 100), " & ",
sprintf("%.1f\\%%", (exp(coef(models$medium_results_ctl$Water)["post"]) - 1) * 100), " & ",
sprintf("%.1f\\%%", (exp(coef(models$medium_results_ctl$Land)["post"]) - 1) * 100), " & ",
sprintf("%.1f\\%%", (exp(coef(models$medium_results_ctl$POTW)["post"]) - 1) * 100), " \\\\[3pt]
Levels change (lbs) & ", sprintf("%.0f", coef(m_lev)["post_air"]), " & \\multicolumn{3}{c}{",
sprintf("%.0f", coef(m_lev)["post_nonair"]), " (pooled non-air)} \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Offset calculation}} \\\\[3pt]
Non-air increase / Air decrease & \\multicolumn{4}{c}{",
sprintf("%.1f\\%%", abs(coef(m_lev)["post_nonair"]) / abs(coef(m_lev)["post_air"]) * 100), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Pre-inspection means computed from the analysis sample prior to first CAA inspection. Log-point changes from the medium-specific regressions with CWA/RCRA controls (Table~\\ref{tab:decomp}, Column 2). Levels changes from the pooled triple-difference in pounds. The offset ratio measures what fraction of the air release reduction is offset by increased non-air releases.
\\end{minipage}
\\end{table}")

writeLines(tab8, file.path(tables_dir, "tab8_magnitudes.tex"))

# ============================================================
# Appendix Table: SDE
# ============================================================
cat("=== Appendix: SDE Table ===\n")

# Compute SDE for main results
compute_sde <- function(model, coef_name, data_subset) {
  est <- coef(model)[coef_name]
  se_val <- se(model)[coef_name]
  sd_y <- sd(data_subset$log_releases_w, na.rm = TRUE)
  sde <- est / sd_y
  se_sde <- se_val / sd_y
  class_label <- if (is.na(sde)) "N/A"
                 else if (abs(sde) > 0.15) "Large"
                 else if (abs(sde) > 0.05) "Moderate"
                 else if (abs(sde) > 0.005) "Small"
                 else "Null"
  list(est = est, se = se_val, sd_y = sd_y, sde = sde, se_sde = se_sde, class = class_label)
}

sde_air    <- compute_sde(models$medium_results_ctl$Air, "post", df[medium_cat == "Air"])
sde_water  <- compute_sde(models$medium_results_ctl$Water, "post", df[medium_cat == "Water"])
sde_land   <- compute_sde(models$medium_results_ctl$Land, "post", df[medium_cat == "Land"])
sde_potw   <- compute_sde(models$medium_results_ctl$POTW, "post", df[medium_cat == "POTW"])
sde_pxair  <- compute_sde(models$m3_cwa_rcra, "post_air", df)
sde_pxna   <- compute_sde(models$m3_cwa_rcra, "post_nonair", df)

sde_row <- function(label, s) {
  paste0(label, " & ", sprintf("%.4f", s$est), " & ", sprintf("%.4f", s$se),
         " & ", sprintf("%.3f", s$sd_y), " & ", sprintf("%.4f", s$sde),
         " & ", sprintf("%.4f", s$se_sde), " & ", s$class, " \\\\")
}

tabF1 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
& Coef. & SE & SD($Y$) & SDE & SE(SDE) & Class \\\\
\\midrule
", sde_row("Air", sde_air), "\n",
sde_row("Water", sde_water), "\n",
sde_row("Land", sde_land), "\n",
sde_row("POTW", sde_potw), "\n",
"\\midrule\n",
sde_row("Post $\\times$ Air", sde_pxair), "\n",
sde_row("Post $\\times$ Non-Air", sde_pxna), "\n",
"\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} SDE = Coefficient / SD($Y$). Classification: Large ($>0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($<0.005$). All estimates use CWA/RCRA controls.
\\end{minipage}
\\end{table}")

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables complete ===\n")
cat("Tables written to:", tables_dir, "\n")
list.files(tables_dir)
