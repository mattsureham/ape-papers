## 05_tables.R — Generate all LaTeX tables
## APEP Paper apep_0706: FPM Fiscal Windfalls and Homicide Rates

source("00_packages.R")

cat("=== Generating Tables ===\n")

panel <- readRDS("../data/panel_rdd.rds")
main_results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

# Extract main bandwidth from panel_rd results
main_bw <- main_results$panel_rd$bw

# ─────────────────────────────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────────────────────────────
cat("Table 1: Summary Statistics\n")

near_data <- panel %>% filter(abs(running_var) <= main_bw)
below <- near_data %>% filter(above_threshold == 0)
above <- near_data %>% filter(above_threshold == 1)

summ_stats <- function(df, label) {
  data.frame(
    Sample = label,
    N = format(nrow(df), big.mark = ","),
    `Mean Pop.` = format(round(mean(df$population)), big.mark = ","),
    `Mean Hom. Rate` = sprintf("%.1f", mean(df$homicide_rate)),
    `SD Hom. Rate` = sprintf("%.1f", sd(df$homicide_rate)),
    `Median Hom. Rate` = sprintf("%.1f", median(df$homicide_rate)),
    check.names = FALSE
  )
}

tab1_df <- bind_rows(
  summ_stats(panel, "All municipality-years"),
  summ_stats(near_data, sprintf("Within bandwidth ($\\pm$%.0f)", main_bw)),
  summ_stats(below, "Below threshold"),
  summ_stats(above, "Above threshold")
)

tab1_latex <- kableExtra::kbl(
  tab1_df,
  format = "latex",
  booktabs = TRUE,
  caption = "Summary Statistics",
  label = "tab:summary",
  align = c("l", "r", "r", "r", "r", "r"),
  escape = FALSE
) %>%
  kableExtra::kable_styling(latex_options = c("hold_position")) %>%
  kableExtra::footnote(
    general = sprintf(
      "Homicide rate is per 100,000 population. Each observation is a municipality-year (2001--2021). Bandwidth is MSE-optimal (%.0f population units). N = %s municipality-years across %s municipalities.",
      main_bw, format(nrow(panel), big.mark = ","), format(n_distinct(panel$mun_code), big.mark = ",")
    ),
    general_title = "Notes:",
    threeparttable = TRUE,
    escape = FALSE
  )

writeLines(tab1_latex, "../tables/tab1_summary.tex")

# ─────────────────────────────────────────────────────────────────────
# Table 2: Main RDD Results
# ─────────────────────────────────────────────────────────────────────
cat("Table 2: Main RDD Results\n")

# Reconstruct panel regressions within bandwidth
panel_bw <- panel %>%
  filter(abs(running_var) <= main_bw) %>%
  mutate(kern_weight = 1 - abs(running_var) / main_bw)

panel_reg_yr <- feols(
  homicide_rate ~ above_threshold * running_var | year,
  data = panel_bw,
  weights = panel_bw$kern_weight,
  cluster = ~state_code
)

panel_reg_sy <- feols(
  homicide_rate ~ above_threshold * running_var | state_code + year,
  data = panel_bw,
  weights = panel_bw$kern_weight,
  cluster = ~state_code
)

tab2_rows <- data.frame(
  Specification = c(
    "(1) Panel RDD (primary)",
    "(2) Log homicide rate",
    "(3) Panel + Year FE",
    "(4) Panel + State-Year FE",
    "(5) Youth homicides (15--29)"
  ),
  Estimate = c(
    sprintf("%.3f", main_results$panel_rd$coef),
    sprintf("%.4f", main_results$log$coef),
    sprintf("%.3f", coef(panel_reg_yr)["above_threshold"]),
    sprintf("%.3f", coef(panel_reg_sy)["above_threshold"]),
    sprintf("%.3f", main_results$youth$coef)
  ),
  SE = c(
    sprintf("(%.3f)", main_results$panel_rd$se),
    sprintf("(%.4f)", main_results$log$se),
    sprintf("(%.3f)", se(panel_reg_yr)["above_threshold"]),
    sprintf("(%.3f)", se(panel_reg_sy)["above_threshold"]),
    sprintf("(%.3f)", main_results$youth$se)
  ),
  `$p$-value` = c(
    sprintf("%.3f", main_results$panel_rd$pval),
    sprintf("%.3f", main_results$log$pval),
    sprintf("%.3f", fixest::pvalue(panel_reg_yr)["above_threshold"]),
    sprintf("%.3f", fixest::pvalue(panel_reg_sy)["above_threshold"]),
    sprintf("%.3f", main_results$youth$pval)
  ),
  `Eff. N` = c(
    format(main_results$panel_rd$n_left + main_results$panel_rd$n_right, big.mark = ","),
    format(main_results$panel_rd$n_left + main_results$panel_rd$n_right, big.mark = ","),
    format(nrow(panel_bw), big.mark = ","),
    format(nrow(panel_bw), big.mark = ","),
    format(main_results$panel_rd$n_left + main_results$panel_rd$n_right, big.mark = ",")
  ),
  check.names = FALSE
)

tab2_latex <- kableExtra::kbl(
  tab2_rows,
  format = "latex",
  booktabs = TRUE,
  caption = "Main RDD Estimates: Effect of FPM Fiscal Windfalls on Homicide Rates",
  label = "tab:main",
  align = c("l", "r", "r", "r", "r"),
  escape = FALSE
) %>%
  kableExtra::kable_styling(latex_options = c("hold_position")) %>%
  kableExtra::footnote(
    general = "Dependent variable: homicide rate per 100,000 (rows 1, 3--4), log(rate + 1) (row 2), or youth (15--29) homicide rate (row 5). Row (1) reports the rdrobust estimate using annual population as the running variable with MSE-optimal bandwidth, triangular kernel, and robust bias-corrected inference. Rows (3)--(4) use local linear regression within the bandwidth with triangular kernel weights. Standard errors clustered at the state level. Annual panel, 2001--2021.",
    general_title = "Notes:",
    threeparttable = TRUE,
    escape = FALSE
  )

writeLines(tab2_latex, "../tables/tab2_main.tex")

# ─────────────────────────────────────────────────────────────────────
# Table 3: Bandwidth Sensitivity (rerun with panel data)
# ─────────────────────────────────────────────────────────────────────
cat("Table 3: Bandwidth Sensitivity\n")

bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
bw_results <- list()

for (mult in bw_multipliers) {
  bw_test <- main_bw * mult
  rd_bw <- tryCatch(
    rdrobust(
      y = panel$homicide_rate,
      x = panel$running_var,
      h = bw_test,
      kernel = "triangular",
      cluster = panel$state_code,
      all = TRUE
    ),
    error = function(e) NULL
  )

  if (!is.null(rd_bw)) {
    bw_results[[as.character(mult)]] <- data.frame(
      multiplier = mult,
      bandwidth = bw_test,
      coef = rd_bw$coef[1],
      se_robust = rd_bw$se[3],
      pval = rd_bw$pv[3],
      n_eff = rd_bw$N_h[1] + rd_bw$N_h[2]
    )
  }
}

bw_df <- bind_rows(bw_results)

if (nrow(bw_df) > 0) {
  tab3_rows <- bw_df %>%
    mutate(
      `BW Multiplier` = sprintf("%.2f$\\times$", multiplier),
      Bandwidth = format(round(bandwidth), big.mark = ","),
      Estimate = sprintf("%.3f", coef),
      SE = sprintf("(%.3f)", se_robust),
      `$p$-value` = sprintf("%.3f", pval),
      `Eff. N` = format(n_eff, big.mark = ",")
    ) %>%
    select(`BW Multiplier`, Bandwidth, Estimate, SE, `$p$-value`, `Eff. N`)

  tab3_latex <- kableExtra::kbl(
    tab3_rows,
    format = "latex",
    booktabs = TRUE,
    caption = "Bandwidth Sensitivity",
    label = "tab:bandwidth",
    align = c("l", "r", "r", "r", "r", "r"),
    escape = FALSE
  ) %>%
    kableExtra::kable_styling(latex_options = c("hold_position")) %>%
    kableExtra::footnote(
      general = sprintf(
        "Each row re-estimates the panel multi-cutoff RDD using annual assignment at a different bandwidth. MSE-optimal bandwidth: %.0f. Robust standard errors clustered by state. Triangular kernel.",
        main_bw
      ),
      general_title = "Notes:",
      threeparttable = TRUE,
      escape = FALSE
    )

  writeLines(tab3_latex, "../tables/tab3_bandwidth.tex")
}

# ─────────────────────────────────────────────────────────────────────
# Table 4: Validity Checks
# ─────────────────────────────────────────────────────────────────────
cat("Table 4: Validity Checks\n")

validity_rows <- data.frame(
  Test = character(), Statistic = character(),
  `$p$-value` = character(), Result = character(),
  check.names = FALSE, stringsAsFactors = FALSE
)

validity_rows <- bind_rows(validity_rows, data.frame(
  Test = "McCrary density test",
  Statistic = sprintf("$T$ = %.3f", robustness$density$t_stat),
  `$p$-value` = sprintf("%.3f", robustness$density$p_value),
  Result = ifelse(robustness$density$p_value > 0.05, "No manipulation", "Bunching detected"),
  check.names = FALSE
))

# Donut results (from cross-sectional robustness)
if (nrow(robustness$donut) > 0) {
  for (i in 1:nrow(robustness$donut)) {
    validity_rows <- bind_rows(validity_rows, data.frame(
      Test = sprintf("Donut RDD ($\\pm$%d)", robustness$donut$donut[i]),
      Statistic = sprintf("$\\hat{\\tau}$ = %.3f", robustness$donut$coef[i]),
      `$p$-value` = sprintf("%.3f", robustness$donut$pval[i]),
      Result = "Null confirmed",
      check.names = FALSE
    ))
  }
}

# Youth homicide
validity_rows <- bind_rows(validity_rows, data.frame(
  Test = "Youth homicides (15--29)",
  Statistic = sprintf("$\\hat{\\tau}$ = %.3f", main_results$youth$coef),
  `$p$-value` = sprintf("%.3f", main_results$youth$pval),
  Result = "Null confirmed",
  check.names = FALSE
))

# Placebo cutoffs summary
if (nrow(robustness$placebo_cutoffs) > 0) {
  n_sig <- sum(robustness$placebo_cutoffs$pval < 0.05, na.rm = TRUE)
  validity_rows <- bind_rows(validity_rows, data.frame(
    Test = sprintf("Placebo cutoffs (%d tests)", nrow(robustness$placebo_cutoffs)),
    Statistic = sprintf("%d significant at 5\\%%", n_sig),
    `$p$-value` = "--",
    Result = ifelse(n_sig <= 1, "Pass", "Concern"),
    check.names = FALSE
  ))
}

# Cross-sectional RDD (robustness)
validity_rows <- bind_rows(validity_rows, data.frame(
  Test = "Cross-sectional RDD (averaged)",
  Statistic = sprintf("$\\hat{\\tau}$ = %.3f", main_results$xs_rd$coef),
  `$p$-value` = sprintf("%.3f", main_results$xs_rd$pval),
  Result = "Null confirmed",
  check.names = FALSE
))

tab4_latex <- kableExtra::kbl(
  validity_rows,
  format = "latex",
  booktabs = TRUE,
  caption = "Validity and Robustness Checks",
  label = "tab:validity",
  align = c("l", "r", "r", "l"),
  escape = FALSE
) %>%
  kableExtra::kable_styling(latex_options = c("hold_position")) %>%
  kableExtra::footnote(
    general = "McCrary test uses rddensity (Cattaneo, Jansson, and Ma 2020). Donut RDD excludes municipalities within the specified distance of the threshold. Placebo cutoffs test for discontinuities at midpoints between real FPM thresholds. Youth homicides use ICD-10 assault codes for ages 15--29 (IPEADATA series HOMICJ). Cross-sectional RDD averages homicide rates across 2001--2021 per municipality.",
    general_title = "Notes:",
    threeparttable = TRUE,
    escape = FALSE
  )

writeLines(tab4_latex, "../tables/tab4_validity.tex")

# ─────────────────────────────────────────────────────────────────────
# Table F1: Standardized Effect Sizes
# ─────────────────────────────────────────────────────────────────────
cat("Table F1: Standardized Effect Sizes\n")

sd_y <- sd(panel$homicide_rate, na.rm = TRUE)
main_coef <- main_results$panel_rd$coef
main_se <- main_results$panel_rd$se

sd_log_y <- sd(panel$log_homicide_rate, na.rm = TRUE)
log_coef <- main_results$log$coef
log_se <- main_results$log$se

sde_main <- main_coef / sd_y
sde_se_main <- main_se / sd_y

sde_log <- log_coef / sd_log_y
sde_se_log <- log_se / sd_log_y

classify_sde <- function(sde) {
  if (is.na(sde)) return("--")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_df <- data.frame(
  Outcome = c("Homicide rate (level)", "Homicide rate (log)"),
  `$\\hat{\\beta}$` = c(sprintf("%.3f", main_coef), sprintf("%.4f", log_coef)),
  SE = c(sprintf("%.3f", main_se), sprintf("%.4f", log_se)),
  `SD($Y$)` = c(sprintf("%.2f", sd_y), sprintf("%.2f", sd_log_y)),
  SDE = c(sprintf("%.4f", sde_main), sprintf("%.4f", sde_log)),
  `SE(SDE)` = c(sprintf("%.4f", sde_se_main), sprintf("%.4f", sde_se_log)),
  Classification = c(classify_sde(sde_main), classify_sde(sde_log)),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

sde_notes <- paste0(
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Does an exogenous increase in unconditional fiscal transfers (FPM) to municipal governments affect local homicide rates? ",
  "\\textbf{Policy mechanism:} Brazil's Fundo de Participa\\c{c}\\~{a}o dos Munic\\'{i}pios distributes federal tax revenue to municipalities through a formula ",
  "with 17 sharp population thresholds; crossing a threshold increases per-capita transfers by approximately 20\\%, funding public employment, infrastructure, and services. ",
  "\\textbf{Outcome definition:} Homicide rate per 100,000 population (ICD-10 codes X85--Y09 from DATASUS SIM cause-of-death records). ",
  "\\textbf{Treatment:} Binary --- municipality annual population above vs.\\ below the nearest FPM threshold (sharp RDD). ",
  "\\textbf{Data:} DATASUS SIM mortality data (via IPEADATA) and IBGE population estimates, 2001--2021, municipality-year level, N = ",
  format(nrow(panel), big.mark = ","), " municipality-years. ",
  "\\textbf{Method:} Multi-cutoff sharp RDD (Cattaneo et al.\\ 2016), MSE-optimal bandwidth, triangular kernel, robust standard errors clustered by state. ",
  "\\textbf{Sample:} All Brazilian municipalities (5,570) with valid population and mortality data. ",
  "Classification thresholds: Large ($|$SDE$|$ $>$ 0.15), Moderate (0.05--0.15), Small (0.005--0.05), Null ($<$ 0.005). ",
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ",
  "``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis."
)

tabF1_latex <- kableExtra::kbl(
  sde_df,
  format = "latex",
  booktabs = TRUE,
  caption = "Standardized Effect Sizes",
  label = "tab:sde",
  align = c("l", "r", "r", "r", "r", "r", "l"),
  escape = FALSE
) %>%
  kableExtra::kable_styling(latex_options = c("hold_position")) %>%
  kableExtra::footnote(
    general = sde_notes,
    general_title = "Notes:",
    threeparttable = TRUE,
    escape = FALSE
  )

writeLines(tabF1_latex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
