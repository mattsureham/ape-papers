# 05_tables.R — Generate all tables for paper
source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- read.csv(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

pre <- panel %>% filter(year < 2019)
post <- panel %>% filter(year >= 2020)

# Summary stats function
sumstat <- function(df, varname, label) {
  x <- df[[varname]]
  data.frame(
    Variable = label,
    Mean = sprintf("%.3f", mean(x, na.rm = TRUE)),
    SD = sprintf("%.3f", sd(x, na.rm = TRUE)),
    Min = sprintf("%.3f", min(x, na.rm = TRUE)),
    Max = sprintf("%.3f", max(x, na.rm = TRUE)),
    N = format(sum(!is.na(x)), big.mark = ",")
  )
}

tab1_data <- bind_rows(
  data.frame(Variable = "\\textit{Panel A: Full sample}", Mean = "", SD = "",
             Min = "", Max = "", N = ""),
  sumstat(panel, "ntl_mean", "Nighttime light intensity (nW/cm$^2$/sr)"),
  sumstat(panel, "log_ntl", "Log nighttime light intensity"),
  sumstat(panel, "intensity_regional", "MFI revocations per 100k pop."),
  sumstat(panel, "high_treatment", "High-treatment district (binary)"),
  data.frame(Variable = "", Mean = "", SD = "", Min = "", Max = "", N = ""),
  data.frame(Variable = "\\textit{Panel B: Pre-treatment (2014--2018)}", Mean = "",
             SD = "", Min = "", Max = "", N = ""),
  sumstat(pre, "ntl_mean", "Nighttime light intensity"),
  sumstat(pre, "log_ntl", "Log nighttime light intensity"),
  data.frame(Variable = "", Mean = "", SD = "", Min = "", Max = "", N = ""),
  data.frame(Variable = "\\textit{Panel C: Post-treatment (2020--2023)}", Mean = "",
             SD = "", Min = "", Max = "", N = ""),
  sumstat(post, "ntl_mean", "Nighttime light intensity"),
  sumstat(post, "log_ntl", "Log nighttime light intensity")
)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  "Variable & Mean & SD & Min & Max & N \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(tab1_data))) {
  row <- tab1_data[i, ]
  if (row$Mean == "") {
    tab1_tex <- paste0(tab1_tex, row$Variable, " \\\\\n")
    if (grepl("Panel", row$Variable)) {
      tab1_tex <- paste0(tab1_tex, "\\addlinespace\n")
    }
  } else {
    tab1_tex <- paste0(tab1_tex,
      sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
              row$Variable, row$Mean, row$SD, row$Min, row$Max, row$N))
  }
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel dataset of ", format(n_distinct(panel$gid), big.mark = ","),
  " Ghanaian districts observed annually from 2014 to 2023 ($N = ",
  format(nrow(panel), big.mark = ","), "$). ",
  "Nighttime light intensity is the mean annual radiance from NASA Black Marble VNP46A4 ",
  "(nW/cm$^2$/sr), aggregated to GADM Level-2 administrative districts. ",
  "MFI revocations per 100,000 population captures the regional treatment intensity ",
  "from the Bank of Ghana's mass license revocation in May--August 2019. ",
  "High-treatment districts are those in regions with above-median revocation intensity.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("  Table 1 saved.\n")

# ============================================================================
# Table 2: Main Results
# ============================================================================
cat("=== Table 2: Main Results ===\n")

m1 <- results$m1_continuous_post2020
m1b <- results$m1b_continuous_incl2019
m2 <- results$m2_binary
m4 <- results$m4_level

# Extract components
get_row <- function(model, var_pattern = NULL) {
  cf <- coef(model)
  se_val <- se(model)
  pv <- pvalue(model)
  if (!is.null(var_pattern)) {
    idx <- grep(var_pattern, names(cf))
    cf <- cf[idx]
    se_val <- se_val[idx]
    pv <- pv[idx]
  }
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  list(beta = sprintf("%.4f%s", cf, stars),
       se = sprintf("(%.4f)", se_val),
       pv = pv)
}

r1 <- get_row(m1)
r1b <- get_row(m1b)
r2_row <- get_row(m2)
r4 <- get_row(m4)

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of MFI Revocations on Nighttime Light Intensity}\n",
  "\\label{tab:main}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Log NTL & Log NTL & Log NTL & NTL Level \\\\\n",
  "\\midrule\n",
  "Intensity $\\times$ Post & ", r1$beta, " & ", r1b$beta, " & & ", r4$beta, " \\\\\n",
  " & ", r1$se, " & ", r1b$se, " & & ", r4$se, " \\\\\n",
  "\\addlinespace\n",
  "High-treatment $\\times$ Post & & & ", r2_row$beta, " & \\\\\n",
  " & & & ", r2_row$se, " & \\\\\n",
  "\\addlinespace\n",
  "\\midrule\n",
  "Post definition & 2020+ & 2019+ & 2020+ & 2020+ \\\\\n",
  "Treatment variable & Continuous & Continuous & Binary & Continuous \\\\\n",
  "District FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Clusters (regions) & 16 & 16 & 16 & 16 \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(m1), big.mark = ","),
          format(nobs(m1b), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m4), big.mark = ",")),
  sprintf("R$^2$ (within) & %.3f & %.3f & %.3f & %.3f \\\\\n",
          fitstat(m1, "wr2")[[1]], fitstat(m1b, "wr2")[[1]],
          fitstat(m2, "wr2")[[1]], fitstat(m4, "wr2")[[1]]),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log mean nighttime light intensity ",
  "(columns 1--3) or level (column 4) from NASA Black Marble VNP46A4 annual composites. ",
  "``Intensity'' is the number of MFI licenses revoked per 100,000 regional population. ",
  "``High-treatment'' is an indicator for districts in regions with above-median revocation intensity. ",
  "All specifications include district and year fixed effects. ",
  "Standard errors clustered at the region level (16 clusters) in parentheses. ",
  "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("  Table 2 saved.\n")

# ============================================================================
# Table 3: Event Study Coefficients
# ============================================================================
cat("=== Table 3: Event Study ===\n")

m3 <- results$m3_eventstudy
cf3 <- coef(m3)
se3 <- se(m3)
pv3 <- pvalue(m3)

# Extract event time coefficients
event_names <- names(cf3)
event_times <- as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", event_names))

stars3 <- ifelse(pv3 < 0.01, "***", ifelse(pv3 < 0.05, "**", ifelse(pv3 < 0.1, "*", "")))

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Treatment Effects}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Event time & Coefficient & SE \\\\\n",
  "\\midrule\n"
)

for (k in order(event_times)) {
  et <- event_times[k]
  period_label <- ifelse(et < 0,
    sprintf("$t%d$ (Pre)", et),
    ifelse(et == 0, "$t_0$ (Treatment year)",
           sprintf("$t+%d$ (Post)", et)))

  tab3_tex <- paste0(tab3_tex,
    sprintf("%s & %s%s & (%s) \\\\\n",
            period_label,
            sprintf("%.4f", cf3[k]),
            stars3[k],
            sprintf("%.4f", se3[k])))
}

tab3_tex <- paste0(tab3_tex,
  "\\addlinespace\n",
  "Reference period & \\multicolumn{2}{c}{$t-1$ (2018)} \\\\\n",
  "\\midrule\n",
  "District FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Clusters (regions) & \\multicolumn{2}{c}{16} \\\\\n",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\\n",
          format(nobs(m3), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from the interaction of year indicators ",
  "with regional MFI revocation intensity (per 100,000 population). ",
  "The reference period is $t-1$ (2018). Standard errors clustered at the region ",
  "level in parentheses. ",
  "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_eventstudy.tex"))
cat("  Table 3 saved.\n")

# ============================================================================
# Table 4: Robustness Checks
# ============================================================================
cat("=== Table 4: Robustness ===\n")

rob_models <- list(
  robustness$placebo_2017,
  robustness$excl_accra,
  robustness$excl_ashanti,
  robustness$region_level
)
rob_labels <- c("Placebo (2017)", "Excl. Gr. Accra", "Excl. Ashanti", "Region level")

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  sprintf(" & %s \\\\\n", paste(rob_labels, collapse = " & ")),
  "\\midrule\n"
)

# Coefficients
betas <- sapply(rob_models, function(m) {
  pv <- pvalue(m)
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  sprintf("%.4f%s", coef(m), stars)
})
ses <- sapply(rob_models, function(m) sprintf("(%.4f)", se(m)))
obs <- sapply(rob_models, function(m) format(nobs(m), big.mark = ","))

tab4_tex <- paste0(tab4_tex,
  "Treatment $\\times$ Post & ", paste(betas, collapse = " & "), " \\\\\n",
  " & ", paste(ses, collapse = " & "), " \\\\\n",
  "\\addlinespace\n",
  "\\midrule\n",
  "District/Region FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", paste(obs, collapse = " & "), " \\\\\n",
  sprintf("RI $p$-value & & & & %.3f \\\\\n", robustness$ri_pvalue),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column 1 uses a placebo treatment date of 2017 on the pre-period ",
  "sample only (2014--2018). Columns 2--3 exclude the highest-treatment regions. ",
  "Column 4 aggregates to the region level. The RI $p$-value is from ",
  "randomization inference (1,000 permutations of treatment intensity across regions). ",
  "Standard errors clustered at the region level in parentheses. ",
  "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))
cat("  Table 4 saved.\n")

# ============================================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# ============================================================================
cat("=== Table F1: SDE Appendix ===\n")

# Calculate SDEs
sd_y_pre <- sd(panel$log_ntl[panel$year < 2019], na.rm = TRUE)
sd_y_level_pre <- sd(panel$ntl_mean[panel$year < 2019], na.rm = TRUE)
sd_x <- sd(panel$intensity_regional[!duplicated(panel$gid)], na.rm = TRUE)

# Continuous treatment: SDE = beta * SD(X) / SD(Y)
beta_cont <- coef(results$m1_continuous_post2020)
se_cont <- se(results$m1_continuous_post2020)
sde_cont <- beta_cont * sd_x / sd_y_pre
se_sde_cont <- se_cont * sd_x / sd_y_pre

# Binary treatment: SDE = beta / SD(Y)
beta_bin <- coef(results$m2_binary)
se_bin <- se(results$m2_binary)
sde_bin <- beta_bin / sd_y_pre
se_sde_bin <- se_bin / sd_y_pre

# Level: SDE = beta * SD(X) / SD(Y_level)
beta_level <- coef(results$m4_level)
se_level <- se(results$m4_level)
sde_level <- beta_level * sd_x / sd_y_level_pre
se_sde_level <- se_level * sd_x / sd_y_level_pre

# Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows <- data.frame(
  Panel = c(rep("A: Pooled", 3), rep("B: Heterogeneous", 2)),
  Outcome = c("Log NTL (continuous)", "Log NTL (binary)", "NTL level (continuous)",
              "Log NTL, high-intensity", "Log NTL, low-intensity"),
  stringsAsFactors = FALSE
)

# Heterogeneity: split by above/below median baseline NTL
pre_median_ntl <- median(panel$ntl_mean[panel$year < 2019], na.rm = TRUE)
panel$above_median_ntl <- as.integer(panel$ntl_mean > pre_median_ntl)

m_high <- feols(log_ntl ~ treat_post | gid + year,
                data = panel %>% filter(above_median_ntl == 1),
                cluster = ~region)
m_low <- feols(log_ntl ~ treat_post | gid + year,
               data = panel %>% filter(above_median_ntl == 0),
               cluster = ~region)

sde_high <- coef(m_high) * sd_x / sd(panel$log_ntl[panel$year < 2019 & panel$above_median_ntl == 1], na.rm = TRUE)
se_sde_high <- se(m_high) * sd_x / sd(panel$log_ntl[panel$year < 2019 & panel$above_median_ntl == 1], na.rm = TRUE)
sde_low <- coef(m_low) * sd_x / sd(panel$log_ntl[panel$year < 2019 & panel$above_median_ntl == 0], na.rm = TRUE)
se_sde_low <- se(m_low) * sd_x / sd(panel$log_ntl[panel$year < 2019 & panel$above_median_ntl == 0], na.rm = TRUE)

all_betas <- c(beta_cont, beta_bin, beta_level, coef(m_high), coef(m_low))
all_ses <- c(se_cont, se_bin, se_level, se(m_high), se(m_low))
all_sdy <- c(sd_y_pre, sd_y_pre, sd_y_level_pre,
             sd(panel$log_ntl[panel$year < 2019 & panel$above_median_ntl == 1], na.rm = TRUE),
             sd(panel$log_ntl[panel$year < 2019 & panel$above_median_ntl == 0], na.rm = TRUE))
all_sde <- c(sde_cont, sde_bin, sde_level, sde_high, sde_low)
all_se_sde <- c(se_sde_cont, se_sde_bin, se_sde_level, se_sde_high, se_sde_low)
all_class <- sapply(all_sde, classify_sde)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Ghana. ",
  "\\textbf{Research question:} What is the effect of mass microfinance license revocation on local economic activity, as measured by nighttime light intensity? ",
  "\\textbf{Policy mechanism:} The Bank of Ghana revoked 347 microfinance institution licenses and 23 savings-and-loans licenses in May--August 2019, eliminating credit intermediaries concentrated in southern urban regions and forcing borrowers to seek alternative financial services or forgo credit entirely. ",
  "\\textbf{Outcome definition:} Mean annual nighttime radiance from NASA Black Marble VNP46A4 (nW/cm$^2$/sr), aggregated to GADM Level-2 administrative districts; log-transformed for the primary specification. ",
  "\\textbf{Treatment:} Continuous (revoked MFI licenses per 100,000 regional population) or binary (above-median regional revocation intensity). ",
  "\\textbf{Data:} NASA Black Marble VNP46A4 annual composites (2014--2023), Bank of Ghana revocation registers, GADM v4.1 boundaries, Ghana Statistical Service 2021 Census; 260 districts, 10 years, $N = 2{,}600$. ",
  "\\textbf{Method:} Two-way fixed effects (district + year), dose-response difference-in-differences; standard errors clustered at the region level (16 clusters); randomization inference and wild cluster bootstrap for robustness. ",
  "\\textbf{Sample:} All 260 GADM Level-2 districts in Ghana; Panel B splits by above/below pre-treatment median nighttime light intensity. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, ",
  "$\\hat{\\beta} / \\text{SD}(Y)$ for binary treatment, ",
  "where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build table
tab_f1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llcccccc}\n",
  "\\toprule\n",
  " & Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

current_panel <- ""
for (i in seq_len(nrow(sde_rows))) {
  if (sde_rows$Panel[i] != current_panel) {
    current_panel <- sde_rows$Panel[i]
    tab_f1_tex <- paste0(tab_f1_tex,
      "\\multicolumn{8}{l}{\\textit{Panel ", current_panel, "}} \\\\\n",
      "\\addlinespace\n")
  }
  tab_f1_tex <- paste0(tab_f1_tex,
    sprintf(" & %s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            sde_rows$Outcome[i],
            all_betas[i], all_ses[i], all_sdy[i],
            all_sde[i], all_se_sde[i], all_class[i]))
}

tab_f1_tex <- paste0(tab_f1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab_f1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("  Table F1 (SDE) saved.\n")

cat("\nAll tables generated.\n")
