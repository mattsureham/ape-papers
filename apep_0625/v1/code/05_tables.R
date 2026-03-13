# =============================================================================
# 05_tables.R — Generate all LaTeX tables including SDE appendix
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
panel <- readRDS("../data/panel_clean.rds")
pre_gaps <- readRDS("../data/pre_gaps.rds")
ban_dates <- readRDS("../data/ban_dates.rds")

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

sumstats <- panel %>%
  group_by(treated) %>%
  summarise(
    `Female New-Hire Earnings` = mean(EarnHirNS_Female, na.rm = TRUE),
    `Male New-Hire Earnings` = mean(EarnHirNS_Male, na.rm = TRUE),
    `Gender Gap (log)` = mean(earn_gap_log, na.rm = TRUE),
    `Gender Gap (ratio)` = mean(earn_gap_ratio, na.rm = TRUE),
    `Female Emp (000s)` = mean(Emp_Female / 1000, na.rm = TRUE),
    `Male Emp (000s)` = mean(Emp_Male / 1000, na.rm = TRUE),
    `New Hires (Female)` = mean(HirN_Female, na.rm = TRUE),
    `New Hires (Male)` = mean(HirN_Male, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  ) %>%
  mutate(Group = ifelse(treated, "Ban States (16)", "No-Ban States (34)")) %>%
  select(Group, everything(), -treated)

# Format as LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: QWI State-Industry-Quarter Panel, 2013--2023}",
  "\\label{tab:sumstats}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Ban States (16) & No-Ban States (34) \\\\",
  "\\midrule"
)

vars <- c("Female New-Hire Earnings", "Male New-Hire Earnings",
          "Gender Gap (log)", "Gender Gap (ratio)",
          "Female Emp (000s)", "Male Emp (000s)",
          "New Hires (Female)", "New Hires (Male)", "N")

for (v in vars) {
  val1 <- sumstats[[v]][sumstats$Group == "Ban States (16)"]
  val2 <- sumstats[[v]][sumstats$Group == "No-Ban States (34)"]
  if (v == "N") {
    tab1_lines <- c(tab1_lines,
                    sprintf("%s & %s & %s \\\\",
                            v, format(round(val1), big.mark = ","),
                            format(round(val2), big.mark = ",")))
  } else if (v %in% c("Gender Gap (log)", "Gender Gap (ratio)")) {
    tab1_lines <- c(tab1_lines,
                    sprintf("%s & %.3f & %.3f \\\\", v, val1, val2))
  } else {
    tab1_lines <- c(tab1_lines,
                    sprintf("%s & %s & %s \\\\",
                            v, format(round(val1), big.mark = ","),
                            format(round(val2), big.mark = ",")))
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} QWI state$\\times$industry$\\times$quarter panel, 2013Q1--2023Q4.",
  "Ban States adopted private-employer salary history bans between 2017 and 2023.",
  "New-hire earnings are average monthly earnings of workers in their first quarter at a firm.",
  "Gender gap (log) is $\\ln(\\text{Female Earn}) - \\ln(\\text{Male Earn})$; ratio is Female/Male.",
  "Employment and hiring figures are per state-industry-quarter cell.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")
cat("Table 1 written.\n")

# =============================================================================
# Table 2: Main Results — CS-DiD ATT
# =============================================================================
cat("\n=== Generating Table 2: Main Results ===\n")

# Extract results
cs_att <- results$agg_simple$overall.att
cs_se <- results$agg_simple$overall.se
cs_n <- results$n_obs

twfe_coefs_all <- coef(results$twfe)
twfe_coef <- twfe_coefs_all[grep("post", names(twfe_coefs_all))[1]]
twfe_ses_all <- se(results$twfe)
twfe_se <- twfe_ses_all[grep("post", names(twfe_ses_all))[1]]
twfe_n <- nobs(results$twfe)

sa_coefs <- coef(results$sa_es)
sa_ses <- se(results$sa_es)
# Get the ATT from Sun-Abraham (aggregate post-treatment)
sa_post <- sa_coefs[grep("^yq::", names(sa_coefs))]
sa_att <- mean(sa_post, na.rm = TRUE)

# Female earnings
fem_att <- results$agg_female_simple$overall.att
fem_se <- results$agg_female_simple$overall.se

# Stars function
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.1) return("^{*}")
  return("")
}

p_cs <- 2 * pnorm(-abs(cs_att / cs_se))
p_twfe <- 2 * pnorm(-abs(twfe_coef / twfe_se))
p_fem <- 2 * pnorm(-abs(fem_att / fem_se))

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Salary History Bans on the Gender Earnings Gap}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) CS-DiD & (2) TWFE & (3) Female Earn \\\\",
  " & Gender Gap & Gender Gap & (log) \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Ban & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\",
          cs_att, stars(p_cs), twfe_coef, stars(p_twfe), fem_att, stars(p_fem)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\", cs_se, twfe_se, fem_se),
  "\\midrule",
  "Estimator & Callaway-Sant'Anna & TWFE & Callaway-Sant'Anna \\\\",
  "Unit FE & State & State$\\times$Industry & State \\\\",
  "Time FE & Quarter & Quarter & Quarter \\\\",
  sprintf("Observations & %s & %s & %s \\\\",
          format(results$n_state_qtr, big.mark = ","),
          format(twfe_n, big.mark = ","),
          format(results$n_state_qtr, big.mark = ",")),
  sprintf("Treated states & %d & %d & %d \\\\",
          results$n_treated, results$n_treated, results$n_treated),
  sprintf("Control states & %d & %d & %d \\\\",
          results$n_control, results$n_control, results$n_control),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable in columns (1)--(2) is $\\ln(\\text{Female Earn}) - \\ln(\\text{Male Earn})$",
  "among new hires. Column (3) uses log female new-hire earnings.",
  "Column (1) uses the Callaway and Sant'Anna (2021) estimator with never-treated states as controls",
  "and doubly-robust estimation. Column (2) uses two-way fixed effects with employment weights.",
  "Standard errors clustered at the state level in parentheses.",
  "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# =============================================================================
# Table 3: Industry Heterogeneity (DDD)
# =============================================================================
cat("\n=== Generating Table 3: Industry Heterogeneity ===\n")

ddd <- rob_results$ddd_industry
ddd_coefs <- coef(ddd)
ddd_ses <- se(ddd)
ddd_pvs <- pvalue(ddd)

ind_effs <- rob_results$industry_effects
if (!is.null(ind_effs) && nrow(ind_effs) > 0) {
  # Industry name mapping
  ind_names <- tribble(
    ~industry, ~name,
    "52", "Finance \\& Insurance",
    "54", "Professional Services",
    "71", "Arts \\& Entertainment",
    "56", "Admin \\& Waste Mgmt",
    "72", "Accommodation \\& Food",
    "44-45", "Retail Trade",
    "42", "Wholesale Trade",
    "31-33", "Manufacturing",
    "62", "Health Care",
    "61", "Education",
    "23", "Construction",
    "51", "Information",
    "48-49", "Transport \\& Warehouse",
    "53", "Real Estate",
    "55", "Mgmt of Companies",
    "81", "Other Services",
    "11", "Agriculture",
    "21", "Mining",
    "22", "Utilities",
    "92", "Government"
  )

  ind_effs <- ind_effs %>%
    left_join(ind_names, by = "industry") %>%
    mutate(
      name = ifelse(is.na(name), industry, name),
      p = 2 * pnorm(-abs(coef / se)),
      star = sapply(p, stars)
    )
}

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Industry Heterogeneity: Salary History Bans and the Gender Gap}",
  "\\label{tab:industry}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{DDD Specification} & \\multicolumn{2}{c}{Pre-Ban Gap} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Coefficient & SE & Gap (\\%) & Category \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Ban & $%.4f%s$ & (%.4f) & & \\\\",
          ddd_coefs["post"], stars(ddd_pvs["post"]), ddd_ses["post"]),
  sprintf("Post $\\times$ Ban $\\times$ High-Gap & $%.4f%s$ & (%.4f) & & \\\\",
          ddd_coefs["post:high_gapTRUE"], stars(ddd_pvs["post:high_gapTRUE"]),
          ddd_ses["post:high_gapTRUE"]),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Selected industry-specific effects:}} \\\\"
)

if (!is.null(ind_effs) && nrow(ind_effs) > 0) {
  for (i in 1:min(nrow(ind_effs), 6)) {
    row <- ind_effs[i, ]
    tab3_lines <- c(tab3_lines,
      sprintf("\\quad %s & $%.4f%s$ & (%.4f) & %.1f & %s \\\\",
              row$name, row$coef, row$star, row$se,
              row$gap_name,
              ifelse(row$gap_name > median(pre_gaps$gap_pct, na.rm = TRUE), "High", "Low")))
  }
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\", format(nobs(ddd), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} DDD specification interacts the Post$\\times$Ban indicator with an",
  "indicator for industries in the top half of the pre-ban gender gap distribution.",
  "High-Gap industries had pre-ban female/male earnings ratios below the median.",
  "Industry-specific effects from separate TWFE regressions by industry.",
  "Standard errors clustered at the state level.",
  "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_industry.tex")
cat("Table 3 written.\n")

# =============================================================================
# Table 4: Race Mechanism + Placebo Tests
# =============================================================================
cat("\n=== Generating Table 4: Robustness ===\n")

# Race gap effect
race_att <- if (!is.null(rob_results$agg_race_simple)) {
  rob_results$agg_race_simple$overall.att
} else NA
race_se <- if (!is.null(rob_results$agg_race_simple)) {
  rob_results$agg_race_simple$overall.se
} else NA

# Government placebo
gov_panel_data <- panel %>% filter(industry == "92")
if (nrow(gov_panel_data) > 100) {
  gov_mod <- feols(earn_gap_log ~ post | state_fips + yq,
                   data = gov_panel_data, cluster = ~state_fips)
  gov_coef <- coef(gov_mod)["post"]
  gov_se <- se(gov_mod)["post"]
  gov_p <- pvalue(gov_mod)["post"]
  gov_n <- nobs(gov_mod)
} else {
  gov_coef <- NA; gov_se <- NA; gov_p <- NA; gov_n <- 0
}

# Pre-treatment placebo
plac_coef <- coef(rob_results$placebo_twfe)["fake_postTRUE"]
plac_se <- se(rob_results$placebo_twfe)["fake_postTRUE"]
plac_p <- pvalue(rob_results$placebo_twfe)["fake_postTRUE"]
plac_n <- nobs(rob_results$placebo_twfe)

# Male earnings
male_coef <- coef(rob_results$twfe_male)["post"]
male_se <- se(rob_results$twfe_male)["post"]
male_p <- pvalue(rob_results$twfe_male)["post"]
male_n <- nobs(rob_results$twfe_male)

# Black hiring
bh_coef <- coef(rob_results$twfe_black_hire)["postTRUE"]
bh_se <- se(rob_results$twfe_black_hire)["postTRUE"]
bh_p <- pvalue(rob_results$twfe_black_hire)["postTRUE"]
bh_n <- nobs(rob_results$twfe_black_hire)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness and Mechanism Tests}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) Race Gap & (2) Black Hiring & (3) Government & (4) Male Earn & (5) Placebo \\\\",
  " & B-W (log) & Rate Gap & Placebo & (log) & (fake treat) \\\\",
  "\\midrule"
)

# Row for each test
format_row <- function(coef_val, se_val, p_val) {
  if (is.na(coef_val)) return(c("---", ""))
  star_str <- stars(p_val)
  c(sprintf("$%.4f%s$", coef_val, star_str),
    sprintf("(%.4f)", se_val))
}

r1 <- format_row(race_att, race_se, if(!is.na(race_att)) 2*pnorm(-abs(race_att/race_se)) else NA)
r2 <- format_row(bh_coef, bh_se, bh_p)
r3 <- format_row(gov_coef, gov_se, gov_p)
r4 <- format_row(male_coef, male_se, male_p)
r5 <- format_row(plac_coef, plac_se, plac_p)

tab4_lines <- c(tab4_lines,
  sprintf("Post $\\times$ Ban & %s & %s & %s & %s & %s \\\\",
          r1[1], r2[1], r3[1], r4[1], r5[1]),
  sprintf(" & %s & %s & %s & %s & %s \\\\",
          r1[2], r2[2], r3[2], r4[2], r5[2]),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          ifelse(!is.na(race_att), format(nrow(rob_results$cs_race$DIDparams$data), big.mark = ","), "---"),
          format(bh_n, big.mark = ","),
          format(gov_n, big.mark = ","),
          format(male_n, big.mark = ","),
          format(plac_n, big.mark = ",")),
  "Expected sign & $+$ (narrows) & $+$ or $-$ & $\\approx 0$ & $\\approx 0$ & $\\approx 0$ \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} (1) Black--White log new-hire earnings gap (CS-DiD).",
  "(2) Black--White new-hire rate gap (TWFE).",
  "(3) Government sector placebo (NAICS 92; exempt from private-employer bans).",
  "(4) Log male new-hire earnings (should be unaffected if bans target gender gap).",
  "(5) Pre-treatment placebo with fake treatment 4 years before actual.",
  "Standard errors clustered at the state level.",
  "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# =============================================================================
# Table 5: Event Study Coefficients
# =============================================================================
cat("\n=== Generating Table 5: Event Study ===\n")

es <- results$agg_dynamic
es_df <- tibble(
  e = es$egt,
  att = es$att.egt,
  se = es$se.egt,
  ci_lower = att - 1.96 * se,
  ci_upper = att + 1.96 * se,
  p = 2 * pnorm(-abs(att / se))
)

# Select key event-time periods
key_periods <- es_df %>%
  filter(e %in% c(-12, -8, -4, -1, 0, 1, 4, 8, 12))

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study Estimates: Gender Gap Response to Salary History Bans}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{ccccc}",
  "\\toprule",
  "Quarters Relative & ATT & SE & 95\\% CI & \\\\",
  "to Ban & & & & \\\\",
  "\\midrule"
)

for (i in 1:nrow(key_periods)) {
  row <- key_periods[i, ]
  star_str <- stars(row$p)
  tab5_lines <- c(tab5_lines,
    sprintf("$%+d$ & $%.4f%s$ & (%.4f) & [%.4f, %.4f] \\\\",
            row$e, row$att, star_str, row$se, row$ci_lower, row$ci_upper))
  if (row$e == -1) {
    tab5_lines <- c(tab5_lines, "\\midrule")
  }
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic aggregation.",
  "Dependent variable: log female/male new-hire earnings ratio.",
  "Event time 0 is the quarter of ban implementation.",
  "Negative event times are pre-treatment (parallel trends test).",
  "95\\% confidence intervals based on pointwise standard errors clustered at the state level.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_eventstudy.tex")
cat("Table 5 written.\n")

# =============================================================================
# SDE Appendix Table (MANDATORY)
# =============================================================================
cat("\n=== Generating SDE Appendix Table ===\n")

# Compute SDE for main outcomes
# For binary treatment, SDE = beta_hat / SD(Y)
gap_sd <- sd(panel$earn_gap_log, na.rm = TRUE)
fem_sd <- sd(log(panel$EarnHirNS_Female), na.rm = TRUE)

sde_rows <- tibble(
  Outcome = character(),
  beta = numeric(),
  se_beta = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character()
)

# Gender gap (main result)
sde_rows <- bind_rows(sde_rows, tibble(
  Outcome = "Gender Earnings Gap (log)",
  beta = results$agg_simple$overall.att,
  se_beta = results$agg_simple$overall.se,
  sd_y = gap_sd,
  sde = results$agg_simple$overall.att / gap_sd,
  se_sde = results$agg_simple$overall.se / gap_sd,
  classification = NA_character_
))

# Female earnings
sde_rows <- bind_rows(sde_rows, tibble(
  Outcome = "Female New-Hire Earnings (log)",
  beta = results$agg_female_simple$overall.att,
  se_beta = results$agg_female_simple$overall.se,
  sd_y = fem_sd,
  sde = results$agg_female_simple$overall.att / fem_sd,
  se_sde = results$agg_female_simple$overall.se / fem_sd,
  classification = NA_character_
))

# Race gap
if (!is.null(rob_results$agg_race_simple)) {
  race_panel_data <- readRDS("../data/race_panel_clean.rds")
  race_sd <- sd(race_panel_data$race_gap_log, na.rm = TRUE)
  sde_rows <- bind_rows(sde_rows, tibble(
    Outcome = "Black-White Earnings Gap (log)",
    beta = rob_results$agg_race_simple$overall.att,
    se_beta = rob_results$agg_race_simple$overall.se,
    sd_y = race_sd,
    sde = rob_results$agg_race_simple$overall.att / race_sd,
    se_sde = rob_results$agg_race_simple$overall.se / race_sd,
    classification = NA_character_
  ))
}

# Classify SDE
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

sde_rows <- sde_rows %>%
  mutate(classification = classify_sde(sde))

# Write SDE table
sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_rows)) {
  row <- sde_rows[i, ]
  sde_lines <- c(sde_lines,
    sprintf("%s & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
            row$Outcome, row$beta, row$se_beta, row$sd_y,
            row$sde, row$se_sde, row$classification))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standardized effect sizes computed as SDE $= \\hat{\\beta} / \\text{SD}(Y)$",
  "for binary treatment (salary history ban adoption).",
  "Research question: Do salary history bans narrow the gender earnings gap among new hires?",
  "Data: Quarterly Workforce Indicators (QWI), state$\\times$industry$\\times$quarter panel, 2013--2023.",
  "Method: Callaway and Sant'Anna (2021) staggered DiD with never-treated states as controls.",
  "Sample: 16 treated states, 34 never-treated states, across 20 NAICS industries.",
  "Total observations: ", format(results$n_obs, big.mark = ","), ".",
  "Classification refers to effect magnitude, not statistical significance.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("SDE table written.\n")

cat("\n=== All tables generated ===\n")
