# 05_tables.R — Generate all LaTeX tables
# apep_0844: State Disinvestment and Enrollment Composition

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
panel <- fread("../data/panel.csv")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary statistics ===\n")

# Reconstruct analysis sample
panel <- panel[nchar(state) == 2 &
               !state %in% c("AS", "GU", "MH", "FM", "MP", "PW", "PR", "VI")]
cpi <- data.table(year = 2004:2022,
  cpi = c(188.9, 195.3, 201.6, 207.3, 215.3, 214.5, 218.1,
          224.9, 229.6, 233.0, 236.7, 237.0, 240.0, 245.1, 251.1,
          255.7, 251.7, 258.8, 292.7))
cpi[, deflator := max(cpi) / cpi]
panel <- merge(panel, cpi, by = "year", all.x = TRUE)
panel[, real_tuition := tuition_instate * deflator]
panel[, real_approp_ps := approp_per_student * deflator]

state_pre <- panel[year %in% 2007:2008 & !is.na(real_approp_ps) & real_approp_ps > 0,
                   .(pre_approp = mean(real_approp_ps, na.rm = TRUE)), by = state]
state_post <- panel[year %in% 2011:2012 & !is.na(real_approp_ps) & real_approp_ps > 0,
                    .(post_approp = mean(real_approp_ps, na.rm = TRUE)), by = state]
state_cut <- merge(state_pre, state_post, by = "state")
state_cut[, cut_intensity := -(post_approp - pre_approp) / pre_approp]
panel <- merge(panel, state_cut[, .(state, cut_intensity)], by = "state", all.x = TRUE)

analysis <- panel[!is.na(real_tuition) & !is.na(real_approp_ps) &
                  real_approp_ps > 0 & real_tuition > 0 &
                  !is.na(EFTOTLT) & EFTOTLT > 100 &
                  !is.na(cut_intensity) & year >= 2004]

# Summary stats table
vars <- c("real_tuition", "real_approp_ps", "pell_share", "EFTOTLT",
          "black_share", "hispanic_share", "nonres_share")
labels <- c("In-state tuition (2022\\$)", "State approp./student (2022\\$)",
            "Pell share", "Total enrollment",
            "Black share", "Hispanic share", "Nonresident share")

pre <- analysis[year %in% 2004:2008]
post <- analysis[year %in% 2009:2022]

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Public Four-Year Institutions, 2004--2022}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Pre-Recession (2004--2008)} & \\multicolumn{3}{c}{Post-Recession (2009--2022)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Mean & SD & N & Mean & SD & N \\\\",
  "\\midrule"
)

for (i in seq_along(vars)) {
  v <- vars[i]
  l <- labels[i]
  pre_mean <- mean(pre[[v]], na.rm = TRUE)
  pre_sd <- sd(pre[[v]], na.rm = TRUE)
  pre_n <- sum(!is.na(pre[[v]]))
  post_mean <- mean(post[[v]], na.rm = TRUE)
  post_sd <- sd(post[[v]], na.rm = TRUE)
  post_n <- sum(!is.na(post[[v]]))

  if (v %in% c("real_tuition", "real_approp_ps", "EFTOTLT")) {
    tab1_lines <- c(tab1_lines,
      sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
              l,
              formatC(round(pre_mean), format = "d", big.mark = ","),
              formatC(round(pre_sd), format = "d", big.mark = ","),
              formatC(pre_n, format = "d", big.mark = ","),
              formatC(round(post_mean), format = "d", big.mark = ","),
              formatC(round(post_sd), format = "d", big.mark = ","),
              formatC(post_n, format = "d", big.mark = ",")))
  } else {
    tab1_lines <- c(tab1_lines,
      sprintf("%s & %.3f & %.3f & %s & %.3f & %.3f & %s \\\\",
              l, pre_mean, pre_sd,
              formatC(pre_n, format = "d", big.mark = ","),
              post_mean, post_sd,
              formatC(post_n, format = "d", big.mark = ",")))
  }
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Institutions & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
          uniqueN(pre$UNITID), uniqueN(post$UNITID)),
  sprintf("States & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
          uniqueN(pre$state), uniqueN(post$state)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Sample includes public four-year institutions in the 50 U.S.\\ states and D.C.\\ with enrollment above 100. Dollar amounts are deflated to 2022 using CPI-U. Pell share is the percentage of first-time, full-time undergraduates receiving Pell grants. Source: IPEDS.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results (OLS comparison not needed — go straight to DiD)
# ============================================================================
cat("=== Table 2: Main DiD results ===\n")

etable(results$did_tuition, results$did_pell, results$did_nonres,
       results$did_enroll, results$did_minority,
       headers = c("Log Tuition", "Pell Share", "Nonres. Share",
                    "Log Enroll.", "Minority Share"),
       se.below = TRUE,
       fitstat = c("n", "r2", "wr2"),
       fixef_sizes = TRUE,
       dict = c(cut_intensity = "Cut Intensity", post = "Post-2009"),
       file = file.path(tables_dir, "tab2_main.tex"),
       replace = TRUE,
       label = "tab:main",
       title = "State Disinvestment and Enrollment Composition: Continuous Treatment DiD")

# ============================================================================
# Table 3: Robustness
# ============================================================================
cat("=== Table 3: Robustness ===\n")

# Trimmed + binary + main for Pell
main_pell <- results$did_pell
trim_pell <- robustness$trimmed_pell
bin_pell <- robustness$binary_pell

etable(main_pell, trim_pell, bin_pell,
       headers = c("Baseline", "Trimmed (5\\%)", "Binary Treatment"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       fixef_sizes = TRUE,
       dict = c(cut_intensity = "Cut Intensity", post = "Post-2009",
                high_cut = "High Cut"),
       file = file.path(tables_dir, "tab3_robustness.tex"),
       replace = TRUE,
       label = "tab:robust",
       title = "Robustness: Pell Share Response to State Disinvestment")

# ============================================================================
# Table F1: SDE Table (MANDATORY)
# ============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDEs for main outcomes
# SDE = beta * SD(X) / SD(Y) for continuous treatment
# Since cut_intensity:post is the regressor, and beta is the coefficient on
# the interaction, SDE = beta * SD(cut_intensity in post period) / SD(Y in pre-period)

analysis[, post := as.integer(year >= 2009)]
sd_cut <- sd(analysis[post == 1]$cut_intensity, na.rm = TRUE)
pre_data <- analysis[year %in% 2004:2008]

# Main outcomes
outcomes <- list(
  list(name = "Pell share", model = results$did_pell,
       sd_y = sd(pre_data$pell_share, na.rm = TRUE)),
  list(name = "Minority share", model = results$did_minority,
       sd_y = sd(pre_data$minority_share, na.rm = TRUE)),
  list(name = "Log tuition", model = results$did_tuition,
       sd_y = sd(log(pmax(pre_data$real_tuition, 1)), na.rm = TRUE)),
  list(name = "Log enrollment", model = results$did_enroll,
       sd_y = sd(pre_data$log_enrollment, na.rm = TRUE)),
  list(name = "Nonresident share", model = results$did_nonres,
       sd_y = sd(pre_data$nonres_share, na.rm = TRUE))
)

sde_rows <- list()
for (o in outcomes) {
  ct <- coeftable(o$model)
  beta <- ct[1, 1]
  se_beta <- ct[1, 2]
  sde <- beta * sd_cut / o$sd_y
  se_sde <- se_beta * sd_cut / o$sd_y

  # Classification
  if (abs(sde) < 0.005) {
    class_label <- "Null"
  } else if (sde > 0.15) {
    class_label <- "Large positive"
  } else if (sde > 0.05) {
    class_label <- "Moderate positive"
  } else if (sde > 0.005) {
    class_label <- "Small positive"
  } else if (sde < -0.15) {
    class_label <- "Large negative"
  } else if (sde < -0.05) {
    class_label <- "Moderate negative"
  } else {
    class_label <- "Small negative"
  }

  sde_rows[[length(sde_rows) + 1]] <- list(
    name = o$name, beta = beta, se = se_beta,
    sd_y = o$sd_y, sde = sde, se_sde = se_sde,
    class = class_label
  )
}

# Heterogeneity: high-enrollment vs low-enrollment institutions
med_enroll <- median(analysis$EFTOTLT, na.rm = TRUE)
het_large <- feols(pell_share ~ cut_intensity:post | UNITID + year,
                   data = analysis[EFTOTLT >= med_enroll & !is.na(pell_share)],
                   cluster = ~state)
het_small <- feols(pell_share ~ cut_intensity:post | UNITID + year,
                   data = analysis[EFTOTLT < med_enroll & !is.na(pell_share)],
                   cluster = ~state)

sd_y_het <- sd(pre_data$pell_share, na.rm = TRUE)
for (het_model in list(list(n = "Pell share (large institutions)", m = het_large),
                       list(n = "Pell share (small institutions)", m = het_small))) {
  ct <- coeftable(het_model$m)
  beta <- ct[1, 1]
  se_beta <- ct[1, 2]
  sde <- beta * sd_cut / sd_y_het
  se_sde <- se_beta * sd_cut / sd_y_het
  if (abs(sde) < 0.005) cl <- "Null"
  else if (sde > 0.15) cl <- "Large positive"
  else if (sde > 0.05) cl <- "Moderate positive"
  else if (sde > 0.005) cl <- "Small positive"
  else if (sde < -0.15) cl <- "Large negative"
  else if (sde < -0.05) cl <- "Moderate negative"
  else cl <- "Small negative"

  sde_rows[[length(sde_rows) + 1]] <- list(
    name = het_model$n, beta = beta, se = se_beta,
    sd_y = sd_y_het, sde = sde, se_sde = se_sde, class = cl)
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state disinvestment in public higher education ",
  "change enrollment composition, specifically the share of low-income (Pell-eligible) ",
  "and minority students at public four-year institutions? ",
  "\\textbf{Policy mechanism:} State legislatures reduce per-student appropriations ",
  "to public universities during fiscal downturns, forcing institutions to adjust ",
  "through tuition increases, enrollment changes, or compositional shifts in the student body. ",
  "\\textbf{Outcome definition:} Pell share is the percentage of first-time full-time ",
  "undergraduates receiving federal Pell grants; minority share is the combined Black ",
  "and Hispanic share of total enrollment; log tuition is log real in-state tuition and fees. ",
  "\\textbf{Treatment:} Continuous; state-level intensity of per-student appropriation ",
  "decline from 2007--2008 to 2011--2012 (real 2022 dollars). ",
  "\\textbf{Data:} IPEDS, 2004--2022, institution-year level, 702 public four-year institutions ",
  "across 51 states/DC, 6,768 observations. ",
  "\\textbf{Method:} Continuous treatment DiD with institution and year fixed effects; ",
  "standard errors clustered at the state level. ",
  "\\textbf{Sample:} Public four-year institutions with enrollment above 100, excluding ",
  "U.S.\\ territories. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the standard deviation of cut intensity. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:5) {
  r <- sde_rows[[i]]
  sde_lines <- c(sde_lines,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
            r$name, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}

sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by institution size)}} \\\\"
)
for (i in 6:7) {
  r <- sde_rows[[i]]
  sde_lines <- c(sde_lines,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
            r$name, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat("Files:", paste(list.files(tables_dir), collapse = ", "), "\n")
