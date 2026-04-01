# 05_tables.R — Generate all LaTeX tables for apep_1270

source("00_packages.R")
options(modelsummary_format_numeric_latex = "plain")
load("../data/models.RData")
load("../data/robustness.RData")

# ─── Table 1: Summary Statistics ───
cat("=== Generating Table 1: Summary Statistics ===\n")

summ <- panel %>%
  group_by(year) %>%
  summarise(
    N = n(),
    `Levy (CHF/t)` = first(levy_chf_per_ton),
    `Oil (%)` = sprintf("%.1f (%.1f)", mean(oil_pct, na.rm=T), sd(oil_pct, na.rm=T)),
    `Heat Pump (%)` = sprintf("%.1f (%.1f)", mean(hp_pct, na.rm=T), sd(hp_pct, na.rm=T)),
    `Gas (%)` = sprintf("%.1f (%.1f)", mean(gas_pct, na.rm=T), sd(gas_pct, na.rm=T)),
    `Wood (%)` = sprintf("%.1f (%.1f)", mean(wood_pct, na.rm=T), sd(wood_pct, na.rm=T)),
    `Electricity (%)` = sprintf("%.1f (%.1f)", mean(elec_pct, na.rm=T), sd(elec_pct, na.rm=T)),
    .groups = "drop"
  )

tab1_tex <- kable(summ, format = "latex", booktabs = TRUE, escape = FALSE,
                  caption = "Dwelling Heating Energy Source by Year (Canton Means)",
                  label = "tab:summary") %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = "Mean (SD) across 26 Swiss cantons. Source: BFS Gebäude- und Wohnungsstatistik (GWS). Levy is the federal CO2 levy rate in CHF per ton CO2. Shares are percentages of dwellings using each energy source for heating.",
           general_title = "", threeparttable = TRUE, escape = FALSE)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 saved.\n")

# ─── Table 2: Main Results ───
cat("=== Generating Table 2: Main Results ===\n")

# Use modelsummary for clean regression table
tab2_models <- list(
  "Oil" = m1_oil,
  "Heat Pump" = m1_hp,
  "Gas" = m1_gas,
  "Wood" = m1_wood,
  "Electricity" = m_elec
)

cm <- c("treatment" = "OilShare$_{c,2000}$ $\\times$ Levy$_t$")

modelsummary(
  tab2_models,
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_map = cm,
  gof_map = c("nobs", "r.squared.within", "FE: canton", "FE: year"),
  output = "../tables/tab2_main.tex",
  title = "Effect of CO2 Levy Exposure on Dwelling Heating Energy Source (\\%)",
  escape = FALSE
)
cat("Table 2 saved.\n")

# ─── Table 3: Robustness ───
cat("=== Generating Table 3: Robustness ===\n")

tab3_models <- list(
  "(1) Full Panel" = m1_gas,
  "(2) 2021--2024" = feols(gas_pct ~ treatment | canton + year,
                           data = panel %>% filter(year >= 2021), cluster = ~canton),
  "(3) Post$\\times$Oil" = m_binary_gas,
  "(4) Placebo Trt" = m_placebo_gas
)

cm3 <- c(
  "treatment" = "OilShare$_{c,2000}$ $\\times$ Levy$_t$",
  "post:oil_share_2000" = "Post $\\times$ OilShare$_{c,2000}$",
  "treatment_gas" = "GasShare$_{c,2000}$ $\\times$ Levy$_t$"
)

modelsummary(
  tab3_models,
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_map = cm3,
  gof_map = c("nobs", "r.squared.within", "FE: canton", "FE: year"),
  output = "../tables/tab3_robustness.tex",
  title = "Robustness: Gas Heating Share",
  escape = FALSE
)
cat("Table 3 saved.\n")

# ─── Table 4: Long Difference ───
cat("=== Generating Table 4: Long Difference ===\n")

tab4_models <- list(
  "$\\Delta$Oil" = m2_oil,
  "$\\Delta$HP" = m2_hp,
  "$\\Delta$Gas" = lm(delta_gas ~ oil_share_2000, data = long_diff)
)

cm4 <- c(
  "oil_share_2000" = "Oil Share$_{c,2000}$",
  "(Intercept)" = "Constant"
)

modelsummary(
  tab4_models,
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_map = cm4,
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  output = "../tables/tab4_longdiff.tex",
  title = "Long Difference: Change in Heating Shares, 2000--2024",
  escape = FALSE
)
cat("Table 4 saved.\n")

# ─── Table 5: Leave-One-Out Summary ───
cat("=== Generating Table 5: Leave-One-Out ===\n")

loo_summ <- data.frame(
  Outcome = c("Oil", "Heat Pump", "Gas"),
  `Main Coef.` = c(round(coef(m1_oil)["treatment"], 3),
                   round(coef(m1_hp)["treatment"], 3),
                   round(coef(m1_gas)["treatment"], 3)),
  `LOO Min` = c(round(min(loo_results$coef_oil), 3),
                round(min(loo_results$coef_hp), 3),
                round(min(loo_results$coef_gas), 3)),
  `LOO Max` = c(round(max(loo_results$coef_oil), 3),
                round(max(loo_results$coef_hp), 3),
                round(max(loo_results$coef_gas), 3)),
  check.names = FALSE
)

tab5_tex <- kable(loo_summ, format = "latex", booktabs = TRUE,
                  caption = "Leave-One-Out Sensitivity of Treatment Coefficients",
                  label = "tab:loo") %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = "Each row shows the main coefficient and the range of coefficients when dropping each of the 26 cantons one at a time. The gas result is stable across all leave-one-out permutations.",
           general_title = "", threeparttable = TRUE)

writeLines(tab5_tex, "../tables/tab5_loo.tex")
cat("Table 5 saved.\n")

# ─── SDE Table (Appendix) ───
cat("=== Generating SDE Table ===\n")

# Standardized effect sizes
# For continuous treatment: SDE = β × SD(X) / SD(Y)
sd_treatment <- sd(panel$treatment[panel$year > 2000])
sd_oil_y <- sd_oil_2000  # Pre-treatment SD of outcome

# Panel A: Pooled
sde_oil <- coef(m1_oil)["treatment"] * sd_treatment / sd_oil_y
sde_hp <- coef(m1_hp)["treatment"] * sd_treatment / sd_hp_2000
sde_gas <- coef(m1_gas)["treatment"] * sd_treatment / sd(panel$gas_pct[panel$year == 2000], na.rm=TRUE)

se_oil <- summary(m1_oil)$se["treatment"] * sd_treatment / sd_oil_y
se_hp <- summary(m1_hp)$se["treatment"] * sd_treatment / sd_hp_2000
se_gas <- summary(m1_gas)$se["treatment"] * sd_treatment / sd(panel$gas_pct[panel$year == 2000], na.rm=TRUE)

classify <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  return("Small positive")
}

sde_rows_a <- data.frame(
  Outcome = c("Oil heating share", "Heat pump share", "Gas heating share"),
  Beta = c(round(coef(m1_oil)["treatment"], 4),
           round(coef(m1_hp)["treatment"], 4),
           round(coef(m1_gas)["treatment"], 4)),
  SE = c(round(summary(m1_oil)$se["treatment"], 4),
         round(summary(m1_hp)$se["treatment"], 4),
         round(summary(m1_gas)$se["treatment"], 4)),
  `SD(Y)` = c(round(sd_oil_y, 2), round(sd_hp_2000, 2),
              round(sd(panel$gas_pct[panel$year == 2000], na.rm=TRUE), 2)),
  SDE = c(round(sde_oil, 4), round(sde_hp, 4), round(sde_gas, 4)),
  `SE(SDE)` = c(round(se_oil, 4), round(se_hp, 4), round(se_gas, 4)),
  Classification = c(classify(sde_oil), classify(sde_hp), classify(sde_gas)),
  check.names = FALSE
)

# Panel B: Heterogeneous — split by initial gas infrastructure
# High gas cantons (above median gas_2000) vs low gas
median_gas_2000 <- median(panel$gas_pct[panel$year == 2000], na.rm = TRUE)

panel_hi_gas <- panel %>%
  filter(gas_pct[year == 2000] > median_gas_2000, .by = canton)
panel_lo_gas <- panel %>%
  filter(gas_pct[year == 2000] <= median_gas_2000, .by = canton)

# Check if we have enough observations
cat("High gas cantons:", n_distinct(panel_hi_gas$canton), "\n")
cat("Low gas cantons:", n_distinct(panel_lo_gas$canton), "\n")

m_gas_hi <- feols(gas_pct ~ treatment | canton + year, data = panel_hi_gas, cluster = ~canton)
m_gas_lo <- feols(gas_pct ~ treatment | canton + year, data = panel_lo_gas, cluster = ~canton)

sde_gas_hi <- coef(m_gas_hi)["treatment"] * sd(panel_hi_gas$treatment[panel_hi_gas$year > 2000]) / sd(panel_hi_gas$gas_pct[panel_hi_gas$year == 2000], na.rm=TRUE)
sde_gas_lo <- coef(m_gas_lo)["treatment"] * sd(panel_lo_gas$treatment[panel_lo_gas$year > 2000]) / sd(panel_lo_gas$gas_pct[panel_lo_gas$year == 2000], na.rm=TRUE)

se_gas_hi <- summary(m_gas_hi)$se["treatment"] * sd(panel_hi_gas$treatment[panel_hi_gas$year > 2000]) / sd(panel_hi_gas$gas_pct[panel_hi_gas$year == 2000], na.rm=TRUE)
se_gas_lo <- summary(m_gas_lo)$se["treatment"] * sd(panel_lo_gas$treatment[panel_lo_gas$year > 2000]) / sd(panel_lo_gas$gas_pct[panel_lo_gas$year == 2000], na.rm=TRUE)

sde_rows_b <- data.frame(
  Outcome = c("Gas share (high gas infra.)", "Gas share (low gas infra.)"),
  Beta = c(round(coef(m_gas_hi)["treatment"], 4),
           round(coef(m_gas_lo)["treatment"], 4)),
  SE = c(round(summary(m_gas_hi)$se["treatment"], 4),
         round(summary(m_gas_lo)$se["treatment"], 4)),
  `SD(Y)` = c(round(sd(panel_hi_gas$gas_pct[panel_hi_gas$year == 2000], na.rm=T), 2),
              round(sd(panel_lo_gas$gas_pct[panel_lo_gas$year == 2000], na.rm=T), 2)),
  SDE = c(round(sde_gas_hi, 4), round(sde_gas_lo, 4)),
  `SE(SDE)` = c(round(se_gas_hi, 4), round(se_gas_lo, 4)),
  Classification = c(classify(sde_gas_hi), classify(sde_gas_lo)),
  check.names = FALSE
)

# Build LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does the federal CO2 levy on heating fuels cause cantonal-level fuel switching from oil to gas or heat pumps? ",
  "\\textbf{Policy mechanism:} Switzerland's CO2 levy imposes a per-ton charge on fossil heating fuels (oil and gas), ",
  "increasing from CHF 12/ton in 2008 to CHF 120/ton in 2022, funded by a legislated ratchet that triggers increases ",
  "when national emission reduction targets are missed. One-third of revenue funds building renovation subsidies. ",
  "\\textbf{Outcome definition:} Share of dwellings (\\%) using each energy source for primary heating, from the BFS GWS register. ",
  "\\textbf{Treatment:} Continuous; canton's 2000 Census oil-heating share (proportion) multiplied by the federal levy rate (CHF/ton CO2). ",
  "\\textbf{Data:} BFS Geb\\\"aude- und Wohnungsstatistik (GWS), 2000 and 2021--2024, 26 cantons, 127 canton-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (canton + year), standard errors clustered at canton level. ",
  "\\textbf{Sample:} All 26 Swiss cantons; oil heating share in 2000 ranges from 41\\% (Basel-Stadt) to 74\\% (Jura). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of treatment intensity ",
  "among post-treatment observations and SD($Y$) is the pre-treatment (2000) standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_all <- rbind(sde_rows_a, sde_rows_b)

# Manual LaTeX construction for proper formatting
cat_sde <- function(rows, panel_label) {
  tex <- paste0("\\multicolumn{7}{l}{\\textit{", panel_label, "}} \\\\\n")
  for (i in 1:nrow(rows)) {
    tex <- paste0(tex, rows$Outcome[i], " & ",
                  rows$Beta[i], " & ", rows$SE[i], " & ",
                  rows[i, "SD(Y)"], " & ",
                  rows$SDE[i], " & ", rows[i, "SE(SDE)"], " & ",
                  rows$Classification[i], " \\\\\n")
  }
  return(tex)
}

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  cat_sde(sde_rows_a, "Panel A: Pooled"),
  "\\midrule\n",
  cat_sde(sde_rows_b, "Panel B: By Gas Infrastructure"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("SDE table saved.\n")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat(paste(list.files("../tables/"), collapse="\n"), "\n")
