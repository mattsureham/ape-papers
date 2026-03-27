# =============================================================================
# 02_clean_data.R — Clean and merge H-2A + QWI data
# apep_1070: H-2A Guestworker Expansion and Farm Worker Displacement
# =============================================================================

source("00_packages.R")

# ---------------------------------------------------------------------------
# 1. Load raw data
# ---------------------------------------------------------------------------
h2a_county <- readRDS("../data/h2a_county_year.rds")
qwi_ag <- readRDS("../data/qwi_agriculture.rds")
qwi_placebo <- readRDS("../data/qwi_placebo.rds")

# ---------------------------------------------------------------------------
# 2. Build county FIPS crosswalk from QWI geography codes
# ---------------------------------------------------------------------------
# QWI geography is 5-digit FIPS (SSCCC)
# H-2A data has state abbreviation + county name
# We need to map county names → FIPS

# Get unique QWI counties
qwi_counties <- qwi_ag %>%
  mutate(
    state_fips = substr(as.character(geography), 1, 2),
    county_fips = as.character(geography)
  ) %>%
  distinct(state_fips, county_fips)

cat(sprintf("QWI covers %d unique counties\n", nrow(qwi_counties)))

# State abbreviation to FIPS mapping
state_fips_map <- data.frame(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                  "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                  "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                  "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                  "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  state_fips = c("01","02","04","05","06","08","09","10","12","13",
                  "15","16","17","18","19","20","21","22","23","24",
                  "25","26","27","28","29","30","31","32","33","34",
                  "35","36","37","38","39","40","41","42","44","45",
                  "46","47","48","49","50","51","53","54","55","56","11"),
  stringsAsFactors = FALSE
)

# Use tidycensus or census.gov FIPS crosswalk
# Download county FIPS codes from Census
county_fips_url <- "https://www2.census.gov/geo/docs/reference/codes2020/national_county2020.txt"
county_fips_file <- "../data/county_fips.csv"

if (!file.exists(county_fips_file)) {
  download.file(county_fips_url, county_fips_file, quiet = TRUE)
}

county_xwalk <- tryCatch({
  read.csv(county_fips_file, header = TRUE, colClasses = "character", sep = "|")
}, error = function(e) {
  # Try pipe-delimited
  readr::read_delim(county_fips_file, delim = "|", col_types = cols(.default = "c"))
})

names(county_xwalk) <- toupper(names(county_xwalk))

# Standardize
county_xwalk <- county_xwalk %>%
  mutate(
    state_fips = STATEFP,
    county_fips_code = COUNTYFP,
    fips5 = paste0(STATEFP, COUNTYFP),
    county_name_clean = toupper(trimws(COUNTYNAME))
  ) %>%
  # Remove " COUNTY", " PARISH", " BOROUGH", " CENSUS AREA", etc.
  mutate(
    county_name_short = gsub("\\s+(COUNTY|PARISH|BOROUGH|CENSUS AREA|MUNICIPALITY|CITY AND BOROUGH|CITY)$",
                              "", county_name_clean)
  ) %>%
  left_join(state_fips_map, by = "state_fips") %>%
  select(state_abbr, state_fips, county_fips_code, fips5, county_name_clean, county_name_short)

cat(sprintf("County FIPS crosswalk: %d entries\n", nrow(county_xwalk)))

# ---------------------------------------------------------------------------
# 3. Match H-2A county names to FIPS
# ---------------------------------------------------------------------------
# Clean H-2A county names to match crosswalk
h2a_county <- h2a_county %>%
  mutate(
    county_clean = toupper(trimws(ws_county)),
    county_clean = gsub("\\s+(COUNTY|PARISH|BOROUGH)$", "", county_clean),
    county_clean = gsub("\\.", "", county_clean),  # "ST." → "ST"
    county_clean = gsub("SAINT ", "ST ", county_clean)
  )

# Join H-2A to FIPS
h2a_fips <- h2a_county %>%
  left_join(
    county_xwalk %>% select(state_abbr, county_name_short, fips5),
    by = c("ws_state" = "state_abbr", "county_clean" = "county_name_short")
  )

matched <- sum(!is.na(h2a_fips$fips5))
total <- nrow(h2a_fips)
cat(sprintf("\nH-2A FIPS matching: %d/%d matched (%.1f%%)\n",
            matched, total, 100 * matched / total))

# For unmatched, try fuzzy matching on county name
unmatched <- h2a_fips %>% filter(is.na(fips5))
if (nrow(unmatched) > 0) {
  cat(sprintf("  %d unmatched records. Top unmatched counties:\n", nrow(unmatched)))
  unmatched %>%
    group_by(ws_state, county_clean) %>%
    summarise(positions = sum(h2a_positions), .groups = "drop") %>%
    arrange(desc(positions)) %>%
    head(20) %>%
    print()

  # Try matching with "ST" → "SAINT" variant and other common mismatches
  h2a_fips <- h2a_fips %>%
    mutate(fips5 = ifelse(
      is.na(fips5),
      county_xwalk$fips5[match(
        paste(ws_state, gsub("^ST ", "SAINT ", county_clean)),
        paste(county_xwalk$state_abbr, county_xwalk$county_name_short)
      )],
      fips5
    ))

  matched2 <- sum(!is.na(h2a_fips$fips5))
  cat(sprintf("  After fuzzy: %d/%d matched (%.1f%%)\n",
              matched2, total, 100 * matched2 / total))
}

# Drop unmatched and aggregate to FIPS-year
h2a_panel <- h2a_fips %>%
  filter(!is.na(fips5)) %>%
  group_by(fips5, fiscal_year) %>%
  summarise(
    h2a_positions = sum(h2a_positions, na.rm = TRUE),
    n_employers = sum(n_employers, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(county_fips = fips5, year = fiscal_year)

cat(sprintf("\nH-2A panel: %d county-year obs, %d unique counties\n",
            nrow(h2a_panel), n_distinct(h2a_panel$county_fips)))

# ---------------------------------------------------------------------------
# 4. Clean QWI data
# ---------------------------------------------------------------------------
clean_qwi <- function(df) {
  df %>%
    mutate(
      county_fips = sprintf("%05d", as.integer(geography)),
      state_fips = substr(county_fips, 1, 2),
      year = as.integer(year),
      quarter = as.integer(quarter),
      # Create year-quarter
      yq = year + (quarter - 1) / 4,
      # Ethnicity label
      hispanic = ifelse(ethnicity == "A2", 1L, 0L),
      # Convert outcomes to numeric
      emp = as.numeric(Emp),
      emp_end = as.numeric(EmpEnd),
      emp_stable = as.numeric(EmpS),
      hires = as.numeric(HirA),
      new_hires = as.numeric(HirN),
      separations = as.numeric(Sep),
      earnings = as.numeric(EarnS),
      earn_beg = as.numeric(EarnBeg)
    ) %>%
    filter(year >= 2010, year <= 2023) %>%
    select(county_fips, state_fips, year, quarter, yq, hispanic, industry,
           emp, emp_end, emp_stable, hires, new_hires, separations, earnings, earn_beg)
}

qwi_ag_clean <- clean_qwi(qwi_ag)
qwi_placebo_clean <- clean_qwi(qwi_placebo)

cat(sprintf("QWI agriculture (cleaned): %d rows\n", nrow(qwi_ag_clean)))
cat(sprintf("QWI placebo (cleaned): %d rows\n", nrow(qwi_placebo_clean)))

# ---------------------------------------------------------------------------
# 5. Merge H-2A treatment into QWI panel
# ---------------------------------------------------------------------------
# Expand H-2A to all years (0 for counties with no H-2A)
all_counties <- qwi_ag_clean %>% distinct(county_fips, state_fips)
all_years <- data.frame(year = 2010:2023)

county_year_grid <- crossing(all_counties, all_years)

h2a_expanded <- county_year_grid %>%
  left_join(h2a_panel, by = c("county_fips", "year")) %>%
  mutate(
    h2a_positions = replace_na(h2a_positions, 0),
    n_employers = replace_na(n_employers, 0),
    ln_h2a = log(h2a_positions + 1)
  )

# Compute Bartik IV: initial share × national growth
# Initial share: county's 2014 H-2A as fraction of state total
initial_year <- 2018
h2a_initial <- h2a_expanded %>%
  filter(year == initial_year) %>%
  group_by(state_fips) %>%
  mutate(state_total = sum(h2a_positions)) %>%
  ungroup() %>%
  mutate(
    initial_share = ifelse(state_total > 0, h2a_positions / state_total, 0)
  ) %>%
  select(county_fips, initial_h2a = h2a_positions, initial_share)

# National H-2A growth (relative to initial year)
national_h2a <- h2a_expanded %>%
  group_by(year) %>%
  summarise(national_h2a = sum(h2a_positions), .groups = "drop") %>%
  mutate(
    national_h2a_initial = national_h2a[year == initial_year],
    national_growth = national_h2a / national_h2a_initial
  )

# Bartik = initial_share × national_growth
h2a_expanded <- h2a_expanded %>%
  left_join(h2a_initial, by = "county_fips") %>%
  left_join(national_h2a %>% select(year, national_growth), by = "year") %>%
  mutate(
    bartik_h2a = initial_share * national_growth,
    ln_bartik = log(bartik_h2a + 1)
  )

# Merge into QWI agriculture panel
analysis_df <- qwi_ag_clean %>%
  left_join(
    h2a_expanded %>% select(county_fips, year, h2a_positions, ln_h2a,
                             initial_h2a, initial_share, bartik_h2a, ln_bartik),
    by = c("county_fips", "year")
  ) %>%
  mutate(
    h2a_positions = replace_na(h2a_positions, 0),
    ln_h2a = replace_na(ln_h2a, 0),
    initial_h2a = replace_na(initial_h2a, 0),
    initial_share = replace_na(initial_share, 0),
    bartik_h2a = replace_na(bartik_h2a, 0),
    ln_bartik = replace_na(ln_bartik, 0)
  )

# Create fixed effect IDs
analysis_df <- analysis_df %>%
  mutate(
    county_eth = paste0(county_fips, "_", hispanic),
    quarter_eth = paste0(year, "Q", quarter, "_", hispanic),
    state_quarter = paste0(state_fips, "_", year, "Q", quarter),
    year_quarter = paste0(year, "Q", quarter)
  )

# Similarly for placebo industries
placebo_df <- qwi_placebo_clean %>%
  left_join(
    h2a_expanded %>% select(county_fips, year, h2a_positions, ln_h2a,
                             initial_h2a, initial_share, bartik_h2a, ln_bartik),
    by = c("county_fips", "year")
  ) %>%
  mutate(
    h2a_positions = replace_na(h2a_positions, 0),
    ln_h2a = replace_na(ln_h2a, 0),
    initial_h2a = replace_na(initial_h2a, 0),
    initial_share = replace_na(initial_share, 0),
    bartik_h2a = replace_na(bartik_h2a, 0),
    ln_bartik = replace_na(ln_bartik, 0),
    county_eth = paste0(county_fips, "_", hispanic),
    quarter_eth = paste0(year, "Q", quarter, "_", hispanic),
    state_quarter = paste0(state_fips, "_", year, "Q", quarter),
    year_quarter = paste0(year, "Q", quarter)
  )

# ---------------------------------------------------------------------------
# 6. Summary statistics
# ---------------------------------------------------------------------------
cat("\n=== ANALYSIS PANEL SUMMARY ===\n")
cat(sprintf("Total county-quarter-ethnicity obs: %d\n", nrow(analysis_df)))
cat(sprintf("Unique counties: %d\n", n_distinct(analysis_df$county_fips)))
cat(sprintf("Year range: %d-%d\n", min(analysis_df$year), max(analysis_df$year)))

cat("\nH-2A treatment distribution:\n")
analysis_df %>%
  filter(hispanic == 0) %>%  # one obs per county-quarter
  group_by(year) %>%
  summarise(
    counties_with_h2a = sum(h2a_positions > 0),
    mean_h2a = mean(h2a_positions),
    median_h2a = median(h2a_positions),
    max_h2a = max(h2a_positions),
    total_h2a = sum(h2a_positions)
  ) %>%
  print(n = 20)

cat("\nEmployment by ethnicity (NAICS 11):\n")
analysis_df %>%
  group_by(hispanic) %>%
  summarise(
    obs = n(),
    non_missing_emp = sum(!is.na(emp)),
    mean_emp = mean(emp, na.rm = TRUE),
    mean_earnings = mean(earnings, na.rm = TRUE),
    mean_sep = mean(separations, na.rm = TRUE),
    mean_hires = mean(hires, na.rm = TRUE)
  ) %>%
  print()

# ---------------------------------------------------------------------------
# 7. Save analysis dataset
# ---------------------------------------------------------------------------
saveRDS(analysis_df, "../data/analysis_panel.rds")
saveRDS(placebo_df, "../data/placebo_panel.rds")
saveRDS(h2a_expanded, "../data/h2a_panel_full.rds")

cat("\nAnalysis datasets saved.\n")
