## ============================================================
## 06_tables.R — Generate all LaTeX tables
## apep_0580: Civil Asset Forfeiture Reform and Police Reallocation
## ============================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("=== Table 1: Summary Statistics ===\n")

summ_vars <- panel %>%
  filter(!is.na(drug_death_rate)) %>%
  group_by(group = ifelse(ever_reformed, "Reformed", "Never-Reformed")) %>%
  summarize(
    `N (state-years)` = n(),
    `N (states)` = n_distinct(state_abbr),
    `Drug Death Rate` = paste0(round(mean(drug_death_rate, na.rm=TRUE), 1),
                                " (", round(sd(drug_death_rate, na.rm=TRUE), 1), ")"),
    `Population (millions)` = paste0(round(mean(population/1e6, na.rm=TRUE), 1),
                                      " (", round(sd(population/1e6, na.rm=TRUE), 1), ")"),
    `Eq. Sharing per Capita` = paste0(round(mean(eq_sharing_per_capita, na.rm=TRUE), 2),
                                       " (", round(sd(eq_sharing_per_capita, na.rm=TRUE), 2), ")"),
    .groups = "drop"
  )

# Add homicide if available
if ("homicide_rate" %in% names(panel)) {
  hom_summ <- panel %>%
    filter(!is.na(homicide_rate)) %>%
    group_by(group = ifelse(ever_reformed, "Reformed", "Never-Reformed")) %>%
    summarize(
      `Homicide Rate` = paste0(round(mean(homicide_rate, na.rm=TRUE), 1),
                                " (", round(sd(homicide_rate, na.rm=TRUE), 1), ")"),
      .groups = "drop"
    )
  summ_vars <- summ_vars %>% left_join(hom_summ, by = "group")
}

print(summ_vars)

# Generate LaTeX
summ_tex <- kable(summ_vars, format = "latex", booktabs = TRUE,
                   caption = "Summary Statistics: Reformed vs. Never-Reformed States, 2004--2020",
                   label = "tab:summary") %>%
  kable_styling(latex_options = c("hold_position"))

writeLines(summ_tex, file.path(tab_dir, "tab1_summary.tex"))
fwrite(summ_vars, file.path(data_dir, "table1_summary.csv"))
cat("  Saved tab1_summary.tex\n")

# ============================================================
# Table 2: Reform Coding
# ============================================================

cat("=== Table 2: Reform Coding ===\n")

reform_table <- panel %>%
  filter(ever_reformed) %>%
  distinct(state_abbr, reform_year, reform_type) %>%
  mutate(
    reform_label = case_when(
      reform_type == 3 ~ "Abolished",
      reform_type == 2 ~ "Conviction Req.",
      reform_type == 1 ~ "Transparency"
    )
  ) %>%
  arrange(reform_year, desc(reform_type), state_abbr) %>%
  select(State = state_abbr, Year = reform_year, `Reform Type` = reform_label)

reform_tex <- kable(reform_table, format = "latex", booktabs = TRUE,
                     caption = "Civil Asset Forfeiture Reform by State",
                     label = "tab:reforms",
                     longtable = TRUE) %>%
  kable_styling(latex_options = c("hold_position", "repeat_header"))

writeLines(reform_tex, file.path(tab_dir, "tab2_reforms.tex"))
fwrite(reform_table, file.path(data_dir, "table2_reforms.csv"))
cat("  Saved tab2_reforms.tex\n")

# ============================================================
# Table 3: Main Results
# ============================================================

cat("=== Table 3: Main Results ===\n")

# Run regressions for table
twfe1 <- feols(drug_death_rate ~ treated | state_abbr + year,
               data = panel, cluster = ~state_abbr)

twfe2 <- feols(drug_death_rate ~ treated + I(treated * eq_sharing_per_capita) |
                 state_abbr + year,
               data = panel, cluster = ~state_abbr)

twfe_log <- feols(log_drug_death_rate ~ treated | state_abbr + year,
                   data = panel %>% filter(!is.na(log_drug_death_rate)),
                   cluster = ~state_abbr)

# Model summary table
models <- list(
  "(1) Levels" = twfe1,
  "(2) Interaction" = twfe2,
  "(3) Log" = twfe_log
)

options("modelsummary_format_numeric_latex" = "plain")
main_tex <- modelsummary(
  models,
  output = "latex_tabular",
  stars = c('*' = 0.10, '**' = 0.05, '***' = 0.01),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  coef_rename = c("treatedTRUE" = "Reform",
                    "I(treated * eq_sharing_per_capita)" = "Reform $\\times$ Forfeiture Intensity")
)

writeLines(as.character(main_tex), file.path(tab_dir, "tab3_main_results.tex"))
cat("  Saved tab3_main_results.tex\n")

# Save coefficient values for paper text
main_coefs <- data.frame(
  spec = c("TWFE Levels", "TWFE + Interaction", "TWFE Log"),
  coef = c(coef(twfe1)["treatedTRUE"],
           coef(twfe2)["treatedTRUE"],
           coef(twfe_log)["treatedTRUE"]),
  se = c(sqrt(vcov(twfe1)["treatedTRUE","treatedTRUE"]),
         sqrt(vcov(twfe2)["treatedTRUE","treatedTRUE"]),
         sqrt(vcov(twfe_log)["treatedTRUE","treatedTRUE"])),
  n = c(nobs(twfe1), nobs(twfe2), nobs(twfe_log))
)
fwrite(main_coefs, file.path(data_dir, "main_coefficients.csv"))

# ============================================================
# Table 4: Robustness Summary
# ============================================================

cat("=== Table 4: Robustness ===\n")

if (file.exists(file.path(data_dir, "robustness_summary.csv"))) {
  robust <- fread(file.path(data_dir, "robustness_summary.csv"))
  # Replace NA with "---" for clean display
  robust[is.na(robust)] <- "---"

  robust_tex <- kable(robust, format = "latex", booktabs = TRUE,
                       caption = "Robustness Checks",
                       label = "tab:robustness") %>%
    kable_styling(latex_options = c("hold_position"))

  writeLines(robust_tex, file.path(tab_dir, "tab4_robustness.tex"))
  cat("  Saved tab4_robustness.tex\n")
}

# ============================================================
# Table 5: Event Study Coefficients
# ============================================================

cat("=== Table 5: Event Study ===\n")

if (file.exists(file.path(data_dir, "event_study_drug.csv"))) {
  es <- fread(file.path(data_dir, "event_study_drug.csv"))

  es_table <- es %>%
    filter(event_time != -1) %>%  # Drop reference period (normalized to 0)
    mutate(
      Estimate = round(att, 3),
      SE = paste0("(", round(se, 3), ")"),
      `95% CI` = paste0("[", round(ci_lower, 3), ", ", round(ci_upper, 3), "]"),
      Sig = stars
    ) %>%
    select(`Event Time` = event_time, Estimate, SE, `95% CI`, Sig)

  es_tex <- kable(es_table, format = "latex", booktabs = TRUE,
                   caption = "Event Study Estimates: Drug Overdose Deaths",
                   label = "tab:event_study") %>%
    kable_styling(latex_options = c("hold_position"))

  writeLines(es_tex, file.path(tab_dir, "tab5_event_study.tex"))
  cat("  Saved tab5_event_study.tex\n")
}

cat("\n=== ALL TABLES GENERATED ===\n")
cat("  Files in", tab_dir, ":\n")
for (f in list.files(tab_dir)) cat("  ", f, "\n")
