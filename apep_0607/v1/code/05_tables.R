# 05_tables.R — Generate all LaTeX tables
# APEP Working Paper apep_0607
# V1 papers have zero figures — all results communicated through tables

source("00_packages.R")

dir.create("../tables", showWarnings = FALSE)

panel <- readRDS("../data/analysis_panel.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

sum_stats <- panel %>%
  summarise(
    across(c(soy_area_ha, soy_prod_tons, soy_value_1000brl,
             cattle_head, temp_crop_area_ha, soy_yield,
             farming_share_2008),
           list(
             mean = ~mean(.x, na.rm = TRUE),
             sd = ~sd(.x, na.rm = TRUE),
             min = ~min(.x, na.rm = TRUE),
             max = ~max(.x, na.rm = TRUE),
             n = ~sum(!is.na(.x))
           ))
  ) %>%
  pivot_longer(everything(),
               names_to = c("variable", "stat"),
               names_pattern = "(.+)_(mean|sd|min|max|n)$") %>%
  pivot_wider(names_from = stat, values_from = value)

# Format variable names
var_labels <- c(
  "soy_area_ha" = "Soybean planted area (ha)",
  "soy_prod_tons" = "Soybean production (tons)",
  "soy_value_1000brl" = "Soybean production value (1000 R\\$)",
  "cattle_head" = "Cattle herd (head)",
  "temp_crop_area_ha" = "Total temp. crop area (ha)",
  "soy_yield" = "Soybean yield (tons/ha)",
  "farming_share_2008" = "Farming share, 2008 (treatment)"
)

sum_stats <- sum_stats %>%
  mutate(label = var_labels[variable]) %>%
  filter(!is.na(label))

# Write LaTeX
tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & Std.~Dev. & Min & Max & N \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(sum_stats))) {
  r <- sum_stats[i, ]
  tab1 <- paste0(tab1,
    r$label, " & ",
    formatC(r$mean, format = "f", digits = 1, big.mark = ","), " & ",
    formatC(r$sd, format = "f", digits = 1, big.mark = ","), " & ",
    formatC(r$min, format = "f", digits = 1, big.mark = ","), " & ",
    formatC(r$max, format = "f", digits = 1, big.mark = ","), " & ",
    formatC(r$n, format = "d", big.mark = ","), " \\\\\n"
  )
}

tab1 <- paste0(tab1,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Municipality-year panel, 2006--2020. ",
  "N = ", formatC(nrow(panel), big.mark = ","), " municipality-year observations ",
  "from ", formatC(n_distinct(panel$muni_code_6), big.mark = ","), " municipalities. ",
  "Farming share is the share of municipality area classified as farming (agriculture + pasture) ",
  "by MapBiomas in 2008, used as the continuous treatment variable measuring amnesty exposure. ",
  "Soybean yield is computed as production (tons) divided by planted area (ha).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

m1_soy <- readRDS("../data/m1_soy.rds")
m1_temp <- readRDS("../data/m1_temp.rds")
m1_cattle <- readRDS("../data/m1_cattle.rds")
m1_value <- readRDS("../data/m1_value.rds")

# Extract coefficients
get_result <- function(m, label) {
  b <- coef(m)["treatment_x_post"]
  s <- se(m)["treatment_x_post"]
  p <- pvalue(m)["treatment_x_post"]
  n <- m$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  list(label = label, beta = b, se = s, p = p, n = n, stars = stars)
}

results <- list(
  get_result(m1_soy, "Log soy area"),
  get_result(m1_temp, "Log temp.~crop area"),
  get_result(m1_cattle, "Log cattle herd"),
  get_result(m1_value, "Log soy value")
)

# Also try to load yield result
if (file.exists("../data/m_yield.rds")) {
  m_yield <- readRDS("../data/m_yield.rds")
  results[[5]] <- get_result(m_yield, "Log soy yield")
}

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Main Results: Effect of Forest Code Amnesty on Agricultural Outcomes}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc",
  ifelse(length(results) >= 5, "c", ""),
  "}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4)",
  ifelse(length(results) >= 5, " & (5)", ""),
  " \\\\\n",
  " & ", paste(sapply(results, function(r) r$label), collapse = " & "), " \\\\\n",
  "\\midrule\n"
)

# Treatment row
tab2 <- paste0(tab2,
  "Farming share $\\times$ Post & ",
  paste(sapply(results, function(r) {
    paste0(formatC(r$beta, format = "f", digits = 3), r$stars)
  }), collapse = " & "),
  " \\\\\n"
)

# SE row
tab2 <- paste0(tab2,
  " & ",
  paste(sapply(results, function(r) {
    paste0("(", formatC(r$se, format = "f", digits = 3), ")")
  }), collapse = " & "),
  " \\\\\n"
)

# 95% CI
tab2 <- paste0(tab2,
  "95\\% CI & ",
  paste(sapply(results, function(r) {
    lo <- r$beta - 1.96 * r$se
    hi <- r$beta + 1.96 * r$se
    paste0("[", formatC(lo, format = "f", digits = 3), ", ",
           formatC(hi, format = "f", digits = 3), "]")
  }), collapse = " & "),
  " \\\\\n"
)

# N, FE, Clusters
tab2 <- paste0(tab2,
  "\\midrule\n",
  "Municipality FE & ", paste(rep("Yes", length(results)), collapse = " & "), " \\\\\n",
  "State $\\times$ Year FE & ", paste(rep("Yes", length(results)), collapse = " & "), " \\\\\n",
  "Clustering & ", paste(rep("Muni", length(results)), collapse = " & "), " \\\\\n",
  "N & ",
  paste(sapply(results, function(r) formatC(r$n, format = "d", big.mark = ",")),
        collapse = " & "),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Standard errors clustered at municipality level in parentheses. ",
  "Each column reports the coefficient on Farming Share $\\times$ Post from a ",
  "continuous-treatment difference-in-differences specification. ",
  "Farming share is the share of municipality area classified as farming (agriculture + pasture) ",
  "by MapBiomas in 2008. Post = 1 for years $\\geq$ 2012. ",
  "The coefficient represents the differential change in the outcome for a municipality ",
  "with 100\\% farming share (vs.~0\\%) after the 2012 Forest Code amnesty.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ============================================================
# Table 3: Robustness Checks
# ============================================================
cat("\n=== Table 3: Robustness ===\n")

specs <- list()
specs[["Baseline"]] <- m1_soy
if (file.exists("../data/r_yearfe_soy.rds"))
  specs[["Year FE only"]] <- readRDS("../data/r_yearfe_soy.rds")
if (file.exists("../data/r_trim_soy.rds"))
  specs[["Trimmed (1--99\\%)"]] <- readRDS("../data/r_trim_soy.rds")
if (file.exists("../data/r_asinh_soy.rds"))
  specs[["Asinh transform"]] <- readRDS("../data/r_asinh_soy.rds")
if (file.exists("../data/r_noamz_soy.rds"))
  specs[["Excl.~Amazon"]] <- readRDS("../data/r_noamz_soy.rds")
if (file.exists("../data/m2_soy.rds"))
  specs[["Forest loss treat."]] <- readRDS("../data/m2_soy.rds")

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness: Log Soybean Planted Area}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{l",
  paste(rep("c", length(specs)), collapse = ""),
  "}\n",
  "\\toprule\n",
  " & ", paste(paste0("(", seq_along(specs), ")"), collapse = " & "), " \\\\\n",
  " & ", paste(names(specs), collapse = " & "), " \\\\\n",
  "\\midrule\n"
)

# Get treatment variable name from each model
for (i in seq_along(specs)) {
  m <- specs[[i]]
  coef_name <- names(coef(m))[1]
  b <- coef(m)[coef_name]
  s <- se(m)[coef_name]
  p <- pvalue(m)[coef_name]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

  if (i == 1) {
    tab3 <- paste0(tab3, "Treatment $\\times$ Post")
  }
  if (i == 1) {
    vals <- sapply(seq_along(specs), function(j) {
      mj <- specs[[j]]
      cn <- names(coef(mj))[1]
      bj <- coef(mj)[cn]
      pj <- pvalue(mj)[cn]
      stj <- ifelse(pj < 0.01, "***", ifelse(pj < 0.05, "**", ifelse(pj < 0.10, "*", "")))
      paste0(formatC(bj, format = "f", digits = 3), stj)
    })
    tab3 <- paste0(tab3, " & ", paste(vals, collapse = " & "), " \\\\\n")

    se_vals <- sapply(seq_along(specs), function(j) {
      mj <- specs[[j]]
      cn <- names(coef(mj))[1]
      sj <- se(mj)[cn]
      paste0("(", formatC(sj, format = "f", digits = 3), ")")
    })
    tab3 <- paste0(tab3, " & ", paste(se_vals, collapse = " & "), " \\\\\n")

    n_vals <- sapply(specs, function(mj) formatC(mj$nobs, format = "d", big.mark = ","))
    tab3 <- paste0(tab3,
      "\\midrule\n",
      "N & ", paste(n_vals, collapse = " & "), " \\\\\n",
      "\\bottomrule\n"
    )
    break
  }
}

tab3 <- paste0(tab3,
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Standard errors clustered at municipality level. ",
  "All specifications include municipality FE except where noted. ",
  "Column (1): baseline with state$\\times$year FE. ",
  "Column (2): year FE only. ",
  "Column (3): trimmed to 1st--99th percentile of treatment intensity. ",
  "Column (4): inverse hyperbolic sine transformation. ",
  "Column (5): excluding Amazon biome municipalities. ",
  "Column (6): forest loss 1985--2008 as alternative treatment.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robustness.tex")
cat("Table 3 written.\n")

# ============================================================
# Table 4: Biome Heterogeneity
# ============================================================
cat("\n=== Table 4: Biome Heterogeneity ===\n")

if (file.exists("../data/biome_results.rds")) {
  biome_results <- readRDS("../data/biome_results.rds")

  tab4 <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Heterogeneity by Biome: Log Soybean Planted Area}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{l",
    paste(rep("c", length(biome_results)), collapse = ""),
    "}\n",
    "\\toprule\n",
    " & ", paste(paste0("(", seq_along(biome_results), ")"), collapse = " & "), " \\\\\n",
    " & ", paste(names(biome_results), collapse = " & "), " \\\\\n",
    "\\midrule\n",
    "Treatment $\\times$ Post & "
  )

  vals <- sapply(biome_results, function(m) {
    b <- coef(m)["treatment_x_post"]
    p <- pvalue(m)["treatment_x_post"]
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
    paste0(formatC(b, format = "f", digits = 3), stars)
  })
  tab4 <- paste0(tab4, paste(vals, collapse = " & "), " \\\\\n")

  se_vals <- sapply(biome_results, function(m) {
    s <- se(m)["treatment_x_post"]
    paste0("(", formatC(s, format = "f", digits = 3), ")")
  })
  tab4 <- paste0(tab4, " & ", paste(se_vals, collapse = " & "), " \\\\\n")

  n_vals <- sapply(biome_results, function(m) formatC(m$nobs, format = "d", big.mark = ","))
  tab4 <- paste0(tab4,
    "\\midrule\n",
    "Municipality FE & ", paste(rep("Yes", length(biome_results)), collapse = " & "), " \\\\\n",
    "Year FE & ", paste(rep("Yes", length(biome_results)), collapse = " & "), " \\\\\n",
    "N & ", paste(n_vals, collapse = " & "), " \\\\\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
    "Standard errors clustered at municipality level. ",
    "Each column estimates the baseline specification on the subsample of municipalities ",
    "whose primary biome (by area) matches the column header. ",
    "Legal reserve requirements: Amazonia 80\\%, Cerrado 35\\%, Mata Atl\\^{a}ntica 20\\%. ",
    "Higher legal reserve implies larger amnesty windfall per unit of pre-2008 clearing.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:biome}\n",
    "\\end{table}\n"
  )

  writeLines(tab4, "../tables/tab4_biome.tex")
  cat("Table 4 written.\n")
}

# ============================================================
# Table 5: Moral Hazard
# ============================================================
cat("\n=== Table 5: Moral Hazard ===\n")

if (file.exists("../data/moral_hazard.rds")) {
  mh <- readRDS("../data/moral_hazard.rds")
  b_mh <- coef(mh)["farming_share_2008"]
  se_mh <- sqrt(diag(vcov(mh)))["farming_share_2008"]
  p_mh <- summary(mh)$coefficients["farming_share_2008", "Pr(>|t|)"]
  n_mh <- nrow(mh$model)
  stars_mh <- ifelse(p_mh < 0.01, "***", ifelse(p_mh < 0.05, "**", ifelse(p_mh < 0.10, "*", "")))

  tab5 <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Moral Hazard: Pre-2008 Amnesty Exposure and Post-2012 Deforestation}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lc}\n",
    "\\toprule\n",
    " & Post-2012 forest loss share \\\\\n",
    "\\midrule\n",
    "Farming share (2008) & ", formatC(b_mh, format = "f", digits = 4), stars_mh, " \\\\\n",
    " & (", formatC(se_mh, format = "f", digits = 4), ") \\\\\n",
    "\\midrule\n",
    "State FE & Yes \\\\\n",
    "N & ", formatC(n_mh, format = "d", big.mark = ","), " \\\\\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
    "OLS cross-sectional regression of post-2012 forest loss (2012--2020, as share of municipality area) ",
    "on pre-2008 farming share, controlling for state fixed effects. ",
    "A positive coefficient indicates moral hazard: municipalities that benefited more ",
    "from the 2012 amnesty subsequently experienced more deforestation, consistent ",
    "with expectations of future amnesties reducing compliance with the new Forest Code.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:moral_hazard}\n",
    "\\end{table}\n"
  )

  writeLines(tab5, "../tables/tab5_moral_hazard.tex")
  cat("Table 5 written.\n")
}

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
# SDE = β / SD(Y) for binary treatment
# For continuous treatment: SDE = β × SD(X) / SD(Y)

sd_x <- sd(panel$farming_share_2008, na.rm = TRUE)

sde_rows <- list()

compute_sde <- function(model, outcome_var, label, panel_data) {
  coef_name <- names(coef(model))[1]
  beta <- coef(model)[coef_name]
  se_beta <- se(model)[coef_name]
  sd_y <- sd(panel_data[[outcome_var]], na.rm = TRUE)

  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y

  classify <- function(s) {
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    if (s < -0.005) return("Small negative")
    if (s < 0.005) return("Null")
    if (s < 0.05) return("Small positive")
    if (s < 0.15) return("Moderate positive")
    return("Large positive")
  }

  list(
    label = label,
    beta = beta,
    se = se_beta,
    sd_x = sd_x,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    class = classify(sde)
  )
}

sde_rows[[1]] <- compute_sde(m1_soy, "log_soy_area", "Log soybean area", panel)
sde_rows[[2]] <- compute_sde(m1_temp, "log_temp_crop", "Log temp.~crop area", panel)
sde_rows[[3]] <- compute_sde(m1_cattle, "log_cattle", "Log cattle herd", panel)
sde_rows[[4]] <- compute_sde(m1_value, "log_soy_value", "Log soy value", panel)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (r in sde_rows) {
  tabF1 <- paste0(tabF1,
    r$label, " & ",
    formatC(r$beta, format = "f", digits = 3), " & ",
    formatC(r$sd_x, format = "f", digits = 3), " & ",
    formatC(r$sd_y, format = "f", digits = 3), " & ",
    formatC(r$sde, format = "f", digits = 3), " & ",
    formatC(r$se_sde, format = "f", digits = 3), " & ",
    r$class, " \\\\\n"
  )
}

tabF1 <- paste0(tabF1,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
  "to facilitate cross-study comparison of treatment effect magnitudes. ",
  "For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, ",
  "which gives the effect of a one-standard-deviation change in the treatment variable, ",
  "measured in standard deviations of the outcome. ",
  "SD($Y$) and SD($X$) are unconditional standard deviations from the full panel.\n\n",
  "\\textbf{Research question:} Does the 2012 Forest Code amnesty exposure affect agricultural outcomes ",
  "at the municipality level? ",
  "\\textbf{Treatment:} Continuous; farming share of municipality area in 2008 (MapBiomas). ",
  "\\textbf{Data:} IBGE PAM/PPM and MapBiomas Collection 9, 2006--2020, municipality-year panel. ",
  "\\textbf{Method:} Continuous-treatment DiD with municipality and state$\\times$year FE, municipality-clustered SEs. ",
  "\\textbf{Sample:} ", formatC(nrow(panel), big.mark = ","), " municipality-year observations.\n\n",
  "Classification thresholds (7 categories): ",
  "large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), ",
  "small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), ",
  "small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), ",
  "large positive ($> 0.15$). ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All Tables Generated ===\n")
print(list.files("../tables/"))
