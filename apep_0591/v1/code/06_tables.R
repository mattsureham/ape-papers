# =============================================================================
# 06_tables.R — All table generation
# APEP-0591: The Erasmus Drain
# =============================================================================

source("00_packages.R")

data_dir  <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel   <- fread(file.path(data_dir, "analysis_panel.csv"))
cross   <- fread(file.path(data_dir, "analysis_cross_section.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust  <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
# Use the main estimation sample (matching the 2SLS regression)
sum_data <- panel[!is.na(tert_share_25_34) & !is.na(predicted_out_rate) & !is.na(out_rate)]

vars_list <- list(
  "Tertiary share, 25--34 (\\%)" = "tert_share_25_34",
  "Tertiary share, 25--64 (\\%)" = "tert_share_25_64",
  "LFP, 25--34 (thousands)" = "lfp_25_34",
  "Employment, 25--34 (thousands)" = "emp_25_34",
  "Erasmus outflow rate (per 1k youth)" = "out_rate",
  "Net Erasmus outflow rate (per 1k youth)" = "net_out_rate",
  "Predicted outflow rate (Bartik IV)" = "predicted_out_rate",
  "Bartik growth rate" = "bartik_growth",
  "GDP per capita (EUR)" = "gdp_pc"
)

sumstats <- data.table()
for (vname in names(vars_list)) {
  vcol <- vars_list[[vname]]
  if (vcol %in% names(sum_data)) {
    vals <- sum_data[[vcol]]
    vals <- vals[!is.na(vals)]
    sumstats <- rbind(sumstats, data.table(
      Variable = vname,
      Mean = round(mean(vals), 2),
      SD = round(sd(vals), 2),
      Min = round(min(vals), 2),
      Max = round(max(vals), 2),
      N = length(vals)
    ))
  }
}

# LaTeX table
tab1_tex <- kable(sumstats, format = "latex", booktabs = TRUE,
                  caption = "Summary Statistics",
                  label = "sumstats",
                  escape = FALSE) |>
  kable_styling(latex_options = c("hold_position"))

# Add resizebox
tab1_tex <- gsub("(\\\\begin\\{tabular\\})", "\\\\resizebox{\\\\textwidth}{!}{\\1", tab1_tex)
tab1_tex <- gsub("(\\\\end\\{tabular\\})", "\\1}", tab1_tex)
writeLines(tab1_tex, file.path(table_dir, "tab1_sumstats.tex"))
fwrite(sumstats, file.path(data_dir, "tab1_sumstats.csv"))
cat("Table 1 saved\n")

# ---------------------------------------------------------------
# Table 2: First Stage
# ---------------------------------------------------------------
tab2_tex <- etable(results$first_stage, results$first_stage_pred,
                   dict = c(out_rate = "Outflow rate",
                            bartik_growth = "Bartik growth",
                            predicted_out_rate = "Predicted outflow rate"),
                   headers = c("Growth", "Level"),
                   tex = TRUE,
                   title = "First Stage: Bartik Instrument and Erasmus Outflows",
                   label = "tab:first_stage",
                   fitstat = ~n + r2,
                   fixef.group = list("Region FE" = "nuts2",
                                      "Year FE" = "^year$"))

# Add scriptsize and adjustbox
tab2_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab2_tex)
tab2_tex <- gsub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n   \\\\begin{tabular}", tab2_tex)
tab2_tex <- gsub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n   \\\\end{adjustbox}", tab2_tex)
tab2_tex <- gsub("\\\\multicolumn\\{3\\}\\{l\\}", "\\\\multicolumn{3}{p{\\\\textwidth}}", tab2_tex)
writeLines(tab2_tex, file.path(table_dir, "tab2_first_stage.tex"))
cat("Table 2 saved\n")

# ---------------------------------------------------------------
# Table 3: Main Results — OLS and 2SLS
# ---------------------------------------------------------------
tab3_tex <- etable(results$ols_tert, results$iv_tert,
                   results$iv_tert_2way, results$iv_lfp,
                   results$iv_emp,
                   dict = c(tert_share_25_34 = "Tertiary share (25--34)",
                            lfp_25_34 = "LFP (25--34)",
                            emp_25_34 = "Employment (25--34)",
                            out_rate = "Outflow rate",
                            fit_out_rate = "Outflow rate"),
                   headers = c("OLS", "2SLS", "2SLS (2-way)", "2SLS: LFP", "2SLS: Emp"),
                   tex = TRUE,
                   title = "Main Results: Effect of Erasmus Outflows on Regional Human Capital",
                   label = "tab:main",
                   fitstat = ~n + ivf + r2,
                   notes = "All specifications include NUTS2 region and year fixed effects. Standard errors clustered at the NUTS2 level (Columns 1--2, 4--5) or two-way clustered by NUTS2 and year (Column 3). The instrument is the shift-share IV constructed from pre-period (2014--2016) bilateral Erasmus flow shares and leave-one-out destination growth rates.")

# Add scriptsize and adjustbox
tab3_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab3_tex)
tab3_tex <- gsub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n   \\\\begin{tabular}", tab3_tex)
tab3_tex <- gsub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n   \\\\end{adjustbox}", tab3_tex)
writeLines(tab3_tex, file.path(table_dir, "tab3_main.tex"))
cat("Table 3 saved\n")

# ---------------------------------------------------------------
# Table 4: Placebo — Young vs Broad Cohort
# ---------------------------------------------------------------
tab4_tex <- etable(results$iv_tert, results$iv_placebo,
                   results$iv_emp, results$iv_emp_placebo,
                   dict = c(tert_share_25_34 = "Tertiary share (25--34)",
                            tert_share_25_64 = "Tertiary share (25--64)",
                            emp_25_34 = "Employment (25--34)",
                            emp_25_64 = "Employment (25--64)",
                            fit_out_rate = "Outflow rate"),
                   headers = c("Tert 25--34", "Tert 25--64", "Emp 25--34", "Emp 25--64"),
                   tex = TRUE,
                   title = "Placebo Test: Erasmus-Affected vs.\\ Broader Cohort",
                   label = "tab:placebo",
                   fitstat = ~n + ivf + r2,
                   notes = "All columns use 2SLS with shift-share IV. Column 2 shows the cohort dilution test: the broader 25--64 tertiary share includes the treated 25--34 group but is diluted by older workers, yielding a near-zero estimate. Column 4 shows employment spillovers to the broader cohort. Standard errors clustered at the NUTS2 level.")

# Add scriptsize and adjustbox
tab4_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab4_tex)
tab4_tex <- gsub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n   \\\\begin{tabular}", tab4_tex)
tab4_tex <- gsub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n   \\\\end{adjustbox}", tab4_tex)
writeLines(tab4_tex, file.path(table_dir, "tab4_placebo.tex"))
cat("Table 4 saved\n")

# ---------------------------------------------------------------
# Table 5: Heterogeneity
# ---------------------------------------------------------------
tab5_tex <- etable(robust$iv_peripheral, robust$iv_core,
                   robust$iv_senders, robust$iv_receivers,
                   dict = c(tert_share_25_34 = "Tertiary share (25--34)",
                            fit_out_rate = "Outflow rate"),
                   headers = c("Peripheral", "Core", "Net Senders", "Net Receivers"),
                   tex = TRUE,
                   title = "Heterogeneity: Effects by Regional Characteristics",
                   label = "tab:heterogeneity",
                   fitstat = ~n + ivf + r2,
                   notes = "Peripheral = below-median pre-period GDP per capita. Net senders = positive average net Erasmus outflow in 2014--2016. All specifications include NUTS2 region and year FE with shift-share IV. Standard errors clustered at NUTS2.")

# Add scriptsize
tab5_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab5_tex)
writeLines(tab5_tex, file.path(table_dir, "tab5_heterogeneity.tex"))
cat("Table 5 saved\n")

# ---------------------------------------------------------------
# Table C.1: Robustness checks (Appendix)
# ---------------------------------------------------------------
tab_c1_tex <- etable(results$iv_tert, robust$nocovid, robust$alt_shares,
                     robust$pretrend, robust$iv_country_year,
                     dict = c(tert_share_25_34 = "Tertiary share (25--34)",
                              fit_out_rate = "Outflow rate",
                              predicted_out_rate = "Predicted outflow rate",
                              predicted_out_rate_alt = "Predicted outflow (alt)"),
                     headers = c("Baseline", "No COVID yrs", "Alt shares (14--15)",
                                 "Pre-trend (14--19)", "Country $\\times$ Year FE"),
                     tex = TRUE,
                     title = "Robustness: Alternative Specifications",
                     label = "tab:robustness",
                     fitstat = ~n + ivf + r2)

# Add scriptsize and adjustbox for wider table
tab_c1_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab_c1_tex)
tab_c1_tex <- gsub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n   \\\\begin{tabular}", tab_c1_tex)
tab_c1_tex <- gsub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n   \\\\end{adjustbox}", tab_c1_tex)
# Fix multicolumn notes width for 6 columns
tab_c1_tex <- gsub("\\\\multicolumn\\{6\\}\\{l\\}", "\\\\multicolumn{6}{p{0.9\\\\textwidth}}", tab_c1_tex)
tab_c1_tex <- gsub("\\\\multicolumn\\{5\\}\\{l\\}", "\\\\multicolumn{5}{p{0.9\\\\textwidth}}", tab_c1_tex)
writeLines(tab_c1_tex, file.path(table_dir, "tabC1_robustness.tex"))
cat("Table C.1 saved\n")

# ---------------------------------------------------------------
# Table C.2: Cross-section results
# ---------------------------------------------------------------
tab_c2_tex <- etable(results$ols_cross, results$iv_cross,
                     results$iv_cross_placebo,
                     dict = c(delta_tert = "Delta Tertiary (25--34)",
                              delta_tert_old = "Delta Tertiary (25--64)",
                              delta_out = "Delta Outflow rate",
                              fit_delta_out = "Delta Outflow rate"),
                     headers = c("OLS", "2SLS", "2SLS Placebo"),
                     tex = TRUE,
                     title = "Cross-Sectional Long-Difference Specification",
                     label = "tab:cross_section",
                     fitstat = ~n + ivf + r2,
                     notes = "Long differences: post (2021--2022) minus pre (2014--2019). Country FE included.")

# Add scriptsize
tab_c2_tex <- gsub("\\\\centering", "\\\\centering\n   \\\\scriptsize", tab_c2_tex)
writeLines(tab_c2_tex, file.path(table_dir, "tabC2_cross_section.tex"))
cat("Table C.2 saved\n")

# ---------------------------------------------------------------
# Table F.1: Standardized Effect Sizes (Appendix F)
# ---------------------------------------------------------------
main_model <- results$iv_tert
lfp_model  <- results$iv_lfp
emp_model  <- results$iv_emp

# SD(Y) from unconditional distribution
sd_tert <- sd(panel$tert_share_25_34, na.rm = TRUE)
sd_lfp  <- sd(panel$lfp_25_34, na.rm = TRUE)
sd_emp  <- sd(panel$emp_25_34, na.rm = TRUE)

# SD(X) — treatment is continuous (outflow rate)
sd_x <- sd(panel$out_rate, na.rm = TRUE)

# Extract coefficients and SEs
beta_tert <- coef(main_model)["fit_out_rate"]
se_tert   <- se(main_model)["fit_out_rate"]
beta_lfp  <- coef(lfp_model)["fit_out_rate"]
se_lfp    <- se(lfp_model)["fit_out_rate"]
beta_emp  <- coef(emp_model)["fit_out_rate"]
se_emp    <- se(emp_model)["fit_out_rate"]

# SDE = beta * SD(X) / SD(Y) (continuous treatment)
sde_tert    <- beta_tert * sd_x / sd_tert
se_sde_tert <- se_tert * sd_x / sd_tert
sde_lfp     <- beta_lfp * sd_x / sd_lfp
se_sde_lfp  <- se_lfp * sd_x / sd_lfp
sde_emp     <- beta_emp * sd_x / sd_emp
se_sde_emp  <- se_emp * sd_x / sd_emp

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("N/A")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_table <- data.table(
  Outcome = c("Tertiary share (25--34)", "LFP (25--34)", "Employment (25--34)"),
  Specification = c("Table 3, Col. 2", "Table 3, Col. 4", "Table 3, Col. 5"),
  `$\\hat{\\beta}$` = round(c(beta_tert, beta_lfp, beta_emp), 4),
  `SD(X)` = round(rep(sd_x, 3), 4),
  `SD(Y)` = round(c(sd_tert, sd_lfp, sd_emp), 4),
  SDE = round(c(sde_tert, sde_lfp, sde_emp), 4),
  `SE(SDE)` = round(c(se_sde_tert, se_sde_lfp, se_sde_emp), 4),
  Classification = c(classify_sde(sde_tert), classify_sde(sde_lfp), classify_sde(sde_emp))
)

tab_f1_tex <- kable(sde_table, format = "latex", booktabs = TRUE,
                    escape = FALSE,
                    caption = "Standardized Effect Sizes",
                    label = "sde") |>
  kable_styling(latex_options = c("hold_position", "scale_down")) |>
  footnote(general = paste0(
    "This table reports standardized effect sizes (SDE) for the main causal estimates. ",
    "The paper studies the effect of Erasmus+ student mobility on regional human capital ",
    "across approximately 313 NUTS2 regions in the EU, 2014--2023, ",
    "using Eurostat regional data and geolocated Erasmus flow records ",
    "(Vaisanen et al. 2025; see references). ",
    "Estimation sample: ", nobs(main_model), " region-year observations (Table 3, Col. 2). ",
    "Identification uses a shift-share (Bartik) IV exploiting pre-period bilateral flow ",
    "structure and destination-level growth (Borusyak, Hull, and Jaravel 2022). ",
    "Treatment is continuous (outflow rate per 1,000 youth population). ",
    "SDE = $\\hat{\\beta}$ $\\times$ SD(X) / SD(Y). ",
    "SE(SDE) = SE($\\hat{\\beta}$) $\\times$ SD(X) / SD(Y). ",
    "SD(X) and SD(Y) are unconditional standard deviations from the full panel. ",
    "Classification labels refer to the magnitude of the standardized point estimate, ",
    "not to statistical significance."),
    escape = FALSE, threeparttable = TRUE)

# Ensure resizebox wraps the full table content
writeLines(tab_f1_tex, file.path(table_dir, "tabF1_sde.tex"))
fwrite(sde_table, file.path(data_dir, "sde_table.csv"))
cat("Table F.1 (SDE) saved\n")

cat("\n=== ALL TABLES GENERATED ===\n")
