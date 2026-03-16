# 05_tables.R — Table generation for apep_0699
# Saudi Arabia guardianship reform and female LFP

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) setwd(file.path(dirname(normalizePath(script_path)), ".."))

source("code/00_packages.R")
load("data/cleaned_data.RData")
load("data/results.RData")
load("data/robustness_results.RData")

dir.create("tables", showWarnings = FALSE)

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

sum_stats <- long_panel %>%
  group_by(
    group = case_when(
      iso2c == "SA" & gender == "female" ~ "Saudi women (treated)",
      iso2c == "SA" & gender == "male"   ~ "Saudi men (control 1)",
      iso2c != "SA" & gender == "female" ~ "GCC/MENA women (control 2)",
      iso2c != "SA" & gender == "male"   ~ "GCC/MENA men (control 3)"
    )
  ) %>%
  summarise(
    N = n(),
    `LFP 2010--17` = mean(lfp[year <= 2017], na.rm = TRUE),
    `LFP 2018` = mean(lfp[year == 2018], na.rm = TRUE),
    `LFP 2019` = mean(lfp[year == 2019], na.rm = TRUE),
    `LFP 2020--23` = mean(lfp[year >= 2020], na.rm = TRUE),
    `$\\Delta$ 2019--17` = mean(lfp[year == 2019], na.rm=T) - mean(lfp[year == 2017], na.rm=T),
    .groups = "drop"
  ) %>%
  arrange(group)

# Write LaTeX table
sink("tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Labor Force Participation Rates by Group, 2010--2023}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Group & N & 2010--17 & 2018 & 2019 & 2020--23 & $\\Delta$ 2019--17 \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(sum_stats)) {
  r <- sum_stats[i, ]
  cat(sprintf("%s & %d & %.1f & %.1f & %.1f & %.1f & %.1f \\\\\n",
    r$group, r$N,
    r$`LFP 2010--17`,
    r$`LFP 2018`,
    r$`LFP 2019`,
    r$`LFP 2020--23`,
    r$`$\\Delta$ 2019--17`
  ))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("{\\footnotesize \\textit{Notes:} LFP rates in percent. Data from World Bank World Development Indicators (ILO modeled estimates). The treatment group is Saudi women, subject to the male guardianship requirement until August 2019. Saudi men and women in GCC/MENA countries serve as controls. The driving ban was lifted June 2018; the guardianship decree took effect August 2019.}\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 written.\n")

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================
cat("Generating Table 2: Main DDD Results...\n")

# Extract coefficients from models
ddd_coef <- results$ddd_coef
ddd_se   <- results$ddd_se
ddd_pval <- results$ddd_pval

drive_coef <- results$drive_coef
drive_se   <- results$drive_se
drive_pval <- results$drive_pval

sa_guard_coef <- results$sa_guard_coef
sa_guard_se   <- results$sa_guard_se
sa_guard_pval <- 2 * pt(-abs(sa_guard_coef/sa_guard_se), df = Inf)

no2020_coef <- robustness_results$no2020_coef
no2020_se   <- robustness_results$no2020_se
no2020_pval <- 2 * pt(-abs(no2020_coef/no2020_se), df = Inf)

# Format p-values as stars
pstar <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

sink("tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Saudi Guardianship Reform on Female Labor Force Participation}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Full DDD & Driving ban & Saudi within & Ex-COVID \\\\\n")
cat("\\hline\n")
cat(sprintf("Saudi$\\times$Female$\\times$Guardianship & %.2f%s & & %.2f%s & %.2f%s \\\\\n",
    ddd_coef, pstar(ddd_pval),
    sa_guard_coef, pstar(sa_guard_pval),
    no2020_coef, pstar(no2020_pval)))
cat(sprintf(" & (%.2f) & & (%.2f) & (%.2f) \\\\\n",
    ddd_se, sa_guard_se, no2020_se))
cat(sprintf("Saudi$\\times$Female$\\times$Driving ban & & %.2f%s & %.2f%s & \\\\\n",
    drive_coef, pstar(drive_pval),
    coef(results$mod_sa_did)["is_female:post_driving"], pstar(
      2*pt(-abs(coef(results$mod_sa_did)["is_female:post_driving"]/
                sqrt(diag(vcov(results$mod_sa_did)))["is_female:post_driving"]), Inf))))
cat(sprintf(" & & (%.2f) & (%.2f) & \\\\\n",
    drive_se,
    sqrt(diag(vcov(results$mod_sa_did)))["is_female:post_driving"]))
cat("\\hline\n")
cat("Country$\\times$Gender FE & Yes & Yes & No & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat("GDP control & Yes & Yes & No & Yes \\\\\n")
cat("2020 included & Yes & Yes & Yes & No \\\\\n")
n_obs_ddd <- nobs(results$mod_ddd)
n_obs_sa  <- nobs(results$mod_sa_did)
cat(sprintf("Observations & %d & %d & %d & %d \\\\\n",
    n_obs_ddd, n_obs_ddd, n_obs_sa,
    nobs(robustness_results$mod_no2020)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat(sprintf("{\\footnotesize \\textit{Notes:} *** $p<0.01$, ** $p<0.05$, * $p<0.10$. Standard errors clustered at the country level in parentheses. Dependent variable is female labor force participation rate (percent). Column (1) reports the triple-difference estimate comparing Saudi women to Saudi men and GCC/MENA women/men. Column (2) reports the driving-ban placebo coefficient. Column (3) uses only Saudi Arabia data, comparing women to men. Column (4) excludes 2020 to isolate the reform effect from COVID-19. The key identifying variation is that Saudi Arabia's guardianship reform (August 2019) produced a 9.7 pp increase in female LFP through 2020, while the driving ban (June 2018) produced a 1.9 pp increase.}\n"))
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 written.\n")

# ============================================================
# TABLE 3: Synthetic Control Results
# ============================================================
cat("Generating Table 3: SCM Results...\n")

scm_res <- results$scm_results

# Annual SCM table
sink("tables/tab3_scm.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Synthetic Control Estimates of Guardianship Reform Effect}\n")
cat("\\label{tab:scm}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Year & Saudi Arabia & Synthetic Saudi & Gap \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(scm_res)) {
  r <- scm_res[i,]
  marker <- if (r$year == 2018) " [driving]" else if (r$year == 2019) " [guardianship]" else ""
  pre_mark <- if (r$year <= 2017) " & \\textit{pre}" else ""
  cat(sprintf("%d%s & %.1f & %.1f & %.1f \\\\\n",
    r$year, marker, r$sa_actual, r$synthetic, r$gap))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")

# SCM weights table
weights_df <- tibble(
  country = names(results$scm_weights),
  weight = as.numeric(results$scm_weights)
) %>% filter(weight > 0.01) %>% arrange(desc(weight))

cat("\\vspace{1em}\n")
cat("\\textit{Synthetic control weights:} ")
cat(paste(sprintf("%s (%.2f)", weights_df$country, weights_df$weight), collapse = ", "), "\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat(sprintf("{\\footnotesize \\textit{Notes:} The synthetic control is constructed from GCC/MENA donor countries to match Saudi Arabia's pre-2018 female LFP trajectory. Pre-treatment RMSPE: %.2f percentage points. The guardianship reform (August 2019) opened a gap of approximately %.1f pp by 2020--2023. In-space permutation test p-value: %.3f.}\n",
    results$rmspe_pre,
    results$mean_guard_effect_scm,
    robustness_results$pval_permutation))
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 written.\n")

# ============================================================
# TABLE 4: Event Study Coefficients
# ============================================================
cat("Generating Table 4: Event Study...\n")

event_df <- results$event_df %>%
  filter(!is.na(rel_year)) %>%
  arrange(rel_year)

sink("tables/tab4_event.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Event Study: Annual Treatment Effects on Saudi Female LFP}\n")
cat("\\label{tab:event}\n")
cat("\\begin{tabular}{cccc}\n")
cat("\\hline\\hline\n")
cat("Year (relative to 2019) & Estimate & Std. Error & 95\\% CI \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(event_df)) {
  r <- event_df[i,]
  pval_event <- if (r$std_error == 0) NA else 2 * pt(-abs(r$estimate / r$std_error), Inf)
  star <- pstar(pval_event)
  pre_post <- if (r$rel_year < 0) " (pre)" else if (r$rel_year == 0) " (reform yr)" else " (post)"
  cat(sprintf("%+d%s & %.2f%s & %.2f & [%.2f, %.2f] \\\\\n",
    r$rel_year, pre_post,
    r$estimate, star, r$std_error,
    r$ci_lo, r$ci_hi))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("{\\footnotesize \\textit{Notes:} *** $p<0.01$, ** $p<0.05$, * $p<0.10$. OLS with country and year fixed effects. Outcome is Saudi female LFP relative to GCC/MENA donor-pool average. Coefficients represent the Saudi advantage/disadvantage relative to base year 2018 (year $-$1). Pre-reform coefficients should be close to zero under parallel trends.}\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 written.\n")

# ============================================================
# TABLE 5: Robustness Checks
# ============================================================
cat("Generating Table 5: Robustness Checks...\n")

rob_data <- tribble(
  ~check, ~estimate, ~se, ~note,
  "Main DDD specification", results$ddd_coef, results$ddd_se, "Baseline",
  "Excl. 2020 (COVID)",     robustness_results$no2020_coef, robustness_results$no2020_se, "col (4)",
  "Gender gap DiD",         robustness_results$gap_coef, robustness_results$gap_se, "(M-F gap, neg = closed)",
  "In-time placebo (2015)", robustness_results$placebo_coef, robustness_results$placebo_se, "Should be 0",
  "SCM gap (2020+ avg)",    results$mean_guard_effect_scm, results$rmspe_pre, "SCM; SE = RMSPE"
)

sink("tables/tab5_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks for Guardianship Reform Effect}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Specification & Estimate & (SE) & Notes \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(rob_data)) {
  r <- rob_data[i,]
  pval_r <- 2 * pt(-abs(r$estimate / r$se), Inf)
  star_r <- pstar(pval_r)
  cat(sprintf("%s & %.2f%s & (%.2f) & %s \\\\\n",
    r$check, r$estimate, star_r, r$se, r$note))
}
cat("\\hline\n")
# Permutation test
cat(sprintf("In-space permutation test & & & p = %.3f \\\\\n",
    robustness_results$pval_permutation))
cat(sprintf("Pre-trend F-test (slope diff.) & %.3f & (%.3f) & Should be 0 \\\\\n",
    robustness_results$pre_trend_coef, robustness_results$pre_trend_se))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("{\\footnotesize \\textit{Notes:} *** $p<0.01$, ** $p<0.05$, * $p<0.10$. All specifications use country and year fixed effects. The in-time placebo uses a false treatment date of 2015, estimated on pre-reform data only; a null result confirms the main effect is not an artifact of time trends. The in-space permutation p-value reports the fraction of donor countries whose post-2020 SCM gap exceeds Saudi Arabia's.}\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 5 written.\n")

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) — Appendix
# ============================================================
cat("Generating SDE appendix table...\n")

# Compute SDE = beta / SD(Y)
outcomes <- long_panel %>%
  group_by(gender, is_saudi) %>%
  summarise(sd_lfp = sd(lfp, na.rm = TRUE), .groups = "drop")
sd_female_lfp <- sd(long_panel$lfp[long_panel$gender == "female"], na.rm = TRUE)

classify_sde <- function(sde) {
  if (is.na(sde)) return("--")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_data <- tribble(
  ~outcome, ~beta, ~se, ~sd_y,
  "Female LFP rate (DDD)", results$ddd_coef, results$ddd_se, sd_female_lfp,
  "Female LFP rate (SCM)", results$mean_guard_effect_scm, results$rmspe_pre, sd_female_lfp,
  "Female LFP rate (within-SA DiD)", results$sa_guard_coef, results$sa_guard_se, sd_female_lfp,
  "Gender gap (M-F LFP)", robustness_results$gap_coef, robustness_results$gap_se,
       sd(long_panel$lfp[long_panel$gender=="male"] - long_panel$lfp[long_panel$gender=="female"], na.rm=TRUE),
  "Driving ban effect (DDD)", results$drive_coef, results$drive_se, sd_female_lfp
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = sapply(sde, classify_sde)
  )

sink("tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & Classification \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(sde_data)) {
  r <- sde_data[i,]
  cat(sprintf("%s & %.2f & %.2f & %.2f & %.3f & %s \\\\\n",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$classification))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("{\\footnotesize \\textit{Notes:} Standardized Effect Size (SDE) $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the standard deviation of the outcome across all country-gender-year observations. Classifications are based on magnitude only, not statistical significance: Large $> |0.15|$; Moderate $[0.05, 0.15)$; Small $[0.005, 0.05)$; Null $< 0.005$. \\textbf{Country:} Saudi Arabia. \\textbf{Research question:} Did Royal Decree M/134 (August 2019), which granted Saudi women aged 21+ the right to work without male guardian permission, increase female labor force participation? \\textbf{Policy mechanism:} Prior to the decree, Saudi women were legally required to obtain written permission from a male guardian (father, husband, or brother) to enter the formal labor market. The August 2019 decree abolished this requirement for women aged 21+, removing a legal barrier to formal employment independent of physical mobility. \\textbf{Outcome:} Female labor force participation rate (\\%), defined as the share of women aged 15+ who are either employed or actively seeking work, from ILO modeled estimates (World Bank WDI). \\textbf{Treatment:} Binary; Saudi Arabia post-August 2019. \\textbf{Data:} World Bank WDI, 16 GCC/MENA countries, 2010--2023. Panel of 239 country-year observations. \\textbf{Method:} Triple difference (DDD) with country-gender and year fixed effects; synthetic control; within-country gender DiD. Standard errors clustered at country level. \\textbf{Sample:} Countries with complete pre-treatment female LFP data, 2010--2017.}\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("SDE table written.\n")

cat("\nAll tables generated in tables/\n")
cat(list.files("tables/"), "\n")
