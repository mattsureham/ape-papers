# 01_fetch_data.R — Fetch CMS telehealth, ACS broadband, preemption law data
# apep_1202: Broadband preemption and telehealth adoption

source("00_packages.R")

cat("=== STEP 1: Compile state broadband preemption law database ===\n")

# Municipal broadband preemption laws — compiled from ILSR (muninetworks.org),
# BroadbandNow, and state legislative records.
# Year = year law enacted. All enacted before COVID (2020).
preemption_laws <- data.table(
  state_abbr = c("AL", "AR", "CO", "FL", "IN", "IA", "LA", "MI",
                 "MN", "MO", "MT", "NE", "NV", "NC", "PA", "SC",
                 "TN", "TX", "UT", "VA", "WA", "WI"),
  preemption_year = c(2006, 2011, 2005, 2005, 2019, 2007, 2004, 2002,
                      2003, 1997, 2007, 1997, 2003, 2011, 2004, 2012,
                      1999, 1997, 2001, 2003, 1997, 2004),
  preemption = 1L
)

# State FIPS crosswalk (all 50 + DC)
state_fips <- data.table(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                 "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  state_fips = c("01","02","04","05","06","08","09","10","11","12",
                 "13","15","16","17","18","19","20","21","22","23",
                 "24","25","26","27","28","29","30","31","32","33",
                 "34","35","36","37","38","39","40","41","42","44",
                 "45","46","47","48","49","50","51","53","54","55","56"),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
                 "Connecticut","Delaware","District of Columbia","Florida","Georgia",
                 "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky",
                 "Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota",
                 "Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire",
                 "New Jersey","New Mexico","New York","North Carolina","North Dakota",
                 "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                 "South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont",
                 "Virginia","Washington","West Virginia","Wisconsin","Wyoming")
)

# Merge preemption status onto all states
states <- merge(state_fips, preemption_laws, by = "state_abbr", all.x = TRUE)
states[is.na(preemption), preemption := 0L]
states[is.na(preemption_year), preemption_year := NA_integer_]

cat(sprintf("  Preempted states: %d\n", sum(states$preemption)))
cat(sprintf("  Control states: %d\n", sum(states$preemption == 0)))
stopifnot(sum(states$preemption) == 22)

fwrite(states, "../data/state_preemption.csv")
cat("  Saved state_preemption.csv\n")

cat("\n=== STEP 2: Fetch CMS Medicare Telehealth Trends ===\n")

# CMS Medicare Telehealth Trends — Data API v2
# Dataset UUID: 939226be-b107-476e-8777-f199a840138a
# 33,712 total rows; paginate with size/offset
# Columns: Year, Quarter, Bene_Geo_Desc, Bene_RUCA_Desc, Pct_Telehealth, etc.

cms_api_base <- "https://data.cms.gov/data-api/v1/dataset/939226be-b107-476e-8777-f199a840138a/data"
page_size <- 5000
offset <- 0
all_pages <- list()

repeat {
  url <- sprintf("%s?size=%d&offset=%d", cms_api_base, page_size, offset)
  cat(sprintf("  Fetching CMS offset=%d...\n", offset))
  resp <- GET(url, timeout(120))
  if (status_code(resp) != 200) {
    stop(sprintf("FATAL: CMS API returned status %d at offset %d", status_code(resp), offset))
  }
  content_text <- content(resp, "text", encoding = "UTF-8")
  page <- fromJSON(content_text, flatten = TRUE)
  if (length(page) == 0 || (is.data.frame(page) && nrow(page) == 0)) break
  all_pages[[length(all_pages) + 1]] <- as.data.table(page)
  offset <- offset + page_size
  if (nrow(page) < page_size) break
}

telehealth_raw <- rbindlist(all_pages, fill = TRUE)
cat(sprintf("  SUCCESS: %d total rows fetched\n", nrow(telehealth_raw)))
cat(sprintf("  Columns: %s\n", paste(names(telehealth_raw), collapse = ", ")))

# Final check — if all CMS approaches fail, we STOP
if (is.null(telehealth_raw) || nrow(telehealth_raw) == 0) {
  stop("FATAL: Could not fetch CMS Medicare Telehealth data from any endpoint. Cannot proceed with simulated data.")
}

fwrite(telehealth_raw, "../data/cms_telehealth_raw.csv")
cat(sprintf("  Saved cms_telehealth_raw.csv (%d rows)\n", nrow(telehealth_raw)))

cat("\n=== STEP 3: Fetch ACS Internet Access Data (B28002) ===\n")

# Census API key from environment
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) > 0) {
  census_api_key(census_key, install = FALSE)
}

# B28002: Presence and Types of Internet Subscriptions
# B28002_001: Total households
# B28002_002: With an Internet subscription
# B28002_004: Broadband (cable, fiber, DSL)
# B28002_013: No Internet access
acs_vars <- c(
  total_hh = "B28002_001",
  internet_sub = "B28002_002",
  broadband = "B28002_004",
  no_internet = "B28002_013"
)

acs_years <- 2015:2023
acs_list <- list()

for (yr in acs_years) {
  cat(sprintf("  Fetching ACS %d...\n", yr))
  result <- tryCatch(
    get_acs(
      geography = "state",
      variables = acs_vars,
      year = yr,
      survey = "acs1",
      output = "wide"
    ),
    error = function(e) {
      cat(sprintf("    Error for %d: %s\n", yr, e$message))
      NULL
    }
  )
  if (!is.null(result)) {
    result$year <- yr
    acs_list[[as.character(yr)]] <- result
  }
}

if (length(acs_list) == 0) {
  stop("FATAL: Could not fetch any ACS data. Cannot proceed.")
}

acs_data <- rbindlist(lapply(acs_list, as.data.table), fill = TRUE)
cat(sprintf("  ACS data: %d rows across %d years\n", nrow(acs_data), length(acs_list)))

fwrite(acs_data, "../data/acs_internet.csv")
cat("  Saved acs_internet.csv\n")

cat("\n=== STEP 4: Fetch ACS demographic controls ===\n")

# Key controls: median income, % 65+, % college, % rural
demo_vars <- c(
  med_income = "B19013_001",     # Median household income
  pop_total = "B01001_001",      # Total population
  pop_65plus = "B01001_020",     # Male 65-66 (proxy, will aggregate)
  college_total = "B15003_001",  # Education total 25+
  college_ba = "B15003_022"      # Bachelor's degree
)

demo_list <- list()
for (yr in c(2015, 2017, 2019, 2021, 2023)) {
  cat(sprintf("  Fetching demographics %d...\n", yr))
  result <- tryCatch(
    get_acs(
      geography = "state",
      variables = demo_vars,
      year = yr,
      survey = "acs1",
      output = "wide"
    ),
    error = function(e) {
      cat(sprintf("    Error for %d: %s\n", yr, e$message))
      NULL
    }
  )
  if (!is.null(result)) {
    result$year <- yr
    demo_list[[as.character(yr)]] <- result
  }
}

if (length(demo_list) > 0) {
  demo_data <- rbindlist(lapply(demo_list, as.data.table), fill = TRUE)
  fwrite(demo_data, "../data/acs_demographics.csv")
  cat(sprintf("  Saved acs_demographics.csv (%d rows)\n", nrow(demo_data)))
} else {
  cat("  WARNING: No demographic data fetched.\n")
}

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("  Preemption laws: %d states coded\n", nrow(states)))
cat(sprintf("  CMS telehealth: %d rows\n", nrow(telehealth_raw)))
cat(sprintf("  ACS internet: %d rows\n", nrow(acs_data)))
cat("  All data is REAL — no simulations.\n")
