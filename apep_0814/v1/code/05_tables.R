## 05_tables.R — Generate all LaTeX tables
## APEP paper apep_0814: El Salvador gang removal and homicide geography

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "panel.csv"))
load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness.RData"))

# ─────────────────────────────────────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────────────────────────────────────
message("=== Table 1: Summary Statistics ===")

pre <- panel[post == 0]
pst <- panel[post == 1]
gang_cross <- panel[year == 2018]

# Build summary table
make_row <- function(varname, label, data, digits = 2) {
  vals <- data[[varname]]
  vals <- vals[!is.na(vals)]
  sprintf("%s & %.0f & %.{digits}f & %.{digits}f & %.{digits}f & %.{digits}f \\\\",
          label, length(vals),
          mean(vals), sd(vals),
          quantile(vals, 0.1), quantile(vals, 0.9))
}

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & N & Mean & SD & P10 & P90 \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Full sample (2002--2021)}} \\\\[3pt]",
  sprintf("Homicide rate (per 10K) & %d & %.2f & %.2f & %.2f & %.2f \\\\",
          sum(!is.na(panel$hom_rate_10k)), mean(panel$hom_rate_10k, na.rm=T),
          sd(panel$hom_rate_10k, na.rm=T),
          quantile(panel$hom_rate_10k, 0.1, na.rm=T),
          quantile(panel$hom_rate_10k, 0.9, na.rm=T)),
  sprintf("ln(Homicide rate + 1) & %d & %.2f & %.2f & %.2f & %.2f \\\\",
          sum(!is.na(panel$ln_hom)), mean(panel$ln_hom, na.rm=T),
          sd(panel$ln_hom, na.rm=T),
          quantile(panel$ln_hom, 0.1, na.rm=T),
          quantile(panel$ln_hom, 0.9, na.rm=T)),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Pre-period (2002--2018)}} \\\\[3pt]",
  sprintf("Homicide rate (per 10K) & %d & %.2f & %.2f & %.2f & %.2f \\\\",
          nrow(pre), mean(pre$hom_rate_10k, na.rm=T),
          sd(pre$hom_rate_10k, na.rm=T),
          quantile(pre$hom_rate_10k, 0.1, na.rm=T),
          quantile(pre$hom_rate_10k, 0.9, na.rm=T)),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel C: Post-period (2019--2021)}} \\\\[3pt]",
  sprintf("Homicide rate (per 10K) & %d & %.2f & %.2f & %.2f & %.2f \\\\",
          nrow(pst), mean(pst$hom_rate_10k, na.rm=T),
          sd(pst$hom_rate_10k, na.rm=T),
          quantile(pst$hom_rate_10k, 0.1, na.rm=T),
          quantile(pst$hom_rate_10k, 0.9, na.rm=T)),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel D: Treatment intensity (cross-section)}} \\\\[3pt]",
  sprintf("Gang detentions/100K (2011--2018 avg) & %d & %.1f & %.1f & %.1f & %.1f \\\\",
          sum(!is.na(gang_cross$gang_rate)),
          mean(gang_cross$gang_rate, na.rm=T),
          sd(gang_cross$gang_rate, na.rm=T),
          quantile(gang_cross$gang_rate, 0.1, na.rm=T),
          quantile(gang_cross$gang_rate, 0.9, na.rm=T)),
  sprintf("Population (2018) & %d & %.0f & %.0f & %.0f & %.0f \\\\",
          sum(!is.na(gang_cross$pop_2018)),
          mean(gang_cross$pop_2018, na.rm=T),
          sd(gang_cross$pop_2018, na.rm=T),
          quantile(gang_cross$pop_2018, 0.1, na.rm=T),
          quantile(gang_cross$pop_2018, 0.9, na.rm=T)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Municipality-year panel, 2002--2021. Homicide rates from PNC/IML administrative records (Carcach, 2025). Gang detentions from PNC records, 2011--2018 annual average per 100,000 population. Population from ONEC projections.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))
message("Table 1 saved.")

# ─────────────────────────────────────────────────────────────────────────────
# Table 2: Main Results
# ─────────────────────────────────────────────────────────────────────────────
message("=== Table 2: Main Results ===")

etable(m1, m2, m3, m4, m5,
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
       depvar = FALSE,
       se.below = TRUE,
       fitstat = ~n + r2,
       dict = c(
         "gang_rate_std:post" = "Gang Intensity $\\times$ Post",
         "gang_rate_std" = "Gang Intensity (std.)",
         "post" = "Post 2019",
         "high_gang:post" = "High Gang $\\times$ Post",
         "hom_2015_std:post" = "2015 Hom. Rate $\\times$ Post",
         "ln_hom" = "ln(Hom. Rate + 1)",
         "hom_rate_10k" = "Hom. Rate per 10K"
       ),
       tex = TRUE,
       file = file.path(table_dir, "tab2_main.tex"),
       replace = TRUE,
       notes = c(
         "Standard errors clustered at the municipality level in parentheses.",
         "Columns (1)--(3) and (5) use ln(homicide rate per 10,000 + 1) as the outcome.",
         "Column (2) uses the homicide rate in levels.",
         "Column (3) includes department $\\times$ year fixed effects.",
         "Column (4) uses a binary indicator for above-median gang detention rate.",
         "Column (5) uses the 2015 homicide rate (peak year) as treatment intensity.",
         "Gang Intensity is the standardized mean annual gang detention rate per 100K (2011--2018).",
         "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$"
       ),
       title = "Effect of Security Policy on Homicides by Gang Intensity",
       label = "tab:main")

message("Table 2 saved.")

# ─────────────────────────────────────────────────────────────────────────────
# Table 3: Robustness
# ─────────────────────────────────────────────────────────────────────────────
message("=== Table 3: Robustness ===")

etable(m1, m_no_ss, m_winsor, m_dept_cl, m_2way,
       headers = c("Baseline", "Drop S.S.", "Winsorized", "Dept. SE", "2-way SE"),
       depvar = FALSE,
       se.below = TRUE,
       fitstat = ~n + r2,
       dict = c(
         "gang_rate_std:post" = "Gang Intensity $\\times$ Post"
       ),
       tex = TRUE,
       file = file.path(table_dir, "tab3_robustness.tex"),
       replace = TRUE,
       notes = c(
         "All columns use ln(homicide rate + 1) as the outcome with municipality and year FE.",
         "Column (1): baseline with municipality-clustered SEs.",
         "Column (2): drops San Salvador department.",
         "Column (3): outcome winsorized at 99th percentile.",
         "Column (4): SEs clustered at the department level (14 clusters).",
         "Column (5): two-way clustered SEs (municipality + year).",
         "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$"
       ),
       title = "Robustness: Alternative Samples and Inference",
       label = "tab:robustness")

message("Table 3 saved.")

# ─────────────────────────────────────────────────────────────────────────────
# Table 4: Placebo Tests
# ─────────────────────────────────────────────────────────────────────────────
message("=== Table 4: Placebo Tests ===")

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Placebo Tests: False Treatment Dates}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Placebo Year & Coefficient & Std. Error & p-value \\\\",
  "\\midrule"
)

for (i in 1:nrow(placebo_df)) {
  stars <- ""
  if (placebo_df$pvalue[i] < 0.01) stars <- "***"
  else if (placebo_df$pvalue[i] < 0.05) stars <- "**"
  else if (placebo_df$pvalue[i] < 0.1) stars <- "*"

  tab4 <- c(tab4, sprintf("%d & %.4f%s & (%.4f) & %.3f \\\\",
                           placebo_df$placebo_year[i],
                           placebo_df$coef[i], stars,
                           placebo_df$se[i],
                           placebo_df$pvalue[i]))
}

tab4 <- c(tab4,
  "\\midrule",
  sprintf("\\textit{Actual treatment (2019)} & \\textit{%.4f}$^{***}$ & \\textit{(%.4f)} & \\textit{%.4f} \\\\",
          as.numeric(coef(m1)), as.numeric(se(m1)), as.numeric(pvalue(m1))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Each row estimates the main specification using only pre-2019 data, with the indicated year as a placebo treatment date. Dependent variable: ln(homicide rate + 1). Municipality and year FE included. SEs clustered at municipality level. The actual 2019 treatment shown in italics for comparison. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, file.path(table_dir, "tab4_placebo.tex"))
message("Table 4 saved.")

# ─────────────────────────────────────────────────────────────────────────────
# Table F1: SDE Appendix
# ─────────────────────────────────────────────────────────────────────────────
message("=== Table F1: Standardized Effect Sizes ===")

# Compute SDEs
# M1: ln(hom+1), continuous gang intensity (std), β = coef(m1)
# SDE = β / SD(Y) since X is already standardized
sde_m1 <- as.numeric(coef(m1)) / pre_sd_log
sde_se_m1 <- as.numeric(se(m1)) / pre_sd_log

# M2: levels, continuous gang intensity (std), β = coef(m2)
sde_m2 <- as.numeric(coef(m2)) / pre_sd_level
sde_se_m2 <- as.numeric(se(m2)) / pre_sd_level

# M4: binary treatment (high gang), β = coef(m4)
sde_m4 <- as.numeric(coef(m4)) / pre_sd_log
sde_se_m4 <- as.numeric(se(m4)) / pre_sd_log

# M5: 2015 intensity, β = coef(m5)
sde_m5 <- as.numeric(coef(m5)) / pre_sd_log
sde_se_m5 <- as.numeric(se(m5)) / pre_sd_log

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} El Salvador. ",
  "\\textbf{Research question:} Does El Salvador's post-2019 homicide decline concentrate in municipalities with greater pre-existing gang presence, as measured by police-recorded gang detention rates? ",
  "\\textbf{Policy mechanism:} President Bukele's Territorial Control Plan (2019) deployed military and police forces to municipalities with gang territorial control, combined with mass arrests and reported informal negotiations with gang leadership, aiming to suppress extortion networks and territorial violence. ",
  "\\textbf{Outcome definition:} Municipality-level homicide rate per 10,000 population, from PNC and IML administrative records (ln-transformed in primary specification). ",
  "\\textbf{Treatment:} Continuous (standardized gang detention rate per 100K, 2011--2018 average) and binary (above/below median gang detentions). ",
  "\\textbf{Data:} Carcach (2025) municipality panel, 262 municipalities, 2002--2021, police administrative records. ",
  "\\textbf{Method:} Continuous-intensity DiD with municipality and year FE, SEs clustered at municipality level. ",
  "\\textbf{Sample:} All 256 El Salvador municipalities with complete data; gang detention rate computed from 2011--2018 PNC records divided by 2018 ONEC population estimates. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("ln(Hom.+1), continuous & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          as.numeric(coef(m1)), as.numeric(se(m1)), pre_sd_log,
          sde_m1, sde_se_m1, classify_sde(sde_m1)),
  sprintf("Hom. rate, continuous & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          as.numeric(coef(m2)), as.numeric(se(m2)), pre_sd_level,
          sde_m2, sde_se_m2, classify_sde(sde_m2)),
  sprintf("ln(Hom.+1), binary & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          as.numeric(coef(m4)), as.numeric(se(m4)), pre_sd_log,
          sde_m4, sde_se_m4, classify_sde(sde_m4)),
  sprintf("ln(Hom.+1), 2015 int. & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          as.numeric(coef(m5)), as.numeric(se(m5)), pre_sd_log,
          sde_m5, sde_se_m5, classify_sde(sde_m5)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))
message("Table F1 saved.")

message("\n=== All tables generated ===")
message("Tables directory: ", normalizePath(table_dir))
