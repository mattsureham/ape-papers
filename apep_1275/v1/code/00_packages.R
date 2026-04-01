# 00_packages.R — Package dependencies for Pakistan 2022 Floods paper
# Install and load required packages

required_packages <- c(
  "sf",           # Spatial vector data
  "terra",        # Raster processing
  "geodata",      # GADM admin boundaries
  "httr",         # HTTP requests (HDX API, MODIS API)
  "jsonlite",     # JSON parsing
  "data.table",   # Fast data manipulation
  "fixest",       # Fixed effects estimation
  "modelsummary", # Regression tables
  "ggplot2",      # Plotting
  "xtable",       # LaTeX table output
  "kableExtra",   # Table formatting
  "sandwich",     # Robust SEs
  "splines"       # Natural splines for non-linear models
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
