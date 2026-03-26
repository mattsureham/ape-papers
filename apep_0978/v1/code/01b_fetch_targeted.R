## 01b_fetch_targeted.R — Fetch specific cultivated land variables from e-Stat
## apep_0978: From Rice Paddies to Solar Panels

source("00_packages.R")

## Load API key
envs <- readLines("../../../../.env", warn = FALSE)
for (line in envs) {
  if (grepl("^ESTAT_APP_ID=", line)) {
    Sys.setenv(ESTAT_APP_ID = sub("^ESTAT_APP_ID=", "", line))
  }
}
estat_key <- Sys.getenv("ESTAT_APP_ID")
stopifnot(nchar(estat_key) > 0)

## -------------------------------------------------------------------------
## Fetch from table 0000010103 (Japan Statistical Yearbook, Economic Base)
## Target categories:
##   C3107:   Cultivated land area (total)
##   C310701: Cultivated land area (Paddy fields)
##   C310702: Cultivated land area (Fields/upland)
##   C310703: Cultivated land (Ordinary fields)
##   C310704: Cultivated land (Land under permanent crops)
##   C310705: Cultivated land (Use for meadows)
##   C3108:   Area of converted farm land
##   C3109:   Area of abandoned cropland
##   C3102:   Number of farm households
##   C310201: Commercial farm households
## Also grab population (A1101) for controls
## -------------------------------------------------------------------------

target_cats <- c("C3107", "C310701", "C310702", "C310703", "C310704",
                 "C310705", "C3108", "C3109", "C3102", "C310201",
                 "A1101")  # Total population

cat("Fetching cultivated land data from e-Stat table 0000010103...\n")

resp <- httr::GET(
  "https://api.e-stat.go.jp/rest/3.0/app/json/getStatsData",
  query = list(
    appId = estat_key,
    statsDataId = "0000010103",
    cdCat01 = paste(target_cats, collapse = ","),
    lang = "E",
    limit = 50000
  )
)

stopifnot(httr::status_code(resp) == 200)
content <- httr::content(resp, as = "text", encoding = "UTF-8")
parsed <- jsonlite::fromJSON(content, simplifyVector = FALSE)

status <- parsed$GET_STATS_DATA$RESULT$STATUS
if (!is.null(status) && status != 0) {
  stop(sprintf("API error: %s", parsed$GET_STATS_DATA$RESULT$ERROR_MSG))
}

values <- parsed$GET_STATS_DATA$STATISTICAL_DATA$DATA_INF$VALUE
cat(sprintf("Received %d records\n", length(values)))

## Parse into data frame
df_raw <- bind_rows(lapply(values, function(v) as_tibble(v)))
cat(sprintf("Parsed: %d rows x %d cols\n", nrow(df_raw), ncol(df_raw)))

## -------------------------------------------------------------------------
## Parse codes into readable labels
## -------------------------------------------------------------------------

## Category labels
cat_labels <- c(
  "C3107" = "cultivated_land_total",
  "C310701" = "paddy_area",
  "C310702" = "field_area",
  "C310703" = "ordinary_field",
  "C310704" = "permanent_crop",
  "C310705" = "meadow",
  "C3108" = "converted_farmland",
  "C3109" = "abandoned_cropland",
  "C3102" = "farm_households_total",
  "C310201" = "farm_households_commercial",
  "A1101" = "population"
)

## Prefecture codes (all 47 + national)
pref_codes <- c(
  "00000" = "All Japan",
  "01000" = "Hokkaido", "02000" = "Aomori", "03000" = "Iwate",
  "04000" = "Miyagi", "05000" = "Akita", "06000" = "Yamagata",
  "07000" = "Fukushima", "08000" = "Ibaraki", "09000" = "Tochigi",
  "10000" = "Gunma", "11000" = "Saitama", "12000" = "Chiba",
  "13000" = "Tokyo", "14000" = "Kanagawa", "15000" = "Niigata",
  "16000" = "Toyama", "17000" = "Ishikawa", "18000" = "Fukui",
  "19000" = "Yamanashi", "20000" = "Nagano", "21000" = "Gifu",
  "22000" = "Shizuoka", "23000" = "Aichi", "24000" = "Mie",
  "25000" = "Shiga", "26000" = "Kyoto", "27000" = "Osaka",
  "28000" = "Hyogo", "29000" = "Nara", "30000" = "Wakayama",
  "31000" = "Tottori", "32000" = "Shimane", "33000" = "Okayama",
  "34000" = "Hiroshima", "35000" = "Yamaguchi", "36000" = "Tokushima",
  "37000" = "Kagawa", "38000" = "Ehime", "39000" = "Kochi",
  "40000" = "Fukuoka", "41000" = "Saga", "42000" = "Nagasaki",
  "43000" = "Kumamoto", "44000" = "Oita", "45000" = "Miyazaki",
  "46000" = "Kagoshima", "47000" = "Okinawa"
)

## Parse time codes: "2005100000" -> 2005
df <- df_raw %>%
  mutate(
    variable = cat_labels[`@cat01`],
    prefecture = pref_codes[`@area`],
    year = as.integer(substr(`@time`, 1, 4)),
    value = as.numeric(`$`),
    area_code = `@area`
  ) %>%
  filter(!is.na(variable), !is.na(prefecture)) %>%
  select(year, area_code, prefecture, variable, value)

cat(sprintf("After parsing: %d observations\n", nrow(df)))
cat(sprintf("Years: %d to %d\n", min(df$year), max(df$year)))
cat(sprintf("Prefectures: %d unique\n", n_distinct(df$prefecture)))
cat(sprintf("Variables: %s\n", paste(unique(df$variable), collapse = ", ")))

## -------------------------------------------------------------------------
## Pivot to wide format (one row per prefecture-year)
## -------------------------------------------------------------------------

df_wide <- df %>%
  filter(prefecture != "All Japan") %>%
  pivot_wider(names_from = variable, values_from = value) %>%
  arrange(area_code, year)

cat(sprintf("\nWide panel: %d rows (pref-year) x %d cols\n", nrow(df_wide), ncol(df_wide)))

## -------------------------------------------------------------------------
## Add FIT rate schedule
## -------------------------------------------------------------------------
fit_rates <- tibble(
  year = 2012:2022,
  fit_rate = c(40, 36, 32, 29, 27, 24, 21, 18, 14, 12, 11)
)

## Pre-FIT years get rate 0
df_wide <- df_wide %>%
  left_join(fit_rates, by = "year") %>%
  mutate(fit_rate = replace_na(fit_rate, 0))

## -------------------------------------------------------------------------
## Compute treatment intensity
## -------------------------------------------------------------------------

## Pre-FIT upland share (using 2011 or latest available pre-2012)
pre_fit_shares <- df_wide %>%
  filter(year <= 2011, year >= 2009) %>%
  group_by(area_code, prefecture) %>%
  summarize(
    pre_upland_share = mean(field_area / cultivated_land_total, na.rm = TRUE),
    pre_cultivated = mean(cultivated_land_total, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== Pre-FIT Upland Shares (2009-2011 avg) ===\n")
cat(sprintf("Prefectures with data: %d\n", nrow(pre_fit_shares)))

## Show range
if (nrow(pre_fit_shares) > 0) {
  shares_sorted <- pre_fit_shares %>% arrange(pre_upland_share)
  cat("Lowest upland share:\n")
  print(head(shares_sorted %>% select(prefecture, pre_upland_share), 5))
  cat("Highest upland share:\n")
  print(tail(shares_sorted %>% select(prefecture, pre_upland_share), 5))
}

## Merge back
df_panel <- df_wide %>%
  left_join(pre_fit_shares %>% select(area_code, pre_upland_share, pre_cultivated),
            by = "area_code")

## Treatment intensity: FIT rate x upland share
df_panel <- df_panel %>%
  mutate(
    treatment_intensity = fit_rate * pre_upland_share,
    ## Outcome: log cultivated land
    log_cultivated = log(cultivated_land_total),
    ## Change in cultivated land (% relative to 2011)
    post_fit = as.integer(year >= 2012),
    ## Upland share (time-varying)
    upland_share = field_area / cultivated_land_total
  )

## -------------------------------------------------------------------------
## Save
## -------------------------------------------------------------------------
write_csv(df_panel, "../data/analysis_panel.csv")
cat(sprintf("\nSaved analysis panel: %d rows\n", nrow(df_panel)))

## Quick diagnostics
cat("\n=== Panel diagnostics ===\n")
cat(sprintf("Prefectures: %d\n", n_distinct(df_panel$prefecture)))
cat(sprintf("Years: %d to %d\n", min(df_panel$year), max(df_panel$year)))
cat(sprintf("Pre-treatment years (pre-2012): %d\n",
            n_distinct(df_panel$year[df_panel$year < 2012])))
cat(sprintf("Post-treatment years (2012+): %d\n",
            n_distinct(df_panel$year[df_panel$year >= 2012])))

## Check for missing values
cat("\nMissing values:\n")
for (col in c("cultivated_land_total", "paddy_area", "field_area",
              "converted_farmland", "abandoned_cropland")) {
  n_miss <- sum(is.na(df_panel[[col]]))
  cat(sprintf("  %s: %d missing\n", col, n_miss))
}

## Sample data
cat("\nSample (Hokkaido, 2010-2014):\n")
print(df_panel %>%
        filter(prefecture == "Hokkaido", year %in% 2010:2014) %>%
        select(year, prefecture, cultivated_land_total, paddy_area, field_area,
               pre_upland_share, fit_rate, treatment_intensity))
