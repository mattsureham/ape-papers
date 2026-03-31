# 05_tables.R — Generate all LaTeX tables for paper
# apep_1192: Defect Queue Congestion

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_investigations.csv"))
load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

summ_vars <- data.table(
  Variable = c(
    "Investigation duration (days)",
    "Log duration",
    "Concurrent investigations (all)",
    "Concurrent investigations (other mfr.)",
    "Recall indicator",
    "Pre-period complaints",
    "Pre-period severity score",
    "Injuries during investigation",
    "Deaths during investigation",
    "Models covered"
  ),
  Mean = c(
    mean(df$duration_days), mean(df$log_duration),
    mean(df$concurrent_all), mean(df$concurrent_other_mfr),
    mean(df$has_recall), mean(df$comp_pre), mean(df$severity_pre),
    mean(df$injuries_during), mean(df$deaths_during), mean(df$n_models)
  ),
  SD = c(
    sd(df$duration_days), sd(df$log_duration),
    sd(df$concurrent_all), sd(df$concurrent_other_mfr),
    sd(df$has_recall), sd(df$comp_pre), sd(df$severity_pre),
    sd(df$injuries_during), sd(df$deaths_during), sd(df$n_models)
  ),
  Min = c(
    min(df$duration_days), min(df$log_duration),
    min(df$concurrent_all), min(df$concurrent_other_mfr),
    0, min(df$comp_pre), min(df$severity_pre),
    min(df$injuries_during), min(df$deaths_during), min(df$n_models)
  ),
  Max = c(
    max(df$duration_days), max(df$log_duration),
    max(df$concurrent_all), max(df$concurrent_other_mfr),
    1, max(df$comp_pre), max(df$severity_pre),
    max(df$injuries_during), max(df$deaths_during), max(df$n_models)
  )
)

# Format
summ_vars[, `:=`(
  Mean = sprintf("%.1f", Mean),
  SD = sprintf("%.1f", SD),
  Min = sprintf("%.0f", Min),
  Max = sprintf("%.0f", Max)
)]

# Build LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: NHTSA Safety Investigations, 2000--2024}",
  "\\label{tab:summ}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & SD & Min & Max \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(summ_vars))) {
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s & %s \\\\",
                                       summ_vars$Variable[i], summ_vars$Mean[i],
                                       summ_vars$SD[i], summ_vars$Min[i], summ_vars$Max[i]))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  sprintf("\\begin{tablenotes}[flushleft]"),
  sprintf("\\footnotesize"),
  sprintf("\\item \\textit{Notes:} Sample includes %s closed Preliminary Evaluation (PE) and Engineering Analysis (EA) investigations opened by NHTSA's Office of Defects Investigation between 2000 and 2024. Concurrent investigations count all PE/EA investigations open on the date the focal investigation was opened. Other-manufacturer concurrent investigations exclude investigations of the same manufacturer group. Pre-period complaints and severity scores are computed over the 12 months preceding investigation opening for the same manufacturer. Injuries and deaths are manufacturer-level complaint counts during the investigation period.", format(nrow(df), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tab_dir, "tab1_summ.tex"))

# ============================================================
# Table 2: Reduced Form — Queue Congestion → Duration & Recall
# ============================================================
cat("Generating Table 2: Reduced Form Results...\n")

# Re-estimate for clean table output
rf_dur_yr <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_year,
                   data = df, vcov = "hetero")

rf_rec_yr <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_year,
                   data = df, vcov = "hetero")

rf_dur_yq <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_yq,
                   data = df[!is.na(open_yq)], vcov = "hetero")

rf_rec_yq <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_yq,
                   data = df[!is.na(open_yq)], vcov = "hetero")

# Manufacturer-clustered versions
rf_dur_cl <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_year,
                   data = df, vcov = ~mfr_clean)

rf_rec_cl <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_year,
                   data = df, vcov = ~mfr_clean)

tab2_tex <- etable(rf_dur_yr, rf_dur_yq, rf_dur_cl,
                   rf_rec_yr, rf_rec_yq, rf_rec_cl,
                   tex = TRUE,
                   headers = c("Year FE", "Yr-Qtr FE", "Clustered",
                               "Year FE", "Yr-Qtr FE", "Clustered"),
                   title = "Reduced-Form Effects of Queue Congestion on Investigation Outcomes",
                   label = "tab:reduced_form",
                   fitstat = ~n + r2 + wr2,
                   keep = "%concurrent_other_mfr",
                   dict = c(concurrent_other_mfr = "Other-mfr. queue"))

writeLines(tab2_tex, file.path(tab_dir, "tab2_reduced_form.tex"))

# ============================================================
# Table 3: Heterogeneity — PE vs EA, Severity Placebo
# ============================================================
cat("Generating Table 3: Heterogeneity...\n")

df_pe <- df[inv_type == "PE"]
df_ea <- df[inv_type == "EA"]
sev_q75 <- quantile(df$severity_pre, 0.75)
df_low <- df[severity_pre < sev_q75]
df_high <- df[severity_pre >= sev_q75]

het_pe <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                  n_models + mfr_inv_count | comp_cat + open_year,
                data = df_pe, vcov = "hetero")

het_ea <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                  n_models + mfr_inv_count | comp_cat + open_year,
                data = df_ea, vcov = "hetero")

het_low <- feols(has_recall ~ concurrent_other_mfr + comp_pre +
                   n_models + mfr_inv_count | comp_cat + open_year,
                 data = df_low, vcov = "hetero")

het_high <- feols(has_recall ~ concurrent_other_mfr + comp_pre +
                    n_models + mfr_inv_count | comp_cat + open_year,
                  data = df_high, vcov = "hetero")

# Duration heterogeneity
het_pe_d <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                    n_models + mfr_inv_count | comp_cat + open_year,
                  data = df_pe, vcov = "hetero")

het_ea_d <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                    n_models + mfr_inv_count | comp_cat + open_year,
                  data = df_ea, vcov = "hetero")

tab3_tex <- etable(het_pe, het_ea, het_low, het_high,
                   het_pe_d, het_ea_d,
                   tex = TRUE,
                   headers = c("PE", "EA", "Low Sev.", "High Sev.", "PE", "EA"),
                   title = "Heterogeneity: Investigation Type and Defect Severity",
                   label = "tab:heterogeneity",
                   fitstat = ~n + r2,
                   keep = "%concurrent_other_mfr",
                   dict = c(concurrent_other_mfr = "Other-mfr. queue"))

writeLines(tab3_tex, file.path(tab_dir, "tab3_heterogeneity.tex"))

# ============================================================
# Table 4: Leave-One-Out Robustness
# ============================================================
cat("Generating Table 4: Leave-One-Out...\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Leave-One-Out Manufacturer Robustness}",
  "\\label{tab:loo}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Log Duration} & \\multicolumn{2}{c}{Recall Prob.} & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Manufacturer Dropped & Coeff. & SE & Coeff. & SE & $N$ \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(loo_results))) {
  tab4_lines <- c(tab4_lines, sprintf("%s & %.4f & (%.4f) & %.4f & (%.4f) & %s \\\\",
                                       loo_results$mfr_dropped[i],
                                       loo_results$rf_coef[i], loo_results$rf_se[i],
                                       loo_results$recall_coef[i], loo_results$recall_se[i],
                                       format(loo_results$n[i], big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  sprintf("Full Sample & %.4f & (%.4f) & %.4f & (%.4f) & %s \\\\",
          coef(rf_dur_yr)["concurrent_other_mfr"], se(rf_dur_yr)["concurrent_other_mfr"],
          coef(rf_rec_yr)["concurrent_other_mfr"], se(rf_rec_yr)["concurrent_other_mfr"],
          format(nrow(df), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each row re-estimates the reduced-form specification from Table~\\ref{tab:reduced_form} after dropping all investigations involving the named manufacturer group. All specifications include component category and year fixed effects, with heteroskedasticity-robust standard errors. Coefficient shown is on concurrent other-manufacturer investigations.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tab_dir, "tab4_loo.tex"))

# ============================================================
# Table 5 (Appendix): IV Estimates
# ============================================================
cat("Generating Table 5: IV Estimates...\n")

# First stage
fs_yr <- feols(concurrent_all ~ concurrent_other_mfr + comp_pre + severity_pre +
                 n_models + mfr_inv_count | comp_cat + open_year,
               data = df, vcov = "hetero")

iv_dur <- feols(log_duration ~ comp_pre + severity_pre + n_models + mfr_inv_count |
                  comp_cat + open_year |
                  concurrent_all ~ concurrent_other_mfr,
                data = df, vcov = "hetero")

iv_rec <- feols(has_recall ~ comp_pre + severity_pre + n_models + mfr_inv_count |
                  comp_cat + open_year |
                  concurrent_all ~ concurrent_other_mfr,
                data = df, vcov = "hetero")

tab5_tex <- etable(fs_yr, iv_dur, iv_rec,
                   tex = TRUE,
                   headers = c("First Stage", "2SLS: Duration", "2SLS: Recall"),
                   title = "Instrumental Variable Estimates: Queue Congestion and Investigation Outcomes",
                   label = "tab:iv",
                   fitstat = ~n + r2 + ivf,
                   dict = c(concurrent_other_mfr = "Other-mfr. queue",
                            concurrent_all = "Total queue (instrumented)",
                            fit_concurrent_all = "Total queue (instrumented)"))

writeLines(tab5_tex, file.path(tab_dir, "tab5_iv.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# ============================================================
cat("Generating Table F1: SDE...\n")

# Compute SDEs for key outcomes
sd_duration <- sd(df$log_duration)
sd_recall <- sd(df$has_recall)
sd_x <- sd(df$concurrent_other_mfr)

# Duration outcome
beta_dur <- coef(rf_dur_yr)["concurrent_other_mfr"]
se_dur <- se(rf_dur_yr)["concurrent_other_mfr"]
sde_dur <- beta_dur * sd_x / sd_duration
se_sde_dur <- se_dur * sd_x / sd_duration

# Recall outcome
beta_rec <- coef(rf_rec_yr)["concurrent_other_mfr"]
se_rec <- se(rf_rec_yr)["concurrent_other_mfr"]
sde_rec <- beta_rec * sd_x / sd_recall
se_sde_rec <- se_rec * sd_x / sd_recall

# PE-only recall
beta_pe <- coef(het_pe)["concurrent_other_mfr"]
se_pe <- se(het_pe)["concurrent_other_mfr"]
sd_recall_pe <- sd(df_pe$has_recall)
sde_pe <- beta_pe * sd_x / sd_recall_pe
se_sde_pe <- se_pe * sd_x / sd_recall_pe

# Low-severity recall
beta_low <- coef(het_low)["concurrent_other_mfr"]
se_low <- se(het_low)["concurrent_other_mfr"]
sd_recall_low <- sd(df_low$has_recall)
sde_low <- beta_low * sd_x / sd_recall_low
se_sde_low <- se_low * sd_x / sd_recall_low

# Classification function
classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does congestion in the NHTSA safety investigation queue --- ",
  "measured by concurrent open investigations at other manufacturers --- reduce the probability ",
  "that a new investigation results in a vehicle recall? ",
  "\\textbf{Policy mechanism:} NHTSA's Office of Defects Investigation operates with a fixed pool ",
  "of approximately 90 investigators responsible for 280+ million registered vehicles. When multiple ",
  "investigations are open simultaneously, each receives less examiner bandwidth, creating a triage ",
  "system where lower-profile defects are more likely to be closed without recall. ",
  "\\textbf{Outcome definition:} Binary recall indicator (1 if investigation led to a manufacturer recall ",
  "campaign, 0 otherwise); log investigation duration (days from opening to closure). ",
  "\\textbf{Treatment:} Continuous --- count of concurrent open PE/EA investigations at other ",
  "manufacturer groups on the date the focal investigation was opened (mean 38.1, SD 34.5). ",
  "\\textbf{Data:} NHTSA Office of Defects Investigation flat files (investigations, complaints, recalls), ",
  sprintf("2000--2024, investigation-level, %s observations. ", format(nrow(df), big.mark = ",")),
  "\\textbf{Method:} Reduced-form OLS with component category and year fixed effects; ",
  "heteroskedasticity-robust standard errors. ",
  "\\textbf{Sample:} Closed PE and EA investigations opened 2000--2024; excludes open investigations ",
  "and non-defect investigation types (AQ, RQ, CI). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional ",
  "standard deviation of the instrument and SD($Y$) is the unconditional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Recall probability & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s \\\\",
          beta_rec, se_rec, sd_recall, sde_rec, se_sde_rec, classify_sde(sde_rec)),
  sprintf("Log duration & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s \\\\",
          beta_dur, se_dur, sd_duration, sde_dur, se_sde_dur, classify_sde(sde_dur)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\[3pt]",
  sprintf("Recall prob. (PE only) & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s \\\\",
          beta_pe, se_pe, sd_recall_pe, sde_pe, se_sde_pe, classify_sde(sde_pe)),
  sprintf("Recall prob. (low severity) & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s \\\\",
          beta_low, se_low, sd_recall_low, sde_low, se_sde_low, classify_sde(sde_low)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tab_dir, "tabF1_sde.tex"))

cat("\nAll tables generated successfully.\n")
cat(sprintf("Tables written to: %s\n", normalizePath(tab_dir)))
