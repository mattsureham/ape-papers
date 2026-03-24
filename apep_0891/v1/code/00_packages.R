## 00_packages.R — Load required libraries
## SNAP EA Expiration and Eviction Filings

pkgs <- c(
  "data.table", "tidyverse", "fixest", "did",
  "xtable", "jsonlite", "httr", "lubridate",
  "sandwich", "lmtest"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
