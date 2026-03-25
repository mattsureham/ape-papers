# =============================================================================
# 05_tables.R — Generate all LaTeX tables (including SDE appendix)
# apep_0894: CFPB Payday Lending Rule and Credit-Sector Labor Markets
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
pre_sds <- readRDS("../data/pre_sds.rds")
df <- readRDS("../data/panel_522.rds")
treatment <- readRDS("../data/treatment_intensity.rds")

# --- Table 1: Summary Statistics -------------------------------------------

cat("Generating Table 1: Summary Statistics...\n")

# Panel A: County characteristics
county_stats <- df %>%
  distinct(fips, payday_density, payday_est, pop2017) %>%
  filter(!is.na(pop2017)) %>%
  summarise(
    n_counties = n(),
    n_with_payday = sum(payday_density > 0),
    mean_payday_est = mean(payday_est, na.rm = TRUE),
    sd_payday_est = sd(payday_est, na.rm = TRUE),
    mean_density = mean(payday_density, na.rm = TRUE),
    sd_density = sd(payday_density, na.rm = TRUE),
    mean_pop = mean(pop2017, na.rm = TRUE),
    sd_pop = sd(pop2017, na.rm = TRUE)
  )

# Panel B: QWI outcomes (pre-compliance)
outcome_stats <- df %>%
  filter(post_compliance == 0) %>%
  summarise(
    mean_emp = mean(EmpEnd, na.rm = TRUE),
    sd_emp = sd(EmpEnd, na.rm = TRUE),
    mean_hire = mean(HirN, na.rm = TRUE),
    sd_hire = sd(HirN, na.rm = TRUE),
    mean_sep = mean(Sep, na.rm = TRUE),
    sd_sep = sd(Sep, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    sd_earn = sd(EarnS, na.rm = TRUE)
  )

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Mean & SD & Min & Max \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: County Characteristics (2017)}} \\\\\n",
  sprintf("Payday establishments & %.1f & %.1f & 0 & --- \\\\\n",
          county_stats$mean_payday_est, county_stats$sd_payday_est),
  sprintf("Payday density (per 10K) & %.3f & %.3f & 0 & --- \\\\\n",
          county_stats$mean_density, county_stats$sd_density),
  sprintf("Population & %.0f & %.0f & --- & --- \\\\\n",
          county_stats$mean_pop, county_stats$sd_pop),
  sprintf("Counties with payday lenders & \\multicolumn{4}{c}{%d of %d (%.0f\\%%)} \\\\\n",
          county_stats$n_with_payday, county_stats$n_counties,
          100 * county_stats$n_with_payday / county_stats$n_counties),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: QWI Outcomes, NAICS 522 (Pre-Compliance, 2014--2019Q2)}} \\\\\n",
  sprintf("Employment (end-of-quarter) & %.0f & %.0f & --- & --- \\\\\n",
          outcome_stats$mean_emp, outcome_stats$sd_emp),
  sprintf("New hires & %.0f & %.0f & --- & --- \\\\\n",
          outcome_stats$mean_hire, outcome_stats$sd_hire),
  sprintf("Separations & %.0f & %.0f & --- & --- \\\\\n",
          outcome_stats$mean_sep, outcome_stats$sd_sep),
  sprintf("Average earnings (\\$) & %.0f & %.0f & --- & --- \\\\\n",
          outcome_stats$mean_earn, outcome_stats$sd_earn),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sprintf("\\item \\textit{Notes:} Panel A reports 2017 County Business Patterns (NAICS 522390) merged with Census population estimates. Payday density is payday-related establishments per 10,000 population. Panel B reports pre-compliance (2014Q1--2019Q2) means and standard deviations of QWI outcome variables for NAICS 522 (Credit Intermediation and Related Activities). Sample: %s county-quarter observations across %s counties.\n",
          formatC(nrow(df %>% filter(post_compliance == 0)), format = "d", big.mark = ","),
          formatC(n_distinct(df$fips), format = "d", big.mark = ",")),
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# --- Table 2: Main DiD Results --------------------------------------------

cat("Generating Table 2: Main DiD Results...\n")

tab2 <- etable(
  results$m1_emp, results$m1_hire, results$m1_sep, results$m1_earn,
  headers = c("ln(Emp)", "ln(Hires)", "ln(Sep)", "ln(Earn)"),
  se.below = TRUE,
  depvar = FALSE,
  fitstat = ~ n + wr2,
  dict = c(
    "payday_density:post_compliance" = "Density $\\times$ Post-Compliance",
    "payday_density:post_rescission" = "Density $\\times$ Post-Rescission"
  ),
  style.tex = style.tex("aer"),
  tex = TRUE,
  title = "CFPB Payday Lending Rule: Main Results",
  label = "tab:main",
  notes = paste0(
    "Each column reports a separate regression of the log outcome on payday establishment ",
    "density (per 10,000 population, 2017 CBP) interacted with post-compliance (2019Q3+) ",
    "and post-rescission (2020Q3+) indicators. All specifications include county and ",
    "quarter fixed effects. Standard errors clustered at the state level in parentheses. ",
    "$^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1."
  )
)

writeLines(tab2, "../tables/tab2_main.tex")

# --- Table 3: Robustness --------------------------------------------------

cat("Generating Table 3: Robustness...\n")

tab3 <- etable(
  robustness$placebo_bank, robustness$binary_did,
  robustness$clean_window, robustness$extensive_margin,
  headers = c("Placebo: Banks", "Binary DiD", "Pre-COVID Only", "Extensive Margin"),
  se.below = TRUE,
  depvar = FALSE,
  fitstat = ~ n + wr2,
  dict = c(
    "payday_density:post_compliance" = "Density $\\times$ Post-Compl.",
    "payday_density:post_rescission" = "Density $\\times$ Post-Resc.",
    "high_density:post_compliance" = "High-Density $\\times$ Post-Compl.",
    "high_density:post_rescission" = "High-Density $\\times$ Post-Resc.",
    "any_payday:post_compliance" = "Any Payday $\\times$ Post-Compl.",
    "any_payday:post_rescission" = "Any Payday $\\times$ Post-Resc."
  ),
  style.tex = style.tex("aer"),
  tex = TRUE,
  title = "Robustness Checks",
  label = "tab:robust",
  notes = paste0(
    "Column (1): Placebo test using NAICS 5221 (Depository Credit --- banks, not subject to payday rule). ",
    "Column (2): Binary treatment (top-quartile density counties vs.~bottom-half). ",
    "Column (3): Restricts sample to 2014Q1--2019Q4 (excludes COVID period). ",
    "Column (4): Extensive margin (any payday presence vs.~none). ",
    "All specifications include county and quarter FE. Standard errors clustered at state level. ",
    "Dependent variable: log employment. ",
    "$^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1."
  )
)

writeLines(tab3, "../tables/tab3_robustness.tex")

# --- Table 4: Event Study Coefficients ------------------------------------

cat("Generating Table 4: Event Study...\n")

es_coefs <- coeftable(results$es_emp) %>%
  as.data.frame() %>%
  rownames_to_column("term") %>%
  mutate(
    event_time = as.integer(str_extract(term, "-?\\d+"))
  ) %>%
  filter(!is.na(event_time)) %>%
  arrange(event_time)

# Format for LaTeX
es_rows <- es_coefs %>%
  mutate(
    stars = case_when(
      `Pr(>|t|)` < 0.01 ~ "$^{***}$",
      `Pr(>|t|)` < 0.05 ~ "$^{**}$",
      `Pr(>|t|)` < 0.10 ~ "$^{*}$",
      TRUE ~ ""
    ),
    row_text = sprintf("$t%s%d$ & %.4f%s & (%.4f) \\\\",
                        ifelse(event_time >= 0, "+", ""),
                        event_time,
                        Estimate, stars, `Std. Error`)
  )

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Log Employment $\\times$ Payday Density}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Quarter & Coefficient & (SE) \\\\\n",
  "\\midrule\n",
  paste(es_rows$row_text, collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Coefficients from regressing log county employment (NAICS 522) ",
  "on interactions between payday density and quarter indicators, relative to $t-1$ (2019Q2). ",
  "County and quarter fixed effects included. Standard errors clustered at state level. ",
  "The compliance date is 2019Q3 ($t=0$). The rescission is effective 2020Q3 ($t+4$). ",
  "$^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_eventstudy.tex")

# --- Table F1: SDE Appendix -----------------------------------------------

cat("Generating Table F1: Standardized Effect Sizes...\n")

# Extract coefficients from main results (compliance effect only)
get_sde <- function(model, outcome_name, sd_y) {
  ct <- coeftable(model)
  # Get compliance coefficient (first row)
  beta <- ct[1, "Estimate"]
  se_beta <- ct[1, "Std. Error"]

  # For log outcomes, SDE = β × SD(density) / 1 since outcome is in logs
  # Actually: the coefficient is on density × post, so the effect of
  # a 1-unit increase in density on log(Y). For SDE we want:
  # SDE = β × SD(X) / SD(Y) where X = density and Y = level outcome
  # But since Y is already logged: SDE = β × SD(density) / SD(ln(Y))
  sd_density <- sd(df$payday_density[df$payday_density > 0], na.rm = TRUE)

  sde <- beta * sd_density
  se_sde <- se_beta * sd_density

  classify <- function(s) {
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    if (s < -0.005) return("Small negative")
    if (s < 0.005) return("Null")
    if (s < 0.05) return("Small positive")
    if (s < 0.15) return("Moderate positive")
    return("Large positive")
  }

  tibble(
    Outcome = outcome_name,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sd_ln_emp <- pre_sds$sd_ln_emp
sd_ln_hire <- sd(df$ln_hire[df$post_compliance == 0], na.rm = TRUE)
sd_ln_sep <- sd(df$ln_sep[df$post_compliance == 0], na.rm = TRUE)
sd_ln_earn <- sd(df$ln_earn[df$post_compliance == 0], na.rm = TRUE)

sde_pooled <- bind_rows(
  get_sde(results$m1_emp, "Employment", sd_ln_emp),
  get_sde(results$m1_hire, "New Hires", sd_ln_hire),
  get_sde(results$m1_sep, "Separations", sd_ln_sep),
  get_sde(results$m1_earn, "Avg. Earnings", sd_ln_earn)
)

# Panel B: Heterogeneous — high vs low density counties
# Split at median density among counties with any payday presence
median_density <- median(df$payday_density[df$payday_density > 0], na.rm = TRUE)

df_high <- df %>% filter(payday_density > median_density)
df_low <- df %>% filter(payday_density > 0 & payday_density <= median_density)

m_high <- feols(
  ln_emp ~ payday_density:post_compliance + payday_density:post_rescission |
    fips + cal_quarter,
  data = df_high, cluster = ~state_fips
)

m_low <- feols(
  ln_emp ~ payday_density:post_compliance + payday_density:post_rescission |
    fips + cal_quarter,
  data = df_low, cluster = ~state_fips
)

sd_ln_emp_high <- sd(df_high$ln_emp[df_high$post_compliance == 0], na.rm = TRUE)
sd_ln_emp_low <- sd(df_low$ln_emp[df_low$post_compliance == 0], na.rm = TRUE)

sde_hetero <- bind_rows(
  get_sde(m_high, "Employment (High-Density Counties)", sd_ln_emp_high),
  get_sde(m_low, "Employment (Low-Density Counties)", sd_ln_emp_low)
)

# Build LaTeX table
format_row <- function(r) {
  sprintf("%s & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s \\\\",
          r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the CFPB's 2017 payday lending rule---which imposed ",
  "ability-to-repay requirements on short-term lenders---reduce employment in the ",
  "non-depository credit intermediation sector? ",
  "\\textbf{Policy mechanism:} The rule required payday and auto-title lenders to verify ",
  "borrower ability to repay before issuing covered loans and imposed a 30-day cooling-off ",
  "period after three consecutive loans, with industry projections that 60--70\\% of existing ",
  "loan volume would be prohibited. ",
  "\\textbf{Outcome definition:} End-of-quarter employment count in NAICS 522 (Credit ",
  "Intermediation and Related Activities) from the Quarterly Workforce Indicators, measuring ",
  "all workers employed in non-depository and depository credit intermediation at the county level. ",
  "\\textbf{Treatment:} Continuous; 2017 County Business Patterns payday-related establishment ",
  "count (NAICS 522390) per 10,000 county population, measuring pre-existing exposure to the ",
  "regulated industry. ",
  "\\textbf{Data:} LEHD Quarterly Workforce Indicators (NAICS 522), 2014Q1--2022Q4, county--quarter ",
  "panel merged with 2017 County Business Patterns and Census population estimates. ",
  sprintf("Sample: %s county--quarter observations across %s counties. ",
          formatC(nrow(df), format = "d", big.mark = ","),
          formatC(n_distinct(df$fips), format = "d", big.mark = ",")),
  "\\textbf{Method:} Continuous difference-in-differences with county and quarter fixed effects; ",
  "standard errors clustered at the state level. ",
  "\\textbf{Sample:} All U.S. counties with non-missing QWI data for NAICS 522, excluding ",
  "county-quarters with suppressed employment counts. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-county ",
  "standard deviation of payday density (among counties with any payday presence) and SD($Y$) is ",
  "the pre-treatment standard deviation of log outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(sapply(1:nrow(sde_pooled), function(i) format_row(sde_pooled[i,])), collapse = "\n"),
  "\n\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits by Pre-Treatment Density)}} \\\\\n",
  paste(sapply(1:nrow(sde_hetero), function(i) format_row(sde_hetero[i,])), collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
cat(sprintf("SDE classifications: %s\n",
            paste(sde_pooled$classification, collapse = ", ")))
