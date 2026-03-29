## 05_tables.R — Generate all LaTeX tables for apep_1114
## Tables: summary stats, main results, adverse selection, robustness, SDE

source("00_packages.R")

cat("=== Generating Tables ===\n\n")

panel <- readRDS("../data/analysis_panel.rds") |>
  filter(!is.na(high_exposure))
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("Table 1: Summary Statistics\n")

sum_2018 <- panel |>
  filter(year == 2018) |>
  group_by(high_exposure) |>
  summarise(
    n = n(),
    farms_mean = mean(n_farms, na.rm = TRUE),
    farms_sd = sd(n_farms, na.rm = TRUE),
    cattle_mean = mean(cattle, na.rm = TRUE),
    cattle_sd = sd(cattle, na.rm = TRUE),
    pigs_mean = mean(pigs, na.rm = TRUE),
    pigs_sd = sd(pigs, na.rm = TRUE),
    chickens_mean = mean(chickens, na.rm = TRUE),
    chickens_sd = sd(chickens, na.rm = TRUE),
    lu_mean = mean(livestock_units, na.rm = TRUE),
    lu_sd = sd(livestock_units, na.rm = TRUE),
    lu_per_farm_mean = mean(livestock_per_farm, na.rm = TRUE),
    lu_per_farm_sd = sd(livestock_per_farm, na.rm = TRUE),
    n2k_mean = mean(n2k_share, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(!is.na(high_exposure))

# Format table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Treatment Exposure (2018)}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{High Exposure} & \\multicolumn{2}{c}{Low Exposure} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

# Helper function
fmt <- function(x, d = 1) formatC(x, format = "f", digits = d, big.mark = ",")

high <- sum_2018 |> filter(high_exposure == TRUE)
low <- sum_2018 |> filter(high_exposure == FALSE)

tab1_lines <- c(tab1_lines,
  paste0("Number of municipalities & \\multicolumn{2}{c}{", high$n, "} & \\multicolumn{2}{c}{", low$n, "} \\\\"),
  "\\addlinespace",
  paste0("Agricultural holdings & ", fmt(high$farms_mean), " & (", fmt(high$farms_sd), ") & ",
         fmt(low$farms_mean), " & (", fmt(low$farms_sd), ") \\\\"),
  paste0("Cattle (head) & ", fmt(high$cattle_mean, 0), " & (", fmt(high$cattle_sd, 0), ") & ",
         fmt(low$cattle_mean, 0), " & (", fmt(low$cattle_sd, 0), ") \\\\"),
  paste0("Pigs (head) & ", fmt(high$pigs_mean, 0), " & (", fmt(high$pigs_sd, 0), ") & ",
         fmt(low$pigs_mean, 0), " & (", fmt(low$pigs_sd, 0), ") \\\\"),
  paste0("Chickens (head) & ", fmt(high$chickens_mean, 0), " & (", fmt(high$chickens_sd, 0), ") & ",
         fmt(low$chickens_mean, 0), " & (", fmt(low$chickens_sd, 0), ") \\\\"),
  paste0("Livestock units (LU) & ", fmt(high$lu_mean, 0), " & (", fmt(high$lu_sd, 0), ") & ",
         fmt(low$lu_mean, 0), " & (", fmt(low$lu_sd, 0), ") \\\\"),
  paste0("LU per farm & ", fmt(high$lu_per_farm_mean), " & (", fmt(high$lu_per_farm_sd), ") & ",
         fmt(low$lu_per_farm_mean), " & (", fmt(low$lu_per_farm_sd), ") \\\\"),
  "\\addlinespace",
  paste0("Natura 2000 exposure share & ", fmt(high$n2k_mean, 3),
         " & & ", fmt(low$n2k_mean, 3), " & \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Treatment exposure defined as above-median interaction of Natura 2000 5km buffer share and pre-2019 livestock density. Livestock units use EU coefficients: cattle = 1.0, pig = 0.3, chicken = 0.014. Standard deviations in parentheses. Data: CBS 80781ned, author's calculations.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Written: tables/tab1_summary.tex\n")

# ---------------------------------------------------------------
# Table 2: Main DiD Results (detrended — preferred specification)
# ---------------------------------------------------------------
cat("\nTable 2: Main DiD Results\n")

# Re-run detrended specs for the table (these are in robustness but
# we need the full model objects)
panel_trend <- panel |> mutate(trend = year - 2000)

# Preferred: detrended
m_dt_farms <- feols(
  log_farms ~ exposure:post_2019 + exposure:post_2023 |
    muni_code[trend] + year,
  data = panel_trend |> filter(!is.na(log_farms)),
  cluster = ~muni_code
)

m_dt_lu <- feols(
  log_livestock ~ exposure:post_2019 + exposure:post_2023 |
    muni_code[trend] + year,
  data = panel_trend |> filter(!is.na(log_livestock)),
  cluster = ~muni_code
)

m_dt_intensive <- feols(
  livestock_per_farm ~ exposure:post_2019 + exposure:post_2023 |
    muni_code[trend] + year,
  data = panel_trend |> filter(!is.na(livestock_per_farm)),
  cluster = ~muni_code
)

# Also run baseline (no trends) for comparison
m_base_farms <- results$m1_farms
m_base_lu <- results$m1_lu

# Combine models
tab2_etable <- etable(
  m_dt_farms, m_dt_lu, m_dt_intensive,
  m_base_farms, m_base_lu,
  headers = c("Log Farms", "Log LU", "LU/Farm",
              "Log Farms", "Log LU"),
  se.below = TRUE,
  dict = c(
    "exposure:post_2019" = "Exposure $\\times$ Post-2019",
    "exposure:post_2023" = "Exposure $\\times$ Post-2023"
  ),
  tex = TRUE,
  file = "../tables/tab2_main_results.tex",
  title = "Effect of Nitrogen Policy and Buyout on Farm Counts and Livestock",
  label = "tab:main",
  notes = paste0(
    "\\\\textit{Notes:} Columns 1--3 include municipality-specific linear time trends (preferred). ",
    "Columns 4--5 show baseline specification without trends. Exposure is the interaction of ",
    "Natura 2000 5km buffer share and pre-2019 livestock density (in thousands of LU). ",
    "Post-2019 captures the nitrogen ruling; Post-2023 captures the buyout program. ",
    "All specifications include municipality and year fixed effects. ",
    "Standard errors clustered by municipality in parentheses. ",
    "\\\\sym{*} \\\\(p<0.10\\\\), \\\\sym{**} \\\\(p<0.05\\\\), \\\\sym{***} \\\\(p<0.01\\\\)."
  ),
  fitstat = ~ n + wr2
)

cat("  Written: tables/tab2_main_results.tex\n")

# ---------------------------------------------------------------
# Table 3: Adverse Selection Test
# ---------------------------------------------------------------
cat("\nTable 3: Adverse Selection Test\n")

# Compute the adverse selection ratio for detrended spec
beta_farms_2023 <- coef(m_dt_farms)["exposure:post_2023"]
beta_lu_2023 <- coef(m_dt_lu)["exposure:post_2023"]
se_farms_2023 <- se(m_dt_farms)["exposure:post_2023"]
se_lu_2023 <- se(m_dt_lu)["exposure:post_2023"]

# Ratio
ratio_dt <- beta_lu_2023 / beta_farms_2023
# Delta method SE for ratio
ratio_se <- abs(ratio_dt) * sqrt(
  (se_lu_2023/beta_lu_2023)^2 + (se_farms_2023/beta_farms_2023)^2
)

# Baseline spec ratio
beta_farms_base <- coef(m_base_farms)["exposure:post_2023"]
beta_lu_base <- coef(m_base_lu)["exposure:post_2023"]
ratio_base <- beta_lu_base / beta_farms_base

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Adverse Selection Test: Elasticity Ratio of Livestock to Farms}",
  "\\label{tab:selection}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Detrended & Baseline \\\\",
  "\\midrule",
  paste0("$\\hat{\\beta}_{\\text{farms}}$ (Post-2023) & ",
         formatC(beta_farms_2023, format = "f", digits = 4), " & ",
         formatC(beta_farms_base, format = "f", digits = 4), " \\\\"),
  paste0(" & (", formatC(se_farms_2023, format = "f", digits = 4), ") & ",
         "(", formatC(se(m_base_farms)["exposure:post_2023"], format = "f", digits = 4), ") \\\\"),
  "\\addlinespace",
  paste0("$\\hat{\\beta}_{\\text{livestock}}$ (Post-2023) & ",
         formatC(beta_lu_2023, format = "f", digits = 4), " & ",
         formatC(beta_lu_base, format = "f", digits = 4), " \\\\"),
  paste0(" & (", formatC(se_lu_2023, format = "f", digits = 4), ") & ",
         "(", formatC(se(m_base_lu)["exposure:post_2023"], format = "f", digits = 4), ") \\\\"),
  "\\addlinespace",
  paste0("Elasticity ratio ($\\hat{\\beta}_{\\text{LU}} / \\hat{\\beta}_{\\text{farms}}$) & ",
         formatC(ratio_dt, format = "f", digits = 2), " & ",
         formatC(ratio_base, format = "f", digits = 2), " \\\\"),
  "\\midrule",
  "Municipality trends & Yes & No \\\\",
  paste0("Municipalities & ", n_distinct(panel$muni_code), " & ", n_distinct(panel$muni_code), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  paste0("\\item \\textit{Notes:} The elasticity ratio measures how livestock units respond relative to farm counts. ",
         "Under proportional exit, ratio $= 1$; under adverse selection (low-intensity farms exit first), ratio $< 1$; ",
         "under positive selection (high-intensity farms exit), ratio $> 1$. ",
         "The detrended specification (preferred) shows a ratio of ",
         formatC(ratio_dt, format = "f", digits = 2),
         ", suggesting roughly proportional exit. ",
         "The baseline ratio of ",
         formatC(ratio_base, format = "f", digits = 2),
         " reflects pre-existing structural trends, not program-induced selection. ",
         "Standard errors clustered by municipality."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_selection.tex")
cat("  Written: tables/tab3_selection.tex\n")

# ---------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------
cat("\nTable 4: Robustness\n")

# Gather robustness results
m_loo <- robust$loo_farms
m_alt <- robust$alt_exposure_farms
m_placebo <- robust$placebo_farms

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Preferred & Leave-3-out & N2K share only & Placebo (2012) & RI $p$-value \\\\",
  "\\midrule",
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Dependent variable: Log farm count}} \\\\",
  "\\addlinespace",
  paste0("Exposure $\\times$ Post-2019 & ",
         formatC(coef(m_dt_farms)[1], format = "f", digits = 4), " & ",
         formatC(coef(m_loo)[1], format = "f", digits = 4), " & ",
         formatC(coef(m_alt)[1], format = "f", digits = 4), " & ",
         formatC(coef(m_placebo)[1], format = "f", digits = 4), " & ",
         formatC(robust$ri_p_2019, format = "f", digits = 3), " \\\\"),
  paste0(" & (", formatC(se(m_dt_farms)[1], format = "f", digits = 4), ") & ",
         "(", formatC(se(m_loo)[1], format = "f", digits = 4), ") & ",
         "(", formatC(se(m_alt)[1], format = "f", digits = 4), ") & ",
         "(", formatC(se(m_placebo)[1], format = "f", digits = 4), ") & \\\\"),
  "\\addlinespace",
  paste0("Exposure $\\times$ Post-2023 & ",
         formatC(coef(m_dt_farms)[2], format = "f", digits = 4), " & ",
         formatC(coef(m_loo)[2], format = "f", digits = 4), " & ",
         formatC(coef(m_alt)[2], format = "f", digits = 4), " & --- & ",
         formatC(robust$ri_p_2023, format = "f", digits = 3), " \\\\"),
  paste0(" & (", formatC(se(m_dt_farms)[2], format = "f", digits = 4), ") & ",
         "(", formatC(se(m_loo)[2], format = "f", digits = 4), ") & ",
         "(", formatC(se(m_alt)[2], format = "f", digits = 4), ") & & \\\\"),
  "\\addlinespace",
  "Municipality trends & Yes & Yes & Yes & No & No \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  paste0("\\item \\textit{Notes:} Preferred specification includes municipality-specific linear trends. ",
         "Leave-3-out drops the three highest-exposure municipalities (Ede, Venray, Barneveld). ",
         "N2K share only uses Natura 2000 buffer share without livestock intensity interaction. ",
         "Placebo uses pseudo-treatment in 2012 on pre-2019 data only. ",
         "RI $p$-values from 500 permutations of exposure across municipalities. ",
         "Standard errors clustered by municipality."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("  Written: tables/tab4_robustness.tex\n")

# ---------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE)
# ---------------------------------------------------------------
cat("\nTable F1: Standardized Effect Sizes\n")

# Compute SD(Y) from pre-treatment period
pre_data <- panel |> filter(year < 2019)

sd_log_farms <- sd(pre_data$log_farms, na.rm = TRUE)
sd_log_lu <- sd(pre_data$log_livestock, na.rm = TRUE)
sd_lu_per_farm <- sd(pre_data$livestock_per_farm, na.rm = TRUE)

# SDE = beta / SD(Y) for binary treatment (continuous exposure, so use β × SD(X) / SD(Y))
sd_exposure <- sd(panel$exposure[!is.na(panel$exposure)])

# Main coefficients from detrended spec
beta_farms <- coef(m_dt_farms)["exposure:post_2023"]
se_beta_farms <- se(m_dt_farms)["exposure:post_2023"]
sde_farms <- beta_farms * sd_exposure / sd_log_farms
se_sde_farms <- se_beta_farms * sd_exposure / sd_log_farms

beta_lu <- coef(m_dt_lu)["exposure:post_2023"]
se_beta_lu <- se(m_dt_lu)["exposure:post_2023"]
sde_lu <- beta_lu * sd_exposure / sd_log_lu
se_sde_lu <- se_beta_lu * sd_exposure / sd_log_lu

beta_int <- coef(m_dt_intensive)["exposure:post_2023"]
se_beta_int <- se(m_dt_intensive)["exposure:post_2023"]
sde_int <- beta_int * sd_exposure / sd_lu_per_farm
se_sde_int <- se_beta_int * sd_exposure / sd_lu_per_farm

classify_sde <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  return("Small positive")
}

# --- Panel A (Pooled) ---
rows_a <- list(
  list("Log farm count", beta_farms, se_beta_farms, sd_log_farms, sde_farms, se_sde_farms),
  list("Log livestock units", beta_lu, se_beta_lu, sd_log_lu, sde_lu, se_sde_lu),
  list("LU per farm", beta_int, se_beta_int, sd_lu_per_farm, sde_int, se_sde_int)
)

# --- Panel B (Heterogeneous: high vs low cattle intensity) ---
# Split by above/below median pre-period cattle share
panel_het <- panel |>
  mutate(
    cattle_share = ifelse(livestock_units > 0, cattle / livestock_units, NA_real_),
    trend = year - 2000
  )

med_cattle_share <- median(
  panel_het$cattle_share[panel_het$year >= 2015 & panel_het$year <= 2018],
  na.rm = TRUE
)

# Cattle-intensive municipalities
m_het_cattle <- feols(
  log_farms ~ exposure:post_2019 + exposure:post_2023 |
    muni_code[trend] + year,
  data = panel_het |>
    filter(!is.na(log_farms) & !is.na(cattle_share)) |>
    filter(cattle_share >= med_cattle_share),
  cluster = ~muni_code
)

# Non-cattle-intensive municipalities (pig/poultry dominant)
m_het_noncattle <- feols(
  log_farms ~ exposure:post_2019 + exposure:post_2023 |
    muni_code[trend] + year,
  data = panel_het |>
    filter(!is.na(log_farms) & !is.na(cattle_share)) |>
    filter(cattle_share < med_cattle_share),
  cluster = ~muni_code
)

sd_farms_cattle <- sd(
  pre_data$log_farms[pre_data$muni_code %in%
    unique(panel_het$muni_code[panel_het$cattle_share >= med_cattle_share])],
  na.rm = TRUE
)
sd_farms_noncattle <- sd(
  pre_data$log_farms[pre_data$muni_code %in%
    unique(panel_het$muni_code[panel_het$cattle_share < med_cattle_share])],
  na.rm = TRUE
)

beta_cattle <- coef(m_het_cattle)["exposure:post_2023"]
se_cattle <- se(m_het_cattle)["exposure:post_2023"]
sde_cattle <- beta_cattle * sd_exposure / sd_farms_cattle
se_sde_cattle <- se_cattle * sd_exposure / sd_farms_cattle

beta_nc <- coef(m_het_noncattle)["exposure:post_2023"]
se_nc <- se(m_het_noncattle)["exposure:post_2023"]
sde_nc <- beta_nc * sd_exposure / sd_farms_noncattle
se_sde_nc <- se_nc * sd_exposure / sd_farms_noncattle

# Format SDE table
fmt4 <- function(x) formatC(x, format = "f", digits = 4)
fmt3 <- function(x) formatC(x, format = "f", digits = 3)

n_obs_total <- nrow(panel |> filter(!is.na(log_farms)))

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Netherlands. ",
  "\\textbf{Research question:} Does the Dutch piekbelasters (peak emitter) livestock buyout program, ",
  "the world's largest environmental farm buyout at EUR 1.5 billion, ",
  "reduce farm counts and livestock in nitrogen-exposed municipalities? ",
  "\\textbf{Policy mechanism:} The Lbv-plus program offers 120\\% of assessed farm value ",
  "to livestock operations near Natura 2000 protected sites that exceed nitrogen emission thresholds, ",
  "conditional on permanent cessation of agricultural activity at that location. ",
  "\\textbf{Outcome definition:} Log number of agricultural holdings (farm count) and log livestock units ",
  "(EU-standardized: cattle = 1.0, pig = 0.3, chicken = 0.014) at the municipality-year level from CBS agricultural census. ",
  "\\textbf{Treatment:} Continuous; interaction of Natura 2000 5km buffer share and pre-2019 mean livestock ",
  "density in thousands of livestock units. ",
  "\\textbf{Data:} CBS 80781ned (agricultural census, 2000--2025), PDOK Natura 2000 boundaries; ",
  "328 municipalities, 26 years, ", formatC(n_obs_total, big.mark = ","), " municipality-year observations. ",
  "\\textbf{Method:} Continuous treatment DiD with municipality and year fixed effects plus municipality-specific ",
  "linear time trends; standard errors clustered by municipality; robustness via leave-three-out and 500-iteration ",
  "randomization inference. ",
  "\\textbf{Sample:} All Dutch municipalities with at least one agricultural holding in any year; ",
  "municipalities with missing Natura 2000 spatial data excluded. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional standard deviation of ",
  "treatment exposure and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabf1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace"
)

for (r in rows_a) {
  tabf1_lines <- c(tabf1_lines,
    paste0(r[[1]], " & ", fmt4(r[[2]]), " & ", fmt4(r[[3]]), " & ",
           fmt3(r[[4]]), " & ", fmt3(r[[5]]), " & ", fmt3(r[[6]]), " & ",
           classify_sde(r[[5]]), " \\\\")
  )
}

tabf1_lines <- c(tabf1_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (farm count, by livestock composition)}} \\\\",
  "\\addlinespace",
  paste0("Cattle-intensive munis & ", fmt4(beta_cattle), " & ", fmt4(se_cattle), " & ",
         fmt3(sd_farms_cattle), " & ", fmt3(sde_cattle), " & ", fmt3(se_sde_cattle), " & ",
         classify_sde(sde_cattle), " \\\\"),
  paste0("Pig/poultry-intensive munis & ", fmt4(beta_nc), " & ", fmt4(se_nc), " & ",
         fmt3(sd_farms_noncattle), " & ", fmt3(sde_nc), " & ", fmt3(se_sde_nc), " & ",
         classify_sde(sde_nc), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabf1_lines, "../tables/tabF1_sde.tex")
cat("  Written: tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
