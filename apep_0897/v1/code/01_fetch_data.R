## 01_fetch_data.R — Fetch real data from public APIs
## apep_0897: The Carboniferous Lottery
##
## Data sources:
## 1. MSHA mines + production (bulk download)
## 2. Water Quality Portal (REST API — specific conductance)
## 3. Census ACS (tidycensus)

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ---- Appalachian coal states ----
COAL_STATES <- c("AL", "KY", "OH", "PA", "TN", "VA", "WV")
COAL_STATE_FIPS <- c("01", "21", "39", "42", "47", "51", "54")

# ======================================================================
# 1. MSHA MINES DATA
# ======================================================================
cat("=== Fetching MSHA mines data ===\n")

msha_url <- "https://arlweb.msha.gov/OpenGovernmentData/DataSets/Mines.zip"
msha_zip <- file.path(DATA_DIR, "Mines.zip")
msha_txt <- file.path(DATA_DIR, "Mines.txt")

if (!file.exists(file.path(DATA_DIR, "msha_mines.rds"))) {
  if (!file.exists(msha_txt)) {
    download.file(msha_url, msha_zip, mode = "wb", quiet = FALSE)
    unzip(msha_zip, exdir = DATA_DIR)
    unlink(msha_zip)
  }

  mines_raw <- fread(msha_txt, sep = "|", header = TRUE, fill = TRUE,
                     quote = "\"")
  mines_raw <- clean_names(mines_raw)
  cat("  Total mines:", nrow(mines_raw), "\n")

  # Check coal_metal_ind values
  cat("  coal_metal_ind values:", paste(unique(mines_raw$coal_metal_ind),
                                         collapse = ", "), "\n")

  # Filter to coal mines in Appalachian states
  coal_mines <- mines_raw %>%
    filter(coal_metal_ind == "C") %>%
    filter(state %in% COAL_STATES)

  cat("  Coal mines in Appalachian states:", nrow(coal_mines), "\n")

  if (nrow(coal_mines) == 0) {
    # Debug: show available states for coal mines
    coal_all <- mines_raw %>% filter(coal_metal_ind == "C")
    cat("  DEBUG — all coal mine states:", paste(head(unique(coal_all$state), 20),
                                                  collapse = ", "), "\n")
    cat("  DEBUG — total coal mines:", nrow(coal_all), "\n")

    # Try matching on state name patterns
    state_patterns <- c("Alabama", "Kentucky", "Ohio", "Pennsylvania",
                        "Tennessee", "Virginia", "West Virginia",
                        "AL", "KY", "OH", "PA", "TN", "VA", "WV")
    coal_mines <- coal_all %>%
      filter(state %in% state_patterns | grepl("^(AL|KY|OH|PA|TN|VA|WV)$", state))

    if (nrow(coal_mines) == 0) {
      stop("FATAL: No coal mines found for Appalachian states. State values: ",
           paste(head(unique(coal_all$state), 10), collapse = ", "))
    }
  }

  cat("  Mine types:\n")
  print(table(coal_mines$current_mine_type))
  cat("  Columns available:\n")
  cat("    ", paste(names(coal_mines), collapse = ", "), "\n")

  saveRDS(coal_mines, file.path(DATA_DIR, "msha_mines.rds"))
} else {
  coal_mines <- readRDS(file.path(DATA_DIR, "msha_mines.rds"))
  cat("  Loaded cached MSHA mines:", nrow(coal_mines), "records\n")
}

# ======================================================================
# 2. MSHA QUARTERLY PRODUCTION DATA
# ======================================================================
cat("\n=== Fetching MSHA production data ===\n")

prod_url <- "https://arlweb.msha.gov/OpenGovernmentData/DataSets/MinesProdQuarterly.zip"
prod_zip <- file.path(DATA_DIR, "MinesProdQuarterly.zip")

if (!file.exists(file.path(DATA_DIR, "msha_production.rds"))) {
  prod_files <- list.files(DATA_DIR, pattern = "MinesProdQuarterly\\.txt$",
                           full.names = TRUE)
  if (length(prod_files) == 0) {
    download.file(prod_url, prod_zip, mode = "wb", quiet = FALSE)
    unzip(prod_zip, exdir = DATA_DIR)
    unlink(prod_zip)
    prod_files <- list.files(DATA_DIR, pattern = "MinesProdQuarterly",
                             full.names = TRUE)
    prod_files <- prod_files[!grepl("\\.zip$", prod_files)]
  }

  prod_raw <- fread(prod_files[1], sep = "|", header = TRUE, fill = TRUE,
                    quote = "\"")
  prod_raw <- clean_names(prod_raw)
  cat("  Total production records:", nrow(prod_raw), "\n")
  cat("  Production columns:", paste(head(names(prod_raw), 20), collapse = ", "), "\n")

  # Get mine IDs for our coal mines
  coal_mine_ids <- coal_mines$mine_id

  coal_prod <- prod_raw %>%
    filter(mine_id %in% coal_mine_ids)

  cat("  Matched production records:", nrow(coal_prod), "\n")

  # Merge mine characteristics
  coal_prod <- coal_prod %>%
    left_join(
      coal_mines %>% select(mine_id, state, fips_cnty_cd, current_mine_type,
                            latitude, longitude, bom_state_cd,
                            avg_mine_height),
      by = "mine_id"
    )

  saveRDS(coal_prod, file.path(DATA_DIR, "msha_production.rds"))
} else {
  coal_prod <- readRDS(file.path(DATA_DIR, "msha_production.rds"))
  cat("  Loaded cached MSHA production:", nrow(coal_prod), "records\n")
}

# ======================================================================
# 3. WATER QUALITY PORTAL — Specific Conductance
# ======================================================================
cat("\n=== Fetching Water Quality Portal data ===\n")

if (!file.exists(file.path(DATA_DIR, "wqp_conductance.rds"))) {
  wqp_all <- list()

  for (i in seq_along(COAL_STATES)) {
    st <- COAL_STATES[i]
    st_fips <- COAL_STATE_FIPS[i]
    cat("  Fetching WQP conductance for", st, "(FIPS", st_fips, ")...\n")

    wqp_url <- paste0(
      "https://www.waterqualitydata.us/data/Result/search?",
      "statecode=US%3A", st_fips,
      "&characteristicName=Specific%20conductance",
      "&startDateLo=01-01-2005&startDateHi=12-31-2023",
      "&mimeType=csv&zip=no&sorted=no",
      "&dataProfile=narrowResult"
    )

    tryCatch({
      resp <- GET(wqp_url, timeout(600))
      if (status_code(resp) == 200) {
        txt <- content(resp, as = "text", encoding = "UTF-8")
        if (nchar(txt) > 200) {
          df <- fread(text = txt, fill = TRUE, quote = "\"")
          df <- clean_names(df)
          wqp_all[[st]] <- df
          cat("    ", st, ":", nrow(df), "records\n")
        } else {
          cat("    ", st, ": empty response\n")
        }
      } else {
        cat("    ", st, ": HTTP", status_code(resp), "\n")
      }
    }, error = function(e) {
      cat("    ", st, ": ERROR -", conditionMessage(e), "\n")
    })
    Sys.sleep(2)
  }

  if (length(wqp_all) > 0) {
    wqp_data <- rbindlist(wqp_all, fill = TRUE)
    cat("  Total WQP records:", nrow(wqp_data), "\n")
    saveRDS(wqp_data, file.path(DATA_DIR, "wqp_conductance.rds"))
  } else {
    stop("FATAL: No Water Quality Portal data retrieved.")
  }
} else {
  wqp_data <- readRDS(file.path(DATA_DIR, "wqp_conductance.rds"))
  cat("  Loaded cached WQP data:", nrow(wqp_data), "records\n")
}

# Print column names for debugging
cat("  WQP columns:", paste(head(names(wqp_data), 15), collapse = ", "), "\n")

# ======================================================================
# 4. CENSUS ACS — County Demographics
# ======================================================================
cat("\n=== Fetching Census ACS data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) > 0) {
  census_api_key(census_key, install = FALSE)
}

if (!file.exists(file.path(DATA_DIR, "census_acs.rds"))) {
  acs_vars <- c(
    total_pop = "B01001_001",
    median_income = "B19013_001",
    pct_poverty = "B17001_002",
    pop_black = "B02001_003",
    pop_white = "B02001_002",
    total_housing = "B25001_001",
    median_age = "B01002_001"
  )

  acs_data <- get_acs(
    geography = "county",
    variables = acs_vars,
    state = COAL_STATE_FIPS,
    year = 2020,
    survey = "acs5",
    output = "wide",
    geometry = FALSE
  )

  acs_data <- acs_data %>%
    mutate(
      fips = GEOID,
      state_fips = substr(GEOID, 1, 2),
      county_fips = substr(GEOID, 3, 5)
    ) %>%
    rename(
      total_pop = total_popE,
      median_income = median_incomeE,
      poverty_n = pct_povertyE,
      pop_black = pop_blackE,
      pop_white = pop_whiteE,
      total_housing = total_housingE,
      median_age = median_ageE
    ) %>%
    select(fips, NAME, state_fips, county_fips,
           total_pop, median_income, poverty_n, pop_black,
           pop_white, total_housing, median_age) %>%
    mutate(
      pct_poverty = poverty_n / total_pop * 100,
      pct_black = pop_black / total_pop * 100
    )

  saveRDS(acs_data, file.path(DATA_DIR, "census_acs.rds"))
  cat("  Census ACS counties:", nrow(acs_data), "\n")
} else {
  acs_data <- readRDS(file.path(DATA_DIR, "census_acs.rds"))
  cat("  Loaded cached Census ACS:", nrow(acs_data), "records\n")
}

# ======================================================================
# SUMMARY
# ======================================================================
cat("\n========================================\n")
cat("DATA FETCH SUMMARY\n")
cat("========================================\n")
cat("MSHA mines (Appalachian coal):", nrow(coal_mines), "\n")
cat("MSHA production records:", nrow(coal_prod), "\n")
cat("WQP conductance records:", nrow(wqp_data), "\n")
cat("Census ACS counties:", nrow(acs_data), "\n")
cat("========================================\n")
