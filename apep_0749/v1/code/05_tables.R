## 05_tables.R — Generate LaTeX tables
## apep_0749: The Game-Day Externality

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel    <- fread(file.path(data_dir, "panel_state_quarter.csv"))
panel_gd <- fread(file.path(data_dir, "panel_gameday.csv"))
results  <- readRDS(file.path(data_dir, "main_results.rds"))
rob      <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Reconstruct indices
panel[, time_idx := (year - 2013) * 4 + quarter]
panel[, cohort_idx := fifelse(cohort_yearq == 0, 0,
                                (osb_year - 2013) * 4 + osb_quarter)]
panel[, nonalc_crash_rate := nonalc_crashes / population * 100000 * 4]

panel_gd[, time_idx := (year - 2013) * 4 + quarter]
panel_gd[, cohort_idx := fifelse(cohort_yearq == 0, 0,
                                    (osb_year - 2013) * 4 + osb_quarter)]
panel_gd[, alc_crash_rate := alc_crashes / population * 100000 * 4]

# ============================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

# Split by treatment status
panel[, ever_treated := as.integer(cohort_idx > 0)]

panel[, pop_millions := population / 1e6]
summ_vars <- c("alc_crash_rate", "total_crash_rate", "alc_share",
               "alc_crashes", "total_crashes", "pop_millions")
summ_labels <- c("Alcohol-involved crash rate (per 100K)",
                  "Total fatal crash rate (per 100K)",
                  "Alcohol share of crashes",
                  "Alcohol-involved crashes (count)",
                  "Total fatal crashes (count)",
                  "Population (millions)")

# Pre-treatment means
pre_panel <- panel[treated == 0]

make_summ_row <- function(var, label) {
  treated_vals <- pre_panel[ever_treated == 1, get(var)]
  control_vals <- pre_panel[ever_treated == 0, get(var)]
  c(label,
    sprintf("%.2f", mean(treated_vals, na.rm = TRUE)),
    sprintf("%.2f", sd(treated_vals, na.rm = TRUE)),
    sprintf("%.2f", mean(control_vals, na.rm = TRUE)),
    sprintf("%.2f", sd(control_vals, na.rm = TRUE)))
}

summ_rows <- lapply(seq_along(summ_vars), function(i) {
  make_summ_row(summ_vars[i], summ_labels[i])
})

# Write LaTeX
sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Pre-Treatment Means}\n")
cat("\\label{tab:summary}\n")
cat("\\footnotesize\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Treated States} & \\multicolumn{2}{c}{Control States} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat(" & Mean & SD & Mean & SD \\\\\n")
cat("\\hline\n")
for (row in summ_rows) {
  cat(paste(row, collapse = " & "), "\\\\\n")
}
cat("\\hline\n")
cat(sprintf("States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
            length(unique(panel[ever_treated == 1, state_fips])),
            length(unique(panel[ever_treated == 0, state_fips]))))
cat(sprintf("State-quarters & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
            nrow(pre_panel[ever_treated == 1]),
            nrow(pre_panel[ever_treated == 0])))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Pre-treatment means and standard deviations for states that legalized online sports betting (Treated) and states that did not (Control) during the sample period. Rates are annualized per 100,000 population. Alcohol involvement determined by FARS DRUNK\\_DR variable indicating at least one driver with BAC $>$ 0.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab1_summary.tex written\n")

# ============================================================
# TABLE 2: MAIN RESULTS
# ============================================================
cat("Generating Table 2: Main Results\n")

# Re-run TWFE specifications for table
twfe1 <- feols(alc_crash_rate ~ treated | state_fips + time_idx,
               data = panel, cluster = ~state_fips)
twfe2 <- feols(nonalc_crash_rate ~ treated | state_fips + time_idx,
               data = panel, cluster = ~state_fips)
twfe3 <- feols(alc_share ~ treated | state_fips + time_idx,
               data = panel, cluster = ~state_fips)

# CS-DiD results
cs_att <- results$cs_alc_att
cs_nonalc <- results$cs_nonalc_att
cs_share <- results$cs_share_att

sink(file.path(tables_dir, "tab2_main.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Effect of Online Sports Betting on Fatal Crashes}\n")
cat("\\label{tab:main}\n")
cat("\\small\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{1}{c}{Alcohol-Involved} & \\multicolumn{1}{c}{Non-Alcohol} & \\multicolumn{1}{c}{Alcohol} \\\\\n")
cat(" & \\multicolumn{1}{c}{Crash Rate} & \\multicolumn{1}{c}{Crash Rate} & \\multicolumn{1}{c}{Share} \\\\\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: Callaway-Sant'Anna}} \\\\\n")
cat(sprintf("Online Sports Betting & %s & %s & %s \\\\\n",
            sprintf("%.3f", cs_att$overall.att),
            sprintf("%.3f", cs_nonalc$overall.att),
            sprintf("%.4f", cs_share$overall.att)))
cat(sprintf(" & (%s) & (%s) & (%s) \\\\\n",
            sprintf("%.3f", cs_att$overall.se),
            sprintf("%.3f", cs_nonalc$overall.se),
            sprintf("%.4f", cs_share$overall.se)))
cat(sprintf(" & [%s] & [%s] & [%s] \\\\\n",
            ifelse(abs(cs_att$overall.att / cs_att$overall.se) > 1.96, "$p < 0.05$", ""),
            ifelse(abs(cs_nonalc$overall.att / cs_nonalc$overall.se) > 1.96, "$p < 0.05$", ""),
            ifelse(abs(cs_share$overall.att / cs_share$overall.se) > 1.96, "$p < 0.05$", "")))
cat("[0.5em]\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: TWFE}} \\\\\n")
cat(sprintf("Online Sports Betting & %s & %s & %s \\\\\n",
            sprintf("%.3f", coef(twfe1)[1]),
            sprintf("%.3f", coef(twfe2)[1]),
            sprintf("%.4f", coef(twfe3)[1])))
cat(sprintf(" & (%s) & (%s) & (%s) \\\\\n",
            sprintf("%.3f", se(twfe1)[1]),
            sprintf("%.3f", se(twfe2)[1]),
            sprintf("%.4f", se(twfe3)[1])))
cat("\\hline\n")
cat(sprintf("Pre-treatment mean & %.2f & %.2f & %.3f \\\\\n",
            mean(panel[treated == 0, alc_crash_rate]),
            mean(panel[treated == 0, nonalc_crash_rate]),
            mean(panel[treated == 0, alc_share], na.rm = TRUE)))
cat(sprintf("Observations & %s & %s & %s \\\\\n",
            formatC(nrow(panel), format = "d", big.mark = ","),
            formatC(nrow(panel), format = "d", big.mark = ","),
            formatC(nrow(panel), format = "d", big.mark = ",")))
cat("States & 51 & 51 & 51 \\\\\n")
cat("Treated states & 24 & 24 & 24 \\\\\n")
cat("State FE & Yes & Yes & Yes \\\\\n")
cat("Quarter FE & Yes & Yes & Yes \\\\\n")
cat("Comparison group & Never-treated & Never-treated & Never-treated \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Panel A reports Callaway and Sant'Anna (2021) doubly-robust ATT estimates using never-treated states as the comparison group. Panel B reports standard TWFE estimates. Standard errors clustered at the state level in parentheses. Crash rates are annualized per 100,000 population. Column (1): alcohol-involved fatal crashes (DRUNK\\_DR $> 0$). Column (2): non-alcohol fatal crashes (placebo). Column (3): alcohol share of all fatal crashes. Data: FARS 2013--2022.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab2_main.tex written\n")

# ============================================================
# TABLE 3: GAME-DAY TRIPLE-DIFFERENCE
# ============================================================
cat("Generating Table 3: Game-Day Triple-Difference\n")

# Re-run game-day specifications
gd1 <- feols(alc_crash_rate ~ treated * game_day |
               state_fips + time_idx + game_day,
             data = panel_gd, cluster = ~state_fips)

# Also non-alcohol as placebo
panel_gd[, nonalc_crash_rate := (total_crashes - alc_crashes) / population * 100000 * 4]
gd2 <- feols(nonalc_crash_rate ~ treated * game_day |
               state_fips + time_idx + game_day,
             data = panel_gd, cluster = ~state_fips)

sink(file.path(tables_dir, "tab3_gameday.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{The Game-Day Externality: Triple-Difference Estimates}\n")
cat("\\label{tab:gameday}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & Alcohol-Involved & Non-Alcohol \\\\\n")
cat(" & Crash Rate & Crash Rate \\\\\n")
cat(" & (1) & (2) \\\\\n")
cat("\\hline\n")
cat(sprintf("OSB $\\times$ Game Day & %s & %s \\\\\n",
            sprintf("%.3f", coef(gd1)["treated:game_day"]),
            sprintf("%.3f", coef(gd2)["treated:game_day"])))
cat(sprintf(" & (%s) & (%s) \\\\\n",
            sprintf("%.3f", se(gd1)["treated:game_day"]),
            sprintf("%.3f", se(gd2)["treated:game_day"])))
cat(sprintf("OSB (Non-Game Day) & %s & %s \\\\\n",
            sprintf("%.3f", coef(gd1)["treated"]),
            sprintf("%.3f", coef(gd2)["treated"])))
cat(sprintf(" & (%s) & (%s) \\\\\n",
            sprintf("%.3f", se(gd1)["treated"]),
            sprintf("%.3f", se(gd2)["treated"])))
cat("\\hline\n")
cat(sprintf("Observations & %s & %s \\\\\n",
            formatC(nrow(panel_gd), format = "d", big.mark = ","),
            formatC(nrow(panel_gd), format = "d", big.mark = ",")))
cat("State FE & Yes & Yes \\\\\n")
cat("Quarter FE & Yes & Yes \\\\\n")
cat("Game-day FE & Yes & Yes \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Triple-difference estimates comparing alcohol-involved fatal crash rates on game days versus non-game days, before and after online sports betting legalization. Game days are defined as NFL game days: Sundays, Mondays, and Thursdays during the NFL season (September--February). Standard errors clustered at the state level in parentheses. Data: FARS 2013--2022.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab3_gameday.tex written\n")

# ============================================================
# TABLE 4: ROBUSTNESS
# ============================================================
cat("Generating Table 4: Robustness\n")

sink(file.path(tables_dir, "tab4_robustness.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Robustness of Main Estimates}\n")
cat("\\label{tab:robustness}\n")
cat("\\small\n")
cat("\\begin{tabular}{lccl}\n")
cat("\\hline\\hline\n")
cat("Specification & ATT & SE & Notes \\\\\n")
cat("\\hline\n")
cat(sprintf("Main (CS-DiD, DR) & %.3f & (%.3f) & Baseline \\\\\n",
            results$cs_alc_att$overall.att, results$cs_alc_att$overall.se))
cat(sprintf("Not-yet-treated comparison & %.3f & (%.3f) & Alt.\\ comparison group \\\\\n",
            rob$nyt$overall.att, rob$nyt$overall.se))
cat(sprintf("Excluding COVID cohorts & %.3f & (%.3f) & Drop 2020--2021 adopters \\\\\n",
            rob$nocovid$overall.att, rob$nocovid$overall.se))
cat(sprintf("Excluding NJ (early adopter) & %.3f & (%.3f) & Drop first mover \\\\\n",
            rob$nonj$overall.att, rob$nonj$overall.se))
cat(sprintf("Total crash rate (broader) & %.3f & (%.3f) & All fatal crashes \\\\\n",
            rob$total$overall.att, rob$total$overall.se))
cat(sprintf("Non-alcohol crashes (placebo) & %.3f & (%.3f) & Falsification \\\\\n",
            results$cs_nonalc_att$overall.att, results$cs_nonalc_att$overall.se))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} All specifications use Callaway and Sant'Anna (2021) doubly-robust ATT estimates unless otherwise noted. Standard errors clustered at the state level. Outcome: alcohol-involved fatal crash rate per 100,000 population (annualized) except rows 5--6. Data: FARS 2013--2022.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab4_robustness.tex written\n")

# ============================================================
# TABLE F1: STANDARDIZED EFFECT SIZE (SDE)
# ============================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Pre-treatment SD of outcomes
pre_alc_sd    <- sd(panel[treated == 0, alc_crash_rate])
pre_share_sd  <- sd(panel[treated == 0, alc_share], na.rm = TRUE)
pre_total_sd  <- sd(panel[treated == 0, total_crash_rate])

# SDE = beta / SD(Y)
sde_alc   <- results$cs_alc_att$overall.att / pre_alc_sd
se_sde_alc <- results$cs_alc_att$overall.se / pre_alc_sd

sde_share <- results$cs_share_att$overall.att / pre_share_sd
se_sde_share <- results$cs_share_att$overall.se / pre_share_sd

sde_nonalc <- results$cs_nonalc_att$overall.att / pre_total_sd
se_sde_nonalc <- results$cs_nonalc_att$overall.se / pre_total_sd

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build table rows
sde_rows <- list(
  list("Alcohol-involved crash rate", results$cs_alc_att$overall.att,
       results$cs_alc_att$overall.se, pre_alc_sd, sde_alc, se_sde_alc,
       classify(sde_alc)),
  list("Alcohol share of crashes", results$cs_share_att$overall.att,
       results$cs_share_att$overall.se, pre_share_sd, sde_share, se_sde_share,
       classify(sde_share)),
  list("Non-alcohol crash rate", results$cs_nonalc_att$overall.att,
       results$cs_nonalc_att$overall.se, pre_total_sd, sde_nonalc, se_sde_nonalc,
       classify(sde_nonalc))
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the legalization of online sports betting increase alcohol-involved fatal motor vehicle crashes? ",
  "\\textbf{Policy mechanism:} State-level legalization of online/mobile sports betting platforms enables convenient wagering during sporting events, ",
  "potentially increasing bar attendance and alcohol consumption during games, thereby raising the risk of impaired driving. ",
  "\\textbf{Outcome definition:} Alcohol-involved fatal crash rate per 100,000 population (annualized), where alcohol involvement is defined by the FARS DRUNK\\_DR variable indicating at least one driver with BAC $>$ 0. ",
  "\\textbf{Treatment:} Binary indicator equal to one beginning in the quarter a state first accepts legal online sports wagers. ",
  "\\textbf{Data:} NHTSA Fatality Analysis Reporting System (FARS) 2013--2022, all 50 states plus DC, state-quarter panel with 2,040 observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) doubly-robust ATT with never-treated states as comparison group; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All US states; 24 treated states that legalized online sports betting between 2018 and 2024; 27 never-treated control states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
for (row in sde_rows) {
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
              row[[1]], row[[2]], row[[3]], row[[4]], row[[5]], row[[6]], row[[7]]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tabF1_sde.tex written\n")

cat("\n=== ALL TABLES GENERATED ===\n")
