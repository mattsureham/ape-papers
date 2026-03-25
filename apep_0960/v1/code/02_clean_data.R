## 02_clean_data.R — Spatial join of VIIRS pixels to districts + panel construction
## apep_0960

source("00_packages.R")

# ── 1. Load GADM districts ───────────────────────────────────────────────
cat("Loading Zambia district boundaries...\n")
zmb_sf <- readRDS("../data/zmb_districts.rds")
cat("  Districts:", nrow(zmb_sf), "\n")

# ── 2. Load pixel-level nightlights ──────────────────────────────────────
cat("Loading VIIRS pixel data...\n")
pixels <- read_csv("../data/viirs_pixels.csv", show_col_types = FALSE)
cat("  Pixel observations:", nrow(pixels), "\n")

# ── 3. Spatial join: assign pixels to districts ──────────────────────────
cat("Performing spatial join (pixels → districts)...\n")

# Convert pixels to sf points
pixels_sf <- st_as_sf(pixels, coords = c("lon", "lat"), crs = 4326)

# Spatial join
joined <- st_join(pixels_sf, zmb_sf[, c("NAME_1", "NAME_2", "GID_2")], join = st_within)

# Drop pixels outside any district
joined <- joined %>%
  filter(!is.na(NAME_2)) %>%
  st_drop_geometry()

cat("  Pixels matched to districts:", nrow(joined), "\n")
cat("  Districts with data:", n_distinct(joined$GID_2), "\n")

# ── 4. Aggregate to district-year panel ──────────────────────────────────
cat("Aggregating to district-year panel...\n")

district_panel <- joined %>%
  group_by(year, NAME_1, NAME_2, GID_2) %>%
  summarise(
    ntl_mean = mean(ntl, na.rm = TRUE),
    ntl_sum = sum(ntl, na.rm = TRUE),
    ntl_median = median(ntl, na.rm = TRUE),
    ntl_p75 = quantile(ntl, 0.75, na.rm = TRUE),
    n_pixels = n(),
    .groups = "drop"
  )

cat("  Panel rows:", nrow(district_panel), "\n")
cat("  Years:", paste(sort(unique(district_panel$year)), collapse = ", "), "\n")

# ── 5. Classify mining districts ─────────────────────────────────────────
cat("Classifying mining districts...\n")

# Major mining districts in Zambia
# Copperbelt Province: Kitwe, Ndola, Mufulira, Chingola, Luanshya, Kalulushi, Chililabombwe, Chambishi, Mpongwe
# North-Western Province: Solwezi, Kalumbila (Lumwana), Kasempa
mining_districts <- c(
  "Kitwe", "Ndola", "Mufulira", "Chingola", "Luanshya",
  "Kalulushi", "Chililabombwe", "Mpongwe",
  "Solwezi", "Kalumbila", "Kasempa"
)

# Also classify entire Copperbelt province as high-mining
district_panel <- district_panel %>%
  mutate(
    mining_district = as.integer(NAME_2 %in% mining_districts),
    copperbelt = as.integer(NAME_1 == "Copperbelt"),
    mining_province = as.integer(NAME_1 %in% c("Copperbelt", "North-Western")),
    post = as.integer(year >= 2019),
    # Log nightlights (adding small constant for zeros)
    log_ntl = log(ntl_mean + 0.01),
    # Asinh transformation (handles zeros without arbitrary constant)
    asinh_ntl = asinh(ntl_mean),
    # Time-centered variable
    year_c = year - 2019
  )

cat("  Mining districts (binary):", sum(district_panel$mining_district[district_panel$year == 2019]), "\n")
cat("  Copperbelt districts:", sum(district_panel$copperbelt[district_panel$year == 2019]), "\n")
cat("  Mining provinces:", sum(district_panel$mining_province[district_panel$year == 2019]), "\n")

# ── 6. Add copper prices ─────────────────────────────────────────────────
cat("Adding copper prices...\n")
copper <- readRDS("../data/copper_prices.rds")

# Annual average copper price
copper_annual <- copper %>%
  group_by(year) %>%
  summarise(copper_price = mean(copper_price_usd, na.rm = TRUE), .groups = "drop")

district_panel <- district_panel %>%
  left_join(copper_annual, by = "year")

# ── 7. Summary statistics by treatment status ────────────────────────────
cat("\n=== Summary Statistics ===\n")
district_panel %>%
  filter(year <= 2018) %>%
  group_by(mining_district) %>%
  summarise(
    n_districts = n_distinct(GID_2),
    mean_ntl = mean(ntl_mean),
    sd_ntl = sd(ntl_mean),
    .groups = "drop"
  ) %>%
  print()

# ── 8. Save panel ────────────────────────────────────────────────────────
saveRDS(district_panel, "../data/district_panel.rds")
write_csv(district_panel, "../data/district_panel.csv")

cat("\nPanel saved: ../data/district_panel.rds\n")
cat("Dimensions:", nrow(district_panel), "rows x", ncol(district_panel), "columns\n")

# Validate
stopifnot(nrow(district_panel) > 500)
stopifnot(n_distinct(district_panel$GID_2) >= 50)
stopifnot(all(2012:2023 %in% district_panel$year))

cat("\n=== Data cleaning complete ===\n")
