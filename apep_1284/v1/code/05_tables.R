# 05_tables.R — Generate all tables
# APEP-1284: BLM Lottery Leases and Western County Economies

source("00_packages.R")

DATA_DIR <- "../data"
TAB_DIR <- "../tables"
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

load(file.path(DATA_DIR, "models.RData"))
load(file.path(DATA_DIR, "robustness_models.RData"))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Cross-sectional county-level stats
cs <- county_leases[lottery_acres > 0 | noncomp_acres > 0]

# Panel stats
panel_1969 <- analysis[year == 1969 & is.finite(log_pc_income)]
panel_2020 <- analysis[year == 2020 & is.finite(log_pc_income)]

sumstat <- data.table(
  Variable = c("Lottery share (pre-FOOGLRA)", "Lottery acres (000s)", "Total federal O\\&G acres (000s)",
               "Number of townships", "Per capita income, 1969 (\\$)",
               "Population, 1969", "Per capita income, 2020 (\\$)", "Population, 2020"),
  Mean = c(
    sprintf("%.3f", mean(cs$lottery_share)),
    sprintf("%.1f", mean(cs$lottery_acres) / 1000),
    sprintf("%.1f", mean(cs$total_all_acres) / 1000),
    sprintf("%.1f", mean(cs$n_townships)),
    sprintf("%s", format(round(mean(panel_1969$pc_income, na.rm = TRUE)), big.mark = ",")),
    sprintf("%s", format(round(mean(panel_1969$population, na.rm = TRUE)), big.mark = ",")),
    sprintf("%s", format(round(mean(panel_2020$pc_income, na.rm = TRUE)), big.mark = ",")),
    sprintf("%s", format(round(mean(panel_2020$population, na.rm = TRUE)), big.mark = ","))
  ),
  SD = c(
    sprintf("%.3f", sd(cs$lottery_share)),
    sprintf("%.1f", sd(cs$lottery_acres) / 1000),
    sprintf("%.1f", sd(cs$total_all_acres) / 1000),
    sprintf("%.1f", sd(cs$n_townships)),
    sprintf("%s", format(round(sd(panel_1969$pc_income, na.rm = TRUE)), big.mark = ",")),
    sprintf("%s", format(round(sd(panel_1969$population, na.rm = TRUE)), big.mark = ",")),
    sprintf("%s", format(round(sd(panel_2020$pc_income, na.rm = TRUE)), big.mark = ",")),
    sprintf("%s", format(round(sd(panel_2020$population, na.rm = TRUE)), big.mark = ","))
  ),
  N = c(rep(nrow(cs), 4), rep(nrow(panel_1969), 2), rep(nrow(panel_2020), 2))
)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & $N$ \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: County lease allocation}} \\\\\n",
  paste(sprintf("%s & %s & %s & %s \\\\", sumstat$Variable[1:4], sumstat$Mean[1:4], sumstat$SD[1:4], sumstat$N[1:4]), collapse = "\n"),
  "\n\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: County economic outcomes}} \\\\\n",
  paste(sprintf("%s & %s & %s & %s \\\\", sumstat$Variable[5:8], sumstat$Mean[5:8], sumstat$SD[5:8], sumstat$N[5:8]), collapse = "\n"),
  "\n\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\vspace{0.5em}\\begin{flushleft}\\small\n",
  "\\item \\textit{Notes:} Panel A reports cross-sectional statistics for 666 Western US counties with federal oil and gas lease activity. ",
  "Lottery share is the fraction of pre-FOOGLRA (1987) federal acreage allocated via BLM simultaneous filing lottery. ",
  "Panel B reports county-level economic outcomes from BEA Regional Economic Accounts.\n",
  "\\end{flushleft}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(TAB_DIR, "tab1_sumstats.tex"))

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

# Get coefficients and standard errors
extract_coef <- function(model, varname_pattern) {
  cf <- coef(model)
  se_vals <- fixest::se(model)
  pv <- fixest::pvalue(model)
  idx <- grep(varname_pattern, names(cf))
  if (length(idx) == 0) return(list(coef = NA, se = NA, p = NA))
  list(coef = cf[idx[1]], se = se_vals[idx[1]], p = pv[idx[1]])
}

# Models for Table 2:
# (1) Income, baseline   (2) Income, acreage ctrl   (3) Income, state trends
# (4) Pop, baseline      (5) Pop, acreage ctrl
r1 <- extract_coef(m1_income, "lottery_share")
r2 <- extract_coef(m4_income, "lottery_share")
r3 <- extract_coef(m5_income, "lottery_share")
r4 <- extract_coef(m1_pop, "lottery_share")
r5 <- extract_coef(m4_pop, "lottery_share")

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  return("")
}

fmt_coef <- function(r) sprintf("%.4f%s", r$coef, stars(r$p))
fmt_se <- function(r) sprintf("(%.4f)", r$se)

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{The Effect of Lottery Allocation on County Economic Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Log Per Capita Income} & \\multicolumn{2}{c}{Log Population} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\hline\n",
  sprintf("Lottery Share $\\times$ Post & %s & %s & %s & %s & %s \\\\\n", fmt_coef(r1), fmt_coef(r2), fmt_coef(r3), fmt_coef(r4), fmt_coef(r5)),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n", fmt_se(r1), fmt_se(r2), fmt_se(r3), fmt_se(r4), fmt_se(r5)),
  "\\addlinespace\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Total acreage $\\times$ Post & & Yes & & & Yes \\\\\n",
  "State $\\times$ Year trends & & & Yes & & \\\\\n",
  "\\addlinespace\n",
  sprintf("Counties & %d & %d & %d & %d & %d \\\\\n", 666, 666, 666, 666, 666),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(nobs(m1_income), big.mark = ","),
          format(nobs(m4_income), big.mark = ","),
          format(nobs(m5_income), big.mark = ","),
          format(nobs(m1_pop), big.mark = ","),
          format(nobs(m4_pop), big.mark = ",")),
  sprintf("$R^2$ (within) & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n",
          fitstat(m1_income, "wr2")[[1]], fitstat(m4_income, "wr2")[[1]],
          fitstat(m5_income, "wr2")[[1]], fitstat(m1_pop, "wr2")[[1]], fitstat(m4_pop, "wr2")[[1]]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\vspace{0.5em}\\begin{flushleft}\\small\n",
  "\\item \\textit{Notes:} Each column reports an OLS regression with county and year fixed effects. ",
  "The treatment variable is the county's lottery share --- the fraction of pre-FOOGLRA federal oil and gas acreage ",
  "allocated via BLM simultaneous filing lottery --- interacted with a post-1990 indicator. ",
  "Standard errors clustered at the state level (13 states) in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{flushleft}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(TAB_DIR, "tab2_main.tex"))

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================
cat("=== Table 3: Event Study ===\n")

es_income <- coef(m2_income_es)
es_se <- fixest::se(m2_income_es)
es_p <- fixest::pvalue(m2_income_es)
es_pop <- coef(m2_pop_es)
es_pop_se <- fixest::se(m2_pop_es)
es_pop_p <- fixest::pvalue(m2_pop_es)

years_es <- c(1969, 1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015)
inc_names <- paste0("lottery_share:year_fac", years_es)
pop_names <- paste0("lottery_share:year_fac", years_es)

tab3_rows <- ""
for (i in seq_along(years_es)) {
  yr <- years_es[i]
  # Income
  ic <- if (inc_names[i] %in% names(es_income)) es_income[inc_names[i]] else NA
  is_val <- if (inc_names[i] %in% names(es_se)) es_se[inc_names[i]] else NA
  ip <- if (inc_names[i] %in% names(es_p)) es_p[inc_names[i]] else NA
  # Population
  pc <- if (pop_names[i] %in% names(es_pop)) es_pop[pop_names[i]] else NA
  ps <- if (pop_names[i] %in% names(es_pop_se)) es_pop_se[pop_names[i]] else NA
  pp <- if (pop_names[i] %in% names(es_pop_p)) es_pop_p[pop_names[i]] else NA

  ic_str <- if (!is.na(ic)) sprintf("%.4f%s", ic, stars(ip)) else "---"
  is_str <- if (!is.na(is_val)) sprintf("(%.4f)", is_val) else ""
  pc_str <- if (!is.na(pc)) sprintf("%.4f%s", pc, stars(pp)) else "---"
  ps_str <- if (!is.na(ps)) sprintf("(%.4f)", ps) else ""

  tab3_rows <- paste0(tab3_rows, sprintf("%d & %s & %s \\\\\n", yr, ic_str, pc_str))
  tab3_rows <- paste0(tab3_rows, sprintf(" & %s & %s \\\\\n", is_str, ps_str))
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Lottery Share $\\times$ Year Interactions}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Log Per Capita Income & Log Population \\\\\n",
  "\\hline\n",
  tab3_rows,
  "\\addlinespace\n",
  "Omitted year & 2020 & 2020 \\\\\n",
  "County, Year FE & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s \\\\\n",
          format(nobs(m2_income_es), big.mark = ","),
          format(nobs(m2_pop_es), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\vspace{0.5em}\\begin{flushleft}\\small\n",
  "\\item \\textit{Notes:} Each cell reports the coefficient on Lottery Share $\\times$ Year for the indicated year. ",
  "The omitted category is 2020. Pre-lottery-era years (1969--1990) test the parallel trends assumption. ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{flushleft}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(TAB_DIR, "tab3_eventstudy.tex"))

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

r_county <- extract_coef(m_r1, "lottery_share")
r_twoway <- extract_coef(m_r2, "lottery_share")
r_altmeas <- extract_coef(m_r4, "lottery_share_all")
r_binary <- extract_coef(m3_income, "high_lottery")

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Log Per Capita Income}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & County & Two-way & All leases & Binary \\\\\n",
  " & cluster & cluster & measure & treatment \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("Treatment $\\times$ Post & %s & %s & %s & %s \\\\\n",
          fmt_coef(r_county), fmt_coef(r_twoway), fmt_coef(r_altmeas), fmt_coef(r_binary)),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          fmt_se(r_county), fmt_se(r_twoway), fmt_se(r_altmeas), fmt_se(r_binary)),
  "\\addlinespace\n",
  "Treatment variable & Lottery share & Lottery share & Lottery share (all) & High lottery \\\\\n",
  "Clustering & County & State + County & State & State \\\\\n",
  "County, Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(m_r1), big.mark = ","), format(nobs(m_r2), big.mark = ","),
          format(nobs(m_r4), big.mark = ","), format(nobs(m3_income), big.mark = ",")),
  "\\addlinespace\n",
  sprintf("LOO range & \\multicolumn{4}{c}{[%.4f, %.4f]} \\\\\n",
          min(loo_results$coef), max(loo_results$coef)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\vspace{0.5em}\\begin{flushleft}\\small\n",
  "\\item \\textit{Notes:} Each column reports a variant of the baseline specification (Table~\\ref{tab:main}, column 1). ",
  "Column (1) clusters at the county level. Column (2) uses two-way clustering (state and county). ",
  "Column (3) defines lottery share relative to all federal leases (including post-FOOGLRA competitive). ",
  "Column (4) uses a binary indicator for above-median lottery share. ",
  "LOO range reports the coefficient range from leave-one-state-out analysis. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{flushleft}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(TAB_DIR, "tab4_robustness.tex"))

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDEs
# For continuous treatment: SDE = beta * SD(X) / SD(Y)
sd_lottery <- sd(county_leases$lottery_share)
sd_y_income <- sd(analysis[year <= 1990 & is.finite(log_pc_income)]$log_pc_income, na.rm = TRUE)
sd_y_pop <- sd(analysis[year <= 1990 & is.finite(log_pop)]$log_pop, na.rm = TRUE)

# Main income effect
b_income <- coef(m1_income)["lottery_share:post_era"]
se_income <- se(m1_income)["lottery_share:post_era"]
sde_income <- b_income * sd_lottery / sd_y_income
se_sde_income <- se_income * sd_lottery / sd_y_income

# Main population effect
b_pop <- coef(m1_pop)["lottery_share:post_era"]
se_pop <- se(m1_pop)["lottery_share:post_era"]
sde_pop <- b_pop * sd_lottery / sd_y_pop
se_sde_pop <- se_pop * sd_lottery / sd_y_pop

# With acreage control
b_income_ctrl <- coef(m4_income)["lottery_share:post_era"]
se_income_ctrl <- se(m4_income)["lottery_share:post_era"]
sde_income_ctrl <- b_income_ctrl * sd_lottery / sd_y_income
se_sde_income_ctrl <- se_income_ctrl * sd_lottery / sd_y_income

# State trends
b_income_st <- coef(m5_income)["lottery_share:post_era"]
se_income_st <- se(m5_income)["lottery_share:post_era"]
sde_income_st <- b_income_st * sd_lottery / sd_y_income
se_sde_income_st <- se_income_st * sd_lottery / sd_y_income

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

# Panel A: Pooled
sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the mechanism of federal oil and gas lease allocation --- random lottery versus first-come-first-served --- affect long-run county economic outcomes in the Western United States? ",
  "\\textbf{Policy mechanism:} The Bureau of Land Management's simultaneous filing procedure (1960s--1990s) resolved competing noncompetitive lease applications by random drawing; lottery winners were disproportionately speculators who delayed drilling relative to non-lottery lessees who developed immediately. ",
  "\\textbf{Outcome definition:} Log per capita personal income from BEA Regional Economic Accounts; log population from BEA. ",
  "\\textbf{Treatment:} Continuous --- county-level share of pre-FOOGLRA federal oil and gas acreage allocated via lottery (mean 0.38, SD 0.29). ",
  "\\textbf{Data:} BLM Mineral and Land Records System (118,138 lottery leases across 13 Western states) merged with BEA REIS county-year panel, 1969--2020, 666 counties, 7,323 observations. ",
  "\\textbf{Method:} OLS with county and year fixed effects; treatment is county lottery share interacted with post-1990 indicator; standard errors clustered at state level (13 states). ",
  "\\textbf{Sample:} Western US counties (AZ, CA, CO, ID, MT, ND, NE, NM, NV, OR, SD, UT, WY) with any federal oil and gas lease activity during 1960--1995. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-county standard deviation of lottery share and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Per capita income & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          b_income, se_income, sd_y_income, sde_income, se_sde_income, classify_sde(sde_income)),
  sprintf("Population & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          b_pop, se_pop, sd_y_pop, sde_pop, se_sde_pop, classify_sde(sde_pop)),
  sprintf("Income (acreage ctrl) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          b_income_ctrl, se_income_ctrl, sd_y_income, sde_income_ctrl, se_sde_income_ctrl, classify_sde(sde_income_ctrl)),
  sprintf("Income (state trends) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          b_income_st, se_income_st, sd_y_income, sde_income_st, se_sde_income_st, classify_sde(sde_income_st)),
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous --- by resource endowment}} \\\\\n"
)

# Heterogeneity: split by total federal acreage (above/below median)
med_acres <- median(county_leases$total_all_acres, na.rm = TRUE)
analysis[, high_acres := total_all_acres > med_acres]

m_hi_acres <- feols(log_pc_income ~ lottery_share:post_era | fips + year,
                    data = analysis[high_acres == TRUE & is.finite(log_pc_income)],
                    cluster = ~state)
m_lo_acres <- feols(log_pc_income ~ lottery_share:post_era | fips + year,
                    data = analysis[high_acres == FALSE & is.finite(log_pc_income)],
                    cluster = ~state)

b_hi <- coef(m_hi_acres)["lottery_share:post_era"]
se_hi <- se(m_hi_acres)["lottery_share:post_era"]
sd_y_hi <- sd(analysis[high_acres == TRUE & year <= 1990 & is.finite(log_pc_income)]$log_pc_income)
sde_hi <- b_hi * sd_lottery / sd_y_hi
se_sde_hi <- se_hi * sd_lottery / sd_y_hi

b_lo <- coef(m_lo_acres)["lottery_share:post_era"]
se_lo <- se(m_lo_acres)["lottery_share:post_era"]
sd_y_lo <- sd(analysis[high_acres == FALSE & year <= 1990 & is.finite(log_pc_income)]$log_pc_income)
sde_lo <- b_lo * sd_lottery / sd_y_lo
se_sde_lo <- se_lo * sd_lottery / sd_y_lo

tabF1_tex <- paste0(tabF1_tex,
  sprintf("High-acreage counties & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          b_hi, se_hi, sd_y_hi, sde_hi, se_sde_hi, classify_sde(sde_hi)),
  sprintf("Low-acreage counties & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          b_lo, se_lo, sd_y_lo, sde_lo, se_sde_lo, classify_sde(sde_lo)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\vspace{0.5em}\\begin{flushleft}\\small\n",
  sde_notes, "\n",
  "\\end{flushleft}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, file.path(TAB_DIR, "tabF1_sde.tex"))

cat("=== All tables generated ===\n")
cat(sprintf("Tables saved in %s/\n", TAB_DIR))
