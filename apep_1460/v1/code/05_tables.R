source("code/00_packages.R")

pl <- readRDS("data/poland_panel.rds")
full <- readRDS("data/full_panel.rds")
main <- readRDS("data/main_results.rds")
rob <- readRDS("data/robustness_results.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================

f60_pre <- pl |> filter(sex == "F", age_group == "60-64", post == 0)
f60_post <- pl |> filter(sex == "F", age_group == "60-64", post == 1)
f55_pre <- pl |> filter(sex == "F", age_group == "55-59", post == 0)
f55_post <- pl |> filter(sex == "F", age_group == "55-59", post == 1)
m60_pre <- pl |> filter(sex == "M", age_group == "60-64", post == 0)
m60_post <- pl |> filter(sex == "M", age_group == "60-64", post == 1)
m55_pre <- pl |> filter(sex == "M", age_group == "55-59", post == 0)
m55_post <- pl |> filter(sex == "M", age_group == "55-59", post == 1)

make_row <- function(df, label) {
  sprintf("%s & %d & %.1f & %.1f & %.1f & %.1f \\\\",
    label, nrow(df), mean(df$emp_rate, na.rm = TRUE), sd(df$emp_rate, na.rm = TRUE),
    min(df$emp_rate, na.rm = TRUE), max(df$emp_rate, na.rm = TRUE))
}

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Quarterly Employment Rates (\\%), Poland 2010--2024}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Quarters & Mean & SD & Min & Max \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Pre-reform (2010-Q1 to 2017-Q3)}} \\\\",
  make_row(f60_pre, "Women 60--64 (treated)"),
  make_row(f55_pre, "Women 55--59 (control)"),
  make_row(m60_pre, "Men 60--64 (control)"),
  make_row(m55_pre, "Men 55--59 (control)"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Post-reform (2017-Q4 to 2024-Q4)}} \\\\",
  make_row(f60_post, "Women 60--64 (treated)"),
  make_row(f55_post, "Women 55--59 (control)"),
  make_row(m60_post, "Men 60--64 (control)"),
  make_row(m55_post, "Men 55--59 (control)"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Quarterly employment rates from Eurostat Labour Force Survey (\\texttt{lfsq\\_ergan}), Poland, all citizens. Pre-reform: 2010-Q1 to 2017-Q3 (%d quarters). Post-reform: 2017-Q4 to 2024-Q4 (%d quarters). The treated group (women 60--64) became newly eligible for statutory pension at age 60 after October 1, 2017. Men 60--64 remained below the retirement threshold (65) under both regimes.", nrow(f60_pre), nrow(f60_post)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, "tables/tab1_summary.tex")

# ============================================================
# Table 2: Main Results
# ============================================================

b1 <- coef(main$cross_dd)["poland:post"]; se1 <- se(main$cross_dd)["poland:post"]; p1 <- pvalue(main$cross_dd)["poland:post"]
b1c <- coef(main$cross_dd_cluster)["poland:post"]; se1c <- se(main$cross_dd_cluster)["poland:post"]; p1c <- pvalue(main$cross_dd_cluster)["poland:post"]
b2 <- coef(main$cross_ddd)["poland:female:age_60_64:post"]; se2 <- se(main$cross_ddd)["poland:female:age_60_64:post"]; p2 <- pvalue(main$cross_ddd)["poland:female:age_60_64:post"]
b3 <- coef(main$dd_women)["age_60_64:post"]; se3 <- se(main$dd_women)["age_60_64:post"]; p3 <- pvalue(main$dd_women)["age_60_64:post"]
b4 <- coef(main$dd_sex)["female:post"]; se4 <- se(main$dd_sex)["female:post"]; p4 <- pvalue(main$dd_sex)["female:post"]
b5 <- coef(main$short_window)["poland:post"]; se5 <- se(main$short_window)["poland:post"]; p5 <- pvalue(main$short_window)["poland:post"]

stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{The Retirement Ratchet: Effect of Poland's 2017 Reversal on Women's Employment}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & Cross-DD & Cross-DD & Cross-DDD & DD: Age & DD: Sex & Short \\\\",
  " & (NW) & (Cluster) & & (within PL) & (within PL) & window \\\\",
  "\\midrule",
  sprintf("Treatment $\\times$ Post & %.2f%s & %.2f%s & %.2f%s & %.2f%s & %.2f%s & %.2f%s \\\\",
    b1, stars(p1), b1c, stars(p1c), b2, stars(p2), b3, stars(p3), b4, stars(p4), b5, stars(p5)),
  sprintf(" & (%.2f) & (%.2f) & (%.2f) & (%.2f) & (%.2f) & (%.2f) \\\\",
    se1, se1c, se2, se3, se4, se5),
  "[0.3em]",
  sprintf("Country FE & Yes & Yes & Yes & --- & --- & Yes \\\\"),
  sprintf("Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Countries & 9 & 9 & 9 & PL & PL & 9 \\\\"),
  sprintf("Age groups & 60--64 & 60--64 & 55--64 & 55--64 & 60--64 & 60--64 \\\\"),
  sprintf("Window & 2010--24 & 2010--24 & 2010--24 & 2010--24 & 2010--24 & 2015--20 \\\\"),
  sprintf("N & %d & %d & %d & %d & %d & %d \\\\",
    nobs(main$cross_dd), nobs(main$cross_dd_cluster), nobs(main$cross_ddd),
    nobs(main$dd_women), nobs(main$dd_sex), nobs(main$short_window)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable: quarterly employment rate (\\%). Columns (1)--(2): DD comparing Poland women 60--64 to 8 CEE/EU donor countries (CZ, SK, HU, DE, AT, LT, LV, EE), with country and quarter FE. Column (3): cross-country DDD (Poland $\\times$ Female $\\times$ Age 60--64 $\\times$ Post), with country-clustered SEs. Column (4): within-Poland DD (women 60--64 vs women 55--59). Column (5): within-Poland DD (women vs men, age 60--64). Column (6): restricted window (2015--2020), avoiding 2013 reform confound and COVID. NW = Newey-West HAC; Cluster = country-clustered. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2, "tables/tab2_main.tex")

# ============================================================
# Table 3: Robustness — placebos and partial treatment
# ============================================================

rb1 <- coef(rob$placebo_55_59)["poland:post"]; rse1 <- se(rob$placebo_55_59)["poland:post"]; rp1 <- pvalue(rob$placebo_55_59)["poland:post"]
rb2 <- coef(rob$placebo_2013)["poland:post_2013"]; rse2 <- se(rob$placebo_2013)["poland:post_2013"]; rp2 <- pvalue(rob$placebo_2013)["poland:post_2013"]

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & Women 55--59 & In-time placebo \\\\",
  " & (untreated age) & (2013 reform) \\\\",
  "\\midrule",
  sprintf("Poland $\\times$ Post & %.2f%s & %.2f%s \\\\",
    rb1, stars(rp1), rb2, stars(rp2)),
  sprintf(" & (%.2f) & (%.2f) \\\\", rse1, rse2),
  "[0.3em]",
  "Country FE & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes \\\\",
  sprintf("N & %d & %d \\\\", nobs(rob$placebo_55_59), nobs(rob$placebo_2013)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column (1): DD for women aged 55--59 (below the retirement threshold in both regimes). Column (2): in-time placebo using the 2013 reform onset with data restricted to pre-2017-Q4. Country-clustered SEs in column (1); Newey-West in column (2). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3, "tables/tab3_robustness.tex")

# ============================================================
# Table 4: Asymmetry — The Ratchet
# ============================================================

ab1 <- coef(rob$raise_2013)["poland:post_2013"]; ase1 <- se(rob$raise_2013)["poland:post_2013"]; ap1 <- pvalue(rob$raise_2013)["poland:post_2013"]
ab2 <- coef(rob$reversal_2017)["poland:post_rev"]; ase2 <- se(rob$reversal_2017)["poland:post_rev"]; ap2 <- pvalue(rob$reversal_2017)["poland:post_rev"]

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{The Ratchet: Comparing the 2013 Raise and 2017 Reversal}",
  "\\label{tab:asymmetry}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & 2013 Raise & 2017 Reversal \\\\",
  " & ($60 \\rightarrow 67$, gradual) & ($67 \\rightarrow 60$, immediate) \\\\",
  "\\midrule",
  sprintf("Poland $\\times$ Post & %.2f%s & %.2f%s \\\\",
    ab1, stars(ap1), ab2, stars(ap2)),
  sprintf(" & (%.2f) & (%.2f) \\\\", ase1, ase2),
  "[0.3em]",
  "Pre-period & 2010-Q1--2012-Q4 & 2015-Q1--2017-Q3 \\\\",
  "Post-period & 2013-Q1--2017-Q3 & 2017-Q4--2022-Q4 \\\\",
  "Country FE & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes \\\\",
  sprintf("N & %d & %d \\\\", nobs(rob$raise_2013), nobs(rob$reversal_2017)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Cross-country DD (Poland women 60--64 vs 8 CEE/EU donors). Column (1): effect of Poland's 2013 reform that gradually raised retirement age toward 67 for both sexes (phased in at 1 month per quarter; effective female retirement age reached $\\sim$61.5 by Q3 2017). Column (2): effect of the October 2017 reversal that immediately restored retirement age to 60 for women. The reversal's effect is approximately 1.8$\\times$ larger, despite the raise being phased over nearly 5 years. Newey-West HAC standard errors. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4, "tables/tab4_asymmetry.tex")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================

sd_y_pre <- pl |>
  filter(sex == "F", age_group == "60-64", post == 0) |>
  pull(emp_rate) |>
  sd(na.rm = TRUE)

sde_main <- b1 / sd_y_pre
se_sde_main <- se1 / sd_y_pre

sde_ddd <- b2 / sd_y_pre
se_sde_ddd <- se2 / sd_y_pre

sde_short <- b5 / sd_y_pre
se_sde_short <- se5 / sd_y_pre

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
  "\\textbf{Country:} Poland. ",
  "\\textbf{Research question:} Does an immediate statutory retirement age reversal --- lowering the pension eligibility age from 67 back to 60 for women --- reduce employment among newly eligible older workers, and is this response symmetric to the original raise? ",
  "\\textbf{Policy mechanism:} Poland's October 2017 law reversed a 2013 gradual retirement-age increase, immediately restoring the pre-2013 statutory pension age of 60 for women (and 65 for men), granting instant pension eligibility to all women aged 60--66 who had been required to continue working under the higher threshold. Over 357,000 new pension claims were filed in the first two quarters. ",
  "\\textbf{Outcome definition:} Quarterly employment rate (percentage of population employed) for women aged 60--64, from the Eurostat Labour Force Survey (\\texttt{lfsq\\_ergan}). ",
  "\\textbf{Treatment:} Binary; post-reversal indicator interacted with Poland (vs.\\ 8 CEE/EU donor countries). ",
  "\\textbf{Data:} Eurostat LFS quarterly employment rates by sex and 5-year age group for 9 countries, 2010-Q1 to 2024-Q4. ",
  "\\textbf{Method:} Cross-country difference-in-differences with country and quarter fixed effects; Newey-West HAC standard errors (Panel A) and cross-country DDD with country-clustered SEs (Panel B). ",
  "\\textbf{Sample:} Adults aged 55--69 in Poland and 8 CEE/EU comparison countries (CZ, SK, HU, DE, AT, LT, LV, EE); all citizens, quarterly frequency. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome for Polish women aged 60--64. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Spec. & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Empl.\\ (F, 60--64) & Cross-DD & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
    b1, se1, sd_y_pre, sde_main, se_sde_main, classify(sde_main)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Empl.\\ (F, 60--64) & Cross-DDD & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
    b2, se2, sd_y_pre, sde_ddd, se_sde_ddd, classify(sde_ddd)),
  sprintf("Empl.\\ (F, 60--64) & Short window & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
    b5, se5, sd_y_pre, sde_short, se_sde_short, classify(sde_short)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(sde_tab, "tables/tabF1_sde.tex")

cat("\nAll tables written to tables/\n")
cat(sprintf("Main cross-DD: %.2f (SE %.2f)\n", b1, se1))
cat(sprintf("Cross-DDD: %.2f (SE %.2f)\n", b2, se2))
cat(sprintf("SD(Y) pre: %.2f\n", sd_y_pre))
cat(sprintf("SDE (cross-DD): %.3f (%s)\n", sde_main, classify(sde_main)))
cat(sprintf("SDE (cross-DDD): %.3f (%s)\n", sde_ddd, classify(sde_ddd)))
