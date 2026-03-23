## 05_tables.R — Generate all LaTeX tables
## apep_0805: Prescribed fire liability reform and wildfire severity

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "results.rds"))
robust <- readRDS(file.path(data_dir, "robustness.rds"))
sumstats <- readRDS(file.path(data_dir, "sumstats.rds"))

df <- as.data.frame(panel)
df <- df[complete.cases(df[, c("ln_fires", "year", "state_id", "first_treat")]), ]

# ─────────────────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────────────────
tab1 <- sprintf(
  "\\begin{table}[H]\n\\centering\n\\caption{Summary Statistics}\n\\label{tab:summary}\n\\begin{threeparttable}\n\\begin{tabular}{l rrrr}\n\\toprule\nVariable & Mean & Std.\\ Dev. & Min & Max \\\\\n\\midrule\n%s\n\\bottomrule\n\\end{tabular}\n\\begin{tablenotes}[flushleft]\n\\small\n\\item \\textit{Notes:} $N = %s$ state-year observations across %d states and %d years (1992--2020). Unit of observation is the state-year. Fire data from USDA FPA FOD 6th Edition \\citep{Short2022}. Large fires defined as those exceeding 100 acres.\n\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}",
  paste(sprintf("%s & %s & %s & %s & %s \\\\",
    sumstats$Variable,
    formatC(sumstats$Mean, format = "f", digits = 1, big.mark = ","),
    formatC(sumstats$SD, format = "f", digits = 1, big.mark = ","),
    formatC(sumstats$Min, format = "f", digits = 0, big.mark = ","),
    formatC(sumstats$Max, format = "f", digits = 0, big.mark = ",")),
    collapse = "\n"),
  formatC(nrow(df), big.mark = ","),
  uniqueN(panel$state),
  length(unique(panel$year))
)
writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))
cat("Written tab1_summary.tex\n")

# ─────────────────────────────────────────────────────────
# Table 2: Main Results (CS DiD + TWFE)
# ─────────────────────────────────────────────────────────
# Extract CS DiD ATTs
cs_results <- data.frame(
  outcome = c("Log(1 + fires)", "Log(1 + acres)", "Log(1 + large fires)"),
  cs_att = c(results$agg_fires$overall.att,
             results$agg_acres$overall.att,
             results$agg_large$overall.att),
  cs_se  = c(results$agg_fires$overall.se,
             results$agg_acres$overall.se,
             results$agg_large$overall.se),
  twfe_coef = c(coef(results$twfe_fires)["treated"],
                coef(results$twfe_acres)["treated"],
                coef(results$twfe_large)["treated"]),
  twfe_se = c(se(results$twfe_fires)["treated"],
              se(results$twfe_acres)["treated"],
              se(results$twfe_large)["treated"])
)

# Stars function
stars <- function(coef, se) {
  p <- 2 * pnorm(-abs(coef / se))
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
}

tab2_rows <- paste(sprintf(
  "%s & %s%s & (%s) & %s%s & (%s) \\\\",
  cs_results$outcome,
  formatC(cs_results$cs_att, format = "f", digits = 4),
  stars(cs_results$cs_att, cs_results$cs_se),
  formatC(cs_results$cs_se, format = "f", digits = 4),
  formatC(cs_results$twfe_coef, format = "f", digits = 4),
  stars(cs_results$twfe_coef, cs_results$twfe_se),
  formatC(cs_results$twfe_se, format = "f", digits = 4)
), collapse = "\n")

tab2 <- sprintf(
  "\\begin{table}[H]\n\\centering\n\\caption{Effect of Prescribed Fire Liability Reform on Wildfire Outcomes}\n\\label{tab:main}\n\\begin{threeparttable}\n\\begin{tabular}{l cc cc}\n\\toprule\n& \\multicolumn{2}{c}{Callaway--Sant'Anna} & \\multicolumn{2}{c}{TWFE} \\\\\n\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\nOutcome & ATT & (SE) & Coefficient & (SE) \\\\\n\\midrule\n%s\n\\midrule\nState FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\\nYear FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\\nStates & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\nState-years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n\\bottomrule\n\\end{tabular}\n\\begin{tablenotes}[flushleft]\n\\small\n\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Column 1 reports the overall average treatment effect on the treated (ATT) from the \\citet{CallawayS2021} estimator with doubly robust estimation and bootstrap inference (1,000 iterations). Column 2 reports two-way fixed effects estimates with standard errors clustered at the state level. Treatment is an indicator equal to one after a state shifts from strict liability to simple or gross negligence for prescribed burning. Sample: 1992--2020.\n\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}",
  tab2_rows,
  uniqueN(panel$state), uniqueN(panel$state),
  formatC(nrow(df), big.mark = ","), formatC(nrow(df), big.mark = ",")
)
writeLines(tab2, file.path(table_dir, "tab2_main.tex"))
cat("Written tab2_main.tex\n")

# ─────────────────────────────────────────────────────────
# Table 3: Mechanism + Placebo (Debris burning + Lightning)
# ─────────────────────────────────────────────────────────
mech_results <- data.frame(
  outcome = c("Log(1 + debris fires)", "Log(1 + lightning fires)"),
  att = c(results$agg_debris$overall.att, results$agg_lightning$overall.att),
  se  = c(results$agg_debris$overall.se, results$agg_lightning$overall.se),
  type = c("Mechanism", "Placebo")
)

tab3_rows <- paste(sprintf(
  "%s & %s & %s%s & (%s) \\\\",
  mech_results$outcome,
  mech_results$type,
  formatC(mech_results$att, format = "f", digits = 4),
  stars(mech_results$att, mech_results$se),
  formatC(mech_results$se, format = "f", digits = 4)
), collapse = "\n")

tab3 <- sprintf(
  "\\begin{table}[H]\n\\centering\n\\caption{Mechanism and Placebo Tests}\n\\label{tab:mechanism}\n\\begin{threeparttable}\n\\begin{tabular}{l l cc}\n\\toprule\nOutcome & Test & ATT & (SE) \\\\\n\\midrule\n%s\n\\bottomrule\n\\end{tabular}\n\\begin{tablenotes}[flushleft]\n\\small\n\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Callaway--Sant'Anna ATT with doubly robust estimation. Debris burning fires proxy for prescribed fire activity: if liability reform encourages controlled burns, we expect more reported debris burns. Lightning-caused fires serve as a placebo---state tort reform should not affect naturally ignited wildfires.\n\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}",
  tab3_rows
)
writeLines(tab3, file.path(table_dir, "tab3_mechanism.tex"))
cat("Written tab3_mechanism.tex\n")

# ─────────────────────────────────────────────────────────
# Table 4: Heterogeneity (Private vs Federal land)
# ─────────────────────────────────────────────────────────
het_results <- data.frame(
  outcome = c("Private land fires", "Federal land fires"),
  att = c(results$agg_private$overall.att, results$agg_federal$overall.att),
  se  = c(results$agg_private$overall.se, results$agg_federal$overall.se)
)

tab4_rows <- paste(sprintf(
  "Log(1 + %s) & %s%s & (%s) \\\\",
  tolower(het_results$outcome),
  formatC(het_results$att, format = "f", digits = 4),
  stars(het_results$att, het_results$se),
  formatC(het_results$se, format = "f", digits = 4)
), collapse = "\n")

tab4 <- sprintf(
  "\\begin{table}[H]\n\\centering\n\\caption{Heterogeneity by Land Ownership}\n\\label{tab:heterogeneity}\n\\begin{threeparttable}\n\\begin{tabular}{l cc}\n\\toprule\nOutcome & ATT & (SE) \\\\\n\\midrule\n%s\n\\bottomrule\n\\end{tabular}\n\\begin{tablenotes}[flushleft]\n\\small\n\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Callaway--Sant'Anna ATT with doubly robust estimation. Private land fires are those on privately owned parcels; federal land fires are those on USFS, BLM, NPS, FWS, BIA, or other federal agency land. Liability reform primarily affects private landowner incentives to conduct prescribed burns, so we expect larger effects on private land.\n\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}",
  tab4_rows
)
writeLines(tab4, file.path(table_dir, "tab4_heterogeneity.tex"))
cat("Written tab4_heterogeneity.tex\n")

# ─────────────────────────────────────────────────────────
# Table 5: Robustness
# ─────────────────────────────────────────────────────────
rob_results <- data.frame(
  specification = c(
    "Not-yet-treated control",
    "Excluding pre-1995 reformers",
    "Level: fire count",
    "Level: acres burned",
    "Fires per 1000 sq mi (log)"
  ),
  coef = c(
    robust$agg_nyt$overall.att,
    robust$agg_post95$overall.att,
    coef(robust$twfe_level_fires)["treated"],
    coef(robust$twfe_level_acres)["treated"],
    coef(robust$twfe_area)["treated"]
  ),
  se = c(
    robust$agg_nyt$overall.se,
    robust$agg_post95$overall.se,
    se(robust$twfe_level_fires)["treated"],
    se(robust$twfe_level_acres)["treated"],
    se(robust$twfe_area)["treated"]
  )
)

tab5_rows <- paste(sprintf(
  "%s & %s%s & (%s) \\\\",
  rob_results$specification,
  formatC(rob_results$coef, format = "f", digits = 4),
  stars(rob_results$coef, rob_results$se),
  formatC(rob_results$se, format = "f", digits = 4)
), collapse = "\n")

tab5 <- sprintf(
  "\\begin{table}[H]\n\\centering\n\\caption{Robustness Checks}\n\\label{tab:robustness}\n\\begin{threeparttable}\n\\begin{tabular}{l cc}\n\\toprule\nSpecification & Estimate & (SE) \\\\\n\\midrule\n%s\n\\bottomrule\n\\end{tabular}\n\\begin{tablenotes}[flushleft]\n\\small\n\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Row 1 uses not-yet-treated states as the control group instead of never-treated. Row 2 excludes states that reformed before 1995 (limited pre-treatment data). Rows 3--4 use level outcomes instead of log-transformed. Row 5 normalizes fires by state land area. All specifications include state and year fixed effects. Standard errors clustered at the state level.\n\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}",
  tab5_rows
)
writeLines(tab5, file.path(table_dir, "tab5_robustness.tex"))
cat("Written tab5_robustness.tex\n")

# ─────────────────────────────────────────────────────────
# SDE Table (Appendix F1) — Standardized Effect Sizes
# ─────────────────────────────────────────────────────────

# Pre-treatment SDs for SDE computation
pre_treat_sd <- function(var) {
  # Use only pre-treatment observations for treated states + all obs for never-treated
  idx <- (df$first_treat == 0) | (df$first_treat > 0 & df$year < df$first_treat)
  sd(df[[var]][idx], na.rm = TRUE)
}

sd_fires <- pre_treat_sd("ln_fires")
sd_acres <- pre_treat_sd("ln_acres")
sd_large <- pre_treat_sd("ln_large")

# SDE = beta / SD(Y) for binary treatment
sde_fires <- results$agg_fires$overall.att / sd_fires
sde_acres <- results$agg_acres$overall.att / sd_acres
sde_large <- results$agg_large$overall.att / sd_large

se_sde_fires <- results$agg_fires$overall.se / sd_fires
se_sde_acres <- results$agg_acres$overall.se / sd_acres
se_sde_large <- results$agg_large$overall.se / sd_large

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_df <- data.frame(
  Outcome = c("Log(1 + wildfire count)", "Log(1 + acres burned)", "Log(1 + large fires)"),
  beta = c(results$agg_fires$overall.att, results$agg_acres$overall.att, results$agg_large$overall.att),
  se = c(results$agg_fires$overall.se, results$agg_acres$overall.se, results$agg_large$overall.se),
  sd_y = c(sd_fires, sd_acres, sd_large),
  sde = c(sde_fires, sde_acres, sde_large),
  se_sde = c(se_sde_fires, se_sde_acres, se_sde_large),
  class = classify(c(sde_fires, sde_acres, sde_large))
)

sde_rows <- paste(sprintf(
  "%s & %s & %s & %s & %s & %s & %s \\\\",
  sde_df$Outcome,
  formatC(sde_df$beta, format = "f", digits = 4),
  formatC(sde_df$se, format = "f", digits = 4),
  formatC(sde_df$sd_y, format = "f", digits = 3),
  formatC(sde_df$sde, format = "f", digits = 4),
  formatC(sde_df$se_sde, format = "f", digits = 4),
  sde_df$class
), collapse = "\n")

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does shifting from strict liability to simple or gross negligence for prescribed burning reduce wildfire frequency and severity at the state level? ",
  "\\textbf{Policy mechanism:} State tort reform reduces the legal risk faced by private landowners and land managers who conduct prescribed burns---the most effective wildfire prevention tool---by replacing automatic liability for fire escape with a negligence standard requiring proof of carelessness or recklessness. ",
  "\\textbf{Outcome definition:} Log-transformed annual state-level wildfire count, total acres burned, and count of large fires exceeding 100 acres, from the USDA Fire Program Analysis Fire-Occurrence Database (FPA FOD). ",
  "\\textbf{Treatment:} Binary indicator equal to one after a state enacts prescribed fire liability reform (shift from strict to simple or gross negligence). ",
  "\\textbf{Data:} USDA FPA FOD 6th Edition (Short 2022), 1992--2020, state-year panel, ",
  formatC(nrow(df), big.mark = ","), " observations across ",
  uniqueN(panel$state), " states. ",
  "\\textbf{Method:} Staggered difference-in-differences with Callaway--Sant'Anna (2021) estimator, doubly robust estimation, bootstrap inference (1,000 iterations). ",
  "\\textbf{Sample:} All 50 U.S.\\ states plus District of Columbia over 29 years; treatment group comprises states enacting prescribed fire liability reform between 1994 and 2018 with at least two pre-treatment years in the data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf(
  "\\begin{table}[H]\n\\centering\n\\caption{Standardized Effect Sizes for Main Outcomes}\n\\label{tab:sde}\n\\begin{threeparttable}\n\\begin{tabular}{l cccccc}\n\\toprule\nOutcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n%s\n\\bottomrule\n\\end{tabular}\n\\begin{tablenotes}[flushleft]\n\\small\n%s\n\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}",
  sde_rows, sde_notes
)
writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))
cat("Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
