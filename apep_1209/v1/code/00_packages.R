## 00_packages.R — Install and load required packages
## apep_1209: Cannabis dispensary lotteries and property values

required_pkgs <- c(
  "data.table", "jsonlite", "httr", "sf", "units",
  "fixest", "modelsummary", "did",
  "ggplot2", "dplyr", "tidyr", "lubridate", "stringr",
  "sandwich", "lmtest", "broom",
  "xtable", "kableExtra",
  "tidycensus"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
