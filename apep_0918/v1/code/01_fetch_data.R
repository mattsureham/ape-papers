## 01_fetch_data.R — Fetch LAQN NO2 data using openair package
## APEP paper apep_0918: ULEZ expansion and NO2

source("code/00_packages.R")

if (!requireNamespace("openair", quietly = TRUE)) {
  install.packages("openair", repos = "https://cloud.r-project.org")
}
library(openair)

cat("=== Step 1: Get London monitoring site metadata ===\n")

## Get all KCL sites
all_sites <- as.data.table(importMeta(source = "kcl"))
cat(sprintf("  Total KCL sites: %d\n", nrow(all_sites)))

## London boroughs (all 32 + City of London)
london_boroughs <- c(
  "Barking and Dagenham", "Barnet", "Bexley", "Brent", "Bromley",
  "Camden", "Croydon", "Ealing", "Enfield", "Greenwich",
  "Hackney", "Hammersmith and Fulham", "Haringey", "Harrow", "Havering",
  "Hillingdon", "Hounslow", "Islington", "Kensington and Chelsea",
  "Kingston upon Thames", "Lambeth", "Lewisham", "Merton", "Newham",
  "Redbridge", "Richmond upon Thames", "Southwark", "Sutton",
  "Tower Hamlets", "Waltham Forest", "Wandsworth", "Westminster",
  "City of London"
)

## Filter to London-area sites using coordinates (roughly London bounding box)
london_sites <- all_sites[latitude > 51.28 & latitude < 51.70 &
                           longitude > -0.52 & longitude < 0.35]
cat(sprintf("  London-area sites (by coordinates): %d\n", nrow(london_sites)))

## ---- 2. Inner vs Outer London classification ----
## The ULEZ expanded in Oct 2021 to the area inside the North/South Circular roads.
## Inner London boroughs (official ONS definition) are mostly inside the ULEZ:
inner_boroughs <- c(
  "Camden", "City of London", "Greenwich", "Hackney",
  "Hammersmith and Fulham", "Haringey", "Islington",
  "Kensington and Chelsea", "Lambeth", "Lewisham", "Newham",
  "Southwark", "Tower Hamlets", "Wandsworth", "Westminster"
)

## Match sites to boroughs using the site name (which often includes borough)
london_sites[, borough := ""]
for (b in london_boroughs) {
  london_sites[grepl(b, site, ignore.case = TRUE), borough := b]
}

## For unmatched, use coordinate-based classification
## Approximate ULEZ boundary: inside North/South Circular ≈ within ~8km of Charing Cross
charing_cross <- c(lat = 51.5074, lon = -0.1278)
london_sites[, dist_center_km := distHaversine(
  matrix(c(longitude, latitude), ncol = 2),
  matrix(c(charing_cross["lon"], charing_cross["lat"]), ncol = 2, nrow = .N, byrow = TRUE)
) / 1000]

## Classify as inner if borough is inner, or if unmatched and within ~8km of center
london_sites[, inner_london := borough %in% inner_boroughs]
london_sites[borough == "" & dist_center_km <= 8, inner_london := TRUE]
london_sites[borough == "" & dist_center_km > 8, inner_london := FALSE]

cat(sprintf("  Initial inner: %d, outer: %d\n",
            sum(london_sites$inner_london), sum(!london_sites$inner_london)))

## ---- 3. Fetch hourly NO2 data ----
cat("=== Step 2: Fetch hourly NO2 (2018-2023) ===\n")

## Filter to relevant site types first
london_sites <- london_sites[site_type %in% c("Roadside", "Kerbside", "Suburban", "Urban Background")]
cat(sprintf("  Monitoring sites (relevant types): %d\n", nrow(london_sites)))

site_codes <- london_sites$code
years <- 2018:2023

## Fetch in batches of 50 sites (openair supports multi-site)
batch_size <- 50
all_data <- list()

for (b in seq(1, length(site_codes), by = batch_size)) {
  batch_end <- min(b + batch_size - 1, length(site_codes))
  batch_codes <- site_codes[b:batch_end]
  cat(sprintf("  Fetching batch %d-%d of %d...\n", b, batch_end, length(site_codes)))
  flush.console()

  dat <- tryCatch({
    suppressMessages(importKCL(site = batch_codes, year = years, pollutant = "no2"))
  }, error = function(e) {
    cat(sprintf("  Batch error: %s\n", e$message))
    NULL
  })

  if (!is.null(dat) && nrow(dat) > 0) {
    all_data[[as.character(b)]] <- as.data.table(dat)
  }
}

hourly <- rbindlist(all_data, fill = TRUE)
cat(sprintf("  Total hourly observations: %s\n", format(nrow(hourly), big.mark = ",")))

## Remove rows where NO2 is NA
hourly <- hourly[!is.na(no2)]
cat(sprintf("  Non-null NO2 observations: %s\n", format(nrow(hourly), big.mark = ",")))
cat(sprintf("  Unique sites with NO2: %d\n", uniqueN(hourly$code)))

stopifnot("No data fetched" = nrow(hourly) > 0)

## ---- 4. Aggregate to station-month means ----
cat("=== Step 3: Aggregate to station-month ===\n")

hourly[, year_month := format(date, "%Y-%m")]
hourly[, year := as.integer(format(date, "%Y"))]
hourly[, month := as.integer(format(date, "%m"))]

## Compute monthly means
monthly <- hourly[, .(
  no2_mean = mean(no2, na.rm = TRUE),
  no2_sd = sd(no2, na.rm = TRUE),
  no2_median = median(no2, na.rm = TRUE),
  n_hours = .N
), by = .(site_code = code, year_month, year, month)]

## Days per month for coverage
monthly[, days_month := ifelse(month %in% c(1,3,5,7,8,10,12), 31L,
                               ifelse(month %in% c(4,6,9,11), 30L,
                                      ifelse(year %% 4 == 0 & (year %% 100 != 0 | year %% 400 == 0), 29L, 28L)))]
monthly[, coverage := n_hours / (24 * days_month)]

## Require >=75% hourly coverage per station-month
monthly_clean <- monthly[coverage >= 0.75]
cat(sprintf("  Station-months (>=75%% coverage): %s\n", format(nrow(monthly_clean), big.mark = ",")))

## ---- 5. Restrict to study window: Jan 2018 - Aug 2023 ----
monthly_clean <- monthly_clean[year_month >= "2018-01" & year_month <= "2023-08"]

## ---- 6. Merge with station metadata ----
panel <- merge(monthly_clean,
               london_sites[, .(site_code = code, site_name = site, site_type,
                                latitude, longitude, inner_london, dist_center_km, borough)],
               by = "site_code", all.x = TRUE)

## Drop stations not in our London site list
panel <- panel[!is.na(inner_london)]

## Create analysis variables
panel[, time_index := (year - 2018L) * 12L + month]
panel[, treat := as.integer(inner_london)]
panel[, post := as.integer(year_month >= "2021-11")]  # First full month after Oct 25
panel[, treat_post := treat * post]
panel[, ln_no2 := log(no2_mean + 1)]

## Site type indicators
panel[, roadside := as.integer(site_type %in% c("Roadside", "Kerbside"))]

## Compute distance from approximate ULEZ boundary (N/S Circular)
boundary_pts <- matrix(c(
  -0.234, 51.534,   # North Circular west
  -0.172, 51.573,   # North Circular north
  -0.098, 51.589,   # North Circular northeast
  -0.038, 51.563,   # North Circular east
   0.030, 51.536,   # A13 south
   0.012, 51.490,   # South Circular east
  -0.044, 51.453,   # South Circular southeast
  -0.110, 51.442,   # South Circular south
  -0.185, 51.454,   # South Circular southwest
  -0.248, 51.480,   # South Circular west
  -0.264, 51.510,   # Connecting to North Circular
  -0.234, 51.534    # Close loop
), ncol = 2, byrow = TRUE)

panel[, dist_boundary_km := mapply(function(lat, lon) {
  min(distHaversine(matrix(c(lon, lat), ncol = 2), boundary_pts)) / 1000
}, latitude, longitude)]
## Sign: negative for inner (inside ULEZ), positive for outer
panel[treat == 1, dist_boundary_km := -dist_boundary_km]

## CS first_treat variable: 47 = Nov 2021 for inner, 0 for never-treated
panel[, first_treat := ifelse(treat == 1, 47L, 0L)]

## ---- 7. Save ----
fwrite(panel, "data/panel.csv")
fwrite(london_sites, "data/sites_metadata.csv")

cat("\n=== Data saved ===\n")
cat(sprintf("  Unique stations: %d (inner: %d, outer: %d)\n",
            uniqueN(panel$site_code),
            uniqueN(panel[treat == 1]$site_code),
            uniqueN(panel[treat == 0]$site_code)))
cat(sprintf("  Station-months: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  Date range: %s to %s\n", min(panel$year_month), max(panel$year_month)))
cat(sprintf("  Mean NO2 (pre-treat, inner): %.1f ug/m3\n",
            mean(panel[treat == 1 & post == 0]$no2_mean)))
cat(sprintf("  Mean NO2 (pre-treat, outer): %.1f ug/m3\n",
            mean(panel[treat == 0 & post == 0]$no2_mean)))
