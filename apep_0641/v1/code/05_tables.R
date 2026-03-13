## 05_tables.R — Generate all tables for the paper
## apep_0641: Salary History Bans and Industry Pay Compression

source("00_packages.R")

cat("=== Generating tables ===\n")

# ---- Load results ----
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
qwi <- arrow::read_parquet("../data/analysis_panel.parquet")
gap <- arrow::read_parquet("../data/gender_gap_panel.parquet")
pre_gap <- read_csv("../data/pre_ban_gender_gaps.csv", show_col_types = FALSE)
summ_stats <- read_csv("../data/summary_stats.csv", show_col_types = FALSE)

# ---- Table 1: Summary Statistics ----
cat("Generating Table 1: Summary Statistics\n")

tab1_data <- qwi %>%
  filter(industry != "00") %>%
  mutate(group = ifelse(treated_state == 1, "Ban States", "No-Ban States")) %>%
  group_by(group, sex_label) %>%
  summarise(
    N = format(n(), big.mark = ","),
    `Earn (New Hire)` = round(weighted.mean(earn_hir, hir_n, na.rm = TRUE), 0),
    `SD(Earn NH)` = round(sd(earn_hir, na.rm = TRUE), 0),
    `Earn (Avg)` = round(weighted.mean(earn_s, emp, na.rm = TRUE), 0),
    `Hire Rate` = round(mean(hire_rate, na.rm = TRUE), 4),
    `Sep Rate` = round(mean(sep_rate, na.rm = TRUE), 4),
    .groups = "drop"
  )

# Write LaTeX
tab1_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: QWI Panel (2013--2025)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llrrrrrr}",
  "\\toprule",
  " & & & \\multicolumn{2}{c}{Earnings (\\$)} & & \\\\",
  "\\cmidrule(lr){4-5}",
  "Group & Sex & N & New Hire & Average & Hire Rate & Sep Rate \\\\",
  "\\midrule"
)

for (i in 1:nrow(tab1_data)) {
  row <- tab1_data[i, ]
  tab1_tex <- c(tab1_tex, sprintf(
    "%s & %s & %s & %s & %s & %.4f & %.4f \\\\",
    row$group, row$sex_label, row$N,
    format(row$`Earn (New Hire)`, big.mark = ","),
    format(row$`Earn (Avg)`, big.mark = ","),
    row$`Hire Rate`, row$`Sep Rate`
  ))
}

tab1_tex <- c(tab1_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\emph{Notes:} QWI state-industry-sex-quarter observations (ages 25--54, non-aggregate industries). Ban states: 16 states with private-employer salary history bans enacted 2017--2023. No-ban states: 34 states with no such law. Earnings are quarterly averages in nominal dollars. Hire rate = new hires / employment. Separation rate = separations / employment. Panel covers 2013Q1--2025Q1."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  -> tables/tab1_summary.tex\n")

# ---- Table 2: Pre-Ban Gender Gaps by Industry ----
cat("Generating Table 2: Pre-Ban Gender Gaps\n")

pre_gap_clean <- pre_gap %>%
  filter(!is.na(gender_gap_pct)) %>%
  arrange(desc(gender_gap_pct)) %>%
  head(15)

industry_labels <- c(
  "52" = "Finance/Insurance", "54" = "Professional Services",
  "55" = "Management", "51" = "Information",
  "71" = "Arts/Entertainment", "53" = "Real Estate",
  "21" = "Mining", "31-33" = "Manufacturing",
  "48-49" = "Transport/Warehouse", "42" = "Wholesale Trade",
  "56" = "Admin/Support", "23" = "Construction",
  "61" = "Education", "62" = "Healthcare",
  "44-45" = "Retail Trade", "72" = "Accommodation/Food",
  "81" = "Other Services", "92" = "Public Admin",
  "11" = "Agriculture", "22" = "Utilities"
)

tab2_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Pre-Ban Gender Earnings Gap by Industry (2013--2016)}",
  "\\label{tab:pregap}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llrrr}",
  "\\toprule",
  "NAICS & Industry & Male (\\$) & Female (\\$) & Gap (\\%) \\\\",
  "\\midrule"
)

for (i in 1:min(nrow(pre_gap_clean), 12)) {
  row <- pre_gap_clean[i, ]
  lab <- ifelse(row$industry %in% names(industry_labels),
                industry_labels[row$industry], row$industry)
  tab2_tex <- c(tab2_tex, sprintf(
    "%s & %s & %s & %s & %.1f \\\\",
    row$industry, lab,
    format(round(row$Male, 0), big.mark = ","),
    format(round(row$Female, 0), big.mark = ","),
    row$gender_gap_pct
  ))
}

tab2_tex <- c(tab2_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\emph{Notes:} Gender earnings gap calculated as (Male $-$ Female) / Male $\\times$ 100. Earnings are weighted-mean quarterly average earnings from QWI, ages 25--54, 2013--2016. Industries above the dashed line are classified as ``high-gap'' ($>$20\\%) for the triple-difference design.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_tex, "../tables/tab2_pregap.tex")
cat("  -> tables/tab2_pregap.tex\n")

# ---- Table 3: Main Results (Triple Difference) ----
cat("Generating Table 3: Main Results\n")

# Extract coefficients
extract_coef <- function(model, term_pattern) {
  ct <- coeftable(model)
  idx <- grep(term_pattern, rownames(ct))
  if (length(idx) == 0) return(list(est = NA, se = NA, p = NA))
  list(
    est = ct[idx[1], "Estimate"],
    se = ct[idx[1], "Std. Error"],
    p = ct[idx[1], "Pr(>|t|)"]
  )
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}

# Get DDD coefficients
ddd_models <- list(
  results$ddd_earn,
  results$ddd_avg_earn,
  results$ddd_hire,
  results$ddd_sep
)

outcome_labels <- c(
  "Log New-Hire Earn",
  "Log Avg Earnings",
  "Hire Rate",
  "Sep Rate"
)

tab3_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Salary History Bans on Labor Market Outcomes}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  paste0(" & ", paste(outcome_labels, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Female × Post
row_fp <- "Female $\\times$ Post"
vals_fp <- c()
se_fp <- c()
for (m in ddd_models) {
  c <- extract_coef(m, "^female:post$")
  vals_fp <- c(vals_fp, sprintf("%.4f%s", c$est, stars(c$p)))
  se_fp <- c(se_fp, sprintf("(%.4f)", c$se))
}
tab3_tex <- c(tab3_tex,
  paste0(row_fp, " & ", paste(vals_fp, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_fp, collapse = " & "), " \\\\"),
  "\\addlinespace"
)

# Female × Post × HighGap (the key DDD interaction)
row_ddd <- "Female $\\times$ Post $\\times$ HighGap"
vals_ddd <- c()
se_ddd <- c()
for (m in ddd_models) {
  c <- extract_coef(m, "female:post:high_gap_industry")
  vals_ddd <- c(vals_ddd, sprintf("%.4f%s", c$est, stars(c$p)))
  se_ddd <- c(se_ddd, sprintf("(%.4f)", c$se))
}
tab3_tex <- c(tab3_tex,
  paste0(row_ddd, " & ", paste(vals_ddd, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_ddd, collapse = " & "), " \\\\"),
  "\\addlinespace"
)

# N and FEs
tab3_tex <- c(tab3_tex,
  "\\midrule",
  sprintf("N & %s & %s & %s & %s \\\\",
    format(nobs(ddd_models[[1]]), big.mark = ","),
    format(nobs(ddd_models[[2]]), big.mark = ","),
    format(nobs(ddd_models[[3]]), big.mark = ","),
    format(nobs(ddd_models[[4]]), big.mark = ",")),
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Industry $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\emph{Notes:} Triple-difference estimates. Unit of observation is state-industry-sex-quarter (ages 25--54). ``Post'' indicates quarters after the state's salary history ban took effect. ``HighGap'' indicates industries with pre-ban gender earnings gap $>$20\\%. Female $\\times$ Post captures the average effect on women in low-gap industries. Female $\\times$ Post $\\times$ HighGap captures the differential effect in high-gap industries. Weighted by new hires (cols 1--2) or employment (cols 3--4). Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_tex, "../tables/tab3_main.tex")
cat("  -> tables/tab3_main.tex\n")

# ---- Table 4: Robustness ----
cat("Generating Table 4: Robustness\n")

att_main <- results$att_female
es_main_gap <- robust$es_gap

tab4_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Estimators and Samples}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & ATT & SE & $p$-value & N \\\\",
  "\\midrule",
  sprintf("\\emph{Panel A: Female new-hire earnings} & & & & \\\\"),
  sprintf("CS-DiD (baseline) & %.4f & %.4f & %.3f & %s \\\\",
    att_main$overall.att, att_main$overall.se,
    2 * pnorm(-abs(att_main$overall.att / att_main$overall.se)),
    "---"),
  "\\addlinespace",
  sprintf("\\emph{Panel B: Gender gap (log F/M)} & & & & \\\\")
)

# Baseline gap ATT
att_gap <- aggte(robust$cs_gap, type = "simple")
tab4_tex <- c(tab4_tex,
  sprintf("CS-DiD (baseline) & %.4f & %.4f & %.3f & --- \\\\",
    att_gap$overall.att, att_gap$overall.se,
    2 * pnorm(-abs(att_gap$overall.att / att_gap$overall.se)))
)

# No-COVID
tab4_tex <- c(tab4_tex,
  sprintf("Excl.\\ COVID (2020--2021H1) & %.4f & %.4f & %.3f & --- \\\\",
    robust$att_nocovid$overall.att, robust$att_nocovid$overall.se,
    2 * pnorm(-abs(robust$att_nocovid$overall.att / robust$att_nocovid$overall.se)))
)

# Placebo
tab4_tex <- c(tab4_tex,
  "\\addlinespace",
  sprintf("\\emph{Panel C: Placebo} & & & & \\\\"),
  sprintf("Male 45--54 (untargeted) & %.4f & %.4f & %.3f & --- \\\\",
    robust$att_placebo$overall.att, robust$att_placebo$overall.se,
    2 * pnorm(-abs(robust$att_placebo$overall.att / robust$att_placebo$overall.se)))
)

# Race results if available
if (!is.null(robust$att_black) && !is.null(robust$att_white)) {
  tab4_tex <- c(tab4_tex,
    "\\addlinespace",
    sprintf("\\emph{Panel D: Race heterogeneity} & & & & \\\\"),
    sprintf("Black new-hire earnings & %.4f & %.4f & %.3f & --- \\\\",
      robust$att_black$overall.att, robust$att_black$overall.se,
      2 * pnorm(-abs(robust$att_black$overall.att / robust$att_black$overall.se))),
    sprintf("White new-hire earnings & %.4f & %.4f & %.3f & --- \\\\",
      robust$att_white$overall.att, robust$att_white$overall.se,
      2 * pnorm(-abs(robust$att_white$overall.att / robust$att_white$overall.se)))
  )
}

tab4_tex <- c(tab4_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\emph{Notes:} Panel A reports the Callaway--Sant'Anna overall ATT for log female new-hire earnings. Panel B reports the ATT for the log female-to-male earnings ratio (gender gap). Panel C reports the placebo test on male workers aged 45--54 (not the target population for salary history bans). Panel D reports race-specific ATTs on new-hire earnings. All specifications use never-treated states as the control group.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_tex, "../tables/tab4_robust.tex")
cat("  -> tables/tab4_robust.tex\n")

# ---- Table 5 (SDE Table) ----
cat("Generating SDE Table (tabF1_sde.tex)\n")

# Extract key estimates for SDE
# 1. DDD: Female × Post on log new-hire earnings
ct_ddd <- coeftable(results$ddd_earn)
idx_fp <- grep("^female:post$", rownames(ct_ddd))
beta_fp <- ct_ddd[idx_fp[1], "Estimate"]
se_fp_val <- ct_ddd[idx_fp[1], "Std. Error"]

# 2. DDD: Female × Post × HighGap
idx_ddd <- grep("female:post:high_gap_industry", rownames(ct_ddd))
beta_ddd <- ct_ddd[idx_ddd[1], "Estimate"]
se_ddd_val <- ct_ddd[idx_ddd[1], "Std. Error"]

# SD of outcome
sd_y_logearn <- sd(qwi$log_earn_hir[qwi$industry != "00"], na.rm = TRUE)
sd_y_hirerate <- sd(qwi$hire_rate[qwi$industry != "00"], na.rm = TRUE)

# Hire rate DDD
ct_hire <- coeftable(results$ddd_hire)
idx_hire_fp <- grep("^female:post$", rownames(ct_hire))
beta_hire <- ct_hire[idx_hire_fp[1], "Estimate"]
se_hire <- ct_hire[idx_hire_fp[1], "Std. Error"]

# Gender gap ATT (CS-DiD)
att_gap_val <- att_gap$overall.att
se_gap_val <- att_gap$overall.se
sd_y_gap <- sd(gap$log_ratio_hir, na.rm = TRUE)

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

sde_rows <- data.frame(
  outcome = c(
    "Female new-hire earn (DDD)",
    "DDD $\\times$ HighGap",
    "Hiring rate (DDD)",
    "Gender gap (CS-DiD)"
  ),
  beta = c(beta_fp, beta_ddd, beta_hire, att_gap_val),
  se = c(se_fp_val, se_ddd_val, se_hire, se_gap_val),
  sd_y = c(sd_y_logearn, sd_y_logearn, sd_y_hirerate, sd_y_gap),
  stringsAsFactors = FALSE
)

sde_rows$sde <- sde_rows$beta / sde_rows$sd_y
sde_rows$se_sde <- sde_rows$se / sde_rows$sd_y
sde_rows$class <- classify_sde(sde_rows$sde)

sde_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  sde_tex <- c(sde_tex, sprintf(
    "%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class
  ))
}

sde_tex <- c(sde_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison. For binary treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$. SD($Y$) is the unconditional standard deviation from the full sample.",
  "\\textbf{Research question:} Do state salary history bans compress gender pay gaps, and does the effect vary across industry types?",
  "\\textbf{Treatment:} Binary: state adopted a private-employer salary history ban.",
  "\\textbf{Data:} Census QWI (Quarterly Workforce Indicators), 2013--2025, state-industry-sex-quarter panel.",
  "\\textbf{Method:} Triple-difference (DDD) and Callaway--Sant'Anna staggered DiD, state-clustered SEs.",
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("  -> tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
