# ==============================================================================
# 02_clean_data.R — Construct analysis dataset
# apep_1058: The Networked Bank Run
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"

# Load raw data
sci_raw <- readRDS(file.path(data_dir, "sci_raw.rds"))
sod_all <- readRDS(file.path(data_dir, "sod_all.rds"))
county_controls <- readRDS(file.path(data_dir, "county_controls.rds"))
qwi_tech <- readRDS(file.path(data_dir, "qwi_tech.rds"))

# ==============================================================================
# 1. Identify SVB branches and compute SVB deposit share by county
# ==============================================================================
cat("=== Computing SVB deposit shares ===\n")

# SVB CERT number: 24735
# Identify SVB branches in SOD 2022 (pre-failure)
sod_2022 <- sod_all %>% filter(YEAR == 2022)

svb_branches <- sod_2022 %>%
  filter(CERT == "24735" | CERT == 24735)

cat(sprintf("SVB branches in 2022 SOD: %d\n", nrow(svb_branches)))

# County-level total deposits in 2022
county_deposits_2022 <- sod_2022 %>%
  mutate(
    fips = sprintf("%05d", as.integer(STCNTYBR)),
    deposits = as.numeric(DEPSUMBR)
  ) %>%
  filter(!is.na(deposits) & !is.na(fips) & nchar(fips) == 5) %>%
  group_by(fips) %>%
  summarise(
    total_deposits_2022 = sum(deposits, na.rm = TRUE),
    n_branches_2022 = n(),
    n_banks_2022 = n_distinct(CERT),
    .groups = "drop"
  )

# SVB deposits by county
svb_county <- svb_branches %>%
  mutate(
    fips = sprintf("%05d", as.integer(STCNTYBR)),
    deposits = as.numeric(DEPSUMBR)
  ) %>%
  filter(!is.na(deposits)) %>%
  group_by(fips) %>%
  summarise(svb_deposits = sum(deposits, na.rm = TRUE), .groups = "drop")

# SVB market share by county
svb_share <- county_deposits_2022 %>%
  left_join(svb_county, by = "fips") %>%
  mutate(svb_share = ifelse(is.na(svb_deposits), 0, svb_deposits / total_deposits_2022))

cat(sprintf("Counties with SVB presence: %d\n", sum(svb_share$svb_share > 0)))
cat(sprintf("SVB deposit share in Santa Clara (06085): %.1f%%\n",
            100 * svb_share$svb_share[svb_share$fips == "06085"]))

# ==============================================================================
# 2. Construct NetworkExposure from SCI
# ==============================================================================
cat("\n=== Constructing NetworkExposure ===\n")

# SCI columns: user_region, friend_region, scaled_sci
sci <- sci_raw %>%
  mutate(
    user_fips = sprintf("%05d", as.integer(user_region)),
    fr_fips = sprintf("%05d", as.integer(friend_region))
  )

# Join SCI with SVB share: for each county c, sum SCI(c,j) * SVBshare(j)
# Only counties where SVB had branches matter for the shift
svb_counties <- svb_share %>%
  filter(svb_share > 0) %>%
  select(fips, svb_share)

cat(sprintf("Computing network exposure across %d SVB-present counties...\n", nrow(svb_counties)))

# Filter SCI to pairs where fr_loc is an SVB county
sci_svb <- sci %>%
  inner_join(svb_counties, by = c("fr_fips" = "fips"))

# For each user county, compute weighted sum
network_exposure <- sci_svb %>%
  group_by(user_fips) %>%
  summarise(
    network_exposure = sum(as.numeric(scaled_sci) * svb_share, na.rm = TRUE),
    sci_to_svb_total = sum(as.numeric(scaled_sci), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(fips = user_fips)

cat(sprintf("Network exposure computed for %d counties\n", nrow(network_exposure)))
cat(sprintf("Exposure range: [%.4f, %.4f]\n",
            min(network_exposure$network_exposure),
            max(network_exposure$network_exposure)))

# ==============================================================================
# 3. Compute county-level deposit changes (annual SOD)
# ==============================================================================
cat("\n=== Computing deposit changes ===\n")

# Exclude SVB (CERT 24735) and its failed peers from deposits to avoid mechanical confound
failed_certs <- c("24735", "57053", "59017")  # SVB, Signature, First Republic

compute_county_deposits <- function(df, yr) {
  df %>%
    filter(YEAR == yr) %>%
    filter(!(as.character(CERT) %in% failed_certs)) %>%
    mutate(
      fips = sprintf("%05d", as.integer(STCNTYBR)),
      deposits = as.numeric(DEPSUMBR)
    ) %>%
    filter(!is.na(deposits) & !is.na(fips) & nchar(fips) == 5) %>%
    group_by(fips) %>%
    summarise(
      deposits = sum(deposits, na.rm = TRUE),
      n_branches = n(),
      .groups = "drop"
    ) %>%
    rename_with(~ paste0(., "_", yr), -fips)
}

dep_2017 <- compute_county_deposits(sod_all, 2017)
dep_2018 <- compute_county_deposits(sod_all, 2018)
dep_2019 <- compute_county_deposits(sod_all, 2019)
dep_2020 <- compute_county_deposits(sod_all, 2020)
dep_2021 <- compute_county_deposits(sod_all, 2021)
dep_2022 <- compute_county_deposits(sod_all, 2022)
dep_2023 <- compute_county_deposits(sod_all, 2023)

# Merge all years
deposits_panel <- dep_2017 %>%
  full_join(dep_2018, by = "fips") %>%
  full_join(dep_2019, by = "fips") %>%
  full_join(dep_2020, by = "fips") %>%
  full_join(dep_2021, by = "fips") %>%
  full_join(dep_2022, by = "fips") %>%
  full_join(dep_2023, by = "fips")

# Compute log changes
deposits_panel <- deposits_panel %>%
  mutate(
    # Main outcome: 2022 → 2023
    dlog_dep_2223 = log(deposits_2023) - log(deposits_2022),
    # Pre-period placebo changes (5 pre-periods)
    dlog_dep_1718 = log(deposits_2018) - log(deposits_2017),
    dlog_dep_1819 = log(deposits_2019) - log(deposits_2018),
    dlog_dep_1920 = log(deposits_2020) - log(deposits_2019),
    dlog_dep_2021 = log(deposits_2021) - log(deposits_2020),
    dlog_dep_2122 = log(deposits_2022) - log(deposits_2021),
    # Pre-crisis trend (avg annual growth 2019-2022)
    pre_trend = (log(deposits_2022) - log(deposits_2019)) / 3,
    # Level
    log_deposits_2022 = log(deposits_2022)
  )

cat(sprintf("Deposit panel: %d counties\n", nrow(deposits_panel)))
cat(sprintf("Mean deposit change 2022-2023: %.3f\n", mean(deposits_panel$dlog_dep_2223, na.rm=TRUE)))

# ==============================================================================
# 4. Geographic distance to Santa Clara County
# ==============================================================================
cat("\n=== Computing geographic distances ===\n")

# Use branch-level lat/lon from SOD to get county centroids
county_centroids <- sod_2022 %>%
  mutate(
    fips = sprintf("%05d", as.integer(STCNTYBR)),
    lat = as.numeric(SIMS_LATITUDE),
    lon = as.numeric(SIMS_LONGITUDE)
  ) %>%
  filter(!is.na(lat) & !is.na(lon) & abs(lat) <= 90 & abs(lon) <= 180) %>%
  group_by(fips) %>%
  summarise(lat = median(lat), lon = median(lon), .groups = "drop")

# Santa Clara County centroid
sc_centroid <- county_centroids %>% filter(fips == "06085")
sc_lat <- sc_centroid$lat[1]
sc_lon <- sc_centroid$lon[1]

# Haversine distance
haversine <- function(lat1, lon1, lat2, lon2) {
  R <- 6371  # km
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  a <- sin(dlat/2)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin(dlon/2)^2
  2 * R * asin(sqrt(a))
}

county_centroids <- county_centroids %>%
  mutate(
    dist_to_sc_km = haversine(lat, lon, sc_lat, sc_lon),
    log_dist_to_sc = log(dist_to_sc_km + 1),
    same_state_ca = as.integer(substr(fips, 1, 2) == "06")
  )

# ==============================================================================
# 5. Merge everything into analysis dataset
# ==============================================================================
cat("\n=== Merging analysis dataset ===\n")

# Clean county controls
county_controls_clean <- county_controls %>%
  mutate(fips = sprintf("%05s", fips)) %>%
  select(fips, personal_income_2022, population_2022) %>%
  mutate(
    log_income = log(as.numeric(personal_income_2022) + 1),
    log_pop = log(as.numeric(population_2022) + 1)
  )

# Clean QWI — use fixed tech share (tech emp / total county emp)
qwi_fixed <- readRDS(file.path(data_dir, "qwi_tech_fixed.rds"))
qwi_clean <- qwi_fixed %>%
  select(fips, tech_share = tech_share_fixed, tech_emp, total_emp_all)

# Merge
analysis <- deposits_panel %>%
  inner_join(network_exposure, by = "fips") %>%
  left_join(county_centroids %>% select(fips, lat, lon, dist_to_sc_km, log_dist_to_sc, same_state_ca), by = "fips") %>%
  left_join(county_controls_clean, by = "fips") %>%
  left_join(qwi_clean, by = "fips") %>%
  mutate(
    state_fips = substr(fips, 1, 2),
    tech_share = ifelse(is.na(tech_share), 0, tech_share)
  )

# Drop extreme outliers and missing
analysis <- analysis %>%
  filter(
    !is.na(dlog_dep_2223) & is.finite(dlog_dep_2223),
    !is.na(network_exposure),
    !is.na(log_dist_to_sc),
    deposits_2022 > 0,
    deposits_2023 > 0
  )

# Standardize network exposure for interpretability
analysis <- analysis %>%
  mutate(
    network_exposure_std = (network_exposure - mean(network_exposure)) / sd(network_exposure),
    network_exposure_pctile = percent_rank(network_exposure)
  )

cat(sprintf("\nFinal analysis dataset: %d counties\n", nrow(analysis)))
cat(sprintf("States represented: %d\n", n_distinct(analysis$state_fips)))
cat(sprintf("Network exposure SD: %.4f\n", sd(analysis$network_exposure)))
cat(sprintf("Dep change mean: %.4f, SD: %.4f\n",
            mean(analysis$dlog_dep_2223), sd(analysis$dlog_dep_2223)))

saveRDS(analysis, file.path(data_dir, "analysis.rds"))
cat("\nAnalysis dataset saved.\n")
