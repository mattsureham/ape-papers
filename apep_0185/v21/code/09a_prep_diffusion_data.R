################################################################################
# 09a_prep_diffusion_data.R
# Fast data prep for diffusion analysis — only downloads SCI + centroids + MW
# Does NOT require QWI data or full analysis_panel.rds
#
# This is a subset of 01_fetch_data.R + 02_clean_data.R that creates only
# the files needed by 09b-09f:
#   - raw_sci.rds
#   - raw_county_centroids.rds
#   - state_mw_panel.rds (state-quarter MW from manually curated data)
#   - raw_all_states.rds
#
# If these files already exist (from running 01_fetch_data.R), this script
# detects them and skips.
################################################################################

source("00_packages.R")

cat("=== Fast Data Prep for Diffusion Analysis ===\n\n")

# ============================================================================
# 1. Check if data already exists
# ============================================================================

needed_files <- c("../data/raw_sci.rds", "../data/raw_county_centroids.rds",
                  "../data/state_mw_panel.rds", "../data/raw_all_states.rds")

if (all(file.exists(needed_files))) {
  cat("All needed data files already exist. Skipping.\n")
  cat("=== Data Prep Skipped ===\n")
  quit(save = "no", status = 0)
}

# ============================================================================
# 2. Facebook SCI
# ============================================================================

if (!file.exists("../data/raw_sci.rds")) {
  cat("1. Fetching Social Connectedness Index from HDX...\n")
  sci_url <- "https://data.humdata.org/dataset/e9988552-74e4-4ff4-943f-c782ac8bca87/resource/97dc352f-c9c5-47d6-a6ef-88709e14006c/download/us_counties.zip"
  sci_zip <- tempfile(fileext = ".zip")
  sci_dir <- tempdir()

  download.file(sci_url, sci_zip, mode = "wb", quiet = TRUE)
  unzip(sci_zip, exdir = sci_dir)
  sci_files <- list.files(sci_dir, pattern = "\\.(tsv|csv)$", full.names = TRUE, recursive = TRUE)
  sci_raw <- fread(sci_files[1], header = TRUE)

  if ("user_region" %in% names(sci_raw)) {
    setnames(sci_raw, c("user_region", "friend_region", "scaled_sci"),
             c("county_fips_1", "county_fips_2", "sci"), skip_absent = TRUE)
    sci_raw[, c("user_country", "friend_country") := NULL]
  }
  sci_raw[, county_fips_1 := sprintf("%05d", as.integer(county_fips_1))]
  sci_raw[, county_fips_2 := sprintf("%05d", as.integer(county_fips_2))]
  sci_raw[, state_fips_1 := substr(county_fips_1, 1, 2)]
  sci_raw[, state_fips_2 := substr(county_fips_2, 1, 2)]

  saveRDS(sci_raw, "../data/raw_sci.rds")
  cat("  Saved raw_sci.rds (", format(nrow(sci_raw), big.mark = ","), " pairs)\n")
} else {
  cat("1. raw_sci.rds already exists, skipping.\n")
}

# ============================================================================
# 3. County Centroids
# ============================================================================

if (!file.exists("../data/raw_county_centroids.rds")) {
  cat("\n2. Fetching county centroids...\n")
  counties_sf <- counties(cb = TRUE, year = 2019) %>%
    filter(!STATEFP %in% c("72", "78", "69", "66", "60"))

  counties_sf <- counties_sf %>%
    mutate(fips = paste0(STATEFP, COUNTYFP), centroid = st_centroid(geometry))

  centroids <- counties_sf %>%
    st_drop_geometry() %>%
    mutate(lon = st_coordinates(centroid)[, 1], lat = st_coordinates(centroid)[, 2]) %>%
    select(fips, state_fips = STATEFP, county_name = NAME, lon, lat)

  saveRDS(centroids, "../data/raw_county_centroids.rds")
  cat("  Saved raw_county_centroids.rds (", nrow(centroids), " counties)\n")
} else {
  cat("2. raw_county_centroids.rds already exists, skipping.\n")
}

# ============================================================================
# 4. State Reference and MW Panel
# ============================================================================

if (!file.exists("../data/raw_all_states.rds")) {
  cat("\n3. Creating state reference...\n")
  all_states <- tibble(
    state_fips = c("01","02","04","05","06","08","09","10","11","12",
                   "13","15","16","17","18","19","20","21","22","23",
                   "24","25","26","27","28","29","30","31","32","33",
                   "34","35","36","37","38","39","40","41","42","44",
                   "45","46","47","48","49","50","51","53","54","55","56"),
    state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                   "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                   "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                   "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                   "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
  )
  saveRDS(all_states, "../data/raw_all_states.rds")
}

if (!file.exists("../data/state_mw_panel.rds")) {
  cat("\n4. Creating state minimum wage panel...\n")

  # Load MW changes from 01_fetch_data.R (inline for independence)
  federal_mw <- 7.25

  state_mw_changes <- tribble(
    ~state_fips, ~state_abbr, ~date, ~min_wage,
    "06","CA","2014-07-01",9.00, "06","CA","2016-01-01",10.00,
    "06","CA","2017-01-01",10.50, "06","CA","2018-01-01",11.00,
    "06","CA","2019-01-01",12.00, "06","CA","2020-01-01",13.00,
    "06","CA","2021-01-01",14.00, "06","CA","2022-01-01",15.00,
    "06","CA","2023-01-01",15.50,
    "36","NY","2014-01-01",8.00, "36","NY","2015-01-01",8.75,
    "36","NY","2016-01-01",9.00, "36","NY","2017-01-01",9.70,
    "36","NY","2018-01-01",10.40, "36","NY","2019-01-01",11.10,
    "36","NY","2020-01-01",11.80, "36","NY","2021-01-01",12.50,
    "36","NY","2022-01-01",13.20, "36","NY","2023-01-01",14.20,
    "53","WA","2012-01-01",9.04, "53","WA","2013-01-01",9.19,
    "53","WA","2014-01-01",9.32, "53","WA","2015-01-01",9.47,
    "53","WA","2017-01-01",11.00, "53","WA","2018-01-01",11.50,
    "53","WA","2019-01-01",12.00, "53","WA","2020-01-01",13.50,
    "53","WA","2021-01-01",13.69, "53","WA","2022-01-01",14.49,
    "53","WA","2023-01-01",15.74,
    "25","MA","2015-01-01",9.00, "25","MA","2016-01-01",10.00,
    "25","MA","2017-01-01",11.00, "25","MA","2019-01-01",12.00,
    "25","MA","2020-01-01",12.75, "25","MA","2021-01-01",13.50,
    "25","MA","2022-01-01",14.25, "25","MA","2023-01-01",15.00,
    "04","AZ","2017-01-01",10.00, "04","AZ","2018-01-01",10.50,
    "04","AZ","2019-01-01",11.00, "04","AZ","2020-01-01",12.00,
    "04","AZ","2021-01-01",12.15, "04","AZ","2022-01-01",12.80,
    "04","AZ","2023-01-01",13.85,
    "08","CO","2017-01-01",9.30, "08","CO","2018-01-01",10.20,
    "08","CO","2019-01-01",11.10, "08","CO","2020-01-01",12.00,
    "08","CO","2021-01-01",12.32, "08","CO","2022-01-01",12.56,
    "08","CO","2023-01-01",13.65,
    "12","FL","2021-01-01",8.65, "12","FL","2021-09-30",10.00,
    "12","FL","2022-09-30",11.00, "12","FL","2023-09-30",12.00,
    "17","IL","2020-01-01",9.25, "17","IL","2020-07-01",10.00,
    "17","IL","2021-01-01",11.00, "17","IL","2022-01-01",12.00,
    "17","IL","2023-01-01",13.00,
    "34","NJ","2019-07-01",10.00, "34","NJ","2020-01-01",11.00,
    "34","NJ","2021-01-01",12.00, "34","NJ","2022-01-01",13.00,
    "34","NJ","2023-01-01",14.13,
    "24","MD","2015-01-01",8.00, "24","MD","2016-07-01",8.75,
    "24","MD","2017-07-01",9.25, "24","MD","2018-07-01",10.10,
    "24","MD","2020-01-01",11.00, "24","MD","2021-01-01",11.75,
    "24","MD","2022-01-01",12.50, "24","MD","2023-01-01",13.25,
    "09","CT","2014-01-01",8.70, "09","CT","2015-01-01",9.15,
    "09","CT","2016-01-01",9.60, "09","CT","2017-01-01",10.10,
    "09","CT","2019-10-01",11.00, "09","CT","2020-09-01",12.00,
    "09","CT","2021-08-01",13.00, "09","CT","2022-07-01",14.00,
    "09","CT","2023-06-01",15.00,
    "41","OR","2016-07-01",9.75, "41","OR","2017-07-01",10.25,
    "41","OR","2018-07-01",10.75, "41","OR","2019-07-01",11.25,
    "41","OR","2020-07-01",12.00, "41","OR","2021-07-01",12.75,
    "41","OR","2022-07-01",13.50, "41","OR","2023-07-01",14.20,
    "32","NV","2019-07-01",8.25, "32","NV","2020-07-01",9.00,
    "32","NV","2021-07-01",9.75, "32","NV","2022-07-01",10.50,
    "32","NV","2023-07-01",11.25,
    "26","MI","2014-09-01",8.15, "26","MI","2016-01-01",8.50,
    "26","MI","2017-01-01",8.90, "26","MI","2018-03-01",9.25,
    "26","MI","2019-03-01",9.45, "26","MI","2020-01-01",9.65,
    "26","MI","2022-01-01",9.87, "26","MI","2023-01-01",10.10,
    "27","MN","2014-08-01",8.00, "27","MN","2015-08-01",9.00,
    "27","MN","2016-08-01",9.50, "27","MN","2018-01-01",9.65,
    "27","MN","2019-01-01",9.86, "27","MN","2020-01-01",10.00,
    "27","MN","2021-01-01",10.08, "27","MN","2022-01-01",10.33,
    "27","MN","2023-01-01",10.59,
    "31","NE","2015-01-01",8.00, "31","NE","2016-01-01",9.00,
    "31","NE","2023-01-01",10.50,
    "02","AK","2015-02-24",8.75, "02","AK","2016-01-01",9.75,
    "02","AK","2017-01-01",9.80, "02","AK","2018-01-01",9.84,
    "02","AK","2019-01-01",9.89, "02","AK","2020-01-01",10.19,
    "02","AK","2021-01-01",10.34, "02","AK","2023-01-01",10.85,
    "05","AR","2015-01-01",7.50, "05","AR","2016-01-01",8.00,
    "05","AR","2017-01-01",8.50, "05","AR","2019-01-01",9.25,
    "05","AR","2020-01-01",10.00, "05","AR","2021-01-01",11.00,
    "46","SD","2015-01-01",8.50, "46","SD","2016-01-01",8.55,
    "46","SD","2017-01-01",8.65, "46","SD","2018-01-01",8.85,
    "46","SD","2019-01-01",9.10, "46","SD","2020-01-01",9.30,
    "46","SD","2021-01-01",9.45, "46","SD","2022-01-01",9.95,
    "46","SD","2023-01-01",10.80,
    "50","VT","2015-01-01",9.15, "50","VT","2016-01-01",9.60,
    "50","VT","2017-01-01",10.00, "50","VT","2018-01-01",10.50,
    "50","VT","2019-01-01",10.78, "50","VT","2020-01-01",10.96,
    "50","VT","2021-01-01",11.75, "50","VT","2022-01-01",12.55,
    "50","VT","2023-01-01",13.18,
    "23","ME","2017-01-01",9.00, "23","ME","2018-01-01",10.00,
    "23","ME","2019-01-01",11.00, "23","ME","2020-01-01",12.00,
    "23","ME","2021-01-01",12.15, "23","ME","2022-01-01",12.75,
    "23","ME","2023-01-01",13.80,
    "44","RI","2015-01-01",9.00, "44","RI","2016-01-01",9.60,
    "44","RI","2018-01-01",10.10, "44","RI","2019-01-01",10.50,
    "44","RI","2021-01-01",11.50, "44","RI","2022-01-01",12.25,
    "44","RI","2023-01-01",13.00,
    "15","HI","2015-01-01",7.75, "15","HI","2016-01-01",8.50,
    "15","HI","2017-01-01",9.25, "15","HI","2018-01-01",10.10,
    "15","HI","2022-10-01",12.00,
    "10","DE","2014-06-01",7.75, "10","DE","2015-06-01",8.25,
    "10","DE","2019-10-01",9.25, "10","DE","2022-01-01",10.50,
    "10","DE","2023-01-01",11.75,
    "29","MO","2019-01-01",8.60, "29","MO","2020-01-01",9.45,
    "29","MO","2021-01-01",10.30, "29","MO","2022-01-01",11.15,
    "29","MO","2023-01-01",12.00,
    "35","NM","2019-01-01",7.50, "35","NM","2020-01-01",9.00,
    "35","NM","2021-01-01",10.50, "35","NM","2022-01-01",11.50,
    "35","NM","2023-01-01",12.00,
    "51","VA","2021-05-01",9.50, "51","VA","2022-01-01",11.00,
    "51","VA","2023-01-01",12.00
  ) %>%
    mutate(date = as.Date(date))

  centroids <- readRDS("../data/raw_county_centroids.rds")

  # All unique state FIPS
  state_fips_list <- unique(centroids$state_fips)

  # Create quarterly panel
  quarters <- expand_grid(year = 2010:2023, quarter = 1:4) %>%
    mutate(
      yearq = year + (quarter - 1) / 4,
      date_start = ymd(paste(year, (quarter - 1) * 3 + 1, "01", sep = "-")),
      date_end = date_start + months(3) - days(1)
    )

  state_mw_panel <- expand_grid(state_fips = state_fips_list, quarters)

  get_min_wage <- function(st_fips, dt) {
    applicable <- state_mw_changes %>%
      filter(state_fips == st_fips, date <= dt) %>%
      arrange(desc(date))
    if (nrow(applicable) > 0) return(applicable$min_wage[1])
    return(federal_mw)
  }

  state_mw_panel <- state_mw_panel %>%
    rowwise() %>%
    mutate(min_wage = get_min_wage(state_fips, date_end)) %>%
    ungroup() %>%
    mutate(log_min_wage = log(min_wage))

  saveRDS(state_mw_panel, "../data/state_mw_panel.rds")
  cat("  Saved state_mw_panel.rds (", nrow(state_mw_panel), " state-quarter obs)\n")
} else {
  cat("4. state_mw_panel.rds already exists, skipping.\n")
}

cat("\n=== Fast Data Prep Complete ===\n")
cat("Ready to run 09b → 09c → 09d → 09e → 09f\n")
