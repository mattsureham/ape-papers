# 01_fetch_data.R — Fetch FRA crossing data and Zillow ZHVI
# apep_0785: Quiet zone designations and property values

source("00_packages.R")

cat("=== Step 1: Fetch FRA Grade Crossing Inventory ===\n")

# FRA Highway-Rail Crossing Inventory via data.transportation.gov SODA API
# Dataset: m2f8-22s6 (Form 71 - Current)
base_url <- "https://data.transportation.gov/resource/m2f8-22s6.json"

# Select only fields we need to reduce transfer size
select_fields <- paste0(
  "crossingid,statecode,statename,citycode,cityname,countyname,",
  "crossingtypecode,crossingtype,crossingpositioncode,crossingposition,",
  "whistlebancode,whistleban,whistledate,",
  "railroadcode,railroadname,",
  "totaldaylightthrutrains,totalnighttimethrutrains,totalswitchingtrains,",
  "numberofmaintracks,annualaveragedailytrafficcount,",
  "maximumtimetablespeed,crossingclosed"
)

all_crossings <- list()
offset <- 0
batch_size <- 50000
repeat {
  url <- paste0(base_url,
                "?$limit=", format(batch_size, scientific = FALSE),
                "&$offset=", format(offset, scientific = FALSE),
                "&$select=", select_fields)

  cat("Fetching offset", offset, "...\n")
  resp <- GET(url, timeout(180))

  if (status_code(resp) != 200) {
    stop("FRA API returned status ", status_code(resp), ": ", content(resp, "text"))
  }

  batch <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  if (is.null(batch) || nrow(batch) == 0) break

  all_crossings[[length(all_crossings) + 1]] <- batch
  cat("  Got", nrow(batch), "records\n")

  if (nrow(batch) < batch_size) break
  offset <- offset + batch_size
}

crossings_raw <- bind_rows(all_crossings)
cat("Total crossings fetched:", nrow(crossings_raw), "\n")
stopifnot("No crossing data returned" = nrow(crossings_raw) > 0)

saveRDS(crossings_raw, "../data/fra_crossings_raw.rds")

cat("\n=== Step 2: Identify Quiet Zone Crossings ===\n")

cat("Whistle ban code distribution:\n")
print(table(crossings_raw$whistlebancode, useNA = "always"))

cat("\nCrossing type distribution:\n")
print(table(crossings_raw$crossingtype, useNA = "always"))

# Filter to public at-grade crossings that are NOT closed
public_crossings <- crossings_raw %>%
  filter(crossingtypecode %in% c("3", 3)) %>%
  filter(crossingpositioncode %in% c("1", 1)) %>%
  filter(is.na(crossingclosed) | crossingclosed != "Yes") %>%
  mutate(
    # whistlebancode: 0=No, 1=24hr, 2=Partial, 3=Chicago Excused
    is_quiet_zone = whistlebancode %in% c("1", "2", "3"),
    total_trains = as.numeric(totaldaylightthrutrains) +
                   as.numeric(totalnighttimethrutrains) +
                   as.numeric(totalswitchingtrains),
    aadt = as.numeric(annualaveragedailytrafficcount),
    max_speed = as.numeric(maximumtimetablespeed)
  )

cat("Public at-grade open crossings:", nrow(public_crossings), "\n")
cat("Quiet zone crossings:", sum(public_crossings$is_quiet_zone, na.rm = TRUE), "\n")

# Extract quiet zone effective dates
qz_crossings <- public_crossings %>%
  filter(is_quiet_zone) %>%
  mutate(
    qz_date = as.Date(substr(whistledate, 1, 10))
  ) %>%
  filter(!is.na(qz_date), qz_date > as.Date("2000-01-01"))

cat("Quiet zone crossings with valid post-2000 dates:", nrow(qz_crossings), "\n")

# Aggregate to city level — first quiet zone date per city
city_qz <- qz_crossings %>%
  mutate(
    state_clean = str_to_title(str_trim(statename)),
    city_clean = str_to_title(str_trim(cityname))
  ) %>%
  group_by(state_clean, city_clean) %>%
  summarise(
    first_qz_date = min(qz_date, na.rm = TRUE),
    n_qz_crossings = n(),
    avg_trains_qz = mean(total_trains, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.na(first_qz_date))

cat("Cities with quiet zones:", nrow(city_qz), "\n")
cat("Date range:", as.character(min(city_qz$first_qz_date)), "to",
    as.character(max(city_qz$first_qz_date)), "\n")
cat("\nQuiet zone designation by year:\n")
print(table(year(city_qz$first_qz_date)))
cat("\nTop states by QZ cities:\n")
print(head(sort(table(city_qz$state_clean), decreasing = TRUE), 15))

# All cities with public at-grade crossings (for control group)
city_crossings <- public_crossings %>%
  mutate(
    state_clean = str_to_title(str_trim(statename)),
    city_clean = str_to_title(str_trim(cityname))
  ) %>%
  group_by(state_clean, city_clean) %>%
  summarise(
    n_public_crossings = n(),
    avg_trains = mean(total_trains, na.rm = TRUE),
    avg_aadt = mean(aadt, na.rm = TRUE),
    .groups = "drop"
  )

cat("Total cities with public at-grade crossings:", nrow(city_crossings), "\n")

saveRDS(city_qz, "../data/city_quiet_zones.rds")
saveRDS(city_crossings, "../data/city_crossings.rds")

cat("\n=== Step 3: Fetch Zillow ZHVI Data ===\n")

# Zillow ZHVI — city level, all homes, smoothed, seasonally adjusted
zhvi_url <- "https://files.zillowstatic.com/research/public_csvs/zhvi/City_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv"

cat("Downloading Zillow ZHVI city-level data...\n")
zhvi_file <- "../data/zhvi_city.csv"
download.file(zhvi_url, zhvi_file, mode = "wb", quiet = TRUE)

zhvi_wide <- fread(zhvi_file)
cat("ZHVI dimensions:", nrow(zhvi_wide), "cities x", ncol(zhvi_wide), "columns\n")

# Reshape to long format
id_cols <- c("RegionID", "SizeRank", "RegionName", "RegionType", "StateName",
             "State", "Metro", "CountyName")
date_cols <- setdiff(names(zhvi_wide), id_cols)

zhvi_long <- zhvi_wide %>%
  pivot_longer(
    cols = all_of(date_cols),
    names_to = "date_str",
    values_to = "zhvi"
  ) %>%
  mutate(
    date = ymd(date_str),
    year = year(date),
    month = month(date),
    city_clean = RegionName,
    state_clean = StateName
  ) %>%
  filter(!is.na(zhvi), !is.na(date))

cat("ZHVI long format:", nrow(zhvi_long), "observations\n")
cat("Date range:", as.character(min(zhvi_long$date)), "to",
    as.character(max(zhvi_long$date)), "\n")
cat("Unique cities:", n_distinct(zhvi_long$RegionID), "\n")

saveRDS(zhvi_long, "../data/zhvi_long.rds")

cat("\n=== Data fetch complete ===\n")
