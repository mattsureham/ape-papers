## 00_packages.R — Install and load required packages
## APEP paper apep_0933: BNG and Housing Development in England

required <- c(
  "data.table", "fixest", "ggplot2", "httr2", "jsonlite",
  "readr", "dplyr", "tidyr", "stringr", "lubridate",
  "modelsummary", "kableExtra", "did"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
