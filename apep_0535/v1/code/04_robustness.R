# ==============================================================================
# 04_robustness.R — Robustness checks and heterogeneity analysis
# apep_0535: Gas Tax Hikes and Macroeconomic Beliefs
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
ces <- fread(file.path(data_dir, "ces_analysis.csv"))

# State-year aggregated panel
ces_sy <- ces %>%
  group_by(state_abbr, year, first_treat) %>%
  summarize(
    pessimism = mean(pessimism, na.rm = TRUE),
    pessimistic = mean(pessimistic, na.rm = TRUE),
    n_respondents = n(),
    unemp_rate = first(unemp_rate),
    income_growth = first(income_growth),
    .groups = "drop"
  ) %>%
  mutate(
    state_id = as.integer(factor(state_abbr)),
    post = as.integer(year >= first_treat & first_treat > 0)
  )

# ==============================================================================
# 1. PLACEBO: TEMPORAL — Fake treatment 2 years early
# ==============================================================================

cat("=== TEMPORAL PLACEBO ===\n")

ces_placebo <- ces_sy %>%
  mutate(
    fake_treat = ifelse(first_treat > 0, first_treat - 2, 0),
    fake_post = as.integer(year >= fake_treat & fake_treat > 0 & year < first_treat)
  )

# Only use pre-treatment observations for placebo test
ces_pre <- ces_placebo %>%
  filter(first_treat == 0 | year < first_treat)

placebo_twfe <- feols(pessimism ~ fake_post | state_id + year,
                      data = ces_pre, cluster = ~state_id)

cat("Temporal placebo (fake treatment 2 years early):\n")
summary(placebo_twfe)

placebo_results <- tibble(
  test = "Temporal placebo (t-2)",
  coef = coef(placebo_twfe)["fake_post"],
  se = se(placebo_twfe)["fake_post"],
  pval = pvalue(placebo_twfe)["fake_post"]
)

# ==============================================================================
# 2. BACON DECOMPOSITION
# ==============================================================================

cat("\n=== BACON DECOMPOSITION ===\n")

if (requireNamespace("bacondecomp", quietly = TRUE)) {
  library(bacondecomp)

  bacon_data <- ces_sy %>%
    filter(first_treat > 0 | first_treat == 0) %>%
    mutate(treat = as.integer(year >= first_treat & first_treat > 0))

  bacon_out <- tryCatch({
    bacon(pessimism ~ treat, data = as.data.frame(bacon_data),
          id_var = "state_id", time_var = "year")
  }, error = function(e) {
    cat("Bacon decomposition failed:", e$message, "\n")
    NULL
  })

  if (!is.null(bacon_out)) {
    bacon_summary <- bacon_out %>%
      group_by(type) %>%
      summarize(
        n_pairs = n(),
        avg_estimate = weighted.mean(estimate, weight),
        total_weight = sum(weight),
        .groups = "drop"
      )
    cat("Bacon decomposition:\n")
    print(bacon_summary)
    fwrite(bacon_summary, file.path(data_dir, "bacon_decomposition.csv"))
    fwrite(as.data.frame(bacon_out), file.path(data_dir, "bacon_full.csv"))
  }
} else {
  cat("bacondecomp package not available. Installing...\n")
  install.packages("bacondecomp", repos = "https://cloud.r-project.org")
  cat("Please re-run this script after installation.\n")
}

# ==============================================================================
# 3. PRE-TRENDS TEST (joint F-test on pre-treatment event study coefficients)
# ==============================================================================

cat("\n=== PRE-TRENDS TEST ===\n")

es_data <- fread(file.path(data_dir, "cs_event_study.csv"))
pre_coefs <- es_data %>% filter(rel_time < 0)

# Joint test: are all pre-treatment coefficients jointly zero?
if (nrow(pre_coefs) > 0) {
  chi_sq <- sum((pre_coefs$att / pre_coefs$se)^2)
  df_pre <- nrow(pre_coefs)
  p_pretrend <- 1 - pchisq(chi_sq, df = df_pre)

  cat("Pre-trends joint test:\n")
  cat("  Chi-squared:", round(chi_sq, 2), "with", df_pre, "df\n")
  cat("  p-value:", round(p_pretrend, 4), "\n")
  cat("  Verdict:", ifelse(p_pretrend > 0.10, "PASS (cannot reject parallel trends)",
                           "CONCERN (pre-trends may be violated)"), "\n")

  pretrend_test <- tibble(
    test = "Pre-trends joint F-test",
    chi_sq = chi_sq,
    df = df_pre,
    pval = p_pretrend
  )
  fwrite(pretrend_test, file.path(data_dir, "pretrend_test.csv"))
}

# ==============================================================================
# 4. EXOGENEITY CHECK: Gas tax timing vs. state business cycle
# ==============================================================================

cat("\n=== EXOGENEITY CHECK ===\n")

# Test whether gas tax changes are predicted by lagged economic conditions
exog_data <- ces_sy %>%
  filter(first_treat > 0) %>%
  distinct(state_abbr, first_treat) %>%
  left_join(
    ces_sy %>%
      select(state_abbr, year, unemp_rate, income_growth) %>%
      mutate(year = year + 1) %>%  # lag by 1 year
      rename(lag_unemp = unemp_rate, lag_income_growth = income_growth),
    by = c("state_abbr", "first_treat" = "year")
  )

# Cross-sectional regression: does lagged economy predict treatment timing?
exog_reg <- lm(first_treat ~ lag_unemp + lag_income_growth, data = exog_data)
cat("Exogeneity test (lagged economy → treatment year):\n")
summary(exog_reg)

exog_results <- tidy(exog_reg)
fwrite(exog_results, file.path(data_dir, "exogeneity_test.csv"))

# ==============================================================================
# 5. HETEROGENEITY BY PARTY AFFILIATION
# ==============================================================================

cat("\n=== PARTISAN HETEROGENEITY ===\n")

if ("party" %in% names(ces)) {
  for (p in c("Democrat", "Republican", "Independent")) {
    sub <- ces %>%
      filter(party == p) %>%
      group_by(state_abbr, year, first_treat) %>%
      summarize(pessimism = mean(pessimism, na.rm = TRUE),
                n_respondents = n(), .groups = "drop") %>%
      mutate(state_id = as.integer(factor(state_abbr)))

    if (nrow(sub) > 100 && n_distinct(sub$state_id) >= 30) {
      cs_party <- tryCatch({
        att_gt(yname = "pessimism", tname = "year", idname = "state_id",
               gname = "first_treat", data = as.data.frame(sub),
               control_group = "nevertreated", est_method = "ipw",
               base_period = "universal")
      }, error = function(e) {
        cat("  CS-DiD for", p, "failed:", e$message, "\n")
        NULL
      })

      if (!is.null(cs_party)) {
        cs_party_agg <- aggte(cs_party, type = "simple")
        cat(p, "ATT:", round(cs_party_agg$overall.att, 4),
            "(SE:", round(cs_party_agg$overall.se, 4), ")\n")
      }
    }
  }
}

# Interaction regression approach
if ("party" %in% names(ces)) {
  het_party <- feols(
    pessimism ~ post * i(party, ref = "Democrat") | state_abbr + year,
    data = ces %>% filter(party %in% c("Democrat", "Republican", "Independent")),
    cluster = ~state_abbr
  )
  cat("\nPartisan interaction:\n")
  summary(het_party)

  party_results <- tidy(het_party) %>% as_tibble()
  fwrite(party_results, file.path(data_dir, "heterogeneity_party.csv"))
}

# ==============================================================================
# 6. HETEROGENEITY BY INCOME
# ==============================================================================

cat("\n=== INCOME HETEROGENEITY ===\n")

if ("low_income" %in% names(ces)) {
  het_income <- feols(
    pessimism ~ post * low_income | state_abbr + year,
    data = ces %>% filter(!is.na(low_income)),
    cluster = ~state_abbr
  )
  cat("Income interaction:\n")
  summary(het_income)

  income_results <- tidy(het_income) %>% as_tibble()
  fwrite(income_results, file.path(data_dir, "heterogeneity_income.csv"))
}

# ==============================================================================
# 7. HETEROGENEITY BY AGE (Malmendier-Nagel experience channel)
# ==============================================================================

cat("\n=== AGE HETEROGENEITY ===\n")

if ("experienced_70s" %in% names(ces)) {
  het_age <- feols(
    pessimism ~ post * experienced_70s | state_abbr + year,
    data = ces %>% filter(!is.na(experienced_70s)),
    cluster = ~state_abbr
  )
  cat("Age/experience interaction:\n")
  summary(het_age)

  age_results <- tidy(het_age) %>% as_tibble()
  fwrite(age_results, file.path(data_dir, "heterogeneity_age.csv"))
}

# Age group event studies
if ("age_group" %in% names(ces)) {
  for (ag in c("18-29", "30-44", "45-59", "60+")) {
    sub <- ces %>%
      filter(age_group == ag) %>%
      group_by(state_abbr, year, first_treat) %>%
      summarize(pessimism = mean(pessimism, na.rm = TRUE),
                n_respondents = n(), .groups = "drop") %>%
      mutate(state_id = as.integer(factor(state_abbr)))

    cs_age <- tryCatch({
      out <- att_gt(yname = "pessimism", tname = "year", idname = "state_id",
                    gname = "first_treat", data = as.data.frame(sub),
                    control_group = "nevertreated", est_method = "ipw",
                    base_period = "universal")
      agg <- aggte(out, type = "simple")
      cat("Age", ag, "ATT:", round(agg$overall.att, 4),
          "(SE:", round(agg$overall.se, 4), ")\n")
      agg
    }, error = function(e) {
      cat("  CS-DiD for age", ag, "failed:", e$message, "\n")
      NULL
    })
  }
}

# ==============================================================================
# 8. PLACEBO: GOOGLE TRENDS NON-ECONOMIC SEARCH TERMS
# ==============================================================================

cat("\n=== PLACEBO: NON-ECONOMIC SEARCH TERMS ===\n")

gt_file <- file.path(data_dir, "gtrends_analysis.csv")
if (file.exists(gt_file)) {
  gt <- fread(gt_file)

  # Fetch placebo search terms
  state_xwalk <- tibble(state_name = state.name, state_abbr = state.abb) %>%
    add_row(state_name = "District of Columbia", state_abbr = "DC")

  placebo_terms <- c("weather", "sports", "recipes")

  for (term in placebo_terms) {
    cat("  Fetching placebo:", term, "\n")
    placebo_gt_list <- list()
    for (yr in 2010:2024) {
      tryCatch({
        res <- gtrends(keyword = term, geo = "US",
                       time = paste0(yr, "-01-01 ", yr, "-12-31"))
        if (!is.null(res$interest_by_region)) {
          placebo_gt_list[[as.character(yr)]] <- res$interest_by_region %>%
            as_tibble() %>%
            mutate(year = yr, keyword = term)
        }
        Sys.sleep(2)
      }, error = function(e) NULL)
    }

    if (length(placebo_gt_list) > 0) {
      placebo_gt <- bind_rows(placebo_gt_list) %>%
        left_join(state_xwalk, by = c("location" = "state_name")) %>%
        filter(!is.na(state_abbr)) %>%
        mutate(placebo_search = as.numeric(hits)) %>%
        left_join(
          gt %>% distinct(state_abbr, first_treat, state_id),
          by = "state_abbr"
        ) %>%
        mutate(post = as.integer(year >= first_treat & first_treat > 0))

      placebo_reg <- feols(placebo_search ~ post | state_abbr + year,
                           data = placebo_gt, cluster = ~state_abbr)
      cat("  Placebo (", term, ") TWFE coef:", round(coef(placebo_reg)["post"], 3),
          "(SE:", round(se(placebo_reg)["post"], 3), ")\n")
    }
  }
}

# ==============================================================================
# 9. DOSE-RESPONSE BY SIZE OF TAX INCREASE
# ==============================================================================

cat("\n=== DOSE-RESPONSE BINS ===\n")

gas_tax <- fread(file.path(data_dir, "gas_tax_changes.csv"))

# Categorize by size of increase
dose_cats <- gas_tax %>%
  group_by(state_abbr) %>%
  slice(1) %>%
  ungroup() %>%
  mutate(
    dose_cat = case_when(
      increase_cpg <= 5 ~ "Small (≤5cpg)",
      increase_cpg <= 10 ~ "Medium (5-10cpg)",
      increase_cpg > 10 ~ "Large (>10cpg)"
    )
  ) %>%
  select(state_abbr, dose_cat, increase_cpg)

ces_dose <- ces %>%
  left_join(dose_cats, by = "state_abbr") %>%
  mutate(dose_cat = replace_na(dose_cat, "Control"))

het_dose <- feols(
  pessimism ~ i(dose_cat, ref = "Control") * post | state_abbr + year,
  data = ces_dose %>% filter(!is.na(post)),
  cluster = ~state_abbr
)

cat("Dose-response by category:\n")
summary(het_dose)

# ==============================================================================
# SAVE ALL ROBUSTNESS RESULTS
# ==============================================================================

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")

# Combine key robustness results
robustness_summary <- bind_rows(
  placebo_results,
  if (exists("pretrend_test")) tibble(test = "Pre-trends", coef = NA,
                                       se = NA, pval = pretrend_test$pval) else NULL
)
fwrite(robustness_summary, file.path(data_dir, "robustness_summary.csv"))
