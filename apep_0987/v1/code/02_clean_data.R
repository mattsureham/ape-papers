## 02_clean_data.R — Build county-year analysis panel
## apep_0987: EPA MATS Staggered Compliance and Infant Health

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

cat("=== Loading raw data ===\n")
coal_plants <- readRDS("coal_plants.rds")
centroids <- readRDS("county_centroids.rds")
aqi_df <- readRDS("county_aqi.rds")
saipe <- readRDS("county_saipe.rds")
county_pop <- readRDS("county_population.rds")

# --- Step 1: Parse CHR low birth weight data across years ---
cat("=== Step 1: Parse County Health Rankings LBW data ===\n")

chr_list <- list()
for (yr in 2012:2020) {
  f <- paste0("chr_", yr, ".csv")
  if (!file.exists(f)) next

  # Read with machine-readable header (row 2)
  d <- tryCatch({
    raw <- read.csv(f, header = FALSE, stringsAsFactors = FALSE, skip = 1, nrows = 1)
    headers <- as.character(raw[1, ])
    d <- read.csv(f, header = FALSE, stringsAsFactors = FALSE, skip = 2)
    names(d) <- headers
    d
  }, error = function(e) {
    cat("  Error reading CHR", yr, ":", conditionMessage(e), "\n")
    NULL
  })
  if (is.null(d)) next

  # Extract LBW variables
  chr_yr <- d %>%
    transmute(
      fips = as.character(fipscode),
      chr_year = as.integer(year),
      lbw_rate = as.numeric(v037_rawvalue),
      lbw_numerator = as.numeric(v037_numerator),
      lbw_denominator = as.numeric(v037_denominator),
      premature_death_rate = as.numeric(v001_rawvalue)
    ) %>%
    filter(nchar(fips) == 5, fips != "00000")  # Remove state/national rows

  cat("  CHR", yr, ":", nrow(chr_yr), "counties, LBW mean =",
      round(mean(chr_yr$lbw_rate, na.rm = TRUE), 4), "\n")

  chr_list[[as.character(yr)]] <- chr_yr
}

chr_panel <- bind_rows(chr_list)
cat("CHR panel:", nrow(chr_panel), "county-year obs\n")
cat("CHR years:", paste(sort(unique(chr_panel$chr_year)), collapse = ", "), "\n")

# CHR "Release Year" maps to underlying data that is typically 2-3 years prior
# CHR 2012 → ~2006-2010 births, CHR 2015 → ~2009-2013, CHR 2020 → ~2014-2018
# We assign the midpoint of the underlying data window:
chr_panel <- chr_panel %>%
  mutate(
    data_year = case_when(
      chr_year == 2012 ~ 2008L,
      chr_year == 2013 ~ 2009L,
      chr_year == 2014 ~ 2010L,
      chr_year == 2015 ~ 2011L,
      chr_year == 2016 ~ 2012L,
      chr_year == 2017 ~ 2013L,
      chr_year == 2018 ~ 2014L,
      chr_year == 2019 ~ 2015L,
      chr_year == 2020 ~ 2016L,
      TRUE ~ NA_integer_
    )
  )

cat("Data years after mapping:", paste(sort(unique(chr_panel$data_year)), collapse = ", "), "\n")

# --- Step 2: Compute county-plant distances and treatment assignment ---
cat("\n=== Step 2: County-plant distance matching ===\n")

# County centroids
county_coords <- centroids %>%
  select(fips, latitude, longitude) %>%
  rename(county_lat = latitude, county_lon = longitude)

# Plant coordinates
plant_coords <- coal_plants %>%
  select(plant_id, latitude, longitude, compliance_wave, total_capacity_mw) %>%
  rename(plant_lat = latitude, plant_lon = longitude)

cat("Computing distances for", nrow(county_coords), "counties x", nrow(plant_coords), "plants...\n")

# Vectorized distance computation using distm
# Build full distance matrix: counties (rows) x plants (cols)
dist_matrix <- distm(
  cbind(county_coords$county_lon, county_coords$county_lat),
  cbind(plant_coords$plant_lon, plant_coords$plant_lat),
  fun = distHaversine
) / 1000  # Convert to km

cat("Distance matrix:", nrow(dist_matrix), "x", ncol(dist_matrix), "\n")

# For each county, find nearest plant
nearest_idx <- apply(dist_matrix, 1, which.min)
nearest_dist <- apply(dist_matrix, 1, min)

county_treatment <- county_coords %>%
  mutate(
    nearest_plant_id = plant_coords$plant_id[nearest_idx],
    dist_km = nearest_dist,
    nearest_wave = plant_coords$compliance_wave[nearest_idx],
    nearest_capacity = plant_coords$total_capacity_mw[nearest_idx]
  )

# Count plants within 50 miles (80.5 km) and total capacity
miles_50_km <- 80.5
county_treatment$plants_50mi <- rowSums(dist_matrix <= miles_50_km)
county_treatment$capacity_50mi <- apply(dist_matrix, 1, function(row) {
  sum(plant_coords$total_capacity_mw[row <= miles_50_km])
})

# Treatment assignment:
# "Treated" county = at least one coal plant within 50 miles (80.5 km)
# Treatment timing = compliance wave of nearest plant
county_treatment <- county_treatment %>%
  mutate(
    exposed = dist_km <= 80.5,          # Within 50 miles
    first_treat = ifelse(exposed, nearest_wave, 0L),  # 0 = never-treated
    dist_group = case_when(
      dist_km <= 40 ~ "0-25mi",
      dist_km <= 80.5 ~ "25-50mi",
      dist_km <= 161 ~ "50-100mi",
      TRUE ~ ">100mi"
    )
  )

cat("\nTreatment assignment:\n")
print(table(county_treatment$first_treat, useNA = "always"))
cat("\nDistance groups:\n")
print(table(county_treatment$dist_group))
cat("\nExposed counties:", sum(county_treatment$exposed), "\n")

# --- Step 3: Build AQI panel ---
cat("\n=== Step 3: Build AQI outcome panel ===\n")

# Clean AQI data — remove duplicate columns first
aqi_df <- aqi_df[, !duplicated(names(aqi_df))]
aqi_clean <- aqi_df %>%
  transmute(
    fips = paste0(
      sprintf("%02d", as.integer(gsub("\"", "", state))),
      sprintf("%03d", as.integer(gsub("\"", "", county)))
    ),
    year = as.integer(year),
    days_aqi = as.integer(days_with_aqi),
    good_days = as.integer(good_days),
    moderate_days = as.integer(moderate_days),
    unhealthy_sensitive = as.integer(unhealthy_for_sensitive_groups_days),
    unhealthy_days = as.integer(unhealthy_days),
    max_aqi = as.integer(max_aqi),
    median_aqi = as.integer(median_aqi)
  ) %>%
  filter(!is.na(fips), year >= 2009, year <= 2019)

cat("AQI panel:", nrow(aqi_clean), "county-year obs\n")
cat("AQI years:", paste(sort(unique(aqi_clean$year)), collapse = ", "), "\n")

# --- Step 4: Merge everything into analysis panel ---
cat("\n=== Step 4: Build analysis panel ===\n")

# AQI panel — county-year
panel_aqi <- aqi_clean %>%
  left_join(county_treatment, by = "fips") %>%
  left_join(saipe, by = c("fips", "year")) %>%
  filter(!is.na(first_treat))

cat("AQI analysis panel:", nrow(panel_aqi), "county-year obs\n")
cat("  Treated (exposed):", sum(panel_aqi$exposed), "obs\n")
cat("  Never-treated:", sum(!panel_aqi$exposed), "obs\n")
cat("  Unique counties:", n_distinct(panel_aqi$fips), "\n")

# LBW panel — county by CHR release year
panel_lbw <- chr_panel %>%
  left_join(county_treatment, by = "fips") %>%
  left_join(
    county_pop %>% select(fips, population),
    by = "fips"
  ) %>%
  filter(!is.na(first_treat), !is.na(lbw_rate))

cat("\nLBW analysis panel:", nrow(panel_lbw), "county-chr_year obs\n")
cat("  Treated:", sum(panel_lbw$exposed), "obs\n")
cat("  Never-treated:", sum(!panel_lbw$exposed), "obs\n")
cat("  Unique counties:", n_distinct(panel_lbw$fips), "\n")

# --- Step 5: Summary statistics ---
cat("\n=== Summary Statistics ===\n")

cat("\nAQI panel by treatment:\n")
panel_aqi %>%
  group_by(exposed) %>%
  summarise(
    n_counties = n_distinct(fips),
    mean_median_aqi = mean(median_aqi, na.rm = TRUE),
    mean_unhealthy = mean(unhealthy_sensitive, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\nLBW panel by treatment:\n")
panel_lbw %>%
  group_by(exposed) %>%
  summarise(
    n_counties = n_distinct(fips),
    mean_lbw = mean(lbw_rate, na.rm = TRUE),
    mean_births = mean(lbw_denominator, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Save analysis panels
saveRDS(panel_aqi, "panel_aqi.rds")
saveRDS(panel_lbw, "panel_lbw.rds")
saveRDS(county_treatment, "county_treatment.rds")

cat("\n=== Data cleaning complete ===\n")
