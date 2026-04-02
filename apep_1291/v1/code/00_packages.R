## 00_packages.R — Load and install required packages
## apep_1291: The Corporate Farm Brake

required <- c(
  "tidyverse", "fixest", "sf", "httr", "jsonlite",
  "tigris", "modelsummary", "xtable", "data.table"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

options(tigris_use_cache = TRUE)
