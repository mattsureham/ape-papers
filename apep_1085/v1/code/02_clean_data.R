# 02_clean_data.R — Construct state-year panel for apep_1085
# Wind Turbines and Avian Community Restructuring

library(tidyverse)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))[1]
if (length(script_dir) > 0 && nchar(script_dir) > 0) setwd(file.path(script_dir, ".."))

# ============================================================
# Load data
# ============================================================
bird_panel <- readRDS("data/bird_panel.rds")
state_cumul <- readRDS("data/state_wind_cumul.rds")
first_treat <- readRDS("data/first_treat.rds")
effort_data <- readRDS("data/effort_data.rds")

cat("Bird panel:", nrow(bird_panel), "rows\n")
cat("States with wind data:", n_distinct(state_cumul$state), "\n")
cat("Treatment states:", nrow(first_treat), "\n")

# ============================================================
# 1. Build complete state-year wind capacity panel
# ============================================================
all_states <- sort(unique(bird_panel$state))
all_years <- sort(unique(bird_panel$year))

wind_full <- expand_grid(state = all_states, year = all_years) %>%
  left_join(
    state_cumul %>%
      group_by(state) %>%
      complete(year_operational = all_years) %>%
      fill(cum_turbines, cum_capacity_mw, .direction = "down") %>%
      rename(year = year_operational) %>%
      select(state, year, cum_turbines, cum_capacity_mw),
    by = c("state", "year")
  ) %>%
  mutate(
    cum_turbines = replace_na(cum_turbines, 0),
    cum_capacity_mw = replace_na(cum_capacity_mw, 0),
    log_capacity = log(1 + cum_capacity_mw)
  ) %>%
  left_join(first_treat, by = "state") %>%
  mutate(
    first_treat_year = replace_na(first_treat_year, 0L),  # 0 = never treated
    treated = as.integer(cum_capacity_mw >= 100),
    post_treat = as.integer(year >= first_treat_year & first_treat_year > 0)
  )

# ============================================================
# 2. Reshape bird data to wide (one row per state-year)
# ============================================================
bird_wide <- bird_panel %>%
  select(state, year, taxon, n_records, total_bird_records) %>%
  pivot_wider(
    id_cols = c(state, year, total_bird_records),
    names_from = taxon,
    values_from = n_records,
    names_prefix = "n_"
  ) %>%
  mutate(
    # Reporting rates (proportion of all bird records)
    rr_raptors = n_raptors / pmax(total_bird_records, 1),
    rr_grassland = n_grassland / pmax(total_bird_records, 1),
    rr_waterfowl = n_waterfowl / pmax(total_bird_records, 1),
    # Log counts
    log_raptors = log(1 + n_raptors),
    log_grassland = log(1 + n_grassland),
    log_waterfowl = log(1 + n_waterfowl),
    log_total = log(1 + total_bird_records)
  )

# ============================================================
# 3. Merge into analysis panel
# ============================================================
panel <- wind_full %>%
  left_join(bird_wide, by = c("state", "year")) %>%
  filter(!is.na(total_bird_records), total_bird_records > 0)

# Event time relative to first treatment
panel <- panel %>%
  mutate(
    rel_year = ifelse(first_treat_year > 0, year - first_treat_year, NA_integer_)
  )

cat(sprintf("\nPanel dimensions: %d rows (%d states × %d years)\n",
            nrow(panel), n_distinct(panel$state), n_distinct(panel$year)))

# ============================================================
# 4. Summary statistics
# ============================================================
cat("\n=== PANEL SUMMARY ===\n")

cat("\nWind capacity by treatment status:\n")
panel %>%
  mutate(group = ifelse(first_treat_year > 0, "Wind states", "No wind")) %>%
  group_by(group) %>%
  summarise(
    n_states = n_distinct(state),
    mean_capacity_mw = mean(cum_capacity_mw),
    mean_raptors = mean(n_raptors, na.rm = TRUE),
    mean_grassland = mean(n_grassland, na.rm = TRUE),
    mean_waterfowl = mean(n_waterfowl, na.rm = TRUE),
    mean_total_birds = mean(total_bird_records, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Pre-treatment standard deviations (for SDE)
pre_stats <- panel %>%
  filter(is.na(rel_year) | rel_year < 0) %>%
  summarise(
    sd_rr_raptors = sd(rr_raptors, na.rm = TRUE),
    sd_rr_grassland = sd(rr_grassland, na.rm = TRUE),
    sd_rr_waterfowl = sd(rr_waterfowl, na.rm = TRUE),
    sd_log_raptors = sd(log_raptors, na.rm = TRUE),
    sd_log_grassland = sd(log_grassland, na.rm = TRUE),
    mean_rr_raptors = mean(rr_raptors, na.rm = TRUE),
    mean_rr_grassland = mean(rr_grassland, na.rm = TRUE)
  )

cat("\nPre-treatment SDs:\n")
print(pre_stats)

saveRDS(pre_stats, "data/pre_stats.rds")
saveRDS(panel, "data/panel.rds")

cat(sprintf("\nPanel saved: %d observations\n", nrow(panel)))
