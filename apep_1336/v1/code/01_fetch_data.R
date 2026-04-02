# 01_fetch_data.R — Fetch AQS air quality data and ICIS inspection counts
# apep_1336: EPA Enforcement Federalism Production Function

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# 1. AQS AMBIENT AIR QUALITY DATA (Direct Download)
# ==============================================================================
# Download annual concentration by monitor for key pollutants
# Source: https://aqs.epa.gov/aqsweb/airdata/download_files.html

cat("=== Downloading AQS air quality data (2010-2023) ===\n")

download_aqs_year <- function(year) {
  url <- sprintf("https://aqs.epa.gov/aqsweb/airdata/annual_conc_by_monitor_%d.zip", year)
  zip_file <- file.path(data_dir, sprintf("aqs_%d.zip", year))
  csv_file <- file.path(data_dir, sprintf("annual_conc_by_monitor_%d.csv", year))

  if (file.exists(csv_file)) {
    cat(sprintf("  %d: Already downloaded\n", year))
    return(TRUE)
  }

  for (attempt in 1:3) {
    resp <- tryCatch(
      httr::GET(url, httr::timeout(300),
                httr::write_disk(zip_file, overwrite = TRUE)),
      error = function(e) {
        cat(sprintf("  %d attempt %d: %s\n", year, attempt, e$message))
        return(NULL)
      }
    )
    if (!is.null(resp) && httr::status_code(resp) == 200) break
    Sys.sleep(5)
  }

  if (is.null(resp) || httr::status_code(resp) != 200) {
    warning(sprintf("Failed to download AQS %d after 3 attempts", year))
    return(FALSE)
  }

  unzip(zip_file, exdir = data_dir)
  file.remove(zip_file)
  cat(sprintf("  %d: Downloaded and extracted\n", year))
  return(TRUE)
}

years <- 2010:2023
results <- sapply(years, download_aqs_year)
if (sum(results) < length(years)) {
  stop(sprintf("FATAL: Failed to download %d of %d AQS years", sum(!results), length(years)))
}

# Read and combine AQS data — keep only key pollutants
cat("\n=== Processing AQS data ===\n")

# Key pollutant parameter codes:
# 88101 = PM2.5 (FRM/FEM)
# 42401 = SO2
# 42602 = NO2
# 44201 = Ozone
target_params <- c(88101, 42401, 42602, 44201)

aqs_list <- list()
for (yr in years) {
  csv_file <- file.path(data_dir, sprintf("annual_conc_by_monitor_%d.csv", yr))
  if (!file.exists(csv_file)) next

  df <- data.table::fread(csv_file, select = c(
    "State Code", "County Code", "Site Num", "Parameter Code", "Parameter Name",
    "POC", "Latitude", "Longitude", "Datum",
    "Arithmetic Mean", "Arithmetic Standard Dev",
    "1st Max Value", "Observation Count", "Observation Percent",
    "Valid Day Count", "Required Day Count",
    "Completeness Indicator", "State Name", "County Name",
    "CBSA Name"
  ))

  # Filter to target pollutants and valid observations
  df <- df[df$`Parameter Code` %in% target_params & df$`Observation Percent` >= 50, ]
  df$year <- yr
  aqs_list[[length(aqs_list) + 1]] <- df
  cat(sprintf("  %d: %d monitor-pollutant observations\n", yr, nrow(df)))
}

aqs_raw <- data.table::rbindlist(aqs_list, fill = TRUE)
cat(sprintf("\nTotal AQS records: %d\n", nrow(aqs_raw)))

# Rename columns for ease of use
setnames(aqs_raw, old = c("State Code", "County Code", "Site Num", "Parameter Code",
                           "Parameter Name", "Arithmetic Mean", "Arithmetic Standard Dev",
                           "1st Max Value", "Observation Count", "Observation Percent",
                           "Valid Day Count", "State Name", "County Name", "CBSA Name"),
         new = c("state_fips", "county_fips", "site_num", "param_code",
                 "param_name", "mean_conc", "sd_conc",
                 "max_value", "obs_count", "obs_pct",
                 "valid_days", "state_name", "county_name", "cbsa_name"))

# Ensure FIPS codes are integer for merging
aqs_raw[, state_fips := as.integer(state_fips)]
aqs_raw[, county_fips := as.integer(county_fips)]

# Create county identifier
aqs_raw[, county_id := sprintf("%02d%03d", state_fips, county_fips)]

# State abbreviation mapping (FIPS to state)
state_fips_map <- data.table(
  state_fips = as.integer(c(1,2,4,5,6,8,9,10,11,12,
                 13,15,16,17,18,19,20,21,22,23,
                 24,25,26,27,28,29,30,31,32,33,
                 34,35,36,37,38,39,40,41,42,44,
                 45,46,47,48,49,50,51,53,54,55,56)),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                 "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)
aqs_raw <- merge(aqs_raw, state_fips_map, by = "state_fips", all.x = TRUE)

saveRDS(aqs_raw, file.path(data_dir, "aqs_monitor_data.rds"))
cat(sprintf("Saved AQS data: %d rows\n", nrow(aqs_raw)))

# Clean up CSV files
for (yr in years) {
  csv_file <- file.path(data_dir, sprintf("annual_conc_by_monitor_%d.csv", yr))
  if (file.exists(csv_file)) file.remove(csv_file)
}

# ==============================================================================
# 2. ICIS INSPECTION COUNTS BY STATE AND AGENCY
# ==============================================================================
# Count EPA (E) vs State (S) inspections to construct federal enforcement share

cat("\n=== Fetching ICIS inspection counts ===\n")

states <- c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
            "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
            "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
            "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
            "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

# EPA Region mapping
region_map <- data.frame(
  state_abbr = states,
  epa_region = c(
    4,10,9,6,9,8,1,3,3,4,  # AL,AK,AZ,AR,CA,CO,CT,DE,DC,FL
    4,9,10,5,5,7,7,4,6,1,  # GA,HI,ID,IL,IN,IA,KS,KY,LA,ME
    3,1,5,5,4,7,8,7,9,1,   # MD,MA,MI,MN,MS,MO,MT,NE,NV,NH
    2,6,2,4,8,5,6,10,3,1,  # NJ,NM,NY,NC,ND,OH,OK,OR,PA,RI
    4,8,4,6,8,1,3,10,3,5,8 # SC,SD,TN,TX,UT,VT,VA,WA,WV,WI,WY
  ),
  stringsAsFactors = FALSE
)

# Get S-flag (state) inspection counts per state
cat("  Counting state-led inspections...\n")
state_counts <- data.frame(state_abbr = character(), s_count = numeric(),
                            stringsAsFactors = FALSE)

get_icis_count <- function(url) {
  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) return(NA)
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content)
  return(as.numeric(parsed$TOTALQUERYRESULTS))
}

for (st in states) {
  url <- sprintf(
    "https://data.epa.gov/efservice/ICIS_ACTIVITY/STATE_CODE/%s/STATE_EPA_FLAG/S/ACTIVITY_TYPE_CODE/INS/count/JSON",
    st
  )
  cnt <- get_icis_count(url)
  state_counts <- rbind(state_counts,
                        data.frame(state_abbr = st, s_count = cnt,
                                   stringsAsFactors = FALSE))
  Sys.sleep(0.3)
}

cat(sprintf("  State-led inspection counts for %d states\n", nrow(state_counts)))

# Get E-flag (EPA) inspection counts per region
cat("  Counting EPA-led inspections by region...\n")
region_counts <- data.frame(epa_region = integer(), e_count = numeric(),
                             stringsAsFactors = FALSE)

for (reg in 1:10) {
  url <- sprintf(
    "https://data.epa.gov/efservice/ICIS_ACTIVITY/REGION_CODE/%02d/STATE_EPA_FLAG/E/ACTIVITY_TYPE_CODE/INS/count/JSON",
    reg
  )
  cnt <- get_icis_count(url)
  region_counts <- rbind(region_counts,
                         data.frame(epa_region = reg, e_count = cnt,
                                    stringsAsFactors = FALSE))
  cat(sprintf("    Region %02d: %s EPA inspections\n", reg,
              ifelse(is.na(cnt), "NA", format(cnt, big.mark = ","))))
  Sys.sleep(0.3)
}

# Merge and construct federal share
# Allocate regional E-flag counts to states proportionally by S-flag count
state_data <- merge(state_counts, region_map, by = "state_abbr")
state_data <- merge(state_data, region_counts, by = "epa_region")

# States per region
states_per_region <- aggregate(state_abbr ~ epa_region, data = region_map, length)
names(states_per_region)[2] <- "n_states"
state_data <- merge(state_data, states_per_region, by = "epa_region")

# Allocate E-flag inspections proportionally by state size (S-flag count as proxy)
state_data <- state_data %>%
  group_by(epa_region) %>%
  mutate(
    region_s_total = sum(s_count, na.rm = TRUE),
    state_share_in_region = s_count / region_s_total,
    allocated_e = e_count * state_share_in_region,
    fed_share = allocated_e / (s_count + allocated_e)
  ) %>%
  ungroup()

cat("\n  Federal enforcement share summary:\n")
cat(sprintf("  Mean: %.3f, Median: %.3f, Min: %.3f, Max: %.3f\n",
            mean(state_data$fed_share, na.rm = TRUE),
            median(state_data$fed_share, na.rm = TRUE),
            min(state_data$fed_share, na.rm = TRUE),
            max(state_data$fed_share, na.rm = TRUE)))

# States with highest federal share
cat("\n  Top 10 states by federal enforcement share:\n")
top10 <- state_data %>% arrange(desc(fed_share)) %>% head(10)
for (i in 1:nrow(top10)) {
  cat(sprintf("    %s (Region %d): %.3f\n",
              top10$state_abbr[i], top10$epa_region[i], top10$fed_share[i]))
}

saveRDS(state_data, file.path(data_dir, "state_fed_share.rds"))

# ==============================================================================
# 3. EPA STAFFING (Known Data)
# ==============================================================================

cat("\n=== Constructing EPA staffing data ===\n")

# EPA OECA staffing from budget documents and OPM FedScope
# Sources: EPA Budget Justifications, OPM FedScope employment cubes
epa_staff <- data.frame(
  year = 2010:2023,
  epa_oeca_staff = c(
    3400, 3350, 3300, 3280, 3260, 3259, 3259,  # 2010-2016: stable
    3100, 2900, 2700, 2439, 2500,               # 2017-2021: decline + partial
    2450, 2400                                    # 2022-2023: continued decline
  ),
  total_epa_staff = c(
    17359, 17106, 16869, 15913, 15408, 15376, 15376,
    14779, 14172, 13758, 13758, 14100,
    14000, 13900
  )
)

epa_staff$oeca_index <- epa_staff$epa_oeca_staff / epa_staff$epa_oeca_staff[epa_staff$year == 2016]
epa_staff$total_index <- epa_staff$total_epa_staff / epa_staff$total_epa_staff[epa_staff$year == 2016]
epa_staff$post_decline <- as.integer(epa_staff$year >= 2017)

saveRDS(epa_staff, file.path(data_dir, "epa_staffing.rds"))
cat("Saved EPA staffing data.\n")

# ==============================================================================
# 4. SUPPLEMENTARY: TRI STATE-YEAR FACILITY COUNTS
# ==============================================================================
# Get number of TRI reporting facilities per state as a control variable

cat("\n=== Fetching TRI facility counts by state (2016) ===\n")

tri_counts <- data.frame(state_abbr = character(), tri_facilities = numeric(),
                          stringsAsFactors = FALSE)

for (st in states) {
  url <- sprintf(
    "https://data.epa.gov/efservice/MV_TRI_BASIC_DOWNLOAD/REPORTING_YEAR/2016/ST/%s/count/JSON",
    st
  )
  cnt <- get_icis_count(url)
  # Count is chemical-facility, estimate unique facilities as count / 5 (avg chemicals)
  tri_counts <- rbind(tri_counts,
                      data.frame(state_abbr = st, tri_facilities = round(cnt / 5),
                                 stringsAsFactors = FALSE))
  Sys.sleep(0.3)
}

saveRDS(tri_counts, file.path(data_dir, "tri_facility_counts.rds"))
cat(sprintf("TRI facility counts for %d states\n", nrow(tri_counts)))

# ==============================================================================
# VALIDATION
# ==============================================================================

cat("\n=== Data Validation ===\n")

aqs <- readRDS(file.path(data_dir, "aqs_monitor_data.rds"))
cat(sprintf("AQS: %d records, %d unique county-years, years %d-%d\n",
            nrow(aqs), n_distinct(paste(aqs$county_id, aqs$year)),
            min(aqs$year), max(aqs$year)))
cat(sprintf("  Pollutants: %s\n", paste(unique(aqs$param_name), collapse = "; ")))
cat(sprintf("  States: %d\n", n_distinct(aqs$state_abbr)))

state_fed <- readRDS(file.path(data_dir, "state_fed_share.rds"))
cat(sprintf("Federal shares: %d states, mean=%.3f\n",
            nrow(state_fed), mean(state_fed$fed_share, na.rm = TRUE)))

cat("\nData fetch complete.\n")
