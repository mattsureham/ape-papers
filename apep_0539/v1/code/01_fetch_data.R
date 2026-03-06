## 01_fetch_data.R — Download all data sources
## APEP Paper apep_0539: Less Cash, Less Crime?

source("00_packages.R")
library(rvest)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# 1. FBI UCR State-Level Crime Data (from Disaster Center compilation)
# ===========================================================================
cat("=== Scraping FBI UCR state-level crime data ===\n")
cat("Source: Disaster Center (compiled from FBI UCR)\n")

state_info <- data.frame(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                  "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                  "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                  "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                  "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  url_code = c("al","ak","az","ar","ca","co","ct","de","dc","fl",
               "ga","hi","id","il","in","ia","ks","ky","la","me",
               "md","ma","mi","mn","ms","mo","mt","ne","nv","nh",
               "nj","nm","ny","nc","nd","oh","ok","or","pa","ri",
               "sc","sd","tn","tx","ut","vt","va","wa","wv","wi","wy"),
  stringsAsFactors = FALSE
)

scrape_state_crime <- function(abbr, url_code) {
  url <- paste0("https://www.disastercenter.com/crime/", url_code, "crime.htm")

  tryCatch({
    page <- read_html(url)
    tables <- html_table(page, fill = TRUE)

    # Find the counts table (Table 5) and rates table (Table 8)
    # They have 12 columns and 60+ rows, with "Year" in the header
    count_tbl <- NULL
    rate_tbl <- NULL

    for (tbl in tables) {
      if (ncol(tbl) == 12 && nrow(tbl) >= 50) {
        # Check second row for "Year" header
        if (any(grepl("Year", as.character(tbl[2, ]), ignore.case = TRUE))) {
          if (is.null(count_tbl)) {
            count_tbl <- tbl
          } else if (is.null(rate_tbl)) {
            rate_tbl <- tbl
          }
        }
      }
    }

    if (is.null(count_tbl)) {
      cat("  WARNING: No crime table found for", abbr, "\n")
      return(NULL)
    }

    # Parse counts table: skip first 2 header rows
    col_names <- c("year", "population", "index_total", "violent_crime",
                   "property_crime", "murder", "rape", "robbery",
                   "aggravated_assault", "burglary", "larceny", "motor_vehicle_theft")

    df <- count_tbl[3:nrow(count_tbl), ]
    names(df) <- col_names

    # Clean: remove commas, convert to numeric
    df <- df %>%
      mutate(across(everything(), ~gsub(",", "", as.character(.)))) %>%
      mutate(across(everything(), ~suppressWarnings(as.numeric(.)))) %>%
      filter(!is.na(year), year >= 1960, year <= 2022) %>%
      mutate(state_abbr = abbr)

    # Also parse rates if available
    if (!is.null(rate_tbl)) {
      rate_df <- rate_tbl[3:nrow(rate_tbl), ]
      names(rate_df) <- paste0(col_names, "_rate")
      names(rate_df)[1] <- "year_check"

      rate_df <- rate_df %>%
        mutate(across(everything(), ~gsub(",", "", as.character(.)))) %>%
        mutate(across(everything(), ~suppressWarnings(as.numeric(.)))) %>%
        filter(!is.na(year_check), year_check >= 1960)

      # Add rate columns to df
      if (nrow(rate_df) == nrow(df)) {
        df$property_crime_rate <- rate_df$property_crime_rate
        df$burglary_rate <- rate_df$burglary_rate
        df$larceny_rate <- rate_df$larceny_rate
        df$robbery_rate <- rate_df$robbery_rate
        df$motor_vehicle_theft_rate <- rate_df$motor_vehicle_theft_rate
        df$violent_crime_rate <- rate_df$violent_crime_rate
        df$murder_rate <- rate_df$murder_rate
      }
    }

    Sys.sleep(0.3)
    return(df)
  }, error = function(e) {
    cat("  FAILED:", abbr, "-", e$message, "\n")
    return(NULL)
  })
}

crime_list <- list()
for (i in seq_len(nrow(state_info))) {
  cat("  [", i, "/", nrow(state_info), "]", state_info$state_abbr[i], "... ")
  result <- scrape_state_crime(state_info$state_abbr[i], state_info$url_code[i])
  if (!is.null(result)) {
    crime_list[[state_info$state_abbr[i]]] <- result
    cat(nrow(result), "years\n")
  } else {
    cat("FAILED\n")
  }
}

ucr <- bind_rows(crime_list)
fwrite(ucr, file.path(data_dir, "ucr_state_crime.csv"))
cat("\nUCR data:", nrow(ucr), "obs,", n_distinct(ucr$state_abbr), "states,",
    min(ucr$year), "-", max(ucr$year), "\n")

# ===========================================================================
# 2. USDA ERS SNAP Policy Database (EBT adoption dates)
# ===========================================================================
cat("\n=== Downloading USDA ERS SNAP Policy Database ===\n")

snap_url <- "https://www.ers.usda.gov/media/6472/snap-policy-database.xlsx"
snap_file <- file.path(data_dir, "snap_policy_database.xlsx")

tryCatch({
  download.file(snap_url, snap_file, mode = "wb", quiet = FALSE)
}, error = function(e) {
  stop("SNAP Policy Database download failed: ", e$message)
})

# The data is in the second sheet ("SNAP Policy Database")
snap_sheets <- excel_sheets(snap_file)
cat("Sheets:", paste(snap_sheets, collapse = ", "), "\n")

snap_raw <- read_excel(snap_file, sheet = "SNAP Policy Database")
cat("SNAP Policy Database:", nrow(snap_raw), "rows,", ncol(snap_raw), "cols\n")
cat("Columns include:", paste(head(names(snap_raw), 20), collapse = ", "), "\n")

# Check for EBT-related columns
ebt_cols <- names(snap_raw)[grepl("ebt|EBT", names(snap_raw), ignore.case = TRUE)]
cat("EBT columns:", paste(ebt_cols, collapse = ", "), "\n")

# Save raw SNAP data as CSV for easier processing
fwrite(as.data.table(snap_raw), file.path(data_dir, "snap_policy_raw.csv"))

# ===========================================================================
# 3. BLS LAUS — State Unemployment Rates
# ===========================================================================
cat("\n=== Fetching BLS LAUS unemployment data ===\n")

# BLS blocks direct downloads; use the BLS API instead
bls_base <- "https://api.bls.gov/publicAPI/v2/timeseries/data/"

# LAUS series: LASST{FIPS}0000000003 = unemployment rate for state
state_fips_map <- data.frame(
  state_abbr = state_info$state_abbr,
  fips = c("01","02","04","05","06","08","09","10","11","12",
           "13","15","16","17","18","19","20","21","22","23",
           "24","25","26","27","28","29","30","31","32","33",
           "34","35","36","37","38","39","40","41","42","44",
           "45","46","47","48","49","50","51","53","54","55","56"),
  stringsAsFactors = FALSE
)

# BLS public API (no key needed, but limited to 25 series per request)
# Fetch annual average unemployment rates
unemp_list <- list()
batch_size <- 20
fips_batches <- split(state_fips_map, ceiling(seq_len(nrow(state_fips_map)) / batch_size))

for (batch in fips_batches) {
  series_ids <- paste0("LASST", batch$fips, "0000000003")

  body <- list(
    seriesid = series_ids,
    startyear = "1990",
    endyear = "2010"
  )

  tryCatch({
    resp <- POST(bls_base, body = toJSON(body, auto_unbox = TRUE),
                 content_type("application/json"))

    if (status_code(resp) == 200) {
      data <- content(resp, "text", encoding = "UTF-8") %>% fromJSON()
      if (data$status == "REQUEST_SUCCEEDED") {
        for (series in data$Results$series) {
          sid <- series$seriesID
          fips_code <- substr(sid, 6, 7)
          st <- batch$state_abbr[batch$fips == fips_code]
          if (length(st) == 1 && !is.null(series$data) && is.data.frame(series$data)) {
            df <- series$data %>%
              filter(period == "M13") %>%  # M13 = annual average
              mutate(state_abbr = st,
                     year = as.integer(year),
                     unemployment_rate = as.numeric(value)) %>%
              select(state_abbr, year, unemployment_rate)
            unemp_list[[st]] <- df
          }
        }
      }
    }
    Sys.sleep(1)  # BLS rate limit
  }, error = function(e) {
    cat("  BLS batch failed:", e$message, "\n")
  })
}

if (length(unemp_list) > 0) {
  unemp <- bind_rows(unemp_list)
  fwrite(unemp, file.path(data_dir, "bls_unemployment.csv"))
  cat("BLS unemployment:", nrow(unemp), "obs,", n_distinct(unemp$state_abbr), "states\n")
} else {
  cat("Warning: No BLS unemployment data fetched.\n")
}

# ===========================================================================
# 4. Census Population Data
# ===========================================================================
cat("\n=== Fetching Census population data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") census_key <- Sys.getenv("CENSUS_KEY")

# 2000 Decennial
tryCatch({
  url_2000 <- paste0("https://api.census.gov/data/2000/dec/sf1?get=P001001,NAME&for=state:*",
                     ifelse(census_key != "", paste0("&key=", census_key), ""))
  d <- content(GET(url_2000), "text", encoding = "UTF-8") %>% fromJSON()
  pop_2000 <- as.data.frame(d[-1, ], stringsAsFactors = FALSE)
  names(pop_2000) <- d[1, ]
  pop_2000$year <- 2000
  pop_2000$population <- as.numeric(pop_2000$P001001)
  fwrite(pop_2000, file.path(data_dir, "census_pop_2000.csv"))
  cat("Census 2000:", nrow(pop_2000), "states\n")
}, error = function(e) cat("Census 2000 failed:", e$message, "\n"))

# 2010 Decennial
tryCatch({
  url_2010 <- paste0("https://api.census.gov/data/2010/dec/sf1?get=P001001,NAME&for=state:*",
                     ifelse(census_key != "", paste0("&key=", census_key), ""))
  d <- content(GET(url_2010), "text", encoding = "UTF-8") %>% fromJSON()
  pop_2010 <- as.data.frame(d[-1, ], stringsAsFactors = FALSE)
  names(pop_2010) <- d[1, ]
  pop_2010$year <- 2010
  pop_2010$population <- as.numeric(pop_2010$P001001)
  fwrite(pop_2010, file.path(data_dir, "census_pop_2010.csv"))
  cat("Census 2010:", nrow(pop_2010), "states\n")
}, error = function(e) cat("Census 2010 failed:", e$message, "\n"))

# ===========================================================================
# === DATA VALIDATION (required) ===
# ===========================================================================
cat("\n=== Data Validation ===\n")

ucr <- fread(file.path(data_dir, "ucr_state_crime.csv"))
stopifnot("UCR must have 40+ state units" = n_distinct(ucr$state_abbr) >= 40)
stopifnot("UCR must span analysis period" = min(ucr$year) <= 1990 & max(ucr$year) >= 2010)
stopifnot("UCR must have crime columns" = all(c("burglary", "robbery", "larceny",
                                                  "property_crime", "motor_vehicle_theft")
                                                %in% names(ucr)))
cat("UCR PASSED:", nrow(ucr), "obs,", n_distinct(ucr$state_abbr), "states,",
    min(ucr$year), "-", max(ucr$year), "\n")

snap <- fread(file.path(data_dir, "snap_policy_raw.csv"))
stopifnot("SNAP must have data" = nrow(snap) > 500)
cat("SNAP PASSED:", nrow(snap), "rows\n")

cat("\n=== All data downloads complete ===\n")
