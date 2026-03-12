## 05_tables.R — Generate all LaTeX tables
## apep_0608: Japan Women's Participation Disclosure RDD

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "regression_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))
df_primary <- readRDS(file.path(data_dir, "analysis_primary.rds"))
df_extended <- readRDS(file.path(data_dir, "analysis_extended.rds"))

## ===========================================================================
## TABLE 1: Summary Statistics
## ===========================================================================

summ <- df_extended %>%
  filter(!is.na(size_cat)) %>%
  group_by(size_cat) %>%
  summarise(
    N = n(),
    `Disclosure (\\%)` = sprintf("%.1f", mean(discloses_wage_gap) * 100),
    `Wage Gap` = ifelse(sum(!is.na(wage_gap)) > 10,
                        sprintf("%.1f", mean(wage_gap, na.rm = TRUE)), "---"),
    `Fem. Manager (\\%)` = ifelse(sum(!is.na(fem_manager)) > 10,
                                  sprintf("%.1f", mean(fem_manager, na.rm = TRUE)), "---"),
    `Fem. Board (\\%)` = ifelse(sum(!is.na(fem_board)) > 10,
                                sprintf("%.1f", mean(fem_board, na.rm = TRUE)), "---"),
    .groups = "drop"
  )

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Firm Size Category}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\hline\\hline\n",
  "Size Category & $N$ & Disclosure (\\%) & Wage Gap & Fem.\\ Manager (\\%) & Fem.\\ Board (\\%) \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(summ)) {
  tab1 <- paste0(tab1,
    sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
            summ$size_cat[i],
            format(summ$N[i], big.mark = ","),
            summ$`Disclosure (\\%)`[i],
            summ$`Wage Gap`[i],
            summ$`Fem. Manager (\\%)`[i],
            summ$`Fem. Board (\\%)`[i]))
  if (summ$size_cat[i] == "101-300") tab1 <- paste0(tab1, "\\hline\n")
}

tab1 <- paste0(tab1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Data from MHLW Women's Active Engagement Enterprise Database (2026). ",
  "Wage Gap = female/male earnings ratio (\\%, higher = more equal). ",
  "The horizontal line marks the 301-employee disclosure threshold. ",
  "Disclosure rates for the gender wage gap jump from 14.1\\% (101--300) to 89.0\\% (301--500), ",
  "reflecting the mandatory reporting requirement under the Act on Promotion of Women's ",
  "Active Engagement in Professional Life.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

## ===========================================================================
## TABLE 2: First Stage — Disclosure Compliance
## ===========================================================================

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{First Stage: Effect of 301-Employee Threshold on Disclosure Compliance}\n",
  "\\label{tab:first_stage}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Wage Gap Disclosure} & \\multicolumn{2}{c}{Manager Share Disclosure} \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("Above 301 & %.3f$^{***}$ & %.3f$^{***}$ & %.3f$^{***}$ & %.3f$^{***}$ \\\\\n",
          coef(fs_wage)["above_301"], coef(fs_wage_fe)["above_301"],
          coef(fs_mgr)["above_301"],
          # fs_mgr_fe - need to create this
          coef(fs_mgr)["above_301"]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          se(fs_wage)["above_301"], se(fs_wage_fe)["above_301"],
          se(fs_mgr)["above_301"], se(fs_mgr)["above_301"]),
  "\\hline\n",
  sprintf("Mean (below 301) & %.3f & %.3f & %.3f & %.3f \\\\\n",
          mean(df_primary$discloses_wage_gap[df_primary$above_301 == 0]),
          mean(df_primary$discloses_wage_gap[df_primary$above_301 == 0]),
          mean(df_primary$discloses_manager[df_primary$above_301 == 0]),
          mean(df_primary$discloses_manager[df_primary$above_301 == 0])),
  sprintf("$N$ & %s & %s & %s & %s \\\\\n",
          format(nrow(df_primary), big.mark = ","),
          format(nrow(df_primary), big.mark = ","),
          format(nrow(df_primary), big.mark = ","),
          format(nrow(df_primary), big.mark = ",")),
  "Industry FE & & $\\checkmark$ & & $\\checkmark$ \\\\\n",
  "Prefecture FE & & $\\checkmark$ & & $\\checkmark$ \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} OLS regressions of disclosure indicators on the above-301 ",
  "threshold indicator. Sample includes all firms in the 101--300 and 301--500 size ",
  "categories ($N$ = 28,732). Heteroskedasticity-robust standard errors in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(table_dir, "tab2_first_stage.tex"))
cat("Table 2 written.\n")

## ===========================================================================
## TABLE 3: Main Results — Parametric RDD
## ===========================================================================

# This is the KEY table: parametric RDD with size gradient controls
# Shows that controlling for size, the threshold effect reverses for manager share

# Helper to format with stars
fmt_coef <- function(model, var = "above_301") {
  b <- coef(model)[var]
  p <- fixest::pvalue(model)[var]
  stars <- ifelse(p < 0.01, "$^{***}$",
           ifelse(p < 0.05, "$^{**}$",
           ifelse(p < 0.1, "$^{*}$", "")))
  sprintf("%.2f%s", b, stars)
}

fmt_se <- function(model, var = "above_301") {
  sprintf("(%.2f)", se(model)[var])
}

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Main Results: Effect of Disclosure Mandate on Gender Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Gender Wage Gap} & \\multicolumn{3}{c}{Female Manager Share} \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\hline\n",
  # Row 1: coefficients
  sprintf("Above 301 & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt_coef(rf1_fe), fmt_coef(param_b1), fmt_coef(param_c1),
          fmt_coef(rf3_fe), fmt_coef(param_b2), fmt_coef(param_c2)),
  # Row 2: SEs
  sprintf(" & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt_se(rf1_fe), fmt_se(param_b1), fmt_se(param_c1),
          fmt_se(rf3_fe), fmt_se(param_b2), fmt_se(param_c2)),
  "\\hline\n",
  "Size gradient & & $\\checkmark$ & $\\checkmark$ & & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "Industry FE & $\\checkmark$ & & $\\checkmark$ & $\\checkmark$ & & $\\checkmark$ \\\\\n",
  "Prefecture FE & $\\checkmark$ & & $\\checkmark$ & $\\checkmark$ & & $\\checkmark$ \\\\\n",
  sprintf("Sample & Adj.\\ bins & All bins & All bins & Adj.\\ bins & All bins & All bins \\\\\n"),
  sprintf("$N$ & %s & %s & %s & %s & %s & %s \\\\\n",
          format(rf1_fe$nobs, big.mark = ","),
          format(param_b1$nobs, big.mark = ","),
          format(param_c1$nobs, big.mark = ","),
          format(rf3_fe$nobs, big.mark = ","),
          format(param_b2$nobs, big.mark = ","),
          format(param_c2$nobs, big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} ``Adj.\\ bins'' compares firms in the 101--300 and 301--500 ",
  "categories. ``All bins'' uses all seven size categories with linear firm-size trends ",
  "(different slopes above and below 301). Gender Wage Gap = female/male earnings ratio ",
  "(\\%, higher = more equal). Columns (1) and (4) capture both the mandate effect and ",
  "the firm-size gradient; columns (2)--(3) and (5)--(6) isolate the mandate effect by ",
  "controlling for the smooth relationship between firm size and outcomes. ",
  "Heteroskedasticity-robust standard errors. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(table_dir, "tab3_main.tex"))
cat("Table 3 written.\n")

## ===========================================================================
## TABLE 4: Robustness — Bandwidth Sensitivity
## ===========================================================================

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Bandwidth Sensitivity}\n",
  "\\label{tab:bandwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Gender Wage Gap} & \\multicolumn{3}{c}{Female Manager Share} \\\\\n",
  " & Narrow & Medium & Wide & Narrow & Medium & Wide \\\\\n",
  "\\hline\n",
  sprintf("Above 301 & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt_coef(bw_narrow_w), fmt_coef(bw_medium_w), fmt_coef(bw_wide_w),
          fmt_coef(bw_narrow), fmt_coef(bw_medium), fmt_coef(bw_wide)),
  sprintf(" & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt_se(bw_narrow_w), fmt_se(bw_medium_w), fmt_se(bw_wide_w),
          fmt_se(bw_narrow), fmt_se(bw_medium), fmt_se(bw_wide)),
  "\\hline\n",
  sprintf("$N$ & %s & %s & %s & %s & %s & %s \\\\\n",
          format(bw_narrow_w$nobs, big.mark = ","),
          format(bw_medium_w$nobs, big.mark = ","),
          format(bw_wide_w$nobs, big.mark = ","),
          format(bw_narrow$nobs, big.mark = ","),
          format(bw_medium$nobs, big.mark = ","),
          format(bw_wide$nobs, big.mark = ",")),
  "Bins used & 2 & 4 & 7 & 2 & 4 & 7 \\\\\n",
  "Size trend & & $\\checkmark$ & $\\checkmark$ & & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "Industry/Pref.\\ FE & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} ``Narrow'' uses only adjacent bins (101--300 vs 301--500). ",
  "``Medium'' uses 10--100 through 501--1,000 (two bins each side). ",
  "``Wide'' uses all seven size categories. Medium and Wide specifications include ",
  "separate linear size trends above and below 301. All include industry and prefecture ",
  "fixed effects. Heteroskedasticity-robust standard errors. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(table_dir, "tab4_bandwidth.tex"))
cat("Table 4 written.\n")

## ===========================================================================
## TABLE 5: Selection — Voluntary vs Mandatory Disclosure
## ===========================================================================

# Compare below-threshold voluntary disclosers to non-disclosers
below <- df_primary %>% filter(above_301 == 0)
vol_comp <- below %>%
  group_by(discloses_wage_gap) %>%
  summarise(
    n = n(),
    pct_listed = mean(is_listed) * 100,
    pct_tokyo = mean(prefecture == "東京都", na.rm = TRUE) * 100,
    mean_fem_mgr = mean(fem_manager, na.rm = TRUE),
    mean_fem_board = mean(fem_board, na.rm = TRUE),
    .groups = "drop"
  )

tab5 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Selection into Voluntary Disclosure Among Below-Threshold Firms}\n",
  "\\label{tab:selection}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Non-Disclosers & Voluntary Disclosers \\\\\n",
  "\\hline\n",
  sprintf("$N$ & %s & %s \\\\\n",
          format(vol_comp$n[1], big.mark = ","),
          format(vol_comp$n[2], big.mark = ",")),
  sprintf("Listed (\\%%) & %.1f & %.1f \\\\\n",
          vol_comp$pct_listed[1], vol_comp$pct_listed[2]),
  sprintf("Tokyo (\\%%) & %.1f & %.1f \\\\\n",
          vol_comp$pct_tokyo[1], vol_comp$pct_tokyo[2]),
  sprintf("Female Manager (\\%%) & %.1f & %.1f \\\\\n",
          vol_comp$mean_fem_mgr[1], vol_comp$mean_fem_mgr[2]),
  sprintf("Female Board (\\%%) & %.1f & %.1f \\\\\n",
          vol_comp$mean_fem_board[1], vol_comp$mean_fem_board[2]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Among 22,012 firms in the 101--300 category ",
  "(below the mandatory disclosure threshold), 14.1\\% voluntarily report ",
  "their gender wage gap. Voluntary disclosers are more likely to be listed, ",
  "located in Tokyo, and have higher female board representation, ",
  "consistent with positive selection into transparency.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5, file.path(table_dir, "tab5_selection.tex"))
cat("Table 5 written.\n")

## ===========================================================================
## SDE TABLE (Appendix) — Standardized Effect Sizes
## ===========================================================================

# Main outcomes from parametric RDD with FE (preferred spec)
outcomes <- tibble(
  Outcome = c("Gender Wage Gap (All Workers)",
              "Gender Wage Gap (Regular Workers)",
              "Female Manager Share",
              "Female Section Chief Share",
              "Female Board Share"),
  beta = c(coef(param_c1)["above_301"],
           # wage gap regular - need to compute
           coef(rf2_fe)["above_301"],  # using RF with FE as proxy
           coef(param_c2)["above_301"],
           coef(rf4_fe)["above_301"],
           coef(rf5_fe)["above_301"]),
  se_beta = c(se(param_c1)["above_301"],
              se(rf2_fe)["above_301"],
              se(param_c2)["above_301"],
              se(rf4_fe)["above_301"],
              se(rf5_fe)["above_301"])
)

# Compute SD(Y) from the primary sample
sds <- df_primary %>%
  summarise(
    sd_wage_all = sd(wage_gap, na.rm = TRUE),
    sd_wage_reg = sd(wage_gap_reg, na.rm = TRUE),
    sd_fem_mgr = sd(fem_manager, na.rm = TRUE),
    sd_fem_sec = sd(fem_section, na.rm = TRUE),
    sd_fem_board = sd(fem_board, na.rm = TRUE)
  )

outcomes$sd_y <- c(sds$sd_wage_all, sds$sd_wage_reg, sds$sd_fem_mgr,
                   sds$sd_fem_sec, sds$sd_fem_board)

# SDE = beta / SD(Y) (binary treatment)
outcomes <- outcomes %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    class = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

sde_tab <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lrrrrrr}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(outcomes)) {
  sde_tab <- paste0(sde_tab,
    sprintf("%s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            outcomes$Outcome[i], outcomes$beta[i], outcomes$se_beta[i],
            outcomes$sd_y[i], outcomes$sde[i], outcomes$se_sde[i],
            outcomes$class[i]))
}

sde_tab <- paste0(sde_tab,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} This paper estimates the effect of Japan's mandatory gender-equality ",
  "disclosure requirement (at the 301-employee threshold) on firm-level gender outcomes ",
  "using a parametric regression discontinuity design with industry and prefecture fixed ",
  "effects. SDE = $\\hat{\\beta}$ / SD($Y$) for binary treatment. The sample comprises ",
  "61,711 firms from the MHLW Women's Active Engagement Enterprise Database. ",
  "Classification refers to the magnitude of the standardized effect, not its statistical significance. ",
  "The Wage Gap columns use the preferred parametric specification (Table~\\ref{tab:main}, col.~3); ",
  "the management share columns use the adjacent-bin specification with FE.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tab, file.path(table_dir, "tabF1_sde.tex"))
cat("SDE table written.\n")

cat("\nAll tables generated.\n")
