# ==============================================================================
# 01_fetch_data.R — Fetch all data for SVB social connectedness analysis
# apep_1058: The Networked Bank Run
# ==============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

# Set working directory context
data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# 1. Social Connectedness Index (SCI) — from Azure
# ==============================================================================
cat("=== Fetching SCI data from Azure ===\n")

if (file.exists(file.path(data_dir, "sci_raw.rds"))) {
  cat("SCI already cached, skipping.\n")
} else {
  sci_csv <- file.path(data_dir, "us_counties.csv")
  stopifnot("SCI CSV must exist (unzip us_counties.zip first)" = file.exists(sci_csv))
  sci_raw <- data.table::fread(sci_csv)
  sci_raw <- as.data.frame(sci_raw)
  cat(sprintf("SCI raw: %s rows, %s columns\n", format(nrow(sci_raw), big.mark=","), ncol(sci_raw)))
  saveRDS(sci_raw, file.path(data_dir, "sci_raw.rds"))
  cat("SCI data saved.\n")
}

# ==============================================================================
# 2. FDIC Summary of Deposits (SOD) — via FDIC API
# ==============================================================================
cat("\n=== Fetching FDIC Summary of Deposits ===\n")

# FDIC BankFind API: https://banks.data.fdic.gov/api/
# Fetch SOD data for 2019-2023, branch-level

fetch_sod_year <- function(year) {
  cat(sprintf("  Fetching SOD %d...\n", year))
  base_url <- "https://banks.data.fdic.gov/api/sod"

  all_rows <- list()
  offset <- 0
  limit <- 10000
  total <- NULL
  fields <- "CERT,STCNTYBR,DEPSUMBR,NAMEFULL,SIMS_LATITUDE,SIMS_LONGITUDE,STALP"

  repeat {
    params <- list(
      filters = sprintf("YEAR:%d", year),
      fields = fields,
      sort_by = "CERT",
      sort_order = "ASC",
      limit = limit,
      offset = offset
    )

    resp <- GET(base_url, query = params)

    if (status_code(resp) != 200) {
      stop(sprintf("FDIC API error for year %d: HTTP %d", year, status_code(resp)))
    }

    json_text <- content(resp, as = "text", encoding = "UTF-8")
    parsed <- fromJSON(json_text, simplifyVector = FALSE)

    if (is.null(total)) {
      total <- parsed$totals$count
      cat(sprintf("    Total branches for %d: %s\n", year, format(total, big.mark=",")))
    }

    if (length(parsed$data) == 0) break

    # Safe extraction: replace NULLs with NA
    rows <- lapply(parsed$data, function(x) {
      d <- x$data
      lapply(d, function(v) if (is.null(v)) NA else v)
    })

    batch_df <- rbindlist(rows, fill = TRUE)
    all_rows[[length(all_rows) + 1]] <- batch_df
    offset <- offset + limit

    if (offset >= total) break
    Sys.sleep(0.3)
  }

  df <- rbindlist(all_rows, fill = TRUE)
  df$YEAR <- year
  cat(sprintf("    Retrieved %s branches for %d\n", format(nrow(df), big.mark=","), year))
  return(as.data.frame(df))
}

if (file.exists(file.path(data_dir, "sod_all.rds"))) {
  cat("SOD already cached, skipping.\n")
  sod_all <- readRDS(file.path(data_dir, "sod_all.rds"))
} else {
  sod_list <- lapply(2019:2023, fetch_sod_year)
  sod_all <- bind_rows(sod_list)
  cat(sprintf("\nTotal SOD records: %s rows\n", format(nrow(sod_all), big.mark=",")))
  stopifnot("SOD data must have records" = nrow(sod_all) > 50000)
  saveRDS(sod_all, file.path(data_dir, "sod_all.rds"))
  cat("SOD data saved.\n")
}

# ==============================================================================
# 3. County-level controls — BEA personal income & population
# ==============================================================================
cat("\n=== Fetching county controls from BEA ===\n")

bea_key <- Sys.getenv("BEA_API_KEY")
if (nchar(bea_key) == 0) stop("BEA_API_KEY not set in .env")

# BEA CAINC1: Personal income, population, per capita income by county
bea_url <- sprintf(
  "https://apps.bea.gov/api/data/?UserID=%s&method=GetData&datasetname=Regional&TableName=CAINC1&LineCode=1&GeoFips=COUNTY&Year=2022&ResultFormat=json",
  bea_key
)

resp_bea <- GET(bea_url)
stopifnot("BEA API must return 200" = status_code(resp_bea) == 200)

bea_parsed <- content(resp_bea, as = "parsed", type = "application/json")
bea_data <- bea_parsed$BEAAPI$Results$Data

bea_df <- bind_rows(lapply(bea_data, function(x) {
  data.frame(
    fips = x$GeoFips,
    geo_name = x$GeoName,
    personal_income_2022 = as.numeric(gsub(",", "", x$DataValue)),
    stringsAsFactors = FALSE
  )
}))

# Also get population (LineCode 2)
bea_pop_url <- sprintf(
  "https://apps.bea.gov/api/data/?UserID=%s&method=GetData&datasetname=Regional&TableName=CAINC1&LineCode=2&GeoFips=COUNTY&Year=2022&ResultFormat=json",
  bea_key
)

resp_pop <- GET(bea_pop_url)
stopifnot("BEA pop API must return 200" = status_code(resp_pop) == 200)

pop_parsed <- content(resp_pop, as = "parsed", type = "application/json")
pop_data <- pop_parsed$BEAAPI$Results$Data

pop_df <- bind_rows(lapply(pop_data, function(x) {
  data.frame(
    fips = x$GeoFips,
    population_2022 = as.numeric(gsub(",", "", x$DataValue)),
    stringsAsFactors = FALSE
  )
}))

county_controls <- merge(bea_df, pop_df, by = "fips", all = TRUE)
cat(sprintf("County controls: %d counties\n", nrow(county_controls)))

saveRDS(county_controls, file.path(data_dir, "county_controls.rds"))
cat("County controls saved.\n")

# ==============================================================================
# 4. QWI tech employment — Census API
# ==============================================================================
cat("\n=== Fetching QWI tech employment ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in .env")

# QWI: Information sector (NAICS 51) as proxy for tech
# State-level loop because QWI requires state FIPS
state_fips <- c(
  "01","02","04","05","06","08","09","10","11","12","13","15","16","17","18","19",
  "20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35",
  "36","37","38","39","40","41","42","44","45","46","47","48","49","50","51","53",
  "54","55","56"
)

qwi_results <- list()
for (st in state_fips) {
  url <- sprintf(
    "https://api.census.gov/data/timeseries/qwi/sa?get=Emp,EmpTotal&for=county:*&in=state:%s&year=2022&quarter=2&industry=51&key=%s",
    st, census_key
  )
  resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)
  if (is.null(resp) || status_code(resp) != 200) {
    cat(sprintf("  QWI skip state %s (HTTP %s)\n", st,
                if(!is.null(resp)) status_code(resp) else "timeout"))
    next
  }
  json_text <- content(resp, as = "text", encoding = "UTF-8")
  mat <- fromJSON(json_text)
  if (is.null(mat) || nrow(mat) <= 1) next

  header <- mat[1, ]
  df_st <- as.data.frame(mat[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(df_st) <- header
  qwi_results[[st]] <- df_st
  Sys.sleep(0.3)
}

qwi_tech <- bind_rows(qwi_results)

if (nrow(qwi_tech) > 0) {
  qwi_tech <- qwi_tech %>%
    mutate(
      fips = paste0(state, county),
      tech_emp = as.numeric(Emp),
      total_emp = as.numeric(EmpTotal)
    ) %>%
    select(fips, tech_emp, total_emp)

  cat(sprintf("QWI tech employment: %d counties\n", nrow(qwi_tech)))
} else {
  cat("WARNING: QWI returned no data. Will use fallback.\n")
  qwi_tech <- data.frame(fips = character(0), tech_emp = numeric(0), total_emp = numeric(0))
}

saveRDS(qwi_tech, file.path(data_dir, "qwi_tech.rds"))

# ==============================================================================
# Validation checks
# ==============================================================================
cat("\n=== Data validation ===\n")

# Reload cached data for validation
sci_check <- readRDS(file.path(data_dir, "sci_raw.rds"))
sod_check <- readRDS(file.path(data_dir, "sod_all.rds"))

cat(sprintf("SCI: %s county pairs\n", format(nrow(sci_check), big.mark=",")))
cat(sprintf("SOD: %s branch-year observations\n", format(nrow(sod_check), big.mark=",")))
cat(sprintf("County controls: %d counties\n", nrow(county_controls)))
cat(sprintf("QWI tech: %d counties\n", nrow(qwi_tech)))

# Hard checks
stopifnot("SCI must have >1M pairs" = nrow(sci_check) > 1000000)
stopifnot("SOD must have >200K records" = nrow(sod_check) > 200000)
stopifnot("County controls must have >2000 counties" = nrow(county_controls) > 2000)

cat("\n=== All data fetched successfully ===\n")
