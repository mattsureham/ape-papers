# 01_fetch_data.R — Fetch Eurostat retail turnover & fiscal data
# APEP-0598: Greece Capital Controls & Shadow Economy Formalization

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. RETAIL TRADE TURNOVER (STS_TRTU_M)
# Monthly, seasonally & calendar adjusted, index 2015=100
# Using eurostat R package for robust parsing
# ============================================================

cat("Fetching retail trade turnover data from Eurostat...\n")

countries <- c("EL", "PT", "ES", "IT", "IE", "CY", "BG", "RO",
               "HR", "SK", "SI", "LT", "LV", "EE", "MT")

nace_sectors <- c("G47", "G471", "G472", "G473")

# Fetch each sector individually to avoid API issues
all_turnover <- list()

for (nace in nace_sectors) {
  cat("  Fetching", nace, "...\n")

  raw <- tryCatch({
    eurostat::get_eurostat(
      "sts_trtu_m",
      filters = list(
        s_adj = "SCA",
        indic_bt = "NETTUR",
        unit = "I15",
        nace_r2 = nace,
        geo = countries
      ),
      time_format = "date",
      cache = FALSE
    )
  }, error = function(e) {
    cat("    eurostat package error:", e$message, "\n")
    cat("    Trying direct API...\n")

    # Fallback: direct API with individual country fetches
    results <- list()
    for (geo in countries) {
      url <- paste0(
        "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/sts_trtu_m?",
        "freq=M&s_adj=SCA&indic_bt=TOVT&nace_r2=", nace,
        "&unit=I15&geo=", geo,
        "&startPeriod=2010-01&endPeriod=2023-12"
      )

      resp <- httr::GET(url, httr::timeout(60))
      if (httr::status_code(resp) == 200) {
        json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))

        # Parse JSON-stat 2.0 format
        values <- json$value
        time_dim <- json$dimension$time$category$index
        time_labels <- names(sort(unlist(time_dim)))

        if (length(values) > 0) {
          df <- data.frame(
            geo = geo,
            nace_r2 = nace,
            TIME_PERIOD = as.Date(paste0(time_labels, "-01")),
            values = as.numeric(unlist(values)),
            stringsAsFactors = FALSE
          )
          results[[geo]] <- df
        }
      }
      Sys.sleep(0.3)
    }
    if (length(results) > 0) bind_rows(results) else NULL
  })

  if (!is.null(raw) && nrow(raw) > 0) {
    # Standardize column names
    if ("TIME_PERIOD" %in% names(raw)) {
      clean <- raw %>%
        mutate(
          country = as.character(geo),
          nace = as.character(nace_r2),
          date = as.Date(TIME_PERIOD),
          value = as.numeric(values)
        )
    } else if ("time" %in% names(raw)) {
      clean <- raw %>%
        mutate(
          country = as.character(geo),
          nace = as.character(nace_r2),
          date = as.Date(time),
          value = as.numeric(values)
        )
    } else {
      clean <- raw %>%
        rename_with(tolower) %>%
        mutate(
          country = as.character(geo),
          nace = nace,
          date = as.Date(time_period),
          value = as.numeric(values)
        )
    }

    clean <- clean %>%
      filter(!is.na(value), !is.na(date)) %>%
      mutate(
        year = year(date),
        month = month(date)
      ) %>%
      filter(year >= 2010, year <= 2023) %>%
      select(country, nace, date, year, month, value)

    all_turnover[[nace]] <- clean
    cat("    Got", nrow(clean), "observations for", n_distinct(clean$country), "countries\n")
  } else {
    stop("FATAL: No data returned for sector ", nace,
         "\nPivot research question or fix the source.")
  }

  Sys.sleep(1)
}

turnover_df <- bind_rows(all_turnover)

cat("\nRetail turnover data:", nrow(turnover_df), "observations\n")
cat("Countries:", n_distinct(turnover_df$country), "\n")
cat("Sectors:", n_distinct(turnover_df$nace), "\n")
cat("Date range:", as.character(min(turnover_df$date)), "to",
    as.character(max(turnover_df$date)), "\n")

# ============================================================
# 2. GOVERNMENT REVENUE / TAX DATA (GOV_10A_TAXAG)
# Annual, for VAT mechanism test
# ============================================================

cat("\nFetching government tax revenue data...\n")

tax_df <- tryCatch({
  raw <- eurostat::get_eurostat(
    "gov_10a_taxag",
    filters = list(
      na_item = "D211",
      unit = "MIO_EUR",
      sector = "S13",
      geo = countries
    ),
    time_format = "date",
    cache = FALSE
  )

  raw %>%
    mutate(
      country = as.character(geo),
      vat_revenue = as.numeric(values),
      year = year(as.Date(TIME_PERIOD))
    ) %>%
    filter(year >= 2008, year <= 2023, !is.na(vat_revenue)) %>%
    select(country, year, vat_revenue)
}, error = function(e) {
  cat("  eurostat package error:", e$message, "\n")
  cat("  Trying direct API for VAT data...\n")

  results <- list()
  for (geo in countries) {
    url <- paste0(
      "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/gov_10a_taxag?",
      "freq=A&na_item=D211&unit=MIO_EUR&sector=S13&geo=", geo,
      "&startPeriod=2008&endPeriod=2023"
    )
    resp <- httr::GET(url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
      values <- json$value
      time_dim <- json$dimension$time$category$index
      time_labels <- names(sort(unlist(time_dim)))
      if (length(values) > 0) {
        df <- data.frame(
          country = geo,
          year = as.integer(time_labels),
          vat_revenue = as.numeric(unlist(values)),
          stringsAsFactors = FALSE
        )
        results[[geo]] <- df
      }
    }
    Sys.sleep(0.3)
  }
  if (length(results) > 0) bind_rows(results) else stop("VAT data unavailable")
})

cat("VAT revenue data:", nrow(tax_df), "observations\n")

# ============================================================
# 3. GDP DATA (for matching covariates) — Direct API
# ============================================================

cat("\nFetching GDP data for SCM covariates...\n")

gdp_results <- list()
for (geo in countries) {
  url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/nama_10_pc?",
    "freq=A&na_item=B1GQ&unit=CP_EUR_HAB&geo=", geo,
    "&startPeriod=2008&endPeriod=2023"
  )
  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) == 200) {
    json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    vals <- json$value
    time_dim <- json$dimension$time$category$index
    time_labels <- names(sort(unlist(time_dim)))
    if (length(vals) > 0) {
      val_indices <- as.integer(names(vals))
      val_values <- as.numeric(unlist(vals))
      gdp_results[[geo]] <- data.frame(
        country = geo,
        year = as.integer(time_labels[val_indices + 1]),
        gdp_pc = val_values,
        stringsAsFactors = FALSE
      )
    }
  }
  Sys.sleep(0.2)
}
gdp_df <- bind_rows(gdp_results) %>% filter(!is.na(gdp_pc))

cat("GDP data:", nrow(gdp_df), "observations for", n_distinct(gdp_df$country), "countries\n")

# ============================================================
# 3b. TOTAL GDP (for VAT-to-GDP ratio) — Direct API
# nama_10_gdp, indicator B1GQ (GDP at market prices), CP_MEUR (current prices, millions EUR)
# ============================================================

cat("\nFetching total GDP data for VAT-to-GDP ratio...\n")

gdp_total_results <- list()
for (geo in countries) {
  url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/nama_10_gdp?",
    "freq=A&na_item=B1GQ&unit=CP_MEUR&geo=", geo,
    "&startPeriod=2008&endPeriod=2023"
  )
  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) == 200) {
    json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    vals <- json$value
    time_dim <- json$dimension$time$category$index
    time_labels <- names(sort(unlist(time_dim)))
    if (length(vals) > 0) {
      val_indices <- as.integer(names(vals))
      val_values <- as.numeric(unlist(vals))
      gdp_total_results[[geo]] <- data.frame(
        country = geo,
        year = as.integer(time_labels[val_indices + 1]),
        gdp_total = val_values,
        stringsAsFactors = FALSE
      )
    }
  }
  Sys.sleep(0.2)
}
gdp_total_df <- bind_rows(gdp_total_results) %>% filter(!is.na(gdp_total))

cat("Total GDP data:", nrow(gdp_total_df), "observations for",
    n_distinct(gdp_total_df$country), "countries\n")

# ============================================================
# 4. UNEMPLOYMENT (for matching covariates) — Direct API
# ============================================================

cat("\nFetching unemployment data...\n")

unemp_results <- list()
for (geo in countries) {
  url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/une_rt_a?",
    "freq=A&age=Y15-74&sex=T&unit=PC_ACT&geo=", geo,
    "&startPeriod=2008&endPeriod=2023"
  )
  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) == 200) {
    json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    vals <- json$value
    time_dim <- json$dimension$time$category$index
    time_labels <- names(sort(unlist(time_dim)))
    if (length(vals) > 0) {
      # JSON-stat: values are sparse — indices are character keys
      val_indices <- as.integer(names(vals))
      val_values <- as.numeric(unlist(vals))
      df <- data.frame(
        country = geo,
        year = as.integer(time_labels[val_indices + 1]),
        unemp_rate = val_values,
        stringsAsFactors = FALSE
      )
      unemp_results[[geo]] <- df
    }
  }
  Sys.sleep(0.2)
}
unemp_df <- bind_rows(unemp_results) %>%
  filter(!is.na(unemp_rate)) %>%
  mutate(
    month = 6L,
    date = as.Date(paste0(year, "-06-01"))
  )

cat("Unemployment data:", nrow(unemp_df), "observations\n")

# ============================================================
# 5. SAVE ALL DATA
# ============================================================

fwrite(turnover_df, file.path(data_dir, "retail_turnover.csv"))
fwrite(tax_df, file.path(data_dir, "vat_revenue.csv"))
fwrite(gdp_df, file.path(data_dir, "gdp_per_capita.csv"))
fwrite(gdp_total_df, file.path(data_dir, "gdp_total.csv"))
fwrite(unemp_df, file.path(data_dir, "unemployment.csv"))

cat("\n=== DATA FETCH COMPLETE ===\n")

# ============================================================
# DATA VALIDATION (required)
# ============================================================

stopifnot("Expected 10+ countries in turnover data" =
            n_distinct(turnover_df$country) >= 10)
stopifnot("Greece must be in turnover data" =
            "EL" %in% turnover_df$country)
stopifnot("Expected G47 aggregate sector" =
            "G47" %in% turnover_df$nace)
stopifnot("Expected subsectors" =
            all(c("G471", "G472", "G473") %in% turnover_df$nace))
stopifnot("Expected data before treatment (pre-2015)" =
            any(turnover_df$year < 2015))
stopifnot("Expected data after treatment (post-2015)" =
            any(turnover_df$year > 2015))

# Verify the capital controls shock is visible
greece_g47 <- turnover_df %>%
  filter(country == "EL", nace == "G47",
         year == 2015, month %in% c(6, 7))
if (nrow(greece_g47) == 2) {
  june_val <- greece_g47$value[greece_g47$month == 6]
  july_val <- greece_g47$value[greece_g47$month == 7]
  pct_drop <- (july_val - june_val) / june_val * 100
  cat(sprintf("\nCapital controls shock visible: June=%.1f, July=%.1f (%.1f%%)\n",
              june_val, july_val, pct_drop))
  stopifnot("Expected negative shock in July 2015" = pct_drop < 0)
}

cat("\nData validation passed:",
    nrow(turnover_df), "turnover obs,",
    n_distinct(turnover_df$country), "countries,",
    n_distinct(turnover_df$nace), "sectors\n")
