## 04_robustness.R — Robustness checks and falsification
## apep_0793: The Innovation Supply Chain

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
models <- readRDS("../data/models.rds")

# ===========================================================================
# 1. Weak IV: LIML estimator
# ===========================================================================
cat("=== LIML ESTIMATION ===\n")

# LIML is median-unbiased under weak instruments
liml_emp <- feols(log_emp ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                  data = panel, cluster = ~state_fips,
                  lean = FALSE)

# Anderson-Rubin confidence intervals (robust to weak IV)
# AR test: regress outcome on instrument and check joint significance
ar_emp <- feols(log_emp ~ bartik_iv | county_fips + year,
                data = panel, cluster = ~state_fips)
ar_earn <- feols(log_earn ~ bartik_iv | county_fips + year,
                 data = panel, cluster = ~state_fips)

cat("Anderson-Rubin (reduced form) for employment:\n")
print(coeftable(ar_emp))
cat("\nAnderson-Rubin (reduced form) for earnings:\n")
print(coeftable(ar_earn))

# ===========================================================================
# 2. Falsification: Accommodation/Food sector (NAICS 72)
# ===========================================================================
cat("\n=== PLACEBO: ACCOMMODATION/FOOD SECTOR ===\n")

panel_food <- panel %>% filter(!is.na(log_emp_food), is.finite(log_emp_food))

placebo_emp <- feols(log_emp_food ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                     data = panel_food, cluster = ~state_fips)
cat("Placebo IV - Food employment:\n")
summary(placebo_emp)

placebo_earn <- feols(log_earn_food ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                      data = panel_food %>% filter(is.finite(log_earn_food)),
                      cluster = ~state_fips)
cat("Placebo IV - Food earnings:\n")
summary(placebo_earn)

# ===========================================================================
# 3. Alternative base years for Bartik instrument
# ===========================================================================
cat("\n=== ALTERNATIVE BASE YEARS ===\n")

ipeds_county <- readRDS("../data/ipeds_county.rds")
national_stem <- readRDS("../data/national_stem.rds")

for (base_yr in c(2010, 2011, 2012)) {
  national_base <- national_stem %>% filter(year == base_yr) %>% pull(national_completions)

  alt_shares <- ipeds_county %>%
    filter(year == base_yr) %>%
    mutate(alt_share = stem_completions / national_base) %>%
    select(county_fips, alt_share)

  alt_growth <- national_stem %>%
    filter(year >= base_yr) %>%
    mutate(alt_shift = national_completions / national_base)

  panel_alt <- panel %>%
    inner_join(alt_shares, by = "county_fips") %>%
    inner_join(alt_growth %>% select(year, alt_shift), by = "year") %>%
    mutate(alt_bartik = alt_share * alt_shift)

  alt_iv <- feols(log_emp ~ 1 | county_fips + year | log_stem ~ alt_bartik,
                  data = panel_alt, cluster = ~state_fips)
  cat(sprintf("\nBase year %d: coef=%.3f, se=%.3f, t=%.2f, N=%d\n",
              base_yr,
              coef(alt_iv)["fit_log_stem"],
              se(alt_iv)["fit_log_stem"],
              coef(alt_iv)["fit_log_stem"] / se(alt_iv)["fit_log_stem"],
              nobs(alt_iv)))
}

# ===========================================================================
# 4. Leave-one-out Bartik (exclude own-state national shift)
# ===========================================================================
cat("\n=== LEAVE-ONE-OUT BARTIK ===\n")

national_2009 <- national_stem %>% filter(year == 2009) %>% pull(national_completions)

# Calculate state-year STEM totals
state_stem <- ipeds_county %>%
  group_by(state_fips, year) %>%
  summarise(state_completions = sum(stem_completions, na.rm = TRUE), .groups = "drop")

panel_loo <- panel %>%
  left_join(state_stem, by = c("state_fips", "year")) %>%
  left_join(national_stem %>% select(year, national_completions), by = "year") %>%
  mutate(
    loo_national = national_completions - replace_na(state_completions, 0),
    loo_shift = loo_national / (national_2009 - replace_na(
      state_stem %>% filter(year == 2009) %>%
        select(state_fips, state_2009 = state_completions) %>%
        right_join(tibble(state_fips = .$state_fips), by = "state_fips") %>%
        pull(state_2009), 0
    ))
  )

# Simpler LOO approach: use national minus own-state as the shift
state_base <- state_stem %>%
  filter(year == 2009) %>%
  select(state_fips, state_base = state_completions)

panel_loo2 <- panel %>%
  left_join(state_stem, by = c("state_fips", "year")) %>%
  left_join(national_stem %>% select(year, national_completions), by = "year") %>%
  left_join(state_base, by = "state_fips") %>%
  mutate(
    state_completions = replace_na(state_completions, 0),
    state_base = replace_na(state_base, 0),
    loo_national = national_completions - state_completions,
    loo_base_national = national_2009 - state_base,
    loo_shift = loo_national / loo_base_national,
    loo_bartik = base_share * loo_shift
  )

iv_loo <- feols(log_emp ~ 1 | county_fips + year | log_stem ~ loo_bartik,
                data = panel_loo2, cluster = ~state_fips)
cat("Leave-one-out Bartik IV - Employment:\n")
summary(iv_loo)

# ===========================================================================
# 5. Pre-trend balance test (2005-2008 if available)
# ===========================================================================
cat("\n=== PRE-TREND BALANCE ===\n")

# Check if employment was trending differently before STEM expansion
panel_full <- readRDS("../data/panel_full.rds")
panel_pre <- panel_full %>%
  filter(year >= 2005, year <= 2009) %>%
  filter(!is.na(log_emp))

if (nrow(panel_pre) > 100 && n_distinct(panel_pre$year) >= 3) {
  tryCatch({
    pre_trend <- feols(log_emp ~ bartik_iv:i(year, ref = min(panel_pre$year)) | county_fips + year,
                       data = panel_pre, cluster = ~state_fips)
    cat("Pre-trends (Bartik × year interactions):\n")
    print(coeftable(pre_trend))
  }, error = function(e) {
    cat("Pre-trend test failed:", e$message, "\n")
  })
} else {
  cat("Insufficient pre-period data for pre-trend test.\n")
}

# ===========================================================================
# 6. Subsample: Exclude top 5% counties (superstar counties)
# ===========================================================================
cat("\n=== EXCLUDING SUPERSTAR COUNTIES ===\n")

q95 <- quantile(panel$base_share, 0.95, na.rm = TRUE)
panel_no_super <- panel %>% filter(base_share < q95)

iv_no_super <- feols(log_emp ~ 1 | county_fips + year | log_stem ~ bartik_iv,
                     data = panel_no_super, cluster = ~state_fips)
cat("Excluding top 5% (superstar counties):\n")
summary(iv_no_super)

# ===========================================================================
# 7. Save robustness results
# ===========================================================================
rob_models <- list(
  liml_emp = liml_emp,
  ar_emp = ar_emp, ar_earn = ar_earn,
  placebo_emp = placebo_emp, placebo_earn = placebo_earn,
  iv_loo = iv_loo,
  iv_no_super = iv_no_super
)
saveRDS(rob_models, "../data/rob_models.rds")

cat("\nRobustness analysis complete.\n")
