## 00_packages.R — Load required libraries for apep_1125
## UK Breathing Space moratorium and personal insolvency

pkgs <- c(
  "tidyverse",    # data manipulation and plotting
  "fixest",       # fast fixed effects estimation
  "readxl",       # read Excel files (Insolvency Service data)
  "httr",         # HTTP requests for data downloads
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra"    # table formatting
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
