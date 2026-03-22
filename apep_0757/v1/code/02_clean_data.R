# ============================================================
# 02_clean_data.R — Build county-quarter analysis panel
# apep_0757: The Racial Anatomy of Food Desert Formation
# ============================================================

source("00_packages.R")
library(fixest)
library(did)
library(data.table)
library(dplyr)

data_dir <- "../data"

# ----------------------------------------------------------
# 1. Clean QWI data
# ----------------------------------------------------------
cat("=== Cleaning QWI data ===\n")

qwi <- readRDS(file.path(data_dir, "qwi_445_race.rds"))
setDT(qwi)

# Race codes: A0=All, A1=White alone, A2=Black alone, A3=Asian,
# A4=AIAN, A5=NHPI, A7=Two+
# Focus on A1 (White) and A2 (Black) for clean comparison
cat("  Race distribution:\n")
print(table(qwi$race))

# Filter to county-level, key race groups, key variables
qwi_clean <- qwi[geo_level == "C" &
                    race %in% c("A0", "A1", "A2") &
                    sex == 0 &          # All sexes
                    agegrp == "A00" &   # All ages
                    ownercode == "A05", # All ownership
                  .(geography, year, quarter, race,
                    Emp, EmpEnd, HirA, Sep, EarnS, Payroll,
                    FrmJbGn, FrmJbLs)]

# Create county FIPS (5-digit)
qwi_clean[, county_fips := sprintf("%05d", as.integer(geography))]
qwi_clean[, yearqtr := paste0(year, "Q", quarter)]
qwi_clean[, time_id := (year - 2005) * 4 + quarter]

# Convert race to readable labels
qwi_clean[, race_label := fcase(
  race == "A0", "all",
  race == "A1", "white",
  race == "A2", "black"
)]

cat("  Cleaned QWI rows:", format(nrow(qwi_clean), big.mark = ","), "\n")
cat("  Counties:", length(unique(qwi_clean$county_fips)), "\n")
cat("  Year range:", min(qwi_clean$year), "-", max(qwi_clean$year), "\n")

# ----------------------------------------------------------
# 2. Clean SNAP retailer data — county-quarter exits
# ----------------------------------------------------------
cat("\n=== Building SNAP supermarket exit panel ===\n")

retailers <- fread(file.path(data_dir, "snap_retailers_raw.csv"),
                   showProgress = FALSE)
setnames(retailers, gsub(" ", "_", names(retailers)))

retailers[, auth_date := as.Date(Authorization_Date, format = "%m/%d/%Y")]
retailers[, end_date := as.Date(End_Date, format = "%m/%d/%Y")]
retailers[, exited := !is.na(end_date)]

# Classify store types
retailers[, is_supermarket := Store_Type %in% c("Large Grocery Store",
                                                  "Supermarket", "Super Store")]
retailers[, is_convenience := Store_Type == "Convenience Store"]

# Build county FIPS from County field (need state + county)
# Use the State abbreviation mapped to FIPS
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

# County FIPS: try to extract from County field + state FIPS
# The County field in the SNAP data is the county name. We need FIPS.
# Use the Latitude/Longitude instead — or geocode.
# Actually, let me use the 5-digit FIPS from Zip Code → county crosswalk
# Simplest: use state FIPS + first 3 digits as county... no, that's wrong.
# Better approach: group by (State, County) and count exits per group.

# For now, use county name as the grouping variable
retailers[, county_name := County]
retailers[, exit_year := year(end_date)]
retailers[, exit_quarter := quarter(end_date)]
retailers[, exit_yearqtr := ifelse(exited, paste0(exit_year, "Q", exit_quarter), NA)]

# Count supermarket exits per state-county-quarter
# Analysis period: 2005Q1 to 2024Q4
all_quarters <- data.table(
  year = rep(2005:2024, each = 4),
  quarter = rep(1:4, 20)
)
all_quarters[, time_id := .I]

# For each state-county, count supermarket exits per quarter
sm_exits <- retailers[is_supermarket == TRUE & exited == TRUE &
                        exit_year >= 2005 & exit_year <= 2024,
                      .N,
                      by = .(state_fips, county_name, exit_year, exit_quarter)]
setnames(sm_exits, c("exit_year", "exit_quarter", "N"),
         c("year", "quarter", "n_sm_exits"))

cat("  Total supermarket exit events:", sum(sm_exits$n_sm_exits), "\n")
cat("  Counties with SM exits:", length(unique(paste(sm_exits$state_fips,
                                                      sm_exits$county_name))), "\n")

# ----------------------------------------------------------
# 3. Create treatment: county had supermarket exit event
# ----------------------------------------------------------
cat("\n=== Creating treatment variables ===\n")

# For each county, identify FIRST major supermarket exit quarter
# (first quarter with ≥1 supermarket exit)
first_exit <- sm_exits[, .(first_exit_time = min((year - 2005) * 4 + quarter)),
                        by = .(state_fips, county_name)]

cat("  Counties with at least one SM exit:", nrow(first_exit), "\n")
cat("  First exit time distribution:\n")
print(summary(first_exit$first_exit_time))

# ----------------------------------------------------------
# 4. Merge QWI with SNAP treatment at county level
# ----------------------------------------------------------
cat("\n=== Merging QWI with SNAP treatment ===\n")

# QWI uses 5-digit FIPS. SNAP has state_fips + county_name.
# We need to match on county FIPS.
# The QWI county_fips is the standard 5-digit FIPS.
# Let's extract state FIPS from county FIPS for the merge.
qwi_clean[, state_fips := substr(county_fips, 1, 2)]

# For SNAP data, we need county FIPS. Since we can't directly
# match county names reliably, let's construct county-level SNAP
# metrics using the geocoded coordinates instead.

# Alternative approach: build SNAP retailer county FIPS panel
# from the geographic coordinates using a FIPS crosswalk.
# Since Latitude/Longitude are in the data, we could geocode.
# But for efficiency, let's use the Zip Code → county FIPS crosswalk.
# Actually, let me try a different approach: count SNAP retailers
# per county FIPS using the county_fips from the SNAP data's
# geographic information.

# Look for county FIPS in the SNAP data
cat("  SNAP data columns:", paste(names(retailers), collapse = ", "), "\n")

# The SNAP data doesn't have county FIPS directly.
# Let me aggregate SNAP retailers by state × county name and
# cross-reference to QWI counties.
# But county names don't always match.

# BEST APPROACH: Use ZIP code to county FIPS crosswalk
# Download HUD ZIP-County crosswalk
zip_county_url <- "https://www.huduser.gov/hudapi/public/usps?type=2&query=All"
# Alternative: use the census.gov Zip-FIPS file

# Actually, let me use a simpler approach:
# Build the county FIPS from the SNAP retailer Latitude/Longitude
# using a simple state_fips + County field matching.

# For the purpose of this V1, let me directly query the SNAP
# retailer data by county and count supermarket exits at the
# state-quarter level, then merge to QWI at state level.
# This is coarser but reliable for a V1.

# Actually, let me try the direct County field match approach.
# QWI has county FIPS. If I can build a county_name → FIPS crosswalk
# from the QWI data (which has county FIPS), I can match.

# Better: download the Census county FIPS file
cat("  Fetching county FIPS crosswalk...\n")
fips_url <- "https://www2.census.gov/geo/docs/reference/codes2020/national_county2020.txt"
resp <- httr::GET(fips_url, httr::timeout(30))

if (httr::status_code(resp) == 200) {
  fips_text <- httr::content(resp, "text", encoding = "UTF-8")
  fips_xwalk <- fread(text = fips_text, sep = "|", header = TRUE)
  cat("  FIPS crosswalk rows:", nrow(fips_xwalk), "\n")
  cat("  Columns:", paste(names(fips_xwalk), collapse = ", "), "\n")

  # Build county FIPS from state FIPS + county FIPS
  fips_xwalk[, county_fips := paste0(
    sprintf("%02d", as.integer(STATEFP)),
    sprintf("%03d", as.integer(COUNTYFP))
  )]
  fips_xwalk[, state_fips := sprintf("%02d", as.integer(STATEFP))]
  fips_xwalk[, county_name_clean := toupper(gsub(" County$| Parish$| Borough$| Census Area$| Municipality$| city$", "",
                                                   COUNTYNAME))]

  # Clean SNAP county names similarly
  retailers[, county_name_clean := toupper(gsub(" County$| Parish$| Borough$", "",
                                                 county_name))]

  # Merge SNAP retailers to county FIPS
  snap_fips <- merge(retailers[, .(Record_ID, state_fips, county_name_clean,
                                    is_supermarket, exited, end_date,
                                    exit_year, exit_quarter)],
                     fips_xwalk[, .(state_fips, county_name_clean, county_fips)],
                     by = c("state_fips", "county_name_clean"),
                     all.x = TRUE, allow.cartesian = TRUE)

  # Check match rate
  match_rate <- mean(!is.na(snap_fips$county_fips))
  cat("  SNAP → FIPS match rate:", round(match_rate * 100, 1), "%\n")

  # Deduplicate (cartesian join may create dupes)
  snap_fips <- unique(snap_fips, by = "Record_ID")
  cat("  After dedup:", format(nrow(snap_fips), big.mark = ","), "rows\n")
} else {
  stop("Failed to download county FIPS crosswalk")
}

# ----------------------------------------------------------
# 5. Build county-quarter supermarket exit treatment
# ----------------------------------------------------------
cat("\n=== Building county-quarter SM exit treatment ===\n")

# Count supermarket exits by county_fips × quarter
sm_exits_fips <- snap_fips[is_supermarket == TRUE & exited == TRUE &
                             exit_year >= 2005 & exit_year <= 2024 &
                             !is.na(county_fips),
                           .(n_sm_exits = .N),
                           by = .(county_fips, exit_year, exit_quarter)]

sm_exits_fips[, time_id := (exit_year - 2005) * 4 + exit_quarter]

# First SM exit per county
first_sm_exit <- sm_exits_fips[, .(first_treat = min(time_id)),
                                by = county_fips]

cat("  Counties with SM exit + FIPS:", nrow(first_sm_exit), "\n")

# ----------------------------------------------------------
# 6. Build analysis panel
# ----------------------------------------------------------
cat("\n=== Building analysis panel ===\n")

# Focus on White and Black for the race DDD
panel <- qwi_clean[race_label %in% c("white", "black")]

# Merge treatment timing
panel <- merge(panel, first_sm_exit, by = "county_fips", all.x = TRUE)

# Counties without SM exit → never treated (first_treat = 0 for CS)
panel[is.na(first_treat), first_treat := 0L]

# Treatment indicator
panel[, treated := as.integer(first_treat > 0 & time_id >= first_treat)]
panel[first_treat == 0, treated := 0L]

# Black indicator
panel[, black := as.integer(race_label == "black")]

# Create numeric county ID
county_map <- data.table(county_fips = sort(unique(panel$county_fips)),
                          county_id = seq_along(sort(unique(panel$county_fips))))
panel <- merge(panel, county_map, by = "county_fips")

# Compute separation rate
panel[, sep_rate := ifelse(Emp > 0 & !is.na(Sep), Sep / Emp, NA_real_)]
# Employment (log)
panel[, ln_emp := ifelse(Emp > 0 & !is.na(Emp), log(Emp), NA_real_)]
# Earnings
panel[, ln_earn := ifelse(EarnS > 0 & !is.na(EarnS), log(EarnS), NA_real_)]

# Filter to analysis window: 2010-2024 (avoid early QWI sparseness)
panel <- panel[year >= 2010 & year <= 2024]

cat("  Panel dimensions:", format(nrow(panel), big.mark = ","), "\n")
cat("  Counties:", length(unique(panel$county_fips)), "\n")
cat("  Treated counties:", sum(panel$first_treat > 0 & !duplicated(panel$county_fips)), "\n")
cat("  Never-treated:", sum(panel$first_treat == 0 & !duplicated(panel$county_fips)), "\n")
cat("  Black observations:", sum(panel$black == 1), "\n")
cat("  White observations:", sum(panel$black == 0), "\n")

# Summary stats
cat("\n=== Pre-treatment Summary Statistics ===\n")
pre <- panel[treated == 0]
cat("  White employment (mean):", round(mean(pre[black == 0]$Emp, na.rm = TRUE), 1), "\n")
cat("  Black employment (mean):", round(mean(pre[black == 1]$Emp, na.rm = TRUE), 1), "\n")
cat("  White sep rate (mean):", round(mean(pre[black == 0]$sep_rate, na.rm = TRUE), 4), "\n")
cat("  Black sep rate (mean):", round(mean(pre[black == 1]$sep_rate, na.rm = TRUE), 4), "\n")

# Save
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(county_map, file.path(data_dir, "county_map.rds"))

cat("\n=== Data cleaning complete ===\n")
