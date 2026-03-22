## 05_tables.R — Generate all LaTeX tables including SDE
## APEP-0740: QPV Designation Paradox

source("00_packages.R")
script_dir <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) ".")
setwd(file.path(script_dir, ".."))
data_dir <- "data"
table_dir <- "tables"
dir.create(table_dir, showWarnings = FALSE)

cat("=== Loading results ===\n")
results <- readRDS(file.path(data_dir, "rdd_results.rds"))
df <- data.table::fread(file.path(data_dir, "analysis_data.csv"))
post <- df  ## All data is post-QPV (2020-2024)

## ======================================================================
## Table 1: Summary Statistics
## ======================================================================
cat("\n=== Table 1: Summary Statistics ===\n")

## Within 500m bandwidth
bw500 <- post[abs(signed_dist) <= 500]
inside <- bw500[inside_qpv == TRUE]
outside <- bw500[inside_qpv == FALSE]

make_stats <- function(d, label) {
  data.table::data.table(
    Panel = label,
    N = format(nrow(d), big.mark = ","),
    `Price/m2` = sprintf("%.0f", mean(d$price_m2, na.rm = TRUE)),
    `SD Price/m2` = sprintf("%.0f", sd(d$price_m2, na.rm = TRUE)),
    `Surface (m2)` = sprintf("%.1f", mean(d$surface, na.rm = TRUE)),
    Rooms = sprintf("%.1f", mean(d$rooms, na.rm = TRUE)),
    `Apt. share` = sprintf("%.3f", mean(d$is_apartment, na.rm = TRUE))
  )
}

stats_tbl <- rbind(
  make_stats(bw500, "All (500m)"),
  make_stats(inside, "Inside QPV"),
  make_stats(outside, "Outside QPV")
)

## Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Property Transactions Within 500m of QPV Boundaries}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  " & N & Mean Price/m\\textsuperscript{2} & SD Price/m\\textsuperscript{2} & Surface (m\\textsuperscript{2}) & Rooms & Apt.\\ Share \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(stats_tbl))) {
  row <- stats_tbl[i]
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            row$Panel, row$N, row$`Price/m2`, row$`SD Price/m2`,
            row$`Surface (m2)`, row$Rooms, row$`Apt. share`))
  if (i == 1) tab1_lines <- c(tab1_lines, "\\midrule")
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Sample restricted to apartments and houses transacted within 500 meters of the nearest QPV boundary, 2020--2024. Price per square meter computed as transaction price divided by built surface area. Transactions below 100 EUR/m\\textsuperscript{2} or above 30,000 EUR/m\\textsuperscript{2} excluded.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))
cat("Wrote tab1_summary.tex\n")

## ======================================================================
## Table 2: Main RDD Results
## ======================================================================
cat("\n=== Table 2: Main RDD Results ===\n")

m <- results$main
mc <- results$covariates
mp <- results$parametric

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Main RDD Estimates: Effect of QPV Designation on Log Property Prices}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Nonparametric & With Covariates & Parametric \\\\",
  "\\midrule",
  sprintf("Inside QPV & %.4f & %.4f & %.4f \\\\", m$tau_bc, mc$tau_bc, mp$tau),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\", m$se_robust, mc$se_robust, mp$se),
  "\\midrule",
  sprintf("Bandwidth (m) & %.0f & %.0f & 500 \\\\", m$bw, mc$bw),
  sprintf("N (left + right) & %s & --- & %s \\\\",
          format(m$n_left + m$n_right, big.mark = ","),
          format(mp$n, big.mark = ",")),
  "Kernel & Triangular & Triangular & --- \\\\",
  "Covariates & No & Yes & Yes \\\\",
  "Boundary FE & No & No & Yes \\\\",
  "Year-Quarter FE & No & No & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log price per square meter. Columns (1)--(2) report bias-corrected RDD estimates with robust standard errors clustered at the commune level (Calonico, Cattaneo, and Titiunik 2014). Column (3) reports OLS with a local linear polynomial in signed distance interacted with the QPV indicator, boundary-segment fixed effects, and year-quarter fixed effects. Covariates include surface area, number of rooms, and an apartment indicator.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))
cat("Wrote tab2_main.tex\n")

## ======================================================================
## Table 3: Bandwidth Robustness + Donut
## ======================================================================
cat("\n=== Table 3: Robustness ===\n")

bw_res <- results$bandwidth_robustness
donut_res <- results$donut

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Bandwidth Sensitivity and Donut Hole}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & 250m & 500m & 750m & 1000m & MSE-Opt. & Donut (50m) \\\\",
  "\\midrule"
)

## Estimates row
est_vals <- sapply(c("250", "500", "750", "1000"), function(b) {
  r <- bw_res[[b]]
  if (!is.null(r)) sprintf("%.4f", r$tau_bc) else "---"
})
est_vals <- c(est_vals,
              sprintf("%.4f", m$tau_bc),
              if (!is.null(donut_res)) sprintf("%.4f", donut_res$tau_bc) else "---")
tab3_lines <- c(tab3_lines, sprintf("Inside QPV & %s \\\\", paste(est_vals, collapse = " & ")))

## SE row
se_vals <- sapply(c("250", "500", "750", "1000"), function(b) {
  r <- bw_res[[b]]
  if (!is.null(r)) sprintf("(%.4f)", r$se_robust) else ""
})
se_vals <- c(se_vals,
             sprintf("(%.4f)", m$se_robust),
             if (!is.null(donut_res)) sprintf("(%.4f)", donut_res$se_robust) else "")
tab3_lines <- c(tab3_lines, sprintf(" & %s \\\\", paste(se_vals, collapse = " & ")))

## N row
n_vals <- sapply(c("250", "500", "750", "1000"), function(b) {
  r <- bw_res[[b]]
  if (!is.null(r)) format(r$n_left + r$n_right, big.mark = ",") else "---"
})
n_vals <- c(n_vals,
            format(m$n_left + m$n_right, big.mark = ","),
            "---")
tab3_lines <- c(tab3_lines, "\\midrule",
                sprintf("N & %s \\\\", paste(n_vals, collapse = " & ")))

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All columns report bias-corrected RDD estimates with robust standard errors clustered at the commune level. Donut column excludes transactions within 50 meters of the QPV boundary.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_robustness.tex"))
cat("Wrote tab3_robustness.tex\n")

## ======================================================================
## Table 4: Validity (McCrary + Balance + Placebos)
## ======================================================================
cat("\n=== Table 4: Validity ===\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Validity Checks: Density, Covariate Balance, and Placebos}",
  "\\label{tab:validity}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Estimate & $p$-value \\\\",
  "\\midrule",
  "\\textit{Panel A: McCrary Density Test} & & \\\\",
  sprintf("Discontinuity in density & & %.3f \\\\", results$mccrary$p_value),
  "\\midrule",
  "\\textit{Panel B: Covariate Balance} & & \\\\"
)

if (!is.null(results$balance) && nrow(results$balance) > 0) {
  for (i in seq_len(nrow(results$balance))) {
    row <- results$balance[i]
    vname <- switch(row$variable,
      surface = "Surface area (m$^2$)",
      rooms = "Number of rooms",
      is_apartment = "Apartment indicator",
      price = "Transaction price",
      row$variable
    )
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %.4f & %.3f \\\\", vname, row$estimate, row$pvalue))
  }
}

tab4_lines <- c(tab4_lines, "\\midrule",
  "\\textit{Panel C: Placebo Tests} & & \\\\")

if (!is.null(results$placebo_pre)) {
  tab4_lines <- c(tab4_lines,
    sprintf("Pre-QPV period (2014) & %.4f & %.3f \\\\",
            results$placebo_pre$tau_bc, results$placebo_pre$pval))
}

for (pc_name in names(results$placebo_cutoffs)) {
  pc <- results$placebo_cutoffs[[pc_name]]
  tab4_lines <- c(tab4_lines,
    sprintf("Placebo cutoff at %+dm & %.4f & %.3f \\\\",
            pc$cutoff, pc$tau_bc, pc$pval))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports the Cattaneo, Jansson, and Ma (2020) manipulation test. Panel B tests for discontinuities in pre-determined property characteristics at the QPV boundary using the main RDD specification. Panel C tests for effects at the real boundary in the pre-QPV period (2014) and at placebo cutoffs where no treatment discontinuity exists.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_validity.tex"))
cat("Wrote tab4_validity.tex\n")

## ======================================================================
## Table 5: Heterogeneity (Property Type + Period)
## ======================================================================
cat("\n=== Table 5: Heterogeneity ===\n")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Property Type and Period}",
  "\\label{tab:hetero}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Apartments & Houses & 2020--2021 & 2022--2024 \\\\",
  "\\midrule"
)

## Estimates
est_h <- c(
  if (!is.null(results$type_appartement)) sprintf("%.4f", results$type_appartement$tau_bc) else "---",
  if (!is.null(results$type_maison)) sprintf("%.4f", results$type_maison$tau_bc) else "---",
  if (!is.null(results$period_2020_2021)) sprintf("%.4f", results$period_2020_2021$tau_bc) else "---",
  if (!is.null(results$period_2022_2024)) sprintf("%.4f", results$period_2022_2024$tau_bc) else "---"
)
tab5_lines <- c(tab5_lines, sprintf("Inside QPV & %s \\\\", paste(est_h, collapse = " & ")))

## SEs
se_h <- c(
  if (!is.null(results$type_appartement)) sprintf("(%.4f)", results$type_appartement$se_robust) else "",
  if (!is.null(results$type_maison)) sprintf("(%.4f)", results$type_maison$se_robust) else "",
  if (!is.null(results$period_2020_2021)) sprintf("(%.4f)", results$period_2020_2021$se_robust) else "",
  if (!is.null(results$period_2022_2024)) sprintf("(%.4f)", results$period_2022_2024$se_robust) else ""
)
tab5_lines <- c(tab5_lines, sprintf(" & %s \\\\", paste(se_h, collapse = " & ")))

## N
n_h <- c(
  if (!is.null(results$type_appartement))
    format(results$type_appartement$n_left + results$type_appartement$n_right, big.mark = ",") else "---",
  if (!is.null(results$type_maison))
    format(results$type_maison$n_left + results$type_maison$n_right, big.mark = ",") else "---",
  "---", "---"
)
tab5_lines <- c(tab5_lines, "\\midrule",
  sprintf("N & %s \\\\", paste(n_h, collapse = " & ")))

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All columns report bias-corrected RDD estimates with MSE-optimal bandwidth and robust standard errors clustered at the commune level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(table_dir, "tab5_hetero.tex"))
cat("Wrote tab5_hetero.tex\n")

## ======================================================================
## SDE Appendix Table (tabF1_sde.tex)
## ======================================================================
cat("\n=== SDE Table ===\n")

## Compute SDE for main outcome
## SDE = beta_hat / SD(Y)
## Use the SD of log price/m2 among outside-QPV properties (control group SD)
pre_sd <- sd(post[inside_qpv == FALSE]$log_price_m2, na.rm = TRUE)
if (is.na(pre_sd) || pre_sd == 0) {
  pre_sd <- sd(post$log_price_m2, na.rm = TRUE)
}

tau <- results$main$tau_bc
se_tau <- results$main$se_robust

sde <- tau / pre_sd
se_sde <- se_tau / pre_sd

## Classification
classify_sde <- function(x) {
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x <= 0.005) return("Null")
  if (x <= 0.05) return("Small positive")
  if (x <= 0.15) return("Moderate positive")
  return("Large positive")
}

class_main <- classify_sde(sde)

## SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does official designation as a Quartier Prioritaire de la Politique de la Ville (QPV) ",
  "increase or decrease local property values at the boundary? ",
  "\\textbf{Policy mechanism:} QPV designation triggers a bundle of place-based policies including ",
  "a 30\\% property tax reduction (TFPB), reduced VAT at 5.5\\% for new construction within and near the boundary, ",
  "corporate tax exemptions, and eligibility for ANRU/NPNRU urban renewal investment totaling 12 billion euros. ",
  "Designation also labels the neighborhood as disadvantaged, potentially creating stigma. ",
  "\\textbf{Outcome definition:} Log price per square meter of residential property transactions from DVF geolocalized data. ",
  "\\textbf{Treatment:} Binary; a property is inside or outside the QPV boundary polygon. ",
  "\\textbf{Data:} DVF geolocalized transactions (data.gouv.fr), 2020--2024, unit of observation is individual property transaction, ",
  sprintf("within MSE-optimal bandwidth of %.0f meters, N = %s. ", results$main$bw, format(results$main$n_left + results$main$n_right, big.mark = ",")),
  "\\textbf{Method:} Local linear RDD with triangular kernel and MSE-optimal bandwidth (Calonico, Cattaneo, and Titiunik 2014); ",
  "standard errors clustered at the commune level. ",
  "\\textbf{Sample:} Residential sales (apartments and houses) within the bandwidth of the nearest QPV boundary; ",
  "transactions below 100 EUR/m$^2$ or above 30,000 EUR/m$^2$ excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the ",
  "standard deviation of log price per square meter among control (outside-QPV) properties. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log price/m$^2$ & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          tau, se_tau, pre_sd, sde, se_sde, class_main),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("Wrote tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
