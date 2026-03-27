## 00_packages.R — Load required packages for Groningen earthquake compensation paper
## apep_1069

required_packages <- c(
  "tidyverse",    # data manipulation and plotting
  "fixest",       # fast fixed effects estimation
  "sf",           # spatial operations
  "jsonlite",     # parse KNMI JSON data
  "httr",         # HTTP requests for APIs
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "data.table"    # efficient data operations
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Also try cbsodataR for CBS StatLine API
if (!requireNamespace("cbsodataR", quietly = TRUE)) {
  install.packages("cbsodataR", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(cbsodataR)

cat("All packages loaded successfully.\n")
