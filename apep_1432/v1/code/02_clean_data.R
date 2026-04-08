## 02_clean_data.R — Construct city-week panel linking protests, contributions, weather
## apep_1432: Protests and Campaign Contributions (Weather IV)

source("00_packages.R")

## Load raw data
ccc <- fread("../data/ccc_protests.csv")
fec <- fread("../data/fec_contributions.csv")
weather <- fread("../data/weather_daily.csv")

cat(sprintf("Loaded: %d protests, %d contributions, %d weather obs\n",
            nrow(ccc), nrow(fec), nrow(weather)))

## --- Create city-week panel ---

## Define week as ISO week (Monday-Sunday)
ccc <- ccc %>%
  mutate(event_date = as.Date(event_date),
         year = year(event_date),
         week = isoweek(event_date),
         year_week = paste0(year, "-W", sprintf("%02d", week)))

fec <- fec %>%
  mutate(contribution_date = as.Date(contribution_receipt_date),
         amount = as.numeric(contribution_receipt_amount),
         city = str_to_title(trimws(contributor_city)),
         state = toupper(trimws(contributor_state)),
         city_state = paste0(city, ", ", state),
         year = year(contribution_date),
         week = isoweek(contribution_date),
         year_week = paste0(year, "-W", sprintf("%02d", week))) %>%
  filter(!is.na(contribution_date), !is.na(amount), amount > 0, amount <= 200)

weather <- weather %>%
  mutate(date = as.Date(date),
         year = year(date),
         week = isoweek(date),
         year_week = paste0(year, "-W", sprintf("%02d", week)))

## --- Protest panel (city-week level) ---
## GDELT uses num_mentions as intensity proxy (no crowd size estimates)
ccc <- ccc %>% mutate(num_mentions = as.numeric(num_mentions))

protest_panel <- ccc %>%
  group_by(city_state, year_week) %>%
  summarise(
    n_protests = n(),
    total_mentions = sum(num_mentions, na.rm = TRUE),
    max_mentions = max(num_mentions, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    total_mentions = ifelse(is.infinite(max_mentions), 0, total_mentions),
    max_mentions = ifelse(is.infinite(max_mentions), 0, max_mentions)
  )

cat(sprintf("Protest panel: %d city-week observations with protests\n", nrow(protest_panel)))

## --- Contribution panel (city-week level) ---
contribution_panel <- fec %>%
  group_by(city_state, year_week) %>%
  summarise(
    n_contributions = n(),
    total_amount = sum(amount, na.rm = TRUE),
    mean_amount = mean(amount, na.rm = TRUE),
    n_unique_donors = n_distinct(contributor_name, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("Contribution panel: %d city-weeks with donations\n", nrow(contribution_panel)))

## --- Weather panel (city-week level) ---
## Average precipitation over the week
weather_panel <- weather %>%
  group_by(city_state, year_week) %>%
  summarise(
    precip_mean_mm = mean(precip_mm, na.rm = TRUE),
    precip_max_mm = max(precip_mm, na.rm = TRUE),
    n_rain_days = sum(precip_mm > 0.5, na.rm = TRUE),
    .groups = "drop"
  )

## Precipitation specifically on protest days (instrument)
protest_day_weather <- ccc %>%
  select(city_state, event_date, year_week) %>%
  inner_join(
    weather %>% select(city_state, date, precip_mm),
    by = c("city_state", "event_date" = "date")
  )

protest_weather_panel <- protest_day_weather %>%
  group_by(city_state, year_week) %>%
  summarise(
    precip_protest_days = mean(precip_mm, na.rm = TRUE),
    n_rainy_protest_days = sum(precip_mm > 1, na.rm = TRUE),
    n_protest_days_with_weather = n(),
    .groups = "drop"
  )

cat(sprintf("Protest-day weather: %d city-weeks\n", nrow(protest_weather_panel)))

## --- Merge into full panel ---
## Universe: all city-weeks where we have both FEC data and weather data
## For cities with protests, include non-protest weeks too

## Get the universe of cities present in both FEC and weather
cities_both <- intersect(
  unique(contribution_panel$city_state),
  unique(weather_panel$city_state)
)
## Further restrict to cities that had at least some protests
cities_with_protests <- unique(protest_panel$city_state)
cities_final <- intersect(cities_both, cities_with_protests)

cat(sprintf("Cities in all three datasets: %d\n", length(cities_final)))

## Create full city-week grid
all_weeks <- sort(unique(c(protest_panel$year_week, contribution_panel$year_week,
                           weather_panel$year_week)))
## Restrict to 2018-2023 (GDELT + FEC overlap period)
all_weeks <- all_weeks[grepl("^201[89]|^202[0123]", all_weeks)]

panel_grid <- expand.grid(
  city_state = cities_final,
  year_week = all_weeks,
  stringsAsFactors = FALSE
) %>% as_tibble()

## Merge all panels
panel <- panel_grid %>%
  left_join(protest_panel, by = c("city_state", "year_week")) %>%
  left_join(contribution_panel, by = c("city_state", "year_week")) %>%
  left_join(weather_panel, by = c("city_state", "year_week")) %>%
  left_join(protest_weather_panel, by = c("city_state", "year_week"))

## Fill zeros for weeks without protests/contributions
panel <- panel %>%
  mutate(
    n_protests = replace_na(n_protests, 0),
    total_mentions = replace_na(total_mentions, 0),
    has_protest = as.integer(n_protests > 0),
    n_contributions = replace_na(n_contributions, 0),
    total_amount = replace_na(total_amount, 0),
    n_unique_donors = replace_na(n_unique_donors, 0),
    ## For non-protest weeks, protest-day precip is undefined; use weekly average
    precip_protest_days = ifelse(has_protest == 1, precip_protest_days, NA_real_)
  )

## Parse year and week from year_week
panel <- panel %>%
  mutate(
    year = as.integer(substr(year_week, 1, 4)),
    week = as.integer(substr(year_week, 7, 8)),
    ## Extract state
    state = sub("^.*, ", "", city_state),
    ## Create log outcomes
    ln_contributions = log(1 + n_contributions),
    ln_amount = log(1 + total_amount),
    ln_donors = log(1 + n_unique_donors),
    ln_mentions = log(1 + total_mentions),
    ln_protests = log(1 + n_protests),
    ## State-month FE
    state_month = paste0(state, "_", year, "_", ceiling(week / 4.33))
  )

## Create numeric IDs for fixed effects
panel <- panel %>%
  mutate(
    city_id = as.integer(factor(city_state)),
    week_id = as.integer(factor(year_week)),
    state_month_id = as.integer(factor(state_month))
  )

cat(sprintf("\n=== FINAL PANEL ===\n"))
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("Cities: %d\n", n_distinct(panel$city_state)))
cat(sprintf("Weeks: %d\n", n_distinct(panel$year_week)))
cat(sprintf("City-weeks with protests: %d (%.1f%%)\n",
            sum(panel$has_protest), 100 * mean(panel$has_protest)))
cat(sprintf("City-weeks with contributions: %d (%.1f%%)\n",
            sum(panel$n_contributions > 0), 100 * mean(panel$n_contributions > 0)))
cat(sprintf("City-weeks with weather data: %d (%.1f%%)\n",
            sum(!is.na(panel$precip_mean_mm)), 100 * mean(!is.na(panel$precip_mean_mm))))

## Drop city-weeks missing weather (can't construct IV)
panel <- panel %>% filter(!is.na(precip_mean_mm))
cat(sprintf("After dropping missing weather: %d observations\n", nrow(panel)))

stopifnot("Panel has fewer than 500 rows" = nrow(panel) >= 500)
stopifnot("Fewer than 5 cities" = n_distinct(panel$city_state) >= 5)

fwrite(panel, "../data/panel.csv")
cat("Saved panel data.\n")
