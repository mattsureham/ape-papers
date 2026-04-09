# 00_packages.R — Install and load required packages
pkgs <- c(
  "readODS", "httr", "jsonlite", "data.table", "dplyr", "tidyr",
  "fixest", "rdrobust", "rddensity", "sandwich", "lmtest",
  "ggplot2", "kableExtra",
  "stringr", "lubridate", "purrr"
)
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
