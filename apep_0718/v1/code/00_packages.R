## 00_packages.R — Load and verify required packages
## apep_0718: Tornado Paths and Manufactured Housing

required_pkgs <- c(
  "tidyverse",    # Data wrangling and visualization
  "sf",           # Spatial operations (tornado path polygons, spatial joins)
  "tigris",       # Census TIGER/Line boundary shapefiles
  "tidycensus",   # Census ACS API access
  "fixest",       # Fixed effects regression
  "rdrobust",     # RDD estimation (Cattaneo et al.)
  "rddensity",    # McCrary density test
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "jsonlite",     # JSON output for diagnostics
  "xtable"        # LaTeX table generation
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Suppress sf messages
sf_use_s2(FALSE)

# Census API key (from environment)
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) > 0) {
  census_api_key(census_key, install = FALSE)
} else {
  warning("CENSUS_API_KEY not set — tidycensus will use unauthenticated access (lower rate limits)")
}

# tigris settings
options(tigris_use_cache = TRUE)

cat("All packages loaded successfully.\n")
