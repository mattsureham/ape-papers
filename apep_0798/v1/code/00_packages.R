# ==============================================================================
# 00_packages.R — Install and load required packages
# Paper: Frictionless Highways (apep_0798)
# ==============================================================================

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols, sunab)
  "sf",            # Spatial features
  "terra",         # Raster processing
  "geodata",       # GADM boundary downloads
  "xtable",        # LaTeX table output
  "jsonlite",      # JSON I/O
  "httr",          # HTTP requests
  "modelsummary",  # Regression tables
  "kableExtra"     # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
