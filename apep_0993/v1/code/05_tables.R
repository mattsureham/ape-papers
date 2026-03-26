## 05_tables.R — Generate all LaTeX tables
## apep_0993: South Korea 52-Hour Workweek Reform

source("00_packages.R")

cat("=== Generating Tables for apep_0993 ===\n")

load("../data/main_results.RData")
load("../data/robustness_results.RData")

# ─────────────────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────────────────

cat("Table 1: Summary Statistics\n")

# Helper for weighted variance
wtd.var <- function(x, w) {
  w <- w / sum(w, na.rm = TRUE)
  m <- sum(x * w, na.rm = TRUE)
  sum(w * (x - m)^2, na.rm = TRUE)
}

pre <- korea[year <= 2017]
post_data <- korea[year >= 2018]

# Recompute with helper
summ_bind_pre <- pre[binding == 1]
summ_nonb_pre <- pre[binding == 0]
summ_bind_post <- post_data[binding == 1]
summ_nonb_post <- post_data[binding == 0]

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Weekly Hours by Industry Overtime Exposure}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{High-Hours (Above Median)} & \\multicolumn{2}{c}{Low-Hours (At/Below Median)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Pre-Reform & Post-Reform & Pre-Reform & Post-Reform \\\\",
  "\\hline",
  sprintf("Mean weekly hours & %.1f & %.1f & %.1f & %.1f \\\\",
          weighted.mean(summ_bind_pre$hours, summ_bind_pre$emp_weight, na.rm = TRUE),
          weighted.mean(summ_bind_post$hours, summ_bind_post$emp_weight, na.rm = TRUE),
          weighted.mean(summ_nonb_pre$hours, summ_nonb_pre$emp_weight, na.rm = TRUE),
          weighted.mean(summ_nonb_post$hours, summ_nonb_post$emp_weight, na.rm = TRUE)),
  sprintf("SD of weekly hours & %.1f & %.1f & %.1f & %.1f \\\\",
          sd(summ_bind_pre$hours), sd(summ_bind_post$hours),
          sd(summ_nonb_pre$hours), sd(summ_nonb_post$hours)),
  sprintf("Mean employment (000s) & %.0f & %.0f & %.0f & %.0f \\\\",
          mean(summ_bind_pre$employment, na.rm = TRUE),
          mean(summ_bind_post$employment, na.rm = TRUE),
          mean(summ_nonb_pre$employment, na.rm = TRUE),
          mean(summ_nonb_post$employment, na.rm = TRUE)),
  sprintf("Industries & %d & %d & %d & %d \\\\",
          uniqueN(summ_bind_pre$industry), uniqueN(summ_bind_post$industry),
          uniqueN(summ_nonb_pre$industry), uniqueN(summ_nonb_post$industry)),
  sprintf("Industry $\\times$ Year obs. & %d & %d & %d & %d \\\\",
          nrow(summ_bind_pre), nrow(summ_bind_post),
          nrow(summ_nonb_pre), nrow(summ_nonb_post)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Data from ILO ILOSTAT. Industries classified as ``high-hours'' if 2017 average weekly hours exceeded the industry median (43.0 hours). High-hours industries had more workers in the 52--68 hour range directly affected by the cap. Pre-reform: 2010--2017; Post-reform: 2018--2023. Employment-weighted means. 20 ISIC Rev.~4 industries.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ─────────────────────────────────────────────────────────
# Table 2: Main DiD Results
# ─────────────────────────────────────────────────────────

cat("Table 2: Main DiD Results\n")

# Regression table using modelsummary
star <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of the 52-Hour Workweek Cap on Weekly Hours}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\hline",
  sprintf("High-Hours $\\times$ Post & %.3f%s & & & %.3f%s & %.3f%s \\\\",
          coef(m1), star(pvalue(m1)), coef(m_unw), star(pvalue(m_unw)),
          coef(m_no2020), star(pvalue(m_no2020))),
  sprintf(" & (%.3f) & & & (%.3f) & (%.3f) \\\\",
          se(m1), se(m_unw), se(m_no2020)),
  sprintf("Overtime Gap $\\times$ Post & & %.3f%s & & & \\\\",
          coef(m2), star(pvalue(m2))),
  sprintf(" & & (%.3f) & & & \\\\", se(m2)),
  sprintf("Baseline Hours $\\times$ Post & & & %.3f%s & & \\\\",
          coef(m3), star(pvalue(m3))),
  sprintf(" & & & (%.3f) & & \\\\", se(m3)),
  "\\hline",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs(m1), nobs(m2), nobs(m3), nobs(m_unw), nobs(m_no2020)),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"), r2(m_unw, "r2"), r2(m_no2020, "r2")),
  "Emp. Weighted & Yes & Yes & Yes & No & Yes \\\\",
  "Industry \\& Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered by industry in parentheses. High-hours industries had 2017 average weekly hours above the cross-industry median (42.9 hours). Col.~(1): binary treatment; (2): continuous overtime gap above median; (3): continuous baseline hours; (4): unweighted; (5): excluding 2020. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main_did.tex")

# ─────────────────────────────────────────────────────────
# Table 3: Event Study Coefficients
# ─────────────────────────────────────────────────────────

cat("Table 3: Event Study\n")

es <- coeftable(m_event)
es_dt <- as.data.table(es, keep.rownames = TRUE)
setnames(es_dt, c("term", "estimate", "se", "tstat", "pvalue"))

# Extract year from term
es_dt[, year := as.integer(gsub(".*year::(\\d+):.*", "\\1", term))]
es_dt <- es_dt[!is.na(year)]
es_dt <- es_dt[order(year)]

# Add reference year
ref_row <- data.table(term = "2017 (ref)", estimate = 0, se = NA, tstat = NA, pvalue = NA, year = 2017)
es_dt <- rbind(es_dt, ref_row)
es_dt <- es_dt[order(year)]

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Binding $\\times$ Year Interactions}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Year & Coefficient & Std. Error & $p$-value \\\\",
  "\\hline"
)

for (i in seq_len(nrow(es_dt))) {
  row <- es_dt[i]
  if (row$year == 2017) {
    tab3_lines <- c(tab3_lines, sprintf("%d & \\multicolumn{3}{c}{Reference} \\\\", row$year))
  } else {
    stars <- ifelse(row$pvalue < 0.01, "***",
                    ifelse(row$pvalue < 0.05, "**",
                           ifelse(row$pvalue < 0.10, "*", "")))
    tab3_lines <- c(tab3_lines, sprintf("%d & %.3f%s & (%.3f) & %.3f \\\\",
                                         row$year, row$estimate, stars, row$se, row$pvalue))
  }
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  sprintf("Observations & \\multicolumn{3}{c}{%d} \\\\", nrow(korea)),
  sprintf("Industries & \\multicolumn{3}{c}{%d} \\\\", uniqueN(korea$industry)),
  "Industry \\& Year FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from regression of weekly hours on interactions of Binding indicator with year dummies, employment-weighted, industry and year fixed effects, SEs clustered by industry. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")

# ─────────────────────────────────────────────────────────
# Table 4: Robustness Checks
# ─────────────────────────────────────────────────────────

cat("Table 4: Robustness\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Baseline & Ind. Trends & Placebo 2015 & Alt. 45h & No 2020 \\\\",
  "\\hline",
  sprintf("High-Hours $\\times$ Post & %.3f%s & %.3f & & & %.3f%s \\\\",
          coef(m1), star(pvalue(m1)),
          coef(m_trends)["binding:post"],
          coef(m_no2020), star(pvalue(m_no2020))),
  sprintf(" & (%.3f) & (%.3f) & & & (%.3f) \\\\",
          se(m1), se(m_trends)["binding:post"], se(m_no2020)),
  sprintf("High-Hours $\\times$ Placebo & & & %.3f & & \\\\",
          coef(m_placebo)),
  sprintf(" & & & (%.3f) & & \\\\", se(m_placebo)),
  sprintf("High-Hours(45h) $\\times$ Post & & & & %.3f%s & \\\\",
          coef(m_alt), star(pvalue(m_alt))),
  sprintf(" & & & & (%.3f) & \\\\", se(m_alt)),
  "\\hline",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs(m1), nobs(m_trends), nobs(m_placebo), nobs(m_alt), nobs(m_no2020)),
  "Industry \\& Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Industry Trends & No & Yes & No & No & No \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sprintf("\\item \\textit{Notes:} Standard errors clustered by industry. Employment-weighted. Placebo column uses 2015 as a fake treatment year on pre-reform data only. Leave-one-out range: [%.3f, %.3f]. Randomization inference $p$-value (1,000 permutations): %.3f. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
          min(loo_results$beta), max(loo_results$beta), ri_pvalue),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ─────────────────────────────────────────────────────────
# Table F1: Standardized Effect Sizes (SDE) — APPENDIX
# ─────────────────────────────────────────────────────────

cat("Table F1: SDE Appendix\n")

# Compute SDE for main outcomes
pre_sd <- sd(korea[year <= 2017, hours])
beta_main <- coef(m1)
se_main <- se(m1)

sde_main <- beta_main / pre_sd
sde_se <- se_main / pre_sd

classify_sde <- function(x) {
  abs_x <- abs(x)
  if (abs_x < 0.005) return("Null")
  if (abs_x < 0.05) return(paste0("Small ", ifelse(x < 0, "negative", "positive")))
  if (abs_x < 0.15) return(paste0("Moderate ", ifelse(x < 0, "negative", "positive")))
  return(paste0("Large ", ifelse(x < 0, "negative", "positive")))
}

# Panel A: Pooled
panel_a <- data.table(
  Outcome = "Weekly hours (all industries)",
  Beta = round(beta_main, 3),
  SE = round(se_main, 3),
  SD_Y = round(pre_sd, 3),
  SDE = round(sde_main, 3),
  SE_SDE = round(sde_se, 3),
  Classification = classify_sde(sde_main)
)

# Continuous specification
beta_gap <- coef(m2)
se_gap <- se(m2)
sde_gap <- beta_gap * sd(korea[year <= 2017, overtime_gap]) / pre_sd
sde_gap_se <- se_gap * sd(korea[year <= 2017, overtime_gap]) / pre_sd

panel_a <- rbind(panel_a, data.table(
  Outcome = "Weekly hours (continuous gap)",
  Beta = round(beta_gap, 3),
  SE = round(se_gap, 3),
  SD_Y = round(pre_sd, 3),
  SDE = round(sde_gap, 3),
  SE_SDE = round(sde_gap_se, 3),
  Classification = classify_sde(sde_gap)
))

# Panel B: Heterogeneous (by sector — sample splits)
# Split 1: Manufacturing industries only
manuf <- korea[industry == "C"]
# Split 2: Service industries with highest overtime (G, H, I)
serv <- korea[industry %in% c("G", "H", "I")]

# Simple before-after for single-industry subsamples
m_manuf <- lm(hours ~ post, data = manuf)
m_serv <- feols(hours ~ post | industry, data = serv)

pre_sd_manuf <- sd(manuf[year <= 2017, hours])
pre_sd_serv <- sd(serv[year <= 2017, hours])

beta_manuf <- coef(m_manuf)["post"]
se_manuf <- summary(m_manuf)$coefficients["post", "Std. Error"]
beta_serv <- coef(m_serv)["post"]
se_serv <- se(m_serv)["post"]

panel_b <- data.table(
  Outcome = c("Manufacturing (C)", "Trade/Transport/Accomm (G,H,I)"),
  Beta = c(round(beta_manuf, 3), round(beta_serv, 3)),
  SE = c(round(se_manuf, 3), round(se_serv, 3)),
  SD_Y = c(round(pre_sd_manuf, 3), round(pre_sd_serv, 3)),
  SDE = c(round(beta_manuf / pre_sd_manuf, 3),
          round(beta_serv / pre_sd_serv, 3)),
  SE_SDE = c(round(se_manuf / pre_sd_manuf, 3),
             round(se_serv / pre_sd_serv, 3)),
  Classification = c(classify_sde(beta_manuf / pre_sd_manuf),
                     classify_sde(beta_serv / pre_sd_serv))
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} South Korea. ",
  "\\textbf{Research question:} Did the 2018 statutory reduction in maximum weekly working hours from 68 to 52 reduce actual hours worked across industries? ",
  "\\textbf{Policy mechanism:} The amended Labor Standards Act (Article 53) imposed a hard cap of 52 hours per week (40 regular plus 12 overtime) with criminal penalties (up to 2 years imprisonment or KRW 20 million fine), implemented in three staggered waves by firm size from July 2018 to July 2021. ",
  "\\textbf{Outcome definition:} Mean weekly hours actually worked per employed person by ISIC Rev.~4 industry, from Korea's Economically Active Population Survey. ",
  "\\textbf{Treatment:} Binary indicator for industries where 2017 baseline average weekly hours exceeded the cross-industry median; high-hours industries had disproportionately more workers constrained by the 52-hour ceiling. ",
  "\\textbf{Data:} ILO ILOSTAT (DF\\_HOW\\_TEMP\\_SEX\\_ECO\\_NB), 2010--2023, industry-year panel, 20 ISIC industries. ",
  "\\textbf{Method:} Two-way fixed effects DiD with industry and year FE, employment-weighted, SEs clustered by industry. ",
  "\\textbf{Sample:} All ISIC Rev.~4 sections (A--U) excluding T (households as employers), 2010--2023 annual observations. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of weekly hours across industries (2010--2017). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in seq_len(nrow(panel_a))) {
  r <- panel_a[i]
  sde_lines <- c(sde_lines, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
                                     r$Outcome, r$Beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}

sde_lines <- c(sde_lines,
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by sector)}} \\\\"
)

for (i in seq_len(nrow(panel_b))) {
  r <- panel_b[i]
  sde_lines <- c(sde_lines, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
                                     r$Outcome, r$Beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
cat(paste(list.files("../tables"), collapse = "\n"), "\n")
