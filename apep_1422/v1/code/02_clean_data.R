# 02_clean_data.R — Merge station weather to county yields
# apep_1422: When Bugs Hatch Early

source("00_packages.R")

cat("=== Cleaning and merging data ===\n")

# ─── Load data ──────────────────────────────────────────────────────
nass <- read_csv("../data/nass_corn_yields.csv", show_col_types = FALSE)
station_year <- read_csv("../data/station_year_gdd.csv", show_col_types = FALSE)

# Ensure types match
nass$year <- as.integer(nass$year)
station_year$year <- as.integer(station_year$year)

nass <- nass %>%
  filter(year >= 2000 & year <= 2022) %>%
  mutate(fips = str_pad(as.character(fips), 5, pad = "0"))

cat(sprintf("NASS: %d records, %d counties\n", nrow(nass), n_distinct(nass$fips)))
cat(sprintf("Station-years: %d\n", nrow(station_year)))

# ─── Map state FIPS to abbreviation ─────────────────────────────────
fips_to_abbr <- c(
  "17" = "IL", "18" = "IN", "19" = "IA", "20" = "KS", "21" = "KY",
  "26" = "MI", "27" = "MN", "29" = "MO", "31" = "NE", "38" = "ND",
  "39" = "OH", "46" = "SD", "55" = "WI"
)
nass$state_abbr <- fips_to_abbr[as.character(nass$state_fips)]

# ─── Download county centroids ──────────────────────────────────────
cat("Downloading county centroids...\n")
centroids_url <- "https://www2.census.gov/geo/docs/reference/cenpop2020/county/CenPop2020_Mean_CO.txt"
centroids <- read_csv(centroids_url, show_col_types = FALSE)

centroids <- centroids %>%
  mutate(
    fips = paste0(str_pad(STATEFP, 2, pad = "0"), str_pad(COUNTYFP, 3, pad = "0")),
    county_lat = LATITUDE,
    county_lon = LONGITUDE
  ) %>%
  select(fips, county_lat, county_lon)

# ─── State-level average weather (simple, robust approach) ──────────
# Average across all stations in each state × year
cat("Computing state-year average weather...\n")

state_weather <- station_year %>%
  group_by(state, year) %>%
  summarise(
    pest_gdd = mean(pest_gdd, na.rm = TRUE),
    heat_stress = mean(heat_stress, na.rm = TRUE),
    tmean_annual = mean(tmean_annual, na.rm = TRUE),
    n_stations = n(),
    .groups = "drop"
  )

cat(sprintf("State-year weather: %d records\n", nrow(state_weather)))
cat(sprintf("States: %s\n", paste(sort(unique(state_weather$state)), collapse = ", ")))

# ─── Merge yields with weather via state abbreviation ────────────────
panel <- nass %>%
  select(fips, year, yield_bu_acre, state_fips, county_fips, county_name,
         state_name, state_abbr) %>%
  inner_join(state_weather, by = c("state_abbr" = "state", "year" = "year")) %>%
  left_join(centroids, by = "fips")

# Create analysis variables
panel <- panel %>%
  mutate(
    ln_yield = log(yield_bu_acre),
    county_id = as.integer(factor(fips)),
    pest_gdd_z = (pest_gdd - mean(pest_gdd, na.rm = TRUE)) / sd(pest_gdd, na.rm = TRUE),
    heat_stress_z = (heat_stress - mean(heat_stress, na.rm = TRUE)) / sd(heat_stress, na.rm = TRUE)
  ) %>%
  filter(!is.na(pest_gdd), !is.na(heat_stress), !is.na(ln_yield))

cat(sprintf("\n=== Analysis panel ===\n"))
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("Counties: %d\n", n_distinct(panel$fips)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Mean yield: %.1f bu/acre\n", mean(panel$yield_bu_acre)))
cat(sprintf("Mean PestGDD: %.1f (SD: %.1f)\n", mean(panel$pest_gdd), sd(panel$pest_gdd)))
cat(sprintf("Mean HeatStress: %.1f (SD: %.1f)\n", mean(panel$heat_stress), sd(panel$heat_stress)))
cat(sprintf("Corr(PestGDD, HeatStress): %.3f\n",
            cor(panel$pest_gdd, panel$heat_stress)))

# Within-state correlation
panel_dm <- panel %>%
  group_by(state_abbr) %>%
  mutate(
    pest_dm = pest_gdd - mean(pest_gdd),
    heat_dm = heat_stress - mean(heat_stress)
  ) %>%
  ungroup()
cat(sprintf("Within-state corr: %.3f\n",
            cor(panel_dm$pest_dm, panel_dm$heat_dm)))

saveRDS(panel, "../data/panel.rds")
cat("\nPanel saved to data/panel.rds\n")
