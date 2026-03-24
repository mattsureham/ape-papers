## 05_tables.R — Generate all tables for apep_0843
## RON Laws and New Business Formation

source("00_packages.R")

panel <- readRDS("../data/panel_primary.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
ron_treat <- readRDS("../data/ron_treatment.rds")

panel <- panel %>% mutate(state_id = as.integer(factor(state)))

# ==================================================================
# Table 1: Summary Statistics
# ==================================================================
cat("Generating Table 1: Summary Statistics\n")

# Pre-treatment period statistics by group
pre_treat_stats <- panel %>%
  filter(post == 0) %>%
  mutate(group = if_else(treated_state, "Treated (22)", "Control (29)")) %>%
  group_by(group) %>%
  summarise(
    `BA Mean`     = mean(BA, na.rm = TRUE),
    `BA SD`       = sd(BA, na.rm = TRUE),
    `CBA Mean`    = mean(CBA, na.rm = TRUE),
    `CBA SD`      = sd(CBA, na.rm = TRUE),
    `HBA Mean`    = mean(HBA, na.rm = TRUE),
    `HBA SD`      = sd(HBA, na.rm = TRUE),
    `WBA Mean`    = mean(WBA, na.rm = TRUE),
    `WBA SD`      = sd(WBA, na.rm = TRUE),
    `State-Months` = n(),
    .groups = "drop"
  )

# Overall
overall_stats <- panel %>%
  filter(post == 0) %>%
  summarise(
    group = "Full Sample (51)",
    `BA Mean`     = mean(BA, na.rm = TRUE),
    `BA SD`       = sd(BA, na.rm = TRUE),
    `CBA Mean`    = mean(CBA, na.rm = TRUE),
    `CBA SD`      = sd(CBA, na.rm = TRUE),
    `HBA Mean`    = mean(HBA, na.rm = TRUE),
    `HBA SD`      = sd(HBA, na.rm = TRUE),
    `WBA Mean`    = mean(WBA, na.rm = TRUE),
    `WBA SD`      = sd(WBA, na.rm = TRUE),
    `State-Months` = n()
  )

tab1_data <- bind_rows(pre_treat_stats, overall_stats)

# Generate LaTeX
tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Business Formation}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{l rr rr rr rr r}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{BA} & \\multicolumn{2}{c}{CBA} & \\multicolumn{2}{c}{HBA} & \\multicolumn{2}{c}{WBA} & \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}\n",
  " & Mean & SD & Mean & SD & Mean & SD & Mean & SD & Obs. \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(tab1_data))) {
  row <- tab1_data[i, ]
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %s & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
      row$group,
      format(round(row$`BA Mean`, 0), big.mark = ","),
      format(round(row$`BA SD`, 0), big.mark = ","),
      format(round(row$`CBA Mean`, 0), big.mark = ","),
      format(round(row$`CBA SD`, 0), big.mark = ","),
      format(round(row$`HBA Mean`, 0), big.mark = ","),
      format(round(row$`HBA SD`, 0), big.mark = ","),
      format(round(row$`WBA Mean`, 0), big.mark = ","),
      format(round(row$`WBA SD`, 0), big.mark = ","),
      format(row$`State-Months`, big.mark = ",")
    )
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Pre-treatment summary statistics for monthly state-level business formation measures from Census Bureau Business Formation Statistics (BFS), July 2004 through December 2019. BA = Business Applications (all EIN applications); CBA = Corporate Business Applications; HBA = High-Propensity Business Applications (likely employers); WBA = Business Applications with Planned Wages. Treated states are 22 states that adopted permanent Remote Online Notarization (RON) laws between 2012 and 2019. Control states are 29 states plus DC without permanent RON laws as of December 2019. Pre-treatment is defined as months before each state's RON adoption date for treated states, and all months for control states.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ==================================================================
# Table 2: Main Results — Callaway-Sant'Anna ATT
# ==================================================================
cat("Generating Table 2: Main Results\n")

# Extract all ATT results
main_att <- tibble(
  outcome = c("log(BA)", "log(CBA)", "log(HBA)", "log(WBA)"),
  cs_att  = c(results$agg_ba$overall.att, results$agg_cba$overall.att,
              results$agg_hba$overall.att, results$agg_wba$overall.att),
  cs_se   = c(results$agg_ba$overall.se, results$agg_cba$overall.se,
              results$agg_hba$overall.se, results$agg_wba$overall.se),
  twfe_att = c(coef(results$twfe_ba)["post"], coef(results$twfe_cba)["post"], NA, NA),
  twfe_se  = c(sqrt(vcov(results$twfe_ba)["post","post"]),
               sqrt(vcov(results$twfe_cba)["post","post"]), NA, NA)
)

# Stars
add_stars <- function(est, se) {
  p <- 2 * pnorm(-abs(est / se))
  stars <- case_when(
    p < 0.01 ~ "***",
    p < 0.05 ~ "**",
    p < 0.10 ~ "*",
    TRUE ~ ""
  )
  return(stars)
}

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of RON Laws on Business Formation}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{l cc cc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Callaway-Sant'Anna} & \\multicolumn{2}{c}{TWFE} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & ATT & [95\\% CI] & $\\hat{\\beta}$ & SE \\\\\n",
  "\\hline\n"
)

for (i in 1:4) {
  r <- main_att[i, ]
  cs_ci_lo <- r$cs_att - 1.96 * r$cs_se
  cs_ci_hi <- r$cs_att + 1.96 * r$cs_se
  cs_stars <- add_stars(r$cs_att, r$cs_se)

  twfe_str <- if (!is.na(r$twfe_att)) {
    twfe_stars <- add_stars(r$twfe_att, r$twfe_se)
    sprintf("& %s%s & (%s)",
      format(round(r$twfe_att, 4), nsmall = 4), twfe_stars,
      format(round(r$twfe_se, 4), nsmall = 4))
  } else {
    "& --- & ---"
  }

  tab2_tex <- paste0(tab2_tex,
    sprintf("%s & %s%s & [%s, %s] %s \\\\\n",
      r$outcome,
      format(round(r$cs_att, 4), nsmall = 4), cs_stars,
      format(round(cs_ci_lo, 4), nsmall = 4),
      format(round(cs_ci_hi, 4), nsmall = 4),
      twfe_str
    )
  )
}

tab2_tex <- paste0(tab2_tex,
  "\\hline\n",
  "Observations & \\multicolumn{2}{c}{", format(nrow(panel), big.mark = ","), "} & \\multicolumn{2}{c}{", format(nrow(panel), big.mark = ","), "} \\\\\n",
  "Treated states & \\multicolumn{2}{c}{22} & \\multicolumn{2}{c}{22} \\\\\n",
  "Control states & \\multicolumn{2}{c}{29} & \\multicolumn{2}{c}{29} \\\\\n",
  "Control group & \\multicolumn{2}{c}{Never-treated} & \\multicolumn{2}{c}{---} \\\\\n",
  "Clustering & \\multicolumn{2}{c}{State} & \\multicolumn{2}{c}{State} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Columns (1)--(2) report Callaway and Sant'Anna (2021) aggregate ATT estimates with 95\\% pointwise confidence intervals using never-treated states as the control group. Columns (3)--(4) report conventional TWFE estimates with state-clustered standard errors. BA = all Business Applications; CBA = Corporate BA; HBA = High-Propensity BA; WBA = BA with Planned Wages. Sample: 51 US states/DC, monthly July 2004--December 2019. Treatment: permanent RON law adoption (22 states, 5 cohorts). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ==================================================================
# Table 3: Robustness
# ==================================================================
cat("Generating Table 3: Robustness\n")

main_att_val <- results$agg_ba$overall.att
main_se_val  <- results$agg_ba$overall.se

rob_rows <- tibble(
  spec = c(
    "Baseline (never-treated)",
    "Not-yet-treated control",
    "1-month anticipation",
    "Extended sample (2004--2024)",
    "Levels (BA count)"
  ),
  att = c(
    main_att_val,
    robust$nyt$att,
    robust$antic$att,
    robust$extended$att,
    robust$levels$att
  ),
  se = c(
    main_se_val,
    robust$nyt$se,
    robust$antic$se,
    robust$extended$se,
    robust$levels$se
  )
)

# Add leave-one-cohort-out
for (cohort_name in names(robust$loco)) {
  loco <- robust$loco[[cohort_name]]
  rob_rows <- bind_rows(rob_rows, tibble(
    spec = paste0("Drop ", loco$cohort, " cohort (", loco$n_dropped, " states)"),
    att = loco$att,
    se  = loco$se
  ))
}

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness of RON Effect on Business Applications}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{l cc c}\n",
  "\\hline\\hline\n",
  "Specification & ATT & SE & [95\\% CI] \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(rob_rows))) {
  r <- rob_rows[i, ]
  ci_lo <- r$att - 1.96 * r$se
  ci_hi <- r$att + 1.96 * r$se
  stars <- add_stars(r$att, r$se)

  # Format: levels row uses integers, log rows use 4 decimals
  if (grepl("Levels", r$spec)) {
    tab3_tex <- paste0(tab3_tex,
      sprintf("%s & %s%s & (%s) & [%s, %s] \\\\\n",
        r$spec,
        format(round(r$att, 1), nsmall = 1), stars,
        format(round(r$se, 1), nsmall = 1),
        format(round(ci_lo, 1), nsmall = 1),
        format(round(ci_hi, 1), nsmall = 1)
      )
    )
  } else {
    tab3_tex <- paste0(tab3_tex,
      sprintf("%s & %s%s & (%s) & [%s, %s] \\\\\n",
        r$spec,
        format(round(r$att, 4), nsmall = 4), stars,
        format(round(r$se, 4), nsmall = 4),
        format(round(ci_lo, 4), nsmall = 4),
        format(round(ci_hi, 4), nsmall = 4)
      )
    )
  }
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Callaway-Sant'Anna aggregate ATT estimates for log(Business Applications) under alternative specifications. Baseline uses never-treated states as control group with no anticipation. ``Not-yet-treated'' uses states not yet adopting RON as additional controls. ``1-month anticipation'' allows effects one month before the law's effective date. ``Extended'' includes months through December 2024 (COVID-era included). ``Levels'' uses BA count rather than log. Leave-one-cohort-out drops each adoption cohort in turn. Standard errors clustered at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_robust.tex")

# ==================================================================
# Table 4: Event Study Coefficients
# ==================================================================
cat("Generating Table 4: Event Study\n")

es_data <- tibble(
  event_time = results$es_ba$egt,
  att_ba     = results$es_ba$att.egt,
  se_ba      = results$es_ba$se.egt,
  att_cba    = results$es_cba$att.egt,
  se_cba     = results$es_cba$se.egt
)

# Keep select event times for table (-24, -18, -12, -6, -1, 0, 3, 6, 9, 12)
show_times <- c(-24, -18, -12, -6, -1, 0, 3, 6, 9, 12)
es_tab <- es_data %>% filter(event_time %in% show_times)

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Treatment Effects}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{r cc cc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{log(BA)} & \\multicolumn{2}{c}{log(CBA)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "Months & ATT & SE & ATT & SE \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(es_tab))) {
  r <- es_tab[i, ]
  ba_stars <- add_stars(r$att_ba, r$se_ba)
  cba_stars <- add_stars(r$att_cba, r$se_cba)

  tab4_tex <- paste0(tab4_tex,
    sprintf("$%+d$ & %s%s & (%s) & %s%s & (%s) \\\\\n",
      r$event_time,
      format(round(r$att_ba, 4), nsmall = 4), ba_stars,
      format(round(r$se_ba, 4), nsmall = 4),
      format(round(r$att_cba, 4), nsmall = 4), cba_stars,
      format(round(r$se_cba, 4), nsmall = 4)
    )
  )
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Callaway-Sant'Anna dynamic ATT estimates at selected event-time horizons. Event time 0 is the month of permanent RON law adoption. Negative values are months before adoption. BA = all Business Applications; CBA = Corporate Business Applications. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_eventstudy.tex")

# ==================================================================
# Table F1: Standardized Effect Size (SDE) Appendix — MANDATORY
# ==================================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute pre-treatment SD(Y) for each outcome
pre_sds <- panel %>%
  filter(post == 0) %>%
  summarise(
    sd_BA  = sd(BA, na.rm = TRUE),
    sd_CBA = sd(CBA, na.rm = TRUE),
    sd_HBA = sd(HBA, na.rm = TRUE),
    sd_WBA = sd(WBA, na.rm = TRUE),
    sd_log_BA  = sd(log_BA, na.rm = TRUE),
    sd_log_CBA = sd(log_CBA, na.rm = TRUE),
    sd_log_HBA = sd(log_HBA, na.rm = TRUE),
    sd_log_WBA = sd(log_WBA, na.rm = TRUE)
  )

# SDE = beta / SD(Y) for log outcomes
classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# Panel A: Pooled
sde_pooled <- tibble(
  outcome = c("Business Applications (BA)", "Corporate BA (CBA)",
              "High-Propensity BA (HBA)", "BA with Planned Wages (WBA)"),
  beta = c(results$agg_ba$overall.att, results$agg_cba$overall.att,
           results$agg_hba$overall.att, results$agg_wba$overall.att),
  se = c(results$agg_ba$overall.se, results$agg_cba$overall.se,
         results$agg_hba$overall.se, results$agg_wba$overall.se),
  sd_y = c(pre_sds$sd_log_BA, pre_sds$sd_log_CBA,
           pre_sds$sd_log_HBA, pre_sds$sd_log_WBA)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = classify_sde(sde)
  )

# Panel B: Heterogeneity — Early vs Late adopters (sample splits)
# Early = 2012-2017 cohorts (VA, MT, TX, NV)
# Late = 2018-2019 cohorts (18 states)
early_states <- ron_treat %>% filter(year(ron_date) <= 2017) %>% pull(state)
late_states  <- ron_treat %>% filter(year(ron_date) > 2017) %>% pull(state)

# Early adopters: log(BA)
panel_early <- panel %>%
  filter(state %in% early_states | first_treat == 0) %>%
  mutate(state_id = as.integer(factor(state)))

cs_early <- att_gt(
  yname = "log_BA", tname = "time_index", idname = "state_id",
  gname = "first_treat", data = panel_early,
  control_group = "nevertreated", anticipation = 0, base_period = "varying"
)
agg_early <- aggte(cs_early, type = "simple")

# Late adopters: log(BA)
panel_late <- panel %>%
  filter(state %in% late_states | first_treat == 0) %>%
  mutate(state_id = as.integer(factor(state)))

cs_late <- att_gt(
  yname = "log_BA", tname = "time_index", idname = "state_id",
  gname = "first_treat", data = panel_late,
  control_group = "nevertreated", anticipation = 0, base_period = "varying"
)
agg_late <- aggte(cs_late, type = "simple")

# Pre-treatment SDs for subgroups
sd_early <- sd(panel_early$log_BA[panel_early$post == 0], na.rm = TRUE)
sd_late  <- sd(panel_late$log_BA[panel_late$post == 0], na.rm = TRUE)

sde_hetero <- tibble(
  outcome = c("BA: Early adopters (2012--2017)", "BA: Late adopters (2018--2019)"),
  beta = c(agg_early$overall.att, agg_late$overall.att),
  se = c(agg_early$overall.se, agg_late$overall.se),
  sd_y = c(sd_early, sd_late)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = classify_sde(sde)
  )

# Generate SDE LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level Remote Online Notarization (RON) laws, which eliminate the requirement for in-person notarization of legal documents, increase new business formation? ",
  "\\textbf{Policy mechanism:} RON laws authorize notarial acts performed via real-time audio-video communication technology, removing the requirement that a signer physically appear before a notary public; this reduces scheduling costs, geographic frictions, and time burdens associated with business incorporation, LLC formation, and related filings that require notarized documents. ",
  "\\textbf{Outcome definition:} Monthly new business applications (EIN applications) from Census Bureau Business Formation Statistics (BFS), measured as log-transformed counts at the state-month level. ",
  "\\textbf{Treatment:} Binary; permanent state-level adoption of RON legislation. ",
  "\\textbf{Data:} Census Bureau Business Formation Statistics via FRED API, July 2004--December 2019, 51 state-level jurisdictions, ",
  format(nrow(panel), big.mark = ","), " state-month observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered difference-in-differences with never-treated states as control group; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 51 US states and DC; 22 treated states adopted permanent RON laws across 5 cohorts (2012--2019); 29 control states had no permanent RON law by December 2019; COVID-era emergency RON orders excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

make_sde_row <- function(r) {
  sprintf("%s & %s & (%s) & %s & %s & (%s) & %s",
    r$outcome,
    format(round(r$beta, 4), nsmall = 4),
    format(round(r$se, 4), nsmall = 4),
    format(round(r$sd_y, 3), nsmall = 3),
    format(round(r$sde, 4), nsmall = 4),
    format(round(r$se_sde, 4), nsmall = 4),
    r$classification
  )
}

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{l cc c cc l}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in seq_len(nrow(sde_pooled))) {
  tabF1_tex <- paste0(tabF1_tex, make_sde_row(sde_pooled[i, ]), " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n"
)

for (i in seq_len(nrow(sde_hetero))) {
  tabF1_tex <- paste0(tabF1_tex, make_sde_row(sde_hetero[i, ]), " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_robust.tex\n")
cat("  tables/tab4_eventstudy.tex\n")
cat("  tables/tabF1_sde.tex\n")
