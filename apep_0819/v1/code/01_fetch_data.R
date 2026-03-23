# 01_fetch_data.R — Fetch rainfall data + load SHRUG nightlights
# apep_0819: Media salience and disaster recovery in India
#
# Data sources:
#   1. SHRUG VIIRS nightlights (local) — outcome
#   2. SHRUG crosswalk + Census (local) — geography and controls
#   3. NASA POWER monthly precipitation — monsoon severity (via API, no key)
#   4. Competing events calendar — instrument (hand-coded from public records)

source("00_packages.R")

cat("=== FETCHING DATA ===\n")

# ── 1. SHRUG data (local) ─────────────────────────────────────────────

# Try relative paths from code/ directory, then workspace root
shrug_dir <- "../../../data/india_shrug"
if (!dir.exists(shrug_dir)) shrug_dir <- "../../data/india_shrug"
if (!dir.exists(shrug_dir)) shrug_dir <- file.path(Sys.getenv("SHRUG_DIR", "data/india_shrug"))
stopifnot("SHRUG directory not found — set SHRUG_DIR env var" = dir.exists(shrug_dir))

cat("Loading SHRUG VIIRS nightlights...\n")
viirs <- fread(file.path(shrug_dir, "viirs_annual_pc11dist.csv"))
viirs <- viirs[category == "median-masked"]
cat(sprintf("  VIIRS: %d district-years, years %d-%d\n",
            nrow(viirs), min(viirs$year), max(viirs$year)))

cat("Loading SHRUG crosswalk...\n")
td <- fread(file.path(shrug_dir, "pc11_td_clean_pc11dist.csv"))
cat(sprintf("  Crosswalk: %d districts\n", nrow(td)))

cat("Loading Census 2011 population...\n")
pca <- fread(file.path(shrug_dir, "pc11_pca_clean_pc11dist.csv"))
cat(sprintf("  Census: %d districts\n", nrow(pca)))

# ── 2. State name/ID mapping ──────────────────────────────────────────

state_map <- data.table(
  pc11_state_id = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
                    17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
                    31, 32, 33, 34, 35, 36),
  state_name = c(
    "Jammu and Kashmir", "Himachal Pradesh", "Punjab", "Chandigarh",
    "Uttarakhand", "Haryana", "Delhi", "Rajasthan", "Uttar Pradesh",
    "Bihar", "Sikkim", "Arunachal Pradesh", "Nagaland", "Manipur",
    "Mizoram", "Tripura", "Meghalaya", "Assam", "West Bengal",
    "Jharkhand", "Odisha", "Chhattisgarh", "Madhya Pradesh", "Gujarat",
    "Daman and Diu", "Dadra and Nagar Haveli", "Maharashtra",
    "Andhra Pradesh", "Karnataka", "Goa", "Lakshadweep", "Kerala",
    "Tamil Nadu", "Puducherry", "Andaman and Nicobar Islands", "Telangana"
  ),
  # Approximate state centroids (lat, lon) for NASA POWER queries
  lat = c(33.7, 31.1, 31.1, 30.7, 30.1, 29.0, 28.7, 27.0, 26.8, 25.6,
          27.5, 28.2, 26.2, 24.8, 23.2, 23.9, 25.5, 26.2, 22.9, 23.6,
          20.9, 21.3, 23.5, 22.3, 20.4, 20.1, 19.7, 15.9, 15.3, 15.4,
          10.6, 10.9, 11.1, 11.9, 11.7, 18.1),
  lon = c(76.8, 77.2, 75.3, 76.8, 79.0, 76.1, 77.1, 74.2, 80.9, 85.1,
          88.5, 94.7, 94.6, 94.0, 92.9, 91.9, 91.4, 92.9, 87.9, 85.3,
          84.0, 82.0, 78.6, 71.6, 72.8, 73.0, 75.7, 78.6, 75.7, 74.0,
          72.6, 76.3, 78.7, 79.8, 92.7, 79.0)
)

# ── 3. NASA POWER monthly precipitation ───────────────────────────────
# API: https://power.larc.nasa.gov/api/temporal/monthly/point
# No API key required. Free access.
# Parameter: PRECTOTCORR = corrected total precipitation (mm/day)

cat("Fetching NASA POWER monthly precipitation for Indian states...\n")
cat("  (This may take a few minutes...)\n")

# Only query major states (exclude small UTs with state_id > 30 or < 4, except Delhi)
major_states <- state_map[!(pc11_state_id %in% c(4, 25, 26, 31, 34, 35))]

rain_list <- list()
for (i in seq_len(nrow(major_states))) {
  st <- major_states[i]
  url <- sprintf(
    "https://power.larc.nasa.gov/api/temporal/monthly/point?parameters=PRECTOTCORR&community=AG&longitude=%.1f&latitude=%.1f&start=2012&end=2021&format=JSON",
    st$lon, st$lat
  )

  cat(sprintf("  %s (%.1f, %.1f)...", st$state_name, st$lat, st$lon))

  resp <- tryCatch({
    con <- url(url)
    raw <- readLines(con, warn = FALSE)
    close(con)
    fromJSON(paste(raw, collapse = ""))
  }, error = function(e) {
    cat(sprintf(" FAILED: %s\n", e$message))
    NULL
  })

  if (is.null(resp) || is.null(resp$properties$parameter$PRECTOTCORR)) {
    cat(" NO DATA\n")
    next
  }

  precip_vals <- resp$properties$parameter$PRECTOTCORR
  months <- names(precip_vals)
  vals <- unlist(precip_vals)

  # Parse YYYYMM format
  dt <- data.table(
    pc11_state_id = st$pc11_state_id,
    state_name = st$state_name,
    yearmonth = months,
    precip_mm_day = vals
  )
  dt[, year := as.integer(substr(yearmonth, 1, 4))]
  dt[, month := as.integer(substr(yearmonth, 5, 6))]
  # Remove annual summaries (month 13)
  dt <- dt[month <= 12]

  rain_list[[i]] <- dt
  cat(sprintf(" OK (%d months)\n", nrow(dt)))

  Sys.sleep(1)  # Rate limit: be courteous
}

rain_all <- rbindlist(rain_list, fill = TRUE)

stopifnot("No rainfall data fetched" = nrow(rain_all) > 500)

cat(sprintf("  Total rainfall records: %d state-months\n", nrow(rain_all)))

# ── 4. Competing events calendar ──────────────────────────────────────
# Major global events during India's monsoon season (June-September)
# These absorb media attention and crowd out Indian flood coverage.
# Sources: Wikipedia, official event calendars

competing_events <- data.table(
  year = 2012:2021,
  # Index: number of major competing global events during Jun-Sep
  # Scaled 0-1 where 1 = maximum competing news
  competing_index = c(
    0.7,   # 2012: London Olympics (Jul 27 - Aug 12), US election campaign
    0.3,   # 2013: Relatively quiet global news
    0.6,   # 2014: FIFA World Cup (Jun 12 - Jul 13), Iraq/ISIS crisis
    0.3,   # 2015: Greek debt crisis (Jan-Jul), relatively quiet monsoon period
    0.8,   # 2016: Rio Olympics (Aug 5-21), Brexit fallout, US election
    0.4,   # 2017: North Korea missile tests, Charlottesville
    0.7,   # 2018: FIFA World Cup (Jun 14 - Jul 15), Trump-Kim summit
    0.5,   # 2019: ICC Cricket World Cup (May 30 - Jul 14), Indian elections aftermath
    1.0,   # 2020: COVID-19 pandemic dominates ALL coverage
    0.8    # 2021: Tokyo Olympics (Jul 23 - Aug 8), COVID variants, Afghanistan
  ),
  # Binary: major sporting event during monsoon
  sports_event = c(1, 0, 1, 0, 1, 0, 1, 1, 0, 1),
  # Description for documentation
  event_description = c(
    "London Olympics", "Quiet", "FIFA World Cup + ISIS",
    "Greek debt crisis", "Rio Olympics + Brexit + US election",
    "North Korea missiles", "FIFA World Cup", "ICC Cricket World Cup",
    "COVID-19 pandemic", "Tokyo Olympics + COVID + Afghanistan"
  )
)

# ── Save all raw data ─────────────────────────────────────────────────

cat("Saving raw data...\n")
dir.create("data", showWarnings = FALSE, recursive = TRUE)
fwrite(viirs, "data/shrug_viirs_district.csv")
fwrite(td, "data/shrug_crosswalk.csv")
fwrite(pca, "data/shrug_census2011.csv")
fwrite(state_map, "data/state_map.csv")
fwrite(rain_all, "data/nasa_power_rainfall.csv")
fwrite(competing_events, "data/competing_events.csv")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("  Nightlights: %d district-years (%d-%d)\n",
            nrow(viirs), min(viirs$year), max(viirs$year)))
cat(sprintf("  Rainfall: %d state-months\n", nrow(rain_all)))
cat(sprintf("  Competing events: %d years\n", nrow(competing_events)))
cat(sprintf("  Districts: %d\n", nrow(td)))
