## 05_tables.R — Generate all LaTeX tables
## apep_1090: The Compliance Trap

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel_balanced.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))
snap_annual <- read_csv(file.path(data_dir, "snap_annual_counts.csv"),
                        show_col_types = FALSE)

panel <- panel %>%
  mutate(
    cs_share_std = (cs_share - mean(cs_share, na.rm = TRUE)) / sd(cs_share, na.rm = TRUE),
    snap_rate_pct = snap_rate * 100,
    poverty_rate_pct = poverty_rate * 100
  )

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

pre <- panel %>% filter(year <= 2017)
post <- panel %>% filter(year >= 2019)

# Create summary by period
stats_pre <- pre %>%
  summarise(
    `SNAP participation rate (\\%)` = sprintf("%.2f (%.2f)", mean(snap_rate_pct, na.rm=T), sd(snap_rate_pct, na.rm=T)),
    `Poverty rate (\\%)` = sprintf("%.2f (%.2f)", mean(poverty_rate_pct, na.rm=T), sd(poverty_rate_pct, na.rm=T)),
    `Population` = sprintf("%.0f (%.0f)", mean(population, na.rm=T), sd(population, na.rm=T)),
    `Convenience store share` = sprintf("%.3f (%.3f)", mean(cs_share, na.rm=T), sd(cs_share, na.rm=T)),
    `Total households` = sprintf("%.0f (%.0f)", mean(total_hh, na.rm=T), sd(total_hh, na.rm=T)),
    `SNAP households` = sprintf("%.0f (%.0f)", mean(snap_hh, na.rm=T), sd(snap_hh, na.rm=T))
  ) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Pre-Period (2015--2017)")

stats_post <- post %>%
  summarise(
    `SNAP participation rate (\\%)` = sprintf("%.2f (%.2f)", mean(snap_rate_pct, na.rm=T), sd(snap_rate_pct, na.rm=T)),
    `Poverty rate (\\%)` = sprintf("%.2f (%.2f)", mean(poverty_rate_pct, na.rm=T), sd(poverty_rate_pct, na.rm=T)),
    `Population` = sprintf("%.0f (%.0f)", mean(population, na.rm=T), sd(population, na.rm=T)),
    `Convenience store share` = sprintf("%.3f (%.3f)", mean(cs_share, na.rm=T), sd(cs_share, na.rm=T)),
    `Total households` = sprintf("%.0f (%.0f)", mean(total_hh, na.rm=T), sd(total_hh, na.rm=T)),
    `SNAP households` = sprintf("%.0f (%.0f)", mean(snap_hh, na.rm=T), sd(snap_hh, na.rm=T))
  ) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Post-Period (2019--2022)")

stats_tab <- stats_pre %>%
  left_join(stats_post, by = "Variable")

# Write LaTeX
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Variable & Pre-Period (2015--2017) & Post-Period (2019--2022) \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(stats_tab))) {
  tab1_tex <- paste0(tab1_tex,
    stats_tab$Variable[i], " & ",
    stats_tab$`Pre-Period (2015--2017)`[i], " & ",
    stats_tab$`Post-Period (2019--2022)`[i], " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\midrule\n",
  "Counties & ", format(n_distinct(panel$fips), big.mark=","), " & ",
  format(n_distinct(panel$fips), big.mark=","), " \\\\\n",
  "County-years & ", format(nrow(pre), big.mark=","), " & ",
  format(nrow(post), big.mark=","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard deviations in parentheses. ",
  "The pre-period covers ACS 5-year estimates centered on 2015--2017 ",
  "(before the January 2018 depth-of-stock provision). ",
  "The post-period begins with the 2019 ACS vintage (2015--2019), the first ",
  "5-year window in which the majority of the reference period falls after the provision. ",
  "Convenience store share is computed from 2015--2016 County Business Patterns ",
  "(NAICS 445120 / (445120 + 445110)).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

# Rerun models to have them in session
m1 <- feols(snap_rate_pct ~ cs_share_std:post | fips + year,
            data = panel, cluster = ~ state_fips)
m2 <- feols(snap_rate_pct ~ cs_share_std:post + poverty_rate_pct | fips + year,
            data = panel, cluster = ~ state_fips)
m3 <- feols(snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
            data = panel, cluster = ~ state_fips)
m4 <- feols(snap_rate_pct ~ cs_share_std:post_2018 | fips + state_fips^year,
            data = panel, cluster = ~ state_fips)

# Placebo
placebo <- feols(poverty_rate_pct ~ cs_share_std:post | fips + state_fips^year,
                 data = panel, cluster = ~ state_fips)

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Convenience Store Exposure on SNAP Participation}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & SNAP Rate & SNAP Rate & SNAP Rate & SNAP Rate & Poverty \\\\\n",
  "\\midrule\n"
)

extract_row <- function(model, varname, label) {
  coefs <- coeftable(model)
  idx <- grep(varname, rownames(coefs), fixed = TRUE)
  if (length(idx) == 0) return(paste0(label, " & & & & & \\\\\n"))
  est <- coefs[idx, "Estimate"]
  se_val <- coefs[idx, "Std. Error"]
  pval <- coefs[idx, "Pr(>|t|)"]
  stars <- ifelse(pval < 0.01, "^{***}", ifelse(pval < 0.05, "^{**}",
           ifelse(pval < 0.1, "^{*}", "")))
  paste0(
    sprintf("%.3f%s", est, stars),
    " \\\\\n",
    sprintf(" & (%.3f)", se_val), " \\\\\n"
  )
}

# Build rows manually for each column
build_cell <- function(model, varname) {
  coefs <- coeftable(model)
  idx <- grep(varname, rownames(coefs), fixed = TRUE)
  if (length(idx) == 0) return(c("", ""))
  est <- coefs[idx, "Estimate"]
  se_val <- coefs[idx, "Std. Error"]
  pval <- coefs[idx, "Pr(>|t|)"]
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**",
           ifelse(pval < 0.1, "*", "")))
  c(sprintf("%.4f%s", est, stars), sprintf("(%.4f)", se_val))
}

c1 <- build_cell(m1, "cs_share_std:post")
c2 <- build_cell(m2, "cs_share_std:post")
c3 <- build_cell(m3, "cs_share_std:post")
c4 <- build_cell(m4, "cs_share_std:post_2018")
c5 <- build_cell(placebo, "cs_share_std:post")

tab2_tex <- paste0(tab2_tex,
  "CS Exposure $\\times$ Post & ", c1[1], " & ", c2[1], " & ", c3[1], " & & ", c5[1], " \\\\\n",
  " & ", c1[2], " & ", c2[2], " & ", c3[2], " & & ", c5[2], " \\\\\n",
  "CS Exposure $\\times$ Post$_{\\geq 2018}$ & & & & ", c4[1], " & \\\\\n",
  " & & & & ", c4[2], " & \\\\\n"
)

# Poverty control row
pov_cell <- build_cell(m2, "poverty_rate_pct")
tab2_tex <- paste0(tab2_tex,
  "Poverty rate (\\%) & & ", pov_cell[1], " & & & \\\\\n",
  " & & ", pov_cell[2], " & & & \\\\\n"
)

tab2_tex <- paste0(tab2_tex,
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & & & \\\\\n",
  "State $\\times$ Year FE & & & Yes & Yes & Yes \\\\\n",
  "\\midrule\n",
  "Observations & ", format(nobs(m1), big.mark=","), " & ",
  format(nobs(m2), big.mark=","), " & ",
  format(nobs(m3), big.mark=","), " & ",
  format(nobs(m4), big.mark=","), " & ",
  format(nobs(placebo), big.mark=","), " \\\\\n",
  "$R^2$ & ", sprintf("%.3f", fitstat(m1, "r2")[[1]]), " & ",
  sprintf("%.3f", fitstat(m2, "r2")[[1]]), " & ",
  sprintf("%.3f", fitstat(m3, "r2")[[1]]), " & ",
  sprintf("%.3f", fitstat(m4, "r2")[[1]]), " & ",
  sprintf("%.3f", fitstat(placebo, "r2")[[1]]), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ",
  "The dependent variable is the SNAP participation rate (\\%) in columns (1)--(4) ",
  "and the poverty rate (\\%) in column (5). ",
  "CS Exposure is the standardized pre-2018 convenience store share ",
  "(NAICS 445120 establishments / total food retail establishments from CBP). ",
  "Post = 1 for ACS vintage years $\\geq$ 2019. ",
  "Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Event Study
# ============================================================
cat("=== Table 3: Event Study ===\n")

es_model <- feols(
  snap_rate_pct ~ i(year, cs_share_std, ref = 2017) | fips + state_fips^year,
  data = panel, cluster = ~ state_fips
)

es_tab <- coeftable(es_model) %>%
  as.data.frame() %>%
  mutate(
    year = as.integer(gsub("year::|:cs_share_std", "", rownames(.))),
    stars = ifelse(`Pr(>|t|)` < 0.01, "***",
            ifelse(`Pr(>|t|)` < 0.05, "**",
            ifelse(`Pr(>|t|)` < 0.1, "*", "")))
  ) %>%
  arrange(year)

# Add reference year
es_tab <- bind_rows(
  es_tab %>% filter(year < 2017),
  data.frame(Estimate = 0, `Std. Error` = NA, `t value` = NA, `Pr(>|t|)` = NA,
             year = 2017, stars = "", check.names = FALSE),
  es_tab %>% filter(year > 2017)
)

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: CS Exposure $\\times$ Year Interactions}\n",
  "\\label{tab:event}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Year & Coefficient & Std. Error \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(es_tab))) {
  yr <- es_tab$year[i]
  if (yr == 2017) {
    tab3_tex <- paste0(tab3_tex,
      yr, " (ref.) & 0.000 & --- \\\\\n")
  } else {
    tab3_tex <- paste0(tab3_tex,
      yr, " & ", sprintf("%.4f%s", es_tab$Estimate[i], es_tab$stars[i]),
      " & ", sprintf("(%.4f)", es_tab$`Std. Error`[i]), " \\\\\n")
  }
}

tab3_tex <- paste0(tab3_tex,
  "\\midrule\n",
  "Pre-trend F-test $p$ & \\multicolumn{2}{c}{",
  sprintf("%.3f", wald(es_model, keep = "2015|2016")$p), "} \\\\\n",
  "County FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "State $\\times$ Year FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Observations & \\multicolumn{2}{c}{", format(nobs(es_model), big.mark=","), "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ",
  "Each coefficient represents the interaction of standardized CS Exposure ",
  "with a year indicator, relative to 2017 (the last pre-treatment year). ",
  "The dependent variable is the SNAP participation rate (\\%). ",
  "Standard errors clustered at the state level. ",
  "The pre-trend F-test jointly tests the 2015 and 2016 coefficients equal to zero. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_event.tex"))

# ============================================================
# Table 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

# Heterogeneity models
rural_m <- feols(snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel %>% mutate(rural = population < median(population[year==2017], na.rm=TRUE)) %>% filter(rural),
  cluster = ~ state_fips)

urban_m <- feols(snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel %>% mutate(urban = population >= median(population[year==2017], na.rm=TRUE)) %>% filter(urban),
  cluster = ~ state_fips)

high_pov <- feols(snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel %>% filter(poverty_rate > median(poverty_rate[year==2017], na.rm=TRUE)),
  cluster = ~ state_fips)

low_pov <- feols(snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel %>% filter(poverty_rate <= median(poverty_rate[year==2017], na.rm=TRUE)),
  cluster = ~ state_fips)

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness and Heterogeneity}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Rural & Urban & High Poverty & Low Poverty & Dose-Response \\\\\n",
  "\\midrule\n"
)

cr <- build_cell(rural_m, "cs_share_std:post")
cu <- build_cell(urban_m, "cs_share_std:post")
chp <- build_cell(high_pov, "cs_share_std:post")
clp <- build_cell(low_pov, "cs_share_std:post")

# Dose response
dose_m <- feols(snap_rate_pct ~ i(cs_tercile, post, ref = 1) | fips + state_fips^year,
  data = panel %>% mutate(cs_tercile = ntile(cs_share, 3)),
  cluster = ~ state_fips)
dose_coefs <- coeftable(dose_m)
d2 <- build_cell(dose_m, "cs_tercile::2:post")
d3 <- build_cell(dose_m, "cs_tercile::3:post")

tab4_tex <- paste0(tab4_tex,
  "CS Exposure $\\times$ Post & ", cr[1], " & ", cu[1], " & ", chp[1], " & ", clp[1], " & \\\\\n",
  " & ", cr[2], " & ", cu[2], " & ", chp[2], " & ", clp[2], " & \\\\\n",
  "Medium CS $\\times$ Post & & & & & ", d2[1], " \\\\\n",
  " & & & & & ", d2[2], " \\\\\n",
  "High CS $\\times$ Post & & & & & ", d3[1], " \\\\\n",
  " & & & & & ", d3[2], " \\\\\n",
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "State $\\times$ Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "\\midrule\n",
  "RI $p$-value & \\multicolumn{5}{c}{", sprintf("%.3f", robustness$ri_pvalue), "} \\\\\n",
  "LOSO range & \\multicolumn{5}{c}{[",
  sprintf("%.4f", min(robustness$loso_coefs)), ", ",
  sprintf("%.4f", max(robustness$loso_coefs)), "]} \\\\\n",
  "\\midrule\n",
  "Observations & ", format(nobs(rural_m), big.mark=","), " & ",
  format(nobs(urban_m), big.mark=","), " & ",
  format(nobs(high_pov), big.mark=","), " & ",
  format(nobs(low_pov), big.mark=","), " & ",
  format(nobs(dose_m), big.mark=","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ",
  "Columns (1)--(2) split the sample by median county population (2017). ",
  "Columns (3)--(4) split by median poverty rate (2017). ",
  "Column (5) replaces the continuous CS Exposure with tercile indicators ",
  "(Low CS share is the omitted category). ",
  "RI $p$-value is from 500 permutations of the treatment assignment. ",
  "LOSO shows the range of the main coefficient when each state is excluded. ",
  "All specifications include county and state $\\times$ year fixed effects. ",
  "Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_robustness.tex"))

# ============================================================
# Table 5: SNAP Retailer Aggregate Time Series
# ============================================================
cat("=== Table 5: Aggregate SNAP Retailers ===\n")

tab5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{SNAP-Authorized Retailers by Fiscal Year}\n",
  "\\label{tab:aggregate}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Fiscal Year & Total Authorized & Small-Format Share & Small-Format Count \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(snap_annual))) {
  r <- snap_annual[i, ]
  marker <- if (r$fiscal_year == 2018) " $\\dagger$" else ""
  tab5_tex <- paste0(tab5_tex,
    r$fiscal_year, marker, " & ",
    format(r$total_authorized, big.mark=","), " & ",
    sprintf("%.1f\\%%", r$small_format_share * 100), " & ",
    format(r$small_format_count, big.mark=","), " \\\\\n")
}

tab5_tex <- paste0(tab5_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ",
  "Data from USDA FNS SNAP Annual Summary Reports. ",
  "$\\dagger$ marks FY2018, when the depth-of-stock provision took effect ",
  "(January 17, 2018). Small-format stores include convenience stores, ",
  "small grocery stores, specialty stores, and direct marketing retailers.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, file.path(tables_dir, "tab5_aggregate.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

pre_sd <- panel %>%
  filter(year <= 2017) %>%
  pull(snap_rate_pct) %>%
  sd(na.rm = TRUE)

# Main spec (m3) coefficient and SE
main_coef <- coef(m3)[["cs_share_std:post"]]
main_se <- se(m3)[["cs_share_std:post"]]

# High-poverty subsample
hp_coef <- coef(high_pov)[["cs_share_std:post"]]
hp_se <- se(high_pov)[["cs_share_std:post"]]

pre_sd_hp <- panel %>%
  filter(year <= 2017, poverty_rate > median(poverty_rate[year==2017], na.rm=TRUE)) %>%
  pull(snap_rate_pct) %>%
  sd(na.rm = TRUE)

# Low-poverty subsample
lp_coef <- coef(low_pov)[["cs_share_std:post"]]
lp_se <- se(low_pov)[["cs_share_std:post"]]

pre_sd_lp <- panel %>%
  filter(year <= 2017, poverty_rate <= median(poverty_rate[year==2017], na.rm=TRUE)) %>%
  pull(snap_rate_pct) %>%
  sd(na.rm = TRUE)

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows <- data.frame(
  panel = c("A", "A", "B", "B"),
  outcome = c(
    "SNAP participation rate",
    "Poverty rate (placebo)",
    "SNAP rate (high-poverty counties)",
    "SNAP rate (low-poverty counties)"
  ),
  beta = c(main_coef, coef(placebo)[[1]], hp_coef, lp_coef),
  se_beta = c(main_se, se(placebo)[[1]], hp_se, lp_se),
  sd_y = c(pre_sd, sd(panel$poverty_rate_pct[panel$year<=2017], na.rm=T), pre_sd_hp, pre_sd_lp),
  stringsAsFactors = FALSE
)

sde_rows$sde <- sde_rows$beta / sde_rows$sd_y
sde_rows$se_sde <- sde_rows$se_beta / sde_rows$sd_y
sde_rows$classification <- sapply(sde_rows$sde, classify_sde)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does tripling SNAP retailer minimum stocking requirements reduce food stamp participation in counties where small-format retailers dominate the food retail landscape? ",
  "\\textbf{Policy mechanism:} The January 2018 USDA depth-of-stock provision raised the minimum number of staple food items that SNAP-authorized retailers must stock from 12 to 36, creating a binding compliance burden on convenience stores and small groceries that lack shelf space and supply chain capacity to meet the new threshold. ",
  "\\textbf{Outcome definition:} SNAP participation rate, defined as the share of households receiving food stamps/SNAP benefits from ACS table B22003, measured at the county level. ",
  "\\textbf{Treatment:} Continuous; pre-2018 county-level convenience store share of total food retail establishments (standardized, mean zero, unit standard deviation). ",
  "\\textbf{Data:} ACS 5-year estimates (2015--2022 vintages) for 3,163 U.S. counties; County Business Patterns (2015--2016 average) for treatment intensity; 25,304 county-year observations in the balanced panel. ",
  "\\textbf{Method:} Two-way fixed effects (county + state-by-year), standard errors clustered at state level, with randomization inference (500 permutations). ",
  "\\textbf{Sample:} Counties with nonmissing CBP food retail data and population above 100; balanced panel requires all 8 ACS vintages (2015--2022). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in which(sde_rows$panel == "A")) {
  tabF1_tex <- paste0(tabF1_tex,
    sde_rows$outcome[i], " & ",
    sprintf("%.4f", sde_rows$beta[i]), " & ",
    sprintf("%.4f", sde_rows$se_beta[i]), " & ",
    sprintf("%.2f", sde_rows$sd_y[i]), " & ",
    sprintf("%.4f", sde_rows$sde[i]), " & ",
    sprintf("%.4f", sde_rows$se_sde[i]), " & ",
    sde_rows$classification[i], " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n"
)

for (i in which(sde_rows$panel == "B")) {
  tabF1_tex <- paste0(tabF1_tex,
    sde_rows$outcome[i], " & ",
    sprintf("%.4f", sde_rows$beta[i]), " & ",
    sprintf("%.4f", sde_rows$se_beta[i]), " & ",
    sprintf("%.2f", sde_rows$sd_y[i]), " & ",
    sprintf("%.4f", sde_rows$sde[i]), " & ",
    sprintf("%.4f", sde_rows$se_sde[i]), " & ",
    sde_rows$classification[i], " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
cat(list.files(tables_dir), sep = "\n")
