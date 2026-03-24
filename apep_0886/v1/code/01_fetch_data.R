# =============================================================================
# 01_fetch_data.R — Fetch QWI Data from Census Bureau API
# Paper: apep_0886 — Childcare Stabilization Grants and Maternal Labor Supply
# =============================================================================
# QWI SE (Sex × Education) quarterly data by state × industry × sex
# Source: Census Bureau QWI API
# =============================================================================

source("00_packages.R")

# Load Census API key from .env
env_lines <- readLines("../../../../.env", warn = FALSE)
census_line <- grep("^CENSUS_API_KEY=", env_lines, value = TRUE)
CENSUS_API_KEY <- sub("^CENSUS_API_KEY=", "", census_line)
stopifnot("Census API key not found" = nchar(CENSUS_API_KEY) > 5)
cat("Census API key loaded.\n")

# State FIPS codes (all 50 states + DC)
state_fips <- c(
  "01","02","04","05","06","08","09","10","11","12",
  "13","15","16","17","18","19","20","21","22","23",
  "24","25","26","27","28","29","30","31","32","33",
  "34","35","36","37","38","39","40","41","42","44",
  "45","46","47","48","49","50","51","53","54","55","56"
)

# Industries of interest (3-digit NAICS)
# Childcare-related: 624 (Social Assistance, includes childcare)
# Comparison: 611 (Education), 623 (Nursing/Residential Care)
# Placebo: 311 (Food Manufacturing), 332 (Fabricated Metal)
industries <- c("624", "611", "623", "311", "332")

# Time period: 2019Q1 to 2024Q4
quarters <- expand.grid(
  year = 2019:2024,
  quarter = 1:4,
  stringsAsFactors = FALSE
) %>%
  mutate(time = paste0(year, "-Q", quarter)) %>%
  filter(!(year == 2024 & quarter > 3))  # QWI may not have 2024Q4 yet

cat("Fetching QWI SE data for", length(state_fips), "states,",
    length(industries), "industries,", nrow(quarters), "quarters\n")

# Function to fetch one state × industry × quarter
fetch_qwi <- function(state, industry, time_str, api_key) {
  base_url <- "https://api.census.gov/data/timeseries/qwi/se"
  url <- paste0(
    base_url,
    "?get=EmpS,EarnS,HirN,SepS,sex,education",
    "&for=state:", state,
    "&industry=", industry,
    "&ownercode=A05",
    "&agegrp=A00",
    "&time=", time_str,
    "&key=", api_key
  )

  resp <- tryCatch(
    httr::GET(url, httr::timeout(30)),
    error = function(e) NULL
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    return(NULL)
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  if (nchar(content) < 10) return(NULL)

  parsed <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
  if (is.null(parsed) || nrow(parsed) < 2) return(NULL)

  df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df$industry <- industry
  df
}

# Fetch all combinations with rate limiting
all_data <- list()
idx <- 0
total_calls <- length(state_fips) * length(industries) * nrow(quarters)
cat("Total API calls needed:", total_calls, "\n")
cat("Fetching in batches...\n")

# Batch by state to reduce API calls — request all quarters at once
fetch_qwi_batch <- function(state, industry, api_key) {
  base_url <- "https://api.census.gov/data/timeseries/qwi/se"
  url <- paste0(
    base_url,
    "?get=EmpS,EarnS,HirN,SepS,sex,education",
    "&for=state:", state,
    "&industry=", industry,
    "&ownercode=A05",
    "&agegrp=A00",
    "&time=from+2019-Q1+to+2024-Q3",
    "&key=", api_key
  )

  resp <- tryCatch(
    httr::GET(url, httr::timeout(60)),
    error = function(e) {
      cat("  HTTP error for", state, industry, ":", conditionMessage(e), "\n")
      NULL
    }
  )

  if (is.null(resp)) return(NULL)

  status <- httr::status_code(resp)
  if (status == 204) {
    cat("  204 (no data) for state", state, "industry", industry, "\n")
    return(NULL)
  }
  if (status != 200) {
    cat("  HTTP", status, "for state", state, "industry", industry, "\n")
    return(NULL)
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  if (nchar(content) < 10) return(NULL)

  parsed <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
  if (is.null(parsed) || nrow(parsed) < 2) return(NULL)

  df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df$industry_code <- industry
  df
}

# Fetch data: loop by industry, then by state
all_data <- list()
for (ind in industries) {
  cat("\n=== Industry:", ind, "===\n")
  for (st in state_fips) {
    idx <- idx + 1
    if (idx %% 50 == 0) cat("  Progress:", idx, "/", length(state_fips) * length(industries), "\n")

    result <- fetch_qwi_batch(st, ind, CENSUS_API_KEY)
    if (!is.null(result) && nrow(result) > 0) {
      all_data[[length(all_data) + 1]] <- result
    }

    Sys.sleep(0.15)  # Rate limiting
  }
}

cat("\nTotal batches fetched:", length(all_data), "\n")

# Combine all data
if (length(all_data) == 0) {
  stop("FATAL: No QWI data fetched. Check API key and network connectivity.")
}

qwi_raw <- bind_rows(all_data)
cat("Raw records:", nrow(qwi_raw), "\n")

# Data validation — fail loudly if data is missing
stopifnot("No data returned from QWI API" = nrow(qwi_raw) > 0)
stopifnot("Missing state column" = "state" %in% names(qwi_raw))
stopifnot("Missing sex column" = "sex" %in% names(qwi_raw))

# Convert types
qwi_raw <- qwi_raw %>%
  mutate(
    EmpS = as.numeric(EmpS),
    EarnS = as.numeric(EarnS),
    HirN = as.numeric(HirN),
    SepS = as.numeric(SepS),
    sex = as.integer(sex),
    year = as.integer(sub("-Q.*", "", time)),
    quarter = as.integer(sub(".*-Q", "", time)),
    state_fips = state
  )

# Drop education dimension — aggregate to state × industry × sex × quarter
qwi_agg <- qwi_raw %>%
  group_by(state_fips, industry_code, sex, year, quarter) %>%
  summarise(
    emp = sum(EmpS, na.rm = TRUE),
    earn = weighted.mean(EarnS, w = EmpS, na.rm = TRUE),
    hires = sum(HirN, na.rm = TRUE),
    separations = sum(SepS, na.rm = TRUE),
    .groups = "drop"
  )

cat("Aggregated records:", nrow(qwi_agg), "\n")
cat("States:", n_distinct(qwi_agg$state_fips), "\n")
cat("Industries:", n_distinct(qwi_agg$industry_code), "\n")
cat("Sex categories:", sort(unique(qwi_agg$sex)), "\n")
cat("Year range:", range(qwi_agg$year), "\n")

# Save raw data
saveRDS(qwi_agg, "../data/qwi_panel.rds")
cat("\nSaved: data/qwi_panel.rds\n")

# Quick summary
qwi_agg %>%
  filter(industry_code == "624", sex == 2, year %in% c(2019, 2021, 2023)) %>%
  group_by(year) %>%
  summarise(total_emp = sum(emp, na.rm = TRUE)) %>%
  print()
