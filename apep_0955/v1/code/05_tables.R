# 05_tables.R — Generate all LaTeX tables including SDE appendix
# apep_0955: AAA Cotton Acreage Reduction and Black Sharecropper Children

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
sibling_dt <- readRDS("../data/analysis_siblings.rds")

dir.create("../tables", showWarnings = FALSE)

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics\n")

vars_info <- list(
  list(var = "age_1930",          label = "Age in 1930"),
  list(var = "female",            label = "Female"),
  list(var = "educ_years_1940",   label = "Years of education (1940)"),
  list(var = "educ_years_1950",   label = "Years of education (1950)"),
  list(var = "occscore_1940",     label = "Occupational income score (1940)"),
  list(var = "occscore_1950",     label = "Occupational income score (1950)"),
  list(var = "incwage_1940_clean",label = "Wage income (1940)"),
  list(var = "incwage_1950_clean",label = "Wage income (1950)"),
  list(var = "migrated_by_1940",  label = "Migrated by 1940"),
  list(var = "off_farm_1940",     label = "Off-farm by 1940"),
  list(var = "aaa_intensity",     label = "AAA cotton intensity (county)")
)

tab1_rows <- lapply(vars_info, function(vi) {
  x <- sibling_dt[[vi$var]]
  sprintf("%-42s & %8.2f & %8.2f & %8.0f & %8.0f & %s \\\\",
    vi$label,
    mean(x, na.rm = TRUE),
    sd(x, na.rm = TRUE),
    min(x, na.rm = TRUE),
    max(x, na.rm = TRUE),
    format(sum(!is.na(x)), big.mark = ","))
})

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Black Farm Children in Cotton South (Sibling Sample)}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & Std.\\ Dev. & Min & Max & N \\\\\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Individual Characteristics}} \\\\\n",
  paste(tab1_rows[1:2], collapse = "\n"), "\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: Outcomes}} \\\\\n",
  paste(tab1_rows[3:10], collapse = "\n"), "\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel C: Treatment}} \\\\\n",
  paste(tab1_rows[11], collapse = "\n"), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} N = ", format(nrow(sibling_dt), big.mark = ","),
  " children in ", format(uniqueN(sibling_dt$serial_1930), big.mark = ","),
  " households with $\\geq$2 linked siblings. Sample: Black farm children aged 0--17 in 1930, ",
  "residing in seven cotton-belt states (AL, AR, GA, LA, MS, SC, TX), linked to 1940 and 1950 censuses ",
  "via the Multigenerational Longitudinal Panel (MLP). ",
  "AAA cotton intensity is the county-level share of Black farm population, proxying for exposure to ",
  "Agricultural Adjustment Act cotton acreage reduction contracts (1933--34).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ============================================================================
# TABLE 2: Main Results — Sibling FE
# ============================================================================
cat("Generating Table 2: Main Results\n")

etable(
  results$main$educ_years_1940,
  results$main$educ_years_1950,
  results$main$occ_1940,
  results$main$occ_1950,
  results$main$migration,
  results$main$off_farm,
  headers = c("Educ 1940", "Educ 1950", "OccScore 1940", "OccScore 1950",
              "Migrated 1940", "Off-Farm 1940"),
  dict = c(
    "aaa_intensity_z:school_age" = "AAA Intensity $\\times$ School Age",
    "age_1930" = "Age in 1930",
    "female" = "Female"
  ),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  fitstat = ~ n + r2,
  style.tex = style.tex("aer"),
  file = "../tables/tab2_main.tex",
  replace = TRUE,
  notes = paste0(
    "Standard errors clustered at the county level in parentheses. ",
    "All specifications include household (serial\\_1930) fixed effects. ",
    "School Age = 1 if child was aged 6--12 in 1933 (when AAA was implemented), 0 otherwise. ",
    "AAA Intensity is the standardized county-level Black farm population share. ",
    "Sample: Black farm children in seven cotton-belt states with $\\geq$2 linked siblings. ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)

# ============================================================================
# TABLE 3: Age Gradient — Three Cohort Interactions
# ============================================================================
cat("Generating Table 3: Age Gradient\n")

etable(
  results$age_gradient$educ50,
  results$age_gradient$occ50,
  results$age_gradient$mig40,
  results$age_gradient$farm40,
  headers = c("Educ 1950", "OccScore 1950", "Migrated 1940", "Off-Farm 1940"),
  dict = c(
    "aaa_intensity_z:cohort_school" = "AAA $\\times$ School Age (6--12)",
    "aaa_intensity_z:cohort_labor" = "AAA $\\times$ Labor Age (13--17)",
    "age_1930" = "Age in 1930",
    "female" = "Female"
  ),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  fitstat = ~ n + r2,
  style.tex = style.tex("aer"),
  file = "../tables/tab3_age_gradient.tex",
  replace = TRUE,
  notes = paste0(
    "Standard errors clustered at the county level in parentheses. ",
    "All specifications include household fixed effects. ",
    "Reference group: children aged 0--5 in 1933 (Young cohort). ",
    "School Age = aged 6--12 when AAA implemented (1933); Labor Age = aged 13--17. ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)

# ============================================================================
# TABLE 4: Racial Comparison (Black vs White)
# ============================================================================
cat("Generating Table 4: Racial Comparison\n")

etable(
  results$main$educ_years_1950,
  results$white_placebo$educ50,
  results$main$occ_1950,
  results$white_placebo$occ50,
  headers = c("Black Educ", "White Educ", "Black Occ", "White Occ"),
  dict = c(
    "aaa_intensity_z:school_age" = "AAA Intensity $\\times$ School Age",
    "age_1930" = "Age in 1930",
    "female" = "Female",
    "as.integer(sex_1930 == 2)" = "Female"
  ),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  fitstat = ~ n + r2,
  style.tex = style.tex("aer"),
  file = "../tables/tab4_racial_comparison.tex",
  replace = TRUE,
  notes = paste0(
    "Standard errors clustered at the county level in parentheses. ",
    "All specifications include household fixed effects. ",
    "Columns (1)--(2) compare Black and White children for education in 1950; ",
    "columns (3)--(4) for occupational income score in 1950. ",
    "If the AAA effect operates through the racial displacement mechanism, ",
    "Black children should show larger effects than White children in the same counties. ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)

# ============================================================================
# TABLE 5: Robustness — LOSO and Alternative Clustering
# ============================================================================
cat("Generating Table 5: Robustness\n")

# LOSO table
state_names <- c("1" = "Alabama", "5" = "Arkansas", "13" = "Georgia",
                 "22" = "Louisiana", "28" = "Mississippi",
                 "45" = "South Carolina", "48" = "Texas")

loso_rows <- lapply(1:nrow(robust$loso_educ), function(i) {
  r <- robust$loso_educ[i, ]
  state_nm <- state_names[as.character(r$dropped_state)]
  sprintf("%-20s & %8.4f & (%8.4f) & %s \\\\",
    state_nm, r$coef, r$se, format(r$n, big.mark = ","))
})

# Main result for comparison
main_coef <- coef(results$main$educ_years_1940)["aaa_intensity_z:school_age"]
main_se <- se(results$main$educ_years_1940)["aaa_intensity_z:school_age"]
state_se <- se(robust$state_cluster)["aaa_intensity_z:school_age"]

tab5_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness: Leave-One-State-Out and Alternative Clustering}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrr}\n",
  "\\toprule\n",
  "& Coefficient & Std.\\ Error & N \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Leave-one-state-out (Education 1940)}} \\\\\n",
  paste(loso_rows, collapse = "\n"), "\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Alternative clustering}} \\\\\n",
  sprintf("County-clustered (baseline) & %8.4f & (%8.4f) & %s \\\\",
    main_coef, main_se, format(nrow(sibling_dt), big.mark = ",")), "\n",
  sprintf("State-clustered            & %8.4f & (%8.4f) & %s \\\\",
    main_coef, state_se, format(nrow(sibling_dt), big.mark = ",")), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is years of education in 1950. ",
  "All specifications include household fixed effects with AAA Intensity $\\times$ School Age ",
  "as the coefficient of interest. Panel A drops one state at a time; ",
  "Panel B compares county-level (baseline) to state-level clustering. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab5_tex, "../tables/tab5_robustness.tex")

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================================
cat("Generating SDE Table\n")

# Extract coefficients and compute SDEs
sde_data <- list(
  list(outcome = "Education (1940)", model = results$main$educ_years_1940,
       sd_y = results$sds$educ_years_1940, coef_name = "aaa_intensity_z:school_age",
       spec = "Sibling FE"),
  list(outcome = "Occ.\\ Score (1950)", model = results$main$occ_1950,
       sd_y = results$sds$occscore_1950, coef_name = "aaa_intensity_z:school_age",
       spec = "Sibling FE"),
  list(outcome = "Migration (1940)", model = results$main$migration,
       sd_y = results$sds$migrated_1940, coef_name = "aaa_intensity_z:school_age",
       spec = "Sibling FE"),
  list(outcome = "Off-Farm (1940)", model = results$main$off_farm,
       sd_y = results$sds$off_farm_1940, coef_name = "aaa_intensity_z:school_age",
       spec = "Sibling FE")
)

classify_sde <- function(s) {
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

# Panel A: Pooled
panel_a_rows <- lapply(sde_data, function(d) {
  beta <- coef(d$model)[d$coef_name]
  se_beta <- se(d$model)[d$coef_name]
  sde <- beta / d$sd_y
  se_sde <- se_beta / d$sd_y
  cls <- classify_sde(sde)
  sprintf("%-22s & %s & %8.4f & --- & %6.3f & %8.4f & %8.4f & %s \\\\",
    d$outcome, d$spec, beta, d$sd_y, sde, se_sde, cls)
})

# Panel B: Heterogeneous (gender split — education only, 2 rows)
het_rows <- list()
m_m <- robust$gender$male
m_f <- robust$gender$female
sd_y <- results$sds$educ_years_1940
label <- "Education (1940)"

for (gender_info in list(list(m = m_m, g = "Male"), list(m = m_f, g = "Female"))) {
  beta <- coef(gender_info$m)["aaa_intensity_z:school_age"]
  se_beta <- se(gender_info$m)["aaa_intensity_z:school_age"]
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  cls <- classify_sde(sde)
  het_rows <- c(het_rows, list(sprintf(
    "%-22s & %s & %8.4f & --- & %6.3f & %8.4f & %8.4f & %s \\\\",
    paste0(label, " (", gender_info$g, ")"),
    "Sibling FE", beta, sd_y, sde, se_sde, cls)))
}

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether the Agricultural Adjustment Act's cotton acreage reduction program (1933--34) causally affected the long-run educational and occupational outcomes of Black sharecropper children at critical developmental stages. ",
  "\\textbf{Policy mechanism:} The AAA paid cotton landowners to reduce planted acreage by up to 35\\%, but landlords systematically displaced Black sharecroppers rather than sharing reduction payments, disrupting children's schooling and family economic stability during formative years. ",
  "\\textbf{Outcome definition:} Years of completed education (educ\\_1950), Duncan occupational income score (occscore\\_1950), binary migration indicator, and binary off-farm residence indicator from linked census records. ",
  "\\textbf{Treatment:} Continuous; county-level Black farm population share in 1930, standardized (mean zero, unit variance), proxying for AAA cotton contract exposure intensity. ",
  "\\textbf{Data:} Multigenerational Longitudinal Panel (MLP) linking 1930--1940--1950 U.S. censuses; unit of observation is the individual child; sample covers seven cotton-belt states. ",
  "\\textbf{Method:} Within-family sibling fixed effects with treatment intensity interacted with age-cohort indicators; standard errors clustered at the county level. ",
  "\\textbf{Sample:} Black farm children aged 0--17 in 1930 in households with two or more linked siblings in the cotton South (AL, AR, GA, LA, MS, SC, TX). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(panel_a_rows, collapse = "\n"), "\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (Gender)}} \\\\\n",
  paste(het_rows, collapse = "\n"), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_age_gradient.tex\n")
cat("  tab4_racial_comparison.tex\n")
cat("  tab5_robustness.tex\n")
cat("  tabF1_sde.tex\n")
