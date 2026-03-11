# ============================================================================
# 06_tables.R — All table generation
# APEP-0593: Roaming Abolition and Cross-Border Tourism
# ============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel_main <- panel[time >= 2012 & time <= 2019]
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# -----------------------------------------------------------------------
# Table 1: Summary Statistics
# -----------------------------------------------------------------------
cat("Generating Table 1: Summary Statistics...\n")

# Split by border type
summ_stats <- panel_main[border_type %in% c("internal_border", "interior"),
                         .(
                           `Foreign nights (mean)` = mean(foreign_nights, na.rm = TRUE),
                           `Foreign nights (sd)` = sd(foreign_nights, na.rm = TRUE),
                           `Domestic nights (mean)` = mean(domestic_nights, na.rm = TRUE),
                           `Domestic nights (sd)` = sd(domestic_nights, na.rm = TRUE),
                           `Population (mean)` = mean(population, na.rm = TRUE),
                           `GDP (EUR M, mean)` = mean(gdp_mio, na.rm = TRUE),
                           `Foreign share` = mean(foreign_nights / (total_nights + 1), na.rm = TRUE),
                           `N (region-years)` = .N,
                           `N regions` = uniqueN(geo)
                         ), by = border_type]

# Also compute log foreign nights sd for SDE table
log_foreign_sd <- sd(panel_main[border_type %in% c("internal_border", "interior")]$log_foreign, na.rm = TRUE)
cat("SD(log foreign nights):", round(log_foreign_sd, 4), "\n")

# Format for LaTeX
summ_long <- melt(summ_stats, id.vars = "border_type", variable.name = "Statistic")
summ_wide <- dcast(summ_long, Statistic ~ border_type)

# Round
num_cols <- c("internal_border", "interior")
for (col in num_cols) {
  summ_wide[[col]] <- ifelse(
    grepl("N ", summ_wide$Statistic),
    format(round(summ_wide[[col]]), big.mark = ","),
    format(round(summ_wide[[col]], 1), big.mark = ",")
  )
}
setnames(summ_wide, c("internal_border", "interior"),
         c("Border Regions", "Interior Regions"))

kbl <- knitr::kable(summ_wide, format = "latex", booktabs = TRUE,
                     caption = "Summary Statistics: Border vs.\\ Interior NUTS2 Regions, 2012--2019",
                     label = "summ_stats", escape = FALSE)
writeLines(kbl, file.path(tab_dir, "tab1_summary.tex"))

# -----------------------------------------------------------------------
# Table 2: Main Results
# -----------------------------------------------------------------------
cat("Generating Table 2: Main Results...\n")

etable(m1, m2, m_cty, m_cty_cont, m_dom,
       tex = TRUE,
       file = file.path(tab_dir, "tab2_main.tex"),
       title = "Effect of Roaming Abolition on Foreign Tourist Nights",
       label = "tab:main_results",
       dict = c(border_post = "Border $\\times$ Post",
                share_post = "Cross-Border Share $\\times$ Post",
                log_foreign = "Log Foreign Nights",
                log_domestic = "Log Domestic Nights"),
       headers = c("Binary", "Continuous", "Cty$\\times$Yr",
                    "Cont.+Cty$\\times$Yr", "Domestic (Placebo)"),
       se.below = TRUE,
       fitstat = ~ n + r2 + wr2,
       notes = "Clustered standard errors at country level in parentheses.
       Pre-COVID sample: 2012--2019. Border = 1 if NUTS2 region shares an
       internal EU land border. Cross-Border Share = pre-treatment (2012--2016)
       mean ratio of foreign to total tourist nights.",
       replace = TRUE)

# Post-process: wrap tabular in adjustbox to prevent overflow
tab2_path <- file.path(tab_dir, "tab2_main.tex")
tab2_lines <- readLines(tab2_path)
tab2_lines <- sub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n\\\\begin{tabular}", tab2_lines)
tab2_lines <- sub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n\\\\end{adjustbox}", tab2_lines)
writeLines(tab2_lines, tab2_path)

# -----------------------------------------------------------------------
# Table 3: Internal vs External Border Comparison
# -----------------------------------------------------------------------
cat("Generating Table 3: Border Comparison...\n")

etable(m1, m_ext, m_matched,
       tex = TRUE,
       file = file.path(tab_dir, "tab3_borders.tex"),
       title = "Border Comparison and Matched Sample",
       label = "tab:borders",
       headers = c("All Regions", "Internal vs External", "CEM Matched"),
       se.below = TRUE,
       fitstat = ~ n + wr2,
       replace = TRUE)

# -----------------------------------------------------------------------
# Table C.1 (Appendix): Robustness — Leave-one-out range
# -----------------------------------------------------------------------
cat("Generating Table C.1: Leave-one-country-out...\n")

loo <- fread(file.path(data_dir, "loo_results.csv"))
loo[, ci_low := beta - 1.96 * se]
loo[, ci_high := beta + 1.96 * se]
loo[, significant := ifelse(ci_low > 0 | ci_high < 0, "*", "")]

loo_tab <- loo[, .(
  `Country Excluded` = excluded,
  `Coefficient` = format(round(beta, 4), nsmall = 4),
  `SE` = format(round(se, 4), nsmall = 4),
  `N Obs.` = format(n_obs, big.mark = ","),
  `N Regions` = format(n_regions, big.mark = ",")
)]

kbl_loo <- knitr::kable(loo_tab, format = "latex", booktabs = TRUE,
                         caption = "Leave-One-Country-Out Robustness",
                         label = "loo", escape = FALSE)
writeLines(kbl_loo, file.path(tab_dir, "tabC1_loo.tex"))

# -----------------------------------------------------------------------
# Table C.2 (Appendix): Placebo timing
# -----------------------------------------------------------------------
cat("Generating Table C.2: Placebo timing...\n")

etable(m_placebo,
       tex = TRUE,
       file = file.path(tab_dir, "tabC2_placebo.tex"),
       title = "Placebo Test: Fake Treatment at 2015",
       label = "tab:placebo_timing",
       se.below = TRUE,
       fitstat = ~ n + wr2,
       replace = TRUE)

# -----------------------------------------------------------------------
# Table F.1 (Appendix F): Standardized Effect Sizes
# -----------------------------------------------------------------------
cat("Generating Table F.1: Standardized Effect Sizes...\n")

# Extract beta and SE from preferred specification (m1: binary DiD, log)
beta_main <- coef(m1)["border_post"]
se_main <- se(m1)["border_post"]

# SD of outcome (unconditional)
sd_y <- sd(panel_main[border_type %in% c("internal_border", "interior")]$log_foreign,
           na.rm = TRUE)

# SDE = beta / sd_y (binary treatment)
sde <- beta_main / sd_y
se_sde <- se_main / sd_y

# Classification
classify_sde <- function(x) {
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x <= 0.005) return("Null")
  if (x <= 0.05) return("Small positive")
  if (x <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_tab <- data.table(
  Outcome = "Log foreign nights",
  Specification = "Table 2, Col. 1",
  `$\\hat{\\beta}$` = format(round(beta_main, 4), nsmall = 4),
  `SD(Y)` = format(round(sd_y, 3), nsmall = 3),
  SDE = format(round(sde, 3), nsmall = 3),
  `SE(SDE)` = format(round(se_sde, 3), nsmall = 3),
  Classification = classify_sde(sde)
)

# Also add country×year FE specification (Table 2, Col. 3)
beta_cty <- coef(m_cty)["border_post"]
se_cty <- se(m_cty)["border_post"]
sde_cty <- beta_cty / sd_y
se_sde_cty <- se_cty / sd_y

sde_tab <- rbind(sde_tab, data.table(
  Outcome = "Log foreign nights",
  Specification = "Table 2, Col. 3",
  `$\\hat{\\beta}$` = format(round(beta_cty, 4), nsmall = 4),
  `SD(Y)` = format(round(sd_y, 3), nsmall = 3),
  SDE = format(round(sde_cty, 3), nsmall = 3),
  `SE(SDE)` = format(round(se_sde_cty, 3), nsmall = 3),
  Classification = classify_sde(sde_cty)
))

# Write SDE table directly as proper LaTeX (avoid kable escaping issues)
n_obs_1 <- format(nobs(m1), big.mark = ",")
n_reg_all <- uniqueN(panel_main$geo)
n_obs_3 <- format(nobs(m_cty), big.mark = ",")
n_reg_bi <- uniqueN(panel_main[border_type %in% c("internal_border", "interior")]$geo)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\caption{\\label{tab:sde}Standardized Effect Sizes}",
  "\\centering",
  "\\resizebox{\\textwidth}{!}{",
  "\\begin{tabular}{lllllll}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD(Y) & SDE & SE(SDE) & Classification\\\\",
  "\\midrule",
  paste0("Log foreign nights & Table 2, Col. 1 & ",
         format(round(beta_main, 4), nsmall = 4), " & ",
         format(round(sd_y, 3), nsmall = 3), " & ",
         format(round(sde, 3), nsmall = 3), " & ",
         format(round(se_sde, 3), nsmall = 3), " & ",
         classify_sde(sde), "\\\\"),
  paste0("Log foreign nights & Table 2, Col. 3 & ",
         format(round(beta_cty, 4), nsmall = 4), " & ",
         format(round(sd_y, 3), nsmall = 3), " & ",
         format(round(sde_cty, 3), nsmall = 3), " & ",
         format(round(se_sde_cty, 3), nsmall = 3), " & ",
         classify_sde(sde_cty), "\\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "}",
  "\\vspace{0.5em}",
  "",
  "\\begin{minipage}{\\textwidth}",
  paste0("\\footnotesize \\textit{Notes:} SDE = $\\hat{\\beta}$ / SD(Y) for binary treatment (Border $\\times$ Post). Research question: whether EU's 2017 RLAH regulation increased foreign accommodation nights in border NUTS2 regions vs.\\ interior regions. Data: Eurostat tour\\_occ\\_nin2, 2012--2019. Unit: NUTS2 region-year. Sample: ", n_obs_1, " obs, ", n_reg_all, " regions (Col.\\ 1); ", n_obs_3, " obs, ", n_reg_bi, " regions (Col.\\ 3, country$\\times$year FE). Method: TWFE DiD, clustered at country level. SE(SDE) = SE($\\hat{\\beta}$) / SD(Y). Col.\\ 1: region + year FE; Col.\\ 3: region + country$\\times$year FE (preferred). Classification labels reflect magnitude of the standardized point estimate, not statistical significance."),
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(sde_lines, file.path(tab_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
