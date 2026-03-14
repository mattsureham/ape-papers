## 05_tables.R — Generate all LaTeX tables
## APEP Paper apep_0669: Capitalization of Reproductive Rights

source("00_packages.R")

cat("=== Generating Tables ===\n")

# Load results
main_results <- readRDS("../data/main_results.rds")
stl_panel <- readRDS("../data/stl_panel.rds")
bw_results <- readRDS("../data/bw_results.rds")

analysis_df <- stl_panel %>%
  filter(pre_dobbs == 1 | post_dobbs == 1)

# ----------------------------------------------------------------
# Table 1: Summary Statistics
# ----------------------------------------------------------------
cat("--- Table 1: Summary Statistics ---\n")

# Compute stats by state and period
stats_by_group <- analysis_df %>%
  mutate(
    side = ifelse(ban_state == 1, "Missouri (Ban)", "Illinois (Protection)"),
    period = ifelse(post_dobbs == 1, "Post-Dobbs", "Pre-Dobbs")
  ) %>%
  group_by(side) %>%
  summarise(
    `N ZIPs` = n_distinct(zip),
    `Mean ZHVI (\\$)` = mean(zhvi, na.rm = TRUE),
    `SD ZHVI (\\$)` = sd(zhvi, na.rm = TRUE),
    `Mean log ZHVI` = mean(log_zhvi, na.rm = TRUE),
    `SD log ZHVI` = sd(log_zhvi, na.rm = TRUE),
    `Mean Dist. (km)` = mean(dist_km, na.rm = TRUE),
    `Observations` = n(),
    .groups = "drop"
  )

# Generate LaTeX
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: St. Louis MSA}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "& Missouri (Ban) & Illinois (Protection) \\\\",
  "\\midrule"
)

for (i in 1:nrow(stats_by_group)) {
  row <- stats_by_group[i, ]
  if (row$side == "Missouri (Ban)") {
    mo_vals <- row
  } else {
    il_vals <- row
  }
}

tab1_lines <- c(tab1_lines,
  sprintf("N ZIPs & %d & %d \\\\", mo_vals$`N ZIPs`, il_vals$`N ZIPs`),
  sprintf("Mean ZHVI (\\$) & %s & %s \\\\",
          formatC(mo_vals$`Mean ZHVI (\\$)`, format = "f", digits = 0, big.mark = ","),
          formatC(il_vals$`Mean ZHVI (\\$)`, format = "f", digits = 0, big.mark = ",")),
  sprintf("SD ZHVI (\\$) & %s & %s \\\\",
          formatC(mo_vals$`SD ZHVI (\\$)`, format = "f", digits = 0, big.mark = ","),
          formatC(il_vals$`SD ZHVI (\\$)`, format = "f", digits = 0, big.mark = ",")),
  sprintf("Mean log ZHVI & %.3f & %.3f \\\\",
          mo_vals$`Mean log ZHVI`, il_vals$`Mean log ZHVI`),
  sprintf("SD log ZHVI & %.3f & %.3f \\\\",
          mo_vals$`SD log ZHVI`, il_vals$`SD log ZHVI`),
  sprintf("Mean Dist. to Border (km) & %.1f & %.1f \\\\",
          mo_vals$`Mean Dist. (km)`, il_vals$`Mean Dist. (km)`),
  sprintf("Observations & %s & %s \\\\",
          formatC(mo_vals$Observations, big.mark = ","),
          formatC(il_vals$Observations, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Unit of observation is ZIP code $\\times$ month. Sample includes all ZIP codes in the St. Louis MSA (CBSA 41180) with Zillow Home Value Index data from January 2020 through December 2024, excluding June 2022 (transition month). ZHVI is the Zillow Home Value Index for all homes (SFR and condos), smoothed and seasonally adjusted. Distance is from ZIP centroid to the nearest point on the Missouri-Illinois state border.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Table 1 written\n")

# ----------------------------------------------------------------
# Table 2: Main Diff-in-Disc Results
# ----------------------------------------------------------------
cat("--- Table 2: Main Results ---\n")

m1 <- main_results$m1
m2 <- main_results$m2
m3 <- main_results$m3
m4 <- main_results$m4
m5 <- main_results$m5

# Extract coefficients
extract_coef <- function(model, var = "treat_post") {
  cf <- coef(model)[var]
  se <- sqrt(diag(vcov(model)))[var]
  pval <- 2 * pnorm(-abs(cf / se))
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
  list(coef = cf, se = se, pval = pval, stars = stars,
       n = model$nobs, n_zip = length(unique(model$fixef_id$zip)))
}

models <- list(m1, m2, m3, m4, m5)
labels <- c("Basic DiD", "Linear dist.", "Quadratic dist.", "30km BW", "15km BW")

# Build table
tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Dobbs on Home Values: St. Louis MSA}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste0("& (1) & (2) & (3) & (4) & (5) \\\\"),
  paste0("& ", paste(labels, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Coefficient row
coef_vals <- sapply(models, function(m) {
  r <- extract_coef(m)
  sprintf("%.4f%s", r$coef, r$stars)
})
tab2_lines <- c(tab2_lines,
  paste0("Missouri $\\times$ Post-Dobbs & ", paste(coef_vals, collapse = " & "), " \\\\"))

# SE row
se_vals <- sapply(models, function(m) {
  r <- extract_coef(m)
  sprintf("(%.4f)", r$se)
})
tab2_lines <- c(tab2_lines,
  paste0("& ", paste(se_vals, collapse = " & "), " \\\\"),
  "\\\\")

# N row
n_vals <- sapply(models, function(m) formatC(m$nobs, big.mark = ","))
tab2_lines <- c(tab2_lines,
  paste0("Observations & ", paste(n_vals, collapse = " & "), " \\\\"))

# ZIP FE row
tab2_lines <- c(tab2_lines,
  "ZIP FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Distance $\\times$ Post & No & Linear & Quadratic & Linear & Linear \\\\",
  "Bandwidth & Full & Full & Full & 30km & 15km \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Dependent variable is log(ZHVI). The coefficient on Missouri $\\times$ Post-Dobbs estimates the change in the Missouri-Illinois home value gap after the Dobbs decision (July 2022). Standard errors clustered at the ZIP level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Columns (1)--(3) use all ZIPs in the St. Louis MSA. Column (4) restricts to ZIPs within 30km of the state border. Column (5) restricts to ZIPs within 15km. ",
  "Distance controls interact signed distance from the border with a post-Dobbs indicator."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Table 2 written\n")

# ----------------------------------------------------------------
# Table 3: Bandwidth Sensitivity
# ----------------------------------------------------------------
cat("--- Table 3: Bandwidth Sensitivity ---\n")

if (length(bw_results) > 0) {
  tab3_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Bandwidth Sensitivity}",
    "\\label{tab:bandwidth}",
    "\\begin{threeparttable}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Bandwidth & $\\hat{\\beta}$ & SE & N ZIPs & Observations \\\\",
    "\\midrule"
  )

  for (bw_name in names(bw_results)) {
    m <- bw_results[[bw_name]]
    r <- extract_coef(m)
    tab3_lines <- c(tab3_lines,
      sprintf("%s & %.4f%s & (%.4f) & %d & %s \\\\",
              bw_name, r$coef, r$stars, r$se,
              length(unique(m$fixef_id$zip)),
              formatC(m$nobs, big.mark = ",")))
  }

  tab3_lines <- c(tab3_lines,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Dependent variable is log(ZHVI). All specifications include ZIP and month fixed effects with linear distance $\\times$ post control. Standard errors clustered at the ZIP level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\end{table}"
  )

  writeLines(tab3_lines, "../tables/tab3_bandwidth.tex")
  cat("  Table 3 written\n")
}

# ----------------------------------------------------------------
# Table 4: Kansas City Replication
# ----------------------------------------------------------------
cat("--- Table 4: KC Replication ---\n")

kc_results_file <- "../data/kc_results.rds"
if (file.exists(kc_results_file)) {
  kc_res <- readRDS(kc_results_file)

  tab4_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Replication: Kansas City MSA (Missouri-Kansas Border)}",
    "\\label{tab:kc}",
    "\\begin{threeparttable}",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    "& (1) & (2) \\\\",
    "& Basic DiD & Linear dist. \\\\",
    "\\midrule"
  )

  for (i in seq_along(kc_res)) {
    m <- kc_res[[i]]
    r <- extract_coef(m)
    if (i == 1) {
      tab4_lines <- c(tab4_lines,
        sprintf("Missouri $\\times$ Post-Dobbs & %.4f%s & ", r$coef, r$stars))
    } else {
      tab4_lines[length(tab4_lines)] <- paste0(
        tab4_lines[length(tab4_lines)],
        sprintf("%.4f%s \\\\", r$coef, r$stars))
    }
  }

  se1 <- extract_coef(kc_res[[1]])$se
  se2 <- extract_coef(kc_res[[2]])$se
  tab4_lines <- c(tab4_lines,
    sprintf("& (%.4f) & (%.4f) \\\\", se1, se2),
    "\\\\",
    sprintf("Observations & %s & %s \\\\",
            formatC(kc_res[[1]]$nobs, big.mark = ","),
            formatC(kc_res[[2]]$nobs, big.mark = ",")),
    "ZIP FE & Yes & Yes \\\\",
    "Month FE & Yes & Yes \\\\",
    "Distance $\\times$ Post & No & Linear \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Dependent variable is log(ZHVI). The Kansas City MSA spans the Missouri-Kansas border. Missouri activated a trigger-law abortion ban on June 24, 2022; Kansas voters rejected a constitutional amendment to remove abortion protections on August 2, 2022. Standard errors clustered at the ZIP level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\end{table}"
  )

  writeLines(tab4_lines, "../tables/tab4_kc.tex")
  cat("  Table 4 written\n")
} else {
  cat("  KC results not available, skipping Table 4\n")
}

# ----------------------------------------------------------------
# Table 5 (Appendix): Placebo Tests
# ----------------------------------------------------------------
cat("--- Table 5: Placebo Tests ---\n")

temporal_file <- "../data/temporal_placebo.rds"
placebo_file <- "../data/placebo_results.rds"
leak_file <- "../data/leak_results.rds"

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Placebo and Anticipation Tests}",
  "\\label{tab:placebo}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Test & $\\hat{\\beta}$ & SE & Observations \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Temporal placebo}} \\\\"
)

if (file.exists(temporal_file)) {
  m_temp <- readRDS(temporal_file)
  r <- extract_coef(m_temp, "fake_treat")
  tab5_lines <- c(tab5_lines,
    sprintf("Fake Dobbs = January 2021 & %.4f%s & (%.4f) & %s \\\\",
            r$coef, r$stars, r$se, formatC(m_temp$nobs, big.mark = ",")))
}

if (file.exists(leak_file)) {
  m_leak <- readRDS(leak_file)
  r <- extract_coef(m_leak, "leak_treat")
  tab5_lines <- c(tab5_lines,
    sprintf("Politico leak = May 2022 & %.4f%s & (%.4f) & %s \\\\",
            r$coef, r$stars, r$se, formatC(m_leak$nobs, big.mark = ",")))
}

tab5_lines <- c(tab5_lines,
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Spatial placebos (shifted border)}} \\\\"
)

if (file.exists(placebo_file)) {
  placebo_res <- readRDS(placebo_file)
  for (shift in names(placebo_res)) {
    m <- placebo_res[[shift]]
    r <- extract_coef(m, "placebo_treat")
    tab5_lines <- c(tab5_lines,
      sprintf("Border shifted %s km & %.4f%s & (%.4f) & %s \\\\",
              shift, r$coef, r$stars, r$se,
              formatC(m$nobs, big.mark = ",")))
  }
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A: temporal placebo assigns a fake treatment date of January 2021, using only pre-Dobbs data (January 2020--May 2022). The leak test uses the Politico draft leak date (May 2, 2022) as the treatment, restricting to July 2021--June 2022. Panel B: spatial placebos shift the state border by the indicated distance (negative = east into Illinois, positive = west into Missouri) and re-estimate the diff-in-disc. All specifications include ZIP and month FEs with linear distance $\\times$ post controls, standard errors clustered at ZIP level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_placebo.tex")
cat("  Table 5 written\n")

# ----------------------------------------------------------------
# SDE Table (Appendix F1)
# ----------------------------------------------------------------
cat("--- SDE Table ---\n")

m_preferred <- main_results$m2  # Model 2: DiD + linear distance
sd_y <- main_results$sd_log_zhvi

beta <- coef(m_preferred)["treat_post"]
se_beta <- sqrt(diag(vcov(m_preferred)))["treat_post"]
sde <- beta / sd_y
se_sde <- se_beta / sd_y

classify <- function(s) {
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

sde_class <- classify(sde)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("log(ZHVI) & DiD + linear dist. & %.4f & --- & %.4f & %.4f & %.4f & %s \\\\",
          beta, sd_y, sde, se_sde, sde_class),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  paste0("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
  "to facilitate cross-study comparison of treatment effect magnitudes. ",
  "For this binary (0/1) treatment, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) ",
  "column is marked ``---''. ",
  "SD($Y$) is the unconditional standard deviation of log(ZHVI) from the full analysis sample. ",
  "\\textbf{Research question:} Does Missouri's trigger-law abortion ban reduce home values relative to neighboring Illinois? ",
  "\\textbf{Treatment:} Binary; ZIP code located in Missouri (ban state) vs. Illinois (protection state). ",
  sprintf("\\textbf{Data:} Zillow ZHVI, 2020--2024, ZIP-month panel, N = %s. ",
          formatC(m_preferred$nobs, big.mark = ",")),
  "\\textbf{Method:} Geographic diff-in-disc with ZIP and month FE, linear distance $\\times$ post control, ZIP-clustered SEs. ",
  "\\textbf{Sample:} St. Louis MSA (CBSA 41180). ",
  "Classification thresholds (7 categories): ",
  "large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), ",
  "small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), ",
  "small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), ",
  "large positive ($> 0.15$). ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}"),
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("  SDE table written\n")

cat("\n=== All tables generated ===\n")
