# 02_clean_data.R — Construct analysis dataset
# apep_0777: SNAP-Medicaid Data Coordination

source("00_packages.R")
library(fixest)

enrollment <- read_csv("../data/medicaid_enrollment.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))
e14 <- read_csv("../data/e14_waiver_states.csv", show_col_types = FALSE)

cat("Enrollment:", nrow(enrollment), "state-months\n")

# ============================================================
# 1. Merge treatment status
# ============================================================

panel <- enrollment %>%
  left_join(e14 %>% select(state, e14_waiver), by = "state") %>%
  filter(!is.na(e14_waiver))

cat("After merge:", nrow(panel), "state-months\n")

# ============================================================
# 2. Normalize enrollment to March 2023 baseline
# ============================================================

baseline <- panel %>%
  filter(date == as.Date("2023-03-01")) %>%
  select(state, baseline_enrollment = enrollment)

panel <- panel %>%
  left_join(baseline, by = "state") %>%
  filter(!is.na(baseline_enrollment)) %>%
  mutate(
    norm_enrollment = enrollment / baseline_enrollment,
    post = as.integer(date >= as.Date("2023-04-01")),
    months_from_unwinding = as.numeric(difftime(date, as.Date("2023-04-01"), units = "days")) / 30.44,
    month_rel = round(months_from_unwinding),
    year_month = format(date, "%Y-%m"),
    state_id = as.integer(factor(state)),
    time_id = as.integer(factor(date))
  )

cat("Final panel:", nrow(panel), "state-months\n")
cat("E14 states:", sum(panel$e14_waiver & panel$post == 0) / sum(panel$post == 0) * 51, "approx\n")

# ============================================================
# 3. Summary statistics
# ============================================================

summary_stats <- panel %>%
  group_by(e14_waiver) %>%
  summarize(
    n_states = n_distinct(state),
    mean_enrollment_pre = mean(enrollment[post == 0]),
    mean_enrollment_post = mean(enrollment[post == 1]),
    mean_norm_pre = mean(norm_enrollment[post == 0]),
    mean_norm_post = mean(norm_enrollment[post == 1]),
    sd_norm_pre = sd(norm_enrollment[post == 0]),
    n_months = n_distinct(date),
    .groups = "drop"
  )

cat("\n=== Summary Statistics ===\n")
print(summary_stats)

# Pre-trends check
pre_trends <- panel %>%
  filter(post == 0) %>%
  group_by(e14_waiver, date) %>%
  summarize(mean_norm = mean(norm_enrollment), .groups = "drop") %>%
  pivot_wider(names_from = e14_waiver, values_from = mean_norm,
              names_prefix = "e14_") %>%
  mutate(diff = e14_TRUE - e14_FALSE)

cat("\n=== Pre-Trends (normalized enrollment) ===\n")
print(pre_trends %>% filter(date >= as.Date("2022-01-01")), n = 20)

# ============================================================
# 4. Save
# ============================================================

write_csv(panel, "../data/analysis_panel.csv")
write_csv(summary_stats, "../data/summary_stats.csv")

cat("\nAnalysis panel saved:", nrow(panel), "rows\n")
