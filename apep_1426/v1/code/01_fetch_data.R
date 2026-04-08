# 01_fetch_data.R — Data acquisition for apep_1426
# TV News Amplification and Workplace Safety Deterrence

source("./code/00_packages.R")

DATA_DIR <- "./data"

# ============================================================
# 1. OSHA INSPECTION DATA via DOL API v2
# ============================================================
cat("=== Fetching OSHA inspection data via DOL API ===\n")

insp_file <- file.path(DATA_DIR, "osha_inspections.csv")

if (!file.exists(insp_file)) {
  # DOL API v2: paginated JSON endpoint
  # https://developer.dol.gov/beginners-guide/
  # OSHA enforcement data available via the enforcement API

  # The actual bulk data is at enforcedata.dol.gov/views/data_catalogs
  # But it requires JavaScript rendering. Use the API instead.

  # DOL API v2 base URL for OSHA inspections
  base_url <- "https://enforcedata.dol.gov/api/enforcement/osha_inspection"

  cat("Trying DOL Enforcement API...\n")

  # Test API access
  test_url <- paste0(base_url, "?limit=10&offset=0")
  test_resp <- tryCatch({
    httr::GET(test_url, httr::timeout(30),
              httr::add_headers("X-API-KEY" = Sys.getenv("DOL_API_KEY", "")))
  }, error = function(e) {
    cat(sprintf("  API error: %s\n", e$message))
    NULL
  })

  if (!is.null(test_resp) && httr::status_code(test_resp) == 200) {
    cat("  DOL API accessible. Downloading paginated data...\n")

    all_data <- list()
    offset <- 0
    page_size <- 1000
    max_records <- 2000000  # ~2M inspections expected

    while (offset < max_records) {
      url <- sprintf("%s?limit=%d&offset=%d", base_url, page_size, offset)
      resp <- httr::GET(url, httr::timeout(60),
                        httr::add_headers("X-API-KEY" = Sys.getenv("DOL_API_KEY", "")))

      if (httr::status_code(resp) != 200) break

      content <- httr::content(resp, as = "text", encoding = "UTF-8")
      page <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)

      if (is.null(page) || length(page) == 0) break
      if (is.data.frame(page)) {
        all_data[[length(all_data) + 1]] <- page
        if (nrow(page) < page_size) break
      } else if (!is.null(page$results)) {
        all_data[[length(all_data) + 1]] <- page$results
        if (nrow(page$results) < page_size) break
      } else {
        break
      }

      offset <- offset + page_size
      if (offset %% 50000 == 0) cat(sprintf("  Downloaded %d records...\n", offset))
      Sys.sleep(0.2)
    }

    if (length(all_data) > 0) {
      insp_dt <- rbindlist(all_data, fill = TRUE)
      fwrite(insp_dt, insp_file)
      cat(sprintf("  OSHA inspections saved: %d rows.\n", nrow(insp_dt)))
    }
  }

  # Fallback: try direct CSV download from alternative sources
  if (!file.exists(insp_file)) {
    cat("  DOL API didn't work. Trying OSHA data from data.gov...\n")

    # data.gov hosts OSHA datasets
    datagov_urls <- c(
      "https://data.bls.gov/gqt/RequestData",
      "https://download.bls.gov/pub/time.series/ii/ii.data.1.AllData"
    )

    # Use the BLS Injuries, Illnesses, and Fatalities (IIF) data instead
    # This is state-year level injury/illness rates - suitable for our analysis
    cat("  Downloading BLS Injury/Illness data (IIF series)...\n")

    iif_url <- "https://download.bls.gov/pub/time.series/ii/ii.data.1.AllData"
    iif_file <- file.path(DATA_DIR, "bls_iif_data.txt")

    dl_success <- tryCatch({
      download.file(iif_url, iif_file, quiet = FALSE)
      TRUE
    }, error = function(e) {
      cat(sprintf("  BLS IIF download failed: %s\n", e$message))
      FALSE
    })

    if (dl_success && file.exists(iif_file)) {
      iif_dt <- fread(iif_file)
      cat(sprintf("  BLS IIF data: %d rows.\n", nrow(iif_dt)))
    }

    # Also try the OSHA ITA (Injury Tracking Application) data
    cat("  Downloading OSHA ITA 300A establishment data...\n")

    # The ITA data is available year-by-year
    ita_years <- 2016:2023
    ita_list <- list()

    for (yr in ita_years) {
      ita_url <- sprintf(
        "https://www.osha.gov/Establishment-Specific-Injury-and-Illness-Data/api/v1/establishments?year=%d&limit=50000&offset=0",
        yr
      )

      resp <- tryCatch({
        httr::GET(ita_url, httr::timeout(60))
      }, error = function(e) NULL)

      if (!is.null(resp) && httr::status_code(resp) == 200) {
        content <- httr::content(resp, as = "text", encoding = "UTF-8")
        parsed <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
        if (!is.null(parsed) && is.data.frame(parsed)) {
          ita_list[[as.character(yr)]] <- parsed
          cat(sprintf("  ITA %d: %d establishments.\n", yr, nrow(parsed)))
        }
      }
      Sys.sleep(1)
    }

    if (length(ita_list) > 0) {
      ita_dt <- rbindlist(ita_list, fill = TRUE)
      fwrite(ita_dt, file.path(DATA_DIR, "osha_ita_300a.csv"))
      cat(sprintf("  OSHA ITA 300A saved: %d rows.\n", nrow(ita_dt)))
    }
  }
}

# If we still don't have OSHA data, use the Python-accessible API
if (!file.exists(insp_file) && !file.exists(file.path(DATA_DIR, "bls_iif_data.txt"))) {
  cat("\n  Last resort: fetching via Python script...\n")
  system2("python3", c("-c", shQuote(paste0(
    "import urllib.request, json, csv, os\n",
    "url = 'https://enforcedata.dol.gov/api/enforcement/osha_inspection?limit=100&offset=0'\n",
    "try:\n",
    "    req = urllib.request.Request(url)\n",
    "    with urllib.request.urlopen(req, timeout=30) as resp:\n",
    "        data = json.loads(resp.read())\n",
    "        print(f'API returned {type(data)} with {len(data) if isinstance(data, list) else \"unknown\"} items')\n",
    "        if isinstance(data, list) and len(data) > 0:\n",
    "            print(f'Keys: {list(data[0].keys())[:10]}')\n",
    "except Exception as e:\n",
    "    print(f'Error: {e}')\n"
  ))), stdout = "", stderr = "")
}

# ============================================================
# 2. GDELT BigQuery — Competing-News Instrument + TV Safety Coverage
# ============================================================
cat("\n=== Querying GDELT BigQuery ===\n")

gdelt_file <- file.path(DATA_DIR, "gdelt_weekly_news.csv")
tv_safety_file <- file.path(DATA_DIR, "gdelt_tv_safety.csv")

if (!file.exists(gdelt_file) || !file.exists(tv_safety_file)) {
  bq_auth(path = "~/.config/gcloud/application_default_credentials.json")
  project_id <- "scl-librechat"

  if (!file.exists(gdelt_file)) {
    # Query 1: Weekly competing-news instrument
    cat("  Running competing-news query...\n")
    query1 <- "
    SELECT
      DATE_TRUNC(DATE(_PARTITIONTIME), WEEK(MONDAY)) AS week,
      COUNT(*) AS total_articles,
      COUNTIF(
        STRPOS(Themes, 'SAFETY') > 0
        OR STRPOS(Themes, 'WB_2961_OCCUPATIONAL_HEALTH_AND_SAFETY') > 0
      ) AS safety_articles,
      COUNTIF(
        STRPOS(Themes, 'SPORTS_OLYMPICS') > 0
        OR STRPOS(Themes, 'SPORTS_SUPERBOWL') > 0
        OR STRPOS(Themes, 'WORLD_CUP') > 0
      ) AS sports_mega_articles,
      COUNTIF(
        STRPOS(Themes, 'ELECTION') > 0
        OR STRPOS(Themes, 'IMPEACH') > 0
      ) AS political_mega_articles,
      COUNTIF(
        STRPOS(Themes, 'SPORTS_OLYMPICS') > 0
      ) AS olympics_articles,
      COUNTIF(
        STRPOS(Themes, 'SPORTS_SUPERBOWL') > 0
      ) AS superbowl_articles,
      COUNTIF(
        STRPOS(Themes, 'IMPEACH') > 0
      ) AS impeach_articles,
      COUNTIF(
        STRPOS(Themes, 'ELECTION') > 0
      ) AS election_articles,
      COUNTIF(
        STRPOS(Themes, 'DISASTER') > 0
        OR STRPOS(Themes, 'NATURAL_DISASTER') > 0
      ) AS disaster_articles
    FROM `gdelt-bq.gdeltv2.gkg_partitioned`
    WHERE _PARTITIONTIME BETWEEN '2009-01-01' AND '2024-01-01'
    GROUP BY week
    HAVING week IS NOT NULL
    ORDER BY week
    "

    result1 <- bq_project_query(project_id, query1)
    gdelt_dt <- as.data.table(bq_table_download(result1))
    fwrite(gdelt_dt, gdelt_file)
    cat(sprintf("  Competing-news data: %d weeks.\n", nrow(gdelt_dt)))
  }

  if (!file.exists(tv_safety_file)) {
    # Query 2: TV-source safety articles with state geography
    cat("  Running TV safety coverage query...\n")
    query2 <- "
    SELECT
      DATE_TRUNC(DATE(_PARTITIONTIME), WEEK(MONDAY)) AS week,
      -- Extract US state from Locations (format: type#name#countrycode#adm1code#lat#lon#featureID)
      REGEXP_EXTRACT(Locations, r'#US\\.([A-Z]{2})#') AS state_code,
      SourceCommonName AS source,
      COUNT(*) AS safety_segments,
      AVG(CAST(SPLIT(Tone, ',')[OFFSET(0)] AS FLOAT64)) AS avg_tone,
      AVG(CAST(SPLIT(Tone, ',')[SAFE_OFFSET(1)] AS FLOAT64)) AS avg_positive_tone,
      AVG(CAST(SPLIT(Tone, ',')[SAFE_OFFSET(2)] AS FLOAT64)) AS avg_negative_tone
    FROM `gdelt-bq.gdeltv2.gkg_partitioned`
    WHERE _PARTITIONTIME BETWEEN '2009-01-01' AND '2024-01-01'
      AND (
        STRPOS(Themes, 'SAFETY') > 0
        OR STRPOS(Themes, 'WB_2961_OCCUPATIONAL_HEALTH_AND_SAFETY') > 0
        OR STRPOS(LOWER(Themes), 'osha') > 0
      )
      AND (
        -- TV news sources (identified by SourceCommonName patterns)
        LOWER(SourceCommonName) LIKE '%cnn%'
        OR LOWER(SourceCommonName) LIKE '%fox%news%'
        OR LOWER(SourceCommonName) LIKE '%msnbc%'
        OR LOWER(SourceCommonName) LIKE '%nbc%news%'
        OR LOWER(SourceCommonName) LIKE '%abc%news%'
        OR LOWER(SourceCommonName) LIKE '%cbs%news%'
        OR LOWER(SourceCommonName) LIKE '%local%tv%'
        OR LOWER(SourceCommonName) LIKE '%television%'
      )
    GROUP BY week, state_code, source
    ORDER BY week
    "

    result2 <- bq_project_query(project_id, query2)
    tv_dt <- as.data.table(bq_table_download(result2))
    fwrite(tv_dt, tv_safety_file)
    cat(sprintf("  TV safety coverage: %d rows.\n", nrow(tv_dt)))
  }
}

# ============================================================
# 3. BLS Injury/Illness Rates (state-year level)
# ============================================================
cat("\n=== Fetching BLS injury/illness data ===\n")

iif_file <- file.path(DATA_DIR, "bls_iif_data.txt")

if (!file.exists(iif_file)) {
  cat("  Downloading BLS IIF series data...\n")

  # BLS publishes flat files for the Survey of Occupational Injuries and Illnesses
  # Series IIU: Industry injury rates by year
  # Series ISU: State injury rates by year

  # Try state-level data first
  state_url <- "https://download.bls.gov/pub/time.series/ii/ii.data.1.AllData"

  dl_ok <- tryCatch({
    download.file(state_url, iif_file, quiet = FALSE)
    TRUE
  }, error = function(e) {
    cat(sprintf("  Download failed: %s\n", e$message))
    FALSE
  })

  if (dl_ok) {
    iif_dt <- fread(iif_file)
    cat(sprintf("  BLS IIF data: %d rows.\n", nrow(iif_dt)))
  }

  # Also get the series definitions
  series_url <- "https://download.bls.gov/pub/time.series/ii/ii.series"
  series_file <- file.path(DATA_DIR, "bls_iif_series.txt")
  tryCatch({
    download.file(series_url, series_file, quiet = TRUE)
    cat("  Series definitions downloaded.\n")
  }, error = function(e) {
    cat(sprintf("  Series file failed: %s\n", e$message))
  })
}

# ============================================================
# 4. State FIPS and Crosswalk Data
# ============================================================
cat("\n=== Creating state-level crosswalk ===\n")

state_file <- file.path(DATA_DIR, "state_crosswalk.csv")

if (!file.exists(state_file)) {
  # Create a state crosswalk directly
  states <- data.table(
    state_fips = c("01","02","04","05","06","08","09","10","11","12",
                   "13","15","16","17","18","19","20","21","22","23",
                   "24","25","26","27","28","29","30","31","32","33",
                   "34","35","36","37","38","39","40","41","42","44",
                   "45","46","47","48","49","50","51","53","54","55","56"),
    state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                   "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                   "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                   "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                   "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
    state_name = c("Alabama","Alaska","Arizona","Arkansas","California",
                   "Colorado","Connecticut","Delaware","District of Columbia","Florida",
                   "Georgia","Hawaii","Idaho","Illinois","Indiana",
                   "Iowa","Kansas","Kentucky","Louisiana","Maine",
                   "Maryland","Massachusetts","Michigan","Minnesota","Mississippi",
                   "Missouri","Montana","Nebraska","Nevada","New Hampshire",
                   "New Jersey","New Mexico","New York","North Carolina","North Dakota",
                   "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                   "South Carolina","South Dakota","Tennessee","Texas","Utah",
                   "Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming")
  )
  fwrite(states, state_file)
  cat(sprintf("  State crosswalk: %d states.\n", nrow(states)))
}

# ============================================================
# VALIDATION SUMMARY
# ============================================================
cat("\n=== Data Fetch Summary ===\n")
files <- list.files(DATA_DIR, full.names = TRUE)
for (f in files) {
  sz <- file.info(f)$size
  cat(sprintf("  %s: %.1f MB\n", basename(f), sz / 1e6))
}

# Check we have minimum required data
has_gdelt <- file.exists(gdelt_file)
has_tv <- file.exists(tv_safety_file)
has_iif <- file.exists(iif_file)

cat(sprintf("\nData availability:\n"))
cat(sprintf("  GDELT competing-news: %s\n", ifelse(has_gdelt, "YES", "NO")))
cat(sprintf("  GDELT TV safety:      %s\n", ifelse(has_tv, "YES", "NO")))
cat(sprintf("  BLS IIF data:         %s\n", ifelse(has_iif, "YES", "NO")))

if (!has_gdelt || !has_tv) {
  stop("FATAL: Missing critical data (GDELT). Cannot proceed.")
}

cat("\nData fetch complete.\n")
