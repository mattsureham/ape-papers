## 00_packages.R — Load required packages
## apep_1090: The Compliance Trap

required_pkgs <- c(
  "tidyverse", "fixest", "data.table", "jsonlite",
  "tidycensus", "modelsummary", "kableExtra",
  "httr", "readr", "sf", "lubridate"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
