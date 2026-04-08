## 01_fetch_data.R — Load GDELT protests (pre-fetched), fetch FEC + weather
## apep_1432: Protests and Campaign Contributions (Weather IV)
##
## GDELT protest data must be pre-fetched by running:
##   python3 01a_fetch_gdelt_protests.py

source("00_packages.R")

cat("=== STEP 1: Load GDELT Protest Data ===\n")

gdelt_file <- "../data/gdelt_protests.csv"
if (!file.exists(gdelt_file)) {
  stop("FATAL: gdelt_protests.csv not found. Run 01a_fetch_gdelt_protests.py first.")
}

gdelt <- fread(gdelt_file)
cat(sprintf("GDELT raw: %d US protest events\n", nrow(gdelt)))
stopifnot("GDELT has fewer than 1000 events" = nrow(gdelt) >= 1000)

## Parse event_date from YYYYMMDD to Date
gdelt <- gdelt %>%
  as_tibble() %>%
  mutate(
    event_date = as.Date(as.character(event_date), format = "%Y%m%d"),
    num_mentions = as.numeric(num_mentions),
    num_articles = as.numeric(num_articles),
    avg_tone = as.numeric(avg_tone),
    lat = as.numeric(lat),
    lon = as.numeric(lon)
  ) %>%
  filter(!is.na(event_date), !is.na(lat), !is.na(lon))

## Extract city and state from location field
## GDELT format: "City, State, United States"
gdelt <- gdelt %>%
  mutate(
    loc_parts = str_split(location, ", "),
    city = map_chr(loc_parts, ~ .x[1]),
    state_name = map_chr(loc_parts, ~ ifelse(length(.x) >= 2, .x[2], NA_character_)),
    ## Map admin1 code to state abbreviation
    ## GDELT admin1 for US is like "USCA" for California
    state_abbr = ifelse(nchar(admin1) == 4 & startsWith(admin1, "US"),
                        substr(admin1, 3, 4), NA_character_),
    city_state = paste0(city, ", ", state_abbr)
  ) %>%
  filter(!is.na(state_abbr), nchar(city) > 0)

## Deduplicate: GDELT often codes the same event from multiple sources
## Keep unique event_id per city-date
gdelt <- gdelt %>%
  group_by(event_id) %>%
  slice_max(num_mentions, n = 1, with_ties = FALSE) %>%
  ungroup()

cat(sprintf("GDELT cleaned: %d events, %d cities, %d states\n",
            nrow(gdelt), n_distinct(gdelt$city_state), n_distinct(gdelt$state_abbr)))
cat(sprintf("Date range: %s to %s\n", min(gdelt$event_date), max(gdelt$event_date)))

## Save as 'ccc' for downstream compatibility
ccc <- gdelt %>%
  select(event_id, event_date, city, state = state_abbr, city_state,
         lat, lon, num_mentions, num_articles, avg_tone, event_base_code)

fwrite(ccc, "../data/ccc_protests.csv")
cat("Saved GDELT protests as ccc_protests.csv.\n")


cat("\n=== STEP 2: Fetch FEC Contribution Data ===\n")

fec_key <- Sys.getenv("FEC_API_KEY", unset = "DEMO_KEY")

## Focus on cities with 10+ protest events
active_cities <- ccc %>%
  count(city_state) %>%
  filter(n >= 10) %>%
  pull(city_state)

cat(sprintf("Cities with 10+ protests: %d\n", length(active_cities)))

## Top states by protest activity
top_states <- ccc %>%
  filter(city_state %in% active_cities) %>%
  count(state, sort = TRUE) %>%
  head(20) %>%
  pull(state)

cat(sprintf("Top 20 states: %s\n", paste(top_states, collapse = ", ")))

fetch_fec_contributions <- function(state, min_date, max_date, api_key) {
  base_url <- "https://api.open.fec.gov/v1/schedules/schedule_a/"
  all_results <- list()
  last_index <- NULL
  last_date <- NULL

  for (i in 1:30) {
    params <- list(
      api_key = api_key,
      contributor_state = state,
      min_date = min_date,
      max_date = max_date,
      max_amount = 200,
      min_amount = 1,
      sort = "contribution_receipt_date",
      per_page = 100,
      is_individual = "true"
    )

    if (!is.null(last_index)) {
      params$last_index <- last_index
      params$last_contribution_receipt_date <- last_date
    }

    resp <- tryCatch(
      {
        r <- GET(base_url, query = params)
        Sys.sleep(0.6)
        content(r, as = "parsed")
      },
      error = function(e) NULL
    )

    if (is.null(resp) || length(resp$results) == 0) break
    all_results <- c(all_results, resp$results)

    if (is.null(resp$pagination$last_indexes)) break
    last_index <- resp$pagination$last_indexes$last_index
    last_date <- resp$pagination$last_indexes$last_contribution_receipt_date
    if (is.null(last_index)) break
  }
  return(all_results)
}

## Fetch by state-quarter for 2018-2023
quarters <- expand.grid(
  state = top_states,
  year = 2018:2023,
  q = 1:4,
  stringsAsFactors = FALSE
) %>%
  mutate(
    min_date = case_when(
      q == 1 ~ paste0(year, "-01-01"),
      q == 2 ~ paste0(year, "-04-01"),
      q == 3 ~ paste0(year, "-07-01"),
      q == 4 ~ paste0(year, "-10-01")
    ),
    max_date = case_when(
      q == 1 ~ paste0(year, "-03-31"),
      q == 2 ~ paste0(year, "-06-30"),
      q == 3 ~ paste0(year, "-09-30"),
      q == 4 ~ paste0(year, "-12-31")
    )
  )

cat(sprintf("State-quarter combinations to fetch: %d\n", nrow(quarters)))

fec_data <- list()
for (i in seq_len(nrow(quarters))) {
  if (i %% 20 == 0) cat(sprintf("  FEC fetch %d/%d...\n", i, nrow(quarters)))
  res <- fetch_fec_contributions(
    state = quarters$state[i],
    min_date = quarters$min_date[i],
    max_date = quarters$max_date[i],
    api_key = fec_key
  )
  if (length(res) > 0) {
    parsed <- map_dfr(res, ~ tibble(
      contributor_city = .x$contributor_city %||% NA_character_,
      contributor_state = .x$contributor_state %||% NA_character_,
      contribution_receipt_date = .x$contribution_receipt_date %||% NA_character_,
      contribution_receipt_amount = .x$contribution_receipt_amount %||% NA_real_,
      committee_name = .x$committee_name %||% NA_character_,
      committee_id = .x$committee_id %||% NA_character_,
      contributor_name = .x$contributor_name %||% NA_character_
    ))
    fec_data[[i]] <- parsed
  }
}

fec_df <- bind_rows(fec_data)
cat(sprintf("FEC raw contributions: %d rows\n", nrow(fec_df)))

if (nrow(fec_df) == 0) {
  stop("FATAL: FEC API returned zero contributions. Cannot proceed.")
}

fec_df <- fec_df %>%
  mutate(
    contribution_date = as.Date(contribution_receipt_date),
    city = str_to_title(trimws(contributor_city)),
    state = toupper(trimws(contributor_state)),
    city_state = paste0(city, ", ", state),
    amount = as.numeric(contribution_receipt_amount)
  ) %>%
  filter(!is.na(contribution_date), !is.na(amount), amount > 0, amount <= 200)

cat(sprintf("FEC cleaned: %d contributions, %d cities\n",
            nrow(fec_df), n_distinct(fec_df$city_state)))

fwrite(fec_df, "../data/fec_contributions.csv")
cat("Saved FEC contributions.\n")


cat("\n=== STEP 3: Fetch Weather Data (Open-Meteo) ===\n")

fetch_weather <- function(lat, lon, start_date, end_date) {
  url <- sprintf(
    "https://archive-api.open-meteo.com/v1/archive?latitude=%.4f&longitude=%.4f&start_date=%s&end_date=%s&daily=precipitation_sum&timezone=America/New_York",
    lat, lon, start_date, end_date
  )
  resp <- tryCatch(
    {
      r <- GET(url)
      Sys.sleep(0.25)
      content(r, as = "parsed")
    },
    error = function(e) NULL
  )
  if (is.null(resp) || is.null(resp$daily)) return(NULL)

  tibble(
    date = as.Date(unlist(resp$daily$time)),
    precip_mm = as.numeric(sapply(resp$daily$precipitation_sum,
                                   function(x) ifelse(is.null(x), NA_real_, x)))
  )
}

## Get representative coordinates for active protest cities
city_coords <- ccc %>%
  filter(city_state %in% active_cities) %>%
  group_by(city_state) %>%
  summarise(lat = median(lat, na.rm = TRUE),
            lon = median(lon, na.rm = TRUE),
            n_protests = n(),
            .groups = "drop") %>%
  filter(!is.na(lat), !is.na(lon))

if (nrow(city_coords) < 30) {
  city_coords <- ccc %>%
    filter(!is.na(lat), !is.na(lon)) %>%
    group_by(city_state) %>%
    summarise(lat = median(lat, na.rm = TRUE),
              lon = median(lon, na.rm = TRUE),
              n_protests = n(),
              .groups = "drop") %>%
    filter(n_protests >= 5)
}

cat(sprintf("Fetching weather for %d cities\n", nrow(city_coords)))

weather_list <- list()
years <- 2018:2023
total_fetches <- nrow(city_coords) * length(years)
fetch_count <- 0

for (yr in years) {
  for (j in seq_len(nrow(city_coords))) {
    fetch_count <- fetch_count + 1
    if (fetch_count %% 100 == 0) {
      cat(sprintf("  Weather fetch %d/%d...\n", fetch_count, total_fetches))
    }
    w <- fetch_weather(
      lat = city_coords$lat[j],
      lon = city_coords$lon[j],
      start_date = paste0(yr, "-01-01"),
      end_date = paste0(yr, "-12-31")
    )
    if (!is.null(w)) {
      w$city_state <- city_coords$city_state[j]
      weather_list[[length(weather_list) + 1]] <- w
    }
  }
}

weather_df <- bind_rows(weather_list)
cat(sprintf("Weather data: %d city-day observations, %d cities\n",
            nrow(weather_df), n_distinct(weather_df$city_state)))

if (nrow(weather_df) == 0) {
  stop("FATAL: Weather API returned zero observations. Cannot proceed.")
}

fwrite(weather_df, "../data/weather_daily.csv")
cat("Saved weather data.\n")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("GDELT protests: %d events\n", nrow(ccc)))
cat(sprintf("FEC contributions: %d rows\n", nrow(fec_df)))
cat(sprintf("Weather observations: %d city-days\n", nrow(weather_df)))
