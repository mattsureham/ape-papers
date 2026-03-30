## 02_clean_data.R — Construct negative-price episodes and analysis panels
## apep_1134: EEG Clawback Threshold Bunching

source("00_packages.R")

# =============================================================================
# 1. Load raw data
# =============================================================================
prices <- readRDS("../data/prices_raw.rds")
generation <- readRDS("../data/generation_raw.rds")

cat(sprintf("Prices: %d obs, %d countries\n", nrow(prices), n_distinct(prices$country)))
cat(sprintf("Generation: %d obs, %d fuel types\n", nrow(generation), n_distinct(generation$fuel_type)))

# =============================================================================
# 2. Identify negative-price episodes for each country
# =============================================================================
identify_episodes <- function(price_df, country_code) {
  df <- price_df %>%
    filter(country == country_code) %>%
    arrange(datetime) %>%
    mutate(negative = price_eur_mwh < 0)

  # Run-length encoding to identify consecutive negative-price hours
  rle_neg <- rle(df$negative)
  episode_id <- rep(seq_along(rle_neg$lengths), rle_neg$lengths)
  df$run_id <- episode_id

  # Keep only negative-price runs
  episodes <- df %>%
    filter(negative) %>%
    group_by(run_id) %>%
    summarize(
      country = first(country),
      start_time = min(datetime),
      end_time = max(datetime),
      duration_hours = n(),
      mean_price = mean(price_eur_mwh, na.rm = TRUE),
      min_price = min(price_eur_mwh, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      date = as.Date(start_time, tz = "Europe/Berlin"),
      year = year(start_time),
      month = month(start_time),
      hour_of_day_start = hour(start_time),
      weekend = lubridate::wday(start_time, week_start = 1) >= 6
    )

  # Assign policy regime (clawback threshold)
  episodes <- episodes %>%
    mutate(
      threshold = case_when(
        year < 2021 ~ 6L,
        year >= 2021 & year < 2024 ~ 4L,
        year >= 2024 ~ 3L
      ),
      above_threshold = duration_hours >= threshold,
      near_threshold = duration_hours >= (threshold - 2) & duration_hours <= (threshold + 2)
    )

  return(episodes)
}

# Germany episodes
de_episodes <- identify_episodes(prices, "DE")
cat(sprintf("\n=== Germany: %d negative-price episodes ===\n", nrow(de_episodes)))
cat("By year:\n")
print(table(de_episodes$year))
cat("\nDuration distribution:\n")
print(summary(de_episodes$duration_hours))
cat(sprintf("Episodes above clawback threshold: %d (%.1f%%)\n",
            sum(de_episodes$above_threshold),
            mean(de_episodes$above_threshold) * 100))

# Placebo country episodes
placebo_episodes <- list()
for (cc in c("FR", "AT", "NL", "ES")) {
  ep <- identify_episodes(prices, cc)
  if (nrow(ep) > 0) {
    placebo_episodes[[cc]] <- ep
    cat(sprintf("%s: %d episodes\n", cc, nrow(ep)))
  }
}
all_episodes <- bind_rows(de_episodes, bind_rows(placebo_episodes))

# =============================================================================
# 3. Construct hourly generation panel for negative-price episodes (Germany)
# =============================================================================

# Aggregate 15-min generation to hourly, by fuel type
gen_hourly <- generation %>%
  mutate(
    date = as.Date(datetime, tz = "Europe/Berlin"),
    hour = hour(datetime)
  ) %>%
  group_by(fuel_type, date, hour) %>%
  summarize(
    generation_mw = mean(generation_mw, na.rm = TRUE),
    .groups = "drop"
  )

# Classify fuel types into renewable categories
renewable_types <- c("Wind onshore", "Wind offshore", "Solar", "Biomass",
                     "Hydro Run-of-River", "Geothermal")
wind_types <- c("Wind onshore", "Wind offshore")
solar_types <- c("Solar")

# Aggregate to renewable/wind/solar totals per hour
gen_totals <- gen_hourly %>%
  mutate(
    is_renewable = fuel_type %in% renewable_types,
    is_wind = fuel_type %in% wind_types,
    is_solar = fuel_type %in% solar_types
  ) %>%
  group_by(date, hour) %>%
  summarize(
    total_gen_mw = sum(generation_mw, na.rm = TRUE),
    renewable_gen_mw = sum(generation_mw[is_renewable], na.rm = TRUE),
    wind_gen_mw = sum(generation_mw[is_wind], na.rm = TRUE),
    solar_gen_mw = sum(generation_mw[is_solar], na.rm = TRUE),
    .groups = "drop"
  )

# =============================================================================
# 4. Match generation data to episodes
# =============================================================================

# For each episode, get hour-by-hour generation
episode_hours <- de_episodes %>%
  rowwise() %>%
  do({
    ep <- .
    hours_seq <- seq(ep$start_time, ep$end_time, by = "hour")
    data.frame(
      episode_id = ep$run_id,
      datetime = hours_seq,
      date = as.Date(hours_seq, tz = "Europe/Berlin"),
      hour = hour(hours_seq),
      episode_hour = seq_along(hours_seq),  # hour within episode (1, 2, 3...)
      duration_hours = ep$duration_hours,
      threshold = ep$threshold,
      year = ep$year,
      above_threshold = ep$above_threshold,
      stringsAsFactors = FALSE
    )
  }) %>%
  ungroup()

# Merge with generation
episode_gen <- episode_hours %>%
  left_join(gen_totals, by = c("date", "hour"))

# Calculate relative generation (within-episode)
episode_gen <- episode_gen %>%
  group_by(episode_id) %>%
  mutate(
    # Normalize to first-hour generation
    renewable_rel = renewable_gen_mw / first(renewable_gen_mw),
    wind_rel = wind_gen_mw / first(wind_gen_mw),
    # Hours to threshold
    hours_to_threshold = threshold - episode_hour
  ) %>%
  ungroup()

cat(sprintf("\nEpisode-hour panel: %d observations\n", nrow(episode_gen)))

# =============================================================================
# 5. Save analysis datasets
# =============================================================================
saveRDS(de_episodes, "../data/de_episodes.rds")
saveRDS(all_episodes, "../data/all_episodes.rds")
saveRDS(episode_gen, "../data/episode_gen.rds")
saveRDS(gen_totals, "../data/gen_totals.rds")

cat("\n=== Cleaning complete ===\n")
cat(sprintf("DE episodes: %d\n", nrow(de_episodes)))
cat(sprintf("All episodes (with placebos): %d\n", nrow(all_episodes)))
cat(sprintf("Episode-hour panel: %d obs\n", nrow(episode_gen)))
