## 04_robustness.R — Robustness checks and placebo tests
## apep_0711: Online sports betting and suicide mortality

source("00_packages.R")

cat("=== Robustness Checks ===\n")

## --- 1. Load data and results ---
results <- readRDS("../data/main_results.rds")
panel <- results$panel

## --- 2. Leave-one-out (each treated state) ---
cat("\n--- Leave-One-Out ---\n")
treated_states <- unique(panel$state_abbr[panel$ever_treated == 1])
loo_results <- list()

for (st in treated_states) {
  loo_data <- panel %>% filter(state_abbr != st)
  loo_fit <- feols(suicide_median ~ treated_post | state_id + period,
                   data = loo_data, cluster = ~state_id)
  loo_results[[st]] <- tibble(
    excluded_state = st,
    coef = coef(loo_fit)["treated_post"],
    se = se(loo_fit)["treated_post"],
    pval = pvalue(loo_fit)["treated_post"]
  )
}

loo_df <- bind_rows(loo_results)
cat("Leave-one-out results:\n")
print(loo_df)

## --- 3. Pre-COVID restriction (treatment before March 2020) ---
cat("\n--- Pre-COVID Restriction ---\n")
pre_covid_treated <- c("NJ", "WV", "PA", "IN")
pre_covid_data <- panel %>%
  filter(year < 2020 | (year == 2020 & week < 11)) %>%  # Before March 2020
  filter(state_abbr %in% c(pre_covid_treated,
                           unique(panel$state_abbr[panel$ever_treated == 0])))

if (nrow(pre_covid_data) > 100 && sum(pre_covid_data$treated_post) > 0) {
  pre_covid_fit <- feols(suicide_median ~ treated_post | state_id + period,
                         data = pre_covid_data, cluster = ~state_id)
  cat("Pre-COVID TWFE:\n")
  print(summary(pre_covid_fit))
} else {
  cat("Insufficient pre-COVID treated observations.\n")
  pre_covid_fit <- NULL
}

## --- 4. State-month aggregation ---
cat("\n--- State-Month Aggregation ---\n")
monthly <- panel %>%
  mutate(month = floor((week - 1) / 4.33) + 1) %>%
  group_by(state_id, state_abbr, year, month, ever_treated, treated_post) %>%
  summarise(
    suicide_median = mean(suicide_median, na.rm = TRUE),
    n_weeks = n(),
    .groups = "drop"
  ) %>%
  mutate(period_m = (year - min(year)) * 12 + month)

monthly_fit <- feols(suicide_median ~ treated_post | state_id + period_m,
                     data = monthly, cluster = ~state_id)
cat("Monthly aggregation TWFE:\n")
print(summary(monthly_fit))

## --- 5. Placebo: Transport/Accident deaths ---
cat("\n--- Placebo: Transport Deaths ---\n")
if (file.exists("../data/cdc_transport_raw.csv")) {
  transport <- read_csv("../data/cdc_transport_raw.csv", show_col_types = FALSE)

  ## Clean transport data (same structure as suicide)
  transport <- transport %>% rename_with(tolower) %>% rename_with(~ gsub("\\.", "_", .x))

  state_col <- names(transport)[grepl("^state$|^jurisdiction|^geography", names(transport), ignore.case = TRUE)]
  median_col <- names(transport)[grepl("median|mean|estimate", names(transport), ignore.case = TRUE)]
  time_cols <- names(transport)[grepl("week|year|date|time|period", names(transport), ignore.case = TRUE)]

  state_xwalk <- tibble(
    state_abbr = c(state.abb, "DC"),
    state_name_full = c(state.name, "District of Columbia")
  )

  transport_panel <- transport %>%
    mutate(
      state_name = .data[[state_col[1]]],
      year = as.integer(.data[[time_cols[grepl("year", time_cols, ignore.case = TRUE)][1]]]),
      week = as.integer(.data[[time_cols[grepl("week", time_cols, ignore.case = TRUE)][1]]]),
      transport_median = as.numeric(.data[[median_col[1]]])
    ) %>%
    left_join(state_xwalk, by = c("state_name" = "state_name_full")) %>%
    mutate(state_abbr = ifelse(is.na(state_abbr) & state_name %in% c(state.abb, "DC"),
                               state_name, state_abbr)) %>%
    filter(!is.na(transport_median), !is.na(state_abbr)) %>%
    left_join(
      distinct(panel, state_abbr, state_id, ever_treated, legal_year, legal_week),
      by = "state_abbr"
    ) %>%
    mutate(
      time_idx = year * 100 + week,
      legal_time_idx = legal_year * 100 + legal_week,
      treated_post = ifelse(!is.na(legal_time_idx) & time_idx >= legal_time_idx, 1, 0),
      period = (year - min(year)) * 52 + week
    )

  placebo_fit <- feols(transport_median ~ treated_post | state_id + period,
                       data = transport_panel, cluster = ~state_id)
  cat("Placebo (transport deaths) TWFE:\n")
  print(summary(placebo_fit))
} else {
  cat("No transport death data available for placebo test.\n")
  placebo_fit <- NULL
}

## --- 6. Wild cluster bootstrap for main spec ---
cat("\n--- Wild Cluster Bootstrap ---\n")
## With 14 treated clusters, standard cluster-robust SEs may be unreliable
## Use fixest's built-in bootstrap

main_fit <- feols(suicide_median ~ treated_post | state_id + period,
                  data = panel, cluster = ~state_id)

## Wild bootstrap p-value using fixest
## Note: fixest doesn't have built-in wild bootstrap, but we can compute
## randomization inference style by permuting treatment assignment
set.seed(42)
n_perms <- 999
perm_coefs <- numeric(n_perms)
actual_coef <- coef(main_fit)["treated_post"]

for (i in 1:n_perms) {
  ## Permute which states are "treated" (reassign treatment)
  perm_states <- sample(unique(panel$state_abbr),
                        size = sum(panel$ever_treated == 1 & !duplicated(panel$state_abbr)))
  perm_data <- panel %>%
    mutate(perm_treated = ifelse(state_abbr %in% perm_states & treated_post == 1, 1, 0))

  perm_fit <- tryCatch(
    feols(suicide_median ~ perm_treated | state_id + period,
          data = perm_data, cluster = ~state_id),
    error = function(e) NULL
  )

  if (!is.null(perm_fit)) {
    perm_coefs[i] <- coef(perm_fit)["perm_treated"]
  } else {
    perm_coefs[i] <- NA
  }
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))
cat("Randomization Inference p-value:", ri_pvalue, "\n")
cat("Actual coefficient:", actual_coef, "\n")
cat("Permutation distribution: mean=", mean(perm_coefs), "sd=", sd(perm_coefs), "\n")

## --- 7. Save robustness results ---
robust_results <- list(
  loo = loo_df,
  pre_covid = pre_covid_fit,
  monthly = monthly_fit,
  placebo = if (exists("placebo_fit")) placebo_fit else NULL,
  ri_pvalue = ri_pvalue,
  perm_coefs = perm_coefs,
  actual_coef = actual_coef
)
saveRDS(robust_results, "../data/robustness_results.rds")

cat("\n=== Robustness Checks Complete ===\n")
