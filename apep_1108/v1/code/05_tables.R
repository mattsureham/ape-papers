## 05_tables.R
## The Housing Cost of Reshoring: CHIPS Act and Local Housing Markets
## Generate all tables including SDE appendix

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# Load results
panel_zhvi <- readRDS(file.path(data_dir, "panel_zhvi.rds"))
panel_zori <- readRDS(file.path(data_dir, "panel_zori.rds"))
overall_zhvi <- readRDS(file.path(data_dir, "overall_zhvi.rds"))
static_zhvi <- readRDS(file.path(data_dir, "static_zhvi.rds"))
dose_zhvi <- readRDS(file.path(data_dir, "dose_zhvi.rds"))
loo_results <- readRDS(file.path(data_dir, "loo_results.rds"))
placebo_results <- readRDS(file.path(data_dir, "placebo_results.rds"))

# Try loading optional results
overall_zori <- tryCatch(readRDS(file.path(data_dir, "overall_zori.rds")), error = function(e) NULL)
static_zori <- tryCatch(readRDS(file.path(data_dir, "static_zori.rds")), error = function(e) NULL)
overall_large <- tryCatch(readRDS(file.path(data_dir, "overall_large.rds")), error = function(e) NULL)
overall_small <- tryCatch(readRDS(file.path(data_dir, "overall_small.rds")), error = function(e) NULL)
overall_donut <- NULL  # Donut not compatible with C-S balanced panel

chips <- read_csv(file.path(data_dir, "chips_announcements.csv"),
                  col_types = cols(county_fips = col_character()))
acs <- read_csv(file.path(data_dir, "census_acs_2021.csv"),
                col_types = cols(county_fips = col_character()))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

baseline_date <- as.Date("2022-01-31")

# Get baseline characteristics (Zillow uses end-of-month dates)
baseline_zhvi <- panel_zhvi %>%
  filter(date == baseline_date) %>%
  group_by(county_fips) %>%
  slice(1) %>%
  ungroup()

# Fallback if exact date not found
if (nrow(baseline_zhvi) == 0) {
  baseline_zhvi <- panel_zhvi %>%
    filter(year(date) == 2022, month(date) == 1) %>%
    group_by(county_fips) %>%
    slice(1) %>%
    ungroup()
}

treated_stats <- baseline_zhvi %>% filter(treated)
control_stats <- baseline_zhvi %>% filter(!treated)

make_row <- function(var, label, fmt = "%.0f") {
  t_vals <- treated_stats[[var]]
  c_vals <- control_stats[[var]]
  # Filter NA and ACS sentinel values
  t_vals <- t_vals[!is.na(t_vals) & t_vals > -999999]
  c_vals <- c_vals[!is.na(c_vals) & c_vals > -999999]

  c(label,
    sprintf(fmt, mean(t_vals)),
    sprintf(fmt, sd(t_vals)),
    sprintf(fmt, mean(c_vals)),
    sprintf(fmt, sd(c_vals)),
    sprintf("%.2f", (mean(t_vals) - mean(c_vals)) / sqrt(sd(t_vals)^2/length(t_vals) + sd(c_vals)^2/length(c_vals))))
}

tab1_rows <- rbind(
  make_row("zhvi", "Home value index (\\$)", "%.0f"),
  make_row("population", "Population", "%.0f"),
  make_row("median_hh_income", "Median household income (\\$)", "%.0f"),
  make_row("housing_units", "Housing units", "%.0f"),
  make_row("median_home_value", "Median home value (\\$)", "%.0f"),
  make_row("median_gross_rent", "Median gross rent (\\$)", "%.0f")
)

n_treated <- nrow(treated_stats)
n_control <- nrow(control_stats)

# Write LaTeX
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: CHIPS Act Counties vs.\\ Control Counties}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{l cc cc c}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Treated (", n_treated, ")} & \\multicolumn{2}{c}{Control (", n_control, ")} & \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD & $t$-stat \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(tab1_rows)) {
  tab1_tex <- paste0(tab1_tex,
    tab1_rows[i, 1], " & ", tab1_rows[i, 2], " & ", tab1_rows[i, 3],
    " & ", tab1_rows[i, 4], " & ", tab1_rows[i, 5], " & ", tab1_rows[i, 6], " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}{\\footnotesize\n",
  "\\item \\textit{Notes:} Baseline characteristics as of January 2022 (pre-CHIPS). ",
  "Treated counties received at least one CHIPS Act semiconductor manufacturing award. ",
  "Home value index from Zillow ZHVI; demographic and housing variables from 2021 ACS 5-year estimates. ",
  "$t$-statistics test equality of means.\n",
  "}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

# Helper for stars
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# C-S ATT for ZHVI
cs_att <- overall_zhvi$overall.att
cs_se <- overall_zhvi$overall.se
cs_p <- 2 * pnorm(-abs(cs_att / cs_se))

# Static DiD ZHVI — coefficient name includes TRUE for logical variable
static_names <- names(coef(static_zhvi))
static_coef_name <- grep("TRUE.*post|post.*TRUE", static_names, value = TRUE)[1]
if (is.na(static_coef_name)) static_coef_name <- static_names[1]
static_coef <- coef(static_zhvi)[static_coef_name]
static_se_val <- se(static_zhvi)[static_coef_name]
static_p <- pvalue(static_zhvi)[static_coef_name]

# Dose response
dose_coef <- coef(dose_zhvi)[1]
dose_se_val <- se(dose_zhvi)[1]
dose_p <- pvalue(dose_zhvi)[1]

# ZORI results
zori_att <- if (!is.null(overall_zori)) overall_zori$overall.att else NA
zori_se <- if (!is.null(overall_zori)) overall_zori$overall.se else NA
zori_p <- if (!is.null(overall_zori)) 2 * pnorm(-abs(zori_att / zori_se)) else NA

if (!is.null(static_zori)) {
  zori_names <- names(coef(static_zori))
  zori_coef_name <- grep("TRUE.*post|post.*TRUE", zori_names, value = TRUE)[1]
  if (is.na(zori_coef_name)) zori_coef_name <- zori_names[1]
  static_zori_coef <- coef(static_zori)[zori_coef_name]
  static_zori_se <- se(static_zori)[zori_coef_name]
  static_zori_p <- pvalue(static_zori)[zori_coef_name]
} else {
  static_zori_coef <- NA
  static_zori_se <- NA
  static_zori_p <- NA
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of CHIPS Act Announcements on Local Housing Costs}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{l ccc cc}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{Home Values (log ZHVI)} & \\multicolumn{2}{c}{Rents (log ZORI)} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}\n",
  " & C-S ATT & Static DiD & Dose--Response & C-S ATT & Static DiD \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\midrule\n",
  "Treatment effect & ", sprintf("%.4f", cs_att), stars(cs_p),
  " & ", sprintf("%.4f", static_coef), stars(static_p),
  " & ", sprintf("%.6f", dose_coef), stars(dose_p),
  " & ", ifelse(is.na(zori_att), "---", paste0(sprintf("%.4f", zori_att), stars(zori_p))),
  " & ", ifelse(is.na(static_zori_coef), "---", paste0(sprintf("%.4f", static_zori_coef), stars(static_zori_p))),
  " \\\\\n",
  " & (", sprintf("%.4f", cs_se), ")",
  " & (", sprintf("%.4f", static_se_val), ")",
  " & (", sprintf("%.6f", dose_se_val), ")",
  " & ", ifelse(is.na(zori_se), "", paste0("(", sprintf("%.4f", zori_se), ")")),
  " & ", ifelse(is.na(static_zori_se), "", paste0("(", sprintf("%.4f", static_zori_se), ")")),
  " \\\\\n",
  "\\midrule\n",
  "Estimator & C-S & TWFE & TWFE & C-S & TWFE \\\\\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Clustering & County & County & County & County & County \\\\\n",
  "Treated counties & ", n_treated, " & ", n_treated, " & ", n_treated,
  " & ", ifelse(is.na(zori_att), "---", as.character(panel_zori %>% filter(treated) %>% pull(county_fips) %>% n_distinct())),
  " & ", ifelse(is.na(static_zori_coef), "---", as.character(panel_zori %>% filter(treated) %>% pull(county_fips) %>% n_distinct())),
  " \\\\\n",
  "Observations & ", format(nrow(panel_zhvi), big.mark = ","),
  " & ", format(nrow(panel_zhvi), big.mark = ","),
  " & ", format(nrow(panel_zhvi), big.mark = ","),
  " & ", ifelse(is.na(zori_att), "---", format(nrow(panel_zori), big.mark = ",")),
  " & ", ifelse(is.na(static_zori_coef), "---", format(nrow(panel_zori), big.mark = ",")),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}{\\footnotesize\n",
  "\\item \\textit{Notes:} Dependent variable is the natural log of Zillow Home Value Index (ZHVI, columns 1--3) ",
  "or Zillow Observed Rent Index (ZORI, columns 4--5). Treatment is the first CHIPS Act funding announcement in a county. ",
  "Column 1 reports the Callaway and Sant'Anna (2021) overall ATT. Column 2 reports a static TWFE DiD with county and ",
  "month fixed effects. Column 3 uses continuous dose (award dollars per housing unit) interacted with post. ",
  "Standard errors clustered at the county level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# ============================================================
# Table 3: Robustness
# ============================================================
cat("=== Table 3: Robustness ===\n")

rob_rows <- list()

# Baseline C-S
rob_rows[[1]] <- c("Baseline (C-S ATT)", sprintf("%.4f", cs_att),
                     sprintf("%.4f", cs_se), stars(cs_p), as.character(n_treated))

# Donut
if (!is.null(overall_donut)) {
  d_p <- 2 * pnorm(-abs(overall_donut$overall.att / overall_donut$overall.se))
  rob_rows[[length(rob_rows) + 1]] <- c(
    "Donut ($\\pm$2 months)",
    sprintf("%.4f", overall_donut$overall.att),
    sprintf("%.4f", overall_donut$overall.se),
    stars(d_p),
    as.character(n_treated))
}

# Large awards
if (!is.null(overall_large)) {
  l_p <- 2 * pnorm(-abs(overall_large$overall.att / overall_large$overall.se))
  rob_rows[[length(rob_rows) + 1]] <- c(
    "Large awards ($\\geq$ median)",
    sprintf("%.4f", overall_large$overall.att),
    sprintf("%.4f", overall_large$overall.se),
    stars(l_p),
    as.character(length(chips$county_fips[chips$total_award_billion >= median(chips$total_award_billion)])))
}

# Small awards
if (!is.null(overall_small)) {
  s_p <- 2 * pnorm(-abs(overall_small$overall.att / overall_small$overall.se))
  rob_rows[[length(rob_rows) + 1]] <- c(
    "Small awards ($<$ median)",
    sprintf("%.4f", overall_small$overall.att),
    sprintf("%.4f", overall_small$overall.se),
    stars(s_p),
    as.character(length(chips$county_fips[chips$total_award_billion < median(chips$total_award_billion)])))
}

# Placebo RI
rob_rows[[length(rob_rows) + 1]] <- c(
  "Placebo (RI $p$-value)",
  sprintf("%.4f", placebo_results$real_att),
  sprintf("%.4f", sd(placebo_results$placebo_atts)),
  "",
  paste0("$p_{RI}=", sprintf("%.3f", placebo_results$p_value_ri), "$"))

# LOO range
if (nrow(loo_results) > 0) {
  rob_rows[[length(rob_rows) + 1]] <- c(
    "Leave-one-out range",
    paste0("[", sprintf("%.4f", min(loo_results$att)), ", ",
           sprintf("%.4f", max(loo_results$att)), "]"),
    "", "", as.character(nrow(loo_results)))
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness of CHIPS Act Housing Price Effects}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{l ccc c}\n",
  "\\toprule\n",
  "Specification & ATT & SE & & Treated \\\\\n",
  "\\midrule\n"
)

for (row in rob_rows) {
  tab3_tex <- paste0(tab3_tex,
    row[1], " & ", row[2], row[4], " & ", row[3], " & & ", row[5], " \\\\\n")
}

tab3_tex <- paste0(tab3_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}{\\footnotesize\n",
  "\\item \\textit{Notes:} All specifications use log ZHVI as the dependent variable. ",
  "Baseline reports the Callaway and Sant'Anna (2021) overall ATT. ",
  "Donut excludes observations within $\\pm$2 months of announcement. ",
  "Large/small awards split at the median award amount. ",
  "Placebo randomly reassigns announcement dates 500 times; RI $p$-value is the share with $|\\text{ATT}| \\geq |\\text{real ATT}|$. ",
  "Leave-one-out reports the range of ATTs when dropping each treated county in turn. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_robustness.tex"))
cat("Table 3 written.\n")

# ============================================================
# Table 4: Leave-One-Out Detail
# ============================================================
cat("=== Table 4: Leave-One-Out ===\n")

if (nrow(loo_results) > 0) {
  tab4_tex <- paste0(
    "\\begin{table}[htbp]\n",
    "\\centering\n",
    "\\caption{Leave-One-Out Sensitivity: Dropping Each Treated County}\n",
    "\\label{tab:loo}\n",
    "\\begin{tabular}{ll cc}\n",
    "\\toprule\n",
    "Dropped County & Company & ATT & SE \\\\\n",
    "\\midrule\n",
    "None (baseline) & --- & ", sprintf("%.4f", cs_att), " & ", sprintf("%.4f", cs_se), " \\\\\n",
    "\\midrule\n"
  )

  for (i in 1:nrow(loo_results)) {
    loo_p <- 2 * pnorm(-abs(loo_results$att[i] / loo_results$se[i]))
    tab4_tex <- paste0(tab4_tex,
      loo_results$dropped_county[i], " & ",
      gsub("&", "\\\\&", loo_results$dropped_company[i]), " & ",
      sprintf("%.4f", loo_results$att[i]), stars(loo_p), " & ",
      sprintf("%.4f", loo_results$se[i]), " \\\\\n")
  }

  tab4_tex <- paste0(tab4_tex,
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\par\\vspace{0.3em}{\\footnotesize\n",
    "\\item \\textit{Notes:} Each row drops one treated county and re-estimates the Callaway and Sant'Anna (2021) overall ATT. ",
    "Standard errors clustered at the county level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
    "}\n",
    "\\end{table}\n"
  )

  writeLines(tab4_tex, file.path(table_dir, "tab4_loo.tex"))
  cat("Table 4 written.\n")
}

# ============================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# ============================================================
cat("=== Table F1: Standardized Effect Size ===\n")

# Compute SD(Y) from pre-treatment period
pre_zhvi <- panel_zhvi %>%
  filter(date < as.Date("2024-01-01"))  # Before earliest major announcement

sd_log_zhvi <- sd(pre_zhvi$log_zhvi, na.rm = TRUE)

# ZORI SD
if (!is.null(overall_zori)) {
  pre_zori <- panel_zori %>% filter(date < as.Date("2024-01-01"))
  sd_log_zori <- sd(pre_zori$log_zori, na.rm = TRUE)
}

# SDE = beta / SD(Y)
sde_zhvi <- cs_att / sd_log_zhvi
sde_zhvi_se <- cs_se / sd_log_zhvi

classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
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
sde_rows <- data.frame(
  outcome = character(),
  beta = numeric(),
  se = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  sde_se = numeric(),
  classification = character(),
  stringsAsFactors = FALSE
)

# Panel A: Pooled
sde_rows <- rbind(sde_rows, data.frame(
  outcome = "Home values (log ZHVI)",
  beta = cs_att,
  se = cs_se,
  sd_y = sd_log_zhvi,
  sde = sde_zhvi,
  sde_se = sde_zhvi_se,
  classification = classify_sde(sde_zhvi),
  stringsAsFactors = FALSE
))

if (!is.null(overall_zori)) {
  sde_zori <- zori_att / sd_log_zori
  sde_zori_se <- zori_se / sd_log_zori
  sde_rows <- rbind(sde_rows, data.frame(
    outcome = "Rents (log ZORI)",
    beta = zori_att,
    se = zori_se,
    sd_y = sd_log_zori,
    sde = sde_zori,
    sde_se = sde_zori_se,
    classification = classify_sde(sde_zori),
    stringsAsFactors = FALSE
  ))
}

# Panel B: Heterogeneous (sample splits)
if (!is.null(overall_large)) {
  sde_large <- overall_large$overall.att / sd_log_zhvi
  sde_large_se <- overall_large$overall.se / sd_log_zhvi
  sde_rows <- rbind(sde_rows, data.frame(
    outcome = "Home values: large awards",
    beta = overall_large$overall.att,
    se = overall_large$overall.se,
    sd_y = sd_log_zhvi,
    sde = sde_large,
    sde_se = sde_large_se,
    classification = classify_sde(sde_large),
    stringsAsFactors = FALSE
  ))
}

if (!is.null(overall_small)) {
  sde_small <- overall_small$overall.att / sd_log_zhvi
  sde_small_se <- overall_small$overall.se / sd_log_zhvi
  sde_rows <- rbind(sde_rows, data.frame(
    outcome = "Home values: small awards",
    beta = overall_small$overall.att,
    se = overall_small$overall.se,
    sd_y = sd_log_zhvi,
    sde = sde_small,
    sde_se = sde_small_se,
    classification = classify_sde(sde_small),
    stringsAsFactors = FALSE
  ))
}

# --- SDE notes string ---
n_obs_total <- nrow(panel_zhvi)
sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does federally subsidized semiconductor manufacturing investment under the CHIPS and Science Act ",
  "increase local housing costs in recipient counties? ",
  "\\textbf{Policy mechanism:} The CHIPS Act allocates \\$52.7 billion for semiconductor manufacturing, with individual awards ",
  "of \\$0.02--8.5 billion triggering fab construction that employs thousands of workers and generates sustained housing demand ",
  "in previously moderate-cost counties. ",
  "\\textbf{Outcome definition:} Natural log of Zillow Home Value Index (ZHVI), a smoothed, seasonally adjusted measure of ",
  "typical home values at the county-month level; and natural log of Zillow Observed Rent Index (ZORI) for rental prices. ",
  "\\textbf{Treatment:} Binary indicator for county receiving at least one CHIPS Act funding announcement. ",
  "\\textbf{Data:} Zillow ZHVI and ZORI county-level monthly data (2020--2026), CHIPS Act awards from Commerce Department, ",
  "Census ACS 2021 for controls; ", format(n_obs_total, big.mark = ","), " county-month observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with never-treated controls, standard errors clustered at county level. ",
  "\\textbf{Sample:} All US counties with Zillow coverage; treated group comprises counties receiving CHIPS Act semiconductor awards. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build LaTeX table
n_pooled <- sum(sde_rows$outcome %in% c("Home values (log ZHVI)", "Rents (log ZORI)"))

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{l cccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in 1:n_pooled) {
  tabF1_tex <- paste0(tabF1_tex,
    sde_rows$outcome[i], " & ",
    sprintf("%.4f", sde_rows$beta[i]), " & ",
    sprintf("%.4f", sde_rows$se[i]), " & ",
    sprintf("%.4f", sde_rows$sd_y[i]), " & ",
    sprintf("%.4f", sde_rows$sde[i]), " & ",
    sprintf("%.4f", sde_rows$sde_se[i]), " & ",
    sde_rows$classification[i], " \\\\\n")
}

if (nrow(sde_rows) > n_pooled) {
  tabF1_tex <- paste0(tabF1_tex,
    "\\midrule\n",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n")

  for (i in (n_pooled + 1):nrow(sde_rows)) {
    tabF1_tex <- paste0(tabF1_tex,
      sde_rows$outcome[i], " & ",
      sprintf("%.4f", sde_rows$beta[i]), " & ",
      sprintf("%.4f", sde_rows$se[i]), " & ",
      sprintf("%.4f", sde_rows$sd_y[i]), " & ",
      sprintf("%.4f", sde_rows$sde[i]), " & ",
      sprintf("%.4f", sde_rows$sde_se[i]), " & ",
      sde_rows$classification[i], " \\\\\n")
  }
}

tabF1_tex <- paste0(tabF1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}{\\footnotesize\n",
  sde_notes, "\n",
  "}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== ALL TABLES COMPLETE ===\n")
