# 05_tables.R — Generate all tables for apep_0895
# Does AML Regulation Actually Detect Money Laundering?

source("00_packages.R")

panel <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")
robust <- readRDS("data/robustness_results.rds")
transposition <- fread("data/transposition_5amld.csv")

dir.create("tables", showWarnings = FALSE)

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
message("=== Table 1: Summary Statistics ===")

pre_data <- panel[treated == 0 & !is.na(ml_offences)]

# Compute summary stats
sum_stats <- rbind(
  data.table(Variable = "ML offences",
             Mean = mean(pre_data$ml_offences, na.rm = TRUE),
             SD = sd(pre_data$ml_offences, na.rm = TRUE),
             Min = min(pre_data$ml_offences, na.rm = TRUE),
             Max = max(pre_data$ml_offences, na.rm = TRUE),
             N = sum(!is.na(pre_data$ml_offences))),
  data.table(Variable = "ML rate per 100k",
             Mean = mean(pre_data$ml_rate, na.rm = TRUE),
             SD = sd(pre_data$ml_rate, na.rm = TRUE),
             Min = min(pre_data$ml_rate, na.rm = TRUE),
             Max = max(pre_data$ml_rate, na.rm = TRUE),
             N = sum(!is.na(pre_data$ml_rate))),
  data.table(Variable = "Property offences",
             Mean = mean(pre_data$property_offences, na.rm = TRUE),
             SD = sd(pre_data$property_offences, na.rm = TRUE),
             Min = min(pre_data$property_offences, na.rm = TRUE),
             Max = max(pre_data$property_offences, na.rm = TRUE),
             N = sum(!is.na(pre_data$property_offences))),
  data.table(Variable = "HPI (2015=100)",
             Mean = mean(pre_data$hpi, na.rm = TRUE),
             SD = sd(pre_data$hpi, na.rm = TRUE),
             Min = min(pre_data$hpi, na.rm = TRUE),
             Max = max(pre_data$hpi, na.rm = TRUE),
             N = sum(!is.na(pre_data$hpi))),
  data.table(Variable = "Population (millions)",
             Mean = mean(pre_data$population, na.rm = TRUE) / 1e6,
             SD = sd(pre_data$population, na.rm = TRUE) / 1e6,
             Min = min(pre_data$population, na.rm = TRUE) / 1e6,
             Max = max(pre_data$population, na.rm = TRUE) / 1e6,
             N = sum(!is.na(pre_data$population)))
)

# Format numbers
sum_stats[, Mean := round(Mean, 2)]
sum_stats[, SD := round(SD, 2)]
sum_stats[, Min := round(Min, 2)]
sum_stats[, Max := round(Max, 2)]

tab1_tex <- kbl(sum_stats, format = "latex", booktabs = TRUE,
                caption = "Summary Statistics (Pre-Treatment Period)",
                label = "tab:summary",
                align = c("l", rep("r", 5))) |>
  kable_styling(latex_options = c("hold_position"))

writeLines(tab1_tex, "tables/tab1_summary.tex")

# ===========================================================================
# Table 2: Transposition Timeline
# ===========================================================================
message("=== Table 2: Transposition Timeline ===")

trans_tab <- transposition[!is.na(iso2) & !is.na(transposition_date),
                            .(Country = name, `ISO` = iso2,
                              `Transposition Date` = format(as.Date(transposition_date), "%B %d, %Y"),
                              `Year` = as.integer(format(as.Date(transposition_date), "%Y")),
                              `N Measures` = n_measures)]
trans_tab <- trans_tab[order(`Year`, Country)]

# Add delay info
deadline <- as.Date("2020-01-10")
trans_tab[, `Delay (months)` := round(as.numeric(
  difftime(transposition[!is.na(iso2) & !is.na(transposition_date)]$transposition_date,
           deadline, units = "days")) / 30.44, 1)]

# Reorder for clean display
trans_tab2 <- transposition[!is.na(iso2) & !is.na(transposition_date)]
trans_tab2[, delay_months := round(as.numeric(difftime(as.Date(transposition_date),
                                                        deadline, units = "days")) / 30.44, 1)]
trans_tab2 <- trans_tab2[order(transposition_date), .(Country = name,
                                                        `Transposition` = format(as.Date(transposition_date), "%Y-%m"),
                                                        `Delay` = delay_months)]

tab2_tex <- kbl(trans_tab2, format = "latex", booktabs = TRUE,
                caption = "5AMLD Transposition Timeline by Member State",
                label = "tab:transposition",
                align = c("l", "c", "r")) |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = paste0("Transposition deadline: January 10, 2020. ",
                             "Delay measured in months from deadline. ",
                             "Negative values indicate early transposition. ",
                             "Source: CELLAR SPARQL (EUR-Lex)."),
           general_title = "", threeparttable = TRUE)

writeLines(tab2_tex, "tables/tab2_transposition.tex")

# ===========================================================================
# Table 3: Main Results
# ===========================================================================
message("=== Table 3: Main Results ===")

# Build results table manually for clean formatting
main_res <- data.table(
  Specification = c("CS: Log(ML offences)", "CS: ML rate/100k",
                    "TWFE: Log(ML offences)", "TWFE: ML rate/100k"),
  Estimate = c(
    results$agg_main$overall.att,
    if (!is.null(results$agg_rate)) results$agg_rate$overall.att else NA_real_,
    coef(results$twfe_log)["treated"],
    coef(results$twfe_rate)["treated"]
  ),
  SE = c(
    results$agg_main$overall.se,
    if (!is.null(results$agg_rate)) results$agg_rate$overall.se else NA_real_,
    sqrt(vcov(results$twfe_log)["treated", "treated"]),
    sqrt(vcov(results$twfe_rate)["treated", "treated"])
  )
)

main_res[, CI_low := Estimate - 1.96 * SE]
main_res[, CI_high := Estimate + 1.96 * SE]
main_res[, p_value := 2 * pnorm(-abs(Estimate / SE))]
main_res[, Stars := fifelse(p_value < 0.01, "***",
                             fifelse(p_value < 0.05, "**",
                                     fifelse(p_value < 0.1, "*", "")))]

# Format
main_res[, Estimate_fmt := paste0(formatC(Estimate, format = "f", digits = 3), Stars)]
main_res[, SE_fmt := paste0("(", formatC(SE, format = "f", digits = 3), ")")]
main_res[, CI_fmt := paste0("[", formatC(CI_low, format = "f", digits = 3), ", ",
                             formatC(CI_high, format = "f", digits = 3), "]")]

n_countries <- uniqueN(panel[!is.na(log_ml), geo])
n_obs_main <- nrow(panel[!is.na(log_ml)])

# Write LaTeX manually for full control
tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of 5AMLD Transposition on Money Laundering Offences}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & \\multicolumn{2}{c}{Callaway-Sant'Anna} & \\multicolumn{2}{c}{TWFE} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Log(ML) & ML rate & Log(ML) & ML rate \\\\",
  "\\midrule"
)

# Add estimate rows
tab3_lines <- c(tab3_lines,
  paste0("ATT & ", main_res$Estimate_fmt[1], " & ", main_res$Estimate_fmt[2],
         " & ", main_res$Estimate_fmt[3], " & ", main_res$Estimate_fmt[4], " \\\\"),
  paste0(" & ", main_res$SE_fmt[1], " & ", main_res$SE_fmt[2],
         " & ", main_res$SE_fmt[3], " & ", main_res$SE_fmt[4], " \\\\"),
  paste0(" & ", main_res$CI_fmt[1], " & ", main_res$CI_fmt[2],
         " & ", main_res$CI_fmt[3], " & ", main_res$CI_fmt[4], " \\\\"),
  "\\midrule",
  paste0("Countries & ", n_countries, " & ", n_countries,
         " & ", n_countries, " & ", n_countries, " \\\\"),
  paste0("Observations & ", n_obs_main, " & ", n_obs_main,
         " & ", n_obs_main, " & ", n_obs_main, " \\\\"),
  paste0("Comparison & Not-yet & Not-yet & --- & --- \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  paste0("\\item \\textit{Notes:} Columns (1)--(2) report Callaway and Sant'Anna (2021) ",
         "ATT estimates using not-yet-treated countries as the comparison group. ",
         "Columns (3)--(4) report static TWFE estimates with country and year fixed effects. ",
         "Standard errors clustered at country level in parentheses. ",
         "95\\% confidence intervals in brackets. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_main.tex")

# ===========================================================================
# Table 4: Robustness
# ===========================================================================
message("=== Table 4: Robustness ===")

robust_res <- data.table(
  Test = character(),
  Estimate = numeric(),
  SE = numeric(),
  p_value = numeric()
)

# Add placebo results
if (!is.null(robust$agg_property)) {
  robust_res <- rbind(robust_res, data.table(
    Test = "Placebo: Property crimes",
    Estimate = robust$agg_property$overall.att,
    SE = robust$agg_property$overall.se,
    p_value = 2 * pnorm(-abs(robust$agg_property$overall.att / robust$agg_property$overall.se))
  ))
}

if (!is.null(robust$agg_assault)) {
  robust_res <- rbind(robust_res, data.table(
    Test = "Placebo: Assault",
    Estimate = robust$agg_assault$overall.att,
    SE = robust$agg_assault$overall.se,
    p_value = 2 * pnorm(-abs(robust$agg_assault$overall.att / robust$agg_assault$overall.se))
  ))
}

# Never-treated comparison
if (!is.null(robust$agg_never)) {
  robust_res <- rbind(robust_res, data.table(
    Test = "Never-treated comparison",
    Estimate = robust$agg_never$overall.att,
    SE = robust$agg_never$overall.se,
    p_value = 2 * pnorm(-abs(robust$agg_never$overall.att / robust$agg_never$overall.se))
  ))
}

# Continuous treatment
robust_res <- rbind(robust_res, data.table(
  Test = "Continuous: Delay months",
  Estimate = coef(robust$twfe_delay)["post_delay"],
  SE = sqrt(vcov(robust$twfe_delay)["post_delay", "post_delay"]),
  p_value = pvalue(robust$twfe_delay)["post_delay"]
))

# ML share
if (!is.null(robust$agg_share)) {
  robust_res <- rbind(robust_res, data.table(
    Test = "ML share of total crime",
    Estimate = robust$agg_share$overall.att,
    SE = robust$agg_share$overall.se,
    p_value = 2 * pnorm(-abs(robust$agg_share$overall.att / robust$agg_share$overall.se))
  ))
}

# LOO range
if (nrow(robust$loo_dt) > 0) {
  robust_res <- rbind(robust_res, data.table(
    Test = paste0("Leave-one-out range [",
                  formatC(min(robust$loo_dt$att), format = "f", digits = 3), ", ",
                  formatC(max(robust$loo_dt$att), format = "f", digits = 3), "]"),
    Estimate = NA_real_, SE = NA_real_, p_value = NA_real_
  ))
}

# Format
robust_res[, Stars := fifelse(is.na(p_value), "",
                               fifelse(p_value < 0.01, "***",
                                       fifelse(p_value < 0.05, "**",
                                               fifelse(p_value < 0.1, "*", ""))))]
robust_res[, Est_fmt := fifelse(is.na(Estimate), "---",
                                 paste0(formatC(Estimate, format = "f", digits = 3), Stars))]
robust_res[, SE_fmt := fifelse(is.na(SE), "---",
                                paste0("(", formatC(SE, format = "f", digits = 3), ")"))]

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Test & Estimate & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(robust_res))) {
  tab4_lines <- c(tab4_lines,
    paste0(robust_res$Test[i], " & ", robust_res$Est_fmt[i],
           " & ", robust_res$SE_fmt[i], " \\\\"))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  paste0("\\item \\textit{Notes:} All specifications use log(ML offences + 1) as the outcome ",
         "unless otherwise noted. Placebo tests apply the same CS estimator to property crimes and ",
         "assault, which should not respond to AML regulation. ",
         "Leave-one-out drops each treated country sequentially. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_robustness.tex")

# ===========================================================================
# Table 5 (Appendix F1): Standardized Effect Sizes
# ===========================================================================
message("=== SDE Table ===")

# Compute SDEs
pre_sd_log_ml <- sd(panel[treated == 0 & !is.na(log_ml), log_ml])
pre_sd_ml_rate <- sd(panel[treated == 0 & !is.na(ml_rate), ml_rate])

# Main: log ML
sde_log_ml <- results$agg_main$overall.att / pre_sd_log_ml
se_sde_log_ml <- results$agg_main$overall.se / pre_sd_log_ml

# Rate
if (!is.null(results$agg_rate)) {
  sde_rate <- results$agg_rate$overall.att / pre_sd_ml_rate
  se_sde_rate <- results$agg_rate$overall.se / pre_sd_ml_rate
} else {
  sde_rate <- NA_real_
  se_sde_rate <- NA_real_
}

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE rows — Panel A (Pooled)
sde_rows_a <- list(
  list(outcome = "Log(ML offences)", beta = results$agg_main$overall.att,
       se = results$agg_main$overall.se, sd_y = pre_sd_log_ml,
       sde = sde_log_ml, se_sde = se_sde_log_ml)
)

if (!is.null(results$agg_rate)) {
  sde_rows_a[[2]] <- list(outcome = "ML rate per 100k", beta = results$agg_rate$overall.att,
                           se = results$agg_rate$overall.se, sd_y = pre_sd_ml_rate,
                           sde = sde_rate, se_sde = se_sde_rate)
}

# Panel B (Heterogeneous) — split by early vs late transposers
# Early = transposed before deadline (treat_year <= 2019)
# Late = transposed after deadline (treat_year >= 2020)
early_countries <- unique(panel[treat_year > 0 & treat_year <= 2019, geo])
late_countries <- unique(panel[treat_year > 0 & treat_year >= 2020, geo])

# Early transposers
cs_early_data <- panel[geo %in% c(early_countries, unique(panel[treat_year == 0, geo])) & !is.na(log_ml)]
cs_early_data[, country_id := as.integer(factor(geo))]

cs_early <- tryCatch({
  att_gt(yname = "log_ml", tname = "year", idname = "country_id", gname = "treat_year",
         data = as.data.frame(cs_early_data), control_group = "notyettreated",
         base_period = "universal", est_method = "reg")
}, error = function(e) NULL)

if (!is.null(cs_early)) {
  agg_early <- aggte(cs_early, type = "simple")
  sde_early <- agg_early$overall.att / pre_sd_log_ml
  se_sde_early <- agg_early$overall.se / pre_sd_log_ml
} else {
  agg_early <- NULL
  sde_early <- NA_real_
  se_sde_early <- NA_real_
}

# Late transposers
cs_late_data <- panel[geo %in% c(late_countries, unique(panel[treat_year == 0, geo])) & !is.na(log_ml)]
cs_late_data[, country_id := as.integer(factor(geo))]

cs_late <- tryCatch({
  att_gt(yname = "log_ml", tname = "year", idname = "country_id", gname = "treat_year",
         data = as.data.frame(cs_late_data), control_group = "notyettreated",
         base_period = "universal", est_method = "reg")
}, error = function(e) NULL)

if (!is.null(cs_late)) {
  agg_late <- aggte(cs_late, type = "simple")
  sde_late <- agg_late$overall.att / pre_sd_log_ml
  se_sde_late <- agg_late$overall.se / pre_sd_log_ml
} else {
  agg_late <- NULL
  sde_late <- NA_real_
  se_sde_late <- NA_real_
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (22 member states). ",
  "\\textbf{Research question:} Does national transposition of the EU 5th Anti-Money Laundering Directive ",
  "(5AMLD, 2018/843) increase police-recorded money laundering offences? ",
  "\\textbf{Policy mechanism:} 5AMLD requires public beneficial ownership registers for corporate entities, ",
  "extends AML obligations to virtual currency exchanges and custodian wallet providers, ",
  "enhances due diligence for high-risk third countries, and mandates centralized bank account identification ",
  "mechanisms, collectively expanding the infrastructure for detecting suspicious financial activity. ",
  "\\textbf{Outcome definition:} Police-recorded money laundering offences (Eurostat crim\\_off\\_cat, ICCS code 07041), ",
  "counting the number of offences recorded by national police in each country-year. ",
  "\\textbf{Treatment:} Binary; takes value one in the year a member state formally notified the Commission ",
  "of national 5AMLD transposition and all subsequent years. ",
  "\\textbf{Data:} Eurostat crime statistics (crim\\_off\\_cat) and CELLAR SPARQL transposition dates, ",
  "22 EU member states, 2014--2022, country-year level, ",
  nrow(panel[!is.na(log_ml)]), " observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) with not-yet-treated comparison group, ",
  "standard errors clustered at country level. ",
  "\\textbf{Sample:} EU member states with non-missing money laundering offence data for at least five years; ",
  "countries with fewer than five years of data excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build SDE LaTeX table
sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

# Panel A rows
for (r in sde_rows_a) {
  sde_lines <- c(sde_lines,
    paste0(r$outcome, " & ",
           formatC(r$beta, format = "f", digits = 3), " & ",
           formatC(r$se, format = "f", digits = 3), " & ",
           formatC(r$sd_y, format = "f", digits = 3), " & ",
           formatC(r$sde, format = "f", digits = 3), " & ",
           formatC(r$se_sde, format = "f", digits = 3), " & ",
           classify_sde(r$sde), " \\\\"))
}

# Panel B
sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Early vs.\\ Late Transposition)}} \\\\"
)

if (!is.null(agg_early)) {
  sde_lines <- c(sde_lines,
    paste0("Early transposers & ",
           formatC(agg_early$overall.att, format = "f", digits = 3), " & ",
           formatC(agg_early$overall.se, format = "f", digits = 3), " & ",
           formatC(pre_sd_log_ml, format = "f", digits = 3), " & ",
           formatC(sde_early, format = "f", digits = 3), " & ",
           formatC(se_sde_early, format = "f", digits = 3), " & ",
           classify_sde(sde_early), " \\\\"))
}

if (!is.null(agg_late)) {
  sde_lines <- c(sde_lines,
    paste0("Late transposers & ",
           formatC(agg_late$overall.att, format = "f", digits = 3), " & ",
           formatC(agg_late$overall.se, format = "f", digits = 3), " & ",
           formatC(pre_sd_log_ml, format = "f", digits = 3), " & ",
           formatC(sde_late, format = "f", digits = 3), " & ",
           formatC(se_sde_late, format = "f", digits = 3), " & ",
           classify_sde(sde_late), " \\\\"))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "tables/tabF1_sde.tex")

message("=== All tables generated ===")
