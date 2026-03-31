## 05_tables.R — Generate all LaTeX tables
## apep_1220: Denmark Property Tax Reform and Housing Market Lock-in

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
dose <- readRDS(file.path(data_dir, "treatment_dose.rds"))
main_results <- readRDS(file.path(data_dir, "main_results.rds"))
robust_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

analysis <- panel %>%
  filter(year >= 2016, year <= 2025) %>%
  filter(!is.na(dose_pct_change)) %>%
  filter(!is.na(total_property_tax_1000kr))

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("=== Table 1: Summary Statistics ===\n")

pre <- panel %>%
  filter(year >= 2016, year <= 2023, !is.na(dose_pct_change))
post <- panel %>%
  filter(year >= 2024, year <= 2025, !is.na(dose_pct_change))

sum_stats <- function(df, varname, label) {
  x <- df[[varname]]
  x <- x[!is.na(x)]
  sprintf("  %s & %.1f & %.1f & %.0f & %.0f & %d",
          label, mean(x), sd(x), min(x), max(x), length(x))
}

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Danish Municipalities, 2016--2025}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "  & Mean & SD & Min & Max & N \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Pre-reform period (2016--2023)}} \\\\[3pt]",
  sum_stats(pre, "grundskyld_promille", "Grundskyld rate (\\textperthousand)"),
  " \\\\",
  sum_stats(pre, "total_property_tax_1000kr", "Total property tax (1000 DKK)"),
  " \\\\",
  sum_stats(pre, "total_assessment_mio", "Property assessment (million DKK)"),
  " \\\\",
  sum_stats(pre, "forced_sales", "Forced sales (annual)"),
  " \\\\[6pt]",
  "\\multicolumn{6}{l}{\\textit{Panel B: Post-reform period (2024--2025)}} \\\\[3pt]",
  sum_stats(post, "grundskyld_promille", "Grundskyld rate (\\textperthousand)"),
  " \\\\",
  sum_stats(post, "total_property_tax_1000kr", "Total property tax (1000 DKK)"),
  " \\\\",
  sum_stats(post, "total_assessment_mio", "Property assessment (million DKK)"),
  " \\\\",
  sum_stats(post, "forced_sales", "Forced sales (annual)"),
  " \\\\[6pt]",
  "\\multicolumn{6}{l}{\\textit{Panel C: Treatment dose (percentage change in grundskyld, 2023--2024)}} \\\\[3pt]",
  sprintf("  Dose (pct change) & %.1f & %.1f & %.1f & %.1f & %d \\\\",
          mean(dose$dose_pct_change, na.rm=T),
          sd(dose$dose_pct_change, na.rm=T),
          min(dose$dose_pct_change, na.rm=T),
          max(dose$dose_pct_change, na.rm=T),
          sum(!is.na(dose$dose_pct_change))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from Statistics Denmark (api.statbank.dk). Unit of observation: municipality-year. 98 municipalities observed 2016--2025 (10 years). Grundskyld is the Danish municipal land value tax, expressed in per mille (\\textperthousand) of assessed land value. Treatment dose is the percentage change in the grundskyld rate from 2023 to 2024 under the Boligskattereform. All municipalities experienced rate reductions (negative dose), ranging from $-87.5\\%$ (Frederiksberg) to $-32.3\\%$ (Struer).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("  Written tab1_summary.tex\n")

# ============================================================
# Table 2: Main results — Dose-Response DiD
# ============================================================

cat("=== Table 2: Main Results ===\n")

# Re-estimate models for clean table
m1 <- feols(log_total_tax ~ dose_pct_change:post |
              municipality + year, data = analysis,
            cluster = ~municipality)

m2 <- feols(log_assessment ~ dose_pct_change:post |
              municipality + year, data = analysis,
            cluster = ~municipality)

m3 <- feols(forced_sales ~ dose_pct_change:post |
              municipality + year,
            data = panel %>%
              filter(year >= 2016, year <= 2025,
                     !is.na(dose_pct_change), !is.na(forced_sales)),
            cluster = ~municipality)

m4 <- feols(grundskyld_promille ~ dose_pct_change:post |
              municipality + year, data = analysis,
            cluster = ~municipality)

# Extract coefficients manually for precise control
extract_coef <- function(m) {
  s <- summary(m)
  coefs <- s$coeftable
  row <- grep("dose_pct_change:post|post:dose_pct_change", rownames(coefs))
  if (length(row) == 0) row <- 1
  list(
    beta = coefs[row, "Estimate"],
    se = coefs[row, "Std. Error"],
    p = coefs[row, "Pr(>|t|)"],
    stars = ifelse(coefs[row, "Pr(>|t|)"] < 0.01, "***",
                   ifelse(coefs[row, "Pr(>|t|)"] < 0.05, "**",
                          ifelse(coefs[row, "Pr(>|t|)"] < 0.1, "*", ""))),
    n = s$nobs,
    r2 = fitstat(m, "wr2")[[1]]
  )
}

c1 <- extract_coef(m1)
c2 <- extract_coef(m2)
c3 <- extract_coef(m3)
c4 <- extract_coef(m4)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Property Tax Reform and Municipality Outcomes: Dose-Response DiD}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "  & (1) & (2) & (3) & (4) \\\\",
  "  & Log Tax & Log Assessment & Forced Sales & Grundskyld \\\\",
  "  & Revenue & Value & (Level) & Rate (\\textperthousand) \\\\",
  "\\midrule",
  sprintf("  Dose $\\times$ Post & %.4f%s & %.4f%s & %.3f%s & %.3f%s \\\\",
          c1$beta, c1$stars, c2$beta, c2$stars,
          c3$beta, c3$stars, c4$beta, c4$stars),
  sprintf("  & (%.4f) & (%.4f) & (%.3f) & (%.3f) \\\\[6pt]",
          c1$se, c2$se, c3$se, c4$se),
  "  Municipality FE & Yes & Yes & Yes & Yes \\\\",
  "  Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("  Observations & %d & %d & %d & %d \\\\",
          c1$n, c2$n, c3$n, c4$n),
  sprintf("  Within $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          c1$r2, c2$r2, c3$r2, c4$r2),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports a separate OLS regression. The treatment variable (Dose) is the percentage change in the municipality's grundskyld rate from 2023 to 2024, interacted with a post-reform indicator ($\\geq 2024$). All specifications include municipality and year fixed effects. Standard errors clustered at the municipality level in parentheses. Sample: 98 Danish municipalities, 2016--2025. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
cat("  Written tab2_main.tex\n")

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================

cat("=== Table 3: Event Study ===\n")

es_tax <- main_results$es_tax
es_fs <- main_results$es_forced

# Extract event study coefficients
es_tax_coefs <- summary(es_tax)$coeftable
es_fs_coefs <- summary(es_fs)$coeftable

# Build table rows
event_times <- c(-7, -6, -5, -4, -3, -2, 0, 1)
event_labels <- c("$t-7$", "$t-6$", "$t-5$", "$t-4$", "$t-3$", "$t-2$",
                   "$t=0$", "$t+1$")

tab3_rows <- character()
for (i in seq_along(event_times)) {
  et <- event_times[i]
  lab <- event_labels[i]
  # Find matching row
  tax_row <- grep(sprintf("::%d:", et), rownames(es_tax_coefs))
  fs_row <- grep(sprintf("::%d:", et), rownames(es_fs_coefs))

  if (length(tax_row) == 1 && length(fs_row) == 1) {
    tax_b <- es_tax_coefs[tax_row, "Estimate"]
    tax_se <- es_tax_coefs[tax_row, "Std. Error"]
    tax_p <- es_tax_coefs[tax_row, "Pr(>|t|)"]
    tax_stars <- ifelse(tax_p < 0.01, "***", ifelse(tax_p < 0.05, "**",
                        ifelse(tax_p < 0.1, "*", "")))

    fs_b <- es_fs_coefs[fs_row, "Estimate"]
    fs_se <- es_fs_coefs[fs_row, "Std. Error"]
    fs_p <- es_fs_coefs[fs_row, "Pr(>|t|)"]
    fs_stars <- ifelse(fs_p < 0.01, "***", ifelse(fs_p < 0.05, "**",
                       ifelse(fs_p < 0.1, "*", "")))

    tab3_rows <- c(tab3_rows,
      sprintf("  %s & %.4f%s & %.3f%s \\\\", lab,
              tax_b, tax_stars, fs_b, fs_stars),
      sprintf("  & (%.4f) & (%.3f) \\\\", tax_se, fs_se))
  }
}

# Add reference year
ref_idx <- which(event_labels == "$t=0$")
tab3_rows <- c(
  tab3_rows[1:(2*(ref_idx-1))],
  "  $t-1$ (ref.) & --- & --- \\\\[3pt]",
  tab3_rows[(2*(ref_idx-1)+1):length(tab3_rows)]
)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Dose-Response Coefficients by Year}",
  "\\label{tab:eventstudy}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "  & (1) & (2) \\\\",
  "  Event Time & Log Tax Revenue & Forced Sales \\\\",
  "\\midrule",
  tab3_rows,
  "\\midrule",
  sprintf("  Observations & %d & %d \\\\", es_tax$nobs, es_fs$nobs),
  "  Municipality FE & Yes & Yes \\\\",
  "  Year FE & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each cell reports the coefficient on (Dose $\\times$ event-time indicator). Dose is the percentage change in grundskyld rate from 2023 to 2024. Reference year: $t-1$ (2023). Endpoints binned: $t-7$ includes 2016 and earlier; $t+1$ includes 2025 and later. Standard errors clustered by municipality in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_eventstudy.tex"))
cat("  Written tab3_eventstudy.tex\n")

# ============================================================
# Table 4: Robustness
# ============================================================

cat("=== Table 4: Robustness ===\n")

c_abs <- extract_coef(robust_results$m_abs)
c_short <- extract_coef(robust_results$m_short)
c_long <- extract_coef(robust_results$m_long)
c_placebo <- extract_coef(robust_results$m_placebo_tax)
c_terc <- extract_coef(robust_results$m_tercile_tax)

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Log Tax Revenue Under Alternative Specifications}",
  "\\label{tab:robust}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "  & (1) & (2) & (3) & (4) & (5) \\\\",
  "  & Absolute & Short & Long & Placebo & Tercile \\\\",
  "  & Dose & Window & Window & 2020 & Top vs. \\\\",
  "  & & (2020--25) & (2007--25) & & Bottom \\\\",
  "\\midrule",
  sprintf("  Treatment $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s & %.3f%s \\\\",
          c_abs$beta, c_abs$stars, c_short$beta, c_short$stars,
          c_long$beta, c_long$stars, c_placebo$beta, c_placebo$stars,
          c_terc$beta, c_terc$stars),
  sprintf("  & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.3f) \\\\[6pt]",
          c_abs$se, c_short$se, c_long$se, c_placebo$se, c_terc$se),
  "  Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "  Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("  Observations & %d & %d & %d & %d & %d \\\\",
          c_abs$n, c_short$n, c_long$n, c_placebo$n, c_terc$n),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications use log total property tax revenue as the dependent variable with municipality and year fixed effects. Column 1: treatment is the absolute change in grundskyld rate (promille). Columns 2--3: vary the pre-period window. Column 4: placebo reform at 2020, estimated on pre-reform data only (2016--2023). Column 5: binary comparison of top tercile (biggest cuts) vs. bottom tercile (smallest cuts). Standard errors clustered by municipality. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robust.tex"))
cat("  Written tab4_robust.tex\n")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE) — Appendix
# ============================================================

cat("=== Table F1: SDE Appendix ===\n")

# Compute SDEs for main outcomes
pre_analysis <- panel %>%
  filter(year >= 2016, year < 2024, !is.na(dose_pct_change))

# SD of outcomes in pre-period
sd_log_tax <- sd(pre_analysis$log_total_tax, na.rm = TRUE)
sd_log_assess <- sd(pre_analysis$log_assessment, na.rm = TRUE)
sd_forced <- sd(pre_analysis$forced_sales, na.rm = TRUE)
sd_rate <- sd(pre_analysis$grundskyld_promille, na.rm = TRUE)

# SD of treatment dose
sd_dose <- sd(dose$dose_pct_change, na.rm = TRUE)

# Continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_tax <- c1$beta * sd_dose / sd_log_tax
sde_tax_se <- c1$se * sd_dose / sd_log_tax

sde_assess <- c2$beta * sd_dose / sd_log_assess
sde_assess_se <- c2$se * sd_dose / sd_log_assess

sde_forced <- c3$beta * sd_dose / sd_forced
sde_forced_se <- c3$se * sd_dose / sd_forced

sde_rate <- c4$beta * sd_dose / sd_rate
sde_rate_se <- c4$se * sd_dose / sd_rate

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Heterogeneity: high-dose vs low-dose municipalities
dose_median <- median(dose$dose_pct_change, na.rm = TRUE)
panel_het <- panel %>%
  filter(year >= 2016, year <= 2025, !is.na(dose_pct_change)) %>%
  mutate(high_dose_grp = dose_pct_change < dose_median)

# High-dose group
high_data <- panel_het %>% filter(high_dose_grp == TRUE, !is.na(total_property_tax_1000kr))
m_high <- feols(log_total_tax ~ dose_pct_change:post | municipality + year,
                data = high_data, cluster = ~municipality)
c_high <- extract_coef(m_high)
sd_tax_high <- sd(high_data$log_total_tax[high_data$year < 2024], na.rm = TRUE)
sd_dose_high <- sd(dose$dose_pct_change[dose$dose_pct_change < dose_median], na.rm = TRUE)
sde_high <- c_high$beta * sd_dose_high / sd_tax_high
sde_high_se <- c_high$se * sd_dose_high / sd_tax_high

# Low-dose group
low_data <- panel_het %>% filter(high_dose_grp == FALSE, !is.na(total_property_tax_1000kr))
m_low <- feols(log_total_tax ~ dose_pct_change:post | municipality + year,
               data = low_data, cluster = ~municipality)
c_low <- extract_coef(m_low)
sd_tax_low <- sd(low_data$log_total_tax[low_data$year < 2024], na.rm = TRUE)
sd_dose_low <- sd(dose$dose_pct_change[dose$dose_pct_change >= dose_median], na.rm = TRUE)
sde_low <- c_low$beta * sd_dose_low / sd_tax_low
sde_low_se <- c_low$se * sd_dose_low / sd_tax_low

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Denmark. ",
  "\\textbf{Research question:} Does the 2024 Boligskattereform's municipality-varying grundskyld rate reductions affect property tax revenue, assessed values, and forced sales across 98 Danish municipalities? ",
  "\\textbf{Policy mechanism:} The reform simultaneously reassessed all properties using 2022 valuations, slashed grundskyld rates by 32--88\\%, and introduced a permanent tax-freeze loan for incumbents that resets upon sale, creating municipality-varying wedges in effective tax burdens. ",
  "\\textbf{Outcome definition:} Log total municipal property tax revenue (1000 DKK), log property assessment value (million DKK), annual count of forced property sales, and grundskyld rate (per mille of assessed land value). ",
  "\\textbf{Treatment:} Continuous; percentage change in municipality grundskyld rate from 2023 to 2024, ranging from $-87.5\\%$ to $-32.3\\%$. ",
  "\\textbf{Data:} Statistics Denmark open API (api.statbank.dk), tables EJDSK2, ESKAT, TVANG3; 98 municipalities, 2016--2025, 980 municipality-year observations. ",
  "\\textbf{Method:} Dose-response difference-in-differences with municipality and year fixed effects; standard errors clustered by municipality. ",
  "\\textbf{Sample:} All 98 Danish municipalities with complete grundskyld rate data 2016--2025; excludes regional and national aggregates. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-municipality standard deviation of the dose and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "  Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("  Log tax revenue & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          c1$beta, c1$se, sd_log_tax, sde_tax, sde_tax_se, classify_sde(sde_tax)),
  sprintf("  Log assessment & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          c2$beta, c2$se, sd_log_assess, sde_assess, sde_assess_se, classify_sde(sde_assess)),
  sprintf("  Forced sales & %.3f & %.3f & %.1f & %.3f & %.3f & %s \\\\",
          c3$beta, c3$se, sd_forced, sde_forced, sde_forced_se, classify_sde(sde_forced)),
  sprintf("  Grundskyld rate & %.3f & %.3f & %.1f & %.3f & %.3f & %s \\\\[6pt]",
          c4$beta, c4$se, sd_rate, sde_rate, sde_rate_se, classify_sde(sde_rate)),
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by dose intensity)}} \\\\[3pt]",
  sprintf("  Log tax (high-dose munis) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          c_high$beta, c_high$se, sd_tax_high, sde_high, sde_high_se, classify_sde(sde_high)),
  sprintf("  Log tax (low-dose munis) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          c_low$beta, c_low$se, sd_tax_low, sde_low, sde_low_se, classify_sde(sde_low)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat(sprintf("\nSDE values: tax=%.3f, assess=%.3f, forced=%.3f, rate=%.3f\n",
            sde_tax, sde_assess, sde_forced, sde_rate))

# ============================================================
# List generated tables
# ============================================================

cat("\n=== All tables generated ===\n")
tab_files <- list.files(tables_dir, pattern = "\\.tex$")
for (f in tab_files) {
  cat(sprintf("  %s\n", f))
}

cat("\nTable generation complete.\n")
