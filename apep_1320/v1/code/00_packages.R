## 00_packages.R — Install and load required packages
required <- c(
  "data.table", "fixest", "modelsummary", "kableExtra",
  "rvest", "httr", "jsonlite", "readr", "stringr", "sf",
  "tidygeocoder", "geosphere", "ivreg", "sandwich", "lmtest"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
