## 01_fetch_data.R — Fetch EEA CO2 monitoring data for NL and DE
## APEP-1349: Dutch BPM Multi-Cutoff Bunching
##
## Data source: European Environment Agency, CO2 emissions from new passenger cars
## Regulation (EU) 2019/631 monitoring data
## API: https://discodata.eea.europa.eu/sql

source("00_packages.R")

# --- Configuration ---
BASE_URL <- "https://discodata.eea.europa.eu/sql"
COUNTRIES <- c("NL", "DE")
YEARS <- 2020:2022
CO2_MIN <- 1    # Skip 0 (EVs)
CO2_MAX <- 250  # ICE/PHEV range

# --- Helper: query EEA API ---
query_eea <- function(sql, retries = 3) {
  url <- paste0(BASE_URL, "?query=", URLencode(sql, reserved = TRUE))
  for (attempt in 1:retries) {
    resp <- tryCatch(
      httr::GET(url, httr::timeout(60)),
      error = function(e) NULL
    )
    if (!is.null(resp) && httr::status_code(resp) == 200) {
      content <- httr::content(resp, as = "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(content)
      if ("errors" %in% names(parsed)) {
        stop("EEA API error: ", parsed$errors$error[1])
      }
      return(parsed$results)
    }
    Sys.sleep(1)
  }
  stop("EEA API failed after ", retries, " attempts")
}

# --- Fetch CO2 frequency distributions ---
# Query COUNT(*) at each integer CO2 value per country x year
# Total: 250 values x 2 countries x 3 years = 1500 queries

cat("Fetching CO2 distributions from EEA API...\n")
cat(sprintf("Range: %d-%d g/km, Countries: %s, Years: %s\n",
            CO2_MIN, CO2_MAX, paste(COUNTRIES, collapse = "/"),
            paste(range(YEARS), collapse = "-")))

all_data <- list()

for (country in COUNTRIES) {
  for (yr in YEARS) {
    cat(sprintf("  %s %d: fetching...", country, yr))
    flush.console()
    year_counts <- integer(CO2_MAX - CO2_MIN + 1)
    names(year_counts) <- as.character(CO2_MIN:CO2_MAX)

    for (co2_val in CO2_MIN:CO2_MAX) {
      sql <- sprintf(
        "SELECT COUNT(*) as n FROM [CO2Emission].[latest].[co2cars] WHERE MS='%s' AND Year=%d AND [Ewltp (g/km)]=%d",
        country, yr, co2_val
      )
      n <- tryCatch({
        res <- query_eea(sql)
        if (is.null(res) || nrow(res) == 0) 0L else as.integer(res$n[1])
      }, error = function(e) {
        warning(sprintf("  Failed CO2=%d: %s", co2_val, e$message))
        0L
      })
      year_counts[as.character(co2_val)] <- n
    }

    year_df <- data.frame(
      co2 = CO2_MIN:CO2_MAX,
      count = as.integer(year_counts),
      country = country,
      year = yr
    )
    year_df <- year_df[year_df$count > 0, ]
    all_data[[length(all_data) + 1]] <- year_df

    cat(sprintf(" %d CO2 values, %s vehicles\n",
                nrow(year_df), format(sum(year_df$count), big.mark = ",")))
  }
}

df <- bind_rows(all_data)

# --- Also fetch fuel-type breakdown near notches (for PHEV identification) ---
cat("\nFetching fuel-type breakdown near notches...\n")
NOTCH_REGIONS <- list(
  n79 = 50:110,
  n141 = 120:170,
  n157 = 140:180
)

fuel_data <- list()
for (region_name in names(NOTCH_REGIONS)) {
  region <- NOTCH_REGIONS[[region_name]]
  cat(sprintf("  Region %s (%d-%d)...", region_name, min(region), max(region)))

  for (co2_val in region) {
    for (ft in c("PETROL", "DIESEL", "PETROL/ELECTRIC", "DIESEL/ELECTRIC")) {
      sql <- sprintf(
        "SELECT COUNT(*) as n FROM [CO2Emission].[latest].[co2cars] WHERE MS='NL' AND Year>=2020 AND [Ewltp (g/km)]=%d AND Ft='%s'",
        co2_val, ft
      )
      n <- tryCatch({
        res <- query_eea(sql)
        if (is.null(res) || nrow(res) == 0) 0L else as.integer(res$n[1])
      }, error = function(e) 0L)

      if (n > 0) {
        fuel_data[[length(fuel_data) + 1]] <- data.frame(
          co2 = co2_val, fuel_type = ft, count = n,
          region = region_name
        )
      }
    }
  }
  cat(" done\n")
}

fuel_df <- bind_rows(fuel_data)

# --- Validation ---
cat("\n=== Data Summary ===\n")
totals <- df %>% group_by(country, year) %>%
  summarise(n_co2_vals = n(), n_vehicles = sum(count), .groups = "drop")
print(totals)

nl_total <- sum(df$count[df$country == "NL"])
de_total <- sum(df$count[df$country == "DE"])

stopifnot("NL must have >100K total registrations" = nl_total > 100000)
stopifnot("DE must have >500K total registrations" = de_total > 500000)

cat(sprintf("\nNL total: %s | DE total: %s\n",
            format(nl_total, big.mark = ","), format(de_total, big.mark = ",")))

# Show bunching at key notches
cat("\n=== Bunching Preview (NL, pooled 2020-2022) ===\n")
nl_pooled <- df %>% filter(country == "NL") %>%
  group_by(co2) %>% summarise(count = sum(count), .groups = "drop")

for (notch in c(79, 101, 141, 157)) {
  below <- nl_pooled$count[nl_pooled$co2 == notch]
  above <- nl_pooled$count[nl_pooled$co2 == notch + 1]
  if (length(below) == 0) below <- 0
  if (length(above) == 0) above <- 0
  ratio <- ifelse(above > 0, below / above, Inf)
  cat(sprintf("  Notch %d: below=%d, above=%d, ratio=%.1f:1\n",
              notch, below, above, ratio))
}

# --- Save ---
saveRDS(df, "../data/co2_distributions.rds")
write_csv(df, "../data/co2_distributions.csv")
saveRDS(fuel_df, "../data/fuel_type_breakdown.rds")
write_csv(fuel_df, "../data/fuel_type_breakdown.csv")

cat("\n01_fetch_data.R complete.\n")
