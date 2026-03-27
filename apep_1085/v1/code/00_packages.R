# 00_packages.R — Load required packages for apep_1085
# Ghana Galamsey Ban and Local Conflict

required <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # TWFE, event studies
  "httr",         # API calls (ACLED)
  "jsonlite",     # JSON parsing
  "sf",           # spatial operations
  "geodata",      # GADM admin boundaries
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust SEs
  "fwildclusterboot" # wild cluster bootstrap
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
