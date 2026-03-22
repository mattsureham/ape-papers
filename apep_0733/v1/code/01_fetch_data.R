## 01_fetch_data.R — Fetch HESTA hotel data from BFS PXWeb + exchange rates
## Paper: The Fortress Premium (apep_0733)

source("code/00_packages.R")

cat("=== Fetching HESTA data from BFS PXWeb ===\n")

meta_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-1003020000_102/px-x-1003020000_102.px"
meta <- jsonlite::fromJSON(meta_url)

years   <- meta$variables$values[[1]]
months  <- meta$variables$values[[2]]
cantons <- meta$variables$values[[3]]
origins <- meta$variables$values[[4]]

# Build lookup tables for value codes -> labels
canton_labels <- setNames(meta$variables$valueTexts[[3]], meta$variables$values[[3]])
origin_labels <- setNames(meta$variables$valueTexts[[4]], meta$variables$values[[4]])
month_labels  <- setNames(meta$variables$valueTexts[[2]], meta$variables$values[[2]])

# Exclude totals
monthly_codes <- months[months != "YYYY"]
canton_codes  <- cantons[cantons != "8100"]  # Switzerland total
origin_codes  <- origins[origins != "00"]     # Origin total

cat(sprintf("Requesting: %d years × %d months × %d cantons × %d origins\n",
            length(years), length(monthly_codes), length(canton_codes), length(origin_codes)))

# Parse PXWeb JSON format into data.table
parse_pxweb_json <- function(json_text) {
  parsed <- jsonlite::fromJSON(json_text, simplifyVector = FALSE)
  rows <- parsed$data
  if (length(rows) == 0) return(data.table())

  dt <- rbindlist(lapply(rows, function(r) {
    keys <- r$key
    vals <- r$values
    data.table(
      year   = as.integer(keys[[1]]),
      month  = as.integer(keys[[2]]),
      canton = keys[[3]],
      origin = keys[[4]],
      nights = as.numeric(vals[[1]])
    )
  }))
  return(dt)
}

# Fetch year by year using JSON format
all_data <- list()

for (yr_idx in seq_along(years)) {
  yr <- years[yr_idx]
  cat(sprintf("  %s (%d/%d)...", yr, yr_idx, length(years)))

  query_body <- list(
    query = list(
      list(code = "Jahr", selection = list(filter = "item", values = list(yr))),
      list(code = "Monat", selection = list(filter = "item", values = as.list(monthly_codes))),
      list(code = "Kanton", selection = list(filter = "item", values = as.list(canton_codes))),
      list(code = "Herkunftsland", selection = list(filter = "item", values = as.list(origin_codes))),
      list(code = "Indikator", selection = list(filter = "item", values = list("2")))
    ),
    response = list(format = "json")
  )

  resp <- httr::POST(
    meta_url,
    body = jsonlite::toJSON(query_body, auto_unbox = TRUE),
    httr::content_type_json(),
    httr::timeout(120)
  )

  status <- httr::status_code(resp)
  if (status == 200) {
    json_text <- httr::content(resp, "text", encoding = "UTF-8")
    dt <- parse_pxweb_json(json_text)
    all_data[[yr_idx]] <- dt
    cat(sprintf(" %d rows\n", nrow(dt)))
  } else {
    cat(sprintf(" HTTP %d — chunking by canton\n", status))
    canton_chunks <- split(canton_codes, ceiling(seq_along(canton_codes) / 6))
    yr_data <- list()
    for (ci in seq_along(canton_chunks)) {
      chunk <- canton_chunks[[ci]]
      query_body2 <- query_body
      query_body2$query[[3]]$selection$values <- as.list(chunk)
      resp2 <- httr::POST(meta_url,
        body = jsonlite::toJSON(query_body2, auto_unbox = TRUE),
        httr::content_type_json(), httr::timeout(120))
      if (httr::status_code(resp2) == 200) {
        yr_data[[ci]] <- parse_pxweb_json(httr::content(resp2, "text", encoding = "UTF-8"))
      }
      Sys.sleep(0.3)
    }
    if (length(yr_data) > 0) {
      dt <- rbindlist(yr_data, fill = TRUE)
      all_data[[yr_idx]] <- dt
      cat(sprintf("    -> %d rows\n", nrow(dt)))
    }
  }

  Sys.sleep(0.3)
}

hesta <- rbindlist(all_data, fill = TRUE)
cat(sprintf("\nTotal HESTA rows: %d\n", nrow(hesta)))

# Add labels
hesta[, canton_name := canton_labels[canton]]
hesta[, origin_name := origin_labels[origin]]

# Validate
stopifnot("No HESTA data!" = nrow(hesta) > 10000)
cat("Sample:\n")
print(head(hesta[nights > 0], 10))

# Summary stats
cat(sprintf("\nYears: %d to %d\n", min(hesta$year), max(hesta$year)))
cat(sprintf("Cantons: %d\n", uniqueN(hesta$canton)))
cat(sprintf("Origins: %d\n", uniqueN(hesta$origin)))
cat(sprintf("Non-zero rows: %d / %d (%.0f%%)\n",
    sum(hesta$nights > 0, na.rm = TRUE), nrow(hesta),
    100 * sum(hesta$nights > 0, na.rm = TRUE) / nrow(hesta)))

fwrite(hesta, "data/hesta_raw.csv")
cat("Saved data/hesta_raw.csv\n")

# --- Step 2: Exchange rates from FRED ---
cat("\n=== Fetching exchange rate data from FRED ===\n")

fred_key <- Sys.getenv("FRED_API_KEY")
stopifnot("FRED_API_KEY not set!" = nchar(fred_key) > 0)

# CHF/USD monthly
fetch_fred <- function(series_id, name) {
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2004-01-01&frequency=m",
    series_id, fred_key)
  resp <- httr::GET(url, httr::timeout(30))
  cat(sprintf("  FRED %s (%s): HTTP %d\n", name, series_id, httr::status_code(resp)))
  if (httr::status_code(resp) != 200) return(NULL)
  d <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  dt <- data.table(
    date = d$observations$date,
    value = as.numeric(d$observations$value)
  )
  setnames(dt, "value", name)
  return(dt)
}

chf_usd <- fetch_fred("EXSZUS", "chf_per_usd")  # CHF per USD
usd_eur <- fetch_fred("EXUSEU", "usd_per_eur")  # USD per EUR

if (!is.null(chf_usd) && !is.null(usd_eur)) {
  fx <- merge(chf_usd, usd_eur, by = "date")
  fx[, chf_per_eur := chf_per_usd * usd_per_eur]
  fx[, year := as.integer(substr(date, 1, 4))]
  fx[, month := as.integer(substr(date, 6, 7))]

  cat(sprintf("\nCHF/EUR monthly: %d observations\n", nrow(fx)))
  cat(sprintf("  Dec 2014: %.4f\n", fx[year == 2014 & month == 12]$chf_per_eur))
  cat(sprintf("  Jan 2015: %.4f\n", fx[year == 2015 & month == 1]$chf_per_eur))
  cat(sprintf("  Feb 2015: %.4f\n", fx[year == 2015 & month == 2]$chf_per_eur))
  appr_jan <- 100 * (1 - fx[year == 2015 & month == 1]$chf_per_eur / fx[year == 2014 & month == 12]$chf_per_eur)
  appr_feb <- 100 * (1 - fx[year == 2015 & month == 2]$chf_per_eur / fx[year == 2014 & month == 12]$chf_per_eur)
  cat(sprintf("  CHF appreciation (Jan): %.1f%%\n", appr_jan))
  cat(sprintf("  CHF appreciation (Feb): %.1f%%\n", appr_feb))

  fwrite(fx, "data/fx_chf_eur.csv")
  cat("Saved data/fx_chf_eur.csv\n")
} else {
  stop("Could not fetch exchange rate data from FRED")
}

# Also fetch CHF/GBP for non-EUR European comparison
chf_gbp_usd <- fetch_fred("EXUSUK", "usd_per_gbp")
if (!is.null(chf_gbp_usd) && !is.null(chf_usd)) {
  fx_gbp <- merge(chf_usd, chf_gbp_usd, by = "date")
  fx_gbp[, chf_per_gbp := chf_per_usd * usd_per_gbp]
  fwrite(fx_gbp[, .(date, chf_per_gbp)], "data/fx_chf_gbp.csv")
  cat("Saved data/fx_chf_gbp.csv\n")
}

cat("\n=== Data fetch complete ===\n")
