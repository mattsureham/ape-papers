## 05_tables.R — Generate all LaTeX tables
## apep_1317: Colombia draft lottery and wartime conscription

source("00_packages.R")
data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))
saber11 <- readRDS(file.path(data_dir, "saber11_analysis.rds"))
saberpro <- readRDS(file.path(data_dir, "saberpro_analysis.rds"))

# ===========================================================================
# TABLE 1: Summary Statistics
# ===========================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Panel A: By gender
panel_a <- saber11 %>%
  group_by(Gender = ifelse(male == 1, "Male", "Female")) %>%
  summarise(
    N = formatC(n(), format = "d", big.mark = ","),
    `Math Score` = sprintf("%.1f (%.1f)", mean(math_score, na.rm = TRUE),
                           sd(math_score, na.rm = TRUE)),
    `English Score` = sprintf("%.1f (%.1f)", mean(eng_score, na.rm = TRUE),
                              sd(eng_score, na.rm = TRUE)),
    `SES Stratum` = sprintf("%.2f", mean(stratum, na.rm = TRUE)),
    `Public School (\\%)` = sprintf("%.1f", 100 * mean(public_school, na.rm = TRUE)),
    `Rural (\\%)` = sprintf("%.1f", 100 * mean(rural, na.rm = TRUE)),
    .groups = "drop"
  )

# Panel B: By treatment group
panel_b <- saber11 %>%
  mutate(Group = case_when(
    high_conflict & conflict_cohort ~ "High-conflict, conflict era",
    high_conflict & !conflict_cohort ~ "High-conflict, peace era",
    !high_conflict & conflict_cohort ~ "Low-conflict, conflict era",
    !high_conflict & !conflict_cohort ~ "Low-conflict, peace era"
  )) %>%
  group_by(Group) %>%
  summarise(
    N = formatC(n(), format = "d", big.mark = ","),
    `Male (\\%)` = sprintf("%.1f", 100 * mean(male)),
    `Math Score` = sprintf("%.1f", mean(math_score, na.rm = TRUE)),
    `SD(Math)` = sprintf("%.1f", sd(math_score, na.rm = TRUE)),
    .groups = "drop"
  )

# Write Table 1 to LaTeX
tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "& N & Math Score & English Score & SES Stratum & Public (\\%) & Rural (\\%) \\\\",
  "& & (SD) & (SD) & & & \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: By Gender}} \\\\[3pt]"
)

for (i in seq_len(nrow(panel_a))) {
  tab1_tex <- c(tab1_tex, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    panel_a$Gender[i], panel_a$N[i], panel_a$`Math Score`[i],
    panel_a$`English Score`[i], panel_a$`SES Stratum`[i],
    panel_a$`Public School (\\%)`[i], panel_a$`Rural (\\%)`[i]
  ))
}

tab1_tex <- c(tab1_tex,
  "\\hline",
  "& N & Male (\\%) & Math Score & SD(Math) & & \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: By Treatment Group}} \\\\[3pt]"
)

for (i in seq_len(nrow(panel_b))) {
  tab1_tex <- c(tab1_tex, sprintf(
    "%s & %s & %s & %s & %s & & \\\\",
    panel_b$Group[i], panel_b$N[i], panel_b$`Male (\\%)`[i],
    panel_b$`Math Score`[i], panel_b$`SD(Math)`[i]
  ))
}

tab1_tex <- c(tab1_tex,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from ICFES Saber 11 exam, 2010--2022.",
  "919,484 individual test-takers across 27 Colombian departments.",
  "Panel A reports means with standard deviations in parentheses.",
  "SES stratum ranges from 1 (lowest) to 6 (highest).",
  "High-conflict departments are those above the median pre-peace-deal homicide rate.",
  "Conflict-era cohorts are individuals born in 1998 or earlier, who turned 18 before the 2016 FARC peace deal.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ===========================================================================
# TABLE 2: Main DDD Results (Math Scores)
# ===========================================================================
cat("Generating Table 2: Main DDD Results...\n")

models_main <- list(
  results$math_dd,
  results$math_dd_ctrl,
  results$math_ddd,
  results$math_ddd_ctrl,
  results$math_continuous
)

etable(models_main,
       file = file.path(table_dir, "tab2_main_math.tex"),
       title = "The Conscription Tax: Triple-Difference Estimates on Math Scores",
       label = "tab:main_math",
       dict = c(
         "male" = "Male",
         "conflict_cohort" = "Conflict Cohort",
         "high_conflictTRUE" = "High Conflict",
         "conflict_intensity" = "Conflict Intensity",
         "public_school" = "Public School",
         "rural" = "Rural",
         "stratum" = "SES Stratum"
       ),
       headers = c("DD", "DD + Ctrl", "DDD", "DDD + Ctrl", "Continuous"),
       depvar = FALSE,
       se.below = TRUE,
       fitstat = c("n", "wr2"),
       notes = paste0(
         "Data: ICFES Saber 11, 2010--2022. Dependent variable: math score (mean 49.3, SD 11.5). ",
         "Conflict Cohort = born $\\leq$ 1998 (turned 18 before peace deal). ",
         "High Conflict = department above median pre-peace homicide rate. ",
         "All models include exam-year and department fixed effects. ",
         "Standard errors clustered at department level (27 clusters) in parentheses. ",
         "* p$<$0.05, ** p$<$0.01, *** p$<$0.001."
       ),
       replace = TRUE)

# ===========================================================================
# TABLE 3: English Scores and Saber Pro
# ===========================================================================
cat("Generating Table 3: Additional Outcomes...\n")

models_outcomes <- list(
  results$eng_dd,
  results$eng_ddd_ctrl,
  results$sp_dd,
  results$sp_ddd
)

etable(models_outcomes,
       file = file.path(table_dir, "tab3_outcomes.tex"),
       title = "Conscription Effects on English Scores and University Exit Exam",
       label = "tab:outcomes",
       dict = c(
         "male" = "Male",
         "conflict_cohort" = "Conflict Cohort",
         "high_conflictTRUE" = "High Conflict",
         "as.integer(high_conflict)" = "High Conflict",
         "public_school" = "Public School",
         "rural" = "Rural",
         "stratum" = "SES Stratum"
       ),
       headers = c("Eng DD", "Eng DDD", "SP DD", "SP DDD"),
       depvar = FALSE,
       se.below = TRUE,
       fitstat = c("n", "wr2"),
       notes = paste0(
         "Columns (1)--(2): ICFES Saber 11 English scores. ",
         "Columns (3)--(4): ICFES Saber Pro quantitative reasoning scores. ",
         "All models include exam-year and department FE. ",
         "Clustered SEs (department) in parentheses."
       ),
       replace = TRUE)

# ===========================================================================
# TABLE 4: Robustness (Placebo + Heterogeneity)
# ===========================================================================
cat("Generating Table 4: Robustness...\n")

# Build robustness summary table manually
ddd_var <- "male:high_conflictTRUE:conflict_cohort"
hc_cc_var <- "high_conflictTRUE:conflict_cohort"

rob_rows <- data.frame(
  Specification = c(
    "Baseline DDD",
    "Placebo: Female sample",
    "Low SES (Stratum 1--2)",
    "High SES (Stratum 3+)",
    "Public schools",
    "Private schools"
  ),
  Coefficient = c(
    coef(results$math_ddd_ctrl)[ddd_var],
    coef(robust$placebo_female)[hc_cc_var],
    coef(robust$ses_low)[ddd_var],
    coef(robust$ses_high)[ddd_var],
    coef(robust$school_public)[ddd_var],
    coef(robust$school_private)[ddd_var]
  ),
  SE = c(
    sqrt(vcov(results$math_ddd_ctrl)[ddd_var, ddd_var]),
    sqrt(vcov(robust$placebo_female)[hc_cc_var, hc_cc_var]),
    sqrt(vcov(robust$ses_low)[ddd_var, ddd_var]),
    sqrt(vcov(robust$ses_high)[ddd_var, ddd_var]),
    sqrt(vcov(robust$school_public)[ddd_var, ddd_var]),
    sqrt(vcov(robust$school_private)[ddd_var, ddd_var])
  ),
  stringsAsFactors = FALSE
)

rob_rows$Stars <- ifelse(abs(rob_rows$Coefficient / rob_rows$SE) > 2.576, "***",
                  ifelse(abs(rob_rows$Coefficient / rob_rows$SE) > 1.96, "**",
                  ifelse(abs(rob_rows$Coefficient / rob_rows$SE) > 1.645, "*", "")))

tab4_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: DDD Estimates Across Specifications}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE \\\\",
  "\\hline"
)

for (i in seq_len(nrow(rob_rows))) {
  tab4_tex <- c(tab4_tex, sprintf(
    "%s & %.3f%s & (%.3f) \\\\",
    rob_rows$Specification[i], rob_rows$Coefficient[i],
    rob_rows$Stars[i], rob_rows$SE[i]
  ))
  if (i == 1 || i == 2) tab4_tex <- c(tab4_tex, "[3pt]")
}

tab4_tex <- c(tab4_tex,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each row reports the DDD coefficient from a separate regression.",
  "Baseline is Male $\\times$ High Conflict $\\times$ Conflict Cohort on math scores.",
  "Placebo uses female sample only; coefficient is High Conflict $\\times$ Conflict Cohort.",
  "All regressions include exam-year and department fixed effects.",
  "Standard errors clustered at the department level (27 clusters).",
  "* p$<$0.1, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))

# ===========================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY
# ===========================================================================
cat("Generating Table F1: SDE...\n")

# Compute SDEs for main outcomes
sd_math <- sd(saber11$math_score, na.rm = TRUE)
sd_eng <- sd(saber11$eng_score, na.rm = TRUE)
sd_quant <- sd(saberpro$quant_score, na.rm = TRUE)

ddd_math <- coef(results$math_ddd_ctrl)[ddd_var]
se_ddd_math <- sqrt(vcov(results$math_ddd_ctrl)[ddd_var, ddd_var])

eng_ddd_var <- "male:high_conflictTRUE:conflict_cohort"
ddd_eng <- coef(results$eng_ddd_ctrl)[eng_ddd_var]
se_ddd_eng <- sqrt(vcov(results$eng_ddd_ctrl)[eng_ddd_var, eng_ddd_var])

# DD for Saber Pro (since DDD is null, use DD)
dd_sp_var <- "male:conflict_cohort"
dd_sp <- coef(results$sp_dd)[dd_sp_var]
se_dd_sp <- sqrt(vcov(results$sp_dd)[dd_sp_var, dd_sp_var])

# SDE calculations
sde_math <- ddd_math / sd_math
se_sde_math <- se_ddd_math / sd_math
sde_eng <- ddd_eng / sd_eng
se_sde_eng <- se_ddd_eng / sd_eng
sde_sp <- dd_sp / sd_quant
se_sde_sp <- se_dd_sp / sd_quant

classify_sde <- function(s) {
  s <- abs(s)
  if (s > 0.15) return("Large")
  if (s > 0.05) return("Moderate")
  if (s > 0.005) return("Small")
  return("Null")
}

sde_sign <- function(coef, sde) {
  cls <- classify_sde(sde)
  if (coef < 0 && cls != "Null") cls <- paste0(cls, " negative")
  if (coef >= 0 && cls != "Null") cls <- paste0(cls, " positive")
  return(cls)
}

# Heterogeneity: Low vs High SES
low_ddd <- coef(robust$ses_low)[ddd_var]
se_low_ddd <- sqrt(vcov(robust$ses_low)[ddd_var, ddd_var])
high_ddd <- coef(robust$ses_high)[ddd_var]
se_high_ddd <- sqrt(vcov(robust$ses_high)[ddd_var, ddd_var])

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Colombia. ",
  "\\textbf{Research question:} Does wartime military conscription reduce academic achievement for young men in conflict-affected departments? ",
  "\\textbf{Policy mechanism:} Colombia's mandatory draft lottery (\\textit{sorteo}) randomly selects approximately 90,000 males annually for 12--24 months of military service; the 2016 FARC peace deal sharply reduced combat risk for post-deal cohorts, creating cohort-level variation in the cost of conscription. ",
  "\\textbf{Outcome definition:} ICFES Saber 11 mathematics score (standardized national high school exit exam, scored 0--100). ",
  "\\textbf{Treatment:} Binary classification of birth cohorts as conflict-era (born $\\leq$ 1998, turned 18 before peace deal) vs.~peace-era, interacted with binary department conflict intensity (above/below median pre-peace homicide rate) and male gender. ",
  "\\textbf{Data:} ICFES Saber 11, 2010--2022, 919,484 individual test-takers across 27 departments. ",
  "\\textbf{Method:} Triple-difference (Male $\\times$ High-Conflict Department $\\times$ Conflict-Era Cohort) with exam-year and department fixed effects; standard errors clustered at department level. ",
  "\\textbf{Sample:} All Saber 11 test-takers aged 14--25 born 1990--2006 in departments with available conflict data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Math (DDD) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          ddd_math, se_ddd_math, sd_math, sde_math, se_sde_math,
          sde_sign(ddd_math, sde_math)),
  sprintf("English (DDD) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          ddd_eng, se_ddd_eng, sd_eng, sde_eng, se_sde_eng,
          sde_sign(ddd_eng, sde_eng)),
  sprintf("Quant Reasoning (DD) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          dd_sp, se_dd_sp, sd_quant, sde_sp, se_sde_sp,
          sde_sign(dd_sp, sde_sp)),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\[3pt]",
  sprintf("Math, Low SES & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          low_ddd, se_low_ddd, sd_math, low_ddd/sd_math, se_low_ddd/sd_math,
          sde_sign(low_ddd, low_ddd/sd_math)),
  sprintf("Math, High SES & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          high_ddd, se_high_ddd, sd_math, high_ddd/sd_math, se_high_ddd/sd_math,
          sde_sign(high_ddd, high_ddd/sd_math)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat(sprintf("Table files in %s:\n", table_dir))
cat(paste("  ", list.files(table_dir), collapse = "\n"), "\n")
