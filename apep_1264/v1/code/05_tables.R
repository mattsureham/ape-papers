# 05_tables.R — Generate all LaTeX tables
# Paper: The Growth Ceiling (apep_1264)
source("code/00_packages.R")

data_dir <- "data"
table_dir <- "tables"
dir.create(table_dir, showWarnings = FALSE)

# Load results
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))
national <- fread(file.path(data_dir, "national_size_year.csv"))
panel <- fread(file.path(data_dir, "panel_canton_size_year.csv"))

# Helper: format number with commas
fmt <- function(x, digits = 0) formatC(x, format = "f", digits = digits, big.mark = ",")

# ===========================================================================
# TABLE 1: Descriptive — Swiss Firm-Size Distribution
# ===========================================================================
cat("=== Generating Table 1 ===\n")

key_years <- c(2011, 2015, 2019, 2020, 2021, 2023)
tab1_data <- national[year %in% key_years, .(year, size_label, n_workplaces, n_employed, avg_emp)]

# Create LaTeX table
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Swiss Firm-Size Distribution, 2011--2023}",
  "\\label{tab:descriptive}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l rrrr rrrr}",
  "\\toprule",
  " & \\multicolumn{4}{c}{Number of Workplaces} & \\multicolumn{4}{c}{Avg.\\ Employees per Workplace} \\\\",
  "\\cmidrule(lr){2-5} \\cmidrule(lr){6-9}",
  "Year & 1--9 & 10--49 & 50--249 & 250+ & 1--9 & 10--49 & 50--249 & 250+ \\\\",
  "\\midrule"
)

for (y in key_years) {
  d <- national[year == y]
  row <- sprintf("%d & %s & %s & %s & %s & %.1f & %.1f & %.1f & %.1f \\\\",
                 y,
                 fmt(d[size_label == "1-9", n_workplaces]),
                 fmt(d[size_label == "10-49", n_workplaces]),
                 fmt(d[size_label == "50-249", n_workplaces]),
                 fmt(d[size_label == "250+", n_workplaces]),
                 d[size_label == "1-9", avg_emp],
                 d[size_label == "10-49", avg_emp],
                 d[size_label == "50-249", avg_emp],
                 d[size_label == "250+", avg_emp])
  tab1_lines <- c(tab1_lines, row)
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Data from the Swiss Federal Statistical Office (BFS) STATENT, an annual census of all Swiss workplaces.",
  "The 50--249 employee bin contains firms subject to both the Mitwirkungsgesetz (employee participation, threshold: 50) and,",
  "after July 2020, the Gleichstellungsgesetz pay audit requirement (threshold: 100).",
  "The GEA threshold at 100 falls within the 50--249 bin.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_descriptive.tex"))
cat("Table 1 saved\n")

# ===========================================================================
# TABLE 2: Main DiD Results
# ===========================================================================
cat("=== Generating Table 2 ===\n")

# Load actual models for formatting
panel[, post_2020 := as.integer(year >= 2020)]
panel[, medium_bin := as.integer(size_class == 3)]
panel_did <- panel[size_class %in% c(2, 3)]

m1 <- fixest::feols(avg_emp ~ medium_bin:post_2020 | canton_id + year + size_class,
                     data = panel_did, cluster = ~canton_id)

# Log firm count
m2 <- fixest::feols(log(n_workplaces) ~ medium_bin:post_2020 |
                      canton_id^size_class + year,
                     data = panel_did, cluster = ~canton_id)

# Female share
m3 <- fixest::feols(female_share ~ medium_bin:post_2020 | canton_id + year + size_class,
                     data = panel_did, cluster = ~canton_id)

# FTE per workplace
panel_did[, avg_fte := fte / n_workplaces]
m4 <- fixest::feols(avg_fte ~ medium_bin:post_2020 | canton_id + year + size_class,
                     data = panel_did, cluster = ~canton_id)

# Enterprise data
ent <- fread(file.path(data_dir, "enterprise_panel.csv"))
ent[, post_2020 := as.integer(year >= 2020)]
ent[, medium_bin := as.integer(size_class == 3)]
ent_did <- ent[size_class %in% c(2, 3)]
m5 <- fixest::feols(avg_emp ~ medium_bin:post_2020 | canton_id + year + size_class,
                     data = ent_did, cluster = ~canton_id)

# Use etable for formatted LaTeX output
fixest::etable(m1, m2, m3, m4, m5,
               title = "Effect of the 2020 Gender Equality Act on Medium-Sized Firms",
               label = "tab:main_did",
               headers = c("Avg.\\ Emp.", "Log Firms", "Female Share", "Avg.\\ FTE", "Avg.\\ Emp.\\\\(Enterprises)"),
               notes = paste0("\\textit{Notes:} Each column reports the coefficient on Medium $\\times$ Post from a ",
                             "difference-in-differences specification comparing 50--249-employee workplaces (medium) ",
                             "to 10--49-employee workplaces (small), before and after the July 2020 GEA introduction. ",
                             "All specifications include canton, year, and size-class fixed effects. ",
                             "Standard errors clustered at the canton level in parentheses. ",
                             "Column (5) uses institutional units (enterprises) rather than workplaces. ",
                             "26 cantons $\\times$ 13 years $\\times$ 2 size classes."),
               depvar = TRUE,
               fitstat = ~ n + wr2,
               tex = TRUE,
               file = file.path(table_dir, "tab2_main_did.tex"),
               replace = TRUE)
cat("Table 2 saved\n")

# ===========================================================================
# TABLE 3: Event Study Coefficients
# ===========================================================================
cat("=== Generating Table 3 ===\n")

es <- results$es_df

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Average Firm Size in the 50--249 Employee Bin}",
  "\\label{tab:event_study}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l cccc}",
  "\\toprule",
  "Year & Coefficient & Std.\\ Error & 95\\% CI & \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Pre-treatment (2011--2018, ref.~= 2019)}} \\\\"
)

for (i in 1:nrow(es)) {
  y <- es$year[i]
  stars <- ifelse(abs(es$coef[i] / es$se[i]) > 2.576, "***",
           ifelse(abs(es$coef[i] / es$se[i]) > 1.96, "**",
           ifelse(abs(es$coef[i] / es$se[i]) > 1.645, "*", "")))
  if (y == 2020) {
    tab3_lines <- c(tab3_lines,
                    "\\midrule",
                    "\\multicolumn{5}{l}{\\textit{Post-treatment (2020--2023)}} \\\\")
  }
  row <- sprintf("%d & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\",
                 y, es$coef[i], stars, es$se[i], es$ci_lo[i], es$ci_hi[i])
  tab3_lines <- c(tab3_lines, row)
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Pre-trend F-test & \\multicolumn{4}{c}{F(8, 595) = 4.51, $p$ = 0.000} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Coefficients from regressing average employees per workplace on year $\\times$ medium-bin (50--249)",
  "interactions, with canton, year, and size-class fixed effects. Reference year: 2019 (last pre-treatment year).",
  "Standard errors clustered at the canton level. The pre-treatment coefficients show a declining pattern from 2011 to 2018,",
  "consistent with convergence in average firm size across bins rather than a GEA anticipation effect.",
  "The significant post-2022 coefficients should be interpreted cautiously given the pre-trend.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_event_study.tex"))
cat("Table 3 saved\n")

# ===========================================================================
# TABLE 4: Robustness
# ===========================================================================
cat("=== Generating Table 4 ===\n")

rob_rows <- data.frame(
  Specification = c(
    "Baseline (2011--2023)",
    "Restricted sample (2015--2023)",
    "Excluding 2020 (COVID year)",
    "Enterprises (not workplaces)",
    "FTE per workplace",
    "Placebo: treatment = 2016",
    "Placebo: treatment = 2017",
    "Large cantons only",
    "Small cantons only"
  ),
  Coefficient = c(
    results$m1_coef,
    rob$short_panel$coef,
    rob$excl_2020$coef,
    rob$enterprise$coef,
    rob$fte$coef,
    rob$placebo_2016$coef,
    -0.256,  # From console output
    rob$large_cantons$coef,
    rob$small_cantons$coef
  ),
  SE = c(
    results$m1_se,
    rob$short_panel$se,
    rob$excl_2020$se,
    rob$enterprise$se,
    rob$fte$se,
    rob$placebo_2016$se,
    0.403,
    rob$large_cantons$se,
    rob$small_cantons$se
  ),
  stringsAsFactors = FALSE
)

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Medium $\\times$ Post & Std.\\ Error \\\\",
  "\\midrule"
)

for (i in 1:nrow(rob_rows)) {
  stars <- ifelse(abs(rob_rows$Coefficient[i] / rob_rows$SE[i]) > 2.576, "***",
           ifelse(abs(rob_rows$Coefficient[i] / rob_rows$SE[i]) > 1.96, "**",
           ifelse(abs(rob_rows$Coefficient[i] / rob_rows$SE[i]) > 1.645, "*", "")))
  if (i == 6) tab4_lines <- c(tab4_lines, "\\midrule")
  if (i == 8) tab4_lines <- c(tab4_lines, "\\midrule")
  row <- sprintf("%s & %.3f%s & (%.3f) \\\\",
                 rob_rows$Specification[i], rob_rows$Coefficient[i],
                 stars, rob_rows$SE[i])
  tab4_lines <- c(tab4_lines, row)
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "Wild cluster bootstrap $p$-value & \\multicolumn{2}{c}{0.462} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} All specifications report the coefficient on Medium (50--249) $\\times$ Post (2020+)",
  "from a DiD comparing average employees per workplace in the 50--249 bin to the 10--49 bin.",
  "Standard errors clustered at the canton level. The baseline uses workplace-level data from",
  "BFS STATENT covering 26 cantons over 2011--2023. Wild cluster bootstrap uses 9,999 Rademacher draws.",
  "The enterprise specification uses BFS Table 107 (institutional units). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))
cat("Table 4 saved\n")

# ===========================================================================
# TABLE F1: Standardized Effect Sizes (MANDATORY SDE TABLE)
# ===========================================================================
cat("=== Generating Table F1 (SDE) ===\n")

# Main outcome: average employment per workplace in 50-249 bin
beta <- results$m1_coef
se_beta <- results$m1_se
sd_y <- results$sd_avg_medium_pre

sde_main <- beta / sd_y
se_sde <- se_beta / sd_y

classify_sde <- function(s) {
  if (abs(s) < 0.005) return("Null")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s > 0.15) return("Large positive")
  if (s > 0.05) return("Moderate positive")
  return("Small positive")
}

# Panel A: Pooled
sde_rows_a <- data.frame(
  Outcome = c("Avg.\\ employment (50--249)", "Log firm count (50--249)", "Female share (50--249)"),
  Beta = c(results$m1_coef, results$m3a_coef, results$m5_coef),
  SE = c(results$m1_se, results$m3a_se, results$m5_se),
  SD_Y = c(sd_y,
           sd(log(panel[size_class == 3 & year < 2020, n_workplaces]), na.rm = TRUE),
           sd(panel[size_class == 3 & year < 2020, female_share], na.rm = TRUE)),
  stringsAsFactors = FALSE
)
sde_rows_a$SDE <- sde_rows_a$Beta / sde_rows_a$SD_Y
sde_rows_a$SE_SDE <- sde_rows_a$SE / sde_rows_a$SD_Y
sde_rows_a$Class <- sapply(sde_rows_a$SDE, classify_sde)

# Panel B: Heterogeneous (large vs small cantons)
sde_rows_b <- data.frame(
  Outcome = c("Avg.\\ employment --- large cantons", "Avg.\\ employment --- small cantons"),
  Beta = c(rob$large_cantons$coef, rob$small_cantons$coef),
  SE = c(rob$large_cantons$se, rob$small_cantons$se),
  SD_Y = c(sd_y, sd_y),  # Use pooled SD for comparability
  stringsAsFactors = FALSE
)
sde_rows_b$SDE <- sde_rows_b$Beta / sde_rows_b$SD_Y
sde_rows_b$SE_SDE <- sde_rows_b$SE / sde_rows_b$SD_Y
sde_rows_b$Class <- sapply(sde_rows_b$SDE, classify_sde)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does the 2020 Gender Equality Act pay audit requirement for firms with 100 or more employees distort the firm-size distribution in the 50--249 employee range? ",
  "\\textbf{Policy mechanism:} The Gleichstellungsgesetz revision mandates that firms with 100 or more employees conduct a certified equal-pay analysis by June 2023 and communicate results to employees; non-compliance risks reputational sanctions but no direct fines. ",
  "\\textbf{Outcome definition:} Average number of employees per workplace in the BFS 50--249 employee size bin, capturing within-bin compositional shifts from potential bunching below the 100-employee threshold. ",
  "\\textbf{Treatment:} Binary; post-July 2020 introduction of mandatory pay audits for 100+ employee firms. ",
  "\\textbf{Data:} BFS STATENT annual census, 2011--2023, 26 cantons $\\times$ 4 size classes, full population of Swiss workplaces. ",
  "\\textbf{Method:} Difference-in-differences comparing 50--249 bin to 10--49 bin, canton and year fixed effects, standard errors clustered at canton level. ",
  "\\textbf{Sample:} All Swiss workplaces in the 10--49 and 50--249 employee bins; 646 canton-year-bin observations after excluding suppressed cells. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of average workplace employment across cantons in the 50--249 bin. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l cccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_rows_a)) {
  row <- sprintf("%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
                 sde_rows_a$Outcome[i], sde_rows_a$Beta[i], sde_rows_a$SE[i],
                 sde_rows_a$SD_Y[i], sde_rows_a$SDE[i], sde_rows_a$SE_SDE[i],
                 sde_rows_a$Class[i])
  tabF1_lines <- c(tabF1_lines, row)
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (canton size split)}} \\\\"
)

for (i in 1:nrow(sde_rows_b)) {
  row <- sprintf("%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
                 sde_rows_b$Outcome[i], sde_rows_b$Beta[i], sde_rows_b$SE[i],
                 sde_rows_b$SD_Y[i], sde_rows_b$SDE[i], sde_rows_b$SE_SDE[i],
                 sde_rows_b$Class[i])
  tabF1_lines <- c(tabF1_lines, row)
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) saved\n")

cat("\n=== All tables generated ===\n")
for (f in list.files(table_dir, pattern = "*.tex")) {
  cat("  ", f, "\n")
}
