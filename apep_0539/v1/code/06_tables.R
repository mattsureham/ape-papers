## 06_tables.R — All tables
## APEP Paper apep_0539: Less Cash, Less Crime?

source("00_packages.R")
data_dir <- "../data"
tbl_dir <- "../tables"
dir.create(tbl_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
main_results <- fread(file.path(data_dir, "main_results.csv"))
twfe_results <- readRDS(file.path(data_dir, "twfe_results.rds"))
cs_results <- readRDS(file.path(data_dir, "cs_did_results.rds"))
ebt_timing <- fread(file.path(data_dir, "ebt_timing.csv"))
mde_data <- fread(file.path(data_dir, "mde_results.csv"))
loo_results <- fread(file.path(data_dir, "loo_results.csv"))
timing_results <- readRDS(file.path(data_dir, "timing_exogeneity.rds"))
twfe_trends <- readRDS(file.path(data_dir, "twfe_trends.rds"))
sunab_results <- readRDS(file.path(data_dir, "sunab_results.rds"))

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
cat("Table 1: Summary statistics...\n")

sumstat <- panel %>%
  summarise(
    across(
      c(property_crime_rate, burglary_rate, larceny_rate,
        robbery_rate, motor_vehicle_theft_rate, violent_crime_rate, population),
      list(
        mean = ~mean(., na.rm = TRUE),
        sd = ~sd(., na.rm = TRUE),
        min = ~min(., na.rm = TRUE),
        max = ~max(., na.rm = TRUE),
        n = ~sum(!is.na(.))
      )
    )
  ) %>%
  pivot_longer(everything(),
               names_to = c("variable", "stat"),
               names_pattern = "(.+)_(mean|sd|min|max|n)$") %>%
  pivot_wider(names_from = stat, values_from = value) %>%
  mutate(variable = case_when(
    variable == "property_crime_rate" ~ "Property Crime Rate",
    variable == "burglary_rate" ~ "Burglary Rate",
    variable == "larceny_rate" ~ "Larceny-Theft Rate",
    variable == "robbery_rate" ~ "Robbery Rate",
    variable == "motor_vehicle_theft_rate" ~ "Motor Vehicle Theft Rate",
    variable == "violent_crime_rate" ~ "Violent Crime Rate",
    variable == "population" ~ "Population"
  ))

fwrite(sumstat, file.path(data_dir, "summary_stats.csv"))

tab1_tex <- sumstat %>%
  mutate(across(c(mean, sd, min, max), ~ifelse(variable == "Population",
                                                 formatC(., format = "f", digits = 0, big.mark = ","),
                                                 formatC(., format = "f", digits = 1)))) %>%
  mutate(n = formatC(as.integer(n), format = "d", big.mark = ",")) %>%
  kbl(col.names = c("Variable", "Mean", "SD", "Min", "Max", "N"),
      format = "latex", booktabs = TRUE, linesep = "",
      caption = "Summary Statistics: Crime Rates per 100,000 Population",
      label = "sumstat") %>%
  kable_styling(latex_options = c("hold_position"))

writeLines(tab1_tex, file.path(tbl_dir, "tab1_sumstat.tex"))

# ===========================================================================
# Table 2: EBT Adoption Timeline
# ===========================================================================
cat("Table 2: EBT adoption timeline...\n")

# Filter to states in analysis sample (exclude 10 missing states)
excluded_states <- c("AL", "MS", "MO", "MT", "NE", "NJ", "NM", "NC", "ND", "OK")
ebt_timing_sample <- ebt_timing %>% filter(!state_abbr %in% excluded_states)

ebt_summary <- ebt_timing_sample %>%
  arrange(ebt_year) %>%
  group_by(ebt_year) %>%
  summarise(states = paste(sort(state_abbr), collapse = ", "),
            n_states = n(),
            .groups = "drop") %>%
  mutate(cumulative = cumsum(n_states))

fwrite(ebt_summary, file.path(data_dir, "ebt_adoption_summary.csv"))

tab2_tex <- ebt_summary %>%
  kbl(col.names = c("Year", "States", "N", "Cumulative"),
      format = "latex", booktabs = TRUE, linesep = "",
      caption = "Statewide EBT Adoption Timeline",
      label = "ebt_timeline") %>%
  kable_styling(latex_options = c("hold_position"))

writeLines(tab2_tex, file.path(tbl_dir, "tab2_ebt_timeline.tex"))

# ===========================================================================
# Table 3: Main Results — CS-DiD and TWFE
# ===========================================================================
cat("Table 3: Main results...\n")

tab3_data <- main_results %>%
  mutate(
    CS_cell = paste0(formatC(CS_ATT, format = "f", digits = 4), CS_stars,
                     "\n(", formatC(CS_SE, format = "f", digits = 4), ")"),
    CS_pct_cell = formatC(CS_pct, format = "f", digits = 2),
    TWFE_cell = paste0(formatC(TWFE_coef, format = "f", digits = 4),
                       case_when(
                         abs(TWFE_coef / TWFE_SE) > 2.576 ~ "***",
                         abs(TWFE_coef / TWFE_SE) > 1.96 ~ "**",
                         abs(TWFE_coef / TWFE_SE) > 1.645 ~ "*",
                         TRUE ~ ""
                       ),
                       "\n(", formatC(TWFE_SE, format = "f", digits = 4), ")")
  )

# Build LaTeX manually for better formatting
tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of EBT on Crime Rates: Main Results}",
  "\\label{tab:main_results}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Callaway-Sant'Anna} & \\multicolumn{2}{c}{TWFE} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Outcome & ATT & \\% Effect & Coefficient & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(main_results))) {
  row <- main_results[i, ]
  cs_stars <- ifelse(is.na(row$CS_stars) | row$CS_stars == "", "", row$CS_stars)
  twfe_stars <- ifelse(abs(row$TWFE_coef / row$TWFE_SE) > 2.576, "***",
                       ifelse(abs(row$TWFE_coef / row$TWFE_SE) > 1.96, "**",
                              ifelse(abs(row$TWFE_coef / row$TWFE_SE) > 1.645, "*", "")))

  line1 <- paste0(row$Outcome, " & ",
                   formatC(row$CS_ATT, format = "f", digits = 4), cs_stars, " & ",
                   formatC(row$CS_pct, format = "f", digits = 2), "\\% & ",
                   formatC(row$TWFE_coef, format = "f", digits = 4), twfe_stars, " & ",
                   formatC(row$TWFE_SE, format = "f", digits = 4), " \\\\")
  line2 <- paste0(" & (", formatC(row$CS_SE, format = "f", digits = 4), ") & & & \\\\")
  tab3_lines <- c(tab3_lines, line1, line2)
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  paste0("State FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\"),
  paste0("Year FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\"),
  paste0("States & \\multicolumn{2}{c}{", n_distinct(panel$state_abbr), "} & \\multicolumn{2}{c}{", n_distinct(panel$state_abbr), "} \\\\"),
  paste0("Observations & \\multicolumn{2}{c}{", formatC(nrow(panel), big.mark = ","), "} & \\multicolumn{2}{c}{", formatC(nrow(panel), big.mark = ","), "} \\\\"),
  "\\bottomrule",
  "\\multicolumn{5}{l}{\\footnotesize Standard errors clustered at the state level in parentheses.} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tbl_dir, "tab3_main_results.tex"))

# ===========================================================================
# Table 4: Robustness Checks
# ===========================================================================
cat("Table 4: Robustness...\n")

# Collect robustness estimates
sa_property_att <- mean(coef(sunab_results$property)[grepl("year::", names(coef(sunab_results$property))) &
                                                       !grepl("-", names(coef(sunab_results$property)))],
                        na.rm = TRUE)
sa_burglary_att <- mean(coef(sunab_results$burglary)[grepl("year::", names(coef(sunab_results$burglary))) &
                                                       !grepl("-", names(coef(sunab_results$burglary)))],
                        na.rm = TRUE)

cs_levels <- readRDS(file.path(data_dir, "cs_levels_results.rds"))

# Load Sun-Abraham aggregate results
sunab_agg <- readRDS(file.path(data_dir, "sunab_agg.rds"))

robust_df <- data.frame(
  Specification = c(
    "CS-DiD (main, log)",
    "Sun-Abraham (log)",
    "TWFE with state trends (log)",
    "CS-DiD (levels, per 100K)"
  ),
  Property = c(
    cs_results$agg_property$overall.att,
    sunab_agg$property_att,
    coef(twfe_trends$property),
    cs_levels$agg_property$overall.att
  ),
  Property_SE = c(
    cs_results$agg_property$overall.se,
    sunab_agg$property_se,
    se(twfe_trends$property),
    cs_levels$agg_property$overall.se
  ),
  Burglary = c(
    cs_results$agg_burglary$overall.att,
    sunab_agg$burglary_att,
    coef(twfe_trends$burglary),
    cs_levels$agg_burglary$overall.att
  ),
  Burglary_SE = c(
    cs_results$agg_burglary$overall.se,
    sunab_agg$burglary_se,
    se(twfe_trends$burglary),
    cs_levels$agg_burglary$overall.se
  )
)

fwrite(robust_df, file.path(data_dir, "robustness_table.csv"))

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness of Main Results}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Property Crime} & \\multicolumn{2}{c}{Burglary} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Specification & Estimate & SE & Estimate & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(robust_df))) {
  r <- robust_df[i, ]
  p_est <- formatC(r$Property, format = "f", digits = 4)
  p_se <- formatC(r$Property_SE, format = "f", digits = 4)
  b_est <- formatC(r$Burglary, format = "f", digits = 4)
  b_se <- formatC(r$Burglary_SE, format = "f", digits = 4)

  # Special formatting for levels spec
  if (i == 4) {
    p_est <- formatC(r$Property, format = "f", digits = 1)
    p_se <- formatC(r$Property_SE, format = "f", digits = 1)
    b_est <- formatC(r$Burglary, format = "f", digits = 1)
    b_se <- formatC(r$Burglary_SE, format = "f", digits = 1)
  }

  tab4_lines <- c(tab4_lines,
    paste0(r$Specification, " & ", p_est, " & (", p_se, ") & ",
           b_est, " & (", b_se, ") \\\\"))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  paste0("LOO range (property) & \\multicolumn{4}{c}{[",
         formatC(min(loo_results$property_att, na.rm = TRUE), format = "f", digits = 4), ", ",
         formatC(max(loo_results$property_att, na.rm = TRUE), format = "f", digits = 4), "]} \\\\"),
  paste0("MDE (80\\% power) & \\multicolumn{2}{c}{",
         formatC(mde_data$mde_pct[1], format = "f", digits = 1),
         "\\%} & \\multicolumn{2}{c}{",
         formatC(mde_data$mde_pct[2], format = "f", digits = 1), "\\%} \\\\"),
  "\\midrule",
  paste0("States & \\multicolumn{4}{c}{", n_distinct(panel$state_abbr), "} \\\\"),
  paste0("Observations & \\multicolumn{4}{c}{", formatC(nrow(panel), big.mark = ","), "} \\\\"),
  "\\bottomrule",
  "\\multicolumn{5}{l}{\\footnotesize Log specifications report ATT in log points; levels in rates per 100,000.} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize Standard errors clustered at the state level. LOO = leave-one-out.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tbl_dir, "tab4_robustness.tex"))

# ===========================================================================
# Table 5: Timing Exogeneity
# ===========================================================================
cat("Table 5: Timing exogeneity...\n")

timing_reg <- timing_results$reg
timing_coefs <- summary(timing_reg)$coefficients

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Timing Exogeneity Test: Pre-Period Characteristics and EBT Adoption Year}",
  "\\label{tab:timing}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Variable & Coefficient & Std. Error \\\\",
  "\\midrule"
)

var_labels <- c("Intercept", "Mean Property Crime Rate", "Mean Burglary Rate",
                "Mean Violent Crime Rate", "Log Population")
for (i in seq_len(nrow(timing_coefs))) {
  stars <- ifelse(timing_coefs[i, 4] < 0.01, "***",
                  ifelse(timing_coefs[i, 4] < 0.05, "**",
                         ifelse(timing_coefs[i, 4] < 0.10, "*", "")))
  tab5_lines <- c(tab5_lines,
    paste0(var_labels[i], " & ",
           formatC(timing_coefs[i, 1], format = "f", digits = 3), stars, " & (",
           formatC(timing_coefs[i, 2], format = "f", digits = 3), ") \\\\"))
}

f_stat <- summary(timing_reg)$fstatistic
f_pval <- pf(f_stat[1], f_stat[2], f_stat[3], lower.tail = FALSE)

tab5_lines <- c(tab5_lines,
  "\\midrule",
  paste0("$R^2$ & \\multicolumn{2}{c}{", formatC(summary(timing_reg)$r.squared, format = "f", digits = 3), "} \\\\"),
  paste0("F-statistic & \\multicolumn{2}{c}{", formatC(f_stat[1], format = "f", digits = 2), "} \\\\"),
  paste0("F-test $p$-value & \\multicolumn{2}{c}{", formatC(f_pval, format = "f", digits = 3), "} \\\\"),
  paste0("N & \\multicolumn{2}{c}{", nrow(timing_results$pre_chars), "} \\\\"),
  "\\bottomrule",
  "\\multicolumn{3}{l}{\\footnotesize Dependent variable: Year of statewide EBT adoption.} \\\\",
  "\\multicolumn{3}{l}{\\footnotesize Pre-period characteristics averaged over 1990--1995.} \\\\",
  "\\multicolumn{3}{l}{\\footnotesize $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tbl_dir, "tab5_timing.tex"))

cat("=== All tables saved ===\n")
