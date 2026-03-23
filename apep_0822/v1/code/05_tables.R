# 05_tables.R — Generate all LaTeX tables for apep_0822

setwd(file.path(dirname(sys.frame(1)$ofile %||% "."), "."))
source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE)

df <- readRDS(file.path(data_dir, "analysis.rds"))
df <- df %>% mutate(fea_pc_10 = fea_per_capita * 10, log_pop = log(total_pop))
models <- readRDS(file.path(data_dir, "models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

# ===========================================================================
# TABLE 1: Summary Statistics
# ===========================================================================
cat("=== Table 1: Summary Statistics ===\n")

summ_vars <- df %>%
  transmute(
    `Total population` = total_pop,
    `Urban share` = urban_share,
    `FeA beneficiaries per capita` = fea_per_capita,
    `Literacy rate, ages 15--24` = lit_young,
    `Literacy rate, ages 25+` = lit_old,
    `Cohort literacy gap` = lit_cohort_gap,
    `Share secondary education+` = share_secondary_plus,
    `Share tertiary education` = share_tertiary,
    `Share no education` = share_none,
    `Employment rate` = emp_rate,
    `Study rate (ages 10+)` = study_rate
  )

summ_df <- data.frame(
  Variable = names(summ_vars),
  N = sapply(summ_vars, function(x) sum(!is.na(x))),
  Mean = sapply(summ_vars, mean, na.rm = TRUE),
  SD = sapply(summ_vars, sd, na.rm = TRUE),
  Min = sapply(summ_vars, min, na.rm = TRUE),
  Max = sapply(summ_vars, max, na.rm = TRUE),
  stringsAsFactors = FALSE
)

# Format for LaTeX
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Colombian Municipalities, 2018 Census}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "Variable & N & Mean & SD & Min & Max \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(summ_df))) {
  r <- summ_df[i, ]
  if (r$Variable == "Total population") {
    line <- sprintf("%s & %s & %s & %s & %s & %s \\\\",
                    r$Variable, format(r$N, big.mark = ","),
                    format(round(r$Mean), big.mark = ","),
                    format(round(r$SD), big.mark = ","),
                    format(round(r$Min), big.mark = ","),
                    format(round(r$Max), big.mark = ","))
  } else {
    line <- sprintf("%s & %s & %.4f & %.4f & %.4f & %.4f \\\\",
                    r$Variable, format(r$N, big.mark = ","),
                    r$Mean, r$SD, r$Min, r$Max)
  }
  tab1_lines <- c(tab1_lines, line)
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Unit of observation is the municipality. Data from Colombia's 2018 Census (CNPV) via ColOpenData and Familias en Acci\\'{o}n beneficiary records from DPS via datos.gov.co. Literacy rates are computed from census counts of literate persons divided by total population in each age group. FeA beneficiaries per capita is the cumulative number of program beneficiaries (2012--2018) divided by total municipal population. The cohort literacy gap is the difference between ages 15--24 and ages 25+ literacy rates.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tab_dir, "tab1_summary.tex"))
cat("Written tab1_summary.tex\n")

# ===========================================================================
# TABLE 2: Main Results — Cohort Literacy Gap
# ===========================================================================
cat("\n=== Table 2: Main Results ===\n")

etable(
  models$m1, models$m2, models$m3,
  se = "hetero",
  dict = c(
    fea_pc_10 = "FeA per capita ($\\times 10$)",
    log_pop = "Log population",
    urban_share = "Urban share",
    lit_cohort_gap = "Cohort literacy gap"
  ),
  headers = c("(1)", "(2)", "(3)"),
  fixef.group = list("Department FE" = "dept"),
  fitstat = c("n", "r2", "wr2"),
  tex = TRUE,
  file = file.path(tab_dir, "tab2_main.tex"),
  title = "Effect of FeA Intensity on the Cohort Literacy Gap",
  label = "tab:main",
  notes = c(
    "Dependent variable: Literacy rate of ages 15--24 minus literacy rate of ages 25+.",
    "FeA per capita is the cumulative number of Familias en Acci\\'{o}n beneficiaries (2012--2018)",
    "divided by municipal population, scaled by 10 (a coefficient of 0.01 means a 10 percentage",
    "point increase in FeA coverage raises the cohort gap by 1 percentage point).",
    "Heteroskedasticity-robust standard errors in parentheses.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  ),
  replace = TRUE
)
cat("Written tab2_main.tex\n")

# ===========================================================================
# TABLE 3: Level Effects — Young vs Old Literacy
# ===========================================================================
cat("\n=== Table 3: Level Effects ===\n")

etable(
  models$m6, rob_models$r1, models$m8,
  se = "hetero",
  dict = c(
    fea_pc_10 = "FeA per capita ($\\times 10$)",
    log_pop = "Log population",
    urban_share = "Urban share",
    lit_old = "Old-cohort literacy rate",
    lit_young = "Young literacy (15--24)",
    lit_old = "Old literacy (25+)"
  ),
  headers = c("Young literacy", "Young literacy", "Old literacy"),
  fixef.group = list("Department FE" = "dept"),
  fitstat = c("n", "r2", "wr2"),
  tex = TRUE,
  file = file.path(tab_dir, "tab3_levels.tex"),
  title = "FeA Intensity and Literacy Levels by Cohort",
  label = "tab:levels",
  notes = c(
    "Column (1): Young-cohort literacy (ages 15--24) on FeA intensity with department FE and controls.",
    "Column (2): Same, adding old-cohort literacy (ages 25+) as a baseline proxy.",
    "Column (3): Old-cohort literacy on FeA intensity (placebo).",
    "Heteroskedasticity-robust standard errors in parentheses.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  ),
  replace = TRUE
)
cat("Written tab3_levels.tex\n")

# ===========================================================================
# TABLE 4: Robustness
# ===========================================================================
cat("\n=== Table 4: Robustness ===\n")

etable(
  models$m3, rob_models$r2, rob_models$r3, rob_models$r4, rob_models$r8,
  se = "hetero",
  dict = c(
    fea_pc_10 = "FeA per capita ($\\times 10$)",
    fea_pc_10_sq = "FeA per capita squared",
    high_fea = "High FeA (above median)",
    log_pop = "Log population",
    urban_share = "Urban share"
  ),
  headers = c("Baseline", "Binary", "Rural only", "Trimmed", "Quadratic"),
  fixef.group = list("Department FE" = "dept"),
  fitstat = c("n", "r2", "wr2"),
  tex = TRUE,
  file = file.path(tab_dir, "tab4_robustness.tex"),
  title = "Robustness: Cohort Literacy Gap",
  label = "tab:robust",
  notes = c(
    "Dependent variable: Cohort literacy gap (ages 15--24 minus ages 25+).",
    "Column (1): Baseline specification. Column (2): Binary treatment (above/below median FeA).",
    "Column (3): Rural municipalities only (population $<$ 30,000).",
    "Column (4): Trimmed sample (5th--95th percentile of FeA per capita).",
    "Column (5): Quadratic FeA specification.",
    "All specifications include department fixed effects.",
    "Heteroskedasticity-robust standard errors in parentheses.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  ),
  replace = TRUE
)
cat("Written tab4_robustness.tex\n")

# ===========================================================================
# TABLE 5: Education and Employment Outcomes
# ===========================================================================
cat("\n=== Table 5: Education and Employment ===\n")

etable(
  models$m9, models$m10, models$m11, models$m12, models$m13,
  se = "hetero",
  dict = c(
    fea_pc_10 = "FeA per capita ($\\times 10$)",
    log_pop = "Log population",
    urban_share = "Urban share"
  ),
  headers = c("Secondary+", "Tertiary", "No education", "Employment", "Studying"),
  fixef.group = list("Department FE" = "dept"),
  fitstat = c("n", "r2", "wr2"),
  tex = TRUE,
  file = file.path(tab_dir, "tab5_outcomes.tex"),
  title = "FeA Intensity and Municipality-Level Education and Employment",
  label = "tab:outcomes",
  notes = c(
    "Each column regresses a different outcome on FeA per capita ($\\times 10$) with department FE,",
    "log population, and urban share. Outcomes are municipality-level shares from the 2018 Census.",
    "Heteroskedasticity-robust standard errors in parentheses.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  ),
  replace = TRUE
)
cat("Written tab5_outcomes.tex\n")

# ===========================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ===========================================================================
cat("\n=== Table F1: SDE ===\n")

# Compute SDEs from main models
# Main outcome: cohort literacy gap (model m3)
beta_gap <- coef(models$m3)["fea_pc_10"]
se_gap <- sqrt(diag(vcov(models$m3, se = "hetero")))["fea_pc_10"]
sd_y_gap <- sd(df$lit_cohort_gap, na.rm = TRUE)
sd_x_gap <- sd(df$fea_pc_10, na.rm = TRUE)
sde_gap <- beta_gap * sd_x_gap / sd_y_gap  # continuous treatment
se_sde_gap <- se_gap * sd_x_gap / sd_y_gap

# Young literacy (model m6 — conditional on controls)
beta_young <- coef(models$m6)["fea_pc_10"]
se_young <- sqrt(diag(vcov(models$m6, se = "hetero")))["fea_pc_10"]
sd_y_young <- sd(df$lit_young, na.rm = TRUE)
sde_young <- beta_young * sd_x_gap / sd_y_young
se_sde_young <- se_young * sd_x_gap / sd_y_young

# Study rate (model m13)
beta_study <- coef(models$m13)["fea_pc_10"]
se_study <- sqrt(diag(vcov(models$m13, se = "hetero")))["fea_pc_10"]
sd_y_study <- sd(df$study_rate, na.rm = TRUE)
sde_study <- beta_study * sd_x_gap / sd_y_study
se_sde_study <- se_study * sd_x_gap / sd_y_study

# Secondary+ share (model m9)
beta_sec <- coef(models$m9)["fea_pc_10"]
se_sec <- sqrt(diag(vcov(models$m9, se = "hetero")))["fea_pc_10"]
sd_y_sec <- sd(df$share_secondary_plus, na.rm = TRUE)
sde_sec <- beta_sec * sd_x_gap / sd_y_sec
se_sde_sec <- se_sec * sd_x_gap / sd_y_sec

# Classify SDE
classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_rows <- data.frame(
  Outcome = c("Cohort literacy gap", "Young literacy (15--24)",
              "Study rate", "Secondary+ share"),
  Beta = c(beta_gap, beta_young, beta_study, beta_sec),
  SE = c(se_gap, se_young, se_study, se_sec),
  SD_X = rep(sd_x_gap, 4),
  SD_Y = c(sd_y_gap, sd_y_young, sd_y_study, sd_y_sec),
  SDE = c(sde_gap, sde_young, sde_study, sde_sec),
  SE_SDE = c(se_sde_gap, se_sde_young, se_sde_study, se_sde_sec),
  stringsAsFactors = FALSE
)
sde_rows$Classification <- classify(sde_rows$SDE)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Colombia. ",
  "\\textbf{Research question:} Whether conditional cash transfer (CCT) program intensity affects ",
  "intergenerational literacy convergence across municipalities. ",
  "\\textbf{Policy mechanism:} Familias en Acci\\'{o}n provides monthly cash payments to poor households ",
  "conditional on children's school attendance and health check-ups, targeting human capital ",
  "accumulation in children aged 0--17 through direct income support and behavioral conditionality. ",
  "\\textbf{Outcome definition:} Cohort literacy gap equals the literacy rate of ages 15--24 minus ",
  "the literacy rate of ages 25+ in each municipality, measuring intergenerational educational convergence. ",
  "\\textbf{Treatment:} Continuous --- cumulative FeA beneficiaries per municipal population (scaled by 10). ",
  "\\textbf{Data:} Colombia 2018 National Census (CNPV) via ColOpenData and DPS beneficiary records ",
  "via datos.gov.co, 1,100 municipalities. ",
  "\\textbf{Method:} OLS with department fixed effects and heteroskedasticity-robust standard errors. ",
  "\\textbf{Sample:} All Colombian municipalities with at least 50 persons in each age cohort and ",
  "non-missing FeA enrollment data. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation and SD($X$) is the standard deviation of FeA per capita ($\\times 10$). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i, ]
  line <- sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
                  r$Outcome, r$Beta, r$SE, r$SD_X, r$SD_Y, r$SDE, r$SE_SDE, r$Classification)
  sde_lines <- c(sde_lines, line)
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tab_dir, "tabF1_sde.tex"))
cat("Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
list.files(tab_dir)
