## 04_robustness.R — Robustness checks
## apep_1134: EEG Clawback Threshold Bunching

source("00_packages.R")

de_episodes <- readRDS("../data/de_episodes.rds")
episode_gen <- readRDS("../data/episode_gen.rds")
all_episodes <- readRDS("../data/all_episodes.rds")

# =============================================================================
# 1. Bunching sensitivity: polynomial order
# =============================================================================
cat("=== Robustness: Polynomial order ===\n")

estimate_bunching_simple <- function(episodes, threshold, bw = 2, poly_order = 5) {
  durations <- episodes$duration_hours
  max_dur <- min(max(durations), threshold + 10)
  dur_counts <- data.frame(duration = 1:max_dur) %>%
    left_join(data.frame(duration = durations) %>% count(duration, name = "count"), by = "duration") %>%
    mutate(count = replace_na(count, 0))
  bunching_low <- max(1, threshold - bw)
  bunching_high <- min(max_dur, threshold + bw)
  cf_data <- dur_counts %>% filter(duration < bunching_low | duration > bunching_high)
  if (nrow(cf_data) < poly_order + 1) return(data.frame(spec = "", b = NA, se = NA))
  cf_fit <- lm(count ~ poly(duration, poly_order, raw = TRUE), data = cf_data)
  dur_counts$cf <- pmax(predict(cf_fit, newdata = dur_counts), 0)
  below <- dur_counts %>% filter(duration >= bunching_low & duration <= threshold)
  excess <- sum(below$count) - sum(below$cf)
  cf_at <- max(dur_counts$cf[dur_counts$duration == threshold], 0.5)
  b <- excess / cf_at

  boot_b <- replicate(500, {
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

  data.frame(b = b, se = sd(boot_b, na.rm = TRUE))
}

regime2 <- de_episodes %>% filter(year >= 2021 & year < 2024)
poly_sensitivity <- bind_rows(lapply(3:7, function(p) {
  res <- estimate_bunching_simple(regime2, threshold = 4, poly_order = p)
  cat(sprintf("  Poly %d: b=%.3f (SE=%.3f)\n", p, res$b, res$se))
  data.frame(poly = p, b = res$b, se = res$se)
}))
saveRDS(poly_sensitivity, "../data/poly_sensitivity.rds")

# =============================================================================
# 2. Bandwidth sensitivity
# =============================================================================
cat("\n=== Robustness: Bandwidth ===\n")
bw_sensitivity <- bind_rows(lapply(1:3, function(bw) {
  res <- estimate_bunching_simple(regime2, threshold = 4, bw = bw)
  cat(sprintf("  BW=%d: b=%.3f (SE=%.3f)\n", bw, res$b, res$se))
  data.frame(bandwidth = bw, b = res$b, se = res$se)
}))
saveRDS(bw_sensitivity, "../data/bw_sensitivity.rds")

# =============================================================================
# 3. Placebo threshold: bunching at non-threshold durations
# =============================================================================
cat("\n=== Robustness: Placebo thresholds ===\n")
bunch_placebo_5h <- estimate_bunching_simple(regime2, threshold = 5)
bunch_placebo_7h <- estimate_bunching_simple(regime2, threshold = 7)
cat(sprintf("  Placebo 5h: b=%.3f (SE=%.3f)\n", bunch_placebo_5h$b, bunch_placebo_5h$se))
cat(sprintf("  Placebo 7h: b=%.3f (SE=%.3f)\n", bunch_placebo_7h$b, bunch_placebo_7h$se))

# =============================================================================
# 4. Donut test
# =============================================================================
cat("\n=== Robustness: Donut ===\n")
regime2_donut <- regime2 %>% filter(duration_hours != 4)
bunch_donut <- estimate_bunching_simple(regime2_donut, threshold = 4)
cat(sprintf("  Donut: b=%.3f (SE=%.3f)\n", bunch_donut$b, bunch_donut$se))

# =============================================================================
# 5. Curtailment regression: alternative windows
# =============================================================================
cat("\n=== Robustness: Alternative near-threshold windows ===\n")

curtail_panel <- episode_gen %>%
  filter(duration_hours >= 3) %>%
  mutate(hours_to_thresh = threshold - episode_hour)

# Window 1: just the threshold hour itself (hours_to_thresh == 0)
curtail_panel$near_0 <- curtail_panel$hours_to_thresh == 0

reg_0 <- feols(renewable_gen_mw ~ near_0 | episode_id + hour,
               data = curtail_panel, cluster = ~date)
cat(sprintf("  Near-threshold (h=0 only): coef=%.1f, SE=%.1f, p=%.3f\n",
            coef(reg_0), se(reg_0), pvalue(reg_0)))

# Window 2: 2 hours before threshold (h in 0:2)
curtail_panel$near_2 <- curtail_panel$hours_to_thresh >= 0 &
                        curtail_panel$hours_to_thresh <= 2

reg_2 <- feols(renewable_gen_mw ~ near_2 | episode_id + hour,
               data = curtail_panel, cluster = ~date)
cat(sprintf("  Near-threshold (h=0:2): coef=%.1f, SE=%.1f, p=%.3f\n",
            coef(reg_2), se(reg_2), pvalue(reg_2)))

# =============================================================================
# 6. Heterogeneity: daytime vs nighttime
# =============================================================================
cat("\n=== Robustness: Daytime vs nighttime ===\n")

# Add daytime indicator to episodes
de_episodes <- de_episodes %>%
  mutate(daytime = hour_of_day_start >= 6 & hour_of_day_start <= 18)

curtail_panel <- curtail_panel %>%
  left_join(de_episodes %>% select(run_id, daytime), by = c("episode_id" = "run_id"))

if ("daytime" %in% names(curtail_panel)) {
  curtail_panel$near_threshold <- curtail_panel$hours_to_thresh >= 0 &
                                   curtail_panel$hours_to_thresh <= 1

  reg_day <- feols(renewable_gen_mw ~ near_threshold | episode_id + hour,
                   data = curtail_panel %>% filter(daytime == TRUE), cluster = ~date)
  reg_night <- feols(renewable_gen_mw ~ near_threshold | episode_id + hour,
                     data = curtail_panel %>% filter(daytime == FALSE), cluster = ~date)

  cat(sprintf("  Daytime: coef=%.1f (SE=%.1f)\n", coef(reg_day), se(reg_day)))
  cat(sprintf("  Nighttime: coef=%.1f (SE=%.1f)\n", coef(reg_night), se(reg_night)))
}

# =============================================================================
# 7. Permutation test: assign placebo "thresholds" to episodes
# =============================================================================
cat("\n=== Robustness: Permutation test (randomized near-threshold) ===\n")

curtail_panel$near_threshold <- curtail_panel$hours_to_thresh >= 0 &
                                 curtail_panel$hours_to_thresh <= 1

# Actual coefficient
actual_coef <- coef(feols(renewable_gen_mw ~ near_threshold | episode_id + hour,
                          data = curtail_panel, cluster = ~date))

# Permute within episodes
set.seed(42)
n_perms <- 500
perm_coefs <- replicate(n_perms, {
  perm_data <- curtail_panel %>%
    group_by(episode_id) %>%
    mutate(near_threshold = sample(near_threshold)) %>%
    ungroup()
  coef(feols(renewable_gen_mw ~ near_threshold | episode_id + hour,
             data = perm_data, cluster = ~date))
})

perm_p <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("  Actual: %.1f | Permutation p-value: %.3f (500 perms)\n", actual_coef, perm_p))

# Save robustness
robustness_summary <- list(
  poly_sensitivity = poly_sensitivity,
  bw_sensitivity = bw_sensitivity,
  donut = bunch_donut,
  placebo_5h = bunch_placebo_5h,
  placebo_7h = bunch_placebo_7h,
  perm_p = perm_p,
  actual_coef = actual_coef
)
saveRDS(robustness_summary, "../data/robustness_summary.rds")

cat("\n=== Robustness complete ===\n")
