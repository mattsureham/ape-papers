## 02_clean_data.R — Construct analysis panel
## APEP Paper apep_0669: Capitalization of Reproductive Rights

source("00_packages.R")

cat("=== Constructing Analysis Panel ===\n")

# ----------------------------------------------------------------
# 1. Load intermediate data
# ----------------------------------------------------------------
zhvi_raw <- readRDS("../data/zhvi_raw.rds")
zcta_centroids <- readRDS("../data/zcta_centroids.rds")
mo_il_border <- readRDS("../data/mo_il_border.rds")
mo_ks_border <- readRDS("../data/mo_ks_border.rds")
msa_zips <- readRDS("../data/msa_zips.rds")
zip_state <- readRDS("../data/zip_state.rds")

# ----------------------------------------------------------------
# 2. Reshape ZHVI from wide to long
# ----------------------------------------------------------------
cat("Reshaping ZHVI to long format...\n")

# Identify the RegionName (ZIP) column and date columns
zip_col <- "RegionName"
date_cols <- grep("^\\d{4}-\\d{2}-\\d{2}$", names(zhvi_raw), value = TRUE)

# Standardize ZIP codes
zhvi_raw[[zip_col]] <- sprintf("%05d", as.integer(zhvi_raw[[zip_col]]))

# Keep only ZIP and date columns
zhvi_long <- zhvi_raw %>%
  select(all_of(c(zip_col, "StateName", "City", "Metro", "CountyName", date_cols))) %>%
  pivot_longer(
    cols = all_of(date_cols),
    names_to = "date",
    values_to = "zhvi"
  ) %>%
  rename(zip = all_of(zip_col)) %>%
  mutate(
    date = as.Date(date),
    year = year(date),
    month = month(date),
    ym = as.integer(format(date, "%Y%m"))
  ) %>%
  filter(!is.na(zhvi))

cat("  ZHVI long format:", nrow(zhvi_long), "rows\n")

# ----------------------------------------------------------------
# 3. Filter to analysis window: Jan 2020 – Dec 2024
# ----------------------------------------------------------------
zhvi_panel <- zhvi_long %>%
  filter(date >= as.Date("2020-01-01") & date <= as.Date("2024-12-31"))

cat("  Analysis window (2020-2024):", nrow(zhvi_panel), "rows\n")

# ----------------------------------------------------------------
# 4. Merge with ZIP centroids and state info
# ----------------------------------------------------------------
zhvi_panel <- zhvi_panel %>%
  left_join(zcta_centroids, by = "zip") %>%
  left_join(zip_state %>% select(zip, state_fips), by = "zip")

cat("  After centroid merge:", sum(!is.na(zhvi_panel$lon)), "with coordinates\n")

# ----------------------------------------------------------------
# 5. Create St. Louis MSA panel
# ----------------------------------------------------------------
stl_panel <- zhvi_panel %>%
  filter(zip %in% msa_zips$stl) %>%
  filter(!is.na(lon) & !is.na(lat))

cat("  St. Louis MSA panel:", nrow(stl_panel), "rows, ",
    n_distinct(stl_panel$zip), "ZIPs\n")

# Assign treatment: Missouri = ban state
stl_panel <- stl_panel %>%
  mutate(
    missouri = as.integer(state_fips == "29"),
    illinois = as.integer(state_fips == "17"),
    ban_state = missouri
  )

# Check state distribution
cat("  MO ZIPs:", sum(stl_panel$missouri[!duplicated(stl_panel$zip)]),
    "| IL ZIPs:", sum(stl_panel$illinois[!duplicated(stl_panel$zip)]), "\n")

# ----------------------------------------------------------------
# 6. Compute signed distance to MO-IL border
# ----------------------------------------------------------------
cat("Computing distances to MO-IL border...\n")

# Convert ZIP centroids to sf for distance computation
stl_zips_sf <- stl_panel %>%
  distinct(zip, lon, lat, missouri) %>%
  filter(!is.na(lon) & !is.na(lat)) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4269)  # NAD83 (Census CRS)

# Ensure border is in same CRS
mo_il_border <- st_transform(mo_il_border, 4269)

# Compute distance in meters
dists <- as.numeric(st_distance(stl_zips_sf, mo_il_border))

# Convert to km and apply sign (positive = MO/ban, negative = IL/protection)
stl_zips_sf$dist_km <- dists / 1000
stl_zips_sf$signed_dist <- ifelse(stl_zips_sf$missouri == 1,
                                   stl_zips_sf$dist_km,
                                   -stl_zips_sf$dist_km)

# Merge back
dist_df <- stl_zips_sf %>%
  st_drop_geometry() %>%
  select(zip, dist_km, signed_dist)

stl_panel <- stl_panel %>%
  left_join(dist_df, by = "zip")

cat("  Distance range:", round(min(stl_panel$signed_dist, na.rm = TRUE), 1),
    "to", round(max(stl_panel$signed_dist, na.rm = TRUE), 1), "km\n")

# ----------------------------------------------------------------
# 7. Create treatment variables
# ----------------------------------------------------------------
dobbs_date <- as.Date("2022-06-24")
leak_date <- as.Date("2022-05-02")

stl_panel <- stl_panel %>%
  mutate(
    post_dobbs = as.integer(date >= as.Date("2022-07-01")),
    # Exclude June 2022 as transition month
    pre_dobbs = as.integer(date < as.Date("2022-06-01")),
    treat_post = ban_state * post_dobbs,
    # Event time (months relative to Dobbs)
    event_month = as.integer(difftime(date, as.Date("2022-06-01"), units = "days")) %/% 30,
    # Log ZHVI
    log_zhvi = log(zhvi)
  )

# ----------------------------------------------------------------
# 8. Create Kansas City MSA panel (replication)
# ----------------------------------------------------------------
kc_panel <- zhvi_panel %>%
  filter(zip %in% msa_zips$kc) %>%
  filter(!is.na(lon) & !is.na(lat))

kc_panel <- kc_panel %>%
  mutate(
    missouri = as.integer(state_fips == "29"),
    kansas = as.integer(state_fips == "20"),
    ban_state = missouri  # MO banned; KS protected via Aug 2022 referendum
  )

cat("  Kansas City MSA panel:", nrow(kc_panel), "rows, ",
    n_distinct(kc_panel$zip), "ZIPs\n")

# KC border distances
kc_zips_sf <- kc_panel %>%
  distinct(zip, lon, lat, missouri) %>%
  filter(!is.na(lon) & !is.na(lat)) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4269)

mo_ks_border <- st_transform(mo_ks_border, 4269)
kc_dists <- as.numeric(st_distance(kc_zips_sf, mo_ks_border))

kc_zips_sf$dist_km <- kc_dists / 1000
kc_zips_sf$signed_dist <- ifelse(kc_zips_sf$missouri == 1,
                                  kc_zips_sf$dist_km,
                                  -kc_zips_sf$dist_km)

kc_dist_df <- kc_zips_sf %>%
  st_drop_geometry() %>%
  select(zip, dist_km, signed_dist)

kc_panel <- kc_panel %>%
  left_join(kc_dist_df, by = "zip") %>%
  mutate(
    post_dobbs = as.integer(date >= as.Date("2022-07-01")),
    pre_dobbs = as.integer(date < as.Date("2022-06-01")),
    treat_post = ban_state * post_dobbs,
    event_month = as.integer(difftime(date, as.Date("2022-06-01"), units = "days")) %/% 30,
    log_zhvi = log(zhvi)
  )

cat("  KC MO ZIPs:", sum(kc_panel$missouri[!duplicated(kc_panel$zip)]),
    "| KS ZIPs:", sum(kc_panel$kansas[!duplicated(kc_panel$zip)]), "\n")

# ----------------------------------------------------------------
# 9. Save analysis panels
# ----------------------------------------------------------------
saveRDS(stl_panel, "../data/stl_panel.rds")
saveRDS(kc_panel, "../data/kc_panel.rds")

# Summary statistics
cat("\n=== SUMMARY ===\n")
cat("St. Louis panel: ", n_distinct(stl_panel$zip), " ZIPs x ",
    n_distinct(stl_panel$date), " months = ", nrow(stl_panel), " obs\n")
cat("Kansas City panel: ", n_distinct(kc_panel$zip), " ZIPs x ",
    n_distinct(kc_panel$date), " months = ", nrow(kc_panel), " obs\n")
cat("=== Data cleaning complete ===\n")
