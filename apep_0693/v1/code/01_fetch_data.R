## 01_fetch_data.R — Fetch Census BFS weekly business applications
## apep_0693: The Price of Privacy

source("00_packages.R")

# ------------------------------------------------------------------
# 1. Download Census BFS weekly state-level data
# ------------------------------------------------------------------
bfs_url <- "https://www.census.gov/econ/bfs/csv/bfs_state_apps_weekly_nsa.csv"
bfs_file <- "../data/bfs_state_weekly.csv"

cat("Downloading Census BFS weekly state data...\n")
download.file(bfs_url, bfs_file, mode = "wb", quiet = FALSE)
bfs_raw <- fread(bfs_file)
cat(sprintf("BFS state data: %d rows, %d columns\n", nrow(bfs_raw), ncol(bfs_raw)))
stopifnot("BA_NSA" %in% names(bfs_raw) || "ba_nsa" %in% tolower(names(bfs_raw)))
stopifnot(nrow(bfs_raw) > 40000)  # Expect ~53K rows

# ------------------------------------------------------------------
# 2. Download Census BFS NAICS 2-digit sector data (national weekly)
# ------------------------------------------------------------------
naics_url <- "https://www.census.gov/econ/bfs/csv/bfs_naics2_apps_weekly_nsa.csv"
naics_file <- "../data/bfs_naics2_weekly.csv"

cat("Downloading Census BFS NAICS sector data...\n")
tryCatch({
  download.file(naics_url, naics_file, mode = "wb", quiet = FALSE)
  naics_raw <- fread(naics_file)
  cat(sprintf("BFS NAICS data: %d rows, %d columns\n", nrow(naics_raw), ncol(naics_raw)))
}, error = function(e) {
  # Try alternative URL patterns
  alt_urls <- c(
    "https://www.census.gov/econ/bfs/csv/naics2.csv",
    "https://www.census.gov/econ/bfs/csv/bfs_naics2_weekly_nsa.csv"
  )
  success <- FALSE
  for (u in alt_urls) {
    tryCatch({
      download.file(u, naics_file, mode = "wb", quiet = FALSE)
      naics_raw <- fread(naics_file)
      cat(sprintf("BFS NAICS data (alt): %d rows, %d columns\n", nrow(naics_raw), ncol(naics_raw)))
      success <- TRUE
      break
    }, error = function(e2) NULL)
  }
  if (!success) {
    stop("FATAL: Cannot download BFS NAICS sector data from any URL. Cannot proceed.")
  }
})

cat("Data fetch complete.\n")
