## 03_main_analysis.R — Main regression analysis
## APEP-0807: Legislating at Midnight

source("00_packages.R")

df <- readRDS("../data/analysis_data.rds")
sub <- filter(df, substantive == 1)
cat(sprintf("Analysis sample: %d substantive enacted laws\n", nrow(sub)))

# ============================================================
# TABLE 1: Summary Statistics by Calendar Pressure
# ============================================================

cat("\n=== TABLE 1: Summary by Calendar Pressure ===\n")
summary_stats <- sub %>%
  group_by(final_30) %>%
  summarise(
    n = n(),
    mean_actions = mean(n_major_actions),
    mean_delib = mean(deliberation_days),
    pct_roll_call = 100 * mean(has_roll_call),
    pct_conference = 100 * mean(has_conference),
    pct_voice = 100 * mean(voice_only),
    pct_unanimous = 100 * mean(unanimous_passage),
    pct_house_origin = 100 * mean(is_house),
    .groups = "drop"
  )
print(summary_stats)

# ============================================================
# TABLE 2: Main Results — Effect of Calendar Pressure on
#           Deliberative Process
# ============================================================

cat("\n=== TABLE 2: Main Regressions ===\n")

# --- Panel A: Roll-Call Vote ---
# (1) No FE
m1_rc <- feols(has_roll_call ~ final_30, data = sub, vcov = ~congress)

# (2) Congress FE
m2_rc <- feols(has_roll_call ~ final_30 | congress, data = sub, vcov = ~congress)

# (3) Congress FE + bill type
m3_rc <- feols(has_roll_call ~ final_30 + is_house + is_joint_res | congress,
               data = sub, vcov = ~congress)

# (4) Continuous: log(days_remaining + 1) with Congress FE
m4_rc <- feols(has_roll_call ~ log1p(days_remaining) | congress,
               data = sub, vcov = ~congress)

cat("\nPanel A: Roll-Call Vote\n")
etable(m1_rc, m2_rc, m3_rc, m4_rc,
       dict = c("final_30" = "Final 30 Days",
                "log1p(days_remaining)" = "Log(Days Remaining)",
                "is_house" = "House Origin",
                "is_joint_res" = "Joint Resolution"),
       se.below = TRUE)

# --- Panel B: Conference Committee ---
m1_cf <- feols(has_conference ~ final_30, data = sub, vcov = ~congress)
m2_cf <- feols(has_conference ~ final_30 | congress, data = sub, vcov = ~congress)
m3_cf <- feols(has_conference ~ final_30 + is_house + is_joint_res | congress,
               data = sub, vcov = ~congress)
m4_cf <- feols(has_conference ~ log1p(days_remaining) | congress,
               data = sub, vcov = ~congress)

cat("\nPanel B: Conference Committee\n")
etable(m1_cf, m2_cf, m3_cf, m4_cf,
       dict = c("final_30" = "Final 30 Days",
                "log1p(days_remaining)" = "Log(Days Remaining)"),
       se.below = TRUE)

# --- Panel C: Voice-Only Passage ---
m1_vc <- feols(voice_only ~ final_30, data = sub, vcov = ~congress)
m2_vc <- feols(voice_only ~ final_30 | congress, data = sub, vcov = ~congress)
m3_vc <- feols(voice_only ~ final_30 + is_house + is_joint_res | congress,
               data = sub, vcov = ~congress)

cat("\nPanel C: Voice-Only Passage\n")
etable(m1_vc, m2_vc, m3_vc,
       dict = c("final_30" = "Final 30 Days"),
       se.below = TRUE)

# ============================================================
# TABLE 3: Gradient — Varying the Compression Window
# ============================================================

cat("\n=== TABLE 3: Window Gradient ===\n")

windows <- c(7, 14, 30, 60, 90)
gradient_results <- map_dfr(windows, function(w) {
  sub_w <- sub %>% mutate(final_w = as.integer(days_remaining <= w))
  m <- feols(has_roll_call ~ final_w | congress, data = sub_w, vcov = ~congress)
  tibble(
    window = w,
    coef = coef(m)["final_w"],
    se = se(m)["final_w"],
    n_treated = sum(sub_w$final_w),
    n_total = nrow(sub_w)
  )
})
gradient_results <- gradient_results %>%
  mutate(
    ci_lo = coef - 1.96 * se,
    ci_hi = coef + 1.96 * se,
    stars = case_when(
      abs(coef / se) > 2.576 ~ "***",
      abs(coef / se) > 1.96  ~ "**",
      abs(coef / se) > 1.645 ~ "*",
      TRUE ~ ""
    )
  )
print(gradient_results)

# ============================================================
# Store key results for later use
# ============================================================

results <- list(
  main_rollcall = m2_rc,
  main_conference = m2_cf,
  main_voice = m2_vc,
  gradient = gradient_results,
  n_total = nrow(sub),
  n_final30 = sum(sub$final_30),
  n_congress = n_distinct(sub$congress),
  mean_rollcall_final30 = mean(sub$has_roll_call[sub$final_30 == 1]),
  mean_rollcall_earlier = mean(sub$has_roll_call[sub$final_30 == 0]),
  mean_conference_final30 = mean(sub$has_conference[sub$final_30 == 1]),
  mean_conference_earlier = mean(sub$has_conference[sub$final_30 == 0]),
  sd_rollcall = sd(sub$has_roll_call),
  sd_conference = sd(sub$has_conference)
)

saveRDS(results, "../data/main_results.rds")

# --- Write diagnostics.json ---
diag <- list(
  n_treated = sum(sub$final_30),
  n_pre = n_distinct(sub$congress[sub$congress < 116]),  # Pre-modern era
  n_obs = nrow(sub)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\ndiagnostics.json: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\n=== Main analysis complete ===\n")
