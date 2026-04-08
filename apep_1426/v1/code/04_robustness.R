# 04_robustness.R — Robustness checks for apep_1426
# TV News Amplification and Workplace Safety Deterrence

source("./code/00_packages.R")

DATA_DIR <- "./data"

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, week := as.Date(week)]

cat("=== Robustness Checks ===\n\n")

# ============================================================
# 1. Alternative Event Windows
# ============================================================
cat("--- R1: Alternative event windows ---\n")

# Narrow window: event week only (no surrounding weeks)
olympics_exact <- as.Date(c("2016-08-08", "2018-02-12", "2021-07-26", "2022-02-07"))
superbowl_exact <- as.Date(c(
  "2015-02-02", "2016-02-08", "2017-02-06", "2018-02-05",
  "2019-02-04", "2020-02-03", "2021-02-08", "2022-02-14", "2023-02-13"
))

panel[, event_exact := 0L]
for (d in c(olympics_exact, superbowl_exact)) {
  panel[abs(as.integer(week - d)) <= 7, event_exact := 1L]
}

rob1 <- feols(total_safety_coverage ~ event_exact | year + quarter, data = panel)
cat("Exact event week only:\n")
summary(rob1)

# Wide window: 3 weeks around events
panel[, event_wide := 0L]
for (d in c(olympics_exact, superbowl_exact)) {
  panel[abs(as.integer(week - d)) <= 21, event_wide := 1L]
}

rob1b <- feols(total_safety_coverage ~ event_wide | year + quarter, data = panel)
cat("\nWide event window (±3 weeks):\n")
summary(rob1b)

# ============================================================
# 2. Olympics-Only Instrument (Cleanest)
# ============================================================
cat("\n--- R2: Olympics-only instrument ---\n")

rob2 <- feols(total_safety_coverage ~ olympics_week | year + quarter, data = panel)
cat("Olympics only:\n")
summary(rob2)

# ============================================================
# 3. Placebo: Random Event Dates
# ============================================================
cat("\n--- R3: Placebo with random event dates ---\n")

set.seed(42)
n_events <- sum(panel$prescheduled_event)
placebo_results <- numeric(500)

for (i in 1:500) {
  panel[, placebo_event := 0L]
  placebo_weeks <- sample(nrow(panel), n_events)
  panel[placebo_weeks, placebo_event := 1L]

  plac <- feols(total_safety_coverage ~ placebo_event | year + quarter,
                data = panel)
  placebo_results[i] <- coef(plac)[["placebo_event"]]
}

actual_coef <- coef(feols(total_safety_coverage ~ prescheduled_event |
                            year + quarter, data = panel))[["prescheduled_event"]]

p_value_ri <- mean(abs(placebo_results) >= abs(actual_coef))
cat(sprintf("Randomization inference p-value: %.4f\n", p_value_ri))
cat(sprintf("Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("Mean placebo: %.4f, SD: %.4f\n",
            mean(placebo_results), sd(placebo_results)))

# ============================================================
# 4. Time Trends
# ============================================================
cat("\n--- R4: Controlling for time trends ---\n")

panel[, time_index := as.integer(week - min(week))]

rob4a <- feols(total_safety_coverage ~ prescheduled_event + time_index |
                 year, data = panel)
cat("Linear time trend:\n")
summary(rob4a)

rob4b <- feols(total_safety_coverage ~ prescheduled_event +
                 poly(time_index, 2) | year, data = panel)
cat("\nQuadratic time trend:\n")
summary(rob4b)

# Month FE instead of quarter
panel[, month_factor := factor(month)]
rob4c <- feols(total_safety_coverage ~ prescheduled_event |
                 year + month_factor, data = panel)
cat("\nMonth fixed effects:\n")
summary(rob4c)

# ============================================================
# 5. Dropping Individual Events
# ============================================================
cat("\n--- R5: Leave-one-out (dropping individual events) ---\n")

events_list <- list(
  rio2016 = c("2016-07-29", "2016-08-28"),
  pyeongchang2018 = c("2018-02-02", "2018-03-04"),
  tokyo2021 = c("2021-07-16", "2021-08-15"),
  beijing2022 = c("2022-01-28", "2022-02-27")
)

for (evt_name in names(events_list)) {
  dates <- as.Date(events_list[[evt_name]])
  panel_loo <- panel[!(week >= dates[1] & week <= dates[2])]

  loo <- feols(total_safety_coverage ~ prescheduled_event |
                 year + quarter, data = panel_loo)
  cat(sprintf("  Drop %s: coef=%.4f, se=%.4f, t=%.2f\n",
              evt_name, coef(loo)[["prescheduled_event"]],
              sqrt(vcov(loo)["prescheduled_event", "prescheduled_event"]),
              coef(loo)[["prescheduled_event"]] /
              sqrt(vcov(loo)["prescheduled_event", "prescheduled_event"])))
}

# ============================================================
# 6. Save Robustness Results
# ============================================================
cat("\n=== Saving robustness results ===\n")

robustness <- list(
  exact_window_coef = coef(rob1)[["event_exact"]],
  wide_window_coef = coef(rob1b)[["event_wide"]],
  olympics_only_coef = coef(rob2)[["olympics_week"]],
  ri_p_value = p_value_ri,
  linear_trend_coef = coef(rob4a)[["prescheduled_event"]],
  month_fe_coef = coef(rob4c)[["prescheduled_event"]]
)

writeLines(
  jsonlite::toJSON(robustness, auto_unbox = TRUE, pretty = TRUE),
  file.path(DATA_DIR, "robustness_results.json")
)

cat("Robustness results saved.\n")
