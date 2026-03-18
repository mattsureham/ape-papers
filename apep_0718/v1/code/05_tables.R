## 05_tables.R — Generate all LaTeX tables
## apep_0718: Tornado Paths and Manufactured Housing

source("00_packages.R")

cat("=== Loading results ===\n")
df <- readRDS("../data/analysis_dataset.rds")
summ <- readRDS("../data/summary_stats.rds")
rdd_res <- readRDS("../data/rdd_results.rds")
ols_res <- readRDS("../data/ols_results.rds")
rob_res <- readRDS("../data/robustness_results.rds")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Helper: format number with significance stars
fmt_star <- function(coef, pv, digits = 3) {
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  paste0(formatC(coef, format = "f", digits = digits), stars)
}

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics\n")

var_labels <- c(
  "mobile_pct_pre" = "Mobile Home Share (\\%, pre)",
  "poverty_rate_pre" = "Poverty Rate (\\%, pre)",
  "log_value_pre" = "Log Median Housing Value (pre)",
  "total_popE_pre" = "Population (pre)",
  "total_unitsE_pre" = "Housing Units (pre)",
  "vacancy_pre" = "Vacancy Rate (\\%, pre)",
  "delta_mobile_pct" = "$\\Delta$ Mobile Home Share (pp)",
  "delta_poverty" = "$\\Delta$ Poverty Rate (pp)",
  "delta_log_value" = "$\\Delta$ Log Housing Value"
)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Treated vs.\\ Control Census Tracts}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Treated (In Path)} & \\multicolumn{2}{c}{Control (Near Path)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\hline"
)

for (v in names(var_labels)) {
  t_mean <- pull(summ$treated, paste0(v, "_mean"))
  t_sd   <- pull(summ$treated, paste0(v, "_sd"))
  c_mean <- pull(summ$control, paste0(v, "_mean"))
  c_sd   <- pull(summ$control, paste0(v, "_sd"))

  tab1_lines <- c(tab1_lines,
    sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\",
            var_labels[v], t_mean, t_sd, c_mean, c_sd))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(summ$n_treated, big.mark = ","),
          format(summ$n_control, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Treated tracts have centroids inside an EF2+ tornado path (2000--2015). Control tracts are within 5 miles of the path edge but outside. Pre-period outcomes are from ACS 2006--2010; post-period from ACS 2018--2022. Changes ($\\Delta$) are post minus pre.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# TABLE 2: Main RDD Results
# ============================================================================
cat("Generating Table 2: Main RDD Results\n")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Spatial RDD Estimates: Effect of Tornado Path Exposure on Neighborhood Outcomes}",
  "\\label{tab:rdd_main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & $\\Delta$ Mobile & $\\Delta$ Poverty & $\\Delta$ Log & $\\Delta$ Log & $\\Delta$ Log & $\\Delta$ Vacancy \\\\",
  " & Home \\% & Rate & Value & Pop. & Income & Rate \\\\",
  "\\hline"
)

# Extract results
coefs <- sapply(rdd_res, function(r) r$coef)
ses   <- sapply(rdd_res, function(r) r$se_robust)
pvs   <- sapply(rdd_res, function(r) r$pv)
bws   <- sapply(rdd_res, function(r) r$bw)
nls   <- sapply(rdd_res, function(r) r$n_left)
nrs   <- sapply(rdd_res, function(r) r$n_right)

# Coefficient row
coef_row <- paste0("RD Estimate & ",
  paste(sapply(seq_along(coefs), function(i) fmt_star(coefs[i], pvs[i])), collapse = " & "),
  " \\\\")
tab2_lines <- c(tab2_lines, coef_row)

# SE row
se_row <- paste0(" & ",
  paste(sprintf("(%.3f)", ses), collapse = " & "),
  " \\\\")
tab2_lines <- c(tab2_lines, se_row)

# Bandwidth row
bw_row <- paste0("Bandwidth (mi) & ",
  paste(sprintf("%.2f", bws), collapse = " & "),
  " \\\\")
tab2_lines <- c(tab2_lines, bw_row)

# N row
n_row <- paste0("Eff.\\ N (left/right) & ",
  paste(sprintf("%d/%d", nls, nrs), collapse = " & "),
  " \\\\")
tab2_lines <- c(tab2_lines, n_row)

tab2_lines <- c(tab2_lines,
  "\\hline",
  "Kernel & \\multicolumn{6}{c}{Triangular} \\\\",
  "Polynomial & \\multicolumn{6}{c}{Local linear} \\\\",
  "BW Selection & \\multicolumn{6}{c}{MSE-optimal (Calonico et al., 2014)} \\\\",
  "Clustering & \\multicolumn{6}{c}{County} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each column reports a separate spatial RDD estimate. The running variable is signed distance (miles) from the tract centroid to the nearest EF2+ tornado path edge, with negative values indicating the tract is inside the path. Outcomes are changes between ACS 2006--2010 and ACS 2018--2022. Robust bias-corrected inference following Calonico, Cattaneo, and Titiunik (2014). Standard errors clustered at the county level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_rdd_main.tex"))

# ============================================================================
# TABLE 3: OLS with State FE (comparison specification)
# ============================================================================
cat("Generating Table 3: OLS Estimates\n")

# Build OLS table manually
ols_models <- list(ols_res$mobile, ols_res$poverty, ols_res$value, ols_res$pop)
ols_coefs <- sapply(ols_models, function(m) coef(m)["treated"])
ols_ses <- sapply(ols_models, function(m) se(m)["treated"])
ols_pvs <- sapply(ols_models, function(m) pvalue(m)["treated"])
ols_ns <- sapply(ols_models, function(m) m$nobs)
ols_r2 <- sapply(ols_models, function(m) fitstat(m, "r2")[[1]])

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{OLS Estimates: Tornado Path Exposure and Neighborhood Changes}",
  "\\label{tab:ols}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & $\\Delta$ Mobile & $\\Delta$ Poverty & $\\Delta$ Log & $\\Delta$ Log \\\\",
  " & Home \\% & Rate & Value & Pop. \\\\",
  "\\hline",
  paste0("In Tornado Path & ",
    paste(sapply(seq_along(ols_coefs), function(i) fmt_star(ols_coefs[i], ols_pvs[i])), collapse = " & "),
    " \\\\"),
  paste0(" & ",
    paste(sprintf("(%.3f)", ols_ses), collapse = " & "),
    " \\\\"),
  "\\hline",
  paste0("Observations & ",
    paste(format(ols_ns, big.mark = ","), collapse = " & "),
    " \\\\"),
  paste0("$R^2$ & ",
    paste(sprintf("%.3f", ols_r2), collapse = " & "),
    " \\\\"),
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Distance controls & Quadratic & Quadratic & Quadratic & Quadratic \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} OLS estimates with state fixed effects and a quadratic polynomial in signed distance from the tornado path edge. Sample restricted to tracts within 2 miles of an EF2+ tornado path edge. Standard errors clustered at the county level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_ols.tex"))

# ============================================================================
# TABLE 4: Robustness — Bandwidth Sensitivity and Placebos
# ============================================================================
cat("Generating Table 4: Robustness\n")

# Panel A: Bandwidth sensitivity for mobile home share
bw_sens <- rob_res$bw_sensitivity
bw_df <- bind_rows(lapply(bw_sens, as.data.frame))

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Bandwidth Sensitivity and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Bandwidth sensitivity ($\\Delta$ Mobile Home Share)}} \\\\[3pt]",
  "Bandwidth (mi) & Estimate & SE & 95\\% CI & N & $p$-value \\\\",
  "\\hline"
)

for (i in seq_len(nrow(bw_df))) {
  tab4_lines <- c(tab4_lines,
    sprintf("%.1f & %s & %.3f & [%.3f, %.3f] & %s & %.3f \\\\",
            bw_df$bw[i], fmt_star(bw_df$coef[i], bw_df$pv[i]),
            bw_df$se[i], bw_df$ci_lower[i], bw_df$ci_upper[i],
            format(bw_df$n[i], big.mark = ","), bw_df$pv[i]))
}

# Panel B: Placebo tests
placebo <- rob_res$placebo

tab4_lines <- c(tab4_lines,
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel B: Placebo tests (RDD at path boundary)}} \\\\[3pt]",
  "Outcome & Estimate & SE & & & $p$-value \\\\",
  "\\hline"
)

for (nm in names(placebo)) {
  p <- placebo[[nm]]
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %s & %.3f & & & %.3f \\\\",
            p$outcome, fmt_star(p$coef, p$pv), p$se, p$pv))
}

# McCrary test
tab4_lines <- c(tab4_lines,
  "\\hline",
  sprintf("\\multicolumn{6}{l}{\\textit{Panel C: McCrary density test $p$-value: %.3f}} \\\\",
          rob_res$mccrary_pv),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Panel A varies the bandwidth for the main mobile home share outcome. Panel B tests for pre-tornado balance at the path boundary (pre-tornado levels should show no discontinuity) and for EF0--1 tornadoes (weak damage should show no effect on mobile home displacement). Panel C reports the McCrary (2008) density test for manipulation of the running variable. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))

# ============================================================================
# TABLE 5: Heterogeneity by pre-tornado mobile home share
# ============================================================================
cat("Generating Table 5: Heterogeneity\n")

het <- rob_res$heterogeneity

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity: Tornado Effects by Pre-Tornado Mobile Home Concentration}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & High Mobile Home & Low Mobile Home \\\\",
  " & Concentration & Concentration \\\\",
  "\\hline"
)

if (length(het) == 2) {
  tab5_lines <- c(tab5_lines,
    sprintf("RD Estimate ($\\Delta$ Mobile Home \\%%) & %s & %s \\\\",
            fmt_star(het$high$coef, het$high$pv),
            fmt_star(het$low$coef, het$low$pv)),
    sprintf(" & (%.3f) & (%.3f) \\\\", het$high$se, het$low$se),
    sprintf("Bandwidth (mi) & %.2f & %.2f \\\\", het$high$bw, het$low$bw),
    sprintf("Observations & %s & %s \\\\",
            format(het$high$n, big.mark = ","),
            format(het$low$n, big.mark = ","))
  )
}

tab5_lines <- c(tab5_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Sample split at the median pre-tornado mobile home share. High-concentration tracts had above-median mobile home shares before the nearest tornado event. Specifications follow Table~\\ref{tab:rdd_main}. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_heterogeneity.tex"))

# ============================================================================
# SDE TABLE (Appendix F1)
# ============================================================================
cat("Generating SDE Table\n")

# Compute SDE for main outcomes
sde_outcomes <- list(
  list(name = "Mobile Home Share", var = "delta_mobile_pct", pre_var = "mobile_pct_pre"),
  list(name = "Poverty Rate", var = "delta_poverty", pre_var = "poverty_rate_pre"),
  list(name = "Log Housing Value", var = "delta_log_value", pre_var = "log_value_pre")
)

sde_rows <- list()
for (o in sde_outcomes) {
  rdd <- rdd_res[[o$var]]
  if (is.null(rdd)) next

  beta <- rdd$coef
  se_beta <- rdd$se_robust
  sd_y <- sd(df[[o$pre_var]], na.rm = TRUE)

  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  classify <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )

  sde_rows[[length(sde_rows) + 1]] <- list(
    outcome = o$name, beta = beta, se = se_beta,
    sd_y = sd_y, sde = sde, se_sde = se_sde,
    classification = classify
  )
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does tornado-driven destruction of manufactured housing communities lead to permanent loss of affordable housing stock and displacement of low-income residents? ",
  "\\textbf{Policy mechanism:} EF2+ tornadoes physically destroy mobile home parks, creating cleared land that developers acquire and redevelop for higher-value uses rather than rebuilding affordable manufactured housing, permanently reducing the local affordable housing stock. ",
  "\\textbf{Outcome definition:} Change in census tract-level mobile home share (ACS B25024\\_010E / B25024\\_001E), poverty rate (B17001), and log median housing value (B25077) between pre- and post-tornado ACS 5-year estimates. ",
  "\\textbf{Treatment:} Binary; census tract centroid falls inside vs.\\ outside the geographic boundary of an EF2+ tornado path, using NOAA Storm Prediction Center path width data. ",
  "\\textbf{Data:} NOAA SPC 1950--2023 tornado database (EF2+ events 2000--2015) merged with ACS 5-year tract-level estimates (2006--2010 pre; 2018--2022 post) and Census TIGER/Line tract boundaries. ",
  "\\textbf{Method:} Spatial regression discontinuity using signed distance from tract centroid to tornado path edge as running variable; local linear polynomial with triangular kernel, MSE-optimal bandwidth, robust bias-corrected inference (Calonico et al., 2014), county-clustered standard errors. ",
  "\\textbf{Sample:} Census tracts within 5 miles of EF2+ tornado paths in tornado-prone US states, restricted to tracts with at least 50 housing units in the pre-period. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
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
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat(sprintf("Tables written to: %s\n", tables_dir))
