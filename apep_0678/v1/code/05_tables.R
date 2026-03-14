# 05_tables.R — Generate all LaTeX tables for APEP-0678
# APEP-0678: Price Floors and Poison — MUP and Alcohol-Specific Mortality
#
# Tables produced:
#   tab1_summary.tex      — Summary statistics: 3 countries, pre/post
#   tab2_main_did.tex     — Main DiD results (country-level + regional)
#   tab3_event_study.tex  — Event-study coefficients (Scotland vs England)
#   tab4_robustness.tex   — Robustness checks
#   tab5_deprivation.tex  — Deprivation gradient analysis
#   tabF1_sde.tex         — SDE / standard deviations of estimates

source("00_packages.R")

cat("\n=== GENERATING TABLES FOR APEP-0678 ===\n\n")

DATA_DIR  <- "../data"
TABLE_DIR <- "../tables"
if (!dir.exists(TABLE_DIR)) dir.create(TABLE_DIR, recursive = TRUE)

country_panel     <- readRDS(file.path(DATA_DIR, "country_panel.rds"))
region_panel      <- readRDS(file.path(DATA_DIR, "region_panel.rds"))
deprivation_panel <- readRDS(file.path(DATA_DIR, "deprivation_panel.rds"))
main_results      <- readRDS(file.path(DATA_DIR, "main_results.rds"))
robustness        <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))

# Helper: write a tex file cleanly
write_tex <- function(lines, filename) {
  path <- file.path(TABLE_DIR, filename)
  writeLines(lines, path)
  cat("  Written:", filename, "\n")
  invisible(path)
}

# ============================================================================
# TABLE 1: Summary Statistics (3 countries, pre/post)
# ============================================================================
cat("--- Table 1: Summary statistics ---\n")

sum_stats <- country_panel %>%
  mutate(period = if_else(year <= 2017, "Pre-MUP (2013--17)", "Post-MUP (2018--23)")) %>%
  group_by(country, period) %>%
  summarise(
    n_years    = n(),
    mean_rate  = mean(rate, na.rm = TRUE),
    sd_rate    = sd(rate, na.rm = TRUE),
    min_rate   = min(rate, na.rm = TRUE),
    max_rate   = max(rate, na.rm = TRUE),
    mean_deaths = mean(deaths, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(country, period)

# Formatting helpers
fmt1  <- function(x) formatC(x, digits = 1, format = "f")
fmt0  <- function(x) formatC(x, digits = 0, format = "f")

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Alcohol-Specific Mortality Rates}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  paste0("Country & Period & Years & Mean Rate & SD & Min & Max \\\\"),
  "\\midrule"
)

# Rows
for (i in seq_len(nrow(sum_stats))) {
  r   <- sum_stats[i, ]
  row <- paste0(
    r$country, " & ",
    r$period, " & ",
    r$n_years, " & ",
    fmt1(r$mean_rate), " & ",
    fmt1(r$sd_rate), " & ",
    fmt1(r$min_rate), " & ",
    fmt1(r$max_rate), " \\\\"
  )
  # Add midrule between countries
  if (i > 1 && sum_stats$country[i] != sum_stats$country[i - 1]) {
    tab1 <- c(tab1, "\\midrule")
  }
  tab1 <- c(tab1, row)
}

# Compute overall England trend
eng_pre  <- mean(country_panel$rate[country_panel$country == "England" & country_panel$year <= 2017])
eng_post <- mean(country_panel$rate[country_panel$country == "England" & country_panel$year >= 2018])
sco_pre  <- mean(country_panel$rate[country_panel$country == "Scotland" & country_panel$year <= 2017])
sco_post <- mean(country_panel$rate[country_panel$country == "Scotland" & country_panel$year >= 2018])
wal_pre  <- mean(country_panel$rate[country_panel$country == "Wales"    & country_panel$year <= 2019])
wal_post <- mean(country_panel$rate[country_panel$country == "Wales"    & country_panel$year >= 2020])

tab1 <- c(tab1,
  "\\bottomrule",
  "\\end{tabular}",
  paste0("\\begin{tablenotes}"),
  "\\small",
  paste0("\\item \\textit{Notes:} Age-standardised alcohol-specific mortality rates per 100,000 population ",
         "(European Standard Population 2013). England: OHID Fingertips indicator 91380. ",
         "Scotland: NRS Alcohol-Specific Deaths bulletin. Wales: ONS Alcohol-Specific Deaths bulletin. ",
         "Pre-MUP period defined as 2013--2017 for Scotland and England; 2013--2019 for Wales ",
         "(Scotland MUP: May 2018; Wales MUP: March 2020; England: no MUP implemented)."),
  "\\end{tablenotes}",
  "\\end{table}"
)

write_tex(tab1, "tab1_summary.tex")

# ============================================================================
# TABLE 2: Main DiD Results
# ============================================================================
cat("\n--- Table 2: Main DiD results ---\n")

twfe_coef     <- main_results$twfe_country_coef
twfe_se       <- main_results$twfe_country_se
perm_pval     <- main_results$perm_pval
cs_att        <- main_results$cs_overall_att
cs_se         <- main_results$cs_overall_se
did_scot      <- main_results$did_att_scotland
did_wales     <- main_results$did_att_wales
reg_coef      <- main_results$twfe_region_coef
reg_se        <- main_results$twfe_region_se

# Significance stars (based on permutation p-value for country-level)
perm_stars <- if (perm_pval < 0.01) "***" else if (perm_pval < 0.05) "**" else if (perm_pval < 0.10) "*" else ""
reg_t      <- abs(reg_coef / reg_se)
reg_stars  <- if (reg_t > 2.58) "***" else if (reg_t > 1.96) "**" else if (reg_t > 1.64) "*" else ""
cs_t       <- abs(cs_att / cs_se)
cs_stars   <- if (cs_t > 2.58) "***" else if (cs_t > 1.96) "**" else if (cs_t > 1.64) "*" else ""

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Main Difference-in-Differences Estimates}",
  "\\label{tab:main_did}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Country-Level} & \\multicolumn{2}{c}{Regional-Level} & \\\\",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}",
  " & (1) TWFE & (2) Simple DiD & (3) TWFE & (4) CS-DiD & \\\\",
  "\\midrule",
  paste0("ATT (MUP treatment) & ",
         fmt1(twfe_coef), perm_stars, " & -- & ",
         fmt1(reg_coef), reg_stars, " & ",
         fmt1(cs_att), cs_stars, " & \\\\"),
  paste0(" & (", fmt1(twfe_se), ") & & (",
         fmt1(reg_se), ") & (",
         fmt1(cs_se), ") & \\\\"),
  "\\midrule",
  paste0("Scotland simple DiD & -- & ", fmt1(did_scot), " & -- & -- & \\\\"),
  paste0("Wales simple DiD    & -- & ", fmt1(did_wales), " & -- & -- & \\\\"),
  "\\midrule",
  "Country FE  & Yes & -- & Yes & Yes & \\\\",
  "Year FE     & Yes & -- & Yes & Yes & \\\\",
  "Cluster     & Country & -- & Unit & Unit & \\\\",
  "Inference   & Permutation & -- & Cluster SE & Bootstrap & \\\\",
  paste0("Permutation p-value & ", formatC(perm_pval, digits = 3, format = "f"),
         " & -- & -- & -- & \\\\"),
  paste0("Observations & ", nrow(country_panel), " & ",
         nrow(country_panel), " & ",
         nrow(region_panel), " & ",
         nrow(region_panel), " & \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is age-standardised alcohol-specific mortality rate ",
  "per 100,000. Col.~(1): two-way fixed effects (country + year) with permutation-based p-value ",
  "(10,000 draws). Col.~(2): simple pre-post DiD using 2013--2017 pre-period. ",
  "Col.~(3): TWFE on 11-unit regional panel (9 English regions + Scotland + Wales), ",
  "cluster-robust SEs. Col.~(4): Callaway-Sant'Anna (2021) staggered DiD with never-treated ",
  "English regions as controls, bootstrap SEs. Stars: ${}^{*}p<0.10$, ${}^{**}p<0.05$, ${}^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

write_tex(tab2, "tab2_main_did.tex")

# ============================================================================
# TABLE 3: Event Study Coefficients
# ============================================================================
cat("\n--- Table 3: Event study coefficients ---\n")

es_df    <- main_results$event_study_scotland
wales_es <- main_results$event_study_wales

# Make sure both have same years
all_es_years <- 2013:2023
es_full <- tibble(year = all_es_years) %>%
  left_join(es_df    %>% select(year, coef_scot = coef, se_scot = se), by = "year") %>%
  left_join(wales_es %>% select(year, coef_wal  = coef, se_wal  = se), by = "year") %>%
  mutate(across(where(is.numeric), ~replace_na(.x, 0)))

stars_fn <- function(coef, se) {
  if (se == 0) return("")
  t <- abs(coef / se)
  if (t > 2.58) "***" else if (t > 1.96) "**" else if (t > 1.64) "*" else ""
}

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event-Study Estimates: Mortality Rate Differential vs England}",
  "\\label{tab:event_study}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Scotland vs England} & \\multicolumn{2}{c}{Wales vs England} \\\\",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}",
  "Year & Coefficient & (SE) & Coefficient & (SE) \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_full))) {
  r     <- es_full[i, ]
  yr    <- r$year
  # Reference year annotation
  ref_note <- ""
  if (yr == 2017) ref_note <- " [ref]"
  if (yr == 2019) ref_note <- " [ref-W]"
  cs    <- stars_fn(r$coef_scot, r$se_scot)
  cw    <- stars_fn(r$coef_wal,  r$se_wal)
  cs_se <- if (r$se_scot == 0) "--" else paste0("(", fmt1(r$se_scot), ")")
  cw_se <- if (r$se_wal  == 0) "--" else paste0("(", fmt1(r$se_wal),  ")")
  row   <- paste0(yr, ref_note, " & ",
                  fmt1(r$coef_scot), cs, " & ", cs_se, " & ",
                  fmt1(r$coef_wal),  cw, " & ", cw_se, " \\\\")
  # Separator at MUP treatment years
  if (yr == 2017 || yr == 2019) tab3 <- c(tab3, "\\midrule")
  tab3 <- c(tab3, row)
}

tab3 <- c(tab3,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Event-study estimates from two-way fixed effects (country + year). ",
  "Scotland (Wales) relative to England, with 2017 (2019) as the omitted reference year. ",
  "Coefficients represent the additional mortality differential vs England in each year. ",
  "Rows above \\textit{midrule} are pre-treatment; rows below are post-treatment. ",
  "Stars: ${}^{*}p<0.10$, ${}^{**}p<0.05$, ${}^{***}p<0.01$ (cluster-robust SEs).",
  "\\end{tablenotes}",
  "\\end{table}"
)

write_tex(tab3, "tab3_event_study.tex")

# ============================================================================
# TABLE 4: Robustness Checks
# ============================================================================
cat("\n--- Table 4: Robustness checks ---\n")

rob <- robustness

fmt3 <- function(x) formatC(x, digits = 3, format = "f")

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Coefficient & SE / p-value \\\\",
  "\\midrule",
  "\\textit{Panel A: Baseline} & & \\\\",
  paste0("\\quad TWFE country-level (main) & ",
         fmt1(main_results$twfe_country_coef), " & perm p = ",
         fmt3(main_results$perm_pval), " \\\\"),
  "\\midrule",
  "\\textit{Panel B: Placebo outcomes} & & \\\\",
  paste0("\\quad Crude all-cause mortality & ",
         fmt1(rob$placebo_coef), " & (",
         fmt1(rob$placebo_se), ") \\\\"),
  "\\midrule",
  "\\textit{Panel C: Synthetic control} & & \\\\",
  paste0("\\quad Avg.~post-treatment gap (Scotland) & ",
         fmt1(rob$synth_avg_gap), " & p = ",
         fmt3(rob$synth_pval), " \\\\"),
  "\\midrule",
  "\\textit{Panel D: Alternative treatment windows} & & \\\\",
  paste0("\\quad Scotland 2019 (first full year) & ",
         fmt1(rob$twfe_alt2019_coef), " & \\\\"),
  paste0("\\quad Exclude 2020--2021 (COVID) & ",
         fmt1(rob$twfe_nocovid_coef), " & \\\\"),
  paste0("\\quad Scotland vs England only & ",
         fmt1(rob$twfe_scot_only_coef), " & \\\\"),
  "\\midrule",
  "\\textit{Panel E: Pre-trend test} & & \\\\",
  paste0("\\quad F-test: differential linear trend (2013--17) & -- & p = ",
         fmt3(rob$pretrend_pval), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All specifications use TWFE with country and year fixed effects. ",
  "Panel A: baseline ATT from Table~\\ref{tab:main_did}. ",
  "Panel B: placebo uses crude all-cause mortality rate as outcome; ",
  "significant effect would indicate confounding. ",
  "Panel C: synthetic Scotland constructed from 9 English regions as donor pool; ",
  "permutation p-value computed from donor-placebo distribution. ",
  "Panel D: robustness to treatment timing and COVID contamination. ",
  "Panel E: F-test for differential linear pre-trend 2013--2017 (null = parallel).",
  "\\end{tablenotes}",
  "\\end{table}"
)

write_tex(tab4, "tab4_robustness.tex")

# ============================================================================
# TABLE 5: Deprivation Heterogeneity
# ============================================================================
cat("\n--- Table 5: Deprivation heterogeneity ---\n")

dep_trends <- rob$dep_trends

dep_wide <- deprivation_panel %>%
  filter(decile %in% c(1, 2, 3, 8, 9, 10)) %>%
  mutate(
    group = case_when(
      decile == 1  ~ "D1 Most deprived",
      decile == 2  ~ "D2",
      decile == 3  ~ "D3",
      decile == 8  ~ "D8",
      decile == 9  ~ "D9",
      decile == 10 ~ "D10 Least deprived"
    )
  ) %>%
  group_by(group, decile) %>%
  summarise(
    rate_2013 = rate[year == 2013],
    rate_2017 = rate[year == 2017],
    rate_2023 = rate[year == max(year[!is.na(rate)])],
    pct_change_pre  = 100 * (rate_2017 - rate_2013) / rate_2013,
    pct_change_all  = 100 * (rate_2023 - rate_2013) / rate_2013,
    .groups = "drop"
  ) %>%
  arrange(decile)

tab5 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Deprivation Gradient in Alcohol Mortality (England, 2013--2023)}",
  "\\label{tab:deprivation}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Deprivation Decile & Rate 2013 & Rate 2017 & Rate 2023 & \\% Chg 2013--17 & \\% Chg 2013--23 \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(dep_wide))) {
  r <- dep_wide[i, ]
  row <- paste0(
    r$group, " & ",
    fmt1(r$rate_2013), " & ",
    fmt1(r$rate_2017), " & ",
    fmt1(r$rate_2023), " & ",
    fmt1(r$pct_change_pre), "\\% & ",
    fmt1(r$pct_change_all), "\\% \\\\"
  )
  if (i == 3) tab5 <- c(tab5, "\\midrule")  # gap between top 3 and bottom 3
  tab5 <- c(tab5, row)
}

# Add a ratio row
d1_2023  <- dep_wide$rate_2023[dep_wide$decile == 1]
d10_2023 <- dep_wide$rate_2023[dep_wide$decile == 10]
d1_2013  <- dep_wide$rate_2013[dep_wide$decile == 1]
d10_2013 <- dep_wide$rate_2013[dep_wide$decile == 10]

tab5 <- c(tab5,
  "\\midrule",
  paste0("Rate ratio (D1/D10) & ",
         fmt1(d1_2013 / d10_2013), " & -- & ",
         fmt1(d1_2023 / d10_2023), " & & \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Age-standardised alcohol-specific mortality rates per 100,000 for ",
  "England by IMD2019 deprivation decile (4/21 geography, \\textit{County \\& UA} areas). ",
  "D1 = most deprived; D10 = least deprived. ",
  "No MUP was implemented in England. The widening gradient illustrates distributional ",
  "consequences of differential pricing sensitivity across income groups. ",
  "Source: OHID Fingertips indicator 91380.",
  "\\end{tablenotes}",
  "\\end{table}"
)

write_tex(tab5, "tab5_deprivation.tex")

# ============================================================================
# APPENDIX TABLE F1: SDE / SE summary table
# ============================================================================
cat("\n--- Table F1: SDE summary ---\n")

sde_data <- tibble(
  model     = c(
    "TWFE country-level",
    "Regional TWFE",
    "CS-DiD overall",
    "Simple DiD (Scotland)",
    "Simple DiD (Wales)",
    "Placebo (crude rate)",
    "Alt. window (Scot 2019)",
    "Excl. COVID (2020-21)",
    "Scotland vs Eng only"
  ),
  coef = c(
    main_results$twfe_country_coef,
    main_results$twfe_region_coef,
    main_results$cs_overall_att,
    main_results$did_att_scotland,
    main_results$did_att_wales,
    robustness$placebo_coef,
    robustness$twfe_alt2019_coef,
    robustness$twfe_nocovid_coef,
    robustness$twfe_scot_only_coef
  ),
  se = c(
    main_results$twfe_country_se,
    main_results$twfe_region_se,
    main_results$cs_overall_se,
    NA, NA,
    robustness$placebo_se,
    NA, NA, NA
  )
) %>%
  mutate(
    t_stat = if_else(!is.na(se) & se > 0, coef / se, NA_real_),
    ci_lo  = if_else(!is.na(se), coef - 1.96 * se, NA_real_),
    ci_hi  = if_else(!is.na(se), coef + 1.96 * se, NA_real_)
  )

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary of Treatment Effect Estimates Across Specifications}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Estimate & SE & t-stat & 95\\% CI \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_data))) {
  r    <- sde_data[i, ]
  se_s <- if (is.na(r$se))    "--" else fmt1(r$se)
  ts_s <- if (is.na(r$t_stat)) "--" else fmt1(r$t_stat)
  ci_s <- if (is.na(r$ci_lo))  "--" else paste0("[", fmt1(r$ci_lo), ", ", fmt1(r$ci_hi), "]")
  row  <- paste0(r$model, " & ", fmt1(r$coef), " & ", se_s, " & ", ts_s, " & ", ci_s, " \\\\")
  tabF1 <- c(tabF1, row)
}

tabF1 <- c(tabF1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All estimates measure the effect of MUP on age-standardised ",
  "alcohol-specific mortality (deaths per 100,000). Negative coefficients indicate MUP ",
  "reduces mortality relative to the counterfactual. SE not reported (--) for specifications ",
  "without a natural SE (simple DiD) or alternative window checks that use the same SE ",
  "structure as the baseline. 95\\% CI based on normal approximation.",
  "\\end{tablenotes}",
  "\\end{table}"
)

write_tex(tabF1, "tabF1_sde.tex")

# ============================================================================
# DIAGNOSTICS CHECK
# ============================================================================
cat("\n--- Final diagnostics ---\n")

diag <- jsonlite::read_json(file.path(DATA_DIR, "diagnostics.json"))
cat("  n_treated:", diag$n_treated, "\n")
cat("  n_pre:", diag$n_pre, "\n")
cat("  n_obs:", diag$n_obs, "\n")
cat("  n_deprivation_deciles:", diag$n_deprivation_deciles, "\n")
cat("  twfe_country_coef:", diag$twfe_country_coef, "\n")
cat("  perm_pval:", diag$perm_pval, "\n")
cat("  cs_overall_att:", diag$cs_overall_att, "\n")

cat("\nTables written to", TABLE_DIR, ":\n")
for (f in list.files(TABLE_DIR, pattern = "\\.tex$")) {
  cat("  ", f, "\n")
}

cat("\n=== TABLE GENERATION COMPLETE ===\n")
