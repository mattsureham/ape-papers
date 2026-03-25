## 00_packages.R — Install and load required packages
## apep_0958: Dutch Nitrogen Ruling and Populist Backlash

required_pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

  "fixest",       # fast fixed effects estimation
  "sf",           # spatial data handling
  "httr",         # HTTP requests for CBS/PDOK APIs
  "jsonlite",     # JSON parsing
  "data.table",   # fast data operations
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "rvest",        # web scraping (Kiesraad)
  "readxl",       # Excel reading
  "HonestDiD"     # Rambachan-Roth sensitivity
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
