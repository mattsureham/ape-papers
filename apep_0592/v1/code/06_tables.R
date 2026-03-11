# ==============================================================================
# 06_tables.R — All table generation
# Paper: State Prohibition and Labor Market Restructuring (apep_0592)
# ==============================================================================

source("00_packages.R")

# Load model objects
load("../data/model_objects.RData")
load("../data/mechanism_objects.RData")
load("../data/longrun_objects.RData")
load("../data/robustness_objects.RData")

# Load CSV data
main_coefs <- fread("../data/main_coefficients.csv")
mechanism_coefs <- fread("../data/mechanism_coefficients.csv")
het_coefs <- fread("../data/heterogeneity_coefficients.csv")
fem_coefs <- fread("../data/female_coefficients.csv")
lr_coefs <- fread("../data/longrun_coefficients.csv")
sum_stats <- fread("../data/summary_stats.csv")
rob_results <- fread("../data/robustness_results.csv")
pre_coefs <- fread("../data/pretrend_coefficients.csv")

# ==============================================================================
# Table 1: Summary Statistics by Treatment Group
# ==============================================================================

tab1_data <- sum_stats[state_group %in% c("Went dry 1910-1919", "Wet until 1920"),
                       .(state_group, N, mean_age, pct_immigrant, pct_black,
                         pct_married, pct_literate, mean_occscore_1910,
                         sd_occscore_1910, mean_delta_occ, sd_delta_occ,
                         pct_occ_switch, pct_mover, mean_alc_share)]

# Format for LaTeX
tab1_rows <- data.table(
  Variable = c("N (male workers)", "Age (mean)", "Immigrant (\\%)",
               "Black (\\%)", "Married (\\%)", "Literate (\\%)",
               "OCCSCORE 1910 (mean)", "OCCSCORE 1910 (SD)",
               "$\\Delta$OCCSCORE (mean)", "$\\Delta$OCCSCORE (SD)",
               "Switched Occupation (\\%)", "Moved County (\\%)",
               "County Alcohol Share (\\%)")
)

for (g in c("Went dry 1910-1919", "Wet until 1920")) {
  row <- sum_stats[state_group == g]
  tab1_rows[, (g) := c(
    format(row$N, big.mark = ","),
    sprintf("%.1f", row$mean_age),
    sprintf("%.1f", row$pct_immigrant),
    sprintf("%.1f", row$pct_black),
    sprintf("%.1f", row$pct_married),
    sprintf("%.1f", row$pct_literate),
    sprintf("%.1f", row$mean_occscore_1910),
    sprintf("%.1f", row$sd_occscore_1910),
    sprintf("%.2f", row$mean_delta_occ),
    sprintf("%.1f", row$sd_delta_occ),
    sprintf("%.1f", row$pct_occ_switch),
    sprintf("%.1f", row$pct_mover),
    sprintf("%.2f", row$mean_alc_share)
  )]
}

tab1_tex <- kable(tab1_rows, format = "latex", booktabs = TRUE, escape = FALSE,
                  col.names = c("", "Treated States", "Control States"),
                  align = c("l", "c", "c"))

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 saved.\n")

# ==============================================================================
# Table 2: Main Results
# ==============================================================================

tab2_tex <- etable(m1, m2, m3, m4, m5,
                   keep = c("%treatment", "%alc_share", "%treated_state", "%treatment_years"),
                   dict = c(treatment = "AlcShare $\\times$ Treated",
                            alc_share = "Alcohol Share",
                            treated_state = "Treated State",
                            treatment_years = "AlcShare $\\times$ ProhibYears"),
                   se.below = TRUE,
                   headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
                   tex = TRUE,
                   fitstat = ~ n + r2,
                   notes = c("Standard errors clustered at state level in parentheses.",
                             "Sample: male workers aged 18-55 in 1910, excluding alcohol industry workers and already-dry states.",
                             "Columns 1-3 include region FE; Column 4 includes state FE; Column 5 uses years of prohibition.",
                             "All specifications include individual controls: age, age$^2$, immigrant, Black, married, literate.",
                             "Columns 3-5 also control for 1910 OCCSCORE."),
                   style.tex = style.tex("aer"),
                   file = "../tables/tab2_main.tex")
cat("Table 2 saved.\n")

# ==============================================================================
# Table 3: Mechanism Tests (from CSV — model objects freed for memory)
# ==============================================================================

# Build table from mechanism_coefficients.csv
mech_tab <- mechanism_coefs[, .(channel, outcome, beta, se, n, pval)]
mech_tab[, stars := fifelse(pval < 0.01, "***",
                     fifelse(pval < 0.05, "**",
                      fifelse(pval < 0.1, "*", "")))]
mech_tab[, beta_str := paste0(sprintf("%.3f", beta), stars)]
mech_tab[, se_str := paste0("(", sprintf("%.3f", se), ")")]

tab3_rows <- data.table(
  Variable = c("AlcShare $\\times$ Treated", "", "Observations")
)
for (i in 1:nrow(mech_tab)) {
  ch <- mech_tab$channel[i]
  tab3_rows[, (ch) := c(mech_tab$beta_str[i], mech_tab$se_str[i],
                          format(mech_tab$n[i], big.mark = ","))]
}

tab3_tex <- kable(tab3_rows, format = "latex", booktabs = TRUE, escape = FALSE,
                  align = c("l", rep("c", nrow(mech_tab))))

writeLines(tab3_tex, "../tables/tab3_mechanisms.tex")
cat("Table 3 saved.\n")

# ==============================================================================
# Table 4: Heterogeneity by Race and Nativity (from CSV)
# ==============================================================================

het_coefs[, stars := fifelse(pval < 0.01, "***",
                      fifelse(pval < 0.05, "**",
                       fifelse(pval < 0.1, "*", "")))]
het_coefs[, beta_str := paste0(sprintf("%.3f", beta), stars)]
het_coefs[, se_str := paste0("(", sprintf("%.3f", se), ")")]

tab4_rows <- data.table(
  Variable = c("AlcShare $\\times$ Treated", "", "Observations")
)
for (i in 1:nrow(het_coefs)) {
  sg <- het_coefs$subgroup[i]
  tab4_rows[, (sg) := c(het_coefs$beta_str[i], het_coefs$se_str[i],
                          format(het_coefs$n[i], big.mark = ","))]
}

tab4_tex <- kable(tab4_rows, format = "latex", booktabs = TRUE, escape = FALSE,
                  align = c("l", rep("c", nrow(het_coefs))))

writeLines(tab4_tex, "../tables/tab4_heterogeneity.tex")
cat("Table 4 saved.\n")

# ==============================================================================
# Table 5: Women's Employment and Long-Run Effects
# ==============================================================================

tab5_tex <- etable(fem_occ, fem_switch, lr_m1, lr_m2,
                   keep = "%treatment",
                   dict = c(treatment = "AlcShare $\\times$ Treated"),
                   se.below = TRUE,
                   headers = c("Female $\\Delta$OCC", "Female Switch",
                               "LR $\\Delta$OCC", "LR Switch"),
                   tex = TRUE,
                   fitstat = ~ n + r2,
                   notes = c("Standard errors clustered at state level in parentheses.",
                             "Columns 1-2: female workers in linked 1910-1920 panel.",
                             "Columns 3-4: male workers in linked 1920-1930 panel (long-run effects).",
                             "All specifications include region FE and individual controls."),
                   style.tex = style.tex("aer"),
                   file = "../tables/tab5_women_longrun.tex")
cat("Table 5 saved.\n")

# ==============================================================================
# Table C.1: Pre-Trend Test (Appendix)
# ==============================================================================

tab_c1_tex <- etable(pre_m1, pre_m2,
                     keep = c("%treatment", "%alc_share_1900"),
                     dict = c(treatment = "AlcShare $\\times$ Treated",
                              alc_share_1900 = "Alcohol Share (1900)"),
                     se.below = TRUE,
                     headers = c("(1)", "(2)"),
                     tex = TRUE,
                     fitstat = ~ n + r2,
                     notes = c("Standard errors clustered at state level in parentheses.",
                               "Sample: linked male workers 1900-1910, aged 18-55 in 1900.",
                               "Treatment defined using 1900 county alcohol shares and future (1910-1919) state prohibition.",
                               "Null coefficients indicate parallel pre-trends."),
                     style.tex = style.tex("aer"),
                     file = "../tables/tabC1_pretrend.tex")
cat("Table C.1 saved.\n")

# ==============================================================================
# Table F.1: Standardized Effect Sizes (Appendix F)
# ==============================================================================

# Extract coefficients from preferred specification (m3)
beta_main <- coef(m3)["treatment"]
se_main <- se(m3)["treatment"]

# For continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_main <- beta_main * sd_treatment / sd_delta_occ
se_sde_main <- se_main * sd_treatment / sd_delta_occ

# Classify SDE
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_table <- data.table(
  Outcome = c("$\\Delta$OCCSCORE (1910-1920)"),
  Specification = c("Table 2, Col. 3"),
  beta_hat = sprintf("%.3f", beta_main),
  SD_X = sprintf("%.4f", sd_treatment),
  SD_Y = sprintf("%.2f", sd_delta_occ),
  SDE = sprintf("%.4f", sde_main),
  SE_SDE = sprintf("%.4f", se_sde_main),
  Classification = classify_sde(sde_main)
)

sde_tex <- kable(sde_table, format = "latex", booktabs = TRUE, escape = FALSE,
                 col.names = c("Outcome", "Spec.", "$\\hat{\\beta}$", "SD($X$)",
                               "SD($Y$)", "SDE", "SE(SDE)", "Classification"),
                 align = c("l", "l", "r", "r", "r", "r", "r", "l"))

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("Table F.1 (SDE) saved.\n")

cat("\nAll tables generated.\n")
