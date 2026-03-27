## 00_packages.R — Load required packages for apep_1064
## Payment Infrastructure and the Formalization Margin

required_packages <- c(
  "data.table", "fixest", "httr", "jsonlite", "readr",
  "dplyr", "tidyr", "lubridate", "stringr", "modelsummary",
  "xtable", "kableExtra", "fwildclusterboot"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
