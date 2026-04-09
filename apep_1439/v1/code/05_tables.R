## 05_tables.R — Generate all LaTeX tables
## apep_1439: The Switching Paradox

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
panel_weekly <- readRDS("../data/panel_weekly.rds")

cat("=== Generating LaTeX Tables ===\n")

# =====================================================================
# Table 1: Summary Statistics
# =====================================================================
cat("--- Table 1: Summary Statistics ---\n")

sum_by_group <- panel_weekly %>%
  group_by(Group = ifelse(treated == 1, "Insurance (Treated)", "Non-Insurance (Control)"),
           Period = ifelse(post == 0, "Pre-Ban", "Post-Ban")) %>%
  summarise(
    Mean = sprintf("%.1f", mean(hits, na.rm = TRUE)),
    SD = sprintf("%.1f", sd(hits, na.rm = TRUE)),
    Min = sprintf("%.0f", min(hits, na.rm = TRUE)),
    Max = sprintf("%.0f", max(hits, na.rm = TRUE)),
    `N (keyword-weeks)` = format(n(), big.mark = ","),
    .groups = "drop"
  )

# Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Weekly Google Trends Search Intensity}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{llccccc}\n")
cat("\\toprule\n")
cat("Group & Period & Mean & SD & Min & Max & N \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(sum_by_group))) {
  r <- sum_by_group[i, ]
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
              r$Group, r$Period, r$Mean, r$SD, r$Min, r$Max, r$`N (keyword-weeks)`))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Google Trends search intensity index (0--100) for UK queries. ")
cat("Insurance (treated) keywords: confused.com, comparethemarket.com, gocompare.com. ")
cat("Non-insurance (control) keywords: uswitch.com, moneysavingexpert.com. ")
cat("Pre-ban: January 2018 -- December 2021. Post-ban: January 2022 onwards. ")
cat("The GIPP pricing remedy took effect 1 January 2022.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tab1_summary.tex\n")

# =====================================================================
# Table 2: Main DiD Results
# =====================================================================
cat("--- Table 2: Main DiD Results ---\n")

m1 <- results$m1; m2 <- results$m2; m3 <- results$m3; m4 <- results$m4

# Extract coefficients
get_row <- function(m, var = "treat_post") {
  ct <- coeftable(m)
  idx <- which(rownames(ct) == var)
  if (length(idx) == 0) return(c(NA, NA, NA))
  c(ct[idx, "Estimate"], ct[idx, "Std. Error"], ct[idx, "Pr(>|t|)"])
}

r1 <- get_row(m1); r2 <- get_row(m2); r3 <- get_row(m3); r4 <- get_row(m4)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  ""
}

sink("../tables/tab2_main_did.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of the Loyalty Penalty Ban on Consumer Search Intensity}\n")
cat("\\label{tab:main_did}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Group-Week & Keyword-Week & Log(Hits+1) & Excl.\\ COVID \\\\\n")
cat("\\midrule\n")
cat(sprintf("Treated $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
            r1[1], stars(r1[3]), r2[1], stars(r2[3]), r3[1], stars(r3[3]), r4[1], stars(r4[3])))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n", r1[2], r2[2], r3[2], r4[2]))
cat("\\midrule\n")
cat(sprintf("Keyword FE & No & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Week FE & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Group FE & Yes & --- & --- & --- \\\\\n"))
cat(sprintf("Excl.\\ COVID & No & No & No & Yes \\\\\n"))
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nobs(m1), big.mark = ","),
            format(nobs(m2), big.mark = ","),
            format(nobs(m3), big.mark = ","),
            format(nobs(m4), big.mark = ",")))
cat(sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
            fitstat(m1, "r2")[[1]], fitstat(m2, "r2")[[1]],
            fitstat(m3, "r2")[[1]], fitstat(m4, "r2")[[1]]))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Difference-in-differences estimates. Dependent variable: Google Trends ")
cat("search intensity (0--100) in columns (1)--(2) and (4); log(hits+1) in column (3). ")
cat("Treatment group: insurance comparison sites (confused.com, comparethemarket.com, gocompare.com). ")
cat("Control group: non-insurance comparison sites (uswitch.com, moneysavingexpert.com). ")
cat("Post = January 2022 onwards. Column (1) uses group-week aggregation with heteroskedasticity-robust SEs. ")
cat("Columns (2)--(4) use keyword-week observations with SEs clustered by keyword. ")
cat("Column (4) drops March 2020 -- June 2021 (COVID lockdown period). ")
cat("$^{***}$, $^{**}$, $^{*}$ denote significance at the 1\\%, 5\\%, and 10\\% levels.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tab2_main_did.tex\n")

# =====================================================================
# Table 3: Event Study Coefficients
# =====================================================================
cat("--- Table 3: Event Study ---\n")

m_es <- results$m_es
es_ct <- coeftable(m_es)

sink("../tables/tab3_event_study.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Event Study: Quarterly Treatment Effects on Search Intensity}\n")
cat("\\label{tab:event_study}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("Quarter Relative to Ban & Coefficient & SE \\\\\n")
cat("\\midrule\n")

# Parse event study coefficients
es_names <- rownames(es_ct)
for (i in seq_along(es_names)) {
  nm <- es_names[i]
  # Extract quarter number from name
  q_num <- gsub(".*::", "", nm)
  q_num <- gsub("rel_q_factor", "", q_num)
  est <- es_ct[i, "Estimate"]
  se <- es_ct[i, "Std. Error"]
  pv <- es_ct[i, "Pr(>|t|)"]
  cat(sprintf("$q = %s$ & %.3f%s & (%.3f) \\\\\n", q_num, est, stars(pv), se))
}

cat("\\midrule\n")
cat(sprintf("Reference period & \\multicolumn{2}{c}{$q = -1$ (Q4 2021)} \\\\\n"))
cat(sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\\n", format(nobs(m_es), big.mark = ",")))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Event study coefficients from a keyword-week regression with keyword and week ")
cat("fixed effects. Each coefficient represents the interaction of the treated indicator with a quarterly ")
cat("relative time dummy (13-week bins). Reference period is $q = -1$ (October--December 2021). ")
cat("SEs clustered by keyword. $^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, 10\\%.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tab3_event_study.tex\n")

# =====================================================================
# Table 4: Robustness
# =====================================================================
cat("--- Table 4: Robustness ---\n")

m_placebo <- rob_results$m_placebo
m_narrow <- rob_results$m_narrow
m_monthly <- rob_results$m_monthly

rp <- get_row(m_placebo, "treat_post_placebo")
rn <- get_row(m_narrow)
rm <- get_row(m_monthly)

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat(" & Placebo (Jan 2020) & Narrow ($\\pm$1 yr) & Monthly Agg. \\\\\n")
cat("\\midrule\n")
cat(sprintf("Treated $\\times$ Post & %.3f%s & %.3f%s & %.3f%s \\\\\n",
            rp[1], stars(rp[3]), rn[1], stars(rn[3]), rm[1], stars(rm[3])))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n", rp[2], rn[2], rm[2]))
cat("\\midrule\n")
cat(sprintf("Observations & %s & %s & %s \\\\\n",
            format(nobs(m_placebo), big.mark = ","),
            format(nobs(m_narrow), big.mark = ","),
            format(nobs(m_monthly), big.mark = ",")))
cat(sprintf("Permutation $p$-value & \\multicolumn{3}{c}{%.3f (500 iterations)} \\\\\n",
            rob_results$perm_pval))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Column (1): placebo test using January 2020 as a fake treatment date, ")
cat("restricted to the pre-ban period. Column (2): narrow window of $\\pm$1 year around January 2022. ")
cat("Column (3): monthly aggregation to reduce weekly noise. All regressions include keyword and ")
cat("time-period fixed effects with SEs clustered by keyword. Permutation $p$-value from 500 random ")
cat("reassignments of treatment status across keywords. ")
cat("$^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, 10\\%.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tab4_robustness.tex\n")

# =====================================================================
# Table F1: SDE Appendix (MANDATORY)
# =====================================================================
cat("--- Table F1: Standardized Effect Sizes ---\n")

# Compute SDE for main outcomes
# Main spec: m2 (keyword-week, levels)
beta_main <- coef(results$m2)["treat_post"]
se_main <- se(results$m2)["treat_post"]

# SD(Y) from pre-treatment treated group
sd_y_pre <- sd(panel_weekly$hits[panel_weekly$treated == 1 & panel_weekly$post == 0], na.rm = TRUE)

sde_main <- beta_main / sd_y_pre
se_sde_main <- se_main / sd_y_pre

# Log spec: m3
beta_log <- coef(results$m3)["treat_post"]
se_log <- se(results$m3)["treat_post"]
sd_y_log_pre <- sd(panel_weekly$log_hits[panel_weekly$treated == 1 & panel_weekly$post == 0], na.rm = TRUE)
sde_log <- beta_log / sd_y_log_pre
se_sde_log <- se_log / sd_y_log_pre

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Heterogeneity: split by keyword type
# Panel B: Split into price-comparison-only (confused, gocompare, comparethemarket)
# vs broad financial (control split not meaningful — do treated keyword-level)
het_results <- list()
for (kw in unique(panel_weekly$keyword[panel_weekly$treated == 1])) {
  df_kw <- panel_weekly %>% filter(keyword == kw | treated == 0)
  m_kw <- feols(hits ~ treat_post | keyword + week, data = df_kw, warn = FALSE)
  b <- coef(m_kw)["treat_post"]
  s <- se(m_kw)["treat_post"]
  sd_pre <- sd(panel_weekly$hits[panel_weekly$keyword == kw & panel_weekly$post == 0], na.rm = TRUE)
  het_results[[kw]] <- c(beta = b, se = s, sd_y = sd_pre, sde = b/sd_pre, se_sde = s/sd_pre)
}

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Search intensity (levels) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)))
cat(sprintf("Search intensity (log) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_log, se_log, sd_y_log_pre, sde_log, se_sde_log, classify_sde(sde_log)))
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by keyword)}} \\\\\n")
for (kw in names(het_results)) {
  r <- het_results[[kw]]
  if (any(is.na(r))) next
  cat(sprintf("%s & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
              gsub("\\.com", "", kw), r["beta"], r["se"], r["sd_y"],
              r["sde"], r["se_sde"], classify_sde(r["sde"])))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does banning loyalty penalties in insurance reduce or increase consumer search behavior, as measured by online comparison-site traffic? ",
  "\\textbf{Policy mechanism:} The FCA's General Insurance Pricing Practices (GIPP) reform, effective 1 January 2022, prohibited insurers from charging renewal customers more than equivalent new-business prices for home and motor insurance, eliminating the loyalty penalty that had previously incentivized active shopping. ",
  "\\textbf{Outcome definition:} Google Trends weekly search intensity index (0--100) for insurance price-comparison websites in the UK, capturing relative consumer search effort. ",
  "\\textbf{Treatment:} Binary; insurance comparison sites (treated by GIPP) versus non-insurance comparison sites (untreated). ",
  "\\textbf{Data:} Google Trends, January 2018 -- December 2025, keyword-week panel, five keywords. ",
  "\\textbf{Method:} Cross-product difference-in-differences with keyword and week fixed effects; standard errors clustered by keyword. ",
  "\\textbf{Sample:} Three insurance comparison keywords (confused.com, comparethemarket.com, gocompare.com) and two non-insurance comparison keywords (uswitch.com, moneysavingexpert.com); all UK queries. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the treated group. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
