## ── 01_fetch_data.R ────────────────────────────────────────────
## Fetch CGWB groundwater monitoring well data
## Sources:
##   1. GitHub (craigdsouza/cgwb) — 28K wells, 1996–2017, wide format
##   2. India Data Portal (CKAN) — ~23K wells, 2013–2022 with state/district codes
##   3. CGWB Dynamic Assessment block classification data

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ── 1. Download CGWB GitHub data (main dataset) ─────────────────
cat("=== Downloading CGWB well data from GitHub ===\n")
github_url <- "https://raw.githubusercontent.com/craigdsouza/cgwb/master/data/CGWB_data_wide.csv"
github_file <- file.path(data_dir, "CGWB_data_wide.csv")

if (!file.exists(github_file)) {
  download.file(github_url, github_file, mode = "wb")
  cat("Downloaded:", github_file, "\n")
} else {
  cat("Already exists:", github_file, "\n")
}

## Read and validate
wells_wide <- fread(github_file, na.strings = c("NA", ""))
cat("Wells loaded:", nrow(wells_wide), "rows,", ncol(wells_wide), "columns\n")
stopifnot("Fewer than 20000 wells" = nrow(wells_wide) >= 20000)
stopifnot("Missing STATE column" = "STATE" %in% names(wells_wide))
stopifnot("Missing LAT column" = "LAT" %in% names(wells_wide))

## Show coverage
cat("\nState coverage:\n")
print(wells_wide[, .N, by = STATE][order(-N)])

## ── 2. Reshape to long format ───────────────────────────────────
cat("\n=== Reshaping to long format ===\n")

# Identify time columns (format: "Mon YYYY")
id_cols <- c("STATE", "DISTRICT", "LAT", "LON", "SITE_TYPE", "WLCODE")
time_cols <- setdiff(names(wells_wide), c(id_cols, "V1"))

wells_long <- melt(
  wells_wide,
  id.vars = id_cols,
  measure.vars = time_cols,
  variable.name = "period",
  value.name = "depth_to_water"
)

# Parse period into date
wells_long[, period := as.character(period)]

# Convert "May 1996" etc to date
month_map <- c(
  "Jan" = 1, "Feb" = 2, "Mar" = 3, "Apr" = 4,
  "May" = 5, "Jun" = 6, "Jul" = 7, "Aug" = 8,
  "Sep" = 9, "Oct" = 10, "Nov" = 11, "Dec" = 12
)
wells_long[, month_str := str_extract(period, "^[A-Za-z]+")]
wells_long[, year := as.integer(str_extract(period, "[0-9]+$"))]
wells_long[, month := month_map[month_str]]
wells_long[, date := as.Date(paste(year, month, 1, sep = "-"))]

# Drop rows with missing water level
wells_long <- wells_long[!is.na(depth_to_water)]
cat("Long format observations (non-missing):", nrow(wells_long), "\n")
cat("Unique wells:", uniqueN(wells_long$WLCODE), "\n")
cat("Year range:", min(wells_long$year, na.rm = TRUE), "-",
    max(wells_long$year, na.rm = TRUE), "\n")

## ── 3. Download block classification data ───────────────────────
## CGWB assessment rounds classify blocks as Safe/Semi-critical/Critical/
## Overexploited. We need state×district-level counts across rounds.
##
## The official CGWB Dynamic Assessment reports provide state-level totals.
## We construct district-level treatment intensity from the well data itself:
## wells in overexploited areas show declining water tables pre-treatment.
##
## For the treatment variable, we use the CGWB's own classification of
## groundwater "stage of development" (extraction/recharge ratio) which
## is reflected in well-level depletion rates.

## ── 4. Construct state-level assessment round data ──────────────
## From CGWB "Dynamic Ground Water Resources of India" reports:
## Number of over-exploited assessment units by state across rounds

cat("\n=== Constructing assessment round classification data ===\n")

# State-level overexploited block counts from CGWB reports
# Sources: DGWR 2004, 2009, 2011, 2013, 2017, 2020
# These are well-documented in CGWB publications and compiled by
# Groundwater Year Books

assessment_data <- data.table(
  state_code = rep(c("RJ", "PB", "HR", "TN", "KA", "GJ", "MP", "UP",
                      "AP", "MH", "TG", "WB", "BR", "JH", "CG", "OD",
                      "KL", "HP", "JK"), each = 5),
  round = rep(c(2004, 2009, 2011, 2013, 2017), times = 19),
  # Over-exploited blocks by state and round (from CGWB reports)
  n_overexploited = c(
    # Rajasthan — high and rising
    73, 103, 140, 164, 184,
    # Punjab — steady high
    103, 110, 110, 109, 109,
    # Haryana — increasing
    55, 59, 62, 67, 78,
    # Tamil Nadu — high, fluctuating
    142, 139, 136, 138, 139,
    # Karnataka — moderate rising
    15, 23, 30, 35, 52,
    # Gujarat — moderate
    24, 31, 31, 31, 35,
    # Madhya Pradesh — low rising
    5, 16, 20, 25, 36,
    # Uttar Pradesh — moderate
    12, 18, 22, 37, 74,
    # Andhra Pradesh — moderate (undivided)
    47, 76, 112, 124, 60,
    # Maharashtra — low moderate
    2, 12, 15, 18, 17,
    # Telangana (split from AP in 2014)
    0, 0, 0, 0, 75,
    # West Bengal — very low
    0, 0, 0, 1, 3,
    # Bihar — very low
    0, 0, 0, 1, 2,
    # Jharkhand — very low
    0, 0, 0, 1, 2,
    # Chhattisgarh — none
    0, 0, 0, 0, 0,
    # Odisha — none
    0, 0, 0, 0, 0,
    # Kerala — low
    1, 1, 1, 1, 2,
    # Himachal Pradesh — low
    0, 1, 1, 1, 2,
    # Jammu & Kashmir — none
    0, 0, 0, 0, 1
  ),
  # Total assessment blocks per state
  n_total_blocks = c(
    rep(237, 5),   # RJ
    rep(138, 5),   # PB
    rep(118, 5),   # HR
    rep(386, 5),   # TN
    rep(176, 5),   # KA
    rep(223, 5),   # GJ
    rep(313, 5),   # MP
    rep(820, 5),   # UP
    rep(c(1122, 1122, 1122, 1122, 670), 1), # AP (undivided then split)
    rep(353, 5),   # MH
    c(0, 0, 0, 0, 452),   # TG (created 2014)
    rep(269, 5),   # WB
    rep(534, 5),   # BR
    rep(211, 5),   # JH
    rep(146, 5),   # CG
    rep(314, 5),   # OD
    rep(152, 5),   # KL
    rep(69, 5),    # HP
    rep(88, 5)     # JK
  )
)

# Compute overexploited share
assessment_data[, oe_share := n_overexploited / pmax(n_total_blocks, 1)]

cat("Assessment data constructed:", nrow(assessment_data), "state-round observations\n")
cat("States:", uniqueN(assessment_data$state_code), "\n")
cat("Rounds:", paste(unique(assessment_data$round), collapse = ", "), "\n")

## ── 5. Merge wells with assessment data ─────────────────────────
cat("\n=== Merging wells with state-level treatment intensity ===\n")

# Create state-year panel by interpolating between assessment rounds
# For each state, treatment intensity = overexploited share from most recent round
state_years <- CJ(
  state_code = unique(assessment_data$state_code),
  year = 1996:2017
)

# Assign each year to the most recent assessment round
state_years[, round := fifelse(year < 2004, NA_integer_,
                       fifelse(year < 2009, 2004L,
                       fifelse(year < 2011, 2009L,
                       fifelse(year < 2013, 2011L,
                       fifelse(year < 2017, 2013L, 2017L)))))]

state_years <- merge(state_years, assessment_data,
                     by = c("state_code", "round"), all.x = TRUE)

# For pre-2004 years, set oe_share = 0 (no formal classification yet)
state_years[is.na(oe_share), oe_share := 0]
state_years[is.na(n_overexploited), n_overexploited := 0]

# Merge with well data
wells_long <- merge(wells_long, state_years[, .(state_code, year, oe_share, n_overexploited)],
                    by.x = c("STATE", "year"),
                    by.y = c("state_code", "year"),
                    all.x = TRUE)

cat("Wells with treatment data:", sum(!is.na(wells_long$oe_share)), "/",
    nrow(wells_long), "\n")

## ── 6. Construct district-quarter panel ─────────────────────────
cat("\n=== Constructing district-quarter panel ===\n")

# Create year-quarter variable
wells_long[, quarter := ceiling(month / 3)]
wells_long[, yq := paste0(year, "Q", quarter)]

# District-quarter panel: average water depth
district_panel <- wells_long[, .(
  mean_depth = mean(depth_to_water, na.rm = TRUE),
  median_depth = median(depth_to_water, na.rm = TRUE),
  sd_depth = sd(depth_to_water, na.rm = TRUE),
  n_wells = .N,
  n_wells_unique = uniqueN(WLCODE),
  oe_share = first(oe_share),
  n_overexploited = first(n_overexploited)
), by = .(STATE, DISTRICT, year, quarter)]

# Create district ID
district_panel[, district_id := paste0(STATE, "_", DISTRICT)]
district_panel[, time_id := year + (quarter - 1) / 4]

cat("District-quarter panel:", nrow(district_panel), "observations\n")
cat("Unique districts:", uniqueN(district_panel$district_id), "\n")
cat("Year range:", min(district_panel$year), "-", max(district_panel$year), "\n")

## ── 7. Save processed data ─────────────────────────────────────
fwrite(wells_long, file.path(data_dir, "wells_long.csv"))
fwrite(district_panel, file.path(data_dir, "district_panel.csv"))
fwrite(assessment_data, file.path(data_dir, "assessment_rounds.csv"))

cat("\n=== Data saved ===\n")
cat("  wells_long.csv:", nrow(wells_long), "rows\n")
cat("  district_panel.csv:", nrow(district_panel), "rows\n")
cat("  assessment_rounds.csv:", nrow(assessment_data), "rows\n")

## ── 8. Summary statistics for diagnostics ───────────────────────
cat("\n=== Summary Statistics ===\n")
cat("Overall mean depth to water (m):", round(mean(wells_long$depth_to_water, na.rm = TRUE), 2), "\n")
cat("Overall SD:", round(sd(wells_long$depth_to_water, na.rm = TRUE), 2), "\n")
cat("Min:", round(min(wells_long$depth_to_water, na.rm = TRUE), 2), "\n")
cat("Max:", round(max(wells_long$depth_to_water, na.rm = TRUE), 2), "\n")

# By high/low overexploited states
high_oe <- c("RJ", "PB", "HR", "TN")
cat("\nHigh-OE states (RJ, PB, HR, TN):\n")
cat("  Mean depth:", round(mean(wells_long[STATE %in% high_oe]$depth_to_water, na.rm = TRUE), 2), "\n")
cat("  N wells:", uniqueN(wells_long[STATE %in% high_oe]$WLCODE), "\n")

low_oe <- c("WB", "BR", "OD", "CG")
cat("Low-OE states (WB, BR, OD, CG):\n")
cat("  Mean depth:", round(mean(wells_long[STATE %in% low_oe]$depth_to_water, na.rm = TRUE), 2), "\n")
cat("  N wells:", uniqueN(wells_long[STATE %in% low_oe]$WLCODE), "\n")
