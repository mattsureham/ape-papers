## 00_packages.R — Install and load required packages
## apep_0717: Benefit Cap Reduction and Temporary Accommodation

pkgs <- c(
  "data.table", "fixest", "ggplot2", "readxl", "httr2", "jsonlite",
  "modelsummary", "kableExtra", "dplyr", "tidyr",
  "stringr", "readr", "lubridate", "readODS", "sandwich"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

cat("All packages loaded.\n")
