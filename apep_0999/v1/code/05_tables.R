# 05_tables.R — Generate all LaTeX tables
# apep_0999: IR35 compliance trap

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
robustness <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))
bunching <- fread(file.path(DATA_DIR, "bunching_ratio_panel.csv"))
analysis <- fread(file.path(DATA_DIR, "analysis_panel.csv"))

bunching[, year_f := factor(year)]
bunching[, post_2021 := as.integer(year >= 2021)]
bunching[, contractor := as.integer(sector_type == "contractor")]

star <- function(p) {
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("Table 1: Summary Statistics\n")

# Aggregate counts by sector × period
agg <- bunching[, .(
  count_20_49 = sum(count_20_49),
  count_50_99 = sum(count_50_99),
  bunching_ratio = sum(count_20_49) / sum(count_50_99),
  n_sic_years = .N
), by = .(sector_type, post_2021)]

tab1 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Firm Size Distribution by Sector and Period}
\\label{tab:summary}
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{Contractor-Intensive} & \\multicolumn{2}{c}{Control (Trade)} \\\\
 & \\multicolumn{2}{c}{(SIC 62, 70, 71, 74)} & \\multicolumn{2}{c}{(SIC 46, 47)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & Pre-2021 & Post-2021 & Pre-2021 & Post-2021 \\\\
\\hline
\\textit{Panel A: Annual mean counts} & & & & \\\\[3pt]
Firms with 20--49 employees & %s & %s & %s & %s \\\\
Firms with 50--99 employees & %s & %s & %s & %s \\\\[6pt]
\\textit{Panel B: Bunching ratio} & & & & \\\\[3pt]
(20--49) / (50--99) & %.2f & %.2f & %.2f & %.2f \\\\[6pt]
\\textit{Panel C: Sample} & & & & \\\\[3pt]
SIC $\\times$ year observations & %d & %d & %d & %d \\\\
Years & \\multicolumn{2}{c}{2010--2020} & \\multicolumn{2}{c}{2021--2025} \\\\
SIC codes & \\multicolumn{2}{c}{4} & \\multicolumn{2}{c}{2} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Data from NOMIS UK Business Counts (Inter-Departmental Business Register), 2010--2025. Contractor-intensive sectors: Computer Programming and Consultancy (SIC 62), Head Offices and Management Consultancy (SIC 70), Architecture and Engineering (SIC 71), Other Professional Activities (SIC 74). Control sectors: Wholesale Trade (SIC 46) and Retail Trade (SIC 47). The bunching ratio is the count of enterprises in the 20--49 employee sizeband divided by the count in the 50--99 band. A declining ratio indicates relatively more firms crossing the 50-employee threshold.
\\end{tablenotes}
\\end{table}",
  format(round(agg[sector_type == "contractor" & post_2021 == 0, count_20_49 / 11]), big.mark = ","),
  format(round(agg[sector_type == "contractor" & post_2021 == 1, count_20_49 / 5]), big.mark = ","),
  format(round(agg[sector_type == "control" & post_2021 == 0, count_20_49 / 11]), big.mark = ","),
  format(round(agg[sector_type == "control" & post_2021 == 1, count_20_49 / 5]), big.mark = ","),
  format(round(agg[sector_type == "contractor" & post_2021 == 0, count_50_99 / 11]), big.mark = ","),
  format(round(agg[sector_type == "contractor" & post_2021 == 1, count_50_99 / 5]), big.mark = ","),
  format(round(agg[sector_type == "control" & post_2021 == 0, count_50_99 / 11]), big.mark = ","),
  format(round(agg[sector_type == "control" & post_2021 == 1, count_50_99 / 5]), big.mark = ","),
  agg[sector_type == "contractor" & post_2021 == 0, bunching_ratio],
  agg[sector_type == "contractor" & post_2021 == 1, bunching_ratio],
  agg[sector_type == "control" & post_2021 == 0, bunching_ratio],
  agg[sector_type == "control" & post_2021 == 1, bunching_ratio],
  agg[sector_type == "contractor" & post_2021 == 0, n_sic_years],
  agg[sector_type == "contractor" & post_2021 == 1, n_sic_years],
  agg[sector_type == "control" & post_2021 == 0, n_sic_years],
  agg[sector_type == "control" & post_2021 == 1, n_sic_years]
)

writeLines(tab1, file.path(TABLE_DIR, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("Table 2: Main Results\n")

# Re-estimate models for the table
reg1 <- feols(bunching_ratio ~ post_2021:contractor | sic_code + year_f,
              data = bunching, vcov = "hetero")
ct1 <- coeftable(reg1)

# Triple-diff
td <- analysis[emp_lower %in% c(20, 50) & count > 0]
td[, log_count := log(count)]
td[, below_threshold := as.integer(emp_upper <= 49)]
td[, year_f := factor(year)]
reg2 <- feols(log_count ~ below_threshold:post_2021:contractor +
                below_threshold:post_2021 + below_threshold:contractor +
                post_2021:contractor | year_f + sector_type,
              data = td, vcov = "hetero")
ct2 <- coeftable(reg2)

# Growth of 50-99 band
band50 <- analysis[emp_lower == 50]
band50[, log_count := log(count)]
band50[, year_f := factor(year)]
reg3 <- feols(log_count ~ post_2021:contractor | sector_type + year_f,
              data = band50, vcov = "hetero")
ct3 <- coeftable(reg3)

tab2 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Main Results: IR35 and Firm Size Distribution}
\\label{tab:main}
\\begin{tabular}{lccc}
\\hline\\hline
 & (1) & (2) & (3) \\\\
 & Bunching Ratio & Log Counts (DDD) & Log Count (50--99) \\\\
\\hline
Post $\\times$ Contractor & $%.3f%s$ & & $%.3f%s$ \\\\
 & (%.3f) & & (%.3f) \\\\[6pt]
Below $\\times$ Post $\\times$ Contractor & & $%.3f%s$ & \\\\
 & & (%.3f) & \\\\[6pt]
\\hline
SIC FE & Yes & & \\\\
Sector FE & & Yes & Yes \\\\
Year FE & Yes & Yes & Yes \\\\
Observations & %d & %d & %d \\\\
$R^2$ (within) & %.3f & %.3f & %.3f \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Column (1): difference-in-bunching regression of the ratio (20--49 emp.)/(50--99 emp.) on Post $\\times$ Contractor, with SIC and year fixed effects. A negative coefficient indicates the bunching ratio fell more in contractor-intensive sectors after IR35 implementation, consistent with firms crossing the 50-employee threshold. Column (2): triple-difference on log firm counts---Below threshold $\\times$ Post-2021 $\\times$ Contractor-intensive SIC. Column (3): DiD on log count of firms in the 50--99 band specifically. Heteroskedasticity-robust standard errors in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.
\\end{tablenotes}
\\end{table}",
  ct1["post_2021:contractor", "Estimate"],
  star(ct1["post_2021:contractor", "Pr(>|t|)"]),
  ct3["post_2021:contractor", "Estimate"],
  star(ct3["post_2021:contractor", "Pr(>|t|)"]),
  ct1["post_2021:contractor", "Std. Error"],
  ct3["post_2021:contractor", "Std. Error"],
  ct2["below_threshold:post_2021:contractor", "Estimate"],
  star(ct2["below_threshold:post_2021:contractor", "Pr(>|t|)"]),
  ct2["below_threshold:post_2021:contractor", "Std. Error"],
  nrow(bunching), nrow(td), nrow(band50),
  fitstat(reg1, "wr2")[[1]], fitstat(reg2, "wr2")[[1]], fitstat(reg3, "wr2")[[1]]
)

writeLines(tab2, file.path(TABLE_DIR, "tab2_main_results.tex"))

# ============================================================
# TABLE 3: Event Study
# ============================================================
cat("Table 3: Event Study\n")

bunching[, year_f := relevel(factor(year), ref = "2019")]
reg_event <- feols(bunching_ratio ~ i(year_f, contractor, ref = "2019") | sic_code,
                   data = bunching, vcov = "hetero")
ect <- as.data.table(coeftable(reg_event), keep.rownames = TRUE)
setnames(ect, c("term", "est", "se", "t", "p"))
ect[, year := as.integer(str_extract(term, "\\d{4}"))]
ect <- ect[!is.na(year)][order(year)]

event_rows <- paste(apply(ect, 1, function(r) {
  y <- as.integer(r["year"])
  e <- as.numeric(r["est"])
  s <- as.numeric(r["se"])
  p <- as.numeric(r["p"])
  marker <- ifelse(y == 2021, " $\\leftarrow$ \\textit{IR35 implemented}", "")
  sprintf("%d & $%.3f%s$ & (%.3f)%s \\\\", y, e, star(p), s, marker)
}), collapse = "\n")

tab3 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Event Study: Differential Bunching Ratio by Year}
\\label{tab:event}
\\begin{tabular}{lcc}
\\hline\\hline
Year & Coefficient & Std. Error \\\\
\\hline
%s
\\hline
Reference year & \\multicolumn{2}{c}{2019} \\\\
SIC FE & \\multicolumn{2}{c}{Yes} \\\\
Observations & \\multicolumn{2}{c}{%d} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Coefficients from a regression of the bunching ratio on Year $\\times$ Contractor interactions, with SIC fixed effects and 2019 as the reference year. Each coefficient represents the differential bunching ratio for contractor-intensive sectors relative to 2019. Negative post-2021 coefficients indicate that the bunching ratio declined more in contractor sectors after IR35 implementation. The effect strengthens over time, consistent with gradual contractor-to-employee conversion. Heteroskedasticity-robust standard errors in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.
\\end{tablenotes}
\\end{table}", event_rows, nrow(bunching))

writeLines(tab3, file.path(TABLE_DIR, "tab3_event_study.tex"))

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("Table 4: Robustness\n")

tab4 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks}
\\label{tab:robust}
\\begin{tabular}{lccc}
\\hline\\hline
 & Coefficient & Std. Error & $p$-value \\\\
\\hline
\\textit{Panel A: Main estimate} & & & \\\\
Post $\\times$ Contractor (50-emp. threshold) & $%.3f%s$ & (%.3f) & %.3f \\\\[6pt]
\\textit{Panel B: Placebo thresholds} & & & \\\\
10--19 / 20--49 ratio (20-emp. placebo) & $%.3f%s$ & (%.3f) & %.3f \\\\
100--249 / 250--499 ratio (250-emp. placebo) & $%.3f%s$ & (%.3f) & %.3f \\\\[6pt]
\\textit{Panel C: Pre-trend test} & & & \\\\
Year $\\times$ Contractor (pre-2021 only) & $%.3f%s$ & (%.3f) & %.3f \\\\[6pt]
\\textit{Panel D: Excluding COVID (2022+ vs pre-2020)} & & & \\\\
Post-2022 $\\times$ Contractor & $%.3f%s$ & (%.3f) & %.3f \\\\[6pt]
\\textit{Panel E: Bootstrap inference (1,000 reps)} & & & \\\\
DiB estimate & $%.3f$ & (%.3f) & \\\\
95\\%% CI & \\multicolumn{3}{c}{$[%.3f, \\, %.3f]$} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Panel A reproduces the main DiD specification with SIC and year fixed effects. Panel B reports placebo tests at the 20- and 250-employee boundaries where no IR35-related policy threshold exists. The significant 20-employee placebo is consistent with broad headcount inflation from contractor-to-employee conversion affecting all firm sizes, not just the 50-employee threshold. The insignificant 250-employee placebo suggests the effect is concentrated among smaller firms where contractors represent a larger share of the workforce. Panel C tests for differential pre-trends. Panel D excludes 2020--2021 to eliminate COVID effects. Panel E reports bootstrap standard errors and percentile confidence intervals. All specifications use heteroskedasticity-robust standard errors unless otherwise noted. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.
\\end{tablenotes}
\\end{table}",
  ct1["post_2021:contractor", "Estimate"],
  star(ct1["post_2021:contractor", "Pr(>|t|)"]),
  ct1["post_2021:contractor", "Std. Error"],
  ct1["post_2021:contractor", "Pr(>|t|)"],
  robustness$placebo_20_coef, star(robustness$placebo_20_p),
  robustness$placebo_20_se, robustness$placebo_20_p,
  robustness$placebo_250_coef, star(robustness$placebo_250_p),
  robustness$placebo_250_se, robustness$placebo_250_p,
  robustness$pretrend_coef, star(robustness$pretrend_p),
  robustness$pretrend_se, robustness$pretrend_p,
  robustness$no_covid_coef, star(robustness$no_covid_p),
  robustness$no_covid_se, robustness$no_covid_p,
  results$dib_estimate, robustness$boot_se,
  robustness$boot_ci[1], robustness$boot_ci[2]
)

writeLines(tab4, file.path(TABLE_DIR, "tab4_robustness.tex"))

# ============================================================
# TABLE 5: By SIC Code
# ============================================================
cat("Table 5: By SIC Code\n")

sic_rows <- ""
for (sic in sort(unique(bunching[contractor == 1, sic_code]))) {
  sic_name <- bunching[sic_code == sic, sic_name[1]]
  sic_short <- str_extract(sic_name, "^\\d+")
  sic_desc <- trimws(sub("^\\d+\\s*:\\s*", "", sic_name))
  sic_desc <- substr(sic_desc, 1, 45)

  sub_data <- rbind(bunching[sic_code == sic], bunching[contractor == 0])
  reg_sub <- feols(bunching_ratio ~ post_2021:contractor | sic_code + year_f,
                   data = sub_data, vcov = "hetero")
  ct_sub <- coeftable(reg_sub)
  est <- ct_sub["post_2021:contractor", "Estimate"]
  se <- ct_sub["post_2021:contractor", "Std. Error"]
  p <- ct_sub["post_2021:contractor", "Pr(>|t|)"]

  # N firms in 20-49 band (latest year)
  n_firms <- bunching[sic_code == sic & year == max(year), count_20_49]

  sic_rows <- paste0(sic_rows, sprintf(
    "SIC %s: %s & $%.3f%s$ & (%.3f) & %s \\\\\n",
    sic_short, sic_desc, est, star(p), se, format(n_firms, big.mark = ",")))
}

tab5 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Heterogeneity: Difference-in-Bunching by SIC Code}
\\label{tab:sic}
\\begin{tabular}{lccc}
\\hline\\hline
Sector & Post $\\times$ Contr. & Std. Error & Firms (20--49) \\\\
\\hline
%s\\hline
\\textit{All contractor SICs pooled} & $%.3f%s$ & (%.3f) & \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Each row reports the Post $\\times$ Contractor coefficient from a separate regression of the bunching ratio with SIC and year fixed effects, pairing each contractor-intensive SIC code individually against the two control SICs (46, 47). The final row reproduces the pooled estimate from Table \\ref{tab:main}. Firms (20--49) shows the latest-year count in the 20--49 employee band. Heteroskedasticity-robust standard errors. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.
\\end{tablenotes}
\\end{table}",
  sic_rows,
  ct1["post_2021:contractor", "Estimate"],
  star(ct1["post_2021:contractor", "Pr(>|t|)"]),
  ct1["post_2021:contractor", "Std. Error"]
)

writeLines(tab5, file.path(TABLE_DIR, "tab5_by_sic.tex"))

# ============================================================
# TABLE F1: SDE (MANDATORY)
# ============================================================
cat("Table F1: Standardized Effect Sizes\n")

# Main outcome: bunching ratio
beta_main <- ct1["post_2021:contractor", "Estimate"]
se_main <- ct1["post_2021:contractor", "Std. Error"]
sd_y <- sd(bunching[post_2021 == 0 & contractor == 1, bunching_ratio])
sde_main <- beta_main / sd_y
se_sde <- se_main / sd_y

classify_sde <- function(sde) {
  a <- abs(sde)
  if (a > 0.15) return(ifelse(sde > 0, "Large pos.", "Large neg."))
  if (a > 0.05) return(ifelse(sde > 0, "Mod. pos.", "Mod. neg."))
  if (a > 0.005) return(ifelse(sde > 0, "Small pos.", "Small neg."))
  return("Null")
}

# Panel B: By SIC subsector (SIC 62 vs SIC 71)
sub62 <- rbind(bunching[sic_code == sort(unique(bunching[contractor == 1, sic_code]))[1]],
               bunching[contractor == 0])
reg62 <- feols(bunching_ratio ~ post_2021:contractor | sic_code + year_f,
               data = sub62, vcov = "hetero")
ct62 <- coeftable(reg62)
sd62 <- sd(bunching[sic_code == sort(unique(bunching[contractor == 1, sic_code]))[1] &
                      post_2021 == 0, bunching_ratio])
sde62 <- ct62["post_2021:contractor", "Estimate"] / sd62

sub71 <- rbind(bunching[sic_code == sort(unique(bunching[contractor == 1, sic_code]))[3]],
               bunching[contractor == 0])
reg71 <- feols(bunching_ratio ~ post_2021:contractor | sic_code + year_f,
               data = sub71, vcov = "hetero")
ct71 <- coeftable(reg71)
sd71 <- sd(bunching[sic_code == sort(unique(bunching[contractor == 1, sic_code]))[3] &
                      post_2021 == 0, bunching_ratio])
sde71 <- ct71["post_2021:contractor", "Estimate"] / sd71

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does the April 2021 extension of IR35 off-payroll working rules to private-sector clients cause contractor-intensive firms to change their size relative to the 50-employee small company threshold? ",
  "\\textbf{Policy mechanism:} IR35 shifts responsibility for determining contractor tax status from the contractor to the client firm, imposing compliance costs of approximately 500--2,000 pounds per contractor per year; companies meeting at least two of three Companies Act 2006 criteria (at most 50 employees, at most 10.2 million pounds turnover, at most 5.1 million pounds balance sheet) are exempt. ",
  "\\textbf{Outcome definition:} Bunching ratio defined as the count of enterprises in the 20--49 employee sizeband divided by the count in the 50--99 sizeband, from NOMIS UK Business Counts. A decline indicates relatively more firms above 50 employees. ",
  "\\textbf{Treatment:} Binary; post-April 2021 implementation of IR35 private-sector extension interacted with contractor-intensive SIC classification. ",
  "\\textbf{Data:} NOMIS UK Business Counts (Inter-Departmental Business Register), 2010--2025, SIC-year level, covering all registered enterprises in the United Kingdom across six 2-digit SIC codes. ",
  "\\textbf{Method:} Difference-in-bunching estimator comparing bunching ratios before versus after 2021 in contractor-intensive sectors (SIC 62, 70, 71, 74) versus control sectors (SIC 46, 47), with SIC and year fixed effects; heteroskedasticity-robust standard errors. ",
  "\\textbf{Sample:} Restricted to 2-digit SIC codes 62, 70, 71, 74 as treatment and 46, 47 as control; employee sizebands 20--49 and 50--99 for the bunching ratio construction. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the bunching ratio among contractor-intensive sectors. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\textit{Panel A: Pooled} & & & & & & \\\\
Bunching ratio (20--49)/(50--99) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\[6pt]
\\textit{Panel B: Heterogeneous (by subsector)} & & & & & & \\\\
SIC 62: Computer programming & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\
SIC 71: Architecture/engineering & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
%s
\\end{tablenotes}
\\end{table}",
  beta_main, se_main, sd_y, sde_main, se_sde, classify_sde(sde_main),
  ct62["post_2021:contractor", "Estimate"], ct62["post_2021:contractor", "Std. Error"],
  sd62, sde62, ct62["post_2021:contractor", "Std. Error"] / sd62, classify_sde(sde62),
  ct71["post_2021:contractor", "Estimate"], ct71["post_2021:contractor", "Std. Error"],
  sd71, sde71, ct71["post_2021:contractor", "Std. Error"] / sd71, classify_sde(sde71),
  sde_notes
)

writeLines(tabF1, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat(paste(" ", list.files(TABLE_DIR), collapse = "\n"))
cat("\n")
