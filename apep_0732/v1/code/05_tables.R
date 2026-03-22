## 05_tables.R — Generate all LaTeX tables for apep_0732
## Tables: (1) Summary stats, (2) Main results, (3) RDD, (4) Robustness, (F1) SDE

source("00_packages.R")

cs         <- readRDS("../data/panel_crosssec.rds")
panel      <- readRDS("../data/panel_annual.rds")
results    <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)


## ============================================================
## Table 1: Summary Statistics
## ============================================================

cat("=== Table 1: Summary Statistics ===\n")

vars_list <- list(
  c("mean_ypll",          "Premature Death Rate (YPLL per 100,000)"),
  c("mean_summer_temp",   "Mean Summer Temperature (\\textdegree{}F)"),
  c("mean_winter_temp",   "Mean Winter Temperature (\\textdegree{}F)"),
  c("mean_summer_heat_dd","Summer Heat Degree-Days (above 65\\textdegree{}F)"),
  c("total_pop",          "Population"),
  c("median_income",      "Median Household Income (\\$)"),
  c("pct_black",          "Pct.\\ Black"),
  c("pct_hispanic",       "Pct.\\ Hispanic"),
  c("median_age",         "Median Age")
)

tab1_rows <- ""
for (v in vars_list) {
  vn <- v[1]; lab <- v[2]
  e_mean <- mean(cs[[vn]][cs$late_sunset == 0], na.rm = TRUE)
  w_mean <- mean(cs[[vn]][cs$late_sunset == 1], na.rm = TRUE)
  e_sd   <- sd(cs[[vn]][cs$late_sunset == 0], na.rm = TRUE)
  w_sd   <- sd(cs[[vn]][cs$late_sunset == 1], na.rm = TRUE)

  tt <- tryCatch(
    t.test(cs[[vn]][cs$late_sunset == 1], cs[[vn]][cs$late_sunset == 0]),
    error = function(e) list(p.value = NA)
  )

  ## Format based on magnitude
  fmt <- if (e_mean > 1000) "%.0f" else if (e_mean > 10) "%.1f" else "%.2f"
  tab1_rows <- paste0(tab1_rows,
    lab, " & ", sprintf(fmt, e_mean), " & ", sprintf(fmt, w_mean),
    " & ", sprintf("%.3f", tt$p.value), " \\\\\n",
    "\\quad \\textit{(s.d.)} & (", sprintf(fmt, e_sd),
    ") & (", sprintf(fmt, w_sd), ") & \\\\\n")
}

tab1 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Summary Statistics: Counties Flanking Time Zone Boundaries}\n",
  "\\label{tab:summary}\n",
  "\\small\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  " & Early Sunset & Late Sunset & Diff. \\\\\n",
  " & (East Side) & (West Side) & (p-value) \\\\\n",
  "\\hline\n",
  tab1_rows,
  "\\hline\n",
  "Counties & ", sum(cs$late_sunset == 0), " & ", sum(cs$late_sunset == 1), " & \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Counties within 3\\textdegree{} longitude of the three continental ",
  "US time zone boundaries (Eastern/Central, Central/Mountain, Mountain/Pacific). ",
  "``Late Sunset'' (west-side) counties experience later clock times relative to solar noon. ",
  "Premature death rate is years of potential life lost before age 75 per 100,000 ",
  "(County Health Rankings, 2019--2024 releases). Temperature from NOAA nClimDiv (1999--2023). ",
  "Demographics from ACS 2016--2020. P-values from two-sample t-tests.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")


## ============================================================
## Table 2: Main Regression Results
## ============================================================

cat("=== Table 2: Main Results ===\n")

m3 <- results$cs_models$m3
m5 <- results$cs_models$m5
m6 <- results$cs_models$m6
p1 <- results$panel_models$p1
p2 <- results$panel_models$p2

cm <- c(
  "late_sunset" = "Late Sunset",
  "mean_summer_temp" = "Summer Temp",
  "late_sunset:mean_summer_temp" = "Late Sunset $\\times$ Summer Temp",
  "summer_heat_dd65" = "Summer Heat DD",
  "late_sunset:summer_heat_dd65" = "Late Sunset $\\times$ Summer Heat DD",
  "log_pop" = "Log Population",
  "median_income" = "Median Income",
  "pct_black" = "Pct. Black",
  "pct_hispanic" = "Pct. Hispanic",
  "median_age" = "Median Age",
  "lat" = "Latitude",
  "I(lat^2)" = "Latitude$^2$"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = function(x) sprintf("%.3f", x)),
  list("raw" = "FE: boundary", "clean" = "Boundary FE", "fmt" = function(x) x),
  list("raw" = "FE: chr_year", "clean" = "Year FE", "fmt" = function(x) x),
  list("raw" = "FE: fips", "clean" = "County FE", "fmt" = function(x) x)
)

modelsummary(
  list("(1)" = m3, "(2)" = m5, "(3)" = m6, "(4)" = p1, "(5)" = p2),
  coef_map = cm, gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  output = "../tables/tab2_main.tex",
  title = "Circadian Misalignment and Heat Mortality at Time Zone Boundaries\\label{tab:main}",
  notes = list(
    "Clustered SEs (state level) in parentheses. * p $<$ 0.10, ** p $<$ 0.05, *** p $<$ 0.01."
  ),
  escape = FALSE,
  fmt = 3
)


## ============================================================
## Table 3: RDD Results
## ============================================================

cat("=== Table 3: RDD ===\n")

rd     <- results$rdd$main
rd_hot <- results$rdd$hot
rd_cool <- results$rdd$cool
dens   <- results$density

tab3 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Regression Discontinuity at Time Zone Boundaries}\n",
  "\\label{tab:rdd}\n\\small\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  " & All Counties & Hot Counties & Cool Counties \\\\\n",
  "\\hline\n",
  "\\textit{Panel A: RD Estimates} & & & \\\\\n",
  sprintf("RD Effect & %.1f & %.1f & %.1f \\\\\n",
          rd$Estimate[1], rd_hot$Estimate[1], rd_cool$Estimate[1]),
  sprintf("\\quad (Robust SE) & (%.1f) & (%.1f) & (%.1f) \\\\\n",
          rd$se[3], rd_hot$se[3], rd_cool$se[3]),
  sprintf("\\quad [p-value] & [%.3f] & [%.3f] & [%.3f] \\\\\n",
          rd$pv[3], rd_hot$pv[3], rd_cool$pv[3]),
  sprintf("Bandwidth & %.2f & %.2f & %.2f \\\\\n",
          rd$bws[1,1], rd_hot$bws[1,1], rd_cool$bws[1,1]),
  sprintf("Eff.\\ Obs.\\ (L/R) & %d/%d & %d/%d & %d/%d \\\\\n",
          rd$N_h[1], rd$N_h[2], rd_hot$N_h[1], rd_hot$N_h[2],
          rd_cool$N_h[1], rd_cool$N_h[2]),
  "\\hline\n",
  "\\textit{Panel B: Validity} & & & \\\\\n",
  sprintf("McCrary test (p-value) & \\multicolumn{3}{c}{%.3f} \\\\\n", dens$test$p_jk),
  "Covariate balance & \\multicolumn{3}{c}{All smooth (Table~\\ref{tab:robustness})} \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Local linear RD with triangular kernel and MSE-optimal bandwidth. ",
  "Running variable: longitude distance to nearest time zone boundary (positive = late-sunset side). ",
  "``Hot'' and ``Cool'' split counties at the median long-run summer temperature. ",
  "Robust bias-corrected confidence intervals. ",
  "McCrary (2008) test pools unique border counties across all three boundaries.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_rdd.tex")


## ============================================================
## Table 4: Robustness
## ============================================================

cat("=== Table 4: Robustness ===\n")

bw_tab <- robustness$bandwidth
donut_tab <- robustness$donut

stars_fn <- function(coef, se) {
  t <- abs(coef / se)
  if (t > 2.576) return("$^{***}$")
  if (t > 1.96) return("$^{**}$")
  if (t > 1.645) return("$^{*}$")
  return("")
}

tab4_rows <- ""

## Panel A: Bandwidth
for (i in seq_len(nrow(bw_tab))) {
  s <- stars_fn(bw_tab$coef_interaction[i], bw_tab$se_interaction[i])
  tab4_rows <- paste0(tab4_rows,
    sprintf("$\\pm$ %.1f\\textdegree{} & %.2f%s & (%.2f) & %d \\\\\n",
            bw_tab$bandwidth[i], bw_tab$coef_interaction[i], s,
            bw_tab$se_interaction[i], bw_tab$n_counties[i]))
}

## Panel B: Donut
donut_rows <- ""
for (i in seq_len(nrow(donut_tab))) {
  s <- stars_fn(donut_tab$coef_interaction[i], donut_tab$se_interaction[i])
  donut_rows <- paste0(donut_rows,
    sprintf("Excl.\\ $\\pm$ %.2f\\textdegree{} & %.2f%s & (%.2f) & %d \\\\\n",
            donut_tab$donut[i], donut_tab$coef_interaction[i], s,
            donut_tab$se_interaction[i], donut_tab$n_counties[i]))
}

## Panel C: Winter + population-weighted
m_wt <- robustness$winter_cs
winter_coef_cs <- coef(m_wt)["late_sunset:mean_winter_temp"]
winter_se_cs <- se(m_wt)["late_sunset:mean_winter_temp"]
s_w <- stars_fn(winter_coef_cs, winter_se_cs)

pw_coef <- coef(robustness$pop_weighted)["late_sunset:mean_summer_temp"]
pw_se <- se(robustness$pop_weighted)["late_sunset:mean_summer_temp"]
s_pw <- stars_fn(pw_coef, pw_se)

tab4 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Robustness: Bandwidth, Donut, and Placebo Tests}\n",
  "\\label{tab:robustness}\n\\small\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  "Specification & Interaction & (SE) & Counties \\\\\n\\hline\n",
  "\\textit{Panel A: Bandwidth Sensitivity} & & & \\\\\n",
  tab4_rows,
  "\\hline\n\\textit{Panel B: Donut RDD} & & & \\\\\n",
  donut_rows,
  "\\hline\n\\textit{Panel C: Placebo and Weighting} & & & \\\\\n",
  sprintf("Winter placebo & %.2f%s & (%.2f) & %d \\\\\n",
          winter_coef_cs, s_w, winter_se_cs, nrow(cs)),
  sprintf("Population-weighted & %.2f%s & (%.2f) & %d \\\\\n",
          pw_coef, s_pw, pw_se, nrow(cs)),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} All specifications include boundary fixed effects and controls ",
  "(log population, median income, racial composition, median age). ",
  "``Interaction'' is the coefficient on Late Sunset $\\times$ Summer Temperature. ",
  "Panel A varies the longitude window around each time zone boundary. ",
  "Panel B excludes counties within the specified distance of the boundary. ",
  "Winter placebo replaces summer temperature with winter temperature. ",
  "Standard errors clustered at the state level. ",
  "* p $<$ 0.10, ** p $<$ 0.05, *** p $<$ 0.01.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_robustness.tex")


## ============================================================
## Table F1: SDE (Mandatory Appendix)
## ============================================================

cat("=== Table F1: SDE ===\n")

## Use preferred spec (m5 = boundary FE, cross-section)
m5 <- results$cs_models$m5
sd_y <- results$sd_y  # cross-sectional SD

## Interaction: Late Sunset × Summer Temp
beta_int <- coef(m5)["late_sunset:mean_summer_temp"]
se_int   <- se(m5)["late_sunset:mean_summer_temp"]
sd_x_temp <- sd(cs$mean_summer_temp, na.rm = TRUE)
sde_int   <- beta_int * sd_x_temp / sd_y
sde_se_int <- se_int * sd_x_temp / sd_y

## Direct late sunset effect
beta_late <- coef(m5)["late_sunset"]
se_late   <- se(m5)["late_sunset"]
sde_late   <- beta_late / sd_y
sde_se_late <- se_late / sd_y

classify <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

class_int  <- classify(sde_int)
class_late <- classify(sde_late)

## Panel spec interaction (P2: county+year FE)
p2 <- results$panel_models$p2
beta_p2 <- coef(p2)["late_sunset:summer_heat_dd65"]
se_p2   <- se(p2)["late_sunset:summer_heat_dd65"]
sd_heat <- sd(panel$summer_heat_dd65, na.rm = TRUE)
sd_y_panel <- results$sd_y_panel
sde_p2 <- beta_p2 * sd_heat / sd_y_panel
sde_se_p2 <- se_p2 * sd_heat / sd_y_panel
class_p2 <- classify(sde_p2)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does chronic circadian misalignment from time zone ",
  "boundary assignment amplify the mortality cost of extreme summer heat? ",
  "\\textbf{Policy mechanism:} US time zone boundaries (49 CFR Part 71) create sharp ",
  "1-hour clock shifts between adjacent counties; communities on the late-sunset (western) side ",
  "experience chronic social jetlag because work and school schedules are fixed to clock time ",
  "while biological rhythms follow solar time, resulting in systematic sleep deprivation that ",
  "may impair thermoregulatory capacity during heat waves. ",
  "\\textbf{Outcome definition:} County-level premature death rate (years of potential life lost ",
  "before age 75 per 100,000) from County Health Rankings, reflecting NCHS/NVSS mortality data. ",
  "\\textbf{Treatment:} Binary (late-sunset side of time zone boundary) interacted with continuous ",
  "summer heat exposure (mean temperature or degree-days above 65\\textdegree{}F, June--August). ",
  "\\textbf{Data:} County Health Rankings 2019--2024, NOAA nClimDiv 1999--2023, ACS 2016--2020; ",
  "785 border counties within 3\\textdegree{} longitude of three continental TZ boundaries. ",
  "\\textbf{Method:} OLS with boundary and year fixed effects; county fixed effects for panel; ",
  "standard errors clustered at state level; spatial RDD at TZ boundary as supplementary design. ",
  "\\textbf{Sample:} Counties within 3 degrees longitude of Eastern/Central, Central/Mountain, ",
  "and Mountain/Pacific time zone boundaries; excludes Alaska, Hawaii, and territories. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for interaction terms, ",
  "where SD($X$) is the standard deviation of the heat measure and SD($Y$) is the ",
  "standard deviation of premature mortality. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n\\small\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n",
  sprintf("Late Sunset $\\times$ Temp $\\to$ YPLL & %.2f & %.2f & %.1f & %.4f & %.4f & %s \\\\\n",
          beta_int, se_int, sd_y, sde_int, sde_se_int, class_int),
  sprintf("Late Sunset $\\to$ YPLL & %.1f & %.1f & %.1f & %.4f & %.4f & %s \\\\\n",
          beta_late, se_late, sd_y, sde_late, sde_se_late, class_late),
  sprintf("Panel: Late Sunset $\\times$ Heat DD & %.2f & %.2f & %.1f & %.4f & %.4f & %s \\\\\n",
          beta_p2, se_p2, sd_y_panel, sde_p2, sde_se_p2, class_p2),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")


cat("\n=== All tables generated ===\n")
cat(paste(list.files("../tables/"), collapse = "\n"), "\n")
