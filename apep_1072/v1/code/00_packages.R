# 00_packages.R — Load and install required packages
# apep_1072: Dam Removal and Water Quality

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "data.table",   # Efficient data processing
  "httr",         # HTTP requests for USGS API
  "jsonlite",     # JSON parsing
  "sf",           # Spatial operations (dam-gauge matching)
  "geosphere",    # Distance calculations
  "modelsummary", # Table generation
  "kableExtra",   # LaTeX table formatting
  "sandwich",     # Robust standard errors
  "lmtest"        # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
