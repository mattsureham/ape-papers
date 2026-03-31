# 05_tables.R — Generate all LaTeX tables
# APEP-1200: Swiss Mass Immigration Initiative Close-Vote RDD

source("00_packages.R")

cat("=== Generating Tables ===\n")

analysis <- readRDS("../data/analysis.rds")
results <- readRDS("../data/main_results.rds")
robust_results <- readRDS("../data/robust_results.rds")

tables_dir <- "../tables"

# Helper: format with stars
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------

cat("\n--- Table 1: Summary Statistics ---\n")

# Compute by treatment group (above/below 50%)
stats_below <- analysis %>% filter(above_50 == 0)
stats_above <- analysis %>% filter(above_50 == 1)

compute_stat <- function(x) {
  c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE))
}

vars <- c("yes_pct", "turnout", "eligible", "pop_total_pre",
          "foreign_share_pre", "delta_foreign_share", "delta_pop_pct")
labels <- c("Yes share (\\%)", "Turnout (\\%)", "Eligible voters",
            "Population (pre)", "Foreign share, pre (\\%)",
            "$\\Delta$ Foreign share (pp)", "$\\Delta$ Population (\\%)")

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by MII Vote Outcome}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Below 50\\%} & \\multicolumn{2}{c}{Above 50\\%} & \\\\\n",
  "\\cline{2-3} \\cline{4-5}\n",
  " & Mean & SD & Mean & SD & Diff. \\\\\n",
  "\\hline\n"
)

for (i in seq_along(vars)) {
  sb <- compute_stat(stats_below[[vars[i]]])
  sa <- compute_stat(stats_above[[vars[i]]])
  diff <- sa["mean"] - sb["mean"]
  tab1_tex <- paste0(tab1_tex,
    labels[i], " & ",
    formatC(sb["mean"], format = "f", digits = 1), " & ",
    formatC(sb["sd"], format = "f", digits = 1), " & ",
    formatC(sa["mean"], format = "f", digits = 1), " & ",
    formatC(sa["sd"], format = "f", digits = 1), " & ",
    formatC(diff, format = "f", digits = 2), " \\\\\n"
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\n",
  "Municipalities & \\multicolumn{2}{c}{", nrow(stats_below), "} & ",
  "\\multicolumn{2}{c}{", nrow(stats_above), "} & \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Summary statistics by whether the municipality voted above or below 50\\% Yes on the Mass Immigration Initiative (February 9, 2014). ",
  "``Pre'' statistics are averaged over 2010--2013. $\\Delta$ Foreign share is the change in the municipal foreign population share (percentage points) from the pre-period (2010--2013) to the post-period (2015--2018). ",
  "Population data from BFS STATPOP; vote data from the Federal Statistical Office via swissdd.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("✓ Table 1 saved\n")

# ---------------------------------------------------------------
# Table 2: Main RDD Results
# ---------------------------------------------------------------

cat("\n--- Table 2: Main RDD Results ---\n")

extract_rdd <- function(rdd_obj) {
  list(
    conv_coef = rdd_obj$coef[1],
    conv_se = rdd_obj$se[1],
    conv_p = rdd_obj$pv[1],
    bc_coef = rdd_obj$coef[2],
    bc_se = rdd_obj$se[3],  # Robust SE for bias-corrected
    bc_p = rdd_obj$pv[3],
    bw = rdd_obj$bws[1, 1],
    n_eff = sum(rdd_obj$N_h)
  )
}

r1 <- extract_rdd(results$rdd_foreign)
r2 <- extract_rdd(results$rdd_pop)
r3 <- extract_rdd(results$rdd_foreign_pct)

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{RDD Estimates: Effect of Local MII Majority on Demographic Change}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & $\\Delta$ Foreign & $\\Delta$ Total & $\\Delta$ Foreign \\\\\n",
  " & Share (pp) & Population (\\%) & Population (\\%) \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Conventional}} \\\\\n",
  "[4pt]\n",
  "Above 50\\% Yes & ", fmt(r1$conv_coef), stars(r1$conv_p), " & ",
  fmt(r2$conv_coef), stars(r2$conv_p), " & ",
  fmt(r3$conv_coef), stars(r3$conv_p), " \\\\\n",
  " & (", fmt(r1$conv_se), ") & (", fmt(r2$conv_se), ") & (",
  fmt(r3$conv_se), ") \\\\\n",
  "[8pt]\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Bias-Corrected, Robust SE}} \\\\\n",
  "[4pt]\n",
  "Above 50\\% Yes & ", fmt(r1$bc_coef), stars(r1$bc_p), " & ",
  fmt(r2$bc_coef), stars(r2$bc_p), " & ",
  fmt(r3$bc_coef), stars(r3$bc_p), " \\\\\n",
  " & (", fmt(r1$bc_se), ") & (", fmt(r2$bc_se), ") & (",
  fmt(r3$bc_se), ") \\\\\n",
  "[4pt]\n",
  "\\hline\n",
  "Bandwidth (pp) & ", fmt(r1$bw, 1), " & ", fmt(r2$bw, 1), " & ",
  fmt(r3$bw, 1), " \\\\\n",
  "Effective N & ", r1$n_eff, " & ", r2$n_eff, " & ", r3$n_eff, " \\\\\n",
  "Kernel & Triangular & Triangular & Triangular \\\\\n",
  "Polynomial & Linear & Linear & Linear \\\\\n",
  "Clustered SE & Canton & Canton & Canton \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Local polynomial RDD estimates using \\texttt{rdrobust} with MSE-optimal bandwidth selection. ",
  "The running variable is the municipal yes-share on the February 2014 Mass Immigration Initiative, centered at 50\\%. ",
  "Panel A reports conventional estimates; Panel B reports bias-corrected point estimates with robust standard errors (Cattaneo, Idrobo, and Titiunik 2020). ",
  "Standard errors clustered at the canton level in parentheses. ",
  "$\\Delta$ Foreign share is the change in the municipal foreign population share (pp) from 2010--2013 to 2015--2018. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("✓ Table 2 saved\n")

# ---------------------------------------------------------------
# Table 3: Robustness
# ---------------------------------------------------------------

cat("\n--- Table 3: Robustness ---\n")

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness of the Foreign Share RDD Estimate}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Specification & Coef. & Robust SE & $p$-value & BW (pp) \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Baseline and Covariates}} \\\\\n",
  "[4pt]\n",
  "Baseline (triangular, $p=1$) & ",
  fmt(results$rdd_foreign$coef[2]), stars(results$rdd_foreign$pv[3]),
  " & ", fmt(results$rdd_foreign$se[3]),
  " & ", fmt(results$rdd_foreign$pv[3]),
  " & ", fmt(results$rdd_foreign$bws[1,1], 1), " \\\\\n",
  "With covariates & ",
  fmt(robust_results$with_covariates$coef), stars(robust_results$with_covariates$pval),
  " & ", fmt(robust_results$with_covariates$se),
  " & ", fmt(robust_results$with_covariates$pval),
  " & --- \\\\\n",
  "[8pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Alternative Kernels}} \\\\\n",
  "[4pt]\n"
)

for (k in names(robust_results$kernels)) {
  kr <- robust_results$kernels[[k]]
  lab <- paste0(toupper(substr(k, 1, 1)), substr(k, 2, nchar(k)))
  tab3_tex <- paste0(tab3_tex,
    lab, " & ",
    fmt(kr$coef), stars(kr$pval), " & ",
    fmt(kr$se), " & ", fmt(kr$pval), " & ",
    fmt(kr$bw, 1), " \\\\\n"
  )
}

tab3_tex <- paste0(tab3_tex,
  "[8pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Polynomial Order}} \\\\\n",
  "[4pt]\n"
)

for (p_name in names(robust_results$polynomial)) {
  pr <- robust_results$polynomial[[p_name]]
  tab3_tex <- paste0(tab3_tex,
    "Order $p = ", pr$order, "$ & ",
    fmt(pr$coef), stars(pr$pval), " & ",
    fmt(pr$se), " & ", fmt(pr$pval), " & ",
    fmt(pr$bw, 1), " \\\\\n"
  )
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications report bias-corrected RDD estimates with robust standard errors. ",
  "Covariates include log pre-period population, pre-period foreign share, and voter turnout. ",
  "MSE-optimal bandwidth selection throughout. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_robustness.tex"))
cat("✓ Table 3 saved\n")

# ---------------------------------------------------------------
# Table 4: Validity — Covariate Balance and Placebo Tests
# ---------------------------------------------------------------

cat("\n--- Table 4: Validity ---\n")

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Validity: Covariate Balance, Placebo Cutoffs, and Placebo Outcome}\n",
  "\\label{tab:validity}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & & Robust & & \\\\\n",
  " & Coef. & SE & $p$-value & Test \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Covariate Balance at Threshold}} \\\\\n",
  "[4pt]\n"
)

bal_labels <- c(
  pop_total_pre = "Population (pre)",
  foreign_share_pre = "Foreign share (pre, \\%)",
  turnout = "Turnout (\\%)",
  eligible = "Eligible voters"
)

for (cov in names(results$balance_results)) {
  br <- results$balance_results[[cov]]
  lab <- bal_labels[cov]
  tab4_tex <- paste0(tab4_tex,
    lab, " & ",
    fmt(br$coef), " & ", fmt(br$se), " & ",
    fmt(br$pval), " & Balance \\\\\n"
  )
}

tab4_tex <- paste0(tab4_tex,
  "[8pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Placebo Cutoffs}} \\\\\n",
  "[4pt]\n"
)

for (pc_name in names(robust_results$placebo_cutoffs)) {
  pcr <- robust_results$placebo_cutoffs[[pc_name]]
  tab4_tex <- paste0(tab4_tex,
    "Cutoff at ", pcr$cutoff, "\\% & ",
    fmt(pcr$coef), stars(pcr$pval), " & ",
    fmt(pcr$se), " & ", fmt(pcr$pval), " & Placebo \\\\\n"
  )
}

tab4_tex <- paste0(tab4_tex,
  "[8pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo Outcome}} \\\\\n",
  "[4pt]\n",
  "$\\Delta$ Foreign share (2010--2013) & ",
  fmt(robust_results$placebo_outcome$coef), stars(robust_results$placebo_outcome$pval),
  " & ", fmt(robust_results$placebo_outcome$se),
  " & ", fmt(robust_results$placebo_outcome$pval),
  " & Pre-trend \\\\\n",
  "[4pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel D: Manipulation Test}} \\\\\n",
  "[4pt]\n",
  "McCrary density & --- & --- & ",
  fmt(results$density_test$test$p_jk), " & Density \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A tests whether pre-determined covariates are smooth through the 50\\% threshold using RDD estimation. ",
  "Panel B tests for effects at false cutoffs (40\\%, 45\\%, 55\\%, 60\\%). ",
  "Panel C uses the pre-treatment change in foreign share (2010--2011 to 2012--2013) as a placebo outcome. ",
  "Panel D reports the McCrary (2008)/Cattaneo, Jansson, and Ma (2020) density manipulation test. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_validity.tex"))
cat("✓ Table 4 saved\n")

# ---------------------------------------------------------------
# Table F1: Standardized Effect Size (SDE) — Appendix
# ---------------------------------------------------------------

cat("\n--- Table F1: SDE ---\n")

# Compute SDE: beta_hat / SD(Y)
sd_y_foreign <- sd(analysis$delta_foreign_share, na.rm = TRUE)
sd_y_pop <- sd(analysis$delta_pop_pct, na.rm = TRUE)
sd_y_foreign_pct <- sd(analysis$delta_foreign_pct, na.rm = TRUE)

classify <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_data <- tibble(
  Outcome = c("Foreign share change (pp)", "Total pop. change (\\%)",
              "Foreign pop. change (\\%)"),
  beta = c(results$rdd_foreign$coef[2], results$rdd_pop$coef[2],
           results$rdd_foreign_pct$coef[2]),
  se = c(results$rdd_foreign$se[3], results$rdd_pop$se[3],
         results$rdd_foreign_pct$se[3]),
  sd_y = c(sd_y_foreign, sd_y_pop, sd_y_foreign_pct)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = sapply(sde, classify)
  )

# Panel B: Heterogeneous by urban/rural
# Split by population size: top quartile vs bottom quartile
pop_q75 <- quantile(analysis$pop_total_pre, 0.75, na.rm = TRUE)
pop_q25 <- quantile(analysis$pop_total_pre, 0.25, na.rm = TRUE)

urban <- analysis %>% filter(pop_total_pre >= pop_q75)
rural <- analysis %>% filter(pop_total_pre <= pop_q25)

rdd_urban <- tryCatch(
  rdrobust(y = urban$delta_foreign_share, x = urban$yes_margin, c = 0,
           kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL)

rdd_rural <- tryCatch(
  rdrobust(y = rural$delta_foreign_share, x = rural$yes_margin, c = 0,
           kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL)

sde_hetero <- tibble()
if (!is.null(rdd_urban)) {
  sd_y_u <- sd(urban$delta_foreign_share, na.rm = TRUE)
  sde_u <- rdd_urban$coef[2] / sd_y_u
  sde_hetero <- bind_rows(sde_hetero, tibble(
    Outcome = "Foreign share (urban Q4)",
    beta = rdd_urban$coef[2], se = rdd_urban$se[3], sd_y = sd_y_u,
    sde = sde_u, se_sde = rdd_urban$se[3] / sd_y_u,
    classification = classify(sde_u)
  ))
}
if (!is.null(rdd_rural)) {
  sd_y_r <- sd(rural$delta_foreign_share, na.rm = TRUE)
  sde_r <- rdd_rural$coef[2] / sd_y_r
  sde_hetero <- bind_rows(sde_hetero, tibble(
    Outcome = "Foreign share (rural Q1)",
    beta = rdd_rural$coef[2], se = rdd_rural$se[3], sd_y = sd_y_r,
    sde = sde_r, se_sde = rdd_rural$se[3] / sd_y_r,
    classification = classify(sde_r)
  ))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does a municipality narrowly voting in favor of the 2014 Mass Immigration Initiative (which mandated caps on EU immigration) cause a differential reduction in its foreign population share relative to a municipality narrowly voting against? ",
  "\\textbf{Policy mechanism:} The February 2014 initiative threatened to end the bilateral Free Movement of Persons Agreement with the EU, creating a three-year policy uncertainty window (2014--2017) during which municipalities with stronger anti-immigration mandates may have become less attractive to foreign residents and cross-border workers through local signaling, employer caution, or migrant sorting. ",
  "\\textbf{Outcome definition:} Change in the municipal foreign population share (percentage points), computed as the difference between the mean share in 2015--2018 and the mean share in 2010--2013, using BFS STATPOP permanent resident population by citizenship. ",
  "\\textbf{Treatment:} Binary indicator for the municipality's yes-share exceeding 50\\% on the Mass Immigration Initiative, with the municipal yes-share as a continuous forcing variable in a regression discontinuity design. ",
  "\\textbf{Data:} BFS STATPOP municipal population by citizenship (2010--2019) merged with municipal vote results from the Federal Statistical Office (2,098 municipalities), via the PXWeb API and swissdd R package. ",
  "\\textbf{Method:} Local polynomial RDD (rdrobust) with MSE-optimal bandwidth, triangular kernel, bias-corrected estimates with robust standard errors (Cattaneo, Idrobo, and Titiunik 2020), clustered at the canton level. ",
  "\\textbf{Sample:} 2,098 Swiss municipalities with matched vote and population data; effective sample within optimal bandwidth varies by specification (approximately 600--1,400 municipalities). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-sectional ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "[4pt]\n"
)

for (i in 1:nrow(sde_data)) {
  r <- sde_data[i, ]
  tabF1_tex <- paste0(tabF1_tex,
    r$Outcome, " & ",
    fmt(r$beta, 2), " & ", fmt(r$se, 2), " & ",
    fmt(r$sd_y, 2), " & ", fmt(r$sde, 3), " & ",
    fmt(r$se_sde, 3), " & ", r$classification, " \\\\\n"
  )
}

if (nrow(sde_hetero) > 0) {
  tabF1_tex <- paste0(tabF1_tex,
    "[8pt]\n",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (urban vs.\\ rural)}} \\\\\n",
    "[4pt]\n"
  )
  for (i in 1:nrow(sde_hetero)) {
    r <- sde_hetero[i, ]
    tabF1_tex <- paste0(tabF1_tex,
      r$Outcome, " & ",
      fmt(r$beta, 2), " & ", fmt(r$se, 2), " & ",
      fmt(r$sd_y, 2), " & ", fmt(r$sde, 3), " & ",
      fmt(r$se_sde, 3), " & ", r$classification, " \\\\\n"
    )
  }
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("✓ Table F1 (SDE) saved\n")

cat("\n=== All tables generated ===\n")
