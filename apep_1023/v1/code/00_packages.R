## 00_packages.R — Load required packages for SNAP retailer analysis
## apep_1023: Redemption Deserts

pkgs <- c(
  "tidyverse",     # Data manipulation + ggplot2
  "dplyr",         # Explicit dplyr load
  "data.table",    # Fast data operations (explicit)
  "fixest",        # IV/2SLS with fixed effects (feols)
  "tidycensus",    # ACS data via Census API
  "data.table",    # Fast data operations
  "jsonlite",      # Write diagnostics.json
  "sf",            # Spatial joins (tract-retailer matching)
  "httr",          # HTTP requests for SNAP retailer data
  "readr",         # Fast CSV reading
  "lmtest",        # Diagnostic tests
  "sandwich"       # Robust standard errors
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
