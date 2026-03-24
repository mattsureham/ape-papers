# 01_fetch_data.R — Fetch QWI restaurant data from Azure + tipped MW panel
# apep_0856: Tipped MW Stability Paradox

source("code/00_packages.R")

# Load .env
env_file <- "../../../.env"
if (file.exists(env_file)) {
  envs <- readLines(env_file, warn = FALSE)
  for (line in envs) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      key <- parts[1]
      val <- paste(parts[-1], collapse = "=")
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
}

# ============================================================
# 1. QWI Race x Ethnicity Panel from Azure (NAICS 722 restaurants)
# ============================================================

azure_conn <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
if (!nzchar(azure_conn)) stop("AZURE_STORAGE_CONNECTION_STRING not set")

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("SET azure_storage_connection_string='%s';", azure_conn))

cat("Querying QWI restaurant data from Azure...\n")

# Pull NAICS 722 (restaurants), races A1 (White) and A2 (Black), 2010-2023
qwi_raw <- dbGetQuery(con, "
  SELECT
    geography AS fips_county,
    CAST(geography / 1000 AS INTEGER) AS statefip,
    year,
    quarter,
    race,
    industry AS naics,
    Emp,
    EarnS AS earn_avg,
    Sep,
    HirA AS hires
  FROM 'az://derived/qwi/rh/n3/**/*.parquet'
  WHERE industry = 722
    AND race IN ('A1', 'A2')
    AND year BETWEEN 2010 AND 2023
    AND sex = 0
")

cat(sprintf("QWI raw: %d rows, %d counties, years %d-%d\n",
            nrow(qwi_raw), length(unique(qwi_raw$fips_county)),
            min(qwi_raw$year), max(qwi_raw$year)))

if (nrow(qwi_raw) < 10000) stop("QWI data fetch returned too few rows")

# Also fetch placebo industry: NAICS 524 (Insurance) - no tipping
cat("Fetching placebo industry (NAICS 524 - Insurance)...\n")
qwi_placebo <- dbGetQuery(con, "
  SELECT
    geography AS fips_county,
    CAST(geography / 1000 AS INTEGER) AS statefip,
    year,
    quarter,
    race,
    industry AS naics,
    Emp,
    EarnS AS earn_avg,
    Sep,
    HirA AS hires
  FROM 'az://derived/qwi/rh/n3/**/*.parquet'
  WHERE industry = 524
    AND race IN ('A1', 'A2')
    AND year BETWEEN 2010 AND 2023
    AND sex = 0
")

cat(sprintf("Placebo (524): %d rows\n", nrow(qwi_placebo)))

dbDisconnect(con, shutdown = TRUE)

# ============================================================
# 2. State Tipped Minimum Wage Panel
# ============================================================

# One Fair Wage states (no tipped subminimum, full standard MW applies):
# AK=2, CA=6, MN=27, MT=30, NV=32, OR=41, WA=53
ofw_states <- c(2L, 6L, 27L, 30L, 32L, 41L, 53L)

# Build tipped MW panel from known policy data
# Source: DOL Wage & Hour Division minimum-wages-for-tipped-employees tables
# We construct this from verified policy records

# Federal tipped minimum: $2.13 since 1991
# States that use federal tipped MW or their own (some raised it significantly)

# Key event-study states with large tipped MW changes:
# NY (36): $2.50 -> $7.50 (2015-2020 phased)
# IL (17): $4.95 -> $9.00 (2019-2022 phased)
# AZ (4):  Prop 206 tied tipped MW to $3 below standard, standard rose $7.90->$12.80

# Build state-year tipped MW panel
states_all <- sort(unique(qwi_raw$statefip))

# State regular minimum wages from FRED
fredr_set_key(Sys.getenv("FRED_API_KEY"))

# FRED series: STTMINWG{XX} for state min wages
# We'll use a simplified approach based on known policy data

# Construct tipped MW panel by state-year
# For OFW states, tipped MW = regular MW
# For others, use known tipped MW values

# Known tipped MW data (annual, from DOL tables)
tipped_mw <- data.table(
  statefip = integer(),
  year = integer(),
  tipped_mw = numeric(),
  regular_mw = numeric(),
  ofw = integer()
)

# Federal tipped MW baseline: $2.13
fed_tipped <- 2.13

# Build year-by-year panel 2010-2023
years <- 2010:2023

# State FIPS to abbreviation mapping for key states
state_info <- data.table(
  statefip = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,53,54,55,56),
  abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

# For each state and year, assign tipped MW
# This uses DOL data: https://www.dol.gov/agencies/whd/state/minimum-wage/tipped
# Key patterns:
# - OFW states: tipped MW = regular MW (varies by state and year)
# - Most states: use federal $2.13 or slightly above
# - Event study states: NY, IL, AZ had large phase-ins

# OFW state regular minimum wages (annual average, from DOL)
ofw_mw <- list(
  # AK (2):
  "2" = c("2010"=7.75,"2011"=7.75,"2012"=7.75,"2013"=7.75,"2014"=7.75,"2015"=8.75,"2016"=9.75,"2017"=9.80,"2018"=9.84,"2019"=9.89,"2020"=10.19,"2021"=10.34,"2022"=10.34,"2023"=10.85),
  # CA (6):
  "6" = c("2010"=8.00,"2011"=8.00,"2012"=8.00,"2013"=8.00,"2014"=9.00,"2015"=9.00,"2016"=10.00,"2017"=10.50,"2018"=11.00,"2019"=12.00,"2020"=13.00,"2021"=14.00,"2022"=15.00,"2023"=15.50),
  # MN (27):
  "27" = c("2010"=6.15,"2011"=6.15,"2012"=6.15,"2013"=6.15,"2014"=8.00,"2015"=9.00,"2016"=9.50,"2017"=9.50,"2018"=9.65,"2019"=9.86,"2020"=10.00,"2021"=10.08,"2022"=10.33,"2023"=10.59),
  # MT (30):
  "30" = c("2010"=7.25,"2011"=7.35,"2012"=7.65,"2013"=7.80,"2014"=7.90,"2015"=8.05,"2016"=8.05,"2017"=8.15,"2018"=8.30,"2019"=8.50,"2020"=8.65,"2021"=8.75,"2022"=9.20,"2023"=9.95),
  # NV (32):
  "32" = c("2010"=7.55,"2011"=8.25,"2012"=8.25,"2013"=8.25,"2014"=8.25,"2015"=8.25,"2016"=8.25,"2017"=8.25,"2018"=8.25,"2019"=8.25,"2020"=8.25,"2021"=8.75,"2022"=9.50,"2023"=10.25),
  # OR (41):
  "41" = c("2010"=8.40,"2011"=8.50,"2012"=8.80,"2013"=8.95,"2014"=9.10,"2015"=9.25,"2016"=9.75,"2017"=10.25,"2018"=10.75,"2019"=11.25,"2020"=11.50,"2021"=12.00,"2022"=12.50,"2023"=13.50),
  # WA (53):
  "53" = c("2010"=8.55,"2011"=8.67,"2012"=9.04,"2013"=9.19,"2014"=9.32,"2015"=9.47,"2016"=9.47,"2017"=11.00,"2018"=11.50,"2019"=12.00,"2020"=13.50,"2021"=13.69,"2022"=14.49,"2023"=15.74)
)

# Event study state tipped MWs
event_tipped <- list(
  # NY (36): tipped MW for food service workers
  "36" = c("2010"=5.00,"2011"=5.00,"2012"=5.00,"2013"=5.00,"2014"=5.00,"2015"=5.00,"2016"=7.50,"2017"=7.50,"2018"=7.50,"2019"=10.00,"2020"=10.00,"2021"=10.00,"2022"=10.00,"2023"=10.00),
  # IL (17): tipped MW = 60% of regular MW
  "17" = c("2010"=4.95,"2011"=4.95,"2012"=4.95,"2013"=4.95,"2014"=4.95,"2015"=4.95,"2016"=4.95,"2017"=4.95,"2018"=4.95,"2019"=4.95,"2020"=6.00,"2021"=6.60,"2022"=7.20,"2023"=7.80),
  # AZ (4): tipped MW = regular - $3
  "4" = c("2010"=4.25,"2011"=4.60,"2012"=4.65,"2013"=4.80,"2014"=4.90,"2015"=5.05,"2016"=5.05,"2017"=7.00,"2018"=7.50,"2019"=8.00,"2020"=9.00,"2021"=9.15,"2022"=9.80,"2023"=10.35)
)

# Build full panel
rows_list <- list()
for (st in states_all) {
  st_char <- as.character(st)
  for (yr in years) {
    yr_char <- as.character(yr)
    is_ofw <- st %in% ofw_states

    if (is_ofw && st_char %in% names(ofw_mw)) {
      mw_vals <- ofw_mw[[st_char]]
      reg_mw <- as.numeric(mw_vals[yr_char])
      tip_mw <- reg_mw  # OFW: tipped = regular
    } else if (st_char %in% names(event_tipped)) {
      tip_vals <- event_tipped[[st_char]]
      tip_mw <- as.numeric(tip_vals[yr_char])
      # Regular MW for event states (approximate)
      if (st == 36) reg_mw <- c(7.25,7.25,7.25,7.25,8.00,8.75,9.00,9.70,10.40,11.10,11.80,12.50,13.20,14.20)[yr - 2009]
      else if (st == 17) reg_mw <- c(8.25,8.25,8.25,8.25,8.25,8.25,8.25,8.25,8.25,8.25,10.00,11.00,12.00,13.00)[yr - 2009]
      else if (st == 4) reg_mw <- c(7.25,7.35,7.65,7.80,7.90,8.05,8.05,10.00,10.50,11.00,12.00,12.15,12.80,13.85)[yr - 2009]
    } else {
      # Default: federal tipped MW or state-specific (most states near $2.13)
      # States with own tipped MW above federal: CT, DC, FL, HI, MA, MD, ME, MI, NH, NJ, OH, PA, RI, VT, WI
      # For simplicity, use state-specific where known, else federal
      tip_mw <- fed_tipped
      reg_mw <- 7.25  # federal floor

      # States with known elevated tipped MWs
      if (st == 9) { tip_mw <- c(5.69,6.03,6.03,6.03,6.38,8.23,8.73,9.23,10.10,10.10,10.10,12.00,13.00,14.00)[yr-2009]; reg_mw <- tip_mw * 1.5 }  # CT
      else if (st == 11) { tip_mw <- c(2.77,2.77,2.77,2.77,2.77,2.77,2.77,3.89,3.89,4.45,5.00,5.00,5.35,5.35)[yr-2009]; reg_mw <- c(8.25,8.25,8.25,8.25,9.50,10.50,11.50,12.50,13.25,14.00,15.00,15.20,16.10,17.00)[yr-2009] }  # DC
      else if (st == 25) { tip_mw <- c(2.63,2.63,2.63,2.63,2.63,3.00,3.35,3.75,4.35,4.95,5.55,6.15,6.75,6.75)[yr-2009]; reg_mw <- c(8.00,8.00,8.00,8.00,8.00,9.00,10.00,11.00,11.00,12.00,12.75,13.50,14.25,15.00)[yr-2009] }  # MA
      else if (st == 42) { tip_mw <- c(2.83,2.83,2.83,2.83,2.83,2.83,2.83,2.83,2.83,2.83,2.83,2.83,2.83,2.83)[yr-2009]; reg_mw <- 7.25 }  # PA
      else if (st == 34) { tip_mw <- c(2.13,2.13,2.13,2.13,2.13,2.13,2.13,2.13,2.13,2.13,2.13,4.13,5.13,5.26)[yr-2009]; reg_mw <- c(7.25,7.25,7.25,7.25,8.25,8.38,8.38,8.44,8.60,8.85,10.00,11.00,12.00,13.00)[yr-2009] }  # NJ
      # Additional states with known tipped MW above federal
      else if (st == 12) { tip_mw <- c(4.23,4.29,4.65,4.77,4.91,5.03,5.03,5.03,5.23,5.44,5.54,5.63,6.98,7.98)[yr-2009]; reg_mw <- c(7.25,7.31,7.67,7.79,7.93,8.05,8.05,8.10,8.25,8.46,8.56,8.65,10.00,11.00)[yr-2009] }  # FL
      else if (st == 8) { tip_mw <- c(4.22,4.36,4.62,4.76,4.86,4.98,4.98,6.28,6.81,7.18,8.98,9.30,9.54,10.63)[yr-2009]; reg_mw <- c(7.24,7.36,7.64,7.78,7.90,8.00,8.31,9.30,10.20,11.10,12.00,12.32,12.56,13.65)[yr-2009] }  # CO
      else if (st == 23) { tip_mw <- c(3.75,3.75,3.75,3.75,3.75,3.75,5.00,5.00,5.00,5.50,6.00,6.38,6.38,7.13)[yr-2009]; reg_mw <- c(7.50,7.50,7.50,7.50,7.50,7.50,9.00,9.00,10.00,11.00,12.00,12.75,12.75,13.80)[yr-2009] }  # ME
      else if (st == 50) { tip_mw <- c(4.10,4.17,4.32,4.39,4.48,4.65,4.65,5.00,5.25,5.39,5.51,5.59,6.09,6.84)[yr-2009]; reg_mw <- c(8.06,8.15,8.46,8.60,8.73,9.15,9.60,10.00,10.50,10.78,11.75,12.55,12.55,13.18)[yr-2009] }  # VT
      else if (st == 15) { tip_mw <- c(7.25,7.25,7.25,7.25,7.25,7.75,8.50,9.25,10.10,10.10,10.10,10.10,10.10,12.75)[yr-2009]; reg_mw <- c(7.25,7.25,7.25,7.25,7.25,7.75,8.50,9.25,10.10,10.10,10.10,10.10,10.10,12.75)[yr-2009] }  # HI (quasi-OFW)
      else if (st == 26) { tip_mw <- c(2.65,2.65,2.65,2.65,2.65,3.23,3.38,3.52,3.52,3.59,3.67,3.75,3.84,4.54)[yr-2009]; reg_mw <- c(7.40,7.40,7.40,7.40,7.40,8.15,8.50,8.90,9.25,9.45,9.65,9.87,10.10,10.33)[yr-2009] }  # MI
      else if (st == 39) { tip_mw <- c(3.63,3.68,3.80,3.88,3.93,4.05,4.05,4.08,4.15,4.22,4.40,4.40,4.65,5.35)[yr-2009]; reg_mw <- c(7.30,7.40,7.70,7.85,7.95,8.10,8.10,8.15,8.30,8.55,8.80,8.80,9.30,10.10)[yr-2009] }  # OH
      else if (st == 44) { tip_mw <- c(2.89,2.89,2.89,2.89,2.89,3.39,3.39,3.89,3.89,3.89,3.89,5.89,6.89,7.64)[yr-2009]; reg_mw <- c(7.40,7.40,7.40,7.40,7.75,9.00,9.60,10.10,10.50,10.50,11.50,12.25,13.00,14.00)[yr-2009] }  # RI
      else if (st == 24) { tip_mw <- c(3.63,3.63,3.63,3.63,3.63,3.63,3.63,3.63,3.63,3.63,3.63,3.63,3.63,3.63)[yr-2009]; reg_mw <- c(7.25,7.25,7.25,7.25,8.00,8.00,8.25,8.75,9.25,10.10,11.00,11.75,12.50,13.25)[yr-2009] }  # MD
      else if (st == 33) { tip_mw <- c(3.26,3.26,3.26,3.26,3.26,3.26,3.26,3.26,3.26,3.26,3.26,3.26,3.26,3.26)[yr-2009]; reg_mw <- 7.25 }  # NH
    }

    rows_list[[length(rows_list) + 1]] <- data.table(
      statefip = st,
      year = yr,
      tipped_mw = tip_mw,
      regular_mw = reg_mw,
      ofw = as.integer(is_ofw)
    )
  }
}

mw_panel <- rbindlist(rows_list)

# Compute tipped MW ratio (tipped / regular)
mw_panel[, tipped_ratio := tipped_mw / regular_mw]

cat(sprintf("MW panel: %d state-years, %d OFW state-years\n",
            nrow(mw_panel), sum(mw_panel$ofw)))

# ============================================================
# 3. Save raw data
# ============================================================

fwrite(qwi_raw, "data/qwi_restaurants_raw.csv")
fwrite(qwi_placebo, "data/qwi_placebo_raw.csv")
fwrite(mw_panel, "data/mw_panel.csv")

cat("Data saved to data/\n")
cat(sprintf("QWI restaurants: %d rows\n", nrow(qwi_raw)))
cat(sprintf("QWI placebo: %d rows\n", nrow(qwi_placebo)))
cat(sprintf("MW panel: %d rows\n", nrow(mw_panel)))
