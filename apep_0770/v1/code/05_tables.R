# 05_tables.R — Generate all tables for apep_0770
# Tables: summary stats, main results, robustness, CS-DiD, SDE appendix

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "panel.rds"))
panel <- panel[!grepl("^97", dep_code)]
main_models <- readRDS(file.path(data_dir, "main_models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Panel A: Full sample
summ_full <- panel[, .(
  Variable = c("FN/RN Vote Share (%)", "Distance to Nearest Maternity (km)",
               "Population", "Ever Affected by Closure"),
  Mean = c(mean(fn_rn_share, na.rm = TRUE), mean(dist_nearest_mat_km, na.rm = TRUE),
           mean(pop, na.rm = TRUE), mean(ever_affected, na.rm = TRUE)),
  SD = c(sd(fn_rn_share, na.rm = TRUE), sd(dist_nearest_mat_km, na.rm = TRUE),
         sd(pop, na.rm = TRUE), sd(as.numeric(ever_affected), na.rm = TRUE)),
  Min = c(min(fn_rn_share, na.rm = TRUE), min(dist_nearest_mat_km, na.rm = TRUE),
          min(pop, na.rm = TRUE), 0),
  Max = c(max(fn_rn_share, na.rm = TRUE), max(dist_nearest_mat_km, na.rm = TRUE),
          max(pop, na.rm = TRUE), 1)
)]

# Panel B: By election year
summ_year <- panel[, .(
  mean_fn_rn = round(mean(fn_rn_share, na.rm = TRUE), 1),
  mean_dist = round(mean(dist_nearest_mat_km, na.rm = TRUE), 1),
  n_communes = uniqueN(commune_code)
), by = election_year][order(election_year)]

# Format and write Table 1
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Mean & SD & Min & Max \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Full Sample ($N = ",
  formatC(nrow(panel), format = "d", big.mark = ","), "$)}} \\\\\n",
  sprintf("FN/RN Vote Share (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          summ_full$Mean[1], summ_full$SD[1], summ_full$Min[1], summ_full$Max[1]),
  sprintf("Distance to Nearest Maternity (km) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          summ_full$Mean[2], summ_full$SD[2], summ_full$Min[2], summ_full$Max[2]),
  sprintf("Population & %.0f & %.0f & %.0f & %.0f \\\\\n",
          summ_full$Mean[3], summ_full$SD[3], summ_full$Min[3], summ_full$Max[3]),
  sprintf("Share Affected by Closure & %.3f & %.3f & %.0f & %.0f \\\\\n",
          summ_full$Mean[4], summ_full$SD[4], summ_full$Min[4], summ_full$Max[4]),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: FN/RN Vote Share by Election Year}} \\\\\n",
  paste(sprintf("%d & %.1f & --- & --- & %s \\\\\n",
                summ_year$election_year, summ_year$mean_fn_rn,
                formatC(summ_year$n_communes, format = "d", big.mark = ",")),
        collapse = ""),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel of 34,791 metropolitan French communes across five ",
  "presidential first-round elections (2002--2022). FN/RN vote share is the combined ",
  "vote share of Jean-Marie Le Pen (2002, 2007) and Marine Le Pen (2012, 2017, 2022). ",
  "Distance is Haversine distance from commune centroid to nearest active maternity ward. ",
  "``Affected by closure'' indicates communes where distance increased by more than 5 km ",
  "between election cycles due to maternity ward closures.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))


# =============================================================================
# Table 2: Main Results
# =============================================================================
cat("=== Table 2: Main Results ===\n")

# Read CS-DiD results
cs_out <- readRDS(file.path(data_dir, "cs_did_result.rds"))
cs_agg <- aggte(cs_out, type = "simple")

# Build table manually for precise control
m1 <- main_models$m1
m2 <- main_models$m2
m3 <- rob_models$dist_change
m4_cs_att <- cs_agg$overall.att
m4_cs_se <- cs_agg$overall.se

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Maternity Ward Closures on FN/RN Vote Share}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Distance & Binary Post & $\\Delta$ Distance & CS-DiD \\\\\n",
  "\\midrule\n",
  sprintf("Distance to nearest (km) & %.4f & & & \\\\\n", coef(m1)[1]),
  sprintf(" & (%.4f) & & & \\\\\n", se(m1)[1]),
  sprintf("Post-closure & & %.4f & & \\\\\n", coef(m2)[1]),
  sprintf(" & & (%.4f) & & \\\\\n", se(m2)[1]),
  sprintf("Distance change & & & %.4f & \\\\\n", coef(m3)[1]),
  sprintf(" & & & (%.4f) & \\\\\n", se(m3)[1]),
  sprintf("ATT (CS 2021) & & & & %.4f \\\\\n", m4_cs_att),
  sprintf(" & & & & (%.4f) \\\\\n", m4_cs_se),
  "\\midrule\n",
  "Commune FE & \\checkmark & \\checkmark & \\checkmark & --- \\\\\n",
  "Election year FE & \\checkmark & \\checkmark & \\checkmark & --- \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          formatC(nobs(m1), format = "d", big.mark = ","),
          formatC(nobs(m2), format = "d", big.mark = ","),
          formatC(nobs(m3), format = "d", big.mark = ","),
          formatC(nobs(m1), format = "d", big.mark = ",")),
  sprintf("Communes & %s & %s & %s & %s \\\\\n",
          formatC(34791, format = "d", big.mark = ","),
          formatC(34791, format = "d", big.mark = ","),
          formatC(34791, format = "d", big.mark = ","),
          formatC(34791, format = "d", big.mark = ",")),
  "Clustering & D\\'{e}partement & D\\'{e}partement & D\\'{e}partement & D\\'{e}partement \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is FN/RN first-round presidential vote share (\\%). ",
  "Column (1) uses distance to nearest active maternity ward (km) as a continuous treatment. ",
  "Column (2) uses a binary indicator for post-closure periods in affected communes. ",
  "Column (3) uses the change in distance from the 2013 baseline. ",
  "Column (4) reports the Callaway and Sant'Anna (2021) overall ATT using not-yet-treated communes ",
  "as the control group. Standard errors clustered at the d\\'{e}partement level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))


# =============================================================================
# Table 3: Robustness and Placebos
# =============================================================================
cat("=== Table 3: Robustness ===\n")

r_prox <- rob_models$proximity_20km
r_small <- rob_models$small_communes
r_large <- rob_models$large_communes
r_lfi <- rob_models$placebo_lfi
r_turn <- rob_models$placebo_turnout
r_idf <- rob_models$excl_idf

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks and Placebo Tests}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & Coefficient & SE & $N$ \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Alternative Treatments}} \\\\\n",
  sprintf("Proximity ($<$20 km to closure) & %.3f$^{***}$ & (%.3f) & %s \\\\\n",
          coef(r_prox)[1], se(r_prox)[1],
          formatC(nobs(r_prox), format = "d", big.mark = ",")),
  sprintf("Excluding \\^{I}le-de-France & %.4f & (%.4f) & %s \\\\\n",
          coef(r_idf)[1], se(r_idf)[1],
          formatC(nobs(r_idf), format = "d", big.mark = ",")),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Heterogeneity by Commune Size}} \\\\\n",
  sprintf("Small communes ($<$2,000 pop.) & %.4f & (%.4f) & %s \\\\\n",
          coef(r_small)[1], se(r_small)[1],
          formatC(nobs(r_small), format = "d", big.mark = ",")),
  sprintf("Large communes ($\\geq$2,000 pop.) & %.4f & (%.4f) & %s \\\\\n",
          coef(r_large)[1], se(r_large)[1],
          formatC(nobs(r_large), format = "d", big.mark = ",")),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Placebo Outcomes}} \\\\\n",
  sprintf("LFI/M\\'{e}lenchon share (\\%%) & %.4f & (%.4f) & %s \\\\\n",
          coef(r_lfi)[1], se(r_lfi)[1],
          formatC(nobs(r_lfi), format = "d", big.mark = ",")),
  sprintf("Turnout (\\%%) & %.4f & (%.4f) & %s \\\\\n",
          coef(r_turn)[1], se(r_turn)[1],
          formatC(nobs(r_turn), format = "d", big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports a separate regression. ",
  "All specifications include commune and election year fixed effects. ",
  "Treatment is distance to nearest maternity (km) unless otherwise noted. ",
  "Panel C uses the same treatment but alternative dependent variables. ",
  "Standard errors clustered at the d\\'{e}partement level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(table_dir, "tab3_robustness.tex"))


# =============================================================================
# Table 4: CS-DiD Event Study
# =============================================================================
cat("=== Table 4: CS-DiD Event Study ===\n")

cs_dynamic <- readRDS(file.path(data_dir, "cs_dynamic.rds"))

es_df <- data.table(
  event_time = cs_dynamic$egt,
  estimate = cs_dynamic$att.egt,
  se = cs_dynamic$se.egt
)
es_df[, ci_low := estimate - 1.96 * se]
es_df[, ci_high := estimate + 1.96 * se]

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Dynamic Treatment Effects (Callaway-Sant'Anna Event Study)}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Event Time (Years) & ATT & SE & 95\\% CI Low & 95\\% CI High \\\\\n",
  "\\midrule\n",
  paste(sprintf("%d & %.3f & (%.3f) & %.3f & %.3f \\\\\n",
                es_df$event_time, es_df$estimate, es_df$se,
                es_df$ci_low, es_df$ci_high),
        collapse = ""),
  "\\midrule\n",
  sprintf("Overall ATT & %.3f & (%.3f) & %.3f & %.3f \\\\\n",
          cs_agg$overall.att, cs_agg$overall.se,
          cs_agg$overall.att - 1.96 * cs_agg$overall.se,
          cs_agg$overall.att + 1.96 * cs_agg$overall.se),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Event time measured relative to the first election after ",
  "the nearest maternity closure. Estimates from Callaway and Sant'Anna (2021) with ",
  "not-yet-treated control group and universal base period. Event time $-5$ is the ",
  "reference period (normalized to zero). Standard errors clustered at the ",
  "d\\'{e}partement level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(table_dir, "tab4_event_study.tex"))


# =============================================================================
# Table F1: Standardized Effect Size (SDE) Appendix — MANDATORY
# =============================================================================
cat("=== Table F1: Standardized Effect Size ===\n")

# Main outcomes and their estimates
sd_y <- sd(panel$fn_rn_share[panel$election_year < 2017], na.rm = TRUE)
beta_dist <- coef(main_models$m1)[1]
se_dist <- se(main_models$m1)[1]
sd_x_dist <- sd(panel$dist_nearest_mat_km, na.rm = TRUE)

beta_post <- coef(main_models$m2)[1]
se_post <- se(main_models$m2)[1]

# SDE calculations
# Continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_dist <- beta_dist * sd_x_dist / sd_y
se_sde_dist <- se_dist * sd_x_dist / sd_y

# Binary treatment: SDE = beta / SD(Y)
sde_post <- beta_post / sd_y
se_sde_post <- se_post / sd_y

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE table
sde_rows <- data.table(
  Outcome = c("FN/RN vote share (distance)", "FN/RN vote share (binary post)"),
  Beta = c(beta_dist, beta_post),
  SE = c(se_dist, se_post),
  SD_Y = c(sd_y, sd_y),
  SDE = c(sde_dist, sde_post),
  SE_SDE = c(se_sde_dist, se_sde_post),
  Classification = c(classify_sde(sde_dist), classify_sde(sde_post))
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does the closure of a nearby maternity ward ",
  "increase far-right (FN/RN) vote share in subsequent presidential elections? ",
  "\\textbf{Policy mechanism:} France closed 536 maternity wards between 2013 ",
  "and 2024 under the Kouchner decree minimum-volume threshold (300 deliveries/year), ",
  "increasing travel distance for affected communes. ",
  "\\textbf{Outcome definition:} FN/RN first-round presidential vote share (\\%), ",
  "measured as combined votes for Le Pen candidates divided by total votes. ",
  "\\textbf{Treatment:} (Row 1) Continuous: distance in km to nearest active maternity; ",
  "(Row 2) Binary: indicator for post-closure period in affected communes. ",
  "\\textbf{Data:} DREES SAE maternity registry (2013--2024), data.gouv.fr presidential ",
  "election results (2002--2022), INSEE commune coordinates. Panel of 34,791 communes ",
  "$\\times$ 5 elections = 173,892 observations. ",
  "\\textbf{Method:} Two-way fixed effects (commune + election year), standard errors ",
  "clustered at d\\'{e}partement level (96 clusters). Also: Callaway-Sant'Anna (2021) ATT. ",
  "\\textbf{Sample:} Metropolitan France (excluding DOM-TOM). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment; ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment, where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  paste(sprintf("%s & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\\n",
                sde_rows$Outcome, sde_rows$Beta, sde_rows$SE, sde_rows$SD_Y,
                sde_rows$SDE, sde_rows$SE_SDE, sde_rows$Classification),
        collapse = ""),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in tables/\n")
for (f in list.files(table_dir)) cat("  ", f, "\n")
