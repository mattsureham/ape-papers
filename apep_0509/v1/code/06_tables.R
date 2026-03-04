# ==============================================================================
# APEP-0509: MGNREGA, Input Substitution, and Crop-Specific Productivity
# 06_tables.R — All table generation
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))
crop_long <- readRDS(file.path(data_dir, "crop_panel.rds"))
agg_panel <- readRDS(file.path(data_dir, "agg_panel.rds"))
wage_panel <- readRDS(file.path(data_dir, "wage_panel.rds"))
fert_panel <- readRDS(file.path(data_dir, "fert_panel.rds"))
baseline <- readRDS(file.path(data_dir, "baseline.rds"))

# ==============================================================================
# Table 1: Summary Statistics by MGNREGA Phase
# ==============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Baseline characteristics by phase
phase_stats <- baseline[, .(
  n_districts = .N,
  backwardness = mean(backwardness_index, na.rm = TRUE),
  sc_st_share = mean(sc_st_share, na.rm = TRUE),
  ag_labor_share = mean(ag_labor_share, na.rm = TRUE),
  literacy = mean(lit_rate, na.rm = TRUE),
  latitude = mean(lat, na.rm = TRUE)
), by = mgnrega_phase]

# Pre-treatment yield means by phase (2000-2005)
pre_yields <- crop_long[year <= 2005 & crop %in% c("RICE", "WHEAT", "COTTON", "SUGARCANE"),
                         .(mean_yield = mean(yield, na.rm = TRUE)),
                         by = .(mgnrega_phase, crop)]
pre_wide <- dcast(pre_yields, mgnrega_phase ~ crop, value.var = "mean_yield")

# Merge
tab1_data <- merge(phase_stats, pre_wide, by = "mgnrega_phase", all.x = TRUE)

# Only use phases present in the data (ICRISAT covers Phase I and II only)
n_phases <- nrow(phase_stats)

all_stats <- baseline[, .(
  n_districts = .N,
  backwardness = mean(backwardness_index, na.rm = TRUE),
  sc_st_share = mean(sc_st_share, na.rm = TRUE),
  ag_labor_share = mean(ag_labor_share, na.rm = TRUE),
  literacy = mean(lit_rate, na.rm = TRUE)
)]

# Pre-treatment yields for all
all_pre <- crop_long[year <= 2005 & crop %in% c("RICE", "WHEAT", "COTTON", "SUGARCANE"),
                      .(mean_yield = mean(yield, na.rm = TRUE)), by = crop]

# LaTeX output — only Phase I, Phase II, All (no Phase III in ICRISAT)
tab1_latex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by MGNREGA Phase}\n",
  "\\label{tab:summary}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Phase I & Phase II & All \\\\\n",
  " & (2006) & (2007) & \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: District Characteristics}} \\\\\n",
  sprintf("Number of districts & %d & %d & %d \\\\\n",
          phase_stats$n_districts[1], phase_stats$n_districts[2], all_stats$n_districts),
  sprintf("Backwardness index & %.3f & %.3f & %.3f \\\\\n",
          phase_stats$backwardness[1], phase_stats$backwardness[2], all_stats$backwardness),
  sprintf("SC/ST population share & %.3f & %.3f & %.3f \\\\\n",
          phase_stats$sc_st_share[1], phase_stats$sc_st_share[2], all_stats$sc_st_share),
  sprintf("Agricultural labor share & %.3f & %.3f & %.3f \\\\\n",
          phase_stats$ag_labor_share[1], phase_stats$ag_labor_share[2], all_stats$ag_labor_share),
  sprintf("Literacy rate & %.3f & %.3f & %.3f \\\\\n",
          phase_stats$literacy[1], phase_stats$literacy[2], all_stats$literacy),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Pre-Treatment Crop Yields (kg/ha, 2000--2005 avg)}} \\\\\n"
)

for (cn in c("RICE", "WHEAT", "COTTON", "SUGARCANE")) {
  vals <- sapply(1:2, function(p) {
    v <- pre_wide[mgnrega_phase == p, get(cn)]
    if (length(v) == 0 || is.na(v)) "---" else sprintf("%.0f", v)
  })
  all_v <- all_pre[crop == cn, mean_yield]
  all_str <- if (length(all_v) == 0 || is.na(all_v)) "---" else sprintf("%.0f", all_v)
  tab1_latex <- paste0(tab1_latex,
    sprintf("%s & %s & %s & %s \\\\\n", cn, vals[1], vals[2], all_str))
}

tab1_latex <- paste0(tab1_latex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\n\\par \\raggedright \\footnotesize\n",
  "\\textit{Notes:} The ICRISAT District Level Database covers 311 districts across Phase I (most backward, MGNREGA from February 2006) and Phase II (April 2007). Phase III districts are not included in this database. Backwardness index is constructed from Census 2001 data as SC/ST share + agricultural labor share $-$ literacy rate. Pre-treatment yields are district-level averages for 2000--2005.\n",
  "\\end{table}\n"
)

writeLines(tab1_latex, file.path(tab_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ==============================================================================
# Table 2: First Stage — MGNREGA → Agricultural Wages
# ==============================================================================
cat("=== Table 2: First Stage ===\n")

etable(results$wage_static, results$wage_es,
       file = file.path(tab_dir, "tab2_first_stage.tex"),
       title = "First Stage: MGNREGA and Agricultural Wages",
       label = "tab:first_stage",
       headers = c("Static DiD", "Sun \\& Abraham"),
       notes = "Dependent variable: Log male agricultural daily wage. Unit of observation: district-year. Sun \\& Abraham (2021) interaction-weighted estimator used in Column 2. Standard errors clustered at the state level in parentheses.",
       style.tex = style.tex("aer"),
       replace = TRUE)
cat("  Saved tab2_first_stage.tex\n")

# ==============================================================================
# Table 3: Main Results — Crop-Specific Yield Effects (Static DiD)
# ==============================================================================
cat("=== Table 3: Main Results ===\n")

# Collect static DiD results for key crops
main_crop_list <- list()
crop_order <- c("RICE", "WHEAT", "COTTON", "SUGARCANE", "MAIZE", "SORGHUM", "CHICKPEA", "GROUNDNUT")
for (cn in crop_order) {
  if (!is.null(results$crop_static[[cn]])) {
    main_crop_list[[cn]] <- results$crop_static[[cn]]
  }
}

etable(main_crop_list,
       file = file.path(tab_dir, "tab3_main_results.tex"),
       title = "MGNREGA and Crop-Specific Yields",
       label = "tab:main_results",
       headers = names(main_crop_list),
       notes = "Dependent variable: Log crop yield (kg/ha). Each column is a separate regression for the indicated crop. All specifications include district and year fixed effects. Post equals one for district-years after MGNREGA implementation. Standard errors clustered at the state level in parentheses.",
       style.tex = style.tex("aer"),
       replace = TRUE)
cat("  Saved tab3_main_results.tex\n")

# ==============================================================================
# Table 4: Mechanism — Fertilizer Intensification
# ==============================================================================
cat("=== Table 4: Mechanism ===\n")

mech_list <- list(
  "Total Fertilizer" = results$fert_static,
  "Nitrogen" = results$fert_n,
  "Phosphate" = results$fert_p
)
# Remove NULLs
mech_list <- mech_list[!sapply(mech_list, is.null)]

if (length(mech_list) > 0) {
  etable(mech_list,
         file = file.path(tab_dir, "tab4_mechanism.tex"),
         title = "Mechanism: Fertilizer Intensification",
         label = "tab:mechanism",
         headers = names(mech_list),
         notes = "Dependent variable: Log fertilizer consumption per hectare. Column 1 uses total fertilizer (N+P+K), Columns 2--3 use individual components. All specifications include district and year fixed effects with Sun \\& Abraham (2021) estimator. Standard errors clustered at the state level in parentheses.",
         style.tex = style.tex("aer"),
         replace = TRUE)
  cat("  Saved tab4_mechanism.tex\n")
}

# ==============================================================================
# Table 5: Robustness — Alternative Specifications
# ==============================================================================
cat("=== Table 5: Robustness ===\n")

# Build robustness comparison for Rice
rice_rob_list <- list()

if (!is.null(results$crop_static[["RICE"]])) {
  rice_rob_list[["Baseline"]] <- results$crop_static[["RICE"]]
}
if (!is.null(rob_results$state_x_year[["RICE"]])) {
  rice_rob_list[["State $\\times$ Year FE"]] <- rob_results$state_x_year[["RICE"]]
}
if (!is.null(rob_results$no_border[["RICE"]])) {
  rice_rob_list[["Excl. Border"]] <- rob_results$no_border[["RICE"]]
}
if (!is.null(rob_results$balanced_static[["RICE"]])) {
  rice_rob_list[["Balanced Panel"]] <- rob_results$balanced_static[["RICE"]]
} else if (!is.null(rob_results$balanced[["RICE"]])) {
  rice_rob_list[["Balanced Panel"]] <- rob_results$balanced[["RICE"]]
}
if (!is.null(rob_results$dist_cluster[["RICE"]])) {
  rice_rob_list[["District Cluster"]] <- rob_results$dist_cluster[["RICE"]]
}

if (length(rice_rob_list) > 1) {
  etable(rice_rob_list,
         file = file.path(tab_dir, "tab5_robustness_rice.tex"),
         title = "Robustness: Alternative Specifications for Rice Yield",
         label = "tab:robustness_rice",
         headers = names(rice_rob_list),
         notes = "Dependent variable: Log rice yield (kg/ha). Column 1 is the baseline specification. Column 2 adds state $\\times$ year fixed effects. Column 3 excludes districts within 100km of Phase I districts. Column 4 restricts to districts with complete 2000--2017 data. Column 5 clusters standard errors at the district level. All columns use static DiD.",
         style.tex = style.tex("aer"),
         replace = TRUE)
  cat("  Saved tab5_robustness_rice.tex\n")
}

# ==============================================================================
# Table 6: Pre-Trend Tests
# ==============================================================================
cat("=== Table 6: Pre-Trend Tests ===\n")

if (length(rob_results$pretrend_tests) > 0) {
  pt_rows <- rbindlist(lapply(names(rob_results$pretrend_tests), function(cn) {
    x <- rob_results$pretrend_tests[[cn]]
    data.table(Crop = cn, `F-statistic` = round(x$f_stat, 2),
               `p-value` = round(x$p_value, 4),
               `Pre-periods` = x$n_pre_coefs,
               Pass = ifelse(x$p_value > 0.10, "Yes", "No"))
  }))

  pt_latex <- kable(pt_rows, format = "latex", booktabs = TRUE,
                    caption = "Joint Pre-Trend Tests by Crop",
                    label = "pretrend",
                    align = c("l", "c", "c", "c", "c")) %>%
    kable_styling(latex_options = "hold_position") %>%
    footnote(general = "Joint Wald test of pre-treatment event-study coefficients (excluding t = -1 reference). Pass indicates failure to reject the null of zero pre-treatment effects at the 10\\\\% level.",
             general_title = "Notes:", footnote_as_chunk = TRUE, escape = FALSE)

  writeLines(pt_latex, file.path(tab_dir, "tab6_pretrend.tex"))
  cat("  Saved tab6_pretrend.tex\n")
}

# ==============================================================================
# Table A1: Crop Labor Intensity Classification (Appendix)
# ==============================================================================
cat("=== Table A1: Crop Classification ===\n")

crop_class <- data.table(
  Crop = c("Rice", "Cotton", "Sugarcane", "Groundnut", "Sesamum",
           "Wheat", "Maize", "Sorghum", "Chickpea", "Mustard/Rapeseed"),
  Classification = c(rep("Labor-Intensive", 5), rep("Non-Labor-Intensive", 5)),
  Rationale = c(
    "Transplanting, weeding, harvesting require intensive manual labor",
    "Hand-picking of bolls, weeding throughout growing season",
    "Planting, harvesting, loading require large labor gangs",
    "Pegging, weeding, harvesting are labor-intensive operations",
    "Requires careful hand-weeding and harvesting",
    "Relatively mechanizable (sowing, harvesting)",
    "Can be mechanically sown and harvested",
    "Low labor input per hectare, drought-resistant",
    "Minimal inter-culture operations required",
    "Mechanizable sowing and harvesting"
  )
)

classA1 <- kable(crop_class, format = "latex", booktabs = TRUE,
                  caption = "Crop Labor Intensity Classification",
                  label = "crop_class",
                  align = c("l", "l", "p{8cm}")) %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = "Classification based on agronomic literature on labor requirements per hectare in Indian agriculture. See Gulati and Saini (2015) and Sharma and Bhaduri (2009).",
           general_title = "Notes:", footnote_as_chunk = TRUE)

writeLines(classA1, file.path(tab_dir, "tabA1_crop_classification.tex"))
cat("  Saved tabA1_crop_classification.tex\n")

cat("\nAll tables saved.\n")
