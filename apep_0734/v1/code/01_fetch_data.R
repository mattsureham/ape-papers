# 01_fetch_data.R — Fetch STATS19 collision data and ONS population data
# apep_0734: Wales 20mph Speed Limit and Road Casualties

source("00_packages.R")

cat("=== Fetching STATS19 collision data ===\n")

base_url <- "https://data.dft.gov.uk/road-accidents-safety-data"

# Use the per-year files where available (2020-2024), and historical for 2019
years_available <- 2020:2024

collision_list <- list()

# First download 2020-2024 individual files
for (yr in years_available) {
  url <- paste0(base_url, "/dft-road-casualty-statistics-collision-", yr, ".csv")
  dest <- paste0("../data/collisions_", yr, ".csv")
  cat("Downloading collisions", yr, "...\n")
  dl <- download.file(url, dest, method = "curl", quiet = TRUE, extra = "-L")
  if (dl != 0) stop(paste("Download failed for collisions", yr))
  dt <- fread(dest, showProgress = FALSE)
  dt[, year := yr]
  collision_list[[as.character(yr)]] <- dt
  cat("  ", nrow(dt), "collisions\n")
  unlink(dest)
}

# 2019: extract from historical master file
cat("Downloading historical collision data for 2019...\n")
hist_url <- paste0(base_url, "/dft-road-casualty-statistics-collision-1979-latest-published-year.csv")
hist_dest <- "../data/collisions_hist.csv"
dl <- download.file(hist_url, hist_dest, method = "curl", quiet = TRUE, extra = "-L")
if (dl != 0) stop("Download failed for historical collision data")

# Read and filter to 2019 only (avoid loading huge file fully)
hist_dt <- fread(hist_dest, showProgress = FALSE)
cat("Historical file:", nrow(hist_dt), "total rows\n")

# Identify year column
yr_col <- intersect(c("collision_year", "accident_year"), names(hist_dt))[1]
cat("Year column:", yr_col, "\n")

dt_2019 <- hist_dt[get(yr_col) == 2019]
dt_2019[, year := 2019L]
collision_list[["2019"]] <- dt_2019
cat("  2019:", nrow(dt_2019), "collisions\n")
rm(hist_dt)
gc()
unlink(hist_dest)

collisions <- rbindlist(collision_list, fill = TRUE)
cat("Total collisions:", nrow(collisions), "\n")
fwrite(collisions, "../data/collisions_raw.csv")

# --- Download casualty data ---
cat("\n=== Fetching casualty data ===\n")
casualty_list <- list()

for (yr in years_available) {
  url <- paste0(base_url, "/dft-road-casualty-statistics-casualty-", yr, ".csv")
  dest <- paste0("../data/casualties_", yr, ".csv")
  cat("Downloading casualties", yr, "...\n")
  dl <- download.file(url, dest, method = "curl", quiet = TRUE, extra = "-L")
  if (dl != 0) stop(paste("Download failed for casualties", yr))
  dt <- fread(dest, showProgress = FALSE)
  dt[, year := yr]
  casualty_list[[as.character(yr)]] <- dt
  cat("  ", nrow(dt), "casualties\n")
  unlink(dest)
}

# 2019 from historical
cat("Downloading historical casualty data for 2019...\n")
hist_cas_url <- paste0(base_url, "/dft-road-casualty-statistics-casualty-1979-latest-published-year.csv")
hist_cas_dest <- "../data/casualties_hist.csv"
dl <- download.file(hist_cas_url, hist_cas_dest, method = "curl", quiet = TRUE, extra = "-L")
if (dl != 0) stop("Download failed for historical casualty data")

hist_cas <- fread(hist_cas_dest, showProgress = FALSE)
cat("Historical casualty file:", nrow(hist_cas), "total rows\n")

# Identify year column
cas_yr_col <- intersect(c("collision_year", "accident_year"), names(hist_cas))
if (length(cas_yr_col) == 0) {
  # Try to extract year from collision_index
  hist_cas[, year_extracted := as.integer(substr(as.character(collision_index), 1, 4))]
  cas_2019 <- hist_cas[year_extracted == 2019]
} else {
  cas_2019 <- hist_cas[get(cas_yr_col[1]) == 2019]
}
cas_2019[, year := 2019L]
casualty_list[["2019"]] <- cas_2019
cat("  2019:", nrow(cas_2019), "casualties\n")
rm(hist_cas)
gc()
unlink(hist_cas_dest)

casualties <- rbindlist(casualty_list, fill = TRUE)
cat("Total casualties:", nrow(casualties), "\n")
fwrite(casualties, "../data/casualties_raw.csv")

# --- Population data ---
cat("\n=== Fetching LA population data ===\n")

pop_url <- "https://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv"
nomis_key <- Sys.getenv("NOMIS_API_KEY")

pop_params <- paste0(
  "?geography=TYPE464",
  "&date=latest",
  "&gender=0",
  "&c_age=200",
  "&measures=20100",
  "&select=DATE_NAME,GEOGRAPHY_NAME,GEOGRAPHY_CODE,OBS_VALUE"
)
if (nchar(nomis_key) > 0) pop_params <- paste0(pop_params, "&uid=", nomis_key)

pop_dest <- "../data/population_raw.csv"
dl_pop <- tryCatch(
  download.file(paste0(pop_url, pop_params), pop_dest, method = "curl", quiet = TRUE, extra = "-L"),
  error = function(e) 1
)

if (dl_pop == 0) {
  pop_dt <- fread(pop_dest, showProgress = FALSE)
  cat("Population data:", nrow(pop_dt), "rows\n")
} else {
  cat("NOMIS population download failed — will use raw counts\n")
}

# --- Validate ---
stopifnot(nrow(collisions) > 100000)
stopifnot(nrow(casualties) > 100000)

cat("\n=== Data fetch complete ===\n")
cat("Collisions:", nrow(collisions), "\n")
cat("Casualties:", nrow(casualties), "\n")
