##############################################################################
# 04_robustness.R — Robustness checks and placebo tests
# APEP-1082: The Lottery Channel
##############################################################################

source("00_packages.R")

data_dir <- "../data"

cy <- read_csv(file.path(data_dir, "country_year_panel.csv"),
               show_col_types = FALSE)

recent_file <- file.path(data_dir, "recent_arrivals_panel.csv")
has_recent <- file.exists(recent_file)
if (has_recent) {
  recent <- read_csv(recent_file, show_col_types = FALSE) %>%
    filter(n_obs >= 20)
}

# ===========================================================================
# R1: Region-matched controls only (Africa for Nigeria, Asia for Bangladesh)
# ===========================================================================

cat("=== R1: Region-matched controls ===\n")

# Africa subsample: Nigeria vs African controls
africa <- cy %>%
  filter(region == "Africa")

m_africa <- feols(pct_college ~ post | country + survey_year,
                  data = africa, weights = ~total_weight,
                  cluster = ~country)
cat("Africa subsample (Nigeria vs African controls):\n")
print(summary(m_africa))

# Asia subsample: Bangladesh/Pakistan vs Asian controls
asia <- cy %>%
  filter(region == "Asia")

m_asia <- feols(pct_college ~ post | country + survey_year,
                data = asia, weights = ~total_weight,
                cluster = ~country)
cat("\nAsia subsample:\n")
print(summary(m_asia))

# ===========================================================================
# R2: Placebo — high school completion (should NOT change with DV loss)
# ===========================================================================
# DV lottery requires high school diploma, so removing DV should not affect
# the HS completion rate of immigrants from other channels

cat("\n=== R2: Placebo outcome — HS completion ===\n")

m_hs <- feols(pct_hs ~ post | country + survey_year,
              data = cy, weights = ~total_weight,
              cluster = ~country)
cat("HS completion (placebo):\n")
print(summary(m_hs))

# ===========================================================================
# R3: Event study — leads and lags
# ===========================================================================

cat("\n=== R3: Event study ===\n")

cy_es <- cy %>%
  filter(treated_country == 1) %>%
  mutate(
    event_time = survey_year - ineligible_from_dv_year
  ) %>%
  bind_rows(
    cy %>%
      filter(treated_country == 0) %>%
      # For controls, assign event_time relative to average treatment year
      mutate(event_time = NA)
  )

# TWFE event study using fixest's i() function
# Need event-time indicators for treated countries
cy_evt <- cy %>%
  mutate(
    event_time = case_when(
      treated_country == 1 ~ survey_year - ineligible_from_dv_year,
      TRUE ~ -99L  # will be absorbed by ref
    )
  )

# Bin at -7 and +7
cy_evt <- cy_evt %>%
  mutate(
    event_time_binned = pmax(-7, pmin(7, event_time)),
    event_time_binned = ifelse(treated_country == 0, -99, event_time_binned)
  )

m_es <- feols(pct_college ~ i(event_time_binned, treated_country, ref = -1) |
                country + survey_year,
              data = cy_evt, weights = ~total_weight,
              cluster = ~country)

cat("Event study coefficients:\n")
print(summary(m_es))

# Save event study data for tables
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$event_time <- as.numeric(gsub(".*::", "", rownames(es_coefs)))
write_csv(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# ===========================================================================
# R4: Dose-response — countries with larger DV shares should show more
# ===========================================================================

cat("\n=== R4: Dose-response (DV intensity) ===\n")

# For treated countries, the "dose" is the pre-treatment DV share
# We can approximate this from the pre-treatment college premium
# (since DV immigrants are positively selected)
# Better: use the pre-treatment immigration volume from the country

# Use pre-treatment average college rate as proxy for DV intensity
pre_college <- cy %>%
  filter(post == 0) %>%
  group_by(country, treated_country) %>%
  summarise(pre_college = weighted.mean(pct_college, w = total_weight, na.rm = TRUE),
            .groups = "drop")

cy_dose <- cy %>%
  left_join(pre_college %>% select(country, pre_college), by = "country") %>%
  mutate(
    # Interaction: treatment effect should be larger for countries where DV was
    # a larger share of total immigration (proxied by college rate)
    dose_post = post * pre_college
  )

m_dose <- feols(pct_college ~ dose_post + post | country + survey_year,
                data = cy_dose, weights = ~total_weight,
                cluster = ~country)
cat("Dose-response:\n")
print(summary(m_dose))

# ===========================================================================
# R5: Leave-one-out — drop each treated country
# ===========================================================================

cat("\n=== R5: Leave-one-out ===\n")

treated_countries <- unique(cy$country[cy$treated_country == 1])
loo_results <- list()

for (tc in treated_countries) {
  cy_loo <- cy %>% filter(country != tc)
  m_loo <- feols(pct_college ~ post | country + survey_year,
                 data = cy_loo, weights = ~total_weight,
                 cluster = ~country)
  loo_results[[tc]] <- data.frame(
    dropped = tc,
    coef = coef(m_loo)["post"],
    se = se(m_loo)["post"]
  )
  cat(sprintf("  Drop %s: coef=%.2f (SE=%.2f)\n", tc, coef(m_loo)["post"], se(m_loo)["post"]))
}

loo_df <- bind_rows(loo_results)
write_csv(loo_df, file.path(data_dir, "leave_one_out.csv"))

# ===========================================================================
# R6: Permutation inference (randomization inference)
# ===========================================================================

cat("\n=== R6: Permutation inference ===\n")

# Permute treatment assignment across countries
set.seed(42)
n_perms <- 1000

# Get the actual coefficient
actual_coef <- coef(feols(pct_college ~ post | country + survey_year,
                          data = cy, weights = ~total_weight))["post"]

perm_coefs <- numeric(n_perms)
countries <- unique(cy$country)
n_treated <- sum(!is.na(unique(cy$ineligible_from_dv_year[cy$treated_country == 1])))

for (p in 1:n_perms) {
  # Randomly assign treatment to n_treated countries
  fake_treated <- sample(countries, n_treated)

  cy_perm <- cy %>%
    mutate(
      perm_treated = as.integer(country %in% fake_treated),
      # Assign random treatment years from actual treatment years
      perm_treat_year = case_when(
        country %in% fake_treated ~ sample(
          unique(cy$ineligible_from_dv_year[cy$treated_country == 1]),
          1),
        TRUE ~ NA_real_
      ),
      perm_post = case_when(
        is.na(perm_treat_year) ~ 0L,
        survey_year >= perm_treat_year ~ 1L,
        TRUE ~ 0L
      )
    )

  m_perm <- tryCatch(
    feols(pct_college ~ perm_post | country + survey_year,
          data = cy_perm, weights = ~total_weight),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    perm_coefs[p] <- coef(m_perm)["perm_post"]
  }
}

perm_coefs <- perm_coefs[perm_coefs != 0]  # drop failures
ri_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))

cat(sprintf("Actual coefficient: %.2f\n", actual_coef))
cat(sprintf("RI p-value (two-sided): %.3f (based on %d permutations)\n",
            ri_pvalue, length(perm_coefs)))

# Save RI results
write_csv(data.frame(
  actual_coef = actual_coef,
  ri_pvalue = ri_pvalue,
  n_perms = length(perm_coefs),
  perm_mean = mean(perm_coefs),
  perm_sd = sd(perm_coefs)
), file.path(data_dir, "ri_results.csv"))

# ===========================================================================
# Save all robustness models
# ===========================================================================

save(m_africa, m_asia, m_hs, m_es, m_dose, loo_df,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n=== Robustness checks complete ===\n")
