# =============================================================================
# 05_tables.R — LaTeX tables including SDE appendix
# Paper: From the Ballot Box to the Bureau (apep_1409)
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds") |>
  filter(foreign_pop > 0, !is.na(nat_rate), is.finite(nat_rate))
main_results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================

cat("Generating Table 1: Summary statistics...\n")

sum_stats <- panel |>
  mutate(period = ifelse(year < 2004, "Pre-ruling", "Post-ruling")) |>
  group_by(treatment_group, period) |>
  summarize(
    N = n(),
    `Mean nat. rate` = mean(nat_rate, na.rm = TRUE),
    `SD nat. rate` = sd(nat_rate, na.rm = TRUE),
    `Mean naturalizations` = mean(naturalizations, na.rm = TRUE),
    `Mean foreign pop.` = mean(foreign_pop, na.rm = TRUE),
    `Mean total pop.` = mean(total_pop, na.rm = TRUE),
    `Foreign share (%)` = mean(foreign_pop / total_pop * 100, na.rm = TRUE),
    .groups = "drop"
  )

# LaTeX table
tab1_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics by Procedure Type and Period}
\\label{tab:summary}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{Ballot Cantons} & \\multicolumn{2}{c}{Administrative Cantons} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
& Pre-ruling & Post-ruling & Pre-ruling & Post-ruling \\\\
\\midrule\n"

# Extract values
ballot_pre <- sum_stats |> filter(treatment_group == "ballot", period == "Pre-ruling")
ballot_post <- sum_stats |> filter(treatment_group == "ballot", period == "Post-ruling")
admin_pre <- sum_stats |> filter(treatment_group == "admin", period == "Pre-ruling")
admin_post <- sum_stats |> filter(treatment_group == "admin", period == "Post-ruling")

tab1_tex <- paste0(tab1_tex, sprintf(
  "Naturalization rate & %.1f & %.1f & %.1f & %.1f \\\\\n",
  ballot_pre$`Mean nat. rate`, ballot_post$`Mean nat. rate`,
  admin_pre$`Mean nat. rate`, admin_post$`Mean nat. rate`))
tab1_tex <- paste0(tab1_tex, sprintf(
  "\\quad (per 1,000 foreign) & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\\n",
  ballot_pre$`SD nat. rate`, ballot_post$`SD nat. rate`,
  admin_pre$`SD nat. rate`, admin_post$`SD nat. rate`))
tab1_tex <- paste0(tab1_tex, sprintf(
  "Mean naturalizations & %.1f & %.1f & %.1f & %.1f \\\\\n",
  ballot_pre$`Mean naturalizations`, ballot_post$`Mean naturalizations`,
  admin_pre$`Mean naturalizations`, admin_post$`Mean naturalizations`))
tab1_tex <- paste0(tab1_tex, sprintf(
  "Mean foreign population & %.0f & %.0f & %.0f & %.0f \\\\\n",
  ballot_pre$`Mean foreign pop.`, ballot_post$`Mean foreign pop.`,
  admin_pre$`Mean foreign pop.`, admin_post$`Mean foreign pop.`))
tab1_tex <- paste0(tab1_tex, sprintf(
  "Mean total population & %.0f & %.0f & %.0f & %.0f \\\\\n",
  ballot_pre$`Mean total pop.`, ballot_post$`Mean total pop.`,
  admin_pre$`Mean total pop.`, admin_post$`Mean total pop.`))
tab1_tex <- paste0(tab1_tex, sprintf(
  "Foreign share (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
  ballot_pre$`Foreign share (%)`, ballot_post$`Foreign share (%)`,
  admin_pre$`Foreign share (%)`, admin_post$`Foreign share (%)`))
tab1_tex <- paste0(tab1_tex, sprintf(
  "Observations & %s & %s & %s & %s \\\\\n",
  format(ballot_pre$N, big.mark = ","), format(ballot_post$N, big.mark = ","),
  format(admin_pre$N, big.mark = ","), format(admin_post$N, big.mark = ",")))
tab1_tex <- paste0(tab1_tex, sprintf(
  "Municipalities & %d & %d & %d & %d \\\\\n",
  n_distinct(panel$bfs_nr[panel$ballot == 1]),
  n_distinct(panel$bfs_nr[panel$ballot == 1]),
  n_distinct(panel$bfs_nr[panel$ballot == 0]),
  n_distinct(panel$bfs_nr[panel$ballot == 0])))

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Standard deviations in parentheses. Ballot cantons are German-speaking cantons (ZH, LU, SZ, OW, NW, GL, ZG, SO, BL, SH, AR, AI, SG, AG, TG) where municipalities used popular assembly votes for naturalization decisions before the 2003 Federal Court ruling. Administrative cantons (GE, VD, NE, TI, JU, BS) already used written administrative procedures. Pre-ruling: 1981--2003. Post-ruling: 2004--2024. Naturalization rate = annual naturalizations per 1,000 foreign residents.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: Main DiD Results
# =============================================================================

cat("Generating Table 2: Main results...\n")

# Use fixest etable to generate LaTeX
etable(main_results$m1, main_results$m2, main_results$m3,
       main_results$m4, main_results$m5,
       headers = c("Nat. Rate", "Canton Trends", "Log Nat.", "Rate/Pop", "Any Nat."),
       se.below = TRUE,
       fitstat = c("n", "r2", "wr2"),
       tex = TRUE,
       file = "../tables/tab2_main.tex",
       title = "Effect of Abolishing Ballot Naturalization on Naturalization Rates",
       label = "tab:main",
       notes = "Municipality and year fixed effects in all columns. Column (2) adds canton-specific linear year trends. Standard errors clustered at the canton level in parentheses. Ballot = 1 for municipalities in German-speaking cantons that used popular assembly votes for naturalization pre-2003. Post = 1 for years $\\geq$ 2004. Naturalization rate = annual naturalizations per 1,000 foreign residents.",
       replace = TRUE)

# =============================================================================
# TABLE 3: Robustness
# =============================================================================

cat("Generating Table 3: Robustness...\n")

etable(main_results$m2, robustness$full_trends, robustness$weighted,
       robustness$winsorized, robustness$small, robustness$large,
       headers = c("Baseline", "Full Sample", "Pop-Weighted",
                    "Winsorized", "Small Mun.", "Large Mun."),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       tex = TRUE,
       file = "../tables/tab3_robustness.tex",
       title = "Robustness Checks",
       label = "tab:robust",
       notes = "All specifications include municipality FE, year FE, and canton-specific linear trends. Standard errors clustered at the canton level. Full sample includes bilingual cantons (BE, FR, VS, GR, UR) as controls. Small/large split at pre-treatment median population.",
       replace = TRUE)

# =============================================================================
# TABLE 4: Placebo Outcomes
# =============================================================================

cat("Generating Table 4: Placebo outcomes...\n")

etable(robustness$placebo_fpop, robustness$placebo_pop,
       headers = c("Foreign Share (%)", "Pop. Growth (%)"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       tex = TRUE,
       file = "../tables/tab4_placebo.tex",
       title = "Placebo Outcomes: Foreign Population Share and Population Growth",
       label = "tab:placebo",
       notes = "Municipality and year fixed effects. Standard errors clustered at the canton level. Neither outcome should respond to the naturalization procedure reform. Foreign share = foreign population / total population $\\times$ 100.",
       replace = TRUE)

# =============================================================================
# SDE TABLE (Appendix F1)
# =============================================================================

cat("Generating SDE table...\n")

# Preferred specification: m2 (with canton trends)
beta_hat <- coef(main_results$m2)[1]
se_beta <- se(main_results$m2)[1]

# Pre-treatment SD of nat_rate in ballot cantons
pre_sd <- panel |>
  filter(year < 2004, treatment_group == "ballot") |>
  pull(nat_rate) |>
  sd(na.rm = TRUE)

# SDE = beta / SD(Y)
sde_main <- beta_hat / pre_sd
se_sde <- se_beta / pre_sd

# Classification
classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

cat(sprintf("Main outcome: beta=%.3f, SD(Y)=%.3f, SDE=%.4f, class=%s\n",
            beta_hat, pre_sd, sde_main, classify_sde(sde_main)))

# Additional outcomes
# Log naturalizations
beta_log <- coef(main_results$m3)[1]
se_log <- se(main_results$m3)[1]
pre_sd_log <- panel |> filter(year < 2004, treatment_group == "ballot") |>
  pull(log_nat) |> sd(na.rm = TRUE)
sde_log <- beta_log / pre_sd_log
se_sde_log <- se_log / pre_sd_log

# Any naturalization
beta_any <- coef(main_results$m5)[1]
se_any <- se(main_results$m5)[1]
panel$any_nat <- as.integer(panel$naturalizations > 0)
pre_sd_any <- panel |> filter(year < 2004, treatment_group == "ballot") |>
  pull(any_nat) |> sd(na.rm = TRUE)
sde_any <- beta_any / pre_sd_any
se_sde_any <- se_any / pre_sd_any

# Small municipalities
beta_small <- coef(robustness$small)[1]
se_small <- se(robustness$small)[1]

pre_median_pop <- panel |>
  filter(year < 2004) |>
  group_by(bfs_nr) |>
  summarize(median_pop = median(total_pop, na.rm = TRUE))

panel_s <- panel |>
  left_join(pre_median_pop, by = "bfs_nr") |>
  filter(median_pop <= median(pre_median_pop$median_pop))

pre_sd_small <- panel_s |> filter(year < 2004, treatment_group == "ballot") |>
  pull(nat_rate) |> sd(na.rm = TRUE)
sde_small <- beta_small / pre_sd_small
se_sde_small <- se_small / pre_sd_small

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Did the 2003 Federal Court ruling (BGE 129 I 232) that banned ballot-vote naturalization increase aggregate naturalization rates in affected municipalities? ",
  "\\textbf{Policy mechanism:} The ruling prohibited municipalities from using popular assembly votes to decide individual naturalization applications, requiring instead written administrative procedures with stated reasoning; this removed a discriminatory gatekeeping mechanism that disproportionately rejected applicants from non-Western European origins. ",
  "\\textbf{Outcome definition:} Annual naturalization count divided by foreign resident population times 1,000, measuring the rate at which foreign residents acquire Swiss citizenship at the municipal level. ",
  "\\textbf{Treatment:} Binary indicator for municipalities in German-speaking cantons (ZH, LU, SZ, OW, NW, GL, ZG, SO, BL, SH, AR, AI, SG, AG, TG) that used ballot-vote naturalization procedures before the 2003 ruling. ",
  "\\textbf{Data:} Swiss Federal Statistical Office (BFS) demographic balance via PXWeb API, 1981--2024, municipality-year level, 62,393 observations across 1,431 municipalities. ",
  "\\textbf{Method:} Two-way fixed effects DiD with municipality and year fixed effects plus canton-specific linear year trends; standard errors clustered at the canton level. ",
  "\\textbf{Sample:} Restricted to municipalities in pure German-speaking (ballot) and pure French/Italian-speaking (administrative) cantons; bilingual cantons (BE, FR, VS, GR) excluded from primary specification. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome among ballot-canton municipalities. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build SDE table
sde_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
Naturalization rate & ", sprintf("%.3f", beta_hat), " & ", sprintf("%.3f", se_beta), " & ",
  sprintf("%.3f", pre_sd), " & ", sprintf("%.4f", sde_main), " & ", sprintf("%.4f", se_sde), " & ",
  classify_sde(sde_main), " \\\\
Log naturalizations & ", sprintf("%.3f", beta_log), " & ", sprintf("%.3f", se_log), " & ",
  sprintf("%.3f", pre_sd_log), " & ", sprintf("%.4f", sde_log), " & ", sprintf("%.4f", se_sde_log), " & ",
  classify_sde(sde_log), " \\\\
Any naturalization & ", sprintf("%.3f", beta_any), " & ", sprintf("%.3f", se_any), " & ",
  sprintf("%.3f", pre_sd_any), " & ", sprintf("%.4f", se_sde_any), " & ", sprintf("%.4f", se_sde_any), " & ",
  classify_sde(sde_any), " \\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\[3pt]
Small municipalities & ", sprintf("%.3f", beta_small), " & ", sprintf("%.3f", se_small), " & ",
  sprintf("%.3f", pre_sd_small), " & ", sprintf("%.4f", sde_small), " & ", sprintf("%.4f", se_sde_small), " & ",
  classify_sde(sde_small), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
", sde_notes, "
\\end{tablenotes}
\\end{table}\n")

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("05_tables.R complete.\n")
