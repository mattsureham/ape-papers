## 03_main_analysis.R — Bunching estimation and within-episode curtailment analysis
## apep_1134: EEG Clawback Threshold Bunching

source("00_packages.R")

# =============================================================================
# Load data
# =============================================================================
de_episodes <- readRDS("../data/de_episodes.rds")
all_episodes <- readRDS("../data/all_episodes.rds")
episode_gen <- readRDS("../data/episode_gen.rds")

cat(sprintf("DE episodes: %d | Episode-hours: %d\n", nrow(de_episodes), nrow(episode_gen)))

# =============================================================================
# 1. BUNCHING ANALYSIS — Episode duration distribution
# =============================================================================
cat("\n=== BUNCHING ANALYSIS ===\n")

estimate_bunching <- function(episodes, threshold, bw = 2, poly_order = 5, n_boot = 500) {
  durations <- episodes$duration_hours
  max_dur <- min(max(durations), threshold + 10)

  dur_counts <- data.frame(duration = 1:max_dur) %>%
    left_join(
      data.frame(duration = durations) %>% count(duration, name = "count"),
      by = "duration"
    ) %>%
    mutate(count = replace_na(count, 0))

  bunching_low <- max(1, threshold - bw)
  bunching_high <- min(max_dur, threshold + bw)

  cf_data <- dur_counts %>%
    filter(duration < bunching_low | duration > bunching_high)

  if (nrow(cf_data) < poly_order + 1) {
    return(list(bunching_b = NA, se = NA, excess_below = NA,
                missing_above = NA, dur_counts = dur_counts, threshold = threshold))
  }

  cf_fit <- lm(count ~ poly(duration, poly_order, raw = TRUE), data = cf_data)
  dur_counts$cf_count <- pmax(predict(cf_fit, newdata = dur_counts), 0)

  # Excess mass at and just below threshold
  below <- dur_counts %>% filter(duration >= bunching_low & duration < threshold)
  at_threshold <- dur_counts %>% filter(duration == threshold)
  above <- dur_counts %>% filter(duration > threshold & duration <= bunching_high)

  excess_below <- sum(below$count) - sum(below$cf_count)
  excess_at <- sum(at_threshold$count) - sum(at_threshold$cf_count)
  missing_above <- sum(above$cf_count) - sum(above$count)

  # Normalized bunching: excess mass relative to counterfactual height at threshold
  cf_at_threshold <- max(at_threshold$cf_count, 0.5)
  bunching_b <- (excess_below + excess_at) / cf_at_threshold

  # Bootstrap SE
  boot_b <- replicate(n_boot, {
    bd <- sample(durations, replace = TRUE)
    bc <- data.frame(duration = 1:max_dur) %>%
      left_join(data.frame(duration = bd) %>% count(duration, name = "count"), by = "duration") %>%
      mutate(count = replace_na(count, 0))
    bcf <- bc %>% filter(duration < bunching_low | duration > bunching_high)
    if (nrow(bcf) < poly_order + 1) return(NA)
    bfit <- lm(count ~ poly(duration, poly_order, raw = TRUE), data = bcf)
    bc$cf <- pmax(predict(bfit, newdata = bc), 0)
    bb <- bc %>% filter(duration >= bunching_low & duration <= threshold)
    bex <- sum(bb$count) - sum(bb$cf)
    bcf_at <- max(bc$cf[bc$duration == threshold], 0.5)
    bex / bcf_at
  })
  se <- sd(boot_b, na.rm = TRUE)

  cat(sprintf("  Threshold=%dh: b=%.3f (SE=%.3f), excess=%.1f, missing_above=%.1f, n=%d\n",
              threshold, bunching_b, se, excess_below + excess_at, missing_above, nrow(episodes)))

  list(bunching_b = bunching_b, se = se,
       excess_below = excess_below + excess_at, missing_above = missing_above,
       dur_counts = dur_counts, threshold = threshold)
}

# By regime
regime1 <- de_episodes %>% filter(year < 2021)
regime2 <- de_episodes %>% filter(year >= 2021 & year < 2024)
regime3 <- de_episodes %>% filter(year >= 2024)

bunch_6h <- estimate_bunching(regime1, threshold = 6)
bunch_4h <- estimate_bunching(regime2, threshold = 4)
bunch_3h <- estimate_bunching(regime3, threshold = 3)

# Pooled: test bunching at the ACTIVE threshold for each episode's regime
# Simple share test: fraction of episodes ending just below threshold
for (regime_name in c("Pre-2021", "2021-2023", "2024")) {
  if (regime_name == "Pre-2021") { ep <- regime1; th <- 6 }
  else if (regime_name == "2021-2023") { ep <- regime2; th <- 4 }
  else { ep <- regime3; th <- 3 }

  just_below <- sum(ep$duration_hours == (th - 1))
  at_or_above <- sum(ep$duration_hours >= th)
  total <- nrow(ep)
  cat(sprintf("  %s: %d/%d (%.1f%%) end at duration=%d (just below threshold=%d)\n",
              regime_name, just_below, total, just_below/total*100, th-1, th))
}

bunching_results <- data.frame(
  regime = c("Pre-2021 (6h)", "2021-2023 (4h)", "2024 (3h)"),
  threshold = c(6, 4, 3),
  n_episodes = c(nrow(regime1), nrow(regime2), nrow(regime3)),
  bunching_b = c(bunch_6h$bunching_b, bunch_4h$bunching_b, bunch_3h$bunching_b),
  se = c(bunch_6h$se, bunch_4h$se, bunch_3h$se),
  excess_mass = c(bunch_6h$excess_below, bunch_4h$excess_below, bunch_3h$excess_below),
  missing_mass = c(bunch_6h$missing_above, bunch_4h$missing_above, bunch_3h$missing_above)
)
print(bunching_results)
saveRDS(bunching_results, "../data/bunching_results.rds")

# =============================================================================
# 2. WITHIN-EPISODE CURTAILMENT — The Curtailment Cliff
# =============================================================================
cat("\n=== WITHIN-EPISODE CURTAILMENT ANALYSIS ===\n")

# Key test: does renewable generation drop as episodes approach the clawback threshold?
# Measure: generation in hour h relative to hour 1, as a function of hours-to-threshold

# Focus on episodes long enough to approach the threshold
curtail_panel <- episode_gen %>%
  filter(duration_hours >= 3) %>%
  mutate(
    hours_to_thresh = threshold - episode_hour,
    regime = case_when(
      year < 2021 ~ "Pre-2021",
      year >= 2021 & year < 2024 ~ "2021-2023",
      TRUE ~ "2024"
    )
  )

# Average generation by hours-to-threshold
curtail_profile <- curtail_panel %>%
  filter(hours_to_thresh >= -3 & hours_to_thresh <= 5) %>%
  group_by(hours_to_thresh) %>%
  summarize(
    mean_renewable_mw = mean(renewable_gen_mw, na.rm = TRUE),
    sd_renewable_mw = sd(renewable_gen_mw, na.rm = TRUE),
    mean_wind_mw = mean(wind_gen_mw, na.rm = TRUE),
    mean_solar_mw = mean(solar_gen_mw, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(se_renewable = sd_renewable_mw / sqrt(n))

cat("Generation by hours to threshold:\n")
print(curtail_profile %>% select(hours_to_thresh, mean_renewable_mw, se_renewable, n))

# Main regression: generation drops as hours_to_thresh approaches 0
# Binary: "near threshold" (0 or 1 hour away) vs "far" (2+ hours away)
curtail_panel <- curtail_panel %>%
  mutate(near_threshold = hours_to_thresh <= 1 & hours_to_thresh >= 0)

# Specification: renewable_gen ~ near_threshold, with episode FE + hour-of-day FE
curtail_reg <- feols(
  renewable_gen_mw ~ near_threshold | episode_id + hour,
  data = curtail_panel,
  cluster = ~date
)
cat("\n--- Curtailment: Renewable generation near threshold ---\n")
summary(curtail_reg)

# Wind-specific
curtail_wind <- feols(
  wind_gen_mw ~ near_threshold | episode_id + hour,
  data = curtail_panel,
  cluster = ~date
)
cat("\n--- Curtailment: Wind near threshold ---\n")
summary(curtail_wind)

# Solar-specific
curtail_solar <- feols(
  solar_gen_mw ~ near_threshold | episode_id + hour,
  data = curtail_panel,
  cluster = ~date
)
cat("\n--- Curtailment: Solar near threshold ---\n")
summary(curtail_solar)

# =============================================================================
# 3. CROSS-REGIME DiD — Curtailment stronger under tighter thresholds?
# =============================================================================
cat("\n=== CROSS-REGIME COMPARISON ===\n")

# Compare curtailment magnitude across regimes
# Test: is the near-threshold generation drop larger under 4h vs 6h regime?
# Use episodes with duration >= 3 from pre-2021 (6h regime) and 2021-2023 (4h regime)

cross_regime <- curtail_panel %>%
  filter(regime %in% c("Pre-2021", "2021-2023")) %>%
  mutate(post_reform = regime == "2021-2023")

cross_did <- feols(
  renewable_gen_mw ~ near_threshold * post_reform | hour + lubridate::month(date),
  data = cross_regime,
  cluster = ~date
)
cat("\n--- Cross-regime DiD: Near-threshold x Post-reform ---\n")
summary(cross_did)

# Wind
cross_did_wind <- feols(
  wind_gen_mw ~ near_threshold * post_reform | hour + lubridate::month(date),
  data = cross_regime,
  cluster = ~date
)
cat("\n--- Cross-regime DiD: Wind ---\n")
summary(cross_did_wind)

# =============================================================================
# 4. Cross-country placebo bunching
# =============================================================================
cat("\n=== CROSS-COUNTRY PLACEBO ===\n")

placebo_bunching <- list()
for (cc in c("FR", "AT", "NL", "ES")) {
  cc_episodes <- all_episodes %>% filter(country == cc)
  if (nrow(cc_episodes) >= 15) {
    pb <- estimate_bunching(cc_episodes, threshold = 4)
    placebo_bunching[[cc]] <- data.frame(
      country = cc,
      bunching_b = pb$bunching_b,
      se = pb$se,
      n_episodes = nrow(cc_episodes)
    )
  }
}

if (length(placebo_bunching) > 0) {
  placebo_df <- bind_rows(
    data.frame(country = "DE", bunching_b = bunch_4h$bunching_b,
               se = bunch_4h$se, n_episodes = nrow(regime2)),
    bind_rows(placebo_bunching)
  )
  cat("\nBunching at 4h threshold — Germany vs placebos:\n")
  print(placebo_df)
  saveRDS(placebo_df, "../data/placebo_bunching.rds")
}

# =============================================================================
# 5. Save results and diagnostics
# =============================================================================
saveRDS(curtail_reg, "../data/curtail_reg.rds")
saveRDS(curtail_wind, "../data/curtail_wind.rds")
saveRDS(curtail_solar, "../data/curtail_solar.rds")
saveRDS(cross_did, "../data/cross_did.rds")
saveRDS(cross_did_wind, "../data/cross_did_wind.rds")
saveRDS(curtail_profile, "../data/curtail_profile.rds")

# Diagnostics for validator
# n_pre: count unique months in pre-reform period (2019-2020 = up to 24 months with episodes)
pre_months <- de_episodes %>%
  filter(year < 2021) %>%
  mutate(ym = paste(year, month, sep = "-")) %>%
  pull(ym) %>%
  n_distinct()

diagnostics <- list(
  n_treated = nrow(de_episodes %>% filter(above_threshold)),
  n_pre = pre_months,
  n_obs = nrow(episode_gen)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== Main analysis complete ===\n")
