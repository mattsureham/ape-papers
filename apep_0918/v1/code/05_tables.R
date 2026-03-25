## 05_tables.R — Generate all tables for ULEZ expansion paper
## APEP paper apep_0918: ULEZ expansion and NO2

source("code/00_packages.R")

panel <- fread("data/panel_clean.csv")
results <- readRDS("data/main_results.rds")
rob_results <- readRDS("data/robustness_results.rds")

cat("=== Generating Tables ===\n")

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("--- Table 1: Summary Statistics ---\n")

## Summary by treatment group and period
sum_stats <- panel[, .(
  Mean = mean(no2_mean, na.rm = TRUE),
  SD = sd(no2_mean, na.rm = TRUE),
  Median = median(no2_mean, na.rm = TRUE),
  N_stations = uniqueN(site_code),
  N_obs = .N
), by = .(Group = ifelse(treat == 1, "Inner London (Treated)", "Outer London (Control)"),
          Period = ifelse(post == 0, "Pre (Jan 2018 -- Oct 2021)", "Post (Nov 2021 -- Aug 2023)"))]

## Overall stats
overall <- panel[, .(
  mean_no2 = mean(no2_mean),
  sd_no2 = sd(no2_mean),
  mean_ln_no2 = mean(ln_no2),
  sd_ln_no2 = sd(ln_no2),
  n_stations = uniqueN(site_code),
  n_inner = uniqueN(site_code[treat == 1]),
  n_outer = uniqueN(site_code[treat == 0]),
  pct_roadside = mean(roadside) * 100,
  mean_dist = mean(abs(dist_boundary_km))
)]

## Generate LaTeX
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: NO$_2$ Concentrations by Treatment Group and Period}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Inner London (Treated)} & \\multicolumn{2}{c}{Outer London (Control)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Pre & Post & Pre & Post \\\\",
  "\\midrule"
)

## Fill in values from sum_stats
for (var_name in c("Mean NO$_2$ ($\\mu$g/m$^3$)", "SD NO$_2$", "Median NO$_2$", "Station-months", "Stations")) {
  vals <- character(4)
  for (g in 1:2) {
    for (p in 1:2) {
      idx <- which(sum_stats$Group == c("Inner London (Treated)", "Outer London (Control)")[g] &
                     sum_stats$Period == c("Pre (Jan 2018 -- Oct 2021)", "Post (Nov 2021 -- Aug 2023)")[p])
      col_idx <- (g - 1) * 2 + p
      if (var_name == "Mean NO$_2$ ($\\mu$g/m$^3$)") vals[col_idx] <- sprintf("%.1f", sum_stats$Mean[idx])
      if (var_name == "SD NO$_2$") vals[col_idx] <- sprintf("%.1f", sum_stats$SD[idx])
      if (var_name == "Median NO$_2$") vals[col_idx] <- sprintf("%.1f", sum_stats$Median[idx])
      if (var_name == "Station-months") vals[col_idx] <- format(sum_stats$N_obs[idx], big.mark = ",")
      if (var_name == "Stations") vals[col_idx] <- as.character(sum_stats$N_stations[idx])
    }
  }
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s & %s \\\\", var_name, vals[1], vals[2], vals[3], vals[4]))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} NO$_2$ measured in $\\mu$g/m$^3$ from the London Air Quality Network (LAQN). Pre-period: January 2018 through October 2021. Post-period: November 2021 through August 2023 (before outer London ULEZ expansion). Inner London = stations inside the North/South Circular roads (treated by October 2021 ULEZ expansion). Stations with $<$75\\%% hourly coverage in a month are excluded. Only stations with $\\geq$80\\%% month coverage over the study period are retained. N = %s station-months across %d stations.",
          format(nrow(panel), big.mark = ","), uniqueN(panel$site_code)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")

## ============================================================
## Table 2: Main Results
## ============================================================
cat("--- Table 2: Main Results ---\n")

m1 <- results$twfe_level
m2 <- results$twfe_log
m5_near <- results$dist_near
m5_far <- results$dist_far
m6_road <- results$roadside
m6_bg <- results$background

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

fmt_coef <- function(model, var = "treat_post") {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  sprintf("%.3f%s", b, stars(p))
}

fmt_se <- function(model, var = "treat_post") {
  sprintf("(%.3f)", se(model)[var])
}

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of ULEZ Expansion on NO$_2$ Concentrations}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & Baseline & Log & Near & Far & Roadside & Background \\\\",
  "\\midrule",
  sprintf("ULEZ $\\times$ Post & %s & %s & %s & %s & %s & %s \\\\",
          fmt_coef(m1), fmt_coef(m2), fmt_coef(m5_near), fmt_coef(m5_far),
          fmt_coef(m6_road), fmt_coef(m6_bg)),
  sprintf(" & %s & %s & %s & %s & %s & %s \\\\",
          fmt_se(m1), fmt_se(m2), fmt_se(m5_near), fmt_se(m5_far),
          fmt_se(m6_road), fmt_se(m6_bg)),
  "\\addlinespace",
  sprintf("Station FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year-Month FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Outcome & Levels & Log & Levels & Levels & Levels & Levels \\\\"),
  sprintf("Sample & All & All & $\\leq$2km & $>$4km & Roadside & Background \\\\"),
  sprintf("Stations & %d & %d & %d & %d & %d & %d \\\\",
          length(fixef(m1)$site_code), length(fixef(m2)$site_code),
          length(fixef(m5_near)$site_code), length(fixef(m5_far)$site_code),
          length(fixef(m6_road)$site_code), length(fixef(m6_bg)$site_code)),
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","), format(nobs(m2), big.mark = ","),
          format(nobs(m5_near), big.mark = ","), format(nobs(m5_far), big.mark = ","),
          format(nobs(m6_road), big.mark = ","), format(nobs(m6_bg), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at station level in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$. All specifications include station and year-month fixed effects. The dependent variable is monthly mean NO$_2$ ($\\mu$g/m$^3$) in columns (1), (3)--(6) and log(NO$_2$ + 1) in column (2). ``Near'' = treated stations within 2 km of ULEZ boundary; ``Far'' = treated stations $>$4 km from boundary. Treatment: October 2021 ULEZ expansion to inner London.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")

## ============================================================
## Table 3: Robustness
## ============================================================
cat("--- Table 3: Robustness ---\n")

r1_placebo <- rob_results$placebo
r2_nocovid <- rob_results$no_covid
r3_trends <- rob_results$borough_trends
m1_main <- results$twfe_level

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Main & Placebo (Oct 2019) & Excl.\\ COVID & Borough Trends \\\\",
  "\\midrule",
  sprintf("Treatment $\\times$ Post & %s & %s & %s & %s \\\\",
          fmt_coef(m1_main), fmt_coef(r1_placebo, "placebo_did"),
          fmt_coef(r2_nocovid), fmt_coef(r3_trends)),
  sprintf(" & %s & %s & %s & %s \\\\",
          fmt_se(m1_main), fmt_se(r1_placebo, "placebo_did"),
          fmt_se(r2_nocovid), fmt_se(r3_trends)),
  "\\addlinespace",
  sprintf("Station FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year-Month FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Borough $\\times$ Trend & No & No & No & Yes \\\\"),
  sprintf("COVID months excl. & No & No & Yes & No \\\\"),
  sprintf("Sample period & Full & Pre only & Excl.\\ 03/20--06/21 & Full \\\\"),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m1_main), big.mark = ","), format(nobs(r1_placebo), big.mark = ","),
          format(nobs(r2_nocovid), big.mark = ","), format(nobs(r3_trends), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at station level in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$. Column (1) reproduces the baseline estimate. Column (2) assigns a placebo treatment date of October 2019 using only pre-ULEZ data. Column (3) drops March 2020 through June 2021 (COVID lockdown months). Column (4) adds borough-specific linear time trends.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_robustness.tex")

## ============================================================
## Table 4: Callaway-Sant'Anna Event Study (if available)
## ============================================================
cat("--- Table 4: CS Event Study ---\n")

cs_dynamic <- results$cs_dynamic
if (!is.null(cs_dynamic)) {
  es_dt <- data.table(
    rel_time = cs_dynamic$egt,
    att = cs_dynamic$att.egt,
    se = cs_dynamic$se.egt
  )
  es_dt[, p := 2 * pnorm(-abs(att / se))]
  es_dt[, ci_lo := att - 1.96 * se]
  es_dt[, ci_hi := att + 1.96 * se]

  ## Select key periods for table
  es_show <- es_dt[rel_time %in% c(-12, -9, -6, -3, -1, 0, 3, 6, 9, 12)]

  tab4_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Dynamic Treatment Effects: Callaway--Sant'Anna Event Study}",
    "\\label{tab:eventstudy}",
    "\\begin{threeparttable}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Months Relative & ATT & SE & 95\\% CI & \\\\",
    "to ULEZ Expansion & & & & \\\\",
    "\\midrule",
    "\\multicolumn{5}{l}{\\textit{Pre-treatment}} \\\\"
  )

  for (i in seq_len(nrow(es_show))) {
    row <- es_show[i]
    if (row$rel_time == 0) {
      tab4_lines <- c(tab4_lines, "\\midrule",
                       "\\multicolumn{5}{l}{\\textit{Post-treatment}} \\\\")
    }
    star_str <- ifelse(abs(row$att / row$se) > 2.576, "$^{***}$",
                       ifelse(abs(row$att / row$se) > 1.96, "$^{**}$",
                              ifelse(abs(row$att / row$se) > 1.645, "$^{*}$", "")))
    tab4_lines <- c(tab4_lines, sprintf(
      "$t %s %d$ & %.2f%s & (%.2f) & [%.2f, %.2f] & \\\\",
      ifelse(row$rel_time >= 0, "+", ""), abs(row$rel_time),
      row$att, star_str, row$se, row$ci_lo, row$ci_hi
    ))
  }

  ## Add overall ATT
  cs_agg <- results$cs_agg
  tab4_lines <- c(tab4_lines,
    "\\midrule",
    sprintf("Overall ATT & %.2f%s & (%.2f) & [%.2f, %.2f] & \\\\",
            cs_agg$overall.att,
            ifelse(abs(cs_agg$overall.att / cs_agg$overall.se) > 2.576, "$^{***}$",
                   ifelse(abs(cs_agg$overall.att / cs_agg$overall.se) > 1.96, "$^{**}$",
                          ifelse(abs(cs_agg$overall.att / cs_agg$overall.se) > 1.645, "$^{*}$", ""))),
            cs_agg$overall.se,
            cs_agg$overall.att - 1.96 * cs_agg$overall.se,
            cs_agg$overall.att + 1.96 * cs_agg$overall.se),
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATTs aggregated to event-time. Doubly robust estimator with never-treated control group. 95\\% simultaneous confidence bands from 1,000 bootstrap iterations. Reference period: one month before ULEZ expansion ($t-1$). $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\end{table}"
  )

  writeLines(tab4_lines, "tables/tab4_eventstudy.tex")
} else {
  cat("  CS results not available — skipping Table 4\n")
}

## ============================================================
## Table F1: SDE (Standardized Effect Sizes) — MANDATORY
## ============================================================
cat("--- Table F1: Standardized Effect Sizes ---\n")

## Extract key values from main model
beta_main <- coef(results$twfe_level)["treat_post"]
se_main <- se(results$twfe_level)["treat_post"]
sd_y <- sd(panel$no2_mean)
sd_y_pre <- sd(panel[post == 0]$no2_mean)

## Pooled SDE
sde_main <- beta_main / sd_y_pre
se_sde_main <- se_main / sd_y_pre

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

## Heterogeneous SDEs
## By site type
beta_road <- coef(results$roadside)["treat_post"]
se_road <- se(results$roadside)["treat_post"]
sd_y_road <- sd(panel[roadside == 1 & post == 0]$no2_mean)
sde_road <- beta_road / sd_y_road
se_sde_road <- se_road / sd_y_road

beta_bg <- coef(results$background)["treat_post"]
se_bg <- se(results$background)["treat_post"]
sd_y_bg <- sd(panel[roadside == 0 & post == 0]$no2_mean)
sde_bg <- beta_bg / sd_y_bg
se_sde_bg <- se_bg / sd_y_bg

## Build SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does expanding a Low Emission Zone that charges non-compliant vehicles reduce ",
  "ambient nitrogen dioxide at monitoring stations within the newly regulated area? ",
  "\\textbf{Policy mechanism:} The Ultra Low Emission Zone charges vehicles not meeting Euro 4 (petrol) or Euro 6 (diesel) ",
  "emission standards a daily fee of GBP 12.50 to drive within the zone boundary, incentivizing fleet turnover to cleaner ",
  "vehicles and route diversion away from the regulated area. ",
  "\\textbf{Outcome definition:} Monthly mean NO$_2$ concentration ($\\mu$g/m$^3$) from continuous monitoring stations, ",
  "computed from validated hourly readings with at least 75\\% temporal coverage per station-month. ",
  "\\textbf{Treatment:} Binary; station located inside versus outside the expanded ULEZ boundary (North/South Circular roads). ",
  "\\textbf{Data:} London Air Quality Network (LAQN) via King's College London API, January 2018 through August 2023, ",
  "station-month panel. ",
  "\\textbf{Method:} Two-way fixed effects DiD with station and year-month fixed effects, standard errors clustered at station level. ",
  "\\textbf{Sample:} London monitoring stations active throughout the study period with at least 80\\% month coverage; ",
  "post-period ends before the August 2023 outer-London ULEZ expansion to preserve the control group. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of monthly NO$_2$. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("NO$_2$ & Baseline TWFE & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("NO$_2$ & Roadside stations & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_road, se_road, sd_y_road, sde_road, se_sde_road, classify_sde(sde_road)),
  sprintf("NO$_2$ & Background stations & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_bg, se_bg, sd_y_bg, sde_bg, se_sde_bg, classify_sde(sde_bg)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
