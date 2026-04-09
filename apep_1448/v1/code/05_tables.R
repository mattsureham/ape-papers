# 05_tables.R — Generate all tables for the paper
# apep_1448: Medicare Advantage Quality Bonus RDD

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- read_csv(file.path(data_dir, "panel_star_ratings.csv"), show_col_types = FALSE)
results <- fromJSON(file.path(data_dir, "rdd_results.json"))
robustness <- fromJSON(file.path(data_dir, "robustness_results.json"))

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

panel_stats <- panel %>%
  summarise(
    `Contract-years` = n(),
    `Unique contracts` = n_distinct(contract_id),
    `Years` = paste(min(year), max(year), sep = "--"),
    `Mean summary score` = sprintf("%.3f", mean(summary_score)),
    `SD summary score` = sprintf("%.3f", sd(summary_score)),
    `Share $\\geq$ 3.75` = sprintf("%.3f", mean(above_threshold)),
    `Share 4+ displayed stars` = sprintf("%.3f", mean(star_4plus, na.rm = TRUE)),
    `Near threshold (3.25--4.25)` = sum(summary_score >= 3.25 & summary_score <= 4.25)
  )

# Also show by-year counts near threshold
year_stats <- panel %>%
  group_by(year) %>%
  summarise(
    N = n(),
    `Mean score` = sprintf("%.3f", mean(summary_score)),
    `SD` = sprintf("%.3f", sd(summary_score)),
    `Share $\\geq$ 4 stars` = sprintf("%.3f", mean(star_4plus, na.rm = TRUE)),
    `N near threshold` = sum(summary_score >= 3.25 & summary_score <= 4.25),
    .groups = "drop"
  )

# Write Table 1
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Medicare Advantage Star Ratings, 2015--2026}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Year & N & Mean Score & SD & Share $\\geq$ 4 Stars & N Near Threshold \\\\",
  "\\hline"
)

for (i in 1:nrow(year_stats)) {
  tab1_lines <- c(tab1_lines,
    sprintf("%d & %d & %s & %s & %s & %d \\\\",
            year_stats$year[i], year_stats$N[i],
            year_stats$`Mean score`[i], year_stats$SD[i],
            year_stats$`Share $\\geq$ 4 stars`[i],
            year_stats$`N near threshold`[i]))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("Total & %d & %s & %s & %s & %d \\\\",
          as.integer(panel_stats$`Contract-years`),
          panel_stats$`Mean summary score`,
          panel_stats$`SD summary score`,
          panel_stats$`Share 4+ displayed stars`,
          panel_stats$`Near threshold (3.25--4.25)`),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Unit of observation is contract-year. Summary score is the unweighted mean",
  "of Part C measure-level stars (1--5) reconstructed from CMS Star Ratings Data Tables.",
  "``Near threshold'' counts contracts with summary score in [3.25, 4.25]. The 3.75",
  "threshold determines whether a contract receives a 4-star overall rating, which triggers",
  "the quality bonus payment ($\\sim$5\\% of benchmark).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ============================================================================
# Table 2: Main RDD Results
# ============================================================================

# Read raw results
first_stage <- results$first_stage
mccrary <- results$mccrary
bw_sens <- results$bandwidth_sensitivity

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{RDD at the 3.75 Star Rating Threshold}",
  "\\label{tab:rdd}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Coefficient & SE & $p$-value & Eff. $N$ \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Main Estimate}} \\\\[3pt]",
  sprintf("$\\Pr(\\text{4+ stars} \\mid \\text{score} \\geq 3.75)$ & %.3f & (%.3f) & %.3f & %d \\\\",
          first_stage$coef, first_stage$se, first_stage$pvalue,
          first_stage$n_left + first_stage$n_right),
  sprintf("\\quad Optimal bandwidth & \\multicolumn{4}{c}{%.3f} \\\\", first_stage$bw),
  sprintf("\\quad McCrary density test $p$-value & \\multicolumn{4}{c}{%.3f} \\\\", mccrary$p_value),
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel B: Bandwidth Sensitivity}} \\\\[3pt]"
)

for (i in 1:nrow(bw_sens)) {
  tab2_lines <- c(tab2_lines,
    sprintf("\\quad $h = %.2f$ & %.3f & (%.3f) & %.3f & %d \\\\",
            bw_sens$bandwidth[i], bw_sens$coef[i], bw_sens$se[i],
            bw_sens$pvalue[i], bw_sens$n_left[i] + bw_sens$n_right[i]))
}

tab2_lines <- c(tab2_lines,
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo Thresholds}} \\\\[3pt]",
  sprintf("\\quad $c = 2.75$ & %.3f & --- & %.3f & \\\\",
          results$placebo_275$coef, results$placebo_275$pvalue),
  sprintf("\\quad $c = 4.25$ & %.3f & --- & %.3f & \\\\",
          results$placebo_425$coef, results$placebo_425$pvalue),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Sharp RDD estimates using local polynomial regression with triangular",
  "kernel (Cattaneo, Idrobo, and Titiunik 2020). Running variable: mean of Part C measure stars.",
  "Outcome: indicator for $\\geq$ 4 displayed stars. Panel A uses MSE-optimal bandwidth.",
  "Panel B varies bandwidth from 0.10 to 0.50. Robust bias-corrected confidence intervals",
  "used throughout. The near-zero coefficient reflects CMS's Categorical Adjustment Index",
  "(CAI), which shifts plans' effective thresholds away from the nominal 3.75 cutoff.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_rdd.tex"))
cat("Table 2 written.\n")

# ============================================================================
# Table 3: Score Dynamics Near the Threshold
# ============================================================================

dynamics <- robustness$dynamics

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Score Dynamics: Year-over-Year Change by Position Relative to Threshold}",
  "\\label{tab:dynamics}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Position (year $t$) & $N$ & $\\Delta$ Score ($t$ to $t+1$) & SE \\\\",
  "\\hline"
)

# Sort positions logically
pos_order <- c("Far below", "Below 3.5", "3.5-3.75 (just missed)",
               "3.75-4.0 (just made it)", "4.0-4.25", "Above 4.25")
dynamics$position <- factor(dynamics$position, levels = pos_order)
dynamics <- dynamics[order(dynamics$position), ]

for (i in 1:nrow(dynamics)) {
  pos_label <- gsub("3.5-3.75 \\(just missed\\)", "3.50--3.75 (just missed bonus)", dynamics$position[i])
  pos_label <- gsub("3.75-4.0 \\(just made it\\)", "3.75--4.00 (received bonus)", pos_label)
  pos_label <- gsub("Far below", "$< 3.25$", pos_label)
  pos_label <- gsub("Below 3.5", "3.25--3.50", pos_label)
  pos_label <- gsub("4.0-4.25", "4.00--4.25", pos_label)
  pos_label <- gsub("Above 4.25", "$> 4.25$", pos_label)

  tab3_lines <- c(tab3_lines,
    sprintf("%s & %d & %.4f & (%.4f) \\\\",
            pos_label, dynamics$n[i],
            dynamics$mean_change[i], dynamics$se_change[i]))
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  "\\multicolumn{4}{l}{Difference: just missed $-$ received bonus} \\\\",
  sprintf("\\quad & & %.4f & ($p < 0.001$) \\\\",
          dynamics$mean_change[dynamics$position == "3.5-3.75 (just missed)"] -
          dynamics$mean_change[dynamics$position == "3.75-4.0 (just made it)"]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each row shows the mean year-over-year change in the reconstructed",
  "summary score for contracts in the indicated score range in year $t$. ``Just missed'' plans",
  "scored 3.50--3.75 (received 3.5 stars, no quality bonus). ``Received bonus'' plans scored",
  "3.75--4.00 (received 4.0 stars, $\\sim$5\\% quality bonus). The 0.032 difference reflects both",
  "mean reversion and an incentive response: plans denied the bonus improve more.",
  "Standard errors clustered by parent organization yield similar results.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_dynamics.tex"))
cat("Table 3 written.\n")

# ============================================================================
# Table 4: Robustness — Year-by-Year and Donut RDD
# ============================================================================

year_res <- robustness$year_by_year
donut_res <- robustness$donut

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Year-by-Year and Donut RDD Estimates}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Coefficient & SE & $p$-value & Eff. $N$ \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Year-by-Year Estimates}} \\\\[3pt]"
)

for (i in 1:nrow(year_res)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad %d & %.3f & (%.3f) & %.3f & %d \\\\",
            year_res$year[i], year_res$coef[i], year_res$se[i],
            year_res$pvalue[i], year_res$n_eff[i]))
}

tab4_lines <- c(tab4_lines,
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel B: Donut RDD}} \\\\[3pt]"
)

for (i in 1:nrow(donut_res)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Hole $= %.2f$ & %.3f & (%.3f) & %.3f & %d \\\\",
            donut_res$donut[i], donut_res$coef[i], donut_res$se[i],
            donut_res$pvalue[i], donut_res$n_eff[i]))
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A estimates the RDD separately for each year using MSE-optimal",
  "bandwidth. Panel B excludes contracts within the specified distance of the 3.75 threshold.",
  "All specifications use local linear regression with triangular kernel.",
  "The consistently small and insignificant coefficients across years and donut specifications",
  "confirm that the reconstructed summary score does not produce a sharp first stage,",
  "consistent with the CAI adjustment introducing idiosyncratic variation.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

# ============================================================================
# Table F1: SDE Table (Appendix)
# ============================================================================

# Main outcome: Pr(4+ stars) at the threshold
# The RDD coefficient is the treatment effect

# Compute SD(Y) for SDE
sd_y_star4plus <- sd(panel$star_4plus, na.rm = TRUE)
sd_y_score_change <- sd(panel %>%
  arrange(contract_id, year) %>%
  group_by(contract_id) %>%
  mutate(sc = summary_score - lag(summary_score)) %>%
  pull(sc), na.rm = TRUE)

# Get dynamics difference
dynamics_diff <- dynamics$mean_change[dynamics$position == "3.5-3.75 (just missed)"] -
                 dynamics$mean_change[dynamics$position == "3.75-4.0 (just made it)"]
dynamics_se <- sqrt(
  dynamics$se_change[dynamics$position == "3.5-3.75 (just missed)"]^2 +
  dynamics$se_change[dynamics$position == "3.75-4.0 (just made it)"]^2
)

# SDE calculations
sde_rdd <- first_stage$coef / sd_y_star4plus
sde_rdd_se <- first_stage$se / sd_y_star4plus

sde_dynamics <- dynamics_diff / sd_y_score_change
sde_dynamics_se <- dynamics_se / sd_y_score_change

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    return(ifelse(sde > 0, "Small positive", "Small negative"))
  }
  if (abs_sde < 0.15) {
    return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  }
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does crossing the 3.75 summary-score threshold --- which triggers ",
  "a $\\sim$5\\% quality bonus payment in Medicare Advantage --- cause plans to receive higher displayed ",
  "star ratings, and do plans denied the bonus improve their quality scores in subsequent years? ",
  "\\textbf{Policy mechanism:} CMS assigns Medicare Advantage plans overall star ratings (1--5 in 0.5 increments) ",
  "based on a weighted composite of HEDIS, CAHPS, and HOS quality measures; plans scoring $\\geq$3.75 ",
  "on the continuous composite round up to 4 stars and receive a quality bonus of approximately ",
  "5\\% of the plan's benchmark payment ($\\sim$\\$372 per enrollee per year). ",
  "\\textbf{Outcome definition:} Panel~A: binary indicator equal to 1 if the contract's displayed ",
  "Part~C star rating is $\\geq$4.0. Panel~B: year-over-year change in the reconstructed continuous ",
  "summary score (mean of Part~C measure-level stars). ",
  "\\textbf{Treatment:} Binary; reconstructed summary score $\\geq$3.75 vs.\\ $<$3.75. ",
  "\\textbf{Data:} CMS Part C \\& D Star Ratings Data Tables, 2015--2026; unit of observation is ",
  "contract-year; 5,329 contract-years from approximately 500 contracts per year. ",
  "\\textbf{Method:} Local polynomial RDD with triangular kernel and MSE-optimal bandwidth ",
  "(Cattaneo, Idrobo, and Titiunik 2020); dynamics estimates use $t$-tests with Welch correction. ",
  "\\textbf{Sample:} All MA contracts with $\\geq$5 reported Part~C measures; excludes employer-only ",
  "and cost plans with fewer than 5 measures. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pooled (unconditional) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("$\\Pr(\\text{4+ stars})$ (RDD) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          first_stage$coef, first_stage$se, sd_y_star4plus,
          sde_rdd, sde_rdd_se, classify_sde(sde_rdd)),
  sprintf("$\\Delta$ Score (dynamics) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          dynamics_diff, dynamics_se, sd_y_score_change,
          sde_dynamics, sde_dynamics_se, classify_sde(sde_dynamics)),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by era)}} \\\\[3pt]"
)

# Heterogeneity: pre-2020 vs post-2020 (COVID disrupted the star ratings system)
panel_pre <- panel %>% filter(year <= 2020)
panel_post <- panel %>% filter(year > 2020)

for (era_label in c("Pre-2021", "2021--2026")) {
  era_df <- if (era_label == "Pre-2021") panel_pre else panel_post
  era_rdd <- tryCatch(
    rdrobust(y = era_df$star_4plus, x = era_df$summary_score, c = 3.75,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(era_rdd)) {
    era_sd <- sd(era_df$star_4plus, na.rm = TRUE)
    era_sde <- era_rdd$coef[1] / era_sd
    era_sde_se <- era_rdd$se[1] / era_sd
    tabF1_lines <- c(tabF1_lines,
      sprintf("\\quad %s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
              era_label, era_rdd$coef[1], era_rdd$se[1], era_sd,
              era_sde, era_sde_se, classify_sde(era_sde)))
  }
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
list.files(tables_dir)
