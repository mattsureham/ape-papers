## ===========================================================
## 06_tables.R — All tables
## APEP-0500 v2: Anti-Open Grazing Laws and Farmer-Herder Violence
## ===========================================================

source("00_packages.R")

state_panel <- read_csv(file.path(data_dir, "state_panel.csv"),
                        show_col_types = FALSE)
lga_panel <- read_csv(file.path(data_dir, "lga_panel.csv"),
                      show_col_types = FALSE)
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

# -----------------------------------------------------------
# Table 1: Descriptive Statistics
# -----------------------------------------------------------
cat("Table 1: Descriptive statistics...\n")

lga_analysis <- lga_panel %>%
  filter(year >= 2010 & year <= 2024) %>%
  mutate(
    post = as.integer(first_treat > 0 & year >= first_treat),
    treat_state = as.integer(first_treat > 0),
    group = case_when(
      treat_state == 1 & pastoral == 1 ~ "Treated × Pastoral",
      treat_state == 1 & pastoral == 0 ~ "Treated × Non-Pastoral",
      treat_state == 0 & pastoral == 1 ~ "Control × Pastoral",
      TRUE ~ "Control × Non-Pastoral"
    )
  )

desc_stats <- lga_analysis %>%
  filter(year < first_treat | first_treat == 0, year <= 2015) %>%
  group_by(group) %>%
  summarise(
    `N (LGA-years)` = n(),
    `Mean non-state events` = sprintf("%.3f", mean(events_nonstate)),
    `SD non-state events` = sprintf("%.3f", sd(events_nonstate)),
    `Mean non-state deaths` = sprintf("%.3f", mean(deaths_nonstate)),
    `Mean state-based events` = sprintf("%.3f", mean(events_statebased)),
    `Mean total events` = sprintf("%.3f", mean(events_total)),
    .groups = "drop"
  )

write_csv(desc_stats, file.path(tab_dir, "table1_descriptive.csv"))

desc_tex <- kbl(desc_stats, format = "latex", booktabs = TRUE,
                caption = "Pre-Treatment Descriptive Statistics by Treatment Group (2010--2015)",
                label = "tab:descriptive") %>%
  kable_styling(latex_options = c("hold_position", "scale_down"))
writeLines(desc_tex, file.path(tab_dir, "table1_descriptive.tex"))

# -----------------------------------------------------------
# Table 2: Main Results — DDD Estimates
# -----------------------------------------------------------
cat("Table 2: Main results...\n")

models <- list(
  "(1) DD" = results$dd_simple,
  "(2) DDD" = results$ddd_main,
  "(3) DDD State×Year" = results$ddd_saturated,
  "(4) Deaths" = results$ddd_deaths,
  "(5) Placebo" = results$ddd_placebo
)

cm <- c(
  "post" = "Post × Treated",
  "post:pastoral" = "Post × Treated × Pastoral"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = 0),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = 3)
)

modelsummary(
  models,
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  output = file.path(tab_dir, "table2_main_results.tex"),
  title = "Effect of Anti-Open Grazing Laws on Violence: Triple-Difference Estimates",
  notes = list(
    "Standard errors clustered at the state level in parentheses.",
    "All specifications include LGA and year fixed effects.",
    "Column 3 adds state $\\times$ year fixed effects.",
    "Column 4 uses deaths as outcome. Column 5 is a placebo using state-based violence."
  )
)

# -----------------------------------------------------------
# Table 3: Callaway-Sant'Anna Results
# -----------------------------------------------------------
cat("Table 3: CS ATT results...\n")

cs_summary <- tribble(
  ~Specification, ~`ATT`, ~`SE`, ~`95\\% CI`,
  "Non-state violence (main)",
    sprintf("%.3f", results$att_nonstate$overall.att),
    sprintf("(%.3f)", results$att_nonstate$overall.se),
    sprintf("[%.3f, %.3f]",
            results$att_nonstate$overall.att - 1.96 * results$att_nonstate$overall.se,
            results$att_nonstate$overall.att + 1.96 * results$att_nonstate$overall.se),
  "State-based violence (placebo)",
    sprintf("%.3f", results$att_statebased$overall.att),
    sprintf("(%.3f)", results$att_statebased$overall.se),
    sprintf("[%.3f, %.3f]",
            results$att_statebased$overall.att - 1.96 * results$att_statebased$overall.se,
            results$att_statebased$overall.att + 1.96 * results$att_statebased$overall.se)
)

cs_tex <- kbl(cs_summary, format = "latex", booktabs = TRUE,
              escape = FALSE,
              caption = "Callaway-Sant'Anna ATT Estimates: State-Year Level",
              label = "tab:cs_att") %>%
  kable_styling(latex_options = "hold_position")
writeLines(cs_tex, file.path(tab_dir, "table3_cs_att.tex"))

# -----------------------------------------------------------
# Table 4: Robustness Summary (expanded with new tests)
# -----------------------------------------------------------
cat("Table 4: Robustness summary...\n")

ri_results <- readRDS(file.path(data_dir, "ri_results.rds"))
loo_results <- readRDS(file.path(data_dir, "loo_results.rds"))

sgf_coef <- coef(robust_results$ddd_sgf)["post:pastoral"]
sgf_se <- se(robust_results$ddd_sgf)["post:pastoral"]
sgf_n <- nobs(robust_results$ddd_sgf)

log_coef <- coef(robust_results$ddd_log)["post:pastoral"]
log_se <- se(robust_results$ddd_log)["post:pastoral"]
log_n <- nobs(robust_results$ddd_log)

os_coef <- coef(robust_results$ddd_onesided)["post:pastoral"]
os_se <- se(robust_results$ddd_onesided)["post:pastoral"]
os_n <- nobs(robust_results$ddd_onesided)

ppml_coef <- if (!is.null(robust_results$ddd_ppml)) coef(robust_results$ddd_ppml)["post:pastoral"] else NA
ppml_se <- if (!is.null(robust_results$ddd_ppml)) se(robust_results$ddd_ppml)["post:pastoral"] else NA

spill_coef <- if (!is.null(robust_results$ddd_spillover)) coef(robust_results$ddd_spillover)["post_spillover:border_lga"] else NA
spill_se <- if (!is.null(robust_results$ddd_spillover)) se(robust_results$ddd_spillover)["post_spillover:border_lga"] else NA
spill_n <- if (!is.null(robust_results$ddd_spillover)) nobs(robust_results$ddd_spillover) else NA

# Geography-only classification
geo_coef <- if (!is.null(robust_results$ddd_geo)) coef(robust_results$ddd_geo)["post:pastoral_geo"] else NA
geo_se <- if (!is.null(robust_results$ddd_geo)) se(robust_results$ddd_geo)["post:pastoral_geo"] else NA
geo_n <- if (!is.null(robust_results$ddd_geo)) nobs(robust_results$ddd_geo) else NA

# Conflict-only classification
con_coef <- if (!is.null(robust_results$ddd_conflict)) coef(robust_results$ddd_conflict)["post:pastoral_conflict"] else NA
con_se <- if (!is.null(robust_results$ddd_conflict)) se(robust_results$ddd_conflict)["post:pastoral_conflict"] else NA
con_n <- if (!is.null(robust_results$ddd_conflict)) nobs(robust_results$ddd_conflict) else NA

# Within-state displacement
np_coef <- if (!is.null(robust_results$dd_nonpastoral)) coef(robust_results$dd_nonpastoral)["post"] else NA
np_se <- if (!is.null(robust_results$dd_nonpastoral)) se(robust_results$dd_nonpastoral)["post"] else NA
np_n <- if (!is.null(robust_results$dd_nonpastoral)) nobs(robust_results$dd_nonpastoral) else NA

# WCB
wcb_pval <- if (!is.null(robust_results$boot_result)) robust_results$boot_result$p_val else NA
wcb_spec <- if (!is.null(robust_results$boot_spec)) robust_results$boot_spec else "---"

robustness_summary <- tribble(
  ~Test, ~Coefficient, ~SE, ~N, ~Notes,
  "Wild cluster bootstrap",
    sprintf("%.4f", ri_results$obs_coef),
    if (!is.na(wcb_pval)) sprintf("p = %.4f", wcb_pval) else "Failed",
    "11,625",
    wcb_spec,
  "Randomization inference",
    sprintf("%.4f", ri_results$obs_coef),
    sprintf("p = %.4f", ri_results$ri_pval),
    "11,625",
    sprintf("Cohort-preserving, %d perms", length(ri_results$perm_coefs)),
  "Leave-one-out range",
    sprintf("[%.4f, %.4f]", min(loo_results), max(loo_results)),
    "---",
    "---",
    sprintf("Full sample: %.4f", ri_results$obs_coef),
  "SGF sub-sample",
    sprintf("%.4f", sgf_coef),
    sprintf("(%.4f)", sgf_se),
    format(sgf_n, big.mark = ","),
    "7 SGF states + 23 controls",
  "Geography-only pastoral",
    if (!is.na(geo_coef)) sprintf("%.4f", geo_coef) else "---",
    if (!is.na(geo_se)) sprintf("(%.4f)", geo_se) else "---",
    if (!is.na(geo_n)) format(geo_n, big.mark = ",") else "---",
    "Middle Belt + GLW cattle density only",
  "Conflict-only pastoral",
    if (!is.na(con_coef)) sprintf("%.4f", con_coef) else "---",
    if (!is.na(con_se)) sprintf("(%.4f)", con_se) else "---",
    if (!is.na(con_n)) format(con_n, big.mark = ",") else "---",
    "Pre-2010--2015 violence only",
  "Within-state displacement",
    if (!is.na(np_coef)) sprintf("%.4f", np_coef) else "---",
    if (!is.na(np_se)) sprintf("(%.4f)", np_se) else "---",
    if (!is.na(np_n)) format(np_n, big.mark = ",") else "---",
    "Non-pastoral LGAs, treated states",
  "Log(events+1)",
    sprintf("%.4f", log_coef),
    sprintf("(%.4f)", log_se),
    format(log_n, big.mark = ","),
    "Semi-elasticity",
  "Poisson PML",
    if (!is.na(ppml_coef)) sprintf("%.4f", ppml_coef) else "---",
    if (!is.na(ppml_se)) sprintf("(%.4f)", ppml_se) else "---",
    "11,625",
    if (!is.na(ppml_coef)) sprintf("IRR = %.3f", exp(ppml_coef)) else "Failed",
  "Cross-state spillover",
    if (!is.na(spill_coef)) sprintf("%.4f", spill_coef) else "---",
    if (!is.na(spill_se)) sprintf("(%.4f)", spill_se) else "---",
    if (!is.na(spill_n)) format(spill_n, big.mark = ",") else "---",
    "Border LGAs, never-treated states",
  "Placebo: one-sided violence",
    sprintf("%.4f", os_coef),
    sprintf("(%.4f)", os_se),
    format(os_n, big.mark = ","),
    "Should be null"
)

rob_tex <- kbl(robustness_summary, format = "latex", booktabs = TRUE,
               caption = "Robustness and Sensitivity Checks",
               label = "tab:robustness") %>%
  kable_styling(latex_options = c("hold_position", "scale_down"))
writeLines(rob_tex, file.path(tab_dir, "table4_robustness.tex"))

# -----------------------------------------------------------
# Table 5: Treatment Assignment
# -----------------------------------------------------------
cat("Table 5: Treatment assignment...\n")

treatment <- read_csv(file.path(data_dir, "treatment_assignment.csv"),
                      show_col_types = FALSE)

treat_table <- treatment %>%
  filter(first_treat > 0) %>%
  arrange(law_year, law_month) %>%
  select(State = state,
         Year = law_year,
         Month = law_month,
         Source = source) %>%
  mutate(Month = month.abb[Month])

treat_tex <- kbl(treat_table, format = "latex", booktabs = TRUE,
                 caption = "Anti-Open Grazing Law Adoption by State",
                 label = "tab:treatment") %>%
  kable_styling(latex_options = c("hold_position", "scale_down"))
writeLines(treat_tex, file.path(tab_dir, "table5_treatment.tex"))

# -----------------------------------------------------------
# Table 6: Effective Sample (Fix 5: NEW)
# -----------------------------------------------------------
cat("Table 6: Effective sample...\n")

effective_sample <- readRDS(file.path(data_dir, "effective_sample.rds"))

eff_table <- effective_sample %>%
  select(
    State = state,
    `Total LGAs` = n_lgas,
    Pastoral = n_pastoral,
    `Non-Pastoral` = n_nonpastoral,
    `\\% Pastoral` = pct_pastoral,
    Cohort = cohort,
    Contributes = contributes
  ) %>%
  mutate(Contributes = ifelse(Contributes, "Yes", "No"))

eff_tex <- kbl(eff_table, format = "latex", booktabs = TRUE,
               escape = FALSE,
               caption = "Effective Sample: State Contributions to DDD Identification",
               label = "tab:effective_sample") %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = "A state contributes to the DDD coefficient if it contains both pastoral and non-pastoral LGAs, providing within-state variation. States that are 100\\\\% pastoral or 100\\\\% non-pastoral are absorbed by state × year fixed effects.",
           escape = FALSE, threeparttable = TRUE)
writeLines(eff_tex, file.path(tab_dir, "table6_effective_sample.tex"))

cat(sprintf("Contributing states: %d of %d total\n",
            sum(effective_sample$contributes),
            nrow(effective_sample)))

cat("\nAll tables saved.\n")
