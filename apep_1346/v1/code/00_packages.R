# 00_packages.R — Load required packages
# apep_1346: The Lag Windfall

required_packages <- c(
  "tidyverse",    # data manipulation
  "fixest",       # fast fixed effects
  "data.table",   # efficient data processing
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "readxl",       # Excel files
  "rvest",        # web scraping
  "lubridate",    # date handling
  "xtable",       # LaTeX tables
  "modelsummary", # regression tables
  "kableExtra"    # table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
