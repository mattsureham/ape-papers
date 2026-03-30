##############################################################################
# 01_fetch_data.R — Fetch all data sources
# apep_1168: Contagious NIMBYism
##############################################################################

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. USGS Wind Turbine Database
# ============================================================================
cat("=== Fetching USGS Wind Turbine Database ===\n")

uswtdb_url <- "https://eerscmap.usgs.gov/uswtdb/assets/data/uswtdbCSV.zip"
uswtdb_zip <- file.path(DATA_DIR, "uswtdb.zip")

if (!file.exists(file.path(DATA_DIR, "uswtdb_v7_1_20240817.csv")) &&
    !any(grepl("uswtdb", list.files(DATA_DIR, pattern = "\\.csv$")))) {
  download.file(uswtdb_url, uswtdb_zip, mode = "wb", quiet = FALSE)
  unzip(uswtdb_zip, exdir = DATA_DIR)
  file.remove(uswtdb_zip)
}

# Find the CSV (version number in filename changes)
uswtdb_file <- list.files(DATA_DIR, pattern = "uswtdb.*\\.csv$", full.names = TRUE)
if (length(uswtdb_file) == 0) {
  stop("FATAL: USGS Wind Turbine Database CSV not found after download.")
}
uswtdb_file <- uswtdb_file[1]
cat("  USGS turbine file:", basename(uswtdb_file), "\n")

turbines <- fread(uswtdb_file)
cat("  Rows:", nrow(turbines), "| Columns:", ncol(turbines), "\n")
cat("  Year range:", range(turbines$p_year, na.rm = TRUE), "\n")
cat("  States:", length(unique(turbines$t_state)), "\n")

# Validate: must have county FIPS and commissioning year
stopifnot("t_fips" %in% names(turbines) || "xlong" %in% names(turbines))
stopifnot("p_year" %in% names(turbines))

# ============================================================================
# 2. SCI (Social Connectedness Index) from Azure
# ============================================================================
cat("\n=== Loading SCI from Azure ===\n")

sci_local <- file.path(DATA_DIR, "sci_us_counties.csv")
if (!file.exists(sci_local)) {
  stop("FATAL: SCI data not found. Download us_counties.zip from Azure raw/sci/v2026/ first.")
}

sci_raw <- fread(sci_local)
cat("  SCI rows:", nrow(sci_raw), "| Columns:", ncol(sci_raw), "\n")
cat("  SCI column names:", paste(names(sci_raw), collapse = ", "), "\n")

# ============================================================================
# 3. Wind Energy Ordinance Data
# ============================================================================
cat("\n=== Fetching wind energy ordinance/opposition data ===\n")

# Try NREL Wind Energy Ordinance Database via Open Energy Data API
# NREL hosts this through their API
nrel_url <- "https://data.openei.org/submissions/5733"  # NREL wind ordinance dataset

# Alternative: use the Sabin Center / Columbia Law School opposition tracker
# which is available at: https://climate.law.columbia.edu/content/renewable-energy-opposition-database
# They provide CSV downloads

# Try downloading from known reliable source
ordinance_file <- file.path(DATA_DIR, "wind_ordinances.csv")

if (!file.exists(ordinance_file)) {
  # Try NREL first via direct download
  cat("  Attempting NREL Wind Ordinance Database download...\n")

  # NREL Wind Ordinance Database 2025 (county/township level)
  nrel_api_url <- "https://data.openei.org/files/8519/Wind%20Ordinances%202025%20(1).xlsx"
  nrel_local <- file.path(DATA_DIR, "nrel_ordinances_2025.xlsx")

  resp <- GET(nrel_api_url, write_disk(nrel_local, overwrite = TRUE), timeout(120))
  if (status_code(resp) != 200 || file.size(nrel_local) < 10000) {
    stop("FATAL: NREL 2025 Wind Ordinance download failed. Status: ", status_code(resp))
  }
  cat("  NREL 2025 download successful:", file.size(nrel_local), "bytes\n")

  # Read all sheets to find the one with county/local data
  sheets <- readxl::excel_sheets(nrel_local)
  cat("  Sheets:", paste(sheets, collapse = ", "), "\n")

  # Read each sheet and find the one with most rows (likely county-level)
  all_data <- list()
  for (s in sheets) {
    d <- as.data.table(readxl::read_excel(nrel_local, sheet = s))
    cat(sprintf("  Sheet '%s': %d rows, %d cols\n", s, nrow(d), ncol(d)))
    cat("    Columns:", paste(head(names(d), 8), collapse = ", "), "\n")
    all_data[[s]] <- d
  }

  # Use the largest sheet (should be county/local ordinances)
  biggest <- which.max(sapply(all_data, nrow))
  nrel_data <- all_data[[biggest]]
  cat("  Using sheet:", names(all_data)[biggest], "with", nrow(nrel_data), "rows\n")
  fwrite(nrel_data, ordinance_file)
}

# ============================================================================
# 4. County-level controls from ACS via tidycensus
# ============================================================================
cat("\n=== Fetching ACS county controls ===\n")

acs_file <- file.path(DATA_DIR, "county_controls.csv")
if (!file.exists(acs_file)) {
  # Use 2020 ACS 5-year for controls
  acs_vars <- c(
    pop = "B01001_001",      # Total population
    medinc = "B19013_001",   # Median household income
    college = "B15003_022",  # Bachelor's degree
    pop25 = "B15003_001",    # Population 25+
    rural = "B01001_001"     # Will use USDA rural codes instead
  )

  acs <- get_acs(
    geography = "county",
    variables = acs_vars[1:4],
    year = 2020,
    survey = "acs5",
    output = "wide",
    geometry = FALSE
  )

  # Clean — wide format uses variable names as suffixes
  acs_dt <- as.data.table(acs)
  cat("  ACS columns:", paste(names(acs_dt), collapse = ", "), "\n")
  acs_dt[, fips := GEOID]
  # Wide format column names: popE, medincE, collegeE, pop25E (estimate suffix E)
  pop_col <- grep("popE$|B01001_001E$", names(acs_dt), value = TRUE)[1]
  medinc_col <- grep("medincE$|B19013_001E$", names(acs_dt), value = TRUE)[1]
  college_col <- grep("collegeE$|B15003_022E$", names(acs_dt), value = TRUE)[1]
  pop25_col <- grep("pop25E$|B15003_001E$", names(acs_dt), value = TRUE)[1]

  acs_dt[, pop := get(pop_col)]
  acs_dt[, medinc := get(medinc_col)]
  acs_dt[, college_share := get(college_col) / get(pop25_col)]

  fwrite(acs_dt[, .(fips, NAME, pop, medinc, college_share)], acs_file)
  cat("  ACS counties:", nrow(acs_dt), "\n")
} else {
  cat("  ACS controls already cached\n")
}

# ============================================================================
# 5. County geographic centroids for distance calculations
# ============================================================================
cat("\n=== Fetching county centroids ===\n")

centroids_file <- file.path(DATA_DIR, "county_centroids.csv")
if (!file.exists(centroids_file)) {
  options(tigris_use_cache = TRUE)
  counties_sf <- counties(cb = TRUE, year = 2020)
  centroids <- st_centroid(counties_sf)
  coords <- st_coordinates(centroids)
  cent_dt <- data.table(
    fips = counties_sf$GEOID,
    lon = coords[, 1],
    lat = coords[, 2]
  )
  fwrite(cent_dt, centroids_file)
  cat("  County centroids:", nrow(cent_dt), "\n")
} else {
  cat("  Centroids already cached\n")
}

# ============================================================================
# 6. Presidential election results by county (political lean control)
# ============================================================================
cat("\n=== Fetching county election data ===\n")

election_file <- file.path(DATA_DIR, "county_elections.csv")
if (!file.exists(election_file)) {
  # MIT Election Data + Science Lab county-level presidential returns
  # Available at: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ
  # Use 2016 + 2020 election results
  elect_url <- "https://raw.githubusercontent.com/tonmcg/US_County_Level_Election_Results_08-20/master/2020_US_County_Level_Presidential_Results.csv"

  tryCatch({
    elect_raw <- fread(elect_url)
    cat("  Election data rows:", nrow(elect_raw), "\n")

    elect_raw[, fips := sprintf("%05d", as.integer(county_fips))]
    elect_raw[, gop_share := per_gop]

    fwrite(elect_raw[, .(fips, gop_share, total_votes)], election_file)
  }, error = function(e) {
    cat("  Election download failed:", e$message, "\n")
    cat("  Will proceed without political lean control.\n")
    # Create empty file as placeholder
    fwrite(data.table(fips = character(), gop_share = numeric(),
                      total_votes = numeric()), election_file)
  })
} else {
  cat("  Election data already cached\n")
}

cat("\n=== Data fetch complete ===\n")
cat("Files in data directory:\n")
cat(paste("  ", list.files(DATA_DIR, recursive = TRUE), collapse = "\n"), "\n")
