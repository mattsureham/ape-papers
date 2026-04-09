# 05_tables.R — Generate all tables for CQC paper
source("00_packages.R")

res <- readRDS("../data/rdd_results.rds")
rob <- readRDS("../data/robustness_results.rds")
dt_panel <- fread("../data/cqc_panel_closures.csv")
dt <- dt_panel[!is.na(composite_2024)]
dt[, D := as.integer(composite_2024 >= 17)]

# Helper: format with stars
fmt_star <- function(coef, se, digits = 3) {
  t <- abs(coef / se)
  stars <- ifelse(t > 2.576, "^{***}", ifelse(t > 1.96, "^{**}", ifelse(t > 1.645, "^{*}", "")))
  sprintf("$%s%s$", formatC(round(coef, digits), format = "f", digits = digits), stars)
}

fmt_se <- function(se, digits = 3) {
  sprintf("$(%s)$", formatC(round(se, digits), format = "f", digits = digits))
}

# ===================================================================
# Table 1: Summary Statistics
# ===================================================================
cat("Generating Table 1: Summary Statistics\n")

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Care Homes by Composite Inspection Score}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Below Threshold} & \\multicolumn{2}{c}{Above Threshold} \\\\",
  " & \\multicolumn{2}{c}{(Composite $< 17$)} & \\multicolumn{2}{c}{(Composite $\\geq 17$)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

# Compute stats
below <- dt[D == 0]
above <- dt[D == 1]

add_row <- function(label, var_below, var_above) {
  sprintf("%s & %.3f & %.3f & %.3f & %.3f \\\\",
          label,
          mean(var_below, na.rm = TRUE), sd(var_below, na.rm = TRUE),
          mean(var_above, na.rm = TRUE), sd(var_above, na.rm = TRUE))
}

tab1_lines <- c(tab1_lines,
  add_row("Closed by March 2026", below$closed_by_2026, above$closed_by_2026),
  add_row("Composite score", below$composite_2024, above$composite_2024),
  add_row("N Inadequate domains", below$n_inad_24, above$n_inad_24),
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          formatC(nrow(below), format = "d", big.mark = ","),
          formatC(nrow(above), format = "d", big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\n\\small",
  "\\item \\textit{Notes:} Sample includes all care homes with complete domain ratings in the CQC October 2024 snapshot. ``Closed by March 2026'' indicates the location no longer appears in the March 2026 CQC register. Composite score is the sum of five domain ratings (Safe, Effective, Caring, Responsive, Well-led), each coded 1 (Outstanding) to 4 (Inadequate), range 5--20. The threshold at composite $\\geq 17$ corresponds to the CQC rule for an overall Inadequate rating.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ===================================================================
# Table 2: Main RDD Results
# ===================================================================
cat("Generating Table 2: Main RDD Results\n")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Inadequate Rating on Care Home Closure}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Narrow & Wider & Diff.~slopes & Quadratic \\\\",
  "\\midrule",
  sprintf("Inadequate ($D$) & %s & %s & %s & %s \\\\",
          fmt_star(res$m1_coef, res$m1_se),
          fmt_star(res$m2_coef, res$m2_se),
          fmt_star(res$m3_coef, res$m3_se),
          fmt_star(res$m4_coef, res$m4_se)),
  sprintf(" & %s & %s & %s & %s \\\\",
          fmt_se(res$m1_se), fmt_se(res$m2_se),
          fmt_se(res$m3_se), fmt_se(res$m4_se)),
  "\\midrule",
  sprintf("Bandwidth & $\\pm 3$ & $\\pm 4.5$ & $\\pm 3.5$ & Full \\\\"),
  sprintf("Polynomial & Linear & Linear & Linear & Quadratic \\\\"),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(res$m1_n, format = "d", big.mark = ","),
          formatC(res$m2_n, format = "d", big.mark = ","),
          formatC(res$m3_n, format = "d", big.mark = ","),
          formatC(res$m4_n, format = "d", big.mark = ",")),
  sprintf("Control mean & \\multicolumn{4}{c}{%.3f} \\\\", res$baseline_closure),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\n\\small",
  "\\item \\textit{Notes:} Each column reports the estimated discontinuity in the probability of care home closure at the CQC Inadequate threshold (composite score $\\geq 17$). The running variable is the sum of five domain ratings (range 5--20), centered at 16.5. Column (1) uses a narrow bandwidth of $\\pm 3$ composite-score points; column (2) widens to $\\pm 4.5$; column (3) allows different slopes on each side of the cutoff; column (4) fits a global quadratic. HC2 robust standard errors in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ===================================================================
# Table 3: Closure Rates by Composite Score (Visual RDD)
# ===================================================================
cat("Generating Table 3: Closure Rates by Score\n")

tab_scores <- res$closure_by_score
tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Closure Rates by Composite Inspection Score}",
  "\\label{tab:scores}",
  "\\begin{tabular}{cccc}",
  "\\toprule",
  "Composite Score & $N$ & Closures & Closure Rate \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(tab_scores))) {
  row <- tab_scores[i]
  marker <- ifelse(row$composite_2024 >= 17, " $\\dagger$", "")
  tab3_lines <- c(tab3_lines,
    sprintf("%d%s & %s & %d & %.3f \\\\",
            row$composite_2024, marker,
            formatC(row$n, format = "d", big.mark = ","),
            row$closures, row$rate))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("\\multicolumn{4}{l}{\\textit{Below threshold (5--16):}} \\\\"),
  sprintf("\\multicolumn{1}{l}{\\quad Mean} & %s & %d & %.3f \\\\",
          formatC(nrow(dt[D == 0]), format = "d", big.mark = ","),
          sum(dt[D == 0]$closed_by_2026),
          mean(dt[D == 0]$closed_by_2026)),
  sprintf("\\multicolumn{4}{l}{\\textit{Above threshold (17--20):}} \\\\"),
  sprintf("\\multicolumn{1}{l}{\\quad Mean} & %d & %d & %.3f \\\\",
          nrow(dt[D == 1]),
          sum(dt[D == 1]$closed_by_2026),
          mean(dt[D == 1]$closed_by_2026)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\n\\small",
  "\\item \\textit{Notes:} Each row shows the number of care homes, closures, and closure rate for a given composite inspection score (sum of five CQC domain ratings, range 5--20). $\\dagger$ denotes scores at or above the Inadequate threshold. The jump in closure rates between composite scores 16 and 17 corresponds to the CQC rule that triggers Special Measures placement.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_scores.tex")

# ===================================================================
# Table 4: Robustness — Bandwidth Sensitivity
# ===================================================================
cat("Generating Table 4: Robustness\n")

bw_df <- rob$bandwidth
tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Bandwidth Sensitivity and Placebo Thresholds}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Bandwidth sensitivity}} \\\\",
  "\\midrule",
  "Bandwidth & Estimate & SE & $N$ \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(bw_df))) {
  row <- bw_df[i]
  tab4_lines <- c(tab4_lines,
    sprintf("$\\pm %d$ & %s & %s & %s \\\\",
            row$bw, fmt_star(row$coef, row$se),
            fmt_se(row$se),
            formatC(row$n, format = "d", big.mark = ",")))
}

placebo_df <- rob$placebo
tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Placebo thresholds (below-threshold sample only)}} \\\\",
  "\\midrule",
  "Placebo cutoff & Estimate & SE & $N$ \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(placebo_df))) {
  row <- placebo_df[i]
  tab4_lines <- c(tab4_lines,
    sprintf("%.1f & %s & %s & %s \\\\",
            row$cutoff, fmt_star(row$coef, row$se),
            fmt_se(row$se),
            formatC(row$n, format = "d", big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\n\\small",
  "\\item \\textit{Notes:} Panel A varies the bandwidth around the Inadequate threshold (composite $\\geq 17$). Panel B estimates the discontinuity at placebo cutoffs using only below-threshold observations (composite $< 17$), with bandwidth $\\pm 4$. HC2 robust standard errors. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")

# ===================================================================
# Table F1: Standardized Effect Sizes (SDE Appendix)
# ===================================================================
cat("Generating Table F1: SDE\n")

sd_y <- res$sd_y  # SD of closure outcome

# Main estimates
specs <- list(
  list(name = "Closure (narrow BW)", coef = res$m1_coef, se = res$m1_se),
  list(name = "Closure (wider BW)", coef = res$m2_coef, se = res$m2_se),
  list(name = "Closure (diff. slopes)", coef = res$m3_coef, se = res$m3_se),
  list(name = "Closure (quadratic)", coef = res$m4_coef, se = res$m4_se)
)

classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\midrule"
)

for (s in specs) {
  sde_val <- s$coef / sd_y
  sde_se <- s$se / sd_y
  cls <- classify_sde(sde_val)
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            s$name, s$coef, s$se, sd_y, round(sde_val, 3), round(sde_se, 3), cls))
}

# Panel B: Heterogeneous (by initial severity)
sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by initial severity)}} \\\\",
  "\\midrule"
)

# Split: homes with composite 17-18 (just above) vs 19-20 (far above)
dt_just <- dt[composite_2024 %in% c(14:18)]
dt_far <- dt[composite_2024 %in% c(14:16, 19:20)]

m_just <- lm(closed_by_2026 ~ D + I(composite_2024 - 16.5), data = dt_just)
m_far <- lm(closed_by_2026 ~ D + I(composite_2024 - 16.5), data = dt_far)

just_coef <- coef(m_just)["D"]
just_se <- sqrt(vcovHC(m_just, type = "HC2")["D", "D"])
far_coef <- coef(m_far)["D"]
far_se <- sqrt(vcovHC(m_far, type = "HC2")["D", "D"])

for (spec in list(
  list(name = "Near threshold (17--18)", coef = just_coef, se = just_se),
  list(name = "Far above (19--20)", coef = far_coef, se = far_se)
)) {
  sde_val <- spec$coef / sd_y
  sde_se <- spec$se / sd_y
  cls <- classify_sde(sde_val)
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            spec$name, spec$coef, spec$se, sd_y, round(sde_val, 3), round(sde_se, 3), cls))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does the CQC Inadequate rating, which triggers automatic Special Measures placement, cause care home closures beyond what underlying quality would predict? ",
  "\\textbf{Policy mechanism:} The Care Quality Commission assigns overall ratings based on a deterministic aggregation of five domain inspections; homes rated Inadequate overall enter Special Measures, a publicly announced regulatory escalation with mandatory six-month improvement deadlines and potential registration cancellation. ",
  "\\textbf{Outcome definition:} Binary indicator for care home deregistration (disappearance from the CQC active register) between October 2024 and March 2026. ",
  "\\textbf{Treatment:} Binary; composite inspection score at or above the Inadequate threshold (composite $\\geq 17$). ",
  "\\textbf{Data:} CQC bulk ratings download, October 2024 and March 2026 snapshots, care home locations only, $N = 14{,}704$. ",
  "\\textbf{Method:} Local linear regression with HC2 robust standard errors at the composite score threshold; varying bandwidths and polynomial orders. ",
  "\\textbf{Sample:} Care homes with complete five-domain ratings in the October 2024 CQC snapshot; excludes inherited ratings and provider-level reports. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation of the closure indicator. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\n\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
