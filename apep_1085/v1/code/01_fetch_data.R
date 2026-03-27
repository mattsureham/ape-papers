# 01_fetch_data.R — Fetch USGS wind turbine data and GBIF bird observations
# Wind Turbines and Avian Community Restructuring

library(tidyverse)
library(httr)
library(jsonlite)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))[1]
if (length(script_dir) > 0 && nchar(script_dir) > 0) {
  setwd(file.path(script_dir, ".."))
}

dir.create("data", showWarnings = FALSE)

# ============================================================
# 1. USGS Wind Turbine Database
# ============================================================
cat("=== Fetching USGS Wind Turbine Database ===\n")

wtdb_url <- "https://eerscmap.usgs.gov/uswtdb/assets/data/uswtdbCSV.zip"
wtdb_zip <- "data/uswtdb.zip"

download.file(wtdb_url, wtdb_zip, mode = "wb", quiet = FALSE)
unzip(wtdb_zip, exdir = "data/")

# Find the CSV file
wtdb_files <- list.files("data/", pattern = "uswtdb.*\\.csv$", full.names = TRUE)
if (length(wtdb_files) == 0) stop("USGS WTDB CSV not found after unzip")

wtdb_raw <- read_csv(wtdb_files[1], show_col_types = FALSE)
cat(sprintf("USGS WTDB: %d turbines\n", nrow(wtdb_raw)))

# Clean and aggregate to state-year
wtdb <- wtdb_raw %>%
  filter(!is.na(p_year), !is.na(t_state), !is.na(t_cap)) %>%
  transmute(
    state = t_state,
    fips = t_fips,
    county = t_county,
    year_operational = as.integer(p_year),
    capacity_kw = as.numeric(t_cap),
    hub_height_m = as.numeric(t_hh),
    rotor_diam_m = as.numeric(t_rd),
    latitude = as.numeric(ylat),
    longitude = as.numeric(xlong)
  )

cat(sprintf("Cleaned: %d turbines with valid state/year/capacity\n", nrow(wtdb)))
cat(sprintf("States represented: %d\n", n_distinct(wtdb$state)))
cat(sprintf("Year range: %d - %d\n", min(wtdb$year_operational), max(wtdb$year_operational)))

# Aggregate to state-year
state_wind <- wtdb %>%
  group_by(state, year_operational) %>%
  summarise(
    n_turbines_new = n(),
    capacity_new_mw = sum(capacity_kw, na.rm = TRUE) / 1000,
    mean_hub_height = mean(hub_height_m, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(state, year_operational)

# Cumulative capacity by state
state_cumul <- state_wind %>%
  group_by(state) %>%
  arrange(year_operational) %>%
  mutate(
    cum_turbines = cumsum(n_turbines_new),
    cum_capacity_mw = cumsum(capacity_new_mw)
  ) %>%
  ungroup()

saveRDS(wtdb, "data/wtdb_clean.rds")
saveRDS(state_cumul, "data/state_wind_cumul.rds")

# Determine first treatment year per state (first year with >=100 MW cumulative)
first_treat <- state_cumul %>%
  filter(cum_capacity_mw >= 100) %>%
  group_by(state) %>%
  summarise(first_treat_year = min(year_operational), .groups = "drop")

cat(sprintf("\nStates reaching 100 MW: %d\n", nrow(first_treat)))
cat("Treatment timing distribution:\n")
print(table(first_treat$first_treat_year))

saveRDS(first_treat, "data/first_treat.rds")

# ============================================================
# 2. GBIF bird occurrence data (eBird dataset)
# ============================================================
cat("\n=== Fetching GBIF bird occurrence data ===\n")

# Target taxa (GBIF taxon keys)
taxa <- list(
  raptors = list(name = "Accipitridae", key = 2480830),
  grassland = list(name = "Grasshopper Sparrow", key = 2491261),
  waterfowl = list(name = "Anatidae", key = 2498252)  # Placebo
)

# eBird dataset key on GBIF
ebird_key <- "4fa7b334-ce0d-4e88-aaae-2e0c138d049e"

# Years to query
years <- 2008:2023

# US state codes for GBIF
us_states <- c(
  "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
  "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
  "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
  "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
  "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
)

# State abbreviation to full name mapping for GBIF
state_names <- c(
  AL="Alabama",AK="Alaska",AZ="Arizona",AR="Arkansas",CA="California",
  CO="Colorado",CT="Connecticut",DE="Delaware",FL="Florida",GA="Georgia",
  HI="Hawaii",ID="Idaho",IL="Illinois",IN="Indiana",IA="Iowa",
  KS="Kansas",KY="Kentucky",LA="Louisiana",ME="Maine",MD="Maryland",
  MA="Massachusetts",MI="Michigan",MN="Minnesota",MS="Mississippi",
  MO="Missouri",MT="Montana",NE="Nebraska",NV="Nevada",NH="New Hampshire",
  NJ="New Jersey",NM="New Mexico",NY="New York",NC="North Carolina",
  ND="North Dakota",OH="Ohio",OK="Oklahoma",OR="Oregon",PA="Pennsylvania",
  RI="Rhode Island",SC="South Carolina",SD="South Dakota",TN="Tennessee",
  TX="Texas",UT="Utah",VT="Vermont",VA="Virginia",WA="Washington",
  WV="West Virginia",WI="Wisconsin",WY="Wyoming"
)

# Function to query GBIF occurrence count via search endpoint
query_gbif_count <- function(taxon_key, state_name, year) {
  url <- paste0(
    "https://api.gbif.org/v1/occurrence/search?",
    "taxonKey=", taxon_key,
    "&country=US",
    "&stateProvince=", URLencode(state_name),
    "&year=", year,
    "&limit=0"
  )

  resp <- tryCatch(
    GET(url, timeout(15)),
    error = function(e) NULL
  )

  if (is.null(resp) || status_code(resp) != 200) return(NA_integer_)

  parsed <- tryCatch(
    fromJSON(content(resp, "text", encoding = "UTF-8")),
    error = function(e) NULL
  )

  if (is.null(parsed)) return(NA_integer_)
  return(as.integer(parsed$count))
}

# Query all combinations
all_results <- list()

for (taxon_name in names(taxa)) {
  taxon_key <- taxa[[taxon_name]]$key
  taxon_label <- taxa[[taxon_name]]$name
  cat(sprintf("\nQuerying %s (key=%d)...\n", taxon_label, taxon_key))

  for (yr in years) {
    cat(sprintf("  Year %d: ", yr))
    year_counts <- map_int(us_states, function(st) {
      Sys.sleep(0.05)  # Rate limiting
      query_gbif_count(taxon_key, state_names[st], yr)
    })
    names(year_counts) <- us_states

    result <- tibble(
      state = us_states,
      year = yr,
      taxon = taxon_name,
      taxon_name = taxon_label,
      n_records = year_counts
    )
    all_results[[paste(taxon_name, yr)]] <- result
    cat(sprintf("total = %s\n", format(sum(year_counts, na.rm = TRUE), big.mark = ",")))
  }
}

bird_data <- bind_rows(all_results)
cat(sprintf("\nTotal bird observations queried: %d state-year-taxon combinations\n",
            nrow(bird_data)))

# Also get total eBird checklists per state-year (effort control)
# Use a very broad taxon (Aves = all birds, key 212)
cat("\nQuerying total eBird records (effort baseline)...\n")
effort_results <- list()

for (yr in years) {
  cat(sprintf("  Year %d: ", yr))
  year_counts <- map_int(us_states, function(st) {
    Sys.sleep(0.05)
    query_gbif_count(212, state_names[st], yr)
  })
  names(year_counts) <- us_states
  effort_results[[as.character(yr)]] <- tibble(
    state = us_states,
    year = yr,
    total_bird_records = year_counts
  )
  cat(sprintf("total = %s\n", format(sum(year_counts, na.rm = TRUE), big.mark = ",")))
}

effort_data <- bind_rows(effort_results)

# Merge bird data with effort data
bird_panel <- bird_data %>%
  left_join(effort_data, by = c("state", "year")) %>%
  mutate(
    reporting_rate = n_records / pmax(total_bird_records, 1)
  )

saveRDS(bird_panel, "data/bird_panel.rds")
saveRDS(effort_data, "data/effort_data.rds")

cat(sprintf("\n=== DATA FETCH COMPLETE ===\n"))
cat(sprintf("Turbines: %d\n", nrow(wtdb)))
cat(sprintf("States with wind: %d\n", nrow(first_treat)))
cat(sprintf("Bird observations: %d state-year-taxon rows\n", nrow(bird_panel)))
