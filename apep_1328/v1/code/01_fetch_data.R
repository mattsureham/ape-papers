## 01_fetch_data.R — Fetch World Bank WDI data for 9 European countries

source("00_packages.R")

# ── Countries ─────────────────────────────────────────────────────────────────
# Treated: Estonia (EST)
# Primary controls: Latvia (LVA), Lithuania (LTU)
# SCM donors: Finland (FIN), Czech Republic (CZE), Poland (POL),
#             Denmark (DNK), Sweden (SWE), Norway (NOR)
countries <- c("EST", "LVA", "LTU", "FIN", "CZE", "POL", "DNK", "SWE", "NOR")

# ── Indicators ────────────────────────────────────────────────────────────────
indicators <- c(
  "IC.BUS.NDNS.ZS",   # New business density (per 1,000 working-age pop)
  "IC.BUS.NREG",       # New business registrations (absolute)
  "NY.GDP.PCAP.KD",    # GDP per capita (constant 2015 USD)
  "NE.TRD.GNFS.ZS",   # Trade openness (% GDP)
  "IT.NET.USER.ZS",    # Internet users (% population)
  "SP.POP.1564.TO"     # Working-age population (15-64)
)

# ── Fetch function ────────────────────────────────────────────────────────────
fetch_wb <- function(indicator, countries, date_range = "2004:2023") {
  country_str <- paste(countries, collapse = ";")
  url <- sprintf(
    "https://api.worldbank.org/v2/country/%s/indicator/%s?date=%s&format=json&per_page=500",
    country_str, indicator, date_range
  )

  resp <- httr::GET(url)
  if (httr::status_code(resp) != 200) {
    stop(sprintf("World Bank API returned status %d for %s", httr::status_code(resp), indicator))
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed  <- jsonlite::fromJSON(content, flatten = TRUE)

  if (length(parsed) < 2 || is.null(parsed[[2]])) {
    stop(sprintf("No data returned for indicator %s", indicator))
  }

  df <- as.data.frame(parsed[[2]])

  # Debug: show column names for first call
  cat(sprintf("    Columns: %s\n", paste(names(df), collapse = ", ")))

  # World Bank API v2 returns "countryiso3code" and "date" (or similar)
  # Find the right columns
  iso_col <- grep("countryiso3code|country.id", names(df), value = TRUE)[1]
  date_col <- grep("^date$", names(df), value = TRUE)[1]
  val_col <- grep("^value$", names(df), value = TRUE)[1]

  if (is.na(iso_col) || is.na(date_col) || is.na(val_col)) {
    stop(sprintf("Could not find expected columns. Found: %s", paste(names(df), collapse = ", ")))
  }

  result <- data.frame(
    iso3 = df[[iso_col]],
    year = as.integer(df[[date_col]]),
    stringsAsFactors = FALSE
  )
  result[[indicator]] <- as.numeric(df[[val_col]])
  return(result)
}

# ── Fetch all indicators ─────────────────────────────────────────────────────
cat("Fetching World Bank indicators...\n")
all_data <- NULL

for (ind in indicators) {
  cat(sprintf("  Fetching %s...\n", ind))
  df <- fetch_wb(ind, countries, "2004:2023")
  if (is.null(all_data)) {
    all_data <- df
  } else {
    all_data <- merge(all_data, df, by = c("iso3", "year"), all = TRUE)
  }
  Sys.sleep(0.5)  # be polite to API
}

# ── Validate ──────────────────────────────────────────────────────────────────
stopifnot("Data must have rows" = nrow(all_data) > 0)

# Check Estonia has business density data
est_biz <- all_data[all_data$iso3 == "EST" & !is.na(all_data$IC.BUS.NDNS.ZS), ]
stopifnot("Estonia must have business density data" = nrow(est_biz) >= 5)

cat(sprintf("\nFetched %d rows across %d countries.\n", nrow(all_data), length(unique(all_data$iso3))))
cat(sprintf("Estonia business density: %d year-obs\n", nrow(est_biz)))
cat(sprintf("Year range: %d to %d\n", min(all_data$year), max(all_data$year)))

# ── E-Residency aggregate data (from public dashboard) ───────────────────────
# Source: https://e-resident.gov.ee/dashboard/
# These are cumulative figures as of various snapshots
eresidency <- data.frame(
  year = 2015:2024,
  e_residents_cumulative = c(1727, 14135, 27727, 45896, 61263, 72060, 82917, 96809, 111174, 128000),
  e_resident_firms_cumulative = c(503, 3410, 6962, 10543, 14261, 17563, 21133, 26536, 33034, 39000),
  stringsAsFactors = FALSE
)

# Compute annual new e-resident firms
eresidency$new_e_firms <- c(eresidency$e_resident_firms_cumulative[1],
                            diff(eresidency$e_resident_firms_cumulative))
eresidency$new_e_residents <- c(eresidency$e_residents_cumulative[1],
                                diff(eresidency$e_residents_cumulative))

cat(sprintf("\nE-Residency data: %d years (2015-2024)\n", nrow(eresidency)))
cat(sprintf("Total e-residents by 2024: %s\n", scales::comma(max(eresidency$e_residents_cumulative))))
cat(sprintf("Total e-resident firms by 2024: %s\n", scales::comma(max(eresidency$e_resident_firms_cumulative))))

# ── Save ──────────────────────────────────────────────────────────────────────
saveRDS(all_data, "../data/wb_panel.rds")
saveRDS(eresidency, "../data/eresidency.rds")

cat("\nData saved to data/wb_panel.rds and data/eresidency.rds\n")
