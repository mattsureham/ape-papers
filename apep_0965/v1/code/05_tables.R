# =============================================================================
# 05_tables.R — Generate all tables including SDE appendix
# apep_0965: EU Retaliatory Tariffs and US County Employment
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
diagnostics <- read_json("../data/diagnostics.json")
panel <- fread("../data/county_panel_balanced.csv")
exposure <- fread("../data/county_exposure.csv")

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================

panel[, yq_factor := factor(paste0(year, "Q", quarter))]
pre_panel <- panel[post == 0]

# Summary by exposure category
summ_stats <- panel[, .(
  `Mean Emp` = mean(emp, na.rm = TRUE),
  `SD Emp` = sd(emp, na.rm = TRUE),
  `Mean Targeted Emp` = mean(emp_targeted, na.rm = TRUE),
  `Mean Hires` = mean(hira, na.rm = TRUE),
  `Mean Separations` = mean(sep, na.rm = TRUE),
  `Mean Exposure` = mean(exposure_share, na.rm = TRUE),
  Counties = uniqueN(fips)
), by = exposure_cat]

setorder(summ_stats, exposure_cat)

# Build LaTeX table manually for full control
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by EU Tariff Exposure}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  " & Mean & SD & Mean Targeted & Mean & Mean & Mean & \\\\",
  "Exposure Group & Emp & Emp & Emp & Hires & Sep & Exposure & Counties \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ_stats)) {
  row <- summ_stats[i]
  # Escape % for LaTeX
  cat_label <- gsub("%", "\\\\%", as.character(row$exposure_cat))
  cat_label <- gsub(">", "$>$", cat_label)
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %.3f & %d \\\\",
    cat_label,
    format(round(row$`Mean Emp`), big.mark = ","),
    format(round(row$`SD Emp`), big.mark = ","),
    format(round(row$`Mean Targeted Emp`), big.mark = ","),
    format(round(row$`Mean Hires`), big.mark = ","),
    format(round(row$`Mean Separations`), big.mark = ","),
    row$`Mean Exposure`,
    row$Counties
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} County-level quarterly observations from QWI (2015Q1--2022Q4). Exposure is the share of county manufacturing employment in EU-targeted NAICS industries (312 Beverage/Tobacco, 331 Primary Metals, 336 Transportation Equipment) as of 2017Q4. High: $>5\\%$; Medium: 2--5\\%; Low: 0--2\\%; None: 0\\%.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
message("Saved Table 1: Summary Statistics")

# ===========================================================================
# Table 2: Main DiD Results
# ===========================================================================

# Build Table 2 manually for full control
add_stars <- function(b, s) {
  t <- abs(b / s)
  stars <- ifelse(t > 2.576, "$^{***}$",
           ifelse(t > 1.96, "$^{**}$",
           ifelse(t > 1.645, "$^{*}$", "")))
  return(stars)
}

mods <- list(results$static_emp, results$static_targeted,
             results$static_hira, results$static_sep)
betas <- sapply(mods, function(m) as.numeric(coef(m)))
ses <- sapply(mods, function(m) as.numeric(se(m)))
nobs_vals <- sapply(mods, function(m) m$nobs)
r2_vals <- sapply(mods, function(m) fitstat(m, "r2")[[1]])

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of EU Retaliatory Tariffs on County-Level Manufacturing Employment}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Total Mfg & Targeted & Total & Total \\\\",
  " & Emp & Emp & Hires & Separations \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Exposure $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          betas[1], add_stars(betas[1], ses[1]),
          betas[2], add_stars(betas[2], ses[2]),
          betas[3], add_stars(betas[3], ses[3]),
          betas[4], add_stars(betas[4], ses[4])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          ses[1], ses[2], ses[3], ses[4]),
  "\\midrule",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs_vals[1], big.mark = ","),
          format(nobs_vals[2], big.mark = ","),
          format(nobs_vals[3], big.mark = ","),
          format(nobs_vals[4], big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          r2_vals[1], r2_vals[2], r2_vals[3], r2_vals[4]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports a separate regression of log outcome on county EU-tariff exposure interacted with a post-June 2018 indicator. Exposure is the pre-tariff (2017Q4) share of county manufacturing employment in EU-targeted industries (NAICS 312, 331, 336). All specifications include county and year-quarter fixed effects. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
message("Saved Table 2: Main Results")

# ===========================================================================
# Table 3: Robustness Checks
# ===========================================================================

# Collect robustness coefficients
rob_rows <- data.table(
  Specification = character(),
  Beta = numeric(),
  SE = numeric(),
  Obs = integer()
)

# Main result for comparison
rob_rows <- rbind(rob_rows, data.table(
  Specification = "Baseline",
  Beta = diagnostics$beta_emp,
  SE = diagnostics$se_emp,
  Obs = diagnostics$n_obs
))

# Binary treatment
rob_rows <- rbind(rob_rows, data.table(
  Specification = "Binary treatment ($>5\\%$)",
  Beta = robustness$binary$beta,
  SE = robustness$binary$se,
  Obs = diagnostics$n_obs
))

# Placebo timing
rob_rows <- rbind(rob_rows, data.table(
  Specification = "Placebo timing (2017Q1)",
  Beta = robustness$placebo$beta,
  SE = robustness$placebo$se,
  Obs = as.integer(diagnostics$n_obs * (12/32))  # approximate pre-period obs
))

# Leave-one-out
for (ind in names(robustness$loo)) {
  ind_name <- switch(ind,
    "312" = "Beverages/Tobacco",
    "331" = "Primary Metals",
    "336" = "Transportation Equip."
  )
  rob_rows <- rbind(rob_rows, data.table(
    Specification = sprintf("Drop NAICS %s (%s)", ind, ind_name),
    Beta = robustness$loo[[ind]]$beta,
    SE = robustness$loo[[ind]]$se,
    Obs = diagnostics$n_obs
  ))
}

# Build LaTeX table
tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: Effect on Total Manufacturing Employment}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Coefficient & SE \\\\",
  "\\midrule"
)

for (i in 1:nrow(rob_rows)) {
  row <- rob_rows[i]
  stars <- ifelse(abs(row$Beta / row$SE) > 2.576, "$^{***}$",
           ifelse(abs(row$Beta / row$SE) > 1.96, "$^{**}$",
           ifelse(abs(row$Beta / row$SE) > 1.645, "$^{*}$", "")))
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %.4f%s & (%.4f) \\\\",
    row$Specification, row$Beta, stars, row$SE
  ))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log total manufacturing employment. All specifications include county and year-quarter fixed effects with state-clustered standard errors. Baseline is the continuous exposure DiD from Table~\\ref{tab:main}. Binary treatment defines high-exposure counties as those with $>5\\%$ of manufacturing employment in targeted industries. Placebo uses only pre-treatment data with a fake treatment date of 2017Q1. Leave-one-out drops each targeted NAICS code from the exposure measure. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
message("Saved Table 3: Robustness")

# ===========================================================================
# Table 4: Event Study Coefficients (selected periods)
# ===========================================================================

es_coefs <- coef(results$es_emp)
es_se_vals <- se(results$es_emp)
es_names <- names(es_coefs)

# Parse relative time from coefficient names
es_data <- data.table(
  name = es_names,
  coef = as.numeric(es_coefs),
  se = as.numeric(es_se_vals)
)

# Extract relative time
es_data[, rel_time := as.integer(gsub("rel_time::(-?[0-9]+):exposure_share", "\\1", name))]
setorder(es_data, rel_time)

# Select key periods
key_periods <- c(-12, -8, -4, -2, 0, 1, 2, 4, 8, 12, 16)
es_show <- es_data[rel_time %in% key_periods]

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study Coefficients: EU Tariff Exposure and Manufacturing Employment}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Quarter Relative to & Coefficient & SE \\\\",
  "Tariff (2018Q3) & & \\\\",
  "\\midrule",
  "\\textit{Pre-treatment} & & \\\\"
)

for (i in 1:nrow(es_show)) {
  row <- es_show[i]
  if (row$rel_time == 0) {
    tab4_lines <- c(tab4_lines, "\\midrule", "\\textit{Post-treatment} & & \\\\")
  }
  stars <- ifelse(abs(row$coef / row$se) > 2.576, "$^{***}$",
           ifelse(abs(row$coef / row$se) > 1.96, "$^{**}$",
           ifelse(abs(row$coef / row$se) > 1.645, "$^{*}$", "")))
  label <- ifelse(row$rel_time < 0, sprintf("$t%d$", row$rel_time), sprintf("$t+%d$", row$rel_time))
  tab4_lines <- c(tab4_lines, sprintf(
    "%s & %.4f%s & (%.4f) \\\\",
    label, row$coef, stars, row$se
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from a regression of log total manufacturing employment on interactions between county EU-tariff exposure and quarter indicators, with 2018Q2 ($t-1$) as the reference period. County and year-quarter fixed effects included. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")
message("Saved Table 4: Event Study Coefficients")

# ===========================================================================
# Table F1: SDE Appendix (MANDATORY)
# ===========================================================================

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_x <- diagnostics$sd_exposure

# Panel A: Pooled
sde_rows_a <- data.table(
  Outcome = c("Total Manufacturing Employment",
               "Targeted Industry Employment",
               "Total Hires",
               "Total Separations"),
  Beta = c(diagnostics$beta_emp, diagnostics$beta_targeted,
           diagnostics$beta_hira, diagnostics$beta_sep),
  SE_beta = c(diagnostics$se_emp, diagnostics$se_targeted,
              diagnostics$se_hira, diagnostics$se_sep),
  SD_Y = c(diagnostics$sd_log_emp, diagnostics$sd_log_emp_targeted,
           diagnostics$sd_log_hira, diagnostics$sd_log_sep)
)

sde_rows_a[, SDE := Beta * sd_x / SD_Y]
sde_rows_a[, SE_SDE := SE_beta * sd_x / SD_Y]
sde_rows_a[, Classification := fcase(
  SDE < -0.15, "Large negative",
  SDE < -0.05, "Moderate negative",
  SDE < -0.005, "Small negative",
  SDE <= 0.005, "Null",
  SDE <= 0.05, "Small positive",
  SDE <= 0.15, "Moderate positive",
  default = "Large positive"
)]

# Panel B: Heterogeneous (sample split: high vs medium exposure counties)
# Re-estimate for high-exposure and medium-exposure subsamples

panel_high <- panel[exposure_share > 0.05]
panel_med <- panel[exposure_share > 0.02 & exposure_share <= 0.05]

if (nrow(panel_high) > 100 && panel_high[, uniqueN(fips)] >= 10) {
  mod_high <- feols(log_emp ~ exposure_share:post | fips + yq_factor,
                    data = panel_high, cluster = ~state_fips)
  sd_y_high <- sd(panel_high[post == 0]$log_emp, na.rm = TRUE)
  sd_x_high <- sd(panel_high[post == 0, .(exposure_share = first(exposure_share)), by = fips]$exposure_share)
  sde_high <- as.numeric(coef(mod_high)) * sd_x_high / sd_y_high
  se_sde_high <- as.numeric(se(mod_high)) * sd_x_high / sd_y_high
} else {
  sde_high <- NA; se_sde_high <- NA
  mod_high <- NULL; sd_y_high <- NA; sd_x_high <- NA
}

if (nrow(panel_med) > 100 && panel_med[, uniqueN(fips)] >= 10) {
  mod_med <- feols(log_emp ~ exposure_share:post | fips + yq_factor,
                   data = panel_med, cluster = ~state_fips)
  sd_y_med <- sd(panel_med[post == 0]$log_emp, na.rm = TRUE)
  sd_x_med <- sd(panel_med[post == 0, .(exposure_share = first(exposure_share)), by = fips]$exposure_share)
  sde_med <- as.numeric(coef(mod_med)) * sd_x_med / sd_y_med
  se_sde_med <- as.numeric(se(mod_med)) * sd_x_med / sd_y_med
} else {
  sde_med <- NA; se_sde_med <- NA
  mod_med <- NULL; sd_y_med <- NA; sd_x_med <- NA
}

classify_sde <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does EU retaliatory tariff exposure (via county-level employment share in targeted manufacturing industries) reduce local manufacturing employment, hiring, and earnings? ",
  "\\textbf{Policy mechanism:} The EU imposed 25\\% ad valorem duties on approximately \\$2.8 billion of US exports (bourbon, motorcycles, steel, boats, peanut butter) in June 2018, selecting products for political salience in key congressional districts rather than economic efficiency. ",
  "\\textbf{Outcome definition:} Log quarterly county-level manufacturing employment, targeted-industry employment, total hires, and total separations from the Census QWI. ",
  "\\textbf{Treatment:} Continuous --- pre-tariff (2017Q4) share of county manufacturing employment in EU-targeted 3-digit NAICS industries (312, 331, 336). ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI/LEHD), 2015Q1--2022Q4, county $\\times$ quarter $\\times$ NAICS 3-digit panel. ",
  sprintf("Sample: %s county-quarter observations across %d counties. ",
          format(diagnostics$n_obs, big.mark = ","), diagnostics$n_counties),
  "\\textbf{Method:} Continuous difference-in-differences with county and year-quarter fixed effects; standard errors clustered at the state level (51 clusters). ",
  "\\textbf{Sample:} All US counties with positive manufacturing employment in every quarter of the sample period (balanced panel). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-county standard deviation of exposure and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build SDE table
tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: EU Retaliatory Tariffs}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)

for (i in 1:nrow(sde_rows_a)) {
  row <- sde_rows_a[i]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    row$Outcome, row$Beta, row$SE_beta, row$SD_Y,
    row$SDE, row$SE_SDE, row$Classification
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\textit{Panel B: Heterogeneous (Total Mfg Emp)} & & & & & & \\\\"
)

# High exposure
if (!is.na(sde_high)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "\\quad High exposure ($>5\\%%$) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    as.numeric(coef(mod_high)), as.numeric(se(mod_high)),
    sd_y_high, sde_high, se_sde_high, classify_sde(sde_high)
  ))
}

# Medium exposure
if (!is.na(sde_med)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "\\quad Medium exposure (2--5\\%%) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    as.numeric(coef(mod_med)), as.numeric(se(mod_med)),
    sd_y_med, sde_med, se_sde_med, classify_sde(sde_med)
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
message("Saved Table F1: SDE Appendix")

message("All tables generated successfully.")
