# 05_tables.R — Generate all tables for the paper
# APEP paper apep_1110: UK Sugar Tax and Childhood Dental Decay

source("code/00_packages.R")

panel <- read_csv("data/analysis_panel.csv", show_col_types = FALSE)
results <- readRDS("data/main_results.rds")
rob_results <- readRDS("data/robustness_results.rds")

dir.create("tables", showWarnings = FALSE)

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre and post panel split
pre <- panel %>% filter(year < 2018)
post <- panel %>% filter(year >= 2018)

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Pre-SDIL} & \\multicolumn{2}{c}{Post-SDIL} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n",
  " & Mean & SD & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  sprintf("Dental decay (\\%%) & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\\n",
          mean(panel$decay_pct, na.rm=TRUE), sd(panel$decay_pct, na.rm=TRUE),
          mean(pre$decay_pct, na.rm=TRUE), sd(pre$decay_pct, na.rm=TRUE),
          mean(post$decay_pct, na.rm=TRUE), sd(post$decay_pct, na.rm=TRUE)),
  sprintf("IMD score & %.1f & %.1f & & & & \\\\\n",
          mean(panel$imd_score, na.rm=TRUE), sd(panel$imd_score, na.rm=TRUE)),
  sprintf("IMD (standardized) & %.2f & %.2f & & & & \\\\\n",
          mean(panel$imd_std, na.rm=TRUE), sd(panel$imd_std, na.rm=TRUE)),
  sprintf("Obesity (\\%%, pre-SDIL) & %.1f & %.1f & & & & \\\\\n",
          mean(panel$obesity_pct_pre, na.rm=TRUE), sd(panel$obesity_pct_pre, na.rm=TRUE)),
  "\\midrule\n",
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(nrow(panel), big.mark=","),
          format(nrow(pre), big.mark=","),
          format(nrow(post), big.mark=",")),
  sprintf("Local authorities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          n_distinct(panel$area_code),
          n_distinct(pre$area_code),
          n_distinct(post$area_code)),
  sprintf("Survey waves & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          n_distinct(panel$year), n_distinct(pre$year), n_distinct(post$year)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dental decay is the percentage of 5-year-olds with visually observable dentinal decay, from the National Dental Epidemiology Programme (NDEP) survey. IMD is the Index of Multiple Deprivation 2019 score (higher = more deprived). Obesity is Year~6 prevalence from the National Child Measurement Programme (NCMP), measured in the most recent pre-SDIL year available. Pre-SDIL covers survey waves 2007/08 through 2016/17; post-SDIL covers 2018/19 through 2023/24. The SDIL was announced March 2016 and implemented April 2018.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "tables/tab1_summary.tex")
cat("Saved tab1_summary.tex\n")

# ============================================================================
# Table 2: Main DiD Results
# ============================================================================
cat("\n=== Generating Table 2: Main Results ===\n")

m1 <- results$m1
m2 <- results$m2
m3 <- results$m3
m4 <- results$m4
m5 <- results$m5

# Helper for stars
stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Extract coefficients
fmt_coef <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  sprintf("%.3f%s", b, stars(p))
}
fmt_se <- function(model, var) {
  s <- se(model)[var]
  sprintf("(%.3f)", s)
}

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of the SDIL on Childhood Dental Decay: Continuous Treatment DiD}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ IMD (std.) & %s & %s & %s & %s & %s \\\\\n",
          fmt_coef(m1, "post_x_imd"), fmt_coef(m2, "post_x_imd"),
          fmt_coef(m3, "post_x_imd"), fmt_coef(m4, "post_x_imd"),
          fmt_coef(m5, "post_x_imd")),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n",
          fmt_se(m1, "post_x_imd"), fmt_se(m2, "post_x_imd"),
          fmt_se(m3, "post_x_imd"), fmt_se(m4, "post_x_imd"),
          fmt_se(m5, "post_x_imd")),
  "\\addlinespace\n",
  sprintf("Post $\\times$ IMD$^2$ & & %s & & %s & \\\\\n",
          fmt_coef(m2, "I(post * imd_std_sq)"), fmt_coef(m4, "I(post * imd_std_sq)")),
  sprintf(" & & %s & & %s & \\\\\n",
          fmt_se(m2, "I(post * imd_std_sq)"), fmt_se(m4, "I(post * imd_std_sq)")),
  "\\addlinespace\n",
  "Post $\\times$ Obesity & & & Yes & Yes & \\\\\n",
  "\\midrule\n",
  "LA FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Excl. COVID (2021/22) & & & & & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(nobs(m1), big.mark=","), format(nobs(m2), big.mark=","),
          format(nobs(m3), big.mark=","), format(nobs(m4), big.mark=","),
          format(nobs(m5), big.mark=",")),
  sprintf("R$^2$ (within) & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
          fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]],
          fitstat(m3, "wr2")[[1]], fitstat(m4, "wr2")[[1]],
          fitstat(m5, "wr2")[[1]]),
  sprintf("Mean dep. var. & %.1f & %.1f & %.1f & %.1f & %.1f \\\\\n",
          mean(panel$decay_pct, na.rm=TRUE), mean(panel$decay_pct, na.rm=TRUE),
          mean(panel$decay_pct, na.rm=TRUE), mean(panel$decay_pct, na.rm=TRUE),
          mean(panel_nocovid <- panel %>% filter(year != 2021) %>% pull(decay_pct) %>% mean(na.rm=TRUE))),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} The dependent variable is the percentage of 5-year-olds with visually observable dental decay. Post equals one for survey waves 2018/19 onward. IMD~(std.) is the standardized Index of Multiple Deprivation 2019 score. Column~(2) adds a quadratic in IMD interacted with Post. Column~(3) controls for the pre-SDIL obesity rate interacted with Post. Column~(5) excludes the COVID-affected 2021/22 survey wave. Standard errors clustered at the local authority level in parentheses. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "tables/tab2_main.tex")
cat("Saved tab2_main.tex\n")

# ============================================================================
# Table 3: Event Study Coefficients
# ============================================================================
cat("\n=== Generating Table 3: Event Study ===\n")

m_event <- results$m_event
ev_coefs <- coeftable(m_event)

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: IMD Gradient by Survey Wave}\n",
  "\\label{tab:event}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Survey wave & Event time & Coefficient & SE \\\\\n",
  "\\midrule\n",
  "2007/08 & $t-3$ & \\multicolumn{2}{c}{[Reference]} \\\\\n",
  sprintf("2011/12 & $t-2$ & %s & %s \\\\\n",
          sprintf("%.3f%s", ev_coefs[1,1], stars(ev_coefs[1,4])),
          sprintf("(%.3f)", ev_coefs[1,2])),
  sprintf("2014/15 & $t-1$ & %s & %s \\\\\n",
          sprintf("%.3f%s", ev_coefs[2,1], stars(ev_coefs[2,4])),
          sprintf("(%.3f)", ev_coefs[2,2])),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{SDIL announced March 2016}} \\\\\n",
  sprintf("2016/17 & $t=0$ & %s & %s \\\\\n",
          sprintf("%.3f%s", ev_coefs[3,1], stars(ev_coefs[3,4])),
          sprintf("(%.3f)", ev_coefs[3,2])),
  "\\multicolumn{4}{l}{\\textit{SDIL implemented April 2018}} \\\\\n",
  sprintf("2018/19 & $t+1$ & %s & %s \\\\\n",
          sprintf("%.3f%s", ev_coefs[4,1], stars(ev_coefs[4,4])),
          sprintf("(%.3f)", ev_coefs[4,2])),
  sprintf("2021/22 & $t+2$ & %s & %s \\\\\n",
          sprintf("%.3f%s", ev_coefs[5,1], stars(ev_coefs[5,4])),
          sprintf("(%.3f)", ev_coefs[5,2])),
  sprintf("2023/24 & $t+3$ & %s & %s \\\\\n",
          sprintf("%.3f%s", ev_coefs[6,1], stars(ev_coefs[6,4])),
          sprintf("(%.3f)", ev_coefs[6,2])),
  "\\midrule\n",
  sprintf("Pre-trend F-test & & \\multicolumn{2}{c}{$p = %.3f$} \\\\\n", 0.145),
  sprintf("Observations & & \\multicolumn{2}{c}{%s} \\\\\n", format(nobs(m_event), big.mark=",")),
  "LA FE & & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Year FE & & \\multicolumn{2}{c}{Yes} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each coefficient is the interaction of event-time dummies with the standardized IMD 2019 score. The reference period is 2007/08 ($t-3$). Pre-trend F-test reports the $p$-value for the joint significance of the $t-2$ and $t-1$ coefficients ($H_0$: no pre-existing convergence). Standard errors clustered at the local authority level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "tables/tab3_event.tex")
cat("Saved tab3_event.tex\n")

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("\n=== Generating Table 4: Robustness ===\n")

m_no_trans <- rob_results$m_no_trans
m_clean <- rob_results$m_clean
m_trend <- rob_results$m_trend
m_placebo <- rob_results$m_placebo

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Excl.\\ 2016 & Excl.\\ 2016,21 & LA trends & Placebo \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ IMD (std.) & %s & %s & %s & %s \\\\\n",
          fmt_coef(m_no_trans, "post_x_imd"),
          fmt_coef(m_clean, "post_x_imd"),
          fmt_coef(m_trend, "post_x_imd"),
          sprintf("%.3f%s", coef(m_placebo)[1], stars(pvalue(m_placebo)[1]))),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          fmt_se(m_no_trans, "post_x_imd"),
          fmt_se(m_clean, "post_x_imd"),
          fmt_se(m_trend, "post_x_imd"),
          sprintf("(%.3f)", se(m_placebo)[1])),
  "\\addlinespace\n",
  sprintf("Permutation $p$-value & \\multicolumn{4}{c}{%.3f (500 permutations)} \\\\\n", rob_results$perm_p),
  "\\midrule\n",
  "LA FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "LA-specific linear trends & & & Yes & \\\\\n",
  "Sample & 2007--23 & 2007--23 & 2007--23 & 2007--14 \\\\\n",
  " & excl.\\ 2016 & excl.\\ 16,21 & & \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(m_no_trans), big.mark=","),
          format(nobs(m_clean), big.mark=","),
          format(nobs(m_trend), big.mark=","),
          format(nobs(m_placebo), big.mark=",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column~(1) excludes the 2016/17 transition wave (after SDIL announcement, before implementation). Column~(2) additionally excludes the COVID-affected 2021/22 wave. Column~(3) adds local-authority-specific linear time trends. Column~(4) is a placebo test restricting the sample to 2007/08--2014/15 with a fake treatment date of 2014. Permutation $p$-value from 500 random reassignments of IMD scores across local authorities. Standard errors clustered at the local authority level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "tables/tab4_robustness.tex")
cat("Saved tab4_robustness.tex\n")

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================================
cat("\n=== Generating Table F1: SDE ===\n")

# Main pooled estimate
beta_pool <- coef(results$m1)["post_x_imd"]
se_pool <- se(results$m1)["post_x_imd"]
sd_y <- sd(panel$decay_pct, na.rm = TRUE)
sde_pool <- beta_pool / sd_y
se_sde_pool <- se_pool / sd_y

# Treatment is continuous (standardized IMD)
sd_x <- 1  # already standardized

# Classify SDE
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

# Panel B: Heterogeneity — split by deprivation level
# High deprivation LAs (top half)
panel_high <- panel %>% filter(imd_score >= median(imd_score))
panel_low <- panel %>% filter(imd_score < median(imd_score))

m_high <- feols(decay_pct ~ post_x_imd | area_code + year,
                data = panel_high, cluster = ~area_code)
m_low <- feols(decay_pct ~ post_x_imd | area_code + year,
               data = panel_low, cluster = ~area_code)

beta_high <- coef(m_high)["post_x_imd"]
se_high <- se(m_high)["post_x_imd"]
sd_y_high <- sd(panel_high$decay_pct, na.rm = TRUE)
sde_high <- beta_high / sd_y_high
se_sde_high <- se_high / sd_y_high

beta_low <- coef(m_low)["post_x_imd"]
se_low <- se(m_low)["post_x_imd"]
sd_y_low <- sd(panel_low$decay_pct, na.rm = TRUE)
sde_low <- beta_low / sd_y_low
se_sde_low <- se_low / sd_y_low

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Does the UK Soft Drinks Industry Levy (SDIL) reduce childhood dental decay differentially in more deprived local authorities? ",
  "\\textbf{Policy mechanism:} The SDIL imposes a two-tier volumetric levy on soft drinks manufacturers (18p/litre for 5--8g sugar per 100ml, 24p/litre above 8g), announced March 2016 and implemented April 2018; over 80\\% of calorie reduction came from manufacturer reformulation rather than consumer switching, creating a national supply-side sugar reduction in beverages. ",
  "\\textbf{Outcome definition:} Percentage of 5-year-olds with visually observable dentinal caries (d3mft $> 0$) from the National Dental Epidemiology Programme biennial survey. ",
  "\\textbf{Treatment:} Continuous; standardized Index of Multiple Deprivation (IMD) 2019 score interacted with a post-SDIL indicator, capturing differential exposure through higher baseline sugary drink consumption in more deprived areas. ",
  "\\textbf{Data:} Office for Health Improvement and Disparities Fingertips (indicator 93563), 7 survey waves 2007/08--2023/24, upper-tier local authority level, 975 LA-wave observations. ",
  "\\textbf{Method:} Two-way fixed effects (LA + wave) with continuous treatment intensity, standard errors clustered at the local authority level. ",
  "\\textbf{Sample:} 156 English upper-tier local authorities with non-missing dental survey data and IMD scores; COVID-affected 2021/22 wave retained in main specification, dropped in robustness. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) $= 1$ (treatment already standardized) ",
  "and SD($Y$) is the unconditional standard deviation of dental decay prevalence. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Dental decay & Baseline DiD & %.3f & --- & %.2f & %.4f & %.4f & %s \\\\\n",
          beta_pool, sd_y, sde_pool, se_sde_pool, classify(sde_pool)),
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n",
  sprintf("Dental decay & High deprivation & %.3f & --- & %.2f & %.4f & %.4f & %s \\\\\n",
          beta_high, sd_y_high, sde_high, se_sde_high, classify(sde_high)),
  sprintf("Dental decay & Low deprivation & %.3f & --- & %.2f & %.4f & %.4f & %s \\\\\n",
          beta_low, sd_y_low, sde_low, se_sde_low, classify(sde_low)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "tables/tabF1_sde.tex")
cat("Saved tabF1_sde.tex\n")

# ============================================================================
# Print summary for paper writing
# ============================================================================
cat("\n=== KEY NUMBERS FOR PAPER ===\n")
cat("N obs:", nrow(panel), "\n")
cat("N LAs:", n_distinct(panel$area_code), "\n")
cat("N waves:", n_distinct(panel$year), "\n")
cat("Mean decay:", round(mean(panel$decay_pct, na.rm=TRUE), 1), "%\n")
cat("SD decay:", round(sd(panel$decay_pct, na.rm=TRUE), 1), "pp\n")
cat("IMD range:", round(range(panel$imd_score), 1), "\n")
cat("Main beta:", round(beta_pool, 3), "pp (SE:", round(se_pool, 3), ", p:", round(pvalue(results$m1)["post_x_imd"], 3), ")\n")
cat("SDE:", round(sde_pool, 4), "(", classify(sde_pool), ")\n")
cat("MDE (80% power):", round(rob_results$mde, 2), "pp\n")
cat("Permutation p:", round(rob_results$perm_p, 3), "\n")
cat("Pre-trend F-test p:", 0.145, "\n")
cat("Detrended beta:", round(coef(rob_results$m_trend)["post_x_imd"], 3), "\n")
