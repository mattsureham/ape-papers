# ==============================================================================
# 03_main_analysis.R — Main DiD analysis
# apep_0535: Gas Tax Hikes and Macroeconomic Beliefs
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
ces <- fread(file.path(data_dir, "ces_analysis.csv"))

cat("Analysis dataset:", nrow(ces), "observations\n")
cat("Treated states:", n_distinct(ces$state_abbr[ces$ever_treated == TRUE]), "\n")
cat("Control states:", n_distinct(ces$state_abbr[ces$ever_treated == FALSE]), "\n")

# ==============================================================================
# 1. TWFE BASELINE (for comparison — not primary specification)
# ==============================================================================

cat("\n=== TWFE REGRESSIONS ===\n")

# Model 1: Basic TWFE
m1_twfe <- feols(pessimism ~ post | state_abbr + year,
                 data = ces, cluster = ~state_abbr)

# Model 2: TWFE with individual controls
m2_twfe <- feols(pessimism ~ post + unemp_rate + income_growth |
                   state_abbr + year,
                 data = ces, cluster = ~state_abbr)

# Model 3: TWFE with demographic controls (where available)
if (all(c("college", "low_income") %in% names(ces))) {
  m3_twfe <- feols(pessimism ~ post + unemp_rate + income_growth +
                     college + low_income | state_abbr + year,
                   data = ces %>% filter(!is.na(college), !is.na(low_income)),
                   cluster = ~state_abbr)
} else {
  m3_twfe <- m2_twfe  # fallback
}

# Model 4: Binary outcome (pessimistic = 1 if economy_retro >= 4)
m4_twfe <- feols(pessimistic ~ post | state_abbr + year,
                 data = ces, cluster = ~state_abbr)

cat("\nTWFE Results:\n")
etable(m1_twfe, m2_twfe, m4_twfe,
       dict = c(post = "Post Gas Tax", pessimism = "Pessimism (1-5)",
                pessimistic = "Pessimistic (0/1)"))

# Save TWFE results
twfe_results <- tibble(
  model = c("TWFE Basic", "TWFE Controls", "TWFE Binary"),
  coef = c(coef(m1_twfe)["post"], coef(m2_twfe)["post"], coef(m4_twfe)["post"]),
  se = c(se(m1_twfe)["post"], se(m2_twfe)["post"], se(m4_twfe)["post"]),
  pval = c(pvalue(m1_twfe)["post"], pvalue(m2_twfe)["post"], pvalue(m4_twfe)["post"]),
  n = c(m1_twfe$nobs, m2_twfe$nobs, m4_twfe$nobs)
)
fwrite(twfe_results, file.path(data_dir, "twfe_results.csv"))

# ==============================================================================
# 2. CALLAWAY-SANT'ANNA STAGGERED DiD (PRIMARY SPECIFICATION)
# ==============================================================================

cat("\n=== CALLAWAY-SANT'ANNA DiD ===\n")

# Prepare data for did package
# Need: panel at state-year level (aggregate CES to state-year means)
ces_state_year <- ces %>%
  group_by(state_abbr, year, first_treat) %>%
  summarize(
    pessimism = mean(pessimism, na.rm = TRUE),
    pessimistic = mean(pessimistic, na.rm = TRUE),
    n_respondents = n(),
    unemp_rate = first(unemp_rate),
    income_growth = first(income_growth),
    .groups = "drop"
  ) %>%
  mutate(state_id = as.integer(factor(state_abbr)))

cat("State-year panel:", nrow(ces_state_year), "observations\n")
cat("  Years:", min(ces_state_year$year), "-", max(ces_state_year$year), "\n")
cat("  States:", n_distinct(ces_state_year$state_id), "\n")

# CS-DiD with never-treated as control
cs_out <- att_gt(
  yname = "pessimism",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(ces_state_year),
  control_group = "nevertreated",
  est_method = "ipw",
  base_period = "universal"
)

cat("\nGroup-time ATTs:\n")
summary(cs_out)

# Aggregate to event study
cs_es <- aggte(cs_out, type = "dynamic", min_e = -7, max_e = 7)
cat("\nEvent Study:\n")
summary(cs_es)

# Save event study coefficients
es_data <- tibble(
  rel_time = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt,
  ci_lower = cs_es$att.egt - 1.96 * cs_es$se.egt,
  ci_upper = cs_es$att.egt + 1.96 * cs_es$se.egt
)
fwrite(es_data, file.path(data_dir, "cs_event_study.csv"))

# Overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nOverall ATT:", round(cs_agg$overall.att, 4),
    "(SE:", round(cs_agg$overall.se, 4), ")\n")

cs_overall <- tibble(
  att = cs_agg$overall.att,
  se = cs_agg$overall.se,
  ci_lower = cs_agg$overall.att - 1.96 * cs_agg$overall.se,
  ci_upper = cs_agg$overall.att + 1.96 * cs_agg$overall.se
)
fwrite(cs_overall, file.path(data_dir, "cs_overall_att.csv"))

# ==============================================================================
# 3. CS-DiD WITH NOT-YET-TREATED (robustness)
# ==============================================================================

cs_nyt <- att_gt(
  yname = "pessimism",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(ces_state_year),
  control_group = "notyettreated",
  est_method = "ipw",
  base_period = "universal"
)

cs_nyt_agg <- aggte(cs_nyt, type = "simple")
cat("\nCS-DiD (not-yet-treated) ATT:", round(cs_nyt_agg$overall.att, 4),
    "(SE:", round(cs_nyt_agg$overall.se, 4), ")\n")

cs_nyt_es <- aggte(cs_nyt, type = "dynamic", min_e = -7, max_e = 7)
nyt_es_data <- tibble(
  rel_time = cs_nyt_es$egt,
  att = cs_nyt_es$att.egt,
  se = cs_nyt_es$se.egt,
  ci_lower = cs_nyt_es$att.egt - 1.96 * cs_nyt_es$se.egt,
  ci_upper = cs_nyt_es$att.egt + 1.96 * cs_nyt_es$se.egt
)
fwrite(nyt_es_data, file.path(data_dir, "cs_event_study_nyt.csv"))

# ==============================================================================
# 4. CS-DiD FOR BINARY OUTCOME (pessimistic indicator)
# ==============================================================================

cs_binary <- att_gt(
  yname = "pessimistic",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(ces_state_year),
  control_group = "nevertreated",
  est_method = "ipw",
  base_period = "universal"
)

cs_binary_agg <- aggte(cs_binary, type = "simple")
cat("\nCS-DiD (binary pessimistic) ATT:", round(cs_binary_agg$overall.att, 4),
    "(SE:", round(cs_binary_agg$overall.se, 4), ")\n")

cs_binary_es <- aggte(cs_binary, type = "dynamic", min_e = -7, max_e = 7)
binary_es_data <- tibble(
  rel_time = cs_binary_es$egt,
  att = cs_binary_es$att.egt,
  se = cs_binary_es$se.egt,
  ci_lower = cs_binary_es$att.egt - 1.96 * cs_binary_es$se.egt,
  ci_upper = cs_binary_es$att.egt + 1.96 * cs_binary_es$se.egt
)
fwrite(binary_es_data, file.path(data_dir, "cs_event_study_binary.csv"))

# ==============================================================================
# 5. DOSE-RESPONSE (interact treatment with gas tax increase magnitude)
# ==============================================================================

cat("\n=== DOSE-RESPONSE ===\n")

# Add dose (increase in cents per gallon) to state-year panel
dose_data <- ces_state_year %>%
  left_join(
    fread(file.path(data_dir, "gas_tax_changes.csv")) %>%
      group_by(state_abbr) %>%
      slice(1) %>%
      ungroup() %>%
      select(state_abbr, increase_cpg),
    by = "state_abbr"
  ) %>%
  mutate(
    post = as.integer(year >= first_treat & first_treat > 0),
    dose = ifelse(post == 1, replace_na(increase_cpg, 0), 0)
  )

# Dose-response regression (TWFE with continuous treatment intensity)
m_dose <- feols(pessimism ~ dose + unemp_rate + income_growth | state_id + year,
                data = dose_data, cluster = ~state_id)

cat("Dose-response (cents/gallon):\n")
summary(m_dose)

dose_results <- tibble(
  variable = names(coef(m_dose)),
  coef = coef(m_dose),
  se = se(m_dose),
  pval = pvalue(m_dose)
)
fwrite(dose_results, file.path(data_dir, "dose_response.csv"))

# ==============================================================================
# 6. FIRST-STAGE: GAS TAX → GAS PRICES (EIA SEDS validation)
# ==============================================================================

cat("\n=== FIRST STAGE ===\n")

eia_file <- file.path(data_dir, "eia_analysis.csv")
if (file.exists(eia_file)) {
  eia <- fread(eia_file)

  # TWFE first stage
  fs_twfe <- feols(gas_price_btu ~ post | state_abbr + year,
                   data = eia, cluster = ~state_abbr)

  cat("First stage (gas tax → gas price, $/MMBtu):\n")
  summary(fs_twfe)

  fs_results <- tibble(
    coef = coef(fs_twfe)["post"],
    se = se(fs_twfe)["post"],
    pval = pvalue(fs_twfe)["post"],
    n = fs_twfe$nobs
  )
  fwrite(fs_results, file.path(data_dir, "first_stage.csv"))
} else {
  cat("EIA data not available — first stage validation skipped.\n")
}

# ==============================================================================
# 7. GOOGLE TRENDS ANALYSIS (secondary outcome)
# ==============================================================================

cat("\n=== GOOGLE TRENDS ANALYSIS ===\n")

gt_file <- file.path(data_dir, "gtrends_analysis.csv")
if (file.exists(gt_file)) {
  gt <- fread(gt_file) %>% filter(!is.na(inflation_search))

  # TWFE
  gt_twfe <- feols(inflation_search ~ post | state_abbr + year,
                   data = gt, cluster = ~state_abbr)
  cat("Google Trends 'inflation' TWFE:\n")
  summary(gt_twfe)

  # CS-DiD
  gt_cs <- att_gt(
    yname = "inflation_search",
    tname = "year",
    idname = "state_id",
    gname = "first_treat",
    data = as.data.frame(gt %>% filter(!is.na(state_id))),
    control_group = "nevertreated",
    est_method = "ipw",
    base_period = "universal"
  )

  gt_cs_agg <- aggte(gt_cs, type = "simple")
  cat("Google Trends CS-DiD ATT:", round(gt_cs_agg$overall.att, 2),
      "(SE:", round(gt_cs_agg$overall.se, 2), ")\n")

  gt_es <- aggte(gt_cs, type = "dynamic", min_e = -5, max_e = 5)
  gt_es_data <- tibble(
    rel_time = gt_es$egt,
    att = gt_es$att.egt,
    se = gt_es$se.egt,
    ci_lower = gt_es$att.egt - 1.96 * gt_es$se.egt,
    ci_upper = gt_es$att.egt + 1.96 * gt_es$se.egt
  )
  fwrite(gt_es_data, file.path(data_dir, "gt_event_study.csv"))

  # Recession searches
  if ("recession_search" %in% names(gt)) {
    gt_recess <- feols(recession_search ~ post | state_abbr + year,
                       data = gt %>% filter(!is.na(recession_search)),
                       cluster = ~state_abbr)
    cat("Google Trends 'recession' TWFE:\n")
    summary(gt_recess)
  }
} else {
  cat("Google Trends data not available.\n")
}

# ==============================================================================
# 8. SAVE ALL RESULTS SUMMARY
# ==============================================================================

results_summary <- tibble(
  specification = c(
    "TWFE Basic", "TWFE Controls", "TWFE Binary",
    "CS-DiD (never-treated)", "CS-DiD (not-yet-treated)", "CS-DiD Binary"
  ),
  outcome = c(rep("Pessimism (1-5)", 2), "Pessimistic (0/1)",
              rep("Pessimism (1-5)", 2), "Pessimistic (0/1)"),
  att = c(
    coef(m1_twfe)["post"], coef(m2_twfe)["post"], coef(m4_twfe)["post"],
    cs_agg$overall.att, cs_nyt_agg$overall.att, cs_binary_agg$overall.att
  ),
  se = c(
    se(m1_twfe)["post"], se(m2_twfe)["post"], se(m4_twfe)["post"],
    cs_agg$overall.se, cs_nyt_agg$overall.se, cs_binary_agg$overall.se
  )
) %>%
  mutate(
    pval = 2 * pnorm(-abs(att / se)),
    ci_lower = att - 1.96 * se,
    ci_upper = att + 1.96 * se,
    stars = case_when(pval < 0.01 ~ "***", pval < 0.05 ~ "**", pval < 0.1 ~ "*", TRUE ~ "")
  )

fwrite(results_summary, file.path(data_dir, "results_summary.csv"))

cat("\n=== RESULTS SUMMARY ===\n")
print(results_summary, n = 10)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
