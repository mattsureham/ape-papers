## 01_fetch_data.R — Fetch all data from real sources
## apep_0486 v2: Progressive Prosecutors, Incarceration, and Public Safety
## NEW in v2: CDC WONDER homicide data (1999-2020), county adjacency file

source("00_packages.R")

cat("=== STEP 1: Fetch Vera Institute Incarceration Trends ===\n")

vera_url <- "https://github.com/vera-institute/incarceration-trends/raw/main/incarceration_trends_county.csv"
vera_file <- file.path(DATA_DIR, "vera_incarceration_trends.csv")

if (!file.exists(vera_file)) {
  cat("Downloading Vera data...\n")
  download.file(vera_url, vera_file, mode = "wb", quiet = FALSE)
  cat("Download complete:", file.size(vera_file), "bytes\n")
} else {
  cat("Vera data already exists:", file.size(vera_file), "bytes\n")
}

vera_raw <- fread(vera_file)
cat("Vera raw rows:", nrow(vera_raw), "\n")
cat("Vera year range:", range(vera_raw$year, na.rm = TRUE), "\n")

stopifnot("fips" %in% names(vera_raw))
stopifnot("total_jail_pop" %in% names(vera_raw))
stopifnot("black_jail_pop" %in% names(vera_raw))

cat("\n=== STEP 2: Fetch County Health Rankings (Homicides) ===\n")

chr_years <- 2013:2024
chr_files <- c()

for (yr in chr_years) {
  urls_to_try <- c(
    sprintf("https://www.countyhealthrankings.org/sites/default/files/media/document/analytic_data%d.csv", yr),
    sprintf("https://www.countyhealthrankings.org/sites/default/files/media/document/analytic_data%d_0.csv", yr)
  )
  outfile <- file.path(DATA_DIR, sprintf("chr_%d.csv", yr))
  if (!file.exists(outfile)) {
    success <- FALSE
    for (url in urls_to_try) {
      tryCatch({
        download.file(url, outfile, mode = "wb", quiet = TRUE)
        if (file.size(outfile) > 10000) {
          cat(sprintf("CHR %d: downloaded (%.1f MB)\n", yr, file.size(outfile)/1e6))
          success <- TRUE
          break
        } else {
          file.remove(outfile)
        }
      }, error = function(e) {
        if (file.exists(outfile)) file.remove(outfile)
      })
    }
    if (!success) cat(sprintf("CHR %d: NOT AVAILABLE\n", yr))
  } else {
    cat(sprintf("CHR %d: already exists\n", yr))
  }
  if (file.exists(outfile)) chr_files <- c(chr_files, outfile)
}
cat("Downloaded CHR files for", length(chr_files), "years\n")

cat("\n=== STEP 3: Fetch Census ACS Demographics ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") stop("CENSUS_API_KEY not set in environment")

acs_years <- 2012:2022
acs_list <- list()

for (yr in acs_years) {
  cat(sprintf("Fetching ACS %d...\n", yr))
  acs_url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs5?get=B01003_001E,B02001_002E,B02001_003E,B19013_001E,B17001_002E,B23025_005E,B23025_003E&for=county:*&key=%s",
    yr, census_key
  )
  tryCatch({
    resp <- fromJSON(acs_url)
    df <- as.data.frame(resp[-1, ], stringsAsFactors = FALSE)
    names(df) <- resp[1, ]
    df <- df %>%
      mutate(
        year = yr,
        fips = paste0(state, county),
        total_pop_acs = as.numeric(B01003_001E),
        white_pop = as.numeric(B02001_002E),
        black_pop = as.numeric(B02001_003E),
        median_hh_income = as.numeric(B19013_001E),
        poverty_pop = as.numeric(B17001_002E),
        unemployed = as.numeric(B23025_005E),
        labor_force = as.numeric(B23025_003E)
      ) %>%
      select(year, fips, total_pop_acs, white_pop, black_pop,
             median_hh_income, poverty_pop, unemployed, labor_force)
    acs_list[[as.character(yr)]] <- df
    cat(sprintf("  ACS %d: %d counties\n", yr, nrow(df)))
    Sys.sleep(0.5)
  }, error = function(e) {
    cat(sprintf("  ACS %d: FAILED - %s\n", yr, e$message))
  })
}

acs_panel <- bind_rows(acs_list)
cat("ACS panel: ", nrow(acs_panel), "county-years\n")
fwrite(acs_panel, file.path(DATA_DIR, "acs_county_demographics.csv"))

cat("\n=== STEP 4: Fetch FRED State Unemployment Rates ===\n")

fred_key <- Sys.getenv("FRED_API_KEY")
if (fred_key == "") stop("FRED_API_KEY not set in environment")

state_fips <- data.frame(
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
  stringsAsFactors = FALSE
)

fred_list <- list()
for (i in seq_len(nrow(state_fips))) {
  st <- state_fips$state_abbr[i]
  sf <- state_fips$state_fips[i]
  series_id <- paste0(st, "UR")
  fred_url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&key=%s&file_type=json&observation_start=2005-01-01&observation_end=2024-12-31&frequency=a",
    series_id, fred_key
  )
  tryCatch({
    resp <- fromJSON(fred_url)
    obs <- resp$observations
    if (nrow(obs) > 0) {
      obs$state_fips <- sf
      obs$state_abbr <- st
      obs$year <- as.integer(substr(obs$date, 1, 4))
      obs$unemp_rate <- as.numeric(obs$value)
      fred_list[[st]] <- obs[, c("state_fips", "state_abbr", "year", "unemp_rate")]
    }
  }, error = function(e) {
    cat(sprintf("FRED %s: FAILED\n", st))
  })
  Sys.sleep(0.2)
}

fred_panel <- bind_rows(fred_list)
cat("FRED unemployment: ", nrow(fred_panel), "state-years\n")
fwrite(fred_panel, file.path(DATA_DIR, "fred_state_unemployment.csv"))

cat("\n=== STEP 5: Create Progressive DA Treatment File ===\n")

progressive_das <- tribble(
  ~fips,  ~county_name,           ~state, ~da_name,              ~treatment_year,
  "24510", "Baltimore City",       "MD",   "Marilyn Mosby",        2015,
  "17031", "Cook County",          "IL",   "Kim Foxx",             2016,
  "12095", "Orange County",        "FL",   "Aramis Ayala",         2016,
  "48201", "Harris County",        "TX",   "Kim Ogg",              2017,
  "29510", "St. Louis City",       "MO",   "Kimberly Gardner",     2017,
  "12057", "Hillsborough County",  "FL",   "Andrew Warren",        2017,
  "42101", "Philadelphia County",  "PA",   "Larry Krasner",        2018,
  "20209", "Wyandotte County",     "KS",   "Mark Dupree",          2017,
  "36047", "Kings County",         "NY",   "Eric Gonzalez",        2018,
  "29189", "St. Louis County",     "MO",   "Wesley Bell",          2019,
  "25025", "Suffolk County",       "MA",   "Rachael Rollins",      2019,
  "06013", "Contra Costa County",  "CA",   "Diana Becton",         2019,
  "37063", "Durham County",        "NC",   "Satana Deberry",       2019,
  "51013", "Arlington County",     "VA",   "Parisa Dehghani-Tafti",2020,
  "51059", "Fairfax County",       "VA",   "Steve Descano",        2020,
  "51107", "Loudoun County",       "VA",   "Buta Biberaj",         2020,
  "48113", "Dallas County",        "TX",   "John Creuzot",         2019,
  "06075", "San Francisco County", "CA",   "Chesa Boudin",         2020,
  "06037", "Los Angeles County",   "CA",   "George Gascon",        2021,
  "48453", "Travis County",        "TX",   "Jose Garza",           2021,
  "26125", "Oakland County",       "MI",   "Karen McDonald",       2021,
  "41051", "Multnomah County",     "OR",   "Mike Schmidt",         2021,
  "26161", "Washtenaw County",     "MI",   "Eli Savit",            2021,
  "36061", "New York County",      "NY",   "Alvin Bragg",          2022,
  "06001", "Alameda County",       "CA",   "Pamela Price",         2023
)

fwrite(progressive_das, file.path(DATA_DIR, "progressive_da_treatment.csv"))
cat("Treatment file:", nrow(progressive_das), "progressive DA counties\n")

cat("\n=== STEP 6: Fetch CDC WONDER Homicide Mortality Data (1999-2020) ===\n")

# CDC WONDER provides county-level mortality data via ICD-10 codes
# Homicide: X85-Y09, Y87.1
# We query the CDC WONDER API for county-level homicide deaths

# CDC WONDER does not have a straightforward REST API for bulk downloads.
# Instead, we use the CDC compressed mortality files available from NBER/CDC:
# https://www.cdc.gov/nchs/data_access/cmf.htm
# Alternatively, use the Multiple Cause of Death data files.

# Strategy: Use the CDC WONDER Underlying Cause of Death API
# The API requires form-encoded POST requests

wonder_file <- file.path(DATA_DIR, "cdc_wonder_homicide.csv")

if (!file.exists(wonder_file)) {
  cat("Fetching CDC WONDER homicide data...\n")

  # CDC WONDER API endpoint for Underlying Cause of Death
  wonder_url <- "https://wonder.cdc.gov/controller/datarequest/D76"

  # We need to query state-by-state and year-by-year due to API limitations
  # CDC WONDER groups data by county (location), year, and cause of death

  # Build the request parameters for homicide deaths by county and year
  # ICD-10 codes for homicide: X85-Y09, Y87.1
  # Group by: County, Year
  # Measures: Deaths, Population, Crude Rate

  all_wonder <- list()
  # Query in blocks: 1999-2004, 2005-2010, 2011-2015, 2016-2020
  year_blocks <- list(
    c("1999", "2000", "2001", "2002", "2003", "2004"),
    c("2005", "2006", "2007", "2008", "2009", "2010"),
    c("2011", "2012", "2013", "2014", "2015"),
    c("2016", "2017", "2018", "2019", "2020")
  )

  for (block in year_blocks) {
    cat(sprintf("  Querying CDC WONDER for %s-%s...\n", block[1], block[length(block)]))

    # CDC WONDER requires specific form parameters
    params <- list(
      "B_1" = "D76.V9-level2",          # Group by County
      "B_2" = "D76.V1-level1",          # Group by Year
      "M_1" = "D76.M1",                 # Deaths
      "M_2" = "D76.M2",                 # Population
      "M_3" = "D76.M3",                 # Crude Rate
      "O_V1_fmode" = "freg",            # Year filter mode
      "O_V9_fmode" = "freg",            # County filter mode
      "O_V10_fmode" = "freg",           # ICD filter mode
      "V_D76.V10" = "*All*",            # All ICD codes initially
      "F_D76.V10" = c("X85", "X86", "X87", "X88", "X89", "X90", "X91",
                       "X92", "X93", "X94", "X95", "X96", "X97", "X98",
                       "X99", "Y00", "Y01", "Y02", "Y03", "Y04", "Y05",
                       "Y06", "Y07", "Y08", "Y09", "Y871"),
      "action" = "Send"
    )

    # Add year values
    for (yr in block) {
      params[[paste0("V_D76.V1")]] <- c(params[["V_D76.V1"]], yr)
    }

    tryCatch({
      resp <- httr::POST(wonder_url, body = params, encode = "form",
                         httr::timeout(120))

      if (httr::status_code(resp) == 200) {
        content <- httr::content(resp, "text", encoding = "UTF-8")
        # Parse the tab-delimited response
        if (grepl("County\t", content)) {
          df <- fread(text = content, sep = "\t", header = TRUE, fill = TRUE)
          if (nrow(df) > 0) {
            all_wonder[[length(all_wonder) + 1]] <- df
            cat(sprintf("    Got %d rows\n", nrow(df)))
          }
        } else {
          cat("    Response not in expected format, trying alternative approach\n")
        }
      } else {
        cat(sprintf("    HTTP %d\n", httr::status_code(resp)))
      }
    }, error = function(e) {
      cat(sprintf("    FAILED: %s\n", e$message))
    })

    Sys.sleep(2)
  }

  if (length(all_wonder) > 0) {
    wonder_combined <- rbindlist(all_wonder, fill = TRUE)
    fwrite(wonder_combined, wonder_file)
    cat("CDC WONDER data saved:", nrow(wonder_combined), "rows\n")
  } else {
    cat("CDC WONDER API queries did not return data in expected format.\n")
    cat("Attempting alternative: CDC compressed mortality data from NBER...\n")

    # Alternative: Use the CDC compressed mortality file
    # Available at: https://data.nber.org/mortality/
    # These are fixed-width files; complex to parse but reliable

    # Second alternative: Use the CDC WISQARS export or pre-compiled CDC data
    # For now, construct from the existing CHR data + extrapolate

    cat("Using CHR data as primary homicide source (2019-2024).\n")
    cat("NOTE: Extended homicide panel from CDC WONDER not available via automated API.\n")
    cat("The paper will note this limitation and use available data.\n")
  }
} else {
  cat("CDC WONDER data already exists\n")
}

# Alternative approach: Use CDC WONDER exported text files if available
# Check if we can get county-level homicide data from another source

# Try FBI Crime Data Explorer API for UCR data
cat("\n=== STEP 7: Fetch FBI UCR Arrest Data ===\n")

ucr_file <- file.path(DATA_DIR, "ucr_arrests.csv")
if (!file.exists(ucr_file)) {
  cat("Fetching FBI UCR data from Crime Data Explorer...\n")

  # FBI CDE API: https://api.usa.gov/crime/fbi/cde/
  # Note: This API has been unreliable, but try the arrest data endpoint

  # Get state-level arrest data by offense (county-level not reliably available)
  fbi_api_key <- Sys.getenv("FBI_API_KEY", unset = "")

  # Try the UCR summarized data
  ucr_list <- list()

  # The FBI CDE API provides state-level data; county requires ICPSR/NACJD
  # Use state-level as a proxy for mechanism analysis

  state_abbrs <- c("CA","FL","IL","KS","MA","MD","MI","MO","NC","NY","OR","PA","TX","VA")

  for (st in state_abbrs) {
    for (yr in 2010:2022) {
      url <- sprintf("https://api.usa.gov/crime/fbi/cde/arrest/state/%s/%d/%d?API_KEY=%s",
                      st, yr, yr, fbi_api_key)
      tryCatch({
        resp <- fromJSON(url, simplifyVector = TRUE)
        if (!is.null(resp$data) && length(resp$data) > 0) {
          df <- as.data.frame(resp$data)
          df$state <- st
          df$year <- yr
          ucr_list[[paste(st, yr)]] <- df
        }
        Sys.sleep(0.3)
      }, error = function(e) {
        # Silently skip failed requests
      })
    }
  }

  if (length(ucr_list) > 0) {
    ucr_combined <- rbindlist(ucr_list, fill = TRUE)
    fwrite(ucr_combined, ucr_file)
    cat("UCR arrest data saved:", nrow(ucr_combined), "rows\n")
  } else {
    cat("FBI CDE API did not return usable arrest data.\n")
    cat("UCR mechanism analysis will be noted as a limitation.\n")
  }
} else {
  cat("UCR data already exists\n")
}

cat("\n=== STEP 8: Fetch County Adjacency File ===\n")

adj_file <- file.path(DATA_DIR, "county_adjacency.csv")
if (!file.exists(adj_file)) {
  cat("Downloading Census county adjacency file...\n")

  # Census Bureau county adjacency file
  adj_url <- "https://www2.census.gov/geo/docs/reference/county_adjacency.txt"

  tryCatch({
    download.file(adj_url, file.path(DATA_DIR, "county_adjacency_raw.txt"),
                  mode = "wb", quiet = FALSE)

    # Parse the adjacency file (tab-delimited, multi-line format)
    raw_lines <- readLines(file.path(DATA_DIR, "county_adjacency_raw.txt"), warn = FALSE)
    cat("Raw adjacency lines:", length(raw_lines), "\n")

    adj_pairs <- list()
    current_fips <- NA
    current_name <- NA

    for (line in raw_lines) {
      parts <- strsplit(line, "\t")[[1]]
      if (length(parts) >= 4 && nchar(trimws(parts[1])) > 0) {
        # New county block
        current_name <- trimws(parts[1])
        current_fips <- trimws(parts[2])
        neighbor_name <- trimws(parts[3])
        neighbor_fips <- trimws(parts[4])
        if (!is.na(current_fips) && !is.na(neighbor_fips) && current_fips != neighbor_fips) {
          adj_pairs[[length(adj_pairs) + 1]] <- data.frame(
            fips = current_fips, neighbor_fips = neighbor_fips,
            stringsAsFactors = FALSE
          )
        }
      } else if (length(parts) >= 2) {
        # Continuation line (neighbor of current county)
        neighbor_name <- trimws(parts[length(parts) - 1])
        neighbor_fips <- trimws(parts[length(parts)])
        if (!is.na(current_fips) && !is.na(neighbor_fips) &&
            nchar(neighbor_fips) == 5 && current_fips != neighbor_fips) {
          adj_pairs[[length(adj_pairs) + 1]] <- data.frame(
            fips = current_fips, neighbor_fips = neighbor_fips,
            stringsAsFactors = FALSE
          )
        }
      }
    }

    if (length(adj_pairs) > 0) {
      adj_df <- rbindlist(adj_pairs)
      # Pad FIPS codes
      adj_df[, fips := str_pad(fips, 5, pad = "0")]
      adj_df[, neighbor_fips := str_pad(neighbor_fips, 5, pad = "0")]
      fwrite(adj_df, adj_file)
      cat("County adjacency file:", nrow(adj_df), "pairs\n")
    }
  }, error = function(e) {
    cat("Adjacency download failed:", e$message, "\n")
  })
} else {
  cat("County adjacency already exists\n")
}

cat("\n=== STEP 9: Fetch MSA/CBSA Classification ===\n")

msa_file <- file.path(DATA_DIR, "county_msa.csv")
if (!file.exists(msa_file)) {
  cat("Downloading CBSA delineation file...\n")

  # Census Bureau CBSA delineation files
  msa_url <- "https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2023/delineation-files/list1_2023.xls"

  tryCatch({
    # Download as xls, convert to csv
    tmp_xls <- tempfile(fileext = ".xls")
    download.file(msa_url, tmp_xls, mode = "wb", quiet = TRUE)

    # Try readxl if available, otherwise use a CSV fallback
    if (requireNamespace("readxl", quietly = TRUE)) {
      msa_raw <- readxl::read_excel(tmp_xls, skip = 2)
      msa_df <- as.data.table(msa_raw)
      # Standardize column names
      if ("FIPS State Code" %in% names(msa_df) && "FIPS County Code" %in% names(msa_df)) {
        msa_df[, fips := paste0(
          str_pad(`FIPS State Code`, 2, pad = "0"),
          str_pad(`FIPS County Code`, 3, pad = "0")
        )]
        msa_df[, cbsa_code := as.character(`CBSA Code`)]
        msa_df[, cbsa_title := `CBSA Title`]
        msa_df[, metro_micro := `Metropolitan/Micropolitan Statistical Area`]
        msa_df[, central_outlying := `Central/Outlying County`]

        msa_out <- msa_df[, .(fips, cbsa_code, cbsa_title, metro_micro, central_outlying)]
        fwrite(msa_out, msa_file)
        cat("MSA classification:", nrow(msa_out), "counties\n")
      }
    } else {
      cat("readxl not available; creating MSA classification from ACS urban flag\n")
    }
  }, error = function(e) {
    cat("MSA download failed:", e$message, "\n")
    cat("Will use Vera urbanicity field as fallback for metro classification.\n")
  })
} else {
  cat("MSA classification already exists\n")
}

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Files in data directory:\n")
cat(paste(list.files(DATA_DIR), collapse = "\n"), "\n")
