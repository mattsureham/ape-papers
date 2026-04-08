## 05_tables.R — Generate all LaTeX tables using etable (fixest)
## Paper: apep_1431 — France DMTO Composition Illusion

library(data.table)
library(fixest)
library(jsonlite)

cat("=== Table Generation: apep_1431 ===\n")

load("data/model_results.RData")
load("data/robustness_results.RData")
panel <- fread("data/dept_panel/dept_month_panel.csv")

dir.create("tables", showWarnings = FALSE)

# -------------------------------------------------------------------
# Helper: wrap etable output in full table environment
# -------------------------------------------------------------------
wrap_table <- function(etab, caption, label, note) {
  # etable returns a tabular; wrap in table environment
  # Extract the tabular content
  tab_content <- as.character(etab)
  # Replace \\begin{table} wrapper if already present
  if (grepl("\\\\begin\\{table\\}", tab_content)) {
    # Already wrapped; just update caption and label
    tab_content <- gsub("\\\\caption\\{\\\\label\\{[^}]*\\}[^}]*\\}",
                        sprintf("\\\\caption{\\\\label{%s} %s}", label, caption),
                        tab_content)
  }
  tab_content
}

dict_main <- c(
  "treat_march25" = "Treated $\\times$ March 2025",
  "treat_feb25"   = "Treated $\\times$ February 2025",
  "treat_apr25"   = "Treated $\\times$ April 2025",
  "log_n"         = "Log transactions",
  "log_mean_value" = "Log mean value",
  "share_above_300k" = "Share $>$300K",
  "share_above_500k" = "Share $>$500K",
  "code_departement" = "Department",
  "ym"            = "Month-Year"
)

# -------------------------------------------------------------------
# TABLE 1: Summary Statistics
# -------------------------------------------------------------------
cat("Generating Table 1...\n")

baseline_s <- panel[year %in% 2022:2024 & !is.na(treated), .(
  n_dept = uniqueN(code_departement),
  avg_n = round(mean(n_transactions)),
  avg_v = round(mean(mean_value)/1000),
  sh5   = round(mean(share_above_500k)*100, 1),
  sh3   = round(mean(share_above_300k)*100, 1)
), by = treated]

mar_s <- panel[year==2025 & month==3 & !is.na(treated),
               .(n=sum(n_transactions), v=round(mean(mean_value)/1000)), by=treated]
feb_s <- panel[year==2025 & month==2 & !is.na(treated),
               .(n=sum(n_transactions), v=round(mean(mean_value)/1000)), by=treated]

rat_t <- mar_s[treated==1]$n / feb_s[treated==1]$n
rat_c <- mar_s[treated==0]$n / feb_s[treated==0]$n
vchg_t <- (mar_s[treated==1]$v / feb_s[treated==1]$v - 1)*100
vchg_c <- (mar_s[treated==0]$v / feb_s[treated==0]$v - 1)*100

tab1 <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\small
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{\\textbf{Panel A: Baseline (2022--2024)}} & \\multicolumn{2}{c}{\\textbf{Panel B: Rush Window (2025)}} \\\\
\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}
 & Treated & Control & Treated & Control \\\\
 & (\\textit{n}=%d) & (\\textit{n}=%d) & -- & -- \\\\
\\hline
\\multicolumn{5}{l}{\\textit{Baseline transaction activity (2022--2024 monthly averages)}} \\\\
Avg.~monthly transactions & %s & %s & -- & -- \\\\
Avg.~transaction value (000 EUR) & %s & %s & -- & -- \\\\
Share above 500K EUR (\\%%) & %.1f & %.1f & -- & -- \\\\
Share above 300K EUR (\\%%) & %.1f & %.1f & -- & -- \\\\
\\hline
\\multicolumn{5}{l}{\\textit{February--March 2025: Timing manipulation}} \\\\
Total transactions, February 2025 & -- & -- & %s & %s \\\\
Total transactions, March 2025 & -- & -- & %s & %s \\\\
March / February ratio & -- & -- & %.2f & %.2f \\\\
Avg.~value, March 2025 (000 EUR) & -- & -- & %d & %d \\\\
Value change, Feb$\\to$Mar (\\%%) & -- & -- & %.1f & %.1f \\\\
\\hline\\hline
\\multicolumn{5}{p{0.92\\textwidth}}{\\footnotesize \\textit{Notes:}
Panel A: 2022--2024 monthly averages per department.
Panel B: February--March 2025 totals and averages.
Treated departments (n=%d) have an anomalous March 2025 surge:
the 2025 March/February transaction ratio exceeds the 2021--2024 average
ratio by more than 15\\%% (excess $\\geq 1.15$).
Control departments (n=%d) show no anomalous surge (excess $\\leq 1.05$).
Data: DVF (Demandes de Valeurs Fonci\\`eres), 2021--2025 H1.}
\\end{tabular}
\\end{table}
",
baseline_s[treated==1]$n_dept, baseline_s[treated==0]$n_dept,
format(baseline_s[treated==1]$avg_n, big.mark=","),
format(baseline_s[treated==0]$avg_n, big.mark=","),
format(baseline_s[treated==1]$avg_v, big.mark=","),
format(baseline_s[treated==0]$avg_v, big.mark=","),
baseline_s[treated==1]$sh5, baseline_s[treated==0]$sh5,
baseline_s[treated==1]$sh3, baseline_s[treated==0]$sh3,
format(feb_s[treated==1]$n, big.mark=","),
format(feb_s[treated==0]$n, big.mark=","),
format(mar_s[treated==1]$n, big.mark=","),
format(mar_s[treated==0]$n, big.mark=","),
rat_t, rat_c,
mar_s[treated==1]$v, mar_s[treated==0]$v,
vchg_t, vchg_c,
baseline_s[treated==1]$n_dept, baseline_s[treated==0]$n_dept
)
writeLines(tab1, "tables/tab1_summary.tex")
cat("Saved: tables/tab1_summary.tex\n")

# -------------------------------------------------------------------
# TABLE 2: Main DiD Results
# -------------------------------------------------------------------
cat("Generating Table 2...\n")

tab2 <- etable(
  m_did_n, m_did_v, m_did_sh300, m_did_sh500,
  tex = TRUE,
  coefstat = "se",
  signif.code = c("***"=0.01, "**"=0.05, "*"=0.1),
  title = "Anticipatory Bunching and Compositional Shift in March 2025",
  label = "tab:main",
  dict = dict_main,
  fitstat = ~ n + r2 + wr2,
  notes = "Standard errors clustered at the department level. Sample: January 2021--April 2025, 76 departments (25 treated, 51 control; 17 ambiguous excluded). Treated departments have an empirically anomalous March 2025 surge (excess March/Feb ratio $\\geq 1.15$ relative to 2021--2024 average ratio). Coefficients on Treated $\\times$ [month] give differential changes in treated vs.~control departments in that month relative to all other months (department + month-year FE absorbed)."
)
writeLines(as.character(tab2), "tables/tab2_main.tex")
cat("Saved: tables/tab2_main.tex\n")

# -------------------------------------------------------------------
# TABLE 3: Heterogeneity by value quintile
# -------------------------------------------------------------------
cat("Generating Table 3...\n")

dict3 <- c(
  "value_quintile::2:march_2025" = "Q2 $\\times$ March 2025",
  "value_quintile::3:march_2025" = "Q3 $\\times$ March 2025",
  "value_quintile::4:march_2025" = "Q4 $\\times$ March 2025",
  "value_quintile::5:march_2025" = "Q5 (highest) $\\times$ March 2025",
  "log_n" = "Log transactions",
  "log_mean_value" = "Log mean value",
  "code_departement" = "Department",
  "ym" = "Month-Year"
)

tab3 <- etable(
  m_hetero, m_hetero_v,
  tex = TRUE,
  coefstat = "se",
  signif.code = c("***"=0.01, "**"=0.05, "*"=0.1),
  title = "Heterogeneity: March 2025 Surge by Department Baseline Value Quintile",
  label = "tab:hetero",
  dict = dict3,
  fitstat = ~ n + r2 + wr2,
  notes = "Standard errors clustered at department level. Full sample: all 93 metropolitan departments. Quintiles based on average transaction value 2022--2024; Q1 (lowest value) is the reference group. Col.~1: log transaction count. Col.~2: log mean transaction value."
)
writeLines(as.character(tab3), "tables/tab3_hetero.tex")
cat("Saved: tables/tab3_hetero.tex\n")

# -------------------------------------------------------------------
# TABLE 4: Robustness
# -------------------------------------------------------------------
cat("Generating Table 4...\n")

dict4 <- c(
  "treat_march25" = "Treated $\\times$ March 2025",
  "treat_feb25"   = "Treated $\\times$ February 2025",
  "treat_apr25"   = "Treated $\\times$ April 2025",
  "treat_march_p" = "Treated $\\times$ March 2024 (placebo)",
  "treat_feb_p"   = "Treated $\\times$ Feb 2024 (placebo)",
  "treat_apr_p"   = "Treated $\\times$ Apr 2024 (placebo)",
  "treat_march23" = "Treated $\\times$ March 2023 (placebo)",
  "treat_feb23"   = "Treated $\\times$ Feb 2023 (placebo)",
  "treat_apr23"   = "Treated $\\times$ Apr 2023 (placebo)",
  "code_departement" = "Department",
  "ym" = "Month-Year"
)

tab4 <- etable(
  m_main, m_plac, m_plac23, m_other, m_full, m_narrow,
  tex = TRUE,
  coefstat = "se",
  signif.code = c("***"=0.01, "**"=0.05, "*"=0.1),
  title = "Robustness Checks",
  label = "tab:robust",
  dict = dict4,
  fitstat = ~ n,
  headers = list(
    "(1) Main" = 1, "(2) Placebo 2024" = 1,
    "(3) Placebo 2023" = 1, "(4) Non-resid." = 1,
    "(5) Full sample" = 1, "(6) Narrow" = 1
  ),
  notes = "Dependent variable: log(monthly transactions + 1), except Col.~4 (non-residential). Col.~1: main specification. Cols.~2--3: placebo with fake treatment dates (March 2024, March 2023). Col.~4: non-residential transactions (DMTO also applies). Col.~5: includes ambiguous departments. Col.~6: narrow window 2024--2025. All specifications: department + month-year FE, SEs clustered at department."
)
writeLines(as.character(tab4), "tables/tab4_robustness.tex")
cat("Saved: tables/tab4_robustness.tex\n")

# -------------------------------------------------------------------
# TABLE F1: SDE Appendix
# -------------------------------------------------------------------
cat("Generating Table F1...\n")

sd_log_n   <- sd(panel[year < 2025]$log_n, na.rm=TRUE)
sd_log_val <- sd(panel[year < 2025]$log_mean_value, na.rm=TRUE)
sd_sh300   <- sd(panel[year < 2025]$share_above_300k, na.rm=TRUE)
sd_sh500   <- sd(panel[year < 2025]$share_above_500k, na.rm=TRUE)

classify_sde <- function(sde) {
  a <- abs(sde)
  d <- ifelse(sde > 0, "positive", "negative")
  if (a < 0.005) return("Null")
  if (a < 0.05)  return(paste("Small", d))
  if (a < 0.15)  return(paste("Moderate", d))
  return(paste("Large", d))
}

sde_data <- data.frame(
  outcome = c(
    "Log transactions (March 2025)",
    "Log transactions (February 2025)",
    "Log transactions (April 2025)",
    "Log mean value (March 2025)",
    "Share $>$300K EUR (March 2025)"
  ),
  beta  = c(coef(m_did_n)["treat_march25"], coef(m_did_n)["treat_feb25"],
            coef(m_did_n)["treat_apr25"],  coef(m_did_v)["treat_march25"],
            coef(m_did_sh300)["treat_march25"]),
  se    = c(se(m_did_n)["treat_march25"], se(m_did_n)["treat_feb25"],
            se(m_did_n)["treat_apr25"],  se(m_did_v)["treat_march25"],
            se(m_did_sh300)["treat_march25"]),
  sd_y  = c(sd_log_n, sd_log_n, sd_log_n, sd_log_val, sd_sh300),
  stringsAsFactors = FALSE
)
sde_data$sde    <- sde_data$beta / sde_data$sd_y
sde_data$se_sde <- sde_data$se / sde_data$sd_y
sde_data$class  <- sapply(sde_data$sde, classify_sde)

# Panel B: Q1 vs Q5
dept_base <- panel[year%in%2022:2024, .(bv=mean(mean_value)), by=code_departement]
dept_base[order(bv), vq := ceiling(.I / (.N/5))]
dept_base[vq > 5, vq := 5L]
ph2 <- merge(panel, dept_base, by="code_departement")
ph2[, march_2025 := as.integer(year==2025 & month==3)]
m_q1 <- feols(log_n ~ march_2025 | code_departement + ym, data=ph2[vq==1], cluster=~code_departement)
m_q5 <- feols(log_n ~ march_2025 | code_departement + ym, data=ph2[vq==5], cluster=~code_departement)

sde_q1   <- coef(m_q1)["march_2025"] / sd_log_n
sde_q5   <- coef(m_q5)["march_2025"] / sd_log_n
se_sde_q1 <- se(m_q1)["march_2025"] / sd_log_n
se_sde_q5 <- se(m_q5)["march_2025"] / sd_log_n

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does a pre-announced 0.5pp increase in the real estate transfer tax (DMTO) generate anticipatory transaction bunching in March 2025, and is this bunching compositionally biased toward high-value transactions? ",
  "\\textbf{Policy mechanism:} Article 116 of France's 2025 Finance Law authorized departmental councils to raise DMTO from 4.5\\% to 5.0\\% on existing residential and commercial property sales, effective April 1, 2025. Buyers completing sales before April 1 avoided the additional tax. ",
  "\\textbf{Outcome definition:} Log monthly residential transaction count = ln(sales in DVF per department per month). Log mean value = ln(mean sale price EUR). Share $>$300K = fraction above 300,000 EUR. ",
  "\\textbf{Treatment:} Binary. Treated departments (n=25) have empirically anomalous March 2025 March/Feb ratio (excess $\\geq$1.15 vs.~2021--2024 average). Control (n=51) have excess $\\leq$1.05. ",
  "\\textbf{Data:} DVF (Demandes de Valeurs Fonci\\`eres), 2021--2025 H1. Aggregated to 76 department-month cells (17 ambiguous excluded). ",
  "\\textbf{Method:} TWFE DiD with department and month-year FE. SEs clustered at department. Panel B uses all 93 departments in within-department event study. ",
  "\\textbf{Sample:} Metropolitan French departments (DOM excluded). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where $\\text{SD}(Y)$ is 2021--2024 standard deviation. ",
  "Classification refers to magnitude, not statistical significance: Large ($|$SDE$|>0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($<0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes: DMTO Anticipatory Bunching}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textbf{Panel A: Treatment effects (DiD, treated vs. control)}} \\\\\n"
)

for (i in seq_len(nrow(sde_data))) {
  tabF1 <- paste0(tabF1, sprintf(
    "%s & %.3f & (%.3f) & %.3f & %.3f & (%.3f) & %s \\\\\n",
    sde_data$outcome[i], sde_data$beta[i], sde_data$se[i],
    sde_data$sd_y[i], sde_data$sde[i], sde_data$se_sde[i], sde_data$class[i]
  ))
}

tabF1 <- paste0(tabF1,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textbf{Panel B: Within-department March 2025 surge (Q1 vs. Q5 departments)}} \\\\\n",
  sprintf("Q1 (lowest value) $\\times$ March 2025 & %.3f & (%.3f) & %.3f & %.3f & (%.3f) & %s \\\\\n",
    coef(m_q1)["march_2025"], se(m_q1)["march_2025"], sd_log_n, sde_q1, se_sde_q1, classify_sde(sde_q1)),
  sprintf("Q5 (highest value) $\\times$ March 2025 & %.3f & (%.3f) & %.3f & %.3f & (%.3f) & %s \\\\\n",
    coef(m_q5)["march_2025"], se(m_q5)["march_2025"], sd_log_n, sde_q5, se_sde_q5, classify_sde(sde_q5)),
  "\\hline\\hline\n",
  "\\begin{tablenotes}\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "tables/tabF1_sde.tex")
cat("Saved: tables/tabF1_sde.tex\n")

cat("\n=== All tables complete ===\n")
cat("Files: tables/tab1_summary.tex, tab2_main.tex, tab3_hetero.tex, tab4_robustness.tex, tabF1_sde.tex\n")
