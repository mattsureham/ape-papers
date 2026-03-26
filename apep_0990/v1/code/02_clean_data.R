# 02_clean_data.R — Construct analysis dataset with NRD treatment timing
# apep_0990: Nebraska groundwater allocations and crop adaptation

source("00_packages.R")

# --- Load raw data ---
crop_data <- readRDS("../data/crop_data_raw.rds")
irrig_corn <- readRDS("../data/irrig_corn_raw.rds")
corn_planted <- readRDS("../data/corn_planted_raw.rds")
farm_income <- readRDS("../data/farm_income_raw.rds")

# --- NRD-to-County Crosswalk ---
# Nebraska has 23 NRDs. County FIPS mapped to dominant NRD based on
# geographic overlap. Sources: Nebraska DNR, UNL Extension.
# Only NRDs with groundwater management allocations are treated.

nrd_county_map <- tribble(
  ~county_fips, ~county_name,         ~nrd_name,                    ~treat_year,
  # Upper Republican NRD — first mandatory allocations in US (1979)
  "31029",  "Chase",              "Upper Republican",            1979,
  "31057",  "Dundy",              "Upper Republican",            1979,
  "31135",  "Perkins",            "Upper Republican",            1979,
  # Middle Republican NRD — allocations adopted ~1994
  "31061",  "Franklin",           "Middle Republican",           1994,
  "31065",  "Furnas",             "Middle Republican",           1994,
  "31073",  "Gosper",             "Middle Republican",           1994,
  "31083",  "Harlan",             "Middle Republican",           1994,
  "31145",  "Red Willow",         "Middle Republican",           1994,
  # Lower Republican NRD — allocations adopted ~1998
  "31081",  "Hamilton",           "Lower Republican",            1998,
  "31099",  "Kearney",            "Lower Republican",            1998,
  "31129",  "Nuckolls",           "Lower Republican",            1998,
  "31159",  "Thayer",             "Lower Republican",            1998,
  "31095",  "Jefferson",          "Lower Republican",            1998,
  # Tri-Basin NRD — allocations adopted ~2005
  "31137",  "Phelps",             "Tri-Basin",                   2005,
  "31071",  "Garfield",           "Tri-Basin",                   2005,
  # Central Platte NRD — allocations adopted ~2006
  "31023",  "Buffalo",            "Central Platte",              2006,
  "31047",  "Dawson",             "Central Platte",              2006,
  "31079",  "Hall",               "Central Platte",              2006,
  # Twin Platte NRD — allocations adopted ~2008
  "31111",  "Lincoln",            "Twin Platte",                 2008,
  "31101",  "Keith",              "Twin Platte",                 2008,
  # South Platte NRD — allocations adopted ~2013
  "31049",  "Deuel",              "South Platte",                2013,
  "31069",  "Garden",             "South Platte",                2013,
  "31165",  "Sioux",              "South Platte",                2013,
  # North Platte NRD — allocations adopted ~2010
  "31157",  "Scotts Bluff",       "North Platte",                2010,
  "31007",  "Banner",             "North Platte",                2010,
  "31123",  "Morrill",            "North Platte",                2010,
  # Upper Niobrara-White NRD — allocations adopted ~2014
  "31045",  "Dawes",              "Upper Niobrara-White",        2014,
  "31161",  "Sheridan",           "Upper Niobrara-White",        2014,
  "31031",  "Cherry",             "Upper Niobrara-White",        2014,
  # Little Blue NRD — allocations adopted 2025 (future — treat as never-treated in sample)
  "31001",  "Adams",              "Little Blue",                 Inf,
  "31035",  "Clay",               "Little Blue",                 Inf,
  "31059",  "Fillmore",           "Little Blue",                 Inf,
  "31169",  "Thayer_LB",          "Little Blue",                 Inf,
  # Never-treated NRDs (eastern Nebraska, sufficient groundwater or surface water)
  "31109",  "Lancaster",          "Lower Platte South",          Inf,
  "31153",  "Sarpy",              "Papio-Missouri River",        Inf,
  "31055",  "Douglas",            "Papio-Missouri River",        Inf,
  "31177",  "Washington",         "Papio-Missouri River",        Inf,
  "31025",  "Cass",               "Nemaha",                      Inf,
  "31131",  "Otoe",               "Nemaha",                      Inf,
  "31147",  "Richardson",         "Nemaha",                      Inf,
  "31133",  "Pawnee",             "Nemaha",                      Inf,
  "31067",  "Gage",               "Lower Big Blue",              Inf,
  "31097",  "Johnson",            "Lower Big Blue",              Inf,
  "31151",  "Saline",             "Lower Big Blue",              Inf,
  "31093",  "Howard",             "Lower Loup",                  Inf,
  "31121",  "Merrick",            "Lower Loup",                  Inf,
  "31125",  "Nance",              "Lower Loup",                  Inf,
  "31141",  "Platte",             "Lower Platte North",          Inf,
  "31037",  "Colfax",             "Lower Platte North",          Inf,
  "31053",  "Dodge",              "Lower Platte North",          Inf,
  "31021",  "Burt",               "Lower Elkhorn",               Inf,
  "31039",  "Cuming",             "Lower Elkhorn",               Inf,
  "31167",  "Stanton",            "Lower Elkhorn",               Inf,
  "31119",  "Madison",            "Lower Elkhorn",               Inf,
  "31139",  "Pierce",             "Lower Elkhorn",               Inf,
  "31179",  "Wayne",              "Lower Elkhorn",               Inf,
  "31051",  "Dixon",              "Lewis and Clark",             Inf,
  "31043",  "Dakota",             "Lewis and Clark",             Inf,
  "31027",  "Cedar",              "Lewis and Clark",             Inf,
  "31003",  "Antelope",           "Upper Elkhorn",               Inf,
  "31015",  "Boyd",               "Lower Niobrara",              Inf,
  "31089",  "Holt",               "Upper Elkhorn",               Inf
)

cat("NRD crosswalk: ", nrow(nrd_county_map), " counties mapped\n")
cat("Treated (finite treat_year): ",
    sum(is.finite(nrd_county_map$treat_year)), " counties\n")
cat("Never-treated: ", sum(!is.finite(nrd_county_map$treat_year)), " counties\n")
cat("Unique NRDs: ", n_distinct(nrd_county_map$nrd_name), "\n")

# --- Pivot crop data to wide format ---
crop_wide <- crop_data %>%
  mutate(commodity = tolower(commodity)) %>%
  select(year, county_fips, commodity, value) %>%
  pivot_wider(
    names_from = commodity,
    values_from = value,
    names_prefix = "acres_",
    values_fn = sum
  )

cat("Crop wide panel: ", nrow(crop_wide), " county-years\n")

# --- Merge with NRD crosswalk ---
panel <- crop_wide %>%
  inner_join(nrd_county_map %>% select(county_fips, nrd_name, treat_year),
             by = "county_fips") %>%
  filter(year >= 1988, year <= 2023)

cat("Panel after NRD merge: ", nrow(panel), " county-years\n")
cat("Unique counties in panel: ", n_distinct(panel$county_fips), "\n")

# --- Construct outcome variables ---
panel <- panel %>%
  mutate(
    # Total crop acres (sum of four main crops)
    total_crop_acres = rowSums(across(starts_with("acres_"), ~replace_na(., 0))),
    # Corn share of total crop acreage
    corn_share = ifelse(total_crop_acres > 0,
                        replace_na(acres_corn, 0) / total_crop_acres, NA_real_),
    # Sorghum share
    sorghum_share = ifelse(total_crop_acres > 0,
                           replace_na(acres_sorghum, 0) / total_crop_acres, NA_real_),
    # Wheat share
    wheat_share = ifelse(total_crop_acres > 0,
                         replace_na(acres_wheat, 0) / total_crop_acres, NA_real_),
    # Soybeans share
    soybean_share = ifelse(total_crop_acres > 0,
                           replace_na(acres_soybeans, 0) / total_crop_acres, NA_real_),
    # Drought-tolerant share (sorghum + wheat)
    drought_tolerant_share = sorghum_share + wheat_share,
    # Treatment indicator
    treated = as.integer(year >= treat_year & is.finite(treat_year)),
    # First treatment year for CS (Inf → 0 for never-treated)
    first_treat = ifelse(is.finite(treat_year), treat_year, 0L)
  )

# --- Merge corn planted data (aggregate to avoid dups) ---
if (nrow(corn_planted) > 0) {
  corn_planted_agg <- corn_planted %>%
    group_by(year, county_fips) %>%
    summarise(corn_planted_acres = sum(corn_planted_acres, na.rm = TRUE), .groups = "drop")
  panel <- panel %>%
    left_join(corn_planted_agg, by = c("year", "county_fips"))
}

# --- Merge farm income ---
if (nrow(farm_income) > 0) {
  panel <- panel %>%
    left_join(farm_income %>% select(year, county_fips, net_farm_income),
              by = c("year", "county_fips"))
}

# --- Merge irrigated corn (Census years only, aggregate first) ---
irrig_corn <- readRDS("../data/irrig_corn_raw.rds")
if (nrow(irrig_corn) > 0) {
  irrig_agg <- irrig_corn %>%
    group_by(year, county_fips) %>%
    summarise(irrigated_corn_acres = sum(irrigated_corn_acres, na.rm = TRUE), .groups = "drop")
  panel <- panel %>%
    left_join(irrig_agg, by = c("year", "county_fips")) %>%
    mutate(
      irrig_corn_share = ifelse(!is.na(irrigated_corn_acres) & !is.na(acres_corn) & acres_corn > 0,
                                irrigated_corn_acres / acres_corn, NA_real_)
    )
}

# --- Add county numeric ID ---
panel <- panel %>%
  mutate(county_id = as.integer(as.factor(county_fips)))

# --- Summary stats ---
cat("\n=== Panel Summary ===\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Counties:", n_distinct(panel$county_fips), "\n")
cat("NRDs:", n_distinct(panel$nrd_name), "\n")
cat("County-years:", nrow(panel), "\n")
cat("Treated county-years:", sum(panel$treated, na.rm = TRUE), "\n")
cat("Ever-treated counties:", n_distinct(panel$county_fips[is.finite(panel$treat_year)]), "\n")
cat("Never-treated counties:", n_distinct(panel$county_fips[!is.finite(panel$treat_year)]), "\n")

cat("\nCorn share: mean =", round(mean(panel$corn_share, na.rm = TRUE), 3),
    ", sd =", round(sd(panel$corn_share, na.rm = TRUE), 3), "\n")
cat("Sorghum share: mean =", round(mean(panel$sorghum_share, na.rm = TRUE), 3),
    ", sd =", round(sd(panel$sorghum_share, na.rm = TRUE), 3), "\n")
cat("Drought-tolerant share: mean =", round(mean(panel$drought_tolerant_share, na.rm = TRUE), 3),
    ", sd =", round(sd(panel$drought_tolerant_share, na.rm = TRUE), 3), "\n")

# --- Save ---
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nAnalysis panel saved to data/analysis_panel.rds\n")
