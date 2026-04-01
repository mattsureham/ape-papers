## 02_clean_data.R — Clean and prepare analysis dataset
## APEP paper apep_1289

source("00_packages.R")

cat("=== Cleaning data for apep_1289 ===\n")

analysis_df <- readRDS("../data/analysis_panel.rds")
national_data <- readRDS("../data/national_data.rds")
child_fatalities <- readRDS("../data/child_fatalities.rds")

# ============================================================
# 1. Event-time and cohort variables
# ============================================================
analysis_df <- analysis_df %>%
  mutate(
    event_time = ifelse(first_treat > 0, year - first_treat, NA_integer_),
    cohort = case_when(
      first_treat == 0 ~ "Never",
      first_treat <= 2001 ~ "Early (1993-2001)",
      first_treat <= 2008 ~ "Middle (2002-2008)",
      first_treat >= 2009 ~ "Late (2009-2015)"
    ),
    cohort_f = factor(cohort, levels = c("Never", "Early (1993-2001)",
                                          "Middle (2002-2008)", "Late (2009-2015)")),
    log_victim_rate = log(victim_rate + 0.01),
    log_victims = log(victims + 1)
  )

# ============================================================
# 2. Summary statistics
# ============================================================
cat("\n--- Summary Statistics ---\n")

overall <- analysis_df %>%
  summarise(
    n = n(),
    n_states = n_distinct(state),
    mean_rate = mean(victim_rate, na.rm = TRUE),
    sd_rate = sd(victim_rate, na.rm = TRUE),
    mean_victims = mean(victims, na.rm = TRUE),
    mean_referrals = mean(referrals, na.rm = TRUE)
  )
cat(sprintf("Overall: %d obs, %d states, mean rate=%.2f, SD=%.2f\n",
            overall$n, overall$n_states, overall$mean_rate, overall$sd_rate))

# By treatment group
by_group <- analysis_df %>%
  mutate(treated = ifelse(first_treat > 0, "DR States", "Never-DR")) %>%
  group_by(treated) %>%
  summarise(
    n_states = n_distinct(state),
    mean_rate = mean(victim_rate, na.rm = TRUE),
    sd_rate = sd(victim_rate, na.rm = TRUE),
    mean_victims = mean(victims, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nBy group:\n")
print(by_group)

# Pre-treatment statistics (for SDE)
pre_treatment_stats <- analysis_df %>%
  filter(dr_adopted == 0) %>%
  summarise(
    mean_y_pre = mean(victim_rate, na.rm = TRUE),
    sd_y_pre = sd(victim_rate, na.rm = TRUE)
  )

cat(sprintf("\nPre-treatment: mean=%.2f, SD=%.2f\n",
            pre_treatment_stats$mean_y_pre, pre_treatment_stats$sd_y_pre))

# ============================================================
# 3. National trends with fatalities
# ============================================================
national_merged <- national_data %>%
  left_join(child_fatalities, by = "year") %>%
  mutate(
    victim_to_referral = victims_national / referrals_national
  )

# ============================================================
# 4. Save
# ============================================================
saveRDS(analysis_df, "../data/analysis_clean.rds")
saveRDS(pre_treatment_stats, "../data/pre_treatment_stats.rds")
saveRDS(national_merged, "../data/national_merged.rds")

cat(sprintf("\n=== Cleaned: %d obs, %d states, %d years ===\n",
            nrow(analysis_df), n_distinct(analysis_df$state), n_distinct(analysis_df$year)))
