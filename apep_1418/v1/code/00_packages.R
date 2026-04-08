## 00_packages.R — Install and load required packages
required <- c(
  "tidyverse", "fixest", "modelsummary", "kableExtra",
  "jsonlite", "httr", "duckdb", "DBI", "sandwich", "lmtest",
  "xtable", "ivreg"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Source Azure helper
source("../../../../scripts/lib/azure_data.R")

cat("All packages loaded.\n")
