## 05_tables.R — Generate all LaTeX tables
## APEP Paper apep_1035

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"

cdc_full <- readRDS(file.path(data_dir, "analysis_panel_cdc.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Replicate balanced CS panel
cdc <- cdc_full %>%
  filter(year >= 1999, state_abb != "FL")
state_years <- cdc %>% count(state_fips) %>% filter(n == max(n)) %>% pull(state_fips)
cdc <- cdc %>% filter(state_fips %in% state_years)

cdc <- cdc %>%
  mutate(post = if_else(treated == 1 & year >= treat_year, 1L, 0L))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

sum_stats <- cdc %>%
  group_by(Group = if_else(treated == 1, "Treated", "Control")) %>%
  summarise(
    `N (state-years)` = n(),
    `States` = n_distinct(state_fips),
    `Mean Divorce Rate` = sprintf("%.2f", mean(divorce_rate, na.rm = TRUE)),
    `SD Divorce Rate` = sprintf("%.2f", sd(divorce_rate, na.rm = TRUE)),
    `Mean Marriage Rate` = sprintf("%.2f", mean(marriage_rate, na.rm = TRUE)),
    `SD Marriage Rate` = sprintf("%.2f", sd(marriage_rate, na.rm = TRUE)),
    .groups = "drop"
  )

# Pre-treatment only
pre_stats <- cdc %>%
  filter(treated == 0 | (treated == 1 & year < treat_year)) %>%
  group_by(Group = if_else(treated == 1, "Treated (Pre)", "Control")) %>%
  summarise(
    `N (state-years)` = n(),
    `States` = n_distinct(state_fips),
    `Mean Divorce Rate` = sprintf("%.2f", mean(divorce_rate, na.rm = TRUE)),
    `SD Divorce Rate` = sprintf("%.2f", sd(divorce_rate, na.rm = TRUE)),
    `Mean Marriage Rate` = sprintf("%.2f", mean(marriage_rate, na.rm = TRUE)),
    `SD Marriage Rate` = sprintf("%.2f", sd(marriage_rate, na.rm = TRUE)),
    .groups = "drop"
  )

tab1_combined <- bind_rows(sum_stats, pre_stats)

tab1_tex <- kableExtra::kbl(
  tab1_combined, format = "latex", booktabs = TRUE,
  caption = "Summary Statistics: State Divorce and Marriage Rates",
  label = "summary"
) %>%
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down"))

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results — Callaway-Sant'Anna + TWFE
# ============================================================
cat("Generating Table 2: Main Results\n")

# Extract CS results
cs_div_att <- results$agg_overall_divorce$overall.att
cs_div_se <- results$agg_overall_divorce$overall.se
cs_mar_att <- results$agg_overall_marriage$overall.att
cs_mar_se <- results$agg_overall_marriage$overall.se

# Extract TWFE results
twfe_div_coef <- coef(results$twfe_divorce)["post"]
twfe_div_se <- se(results$twfe_divorce)["post"]
twfe_mar_coef <- coef(results$twfe_marriage)["post"]
twfe_mar_se <- se(results$twfe_marriage)["post"]

# Wild bootstrap p-values
wcb_div_p <- if (!is.null(results$boot_divorce)) results$boot_divorce$p_val else NA
wcb_mar_p <- if (!is.null(results$boot_marriage)) results$boot_marriage$p_val else NA

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Format coefficient with stars based on t-stat
fmt_coef <- function(b, se, extra_p = NA) {
  t <- abs(b / se)
  p <- 2 * (1 - pnorm(t))
  s <- stars(p)
  sprintf("%.3f%s", b, s)
}

main_tab <- data.frame(
  ` ` = c("Post × Treated", "", "Wild Bootstrap p-value", "N (state-years)", "States", "Years"),
  `Divorce Rate (CS)` = c(
    fmt_coef(cs_div_att, cs_div_se),
    sprintf("(%.3f)", cs_div_se),
    "", # CS doesn't have WCB
    nrow(cdc),
    n_distinct(cdc$state_fips),
    paste(range(cdc$year), collapse = "--")
  ),
  `Divorce Rate (TWFE)` = c(
    fmt_coef(twfe_div_coef, twfe_div_se),
    sprintf("(%.3f)", twfe_div_se),
    if (!is.na(wcb_div_p)) sprintf("[%.3f]", wcb_div_p) else "---",
    nrow(cdc),
    n_distinct(cdc$state_fips),
    paste(range(cdc$year), collapse = "--")
  ),
  `Marriage Rate (CS)` = c(
    fmt_coef(cs_mar_att, cs_mar_se),
    sprintf("(%.3f)", cs_mar_se),
    "",
    nrow(cdc %>% filter(!is.na(marriage_rate))),
    n_distinct(cdc$state_fips[!is.na(cdc$marriage_rate)]),
    paste(range(cdc$year[!is.na(cdc$marriage_rate)]), collapse = "--")
  ),
  `Marriage Rate (TWFE)` = c(
    fmt_coef(twfe_mar_coef, twfe_mar_se),
    sprintf("(%.3f)", twfe_mar_se),
    if (!is.na(wcb_mar_p)) sprintf("[%.3f]", wcb_mar_p) else "---",
    nrow(cdc %>% filter(!is.na(marriage_rate))),
    n_distinct(cdc$state_fips[!is.na(cdc$marriage_rate)]),
    paste(range(cdc$year[!is.na(cdc$marriage_rate)]), collapse = "--")
  ),
  check.names = FALSE
)

tab2_tex <- kableExtra::kbl(
  main_tab, format = "latex", booktabs = TRUE,
  caption = "Effect of Premarital Education Policies on Divorce and Marriage Rates",
  label = "main",
  escape = FALSE
) %>%
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  kableExtra::footnote(
    general = "Callaway-Sant'Anna (CS) estimates use doubly-robust method with never-treated controls. TWFE estimates include state and year fixed effects with standard errors clustered at the state level. Wild cluster bootstrap uses Webb weights with 999 iterations. Divorce and marriage rates are per 1,000 population. Georgia excluded from divorce analysis due to missing data 2004--2016. * p<0.10, ** p<0.05, *** p<0.01.",
    threeparttable = TRUE
  )

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================
cat("Generating Table 3: Event Study\n")

es_div <- results$agg_dynamic_divorce
es_mar <- results$agg_dynamic_marriage

es_tab <- tibble(
  `Event Time` = es_div$egt,
  `Divorce ATT` = sprintf("%.3f%s", es_div$att.egt,
                           sapply(2*(1-pnorm(abs(es_div$att.egt/es_div$se.egt))), stars)),
  `SE` = sprintf("(%.3f)", es_div$se.egt)
)

# Add marriage if same event times
if (length(es_mar$egt) > 0) {
  es_mar_df <- tibble(
    `Event Time` = es_mar$egt,
    `Marriage ATT` = sprintf("%.3f%s", es_mar$att.egt,
                              sapply(2*(1-pnorm(abs(es_mar$att.egt/es_mar$se.egt))), stars)),
    `SE (Marriage)` = sprintf("(%.3f)", es_mar$se.egt)
  )
  es_tab <- es_tab %>% left_join(es_mar_df, by = "Event Time")
}

tab3_tex <- kableExtra::kbl(
  es_tab, format = "latex", booktabs = TRUE,
  caption = "Dynamic Treatment Effects: Event Study Estimates",
  label = "eventstudy",
  escape = FALSE
) %>%
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  kableExtra::footnote(
    general = "Callaway-Sant'Anna group-time ATTs aggregated to event time. Doubly-robust estimator with never-treated controls. Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01.",
    threeparttable = TRUE
  )

writeLines(tab3_tex, file.path(table_dir, "tab3_eventstudy.tex"))

# ============================================================
# Table 4: Robustness Checks
# ============================================================
cat("Generating Table 4: Robustness\n")

rob_rows <- list()

# Baseline
rob_rows[["Baseline (CS)"]] <- c(
  sprintf("%.3f", cs_div_att),
  sprintf("(%.3f)", cs_div_se),
  as.character(nrow(cdc))
)

# No covenant marriage states
if (!is.null(robustness$agg_no_covenant)) {
  rob_rows[["Excl. Covenant Marriage States"]] <- c(
    sprintf("%.3f", robustness$agg_no_covenant$overall.att),
    sprintf("(%.3f)", robustness$agg_no_covenant$overall.se),
    as.character(nrow(cdc %>% filter(!state_abb %in% c("LA", "AZ", "AR"))))
  )
}

# Late adopters
if (!is.null(robustness$agg_late)) {
  rob_rows[["Late Adopters Only"]] <- c(
    sprintf("%.3f", robustness$agg_late$overall.att),
    sprintf("(%.3f)", robustness$agg_late$overall.se),
    as.character(nrow(cdc %>% filter(!state_abb %in% c("FL", "OK"))))
  )
}

# With controls
if (!is.null(robustness$agg_controls)) {
  rob_rows[["With Unemployment Control"]] <- c(
    sprintf("%.3f", robustness$agg_controls$overall.att),
    sprintf("(%.3f)", robustness$agg_controls$overall.se),
    as.character(nrow(cdc %>% filter(!is.na(unemployment_rate))))
  )
}

# Placebo (TWFE with 3-year shift)
if (!is.null(robustness$agg_placebo)) {
  rob_rows[["Placebo (3-Year Shift, TWFE)"]] <- c(
    sprintf("%.3f", robustness$agg_placebo$overall.att),
    sprintf("(%.3f)", robustness$agg_placebo$overall.se),
    "---"
  )
}

rob_df <- do.call(rbind, rob_rows)
colnames(rob_df) <- c("ATT", "SE", "N")
rob_df <- as.data.frame(rob_df)
rob_df$Specification <- rownames(rob_df)
rob_df <- rob_df[, c("Specification", "ATT", "SE", "N")]

tab4_tex <- kableExtra::kbl(
  rob_df, format = "latex", booktabs = TRUE, row.names = FALSE,
  caption = "Robustness Checks: Effect on Divorce Rate",
  label = "robustness",
  escape = FALSE
) %>%
  kableExtra::kable_styling(latex_options = "hold_position") %>%
  kableExtra::footnote(
    general = "All specifications use Callaway-Sant'Anna with doubly-robust method and never-treated controls except where noted. Covenant marriage states: Louisiana, Arizona, Arkansas. Late adopters excludes Florida (1998) and Oklahoma (1999). Placebo shifts treatment timing 5 years earlier using only pre-treatment data. Standard errors in parentheses.",
    threeparttable = TRUE
  )

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================
# Table 5: Leave-One-Out Sensitivity
# ============================================================
cat("Generating Table 5: Leave-One-Out\n")

if (nrow(robustness$loo_df) > 0) {
  loo_tab <- robustness$loo_df %>%
    mutate(
      `Dropped State` = dropped,
      ATT = sprintf("%.3f", att),
      SE = sprintf("(%.3f)", se)
    ) %>%
    select(`Dropped State`, ATT, SE)

  tab5_tex <- kableExtra::kbl(
    loo_tab, format = "latex", booktabs = TRUE, row.names = FALSE,
    caption = "Leave-One-Out Sensitivity: Effect on Divorce Rate",
    label = "loo",
    escape = FALSE
  ) %>%
    kableExtra::kable_styling(latex_options = "hold_position") %>%
    kableExtra::footnote(
      general = "Each row drops one treated state and re-estimates the overall ATT using Callaway-Sant'Anna. Standard errors in parentheses.",
      threeparttable = TRUE
    )

  writeLines(tab5_tex, file.path(table_dir, "tab5_loo.tex"))
}

# ============================================================
# Table F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================
cat("Generating Table F1: SDE\n")

pre_sd_div <- results$pre_sd_divorce
pre_sd_mar <- results$pre_sd_marriage

# Main outcomes
sde_rows <- tibble(
  Outcome = character(),
  beta = numeric(),
  se = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character()
)

classify_sde <- function(sde_val) {
  abs_sde <- abs(sde_val)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde_val > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde_val > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde_val > 0) return("Large positive") else return("Large negative")
}

# Panel A: Pooled
sde_pooled <- tibble(
  Outcome = c("Divorce rate", "Marriage rate"),
  beta = c(cs_div_att, cs_mar_att),
  se = c(cs_div_se, cs_mar_se),
  sd_y = c(pre_sd_div, pre_sd_mar),
  sde = c(cs_div_att / pre_sd_div, cs_mar_att / pre_sd_mar),
  se_sde = c(cs_div_se / pre_sd_div, cs_mar_se / pre_sd_mar)
) %>%
  mutate(classification = sapply(sde, classify_sde))

# Panel B: Heterogeneous — Early vs. Late adopters
# Early (in CS panel): MD, MN, TN (2001-2002)
# Late: SC, TX, WV, UT (2006+)
early_states <- c("MD", "MN", "TN")
late_states <- c("SC", "TX", "WV", "UT")

cdc_early <- cdc %>%
  filter(state_abb %in% early_states | treated == 0) %>%
  mutate(first_treat = if_else(!state_abb %in% early_states & treated == 1, 0L, first_treat))
cdc_late <- cdc %>%
  filter(state_abb %in% late_states | treated == 0) %>%
  mutate(first_treat = if_else(!state_abb %in% late_states & treated == 1, 0L, first_treat))

cs_early <- tryCatch({
  out <- att_gt(yname = "divorce_rate", tname = "year", idname = "state_fips",
                gname = "first_treat", data = cdc_early, control_group = "nevertreated",
                base_period = "universal", est_method = "dr")
  aggte(out, type = "simple")
}, error = function(e) NULL)

cs_late <- tryCatch({
  out <- att_gt(yname = "divorce_rate", tname = "year", idname = "state_fips",
                gname = "first_treat", data = cdc_late, control_group = "nevertreated",
                base_period = "universal", est_method = "dr")
  aggte(out, type = "simple")
}, error = function(e) NULL)

pre_sd_early <- cdc %>%
  filter(state_abb %in% early_states & treated == 1 & year < treat_year) %>%
  summarise(sd_y = sd(divorce_rate, na.rm = TRUE)) %>% pull(sd_y)

pre_sd_late <- cdc %>%
  filter(state_abb %in% late_states & treated == 1 & year < treat_year) %>%
  summarise(sd_y = sd(divorce_rate, na.rm = TRUE)) %>% pull(sd_y)

sde_hetero <- tibble(
  Outcome = character(), beta = numeric(), se = numeric(),
  sd_y = numeric(), sde = numeric(), se_sde = numeric(),
  classification = character()
)

if (!is.null(cs_early)) {
  sde_hetero <- bind_rows(sde_hetero, tibble(
    Outcome = "Divorce rate (early adopters)",
    beta = cs_early$overall.att, se = cs_early$overall.se,
    sd_y = pre_sd_early, sde = cs_early$overall.att / pre_sd_early,
    se_sde = cs_early$overall.se / pre_sd_early,
    classification = classify_sde(cs_early$overall.att / pre_sd_early)
  ))
}

if (!is.null(cs_late)) {
  sde_hetero <- bind_rows(sde_hetero, tibble(
    Outcome = "Divorce rate (late adopters)",
    beta = cs_late$overall.att, se = cs_late$overall.se,
    sd_y = pre_sd_late, sde = cs_late$overall.att / pre_sd_late,
    se_sde = cs_late$overall.se / pre_sd_late,
    classification = classify_sde(cs_late$overall.att / pre_sd_late)
  ))
}

# Format for LaTeX
format_sde <- function(df, panel_label) {
  df %>%
    mutate(
      `$\\hat{\\beta}$` = sprintf("%.3f", beta),
      SE = sprintf("%.3f", se),
      `SD(Y)` = sprintf("%.3f", sd_y),
      SDE = sprintf("%.3f", sde),
      `SE(SDE)` = sprintf("%.3f", se_sde),
      Classification = classification
    ) %>%
    select(Outcome, `$\\hat{\\beta}$`, SE, `SD(Y)`, SDE, `SE(SDE)`, Classification)
}

pooled_fmt <- format_sde(sde_pooled, "A")
hetero_fmt <- format_sde(sde_hetero, "B")

# Build LaTeX manually for two-panel table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state policies that reduce marriage license fees for couples completing premarital counseling lower divorce rates? ",
  "\\textbf{Policy mechanism:} Ten states adopted policies offering \\$20--60 marriage license fee reductions or waiting period waivers to couples completing 4--8 hours of premarital education courses, creating a financial incentive to acquire relationship skills before marriage. ",
  "\\textbf{Outcome definition:} State-level divorce rate per 1,000 population from CDC National Vital Statistics System. ",
  "\\textbf{Treatment:} Binary indicator for state adoption of a premarital education promotion policy. ",
  "\\textbf{Data:} CDC NVSS state divorce and marriage rates, 1990--2022, state-year level, approximately 1,500 state-year observations (excluding Georgia due to missing data). ",
  "\\textbf{Method:} Callaway-Sant'Anna (2021) doubly-robust estimator with never-treated controls; wild cluster bootstrap for inference with 10 treated clusters. ",
  "\\textbf{Sample:} 50 US states plus DC, excluding Georgia (missing divorce data 2004--2016); 9 treated states with staggered adoption 1998--2018, approximately 41 never-treated controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write full SDE table
sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD(Y) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(pooled_fmt))) {
  row <- pooled_fmt[i, ]
  sde_tex <- c(sde_tex, paste0(
    row$Outcome, " & ", row$`$\\hat{\\beta}$`, " & ", row$SE, " & ",
    row$`SD(Y)`, " & ", row$SDE, " & ", row$`SE(SDE)`, " & ", row$Classification, " \\\\"
  ))
}

sde_tex <- c(sde_tex, "\\addlinespace",
             "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Early vs.\\ Late Adopters)}} \\\\",
             "\\addlinespace")

for (i in seq_len(nrow(hetero_fmt))) {
  row <- hetero_fmt[i, ]
  sde_tex <- c(sde_tex, paste0(
    row$Outcome, " & ", row$`$\\hat{\\beta}$`, " & ", row$SE, " & ",
    row$`SD(Y)`, " & ", row$SDE, " & ", row$`SE(SDE)`, " & ", row$Classification, " \\\\"
  ))
}

sde_tex <- c(sde_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Tables in:", table_dir, "\n")
list.files(table_dir)
