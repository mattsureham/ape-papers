## 01_fetch_data.R — Fetch data from e-Stat API and construct treatment variable
## apep_0976: Yakuza Exclusion Ordinances and Real Estate Markets

source("00_packages.R")

# ── e-Stat API configuration ─────────────────────────────────────────
estat_app_id <- Sys.getenv("ESTAT_APP_ID")
if (estat_app_id == "") {
  env_file <- file.path(Sys.getenv("HOME"), "auto-policy-evals", ".env")
  if (file.exists(env_file)) {
    lines <- readLines(env_file, warn = FALSE)
    for (line in lines) {
      if (grepl("^ESTAT_APP_ID=", line)) {
        estat_app_id <- sub("^ESTAT_APP_ID=", "", line)
        break
      }
    }
  }
}
stopifnot("ESTAT_APP_ID not found" = nchar(estat_app_id) > 0)

# ── Helper: fetch single indicator from e-Stat ────────────────────────
fetch_indicator <- function(table_id, cat01_code, label) {
  base_url <- "https://api.e-stat.go.jp/rest/3.0/app/json/getStatsData"
  cat("  Fetching", label, "(", cat01_code, ") ...\n")

  res <- GET(base_url, query = list(
    appId = estat_app_id,
    statsDataId = table_id,
    cdCat01 = cat01_code,
    limit = 10000
  ), timeout(120))

  stopifnot("API request failed" = status_code(res) == 200)
  data <- fromJSON(content(res, as = "text", encoding = "UTF-8"),
                   simplifyDataFrame = TRUE)

  values <- data$GET_STATS_DATA$STATISTICAL_DATA$DATA_INF$VALUE
  if (is.null(values) || nrow(values) == 0) {
    stop("No data returned for ", cat01_code)
  }

  result <- as_tibble(values) %>%
    select(area = `@area`, time = `@time`, value = `$`) %>%
    mutate(
      # Parse fiscal year from time code (format: "2010100000" -> 2010)
      fy = as.integer(substr(time, 1, 4)),
      # Parse prefecture code (format: "13000" -> "13")
      pref_code = sprintf("%02d", as.integer(substr(area, 1, 2))),
      value = suppressWarnings(as.numeric(value)),
      indicator = label
    ) %>%
    filter(
      pref_code != "00",  # Exclude national total
      fy >= 2003, fy <= 2019  # Study period
    ) %>%
    select(pref_code, fy, indicator, value)

  cat("    Got", nrow(result), "observations,", n_distinct(result$pref_code),
      "prefectures,", min(result$fy), "-", max(result$fy), "\n")
  return(result)
}

# ── 1. Fetch economic indicators (table C: Economic Base) ─────────────
cat("\n=== Fetching economic indicators ===\n")
land_price <- fetch_indicator("0000010103", "C5401",
                              "land_price_residential")
land_price_chg <- fetch_indicator("0000010103", "C5501",
                                  "land_price_change_pct")
building_starts <- fetch_indicator("0000010103", "C3301",
                                   "building_starts")
# Real estate GDP share
re_gdp <- fetch_indicator("0000010103", "C110211",
                          "gdp_real_estate")

# ── 2. Fetch crime indicators (table K: Safety) ──────────────────────
cat("\n=== Fetching crime indicators ===\n")
crime_total <- fetch_indicator("0000010111", "K4201",
                               "crime_reported")
crime_violent <- fetch_indicator("0000010111", "K420101",
                                "crime_violent")
crime_rough <- fetch_indicator("0000010111", "K420102",
                               "crime_rough")
crime_theft <- fetch_indicator("0000010111", "K420103",
                               "crime_theft")

# ── 3. Fetch population (table A: Population) ────────────────────────
cat("\n=== Fetching population ===\n")
population <- fetch_indicator("0000010101", "A1101",
                              "population")

# ── 4. Stack all indicators ──────────────────────────────────────────
all_data <- bind_rows(
  land_price, land_price_chg, building_starts, re_gdp,
  crime_total, crime_violent, crime_rough, crime_theft,
  population
)

cat("\n=== All indicators stacked:", nrow(all_data), "rows ===\n")
cat("Indicators:\n")
print(all_data %>% group_by(indicator) %>%
        summarise(n = n(), min_fy = min(fy), max_fy = max(fy),
                  n_pref = n_distinct(pref_code), .groups = "drop"))

# ── 5. YEO adoption dates (Hoshino & Kamada 2020, Table 1) ──────────
# Source: "Enforcement against Organized Crime Fosters Illegal Markets:
# Evidence from the Yakuza" (NHH Working Paper version)
# Published as Hoshino & Kamada (2020), J. Quantitative Criminology
yeo_dates <- tribble(
  ~pref_code, ~pref_name_en,  ~yeo_date,
  "01", "Hokkaido",     "2011-04",
  "02", "Aomori",       "2011-07",
  "03", "Iwate",        "2011-07",
  "04", "Miyagi",       "2011-04",
  "05", "Akita",        "2011-07",
  "06", "Yamagata",     "2011-08",
  "07", "Fukushima",    "2011-07",
  "08", "Ibaraki",      "2011-04",
  "09", "Tochigi",      "2011-04",
  "10", "Gunma",        "2011-04",
  "11", "Saitama",      "2011-08",
  "12", "Chiba",        "2011-09",
  "13", "Tokyo",        "2011-10",
  "14", "Kanagawa",     "2011-04",
  "15", "Niigata",      "2011-08",
  "16", "Toyama",       "2011-08",
  "17", "Ishikawa",     "2011-08",
  "18", "Fukui",        "2011-04",
  "19", "Yamanashi",    "2011-04",
  "20", "Nagano",       "2011-09",
  "21", "Gifu",         "2011-04",
  "22", "Shizuoka",     "2011-08",
  "23", "Aichi",        "2011-04",
  "24", "Mie",          "2011-04",
  "25", "Shiga",        "2011-08",
  "26", "Kyoto",        "2011-04",
  "27", "Osaka",        "2011-04",
  "28", "Hyogo",        "2011-04",
  "29", "Nara",         "2011-07",
  "30", "Wakayama",     "2011-07",
  "31", "Tottori",      "2011-04",
  "32", "Shimane",      "2011-04",
  "33", "Okayama",      "2011-04",
  "34", "Hiroshima",    "2011-04",
  "35", "Yamaguchi",    "2011-04",
  "36", "Tokushima",    "2011-04",
  "37", "Kagawa",       "2011-04",
  "38", "Ehime",        "2010-08",
  "39", "Kochi",        "2011-04",
  "40", "Fukuoka",      "2010-04",
  "41", "Saga",         "2012-01",
  "42", "Nagasaki",     "2010-04",
  "43", "Kumamoto",     "2011-04",
  "44", "Oita",         "2011-04",
  "45", "Miyazaki",     "2011-08",
  "46", "Kagoshima",    "2010-04",
  "47", "Okinawa",      "2011-10"
)

# Assign calendar year of adoption for DiD
yeo_dates <- yeo_dates %>%
  mutate(
    yeo_year = as.integer(substr(yeo_date, 1, 4)),
    yeo_month = as.integer(substr(yeo_date, 6, 7)),
    # For annual data: treatment year = calendar year of adoption
    first_treat = yeo_year
  )

cat("\n=== YEO adoption timing ===\n")
cat("Calendar year distribution:\n")
print(table(yeo_dates$first_treat))
cat("\nMonthly distribution:\n")
print(sort(table(yeo_dates$yeo_date), decreasing = TRUE))

# ── 6. Save all raw data ─────────────────────────────────────────────
save(all_data, yeo_dates, file = "../data/raw_data.RData")
cat("\n✓ All data saved to data/raw_data.RData\n")
cat("  Total observations:", nrow(all_data), "\n")
cat("  Prefectures:", n_distinct(all_data$pref_code), "\n")
cat("  Indicators:", n_distinct(all_data$indicator), "\n")
