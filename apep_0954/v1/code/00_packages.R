## 00_packages.R — Load required libraries for apep_0954
## Beirut Port Explosion and Food Prices

pkgs <- c(
  "data.table", "fixest", "ggplot2", "readr", "jsonlite",
  "stringr", "lubridate", "geosphere",
  "modelsummary", "kableExtra", "tidygeocoder"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
