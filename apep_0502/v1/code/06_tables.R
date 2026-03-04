# ==============================================================================
# 06_tables.R — Generate all tables
# Clean Air, Dirty Power? NAAQS Nonattainment and the Clean Energy Transition
# ==============================================================================

source("00_packages.R")

# Load data
cs <- readRDS(file.path(data_dir, "cross_section_rdd.rds"))
analysis <- tryCatch(
  readRDS(file.path(data_dir, "analysis_with_energy.rds")),
  error = function(e) readRDS(file.path(data_dir, "analysis_panel.rds"))
)

cat("=== Generating Tables ===\n\n")

# ==============================================================================
# Table 1: Summary Statistics (cross-sectional)
# ==============================================================================

cat("Table 1: Summary statistics (cross-sectional)\n")

rdd_data <- cs[!is.na(running_12)]

# Split by treatment status
summ_vars <- c("dv_recent", "pm25_recent", "n_monitors")
if ("total_capacity" %in% names(cs)) {
  summ_vars <- c(summ_vars, "total_capacity", "fossil_capacity", "renewable_capacity",
                 "coal_capacity")
}
if ("total_pop" %in% names(cs)) {
  summ_vars <- c(summ_vars, "total_pop", "median_income")
}

# Create summary by attainment status
make_summ <- function(dt, group_name) {
  stats <- list()
  for (v in summ_vars) {
    if (v %in% names(dt) && sum(!is.na(dt[[v]])) > 0) {
      stats[[v]] <- data.table(
        variable = v,
        group = group_name,
        mean = mean(dt[[v]], na.rm = TRUE),
        sd = sd(dt[[v]], na.rm = TRUE),
        median = median(dt[[v]], na.rm = TRUE),
        N = sum(!is.na(dt[[v]]))
      )
    }
  }
  rbindlist(stats)
}

summ_treat <- make_summ(rdd_data[treat_12 == 1], "Nonattainment")
summ_ctrl <- make_summ(rdd_data[treat_12 == 0], "Attainment")
summ_all <- make_summ(rdd_data, "Full Sample")

summ_table <- rbind(summ_all, summ_ctrl, summ_treat)

# Format as LaTeX table
var_labels <- c(
  "dv_recent" = "PM2.5 Design Value (μg/m³)",
  "pm25_recent" = "Annual Mean PM2.5 (μg/m³)",
  "n_monitors" = "Number of Monitors",
  "total_capacity" = "Total Generation Capacity (MW)",
  "fossil_capacity" = "Fossil Fuel Capacity (MW)",
  "renewable_capacity" = "Renewable Capacity (MW)",
  "coal_capacity" = "Coal Capacity (MW)",
  "total_pop" = "Total Population",
  "median_income" = "Median Household Income ($)"
)

# Pivot to wide format
summ_wide <- dcast(summ_table, variable ~ group, value.var = c("mean", "sd", "N"))

# Generate LaTeX
latex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Nonattainment Status}",
  "\\label{tab:summary_stats}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Attainment} & \\multicolumn{2}{c}{Nonattainment} & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Variable & Mean & SD & Mean & SD & Mean & SD & N \\\\",
  "\\midrule"
)

for (v in summ_vars) {
  if (v %in% summ_wide$variable) {
    row <- summ_wide[variable == v]
    label <- var_labels[v]
    if (is.na(label)) label <- v

    vals <- sprintf("%s & %.1f & (%.1f) & %.1f & (%.1f) & %.1f & (%.1f) & %s \\\\",
                    label,
                    row[["mean_Full Sample"]], row[["sd_Full Sample"]],
                    row[["mean_Attainment"]], row[["sd_Attainment"]],
                    row[["mean_Nonattainment"]], row[["sd_Nonattainment"]],
                    format(row[["N_Full Sample"]], big.mark = ","))
    latex_lines <- c(latex_lines, vals)
  }
}

latex_lines <- c(latex_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Cross-sectional sample: one observation per county. Design value is the 2012--2022 average annual mean PM2.5 concentration. Nonattainment counties have design values exceeding 12 $\\mu$g/m$^3$. Energy capacity from eGRID 2022. Counties without power plants assigned zero capacity.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(latex_lines, file.path(tab_dir, "summary_stats.tex"))
cat("  Saved summary_stats.tex\n")

# ==============================================================================
# Table 2: Main RDD Results
# ==============================================================================

cat("Table 2: Main RDD results\n")

# Run all main specifications
outcomes <- list()

if ("fossil_capacity" %in% names(cs)) {
  outcomes[["Fossil Capacity"]] <- "fossil_capacity"
  outcomes[["Renewable Capacity"]] <- "renewable_capacity"
  outcomes[["Coal Capacity"]] <- "coal_capacity"
  outcomes[["Total Capacity"]] <- "total_capacity"
}

rdd_results <- list()

for (outcome_name in names(outcomes)) {
  var <- outcomes[[outcome_name]]
  if (!var %in% names(cs)) next

  rdd_data_out <- cs[!is.na(running_12) & !is.na(get(var))]

  tryCatch({
    rd <- rdrobust(
      y = rdd_data_out[[var]],
      x = rdd_data_out$running_12,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd"
    )

    rdd_results[[outcome_name]] <- data.table(
      outcome = outcome_name,
      coef_conv = rd$coef["Conventional", ],
      se_conv = rd$se["Conventional", ],
      pv_conv = rd$pv["Conventional", ],
      coef_bc = rd$coef["Bias-Corrected", ],
      se_bc = rd$se["Bias-Corrected", ],
      pv_bc = rd$pv["Bias-Corrected", ],
      coef_robust = rd$coef["Robust", ],
      se_robust = rd$se["Robust", ],
      pv_robust = rd$pv["Robust", ],
      bw_h = rd$bws["h", "left"],
      bw_b = rd$bws["b", "left"],
      N_left = rd$N_h[1],
      N_right = rd$N_h[2],
      N_eff = rd$N_h[1] + rd$N_h[2]
    )
  }, error = function(e) {
    cat(sprintf("  %s: error — %s\n", outcome_name, e$message))
  })
}

if (length(rdd_results) > 0) {
  rdd_dt <- rbindlist(rdd_results)
  saveRDS(rdd_dt, file.path(data_dir, "main_rdd_results.rds"))

  # Generate LaTeX table
  latex_main <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{RDD Estimates of Nonattainment Effects on Energy Infrastructure}",
    "\\label{tab:main_results}",
    "\\begin{adjustbox}{max width=\\textwidth}",
    sprintf("\\begin{tabular}{l*{%d}{c}}", nrow(rdd_dt)),
    "\\toprule",
    paste0(" & ", paste(rdd_dt$outcome, collapse = " & "), " \\\\"),
    paste0(" & ", paste(sprintf("(%d)", 1:nrow(rdd_dt)), collapse = " & "), " \\\\"),
    "\\midrule",
    "\\addlinespace",
    sprintf("\\multicolumn{%d}{l}{\\textit{Panel A: Conventional}} \\\\", nrow(rdd_dt) + 1),
    "\\addlinespace"
  )

  # Conventional estimates
  coef_row <- paste0("RDD Estimate & ", paste(sprintf("%.2f", rdd_dt$coef_conv), collapse = " & "), " \\\\")
  se_row <- paste0(" & ", paste(sprintf("(%.2f)", rdd_dt$se_conv), collapse = " & "), " \\\\")
  latex_main <- c(latex_main, coef_row, se_row)

  # Robust estimates
  latex_main <- c(latex_main,
    "\\addlinespace",
    sprintf("\\multicolumn{%d}{l}{\\textit{Panel B: Robust Bias-Corrected}} \\\\", nrow(rdd_dt) + 1),
    "\\addlinespace"
  )
  coef_row_r <- paste0("RDD Estimate & ", paste(sprintf("%.2f", rdd_dt$coef_robust), collapse = " & "), " \\\\")
  se_row_r <- paste0(" & ", paste(sprintf("[%.2f]", rdd_dt$se_robust), collapse = " & "), " \\\\")
  latex_main <- c(latex_main, coef_row_r, se_row_r)

  # Diagnostics
  latex_main <- c(latex_main,
    "\\addlinespace",
    "\\midrule",
    paste0("Bandwidth & ", paste(sprintf("%.2f", rdd_dt$bw_h), collapse = " & "), " \\\\"),
    paste0("$N_{\\text{left}}$ & ", paste(format(rdd_dt$N_left, big.mark = ","), collapse = " & "), " \\\\"),
    paste0("$N_{\\text{right}}$ & ", paste(format(rdd_dt$N_right, big.mark = ","), collapse = " & "), " \\\\"),
    paste0("Effective N & ", paste(format(rdd_dt$N_eff, big.mark = ","), collapse = " & "), " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{adjustbox}",
    "\\begin{tablenotes}",
    "\\small",
    "\\item \\textit{Notes:} Local polynomial RDD estimates using triangular kernel and MSE-optimal bandwidth selection (Calonico, Cattaneo, and Titiunik 2014). Running variable is county PM2.5 design value minus the 12 $\\mu$g/m$^3$ NAAQS standard. Panel A reports conventional point estimates with conventional standard errors in parentheses. Panel B reports robust bias-corrected estimates with robust standard errors in brackets.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(latex_main, file.path(tab_dir, "main_results.tex"))
  cat("  Saved main_results.tex\n")
}

# ==============================================================================
# Table 3: Robustness — Bandwidth Sensitivity
# ==============================================================================

cat("Table 3: Bandwidth sensitivity\n")

bw_dt <- tryCatch(readRDS(file.path(data_dir, "robustness_bandwidth.rds")), error = function(e) NULL)

if (!is.null(bw_dt) && nrow(bw_dt) > 0) {
  stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

  latex_bw <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Bandwidth Sensitivity}",
    "\\label{tab:bandwidth}",
    "\\begin{tabular}{lccccc}",
    "\\toprule",
    "Bandwidth & \\% of Optimal & Estimate & SE & p-value & Eff. N \\\\",
    "\\midrule"
  )

  for (i in 1:nrow(bw_dt)) {
    row <- bw_dt[i]
    latex_bw <- c(latex_bw,
      sprintf("%.2f & %.0f\\%% & %.2f%s & (%.2f) & %.3f & %s \\\\",
              row$bandwidth, row$bandwidth_mult * 100,
              row$coef, stars(row$pvalue), row$se, row$pvalue,
              format(row$N_left + row$N_right, big.mark = ",")))
  }

  latex_bw <- c(latex_bw,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}",
    "\\small",
    "\\item \\textit{Notes:} RDD estimates at varying bandwidths. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(latex_bw, file.path(tab_dir, "bandwidth_sensitivity.tex"))
  cat("  Saved bandwidth_sensitivity.tex\n")
}

# ==============================================================================
# Table 4: Placebo Tests
# ==============================================================================

cat("Table 4: Placebo cutoff tests\n")

placebo_dt <- tryCatch(readRDS(file.path(data_dir, "robustness_placebos.rds")), error = function(e) NULL)

if (!is.null(placebo_dt) && nrow(placebo_dt) > 0) {
  latex_plc <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Placebo Cutoff Tests}",
    "\\label{tab:placebos}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Cutoff Shift & Estimate & SE & $p$-value & Eff. N \\\\",
    "\\midrule"
  )

  has_N <- "N_left" %in% names(placebo_dt)
  for (i in 1:nrow(placebo_dt)) {
    row <- placebo_dt[i]
    eff_n <- if (has_N) format(row$N_left + row$N_right, big.mark = ",") else "---"
    latex_plc <- c(latex_plc,
      sprintf("%+d $\\mu$g/m$^3$ & %.2f & (%.2f) & %.3f & %s \\\\",
              as.integer(row$cutoff_shift), row$coef, row$se, row$pvalue, eff_n))
  }

  latex_plc <- c(latex_plc,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}",
    "\\small",
    "\\item \\textit{Notes:} RDD estimates at placebo cutoffs shifted from the true 12 $\\mu$g/m$^3$ threshold. Significant effects at non-zero shifts would indicate specification concerns.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(latex_plc, file.path(tab_dir, "placebos.tex"))
  cat("  Saved placebos.tex\n")
}

cat("\n=== All tables generated ===\n")
