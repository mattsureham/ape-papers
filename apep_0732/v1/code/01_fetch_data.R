## 01_fetch_data.R — Fetch all data for apep_0732
## Sources: Census TIGER (county shapefiles), NOAA nClimDiv (temperature),
##          County Health Rankings (mortality), ACS (demographics)

source("00_packages.R")
options(tigris_use_cache = TRUE)

## ============================================================
## Step 1: County shapefiles and TZ boundary classification
## ============================================================

cat("=== Step 1: County shapefiles and time zone boundaries ===\n")

counties_sf <- tigris::counties(cb = TRUE, year = 2020, resolution = "20m") |>
  filter(!STATEFP %in% c("02", "15", "60", "66", "69", "72", "78")) |>
  st_transform(4326)

stopifnot("counties_sf is empty" = nrow(counties_sf) > 0)
cat("Counties loaded:", nrow(counties_sf), "\n")

## Get county centroids
centroids <- counties_sf |>
  st_centroid() |>
  mutate(
    lon = st_coordinates(geometry)[, 1],
    lat = st_coordinates(geometry)[, 2],
    fips = paste0(STATEFP, COUNTYFP)
  ) |>
  st_drop_geometry() |>
  select(fips, STATEFP, COUNTYFP, NAME, lon, lat)

## Assign time zones based on state + longitude for split states
tz_assign <- centroids |>
  mutate(
    timezone = case_when(
      ## Pacific
      STATEFP %in% c("06", "41", "53") ~ "Pacific",
      ## Mountain
      STATEFP %in% c("04", "08", "16", "30", "35", "49", "56") ~ "Mountain",
      STATEFP == "32" ~ "Pacific",   # Nevada = Pacific
      ## Central
      STATEFP %in% c("01", "05", "19", "20", "22", "27", "28", "29",
                      "31", "38", "40", "46", "48", "55") ~ "Central",
      ## Eastern
      STATEFP %in% c("09", "10", "11", "23", "24", "25", "33", "34",
                      "36", "37", "39", "42", "44", "45", "50", "51", "54") ~ "Eastern",
      STATEFP == "13" ~ "Eastern",   # Georgia
      ## Split states
      STATEFP == "12" ~ if_else(lon < -85.5, "Central", "Eastern"),     # Florida
      STATEFP == "18" ~ if_else(lon < -86.3, "Central", "Eastern"),     # Indiana
      STATEFP == "21" ~ if_else(lon < -85.7, "Central", "Eastern"),     # Kentucky
      STATEFP == "26" ~ if_else(lat > 45.5 & lon < -88.0, "Central", "Eastern"),  # Michigan UP
      STATEFP == "47" ~ if_else(lon < -85.3, "Central", "Eastern"),     # Tennessee
      TRUE ~ NA_character_
    )
  )

## Assign remaining by longitude
n_na <- sum(is.na(tz_assign$timezone))
if (n_na > 0) {
  cat("Assigning", n_na, "remaining counties by longitude.\n")
  tz_assign <- tz_assign |>
    mutate(timezone = case_when(
      !is.na(timezone) ~ timezone,
      lon > -82 ~ "Eastern",
      lon > -98 ~ "Central",
      lon > -110 ~ "Mountain",
      TRUE ~ "Pacific"
    ))
}

## Identify border counties for each TZ boundary
boundaries <- list(
  ET_CT = list(east_tz = "Eastern",  west_tz = "Central",  ref_lon = -86),
  CT_MT = list(east_tz = "Central",  west_tz = "Mountain", ref_lon = -102),
  MT_PT = list(east_tz = "Mountain", west_tz = "Pacific",  ref_lon = -115)
)

border_data <- list()
for (bname in names(boundaries)) {
  b <- boundaries[[bname]]
  east_counties <- tz_assign |> filter(timezone == b$east_tz, abs(lon - b$ref_lon) < 3)
  west_counties <- tz_assign |> filter(timezone == b$west_tz, abs(lon - b$ref_lon) < 3)
  combined <- bind_rows(
    east_counties |> mutate(boundary = bname, late_sunset = 0L,
                            dist_to_boundary = lon - b$ref_lon),
    west_counties |> mutate(boundary = bname, late_sunset = 1L,
                            dist_to_boundary = lon - b$ref_lon)
  )
  border_data[[bname]] <- combined
}

border_counties <- bind_rows(border_data)
cat("Border counties:", nrow(border_counties), "\n")
cat("  ET/CT:", sum(border_counties$boundary == "ET_CT"), "\n")
cat("  CT/MT:", sum(border_counties$boundary == "CT_MT"), "\n")
cat("  MT/PT:", sum(border_counties$boundary == "MT_PT"), "\n")
stopifnot("Too few border counties" = nrow(border_counties) >= 100)

saveRDS(border_counties, "../data/border_counties.rds")
saveRDS(tz_assign, "../data/all_counties_tz.rds")


## ============================================================
## Step 2: NOAA nClimDiv temperature data
## ============================================================

cat("\n=== Step 2: Fetch NOAA temperature data ===\n")

nclim_url <- "https://www.ncei.noaa.gov/pub/data/cirs/climdiv/"

## nClimDiv county temperature file
temp_resp <- NULL
for (suffix in c("20260305", "20260301", "20260201")) {
  cat("  Trying suffix:", suffix, "\n")
  temp_resp <- request(nclim_url) |>
    req_url_path_append(paste0("climdiv-tmpccy-v1.0.0-", suffix)) |>
    req_timeout(180) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()
  if (resp_status(temp_resp) == 200) {
    cat("  Found:", suffix, "\n")
    break
  }
}

stopifnot("Failed to fetch nClimDiv temperature data" = !is.null(temp_resp) && resp_status(temp_resp) == 200)

temp_raw <- resp_body_string(temp_resp)
temp_lines <- strsplit(temp_raw, "\n")[[1]]
temp_lines <- temp_lines[nchar(trimws(temp_lines)) > 10]
cat("Temperature records:", length(temp_lines), "\n")

## Parse nClimDiv fixed-width format
## Check actual field widths by examining first line
cat("Sample line:", substr(temp_lines[1], 1, 120), "\n")

## nClimDiv county format: SS CCC EE YYYY followed by 12 monthly values
## SS = NOAA state code (2 digits, positions 1-2)
## CCC = county FIPS code (3 digits, positions 3-5)
## EE = element code (2 digits, positions 6-7)
## YYYY = year (4 digits, positions 8-11)
## Then 12 monthly values, each 9 characters wide

parse_nclim <- function(lines) {
  dt <- data.table(raw = lines)
  dt[, `:=`(
    state_code  = substr(raw, 1, 2),
    county_code = substr(raw, 3, 5),
    element     = substr(raw, 6, 7),
    year        = as.integer(substr(raw, 8, 11))
  )]

  for (m in 1:12) {
    start_pos <- 12 + (m - 1) * 9
    end_pos <- start_pos + 8
    col_name <- sprintf("m%02d", m)
    dt[, (col_name) := as.numeric(trimws(substr(raw, start_pos, end_pos)))]
  }
  dt[, raw := NULL]
  return(dt)
}

temp_dt <- parse_nclim(temp_lines)

## NOAA state number → FIPS state code mapping
noaa_to_fips <- c(
  "01"="01", "02"="04", "03"="05", "04"="06", "05"="08",
  "06"="09", "07"="10", "08"="11", "09"="12", "10"="13",
  "11"="16", "12"="17", "13"="18", "14"="19", "15"="20",
  "16"="21", "17"="22", "18"="23", "19"="24", "20"="25",
  "21"="26", "22"="27", "23"="28", "24"="29", "25"="30",
  "26"="31", "27"="32", "28"="33", "29"="34", "30"="35",
  "31"="36", "32"="37", "33"="38", "34"="39", "35"="40",
  "36"="41", "37"="42", "38"="44", "39"="45", "40"="46",
  "41"="47", "42"="48", "43"="49", "44"="50", "45"="51",
  "46"="53", "47"="54", "48"="55", "49"="56"
)

temp_dt[, state_fips := noaa_to_fips[state_code]]
temp_dt[, fips := paste0(state_fips, county_code)]

## Pivot to long
temp_long <- melt(
  temp_dt,
  id.vars = c("fips", "state_fips", "county_code", "year"),
  measure.vars = paste0("m", sprintf("%02d", 1:12)),
  variable.name = "month_var",
  value.name = "avg_temp_f"
)
temp_long[, month := as.integer(gsub("m", "", month_var))]
temp_long[, month_var := NULL]
temp_long <- temp_long[avg_temp_f > -90 & year >= 1999 & year <= 2023]

cat("Temperature panel:", nrow(temp_long), "county-year-months\n")
cat("Unique FIPS in temp:", length(unique(temp_long$fips)), "\n")

## Compute annual heat measures
temp_annual <- temp_long[, .(
  avg_temp_annual    = mean(avg_temp_f, na.rm = TRUE),
  summer_avg_temp    = mean(avg_temp_f[month %in% 6:8], na.rm = TRUE),
  winter_avg_temp    = mean(avg_temp_f[month %in% c(12, 1, 2)], na.rm = TRUE),
  summer_heat_dd65   = sum(pmax(avg_temp_f[month %in% 6:8] - 65, 0), na.rm = TRUE),
  n_hot_months       = sum(avg_temp_f > 75, na.rm = TRUE)
), by = .(fips, year)]

## Also compute long-run averages for cross-section
temp_crosssec <- temp_long[year >= 1999 & year <= 2020, .(
  mean_summer_temp     = mean(avg_temp_f[month %in% 6:8], na.rm = TRUE),
  mean_winter_temp     = mean(avg_temp_f[month %in% c(12, 1, 2)], na.rm = TRUE),
  mean_summer_heat_dd  = sum(pmax(avg_temp_f[month %in% 6:8] - 65, 0), na.rm = TRUE) /
                          length(unique(year)),
  sd_summer_temp       = sd(avg_temp_f[month %in% 6:8], na.rm = TRUE)
), by = fips]

saveRDS(temp_long, "../data/temp_monthly.rds")
saveRDS(temp_annual, "../data/temp_annual.rds")
saveRDS(temp_crosssec, "../data/temp_crosssec.rds")


## ============================================================
## Step 3: County Health Rankings — county-level mortality
## ============================================================

cat("\n=== Step 3: Fetch County Health Rankings mortality data ===\n")

## CHR provides county-level premature death rates (YPLL per 100,000)
## Available releases: 2019-2024

chr_years <- 2019:2024
chr_data_list <- list()

for (yr in chr_years) {
  url <- sprintf(
    "https://www.countyhealthrankings.org/sites/default/files/media/document/analytic_data%d.csv",
    yr
  )
  cat("  Fetching CHR", yr, "...\n")

  resp <- request(url) |>
    req_timeout(120) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()

  if (resp_status(resp) != 200) {
    cat("    FAILED (HTTP", resp_status(resp), ")\n")
    next
  }

  ## Read CSV - skip first row (header descriptions), use second row as names
  tmp_file <- tempfile(fileext = ".csv")
  writeBin(resp_body_raw(resp), tmp_file)

  ## CHR files have two header rows: labels and variable names
  dt <- tryCatch({
    ## Read with two header rows
    raw <- fread(tmp_file, header = FALSE, skip = 2, fill = TRUE)
    headers <- fread(tmp_file, header = FALSE, nrows = 1, skip = 1)
    if (ncol(raw) >= ncol(headers)) {
      setnames(raw, seq_len(ncol(headers)), as.character(headers[1, ]))
    }
    raw
  }, error = function(e) {
    cat("    Parse error:", conditionMessage(e), "\n")
    NULL
  })

  if (is.null(dt) || nrow(dt) == 0) {
    cat("    No data parsed\n")
    next
  }

  ## Extract key columns: FIPS, premature death rate, and related
  ## Column names vary by year, so search for them
  fips_col <- intersect(names(dt), c("fipscode", "FIPS", "5-digit FIPS Code"))
  ypll_col <- intersect(names(dt), c("v001_rawvalue", "YPLL Rate"))

  if (length(fips_col) == 0 || length(ypll_col) == 0) {
    cat("    Columns not found. Available:", paste(head(names(dt), 20), collapse=", "), "\n")
    next
  }

  chr_sub <- dt[, c(fips_col[1], ypll_col[1]), with = FALSE]
  setnames(chr_sub, c("fips", "ypll_rate"))
  chr_sub[, `:=`(
    chr_year = yr,
    fips = sprintf("%05s", fips),
    ypll_rate = as.numeric(ypll_rate)
  )]
  chr_sub <- chr_sub[!is.na(ypll_rate) & nchar(fips) == 5 & fips != "00000"]

  chr_data_list[[as.character(yr)]] <- chr_sub
  cat("    Counties:", nrow(chr_sub), "\n")
  unlink(tmp_file)
}

if (length(chr_data_list) == 0) {
  stop("FATAL: Could not fetch any County Health Rankings data.")
}

chr_panel <- rbindlist(chr_data_list, fill = TRUE)
cat("CHR panel:", nrow(chr_panel), "county-year observations\n")
cat("CHR years:", paste(sort(unique(chr_panel$chr_year)), collapse = ", "), "\n")
cat("Unique counties:", length(unique(chr_panel$fips)), "\n")

## Also compute cross-sectional average
chr_crosssec <- chr_panel[, .(
  mean_ypll = mean(ypll_rate, na.rm = TRUE),
  sd_ypll = sd(ypll_rate, na.rm = TRUE),
  n_years = .N
), by = fips]

saveRDS(chr_panel, "../data/chr_panel.rds")
saveRDS(chr_crosssec, "../data/chr_crosssec.rds")


## ============================================================
## Step 4: ACS county demographics
## ============================================================

cat("\n=== Step 4: Fetch ACS demographics ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) > 0) {
  census_api_key(census_key, install = FALSE)
}

acs_vars <- c(
  total_pop      = "B01003_001",
  median_income  = "B19013_001",
  pct_black      = "B02001_003",
  pct_hispanic   = "B03003_003",
  median_age     = "B01002_001",
  pct_65plus_m   = "B01001_020",  # Males 65-66
  total_housing  = "B25001_001"
)

acs_data <- get_acs(
  geography = "county",
  variables = acs_vars,
  year = 2020,
  survey = "acs5",
  output = "wide"
)

acs_clean <- acs_data |>
  transmute(
    fips = GEOID,
    total_pop = total_popE,
    median_income = median_incomeE,
    pct_black = pct_blackE / total_popE * 100,
    pct_hispanic = pct_hispanicE / total_popE * 100,
    median_age = median_ageE,
    total_housing = total_housingE
  )

cat("ACS demographics:", nrow(acs_clean), "counties\n")
saveRDS(acs_clean, "../data/acs_demographics.rds")


## ============================================================
## Step 5: CDC state-weekly mortality (for panel analysis)
## ============================================================

cat("\n=== Step 5: Fetch CDC state-week mortality ===\n")

## Fetch state-level weekly all-cause mortality from CDC Excess Deaths dataset
## This enables state-level panel analysis for state pairs straddling TZ boundaries

all_state_mort <- list()
offset <- 0
chunk <- 50000

repeat {
  mort_resp <- request("https://data.cdc.gov/resource/xkkf-xrst.json") |>
    req_url_query(
      `$limit` = chunk,
      `$offset` = offset,
      outcome = "All causes",
      type = "Predicted (weighted)"
    ) |>
    req_timeout(120) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()

  if (resp_status(mort_resp) != 200) break

  batch <- resp_body_json(mort_resp, simplifyVector = TRUE)
  if (length(batch) == 0 || nrow(batch) == 0) break

  all_state_mort[[length(all_state_mort) + 1]] <- as.data.table(batch)
  cat("  Fetched", nrow(batch), "records (offset:", offset, ")\n")
  offset <- offset + chunk
  if (nrow(batch) < chunk) break
}

if (length(all_state_mort) > 0) {
  state_mort <- rbindlist(all_state_mort, fill = TRUE)
  state_mort[, `:=`(
    week_date = as.Date(substr(week_ending_date, 1, 10)),
    observed = as.numeric(observed_number),
    expected = as.numeric(average_expected_count),
    year = as.integer(year)
  )]
  cat("State-week mortality:", nrow(state_mort), "rows\n")
  cat("States:", length(unique(state_mort$state)), "\n")
  cat("Years:", paste(range(state_mort$year, na.rm = TRUE), collapse = "-"), "\n")
  saveRDS(state_mort, "../data/state_weekly_mortality.rds")
} else {
  cat("WARNING: Could not fetch state weekly mortality.\n")
}

cat("\n=== All data fetched successfully ===\n")
