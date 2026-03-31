## 05_tables.R — apep_1223: The Choice Tax
## Generate all LaTeX tables

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
advice <- fread(file.path(data_dir, "advice_clean.csv"))
welfare <- fread(file.path(data_dir, "welfare_results.csv"))
load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

pot_order <- c("<10K", "10-29K", "30-49K", "50-99K", "100-249K", "250K+")

# ============================================================
# TABLE 1: Summary Statistics — Access Method by Pot Size
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

tab1 <- panel[, .(
  `Pots per Period` = format(round(mean(total)), big.mark = ","),
  `Full Encash (\\%)` = sprintf("%.1f", mean(share_fullwd, na.rm = TRUE) * 100),
  `Drawdown (\\%)` = sprintf("%.1f", mean(share_drawdown, na.rm = TRUE) * 100),
  `Annuity (\\%)` = sprintf("%.1f", mean(share_annuity, na.rm = TRUE) * 100),
  `UFPLS (\\%)` = sprintf("%.1f", mean(share_ufpls, na.rm = TRUE) * 100)
), by = .(pot_size)]
tab1[, pot_idx := match(pot_size, pot_order)]
setorder(tab1, pot_idx)
tab1[, pot_idx := NULL]
setnames(tab1, "pot_size", "Pot Size")

# Add totals row
totals <- panel[, .(
  `Pot Size` = "All",
  `Pots per Period` = format(round(mean(total)), big.mark = ","),
  `Full Encash (\\%)` = sprintf("%.1f", weighted.mean(share_fullwd, total, na.rm = TRUE) * 100),
  `Drawdown (\\%)` = sprintf("%.1f", weighted.mean(share_drawdown, total, na.rm = TRUE) * 100),
  `Annuity (\\%)` = sprintf("%.1f", weighted.mean(share_annuity, total, na.rm = TRUE) * 100),
  `UFPLS (\\%)` = sprintf("%.1f", weighted.mean(share_ufpls, total, na.rm = TRUE) * 100)
)]
tab1 <- rbind(tab1, totals)

# LaTeX output
tab1_tex <- kbl(tab1, format = "latex", booktabs = TRUE, escape = FALSE,
    caption = "Pension Access Method by Pot Size, 2015--2024",
    label = "tab:summary") |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = "Sample: FCA Retirement Income Market Data, H2 2015--H2 2023 (17 half-year periods). Columns show cross-period means. Full Encash = pots fully withdrawn at first access. UFPLS = Uncrystallised Funds Pension Lump Sum (partial withdrawal). Pot sizes exclude Pension Commencement Lump Sum (PCLS).",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Advice Gap by Pot Size (2018-2024)
# ============================================================
cat("Generating Table 2: Advice Gap\n")

advice_avg <- advice[, .(
  `Total Full Withdrawals` = format(sum(total), big.mark = ","),
  `Regulated Advice (\\%)` = sprintf("%.1f", mean(advice_rate) * 100),
  `Pension Wise (\\%)` = sprintf("%.1f", mean(pension_wise / total) * 100),
  `No Advice (\\%)` = sprintf("%.1f", (1 - mean(any_help_rate)) * 100)
), by = pot_size]
advice_avg[, pot_idx := match(pot_size, pot_order)]
setorder(advice_avg, pot_idx)
advice_avg[, pot_idx := NULL]
setnames(advice_avg, "pot_size", "Pot Size")

tab2_tex <- kbl(advice_avg, format = "latex", booktabs = TRUE, escape = FALSE,
    caption = "Advice and Guidance Usage by Pot Size Among Full Withdrawals, 2018--2024",
    label = "tab:advice") |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = "Sample: FCA Retirement Income Market Data, H1 2018--H2 2023 (12 half-year periods). Regulated Advice = used an FCA-regulated financial adviser. Pension Wise = used the government's free guidance service. Percentages are cross-period means.",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab2_tex, file.path(table_dir, "tab2_advice.tex"))

# ============================================================
# TABLE 3: Main Regression Results
# ============================================================
cat("Generating Table 3: Regression Results\n")

# modelsummary table
models_list <- list(
  "Full Encash" = m1,
  "Full Encash (trend)" = m2,
  "Annuity" = m3,
  "Drawdown" = m4
)

cm <- c("log_pot" = "log(Pot Size)",
        "log_pot:time" = "log(Pot Size) $\\times$ Time")

options("modelsummary_format_numeric_latex" = "plain")

modelsummary(models_list,
  output = file.path(table_dir, "tab3_regressions.tex"),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = cm,
  gof_map = c("nobs", "r.squared", "FE: period"),
  title = "Pot-Size Gradient in Pension Access Method",
  notes = list("Standard errors clustered by pot-size band in parentheses. Dependent variable: method share (0--1). All specifications include half-year period fixed effects. Sample: 17 half-year periods $\\times$ 6 pot-size bands, H2 2015--H2 2023."),
  escape = FALSE
)

# ============================================================
# TABLE 4: Welfare Loss from Full Encashment
# ============================================================
cat("Generating Table 4: Welfare Loss\n")

tab4 <- welfare[, .(
  `Pot Size` = pot_size,
  `Median Pot (\\pounds)` = format(pot_mid, big.mark = ","),
  `Return Forgone (\\pounds)` = format(round(return_forgone), big.mark = ","),
  `Tax Penalty (\\pounds)` = format(round(tax_penalty), big.mark = ","),
  `Total Loss (\\pounds)` = format(round(total_loss), big.mark = ","),
  `Loss (\\% of Pot)` = sprintf("%.1f", loss_pct),
  `Total Encash (000s)` = format(round(total_encash / 1000), big.mark = ","),
  `Agg. Loss (\\pounds M)` = format(round(aggregate_loss / 1e6), big.mark = ",")
)]

tab4_tex <- kbl(tab4, format = "latex", booktabs = TRUE, escape = FALSE,
    caption = "Welfare Loss from Full Encashment: Investment Returns Forgone and Tax Penalty",
    label = "tab:welfare") |>
  kable_styling(latex_options = c("hold_position", "scale_down")) |>
  footnote(general = "Return Forgone: present value of investment returns lost by encashing immediately rather than drawing down over 10 years, assuming 5\\% annual real return. Tax Penalty: difference in income tax paid between full encashment in one year and phased drawdown over 10 years, assuming basic-rate taxpayer with no other income and personal allowance of \\pounds12,570. Total Encash: cumulative full withdrawals across all 17 half-year periods in the FCA data. Aggregate Loss = per-pot loss $\\times$ total encashments.",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab4_tex, file.path(table_dir, "tab4_welfare.tex"))

# ============================================================
# TABLE 5: Robustness
# ============================================================
cat("Generating Table 5: Robustness\n")

rob_list <- list(
  "Baseline" = m1,
  "No COVID" = r1,
  "Age 55--64" = r3_young,
  "Age 75+" = r3_old,
  "Early (15--19)" = r4_early,
  "Late (20--24)" = r4_late
)

modelsummary(rob_list,
  output = file.path(table_dir, "tab5_robustness.tex"),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c("log_pot" = "log(Pot Size)"),
  gof_map = c("nobs", "r.squared"),
  title = "Robustness: Full Encashment Share on log(Pot Size)",
  notes = list("Dependent variable: full encashment share. All specifications include period fixed effects. Standard errors clustered by pot-size band. Age subsamples use the 2018--2024 age-disaggregated data (full withdrawal and annuity methods only). Early = H2 2015 to H2 2019; Late = H1 2020 to H2 2023."),
  escape = FALSE
)

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("Generating Table F1: SDE\n")

# Main outcomes: full encashment share, annuity share, advice rate
# Treatment: log(pot size) — continuous
# SD(X) and SD(Y) from the data

sd_fullwd <- sd(panel$share_fullwd, na.rm = TRUE)
sd_annuity <- sd(panel$share_annuity, na.rm = TRUE)
sd_drawdown <- sd(panel$share_drawdown, na.rm = TRUE)
sd_logpot <- sd(panel$log_pot, na.rm = TRUE)

sd_advice <- sd(advice$advice_rate, na.rm = TRUE)
sd_logpot_advice <- sd(advice$log_pot, na.rm = TRUE)

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sde_table <- data.table(
  Outcome = c(
    "Full encashment share",
    "Annuity share",
    "Drawdown share",
    "Regulated advice rate"
  ),
  beta = c(coef(m1)["log_pot"], coef(m3)["log_pot"], coef(m4)["log_pot"], coef(m6)["log_pot"]),
  se = c(se(m1)["log_pot"], se(m3)["log_pot"], se(m4)["log_pot"], se(m6)["log_pot"]),
  sd_y = c(sd_fullwd, sd_annuity, sd_drawdown, sd_advice),
  sd_x = c(sd_logpot, sd_logpot, sd_logpot, sd_logpot_advice)
)

sde_table[, SDE := beta * sd_x / sd_y]
sde_table[, SE_SDE := se * sd_x / sd_y]

# Classification
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

sde_table[, Classification := sapply(SDE, classify_sde)]

# Panel A: Pooled
panel_a <- sde_table[, .(Outcome,
                          `$\\hat{\\beta}$` = sprintf("%.4f", beta),
                          SE = sprintf("%.4f", se),
                          `SD($Y$)` = sprintf("%.4f", sd_y),
                          SDE = sprintf("%.3f", SDE),
                          `SE(SDE)` = sprintf("%.3f", SE_SDE),
                          Classification)]

# Panel B: Heterogeneous (by era: early vs late)
panel_early <- fread(file.path(data_dir, "analysis_panel.csv"))
panel_early[, era := ifelse(as.numeric(sub("H[12]_", "", period)) <= 2019, "early", "late")]

sd_fullwd_early <- sd(panel_early[era == "early"]$share_fullwd, na.rm = TRUE)
sd_fullwd_late <- sd(panel_early[era == "late"]$share_fullwd, na.rm = TRUE)

sde_early <- coef(r4_early)["log_pot"] * sd(panel_early[era == "early"]$log_pot) / sd_fullwd_early
sde_late <- coef(r4_late)["log_pot"] * sd(panel_early[era == "late"]$log_pot) / sd_fullwd_late

panel_b <- data.table(
  Outcome = c("Full encashment (early, 2015--2019)", "Full encashment (late, 2020--2024)"),
  `$\\hat{\\beta}$` = sprintf("%.4f", c(coef(r4_early)["log_pot"], coef(r4_late)["log_pot"])),
  SE = sprintf("%.4f", c(se(r4_early)["log_pot"], se(r4_late)["log_pot"])),
  `SD($Y$)` = sprintf("%.4f", c(sd_fullwd_early, sd_fullwd_late)),
  SDE = sprintf("%.3f", c(sde_early, sde_late)),
  `SE(SDE)` = sprintf("%.3f", c(
    se(r4_early)["log_pot"] * sd(panel_early[era == "early"]$log_pot) / sd_fullwd_early,
    se(r4_late)["log_pot"] * sd(panel_early[era == "late"]$log_pot) / sd_fullwd_late
  )),
  Classification = sapply(c(sde_early, sde_late), classify_sde)
)

# Combine panels
combined_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in 1:nrow(panel_a)) {
  combined_tex <- paste0(combined_tex,
    panel_a$Outcome[i], " & ",
    panel_a$`$\\hat{\\beta}$`[i], " & ",
    panel_a$SE[i], " & ",
    panel_a$`SD($Y$)`[i], " & ",
    panel_a$SDE[i], " & ",
    panel_a$`SE(SDE)`[i], " & ",
    panel_a$Classification[i], " \\\\\n")
}

combined_tex <- paste0(combined_tex,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Early vs.\\ Late Period)}} \\\\\n"
)

for (i in 1:nrow(panel_b)) {
  combined_tex <- paste0(combined_tex,
    panel_b$Outcome[i], " & ",
    panel_b$`$\\hat{\\beta}$`[i], " & ",
    panel_b$SE[i], " & ",
    panel_b$`SD($Y$)`[i], " & ",
    panel_b$SDE[i], " & ",
    panel_b$`SE(SDE)`[i], " & ",
    panel_b$Classification[i], " \\\\\n")
}

# SDE Notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does the UK's Pension Freedoms reform induce regressive decisionmaking, ",
  "where small-pot holders disproportionately choose dominated full-encashment strategies over phased drawdown? ",
  "\\textbf{Policy mechanism:} The Finance Act 2014 (effective April 2015) eliminated the effective annuity mandate ",
  "for defined-contribution pension holders, allowing unrestricted access via full cash withdrawal, flexible drawdown, ",
  "or UFPLS, while financial advice costs (\\pounds1--3K) remained fixed, creating a regressive barrier. ",
  "\\textbf{Outcome definition:} Share of pension pots accessed via full cash withdrawal at first access, ",
  "measured as count of full withdrawals divided by total pots accessed in each pot-size band and half-year period. ",
  "\\textbf{Treatment:} Continuous; log of pot-size band midpoint (\\pounds5K to \\pounds375K). ",
  "\\textbf{Data:} FCA Retirement Income Market Data, H2 2015--H2 2023, 6 pot-size bands $\\times$ 17 half-year periods. ",
  "\\textbf{Method:} OLS with period fixed effects; standard errors clustered by pot-size band. ",
  "\\textbf{Sample:} All DC pension pots accessed for the first time post-reform, reported by FCA-regulated providers. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

combined_tex <- paste0(combined_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(combined_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
