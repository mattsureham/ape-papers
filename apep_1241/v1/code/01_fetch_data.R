## 01_fetch_data.R — Fetch trade data from Open Trade Statistics API
## apep_1241: Animal Welfare Havens

source("00_packages.R")

# --- OTS API (mirrors COMTRADE) ---
# No API key needed; endpoint: api.tradestatistics.io

# Countries of interest
countries <- c(
  # Fur farming ban countries
  "gbr", "aut", "nld", "bel", "cze", "hun", "irl",
  "lva", "ltu", "nor", "dnk",
  # Never-banned EU fur producers (controls)
  "fin", "pol", "grc",
  # Other EU
  "deu", "fra", "ita", "esp", "swe", "rou", "bgr", "hrv", "svn", "svk",
  # Major global producers/consumers
  "chn", "usa", "can", "kor", "jpn", "tur", "rus"
)

# HS codes
# 430110: Mink furskins, raw (primary treatment commodity)
# 4301: Raw furskins, all types (broader)
# 4101: Raw bovine hides (placebo)
# 5101: Wool, not carded (placebo)
hs_codes <- c("430110", "4301", "4101", "5101")

years <- 2002:2022  # OTS coverage range

# --- Fetch function ---
fetch_ots <- function(reporter, year, commodity) {
  url <- sprintf(
    "https://api.tradestatistics.io/yrpc?y=%d&r=%s&p=all&c=%s",
    year, reporter, commodity
  )

  tryCatch({
    resp <- request(url) |>
      req_timeout(30) |>
      req_retry(max_tries = 3, backoff = ~2) |>
      req_perform()

    data <- resp_body_json(resp)

    if (length(data) == 0 || (length(data) == 1 && !is.null(data[[1]]$observation))) {
      return(tibble())
    }

    bind_rows(lapply(data, function(x) {
      tibble(
        year = x$year %||% NA_integer_,
        reporter = x$reporter_iso %||% NA_character_,
        partner = x$partner_iso %||% NA_character_,
        commodity = x$commodity_code %||% NA_character_,
        export_value = x$trade_value_usd_exp %||% NA_real_
      )
    }))
  }, error = function(e) {
    cat("  Error for", reporter, year, commodity, ":", conditionMessage(e), "\n")
    tibble()
  })
}

# --- Fetch all data ---
all_data <- list()
total_calls <- length(countries) * length(years) * length(hs_codes)
call_count <- 0

for (hs in hs_codes) {
  cat("\n=== HS", hs, "===\n")
  for (reporter in countries) {
    for (yr in years) {
      call_count <- call_count + 1
      if (call_count %% 50 == 0) {
        cat("  Progress:", call_count, "/", total_calls, "\n")
      }

      result <- fetch_ots(reporter, yr, hs)
      if (nrow(result) > 0) {
        all_data[[length(all_data) + 1]] <- result
      }

      Sys.sleep(0.3)  # Rate limiting
    }
  }
}

trade_df <- bind_rows(all_data)
cat("\nTotal trade observations:", nrow(trade_df), "\n")

# --- Standardize case (OTS returns uppercase, we use lowercase) ---
trade_df <- trade_df |>
  mutate(reporter = tolower(reporter),
         partner = tolower(partner))

# --- Save raw first (before validation, to avoid data loss) ---
stopifnot("No trade data retrieved" = nrow(trade_df) > 0)

# Aggregate to reporter-year level for main analysis
trade_agg <- trade_df |>
  group_by(reporter, year, commodity) |>
  summarise(
    export_value = sum(export_value, na.rm = TRUE),
    n_partners = n_distinct(partner),
    .groups = "drop"
  )

write_csv(trade_df, "../data/trade_bilateral.csv")
write_csv(trade_agg, "../data/trade_panel.csv")
cat("Data saved to disk.\n")

# --- Validate ---
dnk_2012 <- trade_df |>
  filter(reporter == "dnk", year == 2012, commodity == "430110") |>
  summarise(total = sum(export_value, na.rm = TRUE)) |>
  pull(total)
cat("Denmark 2012 mink exports:", scales::dollar(dnk_2012), "\n")
stopifnot("Denmark 2012 export value implausible" = dnk_2012 > 1e9)

pol_exports <- trade_df |>
  filter(reporter == "pol", commodity == "430110") |>
  group_by(year) |>
  summarise(total = sum(export_value, na.rm = TRUE)) |>
  arrange(year)
cat("Poland mink exports trend:\n")
print(pol_exports)

cat("\nAggregated panel:", nrow(trade_agg), "reporter-year-commodity obs\n")
cat("Reporters:", n_distinct(trade_agg$reporter), "\n")
cat("Years:", paste(range(trade_agg$year), collapse = "-"), "\n")
cat("\nData saved successfully.\n")
