## ============================================================================
## 06_tables.R — All Tables
## Paper: NLW Bite and Care Home Closures in England (apep_0515)
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel_clean <- panel[!is.na(bite_kaitz) & !is.na(closure_rate)]
panel_clean[, la_id := as.integer(factor(la_name))]

results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ---- Table 1: Summary Statistics ----
cat("=== Table 1: Summary Statistics ===\n")

pre <- panel_clean[year < 2016]
post <- panel_clean[year >= 2016]

make_sumstat <- function(dt, label) {
  vars <- c("n_homes", "n_exits", "n_entries", "net_change", "total_beds",
            "closure_rate", "entry_rate", "bite_kaitz")
  out <- data.table(
    Variable = c("Care homes (stock)", "Closures", "New registrations",
                 "Net change", "Total beds", "Closure rate (\\%)",
                 "Entry rate (\\%)", "NLW Kaitz index (bite)"),
    Period = label,
    Mean = sapply(vars, function(v) mean(dt[[v]], na.rm = TRUE)),
    SD = sapply(vars, function(v) sd(dt[[v]], na.rm = TRUE)),
    Min = sapply(vars, function(v) min(dt[[v]], na.rm = TRUE)),
    Max = sapply(vars, function(v) max(dt[[v]], na.rm = TRUE)),
    N = nrow(dt)
  )
  out
}

tab1 <- rbind(
  make_sumstat(pre, "Pre-NLW (2012-2015)"),
  make_sumstat(post, "Post-NLW (2016-2019)")
)

# Format nicely
tab1[, Mean := round(Mean, 2)]
tab1[, SD := round(SD, 2)]
tab1[, Min := round(Min, 2)]
tab1[, Max := round(Max, 2)]

fwrite(tab1, file.path(tab_dir, "tab1_summary_stats.csv"))

# LaTeX version
tab1_tex <- tab1[, .(Variable, Period, Mean, SD, Min, Max)]
# Create wide format: pre and post side by side
pre_tab <- tab1_tex[Period == "Pre-NLW (2012-2015)", .(Variable, Mean_Pre = Mean, SD_Pre = SD)]
post_tab <- tab1_tex[Period == "Post-NLW (2016-2019)", .(Variable, Mean_Post = Mean, SD_Post = SD)]
tab1_wide <- merge(pre_tab, post_tab, by = "Variable")

latex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics: Care Home Market by NLW Period}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-NLW (2012--2015)} & \\multicolumn{2}{c}{Post-NLW (2016--2019)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in 1:nrow(tab1_wide)) {
  latex_lines <- c(latex_lines, sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\",
    tab1_wide$Variable[i], tab1_wide$Mean_Pre[i], tab1_wide$SD_Pre[i],
    tab1_wide$Mean_Post[i], tab1_wide$SD_Post[i]))
}

latex_lines <- c(latex_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\", nrow(pre), nrow(post)),
  sprintf("Local Authorities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          length(unique(pre$la_name)), length(unique(post$la_name))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel of 134 English Local Authorities, 2012--2019 (LA-year level; 134 $\\times$ 8 = 1,072 observations). Each row aggregates across all care homes in the LA-year cell. Closure rate = closures / (stock + closures) $\\times$ 100. The Kaitz index is a time-invariant cross-sectional measure: NLW (\\pounds7.20 in 2016) / LA median hourly wage (2015 ASHE). It is identical across periods by construction. Source: CQC, NOMIS ASHE.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(latex_lines, file.path(tab_dir, "tab1_summary_stats.tex"))

## ---- Table 2: Main DiD Results ----
cat("=== Table 2: Main Results ===\n")

# Use modelsummary for main regression table
model_list <- list(
  "(1)" = results$m1,
  "(2)" = results$m2,
  "(3)" = results$m_homes,
  "(4)" = results$m_beds,
  "(5)" = results$m_net
)

# Custom coefficient labels
cm <- c(
  "bite_kaitz:post" = "Bite $\\times$ Post",
  "log(pop_total)" = "Log(Population)",
  "log(pop_65plus)" = "Log(Pop 85+)"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = 0),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = 3)
)

ms_tab2 <- modelsummary(
  model_list,
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  output = file.path(tab_dir, "tab2_main_results.tex"),
  title = "Main Results: NLW Bite and Care Home Market Outcomes",
  notes = list("Standard errors clustered at the Local Authority level in parentheses.",
               "All models include LA and year fixed effects.",
               "Columns (1)-(2): closure rate. (3): number of homes (level). (4): total beds (level). (5): net change (homes).",
               "High $R^2$ in (3)-(4) reflects LA fixed effects absorbing cross-sectional stock variation."),
  escape = FALSE
)

## ---- Table 3: Event Study Coefficients ----
cat("=== Table 3: Event Study ===\n")

es <- results$es_model
es_coefs <- coeftable(es)
es_dt <- data.table(
  Year = as.integer(gsub("year::(\\d+):bite_kaitz", "\\1", rownames(es_coefs))),
  Coefficient = es_coefs[, 1],
  SE = es_coefs[, 2],
  p_value = es_coefs[, 4]
)
es_dt <- rbind(es_dt, data.table(Year = 2015, Coefficient = 0, SE = NA, p_value = NA))
es_dt <- es_dt[order(Year)]

fwrite(es_dt, file.path(tab_dir, "tab3_event_study.csv"))

latex_es <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Event Study Coefficients: Bite $\\times$ Year on Closure Rate}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year & Coefficient & Std. Error & $p$-value \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_dt)) {
  if (es_dt$Year[i] == 2015) {
    latex_es <- c(latex_es, sprintf("%d & [Reference] & --- & --- \\\\", es_dt$Year[i]))
  } else {
    stars <- ifelse(es_dt$p_value[i] < 0.01, "***",
             ifelse(es_dt$p_value[i] < 0.05, "**",
             ifelse(es_dt$p_value[i] < 0.1, "*", "")))
    latex_es <- c(latex_es, sprintf("%d & %.3f%s & (%.3f) & %.3f \\\\",
      es_dt$Year[i], es_dt$Coefficient[i], stars, es_dt$SE[i], es_dt$p_value[i]))
  }
  if (es_dt$Year[i] == 2015) {
    latex_es <- c(latex_es, "\\midrule")
  }
}

latex_es <- c(latex_es,
  "\\midrule",
  sprintf("Observations & \\multicolumn{3}{c}{%d} \\\\", nobs(results$es_model)),
  sprintf("Local Authorities & \\multicolumn{3}{c}{%d} \\\\", length(unique(panel_clean$la_name))),
  "LA FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable: closure rate (\\%). Each coefficient represents the interaction of the Kaitz index with a year dummy (reference: 2015). Standard errors clustered by LA. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(latex_es, file.path(tab_dir, "tab3_event_study.tex"))

## ---- Table 4: Robustness ----
cat("=== Table 4: Robustness ===\n")

rob_models <- list(
  "(1) Baseline" = results$m1,
  "(2) Narrow window" = robustness$m_narrow,
  "(3) Symmetric window" = robustness$m_sym,
  "(4) Trimmed LAs" = robustness$m_trimmed,
  "(5) Tercile treat." = robustness$m_tercile
)

cm_rob <- c(
  "bite_kaitz:post" = "Bite $\\times$ Post",
  "high_bite:post" = "High Bite $\\times$ Post"
)

ms_tab4 <- modelsummary(
  rob_models,
  coef_map = cm_rob,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  output = file.path(tab_dir, "tab4_robustness.tex"),
  title = "Robustness: Alternative Specifications",
  notes = list("Standard errors clustered at the Local Authority level in parentheses.",
               "All models include LA and year fixed effects.",
               "Column (2): 2014-2017 only. (3): 2013-2018 only. (4): drops top/bottom 5\\% LAs by size. (5): binary treatment = top bite tercile."),
  escape = FALSE
)

## ---- Table 5: Placebo Tests ----
cat("=== Table 5: Placebo Tests ===\n")

placebo_models <- list(
  "(1) Entry rate" = robustness$m_entry_placebo,
  "(2) Placebo 2014" = robustness$m_placebo
)

cm_placebo <- c(
  "bite_kaitz:post" = "Bite $\\times$ Post",
  "bite_kaitz:post_placebo" = "Bite $\\times$ Post (Placebo 2014)"
)

ms_tab5 <- modelsummary(
  placebo_models,
  coef_map = cm_placebo,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  output = file.path(tab_dir, "tab5_placebo.tex"),
  title = "Placebo Tests",
  notes = list("Standard errors clustered at the Local Authority level in parentheses.",
               "Column (1): entry rate as outcome (should not respond to NLW). Column (2): placebo treatment at 2014 using pre-period data only (2012--2015)."),
  escape = FALSE
)

## ---- Table 6: Beds Lost (Intensive Margin) ----
cat("=== Table 6: Beds Lost ===\n")

beds_models <- list(
  "(1) Beds lost" = robustness$m_beds_lost
)

cm_beds <- c(
  "bite_kaitz:post" = "Bite $\\times$ Post"
)

ms_tab6 <- modelsummary(
  beds_models,
  coef_map = cm_beds,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  output = file.path(tab_dir, "tab6_beds_lost.tex"),
  title = "Intensive Margin: Beds Lost per Year",
  notes = list("Standard errors clustered at the Local Authority level in parentheses.",
               "LA and year fixed effects included.",
               "Dependent variable: total beds lost through closures per LA per year."),
  escape = FALSE
)

cat("\nAll tables saved to", tab_dir, "\n")
