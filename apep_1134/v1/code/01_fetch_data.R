## 01_fetch_data.R — Fetch electricity price and generation data from Energy-Charts API
## apep_1134: EEG Clawback Threshold Bunching
##
## Data source: Fraunhofer ISE Energy-Charts (https://energy-charts.info/)
## License: CC BY 4.0
## Resolution: hourly day-ahead prices, 15-minute generation by fuel type
## Coverage: 2019-2024, Germany + placebo countries (FR, AT, NL, ES)

source("00_packages.R")

# =============================================================================
# Helper: fetch Energy-Charts API
# =============================================================================
fetch_energy_charts <- function(endpoint, params, max_retries = 3) {
  base_url <- "https://api.energy-charts.info"
  url <- paste0(base_url, "/", endpoint)

  for (attempt in 1:max_retries) {
    resp <- tryCatch(
      httr::GET(url, query = params, httr::timeout(120)),
      error = function(e) {
        cat(sprintf("  Attempt %d failed: %s\n", attempt, e$message))
        NULL
      }
    )

    if (!is.null(resp) && httr::status_code(resp) == 200) {
      content <- httr::content(resp, as = "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(content)
      return(parsed)
    }

    if (!is.null(resp)) {
      cat(sprintf("  HTTP %d on attempt %d for %s\n",
                  httr::status_code(resp), attempt, endpoint))
    }
    Sys.sleep(2 * attempt)
  }

  stop(sprintf("FATAL: Failed to fetch %s after %d attempts. Cannot proceed with simulated data.",
               endpoint, max_retries))
}

# =============================================================================
# 1. Fetch hourly day-ahead prices
# =============================================================================
cat("=== Fetching day-ahead prices ===\n")

countries <- c("de" = "DE-LU", "fr" = "FR", "at" = "AT", "nl" = "NL", "es" = "ES")
years <- 2019:2024

all_prices <- list()

for (ccode in names(countries)) {
  for (yr in years) {
    cat(sprintf("  Prices: %s %d... ", toupper(ccode), yr))

    # Energy-Charts price endpoint
    params <- list(
      bzn = countries[[ccode]],
      start = paste0(yr, "-01-01"),
      end = paste0(yr, "-12-31")
    )

    result <- fetch_energy_charts("price", params)

    # The API returns unix_seconds and price arrays
    if (is.null(result$unix_seconds) || is.null(result$price)) {
      stop(sprintf("FATAL: No price data returned for %s %d", toupper(ccode), yr))
    }

    n_obs <- length(result$unix_seconds)
    cat(sprintf("%d observations\n", n_obs))

    if (n_obs < 1000) {
      stop(sprintf("FATAL: Only %d price observations for %s %d — expected ~8760",
                    n_obs, toupper(ccode), yr))
    }

    df_price <- data.frame(
      timestamp_unix = result$unix_seconds,
      price_eur_mwh = result$price,
      country = toupper(ccode),
      stringsAsFactors = FALSE
    )

    df_price$datetime <- as.POSIXct(df_price$timestamp_unix, origin = "1970-01-01", tz = "Europe/Berlin")
    df_price$date <- as.Date(df_price$datetime, tz = "Europe/Berlin")
    df_price$hour <- hour(df_price$datetime)
    df_price$year <- yr

    all_prices[[paste(ccode, yr)]] <- df_price
    Sys.sleep(0.5)  # rate limiting
  }
}

prices <- bind_rows(all_prices)
cat(sprintf("\nTotal price observations: %d\n", nrow(prices)))
cat(sprintf("Countries: %s\n", paste(unique(prices$country), collapse = ", ")))

# Validate: no all-NA prices
for (cc in unique(prices$country)) {
  na_pct <- mean(is.na(prices$price_eur_mwh[prices$country == cc]))
  cat(sprintf("  %s: %.1f%% NA prices\n", cc, na_pct * 100))
  if (na_pct > 0.10) {
    stop(sprintf("FATAL: %s has %.0f%% NA prices — data quality insufficient", cc, na_pct * 100))
  }
}

saveRDS(prices, "../data/prices_raw.rds")
cat("Saved prices_raw.rds\n")

# =============================================================================
# 2. Fetch 15-minute generation data (Germany only — primary analysis)
# =============================================================================
cat("\n=== Fetching 15-min generation data (Germany) ===\n")

all_gen <- list()

for (yr in years) {
  cat(sprintf("  Generation: DE %d... ", yr))

  params <- list(
    country = "de",
    start = paste0(yr, "-01-01"),
    end = paste0(yr, "-12-31")
  )

  result <- fetch_energy_charts("public_power", params)

  # Parse the production_types array
  if (is.null(result$unix_seconds)) {
    stop(sprintf("FATAL: No generation data returned for DE %d", yr))
  }

  timestamps <- result$unix_seconds
  n_times <- length(timestamps)
  cat(sprintf("%d time points, ", n_times))

  # jsonlite parses production_types as data.frame with $name (chr) and $data (list)
  pt <- result$production_types
  gen_list <- list()
  for (i in seq_len(nrow(pt))) {
    type_name <- pt$name[i]
    values <- pt$data[[i]]

    if (length(values) == n_times) {
      gen_list[[type_name]] <- data.frame(
        timestamp_unix = timestamps,
        fuel_type = type_name,
        generation_mw = as.numeric(values),
        stringsAsFactors = FALSE
      )
    }
  }

  gen_yr <- bind_rows(gen_list)
  gen_yr$year <- yr
  gen_yr$datetime <- as.POSIXct(gen_yr$timestamp_unix, origin = "1970-01-01", tz = "Europe/Berlin")

  n_types <- length(unique(gen_yr$fuel_type))
  cat(sprintf("%d fuel types\n", n_types))

  all_gen[[as.character(yr)]] <- gen_yr
  Sys.sleep(1)  # rate limiting for large requests
}

generation <- bind_rows(all_gen)
cat(sprintf("\nTotal generation observations: %d\n", nrow(generation)))
cat(sprintf("Fuel types: %s\n", paste(sort(unique(generation$fuel_type)), collapse = ", ")))

# Validate
stopifnot("generation data is empty" = nrow(generation) > 0)
stopifnot("missing fuel types" = length(unique(generation$fuel_type)) >= 5)

saveRDS(generation, "../data/generation_raw.rds")
cat("Saved generation_raw.rds\n")

# =============================================================================
# 3. Fetch hourly generation for placebo countries (lower resolution is fine)
# =============================================================================
cat("\n=== Fetching generation data for placebo countries ===\n")

placebo_gen <- list()

for (ccode in c("fr", "at", "nl", "es")) {
  for (yr in years) {
    cat(sprintf("  Generation: %s %d... ", toupper(ccode), yr))

    params <- list(
      country = ccode,
      start = paste0(yr, "-01-01"),
      end = paste0(yr, "-12-31")
    )

    result <- tryCatch(
      fetch_energy_charts("public_power", params),
      error = function(e) {
        cat(sprintf("WARN: %s\n", e$message))
        NULL
      }
    )

    if (is.null(result) || is.null(result$unix_seconds)) {
      cat("skipped (no data)\n")
      next
    }

    timestamps <- result$unix_seconds
    n_times <- length(timestamps)

    pt <- result$production_types
    gen_list <- list()
    for (i in seq_len(nrow(pt))) {
      type_name <- pt$name[i]
      values <- pt$data[[i]]
      if (length(values) == n_times) {
        gen_list[[type_name]] <- data.frame(
          timestamp_unix = timestamps,
          fuel_type = type_name,
          generation_mw = as.numeric(values),
          stringsAsFactors = FALSE
        )
      }
    }

    if (length(gen_list) > 0) {
      gen_yr <- bind_rows(gen_list)
      gen_yr$country <- toupper(ccode)
      gen_yr$year <- yr
      gen_yr$datetime <- as.POSIXct(gen_yr$timestamp_unix, origin = "1970-01-01", tz = "Europe/Berlin")
      placebo_gen[[paste(ccode, yr)]] <- gen_yr
      cat(sprintf("%d obs\n", nrow(gen_yr)))
    } else {
      cat("no generation types parsed\n")
    }

    Sys.sleep(0.5)
  }
}

if (length(placebo_gen) > 0) {
  placebo_generation <- bind_rows(placebo_gen)
  cat(sprintf("\nTotal placebo generation observations: %d\n", nrow(placebo_generation)))
  saveRDS(placebo_generation, "../data/placebo_generation_raw.rds")
  cat("Saved placebo_generation_raw.rds\n")
} else {
  cat("WARNING: No placebo generation data fetched. Proceeding with DE-only analysis.\n")
}

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Price obs: %d | DE generation obs: %d\n", nrow(prices), nrow(generation)))
