## 00_packages.R — Load required libraries
## apep_0942: Dominican Republic MIPYME Procurement Set-Asides

required_packages <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr",
  "lubridate", "readr", "jsonlite", "stringr", "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
