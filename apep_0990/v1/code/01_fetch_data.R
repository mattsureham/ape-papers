# 01_fetch_data.R — Fetch USDA NASS data for Nebraska counties
# apep_0990: Nebraska groundwater allocations and crop adaptation

source("00_packages.R")

nass_key <- Sys.getenv("USDA_NASS_API_KEY")
if (nass_key == "") stop("USDA_NASS_API_KEY not found in environment. Set it in .env")

# --- Helper: Query NASS Quick Stats API ---
query_nass <- function(params) {
  base_url <- "https://quickstats.nass.usda.gov/api/api_GET/"
  params$key <- nass_key
  params$format <- "JSON"

  resp <- httr::GET(base_url, query = params)
  if (httr::status_code(resp) != 200) {
    stop("NASS API returned status ", httr::status_code(resp), ": ",
         httr::content(resp, "text", encoding = "UTF-8"))
  }

  content <- httr::content(resp, "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content)

  if (is.null(parsed$data) || length(parsed$data) == 0) {
    stop("NASS API returned no data for params: ",
         paste(names(params), params, sep = "=", collapse = ", "))
  }

  as_tibble(parsed$data)
}

# --- 1. Fetch county-level crop acreage for Nebraska ---
# Annual Survey data: corn, sorghum, wheat, soybeans — area harvested
cat("Fetching Nebraska crop acreage data...\n")

crops <- c("CORN", "SORGHUM", "WHEAT", "SOYBEANS")
all_crop_data <- list()

for (crop in crops) {
  cat("  Fetching", crop, "...\n")

  tryCatch({
    df <- query_nass(list(
      source_desc = "SURVEY",
      sector_desc = "CROPS",
      group_desc = "FIELD CROPS",
      commodity_desc = crop,
      statisticcat_desc = "AREA HARVESTED",
      agg_level_desc = "COUNTY",
      state_alpha = "NE",
      unit_desc = "ACRES",
      freq_desc = "ANNUAL"
    ))

    df_clean <- df %>%
      select(commodity_desc, year, county_name, county_code,
             state_fips_code, Value) %>%
      mutate(
        year = as.integer(year),
        county_fips = paste0(state_fips_code, county_code),
        value = as.numeric(gsub(",", "", Value))
      ) %>%
      filter(!is.na(value), year >= 1988, year <= 2023) %>%
      select(commodity = commodity_desc, year, county_name, county_fips, value)

    all_crop_data[[crop]] <- df_clean
    cat("    Got", nrow(df_clean), "observations for", crop, "\n")
  }, error = function(e) {
    stop("FAILED to fetch ", crop, " data: ", e$message)
  })

  Sys.sleep(1)  # rate limit
}

crop_data <- bind_rows(all_crop_data)
cat("Total crop observations:", nrow(crop_data), "\n")

# Validate: must have data
if (nrow(crop_data) < 100) {
  stop("FATAL: Insufficient crop data. Got only ", nrow(crop_data), " rows.")
}

# --- 2. Fetch irrigated vs non-irrigated breakdown from Census ---
cat("\nFetching Census irrigated/non-irrigated breakdown for corn...\n")

irrig_data <- tryCatch({
  query_nass(list(
    source_desc = "CENSUS",
    sector_desc = "CROPS",
    group_desc = "FIELD CROPS",
    commodity_desc = "CORN",
    statisticcat_desc = "AREA HARVESTED",
    agg_level_desc = "COUNTY",
    state_alpha = "NE",
    unit_desc = "ACRES",
    freq_desc = "ANNUAL",
    prodn_practice_desc = "IRRIGATED"
  ))
}, error = function(e) {
  cat("  Warning: Could not fetch irrigated corn data:", e$message, "\n")
  NULL
})

if (!is.null(irrig_data)) {
  irrig_corn <- irrig_data %>%
    select(year, county_name, county_code, state_fips_code, Value,
           prodn_practice_desc) %>%
    mutate(
      year = as.integer(year),
      county_fips = paste0(state_fips_code, county_code),
      irrigated_corn_acres = as.numeric(gsub(",", "", Value))
    ) %>%
    filter(!is.na(irrigated_corn_acres)) %>%
    select(year, county_name, county_fips, irrigated_corn_acres)

  cat("  Got", nrow(irrig_corn), "irrigated corn observations\n")
} else {
  irrig_corn <- tibble()
}

# --- 3. Fetch total cropland harvested ---
cat("\nFetching total cropland harvested...\n")

total_cropland <- tryCatch({
  df <- query_nass(list(
    source_desc = "SURVEY",
    sector_desc = "CROPS",
    group_desc = "FIELD CROPS",
    commodity_desc = "CORN",
    statisticcat_desc = "AREA PLANTED",
    agg_level_desc = "COUNTY",
    state_alpha = "NE",
    unit_desc = "ACRES",
    freq_desc = "ANNUAL"
  ))

  df %>%
    select(year, county_name, county_code, state_fips_code, Value) %>%
    mutate(
      year = as.integer(year),
      county_fips = paste0(state_fips_code, county_code),
      corn_planted_acres = as.numeric(gsub(",", "", Value))
    ) %>%
    filter(!is.na(corn_planted_acres), year >= 1988, year <= 2023) %>%
    select(year, county_name, county_fips, corn_planted_acres)
}, error = function(e) {
  cat("  Warning: Could not fetch corn planted data:", e$message, "\n")
  tibble()
})

cat("  Got", nrow(total_cropland), "corn planted observations\n")

# --- 4. Fetch farm income data (county-level) ---
cat("\nFetching county farm income...\n")

farm_income <- tryCatch({
  df <- query_nass(list(
    source_desc = "SURVEY",
    sector_desc = "ECONOMICS",
    group_desc = "INCOME",
    commodity_desc = "INCOME, NET CASH FARM",
    statisticcat_desc = "NET INCOME",
    agg_level_desc = "COUNTY",
    state_alpha = "NE",
    unit_desc = "$",
    freq_desc = "ANNUAL"
  ))

  df %>%
    select(year, county_name, county_code, state_fips_code, Value) %>%
    mutate(
      year = as.integer(year),
      county_fips = paste0(state_fips_code, county_code),
      net_farm_income = as.numeric(gsub(",", "", Value))
    ) %>%
    filter(!is.na(net_farm_income)) %>%
    select(year, county_name, county_fips, net_farm_income)
}, error = function(e) {
  cat("  Warning: Could not fetch farm income:", e$message, "\n")
  tibble()
})

cat("  Got", nrow(farm_income), "farm income observations\n")

# --- Save raw data ---
saveRDS(crop_data, "../data/crop_data_raw.rds")
saveRDS(irrig_corn, "../data/irrig_corn_raw.rds")
saveRDS(total_cropland, "../data/corn_planted_raw.rds")
saveRDS(farm_income, "../data/farm_income_raw.rds")

cat("\n=== Data fetch complete ===\n")
cat("Crop data:", nrow(crop_data), "obs\n")
cat("Irrigated corn:", nrow(irrig_corn), "obs\n")
cat("Corn planted:", nrow(total_cropland), "obs\n")
cat("Farm income:", nrow(farm_income), "obs\n")
