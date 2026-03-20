## 05_tables.R — apep_0728
## Generate all LaTeX tables (including SDE appendix)

source("00_packages.R")

models <- readRDS("../data/models.rds")
robust_models <- readRDS("../data/robust_models.rds")
qwi <- readRDS("../data/qwi_clean.rds")
bw_gap <- readRDS("../data/bw_gap_panel.rds")
ntr_gaps <- readRDS("../data/ntr_gaps.rds")
diagnostics <- jsonlite::fromJSON("../data/diagnostics.json")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════════════════

df <- qwi %>% filter(race %in% c("BK", "WH"))

summ_pre <- df %>%
  filter(year <= 2000) %>%
  group_by(race) %>%
  summarise(
    `Mean Monthly Earnings` = mean(avg_earnings, na.rm = TRUE),
    `SD Monthly Earnings` = sd(avg_earnings, na.rm = TRUE),
    `Mean Employment` = mean(employment, na.rm = TRUE),
    `Mean Hires` = mean(hires, na.rm = TRUE),
    `Mean Separations` = mean(separations, na.rm = TRUE),
    `N (county-industry-quarter)` = n(),
    .groups = "drop"
  )

summ_post <- df %>%
  filter(year >= 2001) %>%
  group_by(race) %>%
  summarise(
    `Mean Monthly Earnings` = mean(avg_earnings, na.rm = TRUE),
    `SD Monthly Earnings` = sd(avg_earnings, na.rm = TRUE),
    `Mean Employment` = mean(employment, na.rm = TRUE),
    `Mean Hires` = mean(hires, na.rm = TRUE),
    `Mean Separations` = mean(separations, na.rm = TRUE),
    `N (county-industry-quarter)` = n(),
    .groups = "drop"
  )

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: QWI Manufacturing Earnings by Race and Period}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-PNTR (1995--2000)} & \\multicolumn{2}{c}{Post-PNTR (2001--2010)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Black & White & Black & White \\\\",
  "\\midrule"
)

# Fill values
for (var in c("Mean Monthly Earnings", "SD Monthly Earnings", "Mean Employment",
              "Mean Hires", "Mean Separations", "N (county-industry-quarter)")) {
  bk_pre <- summ_pre %>% filter(race == "BK") %>% pull(!!sym(var))
  wh_pre <- summ_pre %>% filter(race == "WH") %>% pull(!!sym(var))
  bk_post <- summ_post %>% filter(race == "BK") %>% pull(!!sym(var))
  wh_post <- summ_post %>% filter(race == "WH") %>% pull(!!sym(var))

  if (var == "N (county-industry-quarter)") {
    tab1_lines <- c(tab1_lines,
      sprintf("%s & %s & %s & %s & %s \\\\",
              var,
              format(round(bk_pre), big.mark = ","),
              format(round(wh_pre), big.mark = ","),
              format(round(bk_post), big.mark = ","),
              format(round(wh_post), big.mark = ",")))
  } else {
    tab1_lines <- c(tab1_lines,
      sprintf("%s & %s & %s & %s & %s \\\\",
              var,
              format(round(bk_pre, 1), big.mark = ","),
              format(round(wh_pre, 1), big.mark = ","),
              format(round(bk_post, 1), big.mark = ","),
              format(round(wh_post, 1), big.mark = ",")))
  }
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Black-White Earnings Gap & \\multicolumn{2}{c}{\\$%s} & \\multicolumn{2}{c}{\\$%s} \\\\",
          format(round(summ_pre$`Mean Monthly Earnings`[summ_pre$race == "WH"] -
                       summ_pre$`Mean Monthly Earnings`[summ_pre$race == "BK"], 0), big.mark = ","),
          format(round(summ_post$`Mean Monthly Earnings`[summ_post$race == "WH"] -
                       summ_post$`Mean Monthly Earnings`[summ_post$race == "BK"], 0), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from QWI race $\\times$ industry panel (Azure). Sample restricted to manufacturing industries (NAICS 31--33) in counties with both Black and White employment. Earnings are average monthly earnings in nominal dollars.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 2: Main DDD Results
# ══════════════════════════════════════════════════════════════════════════════

cm <- c(
  "ntr_x_black_x_post" = "NTR Gap $\\times$ Black $\\times$ Post",
  "ntr_x_post" = "NTR Gap $\\times$ Post",
  "black_x_post" = "Black $\\times$ Post",
  "ntr_x_black" = "NTR Gap $\\times$ Black",
  "ntr_gap:post_pntr" = "NTR Gap $\\times$ Post"
)

gm <- list(
  list(raw = "nobs", clean = "Observations", fmt = function(x) format(x, big.mark = ",")),
  list(raw = "r.squared", clean = "$R^2$", fmt = 3),
  list(raw = "FE: county_industry", clean = "County $\\times$ Industry FE", fmt = function(x) ifelse(x > 0, "\\checkmark", "")),
  list(raw = "FE: county_quarter", clean = "County $\\times$ Quarter FE", fmt = function(x) ifelse(x > 0, "\\checkmark", "")),
  list(raw = "FE: industry_quarter", clean = "Industry $\\times$ Quarter FE", fmt = function(x) ifelse(x > 0, "\\checkmark", ""))
)

modelsummary(
  list(
    "(1)" = models$m1_baseline,
    "(2)" = models$m2_ind_fe,
    "(3)" = models$m3_saturated,
    "(4)" = models$m4_bw_gap
  ),
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title = "Triple-Difference Estimates: PNTR, Race, and Manufacturing Earnings",
  notes = list(
    "Standard errors clustered by state in parentheses.",
    "Dependent variable: log average monthly earnings (cols 1--3) or Black-White log earnings gap (col 4).",
    "NTR Gap is the Pierce-Schott (2016) industry-level difference between Smoot-Hawley and NTR tariff rates.",
    "Post = 1 for quarters after Q4 2000. Black = 1 for Black workers."
  ),
  output = "../tables/tab2_main.tex",
  escape = FALSE
)
cat("Table 2 written.\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 3: Event Study Coefficients
# ══════════════════════════════════════════════════════════════════════════════

es_coefs <- as.data.frame(coeftable(models$m_es))
es_coefs$term <- rownames(es_coefs)

# Extract relative year from term names
es_coefs <- es_coefs %>%
  mutate(
    rel_year = as.numeric(gsub(".*::(-?[0-9]+):.*", "\\1", term))
  ) %>%
  filter(!is.na(rel_year)) %>%
  arrange(rel_year) %>%
  mutate(
    stars = case_when(
      `Pr(>|t|)` < 0.01 ~ "***",
      `Pr(>|t|)` < 0.05 ~ "**",
      `Pr(>|t|)` < 0.10 ~ "*",
      TRUE ~ ""
    )
  )

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: NTR Gap $\\times$ Black Interaction by Year Relative to PNTR}",
  "\\label{tab:event_study}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Year Relative to PNTR & Coefficient & Std. Error \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_coefs))) {
  yr <- es_coefs$rel_year[i]
  yr_label <- ifelse(yr == 0, "0 (reference)", as.character(yr))
  tab3_lines <- c(tab3_lines,
    sprintf("$t = %s$ & %s%s & (%s) \\\\",
            yr_label,
            format(round(es_coefs$Estimate[i], 4), nsmall = 4),
            es_coefs$stars[i],
            format(round(es_coefs$`Std. Error`[i], 4), nsmall = 4)))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(diagnostics$n_obs, big.mark = ",")),
  "Fixed Effects & \\multicolumn{2}{c}{County$\\times$Ind., County$\\times$Qtr., Ind.$\\times$Qtr.} \\\\",
  "Clustering & \\multicolumn{2}{c}{State} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from regressing log earnings on interactions of NTR Gap $\\times$ Black $\\times$ year dummies, with year 2000 as reference. Pre-PNTR coefficients test the parallel trends assumption. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_event_study.tex")
cat("Table 3 written.\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 4: Mechanism Decomposition
# ══════════════════════════════════════════════════════════════════════════════

cm_mech <- c("ntr_x_black_x_post" = "NTR Gap $\\times$ Black $\\times$ Post")

modelsummary(
  list(
    "Log Earnings" = models$m3_saturated,
    "Log Employment" = models$m_emp,
    "Log Hires" = models$m_hire,
    "Log Separations" = models$m_sep
  ),
  coef_map = cm_mech,
  gof_map = gm,
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title = "Mechanism Decomposition: Earnings, Employment, Hires, and Separations",
  notes = list(
    "Standard errors clustered by state in parentheses.",
    "All specifications include county$\\times$industry, county$\\times$quarter, and industry$\\times$quarter fixed effects.",
    "The DDD coefficient captures the differential effect on Black vs. White workers in high- vs. low-NTR-gap industries after PNTR."
  ),
  output = "../tables/tab4_mechanisms.tex",
  escape = FALSE
)
cat("Table 4 written.\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 5: Robustness and Placebo Tests
# ══════════════════════════════════════════════════════════════════════════════

# Need to rename coefficients for uniform display
cm_robust <- c(
  "ntr_x_black_x_post" = "DDD Coefficient",
  "ntr_x_black_x_placebo" = "DDD Coefficient",
  "ntr_x_asian_x_post" = "DDD Coefficient"
)

modelsummary(
  list(
    "Baseline" = models$m3_saturated,
    "County Clust." = robust_models$r1_county,
    "Two-Way Clust." = robust_models$r2_twoway,
    "Trim NTR" = robust_models$r3_trim,
    "Excl. South" = robust_models$r4_nosouth,
    "Placebo Pre" = robust_models$r5_placebo,
    "Asian Placebo" = robust_models$r6_asian
  ),
  coef_map = cm_robust,
  gof_map = gm,
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title = "Robustness Checks and Placebo Tests",
  notes = list(
    "Standard errors in parentheses. Col. 1: baseline (state clustering). Col. 2: county clustering.",
    "Col. 3: two-way clustering (state $\\times$ industry). Col. 4: trim top/bottom quartile NTR gaps.",
    "Col. 5: exclude Southern states. Col. 6: pre-PNTR placebo (1998+ vs 1995--1997).",
    "Col. 7: Asian workers replacing Black (should be null if effect is specific to Black workers)."
  ),
  output = "../tables/tab5_robustness.tex",
  escape = FALSE
)
cat("Table 5 written.\n")

# ══════════════════════════════════════════════════════════════════════════════
# SDE APPENDIX TABLE (tabF1_sde.tex)
# ══════════════════════════════════════════════════════════════════════════════

cat("\n=== GENERATING SDE TABLE ===\n")

# Compute SD(Y) for each outcome from pre-treatment period
df_pre <- df %>% filter(year <= 2000)

sd_log_earnings <- sd(df_pre$log_earnings, na.rm = TRUE)
sd_log_emp <- sd(log(df_pre$employment + 1), na.rm = TRUE)
sd_log_hires <- sd(log(df_pre$hires + 1), na.rm = TRUE)
sd_log_sep <- sd(log(df_pre$separations + 1), na.rm = TRUE)

# For BW gap
bw_pre <- bw_gap %>% filter(year <= 2000)
sd_bw_gap <- sd(bw_pre$bw_earnings_gap, na.rm = TRUE)

# SD of treatment (NTR gap × Black interaction — continuous)
sd_treatment <- sd(df$ntr_x_black, na.rm = TRUE)

# Compute SDEs
# For continuous treatment: SDE = β × SD(X) / SD(Y)
sde_earnings <- coef(models$m3_saturated)["ntr_x_black_x_post"] * sd_treatment / sd_log_earnings
sde_emp <- coef(models$m_emp)["ntr_x_black_x_post"] * sd_treatment / sd_log_emp
sde_hires <- coef(models$m_hire)["ntr_x_black_x_post"] * sd_treatment / sd_log_hires
sde_sep <- coef(models$m_sep)["ntr_x_black_x_post"] * sd_treatment / sd_log_sep

# SE(SDE) = SE(β) × SD(X) / SD(Y)
se_sde_earnings <- sqrt(vcov(models$m3_saturated)["ntr_x_black_x_post","ntr_x_black_x_post"]) * sd_treatment / sd_log_earnings
se_sde_emp <- sqrt(vcov(models$m_emp)["ntr_x_black_x_post","ntr_x_black_x_post"]) * sd_treatment / sd_log_emp
se_sde_hires <- sqrt(vcov(models$m_hire)["ntr_x_black_x_post","ntr_x_black_x_post"]) * sd_treatment / sd_log_hires
se_sde_sep <- sqrt(vcov(models$m_sep)["ntr_x_black_x_post","ntr_x_black_x_post"]) * sd_treatment / sd_log_sep

# Classification function
classify_sde <- function(x) {
  abs_x <- abs(x)
  if (abs_x < 0.005) return("Null")
  if (abs_x < 0.05) {
    if (x > 0) return("Small positive") else return("Small negative")
  }
  if (abs_x < 0.15) {
    if (x > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (x > 0) return("Large positive") else return("Large negative")
}

sde_data <- tibble(
  Outcome = c("Log Monthly Earnings", "Log Employment", "Log Hires", "Log Separations"),
  beta = c(coef(models$m3_saturated)["ntr_x_black_x_post"],
           coef(models$m_emp)["ntr_x_black_x_post"],
           coef(models$m_hire)["ntr_x_black_x_post"],
           coef(models$m_sep)["ntr_x_black_x_post"]),
  se = c(sqrt(vcov(models$m3_saturated)["ntr_x_black_x_post","ntr_x_black_x_post"]),
         sqrt(vcov(models$m_emp)["ntr_x_black_x_post","ntr_x_black_x_post"]),
         sqrt(vcov(models$m_hire)["ntr_x_black_x_post","ntr_x_black_x_post"]),
         sqrt(vcov(models$m_sep)["ntr_x_black_x_post","ntr_x_black_x_post"])),
  sd_y = c(sd_log_earnings, sd_log_emp, sd_log_hires, sd_log_sep),
  sde = c(sde_earnings, sde_emp, sde_hires, sde_sep),
  se_sde = c(se_sde_earnings, se_sde_emp, se_sde_hires, se_sde_sep)
) %>%
  mutate(classification = sapply(sde, classify_sde))

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the elimination of trade policy uncertainty via PNTR (2000) ",
  "disproportionately reduce Black workers' earnings relative to White workers in exposed U.S. manufacturing industries? ",
  "\\textbf{Policy mechanism:} PNTR removed the annual congressional threat of tariff reversion to Smoot-Hawley rates ",
  "for Chinese imports, eliminating an uncertainty premium that had insulated domestic manufacturing; industries with ",
  "larger gaps between Smoot-Hawley and NTR rates faced sharper import competition, and Black workers were ",
  "over-represented in these high-exposure sectors due to historical occupational segregation. ",
  "\\textbf{Outcome definition:} Log average monthly earnings from QWI, measured at the county-industry-quarter-race cell. ",
  "\\textbf{Treatment:} Continuous; industry-level NTR gap (Smoot-Hawley rate minus NTR rate) interacted with ",
  "Black worker indicator and post-2000 period indicator. ",
  "\\textbf{Data:} QWI race $\\times$ industry panel (Azure), 1995--2010, county $\\times$ NAICS3 $\\times$ quarter $\\times$ race, ",
  format(diagnostics$n_obs, big.mark = ","), " observations across ", diagnostics$n_counties, " counties. ",
  "\\textbf{Method:} Triple difference (NTR gap $\\times$ Black $\\times$ Post) with county$\\times$industry, ",
  "county$\\times$quarter, and industry$\\times$quarter fixed effects; standard errors clustered by state. ",
  "\\textbf{Sample:} Manufacturing industries (NAICS 31--33) in counties with both Black and White manufacturing employment; ",
  "restricted to 1995--2010 to capture the PNTR adjustment decade. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of the ",
  "NTR Gap $\\times$ Black interaction and SD($Y$) is the pre-treatment standard deviation of each outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build LaTeX table
sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: PNTR Trade Shock on Racial Manufacturing Earnings Gap}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_data))) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %s & (%s) & %s & %s & (%s) & %s \\\\",
            sde_data$Outcome[i],
            format(round(sde_data$beta[i], 4), nsmall = 4),
            format(round(sde_data$se[i], 4), nsmall = 4),
            format(round(sde_data$sd_y[i], 3), nsmall = 3),
            format(round(sde_data$sde[i], 4), nsmall = 4),
            format(round(sde_data$se_sde[i], 4), nsmall = 4),
            sde_data$classification[i]))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("SDE table written.\n")

cat("\n=== ALL TABLES COMPLETE ===\n")
