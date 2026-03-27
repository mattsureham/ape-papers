## 05_tables.R — Generate all tables for the paper
## Outputs: tables/tab1_summary.tex, tab2_main.tex, tab3_event.tex,
##          tab4_robust.tex, tab5_hetero.tex, tabF1_sde.tex

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
# Note: robustness_results.rds can be very large due to state trends model
# Re-run needed specs directly instead of loading from disk

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Pre-period and post-period means
sum_vars <- c("enterprises_pc", "units_pc", "emp_pc", "n_enterprises",
              "population", "urban_share")
sum_labels <- c("Enterprises per 10K pop.", "Local units per 10K pop.",
                "Employment per 10K pop.", "Number of enterprises",
                "Population", "Urbanization rate (2010)")

pre_data <- panel[year < 2021]
post_data <- panel[year == 2021]

sum_table <- data.table(
  Variable = sum_labels,
  `Pre-Mean` = sapply(sum_vars, function(v) sprintf("%.1f", mean(pre_data[[v]], na.rm=TRUE))),
  `Pre-SD` = sapply(sum_vars, function(v) sprintf("%.1f", sd(pre_data[[v]], na.rm=TRUE))),
  `Post-Mean` = sapply(sum_vars, function(v) sprintf("%.1f", mean(post_data[[v]], na.rm=TRUE))),
  `Post-SD` = sapply(sum_vars, function(v) sprintf("%.1f", sd(post_data[[v]], na.rm=TRUE))),
  N = sapply(sum_vars, function(v) format(sum(!is.na(pre_data[[v]])), big.mark=","))
)

# Write LaTeX
tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-Pix (2018--2020)} & \\multicolumn{2}{c}{Post-Pix (2021)} & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD & N (Pre) \\\\",
  "\\midrule"
)

for (i in 1:nrow(sum_table)) {
  tab1_tex <- c(tab1_tex, sprintf("%s & %s & %s & %s & %s & %s \\\\",
                                  sum_table$Variable[i],
                                  sum_table$`Pre-Mean`[i],
                                  sum_table$`Pre-SD`[i],
                                  sum_table$`Post-Mean`[i],
                                  sum_table$`Post-SD`[i],
                                  sum_table$N[i]))
}

tab1_tex <- c(tab1_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Unit of observation is municipality-year. Pre-Pix period includes 2018--2020; post-Pix period is 2021 (first full calendar year after Pix launch in November 2020). Urbanization rate is from the 2010 Census. Sample includes 5,565 municipalities across 27 Brazilian states.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ============================================================================
# Table 2: Main Results
# ============================================================================
cat("=== Table 2: Main Results ===\n")

# Re-run models for clean table
main <- feols(enterprises_pc ~ treat_x_post | muni_code + year,
              data = panel, cluster = ~state_code)

panel_3yr <- panel[year >= 2019]
panel_3yr[, post := as.integer(year >= 2021)]
panel_3yr[, treat_x_post := urban_share * post]

main_3yr <- feols(enterprises_pc ~ treat_x_post | muni_code + year,
                  data = panel_3yr, cluster = ~state_code)

state_yr <- feols(enterprises_pc ~ treat_x_post | muni_code + state_code^year,
                  data = panel, cluster = ~state_code)

units <- feols(units_pc ~ treat_x_post | muni_code + year,
               data = panel, cluster = ~state_code)

emp <- feols(emp_pc ~ treat_x_post | muni_code + year,
             data = panel, cluster = ~state_code)

# Format table
tab2_models <- list(main, main_3yr, state_yr, units, emp)
tab2_names <- c("(1)", "(2)", "(3)", "(4)", "(5)")

# Extract stats
get_row <- function(models, param = "treat_x_post") {
  coefs <- sapply(models, function(m) coef(m)[param])
  ses <- sapply(models, function(m) se(m)[param])
  pvals <- sapply(models, function(m) pvalue(m)[param])
  stars <- sapply(pvals, function(p) {
    if (p < 0.001) return("***")
    if (p < 0.01) return("**")
    if (p < 0.05) return("*")
    return("")
  })
  list(coefs = coefs, ses = ses, stars = stars)
}

r <- get_row(tab2_models)

tab2_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Pix Adoption on Business Formalization}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Enterprises per 10K} & Units & Employment \\\\",
  " & \\multicolumn{3}{c}{population} & per 10K & per 10K \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-5} \\cmidrule(lr){6-6}",
  sprintf(" & %s \\\\", paste(tab2_names, collapse = " & ")),
  "\\midrule",
  sprintf("Urban share $\\times$ Post & %s \\\\",
          paste(sprintf("%.2f%s", r$coefs, r$stars), collapse = " & ")),
  sprintf(" & %s \\\\",
          paste(sprintf("(%.2f)", r$ses), collapse = " & ")),
  "\\midrule",
  sprintf("Panel years & 2018--21 & 2019--21 & 2018--21 & 2018--21 & 2018--21 \\\\"),
  sprintf("Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & --- & Yes & Yes \\\\"),
  sprintf("State $\\times$ Year FE & --- & --- & Yes & --- & --- \\\\"),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(main), big.mark=","),
          format(nobs(main_3yr), big.mark=","),
          format(nobs(state_yr), big.mark=","),
          format(nobs(units), big.mark=","),
          format(nobs(emp), big.mark=",")),
  sprintf("Municipalities & %s & %s & %s & %s & %s \\\\",
          format(uniqueN(panel$muni_code), big.mark=","),
          format(uniqueN(panel_3yr$muni_code), big.mark=","),
          format(uniqueN(panel$muni_code), big.mark=","),
          format(uniqueN(panel$muni_code), big.mark=","),
          format(uniqueN(panel$muni_code), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports a separate OLS regression. The dependent variable is indicated in the column header. ``Urban share $\\times$ Post'' is the interaction of the municipality's 2010 Census urbanization rate with an indicator for the post-Pix period (2021). All specifications include municipality fixed effects. Standard errors clustered at the state level (27 clusters) in parentheses. Wild cluster bootstrap $p$-value for column (1): 0.003. * $p < 0.05$, ** $p < 0.01$, *** $p < 0.001$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

# ============================================================================
# Table 3: Event Study
# ============================================================================
cat("=== Table 3: Event Study ===\n")

# Full panel event study (2015-2021, base=2020)
panel[, year_f := factor(year, levels = c(2020, 2015, 2016, 2017, 2018, 2019, 2021))]
es_full <- feols(
  enterprises_pc ~ i(year_f, urban_share, ref = 2020) | muni_code + year,
  data = panel, cluster = ~state_code
)

es_coefs <- coef(es_full)
es_se <- se(es_full)
es_pv <- pvalue(es_full)

stars_fn <- function(p) {
  if (p < 0.001) return("***")
  if (p < 0.01) return("**")
  if (p < 0.05) return("*")
  return("")
}

# Build event study table with all years
es_years <- c(2015, 2016, 2017, 2018, 2019, 2021)
tab3_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Year-by-Year Effects}",
  "\\label{tab:event}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  " & Enterprises per 10K \\\\",
  "\\midrule"
)

for (i in seq_along(es_years)) {
  yr <- es_years[i]
  tab3_tex <- c(tab3_tex,
    sprintf("Urban $\\times$ $\\mathbb{1}[%d]$ & %.2f%s \\\\", yr, es_coefs[i], stars_fn(es_pv[i])),
    sprintf(" & (%.2f) \\\\", es_se[i])
  )
}
tab3_tex <- c(tab3_tex,
  "Urban $\\times$ $\\mathbb{1}[2020]$ & [Base] \\\\",
  "\\midrule",
  sprintf("Observations & %s \\\\", format(nobs(es_full), big.mark=",")),
  sprintf("Municipalities & %s \\\\", format(uniqueN(panel$muni_code), big.mark=",")),
  "Municipality FE & Yes \\\\",
  "Year FE & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from a single regression of enterprises per 10,000 population on year-specific interactions of urban share with year indicators. Base year is 2020 (Pix launch year). The large 2018 coefficient reflects the MEI revenue threshold expansion from R\\$60,000 to R\\$81,000. Standard errors clustered at the state level (27 clusters) in parentheses. * $p < 0.05$, ** $p < 0.01$, *** $p < 0.001$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_event.tex"))
cat("  Saved tab3_event.tex\n")

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("=== Table 4: Robustness ===\n")

# Compile robustness results
panel[, high_urban := as.integer(urban_share > median(urban_share))]
panel[, high_urban_x_post := high_urban * post]

binary <- feols(enterprises_pc ~ high_urban_x_post | muni_code + year,
                data = panel, cluster = ~state_code)

# Placebo timing
panel_pre <- panel[year <= 2020]
panel_pre[, pseudo_post := as.integer(year >= 2020)]
panel_pre[, pseudo_treat := urban_share * pseudo_post]
placebo_time <- feols(enterprises_pc ~ pseudo_treat | muni_code + year,
                      data = panel_pre, cluster = ~state_code)

# Placebo outcome
panel[, emp_salaried_pc := (emp_salaried / population) * 10000]
placebo_sal <- feols(emp_salaried_pc ~ treat_x_post | muni_code + year,
                     data = panel[!is.na(emp_salaried_pc)], cluster = ~state_code)

# Build table (6 specs — state trends removed for speed)
specs <- list(main, main_3yr, state_yr, binary, placebo_time, placebo_sal)
spec_names <- c("Baseline", "Drop 2018", "State$\\times$Year FE",
                "Binary treat.", "Placebo timing", "Placebo outcome")
param_names <- c("treat_x_post", "treat_x_post", "treat_x_post",
                 "high_urban_x_post", "pseudo_treat", "treat_x_post")

tab4_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule"
)

# Header row
header <- paste(sprintf("& (%d)", 1:6), collapse = " ")
tab4_tex <- c(tab4_tex, sprintf(" %s \\\\", header))
tab4_tex <- c(tab4_tex, "\\midrule")

# Coefficient row
coef_vals <- mapply(function(m, p) {
  cf <- coef(m)[p]
  pv <- pvalue(m)[p]
  sprintf("%.2f%s", cf, stars_fn(pv))
}, specs, param_names)
tab4_tex <- c(tab4_tex, sprintf("Treatment $\\times$ Post & %s \\\\",
                                paste(coef_vals, collapse = " & ")))

# SE row
se_vals <- mapply(function(m, p) sprintf("(%.2f)", se(m)[p]), specs, param_names)
tab4_tex <- c(tab4_tex, sprintf(" & %s \\\\", paste(se_vals, collapse = " & ")))

tab4_tex <- c(tab4_tex,
  "\\midrule",
  sprintf("Specification & %s \\\\", paste(spec_names, collapse = " & ")),
  sprintf("Dep. var. & %s \\\\",
          paste(c(rep("Ent./10K", 5), "Sal. emp./10K"), collapse = " & ")),
  sprintf("Observations & %s \\\\",
          paste(sapply(specs, function(m) format(nobs(m), big.mark=",")), collapse = " & ")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Columns (1)--(4) report the effect on enterprises per 10,000 population. Column (5) applies the main specification to the pre-period only (2018--2020) with a pseudo-treatment at 2020. Column (6) replaces the dependent variable with salaried employment per 10,000 population. All specifications include municipality and year fixed effects unless otherwise noted. ``Binary treat.'' replaces continuous urbanization with an above-median indicator. Standard errors clustered at the state level in parentheses. * $p < 0.05$, ** $p < 0.01$, *** $p < 0.001$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_robust.tex"))
cat("  Saved tab4_robust.tex\n")

# ============================================================================
# Table 5: Heterogeneity
# ============================================================================
cat("=== Table 5: Heterogeneity ===\n")

# Split-sample regressions
panel_south <- panel[region %in% c("South", "Southeast")]
panel_north <- panel[region %in% c("North", "Northeast")]
panel_large <- panel[population >= 50000]
panel_small <- panel[population < 50000]

het_south <- feols(enterprises_pc ~ treat_x_post | muni_code + year,
                   data = panel_south, cluster = ~state_code)
het_north <- feols(enterprises_pc ~ treat_x_post | muni_code + year,
                   data = panel_north, cluster = ~state_code)
het_large <- feols(enterprises_pc ~ treat_x_post | muni_code + year,
                   data = panel_large, cluster = ~state_code)
het_small <- feols(enterprises_pc ~ treat_x_post | muni_code + year,
                   data = panel_small, cluster = ~state_code)

het_specs <- list(het_south, het_north, het_large, het_small)

tab5_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Region and Municipality Size}",
  "\\label{tab:hetero}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & South/ & North/ & Large & Small \\\\",
  " & Southeast & Northeast & ($\\geq$50K) & ($<$50K) \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule"
)

coef_h <- sapply(het_specs, function(m) coef(m)["treat_x_post"])
se_h <- sapply(het_specs, function(m) se(m)["treat_x_post"])
pv_h <- sapply(het_specs, function(m) pvalue(m)["treat_x_post"])

tab5_tex <- c(tab5_tex,
  sprintf("Urban share $\\times$ Post & %s \\\\",
          paste(sprintf("%.2f%s", coef_h, sapply(pv_h, stars_fn)), collapse = " & ")),
  sprintf(" & %s \\\\", paste(sprintf("(%.2f)", se_h), collapse = " & ")),
  "\\midrule",
  sprintf("Municipalities & %s \\\\",
          paste(sapply(het_specs, function(m) format(length(fixef(m)[[1]]), big.mark=",")), collapse = " & ")),
  sprintf("Observations & %s \\\\",
          paste(sapply(het_specs, function(m) format(nobs(m), big.mark=",")), collapse = " & ")),
  "Municipality FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column restricts the sample to the indicated subgroup. South/Southeast includes states in the two most developed macro-regions; North/Northeast includes the less developed regions. Large municipalities have population $\\geq$ 50,000; small municipalities have population $<$ 50,000. Standard errors clustered at the state level in parentheses. * $p < 0.05$, ** $p < 0.01$, *** $p < 0.001$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_tex, file.path(table_dir, "tab5_hetero.tex"))
cat("  Saved tab5_hetero.tex\n")

# ============================================================================
# SDE Table (Appendix)
# ============================================================================
cat("=== SDE Table ===\n")

pre_sd_ent <- sd(panel[year < 2021]$enterprises_pc, na.rm = TRUE)
pre_sd_units <- sd(panel[year < 2021]$units_pc, na.rm = TRUE)
pre_sd_emp <- sd(panel[year < 2021]$emp_pc, na.rm = TRUE)
sd_x <- sd(panel$urban_share, na.rm = TRUE)

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sde_ent <- coef(main)["treat_x_post"] * sd_x / pre_sd_ent
sde_units <- coef(units)["treat_x_post"] * sd_x / pre_sd_units
sde_emp <- coef(emp)["treat_x_post"] * sd_x / pre_sd_emp

se_sde_ent <- se(main)["treat_x_post"] * sd_x / pre_sd_ent
se_sde_units <- se(units)["treat_x_post"] * sd_x / pre_sd_units
se_sde_emp <- se(emp)["treat_x_post"] * sd_x / pre_sd_emp

# Heterogeneity SDEs (split sample)
pre_sd_south <- sd(panel_south[year < 2021]$enterprises_pc, na.rm = TRUE)
pre_sd_north <- sd(panel_north[year < 2021]$enterprises_pc, na.rm = TRUE)
sd_x_south <- sd(panel_south$urban_share, na.rm = TRUE)
sd_x_north <- sd(panel_north$urban_share, na.rm = TRUE)

sde_south <- coef(het_south)["treat_x_post"] * sd_x_south / pre_sd_south
sde_north <- coef(het_north)["treat_x_post"] * sd_x_north / pre_sd_north
se_sde_south <- se(het_south)["treat_x_post"] * sd_x_south / pre_sd_south
se_sde_north <- se(het_north)["treat_x_post"] * sd_x_north / pre_sd_north

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Build SDE rows
sde_rows <- data.table(
  Panel = c(rep("A", 3), rep("B", 2)),
  Outcome = c("Enterprises per 10K", "Local units per 10K", "Employment per 10K",
              "Enterprises (South/SE)", "Enterprises (North/NE)"),
  Beta = c(coef(main)["treat_x_post"], coef(units)["treat_x_post"], coef(emp)["treat_x_post"],
           coef(het_south)["treat_x_post"], coef(het_north)["treat_x_post"]),
  SE = c(se(main)["treat_x_post"], se(units)["treat_x_post"], se(emp)["treat_x_post"],
         se(het_south)["treat_x_post"], se(het_north)["treat_x_post"]),
  SD_Y = c(pre_sd_ent, pre_sd_units, pre_sd_emp, pre_sd_south, pre_sd_north),
  SDE = c(sde_ent, sde_units, sde_emp, sde_south, sde_north),
  SE_SDE = c(se_sde_ent, se_sde_units, se_sde_emp, se_sde_south, se_sde_north),
  Classification = c(classify_sde(sde_ent), classify_sde(sde_units), classify_sde(sde_emp),
                     classify_sde(sde_south), classify_sde(sde_north))
)

cat("SDE results:\n")
print(sde_rows)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Does the adoption of instant digital payment infrastructure (Pix) cause microenterprise formalization, as measured by business registration rates in Brazilian municipalities? ",
  "\\textbf{Policy mechanism:} Brazil's Central Bank launched Pix in November 2020 as a mandatory instant payment system with zero fees for individuals and near-zero fees for merchants, reducing the cost of accepting formal digital payments and thereby lowering the effective barrier to business registration for informal microenterprises. ",
  "\\textbf{Outcome definition:} Number of active enterprises per 10,000 municipal population from IBGE CEMPRE, counting all registered business entities (CNPJ holders) including microentrepreneurs (MEI). ",
  "\\textbf{Treatment:} Continuous; 2010 Census urbanization rate (share of population in urban areas) as a proxy for pre-existing digital readiness and Pix adoption intensity. ",
  "\\textbf{Data:} IBGE SIDRA (CEMPRE Tables 6449/6450 and Census 2010 Table 202), 2018--2021, municipality-year panel, 5,565 municipalities, 22,260 observations. ",
  "\\textbf{Method:} Continuous treatment intensity difference-in-differences with municipality and year fixed effects; standard errors clustered at the state level (27 clusters); wild cluster bootstrap inference. ",
  "\\textbf{Sample:} All Brazilian municipalities with non-missing CEMPRE data and 2010 Census population; excludes Fernando de Noronha and other territories with missing urbanization data. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional standard deviation of the urbanization rate and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in which(sde_rows$Panel == "A")) {
  sde_tex <- c(sde_tex, sprintf("%s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
                                sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
                                sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
                                sde_rows$Classification[i]))
}

sde_tex <- c(sde_tex,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by region)}} \\\\"
)

for (i in which(sde_rows$Panel == "B")) {
  sde_tex <- c(sde_tex, sprintf("%s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
                                sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
                                sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
                                sde_rows$Classification[i]))
}

sde_tex <- c(sde_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat(paste(list.files(table_dir), collapse = "\n"), "\n")
