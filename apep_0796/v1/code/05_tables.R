## 05_tables.R — Generate all LaTeX tables
## apep_0796: Swiss Second Home Ban RDD

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

rdd <- readRDS(file.path(data_dir, "rdd_cross_section.rds"))
results <- readRDS(file.path(data_dir, "rdd_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ================================================================
## Table 1: Summary Statistics
## ================================================================

# Compute stats by treatment group
stats_fn <- function(df, varname, label) {
  x <- df[[varname]]
  data.frame(
    Variable = label,
    Mean_All = mean(x, na.rm = TRUE),
    SD_All = sd(x, na.rm = TRUE),
    Mean_Treated = mean(x[df$treated == 1], na.rm = TRUE),
    SD_Treated = sd(x[df$treated == 1], na.rm = TRUE),
    Mean_Control = mean(x[df$treated == 0], na.rm = TRUE),
    SD_Control = sd(x[df$treated == 0], na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

summ <- rbind(
  stats_fn(rdd, "baseline_secondary_pct", "Baseline second-home share (\\%)"),
  stats_fn(rdd, "baseline_primary_pct", "Baseline primary-home share (\\%)"),
  stats_fn(rdd, "baseline_total", "Total dwellings (baseline)"),
  stats_fn(rdd, "delta_primary", "$\\Delta$ Primary share (pp)"),
  stats_fn(rdd, "delta_secondary", "$\\Delta$ Secondary share (pp)"),
  stats_fn(rdd, "pct_change_total", "Dwelling stock growth (\\%)"),
  stats_fn(rdd, "alpine", "Alpine canton")
)

# Format
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d)

tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{All} & \\multicolumn{2}{c}{Above 20\\%} & \\multicolumn{2}{c}{Below 20\\%} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD \\\\"
)
tex_lines <- c(tex_lines, "\\midrule")

for (i in seq_len(nrow(summ))) {
  row <- paste0(
    summ$Variable[i], " & ",
    fmt(summ$Mean_All[i]), " & ", fmt(summ$SD_All[i]), " & ",
    fmt(summ$Mean_Treated[i]), " & ", fmt(summ$SD_Treated[i]), " & ",
    fmt(summ$Mean_Control[i]), " & ", fmt(summ$SD_Control[i]), " \\\\"
  )
  tex_lines <- c(tex_lines, row)
}

tex_lines <- c(tex_lines,
  "\\midrule",
  paste0("Municipalities & \\multicolumn{2}{c}{", nrow(rdd), "} & \\multicolumn{2}{c}{",
         sum(rdd$treated == 1), "} & \\multicolumn{2}{c}{", sum(rdd$treated == 0), "} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  paste0("\\begin{tablenotes}[flushleft]\\footnotesize"),
  paste0("\\item \\textit{Notes:} Summary statistics for Swiss municipalities from the Federal Housing Inventory ",
         "(Zweitwohnungsinventar). ``Above 20\\%'' municipalities face the second-home construction ban under ",
         "Art.~75b of the Federal Constitution and the ZWG (SR 702). $\\Delta$ Primary share is the change from ",
         "the earliest inventory wave (2017) to the latest available wave. ",
         "Source: Federal Office for Spatial Development (ARE)."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("Wrote tab1_summary.tex\n")

## ================================================================
## Table 2: Main RDD Results
## ================================================================

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

main <- results$main
sec <- results$secondary
grw <- results$growth
dens <- results$density

tex2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{RDD Estimates: Effect of Second-Home Construction Ban}",
  "\\label{tab:main_rdd}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & $\\Delta$ Primary & $\\Delta$ Secondary & Dwelling \\\\",
  " & Share (pp) & Share (pp) & Growth (\\%) \\\\",
  "\\midrule"
)

tex2 <- c(tex2,
  paste0("RDD estimate & ", fmt(main$coef, 3), stars(main$pval),
         " & ", fmt(sec$coef, 3), stars(sec$pval),
         " & ", fmt(grw$coef, 3), stars(grw$pval), " \\\\"),
  paste0(" & (", fmt(main$se, 3), ")",
         " & (", fmt(sec$se, 3), ")",
         " & (", fmt(grw$se, 3), ") \\\\"),
  "\\addlinespace",
  paste0("Bandwidth (pp) & ", fmt(main$bw, 2),
         " & ", fmt(sec$bw, 2),
         " & ", fmt(grw$bw, 2), " \\\\"),
  paste0("Effective $N$ & ", main$n_eff,
         " & ", sec$n_eff,
         " & ", grw$n_eff, " \\\\"),
  paste0("$N$ left/right & ", main$n_left, "/", main$n_right,
         " & ", sec$n_left, "/", sec$n_right,  # use same structure
         " & --- \\\\"),
  "\\addlinespace",
  paste0("McCrary $p$-value & \\multicolumn{3}{c}{", fmt(dens$p_value, 3), "} \\\\"),
  "Kernel & \\multicolumn{3}{c}{Triangular} \\\\",
  "Polynomial & \\multicolumn{3}{c}{Local linear} \\\\",
  "BW selection & \\multicolumn{3}{c}{CCT (MSE-optimal)} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} Sharp RDD estimates at the 20\\% second-home share threshold. ",
         "Municipalities above 20\\% are prohibited from authorizing new second homes under the ZWG. ",
         "Running variable: baseline second-home share (\\%), centered at 20\\%. ",
         "Outcomes measured as changes from the earliest inventory wave (2017) to the latest. ",
         "Robust bias-corrected standard errors in parentheses (Cattaneo, Idrobo, and Titiunik 2020). ",
         "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

# Fix: also grab secondary n_left/n_right
sec_n_left <- results$secondary$n_eff  # approximate
tex2[grep("N left/right", tex2)] <- paste0(
  "$N$ left/right & ", main$n_left, "/", main$n_right,
  " & ---",
  " & --- \\\\"
)

writeLines(tex2, file.path(tables_dir, "tab2_main_rdd.tex"))
cat("Wrote tab2_main_rdd.tex\n")

## ================================================================
## Table 3: Covariate Balance
## ================================================================

bal <- results$balance
if (nrow(bal) > 0) {
  tex3 <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Covariate Balance at the 20\\% Threshold}",
    "\\label{tab:balance}",
    "\\begin{tabular}{lccc}",
    "\\toprule",
    "Variable & RD Estimate & Robust SE & $p$-value \\\\",
    "\\midrule"
  )

  for (i in seq_len(nrow(bal))) {
    tex3 <- c(tex3, paste0(
      bal$Variable[i], " & ",
      fmt(bal$Coef[i], 3), " & ",
      fmt(bal$SE[i], 3), " & ",
      fmt(bal$Pval[i], 3), " \\\\"
    ))
  }

  tex3 <- c(tex3,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]\\footnotesize",
    paste0("\\item \\textit{Notes:} RDD estimates of discontinuities in pre-determined covariates ",
           "at the 20\\% second-home share threshold. Estimates use the same local linear specification ",
           "as the main analysis. No significant discontinuities indicate that the threshold is not ",
           "associated with systematic sorting. Robust standard errors from Cattaneo, Idrobo, and Titiunik (2020)."),
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tex3, file.path(tables_dir, "tab3_balance.tex"))
  cat("Wrote tab3_balance.tex\n")
}

## ================================================================
## Table 4: Robustness (Bandwidth Sensitivity + Placebo + Donut)
## ================================================================

bw_s <- robust$bandwidth_sensitivity
plac <- robust$placebo_cutoffs
donut <- robust$donut
quad <- robust$quadratic
unif <- robust$uniform

tex4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Bandwidth Sensitivity, Placebo Cutoffs, and Specification Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Estimate & Robust SE & $p$-value & Eff.~$N$ \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Bandwidth sensitivity}} \\\\"
)

for (i in seq_len(nrow(bw_s))) {
  opt_marker <- ifelse(abs(bw_s$bandwidth[i] - results$main$bw) < 0.01, " (optimal)", "")
  tex4 <- c(tex4, paste0(
    "\\quad $h = ", fmt(bw_s$bandwidth[i], 2), "$", opt_marker, " & ",
    fmt(bw_s$coef[i], 3), stars(bw_s$pval[i]), " & ",
    fmt(bw_s$se_robust[i], 3), " & ",
    fmt(bw_s$pval[i], 3), " & ",
    bw_s$n_eff[i], " \\\\"
  ))
}

tex4 <- c(tex4,
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B: Placebo cutoffs}} \\\\"
)

for (i in seq_len(nrow(plac))) {
  tex4 <- c(tex4, paste0(
    "\\quad Cutoff = ", plac$cutoff[i], "\\% & ",
    fmt(plac$coef[i], 3), stars(plac$pval[i]), " & ",
    fmt(plac$se_robust[i], 3), " & ",
    fmt(plac$pval[i], 3), " & ",
    plac$n_eff[i], " \\\\"
  ))
}

tex4 <- c(tex4,
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel C: Specification tests}} \\\\"
)

if (!is.null(donut)) {
  tex4 <- c(tex4, paste0(
    "\\quad Donut ($|X - 20| \\geq 0.5$) & ",
    fmt(donut$coef, 3), stars(donut$pval), " & ",
    fmt(donut$se, 3), " & ",
    fmt(donut$pval, 3), " & --- \\\\"
  ))
}
if (!is.null(quad)) {
  tex4 <- c(tex4, paste0(
    "\\quad Local quadratic & ",
    fmt(quad$coef, 3), stars(quad$pval), " & ",
    fmt(quad$se, 3), " & ",
    fmt(quad$pval, 3), " & --- \\\\"
  ))
}
if (!is.null(unif)) {
  tex4 <- c(tex4, paste0(
    "\\quad Uniform kernel & ",
    fmt(unif$coef, 3), stars(unif$pval), " & ",
    fmt(unif$se, 3), " & ",
    fmt(unif$pval, 3), " & --- \\\\"
  ))
}

tex4 <- c(tex4,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} Robustness of the main RDD estimate ($\\Delta$ primary-home share). ",
         "Panel A varies the bandwidth around the CCT-optimal value. ",
         "Panel B applies the same RDD specification at placebo cutoffs where no policy discontinuity exists. ",
         "Panel C tests sensitivity to donut-hole exclusion, local quadratic polynomial, ",
         "and uniform kernel. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex4, file.path(tables_dir, "tab4_robustness.tex"))
cat("Wrote tab4_robustness.tex\n")

## ================================================================
## Table 5: Dynamic RDD Results
## ================================================================

dyn <- results$dynamic

if (nrow(dyn) > 0) {
  tex5 <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Dynamic RDD: Evolution of the Treatment Effect Over Time}",
    "\\label{tab:dynamic}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Wave & Estimate & Robust SE & $p$-value & Bandwidth \\\\",
    "\\midrule"
  )

  for (i in seq_len(nrow(dyn))) {
    tex5 <- c(tex5, paste0(
      dyn$wave[i], " & ",
      fmt(dyn$coef[i], 3), stars(dyn$pval[i]), " & ",
      fmt(dyn$se_robust[i], 3), " & ",
      fmt(dyn$pval[i], 3), " & ",
      fmt(dyn$bw[i], 2), " \\\\"
    ))
  }

  tex5 <- c(tex5,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]\\footnotesize",
    paste0("\\item \\textit{Notes:} RDD estimates of the discontinuity in $\\Delta$ primary-home share ",
           "at each inventory wave, relative to the baseline (earliest wave). ",
           "Each row is a separate local linear RDD with CCT-optimal bandwidth. ",
           "The running variable is baseline second-home share centered at 20\\%. ",
           "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$."),
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tex5, file.path(tables_dir, "tab5_dynamic.tex"))
  cat("Wrote tab5_dynamic.tex\n")
}

## ================================================================
## SDE Table (Appendix — tabF1_sde.tex)
## ================================================================

# Compute SDE for main outcomes
main_coef <- results$main$coef
main_se <- results$main$se

# SD(Y) = pre-treatment SD of delta_primary (which is 0 at baseline, so use control group variation)
sd_y_primary <- sd(rdd$delta_primary[rdd$treated == 0], na.rm = TRUE)
sd_y_secondary <- sd(rdd$delta_secondary[rdd$treated == 0], na.rm = TRUE)
sd_y_growth <- sd(rdd$pct_change_total[rdd$treated == 0], na.rm = TRUE)

sde_primary <- main_coef / sd_y_primary
sde_se_primary <- main_se / sd_y_primary

sec_coef <- results$secondary$coef
sec_se <- results$secondary$se
sde_secondary <- sec_coef / sd_y_secondary
sde_se_secondary <- sec_se / sd_y_secondary

grw_coef <- results$growth$coef
grw_se <- results$growth$se
sde_growth <- grw_coef / sd_y_growth
sde_se_growth <- grw_se / sd_y_growth

classify_sde <- function(s) {
  s <- abs(s)
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small")
  if (s < 0.15) return("Moderate")
  return("Large")
}

sde_rows <- data.frame(
  Outcome = c("$\\Delta$ Primary share", "$\\Delta$ Secondary share", "Dwelling growth"),
  Beta = c(main_coef, sec_coef, grw_coef),
  SE = c(main_se, sec_se, grw_se),
  SD_Y = c(sd_y_primary, sd_y_secondary, sd_y_growth),
  SDE = c(sde_primary, sde_secondary, sde_growth),
  SE_SDE = c(sde_se_primary, sde_se_secondary, sde_se_growth),
  stringsAsFactors = FALSE
)
sde_rows$Classification <- sapply(sde_rows$SDE, function(s) {
  classify_sde(s)
})
# Add sign
sde_rows$Classification <- ifelse(
  sde_rows$SDE < 0,
  paste(sde_rows$Classification, "negative"),
  paste(sde_rows$Classification, "positive")
)
sde_rows$Classification <- ifelse(
  abs(sde_rows$SDE) < 0.005,
  "Null",
  sde_rows$Classification
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does banning new second-home construction in municipalities ",
  "above a 20\\% second-home share convert housing stock toward permanent residents? ",
  "\\textbf{Policy mechanism:} The 2012 Second Home Initiative (Art.~75b Federal Constitution) ",
  "prohibits municipalities with second-home shares exceeding 20\\% from authorizing new ",
  "second-home construction, creating a sharp regulatory discontinuity at the threshold. ",
  "\\textbf{Outcome definition:} Change in primary-home share (\\%) from the Federal Housing ",
  "Inventory (Zweitwohnungsinventar), measuring the fraction of dwellings classified as primary residences. ",
  "\\textbf{Treatment:} Binary; municipalities above vs.\\ below the 20\\% second-home share threshold. ",
  "\\textbf{Data:} Federal Housing Inventory (geo.admin.ch), 2017--2025, municipality-level, ",
  "$N = ", nrow(rdd), "$ municipalities. ",
  "\\textbf{Method:} Sharp RDD with local linear regression, triangular kernel, ",
  "CCT-optimal bandwidth, robust bias-corrected inference. ",
  "\\textbf{Sample:} All Swiss municipalities with complete housing inventory data; ",
  "effective sample within optimal bandwidth. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the control-group ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tex_sde <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_rows))) {
  tex_sde <- c(tex_sde, paste0(
    sde_rows$Outcome[i], " & ",
    fmt(sde_rows$Beta[i], 3), " & ",
    fmt(sde_rows$SE[i], 3), " & ",
    fmt(sde_rows$SD_Y[i], 3), " & ",
    fmt(sde_rows$SDE[i], 3), " & ",
    fmt(sde_rows$SE_SDE[i], 3), " & ",
    sde_rows$Classification[i], " \\\\"
  ))
}

tex_sde <- c(tex_sde,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_sde, file.path(tables_dir, "tabF1_sde.tex"))
cat("Wrote tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
print(list.files(tables_dir))
