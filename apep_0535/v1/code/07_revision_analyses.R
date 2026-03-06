# ==============================================================================
# 07_revision_analyses.R — Stage C Revision: CS-DiD subgroup heterogeneity
# apep_0535: Gas Tax Hikes and Macroeconomic Beliefs
#
# Addresses reviewer concern: TWFE used for heterogeneity despite being
# argued as biased for main results. Replaces with subgroup-specific CS-DiD.
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
ces <- fread(file.path(data_dir, "ces_analysis.csv"))

cat("=== REVISION ANALYSES ===\n")
cat("Loaded:", nrow(ces), "observations\n")

# ==============================================================================
# 1. CS-DiD BY PARTISAN SUBGROUP
# ==============================================================================

cat("\n=== CS-DiD BY PARTY ===\n")

party_cs_results <- list()

if ("party" %in% names(ces)) {
  for (p in c("Democrat", "Republican", "Independent")) {
    sub <- ces %>%
      filter(party == p) %>%
      group_by(state_abbr, year, first_treat) %>%
      summarize(
        pessimism = mean(pessimism, na.rm = TRUE),
        n_respondents = n(),
        .groups = "drop"
      ) %>%
      mutate(state_id = as.integer(factor(state_abbr)))

    cat("  ", p, ":", nrow(sub), "state-years,", n_distinct(sub$state_id), "states\n")

    cs_party <- tryCatch({
      att_gt(
        yname = "pessimism", tname = "year", idname = "state_id",
        gname = "first_treat", data = as.data.frame(sub),
        control_group = "nevertreated", est_method = "ipw",
        base_period = "universal"
      )
    }, error = function(e) {
      cat("    CS-DiD failed for", p, ":", e$message, "\n")
      NULL
    })

    if (!is.null(cs_party)) {
      agg <- aggte(cs_party, type = "simple")
      cat("  ", p, "ATT:", round(agg$overall.att, 4),
          "(SE:", round(agg$overall.se, 4), ")\n")
      party_cs_results[[p]] <- tibble(
        subgroup = p,
        att = agg$overall.att,
        se = agg$overall.se,
        ci_lower = agg$overall.att - 1.96 * agg$overall.se,
        ci_upper = agg$overall.att + 1.96 * agg$overall.se
      )
    }
  }

  party_cs_df <- bind_rows(party_cs_results)
  fwrite(party_cs_df, file.path(data_dir, "cs_heterogeneity_party.csv"))
  cat("\nPartisan CS-DiD results saved.\n")
  print(party_cs_df)
}

# ==============================================================================
# 2. CS-DiD BY INCOME SUBGROUP
# ==============================================================================

cat("\n=== CS-DiD BY INCOME ===\n")

income_cs_results <- list()

if ("low_income" %in% names(ces)) {
  for (inc_val in c(0, 1)) {
    inc_label <- ifelse(inc_val == 1, "Low income", "Higher income")
    sub <- ces %>%
      filter(!is.na(low_income), low_income == inc_val) %>%
      group_by(state_abbr, year, first_treat) %>%
      summarize(
        pessimism = mean(pessimism, na.rm = TRUE),
        n_respondents = n(),
        .groups = "drop"
      ) %>%
      mutate(state_id = as.integer(factor(state_abbr)))

    cat("  ", inc_label, ":", nrow(sub), "state-years\n")

    cs_inc <- tryCatch({
      att_gt(
        yname = "pessimism", tname = "year", idname = "state_id",
        gname = "first_treat", data = as.data.frame(sub),
        control_group = "nevertreated", est_method = "ipw",
        base_period = "universal"
      )
    }, error = function(e) {
      cat("    CS-DiD failed for", inc_label, ":", e$message, "\n")
      NULL
    })

    if (!is.null(cs_inc)) {
      agg <- aggte(cs_inc, type = "simple")
      cat("  ", inc_label, "ATT:", round(agg$overall.att, 4),
          "(SE:", round(agg$overall.se, 4), ")\n")
      income_cs_results[[inc_label]] <- tibble(
        subgroup = inc_label,
        att = agg$overall.att,
        se = agg$overall.se,
        ci_lower = agg$overall.att - 1.96 * agg$overall.se,
        ci_upper = agg$overall.att + 1.96 * agg$overall.se
      )
    }
  }

  income_cs_df <- bind_rows(income_cs_results)
  fwrite(income_cs_df, file.path(data_dir, "cs_heterogeneity_income.csv"))
  cat("\nIncome CS-DiD results saved.\n")
  print(income_cs_df)
}

# ==============================================================================
# 3. CS-DiD BY AGE GROUP (Malmendier-Nagel experience)
# ==============================================================================

cat("\n=== CS-DiD BY AGE GROUP ===\n")

age_cs_results <- list()

if ("age_group" %in% names(ces)) {
  for (ag in c("18-29", "30-44", "45-59", "60+")) {
    sub <- ces %>%
      filter(age_group == ag) %>%
      group_by(state_abbr, year, first_treat) %>%
      summarize(
        pessimism = mean(pessimism, na.rm = TRUE),
        n_respondents = n(),
        .groups = "drop"
      ) %>%
      mutate(state_id = as.integer(factor(state_abbr)))

    cat("  Age", ag, ":", nrow(sub), "state-years\n")

    cs_age <- tryCatch({
      att_gt(
        yname = "pessimism", tname = "year", idname = "state_id",
        gname = "first_treat", data = as.data.frame(sub),
        control_group = "nevertreated", est_method = "ipw",
        base_period = "universal"
      )
    }, error = function(e) {
      cat("    CS-DiD failed for age", ag, ":", e$message, "\n")
      NULL
    })

    if (!is.null(cs_age)) {
      agg <- aggte(cs_age, type = "simple")
      cat("  Age", ag, "ATT:", round(agg$overall.att, 4),
          "(SE:", round(agg$overall.se, 4), ")\n")
      age_cs_results[[ag]] <- tibble(
        subgroup = paste0("Age ", ag),
        att = agg$overall.att,
        se = agg$overall.se,
        ci_lower = agg$overall.att - 1.96 * agg$overall.se,
        ci_upper = agg$overall.att + 1.96 * agg$overall.se
      )
    }
  }

  age_cs_df <- bind_rows(age_cs_results)
  fwrite(age_cs_df, file.path(data_dir, "cs_heterogeneity_age.csv"))
  cat("\nAge CS-DiD results saved.\n")
  print(age_cs_df)
}

# ==============================================================================
# 4. LATE-YEAR RECODING ROBUSTNESS
# ==============================================================================

cat("\n=== LATE-YEAR RECODING ROBUSTNESS ===\n")

gas_tax <- fread(file.path(data_dir, "gas_tax_changes.csv"))

# Identify late-year adopters (effective date after Aug 1)
late_adopters <- gas_tax %>%
  mutate(effective_date = as.Date(effective_date)) %>%
  filter(month(effective_date) >= 8) %>%
  pull(state_abbr)

cat("Late-year adopters (Aug+):", paste(late_adopters, collapse = ", "), "\n")

# Recode: shift late-year effective dates to following year
ces_recoded <- ces %>%
  group_by(state_abbr, year, first_treat) %>%
  summarize(
    pessimism = mean(pessimism, na.rm = TRUE),
    n_respondents = n(),
    .groups = "drop"
  ) %>%
  mutate(
    first_treat_recoded = ifelse(
      state_abbr %in% late_adopters & first_treat > 0,
      first_treat + 1,
      first_treat
    ),
    state_id = as.integer(factor(state_abbr))
  )

cs_recoded <- tryCatch({
  att_gt(
    yname = "pessimism", tname = "year", idname = "state_id",
    gname = "first_treat_recoded", data = as.data.frame(ces_recoded),
    control_group = "nevertreated", est_method = "ipw",
    base_period = "universal"
  )
}, error = function(e) {
  cat("Late-year recoding CS-DiD failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_recoded)) {
  agg_recoded <- aggte(cs_recoded, type = "simple")
  cat("Late-year recoded ATT:", round(agg_recoded$overall.att, 4),
      "(SE:", round(agg_recoded$overall.se, 4), ")\n")

  recoded_results <- tibble(
    test = "Late-year recoded (Aug+ → next year)",
    att = agg_recoded$overall.att,
    se = agg_recoded$overall.se,
    ci_lower = agg_recoded$overall.att - 1.96 * agg_recoded$overall.se,
    ci_upper = agg_recoded$overall.att + 1.96 * agg_recoded$overall.se
  )
  fwrite(recoded_results, file.path(data_dir, "late_year_recoding.csv"))
}

# ==============================================================================
# 5. CELL SIZE DISTRIBUTION
# ==============================================================================

cat("\n=== CELL SIZE DISTRIBUTION ===\n")

cell_sizes <- ces %>%
  group_by(state_abbr, year) %>%
  summarize(n = n(), .groups = "drop")

cat("State-year cell sizes:\n")
cat("  Min:", min(cell_sizes$n), "\n")
cat("  Median:", median(cell_sizes$n), "\n")
cat("  Mean:", round(mean(cell_sizes$n), 0), "\n")
cat("  Max:", max(cell_sizes$n), "\n")
cat("  SD:", round(sd(cell_sizes$n), 0), "\n")

cell_summary <- tibble(
  statistic = c("Min", "P10", "P25", "Median", "P75", "P90", "Max", "Mean", "SD"),
  value = c(
    min(cell_sizes$n),
    quantile(cell_sizes$n, 0.10),
    quantile(cell_sizes$n, 0.25),
    median(cell_sizes$n),
    quantile(cell_sizes$n, 0.75),
    quantile(cell_sizes$n, 0.90),
    max(cell_sizes$n),
    round(mean(cell_sizes$n), 0),
    round(sd(cell_sizes$n), 0)
  )
)
fwrite(cell_summary, file.path(data_dir, "cell_size_distribution.csv"))

cat("\n=== REVISION ANALYSES COMPLETE ===\n")
