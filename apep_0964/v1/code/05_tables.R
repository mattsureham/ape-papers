# 05_tables.R — Generate all tables for the paper
source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
models <- readRDS("../data/models.rds")
rob <- readRDS("../data/robustness.rds")

dir.create("../tables", showWarnings = FALSE)

# ================================================================
# TABLE 1: Summary Statistics
# ================================================================
cat("--- Table 1: Summary Statistics ---\n")

pre <- panel[year < 2019]
post <- panel[year >= 2019]

make_row <- function(varname, label, multiplier = 1) {
  pre_v <- pre[[varname]] * multiplier
  post_v <- post[[varname]] * multiplier
  sprintf("%s & %.2f & %.2f & %d & %.2f & %.2f & %d \\\\",
          label,
          mean(pre_v, na.rm = TRUE), sd(pre_v, na.rm = TRUE), sum(!is.na(pre_v)),
          mean(post_v, na.rm = TRUE), sd(post_v, na.rm = TRUE), sum(!is.na(post_v)))
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Non-Financial Corporations (S11), 2012--2023}",
  "\\label{tab:sumstats}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "& \\multicolumn{3}{c}{Pre-ATAD (2012--2018)} & \\multicolumn{3}{c}{Post-ATAD (2019--2023)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  "& Mean & SD & N & Mean & SD & N \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Key Ratios}} \\\\[3pt]",
  make_row("interest_gos_ratio", "Interest/GOS ratio", 100),
  make_row("debt_ratio", "Debt securities share (\\%)", 100),
  make_row("leverage", "Leverage ratio", 1),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Levels (\\euro{} millions, national currency)}} \\\\[3pt]",
  sprintf("Interest paid & %s & %s & %d & %s & %s & %d \\\\",
          format(round(mean(pre$interest_paid, na.rm=T)), big.mark=","),
          format(round(sd(pre$interest_paid, na.rm=T)), big.mark=","),
          sum(!is.na(pre$interest_paid)),
          format(round(mean(post$interest_paid, na.rm=T)), big.mark=","),
          format(round(sd(post$interest_paid, na.rm=T)), big.mark=","),
          sum(!is.na(post$interest_paid))),
  sprintf("Gross operating surplus & %s & %s & %d & %s & %s & %d \\\\",
          format(round(mean(pre$gos_ebitda, na.rm=T)), big.mark=","),
          format(round(sd(pre$gos_ebitda, na.rm=T)), big.mark=","),
          sum(!is.na(pre$gos_ebitda)),
          format(round(mean(post$gos_ebitda, na.rm=T)), big.mark=","),
          format(round(sd(post$gos_ebitda, na.rm=T)), big.mark=","),
          sum(!is.na(post$gos_ebitda))),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel C: Macroeconomic Controls}} \\\\[3pt]",
  make_row("gdp_growth", "Real GDP growth (\\%)", 1),
  make_row("inflation", "HICP inflation (\\%)", 1),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from Eurostat Annual Sector Accounts for non-financial corporations (S11). Interest/GOS ratio is interest paid (D41) divided by gross operating surplus and mixed income (B2A3G). Debt securities share is F3 liabilities as a fraction of total debt (F3+F4). Leverage is total debt (F3+F4) over equity (F5). All financial data in millions of national currency. 27 EU member states, balanced panel. Pre-ATAD period: 2012--2018. Post-ATAD period: 2019--2023.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# ================================================================
# TABLE 2: Main DiD Results
# ================================================================
cat("--- Table 2: Main DiD ---\n")

# Extract key statistics
extract_row <- function(model, varname) {
  ct <- coeftable(model)
  row <- ct[varname, ]
  list(coef = row["Estimate"], se = row["Std. Error"],
       pval = row["Pr(>|t|)"], n = model$nobs, r2w = fitstat(model, "wr2")[[1]])
}

# Models: m1 (adopted), m2 (dose), m3 (dose+controls), m4 (debt ratio), m5 (leverage)
r1 <- extract_row(models$m1, "adopted")
r2 <- extract_row(models$m2, "treat_dose")
r3 <- extract_row(models$m3, "treat_dose")
r4 <- extract_row(models$m4, "treat_dose")
r5 <- extract_row(models$m5, "treat_dose")

stars <- function(p) {
  if (p < 0.01) "***"
  else if (p < 0.05) "**"
  else if (p < 0.1) "*"
  else ""
}

fmt_coef <- function(r, varname = NULL) {
  sprintf("%.4f%s", r$coef, stars(r$pval))
}

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of ATAD Interest Limitation on Corporate Financing}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& Interest/ & Interest/ & Interest/ & Debt Sec. & Leverage \\\\",
  "& GOS & GOS & GOS & Share & Ratio \\\\",
  "\\midrule",
  sprintf("Adopted & %s & & & & \\\\", fmt_coef(r1)),
  sprintf("& (%.4f) & & & & \\\\", r1$se),
  sprintf("Adopted $\\times$ Dose & & %s & %s & %s & %s \\\\",
          fmt_coef(r2), fmt_coef(r3), fmt_coef(r4), fmt_coef(r5)),
  sprintf("& & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          r2$se, r3$se, r4$se, r5$se),
  "\\midrule",
  sprintf("Macro controls & No & No & Yes & No & No \\\\"),
  "Country FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          r1$n, r2$n, r3$n, r4$n, r5$n),
  sprintf("Within $R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          r1$r2w, r2$r2w, r3$r2w, r4$r2w, r5$r2w),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports a separate regression of the outcome on ATAD adoption, with country and year fixed effects. Column 1 uses a binary indicator for post-adoption. Columns 2--5 interact adoption with dose intensity, defined as $(5 - \\text{de minimis threshold})/5$, where higher values indicate more firms are constrained. Column 3 adds GDP growth and HICP inflation as controls. Standard errors clustered by country in parentheses. * $p<0.1$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ================================================================
# TABLE 3: Event Study Coefficients
# ================================================================
cat("--- Table 3: Event Study ---\n")

es_ct <- coeftable(models$es1)
es_ct2 <- coeftable(models$es2)

# Format event study table
es_rows <- character()
for (i in seq_len(nrow(es_ct))) {
  rn <- rownames(es_ct)[i]
  # Extract event time from rowname like "et::-5:dose"
  et <- gsub("et::|:dose", "", rn)
  es_rows <- c(es_rows,
    sprintf("$t %s$ & %.4f%s & (%.4f) & %.4f%s & (%.4f) \\\\",
            ifelse(as.numeric(et) >= 0, paste0("+ ", et), paste0("- ", abs(as.numeric(et)))),
            es_ct[i, "Estimate"], stars(es_ct[i, "Pr(>|t|)"]),
            es_ct[i, "Std. Error"],
            es_ct2[i, "Estimate"], stars(es_ct2[i, "Pr(>|t|)"]),
            es_ct2[i, "Std. Error"]))
}

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Dynamic Effects of ATAD Adoption}",
  "\\label{tab:eventstudy}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& \\multicolumn{2}{c}{Interest/GOS} & \\multicolumn{2}{c}{Debt Securities Share} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Event time & Coeff. & (SE) & Coeff. & (SE) \\\\",
  "\\midrule",
  es_rows,
  "\\midrule",
  "Reference: $t - 1$ & \\multicolumn{4}{c}{---} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          models$es1$nobs, models$es2$nobs),
  "Country FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{4}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Event-study regressions using the full panel of 27 EU countries with staggered ATAD adoption. Event time is relative to each country's adoption year (2019 for 21 early adopters; 2022 for Ireland; 2024 for France, Greece, Slovakia, Slovenia, Spain). Coefficients are interactions of event-time dummies with dose intensity. Reference period is $t-1$ (one year before adoption). Standard errors clustered by country. * $p<0.1$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_eventstudy.tex")

# ================================================================
# TABLE 4: Robustness
# ================================================================
cat("--- Table 4: Robustness ---\n")

# Collect robustness results
rob_nocovid <- coeftable(rob$m_nocovid)["treat_dose", ]

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & $p$-value \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Interest/GOS Ratio}} \\\\[3pt]",
  sprintf("Baseline (Adopted $\\times$ Dose) & %.4f & %.4f & %.3f \\\\",
          coef(models$m2)["treat_dose"],
          coeftable(models$m2)["treat_dose", "Std. Error"],
          coeftable(models$m2)["treat_dose", "Pr(>|t|)"]),
  sprintf("Wild cluster bootstrap & %.4f & --- & %.3f \\\\",
          coef(models$m2)["treat_dose"], rob$boot_pval_intgos),
  sprintf("Excluding 2020 & %.4f & %.4f & %.3f \\\\",
          rob_nocovid["Estimate"], rob_nocovid["Std. Error"], rob_nocovid["Pr(>|t|)"]),
  sprintf("Leave-one-out range & [%.4f, %.4f] & --- & --- \\\\",
          rob$loo_range[1], rob$loo_range[2]),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Derogation Country Placebo (2019--2021)}} \\\\[3pt]",
  sprintf("Interest/GOS ratio & %.4f & %.4f & %.3f \\\\",
          coef(models$plac1)["placebo_treat"],
          coeftable(models$plac1)["placebo_treat", "Std. Error"],
          coeftable(models$plac1)["placebo_treat", "Pr(>|t|)"]),
  sprintf("Debt securities share & %.4f & %.4f & %.3f \\\\",
          coef(models$plac2)["placebo_treat"],
          coeftable(models$plac2)["placebo_treat", "Std. Error"],
          coeftable(models$plac2)["placebo_treat", "Pr(>|t|)"]),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel C: Minimum Detectable Effect (80\\% power)}} \\\\[3pt]",
  sprintf("MDE (Int/GOS) & %.4f & --- & --- \\\\", rob$mde),
  sprintf("MDE as \\%% of pre-treatment SD & %.1f\\%% & --- & --- \\\\",
          100 * rob$mde / rob$pre_sd),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports the main dose-response coefficient under alternative specifications. Wild cluster bootstrap uses 9,999 Webb weight iterations. Leave-one-out reports the range of coefficients when each country is sequentially dropped. Panel B tests whether derogation countries (France, Greece, Slovakia, Slovenia, Spain, Ireland) experienced spurious effects in 2019--2021, before their ATAD adoption. Panel C reports the minimum detectable effect at 80\\% power and 5\\% significance.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, "../tables/tab4_robustness.tex")

# ================================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ================================================================
cat("--- Table F1: SDE ---\n")

# Compute SDEs for main outcomes
pre_sd_intgos <- sd(panel[year < 2019, interest_gos_ratio], na.rm = TRUE)
pre_sd_debtratio <- sd(panel[year < 2019, debt_ratio], na.rm = TRUE)
pre_sd_leverage <- sd(panel[year < 2019, leverage], na.rm = TRUE)

# Main results: dose-response (m2 for interest/GOS, m4 for debt ratio, m5 for leverage)
# Treatment is continuous dose (0 to 1), so SDE = beta * SD(dose) / SD(Y)
dose_sd <- sd(panel$dose, na.rm = TRUE)

# Interest/GOS
beta_ig <- coef(models$m2)["treat_dose"]
se_ig <- coeftable(models$m2)["treat_dose", "Std. Error"]
sde_ig <- beta_ig * dose_sd / pre_sd_intgos
se_sde_ig <- se_ig * dose_sd / pre_sd_intgos

# Debt ratio
beta_dr <- coef(models$m4)["treat_dose"]
se_dr <- coeftable(models$m4)["treat_dose", "Std. Error"]
sde_dr <- beta_dr * dose_sd / pre_sd_debtratio
se_sde_dr <- se_dr * dose_sd / pre_sd_debtratio

# Leverage
beta_lv <- coef(models$m5)["treat_dose"]
se_lv <- coeftable(models$m5)["treat_dose", "Std. Error"]
sde_lv <- beta_lv * dose_sd / pre_sd_leverage
se_sde_lv <- se_lv * dose_sd / pre_sd_leverage

classify_sde <- function(sde) {
  if (sde < -0.15) "Large negative"
  else if (sde < -0.05) "Moderate negative"
  else if (sde < -0.005) "Small negative"
  else if (sde <= 0.005) "Null"
  else if (sde <= 0.05) "Small positive"
  else if (sde <= 0.15) "Moderate positive"
  else "Large positive"
}

# Binary adopted on interest/GOS (m1)
beta_bin <- coef(models$m1)["adopted"]
se_bin <- coeftable(models$m1)["adopted", "Std. Error"]
sde_bin <- beta_bin / pre_sd_intgos
se_sde_bin <- se_bin / pre_sd_intgos

# Heterogeneity: early adopters with standard (3M) threshold
het_ct <- coeftable(rob$m_het)
beta_3m <- het_ct["dose_group::3M:post2019", "Estimate"]
se_3m <- het_ct["dose_group::3M:post2019", "Std. Error"]
pre_sd_early <- sd(panel[year < 2019 & derogation == 0, interest_gos_ratio], na.rm = TRUE)
sde_3m <- beta_3m / pre_sd_early
se_sde_3m <- se_3m / pre_sd_early

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states). ",
  "\\textbf{Research question:} Does coordinated limitation of interest deductibility under the EU Anti-Tax Avoidance Directive shift aggregate corporate financing from debt toward equity? ",
  "\\textbf{Policy mechanism:} ATAD I caps tax-deductible net borrowing costs at 30\\% of EBITDA for non-financial corporations, with member states setting de minimis thresholds below which the rule does not apply, aiming to reduce the tax-induced incentive to finance with debt over equity. ",
  "\\textbf{Outcome definition:} Panel A: Interest-to-GOS ratio (D41 PAID / B2A3G), debt securities share (F3 / [F3 + F4]), leverage ratio ([F3 + F4] / F5) from Eurostat Annual Sector Accounts. Panel B: Interest-to-GOS ratio for subsamples by de minimis threshold group. ",
  "\\textbf{Treatment:} Continuous dose intensity for Panel A, defined as $(5 - \\text{de minimis in EUR million})/5$; binary post-adoption indicator for Panel B subsamples. ",
  "\\textbf{Data:} Eurostat Annual Sector Accounts (nasa\\_10\\_f\\_bs, nasa\\_10\\_nf\\_tr) for non-financial corporations (S11), 2012--2023, country-year observations ($N = 647$). ",
  "\\textbf{Method:} Two-way fixed effects (country + year) difference-in-differences exploiting cross-country variation in de minimis thresholds and staggered adoption timing; standard errors clustered by country. ",
  "\\textbf{Sample:} All 27 EU member states; 21 early adopters (January 2019) and 6 derogation countries (2022--2024). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment (Panel A) and ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment (Panel B), where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (Dose-Response)}} \\\\[3pt]",
  sprintf("Interest/GOS ratio & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_ig, se_ig, pre_sd_intgos, sde_ig, se_sde_ig, classify_sde(sde_ig)),
  sprintf("Debt securities share & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_dr, se_dr, pre_sd_debtratio, sde_dr, se_sde_dr, classify_sde(sde_dr)),
  sprintf("Leverage ratio & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_lv, se_lv, pre_sd_leverage, sde_lv, se_sde_lv, classify_sde(sde_lv)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by de minimis threshold)}} \\\\[3pt]",
  sprintf("Int/GOS: Standard (\\euro{}3M) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_3m, se_3m, pre_sd_early, sde_3m, se_sde_3m, classify_sde(sde_3m)),
  sprintf("Int/GOS: Binary adopted & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_bin, se_bin, pre_sd_intgos, sde_bin, se_sde_bin, classify_sde(sde_bin)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables written to tables/\n")
