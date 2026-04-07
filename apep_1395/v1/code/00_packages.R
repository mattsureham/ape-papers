## 00_packages.R — Install and load required packages
## apep_1395: Denmark Renovation Arbitrage Ban

required_packages <- c(
  "httr", "jsonlite", "dplyr", "tidyr", "readr", "stringr", "lubridate",
  "fixest", "did", "ggplot2", "patchwork", "scales", "kableExtra",
  "sf", "xtable"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
