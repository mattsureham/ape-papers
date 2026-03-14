## 05_tables.R — Generate all tables including SDE
## apep_0668: The Pollinator Penalty

source("code/00_packages.R")

cat("=== Generating Tables ===\n")

panel <- readRDS("data/analysis_panel.rds")
models <- readRDS("data/model_results.rds")
robust <- readRDS("data/robustness_results.rds")

# ==================================================================
# TABLE 1: Summary Statistics
# ==================================================================

cat("\n--- Table 1: Summary Statistics ---\n")

# Overall stats
stats_overall <- panel |>
  summarise(
    `Yield (100 kg/ha)` = sprintf("%.1f & %.1f & %.1f & %.1f",
      mean(yield, na.rm=T), sd(yield, na.rm=T),
      min(yield, na.rm=T), max(yield, na.rm=T)),
    `Log yield` = sprintf("%.2f & %.2f & %.2f & %.2f",
      mean(log_yield, na.rm=T), sd(log_yield, na.rm=T),
      min(log_yield, na.rm=T), max(log_yield, na.rm=T)),
    `PDR` = sprintf("%.2f & %.2f & %.2f & %.2f",
      mean(pdr), sd(pdr), min(pdr), max(pdr)),
    `Harvested area (1000 ha)` = sprintf("%.1f & %.1f & %.1f & %.1f",
      mean(area_ha, na.rm=T), sd(area_ha, na.rm=T),
      min(area_ha, na.rm=T), max(area_ha, na.rm=T)),
    `Post-ban (2019+)` = sprintf("%.2f & %.2f & 0 & 1",
      mean(post_ban), sd(post_ban)),
    `Derogation country` = sprintf("%.2f & %.2f & 0 & 1",
      mean(derog), sd(derog))
  )

# Build LaTeX table manually for precision
n_obs <- nrow(panel)
n_countries <- n_distinct(panel$country)
n_crops <- n_distinct(panel$crop_code)

sumstat_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  sprintf("\\begin{tabular}{l S[table-format=4.1] S[table-format=4.1] S[table-format=4.1] S[table-format=5.1]}"),
  "\\toprule",
  "Variable & {Mean} & {Std.\\ Dev.} & {Min} & {Max} \\\\",
  "\\midrule"
)

# Compute stats row by row
add_row <- function(name, vec) {
  vec <- vec[!is.na(vec)]
  sprintf("%s & %.1f & %.1f & %.1f & %.1f \\\\",
          name, mean(vec), sd(vec), min(vec), max(vec))
}

sumstat_lines <- c(sumstat_lines,
  add_row("Yield (100 kg/ha)", panel$yield),
  add_row("Log yield", panel$log_yield),
  sprintf("PDR (pollinator dependence) & %.2f & %.2f & %.2f & %.2f \\\\",
    mean(panel$pdr), sd(panel$pdr), min(panel$pdr), max(panel$pdr)),
  add_row("Harvested area (1000 ha)", panel$area_ha),
  sprintf("Post-ban (2019+) & %.2f & %.2f & 0 & 1 \\\\",
    mean(panel$post_ban), sd(panel$post_ban)),
  sprintf("Derogation country & %.2f & %.2f & 0 & 1 \\\\",
    mean(panel$derog), sd(panel$derog)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item Notes: N = %s observations across %d EU countries, %d crops, and years 2000--2023. Yield is measured in 100 kg per hectare (Eurostat \\texttt{apro\\_cpsh1}). Pollinator dependence ratio (PDR) from Klein et al.\\ (2007): 0 for wind/self-pollinated crops (wheat, barley, maize), 0.05--0.25 for moderately dependent crops (rapeseed, soybeans, tomatoes), 0.65 for highly dependent crops (sunflower, apples, pears, cherries). Derogation country indicates the 11 EU member states that granted Article 53 emergency authorizations for neonicotinoid use on sugar beet during 2019--2022.",
    formatC(n_obs, format = "d", big.mark = ","), n_countries, n_crops),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sumstat_lines, "tables/tab1_summary.tex")
cat("Wrote tables/tab1_summary.tex\n")

# ==================================================================
# TABLE 2: Main DDD Results
# ==================================================================

cat("\n--- Table 2: Main Results ---\n")

# Extract results from models
extract_coef <- function(model, label) {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model)))
  pv <- summary(model)$coeftable[, 4]
  n <- nobs(model)
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  list(coef = cf, se = se, pval = pv, n = n, stars = stars, label = label)
}

r1 <- extract_coef(models$m1, "DDD (cont. PDR)")
r2 <- extract_coef(models$m2, "DD (Post×PDR)")
r4 <- extract_coef(models$m4, "DDD (binary PDR)")
r3 <- extract_coef(models$m3, "Sugar beet DD")

# Build LaTeX
main_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of the Neonicotinoid Ban on Crop Yields}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & DDD & DD & DDD Binary & Sugar Beet \\\\",
  "\\midrule",
  sprintf("Post $\\times$ PDR $\\times$ Derog & %s%s & & & \\\\",
    formatC(r1$coef[1], format = "f", digits = 4), r1$stars[1]),
  sprintf(" & (%s) & & & \\\\", formatC(r1$se[1], format = "f", digits = 4)),
  " \\\\",
  sprintf("Post $\\times$ PDR & & %s%s & & \\\\",
    formatC(r2$coef[1], format = "f", digits = 4), r2$stars[1]),
  sprintf(" & & (%s) & & \\\\", formatC(r2$se[1], format = "f", digits = 4)),
  " \\\\",
  sprintf("Post $\\times$ High PDR $\\times$ Derog & & & %s%s & \\\\",
    formatC(r4$coef[1], format = "f", digits = 4), r4$stars[1]),
  sprintf(" & & & (%s) & \\\\", formatC(r4$se[1], format = "f", digits = 4)),
  " \\\\",
  sprintf("Post $\\times$ Derog & & & & %s%s \\\\",
    formatC(r3$coef[1], format = "f", digits = 4), r3$stars[1]),
  sprintf(" & & & & (%s) \\\\", formatC(r3$se[1], format = "f", digits = 4)),
  "\\midrule",
  "Country $\\times$ Crop FE & Yes & Yes & Yes & Yes \\\\",
  "Crop $\\times$ Year FE & Yes & & Yes & \\\\",
  "Country $\\times$ Year FE & Yes & Yes & Yes & \\\\",
  "Country FE & & & & Yes \\\\",
  "Year FE & & & & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    formatC(r1$n, format = "d", big.mark = ","),
    formatC(r2$n, format = "d", big.mark = ","),
    formatC(r4$n, format = "d", big.mark = ","),
    formatC(r3$n, format = "d", big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Standard errors clustered at the country level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Dependent variable is log yield (100 kg/ha). Column (1): triple-difference with continuous PDR (Klein et al.\\ 2007). Column (2): difference-in-differences with continuous PDR across all 27 EU countries. Column (3): DDD with binary PDR indicator (PDR $>$ 0). Column (4): sugar beet only, comparing derogation vs.\\ non-derogation countries. All specifications include country$\\times$crop fixed effects. Columns (1) and (3) additionally include crop$\\times$year and country$\\times$year fixed effects, which absorb all two-way interactions.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(main_lines, "tables/tab2_main.tex")
cat("Wrote tables/tab2_main.tex\n")

# ==================================================================
# TABLE 3: Robustness Checks
# ==================================================================

cat("\n--- Table 3: Robustness ---\n")

rob_placebo  <- extract_coef(robust$r2_placebo, "Placebo 2014")
rob_altclust <- extract_coef(robust$r3_altcluster, "Country×crop cluster")
rob_nosugar  <- extract_coef(robust$r4_no_sugar, "Excl. sugar beet")
rob_weight   <- extract_coef(robust$r5_weighted, "Area-weighted")

rob_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Placebo 2014 & Alt.\\ Cluster & Excl.\\ Sugar Beet & Area-Weighted \\\\",
  "\\midrule",
  sprintf("Post $\\times$ PDR $\\times$ Derog & %s%s & %s%s & %s%s & %s%s \\\\",
    formatC(rob_placebo$coef[1], format = "f", digits = 4), rob_placebo$stars[1],
    formatC(rob_altclust$coef[1], format = "f", digits = 4), rob_altclust$stars[1],
    formatC(rob_nosugar$coef[1], format = "f", digits = 4), rob_nosugar$stars[1],
    formatC(rob_weight$coef[1], format = "f", digits = 4), rob_weight$stars[1]),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    formatC(rob_placebo$se[1], format = "f", digits = 4),
    formatC(rob_altclust$se[1], format = "f", digits = 4),
    formatC(rob_nosugar$se[1], format = "f", digits = 4),
    formatC(rob_weight$se[1], format = "f", digits = 4)),
  "\\midrule",
  "Country $\\times$ Crop FE & Yes & Yes & Yes & Yes \\\\",
  "Crop $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  "Country $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    formatC(rob_placebo$n, format = "d", big.mark = ","),
    formatC(rob_altclust$n, format = "d", big.mark = ","),
    formatC(rob_nosugar$n, format = "d", big.mark = ","),
    formatC(rob_weight$n, format = "d", big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Standard errors in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (1): placebo test using 2014 as fake treatment year on pre-ban data (2006--2018). Column (2): standard errors clustered at country$\\times$crop level. Column (3): excludes sugar beet (the primary derogation crop). Column (4): observations weighted by harvested area.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(rob_lines, "tables/tab3_robust.tex")
cat("Wrote tables/tab3_robust.tex\n")

# ==================================================================
# TABLE 4: Mechanism — Crop Group Heterogeneity
# ==================================================================

cat("\n--- Table 4: Mechanism ---\n")

mech_cereals  <- extract_coef(robust$r7a_cereals, "Cereals")
mech_oilseeds <- extract_coef(robust$r7b_oilseeds, "Oilseeds")

# Fruit subsample
panel_fruit <- panel |> filter(crop_group == "Fruit")
if (nrow(panel_fruit) > 50) {
  m_fruit <- feols(
    log_yield ~ post_ban:derog | country + as.factor(year),
    data = panel_fruit,
    cluster = ~country
  )
  mech_fruit <- extract_coef(m_fruit, "Fruit")
} else {
  mech_fruit <- list(coef = NA, se = NA, stars = "", n = 0)
}

# Root crops subsample
panel_root <- panel |> filter(crop_group == "Root")
if (nrow(panel_root) > 50) {
  m_root <- feols(
    log_yield ~ post_ban:derog | country + as.factor(year),
    data = panel_root,
    cluster = ~country
  )
  mech_root <- extract_coef(m_root, "Root")
} else {
  mech_root <- list(coef = NA, se = NA, stars = "", n = 0)
}

mech_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Mechanism: Derogation Effect by Crop Group}",
  "\\label{tab:mechanism}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Cereals & Oilseeds & Fruit & Root Crops \\\\",
  " & (PDR = 0) & (PDR = 0.25--0.65) & (PDR = 0.65) & (PDR = 0) \\\\",
  "\\midrule"
)

fmt <- function(x, d = 4) {
  if (is.na(x)) return("") else formatC(x, format = "f", digits = d)
}

mech_lines <- c(mech_lines,
  sprintf("Post $\\times$ Derog & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(mech_cereals$coef[1]), mech_cereals$stars[1],
    fmt(mech_oilseeds$coef[1]), mech_oilseeds$stars[1],
    fmt(mech_fruit$coef[1]), mech_fruit$stars[1],
    fmt(mech_root$coef[1]), mech_root$stars[1]),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(mech_cereals$se[1]), fmt(mech_oilseeds$se[1]),
    fmt(mech_fruit$se[1]), fmt(mech_root$se[1])),
  "\\midrule",
  "Mean PDR & 0.00 & 0.35 & 0.65 & 0.00 \\\\",
  "Country FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    formatC(mech_cereals$n, format = "d", big.mark = ","),
    formatC(mech_oilseeds$n, format = "d", big.mark = ","),
    formatC(mech_fruit$n, format = "d", big.mark = ","),
    formatC(mech_root$n, format = "d", big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Standard errors clustered at the country level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Each column estimates the derogation effect (Post $\\times$ Derog) within a single crop group. Cereals (column 1) and root crops (column 4) have zero pollinator dependence and serve as mechanism tests: any derogation effect on these crops operates exclusively through pest protection. Oilseeds (column 2) and fruit (column 3) are pollinator-dependent, so the derogation effect conflates pest protection and pollinator harm.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(mech_lines, "tables/tab4_mechanism.tex")
cat("Wrote tables/tab4_mechanism.tex\n")

# ==================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ==================================================================

cat("\n--- Table F1: SDE ---\n")

# Main DDD model
m1 <- models$m1
beta_ddd  <- coef(m1)[[1]]
se_ddd    <- sqrt(diag(vcov(m1)))[[1]]
sd_y_all  <- sd(panel$log_yield, na.rm = TRUE)

# The treatment here is PDR × Derog (interaction), which is continuous
# For the DDD, treatment is effectively: a 1-unit increase in PDR for derogation countries
# PDR ranges from 0 to 0.65, so SD(PDR × Derog) is the relevant treatment SD
panel_treat <- panel |> mutate(treat_var = pdr * derog)
sd_x_ddd <- sd(panel_treat$treat_var, na.rm = TRUE)

sde_ddd    <- beta_ddd * sd_x_ddd / sd_y_all
se_sde_ddd <- se_ddd * sd_x_ddd / sd_y_all

# DD model (Post × PDR)
m2 <- models$m2
beta_dd <- coef(m2)[[1]]
se_dd   <- sqrt(diag(vcov(m2)))[[1]]
sd_x_dd <- sd(panel$pdr, na.rm = TRUE)

sde_dd    <- beta_dd * sd_x_dd / sd_y_all
se_sde_dd <- se_dd * sd_x_dd / sd_y_all

# Sugar beet DD
m3 <- models$m3
beta_sb <- coef(m3)[[1]]
se_sb   <- sqrt(diag(vcov(m3)))[[1]]
sugar_beet_data <- panel |> filter(crop_code == "R2000")
sd_y_sb <- sd(sugar_beet_data$log_yield, na.rm = TRUE)

sde_sb    <- beta_sb / sd_y_sb  # binary treatment
se_sde_sb <- se_sb / sd_y_sb

# Classification function
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

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log yield & DDD (cont.\\ PDR) & %s & %s & %s & %s & %s & %s \\\\",
    formatC(beta_ddd, format = "f", digits = 4),
    formatC(sd_x_ddd, format = "f", digits = 3),
    formatC(sd_y_all, format = "f", digits = 3),
    formatC(sde_ddd, format = "f", digits = 4),
    formatC(se_sde_ddd, format = "f", digits = 4),
    classify_sde(sde_ddd)),
  sprintf("Log yield & DD (Post $\\times$ PDR) & %s & %s & %s & %s & %s & %s \\\\",
    formatC(beta_dd, format = "f", digits = 4),
    formatC(sd_x_dd, format = "f", digits = 3),
    formatC(sd_y_all, format = "f", digits = 3),
    formatC(sde_dd, format = "f", digits = 4),
    formatC(se_sde_dd, format = "f", digits = 4),
    classify_sde(sde_dd)),
  sprintf("Log yield & Sugar beet DD & %s & --- & %s & %s & %s & %s \\\\",
    formatC(beta_sb, format = "f", digits = 4),
    formatC(sd_y_sb, format = "f", digits = 3),
    formatC(sde_sb, format = "f", digits = 4),
    formatC(se_sde_sb, format = "f", digits = 4),
    classify_sde(sde_sb)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. For the DDD and DD specifications, the treatment is continuous: SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, giving the effect of a one-standard-deviation change in the treatment interaction, measured in standard deviations of the outcome. For the sugar beet DD, treatment is binary (derogation = 0/1): SDE $= \\hat{\\beta} / \\text{SD}(Y)$. SD($Y$) and SD($X$) are unconditional standard deviations from the full sample. \\textbf{Research question:} What is the yield cost of the EU's 2018 neonicotinoid ban, and does it vary by pollinator dependence? \\textbf{Treatment:} DDD interaction of post-ban period, pollinator dependence ratio, and derogation status. \\textbf{Data:} Eurostat apro\\_cpsh1, %d EU countries, %d crops, 2000--2023, %s observations. \\textbf{Method:} OLS with country$\\times$crop, crop$\\times$year, and country$\\times$year FE; SEs clustered at country level. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
    n_distinct(panel$country), n_distinct(panel$crop_code),
    formatC(nrow(panel), format = "d", big.mark = ",")),
  "\\end{table}"
)

writeLines(sde_lines, "tables/tabF1_sde.tex")
cat("Wrote tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
