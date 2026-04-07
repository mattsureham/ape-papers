## 04_robustness.R — Robustness checks and placebo tests
## apep_1393: Merger-Induced Branch Closures and Racial Mortgage Gaps

source("00_packages.R")


data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Robustness Checks ===\n")

# ============================================================================
# 1. Event Study: Merger Exposure Timing
# ============================================================================
cat("\n--- Event Study ---\n")

# Create event-time relative to first merger exposure above median
panel <- panel %>%
  group_by(county_fips) %>%
  mutate(
    ever_high_exposure = any(merger_exposure > median(panel$merger_exposure, na.rm = TRUE)),
    first_high_year = ifelse(ever_high_exposure,
                             min(year[merger_exposure > median(panel$merger_exposure, na.rm = TRUE)]),
                             NA_real_),
    event_time = year - first_high_year
  ) %>%
  ungroup()

# Event study regression (for treated counties only)
es_panel <- panel %>%
  filter(!is.na(event_time), event_time >= -3, event_time <= 4)

if (nrow(es_panel) > 100) {
  es_panel$event_time_f <- factor(es_panel$event_time)
  # Omit t=-1 as reference
  es_bw <- feols(bw_denial_gap ~ i(event_time_f, ref = "-1") | state_fips + year,
                 data = es_panel, cluster = ~county_fips)
  summary(es_bw)

  es_aw <- feols(aw_denial_gap ~ i(event_time_f, ref = "-1") | state_fips + year,
                 data = es_panel, cluster = ~county_fips)
}

# ============================================================================
# 2. Placebo: Non-merger counties should show no trend
# ============================================================================
cat("\n--- Placebo: Low-exposure counties ---\n")

# Restrict to counties with near-zero merger exposure
placebo_panel <- panel %>% filter(merger_exposure < 0.05)
if (nrow(placebo_panel) > 50) {
  placebo_reg <- feols(bw_denial_gap ~ branch_change_pct | state_fips + year,
                       data = placebo_panel, cluster = ~county_fips)
  cat("Placebo (low exposure) coefficient:", coef(placebo_reg)["branch_change_pct"], "\n")
}

# ============================================================================
# 3. Balance test: pre-merger characteristics
# ============================================================================
cat("\n--- Balance Tests ---\n")

# Test whether high-exposure counties differ on pre-period characteristics
pre_period <- panel %>%
  filter(year <= 2018) %>%
  group_by(county_fips) %>%
  summarise(
    mean_denial_gap = mean(bw_denial_gap, na.rm = TRUE),
    mean_income_w = mean(income_w, na.rm = TRUE),
    mean_income_b = mean(income_b, na.rm = TRUE),
    mean_branches = mean(n_branches, na.rm = TRUE),
    mean_black_share = mean(black_share, na.rm = TRUE),
    max_exposure = max(merger_exposure, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(high_exposure = max_exposure > median(max_exposure, na.rm = TRUE))

balance_vars <- c("mean_denial_gap", "mean_income_w", "mean_income_b",
                  "mean_branches", "mean_black_share")
balance_results <- list()
for (v in balance_vars) {
  tt <- t.test(as.formula(paste(v, "~ high_exposure")), data = pre_period)
  balance_results[[v]] <- tibble(
    variable = v,
    high_mean = tt$estimate[2],
    low_mean = tt$estimate[1],
    diff = tt$estimate[2] - tt$estimate[1],
    p_value = tt$p.value
  )
}
balance_df <- bind_rows(balance_results)
cat("Balance test results:\n")
print(balance_df)

# ============================================================================
# 4. Alternative bandwidths for merger exposure window
# ============================================================================
cat("\n--- Alternative Merger Windows ---\n")

# Recompute with 2-year and 4-year windows
sod <- readRDS(file.path(data_dir, "fdic_sod.rds"))
mergers <- readRDS(file.path(data_dir, "fdic_mergers.rds"))

merger_certs <- mergers %>%
  mutate(merger_year = as.integer(format(eff_date, "%Y"))) %>%
  select(cert = target_cert, merger_year) %>%
  filter(!is.na(cert)) %>%
  distinct(cert, merger_year)

sod_clean <- sod %>%
  filter(!is.na(stcntybr), nchar(stcntybr) >= 4) %>%
  mutate(county_fips = str_pad(stcntybr, 5, pad = "0"))

for (window in c(2, 4)) {
  cat("  Window =", window, "years\n")
  exposure_alt <- list()
  for (yr in sort(unique(panel$year))) {
    recent <- merger_certs %>%
      filter(merger_year > yr - window, merger_year <= yr) %>%
      pull(cert) %>% unique()

    yr_sod <- sod_clean %>% filter(year == yr)
    ce <- yr_sod %>%
      mutate(is_merger = cert %in% recent) %>%
      group_by(county_fips) %>%
      summarise(merger_exposure_alt = sum(is_merger) / n(), .groups = "drop") %>%
      mutate(year = yr)
    exposure_alt[[as.character(yr)]] <- ce
  }
  exposure_alt_df <- bind_rows(exposure_alt)

  panel_alt <- panel %>%
    select(-merger_exposure) %>%
    left_join(exposure_alt_df %>% rename(merger_exposure = merger_exposure_alt),
              by = c("county_fips", "year"))

  if (nrow(panel_alt %>% filter(!is.na(merger_exposure))) > 100) {
    iv_alt <- feols(bw_denial_gap ~ 1 | state_fips + year |
                      branch_change_pct ~ merger_exposure,
                    data = panel_alt, cluster = ~county_fips)
    cat("  IV coef (window=", window, "):", coef(iv_alt), "\n")
  }
}

# ============================================================================
# 5. Heterogeneity: Urban vs Rural, High vs Low minority share
# ============================================================================
cat("\n--- Heterogeneity ---\n")

# By minority share
panel <- panel %>%
  mutate(high_minority = black_share + black_share > median(black_share + black_share, na.rm = TRUE))

het_high <- feols(bw_denial_gap ~ 1 | state_fips + year |
                    branch_change_pct ~ merger_exposure,
                  data = panel %>% filter(high_minority), cluster = ~county_fips)

het_low <- feols(bw_denial_gap ~ 1 | state_fips + year |
                   branch_change_pct ~ merger_exposure,
                 data = panel %>% filter(!high_minority), cluster = ~county_fips)

cat("High minority counties IV:", coef(het_high), "\n")
cat("Low minority counties IV:", coef(het_low), "\n")

# By branch density (proxy for urban/rural)
panel <- panel %>%
  mutate(high_density = n_branches > median(n_branches, na.rm = TRUE))

het_dense <- feols(bw_denial_gap ~ 1 | state_fips + year |
                     branch_change_pct ~ merger_exposure,
                   data = panel %>% filter(high_density), cluster = ~county_fips)

het_sparse <- feols(bw_denial_gap ~ 1 | state_fips + year |
                      branch_change_pct ~ merger_exposure,
                    data = panel %>% filter(!high_density), cluster = ~county_fips)

cat("Dense counties IV:", coef(het_dense), "\n")
cat("Sparse counties IV:", coef(het_sparse), "\n")

# ============================================================================
# 6. Save robustness results
# ============================================================================
rob_results <- list(
  event_study_bw = if (exists("es_bw")) es_bw else NULL,
  event_study_hw = if (exists("es_aw")) es_aw else NULL,
  balance = balance_df,
  het_high_minority = het_high,
  het_low_minority = het_low,
  het_dense = het_dense,
  het_sparse = het_sparse
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
