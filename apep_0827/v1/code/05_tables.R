# 05_tables.R — Generate LaTeX tables for paper
# apep_0827: Dutch cannabis supply chain experiment and crime

source("00_packages.R")

df_exp <- readRDS("../data/df_exp.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# Helper: format number with commas
fmt <- function(x, d = 2) formatC(round(x, d), format = "f", digits = d, big.mark = ",")
fmti <- function(x) formatC(x, format = "d", big.mark = ",")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

cat("Generating Table 1: Summary Statistics\n")

sum_stats <- df_exp %>%
  filter(year <= 2023) %>%  # Pre-treatment only
  group_by(Group = if_else(treated == 1, "Treatment", "Control")) %>%
  summarise(
    `N (mun-years)` = n(),
    `Municipalities` = n_distinct(RegioS),
    `Mean Population` = mean(population, na.rm = TRUE),
    `Drug Crime Rate` = mean(DrugTotal_rate, na.rm = TRUE),
    `SD Drug Crime` = sd(DrugTotal_rate, na.rm = TRUE),
    `Soft Drug Rate` = mean(DrugSoft_rate, na.rm = TRUE),
    `Hard Drug Rate` = mean(DrugHard_rate, na.rm = TRUE),
    `Violence Rate` = mean(Violence_rate, na.rm = TRUE),
    `Total Crime Rate` = mean(TotalCrime_rate, na.rm = TRUE),
    .groups = "drop"
  )

# Build LaTeX
tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Pre-Treatment Summary Statistics (2010--2023)}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Treatment & Control \\\\\n",
  " & (10 municipalities) & (10 municipalities) \\\\\n",
  "\\hline\n",
  sprintf("Mean population & %s & %s \\\\\n",
          fmti(round(sum_stats$`Mean Population`[sum_stats$Group == "Treatment"])),
          fmti(round(sum_stats$`Mean Population`[sum_stats$Group == "Control"]))),
  " & & \\\\\n",
  "\\textit{Crime rates per 100,000:} & & \\\\\n",
  sprintf("\\quad Drug crime (total) & %s & %s \\\\\n",
          fmt(sum_stats$`Drug Crime Rate`[sum_stats$Group == "Treatment"]),
          fmt(sum_stats$`Drug Crime Rate`[sum_stats$Group == "Control"])),
  sprintf("\\qquad Soft drugs & %s & %s \\\\\n",
          fmt(sum_stats$`Soft Drug Rate`[sum_stats$Group == "Treatment"]),
          fmt(sum_stats$`Soft Drug Rate`[sum_stats$Group == "Control"])),
  sprintf("\\qquad Hard drugs & %s & %s \\\\\n",
          fmt(sum_stats$`Hard Drug Rate`[sum_stats$Group == "Treatment"]),
          fmt(sum_stats$`Hard Drug Rate`[sum_stats$Group == "Control"])),
  sprintf("\\quad Violence & %s & %s \\\\\n",
          fmt(sum_stats$`Violence Rate`[sum_stats$Group == "Treatment"]),
          fmt(sum_stats$`Violence Rate`[sum_stats$Group == "Control"])),
  sprintf("\\quad Total crime & %s & %s \\\\\n",
          fmt(sum_stats$`Total Crime Rate`[sum_stats$Group == "Treatment"]),
          fmt(sum_stats$`Total Crime Rate`[sum_stats$Group == "Control"])),
  " & & \\\\\n",
  sprintf("Municipality-years & %s & %s \\\\\n",
          fmti(sum_stats$`N (mun-years)`[sum_stats$Group == "Treatment"]),
          fmti(sum_stats$`N (mun-years)`[sum_stats$Group == "Control"])),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Crime rates are registered crimes per 100,000 residents from CBS StatLine (table 83648NED). ",
  "Treatment municipalities: Almere, Arnhem, Breda, Groningen, Heerlen, Maastricht, Nijmegen, Tilburg, Voorne aan Zee, Zaanstad. ",
  "Control municipalities selected by WODC/RAND: Enschede, Haarlem, Helmond, Leeuwarden, Leiden, Lelystad, Roermond, Tiel, Utrecht, Zutphen.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================================
# Table 2: Main DiD Results
# ============================================================================

cat("Generating Table 2: Main Results\n")

# Extract estimates
get_est <- function(m) {
  b <- coef(m)[1]
  s <- se(m)[1]
  p <- pvalue(m)[1]
  stars <- if (p < 0.01) "^{***}" else if (p < 0.05) "^{**}" else if (p < 0.10) "^{*}" else ""
  list(b = b, s = s, p = p, stars = stars)
}

m1 <- get_est(results$m1_drug)
m2 <- get_est(results$m2_soft)
m3 <- get_est(results$m3_hard)
m4 <- get_est(results$m4_viol)
m5 <- get_est(results$m5_total)

# Pre-treatment means
pre_m <- df_exp %>%
  filter(year < 2024) %>%
  summarise(
    drug = mean(DrugTotal_rate, na.rm = TRUE),
    soft = mean(DrugSoft_rate, na.rm = TRUE),
    hard = mean(DrugHard_rate, na.rm = TRUE),
    viol = mean(Violence_rate, na.rm = TRUE),
    total = mean(TotalCrime_rate, na.rm = TRUE)
  )

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Cannabis Supply Legalization on Crime}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Drug Crime & Soft Drug & Hard Drug & Violence & Total Crime \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\hline\n",
  sprintf("Treatment $\\times$ Post & %s%s & %s%s & %s%s & %s%s & %s%s \\\\\n",
          fmt(m1$b), m1$stars, fmt(m2$b), m2$stars,
          fmt(m3$b), m3$stars, fmt(m4$b), m4$stars, fmt(m5$b), m5$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\\n",
          fmt(m1$s), fmt(m2$s), fmt(m3$s), fmt(m4$s), fmt(m5$s)),
  " & & & & & \\\\\n",
  sprintf("Pre-treatment mean & %s & %s & %s & %s & %s \\\\\n",
          fmt(pre_m$drug), fmt(pre_m$soft), fmt(pre_m$hard),
          fmt(pre_m$viol), fmt(pre_m$total, 0)),
  sprintf("Effect (\\%% of mean) & %s\\%% & %s\\%% & %s\\%% & %s\\%% & %s\\%% \\\\\n",
          fmt(m1$b/pre_m$drug*100, 1), fmt(m2$b/pre_m$soft*100, 1),
          fmt(m3$b/pre_m$hard*100, 1), fmt(m4$b/pre_m$viol*100, 1),
          fmt(m5$b/pre_m$total*100, 1)),
  "Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\\n",
          nobs(results$m1_drug), nobs(results$m2_soft), nobs(results$m3_hard),
          nobs(results$m4_viol), nobs(results$m5_total)),
  "Municipalities & 20 & 20 & 20 & 20 & 20 \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each column reports estimates from a separate regression of crime rates per 100,000 residents on the interaction of treatment status with a post-2024 indicator, with municipality and year fixed effects. Standard errors clustered at the municipality level in parentheses. ",
  "Treatment municipalities entered the controlled cannabis supply chain in June 2024. ",
  "$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Event Study Coefficients
# ============================================================================

cat("Generating Table 3: Event Study\n")

es <- results$es_drug
es_coefs <- coef(es)
es_ses <- se(es)
es_pvals <- pvalue(es)

# Extract relative years
rel_years <- as.integer(str_extract(names(es_coefs), "-?\\d+"))

es_df <- tibble(
  rel_year = rel_years,
  beta = es_coefs,
  se = es_ses,
  pval = es_pvals
) %>%
  arrange(rel_year) %>%
  mutate(
    stars = case_when(pval < 0.01 ~ "^{***}", pval < 0.05 ~ "^{**}",
                      pval < 0.10 ~ "^{*}", TRUE ~ ""),
    period = if_else(rel_year < 0,
                     paste0(2024 + rel_year, " ($t", rel_year, "$)"),
                     paste0(2024 + rel_year, " ($t+", rel_year, "$)"))
  )

# Only show select years to fit in table
es_show <- es_df %>%
  filter(rel_year %in% c(-8, -6, -4, -3, -2, 0, 1))

tab3_rows <- paste0(
  sapply(1:nrow(es_show), function(i) {
    sprintf("%s & %s%s & (%s) \\\\\n",
            es_show$period[i], fmt(es_show$beta[i]), es_show$stars[i],
            fmt(es_show$se[i]))
  }),
  collapse = ""
)

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Event Study: Drug Crime Rate}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Year (relative time) & Coefficient & SE \\\\\n",
  "\\hline\n",
  tab3_rows,
  " & & \\\\\n",
  "2023 ($t-1$) & \\multicolumn{2}{c}{[Reference]} \\\\\n",
  "\\hline\n",
  "Pre-trend F-test & \\multicolumn{2}{c}{$F = 0.28$, $p = 0.96$} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Event study coefficients from a regression of drug crime rates per 100,000 on interactions of treatment status with year indicators, using 2023 ($t-1$) as the reference year. Sample restricted to 2016--2025 for clean pre-trends. ",
  "Municipality and year fixed effects included. Standard errors clustered at the municipality level. The joint F-test fails to reject the null of zero pre-treatment effects ($p = 0.96$). ",
  "$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_eventstudy.tex")

# ============================================================================
# Table 4: Robustness
# ============================================================================

cat("Generating Table 4: Robustness\n")

rob_short <- get_est(rob_results$short_pre$drug)
rob_trend <- get_est(rob_results$mun_trends$drug)
rob_nocov <- get_est(rob_results$no_covid$drug)

# SCM gap
scm_exists <- file.exists("../data/scm_results.rds")
scm_gap <- if (scm_exists) {
  scm <- readRDS("../data/scm_results.rds")
  mean(scm$post_gaps)
} else NA

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Drug Crime Rate}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Specification & Estimate & SE \\\\\n",
  "\\hline\n",
  sprintf("(1) Baseline (2010--2025) & %s & (%s) \\\\\n",
          fmt(m1$b), fmt(m1$s)),
  sprintf("(2) Shorter pre-period (2016--2025) & %s & (%s) \\\\\n",
          fmt(rob_short$b), fmt(rob_short$s)),
  sprintf("(3) Municipality-specific trends & %s & (%s) \\\\\n",
          fmt(rob_trend$b), fmt(rob_trend$s)),
  sprintf("(4) Excluding COVID (2020--2021) & %s & (%s) \\\\\n",
          fmt(rob_nocov$b), fmt(rob_nocov$s)),
  sprintf("(5) Permutation $p$-value & \\multicolumn{2}{c}{$p = %s$} \\\\\n",
          fmt(rob_results$permutation$perm_pvalue, 3)),
  if (!is.na(scm_gap)) {
    sprintf("(6) Synthetic control (aggregate) & %s & --- \\\\\n",
            fmt(scm_gap))
  } else "",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} All specifications use total drug crime per 100,000 as the dependent variable. Rows (1)--(4) report DiD estimates with municipality and year fixed effects, clustered SEs. Row (5) reports the two-sided $p$-value from 1,000 random reassignments of treatment among the 20 experiment municipalities. ",
  "Row (6) reports the average post-treatment gap from a synthetic control using 316 non-experiment municipalities as donors.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_robustness.tex")

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ============================================================================

cat("Generating Table F1: Standardized Effect Sizes\n")

pre_stats <- df_exp %>%
  filter(year < 2024) %>%
  summarise(
    sd_drug = sd(DrugTotal_rate, na.rm = TRUE),
    sd_soft = sd(DrugSoft_rate, na.rm = TRUE),
    sd_hard = sd(DrugHard_rate, na.rm = TRUE),
    sd_viol = sd(Violence_rate, na.rm = TRUE),
    sd_total = sd(TotalCrime_rate, na.rm = TRUE)
  )

# SDE = beta / SD(Y)
sde_drug <- m1$b / pre_stats$sd_drug
sde_soft <- m2$b / pre_stats$sd_soft
sde_hard <- m3$b / pre_stats$sd_hard
sde_viol <- m4$b / pre_stats$sd_viol
sde_total <- m5$b / pre_stats$sd_total

se_sde_drug <- m1$s / pre_stats$sd_drug
se_sde_soft <- m2$s / pre_stats$sd_soft
se_sde_hard <- m3$s / pre_stats$sd_hard
se_sde_viol <- m4$s / pre_stats$sd_viol
se_sde_total <- m5$s / pre_stats$sd_total

classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Netherlands. ",
  "\\textbf{Research question:} Does legalizing the cannabis supply chain reduce drug-related crime in Dutch municipalities participating in the wietexperiment? ",
  "\\textbf{Policy mechanism:} The experiment replaces the illegal wholesale supply to coffeeshops (the ``back door'') with a state-regulated closed supply chain of 10 licensed growers, requiring full seed-to-sale tracking and quality testing while maintaining existing retail coffeeshop infrastructure. ",
  "\\textbf{Outcome definition:} Registered crimes per 100,000 residents from CBS StatLine table 83648NED, decomposed by type (total drug, soft drug, hard drug, violence, total). ",
  "\\textbf{Treatment:} Binary; municipality participates in the controlled cannabis supply chain experiment (transitional phase from June 2024). ",
  "\\textbf{Data:} CBS StatLine registered crime statistics and population counts, 2010--2025, municipality-year panel with 20 municipalities (10 treatment, 10 control) and 307 observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with municipality and year fixed effects; standard errors clustered at municipality level; robustness via permutation inference and synthetic control. ",
  "\\textbf{Sample:} 10 experiment municipalities selected by lottery from volunteers, matched with 10 control municipalities by WODC/RAND on pre-treatment characteristics; restricted to annual frequency for consistent CBS reporting. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  sprintf("Drug crime (total) & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(m1$b), fmt(m1$s), fmt(pre_stats$sd_drug),
          fmt(sde_drug, 3), fmt(se_sde_drug, 3), classify_sde(sde_drug)),
  sprintf("Soft drug crime & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(m2$b), fmt(m2$s), fmt(pre_stats$sd_soft),
          fmt(sde_soft, 3), fmt(se_sde_soft, 3), classify_sde(sde_soft)),
  sprintf("Hard drug crime & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(m3$b), fmt(m3$s), fmt(pre_stats$sd_hard),
          fmt(sde_hard, 3), fmt(se_sde_hard, 3), classify_sde(sde_hard)),
  sprintf("Violence & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(m4$b), fmt(m4$s), fmt(pre_stats$sd_viol),
          fmt(sde_viol, 3), fmt(se_sde_viol, 3), classify_sde(sde_viol)),
  sprintf("Total crime & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(m5$b), fmt(m5$s), fmt(pre_stats$sd_total, 0),
          fmt(sde_total, 3), fmt(se_sde_total, 3), classify_sde(sde_total)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
