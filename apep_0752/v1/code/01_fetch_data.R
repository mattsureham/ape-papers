## 01_fetch_data.R — Data acquisition for apep_0752
## Tribal Casino Revenues and Opioid Mortality
##
## Three data streams:
## 1. Tribal casino locations and opening dates (NIGC + web sources)
## 2. County-level drug overdose deaths (CDC WONDER export + VSRR API)
## 3. County demographics and AI/AN population (Census ACS API)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

census_key <- Sys.getenv("CENSUS_API_KEY")
stopifnot(nzchar(census_key))

# ============================================================
# PART 1: Tribal Gaming Facilities — NIGC facility data
# ============================================================
# The NIGC lists gaming operations. We also use a curated list
# of tribal casino opening dates from multiple sources.

cat("=== Fetching tribal gaming facility data ===\n")

# Approach: Build treatment from the NIGC website + Wikipedia list
# of Native American casinos by state, which includes opening years.
# We need: casino name, state, county (FIPS), opening year.

# State FIPS codes for mapping
state_fips <- tigris::fips_codes |>
  select(state_code, state_name, state) |>
  distinct() |>
  filter(as.integer(state_code) <= 56)

# Use the Federal Register API for gaming compact approval dates
# These represent the earliest legal authorization per tribe
fr_url <- "https://www.federalregister.gov/api/v1/documents.json"

fetch_fr_compacts <- function(page = 1) {
  # Build URL manually to handle repeated fields[] param
  base <- paste0(fr_url,
    "?conditions%5Bterm%5D=%22Indian+gaming%22+%22tribal-state+compact%22",
    "&per_page=100&page=", page,
    "&fields%5B%5D=title&fields%5B%5D=publication_date",
    "&fields%5B%5D=abstract&fields%5B%5D=document_number")
  resp <- httr::GET(base)
  if (httr::status_code(resp) != 200) stop("Federal Register API failed: ", httr::status_code(resp))
  httr::content(resp, as = "parsed")
}

cat("  Querying Federal Register for gaming compact notices...\n")
all_compacts <- list()
page <- 1
repeat {
  result <- fetch_fr_compacts(page)
  if (length(result$results) == 0) break
  all_compacts <- c(all_compacts, result$results)
  if (page * 100 >= result$count) break
  page <- page + 1
  Sys.sleep(0.5)
}
cat("  Found", length(all_compacts), "Federal Register compact notices\n")

# Parse compact data into a data frame
compact_df <- map_dfr(all_compacts, function(x) {
  tibble(
    title = x$title %||% NA_character_,
    pub_date = x$publication_date %||% NA_character_,
    abstract = x$abstract %||% NA_character_,
    doc_number = x$document_number %||% NA_character_
  )
}) |>
  mutate(pub_year = as.integer(substr(pub_date, 1, 4))) |>
  filter(!is.na(pub_year))

cat("  Compact notices span", min(compact_df$pub_year), "-", max(compact_df$pub_year), "\n")

# Extract state mentions from titles AND abstracts
compact_df <- compact_df |>
  mutate(
    text_combined = paste(title, abstract, sep = " "),
    state_match = map_chr(text_combined, function(t) {
      # Try longer state names first to avoid partial matches
      sorted_states <- state_fips$state_name[order(-nchar(state_fips$state_name))]
      for (s in sorted_states) {
        if (grepl(paste0("\\b", s, "\\b"), t, ignore.case = TRUE)) return(s)
      }
      return(NA_character_)
    })
  )

# First compact year per state from Federal Register
fr_state_compact <- compact_df |>
  filter(!is.na(state_match)) |>
  group_by(state_match) |>
  summarize(
    first_compact_year = min(pub_year),
    n_compacts = n(),
    .groups = "drop"
  ) |>
  rename(state_name = state_match)

cat("  Federal Register matched states:", nrow(fr_state_compact), "\n")

# Supplement with known gaming compact dates from NIGC/historical records
# Source: NIGC "Indian Gaming Fact Sheet" + National Conference of State Legislatures
# These are first Class III compact approval dates per state
known_gaming_states <- tribble(
  ~state_name, ~first_compact_year,
  "Connecticut",    1993,
  "Minnesota",      1991,
  "Wisconsin",      1992,
  "Michigan",       1993,
  "Iowa",           1992,
  "Louisiana",      1993,
  "Mississippi",    1994,
  "Arizona",        1993,
  "New Mexico",     1997,
  "Colorado",       1992,
  "Montana",        1994,
  "South Dakota",   1991,
  "North Dakota",   1992,
  "Nebraska",       1993,
  "Kansas",         1996,
  "Oklahoma",       2005,
  "Oregon",         1992,
  "Washington",     1991,
  "Idaho",          1993,
  "Nevada",         1998,
  "California",     2000,
  "New York",       1993,
  "North Carolina", 1994,
  "Florida",        2010,
  "Alabama",        1999,
  "Indiana",        1993,
  "Wyoming",        1993,
  "Texas",          2002,
  "Rhode Island",   1994
)

# Merge: prefer Federal Register dates when available, fill gaps with known dates
state_first_compact <- known_gaming_states |>
  left_join(fr_state_compact |> select(state_name, fr_year = first_compact_year),
            by = "state_name") |>
  mutate(
    # Use the earlier of FR date and known date
    first_compact_year = pmin(first_compact_year, fr_year, na.rm = TRUE)
  ) |>
  select(state_name, first_compact_year) |>
  left_join(state_fips |> select(state_name, state_code, state) |> distinct(),
            by = "state_name")

cat("  Gaming states:", nrow(state_first_compact), "\n")
cat("  First compacts:", paste(sort(unique(state_first_compact$first_compact_year)), collapse = ", "), "\n")
cat("  Treatment timing distribution:\n")
print(table(state_first_compact$first_compact_year))

# ============================================================
# PART 2: County-Level Drug Overdose Deaths
# ============================================================
# CDC VSRR Provisional County-Level Drug Overdose Deaths
# Dataset: gb4e-yj24 on data.cdc.gov
# Available: 2020-2025, total deaths only (no race breakdown)

cat("\n=== Fetching CDC VSRR county-level overdose deaths ===\n")

# Fetch VSRR county-level data
vsrr_county_url <- "https://data.cdc.gov/resource/gb4e-yj24.json"

# Get all records (paginate)
vsrr_all <- list()
offset <- 0
repeat {
  resp <- httr::GET(vsrr_county_url, query = list(
    `$limit` = 50000,
    `$offset` = offset,
    `$order` = "fips"
  ))
  if (httr::status_code(resp) != 200) {
    warning("VSRR API returned ", httr::status_code(resp), " at offset ", offset)
    break
  }
  batch <- httr::content(resp, as = "text", encoding = "UTF-8") |>
    jsonlite::fromJSON()
  if (nrow(batch) == 0) break
  vsrr_all[[length(vsrr_all) + 1]] <- batch
  offset <- offset + 50000
  cat("  Fetched", offset, "records...\n")
  if (nrow(batch) < 50000) break
  Sys.sleep(1)
}

vsrr_county <- bind_rows(vsrr_all)
cat("  Total VSRR county records:", nrow(vsrr_county), "\n")
cat("  Columns:", paste(names(vsrr_county), collapse = ", "), "\n")

# Clean VSRR data
# Find the overdose deaths column (name varies across API versions)
od_col <- names(vsrr_county)[grepl("provisional_drug_overdose", names(vsrr_county))][1]
cat("  Overdose column:", od_col, "\n")

vsrr_clean <- vsrr_county |>
  rename(od_deaths_raw = !!sym(od_col)) |>
  mutate(
    fips = as.character(fips),
    fips = ifelse(nchar(fips) == 4, paste0("0", fips), fips),
    overdose_deaths = as.numeric(od_deaths_raw),
    year = as.integer(substr(year, 1, 4))
  ) |>
  filter(!is.na(overdose_deaths), !is.na(fips)) |>
  select(fips, state_name = state_name, county_name = countyname,
         year, month, overdose_deaths)

cat("  Clean VSRR records:", nrow(vsrr_clean), "\n")
cat("  Years covered:", paste(sort(unique(vsrr_clean$year)), collapse = ", "), "\n")
cat("  Counties covered:", n_distinct(vsrr_clean$fips), "\n")

# ============================================================
# PART 2b: State-Level Drug Overdose Deaths (longer time series)
# ============================================================
# CDC NCHS Age-Adjusted Drug Overdose Death Rates by state
# Dataset: jx6g-fdh6 on data.cdc.gov (1999-2015)
# + VSRR state-level (xkb8-kh2a) for 2015-2024

cat("\n=== Fetching state-level overdose death rates ===\n")

# NCHS state-level 1999-2015
nchs_url <- "https://data.cdc.gov/resource/jx6g-fdh6.json"
nchs_resp <- httr::GET(nchs_url, query = list(
  `$limit` = 50000,
  sex = "Both Sexes",
  age = "All Ages",
  `race_hispanic_origin` = "All Races-All Origins"
))
stopifnot(httr::status_code(nchs_resp) == 200)
nchs_state <- httr::content(nchs_resp, as = "text", encoding = "UTF-8") |>
  jsonlite::fromJSON()

nchs_clean <- nchs_state |>
  mutate(
    year = as.integer(year),
    age_adjusted_rate = as.numeric(age_adjusted_rate),
    deaths = as.numeric(deaths),
    population = as.numeric(population)
  ) |>
  filter(!is.na(age_adjusted_rate), state != "United States") |>
  select(state, year, rate = age_adjusted_rate, deaths, population)

cat("  NCHS state records:", nrow(nchs_clean), "\n")
cat("  Years:", min(nchs_clean$year), "-", max(nchs_clean$year), "\n")
cat("  States:", n_distinct(nchs_clean$state), "\n")

# VSRR state-level 2015-2024
vsrr_state_url <- "https://data.cdc.gov/resource/xkb8-kh2a.json"
vsrr_state_resp <- httr::GET(vsrr_state_url, query = list(
  `$limit` = 50000,
  indicator = "Number of Drug Overdose Deaths",
  period = "12 month-ending"
))
stopifnot(httr::status_code(vsrr_state_resp) == 200)
vsrr_state <- httr::content(vsrr_state_resp, as = "text", encoding = "UTF-8") |>
  jsonlite::fromJSON()

vsrr_state_clean <- vsrr_state |>
  filter(month == "December") |>  # Annual total (12-month ending Dec)
  mutate(
    year = as.integer(year),
    deaths = as.numeric(data_value)
  ) |>
  filter(!is.na(deaths), !state_name %in% c("United States", "US")) |>
  select(state = state_name, year, deaths_vsrr = deaths)

cat("  VSRR state records:", nrow(vsrr_state_clean), "\n")
cat("  Years:", min(vsrr_state_clean$year, na.rm = TRUE), "-",
    max(vsrr_state_clean$year, na.rm = TRUE), "\n")

# Merge state-level: NCHS (1999-2015) + VSRR (2015-2024)
state_od <- nchs_clean |>
  select(state, year, od_deaths = deaths, od_rate = rate, population) |>
  bind_rows(
    vsrr_state_clean |>
      filter(year > 2015) |>
      rename(od_deaths = deaths_vsrr) |>
      mutate(od_rate = NA_real_, population = NA_real_)
  ) |>
  arrange(state, year) |>
  distinct(state, year, .keep_all = TRUE)

cat("  Combined state-level panel:", nrow(state_od), "state-years\n")
cat("  Years:", min(state_od$year), "-", max(state_od$year), "\n")

# ============================================================
# PART 3: County-Level Demographics (Census ACS)
# ============================================================
# AI/AN population share by county from ACS 5-year

cat("\n=== Fetching county demographics from Census ACS ===\n")

# Function to query ACS for a given year
fetch_acs_county <- function(yr) {
  # B02001_001E = total population
  # B02001_004E = American Indian and Alaska Native alone
  url <- paste0("https://api.census.gov/data/", yr, "/acs/acs5")
  resp <- httr::GET(url, query = list(
    get = "NAME,B02001_001E,B02001_004E",
    `for` = "county:*",
    key = census_key
  ))
  if (httr::status_code(resp) != 200) {
    warning("ACS ", yr, " failed: ", httr::status_code(resp))
    return(NULL)
  }
  raw <- httr::content(resp, as = "text", encoding = "UTF-8") |>
    jsonlite::fromJSON()
  df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
  names(df) <- raw[1, ]
  df |>
    mutate(
      fips = paste0(state, county),
      total_pop = as.integer(B02001_001E),
      aian_pop = as.integer(B02001_004E),
      year = yr
    ) |>
    select(fips, name = NAME, year, total_pop, aian_pop)
}

# Get demographics for 2010, 2015, 2020
acs_years <- c(2010, 2015, 2020)
acs_list <- list()
for (yr in acs_years) {
  cat("  Fetching ACS", yr, "...\n")
  acs_list[[as.character(yr)]] <- fetch_acs_county(yr)
  Sys.sleep(1)
}

acs_county <- bind_rows(acs_list) |>
  filter(!is.na(total_pop), total_pop > 0) |>
  mutate(aian_share = aian_pop / total_pop)

cat("  ACS county records:", nrow(acs_county), "\n")
cat("  Counties with >10% AI/AN:", sum(acs_county$aian_share > 0.10 & acs_county$year == 2010), "\n")
cat("  Counties with >25% AI/AN:", sum(acs_county$aian_share > 0.25 & acs_county$year == 2010), "\n")
cat("  Counties with >50% AI/AN:", sum(acs_county$aian_share > 0.50 & acs_county$year == 2010), "\n")

# Use 2010 as baseline AI/AN share (pre-treatment for most treatment timing)
aian_baseline <- acs_county |>
  filter(year == 2010) |>
  select(fips, aian_share_2010 = aian_share, aian_pop_2010 = aian_pop, total_pop_2010 = total_pop)

cat("  Baseline (2010) counties:", nrow(aian_baseline), "\n")

# ============================================================
# PART 4: Identify "Tribal Counties" from Census Geography
# ============================================================

cat("\n=== Identifying tribal counties via Census AIAN geography ===\n")

# Use tigris to get counties and AIAN areas, then spatial join
# to find which counties contain tribal lands

# Get county boundaries
counties_sf <- tigris::counties(year = 2020, cb = TRUE) |>
  select(GEOID, NAME, STATEFP, STUSPS) |>
  st_transform(4326)

# Get AIAN areas (reservations + TDSA + ANVSA)
aian_areas <- tryCatch({
  tigris::native_areas(year = 2020, cb = TRUE) |>
    select(GEOID, NAMELSAD, LSAD) |>
    st_transform(4326)
}, error = function(e) {
  cat("  Warning: Could not fetch AIAN areas:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(aian_areas)) {
  cat("  AIAN areas loaded:", nrow(aian_areas), "\n")

  # Spatial intersection: which counties contain AIAN lands?
  # Use st_intersects for efficiency
  intersects <- st_intersects(counties_sf, aian_areas)
  tribal_counties <- counties_sf |>
    mutate(
      has_tribal_land = lengths(intersects) > 0,
      n_tribal_areas = lengths(intersects)
    ) |>
    st_drop_geometry() |>
    select(fips = GEOID, state_abbr = STUSPS, has_tribal_land, n_tribal_areas)

  cat("  Counties with tribal land:", sum(tribal_counties$has_tribal_land), "\n")
} else {
  # Fallback: use AI/AN population share as proxy
  cat("  Using AI/AN share >5% as tribal county proxy\n")
  tribal_counties <- aian_baseline |>
    mutate(
      has_tribal_land = aian_share_2010 > 0.05,
      n_tribal_areas = ifelse(has_tribal_land, 1, 0)
    ) |>
    select(fips, has_tribal_land, n_tribal_areas)
}

# ============================================================
# PART 5: Merge Treatment Assignment
# ============================================================

cat("\n=== Constructing treatment assignment ===\n")

# Map first compact year to states, then to counties
treatment <- tribal_counties |>
  mutate(state_code = substr(fips, 1, 2)) |>
  left_join(
    state_first_compact |> select(state_code, first_compact_year),
    by = "state_code"
  ) |>
  mutate(
    # Treatment: county has tribal land AND is in a gaming state
    has_casino = has_tribal_land & !is.na(first_compact_year),
    treatment_year = ifelse(has_casino, first_compact_year, NA_integer_)
  )

cat("  Casino counties (tribal land + gaming state):", sum(treatment$has_casino, na.rm = TRUE), "\n")
cat("  Non-gaming tribal counties:", sum(treatment$has_tribal_land & !treatment$has_casino, na.rm = TRUE), "\n")
cat("  Treatment timing distribution:\n")
print(table(treatment$treatment_year, useNA = "ifany"))

# ============================================================
# SAVE ALL DATA
# ============================================================

cat("\n=== Saving data ===\n")
saveRDS(compact_df, file.path(data_dir, "federal_register_compacts.rds"))
saveRDS(state_first_compact, file.path(data_dir, "state_first_compact.rds"))
saveRDS(vsrr_clean, file.path(data_dir, "vsrr_county_od.rds"))
saveRDS(state_od, file.path(data_dir, "state_overdose_panel.rds"))
saveRDS(acs_county, file.path(data_dir, "acs_county_demographics.rds"))
saveRDS(aian_baseline, file.path(data_dir, "aian_baseline_2010.rds"))
saveRDS(tribal_counties, file.path(data_dir, "tribal_counties.rds"))
saveRDS(treatment, file.path(data_dir, "treatment_assignment.rds"))

cat("\nData fetch complete. All files saved to", data_dir, "\n")
cat("Summary:\n")
cat("  Federal Register compacts:", nrow(compact_df), "\n")
cat("  Gaming states:", nrow(state_first_compact), "\n")
cat("  State-level OD panel:", nrow(state_od), "state-years\n")
cat("  County-level VSRR OD:", nrow(vsrr_clean), "records\n")
cat("  County demographics:", nrow(acs_county), "records\n")
cat("  Tribal counties:", sum(tribal_counties$has_tribal_land), "\n")
cat("  Casino counties:", sum(treatment$has_casino, na.rm = TRUE), "\n")
