## 00_packages.R — Load required packages
## apep_1190: SNAP Retailer Exits and Birth Outcomes

required <- c(
  "tidyverse", "fixest", "data.table", "httr", "jsonlite",
  "readr", "haven", "modelsummary", "kableExtra"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
