# apep_1120 - Romanian 2014 EU-2 Restriction Lifting
# 05_tables.R - Generate LaTeX tables for paper

source("code/00_packages.R")

data_dir  <- "data"
table_dir <- "tables"
if (!dir.exists(table_dir)) dir.create(table_dir, recursive = TRUE)

# ============================================================
# Load saved results
# ============================================================
cat("Loading results...\n")
results    <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

panel   <- results$panel
m1      <- results$m1
m2      <- results$m2
m3      <- results$m3
m4      <- results$m4
m5      <- results$m5
m_ddd   <- results$m_ddd

# ============================================================
# Helper functions
# ============================================================

fmt <- function(x, digits = 3) {
  formatC(x, format = "f", digits = digits)
}

# Format coefficient with stars
fmt_coef <- function(model, varname, digits = 3) {
  ct  <- summary(model)$coeftable
  b   <- ct[varname, "Estimate"]
  pv  <- ct[varname, "Pr(>|t|)"]
  stars <- ""
  if (pv < 0.01) stars <- "***"
  else if (pv < 0.05) stars <- "**"
  else if (pv < 0.10) stars <- "*"
  paste0(fmt(b, digits), stars)
}

# Format SE in parentheses
fmt_se <- function(model, varname, digits = 3) {
  ct <- summary(model)$coeftable
  se <- ct[varname, "Std. Error"]
  paste0("(", fmt(se, digits), ")")
}

# Get R-squared
fmt_r2 <- function(model, digits = 3) {
  r2 <- fitstat(model, "r2")$r2
  fmt(r2, digits)
}

# Write lines to file
write_tex <- function(lines, filepath) {
  writeLines(lines, filepath)
  cat(sprintf("  Wrote %s\n", filepath))
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\nTable 1: Summary statistics\n")

# Split by high/low theta
panel$high_theta_label <- ifelse(panel$high_theta == 1, "High", "Low")

# Pre vs post
panel$period <- ifelse(panel$year < 2014, "Pre", "Post")

# Compute summary stats
# Note: employment is in thousands (Eurostat LFS), population is in raw units
summ_stats <- function(df) {
  data.frame(
    emp_mean     = mean(df$employment, na.rm = TRUE),
    emp_sd       = sd(df$employment, na.rm = TRUE),
    pop_mean     = mean(df$population / 1000, na.rm = TRUE),   # convert to thousands
    pop_sd       = sd(df$population / 1000, na.rm = TRUE),
    gdp_mean     = mean(df$gdp_pc, na.rm = TRUE),
    gdp_sd       = sd(df$gdp_pc, na.rm = TRUE),
    emprate_mean = mean(df$emp_rate * 1000, na.rm = TRUE),     # per 1000 pop
    emprate_sd   = sd(df$emp_rate * 1000, na.rm = TRUE),
    constr_mean  = mean(df$constr_share, na.rm = TRUE),
    constr_sd    = sd(df$constr_share, na.rm = TRUE)
  )
}

# Four cells: High-Pre, High-Post, Low-Pre, Low-Post
hp <- summ_stats(panel[panel$high_theta == 1 & panel$period == "Pre", ])
hq <- summ_stats(panel[panel$high_theta == 1 & panel$period == "Post", ])
lp <- summ_stats(panel[panel$high_theta == 0 & panel$period == "Pre", ])
lq <- summ_stats(panel[panel$high_theta == 0 & panel$period == "Post", ])

# Build table
tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Emigration Exposure}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{High $\\theta$ (Above Median)} & \\multicolumn{2}{c}{Low $\\theta$ (Below Median)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Pre (2008--2013) & Post (2014--2024) & Pre (2008--2013) & Post (2014--2024) \\\\",
  "\\midrule",
  sprintf("Employment (thousands) & %s & %s & %s & %s \\\\",
          fmt(hp$emp_mean, 1), fmt(hq$emp_mean, 1), fmt(lp$emp_mean, 1), fmt(lq$emp_mean, 1)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(hp$emp_sd, 1), fmt(hq$emp_sd, 1), fmt(lp$emp_sd, 1), fmt(lq$emp_sd, 1)),
  "\\addlinespace",
  sprintf("Population (thousands) & %s & %s & %s & %s \\\\",
          fmt(hp$pop_mean, 1), fmt(hq$pop_mean, 1), fmt(lp$pop_mean, 1), fmt(lq$pop_mean, 1)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(hp$pop_sd, 1), fmt(hq$pop_sd, 1), fmt(lp$pop_sd, 1), fmt(lq$pop_sd, 1)),
  "\\addlinespace",
  sprintf("GDP per capita (EUR) & %s & %s & %s & %s \\\\",
          fmt(hp$gdp_mean, 0), fmt(hq$gdp_mean, 0), fmt(lp$gdp_mean, 0), fmt(lq$gdp_mean, 0)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(hp$gdp_sd, 0), fmt(hq$gdp_sd, 0), fmt(lp$gdp_sd, 0), fmt(lq$gdp_sd, 0)),
  "\\addlinespace",
  sprintf("Employment rate (per 1,000 pop.) & %s & %s & %s & %s \\\\",
          fmt(hp$emprate_mean, 1), fmt(hq$emprate_mean, 1), fmt(lp$emprate_mean, 1), fmt(lq$emprate_mean, 1)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(hp$emprate_sd, 1), fmt(hq$emprate_sd, 1), fmt(lp$emprate_sd, 1), fmt(lq$emprate_sd, 1)),
  "\\addlinespace",
  sprintf("Construction share & %s & %s & %s & %s \\\\",
          fmt(hp$constr_mean, 3), fmt(hq$constr_mean, 3), fmt(lp$constr_mean, 3), fmt(lq$constr_mean, 3)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(hp$constr_sd, 3), fmt(hq$constr_sd, 3), fmt(lp$constr_sd, 3), fmt(lq$constr_sd, 3)),
  "\\midrule",
  sprintf("Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          sum(panel$high_theta == 1 & panel$year == 2008),
          sum(panel$high_theta == 0 & panel$year == 2008)),
  sprintf("County-years & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          sum(panel$high_theta == 1), sum(panel$high_theta == 0)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{flushleft}\\small",
  paste0("\\textit{Notes:} Means with standard deviations in parentheses. ",
         "High $\\theta$ counties are those with above-median population decline ",
         "between 2002 and 2013, reflecting stronger pre-existing emigration pressure. ",
         "Employment and population are in thousands. GDP per capita is in current EUR. ",
         "Employment rate is total employment per 1,000 population. ",
         "Construction share is the ratio of construction employment to total employment. ",
         "Data: Eurostat regional statistics (NUTS-3)."),
  "\\end{flushleft}",
  "\\end{table}"
)

write_tex(tab1, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("\nTable 2: Main results\n")

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Emigration Exposure on County-Level Outcomes}",
  "\\label{tab:main}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & log(Employment) & log(Population) & Employment Rate & log(GDP p.c.) \\\\",
  "\\midrule",
  sprintf("$\\theta_c \\times \\text{Post}_{t}$ & %s & %s & %s & %s \\\\",
          fmt_coef(m1, "theta_x_post"), fmt_coef(m2, "theta_x_post"),
          fmt_coef(m3, "theta_x_post"), fmt_coef(m4, "theta_x_post")),
  sprintf(" & %s & %s & %s & %s \\\\",
          fmt_se(m1, "theta_x_post"), fmt_se(m2, "theta_x_post"),
          fmt_se(m3, "theta_x_post"), fmt_se(m4, "theta_x_post")),
  "\\addlinespace",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("$N$ & %s & %s & %s & %s \\\\",
          formatC(m1$nobs, format = "d", big.mark = ","),
          formatC(m2$nobs, format = "d", big.mark = ","),
          formatC(m3$nobs, format = "d", big.mark = ","),
          formatC(m4$nobs, format = "d", big.mark = ",")),
  sprintf("$R^2$ & %s & %s & %s & %s \\\\",
          fmt_r2(m1), fmt_r2(m2), fmt_r2(m3), fmt_r2(m4)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{flushleft}\\small",
  paste0("\\textit{Notes:} Each column reports estimates from a separate county-year regression ",
         "of the form $Y_{ct} = \\alpha_c + \\lambda_t + \\beta(\\theta_c \\times \\text{Post}_t) + \\varepsilon_{ct}$. ",
         "$\\theta_c$ measures the population decline in county $c$ between 2002 and 2013, ",
         "capturing pre-existing emigration exposure. $\\text{Post}_t = \\mathbf{1}[t \\geq 2014]$. ",
         "Standard errors clustered at the county level in parentheses. ",
         "Column (4) is restricted to 2012--2024 due to GDP data availability. ",
         "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$."),
  "\\end{flushleft}",
  "\\end{table}"
)

write_tex(tab2, file.path(table_dir, "tab2_main.tex"))

# ============================================================
# TABLE 3: Robustness
# ============================================================
cat("\nTable 3: Robustness\n")

m_baseline    <- m1
m_controls    <- m5
m_no_buc      <- robustness$no_bucharest
m_no_west     <- robustness$no_west

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness of the Employment Effect}",
  "\\label{tab:robust}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Baseline & With Controls & Without Bucharest & Without NW/West \\\\",
  "\\midrule",
  sprintf("$\\theta_c \\times \\text{Post}_{t}$ & %s & %s & %s & %s \\\\",
          fmt_coef(m_baseline, "theta_x_post"),
          fmt_coef(m_controls, "theta_x_post"),
          fmt_coef(m_no_buc,   "theta_x_post"),
          fmt_coef(m_no_west,  "theta_x_post")),
  sprintf(" & %s & %s & %s & %s \\\\",
          fmt_se(m_baseline, "theta_x_post"),
          fmt_se(m_controls, "theta_x_post"),
          fmt_se(m_no_buc,   "theta_x_post"),
          fmt_se(m_no_west,  "theta_x_post")),
  "\\addlinespace",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Baseline controls & No & Yes & No & No \\\\"),
  sprintf("$N$ & %s & %s & %s & %s \\\\",
          formatC(m_baseline$nobs, format = "d", big.mark = ","),
          formatC(m_controls$nobs, format = "d", big.mark = ","),
          formatC(m_no_buc$nobs,   format = "d", big.mark = ","),
          formatC(m_no_west$nobs,  format = "d", big.mark = ",")),
  sprintf("$R^2$ & %s & %s & %s & %s \\\\",
          fmt_r2(m_baseline), fmt_r2(m_controls),
          fmt_r2(m_no_buc),   fmt_r2(m_no_west)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{flushleft}\\small",
  paste0("\\textit{Notes:} Dependent variable: log(employment). ",
         "Column (1) repeats the baseline specification from Table~\\ref{tab:main}. ",
         "Column (2) adds interactions of log initial employment (2008) and a West-region indicator with $\\text{Post}_t$. ",
         "Column (3) drops Bucharest (RO321). ",
         "Column (4) drops all Nord-Vest and Vest counties (the highest-$\\theta$ region). ",
         "Standard errors clustered at the county level in parentheses. ",
         sprintf("Randomization inference $p$-value for the baseline specification: %s (1,000 permutations). ",
                 fmt(robustness$ri_pvalue, 3)),
         "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$."),
  "\\end{flushleft}",
  "\\end{table}"
)

write_tex(tab3, file.path(table_dir, "tab3_robustness.tex"))

# ============================================================
# TABLE 4: Sector Heterogeneity (DDD)
# ============================================================
cat("\nTable 4: Sector heterogeneity (DDD)\n")

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Sector Heterogeneity: Construction Triple-Difference}",
  "\\label{tab:ddd}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  " & log(Employment) \\\\",
  "\\midrule",
  sprintf("$\\theta_c \\times \\text{Post}_{t}$ & %s \\\\",
          fmt_coef(m_ddd, "theta_x_post")),
  sprintf(" & %s \\\\",
          fmt_se(m_ddd, "theta_x_post")),
  "\\addlinespace",
  sprintf("$\\theta_c \\times \\text{Post}_{t} \\times \\text{Construction}$ & %s \\\\",
          fmt_coef(m_ddd, "theta_x_post_x_constr")),
  sprintf(" & %s \\\\",
          fmt_se(m_ddd, "theta_x_post_x_constr")),
  "\\addlinespace",
  "County FE & Yes \\\\",
  "Year FE & Yes \\\\",
  "Sector FE & Yes \\\\",
  sprintf("$N$ & %s \\\\",
          formatC(m_ddd$nobs, format = "d", big.mark = ",")),
  sprintf("$R^2$ & %s \\\\", fmt_r2(m_ddd)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  paste0("\\textit{Notes:} County-sector-year panel (NACE sectors F, C, G--I, O--Q). ",
         "The dependent variable is log(employment) at the county-sector-year level. ",
         "$\\theta_c \\times \\text{Post}_t$ captures the average effect of emigration exposure ",
         "across all sectors. ",
         "$\\theta_c \\times \\text{Post}_t \\times \\text{Construction}$ captures the differential ",
         "effect in construction (NACE F) relative to other sectors. ",
         "Standard errors clustered at the county level in parentheses. ",
         "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$."),
  "\\end{flushleft}",
  "\\end{table}"
)

write_tex(tab4, file.path(table_dir, "tab4_ddd.tex"))

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================
cat("\nTable F1: SDE appendix\n")

# Compute SDE for each outcome
compute_sde <- function(model, varname, outcome_vec, outcome_label) {
  ct   <- summary(model)$coeftable
  beta <- ct[varname, "Estimate"]
  se   <- ct[varname, "Std. Error"]
  sd_y <- sd(outcome_vec, na.rm = TRUE)
  sde  <- beta / sd_y

  # SE of SDE via delta method: SE(beta)/SD(Y)
  se_sde <- se / sd_y

  # Classification
  abs_sde <- abs(sde)
  classification <- if (abs_sde > 0.15) {
    "Large"
  } else if (abs_sde > 0.05) {
    "Moderate"
  } else if (abs_sde > 0.005) {
    "Small"
  } else {
    "Null"
  }

  list(
    outcome        = outcome_label,
    beta           = beta,
    se             = se,
    sd_y           = sd_y,
    sde            = sde,
    se_sde         = se_sde,
    classification = classification
  )
}

# Panel A: Pooled
sde_emp     <- compute_sde(m1, "theta_x_post", panel$log_emp, "log(Employment)")
sde_pop     <- compute_sde(m2, "theta_x_post", panel$log_pop, "log(Population)")
sde_emprate <- compute_sde(m3, "theta_x_post", panel$emp_rate, "Employment rate")
panel_gdp   <- panel[!is.na(panel$log_gdp_pc), ]
sde_gdp     <- compute_sde(m4, "theta_x_post", panel_gdp$log_gdp_pc, "log(GDP p.c.)")

# Panel B: Heterogeneous — West vs non-West for employment
panel_west    <- panel[panel$west == 1, ]
panel_nonwest <- panel[panel$west == 0, ]
m_west    <- feols(log_emp ~ theta_x_post | geo + year, data = panel_west, cluster = ~geo)
m_nonwest <- feols(log_emp ~ theta_x_post | geo + year, data = panel_nonwest, cluster = ~geo)
sde_west    <- compute_sde(m_west,    "theta_x_post", panel_west$log_emp,    "Employment (West)")
sde_nonwest <- compute_sde(m_nonwest, "theta_x_post", panel_nonwest$log_emp, "Employment (non-West)")

# Format SDE row
sde_row <- function(s) {
  sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
          s$outcome,
          fmt(s$beta, 3),
          fmt(s$se, 3),
          fmt(s$sd_y, 3),
          fmt(s$sde, 3),
          fmt(s$se_sde, 3),
          s$classification)
}

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace",
  sde_row(sde_emp),
  sde_row(sde_pop),
  sde_row(sde_emprate),
  sde_row(sde_gdp),
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Employment)}} \\\\",
  "\\addlinespace",
  sde_row(sde_west),
  sde_row(sde_nonwest),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{flushleft}\\small",
  paste0(
    "\\textit{Notes:} SDE $= \\hat{\\beta} / \\text{SD}(Y)$, where SD($Y$) is the unconditional ",
    "standard deviation of the outcome in the estimation sample. ",
    "SE(SDE) $= \\text{SE}(\\hat{\\beta}) / \\text{SD}(Y)$ via the delta method. ",
    "Classification: Large ($|\\text{SDE}| > 0.15$), Moderate ($0.05 < |\\text{SDE}| \\leq 0.15$), ",
    "Small ($0.005 < |\\text{SDE}| \\leq 0.05$), Null ($|\\text{SDE}| \\leq 0.005$). ",
    "\\\\[3pt]",
    "\\textbf{Country:} Romania. ",
    "\\textbf{Research question:} Does the 2014 lifting of EU labor mobility restrictions ",
    "affect sending-county labor markets? ",
    "\\textbf{Policy mechanism:} Removal of work permit requirements by Germany, France, ",
    "and Austria for Romanian workers on January 1, 2014. ",
    "\\textbf{Outcome definition:} Employment (thousands, Eurostat LFS), population (thousands, Eurostat), ",
    "employment rate (per 1,000 pop.), GDP per capita (EUR, Eurostat). ",
    "\\textbf{Treatment:} County-level pre-2014 population decline ($\\theta_c$), capturing ",
    "emigration exposure intensity. ",
    "\\textbf{Data:} Eurostat NUTS-3 regional statistics, 2008--2024. ",
    "\\textbf{Method:} Continuous-treatment difference-in-differences with county and year fixed effects. ",
    "\\textbf{Sample:} 42 Romanian counties (NUTS-3), 17 years (2008--2024); ",
    "GDP specification limited to 2012--2024."
  ),
  "\\end{flushleft}",
  "\\end{table}"
)

write_tex(tabF1, file.path(table_dir, "tabF1_sde.tex"))

# ============================================================
# Done
# ============================================================
cat("\nAll tables written to ", table_dir, "/\n", sep = "")
cat("Files:\n")
for (f in list.files(table_dir, pattern = "\\.tex$")) {
  cat(sprintf("  %s\n", f))
}
