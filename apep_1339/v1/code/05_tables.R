## ==========================================================
## 05_tables.R — Generate all LaTeX tables
## Paper: Obsolete by Design (apep_1339)
## ==========================================================

source("00_packages.R")

data_dir   <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## -----------------------------------------------------------
## Load data and results
## -----------------------------------------------------------
panel      <- fread(file.path(data_dir, "state_year_panel.csv"))
dams       <- fread(file.path(data_dir, "dams_clean.csv"))
state_dams <- fread(file.path(data_dir, "state_year_panel.csv"))
main_res   <- readRDS(file.path(data_dir, "main_results.rds"))
rob_res    <- readRDS(file.path(data_dir, "robustness_results.rds"))

## -----------------------------------------------------------
## Table 1: Summary Statistics
## -----------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

# State-level cross-section
state_cs <- panel[year == 2024, .(state_abbr, n_dams, n_pre1970, pre1970_share,
                                   total_storage, mean_year_built, n_high_hazard)]

# Panel outcomes
panel_stats <- panel[, .(
  flood_declared = flood_declared,
  n_flood_decl = n_flood_decl,
  n_claims = n_claims,
  pre1970_share = pre1970_share,
  log_n_dams = log_n_dams,
  design_gap = design_gap,
  precip_ratio = precip_ratio
)]

# Generate summary stats
vars_panel <- c("flood_declared", "n_flood_decl", "n_claims",
                "pre1970_share", "log_n_dams", "design_gap", "precip_ratio")

stats_df <- data.frame(
  Variable = c("Flood Declaration (=1)", "Flood Declaration Count",
               "NFIP Claims", "Pre-1970 Dam Share",
               "Log(Dam Count + 1)", "Design Gap Index",
               "Precipitation Ratio (2000s/1950s)"),
  N = sapply(vars_panel, function(v) sum(!is.na(panel[[v]]))),
  Mean = sapply(vars_panel, function(v) round(mean(panel[[v]], na.rm = TRUE), 3)),
  SD = sapply(vars_panel, function(v) round(sd(panel[[v]], na.rm = TRUE), 3)),
  Min = sapply(vars_panel, function(v) round(min(panel[[v]], na.rm = TRUE), 3)),
  Max = sapply(vars_panel, function(v) round(max(panel[[v]], na.rm = TRUE), 3))
)
rownames(stats_df) <- NULL

# LaTeX output
tab1 <- xtable(stats_df,
               caption = "Summary Statistics: State-Year Panel (2000--2024)",
               label = "tab:summary")

print(tab1, file = file.path(tables_dir, "tab1_summary.tex"),
      include.rownames = FALSE,
      booktabs = TRUE,
      caption.placement = "top",
      sanitize.text.function = identity,
      floating = TRUE,
      table.placement = "htbp",
      add.to.row = list(
        pos = list(nrow(stats_df)),
        command = paste0(
          "\\bottomrule\n",
          "\\multicolumn{6}{l}{\\footnotesize \\textit{Notes:} ",
          "Panel of 48 CONUS states $\\times$ 25 years (2000--2024). ",
          "Pre-1970 Dam Share is the fraction of a state's dams completed before 1970. ",
          "Design Gap Index = Pre-1970 Share $\\times$ Precipitation Ratio. ",
          "Flood declarations from FEMA; NFIP claims from OpenFEMA (50K sample). ",
          "Precipitation ratio from NOAA nClimDiv (design era 1950--1969 vs.~modern 2000--2019).}\n"
        )
      ))

cat("  Saved tab1_summary.tex\n")

## -----------------------------------------------------------
## Table 2: Main Results
## -----------------------------------------------------------
cat("=== Table 2: Main Results ===\n")

# Use modelsummary for clean regression table
tab2_models <- list(
  "(1)" = main_res$m1_share,
  "(2)" = main_res$m2_count,
  "(3)" = main_res$m3_high_hazard,
  "(4)" = main_res$m4_design_gap,
  "(5)" = main_res$m5_poisson
)

cm <- c(
  "pre1970_share"      = "Pre-1970 Share",
  "log_pre1970"        = "Log(Pre-1970 Count + 1)",
  "pre1970_high_share" = "High-Hazard Pre-1970 Share",
  "design_gap"         = "Design Gap Index",
  "precip_ratio"       = "Precip. Ratio",
  "log_n_dams"         = "Log(Total Dams + 1)",
  "log_storage"        = "Log(Storage + 1)"
)

gm <- list(
  list("raw" = "nobs",     "clean" = "Observations",  "fmt" = 0),
  list("raw" = "r.squared","clean" = "Within $R^2$",  "fmt" = 3),
  list("raw" = "FE: year", "clean" = "Year FE",       "fmt" = 0)
)

options("modelsummary_format_numeric_latex" = "plain")

modelsummary(tab2_models,
  output = file.path(tables_dir, "tab2_main.tex"),
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Dam Vintage and Flood Outcomes: Main Results",
  notes = list(
    "Standard errors clustered at the state level in parentheses.",
    "Columns (1)--(4): OLS with year fixed effects. Column (5): Poisson with year fixed effects.",
    "Pre-1970 Share = fraction of state's dams completed before 1970.",
    "Design Gap Index = Pre-1970 Share $\\times$ Precipitation Ratio.",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)

cat("  Saved tab2_main.tex\n")

## -----------------------------------------------------------
## Table 3: Robustness and Placebos
## -----------------------------------------------------------
cat("=== Table 3: Robustness ===\n")

tab3_models <- list(
  "(1) Post-1990" = rob_res$placebo_post1990,
  "(2) Non-Flood" = rob_res$placebo_nonflood,
  "(3) Controls"  = rob_res$controls,
  "(4) Precip."   = rob_res$precip_interaction
)

cm3 <- c(
  "post1990_share"                   = "Post-1990 Share",
  "pre1970_share"                    = "Pre-1970 Share",
  "precip_increased"                 = "Precip. Increased (=1)",
  "pre1970_share:precip_increased"   = "Pre-1970 $\\times$ Precip. Incr.",
  "log_n_dams"                       = "Log(Total Dams + 1)",
  "log_storage"                      = "Log(Storage + 1)"
)

modelsummary(tab3_models,
  output = file.path(tables_dir, "tab3_robustness.tex"),
  coef_map = cm3,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Robustness Checks and Placebo Tests",
  notes = list(
    "Standard errors clustered at the state level in parentheses.",
    "All specifications include year fixed effects.",
    "Column (1): Placebo using post-1990 dam share (expected: no effect).",
    "Column (2): Placebo using non-flood disasters as outcome (expected: no effect).",
    "Column (3): Additional storage control.",
    "Column (4): Precipitation interaction.",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)

cat("  Saved tab3_robustness.tex\n")

## -----------------------------------------------------------
## Table 4: Age Gradient Decomposition
## -----------------------------------------------------------
cat("=== Table 4: Age Gradient ===\n")

tab4_models <- list("(1) LPM" = main_res$m_gradient)

cm4 <- c(
  "share_1920s" = "1920s Share",
  "share_1930s" = "1930s Share",
  "share_1940s" = "1940s Share",
  "share_1950s" = "1950s Share",
  "share_1960s" = "1960s Share",
  "share_1970s" = "1970s Share",
  "share_1980s" = "1980s Share",
  "share_1990s" = "1990s Share",
  "log_n_dams"  = "Log(Total Dams + 1)"
)

modelsummary(tab4_models,
  output = file.path(tables_dir, "tab4_gradient.tex"),
  coef_map = cm4,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Age Gradient Decomposition: Flood Probability by Dam Construction Decade",
  notes = list(
    "Standard errors clustered at the state level in parentheses.",
    "Dependent variable: flood declaration indicator (=1 if any flood declaration in state-year).",
    "Each coefficient is the share of dams built in that decade (omitted: pre-1920 and 2000+).",
    "Year fixed effects included.",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)

cat("  Saved tab4_gradient.tex\n")

## -----------------------------------------------------------
## Table F1: Standardized Effect Sizes (SDE Appendix)
## -----------------------------------------------------------
cat("=== Table F1: SDE ===\n")

# Extract key coefficients for SDE computation
# Main outcome: flood declaration probability (Panel A: pooled)
# SD(Y) = SD of flood_declared in pre-period (2000-2003)
sd_y_flood <- sd(panel[year < 2004]$flood_declared)
sd_x_share <- sd(panel$pre1970_share)

# M1: pre1970_share (continuous treatment)
beta_m1 <- coef(main_res$m1_share)["pre1970_share"]
se_m1 <- se(main_res$m1_share)["pre1970_share"]
sde_m1 <- beta_m1 * sd_x_share / sd_y_flood
se_sde_m1 <- se_m1 * sd_x_share / sd_y_flood

# M4: design_gap (continuous)
sd_x_gap <- sd(panel[!is.na(design_gap)]$design_gap)
beta_m4 <- coef(main_res$m4_design_gap)["design_gap"]
se_m4 <- se(main_res$m4_design_gap)["design_gap"]
sde_m4 <- beta_m4 * sd_x_gap / sd_y_flood
se_sde_m4 <- se_m4 * sd_x_gap / sd_y_flood

# M5 Poisson: marginal effect (approximate)
beta_m5 <- coef(main_res$m5_poisson)["pre1970_share"]
se_m5 <- se(main_res$m5_poisson)["pre1970_share"]
sd_y_count <- sd(panel$n_flood_decl)
sde_m5 <- beta_m5 * sd_x_share / sd_y_count  # Approx SDE for count
se_sde_m5 <- se_m5 * sd_x_share / sd_y_count

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde < 0) return("Small negative") else return("Small positive")
  }
  if (abs_sde < 0.15) {
    if (sde < 0) return("Moderate negative") else return("Moderate positive")
  }
  if (sde < 0) return("Large negative") else return("Large positive")
}

# Panel A: Pooled effects
sde_table_a <- data.frame(
  Outcome = c("Flood Declaration (LPM)", "Flood Declaration (Design Gap)",
              "Flood Declaration Count (Poisson)"),
  Beta = round(c(beta_m1, beta_m4, beta_m5), 4),
  SE = round(c(se_m1, se_m4, se_m5), 4),
  SD_Y = round(c(sd_y_flood, sd_y_flood, sd_y_count), 3),
  SDE = round(c(sde_m1, sde_m4, sde_m5), 4),
  SE_SDE = round(c(se_sde_m1, se_sde_m4, se_sde_m5), 4),
  Classification = c(classify_sde(sde_m1), classify_sde(sde_m4), classify_sde(sde_m5))
)

# Panel B: Heterogeneous effects (by precipitation change)
# Split: states where precip increased vs decreased
panel_incr <- panel[!is.na(precip_ratio) & precip_ratio > 1]
panel_decr <- panel[!is.na(precip_ratio) & precip_ratio <= 1]

m_incr <- feols(flood_declared ~ pre1970_share + log_n_dams | year,
                data = panel_incr, cluster = ~state_abbr)
m_decr <- feols(flood_declared ~ pre1970_share + log_n_dams | year,
                data = panel_decr, cluster = ~state_abbr)

sd_y_incr <- sd(panel_incr$flood_declared)
sd_y_decr <- sd(panel_decr$flood_declared)

sde_incr <- coef(m_incr)["pre1970_share"] * sd_x_share / sd_y_incr
se_sde_incr <- se(m_incr)["pre1970_share"] * sd_x_share / sd_y_incr
sde_decr <- coef(m_decr)["pre1970_share"] * sd_x_share / sd_y_decr
se_sde_decr <- se(m_decr)["pre1970_share"] * sd_x_share / sd_y_decr

sde_table_b <- data.frame(
  Outcome = c("Flood Decl. (Precip. Increased)", "Flood Decl. (Precip. Decreased)"),
  Beta = round(c(coef(m_incr)["pre1970_share"], coef(m_decr)["pre1970_share"]), 4),
  SE = round(c(se(m_incr)["pre1970_share"], se(m_decr)["pre1970_share"]), 4),
  SD_Y = round(c(sd_y_incr, sd_y_decr), 3),
  SDE = round(c(sde_incr, sde_decr), 4),
  SE_SDE = round(c(se_sde_incr, se_sde_decr), 4),
  Classification = c(classify_sde(sde_incr), classify_sde(sde_decr))
)

# Combine and output
sde_full <- rbind(sde_table_a, sde_table_b)

sde_tab <- xtable(sde_full,
                   caption = "Standardized Effect Sizes: Dam Vintage and Flood Outcomes",
                   label = "tab:sde")

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the share of dams built before 1970---designed with outdated ",
  "precipitation estimates---predict higher flood damage in a state? ",
  "\\textbf{Policy mechanism:} Dam spillways are physical constants set at construction using ",
  "the hydrological standards of that era (TP-40, 1961); as climate shifts increase precipitation, ",
  "older dams face design gaps between their engineered capacity and current flood magnitudes. ",
  "\\textbf{Outcome definition:} FEMA flood disaster declaration indicator (=1 if any flood ",
  "declaration in a state-year) and count of flood declarations. ",
  "\\textbf{Treatment:} Continuous---share of state's dams completed before 1970 (0.30--0.96). ",
  "\\textbf{Data:} National Inventory of Dams (73,293 dams), FEMA Disaster Declarations ",
  "(11,234 flood records), NOAA nClimDiv precipitation, 2000--2024, state-year panel (1,200 obs). ",
  "\\textbf{Method:} OLS and Poisson with year FE, SEs clustered at state level (48 clusters). ",
  "\\textbf{Sample:} 48 CONUS states, excluding Alaska and Hawaii. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, ",
  "where SD($Y$) is computed over the full sample. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes: Dam Vintage and Flood Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (i in 1:nrow(sde_table_a)) {
  cat(paste(sde_table_a[i, ], collapse = " & "), "\\\\\n")
}
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by precipitation change)}} \\\\\n")
for (i in 1:nrow(sde_table_b)) {
  cat(paste(sde_table_b[i, ], collapse = " & "), "\\\\\n")
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("  Saved tabF1_sde.tex\n")
cat("\nAll tables generated.\n")
