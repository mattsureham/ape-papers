# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
df <- readRDS("../data/panel.rds")

dir.create("../tables", showWarnings = FALSE)

# ---------------------------------------------------------------------------
# Table 1: Summary Statistics by Race (NAICS 72, pre-COVID sample)
# ---------------------------------------------------------------------------

df72 <- df %>% filter(industry == "72" & in_pre_covid_sample)

# Compute summary stats
ss <- df72 %>%
  group_by(Race = ifelse(race == "A0", "All Non-Hispanic", "Black Non-Hispanic")) %>%
  summarise(
    `Mean Employment` = sprintf("%.0f", mean(EmpEnd, na.rm = TRUE)),
    `SD Employment` = sprintf("%.0f", sd(EmpEnd, na.rm = TRUE)),
    `Mean Earnings (\\$)` = sprintf("%.0f", mean(EarnS, na.rm = TRUE)),
    `SD Earnings` = sprintf("%.0f", sd(EarnS, na.rm = TRUE)),
    `Mean Hires` = sprintf("%.0f", mean(HirA, na.rm = TRUE)),
    `Mean Separations` = sprintf("%.0f", mean(Sep, na.rm = TRUE)),
    `Mean Turnover` = sprintf("%.3f", mean(TurnOvrS, na.rm = TRUE)),
    `County-Quarters` = format(n(), big.mark = ","),
    .groups = "drop"
  )

# Write manually for clean formatting
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Food Service Employment by Race}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & All Non-Hispanic & Black Non-Hispanic \\\\",
  "\\hline"
)

ss_all <- df72 %>% filter(race == "A0")
ss_blk <- df72 %>% filter(race == "A2")

vars <- list(
  list("Employment (end-of-quarter)", "EmpEnd"),
  list("Quarterly earnings (\\$)", "EarnS"),
  list("All hires", "HirA"),
  list("Separations", "Sep"),
  list("Turnover rate", "TurnOvrS")
)

for (v in vars) {
  nm <- v[[1]]
  vr <- v[[2]]
  a_mean <- mean(ss_all[[vr]], na.rm = TRUE)
  b_mean <- mean(ss_blk[[vr]], na.rm = TRUE)
  a_sd <- sd(ss_all[[vr]], na.rm = TRUE)
  b_sd <- sd(ss_blk[[vr]], na.rm = TRUE)
  if (vr == "TurnOvrS") {
    tab1_lines <- c(tab1_lines,
      sprintf("%s & %.3f & %.3f \\\\", nm, a_mean, b_mean),
      sprintf(" & (%.3f) & (%.3f) \\\\", a_sd, b_sd))
  } else {
    tab1_lines <- c(tab1_lines,
      sprintf("%s & %s & %s \\\\", nm,
              format(round(a_mean), big.mark = ","),
              format(round(b_mean), big.mark = ",")),
      sprintf(" & (%s) & (%s) \\\\",
              format(round(a_sd), big.mark = ","),
              format(round(b_sd), big.mark = ",")))
  }
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("County-quarters & %s & %s \\\\",
          format(nrow(ss_all), big.mark = ","),
          format(nrow(ss_blk), big.mark = ",")),
  sprintf("Counties & %s & %s \\\\",
          format(n_distinct(ss_all$fips), big.mark = ","),
          format(n_distinct(ss_blk$fips), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} QWI county-quarter data for NAICS 72 (Accommodation and Food Services), ",
  "2013Q1--2019Q4. Standard deviations in parentheses. ``All Non-Hispanic'' includes all races ",
  "with non-Hispanic ethnicity (QWI race A0, ethnicity A1). ``Black Non-Hispanic'' is QWI race ",
  "A2, ethnicity A1. Earnings are average quarterly earnings for stable (full-quarter) workers.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ---------------------------------------------------------------------------
# Table 2: Main DDD Results (pre-COVID)
# ---------------------------------------------------------------------------

# Extract coefficients
extract_ddd <- function(model, outcome_name) {
  b <- coef(model)["treat_post_black"]
  s <- se(model)["treat_post_black"]
  p <- fixest::pvalue(model)["treat_post_black"]
  n <- model$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = s, p = p, n = n, stars = stars, name = outcome_name)
}

m <- results$twfe_precovid
cols <- list(
  extract_ddd(m$emp, "ln(Employment)"),
  extract_ddd(m$earn, "ln(Earnings)"),
  extract_ddd(m$sep, "ln(Separations)"),
  extract_ddd(m$hir, "ln(Hires)"),
  extract_ddd(m$turn, "Turnover Rate")
)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Fair Workweek Laws on Black Workers in Food Service: Triple-Difference Estimates}",
  "\\label{tab:main}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", length(cols)), collapse = "")),
  "\\hline\\hline",
  paste0(" & ", paste(sapply(cols, function(x) x$name), collapse = " & "), " \\\\"),
  paste0(" & ", paste(paste0("(", seq_along(cols), ")"), collapse = " & "), " \\\\"),
  "\\hline"
)

# DDD coefficient row
coef_row <- paste0("Treated $\\times$ Post $\\times$ Black & ",
  paste(sapply(cols, function(x)
    sprintf("%.4f%s", x$b, x$stars)), collapse = " & "), " \\\\")
se_row <- paste0(" & ",
  paste(sapply(cols, function(x)
    sprintf("(%.4f)", x$se)), collapse = " & "), " \\\\")

tab2_lines <- c(tab2_lines,
  coef_row, se_row,
  "\\hline",
  paste0("County $\\times$ Race FE & ", paste(rep("\\checkmark", length(cols)), collapse = " & "), " \\\\"),
  paste0("Quarter $\\times$ Race FE & ", paste(rep("\\checkmark", length(cols)), collapse = " & "), " \\\\"),
  paste0("State $\\times$ Quarter FE & ", paste(rep("\\checkmark", length(cols)), collapse = " & "), " \\\\"),
  paste0("Observations & ", paste(sapply(cols, function(x)
    format(x$n, big.mark = ",")), collapse = " & "), " \\\\"),
  sprintf("Clusters (states) & %s \\\\",
    paste(rep(as.character(results$meta$n_clusters), length(cols)), collapse = " & ")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Triple-difference estimates of Fair Workweek law effects on Black relative to all ",
  "non-Hispanic workers in NAICS 72 (food service), pre-COVID sample (2013Q1--2019Q4). Treatment: counties ",
  "covered by predictive scheduling mandates in San Francisco (2015), Seattle (2017), New York City (2017), ",
  "and Oregon (2018). All specifications include county$\\times$race, quarter$\\times$race, and ",
  "state$\\times$quarter fixed effects. Standard errors clustered at the state level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ---------------------------------------------------------------------------
# Table 3: Robustness — Placebo industry + Leave-one-out
# ---------------------------------------------------------------------------

p_emp <- extract_ddd(rob$placebo$emp, "Placebo: Construction")
p_earn <- extract_ddd(rob$placebo$earn, "Placebo: Construction")
loo_or <- extract_ddd(rob$loo_no_oregon, "Drop Oregon")
loo_sf <- extract_ddd(rob$loo_no_sf, "Drop San Francisco")
loo_nyc <- extract_ddd(rob$loo_no_nyc, "Drop New York City")
full_emp <- extract_ddd(rob$full_sample$emp, "Full (incl. COVID)")
full_earn <- extract_ddd(rob$full_sample$earn, "Full (incl. COVID)")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Placebo Industry and Leave-One-Out Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & DDD Coefficient & SE & Observations \\\\",
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel A: Placebo industry (NAICS 23 --- Construction)}} \\\\[3pt]",
  sprintf("ln(Employment) & %.4f%s & (%.4f) & %s \\\\",
    p_emp$b, p_emp$stars, p_emp$se, format(p_emp$n, big.mark = ",")),
  sprintf("ln(Earnings) & %.4f%s & (%.4f) & %s \\\\",
    p_earn$b, p_earn$stars, p_earn$se, format(p_earn$n, big.mark = ",")),
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel B: Leave-one-out (ln Employment, NAICS 72)}} \\\\[3pt]",
  sprintf("Drop Oregon & %.4f%s & (%.4f) & %s \\\\",
    loo_or$b, loo_or$stars, loo_or$se, format(loo_or$n, big.mark = ",")),
  sprintf("Drop San Francisco & %.4f%s & (%.4f) & %s \\\\",
    loo_sf$b, loo_sf$stars, loo_sf$se, format(loo_sf$n, big.mark = ",")),
  sprintf("Drop New York City & %.4f%s & (%.4f) & %s \\\\",
    loo_nyc$b, loo_nyc$stars, loo_nyc$se, format(loo_nyc$n, big.mark = ",")),
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel C: Full sample including COVID-era adopters (2013Q1--2022Q4)}} \\\\[3pt]",
  sprintf("ln(Employment) & %.4f%s & (%.4f) & %s \\\\",
    full_emp$b, full_emp$stars, full_emp$se, format(full_emp$n, big.mark = ",")),
  sprintf("ln(Earnings) & %.4f%s & (%.4f) & %s \\\\",
    full_earn$b, full_earn$stars, full_earn$se, format(full_earn$n, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel A shows triple-difference estimates for NAICS 23 (Construction), an industry ",
  "not covered by Fair Workweek laws but with substantial Black employment. Panel B drops each treatment ",
  "jurisdiction in turn from the pre-COVID NAICS 72 sample. Panel C extends the sample through 2022Q4, ",
  "adding Philadelphia (2020) and Chicago (2020) as treated jurisdictions. All specifications include ",
  "county$\\times$race, quarter$\\times$race, and state$\\times$quarter FE. SEs clustered at state level. ",
  sprintf("Randomization inference p-value (500 permutations): %.3f.", rob$ri$ri_p),
  " $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("Table 3 written.\n")

# ---------------------------------------------------------------------------
# Table 4: Callaway-Sant'Anna DDD Estimates
# ---------------------------------------------------------------------------

cs_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Callaway-Sant'Anna Estimates of the Employment Gap Effect}",
  "\\label{tab:cs}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & ATT & SE \\\\",
  "\\hline"
)

if (!is.null(results$cs_emp)) {
  cs_agg <- aggte(results$cs_emp, type = "simple")
  p_cs <- 2 * pnorm(-abs(cs_agg$overall.att / cs_agg$overall.se))
  stars_cs <- ifelse(p_cs < 0.01, "***", ifelse(p_cs < 0.05, "**", ifelse(p_cs < 0.1, "*", "")))
  cs_lines <- c(cs_lines,
    sprintf("Employment gap (Black $-$ All) & %.4f%s & (%.4f) \\\\",
      cs_agg$overall.att, stars_cs, cs_agg$overall.se))
}

if (!is.null(results$cs_earn)) {
  cs_earn_agg <- aggte(results$cs_earn, type = "simple")
  p_cse <- 2 * pnorm(-abs(cs_earn_agg$overall.att / cs_earn_agg$overall.se))
  stars_cse <- ifelse(p_cse < 0.01, "***", ifelse(p_cse < 0.05, "**", ifelse(p_cse < 0.1, "*", "")))
  cs_lines <- c(cs_lines,
    sprintf("Earnings gap (Black $-$ All) & %.4f%s & (%.4f) \\\\",
      cs_earn_agg$overall.att, stars_cse, cs_earn_agg$overall.se))
}

if (!is.null(results$cs_sep)) {
  cs_sep_agg <- aggte(results$cs_sep, type = "simple")
  p_css <- 2 * pnorm(-abs(cs_sep_agg$overall.att / cs_sep_agg$overall.se))
  stars_css <- ifelse(p_css < 0.01, "***", ifelse(p_css < 0.05, "**", ifelse(p_css < 0.1, "*", "")))
  cs_lines <- c(cs_lines,
    sprintf("Separations gap (Black $-$ All) & %.4f%s & (%.4f) \\\\",
      cs_sep_agg$overall.att, stars_css, cs_sep_agg$overall.se))
}

cs_lines <- c(cs_lines,
  "\\hline",
  "Estimator & \\multicolumn{2}{c}{Callaway-Sant'Anna (2021)} \\\\",
  "Comparison group & \\multicolumn{2}{c}{Never-treated counties} \\\\",
  "Base period & \\multicolumn{2}{c}{Universal} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATT estimates aggregated into an ",
  "overall simple-weighted ATT. The dependent variable is the log-ratio gap between Black non-Hispanic ",
  "and all non-Hispanic workers in NAICS 72 (food service). Comparison group: never-treated counties. ",
  "Standard errors clustered at the state level.",
  " $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(cs_lines, "../tables/tab4_cs.tex")
cat("Table 4 written.\n")

# ---------------------------------------------------------------------------
# Table F1: Standardized Effect Size (SDE) Appendix
# ---------------------------------------------------------------------------

# Compute SDEs from the pre-COVID main results
df72_pre <- df %>% filter(industry == "72" & in_pre_covid_sample)
m <- results$twfe_precovid

# SD(Y) from pre-treatment period for treated counties
pre_treated <- df72_pre %>%
  filter(treated_ever & post == 0 & race == "A2")

sd_ln_emp <- sd(pre_treated$ln_emp, na.rm = TRUE)
sd_ln_earn <- sd(pre_treated$ln_earn, na.rm = TRUE)
sd_ln_sep <- sd(pre_treated$ln_sep, na.rm = TRUE)
sd_turn <- sd(pre_treated$TurnOvrS, na.rm = TRUE)

sde_emp <- coef(m$emp)["treat_post_black"] / sd_ln_emp
sde_earn <- coef(m$earn)["treat_post_black"] / sd_ln_earn
sde_sep <- coef(m$sep)["treat_post_black"] / sd_ln_sep
sde_turn <- coef(m$turn)["treat_post_black"] / sd_turn

se_sde_emp <- se(m$emp)["treat_post_black"] / sd_ln_emp
se_sde_earn <- se(m$earn)["treat_post_black"] / sd_ln_earn
se_sde_sep <- se(m$sep)["treat_post_black"] / sd_ln_sep
se_sde_turn <- se(m$turn)["treat_post_black"] / sd_turn

classify <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do predictive scheduling mandates (Fair Workweek laws) ",
  "differentially improve employment, earnings, and retention for Black workers in food service? ",
  "\\textbf{Policy mechanism:} Fair Workweek laws require covered food service and retail employers ",
  "to post schedules at least 14 days in advance, pay premium wages for last-minute schedule changes, ",
  "and offer additional hours to existing staff before hiring new workers, reducing schedule ",
  "uncertainty that disproportionately affects workers with binding childcare and transportation constraints. ",
  "\\textbf{Outcome definition:} Log end-of-quarter employment, log average quarterly earnings of stable ",
  "full-quarter workers, log quarterly separations, and turnover rate (separations/stable employment) ",
  "from the Census Quarterly Workforce Indicators (QWI). ",
  "\\textbf{Treatment:} Binary; county covered by a Fair Workweek law interacted with Black non-Hispanic ",
  "race indicator (triple-difference). ",
  "\\textbf{Data:} QWI race/ethnicity panel (county $\\times$ quarter $\\times$ race), NAICS 72 ",
  "(Accommodation and Food Services), 2013Q1--2019Q4, pre-COVID sample. ",
  sprintf("N = %s county-quarter-race observations across %d states. ",
    format(nrow(df72_pre), big.mark = ","), n_distinct(df72_pre$state_fips)),
  "\\textbf{Method:} TWFE triple-difference (county$\\times$race, quarter$\\times$race, ",
  "state$\\times$quarter FE); standard errors clustered at the state level; robustness via ",
  "Callaway-Sant'Anna (2021), randomization inference, and placebo industry (construction). ",
  "\\textbf{Sample:} Counties with positive Black non-Hispanic employment in NAICS 72; ",
  "pre-COVID period only; COVID-era adopters (Philadelphia, Chicago) excluded from main specification. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome among treated Black workers. Classification refers to magnitude, ",
  "not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), ",
  "Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_rows <- list(
  list("ln(Employment)", coef(m$emp)["treat_post_black"], se(m$emp)["treat_post_black"],
       sd_ln_emp, sde_emp, se_sde_emp),
  list("ln(Earnings)", coef(m$earn)["treat_post_black"], se(m$earn)["treat_post_black"],
       sd_ln_earn, sde_earn, se_sde_earn),
  list("ln(Separations)", coef(m$sep)["treat_post_black"], se(m$sep)["treat_post_black"],
       sd_ln_sep, sde_sep, se_sde_sep),
  list("Turnover Rate", coef(m$turn)["treat_post_black"], se(m$turn)["treat_post_black"],
       sd_turn, sde_turn, se_sde_turn)
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (r in sde_rows) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
      r[[1]], r[[2]], r[[3]], r[[4]], r[[5]], r[[6]], classify(r[[5]])))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
