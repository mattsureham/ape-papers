# 01_fetch_data.R — Fetch day-ahead prices and bilateral flows from Energy-Charts API
# Data source: Fraunhofer ISE Energy-Charts (open access, CC BY 4.0)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Helper: fetch Energy-Charts JSON ----
fetch_ec <- function(endpoint, params, max_retries = 5) {
  base_url <- paste0("https://api.energy-charts.info/", endpoint)
  for (attempt in seq_len(max_retries)) {
    resp <- GET(base_url, query = params,
                add_headers("Accept" = "application/json"),
                timeout(120))
    if (status_code(resp) == 200) {
      return(content(resp, as = "text", encoding = "UTF-8"))
    }
    cat(sprintf("  Attempt %d failed (HTTP %d), retrying...\n",
                attempt, status_code(resp)))
    Sys.sleep(3 * attempt)
  }
  stop(sprintf("API call failed after %d attempts: %s", max_retries, base_url))
}

# ============================================================
# 1. Fetch day-ahead prices for DE-LU bidding zone
# ============================================================
cat("=== Fetching day-ahead prices ===\n")

price_list <- list()
for (yr in 2019:2025) {
  cat(sprintf("  Fetching prices for %d...\n", yr))
  end_date <- if (yr == 2025) "2025-03-31" else paste0(yr, "-12-31")

  json_text <- fetch_ec("price", list(
    bzn = "DE-LU",
    start = paste0(yr, "-01-01"),
    end = end_date
  ))
  parsed <- fromJSON(json_text)

  stopifnot("Missing price fields" = !is.null(parsed$unix_seconds) && !is.null(parsed$price))

  dt <- data.table(
    timestamp_unix = parsed$unix_seconds,
    price_eur_mwh = parsed$price
  )
  dt[, datetime := as.POSIXct(timestamp_unix, origin = "1970-01-01", tz = "Europe/Berlin")]
  price_list[[as.character(yr)]] <- dt
  cat(sprintf("    Got %d hourly observations\n", nrow(dt)))
  Sys.sleep(1)
}

prices <- rbindlist(price_list)
prices <- prices[!is.na(price_eur_mwh)]
prices[, date := as.Date(datetime, tz = "Europe/Berlin")]
prices[, hour := hour(datetime)]
prices[, year := year(datetime)]
prices[, month := month(datetime)]
prices[, yearmonth := year * 100 + month]

cat(sprintf("\nTotal price observations: %d\n", nrow(prices)))
cat(sprintf("Date range: %s to %s\n", min(prices$date), max(prices$date)))
cat(sprintf("Negative price hours: %d (%.1f%%)\n",
            sum(prices$price_eur_mwh < 0),
            100 * mean(prices$price_eur_mwh < 0)))

stopifnot("No price data fetched" = nrow(prices) > 1000)
stopifnot("No negative prices found" = sum(prices$price_eur_mwh < 0) > 50)

fwrite(prices, file.path(data_dir, "prices_de.csv"))
cat("Saved prices_de.csv\n")

# ============================================================
# 2. Fetch bilateral cross-border flows (all neighbors in one call)
# ============================================================
cat("\n=== Fetching bilateral cross-border flows ===\n")
# CBET endpoint returns ALL neighbors for a given country in one call
# Fields: unix_seconds, countries (list of {name, data})
# Convention: negative values = export from Germany to neighbor

flow_list <- list()

for (yr in 2019:2025) {
  cat(sprintf("  Fetching CBET flows for %d...\n", yr))
  end_date <- if (yr == 2025) "2025-03-31" else paste0(yr, "-12-31")

  json_text <- fetch_ec("cbet", list(
    country = "de",
    start = paste0(yr, "-01-01"),
    end = end_date
  ))

  parsed <- fromJSON(json_text, simplifyDataFrame = FALSE)
  timestamps <- parsed$unix_seconds

  for (entry in parsed$countries) {
    if (is.null(entry$name) || tolower(entry$name) == "sum") next
    flow_vals <- as.numeric(entry$data)
    # Handle NAs in flow data
    flow_vals[is.null(flow_vals) | !is.finite(flow_vals)] <- NA_real_

    min_len <- min(length(timestamps), length(flow_vals))
    dt <- data.table(
      timestamp_unix = timestamps[1:min_len],
      flow_gw = flow_vals[1:min_len],
      neighbor = entry$name
    )
    flow_list[[paste0(entry$name, "_", yr)]] <- dt
  }

  cat(sprintf("    Got %d timestamps, %d neighbor series\n",
              length(timestamps),
              sum(sapply(parsed$countries, function(x) !is.null(x$name) && tolower(x$name) != "sum"))))
  Sys.sleep(2)
}

if (length(flow_list) == 0) {
  stop("FATAL: No bilateral flow data retrieved from Energy-Charts API")
}

flows <- rbindlist(flow_list)
flows <- flows[!is.na(flow_gw)]
flows[, flow_mw := flow_gw * 1000]  # Convert GW to MW
flows[, datetime := as.POSIXct(timestamp_unix, origin = "1970-01-01", tz = "Europe/Berlin")]
flows[, date := as.Date(datetime, tz = "Europe/Berlin")]
flows[, hour := hour(datetime)]
flows[, minute := minute(datetime)]
flows[, year := year(datetime)]
flows[, month := month(datetime)]
flows[, yearmonth := year * 100 + month]

# Standardize neighbor names
flows[, neighbor := gsub(" ", "_", neighbor)]
flows[neighbor == "Czech_Republic", neighbor := "Czechia"]

# Aggregate from 15-min to hourly (mean flow)
flows_hourly <- flows[, .(flow_mw = mean(flow_mw, na.rm = TRUE),
                          flow_gw = mean(flow_gw, na.rm = TRUE)),
                      by = .(date, hour, year, month, yearmonth, neighbor)]
flows_hourly[, datetime := as.POSIXct(paste(date, sprintf("%02d:00:00", hour)),
                                       tz = "Europe/Berlin")]

cat(sprintf("\nTotal 15-min flow observations: %d\n", nrow(flows)))
cat(sprintf("Total hourly flow observations: %d\n", nrow(flows_hourly)))
cat(sprintf("Neighbors: %s\n", paste(sort(unique(flows_hourly$neighbor)), collapse = ", ")))
cat(sprintf("Date range: %s to %s\n", min(flows_hourly$date), max(flows_hourly$date)))

# Positive = import into Germany; Negative = export from Germany
# For our analysis, we want export from Germany, so negate:
flows_hourly[, export_mw := -flow_mw]  # positive = German export

cat("\nMean hourly export by neighbor (MW, positive = DE exports):\n")
print(flows_hourly[, .(mean_export_mw = round(mean(export_mw, na.rm = TRUE), 0),
                        n_hours = .N),
                   by = neighbor][order(-mean_export_mw)])

stopifnot("No flow data" = nrow(flows_hourly) > 10000)
stopifnot("Fewer than 5 neighbors" = length(unique(flows_hourly$neighbor)) >= 5)

fwrite(flows_hourly, file.path(data_dir, "flows_hourly.csv"))
cat("\nSaved flows_hourly.csv\n")
cat("=== Data fetch complete ===\n")
