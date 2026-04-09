## 02_clean_data.R — Construct analysis panel
## apep_1439: The Switching Paradox

source("00_packages.R")

gt_all <- readRDS("../data/google_trends.rds")
cat(sprintf("Loaded Google Trends: %d rows\n", nrow(gt_all)))

# --- Construct weekly panel ---
panel <- gt_all %>%
  mutate(
    week = floor_date(date, "week"),
    year = year(date),
    month = month(date),
    # Treatment: insurance comparison sites
    treated = as.integer(group == "insurance"),
    # Post: January 2022 onwards
    post = as.integer(date >= as.Date("2022-01-01")),
    # Interaction
    treat_post = treated * post,
    # Time relative to treatment (in weeks)
    rel_week = as.numeric(difftime(date, as.Date("2022-01-01"), units = "weeks")) %/% 1
  )

# Aggregate to keyword-week level (already is, but ensure)
panel_weekly <- panel %>%
  group_by(keyword, week, group, treated, post, treat_post) %>%
  summarise(hits = mean(hits, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    rel_week = as.numeric(difftime(week, as.Date("2022-01-01"), units = "weeks")) %/% 1,
    # Log transform for percentage interpretation
    log_hits = log(hits + 1)
  )

cat(sprintf("Weekly panel: %d rows, %d keywords, weeks %s to %s\n",
            nrow(panel_weekly), n_distinct(panel_weekly$keyword),
            min(panel_weekly$week), max(panel_weekly$week)))

# --- Aggregate to group-week level ---
panel_group <- panel_weekly %>%
  group_by(group, week, treated, post, treat_post) %>%
  summarise(
    hits = mean(hits, na.rm = TRUE),
    log_hits = mean(log_hits, na.rm = TRUE),
    n_keywords = n(),
    .groups = "drop"
  ) %>%
  mutate(rel_week = as.numeric(difftime(week, as.Date("2022-01-01"), units = "weeks")) %/% 1)

cat(sprintf("Group-week panel: %d rows\n", nrow(panel_group)))

# --- Summary stats ---
cat("\n=== Summary Statistics ===\n")
panel_weekly %>%
  group_by(group, post) %>%
  summarise(
    mean_hits = mean(hits, na.rm = TRUE),
    sd_hits = sd(hits, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  print()

# --- Drop COVID lockdown periods as sensitivity (mark only) ---
panel_weekly <- panel_weekly %>%
  mutate(covid_period = week >= as.Date("2020-03-01") & week <= as.Date("2021-06-30"))

panel_group <- panel_group %>%
  mutate(covid_period = week >= as.Date("2020-03-01") & week <= as.Date("2021-06-30"))

# --- Save ---
saveRDS(panel_weekly, "../data/panel_weekly.rds")
saveRDS(panel_group, "../data/panel_group.rds")
cat("\nSaved panel_weekly.rds and panel_group.rds\n")
