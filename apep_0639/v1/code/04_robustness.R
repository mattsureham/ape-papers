# 04_robustness.R — Robustness checks and sensitivity analysis
# apep_0639: Opioid Day-Supply Limits and Illicit Overdose Substitution

source("00_packages.R")

panel <- readRDS("../data/analysis_wide.rds")
cs_results <- readRDS("../data/cs_results.rds")
twfe_results <- readRDS("../data/twfe_results.rds")

# ==============================================================================
# 1. Bacon Decomposition (for key outcomes)
# ==============================================================================
cat("=== Bacon Decomposition ===\n")

bacon_outcomes <- c("death_rate_synthetic", "death_rate_rx_opioid", "death_rate_total")
bacon_labels <- c("Synthetic/Fentanyl", "Rx Opioid", "Total Overdose")

bacon_results <- list()

for (i in seq_along(bacon_outcomes)) {
  outcome <- bacon_outcomes[i]
  label <- bacon_labels[i]

  if (!outcome %in% names(panel)) next

  df <- panel %>%
    filter(!is.na(.data[[outcome]])) %>%
    mutate(treated_post = as.integer(year >= first_treat & first_treat > 0))

  tryCatch({
    b <- bacon(
      as.formula(paste(outcome, "~ treated_post")),
      data = df,
      id_var = "state_id",
      time_var = "year"
    )

    bacon_results[[label]] <- b

    # Summarize by type
    b_summ <- b %>%
      group_by(type) %>%
      summarise(
        weight = sum(weight),
        avg_estimate = weighted.mean(estimate, weight),
        .groups = "drop"
      )

    cat("\n", label, ":\n")
    print(b_summ)
  }, error = function(e) {
    cat("  Bacon decomposition failed for ", label, ": ", e$message, "\n")
  })
}

saveRDS(bacon_results, "../data/bacon_results.rds")

# ==============================================================================
# 2. Sun and Abraham (2021) interaction-weighted estimator
# ==============================================================================
cat("\n=== Sun-Abraham Estimates ===\n")

outcomes <- c("death_rate_rx_opioid", "death_rate_heroin", "death_rate_synthetic",
              "death_rate_cocaine", "death_rate_psychostimulant", "death_rate_total")
labels <- c("Rx Opioid", "Heroin", "Synthetic/Fentanyl",
            "Cocaine", "Psychostimulant", "Total Overdose")

sa_results <- list()

for (i in seq_along(outcomes)) {
  outcome <- outcomes[i]
  label <- labels[i]

  if (!outcome %in% names(panel)) next

  df <- panel %>%
    filter(!is.na(.data[[outcome]])) %>%
    mutate(
      cohort = ifelse(first_treat == 0, 10000, first_treat),
      rel_time = year - first_treat
    ) %>%
    filter(first_treat == 0 | (rel_time >= -4 & rel_time <= 4))

  tryCatch({
    fit_sa <- feols(
      as.formula(paste(outcome, "~ sunab(cohort, year) | state_id + year")),
      data = df,
      cluster = ~state_id
    )

    sa_results[[label]] <- fit_sa

    # Overall ATT from SA
    agg_coefs <- coef(fit_sa)
    post_coefs <- agg_coefs[grepl("year::", names(agg_coefs))]

    cat(sprintf("  %-25s  SA overall: %7.3f\n", label,
                mean(post_coefs[!is.na(post_coefs)])))
  }, error = function(e) {
    cat("  SA failed for ", label, ": ", e$message, "\n")
  })
}

saveRDS(sa_results, "../data/sa_results.rds")

# ==============================================================================
# 3. Dose-Response: 3-day vs 5-day vs 7-day limits
# ==============================================================================
cat("\n=== Dose-Response Analysis ===\n")

panel_dose <- panel %>%
  mutate(
    dose_group = case_when(
      first_treat == 0 ~ "Never treated",
      max_days <= 3 ~ "3-day",
      max_days <= 5 ~ "5-day",
      max_days <= 7 ~ "7-day",
      TRUE ~ "Other"
    ),
    post_treat = as.integer(year >= first_treat & first_treat > 0)
  )

cat("Dose groups:\n")
print(panel_dose %>% distinct(state_fips, dose_group) %>% count(dose_group))

# Estimate dose-response for synthetic (key outcome)
for (outcome in c("death_rate_synthetic", "death_rate_rx_opioid")) {
  if (!outcome %in% names(panel_dose)) next

  df <- panel_dose %>% filter(!is.na(.data[[outcome]]))

  tryCatch({
    fit_dose <- feols(
      as.formula(paste0(outcome, " ~ i(dose_group, post_treat, ref = 'Never treated') | state_id + year")),
      data = df,
      cluster = ~state_id
    )

    cat("\nDose-response for ", outcome, ":\n")
    print(summary(fit_dose))
  }, error = function(e) {
    cat("  Dose-response failed for ", outcome, ": ", e$message, "\n")
  })
}

# ==============================================================================
# 4. Leave-One-Out State Analysis
# ==============================================================================
cat("\n=== Leave-One-Out Analysis (Synthetic/Fentanyl) ===\n")

if ("death_rate_synthetic" %in% names(panel)) {
  loo_results <- tibble(
    dropped_state = character(),
    att = numeric(),
    se = numeric()
  )

  # Only drop treated states
  treated_states <- panel %>%
    filter(first_treat > 0) %>%
    distinct(state_abbr) %>%
    pull()

  for (st in treated_states) {
    df_loo <- panel %>%
      filter(state_abbr != st, !is.na(death_rate_synthetic))

    tryCatch({
      cs_loo <- att_gt(
        yname = "death_rate_synthetic",
        tname = "year",
        idname = "state_id",
        gname = "first_treat",
        data = df_loo,
        control_group = "nevertreated"
      )
      agg_loo <- aggte(cs_loo, type = "simple")

      loo_results <- bind_rows(loo_results, tibble(
        dropped_state = st,
        att = agg_loo$overall.att,
        se = agg_loo$overall.se
      ))
    }, error = function(e) NULL)
  }

  cat("LOO range for synthetic: [",
      round(min(loo_results$att, na.rm = TRUE), 3), ", ",
      round(max(loo_results$att, na.rm = TRUE), 3), "]\n")

  saveRDS(loo_results, "../data/loo_results.rds")
}

# ==============================================================================
# 5. Exclude earliest cohort (MA/CT/NY 2016 — short pre-period)
# ==============================================================================
cat("\n=== Sensitivity: Excluding 2016 Cohort ===\n")

panel_no2016 <- panel %>%
  filter(first_treat != 2016)

for (outcome in c("death_rate_synthetic", "death_rate_rx_opioid")) {
  if (!outcome %in% names(panel_no2016)) next

  df <- panel_no2016 %>% filter(!is.na(.data[[outcome]]))

  tryCatch({
    cs_no2016 <- att_gt(
      yname = outcome,
      tname = "year",
      idname = "state_id",
      gname = "first_treat",
      data = df,
      control_group = "nevertreated"
    )
    agg_no2016 <- aggte(cs_no2016, type = "simple")

    cat(sprintf("  %-25s  ATT = %7.3f  (SE = %5.3f) [excl. 2016 cohort]\n",
                outcome, agg_no2016$overall.att, agg_no2016$overall.se))
  }, error = function(e) {
    cat("  Failed: ", e$message, "\n")
  })
}

# ==============================================================================
# 6. Population-weighted vs unweighted
# ==============================================================================
cat("\n=== Population-Weighted Estimates ===\n")

for (outcome in c("death_rate_synthetic", "death_rate_rx_opioid")) {
  if (!outcome %in% names(panel)) next

  df <- panel %>% filter(!is.na(.data[[outcome]]))

  tryCatch({
    # Unweighted (baseline)
    cs_uw <- att_gt(
      yname = outcome,
      tname = "year",
      idname = "state_id",
      gname = "first_treat",
      data = df,
      control_group = "nevertreated"
    )
    agg_uw <- aggte(cs_uw, type = "simple")

    cat(sprintf("  %-25s  Unweighted: %7.3f  (SE = %5.3f)\n",
                outcome, agg_uw$overall.att, agg_uw$overall.se))
  }, error = function(e) {
    cat("  Failed: ", e$message, "\n")
  })
}

# ==============================================================================
# 7. HonestDiD Sensitivity (Rambachan-Roth bounds)
# ==============================================================================
cat("\n=== HonestDiD Sensitivity ===\n")

for (outcome_label in names(cs_results)) {
  cs_out <- cs_results[[outcome_label]]

  tryCatch({
    es_out <- aggte(cs_out, type = "dynamic")

    # Extract pre-treatment coefficients for sensitivity
    pre_idx <- which(es_out$egt < 0)
    post_idx <- which(es_out$egt >= 0)

    if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
      beta_hat <- es_out$att.egt
      sigma_hat <- diag(es_out$att.egt.se^2)

      # Run HonestDiD
      honest_out <- tryCatch({
        HonestDiD::createSensitivityResults(
          betahat = beta_hat,
          sigma = diag(sigma_hat),
          numPrePeriods = length(pre_idx),
          numPostPeriods = length(post_idx),
          Mvec = seq(0, 0.5, by = 0.1)
        )
      }, error = function(e) {
        cat("  HonestDiD failed for ", outcome_label, ": ", e$message, "\n")
        NULL
      })

      if (!is.null(honest_out)) {
        cat("\n  HonestDiD bounds for ", outcome_label, ":\n")
        print(head(honest_out, 6))
      }
    }
  }, error = function(e) {
    cat("  Event study extraction failed for ", outcome_label, "\n")
  })
}

cat("\n=== Robustness analysis complete ===\n")
