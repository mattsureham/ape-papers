# ==============================================================================
# 06_tables.R — Generate all tables
# apep_0535: Gas Tax Hikes and Macroeconomic Beliefs
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

ces <- fread(file.path(data_dir, "ces_analysis.csv"))

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================

cat("Table 1: Summary Statistics\n")

# Panel A: Full sample
panel_a <- ces %>%
  summarize(
    `Mean pessimism` = mean(pessimism, na.rm = TRUE),
    `SD pessimism` = sd(pessimism, na.rm = TRUE),
    `Pct pessimistic` = mean(pessimistic, na.rm = TRUE) * 100,
    `Mean unemployment` = mean(unemp_rate, na.rm = TRUE),
    `Mean income growth` = mean(income_growth, na.rm = TRUE),
    N = n(),
    States = n_distinct(state_abbr),
    Years = n_distinct(year)
  ) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Full Sample")

# Panel B: By treatment status
panel_b_treated <- ces %>%
  filter(ever_treated == TRUE) %>%
  summarize(
    `Mean pessimism` = mean(pessimism, na.rm = TRUE),
    `SD pessimism` = sd(pessimism, na.rm = TRUE),
    `Pct pessimistic` = mean(pessimistic, na.rm = TRUE) * 100,
    `Mean unemployment` = mean(unemp_rate, na.rm = TRUE),
    `Mean income growth` = mean(income_growth, na.rm = TRUE),
    N = n(),
    States = n_distinct(state_abbr),
    Years = n_distinct(year)
  ) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Treated States")

panel_b_control <- ces %>%
  filter(ever_treated == FALSE) %>%
  summarize(
    `Mean pessimism` = mean(pessimism, na.rm = TRUE),
    `SD pessimism` = sd(pessimism, na.rm = TRUE),
    `Pct pessimistic` = mean(pessimistic, na.rm = TRUE) * 100,
    `Mean unemployment` = mean(unemp_rate, na.rm = TRUE),
    `Mean income growth` = mean(income_growth, na.rm = TRUE),
    N = n(),
    States = n_distinct(state_abbr),
    Years = n_distinct(year)
  ) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Control States")

sumstats <- panel_a %>%
  left_join(panel_b_treated, by = "Variable") %>%
  left_join(panel_b_control, by = "Variable")

fwrite(sumstats, file.path(data_dir, "summary_statistics.csv"))

# LaTeX output
sumstats_tex <- sumstats %>%
  mutate(across(where(is.numeric), ~round(., 2)))

sink(file.path(table_dir, "table1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("& Full Sample & Treated States & Control States \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(sumstats_tex))) {
  cat(sumstats_tex$Variable[i], "&",
      format(sumstats_tex$`Full Sample`[i], nsmall = 2), "&",
      format(sumstats_tex$`Treated States`[i], nsmall = 2), "&",
      format(sumstats_tex$`Control States`[i], nsmall = 2), "\\\\\n")
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Pessimism is the CES economy retrospection variable (1 = much better, 5 = much worse). Pct pessimistic is the share reporting the economy has ``gotten somewhat worse'' or ``much worse.'' Treated states enacted a discrete gasoline tax increase between 2013 and 2021. Control states never enacted a discrete increase in this period.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ==============================================================================
# TABLE 2: Main DiD Results
# ==============================================================================

cat("Table 2: Main results\n")

results <- fread(file.path(data_dir, "results_summary.csv"))

sink(file.path(table_dir, "table2_main_results.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of State Gas Tax Increases on Macroeconomic Beliefs}\n")
cat("\\label{tab:main}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("& \\multicolumn{3}{c}{TWFE} & \\multicolumn{3}{c}{Callaway-Sant'Anna} \\\\\n")
cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n")
cat("& (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat("& Basic & Controls & Binary & Never-treated & Not-yet & Binary \\\\\n")
cat("\\midrule\n")

for (i in seq_len(nrow(results))) {
  r <- results[i, ]
  stars <- r$stars
  cat("\\multicolumn{7}{l}{\\textit{", r$specification, "}} \\\\\n")
  if (i <= 3) {
    cols <- rep("", 6)
    cols[i] <- paste0(format(round(r$att, 4), nsmall = 4), stars)
    cat("ATT &", paste(cols, collapse = " & "), "\\\\\n")
    cols[i] <- paste0("(", format(round(r$se, 4), nsmall = 4), ")")
    cat("&", paste(cols, collapse = " & "), "\\\\\n")
  } else {
    cols <- rep("", 6)
    cols[i] <- paste0(format(round(r$att, 4), nsmall = 4), stars)
    cat("ATT &", paste(cols, collapse = " & "), "\\\\\n")
    cols[i] <- paste0("(", format(round(r$se, 4), nsmall = 4), ")")
    cat("&", paste(cols, collapse = " & "), "\\\\\n")
  }
}

cat("\\midrule\n")
cat("State FE & Yes & Yes & Yes & --- & --- & --- \\\\\n")
cat("Year FE & Yes & Yes & Yes & --- & --- & --- \\\\\n")
cat("Econ controls & No & Yes & No & No & No & No \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Columns (1)--(3): TWFE with state and year fixed effects, standard errors clustered by state. Columns (4)--(6): Callaway and Sant'Anna (2021) staggered DiD. Column (4) uses never-treated states as controls; (5) uses not-yet-treated. Column (3) and (6): binary outcome (1 if economy ``gotten worse''). Econ controls: state unemployment rate and personal income growth. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ==============================================================================
# TABLE 3: Heterogeneity Results
# ==============================================================================

cat("Table 3: Heterogeneity\n")

# Collect heterogeneity results
het_rows <- list()

# Party
party_file <- file.path(data_dir, "heterogeneity_party.csv")
if (file.exists(party_file)) {
  party <- fread(party_file)
  het_rows[["Party (Democrat, base)"]] <- party %>% filter(term == "post")
  het_rows[["Party x Republican"]] <- party %>% filter(grepl("Republican", term))
  het_rows[["Party x Independent"]] <- party %>% filter(grepl("Independent", term))
}

# Income
income_file <- file.path(data_dir, "heterogeneity_income.csv")
if (file.exists(income_file)) {
  income <- fread(income_file)
  het_rows[["Post (base)"]] <- income %>% filter(term == "post")
  het_rows[["Post x Low income"]] <- income %>% filter(term == "post:low_income")
}

# Age
age_file <- file.path(data_dir, "heterogeneity_age.csv")
if (file.exists(age_file)) {
  age <- fread(age_file)
  het_rows[["Post (base)"]] <- age %>% filter(term == "post")
  het_rows[["Post x 1970s experience"]] <- age %>% filter(term == "post:experienced_70s")
}

het_summary <- bind_rows(het_rows, .id = "label") %>%
  select(label, estimate, std.error, p.value)

fwrite(het_summary, file.path(data_dir, "heterogeneity_summary.csv"))

# ==============================================================================
# TABLE 4: Robustness Checks
# ==============================================================================

cat("Table 4: Robustness\n")

robustness <- fread(file.path(data_dir, "robustness_summary.csv"))

# Add first-stage if available
fs_file <- file.path(data_dir, "first_stage.csv")
if (file.exists(fs_file)) {
  fs <- fread(fs_file)
  robustness <- bind_rows(
    robustness,
    tibble(test = "First stage (gas tax -> price)", coef = fs$coef, se = fs$se, pval = fs$pval)
  )
}

# Add dose-response
dose_file <- file.path(data_dir, "dose_response.csv")
if (file.exists(dose_file)) {
  dose <- fread(dose_file) %>% filter(variable == "dose")
  if (nrow(dose) > 0) {
    robustness <- bind_rows(
      robustness,
      tibble(test = "Dose-response (per cent/gal)", coef = dose$coef, se = dose$se, pval = dose$pval)
    )
  }
}

fwrite(robustness, file.path(data_dir, "robustness_full.csv"))

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Tables saved to:", table_dir, "\n")
