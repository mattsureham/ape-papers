## 00_packages.R — Install and load required packages
## apep_0752: Tribal Casino Revenues and Opioid Mortality

pkgs <- c(
  "tidyverse",    # Data wrangling
  "fixest",       # Two-way FE and staggered DiD
  "did",          # Callaway-Sant'Anna (2021)
  "data.table",   # Fast data manipulation
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "readr",        # CSV reading
  "rvest",        # Web scraping for casino data
  "tigris",       # Census TIGER/Line geographic data
  "sf",           # Spatial operations
  "modelsummary", # Regression tables
  "kableExtra"    # Table formatting
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
