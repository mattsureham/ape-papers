# 00_packages.R — Load required libraries
# APEP-1081: Coal Tar Sealant Bans and Waterway PAH Contamination

required <- c(
  "tidyverse",
  "fixest",
  "did",
  "dataRetrieval",  # USGS/WQP data access
  "jsonlite",
  "modelsummary",
  "kableExtra",
  "lubridate"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
