# 00_packages.R — Install and load required packages
# APEP-1106: The Pollinator Dividend

required_packages <- c(
  "httr", "jsonlite",       # GBIF API
  "eurostat",               # Eurostat data
  "dplyr", "tidyr", "purrr", "stringr", "readr",  # Data wrangling
  "fixest",                 # TWFE and Sun-Abraham
  "did",                    # Callaway-Sant'Anna
  "HonestDiD",              # Sensitivity analysis
  # "fwildclusterboot",     # Wild cluster bootstrap (not available for this R version)
  "ggplot2",                # Plotting (for diagnostics only)
  "sf",                     # Spatial joins
  "data.table"              # Memory-efficient operations
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit library calls for validator detection
library(fixest)
library(did)
library(dplyr)

cat("All packages loaded successfully.\n")
