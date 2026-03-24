# 01_fetch_data.R — apep_0873: The Pill Pipeline
# State-level panel: disability prevalence → opioid overdose deaths
# Data: CDC VSRR (mortality by drug type), ACS (disability), Census (demographics)
source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ═══════════════════════════════════════════════════════════════════
# 1. CDC VSRR: State-level drug overdose deaths by type (2015-2024)
# ═══════════════════════════════════════════════════════════════════
cat("=== Fetching CDC VSRR overdose mortality ===\n")

cdc_url <- "https://data.cdc.gov/resource/xkb8-kh2a.json"

all_cdc <- list()
offset <- 0
repeat {
  resp <- GET(cdc_url, query = list(
    `$limit` = 50000,
    `$offset` = offset,
    `$order` = "state,year,month,indicator"
  ))
  if (status_code(resp) != 200) {
    cat(sprintf("  CDC API HTTP %d at offset %d\n", status_code(resp), offset))
    break
  }
  batch <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  if (is.null(batch) || length(batch) == 0 || nrow(batch) == 0) break
  all_cdc[[length(all_cdc) + 1]] <- batch
  cat(sprintf("  Fetched %d rows (offset %d)\n", nrow(batch), offset))
  offset <- offset + 50000
  if (nrow(batch) < 50000) break
  Sys.sleep(1)
}

cdc_raw <- rbindlist(all_cdc, fill = TRUE)

if (is.null(cdc_raw) || nrow(cdc_raw) == 0) {
  stop("CDC VSRR returned no data. Cannot proceed.")
}

cat("  Total CDC rows:", nrow(cdc_raw), "\n")
cat("  States:", length(unique(cdc_raw$state)), "\n")
cat("  Years:", paste(sort(unique(cdc_raw$year)), collapse = ", "), "\n")
cat("  Indicators:", paste(unique(cdc_raw$indicator), collapse = "; "), "\n")

fwrite(cdc_raw, file.path(data_dir, "cdc_vsrr_raw.csv"))
cat("  Saved cdc_vsrr_raw.csv\n")

# ═══════════════════════════════════════════════════════════════════
# 2. ACS: State-level disability prevalence (5-year estimates)
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Fetching ACS state-level disability data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")

fetch_acs_state <- function(year) {
  # B18101: Sex by age by disability status
  # Total pop = B18101_001E
  # With disability: sum of all "with disability" cells
  # Easier: use C18120 (age by disability status by employment)
  # Or: B18101 with specific cells

  # Simplest: S1810 subject table (disability characteristics)
  # S1810_C01_001E = Total civilian noninstitutionalized population
  # S1810_C02_001E = With a disability
  # But subject tables need /subject endpoint

  # Try detailed table B18101 at state level
  base_url <- sprintf("https://api.census.gov/data/%d/acs/acs5", year)

  # B18101_001E = Total, various _004E/_007E/etc = with disability by age/sex
  # Sum all "with disability" estimates
  dis_vars <- c(
    "B18101_004E", "B18101_007E", "B18101_010E", "B18101_013E",
    "B18101_016E", "B18101_019E",  # Males by age with disability
    "B18101_023E", "B18101_026E", "B18101_029E", "B18101_032E",
    "B18101_035E", "B18101_038E"   # Females by age with disability
  )

  get_str <- paste(c("NAME", "B18101_001E", dis_vars), collapse = ",")

  params <- list(
    get = get_str,
    `for` = "state:*"
  )
  if (!is.null(census_key) && census_key != "") params$key <- census_key

  resp <- GET(base_url, query = params)
  if (status_code(resp) != 200) {
    cat(sprintf("  ACS %d failed (HTTP %d)\n", year, status_code(resp)))
    return(NULL)
  }

  raw <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
  names(df) <- raw[1, ]

  # Compute disabled population
  for (v in dis_vars) {
    df[[v]] <- as.numeric(df[[v]])
  }
  df$disabled_pop <- rowSums(df[, dis_vars], na.rm = TRUE)
  df$total_pop <- as.numeric(df$B18101_001E)
  df$disability_rate <- df$disabled_pop / df$total_pop
  df$year <- year
  df$state_fips <- df$state

  return(df[, c("state_fips", "NAME", "year", "total_pop", "disabled_pop", "disability_rate")])
}

acs_list <- list()
for (yr in 2015:2022) {
  cat(sprintf("  Fetching ACS %d...\n", yr))
  acs_list[[as.character(yr)]] <- tryCatch(
    fetch_acs_state(yr),
    error = function(e) { cat(sprintf("  ACS %d error: %s\n", yr, e$message)); NULL }
  )
  Sys.sleep(0.5)
}

acs_state <- rbindlist(Filter(Negate(is.null), acs_list))

if (nrow(acs_state) == 0) {
  stop("ACS disability data empty. Cannot proceed.")
}

cat("  ACS state rows:", nrow(acs_state), "\n")
cat("  ACS years:", paste(sort(unique(acs_state$year)), collapse = ", "), "\n")
cat("  Mean disability rate:", round(mean(acs_state$disability_rate, na.rm = TRUE), 4), "\n")

fwrite(acs_state, file.path(data_dir, "acs_state_disability.csv"))
cat("  Saved acs_state_disability.csv\n")

# ═══════════════════════════════════════════════════════════════════
# 3. Census: State-level demographics (unemployment, income)
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Fetching Census state demographics ===\n")

fetch_census_state <- function(year) {
  base_url <- sprintf("https://api.census.gov/data/%d/acs/acs5", year)
  params <- list(
    get = "NAME,B01003_001E,B23025_002E,B23025_005E,B19013_001E,B01002_001E,B02001_002E,B02001_003E,B27001_001E,B27001_005E,B27001_008E,B27001_011E,B27001_033E,B27001_036E,B27001_039E",
    `for` = "state:*"
  )
  if (!is.null(census_key) && census_key != "") params$key <- census_key

  resp <- GET(base_url, query = params)
  if (status_code(resp) != 200) {
    cat(sprintf("  Census %d failed (HTTP %d)\n", year, status_code(resp)))
    return(NULL)
  }

  raw <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
  names(df) <- raw[1, ]

  df$year <- year
  df$state_fips <- df$state
  df$population <- as.numeric(df$B01003_001E)
  df$labor_force <- as.numeric(df$B23025_002E)
  df$unemployed <- as.numeric(df$B23025_005E)
  df$median_income <- as.numeric(df$B19013_001E)
  df$median_age <- as.numeric(df$B01002_001E)
  df$white_pop <- as.numeric(df$B02001_002E)
  df$black_pop <- as.numeric(df$B02001_003E)

  # Health insurance: B27001 (some cells for uninsured by age)
  # Simplified: just get key demographics
  df$unemp_rate <- df$unemployed / df$labor_force
  df$pct_white <- df$white_pop / df$population
  df$pct_black <- df$black_pop / df$population

  return(df[, c("state_fips", "NAME", "year", "population", "labor_force",
                "unemployed", "unemp_rate", "median_income", "median_age",
                "pct_white", "pct_black")])
}

demo_list <- list()
for (yr in 2015:2022) {
  cat(sprintf("  Fetching Census %d...\n", yr))
  demo_list[[as.character(yr)]] <- tryCatch(
    fetch_census_state(yr),
    error = function(e) { cat(sprintf("  Census %d error: %s\n", yr, e$message)); NULL }
  )
  Sys.sleep(0.5)
}

census_state <- rbindlist(Filter(Negate(is.null), demo_list))
cat("  Census state rows:", nrow(census_state), "\n")

fwrite(census_state, file.path(data_dir, "census_state.csv"))
cat("  Saved census_state.csv\n")

# ═══════════════════════════════════════════════════════════════════
# 4. State FIPS crosswalk (state abbreviation → FIPS)
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Building state FIPS crosswalk ===\n")

state_xwalk <- data.table(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                 "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                 "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                 "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  state_fips = c("01","02","04","05","06","08","09","10","12","13",
                 "15","16","17","18","19","20","21","22","23","24",
                 "25","26","27","28","29","30","31","32","33","34",
                 "35","36","37","38","39","40","41","42","44","45",
                 "46","47","48","49","50","51","53","54","55","56","11")
)

fwrite(state_xwalk, file.path(data_dir, "state_fips_xwalk.csv"))
cat("  Saved state_fips_xwalk.csv\n")

# ═══════════════════════════════════════════════════════════════════
# VALIDATION
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Data Validation ===\n")

files <- c("cdc_vsrr_raw.csv", "acs_state_disability.csv", "census_state.csv")
for (f in files) {
  ok <- file.exists(file.path(data_dir, f))
  n <- if (ok) nrow(fread(file.path(data_dir, f))) else 0
  cat(sprintf("  %s: %s (%d rows)\n", f, ifelse(ok, "OK", "MISSING"), n))
}

cat("\n=== Data fetch complete ===\n")
