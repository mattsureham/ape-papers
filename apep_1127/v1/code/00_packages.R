# 00_packages.R — Load required packages for apep_1127
# Injection well volume regulations and induced seismicity

required_packages <- c(
  "tidyverse",    # Data manipulation and plotting
  "fixest",       # Fixed effects estimation
  "did",          # Callaway & Sant'Anna (2021)
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "sf",           # Spatial operations (point-in-polygon)
  "tigris",       # Census TIGER/Line shapefiles
  "fredr",        # FRED API for oil prices
  "data.table",   # Fast data manipulation
  "xtable",       # LaTeX table export
  "sandwich",     # Robust SEs
  "lmtest"        # Hypothesis testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Set FRED API key
fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) > 0) {
  fredr_set_key(fred_key)
} else {
  warning("FRED_API_KEY not set — will use backup oil price data")
}

# tigris options
options(tigris_use_cache = TRUE)

cat("All packages loaded successfully.\n")
