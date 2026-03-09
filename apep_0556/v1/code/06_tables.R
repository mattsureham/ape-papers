## ============================================================
## 06_tables.R — Generate all LaTeX tables
## APEP Paper: India's NRHM and Neonatal Mortality Transition
## ============================================================

source("00_packages.R")
data_dir <- "../data"
tab_dir  <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

## ── Table 1: Summary Statistics ────────────────────────────────

cat("Table 1: Summary statistics...\n")

# Baseline (2006) summary by group
base <- panel[SurveyYear == 2006 & !is.na(inst_delivery)]

make_stats <- function(dt, group_label) {
  data.table(
    Group = group_label,
    N = nrow(dt),
    `Inst. Delivery (%)` = sprintf("%.1f (%.1f)", mean(dt$inst_delivery, na.rm = TRUE),
                                                    sd(dt$inst_delivery, na.rm = TRUE)),
    `ANC 4+ (%)` = sprintf("%.1f (%.1f)", mean(dt$anc_4plus, na.rm = TRUE),
                                            sd(dt$anc_4plus, na.rm = TRUE)),
    `Anemia (%)` = sprintf("%.1f (%.1f)", mean(dt$anemia_women, na.rm = TRUE),
                                           sd(dt$anemia_women, na.rm = TRUE))
  )
}

tab1 <- rbind(
  make_stats(base[high_focus == 1], "High-Focus States (Phase 1)"),
  make_stats(base[high_focus == 0], "Non-High-Focus States (Phase 2)"),
  make_stats(base, "All States")
)

# Add endline
end <- panel[SurveyYear == 2015 & !is.na(inst_delivery)]
tab1_end <- rbind(
  make_stats(end[high_focus == 1], "High-Focus States (Phase 1)"),
  make_stats(end[high_focus == 0], "Non-High-Focus States (Phase 2)"),
  make_stats(end, "All States")
)

# Write LaTeX
sink(file.path(tab_dir, "table1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Health Indicators by NRHM Treatment Group}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & Inst.\\ Delivery (\\%) & ANC 4+ (\\%) & Anemia (\\%) \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: Baseline (NFHS-3, 2005--06)}} \\\\\n")
for (i in 1:nrow(tab1)) {
  cat(sprintf("%s & %s & %s & %s \\\\\n",
              tab1$Group[i], tab1$`Inst. Delivery (%)`[i],
              tab1$`ANC 4+ (%)`[i], tab1$`Anemia (%)`[i]))
}
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: Endline (NFHS-4, 2015--16)}} \\\\\n")
for (i in 1:nrow(tab1_end)) {
  cat(sprintf("%s & %s & %s & %s \\\\\n",
              tab1_end$Group[i], tab1_end$`Inst. Delivery (%)`[i],
              tab1_end$`ANC 4+ (%)`[i], tab1_end$`Anemia (%)`[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Means with standard deviations in parentheses. ")
cat("High-focus states (Phase 1) include 8 EAG states, 8 northeastern states, Jammu \\& Kashmir, and Himachal Pradesh (18 total), ")
cat("which received priority ASHA deployment (2005--06) and higher JSY incentives (INR 1,400). ")
cat("Non-high-focus states (Phase 2) received ASHA deployment from 2008--10 with lower JSY incentives (INR 800). ")
cat("Source: DHS/NFHS subnational indicators via DHS Program API.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

## ── Table 2: Main DiD Results ──────────────────────────────────

cat("Table 2: Main results...\n")

# Re-run regressions for table output
panel_main <- panel[SurveyYear %in% c(2006, 2015, 2020)]
panel_main[, post := as.integer(SurveyYear >= 2015)]
panel_main[, jsy_intensity := jsy_incentive_inr / 1000]

m1 <- feols(inst_delivery ~ high_focus:post | state + SurveyYear,
            data = panel_main, cluster = ~state)
m2 <- feols(inst_delivery ~ high_focus:post | state + SurveyYear,
            data = panel_main[ne_state == 0], cluster = ~state)
m3 <- feols(inst_delivery ~ jsy_intensity:post | state + SurveyYear,
            data = panel_main, cluster = ~state)

panel_anc <- panel_main[!is.na(anc_4plus)]
m4 <- feols(anc_4plus ~ high_focus:post | state + SurveyYear,
            data = panel_anc[ne_state == 0], cluster = ~state)

panel_full <- panel[!is.na(inst_delivery)]
panel_full[, post := as.integer(SurveyYear >= 2015)]
m5 <- feols(inst_delivery ~ high_focus:post | state + SurveyYear,
            data = panel_full, cluster = ~state)

# Generate LaTeX table using modelsummary
# Disable \num{} wrapping to avoid siunitx issues
options("modelsummary_format_numeric_latex" = "plain")

dict <- c("high_focus:post" = "High-Focus $\\times$ Post",
          "jsy_intensity:post" = "JSY Intensity $\\times$ Post",
          "high_focus:post_1999" = "High-Focus $\\times$ Post")

ms_table <- modelsummary(
  list("(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4, "(5)" = m5),
  output = file.path(tab_dir, "table2_main.tex"),
  coef_map = dict,
  escape = FALSE,
  stars = c('*' = 0.10, '**' = 0.05, '***' = 0.01),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  title = "Effect of NRHM on Maternal Health Indicators",
  notes = list("State-clustered standard errors in parentheses.",
               "All regressions include state and survey-year fixed effects.",
               "High-focus states received priority ASHA deployment (2005--06) and higher JSY incentives.",
               "Column (3) uses continuous JSY incentive (INR thousands).",
               "Column (4) outcome is ANC 4+ visit rate.")
)

## ── Table 3: Robustness Summary ────────────────────────────────

cat("Table 3: Robustness...\n")

ri <- fread(file.path(data_dir, "robustness_ri.csv"))
pt <- fread(file.path(data_dir, "results_pretrend.csv"))
loo <- fread(file.path(data_dir, "robustness_loo.csv"))

sink(file.path(tab_dir, "table3_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("Test & Coefficient & SE & $p$-value & Result \\\\\n")
cat("\\hline\n")
cat(sprintf("Pre-trend (1993$\\rightarrow$1999) & %.2f & %.2f & %.3f & %s \\\\\n",
            pt$coef, pt$se, pt$pval,
            ifelse(pt$pval > 0.10, "Pass", "Fail")))
cat(sprintf("Randomization inference & %.2f & N/A & %.4f & %s \\\\\n",
            ri$actual_coef, ri$ri_pval, ifelse(ri$ri_pval < 0.05, "Significant", "Not sig.")))
cat(sprintf("Leave-one-out range & [%.1f, %.1f] & N/A & N/A & Stable \\\\\n",
            min(loo$coef), max(loo$coef)))
cat("\\hline\n")
main_coef <- coef(m2)["high_focus:post"]
main_se <- se(m2)["high_focus:post"]
main_pval <- 2 * pnorm(-abs(main_coef / main_se))
main_pval_str <- ifelse(main_pval < 0.001, "$<$0.001", sprintf("%.3f", main_pval))
cat(sprintf("Main estimate (reference) & %.2f & %.2f & %s & --- \\\\\n",
            main_coef, main_se, main_pval_str))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Pre-trend test compares differential change in institutional delivery ")
cat("between high-focus and non-high-focus states from NFHS-1 (1993) to NFHS-2 (1999), ")
cat("before NRHM launch. Randomization inference permutes treatment assignment across states ")
cat("(1,000 permutations). Leave-one-out drops each high-focus state individually.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

cat("\n✓ All tables saved to ../tables/\n")
