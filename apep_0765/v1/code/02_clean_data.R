# ============================================================
# 02_clean_data.R — Build tract-year merged panel
# apep_0765: SNAP Retailer Exits and Mortgage Access
# ============================================================

source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"

# ----------------------------------------------------------
# 1. Load data
# ----------------------------------------------------------
cat("=== Loading data ===\n")
hmda <- readRDS(file.path(data_dir, "hmda_tract_year.rds"))
retailers <- fread(file.path(data_dir, "snap_retailers_raw.csv"), showProgress = FALSE)
setnames(retailers, gsub(" ", "_", names(retailers)))

# ----------------------------------------------------------
# 2. Build SNAP supermarket exits by tract-year
# ----------------------------------------------------------
cat("\n=== Building SNAP supermarket exits by tract ===\n")

retailers[, auth_date := as.Date(Authorization_Date, format = "%m/%d/%Y")]
retailers[, end_date := as.Date(End_Date, format = "%m/%d/%Y")]
retailers[, exited := !is.na(end_date)]
retailers[, is_supermarket := Store_Type %in% c("Large Grocery Store",
                                                  "Supermarket", "Super Store")]

# Build tract from Zip + geocoding
# The SNAP data has lat/lon. For tract-level, we need census tract FIPS.
# Census tract is 11 digits: 2-digit state + 3-digit county + 6-digit tract
# The SNAP data doesn't have tract FIPS directly.
# We need to geocode lat/lon to tract.

# Alternative: Use Zip Code to approximate tract via crosswalk.
# But Zip-to-tract is many-to-many.

# Best for V1: aggregate SNAP exits to county level, then merge HMDA
# tracts to county-year. Less precise but avoids geocoding.

# Actually, let me use the county FIPS approach from apep_0757.
# Extract county from state + county name → county FIPS crosswalk.

# Download FIPS crosswalk
cat("  Fetching county FIPS crosswalk...\n")
fips_url <- "https://www2.census.gov/geo/docs/reference/codes2020/national_county2020.txt"
resp <- httr::GET(fips_url, httr::timeout(30))
stopifnot("FIPS download failed" = httr::status_code(resp) == 200)
fips_text <- httr::content(resp, "text", encoding = "UTF-8")
fips_xwalk <- fread(text = fips_text, sep = "|", header = TRUE)

# State FIPS mapping
state_fips_map <- data.table(
  State = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
            "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
            "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
            "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
            "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,
                                  15,16,17,18,19,20,21,22,23,24,
                                  25,26,27,28,29,30,31,32,33,34,
                                  35,36,37,38,39,40,41,42,44,45,
                                  46,47,48,49,50,51,53,54,55,56))
)

retailers <- merge(retailers, state_fips_map, by = "State", all.x = TRUE)

fips_xwalk[, county_fips := paste0(sprintf("%02d", as.integer(STATEFP)),
                                    sprintf("%03d", as.integer(COUNTYFP)))]
fips_xwalk[, state_fips := sprintf("%02d", as.integer(STATEFP))]
fips_xwalk[, county_name_clean := toupper(gsub(" County$| Parish$| Borough$| Census Area$| Municipality$| city$", "",
                                                 COUNTYNAME))]

retailers[, county_name_clean := toupper(gsub(" County$| Parish$| Borough$", "", County))]

# Merge to get county FIPS for each retailer
snap_fips <- merge(retailers[, .(Record_ID, state_fips, county_name_clean,
                                  is_supermarket, exited, end_date)],
                   fips_xwalk[, .(state_fips, county_name_clean, county_fips)],
                   by = c("state_fips", "county_name_clean"),
                   all.x = TRUE)
snap_fips <- unique(snap_fips, by = "Record_ID")

cat("  SNAP → county FIPS match rate:", round(mean(!is.na(snap_fips$county_fips)) * 100, 1), "%\n")

# Supermarket exits by county-year
snap_fips[, exit_year := year(end_date)]
sm_exits <- snap_fips[is_supermarket == TRUE & exited == TRUE &
                        exit_year >= 2015 & exit_year <= 2023 &
                        !is.na(county_fips),
                      .(n_sm_exits = .N),
                      by = .(county_fips, exit_year)]

# First SM exit per county
first_sm_exit <- sm_exits[, .(first_exit_year = min(exit_year)),
                           by = county_fips]

cat("  Counties with SM exits:", nrow(first_sm_exit), "\n")

# ----------------------------------------------------------
# 3. Merge HMDA with SNAP treatment at county level
# ----------------------------------------------------------
cat("\n=== Merging HMDA with SNAP treatment ===\n")

# Extract county FIPS from HMDA tract (first 5 digits of 11-digit tract)
hmda[, county_fips := substr(tract, 1, 5)]

# County-year HMDA aggregates
county_hmda <- hmda[, .(
  n_originations = sum(n_originations, na.rm = TRUE),
  n_denials = sum(n_denials, na.rm = TRUE),
  n_applications = sum(n_applications, na.rm = TRUE),
  median_loan = median(median_loan, na.rm = TRUE),
  n_fha = sum(n_fha, na.rm = TRUE),
  n_tracts = .N
), by = .(county_fips, year)]

county_hmda[, denial_rate := n_denials / pmax(n_applications, 1)]
county_hmda[, fha_share := n_fha / pmax(n_originations, 1)]
county_hmda[, ln_orig := log(pmax(n_originations, 1))]
county_hmda[, ln_loan := log(pmax(median_loan, 1))]

# Merge treatment
panel <- merge(county_hmda, first_sm_exit, by = "county_fips", all.x = TRUE)

# Treatment: post-first-exit
panel[is.na(first_exit_year), first_exit_year := 9999L]  # never-treated
panel[, treated := as.integer(year >= first_exit_year)]
panel[first_exit_year == 9999, treated := 0L]

# For CS estimator: group variable (0 = never-treated)
panel[, first_treat := ifelse(first_exit_year == 9999, 0L, first_exit_year)]

# Numeric county ID
county_map <- data.table(county_fips = sort(unique(panel$county_fips)),
                          county_id = seq_along(sort(unique(panel$county_fips))))
panel <- merge(panel, county_map, by = "county_fips")

# Extract state for clustering
panel[, state_fips := substr(county_fips, 1, 2)]

cat("  Panel rows:", format(nrow(panel), big.mark = ","), "\n")
cat("  Counties:", length(unique(panel$county_fips)), "\n")
cat("  Treated (ever):", sum(panel$first_treat > 0 & !duplicated(panel$county_fips)), "\n")
cat("  Never-treated:", sum(panel$first_treat == 0 & !duplicated(panel$county_fips)), "\n")
cat("  Years:", min(panel$year), "-", max(panel$year), "\n")

# ----------------------------------------------------------
# 4. Summary statistics
# ----------------------------------------------------------
cat("\n=== Pre-treatment Summary ===\n")
pre <- panel[treated == 0]
cat("  Denial rate (mean):", round(mean(pre$denial_rate, na.rm = TRUE), 4), "\n")
cat("  Denial rate (sd):", round(sd(pre$denial_rate, na.rm = TRUE), 4), "\n")
cat("  Log originations (mean):", round(mean(pre$ln_orig, na.rm = TRUE), 2), "\n")
cat("  Log originations (sd):", round(sd(pre$ln_orig, na.rm = TRUE), 2), "\n")
cat("  FHA share (mean):", round(mean(pre$fha_share, na.rm = TRUE), 4), "\n")
cat("  Median loan (mean):", round(mean(pre$median_loan, na.rm = TRUE), 0), "\n")

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\n=== Cleaning complete ===\n")
