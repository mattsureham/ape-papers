## 00_packages.R — Load and install required packages
## APEP paper apep_1234: FATF Grey-Listing and Panama Banking

required_packages <- c(
  "tidyverse",    # data manipulation and plotting
  "readxl",       # read Excel files
  "fixest",       # fast fixed effects estimation
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite",     # write diagnostics
  "httr",         # HTTP requests
  "lubridate"     # date handling
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
