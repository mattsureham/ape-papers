## 00_packages.R — Install and load required packages
## apep_1007: Banking the Unbanked by Mandate

required_packages <- c(
  "data.table", "dplyr", "tidyr", "readr", "stringr", "lubridate",
  "fixest", "did", "HonestDiD",
  "httr", "jsonlite", "xml2", "rsdmx",
  "eurostat",
  "xtable", "kableExtra",
  "ggplot2",
  "sandwich",
  "WDI"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
