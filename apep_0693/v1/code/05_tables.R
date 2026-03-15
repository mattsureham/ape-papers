## 05_tables.R — Generate all tables including SDE appendix
## apep_0693: The Price of Privacy

source("00_packages.R")

df <- readRDS("../data/bfs_quarterly_clean.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

# ------------------------------------------------------------------
# Table 1: Summary Statistics
# ------------------------------------------------------------------
cat("\n=== Generating Table 1: Summary Statistics ===\n")

# Pre-treatment summary by treatment status
pre_treat_min <- min(df$first_treat_q[df$first_treat_q > 0])

summ <- df %>%
  filter(yq < pre_treat_min) %>%
  mutate(group = ifelse(first_treat_q > 0, "Privacy-Law States", "Never-Treated States")) %>%
  group_by(group) %>%
  summarise(
    `N (state-quarters)` = n(),
    `States` = n_distinct(state),
    `Mean BA` = sprintf("%.0f", mean(ba, na.rm = TRUE)),
    `SD BA` = sprintf("%.0f", sd(ba, na.rm = TRUE)),
    `Mean HBA` = sprintf("%.0f", mean(hba, na.rm = TRUE)),
    `Mean CBA` = sprintf("%.0f", mean(cba, na.rm = TRUE)),
    `Mean WBA` = sprintf("%.0f", mean(wba, na.rm = TRUE)),
    .groups = "drop"
  )

tab1_latex <- kbl(summ, format = "latex", booktabs = TRUE,
                  caption = "Summary Statistics: Pre-Treatment Business Applications by State Group",
                  label = "tab:summary") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste0(
    "Source: Census Bureau Business Formation Statistics (BFS), 2006--2019. ",
    "BA = total business applications; HBA = high-propensity; CBA = corporate; WBA = with planned wages. ",
    "Privacy-law states are the 20 states that adopted comprehensive data privacy laws by 2026. ",
    "All figures are quarterly aggregates of weekly non-seasonally-adjusted counts."
  ), threeparttable = TRUE)

writeLines(tab1_latex, "../tables/tab1_summary.tex")

# ------------------------------------------------------------------
# Table 2: Main CS-DiD Results
# ------------------------------------------------------------------
cat("=== Generating Table 2: Main Results ===\n")

# Extract results
get_cs_row <- function(agg_obj, label) {
  tibble(
    Outcome = label,
    ATT = sprintf("%.4f", agg_obj$overall.att),
    SE = sprintf("(%.4f)", agg_obj$overall.se),
    `p-value` = sprintf("%.3f", 2 * pnorm(-abs(agg_obj$overall.att / agg_obj$overall.se))),
    `95\\% CI` = sprintf("[%.4f, %.4f]",
                          agg_obj$overall.att - 1.96 * agg_obj$overall.se,
                          agg_obj$overall.att + 1.96 * agg_obj$overall.se)
  )
}

main_tab <- bind_rows(
  get_cs_row(results$agg_ba, "log(Total Applications)"),
  get_cs_row(results$agg_hba, "log(High-Propensity)"),
  get_cs_row(results$agg_cba, "log(Corporate)"),
  get_cs_row(results$agg_wba, "log(With Planned Wages)")
)

n_treated <- n_distinct(df$state[df$first_treat_q > 0])
n_control <- n_distinct(df$state[df$first_treat_q == 0])

tab2_latex <- kbl(main_tab, format = "latex", booktabs = TRUE, escape = FALSE,
                  caption = "Effect of State Privacy Laws on Business Formation: Callaway-Sant'Anna Estimates",
                  label = "tab:main") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste0(
    "Callaway-Sant'Anna difference-in-differences estimates. ",
    "Treatment = effective date of state comprehensive data privacy law. ",
    "Control group = never-treated states. ",
    sprintf("N = %s state-quarters; %d treated states; %d control states. ",
            format(nrow(df), big.mark = ","), n_treated, n_control),
    "Standard errors clustered at the state level in parentheses. ",
    "Dependent variables are log(quarterly applications + 1)."
  ), threeparttable = TRUE)

writeLines(tab2_latex, "../tables/tab2_main.tex")

# ------------------------------------------------------------------
# Table 3: Robustness Checks
# ------------------------------------------------------------------
cat("=== Generating Table 3: Robustness ===\n")

# LOO range
loo_range <- robust$loo
if (nrow(loo_range) > 0) {
  loo_min <- min(loo_range$att)
  loo_max <- max(loo_range$att)
  loo_str <- sprintf("[%.4f, %.4f]", loo_min, loo_max)
} else {
  loo_str <- "N/A"
}

robust_tab <- tribble(
  ~Specification, ~ATT, ~SE, ~Notes,
  "Baseline (CS-DiD)", sprintf("%.4f", results$agg_ba$overall.att),
    sprintf("(%.4f)", results$agg_ba$overall.se), "Never-treated controls",
  "Exclude California", sprintf("%.4f", robust$no_ca$overall.att),
    sprintf("(%.4f)", robust$no_ca$overall.se), "Removes COVID-CCPA overlap",
  "Donut-hole (drop 2020Q1-Q2)", sprintf("%.4f", robust$donut$overall.att),
    sprintf("(%.4f)", robust$donut$overall.se), "Excludes COVID shock quarters",
  "Not-yet-treated controls", sprintf("%.4f", robust$nyt$overall.att),
    sprintf("(%.4f)", robust$nyt$overall.se), "Alternative control group",
  "Leave-one-out range", loo_str, "", paste0(nrow(loo_range), " specifications")
)

# Add wild bootstrap if available
if (!is.na(robust$boot_pval)) {
  robust_tab <- bind_rows(robust_tab, tribble(
    ~Specification, ~ATT, ~SE, ~Notes,
    "Wild cluster bootstrap p", "", sprintf("p = %.3f", robust$boot_pval), "Webb weights, 999 reps"
  ))
}

tab3_latex <- kbl(robust_tab, format = "latex", booktabs = TRUE,
                  caption = "Robustness: Effect of Privacy Laws on log(Total Business Applications)",
                  label = "tab:robust") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste0(
    "All specifications use log(total quarterly business applications + 1) as the dependent variable. ",
    "Standard errors clustered at the state level in parentheses. ",
    "Leave-one-out reports the range of ATT estimates when dropping each treated state in turn."
  ), threeparttable = TRUE)

writeLines(tab3_latex, "../tables/tab3_robust.tex")

# ------------------------------------------------------------------
# Table 4: Event Study Coefficients
# ------------------------------------------------------------------
cat("=== Generating Table 4: Event Study ===\n")

es <- results$es_ba
es_tab <- tibble(
  `Event Quarter` = es$egt,
  ATT = sprintf("%.4f", es$att.egt),
  SE = sprintf("(%.4f)", es$se.egt),
  `p-value` = sprintf("%.3f", 2 * pnorm(-abs(es$att.egt / es$se.egt)))
)

tab4_latex <- kbl(es_tab, format = "latex", booktabs = TRUE,
                  caption = "Event Study: Dynamic Effects of Privacy Laws on log(Total Business Applications)",
                  label = "tab:event") %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = paste0(
    "Dynamic ATT estimates from Callaway-Sant'Anna aggregated by event time. ",
    "Event quarter 0 = quarter of law's effective date. ",
    "Standard errors clustered at the state level in parentheses."
  ), threeparttable = TRUE)

writeLines(tab4_latex, "../tables/tab4_event.tex")

# ------------------------------------------------------------------
# Table 5: Group-Level ATT (by treatment cohort)
# ------------------------------------------------------------------
cat("=== Generating Table 5: Group ATT ===\n")

grp <- results$group_ba

# Map group codes back to approximate dates
grp_tab <- tibble(
  `Cohort (year-quarter)` = grp$egt,
  ATT = sprintf("%.4f", grp$att.egt),
  SE = sprintf("(%.4f)", grp$se.egt)
)

tab5_latex <- kbl(grp_tab, format = "latex", booktabs = TRUE,
                  caption = "Cohort-Specific ATT: Privacy Law Effects by Adoption Group",
                  label = "tab:group") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste0(
    "Group-level ATT from Callaway-Sant'Anna. Each row reports the average treatment effect ",
    "for states adopting privacy laws in the indicated quarter. ",
    "Standard errors clustered at the state level in parentheses."
  ), threeparttable = TRUE)

writeLines(tab5_latex, "../tables/tab5_group.tex")

# ------------------------------------------------------------------
# SDE Appendix Table (MANDATORY)
# ------------------------------------------------------------------
cat("=== Generating SDE Table ===\n")

# Compute SDE for each outcome
compute_sde <- function(agg_obj, outcome_var, label) {
  att <- agg_obj$overall.att
  se_att <- agg_obj$overall.se
  sd_y <- sd(df[[outcome_var]], na.rm = TRUE)
  sde <- att / sd_y
  se_sde <- se_att / sd_y

  # Classification
  classify <- function(x) {
    if (x < -0.15) return("Large negative")
    if (x < -0.05) return("Moderate negative")
    if (x < -0.005) return("Small negative")
    if (x <= 0.005) return("Null")
    if (x <= 0.05) return("Small positive")
    if (x <= 0.15) return("Moderate positive")
    return("Large positive")
  }

  tibble(
    Outcome = label,
    `$\\hat{\\beta}$` = sprintf("%.4f", att),
    SE = sprintf("%.4f", se_att),
    `SD(Y)` = sprintf("%.3f", sd_y),
    SDE = sprintf("%.4f", sde),
    `SE(SDE)` = sprintf("%.4f", se_sde),
    Classification = classify(sde)
  )
}

sde_tab <- bind_rows(
  compute_sde(results$agg_ba, "log_ba", "log(Total Applications)"),
  compute_sde(results$agg_hba, "log_hba", "log(High-Propensity)"),
  compute_sde(results$agg_cba, "log_cba", "log(Corporate)"),
  compute_sde(results$agg_wba, "log_wba", "log(With Planned Wages)")
)

sde_latex <- kbl(sde_tab, format = "latex", booktabs = TRUE, escape = FALSE,
                 caption = "Standardized Effect Sizes: Privacy Laws and Business Formation",
                 label = "tab:sde") %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = paste0(
    "Research question: Do state comprehensive data privacy laws reduce new business formation? ",
    "Data: Census Bureau Business Formation Statistics (BFS), quarterly state-level panel, 2006--2026. ",
    "Method: Callaway-Sant'Anna difference-in-differences with never-treated control group. ",
    sprintf("Sample: %s state-quarters, %d treated states, %d never-treated states. ",
            format(nrow(df), big.mark = ","), n_treated, n_control),
    "Treatment: binary (privacy law effective). ",
    "SDE = $\\hat{\\beta}$ / SD(Y). Classification refers to magnitude of effect size, not statistical significance. ",
    "7-bucket classification: Large negative ($<-0.15$), Moderate negative ($-0.15$ to $-0.05$), ",
    "Small negative ($-0.05$ to $-0.005$), Null ($-0.005$ to $0.005$), ",
    "Small positive ($0.005$ to $0.05$), Moderate positive ($0.05$ to $0.15$), ",
    "Large positive ($>0.15$)."
  ), threeparttable = TRUE)

writeLines(sde_latex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
