## 00_packages.R — Load and install required packages
## apep_1417: Morocco Cannabis Legalization

pkgs <- c(
  "sf", "dplyr", "tidyr", "readr", "stringr", "lubridate",
  "fixest", "did", "ggplot2", "jsonlite", "httr2", "purrr",
  "modelsummary", "kableExtra"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
