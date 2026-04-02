# =============================================================================
# 04_robustness.R — Robustness checks for HEERF reduced-form
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/results.rds")
panel <- results$panel

# =============================================================================
# 1. ALTERNATIVE SPECIFICATIONS FOR KEY OUTCOMES
# =============================================================================

# --- 1a. Enrollment: unit + year FE only (no state × year) ---
rob_enroll_simple <- feols(enrollment ~ predicted_heerf_post | unitid + year,
                           data = panel, cluster = ~unitid)

# --- 1b. Enrollment: state-clustered SEs ---
rob_enroll_state <- feols(enrollment ~ predicted_heerf_post | unitid + state_id^year,
                          data = panel, cluster = ~state_id)

# --- 1c. Log enrollment ---
panel_log <- panel %>% mutate(log_enrollment = log(pmax(enrollment, 1)))
rob_log_enroll <- feols(log_enrollment ~ predicted_heerf_post | unitid + state_id^year,
                        data = panel_log, cluster = ~unitid)

# --- 1d. Tuition: unit + year FE only ---
rob_tuition_simple <- feols(in_state_tuition ~ predicted_heerf_post | unitid + year,
                            data = panel, cluster = ~unitid)

# =============================================================================
# 2. HETEROGENEITY
# =============================================================================

# --- 2a. By institution type (4-year vs 2-year) ---
het_enroll_4yr <- feols(enrollment ~ predicted_heerf_post | unitid + state_id^year,
                        data = panel %>% filter(is_4year), cluster = ~unitid)
het_enroll_2yr <- feols(enrollment ~ predicted_heerf_post | unitid + state_id^year,
                        data = panel %>% filter(is_2year), cluster = ~unitid)

het_tuition_4yr <- feols(in_state_tuition ~ predicted_heerf_post | unitid + state_id^year,
                         data = panel %>% filter(is_4year), cluster = ~unitid)
het_tuition_2yr <- feols(in_state_tuition ~ predicted_heerf_post | unitid + state_id^year,
                         data = panel %>% filter(is_2year), cluster = ~unitid)

# --- 2b. By baseline Pell share (high vs low) ---
med_pell <- median(panel$pell_share_2018)
het_enroll_highpell <- feols(enrollment ~ predicted_heerf_post | unitid + state_id^year,
                             data = panel %>% filter(pell_share_2018 > med_pell), cluster = ~unitid)
het_enroll_lowpell <- feols(enrollment ~ predicted_heerf_post | unitid + state_id^year,
                            data = panel %>% filter(pell_share_2018 <= med_pell), cluster = ~unitid)

# =============================================================================
# 3. PLACEBO TESTS
# =============================================================================

# --- 3a. Placebo: pre-period only (2015-2019), fake treatment at 2018 ---
panel_pre <- panel %>% filter(year <= 2019) %>%
  mutate(placebo_post = as.integer(year >= 2018),
         placebo_treat = predicted_heerf_per_student * placebo_post / 1000)

placebo_enroll <- feols(enrollment ~ placebo_treat | unitid + state_id^year,
                        data = panel_pre, cluster = ~unitid)
placebo_tuition <- feols(in_state_tuition ~ placebo_treat | unitid + state_id^year,
                         data = panel_pre, cluster = ~unitid)

cat("=== PLACEBO TESTS (fake treatment at 2018) ===\n")
cat(sprintf("Enrollment: β = %.2f (SE = %.2f), p = %.4f\n",
            coef(placebo_enroll)["placebo_treat"],
            se(placebo_enroll)["placebo_treat"],
            2 * pnorm(-abs(coef(placebo_enroll)["placebo_treat"] / se(placebo_enroll)["placebo_treat"]))))
cat(sprintf("Tuition: β = %.2f (SE = %.2f), p = %.4f\n",
            coef(placebo_tuition)["placebo_treat"],
            se(placebo_tuition)["placebo_treat"],
            2 * pnorm(-abs(coef(placebo_tuition)["placebo_treat"] / se(placebo_tuition)["placebo_treat"]))))

# --- 3b. Leave-one-state-out for enrollment ---
states <- unique(panel$state)
loo_coefs <- numeric(length(states))
names(loo_coefs) <- states
for (s in states) {
  tryCatch({
    fit <- feols(enrollment ~ predicted_heerf_post | unitid + year,
                 data = panel %>% filter(state != s), cluster = ~unitid)
    loo_coefs[s] <- coef(fit)["predicted_heerf_post"]
  }, error = function(e) { loo_coefs[s] <<- NA })
}

full_coef <- coef(results$main$enrollment)["predicted_heerf_post"]
cat(sprintf("\n=== LEAVE-ONE-STATE-OUT (enrollment) ===\n"))
cat(sprintf("Full sample: %.2f\n", full_coef))
cat(sprintf("LOO range: [%.2f, %.2f]\n", min(loo_coefs, na.rm = TRUE), max(loo_coefs, na.rm = TRUE)))
cat(sprintf("LOO mean: %.2f, LOO sd: %.2f\n", mean(loo_coefs, na.rm = TRUE), sd(loo_coefs, na.rm = TRUE)))

# =============================================================================
# 4. SAVE
# =============================================================================

robustness <- list(
  rob_enroll_simple = rob_enroll_simple,
  rob_enroll_state = rob_enroll_state,
  rob_log_enroll = rob_log_enroll,
  rob_tuition_simple = rob_tuition_simple,
  het_enroll_4yr = het_enroll_4yr,
  het_enroll_2yr = het_enroll_2yr,
  het_tuition_4yr = het_tuition_4yr,
  het_tuition_2yr = het_tuition_2yr,
  het_enroll_highpell = het_enroll_highpell,
  het_enroll_lowpell = het_enroll_lowpell,
  placebo_enroll = placebo_enroll,
  placebo_tuition = placebo_tuition,
  loo_coefs = loo_coefs,
  med_pell = med_pell
)

saveRDS(robustness, "../data/robustness.rds")
cat("\nAll robustness results saved.\n")
