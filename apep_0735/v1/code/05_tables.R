# 05_tables.R — Generate all LaTeX tables
# apep_0735: ABF Monument Boundary Spatial RDD

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_sample.csv"))
results <- readRDS(file.path(data_dir, "rdd_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

stats_by_group <- df[, .(
  N = .N,
  `Price/m$^2$` = sprintf("%.0f", mean(price_per_m2)),
  `SD Price/m$^2$` = sprintf("%.0f", sd(price_per_m2)),
  `Floor Area (m$^2$)` = sprintf("%.1f", mean(surface_reelle_bati)),
  Rooms = sprintf("%.2f", mean(nombre_pieces_principales, na.rm = TRUE)),
  `Pct Apartment` = sprintf("%.1f", 100 * mean(type_local == "Appartement")),
  `Distance (m)` = sprintf("%.0f", mean(dist_to_monument))
), by = .(Group = fifelse(treated == 1, "Inside 500m (Treated)", "Outside 500m (Control)"))]

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics by ABF Zone Status}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  paste0(" & ", stats_by_group$Group[1], " & ", stats_by_group$Group[2], " \\\\"),
  "\\midrule",
  paste0("N & ", format(stats_by_group$N[1], big.mark = ","), " & ",
         format(stats_by_group$N[2], big.mark = ","), " \\\\"),
  paste0("Mean Price/m$^2$ (\\euro) & ", stats_by_group$`Price/m$^2$`[1], " & ",
         stats_by_group$`Price/m$^2$`[2], " \\\\"),
  paste0("SD Price/m$^2$ (\\euro) & ", stats_by_group$`SD Price/m$^2$`[1], " & ",
         stats_by_group$`SD Price/m$^2$`[2], " \\\\"),
  paste0("Floor Area (m$^2$) & ", stats_by_group$`Floor Area (m$^2$)`[1], " & ",
         stats_by_group$`Floor Area (m$^2$)`[2], " \\\\"),
  paste0("Rooms & ", stats_by_group$Rooms[1], " & ",
         stats_by_group$Rooms[2], " \\\\"),
  paste0("Apartment (\\%) & ", stats_by_group$`Pct Apartment`[1], " & ",
         stats_by_group$`Pct Apartment`[2], " \\\\"),
  paste0("Mean Distance to Monument (m) & ", stats_by_group$`Distance (m)`[1], " & ",
         stats_by_group$`Distance (m)`[2], " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Sample includes all residential property sales (apartments and houses) within 1,000 meters of a classified or registered historic monument in metropolitan France, 2020--2024. Data from DVF (Demandes de Valeurs Fonci\\`eres). Treatment assignment based on 500-meter ABF regulatory boundary.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main RDD Results
# ============================================================
cat("Generating Table 2: Main RDD Results\n")

main <- results$main
bw_sens <- results$bandwidth

# Build rows for bandwidth sensitivity
bw_rows <- character(0)
for (i in seq_len(nrow(bw_sens))) {
  stars <- ""
  if (!is.na(bw_sens$pval[i])) {
    if (bw_sens$pval[i] < 0.01) stars <- "$^{***}$"
    else if (bw_sens$pval[i] < 0.05) stars <- "$^{**}$"
    else if (bw_sens$pval[i] < 0.1) stars <- "$^{*}$"
  }
  bw_rows <- c(bw_rows, paste0(
    bw_sens$bandwidth[i], " & ",
    sprintf("%.4f", bw_sens$estimate[i]), stars, " & ",
    "(", sprintf("%.4f", bw_sens$se_robust[i]), ") & ",
    format(bw_sens$n_left[i] + bw_sens$n_right[i], big.mark = ","), " \\\\"
  ))
}

# Stars for main estimate
main_stars <- ""
if (!is.na(main$pval)) {
  if (main$pval < 0.01) main_stars <- "$^{***}$"
  else if (main$pval < 0.05) main_stars <- "$^{**}$"
  else if (main$pval < 0.1) main_stars <- "$^{*}$"
}

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{RDD Estimates: Effect of ABF Zone on Log Property Price per m$^2$}",
  "\\label{tab:main_rdd}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Bandwidth (m) & Bias-Corrected Estimate & Robust SE & Effective N \\\\",
  "\\midrule",
  paste0("\\textit{CCT Optimal: ", round(main$bw), "} & ",
         sprintf("%.4f", main$tau_bc), main_stars, " & ",
         "(", sprintf("%.4f", main$se_robust), ") & ",
         format(main$n_left + main$n_right, big.mark = ","), " \\\\"),
  "\\midrule",
  "\\textit{Bandwidth Sensitivity:} & & & \\\\",
  bw_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Local linear regression discontinuity estimates with triangular kernel. Dependent variable is log price per square meter. The cutoff is 500 meters from the nearest historic monument (ABF regulatory boundary). Bias-corrected estimates and robust standard errors following \\citet{CattaneoEtAl2014}. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main_rdd.tex"))

# ============================================================
# Table 3: Validity Tests
# ============================================================
cat("Generating Table 3: Validity Tests\n")

bal <- results$balance
donut <- results$donut

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{RDD Validity Tests}",
  "\\label{tab:validity}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & & & & \\\\",
  "\\multicolumn{5}{l}{\\textit{Panel A: McCrary Density Test}} \\\\",
  "\\midrule",
  paste0("Manipulation test $p$-value & \\multicolumn{4}{c}{",
         sprintf("%.3f", results$density_pval), "} \\\\"),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Covariate Balance at 500m Cutoff}} \\\\",
  "\\midrule",
  "Covariate & Estimate & Robust SE & $p$-value & \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(bal))) {
  tab3_lines <- c(tab3_lines, paste0(
    bal$Covariate[i], " & ",
    sprintf("%.3f", bal$Estimate[i]), " & ",
    sprintf("%.3f", bal$SE[i]), " & ",
    sprintf("%.3f", bal$pval[i]), " & \\\\"
  ))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel C: Donut Hole Tests}} \\\\",
  "\\midrule",
  "Exclusion Window (m) & Estimate & Robust SE & $p$-value & N \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(donut))) {
  donut_stars <- ""
  if (!is.na(donut$pval[i])) {
    if (donut$pval[i] < 0.01) donut_stars <- "$^{***}$"
    else if (donut$pval[i] < 0.05) donut_stars <- "$^{**}$"
    else if (donut$pval[i] < 0.1) donut_stars <- "$^{*}$"
  }
  tab3_lines <- c(tab3_lines, paste0(
    "$\\pm$", donut$donut_m[i], " & ",
    sprintf("%.4f", donut$estimate[i]), donut_stars, " & ",
    sprintf("%.4f", donut$se_robust[i]), " & ",
    sprintf("%.3f", donut$pval[i]), " & ",
    format(donut$n_eff[i], big.mark = ","), " \\\\"
  ))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports the \\citet{McCrary2008} density test for manipulation of the running variable (distance to nearest monument) at the 500-meter cutoff. Panel B tests for discontinuities in pre-determined property characteristics. Panel C removes transactions within a symmetric window around the 500m cutoff.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_validity.tex"))

# ============================================================
# Table 4: Placebo Cutoffs
# ============================================================
cat("Generating Table 4: Placebo Cutoffs\n")

placebo <- results$placebo

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Placebo Cutoff Tests}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Cutoff (m) & Bias-Corrected Estimate & Robust SE & $p$-value \\\\",
  "\\midrule",
  paste0("500 (actual) & ", sprintf("%.4f", main$tau_bc), main_stars,
         " & (", sprintf("%.4f", main$se_robust), ") & ",
         sprintf("%.3f", main$pval), " \\\\"),
  "\\midrule"
)

for (i in seq_len(nrow(placebo))) {
  p_stars <- ""
  if (!is.na(placebo$pval[i])) {
    if (placebo$pval[i] < 0.01) p_stars <- "$^{***}$"
    else if (placebo$pval[i] < 0.05) p_stars <- "$^{**}$"
    else if (placebo$pval[i] < 0.1) p_stars <- "$^{*}$"
  }
  tab4_lines <- c(tab4_lines, paste0(
    placebo$cutoff[i], " & ",
    sprintf("%.4f", placebo$estimate[i]), p_stars, " & ",
    "(", sprintf("%.4f", placebo$se_robust[i]), ") & ",
    sprintf("%.3f", placebo$pval[i]), " \\\\"
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} RDD estimates at placebo cutoffs where no regulatory boundary exists. Specifications mirror the main analysis (local linear, triangular kernel, CCT optimal bandwidth). The absence of significant effects at non-500m cutoffs supports the identifying assumption.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_placebo.tex"))

# ============================================================
# Table 5: Heterogeneity
# ============================================================
cat("Generating Table 5: Heterogeneity\n")

# Re-run heterogeneity for table generation
het_results <- list()

# By monument type
for (mtype in c("classe", "inscrit")) {
  sub <- df[monument_type == mtype]
  if (nrow(sub) < 500) next
  rdd_h <- rdrobust(y = sub$log_price_m2, x = sub$dist_to_monument,
                     c = 500, kernel = "triangular", p = 1, bwselect = "mserd")
  het_results[[mtype]] <- list(
    label = if (mtype == "classe") "Class\\'{e}" else "Inscrit",
    est = rdd_h$coef[2], se = rdd_h$se[3], pval = rdd_h$pv[3],
    n = rdd_h$N[1] + rdd_h$N[2]
  )
}

# By property type
for (ptype in c("Appartement", "Maison")) {
  sub <- df[type_local == ptype]
  if (nrow(sub) < 500) next
  rdd_h <- rdrobust(y = sub$log_price_m2, x = sub$dist_to_monument,
                     c = 500, kernel = "triangular", p = 1, bwselect = "mserd")
  het_results[[ptype]] <- list(
    label = ptype,
    est = rdd_h$coef[2], se = rdd_h$se[3], pval = rdd_h$pv[3],
    n = rdd_h$N[1] + rdd_h$N[2]
  )
}

# By region
df[, ile_de_france := dept %in% c("75", "77", "78", "91", "92", "93", "94", "95")]
for (region in c(TRUE, FALSE)) {
  label <- if (region) "\\^Ile-de-France" else "Province"
  sub <- df[ile_de_france == region]
  if (nrow(sub) < 500) next
  rdd_h <- rdrobust(y = sub$log_price_m2, x = sub$dist_to_monument,
                     c = 500, kernel = "triangular", p = 1, bwselect = "mserd")
  het_results[[label]] <- list(
    label = label,
    est = rdd_h$coef[2], se = rdd_h$se[3], pval = rdd_h$pv[3],
    n = rdd_h$N[1] + rdd_h$N[2]
  )
}

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity in ABF Zone Premium}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Subsample & Estimate & Robust SE & N \\\\",
  "\\midrule",
  paste0("\\textit{Full sample} & ", sprintf("%.4f", main$tau_bc), main_stars,
         " & (", sprintf("%.4f", main$se_robust), ") & ",
         format(main$n_left + main$n_right, big.mark = ","), " \\\\"),
  "\\midrule",
  "\\textit{By Monument Type:} & & & \\\\"
)

for (key in names(het_results)) {
  h <- het_results[[key]]
  h_stars <- ""
  if (!is.na(h$pval)) {
    if (h$pval < 0.01) h_stars <- "$^{***}$"
    else if (h$pval < 0.05) h_stars <- "$^{**}$"
    else if (h$pval < 0.1) h_stars <- "$^{*}$"
  }

  # Add section headers
  if (key == "Appartement") {
    tab5_lines <- c(tab5_lines, "\\midrule", "\\textit{By Property Type:} & & & \\\\")
  }
  if (key == "\\^Ile-de-France") {
    tab5_lines <- c(tab5_lines, "\\midrule", "\\textit{By Region:} & & & \\\\")
  }

  tab5_lines <- c(tab5_lines, paste0(
    "\\quad ", h$label, " & ",
    sprintf("%.4f", h$est), h_stars, " & ",
    "(", sprintf("%.4f", h$se), ") & ",
    format(h$n, big.mark = ","), " \\\\"
  ))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications use local linear RDD with triangular kernel and CCT optimal bandwidth. Dependent variable is log price per square meter. Class\\'{e} monuments have the highest protection status. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_heterogeneity.tex"))

# ============================================================
# SDE Table (Appendix F1)
# ============================================================
cat("Generating SDE Table\n")

# Compute SDE for main outcome
sde_main <- results$main$tau_bc / results$sd_y
se_sde_main <- results$main$se_robust / results$sd_y

# Classify
classify_sde <- function(sde) {
  if (is.na(sde)) return("NA")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_class <- classify_sde(sde_main)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does binding architectural review by Architectes des B\\^{a}timents de France within 500 meters of historic monuments affect residential property prices? ",
  "\\textbf{Policy mechanism:} Since 1943, all construction within 500 meters of a classified or registered historic monument requires binding ABF advisory opinion, creating aesthetic gatekeeping that can delay, modify, or block development projects. ",
  "\\textbf{Outcome definition:} Log price per square meter of residential property (apartments and houses) from DVF transaction records. ",
  "\\textbf{Treatment:} Binary; property located inside (vs.~outside) the 500-meter ABF regulatory perimeter. ",
  "\\textbf{Data:} DVF (Demandes de Valeurs Fonci\\`eres) geolocated property transactions, 2020--2024, matched to 46,700+ monuments from the Monuments Historiques database. ",
  "\\textbf{Method:} Local linear spatial RDD at 500m cutoff, triangular kernel, CCT optimal bandwidth, robust bias-corrected inference. ",
  "\\textbf{Sample:} Residential sales (apartments, houses) in metropolitan France within 1,000m of a monument; outlier-trimmed on price per m$^2$ (200--30,000\\euro) and floor area (9--500 m$^2$). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the sample standard deviation of log price per m$^2$. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  paste0("Log Price/m$^2$ & ",
         sprintf("%.4f", results$main$tau_bc), " & ",
         sprintf("%.4f", results$main$se_robust), " & ",
         sprintf("%.3f", results$sd_y), " & ",
         sprintf("%.3f", sde_main), " & ",
         sprintf("%.3f", se_sde_main), " & ",
         sde_class, " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
