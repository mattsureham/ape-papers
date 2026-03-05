## 06_tables.R — All tables (LaTeX output)
## APEP-0528: Do Administrative Borders Tax Electricity?

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

# ===========================================================================
# Table 1: Descriptive Statistics
# ===========================================================================
cat("=== Table 1: Descriptive Statistics ===\n")

panel <- fread(file.path(data_dir, "panel.csv"))
reform_dates <- fread(file.path(data_dir, "reform_dates.csv"))
reform_cantons_vec <- reform_dates$canton

# Summary for all, reform, and non-reform municipalities
make_summary <- function(dt, label) {
  dt[, .(
    Label = label,
    N_obs = .N,
    N_mun = uniqueN(mun_id),
    N_years = uniqueN(year),
    Mean_total = round(mean(total, na.rm = TRUE), 2),
    SD_total = round(sd(total, na.rm = TRUE), 2),
    Mean_energy = round(mean(energy, na.rm = TRUE), 2),
    Mean_grid = round(mean(gridusage, na.rm = TRUE), 2),
    Mean_aidfee = round(mean(aidfee, na.rm = TRUE), 2),
    Mean_charge = round(mean(charge, na.rm = TRUE), 2)
  )]
}

desc_all <- make_summary(panel[!is.na(canton)], "All municipalities")
desc_reform <- make_summary(panel[canton %in% reform_cantons_vec], "Reform cantons")
desc_control <- make_summary(panel[!canton %in% reform_cantons_vec & !is.na(canton)], "Non-reform cantons")
desc_border <- make_summary(panel[dist_to_border_km <= 15 & !is.na(canton)], "Border sample (15km)")

desc_table <- rbind(desc_all, desc_reform, desc_control, desc_border)

# Write LaTeX
tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Descriptive Statistics: Electricity Tariffs by Reform Status}",
  "\\label{tab:desc_stats}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lrrrrrrrrr}",
  "\\toprule",
  " & Obs. & Mun. & Years & \\multicolumn{2}{c}{Total Tariff} & Energy & Grid & Aid Fee & Charges \\\\",
  " & & & & Mean & SD & Mean & Mean & Mean & Mean \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(desc_table))) {
  r <- desc_table[i]
  tex_lines <- c(tex_lines, paste0(
    r$Label, " & ",
    format(r$N_obs, big.mark = ","), " & ",
    format(r$N_mun, big.mark = ","), " & ",
    r$N_years, " & ",
    r$Mean_total, " & ",
    r$SD_total, " & ",
    r$Mean_energy, " & ",
    r$Mean_grid, " & ",
    r$Mean_aidfee, " & ",
    r$Mean_charge, " \\\\"
  ))
}

tex_lines <- c(tex_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All tariff values in Rappen per kWh (Rp/kWh) for household consumption category H4 (4,500 kWh/year). Reform cantons adopted comprehensive energy legislation between 2010 and 2020: GR (2010), BE (2011), AG (2012), BL (2016), BS (2016), LU (2017), FR (2019), AI (2020). Border sample includes municipalities within 15km of a cantonal border. Source: ElCom/LINDAS.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_lines, file.path(tab_dir, "tab1_descriptive.tex"))
cat("  Saved tab1_descriptive.tex\n")

# ===========================================================================
# Table 2: Main RDD Results — Component Decomposition
# ===========================================================================
cat("=== Table 2: Main RDD Results ===\n")

rdd_data <- tryCatch(fread(file.path(data_dir, "rdd_cross_section.csv")), error = function(e) NULL)

if (!is.null(rdd_data) && nrow(rdd_data) > 0) {
  tex_lines <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Spatial RDD: Energy Law Reform Effect on Electricity Tariff Components}",
    "\\label{tab:main_rdd}",
    "\\begin{tabular}{lccccc}",
    "\\toprule",
    " & Total & Energy & Grid & Charges & Aid Fee \\\\",
    " & (1) & (2) & (3) & (4) & (5) \\\\",
    "\\midrule",
    "Reform Canton & "
  )

  coefs <- c()
  ses <- c()
  for (comp in c("total", "energy", "gridusage", "charge", "aidfee")) {
    row <- rdd_data[component == comp]
    if (nrow(row) > 0) {
      coefs <- c(coefs, sprintf("%.3f", row$coef))
      stars <- ifelse(abs(row$coef / row$se) > 2.576, "***",
                      ifelse(abs(row$coef / row$se) > 1.96, "**",
                             ifelse(abs(row$coef / row$se) > 1.645, "*", "")))
      coefs[length(coefs)] <- paste0(coefs[length(coefs)], stars)
      ses <- c(ses, sprintf("(%.3f)", row$se))
    } else {
      coefs <- c(coefs, "---")
      ses <- c(ses, "")
    }
  }

  tex_lines[length(tex_lines)] <- paste0("Reform Canton & ", paste(coefs, collapse = " & "), " \\\\")
  tex_lines <- c(tex_lines, paste0(" & ", paste(ses, collapse = " & "), " \\\\"))

  # Add N and controls
  n_vals <- sapply(c("total", "energy", "gridusage", "charge", "aidfee"), function(comp) {
    row <- rdd_data[component == comp]
    if (nrow(row) > 0) format(row$n, big.mark = ",") else "---"
  })
  nbp_vals <- sapply(c("total", "energy", "gridusage", "charge", "aidfee"), function(comp) {
    row <- rdd_data[component == comp]
    if (nrow(row) > 0) as.character(row$n_bp) else "---"
  })

  tex_lines <- c(tex_lines,
    "\\midrule",
    paste0("Border-pair FE & Yes & Yes & Yes & Yes & Yes \\\\"),
    paste0("Year FE & Yes & Yes & Yes & Yes & Yes \\\\"),
    paste0("Distance control & Quadratic & Quadratic & Quadratic & Quadratic & Quadratic \\\\"),
    paste0("Observations & ", paste(n_vals, collapse = " & "), " \\\\"),
    paste0("Border pairs & ", paste(nbp_vals, collapse = " & "), " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Each column reports the coefficient on an indicator for being located in a canton that has adopted comprehensive energy legislation, estimated using OLS with border-pair and year fixed effects. The sample includes municipalities within 15km of a cantonal border where one side has reformed and the other has not. Standard errors clustered at the canton level in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tex_lines, file.path(tab_dir, "tab2_main_rdd.tex"))
  cat("  Saved tab2_main_rdd.tex\n")
}

# ===========================================================================
# Table 3: Robustness — Bandwidth Sensitivity
# ===========================================================================
cat("=== Table 3: Bandwidth Sensitivity ===\n")

bw_data <- tryCatch(fread(file.path(data_dir, "robustness_bandwidth.csv")), error = function(e) NULL)

if (!is.null(bw_data) && nrow(bw_data) > 0) {
  charge_bw <- bw_data[component == "charge"]

  tex_lines <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Bandwidth Sensitivity: Reform Effect on Cantonal Charges}",
    "\\label{tab:bandwidth}",
    "\\begin{tabular}{lccccc}",
    "\\toprule",
    paste0("Bandwidth (km) & ", paste(charge_bw$bandwidth_km, collapse = " & "), " \\\\"),
    "\\midrule"
  )

  coef_line <- "Reform Canton"
  se_line <- ""
  n_line <- "Observations"
  mun_line <- "Municipalities"

  for (i in seq_len(nrow(charge_bw))) {
    r <- charge_bw[i]
    stars <- ifelse(abs(r$coef / r$se) > 2.576, "***",
                    ifelse(abs(r$coef / r$se) > 1.96, "**",
                           ifelse(abs(r$coef / r$se) > 1.645, "*", "")))
    coef_line <- paste0(coef_line, " & ", sprintf("%.3f%s", r$coef, stars))
    se_line <- paste0(se_line, " & ", sprintf("(%.3f)", r$se))
    n_line <- paste0(n_line, " & ", format(r$n, big.mark = ","))
    mun_line <- paste0(mun_line, " & ", format(r$n_mun, big.mark = ","))
  }

  tex_lines <- c(tex_lines,
    paste0(coef_line, " \\\\"),
    paste0(se_line, " \\\\"),
    "\\midrule",
    paste0(n_line, " \\\\"),
    paste0(mun_line, " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Each column uses a different distance bandwidth from cantonal borders. All specifications include border-pair and year fixed effects with a quadratic distance control. Standard errors clustered at the canton level.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tex_lines, file.path(tab_dir, "tab3_bandwidth.tex"))
  cat("  Saved tab3_bandwidth.tex\n")
}

# ===========================================================================
# Table 4: Robustness — Polynomial, Donut, DSO FE
# ===========================================================================
cat("=== Table 4: Additional Robustness ===\n")

poly_data <- tryCatch(fread(file.path(data_dir, "robustness_polynomial.csv")), error = function(e) NULL)
donut_data <- tryCatch(fread(file.path(data_dir, "robustness_donut.csv")), error = function(e) NULL)

if (!is.null(poly_data) || !is.null(donut_data)) {
  tex_lines <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Robustness: Alternative Specifications for Charges Component}",
    "\\label{tab:robustness}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    " & Linear & Quadratic & Cubic & Donut (2km) \\\\",
    " & (1) & (2) & (3) & (4) \\\\",
    "\\midrule"
  )

  # Populate with actual coefficients from data
  coef_vals <- c()
  se_vals <- c()
  n_vals <- c()

  # Cols 1-3: polynomial sensitivity (charge component)
  if (!is.null(poly_data) && nrow(poly_data) > 0) {
    for (po in 1:3) {
      row <- poly_data[poly_order == po]
      if (nrow(row) > 0) {
        stars <- ifelse(abs(row$coef / row$se) > 2.576, "***",
                        ifelse(abs(row$coef / row$se) > 1.96, "**",
                               ifelse(abs(row$coef / row$se) > 1.645, "*", "")))
        coef_vals <- c(coef_vals, sprintf("%.3f%s", row$coef, stars))
        se_vals <- c(se_vals, sprintf("(%.3f)", row$se))
        n_vals <- c(n_vals, format(row$n, big.mark = ","))
      } else {
        coef_vals <- c(coef_vals, "---")
        se_vals <- c(se_vals, "")
        n_vals <- c(n_vals, "---")
      }
    }
  } else {
    coef_vals <- c(coef_vals, "---", "---", "---")
    se_vals <- c(se_vals, "", "", "")
    n_vals <- c(n_vals, "---", "---", "---")
  }

  # Col 4: donut RDD (charge component only)
  if (!is.null(donut_data) && nrow(donut_data) > 0) {
    row <- donut_data[component == "charge"]
    if (nrow(row) > 0) {
      stars <- ifelse(abs(row$coef / row$se) > 2.576, "***",
                      ifelse(abs(row$coef / row$se) > 1.96, "**",
                             ifelse(abs(row$coef / row$se) > 1.645, "*", "")))
      coef_vals <- c(coef_vals, sprintf("%.3f%s", row$coef, stars))
      se_vals <- c(se_vals, sprintf("(%.3f)", row$se))
      n_vals <- c(n_vals, format(row$n, big.mark = ","))
    } else {
      coef_vals <- c(coef_vals, "---")
      se_vals <- c(se_vals, "")
      n_vals <- c(n_vals, "---")
    }
  } else {
    coef_vals <- c(coef_vals, "---")
    se_vals <- c(se_vals, "")
    n_vals <- c(n_vals, "---")
  }

  tex_lines <- c(tex_lines,
    paste0("Reform Canton & ", paste(coef_vals, collapse = " & "), " \\\\"),
    paste0(" & ", paste(se_vals, collapse = " & "), " \\\\"),
    "\\midrule",
    paste0("Observations & ", paste(n_vals, collapse = " & "), " \\\\"),
    "Border-pair FE & Yes & Yes & Yes & Yes \\\\",
    "Year FE & Yes & Yes & Yes & Yes \\\\",
    "Donut (2km) & No & No & No & Yes \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Dependent variable: cantonal/municipal charges (Rp/kWh). All specifications include border-pair and year fixed effects and use the 15km bandwidth sample. Columns (1)--(3) vary the polynomial order of the distance control. Column (4) excludes municipalities within 2km of the border (donut RDD). Standard errors clustered at the canton level.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tex_lines, file.path(tab_dir, "tab4_robustness.tex"))
  cat("  Saved tab4_robustness.tex\n")
}

# ===========================================================================
# Table 5: Consumer Cost Counterfactual
# ===========================================================================
cat("=== Table 5: Consumer Cost Counterfactual ===\n")

cost_data <- tryCatch(fread(file.path(data_dir, "cost_counterfactual.csv")), error = function(e) NULL)

if (!is.null(cost_data) && nrow(cost_data) > 0) {
  tex_lines <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Consumer Cost of Cantonal Energy Policy: Near-Border Comparison}",
    "\\label{tab:counterfactual}",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    " & Reform Canton & Non-Reform Canton \\\\",
    "\\midrule"
  )

  reform_row <- cost_data[reformed == TRUE]
  control_row <- cost_data[reformed == FALSE]

  if (nrow(reform_row) > 0 && nrow(control_row) > 0) {
    tex_lines <- c(tex_lines,
      paste0("Mean total tariff (Rp/kWh) & ",
             round(reform_row$mean_total, 2), " & ",
             round(control_row$mean_total, 2), " \\\\"),
      paste0("Mean charges (Rp/kWh) & ",
             round(reform_row$mean_charge, 2), " & ",
             round(control_row$mean_charge, 2), " \\\\"),
      paste0("Number of municipalities & ",
             reform_row$n_mun, " & ",
             control_row$n_mun, " \\\\"),
      "\\midrule",
      paste0("Charges gap (Rp/kWh) & \\multicolumn{2}{c}{",
             round(reform_row$mean_charge - control_row$mean_charge, 2), "} \\\\"),
      paste0("Annual cost for H4 household (CHF) & \\multicolumn{2}{c}{",
             round((reform_row$mean_charge - control_row$mean_charge) * 45, 0), "} \\\\")
    )
  }

  tex_lines <- c(tex_lines,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Comparison of municipalities within 10km of cantonal borders where one side adopted energy law reform and the other did not. H4 household consumption: 4,500 kWh/year. Charges gap converted to annual CHF at H4 consumption level.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tex_lines, file.path(tab_dir, "tab5_counterfactual.tex"))
  cat("  Saved tab5_counterfactual.tex\n")
}

cat("\n=== All tables generated ===\n")
