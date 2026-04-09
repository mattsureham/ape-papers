## 00_packages.R — Load required libraries
## apep_1446: X-waiver elimination and buprenorphine desert entry

pkgs <- c("data.table", "arrow", "fixest", "ggplot2", "dplyr",
          "jsonlite", "xtable", "httr", "readr", "stringr", "lubridate")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
