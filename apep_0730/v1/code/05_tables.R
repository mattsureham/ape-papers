# 05_tables.R — Generate all tables including SDE appendix
# apep_0730: Time Zone Boundaries and Teen Morning Traffic Deaths

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

cat("=== Loading results ===\n")
results <- readRDS("main_results.rds")
robustness <- readRDS("robustness_results.rds")
df <- fread("fars_cleaned.csv")
diagnostics <- fromJSON("diagnostics.json")

tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

bandwidth_deg <- 1.5
rdd_df <- df[abs(dist_to_boundary) <= bandwidth_deg]

# Split by late_sunset
make_stats <- function(dt, label) {
  data.table(
    Group = label,
    `N Crashes` = format(nrow(dt), big.mark = ","),
    `Morning (%)` = sprintf("%.1f", 100 * mean(dt$morning)),
    `Evening (%)` = sprintf("%.1f", 100 * mean(dt$evening)),
    `Teen Fatal (%)` = sprintf("%.1f", 100 * mean(dt$teen_fatal)),
    `Weekend (%)` = sprintf("%.1f", 100 * mean(dt$weekend)),
    `Dark (%)` = sprintf("%.1f", 100 * mean(dt$dark, na.rm = TRUE))
  )
}

stats_late <- make_stats(rdd_df[late_sunset == 1], "Late-sunset (West)")
stats_early <- make_stats(rdd_df[late_sunset == 0], "Early-sunset (East)")
stats_all <- make_stats(rdd_df, "Full sample")

sumstats <- rbind(stats_late, stats_early, stats_all)

# LaTeX output
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Fatal Crashes Near Time Zone Boundaries}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & N Crashes & Morning & Evening & Teen Fatal & Weekend & Dark \\\\\n",
  " & & (\\%) & (\\%) & (\\%) & (\\%) & (\\%) \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sumstats)) {
  tab1_tex <- paste0(tab1_tex,
    sumstats$Group[i], " & ",
    sumstats$`N Crashes`[i], " & ",
    sumstats$`Morning (%)`[i], " & ",
    sumstats$`Evening (%)`[i], " & ",
    sumstats$`Teen Fatal (%)`[i], " & ",
    sumstats$`Weekend (%)`[i], " & ",
    sumstats$`Dark (%)`[i], " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Sample includes all fatal crashes in FARS (2010--2023) within ",
  sprintf("%.0f km ($\\pm$%.1f$^\\circ$ longitude) ", bandwidth_deg * 85, bandwidth_deg),
  "of the three continental US time zone boundaries (Eastern/Central, Central/Mountain, Mountain/Pacific). ",
  "Morning = 6:00--9:59 AM; Evening = 3:00--7:59 PM. ",
  "Teen fatal = crash involving at least one fatality aged 15--19.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_sumstats.tex"))
cat("Table 1 saved.\n")

# ============================================================
# TABLE 2: Main RDD Results
# ============================================================
cat("=== Table 2: Main RDD Results ===\n")

# Extract results from rdrobust objects
extract_rd <- function(rd, label) {
  data.table(
    Specification = label,
    Coefficient = sprintf("%.4f", rd$coef[1]),
    SE = sprintf("(%.4f)", rd$se[3]),
    p_value = sprintf("%.3f", rd$pv[3]),
    BW_opt = sprintf("%.2f", rd$bws[1, 1]),
    N_eff = sprintf("%d", round(rd$N_h[1] + rd$N_h[2]))
  )
}

rd_rows <- list()
rd_rows[[1]] <- extract_rd(results$rdd_county_morning, "Morning fatality rate")
rd_rows[[2]] <- extract_rd(results$rdd_county_evening, "Evening fatality rate (placebo)")

# Add parametric specs
spec1 <- results$spec1
s1_coef <- coef(spec1)["late_sunset"]
s1_se <- sqrt(vcov(spec1)["late_sunset", "late_sunset"])
s1_pval <- coeftable(spec1)["late_sunset", "Pr(>|t|)"]

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Main Results: RDD Estimates at Time Zone Boundaries}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Nonparametric RDD} & & \\multicolumn{2}{c}{Parametric} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){5-6}\n",
  " & (1) & (2) & & (3) & (4) \\\\\n",
  " & Morning & Evening & & Linear & Quadratic \\\\\n",
  "\\midrule\n",
  "Late-sunset & ", sprintf("%.4f", results$rdd_county_morning$coef[1]),
  " & ", sprintf("%.4f", results$rdd_county_evening$coef[1]),
  " & & ", sprintf("%.4f", s1_coef),
  " & ", sprintf("%.4f", coef(results$spec2)["late_sunset"]),
  " \\\\\n",
  " & ", sprintf("(%.4f)", results$rdd_county_morning$se[3]),
  " & ", sprintf("(%.4f)", results$rdd_county_evening$se[3]),
  " & & ", sprintf("(%.4f)", s1_se),
  " & ", sprintf("(%.4f)", sqrt(vcov(results$spec2)["late_sunset", "late_sunset"])),
  " \\\\\n",
  "\\addlinespace\n",
  "Optimal BW ($^\\circ$) & ", sprintf("%.2f", results$rdd_county_morning$bws[1, 1]),
  " & ", sprintf("%.2f", results$rdd_county_evening$bws[1, 1]),
  " & & 1.50 & 1.50 \\\\\n",
  "Eff. N & ", sprintf("%d", round(results$rdd_county_morning$N_h[1] + results$rdd_county_morning$N_h[2])),
  " & ", sprintf("%d", round(results$rdd_county_evening$N_h[1] + results$rdd_county_evening$N_h[2])),
  " & & ", sprintf("%d", nobs(results$spec1)),
  " & ", sprintf("%d", nobs(results$spec2)),
  " \\\\\n",
  "Year FE & & & & Yes & Yes \\\\\n",
  "Boundary FE & & & & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Columns (1)--(2) report local polynomial RDD estimates ",
  "(triangular kernel, MSE-optimal bandwidth, robust bias-corrected inference). ",
  "Columns (3)--(4) report parametric estimates from county-year panel regressions ",
  "with year and boundary fixed effects, clustered at the county level. ",
  "Dependent variable: morning (6--10 AM) or evening (3--8 PM) traffic fatality rate per 100,000 population. ",
  "Late-sunset = county centroid west of nearest time zone boundary.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 saved.\n")

# ============================================================
# TABLE 3: Robustness — Bandwidth Sensitivity
# ============================================================
cat("=== Table 3: Bandwidth Sensitivity ===\n")

bw_dt <- robustness$bandwidth_sensitivity

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Bandwidth Sensitivity}\n",
  "\\label{tab:bandwidth}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Bandwidth ($^\\circ$) & Coefficient & Robust SE & $p$-value & N \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(bw_dt)) {
  tab3_tex <- paste0(tab3_tex,
    sprintf("%.2f (%.0f km)", bw_dt$bandwidth[i], bw_dt$bandwidth[i] * 85),
    " & ", sprintf("%.4f", bw_dt$coef[i]),
    " & ", sprintf("%.4f", bw_dt$se[i]),
    " & ", sprintf("%.3f", bw_dt$pval[i]),
    " & ", format(bw_dt$n_obs[i], big.mark = ","),
    " \\\\\n")
}

tab3_tex <- paste0(tab3_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row reports a separate crash-level RDD estimate ",
  "(triangular kernel, MSE-optimal bandwidth within stated window, robust bias-corrected inference). ",
  "Dependent variable: indicator for morning (6--10 AM) fatal crash. ",
  "Running variable: longitude distance to nearest time zone boundary.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_bandwidth.tex"))
cat("Table 3 saved.\n")

# ============================================================
# TABLE 4: Mechanism — Weekday vs Weekend & Boundary-Specific
# ============================================================
cat("=== Table 4: Mechanism Tests ===\n")

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Mechanism Tests: Weekday vs.\\ Weekend and Boundary-Specific Estimates}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & Coefficient & Robust SE & $p$-value \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Time of week}} \\\\\n",
  "\\addlinespace\n"
)

# Weekday
if (!is.null(robustness$weekday)) {
  tab4_tex <- paste0(tab4_tex,
    "Weekday mornings & ", sprintf("%.4f", robustness$weekday$coef),
    " & ", sprintf("(%.4f)", robustness$weekday$se),
    " & ", sprintf("%.3f", robustness$weekday$pval), " \\\\\n")
}

# Weekend
if (!is.null(robustness$weekend)) {
  tab4_tex <- paste0(tab4_tex,
    "Weekend mornings & ", sprintf("%.4f", robustness$weekend$coef),
    " & ", sprintf("(%.4f)", robustness$weekend$se),
    " & ", sprintf("%.3f", robustness$weekend$pval), " \\\\\n")
}

# No COVID
if (!is.null(robustness$no_covid)) {
  tab4_tex <- paste0(tab4_tex,
    "\\addlinespace\n",
    "Excl.\\ COVID (2020--21) & ", sprintf("%.4f", robustness$no_covid$coef),
    " & ", sprintf("(%.4f)", robustness$no_covid$se),
    " & ", sprintf("%.3f", robustness$no_covid$pval), " \\\\\n")
}

# Boundary-specific
tab4_tex <- paste0(tab4_tex,
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: By boundary}} \\\\\n",
  "\\addlinespace\n"
)

bnd_dt <- robustness$boundary_specific
for (i in 1:nrow(bnd_dt)) {
  bname <- switch(bnd_dt$boundary[i],
    "EC" = "Eastern/Central",
    "CM" = "Central/Mountain",
    "MP" = "Mountain/Pacific"
  )
  tab4_tex <- paste0(tab4_tex,
    bname,
    " & ", sprintf("%.4f", bnd_dt$coef[i]),
    " & ", sprintf("(%.4f)", bnd_dt$se[i]),
    " & ", sprintf("%.3f", bnd_dt$pval[i]),
    " \\\\\n")
}

tab4_tex <- paste0(tab4_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row reports a separate crash-level RDD estimate ",
  "(triangular kernel, MSE-optimal bandwidth, robust bias-corrected inference). ",
  "Panel A tests the social jetlag mechanism: if chronic circadian misalignment drives the effect, ",
  "it should concentrate on weekday mornings (forced early wake) and not weekend mornings (can sleep in). ",
  "Panel B reports boundary-specific estimates.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_mechanism.tex"))
cat("Table 4 saved.\n")

# ============================================================
# TABLE 5: Validity — McCrary, Covariate Balance, Placebo Cutoffs
# ============================================================
cat("=== Table 5: Validity Tests ===\n")

tab5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Validity Tests}\n",
  "\\label{tab:validity}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & Estimate & SE & $p$-value \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Density test (McCrary)}} \\\\\n",
  "\\addlinespace\n",
  sprintf("Log density difference & %.4f & (%.4f) & %.3f \\\\\n",
    results$density_test$test$t_jk, results$density_test$test$se_jk,
    results$density_test$test$p_jk),
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Covariate balance at boundary}} \\\\\n",
  "\\addlinespace\n"
)

bal_dt <- robustness$covariate_balance
for (i in 1:nrow(bal_dt)) {
  cov_label <- switch(bal_dt$covariate[i],
    "weekend" = "Weekend share",
    "dark" = "Darkness share",
    "MONTH" = "Month"
  )
  tab5_tex <- paste0(tab5_tex,
    cov_label,
    " & ", sprintf("%.4f", bal_dt$coef[i]),
    " & ", sprintf("(%.4f)", bal_dt$se[i]),
    " & ", sprintf("%.3f", bal_dt$pval[i]),
    " \\\\\n")
}

tab5_tex <- paste0(tab5_tex,
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Placebo cutoffs}} \\\\\n",
  "\\addlinespace\n"
)

plac_dt <- robustness$placebo_cutoffs
for (i in 1:nrow(plac_dt)) {
  tab5_tex <- paste0(tab5_tex,
    sprintf("True boundary %+d$^\\circ$", plac_dt$offset[i]),
    " & ", sprintf("%.4f", plac_dt$coef[i]),
    " & ", sprintf("(%.4f)", plac_dt$se[i]),
    " & ", sprintf("%.3f", plac_dt$pval[i]),
    " \\\\\n")
}

# Donut
if (!is.null(robustness$donut)) {
  tab5_tex <- paste0(tab5_tex,
    "\\addlinespace\n",
    "\\multicolumn{4}{l}{\\textit{Panel D: Donut hole ($\\pm$0.1$^\\circ$ excluded)}} \\\\\n",
    "\\addlinespace\n",
    sprintf("Morning fatality & %.4f & (%.4f) & %.3f \\\\\n",
      robustness$donut$coef, robustness$donut$se, robustness$donut$pval))
}

tab5_tex <- paste0(tab5_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A: Cattaneo, Jansson, and Ma (2020) density test at the TZ boundary. ",
  "Panel B: RDD estimates on pre-determined covariates (should be zero if boundary is as-good-as-random). ",
  "Panel C: RDD estimates at false boundaries $\\pm$1$^\\circ$ and $\\pm$2$^\\circ$ from true boundaries (should be zero). ",
  "Panel D: Excludes crashes within $\\pm$0.1$^\\circ$ ($\\approx$ 8.5 km) of boundary.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, file.path(tables_dir, "tab5_validity.tex"))
cat("Table 5 saved.\n")

# ============================================================
# TABLE F1: SDE Appendix (MANDATORY)
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Load county-year data for SD computations
rdd_county <- fread("fars_cleaned.csv")
rdd_county <- rdd_county[abs(dist_to_boundary) <= 1.5]

# Compute county-year rates for SD
county_yr <- rdd_county[, .(
  morning_count = sum(morning),
  total = .N
), by = .(fips, YEAR)]

pop <- fread("county_population.csv")
pop[, fips := as.character(paste0(state, county))]
county_yr[, fips := as.character(fips)]
county_yr[, acs_year := fcase(YEAR <= 2016, 2014, YEAR <= 2021, 2019, default = 2023)]
county_yr <- merge(county_yr, pop[, .(fips, acs_year, total_pop)],
                   by = c("fips", "acs_year"), all.x = TRUE)
county_yr[total_pop > 0, morning_rate := morning_count / total_pop * 100000]

# SD of morning fatality rate
sd_morning <- sd(county_yr$morning_rate, na.rm = TRUE)

# Main coefficient
beta_morning <- results$rdd_county_morning$coef[1]
se_morning <- results$rdd_county_morning$se[3]

# Evening (falsification)
beta_evening <- results$rdd_county_evening$coef[1]
se_evening <- results$rdd_county_evening$se[3]
sd_evening <- sd(county_yr[total_pop > 0, total / total_pop * 100000], na.rm = TRUE)

# Compute SDEs
sde_morning <- beta_morning / sd_morning
sde_se_morning <- se_morning / sd_morning

sde_evening <- beta_evening / sd_evening
sde_se_evening <- se_evening / sd_evening

# Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

class_morning <- classify_sde(sde_morning)
class_evening <- classify_sde(sde_evening)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does chronic circadian misalignment caused by time zone boundary assignment increase morning traffic fatality rates? ",
  "\\textbf{Policy mechanism:} US time zone boundaries (49 CFR Part 71) create sharp 1-hour clock shifts at county borders; residents on the late-sunset (western) side experience later effective sunrise and chronic sleep deprivation from social schedules misaligned with solar time. ",
  "\\textbf{Outcome definition:} Morning (6:00--9:59 AM) traffic fatality rate per 100,000 county population, computed from NHTSA FARS geocoded crash records. ",
  "\\textbf{Treatment:} Binary indicator for county centroid located west (late-sunset side) of the nearest continental time zone boundary. ",
  "\\textbf{Data:} NHTSA FARS 2010--2023, Census ACS 5-year for population denominators, county-year panel with ", sprintf("%d", diagnostics$n_obs), " observations. ",
  "\\textbf{Method:} Spatial regression discontinuity at three continental US time zone boundaries; local polynomial with triangular kernel and MSE-optimal bandwidth (Calonico, Cattaneo, and Titiunik 2014); robust bias-corrected inference. ",
  "\\textbf{Sample:} Counties within $\\pm$1.5$^\\circ$ longitude ($\\approx$127 km) of nearest time zone boundary; excludes Alaska, Hawaii, and territories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-county ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tab_sde <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sprintf("Morning fatality rate & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
    beta_morning, se_morning, sd_morning, sde_morning, sde_se_morning, class_morning),
  sprintf("Evening fatality rate & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
    beta_evening, se_evening, sd_evening, sde_evening, sde_se_evening, class_evening),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab_sde, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) saved.\n")

cat("\n=== All tables generated ===\n")
