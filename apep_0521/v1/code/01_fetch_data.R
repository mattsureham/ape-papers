## ==========================================================================
## 01_fetch_data.R — Fetch all data for Constitutional Carry analysis
## Sources: CDC (multiple), FBI NICS, Census ACS, FRED
## ==========================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ==========================================================================
## PART 1: Treatment Timing
## ==========================================================================

cat("=== PART 1: Treatment timing ===\n")

treatment_df <- tibble(
  state = c("Vermont", "Alaska", "Arizona", "Wyoming", "Kansas", "Maine",
            "Idaho", "Mississippi", "West Virginia", "Missouri",
            "New Hampshire", "North Dakota", "Kentucky", "Oklahoma",
            "South Dakota", "Arkansas", "Iowa", "Montana", "Tennessee",
            "Texas", "Utah", "Alabama", "Georgia", "Indiana", "Ohio",
            "Florida", "Nebraska"),
  treat_year = c(1791, 2003, 2010, 2011, 2015, 2015,
                 2016, 2016, 2016, 2017,
                 2017, 2017, 2019, 2019,
                 2019, 2021, 2021, 2021, 2021,
                 2021, 2021, 2023, 2022, 2022, 2022,
                 2023, 2023)
)

state_fips <- tibble(
  state = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC"),
  fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,12,13,15,16,17,18,19,20,21,22,23,24,
                           25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,
                           44,45,46,47,48,49,50,51,53,54,55,56,11))
)

treatment_df <- treatment_df %>% left_join(state_fips, by = "state")
fwrite(treatment_df, file.path(data_dir, "treatment_timing.csv"))
cat("Treatment timing:", nrow(treatment_df), "states\n")

## ==========================================================================
## PART 2: CDC Leading Causes of Death (state × year)
## ==========================================================================

cat("\n=== PART 2: CDC Leading Causes ===\n")

cdc_url <- "https://data.cdc.gov/resource/bi63-dtpu.json"
all_mort <- list()

for (yr in 1999:2022) {
  cat("  CDC year", yr, "...")
  resp <- tryCatch(
    GET(paste0(cdc_url, "?year=", yr, "&$limit=5000"),
        add_headers("Accept" = "application/json"), timeout(15)),
    error = function(e) { message(e$message); NULL }
  )
  if (!is.null(resp) && status_code(resp) == 200) {
    txt <- content(resp, "text", encoding = "UTF-8")
    data <- tryCatch(fromJSON(txt), error = function(e) data.frame())
    if (is.data.frame(data) && nrow(data) > 0) {
      all_mort[[as.character(yr)]] <- data
      cat("OK (", nrow(data), ")\n")
    } else { cat("empty\n") }
  } else { cat("fail\n") }
  Sys.sleep(0.25)
}

if (length(all_mort) > 0) {
  cdc_leading <- bind_rows(all_mort) %>% clean_names()
  fwrite(cdc_leading, file.path(data_dir, "cdc_leading_causes.csv"))
  cat("CDC Leading Causes:", nrow(cdc_leading), "rows,",
      n_distinct(cdc_leading$year), "years\n")
} else {
  cat("WARNING: CDC leading causes dataset unavailable.\n")
}

## ==========================================================================
## PART 3: CDC Injury Mortality (state × year × mechanism)
## ==========================================================================

cat("\n=== PART 3: CDC Injury Mortality ===\n")

injury_url <- "https://data.cdc.gov/resource/nt65-c7a7.json"
all_injury <- list()
offset <- 0

repeat {
  cat("  Injury mortality offset", offset, "...")
  resp <- tryCatch(
    GET(paste0(injury_url, "?$limit=50000&$offset=", offset),
        add_headers("Accept" = "application/json"), timeout(30)),
    error = function(e) NULL
  )
  if (is.null(resp) || status_code(resp) != 200) { cat("fail\n"); break }
  txt <- content(resp, "text", encoding = "UTF-8")
  data <- tryCatch(fromJSON(txt), error = function(e) data.frame())
  if (!is.data.frame(data) || nrow(data) == 0) { cat("done\n"); break }
  all_injury[[length(all_injury) + 1]] <- data
  cat("OK (", nrow(data), ")\n")
  offset <- offset + 50000
  if (nrow(data) < 50000) break
  Sys.sleep(0.5)
}

if (length(all_injury) > 0) {
  cdc_injury <- bind_rows(all_injury) %>% clean_names()
  fwrite(cdc_injury, file.path(data_dir, "cdc_injury_mortality.csv"))
  cat("CDC Injury Mortality:", nrow(cdc_injury), "rows\n")
}

## ==========================================================================
## PART 4: CDC Firearm Mortality (Stats of the States)
## ==========================================================================

cat("\n=== PART 4: CDC Firearm Mortality ===\n")

firearm_url <- "https://data.cdc.gov/resource/489q-934x.json"
resp <- tryCatch(
  GET(paste0(firearm_url, "?$limit=50000"),
      add_headers("Accept" = "application/json"), timeout(30)),
  error = function(e) NULL
)

if (!is.null(resp) && status_code(resp) == 200) {
  txt <- content(resp, "text", encoding = "UTF-8")
  data <- tryCatch(fromJSON(txt), error = function(e) data.frame())
  if (is.data.frame(data) && nrow(data) > 0) {
    cdc_firearm <- clean_names(data)
    fwrite(cdc_firearm, file.path(data_dir, "cdc_firearm_mortality.csv"))
    cat("CDC Firearm Mortality:", nrow(cdc_firearm), "rows\n")
  } else { cat("Empty response\n") }
} else { cat("Failed or unavailable\n") }

## ==========================================================================
## PART 4b: CDC Mapping Violence (State-Level Firearm by Intent)
## ==========================================================================

cat("\n=== PART 4b: CDC Mapping Violence ===\n")

violence_url <- "https://data.cdc.gov/resource/fpsi-y8tj.json"
all_violence <- list()
offset <- 0

repeat {
  resp <- tryCatch(
    GET(paste0(violence_url, "?$limit=50000&$offset=", offset),
        add_headers("Accept" = "application/json"), timeout(30)),
    error = function(e) NULL
  )
  if (is.null(resp) || status_code(resp) != 200) break
  txt <- content(resp, "text", encoding = "UTF-8")
  batch <- tryCatch(fromJSON(txt), error = function(e) data.frame())
  if (!is.data.frame(batch) || nrow(batch) == 0) break
  all_violence <- c(all_violence, list(batch))
  offset <- offset + 50000
  if (nrow(batch) < 50000) break
}

if (length(all_violence) > 0) {
  cdc_violence <- bind_rows(all_violence) %>% clean_names()
  fwrite(cdc_violence, file.path(data_dir, "cdc_state_violence.csv"))
  cat("CDC Mapping Violence:", nrow(cdc_violence), "rows\n")
} else {
  stop("CDC Mapping Violence data unavailable. Required for Panel B.")
}

## ==========================================================================
## PART 5: FBI NICS Background Checks
## ==========================================================================

cat("\n=== PART 5: FBI NICS ===\n")

nics_url <- "https://raw.githubusercontent.com/BuzzFeedNews/nics-firearm-background-checks/master/data/nics-firearm-background-checks.csv"
nics_file <- file.path(data_dir, "nics_checks.csv")

tryCatch({
  download.file(nics_url, nics_file, mode = "wb", quiet = TRUE)
  nics <- fread(nics_file)
  cat("NICS:", nrow(nics), "rows,", n_distinct(nics$state), "states,",
      min(nics$month), "to", max(nics$month), "\n")
}, error = function(e) {
  stop("NICS download failed: ", e$message,
       "\nRequired for first-stage analysis. Pivot or fix source.")
})

## ==========================================================================
## PART 6: Census ACS Covariates
## ==========================================================================

cat("\n=== PART 6: Census ACS ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") {
  cat("CENSUS_API_KEY not set, proceeding without key (rate-limited)\n")
  key_param <- ""
} else {
  key_param <- paste0("&key=", census_key)
}

acs_list <- list()
for (yr in 2009:2023) {
  cat("  ACS", yr, "...")
  vars <- "NAME,B01003_001E,B19013_001E,B17001_002E,B02001_003E"
  url <- paste0("https://api.census.gov/data/", yr, "/acs/acs5?get=",
                vars, "&for=state:*", key_param)
  resp <- tryCatch(GET(url, timeout(20)), error = function(e) NULL)

  if (!is.null(resp) && status_code(resp) == 200) {
    raw <- tryCatch(fromJSON(content(resp, "text", encoding = "UTF-8")),
                    error = function(e) NULL)
    if (!is.null(raw) && is.matrix(raw) && nrow(raw) > 1) {
      df <- as_tibble(raw[-1, ], .name_repair = "minimal")
      colnames(df) <- raw[1, ]
      df$year <- yr
      acs_list[[as.character(yr)]] <- df
      cat("OK\n")
    } else { cat("parse fail\n") }
  } else { cat("fail\n") }
  Sys.sleep(0.3)
}

if (length(acs_list) > 0) {
  acs_data <- bind_rows(acs_list) %>%
    clean_names() %>%
    mutate(across(c(b01003_001e, b19013_001e, b17001_002e, b02001_003e),
                  as.numeric))
  fwrite(acs_data, file.path(data_dir, "acs_covariates.csv"))
  cat("ACS:", nrow(acs_data), "rows,", n_distinct(acs_data$state), "states\n")
} else {
  stop("ACS data fetch returned no data. Cannot proceed.")
}

## ==========================================================================
## PART 7: FRED Unemployment Rates
## ==========================================================================

cat("\n=== PART 7: FRED ===\n")

fred_key <- Sys.getenv("FRED_API_KEY")
if (fred_key == "") {
  cat("FRED_API_KEY not set, skipping\n")
} else {
  fred_list <- list()
  for (st in state_fips$state_abbr) {
    series_id <- paste0(st, "UR")
    url <- paste0("https://api.stlouisfed.org/fred/series/observations?",
                  "series_id=", series_id,
                  "&api_key=", fred_key,
                  "&file_type=json",
                  "&observation_start=2000-01-01&frequency=a")
    resp <- tryCatch(GET(url, timeout(10)), error = function(e) NULL)
    if (!is.null(resp) && status_code(resp) == 200) {
      data <- tryCatch(fromJSON(content(resp, "text", encoding = "UTF-8")),
                       error = function(e) NULL)
      if (!is.null(data$observations) && nrow(data$observations) > 0) {
        fred_list[[st]] <- data$observations %>% mutate(state_abbr = st)
      }
    }
    Sys.sleep(0.08)
  }
  if (length(fred_list) > 0) {
    fred_unemp <- bind_rows(fred_list) %>%
      clean_names() %>%
      mutate(year = as.integer(substr(date, 1, 4)),
             unemp_rate = as.numeric(value)) %>%
      select(state_abbr, year, unemp_rate)
    fwrite(fred_unemp, file.path(data_dir, "fred_unemployment.csv"))
    cat("FRED unemployment:", nrow(fred_unemp), "state-years\n")
  }
}

## ==========================================================================
## VALIDATION
## ==========================================================================

cat("\n=== VALIDATION ===\n")
files <- list.files(data_dir, pattern = "\\.csv$")
for (f in files) {
  sz <- file.info(file.path(data_dir, f))$size
  cat(sprintf("  %-40s %s bytes\n", f, format(sz, big.mark = ",")))
}

stopifnot("Treatment timing" = file.exists(file.path(data_dir, "treatment_timing.csv")))
stopifnot("NICS data" = file.exists(file.path(data_dir, "nics_checks.csv")))
stopifnot("ACS covariates" = file.exists(file.path(data_dir, "acs_covariates.csv")))

# Check we have at least one CDC mortality source
cdc_files <- files[grepl("cdc_", files)]
stopifnot("At least one CDC mortality dataset" = length(cdc_files) >= 1)

cat("\nData fetch PASSED. ", length(files), "files created.\n")
