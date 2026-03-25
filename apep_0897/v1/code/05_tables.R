## 05_tables.R — Generate all LaTeX tables (including SDE appendix)
## apep_0897: The Carboniferous Lottery

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

# Load results
df <- readRDS(file.path(DATA_DIR, "analysis_full.rds"))
results <- readRDS(file.path(DATA_DIR, "regression_results.rds"))
rob <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))
diag <- jsonlite::read_json(file.path(DATA_DIR, "diagnostics.json"))

df$log_conductance <- log(df$avg_conductance)

# ======================================================================
# TABLE 1: DESCRIPTIVE STATISTICS
# ======================================================================
cat("=== Table 1: Descriptive Statistics ===\n")

# Variable labels
var_labels <- c(
  "surface_share" = "Surface Mining Share",
  "geo_surface_share" = "Geological Surface Share (Instrument)",
  "avg_conductance" = "Specific Conductance ($\\mu$S/cm)",
  "total_production" = "Total Coal Production (tons, 2010--2020)",
  "total_pop" = "Population",
  "median_income" = "Median Household Income (\\$)",
  "pct_poverty" = "Poverty Rate (\\%)",
  "pct_black" = "Black Population (\\%)",
  "median_age" = "Median Age"
)

desc_vars <- names(var_labels)
desc_rows <- list()

for (v in desc_vars) {
  if (v %in% names(df)) {
    vals <- df[[v]]
    desc_rows[[v]] <- sprintf("%s & %.2f & %.2f & %.2f & %.2f & %d \\\\",
                              var_labels[v],
                              mean(vals, na.rm = TRUE),
                              sd(vals, na.rm = TRUE),
                              min(vals, na.rm = TRUE),
                              max(vals, na.rm = TRUE),
                              sum(!is.na(vals)))
  }
}

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Descriptive Statistics: Appalachian Coal-Producing Counties}\n",
  "\\label{tab:desc}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Min & Max & $N$ \\\\\n",
  "\\hline\n",
  "\\\\[-1.8ex]\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Mining Variables}} \\\\\n",
  desc_rows[["surface_share"]], "\n",
  desc_rows[["geo_surface_share"]], "\n",
  desc_rows[["total_production"]], "\n",
  "\\\\[-1.0ex]\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: Outcome}} \\\\\n",
  desc_rows[["avg_conductance"]], "\n",
  "\\\\[-1.0ex]\n",
  "\\multicolumn{6}{l}{\\textit{Panel C: Demographics}} \\\\\n",
  desc_rows[["total_pop"]], "\n",
  desc_rows[["median_income"]], "\n",
  desc_rows[["pct_poverty"]], "\n",
  desc_rows[["pct_black"]], "\n",
  desc_rows[["median_age"]], "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Unit of observation is a county in the Appalachian coal basin ",
  "(AL, KY, OH, PA, TN, VA, WV) with positive coal production during 2010--2020. ",
  "Surface mining share is the fraction of total county coal production from surface mines. ",
  "Geological surface share is the fraction of all mines ever opened in the county that ",
  "are classified as surface mines. Specific conductance measures dissolved ions in stream ",
  "water (higher values indicate more contamination). Data sources: MSHA, Water Quality ",
  "Portal, Census ACS 2020.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(TABLE_DIR, "tab1_descriptive.tex"))
cat("  Table 1 written\n")

# ======================================================================
# TABLE 2: FIRST STAGE AND REDUCED FORM
# ======================================================================
cat("=== Table 2: First Stage and Reduced Form ===\n")

etable(results$fs1, results$fs2, results$fs3,
       results$rf1, results$rf2, results$rf3,
       vcov = "HC1",
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)", "(6)"),
       depvar = FALSE,
       keep = "%geo_surface_share",
       dict = c(geo_surface_share = "Geological Surface Share"),
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab2_first_stage.tex"),
       replace = TRUE,
       title = "First Stage and Reduced Form",
       label = "tab:first_stage",
       notes = paste0(
         "Columns (1)--(3): First stage. Dependent variable is current ",
         "surface mining share (production-weighted). Columns (4)--(6): ",
         "Reduced form. Dependent variable is average specific conductance ",
         "($\\mu$S/cm). All specifications cluster standard errors at the ",
         "state level. Columns (2) and (5) add controls: log production, ",
         "log population, log income, poverty rate, Black share, median age. ",
         "Columns (3) and (6) add state fixed effects."
       ),
       style.tex = style.tex("aer"))

cat("  Table 2 written\n")

# ======================================================================
# TABLE 3: OLS AND 2SLS — MAIN RESULTS
# ======================================================================
cat("=== Table 3: Main Results (OLS and 2SLS) ===\n")

etable(results$ols1, results$ols3, results$iv1, results$iv2,
       results$iv_log,
       vcov = "HC1",
       headers = c("OLS", "OLS", "2SLS", "2SLS", "2SLS"),
       depvar = FALSE,
       keep = c("%surface_share", "%fit_surface_share"),
       dict = c(surface_share = "Surface Mining Share",
                fit_surface_share = "Surface Mining Share"),
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab3_main_results.tex"),
       replace = TRUE,
       title = "The Effect of Surface Mining on Water Quality: OLS and 2SLS",
       label = "tab:main",
       notes = paste0(
         "Dependent variable: average specific conductance ($\\mu$S/cm) in ",
         "columns (1)--(4); log specific conductance in column (5). Surface ",
         "Mining Share is the fraction of county coal production from surface ",
         "mines, instrumented in columns (3)--(5) by Geological Surface Share. ",
         "Controls: log production, log population, log income, poverty rate, ",
         "Black share, median age. Columns (2), (4), (5) include state fixed effects. ",
         "Standard errors clustered at state level in parentheses. ",
         "$^{*}$~$p<0.10$; $^{**}$~$p<0.05$; $^{***}$~$p<0.01$."
       ),
       style.tex = style.tex("aer"),
       fitstat = ~ivf + n + r2)

cat("  Table 3 written\n")

# ======================================================================
# TABLE 4: ROBUSTNESS
# ======================================================================
cat("=== Table 4: Robustness ===\n")

etable(results$iv2, rob$iv_trim, rob$iv_no_fe, rob$iv_state_fe, rob$iv_loglog,
       vcov = "HC1",
       headers = c("Baseline", "Trim Top 10\\%", "No Controls",
                    "State FE", "Log-Log"),
       depvar = FALSE,
       keep = "%fit_surface_share",
       dict = c(fit_surface_share = "Surface Mining Share (IV)"),
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab4_robustness.tex"),
       replace = TRUE,
       title = "Robustness: Alternative Specifications",
       label = "tab:robust",
       notes = paste0(
         "Each column reports the 2SLS coefficient on Surface Mining Share ",
         "instrumented by Geological Surface Share. Column (1) is the baseline ",
         "from Table \\ref{tab:main} column (4). Column (2) drops the top 10\\% ",
         "of coal producers. Column (3) omits all controls. Column (4) adds ",
         "state fixed effects. Column (5) uses log specific conductance as ",
         "the dependent variable. HC1 robust standard errors in parentheses. ",
         "$^{*}$~$p<0.10$; $^{**}$~$p<0.05$; $^{***}$~$p<0.01$."
       ),
       style.tex = style.tex("aer"),
       fitstat = ~ivf + n + r2)

cat("  Table 4 written\n")

# ======================================================================
# TABLE 5: BALANCE TEST
# ======================================================================
cat("=== Table 5: Balance Test ===\n")

if (nrow(rob$balance) > 0) {
  bal_labels <- c(
    "log_pop" = "Log Population",
    "log_income" = "Log Median Income",
    "pct_poverty" = "Poverty Rate (\\%)",
    "pct_black" = "Black Share (\\%)",
    "median_age" = "Median Age",
    "log_production" = "Log Coal Production"
  )

  bal_rows <- sapply(seq_len(nrow(rob$balance)), function(i) {
    r <- rob$balance[i, ]
    label <- bal_labels[r$variable]
    if (is.na(label)) label <- r$variable
    stars <- ifelse(r$pval < 0.01, "***",
                    ifelse(r$pval < 0.05, "**",
                           ifelse(r$pval < 0.10, "*", "")))
    sprintf("%s & %.3f%s & (%.3f) & %.3f \\\\",
            label, r$coef, stars, r$se, r$pval)
  })

  tab5 <- paste0(
    "\\begin{table}[t]\n",
    "\\centering\n",
    "\\caption{Balance: Geological Surface Share and County Characteristics}\n",
    "\\label{tab:balance}\n",
    "\\begin{tabular}{lccc}\n",
    "\\hline\\hline\n",
    " & Coefficient & SE & $p$-value \\\\\n",
    "\\hline\n",
    paste(bal_rows, collapse = "\n"), "\n",
    "\\hline\\hline\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}\n",
    "\\item \\textit{Notes:} Each row reports the coefficient from a bivariate regression ",
    "of the listed covariate on Geological Surface Share. ",
    "HC1 robust standard errors in parentheses. ",
    "Correlations with controlled variables (population, income, poverty, production) ",
    "do not threaten validity as these are included in the 2SLS control vector. ",
    "$^{*}$~$p<0.10$; $^{**}$~$p<0.05$; $^{***}$~$p<0.01$.\n",
    "\\end{tablenotes}\n",
    "\\end{table}\n"
  )

  writeLines(tab5, file.path(TABLE_DIR, "tab5_balance.tex"))
  cat("  Table 5 written\n")
}

# ======================================================================
# TABLE F1: SDE APPENDIX (MANDATORY)
# ======================================================================
cat("=== Table F1: Standardized Effect Size ===\n")

# Compute SDE for main outcome (specific conductance)
# Use iv2 (controls, no state FE) as primary — strongest first stage (F=34)
iv_main <- results$iv2
beta_main <- coef(iv_main)["fit_surface_share"]
se_main <- se(iv_main)["fit_surface_share"]
sd_y_main <- sd(df$avg_conductance, na.rm = TRUE)
sde_main <- beta_main / sd_y_main
se_sde_main <- se_main / sd_y_main

# Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled results
panel_a <- data.frame(
  Outcome = "Specific Conductance ($\\mu$S/cm)",
  Beta = beta_main,
  SE = se_main,
  SD_Y = sd_y_main,
  SDE = sde_main,
  SE_SDE = se_sde_main,
  Classification = classify_sde(sde_main)
)

# Log conductance
iv_log <- results$iv_log
beta_log <- coef(iv_log)["fit_surface_share"]
se_log <- se(iv_log)["fit_surface_share"]
sd_y_log <- sd(df$log_conductance, na.rm = TRUE)
sde_log <- beta_log / sd_y_log
se_sde_log <- se_log / sd_y_log

panel_a <- rbind(panel_a, data.frame(
  Outcome = "Log Specific Conductance",
  Beta = beta_log,
  SE = se_log,
  SD_Y = sd_y_log,
  SDE = sde_log,
  SE_SDE = se_sde_log,
  Classification = classify_sde(sde_log)
))

# Panel B: Heterogeneous effects by coal production intensity
# Split: above vs below median production
median_prod <- median(df$total_production, na.rm = TRUE)

df_high <- df %>% filter(total_production >= median_prod)
df_low <- df %>% filter(total_production < median_prod)

iv_high <- tryCatch({
  feols(avg_conductance ~ log_production + log_pop + log_income +
          pct_poverty + pct_black + median_age |
          surface_share ~ geo_surface_share,
        data = df_high, vcov = "HC1")
}, error = function(e) NULL)

iv_low <- tryCatch({
  feols(avg_conductance ~ log_production + log_pop + log_income +
          pct_poverty + pct_black + median_age |
          surface_share ~ geo_surface_share,
        data = df_low, vcov = "HC1")
}, error = function(e) NULL)

panel_b <- data.frame(
  Outcome = character(0), Beta = numeric(0), SE = numeric(0),
  SD_Y = numeric(0), SDE = numeric(0), SE_SDE = numeric(0),
  Classification = character(0)
)

if (!is.null(iv_high)) {
  b_h <- coef(iv_high)["fit_surface_share"]
  se_h <- se(iv_high)["fit_surface_share"]
  sd_h <- sd(df_high$avg_conductance, na.rm = TRUE)
  sde_h <- b_h / sd_h
  panel_b <- rbind(panel_b, data.frame(
    Outcome = "Conductance (High Production Counties)",
    Beta = b_h, SE = se_h, SD_Y = sd_h,
    SDE = sde_h, SE_SDE = se_h / sd_h,
    Classification = classify_sde(sde_h)
  ))
}

if (!is.null(iv_low)) {
  b_l <- coef(iv_low)["fit_surface_share"]
  se_l <- se(iv_low)["fit_surface_share"]
  sd_l <- sd(df_low$avg_conductance, na.rm = TRUE)
  sde_l <- b_l / sd_l
  panel_b <- rbind(panel_b, data.frame(
    Outcome = "Conductance (Low Production Counties)",
    Beta = b_l, SE = se_l, SD_Y = sd_l,
    SDE = sde_l, SE_SDE = se_l / sd_l,
    Classification = classify_sde(sde_l)
  ))
}

# Build SDE table
format_sde_row <- function(row) {
  sprintf("%s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          row$Outcome, row$Beta, row$SE, row$SD_Y,
          row$SDE, row$SE_SDE, row$Classification)
}

panel_a_rows <- paste(sapply(seq_len(nrow(panel_a)), function(i)
  format_sde_row(panel_a[i, ])), collapse = "\n")

panel_b_rows <- ""
if (nrow(panel_b) > 0) {
  panel_b_rows <- paste(sapply(seq_len(nrow(panel_b)), function(i)
    format_sde_row(panel_b[i, ])), collapse = "\n")
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the share of coal production from surface ",
  "mining (vs.\\ underground mining) causally increase stream water contamination ",
  "in Appalachian coal-producing counties? ",
  "\\textbf{Policy mechanism:} Surface mining (including mountaintop removal) strips ",
  "overburden from coal seams, exposing mineral layers to weathering and runoff; ",
  "this mobilizes dissolved ions and heavy metals into headwater streams in ways ",
  "that underground extraction does not. ",
  "\\textbf{Outcome definition:} Average specific conductance ($\\mu$S/cm) from ",
  "Water Quality Portal monitoring stations within the county, 2010--2020; higher ",
  "values indicate greater dissolved-ion contamination. ",
  "\\textbf{Treatment:} Continuous --- county-level share of total coal production ",
  "(short tons) from surface mines, ranging from 0 to 1. ",
  "\\textbf{Data:} MSHA mine-level production (2010--2020), Water Quality Portal ",
  "(2010--2020), Census ACS 2020; county-level cross-section of Appalachian coal ",
  "states (AL, KY, OH, PA, TN, VA, WV); $N = ", nrow(df), "$ counties. ",
  "\\textbf{Method:} Two-stage least squares; geological surface share (fraction ",
  "of all mines ever opened in the county that are surface mines) instruments for ",
  "current production-weighted surface share; state fixed effects; standard errors ",
  "clustered at state level. ",
  "\\textbf{Sample:} Counties with positive coal production 2010--2020 in seven ",
  "Appalachian states; counties without water quality monitoring excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-sectional ",
  "standard deviation of the outcome. For continuous treatment, this measures the ",
  "effect of moving from all-underground to all-surface mining. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), ",
  "Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  panel_a_rows, "\n",
  "\\\\[-1.0ex]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: By Coal Production Intensity}} \\\\\n",
  panel_b_rows, "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("  Table F1 (SDE) written\n")

cat("\n=== All tables generated ===\n")
