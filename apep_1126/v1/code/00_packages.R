## ============================================================================
## 00_packages.R — Package loading for apep_1126
## Canada Cannabis Legalization and US Border Drug Enforcement
## ============================================================================

required_packages <- c(
  "data.table", "fixest", "ggplot2",
  "sf", "tigris", "tidycensus",
  "httr", "jsonlite",
  "sandwich", "lmtest",
  "xtable", "arrow"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

options(tigris_use_cache = TRUE)
options(scipen = 999)
set.seed(20261126)

cat("All packages loaded.\n")
