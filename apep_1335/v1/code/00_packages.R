# 00_packages.R — Load and install required packages
# apep_1335: Cannabis Lottery and Local Economic Renewal

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna staggered DiD
  "HonestDiD",    # Sensitivity analysis for parallel trends
  "httr",         # HTTP requests for APIs
  "jsonlite",     # JSON parsing
  "xtable",       # LaTeX table generation
  "pdftools",     # PDF text extraction (IDFPR list)
  "tidygeocoder", # Geocoding dispensary addresses
  "tigris",       # FIPS code lookups
  "sf"            # Spatial operations for county assignment
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
