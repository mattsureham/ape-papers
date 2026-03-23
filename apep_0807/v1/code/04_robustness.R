## 04_robustness.R — Robustness checks and placebos
## APEP-0807: Legislating at Midnight

source("00_packages.R")

df <- readRDS("../data/analysis_data.rds")
sub <- filter(df, substantive == 1)

# ============================================================
# 1. PLACEBO: Mid-Session Cutoff
# ============================================================
# If our effect is driven by session-end pressure, a "final 30 days"
# cutoff applied to the MIDDLE of the session should show no effect.

cat("=== Placebo: Mid-Session Cutoff ===\n")

sub <- sub %>%
  mutate(
    session_midpoint = session_start + (session_end - session_start) / 2,
    days_from_mid = as.integer(session_midpoint - enacted_date),
    # Laws enacted 0-30 days before session midpoint
    placebo_final30 = as.integer(days_from_mid >= 0 & days_from_mid <= 30)
  )

m_placebo <- feols(has_roll_call ~ placebo_final30 | congress,
                   data = sub, vcov = ~congress)
cat("Placebo (mid-session final 30 days) on roll-call:\n")
etable(m_placebo, se.below = TRUE)

# ============================================================
# 2. NAMING BILLS AS PLACEBO
# ============================================================
# Naming bills are trivial — should always pass by voice vote
# regardless of calendar pressure. Effect should be null.

cat("\n=== Placebo: Naming Bills ===\n")
naming <- filter(df, substantive == 0)
m_naming <- feols(has_roll_call ~ final_30 | congress,
                  data = naming, vcov = ~congress)
cat(sprintf("Naming bills sample: %d laws, %d in final 30\n",
            nrow(naming), sum(naming$final_30)))
etable(m_naming, se.below = TRUE)

# ============================================================
# 3. ERA HETEROGENEITY
# ============================================================

cat("\n=== Era Heterogeneity ===\n")

era_results <- sub %>%
  group_by(era) %>%
  group_modify(~ {
    m <- feols(has_roll_call ~ final_30 | congress, data = .x, vcov = "hetero")
    tibble(
      coef = coef(m)["final_30"],
      se = se(m)["final_30"],
      n = nrow(.x),
      n_treated = sum(.x$final_30)
    )
  }) %>%
  ungroup()
print(era_results)

# ============================================================
# 4. BILL TYPE HETEROGENEITY
# ============================================================

cat("\n=== Bill Origin Heterogeneity ===\n")
m_house <- feols(has_roll_call ~ final_30 | congress,
                 data = filter(sub, is_house == 1), vcov = ~congress)
m_senate <- feols(has_roll_call ~ final_30 | congress,
                  data = filter(sub, is_house == 0), vcov = ~congress)
cat("House-origin bills:\n")
etable(m_house, se.below = TRUE)
cat("Senate-origin bills:\n")
etable(m_senate, se.below = TRUE)

# ============================================================
# 5. ALTERNATIVE FUNCTIONAL FORMS
# ============================================================

cat("\n=== Alternative Specifications ===\n")

# Quadratic in days remaining
m_quad <- feols(has_roll_call ~ days_remaining + I(days_remaining^2) | congress,
                data = sub, vcov = ~congress)

# Logit
m_logit <- feglm(has_roll_call ~ final_30 | congress,
                 data = sub, family = binomial, vcov = ~congress)

cat("Quadratic specification:\n")
etable(m_quad, se.below = TRUE)
cat("Logit specification:\n")
etable(m_logit, se.below = TRUE)

# ============================================================
# 6. CONFERENCE COMMITTEE ROBUSTNESS
# ============================================================

cat("\n=== Conference Committee Robustness ===\n")
m_cf_grad <- map_dfr(c(7, 14, 30, 60, 90), function(w) {
  sub_w <- sub %>% mutate(final_w = as.integer(days_remaining <= w))
  m <- feols(has_conference ~ final_w | congress, data = sub_w, vcov = ~congress)
  tibble(
    window = w,
    coef = coef(m)["final_w"],
    se = se(m)["final_w"]
  )
})
print(m_cf_grad)

# ============================================================
# Save robustness results
# ============================================================

robust_results <- list(
  placebo_mid = m_placebo,
  placebo_naming = m_naming,
  era_het = era_results,
  house = m_house,
  senate = m_senate,
  logit = m_logit,
  conference_gradient = m_cf_grad
)
saveRDS(robust_results, "../data/robust_results.rds")

cat("\n=== Robustness checks complete ===\n")
