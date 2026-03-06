## 06_tables.R — Generate all publication-quality tables
## APEP-0538: ZFE Housing Price Capitalization

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

## =========================================================================
## Table 1: Summary statistics
## =========================================================================

cat("=== Table 1: Summary statistics ===\n")

dvf <- fread(file.path(data_dir, "dvf_boundary_2km.csv"))
dvf_res <- dvf[property_type %in% c("house", "apartment")]

## Summary by inside/outside ZFE
summ_func <- function(dt, label) {
  data.table(
    group = label,
    n_transactions = format(nrow(dt), big.mark = ","),
    mean_price_m2 = round(mean(dt$price_m2, na.rm = TRUE)),
    sd_price_m2 = round(sd(dt$price_m2, na.rm = TRUE)),
    median_price_m2 = round(median(dt$price_m2, na.rm = TRUE)),
    mean_surface = round(mean(dt$surface, na.rm = TRUE), 1),
    mean_rooms = round(mean(dt$nombre_pieces_principales, na.rm = TRUE), 1),
    pct_apartment = round(mean(dt$property_type == "apartment", na.rm = TRUE) * 100, 1),
    n_cities = dt[, uniqueN(city)],
    n_communes = dt[, uniqueN(code_commune)]
  )
}

summ_table <- rbind(
  summ_func(dvf_res, "Full sample"),
  summ_func(dvf_res[inside_zfe == 1], "Inside ZFE"),
  summ_func(dvf_res[inside_zfe == 0], "Outside ZFE"),
  summ_func(dvf_res[inside_zfe == 1 & post_zfe == 1], "Inside x Post"),
  summ_func(dvf_res[inside_zfe == 0 | post_zfe == 0], "Control group")
)

fwrite(summ_table, file.path(tab_dir, "table1_summary.csv"))

## LaTeX output
sink(file.path(tab_dir, "table1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Residential Transactions within 2km of ZFE Boundaries}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lrrrrrrrr}\n")
cat("\\hline\\hline\n")
cat(" & N & Mean & SD & Median & Surface & Rooms & \\% Apt & Cities \\\\\n")
cat(" & & Price/m\\textsuperscript{2} & & Price/m\\textsuperscript{2} & (m\\textsuperscript{2}) & & & \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(summ_table)) {
  cat(summ_table$group[i], " & ",
      summ_table$n_transactions[i], " & ",
      summ_table$mean_price_m2[i], " & ",
      summ_table$sd_price_m2[i], " & ",
      summ_table$median_price_m2[i], " & ",
      summ_table$mean_surface[i], " & ",
      summ_table$mean_rooms[i], " & ",
      summ_table$pct_apartment[i], " & ",
      summ_table$n_cities[i], " \\\\\n")
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small \\textit{Notes:} Sample includes residential transactions (apartments and houses) within 2km of ZFE boundaries in 9 French metropolitan areas with matched boundary data, 2020--2024. Price/m\\textsuperscript{2} is transaction price divided by built surface area. Source: DVF (Demandes de Valeurs Fonci\\`eres).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  Saved table1_summary\n")

## =========================================================================
## Table 2: Main results
## =========================================================================

cat("=== Table 2: Main results ===\n")

main <- fread(file.path(data_dir, "main_results.csv"))

sink(file.path(tab_dir, "table2_main_results.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Main Results: Effect of ZFE on Residential Housing Prices}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat(" & Basic & Hedonic & City$\\times$Time & Commune & 1km BW \\\\\n")
cat("\\hline\n")
cat("Inside ZFE $\\times$ Post")
for (i in 1:nrow(main)) {
  stars <- ""
  if (main$pval[i] < 0.01) stars <- "***"
  else if (main$pval[i] < 0.05) stars <- "**"
  else if (main$pval[i] < 0.1) stars <- "*"
  cat(" & ", sprintf("%.4f%s", main$coef[i], stars))
}
cat(" \\\\\n")
cat(" ")
for (i in 1:nrow(main)) {
  cat(" & (", sprintf("%.4f", main$se[i]), ")")
}
cat(" \\\\\n")
cat("\\hline\n")
cat("Hedonic controls & No & Yes & Yes & Yes & Yes \\\\\n")
cat("City FE & Yes & Yes & -- & -- & -- \\\\\n")
cat("Year-Quarter FE & Yes & Yes & -- & Yes & Yes \\\\\n")
cat("City $\\times$ Year-Quarter FE & No & No & Yes & No & No \\\\\n")
cat("Commune FE & No & No & No & Yes & Yes \\\\\n")
cat("Bandwidth (km) & 2 & 2 & 2 & 2 & 1 \\\\\n")
cat("Observations")
for (i in 1:nrow(main)) {
  cat(" & ", format(main$n_obs[i], big.mark = ","))
}
cat(" \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small \\textit{Notes:} Dependent variable is log(price/m\\textsuperscript{2}). Sample includes residential transactions within the specified bandwidth of ZFE boundaries. Hedonic controls include surface area and number of rooms. Standard errors clustered at the commune level in parentheses. * $p<0.1$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  Saved table2_main_results\n")

## =========================================================================
## Table 3: Robustness
## =========================================================================

cat("=== Table 3: Robustness ===\n")

bw <- fread(file.path(data_dir, "robustness_bandwidth.csv"))
donut <- tryCatch(fread(file.path(data_dir, "robustness_donut.csv")), error = function(e) NULL)
placebo <- tryCatch(fread(file.path(data_dir, "placebo_commercial.csv")), error = function(e) NULL)
ri <- tryCatch(fread(file.path(data_dir, "randomization_inference.csv")), error = function(e) NULL)

robust_rows <- list()
for (i in 1:nrow(bw)) {
  robust_rows[[length(robust_rows) + 1]] <- data.table(
    spec = paste0("Bandwidth = ", bw$bandwidth_km[i], "km"),
    coef = bw$coef[i], se = bw$se[i], n = bw$n_obs[i]
  )
}
if (!is.null(donut)) {
  robust_rows[[length(robust_rows) + 1]] <- data.table(
    spec = donut$spec, coef = donut$coef, se = donut$se, n = donut$n_obs
  )
}
if (!is.null(placebo)) {
  robust_rows[[length(robust_rows) + 1]] <- data.table(
    spec = "Placebo: Commercial properties", coef = placebo$coef, se = placebo$se, n = placebo$n
  )
}

robust_table <- rbindlist(robust_rows)
robust_table[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(robust_table, file.path(tab_dir, "table3_robustness.csv"))

sink(file.path(tab_dir, "table3_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Specification & Coefficient & SE & N \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(robust_table)) {
  stars <- ""
  if (robust_table$pval[i] < 0.01) stars <- "***"
  else if (robust_table$pval[i] < 0.05) stars <- "**"
  else if (robust_table$pval[i] < 0.1) stars <- "*"
  cat(robust_table$spec[i], " & ",
      sprintf("%.4f%s", robust_table$coef[i], stars), " & ",
      sprintf("(%.4f)", robust_table$se[i]), " & ",
      format(robust_table$n[i], big.mark = ","), " \\\\\n")
}
cat("\\hline\n")
if (!is.null(ri)) {
  cat("\\multicolumn{4}{l}{Randomization inference $p$-value: ",
      sprintf("%.3f", ri$ri_pval), " (", ri$n_perms, " permutations)} \\\\\n")
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small \\textit{Notes:} All bandwidth specifications use city and year-quarter fixed effects (not commune FE), and hedonic controls (surface area, number of rooms). Coefficients may differ from Table~\\ref{tab:main} where commune FE are used. The dependent variable is log(price/m\\textsuperscript{2}) for residential transactions. Standard errors clustered at the commune level. The placebo test uses commercial and industrial properties within 2km of ZFE boundaries. * $p<0.1$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  Saved table3_robustness\n")

## =========================================================================
## Table 4: First stage (air quality)
## =========================================================================

cat("=== Table 4: First stage ===\n")

fs <- fread(file.path(data_dir, "first_stage_results.csv"))

sink(file.path(tab_dir, "table4_first_stage.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{First Stage: ZFE Adoption and Air Quality}\n")
cat("\\label{tab:firststage}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) \\\\\n")
cat(" & NO\\textsubscript{2} ($\\mu$g/m\\textsuperscript{3}) & PM\\textsubscript{2.5} ($\\mu$g/m\\textsuperscript{3}) \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(fs)) {
  stars <- ""
  if (fs$pval[i] < 0.01) stars <- "***"
  else if (fs$pval[i] < 0.05) stars <- "**"
  else if (fs$pval[i] < 0.1) stars <- "*"
  if (i == 1) cat("Post ZFE")
  cat(" & ", sprintf("%.2f%s", fs$coef[i], stars))
}
cat(" \\\\\n")
for (i in 1:nrow(fs)) {
  if (i == 1) cat(" ")
  cat(" & (", sprintf("%.2f", fs$se[i]), ")")
}
cat(" \\\\\n")
cat("\\hline\n")
cat("City FE & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes \\\\\n")
cat("Month-of-year FE & Yes & Yes \\\\\n")
cat("Observations")
for (i in 1:nrow(fs)) {
  if ("n_obs" %in% names(fs)) {
    cat(" & ", format(fs$n_obs[i], big.mark = ","))
  } else {
    cat(" & --")
  }
}
cat(" \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small \\textit{Notes:} Unit of observation is city-month for the 9 cities in the boundary sample, 2020--2024. Dependent variable is mean monthly concentration. Data from CAMS reanalysis via Open-Meteo API. * $p<0.1$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  Saved table4_first_stage\n")

cat("\n=== All tables generated ===\n")
